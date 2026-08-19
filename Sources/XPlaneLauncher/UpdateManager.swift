//
//  Copyright (c) 2026 Jeremie Corbier
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation
import Observation

@MainActor
@Observable
class UpdateManager {
    private let scanService = UpdaterScanService.shared
    private let defaults = UserDefaults.standard

    /// Cancels an in-flight scan when a new one starts, so a quick succession of
    /// data-folder changes cannot leave two scans racing to assign the result.
    private var scanTask: Task<Void, Never>?

    private(set) var isScanning = false

    /// Master switch for the whole add-on update feature. Off means no scan at
    /// all, which is the guaranteed way to a launch that touches no add-on files.
    var enableAddonUpdates: Bool {
        didSet {
            guard enableAddonUpdates != oldValue else { return }
            defaults.set(enableAddonUpdates, forKey: .enableAddonUpdates)
            if enableAddonUpdates {
                scanUpdatableAddons()
            } else {
                scanTask?.cancel()
                scanTask = nil
                isScanning = false
                updatableAddons = []
            }
        }
    }

    var automaticallyCheckSkunkCraftsUpdates: Bool {
        didSet {
            defaults.set(automaticallyCheckSkunkCraftsUpdates, forKey: .autoCheckSkunkCraftsUpdates)
        }
    }

    var automaticallyCheckXUpdaterUpdates: Bool {
        didSet {
            defaults.set(automaticallyCheckXUpdaterUpdates, forKey: .autoCheckXUpdaterUpdates)
        }
    }

    var launcherDataFolder: URL? {
        didSet {
            guard launcherDataFolder != oldValue else { return }
            scanUpdatableAddons()
        }
    }

    var updatableAddons: [UpdatableAddon] = []
    let logger = ConsoleLogger()

    var isCheckingUpdates: Bool {
        updatableAddons.contains { $0.isChecking }
    }

    var isUpdatingAddons: Bool {
        updatableAddons.contains { $0.isUpdating }
    }

    var isProcessing: Bool {
        updatableAddons.contains { $0.isChecking || $0.isUpdating }
    }

    func log(_ message: String) {
        logger.log(message)
    }

    func clearLogs() {
        logger.clear()
    }

    // Model typealiases for view compatibility
    typealias UpdaterType = XPlaneLauncher.UpdaterType
    typealias AddonCategory = XPlaneLauncher.AddonCategory
    typealias UpdatableAddon = XPlaneLauncher.UpdatableAddon

    init(launcherDataFolder: URL? = nil) {
        if defaults.object(forKey: .autoCheckSkunkCraftsUpdates) == nil {
            self.automaticallyCheckSkunkCraftsUpdates = true
        } else {
            self.automaticallyCheckSkunkCraftsUpdates = defaults.bool(forKey: .autoCheckSkunkCraftsUpdates)
        }

        if defaults.object(forKey: .autoCheckXUpdaterUpdates) == nil {
            self.automaticallyCheckXUpdaterUpdates = true
        } else {
            self.automaticallyCheckXUpdaterUpdates = defaults.bool(forKey: .autoCheckXUpdaterUpdates)
        }

        if defaults.object(forKey: .enableAddonUpdates) == nil {
            self.enableAddonUpdates = true
        } else {
            self.enableAddonUpdates = defaults.bool(forKey: .enableAddonUpdates)
        }

        self.launcherDataFolder = launcherDataFolder
        if launcherDataFolder != nil {
            scanUpdatableAddons()
        }
    }

    // MARK: - Scanning

    /// Rescans the central data folder off the main actor and checks for updates
    /// once the list is in place. Safe to call repeatedly: an in-flight scan is
    /// cancelled and replaced.
    func scanUpdatableAddons() {
        scanTask?.cancel()

        guard enableAddonUpdates, let dataFolder = launcherDataFolder else {
            scanTask = nil
            isScanning = false
            updatableAddons = []
            return
        }

        isScanning = true
        let scanService = self.scanService

        scanTask = Task { [weak self] in
            let found = await Task.detached(priority: .userInitiated) {
                scanService.scanUpdatableAddons(in: dataFolder)
            }.value

            guard let self, !Task.isCancelled else { return }

            self.updatableAddons = found
            self.isScanning = false
            self.scanTask = nil
            self.checkAutoUpdates()
        }
    }

    // MARK: - Update Checking

    /// How many add-ons are checked against their remote at the same time.
    /// Firing one request per add-on at once turns a large collection into a
    /// burst of network traffic right at launch.
    private static let maxConcurrentChecks = 4

    func checkAutoUpdates() {
        guard enableAddonUpdates else { return }

        let due = updatableAddons.filter { addon in
            guard !addon.isChecking, !addon.isUpdating else { return false }
            switch addon.updaterType {
            case .skunkcrafts: return automaticallyCheckSkunkCraftsUpdates
            case .xUpdater: return automaticallyCheckXUpdaterUpdates
            }
        }
        checkForUpdates(in: due)
    }

    func checkAllAddonUpdates() {
        guard enableAddonUpdates else { return }
        checkForUpdates(in: updatableAddons.filter { !$0.isChecking && !$0.isUpdating })
    }

    /// Runs the checks with a bounded number in flight, refilling as each one
    /// finishes rather than waiting for the whole batch.
    private func checkForUpdates(in addons: [UpdatableAddon]) {
        guard !addons.isEmpty else { return }

        for index in updatableAddons.indices where addons.contains(where: { $0.id == updatableAddons[index].id }) {
            updatableAddons[index].isChecking = true
            updatableAddons[index].statusMessage = "Checking..."
        }

        Task { @MainActor in
            var next = 0
            await withTaskGroup(of: Void.self) { group in
                while next < addons.count && next < Self.maxConcurrentChecks {
                    let addon = addons[next]
                    group.addTask { await self.performCheck(for: addon) }
                    next += 1
                }

                while await group.next() != nil {
                    guard next < addons.count else { continue }
                    let addon = addons[next]
                    group.addTask { await self.performCheck(for: addon) }
                    next += 1
                }
            }
        }
    }

    /// Single-add-on entry point, used by the per-row button.
    func checkForUpdates(for addon: UpdatableAddon) {
        guard let index = updatableAddons.firstIndex(where: { $0.id == addon.id }) else { return }
        guard !updatableAddons[index].isChecking && !updatableAddons[index].isUpdating else { return }
        checkForUpdates(in: [addon])
    }

    private func performCheck(for addon: UpdatableAddon) async {
        let addonId = addon.id

        guard let remoteURLString = addon.remoteManifestURL, !remoteURLString.isEmpty else {
            if let i = updatableAddons.firstIndex(where: { $0.id == addonId }) {
                updatableAddons[i].isChecking = false
                updatableAddons[i].statusMessage = "Up to date"
            }
            return
        }

        let updater = addon.updaterType.updater

        do {
            let result = try await updater.checkStatus(for: addon) { [weak self] msg in
                self?.log(msg)
            }

            if let i = updatableAddons.firstIndex(where: { $0.id == addonId }) {
                updatableAddons[i].isChecking = false
                updatableAddons[i].latestVersion = result.latestVersion
                updatableAddons[i].isUpdateAvailable = result.isUpdateAvailable
                updatableAddons[i].statusMessage = result.statusMessage
            }
        } catch {
            log("[UpdateManager] Error checking \(addon.name): \(error.localizedDescription)")
            if let i = updatableAddons.firstIndex(where: { $0.id == addonId }) {
                updatableAddons[i].isChecking = false
                updatableAddons[i].isUpdateAvailable = false
                updatableAddons[i].statusMessage = "Check failed"
            }
        }
    }

    func updateAddon(_ addon: UpdatableAddon) {
        guard let index = updatableAddons.firstIndex(where: { $0.id == addon.id }) else { return }
        guard !updatableAddons[index].isUpdating else { return }
        updatableAddons[index].isUpdating = true
        updatableAddons[index].statusMessage = "Updating..."

        let addonId = addon.id
        let updater = addon.updaterType.updater

        Task { @MainActor in
            do {
                try await updater.applyUpdates(
                    for: addon,
                    logHandler: { [weak self] msg in
                        self?.log(msg)
                    },
                    progressHandler: { [weak self] message, progress in
                        if let i = self?.updatableAddons.firstIndex(where: { $0.id == addonId }) {
                            self?.updatableAddons[i].statusMessage = message
                        }
                    }
                )

                if let i = self.updatableAddons.firstIndex(where: { $0.id == addonId }) {
                    if let latest = self.updatableAddons[i].latestVersion {
                        self.updatableAddons[i].currentVersion = latest
                    }
                    self.updatableAddons[i].isUpdating = false
                    self.updatableAddons[i].isUpdateAvailable = false
                    self.updatableAddons[i].statusMessage = "Up to date"
                }
            } catch {
                self.log("[UpdateManager] Update failed for \(addon.name): \(error.localizedDescription)")
                if let i = self.updatableAddons.firstIndex(where: { $0.id == addonId }) {
                    self.updatableAddons[i].isUpdating = false
                    self.updatableAddons[i].statusMessage = "Update failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

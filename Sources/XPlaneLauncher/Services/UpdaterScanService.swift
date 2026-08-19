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

/// Walks the central data folder looking for add-ons that ship an updater
/// configuration.
///
/// The scan is deliberately listing-driven: every directory is enumerated
/// exactly once and all config-name probing happens in memory against that
/// listing. Probing each candidate name with `fileExists` instead costs over two
/// hundred `stat` calls per directory, which on a real add-on collection means
/// millions of syscalls for a single scan.
final class UpdaterScanService: Sendable {
    static let shared = UpdaterScanService()

    private var fileManager: FileManager { FileManager.default }

    private let pathService = PathService.shared

    /// Directories that belong to an add-on's internals and never contain an
    /// updater configuration. Skipping them removes the bulk of the tree —
    /// scenery packages carry hundreds of tile folders under "Earth nav data",
    /// aircraft carry one folder per livery and object.
    ///
    /// Only names that are unambiguously X-Plane internals belong here. A folder
    /// used to group add-ons (`Aircraft/Heli/…`) must keep being searched.
    private let skippedFolderNames: Set<String> = [
        "earth nav data", "objects", "liveries", "textures", "fmod", "sounds",
        "cockpit", "cockpit_3d", "airfoils", "terrain",
        "win_x64", "mac_x64", "lin_x64", ".git"
    ]

    private let maxDepth = 5

    // MARK: - Scanning

    func scanUpdatableAddons(in dataFolder: URL) -> [UpdatableAddon] {
        var results: [UpdatableAddon] = []

        for category in AddonCategory.allCases {
            if Task.isCancelled { return [] }

            let folderURL = pathService.dataFolder(category.dataSubfolder, in: dataFolder)
            guard fileManager.fileExists(atPath: folderURL.path) else { continue }

            results.append(contentsOf: scanDirectory(folderURL, category: category, depth: 0))
        }

        return results
    }

    private func scanDirectory(_ folderURL: URL, category: AddonCategory, depth: Int) -> [UpdatableAddon] {
        guard depth <= maxDepth, !Task.isCancelled else { return [] }

        guard let contents = try? fileManager.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        // One listing serves both purposes: telling directories from files, and
        // answering every "does this config file exist here?" question below.
        var subdirectories: [URL] = []
        var entryNames: Set<String> = []
        for url in contents {
            entryNames.insert(url.lastPathComponent)
            if (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
                subdirectories.append(url)
            }
        }

        var results: [UpdatableAddon] = []

        for itemURL in subdirectories {
            if Task.isCancelled { return results }

            let folderName = itemURL.lastPathComponent
            if skippedFolderNames.contains(folderName.lowercased()) { continue }

            guard let childEntries = try? fileManager.contentsOfDirectory(
                at: itemURL,
                includingPropertiesForKeys: nil,
                options: []  // config files may be hidden, e.g. ".xupdater"
            ) else {
                continue
            }
            let childNames = Set(childEntries.map { $0.lastPathComponent })

            if let updaterInfo = findUpdaterConfig(in: itemURL, entries: childNames) {
                let (parsedName, version, remoteURL) = parseUpdaterConfig(
                    url: updaterInfo.fileURL,
                    type: updaterInfo.type,
                    defaultName: folderName
                )

                results.append(UpdatableAddon(
                    name: parsedName,
                    addonCategory: category,
                    folderName: folderName,
                    folderURL: itemURL,
                    updaterType: updaterInfo.type,
                    configFileURL: updaterInfo.fileURL,
                    currentVersion: version,
                    remoteManifestURL: remoteURL
                ))
            } else {
                results.append(contentsOf: scanDirectory(itemURL, category: category, depth: depth + 1))
            }
        }

        return results
    }

    // MARK: - Config Discovery

    private func findUpdaterConfig(in folderURL: URL, entries: Set<String>) -> (type: UpdaterType, fileURL: URL)? {
        if let url = SkunkCraftsUpdaterService.shared.matchConfig(in: folderURL, entries: entries) {
            return (.skunkcrafts, url)
        }
        if let url = XUpdaterService.shared.matchConfig(in: folderURL, entries: entries) {
            return (.xUpdater, url)
        }
        return nil
    }

    private func parseUpdaterConfig(url: URL, type: UpdaterType, defaultName: String) -> (name: String, version: String?, remoteURL: String?) {
        switch type {
        case .skunkcrafts:
            if let config = SkunkCraftsUpdaterService.shared.parseConfig(at: url, defaultName: defaultName) {
                return (config.name, config.version, config.remoteManifestURL)
            }
        case .xUpdater:
            if let config = XUpdaterService.shared.parseConfig(at: url, defaultName: defaultName) {
                return (config.name, config.version, config.remoteURL)
            }
        }
        return (defaultName, nil, nil)
    }
}

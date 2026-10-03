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

/// Polls the CPU usage of everything except the launcher itself and tells the
/// UI whether starting X-Plane right now is a good idea. Blocking is advisory:
/// the launch button always keeps a manual override so a wrong reading can
/// never lock the user out.
@MainActor
@Observable
class SystemReadinessManager {
    private let defaults = UserDefaults.standard

    /// Cancelled and restarted when the feature flag flips, so no stale loop
    /// keeps writing state after the feature was turned off.
    private var pollTask: Task<Void, Never>?

    /// Master switch. Off means no polling at all and no status line in the UI.
    var blockLaunchOnHighLoad: Bool {
        didSet {
            guard blockLaunchOnHighLoad != oldValue else { return }
            defaults.set(blockLaunchOnHighLoad, forKey: .blockLaunchOnHighLoad)
            if blockLaunchOnHighLoad {
                startMonitoring()
            } else {
                stopMonitoring()
                resetState()
            }
        }
    }

    /// Optimistic until the first sample arrives: never block on startup.
    private(set) var isReady = true
    private(set) var reason = "Ready to launch."
    private(set) var lastSample: CPUUsageSample?

    /// Foreign CPU share after smoothing; what the thresholds are applied to.
    private(set) var smoothedForeignShare: Double?

    /// The only thing the launch button needs to know.
    var blocksLaunch: Bool {
        blockLaunchOnHighLoad && !isReady
    }

    init() {
        if defaults.object(forKey: .blockLaunchOnHighLoad) == nil {
            self.blockLaunchOnHighLoad = true
        } else {
            self.blockLaunchOnHighLoad = defaults.bool(forKey: .blockLaunchOnHighLoad)
        }
    }

    // MARK: - Monitoring

    /// Idempotent: a running loop is left alone instead of being duplicated.
    func startMonitoring() {
        guard blockLaunchOnHighLoad, pollTask == nil else { return }

        // A paused loop restarts from a fresh baseline; carrying the old
        // average over would judge the machine by how it was minutes ago.
        smoothedForeignShare = nil

        pollTask = Task { [weak self] in
            var previous = await Self.readCounters()
            var interval = SystemReadinessService.firstPollInterval

            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: interval)
                } catch {
                    return
                }
                interval = SystemReadinessService.pollInterval

                let current = await Self.readCounters()
                guard !Task.isCancelled else { return }

                if let old = previous, let new = current,
                   let sample = CPUUsageSample(from: old, to: new, coreCount: SystemReadinessService.shared.coreCount) {
                    self?.apply(sample)
                }
                previous = current ?? previous
            }
        }
    }

    func stopMonitoring() {
        pollTask?.cancel()
        pollTask = nil
    }

    private nonisolated static func readCounters() async -> CPUCounters? {
        await Task.detached {
            SystemReadinessService.shared.readCounters()
        }.value
    }

    // MARK: - Evaluation

    private func apply(_ sample: CPUUsageSample) {
        lastSample = sample
        let share = SystemReadinessService.smoothed(
            previous: smoothedForeignShare,
            current: sample.foreignShare,
            elapsed: sample.elapsed
        )
        smoothedForeignShare = share

        // Hysteresis: once blocked, the usage has to fall back below the lower
        // threshold before the button comes back.
        let threshold = isReady ? SystemReadinessService.busyThreshold : SystemReadinessService.readyThreshold
        isReady = share < threshold

        if isReady {
            reason = "Ready to launch."
        } else {
            let percent = Int((share * 100).rounded())
            reason = "System still busy — other processes use \(percent)% of \(sample.coreCount) cores (indexing, sync). X-Plane would start slowly."
        }
    }

    private func resetState() {
        isReady = true
        reason = "Ready to launch."
        lastSample = nil
        smoothedForeignShare = nil
    }
}

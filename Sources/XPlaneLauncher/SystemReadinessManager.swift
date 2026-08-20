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

/// Polls the system load and tells the UI whether starting X-Plane right now is
/// a good idea. Blocking is advisory: the launch button always keeps a manual
/// override so a wrong reading can never lock the user out.
@MainActor
@Observable
class SystemReadinessManager {
    private let service = SystemReadinessService.shared
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
    private(set) var lastSample: SystemLoadSample?

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

        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                let sample = await Task.detached {
                    SystemReadinessService.shared.sample()
                }.value

                guard !Task.isCancelled else { return }
                self?.apply(sample)

                do {
                    try await Task.sleep(for: SystemReadinessService.pollInterval)
                } catch {
                    return
                }
            }
        }
    }

    func stopMonitoring() {
        pollTask?.cancel()
        pollTask = nil
    }

    // MARK: - Evaluation

    private func apply(_ sample: SystemLoadSample) {
        lastSample = sample

        // Hysteresis: once blocked, the load has to fall back below the lower
        // threshold before the button comes back.
        let threshold = isReady ? SystemReadinessService.busyThreshold : SystemReadinessService.readyThreshold
        isReady = sample.loadPerCore < threshold

        if isReady {
            reason = "Ready to launch."
        } else {
            let load = String(format: "%.1f", sample.loadOneMinute)
            reason = "System still busy — load \(load) across \(sample.coreCount) cores (indexing, sync). X-Plane would start slowly."
        }
    }

    private func resetState() {
        isReady = true
        reason = "Ready to launch."
        lastSample = nil
    }
}

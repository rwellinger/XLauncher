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

/// One reading of the system load, taken off the main actor.
struct SystemLoadSample: Sendable {
    let loadOneMinute: Double
    let coreCount: Int

    /// Load relative to the number of cores: 1.0 means every core is saturated.
    var loadPerCore: Double {
        coreCount > 0 ? loadOneMinute / Double(coreCount) : 0
    }
}

/// Reads the kernel load average so the launcher can tell whether the machine is
/// still working through a boot storm (Spotlight indexing, iCloud sync,
/// background Shortcuts) — X-Plane starts several times slower in that phase.
final class SystemReadinessService: Sendable {
    static let shared = SystemReadinessService()

    /// Considered ready below this share of the cores. The gap to
    /// `busyThreshold` is hysteresis so the launch button cannot flicker while
    /// the load hovers around the boundary.
    static let readyThreshold: Double = 0.50
    static let busyThreshold: Double = 0.65

    /// How often the load is sampled. The kernel averages over a minute anyway,
    /// so anything faster only burns cycles.
    static let pollInterval: Duration = .seconds(4)

    private init() {}

    /// Cheap syscall (`getloadavg`), safe to call from any actor. A failed read
    /// reports zero load, which keeps the launcher permissive rather than
    /// locking the user out because of a measurement error.
    nonisolated func sample() -> SystemLoadSample {
        var loads = [Double](repeating: 0, count: 3)
        let count = getloadavg(&loads, 3)

        return SystemLoadSample(
            loadOneMinute: count > 0 ? loads[0] : 0,
            coreCount: ProcessInfo.processInfo.activeProcessorCount
        )
    }
}

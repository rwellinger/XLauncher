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

import Darwin
import Foundation

/// Raw cumulative counters, read twice to get the usage in between.
struct CPUCounters: Sendable, Equatable {
    /// Machine-wide ticks summed over all cores, as the kernel reports them.
    /// 32-bit and free-running, so they wrap; `CPUUsageSample` subtracts with
    /// wrapping arithmetic.
    let userTicks: UInt32
    let systemTicks: UInt32
    let niceTicks: UInt32
    let idleTicks: UInt32

    /// CPU time consumed by the launcher process itself (all threads), seconds.
    let ownCPUTime: TimeInterval

    /// Monotonic clock at the moment of reading, seconds.
    let uptime: TimeInterval
}

/// CPU usage over one polling interval, with the launcher's own share taken out.
struct CPUUsageSample: Sendable, Equatable {
    /// Share of the whole machine (0...1) busy with work other than the launcher.
    let foreignShare: Double
    /// Share of the whole machine (0...1) the launcher itself was using.
    let ownShare: Double
    let coreCount: Int
    let elapsed: TimeInterval

    /// `nil` when the interval is empty or the readings are out of order — the
    /// caller then just waits for the next one.
    init?(from old: CPUCounters, to new: CPUCounters, coreCount: Int) {
        let busy = UInt64(new.userTicks &- old.userTicks)
            + UInt64(new.systemTicks &- old.systemTicks)
            + UInt64(new.niceTicks &- old.niceTicks)
        let total = busy + UInt64(new.idleTicks &- old.idleTicks)
        let elapsed = new.uptime - old.uptime
        guard total > 0, elapsed > 0, coreCount > 0 else { return nil }

        let machineShare = Double(busy) / Double(total)
        let ownShare = min(max((new.ownCPUTime - old.ownCPUTime) / (elapsed * Double(coreCount)), 0), 1)

        // The two come from different clocks (scheduler ticks vs. rusage), so
        // the difference can dip slightly below zero on an idle machine.
        self.foreignShare = max(machineShare - ownShare, 0)
        self.ownShare = ownShare
        self.coreCount = coreCount
        self.elapsed = elapsed
    }
}

/// Measures how busy the machine is so the launcher can tell whether it is
/// still working through a boot storm (Spotlight indexing, iCloud sync,
/// background Shortcuts) — X-Plane starts several times slower in that phase.
///
/// The launcher's own CPU time is subtracted: its add-on checks checksum
/// gigabytes of files right at startup, and the system-wide load average used
/// before counted that work too, so the launcher blocked itself.
final class SystemReadinessService: Sendable {
    static let shared = SystemReadinessService()

    /// Considered ready below this share of foreign CPU usage. The gap to
    /// `busyThreshold` is hysteresis so the launch button cannot flicker while
    /// the usage hovers around the boundary.
    static let readyThreshold: Double = 0.50
    static let busyThreshold: Double = 0.65

    /// How often the counters are read. The first interval is shorter so the
    /// status is known almost immediately after the window opens.
    static let pollInterval: Duration = .seconds(4)
    static let firstPollInterval: Duration = .seconds(1)

    /// Time constant of the smoothing. Single intervals are spiky; this keeps a
    /// short burst from blocking the button while still reacting within
    /// seconds rather than the minute the kernel load average took.
    static let smoothingTimeConstant: TimeInterval = 15

    /// Cached: every `mach_host_self()` call adds a send right to the port.
    private let host: host_t = mach_host_self()

    private init() {}

    /// Two cheap syscalls, safe to call from any actor. `nil` if the kernel
    /// refuses the host statistics; the manager then keeps its last state,
    /// which stays permissive rather than locking the user out.
    nonisolated func readCounters() -> CPUCounters? {
        var info = host_cpu_load_info_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<host_cpu_load_info_data_t>.stride / MemoryLayout<integer_t>.stride
        )
        let status = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(host, HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard status == KERN_SUCCESS else { return nil }

        // getrusage reports in microseconds on every architecture, unlike
        // proc_pid_rusage, whose times are Mach ticks on Apple Silicon.
        var usage = rusage()
        guard getrusage(RUSAGE_SELF, &usage) == 0 else { return nil }

        // cpu_ticks is indexed by CPU_STATE_USER / SYSTEM / IDLE / NICE.
        return CPUCounters(
            userTicks: info.cpu_ticks.0,
            systemTicks: info.cpu_ticks.1,
            niceTicks: info.cpu_ticks.3,
            idleTicks: info.cpu_ticks.2,
            ownCPUTime: Self.seconds(usage.ru_utime) + Self.seconds(usage.ru_stime),
            uptime: Double(clock_gettime_nsec_np(CLOCK_UPTIME_RAW)) / 1_000_000_000
        )
    }

    nonisolated var coreCount: Int {
        ProcessInfo.processInfo.activeProcessorCount
    }

    /// Exponential moving average, weighted by the real length of the interval
    /// so a late wakeup does not distort it. Seeds with the first value.
    static func smoothed(previous: Double?, current: Double, elapsed: TimeInterval) -> Double {
        guard let previous else { return current }
        let weight = 1 - exp(-max(elapsed, 0) / smoothingTimeConstant)
        return previous + weight * (current - previous)
    }

    private static func seconds(_ value: timeval) -> TimeInterval {
        TimeInterval(value.tv_sec) + TimeInterval(value.tv_usec) / 1_000_000
    }
}

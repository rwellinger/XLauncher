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


import XCTest
@testable import XPlaneLauncher

final class SystemReadinessTests: XCTestCase {
    private func counters(
        user: UInt32, system: UInt32 = 0, nice: UInt32 = 0, idle: UInt32,
        ownCPU: TimeInterval = 0, uptime: TimeInterval
    ) -> CPUCounters {
        CPUCounters(
            userTicks: user, systemTicks: system, niceTicks: nice, idleTicks: idle,
            ownCPUTime: ownCPU, uptime: uptime
        )
    }

    func testOwnCPUTimeIsSubtracted() throws {
        // 4 cores, 4 s: 16 core-seconds. Machine 75% busy, of which the
        // launcher used 8 core-seconds (50%) — only 25% belongs to others.
        let old = counters(user: 0, idle: 0, ownCPU: 10, uptime: 100)
        let new = counters(user: 1200, idle: 400, ownCPU: 18, uptime: 104)

        let sample = try XCTUnwrap(CPUUsageSample(from: old, to: new, coreCount: 4))
        XCTAssertEqual(sample.ownShare, 0.50, accuracy: 0.0001)
        XCTAssertEqual(sample.foreignShare, 0.25, accuracy: 0.0001)
    }

    func testNiceTicksCountAsBusy() throws {
        // Spotlight and other background indexing run niced.
        let old = counters(user: 0, idle: 0, uptime: 0)
        let new = counters(user: 100, system: 100, nice: 400, idle: 200, uptime: 1)

        let sample = try XCTUnwrap(CPUUsageSample(from: old, to: new, coreCount: 8))
        XCTAssertEqual(sample.foreignShare, 0.75, accuracy: 0.0001)
    }

    func testCountersWrapAround() throws {
        let old = counters(user: UInt32.max - 49, idle: UInt32.max - 49, uptime: 0)
        let new = counters(user: 50, idle: 50, uptime: 1)

        let sample = try XCTUnwrap(CPUUsageSample(from: old, to: new, coreCount: 1))
        XCTAssertEqual(sample.foreignShare, 0.5, accuracy: 0.0001)
    }

    func testForeignShareNeverNegative() throws {
        // Rusage and scheduler ticks disagree slightly on an idle machine.
        let old = counters(user: 0, idle: 0, ownCPU: 0, uptime: 0)
        let new = counters(user: 10, idle: 990, ownCPU: 0.5, uptime: 1)

        let sample = try XCTUnwrap(CPUUsageSample(from: old, to: new, coreCount: 2))
        XCTAssertEqual(sample.foreignShare, 0)
    }

    func testEmptyIntervalYieldsNoSample() {
        let reading = counters(user: 5, idle: 5, uptime: 10)
        XCTAssertNil(CPUUsageSample(from: reading, to: reading, coreCount: 4))
    }

    func testSmoothingSeedsWithFirstValue() {
        XCTAssertEqual(SystemReadinessService.smoothed(previous: nil, current: 0.8, elapsed: 4), 0.8)
    }

    func testSmoothingDampensShortBurst() {
        // One 4 s spike to 100% on an idle machine must not cross the busy threshold.
        let afterSpike = SystemReadinessService.smoothed(previous: 0.1, current: 1.0, elapsed: 4)
        XCTAssertLessThan(afterSpike, SystemReadinessService.busyThreshold)
    }

    func testSmoothingFollowsSustainedLoad() {
        var share: Double? = 0.1
        for _ in 0..<10 {
            share = SystemReadinessService.smoothed(previous: share, current: 0.9, elapsed: 4)
        }
        XCTAssertGreaterThan(try XCTUnwrap(share), SystemReadinessService.busyThreshold)
    }

    func testLiveCountersAreReadable() throws {
        let first = try XCTUnwrap(SystemReadinessService.shared.readCounters())
        Thread.sleep(forTimeInterval: 0.2)
        let second = try XCTUnwrap(SystemReadinessService.shared.readCounters())

        XCTAssertGreaterThan(second.uptime, first.uptime)
        XCTAssertGreaterThanOrEqual(second.ownCPUTime, first.ownCPUTime)
    }
}

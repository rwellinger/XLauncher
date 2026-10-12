//
//  AppInfoTests.swift
//  XPlaneLauncherTests
//

import XCTest
@testable import XPlaneLauncher

final class AppInfoTests: XCTestCase {
    func testDocumentationURLPointsAtFork() {
        XCTAssertEqual(
            AppInfo.documentationURL.absoluteString,
            "https://github.com/rwellinger/XLauncher/blob/main/docs/source/index.md"
        )
    }

    func testSemanticVersionIsPrerelease() {
        let stable = SemanticVersion(string: "1.0.0")
        XCTAssertEqual(stable?.isPrerelease, false)

        let rc = SemanticVersion(string: "1.0.0-rc1")
        XCTAssertEqual(rc?.isPrerelease, true)

        let beta = SemanticVersion(string: "v1.2.0-beta.2")
        XCTAssertEqual(beta?.isPrerelease, true)
    }
}

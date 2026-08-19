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

struct AddonUpdateCheckResult: Sendable {
    let latestVersion: String?
    let isUpdateAvailable: Bool
    let statusMessage: String
}

protocol AddonUpdater: Sendable {
    /// Picks this backend's configuration file out of an already-read directory
    /// listing. Taking the listing as input keeps the scan at one enumeration
    /// per directory instead of one `stat` per candidate file name.
    func matchConfig(in folderURL: URL, entries: Set<String>) -> URL?

    func checkStatus(
        for addon: UpdateManager.UpdatableAddon,
        logHandler: @Sendable @escaping @MainActor (String) -> Void
    ) async throws -> AddonUpdateCheckResult

    func applyUpdates(
        for addon: UpdateManager.UpdatableAddon,
        logHandler: @Sendable @escaping @MainActor (String) -> Void,
        progressHandler: @Sendable @escaping @MainActor (String, Double) -> Void
    ) async throws
}

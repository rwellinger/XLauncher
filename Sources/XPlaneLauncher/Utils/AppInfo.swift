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

enum AppInfo {
    static let appName = "X-Plane Launcher"
    static let maintainer = "thWelly"
    static let originalAuthor = "Jeremie Corbier"
    static let copyright = "Copyright © 2026 Jeremie Corbier, thWelly"
    static let license = "MIT License"

    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    }

    /// Placeholder written by `package.sh`; only the release workflow stamps a
    /// real version. A locally built fork therefore has no meaningful version
    /// number to show.
    private static let unversionedPlaceholder = "0.0.0"

    static var displayVersion: String {
        let ver = version.trimmingCharacters(in: .whitespacesAndNewlines)
        if ver.isEmpty || ver == unversionedPlaceholder {
            return "FORK"
        }
        let build = buildNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        if !build.isEmpty && build != ver {
            return "Version \(ver) (\(build))"
        }
        return "Version \(ver)"
    }

    // Repository links point at this fork: upstream releases do not carry the
    // fork's changes, so offering them would roll the user back.
    static let githubURL = URL(string: "https://github.com/rwellinger/XLauncher")!
    static let releasesURL = URL(string: "https://github.com/rwellinger/XLauncher/releases")!
    static let latestReleaseAPIURL = URL(string: "https://api.github.com/repos/rwellinger/XLauncher/releases/latest")!
    static let allReleasesAPIURL = URL(string: "https://api.github.com/repos/rwellinger/XLauncher/releases")!
    static let appcastURL = URL(string: "https://github.com/rwellinger/XLauncher/releases/latest/download/appcast.xml")!
    static let maintainerURL = URL(string: "https://github.com/rwellinger")!
    static let originalAuthorURL = URL(string: "https://github.com/jcorbier")!

    /// The fork has no hosted documentation build, so this points at the
    /// sources in the repository, which GitHub renders directly.
    static let documentationURL = URL(string: "https://github.com/rwellinger/XLauncher/blob/main/docs/source/index.md")!

    static let licenseText = """
    Copyright (c) 2026 Jeremie Corbier
    Copyright (c) 2026 thWelly

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
    """
}

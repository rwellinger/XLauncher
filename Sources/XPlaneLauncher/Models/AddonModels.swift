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

struct Plugin: Identifiable, Equatable, Hashable, Sendable {
    let id: UUID
    let name: String
    var isEnabled: Bool
    let folderName: String

    init(id: UUID = UUID(), name: String, isEnabled: Bool, folderName: String) {
        self.id = id
        self.name = name
        self.isEnabled = isEnabled
        self.folderName = folderName
    }
}

struct Aircraft: Identifiable, Equatable, Hashable, Sendable {
    let id: UUID
    let name: String
    var isEnabled: Bool
    /// Path relative to the central `Aircraft` folder — "B737-800X" when stored
    /// flat, "Heli/AW109SP" when the user groups aircraft in subfolders. This is
    /// the identity used for both symlinks and profile entries.
    let folderName: String
    /// Name of the grouping folder this aircraft sits in, or nil when it lives
    /// directly under `Aircraft`. Presentation only.
    let groupName: String?

    init(id: UUID = UUID(), name: String, isEnabled: Bool, folderName: String, groupName: String? = nil) {
        self.id = id
        self.name = name
        self.isEnabled = isEnabled
        self.folderName = folderName
        self.groupName = groupName
    }
}

struct LuaScript: Identifiable, Equatable, Hashable, Sendable {
    let id: UUID
    let name: String
    var isEnabled: Bool
    let folderName: String
    let isDirectory: Bool

    init(id: UUID = UUID(), name: String, isEnabled: Bool, folderName: String, isDirectory: Bool = false) {
        self.id = id
        self.name = name
        self.isEnabled = isEnabled
        self.folderName = folderName
        self.isDirectory = isDirectory
    }
}

struct Scenery: Identifiable, Equatable, Hashable, Sendable {
    let id: UUID
    var name: String
    var isEnabled: Bool
    var folderName: String
    var isManaged: Bool
    var isInIni: Bool
    var iniLine: String

    var isToggleable: Bool {
        !folderName.hasPrefix("*")
    }

    init(id: UUID = UUID(), name: String, isEnabled: Bool, folderName: String, isManaged: Bool, isInIni: Bool, iniLine: String) {
        self.id = id
        self.name = name
        self.isEnabled = isEnabled
        self.folderName = folderName
        self.isManaged = isManaged
        self.isInIni = isInIni
        self.iniLine = iniLine
    }
}

struct SceneryGroup: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var name: String
    var childFolderNames: [String]
    var isExpanded: Bool

    init(id: UUID = UUID(), name: String, childFolderNames: [String] = [], isExpanded: Bool = true) {
        self.id = id
        self.name = name
        self.childFolderNames = childFolderNames
        self.isExpanded = isExpanded
    }
}

struct ScriptEnvVar: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var key: String
    var value: String

    init(id: UUID = UUID(), key: String, value: String) {
        self.id = id
        self.key = key
        self.value = value
    }
}

struct ProfileScript: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var path: String
    var isEnabled: Bool

    init(id: UUID = UUID(), path: String, isEnabled: Bool = true) {
        self.id = id
        self.path = path
        self.isEnabled = isEnabled
    }
}

struct PluginProfile: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var name: String
    var pluginFolderNames: [String]
    var sceneryFolderNames: [String]
    var aircraftFolderNames: [String]
    var luaScriptFolderNames: [String]
    var shellScriptPath: String?
    var scripts: [ProfileScript]
    var environmentVariables: [ScriptEnvVar]

    enum CodingKeys: String, CodingKey {
        case id, name, pluginFolderNames, sceneryFolderNames, aircraftFolderNames, luaScriptFolderNames, shellScriptPath, scripts, environmentVariables
    }

    init(
        id: UUID = UUID(),
        name: String,
        pluginFolderNames: [String],
        sceneryFolderNames: [String] = [],
        aircraftFolderNames: [String] = [],
        luaScriptFolderNames: [String] = [],
        shellScriptPath: String? = nil,
        scripts: [ProfileScript] = [],
        environmentVariables: [ScriptEnvVar] = []
    ) {
        self.id = id
        self.name = name
        self.pluginFolderNames = pluginFolderNames
        self.sceneryFolderNames = sceneryFolderNames
        self.aircraftFolderNames = aircraftFolderNames
        self.luaScriptFolderNames = luaScriptFolderNames
        self.shellScriptPath = shellScriptPath
        self.scripts = scripts
        self.environmentVariables = environmentVariables
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.pluginFolderNames = try container.decode([String].self, forKey: .pluginFolderNames)
        self.sceneryFolderNames = try container.decodeIfPresent([String].self, forKey: .sceneryFolderNames) ?? []
        self.aircraftFolderNames = try container.decodeIfPresent([String].self, forKey: .aircraftFolderNames) ?? []
        self.luaScriptFolderNames = try container.decodeIfPresent([String].self, forKey: .luaScriptFolderNames) ?? []
        self.shellScriptPath = try container.decodeIfPresent(String.self, forKey: .shellScriptPath)
        self.scripts = try container.decodeIfPresent([ProfileScript].self, forKey: .scripts) ?? []
        self.environmentVariables = try container.decodeIfPresent([ScriptEnvVar].self, forKey: .environmentVariables) ?? []
    }
}

// MARK: - Add-on Updates

/// Which updater backend an add-on ships with.
///
/// Lives at file scope rather than nested in `UpdateManager` so the scan can run
/// off the main actor: types nested in a `@MainActor` declaration inherit its
/// isolation and could not cross an actor boundary.
enum UpdaterType: String, Codable, Identifiable, Sendable {
    case skunkcrafts = "SkunkCrafts"
    case xUpdater = "X-Updater"
    var id: String { rawValue }

    var updater: any AddonUpdater {
        switch self {
        case .skunkcrafts:
            return SkunkCraftsUpdaterService.shared
        case .xUpdater:
            return XUpdaterService.shared
        }
    }
}

enum AddonCategory: String, Codable, Identifiable, CaseIterable, Sendable {
    case aircraft = "Aircraft"
    case plugin = "Plugin"
    case scenery = "Scenery"
    case luaScript = "Lua Script"
    var id: String { rawValue }

    /// Where this category's source add-ons live inside the central data folder.
    var dataSubfolder: DataSubfolder {
        switch self {
        case .aircraft: return .aircraft
        case .plugin: return .plugins
        case .scenery: return .scenery
        case .luaScript: return .luaScripts
        }
    }
}

struct UpdatableAddon: Identifiable, Equatable, Hashable, Sendable {
    let id = UUID()
    let name: String
    let addonCategory: AddonCategory
    let folderName: String
    let folderURL: URL
    let updaterType: UpdaterType
    let configFileURL: URL
    var currentVersion: String?
    var latestVersion: String?
    var isUpdateAvailable: Bool = false
    var isChecking: Bool = false
    var isUpdating: Bool = false
    var statusMessage: String = "Unknown"
    var remoteManifestURL: String?
}

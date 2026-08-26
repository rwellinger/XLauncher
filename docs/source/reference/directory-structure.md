# Directory Structure

This page describes the file and folder layout used by X-Plane Launcher and the symbolic link mappings to your X-Plane 12 installation.

---

## Central Data Folder

Default location:
```text
~/Library/Application Support/XPlaneLauncher/
```

### Subdirectories

```text
XPlaneLauncher/
├── Aircraft/       # Source aircraft add-ons
├── Plugins/        # Source plugin add-ons
├── Scenery/        # Source custom scenery packages
└── LuaScripts/     # Source FlyWithLua scripts and bundles
```

Aircraft may additionally be sorted into grouping folders one level deep. A folder holding
no `.acf` file of its own, but containing folders that do, is treated as a group whose
aircraft are managed individually:

```text
Aircraft/
├── Zibo 737-800X/
└── Heli/
    ├── AW109SP/
    └── EC135/
```

This applies to aircraft only — plugins, scenery, and Lua scripts must sit directly in
their subdirectory.

---

## Symlink Mappings

When a profile is activated, X-Plane Launcher creates symbolic links inside the corresponding X-Plane 12 directories:

| Category | Source Path in Central Folder | Target Path in X-Plane 12 |
| :--- | :--- | :--- |
| **Aircraft** | `Aircraft/<Folder>` | `<X-Plane 12>/Aircraft/<Folder>` |
| **Grouped aircraft** | `Aircraft/<Group>/<Folder>` | `<X-Plane 12>/Aircraft/<Group>/<Folder>` (`<Group>` is a real directory, created and removed with its links) |
| **Plugins** | `Plugins/<Folder>` | `<X-Plane 12>/Resources/plugins/<Folder>` |
| **Scenery** | `Scenery/<Folder>` | `<X-Plane 12>/Custom Scenery/<Folder>` |
| **Lua Script** | `LuaScripts/<Script>.lua` | `<X-Plane 12>/Resources/plugins/FlyWithLua/Scripts/<Script>.lua` |
| **Lua Bundle** | `LuaScripts/<Folder>` | `<X-Plane 12>/Resources/plugins/FlyWithLua/Scripts/<Folder>` |
| **CSL Models** | *Directly installed* | `<X-Plane 12>/Resources/plugins/IVAO_CSL/CSL/<Package>` |

---

## Scenery Configuration File

File location:
```text
<X-Plane 12>/Custom Scenery/scenery_packs.ini
```

Entries are formatted as:
```text
I
1000 Version
SCENERY_PACK Custom Scenery/Aerosoft - EDDF Frankfurt/
SCENERY_PACK_DISABLED Custom Scenery/KLAS Las Vegas/
SCENERY_PACK Custom Scenery/Global Airports/
```

- `SCENERY_PACK`: Enabled scenery pack.
- `SCENERY_PACK_DISABLED`: Disabled scenery pack (skipped by simulator on startup).
- The order of lines determines loading and rendering priority.

---

## Application Preferences

Preferences are saved in macOS `UserDefaults`:

| Key | Type | Description |
| :--- | :--- | :--- |
| `XPlanePath` | String | Path to the X-Plane 12 folder |
| `LauncherDataFolder` | String | Path to the custom Central Data Folder |
| `PluginProfiles` | Data (JSON) | Saved profiles |
| `SelectedProfileId` | String (UUID) | ID of the currently selected profile |
| `SceneryGroups` | Data (JSON) | Scenery group definitions |
| `ScriptEnvVars` | Data (JSON) | Global pre-launch script environment variables |
| `EnableCSLSupport` | Boolean | Whether CSL support is enabled |
| `EnableCSLXP12Lights` | Boolean | Whether XP12 parameterized lighting is enabled |
| `HasCompletedWelcome` | Boolean | Whether the initial welcome assistant was completed |

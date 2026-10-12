# X-Plane Launcher

> **This is an independent fork**, maintained by thWelly. It is based on
> [jcorbier/XLauncher](https://github.com/jcorbier/XLauncher) by Jeremie Corbier
> and carries changes that are not part of the original. It does not include the
> original's Pro edition. For the upstream version, its downloads, and support,
> please go to the original repository.
>
> In-app self-updating is **disabled** in this fork. The upstream update feed
> serves builds without these changes, so installing from it would roll you back.
> Update by pulling this repository and running `./package.sh` again.

A native macOS manager and launcher for X-Plane 12.

X-Plane Launcher lets you organize your add-ons in a central folder, create distinct profiles (e.g. VATSIM, airliner, general aviation), reorder scenery, keep add-ons updated, and launch X-Plane with the exact configuration you need.

## Features

- **Profiles**: Save and switch configurations across aircraft, plugins, scenery packs, and FlyWithLua scripts.
- **Clean symlink management**: Keep your X-Plane directory tidy. Add-ons stay in a central folder and are symlinked into X-Plane on demand.
- **Aircraft grouping**: Organize your fleet in subfolders (e.g. `Aircraft/Heli/AW109SP`). Each aircraft is still enabled and disabled individually, and the grouping is mirrored into your X-Plane installation.
- **Scenery pack ordering & grouping**: Reorder `scenery_packs.ini` with drag-and-drop, enable or disable packs without deleting files, and organize scenery into groups.
- **Smart add-on installer & deletion**: Drag and drop `.zip` archives, folders, or `.lua` scripts to install add-ons, or delete them directly from the UI with automated profile cleanup and unlinking.
- **Add-on updates**: Check and install updates for add-ons supported by SkunkCrafts Updater or X-Updater directly from the UI.
- **Navigation data updates**: Download and update AIRAC cycles directly from Navigraph for X-Plane 12 and supported aircrafts.
- **CSL packages & lights**: Manage CSL model matching packages, apply lighting intensity presets (high/medium/low), or restore original lights.
- **Pre-launch scripts**: Run custom shell scripts with profile-specific environment variables before starting X-Plane (e.g. setting up Hoppie ACARS).

## Requirements

- macOS 14.0 (Sonoma) or later
- X-Plane 12

## Installation

### Pre-built binaries

Fork releases, when there are any, are published on this repository's [Releases](https://github.com/rwellinger/XLauncher/releases) page. Builds from the original project do **not** include this fork's changes — build from source for that.

### Building from source

Requires Xcode or Swift command-line tools:

```bash
git clone https://github.com/rwellinger/XLauncher.git
cd XLauncher
./package.sh
```

This generates `XLauncher.app` in the project root.

## Setup & Organization

On first launch, a welcome assistant helps you configure your paths:
- **X-Plane 12 folder**: Root folder containing `X-Plane.app`.
- **Central Data Folder**: Default is `~/Library/Application Support/XPlaneLauncher/`.

### Directory layout

Store your add-ons in their respective subdirectories inside the central folder:

```text
~/Library/Application Support/XPlaneLauncher/
├── Aircraft/   <-- Source aircraft
├── Plugins/    <-- Source plugins
├── Scenery/    <-- Source scenery packs
└── LuaScripts/ <-- Source FlyWithLua scripts
```

Aircraft may be grouped one level deep; plugins, scenery, and scripts may not:

```text
Aircraft/
├── B738/           <-- managed on its own
└── Heli/           <-- a grouping folder
    ├── AW109SP/    <-- each managed on its own
    └── EC135/
```

When applying a profile, the launcher creates symlinks in:
- `<X-Plane 12>/Aircraft`
- `<X-Plane 12>/Resources/plugins`
- `<X-Plane 12>/Custom Scenery`
- `<X-Plane 12>/Resources/plugins/FlyWithLua/Scripts`

## Scripting

You can attach shell scripts to profiles to run before X-Plane launches.

- `XLAUNCHER_PROFILE` is automatically set to the active profile name.
- Global environment variables can be configured in **Settings**.
- Per-profile environment variables can be configured in the **Profile Scripts** tab.

An example script is available in [examples/hoppie.sh](examples/hoppie.sh).

## License

MIT License. See [LICENSE](LICENSE) for details.

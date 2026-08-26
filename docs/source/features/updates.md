# Add-on Updates

X-Plane Launcher includes a built-in updater that scans your Central Data Folder for add-ons supported by **SkunkCrafts Updater** and **X-Updater**, checks for new versions, and applies updates.

---

## Enabling the Updater

The whole feature sits behind **Manage add-on updates** in **Settings**. When it is off, no
scan of the Central Data Folder runs at all and the **Updates** tab is hidden.

---

## Supported Updaters

- **SkunkCrafts Updater**: Detects `skunkcrafts_updater.cfg` or `skunkcrafts_updater.ini` configuration files.
- **X-Updater**: Detects `x-updater.json` configuration files.

---

## Checking and Installing Updates

Navigate to the **Updates** tab:

```{image} /_static/images/updates-view.png
:alt: Screenshot of the Updates tab with list of updatable add-ons, current/latest version badges, Update All button, and open console drawer
:align: center
```

### Features:
- **Scan**: Automatically scans up to five directory levels deep inside `Aircraft`, `Plugins`, `Scenery`, and `LuaScripts`. The scan runs off the main thread, so it never blocks the interface, and reads each directory exactly once.
- **Check for Updates**: Queries remote manifest servers for version comparisons.
- **Update Individual Add-ons**: Click **Update** next to any add-on with an available update.
- **Update All**: Downloads and applies all available updates in sequence.
- **Live Console**: Click the **Console** button in the header bar to view real-time download logs, HTTP responses, and file operations.

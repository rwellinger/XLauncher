# Aircraft

X-Plane Launcher lets you organize your aircraft in a central directory and link only selected airframes into your simulator.

---

## Folder Organization

Place aircraft folders into the `Aircraft` subfolder of your Central Data Folder:

```text
<Central Data Folder>/Aircraft/
├── ToLiss A321/
├── ToLiss A340-600/
└── Zibo 737-800X/
```

Each subfolder inside `Aircraft` should be a standalone aircraft folder containing the `.acf` file and related assets.

### Grouping folders

If your fleet is large, you can sort it into grouping folders one level deep:

```text
<Central Data Folder>/Aircraft/
├── Zibo 737-800X/          <-- managed on its own
└── Heli/                   <-- a grouping folder, not an aircraft
    ├── AW109SP/            <-- each managed on its own
    └── EC135/
```

A folder counts as a grouping folder when it holds no `.acf` file of its own but contains
folders that do. Its aircraft are then listed and toggled **individually**, grouped under
a collapsible header in the **Aircraft** tab — the group itself is never enabled as a
whole.

Enabling one mirrors the grouping into your simulator: X-Plane Launcher creates a real
directory `<X-Plane 12>/Aircraft/Heli/` and places one symbolic link inside it. Once the
last aircraft of a group is disabled, that directory is removed again. X-Plane searches
`Aircraft` recursively, so grouped airframes are found exactly like ungrouped ones.

:::{note}
Grouping is aircraft-only. Plugins must sit directly under `Resources/plugins`, or
X-Plane will not load them; the same flat layout applies to scenery and Lua scripts.
:::

---

## Managing Aircraft

```{image} /_static/images/aircraft-view.png
:alt: Screenshot of the Aircraft view with toggle switches, search, and link status indicators
:align: center
```

In the **Aircraft** tab:
- **Toggle switch**: Enables or disables the aircraft for the current profile.
- **Enabling an aircraft**: Creates a symbolic link from `<X-Plane 12>/Aircraft/<Folder>` pointing to `<Central Data Folder>/Aircraft/<Folder>`. For a grouped aircraft, `<Folder>` includes its group (`Heli/AW109SP`).
- **Disabling an aircraft**: Removes the symbolic link from `<X-Plane 12>/Aircraft/`. Your original aircraft files, liveries, and saved states remain safe in the central directory.
- **Deleting an aircraft**: Right-click the aircraft row and select **Delete Add-on...** to permanently delete the aircraft folder from your Central Data Folder and purge it from all profiles after confirmation.

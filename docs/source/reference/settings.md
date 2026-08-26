# Settings

This page details the options available in the **Settings** view.

```{image} /_static/images/settings-view.png
:alt: Screenshot of the Settings view with General, X-CSL Models, and Script Environment sections
:align: center
```

---

## General

- **X-Plane Location**: The folder containing your X-Plane 12 installation (where `X-Plane.app` is located). Click the folder button to change the path.
- **Central Data Folder**: The folder where your source add-ons are stored. Defaults to `~/Library/Application Support/XPlaneLauncher/`.
- **Welcome Guide**: Click **Show Welcome Screen...** to reopen the initial setup assistant.

---

## Launch

- **Block launch while the system is under heavy load**: Right after a boot, Spotlight indexing, iCloud sync, and background Shortcuts keep the machine busy, and X-Plane takes far longer to start. While the one-minute load average stays high, the launch button is disabled. A **Launch Anyway** override is always offered, so this never blocks you outright.

---

## Automatic Updates

Configure which components automatically check for new versions and updates when X-Plane Launcher starts:

- **X-Plane Launcher application**: When enabled, checks GitHub for new application versions on startup. Off by default in this fork, because the releases it finds are the original project's and do not carry this fork's changes.
- **Manage add-on updates**: Master switch for the whole add-on updater. When disabled, no scan of the Central Data Folder runs at all and the **Updates** tab disappears from the sidebar.
- **SkunkCrafts add-ons**: When enabled, queries remote servers for updates to SkunkCrafts-managed add-ons on startup.
- **X-Updater add-ons**: When enabled, queries remote servers for updates to X-Updater-managed add-ons on startup.
- **X-CSL models**: When enabled, synchronizes the package index and checks for model updates from the X-CSL repository on startup (available when X-CSL support is enabled).
- **Navigation data (Navigraph)**: When enabled, checks Navigraph for newly published AIRAC cycles on startup (available when Navigation Data support is enabled).

:::{note}
Disabling automatic checks on launch does not prevent manual checks. You can still check for updates at any time from the **Updates**, **CSL**, **Navigation Data**, or **Settings** tabs.
:::

---

## Application Updates

:::{note}
In-app updating is disabled in this fork. The update feed belongs to the original
project, so installing from it would replace your build with the upstream version.
Update by pulling the repository and running `./package.sh` again — see
[Installation](../getting-started/installation.md).
:::

- **Include pre-release and beta versions**: When enabled, checks for pre-release and beta builds on GitHub in addition to stable releases.
- **Check Now**: Manually checks GitHub for application updates immediately. This reports what the original project has published; it does not install anything.
- **What's New**: View version release notes and changelogs.

---

## X-CSL Models

- **Enable X-CSL support**: Adds the CSL tab to the sidebar for managing multiplayer aircraft models in `<X-Plane 12>/Resources/plugins/IVAO_CSL/CSL`.
- **Apply modern X-Plane 12 lighting to X-CSL models**: Injects photometric parameterized lighting, ground spill, dynamic strobe sequences, and gear-coupled taxi light animations into installed CSL aircraft models.

---

## Navigation Data

- **Enable Navigraph navdata updates**: Adds the Navigation Data tab to the sidebar for downloading and updating AIRAC cycles directly from Navigraph for X-Plane 12 and supported add-ons.

---

## Script Environment

- **Global Environment Variables**: Key-value pairs passed to pre-launch scripts across all profiles.
- **Add / Remove**: Use the `+` and `-` buttons below the table to add or remove variable entries.
- **Profile Overrides**: Variables defined in a profile's **Profile Scripts** tab override global variables with the same key name.

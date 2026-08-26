# Installation

:::{note}
This documentation describes a **fork** of
[jcorbier/x-plane-launcher](https://github.com/jcorbier/x-plane-launcher). Pre-built
binaries from the original project do not contain this fork's changes — build from
source instead.
:::

## System Requirements

- **Operating System**: macOS 14.0 (Sonoma) or macOS 15.0+ (Sequoia)
- **Architecture**: Apple Silicon (M1/M2/M3/M4) or Intel (x86_64)
- **Simulator**: X-Plane 12

---

## Pre-Built Binaries

The original project publishes `XLauncher.dmg` on its
[GitHub Releases](https://github.com/jcorbier/x-plane-launcher/releases) page. Those
builds are the upstream version and carry none of this fork's changes, so use them only
if you want the original application. Otherwise build from source as described below.

---

## Building from Source

Building from source requires Xcode or the Swift command-line tools:

```bash
xcode-select --install
```

1. Clone the repository:
   ```bash
   git clone https://github.com/rwellinger/XLauncher.git
   cd XLauncher
   ```

2. Run the packaging script:
   ```bash
   ./package.sh
   ```

3. The script compiles the executable in release mode, builds the macOS app bundle structure, copies resources, and signs the bundle.

4. Open `XLauncher.app` or move it to your `/Applications` folder:
   ```bash
   open XLauncher.app
   ```

---

## Updating

In-app self-updating is **disabled** in this fork. The update feed serves builds of the
original project, which do not carry these changes, so installing from it would roll you
back to the upstream version.

Update by pulling the repository and rebuilding:

```bash
git pull
./package.sh
```

Your settings, profiles, and add-ons live outside the application bundle and are not
affected by rebuilding.

# Installation

:::{note}
This documentation describes an independent **fork** of
[jcorbier/XLauncher](https://github.com/jcorbier/XLauncher). Pre-built binaries from
the original project do not contain this fork's changes — build from source instead.
:::

## System Requirements

- **Operating System**: macOS 14.0 (Sonoma) or macOS 15.0+ (Sequoia)
- **Architecture**: Apple Silicon (M1/M2/M3/M4) or Intel (x86_64)
- **Simulator**: X-Plane 12

---

## Pre-Built Binaries

Releases of this fork, when there are any, are published on its
[GitHub Releases](https://github.com/rwellinger/XLauncher/releases) page. Builds from the
original project carry none of this fork's changes, so build from source as described
below unless a fork release is available.

### First Launch (Gatekeeper)

Fork releases are signed ad-hoc and not notarized by Apple, so macOS blocks the first
launch of a downloaded `XLauncher.app` ("cannot be opened because Apple cannot check it
for malicious software"). After moving the app to `/Applications`, allow it once in either
of two ways:

- Open **System Settings → Privacy & Security**, scroll to the message about XLauncher
  and click **Open Anyway**.
- Or remove the quarantine flag in Terminal:
  ```bash
  xattr -dr com.apple.quarantine /Applications/XLauncher.app
  ```

A build you create yourself with `./package.sh` is not affected — only downloaded files
carry the quarantine flag.

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

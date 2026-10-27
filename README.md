# Homebrew tap for AerospaceTabs

Install the latest stable release. Both commands install the same app.

One command adds the tap and installs the app:

```sh
brew install --cask pedrotmr/aerospace-tabs/pedrotmr-aerospace-tabs
```

Or add the tap once, then install with the shorter name:

```sh
brew tap pedrotmr/aerospace-tabs
brew install --cask pedrotmr-aerospace-tabs
```

Requires macOS 14 or later and AeroSpace. Grant Accessibility permission on first launch; Screen Recording is optional for window previews.

The cask installs the universal app from the GitHub Release pinned in `Casks/pedrotmr-aerospace-tabs.rb`.

The app repository updates this cask after a stable release is published. Its workflow checks the versioned ZIP, Developer ID signature, notarization ticket, Gatekeeper result, icon, and Sparkle feed. It calculates the ZIP's SHA-256, runs `brew audit --cask --strict --online`, and pushes the cask update. Drafts and prereleases do not change the tap. This repository's CI checks pull requests and pushes to `main`; it audits a cask only when one exists.

The current v0.1.2 cask installs an app without Sparkle, so Homebrew handles its updates. A later cask may set `auto_updates true`. Sparkle can then move the app ahead of the version in the tap. Check the app version before you force a Homebrew update; Homebrew may reinstall the version in the tap. [Homebrew explains this behavior](https://docs.brew.sh/FAQ#how-does-brew-upgrade-handle-apps-that-update-themselves).

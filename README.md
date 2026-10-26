# Homebrew tap for Aerospace Tabs

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

GitHub Actions checks for a new published stable release every six hours. It validates the universal app, icon, Developer ID signature, notarization ticket, Gatekeeper result, and stable Sparkle appcast, computes the ZIP's SHA-256, audits the generated cask, and updates it. Releases without a notarized Sparkle-enabled app are ignored. You can also run **Sync Homebrew cask** manually from the repository's Actions tab.

Updates use `brew update && brew upgrade`. A Sparkle update can move the app ahead of the cask; avoid explicitly upgrading the named cask or using Homebrew's greedy flags, which may reinstall the older cask version.

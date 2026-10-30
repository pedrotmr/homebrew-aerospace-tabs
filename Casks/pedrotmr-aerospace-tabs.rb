cask "pedrotmr-aerospace-tabs" do
  version "0.4.0"
  sha256 "8c87b740789c51312ac9b71f2df681ce5b1c4c66bd0f2673065fb3322a8437f9"

  url "https://github.com/pedrotmr/aerospace-tabs/releases/download/v#{version}/AerospaceTabs-#{version}.zip"
  name "AeroSpaceTabs"
  desc "Window tabs and overview for AeroSpace"
  homepage "https://github.com/pedrotmr/aerospace-tabs"

  livecheck do
    url "https://github.com/pedrotmr/aerospace-tabs/releases/latest/download/appcast.xml"
    strategy :sparkle, &:short_version
  end

  auto_updates true
  depends_on macos: :sonoma

  app "AerospaceTabs.app"

  postflight_steps do
    run "/usr/bin/defaults",
        args:           [
          "write",
          "com.pedrotmr.AerospaceTabs.homebrew",
          "managedByHomebrew",
          "-bool",
          "true",
        ],
        writable_paths: ["Library/Preferences"],
        writable_base:  :home
    run "/usr/bin/defaults",
        args:           [
          "write",
          "com.pedrotmr.AerospaceTabs.homebrew",
          "managedByHomebrewVersion",
          "-string",
          "0.4.0",
        ],
        writable_paths: ["Library/Preferences"],
        writable_base:  :home
    run "/usr/bin/defaults",
        args:           [
          "write",
          "com.pedrotmr.AerospaceTabs.homebrew",
          "managedByHomebrewBundlePath",
          "-string",
          "{{appdir}}/AerospaceTabs.app",
        ],
        writable_paths: ["Library/Preferences"],
        writable_base:  :home
  end

  uninstall_postflight_steps do
    run "/usr/bin/defaults",
        args:           [
          "delete",
          "com.pedrotmr.AerospaceTabs.homebrew",
          "managedByHomebrew",
        ],
        must_succeed:   false,
        writable_paths: ["Library/Preferences"],
        writable_base:  :home
    run "/usr/bin/defaults",
        args:           [
          "delete",
          "com.pedrotmr.AerospaceTabs.homebrew",
          "managedByHomebrewBundlePath",
        ],
        must_succeed:   false,
        writable_paths: ["Library/Preferences"],
        writable_base:  :home
    run "/usr/bin/defaults",
        args:           [
          "delete",
          "com.pedrotmr.AerospaceTabs.homebrew",
          "managedByHomebrewVersion",
        ],
        must_succeed:   false,
        writable_paths: ["Library/Preferences"],
        writable_base:  :home
  end
end

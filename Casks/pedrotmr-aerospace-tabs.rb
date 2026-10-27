cask "pedrotmr-aerospace-tabs" do
  version "0.2.3"
  sha256 "f8e2222b8eaee553425be1be8624fa998b226ecb0c8a83f25a54504900e6f22c"

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
          "0.2.3",
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

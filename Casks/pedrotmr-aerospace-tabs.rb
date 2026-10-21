cask "pedrotmr-aerospace-tabs" do
  version "0.1.1"
  sha256 "69bbad1776bb5a49d8efcbcf8f65607bb032f3de908d5d5866b9bf5f846e2e5f"

  url "https://github.com/pedrotmr/aerospace-tabs/releases/download/v#{version}/AerospaceTabs.zip"
  name "Aerospace Tabs"
  desc "Window tabs and overview for AeroSpace"
  homepage "https://github.com/pedrotmr/aerospace-tabs"

  depends_on macos: :sonoma

  app "AerospaceTabs.app"

  caveats <<~EOS
    Requires AeroSpace to be installed and running.
    Accessibility permission enables global shortcuts and Dock notification badges.
    Screen Recording permission is optional and enables window previews.
  EOS
end

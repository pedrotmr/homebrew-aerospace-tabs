#!/usr/bin/env bash
set -euo pipefail

repo="pedrotmr/aerospace-tabs"
cask="Casks/pedrotmr-aerospace-tabs.rb"
if [[ -n "${RUNNER_TEMP:-}" ]]; then
  work_dir="$RUNNER_TEMP/aerospace-tabs-cask-sync"
else
  work_dir=$(mktemp -d "${TMPDIR:-/tmp}/aerospace-tabs-cask-sync.XXXXXX")
  trap 'rm -rf "$work_dir"' EXIT
fi
mkdir -p "$work_dir"
release_json="$work_dir/latest-release.json"
archive="$work_dir/release.zip"
extract_dir="$work_dir/extracted"
appcast="$work_dir/appcast.xml"

curl --fail --silent --show-error --location \
  "https://api.github.com/repos/$repo/releases/latest" \
  --header 'Accept: application/vnd.github+json' \
  --header 'X-GitHub-Api-Version: 2022-11-28' \
  --output "$release_json"

tag_name=$(python3 - "$release_json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as release_file:
    release = json.load(release_file)
if release.get("draft") or release.get("prerelease"):
    raise SystemExit("GitHub latest endpoint returned a draft or prerelease")
print(release["tag_name"])
PY
)
if [[ ! "$tag_name" =~ ^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; then
  echo "::error::Unexpected latest release tag: $tag_name"
  exit 1
fi
version=${tag_name#v}
asset_name="AerospaceTabs-$version.zip"
asset_url=$(python3 - "$release_json" "$asset_name" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as release_file:
    release = json.load(release_file)
asset = next((item for item in release["assets"] if item["name"] == sys.argv[2]), None)
print(asset["browser_download_url"] if asset else "")
PY
)
if [[ -z "$asset_url" && "$version" == "0.1.2" ]]; then
  echo "::notice::Latest stable release $version predates the versioned Sparkle distribution; the current cask remains unchanged."
  exit 0
fi
[[ -n "$asset_url" ]] || { echo "::error::Latest stable release is missing $asset_name."; exit 1; }

curl --fail --location --retry 3 --silent --show-error --output "$archive" "$asset_url"
rm -rf "$extract_dir"
mkdir -p "$extract_dir"
ditto -x -k "$archive" "$extract_dir"
app="$extract_dir/AerospaceTabs.app"
[[ -d "$app" ]] || { echo "::error::ZIP does not contain AerospaceTabs.app at its root."; exit 1; }

bundle_id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app/Contents/Info.plist")
app_version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist")
build_version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$app/Contents/Info.plist")
minimum_os=$(/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' "$app/Contents/Info.plist")
icon_name=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIconFile' "$app/Contents/Info.plist")
feed_url=$(/usr/libexec/PlistBuddy -c 'Print :SUFeedURL' "$app/Contents/Info.plist" 2>/dev/null || true)
public_key=$(/usr/libexec/PlistBuddy -c 'Print :SUPublicEDKey' "$app/Contents/Info.plist" 2>/dev/null || true)
[[ "$bundle_id" == "com.pedrotmr.AerospaceTabs" ]] || { echo "::error::Unexpected bundle identifier: $bundle_id"; exit 1; }
[[ "$app_version" == "$version" ]] || { echo "::error::App bundle version does not match $tag_name."; exit 1; }
[[ "$minimum_os" == "14.0" ]] || { echo "::error::Unexpected minimum macOS version: $minimum_os"; exit 1; }
if [[ "$icon_name" != *.icns ]]; then icon_path="$app/Contents/Resources/$icon_name.icns"; else icon_path="$app/Contents/Resources/$icon_name"; fi
[[ -s "$icon_path" ]] || { echo "::error::App bundle icon is missing or empty."; exit 1; }

framework="$app/Contents/Frameworks/Sparkle.framework/Versions/B"
# The old stable v0.1.2 build predates Sparkle and cannot be marked as auto-updating.
if [[ ! -x "$framework/Sparkle" || "$feed_url" != "https://github.com/pedrotmr/aerospace-tabs/releases/latest/download/appcast.xml" || -z "$public_key" ]]; then
  echo "::notice::Latest stable release $version does not contain the configured stable Sparkle updater; the cask remains unchanged."
  exit 0
fi

codesign --verify --deep --strict --verbose=2 "$app"
signature_details=$(codesign --display --verbose=4 "$app" 2>&1)
[[ "$signature_details" == *'Authority=Developer ID Application:'* ]] || { echo "::error::App is not signed with Developer ID Application."; exit 1; }
[[ "$signature_details" == *'TeamIdentifier=YW25U2BJ23'* ]] || { echo "::error::Unexpected Developer ID team."; exit 1; }
[[ "$signature_details" == *'Timestamp='* ]] || { echo "::error::App signature has no secure timestamp."; exit 1; }
[[ "$signature_details" == *'(runtime)'* ]] || { echo "::error::App signature does not enable hardened runtime."; exit 1; }
framework_root="$app/Contents/Frameworks/Sparkle.framework"
for binary in "$app/Contents/MacOS/AerospaceTabs" "$framework/Sparkle" "$framework/Autoupdate" \
  "$framework/Updater.app/Contents/MacOS/Updater"; do
  lipo -verify_arch arm64 "$binary"
  lipo -verify_arch x86_64 "$binary"
done
for component in "$framework/Autoupdate" "$framework/Updater.app" "$framework_root"; do
  codesign --verify --strict --verbose=2 "$component"
  component_signature=$(codesign --display --verbose=4 "$component" 2>&1)
  [[ "$component_signature" == *'Authority=Developer ID Application:'* && \
    "$component_signature" == *'TeamIdentifier=YW25U2BJ23'* && \
    "$component_signature" == *'Timestamp='* && "$component_signature" == *'(runtime)'* ]] || {
    echo "::error::Sparkle component has an unexpected or incomplete Developer ID signature: ${component##*/}"; exit 1;
  }
done
xcrun stapler validate "$app"
spctl --assess --type execute --verbose=2 "$app"

curl --fail --silent --show-error --location "$feed_url" --output "$appcast"
python3 - "$appcast" "$build_version" "$version" "$asset_url" "$archive" <<'PY'
import os
import sys
import xml.etree.ElementTree as ET

feed_path, expected_build, expected_version, expected_url, archive_path = sys.argv[1:]
root = ET.parse(feed_path).getroot()
item = root.find(".//item")
if item is None:
    raise SystemExit("Sparkle appcast has no update item")
values = {child.tag.split("}")[-1]: child.text or "" for child in item}
enclosure = item.find("enclosure")
if enclosure is None:
    raise SystemExit("Sparkle appcast item has no enclosure")
if values.get("version") != expected_build:
    raise SystemExit("Appcast build version does not match CFBundleVersion")
if values.get("shortVersionString") != expected_version:
    raise SystemExit("Appcast marketing version does not match the release tag")
if enclosure.attrib.get("url") != expected_url:
    raise SystemExit("Appcast URL does not match the versioned release ZIP")
if not enclosure.attrib.get("edSignature"):
    raise SystemExit("Appcast enclosure has no EdDSA signature")
if enclosure.attrib.get("length") != str(os.path.getsize(archive_path)):
    raise SystemExit("Appcast enclosure size does not match the downloaded ZIP")
PY

sha256=$(shasum -a 256 "$archive" | awk '{print $1}')
python3 - "$cask" "$version" "$sha256" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
version, sha256 = sys.argv[2:]
url = "https://github.com/pedrotmr/aerospace-tabs/releases/download/v#{version}/AerospaceTabs-#{version}.zip"
content = f'''cask "pedrotmr-aerospace-tabs" do
  version "{version}"
  sha256 "{sha256}"

  url "{url}"
  name "Aerospace Tabs"
  desc "Window tabs and overview for AeroSpace"
  homepage "https://github.com/pedrotmr/aerospace-tabs"

  livecheck do
    url "https://github.com/pedrotmr/aerospace-tabs/releases/latest/download/appcast.xml"
    strategy :sparkle, &:short_version
  end

  auto_updates true
  depends_on macos: :sonoma

  app "AerospaceTabs.app"

  postflight do
    system_command "/usr/bin/defaults", args: ["write", "com.pedrotmr.AerospaceTabs.homebrew", "managedByHomebrew", "-bool", "true"]
  end

  uninstall_postflight do
    system_command "/usr/bin/defaults", args: ["delete", "com.pedrotmr.AerospaceTabs.homebrew", "managedByHomebrew"], must_succeed: false
  end

  caveats <<~EOS
    Requires AeroSpace to be installed and running.
    Accessibility permission enables global shortcuts and Dock notification badges.
    Screen Recording permission is optional and enables window previews.
    Update with `brew update && brew upgrade`.
  EOS
end
'''
path.write_text(content)
PY

echo "Verified $asset_name with SHA-256 $sha256."

#!/usr/bin/env bash
set -euo pipefail

tap="pedrotmr/aerospace-tabs"
cask="Casks/pedrotmr-aerospace-tabs.rb"
[[ -f "$cask" ]] || { echo "error: the tap cask is missing." >&2; exit 1; }

if ! brew tap | grep -Fxq "$tap"; then
  brew tap --custom-remote "$tap" "file://$PWD"
fi

tap_dir=$(brew --repository "$tap")
mkdir -p "$tap_dir/Casks"
cp "$cask" "$tap_dir/$cask"
brew audit --cask --strict --online --tap "$tap"
brew style --cask "$tap"

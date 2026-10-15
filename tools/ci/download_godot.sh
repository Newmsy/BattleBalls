#!/usr/bin/env bash
# Downloads the Godot editor and the web export templates into ~/godot for CI.
# The Sim tests and Web jobs share this as one cache entry.
set -euo pipefail
mkdir -p ~/godot/templates && cd ~/godot
base="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable"
curl -sSfL -o godot.zip "$base/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip"
unzip -q godot.zip && mv "Godot_v${GODOT_VERSION}-stable_linux.x86_64" godot && rm godot.zip
curl -sSfL -o templates.tpz "$base/Godot_v${GODOT_VERSION}-stable_export_templates.tpz"
unzip -q -j templates.tpz 'templates/web_nothreads_*' 'templates/version.txt' -d templates && rm templates.tpz

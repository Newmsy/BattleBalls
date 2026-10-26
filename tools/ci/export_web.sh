#!/usr/bin/env bash
# Exports the web build into build/web for CI (the Web and Smoke jobs share it).
# Needs Godot and its web templates in ~/godot (tools/ci/download_godot.sh).
# Env: BUILD_SHA stamps the build; SUPABASE_URL / SUPABASE_ANON_KEY, when set,
# write the online backend config (public key only).
set -euo pipefail
mkdir -p ~/.local/share/godot/export_templates/${GODOT_VERSION}.stable
cp ~/godot/templates/* ~/.local/share/godot/export_templates/${GODOT_VERSION}.stable/
if [ -n "${BUILD_SHA:-}" ]; then echo "$BUILD_SHA" | cut -c1-7 > build_info.txt; fi

# Only the public anon/publishable key may ship in the game: anyone can
# read it out of the web build. Row-level security protects the data.
if [ -z "${SUPABASE_URL:-}" ] || [ -z "${SUPABASE_ANON_KEY:-}" ]; then
  echo "::notice::SUPABASE_URL / SUPABASE_ANON_KEY secrets not set: this build plays offline."
else
  python3 tools/ci/backend_config.py
fi

timeout 180 ~/godot/godot --headless --import || true
# Every scheduled Bracket of Legends, fought out now so phones don't have to.
timeout 300 ~/godot/godot --headless --script res://tools/bracket_results.gd
# The fight-rules fingerprint live matches pair by (sim/sim_version.gd).
timeout 120 ~/godot/godot --headless --script res://tools/sim_version.gd
mkdir -p build/web
timeout 300 ~/godot/godot --headless --export-release "Web" build/web/index.html
test -s build/web/index.wasm
# Godot 4.3's web audio copies a sound's whole buffer every time it plays
# (Sample.getAudioBuffer). Nothing writes to those buffers, so share the one
# copy: dozens of sounds a second otherwise churn memory iPhone Safari is slow
# to give back.
python3 - <<'PY'
p = "build/web/index.js"
s = open(p).read()
old = "getAudioBuffer(){return this._duplicateAudioBuffer()}"
if old in s:
    open(p, "w").write(s.replace(old, "getAudioBuffer(){return this._audioBuffer}"))
    print("Patched web audio: sounds share their buffers")
else:
    print("::warning::Godot web audio buffer patch did not apply (engine changed?)")
PY
# The live-ops schedule, served next to the game so builds can refresh it.
cp liveops/liveops.json build/web/liveops.json
# Privacy policy, terms and support pages (linked from Settings and the store listings).
cp site/*.html site/*.css build/web/
# The loading picture the page shows while the game downloads (game/web/shell.html).
cp site/loading.webp build/web/

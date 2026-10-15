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
  python3 - <<'PY'
import base64, json, os, re, sys
# The dashboard's "API URL" can carry /rest/v1; the game wants the project root.
url = re.sub(r"/(rest|auth)/v1/?$", "", os.environ["SUPABASE_URL"].strip().rstrip("/"))
key = os.environ["SUPABASE_ANON_KEY"].strip()
def fail(msg):
    print(f"::error::{msg}")
    sys.exit(1)
if not url.startswith("https://"):
    fail("SUPABASE_URL should look like https://<project>.supabase.co")
if key.startswith("sb_secret_"):
    fail("SUPABASE_ANON_KEY is a secret key. Use the publishable (or legacy anon) key; never ship a secret key.")
if not key.startswith("sb_publishable_"):
    parts = key.split(".")
    try:
        claims = json.loads(base64.urlsafe_b64decode(parts[1] + "=" * (-len(parts[1]) % 4)))
    except Exception:
        fail("SUPABASE_ANON_KEY is not a Supabase publishable or anon key")
    if claims.get("role") != "anon":
        fail(f"SUPABASE_ANON_KEY has role {claims.get('role')!r}, expected 'anon'. Never ship the service_role key.")
with open("backend_config.json", "w") as f:
    json.dump({"url": url, "anon_key": key}, f)
print("Backend config written for", url)
PY
fi

timeout 180 ~/godot/godot --headless --import || true
# Every scheduled Bracket of Legends, fought out now so phones don't have to.
timeout 300 ~/godot/godot --headless --script res://tools/bracket_results.gd
mkdir -p build/web
timeout 300 ~/godot/godot --headless --export-release "Web" build/web/index.html
test -s build/web/index.wasm
# The live-ops schedule, served next to the game so builds can refresh it.
cp liveops/liveops.json build/web/liveops.json

#!/usr/bin/env bash
# Exports the Google Play build (an .aab) into build/android for CI.
# Needs Godot + its Android templates in ~/godot (tools/ci/download_godot.sh
# with GODOT_TEMPLATES=android), an Android SDK (ANDROID_HOME) and JDK 17
# (JAVA_HOME).
# Env:
#   ANDROID_KEYSTORE_BASE64    upload keystore (.jks), base64 (repo secret)
#   ANDROID_KEYSTORE_PASSWORD  its password, also used for the key (repo secret)
#   ANDROID_KEY_ALIAS          key alias inside it (repo secret, default "upload")
#   VERSION_CODE               Play's ever-increasing build number
#   VERSION_NAME               the version players see (default 1.0.<code>)
#   BUILD_SHA, SUPABASE_URL, SUPABASE_ANON_KEY  as for the web build
# Without the keystore secrets it signs with a throwaway key: the build still
# proves it compiles, but Play won't take it.
set -euo pipefail
: "${GODOT_VERSION:?}"
: "${ANDROID_HOME:?set ANDROID_HOME to the Android SDK}"
: "${JAVA_HOME:?set JAVA_HOME to a JDK 17}"
tpl=~/.local/share/godot/export_templates/${GODOT_VERSION}.stable
mkdir -p "$tpl"
cp ~/godot/templates/* "$tpl/"
if [ -n "${BUILD_SHA:-}" ]; then echo "$BUILD_SHA" | cut -c1-7 > build_info.txt; fi
if [ -n "${SUPABASE_URL:-}" ] && [ -n "${SUPABASE_ANON_KEY:-}" ]; then
  python3 tools/ci/backend_config.py
else
  echo "::notice::SUPABASE_URL / SUPABASE_ANON_KEY not set: this build plays offline."
fi

# Where the editor finds the SDK and JDK.
for f in editor_settings-4.tres "editor_settings-${GODOT_VERSION}.tres"; do
  mkdir -p ~/.config/godot
  cat > ~/.config/godot/$f <<TRES
[gd_resource type="EditorSettings" format=3]

[resource]
export/android/android_sdk_path = "$ANDROID_HOME"
export/android/java_sdk_path = "$JAVA_HOME"
TRES
done

# Signing: the keystore never touches the repo, only this runner's temp dir.
keystore="${RUNNER_TEMP:-/tmp}/upload.jks"
alias="${ANDROID_KEY_ALIAS:-upload}"
if [ -n "${ANDROID_KEYSTORE_BASE64:-}" ] && [ -n "${ANDROID_KEYSTORE_PASSWORD:-}" ]; then
  echo "$ANDROID_KEYSTORE_BASE64" | base64 -d > "$keystore"
  pass="$ANDROID_KEYSTORE_PASSWORD"
else
  echo "::warning::ANDROID_KEYSTORE_BASE64 / ANDROID_KEYSTORE_PASSWORD not set: signing with a throwaway key Play will refuse."
  pass="throwaway-$RANDOM$RANDOM"
  rm -f "$keystore"
  "$JAVA_HOME/bin/keytool" -genkeypair -keystore "$keystore" -alias "$alias" -keyalg RSA -keysize 2048 \
    -validity 10000 -storepass "$pass" -keypass "$pass" -dname "CN=Battle Balls test" >/dev/null
fi
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$keystore"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="$alias"
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$pass"

# Version: Play needs a bigger code on every upload.
code="${VERSION_CODE:-1}"
name="${VERSION_NAME:-1.0.$code}"
sed -i "s/^version\/code=.*/version\/code=$code/; s/^version\/name=.*/version\/name=\"$name\"/" export_presets.cfg

timeout 180 ~/godot/godot --headless --import || true
timeout 300 ~/godot/godot --headless --script res://tools/bracket_results.gd
timeout 120 ~/godot/godot --headless --script res://tools/sim_version.gd

# The Gradle project Godot builds the .aab from (needed for plugins and .aab).
# Same as the editor's Project > Install Android Build Template (Godot 4.3 has
# no command-line switch for it).
rm -rf android
mkdir -p android/build
unzip -q "$tpl/android_source.zip" -d android/build
echo "${GODOT_VERSION}.stable" > android/.build_version
touch android/build/.gdignore
test -f android/build/build.gradle
tools/ci/patch_android_build.sh

mkdir -p build/android
timeout 1500 ~/godot/godot --headless --export-release "Android" build/android/battleballs.aab
test -s build/android/battleballs.aab
echo "Built build/android/battleballs.aab (version $name, code $code)"

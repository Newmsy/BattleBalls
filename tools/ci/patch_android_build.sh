#!/usr/bin/env bash
# Brings the Gradle template Godot 4.3 installs into android/build up to what
# Google Play takes today: target and compile SDK 36 (new apps and updates
# must target Android 16 since 31 Aug 2026). Godot 4.3's exporter refuses a
# Target SDK above 34 in the preset, so the template sets it instead.
set -euo pipefail
cd android/build
SDK=36
sed -i "s/compileSdk *: *34,/compileSdk         : $SDK,/; s/targetSdk *: *34,/targetSdk          : $SDK,/; s/buildTools *: *'34.0.0',/buildTools         : '$SDK.0.0',/" config.gradle
# The preset's Target SDK (34 at most in 4.3) can only raise it, never lower it.
python3 - <<'PY'
p = "config.gradle"
s = open(p).read()
start = s.index("ext.getExportTargetSdkVersion")
end = s.index("\n}\n", start) + 3
s = s[:start] + """ext.getExportTargetSdkVersion = { ->
    String targetSdkVersion = project.hasProperty("export_version_target_sdk") ? project.property("export_version_target_sdk") : ""
    try {
        return Math.max(Integer.parseInt(targetSdkVersion), versions.targetSdk)
    } catch (NumberFormatException ignored) {
        return versions.targetSdk
    }
}
""" + s[end:]
open(p, "w").write(s)
PY
grep -q "suppressUnsupportedCompileSdk" gradle.properties || echo "android.suppressUnsupportedCompileSdk=$SDK" >> gradle.properties
grep -n "compileSdk\|targetSdk\|buildTools" config.gradle | head -4

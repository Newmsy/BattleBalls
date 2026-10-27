# Writes backend_config.json (Supabase URL + public key) for a game build from
# the SUPABASE_URL / SUPABASE_ANON_KEY env vars. Shared by the web and native
# exports. Refuses secret / service_role keys: anyone can read them out of a build.
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

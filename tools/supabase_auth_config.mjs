// Keeps Supabase Auth set up the way the game expects (run by CI's migrate
// job, after the migrations). Needs SUPABASE_URL and SUPABASE_ACCESS_TOKEN;
// Apple, Google and custom email (SMTP) switch on once their secrets exist.
// No dependencies: Node 20's fetch and crypto. Never prints a secret.
//
//   Apple:  APPLE_TEAM_ID, APPLE_KEY_ID, APPLE_SERVICES_ID, APPLE_PRIVATE_KEY
//           (the .p8 file's text), optional APPLE_BUNDLE_ID for the iOS app.
//           Apple's client secret is a token that expires within 6 months, so
//           it is made fresh from the key on every run.
//   Google: GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET
//   Email:  SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, SMTP_SENDER
//
// It also keeps the test-mode account (game/online/test_user.gd) ready: it
// creates test user 1 if missing, gives it a new random password and stores
// the login in public.test_logins, where the game picks it up. The password
// never touches the repo or the log.
//
// `--dry-run` prints which settings would change (names only) and exits.
import { createPrivateKey, randomBytes, sign } from "node:crypto";

const env = process.env;
const dryRun = process.argv.includes("--dry-run");
const SITE = "https://battleballs.vercel.app";
// Where emailed links and Apple/Google may send players back to (with their
// session): the live site and this project's own Vercel previews only.
const ALLOW = [`${SITE}/**`, "https://battleballs-*-invokers1.vercel.app/**"];

const has = (...names) => names.every((n) => (env[n] || "").trim() !== "");
const b64url = (buf) => Buffer.from(buf).toString("base64").replace(/=+$/, "").replace(/\+/g, "-").replace(/\//g, "_");

export function appleClientSecret({ teamId, keyId, servicesId, privateKey, now = Math.floor(Date.now() / 1000) }) {
  const header = { alg: "ES256", kid: keyId, typ: "JWT" };
  // Apple allows up to 6 months; 150 days leaves room if CI doesn't run for a while.
  const payload = { iss: teamId, iat: now, exp: now + 150 * 86400, aud: "https://appleid.apple.com", sub: servicesId };
  const input = `${b64url(JSON.stringify(header))}.${b64url(JSON.stringify(payload))}`;
  const key = createPrivateKey(privateKey.replace(/\\n/g, "\n"));
  const sig = sign("sha256", Buffer.from(input), { key, dsaEncoding: "ieee-p1363" });
  return `${input}.${b64url(sig)}`;
}

const code = (what) => `<h2>Your BattleBalls code</h2>
<p>Enter this code in the game to ${what}:</p>
<p style="font-size:32px;font-weight:bold;letter-spacing:6px">{{ .Token }}</p>
<p>Or tap <a href="{{ .ConfirmationURL }}">this link</a> on the device you're playing on.</p>
<p>If you didn't ask for this, you can ignore this email.</p>`;

export function authSettings() {
  const s = {
    site_url: SITE,
    uri_allow_list: ALLOW.join(","),
    external_anonymous_users_enabled: true,
    security_manual_linking_enabled: true, // A guest links Apple/Google to the same account.
    external_email_enabled: true,
    mailer_otp_length: 6,
    mailer_otp_exp: 3600,
    mailer_secure_email_change_enabled: false, // A guest has no old address to confirm.
  };
  const on = ["email"];
  if (has("APPLE_TEAM_ID", "APPLE_KEY_ID", "APPLE_SERVICES_ID", "APPLE_PRIVATE_KEY")) {
    Object.assign(s, {
      external_apple_enabled: true,
      external_apple_client_id: env.APPLE_SERVICES_ID.trim(),
      external_apple_secret: appleClientSecret({
        teamId: env.APPLE_TEAM_ID.trim(), keyId: env.APPLE_KEY_ID.trim(),
        servicesId: env.APPLE_SERVICES_ID.trim(), privateKey: env.APPLE_PRIVATE_KEY,
      }),
    });
    if (has("APPLE_BUNDLE_ID")) s.external_apple_additional_client_ids = env.APPLE_BUNDLE_ID.trim();
    on.push("apple");
  }
  if (has("GOOGLE_CLIENT_ID", "GOOGLE_CLIENT_SECRET")) {
    Object.assign(s, {
      external_google_enabled: true,
      external_google_client_id: env.GOOGLE_CLIENT_ID.trim(),
      external_google_secret: env.GOOGLE_CLIENT_SECRET.trim(),
    });
    on.push("google");
  }
  if (has("SMTP_HOST", "SMTP_USER", "SMTP_PASS", "SMTP_SENDER")) {
    Object.assign(s, {
      smtp_host: env.SMTP_HOST.trim(),
      smtp_port: (env.SMTP_PORT || "587").trim(),
      smtp_user: env.SMTP_USER.trim(),
      smtp_pass: env.SMTP_PASS,
      smtp_admin_email: env.SMTP_SENDER.trim(),
      smtp_sender_name: "BattleBalls",
      rate_limit_email_sent: 60,
      // Supabase only lets a project change its email subjects and templates
      // once it sends through its own SMTP (the free tier's built-in mailer
      // refuses them), so the code emails ride along with the SMTP settings.
      mailer_subjects_magic_link: "Your BattleBalls sign-in code",
      mailer_templates_magic_link_content: code("sign in"),
      mailer_subjects_email_change: "Your BattleBalls code to save your progress",
      mailer_templates_email_change_content: code("save your progress"),
    });
    on.push("smtp");
  } else {
    console.log("::notice::No SMTP secrets: Supabase's built-in mailer sends its default emails (no custom code templates).");
  }
  return { settings: s, on };
}

async function main() {
  const { settings, on } = authSettings();
  console.log(`Auth: ${on.join(", ")} on; settings: ${Object.keys(settings).join(", ")}`);
  if (dryRun) return;
  const ref = (env.SUPABASE_URL || "").match(/https:\/\/([a-z0-9]+)\.supabase\.co/)?.[1];
  if (!ref || !has("SUPABASE_ACCESS_TOKEN")) {
    console.log("::notice::Supabase secrets not set: auth settings not applied.");
    return;
  }
  const res = await fetch(`https://api.supabase.com/v1/projects/${ref}/config/auth`, {
    method: "PATCH",
    headers: { Authorization: `Bearer ${env.SUPABASE_ACCESS_TOKEN.trim()}`, "Content-Type": "application/json" },
    body: JSON.stringify(settings),
  });
  if (!res.ok) {
    // The reply can echo field names, never our values.
    console.log(`::error::Updating Supabase auth settings failed: HTTP ${res.status} ${(await res.text()).slice(0, 300)}`);
    process.exit(1);
  }
  console.log("Supabase auth settings applied.");
  // A problem here must not stop deploys: the game falls back to guests.
  try {
    await ensureTestAccounts(ref);
  } catch (e) {
    console.log(`::warning::Test account not refreshed: ${String(e.message).slice(0, 200)}`);
  }
}

const TEST_SLOTS = [1]; // game/online/test_user.gd ID

// The project's server key, read with the access token and kept in memory.
async function serverKey(ref) {
  const res = await fetch(`https://api.supabase.com/v1/projects/${ref}/api-keys?reveal=true`, {
    headers: { Authorization: `Bearer ${env.SUPABASE_ACCESS_TOKEN.trim()}` },
  });
  if (!res.ok) throw new Error(`api-keys HTTP ${res.status}`);
  const keys = await res.json();
  const key = keys.find((k) => k.name === "service_role")?.api_key ?? keys.find((k) => k.type === "secret")?.api_key;
  if (!key || key.includes("·")) throw new Error("no server key returned");
  return key;
}

export function serverHeaders(key) {
  // New secret keys go in apikey only; the legacy service_role JWT in both.
  const h = { apikey: key, "Content-Type": "application/json" };
  if (!key.startsWith("sb_secret_")) h.Authorization = `Bearer ${key}`;
  return h;
}

export const testEmail = (slot) => `test-user-${slot}@example.com`;

export async function ensureTestAccounts(ref) {
  const base = `https://${ref}.supabase.co`;
  const headers = serverHeaders(await serverKey(ref));
  const call = async (method, path, body) => {
    const res = await fetch(base + path, { method, headers: { ...headers, Prefer: "resolution=merge-duplicates,return=representation" }, body: body && JSON.stringify(body) });
    const text = await res.text();
    let data = null;
    try { data = text ? JSON.parse(text) : null; } catch { /* not JSON: status says enough */ }
    return { status: res.status, ok: res.ok, data };
  };
  const known = await call("GET", "/rest/v1/test_logins?select=slot,user_id");
  if (!known.ok) throw new Error(`test_logins HTTP ${known.status}`);
  for (const slot of TEST_SLOTS) {
    const email = testEmail(slot);
    const password = randomBytes(24).toString("base64url");
    let id = known.data.find((r) => r.slot === slot)?.user_id;
    let res = id ? await call("PUT", `/auth/v1/admin/users/${id}`, { password, email_confirm: true }) : { ok: false, status: 404 };
    if (!res.ok) {
      res = await call("POST", "/auth/v1/admin/users", { email, password, email_confirm: true, user_metadata: { test_user: slot } });
      if (res.ok) id = res.data.id;
    }
    if (!res.ok) {
      // Made before its login was stored: find it by email.
      const list = await call("GET", "/auth/v1/admin/users?page=1&per_page=1000");
      id = list.data?.users?.find((u) => u.email === email)?.id;
      if (!id) throw new Error(`creating ${email} HTTP ${res.status}`);
      res = await call("PUT", `/auth/v1/admin/users/${id}`, { password, email_confirm: true });
      if (!res.ok) throw new Error(`updating ${email} HTTP ${res.status}`);
    }
    const saved = await call("POST", "/rest/v1/test_logins?on_conflict=slot", { slot, user_id: id, email, password, updated_at: new Date().toISOString() });
    if (!saved.ok) throw new Error(`storing test login HTTP ${saved.status}`);
    console.log(`Test user ${slot} ready (${email}).`);
  }
}

if (import.meta.url === `file://${process.argv[1]}`) await main();

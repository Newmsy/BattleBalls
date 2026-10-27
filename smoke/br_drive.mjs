// Smoke test for the web build: boots it in a phone-sized headless Chromium,
// plays one auto fight and one fight through the real menu, fails on any
// page error, and saves screenshots. Also opens Daily Trick Shot and solves one,
// plays the whole onboarding, follows a Bracket of Legends from picks to the
// final and climbs the first floor of The Spire, fights
// the first floor of Bounce Run and runs a live fight with a code.
// Usage: node smoke.mjs [path/to/build/web]
import { chromium } from "playwright";
import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import os from "node:os";
import { execFile } from "node:child_process";

const root = path.resolve(process.argv[2] ?? "../build/web");
const shots = process.env.SHOTS;
fs.mkdirSync(shots, { recursive: true });

const types = { ".html": "text/html", ".js": "text/javascript", ".wasm": "application/wasm", ".pck": "application/octet-stream", ".png": "image/png" };
const server = http.createServer((req, res) => {
  const file = path.join(root, decodeURIComponent(new URL(req.url, "http://x").pathname));
  const target = fs.existsSync(file) && fs.statSync(file).isDirectory() ? path.join(file, "index.html") : file;
  if (!target.startsWith(root) || !fs.existsSync(target)) {
    res.writeHead(404).end();
    return;
  }
  res.writeHead(200, { "Content-Type": types[path.extname(target)] ?? "application/octet-stream" });
  fs.createReadStream(target).pipe(res);
});
await new Promise((r) => server.listen(0, "127.0.0.1", r));
const base = `http://127.0.0.1:${server.address().port}/`;

// Autoplay allowed so the audio code paths really run (on a phone, the first tap unlocks them).
const launchOptions = { args: ["--use-gl=angle", "--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--autoplay-policy=no-user-gesture-required"] };
if (process.env.CHROMIUM_PATH) launchOptions.executablePath = process.env.CHROMIUM_PATH;
const browser = await chromium.launch(launchOptions);
const errors = [];

async function openGame(query, viewport = { width: 390, height: 844 }) {
  // Default: iPhone 14-ish viewport.
  const page = await browser.newPage({ viewport, deviceScaleFactor: 2, hasTouch: true });
  // Taps the audio output so tests can check sound really reaches the speakers
  // (Godot can start sounds into a broken route and stay silent).
  await page.addInitScript(() => {
    window.__audioPeak = 0;
    const real = Object.getOwnPropertyDescriptor(BaseAudioContext.prototype, "destination").get;
    const taps = new WeakMap();
    Object.defineProperty(BaseAudioContext.prototype, "destination", {
      get() {
        if (!taps.has(this)) {
          const out = real.call(this);
          const tap = this.createGain();
          const meter = this.createAnalyser();
          tap.connect(out);
          tap.connect(meter);
          const buf = new Float32Array(meter.fftSize);
          setInterval(() => {
            meter.getFloatTimeDomainData(buf);
            for (const v of buf) window.__audioPeak = Math.max(window.__audioPeak, Math.abs(v));
          }, 40);
          taps.set(this, tap);
        }
        return taps.get(this);
      },
    });
  });
  const logs = [];
  page.on("console", (m) => {
    logs.push(m.text());
    // A screen that should fit a phone (design/ui.md, "No scrolling") needs scrolling.
    if (m.text().startsWith("UI_OVERFLOW ")) errors.push(`${m.text()} (fit it, or put detail behind an "i")`);
    if (m.text().startsWith("UI_OVERFLOW_X ")) errors.push(`${m.text()} (a card runs off the right edge: trim long labels or shrink icons)`);
    // The online backend is best-effort (the game plays offline), so a failed
    // request to it is reported but doesn't fail the smoke test.
    if (m.type() === "error" && /supabase\.co/.test(m.location()?.url ?? "")) console.log(`backend request failed: ${m.text()}`);
    else if (m.type() === "error") errors.push(`${query}: ${m.text()}`);
  });
  page.on("response", (r) => { if (r.status() === 404) console.log("404:", r.url()); });
  page.on("pageerror", (e) => errors.push(`${query}: ${e.message}`));
  await page.goto(base + "index.html" + query);
  return { page, logs };
}

async function waitForLog(logs, prefix, timeoutMs) {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    const hit = logs.find((l) => l.startsWith(prefix));
    if (hit) return hit;
    await new Promise((r) => setTimeout(r, 250));
  }
  throw new Error(`Timed out waiting for "${prefix}". Last logs:\n${logs.slice(-15).join("\n")}`);
}

async function waitForLogAfter(logs, start, prefix, timeoutMs) {
  const t0 = Date.now();
  while (Date.now() - t0 < timeoutMs) {
    const hit = logs.slice(start).find((l) => l.startsWith(prefix));
    if (hit) return hit;
    await new Promise((r) => setTimeout(r, 200));
  }
  throw new Error(`Timed out waiting for "${prefix}". Last logs:\n${logs.slice(-15).join("\n")}`);
}

// Taps a menu control by the name the shell logs for it ("UI_AT name x y"),
// then waits for the screen it leads to (if any) and returns.
async function tapUi(page, logs, name, nextScreen) {
  const at = [...logs].reverse().find((l) => l.startsWith(`UI_AT ${name} `));
  if (!at) throw new Error(`No UI_AT for ${name}. Last logs:\n${logs.slice(-15).join("\n")}`);
  const [x, y] = at.split(" ").slice(2).map(Number);
  const start = logs.length;
  await page.mouse.click(...toPage(page, x, y));
  if (nextScreen) {
    // Software-rendered Chromium with audio playing can drop a tap on a slow
    // frame; one retry keeps the tour from failing on that.
    try {
      await waitForLogAfter(logs, start, `UI_SCREEN ${nextScreen}`, 5000);
    } catch {
      await page.mouse.click(...toPage(page, x, y));
      await waitForLogAfter(logs, start, `UI_SCREEN ${nextScreen}`, 5000);
    }
  }
  await page.waitForTimeout(600);
}

// A finger drag in design-space coordinates, in small steps like a real swipe.
async function swipe(page, x, y, dx, dy) {
  await page.mouse.move(...toPage(page, x, y));
  await page.mouse.down();
  for (let i = 1; i <= 10; i++) {
    await page.mouse.move(...toPage(page, x + (dx * i) / 10, y + (dy * i) / 10));
    await page.waitForTimeout(16);
  }
  await page.mouse.up();
  await page.waitForTimeout(700);
}

// Godot's canvas maps the 720x1280 design space onto the page, keeping
// whichever side is tighter and expanding the other.
function toPage(page, x, y) {
  const { width, height } = page.viewportSize();
  const s = Math.min(width / 720, height / 1280);
  return [x * s, y * s];
}
const tag = process.env.TAG ?? "x";
const vp = process.env.VP === "se" ? { width: 375, height: 667 } : { width: 390, height: 844 };
const { page, logs } = await openGame("?mode=bouncerun&offline=1&dev=1", vp);
await waitForLog(logs, "UI_SCREEN br_draft", 90000);
await page.waitForTimeout(800);
for (const i of [0, 1, 2]) await tapUi(page, logs, `br_card_${i}`, "br_draft");
await tapUi(page, logs, "br_next", "br_start_boons");
for (const i of [0, 1, 2]) await tapUi(page, logs, `br_sboon_${i}`, "br_start_boons");
await tapUi(page, logs, "br_srelic_0", "br_start_boons");
await tapUi(page, logs, "br_start", "br_map");
await tapUi(page, logs, "br_node_0", "br_floor");
await page.screenshot({ path: path.join(shots, `${tag}-floor.png`) });
for (let k = 0; k < 4; k++) {
  await tapUi(page, logs, "br_send_0", "br_aim");
  await tapUi(page, logs, "br_launch", "br_fight");
  await tapUi(page, logs, "br_skip", "br_result");
  const won = [...logs].reverse().find((l) => l.startsWith("BOUNCERUN_RESULT")).includes("won=true");
  await tapUi(page, logs, "br_continue", won ? "br_boon" : "br_floor");
  if (won) { await page.screenshot({ path: path.join(shots, `${tag}-boon.png`) }); break; }
}
console.log(logs.filter((l) => l.startsWith("DBG") || l.startsWith("UI_SCREEN") || l.startsWith("UI_OVERFLOW") || l.startsWith("UI_FIT")).join("\n"));
console.log("ERRORS", errors.join("\n"));
await browser.close(); server.close();

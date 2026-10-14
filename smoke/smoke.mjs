// Smoke test for the web build: boots it in a phone-sized headless Chromium,
// plays one auto fight and one fight through the real menu, fails on any
// page error, and saves screenshots.
// Usage: node smoke.mjs [path/to/build/web]
import { chromium } from "playwright";
import http from "node:http";
import fs from "node:fs";
import path from "node:path";

const root = path.resolve(process.argv[2] ?? "../build/web");
const shots = path.resolve("screenshots");
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
  const logs = [];
  page.on("console", (m) => {
    logs.push(m.text());
    if (m.type() === "error") errors.push(`${query}: ${m.text()}`);
  });
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

// Godot's canvas maps the 720x1280 design space onto the page, keeping
// whichever side is tighter and expanding the other.
function toPage(page, x, y) {
  const { width, height } = page.viewportSize();
  const s = Math.min(width / 720, height / 1280);
  return [x * s, y * s];
}

try {
  // 1. Auto fight from URL params runs to a result.
  {
    const { page, logs } = await openGame("?p1=vampire&p2=vampire&seed=7&auto=1&speed=4");
    await waitForLog(logs, "BOOT_OK", 60000);
    await page.waitForTimeout(3000);
    await page.screenshot({ path: path.join(shots, "1-fight.png") });
    const end = await waitForLog(logs, "MATCH_END", 90000);
    console.log("auto fight:", end);
    await page.waitForTimeout(500);
    await page.screenshot({ path: path.join(shots, "2-result.png") });
    await page.close();
  }

  // 2. Real flow: menu -> FIGHT! -> drag to aim -> fight runs.
  {
    const { page, logs } = await openGame("?seed=7");
    await waitForLog(logs, "BOOT_OK", 60000);
    await page.waitForTimeout(1500);
    await page.screenshot({ path: path.join(shots, "3-menu.png") });
    // Layout: arena 680px at y=190, controls start at 190+680+120=990.
    // Menu rows: label, ball row, label, opponent row, seed row, FIGHT! (last).
    await page.mouse.click(...toPage(page, 360, 990 + 5 * 14 + 2 * 36 + 3 * 84 + 42 + 20));
    await page.waitForTimeout(800);
    await page.screenshot({ path: path.join(shots, "4-aim.png") });
    // Drag from the player's corner toward the top middle.
    const [sx, sy] = toPage(page, 20 + 170 * 0.68, 190 + 830 * 0.68);
    const [ex, ey] = toPage(page, 360, 300);
    await page.mouse.move(sx, sy);
    await page.mouse.down();
    await page.mouse.move(ex, ey, { steps: 8 });
    await page.mouse.up();
    console.log("menu fight:", await waitForLog(logs, "FIGHT_START", 5000));
    await page.waitForTimeout(3000);
    await page.screenshot({ path: path.join(shots, "5-flow-fight.png") });
    await page.close();
  }

  // 3. Wide screen: controls sit beside the arena and FIGHT! is reachable.
  {
    const { page, logs } = await openGame("?seed=7", { width: 1376, height: 1263 });
    await waitForLog(logs, "BOOT_OK", 60000);
    await page.waitForTimeout(1500);
    await page.screenshot({ path: path.join(shots, "6-wide-menu.png") });
    // Visible area is 1394x1280: arena 614px at x=30, panel at x=684, FIGHT! at the panel's bottom.
    await page.mouse.click(...toPage(page, 684 + 340, 190 + 100 + 478 - 42));
    await page.waitForTimeout(800);
    await page.mouse.click(...toPage(page, 684 + 170, 190 + 100 + 42)); // Launch
    console.log("wide menu:", await waitForLog(logs, "FIGHT_START", 5000));
    await page.waitForTimeout(1500);
    await page.screenshot({ path: path.join(shots, "7-wide-fight.png") });
    await page.close();
  }

  // 4. Sound board opens over the menu and its buttons play without errors.
  {
    const { page, logs } = await openGame("?sounds=1");
    await waitForLog(logs, "BOOT_OK", 60000);
    await page.waitForTimeout(1500);
    for (const y of [140, 230, 320, 410]) {
      await page.mouse.click(...toPage(page, 180, y));
      await page.mouse.click(...toPage(page, 540, y));
      await page.waitForTimeout(200);
    }
    await page.screenshot({ path: path.join(shots, "8-sound-board.png") });
    await page.close();
  }

  // 5. Chaos Weekend modifier from the URL reaches the sim and the report code.
  {
    const { page, logs } = await openGame("?p1=vampire&p2=laser&seed=7&auto=1&speed=4&mod=big_head");
    await waitForLog(logs, "BOOT_OK", 60000);
    const start = await waitForLog(logs, "FIGHT_START", 5000);
    if (!start.endsWith(".big_head")) throw new Error(`modifier missing from report code: ${start}`);
    await page.waitForTimeout(3000);
    await page.screenshot({ path: path.join(shots, "9-big-head.png") });
    console.log("modifier fight:", await waitForLog(logs, "MATCH_END", 90000));
    await page.close();
  }
} catch (e) {
  errors.push(String(e.stack ?? e));
} finally {
  await browser.close();
  server.close();
}

if (errors.length) {
  console.error("Smoke test FAILED:\n" + errors.join("\n"));
  process.exit(1);
}
console.log(`Smoke test passed. Screenshots in ${shots}`);

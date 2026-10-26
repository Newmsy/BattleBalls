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

// SMOKE_SHARD=k/n runs only this machine's share of the cases below, so CI can
// spread the test over n machines. Each case's weight is about its seconds in
// CI; cases go, in order, to the least-loaded shard, so every shard computes the
// same split. No SMOKE_SHARD runs everything.
const [shardK, shardN] = (process.env.SMOKE_SHARD ?? "1/1").split("/").map(Number);
if (!(shardN >= 1 && shardK >= 1 && shardK <= shardN)) throw new Error(`Bad SMOKE_SHARD: ${process.env.SMOKE_SHARD}`);
const shardLoad = new Array(shardN).fill(0);
function mine(weight) {
  const least = shardLoad.indexOf(Math.min(...shardLoad));
  shardLoad[least] += weight;
  return least === shardK - 1;
}

try {
  // 1. Auto fight from URL params runs to a result.
  if (mine(20)) {
    const { page, logs } = await openGame("?p1=vampire&p2=vampire&seed=7&auto=1&speed=4&offline=1");
    await waitForLog(logs, "BOOT_OK", 60000);
    await page.waitForTimeout(3000);
    await page.screenshot({ path: path.join(shots, "1-fight.png") });
    const end = await waitForLog(logs, "MATCH_END", 90000);
    console.log("auto fight:", end);
    const peak = await page.evaluate(() => window.__audioPeak);
    console.log("audio peak:", peak.toFixed(3));
    if (!(peak > 0.02)) errors.push(`auto fight was silent (audio peak ${peak})`);
    await page.waitForTimeout(500);
    await page.screenshot({ path: path.join(shots, "2-result.png") });
    await page.close();
  }

  // 1a. Determinism probe: the web build must play a varied set of fights
  // exactly like headless Godot (sim/probe.gd), or two players' phones could
  // see different fights. Needs Godot (GODOT, or ~/godot/godot as in CI).
  if (mine(40)) {
    const godot = process.env.GODOT ?? path.join(os.homedir(), "godot", "godot");
    const native = new Promise((resolve, reject) => execFile(godot, ["--headless", "--script", "res://tools/probe.gd"],
      { cwd: path.resolve(".."), maxBuffer: 1 << 20 }, (err, out) => (err ? reject(err) : resolve(out))));
    const { page, logs } = await openGame("?probe=1&offline=1");
    const web = (await waitForLog(logs, "PROBE ", 180000)).split(" ");
    const want = (await native).split("\n").find((l) => l.startsWith("PROBE ")).split(" ");
    console.log(`probe: web ${web[1].slice(0, 16)} (${web[3]}), headless ${want[1].slice(0, 16)} (${want[3]})`);
    if (web[1] !== want[1]) errors.push(`web build plays fights differently from headless Godot (probe ${web[1]} vs ${want[1]}): something in sim/ depends on the platform`);
    await page.close();
  }

  // 1c. Live Quick fight: two browsers meet on a local live server
  // (server/live_server.gd, dev sign-in), aim, and each replays the server's
  // fight. Both must agree with the server and see opposite results.
  if (mine(70)) {
    const godot = process.env.GODOT ?? path.join(os.homedir(), "godot", "godot");
    const port = 18090;
    const live = execFile(godot, ["--headless", "--script", "res://server/live_server.gd"],
      { cwd: path.resolve(".."), env: { ...process.env, LIVE_DEV: "1", PORT: String(port) } });
    try {
      const q = `&live=ws://127.0.0.1:${port}&auto=1&speed=4&offline=1&tutorial=0`;
      const a = await openGame("?p1=vampire" + q);
      const b = await openGame("?p1=spiker" + q); // Same rarity and tier: a rarity step (x1.25) is outside the band until the ghost fallback.
      const ends = await Promise.all([a, b].map(({ logs }) => waitForLog(logs, "LIVE_END ", 150000)));
      console.log("live fight:", ends.join(" | "));
      await a.page.screenshot({ path: path.join(shots, "1c-live.png") });
      for (const e of ends) if (!e.startsWith("LIVE_END ok")) errors.push(`live fight differs from the server's: ${e}`);
      const side = (e) => Number(/side=(\d)/.exec(e)[1]);
      if (side(ends[0]) === side(ends[1])) errors.push(`both live players got the same side: ${ends.join(" | ")}`);
      await a.page.close();
      await b.page.close();
      // Friends with a live code: one makes it, the other types it in, and
      // they meet in their own room, away from the open queue.
      const rq = `&demo=friends&offline=1&tutorial=0&speed=4&live=ws://127.0.0.1:${port}`;
      const host = await openGame("?f=RBNW-XYZ2&p1=vampire" + rq);
      const guest = await openGame("?f=RBNW-XYZ2&p1=laser" + rq);
      for (const g of [host, guest]) await waitForLog(g.logs, "UI_SCREEN friends", 60000);
      await tapUi(host.page, host.logs, "live_code", "sheet");
      await tapUi(host.page, host.logs, "live_make");
      const code = (await waitForLog(host.logs, "LIVE_ROOM ", 10000)).split(":").pop();
      await waitForLog(host.logs, "LIVE_QUEUED", 15000);
      await host.page.screenshot({ path: path.join(shots, "1d-live-code-wait.png") });
      guest.page.once("dialog", (d) => d.accept(code));
      await tapUi(guest.page, guest.logs, "live_code", "sheet");
      await tapUi(guest.page, guest.logs, "live_join");
      const roomEnds = await Promise.all([host, guest].map(({ logs }) => waitForLog(logs, "LIVE_END ", 150000)));
      console.log("live code fight:", code, roomEnds.join(" | "));
      for (const e of roomEnds) if (!e.startsWith("LIVE_END ok")) errors.push(`live code fight differs from the server's: ${e}`);
      await host.page.close();
      await guest.page.close();
    } finally {
      live.kill();
    }
  }

  // 1b. Season 1 debut: Flux (Magnet) fights Optic; its field rings and poles render.
  if (mine(24)) {
    const { page, logs } = await openGame("?p1=magnet&p2=laser&seed=42&auto=1&speed=2");
    await waitForLog(logs, "BOOT_OK", 60000);
    await page.waitForTimeout(2500);
    await page.screenshot({ path: path.join(shots, "1b-flux.png") });
    console.log("flux fight:", await waitForLog(logs, "MATCH_END", 90000));
    await page.close();
  }

  // 2. Real flow: home -> menus tour -> fuse -> quick fight -> FIGHT! -> drag to aim -> fight runs. Only this case
  // goes online (signs in a guest) when the build has a backend. demo=1 gives the
  // filled-in sample profile, so there is something to fuse, equip and summon.
  if (mine(115)) {
    const { page, logs } = await openGame("?seed=7&demo=1&quickfight=1");
    await waitForLog(logs, "BOOT_OK", 60000);
    await waitForLog(logs, "UI_SCREEN play", 10000);
    await page.waitForTimeout(1500);
    await page.screenshot({ path: path.join(shots, "3a-home.png") });
    await tapUi(page, logs, "tab_critters", "critters");
    await page.screenshot({ path: path.join(shots, "3b-critters.png") });
    // A drag that starts on a critter card scrolls the list (and doesn't open the card).
    {
      const before = logs.length;
      await swipe(page, 360, 700, 0, -400);
      // A short collection fits on one screen and doesn't scroll (so doesn't re-report); either way no card opens.
      await waitForLogAfter(logs, before, "UI_SCREEN critters", 5000).catch(() => {});
      if (logs.slice(before).some((l) => l.startsWith("UI_SCREEN detail"))) errors.push("a scroll drag opened a critter card");
      await page.screenshot({ path: path.join(shots, "3b2-critters-scrolled.png") });
      await swipe(page, 360, 500, 0, 600);
    }
    await tapUi(page, logs, "tile_vampire", "detail");
    await page.screenshot({ path: path.join(shots, "3c-detail.png") });
    // Swiping in from the left edge goes back to the list, then reopen the card.
    {
      const before = logs.length;
      // Held halfway: the card follows the finger over the list (TouchInput slide).
      await page.mouse.move(...toPage(page, 4, 700));
      await page.mouse.down();
      for (let i = 1; i <= 10; i++) {
        await page.mouse.move(...toPage(page, 4 + 26 * i, 700));
        await page.waitForTimeout(16);
      }
      await page.waitForTimeout(300);
      await page.screenshot({ path: path.join(shots, "3c1-swipe-back.png") });
      for (let i = 1; i <= 6; i++) {
        await page.mouse.move(...toPage(page, 264 + 26 * i, 700));
        await page.waitForTimeout(16);
      }
      await page.mouse.up();
      await waitForLogAfter(logs, before, "UI_SCREEN critters", 5000);
      console.log("edge swipe: detail -> critters");
      await tapUi(page, logs, "tile_vampire", "detail");
    }
    // Faction talent trees: the grid, one tree, a suggested fill and back out.
    await tapUi(page, logs, "tab_critters", "critters");
    await tapUi(page, logs, "factions", "factions");
    await page.screenshot({ path: path.join(shots, "3c2-factions.png") });
    await tapUi(page, logs, "faction_spooky", "faction");
    await tapUi(page, logs, "talent_suggest", "faction");
    await page.screenshot({ path: path.join(shots, "3c3-faction-tree.png") });
    await tapUi(page, logs, "back", "factions");
    await tapUi(page, logs, "back", "critters");
    await tapUi(page, logs, "tab_fuse", "fuse");
    await page.screenshot({ path: path.join(shots, "3d-fuse.png") });
    const before = logs.length;
    await tapUi(page, logs, "fuse");
    console.log("fusion:", await waitForLogAfter(logs, before, "UI_FUSED", 5000));
    // What changed pops up once the new critter is out (UpgradePopup).
    await waitForLogAfter(logs, before, "UI_SCREEN sheet", 5000);
    await page.waitForTimeout(400);
    await page.screenshot({ path: path.join(shots, "3e-fused.png") });
    await tapUi(page, logs, "fuse_done", "fuse");
    await tapUi(page, logs, "tab_bag", "bag");
    await tapUi(page, logs, "gear_5", "sheet");
    await page.screenshot({ path: path.join(shots, "3f-bag-sheet.png") });
    await tapUi(page, logs, "gear_equip", "sheet");
    await tapUi(page, logs, "pick_juggernaut", "bag");
    await page.screenshot({ path: path.join(shots, "3g-bag.png") });
    // Three 1-star Bubble Shells now: Merge all makes a 2-star (design/gear.md).
    const merging = logs.length;
    await tapUi(page, logs, "merge_all", "bag");
    await waitForLogAfter(logs, merging, "UI_SCREEN sheet", 5000);
    await page.waitForTimeout(400);
    await page.screenshot({ path: path.join(shots, "3g-bag-merged.png") });
    await tapUi(page, logs, "merge_done");
    await tapUi(page, logs, "tab_summon", "summon");
    await page.screenshot({ path: path.join(shots, "3h-summon.png") });
    await tapUi(page, logs, "wishlist_edit", "sheet");
    await tapUi(page, logs, "wish_laser");
    await tapUi(page, logs, "wish_blackhole");
    await page.waitForTimeout(300);
    await page.screenshot({ path: path.join(shots, "3h2-wishlist-picker.png") });
    await tapUi(page, logs, "wishlist_done", "summon");
    await page.screenshot({ path: path.join(shots, "3h3-wishlist.png") });
    await tapUi(page, logs, "pull10", "reveal");
    // A tap anywhere opens every egg at once; then Again x10 summons the same again.
    await page.mouse.click(...toPage(page, 360, 260));
    await page.waitForTimeout(2000);
    await page.screenshot({ path: path.join(shots, "3i-reveal.png") });
    await tapUi(page, logs, "reveal_done", "summon");
    // The sample's 14 eggs leave 4: a x1, then Again x1 from the reveal.
    await tapUi(page, logs, "pull1", "reveal");
    await page.mouse.click(...toPage(page, 360, 260));
    await page.waitForTimeout(800);
    const againAt = logs.length;
    await tapUi(page, logs, "summon_again");
    console.log("summon again:", await waitForLogAfter(logs, againAt, "UI_SUMMON", 5000));
    await page.mouse.click(...toPage(page, 360, 260));
    await page.waitForTimeout(800);
    await page.screenshot({ path: path.join(shots, "3i2-reveal-again.png") });
    await tapUi(page, logs, "reveal_done", "summon");
    // Accessibility settings: open the sheet, try Larger text, then put it back.
    await tapUi(page, logs, "settings", "sheet");
    await page.screenshot({ path: path.join(shots, "3j-settings.png") });
    await tapUi(page, logs, "a11y_large_text", "sheet");
    await page.screenshot({ path: path.join(shots, "3j-settings-large-text.png") });
    await tapUi(page, logs, "a11y_large_text", "sheet");
    await page.mouse.click(...toPage(page, 360, 120));
    await page.waitForTimeout(400);
    // The level badge opens Account (save progress / sign in).
    await tapUi(page, logs, "account", "account");
    await page.waitForTimeout(1500);
    await page.screenshot({ path: path.join(shots, "3j2-account.png") });
    await tapUi(page, logs, "back", "summon");
    await tapUi(page, logs, "tab_play", "play");
    // Quick fight is one tap: your fighter, a random foe and arena, straight to the aim.
    const quickAt = logs.length;
    await tapUi(page, logs, "quickfight");
    await waitForLogAfter(logs, quickAt, "UI_AT aim_launch ", 5000);
    await page.waitForTimeout(800);
    await page.screenshot({ path: path.join(shots, "3-menu.png") }); // The PR comment links this shot.
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
    console.log("online:", logs.find((l) => l.startsWith("ONLINE")) ?? "no backend configured");
    console.log("analytics:", logs.find((l) => l.startsWith("ANALYTICS_OK")) ?? "nothing sent yet");
    await page.close();
  }

  // 2b. An invite link (?f=<friend code>) opens the Friends screen. demo=friends fills in sample friends (no server):
  // preset phrases sheet, then a rematch against a friend's saved team.
  if (mine(14)) {
    const { page, logs } = await openGame("?f=RBNW-XYZ2&demo=friends&offline=1");
    await waitForLog(logs, "BOOT_OK", 60000);
    await waitForLog(logs, "UI_SCREEN friends", 10000);
    await page.waitForTimeout(800);
    await page.screenshot({ path: path.join(shots, "3k-friends-invite.png") });
    await tapUi(page, logs, "say_Theo", "sheet");
    await page.screenshot({ path: path.join(shots, "3l-friends-say.png") });
    await tapUi(page, logs, "preset_1");
    await tapUi(page, logs, "rematch_Theo");
    console.log("rival:", await waitForLog(logs, "RIVAL_MENU", 5000));
    await page.screenshot({ path: path.join(shots, "3m-rival-menu.png") });
    await page.close();
  }

  // 2c. Shop and Glow Pass (?screen=shop, &dev=1 for the test store): buy gems from it, buy this week's first bundle (it goes
  // on at once), then fight wearing it. Then the pass: unlock the premium track from the test store.
  if (mine(68)) {
    const { page, logs } = await openGame("?screen=shop&seed=7&today=2026-10-20&offline=1&dev=1&quickfight=1");
    await waitForLog(logs, "BOOT_OK", 60000);
    await waitForLog(logs, "UI_SCREEN shop", 10000);
    await page.waitForTimeout(1200);
    await page.screenshot({ path: path.join(shots, "3n-shop.png") });
    await tapUi(page, logs, "get_gems", "sheet");
    await page.screenshot({ path: path.join(shots, "3o-gems.png") });
    await tapUi(page, logs, "buy_gems_2000", "shop");
    const bundle = [...logs].reverse().find((l) => l.startsWith("UI_AT buy_bundle_")).split(" ")[1];
    await tapUi(page, logs, bundle, "shop");
    await page.screenshot({ path: path.join(shots, "3p-shop-bought.png") });
    await tapUi(page, logs, "shop_back", "play");
    const menuAt = logs.length;
    await tapUi(page, logs, "quickfight");
    await waitForLogAfter(logs, menuAt, "UI_AT aim_launch ", 5000);
    await page.waitForTimeout(800);
    const [sx, sy] = toPage(page, 20 + 170 * 0.68, 190 + 830 * 0.68);
    const [ex, ey] = toPage(page, 360, 300);
    await page.mouse.move(sx, sy);
    await page.mouse.down();
    await page.mouse.move(ex, ey, { steps: 8 });
    await page.mouse.up();
    console.log("dressed fight:", await waitForLog(logs, "FIGHT_START", 5000));
    await page.waitForTimeout(2500);
    await page.screenshot({ path: path.join(shots, "3q-dressed-fight.png") });
    await page.close();
  }
  if (mine(15)) {
    const { page, logs } = await openGame("?screen=pass&today=2026-10-20&offline=1&dev=1");
    await waitForLog(logs, "BOOT_OK", 60000);
    await waitForLog(logs, "UI_SCREEN pass", 10000);
    await page.waitForTimeout(800);
    await page.screenshot({ path: path.join(shots, "3r-pass.png") });
    await tapUi(page, logs, "pass_buy", "pass");
    await page.screenshot({ path: path.join(shots, "3s-pass-premium.png") });
    await page.close();
  }

  // 3. Wide screen: controls sit beside the arena and FIGHT! is reachable.
  if (mine(41)) {
    const { page, logs } = await openGame("?seed=7&offline=1&quickfight=1", { width: 1376, height: 1263 });
    await waitForLog(logs, "BOOT_OK", 60000);
    await page.waitForTimeout(1500);
    await waitForLog(logs, "UI_SCREEN play", 10000);
    await page.waitForTimeout(800);
    await page.screenshot({ path: path.join(shots, "6a-wide-home.png") });
    await tapUi(page, logs, "quickfight");
    await waitForLog(logs, "UI_AT aim_launch ", 5000);
    await page.waitForTimeout(800);
    await page.screenshot({ path: path.join(shots, "6-wide-aim.png") });
    await tapUi(page, logs, "aim_launch");
    console.log("wide menu:", await waitForLog(logs, "FIGHT_START", 5000));
    await page.waitForTimeout(1500);
    await page.screenshot({ path: path.join(shots, "7-wide-fight.png") });
    await page.close();
  }

  // 3b. The owner's stats screen (?stats#k=<key>) with sample numbers, and
  // without a backend it says so instead of failing.
  if (mine(12)) {
    const { page, logs } = await openGame("?stats&demo=1&offline=1#k=demo");
    console.log("stats:", await waitForLog(logs, "STATS_SCREEN", 60000));
    await page.waitForTimeout(1000);
    await page.screenshot({ path: path.join(shots, "6s-stats.png") });
    await page.close();
    const off = await openGame("?stats&offline=1#k=demo");
    const status = await waitForLog(off.logs, "STATS_SCREEN", 60000);
    if (status !== "STATS_SCREEN offline") throw new Error(`stats without a backend: ${status}`);
    await off.page.close();
  }

  // 4. Sound board opens over the menu and its buttons play without errors.
  if (mine(15)) {
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

  // 5. Share: tap "Share fight" on a result, open the link it made, and the
  // same fight replays to the same end state. Then tap "Challenge friend" and
  // open that link: the challenge menu shows and its fight starts.
  if (mine(72)) {
    const { page, logs } = await openGame("?p1=laser&p2=vampire&seed=11&aim=-300&auto=1&speed=4");
    await waitForLog(logs, "BOOT_OK", 60000);
    const end = (await waitForLog(logs, "MATCH_END", 90000)).split("hash=")[1];
    const tapTarget = async (kind) => {
      await page.waitForFunction((k) => window.bbShare?.targets.some((t) => t.kind === k), kind, { timeout: 5000 });
      const t = await page.evaluate((k) => window.bbShare.targets.find((t) => t.kind === k), kind);
      const box = await page.locator("canvas").boundingBox();
      await page.mouse.click(box.x + (t.x + t.w / 2) * box.width, box.y + (t.y + t.h / 2) * box.height);
      return (await waitForLog(logs, `SHARE ${kind} `, 5000)).split(" ")[2];
    };
    await page.waitForTimeout(500);
    const replayUrl = await tapTarget("r");
    await page.waitForTimeout(500);
    await page.screenshot({ path: path.join(shots, "9-share.png") });
    const challengeUrl = await tapTarget("c");
    await page.close();
    console.log("share links:", replayUrl, challengeUrl);

    const replay = await openGame(new URL(replayUrl).search);
    const replayEnd = (await waitForLog(replay.logs, "MATCH_END", 120000)).split("hash=")[1];
    if (replayEnd !== end) throw new Error(`Replay link ended differently: ${replayEnd} vs ${end}`);
    await replay.page.waitForTimeout(500);
    await replay.page.screenshot({ path: path.join(shots, "10-replay-result.png") });
    await replay.page.close();

    const challenge = await openGame(new URL(challengeUrl).search);
    await waitForLog(challenge.logs, "BOOT_OK", 60000);
    await challenge.page.waitForTimeout(1500);
    await challenge.page.screenshot({ path: path.join(shots, "11-challenge-menu.png") });
    // One tap fights: FIGHT! launches at once (no aim step after it).
    await tapUi(challenge.page, challenge.logs, "menu_fight");
    console.log("challenge fight:", await waitForLog(challenge.logs, "FIGHT_START", 5000));
    await challenge.page.close();
  }

  // 6. Daily Trick Shot opens from its card on the Play tab.
  if (mine(8)) {
    const { page, logs } = await openGame("?seed=7");
    await waitForLog(logs, "BOOT_OK", 60000);
    await waitForLog(logs, "UI_SCREEN play", 10000);
    await page.waitForTimeout(800);
    // The campaign card above it pushes the Trick Shot card below the fold.
    await page.mouse.move(...toPage(page, 360, 800));
    for (let i = 0; i < 2; i++) {
      await page.mouse.wheel(0, 300);
      await page.waitForTimeout(150);
    }
    await page.waitForTimeout(600);
    await tapUi(page, logs, "trickshot");
    const ready = await waitForLog(logs, "TRICKSHOT_READY", 10000);
    console.log("trick shot:", ready);
    await page.waitForTimeout(800);
    await page.screenshot({ path: path.join(shots, "12-trickshot-aim.png") });
    await page.close();
  }

  // 7. A known solution of day 1 solves it.
  if (mine(13)) {
    const probe = await openGame("?mode=trickshot&day=1");
    const [lo, hi] = (await waitForLog(probe.logs, "TRICKSHOT_READY", 60000)).match(/solutions=(\d+)-(\d+)/).slice(1).map(Number);
    await probe.page.close();
    const aim = Math.round((lo + hi) / 2);
    const { page, logs } = await openGame(`?mode=trickshot&day=1&aim=${aim}&auto=1`);
    const result = await waitForLog(logs, "TRICKSHOT_RESULT", 60000);
    console.log("trick shot result:", result);
    if (!result.includes("result=solved")) throw new Error(`Aim ${aim} should solve day 1: ${result}`);
    await page.waitForTimeout(800);
    await page.screenshot({ path: path.join(shots, "13-trickshot-solved.png") });
    await page.close();
  }

  // 8. Daily board on a Saturday: open it from the Play tab, call
  // the Fight of the Day, watch it to the end and come back to the board.
  if (mine(22)) {
    const { page, logs } = await openGame("?today=2026-10-17&speed=4");
    await waitForLog(logs, "BOOT_OK", 60000);
    await waitForLog(logs, "UI_SCREEN play", 10000);
    await page.waitForTimeout(800);
    await tapUi(page, logs, "thisweek", "week");
    await page.screenshot({ path: path.join(shots, "14-this-week.png") });
    await tapUi(page, logs, "fotd_pick0");
    console.log("fight of the day:", await waitForLog(logs, "FIGHT_START", 5000));
    console.log("fight of the day end:", await waitForLog(logs, "MATCH_END", 90000));
    await page.waitForTimeout(800);
    await page.screenshot({ path: path.join(shots, "15-fotd-result.png") });
    await page.close();
  }

  // 9. Quests: the board's wide painted Quests door opens the Quests screen,
  // and the free swap rolls a different quest.
  if (mine(21)) {
    const { page, logs } = await openGame("?today=2026-10-15");
    await waitForLog(logs, "BOOT_OK", 60000);
    await waitForLog(logs, "UI_SCREEN play", 10000);
    await page.waitForTimeout(800);
    await tapUi(page, logs, "thisweek", "week");
    await page.waitForTimeout(800);
    await page.screenshot({ path: path.join(shots, "16-quests-door.png") });
    await tapUi(page, logs, "week_quests", "quests");
    await page.waitForTimeout(600);
    await page.screenshot({ path: path.join(shots, "16b-quests.png") });
    await page.close();
  }

  // 9a. Bounce Run chest: yesterday's best floor (set from Settings > Testing,
  // which then opens the Daily board) turns the Daily board's Bounce Run button into Open; the chest shakes,
  // bursts open, spills its rewards and Collect pays them.
  if (mine(11)) {
    const { page, logs } = await openGame("?demo=1&tutorial=0&dev=1");
    await waitForLog(logs, "BOOT_OK", 60000);
    await waitForLog(logs, "UI_SCREEN play", 10000);
    await page.waitForTimeout(800);
    await tapUi(page, logs, "settings", "sheet");
    await tapUi(page, logs, "dev_bounce_chest_20", "week");
    await page.waitForTimeout(600);
    await page.screenshot({ path: path.join(shots, "16c-daily-bounce-chest.png") });
    await tapUi(page, logs, "week_bounce_chest", "bounce_chest");
    await page.waitForTimeout(1200);
    await page.screenshot({ path: path.join(shots, "16d-bounce-chest.png") });
    await page.mouse.click(...toPage(page, 360, 700));
    await page.waitForTimeout(1500);
    await page.screenshot({ path: path.join(shots, "16e-bounce-chest-opening.png") });
    await waitForLog(logs, "UI_AT bounce_chest_collect", 15000);
    await page.screenshot({ path: path.join(shots, "16e2-bounce-chest-open.png") });
    const at = logs.length;
    await tapUi(page, logs, "bounce_chest_collect");
    console.log("bounce chest:", await waitForLogAfter(logs, at, "UI_BOUNCE_CHEST_COLLECT", 5000));
    await page.waitForTimeout(800);
    await page.screenshot({ path: path.join(shots, "16f-bounce-chest-collected.png") });
    await page.close();
  }

  // 9b. Finisher cam, then Save clip: the KO is shown zoomed in, the clip
  // plays in its "Who wins?" layout, gets recorded and downloads as a video.
  if (mine(70)) {
    const { page, logs } = await openGame("?p1=laser&p2=vampire&seed=11&aim=-300&auto=1&speed=4&offline=1&clip=1");
    await waitForLog(logs, "BOOT_OK", 60000);
    console.log("finisher:", await waitForLog(logs, "FINISHER_KO", 90000));
    await page.waitForTimeout(400);
    await page.screenshot({ path: path.join(shots, "30-finisher.png") });
    console.log("clip:", await waitForLog(logs, "CLIP_START", 10000));
    await page.waitForTimeout(1200);
    await page.screenshot({ path: path.join(shots, "31-clip-title.png") });
    await page.waitForTimeout(3000);
    await page.screenshot({ path: path.join(shots, "32-clip-fight.png") });
    const done = await waitForLog(logs, "CLIP_READY", 120000).catch(() => {
      throw new Error(`Clip was not made: ${logs.filter((l) => l.startsWith("CLIP")).join(" | ")}`);
    });
    console.log("clip made:", done, logs.find((l) => l.startsWith("CLIP_BLOB")));
    await page.waitForTimeout(500);
    await page.screenshot({ path: path.join(shots, "33-clip-ready.png") });
    await page.waitForFunction(() => window.bbShare?.targets.some((t) => t.kind === "clip"), null, { timeout: 5000 });
    const t = await page.evaluate(() => window.bbShare.targets.find((t) => t.kind === "clip"));
    const box = await page.locator("canvas").boundingBox();
    const download = page.waitForEvent("download", { timeout: 10000 });
    await page.mouse.click(box.x + (t.x + t.w / 2) * box.width, box.y + (t.y + t.h / 2) * box.height);
    const file = await download;
    const saved = path.join(shots, "clip-" + file.suggestedFilename());
    await file.saveAs(saved);
    const bytes = fs.statSync(saved).size;
    console.log("clip file:", file.suggestedFilename(), bytes, "bytes");
    if (bytes < 20000) throw new Error(`Clip file too small: ${bytes} bytes`);
    await page.close();
  }

  // 10. Ghost Arena: Play -> Arena screen -> pick a card -> play the relay to a result -> back to the Arena.
  if (mine(25)) {
    const { page, logs } = await openGame("?seed=7&offline=1");
    await waitForLog(logs, "UI_SCREEN play", 60000);
    await page.waitForTimeout(800);
    // The Arena card sits below the fold on a phone: scroll the Play tab first.
    await page.mouse.move(...toPage(page, 360, 800));
    // Scroll until the card's centre sits above the tab bar (more daily cards push it further down).
    const arenaY = () => Number([...logs].reverse().find((l) => l.startsWith("UI_AT arena "))?.split(" ")[3] ?? 9999);
    for (let i = 0; i < 20 && arenaY() > 1300; i++) {
      await page.mouse.wheel(0, 300);
      await page.waitForTimeout(250);
    }
    await page.waitForTimeout(600);
    await tapUi(page, logs, "arena", "arena");
    await page.screenshot({ path: path.join(shots, "18-arena.png") });
    await tapUi(page, logs, "arena_card_0");
    console.log("ghost arena:", await waitForLog(logs, "ARENA_READY", 10000));
    await page.waitForTimeout(800);
    await page.screenshot({ path: path.join(shots, "19-arena-intro.png") });
    // It opens straight on aiming the first ball. Each ball's Launch and its
    // leg's Skip (the middle pill of the bottom row) are tapped where the
    // scene logs them (arena_launch, arena_skip), newest first.
    const start = 0;
    let result = null;
    let done = start;
    for (let i = 0; i < 60 && !result; i++) {
      const at = logs.length;
      const mark = [...logs.slice(done)].reverse().find((l) => l.startsWith("UI_AT arena_launch ") || l.startsWith("UI_AT arena_skip "));
      if (mark) {
        done = at;
        await page.mouse.click(...toPage(page, ...mark.split(" ").slice(2).map(Number)));
      }
      await page.waitForTimeout(700);
      result = logs.slice(start).find((l) => l.startsWith("ARENA_RESULT"));
    }
    if (!result) throw new Error(`Ghost Arena fight never finished. Last logs:\n${logs.slice(-15).join("\n")}`);
    console.log("ghost arena result:", result);
    await page.screenshot({ path: path.join(shots, "20-arena-result.png") });
    await page.waitForTimeout(600);
    const back = logs.length;
    await tapUi(page, logs, "arena_back");
    await waitForLogAfter(logs, back, "UI_SCREEN arena", 15000);
    await page.screenshot({ path: path.join(shots, "21-arena-after.png") });
    await page.close();
  }

  // 11. Onboarding: cold open, starter pick, two aimed tutorial wins, the
  // guided first fusion, the boss teaser and on to the Glow Garden map.
  if (mine(102)) {
    const { page, logs } = await openGame("?tutorial=1");
    await waitForLog(logs, "BOOT_OK", 60000);
    // The story prologue: tap through every line.
    await waitForLog(logs, "UI_SCREEN onboard_story", 10000);
    await page.waitForTimeout(800);
    await page.screenshot({ path: path.join(shots, "22-onboard-prologue.png") });
    for (let n = 0; n < 10 && !logs.some((l) => l.startsWith("STORY_DONE")); n++) {
      await tapUi(page, logs, "story_next");
    }
    await waitForLog(logs, "UI_SCREEN onboard_cold_open", 10000);
    await page.waitForTimeout(800);
    await page.screenshot({ path: path.join(shots, "22a-onboard-cold-open.png") });
    await tapUi(page, logs, "pick_laser");
    await page.waitForTimeout(4000);
    await page.screenshot({ path: path.join(shots, "22b-onboard-cold-fight.png") });
    await waitForLog(logs, "UI_SCREEN onboard_cold_result", 90000);
    await page.screenshot({ path: path.join(shots, "22c-onboard-cold-result.png") });
    await tapUi(page, logs, "next", "onboard_starter");
    await page.screenshot({ path: path.join(shots, "22d-onboard-starter.png") });
    const aimAndWin = async (n) => {
      await page.waitForTimeout(800);
      await page.screenshot({ path: path.join(shots, `22e-onboard-aim${n}.png`) });
      const [sx, sy] = toPage(page, 20 + 170 * 0.68, 190 + 830 * 0.68);
      const [ex, ey] = toPage(page, 360, 300);
      const start = logs.length;
      await page.mouse.move(sx, sy);
      await page.mouse.down();
      await page.mouse.move(ex, ey, { steps: 8 });
      await page.mouse.up();
      await waitForLogAfter(logs, start, "FIGHT_START", 5000);
      await waitForLogAfter(logs, start, "UI_SCREEN onboard_reward", 120000);
      await page.screenshot({ path: path.join(shots, `22f-onboard-reward${n}.png`) });
    };
    await tapUi(page, logs, "starter_laser");
    await aimAndWin(1);
    await tapUi(page, logs, "next");
    await aimAndWin(2);
    await tapUi(page, logs, "next", "fuse");
    await page.screenshot({ path: path.join(shots, "22g-onboard-fuse.png") });
    const before = logs.length;
    await tapUi(page, logs, "fuse");
    console.log("onboarding fusion:", await waitForLogAfter(logs, before, "UI_FUSED", 5000));
    // Chapter 1's story, skipped, then the boss it leaves behind.
    await waitForLogAfter(logs, before, "UI_SCREEN onboard_story", 10000);
    await tapUi(page, logs, "story_next");
    await waitForLogAfter(logs, before, "STORY_LINE 1 glitch", 5000);
    await page.waitForTimeout(600);
    await page.screenshot({ path: path.join(shots, "22h-onboard-chapter1.png") });
    await tapUi(page, logs, "story_skip");
    await waitForLogAfter(logs, before, "UI_SCREEN onboard_boss", 10000);
    await page.screenshot({ path: path.join(shots, "22h-onboard-boss.png") });
    await tapUi(page, logs, "lets_go");
    await waitForLog(logs, "ONBOARD step=done", 5000);
    // "Let's go!" opens the Glow Garden map the teaser points at.
    await waitForLog(logs, "UI_SCREEN campaign", 5000);
    await page.waitForTimeout(800);
    await page.screenshot({ path: path.join(shots, "22i-onboard-home.png") });
    // Home already shows every mode, the closed ones dimmed and locked.
    await tapUi(page, logs, "back", "play");
    await page.screenshot({ path: path.join(shots, "22j-onboard-home-locked.png") });
    console.log("onboarding:", logs.filter((l) => l.startsWith("ONBOARD")).map((l) => l.split(" ")[1]).join(" "));
    await page.close();
  }

  // Spire. The Spire: open it from its link, pick a critter, climb floor 1 and
  // come back to the Spire screen.
  if (mine(14)) {
    const { page, logs } = await openGame("?mode=spire&offline=1");
    await waitForLog(logs, "BOOT_OK", 60000);
    await waitForLog(logs, "UI_SCREEN spire", 10000);
    await page.waitForTimeout(800);
    await page.screenshot({ path: path.join(shots, "16-spire.png") });
    await tapUi(page, logs, "spire_pick_vampire", "spire");
    await tapUi(page, logs, "spire_climb");
    console.log("spire:", await waitForLog(logs, "SPIRE_READY", 10000));
    await page.waitForTimeout(800);
    // The fight opens straight on the aim: Launch (or a tap on the arena) starts it.
    await tapUi(page, logs, "SpireLaunch");
    await tapUi(page, logs, "SpireSkip");
    console.log("spire result:", await waitForLog(logs, "SPIRE_RESULT", 30000));
    await page.waitForTimeout(800);
    await page.screenshot({ path: path.join(shots, "17-spire-result.png") });
    const back = logs.length;
    await tapUi(page, logs, "SpireBack");
    await waitForLogAfter(logs, back, "UI_SCREEN spire", 30000);
    await page.waitForTimeout(800);
    await page.screenshot({ path: path.join(shots, "18-spire-after.png") });
    await page.close();
  }

  // 12. Every non-square arena boots, draws and finishes a fight.
  if (mine(57)) for (const [i, arena] of ["rink", "pillars", "bumpers"].entries()) {
    const { page, logs } = await openGame(`?p1=vampire&p2=laser&seed=42&auto=1&speed=4&arena=${arena}`);
    await waitForLog(logs, "BOOT_OK", 60000);
    await page.waitForTimeout(2500);
    await page.screenshot({ path: path.join(shots, `${23 + i}-arena-${arena}.png`) });
    console.log(`arena ${arena}:`, await waitForLog(logs, "MATCH_END", 90000));
    await page.close();
  }

  // 13. Campaign: a new player opens the Glow Garden map from the Play tab,
  // fights stage 1-1, and comes back to the map with the result.
  if (mine(54)) {
    const { page, logs } = await openGame("?seed=7&offline=1");
    await waitForLog(logs, "BOOT_OK", 60000);
    await waitForLog(logs, "UI_SCREEN play", 10000);
    await page.waitForTimeout(800);
    await page.screenshot({ path: path.join(shots, "26-home-new-player.png") });
    await tapUi(page, logs, "campaign", "world");
    await page.screenshot({ path: path.join(shots, "27-world-map.png") });
    await tapUi(page, logs, "zone_1", "campaign");
    await page.screenshot({ path: path.join(shots, "27-campaign-map.png") });
    await tapUi(page, logs, "stage_1_1");
    await page.screenshot({ path: path.join(shots, "28-stage-aim.png") });
    await page.mouse.click(...toPage(page, 20 + 170, 990 + 42)); // Launch
    console.log("campaign fight:", await waitForLog(logs, "FIGHT_START", 5000));
    const end = await waitForLog(logs, "STAGE_END", 120000);
    console.log("campaign stage:", end);
    // The fight goes straight back to the stage list with the results popup up.
    await waitForLogAfter(logs, logs.indexOf(end), "UI_SCREEN campaign", 10000);
    await waitForLogAfter(logs, logs.indexOf(end), "UI_SCREEN sheet", 10000);
    await page.waitForTimeout(800);
    await page.screenshot({ path: path.join(shots, "30-campaign-after.png") });
    await page.close();
  }

  // 14. A campaign stage straight from the URL plays through to its rewards.
  if (mine(19)) {
    const { page, logs } = await openGame("?pve=1-4&auto=1&speed=4&offline=1");
    console.log("url stage:", await waitForLog(logs, "STAGE_END", 120000));
    await page.close();
  }

  // 14b. The Anvil King (design/bosses.md): the boss screen, then an Easy
  // fight on The Forge through to its rewards.
  if (mine(30)) {
    const { page, logs } = await openGame("?demo=1&stars=3&screen=vault&speed=4&offline=1");
    await waitForLog(logs, "UI_SCREEN vault", 60000);
    await page.waitForTimeout(800);
    await page.screenshot({ path: path.join(shots, "31-anvil-king.png") });
    await tapUi(page, logs, "vault_go");
    await page.waitForTimeout(500);
    await page.mouse.click(...toPage(page, 20 + 170, 990 + 42)); // Launch
    console.log("boss fight:", await waitForLog(logs, "FIGHT_START", 5000));
    await page.waitForTimeout(4000);
    await page.screenshot({ path: path.join(shots, "32-anvil-king-fight.png") });
    console.log("boss end:", await waitForLog(logs, "BOSS_END", 120000));
    await page.close();
  }

  // 14c. The Brood Queen: her screen, then an Easy fight on The Nest.
  if (mine(30)) {
    const { page, logs } = await openGame("?demo=1&stars=3&zones=2&screen=nest&speed=4&offline=1");
    await waitForLog(logs, "UI_SCREEN nest", 60000);
    await page.waitForTimeout(800);
    await page.screenshot({ path: path.join(shots, "33-brood-queen.png") });
    await tapUi(page, logs, "nest_go");
    await page.waitForTimeout(500);
    await page.mouse.click(...toPage(page, 20 + 170, 990 + 42)); // Launch
    console.log("queen fight:", await waitForLog(logs, "FIGHT_START", 5000));
    await page.waitForTimeout(6000);
    await page.screenshot({ path: path.join(shots, "34-brood-queen-fight.png") });
    console.log("queen end:", await waitForLog(logs, "BOSS_END", 120000));
    await page.close();
  }

  // 14d. The boss hall, then the Piñata Titan: a 30 second smash on Fiesta Plaza.
  if (mine(25)) {
    const { page, logs } = await openGame("?demo=1&stars=3&zones=2&screen=bosses&speed=4&offline=1");
    await waitForLog(logs, "UI_SCREEN bosses", 60000);
    await page.waitForTimeout(800);
    await page.screenshot({ path: path.join(shots, "35-boss-hall.png") });
    await tapUi(page, logs, "boss_pinata");
    await waitForLog(logs, "UI_SCREEN pinata", 10000);
    await page.waitForTimeout(500);
    await page.screenshot({ path: path.join(shots, "36-pinata.png") });
    await tapUi(page, logs, "pinata_go");
    await page.waitForTimeout(500);
    await page.mouse.click(...toPage(page, 20 + 170, 990 + 42)); // Launch
    console.log("pinata fight:", await waitForLog(logs, "FIGHT_START", 5000));
    await page.waitForTimeout(4000);
    await page.screenshot({ path: path.join(shots, "37-pinata-fight.png") });
    console.log("pinata end:", await waitForLog(logs, "BOSS_END", 120000));
    await page.close();
  }

  // 14e. The Totem of Nine: its screen, then an Easy fight in the Spirit Shrine.
  if (mine(30)) {
    const { page, logs } = await openGame("?demo=1&stars=3&zones=3&screen=totem&speed=4&offline=1");
    await waitForLog(logs, "UI_SCREEN totem", 60000);
    await page.waitForTimeout(800);
    await page.screenshot({ path: path.join(shots, "38-totem.png") });
    await tapUi(page, logs, "totem_go");
    await page.waitForTimeout(500);
    await page.mouse.click(...toPage(page, 20 + 170, 990 + 42)); // Launch
    console.log("totem fight:", await waitForLog(logs, "FIGHT_START", 5000));
    await page.waitForTimeout(5000);
    await page.screenshot({ path: path.join(shots, "39-totem-fight.png") });
    console.log("totem end:", await waitForLog(logs, "BOSS_END", 120000));
    await page.close();
  }

  // 14f. The Prism Wyrm: its screen, then an Easy fight in the Crystal Rift.
  if (mine(40)) {
    const { page, logs } = await openGame("?demo=1&stars=3&zones=4&screen=wyrm&speed=4&offline=1");
    await waitForLog(logs, "UI_SCREEN wyrm", 60000);
    await page.waitForTimeout(800);
    await page.screenshot({ path: path.join(shots, "40-wyrm.png") });
    await tapUi(page, logs, "wyrm_go");
    await page.waitForTimeout(500);
    await page.mouse.click(...toPage(page, 20 + 170, 990 + 42)); // Launch
    console.log("wyrm fight:", await waitForLog(logs, "FIGHT_START", 5000));
    await page.waitForTimeout(5000);
    await page.screenshot({ path: path.join(shots, "41-wyrm-fight.png") });
    console.log("wyrm end:", await waitForLog(logs, "BOSS_END", 120000));
    await page.close();
  }

  // 14g. The Glitch: its screen, then the weekly fight in the Corrupted Core.
  if (mine(40)) {
    const { page, logs } = await openGame("?demo=1&stars=3&zones=5&screen=glitch&speed=4&offline=1");
    await waitForLog(logs, "UI_SCREEN glitch", 60000);
    await page.waitForTimeout(800);
    await page.screenshot({ path: path.join(shots, "42-glitch.png") });
    await tapUi(page, logs, "glitch_go");
    await page.waitForTimeout(500);
    await page.mouse.click(...toPage(page, 20 + 170, 990 + 42)); // Launch
    console.log("glitch fight:", await waitForLog(logs, "FIGHT_START", 5000));
    await page.waitForTimeout(5000);
    await page.screenshot({ path: path.join(shots, "43-glitch-fight.png") });
    console.log("glitch end:", await waitForLog(logs, "BOSS_END", 120000));
    await page.close();
  }

  // 15. Bracket of Legends: pick a champion while picks are open, then on
  // final day open the final and watch its first game.
  if (mine(20)) {
    const { page, logs } = await openGame("?mode=bracket&today=2026-10-14&speed=4");
    await waitForLog(logs, "BOOT_OK", 60000);
    await waitForLog(logs, "UI_SCREEN bracket", 10000);
    await page.waitForTimeout(800);
    // The first card in the grid: later ones sit below the fold as the roster grows.
    const champ = logs.find((l) => l.startsWith("UI_AT champ_"));
    if (!champ) throw new Error(`No champion cards. Last logs:\n${logs.slice(-15).join("\n")}`);
    await tapUi(page, logs, champ.split(" ")[1], "bracket");
    await page.screenshot({ path: path.join(shots, "30-bracket-picks.png") });
    await page.close();
  }
  if (mine(25)) {
    const { page, logs } = await openGame("?mode=bracket&today=2026-10-25&speed=4");
    await waitForLog(logs, "BOOT_OK", 60000);
    await waitForLog(logs, "UI_SCREEN bracket", 10000);
    await page.waitForTimeout(800);
    // Builds ship every bracket already fought out (tools/bracket_results.gd);
    // a phone fighting it out itself takes minutes.
    if (logs.some((l) => l.startsWith("BRACKET_FIGHTING"))) throw new Error("The build has no fought-out bracket: did tools/bracket_results.gd run before the export?");
    await page.screenshot({ path: path.join(shots, "31-bracket-final-day.png") });
    // The final: the screen opens on the latest round out, whatever the field size.
    const final = [...logs].reverse().find((l) => l.startsWith("UI_AT match_"));
    if (!final) throw new Error(`No playable bracket match on final day. Last logs:\n${logs.slice(-15).join("\n")}`);
    await tapUi(page, logs, final.split(" ")[1], "sheet");
    await page.screenshot({ path: path.join(shots, "32-bracket-series.png") });
    await tapUi(page, logs, "game_0");
    console.log("bracket game:", await waitForLog(logs, "FIGHT_START", 5000));
    console.log("bracket game end:", await waitForLog(logs, "MATCH_END", 90000));
    await page.waitForTimeout(800);
    await page.screenshot({ path: path.join(shots, "33-bracket-game-result.png") });
    await page.close();
  }

  // 15. Bounce Run: the Play tab has its card; open it by link (the card sits
  // below the fold), draft three critters and three boons, pick a node on the
  // map and fight floor 1.
  if (mine(27)) {
    const home = await openGame("?seed=7&offline=1");
    await waitForLog(home.logs, "UI_AT bouncerun ", 60000);
    await home.page.close();
    const { page, logs } = await openGame("?mode=bouncerun&offline=1");
    console.log("bounce run:", await waitForLog(logs, "BOUNCERUN_READY", 60000));
    await waitForLog(logs, "UI_SCREEN br_draft", 5000);
    await page.waitForTimeout(800);
    for (const i of [0, 1, 2]) await tapUi(page, logs, `br_card_${i}`, "br_draft");
    await page.screenshot({ path: path.join(shots, "40-bouncerun-draft.png") });
    await tapUi(page, logs, "br_next", "br_start_boons");
    for (const i of [0, 1, 2]) await tapUi(page, logs, `br_sboon_${i}`, "br_start_boons");
    await tapUi(page, logs, "br_srelic_0", "br_start_boons");
    await page.screenshot({ path: path.join(shots, "40b-bouncerun-start-boons.png") });
    await tapUi(page, logs, "br_start", "br_map");
    await page.screenshot({ path: path.join(shots, "41-bouncerun-map.png") });
    // A tap on a lit node goes straight there (floor 1 is all fights).
    await tapUi(page, logs, "br_node_0", "br_floor");
    await page.screenshot({ path: path.join(shots, "41b-bouncerun-floor.png") });
    await tapUi(page, logs, "br_send_0", "br_aim");
    await page.screenshot({ path: path.join(shots, "42-bouncerun-aim.png") });
    await tapUi(page, logs, "br_launch", "br_fight");
    await page.waitForTimeout(2500);
    await page.screenshot({ path: path.join(shots, "43-bouncerun-fight.png") });
    await tapUi(page, logs, "br_skip", "br_result");
    console.log("bounce run fight:", await waitForLog(logs, "BOUNCERUN_RESULT", 5000));
    await page.screenshot({ path: path.join(shots, "44-bouncerun-result.png") });
    const won = logs.some((l) => l.startsWith("BOUNCERUN_RESULT") && l.includes("won=true"));
    await tapUi(page, logs, "br_continue", won ? "br_boon" : "br_floor");
    await page.screenshot({ path: path.join(shots, won ? "45-bouncerun-boon.png" : "45-bouncerun-retry.png") });
    if (won) {
      // After the boon, back on the map with floor 2's nodes lit.
      await tapUi(page, logs, "br_boon_0", "br_map");
      await page.screenshot({ path: path.join(shots, "45b-bouncerun-map-floor2.png") });
    }
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
console.log(`Smoke test passed${shardN > 1 ? ` (shard ${shardK} of ${shardN})` : ""}. Screenshots in ${shots}`);

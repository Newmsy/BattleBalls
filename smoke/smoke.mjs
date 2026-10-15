// Smoke test for the web build: boots it in a phone-sized headless Chromium,
// plays one auto fight and one fight through the real menu, fails on any
// page error, and saves screenshots. Also opens Daily Trick Shot and solves one,
// plays the whole onboarding, follows a Bracket of Legends from picks to the
// final and climbs the first floor of The Spire, and fights
// the first floor of Bounce Run.
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

try {
  // 1. Auto fight from URL params runs to a result.
  {
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

  // 1b. Season 1 debut: Flux (Magnet) fights Optic; its field rings and poles render.
  {
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
  {
    const { page, logs } = await openGame("?seed=7&demo=1");
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
      await waitForLogAfter(logs, before, "UI_SCREEN critters", 5000);
      if (logs.slice(before).some((l) => l.startsWith("UI_SCREEN detail"))) errors.push("a scroll drag opened a critter card");
      await page.screenshot({ path: path.join(shots, "3b2-critters-scrolled.png") });
      await swipe(page, 360, 500, 0, 600);
    }
    await tapUi(page, logs, "tile_vampire", "detail");
    await page.screenshot({ path: path.join(shots, "3c-detail.png") });
    // Swiping in from the left edge goes back to the list, then reopen the card.
    {
      const before = logs.length;
      await swipe(page, 4, 700, 420, 0);
      await waitForLogAfter(logs, before, "UI_SCREEN critters", 5000);
      console.log("edge swipe: detail -> critters");
      await tapUi(page, logs, "tile_vampire", "detail");
    }
    await tapUi(page, logs, "tab_fuse", "fuse");
    await page.screenshot({ path: path.join(shots, "3d-fuse.png") });
    const before = logs.length;
    await tapUi(page, logs, "fuse");
    console.log("fusion:", await waitForLogAfter(logs, before, "UI_FUSED", 5000));
    await page.waitForTimeout(800);
    await page.screenshot({ path: path.join(shots, "3e-fused.png") });
    await tapUi(page, logs, "tab_bag", "bag");
    await tapUi(page, logs, "gear_5", "sheet");
    await page.screenshot({ path: path.join(shots, "3f-bag-sheet.png") });
    await tapUi(page, logs, "equip_juggernaut", "bag");
    await page.screenshot({ path: path.join(shots, "3g-bag.png") });
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
    await tapUi(page, logs, "open_all");
    await page.waitForTimeout(2000);
    await page.screenshot({ path: path.join(shots, "3i-reveal.png") });
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
    await tapUi(page, logs, "quickfight");
    await page.screenshot({ path: path.join(shots, "3-menu.png") });
    await waitForLog(logs, "UI_AT menu_fight ", 5000);
    await tapUi(page, logs, "pick_laser");
    await page.waitForTimeout(300);
    await tapUi(page, logs, "menu_fight");
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
    console.log("online:", logs.find((l) => l.startsWith("ONLINE")) ?? "no backend configured");
    console.log("analytics:", logs.find((l) => l.startsWith("ANALYTICS_OK")) ?? "nothing sent yet");
    await page.close();
  }

  // 2b. An invite link (?f=<friend code>) opens the Friends screen. demo=friends fills in sample friends (no server):
  // preset phrases sheet, then a rematch against a friend's saved team.
  {
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

  // 2c. Shop and Glow Pass (?screen=shop): buy gems from the test store, buy this week's first bundle (it goes
  // on at once), then fight wearing it. Then the pass: unlock the premium track from the test store.
  {
    const { page, logs } = await openGame("?screen=shop&seed=7&today=2026-10-20&offline=1");
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
    await waitForLogAfter(logs, menuAt, "UI_AT menu_fight ", 5000);
    await tapUi(page, logs, "menu_fight");
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
  {
    const { page, logs } = await openGame("?screen=pass&today=2026-10-20&offline=1");
    await waitForLog(logs, "BOOT_OK", 60000);
    await waitForLog(logs, "UI_SCREEN pass", 10000);
    await page.waitForTimeout(800);
    await page.screenshot({ path: path.join(shots, "3r-pass.png") });
    await tapUi(page, logs, "pass_buy", "pass");
    await page.screenshot({ path: path.join(shots, "3s-pass-premium.png") });
    await page.close();
  }

  // 3. Wide screen: controls sit beside the arena and FIGHT! is reachable.
  {
    const { page, logs } = await openGame("?seed=7&offline=1", { width: 1376, height: 1263 });
    await waitForLog(logs, "BOOT_OK", 60000);
    await page.waitForTimeout(1500);
    await waitForLog(logs, "UI_SCREEN play", 10000);
    await page.waitForTimeout(800);
    await page.screenshot({ path: path.join(shots, "6a-wide-home.png") });
    await tapUi(page, logs, "quickfight");
    await page.screenshot({ path: path.join(shots, "6-wide-menu.png") });
    await waitForLog(logs, "UI_AT menu_fight ", 5000);
    await tapUi(page, logs, "menu_fight");
    await page.waitForTimeout(800);
    await waitForLog(logs, "UI_AT aim_launch ", 5000);
    await tapUi(page, logs, "aim_launch");
    console.log("wide menu:", await waitForLog(logs, "FIGHT_START", 5000));
    await page.waitForTimeout(1500);
    await page.screenshot({ path: path.join(shots, "7-wide-fight.png") });
    await page.close();
  }

  // 3b. The owner's stats screen (?stats#k=<key>) with sample numbers, and
  // without a backend it says so instead of failing.
  {
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

  // 5. Share: tap "Share fight" on a result, open the link it made, and the
  // same fight replays to the same end state. Then tap "Challenge friend" and
  // open that link: the challenge menu shows and its fight starts.
  {
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
    await tapUi(challenge.page, challenge.logs, "menu_fight");
    await waitForLog(challenge.logs, "UI_AT aim_launch ", 5000);
    await tapUi(challenge.page, challenge.logs, "aim_launch");
    console.log("challenge fight:", await waitForLog(challenge.logs, "FIGHT_START", 5000));
    await challenge.page.close();
  }

  // 6. Daily Trick Shot opens from its card on the Play tab.
  {
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
  {
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

  // 8. This Week board on a Chaos Saturday: open it from the Play tab, call
  // the Fight of the Day, watch it to the end and come back to the board.
  {
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

  // 9. Try-a-Critter: the board's loaner card, then that day's Critter Shot
  // (a separate puzzle shot with the loaner) solved with a known aim.
  {
    const { page, logs } = await openGame("?today=2026-10-15");
    await waitForLog(logs, "BOOT_OK", 60000);
    await waitForLog(logs, "UI_SCREEN play", 10000);
    await page.waitForTimeout(800);
    await tapUi(page, logs, "thisweek", "week");
    await page.waitForTimeout(800);
    await page.screenshot({ path: path.join(shots, "16-try-a-critter.png") });
    await page.close();
    const probe = await openGame("?mode=trickshot&day=2&shooter=laser");
    const ready = await waitForLog(probe.logs, "TRICKSHOT_READY", 60000);
    if (!ready.includes("shooter=laser")) throw new Error(`Critter Shot should be shot by Optic: ${ready}`);
    const [lo, hi] = ready.match(/solutions=(\d+)-(\d+)/).slice(1).map(Number);
    await probe.page.close();
    const shot = await openGame(`?mode=trickshot&day=2&shooter=laser&aim=${Math.round((lo + hi) / 2)}&auto=1`);
    const result = await waitForLog(shot.logs, "TRICKSHOT_RESULT", 60000);
    console.log("critter shot result:", result);
    if (!result.includes("result=solved")) throw new Error(`The middle aim should solve the Critter Shot: ${result}`);
    await shot.page.waitForTimeout(800);
    await shot.page.screenshot({ path: path.join(shots, "17-critter-shot.png") });
    await shot.page.close();
  }

  // 9b. Finisher cam, then Save clip: the KO is shown zoomed in, the clip
  // plays in its "Who wins?" layout, gets recorded and downloads as a video.
  {
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
  {
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
    // FIGHT!, Launch and Skip all sit under this point (first panel row, right half).
    const start = logs.length;
    let result = null;
    for (let i = 0; i < 60 && !result; i++) {
      await page.mouse.click(...toPage(page, 530, 1032));
      await page.waitForTimeout(700);
      result = logs.slice(start).find((l) => l.startsWith("ARENA_RESULT"));
    }
    if (!result) throw new Error(`Ghost Arena fight never finished. Last logs:\n${logs.slice(-15).join("\n")}`);
    console.log("ghost arena result:", result);
    await page.screenshot({ path: path.join(shots, "20-arena-result.png") });
    const back = logs.length;
    // Back to Arena sits under the result headline.
    await page.mouse.click(...toPage(page, 360, 1118));
    await waitForLogAfter(logs, back, "UI_SCREEN arena", 15000);
    await page.screenshot({ path: path.join(shots, "21-arena-after.png") });
    await page.close();
  }

  // 11. Onboarding: cold open, starter pick, two aimed tutorial wins, the
  // guided first fusion, the boss teaser and on to the Glow Garden map.
  {
    const { page, logs } = await openGame("?tutorial=1");
    await waitForLog(logs, "BOOT_OK", 60000);
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
    await waitForLogAfter(logs, before, "UI_SCREEN onboard_boss", 10000);
    await page.screenshot({ path: path.join(shots, "22h-onboard-boss.png") });
    await tapUi(page, logs, "lets_go");
    await waitForLog(logs, "ONBOARD step=done", 5000);
    // "Let's go!" opens the Glow Garden map the teaser points at.
    await waitForLog(logs, "UI_SCREEN campaign", 5000);
    await page.waitForTimeout(800);
    await page.screenshot({ path: path.join(shots, "22i-onboard-home.png") });
    console.log("onboarding:", logs.filter((l) => l.startsWith("ONBOARD")).map((l) => l.split(" ")[1]).join(" "));
    await page.close();
  }

  // Spire. The Spire: open it from its link, pick a critter, climb floor 1 and
  // come back to the Spire screen.
  {
    const { page, logs } = await openGame("?mode=spire&offline=1");
    await waitForLog(logs, "BOOT_OK", 60000);
    await waitForLog(logs, "UI_SCREEN spire", 10000);
    await page.waitForTimeout(800);
    await page.screenshot({ path: path.join(shots, "16-spire.png") });
    await tapUi(page, logs, "spire_pick_vampire", "spire");
    await tapUi(page, logs, "spire_climb");
    console.log("spire:", await waitForLog(logs, "SPIRE_READY", 10000));
    await page.waitForTimeout(800);
    await tapUi(page, logs, "SpireFight");
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
  for (const [i, arena] of ["rink", "pillars", "bumpers"].entries()) {
    const { page, logs } = await openGame(`?p1=vampire&p2=laser&seed=42&auto=1&speed=4&arena=${arena}`);
    await waitForLog(logs, "BOOT_OK", 60000);
    await page.waitForTimeout(2500);
    await page.screenshot({ path: path.join(shots, `${23 + i}-arena-${arena}.png`) });
    console.log(`arena ${arena}:`, await waitForLog(logs, "MATCH_END", 90000));
    await page.close();
  }

  // 13. Campaign: a new player opens the Glow Garden map from the Play tab,
  // fights stage 1-1, and comes back to the map with the result.
  {
    const { page, logs } = await openGame("?seed=7&offline=1");
    await waitForLog(logs, "BOOT_OK", 60000);
    await waitForLog(logs, "UI_SCREEN play", 10000);
    await page.waitForTimeout(800);
    await page.screenshot({ path: path.join(shots, "26-home-new-player.png") });
    await tapUi(page, logs, "campaign", "campaign");
    await page.screenshot({ path: path.join(shots, "27-campaign-map.png") });
    await tapUi(page, logs, "stage_1_1");
    await page.screenshot({ path: path.join(shots, "28-stage-aim.png") });
    await page.mouse.click(...toPage(page, 20 + 170, 990 + 42)); // Launch
    console.log("campaign fight:", await waitForLog(logs, "FIGHT_START", 5000));
    const end = await waitForLog(logs, "STAGE_END", 120000);
    console.log("campaign stage:", end);
    await page.waitForTimeout(800);
    await page.screenshot({ path: path.join(shots, "29-stage-result.png") });
    // Result screen: result label, report, then the "Back to the map" row.
    await page.mouse.click(...toPage(page, 360, 990 + 56 + 14 + 60 + 14 + 42));
    await waitForLog(logs, "UI_SCREEN campaign", 5000);
    await page.waitForTimeout(800);
    await page.screenshot({ path: path.join(shots, "30-campaign-after.png") });
    await page.close();
  }

  // 14. A campaign stage straight from the URL plays through to its rewards.
  {
    const { page, logs } = await openGame("?pve=1-4&auto=1&speed=4&offline=1");
    console.log("url stage:", await waitForLog(logs, "STAGE_END", 120000));
    await page.close();
  }

  // 15. Bracket of Legends: pick a champion while picks are open, then on
  // final day open the final and watch its first game.
  {
    const { page, logs } = await openGame("?mode=bracket&today=2026-10-14&speed=4");
    await waitForLog(logs, "BOOT_OK", 60000);
    await waitForLog(logs, "UI_SCREEN bracket", 10000);
    await page.waitForTimeout(800);
    await tapUi(page, logs, "champ_laser", "bracket");
    await page.screenshot({ path: path.join(shots, "30-bracket-picks.png") });
    await page.close();
  }
  {
    const { page, logs } = await openGame("?mode=bracket&today=2026-10-25&speed=4");
    await waitForLog(logs, "BOOT_OK", 60000);
    await waitForLog(logs, "UI_SCREEN bracket", 10000);
    await page.waitForTimeout(800);
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

  // 14. Chaos Weekend modifier from the URL reaches the sim and the report code.
  {
    const { page, logs } = await openGame("?p1=vampire&p2=laser&seed=7&auto=1&speed=4&mod=big_head");
    await waitForLog(logs, "BOOT_OK", 60000);
    const start = await waitForLog(logs, "FIGHT_START", 5000);
    if (!start.endsWith(".big_head")) throw new Error(`modifier missing from report code: ${start}`);
    await page.waitForTimeout(3000);
    await page.screenshot({ path: path.join(shots, "26-big-head.png") });
    console.log("modifier fight:", await waitForLog(logs, "MATCH_END", 90000));
    await page.close();
  }

  // 15. Bounce Run: the Play tab has its card; open it by link (the card sits
  // below the fold), draft three, fight floor 1.
  {
    const home = await openGame("?seed=7&offline=1");
    await waitForLog(home.logs, "UI_AT bouncerun ", 60000);
    await home.page.close();
    const { page, logs } = await openGame("?mode=bouncerun&offline=1");
    console.log("bounce run:", await waitForLog(logs, "BOUNCERUN_READY", 60000));
    await waitForLog(logs, "UI_SCREEN br_draft", 5000);
    await page.waitForTimeout(800);
    for (const i of [0, 1, 2]) await tapUi(page, logs, `br_card_${i}`, "br_draft");
    await page.screenshot({ path: path.join(shots, "40-bouncerun-draft.png") });
    await tapUi(page, logs, "br_start", "br_floor");
    await page.screenshot({ path: path.join(shots, "41-bouncerun-floor.png") });
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

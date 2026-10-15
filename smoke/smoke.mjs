// Smoke test for the web build: boots it in a phone-sized headless Chromium,
// plays one auto fight and one fight through the real menu, fails on any
// page error, and saves screenshots. Also opens Daily Trick Shot and solves one.
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
    // The online backend is best-effort (the game plays offline), so a failed
    // request to it is reported but doesn't fail the smoke test.
    if (m.type() === "error" && /supabase\.co/.test(m.location()?.url ?? "")) console.log(`backend request failed: ${m.text()}`);
    else if (m.type() === "error") errors.push(`${query}: ${m.text()}`);
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
  if (nextScreen) await waitForLogAfter(logs, start, `UI_SCREEN ${nextScreen}`, 5000);
  await page.waitForTimeout(600);
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
    await page.waitForTimeout(500);
    await page.screenshot({ path: path.join(shots, "2-result.png") });
    await page.close();
  }

  // 2. Real flow: home -> menus tour -> fuse -> quick fight -> FIGHT! -> drag to aim -> fight runs. Only this case
  // goes online (signs in a guest) when the build has a backend.
  {
    const { page, logs } = await openGame("?seed=7");
    await waitForLog(logs, "BOOT_OK", 60000);
    await waitForLog(logs, "UI_SCREEN play", 10000);
    await page.waitForTimeout(1500);
    await page.screenshot({ path: path.join(shots, "3a-home.png") });
    await tapUi(page, logs, "tab_critters", "critters");
    await page.screenshot({ path: path.join(shots, "3b-critters.png") });
    await tapUi(page, logs, "tile_vampire", "detail");
    await page.screenshot({ path: path.join(shots, "3c-detail.png") });
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
    const { width, height } = page.viewportSize();
    await page.mouse.move(width / 2, height / 2);
    await page.mouse.wheel(0, 1100);
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

  // 10. Ghost Arena: Play -> Arena screen -> pick a card -> play the relay to a result -> back to the Arena.
  {
    const { page, logs } = await openGame("?seed=7&offline=1");
    await waitForLog(logs, "UI_SCREEN play", 60000);
    await page.waitForTimeout(800);
    // The Arena card sits below the fold on a phone: scroll the Play tab first.
    await page.mouse.move(...toPage(page, 360, 800));
    for (let i = 0; i < 6; i++) {
      await page.mouse.wheel(0, 300);
      await page.waitForTimeout(150);
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

// Screenshots every home screen at two phone sizes, with normal and Larger
// text, for UI reviews (before/after shots in PRs). Not part of CI.
// Usage: [EXTRA=&today=2026-10-17] node screens.mjs [path/to/build/web] [out dir] [screen,screen,...]
import { chromium } from "playwright";
import http from "node:http";
import fs from "node:fs";
import path from "node:path";

const root = path.resolve(process.argv[2] ?? "../build/web");
const out = path.resolve(process.argv[3] ?? "screens");
const only = process.argv[4]?.split(",");
fs.mkdirSync(out, { recursive: true });

const SCREENS = ["play", "critters", "detail", "dex", "dex_entry", "bag", "fuse", "summon", "week", "arena", "spire", "bracket", "friends", "account", "shop", "pass", "world", "campaign", "factions", "faction"];
const SIZES = { phone: { width: 390, height: 844 }, small: { width: 375, height: 667 } };

const types = { ".html": "text/html", ".js": "text/javascript", ".wasm": "application/wasm", ".pck": "application/octet-stream", ".png": "image/png" };
const server = http.createServer((req, res) => {
  const file = path.join(root, decodeURIComponent(new URL(req.url, "http://x").pathname));
  const target = fs.existsSync(file) && fs.statSync(file).isDirectory() ? path.join(file, "index.html") : file;
  if (!target.startsWith(root) || !fs.existsSync(target)) return res.writeHead(404).end();
  res.writeHead(200, { "Content-Type": types[path.extname(target)] ?? "application/octet-stream" });
  fs.createReadStream(target).pipe(res);
});
await new Promise((r) => server.listen(0, "127.0.0.1", r));
const base = `http://127.0.0.1:${server.address().port}/`;
const launchOptions = { args: ["--use-gl=angle", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"] };
if (process.env.CHROMIUM_PATH) launchOptions.executablePath = process.env.CHROMIUM_PATH;
const browser = await chromium.launch(launchOptions);

async function shoot(screen, sizeName, large, extra = process.env.EXTRA ?? "") {
  const page = await browser.newPage({ viewport: SIZES[sizeName], deviceScaleFactor: 2, hasTouch: true });
  const logs = [];
  page.on("console", (m) => logs.push(m.text()));
  const id = screen === "detail" || screen === "dex_entry" ? "&id=vampire" : screen === "faction" ? "&id=spooky" : "";
  await page.goto(`${base}?demo=1&offline=1&seed=7&screen=${screen}${id}${large ? "&text=large" : ""}${extra}`);
  const t0 = Date.now();
  while (!logs.some((l) => l.startsWith(`UI_SCREEN ${screen}`)) && Date.now() - t0 < 60000) await page.waitForTimeout(200);
  await page.waitForTimeout(1200);
  const name = `${screen}-${sizeName}${large ? "-large" : ""}.png`;
  await page.screenshot({ path: path.join(out, name) });
  const fit = logs.filter((l) => l.startsWith("UI_FIT ")).pop();
  console.log(name, fit ?? "");
  await page.close();
}

for (const screen of only ?? SCREENS)
  for (const size of Object.keys(SIZES))
    for (const large of [false, true]) await shoot(screen, size, large);
await browser.close();
server.close();

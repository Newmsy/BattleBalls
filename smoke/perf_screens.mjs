// Times every home screen's open in the web build (?perftour=1, see
// game/perf_tour.gd). Not part of CI. CPU throttle approximates a phone.
// Usage: [THROTTLE=4] [ONLY=play,campaign] [EXTRA=&copies=160] node perf_screens.mjs [path/to/build/web]
import { chromium } from "playwright";
import http from "node:http";
import fs from "node:fs";
import path from "node:path";

const root = path.resolve(process.argv[2] ?? "../build/web");
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
const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2, hasTouch: true });
const cdp = await page.context().newCDPSession(page);
await cdp.send("Emulation.setCPUThrottlingRate", { rate: Number(process.env.THROTTLE ?? 4) });
const rows = {};
let done = false;
page.on("console", (m) => {
  const t = m.text();
  if (t.startsWith("PERF_TOUR_DONE")) done = true;
  const p = t.match(/^PERF_SCREEN (\w+) (\w+) build (\d+) frame (\d+)/);
  if (p) (rows[p[2]] ??= {})[p[1]] = { build: +p[3], frame: +p[4] };
  if (t.includes("SCRIPT ERROR") || t.includes("ERROR:")) console.log(t);
});
const only = process.env.ONLY ? `=${process.env.ONLY}` : "=1";
await page.goto(`${base}?demo=1&offline=1&seed=7&perftour${only}${process.env.EXTRA ?? ""}`);
const t0 = Date.now();
while (!done && Date.now() - t0 < 600000) await page.waitForTimeout(500);
const list = Object.entries(rows).sort((a, b) => (b[1].cold?.frame ?? 0) - (a[1].cold?.frame ?? 0));
console.log("screen".padEnd(14), "cold build/frame".padEnd(18), "warm build/frame");
for (const [name, r] of list)
  console.log(name.padEnd(14), `${r.cold?.build}/${r.cold?.frame} ms`.padEnd(18), `${r.warm?.build}/${r.warm?.frame} ms`);
await browser.close();
server.close();

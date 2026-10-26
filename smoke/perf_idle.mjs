// What the web build costs while you just look at it: per idle screen
// (?perfidle, see game/perf_tour.gd) and per second of a fight. Not part of CI.
// Prints frames drawn/s, WebGL calls/s and per drawn frame, and browser main
// thread CPU (ms per second) from the DevTools Performance metrics.
// Usage: [THROTTLE=1] [ONLY=home,summon] [FIGHT=p1=vampire&p2=beacon] node perf_idle.mjs [path/to/build/web]
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
await cdp.send("Performance.enable");
await cdp.send("Emulation.setCPUThrottlingRate", { rate: Number(process.env.THROTTLE ?? 1) });
// Count WebGL calls, and frames that issued any (drawn frames).
await page.addInitScript(() => {
  const st = (window.__gl = { calls: 0, frames: 0, raf: 0, by: {} });
  for (const C of [window.WebGL2RenderingContext, window.WebGLRenderingContext]) {
    if (!C) continue;
    for (const k of Object.getOwnPropertyNames(C.prototype)) {
      const d = Object.getOwnPropertyDescriptor(C.prototype, k);
      if (typeof d.value !== "function" || k === "constructor") continue;
      const f = d.value;
      C.prototype[k] = function (...a) { st.calls++; st.by[k] = (st.by[k] ?? 0) + 1; return f.apply(this, a); };
    }
  }
  const raf = window.requestAnimationFrame.bind(window);
  window.requestAnimationFrame = (cb) => raf((t) => {
    st.raf++;
    const before = st.calls;
    cb(t);
    if (st.calls > before) st.frames++;
  });
});
const cpu = async () => {
  const m = Object.fromEntries((await cdp.send("Performance.getMetrics")).metrics.map((x) => [x.name, x.value]));
  return { task: m.TaskDuration * 1000, script: m.ScriptDuration * 1000, t: Date.now() };
};
const snap = async () => ({ ...(await page.evaluate(() => JSON.parse(JSON.stringify(window.__gl)))), ...(await cpu()) });
const row = (name, a, b) => {
  if (process.env.BY) console.log(Object.entries(b.by).map(([k, v]) => [k, v - (a.by[k] ?? 0)]).sort((x, y) => y[1] - x[1]).slice(0, 12).map(([k, v]) => `${k}:${(v / Math.max(1, b.frames - a.frames)).toFixed(0)}`).join(" "));
  const s = (b.t - a.t) / 1000, fr = b.frames - a.frames;
  console.log(name.padEnd(14), `${(fr / s).toFixed(1)}`.padStart(6), `${((b.calls - a.calls) / s).toFixed(0)}`.padStart(8),
    `${fr ? ((b.calls - a.calls) / fr).toFixed(0) : "-"}`.padStart(8), `${((b.task - a.task) / s).toFixed(0)}`.padStart(8), "  " + (extra[name] ?? ""));
};
const extra = {};
let begin = null, pending = [], done = false;
page.on("console", (m) => {
  const t = m.text();
  if (t.includes("SCRIPT ERROR")) console.log(t);
  pending.push(t);
});
console.log("screen".padEnd(14), "fps".padStart(6), "gl/s".padStart(8), "gl/frame".padStart(8), "cpu ms/s".padStart(8), "  godot drawn/ticks/process");
if (process.env.FIGHT) {
  await page.goto(`${base}?offline=1&seed=7&aim=-450&auto=1&${process.env.FIGHT}`);
  const t0 = Date.now();
  while (!pending.some((t) => t.startsWith("FIGHT_START")) && Date.now() - t0 < 60000) await page.waitForTimeout(100);
  await page.waitForTimeout(1500);
  const a = await snap();
  await page.waitForTimeout(Number(process.env.SECS ?? 6) * 1000);
  row("fight", a, await snap());
} else {
  const only = process.env.ONLY ? `=${process.env.ONLY}` : "=1";
  await page.goto(`${base}?demo=1&offline=1&seed=7&perfidle${only}${process.env.EXTRA ?? ""}`);
  const t0 = Date.now();
  while (!done && Date.now() - t0 < 900000) {
    await page.waitForTimeout(50);
    for (const t of pending.splice(0)) {
      if (t.startsWith("PERF_IDLE_BEGIN")) begin = await snap();
      const p = t.match(/^PERF_IDLE (\w+) (.*)/);
      if (p && begin) { extra[p[1]] = p[2]; row(p[1], begin, await snap()); }
      if (t.startsWith("PERF_IDLE_DONE")) done = true;
    }
  }
}
await browser.close();
server.close();

// Renders every Bounce Run event scene in tools/event_art/scenes/*.mjs (each
// default-exports a function returning a 720x440 SVG string) into
// game/bounce_run/art/<name>.png (720x440). The art is static: the game shows
// it as a plain texture, so it costs nothing per frame. Each PNG's .import
// keeps it lossy-compressed (compress/mode=1) so the web download stays small.
// Files starting with _ are shared parts (and the Buttons icon reference).
// A scene may also `export const size = [w, h]` (default 720x440) and
// `export const transparent = true` to render on a transparent background
// (used by the map's node tokens), `export const dir = "game/..."` to write
// somewhere other than game/bounce_run/art (the Home screen art), and
// `export const many = { name: fn }` to render several pictures from one file
// (with `export const sizes = { name: [w, h] }` where one differs from `size`).
// Usage (from the repo root): node tools/event_art/render.mjs [name ...]
import { createRequire } from "node:module";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, "../..");
let chromium;
try {
  chromium = createRequire(path.join(repo, "smoke/package.json"))("playwright").chromium;
} catch {
  chromium = createRequire(import.meta.url)("playwright").chromium;
}
const src = path.join(here, "scenes");
const dst = path.join(repo, "game/bounce_run/art");
fs.mkdirSync(dst, { recursive: true });
const only = process.argv.slice(2);
const names = fs.readdirSync(src).filter((f) => f.endsWith(".mjs") && !f.startsWith("_")).map((f) => f.slice(0, -4))
  .filter((n) => !only.length || only.includes(n));

const browser = await chromium.launch(process.env.CHROMIUM_PATH ? { executablePath: process.env.CHROMIUM_PATH } : {});
const page = await browser.newPage({ viewport: { width: 720, height: 440 } });
for (const n of names) {
  const mod = await import(pathToFileURL(path.join(src, n + ".mjs")).href);
  const [W, H] = mod.size || [720, 440];
  const bg = mod.transparent ? "transparent" : "#0D0F26";
  const out = mod.dir ? path.join(repo, mod.dir) : dst;
  fs.mkdirSync(out, { recursive: true });
  for (const [name, draw] of mod.many ? Object.entries(mod.many) : [[n, mod.default]]) {
    const [w, h] = (mod.sizes && mod.sizes[name]) || [W, H];
    await page.setViewportSize({ width: w, height: h });
    await page.setContent(`<html><body style="margin:0;background:${bg}">${draw()}</body></html>`);
    const file = path.join(out, name + ".png");
    await page.screenshot({ path: file, clip: { x: 0, y: 0, width: w, height: h }, omitBackground: !!mod.transparent });
    console.log(path.relative(repo, file));
  }
}
await browser.close();

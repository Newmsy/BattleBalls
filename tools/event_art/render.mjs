// Renders every Bounce Run event scene in tools/event_art/scenes/*.mjs (each
// default-exports a function returning a 720x440 SVG string) into
// game/bounce_run/art/<name>.png (720x440). The art is static: the game shows
// it as a plain texture, so it costs nothing per frame. Each PNG's .import
// keeps it lossy-compressed (compress/mode=1) so the web download stays small.
// Files starting with _ are shared parts (and the Buttons icon reference).
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
const W = 720, H = 440;
const src = path.join(here, "scenes");
const dst = path.join(repo, "game/bounce_run/art");
fs.mkdirSync(dst, { recursive: true });
const only = process.argv.slice(2);
const names = fs.readdirSync(src).filter((f) => f.endsWith(".mjs") && !f.startsWith("_")).map((f) => f.slice(0, -4))
  .filter((n) => !only.length || only.includes(n));

const browser = await chromium.launch(process.env.CHROMIUM_PATH ? { executablePath: process.env.CHROMIUM_PATH } : {});
const page = await browser.newPage({ viewport: { width: W, height: H } });
for (const n of names) {
  const svg = (await import(pathToFileURL(path.join(src, n + ".mjs")).href)).default();
  await page.setContent(`<html><body style="margin:0;background:#0D0F26">${svg}</body></html>`);
  const file = path.join(dst, n + ".png");
  await page.screenshot({ path: file, clip: { x: 0, y: 0, width: W, height: H } });
  console.log(path.relative(repo, file));
}
await browser.close();

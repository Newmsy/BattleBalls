// Renders the Summon tab paintings in tools/summon_art/scenes/*.mjs into
// game/ui/art/summon/<name>.png at 1x. Like tools/event_art: each scene
// default-exports a function returning an SVG string, may export `size`
// ([w, h]) and `transparent`, and may export `many` ({name: fn}) to render
// several PNGs from one file. Files starting with _ are shared parts.
// The game shows them as plain textures, so they cost nothing per frame.
// Usage (from the repo root): node tools/summon_art/render.mjs [scene ...]
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
const dst = path.join(repo, "game/ui/art/summon");
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
  for (const [name, fn] of mod.many ? Object.entries(mod.many) : [[n, mod.default]]) {
    await page.setViewportSize({ width: W, height: H });
    await page.setContent(`<html><body style="margin:0;background:${bg}">${fn()}</body></html>`);
    const file = path.join(dst, name + ".png");
    await page.screenshot({ path: file, clip: { x: 0, y: 0, width: W, height: H }, omitBackground: !!mod.transparent });
    console.log(path.relative(repo, file));
  }
}
await browser.close();

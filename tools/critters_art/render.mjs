// Renders the Critters tab paintings in tools/critters_art/scenes/*.mjs (each
// exports `size` and default-exports a function returning an SVG string) into
// game/ui/art/<name>.png: the Den band over My critters (band_den), and one
// home per family (scene hab_<family> -> game/ui/art/families/<family>.png)
// used by the critter cards, the critter page and the Summon screen.
// Shown as static textures (game/ui/painted.gd), so free per frame. Habitats:
// 780x460 with an empty lit stage centred (200, 330) for a critter of radius
// ~110 at (200, 250), calm on the right for text. Files starting with _ are
// shared parts. A scene's `many` export (a check image with a critter on the
// stage) is not rendered here.
// Usage (from the repo root): node tools/critters_art/render.mjs [name ...]
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
const dst = path.join(repo, "game/ui/art");
fs.mkdirSync(dst, { recursive: true });
const only = process.argv.slice(2);
const names = fs.readdirSync(src).filter((f) => f.endsWith(".mjs") && !f.startsWith("_")).map((f) => f.slice(0, -4))
  .filter((n) => !only.length || only.includes(n));

const browser = await chromium.launch(process.env.CHROMIUM_PATH ? { executablePath: process.env.CHROMIUM_PATH } : {});
const page = await browser.newPage({ viewport: { width: 780, height: 460 } });
for (const n of names) {
  const mod = await import(pathToFileURL(path.join(src, n + ".mjs")).href);
  const [W, H] = mod.size;
  await page.setViewportSize({ width: W, height: H });
  await page.setContent(`<html><body style="margin:0;background:#0D0F26">${mod.default()}</body></html>`);
  const file = n.startsWith("hab_") ? path.join(dst, "families", n.slice(4) + ".png") : path.join(dst, n + ".png");
  fs.mkdirSync(path.dirname(file), { recursive: true });
  await page.screenshot({ path: file, clip: { x: 0, y: 0, width: W, height: H } });
  console.log(path.relative(repo, file));
}
await browser.close();

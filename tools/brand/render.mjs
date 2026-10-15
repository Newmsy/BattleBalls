// Renders every brand image from designs.mjs into game/brand/.
// Usage (from the repo root, after `cd smoke && npm ci`):
//   NODE_PATH=smoke/node_modules node tools/brand/render.mjs
// Needs ImageMagick (`convert`) to strip the alpha channel from store icons,
// which Apple rejects even when every pixel is opaque.
import { createRequire } from "node:module";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import * as D from "./designs.mjs";

const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, "../..");
const require = createRequire(path.join(repo, "smoke/package.json"));
const { chromium } = require("playwright");
// Inlined: a page made with setContent may not load file:// fonts.
const font = "data:font/ttf;base64," + fs.readFileSync(path.join(repo, "game/fonts/ChakraPetch-Bold.ttf")).toString("base64");
const out = (p) => {
  const f = path.join(repo, "game/brand", p);
  fs.mkdirSync(path.dirname(f), { recursive: true });
  return f;
};

const browser = await chromium.launch(process.env.CHROMIUM_PATH ? { executablePath: process.env.CHROMIUM_PATH } : {});
const page = await browser.newPage();

// Draws an SVG at w x h (scaled from its own size) and saves a PNG.
async function render(svg, file, w, h = w, { transparent = false, opaque = false } = {}) {
  await page.setViewportSize({ width: w, height: h });
  const sized = svg.replace(/width="\d+" height="\d+"/, `width="${w}" height="${h}"`);
  await page.setContent(`<html><body style="margin:0;background:transparent">${sized}</body></html>`);
  await page.evaluate(() => document.fonts.ready);
  await page.screenshot({ path: file, omitBackground: transparent, clip: { x: 0, y: 0, width: w, height: h } });
  if (opaque) execFileSync("convert", [file, "-background", D.NAVY, "-alpha", "remove", "-alpha", "off", file]);
  console.log(path.relative(repo, file));
}

const icon = D.icon();
await render(icon, out("icon.png"), 512);
await render(D.logo(font), out("splash.png"), 768, 768, { transparent: true });

for (const s of [1024, 180, 167, 152, 120, 87, 80, 76, 60, 58, 40]) {
  await render(icon, out(`store/ios/icon_${s}.png`), s, s, { opaque: true });
}
await render(icon, out("store/android/main_192.png"), 192);
await render(D.adaptiveForeground(), out("store/android/adaptive_foreground_432.png"), 432, 432, { transparent: true });
await render(D.adaptiveBackground(), out("store/android/adaptive_background_432.png"), 432, 432, { opaque: true });
await render(icon, out("store/play/icon_512.png"), 512, 512, { opaque: true });
await render(D.featureGraphic(font), out("store/play/feature_graphic_1024x500.png"), 1024, 500, { opaque: true });

await browser.close();

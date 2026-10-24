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
// `export const many = { name: fn }` to render several pictures from one file.
//
// Living layers: wrap a part that should move (a critter, a scarf, a lantern)
// in <g data-layer="rival" data-move="bob 5 0.7 0">. The picture's PNG is
// then the background plate with every layer left out, and each layer is
// cut out on its own (transparent, cropped) to <name>_<layer>.png, so the
// game moves the whole part over a clean background instead of warping the
// flat picture. data-move is "kind amount speed(Hz) phase(0-1)", kinds:
// bob (px up/down), sway (degrees, pivots at data-pivot "x y", default the
// part's bottom centre), breathe (squash and stretch, fraction), idle (bob
// px plus a little breathe), still (no motion: a static part that sits in
// front of a moving one). A layer with eyes drawn by parts.mjs eye() also
// gets a <name>_<layer>_blink.png frame. data-follow="rival" makes a part
// (a scarf tail) ride along with another layer's motion on top of its own. Layers draw in document order, so
// anything static drawn over a moving part must be its own still layer.
// Layer rects, moves and pivots go to tools/event_art/layers.json and
// game/bounce_run/living_layers.gd (what LivingArt reads).
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
const cut = await browser.newPage();
const manifestFile = path.join(here, "layers.json");
const manifest = fs.existsSync(manifestFile) ? JSON.parse(fs.readFileSync(manifestFile, "utf8")) : {};
// Defs, clip paths, masks and patterns must stay visible or a hidden plate
// would stop clipping (or <use>-cloning into) the layer being cut out.
const ONLY = (id) => `svg{visibility:hidden}[data-layer="${id}"],defs,defs *,clipPath,clipPath *,mask,mask *,pattern *{visibility:visible}`;
const BLINK = ".la-eye{display:none}.la-shut{display:inline}";

// The smallest box (padded 2px, within the picture) holding every visible
// pixel of a transparent screenshot, or null when it's empty.
async function usedRect(png, W, H) {
  return cut.evaluate(async ([b64, W, H]) => {
    const img = new Image();
    img.src = "data:image/png;base64," + b64;
    await img.decode();
    const c = document.createElement("canvas");
    c.width = W; c.height = H;
    const g = c.getContext("2d");
    g.drawImage(img, 0, 0);
    const d = g.getImageData(0, 0, W, H).data;
    let x0 = W, y0 = H, x1 = -1, y1 = -1;
    for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
      if (d[(y * W + x) * 4 + 3] > 2) { x0 = Math.min(x0, x); x1 = Math.max(x1, x); y0 = Math.min(y0, y); y1 = Math.max(y1, y); }
    }
    if (x1 < 0) return null;
    x0 = Math.max(0, x0 - 2); y0 = Math.max(0, y0 - 2);
    return [x0, y0, Math.min(W, x1 + 3) - x0, Math.min(H, y1 + 3) - y0];
  }, [png.toString("base64"), W, H]);
}

// Godot's import settings for a new PNG (lossy, like the paintings).
function importFor(file) {
  const f = file + ".import";
  if (fs.existsSync(f)) return;
  fs.writeFileSync(f, `[remap]\n\nimporter="texture"\ntype="CompressedTexture2D"\n\n[params]\n\ncompress/mode=1\ncompress/lossy_quality=0.85\nmipmaps/generate=false\nprocess/fix_alpha_border=true\n`);
}

for (const n of names) {
  const mod = await import(pathToFileURL(path.join(src, n + ".mjs")).href);
  const [W, H] = mod.size || [720, 440];
  const bg = mod.transparent ? "transparent" : "#0D0F26";
  const out = mod.dir ? path.join(repo, mod.dir) : dst;
  fs.mkdirSync(out, { recursive: true });
  for (const [name, draw] of mod.many ? Object.entries(mod.many) : [[n, mod.default]]) {
    await page.setViewportSize({ width: W, height: H });
    await page.setContent(`<html><head><style id="la"></style></head><body style="margin:0;background:${bg}">${draw()}</body></html>`);
    const style = (css) => page.evaluate((css) => { document.getElementById("la").textContent = css; }, css);
    const layers = await page.evaluate(() => [...document.querySelectorAll("[data-layer]")].map((e) => {
      const b = e.getBoundingClientRect();
      const p = (e.getAttribute("data-pivot") || "").split(/\s+/).filter(Boolean).map(Number);
      return {
        id: e.getAttribute("data-layer"),
        move: (e.getAttribute("data-move") || "still").trim(),
        pivot: p.length == 2 ? p : [Math.round(b.x + b.width / 2), Math.round(b.y + b.height)],
        blink: !!e.querySelector(".la-eye"),
        follow: e.getAttribute("data-follow") || "",
      };
    }));
    await style(layers.length ? "[data-layer]{display:none}" : "");
    const file = path.join(out, name + ".png");
    await page.screenshot({ path: file, clip: { x: 0, y: 0, width: W, height: H }, omitBackground: !!mod.transparent });
    console.log(path.relative(repo, file));
    const kept = [], made = new Set();
    for (const l of layers) {
      await page.evaluate(() => { document.body.style.background = "transparent"; });
      await style(ONLY(l.id));
      const full = await page.screenshot({ clip: { x: 0, y: 0, width: W, height: H }, omitBackground: true });
      const rect = await usedRect(full, W, H);
      if (!rect) continue;
      const clip = { x: rect[0], y: rect[1], width: rect[2], height: rect[3] };
      const lf = path.join(out, `${name}_L${l.id}.png`);
      await page.screenshot({ path: lf, clip, omitBackground: true });
      importFor(lf);
      made.add(path.basename(lf));
      console.log("  " + path.relative(repo, lf), l.move);
      if (l.blink) {
        await style(ONLY(l.id) + BLINK);
        const bf = path.join(out, `${name}_L${l.id}_blink.png`);
        await page.screenshot({ path: bf, clip, omitBackground: true });
        importFor(bf);
        made.add(path.basename(bf));
      }
      kept.push({ ...l, rect });
    }
    // Layers this picture no longer has.
    for (const f of fs.readdirSync(out).filter((f) => f.startsWith(name + "_L") && /\.png(\.import)?$/.test(f))) {
      if (!made.has(f.replace(/\.import$/, ""))) fs.rmSync(path.join(out, f));
    }
    await page.evaluate((bg) => { document.body.style.background = bg; }, bg);
    if (kept.length) manifest[name] = { size: [W, H], layers: kept };
    else delete manifest[name];
  }
}
await browser.close();

// The manifest, and the same as GDScript constants for the game.
const sorted = Object.fromEntries(Object.keys(manifest).sort().map((k) => [k, manifest[k]]));
fs.writeFileSync(manifestFile, JSON.stringify(sorted, null, 1) + "\n");
const KINDS = { still: 0, bob: 1, sway: 2, breathe: 3, idle: 4 };
let gd = `## Generated by tools/event_art/render.mjs from the scenes' data-layer parts: do not edit.
## Per painting, its moving layers in drawing order: [file suffix, rect (art px),
## move (kind, amount, speed Hz, phase), pivot (art px), has a blink frame,
## the index of the layer it rides along with (-1 none)].
## Kinds: 0 still, 1 bob, 2 sway, 3 breathe, 4 idle (see LivingArt).
const LAYERS := {\n`;
for (const [k, v] of Object.entries(sorted)) {
  gd += `\t"${k}": [\n`;
  for (const l of v.layers) {
    const [kind, a = 0, hz = 0.5, ph = 0] = l.move.split(/\s+/);
    if (!(kind in KINDS)) throw new Error(`${k}: unknown move "${l.move}"`);
    const parent = v.layers.findIndex((o) => o.id == l.follow);
    if (l.follow && parent < 0) throw new Error(`${k}: ${l.id} follows a missing layer "${l.follow}"`);
    gd += `\t\t["_L${l.id}", Rect2(${l.rect.join(", ")}), Vector4(${KINDS[kind]}, ${+a}, ${+hz}, ${+ph}), Vector2(${l.pivot.map((n) => Math.round(n)).join(", ")}), ${l.blink}, ${parent}],\n`;
  }
  gd += `\t],\n`;
}
gd += "}\n";
fs.writeFileSync(path.join(repo, "game/bounce_run/living_layers.gd"), gd);

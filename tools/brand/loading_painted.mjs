// Painted loading screens in the Bounce Run / Home event-art style: one calm
// scene, soft painted light, critters drawn by the event-art critter() so
// they match the rest of the painted screens. 853x1844 portrait; the title
// sits in the top band and the web page's progress bar and tip sit over the
// bottom ~16%, so that band stays quiet ground.
// The moonlit arena ("clash" draft) is the loading picture; game/ui/splash_art.gd and
// game/web/shell.html move lights at spots on it, so keep those in step.
// Usage (from the repo root, after `cd smoke && npm ci`):
//   node tools/brand/loading_painted.mjs [outdir] [name ...]  -> <outdir>/loading_<name>.png
//   node tools/brand/loading_painted.mjs ship clash  -> game/brand/loading.png + site/loading.webp
import { createRequire } from "node:module";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { blurs, rng, sparkle } from "../event_art/scenes/_shop_charge_pad_glow_chest_parts.mjs";
import { critter, shadow, motes, FAM } from "../event_art/scenes/_banner_parts.mjs";
import { shade } from "./parts.mjs";

const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, "../..");
export const W = 853, H = 1844;
const f = (n) => (+n).toFixed(1);
const font = "data:font/ttf;base64," + fs.readFileSync(path.join(repo, "game/fonts/ChakraPetch-Bold.ttf")).toString("base64");

const svg = (body) => `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">
  <defs><style>@font-face { font-family: Chakra; src: url(${font}); }</style></defs>${blurs()}${body}</svg>`;

// The title: cream and gold letters with a thick ink outline and a hard
// drop shadow, like a painted sign. No glow.
function title(y0, { ink = "#1d1233", top = "#fff8e6", gold = "#ffc93c", shadowOp = 0.45 } = {}) {
  const word = (text, y, size, a, b) => `
    <text x="${W / 2}" y="${y + size * 0.07}" font-family="Chakra" font-size="${size}" text-anchor="middle" fill="${ink}" opacity="${shadowOp}" stroke="${ink}" stroke-width="${size * 0.16}" stroke-linejoin="round">${text}</text>
    <text x="${W / 2}" y="${y}" font-family="Chakra" font-size="${size}" text-anchor="middle" fill="${ink}" stroke="${ink}" stroke-width="${size * 0.15}" stroke-linejoin="round">${text}</text>
    <defs><linearGradient id="tg${size}" x1="0" y1="0" x2="0" y2="1"><stop offset="0.1" stop-color="${a}"/><stop offset="1" stop-color="${b}"/></linearGradient></defs>
    <text x="${W / 2}" y="${y}" font-family="Chakra" font-size="${size}" text-anchor="middle" fill="url(#tg${size})">${text}</text>
    <text x="${W / 2}" y="${y}" font-family="Chakra" font-size="${size}" text-anchor="middle" fill="none" stroke="#fff" stroke-opacity="0.35" stroke-width="3" transform="translate(-2 -3)">${text}</text>`;
  return `${word("BATTLE", y0, 138, top, shade(top, -0.12))}${word("BALLS", y0 + 168, 190, "#fff1a8", gold)}`;
}

// Soft dark fade over the bottom so the progress bar and tip read.
const footFade = (col, o = 0.7) => `<defs><linearGradient id="foot" x1="0" y1="0" x2="0" y2="1"><stop offset="0.78" stop-color="${col}" stop-opacity="0"/><stop offset="1" stop-color="${col}" stop-opacity="${o}"/></linearGradient></defs>
  <rect width="${W}" height="${H}" fill="url(#foot)"/>`;

function grass(seed, n, y0, y1, cols, scale = 1) {
  const R = rng(seed);
  let out = "";
  for (let k = 0; k < n; k++) {
    const x = R() * (W + 20) - 10, y = y0 + R() * (y1 - y0), h = (10 + R() * 18) * scale * (0.5 + (y - y0) / (y1 - y0));
    out += `<path d="M ${f(x)} ${f(y)} q -4 ${f(-h * 0.6)} -9 ${f(-h)} M ${f(x)} ${f(y)} q 1 ${f(-h * 0.7)} 3 ${f(-h * 1.2)} M ${f(x)} ${f(y)} q 5 ${f(-h * 0.5)} 10 ${f(-h * 0.9)}" stroke="${cols[k % cols.length]}" stroke-width="${f(2.6 * scale)}" fill="none" stroke-linecap="round"/>`;
  }
  return out;
}

function stars(seed, n, y1) {
  const R = rng(seed);
  let out = "";
  for (let k = 0; k < n; k++) {
    const x = R() * W, y = R() * y1, s = R();
    out += `<circle cx="${f(x)}" cy="${f(y)}" r="${f(0.8 + s * s * 2.4)}" fill="${s > 0.8 ? "#ffe9c4" : "#ece6ff"}" opacity="${f(0.25 + s * 0.6)}"/>`;
  }
  for (let k = 0; k < 7; k++) out += sparkle(R() * W, R() * y1 * 0.8, 5 + R() * 6, "#efe8ff", 0.5 + R() * 0.4);
  return out;
}

function tree(x, y, s, col) {
  return `<path d="M ${x} ${y} L ${x} ${y - 60 * s}" stroke="${col}" stroke-width="${12 * s}"/>
    <circle cx="${x}" cy="${y - 92 * s}" r="${50 * s}" fill="${col}"/><circle cx="${x - 30 * s}" cy="${y - 64 * s}" r="${32 * s}" fill="${col}"/><circle cx="${x + 32 * s}" cy="${y - 68 * s}" r="${36 * s}" fill="${col}"/>`;
}

function pine(x, y, s, col) {
  return `<path d="M ${x} ${y - 150 * s} L ${x + 34 * s} ${y - 80 * s} L ${x + 20 * s} ${y - 80 * s} L ${x + 50 * s} ${y - 20 * s} L ${x + 8 * s} ${y - 20 * s} L ${x + 8 * s} ${y} L ${x - 8 * s} ${y} L ${x - 8 * s} ${y - 20 * s} L ${x - 50 * s} ${y - 20 * s} L ${x - 20 * s} ${y - 80 * s} L ${x - 34 * s} ${y - 80 * s} Z" fill="${col}"/>`;
}

// The game's square arena seen from the front and above: a stone floor with
// a low wall and four corner lamps. cx, cy = floor centre.
function squareArena(cx, cy, w, d, { floor = "#3a4a5a", line = "#7dffb0", wall = "#24303e", wallTop = "#4a5c6c", lamp = "#ffd36b" } = {}) {
  const t = w * 0.3; // the far edge is narrower (perspective)
  const fl = [[cx - t, cy - d / 2], [cx + t, cy - d / 2], [cx + w / 2, cy + d / 2], [cx - w / 2, cy + d / 2]];
  const P = (pts) => pts.map((p) => p.map(f).join(",")).join(" ");
  const lift = 26;
  const front = [[cx - w / 2, cy + d / 2], [cx + w / 2, cy + d / 2], [cx + w / 2, cy + d / 2 + lift * 1.6], [cx - w / 2, cy + d / 2 + lift * 1.6]];
  let tiles = "";
  for (let k = 1; k < 6; k++) {
    const u = k / 6;
    const yy = cy - d / 2 + d * u * (0.85 + 0.15 * u), half = t + (w / 2 - t) * ((yy - (cy - d / 2)) / d);
    tiles += `<line x1="${f(cx - half)}" y1="${f(yy)}" x2="${f(cx + half)}" y2="${f(yy)}"/>`;
    const xt = cx - t + 2 * t * u, xb = cx - w / 2 + w * u;
    tiles += `<line x1="${f(xt)}" y1="${f(cy - d / 2)}" x2="${f(xb)}" y2="${f(cy + d / 2)}"/>`;
  }
  const lamps = fl.map(([x, y], k) => {
    const s = k < 2 ? 0.7 : 1;
    return `<rect x="${f(x - 9 * s)}" y="${f(y - 54 * s)}" width="${f(18 * s)}" height="${f(54 * s)}" rx="${f(4 * s)}" fill="${wall}" stroke="#0e1420" stroke-width="2"/>
      <circle cx="${f(x)}" cy="${f(y - 62 * s)}" r="${f(38 * s)}" fill="${lamp}" opacity="0.28" filter="url(#bl16)"/>
      <circle cx="${f(x)}" cy="${f(y - 62 * s)}" r="${f(12 * s)}" fill="${shade(lamp, 0.5)}" stroke="${shade(lamp, -0.5)}" stroke-width="2"/>`;
  }).join("");
  return `
    <defs><radialGradient id="arFloor" cx="0.5" cy="0.55" r="0.65"><stop offset="0" stop-color="${shade(floor, 0.25)}"/><stop offset="1" stop-color="${shade(floor, -0.3)}"/></radialGradient></defs>
    <ellipse cx="${cx}" cy="${cy + d * 0.58}" rx="${w * 0.62}" ry="${d * 0.22}" fill="#000" opacity="0.4" filter="url(#bl12)"/>
    <polygon points="${P(front)}" fill="${wall}" stroke="#0e1420" stroke-width="3"/>
    <polygon points="${P(fl)}" fill="url(#arFloor)" stroke="${wallTop}" stroke-width="14" stroke-linejoin="round"/>
    <g stroke="${shade(floor, -0.35)}" stroke-width="2.5" opacity="0.7">${tiles}</g>
    <polygon points="${P(fl)}" fill="none" stroke="${line}" stroke-width="4" stroke-linejoin="round" opacity="0.8" transform="translate(0 0)"/>
    <polygon points="${P(fl)}" fill="none" stroke="#0e1420" stroke-width="2" stroke-linejoin="round"/>
    ${lamps}`;
}

// Fire breathed from a critter's open mouth (mx, my) toward (tx, ty).
function breath(mx, my, tx, ty, w0, w1, pal = ["#ff6a3d", "#ff7a2a", "#a8321a", "#ffc23d", "#fff0a0"]) {
  const dx = tx - mx, dy = ty - my, L = Math.hypot(dx, dy), ux = dx / L, uy = dy / L, nx = -uy, ny = ux;
  const pt = (t, side, wv) => { const w = w0 + (w1 - w0) * t; return [mx + dx * t + nx * side * w * wv, my + dy * t + ny * side * w * wv]; };
  const shape = (sc) => {
    const a = [0, 0.3, 0.6, 0.85].map((t, k) => pt(t, 1, sc * (k % 2 ? 1.1 : 0.85)));
    const b = [0.85, 0.6, 0.3, 0].map((t, k) => pt(t, -1, sc * (k % 2 ? 0.9 : 1.1)));
    const tip = [mx + dx * 1.04, my + dy * 1.04];
    return `M ${f(mx)} ${f(my)} ${a.map((p) => `L ${f(p[0])} ${f(p[1])}`).join(" ")} Q ${f(tip[0] + nx * w1 * sc)} ${f(tip[1] + ny * w1 * sc)} ${f(tip[0])} ${f(tip[1])} Q ${f(tip[0] - nx * w1 * sc)} ${f(tip[1] - ny * w1 * sc)} ${f(b[0][0])} ${f(b[0][1])} ${b.map((p) => `L ${f(p[0])} ${f(p[1])}`).join(" ")} Z`;
  };
  return `<path d="${shape(1.3)}" fill="${pal[0]}" opacity="0.35" filter="url(#bl12)"/>
    <path d="${shape(1)}" fill="${pal[1]}" stroke="${pal[2]}" stroke-width="3" stroke-linejoin="round"/>
    <path d="${shape(0.66)}" fill="${pal[3]}"/><path d="${shape(0.34)}" fill="${pal[4]}"/>`;
}

// --- A: Moonlit arena -----------------------------------------------------
// A stone square arena in a night meadow under a big moon; two critters
// clash mid-air over it, a few friends watch from the grass.
function moonlit() {
  const R = rng(5);
  const clash = [426, 1000];
  return svg(`
  <defs>
    <linearGradient id="mSky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0c1030"/><stop offset="0.38" stop-color="#1b3460"/><stop offset="0.56" stop-color="#2a6a70"/><stop offset="1" stop-color="#2a6a70"/></linearGradient>
    <linearGradient id="mGround" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#22564a"/><stop offset="1" stop-color="#0d1f24"/></linearGradient>
    <radialGradient id="mMoon" cx="0.42" cy="0.4" r="0.7"><stop offset="0" stop-color="#fffbe8"/><stop offset="1" stop-color="#e8e0c0"/></radialGradient>
    <radialGradient id="mHalo" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#dff4ff" stop-opacity="0.35"/><stop offset="1" stop-color="#dff4ff" stop-opacity="0"/></radialGradient>
  </defs>
  <rect width="${W}" height="${H}" fill="url(#mSky)"/>
  ${stars(3, 160, 900)}
  <circle cx="426" cy="740" r="440" fill="url(#mHalo)"/>
  <circle cx="426" cy="740" r="210" fill="url(#mMoon)"/>
  <circle cx="370" cy="690" r="30" fill="#d8cfae" opacity="0.5"/><circle cx="480" cy="800" r="22" fill="#d8cfae" opacity="0.45"/><circle cx="500" cy="670" r="14" fill="#d8cfae" opacity="0.4"/>
  <path d="M 0 960 Q 160 880 330 920 Q 470 950 600 900 Q 740 850 853 900 L 853 1100 L 0 1100 Z" fill="#1b3a4a"/>
  ${tree(70, 960, 1.4, "#132a3a")}${tree(230, 935, 1.0, "#132a3a")}${tree(640, 915, 1.1, "#132a3a")}${tree(800, 920, 1.5, "#132a3a")}
  <path d="M 0 1010 Q 220 980 430 1000 Q 650 1020 853 990 L 853 1844 L 0 1844 Z" fill="url(#mGround)"/>
  ${grass(14, 120, 1010, 1844, ["#2f6a4a", "#3a8a5a", "#245a40"], 1.3)}
  ${squareArena(426, 1290, 700, 260)}
  ${shadow(clash[0] - 125, 1310, 80, 0.45)}${shadow(clash[0] + 125, 1310, 80, 0.45)}
  <circle cx="${clash[0]}" cy="${clash[1]}" r="90" fill="#fff6c8" opacity="0.4" filter="url(#bl24)"/>
  ${[0, 1, 2, 3, 4, 5, 6, 7].map((k) => { const a = k * Math.PI / 4 + 0.2, r0 = 36, r1 = 70 + (k % 2) * 26; return `<line x1="${f(clash[0] + Math.cos(a) * r0)}" y1="${f(clash[1] + Math.sin(a) * r0)}" x2="${f(clash[0] + Math.cos(a) * r1)}" y2="${f(clash[1] + Math.sin(a) * r1)}" stroke="#fff3c0" stroke-width="7" stroke-linecap="round"/>`; }).join("")}
  <path d="M ${clash[0] - 360} ${clash[1] + 150} Q ${clash[0] - 290} ${clash[1] + 20} ${clash[0] - 190} ${clash[1] + 10}" fill="none" stroke="#ffb3a8" stroke-width="8" stroke-linecap="round" opacity="0.5" stroke-dasharray="2 18"/>
  <path d="M ${clash[0] + 360} ${clash[1] + 150} Q ${clash[0] + 290} ${clash[1] + 20} ${clash[0] + 190} ${clash[1] + 10}" fill="none" stroke="#a8e4ff" stroke-width="8" stroke-linecap="round" opacity="0.5" stroke-dasharray="2 18"/>
  ${critter(clash[0] - 128, clash[1] + 10, 108, "#e8465a", { acc: "horns", mood: "determined", look: [0.8, -0.1], rim: "#fff2c8", rimSide: 1, sx: 0.94, sy: 1.04 })}
  ${critter(clash[0] + 128, clash[1] + 10, 108, FAM.sea, { acc: "fin", mood: "determined", look: [-0.8, -0.1], rim: "#fff2c8", rimSide: -1, sx: 0.94, sy: 1.04 })}
  ${shadow(120, 1560, 56, 0.5)}${critter(120, 1505, 66, FAM.nature, { acc: "leaf", mood: "wow", look: [0.6, -0.6], rim: "#7dffb0", rimSide: 1 })}
  ${shadow(735, 1575, 50, 0.5)}${critter(735, 1525, 58, FAM.sweet, { acc: "ears", mood: "cheer", rim: "#ffd0ec", rimSide: -1 })}
  ${shadow(640, 1490, 32, 0.45)}${critter(640, 1458, 36, FAM.toybox, { acc: "propeller", mood: "wow", look: [-0.5, -0.7], rimSide: -1 })}
  ${motes(9, 46, 0, 1000, W, 1700, ["#d8ff7a", "#7dffb0", "#ffe9a8"])}
  ${title(250, { ink: "#0e1430" })}
  ${footFade("#0d1f24", 0.8)}`);
}

// --- A, detailed: the moonlit arena with a painted detail pass -------------
// Same layout (and so the same light spots) as moonlit(), with depth and
// texture: drifting clouds across the moon, three hill layers with moonlit
// tree crowns, a stone-block arena wall with moss, glowing Glow Garden
// mushrooms and bell flowers in the meadow, a stepping-stone path, framing
// ferns, and a crowd of little critters on the far hill. Variants:
// "festival" strings lights and bunting between the lamps and fills the
// crowd; "clash" turns the bump into a fire-against-water face-off (the fire
// comes from the red critter's mouth) with a burst of steam where they meet.
function cloudBand(x, y, s, lit = "#8fb0d8", body = "#2a3f6e") {
  return `<g opacity="0.92"><path d="M ${x - 150 * s} ${y} Q ${x - 140 * s} ${y - 40 * s} ${x - 90 * s} ${y - 36 * s} Q ${x - 70 * s} ${y - 80 * s} ${x - 10 * s} ${y - 70 * s} Q ${x + 30 * s} ${y - 104 * s} ${x + 80 * s} ${y - 66 * s} Q ${x + 140 * s} ${y - 70 * s} ${x + 150 * s} ${y} Z" fill="${body}"/>
    <path d="M ${x - 90 * s} ${y - 36 * s} Q ${x - 70 * s} ${y - 80 * s} ${x - 10 * s} ${y - 70 * s} Q ${x + 30 * s} ${y - 104 * s} ${x + 80 * s} ${y - 66 * s}" fill="none" stroke="${lit}" stroke-width="${6 * s}" stroke-linecap="round" opacity="0.8"/></g>`;
}

function litTree(x, y, s, col, lit) {
  return `${tree(x, y, s, col)}<circle cx="${f(x - 14 * s)}" cy="${f(y - 112 * s)}" r="${f(26 * s)}" fill="${lit}" opacity="0.55"/><circle cx="${f(x + 22 * s)}" cy="${f(y - 90 * s)}" r="${f(16 * s)}" fill="${lit}" opacity="0.4"/>`;
}

function glowShroom(x, y, s, cap, glow) {
  return `<ellipse cx="${x}" cy="${y - s * 1.1}" rx="${s * 1.5}" ry="${s}" fill="${glow}" opacity="0.28" filter="url(#bl12)"/>
    <path d="M ${x - s * 0.22} ${y} Q ${x - s * 0.3} ${y - s * 0.6} ${x - s * 0.16} ${y - s * 1.1} L ${x + s * 0.16} ${y - s * 1.1} Q ${x + s * 0.3} ${y - s * 0.6} ${x + s * 0.22} ${y} Z" fill="#e8e0c8" stroke="#2a3248" stroke-width="2.5"/>
    <path d="M ${x - s} ${y - s * 1.02} Q ${x - s * 0.9} ${y - s * 1.8} ${x} ${y - s * 1.84} Q ${x + s * 0.9} ${y - s * 1.8} ${x + s} ${y - s * 1.02} Q ${x} ${y - s * 1.2} ${x - s} ${y - s * 1.02} Z" fill="${cap}" stroke="${shade(cap, -0.55)}" stroke-width="3"/>
    <path d="M ${x - s * 0.7} ${y - s * 1.3} Q ${x - s * 0.4} ${y - s * 1.7} ${x + s * 0.1} ${y - s * 1.72}" fill="none" stroke="#fff" stroke-width="${s * 0.08}" opacity="0.35" stroke-linecap="round"/>
    ${[[-0.45, -1.4, 0.13], [0.2, -1.55, 0.1], [0.55, -1.25, 0.09], [-0.1, -1.25, 0.07]].map(([a, b, r]) => `<circle cx="${f(x + a * s)}" cy="${f(y + b * s)}" r="${f(r * s)}" fill="${glow}"/>`).join("")}`;
}

function bellFlower(x, y, h, col) {
  return `<path d="M ${x} ${y} Q ${x + 8} ${y - h * 0.6} ${x - 5} ${y - h}" fill="none" stroke="#2f6a4a" stroke-width="4"/>
    <circle cx="${x - 5}" cy="${y - h + 16}" r="12" fill="${col}" opacity="0.4" filter="url(#bl6)"/>
    <path d="M ${x - 5} ${y - h} q -13 5 -13 21 q 13 -5 13 -5 q 0 0 13 5 q 0 -16 -13 -21 Z" fill="${col}" stroke="${shade(col, -0.5)}" stroke-width="2"/>`;
}

function fern(x, y, s, flip, col) {
  let out = `<path d="M ${x} ${y} Q ${x + flip * 60 * s} ${y - 120 * s} ${x + flip * 170 * s} ${y - 170 * s}" fill="none" stroke="${col}" stroke-width="${7 * s}" stroke-linecap="round"/>`;
  for (let k = 1; k < 9; k++) {
    const t = k / 9, px = x + flip * (60 * s * 2 * t * (1 - t) + 170 * s * t * t), py = y - (120 * s * 2 * t * (1 - t) + 170 * s * t * t), L = 60 * s * (1 - t * 0.6);
    out += `<path d="M ${f(px)} ${f(py)} q ${f(flip * L * 0.3)} ${f(-L * 0.9)} ${f(flip * L * 0.9)} ${f(-L * 0.6)} q ${f(-flip * L * 0.4)} ${f(L * 0.3)} ${f(-flip * L * 0.9)} ${f(L * 0.6)} Z" fill="${col}"/>
      <path d="M ${f(px)} ${f(py)} q ${f(flip * L * 0.6)} ${f(L * 0.1)} ${f(flip * L)} ${f(L * 0.55)} q ${f(-flip * L * 0.5)} ${f(-L * 0.05)} ${f(-flip * L)} ${f(-L * 0.55)} Z" fill="${col}"/>`;
  }
  return out;
}

function moonDetail(variant = "detail") {
  const R = rng(11);
  const clash = [426, 1000];
  const festival = variant === "festival", fight = variant === "clash";
  // Moon craters with a lit lower rim.
  const craters = [[360, 680, 34], [482, 800, 26], [505, 660, 16], [330, 800, 14], [440, 610, 12], [540, 735, 20], [400, 860, 11]]
    .map(([x, y, r]) => `<circle cx="${x}" cy="${y}" r="${r}" fill="#d6cba4" opacity="0.55"/><path d="M ${x - r * 0.8} ${y + r * 0.4} A ${r} ${r} 0 0 0 ${x + r * 0.8} ${y + r * 0.4}" fill="none" stroke="#fffdf0" stroke-width="${f(r * 0.18)}" opacity="0.6"/>`).join("");
  // Far-hill crowd: tiny critters cheering along the ridge behind the arena.
  const crowdCols = [FAM.spooky, FAM.toybox, FAM.frost, FAM.fire, FAM.cosmic, FAM.nature, FAM.sweet, FAM.sea, FAM.tech];
  const crowdSpots = festival
    ? [[60, 1060, 26], [125, 1046, 24], [190, 1036, 27], [256, 1040, 22], [596, 1040, 22], [660, 1034, 27], [726, 1044, 24], [792, 1058, 26]]
    : [[140, 1046, 26], [214, 1036, 24], [640, 1036, 24], [714, 1046, 27]];
  const accs = ["horns", "propeller", "crystal", "flame", "orbit", "leaf", "ears", "fin", "antenna"];
  const crowd = crowdSpots.map(([x, y, r], k) => `${critter(x, y, r, crowdCols[k % 9], { acc: accs[k % 9], mood: k % 3 ? "cheer" : "wow", look: [x < 426 ? 0.6 : -0.6, 0], rim: "#e8f4ff", rimSide: x < 426 ? -1 : 1, glow: false })}
    ${festival && k % 2 === 0 ? `<line x1="${x + r * 0.9}" y1="${y}" x2="${x + r * 1.3}" y2="${y - r * 2.2}" stroke="#5a3a2a" stroke-width="3"/><path d="M ${x + r * 1.3} ${y - r * 2.2} l 24 8 l -24 9 Z" fill="${["#ff5a6e", "#ffc93c", "#3fa9f5", "#5fd068"][k % 4]}" stroke="#3a2a2a" stroke-width="2"/>` : ""}`).join("");
  // Arena wall stone blocks and moss.
  let blocks = "";
  for (let k = 0; k < 12; k++) {
    const x0 = 76 + k * (700 / 12);
    blocks += `<line x1="${f(x0)}" y1="1424" x2="${f(x0)}" y2="1460" stroke="#141c28" stroke-width="2.5"/>`;
    if (k % 3 === 1) blocks += `<path d="M ${f(x0 + 8)} 1424 q 10 14 22 2 q 8 12 18 -2 Z" fill="#3a7a4a" stroke="#1e3a2a" stroke-width="1.5"/>`;
  }
  blocks += `<line x1="76" y1="1442" x2="776" y2="1442" stroke="#141c28" stroke-width="2" opacity="0.7"/>
    <path d="M 76 1422 L 776 1422" stroke="#8aa0b4" stroke-width="3" opacity="0.5"/>`;
  // Floor marks: a soft centre ring and two start pads, like the game's arena.
  const floorMarks = `<ellipse cx="426" cy="1300" rx="150" ry="46" fill="none" stroke="#7dffb0" stroke-width="3" opacity="0.35"/>
    ${[[250, 1345], [602, 1345]].map(([x, y]) => `<ellipse cx="${x}" cy="${y}" rx="44" ry="14" fill="#7dffb0" opacity="0.14"/>`).join("")}
    <path d="M 300 1220 l 30 22 l -10 26 M 560 1370 l 22 -14 l 16 18" fill="none" stroke="#1e2834" stroke-width="2.5" opacity="0.8"/>`;
  // Stepping stones from the front up to the arena wall.
  const stones = [[340, 1800, 1], [400, 1720, 0.9], [366, 1640, 0.82], [420, 1570, 0.74], [400, 1505, 0.66]].map(([x, y, s]) =>
    `<ellipse cx="${x}" cy="${y + 9 * s}" rx="${f(62 * s)}" ry="${f(20 * s)}" fill="#14262a"/><ellipse cx="${x}" cy="${y}" rx="${f(58 * s)}" ry="${f(18 * s)}" fill="#4a5a5a" stroke="#14262a" stroke-width="2.5"/>
     <ellipse cx="${f(x - 10 * s)}" cy="${f(y - 4 * s)}" rx="${f(32 * s)}" ry="${f(7 * s)}" fill="#6a7a70"/><ellipse cx="${x}" cy="${y}" rx="${f(24 * s)}" ry="${f(7 * s)}" fill="#7dffb0" opacity="0.55"/>`).join("");
  // The bump: a burst and trails, or the fire-and-water face-off.
  const L = [clash[0] - 128, clash[1] + 10], Rr = [clash[0] + 128, clash[1] + 10];
  const bump = fight ? `
    ${breath(L[0], L[1] + 39, clash[0] + 14, clash[1] + 44, 10, 54)}
    ${breath(Rr[0], Rr[1] + 39, clash[0] - 14, clash[1] + 44, 10, 54, ["#3fa9f5", "#5cc8ff", "#1e5a8a", "#a8e4ff", "#f0fbff"])}
    <g transform="translate(${clash[0] * 0.38} ${(clash[1] + 44) * 0.38 - 70}) scale(0.62)"><path d="M ${clash[0] - 70} ${clash[1] + 40} Q ${clash[0] - 90} ${clash[1] - 20} ${clash[0] - 40} ${clash[1] - 40} Q ${clash[0] - 40} ${clash[1] - 110} ${clash[0] + 10} ${clash[1] - 100} Q ${clash[0] + 50} ${clash[1] - 150} ${clash[0] + 70} ${clash[1] - 70} Q ${clash[0] + 110} ${clash[1] - 40} ${clash[0] + 70} ${clash[1] + 40} Z" fill="#eef4fa" stroke="#9ab0c8" stroke-width="3" opacity="0.92"/>
    <path d="M ${clash[0] - 40} ${clash[1] - 40} Q ${clash[0] - 40} ${clash[1] - 110} ${clash[0] + 10} ${clash[1] - 100} Q ${clash[0] + 50} ${clash[1] - 150} ${clash[0] + 70} ${clash[1] - 70}" fill="none" stroke="#fff" stroke-width="7" stroke-linecap="round"/></g>
    <circle cx="${clash[0]}" cy="${clash[1] + 10}" r="70" fill="#fff6c8" opacity="0.35" filter="url(#bl16)"/>` : `
    <circle cx="${clash[0]}" cy="${clash[1]}" r="90" fill="#fff6c8" opacity="0.4" filter="url(#bl24)"/>
    <path d="${(() => { let d = ""; for (let k = 0; k < 16; k++) { const a = k * Math.PI / 8, r = k % 2 ? 34 : 86 + (k % 4) * 8; d += `${k ? "L" : "M"} ${f(clash[0] + Math.cos(a) * r)} ${f(clash[1] + Math.sin(a) * r * 1.1)} `; } return d + "Z"; })()}" fill="#fff3c0" stroke="#e8a040" stroke-width="3" stroke-linejoin="round" opacity="0.9"/>
    <circle cx="${clash[0]}" cy="${clash[1]}" r="26" fill="#fffbe8"/>
    ${[[-40, -120, 8], [50, -130, 6], [80, 90, 7], [-70, 100, 6], [0, 140, 5]].map(([dx, dy, r]) => `<circle cx="${clash[0] + dx}" cy="${clash[1] + dy}" r="${r}" fill="#fff3c0"/>`).join("")}`;
  const trails = [[-1, "#ffb3a8"], [1, "#a8e4ff"]].map(([d, c]) => `
    <path d="M ${clash[0] + d * 380} ${clash[1] + 170} Q ${clash[0] + d * 300} ${clash[1] + 10} ${clash[0] + d * 200} ${clash[1] - 10}" fill="none" stroke="${c}" stroke-width="10" stroke-linecap="round" opacity="0.45" stroke-dasharray="2 20"/>
    ${[0, 1, 2].map((k) => `<path d="M ${clash[0] + d * (250 + k * 14)} ${clash[1] - 60 + k * 50} l ${d * 70} ${10 - k * 6}" stroke="#fff" stroke-width="5" stroke-linecap="round" opacity="${0.5 - k * 0.1}"/>`).join("")}`).join("");
  // Festival: string lights between the lamps and bunting along the wall.
  const bulbs = (x0, y0, x1, y1, sag, n) => {
    let out = `<path d="M ${x0} ${y0} Q ${(x0 + x1) / 2} ${(y0 + y1) / 2 + sag * 2} ${x1} ${y1}" fill="none" stroke="#1a1a2a" stroke-width="2.5"/>`;
    for (let k = 1; k < n; k++) {
      const t = k / n, x = (1 - t) * (1 - t) * x0 + 2 * t * (1 - t) * (x0 + x1) / 2 + t * t * x1, y = (1 - t) * (1 - t) * y0 + 2 * t * (1 - t) * ((y0 + y1) / 2 + sag * 2) + t * t * y1;
      const c = ["#ffd36b", "#ff7ac8", "#5ce1ff", "#7ee08a"][k % 4];
      out += `<circle cx="${f(x)}" cy="${f(y + 6)}" r="11" fill="${c}" opacity="0.35" filter="url(#bl4)"/><circle cx="${f(x)}" cy="${f(y + 6)}" r="5" fill="${c}" stroke="#1a1a2a" stroke-width="1.5"/>`;
    }
    return out;
  };
  const fest = festival ? `${bulbs(216, 1117, 636, 1117, 18, 12)}
    ${(() => { let o = ""; for (let k = 0; k < 14; k++) { const x = 90 + k * 48; o += `<path d="M ${x} 1426 l 40 0 l -20 26 Z" fill="${["#ff5a6e", "#ffc93c", "#3fa9f5", "#5fd068", "#b07cff"][k % 5]}" stroke="#1a1a2a" stroke-width="1.5"/>`; } return o; })()}` : "";
  return svg(`
  <defs>
    <linearGradient id="dSky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0a0d2a"/><stop offset="0.36" stop-color="#1b3460"/><stop offset="0.56" stop-color="#2a6a74"/><stop offset="1" stop-color="#2a6a74"/></linearGradient>
    <linearGradient id="dGround" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#26604e"/><stop offset="0.5" stop-color="#18403a"/><stop offset="1" stop-color="#0b1a1e"/></linearGradient>
    <radialGradient id="dMoon" cx="0.4" cy="0.36" r="0.72"><stop offset="0" stop-color="#fffdf0"/><stop offset="0.7" stop-color="#f2ead0"/><stop offset="1" stop-color="#d8cca4"/></radialGradient>
    <radialGradient id="dHalo" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#dff4ff" stop-opacity="0.38"/><stop offset="1" stop-color="#dff4ff" stop-opacity="0"/></radialGradient>
    <radialGradient id="dPool" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#bfe8ff" stop-opacity="0.22"/><stop offset="1" stop-color="#bfe8ff" stop-opacity="0"/></radialGradient>
    <linearGradient id="dMilky" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#8f8cff" stop-opacity="0"/><stop offset="0.5" stop-color="#b8b4ff" stop-opacity="0.14"/><stop offset="1" stop-color="#8f8cff" stop-opacity="0"/></linearGradient>
  </defs>
  <rect width="${W}" height="${H}" fill="url(#dSky)"/>
  <path d="M -100 120 Q 300 420 953 640 L 953 820 Q 300 600 -100 300 Z" fill="url(#dMilky)"/>
  ${stars(3, 220, 960)}
  <path d="M 640 120 l -170 70" stroke="#fff" stroke-width="3" stroke-linecap="round" opacity="0.6"/><circle cx="640" cy="120" r="4" fill="#fff"/>
  <circle cx="426" cy="740" r="440" fill="url(#dHalo)"/>
  <circle cx="426" cy="740" r="210" fill="url(#dMoon)"/>
  ${craters}
  ${cloudBand(250, 900, 1.3)}${cloudBand(660, 820, 1.0)}${cloudBand(130, 640, 0.7, "#6a88b8", "#1f3060")}
  <path d="M 0 930 Q 140 870 300 900 Q 440 925 560 880 Q 720 830 853 870 L 853 1100 L 0 1100 Z" fill="#244a62"/>
  ${pine(330, 930, 0.6, "#1c3a50")}${pine(360, 935, 0.45, "#1c3a50")}${pine(520, 905, 0.55, "#1c3a50")}
  <path d="M 0 970 Q 160 905 330 935 Q 470 960 600 915 Q 740 870 853 915 L 853 1100 L 0 1100 Z" fill="#1b3a4a"/>
  ${litTree(70, 975, 1.4, "#132a3a", "#2a4a60")}${litTree(230, 950, 1.0, "#132a3a", "#2a4a60")}${litTree(640, 930, 1.1, "#132a3a", "#2a4a60")}${litTree(800, 935, 1.5, "#132a3a", "#2a4a60")}
  <path d="M 0 1060 Q 120 1020 260 1035 Q 360 1045 426 1040 Q 520 1035 620 1030 Q 760 1022 853 1050 L 853 1100 L 0 1100 Z" fill="#1f4a46"/>
  ${crowd}
  <path d="M 0 1075 Q 220 1050 430 1065 Q 650 1080 853 1060 L 853 1844 L 0 1844 Z" fill="url(#dGround)"/>
  <ellipse cx="426" cy="1300" rx="460" ry="200" fill="url(#dPool)"/>
  ${grass(14, 170, 1075, 1844, ["#2f6a4a", "#3a8a5a", "#245a40", "#4a9a66"], 1.3)}
  ${glowShroom(40, 1150, 30, "#7b77ff", "#b8b4ff")}${glowShroom(92, 1170, 18, "#ff8ad0", "#ffd0ec")}${glowShroom(815, 1160, 26, "#3fa9f5", "#bfe8ff")}${glowShroom(770, 1180, 16, "#7b77ff", "#b8b4ff")}
  ${bellFlower(150, 1150, 44, "#ffd36b")}${bellFlower(700, 1140, 40, "#7dffb0")}${bellFlower(728, 1150, 30, "#ff8ad0")}
  ${squareArena(426, 1290, 700, 260)}
  ${blocks}${floorMarks}${fest}
  ${shadow(clash[0] - 125, 1310, 80, 0.45)}${shadow(clash[0] + 125, 1310, 80, 0.45)}
  ${trails}
  ${critter(L[0], L[1], 108, fight ? FAM.fire : "#e8465a", { acc: fight ? "flame" : "horns", mood: fight ? "wow" : "determined", look: [0.8, -0.1], rim: "#fff2c8", rimSide: 1, sx: 0.94, sy: 1.04 })}
  ${critter(Rr[0], Rr[1], 108, FAM.sea, { acc: "fin", mood: fight ? "wow" : "determined", look: [-0.8, -0.1], rim: "#fff2c8", rimSide: -1, sx: 0.94, sy: 1.04 })}
  ${bump}
  ${stones}
  ${glowShroom(60, 1640, 44, "#5a4ab0", "#9a8cff")}${glowShroom(130, 1660, 26, "#ff8ad0", "#ffd0ec")}${glowShroom(800, 1690, 38, "#3fa9f5", "#bfe8ff")}
  ${bellFlower(250, 1560, 54, "#ff8ad0")}${bellFlower(600, 1600, 50, "#ffd36b")}${bellFlower(626, 1596, 36, "#7dffb0")}
  ${shadow(84, 1336, 46, 0.5)}${critter(84, 1290, 50, FAM.nature, { acc: "leaf", mood: "wow", look: [0.6, -0.6], rim: "#7dffb0", rimSide: 1 })}
  ${shadow(772, 1346, 42, 0.5)}${critter(772, 1304, 46, FAM.sweet, { acc: "ears", mood: "cheer", rim: "#ffd0ec", rimSide: -1 })}
  ${shadow(742, 1222, 26, 0.45)}${critter(742, 1196, 28, FAM.toybox, { acc: "propeller", mood: "wow", look: [-0.5, -0.7], rimSide: -1 })}
  ${fern(-20, 1844, 1.5, 1, "#0d2420")}${fern(873, 1844, 1.4, -1, "#0d2420")}${fern(-10, 1844, 1.0, 1, "#123028")}
  ${motes(9, 60, 0, 1060, W, 1720, ["#d8ff7a", "#7dffb0", "#ffe9a8"])}
  ${title(250, { ink: "#0e1430" })}
  ${footFade("#0b1a1e", 0.8)}`);
}

// --- B: Sunny road --------------------------------------------------------
// Bright morning: a winding stone path climbs green hills to the arena on
// the hilltop, its flags flying; a line of critters bounces up the path.
function sunny() {
  const R = rng(21);
  // Path stones from the front up to the arena gate.
  const pathPts = [];
  for (let k = 0; k < 15; k++) {
    const t = k / 14;
    pathPts.push([426 + Math.sin(t * 5.2 + 0.4) * 200 * (1 - t * 0.7), 1720 - t * 790, 1 - t * 0.72]);
  }
  const stones = pathPts.map(([x, y, s]) => `<ellipse cx="${f(x)}" cy="${f(y + 10 * s)}" rx="${f(64 * s)}" ry="${f(22 * s)}" fill="#7a6a58"/>
    <ellipse cx="${f(x)}" cy="${f(y)}" rx="${f(60 * s)}" ry="${f(20 * s)}" fill="#e8dcc0" stroke="#7a6a58" stroke-width="2.5"/>
    <ellipse cx="${f(x - 10 * s)}" cy="${f(y - 5 * s)}" rx="${f(32 * s)}" ry="${f(8 * s)}" fill="#fff8e6" opacity="0.8"/>`).reverse().join("");
  const clouds = [[150, 560, 1.2], [690, 470, 1.5], [520, 760, 0.8], [90, 860, 0.7]].map(([x, y, s]) => `
    <g opacity="0.95"><ellipse cx="${x}" cy="${y + 20 * s}" rx="${120 * s}" ry="${34 * s}" fill="#bfe2ff"/>
    <circle cx="${x - 50 * s}" cy="${y}" r="${44 * s}" fill="#fff"/><circle cx="${x + 10 * s}" cy="${y - 22 * s}" r="${60 * s}" fill="#fff"/><circle cx="${x + 70 * s}" cy="${y + 4 * s}" r="${40 * s}" fill="#fff"/>
    <ellipse cx="${x}" cy="${y + 22 * s}" rx="${118 * s}" ry="${22 * s}" fill="#e2f1ff"/></g>`).join("");
  const ax = 430, ay = 880; // arena on the hilltop
  const flags = [-200, -70, 70, 200].map((dx, k) => `<line x1="${ax + dx}" y1="${ay - 90}" x2="${ax + dx}" y2="${ay - 210}" stroke="#5a3a2a" stroke-width="6"/>
    <path d="M ${ax + dx} ${ay - 210} q 40 8 70 -4 q -18 20 0 38 q -34 10 -70 0 Z" fill="${["#ff5a6e", "#ffc93c", "#3fa9f5", "#5fd068"][k]}" stroke="#5a3a2a" stroke-width="3"/>`).join("");
  const bowl = `
    <ellipse cx="${ax}" cy="${ay}" rx="290" ry="70" fill="#000" opacity="0.18" filter="url(#bl8)"/>
    <path d="M ${ax - 270} ${ay - 10} L ${ax - 250} ${ay - 110} Q ${ax} ${ay - 150} ${ax + 250} ${ay - 110} L ${ax + 270} ${ay - 10} Q ${ax} ${ay + 40} ${ax - 270} ${ay - 10} Z" fill="#e9d6b0" stroke="#6a4e3a" stroke-width="5" stroke-linejoin="round"/>
    ${[-200, -120, -40, 40, 120, 200].map((dx) => `<path d="M ${ax + dx - 26} ${ay - 2 + Math.abs(dx) * 0.03} L ${ax + dx - 26} ${ay - 72} Q ${ax + dx} ${ay - 100} ${ax + dx + 26} ${ay - 72} L ${ax + dx + 26} ${ay + 2 - Math.abs(dx) * 0.0}" fill="#8a6a4e" stroke="#6a4e3a" stroke-width="3"/>`).join("")}
    <path d="M ${ax - 250} ${ay - 110} Q ${ax} ${ay - 150} ${ax + 250} ${ay - 110}" fill="none" stroke="#fff4d8" stroke-width="10" stroke-linecap="round"/>
    <path d="M ${ax - 60} ${ay + 10} L ${ax - 60} ${ay - 60} Q ${ax} ${ay - 104} ${ax + 60} ${ay - 60} L ${ax + 60} ${ay + 12} Z" fill="#3a2a40" stroke="#6a4e3a" stroke-width="5"/>
    <path d="M ${ax - 40} ${ay + 10} L ${ax - 40} ${ay - 52} Q ${ax} ${ay - 82} ${ax + 40} ${ay - 52} L ${ax + 40} ${ay + 10} Z" fill="#ffd36b" opacity="0.5"/>
    ${flags}`;
  const walkers = [
    [pathPts[2][0], pathPts[2][1] - 92, 92, "#7b77ff", "antenna", "cheer", 1],
    [pathPts[5][0], pathPts[5][1] - 66, 64, FAM.fire, "flame", "happy", 0.8],
    [pathPts[8][0], pathPts[8][1] - 46, 44, FAM.frost, "crystal", "happy", 0.6],
    [pathPts[11][0], pathPts[11][1] - 32, 30, FAM.sweet, "ears", "cheer", 0.45],
  ].map(([x, y, r, col, acc, mood, s]) => `${shadow(x, y + r + 40 * s, r * 0.8, 0.35)}${critter(x, y, r, col, { acc, mood, look: [0.2, -0.5], rim: "#fff6d0", rimSide: -1, glow: false, sy: 1.04 })}
    <path d="M ${f(x - r * 0.9)} ${f(y + r * 1.25)} q ${f(r * 0.3)} ${f(r * 0.25)} ${f(r * 0.6)} 0 M ${f(x + r * 0.3)} ${f(y + r * 1.3)} q ${f(r * 0.3)} ${f(r * 0.25)} ${f(r * 0.6)} 0" stroke="#fff" stroke-width="${f(4 * s + 1)}" fill="none" stroke-linecap="round" opacity="0.8"/>`).reverse().join("");
  return svg(`
  <defs>
    <linearGradient id="sSky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3a8fff"/><stop offset="0.35" stop-color="#7cc8ff"/><stop offset="0.55" stop-color="#d6f1ff"/></linearGradient>
    <linearGradient id="sHill1" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9ad86a"/><stop offset="1" stop-color="#5aae4e"/></linearGradient>
    <linearGradient id="sHill2" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6cc458"/><stop offset="1" stop-color="#2f8a46"/></linearGradient>
    <radialGradient id="sSun" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#fffbe0" stop-opacity="0.95"/><stop offset="0.3" stop-color="#fff3b0" stop-opacity="0.6"/><stop offset="1" stop-color="#fff3b0" stop-opacity="0"/></radialGradient>
  </defs>
  <rect width="${W}" height="${H}" fill="url(#sSky)"/>
  <circle cx="660" cy="660" r="300" fill="url(#sSun)"/>
  ${clouds}
  <path d="M 0 900 Q 140 840 300 880 Q 420 900 520 860 Q 680 800 853 860 L 853 1000 L 0 1000 Z" fill="#8ac8e0" opacity="0.7"/>
  <path d="M 0 1000 Q 100 900 260 900 Q 360 870 430 870 Q 520 870 620 900 Q 760 920 853 980 L 853 1300 L 0 1300 Z" fill="url(#sHill1)"/>
  ${pine(70, 990, 0.9, "#2f7a46")}${pine(130, 1010, 0.7, "#2a6a40")}${pine(780, 1010, 1.0, "#2f7a46")}${pine(720, 1030, 0.7, "#2a6a40")}
  ${bowl}
  <path d="M 0 1150 Q 200 1090 430 1130 Q 650 1170 853 1110 L 853 1844 L 0 1844 Z" fill="url(#sHill2)"/>
  ${grass(31, 110, 1150, 1844, ["#2f8a46", "#4aa858", "#7cd06a"], 1.3)}
  ${[[90, 1300], [760, 1420], [140, 1620], [700, 1700], [300, 1250], [600, 1260]].map(([x, y], k) => `<circle cx="${x}" cy="${y}" r="9" fill="${["#fff", "#ffd36b", "#ff8ad0"][k % 3]}" stroke="#2f6a3a" stroke-width="2"/><circle cx="${x}" cy="${y}" r="3.5" fill="#ffb347"/>`).join("")}
  ${stones}
  ${walkers}
  ${title(250, { ink: "#1d2a5a", shadowOp: 0.3 })}
  ${footFade("#1a4a2a", 0.75)}`);
}

// --- C: Campfire ------------------------------------------------------------
// Dusk in a forest clearing: a fire critter breathes a little flame to light
// the campfire while the team gathers round, one toasting a marshmallow.
function campfire() {
  const fx = 426, fy = 1290; // the fire
  const flame = (s, o) => `<path d="M ${fx - 70 * s} ${fy} Q ${fx - 90 * s} ${fy - 80 * s} ${fx - 30 * s} ${fy - 150 * s} Q ${fx - 30 * s} ${fy - 90 * s} ${fx} ${fy - 90 * s} Q ${fx - 10 * s} ${fy - 170 * s} ${fx + 30 * s} ${fy - 220 * s} Q ${fx + 40 * s} ${fy - 130 * s} ${fx + 60 * s} ${fy - 120 * s} Q ${fx + 90 * s} ${fy - 60 * s} ${fx + 70 * s} ${fy} Z" opacity="${o}"`;
  const logs = `<rect x="${fx - 110}" y="${fy - 18}" width="220" height="34" rx="17" fill="#6a3e2a" stroke="#2a160e" stroke-width="4" transform="rotate(14 ${fx} ${fy})"/>
    <rect x="${fx - 110}" y="${fy - 18}" width="220" height="34" rx="17" fill="#7a4a30" stroke="#2a160e" stroke-width="4" transform="rotate(-14 ${fx} ${fy})"/>
    ${[-1, 1].map((d) => `<circle cx="${fx + d * 104}" cy="${fy + d * -2}" r="13" fill="#c89a6a" stroke="#2a160e" stroke-width="3"/>`).join("")}`;
  const ring = Array.from({ length: 11 }, (_, k) => { const a = Math.PI * (0.05 + k * 0.09); return [fx + Math.cos(a) * 150, fy + 22 + Math.sin(a) * 40]; })
    .map(([x, y]) => `<ellipse cx="${f(x)}" cy="${f(y)}" rx="26" ry="16" fill="#6a6070" stroke="#2a2030" stroke-width="3"/>`).join("");
  const dk = [fx - 250, 1170]; // the fire critter, breathing into the logs
  return svg(`
  <defs>
    <linearGradient id="cSky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#1a1240"/><stop offset="0.32" stop-color="#4a2a6a"/><stop offset="0.48" stop-color="#c2644a"/><stop offset="0.56" stop-color="#ffb070"/></linearGradient>
    <radialGradient id="cLight" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#ffb347" stop-opacity="0.55"/><stop offset="0.5" stop-color="#ff7a3a" stop-opacity="0.18"/><stop offset="1" stop-color="#ff7a3a" stop-opacity="0"/></radialGradient>
    <linearGradient id="cGround" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2a2a3e"/><stop offset="1" stop-color="#120c1e"/></linearGradient>
  </defs>
  <rect width="${W}" height="${H}" fill="url(#cSky)"/>
  ${stars(8, 110, 760)}
  <circle cx="640" cy="560" r="44" fill="#fff1d0" opacity="0.9"/><circle cx="660" cy="548" r="40" fill="#5a3470"/>
  <path d="M 0 1000 L 0 880 Q 120 820 220 860 Q 330 760 440 840 Q 560 780 660 830 Q 760 790 853 840 L 853 1000 Z" fill="#3a2250"/>
  ${[40, 120, 200, 640, 720, 810].map((x, k) => pine(x, 1010 + (k % 2) * 16, 1.6 + (k % 3) * 0.3, "#1c1232")).join("")}
  <path d="M 0 1030 Q 220 1000 430 1020 Q 640 1040 853 1010 L 853 1844 L 0 1844 Z" fill="url(#cGround)"/>
  <ellipse cx="${fx}" cy="${fy - 40}" rx="560" ry="420" fill="url(#cLight)"/>
  ${grass(44, 80, 1040, 1844, ["#3a3050", "#4a3a5a", "#2a2040"], 1.2)}
  ${ring}${logs}
  ${breath(dk[0] + 52, dk[1] + 34, fx - 30, fy - 50, 10, 46)}
  <path ${flame(1.15, 0.4)} fill="#ff6a3d" filter="url(#bl16)"/>
  <path ${flame(1, 1)} fill="#ff7a2a" stroke="#a8321a" stroke-width="4" stroke-linejoin="round"/>
  <path ${flame(0.62, 1)} fill="#ffc23d"/><path ${flame(0.32, 1)} fill="#fff0a0"/>
  ${shadow(dk[0], dk[1] + 100, 70, 0.6)}
  ${critter(dk[0], dk[1], 92, FAM.fire, { acc: "flame", mood: "wow", look: [0.8, 0.3], rim: "#ffc070", rimSide: 1 })}
  ${shadow(fx + 240, 1300, 64, 0.6)}${critter(fx + 240, 1215, 80, FAM.sweet, { acc: "ears", mood: "happy", look: [-0.8, 0.1], rim: "#ffc070", rimSide: -1 })}
  <path d="M ${fx + 175} ${1240} L ${fx + 60} ${1150}" stroke="#8a5a3a" stroke-width="6" stroke-linecap="round"/>
  <rect x="${fx + 34}" y="${1128}" width="34" height="30" rx="10" fill="#fff4e8" stroke="#8a6a5a" stroke-width="3" transform="rotate(-38 ${fx + 51} ${1143})"/>
  <rect x="${fx + 34}" y="${1146}" width="34" height="12" rx="6" fill="#d89a5a" transform="rotate(-38 ${fx + 51} ${1143})"/>
  ${shadow(fx - 120, 1500, 70, 0.6)}${critter(fx - 120, 1420, 82, FAM.nature, { acc: "leaf", mood: "cheer", rim: "#ffc070", rimSide: 1 })}
  ${shadow(fx + 150, 1520, 66, 0.6)}${critter(fx + 150, 1445, 76, "#7b77ff", { acc: "antenna", mood: "happy", look: [-0.3, -0.6], rim: "#ffc070", rimSide: -1 })}
  ${shadow(fx + 330, 1440, 40, 0.5)}${critter(fx + 330, 1395, 46, FAM.frost, { acc: "crystal", mood: "sleepy", rim: "#ffc070", rimSide: -1 })}
  ${motes(17, 34, fx - 200, 800, fx + 200, 1200, ["#ffd36b", "#ff9f43", "#fff0a0"])}
  ${title(250, { ink: "#1a1030" })}
  ${footFade("#120c1e", 0.85)}`);
}

export const SCENES = { moonlit, detail: () => moonDetail("detail"), festival: () => moonDetail("festival"), clash: () => moonDetail("clash"), sunny, campfire };

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  // `ship <name>` writes the loading picture itself: game/brand/loading.png
  // (native boot splash, iOS storyboard, the game's live copy) and
  // site/loading.webp, the small copy the web page shows while the game
  // downloads. Otherwise renders previews to [outdir].
  const ship = process.argv[2] === "ship";
  const out = ship ? null : path.resolve(process.argv[2] || path.join(repo, "build/loading_painted"));
  const only = process.argv.slice(3);
  if (out) fs.mkdirSync(out, { recursive: true });
  const require = createRequire(path.join(repo, "smoke/package.json"));
  const { chromium } = require("playwright");
  const browser = await chromium.launch(process.env.CHROMIUM_PATH ? { executablePath: process.env.CHROMIUM_PATH } : {});
  const page = await browser.newPage({ viewport: { width: W, height: H } });
  for (const [name, fn] of Object.entries(SCENES).filter(([n]) => !only.length || only.includes(n))) {
    await page.setContent(`<html><body style="margin:0">${fn()}</body></html>`);
    await page.evaluate(() => document.fonts.ready);
    await page.waitForTimeout(200);
    const png = ship ? path.join(repo, "game/brand/loading.png") : path.join(out, `loading_${name}.png`);
    await page.screenshot({ path: png, clip: { x: 0, y: 0, width: W, height: H } });
    console.log(png);
    if (ship) {
      const b64 = await page.evaluate(async (src) => {
        const img = new Image();
        img.src = src;
        await img.decode();
        const c = document.createElement("canvas");
        c.width = img.width; c.height = img.height;
        c.getContext("2d").drawImage(img, 0, 0);
        return c.toDataURL("image/webp", 0.82).split(",")[1];
      }, "data:image/png;base64," + fs.readFileSync(png).toString("base64"));
      const webp = path.join(repo, "site/loading.webp");
      fs.writeFileSync(webp, Buffer.from(b64, "base64"));
      console.log(webp, fs.statSync(webp).size, "bytes");
      break;
    }
  }
  await browser.close();
}

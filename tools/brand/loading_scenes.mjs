// Code-drawn loading screens in the Bounce Run event-art style (dark,
// moody scenes lit by glowing accents, glossy gradient critters with rim
// light) that keep the layout of the painted loading picture: title at
// the top, Count Nibbles centre stage on a ring, the cast round him.
// Usage (from the repo root, after `cd smoke && npm ci`):
//   node tools/brand/loading_scenes.mjs [outdir]   -> <outdir>/loading_<name>.png
import { createRequire } from "node:module";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { shade } from "./parts.mjs";

const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, "../..");
const W = 853;
const H = 1844;
const font = "data:font/ttf;base64," + fs.readFileSync(path.join(repo, "game/fonts/ChakraPetch-Bold.ttf")).toString("base64");

let uid = 0;
const id = (p) => `${p}${uid++}`;
const rnd = (() => {
  let s = 7;
  return () => ((s = (s * 16807) % 2147483647) / 2147483647);
})();

// --- Shared defs ---------------------------------------------------------

const defs = `
<defs>
  <style>@font-face { font-family: Chakra; src: url(${font}); }</style>
  <filter id="blur4" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="4"/></filter>
  <filter id="blur10" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="10"/></filter>
  <filter id="blur24" x="-80%" y="-80%" width="260%" height="260%"><feGaussianBlur stdDeviation="24"/></filter>
  <filter id="blur60" x="-100%" y="-100%" width="300%" height="300%"><feGaussianBlur stdDeviation="60"/></filter>
  <filter id="glow" x="-50%" y="-50%" width="200%" height="200%">
    <feGaussianBlur stdDeviation="6" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge>
  </filter>
</defs>`;

// A glossy critter body: radial gradient lit from the top left, a rim light
// on the shadow side, a specular highlight and a soft coloured glow.
function body(cx, cy, r, col, { glow = 0.5, rim = "#ff9ad8" } = {}) {
  const g = id("g");
  return `
  <defs><radialGradient id="${g}" cx="0.36" cy="0.3" r="0.78">
    <stop offset="0" stop-color="${shade(col, 0.5)}"/><stop offset="0.5" stop-color="${col}"/><stop offset="1" stop-color="${shade(col, -0.45)}"/>
  </radialGradient></defs>
  <circle cx="${cx}" cy="${cy}" r="${r * 1.15}" fill="${col}" opacity="${glow}" filter="url(#blur24)"/>
  <circle cx="${cx}" cy="${cy}" r="${r}" fill="url(#${g})" stroke="${shade(col, -0.6)}" stroke-width="${r * 0.05}"/>
  <path d="M ${cx + r * 0.62} ${cy + r * 0.62} A ${r * 0.93} ${r * 0.93} 0 0 1 ${cx - r * 0.55} ${cy + r * 0.76}" fill="none" stroke="${rim}" stroke-opacity="0.7" stroke-width="${r * 0.07}" stroke-linecap="round"/>
  <ellipse cx="${cx - r * 0.34}" cy="${cy - r * 0.42}" rx="${r * 0.3}" ry="${r * 0.17}" transform="rotate(-30 ${cx - r * 0.34} ${cy - r * 0.42})" fill="#fff" opacity="0.75"/>
  <circle cx="${cx - r * 0.08}" cy="${cy - r * 0.58}" r="${r * 0.06}" fill="#fff" opacity="0.8"/>`;
}

// Big cartoon eyes looking toward (lx, ly); mood: "happy", "angry", "smug", "calm".
function face(cx, cy, r, { lx = 0, ly = 0.1, mood = "happy", one = false } = {}) {
  const ink = "#1b1030";
  const eye = (x, y, er) => `
    <ellipse cx="${x}" cy="${y}" rx="${er}" ry="${er * 1.12}" fill="#fff"/>
    <circle cx="${x + lx * er * 0.35}" cy="${y + ly * er * 0.35}" r="${er * 0.62}" fill="${ink}"/>
    <circle cx="${x + lx * er * 0.35 - er * 0.22}" cy="${y + ly * er * 0.35 - er * 0.25}" r="${er * 0.2}" fill="#fff"/>
    <circle cx="${x + lx * er * 0.35 + er * 0.15}" cy="${y + ly * er * 0.35 + er * 0.2}" r="${er * 0.08}" fill="#fff"/>`;
  let s = "";
  if (one) s += eye(cx, cy - r * 0.08, r * 0.36);
  else if (mood === "calm") {
    for (const sx of [-1, 1]) s += `<path d="M ${cx + sx * r * 0.42} ${cy - r * 0.05} q ${-sx * r * 0.14} ${r * 0.14} ${-sx * r * 0.28} 0" fill="none" stroke="${ink}" stroke-width="${r * 0.07}" stroke-linecap="round"/>`;
  } else {
    s += eye(cx - r * 0.3, cy - r * 0.1, r * 0.22) + eye(cx + r * 0.3, cy - r * 0.1, r * 0.22);
  }
  if (mood === "angry" || mood === "smug") {
    const t = mood === "angry" ? 0.16 : 0.06;
    for (const sx of [-1, 1]) s += `<path d="M ${cx + sx * r * 0.55} ${cy - r * (0.42 + t)} L ${cx + sx * r * 0.12} ${cy - r * 0.34}" stroke="${ink}" stroke-width="${r * 0.09}" stroke-linecap="round"/>`;
  }
  if (mood === "smug") {
    // Heavy lids over the top of the eyes.
    for (const sx of [-1, 1]) s += `<path d="M ${cx + sx * r * 0.3 - r * 0.24} ${cy - r * 0.14} a ${r * 0.24} ${r * 0.2} 0 0 1 ${r * 0.48} 0 z" fill="${shade("#c2264a", -0.15)}"/>`;
  }
  const my = cy + r * 0.32;
  if (mood === "angry" || mood === "smug") {
    s += `<path d="M ${cx - r * 0.18} ${my} q ${r * 0.18} ${r * 0.1} ${r * 0.36} -${r * 0.04}" fill="none" stroke="${ink}" stroke-width="${r * 0.06}" stroke-linecap="round"/>
      <path d="M ${cx - r * 0.1} ${my + r * 0.02} l ${r * 0.04} ${r * 0.1} l ${r * 0.04} -${r * 0.09} M ${cx + r * 0.04} ${my + r * 0.01} l ${r * 0.04} ${r * 0.1} l ${r * 0.04} -${r * 0.1}" fill="#fff"/>`;
  } else {
    s += `<path d="M ${cx - r * 0.16} ${my} q ${r * 0.16} ${r * 0.16} ${r * 0.32} 0" fill="#7a1e3a" stroke="${ink}" stroke-width="${r * 0.05}" stroke-linecap="round"/>`;
    s += `<ellipse cx="${cx - r * 0.52}" cy="${my - r * 0.06}" rx="${r * 0.12}" ry="${r * 0.07}" fill="#ff7aa8" opacity="0.5"/><ellipse cx="${cx + r * 0.52}" cy="${my - r * 0.06}" rx="${r * 0.12}" ry="${r * 0.07}" fill="#ff7aa8" opacity="0.5"/>`;
  }
  return s;
}

const spikes = (cx, cy, r1, r2, n, col, rot = 0, from = 0, to = Math.PI * 2) => {
  let d = "";
  for (let i = 0; i < n; i++) {
    const a0 = from + ((to - from) * i) / n + rot;
    const a1 = from + ((to - from) * (i + 0.5)) / n + rot;
    const a2 = from + ((to - from) * (i + 1)) / n + rot;
    d += `M ${cx + Math.cos(a0) * r1} ${cy + Math.sin(a0) * r1} L ${cx + Math.cos(a1) * r2} ${cy + Math.sin(a1) * r2} L ${cx + Math.cos(a2) * r1} ${cy + Math.sin(a2) * r1} Z `;
  }
  return `<path d="${d}" fill="${col}"/>`;
};

const coin = (x, y, r) => `
  <circle cx="${x}" cy="${y}" r="${r * 1.6}" fill="#ffd45c" opacity="0.35" filter="url(#blur10)"/>
  <circle cx="${x + r * 0.1}" cy="${y + r * 0.1}" r="${r}" fill="#a86d10"/>
  <circle cx="${x}" cy="${y}" r="${r}" fill="#ffd45c" stroke="#c88a1c" stroke-width="${r * 0.12}"/>
  <path d="${starPath(x, y, r * 0.45, r * 0.2)}" fill="#fff3b8"/>`;

function starPath(x, y, r1, r2, n = 5) {
  let d = "";
  for (let i = 0; i < n * 2; i++) {
    const a = -Math.PI / 2 + (i * Math.PI) / n;
    const r = i % 2 ? r2 : r1;
    d += `${i ? "L" : "M"} ${x + Math.cos(a) * r} ${y + Math.sin(a) * r} `;
  }
  return d + "Z";
}

const sparkle = (x, y, s, col = "#fff", o = 0.9) =>
  `<path d="M ${x} ${y - s} Q ${x} ${y} ${x + s} ${y} Q ${x} ${y} ${x} ${y + s} Q ${x} ${y} ${x - s} ${y} Q ${x} ${y} ${x} ${y - s} Z" fill="${col}" opacity="${o}"/>`;

// --- The cast (positions follow the painted picture) --------------------

function cast(rim) {
  let s = "";
  // Ghost with afterimages, top left.
  for (let i = 3; i >= 1; i--) s += `<circle cx="${150 - i * 34}" cy="${545 + i * 12}" r="${46 - i * 3}" fill="#e3d6ff" opacity="${0.12 * (4 - i)}"/>`;
  s += body(150, 545, 48, "#d9ccff", { rim }) + face(150, 545, 48, { lx: 0.5, ly: -0.2 });
  // Comet streaking, top right.
  for (let i = 0; i < 5; i++) s += `<line x1="${700 + 40}" y1="${545 + (i - 2) * 14}" x2="${700 + 150 - Math.abs(i - 2) * 20}" y2="${545 + (i - 2) * 14 + 30}" stroke="#ff9ae8" stroke-width="5" stroke-linecap="round" opacity="${0.75 - Math.abs(i - 2) * 0.2}"/>`;
  s += body(700, 545, 44, "#ff5ad1", { rim: "#ffd1f3" }) + face(700, 545, 44, { lx: -0.6, mood: "happy" });
  // Phoenix crowned in flame under the title.
  s += spikes(432, 565, 58, 92, 11, "#ff6a2a", 0, Math.PI * 1.05, Math.PI * 1.95) + spikes(432, 565, 56, 78, 11, "#ffd23f", 0.12, Math.PI * 1.05, Math.PI * 1.95);
  s += body(432, 565, 62, "#ff7a2a", { rim: "#ffe066", glow: 0.7 }) + face(432, 565, 62, { mood: "angry", ly: 0.3 });
  // Drako breathing fireballs, left.
  s += `<path d="M 95 700 l -18 -44 l 34 26 z M 165 700 l 18 -44 l -34 26 z" fill="#ffd23f"/>`;
  for (const [x, y, r] of [[205, 768, 16], [240, 780, 20], [276, 792, 24], [318, 806, 30]]) s += `<circle cx="${x}" cy="${y}" r="${r * 1.6}" fill="#ff7a1f" opacity="0.35" filter="url(#blur10)"/><circle cx="${x}" cy="${y}" r="${r}" fill="#ff7a1f"/><circle cx="${x}" cy="${y}" r="${r * 0.55}" fill="#ffe066"/>`;
  s += body(130, 750, 66, "#2fae4f", { rim }) + face(130, 750, 66, { mood: "angry", lx: 0.5 });
  s += `<ellipse cx="130" cy="788" rx="40" ry="22" fill="#a8e6b4" opacity="0.8"/>`;
  // Laser firing its beam, right.
  s += `<line x1="715" y1="715" x2="505" y2="818" stroke="#27c8ff" stroke-width="26" opacity="0.35" filter="url(#blur10)"/><line x1="660" y1="742" x2="505" y2="818" stroke="#7fe6ff" stroke-width="10"/><line x1="660" y1="742" x2="505" y2="818" stroke="#fff" stroke-width="3"/>`;
  s += sparkle(505, 818, 34, "#e6fbff") + `<line x1="690" y1="660" x2="676" y2="632" stroke="#1d6f99" stroke-width="5"/><line x1="740" y1="660" x2="754" y2="632" stroke="#1d6f99" stroke-width="5"/><circle cx="676" cy="630" r="7" fill="#9ff0ff"/><circle cx="754" cy="630" r="7" fill="#9ff0ff"/>`;
  s += body(715, 715, 62, "#27b8f0", { rim: "#c9f4ff" }) + face(715, 715, 62, { one: true, lx: -0.6, ly: 0.3 });
  // Sprout with leaves swirling, left.
  for (let i = 0; i < 6; i++) {
    const a = (i / 6) * Math.PI * 2;
    const x = 135 + Math.cos(a) * 92, y = 925 + Math.sin(a) * 52;
    s += `<ellipse cx="${x}" cy="${y}" rx="14" ry="7" transform="rotate(${(a * 180) / Math.PI + 90} ${x} ${y})" fill="${i % 2 ? "#8ac926" : "#b8f06a"}"/>`;
  }
  s += `<path d="M 135 870 q -30 -30 -46 -6 q 26 14 46 6 M 135 870 q 30 -30 46 -6 q -26 14 -46 6" fill="#6fd04a"/>`;
  s += body(135, 925, 58, "#8ac926", { rim }) + face(135, 925, 58, { mood: "happy" });
  // Kraken waving tentacles, right.
  for (let i = 0; i < 5; i++) {
    const a = Math.PI * (0.15 + i * 0.175);
    const x0 = 715 + Math.cos(a) * 40, y0 = 950 + Math.sin(a) * 40;
    const x1 = 715 + Math.cos(a) * 120, y1 = 950 + Math.sin(a) * 105;
    s += `<path d="M ${x0} ${y0} Q ${(x0 + x1) / 2 + 26 * (i % 2 ? 1 : -1)} ${(y0 + y1) / 2} ${x1} ${y1} q ${10 * (i - 2)} 12 ${-6} 18" fill="none" stroke="#6b2a99" stroke-width="20" stroke-linecap="round"/>`;
    s += `<path d="M ${x0} ${y0} Q ${(x0 + x1) / 2 + 26 * (i % 2 ? 1 : -1)} ${(y0 + y1) / 2} ${x1} ${y1} q ${10 * (i - 2)} 12 ${-6} 18" fill="none" stroke="#a65ad9" stroke-width="13" stroke-linecap="round"/>`;
  }
  s += body(715, 950, 70, "#8e3bbd", { rim: "#e0b3ff" }) + face(715, 950, 70, { lx: -0.3 });
  s += `<path d="M 709 978 l 6 10 l 6 -10 z" fill="#ffb020"/>`;
  return s;
}

function ground(rim) {
  let s = "";
  // Sundae flinging scoops, front left.
  for (const [x, y, c] of [[226, 1176, "#7a4a2a"], [96, 1132, "#ffb3d1"], [186, 1100, "#fff1d6"]]) s += `<circle cx="${x}" cy="${y}" r="20" fill="${c}"/><circle cx="${x}" cy="${y - 20}" r="6" fill="#ff2d55"/>`;
  s += `<ellipse cx="150" cy="1372" rx="62" ry="12" fill="#000" opacity="0.35"/>`;
  s += body(150, 1300, 72, "#fbe3d8", { rim });
  s += `<path d="M 80 1300 A 72 72 0 0 0 220 1300 Z" fill="#e0a45c"/><path d="M 84 1310 L 216 1310 M 96 1336 L 204 1336 M 118 1360 L 182 1360 M 110 1300 L 150 1371 M 150 1300 L 190 1365 M 190 1300 L 210 1330 M 110 1300 L 90 1330" stroke="#a96a2a" stroke-width="4" opacity="0.8"/>`;
  s += face(150, 1270, 60, { mood: "calm" });
  // Yeti breathing frost, front right.
  for (let i = 0; i < 6; i++) s += `<circle cx="${620 - i * 30}" cy="${1300 - i * 8}" r="${12 + i * 6}" fill="#cfefff" opacity="${0.22 - i * 0.035}"/>`;
  s += `<path d="M 650 1238 l -12 -46 l 30 34 z M 730 1238 l 12 -46 l -30 34 z" fill="#f3f6ff"/>`;
  s += `<ellipse cx="690" cy="1374" rx="66" ry="12" fill="#000" opacity="0.35"/>`;
  s += body(690, 1300, 76, "#cfd6e4", { rim: "#d6f2ff" });
  for (let i = 0; i < 9; i++) s += `<path d="M ${640 + i * 12} 1240 l 6 30 l 6 -30" fill="none" stroke="#9aa3b8" stroke-width="3"/>`;
  s += face(690, 1300, 76, { lx: -0.4 });
  for (const [x, y] of [[620, 1220], [760, 1250], [600, 1380], [775, 1360]]) s += sparkle(x, y, 10, "#e6f8ff");
  // Yoyo looping, front.
  s += `<path d="M 480 1460 m -70 0 a 70 40 0 1 0 140 0 a 70 40 0 1 0 -140 0" fill="none" stroke="#7ff0ff" stroke-width="8" opacity="0.35" stroke-dasharray="40 18"/>`;
  s += `<line x1="480" y1="1460" x2="472" y2="1408" stroke="#ffe066" stroke-width="3"/>`;
  s += body(480, 1460, 44, "#00b4d8", { rim: "#c9f8ff" }) + face(480, 1460, 44, { mood: "calm" });
  return s;
}

function nibbles(rim) {
  let s = "";
  // Bat-wing collar behind him, then the shield bubble.
  s += spikes(428, 1090, 120, 205, 10, "#7a1028", -0.15, Math.PI * 0.95, Math.PI * 2.05);
  s += spikes(428, 1090, 115, 180, 10, "#a8173a", -0.15, Math.PI * 0.95, Math.PI * 2.05);
  s += body(428, 1090, 135, "#d42a4a", { rim: "#ff9ab0", glow: 0.6 });
  s += face(428, 1090, 135, { mood: "smug", ly: 0.2 });
  s += `<circle cx="428" cy="1090" r="160" fill="#ff3d6e" opacity="0.08"/><circle cx="428" cy="1090" r="160" fill="none" stroke="#ff7a96" stroke-width="4" opacity="0.6"/>
    <path d="M 316 1010 A 160 160 0 0 1 400 934" fill="none" stroke="#fff" stroke-width="5" opacity="0.5" stroke-linecap="round"/>`;
  return s;
}

function title(y0, { fill2 = "#ffcf3d" } = {}) {
  const g1 = id("t"), g2 = id("t");
  const word = (text, y, size, grad) => `
    <text x="${W / 2}" y="${y + size * 0.06}" font-family="Chakra" font-size="${size}" text-anchor="middle" fill="#120826" stroke="#120826" stroke-width="${size * 0.16}" stroke-linejoin="round">${text}</text>
    <text x="${W / 2}" y="${y}" font-family="Chakra" font-size="${size}" text-anchor="middle" fill="url(#${grad})" stroke="#2a1150" stroke-width="${size * 0.14}" stroke-linejoin="round" paint-order="stroke"/>
    <text x="${W / 2}" y="${y}" font-family="Chakra" font-size="${size}" text-anchor="middle" fill="url(#${grad})">${text}</text>`;
  return `<defs>
    <linearGradient id="${g1}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffffff"/><stop offset="0.55" stop-color="#eef0ff"/><stop offset="1" stop-color="#b9b3ff"/></linearGradient>
    <linearGradient id="${g2}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff6a8"/><stop offset="0.5" stop-color="${fill2}"/><stop offset="1" stop-color="#ff9a1f"/></linearGradient>
  </defs>
  <ellipse cx="${W / 2}" cy="${y0 + 90}" rx="360" ry="170" fill="#000" opacity="0.25" filter="url(#blur24)"/>
  ${word("BATTLE", y0, 150, g1)}
  ${word("BALLS", y0 + 170, 196, g2)}`;
}

function grid(hz, col, { opacity = 0.7 } = {}) {
  let s = "";
  const vx = W / 2, vy = hz - 70;
  for (let i = -16; i <= 16; i++) {
    const bx = vx + i * 120;
    const t = (hz - vy) / (H - vy);
    const ax = vx + (bx - vx) * t;
    s += `<line x1="${ax}" y1="${hz}" x2="${vx + (bx - vx) * 1.6}" y2="${H + 400}" stroke="${col}" stroke-width="3" opacity="${opacity}"/>`;
  }
  let y = hz, step = 14;
  while (y < H) {
    s += `<line x1="0" y1="${y}" x2="${W}" y2="${y}" stroke="${col}" stroke-width="${2 + step * 0.02}" opacity="${opacity}"/>`;
    y += step;
    step *= 1.32;
  }
  return `<g filter="url(#glow)">${s}</g>`;
}

function ring(cx, cy, rx, ry, col) {
  return `<ellipse cx="${cx}" cy="${cy}" rx="${rx}" ry="${ry}" fill="none" stroke="${col}" stroke-width="22" opacity="0.4" filter="url(#blur10)"/>
    <ellipse cx="${cx}" cy="${cy}" rx="${rx}" ry="${ry}" fill="none" stroke="${col}" stroke-width="7"/>
    <ellipse cx="${cx}" cy="${cy}" rx="${rx}" ry="${ry}" fill="none" stroke="#fff" stroke-width="2" opacity="0.8"/>`;
}

// --- Detail pieces for the dusk arena ------------------------------------

// A cumulus cloud: dark lobes, lighter tops catching the sky, a hot pink
// underside lit by the sun, plus a few loose wisps.
function cloud(x, y, sc, flip = 1) {
  const lobes = [[-70, 14, 38], [-30, -14, 54], [24, -26, 50], [64, -2, 42], [96, 18, 30]];
  let s = `<g transform="translate(${x} ${y}) scale(${sc * flip} ${sc})">`;
  s += `<ellipse cx="10" cy="34" rx="150" ry="40" fill="#ff5aa8" opacity="0.25" filter="url(#blur10)"/>`;
  for (const [dx, dy, r] of lobes) s += `<circle cx="${dx}" cy="${dy}" r="${r}" fill="#4a2278"/>`;
  s += `<rect x="-110" y="8" width="230" height="40" rx="20" fill="#4a2278"/>`;
  for (const [dx, dy, r] of lobes) s += `<circle cx="${dx - r * 0.18}" cy="${dy - r * 0.2}" r="${r * 0.72}" fill="#6a3398"/>`;
  for (const [dx, dy, r] of lobes) s += `<circle cx="${dx - r * 0.3}" cy="${dy - r * 0.4}" r="${r * 0.35}" fill="#8c4ab0" opacity="0.8"/>`;
  s += `<path d="M -108 36 Q -40 58 10 50 Q 70 60 118 34" stroke="#ff9ac4" stroke-width="6" fill="none" stroke-linecap="round"/>`;
  s += `<path d="M -96 44 Q -20 62 60 54" stroke="#ffd1a8" stroke-width="2.5" fill="none" opacity="0.8" stroke-linecap="round"/>`;
  s += `<path d="M 130 0 q 30 -4 60 4 M 140 16 q 24 -2 46 4" stroke="#6a3398" stroke-width="5" fill="none" stroke-linecap="round"/>`;
  return s + `</g>`;
}

// A mountain range with faceted peaks: each slope facing the sun gets a
// lighter face and a bright rim, the other side falls into shadow.
function peaks(list, base, col, lit, edge) {
  let s = "";
  for (const [x, top, w] of list) {
    const l = x - w, r = x + w;
    s += `<path d="M ${l} ${base} L ${x - w * 0.12} ${top + 14} L ${x} ${top} L ${x + w * 0.2} ${top + 22} L ${r} ${base} Z" fill="${col}"/>`;
    const sunSide = x > 426 ? -1 : 1;
    const fx = sunSide > 0 ? r : l;
    s += `<path d="M ${x} ${top} L ${x + sunSide * w * 0.2} ${top + 22} L ${fx} ${base} L ${x + sunSide * w * 0.15} ${base} L ${x + sunSide * w * 0.05} ${top + (base - top) * 0.45} Z" fill="${lit}" opacity="0.55"/>`;
    s += `<path d="M ${l} ${base} L ${x - w * 0.12} ${top + 14} L ${x} ${top} L ${x + w * 0.2} ${top + 22} L ${r} ${base}" fill="none" stroke="${edge}" stroke-width="3" stroke-linejoin="round" opacity="0.9"/>`;
    // Glowing crevices.
    s += `<path d="M ${x} ${top + 30} l ${-w * 0.08} ${(base - top) * 0.25} l ${w * 0.05} ${(base - top) * 0.15}" fill="none" stroke="${edge}" stroke-width="2" opacity="0.45"/>`;
  }
  return s;
}

// Distant arena on the ridge: a domed stadium and two towers with lit windows
// and pennants, all silhouetted against the dusk.
function castle(cx, by) {
  let s = `<ellipse cx="${cx}" cy="${by - 30}" rx="150" ry="60" fill="#ff6ab0" opacity="0.25" filter="url(#blur24)"/>`;
  s += `<path d="M ${cx - 90} ${by} L ${cx - 90} ${by - 40} Q ${cx} ${by - 100} ${cx + 90} ${by - 40} L ${cx + 90} ${by} Z" fill="#26103f"/>`;
  s += `<path d="M ${cx - 90} ${by - 40} Q ${cx} ${by - 100} ${cx + 90} ${by - 40}" fill="none" stroke="#ff8fd0" stroke-width="2.5"/>`;
  for (let i = 0; i < 7; i++) s += `<rect x="${cx - 66 + i * 20}" y="${by - 34}" width="7" height="12" rx="3" fill="#ffd27a"/>`;
  for (const [tx, th] of [[cx - 110, 120], [cx + 110, 100]]) {
    s += `<rect x="${tx - 16}" y="${by - th}" width="32" height="${th}" fill="#26103f"/><path d="M ${tx - 22} ${by - th} L ${tx} ${by - th - 36} L ${tx + 22} ${by - th} Z" fill="#3a1660" stroke="#ff8fd0" stroke-width="2"/>`;
    s += `<line x1="${tx}" y1="${by - th - 36}" x2="${tx}" y2="${by - th - 62}" stroke="#26103f" stroke-width="3"/><path d="M ${tx} ${by - th - 62} l 22 6 l -22 6 z" fill="#33dcff"/>`;
    for (let k = 0; k < 3; k++) s += `<rect x="${tx - 4}" y="${by - th + 16 + k * 26}" width="8" height="12" rx="3" fill="#ffd27a"/>`;
  }
  // Searchlights sweeping up from the stadium.
  for (const a of [-0.35, 0.3]) s += `<path d="M ${cx} ${by - 60} L ${cx + Math.sin(a - 0.04) * 500} ${by - 60 - Math.cos(a) * 500} L ${cx + Math.sin(a + 0.04) * 500} ${by - 60 - Math.cos(a) * 500} Z" fill="#9ae6ff" opacity="0.08"/>`;
  return s;
}

// A glowing crystal cluster for the foreground corners.
function crystals(x, y, sc, col, flip = 1) {
  const shards = [[0, 0, 26, 150, -8], [-36, 18, 20, 100, -24], [34, 22, 18, 110, 16], [-62, 40, 14, 60, -38], [60, 44, 12, 70, 34]];
  let s = `<g transform="translate(${x} ${y}) scale(${sc * flip} ${sc})"><ellipse cx="0" cy="-40" rx="110" ry="90" fill="${col}" opacity="0.3" filter="url(#blur24)"/>`;
  for (const [dx, dy, w, h, rot] of shards) {
    s += `<g transform="translate(${dx} ${dy}) rotate(${rot})">
      <path d="M ${-w} 0 L ${-w} ${-h * 0.75} L 0 ${-h} L ${w} ${-h * 0.75} L ${w} 0 Z" fill="${shade(col, -0.35)}"/>
      <path d="M ${-w} 0 L ${-w} ${-h * 0.75} L 0 ${-h} L 0 0 Z" fill="${col}"/>
      <path d="M ${-w * 0.6} ${-h * 0.1} L ${-w * 0.6} ${-h * 0.7} L ${-w * 0.2} ${-h * 0.86}" stroke="#fff" stroke-width="3" fill="none" opacity="0.7"/>
      <path d="M ${-w} ${-h * 0.75} L 0 ${-h} L ${w} ${-h * 0.75}" stroke="${shade(col, 0.5)}" stroke-width="2" fill="none"/></g>`;
  }
  for (const [dx, r] of [[-80, 14], [-50, 20], [-14, 16], [26, 22], [70, 15], [96, 10]]) s += `<ellipse cx="${dx}" cy="${4 + r * 0.2}" rx="${r * 1.3}" ry="${r * 0.7}" fill="#24104a" stroke="${col}" stroke-opacity="0.5" stroke-width="2"/>`;
  return s + `</g>`;
}

// Mirror an element in the glossy floor at contact height cy.
const reflect = (cy, inner, o = 0.22) =>
  `<g transform="translate(0 ${2 * cy}) scale(1 -1)" opacity="${o}" filter="url(#blur4)">${inner}</g>`;

// Extra critter details layered on top of the shared cast.
function castDetail() {
  let s = "";
  // Ghost: a wispy tail curling off behind it.
  s += `<path d="M 118 580 q -50 30 -90 10 q 30 -4 40 -26 q -30 10 -50 -6" fill="#e3d6ff" opacity="0.35"/>`;
  // Comet: a tapering tail of light with stars caught in it.
  s += `<defs><linearGradient id="ctail" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#ff9ae8" stop-opacity="0.8"/><stop offset="1" stop-color="#ff9ae8" stop-opacity="0"/></linearGradient></defs>`;
  s += `<path d="M 730 515 L 860 470 L 870 560 L 730 580 Z" fill="url(#ctail)" opacity="0.6"/>`;
  s += sparkle(800, 520, 8) + sparkle(835, 545, 5) + sparkle(770, 560, 6, "#ffd1f3");
  // Phoenix: an inner flame tongue and embers drifting up.
  s += spikes(432, 565, 52, 66, 9, "#fff2a8", 0.2, Math.PI * 1.15, Math.PI * 1.85);
  for (const [x, y, r] of [[380, 470, 4], [470, 455, 5], [500, 490, 3], [355, 500, 3], [445, 430, 3]]) s += `<circle cx="${x}" cy="${y}" r="${r * 2.5}" fill="#ff7a1f" opacity="0.4" filter="url(#blur4)"/><circle cx="${x}" cy="${y}" r="${r}" fill="#ffe066"/>`;
  // Drako: scale ridges on the brow and smoke from the nostrils.
  for (let i = 0; i < 4; i++) s += `<path d="M ${100 + i * 20} 694 q 10 -10 20 0" fill="none" stroke="#1f7a37" stroke-width="4" stroke-linecap="round"/>`;
  s += `<path d="M 104 798 h 52 M 108 808 h 44" stroke="#6fbf82" stroke-width="3" stroke-linecap="round"/>`;
  s += `<circle cx="196" cy="742" r="9" fill="#9a8aa8" opacity="0.5"/><circle cx="208" cy="728" r="12" fill="#9a8aa8" opacity="0.35"/><circle cx="224" cy="712" r="15" fill="#9a8aa8" opacity="0.2"/>`;
  // Laser: a muzzle ring and a scorch flash where the beam lands.
  s += `<ellipse cx="660" cy="742" rx="10" ry="16" transform="rotate(-26 660 742)" fill="none" stroke="#c9f4ff" stroke-width="4"/>`;
  s += `<circle cx="505" cy="818" r="40" fill="#7fe6ff" opacity="0.35" filter="url(#blur10)"/>`;
  for (let i = 0; i < 6; i++) {
    const a = i * 1.05 + 0.3;
    s += `<line x1="${505 + Math.cos(a) * 18}" y1="${818 + Math.sin(a) * 18}" x2="${505 + Math.cos(a) * 36}" y2="${818 + Math.sin(a) * 36}" stroke="#e6fbff" stroke-width="3" stroke-linecap="round"/>`;
  }
  // Sprout: veins on the head leaves and a little flower.
  s += `<path d="M 133 868 q -18 -16 -36 -12 M 137 868 q 18 -16 36 -12" stroke="#3f8a26" stroke-width="2" fill="none"/>`;
  s += `<circle cx="172" cy="882" r="9" fill="#ff8ac0"/><circle cx="172" cy="882" r="4" fill="#ffe066"/>`;
  // Kraken: spots on the body and suckers along the tentacles.
  for (const [x, y, r] of [[670, 905, 9], [760, 915, 7], [750, 990, 8], [680, 995, 6]]) s += `<circle cx="${x}" cy="${y}" r="${r}" fill="#6b2a99" opacity="0.6"/>`;
  for (let i = 0; i < 5; i++) {
    const a = Math.PI * (0.15 + i * 0.175);
    for (let k = 1; k <= 3; k++) s += `<circle cx="${715 + Math.cos(a) * (50 + k * 18)}" cy="${950 + Math.sin(a) * (48 + k * 15)}" r="3" fill="#e9c8ff" opacity="0.8"/>`;
  }
  // Two little bats flitting round Nibbles.
  for (const [x, y, sc] of [[270, 930, 1], [600, 900, 0.8]]) s += `<path transform="translate(${x} ${y}) scale(${sc})" d="M 0 0 q -14 -16 -32 -8 q 8 4 6 12 q 10 -6 14 0 q 6 -10 12 -4 q 6 -6 12 4 q 4 -6 14 0 q -2 -8 6 -12 q -18 -8 -32 8 z" fill="#2a0f2a" stroke="#ff7a96" stroke-width="1.5"/>`;
  return s;
}

function groundDetail() {
  let s = "";
  // Sundae: a cream cap with drips and sprinkles, a cherry on top.
  s += `<path transform="translate(0 -18)" d="M 86 1262 q 10 -60 64 -64 q 54 4 64 64 q -10 6 -14 -2 q -4 18 -12 2 q -10 12 -18 0 q -10 14 -20 0 q -8 16 -18 0 q -10 10 -16 -2 q -6 10 -14 0 q -8 8 -16 2 z" fill="#fff6ee" opacity="0.95"/>`;
  for (const [x, y, c, a] of [[120, 1206, "#ff5aa8", 20], [150, 1194, "#7fe6ff", -30], [180, 1210, "#ffe066", 60], [136, 1226, "#a6ff6e", -10], [168, 1230, "#ff5aa8", 40]]) s += `<rect x="${x}" y="${y}" width="10" height="3.5" rx="1.5" fill="${c}" transform="rotate(${a} ${x} ${y})"/>`;
  s += `<circle cx="150" cy="1180" r="11" fill="#ff2d55"/><circle cx="146" cy="1176" r="3.5" fill="#fff" opacity="0.8"/><path d="M 152 1170 q 6 -14 14 -16" stroke="#3f8a26" stroke-width="2.5" fill="none"/>`;
  // Yeti: shaggy tufts round the outline.
  for (let i = 0; i < 14; i++) {
    const a = Math.PI * (0.05 + i * 0.065) + Math.PI;
    const x = 690 + Math.cos(a) * 74, y = 1300 + Math.sin(a) * 74;
    s += `<path d="M ${x} ${y} l ${Math.cos(a - 0.3) * 14} ${Math.sin(a - 0.3) * 14} l ${Math.cos(a + 0.4) * 6} ${Math.sin(a + 0.4) * 6}" fill="none" stroke="#eef2fa" stroke-width="4" stroke-linecap="round"/>`;
  }
  // Yoyo: speed streaks along its loop.
  for (const a of [0.3, 0.6, 0.9]) s += `<path d="M ${480 + Math.cos(Math.PI + a) * 70} ${1460 + Math.sin(Math.PI + a) * 40} A 70 40 0 0 1 ${480 + Math.cos(Math.PI + a + 0.4) * 70} ${1460 + Math.sin(Math.PI + a + 0.4) * 40}" stroke="#fff" stroke-width="3" fill="none" opacity="${0.9 - a * 0.6}"/>`;
  return s;
}

const svg = (body_) => `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${defs}${body_}</svg>`;

// --- Option A: Dusk arena -----------------------------------------------
// The painted picture's sunset at dusk: a deep indigo sky with stars, a
// low magenta-gold sun behind the title, layered mountains rim-lit pink,
// and the neon grid and ring glowing out of the dark.
function dusk() {
  let s = `<defs>
    <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#0d0a2a"/><stop offset="0.25" stop-color="#2a145a"/><stop offset="0.45" stop-color="#7a2a86"/><stop offset="0.56" stop-color="#e2557f"/><stop offset="0.6" stop-color="#ffb35c"/>
    </linearGradient>
    <linearGradient id="floor" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3a1670"/><stop offset="0.4" stop-color="#1c0c48"/><stop offset="1" stop-color="#0b0624"/></linearGradient>
    <radialGradient id="sun" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#fff2b8"/><stop offset="0.6" stop-color="#ffc35a"/><stop offset="1" stop-color="#ff6a8a"/></radialGradient>
  </defs>
  <rect width="${W}" height="${H}" fill="url(#sky)"/>`;
  // Nebula wisps and a field of tinted stars, a crescent moon, a shooting star.
  for (const [x, y, rx, ry, c, o] of [[160, 160, 260, 90, "#5a2ab8", 0.35], [660, 110, 240, 80, "#b83a9a", 0.28], [420, 60, 300, 60, "#2a4ab8", 0.3], [720, 300, 160, 70, "#7a2ab8", 0.25]])
    s += `<ellipse cx="${x}" cy="${y}" rx="${rx}" ry="${ry}" fill="${c}" opacity="${o}" filter="url(#blur60)"/>`;
  for (let i = 0; i < 150; i++) {
    const x = rnd() * W, y = rnd() * 780, r = rnd() * 1.8 + 0.4;
    const c = ["#fff", "#fff", "#fff", "#ffd1f3", "#bfefff"][i % 5];
    if (r > 1.9) s += `<circle cx="${x}" cy="${y}" r="${r * 3}" fill="${c}" opacity="0.2" filter="url(#blur4)"/>`;
    s += `<circle cx="${x}" cy="${y}" r="${r}" fill="${c}" opacity="${0.3 + rnd() * 0.6}"/>`;
  }
  s += sparkle(120, 140, 14) + sparkle(740, 220, 10) + sparkle(640, 90, 8) + sparkle(300, 60, 9, "#bfefff") + sparkle(60, 300, 7, "#ffd1f3");
  s += `<circle cx="745" cy="130" r="60" fill="#ffe6f6" opacity="0.25" filter="url(#blur24)"/><path d="M 760 88 A 44 44 0 1 0 778 160 A 36 36 0 1 1 760 88 Z" fill="#ffeef8"/>`;
  s += `<defs><linearGradient id="shoot" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#fff"/></linearGradient></defs>`;
  s += `<path d="M 40 70 L 214 128 L 210 134 Z" fill="url(#shoot)"/>` + sparkle(214, 131, 8);
  // Sun with stripes, its glow and light rays behind the title.
  s += `<circle cx="426" cy="560" r="420" fill="#ff6a9a" opacity="0.35" filter="url(#blur60)"/>`;
  for (let i = 0; i < 18; i++) {
    const a = (i / 18) * Math.PI * 2, w = i % 2 ? 0.03 : 0.06;
    s += `<path d="M 426 330 L ${426 + Math.cos(a - w) * 1400} ${330 + Math.sin(a - w) * 1400} L ${426 + Math.cos(a + w) * 1400} ${330 + Math.sin(a + w) * 1400} Z" fill="#ffd9a8" opacity="${i % 2 ? 0.04 : 0.07}"/>`;
  }
  s += `<defs><clipPath id="sunbands">`;
  for (let k = 0; k < 9; k++) s += `<rect x="0" y="${330 - 215 + k * 26 + (k > 4 ? (k - 4) * 3 : 0)}" width="${W}" height="${k > 4 ? 26 - (k - 4) * 5 : 26}"/>`;
  s += `<rect x="0" y="${330 - 215 + 9 * 26}" width="${W}" height="0"/></clipPath></defs>`;
  s += `<circle cx="426" cy="330" r="250" fill="#ffb35c" opacity="0.4" filter="url(#blur24)"/><circle cx="426" cy="330" r="215" fill="url(#sun)" opacity="0.92"/>`;
  for (let k = 0; k < 6; k++) s += `<rect x="200" y="${380 + k * 26}" width="460" height="${3 + k * 2.5}" fill="#7a2a86" opacity="0.7"/>`;
  s += `<circle cx="426" cy="330" r="215" fill="none" stroke="#fff2b8" stroke-width="3" opacity="0.6"/>`;
  // Clouds lit from below.
  s += cloud(100, 470, 1) + cloud(770, 395, 0.85, -1) + cloud(760, 630, 0.6, -1) + cloud(40, 250, 0.5);
  // Far faceted peaks, the arena on the ridge, then rolling hills.
  s += peaks([[40, 740, 150], [250, 800, 140], [610, 780, 150], [820, 730, 140]], 1080, "#3a1462", "#c04a9e", "#ff8fb8");
  s += `<rect x="0" y="860" width="${W}" height="220" fill="#ff5aa8" opacity="0.12" filter="url(#blur24)"/>`;
  s += castle(426, 912);
  const range = (base, amp, seed, col, edge) => {
    let d = `M 0 ${H} L 0 ${base}`;
    const pts = [];
    for (let x = 0; x <= W; x += 20) {
      const y = base - amp * (0.5 + 0.5 * Math.sin(x * 0.012 + seed)) - amp * 0.4 * Math.sin(x * 0.031 + seed * 2);
      pts.push([x, y]);
      d += ` L ${x} ${y}`;
    }
    d += ` L ${W} ${H} Z`;
    return `<path d="${d}" fill="${col}"/><polyline points="${pts.map((p) => p.join(",")).join(" ")}" fill="none" stroke="${edge}" stroke-width="3" opacity="0.8"/>`;
  };
  s += range(1010, 90, 3.3, "#2a0f4c", "#ff5aa8");
  // Pine silhouettes along the near hills.
  for (const [x, h] of [[20, 70], [52, 54], [86, 80], [236, 50], [262, 66], [590, 60], [618, 84], [652, 56], [790, 74], [826, 58]]) {
    const y = 1010 - 90 * (0.5 + 0.5 * Math.sin(x * 0.012 + 3.3)) - 36 * Math.sin(x * 0.031 + 6.6) + 6;
    s += `<path d="M ${x} ${y - h} L ${x + h * 0.28} ${y} L ${x - h * 0.28} ${y} Z" fill="#1a0834"/><path d="M ${x} ${y - h} L ${x + h * 0.28} ${y}" stroke="#ff5aa8" stroke-width="1.5" opacity="0.6"/>`;
  }
  s += range(1050, 40, 5.0, "#1e0a3c", "#c44fff");
  // The floor: horizon haze, neon grid with glowing crossings, the ring.
  s += `<rect x="0" y="1060" width="${W}" height="${H - 1060}" fill="url(#floor)"/>`;
  s += `<rect x="0" y="1050" width="${W}" height="24" fill="#ff5ad8" opacity="0.6" filter="url(#blur10)"/>`;
  s += `<rect x="0" y="1062" width="${W}" height="70" fill="#ff7ad0" opacity="0.18" filter="url(#blur24)"/>`;
  s += grid(1062, "#d24fff", { opacity: 0.55 });
  for (let i = 0; i < 18; i++) {
    const x = 40 + rnd() * (W - 80), y = 1120 + rnd() * 650;
    s += `<circle cx="${x}" cy="${y}" r="10" fill="#ff7ae8" opacity="0.35" filter="url(#blur4)"/><circle cx="${x}" cy="${y}" r="2.5" fill="#ffd1f3"/>`;
  }
  // Floor reflections of the cast standing on it.
  s += reflect(1240, body(428, 1090, 135, "#d42a4a", { glow: 0 }), 0.18);
  s += reflect(1372, body(150, 1300, 72, "#fbe3d8", { glow: 0 }), 0.15) + reflect(1374, body(690, 1300, 76, "#cfd6e4", { glow: 0 }), 0.15);
  s += `<ellipse cx="432" cy="1262" rx="380" ry="90" fill="#27c8ff" opacity="0.12" filter="url(#blur24)"/>` + ring(432, 1262, 330, 58, "#33dcff");
  s += `<ellipse cx="432" cy="1262" rx="290" ry="46" fill="none" stroke="#33dcff" stroke-width="2" stroke-dasharray="14 10" opacity="0.6"/>`;
  for (let i = 0; i < 24; i++) {
    const a = (i / 24) * Math.PI * 2, x = 432 + Math.cos(a) * 345, y = 1262 + Math.sin(a) * 66;
    s += `<line x1="${432 + Math.cos(a) * 335}" y1="${1262 + Math.sin(a) * 62}" x2="${x}" y2="${y}" stroke="#bff6ff" stroke-width="2" opacity="0.7"/>`;
  }
  for (const a of [0, Math.PI / 2, Math.PI, Math.PI * 1.5]) {
    const x = 432 + Math.cos(a) * 330, y = 1262 + Math.sin(a) * 58;
    s += `<circle cx="${x}" cy="${y}" r="18" fill="#33dcff" opacity="0.5" filter="url(#blur10)"/><path d="M ${x} ${y - 10} L ${x + 8} ${y} L ${x} ${y + 10} L ${x - 8} ${y} Z" fill="#fff"/>`;
  }
  s += `<ellipse cx="428" cy="1240" rx="150" ry="26" fill="#000" opacity="0.45"/>`;
  s += title(300) + cast("#ff9ad8") + castDetail() + nibbles() + ground("#ff9ad8") + groundDetail();
  // Title glints.
  s += sparkle(170, 330, 16) + sparkle(700, 474, 14) + sparkle(300, 410, 9, "#fff6a8");
  for (const [x, y, r] of [[57, 630, 22], [790, 870, 22], [62, 1150, 22], [782, 1153, 22], [568, 778, 14], [770, 438, 16], [300, 1560, 18], [600, 1640, 16]]) s += coin(x, y, r);
  for (const [x, y, sz] of [[260, 600, 14], [600, 470, 12], [40, 1060, 12], [810, 1050, 14], [330, 1500, 10], [620, 1560, 10]]) s += sparkle(x, y, sz);
  // Crystal clusters in the foreground corners, then a vignette at the foot.
  s += crystals(60, 1700, 1, "#c44fff") + crystals(800, 1640, 0.8, "#33dcff", -1);
  s += `<defs><linearGradient id="foot" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0b0624" stop-opacity="0"/><stop offset="1" stop-color="#0b0624" stop-opacity="0.85"/></linearGradient></defs><rect x="0" y="1560" width="${W}" height="${H - 1560}" fill="url(#foot)"/>`;
  // Fireflies of light rising off the floor.
  for (let i = 0; i < 40; i++) {
    const x = rnd() * W, y = 1000 + rnd() * 800;
    s += `<circle cx="${x}" cy="${y}" r="${2 + rnd() * 3}" fill="${i % 3 ? "#ff9ae8" : "#9ae6ff"}" opacity="${0.3 + rnd() * 0.5}"/>`;
  }
  return svg(s);
}

// --- Option B: Spotlight stage --------------------------------------------
// Night show: a dark blue stage under swinging spotlights and festoon
// lights, the title hung like a marquee, Nibbles on a lit round podium and
// the cast in the glow around him, confetti in the air.
function stage() {
  let s = `<defs>
    <linearGradient id="bsky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#070a24"/><stop offset="0.5" stop-color="#1a1650"/><stop offset="0.62" stop-color="#2c1c66"/><stop offset="1" stop-color="#0c0820"/></linearGradient>
    <linearGradient id="beam" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff6d0" stop-opacity="0.5"/><stop offset="1" stop-color="#fff6d0" stop-opacity="0"/></linearGradient>
    <radialGradient id="pod" cx="0.5" cy="0.4" r="0.6"><stop offset="0" stop-color="#5a3aa8"/><stop offset="1" stop-color="#22145a"/></radialGradient>
  </defs>
  <rect width="${W}" height="${H}" fill="url(#bsky)"/>`;
  // Curtains at the sides.
  for (const side of [0, 1]) {
    const x0 = side ? W : 0, dir = side ? -1 : 1;
    let d = `M ${x0} 0 L ${x0 + dir * 120} 0 Q ${x0 + dir * 70} 600 ${x0 + dir * 150} 1100 L ${x0} 1100 Z`;
    s += `<path d="${d}" fill="#5a0f3a"/>`;
    for (let k = 0; k < 4; k++) s += `<path d="M ${x0 + dir * (20 + k * 28)} 0 Q ${x0 + dir * (10 + k * 22)} 600 ${x0 + dir * (30 + k * 32)} 1100" stroke="#8a1a5a" stroke-width="10" fill="none" opacity="0.7"/>`;
  }
  s += `<path d="M 0 0 L ${W} 0 L ${W} 70 Q ${W * 0.75} 120 ${W / 2} 80 Q ${W * 0.25} 120 0 70 Z" fill="#7a1248"/><path d="M 0 70 Q ${W * 0.25} 120 ${W / 2} 80 Q ${W * 0.75} 120 ${W} 70" stroke="#ffcf3d" stroke-width="6" fill="none"/>`;
  // Spotlight beams converging on the podium.
  for (const [x, c] of [[90, "#ffe7a8"], [W - 90, "#ffe7a8"], [260, "#ff9ad8"], [W - 260, "#9ae6ff"]]) {
    s += `<path d="M ${x - 14} 90 L ${x + 14} 90 L ${428 + 210} 1300 L ${428 - 210} 1300 Z" fill="${c}" opacity="0.07"/>`;
    s += `<circle cx="${x}" cy="96" r="22" fill="#2a2050" stroke="#6b5fae" stroke-width="5"/><circle cx="${x}" cy="102" r="12" fill="${c}"/><circle cx="${x}" cy="102" r="40" fill="${c}" opacity="0.4" filter="url(#blur10)"/>`;
  }
  // Festoon lights.
  for (const [y0, sag] of [[118, 30], [640, 50]]) {
    let d = "";
    for (let i = 0; i <= 20; i++) {
      const t = i / 20, x = 60 + t * (W - 120), y = y0 + Math.sin(t * Math.PI) * sag;
      d += `${i ? "L" : "M"} ${x} ${y} `;
      if (i % 2 === 0) {
        const c = ["#ffd23f", "#ff5aa8", "#7fe6ff", "#a6ff6e"][(i / 2) % 4];
        s += `<circle cx="${x}" cy="${y + 10}" r="18" fill="${c}" opacity="0.4" filter="url(#blur10)"/><circle cx="${x}" cy="${y + 10}" r="7" fill="${c}"/>`;
      }
    }
    s += `<path d="${d}" stroke="#3a2a60" stroke-width="3" fill="none"/>`;
  }
  // Marquee board behind the title.
  s += `<rect x="96" y="150" width="${W - 192}" height="330" rx="40" fill="#1a0f3c" stroke="#ffcf3d" stroke-width="8"/>`;
  for (let i = 0; i < 26; i++) {
    const t = i / 26;
    const per = 2 * (W - 192 + 330);
    let d = t * per, x, y;
    if (d < W - 192) { x = 96 + d; y = 150; } else if ((d -= W - 192) < 330) { x = W - 96; y = 150 + d; } else if ((d -= 330) < W - 192) { x = W - 96 - d; y = 480; } else { d -= W - 192; x = 96; y = 480 - d; }
    s += `<circle cx="${x}" cy="${y}" r="9" fill="#fff3b8"/><circle cx="${x}" cy="${y}" r="20" fill="#ffd23f" opacity="0.35" filter="url(#blur4)"/>`;
  }
  // The stage floor: glossy boards, a lit round podium with the ring.
  s += `<rect x="0" y="1100" width="${W}" height="${H - 1100}" fill="#170d38"/>`;
  for (let i = -10; i <= 10; i++) s += `<line x1="${W / 2 + i * 40}" y1="1100" x2="${W / 2 + i * 160}" y2="${H}" stroke="#2a1a5a" stroke-width="3"/>`;
  s += `<ellipse cx="432" cy="1262" rx="420" ry="140" fill="#ffe7a8" opacity="0.12" filter="url(#blur24)"/>`;
  s += `<ellipse cx="432" cy="1290" rx="360" ry="80" fill="#120a2c"/><ellipse cx="432" cy="1262" rx="360" ry="80" fill="url(#pod)" stroke="#8a6aff" stroke-width="4"/>`;
  s += ring(432, 1262, 330, 58, "#33dcff");
  s += `<ellipse cx="428" cy="1240" rx="150" ry="26" fill="#000" opacity="0.45"/>`;
  s += title(282, { fill2: "#ffcf3d" }) + cast("#ffcf7a") + nibbles() + ground("#ffcf7a");
  for (const [x, y, r] of [[57, 630, 22], [790, 870, 22], [62, 1150, 22], [782, 1153, 22], [568, 778, 14], [770, 438, 16]]) s += coin(x, y, r);
  // Confetti.
  for (let i = 0; i < 70; i++) {
    const x = rnd() * W, y = 560 + rnd() * 1200, c = ["#ffd23f", "#ff5aa8", "#7fe6ff", "#a6ff6e", "#ffffff"][i % 5];
    s += `<rect x="${x}" y="${y}" width="${6 + rnd() * 6}" height="${3 + rnd() * 4}" fill="${c}" transform="rotate(${rnd() * 180} ${x} ${y})" opacity="${0.5 + rnd() * 0.5}"/>`;
  }
  return svg(s);
}

const SCENES = { dusk };

const out = path.resolve(process.argv[2] || path.join(repo, "build/loading_scenes"));
fs.mkdirSync(out, { recursive: true });
const require = createRequire(path.join(repo, "smoke/package.json"));
const { chromium } = require("playwright");
const browser = await chromium.launch(process.env.CHROMIUM_PATH ? { executablePath: process.env.CHROMIUM_PATH } : {});
const page = await browser.newPage({ viewport: { width: W, height: H } });
for (const [name, fn] of Object.entries(SCENES)) {
  const markup = fn();
  fs.writeFileSync(path.join(out, `loading_${name}.svg`), markup);
  await page.setContent(`<html><body style="margin:0">${markup}</body></html>`);
  await page.evaluate(() => document.fonts.ready);
  await page.waitForTimeout(200);
  await page.screenshot({ path: path.join(out, `loading_${name}.png`), clip: { x: 0, y: 0, width: W, height: H } });
  console.log(path.join(out, `loading_${name}.png`));
}
await browser.close();

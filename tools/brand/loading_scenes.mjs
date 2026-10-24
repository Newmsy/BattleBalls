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
  for (const [x, y, c] of [[150, 1196, "#7a4a2a"], [120, 1150, "#ffb3d1"], [176, 1120, "#fff1d6"]]) s += `<circle cx="${x}" cy="${y}" r="20" fill="${c}"/><circle cx="${x}" cy="${y - 20}" r="6" fill="#ff2d55"/>`;
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
  for (let i = 0; i < 90; i++) {
    const x = rnd() * W, y = rnd() * 760, r = rnd() * 1.8 + 0.4;
    s += `<circle cx="${x}" cy="${y}" r="${r}" fill="#fff" opacity="${0.3 + rnd() * 0.6}"/>`;
  }
  s += sparkle(120, 140, 14) + sparkle(740, 220, 10) + sparkle(640, 90, 8);
  // Sun with stripes, its glow and light rays behind the title.
  s += `<circle cx="426" cy="560" r="420" fill="#ff6a9a" opacity="0.35" filter="url(#blur60)"/>`;
  for (let i = 0; i < 14; i++) {
    const a = (i / 14) * Math.PI * 2;
    s += `<path d="M 426 330 L ${426 + Math.cos(a - 0.05) * 1400} ${330 + Math.sin(a - 0.05) * 1400} L ${426 + Math.cos(a + 0.05) * 1400} ${330 + Math.sin(a + 0.05) * 1400} Z" fill="#ffd9a8" opacity="0.06"/>`;
  }
  s += `<circle cx="426" cy="330" r="250" fill="#ffb35c" opacity="0.4" filter="url(#blur24)"/><circle cx="426" cy="330" r="215" fill="url(#sun)" opacity="0.92"/>`;
  for (let k = 0; k < 0; k++) s += `<rect x="190" y="${400 + k * 22}" width="480" height="${4 + k * 2}" fill="#2a145a" opacity="0.55"/>`;
  // Clouds lit from below.
  for (const [x, y, sc] of [[110, 470, 1], [760, 400, 0.9], [740, 620, 0.7]]) {
    s += `<g opacity="0.85">`;
    for (const [dx, dy, r] of [[-60, 10, 40], [-20, -12, 52], [30, -4, 46], [70, 12, 34]]) s += `<circle cx="${x + dx * sc}" cy="${y + dy * sc}" r="${r * sc}" fill="#5a2a8a"/>`;
    s += `<rect x="${x - 95 * sc}" y="${y + 6 * sc}" width="${190 * sc}" height="${36 * sc}" rx="${18 * sc}" fill="#5a2a8a"/>`;
    s += `<path d="M ${x - 90 * sc} ${y + 30 * sc} Q ${x} ${y + 52 * sc} ${x + 95 * sc} ${y + 30 * sc}" stroke="#ff8fb8" stroke-width="${5 * sc}" fill="none" opacity="0.8"/></g>`;
  }
  // Mountains: far, mid, near, each rim-lit along its top.
  const range = (base, amp, seed, col, edge) => {
    let d = `M 0 ${H} L 0 ${base}`;
    const pts = [];
    for (let x = 0; x <= W; x += 40) {
      const y = base - amp * (0.5 + 0.5 * Math.sin(x * 0.012 + seed)) - amp * 0.4 * Math.sin(x * 0.031 + seed * 2);
      pts.push([x, y]);
      d += ` L ${x} ${y}`;
    }
    d += ` L ${W} ${H} Z`;
    return `<path d="${d}" fill="${col}"/><polyline points="${pts.map((p) => p.join(",")).join(" ")}" fill="none" stroke="${edge}" stroke-width="3" opacity="0.8"/>`;
  };
  s += range(900, 170, 1.1, "#4a1a6e", "#ff8fb8") + range(990, 110, 3.3, "#2f1052", "#ff5aa8") + range(1040, 60, 5.0, "#1e0a3c", "#c44fff");
  // The floor and its neon grid.
  s += `<rect x="0" y="1060" width="${W}" height="${H - 1060}" fill="url(#floor)"/>`;
  s += `<rect x="0" y="1050" width="${W}" height="24" fill="#ff5ad8" opacity="0.6" filter="url(#blur10)"/>`;
  s += grid(1062, "#d24fff", { opacity: 0.55 });
  s += `<ellipse cx="432" cy="1262" rx="380" ry="90" fill="#27c8ff" opacity="0.12" filter="url(#blur24)"/>` + ring(432, 1262, 330, 58, "#33dcff");
  s += `<ellipse cx="428" cy="1240" rx="150" ry="26" fill="#000" opacity="0.45"/>`;
  s += title(300) + cast("#ff9ad8") + nibbles() + ground("#ff9ad8");
  for (const [x, y, r] of [[57, 630, 22], [312, 826, 0], [790, 870, 22], [62, 1150, 22], [782, 1153, 22], [568, 778, 14], [770, 438, 16]]) if (r) s += coin(x, y, r);
  for (const [x, y, sz] of [[260, 600, 14], [600, 470, 12], [40, 1060, 12], [810, 1050, 14], [330, 1500, 10], [620, 1560, 10]]) s += sparkle(x, y, sz);
  // Fireflies of light rising off the floor.
  for (let i = 0; i < 26; i++) {
    const x = rnd() * W, y = 1100 + rnd() * 700;
    s += `<circle cx="${x}" cy="${y}" r="${2 + rnd() * 3}" fill="#ff9ae8" opacity="${0.3 + rnd() * 0.5}"/>`;
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

const SCENES = { dusk, stage };

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

// The summon egg from game/ui/screens/summon_screen.gd (_Capsule._draw_egg
// and EggArt.pattern), ported to SVG so event art can show the same eggs.
// Everything is built in the same unit egg space as the game (x -0.8..0.8,
// y -1.1..0.9, y down) and placed with a transform, so shapes match exactly.

// Godot Color helpers on #rrggbb strings.
const rgb = (h) => [0, 2, 4].map((i) => parseInt(h.replace("#", "").slice(i, i + 2), 16));
const hex = (c) => "#" + c.map((v) => Math.max(0, Math.min(255, Math.round(v))).toString(16).padStart(2, "0")).join("");
export const lerp = (a, b, t) => hex(rgb(a).map((v, i) => v + (rgb(b)[i] - v) * t));
export const darkened = (a, t) => hex(rgb(a).map((v) => v * (1 - t)));

// Roster.RARITY_COLORS and the family colours from sim/families.gd.
export const RARITY = { common: "#c9d3e0", uncommon: "#4cd98a", rare: "#3d9bff", epic: "#b366ff", legendary: "#ffc23d" };
export const RARITY_INDEX = { common: 0, uncommon: 1, rare: 2, epic: 3, legendary: 4 };
export const FAMILY_INK = { nature: "#5fd068", sea: "#3fa9f5", tech: "#9aa8c7", sweet: "#ff7ac8", frost: "#8fe6ff", toybox: "#ffc93c", spooky: "#b07cff", fire: "#ff6a3d", cosmic: "#6f6bff" };

// Small seeded RNG standing in for RandomNumberGenerator.
export function rng(seed = 7) {
  let s = seed >>> 0;
  const next = () => {
    s = (s + 0x6d2b79f5) >>> 0;
    let t = s;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
  return { randf: next, range: (a, b) => a + (b - a) * next() };
}

const TAU = Math.PI * 2;
const rot = ([x, y], a) => [x * Math.cos(a) - y * Math.sin(a), x * Math.sin(a) + y * Math.cos(a)];

// _Capsule.setup: the unit egg outline (32 points, narrower and taller on top).
export function eggOutline() {
  const pts = [];
  for (let i = 0; i < 32; i++) {
    const a = (TAU * i) / 32;
    const up = Math.max(0, -Math.sin(a));
    pts.push([0.8 * Math.cos(a) * (1 - 0.16 * up), Math.sin(a) * (Math.sin(a) < 0 ? 1.12 : 0.92)]);
  }
  return pts;
}

// The zigzag crack across the middle, left to right.
export function crackLine() {
  const pts = [];
  for (let i = 0; i < 9; i++) pts.push([-0.8 + (1.6 * i) / 8, -0.08 + (i % 2 ? 0.11 : -0.07)]);
  return pts;
}

export function wave(x0, x1, y, amp, waves) {
  const pts = [];
  for (let i = 0; i < 17; i++) pts.push([x0 + ((x1 - x0) * i) / 16, y + amp * Math.sin((i / 16) * TAU * waves * 0.5)]);
  return pts;
}

export function leaf([cx, cy], len, r) {
  const pts = [];
  for (let i = 0; i < 9; i++) {
    const t = i / 8;
    const [x, y] = rot([len * (t - 0.5) * 2, -Math.sin(t * Math.PI) * len * 0.45], r);
    pts.push([cx + x, cy + y]);
  }
  for (let i = 7; i > 0; i--) {
    const t = i / 8;
    const [x, y] = rot([len * (t - 0.5) * 2, Math.sin(t * Math.PI) * len * 0.45], r);
    pts.push([cx + x, cy + y]);
  }
  return pts;
}

// EggArt.pattern for the families event art needs so far: [kind, points, width or 0 for filled].
export function eggPattern(family, r) {
  const out = [];
  if (family === "nature") {
    out.push(["vine", wave(-0.55, 0.55, 0.25, 0.12, 2.2), 0.05]);
    for (const p of [[-0.35, 0.05], [0.12, 0.38], [0.4, -0.2], [-0.1, -0.55]]) out.push(["leaf", leaf(p, 0.2, r.range(-1, 1)), 0]);
  } else {
    for (let k = 0; k < 7; k++) {
      const c = [r.range(-0.5, 0.5), r.range(-0.7, 0.6)], rr = r.range(0.04, 0.08);
      const ring = [];
      for (let i = 0; i < 13; i++) ring.push([c[0] + Math.cos((TAU * i) / 12) * rr, c[1] + Math.sin((TAU * i) / 12) * rr]);
      out.push(["speck", ring, 0]);
    }
  }
  return out;
}

const P = (pts) => pts.map(([x, y]) => `${x.toFixed(4)},${y.toFixed(4)}`).join(" ");

// The shell colour: matte bone with a hint of the family (_shell_color).
export const shellColor = (family) => darkened(lerp("#ddd2bd", FAMILY_INK[family] || "#ffffff", 0.3), 0.12);

let uid = 0;

// The egg as _draw_egg paints it, centred at (cx, cy), `s` pixels per unit
// (the egg is about 1.6s wide, 2.04s tall). `cracked` (0..1) draws the white
// crack with its rarity glow; `crackGlow` the colour leaking out of it.
// `extraShade` adds an SVG-only soft form shadow so it sits in a lit scene.
export function egg(cx, cy, s, { family = "nature", rarity = "common", seed = 7, cracked = 0, crackGlow = null, tilt = 0, extraShade = true } = {}) {
  const id = `egg${uid++}`;
  const r = rng(seed);
  const ri = RARITY_INDEX[rarity];
  const col = RARITY[rarity];
  const shell = shellColor(family);
  const outline = eggOutline();
  const pattern = eggPattern(family, r);
  const specks = [];
  for (let k = 0; k < 9; k++) specks.push([r.range(-0.5, 0.5), r.range(-0.75, 0.6), r.range(0.025, 0.055)]);
  const lit = outline.map(([x, y]) => [x * 0.9 - 0.05, y * 0.9 - 0.06]);
  const ink = darkened(shell, 0.32);
  const pat = pattern
    .map(([, pts, w]) => (w > 0 ? `<polyline points="${P(pts)}" fill="none" stroke="${ink}" stroke-opacity="0.55" stroke-width="${w}" stroke-linecap="round" stroke-linejoin="round"/>` : `<polygon points="${P(pts)}" fill="${ink}" fill-opacity="0.55"/>`))
    .join("");
  const sp = specks.map(([x, y, rr]) => `<circle cx="${x}" cy="${y}" r="${rr}" fill="${darkened(shell, 0.45)}" fill-opacity="0.45"/>`).join("");
  let crack = "";
  if (cracked > 0) {
    const cl = crackLine();
    const n = Math.ceil(cracked * (cl.length - 1));
    const line = cl.slice(0, n + 1);
    const glow = crackGlow || lerp(col, "#ffffff", 0.5);
    crack = `
      <polyline points="${P(line)}" fill="none" stroke="${glow}" stroke-opacity="0.85" stroke-width="0.3" stroke-linecap="round" stroke-linejoin="round" filter="url(#${id}cb)"/>
      <polyline points="${P(line)}" fill="none" stroke="${glow}" stroke-opacity="0.5" stroke-width="0.16" stroke-linecap="round" stroke-linejoin="round"/>
      <polyline points="${P(line)}" fill="none" stroke="#fff" stroke-opacity="0.95" stroke-width="0.06" stroke-linecap="round" stroke-linejoin="round"/>`;
  }
  return `
  <defs>
    <clipPath id="${id}c"><polygon points="${P(outline)}"/></clipPath>
    <radialGradient id="${id}fs" cx="0.3" cy="0.25" r="0.95">
      <stop offset="0.45" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#0b0a1f" stop-opacity="0.45"/>
    </radialGradient>
    <filter id="${id}cb" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="0.07"/></filter>
  </defs>
  <g transform="translate(${cx} ${cy}) rotate(${tilt}) scale(${s})">
    <polygon points="${P(outline)}" fill="${darkened(shell, 0.28)}"/>
    <g clip-path="url(#${id}c)">
      <polygon points="${P(lit)}" fill="${shell}"/>
      ${pat}${sp}
      ${extraShade ? `<rect x="-0.9" y="-1.2" width="1.8" height="2.2" fill="url(#${id}fs)"/>` : ""}
    </g>
    <polygon points="${P(outline)}" fill="none" stroke="${darkened(col, 0.15)}" stroke-width="${0.045 + 0.01 * ri}" stroke-linejoin="round"/>
    <circle cx="-0.3" cy="-0.52" r="0.14" fill="#fff" fill-opacity="0.16"/>
    ${crack}
  </g>`;
}

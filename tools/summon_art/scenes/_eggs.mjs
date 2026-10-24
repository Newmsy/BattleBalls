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

// EggArt.pattern (game/ui/screens/summon_screen.gd), all nine families.
const ring = ([cx, cy], r, n = 12) => Array.from({ length: n + 1 }, (_, i) => [cx + Math.cos((TAU * i) / n) * r, cy + Math.sin((TAU * i) / n) * r]);
const ellipseR = ([cx, cy], [rx, ry], a) => Array.from({ length: 25 }, (_, i) => { const t = (TAU * i) / 24; const [x, y] = rot([Math.cos(t) * rx, Math.sin(t) * ry], a); return [cx + x, cy + y]; });
const starPts = ([cx, cy], r1, r2, n, a0 = -Math.PI / 2) => Array.from({ length: n * 2 }, (_, i) => { const rr = i % 2 ? r2 : r1, a = a0 + (i * Math.PI) / n; return [cx + Math.cos(a) * rr, cy + Math.sin(a) * rr]; });
const crescent = ([cx, cy], r) => {
  const pts = [];
  for (let i = 0; i < 13; i++) { const a = Math.PI * 0.3 + (Math.PI * 1.4 * i) / 12; pts.push([cx + Math.cos(a) * r, cy + Math.sin(a) * r]); }
  for (let i = 12; i >= 0; i--) { const a = Math.PI * 0.4 + (Math.PI * 1.2 * i) / 12; pts.push([cx + r * 0.35 + Math.cos(a) * r * 0.8, cy + Math.sin(a) * r * 0.8]); }
  return pts;
};
export function eggPattern(family, r) {
  const out = [];
  switch (family) {
    case "nature":
      out.push(["vine", wave(-0.55, 0.55, 0.25, 0.12, 2.2), 0.05]);
      for (const p of [[-0.35, 0.05], [0.12, 0.38], [0.4, -0.2], [-0.1, -0.55]]) out.push(["leaf", leaf(p, 0.2, r.range(-1, 1)), 0]);
      break;
    case "sea":
      out.push(["wave", wave(-0.72, 0.72, -0.05, 0.1, 3), 0.07]);
      out.push(["wave", wave(-0.68, 0.68, 0.35, 0.08, 3), 0.06]);
      for (const p of [[-0.3, -0.5], [0.15, -0.7], [0.35, -0.42]]) out.push(["bubble", ring(p, 0.08 + r.randf() * 0.05), 0.04]);
      break;
    case "tech":
      out.push(["trace", [[-0.7, 0.1], [-0.3, 0.1], [-0.15, -0.15], [0.2, -0.15], [0.2, -0.55]], 0.05]);
      out.push(["trace", [[-0.5, 0.55], [-0.1, 0.55], [0.05, 0.3], [0.6, 0.3]], 0.05]);
      out.push(["trace", [[-0.35, -0.45], [-0.35, -0.75]], 0.05]);
      for (const p of [[0.2, -0.55], [0.6, 0.3], [-0.35, -0.75], [-0.5, 0.55], [-0.7, 0.1]]) out.push(["pad", ring(p, 0.065), 0]);
      break;
    case "sweet": {
      const drip = [];
      for (let i = 0; i < 13; i++) { const x = -0.62 + (1.24 * i) / 12; drip.push([x, -0.42 + (i % 3 === 1 ? 0.12 : 0) + 0.05 * Math.sin(x * 7)]); }
      drip.push([0.4, -0.85], [0, -1], [-0.4, -0.85]);
      out.push(["icing", drip, 0]);
      for (let k = 0; k < 9; k++) { const p = [r.range(-0.5, 0.5), r.range(-0.15, 0.65)], a = r.range(0, Math.PI); out.push(["sprinkle", [[p[0] - Math.cos(a) * 0.07, p[1] - Math.sin(a) * 0.07], [p[0] + Math.cos(a) * 0.07, p[1] + Math.sin(a) * 0.07]], 0.05]); }
      break;
    }
    case "frost": {
      const c = [0, -0.05];
      for (let k = 0; k < 6; k++) {
        const a = (k * Math.PI) / 3, d = [Math.cos(a), Math.sin(a)];
        out.push(["arm", [c, [c[0] + d[0] * 0.42, c[1] + d[1] * 0.42]], 0.06]);
        const m = [c[0] + d[0] * 0.26, c[1] + d[1] * 0.26];
        const d1 = rot(d, 0.9), d2 = rot(d, -0.9);
        out.push(["twig", [[m[0] + d1[0] * 0.1, m[1] + d1[1] * 0.1], m, [m[0] + d2[0] * 0.1, m[1] + d2[1] * 0.1]], 0.045]);
      }
      for (const p of [[-0.45, -0.65], [0.45, 0.5], [-0.5, 0.45]]) out.push(["flake", starPts(p, 0.07, 0.025, 6), 0]);
      break;
    }
    case "toybox": {
      for (const p of [[-0.4, -0.4], [0.3, -0.6], [0.05, -0.05], [-0.45, 0.35], [0.45, 0.2], [0.1, 0.58]]) out.push(["dot", ring(p, 0.1 + r.randf() * 0.04), 0]);
      const zig = [];
      for (let i = 0; i < 9; i++) zig.push([-0.76 + (1.52 * i) / 8, 0.3 + (i % 2 ? -0.07 : 0.07)]);
      out.push(["zig", zig, 0.06]);
      break;
    }
    case "spooky":
      out.push(["bat", [[-0.6, 0.05], [-0.4, -0.08], [-0.3, 0.08], [-0.12, -0.05], [0, -0.18], [0.12, -0.05], [0.3, 0.08], [0.4, -0.08], [0.6, 0.05], [0.3, 0.2], [0, 0.1], [-0.3, 0.2]], 0]);
      out.push(["moon", crescent([0.3, -0.6], 0.17), 0]);
      for (const p of [[-0.22, 0.5], [0.18, 0.5]]) out.push(["eye", ring(p, 0.07), 0]);
      break;
    case "fire": {
      const fl = [[-0.66, 0.45]];
      for (let k = 0; k < 5; k++) { const x = -0.55 + k * 0.27; fl.push([x - 0.07, 0.1], [x + 0.02, -0.35 - 0.25 * (k % 2 === 0 ? 1 : 0) * (k === 2 ? 1 : 0.6)], [x + 0.1, 0.05]); }
      fl.push([0.66, 0.45], [0.45, 0.8], [-0.45, 0.8]);
      out.push(["flame", fl, 0]);
      for (const p of [[-0.3, -0.7], [0.25, -0.85], [0.05, -0.6]]) out.push(["ember", ring(p, 0.045 + r.randf() * 0.03), 0]);
      break;
    }
    case "cosmic":
      out.push(["orbit", ellipseR([0, 0.05], [0.95, 0.22], -0.35), 0.05]);
      for (const p of [[-0.3, -0.55], [0.35, -0.3], [-0.15, 0.45], [0.4, 0.45]]) { const big = r.range(0.07, 0.12); out.push(["star", starPts(p, big, big * 0.4, 5), 0]); }
      out.push(["planet", ring([0.05, 0.05], 0.13), 0]);
      break;
    default:
      for (let k = 0; k < 7; k++) out.push(["speck", ring([r.range(-0.5, 0.5), r.range(-0.7, 0.6)], r.range(0.04, 0.08)), 0]);
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

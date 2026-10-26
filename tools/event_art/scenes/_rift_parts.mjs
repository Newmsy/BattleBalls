// Shared pieces for the Rift art (adventure_rift.mjs, rift_tear.mjs): a
// Glitch tear hanging in the air (jagged, magenta and cyan split edges,
// static and scanlines inside, a deep violet glow through it), the nine
// family shards drifting round it, and the brass Rift Key with its glitch
// crystal (the same key as the Bag glyph in game/ui/glyph.gd).
import { FAM } from "./_banner_parts.mjs";
import { rng } from "./_shop_charge_pad_glow_chest_parts.mjs";

export const MG = "#FF4FB8";
export const CY = "#3EE6FF";
const f = (n) => (+n).toFixed(1);

let uid = 0;

// A vertical tear centred on (cx, cy), w wide and h tall.
export function tear(cx, cy, w, h, seed = 3, haze = 1) {
  const R = rng(seed);
  const id = `rt${uid++}`;
  // Jagged outline: down the right edge, back up the left.
  const right = [], left = [];
  const n = 11;
  for (let k = 0; k <= n; k++) {
    const t = k / n, y = cy - h / 2 + t * h;
    const bulge = Math.sin(t * Math.PI) ** 0.8;
    const jag = (k % 2 ? 0.55 : 1) * (0.75 + R() * 0.35);
    right.push([cx + (w / 2) * bulge * jag + (R() - 0.5) * 6, y]);
    left.push([cx - (w / 2) * bulge * (k % 2 ? 1 : 0.6) * (0.75 + R() * 0.35) + (R() - 0.5) * 6, y]);
  }
  const pts = [...right, ...left.reverse()];
  const poly = (dx = 0, dy = 0, s = 1) => pts.map(([x, y]) => `${f(cx + (x - cx) * s + dx)},${f(cy + (y - cy) * s + dy)}`).join(" ");
  // Static and glitch bands inside.
  let noise = "";
  for (let k = 0; k < 260; k++) {
    const x = cx - w / 2 + R() * w, y = cy - h / 2 + R() * h;
    const ww = 2 + R() * (R() < 0.15 ? 22 : 6), hh = 1.5 + R() * 2.5;
    const r = R();
    const c = r < 0.38 ? MG : r < 0.76 ? CY : r < 0.9 ? "#ffffff" : "#6f6bff";
    noise += `<rect x="${f(x)}" y="${f(y)}" width="${f(ww)}" height="${f(hh)}" fill="${c}" opacity="${(0.12 + R() * 0.5).toFixed(2)}"/>`;
  }
  let bands = "";
  for (let k = 0; k < 9; k++) {
    const y = cy - h / 2 + R() * h, bh = 2 + R() * 7, x = cx - w / 2 - 10 + R() * w * 0.4, bw = w * (0.4 + R() * 0.7);
    bands += `<rect x="${f(x)}" y="${f(y)}" width="${f(bw)}" height="${f(bh)}" fill="${R() < 0.5 ? MG : CY}" opacity="${(0.22 + R() * 0.3).toFixed(2)}"/>`;
  }
  let scan = "";
  for (let y = cy - h / 2; y < cy + h / 2; y += 4) scan += `<rect x="${f(cx - w / 2)}" y="${f(y)}" width="${f(w)}" height="1.5" fill="#05030f" opacity="0.4"/>`;
  return `<defs>
    <clipPath id="${id}c"><polygon points="${poly()}"/></clipPath>
    <radialGradient id="${id}g" cx="0.5" cy="0.5" r="0.6"><stop offset="0" stop-color="#ffffff" stop-opacity="0.9"/><stop offset="0.18" stop-color="#d9b8ff"/><stop offset="0.5" stop-color="#5a2aa8"/><stop offset="1" stop-color="#12062a"/></radialGradient>
  </defs>
  <ellipse cx="${cx}" cy="${cy}" rx="${w * 1.1}" ry="${h * 0.62}" fill="#b07cff" opacity="${(0.28 * haze).toFixed(2)}" filter="url(#bl24)"/>
  <ellipse cx="${cx}" cy="${cy}" rx="${w * 0.7}" ry="${h * 0.5}" fill="${MG}" opacity="${(0.18 * haze).toFixed(2)}" filter="url(#bl16)"/>
  <polygon points="${poly()}" fill="url(#${id}g)"/>
  <g clip-path="url(#${id}c)">${noise}${bands}${scan}
    <ellipse cx="${cx}" cy="${cy}" rx="${w * 0.22}" ry="${h * 0.3}" fill="#ffffff" opacity="0.5" filter="url(#bl12)"/></g>
  <polygon points="${poly(-3, 0)}" fill="none" stroke="${MG}" stroke-width="3" stroke-linejoin="round" opacity="0.9"/>
  <polygon points="${poly(3, 0)}" fill="none" stroke="${CY}" stroke-width="3" stroke-linejoin="round" opacity="0.9"/>
  <polygon points="${poly()}" fill="none" stroke="#ffffff" stroke-width="1.6" stroke-linejoin="round" opacity="0.85"/>`;
}

// The nine family shards on a tilted ring round (cx, cy), with pixel bits.
export function shards(cx, cy, rx, ry, seed = 5, size = 1) {
  const R = rng(seed);
  const cols = Object.values(FAM);
  let out = "";
  cols.forEach((c, k) => {
    const a = (k / cols.length) * Math.PI * 2 + 0.4;
    const x = cx + Math.cos(a) * rx, y = cy + Math.sin(a) * ry;
    const s = (9 + R() * 6) * size * (0.75 + 0.35 * (Math.sin(a) + 1) / 2);
    const rot = R() * 60 - 30;
    out += `<g transform="translate(${f(x)} ${f(y)}) rotate(${f(rot)})">
      <ellipse cx="0" cy="0" rx="${f(s * 1.8)}" ry="${f(s * 1.8)}" fill="${c}" opacity="0.3" filter="url(#bl6)"/>
      <polygon points="0,${f(-s * 1.3)} ${f(s * 0.7)},0 0,${f(s * 1.3)} ${f(-s * 0.7)},0" fill="${c}" stroke="#14102e" stroke-width="${f(1.5 * size)}"/>
      <polygon points="0,${f(-s * 1.3)} ${f(s * 0.7)},0 0,0" fill="#ffffff" opacity="0.45"/></g>`;
  });
  for (let k = 0; k < 18; k++) {
    const x = cx + (R() - 0.5) * rx * 2.4, y = cy + (R() - 0.5) * ry * 3.2, s = (2 + R() * 4) * size;
    out += `<rect x="${f(x)}" y="${f(y)}" width="${f(s)}" height="${f(s)}" fill="${R() < 0.5 ? MG : CY}" opacity="${(0.4 + R() * 0.5).toFixed(2)}"/>`;
  }
  return out;
}

// The Rift Key at (cx, cy), tilted, s = scale (1 is about 90px long).
export function key(cx, cy, s = 1, rot = -40) {
  const brass = "#e0a93a", dark = "#8a5a14", lit = "#ffe08a";
  return `<g transform="translate(${f(cx)} ${f(cy)}) rotate(${rot}) scale(${s})">
    <ellipse cx="0" cy="-18" rx="40" ry="40" fill="${CY}" opacity="0.28" filter="url(#bl12)"/>
    <rect x="-5" y="0" width="10" height="56" rx="3" fill="${brass}" stroke="${dark}" stroke-width="2.5"/>
    <rect x="-3" y="2" width="3" height="52" fill="${lit}" opacity="0.7"/>
    <path d="M 5 36 h 13 v 7 h -13 Z M 5 47 h 9 v 7 h -9 Z" fill="${brass}" stroke="${dark}" stroke-width="2.5" stroke-linejoin="round"/>
    <circle cx="0" cy="-18" r="22" fill="${brass}" stroke="${dark}" stroke-width="3"/>
    <circle cx="0" cy="-18" r="15" fill="#2a1450" stroke="${dark}" stroke-width="2"/>
    <polygon points="0,-31 11,-18 0,-5" fill="${CY}"/>
    <polygon points="0,-31 -11,-18 0,-5" fill="${MG}"/>
    <polygon points="0,-31 11,-18 0,-18" fill="#ffffff" opacity="0.45"/>
    <path d="M -15 -28 A 18 18 0 0 1 4 -38" fill="none" stroke="${lit}" stroke-width="3" stroke-linecap="round" opacity="0.8"/>
    <circle cx="-4" cy="-24" r="2.4" fill="#ffffff"/>
  </g>`;
}

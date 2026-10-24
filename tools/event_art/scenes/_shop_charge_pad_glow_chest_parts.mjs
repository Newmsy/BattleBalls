// Shared pieces for the shop, charge_pad, glow_chest and buttons_icon scenes:
// the Buttons coin, boon badges, sparkles, string lights and small face bits.
import { shade, INK } from "../../brand/parts.mjs";

let uid = 0;
const id = (p) => `${p}${uid++}`;

export const svg = (body) =>
  `<svg xmlns="http://www.w3.org/2000/svg" width="720" height="440" viewBox="0 0 720 440">${body}</svg>`;

// Deterministic pseudo-random numbers so renders are repeatable.
export function rng(seed) {
  let s = seed >>> 0;
  return () => ((s = (s * 1664525 + 1013904223) >>> 0) / 4294967296);
}

// Shared blur filters: url(#bl2) .. url(#bl40).
export const blurs = () =>
  `<defs>${[1, 2, 3, 4, 6, 8, 12, 16, 24, 32, 40]
    .map((s) => `<filter id="bl${s}" x="-100%" y="-100%" width="300%" height="300%"><feGaussianBlur stdDeviation="${s}"/></filter>`)
    .join("")}</defs>`;

export const RARITY = { common: "#3EE6FF", rare: "#B88CFF", epic: "#FF8AD0" };

// A Buttons coin: round sewing button, cream/gold face, teal rim, 4 holes.
// rot rotates it, sy < 1 squashes it (tilted away from the viewer).
export function coin(cx, cy, r, { rot = 0, sy = 1, glow = true, shadow = true } = {}) {
  const g = id("cn");
  const holes = [
    [-1, -1],
    [1, -1],
    [-1, 1],
    [1, 1],
  ]
    .map(([a, b]) => {
      const hx = cx + a * r * 0.2, hy = cy + b * r * 0.2;
      return `<circle cx="${hx}" cy="${hy}" r="${r * 0.095}" fill="#4a2c14"/>
        <path d="M ${hx - r * 0.07} ${hy + r * 0.03} A ${r * 0.08} ${r * 0.08} 0 0 0 ${hx + r * 0.07} ${hy + r * 0.03}" fill="none" stroke="#fff2c2" stroke-width="${r * 0.025}" opacity="0.7"/>
        <circle cx="${hx}" cy="${hy - r * 0.02}" r="${r * 0.06}" fill="#2a170a"/>`;
    })
    .join("");
  return `
  <defs>
    <radialGradient id="${g}r" cx="0.35" cy="0.3" r="0.85"><stop offset="0" stop-color="#7ff5ea"/><stop offset="0.5" stop-color="#22b8b0"/><stop offset="1" stop-color="#0b5a62"/></radialGradient>
    <radialGradient id="${g}f" cx="0.36" cy="0.3" r="0.85"><stop offset="0" stop-color="#fff8dc"/><stop offset="0.45" stop-color="#f6d88a"/><stop offset="1" stop-color="#c38a3c"/></radialGradient>
    <radialGradient id="${g}d" cx="0.62" cy="0.7" r="0.8"><stop offset="0" stop-color="#ffefb8"/><stop offset="0.6" stop-color="#e9bf68"/><stop offset="1" stop-color="#b57d33"/></radialGradient>
  </defs>
  <g transform="translate(${cx} ${cy}) rotate(${rot}) scale(1 ${sy}) translate(${-cx} ${-cy})">
    ${glow ? `<circle cx="${cx}" cy="${cy}" r="${r * 1.25}" fill="#ffd98a" opacity="0.28" filter="url(#bl${r > 60 ? 24 : r > 20 ? 8 : 3})"/>` : ""}
    ${shadow ? `<circle cx="${cx + r * 0.06}" cy="${cy + r * 0.12}" r="${r}" fill="#000" opacity="0.35"/>` : ""}
    <circle cx="${cx}" cy="${cy}" r="${r}" fill="url(#${g}r)" stroke="#073a40" stroke-width="${r * 0.05}"/>
    <circle cx="${cx}" cy="${cy}" r="${r * 0.82}" fill="url(#${g}f)" stroke="#8a5a22" stroke-width="${r * 0.03}"/>
    <circle cx="${cx}" cy="${cy}" r="${r * 0.6}" fill="url(#${g}d)"/>
    <circle cx="${cx}" cy="${cy}" r="${r * 0.6}" fill="none" stroke="#9a6526" stroke-width="${r * 0.035}" opacity="0.8"/>
    <path d="M ${cx - r * 0.55} ${cy + r * 0.24} A ${r * 0.6} ${r * 0.6} 0 0 0 ${cx + r * 0.24} ${cy + r * 0.55}" fill="none" stroke="#fff6d0" stroke-width="${r * 0.04}" opacity="0.8"/>
    ${holes}
    <path d="M ${cx - r * 0.78} ${cy - r * 0.2} A ${r * 0.8} ${r * 0.8} 0 0 1 ${cx - r * 0.2} ${cy - r * 0.78}" fill="none" stroke="#fff" stroke-width="${r * 0.07}" stroke-linecap="round" opacity="0.6"/>
    <path d="M ${cx - r * 0.93} ${cy + r * 0.05} A ${r * 0.94} ${r * 0.94} 0 0 1 ${cx - r * 0.45} ${cy - r * 0.82}" fill="none" stroke="#c8fff9" stroke-width="${r * 0.05}" stroke-linecap="round" opacity="0.7"/>
  </g>`;
}

// A boon badge: a faceted glowing diamond with a star at its heart.
export function badge(cx, cy, s, col, { rot = 0, glow = 1, stand = false } = {}) {
  const g = id("bd");
  const p = (k) => `${cx},${cy - s * k} ${cx + s * 0.8 * k},${cy} ${cx},${cy + s * k} ${cx - s * 0.8 * k},${cy}`;
  const st = (r) => {
    let pts = "";
    for (let k = 0; k < 8; k++) {
      const a = (k * Math.PI) / 4 - Math.PI / 2;
      const rr = k % 2 ? r * 0.32 : r;
      pts += `${cx + Math.cos(a) * rr},${cy + Math.sin(a) * rr} `;
    }
    return pts;
  };
  return `
  <defs>
    <linearGradient id="${g}" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="${shade(col, 0.6)}"/><stop offset="0.5" stop-color="${col}"/><stop offset="1" stop-color="${shade(col, -0.45)}"/></linearGradient>
  </defs>
  <g transform="rotate(${rot} ${cx} ${cy})">
    ${stand ? `<path d="M ${cx - s * 0.45} ${cy + s * 1.18} L ${cx + s * 0.45} ${cy + s * 1.18} L ${cx + s * 0.2} ${cy + s * 0.75} L ${cx - s * 0.2} ${cy + s * 0.75} Z" fill="#3a2a4a" stroke="#1a1230" stroke-width="${s * 0.06}"/>` : ""}
    ${glow ? `<polygon points="${p(1.25)}" fill="${col}" opacity="${0.55 * glow}" filter="url(#bl${s > 30 ? 12 : s > 14 ? 6 : 3})"/>` : ""}
    <polygon points="${p(1)}" fill="url(#${g})" stroke="${shade(col, -0.65)}" stroke-width="${s * 0.09}" stroke-linejoin="round"/>
    <polygon points="${cx},${cy - s} ${cx - s * 0.8},${cy} ${cx - s * 0.4},${cy} ${cx},${cy - s * 0.5}" fill="#fff" opacity="0.35"/>
    <polygon points="${cx},${cy + s} ${cx + s * 0.8},${cy} ${cx + s * 0.4},${cy} ${cx},${cy + s * 0.5}" fill="#000" opacity="0.18"/>
    <polygon points="${p(0.62)}" fill="none" stroke="#fff" stroke-width="${s * 0.05}" opacity="0.55"/>
    <polygon points="${st(s * 0.38)}" fill="#fff" stroke="${shade(col, 0.4)}" stroke-width="${s * 0.03}"/>
  </g>`;
}

// Four-point twinkle.
export function sparkle(cx, cy, r, col = "#fff", o = 1) {
  const q = r * 0.18;
  return `<g opacity="${o}"><circle cx="${cx}" cy="${cy}" r="${r * 0.7}" fill="${col}" opacity="0.35" filter="url(#bl${r > 10 ? 4 : 2})"/>
    <path d="M ${cx} ${cy - r} Q ${cx + q} ${cy - q} ${cx + r} ${cy} Q ${cx + q} ${cy + q} ${cx} ${cy + r} Q ${cx - q} ${cy + q} ${cx - r} ${cy} Q ${cx - q} ${cy - q} ${cx} ${cy - r} Z" fill="${col}"/></g>`;
}

// A starry sky scatter inside a box.
export function stars(seed, n, x0, y0, x1, y1, col = "#dcd6ff") {
  const r = rng(seed);
  let out = "";
  for (let k = 0; k < n; k++) {
    const x = x0 + r() * (x1 - x0), y = y0 + r() * (y1 - y0), s = 0.6 + r() * 1.4;
    out += `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="${s.toFixed(2)}" fill="${col}" opacity="${(0.3 + r() * 0.6).toFixed(2)}"/>`;
  }
  return out;
}

// A sagging strand of party bulbs from (x0,y0) to (x1,y1).
export function stringLights(x0, y0, x1, y1, sag, n, cols, size = 6) {
  const mx = (x0 + x1) / 2, my = (y0 + y1) / 2 + sag * 2;
  const pt = (t) => [
    (1 - t) * (1 - t) * x0 + 2 * (1 - t) * t * mx + t * t * x1,
    (1 - t) * (1 - t) * y0 + 2 * (1 - t) * t * my + t * t * y1,
  ];
  let glow = "", bulbs = "";
  for (let k = 1; k < n; k++) {
    const [x, y] = pt(k / n);
    const c = cols[k % cols.length];
    glow += `<circle cx="${x}" cy="${y + size}" r="${size * 2.6}" fill="${c}" opacity="0.45"/>`;
    bulbs += `<rect x="${x - size * 0.4}" y="${y}" width="${size * 0.8}" height="${size * 0.7}" fill="#2a2440"/>
      <ellipse cx="${x}" cy="${y + size * 1.4}" rx="${size * 0.7}" ry="${size}" fill="${c}"/>
      <ellipse cx="${x - size * 0.2}" cy="${y + size * 1.1}" rx="${size * 0.25}" ry="${size * 0.4}" fill="#fff" opacity="0.8"/>`;
  }
  return `<path d="M ${x0} ${y0} Q ${mx} ${my} ${x1} ${y1}" fill="none" stroke="#0a0818" stroke-width="2"/>
    <g filter="url(#bl${size > 5 ? 8 : 4})">${glow}</g>${bulbs}`;
}

// Face bits.
export const smile = (cx, cy, w, h, wdt) =>
  `<path d="M ${cx - w} ${cy} Q ${cx} ${cy + h} ${cx + w} ${cy}" fill="none" stroke="${INK}" stroke-width="${wdt}" stroke-linecap="round"/>`;
export const sleepyEye = (cx, cy, w, wdt) =>
  `<path d="M ${cx - w} ${cy} Q ${cx} ${cy + w * 0.8} ${cx + w} ${cy}" fill="none" stroke="${INK}" stroke-width="${wdt}" stroke-linecap="round"/>`;
export const blush = (cx, cy, rx, col = "#ff6f9f", o = 0.5) =>
  `<ellipse cx="${cx}" cy="${cy}" rx="${rx}" ry="${rx * 0.55}" fill="${col}" opacity="${o}" filter="url(#bl2)"/>`;

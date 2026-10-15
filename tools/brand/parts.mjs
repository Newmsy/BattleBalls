// Shared SVG pieces for the Battle Balls brand art (Neon Critters style).
// Everything is drawn here so the icon, splash and store art stay in step.

export const NAVY = "#0b0a1f";
export const VIOLET = "#8f7bff";
export const INK = "#14102e";

// A lighter and darker shade of a #rrggbb colour (t in 0..1).
export function shade(hex, t) {
  const n = parseInt(hex.slice(1), 16);
  const ch = [(n >> 16) & 255, (n >> 8) & 255, n & 255].map((c) =>
    Math.round(t >= 0 ? c + (255 - c) * t : c * (1 + t)),
  );
  return "#" + ch.map((c) => c.toString(16).padStart(2, "0")).join("");
}

let uid = 0;

// Navy arena: soft violet glow, faint grid, glowing rounded border.
export function arena(size, { inset = 72, radius = 170, border = true, grid = true } = {}) {
  const id = `a${uid++}`;
  const step = size / 16;
  let lines = "";
  if (grid) {
    for (let k = 1; k < 16; k++) {
      const p = k * step;
      lines += `<line x1="${p}" y1="0" x2="${p}" y2="${size}"/><line x1="0" y1="${p}" x2="${size}" y2="${p}"/>`;
    }
  }
  const w = size - inset * 2;
  const frame = border
    ? `<rect x="${inset}" y="${inset}" width="${w}" height="${w}" rx="${radius}" fill="none" stroke="${VIOLET}" stroke-width="${size * 0.034}" opacity="0.55" filter="url(#${id}b)"/>
       <rect x="${inset}" y="${inset}" width="${w}" height="${w}" rx="${radius}" fill="none" stroke="#c2b5ff" stroke-width="${size * 0.012}"/>`
    : "";
  return `
  <defs>
    <radialGradient id="${id}g" cx="50%" cy="42%" r="70%">
      <stop offset="0" stop-color="#2c2170"/><stop offset="0.55" stop-color="#141038"/><stop offset="1" stop-color="${NAVY}"/>
    </radialGradient>
    <filter id="${id}b" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="${size * 0.018}"/></filter>
  </defs>
  <rect width="${size}" height="${size}" fill="url(#${id}g)"/>
  <g stroke="${VIOLET}" stroke-opacity="0.07" stroke-width="${size * 0.002}">${lines}</g>
  ${frame}`;
}

// A critter ball like the game's _body(): gradient toward a top-left
// highlight, dark rim, soft drop shadow, optional glow.
export function ball(cx, cy, r, col, { sx = 1, sy = 1, glow = true } = {}) {
  const id = `b${uid++}`;
  return `
  <defs>
    <radialGradient id="${id}g" cx="0.34" cy="0.3" r="0.8">
      <stop offset="0" stop-color="${shade(col, 0.55)}"/><stop offset="0.45" stop-color="${col}"/><stop offset="1" stop-color="${shade(col, -0.35)}"/>
    </radialGradient>
    <filter id="${id}f" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="${r * 0.18}"/></filter>
  </defs>
  ${glow ? `<ellipse cx="${cx}" cy="${cy}" rx="${r * sx * 1.08}" ry="${r * sy * 1.08}" fill="${col}" opacity="0.55" filter="url(#${id}f)"/>` : ""}
  <ellipse cx="${cx + r * 0.08}" cy="${cy + r * 0.14}" rx="${r * sx}" ry="${r * sy}" fill="#000" opacity="0.35"/>
  <ellipse cx="${cx}" cy="${cy}" rx="${r * sx}" ry="${r * sy}" fill="url(#${id}g)" stroke="${shade(col, -0.5)}" stroke-width="${r * 0.06}"/>
  <ellipse cx="${cx - r * 0.38 * sx}" cy="${cy - r * 0.46 * sy}" rx="${r * 0.22}" ry="${r * 0.12}" fill="#fff" opacity="0.45" transform="rotate(-35 ${cx - r * 0.38 * sx} ${cy - r * 0.46 * sy})"/>`;
}

// Big white eye with a pupil looking along (lx, ly) and a catch-light.
export function eye(cx, cy, w, h, lx, ly, pupil) {
  const px = cx + lx * w * 0.42;
  const py = cy + ly * h * 0.42;
  return `
  <ellipse cx="${cx}" cy="${cy}" rx="${w}" ry="${h}" fill="#fff"/>
  <ellipse cx="${px}" cy="${py}" rx="${pupil}" ry="${pupil * 1.12}" fill="${INK}"/>
  <circle cx="${px - pupil * 0.38}" cy="${py - pupil * 0.42}" r="${pupil * 0.36}" fill="#fff"/>`;
}

// Determined brow: thick rounded bar slanting down toward the middle.
export function brow(x1, y1, x2, y2, wdt) {
  return `<line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" stroke="${INK}" stroke-width="${wdt}" stroke-linecap="round"/>`;
}

// Wince: the game's >< eyes.
export function wince(cx, cy, s, side, wdt) {
  return `<polyline points="${cx - side * s} ${cy - s * 0.8} ${cx + side * s * 0.7} ${cy} ${cx - side * s} ${cy + s * 0.8}" fill="none" stroke="${INK}" stroke-width="${wdt}" stroke-linecap="round" stroke-linejoin="round"/>`;
}

// Open grin: dark D shape with a pink tongue and a row of teeth.
export function grin(cx, cy, w, h) {
  const id = `m${uid++}`;
  return `
  <defs><clipPath id="${id}"><path d="M ${cx - w} ${cy} Q ${cx} ${cy + h * 0.12} ${cx + w} ${cy} Q ${cx + w * 0.8} ${cy + h * 1.15} ${cx} ${cy + h * 1.15} Q ${cx - w * 0.8} ${cy + h * 1.15} ${cx - w} ${cy} Z"/></clipPath></defs>
  <g clip-path="url(#${id})">
    <rect x="${cx - w}" y="${cy - h}" width="${w * 2}" height="${h * 3}" fill="${INK}"/>
    <ellipse cx="${cx}" cy="${cy + h * 1.15}" rx="${w * 0.55}" ry="${h * 0.5}" fill="#ff5a7a"/>
    <rect x="${cx - w}" y="${cy - h}" width="${w * 2}" height="${h * 1.25}" fill="#fff"/>
  </g>`;
}

// Yellow impact star with a white core, like the in-game hit burst.
export function burst(cx, cy, r, points = 8, rot = 0) {
  const id = `s${uid++}`;
  let pts = "";
  for (let k = 0; k < points * 2; k++) {
    const a = rot + (k * Math.PI) / points;
    const rr = k % 2 ? r * 0.45 : r;
    pts += `${cx + Math.cos(a) * rr},${cy + Math.sin(a) * rr} `;
  }
  return `
  <defs><filter id="${id}" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="${r * 0.15}"/></filter></defs>
  <circle cx="${cx}" cy="${cy}" r="${r * 0.9}" fill="#fff6b0" opacity="0.6" filter="url(#${id})"/>
  <polygon points="${pts}" fill="#ffd23f" stroke="#fff3a0" stroke-width="${r * 0.05}" stroke-linejoin="round"/>
  <circle cx="${cx}" cy="${cy}" r="${r * 0.3}" fill="#fff"/>`;
}

// Speed streaks trailing behind a moving ball.
export function streaks(list, col, wdt) {
  return list
    .map(([x1, y1, x2, y2, o]) => `<line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" stroke="${col}" stroke-width="${wdt}" stroke-linecap="round" opacity="${o}"/>`)
    .join("");
}

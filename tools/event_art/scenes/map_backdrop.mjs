// Map backdrop: the tall painting behind the Bounce Run map (720x2600), which
// climbs 20 floors from bottom to top. Bottom: a mossy night meadow strewn with
// toybox clutter. Middle: glowing crystal caves and neon ruins. Upper: a neon
// city, then a starry sky with the distant Champion arena-tower at the very top.
// It sits behind node tokens and dashed paths, so it stays dark and quiet: the
// centre ~70% of the width is soft gradient and haze, and the silhouettes with
// detail hug the left and right edges.
import { shade } from "../../brand/parts.mjs";
import { blurs, rng } from "./_shop_charge_pad_glow_chest_parts.mjs";

export const size = [720, 2600];
const W = 720, H = 2600;

const f = (n) => n.toFixed(1);
// Distance from the nearest side edge -> how much detail is allowed there.
const sideX = (r, side, min, max) => (side < 0 ? min + r() * (max - min) : W - (min + r() * (max - min)));

// A soft glow made with a radial gradient (smoother than a big blur filter).
let gid = 0;
function soft(x, y, rx, ry, c, o) {
  const g = `mbS${gid++}`;
  return `<defs><radialGradient id="${g}"><stop offset="0" stop-color="${c}" stop-opacity="${o}"/><stop offset="0.45" stop-color="${c}" stop-opacity="${(o * 0.55).toFixed(3)}"/><stop offset="1" stop-color="${c}" stop-opacity="0"/></radialGradient></defs>
  <ellipse cx="${x}" cy="${y}" rx="${rx}" ry="${ry}" fill="url(#${g})"/>`;
}
// A horizontal haze band whose opacity fades in and out vertically.
function band(y, h, c, o) {
  const g = `mbB${gid++}`;
  return `<defs><linearGradient id="${g}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${c}" stop-opacity="0"/><stop offset="0.5" stop-color="${c}" stop-opacity="${o}"/><stop offset="1" stop-color="${c}" stop-opacity="0"/></linearGradient></defs>
  <rect x="0" y="${y - h / 2}" width="${W}" height="${h}" fill="url(#${g})"/>`;
}

// ---------------------------------------------------------------- sky + glows
function base() {
  return `
  <defs>
    <linearGradient id="mbBase" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#0a0920"/>
      <stop offset="0.07" stop-color="#120d34"/>
      <stop offset="0.17" stop-color="#140f3a"/>
      <stop offset="0.3" stop-color="#110f33"/>
      <stop offset="0.42" stop-color="#0e0f2e"/>
      <stop offset="0.52" stop-color="#0b1230"/>
      <stop offset="0.64" stop-color="#0c112c"/>
      <stop offset="0.74" stop-color="#0c1428"/>
      <stop offset="0.86" stop-color="#0d1a28"/>
      <stop offset="1" stop-color="#0a1820"/>
    </linearGradient>
  </defs>
  <rect width="${W}" height="${H}" fill="url(#mbBase)"/>`;
}

// Big soft colour washes that tint each zone and blend them into one another.
function washes() {
  const list = [
    // sky: violet nebula around the tower, a pink drift
    [360, 170, 380, 230, "#5a3aa8", 0.32],
    [150, 360, 260, 160, "#7a3a9a", 0.14],
    [600, 470, 240, 150, "#3a3a9a", 0.16],
    // city: magenta + cyan neon haze on the sides
    [40, 780, 200, 320, "#a0307a", 0.13],
    [690, 900, 200, 320, "#2a7ab0", 0.13],
    [360, 1080, 420, 110, "#4a2a80", 0.14],
    // caves: teal and purple crystal light pooling from the walls
    [30, 1380, 220, 300, "#1a8a9a", 0.15],
    [700, 1560, 220, 300, "#6a3ab0", 0.15],
    [40, 1760, 200, 220, "#5a3ab0", 0.12],
    [690, 1300, 160, 200, "#2a9aa0", 0.1],
    // meadow: green hush near the ground
    [360, 2420, 460, 200, "#1f6a4a", 0.16],
    [80, 2200, 220, 200, "#2a7a5a", 0.12],
    [650, 2120, 220, 200, "#2a6a7a", 0.1],
  ];
  return list.map(([x, y, rx, ry, c, o]) => soft(x, y, rx * 1.5, ry * 1.5, c, o * 1.6)).join("");
}

function starfield() {
  const r = rng(91);
  let out = "";
  for (let k = 0; k < 420; k++) {
    const y = Math.pow(r(), 1.7) * 1250; // densest at the top
    const x = r() * W;
    const s = r();
    const fade = Math.max(0, 1 - y / 1250);
    const centre = Math.abs(x - W / 2) < W * 0.35 ? 0.7 : 1;
    const o = (0.12 + s * 0.5) * fade * centre;
    if (o < 0.04) continue;
    const col = s > 0.9 ? "#ffe9c4" : s > 0.75 ? "#cfe0ff" : "#e4ddff";
    out += `<circle cx="${f(x)}" cy="${f(y)}" r="${(0.5 + s * s * 1.5).toFixed(2)}" fill="${col}" opacity="${o.toFixed(2)}"/>`;
  }
  // A few soft twinkles near the edges.
  const tw = [[60, 120, 7], [668, 260, 6], [110, 520, 5], [640, 640, 5], [34, 300, 4], [700, 90, 4]];
  for (const [x, y, s] of tw)
    out += `<circle cx="${x}" cy="${y}" r="${s * 1.6}" fill="#cbbcff" opacity="0.18" filter="url(#bl4)"/>
      <path d="M ${x} ${y - s} Q ${x} ${y} ${x + s} ${y} Q ${x} ${y} ${x} ${y + s} Q ${x} ${y} ${x - s} ${y} Q ${x} ${y} ${x} ${y - s} Z" fill="#e8e0ff" opacity="0.55"/>`;
  return out;
}

// A wispy milky band of nebula across the top.
function nebula() {
  return `<g transform="rotate(-14 360 380)">${soft(360, 380, 520, 60, "#3b2a7a", 0.35)}${soft(250, 390, 200, 34, "#5a3a8a", 0.2)}</g>
  <g transform="rotate(8 420 170)">${soft(420, 170, 480, 44, "#4a2a7a", 0.22)}</g>`;
}

// ------------------------------------------------------------ champion tower
function tower() {
  const cx = 360, by = 340; // base of the mesa
  // Spotlight beams fanning up out of the arena.
  let beams = "";
  for (const [a, w, o] of [[-0.55, 0.05, 0.5], [-0.22, 0.04, 0.6], [0.18, 0.04, 0.6], [0.5, 0.05, 0.5]]) {
    const L = 420, ox = cx + a * 60, oy = by - 70;
    const ang = -Math.PI / 2 + a;
    const p1 = [ox + Math.cos(ang - w) * L, oy + Math.sin(ang - w) * L];
    const p2 = [ox + Math.cos(ang + w) * L, oy + Math.sin(ang + w) * L];
    beams += `<polygon points="${ox},${oy} ${p1.map(f)} ${p2.map(f)}" fill="url(#mbBeam)" opacity="${o * 0.6}"/>`;
  }
  // Arena bowl: a wide tiered drum on a rocky mesa, with a spire rising out of it.
  let arches = "";
  for (let k = 0; k < 9; k++) {
    const x = cx - 84 + k * 21;
    arches += `<path d="M ${x - 6} ${by - 48} L ${x - 6} ${by - 60} Q ${x} ${by - 68} ${x + 6} ${by - 60} L ${x + 6} ${by - 48} Z" fill="#ffb877" opacity="${0.35 + (k % 3) * 0.12}"/>`;
  }
  let lights = "";
  for (let k = 0; k < 13; k++) {
    const x = cx - 96 + k * 16;
    lights += `<circle cx="${x}" cy="${by - 83 + Math.abs(k - 6) * 0.6}" r="1.8" fill="#ffe2b0" opacity="0.8"/>`;
  }
  return `
  <defs>
    <linearGradient id="mbBeam" gradientUnits="userSpaceOnUse" x1="0" y1="${by - 70}" x2="0" y2="${by - 470}">
      <stop offset="0" stop-color="#ffcf9a" stop-opacity="0.35"/><stop offset="1" stop-color="#ff9ad0" stop-opacity="0"/>
    </linearGradient>
    <radialGradient id="mbMesa" cx="0.5" cy="0" r="0.75"><stop offset="0" stop-color="#2a2160" stop-opacity="0.9"/><stop offset="0.5" stop-color="#1c1648" stop-opacity="0.5"/><stop offset="1" stop-color="#120f33" stop-opacity="0"/></radialGradient>
    <linearGradient id="mbDrum" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1c1648"/><stop offset="0.45" stop-color="#3a2a78"/><stop offset="1" stop-color="#16123e"/></linearGradient>
    <linearGradient id="mbSpire" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#241c5a"/><stop offset="0.5" stop-color="#4a3690"/><stop offset="1" stop-color="#1a1446"/></linearGradient>
  </defs>
  ${soft(cx, by - 110, 300, 260, "#ff7a9a", 0.16)}
  ${soft(cx, by - 90, 160, 130, "#ffb877", 0.16)}
  <g filter="url(#bl6)">${beams}</g>
  <!-- mesa -->
  <path d="M ${cx - 150} ${by + 30} Q ${cx - 120} ${by - 20} ${cx - 104} ${by - 36} L ${cx + 104} ${by - 36} Q ${cx + 120} ${by - 20} ${cx + 150} ${by + 30} L ${cx + 60} ${by + 70} L ${cx + 20} ${by + 110} L ${cx - 30} ${by + 80} L ${cx - 80} ${by + 64} Z" fill="url(#mbMesa)"/>
  <!-- spire -->
  <path d="M ${cx - 20} ${by - 90} L ${cx - 9} ${by - 238} L ${cx} ${by - 262} L ${cx + 9} ${by - 238} L ${cx + 20} ${by - 90} Z" fill="url(#mbSpire)"/>
  <path d="M ${cx} ${by - 262} L ${cx} ${by - 92}" stroke="#ff9ad0" stroke-width="1.2" opacity="0.45"/>
  <circle cx="${cx}" cy="${by - 266}" r="14" fill="#ffd9a8" opacity="0.5" filter="url(#bl8)"/>
  <circle cx="${cx}" cy="${by - 266}" r="4" fill="#fff1d8" opacity="0.9"/>
  <path d="M ${cx - 32} ${by - 150} L ${cx + 32} ${by - 150} L ${cx + 22} ${by - 140} L ${cx - 22} ${by - 140} Z" fill="#3a2a78"/>
  <path d="M ${cx - 32} ${by - 150} L ${cx + 32} ${by - 150}" stroke="#ff9ad0" stroke-width="1.4" opacity="0.6"/>
  <!-- arena drum -->
  <ellipse cx="${cx}" cy="${by - 84}" rx="104" ry="14" fill="#2c2270"/>
  <path d="M ${cx - 104} ${by - 84} L ${cx - 98} ${by - 36} Q ${cx} ${by - 22} ${cx + 98} ${by - 36} L ${cx + 104} ${by - 84} Q ${cx} ${by - 70} ${cx - 104} ${by - 84} Z" fill="url(#mbDrum)"/>
  ${arches}
  <path d="M ${cx - 104} ${by - 84} Q ${cx} ${by - 70} ${cx + 104} ${by - 84}" fill="none" stroke="#ffb0c8" stroke-width="1.6" opacity="0.55"/>
  ${lights}
  <ellipse cx="${cx}" cy="${by - 86}" rx="80" ry="8" fill="#ffcf9a" opacity="0.35" filter="url(#bl4)"/>
  <!-- banners -->
  <path d="M ${cx - 104} ${by - 84} l 0 -26 l 12 4 l -12 4" fill="#ff5a6e" opacity="0.6"/>
  <path d="M ${cx + 104} ${by - 84} l 0 -26 l -12 4 l 12 4" fill="#ff5a6e" opacity="0.6"/>
  <!-- haze so it reads as far away -->
  <rect x="0" y="${by - 120}" width="${W}" height="200" fill="url(#mbTowerFog)"/>
  <defs><linearGradient id="mbTowerFog" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#140f3a" stop-opacity="0"/><stop offset="0.6" stop-color="#140f3a" stop-opacity="0.5"/><stop offset="1" stop-color="#140f3a" stop-opacity="0"/></linearGradient></defs>`;
}

// ------------------------------------------------------------------ the city
function building(x, top, w, bottom, fill, r, opts = {}) {
  const { windows = 0.25, neon = null, cap = 0 } = opts;
  let out = "";
  if (cap === 1) out += `<path d="M ${x} ${top} L ${x + w / 2} ${top - w * 0.5} L ${x + w} ${top} Z" fill="${fill}"/>`;
  if (cap === 2) out += `<rect x="${x + w * 0.42}" y="${top - 46}" width="${w * 0.16 > 4 ? 4 : w * 0.16}" height="46" fill="${fill}"/>
    <circle cx="${x + w * 0.5}" cy="${top - 48}" r="5" fill="#ff5a6e" opacity="0.35" filter="url(#bl3)"/><circle cx="${x + w * 0.5}" cy="${top - 48}" r="1.8" fill="#ff8a9a"/>`;
  if (cap === 3) out += `<rect x="${x + w * 0.15}" y="${top - 14}" width="${w * 0.7}" height="14" fill="${fill}"/>`;
  out += `<rect x="${f(x)}" y="${f(top)}" width="${f(w)}" height="${f(bottom - top)}" fill="${fill}"/>`;
  // Windows: a sparse grid of dim lit panes.
  const cols = ["#ffd98a", "#7fe6ff", "#ff9ad0", "#c8b8ff"];
  for (let y = top + 12; y < bottom - 10; y += 16) {
    for (let wx = x + 6; wx < x + w - 8; wx += 11) {
      if (r() > windows) continue;
      const o = 0.12 + r() * 0.3;
      out += `<rect x="${f(wx)}" y="${f(y)}" width="5" height="7" fill="${cols[Math.floor(r() * cols.length)]}" opacity="${o.toFixed(2)}"/>`;
    }
  }
  if (neon) {
    const nx = neon.side < 0 ? x + 3 : x + w - 3;
    const ny = top + 20 + r() * 40;
    out += `<line x1="${nx}" y1="${ny}" x2="${nx}" y2="${ny + neon.len}" stroke="${neon.col}" stroke-width="7" opacity="0.35" filter="url(#bl4)"/>
      <line x1="${nx}" y1="${ny}" x2="${nx}" y2="${ny + neon.len}" stroke="${shade(neon.col, 0.4)}" stroke-width="2" opacity="0.8"/>`;
  }
  return out;
}

// A wordless neon sign: a glowing rounded frame with a simple shape inside.
function neonSign(x, y, w, h, col, kind) {
  const inner =
    kind === "ball"
      ? `<circle cx="${x + w / 2}" cy="${y + h / 2}" r="${h * 0.28}" fill="none" stroke="${shade(col, 0.5)}" stroke-width="2"/>`
      : kind === "star"
        ? `<path d="M ${x + w / 2} ${y + h * 0.2} L ${x + w * 0.58} ${y + h * 0.45} L ${x + w * 0.82} ${y + h * 0.5} L ${x + w * 0.58} ${y + h * 0.56} L ${x + w / 2} ${y + h * 0.8} L ${x + w * 0.42} ${y + h * 0.56} L ${x + w * 0.18} ${y + h * 0.5} L ${x + w * 0.42} ${y + h * 0.45} Z" fill="none" stroke="${shade(col, 0.5)}" stroke-width="2" stroke-linejoin="round"/>`
        : `<path d="M ${x + w * 0.2} ${y + h * 0.65} L ${x + w * 0.4} ${y + h * 0.35} L ${x + w * 0.6} ${y + h * 0.65} L ${x + w * 0.8} ${y + h * 0.35}" fill="none" stroke="${shade(col, 0.5)}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>`;
  return `<rect x="${x - 4}" y="${y - 4}" width="${w + 8}" height="${h + 8}" rx="8" fill="${col}" opacity="0.22" filter="url(#bl8)"/>
    <rect x="${x}" y="${y}" width="${w}" height="${h}" rx="6" fill="#0c0a24" stroke="${col}" stroke-width="2.2" opacity="0.9"/>
    <g opacity="0.85">${inner}</g>`;
}

function city() {
  const r = rng(5);
  // Far skyline across the whole width, barely above the sky value.
  let far = "";
  let x = -10;
  while (x < W + 10) {
    const w = 26 + r() * 46;
    const top = 960 + r() * 150 - (Math.abs(x - W / 2) < 200 ? 0 : 40);
    far += building(x, top, w, 1260, "#121036", r, { windows: 0.035, cap: r() > 0.75 ? 2 : r() > 0.6 ? 1 : 0 });
    x += w + r() * 4;
  }
  // Mid layer on the edges.
  let mid = "";
  for (const side of [-1, 1]) {
    let y0 = 0;
    const spec = side < 0
      ? [[-6, 54, 640], [44, 40, 760], [80, 48, 860], [120, 30, 960]]
      : [[W - 50, 56, 600], [W - 96, 44, 720], [W - 134, 40, 840], [W - 164, 30, 950]];
    for (const [bx, w, top] of spec) mid += building(bx, top, w, 1300, "#18163f", r, { windows: 0.08, cap: Math.floor(r() * 4) });
    y0++;
  }
  // Near towers hugging the edges, with neon strips and signs.
  let near = "";
  near += building(-20, 470, 92, 1320, "#0f0d2c", r, { windows: 0.18, cap: 2, neon: { side: 1, col: "#ff4fb8", len: 160 } });
  near += building(66, 720, 50, 1320, "#110f30", r, { windows: 0.14, cap: 1, neon: { side: 1, col: "#3ee6ff", len: 110 } });
  near += building(W - 76, 520, 96, 1320, "#0f0d2c", r, { windows: 0.18, cap: 3, neon: { side: -1, col: "#3ee6ff", len: 180 } });
  near += building(W - 118, 800, 44, 1320, "#110f30", r, { windows: 0.14, cap: 2, neon: { side: -1, col: "#b88cff", len: 90 } });
  near += neonSign(12, 600, 48, 30, "#ff4fb8", "ball");
  near += neonSign(W - 64, 680, 50, 30, "#3ee6ff", "zig");
  near += neonSign(18, 880, 40, 40, "#ffd34e", "star");
  near += neonSign(W - 60, 1000, 44, 28, "#b88cff", "ball");
  // A sky bridge between near towers on each side and drifting blimp lights.
  near += `<rect x="40" y="900" width="70" height="8" fill="#0f0d2c"/><line x1="40" y1="900" x2="110" y2="900" stroke="#3ee6ff" stroke-width="1.2" opacity="0.45"/>`;
  near += `<path d="M 150 560 q 30 -14 60 0 q -30 14 -60 0 Z" fill="#1a1646" opacity="0.8"/><circle cx="208" cy="560" r="2" fill="#ff8a9a" opacity="0.7"/>`;
  return `
  <defs>
    <linearGradient id="mbCityFade" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#0e0f2e" stop-opacity="0"/><stop offset="0.35" stop-color="#0e0f2e" stop-opacity="0.6"/><stop offset="1" stop-color="#0b1230" stop-opacity="1"/>
    </linearGradient>
  </defs>
  <mask id="mbCityMask" maskUnits="userSpaceOnUse" x="0" y="0" width="${W}" height="${H}">
    <rect width="${W}" height="1400" fill="url(#mbCityM)"/>
  </mask>
  <linearGradient id="mbCityM" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="0" y2="1400">
    <stop offset="0.78" stop-color="#fff"/><stop offset="0.9" stop-color="#fff" stop-opacity="0.35"/><stop offset="0.94" stop-color="#fff" stop-opacity="0"/>
  </linearGradient>
  <g mask="url(#mbCityMask)">
    <g opacity="0.9">${far}</g>
    ${mid}
    ${near}
    <rect x="0" y="1000" width="${W}" height="320" fill="url(#mbCityFade)" opacity="0.6"/>
  </g>`;
}

// ------------------------------------------------------------ crystal caves
function crystal(x, y, len, wid, ang, col, o = 1) {
  // A hexagonal prism pointing along ang (degrees, 0 = up).
  const g = `mbC${Math.round(x)}_${Math.round(y)}`;
  return `<defs><linearGradient id="${g}" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="${shade(col, -0.35)}"/><stop offset="0.45" stop-color="${col}"/><stop offset="0.55" stop-color="${shade(col, -0.15)}"/><stop offset="1" stop-color="${shade(col, -0.6)}"/></linearGradient></defs>
  <g transform="translate(${f(x)} ${f(y)}) rotate(${f(ang)})" opacity="${o}">
    <path d="M ${-wid} 0 L ${-wid} ${-len * 0.78} L 0 ${-len} L ${wid} ${-len * 0.78} L ${wid} 0 Z" fill="url(#${g})"/>
    <path d="M 0 ${-len} L 0 0" stroke="${shade(col, 0.5)}" stroke-width="${wid * 0.12}" opacity="0.5"/>
    <path d="M ${-wid} ${-len * 0.78} L 0 ${-len} L ${wid} ${-len * 0.78}" fill="none" stroke="${shade(col, 0.6)}" stroke-width="${Math.max(1, wid * 0.15)}" opacity="0.7"/>
  </g>`;
}

function cluster(x, y, side, scale, col, seed) {
  // Prisms rooted in the wall, fanning inward and upward at varied angles.
  const r = rng(seed);
  let out = soft(x - side * 30 * scale, y - 30 * scale, 120 * scale, 100 * scale, col, 0.32);
  // [degrees from straight up toward the cave's middle, length, width]
  const spec = [[78, 0.7, 0.9], [52, 1.25, 1.2], [28, 0.9, 1], [66, 0.55, 0.75], [10, 0.6, 0.8]];
  spec.forEach(([a, l, w], k) => {
    const ang = -side * (a + (r() - 0.5) * 10);
    const len = (58 + r() * 14) * l * scale;
    const bx = x + side * (k % 2 ? -6 : 6) * scale, by = y + (k - 2) * 5 * scale;
    out += crystal(bx, by, len, 10 * w * scale, ang, k % 2 ? col : shade(col, 0.12), 0.7);
  });
  // A lump of the wall's rock hiding the roots, lit along its top by the crystals.
  const q = (dx, dy) => `${f(x + side * dx * scale)} ${f(y + dy * scale)}`;
  out += `<path d="M ${q(-30, -18)} Q ${q(-4, -16)} ${q(10, -4)} Q ${q(20, 6)} ${q(12, 16)} Q ${q(-6, 28)} ${q(-30, 26)} Z" fill="#090b24"/>
    <path d="M ${q(-26, -17)} Q ${q(-4, -15)} ${q(10, -4)}" fill="none" stroke="${col}" stroke-width="${f(2 * scale)}" opacity="0.35" stroke-linecap="round"/>`;
  // A rock socket the crystals grow out of.
  return out;
}

function wallPts(y0, y1, seed, depth) {
  const r = rng(seed);
  const pts = [];
  for (let y = y0; y <= y1; y += 40 + r() * 30) {
    const t = (y - y0) / (y1 - y0);
    const bulge = Math.sin(t * Math.PI) * depth;
    pts.push([bulge * (0.55 + r() * 0.45), y]);
  }
  pts.push([0, y1]);
  return pts;
}
// How far a wall reaches in from its side at height y.
function wallDepth(pts, y) {
  for (let k = 1; k < pts.length; k++) {
    const [d0, a] = pts[k - 1], [d1, b] = pts[k];
    if (y >= a && y <= b) return d0 + ((d1 - d0) * (y - a)) / (b - a || 1);
  }
  return 0;
}

function wall(side, y0, y1, seed, fill, depth, rim = "#3ee6d8") {
  const pts = wallPts(y0, y1, seed, depth);
  const edge = side < 0 ? 0 : W;
  const P = pts.map(([d, y]) => `${f(side < 0 ? d : W - d)},${f(y)}`).join(" ");
  return `<polygon points="${edge},${y0} ${P} ${edge},${y1}" fill="${fill}"/>
    <polyline points="${P}" fill="none" stroke="${rim}" stroke-width="3" opacity="0.18" stroke-linejoin="round" filter="url(#bl2)"/>`;
}

function caves() {
  const T = "#3ee6d8", P = "#b88cff", B = "#5aa8ff", M = "#ff7ad0";
  let out = "";
  // Back cave walls with a soft rim of crystal light.
  out += `<g filter="url(#bl3)">${wall(-1, 1150, 2020, 7, "#0d1030", 150)}${wall(1, 1180, 2000, 8, "#0d1030", 150)}</g>`;
  out += wall(-1, 1220, 1960, 17, "#090b24", 112, "#3ee6d8") + wall(1, 1240, 1940, 18, "#090b24", 112, "#b88cff");
  // Crystal clusters growing out of the front walls' edges.
  const LW = wallPts(1220, 1960, 17, 112), RW = wallPts(1240, 1940, 18, 112);
  const onWall = (side, y, scale, col, seed) => {
    scale *= 1.3;
    const d = wallDepth(side < 0 ? LW : RW, y) - 4;
    return cluster(side < 0 ? d : W - d, y, side, scale, col, seed);
  };
  out += onWall(-1, 1350, 0.95, T, 1);
  out += onWall(1, 1480, 1.05, P, 2);
  out += onWall(-1, 1630, 0.85, P, 3);
  out += onWall(1, 1730, 0.8, T, 4);
  out += onWall(-1, 1850, 0.75, B, 5);
  out += onWall(1, 1300, 0.7, M, 6);
  // Stalagmite / stalactite fingers along the walls.
  const r = rng(44);
  for (const side of [-1, 1]) {
    for (let k = 0; k < 7; k++) {
      const y = 1280 + k * 95 + r() * 30;
      const d = wallDepth(side < 0 ? LW : RW, y + 10);
      if (d < 20) continue;
      const x = side < 0 ? d : W - d;
      const len = 20 + r() * 30;
      out += `<path d="M ${f(x + side * 12)} ${f(y)} L ${f(x - side * len)} ${f(y + 12 - r() * 16)} L ${f(x + side * 12)} ${f(y + 22)} Z" fill="#090b24"/>`;
    }
  }
  // A few loose glowing shards floating in the open middle, very faint.
  const r2 = rng(12);
  for (let k = 0; k < 14; k++) {
    const x = 120 + r2() * 480, y = 1180 + r2() * 760, s = 2 + r2() * 3;
    const col = [T, P, B][k % 3];
    out += `<circle cx="${f(x)}" cy="${f(y)}" r="${f(s * 3)}" fill="${col}" opacity="0.12" filter="url(#bl4)"/>
      <path d="M ${f(x)} ${f(y - s * 1.6)} L ${f(x + s * 0.7)} ${f(y)} L ${f(x)} ${f(y + s * 1.6)} L ${f(x - s * 0.7)} ${f(y)} Z" fill="${shade(col, 0.3)}" opacity="${(0.25 + r2() * 0.2).toFixed(2)}"/>`;
  }
  return out;
}

// Neon ruins: broken pillars and an arch fragment with glowing glyph bands.
function pillar(x, top, bottom, w, col, broken) {
  const crack = broken ? `L ${x + w} ${top + 10} L ${x + w * 0.6} ${top - 6} L ${x + w * 0.3} ${top + 6} L ${x} ${top - 4}` : `L ${x + w} ${top} L ${x} ${top}`;
  return `
  <path d="M ${x} ${bottom} L ${x + w} ${bottom} ${crack} Z" fill="url(#mbStone)"/>
  <rect x="${x - 5}" y="${bottom - 12}" width="${w + 10}" height="12" rx="2" fill="#1a1a44"/>
  <line x1="${x + w * 0.3}" y1="${top + 22}" x2="${x + w * 0.3}" y2="${bottom - 18}" stroke="#0b0b26" stroke-width="2" opacity="0.6"/>
  <line x1="${x + w * 0.7}" y1="${top + 22}" x2="${x + w * 0.7}" y2="${bottom - 18}" stroke="#0b0b26" stroke-width="2" opacity="0.6"/>
  <rect x="${x - 1}" y="${(top + bottom) / 2 - 5}" width="${w + 2}" height="9" fill="${col}" opacity="0.25" filter="url(#bl4)"/>
  <rect x="${x}" y="${(top + bottom) / 2 - 2}" width="${w}" height="3" fill="${shade(col, 0.3)}" opacity="0.65"/>`;
}

function ruins() {
  const T = "#3ee6ff", P = "#b88cff";
  return `
  <defs><linearGradient id="mbStone" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1a1a46"/><stop offset="0.5" stop-color="#262660"/><stop offset="1" stop-color="#121236"/></linearGradient></defs>
  ${pillar(18, 1160, 1330, 34, T, true)}
  ${pillar(66, 1220, 1330, 26, T, true)}
  ${pillar(W - 52, 1080, 1290, 34, P, true)}
  ${pillar(W - 98, 1180, 1290, 26, P, true)}
  <!-- arch fragment on the right, half swallowed by the cave -->
  <path d="M ${W} 1500 Q ${W - 120} 1490 ${W - 150} 1600 L ${W - 128} 1604 Q ${W - 104} 1516 ${W} 1524 Z" fill="url(#mbStone)" opacity="0.9"/>
  <path d="M ${W} 1512 Q ${W - 112} 1503 ${W - 139} 1602" fill="none" stroke="${T}" stroke-width="2" opacity="0.5"/>
  <!-- fallen block on the left -->
  <rect x="-6" y="1760" width="62" height="34" rx="4" fill="url(#mbStone)" transform="rotate(-8 30 1777)"/>
  <rect x="2" y="1772" width="46" height="3" fill="${P}" opacity="0.5" transform="rotate(-8 30 1777)"/>`;
}

// ---------------------------------------------------------- toybox meadow
function grassBlade(x, y, h, lean, w, fill, op = 1) {
  return `<path d="M ${f(x - w)} ${f(y)} Q ${f(x - w * 0.3 + lean * 0.35)} ${f(y - h * 0.55)} ${f(x + lean)} ${f(y - h)} Q ${f(x + w * 0.5 + lean * 0.4)} ${f(y - h * 0.5)} ${f(x + w)} ${f(y)} Z" fill="${fill}" opacity="${op}"/>`;
}

function tree(x, y, r, c) {
  return `<rect x="${x - r * 0.08}" y="${y}" width="${r * 0.16}" height="${r * 3}" fill="${shade(c, -0.3)}"/>
    <circle cx="${x}" cy="${y}" r="${r}" fill="${c}"/><circle cx="${x - r * 0.45}" cy="${y + r * 0.35}" r="${r * 0.7}" fill="${c}"/><circle cx="${x + r * 0.5}" cy="${y + r * 0.3}" r="${r * 0.65}" fill="${c}"/>
    <circle cx="${x + r * 0.1}" cy="${y + r * 0.6}" r="${r * 0.75}" fill="${c}"/>`;
}

function toyBlock(x, y, s, rot, col) {
  return `<g transform="rotate(${rot} ${x} ${y})">
    <rect x="${x - s / 2 + 3}" y="${y - s / 2 + 5}" width="${s}" height="${s}" rx="${s * 0.14}" fill="#000" opacity="0.35"/>
    <rect x="${x - s / 2}" y="${y - s / 2}" width="${s}" height="${s}" rx="${s * 0.14}" fill="${shade(col, -0.62)}"/>
    <rect x="${x - s * 0.36}" y="${y - s * 0.36}" width="${s * 0.72}" height="${s * 0.72}" rx="${s * 0.1}" fill="none" stroke="${shade(col, -0.35)}" stroke-width="${s * 0.06}"/>
    <circle cx="${x}" cy="${y}" r="${s * 0.16}" fill="${shade(col, -0.3)}"/>
    <path d="M ${x - s / 2 + 4} ${y - s / 2 + 2} L ${x + s / 2 - 4} ${y - s / 2 + 2}" stroke="${shade(col, -0.1)}" stroke-width="2" opacity="0.6" stroke-linecap="round"/>
  </g>`;
}

function bouncyBall(x, y, r) {
  return `<defs>
    <radialGradient id="mbBB" cx="0.35" cy="0.3" r="0.8"><stop offset="0" stop-color="#4a3a8a"/><stop offset="1" stop-color="#1a1440"/></radialGradient>
    <clipPath id="mbBBc"><circle cx="${x}" cy="${y}" r="${r}"/></clipPath>
  </defs>
  <circle cx="${x}" cy="${y}" r="${r * 1.2}" fill="#ff4fb8" opacity="0.1" filter="url(#bl16)"/>
  <circle cx="${x}" cy="${y}" r="${r}" fill="url(#mbBB)"/>
  <g clip-path="url(#mbBBc)">
    <path d="M ${x - r} ${y - r * 0.2} Q ${x} ${y - r * 0.6} ${x + r} ${y - r * 0.1} L ${x + r} ${y + r * 0.15} Q ${x} ${y - r * 0.3} ${x - r} ${y + r * 0.1} Z" fill="#7a2a6a" opacity="0.7"/>
    <path d="M ${x - r} ${y + r * 0.45} Q ${x} ${y + r * 0.1} ${x + r} ${y + r * 0.55} L ${x + r} ${y + r * 0.8} Q ${x} ${y + r * 0.35} ${x - r} ${y + r * 0.7} Z" fill="#1f6a7a" opacity="0.7"/>
  </g>
  <ellipse cx="${x - r * 0.38}" cy="${y - r * 0.45}" rx="${r * 0.22}" ry="${r * 0.1}" fill="#fff" opacity="0.18" transform="rotate(-35 ${x - r * 0.38} ${y - r * 0.45})"/>`;
}

function mushroom(x, y, s, col) {
  return `<circle cx="${x}" cy="${y - s}" r="${s * 2.4}" fill="${col}" opacity="0.18" filter="url(#bl6)"/>
    <rect x="${x - s * 0.22}" y="${y - s}" width="${s * 0.44}" height="${s}" rx="${s * 0.2}" fill="#bfc6e6" opacity="0.55"/>
    <path d="M ${x - s} ${y - s * 0.9} Q ${x} ${y - s * 2.1} ${x + s} ${y - s * 0.9} Z" fill="${col}" opacity="0.75"/>
    <circle cx="${x - s * 0.3}" cy="${y - s * 1.3}" r="${s * 0.14}" fill="#fff" opacity="0.6"/>`;
}

function meadow() {
  const r = rng(301);
  let out = "";
  // Edge trees fading into the cave mouth above.
  out += tree(-20, 2030, 110, "#08101e") + tree(740, 2010, 115, "#08101e");
  out += tree(64, 2120, 78, "#09131f") + tree(664, 2150, 84, "#09131f");
  // Rolling hills: far ones barely visible across the width, nearer ones lower.
  out += `<path d="M 0 2150 Q 120 2090 240 2120 Q 360 2080 480 2115 Q 600 2075 720 2110 L 720 2600 L 0 2600 Z" fill="#0f1c2e" opacity="0.8"/>`;
  out += `<path d="M 0 2290 Q 150 2240 300 2270 Q 450 2235 600 2265 Q 670 2250 720 2260 L 720 2600 L 0 2600 Z" fill="#0d1d2a"/>`;
  out += `<path d="M 0 2440 Q 180 2400 360 2425 Q 540 2395 720 2420 L 720 2600 L 0 2600 Z" fill="#0b1a24"/>`;
  // Toybox clutter on the edges.
  out += toyBlock(40, 2238, 54, -8, "#ffd34e") + toyBlock(96, 2250, 46, 6, "#3ee6ff") + toyBlock(62, 2190, 44, 12, "#ff4fb8");
  out += bouncyBall(650, 2228, 52);
  // A coiled spring on the right.
  let coil = "";
  for (let k = 0; k < 6; k++) coil += `<ellipse cx="598" cy="${2268 - k * 9}" rx="15" ry="5" fill="none" stroke="#3a4a7a" stroke-width="3" opacity="0.8"/>`;
  out += coil + `<ellipse cx="598" cy="2214" rx="18" ry="6" fill="#2a2a5a"/>`;
  // Grass tufts: dense on the edges, sparse and short in the middle.
  let grass = "";
  for (let k = 0; k < 120; k++) {
    const x = r() * W;
    const edge = Math.min(x, W - x) / (W / 2); // 0 at edges, 1 at centre
    const yb = k % 3 === 0 ? 2300 : k % 3 === 1 ? 2440 : 2600;
    const h = (20 + r() * 50) * (1.2 - edge * 0.85);
    grass += grassBlade(x, yb + 4, h, (r() - 0.5) * 24, 3 + r() * 3, k % 4 ? "#122a30" : "#163636", 0.85);
  }
  out += grass;
  // A few glowing blades and mushrooms along the edges.
  let glow = "";
  for (let k = 0; k < 16; k++) {
    const side = k % 2 ? 1 : -1;
    const x = side < 0 ? 10 + r() * 110 : W - 10 - r() * 110;
    const yb = [2300, 2440, 2600][k % 3];
    glow += grassBlade(x, yb, 30 + r() * 40, side * (4 + r() * 12), 2.4, "url(#mbBlade)", 0.65);
  }
  out += `<defs><linearGradient id="mbBlade" x1="0" y1="1" x2="0" y2="0"><stop offset="0" stop-color="#1a4a3a"/><stop offset="1" stop-color="#5cff9a" stop-opacity="0.7"/></linearGradient></defs>` + glow;
  out += mushroom(130, 2302, 10, "#5aa8ff") + mushroom(150, 2300, 6, "#b88cff") + mushroom(560, 2442, 9, "#b88cff") + mushroom(690, 2300, 7, "#5cff9a") + mushroom(28, 2444, 8, "#ff7ad0");
  // Fireflies drifting up through the meadow and into the caves.
  let flies = "";
  for (let k = 0; k < 26; k++) {
    const side = r() < 0.5 ? -1 : 1;
    const x = r() < 0.7 ? sideX(r, side, 10, 150) : 150 + r() * 420;
    const y = 1900 + r() * 680;
    const s = 1.4 + r() * 1.4;
    flies += `<circle cx="${f(x)}" cy="${f(y)}" r="${f(s * 4)}" fill="#5cff9a" opacity="0.18" filter="url(#bl4)"/><circle cx="${f(x)}" cy="${f(y)}" r="${f(s * 0.7)}" fill="#d8ffe6" opacity="0.7"/>`;
  }
  return out + flies;
}

// ----------------------------------------------------------- mist + finish
function mist() {
  // Soft horizontal haze bands at the zone joins so nothing reads as a seam.
  const bands = [[440, 200, "#140f38", 0.45], [1120, 260, "#100f30", 0.55], [1960, 300, "#0d1828", 0.6], [2090, 160, "#0e1a2c", 0.35]];
  return bands.map(([y, h, c, o]) => band(y, h, c, o)).join("");
}

function centreCalm() {
  // Darken and flatten the central lane where nodes and paths sit.
  return `
  <defs><linearGradient id="mbLane" x1="0" y1="0" x2="1" y2="0">
    <stop offset="0" stop-color="#0b0c24" stop-opacity="0"/>
    <stop offset="0.2" stop-color="#0b0c24" stop-opacity="0.18"/>
    <stop offset="0.5" stop-color="#0b0c24" stop-opacity="0.28"/>
    <stop offset="0.8" stop-color="#0b0c24" stop-opacity="0.18"/>
    <stop offset="1" stop-color="#0b0c24" stop-opacity="0"/>
  </linearGradient>
  <linearGradient id="mbEnds" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#07071a" stop-opacity="0.6"/><stop offset="0.03" stop-color="#07071a" stop-opacity="0"/>
    <stop offset="0.97" stop-color="#06100f" stop-opacity="0"/><stop offset="1" stop-color="#06100f" stop-opacity="0.5"/>
  </linearGradient></defs>
  <rect x="0" y="0" width="${W}" height="${H}" fill="url(#mbLane)"/>
  <rect width="${W}" height="${H}" fill="url(#mbEnds)"/>`;
}

export default () =>
  `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${blurs()}
  ${base()}
  ${washes()}
  ${nebula()}
  ${starfield()}
  ${tower()}
  ${city()}
  ${caves()}
  ${ruins()}
  ${meadow()}
  ${mist()}
  ${centreCalm()}
  </svg>`;

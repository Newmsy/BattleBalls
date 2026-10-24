// Map backdrop: the tall painting behind the Bounce Run map (720x4000, the same
// ~1:5.6 shape the map scrolls through in game, so nothing is stretched), which
// climbs 20 floors from bottom to top. Bottom: a mossy night meadow strewn with
// toybox clutter. Middle: glowing crystal caves and neon ruins. Upper: a neon
// city, then a starry sky with the distant Champion arena-tower at the very top.
// It sits behind node tokens and dashed paths, so it stays dark and quiet: the
// centre ~70% of the width is soft gradient and haze, and the silhouettes with
// detail hug the left and right edges (about 0-130 px and 590-720 px).
//
// Zones, top to bottom (y): sky + tower 0-800, neon city 760-2080, ruins
// 1750-2100 (and scattered through the caves), crystal caves 1820-3180, meadow
// 3060-4000. Each zone has its own props at natural proportions; the extra
// height is filled with more of them, never by stretching.
import { shade } from "../../brand/parts.mjs";
import { blurs, rng } from "./_shop_charge_pad_glow_chest_parts.mjs";

export const size = [720, 4000];
const W = 720, H = 4000;

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
      <stop offset="0.43" stop-color="#0e0f2e"/>
      <stop offset="0.53" stop-color="#0b1230"/>
      <stop offset="0.65" stop-color="#0c112c"/>
      <stop offset="0.75" stop-color="#0c1428"/>
      <stop offset="0.86" stop-color="#0d1a28"/>
      <stop offset="1" stop-color="#0a1820"/>
    </linearGradient>
  </defs>
  <rect width="${W}" height="${H}" fill="url(#mbBase)"/>`;
}

// Big soft colour washes that tint each zone and blend them into one another.
function washes() {
  const list = [
    // sky: violet nebula around the tower, pink and blue drifts lower down
    [360, 240, 380, 250, "#5a3aa8", 0.32],
    [150, 540, 260, 170, "#7a3a9a", 0.14],
    [600, 720, 240, 170, "#3a3a9a", 0.16],
    // city: magenta + cyan neon haze on the sides, alternating down the towers
    [40, 1120, 200, 340, "#a0307a", 0.13],
    [690, 1320, 200, 340, "#2a7ab0", 0.13],
    [40, 1640, 180, 260, "#6a3ab0", 0.1],
    [690, 1820, 180, 240, "#a0307a", 0.08],
    [360, 1920, 420, 130, "#4a2a80", 0.14],
    // caves: teal and purple crystal light pooling from the walls
    [30, 2180, 220, 300, "#1a8a9a", 0.15],
    [700, 2440, 220, 300, "#6a3ab0", 0.15],
    [40, 2720, 200, 240, "#5a3ab0", 0.12],
    [690, 2050, 160, 220, "#2a9aa0", 0.1],
    [690, 2900, 180, 240, "#2a9aa0", 0.1],
    [30, 3000, 180, 200, "#1a8a9a", 0.08],
    // meadow: green hush near the ground
    [360, 3760, 460, 240, "#1f6a4a", 0.16],
    [80, 3340, 220, 220, "#2a7a5a", 0.12],
    [650, 3240, 220, 220, "#2a6a7a", 0.1],
    [650, 3780, 200, 200, "#2a7a5a", 0.08],
  ];
  return list.map(([x, y, rx, ry, c, o]) => soft(x, y, rx * 1.5, ry * 1.5, c, o * 1.6)).join("");
}

function starfield() {
  const r = rng(91);
  let out = "";
  const depth = 1950; // stars thin out into the city glow
  for (let k = 0; k < 640; k++) {
    const y = Math.pow(r(), 1.7) * depth; // densest at the top
    const x = r() * W;
    const s = r();
    const fade = Math.max(0, 1 - y / depth);
    const centre = Math.abs(x - W / 2) < W * 0.35 ? 0.7 : 1;
    const o = (0.12 + s * 0.5) * fade * centre;
    if (o < 0.04) continue;
    const col = s > 0.9 ? "#ffe9c4" : s > 0.75 ? "#cfe0ff" : "#e4ddff";
    out += `<circle cx="${f(x)}" cy="${f(y)}" r="${(0.5 + s * s * 1.5).toFixed(2)}" fill="${col}" opacity="${o.toFixed(2)}"/>`;
  }
  // A few soft twinkles near the edges.
  const tw = [[60, 130, 7], [668, 280, 6], [110, 560, 5], [640, 700, 5], [34, 330, 4], [700, 100, 4], [24, 820, 4], [692, 520, 4], [96, 980, 3]];
  for (const [x, y, s] of tw)
    out += `<circle cx="${x}" cy="${y}" r="${s * 1.6}" fill="#cbbcff" opacity="0.18" filter="url(#bl4)"/>
      <path d="M ${x} ${y - s} Q ${x} ${y} ${x + s} ${y} Q ${x} ${y} ${x} ${y + s} Q ${x} ${y} ${x - s} ${y} Q ${x} ${y} ${x} ${y - s} Z" fill="#e8e0ff" opacity="0.55"/>`;
  return out;
}

// A wispy milky band of nebula across the top, and a fainter one lower down.
function nebula() {
  return `<g transform="rotate(-14 360 420)">${soft(360, 420, 520, 60, "#3b2a7a", 0.35)}${soft(250, 430, 200, 34, "#5a3a8a", 0.2)}</g>
  <g transform="rotate(8 420 190)">${soft(420, 190, 480, 44, "#4a2a7a", 0.22)}</g>
  <g transform="rotate(10 380 760)">${soft(380, 760, 460, 46, "#2e2a6a", 0.22)}</g>`;
}

// Edge-of-sky extras: a thin crescent moon, a drifting rock and a falling star.
function skyExtras() {
  const mx = 74, my = 640, mr = 26;
  return `
  ${soft(mx, my, 90, 90, "#8a7ad8", 0.14)}
  <defs><mask id="mbMoon" maskUnits="userSpaceOnUse" x="0" y="0" width="${W}" height="1000">
    <circle cx="${mx}" cy="${my}" r="${mr}" fill="#fff"/><circle cx="${mx + 11}" cy="${my - 7}" r="${mr - 2}" fill="#000"/>
  </mask></defs>
  <circle cx="${mx}" cy="${my}" r="${mr}" fill="#d8ccff" opacity="0.42" mask="url(#mbMoon)"/>
  <!-- a little floating island far off on the right -->
  ${soft(652, 880, 70, 40, "#5a3aa8", 0.16)}
  <path d="M 612 872 Q 650 860 690 870 Q 684 884 664 892 L 652 916 L 640 894 Q 620 888 612 872 Z" fill="#17143e"/>
  <path d="M 614 872 Q 650 861 688 870" fill="none" stroke="#8a7ad8" stroke-width="1.4" opacity="0.35"/>
  <path d="M 640 866 L 640 852 M 636 856 L 640 846 L 644 856" stroke="#17143e" stroke-width="3" fill="none" stroke-linecap="round"/>
  <!-- a falling star streaking down the right edge -->
  <line x1="610" y1="380" x2="676" y2="430" stroke="url(#mbStreak)" stroke-width="1.6" stroke-linecap="round"/>
  <defs><linearGradient id="mbStreak" gradientUnits="userSpaceOnUse" x1="610" y1="380" x2="676" y2="430"><stop offset="0" stop-color="#e8e0ff" stop-opacity="0"/><stop offset="1" stop-color="#fff1d8" stop-opacity="0.6"/></linearGradient></defs>`;
}

// ------------------------------------------------------------ champion tower
function tower() {
  const cx = 360, by = 420; // base of the mesa
  // Spotlight beams fanning up out of the arena.
  let beams = "";
  for (const [a, w, o] of [[-0.55, 0.05, 0.5], [-0.22, 0.04, 0.6], [0.18, 0.04, 0.6], [0.5, 0.05, 0.5]]) {
    const L = 480, ox = cx + a * 60, oy = by - 70;
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
    <linearGradient id="mbBeam" gradientUnits="userSpaceOnUse" x1="0" y1="${by - 70}" x2="0" y2="${by - 530}">
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
    const ny = neon.at ?? top + 20 + r() * 40;
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
        : kind === "heart"
          ? `<path d="M ${x + w / 2} ${y + h * 0.78} Q ${x + w * 0.2} ${y + h * 0.52} ${x + w * 0.32} ${y + h * 0.3} Q ${x + w * 0.44} ${y + h * 0.18} ${x + w / 2} ${y + h * 0.36} Q ${x + w * 0.56} ${y + h * 0.18} ${x + w * 0.68} ${y + h * 0.3} Q ${x + w * 0.8} ${y + h * 0.52} ${x + w / 2} ${y + h * 0.78} Z" fill="none" stroke="${shade(col, 0.5)}" stroke-width="2" stroke-linejoin="round"/>`
          : `<path d="M ${x + w * 0.2} ${y + h * 0.65} L ${x + w * 0.4} ${y + h * 0.35} L ${x + w * 0.6} ${y + h * 0.65} L ${x + w * 0.8} ${y + h * 0.35}" fill="none" stroke="${shade(col, 0.5)}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>`;
  return `<rect x="${x - 4}" y="${y - 4}" width="${w + 8}" height="${h + 8}" rx="8" fill="${col}" opacity="0.22" filter="url(#bl8)"/>
    <rect x="${x}" y="${y}" width="${w}" height="${h}" rx="6" fill="#0c0a24" stroke="${col}" stroke-width="2.2" opacity="0.9"/>
    <g opacity="0.85">${inner}</g>`;
}

// A walkway between towers, with a neon underline.
function skyBridge(x0, x1, y, col) {
  return `<rect x="${x0}" y="${y}" width="${x1 - x0}" height="8" fill="#0f0d2c"/>
    <line x1="${x0}" y1="${y}" x2="${x1}" y2="${y}" stroke="${col}" stroke-width="1.2" opacity="0.45"/>
    <line x1="${x0}" y1="${y + 8}" x2="${x1}" y2="${y + 8}" stroke="${col}" stroke-width="5" opacity="0.12" filter="url(#bl3)"/>`;
}
// A small drifting blimp with a blinking nose light.
function blimp(x, y, s, col) {
  return `<path d="M ${x} ${y} q ${30 * s} ${-14 * s} ${60 * s} 0 q ${-30 * s} ${14 * s} ${-60 * s} 0 Z" fill="#1a1646" opacity="0.8"/>
    <rect x="${x + 22 * s}" y="${y + 5 * s}" width="${14 * s}" height="${4 * s}" rx="1" fill="#1a1646" opacity="0.8"/>
    <circle cx="${x + 58 * s}" cy="${y}" r="${2 * s}" fill="${col}" opacity="0.7"/>`;
}
// A rooftop water tank on legs.
function tank(x, y, col) {
  return `<rect x="${x - 2}" y="${y - 10}" width="2" height="10" fill="${col}"/><rect x="${x + 16}" y="${y - 10}" width="2" height="10" fill="${col}"/>
    <path d="M ${x - 4} ${y - 10} L ${x - 4} ${y - 30} Q ${x + 8} ${y - 40} ${x + 20} ${y - 30} L ${x + 20} ${y - 10} Z" fill="${col}"/>`;
}

function city() {
  const r = rng(5);
  const B = 2090; // street level, hidden in the fog where the caves begin
  // A hazy, very distant skyline high up, so the open middle of the city is not empty.
  let haze = "";
  let hx = -10;
  while (hx < W + 10) {
    const w = 20 + r() * 34;
    const top = 1180 + r() * 160 - (Math.abs(hx - W / 2) < 220 ? 0 : 90);
    haze += building(hx, top, w, B, "#100e30", r, { windows: 0.02, cap: r() > 0.8 ? 2 : 0 });
    hx += w + r() * 6;
  }
  // Far skyline across the whole width, barely above the sky value.
  let far = "";
  let x = -10;
  while (x < W + 10) {
    const w = 26 + r() * 46;
    const top = 1560 + r() * 170 - (Math.abs(x - W / 2) < 200 ? 0 : 60);
    far += building(x, top, w, B, "#121036", r, { windows: 0.035, cap: r() > 0.75 ? 2 : r() > 0.6 ? 1 : 0 });
    x += w + r() * 4;
  }
  // Mid layer on the edges, stepping down toward the middle as the city drops.
  let mid = "";
  const midSpec = [
    [-6, 54, 920], [44, 40, 1100], [80, 48, 1260], [120, 30, 1430], [100, 28, 1600],
    [W - 50, 56, 880], [W - 96, 44, 1040], [W - 134, 40, 1220], [W - 164, 30, 1400], [W - 130, 28, 1580],
  ];
  for (const [bx, w, top] of midSpec) mid += building(bx, top, w, B, "#18163f", r, { windows: 0.08, cap: Math.floor(r() * 4) });
  // Near towers hugging the edges, with neon strips and signs.
  let near = "";
  near += building(-20, 760, 92, B, "#0f0d2c", r, { windows: 0.18, cap: 2, neon: { side: 1, col: "#ff4fb8", len: 160, at: 800 } });
  near += building(66, 1040, 50, B, "#110f30", r, { windows: 0.14, cap: 1, neon: { side: 1, col: "#3ee6ff", len: 110, at: 1080 } });
  near += building(W - 76, 820, 96, B, "#0f0d2c", r, { windows: 0.18, cap: 3, neon: { side: -1, col: "#3ee6ff", len: 180, at: 860 } });
  near += building(W - 118, 1120, 44, B, "#110f30", r, { windows: 0.14, cap: 2, neon: { side: -1, col: "#b88cff", len: 90, at: 1160 } });
  near += tank(W - 54, 806, "#0f0d2c");
  // A second, lower street block in front of the towers, lower down the city.
  near += building(-14, 1520, 74, B, "#0d0b27", r, { windows: 0.16, cap: 3, neon: { side: 1, col: "#ffd34e", len: 120, at: 1560 } });
  near += building(54, 1700, 56, B, "#0e0c29", r, { windows: 0.12, cap: 0, neon: { side: 1, col: "#ff4fb8", len: 70, at: 1730 } });
  near += building(W - 66, 1460, 80, B, "#0d0b27", r, { windows: 0.16, cap: 2, neon: { side: -1, col: "#ff4fb8", len: 140, at: 1500 } });
  near += building(W - 122, 1660, 60, B, "#0e0c29", r, { windows: 0.12, cap: 1, neon: { side: -1, col: "#3ee6ff", len: 80, at: 1700 } });
  near += tank(18, 1520, "#0d0b27");
  // Signs, alternating sides and colours all the way down.
  near += neonSign(12, 900, 48, 30, "#ff4fb8", "ball");
  near += neonSign(W - 64, 980, 50, 30, "#3ee6ff", "zig");
  near += neonSign(18, 1180, 40, 40, "#ffd34e", "star");
  near += neonSign(W - 60, 1300, 44, 28, "#b88cff", "ball");
  near += neonSign(14, 1390, 46, 30, "#3ee6ff", "heart");
  near += neonSign(W - 58, 1580, 42, 40, "#ffd34e", "star");
  near += neonSign(16, 1620, 44, 28, "#b88cff", "zig");
  near += neonSign(W - 62, 1680, 48, 30, "#ff4fb8", "heart");
  // Sky bridges between near towers and drifting blimps.
  near += skyBridge(40, 110, 1200, "#3ee6ff") + skyBridge(W - 120, W - 40, 1420, "#b88cff") + skyBridge(30, 104, 1760, "#ffd34e");
  near += blimp(150, 860, 1, "#ff8a9a") + blimp(520, 1260, 0.8, "#7fe6ff");
  return `
  <defs>
    <linearGradient id="mbCityFade" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#0e0f2e" stop-opacity="0"/><stop offset="0.35" stop-color="#0e0f2e" stop-opacity="0.6"/><stop offset="1" stop-color="#0b1230" stop-opacity="1"/>
    </linearGradient>
  </defs>
  <linearGradient id="mbCityHaze" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0e0f2e" stop-opacity="0.2"/><stop offset="0.5" stop-color="#0e0f2e" stop-opacity="0.55"/><stop offset="1" stop-color="#0e0f2e" stop-opacity="0.7"/></linearGradient>
  <mask id="mbCityMask" maskUnits="userSpaceOnUse" x="0" y="0" width="${W}" height="${H}">
    <rect width="${W}" height="2200" fill="url(#mbCityM)"/>
  </mask>
  <linearGradient id="mbCityM" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="0" y2="2200">
    <stop offset="0.8" stop-color="#fff"/><stop offset="0.9" stop-color="#fff" stop-opacity="0.35"/><stop offset="0.95" stop-color="#fff" stop-opacity="0"/>
  </linearGradient>
  <g mask="url(#mbCityMask)">
    <g opacity="0.75">${haze}</g>
    <rect x="0" y="1100" width="${W}" height="900" fill="url(#mbCityHaze)"/>
    <g opacity="0.9">${far}</g>
    ${mid}
    ${near}
    <rect x="0" y="1720" width="${W}" height="380" fill="url(#mbCityFade)" opacity="0.6"/>
  </g>`;
}

// ------------------------------------------------------------ crystal caves
function crystal(x, y, len, wid, ang, col, o = 1) {
  // A hexagonal prism pointing along ang (degrees, 0 = up).
  const g = `mbC${gid++}`;
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
  return out;
}

// Small crystal sprouts tucked into the wall between the big clusters.
function sprout(x, y, side, col, seed) {
  const r = rng(seed);
  let out = soft(x - side * 10, y - 12, 40, 34, col, 0.22);
  for (let k = 0; k < 3; k++) {
    const ang = -side * (25 + k * 22 + (r() - 0.5) * 10);
    out += crystal(x + side * (k - 1) * 4, y + k * 3, 22 + r() * 16, 4 + r() * 2, ang, col, 0.6);
  }
  return out;
}

function wallPts(y0, y1, seed, depth) {
  const r = rng(seed);
  const pts = [];
  for (let y = y0; y <= y1; y += 40 + r() * 30) {
    const t = (y - y0) / (y1 - y0);
    // A long wall: swells in quickly, then wanders in and out along its length.
    const bulge = Math.pow(Math.sin(t * Math.PI), 0.55) * depth * (0.85 + 0.15 * Math.sin(t * Math.PI * 5 + seed));
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
  const LY = [1900, 3110], RY = [1930, 3090];
  let out = "";
  // Back cave walls with a soft rim of crystal light.
  out += `<g filter="url(#bl3)">${wall(-1, 1820, 3180, 7, "#0d1030", 140)}${wall(1, 1850, 3160, 8, "#0d1030", 140)}</g>`;
  out += wall(-1, LY[0], LY[1], 17, "#090b24", 104, T) + wall(1, RY[0], RY[1], 18, "#090b24", 104, P);
  // Crystal clusters growing out of the front walls' edges.
  const LW = wallPts(LY[0], LY[1], 17, 104), RW = wallPts(RY[0], RY[1], 18, 104);
  const at = (side, y) => {
    const d = wallDepth(side < 0 ? LW : RW, y) - 4;
    return side < 0 ? d : W - d;
  };
  const onWall = (side, y, scale, col, seed) => cluster(at(side, y), y, side, scale * 1.2, col, seed);
  out += onWall(-1, 2060, 0.95, T, 1);
  out += onWall(1, 2230, 1.05, P, 2);
  out += onWall(-1, 2390, 0.85, P, 3);
  out += onWall(1, 2560, 0.8, T, 4);
  out += onWall(-1, 2700, 0.9, B, 5);
  out += onWall(1, 2020, 0.7, M, 6);
  out += onWall(1, 2860, 0.95, B, 7);
  out += onWall(-1, 2960, 0.75, M, 8);
  out += onWall(1, 3010, 0.65, T, 9);
  out += onWall(-1, 2200, 0.6, B, 10);
  // Little sprouts between them so the walls never go dark for long.
  const sp = [[-1, 2290, M], [1, 2390, B], [-1, 2560, T], [1, 2700, M], [-1, 2840, P], [1, 2120, T], [-1, 3050, T]];
  sp.forEach(([side, y, col], k) => {
    out += sprout(at(side, y) + side * 2, y, side, col, 60 + k);
  });
  // Stalagmite / stalactite fingers along the walls.
  const r = rng(44);
  for (const side of [-1, 1]) {
    for (let k = 0; k < 12; k++) {
      const y = 1980 + k * 92 + r() * 30;
      const d = wallDepth(side < 0 ? LW : RW, y + 10);
      if (d < 20) continue;
      const x = side < 0 ? d : W - d;
      const len = 20 + r() * 30;
      out += `<path d="M ${f(x + side * 12)} ${f(y)} L ${f(x - side * len)} ${f(y + 12 - r() * 16)} L ${f(x + side * 12)} ${f(y + 22)} Z" fill="#090b24"/>`;
    }
  }
  // A few loose glowing shards floating in the open middle, very faint.
  const r2 = rng(12);
  for (let k = 0; k < 22; k++) {
    const x = 120 + r2() * 480, y = 1900 + r2() * 1200, s = 2 + r2() * 3;
    const col = [T, P, B][k % 3];
    out += `<circle cx="${f(x)}" cy="${f(y)}" r="${f(s * 3)}" fill="${col}" opacity="0.12" filter="url(#bl4)"/>
      <path d="M ${f(x)} ${f(y - s * 1.6)} L ${f(x + s * 0.7)} ${f(y)} L ${f(x)} ${f(y + s * 1.6)} L ${f(x - s * 0.7)} ${f(y)} Z" fill="${shade(col, 0.3)}" opacity="${(0.25 + r2() * 0.2).toFixed(2)}"/>`;
  }
  return out;
}

// Neon ruins: broken pillars and arch fragments with glowing glyph bands.
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

function fallenBlock(x, y, w, h, rot, col) {
  const cx = x + w / 2, cy = y + h / 2;
  return `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="4" fill="url(#mbStone)" transform="rotate(${rot} ${cx} ${cy})"/>
  <rect x="${x + 8}" y="${y + 12}" width="${w - 16}" height="3" fill="${col}" opacity="0.5" transform="rotate(${rot} ${cx} ${cy})"/>`;
}

function ruins() {
  const T = "#3ee6ff", P = "#b88cff", M = "#ff7ad0";
  return `
  <defs><linearGradient id="mbStone" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1a1a46"/><stop offset="0.5" stop-color="#262660"/><stop offset="1" stop-color="#121236"/></linearGradient></defs>
  <!-- the colonnade where the city gives way to the caves -->
  ${pillar(18, 1840, 2040, 34, T, true)}
  ${pillar(66, 1910, 2040, 26, T, true)}
  ${pillar(100, 1980, 2050, 20, P, true)}
  ${pillar(W - 52, 1760, 2000, 34, P, true)}
  ${pillar(W - 98, 1870, 2000, 26, P, true)}
  ${pillar(W - 126, 1950, 2010, 18, T, true)}
  <!-- a lintel still resting across the two right pillars -->
  <rect x="${W - 104}" y="1858" width="70" height="12" rx="2" fill="url(#mbStone)" transform="rotate(-6 ${W - 69} 1864)"/>
  <!-- arch fragment on the right, half swallowed by the cave -->
  <path d="M ${W} 2320 Q ${W - 120} 2310 ${W - 150} 2420 L ${W - 128} 2424 Q ${W - 104} 2336 ${W} 2344 Z" fill="url(#mbStone)" opacity="0.9"/>
  <path d="M ${W} 2332 Q ${W - 112} 2323 ${W - 139} 2422" fill="none" stroke="${T}" stroke-width="2" opacity="0.5"/>
  <!-- a smaller arch fragment on the left, lower down -->
  <path d="M 0 2600 Q 100 2592 124 2684 L 106 2688 Q 86 2614 0 2620 Z" fill="url(#mbStone)" opacity="0.85"/>
  <path d="M 0 2610 Q 92 2602 115 2686" fill="none" stroke="${M}" stroke-width="2" opacity="0.45"/>
  <!-- a pillar that toppled against the right wall -->
  <g transform="rotate(-24 ${W - 40} 2780)">${pillar(W - 58, 2660, 2790, 26, M, true)}</g>
  <!-- fallen blocks -->
  ${fallenBlock(-6, 2510, 62, 34, -8, P)}
  ${fallenBlock(W - 70, 3010, 56, 30, 7, T)}
  ${fallenBlock(4, 3050, 48, 28, 12, M)}`;
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

function bouncyBall(x, y, r, a = "#7a2a6a", b = "#1f6a7a", glow = "#ff4fb8") {
  const g = `mbBB${gid++}`;
  return `<defs>
    <radialGradient id="${g}" cx="0.35" cy="0.3" r="0.8"><stop offset="0" stop-color="#4a3a8a"/><stop offset="1" stop-color="#1a1440"/></radialGradient>
    <clipPath id="${g}c"><circle cx="${x}" cy="${y}" r="${r}"/></clipPath>
  </defs>
  <circle cx="${x}" cy="${y}" r="${r * 1.2}" fill="${glow}" opacity="0.1" filter="url(#bl16)"/>
  <circle cx="${x}" cy="${y}" r="${r}" fill="url(#${g})"/>
  <g clip-path="url(#${g}c)">
    <path d="M ${x - r} ${y - r * 0.2} Q ${x} ${y - r * 0.6} ${x + r} ${y - r * 0.1} L ${x + r} ${y + r * 0.15} Q ${x} ${y - r * 0.3} ${x - r} ${y + r * 0.1} Z" fill="${a}" opacity="0.7"/>
    <path d="M ${x - r} ${y + r * 0.45} Q ${x} ${y + r * 0.1} ${x + r} ${y + r * 0.55} L ${x + r} ${y + r * 0.8} Q ${x} ${y + r * 0.35} ${x - r} ${y + r * 0.7} Z" fill="${b}" opacity="0.7"/>
  </g>
  <ellipse cx="${x - r * 0.38}" cy="${y - r * 0.45}" rx="${r * 0.22}" ry="${r * 0.1}" fill="#fff" opacity="0.18" transform="rotate(-35 ${x - r * 0.38} ${y - r * 0.45})"/>`;
}

// A coiled spring standing on its base, cap on top.
function spring(x, y, turns) {
  let coil = "";
  for (let k = 0; k < turns; k++) coil += `<ellipse cx="${x}" cy="${y - k * 9}" rx="15" ry="5" fill="none" stroke="#3a4a7a" stroke-width="3" opacity="0.8"/>`;
  return `<ellipse cx="${x}" cy="${y + 6}" rx="18" ry="6" fill="#1a1a44"/>` + coil + `<ellipse cx="${x}" cy="${y - turns * 9}" rx="18" ry="6" fill="#2a2a5a"/>`;
}

// A big speckled egg nestled in the grass, faintly lit from inside.
function egg(x, y, s) {
  const g = `mbEgg${gid++}`;
  const h = s * 1.05; // lower half-height; the top half is 1.3x taller
  let spots = "";
  const r = rng(Math.round(x + y));
  for (let k = 0; k < 9; k++) {
    const a = r() * Math.PI * 2, d = Math.sqrt(r()) * 0.7;
    spots += `<ellipse cx="${f(x + Math.cos(a) * s * d)}" cy="${f(y - h * 1.1 + Math.sin(a) * h * d)}" rx="${f(1.5 + r() * 2.5)}" ry="${f(1.2 + r() * 2)}" fill="#1a2240" opacity="0.6"/>`;
  }
  return `<defs><radialGradient id="${g}" cx="0.38" cy="0.32" r="0.8"><stop offset="0" stop-color="#4a5a8a"/><stop offset="0.7" stop-color="#25305a"/><stop offset="1" stop-color="#151b3a"/></radialGradient></defs>
  ${soft(x, y - h, s * 2.4, h * 2.2, "#5cff9a", 0.1)}
  <path d="M ${x - s} ${y - h} A ${s} ${h} 0 0 0 ${x + s} ${y - h} A ${s} ${f(h * 1.3)} 0 0 0 ${x - s} ${y - h} Z" fill="url(#${g})"/>
  ${spots}
  <path d="M ${x - s * 0.6} ${y - h * 1.5} Q ${x - s * 0.45} ${y - h * 1.95} ${x - s * 0.1} ${y - h * 2.1}" stroke="#fff" stroke-width="2" fill="none" opacity="0.14" stroke-linecap="round"/>`;
}

// A spinning top leaning over where it stopped.
function spinTop(x, y, s, rot, col) {
  const body = `M ${x - s} ${y} Q ${x - s} ${y - s * 0.38} ${x} ${y - s * 0.42} Q ${x + s} ${y - s * 0.38} ${x + s} ${y} L ${x + s * 0.16} ${y + s * 0.8} Q ${x} ${y + s * 0.95} ${x - s * 0.16} ${y + s * 0.8} Z`;
  return `<ellipse cx="${x}" cy="${y + s * 0.95}" rx="${s * 0.9}" ry="${s * 0.16}" fill="#000" opacity="0.3"/>
  <g transform="rotate(${rot} ${x} ${y + s * 0.9})">
    <path d="${body}" fill="${shade(col, -0.66)}"/>
    <path d="M ${x - s * 0.92} ${y + s * 0.12} L ${x + s * 0.92} ${y + s * 0.12}" stroke="${shade(col, -0.35)}" stroke-width="${s * 0.14}"/>
    <path d="M ${x - s * 0.6} ${y + s * 0.42} L ${x + s * 0.6} ${y + s * 0.42}" stroke="${shade(col, -0.5)}" stroke-width="${s * 0.08}"/>
    <rect x="${x - s * 0.09}" y="${y - s * 0.78}" width="${s * 0.18}" height="${s * 0.42}" rx="${s * 0.06}" fill="${shade(col, -0.55)}"/>
    <path d="M ${x - s * 0.7} ${y - s * 0.14} Q ${x - s * 0.4} ${y - s * 0.32} ${x - s * 0.05} ${y - s * 0.34}" stroke="#fff" stroke-width="2" fill="none" opacity="0.12" stroke-linecap="round"/>
  </g>`;
}

function mushroom(x, y, s, col) {
  return `<circle cx="${x}" cy="${y - s}" r="${s * 2.4}" fill="${col}" opacity="0.18" filter="url(#bl6)"/>
    <rect x="${x - s * 0.22}" y="${y - s}" width="${s * 0.44}" height="${s}" rx="${s * 0.2}" fill="#bfc6e6" opacity="0.55"/>
    <path d="M ${x - s} ${y - s * 0.9} Q ${x} ${y - s * 2.1} ${x + s} ${y - s * 0.9} Z" fill="${col}" opacity="0.75"/>
    <circle cx="${x - s * 0.3}" cy="${y - s * 1.3}" r="${s * 0.14}" fill="#fff" opacity="0.6"/>`;
}

// A bush: a cluster of overlapping blobs, darker than the hill it sits on.
function bush(x, y, s, c) {
  return `<circle cx="${x}" cy="${y - s * 0.6}" r="${s}" fill="${c}"/><circle cx="${x - s * 0.9}" cy="${y - s * 0.3}" r="${s * 0.7}" fill="${c}"/><circle cx="${x + s * 0.9}" cy="${y - s * 0.25}" r="${s * 0.75}" fill="${c}"/>`;
}

// Grass tufts: dense and tall on the edges, sparse and short in the middle.
function grassRow(r, yb, n) {
  let out = "";
  for (let k = 0; k < n; k++) {
    const x = r() * W;
    const edge = Math.min(x, W - x) / (W / 2); // 0 at edges, 1 at centre
    const h = (20 + r() * 50) * (1.2 - edge * 0.85);
    out += grassBlade(x, yb + 4, h, (r() - 0.5) * 24, 3 + r() * 3, k % 4 ? "#122a30" : "#163636", 0.85);
  }
  return out;
}

function meadow() {
  const r = rng(301);
  const rows = [3420, 3640, 3840, 4000]; // the grass lines at the foot of each hill
  let out = "";
  // Edge trees fading into the cave mouth above.
  out += tree(-20, 3130, 110, "#08101e") + tree(740, 3110, 115, "#08101e");
  out += tree(64, 3220, 78, "#09131f") + tree(664, 3250, 84, "#09131f");
  // Rolling hills: far ones barely visible across the width, nearer ones lower.
  out += `<path d="M 0 3260 Q 120 3200 240 3230 Q 360 3190 480 3225 Q 600 3185 720 3220 L 720 ${H} L 0 ${H} Z" fill="#0f1c2e" opacity="0.8"/>`;
  out += tree(30, 3290, 54, "#0a1420") + tree(700, 3310, 50, "#0a1420");
  out += `<path d="M 0 3400 Q 150 3350 300 3380 Q 450 3345 600 3375 Q 670 3360 720 3370 L 720 ${H} L 0 ${H} Z" fill="#0d1d2a"/>`;
  // First hill: the classic toy pile, blocks on the left and ball + spring on the right.
  out += toyBlock(40, 3348, 54, -8, "#ffd34e") + toyBlock(96, 3360, 46, 6, "#3ee6ff") + toyBlock(62, 3300, 44, 12, "#ff4fb8");
  out += bouncyBall(650, 3338, 52);
  out += spring(582, 3380, 6);
  out += grassRow(r, rows[0], 50);
  out += `<path d="M 0 3600 Q 180 3560 360 3585 Q 540 3555 720 3580 L 720 ${H} L 0 ${H} Z" fill="#0c1b27"/>`;
  // Second hill: the egg on the left, a toppled top and bushes on the right.
  out += bush(110, 3600, 22, "#0a1820") + bush(612, 3590, 20, "#0a1820");
  out += egg(58, 3618, 28);
  out += spinTop(656, 3604, 28, 16, "#b88cff");
  out += grassRow(r, rows[1], 46);
  out += `<path d="M 0 3800 Q 180 3760 360 3785 Q 540 3755 720 3780 L 720 ${H} L 0 ${H} Z" fill="#0b1a24"/>`;
  // Third hill: a small ball on the left, a two-block stack on the right.
  out += bouncyBall(76, 3786, 30, "#1f6a7a", "#7a6a2a", "#3ee6ff");
  out += toyBlock(648, 3800, 42, -4, "#5cff9a") + toyBlock(690, 3806, 34, 10, "#ffd34e") + toyBlock(664, 3762, 34, 14, "#b88cff");
  out += grassRow(r, rows[2], 46);
  out += `<path d="M 0 3950 Q 200 3920 360 3935 Q 520 3915 720 3940 L 720 ${H} L 0 ${H} Z" fill="#0a1820"/>`;
  out += grassRow(r, rows[3], 40);
  // A few glowing blades and mushrooms along the edges.
  let glow = "";
  for (let k = 0; k < 24; k++) {
    const side = k % 2 ? 1 : -1;
    const x = side < 0 ? 10 + r() * 110 : W - 10 - r() * 110;
    const yb = rows[k % 4];
    glow += grassBlade(x, yb, 30 + r() * 40, side * (4 + r() * 12), 2.4, "url(#mbBlade)", 0.65);
  }
  out += `<defs><linearGradient id="mbBlade" x1="0" y1="1" x2="0" y2="0"><stop offset="0" stop-color="#1a4a3a"/><stop offset="1" stop-color="#5cff9a" stop-opacity="0.7"/></linearGradient></defs>` + glow;
  out += mushroom(130, 3422, 10, "#5aa8ff") + mushroom(150, 3420, 6, "#b88cff") + mushroom(690, 3420, 7, "#5cff9a");
  out += mushroom(574, 3642, 9, "#b88cff") + mushroom(110, 3644, 7, "#5cff9a") + mushroom(124, 3646, 5, "#ff7ad0");
  out += mushroom(28, 3842, 8, "#ff7ad0") + mushroom(600, 3842, 8, "#5aa8ff") + mushroom(586, 3844, 5, "#5cff9a");
  out += mushroom(40, 3990, 9, "#b88cff") + mushroom(680, 3988, 10, "#ff7ad0");
  // Fireflies drifting up through the meadow and into the caves.
  let flies = "";
  for (let k = 0; k < 42; k++) {
    const side = r() < 0.5 ? -1 : 1;
    const x = r() < 0.7 ? sideX(r, side, 10, 150) : 150 + r() * 420;
    const y = 2950 + r() * 1030;
    const s = 1.4 + r() * 1.4;
    flies += `<circle cx="${f(x)}" cy="${f(y)}" r="${f(s * 4)}" fill="#5cff9a" opacity="0.18" filter="url(#bl4)"/><circle cx="${f(x)}" cy="${f(y)}" r="${f(s * 0.7)}" fill="#d8ffe6" opacity="0.7"/>`;
  }
  return out + flies;
}

// ----------------------------------------------------------- mist + finish
function mist() {
  // Soft horizontal haze bands at the zone joins so nothing reads as a seam.
  const bands = [[720, 320, "#140f38", 0.45], [1990, 380, "#100f30", 0.55], [3100, 400, "#0d1828", 0.6], [3270, 200, "#0e1a2c", 0.35]];
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
    <stop offset="0" stop-color="#07071a" stop-opacity="0.6"/><stop offset="0.02" stop-color="#07071a" stop-opacity="0"/>
    <stop offset="0.98" stop-color="#06100f" stop-opacity="0"/><stop offset="1" stop-color="#06100f" stop-opacity="0.5"/>
  </linearGradient></defs>
  <rect x="0" y="0" width="${W}" height="${H}" fill="url(#mbLane)"/>
  <rect width="${W}" height="${H}" fill="url(#mbEnds)"/>`;
}

export default () => {
  gid = 0; // stable ids across renders
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${blurs()}
  ${base()}
  ${washes()}
  ${nebula()}
  ${starfield()}
  ${skyExtras()}
  ${tower()}
  ${city()}
  ${caves()}
  ${ruins()}
  ${meadow()}
  ${mist()}
  ${centreCalm()}
  </svg>`;
};

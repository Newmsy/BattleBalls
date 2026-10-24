// Glow chest: halfway up the run, a treasure chest bursts open in warm orange
// light; boon badges float out with sparkles while a little critter gawps.
import { ball, eye, shade, INK } from "../../brand/parts.mjs";
import { svg, blurs, coin, badge, sparkle, stars, blush, rng, RARITY } from "./_shop_charge_pad_glow_chest_parts.mjs";

const C = RARITY.common, R = RARITY.rare, E = RARITY.epic;
const O = "#FF9A3C";
const MX = 372, MY = 236; // chest mouth centre

function backdrop() {
  let hills = "";
  hills += `<path d="M 0 300 Q 90 230 190 270 Q 280 220 380 262 Q 480 214 580 258 Q 660 230 720 262 L 720 440 L 0 440 Z" fill="#1c1650"/>`;
  hills += `<path d="M 0 330 Q 120 290 240 320 Q 360 296 480 318 Q 600 290 720 316 L 720 440 L 0 440 Z" fill="#161240"/>`;
  return `
  <defs>
    <radialGradient id="bgG" cx="0.52" cy="0.5" r="0.75"><stop offset="0" stop-color="#4a2a6a"/><stop offset="0.35" stop-color="#2c2170"/><stop offset="0.7" stop-color="#141038"/><stop offset="1" stop-color="#0D0F26"/></radialGradient>
    <radialGradient id="pool" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="${O}" stop-opacity="0.55"/><stop offset="1" stop-color="${O}" stop-opacity="0"/></radialGradient>
  </defs>
  <rect width="720" height="440" fill="url(#bgG)"/>
  ${stars(31, 80, 0, 0, 720, 260)}
  ${hills}
  <ellipse cx="${MX}" cy="366" rx="330" ry="72" fill="url(#pool)"/><ellipse cx="${MX}" cy="360" rx="190" ry="34" fill="${O}" opacity="0.35" filter="url(#bl16)"/>`;
}

function rays() {
  let out = "";
  const n = 13;
  for (let k = 0; k < n; k++) {
    const a = -Math.PI / 2 + (k - (n - 1) / 2) * 0.2;
    const w = 0.045 + (k % 3) * 0.02;
    const L = 360 + (k % 2) * 80;
    const p1 = [MX + Math.cos(a - w) * L, MY + Math.sin(a - w) * L];
    const p2 = [MX + Math.cos(a + w) * L, MY + Math.sin(a + w) * L];
    out += `<polygon points="${MX},${MY} ${p1} ${p2}" fill="url(#rayG)" opacity="${k % 2 ? 0.55 : 0.85}"/>`;
  }
  return `
  <defs><radialGradient id="rayG" gradientUnits="userSpaceOnUse" cx="${MX}" cy="${MY}" r="420"><stop offset="0" stop-color="#ffe7a8" stop-opacity="0.9"/><stop offset="0.5" stop-color="${O}" stop-opacity="0.35"/><stop offset="1" stop-color="${O}" stop-opacity="0"/></radialGradient></defs>
  <circle cx="${MX}" cy="${MY - 20}" r="170" fill="${O}" opacity="0.35" filter="url(#bl40)"/>
  <g filter="url(#bl4)">${out}</g>`;
}

function chest() {
  const L = 268, Rr = 476, top = 240, bot = 356;
  const wood = (x, y, w, h) => `<rect x="${x}" y="${y}" width="${w}" height="${h}" fill="url(#woodG)"/>`;
  let planks = "";
  for (let y = top + 6; y < bot; y += 28) planks += `<line x1="${L}" y1="${y}" x2="${Rr}" y2="${y}" stroke="#2a1430" stroke-width="2" opacity="0.7"/>`;
  return `
  <defs>
    <linearGradient id="woodG" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#7a3e6a"/><stop offset="1" stop-color="#3e1a44"/></linearGradient>
    <linearGradient id="lidIn" x1="0" y1="1" x2="0" y2="0"><stop offset="0" stop-color="#ffb35a"/><stop offset="1" stop-color="#5a2a50"/></linearGradient>
    <linearGradient id="bodyShade" x1="0" y1="0" x2="0" y2="1"><stop offset="0.3" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.35"/></linearGradient>
    <linearGradient id="gold" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffe9a0"/><stop offset="0.5" stop-color="#e8b04a"/><stop offset="1" stop-color="#9a6420"/></linearGradient>
    <linearGradient id="rimLight" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${O}" stop-opacity="0.65"/><stop offset="0.5" stop-color="${O}" stop-opacity="0"/></linearGradient>
  </defs>
  <ellipse cx="${(L + Rr) / 2}" cy="${bot + 6}" rx="140" ry="18" fill="#000" opacity="0.55" filter="url(#bl6)"/>
  <!-- lid, flung open and tilted back -->
  <path d="M ${L + 6} ${top - 10} L ${L + 26} ${top - 96} Q ${(L + Rr) / 2} ${top - 128} ${Rr - 26} ${top - 96} L ${Rr - 6} ${top - 10} Z" fill="url(#lidIn)" stroke="#1e0a22" stroke-width="3"/>
  <path d="M ${L + 26} ${top - 96} Q ${(L + Rr) / 2} ${top - 128} ${Rr - 26} ${top - 96} L ${Rr - 22} ${top - 84} Q ${(L + Rr) / 2} ${top - 114} ${L + 22} ${top - 84} Z" fill="url(#gold)" stroke="#5a3410" stroke-width="2"/>
  <rect x="${L + 70}" y="${top - 112}" width="16" height="104" fill="url(#gold)" opacity="0.9" transform="skewX(-4)"/>
  <rect x="${Rr - 86}" y="${top - 112}" width="16" height="104" fill="url(#gold)" opacity="0.9" transform="skewX(4)"/>
  <!-- glowing mouth -->
  <path d="M ${MX - 80} ${top - 4} L ${MX - 40} ${top - 170} L ${MX + 40} ${top - 170} L ${MX + 80} ${top - 4} Z" fill="#ffe7a8" opacity="0.45" filter="url(#bl16)"/>
  <ellipse cx="${MX}" cy="${top - 26}" rx="130" ry="46" fill="#ffd27a" opacity="0.75" filter="url(#bl16)"/>
  <ellipse cx="${MX}" cy="${top - 2}" rx="${(Rr - L) / 2 - 4}" ry="22" fill="#fff4d0"/>
  <ellipse cx="${MX}" cy="${top - 2}" rx="${(Rr - L) / 2 + 10}" ry="34" fill="#ffd27a" opacity="0.8" filter="url(#bl8)"/>
  <ellipse cx="${MX}" cy="${top - 10}" rx="84" ry="20" fill="#fff" filter="url(#bl6)"/>
  <!-- body -->
  <path d="M ${L} ${top} L ${Rr} ${top} L ${Rr - 4} ${bot} Q ${MX} ${bot + 8} ${L + 4} ${bot} Z" fill="url(#woodG)" stroke="#1e0a22" stroke-width="3"/>
  ${planks}
  <path d="M ${L} ${top} L ${Rr} ${top} L ${Rr - 4} ${bot} Q ${MX} ${bot + 8} ${L + 4} ${bot} Z" fill="url(#bodyShade)"/>
  <path d="M ${L + 3} ${top + 12} L ${L + 6} ${bot - 6}" stroke="#ffb35a" stroke-width="3" opacity="0.5"/>
  <path d="M ${Rr - 3} ${top + 12} L ${Rr - 6} ${bot - 6}" stroke="#ffb35a" stroke-width="3" opacity="0.5"/>
  <path d="M ${L} ${top} L ${Rr} ${top} L ${Rr - 1} ${top + 50} L ${L + 1} ${top + 50} Z" fill="url(#rimLight)"/>
  <rect x="${L - 6}" y="${top - 6}" width="${Rr - L + 12}" height="18" rx="5" fill="url(#gold)" stroke="#5a3410" stroke-width="2"/>
  <rect x="${L - 4}" y="${bot - 18}" width="${Rr - L + 8}" height="16" rx="5" fill="url(#gold)" stroke="#5a3410" stroke-width="2"/>
  <rect x="${L + 32}" y="${top + 8}" width="20" height="${bot - top - 24}" fill="url(#gold)" stroke="#5a3410" stroke-width="2"/>
  <rect x="${Rr - 52}" y="${top + 8}" width="20" height="${bot - top - 24}" fill="url(#gold)" stroke="#5a3410" stroke-width="2"/>
  ${[top + 2, bot - 10].map((y) => [L + 8, L + 42, Rr - 42, Rr - 8].map((x) => `<circle cx="${x}" cy="${y}" r="3" fill="#5a3410"/>`).join("")).join("")}
  <!-- Button-shaped lock plate -->
  <path d="M ${MX - 30} ${top + 8} L ${MX + 30} ${top + 8} L ${MX + 30} ${top + 50} Q ${MX} ${top + 78} ${MX - 30} ${top + 50} Z" fill="url(#gold)" stroke="#5a3410" stroke-width="2.5"/>
  ${coin(MX, top + 40, 20, { glow: false, shadow: false })}
  <rect x="${L - 6}" y="${top - 6}" width="${Rr - L + 12}" height="4" rx="2" fill="#fff4d0" opacity="0.9"/>`;
}

function floaters() {
  // Badges rising out of the chest along a fountain, with trails.
  const list = [
    [236, 150, 22, C, -14],
    [298, 92, 26, R, -8],
    [384, 66, 32, E, 4],
    [462, 104, 26, C, 10],
    [516, 168, 21, R, 16],
  ];
  let out = "";
  for (const [x, y, s, col, rot] of list) {
    const dx = MX - x, dy = MY - 30 - y, d = Math.hypot(dx, dy);
    const ux = dx / d, uy = dy / d;
    out += `<line x1="${x + ux * s * 1.2}" y1="${y + uy * s * 1.2}" x2="${x + ux * s * 3}" y2="${y + uy * s * 3}" stroke="${col}" stroke-width="${s * 0.5}" stroke-linecap="round" opacity="0.35" filter="url(#bl3)"/>`;
    out += badge(x, y, s, col, { rot, glow: 1.3 });
  }
  return out;
}

function flyingCoins() {
  return [
    [330, 182, 12, 30, 0.6], [424, 176, 11, -20, 0.5], [262, 214, 10, 50, 0.85], [492, 222, 12, -40, 0.7],
  ].map(([x, y, r, rot, sy]) => coin(x, y, r, { rot, sy, glow: true, shadow: false })).join("") +
    [[236, 368, 14, 10, 0.45], [506, 372, 15, -20, 0.45], [530, 352, 11, 30, 0.9], [210, 352, 10, -10, 0.85]]
      .map(([x, y, r, rot, sy]) => coin(x, y, r, { rot, sy, glow: true })).join("");
}

function sparkles() {
  const r = rng(4);
  let out = "";
  for (let k = 0; k < 16; k++) {
    const a = -Math.PI + r() * Math.PI, d = 90 + r() * 200;
    const x = MX + Math.cos(a) * d * 1.2, y = MY - 20 + Math.sin(a) * d * 0.9;
    if (x < 30 || x > 690 || y < 26) continue;
    out += sparkle(x, y, 3 + r() * 7, k % 3 ? "#fff4d0" : "#ffd27a", 0.6 + r() * 0.4);
  }
  return out;
}

function gawper(cx, cy, r) {
  const col = "#5CFF9A";
  const ey = cy - r * 0.18;
  return `
  <defs><linearGradient id="gwRim" x1="0" y1="0" x2="1" y2="0"><stop offset="0.55" stop-color="${O}" stop-opacity="0"/><stop offset="1" stop-color="${O}" stop-opacity="0.7"/></linearGradient></defs>
  <ellipse cx="${cx + 4}" cy="${cy + r * 0.95}" rx="${r * 0.9}" ry="${r * 0.2}" fill="#000" opacity="0.45" filter="url(#bl3)"/>
  ${ball(cx, cy, r, col, { sx: 0.96, sy: 1.04, glow: false })}
  <ellipse cx="${cx}" cy="${cy}" rx="${r * 0.96}" ry="${r * 1.04}" fill="url(#gwRim)"/>
  ${eye(cx - r * 0.18, ey, r * 0.24, r * 0.3, 0.6, -0.6, r * 0.13)}
  ${eye(cx + r * 0.38, ey, r * 0.24, r * 0.3, 0.6, -0.6, r * 0.13)}
  <path d="M ${cx - r * 0.4} ${ey - r * 0.46} Q ${cx - r * 0.2} ${ey - r * 0.6} ${cx - r * 0.02} ${ey - r * 0.48}" fill="none" stroke="${INK}" stroke-width="${r * 0.08}" stroke-linecap="round"/>
  <path d="M ${cx + r * 0.2} ${ey - r * 0.48} Q ${cx + r * 0.4} ${ey - r * 0.62} ${cx + r * 0.6} ${ey - r * 0.46}" fill="none" stroke="${INK}" stroke-width="${r * 0.08}" stroke-linecap="round"/>
  <ellipse cx="${cx + r * 0.12}" cy="${cy + r * 0.38}" rx="${r * 0.13}" ry="${r * 0.17}" fill="${INK}"/>
  ${blush(cx - r * 0.5, cy + r * 0.2, r * 0.14)}${blush(cx + r * 0.66, cy + r * 0.2, r * 0.14)}
  ${sparkle(cx + r * 0.95, cy - r * 0.95, 6, "#fff4d0")}`;
}

export default () =>
  svg(`${blurs()}
  ${backdrop()}
  ${rays()}
  ${chest()}
  ${floaters()}
  ${flyingCoins()}
  ${sparkles()}
  ${gawper(150, 330, 52)}
  <defs><radialGradient id="vig" cx="0.5" cy="0.45" r="0.75"><stop offset="0.6" stop-color="#0D0F26" stop-opacity="0"/><stop offset="1" stop-color="#0D0F26" stop-opacity="0.7"/></radialGradient></defs>
  <rect width="720" height="440" fill="url(#vig)"/>
  <path d="M -10 440 L -10 380 Q 60 360 120 400 Q 160 420 180 440 Z" fill="#0d0a2a"/>
  <path d="M 730 440 L 730 370 Q 650 372 600 410 Q 580 428 570 440 Z" fill="#0d0a2a"/>`);

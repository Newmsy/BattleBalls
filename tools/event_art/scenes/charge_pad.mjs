// Charge pad: a rest stop. A sleepy critter dozes on a glowing green charging
// pad in a cosy nook; it's where knocked-out critters revive and boons get polished.
import { ball, shade, INK } from "../../brand/parts.mjs";
import { svg, blurs, badge, sparkle, stars, sleepyEye, blush, rng, RARITY } from "./_shop_charge_pad_glow_chest_parts.mjs";

const G = "#5CFF9A";
const PX = 360, PY = 336; // pad centre

function room() {
  return `
  <defs>
    <linearGradient id="wallG" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#141038"/><stop offset="1" stop-color="#231a55"/></linearGradient>
    <radialGradient id="nookG" cx="0.5" cy="0.85" r="0.8"><stop offset="0" stop-color="#1f5a5a"/><stop offset="0.45" stop-color="#1a2a55"/><stop offset="1" stop-color="#110d2e"/></radialGradient>
    <linearGradient id="floorG" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#1e1848"/><stop offset="1" stop-color="#0D0F26"/></linearGradient>
    <clipPath id="nookC"><path d="M 140 330 L 140 170 Q 140 44 360 44 Q 580 44 580 170 L 580 330 Z"/></clipPath>
  </defs>
  <rect width="720" height="440" fill="url(#wallG)"/>
  <g opacity="0.25" stroke="#3a2f7a" stroke-width="2">${Array.from({ length: 12 }, (_, k) => `<line x1="${k * 64}" y1="0" x2="${k * 64}" y2="330"/>`).join("")}</g>
  <path d="M 140 330 L 140 170 Q 140 44 360 44 Q 580 44 580 170 L 580 330 Z" fill="url(#nookG)"/>
  <g clip-path="url(#nookC)">
    ${window_(250, 140)}
    ${shelfR()}
    <path d="M 140 70 Q 360 30 580 70" fill="none" stroke="#000" stroke-width="40" opacity="0.35" filter="url(#bl12)"/>
  </g>
  <path d="M 140 330 L 140 170 Q 140 44 360 44 Q 580 44 580 170 L 580 330" fill="none" stroke="#3a2f7a" stroke-width="14"/>
  <path d="M 140 330 L 140 170 Q 140 44 360 44 Q 580 44 580 170 L 580 330" fill="none" stroke="#6a5ac0" stroke-width="3" opacity="0.7"/>
  <path d="M 0 322 L 720 322 L 720 440 L 0 440 Z" fill="url(#floorG)"/>
  <rect x="0" y="320" width="720" height="5" fill="#3a2f7a"/>
  <ellipse cx="${PX}" cy="${PY + 14}" rx="290" ry="70" fill="#3a2a6a"/>
  <ellipse cx="${PX}" cy="${PY + 14}" rx="290" ry="70" fill="none" stroke="#6a4ab0" stroke-width="5" stroke-dasharray="2 9" stroke-linecap="round" opacity="0.8"/>
  <ellipse cx="${PX}" cy="${PY + 14}" rx="270" ry="62" fill="none" stroke="#FF8AD0" stroke-width="2" opacity="0.35"/>`;
}

function window_(cx, cy) {
  return `
  <circle cx="${cx}" cy="${cy}" r="50" fill="#2c2170"/>
  <circle cx="${cx}" cy="${cy}" r="50" fill="#0D0F26" opacity="0.5"/>
  <g clip-path="url(#winC)">${stars(21, 14, cx - 50, cy - 50, cx + 50, cy + 50)}</g>
  <defs><clipPath id="winC"><circle cx="${cx}" cy="${cy}" r="48"/></clipPath><mask id="moonM"><rect x="${cx - 50}" y="${cy - 50}" width="100" height="100" fill="#fff"/><circle cx="${cx + 20}" cy="${cy - 22}" r="17" fill="#000"/></mask></defs>
  <circle cx="${cx + 12}" cy="${cy - 16}" r="26" fill="#fff3c0" opacity="0.4" filter="url(#bl8)"/>
  <circle cx="${cx + 12}" cy="${cy - 16}" r="18" fill="#fff3c0" mask="url(#moonM)"/>
  <line x1="${cx - 50}" y1="${cy}" x2="${cx + 50}" y2="${cy}" stroke="#3a2f7a" stroke-width="5"/>
  <line x1="${cx}" y1="${cy - 50}" x2="${cx}" y2="${cy + 50}" stroke="#3a2f7a" stroke-width="5"/>
  <circle cx="${cx}" cy="${cy}" r="50" fill="none" stroke="#5a4aa0" stroke-width="8"/>
  <path d="M ${cx - 38} ${cy + 46} Q ${cx} ${cy + 64} ${cx + 38} ${cy + 46}" fill="none" stroke="#2a2060" stroke-width="6" stroke-linecap="round"/>
  ${plant(cx - 2, cy + 52)}`;
}

function plant(x, y) {
  return `<path d="M ${x - 10} ${y - 20} L ${x + 10} ${y - 20} L ${x + 8} ${y} L ${x - 8} ${y} Z" fill="#c25a3a" stroke="#5a2216" stroke-width="2"/>
    <path d="M ${x} ${y - 20} Q ${x - 22} ${y - 34} ${x - 20} ${y - 46} Q ${x - 6} ${y - 36} ${x} ${y - 20} Z" fill="#3ac77a"/>
    <path d="M ${x} ${y - 20} Q ${x + 20} ${y - 40} ${x + 14} ${y - 54} Q ${x + 2} ${y - 40} ${x} ${y - 20} Z" fill="#5CFF9A"/>
    <path d="M ${x} ${y - 20} Q ${x - 2} ${y - 46} ${x + 2} ${y - 60} Q ${x + 6} ${y - 40} ${x} ${y - 20} Z" fill="#2fa865"/>`;
}

// Right-hand shelf: a polishing cushion with a boon badge and a little rag.
function shelfR() {
  return `
  <rect x="470" y="252" width="110" height="10" rx="2" fill="#6a4532"/><rect x="470" y="252" width="110" height="3" fill="#a87a56"/>
  <rect x="470" y="262" width="110" height="10" fill="#000" opacity="0.25" filter="url(#bl3)"/>
  <ellipse cx="524" cy="246" rx="32" ry="9" fill="#7a2e6a"/>
  <path d="M 492 246 Q 494 234 524 234 Q 554 234 556 246 Z" fill="#a24a8c"/>
  ${badge(524, 212, 18, RARITY.rare, { glow: 1.3 })}
  ${sparkle(548, 194, 6)}${sparkle(502, 202, 4)}
  <path d="M 556 252 Q 560 238 572 240 Q 580 246 576 252 Z" fill="#e9dcc6" stroke="#8a7a6a" stroke-width="1.5"/>`;
}

// Warm fairy lights following the arch.
function archLights() {
  let out = "", glow = "";
  const n = 28;
  const q = (u, p0, c, p2) => (1 - u) ** 2 * p0 + 2 * (1 - u) * u * c + u * u * p2;
  for (let k = 1; k < n; k++) {
    const seg = (k / n) * 4;
    let x, y;
    if (seg < 1) { x = 152; y = 310 - seg * 140; }
    else if (seg < 2) { const u = seg - 1; x = q(u, 152, 152, 360); y = q(u, 170, 56, 56); }
    else if (seg < 3) { const u = seg - 2; x = q(u, 360, 568, 568); y = q(u, 56, 56, 170); }
    else { x = 568; y = 170 + (seg - 3) * 140; }
    const wob = (k % 2 ? 5 : -2);
    const c = k % 3 ? "#FFD34E" : "#FF9A6A";
    glow += `<circle cx="${x}" cy="${y + wob}" r="9" fill="${c}"/>`;
    out += `<circle cx="${x}" cy="${y + wob}" r="3" fill="#fff4c8"/>`;
  }
  return `<g opacity="0.55" filter="url(#bl6)">${glow}</g>${out}`;
}

function pad() {
  const rings = [138, 104, 70, 38];
  return `
  <defs>
    <linearGradient id="padSide" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2a3a5a"/><stop offset="1" stop-color="#121a33"/></linearGradient>
    <radialGradient id="padTop" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#2a6a5a"/><stop offset="0.7" stop-color="#1d3550"/><stop offset="1" stop-color="#18263f"/></radialGradient>
    <linearGradient id="beam" x1="0" y1="1" x2="0" y2="0"><stop offset="0" stop-color="${G}" stop-opacity="0.55"/><stop offset="0.6" stop-color="${G}" stop-opacity="0.12"/><stop offset="1" stop-color="${G}" stop-opacity="0"/></linearGradient>
  </defs>
  <ellipse cx="${PX}" cy="${PY + 26}" rx="170" ry="40" fill="#000" opacity="0.45" filter="url(#bl6)"/>
  <ellipse cx="${PX}" cy="${PY}" rx="200" ry="56" fill="${G}" opacity="0.25" filter="url(#bl24)"/>
  <path d="M ${PX - 156} ${PY} L ${PX - 156} ${PY + 16} A 156 38 0 0 0 ${PX + 156} ${PY + 16} L ${PX + 156} ${PY} Z" fill="url(#padSide)" stroke="#0a0f20" stroke-width="2"/>
  <path d="M ${PX - 150} ${PY + 18} A 150 34 0 0 0 ${PX + 150} ${PY + 18}" fill="none" stroke="${G}" stroke-width="2.5" opacity="0.8"/>
  ${[-90, -45, 0, 45, 90].map((d) => `<circle cx="${PX + d * 1.4}" cy="${PY + 18 + 34 * Math.sqrt(1 - (d * 1.4 / 150) ** 2)}" r="3" fill="${G}"/>`).join("")}
  <ellipse cx="${PX}" cy="${PY}" rx="156" ry="38" fill="url(#padTop)" stroke="#5a6a9a" stroke-width="2.5"/>
  <g filter="url(#bl4)">${rings.map((r) => `<ellipse cx="${PX}" cy="${PY}" rx="${r}" ry="${r * 0.245}" fill="none" stroke="${G}" stroke-width="6"/>`).join("")}</g>
  ${rings.map((r, k) => `<ellipse cx="${PX}" cy="${PY}" rx="${r}" ry="${r * 0.245}" fill="none" stroke="#d6ffe6" stroke-width="${2 - k * 0.2}" ${k === 1 ? 'stroke-dasharray="14 8"' : ""}/>`).join("")}
  <path d="M ${PX - 130} ${PY} L ${PX - 110} ${PY - 250} L ${PX + 110} ${PY - 250} L ${PX + 130} ${PY} Z" fill="url(#beam)" opacity="0.7" filter="url(#bl6)"/>`;
}

function motes() {
  const r = rng(9);
  let out = "";
  for (let k = 0; k < 14; k++) {
    const x = PX - 120 + r() * 240, y = PY - 30 - r() * 220, s = 3 + r() * 5;
    const o = (0.4 + r() * 0.6).toFixed(2);
    if (k % 3 === 0)
      out += `<g opacity="${o}"><rect x="${x - s}" y="${y - s * 0.35}" width="${s * 2}" height="${s * 0.7}" rx="${s * 0.3}" fill="${G}"/><rect x="${x - s * 0.35}" y="${y - s}" width="${s * 0.7}" height="${s * 2}" rx="${s * 0.3}" fill="${G}"/></g>`;
    else out += `<circle cx="${x}" cy="${y}" r="${s * 0.5}" fill="#c8ffdf" opacity="${o}"/>`;
  }
  return `<g filter="url(#bl1)">${out}</g>`;
}

function sleeper(cx, cy, r) {
  const col = "#8FB4FF";
  const ey = cy - r * 0.08;
  const capTip = [cx + r * 1.05, cy - r * 0.55];
  return `
  <defs>
    <linearGradient id="greenUnder" x1="0" y1="0" x2="0" y2="1"><stop offset="0.45" stop-color="${G}" stop-opacity="0"/><stop offset="1" stop-color="${G}" stop-opacity="0.55"/></linearGradient>
  </defs>
  ${ball(cx, cy, r, col, { sx: 1.1, sy: 0.9, glow: false })}
  <ellipse cx="${cx}" cy="${cy}" rx="${r * 1.1}" ry="${r * 0.9}" fill="url(#greenUnder)"/>
  ${sleepyEye(cx - r * 0.34, ey, r * 0.17, r * 0.07)}${sleepyEye(cx + r * 0.34, ey, r * 0.17, r * 0.07)}
  ${blush(cx - r * 0.6, ey + r * 0.22, r * 0.15)}${blush(cx + r * 0.6, ey + r * 0.22, r * 0.15)}
  <ellipse cx="${cx}" cy="${cy + r * 0.32}" rx="${r * 0.09}" ry="${r * 0.11}" fill="${INK}"/>
  <ellipse cx="${cx + r * 0.2}" cy="${cy + r * 0.26}" rx="${r * 0.06}" ry="${r * 0.08}" fill="#cfefff" stroke="#7ab0d0" stroke-width="1.5" opacity="0.9"/>
  <g transform="rotate(-22 ${cx - r * 0.5} ${cy - r * 0.5})">
    <rect x="${cx - r * 0.72}" y="${cy - r * 0.6}" width="${r * 0.46}" height="${r * 0.18}" rx="${r * 0.08}" fill="#ffe2c4" stroke="#b08a6a" stroke-width="1.5"/>
    <rect x="${cx - r * 0.56}" y="${cy - r * 0.6}" width="${r * 0.14}" height="${r * 0.18}" fill="#f0c8a4"/>
  </g>
  <path d="M ${cx - r * 0.82} ${cy - r * 0.56} Q ${cx - r * 0.2} ${cy - r * 1.18} ${cx + r * 0.5} ${cy - r * 0.86} Q ${cx + r * 0.9} ${cy - r * 0.9} ${capTip[0]} ${capTip[1]} Q ${cx + r * 0.6} ${cy - r * 0.62} ${cx + r * 0.6} ${cy - r * 0.62} Q ${cx} ${cy - r * 0.86} ${cx - r * 0.82} ${cy - r * 0.56} Z" fill="#5a4ab0" stroke="#231a55" stroke-width="2.5"/>
  <path d="M ${cx - r * 0.86} ${cy - r * 0.52} Q ${cx - r * 0.1} ${cy - r * 0.98} ${cx + r * 0.64} ${cy - r * 0.62}" fill="none" stroke="#e9dcc6" stroke-width="${r * 0.14}" stroke-linecap="round"/>
  <path d="M ${cx - r * 0.3} ${cy - r * 0.96} Q ${cx + r * 0.1} ${cy - r * 1.06} ${cx + r * 0.4} ${cy - r * 0.92}" fill="none" stroke="#FFD34E" stroke-width="3" stroke-dasharray="1 8" stroke-linecap="round"/>
  <circle cx="${capTip[0]}" cy="${capTip[1] + 4}" r="${r * 0.13}" fill="#FFD34E" stroke="#a07a10" stroke-width="2"/>
  ${zz(cx + r * 0.95, cy - r * 1.15, 13, 0.95)}${zz(cx + r * 1.18, cy - r * 1.6, 9.5, 0.75)}${zz(cx + r * 1.32, cy - r * 1.98, 7, 0.55)}`;
}

function zz(x, y, s, o) {
  return `<path d="M ${x - s} ${y - s} L ${x + s} ${y - s} L ${x - s} ${y + s} L ${x + s} ${y + s}" fill="none" stroke="#d6ffe6" stroke-width="${s * 0.32}" stroke-linecap="round" stroke-linejoin="round" opacity="${o}"/>`;
}

// Battery charge pips floating above the sleeper.
function chargeMeter(cx, cy) {
  const n = 5, w = 14, gap = 4, on = 3;
  let out = `<rect x="${cx - (n * (w + gap)) / 2 - 6}" y="${cy - 12}" width="${n * (w + gap) + 8}" height="24" rx="8" fill="#0d1a2a" stroke="${G}" stroke-width="2.5"/>
    <rect x="${cx + (n * (w + gap)) / 2 + 2}" y="${cy - 5}" width="6" height="10" rx="2" fill="${G}"/>`;
  for (let k = 0; k < n; k++) {
    const x = cx - (n * (w + gap)) / 2 + k * (w + gap);
    out += `<rect x="${x}" y="${cy - 7}" width="${w}" height="14" rx="3" fill="${G}" opacity="${k < on ? 1 : k === on ? 0.45 : 0.12}"/>`;
  }
  return `<g><rect x="${cx - 60}" y="${cy - 18}" width="120" height="36" rx="12" fill="${G}" opacity="0.3" filter="url(#bl6)"/>${out}</g>`;
}

function lamp(x, y) {
  return `<circle cx="${x}" cy="${y - 70}" r="80" fill="#ffb347" opacity="0.18" filter="url(#bl24)"/>
    <ellipse cx="${x}" cy="${y}" rx="26" ry="6" fill="#000" opacity="0.4"/>
    <rect x="${x - 3}" y="${y - 70}" width="6" height="70" fill="#3a2a4a"/>
    <ellipse cx="${x}" cy="${y - 2}" rx="18" ry="5" fill="#4a3a5a"/>
    <path d="M ${x - 20} ${y - 70} L ${x - 30} ${y - 104} L ${x + 30} ${y - 104} L ${x + 20} ${y - 70} Z" fill="#ff9a4a" stroke="#7a3a10" stroke-width="2"/>
    <path d="M ${x - 20} ${y - 70} L ${x + 20} ${y - 70}" stroke="#fff0c0" stroke-width="3"/>`;
}

function cushions() {
  return `
  <ellipse cx="96" cy="368" rx="72" ry="16" fill="#000" opacity="0.4" filter="url(#bl4)"/>
  <path d="M 36 368 Q 30 318 92 314 Q 156 316 150 362 Q 92 380 36 368 Z" fill="#c24a7a" stroke="#4a1230" stroke-width="2.5"/>
  <path d="M 50 340 Q 92 326 136 340" fill="none" stroke="#ff8ad0" stroke-width="2" opacity="0.6"/>
  <path d="M 70 330 Q 66 290 112 288 Q 158 292 150 330 Q 112 342 70 330 Z" fill="#3a8a9a" stroke="#0e3a44" stroke-width="2.5"/>
  <circle cx="110" cy="314" r="4" fill="#0e3a44"/>
  <path d="M 120 380 Q 160 360 210 384 Q 180 400 120 380 Z" fill="#e9dcc6" opacity="0.85"/>`;
}

export default () =>
  svg(`${blurs()}
  ${room()}
  ${archLights()}
  ${lamp(628, 330)}
  ${cushions()}
  ${pad()}
  ${motes()}
  ${sleeper(PX, 284, 70)}
  ${chargeMeter(PX - 6, 128)}
  ${sparkle(250, 270, 6, "#c8ffdf")}${sparkle(472, 230, 5, "#c8ffdf")}
  <path d="M -10 440 Q 40 380 20 330 Q 70 370 60 440 Z" fill="#0a1a18"/>
  <path d="M 730 440 Q 680 390 700 350 Q 650 390 670 440 Z" fill="#0a1a18"/>`);

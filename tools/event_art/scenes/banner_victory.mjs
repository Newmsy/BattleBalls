// Victory banner: the trio stands on top of the Champion's tower at night,
// cheering in front of a giant glowing trophy, the middle one crowned, while
// fireworks burst overhead and the valley glitters far below.
import { svg, blurs, sparkle } from "./_shop_charge_pad_glow_chest_parts.mjs";
import { critter, shadow, sky, edges, FAM, rng, star5 } from "./_banner_parts.mjs";

const GOLD = "#ffd34e";
const TY = 312; // tower top surface

function firework(cx, cy, r, col, seed, n = 18) {
  const R = rng(seed);
  let lines = "", dots = "";
  for (let k = 0; k < n; k++) {
    const a = (k / n) * Math.PI * 2 + R() * 0.15;
    const L = r * (0.75 + R() * 0.25);
    const x1 = cx + Math.cos(a) * L * 0.3, y1 = cy + Math.sin(a) * L * 0.3;
    const x2 = cx + Math.cos(a) * L, y2 = cy + Math.sin(a) * L + L * 0.08;
    lines += `<line x1="${x1.toFixed(1)}" y1="${y1.toFixed(1)}" x2="${x2.toFixed(1)}" y2="${y2.toFixed(1)}"/>`;
    dots += `<circle cx="${x2.toFixed(1)}" cy="${y2.toFixed(1)}" r="${(r * 0.035).toFixed(1)}" fill="#fff"/>`;
    if (k % 2) dots += `<circle cx="${(x2 + Math.cos(a) * r * 0.12).toFixed(1)}" cy="${(y2 + Math.sin(a) * r * 0.12 + r * 0.06).toFixed(1)}" r="${(r * 0.02).toFixed(1)}" fill="${col}"/>`;
  }
  return `<g>
    <circle cx="${cx}" cy="${cy}" r="${r * 0.9}" fill="${col}" opacity="0.22" filter="url(#bl24)"/>
    <g stroke="${col}" stroke-width="${r * 0.06}" stroke-linecap="round" opacity="0.5" filter="url(#bl3)">${lines}</g>
    <g stroke="${col}" stroke-width="${r * 0.025}" stroke-linecap="round">${lines}</g>
    ${dots}
    <circle cx="${cx}" cy="${cy}" r="${r * 0.08}" fill="#fff"/>
  </g>`;
}

function backdrop() {
  // Valley far below: rolling hills with tiny lights.
  const R = rng(14);
  let lights = "";
  for (let k = 0; k < 60; k++) {
    const x = R() * 720, y = 330 + R() * 90;
    lights += `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="${(0.8 + R() * 1.4).toFixed(1)}" fill="${["#ffcf6b", "#3EE6FF", "#ff8ad0"][k % 3]}" opacity="${(0.4 + R() * 0.5).toFixed(2)}"/>`;
  }
  return `
  <defs>
    <linearGradient id="vSky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0D0F26"/><stop offset="0.55" stop-color="#231a66"/><stop offset="1" stop-color="#4a2a8a"/></linearGradient>
  </defs>
  <rect width="720" height="440" fill="url(#vSky)"/>
  ${sky(88, 130, 0, 0, 720, 300)}
  <path d="M 0 330 Q 120 300 250 320 Q 380 296 500 318 Q 620 298 720 316 L 720 440 L 0 440 Z" fill="#1c1652"/>
  <path d="M 0 370 Q 140 346 300 364 Q 460 340 720 366 L 720 440 L 0 440 Z" fill="#150f40"/>
  ${lights}`;
}

// Parapet blocks along the front (front=true) or back half of the tower top.
function crenels(front) {
  const w = 240;
  let out = "";
  for (let k = -5; k <= 5; k++) {
    const x = 360 + k * 44;
    const t = Math.abs(k) / 5.5;
    const y = TY + (front ? 1 : -1) * 30 * Math.sqrt(1 - t * t) - 2;
    out += `<rect x="${x - 14}" y="${y - 8}" width="28" height="22" rx="3" fill="${front ? "#3a3290" : "#2a2470"}" stroke="#120f30" stroke-width="2"/>
      <rect x="${x - 12}" y="${y - 7}" width="24" height="4" rx="2" fill="#8a80e0" opacity="${front ? 0.6 : 0.35}"/>`;
  }
  return out;
}

function tower() {
  // A broad round tower top seen from slightly above, crenellated, tapering down.
  const w = 240;
  let wins = "", flags = "";
  for (const [x, y] of [[300, 372], [360, 380], [420, 372], [330, 414], [390, 414]]) {
    wins += `<circle cx="${x}" cy="${y + 4}" r="18" fill="#ffcf6b" opacity="0.3" filter="url(#bl6)"/><path d="M ${x - 7} ${y + 14} L ${x - 7} ${y} A 7 7 0 0 1 ${x + 7} ${y} L ${x + 7} ${y + 14} Z" fill="#ffcf6b"/>`;
  }
  for (const [x, d, col] of [[130, -1, "#ff5a6e"], [590, 1, "#3EE6FF"]]) {
    flags += `<line x1="${x}" y1="${TY + 10}" x2="${x}" y2="${TY - 120}" stroke="#c8b8ff" stroke-width="4" stroke-linecap="round"/>
      <circle cx="${x}" cy="${TY - 124}" r="5" fill="${GOLD}"/>
      <path d="M ${x} ${TY - 116} Q ${x + d * 30} ${TY - 124} ${x + d * 62} ${TY - 108} Q ${x + d * 48} ${TY - 96} ${x + d * 60} ${TY - 82} Q ${x + d * 30} ${TY - 90} ${x} ${TY - 80} Z" fill="${col}" stroke="#120f30" stroke-width="2"/>
      <polygon points="${star5(x + d * 26, TY - 98, 7)}" fill="#fff" opacity="0.9"/>`;
  }
  return `
  <defs>
    <linearGradient id="vTower" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1c1652"/><stop offset="0.4" stop-color="#3a3290"/><stop offset="0.7" stop-color="#2a2470"/><stop offset="1" stop-color="#151040"/></linearGradient>
    <radialGradient id="vTop" cx="0.5" cy="0.4" r="0.6"><stop offset="0" stop-color="#5a4fb8"/><stop offset="1" stop-color="#2a2470"/></radialGradient>
  </defs>
  <path d="M ${360 - w} ${TY} L ${360 - w + 60} 460 L ${360 + w - 60} 460 L ${360 + w} ${TY} Z" fill="url(#vTower)" stroke="#120f30" stroke-width="3"/>
  ${[350, 392, 434].map((y) => `<line x1="${360 - w + (y - TY) * 0.24}" y1="${y}" x2="${360 + w - (y - TY) * 0.24}" y2="${y}" stroke="#120f30" stroke-width="2" opacity="0.5"/>`).join("")}
  ${wins}
  <ellipse cx="360" cy="${TY}" rx="${w}" ry="34" fill="url(#vTop)" stroke="#120f30" stroke-width="3"/>
  <ellipse cx="360" cy="${TY}" rx="${w - 30}" ry="24" fill="none" stroke="${GOLD}" stroke-width="3" opacity="0.7"/>
  <ellipse cx="360" cy="${TY}" rx="${w - 30}" ry="24" fill="none" stroke="${GOLD}" stroke-width="10" opacity="0.25" filter="url(#bl4)"/>
  ${crenels(false)}
  ${flags}`;
}

function trophy() {
  const x = 360, y = 150;
  return `
  <defs>
    <linearGradient id="vGold" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#b8701a"/><stop offset="0.3" stop-color="#ffe48a"/><stop offset="0.55" stop-color="${GOLD}"/><stop offset="1" stop-color="#a0601a"/></linearGradient>
    <radialGradient id="vHalo" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#fff4c0" stop-opacity="0.8"/><stop offset="0.4" stop-color="${GOLD}" stop-opacity="0.35"/><stop offset="1" stop-color="${GOLD}" stop-opacity="0"/></radialGradient>
  </defs>
  <circle cx="${x}" cy="${y}" r="190" fill="url(#vHalo)"/>
  ${Array.from({ length: 14 }, (_, k) => {
    const a = (k / 14) * Math.PI * 2;
    return `<polygon points="${x},${y} ${x + Math.cos(a - 0.07) * 230},${y + Math.sin(a - 0.07) * 230} ${x + Math.cos(a + 0.07) * 230},${y + Math.sin(a + 0.07) * 230}" fill="#fff4c0" opacity="0.12"/>`;
  }).join("")}
  <!-- handles -->
  <path d="M ${x - 52} ${y - 52} Q ${x - 102} ${y - 50} ${x - 92} ${y - 6} Q ${x - 84} ${y + 22} ${x - 44} ${y + 18}" fill="none" stroke="#6a3e0a" stroke-width="16" stroke-linecap="round"/>
  <path d="M ${x - 52} ${y - 52} Q ${x - 102} ${y - 50} ${x - 92} ${y - 6} Q ${x - 84} ${y + 22} ${x - 44} ${y + 18}" fill="none" stroke="url(#vGold)" stroke-width="10" stroke-linecap="round"/>
  <path d="M ${x + 52} ${y - 52} Q ${x + 102} ${y - 50} ${x + 92} ${y - 6} Q ${x + 84} ${y + 22} ${x + 44} ${y + 18}" fill="none" stroke="#6a3e0a" stroke-width="16" stroke-linecap="round"/>
  <path d="M ${x + 52} ${y - 52} Q ${x + 102} ${y - 50} ${x + 92} ${y - 6} Q ${x + 84} ${y + 22} ${x + 44} ${y + 18}" fill="none" stroke="url(#vGold)" stroke-width="10" stroke-linecap="round"/>
  <!-- cup -->
  <path d="M ${x - 66} ${y - 66} L ${x + 66} ${y - 66} Q ${x + 66} ${y + 30} ${x + 14} ${y + 46} L ${x + 12} ${y + 70} L ${x - 12} ${y + 70} L ${x - 14} ${y + 46} Q ${x - 66} ${y + 30} ${x - 66} ${y - 66} Z" fill="url(#vGold)" stroke="#6a3e0a" stroke-width="3.5" stroke-linejoin="round"/>
  <ellipse cx="${x}" cy="${y - 66}" rx="66" ry="12" fill="#b8701a" stroke="#6a3e0a" stroke-width="3"/>
  <ellipse cx="${x}" cy="${y - 64}" rx="56" ry="7" fill="#6a3e0a"/>
  <path d="M ${x - 44} ${y - 50} Q ${x - 48} ${y + 4} ${x - 18} ${y + 30}" fill="none" stroke="#fff8d8" stroke-width="7" stroke-linecap="round" opacity="0.75"/>
  <polygon points="${star5(x, y - 14, 24)}" fill="#fff4c0" stroke="#8a5210" stroke-width="2.5" stroke-linejoin="round"/>
  <!-- base -->
  <path d="M ${x - 34} ${y + 70} L ${x + 34} ${y + 70} L ${x + 44} ${y + 92} L ${x - 44} ${y + 92} Z" fill="url(#vGold)" stroke="#6a3e0a" stroke-width="3"/>
  <rect x="${x - 54}" y="${y + 90}" width="108" height="16" rx="4" fill="#3a2a7a" stroke="#120f30" stroke-width="2.5"/>
  ${sparkle(x + 40, y - 40, 10, "#fff")}${sparkle(x - 30, y + 46, 6, "#fff", 0.8)}`;
}

function crown(cx, cy, s) {
  return `<g transform="rotate(-8 ${cx} ${cy})">
    <circle cx="${cx}" cy="${cy}" r="${s * 1.2}" fill="${GOLD}" opacity="0.4" filter="url(#bl8)"/>
    <path d="M ${cx - s} ${cy + s * 0.5} L ${cx - s} ${cy - s * 0.4} L ${cx - s * 0.5} ${cy + s * 0.05} L ${cx} ${cy - s * 0.65} L ${cx + s * 0.5} ${cy + s * 0.05} L ${cx + s} ${cy - s * 0.4} L ${cx + s} ${cy + s * 0.5} Z" fill="url(#vGold)" stroke="#6a3e0a" stroke-width="3" stroke-linejoin="round"/>
    ${[-1, 0, 1].map((d) => `<circle cx="${cx + d * s}" cy="${cy - (d ? s * 0.4 : s * 0.65)}" r="${s * 0.13}" fill="#fff4c0" stroke="#6a3e0a" stroke-width="2"/>`).join("")}
    <circle cx="${cx}" cy="${cy + s * 0.2}" r="${s * 0.16}" fill="#ff5a6e" stroke="#6a3e0a" stroke-width="2"/>
  </g>`;
}

function confetti() {
  const R = rng(6);
  let out = "";
  for (let k = 0; k < 46; k++) {
    const x = 60 + R() * 600, y = 20 + R() * 300;
    if (Math.abs(x - 360) < 80 && y > 60 && y < 260) continue;
    const c = ["#ff5a6e", "#3EE6FF", GOLD, "#5CFF9A", "#ff8ad0", "#b98cff"][k % 6];
    out += `<rect x="${x.toFixed(1)}" y="${y.toFixed(1)}" width="${(4 + R() * 5).toFixed(1)}" height="${(2.5 + R() * 2.5).toFixed(1)}" rx="1" fill="${c}" opacity="${(0.6 + R() * 0.4).toFixed(2)}" transform="rotate(${(R() * 180).toFixed(0)} ${x.toFixed(1)} ${y.toFixed(1)})"/>`;
  }
  return out;
}

export default () =>
  svg(`${blurs()}
  ${backdrop()}
  ${firework(130, 92, 76, "#ff8ad0", 1, 20)}
  ${firework(600, 78, 86, "#3EE6FF", 2, 22)}
  ${firework(232, 30, 40, GOLD, 3, 14)}
  ${firework(506, 196, 44, "#5CFF9A", 4, 14)}
  ${firework(66, 230, 36, GOLD, 5, 12)}
  ${trophy()}
  ${tower()}
  ${confetti()}
  <!-- the champions -->
  ${shadow(258, 318, 46, 0.5)}${shadow(462, 318, 46, 0.5)}${shadow(360, 330, 56, 0.5)}
  <g data-layer="sides" data-move="bob 6 0.9 0">
  ${critter(258, 282, 46, FAM.sea, { acc: "fin", mood: "cheer", tilt: -10, rim: GOLD, rimSide: 1 })}
  ${critter(462, 282, 46, FAM.nature, { acc: "leaf", mood: "cheer", tilt: 10, rim: GOLD, rimSide: -1 })}
  </g>
  <g data-layer="champ" data-move="idle 7 0.9 0.5">${critter(360, 286, 56, FAM.fire, { mood: "cheer", rim: GOLD, rimSide: 1 })}</g>
  <g data-layer="crenels">${crenels(true)}</g>
  <g data-layer="crown" data-follow="champ">${crown(360, 222, 30)}</g>
  ${sparkle(198, 240, 9, "#fff4c0")}${sparkle(524, 236, 9, "#fff4c0")}${sparkle(410, 216, 7, "#fff")}
  ${edges(0.9)}`);

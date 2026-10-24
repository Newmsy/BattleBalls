// Tier-up banner, power-up: a critter rises from a glowing launch pad inside a
// pillar of light, wrapped in rising rings of energy, with five gold stars
// arcing above its head and streaks shooting upward.
import { svg, blurs, sparkle } from "./_shop_charge_pad_glow_chest_parts.mjs";
import { critter, sky, motes, edges, FAM, goldStar, rng } from "./_banner_parts.mjs";

const CX = 360, CY = 236, R = 66;
const GOLD = "#ffd34e", CYAN = "#3EE6FF", VIO = "#b98cff";

function backdrop() {
  let streaks = "";
  const r = rng(21);
  for (let k = 0; k < 34; k++) {
    const x = 120 + r() * 480, y = 30 + r() * 340, L = 30 + r() * 90;
    if (Math.abs(x - CX) < 70) continue;
    const c = [CYAN, VIO, GOLD][k % 3];
    streaks += `<line x1="${x.toFixed(1)}" y1="${y.toFixed(1)}" x2="${x.toFixed(1)}" y2="${(y + L).toFixed(1)}" stroke="${c}" stroke-width="${(1.5 + r() * 2.5).toFixed(1)}" stroke-linecap="round" opacity="${(0.25 + r() * 0.45).toFixed(2)}"/>`;
  }
  return `
  <defs>
    <radialGradient id="tuBg" cx="0.5" cy="0.55" r="0.8"><stop offset="0" stop-color="#3a2a86"/><stop offset="0.35" stop-color="#231c62"/><stop offset="0.7" stop-color="#131036"/><stop offset="1" stop-color="#0D0F26"/></radialGradient>
    <linearGradient id="tuPillar" x1="0" y1="1" x2="0" y2="0"><stop offset="0" stop-color="#fff4c0" stop-opacity="0.75"/><stop offset="0.5" stop-color="${VIO}" stop-opacity="0.35"/><stop offset="1" stop-color="${CYAN}" stop-opacity="0"/></linearGradient>
  </defs>
  <rect width="720" height="440" fill="url(#tuBg)"/>
  ${sky(64, 120, 0, 0, 720, 330)}
  <!-- floating rock islands at the edges -->
  <path d="M 40 300 Q 100 280 170 296 L 150 318 Q 110 340 70 320 Z" fill="#1c1652"/>
  <path d="M 560 268 Q 620 252 690 266 L 676 284 Q 630 304 580 286 Z" fill="#1c1652"/>
  <!-- pillar of light -->
  <path d="M ${CX - 130} 360 L ${CX - 70} -10 L ${CX + 70} -10 L ${CX + 130} 360 Z" fill="url(#tuPillar)" filter="url(#bl16)"/>
  <path d="M ${CX - 60} 360 L ${CX - 34} -10 L ${CX + 34} -10 L ${CX + 60} 360 Z" fill="url(#tuPillar)" opacity="0.8" filter="url(#bl6)"/>
  ${streaks}`;
}

function pad() {
  const y = 340;
  let hex = "";
  for (let k = 0; k < 6; k++) {
    const a = (k / 6) * Math.PI * 2 + Math.PI / 6;
    hex += `${CX + Math.cos(a) * 170},${y + Math.sin(a) * 40} `;
  }
  let ticks = "";
  for (let k = 0; k < 24; k++) {
    const a = (k / 24) * Math.PI * 2;
    ticks += `<circle cx="${(CX + Math.cos(a) * 120).toFixed(1)}" cy="${(y + Math.sin(a) * 28).toFixed(1)}" r="2.5" fill="${k % 2 ? CYAN : GOLD}"/>`;
  }
  return `
  <polygon points="${hex}" fill="#1e1850" stroke="#4a4294" stroke-width="3"/>
  <polygon points="${hex}" fill="none" stroke="${VIO}" stroke-width="8" opacity="0.4" filter="url(#bl6)"/>
  <ellipse cx="${CX}" cy="${y}" rx="130" ry="30" fill="${GOLD}" opacity="0.35" filter="url(#bl12)"/>
  <ellipse cx="${CX}" cy="${y}" rx="120" ry="28" fill="none" stroke="#fff4c0" stroke-width="2" opacity="0.7"/>
  ${ticks}
  <ellipse cx="${CX}" cy="${y}" rx="76" ry="18" fill="#fff4c0" opacity="0.9" filter="url(#bl6)"/>
  <ellipse cx="${CX}" cy="${y}" rx="44" ry="10" fill="#fff"/>`;
}

// Energy rings around the critter at several heights; back halves drawn
// before the critter, front halves after, so they wrap around it.
const RINGS = [
  [338, 128, 0.9, GOLD, 5],
  [306, 112, 0.8, CYAN, 4.5],
  [280, 98, 0.7, VIO, 4],
  [150, 74, 0.45, CYAN, 3],
];
function ringHalf(front) {
  return RINGS.map(([y, rx, o, col, w]) => {
    const ry = rx * 0.22;
    const d = front
      ? `M ${CX - rx} ${y} A ${rx} ${ry} 0 0 0 ${CX + rx} ${y}`
      : `M ${CX - rx} ${y} A ${rx} ${ry} 0 0 1 ${CX + rx} ${y}`;
    return `<path d="${d}" fill="none" stroke="${col}" stroke-width="${w * 3}" opacity="${o * 0.55}" filter="url(#bl4)"/>
      <path d="${d}" fill="none" stroke="#fff" stroke-width="${w * 0.7}" opacity="${o * (front ? 1 : 0.6)}" stroke-linecap="round"/>`;
  }).join("");
}

function starArc() {
  // Five gold stars on an arc over the head; the middle one biggest.
  const pts = [
    [214, 130, 20, -0.25],
    [276, 82, 24, -0.12],
    [CX, 58, 32, 0],
    [444, 82, 24, 0.12],
    [506, 130, 20, 0.25],
  ];
  return `<path d="M 214 130 Q ${CX} 10 506 130" fill="none" stroke="${GOLD}" stroke-width="2" stroke-dasharray="3 7" opacity="0.5"/>` +
    pts.map(([x, y, s, rot]) => goldStar(x, y, s, { rot })).join("");
}

// Rising chevrons either side of the critter.
function chevrons() {
  let out = "";
  for (const x of [252, 468]) {
    for (let k = 0; k < 3; k++) {
      const y = 300 - k * 34, w = 16 - k * 2, o = 0.85 - k * 0.22;
      const d = `M ${x - w} ${y} L ${x} ${y - w * 0.8} L ${x + w} ${y}`;
      out += `<path d="${d}" fill="none" stroke="${CYAN}" stroke-width="10" stroke-linecap="round" stroke-linejoin="round" opacity="${o * 0.5}" filter="url(#bl4)"/>
        <path d="${d}" fill="none" stroke="#dffcff" stroke-width="4" stroke-linecap="round" stroke-linejoin="round" opacity="${o}"/>`;
    }
  }
  return out;
}

export default () => {
  const r = rng(3);
  let sp = "";
  for (let k = 0; k < 12; k++) {
    const a = r() * Math.PI * 2, d = R * (1.4 + r() * 0.9);
    sp += sparkle(CX + Math.cos(a) * d * 1.4, CY + Math.sin(a) * d * 0.9, 4 + r() * 7, k % 2 ? "#fff4c0" : "#c8fbff", 0.7 + r() * 0.3);
  }
  return svg(`${blurs()}
  ${backdrop()}
  ${pad()}
  ${motes(8, 30, 200, 40, 520, 360, [GOLD, CYAN, VIO, "#fff"])}
  ${ringHalf(false)}
  <!-- aura -->
  <circle cx="${CX}" cy="${CY}" r="${R * 1.9}" fill="${VIO}" opacity="0.35" filter="url(#bl24)"/>
  <circle cx="${CX}" cy="${CY}" r="${R * 1.35}" fill="#fff4c0" opacity="0.4" filter="url(#bl16)"/>
  <!-- upward motion trail under the critter -->
  <path d="M ${CX - R * 0.8} ${CY + R * 0.4} L ${CX - R * 0.5} 338 L ${CX + R * 0.5} 338 L ${CX + R * 0.8} ${CY + R * 0.4} Z" fill="#fff4c0" opacity="0.35" filter="url(#bl8)"/>
  ${chevrons()}
  ${critter(CX, CY, R, FAM.fire, { acc: "flame", mood: "determined", look: [0, -0.5], rim: "#fff4c0", rimSide: 1, sx: 0.94, sy: 1.06 })}
  ${ringHalf(true)}
  ${starArc()}
  ${sp}
  ${edges()}`);
};

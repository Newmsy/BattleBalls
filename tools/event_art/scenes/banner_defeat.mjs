// Defeat banner, gentle: "try again tomorrow". Three tired critters rest by a
// small campfire under the stars, toasting a marshmallow, one already dozing;
// behind them a lantern-lit path winds up the hills to the distant Champion's
// tower, its beacon still glowing.
import { svg, blurs, sparkle } from "./_shop_charge_pad_glow_chest_parts.mjs";
import { critter, sky, edges, FAM, rng } from "./_banner_parts.mjs";

const FX = 352, FY = 352; // fire base
const WARM = "#ffb35a";

function backdrop() {
  return `
  <defs>
    <linearGradient id="dfSky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0D0F26"/><stop offset="0.6" stop-color="#1c1858"/><stop offset="1" stop-color="#2e2470"/></linearGradient>
    <linearGradient id="dfHill1" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2a2268"/><stop offset="1" stop-color="#1a1548"/></linearGradient>
    <linearGradient id="dfGround" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#1e1850"/><stop offset="1" stop-color="#0D0F26"/></linearGradient>
  </defs>
  <rect width="720" height="440" fill="url(#dfSky)"/>
  ${sky(52, 150, 0, 0, 720, 250)}
  <!-- milky way band -->
  <ellipse cx="380" cy="90" rx="380" ry="40" fill="#8f7bff" opacity="0.16" filter="url(#bl24)" transform="rotate(-10 380 90)"/>
  <!-- crescent moon -->
  <circle cx="112" cy="74" r="44" fill="#fff4d6" opacity="0.25" filter="url(#bl16)"/>
  <circle cx="112" cy="74" r="26" fill="#fff4d6"/>
  <circle cx="124" cy="66" r="24" fill="#141040"/>
  <!-- far mountains -->
  <path d="M 0 250 L 70 200 L 130 236 L 210 170 L 290 230 L 360 196 L 430 236 L 520 160 L 600 222 L 660 188 L 720 220 L 720 300 L 0 300 Z" fill="#1d1856"/>
  <!-- the far hill with the tower -->
  <path d="M 380 270 Q 470 150 560 140 Q 640 150 720 236 L 720 320 L 380 320 Z" fill="url(#dfHill1)"/>
  ${towerFar(566, 142)}
  <path d="M 0 288 Q 160 250 330 282 Q 480 260 720 292 L 720 440 L 0 440 Z" fill="#1a1548"/>`;
}

function towerFar(x, base) {
  return `
  <circle cx="${x}" cy="${base - 70}" r="40" fill="#ffd34e" opacity="0.3" filter="url(#bl16)"/>
  <path d="M ${x - 16} ${base} L ${x - 11} ${base - 58} L ${x + 11} ${base - 58} L ${x + 16} ${base} Z" fill="#120e36"/>
  <path d="M ${x - 16} ${base - 58} L ${x - 16} ${base - 66} ${[-16, -10, -4, 4, 10, 16].map((d, i) => `L ${x + d} ${base - (i % 2 ? 66 : 72)}`).join(" ")} L ${x + 16} ${base - 58} Z" fill="#120e36"/>
  <rect x="${x - 3}" y="${base - 42}" width="6" height="9" rx="3" fill="#ffcf6b"/>
  <rect x="${x - 3}" y="${base - 22}" width="6" height="9" rx="3" fill="#ffcf6b" opacity="0.8"/>
  <line x1="${x}" y1="${base - 72}" x2="${x}" y2="${base - 94}" stroke="#120e36" stroke-width="2"/>
  <path d="M ${x} ${base - 94} L ${x + 14} ${base - 89} L ${x} ${base - 84} Z" fill="#ff5a6e"/>
  <circle cx="${x}" cy="${base - 66}" r="5" fill="#fff4c0"/>
  ${sparkle(x, base - 66, 12, "#ffe9a8", 0.9)}`;
}

function path() {
  // A winding dirt path from the bottom right up to the tower, with lanterns.
  const d = "M 610 448 C 520 400 680 350 600 312 C 540 284 470 270 520 230 C 548 206 560 180 566 146";
  let lanterns = "";
  for (const [x, y, s] of [[628, 392, 5], [600, 312, 4], [512, 248, 3.2], [548, 196, 2.5], [562, 166, 2]]) {
    lanterns += `<circle cx="${x}" cy="${y}" r="${s * 4}" fill="#ffcf6b" opacity="0.35" filter="url(#bl6)"/><circle cx="${x}" cy="${y}" r="${s}" fill="#fff0c0"/>`;
  }
  return `
  <path d="${d}" fill="none" stroke="#3a2f78" stroke-width="30" stroke-linecap="round" opacity="0.9"/>
  <path d="${d}" fill="none" stroke="#4a3e94" stroke-width="18" stroke-linecap="round"/>
  <path d="${d}" fill="none" stroke="#8a7ee0" stroke-width="2" stroke-dasharray="2 10" stroke-linecap="round" opacity="0.6"/>
  ${lanterns}`;
}

function ground() {
  const R = rng(19);
  let tufts = "";
  for (let k = 0; k < 18; k++) {
    const x = 20 + R() * 680, y = 330 + R() * 90;
    if (Math.abs(x - FX) < 150 && y < 400) continue;
    const h = 8 + R() * 12;
    tufts += `<path d="M ${x - 6} ${y} Q ${x - 5} ${y - h * 0.6} ${x - 9} ${y - h} M ${x} ${y} Q ${x + 1} ${y - h} ${x + 2} ${y - h * 1.2} M ${x + 6} ${y} Q ${x + 6} ${y - h * 0.6} ${x + 10} ${y - h * 0.9}" fill="none" stroke="#2e2878" stroke-width="2.5" stroke-linecap="round"/>`;
  }
  return `
  <path d="M -20 330 Q 200 300 420 318 Q 600 306 740 330 L 740 460 L -20 460 Z" fill="url(#dfGround)"/>
  <!-- warm light pool -->
  <ellipse cx="${FX}" cy="${FY}" rx="270" ry="80" fill="${WARM}" opacity="0.28" filter="url(#bl24)"/>
  <ellipse cx="${FX}" cy="${FY + 4}" rx="140" ry="34" fill="${WARM}" opacity="0.35" filter="url(#bl12)"/>
  ${tufts}`;
}

function fire() {
  const R = rng(31);
  let embers = "";
  for (let k = 0; k < 16; k++) {
    const t = R();
    const x = FX + (R() - 0.5) * 50 + t * 30 * Math.sin(k), y = FY - 50 - t * 150;
    embers += `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="${(2.6 - t * 1.6).toFixed(1)}" fill="${k % 3 ? "#ffcf6b" : "#ff8a3c"}" opacity="${(0.95 - t * 0.6).toFixed(2)}"/>`;
  }
  const flame = (s, col) => `<path d="M ${FX - 30 * s} ${FY - 6} Q ${FX - 40 * s} ${FY - 40 * s} ${FX - 14 * s} ${FY - 62 * s} Q ${FX - 16 * s} ${FY - 40 * s} ${FX - 2 * s} ${FY - 36 * s} Q ${FX - 6 * s} ${FY - 72 * s} ${FX + 12 * s} ${FY - 92 * s} Q ${FX + 14 * s} ${FY - 58 * s} ${FX + 22 * s} ${FY - 48 * s} Q ${FX + 34 * s} ${FY - 56 * s} ${FX + 32 * s} ${FY - 70 * s} Q ${FX + 46 * s} ${FY - 36 * s} ${FX + 30 * s} ${FY - 6} Z" fill="${col}"/>`;
  return `
  <circle cx="${FX}" cy="${FY - 40}" r="90" fill="#ff8a3c" opacity="0.35" filter="url(#bl24)"/>
  <!-- stone ring -->
  ${[-48, -30, -10, 12, 32, 50].map((dx, i) => `<ellipse cx="${FX + dx}" cy="${FY + 6 + (i % 2) * 3}" rx="13" ry="9" fill="#3a3478" stroke="#120f30" stroke-width="2"/><ellipse cx="${FX + dx - 3}" cy="${FY + 2 + (i % 2) * 3}" rx="6" ry="3" fill="${WARM}" opacity="0.5"/>`).join("")}
  <!-- logs -->
  <g transform="rotate(-16 ${FX} ${FY})"><rect x="${FX - 44}" y="${FY - 12}" width="88" height="16" rx="8" fill="#6a3a2a" stroke="#2a140e" stroke-width="2.5"/><ellipse cx="${FX + 42}" cy="${FY - 4}" rx="6" ry="8" fill="#c88a5a" stroke="#2a140e" stroke-width="2"/></g>
  <g transform="rotate(16 ${FX} ${FY})"><rect x="${FX - 44}" y="${FY - 12}" width="88" height="16" rx="8" fill="#7a4632" stroke="#2a140e" stroke-width="2.5"/><ellipse cx="${FX - 42}" cy="${FY - 4}" rx="6" ry="8" fill="#c88a5a" stroke="#2a140e" stroke-width="2"/></g>
  ${flame(1.05, "#ff6a3d")}
  <g filter="url(#bl2)">${flame(0.8, "#ffa53c")}</g>
  ${flame(0.55, "#ffd34e")}
  ${flame(0.3, "#fff4c0")}
  ${embers}`;
}

// A marshmallow on a stick, propped on a rock, toasting over the fire.
function marshmallow() {
  return `
  <ellipse cx="262" cy="392" rx="18" ry="10" fill="#2e2870" stroke="#120f30" stroke-width="2"/>
  <line x1="236" y1="404" x2="306" y2="322" stroke="#5a3424" stroke-width="5" stroke-linecap="round"/>
  <line x1="236" y1="404" x2="306" y2="322" stroke="#9a6a44" stroke-width="2" stroke-linecap="round"/>
  <g transform="rotate(-34 312 318)">
    <rect x="300" y="308" width="24" height="20" rx="7" fill="#fff4e6" stroke="#c8a48a" stroke-width="2"/>
    <rect x="312" y="308" width="12" height="20" rx="6" fill="#e8a060" opacity="0.8"/>
  </g>`;
}

const zzz = (x, y) => `<g fill="none" stroke="#c8b8ff" stroke-linecap="round" stroke-linejoin="round" opacity="0.85">
  <path d="M ${x} ${y} l 10 0 l -10 12 l 10 0" stroke-width="3"/>
  <path d="M ${x + 18} ${y - 22} l 13 0 l -13 15 l 13 0" stroke-width="3.5"/>
  <path d="M ${x + 40} ${y - 50} l 16 0 l -16 18 l 16 0" stroke-width="4"/></g>`;

export default () =>
  svg(`${blurs()}
  ${backdrop()}
  ${ground()}
  ${path()}
  <!-- the tired trio -->
  <ellipse cx="206" cy="372" rx="48" ry="10" fill="#000" opacity="0.45" filter="url(#bl4)"/>
  ${critter(206, 330, 46, FAM.sea, { acc: "fin", mood: "tired", look: [0.6, 0.2], rim: WARM, rimSide: 1, sy: 0.94, tilt: 4 })}
  ${marshmallow()}
  <ellipse cx="478" cy="374" rx="46" ry="10" fill="#000" opacity="0.45" filter="url(#bl4)"/>
  ${critter(478, 334, 44, FAM.sweet, { acc: "ears", mood: "tired", look: [-0.6, 0.2], rim: WARM, rimSide: -1, sy: 0.94, tilt: -4 })}
  <ellipse cx="548" cy="384" rx="36" ry="8" fill="#000" opacity="0.45" filter="url(#bl4)"/>
  ${critter(546, 356, 32, FAM.nature, { acc: "leaf", mood: "sleepy", rim: WARM, rimSide: -1, sy: 0.9, tilt: -22 })}
  ${zzz(574, 300)}
  ${fire()}
  ${sparkle(300, 210, 6, "#fff4c0", 0.7)}${sparkle(420, 196, 5, "#fff4c0", 0.6)}
  ${edges(0.9)}`);


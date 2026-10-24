// The Glitch's broken vending machine: an RGB-split, flickering boon dispenser
// in a neon back alley, capsules behind cracked glass, a Button slot, a kick dent.
import { shade } from "../../brand/parts.mjs";

const GL = "#FF5A6E";
const CY = "#3EE6FF";
const MG = "#FF3EDC";

function rng(seed) {
  let s = seed;
  return () => ((s = (s * 16807) % 2147483647) / 2147483647);
}

// A shop Button: cream/gold sewing button with a teal rim and 4 holes.
function button(cx, cy, r, { tilt = 1, rot = 0 } = {}) {
  const h = r * 0.2;
  const o = r * 0.3;
  return `<g transform="translate(${cx} ${cy}) rotate(${rot}) scale(1 ${tilt})">
    <circle r="${r * 1.05}" fill="#000" opacity="0.3" cy="${r * 0.18}"/>
    <circle r="${r}" fill="#2FC4B2"/>
    <circle r="${r * 0.8}" fill="url(#vmBtn)"/>
    <circle r="${r * 0.62}" fill="none" stroke="#c99a4a" stroke-width="${r * 0.08}" opacity="0.7"/>
    <circle cx="${-o}" cy="${-o}" r="${h}" fill="#1f5f5a"/><circle cx="${o}" cy="${-o}" r="${h}" fill="#1f5f5a"/>
    <circle cx="${-o}" cy="${o}" r="${h}" fill="#1f5f5a"/><circle cx="${o}" cy="${o}" r="${h}" fill="#1f5f5a"/>
    <ellipse cx="${-r * 0.35}" cy="${-r * 0.5}" rx="${r * 0.3}" ry="${r * 0.12}" fill="#fff" opacity="0.6" transform="rotate(-30 ${-r * 0.35} ${-r * 0.5})"/>
  </g>`;
}

// A boon capsule: coloured top, pale bottom, gloss.
function capsule(cx, cy, r, col) {
  return `<g>
    <circle cx="${cx}" cy="${cy}" r="${r}" fill="#e9e4ff"/>
    <path d="M ${cx - r} ${cy} A ${r} ${r} 0 0 1 ${cx + r} ${cy} Z" fill="${col}"/>
    <path d="M ${cx - r} ${cy} A ${r} ${r} 0 0 1 ${cx + r} ${cy} Z" fill="url(#vmCapSh)"/>
    <line x1="${cx - r}" y1="${cy}" x2="${cx + r}" y2="${cy}" stroke="${shade(col, -0.45)}" stroke-width="${r * 0.14}"/>
    <circle cx="${cx}" cy="${cy}" r="${r}" fill="none" stroke="${shade(col, -0.55)}" stroke-width="${r * 0.1}"/>
    <ellipse cx="${cx - r * 0.38}" cy="${cy - r * 0.48}" rx="${r * 0.28}" ry="${r * 0.14}" fill="#fff" opacity="0.7" transform="rotate(-35 ${cx - r * 0.38} ${cy - r * 0.48})"/>
  </g>`;
}

export default function () {
  const R = rng(7);
  // Machine frame (drawn upright then tilted a touch).
  const mx = 236, my = 58, mw = 248, mh = 318;
  // Background brick wall.
  let bricks = "";
  for (let row = 0; row < 12; row++) {
    const y = row * 26;
    const off = row % 2 ? 0 : 30;
    for (let x = -60 + off; x < 760; x += 60) {
      bricks += `<rect x="${x + 2}" y="${y + 2}" width="56" height="22" rx="3" fill="#1b1744" opacity="${0.5 + R() * 0.4}"/>`;
    }
  }
  // Capsules on 3 shelves.
  const fam = ["#5CFF9A", "#3EA8FF", "#FF8AD0", "#FFD34E", "#B88CFF", "#FF7A45", "#BFEFFF", "#C9A6FF", "#3EE6FF"];
  let caps = "";
  const gx = mx + 22, gw = 140;
  [0, 1, 2].forEach((s) => {
    const sy = my + 92 + s * 64;
    for (let k = 0; k < 4; k++) {
      caps += capsule(gx + 20 + k * 34 + (s === 1 ? 4 : 0), sy - 18, 14.5, fam[(s * 4 + k * 2 + 1) % fam.length]);
    }
    caps += `<rect x="${gx}" y="${sy - 2}" width="${gw}" height="7" fill="#3a2f78"/><rect x="${gx}" y="${sy - 2}" width="${gw}" height="2" fill="#8f7bff" opacity="0.6"/>`;
    // spiral coils
    for (let k = 0; k < 4; k++) {
      const cx = gx + 20 + k * 34 + (s === 1 ? 4 : 0);
      caps += `<path d="M ${cx - 13} ${sy - 3} q 4 -6 8 0 q 4 6 8 0 q 4 -6 8 0" fill="none" stroke="#a9b4d6" stroke-width="1.6" opacity="0.55"/>`;
    }
  });
  // One capsule tumbling out at the bottom tray.
  const fallen = capsule(gx + 96, my + 272, 13, "#FF5A6E");

  // Glitch slices: horizontal bands copied with an offset.
  const slices = [
    [my + 36, 14, 16], [my + 128, 8, -20], [my + 196, 12, 14], [my + 252, 5, -12],
  ];

  const body = `
    <!-- side panel depth -->
    <path d="M ${mx + mw} ${my + 10} L ${mx + mw + 30} ${my + 24} L ${mx + mw + 30} ${my + mh + 4} L ${mx + mw} ${my + mh} Z" fill="url(#vmSide)"/>
    <!-- dent on side panel -->
    <path d="M ${mx + mw + 4} ${my + 196} q 16 6 20 26 q -2 22 -18 30 q 6 -28 -2 -56 Z" fill="#160f30" opacity="0.85"/>
    <path d="M ${mx + mw + 6} ${my + 200} q 12 8 14 24" fill="none" stroke="#ff9aa6" stroke-width="2" opacity="0.6"/>
    <!-- main body -->
    <rect x="${mx}" y="${my}" width="${mw}" height="${mh}" rx="18" fill="url(#vmBody)" stroke="#120c2a" stroke-width="4"/>
    <rect x="${mx + 4}" y="${my + 4}" width="${mw - 8}" height="${mh - 8}" rx="15" fill="none" stroke="${GL}" stroke-width="2.5" opacity="0.75" filter="url(#vmGlowS)"/>
    <rect x="${mx + 4}" y="${my + 4}" width="${mw - 8}" height="${mh - 8}" rx="15" fill="none" stroke="#ffc0c8" stroke-width="1" opacity="0.6"/>
    <!-- top marquee (no text: glowing pill + capsule icon) -->
    <rect x="${mx + 18}" y="${my + 14}" width="${mw - 36}" height="34" rx="10" fill="#1a0f2c" stroke="#3b2552" stroke-width="2"/>
    <rect x="${mx + 30}" y="${my + 24}" width="${mw - 60}" height="14" rx="7" fill="${GL}" opacity="0.9" filter="url(#vmGlowS)"/>
    <rect x="${mx + 30}" y="${my + 24}" width="${mw - 60}" height="14" rx="7" fill="#ffd0d6"/>
    <rect x="${mx + 100}" y="${my + 22}" width="62" height="18" fill="#1a0f2c"/><rect x="${mx + 108}" y="${my + 29}" width="20" height="4" fill="${GL}" opacity="0.5"/>
    <rect x="${mx + 166}" y="${my + 24}" width="14" height="14" fill="${CY}" opacity="0.9"/>
    <!-- glass window -->
    <rect x="${gx - 6}" y="${my + 58}" width="${gw + 12}" height="214" rx="8" fill="#0b0920" stroke="#2d2160" stroke-width="3"/>
    <g clip-path="url(#vmGlass)">
      <rect x="${gx}" y="${my + 62}" width="${gw}" height="206" fill="url(#vmInside)"/>
      ${caps}
      <!-- glass sheen + crack -->
      <path d="M ${gx} ${my + 62} L ${gx + 50} ${my + 62} L ${gx} ${my + 160} Z" fill="#fff" opacity="0.08"/>
      <path d="M ${gx + 70} ${my + 62} L ${gx + 98} ${my + 62} L ${gx + 20} ${my + 268} L ${gx - 8} ${my + 268} Z" fill="#fff" opacity="0.05"/>
      <g stroke="#e8f6ff" stroke-width="1.6" fill="none" opacity="0.75" stroke-linecap="round">
        <path d="M ${gx + 112} ${my + 150} l -18 -22 l -6 -24 M ${gx + 112} ${my + 150} l 22 -10 M ${gx + 112} ${my + 150} l 6 30 l -10 26 M ${gx + 112} ${my + 150} l -26 12 l -14 -4"/>
      </g>
      
    </g>
    <!-- tray -->
    <rect x="${gx + 10}" y="${my + 282}" width="${gw - 20}" height="26" rx="6" fill="#07061a" stroke="#2d2160" stroke-width="2"/>
    <g clip-path="url(#vmTray)">${fallen}</g>
    <!-- control column -->
    <rect x="${mx + 176}" y="${my + 58}" width="56" height="250" rx="8" fill="#22163f" stroke="#120c2a" stroke-width="2"/>
    <!-- screen -->
    <rect x="${mx + 182}" y="${my + 66}" width="44" height="40" rx="4" fill="#07061a"/>
    <g clip-path="url(#vmScr)">
      <rect x="${mx + 182}" y="${my + 66}" width="44" height="40" fill="${GL}" opacity="0.25"/>
      ${[[0,0],[2,2],[4,0],[0,4],[4,4]].map(([a,b])=>`<rect x="${mx+187+a*2}" y="${my+72+b*2}" width="3" height="3" fill="#fff"/>`).join("")}
      ${[[0,0],[2,2],[4,0],[0,4],[4,4]].map(([a,b])=>`<rect x="${mx+211+a*2}" y="${my+72+b*2}" width="3" height="3" fill="#fff"/>`).join("")}
      <rect x="${mx + 197}" y="${my + 90}" width="16" height="3" fill="#fff"/>
      <rect x="${mx + 194}" y="${my + 93}" width="3" height="3" fill="#fff"/><rect x="${mx + 213}" y="${my + 93}" width="3" height="3" fill="#fff"/>
      <rect x="${mx + 186}" y="${my + 80}" width="44" height="4" fill="${CY}" opacity="0.7"/>
      <rect x="${mx + 182}" y="${my + 88}" width="44" height="2" fill="${MG}" opacity="0.8"/>
      <rect x="${mx + 182}" y="${my + 98}" width="44" height="3" fill="#fff" opacity="0.7"/>
    </g>
    <rect x="${mx + 182}" y="${my + 66}" width="44" height="40" rx="4" fill="none" stroke="${CY}" stroke-width="1.5" opacity="0.8" filter="url(#vmGlowS)"/>
    <!-- keypad -->
    ${[0, 1, 2].map((r) => [0, 1].map((c) => {
      const lit = (r + c) % 3 === 0;
      return `<rect x="${mx + 186 + c * 20}" y="${my + 118 + r * 18}" width="16" height="12" rx="3" fill="${lit ? GL : "#3a2b66"}" ${lit ? 'filter="url(#vmGlowS)"' : ""}/><rect x="${mx + 186 + c * 20}" y="${my + 118 + r * 18}" width="16" height="12" rx="3" fill="${lit ? "#ffc4cc" : "#4a3a80"}" opacity="${lit ? 1 : 0.8}"/>`;
    }).join("")).join("")}
    <!-- Button slot: a round Button-shaped hole with a teal ring -->
    <rect x="${mx + 186}" y="${my + 184}" width="36" height="52" rx="6" fill="#170f33" stroke="#3b2c70" stroke-width="2"/>
    <circle cx="${mx + 204}" cy="${my + 204}" r="12" fill="#2FC4B2" opacity="0.6" filter="url(#vmGlowS)"/>
    <circle cx="${mx + 204}" cy="${my + 204}" r="10" fill="none" stroke="#7ff3e2" stroke-width="2.5"/>
    <rect x="${mx + 202}" y="${my + 195}" width="4" height="18" rx="2" fill="#05040f"/>
    <rect x="${mx + 194}" y="${my + 222}" width="20" height="6" rx="3" fill="#05040f"/>
    <!-- return lever -->
    <rect x="${mx + 190}" y="${my + 252}" width="28" height="40" rx="6" fill="#170f33"/>
    <rect x="${mx + 196}" y="${my + 260}" width="16" height="22" rx="4" fill="#07061a"/>
    <!-- feet -->
    <rect x="${mx + 14}" y="${my + mh - 2}" width="28" height="12" rx="3" fill="#120c2a"/>
    <rect x="${mx + mw - 42}" y="${my + mh - 2}" width="28" height="12" rx="3" fill="#120c2a"/>
    <!-- kick dent: crumpled hollow low on the front right -->
    <path d="M ${mx + 150} ${my + 300} q -6 -26 18 -34 q 22 -10 36 6 q 16 18 4 32 Z" fill="#1a0c2a"/>
    <path d="M ${mx + 156} ${my + 298} q -2 -22 16 -28 q 18 -6 30 6" fill="none" stroke="#ff9aa6" stroke-width="2.5" opacity="0.8" stroke-linecap="round"/>
    <path d="M ${mx + 166} ${my + 290} l 10 -8 l 6 10 l 10 -6" fill="none" stroke="#0b0716" stroke-width="2.5" stroke-linejoin="round"/>
    <g stroke="#0b0716" stroke-width="2" fill="none" stroke-linecap="round">
      <path d="M ${mx + 150} ${my + 284} l -12 -8 M ${mx + 208} ${my + 270} l 10 -10 M ${mx + 214} ${my + 292} l 12 2"/>
    </g>
    <ellipse cx="${mx + 178}" cy="${my + 292}" rx="14" ry="6" fill="#ff5a6e" opacity="0.18" transform="rotate(-20 ${mx + 178} ${my + 292})"/>
`;

  // Glitch-shifted copies of slices of the machine.
  const glitch = slices
    .map(([y, h, dx], i) => `
      <clipPath id="vmSl${i}"><rect x="0" y="${y}" width="720" height="${h}"/></clipPath>
      <g clip-path="url(#vmSl${i})"><g transform="translate(${dx} 0)"><use href="#vmMachine"/></g></g>
      <rect x="${mx + dx - 4}" y="${y}" width="${mw + 40}" height="${h}" fill="${i % 2 ? CY : MG}" opacity="0.22"/>
      <rect x="${mx + dx - 14}" y="${y}" width="${mw + 60}" height="1.5" fill="${i % 2 ? CY : MG}" opacity="0.9"/>`)
    .join("");

  // Pixel debris.
  let px = "";
  for (let k = 0; k < 28; k++) {
    const x = mx - 40 + R() * (mw + 110);
    const y = my - 20 + R() * (mh * 0.9);
    if (x > mx - 4 && x < mx + mw + 30) continue;
    const s = 4 + R() * 9;
    const c = [GL, CY, MG][k % 3];
    px += `<rect x="${x}" y="${y}" width="${s}" height="${s}" fill="${c}" opacity="${0.35 + R() * 0.55}"/>`;
  }
  // Rising sparks / scanline bars near the top.
  let bars = "";
  for (let k = 0; k < 6; k++) {
    const y = 40 + R() * 300;
    bars += `<rect x="${mx - 70 - R() * 50}" y="${y}" width="${30 + R() * 70}" height="3" fill="${k % 2 ? CY : MG}" opacity="0.4"/>`;
    bars += `<rect x="${mx + mw + 40 + R() * 40}" y="${y + 30}" width="${30 + R() * 60}" height="3" fill="${k % 2 ? MG : CY}" opacity="0.35"/>`;
  }

  return `<svg xmlns="http://www.w3.org/2000/svg" width="720" height="440" viewBox="0 0 720 440">
  <defs>
    <radialGradient id="vmBg" cx="50%" cy="40%" r="75%">
      <stop offset="0" stop-color="#2c2170"/><stop offset="0.55" stop-color="#141038"/><stop offset="1" stop-color="#0D0F26"/>
    </radialGradient>
    <radialGradient id="vmHalo" cx="50%" cy="50%" r="50%">
      <stop offset="0" stop-color="${GL}" stop-opacity="0.55"/><stop offset="0.5" stop-color="${MG}" stop-opacity="0.18"/><stop offset="1" stop-color="${MG}" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="vmBody" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#5a2a5e"/><stop offset="0.5" stop-color="#3b1f4e"/><stop offset="1" stop-color="#22143a"/>
    </linearGradient>
    <linearGradient id="vmSide" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#25153d"/><stop offset="1" stop-color="#140c26"/>
    </linearGradient>
    <linearGradient id="vmInside" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#2a2160"/><stop offset="1" stop-color="#140f38"/>
    </linearGradient>
    <linearGradient id="vmCapSh" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#fff" stop-opacity="0.15"/><stop offset="1" stop-color="#000" stop-opacity="0.2"/>
    </linearGradient>
    <radialGradient id="vmBtn" cx="0.35" cy="0.3" r="0.8">
      <stop offset="0" stop-color="#fff4d6"/><stop offset="0.5" stop-color="#f1cf86"/><stop offset="1" stop-color="#c99a4a"/>
    </radialGradient>
    <linearGradient id="vmFloor" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#1c1648"/><stop offset="1" stop-color="#0a0a1e"/>
    </linearGradient>
    <linearGradient id="vmRefl" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#fff" stop-opacity="0.32"/><stop offset="1" stop-color="#fff" stop-opacity="0"/>
    </linearGradient>
    <mask id="vmReflMask"><rect x="0" y="${my + mh + 8}" width="720" height="120" fill="url(#vmRefl)"/></mask>
    <filter id="vmGlowS" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="3"/></filter>
    <filter id="vmGlowL" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="16"/></filter>
    <filter id="vmBlur2" x="-10%" y="-10%" width="120%" height="120%"><feGaussianBlur stdDeviation="2.5"/></filter>
    <clipPath id="vmGlass"><rect x="${gx}" y="${my + 62}" width="${gw}" height="206" rx="4"/></clipPath>
    <clipPath id="vmTray"><rect x="${gx + 12}" y="${my + 284}" width="${gw - 24}" height="22" rx="5"/></clipPath>
    <clipPath id="vmScr"><rect x="${mx + 182}" y="${my + 66}" width="44" height="40" rx="4"/></clipPath>
    <g id="vmMachine">${body}</g>
  </defs>

  <rect width="720" height="440" fill="url(#vmBg)"/>
  <!-- brick alley wall -->
  <g opacity="0.85">${bricks}</g>
  <rect width="720" height="320" fill="url(#vmBg)" opacity="0.55"/>
  <!-- neighbour neon signs, soft and out of focus -->
  <g filter="url(#vmBlur2)" opacity="0.8">
    <rect x="58" y="70" width="90" height="46" rx="12" fill="none" stroke="${CY}" stroke-width="5"/>
    <circle cx="103" cy="93" r="10" fill="none" stroke="${CY}" stroke-width="5"/>
    <path d="M 588 84 q 26 -30 52 0 q -26 40 -52 0 Z" fill="none" stroke="#FF8AD0" stroke-width="5"/>
    <circle cx="614" cy="150" r="5" fill="#FF8AD0"/>
  </g>
  <rect x="58" y="70" width="90" height="46" rx="12" fill="none" stroke="${CY}" stroke-width="10" opacity="0.25" filter="url(#vmGlowL)"/>
  <!-- pipes -->
  <rect x="652" y="0" width="14" height="330" fill="#1a1540"/><rect x="655" y="0" width="3" height="330" fill="#3a3380" opacity="0.6"/>
  <rect x="40" y="190" width="10" height="140" fill="#1a1540"/>
  <!-- floor -->
  <rect x="0" y="${my + mh + 6}" width="720" height="${440 - my - mh - 6}" fill="url(#vmFloor)"/>
  <rect x="0" y="${my + mh + 6}" width="720" height="2" fill="#4a3d9a" opacity="0.6"/>
  <!-- halo behind machine -->
  <ellipse cx="${mx + mw / 2 + 10}" cy="${my + mh / 2}" rx="260" ry="210" fill="url(#vmHalo)"/>
  <!-- trash bag + box, side props -->
  <ellipse cx="126" cy="${my + mh + 4}" rx="70" ry="12" fill="#000" opacity="0.4"/>
  <path d="M 72 ${my + mh + 4} q -8 -54 30 -70 q 8 -14 18 -2 q 44 10 40 72 Z" fill="#1d1a3e" stroke="#2f2a66" stroke-width="2"/>
  <path d="M 96 ${my + mh - 52} q 10 -10 20 0" stroke="#5a50b0" stroke-width="2" fill="none" opacity="0.6"/>
  <rect x="540" y="${my + mh - 54}" width="80" height="58" rx="4" fill="#2a2058" stroke="#3d3280" stroke-width="2"/>
  <path d="M 540 ${my + mh - 54} l 14 -16 l 80 0 l -14 16 Z" fill="#3a2e78"/>
  <rect x="566" y="${my + mh - 40}" width="28" height="10" rx="3" fill="#1a1440"/>
  <!-- machine shadow -->
  <ellipse cx="${mx + mw / 2 + 16}" cy="${my + mh + 10}" rx="${mw * 0.72}" ry="16" fill="#000" opacity="0.55"/>
  <ellipse cx="${mx + mw / 2 + 16}" cy="${my + mh + 12}" rx="${mw * 0.6}" ry="10" fill="${GL}" opacity="0.25" filter="url(#vmGlowS)"/>

  <!-- machine, slightly tilted from the kick -->
  <!-- living layer (render.mjs): the machine still shudders from the kick -->
  <g data-layer="machine" data-move="sway 0.5 3.1 0" transform="rotate(-2.2 ${mx + mw / 2} ${my + mh})">
    <!-- RGB ghost copies -->
    <g opacity="0.8" transform="translate(-7 -1)"><use href="#vmMachine" filter="url(#vmCyan)"/></g>
    <g opacity="0.8" transform="translate(7 1)"><use href="#vmMachine" filter="url(#vmMag)"/></g>
    <use href="#vmMachine"/>
    ${glitch}
  </g>
  <filter id="vmMag"><feColorMatrix type="matrix" values="0 0 0 0 1  0 0 0 0 0.25  0 0 0 0 0.86  0 0 0 0.9 0"/></filter>
  <filter id="vmCyan"><feColorMatrix type="matrix" values="0 0 0 0 0.24  0 0 0 0 0.9  0 0 0 0 1  0 0 0 0.9 0"/></filter>

  <!-- wet floor reflection -->
  <g mask="url(#vmReflMask)" opacity="0.6">
    <g transform="translate(0 ${2 * (my + mh) + 16}) scale(1 -1)"><use href="#vmMachine" filter="url(#vmBlur2)"/></g>
  </g>
  <ellipse cx="${mx + 80}" cy="${my + mh + 40}" rx="120" ry="10" fill="${GL}" opacity="0.15" filter="url(#vmGlowS)"/>

  <!-- glitch debris -->
  ${px}${bars}
  <!-- sparks from the dent -->
  <g stroke-linecap="round">
    <line x1="${mx + mw + 34}" y1="${my + 220}" x2="${mx + mw + 62}" y2="${my + 206}" stroke="#fff2b0" stroke-width="3"/>
    <line x1="${mx + mw + 34}" y1="${my + 226}" x2="${mx + mw + 66}" y2="${my + 232}" stroke="${GL}" stroke-width="3"/>
    <line x1="${mx + mw + 30}" y1="${my + 214}" x2="${mx + mw + 46}" y2="${my + 190}" stroke="${CY}" stroke-width="2.5"/>
  </g>
  <circle cx="${mx + mw + 36}" cy="${my + 222}" r="10" fill="#fff2b0" opacity="0.6" filter="url(#vmGlowS)"/>

  <!-- spilled Buttons in the foreground -->
  ${button(214, 404, 17, { tilt: 0.55, rot: 10 })}
  ${button(250, 398, 13, { tilt: 0.5, rot: -8 })}
  ${button(520, 412, 18, { tilt: 0.5, rot: 4 })}
  ${button(468, 380, 12, { tilt: 0.85, rot: 30 })}
  ${button(492, 396, 11, { tilt: 0.45, rot: 0 })}

  <!-- vignette -->
  <rect width="720" height="440" fill="url(#vmVig)"/>
  <radialGradient id="vmVig" cx="50%" cy="48%" r="70%">
    <stop offset="0.6" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.55"/>
  </radialGradient>
</svg>`;
}

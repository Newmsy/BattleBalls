// World map island, Haunted Arcade: a floating chunk of checker-tiled arcade
// floor. On the left a haunted cabinet glows with a ghost on its screen, a
// violet portal swirls behind it and two little ghosts drift above; pinball
// bumpers stand in front. The right (label) side stays low: a few floor tiles,
// a tiny bumper and a dropped token. The underside is violet rock with glowing
// purple veins and ectoplasm drips. The game draws the zone node over (140, 92).
import { blurs, rng } from "./_shop_charge_pad_glow_chest_parts.mjs";
import { shade } from "../../brand/parts.mjs";

export const size = [280, 210];
export const transparent = true;
export const dir = "game/ui/map_art";

const f = (n) => (+n).toFixed(1);
const PU = "#c77dff", PINK = "#ff9ae6", OUT = "#0a0618";
const CX = 140, CY = 118, RX = 118, RY = 34;

// The island's underside: a rounded rock mass tapering to a point at
// (140, 202), its edge broken into uneven stalactites of different lengths.
function underside() {
  // [x, y] around the bottom, left rim to right rim.
  const pts = [[22, 118], [26, 130], [34, 136], [40, 150], [48, 144], [58, 156], [64, 176], [72, 160], [84, 166],
    [96, 186], [104, 172], [116, 180], [128, 196], [140, 206], [150, 190], [160, 184], [170, 196], [178, 174],
    [192, 170], [200, 184], [208, 162], [222, 156], [230, 166], [238, 144], [248, 138], [254, 128], [258, 118]];
  return "M " + pts.map(([x, y]) => `${x} ${y}`).join(" L ") + " Z";
}
// Lit and shadowed rock facets (planes) on the underside.
const FACETS = [
  [[30, 128], [60, 134], [58, 156], [48, 144], [40, 150]],
  [[70, 140], [104, 150], [96, 186], [84, 166], [72, 160]],
  [[112, 152], [150, 156], [140, 206], [128, 196], [116, 180]],
  [[160, 152], [194, 148], [178, 174], [170, 196], [160, 184]],
  [[204, 144], [236, 134], [230, 166], [222, 156], [208, 162]],
];

export default function () {
  const R = rng(83);
  const d = underside();
  const facets = FACETS.map((q, k) => {
    const pp = q.map(([x, y]) => `${x},${y}`).join(" ");
    return `<polygon points="${pp}" fill="${k % 2 ? "#4a2a78" : "#2e1850"}" opacity="0.55"/><polyline points="${q.slice(0, 3).map(([x, y]) => `${x},${y}`).join(" ")}" fill="none" stroke="#8a5ac8" stroke-width="1.4" opacity="0.55"/>`;
  }).join("");
  // Glowing veins and drips.
  const veins = [
    `M 44 140 Q 52 150 62 160 L 64 172`,
    `M 88 150 Q 84 166 95 182`,
    `M 132 160 Q 126 176 138 188 L 140 200`,
    `M 176 156 Q 168 170 170 190`,
    `M 216 146 Q 206 160 214 170 M 230 146 L 229 162`,
  ];
  const veinSvg = veins.map((p) => `<path d="${p}" fill="none" stroke="${PU}" stroke-width="5" opacity="0.5" filter="url(#bl3)"/><path d="${p}" fill="none" stroke="#e9c6ff" stroke-width="1.6" stroke-linecap="round"/>`).join("");
  const drips = [[64, 182, 4.5], [96, 193, 5.5], [140, 214, 6], [170, 203, 5], [200, 190, 4], [230, 172, 3.6]].map(([x, y, s]) =>
    `<ellipse cx="${x}" cy="${y}" rx="${s * 1.6}" ry="${s * 1.6}" fill="${PU}" opacity="0.45" filter="url(#bl3)"/>
     <path d="M ${x} ${y - s * 1.8} Q ${x + s * 0.8} ${y - s * 0.2} ${x} ${y + s * 0.7} Q ${x - s * 0.8} ${y - s * 0.2} ${x} ${y - s * 1.8} Z" fill="#e9c6ff"/>`).join("");

  // Checker floor on the plateau, clipped to the top ellipse.
  let tiles = "";
  for (let r = -4; r < 5; r++) for (let c = -9; c < 10; c++) {
    if ((r + c + 20) % 2) continue;
    const x = CX + c * 16 + r * 6, y = CY + r * 8;
    tiles += `<path d="M ${f(x)} ${f(y)} l 16 0 l 6 8 l -16 0 Z" fill="#3a2366"/>`;
  }

  // The haunted cabinet, left.
  const cab = (x, y, s) => `<g transform="translate(${x} ${y}) scale(${s})">
    <ellipse cx="0" cy="2" rx="34" ry="7" fill="#000" opacity="0.55" filter="url(#bl3)"/>
    <path d="M -24 0 L -24 -86 L -30 -100 L -26 -118 L 26 -118 L 30 -100 L 24 -86 L 24 0 Z" fill="url(#haCab)" stroke="${OUT}" stroke-width="3" stroke-linejoin="round"/>
    <path d="M -26 -118 L 26 -118 L 22 -130 L -22 -130 Z" fill="#7a3ab0" stroke="${OUT}" stroke-width="3" stroke-linejoin="round"/>
    <rect x="-18" y="-128" width="36" height="7" rx="2" fill="${PINK}"/>
    <rect x="-18" y="-128" width="36" height="7" rx="2" fill="${PINK}" filter="url(#bl3)"/>
    <rect x="-22" y="-112" width="44" height="40" rx="5" fill="${OUT}"/>
    <rect x="-18" y="-108" width="36" height="32" rx="3" fill="url(#haScreen)"/>
    <rect x="-18" y="-108" width="36" height="32" rx="3" fill="#9af0ff" opacity="0.5" filter="url(#bl6)"/>
    <path d="M -9 -80 L -9 -92 Q -9 -102 0 -102 Q 9 -102 9 -92 L 9 -80 L 6 -83 L 3 -80 L 0 -83 L -3 -80 L -6 -83 Z" fill="#f6e8ff"/>
    <circle cx="-3.5" cy="-93" r="1.8" fill="#2a1a48"/><circle cx="3.5" cy="-93" r="1.8" fill="#2a1a48"/>
    <path d="M -17 -106 L -6 -106" stroke="#fff" stroke-width="2" opacity="0.7" stroke-linecap="round"/>
    <path d="M -28 -70 L 28 -70 L 32 -56 L -32 -56 Z" fill="#4a2380" stroke="${OUT}" stroke-width="2.5" stroke-linejoin="round"/>
    <circle cx="-14" cy="-63" r="4" fill="#ff4f7a" stroke="${OUT}" stroke-width="1.5"/><circle cx="-3" cy="-63" r="4" fill="#ffd36b" stroke="${OUT}" stroke-width="1.5"/>
    <line x1="14" y1="-61" x2="17" y2="-72" stroke="${OUT}" stroke-width="3" stroke-linecap="round"/><circle cx="17" cy="-73" r="3.5" fill="#ff4fd8" stroke="${OUT}" stroke-width="1.5"/>
    <rect x="-10" y="-40" width="20" height="14" rx="2" fill="#2a1048" stroke="${OUT}" stroke-width="2"/>
    <rect x="-3" y="-37" width="6" height="8" rx="1" fill="#ffd36b"/>
    <path d="M -21 -84 L -21 -6" stroke="#b07aff" stroke-width="2" opacity="0.6"/>
  </g>`;

  // A glowing pinball bumper.
  const bumper = (x, y, s, c) => `<g transform="translate(${x} ${y}) scale(${s})">
    <ellipse cx="0" cy="2" rx="13" ry="4" fill="#000" opacity="0.5" filter="url(#bl2)"/>
    <ellipse cx="0" cy="-4" rx="14" ry="10" fill="${c}" opacity="0.4" filter="url(#bl4)"/>
    <path d="M -10 0 L -10 -8 L 10 -8 L 10 0 Z" fill="${shade(c, -0.45)}" stroke="${OUT}" stroke-width="2"/>
    <ellipse cx="0" cy="0" rx="10" ry="3.6" fill="${shade(c, -0.45)}" stroke="${OUT}" stroke-width="2"/>
    <ellipse cx="0" cy="-8" rx="11" ry="4.2" fill="${c}" stroke="${OUT}" stroke-width="2"/>
    <ellipse cx="0" cy="-8.5" rx="5" ry="1.8" fill="#fff" opacity="0.85"/>
  </g>`;

  // Little sheet ghosts.
  const ghost = (x, y, s, rot = 0, o = 0.92) => `<g transform="translate(${x} ${y}) rotate(${rot}) scale(${s})" opacity="${o}">
    <ellipse cx="0" cy="4" rx="26" ry="28" fill="${PINK}" opacity="0.35" filter="url(#bl8)"/>
    <path d="M -15 18 L -15 0 Q -15 -17 0 -17 Q 15 -17 15 0 L 15 18 Q 10 13 5 18 Q 0 13 -5 18 Q -10 13 -15 18 Z" fill="#f6e8ff" stroke="#6a3a9a" stroke-width="2.2" stroke-linejoin="round"/>
    <path d="M -9 -9 Q -6 -13 -1 -13" stroke="#fff" stroke-width="2" fill="none" stroke-linecap="round"/>
    <ellipse cx="-5" cy="-2" rx="2.6" ry="3.6" fill="#2a1a48"/><ellipse cx="5" cy="-2" rx="2.6" ry="3.6" fill="#2a1a48"/>
    <ellipse cx="0" cy="7" rx="2.6" ry="3.2" fill="#2a1a48"/>
  </g>`;

  // The portal swirl behind the cabinet.
  const spiral = (ph, w, c, o) => {
    let p = "";
    for (let k = 0; k <= 60; k++) {
      const t = k / 60, a = ph + t * Math.PI * 4.2, r = 3 + t * 38;
      p += `${k ? "L" : "M"} ${f(56 + Math.cos(a) * r)} ${f(50 + Math.sin(a) * r * 1.04)} `;
    }
    return `<path d="${p}" fill="none" stroke="${c}" stroke-width="${w}" stroke-linecap="round" opacity="${o}"/>`;
  };
  const swirl = spiral(0, 3.2, "#ffe6fb", 0.85) + spiral(Math.PI, 2.4, PINK, 0.7);
  const portal = `<ellipse cx="58" cy="56" rx="48" ry="44" fill="${PU}" opacity="0.5" filter="url(#bl12)"/>
    <ellipse cx="56" cy="50" rx="42" ry="44" fill="url(#haPortal)"/>
    <ellipse cx="56" cy="50" rx="42" ry="44" fill="none" stroke="#3a1a5a" stroke-width="5"/>
    <ellipse cx="56" cy="50" rx="42" ry="44" fill="none" stroke="${PU}" stroke-width="2"/>
    ${swirl}`;

  // Neon star sign floating above.
  const starP = `M 14 66 l 3.5 7.5 l 8 1 l -6 5.5 l 1.8 8 l -7.3 -4 l -7.3 4 l 1.8 -8 l -6 -5.5 l 8 -1 Z`;

  let motes = "";
  for (let k = 0; k < 14; k++) {
    const x = 8 + R() * 264, y = 10 + R() * 190, s = 0.8 + R() * 1.6, c = [PINK, PU, "#39d7ff"][k % 3];
    if (Math.hypot(x - 140, y - 92) < 66) continue;
    motes += `<circle cx="${f(x)}" cy="${f(y)}" r="${f(s * 2.6)}" fill="${c}" opacity="0.3" filter="url(#bl2)"/><circle cx="${f(x)}" cy="${f(y)}" r="${f(s)}" fill="${c}" opacity="0.9"/>`;
  }

  return `<svg xmlns="http://www.w3.org/2000/svg" width="280" height="210" viewBox="0 0 280 210">${blurs()}
  <defs>
    <radialGradient id="haGlow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="${PU}" stop-opacity="0.55"/><stop offset="0.6" stop-color="${PU}" stop-opacity="0.18"/><stop offset="1" stop-color="${PU}" stop-opacity="0"/></radialGradient>
    <linearGradient id="haRock" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3a1f5e"/><stop offset="0.5" stop-color="#22123c"/><stop offset="1" stop-color="#120a24"/></linearGradient>
    <linearGradient id="haRockSide" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#000" stop-opacity="0.35"/><stop offset="0.35" stop-color="#000" stop-opacity="0"/><stop offset="0.7" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.4"/></linearGradient>
    <linearGradient id="haTop" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2a1748"/><stop offset="1" stop-color="#1c0f34"/></linearGradient>
    <linearGradient id="haLip" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6a3aa0"/><stop offset="1" stop-color="#3a1f5e"/></linearGradient>
    <linearGradient id="haCab" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#5a2a90"/><stop offset="0.55" stop-color="#3a1a62"/><stop offset="1" stop-color="#241040"/></linearGradient>
    <linearGradient id="haScreen" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#4ad8ff"/><stop offset="1" stop-color="#1a6aa8"/></linearGradient>
    <radialGradient id="haPortal" cx="0.5" cy="0.5" r="0.55"><stop offset="0" stop-color="#fff0ff"/><stop offset="0.3" stop-color="${PINK}"/><stop offset="0.75" stop-color="#7a3ab0"/><stop offset="1" stop-color="#2a1048"/></radialGradient>
    <clipPath id="haTopClip"><ellipse cx="${CX}" cy="${CY}" rx="${RX - 2}" ry="${RY - 2}"/></clipPath>
  </defs>
  <ellipse cx="140" cy="160" rx="132" ry="46" fill="url(#haGlow)"/>
  <ellipse cx="140" cy="188" rx="40" ry="10" fill="${PU}" opacity="0.35" filter="url(#bl8)"/>
  <g transform="translate(0 118) scale(1 0.85) translate(0 -118)">
  <path d="${d}" fill="url(#haRock)" stroke="${OUT}" stroke-width="3" stroke-linejoin="round"/>
  <path d="${d}" fill="url(#haRockSide)"/>
  ${facets}${veinSvg}${drips}</g>
  <ellipse cx="${CX}" cy="${CY + 7}" rx="${RX}" ry="${RY}" fill="url(#haLip)" stroke="${OUT}" stroke-width="3"/>
  <path d="M ${CX - RX + 8} ${CY + 14} Q ${CX} ${CY + RY + 16} ${CX + RX - 8} ${CY + 14}" fill="none" stroke="${PU}" stroke-width="2" opacity="0.65"/>
  <ellipse cx="${CX}" cy="${CY}" rx="${RX}" ry="${RY}" fill="url(#haTop)" stroke="${OUT}" stroke-width="3"/>
  <g clip-path="url(#haTopClip)">${tiles}
    <ellipse cx="44" cy="112" rx="50" ry="20" fill="${PU}" opacity="0.35" filter="url(#bl8)"/>
    <ellipse cx="236" cy="118" rx="40" ry="16" fill="#b88cff" opacity="0.18" filter="url(#bl6)"/>
  </g>
  <ellipse cx="${CX}" cy="${CY}" rx="${RX - 3}" ry="${RY - 3}" fill="none" stroke="#9a6ad8" stroke-width="1.5" opacity="0.6"/>
  <path d="M ${CX - RX + 2} ${CY + 4} Q ${CX} ${CY + RY * 2 + 6} ${CX + RX - 2} ${CY + 4}" fill="none" stroke="${PINK}" stroke-width="5" opacity="0.4" filter="url(#bl3)"/>
  <path d="M ${CX - RX + 2} ${CY + 4} Q ${CX} ${CY + RY * 2 + 6} ${CX + RX - 2} ${CY + 4}" fill="none" stroke="#ffd0f4" stroke-width="1.4" opacity="0.8"/>
  <path d="M ${CX - RX + 10} ${CY - 12} Q ${CX - 60} ${CY - RY + 2} ${CX - 20} ${CY - RY + 1}" fill="none" stroke="#e9c6ff" stroke-width="1.6" opacity="0.5" stroke-linecap="round"/>
  ${portal}
  <path d="${starP}" fill="none" stroke="#ffd36b" stroke-width="2.6" stroke-linejoin="round"/>
  <path d="${starP}" fill="none" stroke="#ffd36b" stroke-width="4" filter="url(#bl3)" opacity="0.8"/>
  ${cab(42, 124, 0.84)}
  ${bumper(28, 130, 0.85, "#ff4fd8")}${bumper(84, 140, 0.95, "#39d7ff")}${bumper(66, 150, 0.7, "#ffd36b")}
  ${ghost(14, 30, 0.6, -14)}${ghost(104, 14, 0.5, 12, 0.85)}
  <!-- label side: low details only -->
  ${bumper(236, 124, 0.62, "#ff4fd8")}
  <g transform="translate(256 110)"><ellipse cx="0" cy="0" rx="6" ry="3" fill="#ffd36b" stroke="${OUT}" stroke-width="1.6"/><ellipse cx="-1.5" cy="-0.8" rx="2" ry="0.9" fill="#fff6c0"/></g>
  ${ghost(214, 102, 0.36, 6, 0.75)}
  ${motes}
  </svg>`;
}

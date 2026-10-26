// World map island, Magma Core: a floating chunk of cracked basalt. On the
// left a volcano glows with lava pouring down its flank and smoke curling up,
// with an obsidian gate full of ember light standing at its foot. The right
// (label) side stays low: glowing cracks, a small lava pool and an obsidian
// spike. The underside is dark rock with molten veins, and lava drips fall
// from its tips. The game draws the zone node over (140, 92).
import { blurs, rng } from "./_shop_charge_pad_glow_chest_parts.mjs";

export const size = [280, 210];
export const transparent = true;
export const dir = "game/ui/map_art";

const f = (n) => (+n).toFixed(1);
const OR = "#ff6a3d", AM = "#ffb347", YE = "#ffd36b", HOT = "#fff3c4", OUT = "#0b0614";
const CX = 140, CY = 118, RX = 118, RY = 34;

// Underside silhouette, left rim to right rim (uneven stalactites).
const PTS = [[22, 118], [26, 130], [36, 136], [44, 156], [52, 146], [62, 152], [72, 178], [80, 162], [92, 170],
  [102, 190], [112, 174], [124, 182], [134, 198], [142, 208], [150, 194], [162, 180], [172, 192], [180, 172],
  [194, 168], [204, 182], [212, 160], [224, 154], [232, 164], [240, 142], [250, 136], [255, 126], [258, 118]];
const FACETS = [
  [[30, 128], [60, 134], [52, 146], [44, 156], [36, 136]],
  [[66, 142], [100, 150], [92, 170], [80, 162], [72, 178]],
  [[112, 152], [152, 156], [142, 208], [134, 198], [124, 182]],
  [[162, 152], [196, 148], [180, 172], [172, 192], [162, 180]],
  [[206, 144], [238, 134], [232, 164], [224, 154], [212, 160]],
];

export default function () {
  const R = rng(41);
  const d = "M " + PTS.map(([x, y]) => `${x} ${y}`).join(" L ") + " Z";
  const facets = FACETS.map((q, k) =>
    `<polygon points="${q.map(([x, y]) => `${x},${y}`).join(" ")}" fill="${k % 2 ? "#3a1a30" : "#24101e"}" opacity="0.65"/>
     <polyline points="${q.slice(0, 3).map(([x, y]) => `${x},${y}`).join(" ")}" fill="none" stroke="#8a3a3a" stroke-width="1.4" opacity="0.55"/>`).join("");
  const veins = [
    `M 38 136 Q 46 146 44 154`,
    `M 82 146 Q 70 160 72 174`,
    `M 104 150 Q 98 168 102 186`,
    `M 140 156 Q 132 172 140 188 L 142 202`,
    `M 180 152 Q 186 162 180 170`,
    `M 220 146 Q 210 156 212 158`,
  ].map((p) => `<path d="${p}" fill="none" stroke="${OR}" stroke-width="6" opacity="0.55" filter="url(#bl3)"/><path d="${p}" fill="none" stroke="${YE}" stroke-width="1.8" stroke-linecap="round"/>`).join("");
  // Lava drips: a molten bead on each tip, and a falling drop below some.
  const drip = (x, y, s, fallTo = 0) => `<ellipse cx="${x}" cy="${y + s}" rx="${s * 2.4}" ry="${s * 2.4}" fill="${OR}" opacity="0.5" filter="url(#bl3)"/>
    <path d="M ${x - s} ${y - 2} Q ${x - s} ${y + s * 1.6} ${x} ${y + s * 1.8} Q ${x + s} ${y + s * 1.6} ${x + s} ${y - 2} Z" fill="${AM}" stroke="#8a2a1a" stroke-width="1"/>
    <ellipse cx="${x - s * 0.3}" cy="${y + s * 0.6}" rx="${s * 0.3}" ry="${s * 0.5}" fill="${HOT}"/>
    ${fallTo ? `<path d="M ${x} ${fallTo - s * 1.6} Q ${x + s * 0.9} ${fallTo} ${x} ${fallTo + s * 0.9} Q ${x - s * 0.9} ${fallTo} ${x} ${fallTo - s * 1.6} Z" fill="${YE}"/><circle cx="${x}" cy="${fallTo}" r="${s * 2}" fill="${OR}" opacity="0.45" filter="url(#bl2)"/>` : ""}`;
  const drips = drip(72, 176, 3.2, 196) + drip(102, 188, 3.6) + drip(142, 205, 4) + drip(172, 190, 3.2, 206) + drip(204, 180, 2.8) + drip(232, 162, 2.6, 180);

  // Cracked basalt plateau with lava seams.
  const cracks = [
    `M 26 120 L 44 124 L 52 134 L 70 138`,
    `M 80 146 L 104 142 L 118 148`,
    `M 176 148 L 194 140 L 214 142 L 226 134`,
    `M 230 108 L 244 114 L 256 112`,
    `M 200 100 L 214 106 L 228 102`,
    `M 52 104 L 64 110`,
  ].map((p) => `<path d="${p}" fill="none" stroke="${OR}" stroke-width="5" opacity="0.6" filter="url(#bl2)"/><path d="${p}" fill="none" stroke="${YE}" stroke-width="1.6" stroke-linejoin="round" stroke-linecap="round"/>`).join("");

  // The volcano on the left.
  const vx = 42;
  const volcano = `
    <ellipse cx="${vx + 6}" cy="52" rx="36" ry="34" fill="${OR}" opacity="0.3" filter="url(#bl12)"/>
    <ellipse cx="${vx + 4}" cy="82" rx="40" ry="46" fill="${OR}" opacity="0.22" filter="url(#bl16)"/>
    <path d="M 11 124 Q 15 96 24 62 L 32 38 Q ${vx} 32 52 38 L 62 64 Q 76 98 88 122 Q 46 136 11 124 Z" fill="url(#mcCone)" stroke="${OUT}" stroke-width="3" stroke-linejoin="round"/>
    <path d="M 11 124 Q 15 96 24 62 L 32 38 Q ${vx} 32 52 38 L 62 64 Q 76 98 88 122 Q 46 136 11 124 Z" fill="url(#mcConeV)"/>
    <path d="M 31 40 L 23 64 Q 14 90 9 118" fill="none" stroke="#c86a7a" stroke-width="2" stroke-linecap="round" opacity="0.8"/>
    <path d="M 53 40 L 62 64 Q 72 90 84 116" fill="none" stroke="${OR}" stroke-width="1.6" stroke-linecap="round" opacity="0.6"/>
    <path d="M 34 40 L 28 62 Q 20 92 18 124 Q 24 126 30 126 Q 28 92 36 60 Z" fill="#9a4a6a" opacity="0.35"/>
    <path d="M 62 64 Q 76 98 88 122 Q 80 126 70 127 Q 66 96 56 70 Z" fill="#12081a" opacity="0.6"/>
    <path d="M 31 40 Q ${vx} 46 53 40 Q ${vx} 34 31 40 Z" fill="${YE}" stroke="${OUT}" stroke-width="2"/>
    <ellipse cx="${vx}" cy="40" rx="11" ry="3" fill="${HOT}"/>
    <ellipse cx="${vx}" cy="38" rx="20" ry="8" fill="${AM}" opacity="0.7" filter="url(#bl4)"/>
    <path d="M 38 42 Q 34 60 40 72 Q 48 88 40 104 Q 36 114 42 124" fill="none" stroke="${OR}" stroke-width="7" stroke-linecap="round" opacity="0.6" filter="url(#bl3)"/>
    <path d="M 38 42 Q 34 60 40 72 Q 48 88 40 104 Q 36 114 42 124" fill="none" stroke="${AM}" stroke-width="4" stroke-linecap="round"/>
    <path d="M 38 44 Q 35 60 40 72 Q 47 88 40 104" fill="none" stroke="${HOT}" stroke-width="1.5" stroke-linecap="round"/>
    <path d="M 48 42 Q 56 58 54 70 Q 52 80 60 90" fill="none" stroke="${OR}" stroke-width="3" stroke-linecap="round"/>
    <path d="M 48 42 Q 56 58 54 70" fill="none" stroke="${YE}" stroke-width="1.2" stroke-linecap="round"/>
    <path d="M 28 46 Q 24 56 18 62" stroke="#a85a6a" stroke-width="1.8" fill="none" stroke-linecap="round" opacity="0.8"/>`;
  // Smoke curling up from the crater.
  // Smoke billowing up from the crater and drifting right above the node.
  const puffs = [[42, 22, 7.5], [36, 14, 7], [48, 13, 9.5], [60, 15, 8], [64, 11, 7], [76, 11, 8.5], [88, 12, 6.5], [98, 15, 5], [107, 18, 3.6]];
  let smoke = `<g opacity="0.95">`;
  puffs.forEach(([x, y, r]) => (smoke += `<circle cx="${x}" cy="${y}" r="${r + 1.6}" fill="${OUT}" opacity="0.6"/>`));
  puffs.forEach(([x, y, r], k) => (smoke += `<circle cx="${x}" cy="${y}" r="${r}" fill="${k < 2 ? "#7a3450" : k < 4 ? "#5e2e5c" : "#46284e"}"/>`));
  puffs.forEach(([x, y, r], k) => (smoke += `<path d="M ${f(x - r * 0.75)} ${f(y + r * 0.35)} A ${f(r * 0.8)} ${f(r * 0.8)} 0 0 0 ${f(x + r * 0.6)} ${f(y + r * 0.55)}" fill="none" stroke="${k < 3 ? AM : "#c86a7a"}" stroke-width="1.8" stroke-linecap="round" opacity="${f(0.85 - k * 0.1)}"/>
    <path d="M ${f(x - r * 0.5)} ${f(y - r * 0.45)} A ${f(r * 0.6)} ${f(r * 0.6)} 0 0 1 ${f(x + r * 0.2)} ${f(y - r * 0.7)}" fill="none" stroke="#b07a9a" stroke-width="1.2" stroke-linecap="round" opacity="0.5"/>`));
  smoke += `</g><ellipse cx="${vx + 2}" cy="26" rx="14" ry="8" fill="${OR}" opacity="0.5" filter="url(#bl3)"/>`;
  // Embers flying out.
  let embers = "";
  [[26, 16, 1.6], [34, 6, 1.3], [18, 30, 1.2], [64, 30, 1.3], [12, 12, 1.1]].forEach(([x, y, s]) =>
    (embers += `<circle cx="${x}" cy="${y}" r="${s * 3}" fill="${OR}" opacity="0.4" filter="url(#bl2)"/><circle cx="${x}" cy="${y}" r="${s}" fill="${YE}"/>`));

  // The obsidian gate at the volcano's foot.
  const gx = 62, gy = 140;
  const gate = `
    <ellipse cx="${gx}" cy="${gy - 20}" rx="26" ry="28" fill="${OR}" opacity="0.5" filter="url(#bl8)"/>
    <path d="M ${gx - 14} ${gy} L ${gx - 14} ${gy - 24} Q ${gx} ${gy - 44} ${gx + 14} ${gy - 24} L ${gx + 14} ${gy} Z" fill="url(#mcPortal)"/>
    <path d="M ${gx - 8} ${gy - 12} Q ${gx} ${gy - 30} ${gx + 8} ${gy - 14}" fill="none" stroke="${HOT}" stroke-width="1.8" opacity="0.85" stroke-linecap="round"/>
    ${[-1, 1].map((s) => `<path d="M ${gx + s * 14} ${gy + 2} L ${gx + s * 14} ${gy - 26} Q ${gx + s * 17} ${gy - 36} ${gx + s * 24} ${gy - 40} L ${gx + s * 23} ${gy + 2} Z" fill="url(#mcObs)" stroke="${OUT}" stroke-width="2.2" stroke-linejoin="round"/>
      <path d="M ${gx + s * 18} ${gy - 6} l ${s * 2} -7 l ${-s * 1.5} -5 l ${s * 2} -6" fill="none" stroke="${OR}" stroke-width="1.5"/>`).join("")}
    <path d="M ${gx - 26} ${gy - 40} Q ${gx} ${gy - 58} ${gx + 26} ${gy - 40}" fill="none" stroke="${OUT}" stroke-width="9" stroke-linecap="round"/>
    <path d="M ${gx - 26} ${gy - 40} Q ${gx} ${gy - 58} ${gx + 26} ${gy - 40}" fill="none" stroke="#3a2450" stroke-width="5.5" stroke-linecap="round"/>
    <path d="M ${gx - 20} ${gy - 44} Q ${gx} ${gy - 56} ${gx + 18} ${gy - 46}" fill="none" stroke="#9a7ab8" stroke-width="1.2" opacity="0.7"/>
    <circle cx="${gx}" cy="${gy - 49}" r="3.6" fill="${YE}" stroke="${OUT}" stroke-width="1.2"/><circle cx="${gx}" cy="${gy - 49}" r="8" fill="${AM}" opacity="0.5" filter="url(#bl3)"/>`;
  // Obsidian shards.
  const spike = (x, y, h, w, lean = 0) => `<g transform="rotate(${lean} ${x} ${y})">
    <path d="M ${x - w} ${y} L ${x - w * 0.3} ${y - h} L ${x + w * 0.4} ${y - h * 0.8} L ${x + w} ${y} Z" fill="url(#mcObs)" stroke="${OUT}" stroke-width="1.8" stroke-linejoin="round"/>
    <path d="M ${x - w * 0.5} ${y - 2} L ${x - w * 0.3} ${y - h + 2}" stroke="#b08ad8" stroke-width="1.2" opacity="0.8"/></g>`;

  let motes = "";
  for (let k = 0; k < 16; k++) {
    const x = 8 + R() * 264, y = 8 + R() * 196, s = 0.7 + R() * 1.4, c = [YE, OR, AM][k % 3];
    if (Math.hypot(x - 140, y - 92) < 66) continue;
    motes += `<circle cx="${f(x)}" cy="${f(y)}" r="${f(s * 2.6)}" fill="${c}" opacity="0.3" filter="url(#bl2)"/><circle cx="${f(x)}" cy="${f(y)}" r="${f(s)}" fill="${c}" opacity="0.9"/>`;
  }

  return `<svg xmlns="http://www.w3.org/2000/svg" width="280" height="210" viewBox="0 0 280 210">${blurs()}
  <defs>
    <radialGradient id="mcGlow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="${OR}" stop-opacity="0.55"/><stop offset="0.6" stop-color="${OR}" stop-opacity="0.16"/><stop offset="1" stop-color="${OR}" stop-opacity="0"/></radialGradient>
    <linearGradient id="mcRock" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3a1a34"/><stop offset="0.55" stop-color="#22101e"/><stop offset="1" stop-color="#140812"/></linearGradient>
    <linearGradient id="mcRockSide" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#000" stop-opacity="0.35"/><stop offset="0.35" stop-color="#000" stop-opacity="0"/><stop offset="0.7" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.4"/></linearGradient>
    <linearGradient id="mcTop" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2e1830"/><stop offset="1" stop-color="#241226"/></linearGradient>
    <linearGradient id="mcLip" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5a2438"/><stop offset="1" stop-color="#2e1424"/></linearGradient>
    <linearGradient id="mcCone" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#7a3658"/><stop offset="0.5" stop-color="#4a2246"/><stop offset="1" stop-color="#2a1230"/></linearGradient>
    <linearGradient id="mcConeV" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ff6a3d" stop-opacity="0.35"/><stop offset="0.35" stop-color="#ff6a3d" stop-opacity="0"/><stop offset="0.8" stop-color="#ff6a3d" stop-opacity="0"/><stop offset="1" stop-color="#ff6a3d" stop-opacity="0.3"/></linearGradient>
    <linearGradient id="mcObs" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#4a3468"/><stop offset="0.5" stop-color="#1c1030"/><stop offset="1" stop-color="#0e0818"/></linearGradient>
    <radialGradient id="mcPortal" cx="0.5" cy="0.65" r="0.65"><stop offset="0" stop-color="${HOT}"/><stop offset="0.35" stop-color="${AM}"/><stop offset="0.8" stop-color="#ff5a2a"/><stop offset="1" stop-color="#6a1a3a"/></radialGradient>
    <radialGradient id="mcPool" cx="0.5" cy="0.5" r="0.55"><stop offset="0" stop-color="${HOT}"/><stop offset="0.4" stop-color="${AM}"/><stop offset="1" stop-color="#c83a1a"/></radialGradient>
    <clipPath id="mcTopClip"><ellipse cx="${CX}" cy="${CY}" rx="${RX - 2}" ry="${RY - 2}"/></clipPath>
  </defs>
  <ellipse cx="140" cy="160" rx="132" ry="46" fill="url(#mcGlow)"/>
  <ellipse cx="140" cy="188" rx="44" ry="10" fill="${OR}" opacity="0.4" filter="url(#bl8)"/>
  <g transform="translate(0 118) scale(1 0.85) translate(0 -118)">
  <path d="${d}" fill="url(#mcRock)" stroke="${OUT}" stroke-width="3" stroke-linejoin="round"/>
  <path d="${d}" fill="url(#mcRockSide)"/>
  ${facets}${veins}${drips}</g>
  <ellipse cx="${CX}" cy="${CY + 7}" rx="${RX}" ry="${RY}" fill="url(#mcLip)" stroke="${OUT}" stroke-width="3"/>
  <ellipse cx="${CX}" cy="${CY}" rx="${RX}" ry="${RY}" fill="url(#mcTop)" stroke="${OUT}" stroke-width="3"/>
  <g clip-path="url(#mcTopClip)">
    ${cracks}
    <ellipse cx="46" cy="120" rx="54" ry="20" fill="${OR}" opacity="0.3" filter="url(#bl8)"/>
    <ellipse cx="226" cy="122" rx="14" ry="5" fill="url(#mcPool)" stroke="${OUT}" stroke-width="1.8"/>
    <ellipse cx="226" cy="121" rx="22" ry="9" fill="${OR}" opacity="0.35" filter="url(#bl4)"/>
    <ellipse cx="222" cy="120.5" rx="4" ry="1.2" fill="#fff" opacity="0.7"/>
  </g>
  <ellipse cx="${CX}" cy="${CY}" rx="${RX - 3}" ry="${RY - 3}" fill="none" stroke="#a8506a" stroke-width="1.5" opacity="0.5"/>
  <path d="M ${CX - RX + 2} ${CY + 4} Q ${CX} ${CY + RY * 2 + 6} ${CX + RX - 2} ${CY + 4}" fill="none" stroke="${OR}" stroke-width="5" opacity="0.45" filter="url(#bl3)"/>
  <path d="M ${CX - RX + 2} ${CY + 4} Q ${CX} ${CY + RY * 2 + 6} ${CX + RX - 2} ${CY + 4}" fill="none" stroke="${YE}" stroke-width="1.3" opacity="0.75"/>
  <g transform="translate(46 124) scale(1.12) translate(-46 -124)">${volcano}</g>${smoke}${embers}
  ${spike(18, 134, 18, 5, -10)}${spike(90, 142, 14, 4, 8)}
  ${gate}
  <!-- label side: low details only -->
  ${spike(250, 120, 14, 4.5, 8)}${spike(242, 124, 8, 3, -6)}
  ${motes}
  </svg>`;
}

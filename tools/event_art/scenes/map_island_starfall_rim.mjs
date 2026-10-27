// World map island, Starfall Rim: a floating chunk of cratered moon rock. On
// the right a glowing crater rim with gold crystals catches a falling star
// streaking in from above; a small ringed moon orbits overhead and a tiny black
// hole with a gold accretion ring hangs at the top corner. The left (label)
// side stays low: a couple of small craters and one tiny crystal. The underside
// is slate-indigo rock with gold veins, hanging gold crystals and a few rock
// crumbs drifting below. The game draws the zone node over (140, 92).
import { blurs, rng } from "./_shop_charge_pad_glow_chest_parts.mjs";

export const size = [280, 210];
export const transparent = true;
export const dir = "game/ui/map_art";

const f = (n) => (+n).toFixed(1);
const GD = "#ffd23d", PALE = "#fff8d0", LAV = "#9a8cff", OUT = "#0c0a22";
const CX = 140, CY = 118, RX = 118, RY = 34;

// Underside silhouette, left rim to right rim (uneven stalactites).
const PTS = [[22, 118], [26, 128], [32, 138], [42, 142], [50, 162], [58, 150], [70, 158], [80, 182], [88, 168],
  [100, 172], [110, 194], [118, 178], [128, 186], [140, 206], [152, 194], [164, 178], [176, 184], [184, 190],
  [190, 170], [204, 166], [216, 178], [222, 156], [234, 152], [244, 140], [252, 132], [256, 124], [258, 118]];
const FACETS = [
  [[28, 130], [56, 136], [50, 162], [42, 142], [32, 138]],
  [[66, 142], [96, 148], [80, 182], [70, 158], [62, 152]],
  [[106, 152], [146, 154], [140, 206], [128, 186], [118, 178]],
  [[160, 152], [196, 148], [184, 190], [176, 184], [164, 178]],
  [[206, 146], [240, 134], [222, 156], [216, 178], [208, 166]],
];

export default function () {
  const R = rng(97);
  const d = "M " + PTS.map(([x, y]) => `${x} ${y}`).join(" L ") + " Z";
  const facets = FACETS.map((q, k) =>
    `<polygon points="${q.map(([x, y]) => `${x},${y}`).join(" ")}" fill="${k % 2 ? "#3e3a78" : "#25224e"}" opacity="0.6"/>
     <polyline points="${q.slice(0, 3).map(([x, y]) => `${x},${y}`).join(" ")}" fill="none" stroke="#8a80d8" stroke-width="1.4" opacity="0.5"/>`).join("");
  const veins = [
    `M 40 136 Q 46 146 50 158`,
    `M 84 150 Q 76 164 80 178`,
    `M 136 158 Q 146 174 140 190 L 141 200`,
    `M 186 154 Q 178 170 184 186`,
    `M 226 144 Q 216 156 216 172`,
  ].map((p) => `<path d="${p}" fill="none" stroke="${GD}" stroke-width="5" opacity="0.45" filter="url(#bl3)"/><path d="${p}" fill="none" stroke="${PALE}" stroke-width="1.5" stroke-linecap="round"/>`).join("");
  // Gold crystals hanging under the rim.
  const hang = (x, y, l, w) => `<path d="M ${x - w} ${y} L ${x} ${y + l} L ${x + w} ${y} Z" fill="url(#srCry)" stroke="${OUT}" stroke-width="1.6" stroke-linejoin="round"/>
    <path d="M ${x - w * 0.3} ${y + 1} L ${x} ${y + l * 0.8}" stroke="${PALE}" stroke-width="1.2" opacity="0.8"/>
    <ellipse cx="${x}" cy="${y + l * 0.6}" rx="${w * 2}" ry="${l * 0.5}" fill="${GD}" opacity="0.3" filter="url(#bl4)"/>`;
  const crystals = hang(80, 176, 14, 4) + hang(110, 188, 16, 4.5) + hang(140, 198, 18, 5) + hang(184, 184, 12, 3.6) + hang(216, 172, 11, 3.4);
  // Rock crumbs floating under the island.
  const crumb = (x, y, s) => `<path d="M ${f(x - s)} ${f(y)} L ${f(x - s * 0.3)} ${f(y - s * 0.8)} L ${f(x + s * 0.8)} ${f(y - s * 0.4)} L ${f(x + s)} ${f(y + s * 0.4)} L ${f(x)} ${f(y + s * 0.8)} Z" fill="#3a3466" stroke="${OUT}" stroke-width="1.4"/><path d="M ${f(x - s * 0.5)} ${f(y - s * 0.3)} L ${f(x + s * 0.4)} ${f(y - s * 0.3)}" stroke="#8a80d8" stroke-width="1" opacity="0.7"/>`;
  const crumbs = crumb(52, 186, 5) + crumb(226, 196, 4) + crumb(98, 204, 3.2) + crumb(246, 172, 3);

  // Cratered moon-rock plateau.
  const crater = (x, y, s, lit = false) => `<ellipse cx="${x}" cy="${y}" rx="${s}" ry="${s * 0.36}" fill="#1a1740"/>
    <path d="M ${x - s} ${y} A ${s} ${s * 0.36} 0 0 0 ${x + s} ${y}" fill="none" stroke="#8a80d8" stroke-width="1.5" opacity="0.7"/>
    ${lit ? `<ellipse cx="${x}" cy="${y + 0.5}" rx="${s * 0.6}" ry="${s * 0.2}" fill="${GD}" opacity="0.5" filter="url(#bl2)"/>` : ""}`;
  const topCraters = crater(36, 118, 9) + crater(62, 130, 6, true) + crater(112, 140, 7) + crater(170, 142, 6) + crater(54, 106, 5);

  // The big crater rim on the right, glowing gold inside.
  const rx0 = 232, ry0 = 116;
  const bigCrater = `
    <ellipse cx="${rx0}" cy="${ry0 - 4}" rx="44" ry="26" fill="${GD}" opacity="0.45" filter="url(#bl8)"/>
    <path d="M ${rx0 - 40} ${ry0} Q ${rx0 - 36} ${ry0 - 18} ${rx0 - 18} ${ry0 - 20} L ${rx0 + 16} ${ry0 - 21} Q ${rx0 + 36} ${ry0 - 18} ${rx0 + 40} ${ry0} Q ${rx0} ${ry0 + 16} ${rx0 - 40} ${ry0} Z" fill="url(#srRimRock)" stroke="${OUT}" stroke-width="2.5" stroke-linejoin="round"/>
    <ellipse cx="${rx0}" cy="${ry0 - 9}" rx="28" ry="9" fill="url(#srBowl)" stroke="${OUT}" stroke-width="2"/>
    <ellipse cx="${rx0}" cy="${ry0 - 8}" rx="18" ry="5" fill="${PALE}" opacity="0.8" filter="url(#bl3)"/>
    <path d="M ${rx0 - 26} ${ry0 - 11} Q ${rx0 - 10} ${ry0 - 19} ${rx0 + 10} ${ry0 - 18}" fill="none" stroke="#c8c0ff" stroke-width="1.5" opacity="0.7"/>
    <path d="M ${rx0 - 34} ${ry0 + 2} Q ${rx0} ${ry0 + 12} ${rx0 + 34} ${ry0 + 2}" fill="none" stroke="#6a62a8" stroke-width="1.5" opacity="0.6"/>`;
  // Gold crystal shards standing around the crater.
  const shard = (x, y, h, w, lean = 0) => `<g transform="rotate(${lean} ${x} ${y})">
    <ellipse cx="${x}" cy="${y - h * 0.5}" rx="${w * 2.2}" ry="${h * 0.7}" fill="${GD}" opacity="0.3" filter="url(#bl4)"/>
    <path d="M ${x - w} ${y} L ${x - w * 0.8} ${y - h * 0.7} L ${x} ${y - h} L ${x + w * 0.8} ${y - h * 0.7} L ${x + w} ${y} Z" fill="url(#srCry)" stroke="${OUT}" stroke-width="1.8" stroke-linejoin="round"/>
    <path d="M ${x} ${y - h} L ${x - w * 0.15} ${y - 1}" stroke="#c87a2a" stroke-width="1.2" opacity="0.7"/>
    <path d="M ${x - w * 0.55} ${y - h * 0.65} L ${x - w * 0.5} ${y - h * 0.2}" stroke="#fff" stroke-width="1.4" stroke-linecap="round" opacity="0.85"/></g>`;
  const shards = shard(200, 112, 30, 6, -16) + shard(212, 118, 18, 4.5, -6) + shard(264, 116, 42, 7.5, 9) + shard(252, 126, 20, 4.5, 2) + shard(246, 100, 14, 3.5, 14);

  // The falling star: comes in from the upper left, its trail fading behind.
  const sx = 238, sy = 48;
  const star = (cx, cy, r, inner = 0.45) => {
    let p = "";
    for (let k = 0; k < 10; k++) {
      const a = -Math.PI / 2 + (k * Math.PI) / 5, rr = k % 2 ? r * inner : r;
      p += `${k ? "L" : "M"} ${f(cx + Math.cos(a) * rr)} ${f(cy + Math.sin(a) * rr)} `;
    }
    return p + "Z";
  };
  const fall = `
    <path d="M ${sx - 6} ${sy + 8} L 136 0 L 176 0 L ${sx + 8} ${sy - 6} Z" fill="url(#srTrail)" opacity="0.9"/>
    <path d="M ${sx - 4} ${sy + 4} Q 196 26 128 10" fill="none" stroke="url(#srTrail2)" stroke-width="12" stroke-linecap="round" opacity="0.7" filter="url(#bl3)"/>
    <path d="M ${sx - 2} ${sy - 4} Q 210 16 176 2" fill="none" stroke="${PALE}" stroke-width="2" stroke-linecap="round" opacity="0.6"/>
    <circle cx="${sx}" cy="${sy}" r="34" fill="${GD}" opacity="0.45" filter="url(#bl12)"/>
    <circle cx="${sx}" cy="${sy}" r="13" fill="${PALE}" opacity="0.6" filter="url(#bl4)"/>
    <path d="${star(sx, sy, 19)}" fill="${GD}" stroke="#8a5a10" stroke-width="2" stroke-linejoin="round" transform="rotate(18 ${sx} ${sy})"/>
    <path d="${star(sx, sy, 10, 0.5)}" fill="${PALE}" transform="rotate(18 ${sx} ${sy})"/>
    <circle cx="${sx - 4}" cy="${sy - 4}" r="2" fill="#fff"/>`;
  // A little ringed moon above the crater.
  const mx = 226, my = 76;
  const moon = `
    <ellipse cx="${mx}" cy="${my}" rx="20" ry="6" fill="none" stroke="#c8b070" stroke-width="2.5" opacity="0.6" transform="rotate(-18 ${mx} ${my})"/>
    <circle cx="${mx}" cy="${my}" r="11" fill="url(#srMoon)" stroke="${OUT}" stroke-width="1.8"/>
    <circle cx="${mx + 2}" cy="${my + 2}" r="2.2" fill="#4a3a8a" opacity="0.7"/>
    <path d="M ${mx - 20} ${my} A 20 6 0 0 0 ${mx + 20} ${my}" fill="none" stroke="#ffe08a" stroke-width="2.5" transform="rotate(-18 ${mx} ${my})"/>`;
  // A tiny black hole in the top corner, its accretion ring lit gold.
  const bx = 262, by = 14;
  const hole = `
    <ellipse cx="${bx}" cy="${by}" rx="18" ry="8" fill="${GD}" opacity="0.25" filter="url(#bl4)"/>
    <ellipse cx="${bx}" cy="${by}" rx="15" ry="4.5" fill="none" stroke="#ff9a3d" stroke-width="2.5" opacity="0.8"/>
    <circle cx="${bx}" cy="${by}" r="6.5" fill="#000" stroke="${PALE}" stroke-width="1.2"/>
    <path d="M ${bx - 15} ${by} A 15 4.5 0 0 0 ${bx + 15} ${by}" fill="none" stroke="${PALE}" stroke-width="1.8"/>`;
  // Orbit arc and sparkles.
  const twinkle = (x, y, s, c = "#fff", o = 1) => `<path d="M ${x} ${y - s} Q ${x} ${y} ${x + s} ${y} Q ${x} ${y} ${x} ${y + s} Q ${x} ${y} ${x - s} ${y} Q ${x} ${y} ${x} ${y - s} Z" fill="${c}" opacity="${o}"/>`;
  let motes = "";
  for (let k = 0; k < 16; k++) {
    const x = 8 + R() * 264, y = 8 + R() * 196, s = 0.7 + R() * 1.4, c = [GD, PALE, LAV][k % 3];
    if (Math.hypot(x - 140, y - 92) < 66) continue;
    motes += `<circle cx="${f(x)}" cy="${f(y)}" r="${f(s * 2.6)}" fill="${c}" opacity="0.3" filter="url(#bl2)"/><circle cx="${f(x)}" cy="${f(y)}" r="${f(s)}" fill="${c}" opacity="0.9"/>`;
  }

  return `<svg xmlns="http://www.w3.org/2000/svg" width="280" height="210" viewBox="0 0 280 210">${blurs()}
  <defs>
    <radialGradient id="srGlow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="${GD}" stop-opacity="0.45"/><stop offset="0.6" stop-color="${GD}" stop-opacity="0.13"/><stop offset="1" stop-color="${GD}" stop-opacity="0"/></radialGradient>
    <linearGradient id="srRock" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#363266"/><stop offset="0.55" stop-color="#1e1a46"/><stop offset="1" stop-color="#100e2a"/></linearGradient>
    <linearGradient id="srRockSide" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#000" stop-opacity="0.35"/><stop offset="0.35" stop-color="#000" stop-opacity="0"/><stop offset="0.7" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.4"/></linearGradient>
    <linearGradient id="srTop" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#302c62"/><stop offset="1" stop-color="#24204e"/></linearGradient>
    <linearGradient id="srLip" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5a54a0"/><stop offset="1" stop-color="#2e2a62"/></linearGradient>
    <linearGradient id="srRimRock" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6a62a8"/><stop offset="1" stop-color="#2e2a62"/></linearGradient>
    <radialGradient id="srBowl" cx="0.5" cy="0.5" r="0.6"><stop offset="0" stop-color="#fffbe0"/><stop offset="0.45" stop-color="${GD}"/><stop offset="1" stop-color="#c8662a"/></radialGradient>
    <linearGradient id="srCry" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fff6c0"/><stop offset="0.5" stop-color="${GD}"/><stop offset="1" stop-color="#c87a2a"/></linearGradient>
    <radialGradient id="srMoon" cx="0.35" cy="0.3" r="0.8"><stop offset="0" stop-color="#e0d4ff"/><stop offset="0.5" stop-color="#9a7cff"/><stop offset="1" stop-color="#3a2e88"/></radialGradient>
    <linearGradient id="srTrail" x1="1" y1="1" x2="0" y2="0"><stop offset="0" stop-color="${PALE}" stop-opacity="0.9"/><stop offset="0.5" stop-color="${GD}" stop-opacity="0.4"/><stop offset="1" stop-color="${GD}" stop-opacity="0"/></linearGradient>
    <linearGradient id="srTrail2" x1="1" y1="1" x2="0" y2="0"><stop offset="0" stop-color="#ff9a3d" stop-opacity="0.8"/><stop offset="1" stop-color="#ff9a3d" stop-opacity="0"/></linearGradient>
    <clipPath id="srTopClip"><ellipse cx="${CX}" cy="${CY}" rx="${RX - 2}" ry="${RY - 2}"/></clipPath>
  </defs>
  <ellipse cx="140" cy="160" rx="132" ry="46" fill="url(#srGlow)"/>
  <ellipse cx="140" cy="188" rx="40" ry="10" fill="${GD}" opacity="0.3" filter="url(#bl8)"/>
  <g transform="translate(0 118) scale(1 0.85) translate(0 -118)">
  ${crumbs}
  <path d="${d}" fill="url(#srRock)" stroke="${OUT}" stroke-width="3" stroke-linejoin="round"/>
  <path d="${d}" fill="url(#srRockSide)"/>
  ${facets}${veins}${crystals}</g>
  <ellipse cx="${CX}" cy="${CY + 7}" rx="${RX}" ry="${RY}" fill="url(#srLip)" stroke="${OUT}" stroke-width="3"/>
  <ellipse cx="${CX}" cy="${CY}" rx="${RX}" ry="${RY}" fill="url(#srTop)" stroke="${OUT}" stroke-width="3"/>
  <g clip-path="url(#srTopClip)">
    ${topCraters}
    <ellipse cx="232" cy="112" rx="56" ry="24" fill="${GD}" opacity="0.18" filter="url(#bl8)"/>
  </g>
  <ellipse cx="${CX}" cy="${CY}" rx="${RX - 3}" ry="${RY - 3}" fill="none" stroke="#9a92e8" stroke-width="1.5" opacity="0.55"/>
  <path d="M ${CX - RX + 2} ${CY + 4} Q ${CX} ${CY + RY * 2 + 6} ${CX + RX - 2} ${CY + 4}" fill="none" stroke="${GD}" stroke-width="5" opacity="0.35" filter="url(#bl3)"/>
  <path d="M ${CX - RX + 2} ${CY + 4} Q ${CX} ${CY + RY * 2 + 6} ${CX + RX - 2} ${CY + 4}" fill="none" stroke="${PALE}" stroke-width="1.3" opacity="0.7"/>
  ${hole}${moon}
  ${bigCrater}${shards}
  ${fall}
  <!-- label side: low details only -->
  ${shard(30, 122, 10, 3, -8)}
  ${twinkle(270, 70, 5, PALE, 0.9)}${twinkle(16, 92, 4, "#e8e0ff", 0.8)}${twinkle(240, 150, 3.5, PALE, 0.8)}
  ${motes}
  </svg>`;
}

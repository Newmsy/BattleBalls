// Campaign world map, Bramble Hollow island: a floating chunk of mossy
// forest floor. On the right a twisted old tree with a glowing door in its
// trunk stands behind a thorny briar arch and a thorn hedge; roots and
// thorny vines with lime glowing buds hang from the earthy underside. A
// small glowing sinkhole sits on the calm left side. The game draws the
// zone's round node over the plateau's centre (disc at 140,92 r 62) and the
// zone's name on the left.
import { blurs, rng, shade } from "./_zone_parts.mjs";
import { twinkle, mix } from "./_map_token.mjs";

export const size = [280, 210];
export const transparent = true;
export const dir = "game/ui/map_art";

const f = (n) => (+n).toFixed(1);
const Z = "#9bd84a";
const OUT = "#0c0812";
const CX = 140, CY = 118, RX = 118, RY = 34;
const rim = (x) => RY * Math.sqrt(Math.max(0, 1 - ((x - CX) / RX) ** 2));
const VINE = "#3a2a4a";


// Rocky underside: a tapering mass of lobes ending in tips, deepest in the middle.
function underside(seed, { n = 13, depth = 30, spike = 6, jag = 0.5, sx = 0, sy = 0, pw = 0.8, lit = "#2c4a78", dark = "#02040c" } = {}) {
  const R = rng(seed);
  const tips = [], pt = [];
  for (let i = 1; i < n; i++) {
    const x = CX - RX + 4 + (i / n) * (RX * 2 - 8) + (R() - 0.5) * 6;
    const u = Math.max(0, 1 - ((x - CX) / RX) ** 2);
    const base = CY + rim(x) + 6;
    const deep = base + 4 + depth * Math.pow(u, pw) + (Math.abs(x - CX) < 12 ? spike : 0);
    const tip = i % 2 === 1;
    const y = tip ? deep + R() * 6 : base + (deep - base) * (0.5 + R() * 0.2);
    pt.push([x + sx, y + sy, tip]);
    if (tip) tips.push([x + sx, y + sy]);
  }
  let d = `M ${f(CX - RX + sx)} ${f(CY + sy)} L ${f(CX - RX + 2 + sx)} ${f(CY + 10 + sy)}`;
  let [px, py] = [CX - RX + 2 + sx, CY + 10 + sy];
  for (const [x, y, tip] of pt) {
    if (tip) d += ` C ${f(px + (x - px) * 0.2)} ${f(py + (y - py) * (1 - jag))} ${f(x - (x - px) * 0.25)} ${f(y - (y - py) * 0.35)} ${f(x)} ${f(y)}`;
    else d += ` C ${f(px + (x - px) * 0.25)} ${f(py - (py - y) * 0.35)} ${f(x - (x - px) * 0.2)} ${f(y + (py - y) * (1 - jag))} ${f(x)} ${f(y)}`;
    [px, py] = [x, y];
  }
  d += ` L ${f(CX + RX - 2 + sx)} ${f(CY + 10 + sy)} L ${f(CX + RX + sx)} ${f(CY + sy)} Z`;
  const ridges = tips.map(([x, y]) => {
    const by = CY + rim(x) + 8;
    return `<path d="M ${f(x - 8)} ${f(by)} Q ${f(x - 5)} ${f((by + y) / 2)} ${f(x - 0.5)} ${f(y - 3)}" stroke="${lit}" stroke-width="2" fill="none" opacity="0.7" stroke-linecap="round"/>
      <path d="M ${f(x + 9)} ${f(by + 2)} Q ${f(x + 5)} ${f((by + y) / 2)} ${f(x + 1)} ${f(y - 6)}" stroke="${dark}" stroke-width="2.5" fill="none" opacity="0.55" stroke-linecap="round"/>`;
  }).join("");
  return { d, tips, ridges };
}

// Thorns along a polyline of points: little curved hooks alternating sides.
function thorns(pts, s = 1, col = shade(VINE, 0.25)) {
  let out = "";
  for (let k = 1; k < pts.length - 1; k++) {
    const [x0, y0] = pts[k - 1], [x1, y1] = pts[k + 1], [x, y] = pts[k];
    const dx = x1 - x0, dy = y1 - y0, L = Math.hypot(dx, dy) || 1;
    const nx = (-dy / L) * (k % 2 ? 1 : -1), ny = (dx / L) * (k % 2 ? 1 : -1);
    const tx = x + nx * 6 * s + (dx / L) * 2 * s, ty = y + ny * 6 * s + (dy / L) * 2 * s;
    out += `<path d="M ${f(x - (dx / L) * 2.5 * s)} ${f(y - (dy / L) * 2.5 * s)} L ${f(tx)} ${f(ty)} L ${f(x + (dx / L) * 2.5 * s)} ${f(y + (dy / L) * 2.5 * s)} Z" fill="${col}" stroke="${OUT}" stroke-width="1" stroke-linejoin="round"/>`;
  }
  return out;
}

// Sample a cubic bezier into points.
function bez(p0, p1, p2, p3, n = 10) {
  return Array.from({ length: n + 1 }, (_, i) => {
    const t = i / n, u = 1 - t;
    return [0, 1].map((j) => u * u * u * p0[j] + 3 * u * u * t * p1[j] + 3 * u * t * t * p2[j] + t * t * t * p3[j]);
  });
}

// A thorny vine along a bezier: outline, body, highlight, thorns, glowing buds.
function vine(p0, p1, p2, p3, w = 5, { buds = [], col = VINE } = {}) {
  const d = `M ${f(p0[0])} ${f(p0[1])} C ${f(p1[0])} ${f(p1[1])} ${f(p2[0])} ${f(p2[1])} ${f(p3[0])} ${f(p3[1])}`;
  const pts = bez(p0, p1, p2, p3, 12);
  return `<path d="${d}" stroke="${OUT}" stroke-width="${w + 3}" fill="none" stroke-linecap="round"/>
    ${thorns(pts, w / 5, shade(col, 0.2))}
    <path d="${d}" stroke="${col}" stroke-width="${w}" fill="none" stroke-linecap="round"/>
    <path d="${d}" stroke="${shade(col, 0.35)}" stroke-width="${f(w * 0.3)}" fill="none" stroke-linecap="round" opacity="0.7" transform="translate(-0.8 -0.8)"/>
    ${buds.map((i) => { const [x, y] = pts[i]; return `<circle cx="${f(x)}" cy="${f(y)}" r="5" fill="${Z}" opacity="0.5" filter="url(#bl2)"/><circle cx="${f(x)}" cy="${f(y)}" r="2.2" fill="#e8ffb0" stroke="${OUT}" stroke-width="0.8"/>`; }).join("")}`;
}

function toadstool(x, y, s, c) {
  return `<circle cx="${x}" cy="${y - s}" r="${s * 2.4}" fill="${c}" opacity="0.35" filter="url(#bl3)"/>
    <rect x="${f(x - s * 0.25)}" y="${f(y - s)}" width="${f(s * 0.5)}" height="${s}" fill="#e8dcc8" stroke="${OUT}" stroke-width="0.8"/>
    <path d="M ${f(x - s)} ${f(y - s * 0.9)} Q ${x} ${f(y - s * 2.3)} ${f(x + s)} ${f(y - s * 0.9)} Z" fill="${c}" stroke="${OUT}" stroke-width="1.2"/>
    <circle cx="${f(x - s * 0.3)}" cy="${f(y - s * 1.4)}" r="${f(s * 0.18)}" fill="#fff" opacity="0.8"/>`;
}

export default function () {
  const R = rng(83);
  const U = underside(13, { depth: 30, spike: 6, jag: 0.45, lit: "#5a4a3a", dark: "#0a0608" });
  const B = underside(31, { n: 11, depth: 22, spike: 0, sx: -3, sy: -4, jag: 0.45 });
  // Dangling roots and a few thorny vines under the island.
  const roots = U.tips.filter((_, i) => i % 2 === 0).map(([x, y], k) => {
    const L = 8 + (k % 3) * 5;
    return `<path d="M ${f(x)} ${f(y - 3)} q ${k % 2 ? 4 : -4} ${f(L * 0.5)} ${k % 2 ? 1 : -1} ${L}" stroke="${OUT}" stroke-width="3.5" fill="none" stroke-linecap="round"/>
      <path d="M ${f(x)} ${f(y - 3)} q ${k % 2 ? 4 : -4} ${f(L * 0.5)} ${k % 2 ? 1 : -1} ${L}" stroke="#6a5038" stroke-width="1.8" fill="none" stroke-linecap="round"/>`;
  }).join("");
  const veins = U.tips.filter((_, i) => i % 2 === 1).map(([tx, ty], k) => {
    const sx = tx + (k % 2 ? 7 : -7), sy = CY + rim(sx) + 9;
    const d = `M ${f(sx)} ${f(sy)} Q ${f(sx + (tx - sx) * 0.2 + (k % 2 ? 6 : -6))} ${f((sy + ty) / 2)} ${f(tx)} ${f(ty - 5)}`;
    return `<path d="${d}" stroke="${Z}" stroke-width="4" fill="none" opacity="0.45" filter="url(#bl2)"/><path d="${d}" stroke="#d8ff7a" stroke-width="1.5" fill="none" stroke-linecap="round"/>
      <circle cx="${f(tx)}" cy="${f(ty - 5)}" r="4" fill="${Z}" opacity="0.6" filter="url(#bl2)"/><circle cx="${f(tx)}" cy="${f(ty - 5)}" r="1.7" fill="#f0ffc8"/>`;
  }).join("");
  const hanging = vine([46, 140], [40, 158], [58, 164], [52, 182], 3.5, { buds: [12] }) + vine([214, 150], [222, 166], [204, 172], [212, 190], 3.5, { buds: [12] });
  // Moss fringe over the front lip.
  let fringe = "";
  for (let k = 0; k < 30; k++) {
    const x = CX - RX + 14 + (k / 29) * (RX * 2 - 28) + (R() - 0.5) * 4, y = CY + rim(x) + 1 + R() * 2, r = 2.5 + R() * 3.2;
    fringe += `<ellipse cx="${f(x)}" cy="${f(y)}" rx="${f(r * 1.3)}" ry="${f(r * 0.75)}" fill="${["#3a5a2a", "#4a6a2a", "#2e4a24"][k % 3]}" stroke="${OUT}" stroke-width="1.1"/>`;
  }
  // The twisted old tree with a glowing door.
  const tx = 236, ty = 126;
  const trunk = `M ${tx - 22} ${ty + 2} Q ${tx - 12} ${ty - 10} ${tx - 14} ${ty - 30} Q ${tx - 18} ${ty - 52} ${tx - 6} ${ty - 66}
    Q ${tx - 16} ${ty - 82} ${tx - 34} ${ty - 92} L ${tx - 30} ${ty - 98} Q ${tx - 10} ${ty - 90} ${tx} ${ty - 76}
    Q ${tx + 4} ${ty - 96} ${tx - 4} ${ty - 110} L ${tx + 2} ${ty - 114} Q ${tx + 14} ${ty - 96} ${tx + 8} ${ty - 72}
    Q ${tx + 20} ${ty - 84} ${tx + 32} ${ty - 84} L ${tx + 32} ${ty - 78} Q ${tx + 18} ${ty - 72} ${tx + 12} ${ty - 58}
    Q ${tx + 8} ${ty - 40} ${tx + 14} ${ty - 24} Q ${tx + 16} ${ty - 6} ${tx + 26} ${ty + 2} Z`;
  const canopy = [[tx - 36, ty - 100, 12], [tx - 2, ty - 116, 14], [tx + 26, ty - 90, 11], [tx - 20, ty - 110, 11], [tx + 14, ty - 106, 12]];
  const twigs = vine([tx - 30, ty - 96], [tx - 44, ty - 100], [tx - 50, ty - 112], [tx - 46, ty - 124], 3, { buds: [12], col: "#4a3634" })
    + vine([tx + 30, ty - 82], [tx + 40, ty - 84], [tx + 44, ty - 96], [tx + 38, ty - 106], 3, { buds: [12], col: "#4a3634" });
  const tree = `<g transform="translate(${tx} ${ty}) scale(0.86) translate(${-tx} ${-ty})">
    <ellipse cx="${tx}" cy="${ty - 70}" rx="54" ry="56" fill="${Z}" opacity="0.14" filter="url(#bl12)"/>
    ${canopy.map(([x, y, r]) => `<circle cx="${x}" cy="${y}" r="${r + 2}" fill="${OUT}"/>`).join("")}
    ${canopy.map(([x, y, r], k) => `<circle cx="${x}" cy="${y}" r="${r}" fill="${k % 2 ? "#2a4026" : "#324a2a"}"/><circle cx="${x - r * 0.3}" cy="${y - r * 0.35}" r="${r * 0.5}" fill="#4a6a32" opacity="0.8"/>`).join("")}
    ${[[tx - 40, ty - 104], [tx + 2, ty - 124], [tx + 34, ty - 92], [tx - 24, ty - 96], [tx + 16, ty - 110], [tx - 8, ty - 106]].map(([x, y], k) => `<path d="M ${x} ${y} q ${k % 2 ? 6 : -6} -4 ${k % 2 ? 9 : -9} 2 q ${k % 2 ? -4 : 4} 3 ${k % 2 ? -9 : 9} -2 Z" fill="${k % 3 ? "#7fbf4a" : "#d8ff7a"}" stroke="${OUT}" stroke-width="1"/>`).join("")}
    ${twigs}
    <path d="${trunk}" fill="url(#bhBark)" stroke="${OUT}" stroke-width="2.6" stroke-linejoin="round"/>
    <path d="M ${tx - 8} ${ty - 6} Q ${tx - 10} ${ty - 36} ${tx - 2} ${ty - 62} M ${tx + 6} ${ty - 10} Q ${tx + 2} ${ty - 40} ${tx + 6} ${ty - 64}" stroke="#2a1c22" stroke-width="2" fill="none"/>
    <path d="M ${tx - 13} ${ty - 28} Q ${tx - 16} ${ty - 48} ${tx - 8} ${ty - 62}" stroke="#8a6a58" stroke-width="2" fill="none" opacity="0.7" stroke-linecap="round"/>
    <ellipse cx="${tx}" cy="${ty - 14}" rx="13" ry="16" fill="${Z}" opacity="0.6" filter="url(#bl4)"/>
    <path d="M ${tx - 7} ${ty} L ${tx - 7} ${ty - 16} Q ${tx} ${ty - 28} ${tx + 7} ${ty - 16} L ${tx + 7} ${ty} Z" fill="url(#bhDoor)" stroke="${OUT}" stroke-width="2"/>
    ${[[-5, -14], [0, -22], [5, -14]].map(([dx, dy]) => `<circle cx="${tx + dx}" cy="${ty + dy}" r="1" fill="#fffbd0"/>`).join("")}
    <ellipse cx="${tx}" cy="${ty + 2}" rx="16" ry="4" fill="${Z}" opacity="0.55" filter="url(#bl3)"/>
    ${[[tx - 26, ty + 2, -1], [tx + 28, ty + 2, 1]].map(([x, y, d]) => `<path d="M ${x} ${y} q ${d * 6} -2 ${d * 10} 4" stroke="${OUT}" stroke-width="5" fill="none" stroke-linecap="round"/><path d="M ${x} ${y} q ${d * 6} -2 ${d * 10} 4" stroke="#5a4038" stroke-width="2.5" fill="none" stroke-linecap="round"/>`).join("")}</g>`;
  // Briar arch in front of the tree.
  const arch = `<ellipse cx="208" cy="146" rx="16" ry="4.5" fill="${Z}" opacity="0.35" filter="url(#bl3)"/>`
    + vine([190, 152], [182, 108], [226, 98], [224, 146], 5.5, { buds: [3, 6, 9] })
    + vine([196, 152], [194, 124], [214, 114], [218, 132], 3, { buds: [5, 8], col: "#4a3458" })
    + vine([224, 146], [230, 150], [236, 146], [234, 140], 2.4, { col: "#4a3458" });
  // Thorn hedge on the right edge.
  const hedge = `
    ${[[258, 132, 10], [266, 126, 7], [248, 137, 7], [260, 121, 6]].map(([x, y, r]) => `<circle cx="${x}" cy="${y}" r="${r + 1.6}" fill="${OUT}"/>`).join("")}
    ${[[258, 132, 10], [266, 126, 7], [248, 137, 7], [260, 121, 6]].map(([x, y, r], k) => `<circle cx="${x}" cy="${y}" r="${r}" fill="${k % 2 ? "#2e4a24" : "#3a5a2a"}"/><circle cx="${x - r * 0.3}" cy="${y - r * 0.4}" r="${r * 0.45}" fill="#5a7a3a" opacity="0.8"/>`).join("")}
    ${vine([246, 134], [250, 118], [260, 112], [268, 116], 2.4, { buds: [6] })}
    ${[[252, 125], [264, 132], [256, 139]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="1.8" fill="#ff8ad0"/>`).join("")}`;
  // Left (label) side: a small glowing sinkhole, toadstools and a fern.
  const sink = `
    <ellipse cx="52" cy="122" rx="22" ry="7" fill="#5a4a3a" stroke="${OUT}" stroke-width="2"/>
    <ellipse cx="52" cy="122.5" rx="18" ry="5" fill="url(#bhHole)"/>
    <ellipse cx="52" cy="123" rx="9" ry="2.2" fill="${Z}" opacity="0.7" filter="url(#bl2)"/>
    <path d="M 36 120 Q 52 114 68 120" stroke="#7a6a4a" stroke-width="1.4" fill="none" opacity="0.8"/>
    ${[[30, 118], [74, 121], [62, 128]].map(([x, y]) => `<ellipse cx="${x}" cy="${y}" rx="3.5" ry="2" fill="#6a5a48" stroke="${OUT}" stroke-width="1"/>`).join("")}`;
  let ferns = "";
  for (let k = 0; k < 26; k++) {
    const x = 24 + R() * 210, yb = CY + rim(x) * (0.2 + R() * 0.75), h = 4 + R() * 5;
    if (Math.abs(x - 52) < 26 && Math.abs(yb - 122) < 9) continue;
    ferns += `<path d="M ${f(x)} ${f(yb)} q -4 ${f(-h * 0.6)} -7 ${f(-h)} M ${f(x)} ${f(yb)} l 0 ${f(-h * 1.1)} M ${f(x)} ${f(yb)} q 4 ${f(-h * 0.6)} 7 ${f(-h)}" stroke="${R() < 0.5 ? "#4a7a3a" : "#5a8a3a"}" stroke-width="1.6" fill="none" stroke-linecap="round"/>`;
  }
  const flies = [[20, 60], [84, 30], [200, 18], [262, 64], [12, 132], [36, 196], [252, 190], [186, 70], [266, 158], [108, 202]].map(([x, y], k) => {
    const c = ["#d8ff7a", "#fff2b0", "#ff8ad0"][k % 3];
    return `<circle cx="${x}" cy="${y}" r="4.5" fill="${c}" opacity="0.35" filter="url(#bl2)"/><circle cx="${x}" cy="${y}" r="${k % 2 ? 1.4 : 2}" fill="${c}"/>`;
  }).join("");

  return `<svg xmlns="http://www.w3.org/2000/svg" width="280" height="210" viewBox="0 0 280 210">${blurs()}
  <defs>
    <radialGradient id="bhUnder" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="${Z}" stop-opacity="0.55"/><stop offset="0.55" stop-color="${Z}" stop-opacity="0.18"/><stop offset="1" stop-color="${Z}" stop-opacity="0"/></radialGradient>
    <radialGradient id="bhAura" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="${Z}" stop-opacity="0.2"/><stop offset="0.7" stop-color="${Z}" stop-opacity="0.05"/><stop offset="1" stop-color="${Z}" stop-opacity="0"/></radialGradient>
    <linearGradient id="bhRock" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3a2e2a"/><stop offset="0.5" stop-color="#2a201e"/><stop offset="1" stop-color="#160f12"/></linearGradient>
    <linearGradient id="bhSide" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#a08a6a" stop-opacity="0.3"/><stop offset="0.35" stop-color="#a08a6a" stop-opacity="0"/><stop offset="0.7" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.45"/></linearGradient>
    <radialGradient id="bhTop" cx="0.7" cy="0.4" r="0.85"><stop offset="0" stop-color="#3e5a2e"/><stop offset="0.6" stop-color="#2c4226"/><stop offset="1" stop-color="#1e2e1e"/></radialGradient>
    <linearGradient id="bhLip" x1="0" y1="0" x2="0" y2="1"><stop offset="0.5" stop-color="#5a4a3a"/><stop offset="1" stop-color="#30241e"/></linearGradient>
    <linearGradient id="bhBark" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6a5048"/><stop offset="0.45" stop-color="#4a3634"/><stop offset="1" stop-color="#2a1c22"/></linearGradient>
    <radialGradient id="bhDoor" cx="0.5" cy="0.65" r="0.65"><stop offset="0" stop-color="#fffbd0"/><stop offset="0.4" stop-color="#d8ff7a"/><stop offset="0.9" stop-color="#5a8a2a"/><stop offset="1" stop-color="#2a4a1a"/></radialGradient>
    <radialGradient id="bhHole" cx="0.5" cy="0.6" r="0.6"><stop offset="0" stop-color="#3a5a1a"/><stop offset="0.5" stop-color="#120c10"/><stop offset="1" stop-color="#05030a"/></radialGradient>
<linearGradient id="edgeH" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#fff" stop-opacity="0"/><stop offset="0.04" stop-color="#fff"/><stop offset="0.96" stop-color="#fff"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>
    <linearGradient id="edgeV" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0"/><stop offset="0.04" stop-color="#fff"/><stop offset="0.95" stop-color="#fff"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>
    <mask id="edgeMH" maskUnits="userSpaceOnUse" x="0" y="0" width="280" height="210"><rect width="280" height="210" fill="url(#edgeH)"/></mask>
    <mask id="edgeMV" maskUnits="userSpaceOnUse" x="0" y="0" width="280" height="210"><rect width="280" height="210" fill="url(#edgeV)"/></mask>
  </defs>
  <g mask="url(#edgeMH)"><g mask="url(#edgeMV)">
  <ellipse cx="140" cy="126" rx="138" ry="82" fill="url(#bhAura)"/>
  <ellipse cx="140" cy="170" rx="104" ry="38" fill="url(#bhUnder)"/>
  <path d="${B.d}" fill="#160f14" stroke="${OUT}" stroke-width="2" stroke-linejoin="round"/>
  <path d="${U.d}" fill="url(#bhRock)" stroke="${OUT}" stroke-width="2.5" stroke-linejoin="round"/>
  <path d="${U.d}" fill="url(#bhSide)"/>
  ${U.ridges}${veins}${roots}${hanging}
  <ellipse cx="${CX}" cy="${CY + 8}" rx="${RX - 1}" ry="${RY}" fill="url(#bhLip)" stroke="${OUT}" stroke-width="2.5"/>
  <ellipse cx="${CX}" cy="${CY}" rx="${RX}" ry="${RY}" fill="url(#bhTop)" stroke="${OUT}" stroke-width="2.5"/>
  <path d="M ${CX + RX - 4} ${CY - 3} Q ${CX + RX - 20} ${CY - RY + 2} ${CX + 40} ${CY - RY + 1}" fill="none" stroke="#7a9a4a" stroke-width="2" opacity="0.45" stroke-linecap="round"/>
  ${fringe}
  ${sink}${ferns}
  ${toadstool(84, 136, 4.5, "#ff8ad0")}${toadstool(92, 140, 3.2, "#d8ff7a")}${toadstool(26, 128, 3.5, "#ff8ad0")}
  ${tree}
  ${hedge}
  ${arch}
  ${toadstool(256, 140, 4, "#ff8ad0")}${toadstool(232, 136, 3, "#d8ff7a")}
  ${flies}
  ${twinkle(214, 8, 4, "#f0ffd0", 0.85)}${twinkle(44, 40, 3.5, "#fff", 0.7)}
  </g></g>
  </svg>`;
}

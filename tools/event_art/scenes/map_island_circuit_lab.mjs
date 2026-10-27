// Campaign world map, Circuit Lab island: a floating slab of steel-plated
// ground laced with glowing circuit traces. On the right a server tower with
// lit windows carries an antenna mast, beside a crackling tesla coil; the
// traces run down the rocky underside to solder pads and dangling cables.
// The game draws the zone's round node over the plateau's centre (disc at
// 140,92 r 62) and the zone's name on the calm left side.
import { blurs, rng, shade } from "./_zone_parts.mjs";
import { twinkle, mix } from "./_map_token.mjs";

export const size = [280, 210];
export const transparent = true;
export const dir = "game/ui/map_art";

const f = (n) => (+n).toFixed(1);
const Z = "#39d7ff";
const OUT = "#050816";
const CX = 140, CY = 118, RX = 118, RY = 34;
const rim = (x) => RY * Math.sqrt(Math.max(0, 1 - ((x - CX) / RX) ** 2));

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

// A glowing circuit trace: a polyline with a halo and a pad at each end.
const trace = (pts, w = 1.6, pad = true) => {
  const d = "M " + pts.map(([x, y]) => `${f(x)} ${f(y)}`).join(" L ");
  const [ex, ey] = pts[pts.length - 1];
  return `<path d="${d}" stroke="${Z}" stroke-width="${w * 3}" fill="none" opacity="0.4" filter="url(#bl2)" stroke-linejoin="round"/>
    <path d="${d}" stroke="${mix(Z, "#ffffff", 0.3)}" stroke-width="${w}" fill="none" stroke-linejoin="round" stroke-linecap="round"/>
    ${pad ? `<circle cx="${f(ex)}" cy="${f(ey)}" r="${f(w * 2.2)}" fill="${OUT}" stroke="${Z}" stroke-width="${f(w * 0.9)}"/><circle cx="${f(ex)}" cy="${f(ey)}" r="${f(w * 0.8)}" fill="#e6fbff"/>` : ""}`;
};

// A server tower in two-point view: front face, right side face, roof, lit windows.
function tower(x, y, w, h, side, R, { body = "#24305a", bodyHi = "#34457a", sideCol = "#141c3a", roof = "#3e5290" } = {}) {
  const sk = side * 0.45; // side face slant
  let win = "";
  const rows = Math.floor((h - 16) / 9), cols = Math.max(2, Math.floor((w - 8) / 7));
  for (let r = 0; r < rows; r++) for (let c = 0; c < cols; c++) {
    const v = R();
    const col = v < 0.12 ? "#ffb347" : v < 0.2 ? "#ff8ad0" : v < 0.34 ? "#16244a" : Z;
    const wx = x + 5 + c * ((w - 10) / cols), wy = y - h + 9 + r * 9;
    win += `<rect x="${f(wx)}" y="${f(wy)}" width="${f((w - 10) / cols - 2.5)}" height="4.5" rx="1" fill="${col}"${col === "#16244a" ? "" : ` opacity="${(0.75 + R() * 0.25).toFixed(2)}"`}/>`;
  }
  return `<ellipse cx="${f(x + w / 2 + side / 2)}" cy="${f(y + 2)}" rx="${f(w * 0.6 + side * 0.5)}" ry="5" fill="#000" opacity="0.45" filter="url(#bl2)"/>
    <rect x="${x}" y="${f(y - h)}" width="${w}" height="${h}" fill="${Z}" opacity="0.25" filter="url(#bl8)"/>
    <path d="M ${x + w} ${f(y)} L ${x + w + side} ${f(y - sk)} L ${x + w + side} ${f(y - h - sk)} L ${x + w} ${f(y - h)} Z" fill="${sideCol}" stroke="${OUT}" stroke-width="2.2" stroke-linejoin="round"/>
    <path d="M ${x} ${f(y - h)} L ${x + side} ${f(y - h - sk)} L ${x + w + side} ${f(y - h - sk)} L ${x + w} ${f(y - h)} Z" fill="${roof}" stroke="${OUT}" stroke-width="2.2" stroke-linejoin="round"/>
    <rect x="${x}" y="${f(y - h)}" width="${w}" height="${h}" fill="url(#clBody)" stroke="${OUT}" stroke-width="2.4"/>
    <rect x="${x + 3}" y="${f(y - h + 4)}" width="${w - 6}" height="${h - 8}" fill="#0b1228" opacity="0.7"/>
    ${win}
    ${[0.3, 0.6].map((t) => `<path d="M ${f(x + w + side * t)} ${f(y - h - sk * t + 6)} L ${f(x + w + side * t)} ${f(y - sk * t - 4)}" stroke="${Z}" stroke-width="1.2" opacity="0.55"/>`).join("")}
    <path d="M ${x + 2} ${f(y - h + 2)} L ${x + 2} ${f(y - 4)}" stroke="#7a90d0" stroke-width="1.5" opacity="0.6"/>
    <rect x="${x - 2}" y="${f(y - 6)}" width="${w + 4}" height="6" fill="${bodyHi}" stroke="${OUT}" stroke-width="2"/>`;
}

// A tesla coil: base, copper coil, top torus with crackling arcs.
function coil(x, y, h) {
  let rings = "";
  for (let k = 0; k < 6; k++) rings += `<rect x="${x - 6}" y="${f(y - 14 - k * ((h - 26) / 6))}" width="12" height="${f((h - 26) / 6 - 1.5)}" rx="1.5" fill="${k % 2 ? "#c8783a" : "#e89a4a"}" stroke="${OUT}" stroke-width="1.2"/>`;
  const ty = y - h + 4;
  const arc = (pts) => `<path d="M ${x} ${ty} ${pts}" stroke="#bff8ff" stroke-width="1.6" fill="none" stroke-linejoin="round"/>`;
  return `<ellipse cx="${x}" cy="${y}" rx="13" ry="4" fill="#000" opacity="0.5"/>
    <path d="M ${x - 11} ${y} L ${x - 8} ${y - 12} L ${x + 8} ${y - 12} L ${x + 11} ${y} Z" fill="#2c3a6a" stroke="${OUT}" stroke-width="2"/>
    ${rings}
    <rect x="${x - 2}" y="${f(ty + 4)}" width="4" height="${f(h - 30)}" fill="#3a4a78" stroke="${OUT}" stroke-width="1"/>
    <ellipse cx="${x}" cy="${ty}" rx="22" ry="14" fill="${Z}" opacity="0.4" filter="url(#bl6)"/>
    <ellipse cx="${x}" cy="${ty}" rx="12" ry="6" fill="url(#clOrb)" stroke="${OUT}" stroke-width="2"/>
    <ellipse cx="${x - 3}" cy="${ty - 2}" rx="5" ry="1.8" fill="#fff" opacity="0.8"/>
    <g filter="url(#bl1)">${arc(`l -7 -5 l 3 -4 l -8 -6`)}${arc(`l 8 -6 l -2 -4 l 9 -5`)}${arc(`l -10 2 l -4 -4 l -6 3`)}</g>
    ${arc(`l -7 -5 l 3 -4 l -8 -6`)}${arc(`l 8 -6 l -2 -4 l 9 -5`)}`;
}

export default function () {
  const R = rng(53);
  const U = underside(11, { depth: 30, spike: 6, jag: 0.25, lit: "#2c4a80" });
  const B = underside(23, { n: 11, depth: 22, spike: 0, sx: -3, sy: -4, jag: 0.25 });
  // Traces running down the underside to the tips.
  const under = U.tips.filter((_, i) => i !== 3).map(([tx, ty], k) => {
    const sx = tx + (k % 2 ? -6 : 6), sy = CY + rim(sx) + 9;
    const mid = sy + (ty - sy) * 0.45;
    return trace([[sx, sy], [sx, mid], [tx, mid + Math.abs(tx - sx)], [tx, ty - 5]], 1.3);
  }).join("");
  // Dangling cables with glowing plugs.
  const cables = [[70, 0], [196, 4]].map(([x0, ti], k) => {
    const [tx, ty] = U.tips[ti + 1];
    const sx = x0, sy = CY + rim(sx) + 8, ex = tx + (k ? 9 : -9), ey = ty - 6;
    return `<path d="M ${sx} ${f(sy)} C ${sx} ${f(sy + 20)} ${f(ex)} ${f(ey - 16)} ${f(ex)} ${f(ey)}" stroke="${OUT}" stroke-width="4.5" fill="none"/>
      <path d="M ${sx} ${f(sy)} C ${sx} ${f(sy + 20)} ${f(ex)} ${f(ey - 16)} ${f(ex)} ${f(ey)}" stroke="#3a4a7a" stroke-width="2" fill="none"/>
      <rect x="${f(ex - 3.5)}" y="${f(ey)}" width="7" height="8" rx="1.5" fill="#24305a" stroke="${OUT}" stroke-width="1.5"/>
      <circle cx="${f(ex)}" cy="${f(ey + 11)}" r="5" fill="${k ? "#ff8ad0" : Z}" opacity="0.6" filter="url(#bl2)"/><circle cx="${f(ex)}" cy="${f(ey + 10.5)}" r="1.8" fill="#fff"/>`;
  }).join("");
  // Panel seams and traces on the plateau top.
  let seams = "";
  for (const x of [46, 80, 200, 234]) {
    const h = rim(x);
    seams += `<path d="M ${x} ${f(CY - h + 2)} Q ${f(x + (x - CX) * 0.06)} ${CY} ${x} ${f(CY + h - 2)}" stroke="#0a1230" stroke-width="1.5" fill="none" opacity="0.8"/>`;
  }
  const topTraces = [
    [[26, 116], [40, 116], [48, 124], [70, 124]],
    [[34, 128], [54, 134], [80, 134]],
    [[40, 104], [58, 104], [66, 98], [84, 98]],
    [[248, 124], [232, 124], [224, 132], [204, 132]],
    [[254, 112], [240, 112], [232, 104], [214, 104]],
  ].map((p) => trace(p, 1.3)).join("");
  // Left (label) side: a couple of tiny low chips and an LED post.
  const chip = (x, y, w) => `<path d="M ${x - w} ${y} L ${x} ${y - w * 0.5} L ${x + w} ${y} L ${x} ${y + w * 0.5} Z" fill="#141a36" stroke="${OUT}" stroke-width="1.5"/>
    <path d="M ${x - w} ${y} L ${x} ${y + w * 0.5} L ${x + w} ${y} L ${x + w} ${y + 3} L ${x} ${y + w * 0.5 + 3} L ${x - w} ${y + 3} Z" fill="#0a0f24" stroke="${OUT}" stroke-width="1.2"/>
    <path d="M ${x - w * 0.5} ${y} L ${x} ${y - w * 0.25} L ${x + w * 0.5} ${y} L ${x} ${y + w * 0.25} Z" fill="${Z}" opacity="0.8"/>
    ${[-0.7, -0.35, 0.35, 0.7].map((t) => `<circle cx="${f(x + t * w)}" cy="${f(y + (1 - Math.abs(t)) * w * 0.5 + 2.5)}" r="0.9" fill="#bff8ff"/>`).join("")}`;
  const led = (x, y, c) => `<rect x="${x - 1.5}" y="${y - 12}" width="3" height="12" fill="#3a4a78" stroke="${OUT}" stroke-width="1"/>
    <circle cx="${x}" cy="${y - 14}" r="6" fill="${c}" opacity="0.5" filter="url(#bl2)"/><circle cx="${x}" cy="${y - 14}" r="2.6" fill="${c}" stroke="${OUT}" stroke-width="1"/><circle cx="${x - 0.8}" cy="${y - 14.8}" r="0.9" fill="#fff"/>`;
  // Antenna mast on the tower roof with signal arcs.
  const ax = 250, ay = 40, at = 18;
  const mast = `<path d="M ${ax - 7} ${ay} L ${ax} ${at} L ${ax + 7} ${ay} M ${ax - 5} ${ay - 8} L ${ax + 5} ${ay - 8} M ${ax - 3} ${ay - 16} L ${ax + 3} ${ay - 16} M ${ax - 5} ${ay - 8} L ${ax + 3} ${ay - 16} M ${ax + 5} ${ay - 8} L ${ax - 3} ${ay - 16}" stroke="${OUT}" stroke-width="3.5" fill="none" stroke-linejoin="round"/>
    <path d="M ${ax - 7} ${ay} L ${ax} ${at} L ${ax + 7} ${ay} M ${ax - 5} ${ay - 8} L ${ax + 5} ${ay - 8} M ${ax - 3} ${ay - 16} L ${ax + 3} ${ay - 16} M ${ax - 5} ${ay - 8} L ${ax + 3} ${ay - 16} M ${ax + 5} ${ay - 8} L ${ax - 3} ${ay - 16}" stroke="#8a9ad0" stroke-width="1.5" fill="none" stroke-linejoin="round"/>
    <circle cx="${ax}" cy="${at}" r="7" fill="#ff5a7a" opacity="0.6" filter="url(#bl3)"/><circle cx="${ax}" cy="${at}" r="3" fill="#ff8aa0" stroke="${OUT}" stroke-width="1.2"/><circle cx="${ax - 1}" cy="${at - 1}" r="1" fill="#fff"/>
    ${[9, 15].map((r, k) => `<path d="M ${ax - r} ${at - r * 0.6} A ${r} ${r} 0 0 0 ${ax - r} ${at + r * 0.6}" stroke="${Z}" stroke-width="1.8" fill="none" opacity="${0.8 - k * 0.3}" stroke-linecap="round" transform="rotate(25 ${ax} ${at})"/>
      <path d="M ${ax + r} ${at - r * 0.6} A ${r} ${r} 0 0 1 ${ax + r} ${at + r * 0.6}" stroke="${Z}" stroke-width="1.8" fill="none" opacity="${0.8 - k * 0.3}" stroke-linecap="round" transform="rotate(-25 ${ax} ${at})"/>`).join("")}`;
  // A satellite dish on the tower's shoulder.
  const dish = `<path d="M 266 58 L 272 64" stroke="${OUT}" stroke-width="3"/><path d="M 262 56 Q 266 46 276 48 Q 274 60 266 64 Z" fill="#9aa8d8" stroke="${OUT}" stroke-width="1.8"/><path d="M 266 55 L 274 50" stroke="#fff" stroke-width="1" opacity="0.6"/><circle cx="274" cy="50" r="1.6" fill="${Z}"/>`;
  const bits = [[20, 40], [60, 20], [270, 90], [12, 150], [34, 186], [248, 180], [104, 16], [176, 10], [268, 150]].map(([x, y], k) =>
    `<rect x="${x - 1.5}" y="${y - 1.5}" width="3" height="3" fill="${k % 3 ? Z : "#bff8ff"}" opacity="${0.5 + (k % 3) * 0.2}"/><rect x="${x - 4}" y="${y - 4}" width="8" height="8" fill="${Z}" opacity="0.2" filter="url(#bl2)"/>`).join("");

  return `<svg xmlns="http://www.w3.org/2000/svg" width="280" height="210" viewBox="0 0 280 210">${blurs()}
  <defs>
    <radialGradient id="clUnder" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="${Z}" stop-opacity="0.65"/><stop offset="0.55" stop-color="${Z}" stop-opacity="0.2"/><stop offset="1" stop-color="${Z}" stop-opacity="0"/></radialGradient>
    <radialGradient id="clAura" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="${Z}" stop-opacity="0.22"/><stop offset="0.7" stop-color="${Z}" stop-opacity="0.05"/><stop offset="1" stop-color="${Z}" stop-opacity="0"/></radialGradient>
    <linearGradient id="clRock" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#1e2a52"/><stop offset="0.5" stop-color="#141c3c"/><stop offset="1" stop-color="#0a0f26"/></linearGradient>
    <linearGradient id="clSide" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#4a6ab0" stop-opacity="0.4"/><stop offset="0.35" stop-color="#4a6ab0" stop-opacity="0"/><stop offset="0.7" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.45"/></linearGradient>
    <radialGradient id="clTop" cx="0.7" cy="0.4" r="0.8"><stop offset="0" stop-color="#34457a"/><stop offset="0.6" stop-color="#243262"/><stop offset="1" stop-color="#1a2450"/></radialGradient>
    <linearGradient id="clLip" x1="0" y1="0" x2="0" y2="1"><stop offset="0.6" stop-color="#4a5a90"/><stop offset="1" stop-color="#222c58"/></linearGradient>
    <linearGradient id="clBody" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#3a4c88"/><stop offset="0.5" stop-color="#2a3868"/><stop offset="1" stop-color="#1e2a54"/></linearGradient>
    <radialGradient id="clOrb" cx="0.4" cy="0.35" r="0.7"><stop offset="0" stop-color="#ffffff"/><stop offset="0.45" stop-color="#bff8ff"/><stop offset="1" stop-color="${Z}"/></radialGradient>
<linearGradient id="edgeH" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#fff" stop-opacity="0"/><stop offset="0.04" stop-color="#fff"/><stop offset="0.96" stop-color="#fff"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>
    <linearGradient id="edgeV" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0"/><stop offset="0.04" stop-color="#fff"/><stop offset="0.95" stop-color="#fff"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>
    <mask id="edgeMH" maskUnits="userSpaceOnUse" x="0" y="0" width="280" height="210"><rect width="280" height="210" fill="url(#edgeH)"/></mask>
    <mask id="edgeMV" maskUnits="userSpaceOnUse" x="0" y="0" width="280" height="210"><rect width="280" height="210" fill="url(#edgeV)"/></mask>
  </defs>
  <g mask="url(#edgeMH)"><g mask="url(#edgeMV)">
  <ellipse cx="140" cy="126" rx="138" ry="82" fill="url(#clAura)"/>
  <ellipse cx="140" cy="170" rx="104" ry="38" fill="url(#clUnder)"/>
  <path d="${B.d}" fill="#0a0f24" stroke="${OUT}" stroke-width="2" stroke-linejoin="round"/>
  <path d="${U.d}" fill="url(#clRock)" stroke="${OUT}" stroke-width="2.5" stroke-linejoin="round"/>
  <path d="${U.d}" fill="url(#clSide)"/>
  ${U.ridges}${under}${cables}
  <ellipse cx="${CX}" cy="${CY + 8}" rx="${RX - 1}" ry="${RY}" fill="url(#clLip)" stroke="${OUT}" stroke-width="2.5"/>
  ${Array.from({ length: 15 }, (_, k) => { const x = CX - RX + 14 + k * 16; return `<path d="M ${x} ${f(CY + rim(x) + 1)} L ${x} ${f(CY + rim(x) + 7)}" stroke="#141c3c" stroke-width="1.5"/>`; }).join("")}
  <ellipse cx="${CX}" cy="${CY}" rx="${RX}" ry="${RY}" fill="url(#clTop)" stroke="${OUT}" stroke-width="2.5"/>
  <path d="M ${CX + RX - 4} ${CY - 3} Q ${CX + RX - 20} ${CY - RY + 2} ${CX + 40} ${CY - RY + 1}" fill="none" stroke="#8aa8ff" stroke-width="2" opacity="0.45" stroke-linecap="round"/>
  <path d="M ${CX - RX + 4} ${CY + 3} Q ${CX - RX + 30} ${CY + RY - 4} ${CX - 30} ${CY + RY - 1}" fill="none" stroke="${Z}" stroke-width="1.6" opacity="0.6" stroke-linecap="round"/>
  <clipPath id="clTopClip"><ellipse cx="${CX}" cy="${CY}" rx="${RX - 2}" ry="${RY - 2}"/></clipPath>
  <g clip-path="url(#clTopClip)" opacity="0.5">${Array.from({ length: 12 }, (_, k) => `<path d="M ${-40 + k * 34} 80 L ${-10 + k * 34 + (k * 34 - 170) * 0.5} 156" stroke="#3a5aa0" stroke-width="1"/>`).join("")}${[100, 110, 122, 136].map((y) => `<path d="M 0 ${y} L 280 ${y}" stroke="#3a5aa0" stroke-width="1"/>`).join("")}</g>
  ${seams}${topTraces}
  <ellipse cx="230" cy="114" rx="44" ry="14" fill="${Z}" opacity="0.18" filter="url(#bl6)"/>
  ${chip(44, 126, 11)}${chip(76, 140, 7)}${led(24, 120, "#5cff9a")}${led(60, 112, Z)}
  ${tower(234, 124, 30, 80, 10, R)}
  ${mast}${dish}
  ${coil(214, 145, 52)}
  ${[0, 1, 2].map((k) => chip(254, 140 - k * 7, 10 - k * 1.5)).join("")}
  <ellipse cx="254" cy="118" rx="10" ry="6" fill="${Z}" opacity="0.45" filter="url(#bl3)"/>
  <path d="M 222 142 Q 232 148 242 136 Q 248 130 256 134" stroke="${OUT}" stroke-width="3.5" fill="none"/><path d="M 222 142 Q 232 148 242 136 Q 248 130 256 134" stroke="#e89a4a" stroke-width="1.5" fill="none"/>
  ${bits}
  ${twinkle(190, 26, 4, "#e6fbff", 0.85)}${twinkle(30, 70, 3.5, "#bff8ff", 0.7)}${twinkle(266, 24, 3, "#fff", 0.7)}
  </g></g>
  </svg>`;
}

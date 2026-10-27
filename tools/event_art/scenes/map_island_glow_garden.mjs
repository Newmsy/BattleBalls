// Campaign world map, Glow Garden island: a floating chunk of mossy meadow
// with giant bioluminescent mushrooms, ferns and bell flowers on the left,
// fireflies drifting about and green glowing roots dripping from its rocky
// underside. The game draws the zone's round node over the plateau's centre
// (disc at 140,92 r 62) and the zone's name on the calm right side.
import { blurs, rng, shade } from "./_zone_parts.mjs";
import { twinkle, mix } from "./_map_token.mjs";

export const size = [280, 210];
export const transparent = true;
export const dir = "game/ui/map_art";

const f = (n) => (+n).toFixed(1);
const Z = "#45f5a6";
const OUT = "#06101a";
const CX = 140, CY = 118, RX = 118, RY = 34;
const rim = (x) => RY * Math.sqrt(Math.max(0, 1 - ((x - CX) / RX) ** 2));

// Rocky underside: a tapering mass of rounded lobes ending in stalactite
// tips, deepest in the middle (the centre spike reaches y ~200).
function underside(seed, { n = 13, depth = 40, spike = 12, jag = 0.5, sx = 0, sy = 0, pw = 0.8 } = {}) {
  const R = rng(seed);
  const tips = [];
  const pt = [];
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
  // Facet ridges from the rim down to each tip.
  const ridges = tips.map(([x, y]) => {
    const by = CY + rim(x) + 8;
    return `<path d="M ${f(x - 8)} ${f(by)} Q ${f(x - 5)} ${f((by + y) / 2)} ${f(x - 0.5)} ${f(y - 3)}" stroke="#2c5a62" stroke-width="2" fill="none" opacity="0.6" stroke-linecap="round"/>
      <path d="M ${f(x + 9)} ${f(by + 2)} Q ${f(x + 5)} ${f((by + y) / 2)} ${f(x + 1)} ${f(y - 6)}" stroke="#03080e" stroke-width="2.5" fill="none" opacity="0.55" stroke-linecap="round"/>`;
  }).join("");
  return { d, tips, ridges };
}

// A glowing mushroom: stem from (x, y) up h px, cap radius s, cap shifted by lean px.
function mushroom(x, y, h, s, cap, glow, lean = 0) {
  const tx = x + lean, cy = y - h;
  return `<ellipse cx="${f(tx)}" cy="${f(cy - s * 0.3)}" rx="${f(s * 1.7)}" ry="${f(s * 1.2)}" fill="${glow}" opacity="0.3" filter="url(#bl8)"/>
    <path d="M ${f(x - s * 0.24)} ${y} Q ${f(x - s * 0.3 + lean * 0.4)} ${f(y - h * 0.55)} ${f(tx - s * 0.16)} ${f(cy)} L ${f(tx + s * 0.16)} ${f(cy)} Q ${f(x + s * 0.3 + lean * 0.4)} ${f(y - h * 0.55)} ${f(x + s * 0.24)} ${y} Z" fill="url(#ggStem)" stroke="${OUT}" stroke-width="2"/>
    <ellipse cx="${f(tx)}" cy="${f(cy + s * 0.02)}" rx="${f(s * 0.86)}" ry="${f(s * 0.2)}" fill="${glow}" opacity="0.8"/>
    <path d="M ${f(tx - s)} ${f(cy)} Q ${f(tx - s * 0.92)} ${f(cy - s * 0.84)} ${f(tx)} ${f(cy - s * 0.88)} Q ${f(tx + s * 0.92)} ${f(cy - s * 0.84)} ${f(tx + s)} ${f(cy)} Q ${f(tx)} ${f(cy - s * 0.2)} ${f(tx - s)} ${f(cy)} Z" fill="${cap}" stroke="${OUT}" stroke-width="2.4"/>
    <path d="M ${f(tx - s * 0.96)} ${f(cy - s * 0.04)} Q ${f(tx)} ${f(cy - s * 0.24)} ${f(tx + s * 0.96)} ${f(cy - s * 0.04)}" fill="none" stroke="${shade(cap, -0.45)}" stroke-width="${f(s * 0.1)}" opacity="0.8"/>
    <path d="M ${f(tx - s * 0.72)} ${f(cy - s * 0.3)} Q ${f(tx - s * 0.5)} ${f(cy - s * 0.72)} ${f(tx + s * 0.05)} ${f(cy - s * 0.76)}" fill="none" stroke="#fff" stroke-width="${f(s * 0.09)}" opacity="0.45" stroke-linecap="round"/>
    ${[[-0.5, -0.4, 0.14], [0.22, -0.58, 0.12], [0.6, -0.28, 0.1], [-0.12, -0.28, 0.08], [-0.2, -0.68, 0.07]].map(([a, b, r]) =>
      `<circle cx="${f(tx + a * s)}" cy="${f(cy + b * s)}" r="${f(r * s * 1.8)}" fill="${glow}" opacity="0.5" filter="url(#bl2)"/><circle cx="${f(tx + a * s)}" cy="${f(cy + b * s)}" r="${f(r * s)}" fill="${mix(glow, "#ffffff", 0.5)}"/>`).join("")}`;
}

function fern(x, y, h, dir, col = "#2f8a5a") {
  let out = `<path d="M ${x} ${y} Q ${f(x + dir * h * 0.15)} ${f(y - h * 0.6)} ${f(x + dir * h * 0.5)} ${f(y - h)}" stroke="${OUT}" stroke-width="4" fill="none" stroke-linecap="round"/>
    <path d="M ${x} ${y} Q ${f(x + dir * h * 0.15)} ${f(y - h * 0.6)} ${f(x + dir * h * 0.5)} ${f(y - h)}" stroke="${col}" stroke-width="2" fill="none" stroke-linecap="round"/>`;
  for (let k = 1; k < 7; k++) {
    const t = k / 7, px = x + dir * h * (0.15 * t + 0.35 * t * t), py = y - h * t, L = h * 0.3 * (1 - t * 0.7);
    for (const s of [-1, 1]) out += `<path d="M ${f(px)} ${f(py)} q ${f(s * L * 0.6)} ${f(-L * 0.1)} ${f(s * L)} ${f(-L * 0.5)}" stroke="${shade(col, 0.15 * s)}" stroke-width="2.2" fill="none" stroke-linecap="round"/>`;
  }
  return out;
}

function bell(x, y, h, col, lean = 1) {
  const hx = x + lean * 8, hy = y - h;
  return `<path d="M ${x} ${y} Q ${f(x + lean * 2)} ${f(y - h * 0.7)} ${f(hx)} ${f(hy)}" fill="none" stroke="${OUT}" stroke-width="3.5"/>
    <path d="M ${x} ${y} Q ${f(x + lean * 2)} ${f(y - h * 0.7)} ${f(hx)} ${f(hy)}" fill="none" stroke="#2f8a5a" stroke-width="1.8"/>
    <circle cx="${f(hx + lean * 3)}" cy="${f(hy + 9)}" r="8" fill="${col}" opacity="0.55" filter="url(#bl4)"/>
    <path d="M ${f(hx + lean * 3)} ${f(hy)} q -7 3 -7 12 q 3.5 -2 7 0 q 3.5 -2 7 0 q 0 -9 -7 -12 Z" fill="${col}" stroke="${OUT}" stroke-width="1.6"/>
    <circle cx="${f(hx + lean * 3)}" cy="${f(hy + 13)}" r="1.8" fill="#fff"/>`;
}

function grass(R, x0, x1, n, h) {
  let out = "";
  for (let k = 0; k < n; k++) {
    const x = x0 + R() * (x1 - x0), yb = CY + rim(x) * (0.2 + R() * 0.75), hh = h * (0.5 + R() * 0.7);
    const c = R() < 0.5 ? "#3fae74" : "#5ad08a";
    out += `<path d="M ${f(x)} ${f(yb)} q -2 ${f(-hh * 0.6)} -5 ${f(-hh)} M ${f(x)} ${f(yb)} q 1 ${f(-hh * 0.7)} 1 ${f(-hh * 1.2)} M ${f(x)} ${f(yb)} q 3 ${f(-hh * 0.5)} 6 ${f(-hh * 0.9)}" stroke="${c}" stroke-width="1.7" fill="none" stroke-linecap="round"/>`;
  }
  return out;
}

export default function () {
  const R = rng(41);
  const U = underside(7, { depth: 30, spike: 6 });
  const B = underside(19, { n: 11, depth: 22, spike: 0, sx: 3, sy: -4 });
  // Glowing roots dangling from the underside, ending in drops.
  const roots = [[44, 0], [88, 1], [170, 3], [214, 5]].map(([x0, ti], k) => {
    const [tx, ty] = U.tips[ti] ?? U.tips[0];
    const sx = x0, sy = CY + rim(sx) + 6, ex = tx + (k % 2 ? 4 : -4), ey = ty - 4;
    const path = `M ${f(sx)} ${f(sy)} C ${f(sx + 10)} ${f(sy + 12)} ${f(ex - 10)} ${f(ey - 14)} ${f(ex)} ${f(ey)}`;
    return `<path d="${path}" stroke="${Z}" stroke-width="5" fill="none" opacity="0.55" filter="url(#bl3)"/>
      <path d="${path}" stroke="${mix(Z, "#ffffff", 0.35)}" stroke-width="1.8" fill="none" stroke-linecap="round"/>`;
  }).join("");
  const drips = U.tips.filter((_, i) => i % 2 === 0 || i === 3).map(([x, y], k) => {
    const L = 5 + (k % 3) * 4;
    return `<path d="M ${f(x)} ${f(y - 2)} L ${f(x)} ${f(y + L)}" stroke="${Z}" stroke-width="1.6" opacity="0.8"/>
      <circle cx="${f(x)}" cy="${f(y + L + 2.5)}" r="5" fill="${Z}" opacity="0.5" filter="url(#bl2)"/>
      <circle cx="${f(x)}" cy="${f(y + L + 2.5)}" r="2.4" fill="#d8fff0"/>`;
  }).join("");
  // Glow-moss patches on the cliff face.
  const moss = [[34, 134], [62, 146], [205, 148], [240, 132], [118, 158], [160, 160]].map(([x, y]) =>
    `<ellipse cx="${x}" cy="${y}" rx="7" ry="3" fill="${Z}" opacity="0.6" filter="url(#bl2)"/><ellipse cx="${x}" cy="${y}" rx="3.5" ry="1.5" fill="#c8ffe6"/>`).join("");
  // Grass fringe hanging over the front lip.
  let fringe = "";
  for (let k = 0; k < 30; k++) {
    const x = CX - RX + 14 + (k / 29) * (RX * 2 - 28) + (R() - 0.5) * 4, y = CY + rim(x) + 1 + R() * 2, r = 2.5 + R() * 3.5;
    fringe += `<ellipse cx="${f(x)}" cy="${f(y)}" rx="${f(r * 1.3)}" ry="${f(r * 0.75)}" fill="${["#2a7a52", "#36a06a", "#22664a"][k % 3]}" stroke="${OUT}" stroke-width="1.1"/>`;
    if (k % 4 === 1) { const L = 8 + R() * 14; fringe += `<path d="M ${f(x)} ${f(y + 2)} q ${f(3 - R() * 6)} ${f(L * 0.6)} ${f(1 - R() * 2)} ${f(L)}" stroke="#2a7a52" stroke-width="2" fill="none" stroke-linecap="round"/><circle cx="${f(x)}" cy="${f(y + L + 2)}" r="1.6" fill="${Z}"/>`; }
  }
  const flies = [[22, 30], [110, 14], [102, 44], [14, 84], [56, 46], [34, 12], [250, 96], [222, 84], [262, 120], [14, 120], [44, 188], [236, 186], [96, 194]]
    .map(([x, y], k) => {
      const c = ["#d8ff7a", Z, "#fff2b0"][k % 3];
      return `<circle cx="${x}" cy="${y}" r="5" fill="${c}" opacity="0.35" filter="url(#bl2)"/><circle cx="${x}" cy="${y}" r="${k % 2 ? 1.6 : 2.2}" fill="${c}"/>`;
    }).join("");
  // Right (label) side: just a few low glowing toadstools and tufts.
  const tiny = [[214, 118, 5, "#ff8ad0"], [228, 126, 4, Z], [240, 116, 3.5, "#7b77ff"], [196, 136, 3.5, "#ffd36b"]].map(([x, y, s, c]) =>
    `<circle cx="${x}" cy="${y - s}" r="${s * 2.4}" fill="${c}" opacity="0.35" filter="url(#bl3)"/>
    <rect x="${f(x - s * 0.25)}" y="${f(y - s)}" width="${f(s * 0.5)}" height="${s}" fill="#e8e0c8" stroke="${OUT}" stroke-width="0.8"/>
    <path d="M ${f(x - s)} ${f(y - s * 0.9)} Q ${x} ${f(y - s * 2.3)} ${f(x + s)} ${f(y - s * 0.9)} Z" fill="${c}" stroke="${OUT}" stroke-width="1.2"/>`).join("");

  return `<svg xmlns="http://www.w3.org/2000/svg" width="280" height="210" viewBox="0 0 280 210">${blurs()}
  <defs>
    <radialGradient id="ggUnder" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="${Z}" stop-opacity="0.7"/><stop offset="0.55" stop-color="${Z}" stop-opacity="0.22"/><stop offset="1" stop-color="${Z}" stop-opacity="0"/></radialGradient>
    <radialGradient id="ggAura" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="${Z}" stop-opacity="0.24"/><stop offset="0.7" stop-color="${Z}" stop-opacity="0.06"/><stop offset="1" stop-color="${Z}" stop-opacity="0"/></radialGradient>
    <linearGradient id="ggRock" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#1c3c4a"/><stop offset="0.5" stop-color="#132836"/><stop offset="1" stop-color="#0a1422"/></linearGradient>
    <linearGradient id="ggSideL" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#3a7a72" stop-opacity="0.5"/><stop offset="0.4" stop-color="#3a7a72" stop-opacity="0"/><stop offset="0.75" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.45"/></linearGradient>
    <radialGradient id="ggTop" cx="0.3" cy="0.4" r="0.8"><stop offset="0" stop-color="#2f8a62"/><stop offset="0.6" stop-color="#1f5e4c"/><stop offset="1" stop-color="#153e3a"/></radialGradient>
    <linearGradient id="ggLip" x1="0" y1="0" x2="0" y2="1"><stop offset="0.6" stop-color="#3a6a5a"/><stop offset="1" stop-color="#1c3a40"/></linearGradient>
    <linearGradient id="ggStem" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#bfb8a6"/><stop offset="0.4" stop-color="#f4eedc"/><stop offset="1" stop-color="#a49c8a"/></linearGradient>
<linearGradient id="edgeH" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#fff" stop-opacity="0"/><stop offset="0.04" stop-color="#fff"/><stop offset="0.96" stop-color="#fff"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>
    <linearGradient id="edgeV" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0"/><stop offset="0.04" stop-color="#fff"/><stop offset="0.95" stop-color="#fff"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>
    <mask id="edgeMH" maskUnits="userSpaceOnUse" x="0" y="0" width="280" height="210"><rect width="280" height="210" fill="url(#edgeH)"/></mask>
    <mask id="edgeMV" maskUnits="userSpaceOnUse" x="0" y="0" width="280" height="210"><rect width="280" height="210" fill="url(#edgeV)"/></mask>
  </defs>
  <g mask="url(#edgeMH)"><g mask="url(#edgeMV)">
  <ellipse cx="140" cy="128" rx="138" ry="80" fill="url(#ggAura)"/>
  <ellipse cx="140" cy="172" rx="104" ry="36" fill="url(#ggUnder)"/>
  <path d="${B.d}" fill="#0a1626" stroke="${OUT}" stroke-width="2" stroke-linejoin="round"/>
  <path d="${U.d}" fill="url(#ggRock)" stroke="${OUT}" stroke-width="2.5" stroke-linejoin="round"/>
  <path d="${U.d}" fill="url(#ggSideL)"/>
  ${U.ridges}${roots}${moss}${drips}
  <ellipse cx="${CX}" cy="${CY + 8}" rx="${RX - 1}" ry="${RY}" fill="url(#ggLip)" stroke="${OUT}" stroke-width="2.5"/>
  <ellipse cx="${CX}" cy="${CY}" rx="${RX}" ry="${RY}" fill="url(#ggTop)" stroke="${OUT}" stroke-width="2.5"/>
  <path d="M ${CX - RX + 4} ${CY - 3} Q ${CX - RX + 20} ${CY - RY + 2} ${CX - 40} ${CY - RY + 1}" fill="none" stroke="#6ae0a0" stroke-width="2" opacity="0.5" stroke-linecap="round"/>
  <ellipse cx="60" cy="112" rx="44" ry="14" fill="${Z}" opacity="0.18" filter="url(#bl6)"/>
  ${fringe}
  ${grass(R, 24, 236, 34, 7)}
  ${tiny}
  <path d="M 64 104 Q 84 110 86 124" stroke="#0e2a2a" stroke-width="3" fill="none"/>
  ${mushroom(78, 106, 64, 23, "#5a56d8", "#b8b4ff", -8)}
  ${fern(20, 126, 30, 1, "#226a4a")}${fern(100, 112, 24, 1, "#226a4a")}
  ${mushroom(44, 126, 42, 32, "#2fcf8c", "#a6ffd6", -2)}
  ${mushroom(82, 138, 13, 12, "#ff8ad0", "#ffd0ec", 1)}
  ${mushroom(20, 138, 9, 8, "#7b77ff", "#c8c4ff", -1)}
  ${fern(66, 136, 26, 1)}${fern(28, 140, 18, -1, "#3fae74")}
  ${bell(54, 142, 22, "#ffd36b", 1)}${bell(100, 146, 18, "#7dffb0", 1)}
  ${mushroom(40, 146, 6, 6, "#3fa9f5", "#bfe8ff", 0)}
  ${flies}
  ${twinkle(52, 8, 5, "#eafff4", 0.9)}${twinkle(118, 26, 3.5, "#fff", 0.7)}${twinkle(256, 74, 3, "#d8ffe8", 0.7)}
  </g></g>
  </svg>`;
}

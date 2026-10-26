// Campaign world map, Frostbite Caves island: a floating snow-capped chunk
// of blue rock. On the left an ice cave mouth glows from within, ringed by
// tall ice crystal shards; icicles and glowing crystals hang from the
// underside. A small frozen lake rim and snow lumps sit on the calm right
// side. The game draws the zone's round node over the plateau's centre
// (disc at 140,92 r 62) and the zone's name on the right.
import { blurs, rng, shade } from "./_zone_parts.mjs";
import { twinkle, mix } from "./_map_token.mjs";

export const size = [280, 210];
export const transparent = true;
export const dir = "game/ui/map_art";

const f = (n) => (+n).toFixed(1);
const Z = "#a8e6ff";
const OUT = "#08102a";
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

// An ice crystal shard: a tall faceted prism, lit face left, shadow face right.
function shard(x, y, h, w, tilt = 0, { col = "#c8ecff", glow = true } = {}) {
  return `<g transform="rotate(${tilt} ${x} ${y})">
    ${glow ? `<path d="M ${x - w} ${y} L ${x} ${y - h} L ${x + w} ${y} Z" fill="${Z}" opacity="0.35" filter="url(#bl6)"/>` : ""}
    <path d="M ${f(x - w)} ${y} L ${f(x - w * 0.85)} ${f(y - h * 0.78)} L ${x} ${f(y - h)} L ${f(x + w * 0.85)} ${f(y - h * 0.78)} L ${f(x + w)} ${y} Z" fill="${col}" stroke="${OUT}" stroke-width="2.2" stroke-linejoin="round"/>
    <path d="M ${x} ${f(y - h)} L ${f(x + w * 0.85)} ${f(y - h * 0.78)} L ${f(x + w)} ${y} L ${f(x + w * 0.15)} ${y} Z" fill="#2a4a8a" opacity="0.4"/>
    <path d="M ${x} ${f(y - h)} L ${f(x + w * 0.15)} ${y}" stroke="#fff" stroke-width="1" opacity="0.5"/>
    <path d="M ${f(x - w * 0.55)} ${f(y - h * 0.12)} L ${f(x - w * 0.5)} ${f(y - h * 0.72)}" stroke="#fff" stroke-width="${f(Math.max(1.2, w * 0.18))}" opacity="0.75" stroke-linecap="round"/></g>`;
}

// A hanging icicle (point down).
const icicle = (x, y, h, w) => `<path d="M ${f(x - w)} ${f(y)} Q ${f(x - w * 0.3)} ${f(y + h * 0.6)} ${f(x)} ${f(y + h)} Q ${f(x + w * 0.3)} ${f(y + h * 0.6)} ${f(x + w)} ${f(y)} Z" fill="#cdeeff" stroke="${OUT}" stroke-width="1.4" stroke-linejoin="round"/>
  <path d="M ${f(x - w * 0.4)} ${f(y + 1)} L ${f(x - w * 0.1)} ${f(y + h * 0.65)}" stroke="#fff" stroke-width="1.1" opacity="0.8" stroke-linecap="round"/>`;

export default function () {
  const R = rng(67);
  const U = underside(5, { depth: 28, spike: 2, jag: 0.2, lit: "#4a6ab0" });
  const B = underside(29, { n: 11, depth: 22, spike: 0, sx: 3, sy: -4, jag: 0.2 });
  // Icicles from the underside tips, crystals glowing in the rock.
  const ics = U.tips.map(([x, y], k) => icicle(x, y - 3, Math.min(8 + (k % 3) * 5, 202 - y), 3 + (k % 2))).join("");
  const glints = [[42, 148, 6, -20], [88, 166, 7, 10], [170, 172, 7, -8], [214, 158, 6, 16], [124, 182, 5, 0]].map(([x, y, s, t]) =>
    `<ellipse cx="${x}" cy="${y}" rx="${s * 2}" ry="${s * 1.6}" fill="${Z}" opacity="0.45" filter="url(#bl4)"/>
    <g transform="rotate(${t} ${x} ${y})"><path d="M ${x} ${y - s * 1.4} L ${x + s * 0.6} ${y} L ${x} ${y + s * 0.8} L ${x - s * 0.6} ${y} Z" fill="#e6f8ff" stroke="${OUT}" stroke-width="1.2"/>
    <path d="M ${x + s * 0.9} ${y - s * 0.6} L ${x + s * 1.3} ${y + s * 0.2} L ${x + s * 0.8} ${y + s * 0.6} Z" fill="#b8d8ff" stroke="${OUT}" stroke-width="1"/></g>`).join("");
  // Snow drift overhanging the front lip, with little drips of icicles.
  let snowLip = `<path d="M ${CX - RX} ${CY}`;
  for (let k = 0; k <= 24; k++) {
    const x = CX - RX + (k / 24) * RX * 2, y = CY + rim(x) + 3 + (k % 2 ? 3 + R() * 3 : 0);
    snowLip += ` L ${f(x)} ${f(y)}`;
  }
  snowLip += ` L ${CX + RX} ${CY} Z`;
  const lipIcicles = [22, 31, 58, 66, 98, 124, 131, 160, 190, 198, 226, 248].map((x0, k) => {
    const x = x0 + (R() - 0.5) * 4;
    return icicle(x, CY + rim(x) + 4, 4 + ((k * 7) % 5) * 2.4, 1.6 + (k % 3) * 0.6);
  }).join("");
  // Cave mouth: a snowy rock mound with a glowing arched opening.
  const mx = 50, my = 126;
  const cave = `
    <ellipse cx="${mx}" cy="${my - 26}" rx="44" ry="40" fill="${Z}" opacity="0.25" filter="url(#bl12)"/>
    <path d="M ${mx - 40} ${my} Q ${mx - 44} ${my - 40} ${mx - 18} ${my - 58} Q ${mx + 4} ${my - 72} ${mx + 24} ${my - 54} Q ${mx + 42} ${my - 38} ${mx + 40} ${my} Z" fill="url(#fcRock)" stroke="${OUT}" stroke-width="2.5" stroke-linejoin="round"/>
    <path d="M ${mx + 10} ${my - 64} Q ${mx + 30} ${my - 48} ${mx + 34} ${my - 20}" stroke="#0e1a40" stroke-width="5" fill="none" opacity="0.6" stroke-linecap="round"/>
    <path d="M ${mx - 36} ${my - 30} Q ${mx - 30} ${my - 52} ${mx - 10} ${my - 62}" stroke="#6a8ad0" stroke-width="2.5" fill="none" opacity="0.6" stroke-linecap="round"/>
    <path d="M ${mx - 18} ${my} L ${mx - 18} ${my - 22} Q ${mx} ${my - 46} ${mx + 18} ${my - 22} L ${mx + 18} ${my} Z" fill="url(#fcMouth)" stroke="${OUT}" stroke-width="2.4"/>
    <ellipse cx="${mx}" cy="${my - 16}" rx="14" ry="16" fill="#ffffff" opacity="0.55" filter="url(#bl6)"/>
    <ellipse cx="${mx}" cy="${my + 2}" rx="26" ry="6" fill="#d8f6ff" opacity="0.75" filter="url(#bl4)"/>
    <path d="M ${mx - 8} ${my - 4} L ${mx} ${my - 24} L ${mx + 8} ${my - 4}" fill="none" stroke="#fff" stroke-width="1.6" opacity="0.7"/>
    ${[-12, -5, 3, 10].map((dx, k) => icicle(mx + dx, my - 30 + Math.abs(dx) * 0.9 - (k === 1 || k === 2 ? 4 : 0), 6 + (k % 2) * 4, 2.2)).join("")}
    <path d="M ${mx - 42} ${my - 34} Q ${mx - 34} ${my - 56} ${mx - 18} ${my - 60} Q ${mx + 2} ${my - 76} ${mx + 24} ${my - 56} Q ${mx + 14} ${my - 58} ${mx + 6} ${my - 62} Q ${mx - 6} ${my - 54} ${mx - 16} ${my - 54} Q ${mx - 32} ${my - 48} ${mx - 42} ${my - 34} Z" fill="url(#fcSnow)" stroke="${OUT}" stroke-width="2"/>
    <path d="M ${mx - 26} ${my - 54} Q ${mx - 14} ${my - 64} ${mx} ${my - 66}" stroke="#fff" stroke-width="2" fill="none" stroke-linecap="round" opacity="0.9"/>`;
  // Right (label) side: a small frozen lake rim with snow lumps.
  const lake = `
    <ellipse cx="226" cy="124" rx="28" ry="7.5" fill="#e8f6ff" stroke="${OUT}" stroke-width="1.8"/>
    <ellipse cx="226" cy="124.5" rx="23" ry="5.5" fill="url(#fcLake)"/>
    <path d="M 210 123 L 220 125 L 228 122 M 232 126 L 240 124" stroke="#e6f8ff" stroke-width="0.9" opacity="0.8"/>
    <ellipse cx="218" cy="122.5" rx="7" ry="1.4" fill="#fff" opacity="0.8"/>
    <ellipse cx="226" cy="124" rx="30" ry="10" fill="${Z}" opacity="0.25" filter="url(#bl4)"/>
    ${shard(252, 120, 13, 4, 10, { glow: true })}${shard(258, 122, 8, 3, 24, { glow: false })}${shard(196, 136, 9, 3, -14, { glow: false })}
    ${[[206, 134, 6], [246, 132, 5], [262, 112, 4]].map(([x, y, r]) => `<ellipse cx="${x}" cy="${y}" rx="${r}" ry="${r * 0.55}" fill="#e8f6ff" stroke="${OUT}" stroke-width="1.4"/><ellipse cx="${x - r * 0.3}" cy="${y - r * 0.2}" rx="${r * 0.45}" ry="${r * 0.2}" fill="#fff"/>`).join("")}`;
  // Falling snow and sparkles.
  const snow = Array.from({ length: 26 }, () => [R() * 270 + 5, R() * 200 + 4, 0.8 + R() * 1.6]).filter(([x, y]) => Math.hypot(x - 140, y - 92) > 66)
    .map(([x, y, r]) => `<circle cx="${f(x)}" cy="${f(y)}" r="${f(r)}" fill="#eef8ff" opacity="${(0.5 + r * 0.2).toFixed(2)}"/>`).join("");

  return `<svg xmlns="http://www.w3.org/2000/svg" width="280" height="210" viewBox="0 0 280 210">${blurs()}
  <defs>
    <radialGradient id="fcUnder" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="${Z}" stop-opacity="0.6"/><stop offset="0.55" stop-color="${Z}" stop-opacity="0.18"/><stop offset="1" stop-color="${Z}" stop-opacity="0"/></radialGradient>
    <radialGradient id="fcAura" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="${Z}" stop-opacity="0.2"/><stop offset="0.7" stop-color="${Z}" stop-opacity="0.05"/><stop offset="1" stop-color="${Z}" stop-opacity="0"/></radialGradient>
    <linearGradient id="fcUrock" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2a3e7a"/><stop offset="0.5" stop-color="#1c2a5a"/><stop offset="1" stop-color="#101838"/></linearGradient>
    <linearGradient id="fcSide" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8ab8ff" stop-opacity="0.35"/><stop offset="0.35" stop-color="#8ab8ff" stop-opacity="0"/><stop offset="0.7" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.4"/></linearGradient>
    <radialGradient id="fcTop" cx="0.3" cy="0.35" r="0.85"><stop offset="0" stop-color="#d6ecff"/><stop offset="0.45" stop-color="#a8c8ee"/><stop offset="1" stop-color="#6e92c8"/></radialGradient>
    <linearGradient id="fcLip" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#b8daf8"/><stop offset="1" stop-color="#7aa4d8"/></linearGradient>
    <linearGradient id="fcRock" x1="0" y1="0" x2="1" y2="0.3"><stop offset="0" stop-color="#4a64a8"/><stop offset="0.5" stop-color="#2e427e"/><stop offset="1" stop-color="#1a2654"/></linearGradient>
    <linearGradient id="fcSnow" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffffff"/><stop offset="1" stop-color="#bcdcf8"/></linearGradient>
    <radialGradient id="fcMouth" cx="0.5" cy="0.75" r="0.75"><stop offset="0" stop-color="#ffffff"/><stop offset="0.3" stop-color="#d0f4ff"/><stop offset="0.7" stop-color="#6ab8ee"/><stop offset="1" stop-color="#2a4a8a"/></radialGradient>
    <linearGradient id="fcLake" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#bfeaff"/><stop offset="0.5" stop-color="#6aaee8"/><stop offset="1" stop-color="#3a6ab8"/></linearGradient>
<linearGradient id="edgeH" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#fff" stop-opacity="0"/><stop offset="0.04" stop-color="#fff"/><stop offset="0.96" stop-color="#fff"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>
    <linearGradient id="edgeV" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0"/><stop offset="0.04" stop-color="#fff"/><stop offset="0.95" stop-color="#fff"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>
    <mask id="edgeMH" maskUnits="userSpaceOnUse" x="0" y="0" width="280" height="210"><rect width="280" height="210" fill="url(#edgeH)"/></mask>
    <mask id="edgeMV" maskUnits="userSpaceOnUse" x="0" y="0" width="280" height="210"><rect width="280" height="210" fill="url(#edgeV)"/></mask>
  </defs>
  <g mask="url(#edgeMH)"><g mask="url(#edgeMV)">
  <ellipse cx="140" cy="126" rx="138" ry="82" fill="url(#fcAura)"/>
  <ellipse cx="140" cy="170" rx="104" ry="38" fill="url(#fcUnder)"/>
  <path d="${B.d}" fill="#121a40" stroke="${OUT}" stroke-width="2" stroke-linejoin="round"/>
  <path d="${U.d}" fill="url(#fcUrock)" stroke="${OUT}" stroke-width="2.5" stroke-linejoin="round"/>
  <path d="${U.d}" fill="url(#fcSide)"/>
  ${U.ridges}${glints}${ics}
  <ellipse cx="${CX}" cy="${CY + 8}" rx="${RX - 1}" ry="${RY}" fill="url(#fcLip)" stroke="${OUT}" stroke-width="2.5"/>
  <path d="${snowLip}" fill="#c4def8" stroke="${OUT}" stroke-width="2" stroke-linejoin="round"/>
  ${lipIcicles}
  <ellipse cx="${CX}" cy="${CY}" rx="${RX}" ry="${RY}" fill="url(#fcTop)" stroke="${OUT}" stroke-width="2.5"/>
  <path d="M ${CX - RX + 10} ${CY + 6} Q ${CX - 60} ${CY + RY - 4} ${CX} ${CY + RY - 2} Q ${CX + 60} ${CY + RY - 4} ${CX + RX - 10} ${CY + 6}" fill="none" stroke="#8ab0e0" stroke-width="3" opacity="0.5" stroke-linecap="round"/>
  ${[[70, 112, 18], [196, 108, 16], [110, 140, 14], [176, 140, 14], [236, 138, 10]].map(([x, y, r]) => `<ellipse cx="${x}" cy="${y}" rx="${r}" ry="${r * 0.25}" fill="#4a6aa8" opacity="0.3"/><ellipse cx="${x - r * 0.3}" cy="${y - 1.5}" rx="${r * 0.6}" ry="${r * 0.12}" fill="#eef8ff" opacity="0.55"/>`).join("")}
  ${lake}
  ${shard(72, 104, 80, 12, 8, { col: "#9ad0ff" })}${shard(24, 112, 70, 10, -8, { col: "#b8a8ff" })}
  ${shard(54, 98, 92, 13, -2)}
  ${cave}
  ${shard(88, 132, 40, 8, 14)}${shard(16, 134, 28, 7, -12)}${shard(80, 140, 20, 5, 30, { col: "#b8a8ff", glow: false })}${shard(24, 144, 16, 5, -26, { glow: false })}
  ${snow}
  ${twinkle(46, 8, 5, "#ffffff", 0.95)}${twinkle(94, 34, 4, "#eaf8ff", 0.8)}${twinkle(250, 84, 3.5, "#ffffff", 0.75)}${twinkle(12, 60, 3, "#eaf8ff", 0.7)}
  </g></g>
  </svg>`;
}

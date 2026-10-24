// Shop: a cosy night-market stall. A shopkeeper critter in a boater hat and
// apron, shelves of boon badges, a jar of Buttons on the counter, string lights.
import { ball, eye, brow, shade, INK } from "../../brand/parts.mjs";
import { svg, blurs, coin, badge, sparkle, stars, stringLights, smile, blush, rng, RARITY } from "./_shop_charge_pad_glow_chest_parts.mjs";

const C = RARITY.common, R = RARITY.rare, E = RARITY.epic;
const BULBS = ["#FFD34E", "#FF8AD0", "#3EE6FF", "#5CFF9A", "#FF7A45"];

function farStalls() {
  const r = rng(7);
  let out = "";
  const stall = (x, w, h, col) => {
    let win = "";
    for (let k = 0; k < 3; k++) win += `<circle cx="${x + w * (0.2 + k * 0.3)}" cy="${330 - h + 18}" r="4" fill="${["#FFD34E", "#FF8AD0", "#3EE6FF"][k]}"/>`;
    return `<path d="M ${x} 330 L ${x} ${330 - h + 12} Q ${x + w / 2} ${330 - h - 10} ${x + w} ${330 - h + 12} L ${x + w} 330 Z" fill="${col}"/>
      <rect x="${x + w * 0.15}" y="${330 - h + 30}" width="${w * 0.7}" height="${h * 0.35}" rx="4" fill="#ffb86b" opacity="${0.25 + r() * 0.2}"/>${win}`;
  };
  out += `<g opacity="0.8" filter="url(#bl1)">${stall(-10, 90, 120, "#1d1850")}${stall(70, 70, 90, "#211b5a")}${stall(640, 100, 125, "#1d1850")}${stall(590, 60, 85, "#211b5a")}</g>`;
  return out;
}

function canopy() {
  const x0 = 78, x1 = 642, top = 58, bot = 112, n = 10, w = (x1 - x0) / n;
  let edge = `M ${x0} ${top} L ${x1} ${top} L ${x1} ${bot}`;
  for (let k = n - 1; k >= 0; k--) edge += ` Q ${x0 + w * (k + 0.5)} ${bot + 22} ${x0 + w * k} ${bot}`;
  edge += " Z";
  let stripes = "";
  for (let k = 0; k < n; k++) stripes += `<rect x="${x0 + w * k}" y="${top - 10}" width="${w}" height="80" fill="${k % 2 ? "#e9dcc6" : "#2b8a96"}"/>`;
  return `
  <defs>
    <clipPath id="cnp"><path d="${edge}"/></clipPath>
    <linearGradient id="cnpS" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0d0b26" stop-opacity="0.7"/><stop offset="0.6" stop-color="#0d0b26" stop-opacity="0.15"/><stop offset="1" stop-color="#ffb86b" stop-opacity="0.25"/></linearGradient>
  </defs>
  <path d="M ${x0 + 10} ${top - 8} L ${x1 - 10} ${top - 8} L ${x1 + 6} ${top + 6} L ${x0 - 6} ${top + 6} Z" fill="#3a2a2a"/>
  <g clip-path="url(#cnp)">${stripes}<rect x="${x0}" y="${top - 10}" width="${x1 - x0}" height="90" fill="url(#cnpS)"/></g>
  <path d="${edge}" fill="none" stroke="#120e2a" stroke-width="3"/>`;
}

function lantern(x, y) {
  return `<line x1="${x}" y1="112" x2="${x}" y2="${y - 16}" stroke="#120e2a" stroke-width="2"/>
  <circle cx="${x}" cy="${y}" r="46" fill="#ffb347" opacity="0.35" filter="url(#bl16)"/>
  <rect x="${x - 9}" y="${y - 18}" width="18" height="6" rx="2" fill="#3a2a2a"/>
  <path d="M ${x - 12} ${y - 12} Q ${x - 16} ${y} ${x - 12} ${y + 12} L ${x + 12} ${y + 12} Q ${x + 16} ${y} ${x + 12} ${y - 12} Z" fill="#ffcf7a" stroke="#7a4a20" stroke-width="2"/>
  <ellipse cx="${x}" cy="${y}" rx="6" ry="8" fill="#fff6d8"/>
  <rect x="${x - 9}" y="${y + 12}" width="18" height="5" rx="2" fill="#3a2a2a"/>`;
}

function shelf(y) {
  return `<rect x="132" y="${y}" width="456" height="11" rx="2" fill="#7a5238"/>
    <rect x="132" y="${y}" width="456" height="3" fill="#b07c56"/>
    <rect x="132" y="${y + 11}" width="456" height="10" fill="#000" opacity="0.25" filter="url(#bl3)"/>`;
}

function shopkeeper(cx, cy, r) {
  const col = "#FFB547";
  const ey = cy - r * 0.26;
  // Apron: bib clipped to the body, straps around the sides.
  const ap = `
    <defs><clipPath id="skc"><ellipse cx="${cx}" cy="${cy}" rx="${r}" ry="${r}"/></clipPath></defs>
    <g clip-path="url(#skc)">
      <path d="M ${cx - r * 0.98} ${cy + r * 0.2} Q ${cx - r * 0.6} ${cy + r * 0.36} ${cx - r * 0.42} ${cy + r * 0.5}" fill="none" stroke="#2a7f8c" stroke-width="${r * 0.08}"/>
      <path d="M ${cx + r * 0.98} ${cy + r * 0.2} Q ${cx + r * 0.6} ${cy + r * 0.36} ${cx + r * 0.42} ${cy + r * 0.5}" fill="none" stroke="#2a7f8c" stroke-width="${r * 0.08}"/>
      <path d="M ${cx - r * 0.48} ${cy + r * 0.46} Q ${cx} ${cy + r * 0.52} ${cx + r * 0.48} ${cy + r * 0.46} L ${cx + r * 0.6} ${cy + r * 1.2} L ${cx - r * 0.6} ${cy + r * 1.2} Z" fill="#2fa3b0" stroke="#145560" stroke-width="${r * 0.04}"/>
      <path d="M ${cx - r * 0.42} ${cy + r * 0.53} Q ${cx} ${cy + r * 0.59} ${cx + r * 0.42} ${cy + r * 0.53}" fill="none" stroke="#e9dcc6" stroke-width="${r * 0.025}" stroke-dasharray="${r * 0.05} ${r * 0.04}"/>
      <rect x="${cx - r * 0.24}" y="${cy + r * 0.66}" width="${r * 0.48}" height="${r * 0.4}" rx="${r * 0.06}" fill="#258895" stroke="#145560" stroke-width="${r * 0.03}"/>
    </g>`;
  // Boater hat, tipped at a jaunty angle.
  const hy = cy - r * 0.86;
  const hat = `<g transform="rotate(-10 ${cx} ${hy})">
      <ellipse cx="${cx + 2}" cy="${hy + 6}" rx="${r * 0.72}" ry="${r * 0.14}" fill="#000" opacity="0.3" filter="url(#bl3)"/>
      <ellipse cx="${cx}" cy="${hy}" rx="${r * 0.7}" ry="${r * 0.15}" fill="#e8c77e" stroke="#7a5522" stroke-width="2.5"/>
      <path d="M ${cx - r * 0.4} ${hy} L ${cx - r * 0.37} ${hy - r * 0.36} Q ${cx} ${hy - r * 0.44} ${cx + r * 0.37} ${hy - r * 0.36} L ${cx + r * 0.4} ${hy} Q ${cx} ${hy + r * 0.08} ${cx - r * 0.4} ${hy} Z" fill="#f2d48e" stroke="#7a5522" stroke-width="2.5"/>
      <path d="M ${cx - r * 0.39} ${hy - r * 0.1} Q ${cx} ${hy - r * 0.02} ${cx + r * 0.39} ${hy - r * 0.1} L ${cx + r * 0.385} ${hy - r * 0.2} Q ${cx} ${hy - r * 0.12} ${cx - r * 0.385} ${hy - r * 0.2} Z" fill="#FF6FB5"/>
      ${badge(cx + r * 0.25, hy - r * 0.15, r * 0.1, C, { glow: 0.6 })}
      <ellipse cx="${cx - r * 0.2}" cy="${hy - r * 0.3}" rx="${r * 0.12}" ry="${r * 0.04}" fill="#fff" opacity="0.5"/>
    </g>`;
  return `
  ${ball(cx, cy, r, col)}
  <path d="M ${cx - r * 0.98} ${cy + r * 0.1} A ${r} ${r} 0 0 1 ${cx - r * 0.5} ${cy - r * 0.86}" fill="none" stroke="#7ff3ff" stroke-width="3" opacity="0.6" filter="url(#bl1)"/>
  <path d="M ${cx + r * 0.5} ${cy - r * 0.86} A ${r} ${r} 0 0 1 ${cx + r * 0.98} ${cy + r * 0.1}" fill="none" stroke="#ff9ad6" stroke-width="3" opacity="0.6" filter="url(#bl1)"/>
  ${ap}
  ${eye(cx - r * 0.32, ey, r * 0.2, r * 0.25, 0.6, 0.25, r * 0.11)}
  ${eye(cx + r * 0.32, ey, r * 0.2, r * 0.25, 0.6, 0.25, r * 0.11)}
  ${brow(cx - r * 0.5, ey - r * 0.4, cx - r * 0.16, ey - r * 0.34, r * 0.07)}
  <path d="M ${cx + r * 0.16} ${ey - r * 0.36} Q ${cx + r * 0.34} ${ey - r * 0.52} ${cx + r * 0.52} ${ey - r * 0.4}" fill="none" stroke="${INK}" stroke-width="${r * 0.07}" stroke-linecap="round"/>
  ${blush(cx - r * 0.56, cy + r * 0.08, r * 0.13)}${blush(cx + r * 0.58, cy + r * 0.08, r * 0.13)}
  <path d="M ${cx - r * 0.24} ${cy + r * 0.12} Q ${cx + r * 0.02} ${cy + r * 0.42} ${cx + r * 0.3} ${cy + r * 0.08} Q ${cx + r * 0.04} ${cy + r * 0.2} ${cx - r * 0.24} ${cy + r * 0.12} Z" fill="${INK}"/>
  <path d="M ${cx - r * 0.06} ${cy + r * 0.24} Q ${cx + r * 0.06} ${cy + r * 0.33} ${cx + r * 0.16} ${cy + r * 0.22}" fill="#ff5a7a"/>
  ${hat}`;
}

function jar(cx, base) {
  const w = 46, h = 104, top = base - h;
  const r = rng(3);
  let coins = "";
  const spots = [[-24, -18], [8, -16], [30, -22], [-10, -42], [22, -48], [-30, -58], [2, -68], [28, -76], [-18, -82]];
  for (const [dx, dy] of spots) coins += coin(cx + dx, base + dy, 17, { rot: r() * 60, sy: 0.75 + r() * 0.25, glow: false, shadow: true });
  return `
  <defs>
    <clipPath id="jarC"><path d="M ${cx - w + 4} ${top + 16} Q ${cx - w - 4} ${top + 26} ${cx - w} ${top + 40} L ${cx - w} ${base - 8} Q ${cx - w} ${base} ${cx - w + 8} ${base} L ${cx + w - 8} ${base} Q ${cx + w} ${base} ${cx + w} ${base - 8} L ${cx + w} ${top + 40} Q ${cx + w + 4} ${top + 26} ${cx + w - 4} ${top + 16} Z"/></clipPath>
  </defs>
  <ellipse cx="${cx}" cy="${base}" rx="${w + 14}" ry="8" fill="#000" opacity="0.4" filter="url(#bl3)"/>
  <circle cx="${cx}" cy="${base - 46}" r="70" fill="#ffd98a" opacity="0.25" filter="url(#bl16)"/>
  <g clip-path="url(#jarC)">
    <rect x="${cx - w - 6}" y="${top}" width="${w * 2 + 12}" height="${h}" fill="#2a4a6a" opacity="0.45"/>
    ${coins}
    <rect x="${cx - w - 6}" y="${top}" width="${w * 2 + 12}" height="${h}" fill="#bfefff" opacity="0.12"/>
    <rect x="${cx - w + 6}" y="${top + 24}" width="7" height="${h - 34}" rx="3.5" fill="#fff" opacity="0.55"/>
    <rect x="${cx + w - 14}" y="${top + 30}" width="3" height="${h - 50}" rx="1.5" fill="#fff" opacity="0.35"/>
  </g>
  <path d="M ${cx - w + 4} ${top + 16} Q ${cx - w - 4} ${top + 26} ${cx - w} ${top + 40} L ${cx - w} ${base - 8} Q ${cx - w} ${base} ${cx - w + 8} ${base} L ${cx + w - 8} ${base} Q ${cx + w} ${base} ${cx + w} ${base - 8} L ${cx + w} ${top + 40} Q ${cx + w + 4} ${top + 26} ${cx + w - 4} ${top + 16}" fill="none" stroke="#cfefff" stroke-width="2.5" opacity="0.8"/>
  <rect x="${cx - w + 2}" y="${top + 2}" width="${w * 2 - 4}" height="16" rx="4" fill="#22b8b0" stroke="#0b5a62" stroke-width="2.5"/>
  <rect x="${cx - w + 6}" y="${top + 5}" width="${w - 8}" height="3" rx="1.5" fill="#bffff8" opacity="0.7"/>
  <path d="M ${cx - 14} ${top + 2} Q ${cx} ${top - 12} ${cx + 14} ${top + 2}" fill="none" stroke="#FF6FB5" stroke-width="4" stroke-linecap="round"/>`;
}

function counter() {
  const r = rng(11);
  let planks = "";
  for (let x = 66; x < 654; x += 49) {
    const t = 0.85 + r() * 0.3;
    planks += `<rect x="${x}" y="326" width="47" height="120" fill="${shade("#6a4532", (t - 1) * 0.8)}"/>
      <rect x="${x + 47}" y="326" width="2" height="120" fill="#2a1a16"/>
      <circle cx="${x + 8}" cy="340" r="2" fill="#2a1a16"/><circle cx="${x + 39}" cy="340" r="2" fill="#2a1a16"/>`;
  }
  let flags = "";
  const fc = ["#FF8AD0", "#3EE6FF", "#B88CFF", "#FFD34E"];
  for (let k = 0; k < 12; k++) {
    const x = 80 + k * 48;
    flags += `<path d="M ${x} 330 L ${x + 44} 330 L ${x + 22} 356 Z" fill="${fc[k % 4]}" opacity="0.85"/><path d="M ${x} 330 L ${x + 44} 330 L ${x + 22} 356 Z" fill="url(#ctrShade)"/>`;
  }
  return `
  <defs>
    <linearGradient id="ctrTop" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#d79a63"/><stop offset="1" stop-color="#8a5a3a"/></linearGradient>
    <linearGradient id="ctrShade" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.35"/></linearGradient>
    <linearGradient id="ctrFade" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0D0F26" stop-opacity="0"/><stop offset="1" stop-color="#0D0F26" stop-opacity="0.75"/></linearGradient>
    <radialGradient id="ctrPool" cx="0.5" cy="0" r="0.7"><stop offset="0" stop-color="#ffcf7a" stop-opacity="0.35"/><stop offset="1" stop-color="#ffcf7a" stop-opacity="0"/></radialGradient>
  </defs>
  ${planks}
  <rect x="66" y="326" width="588" height="120" fill="url(#ctrFade)"/>
  ${flags}
  <path d="M 56 312 L 664 312 L 670 328 L 50 328 Z" fill="url(#ctrTop)" stroke="#2a1a16" stroke-width="2"/>
  <rect x="56" y="312" width="608" height="3" fill="#ffd9a8" opacity="0.6"/>
  <ellipse cx="360" cy="318" rx="300" ry="20" fill="url(#ctrPool)"/>`;
}

function displayStand(cx, base) {
  return `
  <ellipse cx="${cx}" cy="${base}" rx="54" ry="7" fill="#000" opacity="0.4" filter="url(#bl3)"/>
  <path d="M ${cx - 46} ${base} Q ${cx - 50} ${base - 18} ${cx - 30} ${base - 22} L ${cx + 30} ${base - 22} Q ${cx + 50} ${base - 18} ${cx + 46} ${base} Z" fill="#7a2e6a" stroke="#3a1232" stroke-width="2"/>
  <path d="M ${cx - 36} ${base - 18} Q ${cx} ${base - 26} ${cx + 36} ${base - 18}" fill="none" stroke="#ff9ad6" stroke-width="2" opacity="0.5"/>
  ${badge(cx, base - 54, 28, E, { glow: 1.2 })}
  ${sparkle(cx + 30, base - 84, 7, "#fff")}
  ${sparkle(cx - 32, base - 62, 5, "#ffd0ee")}`;
}

// A customer seen from behind, in the dark foreground, rim-lit by the stall.
function customer(cx, cy, r, col, side) {
  const dark = shade(col, -0.78);
  return `<ellipse cx="${cx}" cy="${cy}" rx="${r}" ry="${r}" fill="${dark}"/>
    <path d="M ${cx - r * 0.95} ${cy - r * 0.3} A ${r} ${r} 0 0 1 ${cx + r * 0.95} ${cy - r * 0.3}" fill="none" stroke="${col}" stroke-width="4" opacity="0.8" filter="url(#bl1)"/>
    <path d="M ${cx - r * 0.7} ${cy - r * 0.66} A ${r} ${r} 0 0 1 ${cx + r * 0.7} ${cy - r * 0.66}" fill="none" stroke="#ffd9a8" stroke-width="2" opacity="0.6"/>`;
}

export default () => {
  const shelfBadges = [
    [166, 164, C], [216, 164, R], [264, 164, C],
    [456, 164, R], [504, 164, C], [554, 164, E],
    [156, 236, R], [262, 236, C], [462, 236, E],
  ];
  return svg(`${blurs()}
  <defs>
    <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0D0F26"/><stop offset="0.6" stop-color="#141038"/><stop offset="1" stop-color="#2c2170"/></linearGradient>
    <radialGradient id="wall" cx="0.5" cy="0.55" r="0.65"><stop offset="0" stop-color="#4a3270"/><stop offset="0.6" stop-color="#2a1d58"/><stop offset="1" stop-color="#191340"/></radialGradient>
  </defs>
  <rect width="720" height="440" fill="url(#sky)"/>
  ${stars(5, 70, 0, 0, 720, 200)}
  ${farStalls()}
  <rect x="0" y="328" width="720" height="112" fill="#120f30"/>
  ${stringLights(-10, 26, 730, 34, 18, 16, BULBS, 4)}
  <!-- stall back wall and posts -->
  <rect x="128" y="104" width="464" height="226" fill="url(#wall)"/>
  <circle cx="360" cy="240" r="150" fill="#ffb86b" opacity="0.12" filter="url(#bl32)"/>
  ${shelf(190)}${shelf(262)}
  ${shelfBadges.map(([x, y, c], k) => badge(x, y, 19, c, { stand: true, rot: k % 3 === 1 ? 6 : -4 })).join("")}
  <rect x="104" y="96" width="22" height="234" fill="#5a3a2c"/><rect x="104" y="96" width="5" height="234" fill="#8a6048"/>
  <rect x="594" y="96" width="22" height="234" fill="#5a3a2c"/><rect x="611" y="96" width="5" height="234" fill="#3a241c"/>
  ${canopy()}
  ${lantern(90, 152)}${lantern(630, 152)}
  ${stringLights(78, 114, 642, 114, 7, 12, BULBS, 5)}
  ${"" /* living layers (render.mjs): the shopkeeper idles behind the counter, the customers bob */}
  <g data-layer="keeper" data-move="idle 4 0.6 0">${shopkeeper(360, 238, 82)}</g>
  <g data-layer="counter">
  ${counter()}
  ${displayStand(206, 314)}
  ${jar(528, 314)}
  ${coin(452, 306, 13, { rot: 20, sy: 0.4, glow: false })}
  ${coin(474, 309, 12, { rot: -10, sy: 0.4, glow: false })}
  ${coin(590, 300, 14, { rot: 15, sy: 0.85, glow: false })}
  </g>
  <ellipse cx="360" cy="380" rx="240" ry="60" fill="#ffb86b" opacity="0.10" filter="url(#bl24)"/>
  <g data-layer="customers" data-move="bob 4 0.5 0.3">${customer(96, 446, 74, "#3EA8FF", 1)}${customer(650, 468, 62, "#5CFF9A", -1)}</g>
  ${sparkle(620, 250, 6)}${sparkle(100, 200, 5, "#c8fff9", 0.8)}`);
};

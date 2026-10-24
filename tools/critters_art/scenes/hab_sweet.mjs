// Sweet habitat: a dusk candy meadow. Soft peach-pink sunset low behind the
// stage, layered gumdrop hills, lollipop trees, sugar sparkle motes. Matte
// palette. Stage: a frosted cookie-stump platform at (200, 330).
import { blurs, critter, sky, motes, sparkle, shade, rng, f } from "./_p.mjs";
import { W, H, SX, SY, fades, withHero } from "./_hab.mjs";

export const size = [W, H];

function lolly(x, y, h, r, col, o = 1, dark = "#3a1f48") {
  return `<g opacity="${o}">
    <path d="M ${x} ${y} L ${x} ${y - h}" stroke="${shade("#f3e3ee", -0.15)}" stroke-width="${r * 0.16}" stroke-linecap="round"/>
    <circle cx="${x}" cy="${y - h}" r="${r}" fill="${col}" stroke="${dark}" stroke-width="${r * 0.08}"/>
    <path d="M ${x} ${y - h} m ${-r * 0.7} 0 a ${r * 0.7} ${r * 0.7} 0 0 1 ${r * 1.4} 0 a ${r * 0.48} ${r * 0.48} 0 0 1 ${-r * 0.96} 0 a ${r * 0.26} ${r * 0.26} 0 0 1 ${r * 0.52} 0" fill="none" stroke="${shade(col, 0.45)}" stroke-width="${r * 0.18}" stroke-linecap="round" opacity="0.8"/>
    <circle cx="${x - r * 0.4}" cy="${y - h - r * 0.42}" r="${r * 0.16}" fill="#fff" opacity="0.35"/></g>`;
}

function gumdrop(x, y, w, h, col, o = 1) {
  return `<g opacity="${o}"><path d="M ${x - w} ${y} Q ${x - w * 0.95} ${y - h} ${x} ${y - h} Q ${x + w * 0.95} ${y - h} ${x + w} ${y} Q ${x} ${y + h * 0.16} ${x - w} ${y} Z" fill="${col}"/>
    <path d="M ${x - w} ${y} Q ${x} ${y + h * 0.16} ${x + w} ${y} Q ${x + w * 0.98} ${y - h * 0.18} ${x + w * 0.9} ${y - h * 0.3} Q ${x} ${y - h * 0.08} ${x - w * 0.9} ${y - h * 0.3} Q ${x - w * 0.98} ${y - h * 0.18} ${x - w} ${y} Z" fill="${shade(col, -0.25)}"/>
    <path d="M ${x - w * 0.55} ${y - h * 0.65} Q ${x - w * 0.2} ${y - h * 0.98} ${x + w * 0.2} ${y - h * 0.9}" fill="none" stroke="${shade(col, 0.35)}" stroke-width="${Math.max(2, w * 0.06)}" stroke-linecap="round" opacity="0.6"/></g>`;
}

function scene() {
  const R = rng(31);
  // Sugar dots on hills.
  const sugar = (x0, y0, x1, y1, n, col, o) => {
    let s = "";
    for (let k = 0; k < n; k++) s += `<circle cx="${f(x0 + R() * (x1 - x0))}" cy="${f(y0 + R() * (y1 - y0))}" r="${f(0.8 + R() * 1.4)}" fill="${col}" opacity="${o}"/>`;
    return s;
  };
  const sun = `
    <circle cx="250" cy="236" r="260" fill="#ff9a8a" opacity="0.22" filter="url(#bl40)"/>
    <ellipse cx="250" cy="236" rx="200" ry="70" fill="#ffc29a" opacity="0.4" filter="url(#bl32)"/>
    <circle cx="262" cy="230" r="46" fill="#ffe0bc" opacity="0.9"/>
    <circle cx="262" cy="230" r="70" fill="#ffd2a8" opacity="0.4" filter="url(#bl16)"/>`;
  // Soft clouds lit from below.
  const cloud = (x, y, s, o) => `<g opacity="${o}"><ellipse cx="${x}" cy="${y}" rx="${60 * s}" ry="${12 * s}" fill="#b0608a"/>
    <ellipse cx="${x - 18 * s}" cy="${y - 7 * s}" rx="${30 * s}" ry="${12 * s}" fill="#b0608a"/><ellipse cx="${x + 16 * s}" cy="${y - 10 * s}" rx="${24 * s}" ry="${12 * s}" fill="#b0608a"/>
    <path d="M ${x - 54 * s} ${y + 6 * s} Q ${x} ${y + 14 * s} ${x + 56 * s} ${y + 5 * s}" fill="none" stroke="#ffb59a" stroke-width="${3 * s}" stroke-linecap="round" opacity="0.8"/></g>`;
  const clouds = `${cloud(110, 150, 1.2, 0.55)}${cloud(420, 176, 1.0, 0.5)}${cloud(640, 110, 1.4, 0.35)}${cloud(330, 96, 0.8, 0.35)}`;
  // Far gumdrop hills (hazy).
  const far = `
    ${gumdrop(80, 330, 90, 110, "#7a4a86", 0.9)}${gumdrop(430, 330, 110, 124, "#6e4482", 0.9)}${gumdrop(600, 330, 120, 104, "#5e3c78", 0.9)}${gumdrop(740, 330, 90, 118, "#5a3a74", 0.9)}
    <rect x="0" y="262" width="${W}" height="50" fill="#ffb59a" opacity="0.16" filter="url(#bl12)"/>`;
  const mid = `
    ${gumdrop(330, 340, 120, 98, "#8a4c84")}${gumdrop(520, 340, 150, 102, "#6a3c74")}${gumdrop(30, 340, 120, 100, "#7c4680")}
    ${sugar(220, 250, 440, 310, 26, "#ffe6f2", 0.35)}${sugar(380, 250, 660, 310, 16, "#ffe6f2", 0.2)}
    <path d="M 0 320 Q 200 296 420 314 Q 600 326 780 304 L 780 460 L 0 460 Z" fill="#4e2c62"/>`;
  // Far lollipop trees.
  const farLollies = `${lolly(452, 300, 40, 12, "#e08aa8", 0.8)}${lolly(474, 306, 30, 9, "#d8a46e", 0.75)}${lolly(560, 254, 30, 10, "#b07ac0", 0.6)}${lolly(690, 230, 30, 11, "#c47896", 0.5)}${lolly(130, 272, 28, 9, "#e0a080", 0.8)}`;
  // Tiny sweet critters far in the meadow.
  const bg = `${critter(470, 312, 9, "#ff7ac8", { acc: "ears", mood: "happy", look: [-0.5, 0], rim: "#ffd2a8", rimSide: -1 })}
    ${critter(492, 316, 6.5, "#f68ab8", { acc: "ears", mood: "cheer", rim: "#ffd2a8", rimSide: -1 })}
    ${critter(56, 290, 7, "#ff7ac8", { acc: "ears", mood: "sleepy", rim: "#ffd2a8", rimSide: 1 })}`;
  // Near lollipop tree on the left edge and right of the stage, gumdrops near.
  const near = `
    ${lolly(30, 392, 242, 46, "#e07a9e")}
    ${lolly(392, 380, 156, 30, "#e8a070")}
    <path d="M -10 460 L -10 372 Q 120 352 260 360 Q 380 366 470 384 Q 520 400 540 460 Z" fill="#3e2252"/>
    ${sugar(0, 366, 520, 420, 40, "#ffd6ea", 0.25)}
    <ellipse cx="364" cy="384" rx="34" ry="6" fill="#1e0e2a" opacity="0.6" filter="url(#bl3)"/>
    ${gumdrop(356, 384, 26, 34, "#c85a8a")}
    <ellipse cx="420" cy="394" rx="26" ry="5" fill="#1e0e2a" opacity="0.6" filter="url(#bl3)"/>
    ${gumdrop(416, 394, 20, 26, "#8a6ad0")}
    <ellipse cx="4" cy="402" rx="34" ry="6" fill="#1e0e2a" opacity="0.6" filter="url(#bl3)"/>
    ${gumdrop(-2, 402, 30, 36, "#d07850")}`;
  // Stage: a frosted cookie platform in a pool of sunset light.
  const stage = `
    <ellipse cx="${SX}" cy="${SY - 4}" rx="190" ry="60" fill="#ffc29a" opacity="0.2" filter="url(#bl24)"/>
    <path d="M ${SX - 124} ${SY} L ${SX - 124} ${SY + 20} Q ${SX} ${SY + 56} ${SX + 124} ${SY + 20} L ${SX + 124} ${SY} Z" fill="#8a5038"/>
    <path d="M ${SX - 124} ${SY + 14} Q ${SX} ${SY + 48} ${SX + 124} ${SY + 14}" fill="none" stroke="#5a3026" stroke-width="2"/>
    <ellipse cx="${SX}" cy="${SY}" rx="124" ry="28" fill="#c98a5a" stroke="#5a3026" stroke-width="3"/>
    <path d="M ${SX - 112} ${SY - 4} Q ${SX - 96} ${SY + 14} ${SX - 80} ${SY + 6} Q ${SX - 66} ${SY + 22} ${SX - 46} ${SY + 10} Q ${SX - 28} ${SY + 26} ${SX - 6} ${SY + 12} Q ${SX + 14} ${SY + 26} ${SX + 34} ${SY + 10} Q ${SX + 56} ${SY + 24} ${SX + 74} ${SY + 8} Q ${SX + 94} ${SY + 18} ${SX + 112} ${SY - 4} Q ${SX} ${SY - 34} ${SX - 112} ${SY - 4} Z" fill="#f6cfe0"/>
    <path d="M ${SX - 90} ${SY - 10} Q ${SX} ${SY - 26} ${SX + 90} ${SY - 10}" fill="none" stroke="#fff4f8" stroke-width="3" stroke-linecap="round" opacity="0.8"/>
    <ellipse cx="${SX + 6}" cy="${SY - 4}" rx="70" ry="10" fill="#ffe0bc" opacity="0.4" filter="url(#bl8)"/>
    ${[[-70, 2, "#7ad0c8"], [-30, 10, "#ffd36b"], [24, 6, "#b07cff"], [64, 8, "#7ad0c8"], [90, -2, "#ff8a7a"], [-96, -2, "#ffd36b"], [0, -6, "#ff8a7a"], [-50, -10, "#b07cff"], [46, -8, "#ffd36b"]].map(([dx, dy, c], k) => `<rect x="${SX + dx - 4}" y="${SY + dy - 1.5}" width="8" height="3" rx="1.5" fill="${c}" transform="rotate(${(k * 47) % 180 - 90} ${SX + dx} ${SY + dy})"/>`).join("")}
    <ellipse cx="${SX}" cy="${SY + 40}" rx="170" ry="14" fill="#2a1438" opacity="0.5" filter="url(#bl8)"/>`;
  // Sugar sparkle motes.
  let spk = "";
  [[60, 60], [150, 108], [430, 60], [380, 230], [86, 210], [520, 150], [700, 180], [340, 140]].forEach(([x, y], k) => {
    spk += sparkle(x, y, 3 + (k % 3) * 1.6, "#fff0f6", 0.6);
  });

  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${blurs()}
  <defs>
    <linearGradient id="hwSky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#1a1238"/><stop offset="0.35" stop-color="#4a2558"/><stop offset="0.6" stop-color="#94486e"/><stop offset="0.75" stop-color="#d07a7e"/><stop offset="1" stop-color="#e8a088"/></linearGradient>
  </defs>
  <rect width="${W}" height="${H}" fill="url(#hwSky)"/>
  ${sky(41, 40, 0, 0, 780, 120)}
  ${sun}${clouds}${far}${farLollies}${mid}${bg}
  ${near}${stage}
  ${motes(13, 26, 0, 120, 780, 400, ["#ffe0ec", "#ffd2a8", "#fff4d8"])}
  ${spk}
  ${fades("hw", { right: 0.42 })}
  </svg>`;
}

export const many = {
  hab_sweet: scene,
  hab_sweet_ctx: withHero(scene, "#ff7ac8", "ears", "#ffd2a8"),
};
export default scene;

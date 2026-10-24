// Spooky habitat: a moonlit haunted hill. Big pale moon, crooked castle on a
// far crag (right, kept dim), purple fog banks, tilted gravestones, lanterns
// and wisps. Stage: a flat moonlit hilltop slab at (200, 330).
import { blurs, critter, shadow, sky, motes, sparkle, rng, f } from "./_p.mjs";
import { W, H, SX, SY, fades, withHero } from "./_hab.mjs";

export const size = [W, H];

function grave(x, y, s, rot, col = "#2a1d48") {
  return `<g transform="translate(${f(x)} ${f(y)}) rotate(${rot}) scale(${s})">
    <path d="M -14 0 L -14 -30 Q -14 -46 0 -46 Q 14 -46 14 -30 L 14 0 Z" fill="${col}" stroke="#120a22" stroke-width="2.5"/>
    <path d="M -9 -30 Q -9 -40 0 -41" fill="none" stroke="#6c5aa8" stroke-width="2" opacity="0.6" stroke-linecap="round"/>
    <path d="M -6 -26 L 6 -26 M 0 -33 L 0 -16" stroke="#120a22" stroke-width="2.6" stroke-linecap="round" opacity="0.7"/></g>`;
}

function lantern(x, y, s = 1, o = 1) {
  return `<g opacity="${o}">
    <circle cx="${x}" cy="${y}" r="${26 * s}" fill="#ffb347" opacity="0.35" filter="url(#bl12)"/>
    <path d="M ${x - 6 * s} ${y - 8 * s} L ${x + 6 * s} ${y - 8 * s} L ${x + 8 * s} ${y + 8 * s} L ${x - 8 * s} ${y + 8 * s} Z" fill="#ffd36b" stroke="#1a0f2a" stroke-width="${2 * s}"/>
    <path d="M ${x - 9 * s} ${y - 8 * s} L ${x + 9 * s} ${y - 8 * s} L ${x} ${y - 15 * s} Z" fill="#1a0f2a"/>
    <rect x="${x - 9 * s}" y="${y + 8 * s}" width="${18 * s}" height="${3 * s}" fill="#1a0f2a"/>
    <circle cx="${x}" cy="${y + 1 * s}" r="${3 * s}" fill="#fff3c4"/></g>`;
}

function wisp(x, y, s, o = 0.8) {
  return `<g opacity="${o}"><path d="M ${x} ${y} q ${-8 * s} ${10 * s} ${-2 * s} ${22 * s} q ${4 * s} ${8 * s} ${-6 * s} ${16 * s}" fill="none" stroke="#cdb8ff" stroke-width="${3 * s}" stroke-linecap="round" opacity="0.5" filter="url(#bl2)"/>
    <circle cx="${x}" cy="${y}" r="${12 * s}" fill="#b9e8ff" opacity="0.35" filter="url(#bl6)"/>
    <circle cx="${x}" cy="${y}" r="${4.5 * s}" fill="#e6f6ff"/></g>`;
}

function scene() {
  const R = rng(17);
  // Moon.
  const mx = 352, my = 92;
  const moon = `
    <circle cx="${mx}" cy="${my}" r="150" fill="#8a7cff" opacity="0.18" filter="url(#bl40)"/>
    <circle cx="${mx}" cy="${my}" r="84" fill="#cfd8ff" opacity="0.28" filter="url(#bl24)"/>
    <circle cx="${mx}" cy="${my}" r="56" fill="url(#hsMoon)"/>
    <circle cx="${mx - 18}" cy="${my - 12}" r="10" fill="#b9b6e6" opacity="0.5"/>
    <circle cx="${mx + 16}" cy="${my + 14}" r="14" fill="#b9b6e6" opacity="0.4"/>
    <circle cx="${mx + 22}" cy="${my - 22}" r="6" fill="#b9b6e6" opacity="0.45"/>
    <circle cx="${mx - 8}" cy="${my + 26}" r="5" fill="#b9b6e6" opacity="0.4"/>`;
  // Bats crossing the moon.
  const bat = (x, y, s) => `<path d="M ${x} ${y} q ${-6 * s} ${-6 * s} ${-14 * s} ${-2 * s} q ${4 * s} ${1 * s} ${4 * s} ${5 * s} q ${4 * s} ${-3 * s} ${10 * s} ${-3 * s} q ${6 * s} 0 ${10 * s} ${3 * s} q 0 ${-4 * s} ${4 * s} ${-5 * s} q ${-8 * s} ${-4 * s} ${-14 * s} ${2 * s} Z" fill="#150b26"/>`;
  // Far crag + castle (right, dim).
  const cx0 = 600;
  const castle = `
    <path d="M 440 300 Q 500 250 540 236 L 560 200 L 590 196 L 640 210 Q 700 230 780 228 L 780 320 L 440 320 Z" fill="#251b4c"/>
    <g fill="#21184a">
      <rect x="${cx0 - 50}" y="140" width="34" height="70"/>
      <path d="M ${cx0 - 56} 142 L ${cx0 - 33} 98 L ${cx0 - 10} 142 Z"/>
      <rect x="${cx0 - 18}" y="160" width="70" height="52"/>
      <rect x="${cx0 + 6}" y="116" width="26" height="60" transform="rotate(4 ${cx0 + 19} 176)"/>
      <path d="M ${cx0 + 1} 120 L ${cx0 + 24} 70 L ${cx0 + 40} 122 Z" transform="rotate(6 ${cx0 + 20} 120)"/>
      <rect x="${cx0 + 46}" y="150" width="22" height="60" transform="rotate(-5 ${cx0 + 57} 210)"/>
      <path d="M ${cx0 + 40} 152 L ${cx0 + 54} 118 L ${cx0 + 72} 150 Z" transform="rotate(-8 ${cx0 + 56} 150)"/>
      ${[-48, -40, -32, -24].map((x) => `<rect x="${cx0 + x}" y="134" width="5" height="8"/>`).join("")}
    </g>
    <rect x="${cx0 - 38}" y="160" width="7" height="11" rx="3.5" fill="#ffc85a" opacity="0.75"/>
    <rect x="${cx0 + 16}" y="140" width="6" height="10" rx="3" fill="#ffc85a" opacity="0.6"/>
    <rect x="${cx0 + 2}" y="182" width="7" height="10" rx="3.5" fill="#b07cff" opacity="0.7"/>
    <circle cx="${cx0 - 34}" cy="165" r="12" fill="#ffb347" opacity="0.25" filter="url(#bl6)"/>`;
  // Far hills.
  const hills = `
    <path d="M 0 250 Q 90 220 180 236 Q 280 252 360 230 Q 420 214 470 236 L 470 330 L 0 330 Z" fill="#251a4a"/>
    <path d="M 0 286 Q 120 262 240 276 Q 360 290 470 270 Q 600 250 780 270 L 780 460 L 0 460 Z" fill="#1d1540"/>`;
  // Fog banks.
  let fog = "";
  for (let k = 0; k < 16; k++) {
    const x = R() * 820 - 20, y = 250 + R() * 80;
    fog += `<ellipse cx="${f(x)}" cy="${f(y)}" rx="${f(70 + R() * 90)}" ry="${f(14 + R() * 12)}" fill="#7a5ad0" opacity="${f(0.12 + R() * 0.14)}" filter="url(#bl12)"/>`;
  }
  // Tiny far gravestones and crosses on the mid hill.
  let farGraves = "";
  [[300, 284, 0.42, -8], [326, 288, 0.36, 10], [470, 276, 0.38, -4], [500, 272, 0.32, 8], [36, 270, 0.4, 6], [66, 268, 0.34, -10]].forEach(([x, y, s, r]) => {
    farGraves += grave(x, y, s, r, "#241a44");
  });
  // Bare crooked tree on the left edge.
  const tree = `
    <path d="M 18 360 Q 30 300 22 250 Q 14 210 40 170 Q 52 150 46 120" fill="none" stroke="#120a22" stroke-width="12" stroke-linecap="round"/>
    <path d="M 30 210 Q 60 196 80 170 M 40 170 Q 20 150 6 150 M 46 130 Q 70 116 88 120 M 24 260 Q 0 246 -10 250" fill="none" stroke="#120a22" stroke-width="5" stroke-linecap="round"/>
    <path d="M 80 170 q 10 -4 14 -14 M 88 120 q 8 4 16 -2" fill="none" stroke="#120a22" stroke-width="3" stroke-linecap="round"/>`;
  // Lantern hanging from the tree branch.
  const hang = `<path d="M 86 172 L 86 196" stroke="#120a22" stroke-width="1.5"/>${lantern(86, 206, 0.8)}`;
  // Stage: a flat hilltop slab in a pool of moonlight.
  const stage = `
    <ellipse cx="${SX}" cy="${SY - 10}" rx="200" ry="70" fill="#c9d6ff" opacity="0.10" filter="url(#bl24)"/>
    <path d="M -10 460 L -10 352 Q 60 318 200 316 Q 340 318 420 350 Q 440 380 460 460 Z" fill="#1a1236"/>
    <path d="M ${SX - 128} ${SY + 6} L ${SX - 112} ${SY + 32} L ${SX - 40} ${SY + 42} L ${SX + 60} ${SY + 40} L ${SX + 118} ${SY + 30} L ${SX + 130} ${SY + 6} Z" fill="#150d2c"/>
    <path d="M ${SX - 128} ${SY + 6} L ${SX - 104} ${SY - 14} L ${SX - 30} ${SY - 22} L ${SX + 58} ${SY - 20} L ${SX + 112} ${SY - 10} L ${SX + 130} ${SY + 6} L ${SX + 100} ${SY + 22} L ${SX - 10} ${SY + 28} L ${SX - 100} ${SY + 22} Z" fill="#43367a" stroke="#140c28" stroke-width="3" stroke-linejoin="round"/>
    <path d="M ${SX - 96} ${SY - 8} L ${SX - 28} ${SY - 16} L ${SX + 54} ${SY - 14} L ${SX + 100} ${SY - 4} L ${SX + 40} ${SY + 6} L ${SX - 60} ${SY + 6} Z" fill="#584a98"/>
    <path d="M ${SX - 128} ${SY + 6} L ${SX - 100} ${SY + 22} L ${SX - 10} ${SY + 28} L ${SX + 100} ${SY + 22} L ${SX + 130} ${SY + 6}" fill="none" stroke="#2a2052" stroke-width="2"/>
    <ellipse cx="${SX + 4}" cy="${SY - 6}" rx="80" ry="12" fill="#d6e0ff" opacity="0.28" filter="url(#bl8)"/>
    <path d="M ${SX - 104} ${SY - 14} L ${SX - 30} ${SY - 22} L ${SX + 58} ${SY - 20} L ${SX + 112} ${SY - 10}" fill="none" stroke="#c9d6ff" stroke-width="2" opacity="0.55" stroke-linejoin="round"/>
    <path d="M ${SX - 50} ${SY - 6} l 12 8 l 14 -2 l 8 8 M ${SX + 40} ${SY - 8} l 14 6" stroke="#2a2052" stroke-width="2" fill="none" stroke-linecap="round"/>
    ${[[-120, 8], [-84, 24], [96, 22], [124, 6], [20, 30]].map(([dx, dy]) => `<path d="M ${SX + dx - 7} ${SY + dy} q 3 -12 5 -2 q 2 -14 4 0 q 3 -10 5 2 Z" fill="#2c4a5a"/>`).join("")}
    <ellipse cx="${SX}" cy="${SY + 30}" rx="180" ry="20" fill="#7a5ad0" opacity="0.22" filter="url(#bl12)"/>`;
  // Near gravestones and lantern post right of the stage.
  const near = `
    ${grave(372, 352, 0.95, 12)}
    ${grave(404, 364, 0.7, -9)}
    ${grave(-2, 372, 0.9, -14)}
    <path d="M 352 352 L 356 262 M 356 262 Q 364 254 378 258" fill="none" stroke="#120a22" stroke-width="5" stroke-linecap="round"/>
    <path d="M 378 258 L 378 270" stroke="#120a22" stroke-width="1.5"/>
    ${lantern(378, 280, 0.95)}`;
  // Wisps floating around (outside the reserved zone).
  const wisps = `${wisp(394, 196, 1)}${wisp(56, 120, 0.8, 0.7)}${wisp(500, 200, 0.6, 0.5)}${wisp(700, 260, 0.6, 0.45)}`;
  // Background spooky critters, tiny and far: one peeking from behind a far grave, one floating ghost-ish.
  const bg = `
    ${critter(486, 262, 8, "#b07cff", { acc: "horns", mood: "happy", look: [-0.6, 0], rim: "#cfd8ff", rimSide: -1 })}
    ${critter(52, 262, 7, "#9d6cf0", { acc: "horns", mood: "sleepy", rim: "#cfd8ff", rimSide: -1 })}`;
  const bats = `${bat(318, 70, 1.1)}${bat(392, 96, 0.8)}${bat(352, 132, 0.6)}${bat(520, 60, 0.6)}`;

  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${blurs()}
  <defs>
    <linearGradient id="hsSky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0c0a24"/><stop offset="0.5" stop-color="#22174a"/><stop offset="1" stop-color="#3d2468"/></linearGradient>
    <radialGradient id="hsMoon" cx="0.4" cy="0.38" r="0.7"><stop offset="0" stop-color="#fbfaff"/><stop offset="0.6" stop-color="#e2e4ff"/><stop offset="1" stop-color="#b8b4f0"/></radialGradient>
  </defs>
  <rect width="${W}" height="${H}" fill="url(#hsSky)"/>
  ${sky(23, 70, 0, 0, 780, 220)}
  ${moon}${bats}
  ${castle}${hills}${farGraves}${bg}${fog}
  ${tree}${hang}
  ${stage}${near}${wisps}
  ${motes(9, 20, 0, 160, 780, 400, ["#cdb8ff", "#b9e8ff", "#e6dcff"])}
  ${fades("hs", { right: 0.4 })}
  </svg>`;
}

export const many = {
  hab_spooky: scene,
  hab_spooky_ctx: withHero(scene, "#b07cff", "horns", "#cfd8ff"),
};
export default scene;

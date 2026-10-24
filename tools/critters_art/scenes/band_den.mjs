// "The Den": a cosy burrow at night where the critter collection lives. A round
// window with the moon, a warm lantern, shelves of eggs and trophies, and a
// cushion pile of mixed-family critters. Left-top and top-right kept calm.
import { blurs, critter, shadow, motes, shade, rng, sparkle, stars, FAM, f } from "./_p.mjs";

export const size = [780, 300];
const W = 780, H = 300;

function egg(x, y, s, col, spot) {
  return `<ellipse cx="${x}" cy="${y + s * 0.95}" rx="${s * 0.8}" ry="${s * 0.18}" fill="#000" opacity="0.35"/>
    <path d="M ${x} ${y - s * 1.05} C ${x + s * 0.75} ${y - s * 1.05} ${x + s * 0.85} ${y + s} ${x} ${y + s} C ${x - s * 0.85} ${y + s} ${x - s * 0.75} ${y - s * 1.05} ${x} ${y - s * 1.05} Z" fill="${col}" stroke="${shade(col, -0.55)}" stroke-width="1.5"/>
    <circle cx="${x + s * 0.2}" cy="${y + s * 0.2}" r="${s * 0.18}" fill="${spot}" opacity="0.8"/><circle cx="${x - s * 0.25}" cy="${y - s * 0.3}" r="${s * 0.12}" fill="${spot}" opacity="0.8"/>
    <path d="M ${x + s * 0.3} ${y - s * 0.6} Q ${x + s * 0.55} ${y - s * 0.1} ${x + s * 0.45} ${y + s * 0.5}" fill="none" stroke="#ffd9a0" stroke-width="${s * 0.12}" opacity="0.35" stroke-linecap="round"/>`;
}
function trophy(x, y, s, col) {
  return `<rect x="${x - s * 0.45}" y="${y + s * 0.7}" width="${s * 0.9}" height="${s * 0.3}" rx="2" fill="#3a2418"/>
    <rect x="${x - s * 0.1}" y="${y + s * 0.3}" width="${s * 0.2}" height="${s * 0.42}" fill="${shade(col, -0.3)}"/>
    <path d="M ${x - s * 0.5} ${y - s * 0.5} L ${x + s * 0.5} ${y - s * 0.5} Q ${x + s * 0.48} ${y + s * 0.35} ${x} ${y + s * 0.38} Q ${x - s * 0.48} ${y + s * 0.35} ${x - s * 0.5} ${y - s * 0.5} Z" fill="${col}" stroke="${shade(col, -0.55)}" stroke-width="1.5"/>
    ${[-1, 1].map((d) => `<path d="M ${x + d * s * 0.48} ${y - s * 0.38} q ${d * s * 0.3} 0 ${d * s * 0.24} ${s * 0.3} q ${-d * s * 0.06} ${s * 0.16} ${-d * s * 0.3} ${s * 0.16}" fill="none" stroke="${shade(col, -0.3)}" stroke-width="${s * 0.1}"/>`).join("")}
    <ellipse cx="${x - s * 0.2}" cy="${y - s * 0.2}" rx="${s * 0.08}" ry="${s * 0.22}" fill="#fff6d8" opacity="0.55"/>`;
}

export default function () {
  const R = rng(41);
  // Back wall: packed earth with soft root lines.
  let roots = "";
  for (let k = 0; k < 14; k++) {
    const x = R() * W, y = R() * 200;
    roots += `<path d="M ${f(x)} ${f(y)} q ${f(20 + R() * 30)} ${f(10 + R() * 20)} ${f(50 + R() * 40)} ${f(-4 + R() * 12)}" fill="none" stroke="#1a1020" stroke-width="${f(2 + R() * 3)}" opacity="0.22" stroke-linecap="round"/>`;
  }
  // Round window with moon, starry night beyond.
  const wx = 440, wy = 86, wr = 56;
  const win = `<defs><clipPath id="dnWin"><circle cx="${wx}" cy="${wy}" r="${wr}"/></clipPath></defs>
    <circle cx="${wx}" cy="${wy}" r="${wr + 20}" fill="#6a8cff" opacity="0.12" filter="url(#bl16)"/>
    <g clip-path="url(#dnWin)">
      <rect x="${wx - wr}" y="${wy - wr}" width="${wr * 2}" height="${wr * 2}" fill="url(#dnNight)"/>
      ${stars(7, 26, wx - wr, wy - wr, wx + wr, wy + wr, "#dfe6ff")}
      <circle cx="${wx + 18}" cy="${wy - 16}" r="34" fill="#cfe0ff" opacity="0.25" filter="url(#bl8)"/>
      <circle cx="${wx + 18}" cy="${wy - 16}" r="19" fill="#f2f0ff"/>
      <circle cx="${wx + 12}" cy="${wy - 20}" r="4" fill="#d6d6f0"/><circle cx="${wx + 24}" cy="${wy - 8}" r="3" fill="#d6d6f0"/>
      <path d="M ${wx - wr} ${wy + 30} Q ${wx - 20} ${wy + 10} ${wx + 10} ${wy + 26} Q ${wx + 40} ${wy + 14} ${wx + wr} ${wy + 24} L ${wx + wr} ${wy + wr} L ${wx - wr} ${wy + wr} Z" fill="#1a2350"/>
      <path d="M ${wx - wr} ${wy + 42} Q ${wx} ${wy + 30} ${wx + wr} ${wy + 44} L ${wx + wr} ${wy + wr} L ${wx - wr} ${wy + wr} Z" fill="#121838"/>
    </g>
    <circle cx="${wx}" cy="${wy}" r="${wr}" fill="none" stroke="#4a2c1c" stroke-width="12"/>
    <circle cx="${wx}" cy="${wy}" r="${wr + 5}" fill="none" stroke="#2a180f" stroke-width="3"/>
    <line x1="${wx - wr}" y1="${wy}" x2="${wx + wr}" y2="${wy}" stroke="#4a2c1c" stroke-width="5"/>
    <line x1="${wx}" y1="${wy - wr}" x2="${wx}" y2="${wy + wr}" stroke="#4a2c1c" stroke-width="5"/>
    <path d="M ${wx - wr + 6} ${wy - 22} A ${wr - 6} ${wr - 6} 0 0 1 ${wx - 22} ${wy - wr + 6}" fill="none" stroke="#ffb866" stroke-width="2" opacity="0.5"/>
    <path d="M ${wx - 70} ${wy + wr + 6} L ${wx + 70} ${wy + wr + 6}" stroke="#5a3620" stroke-width="7" stroke-linecap="round"/>`;
  // Cool moonbeam falling across the floor.
  const beam = `<path d="M ${wx - 40} ${wy} L ${wx + 40} ${wy} L ${wx - 10} 270 L ${wx - 130} 270 Z" fill="#9db8ff" opacity="0.09" filter="url(#bl6)"/><ellipse cx="${wx - 70}" cy="262" rx="70" ry="10" fill="#9db8ff" opacity="0.1" filter="url(#bl6)"/>`;
  // Hanging lantern (rope from a ceiling beam), the warm key light.
  const lx = 600, ly = 118;
  const lantern = `<circle cx="${lx}" cy="${ly + 6}" r="150" fill="url(#dnWarm)"/>
    <line x1="${lx}" y1="0" x2="${lx}" y2="${ly - 22}" stroke="#2a1a14" stroke-width="2"/>
    <path d="M ${lx - 10} ${ly - 22} L ${lx + 10} ${ly - 22} L ${lx + 14} ${ly - 14} L ${lx - 14} ${ly - 14} Z" fill="#3a2418"/>
    <rect x="${lx - 13}" y="${ly - 14}" width="26" height="34" rx="6" fill="#ffd27a"/>
    <ellipse cx="${lx}" cy="${ly + 3}" rx="7" ry="10" fill="#fff4cf"/>
    <rect x="${lx - 13}" y="${ly - 14}" width="26" height="34" rx="6" fill="none" stroke="#3a2418" stroke-width="3"/>
    <line x1="${lx}" y1="${ly - 14}" x2="${lx}" y2="${ly + 20}" stroke="#3a2418" stroke-width="2"/>
    <path d="M ${lx - 14} ${ly + 20} L ${lx + 14} ${ly + 20} L ${lx + 8} ${ly + 27} L ${lx - 8} ${ly + 27} Z" fill="#3a2418"/>
    <circle cx="${lx}" cy="${ly + 3}" r="26" fill="#ffc86a" opacity="0.55" filter="url(#bl8)"/>`;
  // Shelves on the right wall with eggs + trophies.
  const sh = (y, x0, x1) => `<rect x="${x0}" y="${y}" width="${x1 - x0}" height="7" rx="2" fill="#6a4228"/><rect x="${x0}" y="${y + 7}" width="${x1 - x0}" height="4" fill="#2a170e" opacity="0.8"/>
    <path d="M ${x0 + 14} ${y + 11} l 0 12 l 10 -12 Z" fill="#3a2418"/><path d="M ${x1 - 14} ${y + 11} l 0 12 l -10 -12 Z" fill="#3a2418"/>`;
  const shelves = `${sh(124, 652, 780)}${sh(186, 640, 780)}
    ${egg(676, 110, 13, "#b49ad8", "#8a6fb8")}${egg(706, 112, 11, "#9fd6b0", "#6fae84")}${trophy(744, 104, 20, "#e7b24a")}
    ${trophy(664, 168, 17, "#b9c3d6")}${egg(698, 172, 13, "#e8b48a", "#c48a62")}${egg(728, 174, 11, "#8ec4e8", "#5e98c0")}${egg(756, 170, 14, "#e8a0c4", "#c07098")}`;
  // Floor rug + cushion pile.
  const floor = `<path d="M 0 236 Q 390 222 780 238 L 780 300 L 0 300 Z" fill="#24151a"/>
    <ellipse cx="530" cy="258" rx="230" ry="30" fill="#5a2a3a"/>
    <ellipse cx="530" cy="258" rx="230" ry="30" fill="none" stroke="#c88a4a" stroke-width="3" stroke-dasharray="10 7" opacity="0.6"/>
    <ellipse cx="530" cy="258" rx="200" ry="22" fill="none" stroke="#8a3e50" stroke-width="2"/>`;
  const cushion = (x, y, w, h, c) => `<ellipse cx="${x}" cy="${y + h * 0.7}" rx="${w}" ry="${h * 0.4}" fill="#000" opacity="0.35" filter="url(#bl4)"/>
    <path d="M ${x - w} ${y} Q ${x - w * 1.05} ${y - h} ${x} ${y - h} Q ${x + w * 1.05} ${y - h} ${x + w} ${y} Q ${x + w * 1.05} ${y + h * 0.8} ${x} ${y + h * 0.7} Q ${x - w * 1.05} ${y + h * 0.8} ${x - w} ${y} Z" fill="${c}" stroke="${shade(c, -0.55)}" stroke-width="2"/>
    <path d="M ${x - w * 0.6} ${y - h * 0.55} Q ${x} ${y - h * 0.8} ${x + w * 0.5} ${y - h * 0.55}" fill="none" stroke="${shade(c, 0.35)}" stroke-width="3" opacity="0.5" stroke-linecap="round"/>
    <circle cx="${x}" cy="${y - h * 0.05}" r="3" fill="${shade(c, -0.4)}"/>`;
  const pile = `${cushion(470, 246, 62, 26, "#8a4a6a")}${cushion(588, 250, 58, 22, "#c98a3a")}${cushion(532, 222, 44, 18, "#4a6a9a")}`;
  // Critters: sleeper on cushion, cheerer in front, one peeking from behind the pile, one on the shelf.
  const crit = `
    ${critter(470, 210, 26, FAM.frost, { acc: "crystal", mood: "sleepy", rim: "#ffc86a", rimSide: 1, tilt: -10 })}
    ${critter(538, 192, 20, FAM.spooky, { acc: "ears", mood: "happy", look: [-0.6, 0.2], rim: "#ffc86a", rimSide: 1 })}
    ${shadow(600, 264, 30, 0.55)}${critter(600, 232, 30, FAM.fire, { acc: "flame", mood: "cheer", rim: "#ffe0a0", rimSide: -1 })}
    ${shadow(676, 266, 22, 0.5)}${critter(676, 244, 22, FAM.sea, { acc: "fin", mood: "wow", look: [-0.7, -0.2], rim: "#ffc86a", rimSide: -1 })}
    ${critter(388, 248, 18, FAM.nature, { acc: "leaf", mood: "happy", look: [0.8, -0.4], rim: "#9db8ff", rimSide: -1 })}
    ${shadow(740, 268, 16, 0.5)}${critter(740, 252, 15, FAM.toybox, { acc: "propeller", mood: "sleepy", rim: "#ffc86a", rimSide: -1 })}`;
  // Little Zzz over the sleeper.
  const zz = `<g fill="none" stroke="#cfe0ff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" opacity="0.75">
    <path d="M 492 172 h 8 l -8 9 h 8"/><path d="M 506 156 h 6 l -6 7 h 6" opacity="0.7"/></g>`;
  // Left: dim tunnel arch, a dark chest and a tiny sleeping critter low in shadow.
  const left = `<path d="M 40 240 L 40 150 Q 40 96 100 96 Q 160 96 160 150 L 160 240 Z" fill="#0e0a18"/>
    <path d="M 40 240 L 40 150 Q 40 96 100 96 Q 160 96 160 150 L 160 240" fill="none" stroke="#3a2418" stroke-width="8"/>
    <rect x="210" y="206" width="70" height="40" rx="5" fill="#3a2418" stroke="#1a0e08" stroke-width="2"/><rect x="210" y="216" width="70" height="5" fill="#5a3a22"/>
    ${critter(250, 196, 13, FAM.cosmic, { acc: "antenna", mood: "sleepy", rim: "#ffc86a", rimSide: 1 })}`;
  // Ceiling beams.
  const beams = `<path d="M 0 0 L 780 0 L 780 14 Q 390 30 0 14 Z" fill="#2a180f"/>
    <rect x="520" y="0" width="16" height="70" fill="#2a180f"/><rect x="742" y="0" width="16" height="96" fill="#24140c"/>`;

  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${blurs()}
  <defs>
    <linearGradient id="dnWall" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1a1226"/><stop offset="0.5" stop-color="#3a2230"/><stop offset="0.8" stop-color="#4a2a28"/><stop offset="1" stop-color="#2e1a22"/></linearGradient>
    <linearGradient id="dnNight" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#141a48"/><stop offset="1" stop-color="#2e3a7a"/></linearGradient>
    <radialGradient id="dnWarm"><stop offset="0" stop-color="#ffb35a" stop-opacity="0.45"/><stop offset="0.5" stop-color="#ff9a4a" stop-opacity="0.14"/><stop offset="1" stop-color="#ff9a4a" stop-opacity="0"/></radialGradient>
    <linearGradient id="dnL" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#0D0F26" stop-opacity="0.8"/><stop offset="0.5" stop-color="#0D0F26" stop-opacity="0"/></linearGradient>
    <linearGradient id="dnT" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0D0F26" stop-opacity="0.55"/><stop offset="0.45" stop-color="#0D0F26" stop-opacity="0"/></linearGradient>
    <linearGradient id="dnB" x1="0" y1="0" x2="0" y2="1"><stop offset="0.74" stop-color="#0D0F26" stop-opacity="0"/><stop offset="1" stop-color="#0D0F26" stop-opacity="1"/></linearGradient>
  </defs>
  <rect width="${W}" height="${H}" fill="url(#dnWall)"/>
  ${roots}<ellipse cx="560" cy="200" rx="260" ry="110" fill="#ff9a4a" opacity="0.12" filter="url(#bl32)"/>${beams}${win}${beam}${shelves}${lantern}${floor}${left}${pile}${crit}${zz}
  ${motes(9, 16, 380, 120, 760, 250, ["#ffd27a", "#ffb35a", "#cfe0ff"])}
  ${sparkle(392, 50, 4, "#e6ecff", 0.6)}
  <rect width="${W}" height="${H}" fill="url(#dnL)"/>
  <rect width="${W}" height="${H}" fill="url(#dnT)"/>
  <rect width="${W}" height="${H}" fill="url(#dnB)"/>
  </svg>`;
}

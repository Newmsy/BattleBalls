// Nature habitat: a night forest glade. Dark canopy framing the top, slanted
// moonbeams falling onto a mossy stump stage, giant glowing mushrooms, ferns
// and fireflies. Signature light: cool mint moonbeams + firefly lime.
// Stage: a wide mossy stump at (200, 330).
import { blurs, critter, sky, motes, shade, rng, f } from "./_p.mjs";
import { W, H, SX, SY, fades, withHero } from "./_hab.mjs";

export const size = [W, H];

function mushroom(x, y, h, r, cap, o = 1, glowCol = "#9af0d0") {
  return `<g opacity="${o}">
    <ellipse cx="${x}" cy="${y - h}" rx="${r * 1.6}" ry="${r * 0.9}" fill="${glowCol}" opacity="0.22" filter="url(#bl16)"/>
    <path d="M ${x - r * 0.18} ${y} Q ${x - r * 0.26} ${y - h * 0.5} ${x - r * 0.14} ${y - h} L ${x + r * 0.14} ${y - h} Q ${x + r * 0.22} ${y - h * 0.5} ${x + r * 0.2} ${y} Z" fill="#9fb8ae"/>
    <path d="M ${x + r * 0.06} ${y} Q ${x + r * 0.14} ${y - h * 0.5} ${x + r * 0.08} ${y - h}" stroke="#6e8a84" stroke-width="${r * 0.08}" fill="none"/>
    <path d="M ${x - r} ${y - h + r * 0.12} Q ${x - r * 0.96} ${y - h - r * 0.76} ${x} ${y - h - r * 0.8} Q ${x + r * 0.96} ${y - h - r * 0.76} ${x + r} ${y - h + r * 0.12} Q ${x} ${y - h - r * 0.08} ${x - r} ${y - h + r * 0.12} Z" fill="${cap}" stroke="${shade(cap, -0.55)}" stroke-width="${r * 0.05}"/>
    <path d="M ${x - r * 0.9} ${y - h + r * 0.1} Q ${x} ${y - h - r * 0.06} ${x + r * 0.9} ${y - h + r * 0.1}" stroke="${glowCol}" stroke-width="${r * 0.08}" fill="none" opacity="0.8"/>
    ${[[-0.5, -0.45, 0.13], [0.1, -0.62, 0.1], [0.5, -0.36, 0.12], [-0.12, -0.3, 0.08]].map(([dx, dy, rr]) => `<circle cx="${f(x + dx * r)}" cy="${f(y - h + dy * r)}" r="${f(rr * r)}" fill="${shade(cap, 0.55)}" opacity="0.85"/>`).join("")}
  </g>`;
}

function fern(x, y, s, rot, col = "#1f4a3a", o = 1) {
  let leaves = "";
  for (let k = 0; k < 7; k++) {
    const t = k / 7, px = t * 70, py = -Math.sin(t * 1.6) * 34, l = 24 * (1 - t * 0.6);
    leaves += `<path d="M ${f(px)} ${f(py)} q ${f(l * 0.3)} ${f(-l)} ${f(l * 0.9)} ${f(-l * 0.9)} q ${f(-l * 0.3)} ${f(l * 0.5)} ${f(-l * 0.9)} ${f(l * 0.9)} Z" fill="${col}"/>
      <path d="M ${f(px)} ${f(py)} q ${f(l * 0.6)} ${f(l * 0.2)} ${f(l * 0.9)} ${f(l * 0.8)} q ${f(-l * 0.6)} 0 ${f(-l * 0.9)} ${f(-l * 0.8)} Z" fill="${col}"/>`;
  }
  return `<g transform="translate(${x} ${y}) rotate(${rot}) scale(${s})" opacity="${o}">
    <path d="M 0 0 Q 36 -34 72 -20" fill="none" stroke="${col}" stroke-width="4" stroke-linecap="round"/>${leaves}</g>`;
}

function scene() {
  const R = rng(71);
  // Far tree trunks in blue haze.
  let trunks = "";
  [[300, 20, "#173a44", 0.8], [380, 26, "#14323e", 0.85], [470, 18, "#173a44", 0.7], [560, 30, "#122c38", 0.9], [650, 22, "#14323e", 0.8], [730, 34, "#10283a", 0.9], [120, 22, "#173a44", 0.7]].forEach(([x, w, c, o]) => {
    trunks += `<path d="M ${x - w / 2} 330 Q ${x - w * 0.3} 200 ${x - w * 0.4} 0 L ${x + w * 0.4} 0 Q ${x + w * 0.3} 200 ${x + w / 2} 330 Z" fill="${c}" opacity="${o}"/>`;
  });
  // Nearer big trunks framing left and right.
  const bigTrunks = `
    <path d="M -10 460 L -10 0 L 54 0 Q 40 120 50 240 Q 60 330 90 400 Q 70 420 -10 460 Z" fill="#0d1f26"/>
    <path d="M 40 60 Q 34 140 44 220" stroke="#2a5a5a" stroke-width="3" fill="none" opacity="0.5"/>
    <path d="M 610 460 Q 640 380 640 260 Q 636 120 620 0 L 720 0 Q 704 140 708 260 Q 712 380 740 460 Z" fill="#0c1c24"/>
    <path d="M 636 40 Q 646 160 642 300" stroke="#2a5a5a" stroke-width="3" fill="none" opacity="0.35"/>`;
  // Canopy: dark leaf clumps along the top with gaps.
  let canopy = "";
  for (let k = 0; k < 34; k++) {
    const x = R() * 820 - 20, y = R() * 70 - 20, r = 30 + R() * 46;
    if (x > 150 && x < 330 && y > 10) continue; // gap for the moonbeams
    canopy += `<circle cx="${f(x)}" cy="${f(y)}" r="${f(r)}" fill="${k % 3 ? "#0c1e24" : "#10282c"}"/>`;
  }
  canopy += `<path d="M 0 0 L 780 0 L 780 30 Q 600 60 460 40 Q 360 20 330 10 L 150 10 Q 80 50 0 70 Z" fill="#0b1a22"/>`;
  // Moonbeams through the gap, falling onto the stage.
  const beams = `
    <path d="M 170 0 L 250 0 L 330 340 L 150 340 Z" fill="url(#hnBeam)" opacity="0.55"/>
    <path d="M 260 0 L 300 0 L 360 300 L 290 300 Z" fill="url(#hnBeam)" opacity="0.35"/>
    <path d="M 120 0 L 150 0 L 180 260 L 130 260 Z" fill="url(#hnBeam)" opacity="0.25"/>
    <circle cx="230" cy="6" r="60" fill="#d6fff0" opacity="0.25" filter="url(#bl24)"/>`;
  // Forest floor layers.
  const floor = `
    <path d="M 0 320 Q 200 300 420 310 Q 600 316 780 300 L 780 460 L 0 460 Z" fill="#12302e"/>
    <path d="M 0 352 Q 180 340 360 350 Q 520 358 780 340 L 780 460 L 0 460 Z" fill="#0f2626"/>`;
  // Giant mushrooms: one tall cluster right of the stage (mid), dimmer ones far right.
  const shrooms = `
    ${mushroom(470, 316, 90, 46, "#3f7a86", 0.75)}
    ${mushroom(520, 318, 50, 26, "#4a8a7a", 0.65)}
    ${mushroom(700, 330, 70, 36, "#356a78", 0.55)}
    ${mushroom(380, 372, 110, 44, "#4a9a8a")}
    ${mushroom(418, 378, 52, 22, "#5aa888")}
    ${mushroom(26, 396, 120, 52, "#3f8a86")}`;
  // Ferns along the bottom and sides.
  const ferns = `
    ${fern(-10, 420, 1.3, -30, "#16443a")}${fern(70, 430, 1.1, -60, "#1a4e40")}
    ${fern(330, 420, 1.0, -20, "#16443a")}${fern(430, 430, 1.2, -150, "#133a32")}
    ${fern(-20, 340, 0.8, -30, "#1a4a3c", 0.8)}${fern(520, 340, 0.8, -160, "#123630", 0.7)}`;
  // Stage: a wide mossy tree stump in the moonbeam pool.
  const stage = `
    <ellipse cx="${SX + 20}" cy="${SY + 4}" rx="200" ry="50" fill="#b6ffe0" opacity="0.14" filter="url(#bl24)"/>
    <path d="M ${SX - 132} ${SY + 50} Q ${SX - 118} ${SY + 30} ${SX - 112} ${SY} L ${SX + 112} ${SY} Q ${SX + 118} ${SY + 30} ${SX + 134} ${SY + 50} Q ${SX} ${SY + 70} ${SX - 132} ${SY + 50} Z" fill="#3a2a22"/>
    ${[-80, -40, 0, 40, 80].map((dx) => `<path d="M ${SX + dx} ${SY + 22} L ${SX + dx * 1.1} ${SY + 56}" stroke="#241812" stroke-width="3" opacity="0.7"/>`).join("")}
    <path d="M ${SX - 132} ${SY + 50} Q ${SX - 160} ${SY + 60} ${SX - 176} ${SY + 70} M ${SX + 134} ${SY + 50} Q ${SX + 160} ${SY + 56} ${SX + 180} ${SY + 70}" stroke="#3a2a22" stroke-width="10" stroke-linecap="round" fill="none"/>
    <ellipse cx="${SX}" cy="${SY}" rx="114" ry="24" fill="#8a6a4a" stroke="#241812" stroke-width="3"/>
    <ellipse cx="${SX}" cy="${SY}" rx="84" ry="17" fill="none" stroke="#6a4e36" stroke-width="2"/>
    <ellipse cx="${SX}" cy="${SY}" rx="52" ry="10" fill="none" stroke="#6a4e36" stroke-width="2"/>
    <ellipse cx="${SX}" cy="${SY}" rx="22" ry="4" fill="none" stroke="#6a4e36" stroke-width="2"/>
    <path d="M ${SX - 114} ${SY} Q ${SX - 100} ${SY + 22} ${SX - 50} ${SY + 24} Q ${SX - 60} ${SY + 36} ${SX - 100} ${SY + 34} Q ${SX - 120} ${SY + 26} ${SX - 114} ${SY} Z" fill="#3f8a4a"/>
    <path d="M ${SX + 114} ${SY} Q ${SX + 104} ${SY + 20} ${SX + 70} ${SY + 22} Q ${SX + 80} ${SY + 34} ${SX + 108} ${SY + 28} Z" fill="#3f8a4a"/>
    <path d="M ${SX - 100} ${SY - 10} Q ${SX - 60} ${SY - 22} ${SX - 20} ${SY - 22}" stroke="#6fd07a" stroke-width="5" stroke-linecap="round" fill="none" opacity="0.7"/>
    <ellipse cx="${SX + 20}" cy="${SY - 4}" rx="80" ry="12" fill="#d6fff0" opacity="0.3" filter="url(#bl8)"/>
    <ellipse cx="${SX}" cy="${SY + 66}" rx="150" ry="10" fill="#000" opacity="0.4" filter="url(#bl6)"/>`;
  // Small nature critters far back on the forest floor and peeking from a fern.
  const bg = `${critter(548, 304, 8, "#5fd068", { acc: "leaf", mood: "sleepy", rim: "#b6ffe0", rimSide: -1 })}
    ${critter(408, 300, 7, "#6fd878", { acc: "leaf", mood: "happy", look: [-0.5, 0], rim: "#b6ffe0", rimSide: -1 })}`;
  // Fireflies.
  let ff = "";
  for (let k = 0; k < 26; k++) {
    let x = R() * 780, y = 60 + R() * 330;
    if (Math.hypot(x - SX, y - 250) < 135) continue;
    const s = 1.4 + R() * 2;
    ff += `<circle cx="${f(x)}" cy="${f(y)}" r="${f(s * 4)}" fill="#d8ff6a" opacity="${f(x > 440 ? 0.18 : 0.3)}" filter="url(#bl4)"/><circle cx="${f(x)}" cy="${f(y)}" r="${f(s)}" fill="#f4ffb0" opacity="${f(x > 440 ? 0.6 : 0.95)}"/>`;
  }

  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${blurs()}
  <defs>
    <linearGradient id="hnSky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0c1a2a"/><stop offset="0.6" stop-color="#16384a"/><stop offset="1" stop-color="#1e4a4a"/></linearGradient>
    <linearGradient id="hnBeam" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#e6fff4" stop-opacity="0.7"/><stop offset="0.7" stop-color="#b6ffe0" stop-opacity="0.25"/><stop offset="1" stop-color="#b6ffe0" stop-opacity="0"/></linearGradient>
  </defs>
  <rect width="${W}" height="${H}" fill="url(#hnSky)"/>
  ${sky(83, 26, 150, 0, 340, 60)}
  <ellipse cx="400" cy="280" rx="400" ry="70" fill="#4ab0a0" opacity="0.14" filter="url(#bl24)"/>
  ${trunks}${floor}${bg}${bigTrunks}${canopy}${beams}
  ${shrooms}${stage}${ferns}
  ${motes(19, 14, 140, 40, 340, 340, ["#e6fff4", "#b6ffe0"])}
  ${ff}
  ${fades("hn", { right: 0.42 })}
  </svg>`;
}

export const many = {
  hab_nature: scene,
  hab_nature_ctx: withHero(scene, "#5fd068", "leaf", "#b6ffe0"),
};
export default scene;

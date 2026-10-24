// Tech habitat: a night rooftop workshop above a little robot town. Boxy
// buildings with round windows, antennas with signal lights, a water tank,
// a satellite dish, cables and pipes. Matte steel palette; signature light:
// cool cyan signal glow. Stage: a round riveted metal hatch at (200, 330).
import { blurs, critter, sky, motes, shade, rng, f, stringLights } from "./_p.mjs";
import { W, H, SX, SY, fades, withHero } from "./_hab.mjs";

export const size = [W, H];

const CY = "#5ae0ff";

function building(x, y, w, h, col, R, { win = 0.5, roof = "flat", o = 1, warm = 0.25 } = {}) {
  let s = `<rect x="${x}" y="${y}" width="${w}" height="${h + 200}" fill="${col}"/>`;
  s += `<rect x="${x}" y="${y}" width="${w}" height="4" fill="${shade(col, 0.25)}"/>`;
  if (roof === "dome") s += `<path d="M ${x + w * 0.15} ${y} A ${w * 0.35} ${w * 0.3} 0 0 1 ${x + w * 0.85} ${y} Z" fill="${shade(col, 0.1)}"/>`;
  if (roof === "antenna") s += `<path d="M ${x + w * 0.5} ${y} L ${x + w * 0.5} ${y - 34}" stroke="${shade(col, 0.15)}" stroke-width="2.5"/>
    <circle cx="${x + w * 0.5}" cy="${y - 36}" r="8" fill="#ff5a6e" opacity="0.35" filter="url(#bl4)"/><circle cx="${x + w * 0.5}" cy="${y - 36}" r="2.6" fill="#ff8a8a"/>`;
  const cols = Math.max(1, Math.floor(w / 18)), rows = Math.max(1, Math.floor(h / 22));
  for (let i = 0; i < cols; i++) for (let j = 0; j < rows; j++) {
    if (R() > win) continue;
    const wx = x + (w / cols) * (i + 0.5), wy = y + 14 + j * 22;
    const c = R() < warm ? "#ffc85a" : CY;
    s += `<circle cx="${f(wx)}" cy="${f(wy)}" r="3.4" fill="${c}" opacity="${f(0.45 + R() * 0.35)}"/>`;
  }
  return `<g opacity="${o}">${s}</g>`;
}

function scene() {
  const R = rng(113);
  // Far skyline (hazy).
  let far = "";
  let x = -10;
  while (x < 790) {
    const w = 30 + R() * 50, h = 60 + R() * 90;
    far += building(x, 300 - h, w, h, "#1c2444", R, { win: x > 420 ? 0.14 : 0.24, roof: R() < 0.3 ? "antenna" : R() < 0.5 ? "dome" : "flat", o: 0.9, warm: 0.15 });
    x += w + 4 + R() * 10;
  }
  // Mid buildings (bigger, darker) on both sides.
  const mid = `
    ${building(340, 210, 70, 160, "#232c50", R, { win: 0.45, roof: "antenna" })}
    ${building(416, 240, 90, 130, "#1e2648", R, { win: 0.22, roof: "dome" })}
    ${building(520, 180, 80, 190, "#1a2140", R, { win: 0.18, roof: "antenna", warm: 0.4 })}
    ${building(610, 230, 100, 140, "#182040", R, { win: 0.16 })}
    ${building(-20, 230, 60, 140, "#232c50", R, { win: 0.4, roof: "dome" })}`;
  // Water tank on the mid roof + satellite dish (right, dim).
  const props = `
    <g opacity="0.85">
      <path d="M 432 240 L 436 206 M 476 240 L 472 206" stroke="#141a34" stroke-width="3"/>
      <rect x="428" y="170" width="52" height="38" rx="6" fill="#2a3458"/>
      <path d="M 424 172 Q 454 152 484 172 Z" fill="#323e66"/>
      <path d="M 432 186 L 476 186 M 432 198 L 476 198" stroke="#1a2244" stroke-width="2"/>
    </g>
    <g opacity="0.7">
      <path d="M 650 230 L 660 200" stroke="#141a34" stroke-width="4"/>
      <path d="M 636 206 A 30 30 0 0 0 690 186 Z" fill="#2a3458" transform="rotate(-20 660 200)"/>
      <circle cx="668" cy="190" r="3" fill="${CY}"/>
    </g>`;
  // Moon-ish big round clock/sign? Keep sky simple: a small moon, drifting blimp.
  const skyBits = `
    <circle cx="470" cy="96" r="20" fill="#d6e4ff" opacity="0.85"/><circle cx="470" cy="96" r="50" fill="#9ab8ff" opacity="0.2" filter="url(#bl16)"/>
    <g opacity="0.75"><ellipse cx="640" cy="70" rx="46" ry="15" fill="#2c3660"/><rect x="628" y="82" width="24" height="7" rx="3" fill="#232c50"/>
      <circle cx="620" cy="70" r="2.4" fill="${CY}"/><circle cx="636" cy="70" r="2.4" fill="${CY}"/><circle cx="652" cy="70" r="2.4" fill="#ffc85a"/>
      <path d="M 684 70 L 696 62 L 696 78 Z" fill="#232c50"/></g>`;
  // Cables with little lamps across the upper left (outside the reserved zone).
  const cables = stringLights(-10, 26, 400, 44, 6, 11, [CY, "#ffc85a", CY], 4);
  // Rooftop deck (foreground floor) with a low railing and pipes.
  const deck = `
    <path d="M -10 330 L 790 320 L 790 460 L -10 460 Z" fill="#20283f"/>
    <path d="M -10 330 L 790 320" stroke="#3a4668" stroke-width="2"/>
    ${Array.from({ length: 12 }, (_, k) => `<path d="M ${-40 + k * 80} 460 L ${k * 70} 328" stroke="#1a2134" stroke-width="2"/>`).join("")}
    <path d="M 0 300 L 330 296 M 420 294 L 790 290" stroke="#2c3656" stroke-width="3"/>
    ${[10, 60, 110, 300, 440, 500, 560, 620, 680, 740].map((px) => `<path d="M ${px} ${px < 400 ? 300 : 293} L ${px} ${px < 400 ? 330 : 322}" stroke="#2c3656" stroke-width="3"/>`).join("")}
    <path d="M 440 380 Q 470 360 520 362 L 780 362" stroke="#2e3a5c" stroke-width="10" fill="none"/>
    <path d="M 440 380 Q 470 360 520 362 L 780 362" stroke="#46557e" stroke-width="2" fill="none" transform="translate(0 -3)"/>
    <rect x="560" y="354" width="8" height="16" rx="2" fill="#3a4668"/><rect x="680" y="354" width="8" height="16" rx="2" fill="#3a4668"/>`;
  // Workshop clutter: crates and a toolbox left; vent stack right of stage.
  const clutter = `
    <rect x="-6" y="346" width="56" height="44" rx="4" fill="#2e3a5c" stroke="#121830" stroke-width="2.5"/>
    <path d="M -6 358 L 50 358" stroke="#121830" stroke-width="2"/>
    <rect x="6" y="320" width="36" height="28" rx="3" fill="#3a4870" stroke="#121830" stroke-width="2.5"/>
    <circle cx="24" cy="334" r="4" fill="${CY}" opacity="0.8"/>
    <path d="M 352 380 L 352 300 Q 352 290 362 290 L 384 290 Q 394 290 394 300 L 394 380 Z" fill="#2e3a5c" stroke="#121830" stroke-width="2.5"/>
    <path d="M 346 292 L 400 292 L 396 280 L 350 280 Z" fill="#3a4870" stroke="#121830" stroke-width="2.5"/>
    ${[310, 324, 338, 352].map((y) => `<path d="M 358 ${y} L 388 ${y}" stroke="#121830" stroke-width="2.5"/>`).join("")}
    <circle cx="373" cy="270" r="12" fill="#9ab8d8" opacity="0.12" filter="url(#bl6)"/>
    <path d="M 366 274 q -4 -14 6 -22 q 10 -8 4 -22" stroke="#9ab8d8" stroke-width="5" fill="none" opacity="0.15" stroke-linecap="round" filter="url(#bl3)"/>`;
  // Stage: round riveted hatch with a cyan ring light.
  const rivets = Array.from({ length: 16 }, (_, k) => {
    const a = (k / 16) * Math.PI * 2;
    return `<circle cx="${f(SX + Math.cos(a) * 112)}" cy="${f(SY + Math.sin(a) * 22)}" r="2.6" fill="#8a9ac0"/>`;
  }).join("");
  const stage = `
    <ellipse cx="${SX}" cy="${SY}" rx="200" ry="50" fill="${CY}" opacity="0.1" filter="url(#bl24)"/>
    <path d="M ${SX - 126} ${SY} L ${SX - 126} ${SY + 22} Q ${SX} ${SY + 56} ${SX + 126} ${SY + 22} L ${SX + 126} ${SY} Z" fill="#2a3456" stroke="#121830" stroke-width="3"/>

    <ellipse cx="${SX}" cy="${SY}" rx="126" ry="26" fill="#4a5680" stroke="#121830" stroke-width="3"/>
    <ellipse cx="${SX}" cy="${SY}" rx="100" ry="19" fill="#3c4870" stroke="#2a3456" stroke-width="2"/>
    ${rivets}
    <path d="M ${SX - 124} ${SY + 14} Q ${SX} ${SY + 48} ${SX + 124} ${SY + 14}" stroke="${CY}" stroke-width="10" fill="none" opacity="0.4" filter="url(#bl4)"/>
    <path d="M ${SX - 124} ${SY + 14} Q ${SX} ${SY + 48} ${SX + 124} ${SY + 14}" stroke="${CY}" stroke-width="3" fill="none"/>
    <path d="M ${SX - 124} ${SY + 14} Q ${SX} ${SY + 48} ${SX + 124} ${SY + 14}" stroke="#e6fbff" stroke-width="1" fill="none" opacity="0.8"/>
    <path d="M ${SX - 70} ${SY - 4} L ${SX + 70} ${SY - 4} M ${SX - 80} ${SY + 4} L ${SX + 80} ${SY + 4}" stroke="#32406a" stroke-width="2"/>
    <path d="M ${SX - 94} ${SY - 8} Q ${SX} ${SY - 24} ${SX + 94} ${SY - 8}" stroke="#a8c0e8" stroke-width="2" fill="none" opacity="0.5"/>
    <ellipse cx="${SX + 4}" cy="${SY - 4}" rx="70" ry="9" fill="#bfe8ff" opacity="0.18" filter="url(#bl8)"/>
    <ellipse cx="${SX}" cy="${SY + 40}" rx="150" ry="12" fill="#000" opacity="0.35" filter="url(#bl6)"/>`;
  // Little tech critters on far rooftops.
  const bg = `${critter(470, 228, 8, "#9aa8c7", { acc: "antenna", mood: "happy", look: [-0.5, 0], rim: CY, rimSide: -1 })}
    ${critter(560, 168, 6.5, "#9aa8c7", { acc: "antenna", mood: "sleepy", rim: CY, rimSide: -1 })}`;

  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${blurs()}
  <defs>
    <linearGradient id="htSky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0a0e26"/><stop offset="0.6" stop-color="#16204a"/><stop offset="1" stop-color="#1e3a5a"/></linearGradient>
  </defs>
  <rect width="${W}" height="${H}" fill="url(#htSky)"/>
  ${sky(131, 60, 0, 0, 780, 200)}
  ${skyBits}
  <ellipse cx="400" cy="290" rx="420" ry="60" fill="${CY}" opacity="0.1" filter="url(#bl24)"/>
  ${far}${mid}${props}${bg}${cables}
  ${deck}${clutter}${stage}
  ${motes(37, 16, 0, 120, 780, 400, [CY, "#bfe8ff", "#ffc85a"])}
  ${fades("ht", { right: 0.42 })}
  </svg>`;
}

export const many = {
  hab_tech: scene,
  hab_tech_ctx: withHero(scene, "#9aa8c7", "antenna", CY),
};
export default scene;

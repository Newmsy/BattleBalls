// Fire habitat: an ember canyon forge. Columnar basalt cliffs on both sides,
// lava rivulets running down the rock, a glowing river in the canyon floor
// receding to a far forge-glow, ember motes against a dark smoky sky.
// Stage: a flat anvil-like basalt rock at (200, 330), lit from below.
import { blurs, critter, shadow, sky, motes, shade, rng, f } from "./_p.mjs";
import { W, H, SX, SY, fades, withHero } from "./_hab.mjs";

export const size = [W, H];

// A cluster of basalt columns: hex-topped prisms.
function columns(x0, baseY, n, w, hs, col, top, R, rimCol = null) {
  let s = "";
  for (let k = 0; k < n; k++) {
    const x = x0 + k * w, h = hs[k % hs.length] + R() * 14;
    const y = baseY - h;
    s += `<path d="M ${f(x)} ${f(baseY)} L ${f(x)} ${f(y)} L ${f(x + w * 0.5)} ${f(y - w * 0.18)} L ${f(x + w)} ${f(y)} L ${f(x + w)} ${f(baseY)} Z" fill="${k % 2 ? col : shade(col, -0.12)}" stroke="#0e0610" stroke-width="2"/>
      <path d="M ${f(x)} ${f(y)} L ${f(x + w * 0.5)} ${f(y - w * 0.18)} L ${f(x + w)} ${f(y)} L ${f(x + w * 0.5)} ${f(y + w * 0.18)} Z" fill="${top}"/>`;
    if (rimCol) s += `<path d="M ${f(x + w - 1.5)} ${f(y + 2)} L ${f(x + w - 1.5)} ${f(baseY)}" stroke="${rimCol}" stroke-width="2" opacity="0.45"/>`;
  }
  return s;
}

function rivulet(d, w = 3) {
  return `<path d="${d}" fill="none" stroke="#ff6a3d" stroke-width="${w * 2.4}" opacity="0.35" filter="url(#bl4)" stroke-linecap="round"/>
    <path d="${d}" fill="none" stroke="#ff8a3d" stroke-width="${w}" stroke-linecap="round"/>
    <path d="${d}" fill="none" stroke="#ffd36b" stroke-width="${w * 0.4}" stroke-linecap="round"/>`;
}

function scene() {
  const R = rng(53);
  // Far forge glow at the canyon's end.
  const glow = `
    <ellipse cx="300" cy="250" rx="260" ry="120" fill="#ff5a2a" opacity="0.28" filter="url(#bl40)"/>
    <ellipse cx="310" cy="262" rx="120" ry="40" fill="#ffb347" opacity="0.4" filter="url(#bl24)"/>`;
  // Smoke wisps drifting in the sky.
  let smoke = "";
  for (let k = 0; k < 10; k++) {
    smoke += `<ellipse cx="${f(80 + R() * 680)}" cy="${f(40 + R() * 120)}" rx="${f(60 + R() * 80)}" ry="${f(12 + R() * 10)}" fill="#3a1a36" opacity="${f(0.4 + R() * 0.3)}" filter="url(#bl8)"/>`;
  }
  // Far canyon walls (hazy, warm).
  const farWalls = `
    <path d="M 160 280 L 170 200 L 200 190 L 220 150 L 250 160 L 270 210 L 300 268 Z" fill="#4a1e34"/>
    <path d="M 330 268 L 360 200 L 380 176 L 420 170 L 440 130 L 480 140 L 500 200 L 520 280 Z" fill="#3e1a32"/>
    ${columns(170, 306, 6, 18, [74, 110, 66, 92, 50, 84], "#4e2236", "#6e2c3a", R)}
    ${columns(370, 306, 8, 20, [110, 150, 96, 128, 140, 84, 116, 70], "#3c1a30", "#5a2436", R)}`;
  // Canyon floor + lava river from the far glow to the near right.
  const floor = `
    <path d="M 0 300 L 780 290 L 780 460 L 0 460 Z" fill="#24101e"/>
    <path d="M 296 276 Q 330 286 318 298 Q 300 318 360 334 Q 450 356 520 372 Q 620 396 680 460 L 600 460 Q 560 410 470 386 Q 380 362 320 344 Q 268 326 288 300 Q 296 288 288 278 Z" fill="url(#hfLava)"/>
    <path d="M 300 290 Q 290 312 330 330 Q 420 356 500 378" fill="none" stroke="#fff0b0" stroke-width="1.6" opacity="0.6" stroke-linecap="round"/>
    <ellipse cx="420" cy="360" rx="160" ry="30" fill="#ff6a3d" opacity="0.22" filter="url(#bl16)"/>`;
  // Crust plates on the river.
  let crust = "";
  for (let k = 0; k < 14; k++) {
    const t = R(), x = 310 + t * 330 + (R() - 0.5) * 30, y = 300 + t * 120, s = 4 + t * 10;
    crust += `<ellipse cx="${f(x)}" cy="${f(y)}" rx="${f(s * 1.6)}" ry="${f(s * 0.5)}" fill="#4a1a26" opacity="0.75"/>`;
  }
  // Near cliffs: left edge tall wall, right side tall dim wall.
  const leftCliff = `
    <path d="M -10 460 L -10 40 L 30 30 L 60 60 L 70 130 L 96 200 L 100 300 L 120 400 L 110 460 Z" fill="#1c0c1a"/>
    ${columns(-10, 420, 5, 22, [330, 380, 300, 260, 200], "#24101e", "#3a1626", R, "#ff8a3d")}
    ${rivulet("M 58 120 Q 52 170 62 210 Q 72 250 60 300 Q 52 340 66 400", 2.6)}
    ${rivulet("M 30 190 Q 36 230 28 270", 1.6)}`;
  const rightCliff = `
    <path d="M 560 460 L 580 300 L 600 220 L 640 120 L 690 60 L 780 30 L 790 460 Z" fill="#1a0b18"/>
    ${columns(600, 470, 9, 22, [260, 330, 370, 410, 390, 430], "#1e0e1c", "#2e1426", R)}
    ${rivulet("M 668 150 Q 660 200 672 240 Q 684 280 670 330", 2)}`;
  // Hanging chains + a far forge silhouette (hammer arm) in the canyon end, small.
  const forge = `
    <path d="M 286 270 L 286 232 L 330 232 L 330 270 Z" fill="#2a1022"/>
    <path d="M 280 232 L 336 232 L 330 222 L 286 222 Z" fill="#2a1022"/>
    <rect x="300" y="246" width="16" height="16" rx="3" fill="#ffd36b"/>
    <rect x="296" y="242" width="24" height="24" rx="5" fill="#ffb347" opacity="0.45" filter="url(#bl4)"/>
    <path d="M 304 222 L 304 196 L 316 196 L 316 222" fill="#2a1022"/>
    <path d="M 302 196 L 318 196 L 322 186 L 298 186 Z" fill="#2a1022"/>`;
  // Small fire critters far down the canyon.
  const bg = `
    ${critter(372, 300, 8, "#ff6a3d", { acc: "flame", mood: "happy", look: [-0.4, 0], rim: "#ffd36b", rimSide: -1 })}
    ${critter(540, 336, 9, "#ff7a4d", { acc: "flame", mood: "determined", look: [-0.6, 0], rim: "#ffd36b", rimSide: -1 })}`;
  // Stage: anvil rock with a flat top, glowing seams and underlight.
  const stage = `
    <ellipse cx="${SX}" cy="${SY}" rx="190" ry="56" fill="#ff7a3d" opacity="0.16" filter="url(#bl24)"/>
    <path d="M ${SX - 70} ${SY + 70} L ${SX - 54} ${SY + 22} L ${SX + 54} ${SY + 22} L ${SX + 76} ${SY + 70} Z" fill="#1c0c18"/>
    <path d="M ${SX - 126} ${SY - 4} L ${SX - 104} ${SY - 14} L ${SX + 108} ${SY - 14} L ${SX + 130} ${SY - 2} L ${SX + 120} ${SY + 16} Q ${SX + 70} ${SY + 22} ${SX + 54} ${SY + 30} L ${SX - 54} ${SY + 30} Q ${SX - 80} ${SY + 22} ${SX - 132} ${SY + 14} Z" fill="#2e1626" stroke="#0e0610" stroke-width="3" stroke-linejoin="round"/>
    <path d="M ${SX - 126} ${SY - 4} L ${SX - 104} ${SY - 14} L ${SX + 108} ${SY - 14} L ${SX + 130} ${SY - 2} L ${SX + 100} ${SY + 4} L ${SX - 100} ${SY + 4} Z" fill="#4a2434"/>
    <path d="M ${SX - 104} ${SY - 14} L ${SX + 108} ${SY - 14}" stroke="#ffb347" stroke-width="2" opacity="0.55"/>
    <ellipse cx="${SX}" cy="${SY - 6}" rx="90" ry="9" fill="#ffb347" opacity="0.25" filter="url(#bl6)"/>
    ${rivulet(`M ${SX - 80} ${SY + 8} l 10 8 l -4 8 l 8 6`, 1.6)}
    ${rivulet(`M ${SX + 60} ${SY + 6} l -6 10 l 8 8`, 1.6)}
    ${rivulet(`M ${SX - 10} ${SY + 24} l 4 14 l -6 14 l 4 12`, 1.8)}
    <ellipse cx="${SX}" cy="${SY + 74}" rx="150" ry="14" fill="#ff5a2a" opacity="0.2" filter="url(#bl12)"/>`;
  // Foreground rocks and lava pool glow at the front left.
  const front = `
    <path d="M 100 460 L 120 400 L 170 386 L 240 392 L 300 404 L 340 430 L 360 460 Z" fill="#1a0a16"/>
`;

  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${blurs()}
  <defs>
    <linearGradient id="hfSky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0e0a20"/><stop offset="0.45" stop-color="#2a1030"/><stop offset="0.75" stop-color="#5a1c30"/><stop offset="1" stop-color="#7a2a2a"/></linearGradient>
    <linearGradient id="hfLava" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#ffd36b"/><stop offset="0.35" stop-color="#ff8a3d"/><stop offset="0.75" stop-color="#d8442a"/><stop offset="1" stop-color="#5a1430"/></linearGradient>
  </defs>
  <rect width="${W}" height="${H}" fill="url(#hfSky)"/>
  ${sky(61, 40, 0, 0, 780, 130)}
  ${smoke}${glow}${farWalls}${forge}${floor}${crust}${bg}
  ${rightCliff}${leftCliff}
  ${stage}${front}
  ${motes(7, 40, 0, 40, 780, 420, ["#ffd36b", "#ff8a3d", "#ffb347"])}
  ${fades("hf", { right: 0.45 })}
  </svg>`;
}

export const many = {
  hab_fire: scene,
  hab_fire_ctx: withHero(scene, "#ff6a3d", "flame", "#ffd36b"),
};
export default scene;

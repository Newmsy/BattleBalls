// Home, Versus door header band (a strip of this scene): inside a night colosseum. Spotlights sweep down on the arena
// floor where two critters square off, a spark between them; a packed crowd
// of little round heads in the stands, and a ghost drifting over the rim for
// Ghost Arena. Magenta/violet palette, calm on the left for the title.
import { blurs, rng, stringLights, sparkle } from "./_shop_charge_pad_glow_chest_parts.mjs";
import { critter, shadow, sky, motes } from "./_banner_parts.mjs";
import { shade } from "../../brand/parts.mjs";

const f = (n) => (+n).toFixed(1);

export const size = [720, 200];
export const dir = "game/ui/home_art";
const W = 720, H = 340;

function scene({ band = false } = {}) {
  const R = rng(21);
  // Stands: three tiers of crowd heads in an arc.
  let crowd = "";
  const heads = ["#7b77ff", "#ff7ac8", "#5fd068", "#3fa9f5", "#ffc93c", "#b07cff", "#ff6a3d", "#8fe6ff"];
  for (let row = 0; row < 4; row++) {
    const y0 = 118 + row * 26;
    for (let x = -10; x < 740; x += 17 + row * 2) {
      const y = y0 + Math.pow((x - 470) / 470, 2) * 26 + R() * 3;
      const c = heads[Math.floor(R() * heads.length)];
      const r = 7 + row * 1.4;
      crowd += `<circle cx="${f(x + R() * 6)}" cy="${f(y)}" r="${f(r)}" fill="${shade(c, -0.74 + row * 0.05)}"/>`;
      if (R() < 0.12) crowd += `<line x1="${f(x)}" y1="${f(y - r)}" x2="${f(x + 4)}" y2="${f(y - r - 12)}" stroke="${shade(c, -0.5)}" stroke-width="3" stroke-linecap="round"/>`;
    }
    crowd += `<path d="M -10 ${y0 + 14} Q 470 ${y0 - 14} 740 ${y0 + 20}" stroke="#1a0f30" stroke-width="7" fill="none"/>`;
  }
  // Spotlight beams converging on the floor.
  const beams = [[120, -10, 430], [360, -10, 470], [700, -10, 520]].map(([x, y, tx]) =>
    `<path d="M ${x - 10} ${y} L ${x + 10} ${y} L ${tx + 70} 300 L ${tx - 70} 300 Z" fill="#ffd0f2" opacity="0.08"/>`).join("");
  // Arena floor: an elliptical ring with a glowing rim.
  const fx = 470, fy = 286;
  const floor = `
    <ellipse cx="${fx}" cy="${fy + 6}" rx="300" ry="62" fill="#120a24"/>
    <ellipse cx="${fx}" cy="${fy}" rx="290" ry="56" fill="url(#vaFloor)"/>
    <ellipse cx="${fx}" cy="${fy}" rx="290" ry="56" fill="none" stroke="#ff4fd8" stroke-width="3" opacity="0.7"/>
    <ellipse cx="${fx}" cy="${fy}" rx="290" ry="56" fill="none" stroke="#ff4fd8" stroke-width="10" opacity="0.25" filter="url(#bl6)"/>
    <ellipse cx="${fx}" cy="${fy}" rx="110" ry="20" fill="none" stroke="#ffb3ec" stroke-width="1.5" opacity="0.35"/>
    <line x1="${fx}" y1="${fy - 56}" x2="${fx}" y2="${fy + 56}" stroke="#ffb3ec" stroke-width="1.5" opacity="0.25"/>`;
  // Pennants on the rim.
  const pennants = [80, 200, 330, 610, 690].map((x, k) => `<line x1="${x}" y1="96" x2="${x}" y2="40" stroke="#2a1a48" stroke-width="3"/>
    <path d="M ${x} 42 L ${x + 26} 50 L ${x} 58 Z" fill="${["#ff4fd8", "#7b77ff", "#ffd36b", "#5ce1ff", "#ff4fd8"][k]}"/>`).join("");
  // Fighters + clash spark.
  const ax = 400, bx = 548, cy = 262;
  const fighters = `${shadow(ax, cy + 34, 34, 0.6)}${shadow(bx, cy + 34, 34, 0.6)}
    ${critter(ax, cy, 34, "#3fa9f5", { acc: "fin", mood: "determined", look: [0.8, 0], rim: "#ff9ae6", rimSide: 1 })}
    ${critter(bx, cy, 34, "#ff6a3d", { acc: "flame", mood: "determined", look: [-0.8, 0], rim: "#9ad8ff", rimSide: -1 })}
    <circle cx="${(ax + bx) / 2}" cy="${cy - 4}" r="22" fill="#fff0fb" opacity="0.6" filter="url(#bl8)"/>
    ${sparkle((ax + bx) / 2, cy - 4, 20, "#fff", 1)}${sparkle((ax + bx) / 2 + 12, cy - 22, 8, "#ffd36b", 0.9)}${sparkle((ax + bx) / 2 - 14, cy + 12, 6, "#5ce1ff", 0.9)}`;
  // Ghost drifting over the stands.
  const gx = 640, gy = 64;
  const ghost = `<g opacity="0.92">
    <ellipse cx="${gx}" cy="${gy + 6}" rx="34" ry="36" fill="#ff9ae6" opacity="0.35" filter="url(#bl12)"/>
    <path d="M ${gx - 24} ${gy + 30} L ${gx - 24} ${gy} Q ${gx - 24} ${gy - 26} ${gx} ${gy - 26} Q ${gx + 24} ${gy - 26} ${gx + 24} ${gy} L ${gx + 24} ${gy + 30} Q ${gx + 16} ${gy + 22} ${gx + 8} ${gy + 30} Q ${gx} ${gy + 22} ${gx - 8} ${gy + 30} Q ${gx - 16} ${gy + 22} ${gx - 24} ${gy + 30} Z" fill="#f6e8ff" stroke="#8a5ab0" stroke-width="2.5"/>
    <ellipse cx="${gx - 8}" cy="${gy - 2}" rx="4" ry="6" fill="#2a1a48"/><ellipse cx="${gx + 8}" cy="${gy - 2}" rx="4" ry="6" fill="#2a1a48"/>
    <ellipse cx="${gx}" cy="${gy + 12}" rx="4" ry="3" fill="#2a1a48"/></g>`;
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${band ? 200 : H}" viewBox="0 ${band ? 130 : 0} ${W} ${band ? 200 : H}">${blurs()}
  <defs>
    <linearGradient id="vaSky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0d0a24"/><stop offset="1" stop-color="#3a1448"/></linearGradient>
    <radialGradient id="vaFloor" cx="0.5" cy="0.4" r="0.6"><stop offset="0" stop-color="#5a2a70"/><stop offset="0.6" stop-color="#2e1648"/><stop offset="1" stop-color="#1a0e30"/></radialGradient>
    <linearGradient id="vaWall" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2a1640"/><stop offset="1" stop-color="#160c2a"/></linearGradient>
    <linearGradient id="vaL" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#0D0F26" stop-opacity="0.75"/><stop offset="0.36" stop-color="#0D0F26" stop-opacity="0"/></linearGradient>
  </defs>
  <rect width="${W}" height="${H}" fill="url(#vaSky)"/>
  ${sky(17, 40, 0, 0, 720, 90)}
  <path d="M -10 100 Q 470 70 740 104 L 740 240 L -10 240 Z" fill="url(#vaWall)"/>
  ${pennants}
  <path d="M -10 100 Q 470 70 740 104" stroke="#ff4fd8" stroke-width="2" fill="none" opacity="0.5"/>
  ${crowd}
  <path d="M -10 222 Q 470 196 740 228 L 740 240 L -10 240 Z" fill="#1a0f30"/>
  <path d="M -10 222 Q 470 196 740 228" stroke="#ff4fd8" stroke-width="2" fill="none" opacity="0.45"/>
  <rect x="-10" y="232" width="740" height="120" fill="#120a24"/>
  <g transform="${band ? "translate(70 0)" : ""}">${floor}${beams}${fighters}</g>${band ? "" : ghost}
  ${motes(12, 20, 200, 160, 720, 330, ["#ffb3ec", "#ffd36b", "#9ad8ff"])}
  <rect width="${W}" height="${H}" fill="url(#vaL)"/>${band ? `<rect y="130" width="${W}" height="200" fill="url(#vaL)"/>` : ""}
  </svg>`;
}

// The door shows a 720x200 strip of the scene with the action pushed right.
export default () => scene({ band: true });

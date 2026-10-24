// Adventure hub, Bosses card (game/ui/home_art/adventure_bosses.png): a forge cavern where the Anvil King looms huge
// behind his anvil, crown on, hammer raised, embers in the air, and a small
// hero squares up at the front. Portrait; title over the top band, status
// over the bottom band.
import { blurs, rng } from "./_shop_charge_pad_glow_chest_parts.mjs";
import { critter, shadow, motes, sparkle } from "./_banner_parts.mjs";

const f = (n) => (+n).toFixed(1);

export const size = [360, 560];
export const dir = "game/ui/home_art";

export default function () {
  const W = 360, H = 560, R = rng(44);
  // cave walls: layered rock arches framing a fiery back
  let bricks = "";
  for (let r = 0; r < 9; r++) for (let c = 0; c < 6; c++) {
    const x = c * 66 - (r % 2) * 33 + R() * 4, y = 40 + r * 40;
    bricks += `<rect x="${f(x)}" y="${f(y)}" width="62" height="36" rx="5" fill="${R() > 0.5 ? "#2a1a3c" : "#24163a"}" stroke="#140a22" stroke-width="2"/>`;
  }
  const crown = (cx, cy, s) => `<path d="M ${cx - 40 * s} ${cy} L ${cx - 46 * s} ${cy - 44 * s} L ${cx - 22 * s} ${cy - 20 * s} L ${cx} ${cy - 54 * s} L ${cx + 22 * s} ${cy - 20 * s} L ${cx + 46 * s} ${cy - 44 * s} L ${cx + 40 * s} ${cy} Z" fill="#ffd36b" stroke="#8a4a10" stroke-width="${4 * s}" stroke-linejoin="round"/>
    <path d="M ${cx - 40 * s} ${cy - 2} L ${cx - 43 * s} ${cy - 30 * s} L ${cx - 24 * s} ${cy - 12 * s}" fill="#fff0b0" opacity="0.6"/>
    ${[-46, 0, 46].map((d, i) => `<circle cx="${cx + d * s}" cy="${cy - (i === 1 ? 54 : 44) * s}" r="${6 * s}" fill="${i === 1 ? "#ff4f7a" : "#5ce1ff"}" stroke="#8a4a10" stroke-width="${2.5 * s}"/>`).join("")}`;
  const kx = 176, ky = 250, kr = 96;
  const king = `
    <ellipse cx="${kx}" cy="${ky}" rx="${kr * 1.5}" ry="${kr * 1.4}" fill="#ff7a2a" opacity="0.28" filter="url(#bl24)"/>
    <circle cx="${kx}" cy="${ky}" r="${kr + 10}" fill="#1a0c1e" opacity="0.55" filter="url(#bl8)"/>
    ${critter(kx, ky, kr, "#ff8a3d", { mood: "determined", look: [0.1, 0.5], rim: "#ffd36b", rimSide: -1 })}
    ${crown(kx + 4, ky - kr * 0.86, 1.15)}`;
  // hammer raised on the right, behind/over the king's shoulder
  const hammer = `<g transform="rotate(28 286 180)">
    <rect x="280" y="150" width="16" height="150" rx="6" fill="#8a5a3a" stroke="#2a120a" stroke-width="3"/>
    <rect x="283" y="156" width="5" height="140" fill="#b8805a"/>
    <rect x="246" y="104" width="84" height="54" rx="8" fill="#8a90aa" stroke="#1e1a34" stroke-width="3.5"/>
    <rect x="246" y="104" width="84" height="16" rx="7" fill="#c8ccdc"/>
    <rect x="276" y="104" width="12" height="54" fill="#5e6280"/>
  </g>
  ${sparkle(330, 112, 9, "#fff4cf", 0.9)}`;
  // anvil in front of the king
  const ay = 360;
  const anvil = `<ellipse cx="176" cy="${ay + 70}" rx="130" ry="16" fill="#000" opacity="0.5" filter="url(#bl6)"/>
    <path d="M 70 ${ay} L 262 ${ay} Q 300 ${ay} 316 ${ay - 12} Q 304 ${ay + 18} 262 ${ay + 22} L 236 ${ay + 22} L 228 ${ay + 44} L 252 ${ay + 64} L 100 ${ay + 64} L 124 ${ay + 44} L 116 ${ay + 22} L 86 ${ay + 22} Q 66 ${ay + 18} 70 ${ay} Z" fill="#3e4060" stroke="#14122a" stroke-width="3.5" stroke-linejoin="round"/>
    <path d="M 74 ${ay + 2} L 262 ${ay + 2} Q 296 ${ay} 310 ${ay - 8}" fill="none" stroke="#9aa0c0" stroke-width="4" stroke-linecap="round"/>
    <path d="M 236 ${ay + 22} L 228 ${ay + 44} L 252 ${ay + 64} L 196 ${ay + 64} Z" fill="#2a2a46"/>
    <ellipse cx="150" cy="${ay - 2}" rx="40" ry="6" fill="#ffb347" opacity="0.5" filter="url(#bl4)"/>`;
  let floor = "";
  for (let k = 0; k < 7; k++) floor += `<path d="M ${-40 + k * 70} ${H} L ${120 + k * 28} 440" stroke="#2a1830" stroke-width="2" opacity="0.8"/>`;
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${blurs()}
  <defs><radialGradient id="bsFire" cx="0.5" cy="0.62" r="0.6"><stop offset="0" stop-color="#fff0b0"/><stop offset="0.25" stop-color="#ffb347"/><stop offset="0.6" stop-color="#e0502a"/><stop offset="1" stop-color="#3a1030" stop-opacity="0"/></radialGradient>
  <linearGradient id="bsFloor" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3a1e30"/><stop offset="1" stop-color="#140a1c"/></linearGradient></defs>
  <rect width="${W}" height="${H}" fill="#160c24"/>
  ${bricks}
  <path d="M 40 440 L 40 200 Q 176 30 312 200 L 312 440 Z" fill="#1a0c1e"/>
  <path d="M 56 440 L 56 206 Q 176 54 296 206 L 296 440 Z" fill="url(#bsFire)"/>
  <path d="M 40 440 L 40 200 Q 176 30 312 200 L 312 440" fill="none" stroke="#3a2440" stroke-width="16"/>
  <path d="M 40 440 L 40 200 Q 176 30 312 200 L 312 440" fill="none" stroke="#ff8a3d" stroke-width="2" opacity="0.5"/>
  <rect x="0" y="436" width="${W}" height="${H - 436}" fill="url(#bsFloor)"/>
  ${floor}
  ${hammer}${king}${anvil}
  ${motes(17, 26, 30, 60, 330, 470, ["#ffd36b", "#ff8a3d", "#ffb347"])}
  ${shadow(70, 470, 24, 0.7)}${critter(70, 444, 22, "#7b77ff", { acc: "antenna", mood: "determined", look: [0.7, -0.6], rim: "#ff8a3d", rimSide: 1 })}
  <rect width="${W}" height="${H}" fill="#0D0F26" opacity="0.08"/>
  </svg>`;
}

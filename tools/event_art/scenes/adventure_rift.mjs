// Adventure hub, Rifts card (game/ui/home_art/adventure_rift.png): dusk over
// broken stone ruins, a Glitch tear hanging in the air with the nine family
// shards drifting round it, the brass Rift Key floating in front of it and a
// small critter peeking out from behind a rock to look in. Calm and dark on
// the left, where the card's title and key count sit. Moving layers: the key
// bobs, the critter idles.
import { blurs, rng, sparkle } from "./_shop_charge_pad_glow_chest_parts.mjs";
import { critter, shadow, sky, motes } from "./_banner_parts.mjs";
import { tear, shards, key, MG, CY } from "./_rift_parts.mjs";

const f = (n) => (+n).toFixed(1);

export const size = [720, 260];
export const dir = "game/ui/home_art";

export default function () {
  const W = 720, H = 260, R = rng(23);
  // Far floating islands, each with a tiny lit home in a family colour.
  const isle = (x, y, s, lamp) => `<g transform="translate(${x} ${y}) scale(${s})" opacity="0.8">
    <path d="M -46 0 Q 0 -8 46 0 L 30 16 L 10 34 L -4 22 L -22 30 L -34 12 Z" fill="#20163e"/>
    <path d="M -46 0 Q 0 -8 46 0" fill="none" stroke="#3a2c66" stroke-width="3"/>
    <rect x="-9" y="-20" width="18" height="16" fill="#1a1236"/><path d="M -13 -20 L 0 -31 L 13 -20 Z" fill="#1a1236"/>
    <rect x="-4" y="-15" width="8" height="7" fill="${lamp}"/><circle cx="0" cy="-12" r="10" fill="${lamp}" opacity="0.35" filter="url(#bl6)"/></g>`;
  // Ruined columns on the plateau.
  const column = (x, h, broken) => {
    const top = 214 - h;
    return `<rect x="${x - 11}" y="${top}" width="22" height="${h}" fill="#2a2050" stroke="#140e2c" stroke-width="2"/>
      <rect x="${x - 11}" y="${top}" width="6" height="${h}" fill="#3a2e6a"/>
      ${broken ? `<path d="M ${x - 13} ${top} L ${x - 4} ${top - 9} L ${x + 3} ${top - 2} L ${x + 13} ${top - 12} L ${x + 13} ${top} Z" fill="#2a2050" stroke="#140e2c" stroke-width="2"/>` : `<rect x="${x - 15}" y="${top - 8}" width="30" height="9" rx="2" fill="#342a60" stroke="#140e2c" stroke-width="2"/>`}`;
  };
  let tiles = "";
  for (let k = 0; k < 11; k++) {
    const x = 250 + k * 46 + R() * 8;
    tiles += `<path d="M ${f(x)} ${f(214 + R() * 3)} l 40 0 l ${f(6 + R() * 6)} 22 l -48 0 Z" fill="${R() > 0.5 ? "#231a44" : "#1e163c"}" stroke="#120c26" stroke-width="2"/>`;
  }
  const cx = 512, cy = 112;
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${blurs()}
  <defs>
    <linearGradient id="arSky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0c0a26"/><stop offset="0.6" stop-color="#2a1650"/><stop offset="1" stop-color="#4a1f5e"/></linearGradient>
    <linearGradient id="arLeft" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#0b0a1f" stop-opacity="0.85"/><stop offset="0.45" stop-color="#0b0a1f" stop-opacity="0"/></linearGradient>
    <linearGradient id="arGround" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#1c1438"/><stop offset="1" stop-color="#0d0a20"/></linearGradient>
  </defs>
  <rect width="${W}" height="${H}" fill="url(#arSky)"/>
  ${sky(7, 70, 0, 0, W, 150)}
  <ellipse cx="${cx}" cy="${cy + 40}" rx="300" ry="90" fill="#ff4fb8" opacity="0.12" filter="url(#bl32)"/>
  ${isle(110, 92, 0.8, "#5fd068")}${isle(230, 54, 0.55, "#3fa9f5")}${isle(668, 70, 0.7, "#ffc93c")}${isle(372, 40, 0.45, "#b07cff")}
  <path d="M 0 214 L 0 190 Q 120 176 230 196 L 250 214 Z" fill="#160f30"/>
  <rect x="0" y="212" width="${W}" height="${H - 212}" fill="url(#arGround)"/>
  ${tiles}
  ${column(300, 70, true)}${column(706, 96, false)}${column(650, 46, true)}
  ${tear(cx, cy, 120, 176, 11)}
  ${shards(cx, cy + 6, 128, 34, 9, 1.05)}
  <ellipse cx="${cx}" cy="216" rx="110" ry="9" fill="${MG}" opacity="0.35" filter="url(#bl8)"/>
  <ellipse cx="${cx}" cy="216" rx="60" ry="5" fill="${CY}" opacity="0.45" filter="url(#bl4)"/>
  <g data-layer="key" data-move="bob 5 0.45 0.2">${key(622, 158, 0.78, -32)}</g>
  <path d="M 356 222 Q 352 186 380 182 Q 414 178 420 204 Q 424 222 412 226 Z" fill="#2a2050" stroke="#140e2c" stroke-width="2.5"/>
  ${shadow(400, 226, 30, 0.6)}
  <g data-layer="peek" data-move="idle 3 0.5 0.6">${critter(408, 190, 24, "#ffc93c", { acc: "antenna", mood: "happy", look: [0.9, -0.4], rim: MG, rimSide: 1 })}</g>
  <path d="M 344 230 Q 346 204 366 200 Q 386 198 388 216 Q 390 230 380 232 Z" fill="#30265a" stroke="#140e2c" stroke-width="2.5"/>
  ${motes(31, 22, 380, 40, 680, 220, [MG, CY, "#ffe08a", "#b07cff"])}
  ${sparkle(560, 30, 7, "#ffffff", 0.9)}${sparkle(452, 54, 5, CY, 0.8)}
  <rect width="${W}" height="${H}" fill="url(#arLeft)"/>
  </svg>`;
}

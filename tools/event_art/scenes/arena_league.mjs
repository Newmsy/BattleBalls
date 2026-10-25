// Ghost Arena league panel (game/ui/screens/arena_screen.gd _league_panel):
// the night colosseum with your league's crest on a plinth under spotlights,
// banners in the league colour, a fan cheering beside it. The league's words
// sit on the left (faded), so the crest is centre-right. One painting per
// league (league_<id>, ids from game/pvp/ladder.gd LEAGUES), into game/ui/versus_art.
import { blurs, sparkle } from "./_shop_charge_pad_glow_chest_parts.mjs";
import { critter, shadow, sky, motes, shade } from "./_banner_parts.mjs";
import { crowd, ghost, cupIcon } from "./_versus_parts.mjs";

const f = (n) => (+n).toFixed(1);

export const dir = "game/ui/versus_art";

export const size = [720, 260];
const W = 720, H = 260;

const LEAGUES = {
  bronze: "#d08a4e", silver: "#c9d3e0", gold: "#ffc23d",
  platinum: "#6ff0d8", diamond: "#7aa8ff", neon: "#ff4fd8",
};

const shield = (x, y, s, col) => {
  const lo = shade(col, -0.55), hi = shade(col, 0.5);
  return `<g transform="translate(${x} ${y}) scale(${s})">
    <path d="M 0 -64 L 52 -46 L 50 8 Q 44 52 0 70 Q -44 52 -50 8 L -52 -46 Z" fill="${shade(col, -0.25)}" stroke="${lo}" stroke-width="5"/>
    <path d="M 0 -52 L 40 -38 L 38 6 Q 34 40 0 56 Q -34 40 -38 6 L -40 -38 Z" fill="${col}"/>
    <path d="M -30 -32 L -28 4 Q -24 30 -6 42" stroke="${hi}" stroke-width="6" fill="none" stroke-linecap="round" opacity="0.7"/></g>`;
};

const laurel = (x, y, side, col) => {
  let out = "";
  for (let k = 0; k < 6; k++) {
    const a = (-60 + k * 26) * Math.PI / 180;
    const lx = x + side * Math.cos(a) * 78, ly = y + Math.sin(a) * 70;
    out += `<ellipse cx="${f(lx)}" cy="${f(ly)}" rx="13" ry="6" fill="${col}" stroke="${shade(col, -0.55)}" stroke-width="2" transform="rotate(${f(side * (k * 26 - 30))} ${f(lx)} ${f(ly)})"/>`;
  }
  return out;
};

const wing = (x, y, side, col) =>
  `<path d="M ${x} ${y} q ${side * 60} -50 ${side * 96} -34 q ${side * -16} 12 ${side * -30} 14 q ${side * 24} 6 ${side * 22} 20 q ${side * -20} 4 ${side * -34} 2 q ${side * 12} 14 ${side * 4} 22 Q ${x + side * 30} ${y + 30} ${x} ${y + 20} Z" fill="${shade(col, 0.2)}" stroke="${shade(col, -0.55)}" stroke-width="3"/>`;

const gem = (x, y, r, col) =>
  `<g><path d="M ${x} ${y - r} L ${x + r * 0.8} ${y - r * 0.2} L ${x} ${y + r} L ${x - r * 0.8} ${y - r * 0.2} Z" fill="${col}" stroke="${shade(col, -0.6)}" stroke-width="3"/>
  <path d="M ${x - r * 0.8} ${y - r * 0.2} L ${x + r * 0.8} ${y - r * 0.2} M ${x} ${y - r} L ${x - r * 0.25} ${y - r * 0.2} L ${x} ${y + r} M ${x} ${y - r} L ${x + r * 0.25} ${y - r * 0.2}" stroke="${shade(col, 0.5)}" stroke-width="2" fill="none" opacity="0.8"/></g>`;

const banner = (x, col, seed) => `<g data-layer="b${seed}" data-move="sway 3 0.4 ${seed * 0.3}" data-pivot="${x} 0">
  <rect x="${x - 2}" y="0" width="4" height="16" fill="#3a2a50"/>
  <path d="M ${x - 26} 14 L ${x + 26} 14 L ${x + 26} 112 L ${x} 96 L ${x - 26} 112 Z" fill="${shade(col, -0.35)}" stroke="${shade(col, -0.7)}" stroke-width="3"/>
  <path d="M ${x - 26} 26 L ${x + 26} 26" stroke="${col}" stroke-width="4"/>
  ${cupIcon(x, 60, 13, col)}</g>`;

const scene = (id) => {
  const col = LEAGUES[id];
  const cx = 540, cy = 128;
  let crest = shield(cx, cy, 1, col);
  if (id === "silver") crest = wing(cx - 44, cy - 20, -1, col) + wing(cx + 44, cy - 20, 1, col) + crest;
  if (id === "gold") crest = laurel(cx, cy + 6, -1, "#7fd66a") + laurel(cx, cy + 6, 1, "#7fd66a") + crest;
  if (id === "platinum") crest = laurel(cx, cy + 6, -1, col) + laurel(cx, cy + 6, 1, col) + crest;
  if (id === "diamond") crest = wing(cx - 44, cy - 20, -1, col) + wing(cx + 44, cy - 20, 1, col) + crest;
  if (id === "neon") crest = wing(cx - 44, cy - 20, -1, col) + wing(cx + 44, cy - 20, 1, col) + laurel(cx, cy + 6, -1, "#ffd36b") + laurel(cx, cy + 6, 1, "#ffd36b") + crest;
  const inner = id === "diamond" || id === "platinum" || id === "neon" ? gem(cx, cy - 4, 24, shade(col, 0.35)) : cupIcon(cx, cy - 6, 22, shade(col, 0.3));
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${blurs()}
  <defs><linearGradient id="lS" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0a0a26"/><stop offset="1" stop-color="${shade(col, -0.82)}"/></linearGradient>
  <linearGradient id="beam" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${col}" stop-opacity="0.35"/><stop offset="1" stop-color="${col}" stop-opacity="0"/></linearGradient>
  <linearGradient id="lL" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#0D0F26" stop-opacity="0.9"/><stop offset="0.5" stop-color="#0D0F26" stop-opacity="0.35"/><stop offset="0.62" stop-color="#0D0F26" stop-opacity="0"/></linearGradient></defs>
  <rect width="${W}" height="${H}" fill="url(#lS)"/>${sky(id.length * 7, 30, 0, 0, 720, 70)}
  ${crowd(id.length * 11, { y: 70, rows: 3, cx: 540, curve: 16, dark: -0.66, wave: 0.1 })}
  <path d="M -10 150 Q 540 132 740 152 L 740 270 L -10 270 Z" fill="#120a2c"/>
  <path d="M 380 0 L 470 230 L 520 230 Z M 700 0 L 560 230 L 610 230 Z" fill="url(#beam)"/>
  ${motes(id.length, 14, 360, 40, 720, 240, [col, "#fff6cc", shade(col, 0.5)])}
  ${ghost(450, 70, 0.45, { o: 0.5, look: 1 })}
  <rect width="${W}" height="${H}" fill="url(#lL)"/>
  ${banner(400, col, 1)}${banner(680, col, 2)}
  <ellipse cx="${cx}" cy="226" rx="120" ry="20" fill="${col}" opacity="0.18" filter="url(#bl12)"/>
  <path d="M ${cx - 70} 200 L ${cx + 70} 200 L ${cx + 84} 232 L ${cx - 84} 232 Z" fill="#2a1e4a" stroke="#0e0820" stroke-width="3"/>
  <path d="M ${cx - 70} 200 L ${cx + 70} 200" stroke="${col}" stroke-width="3" opacity="0.8"/>
  <ellipse cx="${cx}" cy="${cy}" rx="90" ry="86" fill="${col}" opacity="0.28" filter="url(#bl12)"/>
  <g data-layer="crest" data-move="breathe 0.03 0.5 0">${crest}${inner}${sparkle(590, 70, 9, "#fff", 0.95)}${sparkle(488, 92, 5, shade(col, 0.6), 0.9)}</g>
  ${shadow(640, 214, 16, 0.5)}<g data-layer="fan" data-move="idle 3 0.8 0">${critter(640, 196, 18, "#7b77ff", { acc: "antenna", mood: "cheer", look: [-0.7, -0.4], rim: col })}</g>
</svg>`;
};

export const many = Object.fromEntries(Object.keys(LEAGUES).map((id) => ["league_" + id, () => scene(id)]));

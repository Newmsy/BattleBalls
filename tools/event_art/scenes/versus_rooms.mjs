// Ghost Arena (game/ui/screens/arena_screen.gd): the three rooms as painted
// doorways (240x220 each, shown at the top of an arch-topped tile): a cup-lined Trophy Room, the Bazaar
// stall heaped with Tokens, and the Defence wall with your trio on guard.
import { blurs, sparkle, stringLights } from "./_shop_charge_pad_glow_chest_parts.mjs";
import { critter, shadow, motes, shade } from "./_banner_parts.mjs";
import { cupIcon, GOLD } from "./_versus_parts.mjs";

const f = (n) => (+n).toFixed(1);

export const dir = "game/ui/versus_art";
export const size = [240, 220];
const W = 240, H = 220;
const svg = (body) => `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${blurs()}${body}
  <defs><linearGradient id="rB" x1="0" y1="0" x2="0" y2="1"><stop offset="0.6" stop-color="#0D0F26" stop-opacity="0"/><stop offset="1" stop-color="#0D0F26" stop-opacity="0.85"/></linearGradient></defs><rect width="${W}" height="${H}" fill="url(#rB)"/></svg>`;

const hex = (cx, cy, r, col) => {
  const pts = Array.from({ length: 6 }, (_, k) => { const a = Math.PI / 3 * k + Math.PI / 6; return `${f(cx + r * Math.cos(a))},${f(cy + r * Math.sin(a))}`; }).join(" ");
  return `<polygon points="${pts}" fill="${col}" stroke="${shade(col, -0.55)}" stroke-width="2"/><path d="M ${f(cx - r * 0.4)} ${f(cy)} L ${f(cx + r * 0.4)} ${f(cy)}" stroke="#fff0fb" stroke-width="2" stroke-linecap="round"/>`;
};

const trophy = () => svg(`
  <defs><radialGradient id="tG" cx="0.5" cy="0.45" r="0.7"><stop offset="0" stop-color="#5a3a1a"/><stop offset="1" stop-color="#1a1020"/></radialGradient></defs>
  <rect width="${W}" height="${H}" fill="url(#tG)"/>
  ${[64, 128].map((y) => `<rect x="10" y="${y}" width="220" height="10" rx="3" fill="#6a4420" stroke="#1a0c08" stroke-width="2"/>`).join("")}
  ${[[36, 52, 13], [80, 50, 15], [160, 52, 13], [204, 50, 15], [40, 116, 15], [200, 116, 15]].map(([x, y, r]) => cupIcon(x, y - 4, r, ["#ffc23d", "#c9d3e0", "#d08a4e"][(x + y) % 3])).join("")}
  <ellipse cx="120" cy="120" rx="60" ry="60" fill="${GOLD}" opacity="0.25" filter="url(#bl12)"/>
  ${cupIcon(120, 112, 34, "#ffc23d")}
  <rect x="76" y="150" width="88" height="40" rx="6" fill="#4a2a14" stroke="#1a0c08" stroke-width="3"/>
  <rect x="84" y="158" width="72" height="8" rx="3" fill="#ffd36b" opacity="0.6"/>
  <rect x="0" y="190" width="${W}" height="30" fill="#2a1a10"/>
  ${sparkle(156, 70, 9, "#fff", 0.95)}${sparkle(90, 84, 5, "#fff6cc", 0.8)}
  ${motes(7, 8, 20, 30, 220, 200, ["#ffd36b", "#fff6cc"])}`);

const bazaar = () => svg(`
  <defs><linearGradient id="zG" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#1a0c30"/><stop offset="1" stop-color="#3a1448"/></linearGradient></defs>
  <rect width="${W}" height="${H}" fill="url(#zG)"/>
  ${stringLights(-10, 22, 250, 22, 16, 8, ["#ff4fd8", "#ffd36b", "#5ce1ff"], 4)}
  <path d="M 14 86 L 226 86 L 210 46 L 30 46 Z" fill="#ff4fd8" stroke="#5a0a40" stroke-width="3"/>
  ${[0, 1, 2, 3, 4].map((k) => `<path d="M ${30 + k * 36} 46 L ${14 + k * 42.4} 86 L ${35 + k * 42.4} 86 L ${48 + k * 36} 46 Z" fill="#fff0fb" opacity="0.8"/>`).join("")}
  ${[0, 1, 2, 3, 4, 5].map((k) => `<path d="M ${14 + k * 35.3} 86 q 17.6 16 35.3 0" fill="#ff4fd8" stroke="#5a0a40" stroke-width="2"/>`).join("")}
  <rect x="26" y="96" width="10" height="100" fill="#3a1a2a"/><rect x="204" y="96" width="10" height="100" fill="#3a1a2a"/>
  ${shadow(120, 152, 28, 0.5)}<g data-layer="seller" data-move="idle 3 0.7 0">${critter(120, 126, 26, "#ffc93c", { acc: "propeller", mood: "cheer", look: [0, 0.2] })}</g>
  <g data-layer="counter" data-move="still"><rect x="20" y="150" width="200" height="46" rx="6" fill="#5a2050" stroke="#1a0a20" stroke-width="3"/>
  ${hex(60, 150, 14, "#ff4fd8")}${hex(84, 142, 12, "#ff7ae0")}${hex(160, 146, 14, "#ff4fd8")}${hex(184, 152, 12, "#ff7ae0")}${hex(72, 160, 12, "#ff4fd8")}</g>
  <rect x="0" y="196" width="${W}" height="24" fill="#1a0c24"/>
  ${sparkle(176, 128, 7, "#fff", 0.9)}
  ${motes(4, 6, 20, 40, 220, 190, ["#ffb3ec", "#ffd36b"])}`);

const defence = () => svg(`
  <defs><linearGradient id="eG" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0a1a2a"/><stop offset="1" stop-color="#123a3a"/></linearGradient></defs>
  <rect width="${W}" height="${H}" fill="url(#eG)"/>
  ${[[30, 30], [190, 18], [110, 40], [70, 14], [220, 50]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="1.6" fill="#dff" opacity="0.7"/>`).join("")}
  <path d="M 0 120 L 0 84 ${[0, 1, 2, 3, 4, 5].map((k) => `L ${k * 44 + 0} 84 L ${k * 44} 70 L ${k * 44 + 24} 70 L ${k * 44 + 24} 84`).join(" ")} L 240 84 L 240 220 L 0 220 Z" fill="#2a4a5a" stroke="#0a1a24" stroke-width="3"/>
  ${[0, 1, 2, 3].map((r) => [0, 1, 2, 3, 4].map((c) => `<rect x="${c * 52 + (r % 2) * 26 - 10}" y="${100 + r * 26}" width="48" height="22" rx="3" fill="#36606e" opacity="0.55"/>`).join("")).join("")}
  ${shadow(60, 86, 18, 0.5)}${shadow(120, 86, 20, 0.5)}${shadow(180, 86, 18, 0.5)}
  <g data-layer="l" data-move="idle 2 0.8 0">${critter(60, 66, 18, "#5fd068", { acc: "leaf", mood: "determined" })}</g>
  <g data-layer="m" data-move="idle 2 0.7 0.4">${critter(120, 62, 22, "#7b77ff", { acc: "antenna", mood: "determined" })}</g>
  <g data-layer="r" data-move="idle 2 0.8 0.7">${critter(180, 66, 18, "#ff6a3d", { acc: "flame", mood: "determined" })}</g>
  <g transform="translate(120 152)"><ellipse rx="44" ry="44" fill="#45f5a6" opacity="0.25" filter="url(#bl12)"/>
  <path d="M 0 -40 L 34 -28 L 32 4 Q 28 30 0 44 Q -28 30 -32 4 L -34 -28 Z" fill="#2a8a6a" stroke="#0e3a2a" stroke-width="3"/>
  <path d="M 0 -32 L 26 -22 L 25 4 Q 22 24 0 35 Q -22 24 -25 4 L -26 -22 Z" fill="#45f5a6"/>
  <path d="M 0 -32 L 0 35 Q -22 24 -25 4 L -26 -22 Z" fill="#fff" opacity="0.2"/></g>
  ${motes(8, 6, 20, 40, 220, 200, ["#45f5a6", "#dff"])}`);

export const many = { room_trophy: trophy, room_bazaar: bazaar, room_defence: defence };
export default trophy;

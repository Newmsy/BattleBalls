// The Bag's gear section bands (Shells, Cores, Charms): one matching set. Every band is the same night arena
// (dark back wall with a lit rim, tiled floor, faint crowd), lit in the
// slot's colour, with critters showing what that gear does in a fight:
//   gear_band_shells - a ball slams into a critter's shield and bounces off
//   gear_band_cores  - a critter with a glowing core lands a big hit
//   gear_band_charms - a critter streaks across the floor, rocket trail and clock
// Title side (left ~40%) stays calm and dark.
import { critter, shadow, sky, motes, shade, rng, sparkle } from "./_banner_parts.mjs";
import { blurs } from "./_shop_charge_pad_glow_chest_parts.mjs";
import { f } from "./_map_token.mjs";

export const size = [720, 200];
export const dir = "game/ui/gear_art";
const W = 720, H = 200, INK = "#14102e";

function arena(col, seed, body) {
  const R = rng(seed);
  let crowd = "";
  for (let x = 250; x < 740; x += 15) {
    const y = 60 + R() * 4;
    crowd += `<circle cx="${f(x + R() * 5)}" cy="${f(y)}" r="${f(6 + R() * 2)}" fill="${shade(col, -0.78 - R() * 0.1)}"/>`;
  }
  let tiles = "";
  for (let k = 0; k < 14; k++) tiles += `<path d="M ${470 + (k - 7) * 30} 112 L ${470 + (k - 7) * 78} 210" stroke="${shade(col, -0.6)}" stroke-width="1.5" opacity="0.6"/>`;
  for (const y of [128, 150, 178]) tiles += `<path d="M -10 ${y} L 740 ${y}" stroke="${shade(col, -0.6)}" stroke-width="1.5" opacity="0.5"/>`;
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${blurs()}
  <defs>
    <linearGradient id="ab" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#121034"/><stop offset="1" stop-color="${shade(col, -0.62)}"/></linearGradient>
    <linearGradient id="af" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${shade(col, -0.62)}"/><stop offset="1" stop-color="#0c0b22"/></linearGradient>
    <radialGradient id="ap" cx="0.66" cy="0.7" r="0.5"><stop offset="0" stop-color="${col}" stop-opacity="0.32"/><stop offset="1" stop-color="${col}" stop-opacity="0"/></radialGradient>
    <linearGradient id="aL" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#0D0F26" stop-opacity="0.88"/><stop offset="0.3" stop-color="#0D0F26" stop-opacity="0.55"/><stop offset="0.46" stop-color="#0D0F26" stop-opacity="0"/></linearGradient>
  </defs>
  <rect width="${W}" height="${H}" fill="url(#ab)"/>${sky(seed, 18, 0, 0, 720, 44)}
  ${crowd}
  <rect x="-10" y="70" width="740" height="44" fill="${shade(col, -0.8)}"/>
  <path d="M -10 72 L 740 72" stroke="${col}" stroke-width="2" opacity="0.45"/>
  <path d="M -10 112 L 740 112" stroke="${col}" stroke-width="3" opacity="0.85"/>
  <path d="M -10 112 L 740 112" stroke="${col}" stroke-width="10" opacity="0.25" filter="url(#bl6)"/>
  <rect x="-10" y="113" width="740" height="100" fill="url(#af)"/>${tiles}
  <rect width="${W}" height="${H}" fill="url(#ap)"/>
  ${body}
  ${motes(seed + 3, 10, 300, 20, 720, 190, [shade(col, 0.5), "#fff4d8"])}
  <rect width="${W}" height="${H}" fill="url(#aL)"/></svg>`;
}

const streak = (x1, y1, x2, y2, col, w = 3, o = 0.7) => `<line x1="${f(x1)}" y1="${f(y1)}" x2="${f(x2)}" y2="${f(y2)}" stroke="${col}" stroke-width="${w}" stroke-linecap="round" opacity="${o}"/>`;

function shells() {
  const G = "#4cd98a";
  const sx = 470, sy = 138;
  return arena(G, 41, `
    ${shadow(sx, sy + 34, 36, 0.6)}
    <g data-layer="guard" data-move="idle 2 0.6 0">${critter(sx, sy, 32, "#3fa9f5", { acc: "fin", mood: "determined", look: [0.9, -0.1], rim: G, rimSide: 1 })}</g>
    <path d="M ${sx + 44} ${sy - 46} A 58 58 0 0 1 ${sx + 44} ${sy + 46}" fill="none" stroke="${G}" stroke-width="16" opacity="0.25" filter="url(#bl6)"/>
    <path d="M ${sx + 44} ${sy - 46} A 58 58 0 0 1 ${sx + 44} ${sy + 46}" fill="${G}" fill-opacity="0.18" stroke="#d6ffe8" stroke-width="4"/>
    ${[-30, -12, 6, 24].map((d) => `<path d="M ${sx + 52} ${sy + d} l 8 6 l -8 6" fill="none" stroke="#d6ffe8" stroke-width="2" opacity="0.5"/>`).join("")}
    ${sparkle(sx + 60, sy - 8, 16, "#fff", 1)}${sparkle(sx + 70, sy - 26, 7, G, 1)}${sparkle(sx + 66, sy + 14, 6, "#ffd36b", 1)}
    ${streak(sx + 74, sy - 4, sx + 112, sy - 28, "#fff", 3)}${streak(sx + 74, sy + 6, sx + 120, sy + 4, "#fff", 2.5)}
    ${shadow(620, 176, 26, 0.5)}
    <g data-layer="bumper" data-move="bob 3 0.9 0.4">${critter(620, 120, 26, "#ff6a3d", { acc: "horns", mood: "wow", look: [-0.6, 0], rim: G, rimSide: -1, tilt: 18 })}</g>
    ${streak(560, 128, 588, 124, "#ffb08a", 3, 0.6)}${streak(556, 140, 590, 134, "#ffb08a", 2, 0.4)}
    <path d="M 650 102 q 14 -8 22 -2 M 652 118 q 16 -2 24 6" stroke="#ffd36b" stroke-width="3" fill="none" stroke-linecap="round"/>`);
}

function cores() {
  const B = "#3d9bff";
  const ax = 430, bx = 560, y = 140;
  let burst = "";
  for (let k = 0; k < 12; k++) { const a = (k / 12) * Math.PI * 2; burst += streak(500 + Math.cos(a) * 18, y - 8 + Math.sin(a) * 18, 500 + Math.cos(a) * (32 + (k % 2) * 14), y - 8 + Math.sin(a) * (32 + (k % 2) * 14), k % 3 ? "#bfe6ff" : "#ffd36b", 3, 0.9); }
  return arena(B, 52, `
    ${shadow(ax, y + 34, 32, 0.6)}${shadow(bx + 20, y + 34, 30, 0.5)}
    ${[0, 1, 2].map((k) => streak(ax - 50 - k * 14, y - 14 + k * 14, ax - 90 - k * 22, y - 14 + k * 14, "#9ad8ff", 3, 0.5)).join("")}
    ${critter(ax, y, 32, "#ffc93c", { acc: "flame", mood: "determined", look: [0.9, 0], rim: B, rimSide: 1, tilt: -8 })}
    <circle cx="${ax - 40}" cy="${y - 40}" r="22" fill="${B}" opacity="0.6" filter="url(#bl8)"/>
    <path d="M ${ax - 40} ${y - 40} Q ${ax - 20} ${y - 40} ${ax - 8} ${y - 26}" stroke="#bfe6ff" stroke-width="2.5" fill="none" opacity="0.8"/>
    <circle cx="${ax - 40}" cy="${y - 40}" r="13" fill="#e8fbff" stroke="${INK}" stroke-width="3"/><circle cx="${ax - 40}" cy="${y - 40}" r="7" fill="${B}"/><circle cx="${ax - 44}" cy="${y - 44}" r="2.5" fill="#fff"/>
    <circle cx="500" cy="${y - 8}" r="26" fill="#fff4d8" opacity="0.55" filter="url(#bl8)"/>
    ${burst}${sparkle(500, y - 8, 16, "#fff", 1)}
    <g data-layer="hit" data-move="sway 4 0.8 0.3">${critter(bx + 20, y - 4, 28, "#b07cff", { acc: "ears", mood: "tired", look: [-0.5, 0.2], rim: B, rimSide: -1, tilt: 22 })}</g>
    <text x="${bx + 46}" y="${y - 42}" font-family="sans-serif" font-weight="900" font-size="22" fill="#ffd36b" stroke="${INK}" stroke-width="4" paint-order="stroke" transform="rotate(12 ${bx + 46} ${y - 42})">!</text>`);
}

function charms() {
  const A = "#ffb347";
  const x = 560, y = 140;
  return arena(A, 63, `
    <path d="M 300 ${y + 18} Q 420 ${y + 30} ${x - 30} ${y + 6}" fill="none" stroke="#5fd068" stroke-width="18" opacity="0.18" stroke-linecap="round"/>
    <path d="M 330 ${y + 20} Q 430 ${y + 28} ${x - 30} ${y + 6}" fill="none" stroke="#ffd36b" stroke-width="5" opacity="0.6" stroke-linecap="round"/>
    ${[[380, y - 18, 60], [400, y + 2, 80], [420, y + 36, 50]].map(([sx, sy, l]) => streak(sx, sy, sx + l, sy - 4, "#fff4d8", 3, 0.55)).join("")}
    ${[350, 400, 450].map((px, k) => `<g opacity="${0.25 + k * 0.15}">${critter(px + 40, y + 4, 26, "#5fd068", { acc: "leaf", mood: "cheer", blushOn: false })}</g>`).join("")}
    ${shadow(x, y + 34, 32, 0.6)}
    <ellipse cx="${x - 52}" cy="${y + 8}" rx="26" ry="14" fill="#ff8a3d" opacity="0.5" filter="url(#bl6)"/>
    <path d="M ${x - 28} ${y - 6} Q ${x - 70} ${y - 8} ${x - 92} ${y + 8} Q ${x - 70} ${y + 22} ${x - 28} ${y + 18} Z" fill="#ff8a3d" stroke="${INK}" stroke-width="2.5" stroke-linejoin="round"/>
    <path d="M ${x - 30} ${y} Q ${x - 56} ${y} ${x - 70} ${y + 8} Q ${x - 56} ${y + 14} ${x - 30} ${y + 12} Z" fill="#ffe08a"/>
    <g data-layer="runner" data-move="bob 3 1.2 0">${critter(x, y, 32, "#5fd068", { acc: "leaf", mood: "cheer", look: [0.9, -0.1], rim: A, rimSide: 1, tilt: 10 })}</g>
    <g transform="translate(${x + 54} ${y - 46})">
      <circle r="24" fill="${A}" opacity="0.35" filter="url(#bl8)"/>
      <circle r="18" fill="#fff6e0" stroke="${INK}" stroke-width="3"/>
      <rect x="-4" y="-27" width="8" height="8" rx="2" fill="#d8b070" stroke="${INK}" stroke-width="2"/>
      <path d="M 0 0 L 0 -14 A 14 14 0 0 1 12 -6 Z" fill="#ff8a3d" opacity="0.6"/>
      <line x1="0" y1="0" x2="10" y2="-7" stroke="#d8402a" stroke-width="3" stroke-linecap="round"/><circle r="2.5" fill="${INK}"/>
    </g>
    ${sparkle(x + 90, y - 20, 8, "#ffd36b", 1)}${sparkle(x + 30, y - 70, 6, "#fff", 0.9)}`);
}

export const many = { gear_band_shells: shells, gear_band_cores: cores, gear_band_charms: charms };
export default shells;

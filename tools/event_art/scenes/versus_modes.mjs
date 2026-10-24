// The Versus hub (game/ui/screens/versus_screen.gd): one painting per mode,
// each its own little place, rendered into game/ui/versus_art.
//   vs_ghost   (720x240) Ghost Arena: your critter faces a trio of ghost-critters
//             (see-through, wispy tails) on a misty spectral ring.
//   vs_quick   (720x200) Quick fight: a sparring pit with ropes, your fighter
//             warming up while a random foe steps out of a "?" gate.
//   vs_duo     (360x280) 2v2: tag-team square ring, two pairs squaring off.
//   vs_friends (360x280) Friends: a cosy box seat over the stands, two critters
//             on a couch sharing a lightning gift (energy).
import { blurs, rng, sparkle, stringLights } from "./_shop_charge_pad_glow_chest_parts.mjs";
import { critter, shadow, sky, motes, shade } from "./_banner_parts.mjs";
import { crowd, ghost, PINK, GOLD, CYAN } from "./_versus_parts.mjs";

const f = (n) => (+n).toFixed(1);

const svg = (W, H, body) => `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${blurs()}${body}</svg>`;
const fadeL = (W, H, id, o = 0.75, to = 0.4) => `<defs><linearGradient id="${id}" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#0D0F26" stop-opacity="${o}"/><stop offset="${to}" stop-color="#0D0F26" stop-opacity="0"/></linearGradient></defs><rect width="${W}" height="${H}" fill="url(#${id})"/>`;
const fadeT = (W, H, id, o = 0.8, to = 0.35) => `<defs><linearGradient id="${id}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0D0F26" stop-opacity="${o}"/><stop offset="${to}" stop-color="#0D0F26" stop-opacity="0"/></linearGradient></defs><rect width="${W}" height="${H}" fill="url(#${id})"/>`;

// A see-through ghost version of a critter: body fades into a wavy tail.
function ghostCritter(cx, cy, r, col, acc, o = 0.7) {
  const id = "gc" + Math.round(cx) + Math.round(cy);
  return `<defs><linearGradient id="${id}" x1="0" y1="0" x2="0" y2="1"><stop offset="0.45" stop-color="#fff"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>
    <mask id="${id}m"><rect x="${cx - r * 2}" y="${cy - r * 2}" width="${r * 4}" height="${r * 4.4}" fill="url(#${id})"/></mask></defs>
    <g opacity="${o}"><ellipse cx="${cx}" cy="${cy}" rx="${r * 1.4}" ry="${r * 1.5}" fill="${col}" opacity="0.35" filter="url(#bl12)"/>
    <g mask="url(#${id}m)">
    <path d="M ${cx - r} ${cy} Q ${cx - r} ${cy + r * 1.6} ${cx - r * 0.5} ${cy + r * 1.9} Q ${cx} ${cy + r * 1.5} ${cx + r * 0.3} ${cy + r * 2} Q ${cx + r} ${cy + r * 1.5} ${cx + r} ${cy} Z" fill="${shade(col, 0.25)}"/>
    ${critter(cx, cy, r, shade(col, 0.25), { acc, mood: "determined", look: [-0.8, 0], blushOn: false })}</g></g>`;
}

const ghostArena = () => {
  const W = 720, H = 240, R = rng(4);
  let mist = "";
  for (let k = 0; k < 14; k++) mist += `<ellipse cx="${f(R() * 760 - 20)}" cy="${f(180 + R() * 60)}" rx="${f(60 + R() * 80)}" ry="${f(10 + R() * 12)}" fill="#c9b8ff" opacity="${f(0.05 + R() * 0.08)}" filter="url(#bl8)"/>`;
  return svg(W, H, `
  <defs><linearGradient id="gS" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0a0a26"/><stop offset="1" stop-color="#2a1a5a"/></linearGradient></defs>
  <rect width="${W}" height="${H}" fill="url(#gS)"/>${sky(8, 40, 0, 0, 720, 120)}
  <circle cx="300" cy="56" r="30" fill="#dcd0ff" opacity="0.2" filter="url(#bl12)"/><circle cx="300" cy="56" r="19" fill="#e9e2ff" opacity="0.55"/>
  ${crowd(30, { y: 66, rows: 3, cx: 470, curve: 18, dark: -0.82, wave: 0.05 })}
  <path d="M -10 130 Q 470 112 740 134 L 740 250 L -10 250 Z" fill="#140c30"/>
  <path d="M -10 130 Q 470 112 740 134" stroke="#9d8cff" stroke-width="2" fill="none" opacity="0.5"/>
  <ellipse cx="480" cy="196" rx="280" ry="40" fill="#1e1446"/>
  <ellipse cx="480" cy="196" rx="280" ry="40" fill="none" stroke="#a98cff" stroke-width="3" opacity="0.7"/>
  <ellipse cx="480" cy="196" rx="280" ry="40" fill="none" stroke="${PINK}" stroke-width="10" opacity="0.18" filter="url(#bl6)"/>
  ${shadow(330, 204, 30, 0.6)}
  ${critter(330, 172, 32, "#3fa9f5", { acc: "fin", mood: "determined", look: [0.9, 0], rim: "#c9b8ff", rimSide: 1 })}
  ${ghostCritter(600, 144, 24, "#b07cff", "horns", 0.55)}${ghostCritter(540, 160, 26, "#8fe6ff", "crystal", 0.65)}${ghostCritter(660, 168, 28, "#ff9ae6", "ears", 0.75)}
  ${sparkle(436, 160, 12, "#fff", 0.9)}${sparkle(452, 146, 5, CYAN, 0.9)}
  ${ghost(120, 70, 0.55, { o: 0.4, look: 1 })}
  ${mist}${motes(6, 12, 200, 100, 720, 230, ["#c9b8ff", "#ffb3ec", "#9ad8ff"])}
  ${fadeL(W, H, "gL", 0.8, 0.42)}`);
};

const quick = () => {
  const W = 720, H = 200;
  const posts = [170, 700].map((x) => `<rect x="${x - 6}" y="70" width="12" height="100" rx="4" fill="#3a2a60" stroke="#140a24" stroke-width="2"/><circle cx="${x}" cy="70" r="9" fill="#8f7bff"/>`).join("");
  return svg(W, H, `
  <defs><linearGradient id="qS" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0e0c2c"/><stop offset="1" stop-color="#28205a"/></linearGradient>
  <radialGradient id="qF" cx="0.5" cy="0.3" r="0.7"><stop offset="0" stop-color="#4a3a8a"/><stop offset="1" stop-color="#1a1440"/></radialGradient></defs>
  <rect width="${W}" height="${H}" fill="url(#qS)"/>${sky(12, 30, 0, 0, 720, 70)}
  ${stringLights(160, 20, 720, 26, 22, 14, ["#8f7bff", "#ffd36b", "#5ce1ff", "#ff4fd8"], 5)}
  <path d="M 560 150 L 560 64 Q 610 24 660 64 L 660 150 Z" fill="#0b0820" stroke="#3a2a60" stroke-width="6"/>
  <path d="M 572 150 L 572 70 Q 610 40 648 70 L 648 150 Z" fill="#8f7bff" opacity="0.25"/>
  <text x="610" y="118" text-anchor="middle" font-family="Arial Black, sans-serif" font-size="46" fill="#cfc8ff" opacity="0.9">?</text>
  <path d="M 100 196 L 160 140 L 710 140 L 740 196 Z" fill="url(#qF)"/>
  ${posts}
  <path d="M 170 84 L 700 84 M 170 108 L 700 108" stroke="#ff4fd8" stroke-width="3" opacity="0.7"/>
  ${shadow(330, 178, 34, 0.6)}${critter(330, 146, 34, "#ff7ac8", { acc: "ears", mood: "determined", look: [0.9, -0.1], rim: "#cfc8ff" })}
  <path d="M 276 128 l -18 -6 M 272 146 l -20 0 M 276 164 l -18 6" stroke="#cfc8ff" stroke-width="3" stroke-linecap="round" opacity="0.6"/>
  ${shadow(520, 182, 28, 0.5)}<g opacity="0.85">${critter(520, 156, 28, "#5a4a8a", { acc: "horns", mood: "determined", look: [-0.9, 0], blushOn: false })}</g>
  <circle cx="520" cy="156" r="40" fill="#8f7bff" opacity="0.15" filter="url(#bl12)"/>
  ${sparkle(426, 140, 10, "#fff", 0.9)}
  ${motes(9, 8, 200, 60, 720, 190, ["#cfc8ff", "#ffd36b"])}
  ${fadeL(W, H, "qL", 0.85, 0.42)}`);
};

const duo = () => {
  const W = 360, H = 280;
  const ropeY = [150, 172, 194];
  return svg(W, H, `
  <defs><linearGradient id="dS" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#160a2c"/><stop offset="1" stop-color="#3a1448"/></linearGradient></defs>
  <rect width="${W}" height="${H}" fill="url(#dS)"/>
  ${crowd(41, { y: 108, rows: 3, x0: -10, x1: 370, cx: 180, curve: 10, step: 15, dark: -0.78 })}
  <path d="M -10 180 L 370 180 L 370 290 L -10 290 Z" fill="#2a1240"/>
  <path d="M 10 190 L 350 190 L 370 280 L -10 280 Z" fill="#4a1e60"/>
  <path d="M 10 190 L 350 190" stroke="${PINK}" stroke-width="3" opacity="0.6"/>
  ${[24, 336].map((x) => `<rect x="${x - 6}" y="120" width="12" height="80" rx="3" fill="#ff4fd8"/><circle cx="${x}" cy="120" r="8" fill="#ffb3ec"/>`).join("")}
  ${ropeY.map((y, k) => `<path d="M 24 ${y - 30 + k * 6} L 336 ${y - 30 + k * 6}" stroke="${["#ff4fd8", "#fff0fb", "#5ce1ff"][k]}" stroke-width="3" opacity="0.75"/>`).join("")}
  ${shadow(70, 252, 24)}${shadow(120, 236, 24)}${shadow(240, 236, 24)}${shadow(290, 252, 24)}
  ${critter(120, 212, 24, "#3fa9f5", { acc: "fin", mood: "determined", look: [0.9, 0] })}
  ${critter(70, 228, 24, "#5fd068", { acc: "leaf", mood: "cheer", look: [0.9, 0] })}
  ${critter(240, 212, 24, "#ff6a3d", { acc: "flame", mood: "determined", look: [-0.9, 0] })}
  ${critter(290, 228, 24, "#ffc93c", { acc: "propeller", mood: "cheer", look: [-0.9, 0] })}
  <circle cx="180" cy="210" r="18" fill="#fff0fb" opacity="0.5" filter="url(#bl8)"/>${sparkle(180, 210, 15, "#fff", 1)}${sparkle(194, 192, 6, GOLD, 0.9)}
  ${sky(3, 16, 0, 0, 360, 90)}
  ${motes(2, 8, 20, 90, 340, 260, ["#ffb3ec", "#ffd36b", "#9ad8ff"])}
  ${fadeT(W, H, "dT", 0.85, 0.36)}`);
};

const friends = () => {
  const W = 360, H = 280;
  return svg(W, H, `
  <defs><linearGradient id="fS" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#120c30"/><stop offset="1" stop-color="#2c1a50"/></linearGradient></defs>
  <rect width="${W}" height="${H}" fill="url(#fS)"/>
  ${sky(11, 20, 0, 0, 360, 110)}
  <path d="M -10 120 Q 180 100 370 122 L 370 160 L -10 160 Z" fill="#1c1238"/>
  ${crowd(52, { y: 128, rows: 2, x0: -10, x1: 370, cx: 180, curve: 8, step: 14, dark: -0.82, wave: 0.04 })}
  ${stringLights(-10, 96, 370, 96, 26, 10, ["#ffd36b", "#ff9ae6", "#5ce1ff", "#45f5a6"], 5)}
  <rect x="-10" y="170" width="380" height="120" fill="#24163e"/>
  <rect x="-10" y="170" width="380" height="10" fill="#3a2660"/>
  <path d="M 60 250 L 60 200 Q 60 184 76 184 L 284 184 Q 300 184 300 200 L 300 250 Z" fill="#6a3a8a" stroke="#1a0c2a" stroke-width="3"/>
  <rect x="44" y="214" width="272" height="44" rx="16" fill="#8a4aa8" stroke="#1a0c2a" stroke-width="3"/>
  <rect x="34" y="204" width="34" height="60" rx="14" fill="#7a4098" stroke="#1a0c2a" stroke-width="3"/><rect x="292" y="204" width="34" height="60" rx="14" fill="#7a4098" stroke="#1a0c2a" stroke-width="3"/>
  ${critter(126, 196, 30, "#3fa9f5", { acc: "fin", mood: "cheer", look: [0.6, -0.2] })}
  ${critter(234, 196, 30, "#ff7ac8", { acc: "ears", mood: "cheer", look: [-0.6, -0.2] })}
  <g transform="translate(180 150)"><circle r="26" fill="#ffd36b" opacity="0.3" filter="url(#bl8)"/>
  <rect x="-18" y="-14" width="36" height="30" rx="5" fill="#45f5a6" stroke="#0e3a2a" stroke-width="2.5"/><rect x="-4" y="-14" width="8" height="30" fill="#ffd36b"/>
  <path d="M 0 -14 q -14 -12 -16 -2 q 4 6 16 2 q 12 4 16 -2 q -2 -10 -16 2 Z" fill="#ffd36b" stroke="#8a5a10" stroke-width="2"/>
  <path d="M 4 -40 L -6 -24 L 1 -24 L -4 -12 L 8 -28 L 1 -28 L 6 -40 Z" fill="#5ce1ff" stroke="#0a3a5a" stroke-width="1.5"/></g>
  <path d="M 180 104 q -8 -10 -14 -2 q -4 8 14 18 q 18 -10 14 -18 q -6 -8 -14 2 Z" fill="#ff6a8a" stroke="#7a1a3a" stroke-width="2" opacity="0.9"/>
  ${motes(5, 8, 20, 100, 340, 260, ["#ffd36b", "#ff9ae6"])}
  ${fadeT(W, H, "fT", 0.85, 0.36)}`);
};

export const dir = "game/ui/versus_art";
export const size = [720, 240];
export const sizes = { vs_quick: [720, 200], vs_duo: [360, 280], vs_friends: [360, 280] };
export const many = { vs_ghost: ghostArena, vs_quick: quick, vs_duo: duo, vs_friends: friends };
export default ghostArena;

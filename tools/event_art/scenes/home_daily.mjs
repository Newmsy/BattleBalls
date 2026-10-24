// Home, Daily door header band (a strip of this scene): a little fairground at sunrise. A striped tent, string lights,
// a Trick Shot target on an easel, bouncy pads, and a storm cloud rolling in
// for Chaos week. Warm gold palette, calm on the left for the title.
import { blurs, rng, stringLights, sparkle } from "./_shop_charge_pad_glow_chest_parts.mjs";
import { critter, shadow, sky, motes } from "./_banner_parts.mjs";
import { shade } from "../../brand/parts.mjs";

const f = (n) => (+n).toFixed(1);

export const size = [720, 200];
export const dir = "game/ui/home_art";
const W = 720, H = 340;

function scene({ band = false } = {}) {
  const R = rng(9);
  const sx = 470, sy = 196; // sun
  let rays = "";
  for (let k = 0; k < 14; k++) {
    const a = -Math.PI + (k + 0.5) * (Math.PI / 14);
    rays += `<path d="M ${sx} ${sy} L ${f(sx + Math.cos(a - 0.05) * 420)} ${f(sy + Math.sin(a - 0.05) * 420)} L ${f(sx + Math.cos(a + 0.05) * 420)} ${f(sy + Math.sin(a + 0.05) * 420)} Z" fill="#ffe2a0" opacity="${k % 2 ? 0.05 : 0.09}"/>`;
  }
  // Tent: striped cone roof + drape, flag on top.
  const tx = 300, ty = 250;
  let stripes = "";
  for (let k = 0; k < 8; k++) {
    const a0 = tx - 96 + k * 24;
    stripes += `<path d="M ${tx} ${ty - 120} L ${a0} ${ty - 54} Q ${a0 + 12} ${ty - 46} ${a0 + 24} ${ty - 54} Z" fill="${k % 2 ? "#3a2a6a" : "#ffc85a"}"/>`;
  }
  const tent = `${shadow(tx, ty + 4, 110, 0.5)}
    <rect x="${tx - 86}" y="${ty - 56}" width="172" height="58" fill="#2a1e52"/>
    ${Array.from({ length: 7 }, (_, k) => `<rect x="${tx - 86 + k * 24.6}" y="${ty - 56}" width="12.3" height="58" fill="#ffb84e" opacity="0.85"/>`).join("")}
    <path d="M ${tx - 26} ${ty + 2} L ${tx - 26} ${ty - 44} Q ${tx} ${ty - 60} ${tx + 26} ${ty - 44} L ${tx + 26} ${ty + 2} Z" fill="#140c2c"/>
    <path d="M ${tx - 20} ${ty} L ${tx - 20} ${ty - 40} Q ${tx} ${ty - 52} ${tx + 20} ${ty - 40} L ${tx + 20} ${ty} Z" fill="#ffcf70" opacity="0.35"/>
    ${stripes}
    <path d="M ${tx - 96} ${ty - 54} ${Array.from({ length: 8 }, (_, k) => `Q ${tx - 84 + k * 24} ${ty - 40} ${tx - 72 + k * 24} ${ty - 54}`).join(" ")}" fill="#ffc85a" stroke="#8a5a1a" stroke-width="2"/>
    <path d="M ${tx} ${ty - 120} L ${tx - 96} ${ty - 54} M ${tx} ${ty - 120} L ${tx + 96} ${ty - 54}" stroke="#2a1a40" stroke-width="2.5" fill="none"/>
    <line x1="${tx}" y1="${ty - 120}" x2="${tx}" y2="${ty - 150}" stroke="#2a1a40" stroke-width="3"/>
    <path d="M ${tx} ${ty - 150} L ${tx + 26} ${ty - 142} L ${tx} ${ty - 134} Z" fill="#ff7ac8"/>`;
  // Target on an easel (Trick Shot).
  const ex = 560, ey = 214;
  const target = `${shadow(ex, 284, 40, 0.5)}
    <path d="M ${ex - 28} 284 L ${ex - 6} ${ey} M ${ex + 28} 284 L ${ex + 6} ${ey} M ${ex} 284 L ${ex} ${ey + 20}" stroke="#4a2e1e" stroke-width="5" stroke-linecap="round"/>
    ${[38, 30, 22, 14, 6].map((r, k) => `<circle cx="${ex}" cy="${ey}" r="${r}" fill="${["#f4e6c8", "#ff6a5a", "#f4e6c8", "#ff6a5a", "#ffd34e"][k]}" stroke="#5a2e2a" stroke-width="${k ? 1 : 3}"/>`).join("")}
    <line x1="${ex + 4}" y1="${ey - 3}" x2="${ex + 46}" y2="${ey - 30}" stroke="#3a2a1a" stroke-width="3.5" stroke-linecap="round"/>
    <path d="M ${ex + 42} ${ey - 34} l 12 -6 l -4 10 l 10 2 l -12 6 Z" fill="#5ce1ff"/>
    ${sparkle(ex - 4, ey - 6, 9, "#fff8dc", 0.9)}`;
  // Bouncy pads (Bounce Run): three springy mushroom caps along the lane.
  const pads = [[150, 300, 30], [214, 286, 24], [404, 296, 26]].map(([x, y, r]) => `${shadow(x, y + 6, r, 0.5)}
    <rect x="${x - r * 0.22}" y="${y - r * 0.2}" width="${r * 0.44}" height="${r * 0.5}" fill="#f4e6c8" stroke="#5a3a2a" stroke-width="2"/>
    <path d="M ${x - r} ${y - r * 0.15} Q ${x} ${y - r * 1.2} ${x + r} ${y - r * 0.15} Z" fill="#5ce1ff" stroke="#1a4a6a" stroke-width="2.5"/>
    <circle cx="${x - r * 0.35}" cy="${y - r * 0.55}" r="${r * 0.14}" fill="#e6fbff"/><circle cx="${x + r * 0.25}" cy="${y - r * 0.68}" r="${r * 0.1}" fill="#e6fbff"/>`).join("");
  // Chaos storm cloud far right.
  const cloud = `<g opacity="0.95">
    ${[[640, 70, 34], [672, 60, 28], [606, 78, 26], [690, 82, 24], [652, 88, 30]].map(([x, y, r]) => `<circle cx="${x}" cy="${y}" r="${r}" fill="#3a2a6a"/>`).join("")}
    ${[[630, 58, 18], [664, 50, 14]].map(([x, y, r]) => `<circle cx="${x}" cy="${y}" r="${r}" fill="#55408a"/>`).join("")}
    <path d="M 646 102 L 634 132 L 648 130 L 638 162 L 666 122 L 652 124 L 662 102 Z" fill="#ff7ac8"/>
    <path d="M 646 102 L 634 132 L 648 130 L 638 162 L 666 122 L 652 124 L 662 102 Z" fill="#ff7ac8" opacity="0.6" filter="url(#bl6)"/></g>`;
  // Critters: one bouncing mid-air over the pads, one cheering by the tent.
  const kids = `${critter(214, 214, 22, "#ff7ac8", { acc: "ears", mood: "cheer", tilt: -10 })}
    <path d="M 200 248 q 6 10 0 18 M 226 250 q -4 10 2 16" stroke="#fff3c4" stroke-width="2" fill="none" opacity="0.6" stroke-linecap="round"/>
    ${shadow(470, 296, 26, 0.55)}${critter(470, 268, 26, "#ffc93c", { acc: "propeller", mood: "happy", look: [0.5, 0], rim: "#ffe2a0", rimSide: -1 })}`;
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${band ? 200 : H}" viewBox="0 ${band ? 140 : 0} ${W} ${band ? 200 : H}">${blurs()}
  <defs>
    <linearGradient id="dfSky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#151036"/><stop offset="0.45" stop-color="#4a2a5e"/><stop offset="0.75" stop-color="#c2644a"/><stop offset="1" stop-color="#f0a24e"/></linearGradient>
    <radialGradient id="dfSun" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#fff4d0"/><stop offset="0.6" stop-color="#ffd36b"/><stop offset="1" stop-color="#ffb347"/></radialGradient>
    <linearGradient id="dfGround" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3a2448"/><stop offset="1" stop-color="#1a1230"/></linearGradient>
    <linearGradient id="dfL" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#0D0F26" stop-opacity="0.7"/><stop offset="0.36" stop-color="#0D0F26" stop-opacity="0"/></linearGradient>
  </defs>
  <rect width="${W}" height="${H}" fill="url(#dfSky)"/>
  ${sky(4, 30, 0, 0, 720, 90)}
  ${rays}
  <circle cx="${sx}" cy="${sy}" r="80" fill="#ffd36b" opacity="0.35" filter="url(#bl24)"/>
  <circle cx="${sx}" cy="${sy}" r="46" fill="url(#dfSun)"/>
  <path d="M 0 216 Q 120 186 240 206 Q 340 222 430 200 Q 560 176 720 204 L 720 340 L 0 340 Z" fill="#5a3058"/>
  <path d="M 0 236 Q 160 218 320 234 Q 480 250 720 226 L 720 340 L 0 340 Z" fill="url(#dfGround)"/>
  <path d="M 90 340 Q 260 250 520 252 Q 640 254 720 270 L 720 340 Z" fill="#2a1a3e" opacity="0.6"/>
  ${band ? "" : cloud}
  <g transform="${band ? "translate(245 75) scale(0.75)" : ""}">
  ${stringLights(120, 150, 400, 160, 22, 12, ["#ffd36b", "#ff7ac8", "#5ce1ff", "#7ee08a"], 5)}
  ${stringLights(400, 160, 720, 132, 18, 12, ["#5ce1ff", "#ffd36b", "#ff7ac8"], 5)}
  ${tent}${pads}${target}${kids}</g>
  ${motes(8, 22, 0, 120, 720, 320, ["#ffe2a0", "#ffd36b"])}
  <rect width="${W}" height="${H}" fill="url(#dfL)"/>${band ? `<rect y="140" width="${W}" height="200" fill="url(#dfL)"/>` : ""}
  </svg>`;
}

// The door shows a 720x200 strip of the scene with the action pushed right.
export default () => scene({ band: true });

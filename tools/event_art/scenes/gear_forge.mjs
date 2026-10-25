// The Armory: the Anvil King's forge. A big anvil glowing with a fresh piece,
// the hammer resting against it, the forge mouth roaring behind, racks of
// shields and cores on the walls. The Merge popup's backdrop: the new piece
// is placed on the anvil (around 470,190) by upgrade_popup.gd.
import { critter, shadow, motes, shade, rng } from "./_banner_parts.mjs";
import { blurs } from "./_shop_charge_pad_glow_chest_parts.mjs";
import { f } from "./_map_token.mjs";

export const size = [720, 340];
export const dir = "game/ui/gear_art";
const INK = "#14102e";

function anvil(x, y, s) {
  return `<g transform="translate(${x} ${y}) scale(${s})">
    <path d="M -70 0 L 70 0 Q 96 -2 110 -22 L 60 -22 L 60 -40 L -60 -40 L -60 -22 Q -90 -22 -70 0 Z" fill="#4a4e78" stroke="${INK}" stroke-width="4" stroke-linejoin="round"/>
    <path d="M -60 -40 L 60 -40 L 60 -32 L -60 -32 Z" fill="#8a90b8"/>
    <path d="M -36 0 L 36 0 L 28 30 L -28 30 Z" fill="#33365a" stroke="${INK}" stroke-width="4"/>
    <path d="M -50 30 L 50 30 L 58 46 L -58 46 Z" fill="#2a2c4a" stroke="${INK}" stroke-width="4"/>
    <path d="M -56 -38 L 20 -38" stroke="#c8cde8" stroke-width="3" opacity="0.7"/></g>`;
}

export default function () {
  const R = rng(77);
  let sparks = "";
  for (let k = 0; k < 26; k++) {
    const a = -Math.PI / 2 + (R() - 0.5) * 2.4, d = 30 + R() * 90;
    sparks += `<line x1="${f(470 + Math.cos(a) * d * 0.6)}" y1="${f(196 + Math.sin(a) * d * 0.6)}" x2="${f(470 + Math.cos(a) * d)}" y2="${f(196 + Math.sin(a) * d)}" stroke="${R() < 0.5 ? "#ffd36b" : "#ff8a3d"}" stroke-width="${f(1.5 + R() * 2)}" stroke-linecap="round" opacity="${f(0.5 + R() * 0.5)}"/>`;
  }
  const rack = (x, y) => `<rect x="${x}" y="${y}" width="120" height="8" rx="3" fill="#5a3a2a" stroke="${INK}" stroke-width="2"/>
    <circle cx="${x + 24}" cy="${y - 14}" r="13" fill="#3d9bff" stroke="${INK}" stroke-width="2.5"/><circle cx="${x + 24}" cy="${y - 14}" r="6" fill="#e8fbff"/>
    <circle cx="${x + 60}" cy="${y - 14}" r="13" fill="#b366ff" stroke="${INK}" stroke-width="2.5"/><circle cx="${x + 60}" cy="${y - 14}" r="6" fill="#f4e6ff"/>
    <circle cx="${x + 96}" cy="${y - 14}" r="13" fill="#ff4a64" stroke="${INK}" stroke-width="2.5"/><circle cx="${x + 96}" cy="${y - 14}" r="6" fill="#ffd0d8"/>`;
  const shieldOnWall = (x, y, col) => `<path d="M ${x} ${y - 26} Q ${x + 14} ${y - 22} ${x + 22} ${y - 22} Q ${x + 22} ${y + 4} ${x} ${y + 26} Q ${x - 22} ${y + 4} ${x - 22} ${y - 22} Q ${x - 14} ${y - 22} ${x} ${y - 26} Z" fill="${col}" stroke="${INK}" stroke-width="3"/><path d="M ${x - 3} ${y - 16} h 6 v 10 h 8 v 6 h -8 v 14 h -6 v -14 h -8 v -6 h 8 Z" fill="#e8eef8" opacity="0.9"/>`;
  return `<svg xmlns="http://www.w3.org/2000/svg" width="720" height="340" viewBox="0 0 720 340">${blurs()}
  <defs>
    <linearGradient id="fgWall" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#1a1236"/><stop offset="1" stop-color="#3a1c3a"/></linearGradient>
    <radialGradient id="fgMouth" cx="0.5" cy="0.6" r="0.6"><stop offset="0" stop-color="#fff0b0"/><stop offset="0.35" stop-color="#ffb347"/><stop offset="0.75" stop-color="#e8402a"/><stop offset="1" stop-color="#5a1a2a"/></radialGradient>
    <radialGradient id="fgHot" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#ffd36b" stop-opacity="0.7"/><stop offset="1" stop-color="#ff6a2a" stop-opacity="0"/></radialGradient>
    <linearGradient id="fgL" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#0D0F26" stop-opacity="0.85"/><stop offset="0.4" stop-color="#0D0F26" stop-opacity="0"/></linearGradient>
  </defs>
  <rect width="720" height="340" fill="url(#fgWall)"/>
  ${Array.from({ length: 7 }, (_, r) => Array.from({ length: 13 }, (_, c) => `<rect x="${c * 60 - (r % 2) * 30}" y="${r * 34}" width="57" height="31" rx="4" fill="${shade("#2e2250", -R() * 0.3)}"/>`).join("")).join("")}
  <path d="M 380 250 L 380 120 Q 470 40 560 120 L 560 250 Z" fill="#20142e" stroke="#120a20" stroke-width="6"/>
  <path d="M 400 250 L 400 130 Q 470 66 540 130 L 540 250 Z" fill="url(#fgMouth)"/>
  ${[420, 450, 480, 510].map((x) => `<path d="M ${x} 250 Q ${x + 10} ${200 - (x % 3) * 10} ${x + 4} 170 Q ${x + 18} 210 ${x + 24} 250 Z" fill="#fff4c0" opacity="0.6"/>`).join("")}
  <circle cx="470" cy="190" r="150" fill="url(#fgHot)"/>
  ${rack(220, 110)}${rack(600, 150)}
  ${shieldOnWall(620, 70, "#2fa868")}${shieldOnWall(680, 70, "#7a4ad8")}${shieldOnWall(250, 50, "#e8402a")}
  <rect x="-10" y="250" width="740" height="100" fill="#160e26"/>
  <path d="M -10 250 L 740 250" stroke="#ff8a3d" stroke-width="2" opacity="0.5"/>
  ${Array.from({ length: 13 }, (_, k) => `<path d="M ${k * 60} 250 L ${k * 60 - 30} 340" stroke="#24183a" stroke-width="2"/>`).join("")}
  <ellipse cx="470" cy="300" rx="130" ry="18" fill="#000" opacity="0.5"/>
  ${anvil(470, 254, 1.05)}
  <ellipse cx="470" cy="206" rx="34" ry="12" fill="#ffd36b" opacity="0.8" filter="url(#bl8)"/>
  <path d="M 450 210 Q 446 180 470 176 Q 494 180 490 210 Z" fill="#ffb347" stroke="${INK}" stroke-width="3"/>
  <path d="M 458 204 Q 456 186 470 184 Q 484 186 482 204 Z" fill="#fff0b0"/>
  ${sparks}
  <g transform="rotate(-28 600 260)"><rect x="594" y="196" width="12" height="80" rx="4" fill="#8a5a3a" stroke="${INK}" stroke-width="3"/><rect x="572" y="178" width="56" height="28" rx="6" fill="#9aa0b8" stroke="${INK}" stroke-width="3"/><rect x="572" y="178" width="56" height="8" rx="4" fill="#d8dcea"/></g>
  ${shadow(330, 300, 34, 0.6)}<g data-layer="king" data-move="idle 3 0.7 0">${critter(330, 266, 34, "#ff8a3d", { acc: "horns", mood: "cheer", look: [0.8, -0.3], rim: "#ffd36b", rimSide: 1 })}
  <path d="M 304 236 L 310 220 L 320 232 L 330 214 L 340 232 L 350 220 L 356 236 Z" fill="#ffd36b" stroke="${INK}" stroke-width="2.5" stroke-linejoin="round"/></g>
  ${motes(14, 16, 360, 40, 700, 240, ["#ffd36b", "#ff8a3d", "#fff0b0"])}
  <rect width="720" height="340" fill="url(#fgL)"/>
  </svg>`;
}



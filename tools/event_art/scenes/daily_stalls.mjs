// Daily board tile headers (game/ui/screens/week_screen.gd): one painted fair
// stall per event, 360x210, shown cover-cropped. Same sunrise fair as the
// Home Daily band. Fight of the Day's ring is empty: the game stands today's
// two critters in it.
import { svg, dawn, booth, boothDefs, target, pad, critter, shadow, sparkle, stringLights, motes, bottomFade, rng, f, LIGHTS, GOLD, CYAN, PINK } from "./_daily_parts.mjs";

export const size = [360, 210];
export const dir = "game/ui/home_art";
const W = 360, H = 210;

const lights = (y = 18) => stringLights(-10, y, 370, y - 6, 10, 9, LIGHTS, 4);

const trick = () => svg(W, H, `${boothDefs("#ffd36b")}${dawn("tr", W, H, 120, { sx: 290, sr: 28 })}
  ${booth(70, 290, 66, 182, "#ff6a5a", "#f4e6c8")}
  ${target(220, 120, 1.1)}
  <path d="M 106 158 L 160 92 L 214 122" fill="none" stroke="#fff3c4" stroke-width="3" stroke-dasharray="2 8" stroke-linecap="round" opacity="0.85"/>
  <rect x="152" y="84" width="16" height="16" rx="4" fill="#5ce1ff" stroke="#1a4a6a" stroke-width="2" transform="rotate(45 160 92)"/>
  ${sparkle(160, 92, 10, "#e6fbff", 0.9)}${sparkle(214, 118, 10, "#fff8dc", 0.95)}
  ${critter(100, 150, 20, "#ffc93c", { acc: "propeller", mood: "determined", look: [0.7, -0.6] })}
  ${lights()}${motes(3, 8, 0, 40, W, 200, ["#ffe2a0"])}${bottomFade("trF", W, H)}`);

const bounce = () => {
  const arc = "M 40 168 Q 80 70 122 160 Q 162 90 204 150 Q 246 96 288 136";
  return svg(W, H, `${dawn("bo", W, H, 118, { sx: 120, sr: 30 })}
  <path d="M -10 210 Q 140 150 370 160 L 370 210 Z" fill="#2a1a3e" opacity="0.7"/>
  ${pad(40, 176, 26)}${pad(122, 166, 22)}${pad(204, 156, 19)}${pad(288, 142, 16)}
  <line x1="326" y1="140" x2="326" y2="80" stroke="#3a2a1a" stroke-width="4"/>
  <path d="M 326 80 L 352 90 L 326 100 Z" fill="${GOLD}" stroke="#7a4a1a" stroke-width="2"/>
  <path d="${arc}" fill="none" stroke="#e6fbff" stroke-width="3" stroke-dasharray="2 8" stroke-linecap="round" opacity="0.8"/>
  ${critter(164, 100, 20, "#ff7ac8", { acc: "ears", mood: "cheer", tilt: 14 })}
  <path d="M 150 128 q 4 10 -2 16 M 172 130 q -2 10 4 14" stroke="#fff3c4" stroke-width="2" fill="none" opacity="0.6" stroke-linecap="round"/>
  ${sparkle(250, 110, 8, "#fff", 0.8)}${lights(14)}${motes(5, 10, 0, 30, W, 200, ["#ffe2a0", "#5ce1ff"])}${bottomFade("boF", W, H)}`);
};

// A little boxing ring under two crossing spotlights; the corners are empty
// (the game puts today's two critters there).
const fotd = () => {
  const R = rng(11);
  let crowd = "";
  for (let k = 0; k < 16; k++) {
    const x = k * 24 + R() * 8 - 6, y = 112 + R() * 10, r = 10 + R() * 5;
    crowd += `<circle cx="${f(x)}" cy="${f(y)}" r="${f(r)}" fill="${["#2a1a48", "#34225a", "#24163e"][k % 3]}"/>`;
  }
  return svg(W, H, `${dawn("fo", W, H, 104, { sx: 180, sr: 26, rays: false, tint: "#8a3a5a" })}
  ${crowd}
  <path d="M 70 0 L 150 190 L 210 190 Z" fill="#fff4d0" opacity="0.08"/><path d="M 290 0 L 150 190 L 210 190 Z" fill="#fff4d0" opacity="0.08"/>
  <path d="M 30 196 L 70 140 L 290 140 L 330 196 Z" fill="#5a3a7a" stroke="#1a1030" stroke-width="3"/>
  <path d="M 70 140 L 290 140 L 300 152 L 60 152 Z" fill="#7a5aa0"/>
  <ellipse cx="108" cy="166" rx="44" ry="12" fill="#fff4d0" opacity="0.25" filter="url(#bl4)"/>
  <ellipse cx="252" cy="166" rx="44" ry="12" fill="#fff4d0" opacity="0.25" filter="url(#bl4)"/>
  ${[[40, 196], [74, 140], [286, 140], [320, 196]].map(([x, y], k) => `<rect x="${x - 5}" y="${y - 58}" width="10" height="58" rx="3" fill="${k % 3 ? CYAN : PINK}" stroke="#1a1030" stroke-width="2"/>`).join("")}
  ${[0, 1, 2].map((j) => `<path d="M 74 ${100 + j * 14} L 286 ${100 + j * 14}" stroke="${["#ffd36b", "#ff7ac8", "#ffd36b"][j]}" stroke-width="2.5" opacity="0.9"/>
    <path d="M 40 ${156 + j * 14} L 74 ${100 + j * 14} M 320 ${156 + j * 14} L 286 ${100 + j * 14}" stroke="${["#ffd36b", "#ff7ac8", "#ffd36b"][j]}" stroke-width="2.5" opacity="0.9"/>`).join("")}
  ${sparkle(180, 128, 16, "#fff8dc", 0.95)}${sparkle(180, 128, 30, GOLD, 0.25)}
  <circle cx="70" cy="-4" r="16" fill="#fff4d0" opacity="0.7" filter="url(#bl6)"/><circle cx="290" cy="-4" r="16" fill="#fff4d0" opacity="0.7" filter="url(#bl6)"/>
  ${motes(7, 8, 0, 20, W, 140, ["#ffe2a0"])}${bottomFade("foF", W, H, 0.7)}`);
};

// Bracket: a trophy on a pedestal at the top of a lit bracket board.
const bracket = () => {
  const ln = (d) => `<path d="${d}" fill="none" stroke="#ffd36b" stroke-width="3" stroke-linecap="round" opacity="0.85"/>`;
  return svg(W, H, `${dawn("br", W, H, 128, { sx: 180, sr: 30, tint: "#7a3a6a" })}
  <rect x="40" y="56" width="280" height="122" rx="10" fill="#1e1438" stroke="#5a3a7a" stroke-width="3"/>
  ${ln("M 60 80 L 90 80 L 90 104 L 60 104 M 90 92 L 120 92 L 120 140 M 60 128 L 90 128 L 90 152 L 60 152 M 90 140 L 150 140")}
  ${ln("M 300 80 L 270 80 L 270 104 L 300 104 M 270 92 L 240 92 L 240 140 M 300 128 L 270 128 L 270 152 L 300 152 M 270 140 L 210 140")}
  ${[[60, 80], [60, 104], [60, 128], [60, 152], [300, 80], [300, 104], [300, 128], [300, 152]].map(([x, y], k) => `<circle cx="${x}" cy="${y}" r="7" fill="${["#ff7ac8", "#5fd068", "#7b77ff", "#ffc93c", "#5ce1ff", "#ff6a3d", "#b07cff", "#8fe6ff"][k]}" stroke="#14102e" stroke-width="2"/>`).join("")}
  ${shadow(180, 176, 40, 0.6)}
  <path d="M 156 176 L 204 176 L 198 160 L 162 160 Z" fill="#6a3e2a" stroke="#2a160e" stroke-width="2"/>
  <rect x="174" y="136" width="12" height="26" fill="#c89a3e"/>
  <path d="M 152 92 L 208 92 L 204 116 Q 180 142 156 116 Z" fill="#ffd36b" stroke="#7a4a1a" stroke-width="3"/>
  <path d="M 152 98 Q 134 100 140 114 Q 146 124 158 120 M 208 98 Q 226 100 220 114 Q 214 124 202 120" fill="none" stroke="#c89a3e" stroke-width="4"/>
  <path d="M 162 96 L 166 112" stroke="#fff4d0" stroke-width="4" stroke-linecap="round" opacity="0.8"/>
  <circle cx="180" cy="110" r="44" fill="#ffd36b" opacity="0.2" filter="url(#bl16)"/>
  ${sparkle(204, 92, 9, "#fff8dc", 0.95)}${lights()}${motes(17, 8, 0, 40, W, 200, ["#ffe2a0"])}${bottomFade("brF", W, H)}`);
};

export const many = { daily_trick: trick, daily_bounce: bounce, daily_fotd: fotd, daily_bracket: bracket };
export default trick;

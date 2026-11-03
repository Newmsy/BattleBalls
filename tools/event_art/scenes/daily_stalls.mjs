// Bounce Run door painting (game/ui/home_art/daily_bounce.png): a painted
// fair stall, 360x210, shown cover-cropped. Same sunrise fair as the old
// Daily board (removed 2026-11-03, with its Trick Shot, Fight of the Day and
// Bracket stalls).
import { svg, dawn, booth, boothDefs, target, pad, critter, shadow, sparkle, stringLights, motes, bottomFade, rng, f, LIGHTS, GOLD, CYAN, PINK } from "./_daily_parts.mjs";

export const size = [360, 210];
export const dir = "game/ui/home_art";
const W = 360, H = 210;

const lights = (y = 18) => stringLights(-10, y, 370, y - 6, 10, 9, LIGHTS, 4);

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

export const many = { daily_bounce: bounce };
export default bounce;

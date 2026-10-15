// The app icon options and the art built from the chosen one.
import { arena, ball, eye, brow, wince, grin, burst, streaks, VIOLET } from "./parts.mjs";

const S = 1024;
const svg = (w, h, body) => `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">${body}</svg>`;

// The mascot: a violet critter ball mid-bounce, grinning, eyes up and to
// the right where it's heading. (cx, cy) centre, r radius.
export function hero(cx, cy, r, { trail = true } = {}) {
  const col = "#7b5cff";
  const t = trail
    ? streaks(
        [
          [cx - r * 1.42, cy + r * 0.58, cx - r * 1.04, cy + r * 0.36, 0.75],
          [cx - r * 1.22, cy + r * 0.98, cx - r * 0.84, cy + r * 0.74, 0.5],
          [cx - r * 1.5, cy + r * 0.14, cx - r * 1.14, cy - r * 0.06, 0.35],
        ],
        "#b9a8ff",
        r * 0.11,
      )
    : "";
  const ey = cy - r * 0.16;
  return `${t}
  ${ball(cx, cy, r, col, { sx: 1.03, sy: 0.97 })}
  ${eye(cx - r * 0.33, ey, r * 0.23, r * 0.28, 0.55, -0.45, r * 0.12)}
  ${eye(cx + r * 0.33, ey, r * 0.23, r * 0.28, 0.55, -0.45, r * 0.12)}
  ${brow(cx - r * 0.56, ey - r * 0.38, cx - r * 0.16, ey - r * 0.27, r * 0.09)}
  ${brow(cx + r * 0.56, ey - r * 0.38, cx + r * 0.16, ey - r * 0.27, r * 0.09)}
  ${grin(cx + r * 0.02, cy + r * 0.25, r * 0.38, r * 0.3)}`;
}

// A: "Hero" - one big mascot ball bouncing in the arena.
export const iconHero = () => svg(S, S, `${arena(S)}${hero(560, 545, 285)}${burst(880, 300, 66, 8, 0.3)}`);

// B: "Clash" - two critters smack together in a star burst.
export const iconClash = () => {
  const r = 225;
  const ly = 560;
  return svg(S, S, `${arena(S)}
    ${ball(318, ly, r, "#ffb020", { sx: 0.94, sy: 1.04 })}
    ${eye(260, ly - 50, 48, 58, 0.8, -0.1, 26)}${eye(370, ly - 50, 48, 58, 0.8, -0.1, 26)}
    ${brow(210, ly - 128, 290, ly - 104, 20)}${brow(420, ly - 128, 340, ly - 104, 20)}
    ${grin(316, ly + 50, 82, 64)}
    ${ball(706, ly, r, "#27c8ff", { sx: 0.94, sy: 1.04 })}
    ${wince(654, ly - 48, 34, -1, 20)}${wince(762, ly - 48, 34, 1, 20)}
    <ellipse cx="708" cy="${ly + 70}" rx="30" ry="24" fill="#14102e"/>
    ${burst(512, ly - 30, 150, 9, -0.2)}`);
};

// C: "Bank shot" - a ball banks off the glowing wall along a dotted aim line.
export const iconBank = () => {
  const dots = [];
  for (let k = 0; k < 7; k++) {
    const t = k / 6;
    dots.push(`<circle cx="${180 + t * (880 - 180)}" cy="${880 - t * (520 - 0) * 1}" r="${20 - k * 1.5}" fill="#c2b5ff" opacity="${0.4 + t * 0.5}"/>`);
  }
  return svg(S, S, `${arena(S)}
    ${dots.join("")}
    ${burst(900, 360, 70, 8, 0)}
    ${ball(600, 300, 200, "#ff4f9a")}
    ${eye(545, 270, 46, 56, -0.6, -0.5, 24)}${eye(655, 270, 46, 56, -0.6, -0.5, 24)}
    ${grin(605, 350, 72, 56)}`);
};

export const OPTIONS = { hero: iconHero, clash: iconClash, bank: iconBank };

// The default (chosen) icon.
export const icon = iconHero;

// Android adaptive icon layers (432 px, the safe zone is the middle 264 px).
export const adaptiveBackground = () => svg(432, 432, arena(432, { border: false }));
export const adaptiveForeground = () => svg(432, 432, `${hero(222, 220, 92)}${burst(298, 140, 22, 8, 0.3)}`);
// Logo lockup: mascot over the wordmark, transparent background. Used as the
// boot splash and on the web loading screen.
export const logo = (font) =>
  svg(1024, 1024, `<defs><style>@font-face { font-family: Chakra; src: url("${font}"); }</style>
    <filter id="tg" x="-20%" y="-50%" width="140%" height="200%"><feGaussianBlur stdDeviation="14"/></filter></defs>
    ${hero(530, 400, 230)}
    <g font-family="Chakra" font-size="116" text-anchor="middle" letter-spacing="4">
      <text x="512" y="820" fill="${VIOLET}" filter="url(#tg)" opacity="0.9">BATTLE BALLS</text>
      <text x="512" y="820" fill="#f0eeff" stroke="#2b2760" stroke-width="3" paint-order="stroke">BATTLE BALLS</text>
    </g>`);

// Google Play feature graphic, 1024x500.
export const featureGraphic = (font) =>
  svg(1024, 500, `<defs><style>@font-face { font-family: Chakra; src: url("${font}"); }</style>
    <filter id="tg" x="-20%" y="-50%" width="140%" height="200%"><feGaussianBlur stdDeviation="10"/></filter>
    <clipPath id="c"><rect width="1024" height="500"/></clipPath></defs>
    <g clip-path="url(#c)">${arena(1024, { border: false })}</g>
    <rect x="24" y="24" width="976" height="452" rx="60" fill="none" stroke="${VIOLET}" stroke-width="6" opacity="0.8"/>
    ${hero(250, 250, 150)}
    ${ball(948, 104, 40, "#ffb020")}${ball(944, 398, 36, "#27c8ff")}${ball(890, 446, 20, "#5cc95a")}
    <g font-family="Chakra" text-anchor="middle">
      <text x="626" y="246" font-size="112" fill="${VIOLET}" filter="url(#tg)" letter-spacing="4">BATTLE</text>
      <text x="626" y="246" font-size="112" fill="#f0eeff" letter-spacing="4">BATTLE</text>
      <text x="626" y="366" font-size="112" fill="${VIOLET}" filter="url(#tg)" letter-spacing="4">BALLS</text>
      <text x="626" y="366" font-size="112" fill="#f0eeff" letter-spacing="4">BALLS</text>
    </g>`);

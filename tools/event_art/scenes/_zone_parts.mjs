// Shared pieces for the Home screen's Adventure door paintings (home_zone_*):
// one 720x440 painting per campaign zone. Each shows the zone's world with a
// winding path of stage stones up to the zone's gate, its guardian beside the
// gate and a small hero critter setting off at the front. The door puts its
// title over the top band and Continue over the bottom, so the gate, the
// guardian and the zone's landmark sit in the middle band (y ~100-260),
// centre-right. No text in the art.
import { blurs, rng } from "./_shop_charge_pad_glow_chest_parts.mjs";
import { critter, shadow, sky, motes } from "./_banner_parts.mjs";
import { shade } from "../../brand/parts.mjs";

export const W = 720, H = 440;
export const f = (n) => (+n).toFixed(1);
export { blurs, rng, critter, shadow, sky, motes, shade };

// The stage path: 11 stones from the front left up to the gate (gx, gy).
// stone: { top, side, rim, glow } colours; lit stones carry a soft glow.
export function stagePath(gx, gy, { top = "#3a2a50", hi = "#55406e", side = "#14091f", glow = "#ffd36b", halo = "#ffb347", from = [118, 418], wiggle = 30, n = 11 } = {}) {
  let out = "";
  for (let k = 0; k < n; k++) {
    const t = k / (n - 1);
    const x = from[0] + t * (gx - 40 - from[0]) + Math.sin(t * 3.2) * wiggle;
    const y = from[1] - t * (from[1] - gy - 6) - Math.sin(t * Math.PI) * 18;
    const s = 1 - t * 0.55, w = 34 * s, h = 12 * s;
    out += `<ellipse cx="${f(x)}" cy="${f(y + h * 0.7)}" rx="${f(w * 1.05)}" ry="${f(h * 0.8)}" fill="${side}"/>
      <ellipse cx="${f(x)}" cy="${f(y)}" rx="${f(w)}" ry="${f(h)}" fill="${top}" stroke="${side}" stroke-width="2"/>
      <ellipse cx="${f(x - w * 0.15)}" cy="${f(y - h * 0.25)}" rx="${f(w * 0.6)}" ry="${f(h * 0.45)}" fill="${hi}"/>
      <ellipse cx="${f(x)}" cy="${f(y - 2)}" rx="${f(w * 0.7)}" ry="${f(h * 1.2)}" fill="${halo}" opacity="0.3" filter="url(#bl6)"/>
      <ellipse cx="${f(x)}" cy="${f(y)}" rx="${f(w * 0.4)}" ry="${f(h * 0.38)}" fill="${glow}" opacity="0.85"/>`;
  }
  return out;
}

// The player's little hero on the first stones, looking up the path.
export const hero = (rim = "#ffb347", x = 150, y = 398) =>
  `${shadow(x, y + 30, 26, 0.6)}${critter(x, y, 26, "#7b77ff", { acc: "antenna", mood: "determined", look: [0.7, -0.3], rim, rimSide: 1 })}`;

// The zone's guardian on a little rise beside the gate, idling on its own
// living layer (render.mjs).
export const guardian = (x, y, col, acc, rim, rock = "#2a1840") =>
  `${shadow(x, y + 40, 30, 0.6)}<path d="M ${x - 28} ${y + 44} Q ${x} ${y + 14} ${x + 30} ${y + 44} Z" fill="${rock}" stroke="#0b0614" stroke-width="2"/>
  <g data-layer="guardian" data-move="idle 3 0.6 0">${critter(x, y, 26, col, { acc, mood: "determined", look: [-0.6, 0.2], rim, rimSide: -1 })}</g>`;

// Darkens the left side a little so the door title reads over any painting.
export const leftFade = () => `<defs><linearGradient id="zpL" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#0D0F26" stop-opacity="0.6"/><stop offset="0.36" stop-color="#0D0F26" stop-opacity="0"/></linearGradient></defs>
  <rect width="${W}" height="${H}" fill="url(#zpL)"/>`;

export const svg = (body) => `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${blurs()}${body}${leftFade()}</svg>`;

// Scattered irregular plates (lava crust, ice floes, floor tiles).
export function plates(seed, n, y0, y1, { fill, stroke, so = 0.6, size = 30 }) {
  const R = rng(seed);
  let out = "";
  for (let k = 0; k < n; k++) {
    const x = R() * 760 - 20, y = y0 + R() * (y1 - y0), s = size * (0.5 + R()) * (0.5 + (y - y0) / (y1 - y0));
    const pts = Array.from({ length: 6 }, (_, j) => {
      const a = (j / 6) * Math.PI * 2 + R() * 0.5, rr = s * (0.6 + R() * 0.5);
      return `${f(x + Math.cos(a) * rr)},${f(y + Math.sin(a) * rr * 0.38)}`;
    }).join(" ");
    out += `<polygon points="${pts}" fill="${fill}" stroke="${stroke}" stroke-width="1.6" stroke-opacity="${so}"/>`;
  }
  return out;
}

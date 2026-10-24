// Shared bits for the family habitat backdrops (hab_*.mjs), 780x460.
// Stage: empty lit spot centred (200, 330); a ball critter r~110 is overlaid
// by the game at (200, 250). Right half (x > 420) is calm for stat text.
// Bottom ~15% fades to #0D0F26.
import { critter, shadow, f } from "./_p.mjs";

export const W = 780, H = 460;
export const SX = 200, SY = 330;

// Right-side calm-down and bottom fade, drawn last.
export function fades(id, { right = 0.5, left = 0.0 } = {}) {
  return `<defs>
    <linearGradient id="${id}R" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#0D0F26" stop-opacity="${left}"/>
      <stop offset="0.12" stop-color="#0D0F26" stop-opacity="0"/>
      <stop offset="0.5" stop-color="#0D0F26" stop-opacity="0"/>
      <stop offset="0.68" stop-color="#0D0F26" stop-opacity="${f(right * 0.7)}"/>
      <stop offset="1" stop-color="#0D0F26" stop-opacity="${right}"/></linearGradient>
    <linearGradient id="${id}B" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#0D0F26" stop-opacity="0"/>
      <stop offset="0.78" stop-color="#0D0F26" stop-opacity="0"/>
      <stop offset="0.9" stop-color="#0D0F26" stop-opacity="0.8"/>
      <stop offset="1" stop-color="#0D0F26" stop-opacity="1"/></linearGradient>
  </defs>
  <rect width="${W}" height="${H}" fill="url(#${id}R)"/>
  <rect width="${W}" height="${H}" fill="url(#${id}B)"/>`;
}

// In-context check: the big critter the game overlays on the stage.
export function withHero(fn, col, acc, rim) {
  return () => fn().replace(/<\/svg>\s*$/, `${shadow(SX, SY + 26, 92, 0.55)}${critter(SX, 250, 110, col, { acc, mood: "happy", look: [0.3, 0.1], rim, rimSide: 1 })}</svg>`);
}

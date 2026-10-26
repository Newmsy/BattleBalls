// The Rift screen's tear (game/ui/home_art/rift_tear.png), on a transparent
// background so it hangs over whichever family's home painting you picked
// (game/ui/art/families): the Glitch tear with the nine family shards round
// it and a magenta-cyan glow on the ground under it. Static, drawn once.
import { blurs } from "./_shop_charge_pad_glow_chest_parts.mjs";
import { tear, shards, MG, CY } from "./_rift_parts.mjs";

export const size = [360, 420];
export const transparent = true;
export const dir = "game/ui/home_art";

export default function () {
  const cx = 180, cy = 190;
  return `<svg xmlns="http://www.w3.org/2000/svg" width="360" height="420" viewBox="0 0 360 420">${blurs()}
  <ellipse cx="${cx}" cy="384" rx="120" ry="14" fill="${MG}" opacity="0.4" filter="url(#bl8)"/>
  <ellipse cx="${cx}" cy="384" rx="64" ry="7" fill="${CY}" opacity="0.55" filter="url(#bl4)"/>
  ${tear(cx, cy, 170, 300, 17, 0.55)}
  ${shards(cx, cy + 20, 150, 46, 13, 1.35)}
  </svg>`;
}

// The Summon tab's backdrop: the Portal Hall. The carved stone portal (a gem
// per family) stands on its steps in a moonlit hall, and an egg of every
// family rests on a stone pedestal in a crescent in front of it; the eggs
// idle as living layers. The game crops it to the room it has and draws the
// spinning vortex over the portal's opening (PORTAL below, mirrored by
// summon_screen.gd _Hall), so the portal itself stays still here.
import { shade } from "../../brand/parts.mjs";
import { blurs, rng } from "./_shop_charge_pad_glow_chest_parts.mjs";
import { motes } from "./_banner_parts.mjs";
import { egg } from "./_egg_parts.mjs";
import { portal, pedestal, lantern, hall, vines } from "./_summon_parts.mjs";

export const size = [720, 760];
export const dir = "game/ui/art/summon";
export const PORTAL = [360, 300, 170 * 0.74];
const f = (n) => (+n).toFixed(1);

export default function () {
  const W = 720, H = 760, floorY = 520;
  const px = 360, py = 300, pr = 170;
  // Nine families in a crescent, back row first. Each row is one living
  // layer (bobbing out of step), the Legendary egg in the middle breathes.
  const rows = [
    { layer: "back", move: "idle 3 0.45 0", eggs: [["spooky", "uncommon", 96, 548, 84], ["tech", "common", 624, 548, 84], ["sea", "rare", 196, 604, 92], ["sweet", "uncommon", 524, 604, 92]] },
    { layer: "front", move: "idle 3 0.45 0.5", eggs: [["nature", "common", 64, 672, 100], ["toybox", "epic", 656, 672, 100], ["frost", "rare", 214, 724, 108], ["fire", "epic", 506, 724, 108]] },
    { layer: "legend", move: "idle 4 0.35 0.25", eggs: [["cosmic", "legendary", 360, 742, 120]] },
  ];
  let stands = "", layers = "";
  let k = 0;
  for (const row of rows) {
    let eggs = "";
    for (const [fam, rar, x, y, w] of row.eggs) {
      const [svg, top] = pedestal(x, y, w);
      stands += svg;
      const s = w * 0.36;
      eggs += egg(x, top - s * 0.82, s, { family: fam, rarity: rar, seed: 4 + k, tilt: (k % 2 ? 1 : -1) * (3 + (k % 3) * 2) });
      k++;
    }
    layers += `<g data-layer="${row.layer}" data-move="${row.move}">${eggs}</g>`;
  }
  // Floor steps leading up to the plinth.
  const steps = [0, 1, 2].map((i) => {
    const y = py + pr * 1.1 + i * 22, hw = pr * 1.25 + i * 40;
    return `<path d="M ${f(px - hw)} ${f(y)} L ${f(px + hw)} ${f(y)} L ${f(px + hw + 14)} ${f(y + 22)} L ${f(px - hw - 14)} ${f(y + 22)} Z" fill="${shade("#2e2a4e", -i * 0.06)}" stroke="#14112a" stroke-width="3"/>
      <rect x="${f(px - hw)}" y="${f(y)}" width="${f(hw * 2)}" height="3" fill="#6a6290" opacity="0.45"/>`;
  }).join("");
  // Two pillars framing the portal.
  const pillar = (x) => `<rect x="${x - 26}" y="40" width="52" height="${floorY - 40}" fill="#2a2648"/>
    <rect x="${x - 26}" y="40" width="14" height="${floorY - 40}" fill="#36315c"/>
    <rect x="${x - 34}" y="28" width="68" height="20" rx="4" fill="#3a3460"/>
    <rect x="${x - 34}" y="${floorY - 18}" width="68" height="20" rx="4" fill="#3a3460"/>`;
  // The game fades the top and bottom edges itself (to whatever room it has),
  // and LivingArt multiplies a painting by itself once more for depth, so the
  // whole picture is lifted by a square-root gamma here to land as drawn.
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${blurs()}
  <defs><filter id="ph_lift" color-interpolation-filters="sRGB"><feComponentTransfer>
    <feFuncR type="gamma" exponent="0.5"/><feFuncG type="gamma" exponent="0.5"/><feFuncB type="gamma" exponent="0.5"/>
  </feComponentTransfer></filter></defs>
  <g filter="url(#ph_lift)">
  ${hall(W, H, floorY, { windows: [[96, 120], [W - 96, 120]], winW: 84 })}
  ${pillar(150)}${pillar(570)}
  ${vines(9, W, 22, 120)}
  ${lantern(150, 180, 15, "#ffcf7a", 150)}${lantern(570, 180, 15, "#ffcf7a", 150)}
  ${steps}
  ${portal(px, py, pr)}
  <ellipse cx="${px}" cy="${floorY + 110}" rx="340" ry="110" fill="#8f6bff" opacity="0.12" filter="url(#bl24)"/>
  ${motes(14, 30, 40, 60, 680, 640, ["#cbb8ff", "#ffe0a6", "#bfe9ff"])}
  ${stands}
  ${layers}
  </g>
</svg>`;
}

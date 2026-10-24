// Specimen jars for the Fuse tab's ready-to-fuse shelf: a glass capsule with a metal cap and
// base, liquid tinted by rarity (the game draws the critter floating inside,
// and the x3 count on the base plate). One transparent PNG per rarity.
import { shade, rng, sparkle } from "./_banner_parts.mjs";
import { blurs } from "./_shop_charge_pad_glow_chest_parts.mjs";
import { f } from "./_map_token.mjs";

export const size = [180, 240];
export const transparent = true;
export const dir = "game/ui/fuse_art";
const COL = { common: "#c9d3e0", uncommon: "#4cd98a", rare: "#3d9bff", epic: "#b366ff", legendary: "#ffc23d" };

function jar(rar, col) {
  const R = rng(rar.length * 7 + 3);
  const x0 = 26, x1 = 154, y0 = 38, y1 = 196, w = x1 - x0;
  let bub = "";
  for (let k = 0; k < 10; k++) {
    const bx = x0 + 12 + R() * (w - 24), by = y0 + 30 + R() * (y1 - y0 - 40), br = 2 + R() * 4;
    bub += `<circle cx="${f(bx)}" cy="${f(by)}" r="${f(br)}" fill="none" stroke="${shade(col, 0.65)}" stroke-width="1.5" opacity="0.75"/>`;
  }
  const lit = rar !== "common";
  return `<svg xmlns="http://www.w3.org/2000/svg" width="180" height="240" viewBox="0 0 180 240">${blurs()}
    <defs>
      <linearGradient id="jl${rar}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${shade(col, 0.2)}" stop-opacity="0.35"/><stop offset="1" stop-color="${shade(col, -0.35)}" stop-opacity="0.75"/></linearGradient>
      <linearGradient id="jm${rar}" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1c1650"/><stop offset="0.35" stop-color="#4a42a0"/><stop offset="1" stop-color="#1c1650"/></linearGradient>
    </defs>
    ${lit ? `<rect x="${x0 - 6}" y="${y0 + 20}" width="${w + 12}" height="${y1 - y0 - 10}" rx="40" fill="${col}" opacity="0.22" filter="url(#bl12)"/>` : ""}
    <rect x="${x0}" y="${y0}" width="${w}" height="${y1 - y0}" rx="34" fill="#141038" opacity="0.7"/>
    <rect x="${x0 + 5}" y="${y0 + 40}" width="${w - 10}" height="${y1 - y0 - 44}" rx="28" fill="url(#jl${rar})"/>
    <ellipse cx="90" cy="${y0 + 42}" rx="${w / 2 - 7}" ry="6" fill="${shade(col, 0.45)}" opacity="0.7"/>
    ${bub}
    <rect x="${x0 + 9}" y="${y0 + 10}" width="9" height="${y1 - y0 - 24}" rx="4.5" fill="#fff" opacity="0.2"/>
    <rect x="${x1 - 22}" y="${y0 + 18}" width="5" height="40" rx="2.5" fill="#fff" opacity="0.14"/>
    <rect x="${x0}" y="${y0}" width="${w}" height="${y1 - y0}" rx="34" fill="none" stroke="${lit ? shade(col, 0.3) : "#9a92e0"}" stroke-width="3" opacity="0.7"/>
    <rect x="${x0 - 8}" y="${y0 - 18}" width="${w + 16}" height="30" rx="9" fill="url(#jm${rar})" stroke="#0c0922" stroke-width="3"/>
    <rect x="${x0 - 2}" y="${y0 - 13}" width="${w + 4}" height="5" rx="2.5" fill="#8a80e0" opacity="0.7"/>
    <rect x="72" y="${y0 - 30}" width="36" height="14" rx="5" fill="#2c2668" stroke="#0c0922" stroke-width="3"/>
    <circle cx="90" cy="${y0 - 23}" r="4" fill="${col}"/>
    <rect x="${x0 - 10}" y="${y1 - 8}" width="${w + 20}" height="42" rx="10" fill="url(#jm${rar})" stroke="#0c0922" stroke-width="3"/>
    <rect x="${x0 + 6}" y="${y1 + 2}" width="${w - 12}" height="22" rx="8" fill="#0e0b2a"/>
    <rect x="${x0 - 4}" y="${y1 - 4}" width="${w + 8}" height="4" rx="2" fill="${lit ? col : "#8a80e0"}" opacity="0.85"/>
    ${lit ? sparkle(x1 - 10, y0 + 16, 7, "#fff", 0.85) : ""}
  </svg>`;
}

export const many = Object.fromEntries(Object.entries(COL).map(([r, c]) => [`jar_${r}`, () => jar(r, c)]));
export default many.jar_epic;

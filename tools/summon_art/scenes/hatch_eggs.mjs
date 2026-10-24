// Painted eggs for the hatch buttons: one egg on x1, a clutch of three on x10.
import { blurs } from "./_p.mjs";
import { egg } from "./_eggs.mjs";

export const size = [220, 180];
export const transparent = true;
const svg = (body) => `<svg xmlns="http://www.w3.org/2000/svg" width="220" height="180" viewBox="0 0 220 180">${blurs()}${body}</svg>`;

export const many = {
  hatch_x1: () => svg(`<ellipse cx="110" cy="160" rx="46" ry="9" fill="#000" opacity="0.35" filter="url(#bl3)"/>${egg(110, 96, 64, { family: "cosmic", rarity: "rare", seed: 6, tilt: -6 })}`),
  hatch_x10: () => svg(`<ellipse cx="110" cy="160" rx="90" ry="11" fill="#000" opacity="0.35" filter="url(#bl3)"/>
  ${egg(62, 112, 44, { family: "sea", rarity: "uncommon", seed: 2, tilt: -14 })}
  ${egg(158, 112, 44, { family: "fire", rarity: "epic", seed: 3, tilt: 12 })}
  ${egg(110, 96, 60, { family: "sweet", rarity: "rare", seed: 4, tilt: -3 })}`),
};
export default many.hatch_x1;

// Map node token: the shop. A big Buttons coin (the in-game currency icon,
// a cream sewing button with four holes) on a gold badge.
import { coin } from "./_shop_charge_pad_glow_chest_parts.mjs";
import { token, twinkle } from "./_map_token.mjs";

export const size = [160, 160];
export const transparent = true;

const GD = "#ffd34e";

export default () =>
  token(GD, `
  <circle cx="80" cy="82" r="50" fill="#ffd98a" opacity="0.3" filter="url(#bl8)"/>
  ${coin(80, 82, 44, { rot: -12, glow: false, shadow: true })}
  ${twinkle(116, 46, 8, "#fff8dc", 0.95)}${twinkle(44, 116, 5, "#fff2c2", 0.8)}`, { face: "#ffb84e" });

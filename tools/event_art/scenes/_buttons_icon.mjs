// Reference art for the in-game Buttons currency icon: one coin, centred.
import { svg, blurs, coin, sparkle } from "./_shop_charge_pad_glow_chest_parts.mjs";

export default () =>
  svg(`${blurs()}
  <defs><radialGradient id="bg" cx="50%" cy="50%" r="60%"><stop offset="0" stop-color="#1a1840"/><stop offset="1" stop-color="#0D0F26"/></radialGradient></defs>
  <rect width="720" height="440" fill="url(#bg)"/>
  <circle cx="360" cy="220" r="185" fill="#3ee6d8" opacity="0.22" filter="url(#bl32)"/>
  ${coin(360, 220, 160, { shadow: true, glow: false })}
  ${sparkle(492, 96, 16, "#fff8dc", 0.9)}
  ${sparkle(250, 330, 9, "#c8fff9", 0.7)}`);

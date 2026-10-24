// Map node token: a treasure chest, shut tight with warm orange light leaking
// from under the lid, on an orange badge.
import { coin } from "./_shop_charge_pad_glow_chest_parts.mjs";
import { token, twinkle } from "./_map_token.mjs";

export const size = [160, 160];
export const transparent = true;

const OR = "#ff9f43";

export default () => {
  const L = 38, R = 122, top = 74, bot = 118;
  return token(OR, `
  <defs>
    <linearGradient id="chWood" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#8a4a72"/><stop offset="1" stop-color="#3e1a44"/></linearGradient>
    <linearGradient id="chLid" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#a05a80"/><stop offset="1" stop-color="#4a2050"/></linearGradient>
    <linearGradient id="chGold" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffe9a0"/><stop offset="0.5" stop-color="#e8b04a"/><stop offset="1" stop-color="#9a6420"/></linearGradient>
  </defs>
  <ellipse cx="80" cy="${bot + 4}" rx="48" ry="7" fill="#000" opacity="0.5" filter="url(#bl3)"/>
  <!-- light leaking from the seam -->
  <ellipse cx="80" cy="${top}" rx="56" ry="12" fill="${OR}" opacity="0.8" filter="url(#bl6)"/>
  <!-- body -->
  <path d="M ${L} ${top} L ${R} ${top} L ${R - 2} ${bot} L ${L + 2} ${bot} Z" fill="url(#chWood)" stroke="#1e0a22" stroke-width="2.5"/>
  <line x1="${L + 2}" y1="${top + 16}" x2="${R - 2}" y2="${top + 16}" stroke="#2a1430" stroke-width="2" opacity="0.6"/>
  <line x1="${L + 2}" y1="${top + 31}" x2="${R - 2}" y2="${top + 31}" stroke="#2a1430" stroke-width="2" opacity="0.6"/>
  <!-- lid, domed -->
  <path d="M ${L - 3} ${top - 2} L ${L - 1} ${top - 22} Q 80 ${top - 46} ${R + 1} ${top - 22} L ${R + 3} ${top - 2} Z" fill="url(#chLid)" stroke="#1e0a22" stroke-width="2.5" stroke-linejoin="round"/>
  <path d="M ${L + 4} ${top - 24} Q 80 ${top - 42} ${R - 4} ${top - 24}" fill="none" stroke="#ffd0e8" stroke-width="2.5" opacity="0.45" stroke-linecap="round"/>
  <!-- gold bands -->
  <path d="M ${L + 14} ${top - 30} Q ${L + 15} ${top - 15} ${L + 15} ${bot}" fill="none" stroke="url(#chGold)" stroke-width="9"/>
  <path d="M ${R - 14} ${top - 30} Q ${R - 15} ${top - 15} ${R - 15} ${bot}" fill="none" stroke="url(#chGold)" stroke-width="9"/>
  <rect x="${L - 4}" y="${top - 4}" width="${R - L + 8}" height="9" rx="3" fill="url(#chGold)" stroke="#5a3410" stroke-width="1.5"/>
  <rect x="${L - 1}" y="${bot - 7}" width="${R - L + 2}" height="8" rx="3" fill="url(#chGold)" stroke="#5a3410" stroke-width="1.5"/>
  <!-- glowing seam line -->
  <rect x="${L - 2}" y="${top - 1.5}" width="${R - L + 4}" height="3" rx="1.5" fill="#fff4d0"/>
  <!-- lock plate with a Button -->
  <path d="M 66 ${top - 6} L 94 ${top - 6} L 94 ${top + 18} Q 80 ${top + 32} 66 ${top + 18} Z" fill="url(#chGold)" stroke="#5a3410" stroke-width="2"/>
  ${coin(80, top + 11, 10, { glow: false, shadow: false })}
  <!-- light shafts sneaking out -->
  <path d="M 52 ${top - 4} L 44 ${top - 30} L 58 ${top - 30} Z" fill="#ffe2a8" opacity="0.35" filter="url(#bl2)"/>
  <path d="M 108 ${top - 4} L 116 ${top - 30} L 102 ${top - 30} Z" fill="#ffe2a8" opacity="0.35" filter="url(#bl2)"/>
  ${twinkle(118, 40, 7, "#fff4d0", 0.95)}${twinkle(42, 44, 5, "#ffe2a8", 0.85)}`);
};

// Map node token: the boss. The Champion: a fierce red ball wearing a gold
// crown, on a red badge.
import { shade, INK, eye } from "../../brand/parts.mjs";
import { token, twinkle } from "./_map_token.mjs";

export const size = [160, 160];
export const transparent = true;

const RD = "#ff5a6e";

export default () => {
  const cx = 80, cy = 96, r = 32;
  return token(RD, `
  <defs>
    <radialGradient id="bsBody" cx="0.35" cy="0.3" r="0.8"><stop offset="0" stop-color="${shade(RD, 0.45)}"/><stop offset="0.5" stop-color="${RD}"/><stop offset="1" stop-color="${shade(RD, -0.5)}"/></radialGradient>
    <linearGradient id="bsGold" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff2b0"/><stop offset="0.45" stop-color="#ffcf4a"/><stop offset="1" stop-color="#b87a18"/></linearGradient>
  </defs>
  <circle cx="${cx}" cy="${cy}" r="${r * 1.4}" fill="${RD}" opacity="0.35" filter="url(#bl8)"/>
  <ellipse cx="${cx + 2}" cy="${cy + 4}" rx="${r}" ry="${r}" fill="#000" opacity="0.35"/>
  <circle cx="${cx}" cy="${cy}" r="${r}" fill="url(#bsBody)" stroke="${shade(RD, -0.65)}" stroke-width="2.5"/>
  <ellipse cx="${cx - 14}" cy="${cy - 12}" rx="8" ry="4" fill="#fff" opacity="0.4" transform="rotate(-35 ${cx - 14} ${cy - 12})"/>
  <!-- confident face -->
  ${eye(cx - 11, cy + 2, 7, 8, 0.2, 0.1, 3.8)}${eye(cx + 11, cy + 2, 7, 8, -0.2, 0.1, 3.8)}
  <path d="M ${cx - 21} ${cy - 9} L ${cx - 4} ${cy - 4}" stroke="${INK}" stroke-width="4.5" stroke-linecap="round"/>
  <path d="M ${cx + 21} ${cy - 9} L ${cx + 4} ${cy - 4}" stroke="${INK}" stroke-width="4.5" stroke-linecap="round"/>
  <path d="M ${cx - 10} ${cy + 16} Q ${cx} ${cy + 22} ${cx + 12} ${cy + 14}" fill="none" stroke="${INK}" stroke-width="3.5" stroke-linecap="round"/>
  <!-- crown -->
  <circle cx="${cx}" cy="${cy - r - 10}" r="26" fill="#ffd34e" opacity="0.35" filter="url(#bl8)"/>
  <path d="M ${cx - 27} ${cy - r + 6} L ${cx - 31} ${cy - r - 26} L ${cx - 15} ${cy - r - 10} L ${cx} ${cy - r - 34} L ${cx + 15} ${cy - r - 10} L ${cx + 31} ${cy - r - 26} L ${cx + 27} ${cy - r + 6} Q ${cx} ${cy - r - 2} ${cx - 27} ${cy - r + 6} Z" fill="url(#bsGold)" stroke="#6a400c" stroke-width="2.5" stroke-linejoin="round"/>
  <path d="M ${cx - 27} ${cy - r + 6} Q ${cx} ${cy - r - 2} ${cx + 27} ${cy - r + 6} L ${cx + 27} ${cy - r - 1} Q ${cx} ${cy - r - 9} ${cx - 27} ${cy - r - 1} Z" fill="#c8861c" opacity="0.8"/>
  <circle cx="${cx - 31}" cy="${cy - r - 27}" r="4" fill="#fff2b0" stroke="#6a400c" stroke-width="1.5"/>
  <circle cx="${cx}" cy="${cy - r - 35}" r="4.5" fill="#fff2b0" stroke="#6a400c" stroke-width="1.5"/>
  <circle cx="${cx + 31}" cy="${cy - r - 27}" r="4" fill="#fff2b0" stroke="#6a400c" stroke-width="1.5"/>
  <path d="M ${cx} ${cy - r - 16} l 6 7 l -6 7 l -6 -7 Z" fill="#3ee6ff" stroke="#0a3a50" stroke-width="1.5"/>
  <circle cx="${cx - 15}" cy="${cy - r - 3}" r="3.5" fill="${RD}" stroke="#6a1020" stroke-width="1.2"/>
  <circle cx="${cx + 15}" cy="${cy - r - 3}" r="3.5" fill="${RD}" stroke="#6a1020" stroke-width="1.2"/>
  <path d="M ${cx - 24} ${cy - r - 18} L ${cx - 16} ${cy - r - 8}" stroke="#fff" stroke-width="2" opacity="0.6" stroke-linecap="round"/>
  ${twinkle(120, 46, 7, "#fff2b0", 0.95)}${twinkle(40, 56, 5, "#ffd0d6", 0.85)}`);
};

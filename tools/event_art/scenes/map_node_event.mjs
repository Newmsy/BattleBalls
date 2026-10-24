// Map node token: a story event. An open storybook with a sparkle of magic
// rising from its pages, on a violet badge (the mystery family).
import { shade } from "../../brand/parts.mjs";
import { token, twinkle } from "./_map_token.mjs";

export const size = [160, 160];
export const transparent = true;

const PU = "#b88cff";

export default () =>
  token(PU, `
  <defs>
    <linearGradient id="evPageL" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#d8ccf0"/><stop offset="1" stop-color="#fff8ec"/></linearGradient>
    <linearGradient id="evPageR" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#fff8ec"/><stop offset="1" stop-color="#cfc0ea"/></linearGradient>
    <radialGradient id="evMagic" cx="0.5" cy="0.6" r="0.5"><stop offset="0" stop-color="#fff" stop-opacity="0.9"/><stop offset="0.4" stop-color="#e2c8ff" stop-opacity="0.5"/><stop offset="1" stop-color="${PU}" stop-opacity="0"/></radialGradient>
  </defs>
  <!-- magic plume -->
  <ellipse cx="80" cy="66" rx="34" ry="36" fill="url(#evMagic)"/>
  <path d="M 80 88 Q 66 70 76 56 Q 84 46 78 34" fill="none" stroke="#e6d4ff" stroke-width="3" stroke-linecap="round" opacity="0.7"/>
  <path d="M 84 88 Q 98 72 90 60 Q 86 52 94 44" fill="none" stroke="#fff" stroke-width="2" stroke-linecap="round" opacity="0.6"/>
  ${twinkle(80, 50, 14, "#fff", 1)}
  ${twinkle(102, 40, 6, "#fff4d0", 0.95)}${twinkle(60, 38, 5, "#e6d4ff", 0.9)}${twinkle(110, 66, 3.5, "#fff", 0.8)}
  <!-- book cover -->
  <path d="M 30 98 L 80 106 L 130 98 L 130 116 L 80 124 L 30 116 Z" fill="${shade(PU, -0.45)}" stroke="#1a0e3a" stroke-width="2.5" stroke-linejoin="round"/>
  <path d="M 30 116 L 80 124 L 130 116" fill="none" stroke="#ffd34e" stroke-width="2" opacity="0.7"/>
  <!-- pages -->
  <path d="M 34 80 Q 58 72 80 86 L 80 112 Q 58 100 34 106 Z" fill="url(#evPageL)" stroke="#3a2a5a" stroke-width="2" stroke-linejoin="round"/>
  <path d="M 126 80 Q 102 72 80 86 L 80 112 Q 102 100 126 106 Z" fill="url(#evPageR)" stroke="#3a2a5a" stroke-width="2" stroke-linejoin="round"/>
  ${[0, 1, 2].map((k) => `<path d="M ${42} ${87 + k * 6} Q ${58} ${82 + k * 6} ${73} ${90 + k * 6}" fill="none" stroke="#9a88c0" stroke-width="1.6" opacity="0.7"/>
    <path d="M ${118} ${87 + k * 6} Q ${102} ${82 + k * 6} ${87} ${90 + k * 6}" fill="none" stroke="#9a88c0" stroke-width="1.6" opacity="0.7"/>`).join("")}
  <path d="M 80 86 L 80 112" stroke="#6a5a90" stroke-width="2"/>
  <ellipse cx="80" cy="88" rx="30" ry="6" fill="#fff" opacity="0.35" filter="url(#bl4)"/>`);

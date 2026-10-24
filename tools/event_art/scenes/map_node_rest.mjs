// Map node token: a rest stop. A glowing battery with a plus, charging on a
// little ring pad, on a green badge.
import { shade } from "../../brand/parts.mjs";
import { token, twinkle } from "./_map_token.mjs";

export const size = [160, 160];
export const transparent = true;

const GR = "#5cff9a";

export default () =>
  token(GR, `
  <defs>
    <linearGradient id="rsShell" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1c3a48"/><stop offset="0.35" stop-color="#3a6a78"/><stop offset="1" stop-color="#0f2430"/></linearGradient>
    <linearGradient id="rsCell" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#3ad87a"/><stop offset="0.4" stop-color="#b8ffd2"/><stop offset="1" stop-color="#2ab86a"/></linearGradient>
  </defs>
  <!-- charge pad rings -->
  <ellipse cx="80" cy="118" rx="44" ry="11" fill="${GR}" opacity="0.35" filter="url(#bl4)"/>
  <ellipse cx="80" cy="118" rx="40" ry="9" fill="none" stroke="${GR}" stroke-width="2.5" opacity="0.8"/>
  <ellipse cx="80" cy="118" rx="27" ry="5.5" fill="none" stroke="#c8ffdc" stroke-width="2" opacity="0.7"/>
  <!-- battery, standing up -->
  <rect x="71" y="34" width="18" height="9" rx="3" fill="#2a4a58" stroke="#0a1a22" stroke-width="2"/>
  <rect x="55" y="40" width="50" height="74" rx="11" fill="url(#rsShell)" stroke="#071418" stroke-width="3"/>
  <rect x="60" y="46" width="40" height="62" rx="7" fill="#06161c"/>
  <rect x="60" y="46" width="40" height="62" rx="7" fill="${GR}" opacity="0.25" filter="url(#bl4)"/>
  ${[0, 1, 2].map((k) => `<rect x="64" y="${86 - k * 18}" width="32" height="15" rx="3" fill="url(#rsCell)" opacity="${k === 2 ? 0.55 : 1}"/>`).join("")}
  <rect x="60" y="46" width="40" height="62" rx="7" fill="${GR}" opacity="0.18"/>
  <!-- plus -->
  <circle cx="80" cy="77" r="17" fill="#ffffff" opacity="0.35" filter="url(#bl6)"/>
  <path d="M 80 64 L 80 90 M 67 77 L 93 77" stroke="${shade(GR, -0.65)}" stroke-width="10" stroke-linecap="round"/>
  <path d="M 80 64 L 80 90 M 67 77 L 93 77" stroke="#fff" stroke-width="6" stroke-linecap="round"/>
  <path d="M 59 52 Q 59 44 66 43" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" opacity="0.6"/>
  ${twinkle(116, 58, 6, "#eafff0", 0.9)}${twinkle(42, 66, 4.5, "#c8ffdc", 0.8)}${twinkle(110, 98, 3.5, "#fff", 0.7)}`);

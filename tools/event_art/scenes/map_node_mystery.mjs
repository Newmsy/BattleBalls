// Map node token: a mystery room. A swirling violet portal with a glowing
// question mark built from shapes floating at its heart.
import { shade } from "../../brand/parts.mjs";
import { token, twinkle, f } from "./_map_token.mjs";

export const size = [160, 160];
export const transparent = true;

const PU = "#b88cff";

function swirl(cx, cy) {
  let out = "";
  const arms = 5;
  for (let a = 0; a < arms; a++) {
    let d = "";
    for (let t = 0; t <= 1.001; t += 0.05) {
      const ang = (a / arms) * Math.PI * 2 + t * 3.4;
      const rr = 8 + t * 50;
      d += `${t ? "L" : "M"} ${f(cx + Math.cos(ang) * rr)} ${f(cy + Math.sin(ang) * rr * 0.92)} `;
    }
    out += `<path d="${d}" fill="none" stroke="${a % 2 ? "#7a5aff" : "#d8a8ff"}" stroke-width="${a % 2 ? 6 : 4}" stroke-linecap="round" opacity="${a % 2 ? 0.45 : 0.55}"/>`;
  }
  return out;
}

export default () => {
  const cx = 80, cy = 82;
  return token(PU, `
  <defs>
    <radialGradient id="myCore" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#fff" stop-opacity="0.9"/><stop offset="0.35" stop-color="#e2c8ff" stop-opacity="0.6"/><stop offset="1" stop-color="${PU}" stop-opacity="0"/></radialGradient>
    <linearGradient id="myQ" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffffff"/><stop offset="1" stop-color="#e6d4ff"/></linearGradient>
  </defs>
  <circle cx="${cx}" cy="${cy}" r="54" fill="#2a1460" opacity="0.7"/>
  <g filter="url(#bl2)">${swirl(cx, cy)}</g>
  <circle cx="${cx}" cy="${cy}" r="34" fill="url(#myCore)"/>
  <!-- question mark: a hooked arc plus a dot -->
  <g transform="translate(0 -2)">
    <path d="M 64 66 Q 64 48 80 48 Q 97 48 97 63 Q 97 74 86 79 Q 80 82 80 92" fill="none" stroke="${shade(PU, -0.6)}" stroke-width="17" stroke-linecap="round" stroke-linejoin="round"/>
    <circle cx="80" cy="110" r="9.5" fill="${shade(PU, -0.6)}"/>
    <path d="M 64 66 Q 64 48 80 48 Q 97 48 97 63 Q 97 74 86 79 Q 80 82 80 92" fill="none" stroke="url(#myQ)" stroke-width="11" stroke-linecap="round" stroke-linejoin="round"/>
    <circle cx="80" cy="110" r="6.5" fill="url(#myQ)"/>
    <path d="M 67 62 Q 69 52 79 51" fill="none" stroke="#fff" stroke-width="3" stroke-linecap="round" opacity="0.9"/>
  </g>
  ${twinkle(116, 52, 7, "#fff", 0.95)}${twinkle(42, 108, 5, "#e6d4ff", 0.85)}${twinkle(48, 50, 3.5, "#fff", 0.7)}`);
};

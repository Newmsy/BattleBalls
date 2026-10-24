// Map node token: an elite fight. A horned, spiked crimson-magenta brute ball
// with a glowering face, on a hot pink badge.
import { shade, INK } from "../../brand/parts.mjs";
import { token, f } from "./_map_token.mjs";

export const size = [160, 160];
export const transparent = true;

const PK = "#ff4fb8";
const BODY = "#e0306e";

function spikes(cx, cy, r) {
  let out = "";
  const n = 10;
  for (let k = 0; k < n; k++) {
    const a = (k / n) * Math.PI * 2 + Math.PI / n;
    if (Math.sin(a) < -0.55) continue; // leave the top for the horns
    const w = 0.24;
    const p = (ang, rr) => `${f(cx + Math.cos(ang) * rr)},${f(cy + Math.sin(ang) * rr)}`;
    out += `<polygon points="${p(a - w, r * 0.9)} ${p(a, r * 1.42)} ${p(a + w, r * 0.9)}" fill="url(#elSpike)" stroke="${shade(BODY, -0.7)}" stroke-width="2" stroke-linejoin="round"/>`;
  }
  return out;
}

export default () => {
  const cx = 80, cy = 90, r = 30;
  return token(PK, `
  <defs>
    <linearGradient id="elSpike" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#ffe0f0"/><stop offset="0.5" stop-color="#d8b8e8"/><stop offset="1" stop-color="#6a4a8a"/></linearGradient>
    <linearGradient id="elHorn" x1="0" y1="1" x2="0" y2="0"><stop offset="0" stop-color="#7a5a8a"/><stop offset="0.6" stop-color="#e8d8f0"/><stop offset="1" stop-color="#fff"/></linearGradient>
    <radialGradient id="elBody" cx="0.35" cy="0.3" r="0.8"><stop offset="0" stop-color="${shade(BODY, 0.45)}"/><stop offset="0.5" stop-color="${BODY}"/><stop offset="1" stop-color="${shade(BODY, -0.5)}"/></radialGradient>
  </defs>
  <circle cx="${cx}" cy="${cy}" r="${r * 1.5}" fill="${PK}" opacity="0.35" filter="url(#bl8)"/>
  ${spikes(cx, cy, r)}
  <!-- horns -->
  <path d="M ${cx - 20} ${cy - 20} Q ${cx - 40} ${cy - 34} ${cx - 34} ${cy - 58} Q ${cx - 24} ${cy - 40} ${cx - 8} ${cy - 30} Z" fill="url(#elHorn)" stroke="${shade(BODY, -0.7)}" stroke-width="2.2" stroke-linejoin="round"/>
  <path d="M ${cx + 20} ${cy - 20} Q ${cx + 40} ${cy - 34} ${cx + 34} ${cy - 58} Q ${cx + 24} ${cy - 40} ${cx + 8} ${cy - 30} Z" fill="url(#elHorn)" stroke="${shade(BODY, -0.7)}" stroke-width="2.2" stroke-linejoin="round"/>
  <ellipse cx="${cx + 2}" cy="${cy + 4}" rx="${r}" ry="${r}" fill="#000" opacity="0.35"/>
  <circle cx="${cx}" cy="${cy}" r="${r}" fill="url(#elBody)" stroke="${shade(BODY, -0.65)}" stroke-width="2.5"/>
  <ellipse cx="${cx - 12}" cy="${cy - 15}" rx="8" ry="4" fill="#fff" opacity="0.45" transform="rotate(-35 ${cx - 12} ${cy - 15})"/>
  <!-- glowering face: slanted glowing eyes, heavy brows, fanged grimace -->
  <path d="M ${cx - 21} ${cy - 6} L ${cx - 5} ${cy - 1} L ${cx - 8} ${cy + 6} L ${cx - 19} ${cy + 3} Z" fill="#fff4b0"/>
  <path d="M ${cx + 21} ${cy - 6} L ${cx + 5} ${cy - 1} L ${cx + 8} ${cy + 6} L ${cx + 19} ${cy + 3} Z" fill="#fff4b0"/>
  <circle cx="${cx - 10}" cy="${cy + 2}" r="2.6" fill="${INK}"/><circle cx="${cx + 10}" cy="${cy + 2}" r="2.6" fill="${INK}"/>
  <path d="M ${cx - 25} ${cy - 13} L ${cx - 3} ${cy - 4}" stroke="${INK}" stroke-width="5" stroke-linecap="round"/>
  <path d="M ${cx + 25} ${cy - 13} L ${cx + 3} ${cy - 4}" stroke="${INK}" stroke-width="5" stroke-linecap="round"/>
  <path d="M ${cx - 14} ${cy + 16} Q ${cx} ${cy + 10} ${cx + 14} ${cy + 16} Q ${cx} ${cy + 22} ${cx - 14} ${cy + 16} Z" fill="${INK}"/>
  <path d="M ${cx - 9} ${cy + 14} L ${cx - 6} ${cy + 20} L ${cx - 3} ${cy + 13} Z" fill="#fff"/>
  <path d="M ${cx + 9} ${cy + 14} L ${cx + 6} ${cy + 20} L ${cx + 3} ${cy + 13} Z" fill="#fff"/>`);
};

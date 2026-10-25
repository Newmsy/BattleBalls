// Gear sheet header: a spotlit pedestal in a quiet vault, left empty; the
// screen places the piece's own painted token on it.
import { sky, motes } from "./_banner_parts.mjs";
import { blurs } from "./_shop_charge_pad_glow_chest_parts.mjs";

export const size = [720, 300];
export const dir = "game/ui/gear_art";
const INK = "#14102e";

export default function plinth() {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="720" height="300" viewBox="0 0 720 300">${blurs()}
  <defs>
    <linearGradient id="plW" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#120e30"/><stop offset="1" stop-color="#2a1a4a"/></linearGradient>
    <linearGradient id="plBeam" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff4d8" stop-opacity="0.32"/><stop offset="1" stop-color="#fff4d8" stop-opacity="0.04"/></linearGradient>
    <linearGradient id="plTop" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#5a5a90"/><stop offset="0.5" stop-color="#9a9ad0"/><stop offset="1" stop-color="#4a4a80"/></linearGradient>
  </defs>
  <rect width="720" height="300" fill="url(#plW)"/>
  ${sky(19, 26, 0, 0, 720, 160)}
  ${[90, 630].map((x) => `<rect x="${x - 22}" y="20" width="44" height="240" fill="#1e1640" stroke="#120a28" stroke-width="3"/><rect x="${x - 28}" y="14" width="56" height="14" rx="3" fill="#2e2456"/><rect x="${x - 28}" y="250" width="56" height="14" rx="3" fill="#2e2456"/>`).join("")}
  <path d="M 120 120 Q 360 60 600 120" stroke="#ffd36b" stroke-width="2" fill="none" opacity="0.25"/>
  <path d="M 330 0 L 390 0 L 470 240 L 250 240 Z" fill="url(#plBeam)"/>
  <rect x="-10" y="240" width="740" height="70" fill="#140c28"/>
  <path d="M -10 240 L 740 240" stroke="#7a6ad0" stroke-width="2" opacity="0.4"/>
  <ellipse cx="360" cy="270" rx="140" ry="16" fill="#000" opacity="0.45"/>
  <path d="M 270 268 L 450 268 L 436 228 L 284 228 Z" fill="#2e2456" stroke="${INK}" stroke-width="4" stroke-linejoin="round"/>
  <ellipse cx="360" cy="228" rx="78" ry="16" fill="url(#plTop)" stroke="${INK}" stroke-width="4"/>
  <ellipse cx="360" cy="228" rx="60" ry="10" fill="#fff4d8" opacity="0.25"/>
  <path d="M 288 246 L 432 246" stroke="#ffd36b" stroke-width="3" opacity="0.6"/>
  ${motes(23, 14, 260, 40, 460, 220, ["#fff4d8", "#ffd36b"])}
  </svg>`;
}


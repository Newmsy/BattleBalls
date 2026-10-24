// Shared frame for the Bounce Run map's node tokens: a 160x160 transparent
// canvas holding a round glowing badge (~144px across) with a coloured rim,
// a dark painted face and a soft outer glow that fades out inside the box.
// Each map_node_* scene draws its icon on the face (centre 80,80, radius ~56).
import { shade } from "../../brand/parts.mjs";
import { blurs } from "./_shop_charge_pad_glow_chest_parts.mjs";

export const S = 160, C = 80;

const rgb = (h) => [0, 2, 4].map((i) => parseInt(h.slice(1 + i, 3 + i), 16));
export const mix = (a, b, t) =>
  "#" + rgb(a).map((v, i) => Math.round(v + (rgb(b)[i] - v) * t).toString(16).padStart(2, "0")).join("");

export const f = (n) => (typeof n === "number" ? n.toFixed(1) : n);

// Four-point twinkle.
export const twinkle = (x, y, s, col = "#fff", o = 1) =>
  `<path d="M ${f(x)} ${f(y - s)} Q ${f(x)} ${f(y)} ${f(x + s)} ${f(y)} Q ${f(x)} ${f(y)} ${f(x)} ${f(y + s)} Q ${f(x)} ${f(y)} ${f(x - s)} ${f(y)} Q ${f(x)} ${f(y)} ${f(x)} ${f(y - s)} Z" fill="${col}" opacity="${o}"/>`;

// The whole token: frame + icon. `face` tints the inner disc (defaults to col).
export function token(col, icon, { face = col, rimHi = shade(col, 0.55) } = {}) {
  const deep = mix(face, "#0D0F26", 0.62);
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${S}" height="${S}" viewBox="0 0 ${S} ${S}">${blurs()}
  <defs>
    <radialGradient id="tkGlow" cx="0.5" cy="0.5" r="0.5">
      <stop offset="0.8" stop-color="${col}" stop-opacity="0.55"/>
      <stop offset="0.9" stop-color="${col}" stop-opacity="0.2"/>
      <stop offset="1" stop-color="${col}" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="tkRim" x1="0.2" y1="0" x2="0.8" y2="1">
      <stop offset="0" stop-color="${rimHi}"/><stop offset="0.45" stop-color="${col}"/><stop offset="1" stop-color="${shade(col, -0.55)}"/>
    </linearGradient>
    <radialGradient id="tkFace" cx="0.5" cy="0.42" r="0.6">
      <stop offset="0" stop-color="${deep}"/><stop offset="0.65" stop-color="${mix(deep, "#0D0F26", 0.6)}"/><stop offset="1" stop-color="#0a0a20"/>
    </radialGradient>
    <linearGradient id="tkGloss" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#fff" stop-opacity="0.16"/><stop offset="1" stop-color="#fff" stop-opacity="0"/>
    </linearGradient>
    <clipPath id="tkClip"><circle cx="${C}" cy="${C}" r="62"/></clipPath>
  </defs>
  <circle cx="${C}" cy="${C}" r="80" fill="url(#tkGlow)"/>
  <circle cx="${C}" cy="${C + 3}" r="72" fill="#05051a" opacity="0.6"/>
  <circle cx="${C}" cy="${C}" r="72" fill="url(#tkRim)"/>
  <circle cx="${C}" cy="${C}" r="72" fill="none" stroke="${shade(col, -0.7)}" stroke-width="2"/>
  <path d="M ${C - 64} ${C - 14} A 66 66 0 0 1 ${C + 14} ${C - 64}" fill="none" stroke="#fff" stroke-width="3" stroke-linecap="round" opacity="0.55"/>
  <circle cx="${C}" cy="${C}" r="63.5" fill="${shade(col, -0.75)}"/>
  <circle cx="${C}" cy="${C}" r="62" fill="url(#tkFace)"/>
  <g clip-path="url(#tkClip)">
    <circle cx="${C}" cy="${C + 8}" r="46" fill="${col}" opacity="0.22" filter="url(#bl12)"/>
    ${icon}
    <ellipse cx="${C}" cy="${C - 34}" rx="50" ry="26" fill="url(#tkGloss)"/>
  </g>
  <circle cx="${C}" cy="${C}" r="62" fill="none" stroke="${shade(col, 0.2)}" stroke-width="1.6" opacity="0.6"/>
  </svg>`;
}

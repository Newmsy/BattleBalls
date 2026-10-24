// Shared parts for the Versus hub and Ghost Arena paintings (versus_*.mjs),
// the same night colosseum as the Home Versus band (home_versus.mjs): crowd
// stands, a friendly ghost and a trophy cup.
import { rng } from "./_shop_charge_pad_glow_chest_parts.mjs";
import { shade } from "./_banner_parts.mjs";

const f = (n) => (+n).toFixed(1);

export const PINK = "#ff4fd8", VIOLET = "#7b77ff", GOLD = "#ffd36b", CYAN = "#5ce1ff";
const HEADS = ["#7b77ff", "#ff7ac8", "#5fd068", "#3fa9f5", "#ffc93c", "#b07cff", "#ff6a3d", "#8fe6ff"];

// Rows of round crowd heads following an arc that dips toward cx.
export function crowd(seed, { y = 118, rows = 4, x0 = -10, x1 = 740, cx = 360, curve = 26, step = 17, dark = -0.74, wave = 0.12 } = {}) {
  const R = rng(seed);
  let out = "";
  for (let row = 0; row < rows; row++) {
    const y0 = y + row * 26;
    for (let x = x0; x < x1; x += step + row * 2) {
      const yy = y0 + Math.pow((x - cx) / ((x1 - x0) / 2), 2) * curve + R() * 3;
      const c = HEADS[Math.floor(R() * HEADS.length)];
      const r = 7 + row * 1.4;
      out += `<circle cx="${f(x + R() * 6)}" cy="${f(yy)}" r="${f(r)}" fill="${shade(c, dark + row * 0.05)}"/>`;
      if (R() < wave) out += `<line x1="${f(x)}" y1="${f(yy - r)}" x2="${f(x + 4)}" y2="${f(yy - r - 12)}" stroke="${shade(c, -0.5)}" stroke-width="3" stroke-linecap="round"/>`;
    }
    out += `<path d="M ${x0} ${y0 + 14} Q ${cx} ${y0 - 14 + curve * 0.2} ${x1} ${y0 + 14}" stroke="#1a0f30" stroke-width="7" fill="none"/>`;
  }
  return out;
}

// A little sheet ghost; s = scale (1 = ~50px wide).
export function ghost(gx, gy, s = 1, { o = 0.92, look = 0 } = {}) {
  return `<g opacity="${o}" transform="translate(${gx} ${gy}) scale(${s})">
    <ellipse cx="0" cy="6" rx="34" ry="36" fill="#ff9ae6" opacity="0.35" filter="url(#bl12)"/>
    <path d="M -24 30 L -24 0 Q -24 -26 0 -26 Q 24 -26 24 0 L 24 30 Q 16 22 8 30 Q 0 22 -8 30 Q -16 22 -24 30 Z" fill="#f6e8ff" stroke="#8a5ab0" stroke-width="2.5"/>
    <ellipse cx="${-8 + look * 3}" cy="-2" rx="4" ry="6" fill="#2a1a48"/><ellipse cx="${8 + look * 3}" cy="-2" rx="4" ry="6" fill="#2a1a48"/>
    <ellipse cx="${look * 3}" cy="12" rx="4" ry="3" fill="#2a1a48"/>
    <ellipse cx="-15" cy="7" rx="4" ry="2.4" fill="#ff9ae6" opacity="0.6"/><ellipse cx="15" cy="7" rx="4" ry="2.4" fill="#ff9ae6" opacity="0.6"/></g>`;
}

// Trophy cup centred at (x, y), about 2r tall.
export function cupIcon(x, y, r, col = GOLD) {
  const hi = shade(col, 0.45), lo = shade(col, -0.45);
  return `<g>
    <path d="M ${x - r * 0.95} ${y - r * 0.7} q -${r * 0.55} 0 -${r * 0.5} ${r * 0.45} q ${r * 0.06} ${r * 0.45} ${r * 0.62} ${r * 0.5}" fill="none" stroke="${lo}" stroke-width="${r * 0.16}"/>
    <path d="M ${x + r * 0.95} ${y - r * 0.7} q ${r * 0.55} 0 ${r * 0.5} ${r * 0.45} q -${r * 0.06} ${r * 0.45} -${r * 0.62} ${r * 0.5}" fill="none" stroke="${lo}" stroke-width="${r * 0.16}"/>
    <path d="M ${x - r} ${y - r * 0.85} L ${x + r} ${y - r * 0.85} Q ${x + r * 0.95} ${y + r * 0.35} ${x} ${y + r * 0.45} Q ${x - r * 0.95} ${y + r * 0.35} ${x - r} ${y - r * 0.85} Z" fill="${col}" stroke="${lo}" stroke-width="2.5"/>
    <path d="M ${x - r * 0.62} ${y - r * 0.7} Q ${x - r * 0.6} ${y + r * 0.1} ${x - r * 0.15} ${y + r * 0.3}" fill="none" stroke="${hi}" stroke-width="${r * 0.14}" stroke-linecap="round" opacity="0.8"/>
    <rect x="${x - r * 0.14}" y="${y + r * 0.42}" width="${r * 0.28}" height="${r * 0.4}" fill="${lo}"/>
    <rect x="${x - r * 0.55}" y="${y + r * 0.8}" width="${r * 1.1}" height="${r * 0.28}" rx="${r * 0.08}" fill="${col}" stroke="${lo}" stroke-width="2"/>
    <ellipse cx="${x}" cy="${y - r * 0.85}" rx="${r}" ry="${r * 0.16}" fill="${lo}"/></g>`;
}
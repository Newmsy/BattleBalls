// Shared pieces for the Daily board paintings (daily_*.mjs): the sunrise fair
// from the Home Daily band (home_daily.mjs), broken into props.
import { critter, shadow, sky, motes, shade } from "./_banner_parts.mjs";
import { blurs, rng, stringLights, sparkle } from "./_shop_charge_pad_glow_chest_parts.mjs";
export { critter, shadow, sky, motes, shade, blurs, rng, stringLights, sparkle };
export const f = (n) => (+n).toFixed(1);

export const GOLD = "#ffd36b", CYAN = "#5ce1ff", PINK = "#ff4fd8", GREEN = "#9be89a", LIGHTS = ["#ffd36b", "#ff7ac8", "#5ce1ff", "#7ee08a"];

// Sunrise sky + sun + rays, over a w x h canvas with the horizon at hy.
export function dawn(id, w, h, hy, { sx = w * 0.6, sr = 46, tint = "#c2644a", rays = true, seed = 4 } = {}) {
  let r = "";
  if (rays) for (let k = 0; k < 14; k++) {
    const a = -Math.PI + (k + 0.5) * (Math.PI / 14), L = Math.max(w, h);
    r += `<path d="M ${sx} ${hy} L ${f(sx + Math.cos(a - 0.05) * L)} ${f(hy + Math.sin(a - 0.05) * L)} L ${f(sx + Math.cos(a + 0.05) * L)} ${f(hy + Math.sin(a + 0.05) * L)} Z" fill="#ffe2a0" opacity="${k % 2 ? 0.04 : 0.08}"/>`;
  }
  return `<defs>
    <linearGradient id="${id}S" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#151036"/><stop offset="0.5" stop-color="#4a2a5e"/><stop offset="0.82" stop-color="${tint}"/><stop offset="1" stop-color="#f0a24e"/></linearGradient>
    <radialGradient id="${id}Sun" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#fff4d0"/><stop offset="0.6" stop-color="#ffd36b"/><stop offset="1" stop-color="#ffb347"/></radialGradient>
    <linearGradient id="${id}G" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3a2448"/><stop offset="1" stop-color="#140e28"/></linearGradient>
  </defs>
  <rect width="${w}" height="${hy + 2}" fill="url(#${id}S)"/>
  ${sky(seed, Math.round(w / 24), 0, 0, w, hy * 0.5)}${r}
  <circle cx="${sx}" cy="${hy}" r="${sr * 1.8}" fill="#ffd36b" opacity="0.35" filter="url(#bl24)"/>
  <circle cx="${sx}" cy="${hy}" r="${sr}" fill="url(#${id}Sun)"/>
  <path d="M 0 ${hy - 10} Q ${w * 0.25} ${hy - 30} ${w * 0.5} ${hy - 6} Q ${w * 0.75} ${hy + 12} ${w} ${hy - 14} L ${w} ${h} L 0 ${h} Z" fill="#5a3058"/>
  <path d="M 0 ${hy + 16} Q ${w * 0.4} ${hy + 2} ${w} ${hy + 18} L ${w} ${h} L 0 ${h} Z" fill="url(#${id}G)"/>`;
}

// A booth's striped scalloped awning across [x0,x1] at y (stripes a/b).
export function awning(x0, x1, y, a, b, { n = 8, drop = 30, edge = "#5a2e2a" } = {}) {
  const w = (x1 - x0) / n;
  let s = "", sc = `M ${x0} ${y + drop}`;
  for (let k = 0; k < n; k++) {
    s += `<path d="M ${f(x0 + k * w)} ${y} L ${f(x0 + (k + 1) * w)} ${y} L ${f(x0 + (k + 1) * w)} ${y + drop} Q ${f(x0 + (k + 0.5) * w)} ${y + drop + 14} ${f(x0 + k * w)} ${y + drop} Z" fill="${k % 2 ? b : a}"/>`;
  }
  return `${s}<path d="M ${x0 - 6} ${y} L ${x1 + 6} ${y} L ${x1} ${y - 10} L ${x0} ${y - 10} Z" fill="${shade(a, -0.35)}"/>
    <path d="M ${x0} ${y} L ${x1} ${y}" stroke="${edge}" stroke-width="2.5"/>`;
}

// Wooden booth: two posts, counter, dark back wall, awning on top.
export function booth(x0, x1, top, base, a, b, { wall = "#24163e" } = {}) {
  return `${shadow((x0 + x1) / 2, base + 4, (x1 - x0) * 0.55, 0.55)}
    <rect x="${x0}" y="${top}" width="${x1 - x0}" height="${base - top}" fill="${wall}"/>
    <rect x="${x0}" y="${top}" width="${x1 - x0}" height="${base - top}" fill="url(#boothLit)" opacity="0.6"/>
    <rect x="${x0 - 8}" y="${top - 6}" width="10" height="${base - top + 6}" fill="#6a3e2a" stroke="#2a160e" stroke-width="2"/>
    <rect x="${x1 - 2}" y="${top - 6}" width="10" height="${base - top + 6}" fill="#6a3e2a" stroke="#2a160e" stroke-width="2"/>
    <rect x="${x0 - 12}" y="${base - 22}" width="${x1 - x0 + 24}" height="14" rx="3" fill="#8a5a3a" stroke="#2a160e" stroke-width="2"/>
    <rect x="${x0 - 12}" y="${base - 22}" width="${x1 - x0 + 24}" height="4" fill="#c08a5a"/>
    <rect x="${x0 - 6}" y="${base - 8}" width="${x1 - x0 + 12}" height="10" fill="#3a2418"/>
    ${awning(x0 - 14, x1 + 14, top - 6, a, b)}`;
}
export const boothDefs = (col) => `<defs><radialGradient id="boothLit" cx="0.5" cy="0.2" r="0.8"><stop offset="0" stop-color="${col}" stop-opacity="0.5"/><stop offset="1" stop-color="${col}" stop-opacity="0"/></radialGradient></defs>`;

export function target(ex, ey, s = 1) {
  return [38, 30, 22, 14, 6].map((r, k) => `<circle cx="${ex}" cy="${ey}" r="${r * s}" fill="${["#f4e6c8", "#ff6a5a", "#f4e6c8", "#ff6a5a", "#ffd34e"][k]}" stroke="#5a2e2a" stroke-width="${k ? 1 : 3}"/>`).join("");
}

export function pad(x, y, r) {
  return `${shadow(x, y + 6, r, 0.5)}
    <rect x="${x - r * 0.22}" y="${y - r * 0.2}" width="${r * 0.44}" height="${r * 0.5}" fill="#f4e6c8" stroke="#5a3a2a" stroke-width="2"/>
    <path d="M ${x - r} ${y - r * 0.15} Q ${x} ${y - r * 1.2} ${x + r} ${y - r * 0.15} Z" fill="#5ce1ff" stroke="#1a4a6a" stroke-width="2.5"/>
    <circle cx="${x - r * 0.35}" cy="${y - r * 0.55}" r="${r * 0.14}" fill="#e6fbff"/><circle cx="${x + r * 0.25}" cy="${y - r * 0.68}" r="${r * 0.1}" fill="#e6fbff"/>`;
}

export function cloud(cx, cy, s = 1, { bolt = true } = {}) {
  const c = (x, y, r, col) => `<circle cx="${f(cx + x * s)}" cy="${f(cy + y * s)}" r="${f(r * s)}" fill="${col}"/>`;
  const B = `M ${f(cx + 6 * s)} ${f(cy + 32 * s)} L ${f(cx - 6 * s)} ${f(cy + 62 * s)} L ${f(cx + 8 * s)} ${f(cy + 60 * s)} L ${f(cx - 2 * s)} ${f(cy + 92 * s)} L ${f(cx + 26 * s)} ${f(cy + 52 * s)} L ${f(cx + 12 * s)} ${f(cy + 54 * s)} L ${f(cx + 22 * s)} ${f(cy + 32 * s)} Z`;
  return `${bolt ? `<path d="${B}" fill="#ff7ac8" opacity="0.7" filter="url(#bl8)"/>` : ""}
    ${[[0, 0, 34], [32, -10, 28], [-34, 8, 26], [50, 12, 24], [12, 18, 30]].map(([x, y, r]) => c(x, y, r, "#3a2a6a")).join("")}
    ${[[-10, -12, 18], [24, -20, 14]].map(([x, y, r]) => c(x, y, r, "#55408a")).join("")}
    ${bolt ? `<path d="${B}" fill="#ffd0f2" stroke="#ff4fd8" stroke-width="${2 * s}" stroke-linejoin="round"/>` : ""}`;
}

// Navy edge fade so a painting melts into the #0D0F26 card at the bottom.
export const bottomFade = (id, w, h, from = 0.6, col = "#0D0F26") => `<defs><linearGradient id="${id}" x1="0" y1="0" x2="0" y2="1"><stop offset="${from}" stop-color="${col}" stop-opacity="0"/><stop offset="1" stop-color="${col}" stop-opacity="0.85"/></linearGradient></defs><rect width="${w}" height="${h}" fill="url(#${id})"/>`;

export const svg = (w, h, body) => `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">${blurs()}${body}</svg>`;

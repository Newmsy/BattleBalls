// Adventure hub, Spire card (game/ui/home_art/adventure_spire_<step>.png): a tall tower of stacked stone floors climbing
// into a moonlit sky, windows lit gold up to the floor you reached, a beacon
// at the top and a little hero at the door looking up. Portrait; title reads
// over the top band, status over the bottom band.
import { blurs, rng } from "./_shop_charge_pad_glow_chest_parts.mjs";
import { critter, shadow, sky, motes, sparkle } from "./_banner_parts.mjs";

const f = (n) => (+n).toFixed(1);

export const size = [360, 560];
export const dir = "game/ui/home_art";
// Four climbs: more windows lit as the week's climb goes up (AdventureScreen.spire_step).
export const LIT = [1, 3, 6, 9];
export const many = Object.fromEntries(LIT.map((n, i) => [`adventure_spire_${i}`, () => paint(n)]));

export default function paint(lit = 4, { bare = false } = {}) {
  const W = 360, H = 560, R = rng(21);
  const floors = 9, base = 486, top = 132;
  let tower = "", glows = "";
  for (let k = 0; k < floors; k++) {
    const t = k / (floors - 1);
    const y1 = base - (k * (base - top)) / floors, y0 = base - ((k + 1) * (base - top)) / floors;
    const w = 128 - t * 66, w0 = 128 - ((k + 1) / (floors - 1)) * 66, cx = 186 + Math.sin(k * 0.9) * 3;
    const on = k < lit;
    // floor body: lit side left (moon), shade right
    tower += `<path d="M ${f(cx - w / 2)} ${f(y1)} L ${f(cx - w0 / 2 - 4)} ${f(y0 + 8)} L ${f(cx + w0 / 2 + 4)} ${f(y0 + 8)} L ${f(cx + w / 2)} ${f(y1)} Z" fill="#2c2458" stroke="#120c2a" stroke-width="2.5" stroke-linejoin="round"/>
      <path d="M ${f(cx + w * 0.12)} ${f(y1)} L ${f(cx + w0 * 0.12)} ${f(y0 + 8)} L ${f(cx + w0 / 2 + 4)} ${f(y0 + 8)} L ${f(cx + w / 2)} ${f(y1)} Z" fill="#1b1540"/>
      <path d="M ${f(cx - w / 2 + 3)} ${f(y1 - 3)} L ${f(cx - w0 / 2 - 1)} ${f(y0 + 10)}" stroke="#4a3f86" stroke-width="3" stroke-linecap="round"/>
      <rect x="${f(cx - w0 / 2 - 10)}" y="${f(y0 + 2)}" width="${f(w0 + 20)}" height="9" rx="4" fill="#3a3070" stroke="#120c2a" stroke-width="2.5"/>
      <rect x="${f(cx - w0 / 2 - 8)}" y="${f(y0 + 3)}" width="${f((w0 + 16) * 0.55)}" height="3" rx="1.5" fill="#5a4fa0"/>`;
    const nw = k < 5 ? 2 : 1;
    for (let j = 0; j < nw; j++) {
      const wx = cx + (nw === 1 ? 0 : (j ? 1 : -1) * w * 0.2) - 6, wy = (y0 + y1) / 2 - 2;
      tower += `<path d="M ${f(wx)} ${f(wy + 14)} L ${f(wx)} ${f(wy + 2)} Q ${f(wx + 6)} ${f(wy - 5)} ${f(wx + 12)} ${f(wy + 2)} L ${f(wx + 12)} ${f(wy + 14)} Z" fill="${on ? "#ffd36b" : "#0e0a22"}" stroke="#120c2a" stroke-width="2"/>`;
      if (on) glows += `<ellipse cx="${f(wx + 6)}" cy="${f(wy + 6)}" rx="16" ry="14" fill="#ffb347" opacity="0.45" filter="url(#bl8)"/>`;
    }
  }
  // door at the base
  const door = `<path d="M 170 ${base} L 170 ${base - 30} Q 186 ${base - 48} 202 ${base - 30} L 202 ${base} Z" fill="#ffd36b"/>
    <ellipse cx="186" cy="${base - 18}" rx="34" ry="30" fill="#ffb347" opacity="0.45" filter="url(#bl12)"/>`;
  // spire cap + beacon
  const cap = `<path d="M 152 ${top + 6} L 186 ${top - 58} L 220 ${top + 6} Z" fill="#3a3070" stroke="#120c2a" stroke-width="2.5" stroke-linejoin="round"/>
    <path d="M 186 ${top - 58} L 220 ${top + 6} L 194 ${top + 6} Z" fill="#221a48"/>
    <circle cx="186" cy="${top - 66}" r="34" fill="#ffd36b" opacity="0.35" filter="url(#bl16)"/>
    <circle cx="186" cy="${top - 66}" r="10" fill="#fff4cf" stroke="#a8701a" stroke-width="2"/>
    <path d="M 186 ${top - 76} L 186 ${top - 104}" stroke="#120c2a" stroke-width="3"/>
    <path d="M 186 ${top - 104} L 212 ${top - 96} L 186 ${top - 88} Z" fill="#ffb347" stroke="#7a4a1a" stroke-width="2" stroke-linejoin="round"/>
    ${sparkle(222, top - 70, 7, "#fff8dc", 0.9)}${sparkle(150, top - 40, 5, "#fff8dc", 0.7)}`;
  // drifting cloud bands wrapping the tower
  const cloud = (y, x, s, o) => `<g opacity="${o}">${[0, 1, 2, 3].map((j) => `<ellipse cx="${f(x + j * 34 * s)}" cy="${f(y - (j % 2) * 8 * s)}" rx="${f(34 * s)}" ry="${f(14 * s)}" fill="#3d3478"/>`).join("")}<rect x="${f(x - 20 * s)}" y="${f(y)}" width="${f(140 * s)}" height="${f(10 * s)}" fill="#3d3478"/></g>`;
  const hill = `<path d="M 0 ${base + 6} Q 90 ${base - 26} 180 ${base - 2} Q 270 ${base - 22} 360 ${base} L 360 ${H} L 0 ${H} Z" fill="#191238"/>
    <path d="M 0 ${base + 30} Q 120 ${base + 6} 230 ${base + 26} Q 300 ${base + 36} 360 ${base + 22} L 360 ${H} L 0 ${H} Z" fill="#120d2c"/>`;
  let steps = "";
  for (let k = 0; k < 6; k++) {
    const t = k / 5, x = 70 + t * 96 + Math.sin(t * 3) * 10, y = 548 - t * 60, s = 1.1 - t * 0.5;
    steps += `<ellipse cx="${f(x)}" cy="${f(y + 4)}" rx="${f(24 * s)}" ry="${f(9 * s)}" fill="#0b0720"/><ellipse cx="${f(x)}" cy="${f(y)}" rx="${f(22 * s)}" ry="${f(8 * s)}" fill="#3a3070"/><ellipse cx="${f(x)}" cy="${f(y)}" rx="${f(10 * s)}" ry="${f(3.5 * s)}" fill="#ffd36b" opacity="0.8"/>`;
  }
  if (bare) return `${glows}${tower}${cap}${door}`;
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${blurs()}
  <defs><linearGradient id="spSky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0c0a26"/><stop offset="0.55" stop-color="#231a52"/><stop offset="1" stop-color="#3a2462"/></linearGradient>
  <radialGradient id="spMoon" cx="0.4" cy="0.4" r="0.6"><stop offset="0" stop-color="#fff6dc"/><stop offset="1" stop-color="#d8cfae"/></radialGradient></defs>
  <rect width="${W}" height="${H}" fill="url(#spSky)"/>
  ${sky(31, 70, 0, 0, W, 420)}
  <circle cx="64" cy="98" r="44" fill="#fff0c0" opacity="0.18" filter="url(#bl16)"/>
  <mask id="spCres"><rect width="360" height="560" fill="#fff"/><circle cx="76" cy="90" r="22" fill="#000"/></mask>
  <circle cx="64" cy="98" r="24" fill="url(#spMoon)" mask="url(#spCres)"/>
  ${cloud(330, -30, 1.2, 0.55)}${cloud(250, 230, 0.9, 0.5)}
  <path d="M 0 440 Q 60 400 120 420 L 120 ${H} L 0 ${H} Z" fill="#221a4a" opacity="0.8"/>
  <path d="M 250 430 Q 310 392 360 410 L 360 ${H} L 250 ${H} Z" fill="#221a4a" opacity="0.8"/>
  ${glows}${tower}${cap}${door}
  ${cloud(410, 236, 0.8, 0.45)}${cloud(186, -40, 0.8, 0.45)}
  ${hill}${steps}
  ${motes(9, 18, 100, 120, 280, 500, ["#ffd36b", "#ffb347", "#fff4cf"])}
  ${shadow(96, 468, 22, 0.6)}${critter(96, 442, 22, "#7b77ff", { acc: "antenna", mood: "determined", look: [0.6, -0.7], rim: "#ffd36b", rimSide: 1 })}
  </svg>`;
}

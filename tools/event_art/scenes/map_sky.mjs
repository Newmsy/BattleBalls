// World map backdrop: the tall night sky behind the campaign's floating
// islands. Deep indigo to violet, a warm orange/gold nebula near the top (where
// Magma Core and Starfall Rim float), a cool cyan/green one near the bottom
// (Glow Garden and Circuit Lab), a starfield, a few distant floating rocks and
// a faint synthwave grid at the very bottom. Islands, labels and the glowing
// path go on top, so the middle stays calm and low in contrast. Opaque.
import { blurs, rng } from "./_shop_charge_pad_glow_chest_parts.mjs";

export const size = [720, 1000];
export const dir = "game/ui/map_art";

const W = 720, H = 1000;
const f = (n) => (+n).toFixed(1);

let gid = 0;
// A soft glow from a radial gradient (smoother than a big blur).
function soft(x, y, rx, ry, c, o, rot = 0) {
  const g = `msS${gid++}`;
  return `<defs><radialGradient id="${g}"><stop offset="0" stop-color="${c}" stop-opacity="${o}"/><stop offset="0.5" stop-color="${c}" stop-opacity="${f(o * 0.45)}"/><stop offset="1" stop-color="${c}" stop-opacity="0"/></radialGradient></defs>
  <ellipse cx="${x}" cy="${y}" rx="${rx}" ry="${ry}" fill="url(#${g})" transform="rotate(${rot} ${x} ${y})"/>`;
}

// A nebula band: overlapping soft clouds along a gentle diagonal, with darker
// dust lanes and a few brighter knots.
function nebula(seed, y0, cols, dir = 1) {
  const R = rng(seed);
  let out = "";
  for (let k = 0; k < 14; k++) {
    const t = k / 13, x = -60 + t * 840, y = y0 + dir * (t - 0.5) * 90 + Math.sin(t * 7 + seed) * 26;
    out += soft(f(x), f(y), f(110 + R() * 90), f(40 + R() * 40), cols[k % cols.length], 0.13 + R() * 0.09, f(-dir * 7 + (R() - 0.5) * 16));
  }
  for (let k = 0; k < 6; k++) {
    const t = R(), x = t * 720, y = y0 + dir * (t - 0.5) * 90 + (R() - 0.5) * 40;
    out += soft(f(x), f(y), f(30 + R() * 40), f(12 + R() * 14), cols[0], 0.14, f(-dir * 7));
  }
  for (let k = 0; k < 5; k++) {
    const t = R(), x = t * 720, y = y0 + dir * (t - 0.5) * 90 + (R() - 0.5) * 30;
    out += soft(f(x), f(y), f(60 + R() * 60), f(8 + R() * 8), "#06061a", 0.35, f(-dir * 7 + (R() - 0.5) * 10));
  }
  return out;
}

function stars(seed, n, y0, y1) {
  const R = rng(seed);
  let out = "";
  for (let k = 0; k < n; k++) {
    const x = R() * W, y = y0 + R() * (y1 - y0), s = R();
    // Calmer in the middle band where the labels sit.
    const mid = 1 - 0.45 * Math.exp(-(((y - 500) / 220) ** 2));
    const col = s > 0.86 ? "#ffe9c4" : s > 0.7 ? "#cfe8ff" : "#e6e0ff";
    out += `<circle cx="${f(x)}" cy="${f(y)}" r="${(0.45 + s * s * 1.5).toFixed(2)}" fill="${col}" opacity="${((0.2 + s * 0.6) * mid).toFixed(2)}"/>`;
  }
  return out;
}

const twinkle = (x, y, s, c, o) => `<circle cx="${x}" cy="${y}" r="${s * 1.2}" fill="${c}" opacity="${o * 0.35}" filter="url(#bl3)"/>
  <path d="M ${x} ${y - s} Q ${x} ${y} ${x + s} ${y} Q ${x} ${y} ${x} ${y + s} Q ${x} ${y} ${x - s} ${y} Q ${x} ${y} ${x} ${y - s} Z" fill="${c}" opacity="${o}"/>`;

// A distant floating rock: small, dark and cool, with a faint rim light.
function rock(x, y, s, rim) {
  return `<g opacity="0.8">${soft(x, y, s * 2.4, s * 1.4, rim, 0.12)}
    <path d="M ${f(x - s)} ${f(y)} Q ${f(x)} ${f(y - s * 0.35)} ${f(x + s)} ${f(y)} L ${f(x + s * 0.5)} ${f(y + s * 0.5)} L ${f(x + s * 0.1)} ${f(y + s * 1.1)} L ${f(x - s * 0.4)} ${f(y + s * 0.55)} Z" fill="#1a1838" stroke="#0a0a1e" stroke-width="1.5"/>
    <path d="M ${f(x - s)} ${f(y)} Q ${f(x)} ${f(y - s * 0.35)} ${f(x + s)} ${f(y)}" fill="none" stroke="${rim}" stroke-width="1.8" opacity="0.75"/>
    <ellipse cx="${f(x)}" cy="${f(y)}" rx="${f(s * 0.9)}" ry="${f(s * 0.22)}" fill="#2a2650"/></g>`;
}

// The synthwave grid on the bottom ~15%.
function grid() {
  const hy = 862, vx = 360;
  let lines = "";
  for (let k = -16; k <= 16; k++) {
    const xb = vx + k * 70;
    lines += `<line x1="${vx + k * 6}" y1="${hy}" x2="${xb}" y2="${H}" stroke="#ff4fd8" stroke-width="${k === 0 ? 1.6 : 1.2}"/>`;
  }
  for (let k = 1; k <= 9; k++) {
    const y = hy + Math.pow(k / 9, 2.1) * (H - hy);
    lines += `<line x1="0" y1="${f(y)}" x2="${W}" y2="${f(y)}" stroke="#39d7ff" stroke-width="${f(0.8 + k * 0.12)}"/>`;
  }
  return `<defs>
    <linearGradient id="msGridFade" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0"/><stop offset="0.25" stop-color="#fff" stop-opacity="0.55"/><stop offset="1" stop-color="#fff" stop-opacity="0.9"/></linearGradient>
    <linearGradient id="msGridSide" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#fff" stop-opacity="0.35"/><stop offset="0.5" stop-color="#fff" stop-opacity="1"/><stop offset="1" stop-color="#fff" stop-opacity="0.35"/></linearGradient>
    <mask id="msGridMask"><rect x="0" y="${hy}" width="${W}" height="${H - hy}" fill="url(#msGridFade)"/></mask>
    <linearGradient id="msFloor" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#140f36"/><stop offset="1" stop-color="#0a0c26"/></linearGradient>
  </defs>
  <rect x="0" y="${hy}" width="${W}" height="${H - hy}" fill="url(#msFloor)"/>
  <g mask="url(#msGridMask)" opacity="0.3">${lines}</g>
  ${soft(360, hy, 420, 26, "#ff4fd8", 0.32)}
  <rect x="0" y="${hy - 1}" width="${W}" height="2" fill="#ff9ae6" opacity="0.35"/>
  ${soft(360, hy - 8, 300, 60, "#39d7ff", 0.12)}`;
}

export default function () {
  const R = rng(9);
  let rocks = "";
  // Distant rocks hug the sides, away from the middle text.
  [[40, 120, 14, "#ffb347"], [684, 220, 11, "#ffd23d"], [28, 390, 9, "#c77dff"], [696, 470, 12, "#b88cff"],
    [44, 610, 10, "#a8e6ff"], [680, 700, 13, "#45f5a6"], [70, 790, 7, "#39d7ff"], [640, 60, 8, "#ff6a3d"],
    [606, 826, 7, "#9bd84a"], [112, 300, 6, "#c77dff"], [560, 330, 5, "#ff9ae6"]].forEach(([x, y, s, c]) => (rocks += rock(x, y, s, c)));
  let sparkles = "";
  for (let k = 0; k < 14; k++) {
    const x = R() * W, y = 20 + R() * 820;
    if (Math.abs(y - 500) < 140 && Math.abs(x - 360) < 220) continue;
    sparkles += twinkle(+f(x), +f(y), +f(2.5 + R() * 3.5), ["#fff3d0", "#e8e0ff", "#c8f8ff"][k % 3], 0.5 + R() * 0.3);
  }
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${blurs()}
  <defs>
    <linearGradient id="msSky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#22103a"/><stop offset="0.2" stop-color="#1a0f34"/><stop offset="0.45" stop-color="#0f0f2a"/>
      <stop offset="0.6" stop-color="#0d0f26"/><stop offset="0.82" stop-color="#0c1430"/><stop offset="1" stop-color="#0b1030"/>
    </linearGradient>
  </defs>
  <rect width="${W}" height="${H}" fill="url(#msSky)"/>
  ${soft(360, 40, 520, 160, "#6a2a6a", 0.35)}
  ${nebula(3, 170, ["#ff7a4a", "#ffb347", "#ff4f9a", "#ffd23d"], 1)}
  ${soft(560, 130, 220, 90, "#ffd23d", 0.12)}${soft(150, 220, 200, 80, "#ff6a3d", 0.12)}
  ${soft(360, 470, 460, 200, "#5a3aa8", 0.08)}
  ${nebula(11, 760, ["#39d7ff", "#45f5a6", "#2a8ad8", "#45f5a6"], -1)}
  ${soft(170, 720, 220, 90, "#45f5a6", 0.1)}${soft(560, 790, 200, 80, "#39d7ff", 0.11)}
  ${stars(5, 360, 0, 870)}
  ${sparkles}
  ${rocks}
  ${grid()}
  </svg>`;
}

// Bosses screen splash (game/ui/home_art/bosses_hall.png): every farming boss
// together in a torch-lit hall over a glowing rune circle. Front row: the
// Brood Queen, the Anvil King (biggest, centre) and the Piñata Titan swinging
// on its rope; back row: The Glitch, the Totem of Nine and the Prism Wyrm.
// Each boss stands in a pool of its own colour (the colours of its card).
// A rose window in the six bosses' colours crowns the vault above them.
// Moving layers (at most 4): the king idles, the piñata sways on its rope,
// the queen bobs and The Glitch hovers. The screen shows all of it on tall
// phones and a band through the bosses (y ~100-470) on short ones; it never
// crops the sides.
import { blurs, rng } from "./_shop_charge_pad_glow_chest_parts.mjs";
import { motes, sparkle, FAM } from "./_banner_parts.mjs";

export const size = [720, 520];
export const dir = "game/ui/home_art";

const f = (n) => (+n).toFixed(1);
const P = (pts) => pts.map(([x, y]) => `${f(x)},${f(y)}`).join(" ");
const poly = (pts, fill, extra = "") => `<polygon points="${P(pts)}" fill="${fill}" ${extra}/>`;
const INK = "#1a1033";

// A pool of coloured light on the floor and a soft glow behind a boss.
const pool = (cx, cy, rx, col, o = 0.5) =>
  `<ellipse cx="${cx}" cy="${cy}" rx="${rx}" ry="${rx * 0.22}" fill="${col}" opacity="${o}" filter="url(#bl12)"/>
   <ellipse cx="${cx}" cy="${cy}" rx="${rx * 0.7}" ry="${rx * 0.13}" fill="#000" opacity="0.45" filter="url(#bl4)"/>`;
const halo = (cx, cy, r, col, o = 0.35) => `<circle cx="${cx}" cy="${cy}" r="${r}" fill="${col}" opacity="${o}" filter="url(#bl24)"/>`;

// The Anvil King: an iron anvil body with a horn, molten slit eyes, a crown
// of three flames and his hammer resting on his shoulder (boss_art.gd).
function anvilKing(cx, cy, r) {
  const at = (x, y) => [cx + x * r, cy + y * r];
  const base = [at(-0.62, 0.78), at(0.62, 0.78), at(0.46, 0.48), at(-0.46, 0.48)];
  const waist = [at(-0.34, 0.5), at(0.34, 0.5), at(0.26, -0.08), at(-0.26, -0.08)];
  const top = [at(-0.98, -0.2), at(-0.6, -0.1), at(0.72, -0.1), at(0.78, -0.48), at(-0.42, -0.48), at(-0.62, -0.36)];
  const flames = [0, 1, 2].map((k) => {
    const x = -0.24 + k * 0.24, h = k === 1 ? 0.42 : 0.3;
    const [rx, ry] = at(x, -0.5);
    return `<path d="M ${f(rx - r * 0.1)} ${f(ry)} Q ${f(rx - r * 0.1)} ${f(ry - r * h * 0.6)} ${f(rx)} ${f(ry - r * h)} Q ${f(rx + r * 0.1)} ${f(ry - r * h * 0.6)} ${f(rx + r * 0.1)} ${f(ry)} Z" fill="#ff8a3d"/>
      <path d="M ${f(rx - r * 0.05)} ${f(ry)} Q ${f(rx - r * 0.05)} ${f(ry - r * h * 0.4)} ${f(rx)} ${f(ry - r * h * 0.62)} Q ${f(rx + r * 0.05)} ${f(ry - r * h * 0.4)} ${f(rx + r * 0.05)} ${f(ry)} Z" fill="#ffd166"/>`;
  }).join("");
  const eyes = [-0.22, 0.18].map((x) => {
    const [ex, ey] = at(x, -0.3), h = r * 0.075;
    return `<ellipse cx="${f(ex)}" cy="${f(ey)}" rx="${f(r * 0.16)}" ry="${f(r * 0.12)}" fill="#ffd166" opacity="0.35" filter="url(#bl3)"/>
      ${poly([[ex - r * 0.1, ey - h], [ex + r * 0.1, ey - h * 0.3], [ex + r * 0.1, ey + h], [ex - r * 0.1, ey + h]], "#ffd166")}`;
  }).join("");
  const sh = at(0.7, -0.24);
  // hammer: handle up and back over the right shoulder, head at the top
  const ang = -1.15, d = [Math.cos(ang), Math.sin(ang)], s = [-d[1], d[0]];
  const head = [sh[0] + d[0] * r * 0.72, sh[1] + d[1] * r * 0.72];
  const hp = (a, b) => [head[0] + s[0] * r * a + d[0] * r * b, head[1] + s[1] * r * a + d[1] * r * b];
  const hammer = `<line x1="${f(sh[0])}" y1="${f(sh[1])}" x2="${f(head[0])}" y2="${f(head[1])}" stroke="#2a120a" stroke-width="${f(r * 0.12)}" stroke-linecap="round"/>
    <line x1="${f(sh[0])}" y1="${f(sh[1])}" x2="${f(head[0])}" y2="${f(head[1])}" stroke="#b07a45" stroke-width="${f(r * 0.07)}" stroke-linecap="round"/>
    ${poly([hp(0.26, -0.14), hp(0.26, 0.14), hp(-0.26, 0.14), hp(-0.26, -0.14)], "#aab4c8", `stroke="#1e1a34" stroke-width="${f(r * 0.04)}" stroke-linejoin="round"`)}
    ${poly([hp(0.26, 0.04), hp(0.26, 0.14), hp(-0.26, 0.14), hp(-0.26, 0.04)], "#e6ebf5")}
    <circle cx="${f(hp(-0.26, 0)[0])}" cy="${f(hp(-0.26, 0)[1])}" r="${f(r * 0.08)}" fill="#ff8a3d"/>`;
  return `${halo(cx, cy - r * 0.1, r * 1.25, "#ff8a3d", 0.4)}
    ${flames}
    ${poly(base, "#3a3f4f", `stroke="#5d6478" stroke-width="${f(r * 0.04)}" stroke-linejoin="round"`)}
    ${poly(waist, "#2c303d")}
    ${hammer}
    ${poly(top, "#3a3f4f", `stroke="#5d6478" stroke-width="${f(r * 0.04)}" stroke-linejoin="round"`)}
    <line x1="${f(at(-0.42, -0.48)[0])}" y1="${f(at(0, -0.48)[1])}" x2="${f(at(0.78, 0)[0])}" y2="${f(at(0, -0.48)[1])}" stroke="#aab4c8" stroke-width="${f(r * 0.06)}" stroke-linecap="round"/>
    ${[0, 1, 2, 3].map((k) => `<circle cx="${f(at(-0.42 + k * 0.28, 0)[0])}" cy="${f(at(0, 0.64)[1])}" r="${f(r * 0.04)}" fill="#7d859c"/>`).join("")}
    <path d="M ${P([at(-0.1, -0.44)])} L ${P([at(0.02, -0.3)])} L ${P([at(-0.06, -0.16)])}" fill="none" stroke="#ffb347" stroke-width="${f(r * 0.035)}" stroke-linecap="round"/>
    <path d="M ${P([at(0.38, -0.12)])} L ${P([at(0.3, 0.1)])} L ${P([at(0.4, 0.4)])}" fill="none" stroke="#ff8a3d" stroke-width="${f(r * 0.03)}" stroke-linecap="round" opacity="0.8"/>
    ${eyes}
    <path d="M ${P([at(-0.38, -0.44)])} L ${P([at(-0.04, -0.37)])} L ${P([at(0.34, -0.44)])}" fill="none" stroke="#14161f" stroke-width="${f(r * 0.06)}" stroke-linecap="round" stroke-linejoin="round"/>
    <circle cx="${f(at(-0.92, 0)[0])}" cy="${f(at(0, -0.06)[1])}" r="${f(r * 0.05)}" fill="#ffd166"/>`;
}

// The Brood Queen, facing right: tail fan, flapping wings, pink body,
// golden tiara, comb, open beak.
function broodQueen(cx, cy, r) {
  const tail = [-2, -1, 0, 1, 2].map((k) => {
    const a = Math.PI + k * 0.36 - 0.25, d = [Math.cos(a), Math.sin(a)], sd = [-d[1], d[0]];
    const root = [cx - r * 0.5, cy - r * 0.05];
    const tip = [root[0] + d[0] * r * (0.85 + (k === 0 ? 0.15 : 0)), root[1] + d[1] * r * (0.85 + (k === 0 ? 0.15 : 0))];
    const col = k % 2 === 0 ? "#8f7bff" : "#5ce1ff";
    return poly([[root[0] + sd[0] * r * 0.12, root[1] + sd[1] * r * 0.12], tip, [root[0] - sd[0] * r * 0.12, root[1] - sd[1] * r * 0.12]], col) +
      `<circle cx="${f(tip[0] - d[0] * r * 0.08)}" cy="${f(tip[1] - d[1] * r * 0.08)}" r="${f(r * 0.08)}" fill="#e6f8ff"/>`;
  }).join("");
  // back wing fanned up behind her, front wing folded over her side
  const backWing = [0, 1, 2].map((k) => {
    const root = [cx - r * 0.1, cy - r * 0.2];
    const tip = [cx - r * (0.55 + k * 0.32), cy - r * (1.2 - k * 0.28)];
    return poly([[root[0] + r * 0.25, root[1] - r * 0.1], tip, [root[0] - r * 0.2, root[1] + r * 0.25]], ["#e05a98", "#c84f8a", "#b0447a"][k], `stroke="#7a2350" stroke-width="${f(r * 0.025)}" stroke-linejoin="round"`);
  }).join("");
  const frontWing = `<path d="M ${f(cx - r * 0.05)} ${f(cy - r * 0.05)} Q ${f(cx - r * 0.75)} ${f(cy - r * 0.1)} ${f(cx - r * 0.62)} ${f(cy + r * 0.42)} Q ${f(cx - r * 0.2)} ${f(cy + r * 0.5)} ${f(cx + r * 0.15)} ${f(cy + r * 0.22)} Z" fill="#ff8fc0" stroke="#a8336c" stroke-width="${f(r * 0.035)}" stroke-linejoin="round"/>
    ${[0, 1].map((k) => `<path d="M ${f(cx - r * (0.5 - k * 0.18))} ${f(cy + r * (0.36 - k * 0.04))} q ${f(r * 0.1)} ${f(-r * 0.18)} ${f(r * 0.05)} ${f(-r * 0.32)}" fill="none" stroke="#ffc6df" stroke-width="${f(r * 0.03)}" stroke-linecap="round"/>`).join("")}`;
  const crown = [0, 1, 2].map((k) => {
    const x = cx + r * 0.25 + (k - 1) * r * 0.17, y = cy - r * 0.68;
    return poly([[x - r * 0.08, y + r * 0.05], [x, y - r * (0.24 + (k === 1 ? 0.07 : 0))], [x + r * 0.08, y + r * 0.05]], "#ffc23d", `stroke="#8a4a10" stroke-width="${f(r * 0.025)}"`) +
      `<circle cx="${f(x)}" cy="${f(y - r * 0.02)}" r="${f(r * 0.045)}" fill="${k === 1 ? "#5ce1ff" : "#ff3d5a"}"/>`;
  }).join("");
  const comb = [0, 1, 2].map((k) => `<circle cx="${f(cx + r * (0.42 + k * 0.13))}" cy="${f(cy - r * (0.66 - k * 0.07))}" r="${f(r * 0.12)}" fill="#ff3d5a"/>`).join("");
  return `${halo(cx, cy, r * 1.2, "#ff6fae", 0.35)}
    ${tail}${backWing}
    <circle cx="${cx}" cy="${cy}" r="${f(r * 0.84)}" fill="#ff6fae" stroke="#a8336c" stroke-width="${f(r * 0.04)}"/>
    <ellipse cx="${f(cx - r * 0.25)}" cy="${f(cy - r * 0.3)}" rx="${f(r * 0.35)}" ry="${f(r * 0.28)}" fill="#ffb3d4" opacity="0.55"/>
    ${[0, 1, 2].map((k) => `<path d="M ${f(cx - r * 0.35 + k * r * 0.22)} ${f(cy + r * 0.38)} q ${f(r * 0.11)} ${f(r * 0.14)} ${f(r * 0.22)} 0" fill="none" stroke="#ffb3d4" stroke-width="${f(r * 0.04)}" stroke-linecap="round"/>`).join("")}
    ${comb}${crown}
    ${poly([[cx + r * 0.72, cy - r * 0.04], [cx + r * 1.16, cy + r * 0.03], [cx + r * 0.72, cy + r * 0.12]], "#ffc23d")}
    ${poly([[cx + r * 0.72, cy + r * 0.12], [cx + r * 1.08, cy + r * 0.12], [cx + r * 0.7, cy + r * 0.24]], "#d99a20")}
    <circle cx="${f(cx + r * 0.42)}" cy="${f(cy - r * 0.18)}" r="${f(r * 0.12)}" fill="${INK}"/>
    <circle cx="${f(cx + r * 0.38)}" cy="${f(cy - r * 0.22)}" r="${f(r * 0.045)}" fill="#fff"/>
    <path d="M ${f(cx + r * 0.28)} ${f(cy - r * 0.36)} L ${f(cx + r * 0.56)} ${f(cy - r * 0.3)}" stroke="${INK}" stroke-width="${f(r * 0.05)}" stroke-linecap="round"/>
    ${frontWing}`;
}

// The Piñata Titan: a paper star with frills, stripes, streamers and a grin,
// hung from a rope that runs off the top of the picture.
function pinata(cx, cy, r) {
  const C = ["#ff6fae", "#5ce1ff", "#ffd166", "#7cff9b", "#b366ff"];
  let cones = "", streamers = "";
  for (let k = 0; k < 5; k++) {
    const a = -Math.PI / 2 + 0.12 + (k * 2 * Math.PI) / 5, d = [Math.cos(a), Math.sin(a)], sd = [-d[1], d[0]];
    const tip = [cx + d[0] * r * 1.08, cy + d[1] * r * 1.08];
    const at = (u, v) => [cx + d[0] * r * u + sd[0] * r * v, cy + d[1] * r * u + sd[1] * r * v];
    cones += poly([at(0.42, 0.3), tip, at(0.42, -0.3)], C[k], `stroke="${INK}" stroke-width="${f(r * 0.03)}" stroke-linejoin="round" stroke-opacity="0.5"`);
    cones += poly([at(0.6, 0.11), at(0.98, 0), at(0.6, -0.11)], "#ffffff", `opacity="0.35"`);
    for (let s = 0; s < 3; s++) {
      const b = a + (s - 1) * 0.45 + 0.15 * Math.sin(k * 3 + s), e = [tip[0] + Math.cos(b) * r * 0.4, tip[1] + Math.sin(b) * r * 0.4];
      streamers += `<path d="M ${f(tip[0])} ${f(tip[1])} Q ${f((tip[0] + e[0]) / 2 + r * 0.06)} ${f((tip[1] + e[1]) / 2 - r * 0.06)} ${f(e[0])} ${f(e[1])}" fill="none" stroke="${C[(k + s + 1) % 5]}" stroke-width="${f(r * 0.045)}" stroke-linecap="round"/>`;
    }
  }
  let frills = "";
  for (let k = 0; k < 14; k++) {
    const a = (k * 2 * Math.PI) / 14, d = [Math.cos(a), Math.sin(a)], sd = [-d[1], d[0]];
    const p = [cx + d[0] * r * 0.6, cy + d[1] * r * 0.6];
    frills += poly([[p[0] + sd[0] * r * 0.11, p[1] + sd[1] * r * 0.11], [p[0] + d[0] * r * 0.12, p[1] + d[1] * r * 0.12], [p[0] - sd[0] * r * 0.11, p[1] - sd[1] * r * 0.11]], C[k % 5]);
  }
  const stripes = [0, 1, 2].map((k) => `<line x1="${f(cx - r * 0.48)}" y1="${f(cy + (k - 0.6) * r * 0.24)}" x2="${f(cx + r * 0.48)}" y2="${f(cy + (k - 0.6) * r * 0.24)}" stroke="${C[(k * 2) % 5]}" stroke-width="${f(r * 0.08)}" stroke-linecap="round"/>`).join("");
  return `<line x1="${cx}" y1="-30" x2="${cx}" y2="${f(cy - r * 0.55)}" stroke="#e8d5b5" stroke-width="${f(r * 0.05)}"/>
    <circle cx="${cx}" cy="${f(cy - r * 0.58)}" r="${f(r * 0.07)}" fill="#c9a77a"/>
    ${halo(cx, cy, r * 1.25, "#ffb627", 0.35)}
    ${streamers}${cones}${frills}
    <circle cx="${cx}" cy="${cy}" r="${f(r * 0.58)}" fill="#ffb627" stroke="#b86f10" stroke-width="${f(r * 0.03)}"/>
    <clipPath id="pnClip"><circle cx="${cx}" cy="${cy}" r="${f(r * 0.56)}"/></clipPath>
    <g clip-path="url(#pnClip)">${stripes}</g>
    ${[-0.18, 0.18].map((x) => `<circle cx="${f(cx + x * r)}" cy="${f(cy - r * 0.22)}" r="${f(r * 0.08)}" fill="${INK}"/><circle cx="${f(cx + x * r - r * 0.025)}" cy="${f(cy - r * 0.25)}" r="${f(r * 0.03)}" fill="#fff"/>`).join("")}
    <path d="M ${f(cx - r * 0.17)} ${f(cy - r * 0.06)} Q ${f(cx)} ${f(cy + r * 0.12)} ${f(cx + r * 0.17)} ${f(cy - r * 0.06)}" fill="none" stroke="${INK}" stroke-width="${f(r * 0.045)}" stroke-linecap="round"/>
    <circle cx="${f(cx - r * 0.32)}" cy="${f(cy - r * 0.06)}" r="${f(r * 0.06)}" fill="#ff6fae" opacity="0.7"/>
    <circle cx="${f(cx + r * 0.32)}" cy="${f(cy - r * 0.06)}" r="${f(r * 0.06)}" fill="#ff6fae" opacity="0.7"/>`;
}

// The Glitch: six cube slices torn sideways in green and magenta, cyan and
// pink ghosts, a scanline, one square eye and dead pixels round it.
function glitch(cx, cy, r) {
  const h = r * 0.72, jit = [0.1, -0.06, 0.02, 0.14, -0.1, 0.04];
  let out = halo(cx, cy, r * 1.3, "#7cff4f", 0.3);
  const R = rng(9);
  for (let k = 0; k < 8; k++) {
    const a = k * Math.PI / 4 + 0.3, rr = r * (1.15 + 0.15 * R()), s = r * 0.055;
    const x = cx + Math.cos(a) * rr, y = cy + Math.sin(a) * rr;
    out += `<rect x="${f(x - s)}" y="${f(y - s)}" width="${f(s * 2)}" height="${f(s * 2)}" fill="${k % 2 ? "#ff4fd8" : "#7cff4f"}" opacity="0.85"/>`;
  }
  for (const [dx, col, o] of [[-0.08, "#4fe8ff", 0.4], [0.08, "#ff4fd8", 0.4], [0, null, 0.95]]) {
    for (let k = 0; k < 6; k++) {
      const y = cy - h + (k * h * 2) / 6, x = cx + dx * r + jit[k] * r;
      out += `<rect x="${f(x - h)}" y="${f(y)}" width="${f(h * 2)}" height="${f(h / 3 + 1)}" fill="${col ?? (k % 2 ? "#ff4fd8" : "#7cff4f")}" opacity="${o}"/>`;
    }
  }
  out += `<rect x="${f(cx - h * 1.1)}" y="${f(cy + h * 0.3)}" width="${f(h * 2.2)}" height="${f(r * 0.04)}" fill="#fff" opacity="0.5"/>
    <rect x="${f(cx - r * 0.24)}" y="${f(cy - r * 0.18)}" width="${f(r * 0.48)}" height="${f(r * 0.4)}" fill="#040a06"/>
    <rect x="${f(cx - r * 0.02)}" y="${f(cy - r * 0.06)}" width="${f(r * 0.14)}" height="${f(r * 0.16)}" fill="#7cff4f"/>`;
  return out;
}

// The Totem of Nine, side on: a carved stone drum with nine family masks
// round it (the front five show) and a moon-white spiral cap.
function totem(cx, cy, r) {
  const fams = Object.values(FAM);
  const w = r * 0.95, top = cy - r * 0.55, bot = cy + r * 0.75;
  let masks = "";
  for (let k = 0; k < 9; k++) {
    const a = (k / 9) * Math.PI * 2 + 0.2, x = Math.sin(a), z = Math.cos(a);
    if (z < -0.1) continue;
    const mx = cx + x * w * 0.82, my = cy + r * 0.12, mr = r * 0.17 * (0.6 + 0.4 * z);
    masks += `<circle cx="${f(mx)}" cy="${f(my)}" r="${f(mr * 1.8)}" fill="${fams[k]}" opacity="${f(0.35 * z)}" filter="url(#bl4)"/>
      <circle cx="${f(mx)}" cy="${f(my)}" r="${f(mr)}" fill="${fams[k]}" stroke="#221c34" stroke-width="${f(r * 0.03)}" opacity="${f(0.55 + 0.45 * z)}"/>
      <circle cx="${f(mx - mr * 0.3)}" cy="${f(my - mr * 0.3)}" r="${f(mr * 0.28)}" fill="#fff" opacity="${f(0.5 * z)}"/>`;
  }
  return `${halo(cx, cy, r * 1.3, "#c9a6ff", 0.35)}
    <path d="M ${f(cx - w)} ${f(top)} L ${f(cx - w)} ${f(bot)} A ${f(w)} ${f(r * 0.24)} 0 0 0 ${f(cx + w)} ${f(bot)} L ${f(cx + w)} ${f(top)} Z" fill="#3a3550" stroke="#221c34" stroke-width="${f(r * 0.04)}"/>
    <path d="M ${f(cx - w * 0.55)} ${f(top + r * 0.2)} L ${f(cx - w * 0.55)} ${f(bot + r * 0.18)}" stroke="#4a4560" stroke-width="${f(r * 0.18)}" opacity="0.6"/>
    ${[0.28, 0.5].map((t) => `<path d="M ${f(cx - w)} ${f(top + (bot - top) * t * 2 - r * 0.32)} A ${f(w)} ${f(r * 0.24)} 0 0 0 ${f(cx + w)} ${f(top + (bot - top) * t * 2 - r * 0.32)}" fill="none" stroke="#221c34" stroke-width="${f(r * 0.03)}" opacity="0.7"/>`).join("")}
    ${masks}
    <ellipse cx="${cx}" cy="${f(top)}" rx="${f(w)}" ry="${f(r * 0.24)}" fill="#5a5470" stroke="#221c34" stroke-width="${f(r * 0.04)}"/>
    <ellipse cx="${cx}" cy="${f(top - r * 0.08)}" rx="${f(w * 0.48)}" ry="${f(r * 0.13)}" fill="#bcb6d8"/>
    <ellipse cx="${cx}" cy="${f(top - r * 0.12)}" rx="${f(w * 0.4)}" ry="${f(r * 0.1)}" fill="#e9e4ff"/>
    <path d="M ${f(cx + r * 0.12)} ${f(top - r * 0.12)} A ${f(r * 0.12)} ${f(r * 0.05)} 0 1 1 ${f(cx)} ${f(top - r * 0.17)}" fill="none" stroke="#8a86a0" stroke-width="${f(r * 0.03)}"/>
    <circle cx="${cx}" cy="${f(top - r * 0.12)}" r="${f(r * 0.05)}" fill="#c9a6ff"/>`;
}

// The Prism Wyrm, facing left: a cut-crystal head with amethyst horns and
// crest, cyan slit eyes, and a trail of hexagonal scales coiling up behind,
// with a rainbow halo.
function wyrm(cx, cy, r) {
  const hex = (x, y, s, lit) => {
    const pts = [], inner = [];
    for (let k = 0; k < 6; k++) {
      const a = (k * Math.PI) / 3 + Math.PI / 6;
      pts.push([x + Math.cos(a) * s, y + Math.sin(a) * s]);
      inner.push([x + Math.cos(a + Math.PI / 6) * s * 0.5, y + Math.sin(a + Math.PI / 6) * s * 0.5]);
    }
    return (lit ? `<circle cx="${f(x)}" cy="${f(y)}" r="${f(s * 1.4)}" fill="#7af0ff" opacity="0.35" filter="url(#bl4)"/>` : "") +
      poly(pts, lit ? "#7af0ff" : "#2f4f6e", `stroke="${lit ? "#e6fdff" : "#4f7fa8"}" stroke-width="${f(s * 0.08)}"`) + poly(inner, lit ? "#c8fbff" : "#3f6688");
  };
  let scales = "";
  const trail = [[1.05, 0.25, 0.42], [1.55, -0.05, 0.38], [1.95, -0.45, 0.34], [2.1, -0.95, 0.3], [1.8, -1.3, 0.26]];
  trail.slice().reverse().forEach(([u, v, s], i) => { scales += hex(cx + u * r, cy + v * r, s * r, i === 1); });
  const face = [-1, 0], side = [0, 1];
  const at = (u, v) => [cx + face[0] * r * u + side[0] * r * v, cy + face[1] * r * u + side[1] * r * v];
  const upper = [at(1.15, 0), at(0.2, -0.85), at(-0.8, -0.55), at(-0.2, 0)];
  const lower = [at(1.15, 0.04), at(-0.2, 0), at(-0.8, 0.55), at(0.2, 0.85)];
  const horns = [-1, 1].map((k) => poly([at(-0.4, k * 0.38), at(-1.15, k * 0.9 - 0.25), at(-0.55, k * 0.6)], "#b366ff", `stroke="#5a2a9a" stroke-width="${f(r * 0.03)}"`)).join("");
  const crest = [0, 1, 2].map((k) => poly([at(-0.35 - k * 0.22, -0.6), at(-0.5 - k * 0.22, -1.0 + k * 0.05), at(-0.6 - k * 0.22, -0.5)], k % 2 ? "#c98aff" : "#b366ff")).join("");
  const eye = at(0.3, -0.3);
  const arcs = [0, 1, 2].map((k) => {
    const a0 = k * 2.1 - 0.6, a1 = a0 + 1.1, rr = r * 1.45;
    return `<path d="M ${f(cx + Math.cos(a0) * rr)} ${f(cy + Math.sin(a0) * rr)} A ${f(rr)} ${f(rr)} 0 0 1 ${f(cx + Math.cos(a1) * rr)} ${f(cy + Math.sin(a1) * rr)}" fill="none" stroke="${["#ff8ad0", "#ffe27a", "#7af0ff"][k]}" stroke-width="${f(r * 0.07)}" stroke-linecap="round" opacity="0.75"/>`;
  }).join("");
  return `${halo(cx + r * 0.6, cy - r * 0.3, r * 1.6, "#7af0ff", 0.3)}
    ${scales}${arcs}${crest}${horns}
    ${poly(upper, "#4a8cc0", `stroke="#7af0ff" stroke-width="${f(r * 0.03)}" stroke-linejoin="round"`)}
    ${poly(lower, "#22587e", `stroke="#7af0ff" stroke-width="${f(r * 0.03)}" stroke-linejoin="round" stroke-opacity="0.6"`)}
    ${poly([at(1.15, 0), at(0.2, -0.85), at(0.1, -0.05)], "#7ab8e0")}
    <line x1="${f(at(0.6, -0.5)[0])}" y1="${f(at(0.6, -0.5)[1])}" x2="${f(at(0.85, 0.3)[0])}" y2="${f(at(0.85, 0.3)[1])}" stroke="#fff" stroke-width="${f(r * 0.05)}" stroke-linecap="round" opacity="0.5"/>
    <circle cx="${f(eye[0])}" cy="${f(eye[1])}" r="${f(r * 0.18)}" fill="#7af0ff" opacity="0.4" filter="url(#bl3)"/>
    <circle cx="${f(eye[0])}" cy="${f(eye[1])}" r="${f(r * 0.11)}" fill="#bff8ff"/>
    <line x1="${f(eye[0] - r * 0.025)}" y1="${f(eye[1] - r * 0.09)}" x2="${f(eye[0] + r * 0.025)}" y2="${f(eye[1] + r * 0.09)}" stroke="${INK}" stroke-width="${f(r * 0.045)}" stroke-linecap="round"/>`;
}

export default function () {
  const W = 720, H = 520, Y = 150, R = rng(61);
  // back wall: tall vaulted arches between pillars, torch glows
  let wall = "";
  for (let k = 0; k < 7; k++) {
    const x = -30 + k * 130;
    wall += `<path d="M ${x} ${Y + 250} L ${x} ${Y + 40} Q ${x + 52} ${Y - 40} ${x + 104} ${Y + 40} L ${x + 104} ${Y + 250} Z" fill="#170f2c"/>
      <path d="M ${x} ${Y + 250} L ${x} ${Y + 40} Q ${x + 52} ${Y - 40} ${x + 104} ${Y + 40} L ${x + 104} ${Y + 250}" fill="none" stroke="#2c2050" stroke-width="5"/>`;
  }
  let pillars = "";
  for (let k = 0; k < 8; k++) {
    const x = -38 + k * 130;
    pillars += `<rect x="${x}" y="0" width="22" height="${Y + 260}" fill="#241a40"/><rect x="${x + 3}" y="0" width="5" height="${Y + 260}" fill="#34285a"/>`;
  }
  // the vault: ribbed ceiling arcs over everything
  let vault = "";
  for (let k = 0; k < 4; k++) vault += `<path d="M -20 ${Y + 10 - k * 6} Q 360 ${-150 + k * 40} 740 ${Y + 10 - k * 6}" fill="none" stroke="${k % 2 ? "#2c2050" : "#231840"}" stroke-width="${10 - k * 2}"/>`;
  // rose window: six petals in the bosses' colours round a moon-white hub
  const cols = ["#ffb627", "#ff8a3d", "#ff6fae", "#c9a6ff", "#7af0ff", "#7cff4f"];
  const rx = 360, ry = 92, rr = 62;
  let rose = `<circle cx="${rx}" cy="${ry}" r="${rr + 30}" fill="#7b5cff" opacity="0.22" filter="url(#bl24)"/>
    <circle cx="${rx}" cy="${ry}" r="${rr + 8}" fill="#120c26" stroke="#3a2c64" stroke-width="8"/>`;
  for (let k = 0; k < 6; k++) {
    const a0 = (k / 6) * Math.PI * 2 - Math.PI / 2, a1 = a0 + Math.PI / 3, r0 = 20, r1 = rr;
    const pt = (a, r) => `${f(rx + Math.cos(a) * r)} ${f(ry + Math.sin(a) * r)}`;
    rose += `<path d="M ${pt(a0 + 0.06, r0)} L ${pt(a0 + 0.04, r1)} A ${r1} ${r1} 0 0 1 ${pt(a1 - 0.04, r1)} L ${pt(a1 - 0.06, r0)} Z" fill="${cols[k]}" opacity="0.55"/>
      <path d="M ${pt(a0 + 0.2, r0 + 14)} L ${pt(a0 + 0.15, r1 - 10)}" stroke="#fff" stroke-width="3" opacity="0.25" stroke-linecap="round"/>`;
  }
  rose += `<circle cx="${rx}" cy="${ry}" r="18" fill="#e9e4ff" stroke="#3a2c64" stroke-width="5"/><circle cx="${rx}" cy="${ry}" r="7" fill="#c9a6ff"/>
    <path d="M ${rx} ${ry + rr + 10} L ${rx - 120} ${Y + 250} L ${rx + 120} ${Y + 250} Z" fill="#c9a6ff" opacity="0.06" filter="url(#bl12)"/>`;
  // pennants hanging from the vault, one per boss colour
  const pennants = [[70, 0], [180, 1], [540, 4], [650, 5]].map(([x, c]) => `<line x1="${x}" y1="0" x2="${x}" y2="40" stroke="#3a2c64" stroke-width="3"/>
    <path d="M ${x - 22} 40 L ${x + 22} 40 L ${x + 22} 120 L ${x} 104 L ${x - 22} 120 Z" fill="${cols[c]}" opacity="0.5" stroke="#120c26" stroke-width="3"/>
    <circle cx="${x}" cy="70" r="8" fill="#fff" opacity="0.35"/>`).join("");
  const torches = [[87, Y + 110], [633, Y + 110]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="40" fill="#ff8a3d" opacity="0.35" filter="url(#bl16)"/>
    <rect x="${x - 4}" y="${y}" width="8" height="22" rx="2" fill="#5a3a2a"/>
    <path d="M ${x - 8} ${y} Q ${x - 9} ${y - 14} ${x} ${y - 26} Q ${x + 9} ${y - 14} ${x + 8} ${y} Z" fill="#ff8a3d"/>
    <path d="M ${x - 4} ${y} Q ${x - 4} ${y - 8} ${x} ${y - 16} Q ${x + 4} ${y - 8} ${x + 4} ${y} Z" fill="#ffd166"/>`).join("");
  // rune circle on the floor
  let runes = "";
  for (let k = 0; k < 24; k++) {
    const a = (k / 24) * Math.PI * 2, x = 360 + Math.cos(a) * 250, y = Y + 300 + Math.sin(a) * 40;
    runes += `<rect x="${f(x - 3)}" y="${f(y - 1.5)}" width="6" height="3" rx="1" fill="#c9a6ff" opacity="${f(0.35 + 0.4 * R())}"/>`;
  }
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${blurs()}
  <defs>
    <linearGradient id="bhSky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0a081c"/><stop offset="1" stop-color="#1e1440"/></linearGradient>
    <linearGradient id="bhFloor" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2a1d4a"/><stop offset="1" stop-color="#120c26"/></linearGradient>
  </defs>
  <rect width="${W}" height="${H}" fill="url(#bhSky)"/>
  ${wall}${vault}${pillars}${rose}${pennants}${torches}
  <rect x="0" y="${Y + 250}" width="${W}" height="${H - Y - 250}" fill="url(#bhFloor)"/>
  <rect x="0" y="${Y + 248}" width="${W}" height="4" fill="#3a2c64"/>
  <ellipse cx="360" cy="${Y + 300}" rx="262" ry="46" fill="#7b5cff" opacity="0.18" filter="url(#bl8)"/>
  <ellipse cx="360" cy="${Y + 300}" rx="250" ry="40" fill="none" stroke="#c9a6ff" stroke-width="2.5" opacity="0.55"/>
  <ellipse cx="360" cy="${Y + 300}" rx="200" ry="31" fill="none" stroke="#c9a6ff" stroke-width="1.5" opacity="0.35"/>
  ${runes}
  ${pool(150, Y + 250, 70, "#7cff4f", 0.35)}${pool(360, Y + 238, 70, "#c9a6ff", 0.35)}${pool(620, Y + 250, 80, "#7af0ff", 0.35)}
  ${totem(360, Y + 172, 64)}
  ${wyrm(596, Y + 150, 44)}
  <g data-layer="glitch" data-move="bob 5 0.6 0.2">${glitch(150, Y + 138, 42)}</g>
  ${pool(222, Y + 318, 80, "#ff6fae", 0.45)}${pool(360, Y + 322, 110, "#ff8a3d", 0.55)}${pool(505, Y + 322, 70, "#ffb627", 0.35)}
  <g data-layer="queen" data-move="bob 4 0.8 0.5">${broodQueen(222, Y + 262, 52)}</g>
  <g data-layer="pinata" data-move="sway 5 0.45 0" data-pivot="505 0">${pinata(505, Y + 236, 48)}</g>
  <g data-layer="king" data-move="idle 3 0.5 0">${anvilKing(360, Y + 248, 82)}</g>
  ${motes(23, 26, 40, Y + 100, 680, Y + 340, ["#ffd36b", "#ff8a3d", "#c9a6ff", "#7af0ff"])}
  ${sparkle(470, Y + 70, 8, "#fff4cf", 0.8)}${sparkle(250, Y + 92, 6, "#e6fdff", 0.7)}
  <rect width="${W}" height="${H}" fill="#0D0F26" opacity="0.06"/>
  </svg>`;
}

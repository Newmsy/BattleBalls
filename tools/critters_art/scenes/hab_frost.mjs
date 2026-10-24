// Frost habitat: an aurora ice plateau. Aurora curtains (aqua into rose-
// violet) over a polar night, crystal spires and snowy mesas, dark still
// water with drifting floes. Signature light: rose-aqua aurora on ice.
// Stage: a flat ice floe on the water at (200, 330).
import { blurs, critter, sky, motes, sparkle, shade, rng, f } from "./_p.mjs";
import { W, H, SX, SY, fades, withHero } from "./_hab.mjs";

export const size = [W, H];

function spire(x, y, h, w, o = 1, lit = "#c8f4ff") {
  return `<g opacity="${o}">
    <path d="M ${x - w} ${y} L ${x - w * 0.3} ${y - h} L ${x + w * 0.1} ${y - h * 1.04} L ${x + w} ${y} Z" fill="#2e5a86"/>
    <path d="M ${x - w * 0.3} ${y - h} L ${x + w * 0.1} ${y - h * 1.04} L ${x + w} ${y} L ${x} ${y} Z" fill="#1e3e66"/>
    <path d="M ${x - w * 0.3} ${y - h} L ${x - w * 0.6} ${y}" stroke="${lit}" stroke-width="1.6" opacity="0.7"/></g>`;
}

function floe(cx, cy, rx, ry, seed, o = 1) {
  const R = rng(seed);
  const n = 10, pts = Array.from({ length: n }, (_, k) => {
    const a = (k / n) * Math.PI * 2, m = 0.85 + R() * 0.2;
    return [cx + Math.cos(a) * rx * m, cy + Math.sin(a) * ry * m];
  });
  const poly = (dy) => pts.map(([x, y]) => `${f(x)},${f(y + dy)}`).join(" ");
  return `<g opacity="${o}"><polygon points="${poly(ry * 0.5)}" fill="#3a6a9a"/><polygon points="${poly(0)}" fill="#cfeeff" stroke="#6aa0cc" stroke-width="1.5" stroke-linejoin="round"/></g>`;
}

function scene() {
  const R = rng(149);
  // Aurora curtains: layered blurred ribbons.
  const ribbon = (d, col, w, o, b) => `<path d="${d}" fill="none" stroke="${col}" stroke-width="${w}" opacity="${o}" filter="url(#bl${b})" stroke-linecap="round"/>`;
  const aurora = `
    ${ribbon("M -40 120 Q 120 40 260 90 Q 400 140 520 70 Q 640 10 820 60", "#5ae8d0", 60, 0.36, 24)}
    ${ribbon("M -40 110 Q 120 30 260 80 Q 400 130 520 60 Q 640 0 820 50", "#8af0e0", 16, 0.35, 8)}
    ${ribbon("M -20 170 Q 140 110 300 150 Q 460 190 600 120 Q 700 80 820 110", "#d878c8", 50, 0.3, 24)}
    ${ribbon("M -20 160 Q 140 100 300 140 Q 460 180 600 110 Q 700 70 820 100", "#f0a0d8", 10, 0.3, 6)}
    ${Array.from({ length: 30 }, (_, k) => {
      const x = k * 28 - 10, t = x / 780;
      const y = 80 + Math.sin(t * 6) * 30 - 10;
      return `<path d="M ${f(x)} ${f(y)} L ${f(x + 4)} ${f(y + 70 + R() * 50)}" stroke="${k % 2 ? "#8af0e0" : "#c0f8ec"}" stroke-width="${f(4 + R() * 6)}" opacity="${f(0.06 + R() * 0.1)}" filter="url(#bl4)"/>`;
    }).join("")}`;
  // Far snowy mesas and crystal spires.
  const far = `
    <path d="M -10 262 L 30 220 L 120 214 L 150 236 L 220 230 L 260 262 Z" fill="#2a4a78"/>
    <path d="M 30 220 L 120 214 L 112 222 L 40 226 Z" fill="#b8e0ff" opacity="0.7"/>
    <path d="M 420 262 L 460 200 L 560 190 L 600 220 L 700 214 L 790 230 L 790 262 Z" fill="#203c66"/>
    <path d="M 460 200 L 560 190 L 552 198 L 466 206 Z" fill="#a8d0f0" opacity="0.5"/>
    ${spire(330, 262, 70, 14, 0.85)}${spire(352, 262, 44, 10, 0.8)}${spire(500, 262, 110, 18, 0.7)}${spire(530, 262, 70, 12, 0.65)}${spire(660, 262, 90, 16, 0.55)}${spire(80, 262, 54, 11, 0.85)}`;
  // Ice plain and dark water.
  let ripples = "";
  for (let k = 0; k < 20; k++) {
    const x = R() * 780, y = 284 + R() * 120, w = 12 + R() * 30;
    ripples += `<path d="M ${f(x)} ${f(y)} q ${f(w / 2)} -2 ${f(w)} 0" stroke="#6ab0d8" stroke-width="1.2" fill="none" opacity="${f(0.2 + R() * 0.2)}"/>`;
  }
  const water = `
    <rect x="0" y="262" width="${W}" height="${H - 262}" fill="url(#hrWater)"/>
    <path d="M 0 262 L 780 262" stroke="#b8e8ff" stroke-width="1.5" opacity="0.4"/>
    <ellipse cx="300" cy="300" rx="260" ry="30" fill="#8af0e0" opacity="0.08" filter="url(#bl16)"/>
    <ellipse cx="420" cy="320" rx="200" ry="20" fill="#d878c8" opacity="0.08" filter="url(#bl16)"/>
    ${ripples}`;
  // Drifting floes, and near ice shelves left and right.
  const floes = `
    ${floe(470, 300, 40, 9, 3, 0.7)}${floe(620, 290, 28, 6, 5, 0.55)}${floe(720, 330, 36, 8, 9, 0.45)}
    <path d="M -10 300 L 40 292 L 70 304 L 60 330 L 90 360 L 70 460 L -10 460 Z" fill="#5a8cba"/>
    <path d="M -10 300 L 40 292 L 70 304 L 62 312 L -10 312 Z" fill="#c8e8fa"/>
    <path d="M 40 292 L 70 304 L 60 330 L 90 360" stroke="#6aa0cc" stroke-width="2" fill="none"/>
    ${spire(20, 300, 80, 16, 1)}${spire(48, 300, 46, 10, 1)}
    <path d="M 520 460 L 540 400 L 620 384 L 720 390 L 790 380 L 790 460 Z" fill="#2a4e7a"/>
    <path d="M 540 400 L 620 384 L 720 390 L 790 380 L 790 392 L 720 400 L 620 394 L 548 408 Z" fill="#8ab8dc" opacity="0.7"/>`;
  // Big crystal cluster right of the stage (outside the reserved zone).
  const cluster = `
    <ellipse cx="380" cy="300" rx="60" ry="60" fill="#8af0e0" opacity="0.14" filter="url(#bl16)"/>
    ${floe(372, 372, 58, 11, 21)}
    <g transform="translate(380 372)">
      <polygon points="-30,0 -22,-90 -10,-104 2,-88 4,0" fill="#9adcf4" stroke="#2e5a86" stroke-width="2.5" stroke-linejoin="round"/>
      <polygon points="-10,-104 2,-88 4,0 -8,0" fill="#6ab4dc"/>
      <polygon points="0,0 14,-60 24,-66 34,-56 34,0" fill="#b8ecff" stroke="#2e5a86" stroke-width="2.5" stroke-linejoin="round"/>
      <polygon points="-44,0 -48,-40 -40,-50 -32,-42 -28,0" fill="#7ac8ec" stroke="#2e5a86" stroke-width="2.5" stroke-linejoin="round"/>
      <path d="M -22 -88 L -24 -10 M 16 -56 L 14 -10" stroke="#f0fcff" stroke-width="2" opacity="0.8"/>
    </g>`;
  // Stage: a wide ice floe with snow cap and a soft aurora-tinted pool of light.
  const stage = `
    <ellipse cx="${SX}" cy="${SY}" rx="200" ry="50" fill="#a8f0ff" opacity="0.14" filter="url(#bl24)"/>
    <ellipse cx="${SX}" cy="${SY + 36}" rx="160" ry="16" fill="#8af0e0" opacity="0.18" filter="url(#bl8)"/>
    <path d="M ${SX - 128} ${SY + 2} L ${SX - 118} ${SY + 26} L ${SX - 40} ${SY + 38} L ${SX + 60} ${SY + 36} L ${SX + 120} ${SY + 24} L ${SX + 130} ${SY + 4} Z" fill="#4a86b8" stroke="#1e3e66" stroke-width="2.5" stroke-linejoin="round"/>
    <path d="M ${SX - 118} ${SY + 26} L ${SX - 40} ${SY + 38} L ${SX + 60} ${SY + 36} L ${SX + 120} ${SY + 24}" stroke="#8af0e0" stroke-width="2" fill="none" opacity="0.6"/>
    <path d="M ${SX - 128} ${SY + 2} L ${SX - 110} ${SY - 16} L ${SX - 40} ${SY - 24} L ${SX + 50} ${SY - 22} L ${SX + 114} ${SY - 12} L ${SX + 130} ${SY + 4} L ${SX + 90} ${SY + 18} L ${SX - 20} ${SY + 22} L ${SX - 100} ${SY + 16} Z" fill="#d6f2ff" stroke="#6aa0cc" stroke-width="2.5" stroke-linejoin="round"/>
    <path d="M ${SX - 100} ${SY - 6} Q ${SX - 20} ${SY - 20} ${SX + 90} ${SY - 8} Q ${SX + 20} ${SY + 6} ${SX - 100} ${SY - 6} Z" fill="#f4fcff"/>
    <path d="M ${SX - 110} ${SY - 16} L ${SX - 40} ${SY - 24} L ${SX + 50} ${SY - 22} L ${SX + 114} ${SY - 12}" stroke="#ffffff" stroke-width="2" fill="none"/>
    <path d="M ${SX - 60} ${SY + 8} l 18 -6 l 10 6 M ${SX + 40} ${SY + 10} l 14 -8" stroke="#9ac8e8" stroke-width="1.6" fill="none"/>
    <ellipse cx="${SX + 10}" cy="${SY - 6}" rx="70" ry="9" fill="#f0a0d8" opacity="0.16" filter="url(#bl8)"/>`;
  // Background frost critters: one on a far floe, one by the left spires.
  const bg = `${critter(470, 290, 8, "#8fe6ff", { acc: "crystal", mood: "happy", look: [-0.5, 0], rim: "#f0a0d8", rimSide: -1 })}
    ${critter(70, 250, 6.5, "#8fe6ff", { acc: "crystal", mood: "sleepy", rim: "#8af0e0", rimSide: 1 })}`;
  let spk = "";
  [[380, 268, 5], [356, 340, 3.5], [24, 230, 4], [96, 300, 3]].forEach(([x, y, r]) => (spk += sparkle(x, y, r, "#f0fcff", 0.8)));

  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${blurs()}
  <defs>
    <linearGradient id="hrSky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#080c26"/><stop offset="0.55" stop-color="#14204a"/><stop offset="1" stop-color="#26406e"/></linearGradient>
    <linearGradient id="hrWater" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#1e3a66"/><stop offset="0.5" stop-color="#142a50"/><stop offset="1" stop-color="#0c1836"/></linearGradient>
  </defs>
  <rect width="${W}" height="${H}" fill="url(#hrSky)"/>
  ${sky(151, 60, 0, 0, 780, 240)}
  ${aurora}${far}${water}${bg}${floes}${cluster}${stage}${spk}
  ${motes(43, 26, 0, 40, 780, 420, ["#f0fcff", "#c8f4ff", "#f0c8e8"])}
  ${fades("hr", { right: 0.42 })}
  </svg>`;
}

export const many = {
  hab_frost: scene,
  hab_frost_ctx: withHero(scene, "#8fe6ff", "crystal", "#f0a0d8"),
};
export default scene;

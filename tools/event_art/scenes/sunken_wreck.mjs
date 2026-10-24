// Sea family: a sunken wooden ship on the sea floor, god rays from above.
// In front of the broken hull a treasure chest glints gold, lid ajar; beside it
// a huge Sea-family critter sleeps, snoring a trail of bubbles. Grab and go?
import { ball, shade, INK } from "../../brand/parts.mjs";

const SEA = "#3fa9f5";
const W = 720, H = 440;

function rng(seed) {
  let s = seed;
  return () => ((s = (s * 16807) % 2147483647) / 2147483647);
}
const f = (n) => n.toFixed(1);

const twinkle = (x, y, s, col = "#fff", o = 1) =>
  `<path d="M ${x} ${y - s} Q ${x} ${y} ${x + s} ${y} Q ${x} ${y} ${x} ${y + s} Q ${x} ${y} ${x - s} ${y} Q ${x} ${y} ${x} ${y - s} Z" fill="${col}" opacity="${o}"/>`;

// One bubble: thin rim, faint fill, white catch-light.
const bub = (x, y, r, o = 0.8) => `
  <circle cx="${f(x)}" cy="${f(y)}" r="${f(r)}" fill="url(#swBub)" stroke="#d6f6ff" stroke-width="${Math.max(1, r * 0.12).toFixed(2)}" opacity="${o}"/>
  <circle cx="${f(x - r * 0.35)}" cy="${f(y - r * 0.38)}" r="${f(r * 0.24)}" fill="#fff" opacity="${(o * 0.9).toFixed(2)}"/>`;

// Wavy kelp frond with little leaf blades.
function kelp(x, y, h, col, sway, R, blades = 5, wdt = 9) {
  const d = `M ${x} ${y} C ${x + sway} ${y - h * 0.33} ${x - sway} ${y - h * 0.66} ${x + sway * 0.5} ${y - h}`;
  let leaves = "";
  for (let k = 1; k <= blades; k++) {
    const t = k / (blades + 1);
    // point along the bezier
    const u = 1 - t;
    const px = u * u * u * x + 3 * u * u * t * (x + sway) + 3 * u * t * t * (x - sway) + t * t * t * (x + sway * 0.5);
    const py = u * u * u * y + 3 * u * u * t * (y - h * 0.33) + 3 * u * t * t * (y - h * 0.66) + t * t * t * (y - h);
    const dir = k % 2 ? 1 : -1, L = 14 + R() * 12;
    leaves += `<path d="M ${f(px)} ${f(py)} q ${dir * L * 0.6} ${-L * 0.2} ${dir * L} ${-L * 0.75} q ${-dir * L * 0.55} ${L * 0.05} ${-dir * L} ${L * 0.75} Z" fill="${col}" stroke="${shade(col, -0.45)}" stroke-width="1.5" stroke-linejoin="round"/>`;
  }
  return `<path d="${d}" fill="none" stroke="${shade(col, -0.45)}" stroke-width="${wdt + 4}" stroke-linecap="round"/>
    <path d="${d}" fill="none" stroke="${col}" stroke-width="${wdt}" stroke-linecap="round"/>
    <path d="${d}" fill="none" stroke="${shade(col, 0.45)}" stroke-width="${wdt * 0.25}" stroke-linecap="round" opacity="0.6" transform="translate(-2 0)"/>
    ${leaves}`;
}

// A gold coin seen at an angle.
const coin = (x, y, r, sy = 0.45, rot = 0) => `
  <g transform="rotate(${rot} ${x} ${y})">
    <ellipse cx="${x}" cy="${y + r * 0.15}" rx="${r}" ry="${r * sy}" fill="#8a5a10"/>
    <ellipse cx="${x}" cy="${y}" rx="${r}" ry="${r * sy}" fill="url(#swGold)" stroke="#9a6a12" stroke-width="1.2"/>
    <ellipse cx="${x}" cy="${y}" rx="${r * 0.6}" ry="${r * sy * 0.6}" fill="none" stroke="#fff3b0" stroke-width="1" opacity="0.7"/>
  </g>`;

// The treasure chest: lid open a crack with gold light pouring out.
function chest(cx, cy) {
  const w = 128, h = 66, lidH = 40;
  const x0 = cx - w / 2, y0 = cy - h / 2;
  const wood = "#7a3f22", woodDk = "#4a2214";
  let planks = "";
  for (let k = 1; k < 3; k++) planks += `<line x1="${x0 + 4}" y1="${y0 + (h * k) / 3}" x2="${x0 + w - 4}" y2="${y0 + (h * k) / 3}" stroke="${woodDk}" stroke-width="2" opacity="0.7"/>`;
  const band = (x) => `<rect x="${x - 7}" y="${y0 - 2}" width="14" height="${h + 4}" rx="3" fill="url(#swGoldBand)" stroke="#6a440c" stroke-width="2"/>
    <circle cx="${x}" cy="${y0 + 8}" r="2.2" fill="#6a440c"/><circle cx="${x}" cy="${y0 + h - 8}" r="2.2" fill="#6a440c"/>`;
  // lid: hinged at the back, tilted up ~22 degrees
  const lid = `
    <g transform="translate(0 -24) rotate(-7 ${x0 + w} ${y0})">
      <path d="M ${x0 - 4} ${y0} L ${x0 - 4} ${y0 - lidH * 0.45} Q ${cx} ${y0 - lidH * 1.35} ${x0 + w + 4} ${y0 - lidH * 0.45} L ${x0 + w + 4} ${y0} Z" fill="${wood}" stroke="${INK}" stroke-width="3" stroke-linejoin="round"/>
      <path d="M ${x0 - 4} ${y0} L ${x0 - 4} ${y0 - lidH * 0.45} Q ${cx} ${y0 - lidH * 1.35} ${x0 + w + 4} ${y0 - lidH * 0.45} L ${x0 + w + 4} ${y0} Z" fill="url(#swLidShade)"/>
      <path d="M ${x0 + 2} ${y0 - lidH * 0.5} Q ${cx} ${y0 - lidH * 1.22} ${x0 + w - 2} ${y0 - lidH * 0.5}" fill="none" stroke="#c07a4a" stroke-width="2" opacity="0.6"/>
      <rect x="${x0 + 18 - 7}" y="${y0 - lidH * 0.95}" width="14" height="${lidH * 0.95}" fill="url(#swGoldBand)" stroke="#6a440c" stroke-width="2"/>
      <rect x="${x0 + w - 18 - 7}" y="${y0 - lidH * 0.95}" width="14" height="${lidH * 0.95}" fill="url(#swGoldBand)" stroke="#6a440c" stroke-width="2"/>
      <rect x="${x0 - 6}" y="${y0 - 6}" width="${w + 12}" height="8" rx="3" fill="url(#swGoldBand)" stroke="#6a440c" stroke-width="2"/>
      <path d="M ${x0 + 14} ${y0 - lidH * 0.62} q 10 -10 22 -12" fill="none" stroke="#5a2a1a" stroke-width="2" opacity="0.7"/>
      <ellipse cx="${x0 + 40}" cy="${y0 - 22}" rx="7" ry="4" fill="#5fd068" opacity="0.7"/>
      <ellipse cx="${x0 + 46}" cy="${y0 - 24}" rx="5" ry="3" fill="#7ee08a" opacity="0.7"/>
    </g>`;
  // light pouring out of the gap
  const glow = `
    <ellipse cx="${cx}" cy="${y0 - 6}" rx="${w * 0.9}" ry="44" fill="#ffd23f" opacity="0.55" filter="url(#swBlur18)"/>
    <path d="M ${x0 + 6} ${y0 - 2} L ${cx - 90} ${y0 - 120} L ${cx + 40} ${y0 - 150} L ${x0 + w - 6} ${y0 - 14} Z" fill="url(#swBeam)" opacity="0.65" filter="url(#swBlur6)"/>
    <path d="M ${x0 + 2} ${y0 - 18} Q ${cx} ${y0 - 40} ${x0 + w - 2} ${y0 - 28} L ${x0 + w - 2} ${y0 + 2} L ${x0 + 2} ${y0 + 2} Z" fill="#fff3b0"/>
    <path d="M ${x0 + 2} ${y0 - 6} Q ${cx} ${y0 - 20} ${x0 + w - 2} ${y0 - 14} L ${x0 + w - 2} ${y0 + 2} L ${x0 + 2} ${y0 + 2} Z" fill="#ffd23f"/>`;
  // gold heap peeking out
  let heap = "";
  const R = rng(91);
  for (let k = 0; k < 16; k++) {
    const x = x0 + 14 + R() * (w - 28), y = y0 - 6 - R() * 14 * Math.sin(((x - x0) / w) * Math.PI);
    heap += coin(x, y, 7 + R() * 3, 0.45, (R() - 0.5) * 40);
  }
  heap += `<circle cx="${cx + 18}" cy="${y0 - 20}" r="8" fill="#ff4fb8" stroke="#8a1a5a" stroke-width="2"/><circle cx="${cx + 15}" cy="${y0 - 23}" r="2.5" fill="#fff" opacity="0.9"/>`;
  heap += `<polygon points="${cx - 30},${y0 - 28} ${cx - 20},${y0 - 18} ${cx - 30},${y0 - 8} ${cx - 40},${y0 - 18}" fill="#3ee6ff" stroke="#127a8a" stroke-width="2"/><polygon points="${cx - 30},${y0 - 28} ${cx - 20},${y0 - 18} ${cx - 30},${y0 - 20}" fill="#d8fbff"/>`;
  // necklace of pearls spilling over the front
  let pearls = "";
  for (let k = 0; k < 9; k++) {
    const t = k / 8;
    const px = x0 + w * 0.62 + t * 34, py = y0 + 2 + Math.sin(t * Math.PI) * 30 + t * 22;
    pearls += `<circle cx="${f(px)}" cy="${f(py)}" r="4" fill="url(#swPearl)" stroke="#a88fb0" stroke-width="0.8"/>`;
  }
  return `
  ${glow}
  <!-- body -->
  <rect x="${x0}" y="${y0}" width="${w}" height="${h}" rx="5" fill="${wood}" stroke="${INK}" stroke-width="3"/>
  <rect x="${x0}" y="${y0}" width="${w}" height="${h}" rx="5" fill="url(#swChestShade)"/>
  ${planks}
  ${heap}
  ${band(x0 + 18)}${band(x0 + w - 18)}
  <rect x="${x0 - 3}" y="${y0 - 3}" width="${w + 6}" height="8" rx="3" fill="url(#swGoldBand)" stroke="#6a440c" stroke-width="2"/>
  <!-- lock -->
  <path d="M ${cx - 11} ${y0 + 4} h 22 v 18 q -11 10 -22 0 Z" fill="url(#swGoldBand)" stroke="#6a440c" stroke-width="2"/>
  <circle cx="${cx}" cy="${y0 + 13}" r="3.2" fill="${INK}"/><rect x="${cx - 1.5}" y="${y0 + 14}" width="3" height="6" fill="${INK}"/>
  ${lid}
  ${pearls}
  <!-- barnacles -->
  <circle cx="${x0 + 6}" cy="${y0 + h - 6}" r="4" fill="#c9c3d8" stroke="#5a5470" stroke-width="1.5"/><circle cx="${x0 + 14}" cy="${y0 + h - 3}" r="3" fill="#c9c3d8" stroke="#5a5470" stroke-width="1.5"/>
  ${twinkle(cx + 36, y0 - 34, 12, "#fff6c8")}
  ${twinkle(x0 + 8, y0 - 18, 8, "#ffe27a", 0.9)}
  ${twinkle(cx - 6, y0 - 52, 6, "#fff", 0.8)}`;
}

// The big sleeping sea critter: squashy, fin, closed eyes, open snoring mouth.
function sleeper(cx, cy, r) {
  const sx = 1.12, sy = 0.9;
  const ey = cy - r * 0.12;
  const ex = r * 0.36;
  const lid = (x) => `<path d="M ${x - r * 0.17} ${ey} Q ${x} ${ey + r * 0.13} ${x + r * 0.17} ${ey}" fill="none" stroke="${INK}" stroke-width="${r * 0.06}" stroke-linecap="round"/>
    <path d="M ${x + r * 0.17} ${ey} l ${r * 0.05} ${-r * 0.04}" stroke="${INK}" stroke-width="${r * 0.04}" stroke-linecap="round"/>`;
  // fins
  const fin = `<path d="M ${cx - r * 0.5} ${cy - r * 0.78} Q ${cx - r * 0.15} ${cy - r * 1.42} ${cx + r * 0.5} ${cy - r * 1.22} Q ${cx + r * 0.22} ${cy - r * 0.98} ${cx + r * 0.4} ${cy - r * 0.78} Z" fill="${shade(SEA, 0.2)}" stroke="${shade(SEA, -0.5)}" stroke-width="${r * 0.05}" stroke-linejoin="round"/>
    <path d="M ${cx - r * 0.25} ${cy - r * 0.9} Q ${cx - r * 0.02} ${cy - r * 1.22} ${cx + r * 0.32} ${cy - r * 1.2}" fill="none" stroke="${shade(SEA, 0.6)}" stroke-width="${r * 0.03}" opacity="0.7"/>`;
  const side = (d) => `<path d="M ${cx + d * r * 1.0} ${cy + r * 0.25} q ${d * r * 0.42} ${r * 0.0} ${d * r * 0.5} ${r * 0.38} q ${-d * r * 0.3} ${r * 0.05} ${-d * r * 0.58} ${-r * 0.12} Z" fill="${shade(SEA, 0.1)}" stroke="${shade(SEA, -0.5)}" stroke-width="${r * 0.045}" stroke-linejoin="round"/>`;
  // freckle spots on the back
  let spots = "";
  for (const [a, b, s] of [[0.55, -0.55, 0.07], [0.72, -0.3, 0.05], [0.4, -0.72, 0.05], [0.8, 0.0, 0.045]])
    spots += `<circle cx="${cx + a * r * sx}" cy="${cy + b * r * sy}" r="${r * s}" fill="${shade(SEA, -0.25)}" opacity="0.7"/>`;
  return `
  ${fin}
  ${side(1)}
  ${ball(cx, cy, r, SEA, { sx, sy, glow: false })}
  <!-- rim light from the chest (left) and caustics on top -->
  <ellipse cx="${cx}" cy="${cy}" rx="${r * sx}" ry="${r * sy}" fill="url(#swRimGold)"/>
  <ellipse cx="${cx}" cy="${cy}" rx="${r * sx}" ry="${r * sy}" fill="url(#swRimTop)"/>
  ${spots}
  ${side(-1)}
  <g transform="translate(${-r * 0.24} 0)">
  ${lid(cx - ex)}${lid(cx + ex)}
  <!-- snoring mouth, a bubble swelling out of it -->
  <ellipse cx="${cx - r * 0.02}" cy="${cy + r * 0.3}" rx="${r * 0.12}" ry="${r * 0.15}" fill="${INK}"/>
  <ellipse cx="${cx - r * 0.02}" cy="${cy + r * 0.37}" rx="${r * 0.07}" ry="${r * 0.05}" fill="#ff5a7a"/>
  <ellipse cx="${cx - r * 0.62}" cy="${cy + r * 0.14}" rx="${r * 0.13}" ry="${r * 0.07}" fill="#ff8ad0" opacity="0.45"/>
  <ellipse cx="${cx + r * 0.62}" cy="${cy + r * 0.14}" rx="${r * 0.13}" ry="${r * 0.07}" fill="#ff8ad0" opacity="0.45"/>
  <circle cx="${cx - r * 0.2}" cy="${cy + r * 0.24}" r="${r * 0.15}" fill="url(#swBub)" stroke="#e6fbff" stroke-width="2.2" opacity="0.95"/>
  <circle cx="${cx - r * 0.25}" cy="${cy + r * 0.18}" r="${r * 0.04}" fill="#fff"/>
  </g>`;
}

export default function () {
  const R = rng(41);

  // God rays from the surface.
  let rays = "";
  for (const [x, wdt, ang, o] of [[150, 46, 14, 0.22], [250, 70, 10, 0.3], [360, 90, 4, 0.34], [470, 56, -4, 0.26], [580, 40, -10, 0.2], [310, 30, 8, 0.2]]) {
    const dx = Math.tan((ang * Math.PI) / 180) * 440;
    rays += `<path d="M ${x - wdt / 2} -10 L ${x + wdt / 2} -10 L ${x + dx + wdt * 1.4} 440 L ${x + dx - wdt * 1.4} 440 Z" fill="url(#swRay)" opacity="${o}"/>`;
  }
  // Surface ripples (caustic band at the top).
  let ripples = "";
  for (let k = 0; k < 26; k++) {
    const x = R() * W, y = 6 + R() * 34, w = 20 + R() * 50;
    ripples += `<path d="M ${f(x)} ${f(y)} q ${f(w / 2)} -6 ${f(w)} 0" fill="none" stroke="#bfefff" stroke-width="${(1 + R() * 1.5).toFixed(1)}" opacity="${(0.15 + R() * 0.3).toFixed(2)}"/>`;
  }
  // Marine snow.
  let snow = "";
  for (let k = 0; k < 70; k++) {
    const x = R() * W, y = R() * H, r = 0.6 + R() * 1.6;
    snow += `<circle cx="${f(x)}" cy="${f(y)}" r="${r.toFixed(2)}" fill="#cfefff" opacity="${(0.2 + R() * 0.5).toFixed(2)}"/>`;
  }
  // Far fish silhouettes.
  let fish = "";
  for (const [x, y, s, d] of [[96, 118, 1, 1], [122, 104, 0.8, 1], [112, 134, 0.7, 1], [628, 90, 0.9, -1], [650, 108, 0.7, -1]]) {
    fish += `<path d="M ${x} ${y} q ${d * 10 * s} ${-7 * s} ${d * 20 * s} 0 q ${-d * 10 * s} ${7 * s} ${-d * 20 * s} 0 Z M ${x} ${y} l ${-d * 7 * s} ${-5 * s} l 0 ${10 * s} Z" fill="#1a3f7a" opacity="0.8"/>`;
  }

  // Ship hull (midground): tilted, bow lifting to the left, broken open in the middle.
  const hull = `
  <g>
    <!-- far half (stern) on the right, sunk in sand -->
    <path d="M 430 300 L 448 186 Q 520 160 640 172 L 700 160 L 712 186 Q 700 250 690 300 Z" fill="url(#swHullFar)" stroke="#0a0a22" stroke-width="3" stroke-linejoin="round"/>
    ${[0, 1, 2, 3, 4, 5].map((k) => `<path d="M ${450 + k * 0} ${200 + k * 18} Q 560 ${178 + k * 18} 706 ${182 + k * 19}" fill="none" stroke="#0e0d2c" stroke-width="2.5" opacity="0.8"/>`).join("")}
    <path d="M 448 186 Q 520 160 640 172 L 700 160" fill="none" stroke="#6ab8ff" stroke-width="3" opacity="0.5"/>
    <!-- stern cabin with glowing portholes -->
    <path d="M 560 172 L 566 128 L 690 120 L 700 160 Z" fill="#2a2458" stroke="#0a0a22" stroke-width="3" stroke-linejoin="round"/>
    <path d="M 566 128 L 690 120" stroke="#6ab8ff" stroke-width="2.5" opacity="0.5"/>
    ${[[600, 150], [640, 147], [678, 144]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="9" fill="#3ee6ff" opacity="0.35" filter="url(#swBlur6)"/><circle cx="${x}" cy="${y}" r="7" fill="#0b1b3e" stroke="#b08a3c" stroke-width="2.5"/><circle cx="${x}" cy="${y}" r="4.5" fill="#3ee6ff" opacity="0.55"/>`).join("")}
    <!-- broken stern mast -->
    <path d="M 612 122 L 600 40 L 610 38 L 624 120 Z" fill="#3a2a40" stroke="#0a0a22" stroke-width="2.5"/>
    <path d="M 600 40 l -4 -10 l 8 4 l 2 -10 l 4 14 Z" fill="#3a2a40"/>
    <!-- near half (bow) on the left, tilted -->
    <path d="M -20 300 L -20 200 Q 60 150 150 136 L 214 96 L 228 112 Q 250 200 262 300 Z" fill="url(#swHullNear)" stroke="#0a0a22" stroke-width="3" stroke-linejoin="round"/>
    ${[0, 1, 2, 3, 4, 5, 6].map((k) => `<path d="M -20 ${212 + k * 16} Q 120 ${160 + k * 20} ${234 + k * 4} ${128 + k * 26}" fill="none" stroke="#0e0d2c" stroke-width="2.5" opacity="0.8"/>`).join("")}
    <path d="M -20 200 Q 60 150 150 136 L 214 96" fill="none" stroke="#6ab8ff" stroke-width="3" opacity="0.55"/>
    <!-- broken plank ends at the tear -->
    <path d="M 228 112 l 16 10 l -10 8 l 18 14 l -12 10 l 16 18 l -10 12 l 14 20 l -8 10 l 12 26 l -6 14 l 12 30 L 262 300 Q 250 200 228 112 Z" fill="#1c1840" stroke="#0a0a22" stroke-width="2"/>
    <path d="M 430 300 l -14 -16 l 10 -14 l -16 -18 l 12 -12 l -14 -24 l 12 -10 l -8 -24 l 12 -8 l -6 -20 L 448 186 Z" fill="#1c1840" stroke="#0a0a22" stroke-width="2"/>
    <!-- bowsprit + figurehead knob -->
    <path d="M 212 100 L 276 58 L 280 66 L 220 108 Z" fill="#3a2a40" stroke="#0a0a22" stroke-width="2.5"/>
    <circle cx="279" cy="60" r="7" fill="#b08a3c" stroke="#5a3a10" stroke-width="2"/>
    <!-- main mast leaning left, torn sail -->
    <path d="M 110 160 L 52 18 L 64 12 L 124 156 Z" fill="#3a2a40" stroke="#0a0a22" stroke-width="2.5"/>
    <path d="M 38 40 L 112 8 L 104 22 Z" fill="#3a2a40" stroke="#0a0a22" stroke-width="2"/>
    <path d="M 62 42 Q 120 40 132 78 L 120 92 L 126 104 L 108 118 Q 96 82 78 76 Z" fill="#c9c0e6" opacity="0.55" stroke="#0a0a22" stroke-width="2"/>
    <path d="M 70 52 Q 112 54 122 82" fill="none" stroke="#ffffff" stroke-width="1.5" opacity="0.4"/>
    <!-- rope + lantern hanging from the bowsprit -->
    <path d="M 254 74 Q 256 96 262 112" fill="none" stroke="#2a2040" stroke-width="2"/>
    <!-- portholes on the bow -->
    ${[[70, 214], [130, 196]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="9" fill="#0b1b3e" stroke="#b08a3c" stroke-width="3"/><circle cx="${x - 2}" cy="${y - 2}" r="3" fill="#6ab8ff" opacity="0.5"/>`).join("")}
    <!-- seaweed and barnacles on the hull -->
    <path d="M 150 138 q -4 20 4 34 q -8 10 -2 26" fill="none" stroke="#3fae6a" stroke-width="5" stroke-linecap="round" opacity="0.85"/>
    <path d="M 520 170 q 4 20 -4 32 q 6 12 0 22" fill="none" stroke="#3fae6a" stroke-width="5" stroke-linecap="round" opacity="0.85"/>
    ${[[40, 250], [52, 258], [180, 240], [470, 260], [486, 268], [660, 250]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="5" fill="#9a94b8" stroke="#3a3458" stroke-width="1.5"/><circle cx="${x}" cy="${y}" r="1.8" fill="#3a3458"/>`).join("")}
  </g>`;

  // Inner darkness through the tear, faint blue glow.
  const tear = `
    <path d="M 230 300 Q 238 190 228 112 Q 330 150 448 186 Q 430 250 430 300 Z" fill="#090a24"/>
    <ellipse cx="340" cy="230" rx="90" ry="60" fill="#3fa9f5" opacity="0.18" filter="url(#swBlur18)"/>
    ${[0, 1, 2].map((k) => `<path d="M ${262 + k * 56} ${140 + k * 14} L ${270 + k * 56} 300" stroke="#1c1840" stroke-width="10" opacity="0.9"/>`).join("")}`;

  // Sand floor.
  let ripplesSand = "";
  for (let k = 0; k < 14; k++) {
    const x = R() * W, y = 320 + R() * 110, w = 30 + R() * 60;
    ripplesSand += `<path d="M ${f(x)} ${f(y)} q ${f(w / 2)} -5 ${f(w)} 0" fill="none" stroke="#3a3e8a" stroke-width="2" opacity="0.5"/>`;
  }
  // Rising bubbles all over.
  let bubbles = "";
  for (let k = 0; k < 18; k++) {
    const x = 20 + R() * 680, y = 40 + R() * 300, r = 2 + R() * 5;
    if (x > 430 && x < 680 && y > 150 && y < 350) continue;
    if (x > 200 && x < 390 && y > 250 && y < 370) continue;
    bubbles += bub(x, y, r, 0.45 + R() * 0.35);
  }
  // Snore trail rising from the sleeper's mouth.
  const sx = 552, sy = 264, sr = 92;
  let snore = "";
  for (const [x, y, r] of [[482, 268, 5], [466, 236, 7], [458, 196, 10], [466, 150, 13], [486, 100, 16], [474, 52, 9], [494, 26, 5]])
    snore += bub(x, y, r, 0.9);

  // Coral clumps.
  const coral = (x, y, s, col) => {
    let d = "";
    for (const [a, l] of [[-40, 1], [-12, 1.3], [16, 1.1], [42, 0.8]]) {
      const rad = ((a - 90) * Math.PI) / 180;
      const ex = x + Math.cos(rad) * 40 * s * l, eyy = y + Math.sin(rad) * 40 * s * l;
      d += `<path d="M ${x} ${y} Q ${f((x + ex) / 2 - a * 0.2)} ${f((y + eyy) / 2)} ${f(ex)} ${f(eyy)}" fill="none" stroke="${shade(col, -0.4)}" stroke-width="${10 * s}" stroke-linecap="round"/>
        <path d="M ${x} ${y} Q ${f((x + ex) / 2 - a * 0.2)} ${f((y + eyy) / 2)} ${f(ex)} ${f(eyy)}" fill="none" stroke="${col}" stroke-width="${6 * s}" stroke-linecap="round"/>
        <circle cx="${f(ex)}" cy="${f(eyy)}" r="${4.5 * s}" fill="${shade(col, 0.4)}"/>`;
    }
    return d;
  };

  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">
  <defs>
    <linearGradient id="swWater" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#1f5fa8"/><stop offset="0.3" stop-color="#173a7e"/><stop offset="0.65" stop-color="#121a4e"/><stop offset="1" stop-color="#0D0F26"/>
    </linearGradient>
    <linearGradient id="swRay" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#d8f6ff" stop-opacity="0.9"/><stop offset="0.6" stop-color="#8fd8ff" stop-opacity="0.25"/><stop offset="1" stop-color="#8fd8ff" stop-opacity="0"/>
    </linearGradient>
    <linearGradient id="swSand" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#2a2c6a"/><stop offset="0.5" stop-color="#1c1c4c"/><stop offset="1" stop-color="#0f0f2e"/>
    </linearGradient>
    <linearGradient id="swHullNear" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#3a3070"/><stop offset="0.6" stop-color="#26204e"/><stop offset="1" stop-color="#1a1638"/>
    </linearGradient>
    <linearGradient id="swHullFar" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#2c2a62"/><stop offset="1" stop-color="#16143a"/>
    </linearGradient>
    <linearGradient id="swGold" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#fff3b0"/><stop offset="0.5" stop-color="#ffd23f"/><stop offset="1" stop-color="#d0901a"/>
    </linearGradient>
    <linearGradient id="swGoldBand" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#c98a14"/><stop offset="0.45" stop-color="#ffe27a"/><stop offset="1" stop-color="#b07810"/>
    </linearGradient>
    <linearGradient id="swChestShade" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#ffd23f" stop-opacity="0.35"/><stop offset="0.3" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.45"/>
    </linearGradient>
    <linearGradient id="swLidShade" x1="0" y1="1" x2="0" y2="0">
      <stop offset="0" stop-color="#ffd23f" stop-opacity="0.5"/><stop offset="0.5" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#8fd8ff" stop-opacity="0.25"/>
    </linearGradient>
    <linearGradient id="swBeam" x1="0" y1="1" x2="0" y2="0">
      <stop offset="0" stop-color="#fff3b0" stop-opacity="0.9"/><stop offset="1" stop-color="#ffd23f" stop-opacity="0"/>
    </linearGradient>
    <linearGradient id="swRimGold" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#ffd23f" stop-opacity="0.55"/><stop offset="0.3" stop-color="#ffd23f" stop-opacity="0"/>
    </linearGradient>
    <linearGradient id="swRimTop" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#d8f6ff" stop-opacity="0.35"/><stop offset="0.25" stop-color="#d8f6ff" stop-opacity="0"/>
    </linearGradient>
    <radialGradient id="swBub" cx="0.5" cy="0.5" r="0.5">
      <stop offset="0" stop-color="#9fdcff" stop-opacity="0.05"/><stop offset="0.75" stop-color="#7fc8ff" stop-opacity="0.18"/><stop offset="1" stop-color="#d6f2ff" stop-opacity="0.6"/>
    </radialGradient>
    <radialGradient id="swPearl" cx="0.35" cy="0.3" r="0.8">
      <stop offset="0" stop-color="#ffffff"/><stop offset="0.7" stop-color="#efe3f6"/><stop offset="1" stop-color="#bba6cc"/>
    </radialGradient>
    <radialGradient id="swVig" cx="50%" cy="48%" r="72%">
      <stop offset="0.6" stop-color="#05061a" stop-opacity="0"/><stop offset="1" stop-color="#05061a" stop-opacity="0.65"/>
    </radialGradient>
    <filter id="swBlur3" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="3"/></filter>
    <filter id="swBlur6" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="6"/></filter>
    <filter id="swBlur18" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="18"/></filter>
    <filter id="swBlur40" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="40"/></filter>
  </defs>

  <!-- deep water -->
  <rect width="${W}" height="${H}" fill="url(#swWater)"/>
  <ellipse cx="360" cy="0" rx="380" ry="90" fill="#8fd8ff" opacity="0.35" filter="url(#swBlur40)"/>
  ${ripples}
  <g filter="url(#swBlur6)">${rays}</g>
  ${fish}

  <!-- far rocks -->
  <path d="M 0 250 Q 60 210 120 228 Q 180 200 250 230 L 250 300 L 0 300 Z" fill="#141a50" opacity="0.8"/>
  <path d="M 470 240 Q 540 200 610 222 Q 670 196 720 214 L 720 300 L 470 300 Z" fill="#141a50" opacity="0.8"/>
  ${kelp(30, 300, 170, "#245a6a", 18, R, 4, 7)}${kelp(690, 300, 190, "#245a6a", -16, R, 4, 7)}

  ${tear}
  ${hull}

  <!-- sand -->
  <path d="M 0 300 Q 180 284 360 296 Q 540 284 720 298 L 720 440 L 0 440 Z" fill="url(#swSand)"/>
  <path d="M 0 300 Q 180 284 360 296 Q 540 284 720 298" fill="none" stroke="#5a6ad0" stroke-width="2" opacity="0.5"/>
  ${ripplesSand}
  <!-- light pool on the sand from the rays -->
  <ellipse cx="370" cy="330" rx="200" ry="34" fill="#8fd8ff" opacity="0.18" filter="url(#swBlur18)"/>
  <ellipse cx="320" cy="340" rx="150" ry="30" fill="#ffd23f" opacity="0.28" filter="url(#swBlur18)"/>

  <!-- the big sleeper -->
  <ellipse cx="${sx + 6}" cy="${sy + sr * 0.86}" rx="${sr * 1.25}" ry="${sr * 0.2}" fill="#000" opacity="0.45" filter="url(#swBlur6)"/>
  <!-- living layers (render.mjs): the sleeper breathes, the kelp sways -->
  <g data-layer="sleeper" data-move="breathe 0.025 0.4 0" data-pivot="${sx} ${sy + sr * 0.86}">${sleeper(sx, sy, sr)}</g>
  <g data-layer="snore" data-move="bob 5 0.8 0.3" data-follow="sleeper">${snore}</g>

  <!-- the chest -->
  <ellipse cx="292" cy="352" rx="84" ry="12" fill="#000" opacity="0.5" filter="url(#swBlur6)"/>
  ${chest(290, 318)}
  ${coin(206, 360, 9, 0.45, 10)}${coin(222, 368, 7, 0.45, -20)}${coin(372, 362, 8, 0.45, 15)}

  ${bubbles}
  ${snow}

  <!-- foreground framing -->
  <path d="M -10 440 L -10 360 Q 30 340 80 352 Q 130 366 150 410 L 156 440 Z" fill="#0c0b26" stroke="#2a2c6a" stroke-width="2"/>
  <path d="M 730 440 L 730 350 Q 690 334 640 350 Q 600 368 588 410 L 584 440 Z" fill="#0c0b26" stroke="#2a2c6a" stroke-width="2"/>
  ${coral(96, 372, 0.9, "#ff7ac8")}${coral(630, 366, 0.8, "#ff8a5c")}
  <g data-layer="kelpl" data-move="sway 3 0.5 0" data-pivot="40 440">${kelp(26, 440, 250, "#3fae6a", 22, R, 6, 10)}${kelp(58, 440, 180, "#5fd068", -16, R, 4, 8)}</g>
  <g data-layer="kelpr" data-move="sway 3 0.45 0.4" data-pivot="680 440">${kelp(694, 440, 270, "#3fae6a", -22, R, 6, 10)}${kelp(664, 440, 170, "#5fd068", 14, R, 4, 8)}</g>
  <rect width="${W}" height="${H}" fill="url(#swVig)"/>
</svg>`;
}

// Candy Fountain: a Sweet-family fountain of bubbling pink fizz on a candy
// tile floor, gumdrops and sprinkles about, a small Sweet critter peeking
// over the basin rim.
import { ball, eye, shade } from "../../brand/parts.mjs";

const SWEET = "#FF8AD0";

function seeded(seed) {
  let s = seed;
  return () => ((s = (s * 16807) % 2147483647) / 2147483647);
}

export default function candyFountain() {
  const R = seeded(23);
  const W = 720, H = 440;
  const cx = 360;
  const HZ = 238; // horizon of the floor

  // Perspective checker floor.
  let floor = "";
  const rows = 9, cols = 18;
  const yAt = (t) => HZ + (H + 40 - HZ) * t * t;
  for (let j = 0; j < rows; j++) {
    const t0 = j / rows, t1 = (j + 1) / rows;
    const y0 = yAt(t0), y1 = yAt(t1);
    const s0 = 0.25 + 1.6 * t0 * t0, s1 = 0.25 + 1.6 * t1 * t1;
    for (let i = -cols / 2; i < cols / 2; i++) {
      const w = 70;
      const pts = [[cx + i * w * s0, y0], [cx + (i + 1) * w * s0, y0], [cx + (i + 1) * w * s1, y1], [cx + i * w * s1, y1]];
      const c = (i + j) % 2 ? "#2c1a4a" : "#3e2260";
      floor += `<polygon points="${pts.map((p) => p.join(",")).join(" ")}" fill="${c}"/>`;
    }
  }

  // Back silhouettes: lollipop trees and candy canes on the horizon.
  const lolli = (x, y, r, col, stick) => `<rect x="${x - 3}" y="${y}" width="6" height="${HZ - y + 6}" fill="${stick}"/>
    <circle cx="${x}" cy="${y}" r="${r}" fill="${col}"/>
    <path d="M ${x} ${y} m ${-r * 0.6} 0 a ${r * 0.6} ${r * 0.6} 0 1 1 ${r * 1.2} 0 a ${r * 0.4} ${r * 0.4} 0 1 1 ${-r * 0.8} 0 a ${r * 0.2} ${r * 0.2} 0 1 1 ${r * 0.4} 0" fill="none" stroke="${shade(col, 0.18)}" stroke-width="${r * 0.14}" opacity="0.8"/>`;
  const cane = (x, y, h, flip) => {
    const d = `M ${x} ${HZ + 4} L ${x} ${y} A 16 16 0 0 ${flip ? 0 : 1} ${x + (flip ? -32 : 32)} ${y}`;
    return `<path d="${d}" fill="none" stroke="#3b2550" stroke-width="12" stroke-linecap="round"/>
      <path d="${d}" fill="none" stroke="#6b3d78" stroke-width="12" stroke-linecap="round" stroke-dasharray="9 9"/>`;
  };
  const back = `${lolli(80, 150, 46, "#3b2763", "#2b1d48")}${lolli(170, 182, 30, "#46286d", "#2b1d48")}${lolli(640, 140, 52, "#3b2763", "#2b1d48")}${lolli(560, 185, 28, "#46286d", "#2b1d48")}
    ${cane(250, 196, 40, false)}${cane(480, 190, 46, true)}`;

  // Stars.
  let stars = "";
  for (let k = 0; k < 34; k++) stars += `<circle cx="${R() * W}" cy="${R() * 150}" r="${0.6 + R() * 1.2}" fill="#ffe6f6" opacity="${0.25 + R() * 0.55}"/>`;

  // Fizz bubbles in the rising column and spray.
  let fizz = "";
  for (let k = 0; k < 32; k++) {
    const t = R();
    const y = 60 + t * 150;
    const spread = 10 + (1 - t) * 42;
    const x = cx + (R() - 0.5) * spread * 2;
    const r = 2.5 + R() * (4 + (1 - t) * 5);
    fizz += `<circle cx="${x}" cy="${y}" r="${r}" fill="#ffd6ef" fill-opacity="0.35" stroke="#fff" stroke-opacity="0.85" stroke-width="1.6"/><circle cx="${x - r * 0.35}" cy="${y - r * 0.35}" r="${r * 0.28}" fill="#fff" opacity="0.9"/>`;
  }
  // Spray droplets arcing out from the top.
  let spray = "";
  for (let k = 0; k < 14; k++) {
    const side = k % 2 ? 1 : -1;
    const a = 0.2 + R() * 0.9;
    const d = 40 + R() * 70;
    const x = cx + side * Math.sin(a) * d * 1.3, y = 78 + (1 - Math.cos(a)) * d * 1.1 - 10;
    spray += `<circle cx="${x}" cy="${y}" r="${2.5 + R() * 3.5}" fill="#ffc2e6"/>`;
  }
  // Bubbles in the basin.
  let basinBubbles = "";
  for (let k = 0; k < 22; k++) {
    const a = R() * Math.PI * 2, rr = Math.sqrt(R());
    const x = cx + Math.cos(a) * 150 * rr, y = 300 + Math.sin(a) * 22 * rr;
    const r = 2.5 + R() * 6;
    basinBubbles += `<circle cx="${x}" cy="${y}" r="${r}" fill="#ffd6ef" fill-opacity="0.3" stroke="#fff" stroke-opacity="0.8" stroke-width="1.3"/>`;
  }

  // Scalloped icing edge along an ellipse arc (front half).
  const scallop = (ex, ey, rx, ry, n, depth, col) => {
    let d = `M ${ex - rx} ${ey}`;
    for (let k = 0; k < n; k++) {
      const a0 = Math.PI - (k / n) * Math.PI, a1 = Math.PI - ((k + 1) / n) * Math.PI;
      const am = (a0 + a1) / 2;
      const x1 = ex + Math.cos(a1) * rx, y1 = ey + Math.sin(a1) * ry;
      const xm = ex + Math.cos(am) * rx, ym = ey + Math.sin(am) * ry + depth * (k % 3 === 1 ? 1.8 : 1);
      d += ` Q ${xm} ${ym + depth} ${x1} ${y1}`;
    }
    return `<path d="${d} L ${ex + rx} ${ey - 4} L ${ex - rx} ${ey - 4} Z" fill="${col}"/>`;
  };
  // Note: the arc above goes left-to-right through the lower half.

  // Gumdrops: domed sugary sweets with a glow.
  const gum = (x, y, s, col) => `<ellipse cx="${x}" cy="${y + 2}" rx="${s * 1.2}" ry="${s * 0.3}" fill="#12081f" opacity="0.6"/>
    <ellipse cx="${x}" cy="${y - s * 0.4}" rx="${s * 1.4}" ry="${s * 1.1}" fill="${col}" opacity="0.35" filter="url(#cf_g8)"/>
    <path d="M ${x - s} ${y} Q ${x - s} ${y - s * 1.4} ${x} ${y - s * 1.4} Q ${x + s} ${y - s * 1.4} ${x + s} ${y} Q ${x} ${y + s * 0.25} ${x - s} ${y} Z" fill="${col}" stroke="${shade(col, -0.4)}" stroke-width="2"/>
    <ellipse cx="${x - s * 0.35}" cy="${y - s * 0.95}" rx="${s * 0.25}" ry="${s * 0.14}" fill="#fff" opacity="0.6" transform="rotate(-30 ${x - s * 0.35} ${y - s * 0.95})"/>
    ${[0, 1, 2, 3, 4].map((k) => `<circle cx="${x + (R() - 0.5) * s * 1.4}" cy="${y - s * (0.2 + R() * 0.9)}" r="${s * 0.06}" fill="#fff" opacity="0.7"/>`).join("")}`;

  // Sprinkles scattered on the floor.
  let sprinkles = "";
  const sc = ["#FF8AD0", "#FFD34E", "#3EE6FF", "#5CFF9A", "#C9A6FF", "#ffffff"];
  for (let k = 0; k < 70; k++) {
    const y = 270 + R() * 160;
    const x = 30 + R() * 660;
    if (Math.abs(x - cx) < 200 && y < 360) continue;
    const s = 0.5 + (y - 260) / 180;
    const a = R() * 180;
    sprinkles += `<rect x="${x - 5 * s}" y="${y - 1.6 * s}" width="${10 * s}" height="${3.2 * s}" rx="${1.6 * s}" fill="${sc[k % sc.length]}" transform="rotate(${a} ${x} ${y})"/>`;
  }

  // Sweet critter peeking over the right of the basin rim.
  const kx = 522, ky = 294, kr = 34;
  const critter = `${ball(kx, ky, kr, "#ff6fbf", { glow: true })}
    ${eye(kx - 12, ky - 8, 9.5, 12, -0.55, -0.65, 5)}${eye(kx + 12, ky - 8, 9.5, 12, -0.55, -0.65, 5)}
    <ellipse cx="${kx - 23}" cy="${ky + 6}" rx="6" ry="3.5" fill="#ff3d8f" opacity="0.6"/><ellipse cx="${kx + 23}" cy="${ky + 6}" rx="6" ry="3.5" fill="#ff3d8f" opacity="0.6"/>
    <path d="M ${kx - 6} ${ky - kr + 2} q 6 -16 14 -6" fill="none" stroke="#ffd6ef" stroke-width="5" stroke-linecap="round"/>`;

  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">
  <defs>
    <linearGradient id="cf_sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0D0F26"/><stop offset="0.6" stop-color="#1c1240"/><stop offset="1" stop-color="#3a1d5a"/></linearGradient>
    <radialGradient id="cf_halo" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="${SWEET}" stop-opacity="0.55"/><stop offset="0.5" stop-color="${SWEET}" stop-opacity="0.15"/><stop offset="1" stop-color="${SWEET}" stop-opacity="0"/></radialGradient>
    <linearGradient id="cf_fizz" x1="0" y1="1" x2="0" y2="0"><stop offset="0" stop-color="#ff5fb4"/><stop offset="0.7" stop-color="#ff9ad6"/><stop offset="1" stop-color="#ffe0f2" stop-opacity="0.9"/></linearGradient>
    <linearGradient id="cf_stone" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8a5aa0"/><stop offset="0.35" stop-color="#f3e3ff"/><stop offset="0.6" stop-color="#c9a6e8"/><stop offset="1" stop-color="#4e2f6e"/></linearGradient>
    <linearGradient id="cf_basin" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#5b2d78"/><stop offset="0.3" stop-color="#b98ad8"/><stop offset="0.55" stop-color="#9566c0"/><stop offset="1" stop-color="#3a2058"/></linearGradient>
    <radialGradient id="cf_pool" cx="0.5" cy="0.4" r="0.6"><stop offset="0" stop-color="#ffc2e6"/><stop offset="0.6" stop-color="#ff6fbf"/><stop offset="1" stop-color="#c2338a"/></radialGradient>
    <radialGradient id="cf_floorglow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="${SWEET}" stop-opacity="0.5"/><stop offset="1" stop-color="${SWEET}" stop-opacity="0"/></radialGradient>
    <linearGradient id="cf_fade" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#1c1240" stop-opacity="1"/><stop offset="0.25" stop-color="#1c1240" stop-opacity="0"/></linearGradient>
    <filter id="cf_g8" x="-100%" y="-100%" width="300%" height="300%"><feGaussianBlur stdDeviation="8"/></filter>
    <filter id="cf_g20" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="20"/></filter>
    <clipPath id="cf_stripes"><path d="M ${cx - 26} 300 L ${cx - 18} 205 L ${cx + 18} 205 L ${cx + 26} 300 Z"/></clipPath>
    <clipPath id="cf_basinclip"><path d="M ${cx - 175} 300 L ${cx - 160} 352 Q ${cx} 380 ${cx + 160} 352 L ${cx + 175} 300 Z"/></clipPath>
    <radialGradient id="cf_vig" cx="0.5" cy="0.45" r="0.75"><stop offset="0.6" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#05061a" stop-opacity="0.7"/></radialGradient>
  </defs>
  <rect width="${W}" height="${H}" fill="url(#cf_sky)"/>
  ${stars}
  <ellipse cx="${cx}" cy="160" rx="300" ry="200" fill="url(#cf_halo)"/>
  ${back}
  ${floor}
  <rect x="0" y="${HZ}" width="${W}" height="${H - HZ}" fill="url(#cf_fade)"/>
  <ellipse cx="${cx}" cy="340" rx="300" ry="80" fill="url(#cf_floorglow)"/>

  <!-- basin shadow and back rim -->
  <ellipse cx="${cx}" cy="362" rx="200" ry="26" fill="#0b0518" opacity="0.65" filter="url(#cf_g8)"/>
  <ellipse cx="${cx}" cy="300" rx="175" ry="34" fill="#e8d2fa"/>
  <ellipse cx="${cx}" cy="302" rx="160" ry="26" fill="url(#cf_pool)"/>
  ${basinBubbles}
  <!-- pedestal with candy stripes -->
  <path d="M ${cx - 26} 300 L ${cx - 18} 205 L ${cx + 18} 205 L ${cx + 26} 300 Z" fill="#f6e8ff"/>
  <g clip-path="url(#cf_stripes)">${Array.from({ length: 9 }, (_, k) => `<path d="M ${cx - 60} ${200 + k * 14} l 120 -34 l 0 8 l -120 34 Z" fill="#ff5fb4"/>`).join("")}
    <rect x="${cx - 30}" y="200" width="22" height="110" fill="#000" opacity="0.18"/><rect x="${cx + 8}" y="200" width="22" height="110" fill="#000" opacity="0.32"/></g>
  <!-- splash ring where the fizz lands -->
  <ellipse cx="${cx}" cy="300" rx="60" ry="10" fill="#fff" opacity="0.5" filter="url(#cf_g8)"/>

  <!-- upper bowl -->
  <ellipse cx="${cx}" cy="206" rx="92" ry="20" fill="#e8d2fa"/>
  <ellipse cx="${cx}" cy="207" rx="80" ry="14" fill="url(#cf_pool)"/>
  <path d="M ${cx - 92} 206 Q ${cx - 70} 250 ${cx} 252 Q ${cx + 70} 250 ${cx + 92} 206 Q ${cx} 232 ${cx - 92} 206 Z" fill="url(#cf_basin)"/>
  ${scallop(cx, 212, 92, 18, 9, 7, "#ff8ad0")}
  <!-- drips spilling from the bowl -->
  ${[-70, -38, 30, 64].map((dx, k) => `<path d="M ${cx + dx - 6} 222 Q ${cx + dx - 6} ${250 + k * 6} ${cx + dx} ${258 + k * 8} Q ${cx + dx + 6} ${250 + k * 6} ${cx + dx + 6} 222 Z" fill="#ff8ad0"/><circle cx="${cx + dx}" cy="${276 + k * 6}" r="3.5" fill="#ffb3e0"/>`).join("")}

  <!-- living layers (render.mjs): the fizz column breathes, the critter bobs behind the rim -->
  <g data-layer="fizz" data-move="breathe 0.04 0.9 0" data-pivot="${cx} 208">
  <!-- the fizz column -->
  <ellipse cx="${cx}" cy="140" rx="80" ry="110" fill="${SWEET}" opacity="0.35" filter="url(#cf_g20)"/>
  <path d="M ${cx - 20} 208 Q ${cx - 30} 150 ${cx - 14} 95 Q ${cx - 30} 70 ${cx} 58 Q ${cx + 30} 70 ${cx + 14} 95 Q ${cx + 30} 150 ${cx + 20} 208 Z" fill="url(#cf_fizz)"/>
  <path d="M ${cx - 6} 205 Q ${cx - 12} 140 ${cx - 4} 80" fill="none" stroke="#fff" stroke-width="5" stroke-linecap="round" opacity="0.6"/>
  <!-- foam crown -->
  ${[[-26, 70, 16], [26, 72, 15], [0, 54, 20], [-14, 44, 12], [15, 46, 12], [-40, 86, 10], [40, 88, 10]].map(([dx, y, r]) => `<circle cx="${cx + dx}" cy="${y}" r="${r}" fill="#ffe6f5"/><circle cx="${cx + dx - r * 0.3}" cy="${y - r * 0.3}" r="${r * 0.35}" fill="#fff"/>`).join("")}
  ${fizz}
  ${spray}
  </g>

  <!-- critter behind the basin front -->
  <g data-layer="critter" data-move="bob 5 0.7 0.3">${critter}</g>
  <!-- basin front wall -->
  <g data-layer="basin">
  <path d="M ${cx - 175} 300 Q ${cx - 172} 345 ${cx - 150} 356 Q ${cx} 386 ${cx + 150} 356 Q ${cx + 172} 345 ${cx + 175} 300 Q ${cx} 352 ${cx - 175} 300 Z" fill="url(#cf_basin)"/>
  ${scallop(cx, 306, 175, 32, 14, 9, "#ff8ad0")}
  ${[[-120, 336], [-60, 352], [0, 357], [60, 352], [120, 336]].map(([dx, y]) => `<circle cx="${cx + dx}" cy="${y}" r="7" fill="#fff4b0"/><circle cx="${cx + dx}" cy="${y}" r="12" fill="#fff4b0" opacity="0.4" filter="url(#cf_g8)"/>`).join("")}
  </g>
  <!-- critter paws over the rim -->
  <g data-layer="paws" data-follow="critter"><ellipse cx="${kx - 18}" cy="${ky + 24}" rx="11" ry="7" fill="#ff8fcf" stroke="#a8306f" stroke-width="2"/><ellipse cx="${kx + 18}" cy="${ky + 25}" rx="11" ry="7" fill="#ff8fcf" stroke="#a8306f" stroke-width="2"/></g>

  ${sprinkles}
  ${gum(120, 380, 30, "#5CFF9A")}${gum(178, 404, 22, "#FFD34E")}${gum(610, 392, 32, "#3EA8FF")}${gum(560, 412, 20, "#FF8AD0")}${gum(78, 300, 16, "#C9A6FF")}${gum(655, 308, 18, "#FF7A45")}
  <rect width="${W}" height="${H}" fill="url(#cf_vig)"/>
</svg>`;
}

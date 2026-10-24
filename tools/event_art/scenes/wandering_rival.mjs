// A masked rival critter blocks the neon path: luchador mask, fluttering scarf,
// a smug smirk, standing in a glowing duel circle. Glitch-tinted accents.
import { ball, eye, brow, shade, INK } from "../../brand/parts.mjs";

const GL = "#FF5A6E";
const CY = "#3EE6FF";
const MG = "#FF3EDC";

function rng(seed) {
  let s = seed;
  return () => ((s = (s * 16807) % 2147483647) / 2147483647);
}

export default function () {
  const R = rng(5);
  const vx = 360, vy = 206; // vanishing point
  const cx = 360, cy = 252, r = 96; // the rival

  // Synthwave ground grid.
  let grid = "";
  for (let k = -12; k <= 12; k++) {
    grid += `<line x1="${vx + k * 12}" y1="${vy}" x2="${vx + k * 150}" y2="440" stroke="#8f7bff" stroke-width="1.2" opacity="0.28"/>`;
  }
  for (let k = 1; k < 12; k++) {
    const y = vy + Math.pow(k / 11, 2.2) * (440 - vy);
    grid += `<line x1="0" y1="${y}" x2="720" y2="${y}" stroke="#8f7bff" stroke-width="1.2" opacity="${0.12 + k * 0.02}"/>`;
  }
  // City skyline silhouette with lit windows.
  let city = "", wins = "";
  let x = -10;
  while (x < 730) {
    const w = 26 + R() * 46, h = 30 + R() * 70;
    const far = Math.abs(x + w / 2 - vx) < 120 ? 0.6 : 1; // lower near the centre so the rival reads
    city += `<rect x="${x}" y="${vy - h * far}" width="${w}" height="${h * far + 2}" fill="#1a1446"/>`;
    for (let k = 0; k < 4; k++) {
      if (R() < 0.5) wins += `<rect x="${x + 4 + R() * (w - 10)}" y="${vy - h * far + 6 + R() * (h * far - 14)}" width="3" height="4" fill="${[CY, MG, "#FFD34E"][k % 3]}" opacity="0.7"/>`;
    }
    x += w + 2;
  }
  // Glitch pixels around the rival.
  let px = "";
  for (let k = 0; k < 26; k++) {
    const a = R() * Math.PI * 2, d = r * (1.15 + R() * 0.8);
    const s = 3 + R() * 8;
    px += `<rect x="${cx + Math.cos(a) * d * 1.3}" y="${cy + Math.sin(a) * d * 0.9 - 10}" width="${s}" height="${s}" fill="${[GL, CY, MG][k % 3]}" opacity="${0.35 + R() * 0.5}"/>`;
  }
  // Path-side neon posts.
  const posts = [0.35, 0.6, 0.9].map((t) => {
    const y = vy + t * (440 - vy);
    const off = 30 + t * 270;
    const h = 10 + t * 50, w = 2 + t * 6;
    return [-1, 1].map((d) => {
      const px0 = vx + d * off;
      const col = d < 0 ? CY : MG;
      return `<rect x="${px0 - w / 2}" y="${y - h}" width="${w}" height="${h}" rx="${w / 2}" fill="${col}" opacity="0.5" filter="url(#wrGlowS)"/>
        <rect x="${px0 - w / 2}" y="${y - h}" width="${w}" height="${h}" rx="${w / 2}" fill="${shade(col, 0.6)}"/>`;
    }).join("");
  }).join("");

  // --- The rival ---------------------------------------------------------
  const body = "#5b4bd6";
  const ey = cy - r * 0.2;
  const maskBottom = cy + r * 0.12;
  const mask = `
    <g clip-path="url(#wrBall)">
      <path d="M ${cx - r - 4} ${cy - r - 4} L ${cx + r + 4} ${cy - r - 4} L ${cx + r + 4} ${maskBottom - 8} Q ${cx + r * 0.5} ${maskBottom - 2} ${cx + r * 0.12} ${maskBottom + 6} L ${cx} ${maskBottom + 18} L ${cx - r * 0.12} ${maskBottom + 6} Q ${cx - r * 0.5} ${maskBottom - 2} ${cx - r - 4} ${maskBottom - 8} Z" fill="url(#wrMask)"/>
      <!-- central crest stripe -->
      <path d="M ${cx - 16} ${cy - r - 4} L ${cx + 16} ${cy - r - 4} L ${cx + 9} ${ey - r * 0.36} L ${cx} ${ey - r * 0.22} L ${cx - 9} ${ey - r * 0.36} Z" fill="${CY}"/>
      <path d="M ${cx - 7} ${cy - r - 4} L ${cx + 7} ${cy - r - 4} L ${cx + 3} ${ey - r * 0.44} L ${cx - 3} ${ey - r * 0.44} Z" fill="#fff" opacity="0.8"/>
      <!-- trim along the lower edge -->
      <path d="M ${cx - r - 4} ${maskBottom - 8} Q ${cx - r * 0.5} ${maskBottom - 2} ${cx - r * 0.12} ${maskBottom + 6} L ${cx} ${maskBottom + 18} L ${cx + r * 0.12} ${maskBottom + 6} Q ${cx + r * 0.5} ${maskBottom - 2} ${cx + r + 4} ${maskBottom - 8}" fill="none" stroke="${CY}" stroke-width="4"/>
      <!-- matte sheen -->
      <ellipse cx="${cx - r * 0.42}" cy="${cy - r * 0.62}" rx="${r * 0.3}" ry="${r * 0.12}" fill="#fff" opacity="0.28" transform="rotate(-35 ${cx - r * 0.42} ${cy - r * 0.62})"/>
    </g>
    <!-- eye holes with flame-shaped trim -->
    ${[-1, 1].map((d) => {
      const ex = cx + d * r * 0.36;
      return `<path d="M ${ex - d * r * 0.3} ${ey + r * 0.04} Q ${ex - d * r * 0.26} ${ey - r * 0.36} ${ex + d * r * 0.06} ${ey - r * 0.34} Q ${ex + d * r * 0.34} ${ey - r * 0.28} ${ex + d * r * 0.28} ${ey + r * 0.06} Q ${ex} ${ey + r * 0.34} ${ex - d * r * 0.3} ${ey + r * 0.04} Z" fill="#fff" stroke="${INK}" stroke-width="5"/>
        <path d="M ${ex - d * r * 0.3} ${ey + r * 0.04} Q ${ex - d * r * 0.26} ${ey - r * 0.36} ${ex + d * r * 0.06} ${ey - r * 0.34} Q ${ex + d * r * 0.34} ${ey - r * 0.28} ${ex + d * r * 0.28} ${ey + r * 0.06}" fill="none" stroke="${CY}" stroke-width="3" transform="translate(${d * 2} -4)"/>`;
    }).join("")}
    ${eye(cx - r * 0.34, ey - r * 0.02, r * 0.17, r * 0.2, 0.15, 0.35, r * 0.1)}
    ${eye(cx + r * 0.36, ey - r * 0.02, r * 0.17, r * 0.2, 0.15, 0.35, r * 0.1)}
    <!-- heavy lids: cool, unimpressed -->
    <path d="M ${cx - r * 0.53} ${ey - r * 0.02} Q ${cx - r * 0.34} ${ey - r * 0.32} ${cx - r * 0.15} ${ey - r * 0.06} Q ${cx - r * 0.34} ${ey - r * 0.1} ${cx - r * 0.53} ${ey - r * 0.02} Z" fill="${shade(body, -0.2)}" stroke="${INK}" stroke-width="4" stroke-linejoin="round"/>
    <path d="M ${cx + r * 0.17} ${ey - r * 0.08} Q ${cx + r * 0.36} ${ey - r * 0.3} ${cx + r * 0.55} ${ey - r * 0.04} Q ${cx + r * 0.36} ${ey - r * 0.16} ${cx + r * 0.17} ${ey - r * 0.08} Z" fill="${shade(body, -0.2)}" stroke="${INK}" stroke-width="4" stroke-linejoin="round"/>
    <!-- confident brows: one low, one cocked up -->
    ${brow(cx - r * 0.6, ey - r * 0.36, cx - r * 0.14, ey - r * 0.22, r * 0.09)}
    ${brow(cx + r * 0.14, ey - r * 0.38, cx + r * 0.6, ey - r * 0.46, r * 0.09)}`;

  const mouth = `
    <path d="M ${cx - r * 0.3} ${cy + r * 0.36} Q ${cx} ${cy + r * 0.5} ${cx + r * 0.34} ${cy + r * 0.24}" fill="none" stroke="${INK}" stroke-width="${r * 0.08}" stroke-linecap="round"/>
    <path d="M ${cx + r * 0.1} ${cy + r * 0.41} l ${r * 0.1} ${-r * 0.06} l ${r * 0.01} ${r * 0.09} Z" fill="#fff"/>
    <path d="M ${cx + r * 0.4} ${cy + r * 0.2} l ${r * 0.08} ${-r * 0.04}" stroke="${INK}" stroke-width="${r * 0.05}" stroke-linecap="round"/>
    <!-- tooth glint -->
    <path d="M ${cx + r * 0.24} ${cy + r * 0.34} l 2 -7 l 2 7 l 7 2 l -7 2 l -2 7 l -2 -7 l -7 -2 Z" fill="#fff"/>`;

  // Scarf around the lower body, tails streaming to the left in the wind.
  const sy = cy + r * 0.64;
  const scarf = `
    <path d="M ${cx - r * 0.7} ${sy - 4} Q ${cx - r * 1.3} ${sy - 30} ${cx - r * 1.9} ${sy - 18} L ${cx - r * 1.82} ${sy + 8} Q ${cx - r * 1.3} ${sy - 4} ${cx - r * 0.66} ${sy + 22} Z" fill="url(#wrScarf)"/>
    <path d="M ${cx - r * 0.6} ${sy + 6} Q ${cx - r * 1.1} ${sy + 20} ${cx - r * 1.6} ${sy + 42} L ${cx - r * 1.48} ${sy + 62} Q ${cx - r * 1.0} ${sy + 38} ${cx - r * 0.5} ${sy + 30} Z" fill="url(#wrScarf)"/>
    ${[0, 1, 2].map((k) => `<rect x="${cx - r * 1.98 - k * 12}" y="${sy - 18 + k * 7}" width="${8 - k * 2}" height="${8 - k * 2}" fill="${[CY, MG, GL][k]}"/>`).join("")}
    ${[0, 1].map((k) => `<rect x="${cx - r * 1.6 - k * 12}" y="${sy + 56 + k * 6}" width="${7 - k * 2}" height="${7 - k * 2}" fill="${[MG, CY][k]}"/>`).join("")}
    <g clip-path="url(#wrBall)">
      <path d="M ${cx - r - 4} ${sy - 10} Q ${cx} ${sy + 18} ${cx + r + 4} ${sy - 18} L ${cx + r + 4} ${sy + 18} Q ${cx} ${sy + 52} ${cx - r - 4} ${sy + 26} Z" fill="url(#wrScarf)"/>
      <path d="M ${cx - r - 4} ${sy + 6} Q ${cx} ${sy + 34} ${cx + r + 4} ${sy}" fill="none" stroke="#0b6b7a" stroke-width="3" opacity="0.6"/>
      ${[-0.6, -0.2, 0.2, 0.6].map((t) => `<rect x="${cx + t * r - 5}" y="${sy + 8 - t * t * 10 + (t > 0 ? -t * 10 : 0)}" width="10" height="5" fill="${GL}" opacity="0.85"/>`).join("")}
    </g>
    <!-- knot -->
    <ellipse cx="${cx - r * 0.66}" cy="${sy + 10}" rx="14" ry="12" fill="${shade(CY, -0.25)}" stroke="#0b4b5a" stroke-width="2"/>`;

  const rival = `
    <g transform="rotate(-5 ${cx} ${cy + r})">
      ${scarf.split("<g clip-path")[0]}
      <path d="M ${cx + r * 0.8} ${cy - r * 0.5} Q ${cx + r * 1.3} ${cy - r * 0.9} ${cx + r * 1.7} ${cy - r * 0.7} L ${cx + r * 1.62} ${cy - r * 0.56} Q ${cx + r * 1.3} ${cy - r * 0.66} ${cx + r * 0.9} ${cy - r * 0.3} Z" fill="url(#wrMask)" stroke="#8a1e30" stroke-width="2"/>
      <path d="M ${cx + r * 0.86} ${cy - r * 0.4} Q ${cx + r * 1.3} ${cy - r * 0.36} ${cx + r * 1.56} ${cy - r * 0.16} L ${cx + r * 1.44} ${cy - r * 0.06} Q ${cx + r * 1.2} ${cy - r * 0.22} ${cx + r * 0.9} ${cy - r * 0.22} Z" fill="url(#wrMask)" stroke="#8a1e30" stroke-width="2"/>
      <!-- RGB split rim behind the body -->
      <circle cx="${cx - 5}" cy="${cy}" r="${r}" fill="${CY}" opacity="0.55"/>
      <circle cx="${cx + 5}" cy="${cy + 1}" r="${r}" fill="${MG}" opacity="0.55"/>
      ${ball(cx, cy, r, body, { glow: false })}
      <!-- rim light from the red arena glow -->
      <path d="M ${cx + r * 0.6} ${cy + r * 0.78} A ${r} ${r} 0 0 0 ${cx + r * 0.96} ${cy - r * 0.2}" fill="none" stroke="#ff9aa8" stroke-width="4" stroke-linecap="round" opacity="0.8"/>
      ${mask}
      ${mouth}
      ${"<g clip-path" + scarf.split("<g clip-path")[1]}
    </g>`;

  return `<svg xmlns="http://www.w3.org/2000/svg" width="720" height="440" viewBox="0 0 720 440">
  <defs>
    <linearGradient id="wrSky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#0D0F26"/><stop offset="0.6" stop-color="#2c2170"/><stop offset="1" stop-color="#6a2a8a"/>
    </linearGradient>
    <radialGradient id="wrSun" cx="50%" cy="50%" r="50%">
      <stop offset="0" stop-color="${MG}" stop-opacity="0.75"/><stop offset="0.5" stop-color="${GL}" stop-opacity="0.25"/><stop offset="1" stop-color="${GL}" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="wrGround" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#1e1650"/><stop offset="1" stop-color="#0D0F26"/>
    </linearGradient>
    <linearGradient id="wrRoad" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#3a2a8a"/><stop offset="1" stop-color="#160f40"/>
    </linearGradient>
    <linearGradient id="wrMask" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#ff8a98"/><stop offset="0.6" stop-color="${GL}"/><stop offset="1" stop-color="#c8304a"/>
    </linearGradient>
    <linearGradient id="wrScarf" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#9ff6ff"/><stop offset="0.5" stop-color="${CY}"/><stop offset="1" stop-color="#1a9ab2"/>
    </linearGradient>
    <radialGradient id="wrVig" cx="50%" cy="52%" r="72%">
      <stop offset="0.6" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.6"/>
    </radialGradient>
    <filter id="wrGlowS" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="3"/></filter>
    <filter id="wrGlowL" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="16"/></filter>
    <clipPath id="wrBall"><circle cx="${cx}" cy="${cy}" r="${r}"/></clipPath>
  </defs>

  <rect width="720" height="440" fill="url(#wrSky)"/>
  <!-- stars -->
  ${Array.from({ length: 40 }, () => `<circle cx="${(R() * 720).toFixed(0)}" cy="${(R() * 150).toFixed(0)}" r="${(0.6 + R() * 1.3).toFixed(1)}" fill="#e8e4ff" opacity="${(0.3 + R() * 0.6).toFixed(2)}"/>`).join("")}
  <!-- glitchy neon sun behind -->
  <ellipse cx="${vx}" cy="${vy - 20}" rx="260" ry="150" fill="url(#wrSun)"/>
  <!-- skyline -->
  ${city}${wins}
  <rect x="0" y="${vy - 2}" width="720" height="3" fill="${MG}" opacity="0.8" filter="url(#wrGlowS)"/>
  <!-- ground and grid -->
  <rect x="0" y="${vy}" width="720" height="${440 - vy}" fill="url(#wrGround)"/>
  ${grid}
  <!-- the neon path -->
  <path d="M ${vx - 14} ${vy} L ${vx + 14} ${vy} L ${vx + 300} 440 L ${vx - 300} 440 Z" fill="url(#wrRoad)"/>
  <path d="M ${vx - 14} ${vy} L ${vx - 300} 440" stroke="${CY}" stroke-width="6" opacity="0.5" filter="url(#wrGlowS)"/>
  <path d="M ${vx - 14} ${vy} L ${vx - 300} 440" stroke="#c9fbff" stroke-width="2.5"/>
  <path d="M ${vx + 14} ${vy} L ${vx + 300} 440" stroke="${MG}" stroke-width="6" opacity="0.5" filter="url(#wrGlowS)"/>
  <path d="M ${vx + 14} ${vy} L ${vx + 300} 440" stroke="#ffc8f4" stroke-width="2.5"/>
  ${[0.08, 0.2, 0.36, 0.58, 0.86].map((t) => { const y = vy + t * (440 - vy); const h = 4 + t * 26; return `<rect x="${vx - 2 - t * 5}" y="${y}" width="${4 + t * 10}" height="${h}" fill="#FFD34E" opacity="0.7"/>`; }).join("")}
  ${posts}

  <!-- duel circle on the ground -->
  <ellipse cx="${cx}" cy="${cy + r + 4}" rx="190" ry="44" fill="${GL}" opacity="0.18"/>
  <ellipse cx="${cx}" cy="${cy + r + 4}" rx="190" ry="44" fill="none" stroke="${GL}" stroke-width="10" opacity="0.5" filter="url(#wrGlowS)"/>
  <ellipse cx="${cx}" cy="${cy + r + 4}" rx="190" ry="44" fill="none" stroke="#ffc0c8" stroke-width="3"/>
  <ellipse cx="${cx}" cy="${cy + r + 4}" rx="150" ry="32" fill="none" stroke="${CY}" stroke-width="2" stroke-dasharray="10 8" opacity="0.8"/>
  ${Array.from({ length: 16 }, (_, k) => { const a = (k / 16) * Math.PI * 2; return `<rect x="${cx + Math.cos(a) * 190 - 4}" y="${cy + r + 4 + Math.sin(a) * 44 - 2}" width="8" height="4" fill="#fff" opacity="0.9"/>`; }).join("")}
  <!-- rival shadow -->
  <ellipse cx="${cx + 8}" cy="${cy + r + 2}" rx="${r * 0.95}" ry="16" fill="#000" opacity="0.55"/>
  <!-- red glow behind the rival -->
  <circle cx="${cx}" cy="${cy}" r="${r * 1.35}" fill="${GL}" opacity="0.5" filter="url(#wrGlowL)"/>
  ${px}
  ${rival}
  <!-- scan lines over the scene -->
  <rect x="0" y="${cy - 40}" width="720" height="3" fill="${CY}" opacity="0.18"/>
  <rect x="0" y="${cy + 30}" width="720" height="2" fill="${MG}" opacity="0.2"/>
  <rect width="720" height="440" fill="url(#wrVig)"/>
</svg>`;
}

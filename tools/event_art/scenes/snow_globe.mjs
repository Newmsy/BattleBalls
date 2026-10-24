// Snow globe: a giant snow globe on an ornate pedestal in a moonlit snowfield
// under an aurora. Inside, amid swirling snow and a tiny snowy village, a tiny
// Frost critter waves out at you. Frost family.
import { ball, eye, shade, INK } from "../../brand/parts.mjs";

const W = 720, H = 440;
const FR = "#8FE6FF";

function rng(seed) {
  let s = seed;
  return () => ((s = (s * 16807) % 2147483647) / 2147483647);
}

const twinkle = (x, y, s, col = "#fff", o = 1) =>
  `<path d="M ${x} ${y - s} Q ${x} ${y} ${x + s} ${y} Q ${x} ${y} ${x} ${y + s} Q ${x} ${y} ${x - s} ${y} Q ${x} ${y} ${x} ${y - s} Z" fill="${col}" opacity="${o}"/>`;

// Snowy pine: stacked triangles with snow caps.
function pine(x, y, h, col = "#14213e", snow = "#dff4ff", lit = 0.6) {
  const w = h * 0.42;
  let d = "", caps = "";
  for (let k = 0; k < 3; k++) {
    const top = y - h + k * h * 0.26, bot = top + h * 0.42, ww = w * (0.55 + k * 0.25);
    d += `<path d="M ${x} ${top} L ${x + ww} ${bot} Q ${x} ${bot + h * 0.05} ${x - ww} ${bot} Z" fill="${col}"/>`;
    caps += `<path d="M ${x} ${top} L ${x + ww * 0.45} ${top + h * 0.19} Q ${x + ww * 0.2} ${top + h * 0.15} ${x} ${top + h * 0.2} Q ${x - ww * 0.3} ${top + h * 0.14} ${x - ww * 0.55} ${top + h * 0.23} Z" fill="${snow}" opacity="${lit}"/>`;
  }
  return `<rect x="${x - h * 0.04}" y="${y - h * 0.1}" width="${h * 0.08}" height="${h * 0.12}" fill="#1a1428"/>${d}${caps}`;
}

export default function () {
  const R = rng(97);
  const gx = 360, gy = 196, gr = 122; // globe

  // Stars.
  let stars = "";
  for (let k = 0; k < 80; k++) {
    const x = R() * W, y = R() * 200, s = R();
    stars += `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="${(0.5 + s * 1.4).toFixed(2)}" fill="#e6f4ff" opacity="${(0.25 + s * 0.6).toFixed(2)}"/>`;
  }
  // Falling snow outside.
  let snow = "";
  for (let k = 0; k < 60; k++) {
    const x = R() * W, y = R() * 400, s = R();
    if (Math.hypot(x - gx, y - gy) < gr + 4) continue;
    snow += `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="${(0.9 + s * 2.4).toFixed(2)}" fill="#fff" opacity="${(0.35 + s * 0.55).toFixed(2)}"/>`;
  }
  // Swirling snow inside the globe: flakes along a few spiral arms.
  let swirl = "";
  for (let arm = 0; arm < 4; arm++) {
    for (let k = 0; k < 22; k++) {
      const t = k / 22;
      const a = arm * (Math.PI / 2) + t * Math.PI * 2.2;
      const rr = 18 + t * 92;
      const x = gx + Math.cos(a) * rr + (R() - 0.5) * 10;
      const y = gy - 6 + Math.sin(a) * rr * 0.78 + (R() - 0.5) * 10;
      if (Math.hypot(x - gx, y - gy) > gr - 8) continue;
      swirl += `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="${(1.2 + R() * 2.6).toFixed(1)}" fill="#fff" opacity="${(0.55 + R() * 0.45).toFixed(2)}"/>`;
    }
  }
  // Swirl trails (faint arcs showing motion).
  let trails = "";
  for (let k = 0; k < 4; k++) {
    const r0 = 40 + k * 18;
    trails += `<path d="M ${gx - r0} ${gy - 10 + k * 4} A ${r0} ${r0 * 0.7} 0 0 1 ${gx + r0 * 0.6} ${gy - r0 * 0.56 - 10}" fill="none" stroke="#fff" stroke-width="${2.2 - k * 0.3}" stroke-linecap="round" opacity="${0.28 - k * 0.04}"/>`;
  }
  // Footprints leading up to the pedestal.
  let prints = "";
  for (let k = 0; k < 7; k++) {
    const t = k / 7;
    const x = 120 + t * 180 + (k % 2 ? 7 : -7), y = 428 - t * 52;
    const s = 1 - t * 0.45;
    prints += `<ellipse cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" rx="${(8 * s).toFixed(1)}" ry="${(4 * s).toFixed(1)}" fill="#7a96d8" opacity="0.55"/>`;
  }

  // Tiny critter inside, waving.
  const cx = 356, cy = 242, cr = 32;
  const critter = `
    <ellipse cx="${cx + 2}" cy="${cy + cr - 2}" rx="${cr * 0.95}" ry="5" fill="#2a4a8a" opacity="0.45"/>
    <!-- waving arm (behind the body edge) with motion lines -->
    <path d="M ${cx + cr * 0.75} ${cy - 2} Q ${cx + cr + 10} ${cy - 14} ${cx + cr + 12} ${cy - 30}" fill="none" stroke="${shade(FR, -0.5)}" stroke-width="9" stroke-linecap="round"/>
    <path d="M ${cx + cr * 0.75} ${cy - 2} Q ${cx + cr + 10} ${cy - 14} ${cx + cr + 12} ${cy - 30}" fill="none" stroke="${shade(FR, 0.1)}" stroke-width="5.5" stroke-linecap="round"/>
    <circle cx="${cx + cr + 12}" cy="${cy - 32}" r="6.5" fill="${shade(FR, 0.2)}" stroke="${shade(FR, -0.5)}" stroke-width="2"/>
    <path d="M ${cx + cr + 22} ${cy - 44} q 6 6 4 14 M ${cx + cr + 28} ${cy - 38} q 4 5 2 10 M ${cx + cr - 2} ${cy - 46} q -4 4 -2 10" fill="none" stroke="#fff" stroke-width="2" stroke-linecap="round" opacity="0.85"/>
    ${ball(cx, cy, cr, FR, { glow: false })}
    <!-- little scarf -->
    <path d="M ${cx - cr * 0.86} ${cy + cr * 0.36} Q ${cx} ${cy + cr * 0.62} ${cx + cr * 0.86} ${cy + cr * 0.36} L ${cx + cr * 0.8} ${cy + cr * 0.56} Q ${cx} ${cy + cr * 0.82} ${cx - cr * 0.8} ${cy + cr * 0.56} Z" fill="#ff7ac8" stroke="#8a2a68" stroke-width="1.6"/>
    <path d="M ${cx - cr * 0.5} ${cy + cr * 0.6} l -4 14 l 8 0 l 3 -12 Z" fill="#ff7ac8" stroke="#8a2a68" stroke-width="1.6" stroke-linejoin="round"/>
    ${eye(cx - 10, cy - 7, 7, 8.5, 0.1, 0.1, 4)}${eye(cx + 10, cy - 7, 7, 8.5, 0.1, 0.1, 4)}
    <path d="M ${cx - 10} ${cy + 4} Q ${cx} ${cy + 17} ${cx + 10} ${cy + 4} Z" fill="${INK}"/>
    <ellipse cx="${cx}" cy="${cy + 10}" rx="4.5" ry="2.5" fill="#ff5a7a"/>
    <ellipse cx="${cx - 20}" cy="${cy + 4}" rx="5" ry="3" fill="#ff8ad0" opacity="0.55"/>
    <ellipse cx="${cx + 20}" cy="${cy + 4}" rx="5" ry="3" fill="#ff8ad0" opacity="0.55"/>
    <!-- earmuff-ish frost tuft -->
    <path d="M ${cx - 6} ${cy - cr + 2} q -2 -10 4 -14 q 0 6 4 7 q 2 -7 8 -7 q -4 8 -2 14 Z" fill="#e8fbff" stroke="${shade(FR, -0.5)}" stroke-width="1.6"/>`;

  // Tiny snowy village inside.
  const scene = `
    <!-- inner sky tint -->
    <circle cx="${gx}" cy="${gy}" r="${gr}" fill="url(#sgInner)"/>
    <path d="M ${gx - 70} ${gy - 60} Q ${gx} ${gy - 100} ${gx + 80} ${gy - 70}" stroke="#7affc8" stroke-width="10" fill="none" opacity="0.18" filter="url(#sgBlur6)"/>
    <!-- far hills -->
    <path d="M ${gx - gr} ${gy + 54} Q ${gx - 70} ${gy + 20} ${gx - 20} ${gy + 44} Q ${gx + 40} ${gy + 14} ${gx + gr} ${gy + 46} L ${gx + gr} ${gy + gr} L ${gx - gr} ${gy + gr} Z" fill="#9fc4f0"/>
    ${pine(gx - 74, gy + 52, 46, "#1d3a6a", "#f0faff", 0.9)}${pine(gx - 52, gy + 50, 34, "#24447a", "#f0faff", 0.9)}
    ${pine(gx + 78, gy + 50, 50, "#1d3a6a", "#f0faff", 0.9)}${pine(gx + 100, gy + 58, 32, "#24447a", "#f0faff", 0.9)}
    <!-- tiny cottage with a warm window -->
    <g transform="translate(${gx - 44} ${gy + 30})">
      <rect x="-14" y="-6" width="28" height="22" fill="#6a4a7a" stroke="#2a1a3a" stroke-width="1.5"/>
      <path d="M -19 -4 L 0 -22 L 19 -4 Z" fill="#f0faff" stroke="#8ab0e0" stroke-width="1.5" stroke-linejoin="round"/>
      <rect x="-5" y="1" width="10" height="9" rx="1" fill="#ffd36a"/>
      <circle cx="0" cy="5" r="12" fill="#ffd36a" opacity="0.35" filter="url(#sgBlur6)"/>
      <rect x="8" y="-22" width="5" height="10" fill="#4a3a5a"/>
    </g>
    <!-- snow ground the critter stands on -->
    <path d="M ${gx - gr} ${gy + 80} Q ${gx - 50} ${gy + 56} ${gx} ${gy + 74} Q ${gx + 60} ${gy + 58} ${gx + gr} ${gy + 76} L ${gx + gr} ${gy + gr} L ${gx - gr} ${gy + gr} Z" fill="url(#sgInnerSnow)"/>
    <path d="M ${gx - gr} ${gy + 80} Q ${gx - 50} ${gy + 56} ${gx} ${gy + 74} Q ${gx + 60} ${gy + 58} ${gx + gr} ${gy + 76}" stroke="#fff" stroke-width="2.5" fill="none" opacity="0.9"/>
    ${critter}
    <!-- tiny snowman -->
    <circle cx="${gx + 52}" cy="${gy + 70}" r="9" fill="#f6fcff" stroke="#9ab8e8" stroke-width="1.2"/>
    <circle cx="${gx + 52}" cy="${gy + 56}" r="6.5" fill="#f6fcff" stroke="#9ab8e8" stroke-width="1.2"/>
    <circle cx="${gx + 50}" cy="${gy + 55}" r="1" fill="${INK}"/><circle cx="${gx + 54}" cy="${gy + 55}" r="1" fill="${INK}"/>
    <path d="M ${gx + 52} ${gy + 57} l 5 1 l -5 1 Z" fill="#ff8a3a"/>
    ${trails}
    ${swirl}`;

  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">
  <defs>
    <linearGradient id="sgSky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#0D0F26"/><stop offset="0.55" stop-color="#16184a"/><stop offset="1" stop-color="#2c3a7a"/>
    </linearGradient>
    <linearGradient id="sgAur1" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#5fffb8" stop-opacity="0"/><stop offset="0.25" stop-color="#5fffb8"/><stop offset="0.6" stop-color="#3ee6ff"/><stop offset="0.9" stop-color="#b07cff"/><stop offset="1" stop-color="#b07cff" stop-opacity="0"/>
    </linearGradient>
    <linearGradient id="sgAurCurtain" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#5fffb8" stop-opacity="0"/><stop offset="0.5" stop-color="#5fffb8" stop-opacity="0.35"/><stop offset="1" stop-color="#3ee6ff" stop-opacity="0"/>
    </linearGradient>
    <radialGradient id="sgMoon" cx="0.4" cy="0.4" r="0.7">
      <stop offset="0" stop-color="#ffffff"/><stop offset="0.6" stop-color="#e6f4ff"/><stop offset="1" stop-color="#a8c6ef"/>
    </radialGradient>
    <linearGradient id="sgSnow" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#d8ecff"/><stop offset="0.4" stop-color="#9ab8ec"/><stop offset="1" stop-color="#4a5aa8"/>
    </linearGradient>
    <linearGradient id="sgSnowFar" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#8aa8e0"/><stop offset="1" stop-color="#3a4688"/>
    </linearGradient>
    <linearGradient id="sgMount" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#5a6ab8"/><stop offset="1" stop-color="#22285e"/>
    </linearGradient>
    <linearGradient id="sgSnowNear" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#7a92d8"/><stop offset="1" stop-color="#262c6a"/>
    </linearGradient>
    <radialGradient id="sgInner" cx="0.5" cy="0.35" r="0.65">
      <stop offset="0" stop-color="#4a6ad0"/><stop offset="0.7" stop-color="#26318a"/><stop offset="1" stop-color="#1a2066"/>
    </radialGradient>
    <linearGradient id="sgInnerSnow" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#ffffff"/><stop offset="1" stop-color="#a8c8f4"/>
    </linearGradient>
    <radialGradient id="sgGlass" cx="0.5" cy="0.5" r="0.5">
      <stop offset="0" stop-color="#bfefff" stop-opacity="0"/><stop offset="0.78" stop-color="#bfefff" stop-opacity="0.06"/><stop offset="0.94" stop-color="#d8f6ff" stop-opacity="0.32"/><stop offset="1" stop-color="#ffffff" stop-opacity="0.6"/>
    </radialGradient>
    <radialGradient id="sgSheen" cx="0.3" cy="0.22" r="0.9">
      <stop offset="0" stop-color="#ffffff" stop-opacity="0.32"/><stop offset="0.35" stop-color="#ffffff" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="sgWood" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#2a2458"/><stop offset="0.3" stop-color="#5a4aa0"/><stop offset="0.55" stop-color="#3a2f78"/><stop offset="1" stop-color="#1a1640"/>
    </linearGradient>
    <linearGradient id="sgGold" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#8a6a20"/><stop offset="0.3" stop-color="#fff1b0"/><stop offset="0.55" stop-color="#ffd23f"/><stop offset="1" stop-color="#7a5414"/>
    </linearGradient>
    <radialGradient id="sgGem" cx="0.35" cy="0.3" r="0.8">
      <stop offset="0" stop-color="#ffffff"/><stop offset="0.45" stop-color="#8fe6ff"/><stop offset="1" stop-color="#2a7ac8"/>
    </radialGradient>
    <radialGradient id="sgVig" cx="50%" cy="50%" r="72%">
      <stop offset="0.6" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.55"/>
    </radialGradient>
    <clipPath id="sgClip"><circle cx="${gx}" cy="${gy}" r="${gr - 2}"/></clipPath>
    <filter id="sgBlur3" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="3"/></filter>
    <filter id="sgBlur6" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="6"/></filter>
    <filter id="sgBlur14" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="14"/></filter>
    <filter id="sgBlur40" x="-80%" y="-80%" width="260%" height="260%"><feGaussianBlur stdDeviation="40"/></filter>
  </defs>

  <!-- sky, stars, aurora, moon -->
  <rect width="${W}" height="${H}" fill="url(#sgSky)"/>
  ${stars}
  <g filter="url(#sgBlur14)" opacity="0.75">
    <path d="M -20 120 C 120 40 240 140 380 70 C 500 10 600 90 740 40" stroke="url(#sgAur1)" stroke-width="34" fill="none"/>
    <path d="M -20 160 C 140 100 260 170 400 110 C 520 60 620 120 740 90" stroke="url(#sgAur1)" stroke-width="16" fill="none" opacity="0.6"/>
  </g>
  <g filter="url(#sgBlur6)" opacity="0.7">
    ${Array.from({ length: 22 }, (_, k) => {
      const x = 20 + k * 32;
      const t = x / 720;
      const top = 70 + Math.sin(t * 6.2 + 0.5) * 34 - 20;
      return `<rect x="${x}" y="${top.toFixed(1)}" width="12" height="${(90 + (k % 3) * 20).toFixed(1)}" fill="url(#sgAurCurtain)"/>`;
    }).join("")}
  </g>
  <path d="M -20 120 C 120 40 240 140 380 70 C 500 10 600 90 740 40" stroke="#c8fff0" stroke-width="2" fill="none" opacity="0.35"/>
  <circle cx="610" cy="72" r="60" fill="#cfe6ff" opacity="0.25" filter="url(#sgBlur14)"/>
  <circle cx="610" cy="72" r="30" fill="url(#sgMoon)"/>
  <circle cx="600" cy="66" r="5" fill="#a8c6ef" opacity="0.5"/><circle cx="620" cy="82" r="3.5" fill="#a8c6ef" opacity="0.5"/>

  <!-- distant mountains -->
  <path d="M -10 260 L 60 190 L 110 220 L 170 160 L 240 230 L 300 200 L 360 240 L 430 190 L 500 230 L 560 170 L 630 210 L 730 160 L 730 300 L -10 300 Z" fill="url(#sgMount)"/>
  <path d="M 60 190 L 76 206 L 66 204 L 56 212 L 46 204 Z M 170 160 L 190 182 L 176 178 L 166 188 L 152 178 Z M 430 190 L 446 206 L 434 204 L 424 210 L 416 204 Z M 560 170 L 580 192 L 566 188 L 556 196 L 544 188 Z M 730 160 L 730 186 L 712 178 L 700 186 Z" fill="#e6f4ff" opacity="0.85"/>
  <!-- far snowfield with pine line -->
  <path d="M -10 272 Q 180 246 360 266 Q 540 248 730 270 L 730 330 L -10 330 Z" fill="url(#sgSnowFar)"/>
  ${[[30, 274, 50], [62, 270, 38], [96, 268, 56], [140, 266, 40], [574, 266, 44], [612, 270, 58], [652, 268, 40], [690, 272, 52]].map(([x, y, h]) => pine(x, y, h, "#151c44", "#cfe6ff", 0.75)).join("")}

  <!-- near snow drifts -->
  <path d="M -10 330 Q 120 300 250 320 Q 360 332 470 316 Q 600 300 730 326 L 730 440 L -10 440 Z" fill="url(#sgSnow)"/>
  <path d="M -10 330 Q 120 300 250 320 Q 360 332 470 316 Q 600 300 730 326" stroke="#ffffff" stroke-width="3" fill="none" opacity="0.8"/>
  <ellipse cx="${gx}" cy="380" rx="230" ry="50" fill="#8fe6ff" opacity="0.28" filter="url(#sgBlur14)"/>
  ${prints}
  ${Array.from({ length: 16 }, () => { const x = 40 + R() * 640, y = 330 + R() * 90; return Math.abs(x - gx) < 150 && y < 400 ? "" : twinkle(x, y, 2 + R() * 4, "#ffffff", 0.5 + R() * 0.5); }).join("")}

  <!-- globe glow + shadow -->
  <circle cx="${gx}" cy="${gy}" r="${gr + 40}" fill="#8fe6ff" opacity="0.22" filter="url(#sgBlur40)"/>
  <ellipse cx="${gx + 10}" cy="392" rx="150" ry="18" fill="#1a2058" opacity="0.6" filter="url(#sgBlur6)"/>

  <!-- globe interior -->
  <g clip-path="url(#sgClip)">${scene}</g>
  <!-- glass -->
  <circle cx="${gx}" cy="${gy}" r="${gr}" fill="url(#sgGlass)"/>
  <circle cx="${gx}" cy="${gy}" r="${gr}" fill="url(#sgSheen)"/>
  <circle cx="${gx}" cy="${gy}" r="${gr}" fill="none" stroke="#e8fbff" stroke-width="3" opacity="0.8"/>
  <path d="M ${gx - gr * 0.82} ${gy - gr * 0.12} A ${gr * 0.84} ${gr * 0.84} 0 0 1 ${gx - gr * 0.2} ${gy - gr * 0.8}" fill="none" stroke="#fff" stroke-width="9" stroke-linecap="round" opacity="0.7"/>
  <path d="M ${gx - gr * 0.62} ${gy - gr * 0.62} A ${gr * 0.86} ${gr * 0.86} 0 0 1 ${gx - gr * 0.5} ${gy - gr * 0.7}" fill="none" stroke="#fff" stroke-width="4" stroke-linecap="round" opacity="0.9"/>
  <ellipse cx="${gx - gr * 0.28}" cy="${gy - gr * 0.86}" rx="7" ry="4" fill="#fff" opacity="0.9" transform="rotate(-20 ${gx - gr * 0.28} ${gy - gr * 0.86})"/>
  <!-- moon window reflection, top right -->
  <path d="M ${gx + gr * 0.48} ${gy - gr * 0.64} q 18 10 24 30 q -16 -8 -24 -30 Z" fill="#fff" opacity="0.55"/>
  <circle cx="${gx + gr * 0.6}" cy="${gy - gr * 0.44}" r="4" fill="#fff" opacity="0.7"/>
  <!-- aurora reflection along the right rim -->
  <path d="M ${gx + gr * 0.94} ${gy - gr * 0.2} A ${gr * 0.96} ${gr * 0.96} 0 0 1 ${gx + gr * 0.5} ${gy + gr * 0.8}" fill="none" stroke="#5fffb8" stroke-width="5" stroke-linecap="round" opacity="0.4"/>
  <path d="M ${gx - gr * 0.9} ${gy + gr * 0.3} A ${gr * 0.95} ${gr * 0.95} 0 0 0 ${gx - gr * 0.55} ${gy + gr * 0.75}" fill="none" stroke="#b07cff" stroke-width="4" stroke-linecap="round" opacity="0.4"/>

  <!-- pedestal -->
  <path d="M ${gx - 100} 302 Q ${gx} 322 ${gx + 100} 302 L ${gx + 112} 344 Q ${gx} 362 ${gx - 112} 344 Z" fill="url(#sgWood)" stroke="#0e0c2a" stroke-width="3" stroke-linejoin="round"/>
  <path d="M ${gx - 104} 300 Q ${gx} 322 ${gx + 104} 300 L ${gx + 104} 308 Q ${gx} 330 ${gx - 104} 308 Z" fill="url(#sgGold)" stroke="#5a3a10" stroke-width="2"/>
  <path d="M ${gx - 130} 350 Q ${gx} 372 ${gx + 130} 350 L ${gx + 138} 384 Q ${gx} 404 ${gx - 138} 384 Z" fill="url(#sgWood)" stroke="#0e0c2a" stroke-width="3" stroke-linejoin="round"/>
  <path d="M ${gx - 116} 342 Q ${gx} 364 ${gx + 116} 342 L ${gx + 130} 352 Q ${gx} 374 ${gx - 130} 352 Z" fill="url(#sgGold)" stroke="#5a3a10" stroke-width="2"/>
  <path d="M ${gx - 138} 384 Q ${gx} 404 ${gx + 138} 384" stroke="#ffd23f" stroke-width="2.5" fill="none" opacity="0.7"/>
  <!-- snow piled on the base -->
  <path d="M ${gx - 136} 382 Q ${gx - 120} 368 ${gx - 96} 374 Q ${gx - 84} 366 ${gx - 70} 378 Q ${gx - 100} 394 ${gx - 136} 382 Z" fill="#f2faff"/>
  <path d="M ${gx + 80} 374 Q ${gx + 100} 362 ${gx + 120} 372 Q ${gx + 134} 372 ${gx + 138} 384 Q ${gx + 110} 390 ${gx + 80} 374 Z" fill="#f2faff"/>
  <!-- frost gem inlay and scrollwork -->
  <circle cx="${gx}" cy="334" r="13" fill="url(#sgGold)" stroke="#5a3a10" stroke-width="2"/>
  <circle cx="${gx}" cy="334" r="9" fill="url(#sgGem)"/>
  <circle cx="${gx}" cy="334" r="22" fill="#8fe6ff" opacity="0.35" filter="url(#sgBlur6)"/>
  ${twinkle(gx - 3, 331, 4, "#fff")}
  <path d="M ${gx - 20} 334 q -16 -8 -30 2 q -10 8 -24 0 M ${gx + 20} 334 q 16 -8 30 2 q 10 8 24 0" stroke="#ffd23f" stroke-width="2.4" fill="none" opacity="0.8" stroke-linecap="round"/>
  <!-- feet -->
  ${[-1, 1].map((s) => `<ellipse cx="${gx + s * 104}" cy="396" rx="18" ry="8" fill="url(#sgGold)" stroke="#5a3a10" stroke-width="2"/>`).join("")}
  <!-- rim light on the pedestal (moon on the right) -->
  <path d="M ${gx + 100} 304 L ${gx + 112} 344 M ${gx + 130} 352 L ${gx + 138} 384" stroke="#cfe6ff" stroke-width="2" opacity="0.6"/>

  <!-- foreground framing drifts and pines -->
  <path d="M -10 440 L -10 380 Q 40 360 90 384 Q 130 404 150 440 Z" fill="url(#sgSnowNear)"/>
  <path d="M -10 380 Q 40 360 90 384 Q 130 404 150 440" stroke="#fff" stroke-width="2.5" fill="none"/>
  <path d="M 730 440 L 730 370 Q 680 356 640 384 Q 610 408 600 440 Z" fill="url(#sgSnowNear)"/>
  <path d="M 730 370 Q 680 356 640 384 Q 610 408 600 440" stroke="#fff" stroke-width="2.5" fill="none"/>
  ${pine(30, 380, 150, "#0c1236", "#cfe6ff", 0.55)}
  ${pine(694, 372, 170, "#0c1236", "#cfe6ff", 0.55)}

  <g>${snow}</g>
  ${twinkle(gx + gr * 0.9, gy - gr * 0.9, 12, "#ffffff")}
  ${twinkle(gx - gr * 1.05, gy + gr * 0.2, 7, "#e8fbff", 0.85)}
  <rect width="${W}" height="${H}" fill="url(#sgVig)"/>
</svg>`;
}

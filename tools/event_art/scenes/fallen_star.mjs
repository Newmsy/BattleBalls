// Cosmic family: a star has just landed in a small glowing crater on a night
// meadow, still fizzing with sparks and steam. Constellations overhead, the
// streak it fell along, and a little Cosmic critter staring at it in awe.
import { ball, eye, shade, INK } from "../../brand/parts.mjs";

const COS = "#6f6bff";
const W = 720, H = 440;

function rng(seed) {
  let s = seed;
  return () => ((s = (s * 16807) % 2147483647) / 2147483647);
}
const f = (n) => n.toFixed(1);

const twinkle = (x, y, s, col = "#fff", o = 1) =>
  `<path d="M ${f(x)} ${f(y - s)} Q ${f(x)} ${f(y)} ${f(x + s)} ${f(y)} Q ${f(x)} ${f(y)} ${f(x)} ${f(y + s)} Q ${f(x)} ${f(y)} ${f(x - s)} ${f(y)} Q ${f(x)} ${f(y)} ${f(x)} ${f(y - s)} Z" fill="${col}" opacity="${o}"/>`;

// A plump 5-point star with rounded tips.
function starPath(cx, cy, r, inner = 0.52, rot = 0) {
  const pts = [];
  for (let k = 0; k < 10; k++) {
    const a = rot + (k * Math.PI) / 5 - Math.PI / 2;
    const rr = k % 2 ? r * inner : r;
    pts.push([cx + Math.cos(a) * rr, cy + Math.sin(a) * rr]);
  }
  // round the corners with quadratic curves through midpoints
  let d = "";
  for (let k = 0; k < 10; k++) {
    const p = pts[k], n = pts[(k + 1) % 10];
    const m = [(p[0] + n[0]) / 2, (p[1] + n[1]) / 2];
    d += k === 0 ? `M ${f(m[0])} ${f(m[1])} ` : "";
    const nn = pts[(k + 2) % 10];
    const m2 = [(n[0] + nn[0]) / 2, (n[1] + nn[1]) / 2];
    d += `Q ${f(n[0])} ${f(n[1])} ${f(m2[0])} ${f(m2[1])} `;
  }
  return d + "Z";
}

// A constellation: stars joined by faint lines.
function constellation(pts, col = "#bfc4ff") {
  let lines = "", dots = "";
  for (let k = 1; k < pts.length; k++) {
    const [a, b] = [pts[k - 1], pts[k]];
    lines += `<line x1="${a[0]}" y1="${a[1]}" x2="${b[0]}" y2="${b[1]}" stroke="${col}" stroke-width="1.2" opacity="0.35" stroke-dasharray="3 4"/>`;
  }
  for (const [x, y, s = 1] of pts) {
    dots += `<circle cx="${x}" cy="${y}" r="${5 * s}" fill="${col}" opacity="0.35" filter="url(#fsBlur3)"/><circle cx="${x}" cy="${y}" r="${1.8 * s}" fill="#ffffff"/>`;
  }
  return lines + dots;
}

export default function () {
  const R = rng(83);

  // Star field.
  let stars = "";
  for (let k = 0; k < 120; k++) {
    const x = R() * W, y = R() * 260, s = R();
    stars += `<circle cx="${f(x)}" cy="${f(y)}" r="${(0.5 + s * 1.3).toFixed(2)}" fill="${R() < 0.2 ? "#ffe9b0" : "#e0e4ff"}" opacity="${(0.25 + s * 0.65).toFixed(2)}"/>`;
  }
  for (let k = 0; k < 8; k++) stars += twinkle(R() * W, 20 + R() * 200, 3 + R() * 4, "#eef0ff", 0.85);

  // Ground hills.
  const hills = `
    <path d="M 0 268 Q 90 236 180 252 Q 260 266 330 246 Q 420 222 520 248 Q 620 270 720 240 L 720 440 L 0 440 Z" fill="#1c1850"/>
    <path d="M 0 268 Q 90 236 180 252 Q 260 266 330 246 Q 420 222 520 248 Q 620 270 720 240" fill="none" stroke="#8f8bff" stroke-width="2" opacity="0.35"/>
    <path d="M 0 300 Q 140 280 260 296 Q 360 306 460 292 Q 600 274 720 296 L 720 440 L 0 440 Z" fill="url(#fsMeadow)"/>`;

  // Sparks fizzing out of the crater.
  const sx = 384, sy = 280; // star centre
  let sparks = "";
  for (let k = 0; k < 26; k++) {
    const a = -Math.PI * (0.08 + R() * 0.84);
    const d0 = 64 + R() * 20, d1 = d0 + 16 + R() * 46;
    const x0 = sx + Math.cos(a) * d0, y0 = sy + Math.sin(a) * d0 * 0.85;
    const x1 = sx + Math.cos(a) * d1, y1 = sy + Math.sin(a) * d1 * 0.85;
    const c = R() < 0.5 ? "#fff3b0" : R() < 0.5 ? "#ffd23f" : "#b8b4ff";
    sparks += `<line x1="${f(x0)}" y1="${f(y0)}" x2="${f(x1)}" y2="${f(y1)}" stroke="${c}" stroke-width="${(1.5 + R() * 2).toFixed(1)}" stroke-linecap="round" opacity="${(0.55 + R() * 0.45).toFixed(2)}"/>`;
    if (k % 2 === 0) sparks += `<circle cx="${f(x1 + Math.cos(a) * 8)}" cy="${f(y1 + Math.sin(a) * 8)}" r="${(1.5 + R() * 2).toFixed(1)}" fill="${c}"/>`;
  }
  // Floating sparkle bits around.
  let bits = "";
  for (let k = 0; k < 16; k++) {
    const x = sx + (R() - 0.5) * 360, y = 150 + R() * 200;
    bits += twinkle(x, y, 2.5 + R() * 5, R() < 0.5 ? "#fff3b0" : "#cfcaff", 0.6 + R() * 0.4);
  }
  // Steam wisps (it is still warm).
  let steam = "";
  for (const [x, h, o] of [[350, 90, 0.35], [404, 110, 0.3], [428, 70, 0.25]]) {
    steam += `<path d="M ${x} ${sy - 50} q -12 ${-h * 0.25} 0 ${-h * 0.5} q 12 ${-h * 0.25} 0 ${-h * 0.5}" fill="none" stroke="#e6e4ff" stroke-width="7" stroke-linecap="round" opacity="${o}" filter="url(#fsBlur3)"/>`;
  }

  // Crater: dark rim lip, glowing bowl, scattered clods.
  const cx = 384, cy = 326;
  let clods = "";
  for (let k = 0; k < 16; k++) {
    const a = -0.25 + R() * (Math.PI + 0.5), d = 1.12 + R() * 0.45;
    const x = cx + Math.cos(a) * 128 * d, y = cy + Math.sin(a) * 30 * d + 4;
    const r = 3 + R() * 6;
    clods += `<ellipse cx="${f(x)}" cy="${f(y)}" rx="${f(r)}" ry="${f(r * 0.7)}" fill="#3a2e6a" stroke="#0c0a24" stroke-width="1.5"/><ellipse cx="${f(x - r * 0.2)}" cy="${f(y - r * 0.3)}" rx="${f(r * 0.5)}" ry="${f(r * 0.25)}" fill="#ffd77a" opacity="0.45"/>`;
  }
  // Bumpy dirt rim: clumps around the bowl, lit gold on the side facing in.
  let rimBack = "", rimFront = "";
  const NR = 26;
  for (let k = 0; k < NR; k++) {
    const a = (k / NR) * Math.PI * 2 + R() * 0.1;
    const x = cx + Math.cos(a) * 134, y = cy + Math.sin(a) * 30;
    const r = (Math.sin(a) > 0 ? 13 : 11) + R() * 6;
    const lx = -Math.cos(a) * r * 0.35, ly = -Math.sin(a) * r * 0.3 - (Math.sin(a) > 0 ? r * 0.25 : 0);
    const clump = `<ellipse cx="${f(x)}" cy="${f(y)}" rx="${f(r * 1.25)}" ry="${f(r * 0.8)}" fill="${Math.sin(a) > 0 ? "#231d56" : "#2e2668"}" stroke="#0c0a24" stroke-width="2"/>
      <ellipse cx="${f(x + lx)}" cy="${f(y + ly)}" rx="${f(r * 0.75)}" ry="${f(r * 0.35)}" fill="#ffd77a" opacity="${Math.sin(a) > 0 ? 0.55 : 0.7}"/>`;
    if (Math.sin(a) < 0) rimBack += clump; else rimFront += clump;
  }
  const crater = `
    <ellipse cx="${cx}" cy="${cy}" rx="240" ry="70" fill="#ffd23f" opacity="0.3" filter="url(#fsBlur40)"/>
    <ellipse cx="${cx}" cy="${cy + 2}" rx="140" ry="34" fill="#1a1546"/>
    <ellipse cx="${cx}" cy="${cy + 2}" rx="128" ry="28" fill="url(#fsBowl)"/>
    <ellipse cx="${cx}" cy="${cy + 2}" rx="70" ry="12" fill="#ffffff" opacity="0.6" filter="url(#fsBlur6)"/>
    ${rimBack}`;

  // The star itself, half sunk and tilted.
  const star = `
    <circle cx="${sx}" cy="${sy}" r="150" fill="#ffd23f" opacity="0.22" filter="url(#fsBlur40)"/>
    <circle cx="${sx}" cy="${sy}" r="92" fill="#fff3b0" opacity="0.45" filter="url(#fsBlur18)"/>
    <g transform="rotate(14 ${sx} ${sy})">
      <path d="${starPath(sx, sy, 82, 0.52)}" fill="#ffd23f" opacity="0.7" filter="url(#fsBlur6)"/>
      <path d="${starPath(sx + 3, sy + 5, 78, 0.52)}" fill="#c27a10"/>
      <path d="${starPath(sx, sy, 78, 0.52)}" fill="url(#fsStar)" stroke="#e08a12" stroke-width="3.5" stroke-linejoin="round"/>
      <path d="${starPath(sx - 4, sy - 6, 44, 0.52)}" fill="#fffbe0" opacity="0.55" filter="url(#fsBlur3)"/>
      <ellipse cx="${sx - 26}" cy="${sy - 34}" rx="12" ry="6" fill="#fff" opacity="0.85" transform="rotate(-30 ${sx - 26} ${sy - 34})"/>
    </g>
    `;

  // The trail it fell along (from upper right).
  const trail = `
    <path d="M 720 20 Q 560 90 ${sx + 50} ${sy - 70}" fill="none" stroke="#ffd23f" stroke-width="26" opacity="0.18" filter="url(#fsBlur18)"/>
    <path d="M 720 20 Q 560 90 ${sx + 50} ${sy - 70}" fill="none" stroke="url(#fsTrail)" stroke-width="7" stroke-linecap="round"/>
    <path d="M 700 40 Q 560 104 ${sx + 64} ${sy - 62}" fill="none" stroke="url(#fsTrail)" stroke-width="2.5" stroke-linecap="round" opacity="0.6"/>`;

  // The awestruck Cosmic critter on the left, lit by the star.
  const kx = 176, ky = 310, kr = 50;
  const critter = `
    <ellipse cx="${kx + 6}" cy="${ky + kr * 0.95}" rx="${kr * 1.1}" ry="${kr * 0.2}" fill="#000" opacity="0.5" filter="url(#fsBlur3)"/>
    <ellipse cx="${kx}" cy="${ky - kr * 0.2}" rx="${kr * 1.35}" ry="${kr * 0.3}" fill="none" stroke="#ffe08a" stroke-width="${kr * 0.06}" opacity="0.7" transform="rotate(-14 ${kx} ${ky - kr * 0.2})" stroke-dasharray="${kr * 2.3} ${kr * 6}" stroke-dashoffset="${kr * 3.9}"/>
    ${ball(kx, ky, kr, COS, { glow: true })}
    <ellipse cx="${kx}" cy="${ky}" rx="${kr}" ry="${kr}" fill="url(#fsRim)"/>
    ${eye(kx - kr * 0.22, ky - kr * 0.16, kr * 0.24, kr * 0.3, 0.8, -0.2, kr * 0.14)}
    ${eye(kx + kr * 0.42, ky - kr * 0.16, kr * 0.24, kr * 0.3, 0.8, -0.2, kr * 0.14)}
    ${twinkle(kx - kr * 0.14, ky - kr * 0.26, kr * 0.08, "#ffe9a0")}${twinkle(kx + kr * 0.5, ky - kr * 0.26, kr * 0.08, "#ffe9a0")}
    <ellipse cx="${kx + kr * 0.12}" cy="${ky + kr * 0.36}" rx="${kr * 0.12}" ry="${kr * 0.16}" fill="${INK}"/>
    <ellipse cx="${kx - kr * 0.5}" cy="${ky + kr * 0.14}" rx="${kr * 0.13}" ry="${kr * 0.07}" fill="#ff8ad0" opacity="0.5"/>
    <ellipse cx="${kx + kr * 0.74}" cy="${ky + kr * 0.12}" rx="${kr * 0.11}" ry="${kr * 0.06}" fill="#ff8ad0" opacity="0.5"/>
    <ellipse cx="${kx}" cy="${ky - kr * 0.2}" rx="${kr * 1.35}" ry="${kr * 0.3}" fill="none" stroke="#ffe08a" stroke-width="${kr * 0.06}" opacity="0.85" transform="rotate(-14 ${kx} ${ky - kr * 0.2})" stroke-dasharray="${kr * 3.9} ${kr * 6}"/>
    <circle cx="${kx + kr * 1.24}" cy="${ky - kr * 0.55}" r="${kr * 0.12}" fill="#ffe08a"/>
    <!-- little sparkle of wonder -->
    ${twinkle(kx + kr * 0.95, ky - kr * 1.05, 9, "#fff6c8")}${twinkle(kx + kr * 1.25, ky - kr * 0.8, 5, "#fff6c8", 0.8)}`;

  // Grass and glowing flowers in the foreground.
  let grass = "";
  for (let k = 0; k < 46; k++) {
    const x = R() * W, y = 400 + R() * 46, h = 12 + R() * 26, d = (R() - 0.5) * 16;
    grass += `<path d="M ${f(x - 3)} ${f(y)} Q ${f(x + d * 0.4)} ${f(y - h * 0.6)} ${f(x + d)} ${f(y - h)} Q ${f(x + d * 0.2 + 2)} ${f(y - h * 0.5)} ${f(x + 3)} ${f(y)} Z" fill="${R() < 0.5 ? "#141040" : "#221c5a"}"/>`;
  }
  const flower = (x, y, col) => `
    <path d="M ${x} ${y} q 2 18 -2 34" fill="none" stroke="#2a4a6a" stroke-width="2.5"/>
    <circle cx="${x}" cy="${y}" r="12" fill="${col}" opacity="0.35" filter="url(#fsBlur3)"/>
    ${[0, 72, 144, 216, 288].map((a) => `<ellipse cx="${f(x + Math.cos((a * Math.PI) / 180) * 5)}" cy="${f(y + Math.sin((a * Math.PI) / 180) * 5)}" rx="4.5" ry="3" fill="${col}" transform="rotate(${a} ${f(x + Math.cos((a * Math.PI) / 180) * 5)} ${f(y + Math.sin((a * Math.PI) / 180) * 5)})"/>`).join("")}
    <circle cx="${x}" cy="${y}" r="2.6" fill="#fff6c8"/>`;
  const rocks = `
    <path d="M -10 440 L -10 380 Q 30 360 80 372 Q 120 384 132 420 L 136 440 Z" fill="#0e0c2c" stroke="#3a3480" stroke-width="2"/>
    <path d="M 730 440 L 730 364 Q 690 350 640 366 Q 600 384 592 420 L 588 440 Z" fill="#0e0c2c" stroke="#3a3480" stroke-width="2"/>
    <path d="M 0 380 Q 30 360 80 372" fill="none" stroke="#ffd77a" stroke-width="2" opacity="0.25"/>`;

  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">
  <defs>
    <linearGradient id="fsSky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#0D0F26"/><stop offset="0.45" stop-color="#16124a"/><stop offset="0.75" stop-color="#2e2478"/><stop offset="1" stop-color="#4a3a9a"/>
    </linearGradient>
    <linearGradient id="fsMeadow" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#241e62"/><stop offset="0.5" stop-color="#161244"/><stop offset="1" stop-color="#0b0a22"/>
    </linearGradient>
    <radialGradient id="fsStar" cx="0.4" cy="0.35" r="0.75">
      <stop offset="0" stop-color="#ffffff"/><stop offset="0.35" stop-color="#fff3b0"/><stop offset="0.75" stop-color="#ffd23f"/><stop offset="1" stop-color="#f0a020"/>
    </radialGradient>
    <radialGradient id="fsBowl" cx="0.5" cy="0.4" r="0.6">
      <stop offset="0" stop-color="#fff6c8"/><stop offset="0.35" stop-color="#ffd23f"/><stop offset="0.75" stop-color="#c06a2a"/><stop offset="1" stop-color="#3a2060"/>
    </radialGradient>
    <linearGradient id="fsLip" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#6a4a8a"/><stop offset="0.4" stop-color="#2e2464"/><stop offset="1" stop-color="#16123e"/>
    </linearGradient>
    <linearGradient id="fsTrail" x1="1" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#ffd23f" stop-opacity="0"/><stop offset="0.6" stop-color="#ffe9a0" stop-opacity="0.6"/><stop offset="1" stop-color="#ffffff" stop-opacity="0.95"/>
    </linearGradient>
    <linearGradient id="fsRim" x1="0" y1="0" x2="1" y2="0.15">
      <stop offset="0.55" stop-color="#ffd23f" stop-opacity="0"/><stop offset="1" stop-color="#ffd23f" stop-opacity="0.6"/>
    </linearGradient>
    <linearGradient id="fsBand" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#8f8bff" stop-opacity="0"/><stop offset="0.5" stop-color="#b8a4ff" stop-opacity="0.35"/><stop offset="1" stop-color="#8f8bff" stop-opacity="0"/>
    </linearGradient>
    <radialGradient id="fsVig" cx="50%" cy="50%" r="72%">
      <stop offset="0.6" stop-color="#05061a" stop-opacity="0"/><stop offset="1" stop-color="#05061a" stop-opacity="0.6"/>
    </radialGradient>
    <filter id="fsBlur3" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="3"/></filter>
    <filter id="fsBlur6" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="6"/></filter>
    <filter id="fsBlur18" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="18"/></filter>
    <filter id="fsBlur40" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="40"/></filter>
  </defs>

  <rect width="${W}" height="${H}" fill="url(#fsSky)"/>
  <!-- milky way band -->
  <path d="M -40 230 Q 200 120 420 70 Q 600 30 760 -20 L 760 60 Q 600 100 420 140 Q 200 190 -40 300 Z" fill="url(#fsBand)" filter="url(#fsBlur18)"/>
  ${stars}
  <!-- constellations -->
  ${constellation([[60, 70, 1.2], [104, 52], [150, 74, 1.1], [196, 58], [236, 96, 1.3], [210, 130]])}
  ${constellation([[470, 36, 1.1], [512, 70], [560, 54, 1.3], [596, 96], [548, 120, 1]])}
  ${constellation([[290, 150], [330, 128, 1.2], [372, 160], [330, 190, 1.1], [290, 150]])}
  <!-- a ringed planet far away -->
  <circle cx="96" cy="176" r="16" fill="#ff7ac8" opacity="0.85"/><circle cx="91" cy="171" r="16" fill="#16124a" opacity="0.35"/>
  <ellipse cx="96" cy="176" rx="28" ry="6" fill="none" stroke="#ffc0e6" stroke-width="2.5" opacity="0.8" transform="rotate(-18 96 176)"/>
  ${trail}
  ${hills}
  ${steam}
  ${crater}
  ${star}
  ${rimFront}
  ${sparks}
  ${clods}
  <!-- light spill on the meadow -->
  <ellipse cx="${cx}" cy="${cy + 40}" rx="260" ry="40" fill="#ffd23f" opacity="0.12" filter="url(#fsBlur18)"/>
  <g data-layer="critter" data-move="idle 4 0.6 0">${critter}</g>
  ${bits}
  ${rocks}
  ${flower(112, 372, "#8fe6ff")}${flower(612, 372, "#ff7ac8")}${flower(640, 388, "#ffe08a")}
  ${grass}
  <rect width="${W}" height="${H}" fill="url(#fsVig)"/>
</svg>`;
}

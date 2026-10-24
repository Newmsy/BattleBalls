// Sweet family: a giant glass gumball machine glowing in candy land at dusk,
// full of glossy rainbow gumballs (a few with faint critter faces). Two gumballs
// have rolled out across the floor; a pink critter licks its lips nearby.
import { ball, eye, brow, shade, INK } from "../../brand/parts.mjs";

const SW = "#FF7AC8";
const GUM = ["#ff4f7a", "#ffc93c", "#5fd068", "#3fa9f5", "#b07cff", "#ff8a3d", "#ff7ac8", "#3ee6ff"];

function rng(seed) {
  let s = seed;
  return () => ((s = (s * 16807) % 2147483647) / 2147483647);
}
const f = (n) => n.toFixed(1);

// A glossy gumball; colour index picks a per-colour gradient.
function gum(x, y, r, ci, { face = 0, look = [0, 0] } = {}) {
  const col = GUM[ci];
  let s = `<circle cx="${f(x)}" cy="${f(y)}" r="${f(r)}" fill="url(#gmG${ci})" stroke="${shade(col, -0.55)}" stroke-width="${f(r * 0.07)}"/>
    <ellipse cx="${f(x - r * 0.36)}" cy="${f(y - r * 0.42)}" rx="${f(r * 0.3)}" ry="${f(r * 0.17)}" fill="#fff" opacity="0.75" transform="rotate(-35 ${f(x - r * 0.36)} ${f(y - r * 0.42)})"/>
    <circle cx="${f(x + r * 0.42)}" cy="${f(y + r * 0.38)}" r="${f(r * 0.1)}" fill="#fff" opacity="0.35"/>`;
  if (face) {
    const o = face;
    const ey = y - r * 0.04;
    s += `<g opacity="${o}">
      <ellipse cx="${f(x - r * 0.3)}" cy="${f(ey)}" rx="${f(r * 0.17)}" ry="${f(r * 0.22)}" fill="#fff"/>
      <ellipse cx="${f(x + r * 0.3)}" cy="${f(ey)}" rx="${f(r * 0.17)}" ry="${f(r * 0.22)}" fill="#fff"/>
      <circle cx="${f(x - r * 0.3 + look[0] * r * 0.07)}" cy="${f(ey + look[1] * r * 0.08)}" r="${f(r * 0.1)}" fill="${INK}"/>
      <circle cx="${f(x + r * 0.3 + look[0] * r * 0.07)}" cy="${f(ey + look[1] * r * 0.08)}" r="${f(r * 0.1)}" fill="${INK}"/>
      <path d="M ${f(x - r * 0.2)} ${f(y + r * 0.32)} Q ${f(x)} ${f(y + r * 0.52)} ${f(x + r * 0.2)} ${f(y + r * 0.32)}" fill="none" stroke="${INK}" stroke-width="${f(r * 0.08)}" stroke-linecap="round"/>
    </g>`;
  }
  return s;
}

// Lollipop tree silhouette with a faint swirl.
function lolly(x, y, r, h, col) {
  return `<rect x="${x - 3}" y="${y}" width="6" height="${h}" fill="${col}"/>
    <circle cx="${x}" cy="${y}" r="${r}" fill="${col}"/>
    <path d="M ${x} ${y} m 0 -${r * 0.2} a ${r * 0.2} ${r * 0.2} 0 1 1 -${r * 0.2} ${r * 0.2} a ${r * 0.4} ${r * 0.4} 0 1 1 ${r * 0.4} ${r * 0.1} a ${r * 0.6} ${r * 0.6} 0 1 1 -${r * 0.62} -${r * 0.3}"
      fill="none" stroke="${shade(col, 0.18)}" stroke-width="${r * 0.12}" stroke-linecap="round"/>`;
}

export default function () {
  const R = rng(97);
  const mx = 360, gy = 178, gr = 104; // globe

  // Stars in the upper dusk sky.
  let stars = "";
  for (let k = 0; k < 60; k++) {
    const x = R() * 720, y = R() * 140, s = R();
    stars += `<circle cx="${f(x)}" cy="${f(y)}" r="${f(0.5 + s * 1.3)}" fill="#ffe6f6" opacity="${(0.2 + s * 0.6).toFixed(2)}"/>`;
  }

  // Gumballs packed in the globe (hex grid, jitter), lower ~80%.
  const gR = 14.5;
  const packed = [];
  for (let row = 0; row < 12; row++) {
    const y = gy + gr - gR * 0.9 - row * gR * 1.72;
    if (y < gy - gr * 0.42) break;
    for (let col = -8; col <= 8; col++) {
      const x = mx + col * gR * 2.02 + (row % 2) * gR;
      const dx = x - mx, dy = y - gy;
      if (Math.hypot(dx, dy) > gr - gR * 0.55) continue;
      packed.push([x + (R() - 0.5) * 3, y + (R() - 0.5) * 3, gR * (0.92 + R() * 0.14), Math.floor(R() * GUM.length)]);
    }
  }
  // Mound the top: drop the topmost row's outer balls so the surface curves.
  const topY = Math.min(...packed.map((p) => p[1]));
  const kept = packed.filter((p) => !(p[1] < topY + 2 && Math.abs(p[0] - mx) > 60));
  const faces = new Set([5, 17, 30, 44]);
  let inside = "";
  kept.sort((a, b) => a[1] - b[1]).forEach((p, i) => {
    inside += gum(p[0], p[1], p[2], p[3], faces.has(i) ? { face: 0.62, look: [i % 2 ? 0.8 : -0.6, -0.2] } : {});
  });

  // Floor checker in perspective.
  let checker = "";
  const hor = 268, vp = 360;
  for (let r = 0; r < 9; r++) {
    const t0 = r / 9, t1 = (r + 1) / 9;
    const y0 = hor + (440 - hor) * t0 * t0, y1 = hor + (440 - hor) * t1 * t1;
    for (let c = -12; c < 12; c++) {
      if ((r + c) % 2 === 0) continue;
      const xs = (y, cc) => vp + (cc * 60) * ((y - hor + 8) / (440 - hor + 8)) * 2.2;
      checker += `<path d="M ${f(xs(y0, c))} ${f(y0)} L ${f(xs(y0, c + 1))} ${f(y0)} L ${f(xs(y1, c + 1))} ${f(y1)} L ${f(xs(y1, c))} ${f(y1)} Z" fill="#ff7ac8" opacity="0.13"/>`;
    }
  }

  // Sprinkles on the floor.
  let sprinkles = "";
  const sprCol = ["#ff7ac8", "#ffc93c", "#5fd068", "#3fa9f5", "#b07cff", "#fff"];
  for (let k = 0; k < 46; k++) {
    const x = 20 + R() * 680, y = 300 + R() * 135;
    if (Math.abs(x - mx) < 120 && y < 400) continue;
    const a = R() * 180, l = 5 + R() * 5 * ((y - 280) / 160 + 0.4);
    sprinkles += `<rect x="${f(x)}" y="${f(y)}" width="${f(l)}" height="2.6" rx="1.3" fill="${sprCol[k % sprCol.length]}" opacity="0.8" transform="rotate(${f(a)} ${f(x)} ${f(y)})"/>`;
  }
  // Sparkle motes.
  let motes = "";
  for (let k = 0; k < 20; k++) {
    const x = 60 + R() * 600, y = 30 + R() * 260;
    motes += `<circle cx="${f(x)}" cy="${f(y)}" r="${f(0.8 + R() * 2)}" fill="#ffd6f0" opacity="${(0.3 + R() * 0.5).toFixed(2)}"/>`;
  }
  const twinkle = (x, y, s, col = "#fff", o = 1) =>
    `<path d="M ${x} ${y - s} Q ${x} ${y} ${x + s} ${y} Q ${x} ${y} ${x} ${y + s} Q ${x} ${y} ${x - s} ${y} Q ${x} ${y} ${x} ${y - s} Z" fill="${col}" opacity="${o}"/>`;

  // Machine body (base) geometry.
  const bTop = 286, bBot = 398, bwT = 70, bwB = 112;
  const body = `
    <path d="M ${mx - bwT} ${bTop} L ${mx + bwT} ${bTop} Q ${mx + bwT + 6} ${bTop + 4} ${mx + bwT + 10} ${bTop + 20} L ${mx + bwB} ${bBot - 14} Q ${mx + bwB + 2} ${bBot} ${mx + bwB - 14} ${bBot} L ${mx - bwB + 14} ${bBot} Q ${mx - bwB - 2} ${bBot} ${mx - bwB} ${bBot - 14} L ${mx - bwT - 10} ${bTop + 20} Q ${mx - bwT - 6} ${bTop + 4} ${mx - bwT} ${bTop} Z"
      fill="url(#gmBody)" stroke="#5a1440" stroke-width="3"/>
    <path d="M ${mx - bwT - 4} ${bTop + 14} L ${mx - bwB + 4} ${bBot - 16}" stroke="#ffd0ec" stroke-width="5" stroke-linecap="round" opacity="0.6"/>
    <path d="M ${mx + bwT + 8} ${bTop + 20} L ${mx + bwB - 2} ${bBot - 16}" stroke="#ffb0de" stroke-width="3" stroke-linecap="round" opacity="0.45"/>
    <path d="M ${mx - 76} ${bBot - 40} c -10 -10 -22 2 -12 14 l 12 12 l 12 -12 c 10 -12 -2 -24 -12 -14 Z" fill="#ffd0ec" opacity="0.85" stroke="#8a1a5a" stroke-width="2"/>
    <path d="M ${mx + 76} ${bBot - 40} c -10 -10 -22 2 -12 14 l 12 12 l 12 -12 c 10 -12 -2 -24 -12 -14 Z" fill="#ffd0ec" opacity="0.6" stroke="#8a1a5a" stroke-width="2"/>
    ${[[-62, 302], [62, 302], [-90, 372], [90, 372]].map(([d, y]) => `<circle cx="${mx + d}" cy="${y}" r="3.2" fill="url(#gmChrome)" stroke="#5a1440" stroke-width="1"/>`).join("")}
    <!-- foot plinth -->
    <rect x="${mx - bwB - 12}" y="${bBot - 6}" width="${(bwB + 12) * 2}" height="18" rx="9" fill="url(#gmChrome)" stroke="#3a1840" stroke-width="2.5"/>
    <!-- coin/crank plate -->
    <circle cx="${mx}" cy="${bTop + 38}" r="31" fill="url(#gmChrome)" stroke="#3a1840" stroke-width="2.5"/>
    <circle cx="${mx}" cy="${bTop + 38}" r="24" fill="none" stroke="#fff" stroke-width="1.5" opacity="0.5"/>
    <rect x="${mx - 3.5}" y="${bTop + 22}" width="7" height="18" rx="3.5" fill="#2a0f2e"/>
    <rect x="${mx - 1.2}" y="${bTop + 24}" width="2.4" height="12" rx="1.2" fill="${SW}" opacity="0.7"/>
    <!-- crank handle -->
    <circle cx="${mx}" cy="${bTop + 50}" r="7" fill="#d8d0e8" stroke="#3a1840" stroke-width="2"/>
    <path d="M ${mx} ${bTop + 50} L ${mx + 30} ${bTop + 60}" stroke="#3a1840" stroke-width="9" stroke-linecap="round"/>
    <path d="M ${mx} ${bTop + 50} L ${mx + 30} ${bTop + 60}" stroke="url(#gmChromeH)" stroke-width="5.5" stroke-linecap="round"/>
    <circle cx="${mx + 32}" cy="${bTop + 61}" r="8" fill="url(#gmKnob)" stroke="#5a1440" stroke-width="2"/>
    <!-- dispensing chute -->
    <path d="M ${mx - 30} ${bBot - 8} L ${mx - 30} ${bBot - 30} Q ${mx - 30} ${bBot - 50} ${mx} ${bBot - 50} Q ${mx + 30} ${bBot - 50} ${mx + 30} ${bBot - 30} L ${mx + 30} ${bBot - 8} Z" fill="url(#gmChrome)" stroke="#3a1840" stroke-width="2.5"/>
    <path d="M ${mx - 21} ${bBot - 10} L ${mx - 21} ${bBot - 30} Q ${mx - 21} ${bBot - 41} ${mx} ${bBot - 41} Q ${mx + 21} ${bBot - 41} ${mx + 21} ${bBot - 30} L ${mx + 21} ${bBot - 10} Z" fill="#1a0820"/>
    ${gum(mx - 2, bBot - 22, 13, 1)}
    <path d="M ${mx - 24} ${bBot - 42} Q ${mx} ${bBot - 54} ${mx + 24} ${bBot - 42} L ${mx + 22} ${bBot - 36} Q ${mx} ${bBot - 46} ${mx - 22} ${bBot - 36} Z" fill="#fff" opacity="0.35"/>`;

  // Collar between globe and body.
  const collar = `
    <path d="M ${mx - 84} ${gy + gr - 22} L ${mx + 84} ${gy + gr - 22} L ${mx + 78} ${bTop + 2} L ${mx - 78} ${bTop + 2} Z" fill="url(#gmBody)" stroke="#5a1440" stroke-width="3"/>
    <rect x="${mx - 92}" y="${gy + gr - 30}" width="184" height="16" rx="8" fill="url(#gmChrome)" stroke="#3a1840" stroke-width="2.5"/>
    ${[-60, -30, 0, 30, 60].map((d) => `<circle cx="${mx + d}" cy="${gy + gr - 22}" r="3" fill="#fff" opacity="0.8"/>`).join("")}`;

  // Cap on top of the globe with a knob.
  const capY = gy - gr + 6;
  const cap = `
    <path d="M ${mx - 62} ${capY + 10} Q ${mx - 58} ${capY - 28} ${mx} ${capY - 32} Q ${mx + 58} ${capY - 28} ${mx + 62} ${capY + 10} Z" fill="url(#gmBody)" stroke="#5a1440" stroke-width="3"/>
    <path d="M ${mx - 44} ${capY - 10} Q ${mx - 30} ${capY - 24} ${mx - 6} ${capY - 26}" stroke="#ffd8f0" stroke-width="5" fill="none" stroke-linecap="round" opacity="0.7"/>
    <rect x="${mx - 70}" y="${capY + 2}" width="140" height="14" rx="7" fill="url(#gmChrome)" stroke="#3a1840" stroke-width="2.5"/>
    <rect x="${mx - 8}" y="${capY - 42}" width="16" height="12" rx="3" fill="url(#gmChromeH)" stroke="#3a1840" stroke-width="2"/>
    <circle cx="${mx}" cy="${capY - 50}" r="15" fill="${SW}" opacity="0.6" filter="url(#gmGlowS)"/>
    <circle cx="${mx}" cy="${capY - 50}" r="13" fill="url(#gmKnob)" stroke="#5a1440" stroke-width="2.5"/>
    <ellipse cx="${mx - 4}" cy="${capY - 55}" rx="5" ry="3" fill="#fff" opacity="0.7" transform="rotate(-30 ${mx - 4} ${capY - 55})"/>`;

  // The sweet critter, licking its lips, eyes on the gumball at its feet.
  const cx = 588, cy = 338, cr = 54;
  const ey = cy - cr * 0.14;
  const critter = `
    <ellipse cx="${cx + 4}" cy="${cy + cr - 2}" rx="${cr * 1.1}" ry="12" fill="#000" opacity="0.45" filter="url(#gmBlurS)"/>
    ${ball(cx, cy, cr, SW, { glow: true })}
    <!-- rim light from the machine -->
    <path d="M ${cx - cr * 0.95} ${cy + cr * 0.25} A ${cr} ${cr} 0 0 1 ${cx - cr * 0.35} ${cy - cr * 0.93}" fill="none" stroke="#ffe0f4" stroke-width="3.5" opacity="0.8" stroke-linecap="round"/>
    <!-- swirl tuft -->
    <path d="M ${cx + 4} ${cy - cr + 3} q -6 -22 12 -26 q 14 0 10 12 q -4 8 -10 2" fill="none" stroke="${shade(SW, -0.45)}" stroke-width="6" stroke-linecap="round"/>
    <path d="M ${cx + 4} ${cy - cr + 3} q -6 -22 12 -26 q 14 0 10 12 q -4 8 -10 2" fill="none" stroke="${shade(SW, 0.35)}" stroke-width="3" stroke-linecap="round"/>
    ${eye(cx - cr * 0.33, ey, cr * 0.22, cr * 0.28, -0.8, 0.55, cr * 0.13)}
    ${eye(cx + cr * 0.31, ey, cr * 0.22, cr * 0.28, -0.8, 0.55, cr * 0.13)}
    <!-- star sparkles in the eyes (wanting) -->
    ${twinkle(cx - cr * 0.27, ey + cr * 0.06, 3.2, "#fff")}${twinkle(cx + cr * 0.37, ey + cr * 0.06, 3.2, "#fff")}
    <path d="M ${cx - cr * 0.56} ${ey - cr * 0.4} Q ${cx - cr * 0.34} ${ey - cr * 0.62} ${cx - cr * 0.12} ${ey - cr * 0.46}" fill="none" stroke="${INK}" stroke-width="${cr * 0.075}" stroke-linecap="round"/>
    <path d="M ${cx + cr * 0.1} ${ey - cr * 0.46} Q ${cx + cr * 0.32} ${ey - cr * 0.62} ${cx + cr * 0.54} ${ey - cr * 0.4}" fill="none" stroke="${INK}" stroke-width="${cr * 0.075}" stroke-linecap="round"/>
    <!-- open mouth with the tongue sweeping over the top lip -->
    <path d="M ${cx - cr * 0.34} ${cy + cr * 0.28} Q ${cx} ${cy + cr * 0.76} ${cx + cr * 0.34} ${cy + cr * 0.26} Q ${cx} ${cy + cr * 0.36} ${cx - cr * 0.34} ${cy + cr * 0.28} Z" fill="${INK}"/>
    <path d="M ${cx - cr * 0.06} ${cy + cr * 0.52} Q ${cx - cr * 0.2} ${cy + cr * 0.12} ${cx + cr * 0.2} ${cy + cr * 0.12} Q ${cx + cr * 0.48} ${cy + cr * 0.16} ${cx + cr * 0.44} ${cy + cr * 0.34} Q ${cx + cr * 0.3} ${cy + cr * 0.32} ${cx + cr * 0.22} ${cy + cr * 0.44} Q ${cx + cr * 0.1} ${cy + cr * 0.6} ${cx - cr * 0.06} ${cy + cr * 0.52} Z"
      fill="#ff4f86" stroke="${INK}" stroke-width="2.5" stroke-linejoin="round"/>
    <path d="M ${cx + cr * 0.06} ${cy + cr * 0.22} Q ${cx + cr * 0.12} ${cy + cr * 0.36} ${cx + cr * 0.08} ${cy + cr * 0.48}" fill="none" stroke="#c42e62" stroke-width="2" stroke-linecap="round"/>
    <ellipse cx="${cx + cr * 0.24}" cy="${cy + cr * 0.2}" rx="${cr * 0.08}" ry="${cr * 0.04}" fill="#fff" opacity="0.6"/>
    <!-- drool drop -->
    <path d="M ${cx - cr * 0.3} ${cy + cr * 0.36} q 6 10 0 16 q -6 -6 0 -16 Z" fill="#cfefff" stroke="#7ab8d8" stroke-width="1"/>
    <ellipse cx="${cx - cr * 0.62}" cy="${cy + cr * 0.12}" rx="${cr * 0.14}" ry="${cr * 0.08}" fill="#ff3f8f" opacity="0.5"/>
    <ellipse cx="${cx + cr * 0.66}" cy="${cy + cr * 0.1}" rx="${cr * 0.14}" ry="${cr * 0.08}" fill="#ff3f8f" opacity="0.5"/>`;

  // Rolled-out gumballs on the floor: one rolling toward the critter, one left.
  const rolled = `
    <ellipse cx="486" cy="404" rx="20" ry="5" fill="#000" opacity="0.45"/>
    ${[0, 1, 2].map((k) => `<path d="M ${446 - k * 12} ${388 + k * 6} l -${18 - k * 4} 0" stroke="#ffc6ea" stroke-width="3" stroke-linecap="round" opacity="${0.6 - k * 0.15}"/>`).join("")}
    <circle cx="486" cy="388" r="26" fill="#3ee6ff" opacity="0.3" filter="url(#gmGlowM)"/>
    ${gum(486, 388, 17, 7, { face: 0.85, look: [0.9, -0.1] })}
    <ellipse cx="216" cy="414" rx="22" ry="5" fill="#000" opacity="0.45"/>
    <circle cx="214" cy="398" r="28" fill="#5fd068" opacity="0.3" filter="url(#gmGlowM)"/>
    ${gum(214, 398, 18, 2)}
    <ellipse cx="548" cy="414" rx="15" ry="4" fill="#000" opacity="0.45"/>
    <circle cx="546" cy="404" r="20" fill="#ffd23f" opacity="0.3" filter="url(#gmGlowM)"/>
    <ellipse cx="546" cy="405" rx="14" ry="7" fill="#c98a14" stroke="#6b4a1c" stroke-width="1.5"/>
    <ellipse cx="546" cy="402" rx="14" ry="7" fill="#ffd23f" stroke="#8a5a14" stroke-width="1.5"/>
    <ellipse cx="546" cy="402" rx="9" ry="4.2" fill="none" stroke="#fff1b0" stroke-width="1.5" opacity="0.8"/>
    ${twinkle(556, 396, 6, "#fff6c8")}
    <ellipse cx="128" cy="380" rx="11" ry="3" fill="#000" opacity="0.4"/>
    ${gum(128, 372, 10, 4)}`;

  return `<svg xmlns="http://www.w3.org/2000/svg" width="720" height="440" viewBox="0 0 720 440">
  <defs>
    <linearGradient id="gmSky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#0d0f26"/><stop offset="0.35" stop-color="#22184e"/><stop offset="0.52" stop-color="#5a2470"/><stop offset="0.62" stop-color="#b8487e"/><stop offset="0.66" stop-color="#ff9a8a"/>
    </linearGradient>
    <linearGradient id="gmFloor" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#5a2a78"/><stop offset="0.35" stop-color="#2c1650"/><stop offset="1" stop-color="#120c2c"/>
    </linearGradient>
    <radialGradient id="gmHalo" cx="50%" cy="50%" r="50%">
      <stop offset="0" stop-color="${SW}" stop-opacity="0.55"/><stop offset="1" stop-color="${SW}" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="gmSun" cx="50%" cy="50%" r="50%">
      <stop offset="0" stop-color="#ffe0b0"/><stop offset="0.5" stop-color="#ff9ab8"/><stop offset="1" stop-color="#ff7ac8" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="gmGlass" cx="0.5" cy="0.4" r="0.6">
      <stop offset="0" stop-color="#4a2a7a" stop-opacity="0.7"/><stop offset="0.8" stop-color="#2a1650" stop-opacity="0.8"/><stop offset="1" stop-color="#ff9ad8" stop-opacity="0.6"/>
    </radialGradient>
    <radialGradient id="gmGlassFront" cx="0.5" cy="0.5" r="0.5">
      <stop offset="0.7" stop-color="#ffffff" stop-opacity="0"/><stop offset="0.93" stop-color="#ffd6f0" stop-opacity="0.18"/><stop offset="1" stop-color="#ffffff" stop-opacity="0.5"/>
    </radialGradient>
    <linearGradient id="gmBody" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#ff9ad8"/><stop offset="0.25" stop-color="#ff5fb4"/><stop offset="0.7" stop-color="#c8287e"/><stop offset="1" stop-color="#6e1450"/>
    </linearGradient>
    <linearGradient id="gmChrome" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#ffffff"/><stop offset="0.3" stop-color="#e6dcf2"/><stop offset="0.55" stop-color="#8a7aa8"/><stop offset="0.75" stop-color="#d8cce8"/><stop offset="1" stop-color="#5a4a78"/>
    </linearGradient>
    <linearGradient id="gmChromeH" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#6a5a88"/><stop offset="0.4" stop-color="#ffffff"/><stop offset="1" stop-color="#8a7aa8"/>
    </linearGradient>
    <radialGradient id="gmKnob" cx="0.35" cy="0.3" r="0.8">
      <stop offset="0" stop-color="#ffe0f2"/><stop offset="0.5" stop-color="${SW}"/><stop offset="1" stop-color="#a01c64"/>
    </radialGradient>
    ${GUM.map((c, i) => `<radialGradient id="gmG${i}" cx="0.36" cy="0.32" r="0.75"><stop offset="0" stop-color="${shade(c, 0.6)}"/><stop offset="0.45" stop-color="${c}"/><stop offset="1" stop-color="${shade(c, -0.45)}"/></radialGradient>`).join("")}
    <radialGradient id="gmVig" cx="50%" cy="46%" r="72%">
      <stop offset="0.55" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.6"/>
    </radialGradient>
    <filter id="gmGlowS" x="-80%" y="-80%" width="260%" height="260%"><feGaussianBlur stdDeviation="4"/></filter>
    <filter id="gmGlowM" x="-80%" y="-80%" width="260%" height="260%"><feGaussianBlur stdDeviation="9"/></filter>
    <filter id="gmGlowL" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="22"/></filter>
    <filter id="gmBlurS" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="5"/></filter>
    <clipPath id="gmClip"><circle cx="${mx}" cy="${gy}" r="${gr - 3}"/></clipPath>
  </defs>

  <!-- dusk sky -->
  <rect width="720" height="440" fill="url(#gmSky)"/>
  ${stars}
  <circle cx="132" cy="250" r="120" fill="url(#gmSun)" opacity="0.7"/>
  <circle cx="132" cy="262" r="40" fill="#ffd6b0" opacity="0.85"/>
  <!-- cotton candy clouds -->
  <g filter="url(#gmBlurS)" opacity="0.75">
    <ellipse cx="560" cy="118" rx="90" ry="18" fill="#ff9ad0" opacity="0.5"/>
    <ellipse cx="610" cy="106" rx="50" ry="16" fill="#ffb8de" opacity="0.5"/>
    <ellipse cx="200" cy="140" rx="80" ry="14" fill="#c88cff" opacity="0.4"/>
  </g>
  <!-- far gumdrop hills and lollipop trees -->
  <path d="M 0 262 Q 40 216 90 236 Q 140 196 200 232 Q 250 206 290 250 L 290 280 L 0 280 Z" fill="#3a1c5e"/>
  <path d="M 440 250 Q 490 200 545 228 Q 600 192 660 226 Q 700 210 720 222 L 720 280 L 440 280 Z" fill="#3a1c5e"/>
  ${lolly(58, 196, 30, 80, "#4a2470")}${lolly(250, 214, 20, 60, "#4a2470")}${lolly(640, 180, 34, 90, "#4a2470")}${lolly(500, 206, 22, 66, "#4a2470")}
  <!-- candy cane posts -->
  ${[[684, 236], [30, 238]].map(([x, y]) => `<path d="M ${x} 290 L ${x} ${y} q 0 -18 14 -18 q 14 0 14 14" fill="none" stroke="#ffdff0" stroke-width="9" stroke-linecap="round" opacity="0.55"/>
     <path d="M ${x} 290 L ${x} ${y} q 0 -18 14 -18 q 14 0 14 14" fill="none" stroke="#ff4f86" stroke-width="9" stroke-dasharray="7 7" opacity="0.6"/>`).join("")}
  <!-- floor -->
  <rect x="0" y="268" width="720" height="172" fill="url(#gmFloor)"/>
  <g>${checker}</g>
  <rect x="0" y="266" width="720" height="3" fill="#ff9ad0" opacity="0.4"/>

  <!-- halo behind the machine -->
  <ellipse cx="${mx}" cy="${gy + 30}" rx="300" ry="220" fill="url(#gmHalo)"/>
  <!-- floor glow pool -->
  <ellipse cx="${mx}" cy="404" rx="220" ry="34" fill="${SW}" opacity="0.35" filter="url(#gmGlowL)"/>
  <ellipse cx="${mx}" cy="410" rx="150" ry="14" fill="#000" opacity="0.5" filter="url(#gmBlurS)"/>

  ${body}
  ${collar}
  <!-- globe -->
  <circle cx="${mx}" cy="${gy}" r="${gr + 8}" fill="${SW}" opacity="0.35" filter="url(#gmGlowM)"/>
  <circle cx="${mx}" cy="${gy}" r="${gr}" fill="url(#gmGlass)"/>
  <g clip-path="url(#gmClip)">
    ${inside}
    <!-- glass tint over the gumballs, darker at the far edge -->
    <circle cx="${mx}" cy="${gy}" r="${gr}" fill="url(#gmGlassFront)"/>
    <ellipse cx="${mx + 50}" cy="${gy + 30}" rx="90" ry="110" fill="#2a1048" opacity="0.18"/>
  </g>
  <!-- glass sheen -->
  <path d="M ${mx - 86} ${gy - 30} A ${gr - 18} ${gr - 18} 0 0 1 ${mx - 20} ${gy - 92}" fill="none" stroke="#fff" stroke-width="10" stroke-linecap="round" opacity="0.55"/>
  <path d="M ${mx - 94} ${gy + 4} A ${gr - 14} ${gr - 14} 0 0 1 ${mx - 92} ${gy - 16}" fill="none" stroke="#fff" stroke-width="7" stroke-linecap="round" opacity="0.45"/>
  <path d="M ${mx + 66} ${gy + 60} A ${gr - 16} ${gr - 16} 0 0 0 ${mx + 92} ${gy + 14}" fill="none" stroke="#ffd0ee" stroke-width="4" stroke-linecap="round" opacity="0.5"/>
  <circle cx="${mx}" cy="${gy}" r="${gr}" fill="none" stroke="#ffe6f6" stroke-width="2.5" opacity="0.8"/>
  ${cap}
  ${twinkle(mx - 54, gy - 62, 9, "#fff")}
  ${twinkle(mx + 82, gy - 56, 6, "#ffe6f6", 0.8)}

  ${sprinkles}
  ${rolled}
  <g data-layer="critter" data-move="idle 4 0.7 0">${critter}</g>
  ${motes}
  ${twinkle(214, 70, 5, "#ffe6f6", 0.8)}${twinkle(520, 56, 6, "#ffe6f6", 0.7)}
  <!-- foreground gumdrops, out of focus -->
  <g filter="url(#gmBlurS)">
    <path d="M -20 440 Q -20 360 40 356 Q 96 360 96 440 Z" fill="#2c6a48" opacity="0.7"/>
    <path d="M 650 440 Q 650 378 700 374 Q 744 378 744 440 Z" fill="#4e3088" opacity="0.7"/>
  </g>
  <rect width="720" height="440" fill="url(#gmVig)"/>
</svg>`;
}

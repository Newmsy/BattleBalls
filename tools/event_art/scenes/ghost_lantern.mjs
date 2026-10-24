// Spooky family: a misty graveyard at night. An old iron lantern drifts over
// crooked gravestones, a cold ghost flame with a little face inside it. A small
// critter peeks out from behind a stone, nervous. It wants something warm.
import { ball, eye, shade, INK } from "../../brand/parts.mjs";

const SP = "#B07CFF";
const GH = "#8fffe6"; // ghost-flame cyan-mint

function rng(seed) {
  let s = seed;
  return () => ((s = (s * 16807) % 2147483647) / 2147483647);
}

// A gravestone: rounded or cross-topped slab, tilted, with rim light and moss.
function stone(x, baseY, w, h, { tilt = 0, kind = "round", tone = "#3a2f66", rim = 0.6, crack = false } = {}) {
  let body;
  if (kind === "round") {
    body = `M ${-w / 2} 0 L ${-w / 2} ${-h + w / 2} A ${w / 2} ${w / 2} 0 0 1 ${w / 2} ${-h + w / 2} L ${w / 2} 0 Z`;
  } else if (kind === "cross") {
    const a = w * 0.32, t = h * 0.62;
    body = `M ${-a / 2} 0 L ${-a / 2} ${-t} L ${-w / 2} ${-t} L ${-w / 2} ${-t - a} L ${-a / 2} ${-t - a} L ${-a / 2} ${-h} L ${a / 2} ${-h} L ${a / 2} ${-t - a} L ${w / 2} ${-t - a} L ${w / 2} ${-t} L ${a / 2} ${-t} L ${a / 2} 0 Z`;
  } else {
    // peaked
    body = `M ${-w / 2} 0 L ${-w / 2} ${-h * 0.8} Q ${-w / 4} ${-h * 0.86} 0 ${-h} Q ${w / 4} ${-h * 0.86} ${w / 2} ${-h * 0.8} L ${w / 2} 0 Z`;
  }
  const crackP = crack
    ? `<path d="M ${w * 0.1} ${-h * 0.9} l ${-w * 0.12} ${h * 0.18} l ${w * 0.1} ${h * 0.12} l ${-w * 0.08} ${h * 0.16}" fill="none" stroke="#120d26" stroke-width="2" stroke-linecap="round"/>`
    : "";
  return `<g transform="translate(${x} ${baseY}) rotate(${tilt})">
    <path d="${body}" fill="${tone}" stroke="#120d26" stroke-width="2.5" stroke-linejoin="round"/>
    <path d="${body}" fill="url(#glStoneSh)"/>
    ${kind !== "cross" ? `<path d="M ${-w / 2 + 7} ${-h * 0.18} L ${-w / 2 + 7} ${-h + w / 2} A ${w / 2 - 7} ${w / 2 - 7} 0 0 1 ${w / 2 - 7} ${-h + w / 2} L ${w / 2 - 7} ${-h * 0.18}" fill="none" stroke="#120d26" stroke-width="2" opacity="${kind === "round" ? 0.45 : 0}"/>` : ""}
    <path d="${body}" fill="none" stroke="#d9c8ff" stroke-width="1.5" opacity="${rim * 0.5}"/>
    <path d="${body}" fill="none" stroke="#bffff0" stroke-width="3" opacity="${rim}" clip-path="url(#glRimClip)" transform="translate(-2 1)"/>
    ${crackP}
    <path d="M ${-w / 2} 0 q ${w * 0.2} ${-h * 0.12} ${w * 0.45} ${-h * 0.05} q ${w * 0.3} ${h * 0.02} ${w * 0.55} 0 Z" fill="#2f5a4e" opacity="0.9"/>
  </g>`;
}

export default function () {
  const R = rng(31);
  const lx = 364, ly = 150; // lantern centre (glass)

  // Stars.
  let stars = "";
  for (let k = 0; k < 70; k++) {
    const x = R() * 720, y = R() * 200;
    stars += `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="${(0.5 + R() * 1.3).toFixed(1)}" fill="#e8dcff" opacity="${(0.25 + R() * 0.6).toFixed(2)}"/>`;
  }
  // Mist bands.
  const mistBand = (y0, y1, n, op) => {
    let m = "";
    for (let k = 0; k < n; k++) {
      const x = R() * 760 - 20, y = y0 + R() * (y1 - y0);
      m += `<ellipse cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" rx="${(80 + R() * 130).toFixed(1)}" ry="${(12 + R() * 16).toFixed(1)}" fill="${SP}" opacity="${(op * (0.6 + R() * 0.6)).toFixed(2)}"/>`;
    }
    return m;
  };
  // Spirit sparks drifting from the flame.
  let sparks = "";
  for (let k = 0; k < 26; k++) {
    const a = R() * Math.PI * 2, d = 40 + R() * 220;
    const x = lx + Math.cos(a) * d * 1.4, y = ly - 10 + Math.sin(a) * d * 0.7;
    if (y > 400) continue;
    const c = R() < 0.6 ? GH : "#e3d2ff";
    sparks += `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="${(0.8 + R() * 2.2).toFixed(1)}" fill="${c}" opacity="${(0.35 + R() * 0.55).toFixed(2)}"/>`;
  }
  // Bare dead tree (far left / right silhouettes).
  const tree = (x, y, s, flip) => `<g transform="translate(${x} ${y}) scale(${flip * s} ${s})" fill="none" stroke="#1a1238" stroke-linecap="round">
      <path d="M 0 0 Q 4 -60 -6 -120 Q -10 -150 4 -190" stroke-width="14"/>
      <path d="M -4 -90 Q -40 -110 -62 -150" stroke-width="7"/><path d="M -46 -128 Q -70 -132 -86 -124" stroke-width="4"/>
      <path d="M 0 -130 Q 36 -150 50 -190" stroke-width="6"/><path d="M 34 -160 Q 56 -164 70 -158" stroke-width="3.5"/>
      <path d="M 2 -170 Q -16 -200 -30 -212" stroke-width="4"/><path d="M -60 -150 Q -66 -170 -58 -186" stroke-width="3"/>
    </g>`;
  // Iron fence along the far ridge.
  let fence = "";
  for (let x = -6; x < 740; x += 15) {
    const top = 246 + Math.sin(x * 0.012) * 6;
    fence += `<line x1="${x}" y1="${top}" x2="${x}" y2="${top + 34}"/><path d="M ${x - 3} ${top + 2} L ${x} ${top - 6} L ${x + 3} ${top + 2}" fill="#1c1440"/>`;
  }

  // The lantern: iron cap with a ring, four-post cage, glass with ghost flame.
  const gw = 44, gh = 62; // glass half-width-ish, height
  const top = ly - gh / 2, bot = ly + gh / 2;
  const flame = `
    <ellipse cx="${lx}" cy="${ly + 4}" rx="34" ry="40" fill="${GH}" opacity="0.55" filter="url(#glBlurM)"/>
    <path d="M ${lx} ${ly - 36} C ${lx + 8} ${ly - 22} ${lx + 30} ${ly - 6} ${lx + 24} ${ly + 14} C ${lx + 20} ${ly + 28} ${lx + 8} ${ly + 30} ${lx} ${ly + 30}
             C ${lx - 10} ${ly + 30} ${lx - 22} ${ly + 26} ${lx - 24} ${ly + 12} C ${lx - 28} ${ly - 4} ${lx - 14} ${ly - 12} ${lx - 10} ${ly - 24}
             C ${lx - 6} ${ly - 16} ${lx - 4} ${ly - 14} ${lx - 2} ${ly - 18} C ${lx} ${ly - 24} ${lx - 4} ${ly - 30} ${lx} ${ly - 36} Z" fill="url(#glFlame)"/>
    <path d="M ${lx + 2} ${ly - 14} C ${lx + 12} ${ly - 2} ${lx + 16} ${ly + 8} ${lx + 12} ${ly + 18} C ${lx + 6} ${ly + 26} ${lx - 8} ${ly + 26} ${lx - 13} ${ly + 16} C ${lx - 16} ${ly + 6} ${lx - 6} ${ly - 2} ${lx + 2} ${ly - 14} Z" fill="#f2fffb" opacity="0.92"/>
    <!-- little face in the flame: wistful, looking down at the critter -->
    <ellipse cx="${lx - 6.5}" cy="${ly + 8}" rx="3.4" ry="4.6" fill="#1f3a5a"/>
    <ellipse cx="${lx + 5.5}" cy="${ly + 8}" rx="3.4" ry="4.6" fill="#1f3a5a"/>
    <circle cx="${lx - 7.6}" cy="${ly + 6.4}" r="1.2" fill="#fff"/><circle cx="${lx + 4.4}" cy="${ly + 6.4}" r="1.2" fill="#fff"/>
    <path d="M ${lx - 11} ${ly + 1} q 4 -3 7 -1 M ${lx + 3} ${ly} q 4 -2 7 1" fill="none" stroke="#1f3a5a" stroke-width="1.4" stroke-linecap="round"/>
    <ellipse cx="${lx - 0.5}" cy="${ly + 17.5}" rx="2.6" ry="3.2" fill="#1f3a5a"/>
    <ellipse cx="${lx - 11}" cy="${ly + 14}" rx="2.6" ry="1.4" fill="#9fd8ff" opacity="0.8"/><ellipse cx="${lx + 10}" cy="${ly + 14}" rx="2.6" ry="1.4" fill="#9fd8ff" opacity="0.8"/>`;
  const posts = [-1, 1].map((d) => `
    <path d="M ${lx + d * (gw - 2)} ${top - 2} L ${lx + d * (gw + 4)} ${ly} L ${lx + d * (gw - 2)} ${bot + 2}" fill="none" stroke="url(#glIron)" stroke-width="7" stroke-linejoin="round"/>
    <path d="M ${lx + d * (gw - 2)} ${top - 2} L ${lx + d * (gw + 4)} ${ly} L ${lx + d * (gw - 2)} ${bot + 2}" fill="none" stroke="${GH}" stroke-width="1.5" opacity="0.55"/>`).join("");
  const lantern = `
    <g>
      <!-- ring and hook -->
      <circle cx="${lx}" cy="${top - 44}" r="11" fill="none" stroke="url(#glIron)" stroke-width="5"/>
      <path d="M ${lx - 11} ${top - 44} A 11 11 0 0 1 ${lx + 4} ${top - 54}" fill="none" stroke="#c9b6ff" stroke-width="1.5" opacity="0.6"/>
      <!-- cap -->
      <path d="M ${lx - 8} ${top - 34} L ${lx + 8} ${top - 34} L ${lx + 10} ${top - 26} L ${lx - 10} ${top - 26} Z" fill="url(#glIron)" stroke="#120d26" stroke-width="2"/>
      <path d="M ${lx - 14} ${top - 26} Q ${lx} ${top - 32} ${lx + 14} ${top - 26} L ${lx + gw + 10} ${top - 4} L ${lx - gw - 10} ${top - 4} Z" fill="url(#glIron)" stroke="#120d26" stroke-width="2.5" stroke-linejoin="round"/>
      <path d="M ${lx - gw - 10} ${top - 4} L ${lx + gw + 10} ${top - 4} L ${lx + gw + 6} ${top + 4} L ${lx - gw - 6} ${top + 4} Z" fill="#2a2150" stroke="#120d26" stroke-width="2"/>
      <path d="M ${lx - 12} ${top - 24} L ${lx - gw - 6} ${top - 6}" stroke="#d9c8ff" stroke-width="2" opacity="0.5"/>
      <!-- glass -->
      <path d="M ${lx - gw + 2} ${top + 4} L ${lx + gw - 2} ${top + 4} L ${lx + gw + 2} ${ly} L ${lx + gw - 2} ${bot} L ${lx - gw + 2} ${bot} L ${lx - gw - 2} ${ly} Z" fill="url(#glGlass)"/>
      ${flame}
      <path d="M ${lx - gw + 6} ${top + 10} L ${lx - gw + 16} ${top + 10} L ${lx - gw + 6} ${bot - 12} Z" fill="#fff" opacity="0.18"/>
      <!-- cage bars -->
      <line x1="${lx}" y1="${top + 4}" x2="${lx}" y2="${ly - 38}" stroke="url(#glIron)" stroke-width="3" opacity="0.7"/>
      ${posts}
      <!-- base -->
      <path d="M ${lx - gw - 6} ${bot} L ${lx + gw + 6} ${bot} L ${lx + gw - 4} ${bot + 12} L ${lx - gw + 4} ${bot + 12} Z" fill="url(#glIron)" stroke="#120d26" stroke-width="2.5" stroke-linejoin="round"/>
      <path d="M ${lx - 16} ${bot + 12} L ${lx + 16} ${bot + 12} L ${lx} ${bot + 26} Z" fill="#2a2150" stroke="#120d26" stroke-width="2"/>
      <circle cx="${lx}" cy="${bot + 28}" r="3.5" fill="${GH}"/>
      <!-- cold rim light from the moon -->
      <path d="M ${lx + 14} ${top - 26} L ${lx + gw + 10} ${top - 4}" stroke="#e8f8ff" stroke-width="2" opacity="0.55"/>
    </g>`;
  // Ghostly wispy tail streaming from the lantern bottom, drifting left.
  const tail = `
    <path d="M ${lx - 30} ${bot + 6} C ${lx - 70} ${bot + 30} ${lx - 120} ${bot + 10} ${lx - 170} ${bot + 40} C ${lx - 200} ${bot + 58} ${lx - 230} ${bot + 50} ${lx - 250} ${bot + 64}
             C ${lx - 220} ${bot + 40} ${lx - 190} ${bot + 36} ${lx - 160} ${bot + 20} C ${lx - 120} ${bot - 4} ${lx - 70} ${bot + 8} ${lx - 40} ${bot - 10} Z" fill="${GH}" opacity="0.45" filter="url(#glBlurS)"/>
    <path d="M ${lx - 34} ${bot + 2} C ${lx - 80} ${bot + 22} ${lx - 130} ${bot + 6} ${lx - 180} ${bot + 34}" fill="none" stroke="#d6fff4" stroke-width="2" opacity="0.4" stroke-linecap="round"/>`;

  // The nervous critter peeking from behind a gravestone, lower left.
  const kx = 232, ky = 338, kr = 32, kc = "#FFC93C";
  const critter = `
    <ellipse cx="${kx + 6}" cy="${ky + kr}" rx="${kr * 1.1}" ry="7" fill="#000" opacity="0.4"/>
    ${ball(kx, ky, kr, kc, { glow: false })}
    <!-- cold cyan rim light from the flame -->
    <path d="M ${kx + kr * 0.2} ${ky - kr * 0.98} A ${kr} ${kr} 0 0 1 ${kx + kr * 0.98} ${ky + kr * 0.1}" fill="none" stroke="${GH}" stroke-width="3" opacity="0.75" stroke-linecap="round"/>
    <path d="M ${kx - 4} ${ky - kr + 3} q -6 -16 4 -22 q 0 10 8 18 Z" fill="${shade(kc, 0.3)}" stroke="${shade(kc, -0.5)}" stroke-width="2.5"/>
    ${eye(kx - 2, ky - 6, 8.5, 11, 0.55, -0.75, 4.2)}${eye(kx + 18, ky - 6, 8.5, 11, 0.55, -0.75, 4.2)}
    <path d="M ${kx - 10} ${ky - 21} q 7 -5 13 -2 M ${kx + 13} ${ky - 21} q 7 -3 12 3" fill="none" stroke="${INK}" stroke-width="2.6" stroke-linecap="round"/>
    <path d="M ${kx + 1} ${ky + 12} q 3 -3 6 0 q 3 3 6 0 q 3 -3 6 0" fill="none" stroke="${INK}" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
    <path d="M ${kx - 22} ${ky - 22} q 7 9 0 14 q -7 -5 0 -14 Z" fill="#bfefff"/>
    <!-- shiver lines -->
    <path d="M ${kx - 38} ${ky - 6} q -4 4 0 8 M ${kx - 44} ${ky - 10} q -5 6 0 14" fill="none" stroke="#e8dcff" stroke-width="2" stroke-linecap="round" opacity="0.7"/>`;

  return `<svg xmlns="http://www.w3.org/2000/svg" width="720" height="440" viewBox="0 0 720 440">
  <defs>
    <linearGradient id="glSky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#0b0a22"/><stop offset="0.5" stop-color="#1c1450"/><stop offset="0.8" stop-color="#3a2470"/><stop offset="1" stop-color="#2a1a58"/>
    </linearGradient>
    <radialGradient id="glHalo" cx="50%" cy="50%" r="50%">
      <stop offset="0" stop-color="${GH}" stop-opacity="0.42"/><stop offset="0.45" stop-color="${SP}" stop-opacity="0.22"/><stop offset="1" stop-color="${SP}" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="glMoon" cx="40%" cy="38%" r="60%">
      <stop offset="0" stop-color="#fbf6ff"/><stop offset="0.7" stop-color="#ddd0ff"/><stop offset="1" stop-color="#b9a4f2"/>
    </radialGradient>
    <radialGradient id="glFlame" cx="50%" cy="65%" r="60%">
      <stop offset="0" stop-color="#ffffff"/><stop offset="0.4" stop-color="${GH}"/><stop offset="0.85" stop-color="#7fb8ff"/><stop offset="1" stop-color="${SP}"/>
    </radialGradient>
    <radialGradient id="glGlass" cx="50%" cy="55%" r="60%">
      <stop offset="0" stop-color="#8ff4e4" stop-opacity="0.75"/><stop offset="1" stop-color="#2a4a8a" stop-opacity="0.6"/>
    </radialGradient>
    <linearGradient id="glIron" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#8a7cc0"/><stop offset="0.4" stop-color="#4a3e80"/><stop offset="1" stop-color="#1e1640"/>
    </linearGradient>
    <linearGradient id="glStoneSh" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#000" stop-opacity="0.35"/><stop offset="0.5" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#9fffe8" stop-opacity="0.18"/>
    </linearGradient>
    <linearGradient id="glGround" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#1e1648"/><stop offset="1" stop-color="#08071a"/>
    </linearGradient>
    <radialGradient id="glPool" cx="50%" cy="50%" r="50%">
      <stop offset="0" stop-color="${GH}" stop-opacity="0.35"/><stop offset="1" stop-color="${GH}" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="glVig" cx="50%" cy="44%" r="72%">
      <stop offset="0.55" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.65"/>
    </radialGradient>
    <clipPath id="glRimClip"><path d="M -6 -400 L 200 -400 L 200 -10 Z"/></clipPath>
    <filter id="glBlurS" x="-40%" y="-40%" width="180%" height="180%"><feGaussianBlur stdDeviation="4"/></filter>
    <filter id="glBlurM" x="-80%" y="-80%" width="260%" height="260%"><feGaussianBlur stdDeviation="10"/></filter>
    <filter id="glBlurL" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="22"/></filter>
    <filter id="glMist" x="-30%" y="-100%" width="160%" height="300%"><feGaussianBlur stdDeviation="14"/></filter>
  </defs>

  <rect width="720" height="440" fill="url(#glSky)"/>
  ${stars}
  <!-- moon low right, with a ring of haze -->
  <circle cx="574" cy="92" r="70" fill="#d9c8ff" opacity="0.18" filter="url(#glBlurL)"/>
  <circle cx="574" cy="92" r="40" fill="url(#glMoon)"/>
  <circle cx="562" cy="84" r="7" fill="#c4b2f0" opacity="0.6"/><circle cx="586" cy="104" r="5" fill="#c4b2f0" opacity="0.5"/><circle cx="580" cy="78" r="3.5" fill="#c4b2f0" opacity="0.5"/>
  <!-- wisp of cloud across the moon -->
  <path d="M 500 104 Q 540 92 580 106 Q 620 96 660 110 Q 610 118 560 114 Q 530 116 500 104 Z" fill="#2a1e5e" opacity="0.8"/>

  <!-- far hills with a tiny chapel silhouette -->
  <path d="M 0 236 Q 90 196 190 214 Q 280 228 340 206 Q 430 180 520 210 Q 610 232 720 200 L 720 300 L 0 300 Z" fill="#1e1648"/>
  <path d="M 96 208 L 96 176 L 110 160 L 124 176 L 124 206 Z M 106 160 L 110 146 L 114 160 Z" fill="#1e1648"/>
  <rect x="106" y="182" width="7" height="10" rx="3" fill="#ffcf70" opacity="0.7"/>
  <g filter="url(#glMist)">${mistBand(220, 250, 7, 0.28)}</g>
  <g stroke="#1c1440" stroke-width="3">${fence}</g>
  ${tree(70, 290, 1.0, 1)}
  ${tree(664, 286, 0.9, -1)}

  <!-- halo behind the lantern -->
  <ellipse cx="${lx}" cy="${ly + 10}" rx="270" ry="210" fill="url(#glHalo)"/>

  <!-- ground -->
  <path d="M 0 290 Q 180 272 360 282 Q 540 290 720 276 L 720 440 L 0 440 Z" fill="url(#glGround)"/>
  <ellipse cx="${lx}" cy="352" rx="210" ry="40" fill="url(#glPool)"/>

  <!-- back row of stones -->
  ${stone(152, 298, 34, 52, { tilt: -6, kind: "peaked", tone: "#2c2358", rim: 0.25 })}
  ${stone(258, 292, 30, 46, { tilt: 5, kind: "round", tone: "#2c2358", rim: 0.3 })}
  ${stone(478, 294, 34, 58, { tilt: -4, kind: "cross", tone: "#2c2358", rim: 0.3 })}
  ${stone(570, 300, 30, 44, { tilt: 8, kind: "round", tone: "#2c2358", rim: 0.25 })}
  <g filter="url(#glMist)">${mistBand(285, 320, 7, 0.17)}</g>

  <!-- mid row: the stones under the lantern -->
  ${stone(298, 352, 54, 84, { tilt: -9, kind: "round", tone: "#3e3274", rim: 0.7, crack: true })}
  ${stone(436, 356, 60, 96, { tilt: 7, kind: "cross", tone: "#3e3274", rim: 0.7 })}
  ${stone(536, 362, 52, 70, { tilt: -12, kind: "peaked", tone: "#3a2f6c", rim: 0.55 })}
  <!-- mounds of earth -->
  <ellipse cx="300" cy="356" rx="48" ry="9" fill="#1a1338"/><ellipse cx="440" cy="360" rx="52" ry="9" fill="#1a1338"/>

  ${tail}
  <!-- glow pool cast on the stones -->
  <ellipse cx="${lx}" cy="${ly + 20}" rx="120" ry="110" fill="${GH}" opacity="0.12" filter="url(#glBlurL)"/>
  <ellipse cx="${lx}" cy="${ly + 4}" rx="70" ry="80" fill="${GH}" opacity="0.35" filter="url(#glBlurL)"/>
  <g transform="translate(${lx} ${ly}) scale(1.32) translate(${-lx} ${-ly})">${lantern}</g>
  ${sparks}

  <!-- the nervous critter, half hidden behind a foreground stone -->
  ${critter}
  ${stone(176, 414, 90, 108, { tilt: 4, kind: "round", tone: "#33295e", rim: 0.75 })}

  <!-- foreground stone bottom right, framing -->
  ${stone(650, 448, 96, 120, { tilt: -10, kind: "cross", tone: "#1e1640", rim: 0.4 })}
  <!-- grass tufts -->
  ${[[60, 430], [250, 420], [380, 428], [520, 424], [700, 432]].map(([x, y]) => `<path d="M ${x - 10} ${y} q 4 -14 2 -22 q 4 10 4 22 q 2 -16 8 -20 q -2 10 0 20 q 4 -10 10 -12 q -6 8 -4 12 Z" fill="#15102e"/>`).join("")}
  <g filter="url(#glMist)">${mistBand(385, 440, 9, 0.2)}</g>
  <ellipse cx="200" cy="430" rx="200" ry="22" fill="${SP}" opacity="0.2" filter="url(#glMist)"/>
  <ellipse cx="540" cy="420" rx="220" ry="22" fill="${SP}" opacity="0.18" filter="url(#glMist)"/>

  <rect width="720" height="440" fill="url(#glVig)"/>
</svg>`;
}

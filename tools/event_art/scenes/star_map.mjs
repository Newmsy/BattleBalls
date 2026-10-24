// Star map: a Cosmic-family night sky where a constellation forms a route of
// nodes and lines (a map path with a fork, ending in a big goal star), seen
// from a stone observatory ledge where a Cosmic critter peers through an old
// brass telescope.
import { ball, eye, shade } from "../../brand/parts.mjs";

const W = 720, H = 440;
const COSMIC = "#C9A6FF";

const twinkle = (x, y, s, col = "#fff", o = 1) =>
  `<path d="M ${x} ${y - s} Q ${x} ${y} ${x + s} ${y} Q ${x} ${y} ${x} ${y + s} Q ${x} ${y} ${x - s} ${y} Q ${x} ${y} ${x} ${y - s} Z" fill="${col}" opacity="${o}"/>`;

// Route node: glowing star in a ring.
function node(x, y, r, col, kind = "ring") {
  const core =
    kind === "diamond"
      ? `<path d="M ${x} ${y - r * 0.7} L ${x + r * 0.55} ${y} L ${x} ${y + r * 0.7} L ${x - r * 0.55} ${y} Z" fill="#fff"/>`
      : kind === "dot"
        ? `<circle cx="${x}" cy="${y}" r="${r * 0.42}" fill="#fff"/>`
        : twinkle(x, y, r * 0.8, "#fff");
  return `
  <circle cx="${x}" cy="${y}" r="${r * 2.2}" fill="${col}" opacity="0.45" filter="url(#smBlur8)"/>
  <circle cx="${x}" cy="${y}" r="${r}" fill="#1b1450" stroke="${col}" stroke-width="${r * 0.22}"/>
  <circle cx="${x}" cy="${y}" r="${r * 1.35}" fill="none" stroke="${col}" stroke-width="1.5" opacity="0.55"/>
  ${core}`;
}

// The goal: a big eight-point star with a halo and rays.
function goal(x, y, r) {
  let pts = "";
  for (let k = 0; k < 16; k++) {
    const a = -Math.PI / 2 + (k * Math.PI) / 8;
    const rr = k % 2 ? r * 0.38 : k % 4 ? r * 0.7 : r;
    pts += `${x + Math.cos(a) * rr},${y + Math.sin(a) * rr} `;
  }
  return `
  <circle cx="${x}" cy="${y}" r="${r * 2.6}" fill="${COSMIC}" opacity="0.35" filter="url(#smBlur24)"/>
  <circle cx="${x}" cy="${y}" r="${r * 1.2}" fill="#fff4d6" opacity="0.5" filter="url(#smBlur8)"/>
  <circle cx="${x}" cy="${y}" r="${r * 1.55}" fill="none" stroke="#ffe08a" stroke-width="2" stroke-dasharray="4 6" opacity="0.8"/>
  <polygon points="${pts}" fill="url(#smGoal)" stroke="#fff6d8" stroke-width="2" stroke-linejoin="round"/>
  <circle cx="${x}" cy="${y}" r="${r * 0.22}" fill="#fff"/>`;
}

// Glowing constellation link.
const link = (a, b, col = "#e3d4ff") => `
  <line x1="${a[0]}" y1="${a[1]}" x2="${b[0]}" y2="${b[1]}" stroke="${COSMIC}" stroke-width="7" opacity="0.35" filter="url(#smBlur3)"/>
  <line x1="${a[0]}" y1="${a[1]}" x2="${b[0]}" y2="${b[1]}" stroke="${col}" stroke-width="2.4" stroke-dasharray="7 6" stroke-linecap="round"/>`;

export default function () {
  let seed = 23;
  const rnd = () => ((seed = (seed * 16807) % 2147483647) / 2147483647);
  let stars = "";
  for (let k = 0; k < 150; k++) {
    const x = rnd() * W, y = rnd() * 360, s = rnd();
    const col = s > 0.85 ? "#ffe9c4" : s > 0.7 ? "#cfe0ff" : "#ece6ff";
    stars += `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="${(0.5 + s * s * 1.8).toFixed(2)}" fill="${col}" opacity="${(0.25 + s * 0.65).toFixed(2)}"/>`;
  }

  // Faint background constellations for texture.
  const faint = [
    [[60, 210], [96, 180], [130, 196], [150, 160]],
    [[620, 300], [660, 270], [690, 290]],
    [[230, 60], [262, 44], [300, 66]],
  ]
    .map((pts) =>
      pts.map((p, i) => (i ? `<line x1="${pts[i - 1][0]}" y1="${pts[i - 1][1]}" x2="${p[0]}" y2="${p[1]}" stroke="#9f8ce0" stroke-width="1.2" opacity="0.35"/>` : "")).join("") +
      pts.map((p) => `<circle cx="${p[0]}" cy="${p[1]}" r="2.2" fill="#e0d6ff" opacity="0.7"/>`).join(""),
    )
    .join("");

  // The route: start -> fork -> rejoin -> goal.
  const N = {
    a: [330, 222], b: [384, 160], c1: [440, 96], c2: [470, 198], d: [540, 140], g: [626, 86],
  };
  const route = `
    ${link(N.a, N.b)}${link(N.b, N.c1)}${link(N.b, N.c2)}${link(N.c1, N.d)}${link(N.c2, N.d)}${link(N.d, N.g, "#ffe9a8")}
    ${node(...N.a, 11, "#7fe6ff", "dot")}
    ${node(...N.b, 12, COSMIC, "ring")}
    ${node(...N.c1, 11, "#ff9ad8", "diamond")}
    ${node(...N.c2, 11, "#5CFF9A", "ring")}
    ${node(...N.d, 12, COSMIC, "diamond")}
    ${goal(...N.g, 30)}`;

  // Telescope: pivot on a tripod, tube aimed up-right at the first node.
  const px = 214, py = 308;
  const ang = Math.atan2(N.a[1] - py, N.a[0] - px);
  const deg = (ang * 180) / Math.PI;
  const tube = `
  <g>
    <!-- tripod -->
    <path d="M ${px} ${py} L ${px - 50} ${py + 112} M ${px} ${py} L ${px + 46} ${py + 112} M ${px} ${py} L ${px + 8} ${py + 118}" stroke="#4a2d1a" stroke-width="9" stroke-linecap="round"/>
    <path d="M ${px} ${py} L ${px - 50} ${py + 112} M ${px} ${py} L ${px + 46} ${py + 112} M ${px} ${py} L ${px + 8} ${py + 118}" stroke="#8a5a34" stroke-width="4.5" stroke-linecap="round"/>
    <g transform="rotate(${deg} ${px} ${py})">
      <!-- tapered brass tube: back end (eyepiece) at -60, lens at +92 -->
      <path d="M ${px - 58} ${py - 9} L ${px + 92} ${py - 17} L ${px + 92} ${py + 17} L ${px - 58} ${py + 9} Z" fill="url(#smBrass)" stroke="#5a3a10" stroke-width="2.5" stroke-linejoin="round"/>
      <rect x="${px + 84}" y="${py - 21}" width="20" height="42" rx="5" fill="url(#smBrass)" stroke="#5a3a10" stroke-width="2.5"/>
      <rect x="${px + 2}" y="${py - 15}" width="10" height="30" rx="3" fill="#c48a2a" stroke="#5a3a10" stroke-width="2"/>
      <rect x="${px - 40}" y="${py - 12}" width="8" height="24" rx="3" fill="#c48a2a" stroke="#5a3a10" stroke-width="2"/>
      <rect x="${px - 76}" y="${py - 6}" width="20" height="12" rx="3" fill="#7a4e1c" stroke="#3a2408" stroke-width="2"/>
      <path d="M ${px - 50} ${py - 6} L ${px + 86} ${py - 13}" stroke="#fff3c0" stroke-width="3" opacity="0.6" stroke-linecap="round"/>
      <ellipse cx="${px + 104}" cy="${py}" rx="5" ry="17" fill="#9fe8ff" stroke="#5a3a10" stroke-width="2"/>
      <ellipse cx="${px + 105}" cy="${py - 5}" rx="2" ry="6" fill="#fff" opacity="0.8"/>
    </g>
    <circle cx="${px}" cy="${py}" r="8" fill="#c48a2a" stroke="#3a2408" stroke-width="2.5"/>
  </g>`;
  // Faint sight beam from lens to the first node.
  const lx = px + Math.cos(ang) * 108, ly = py + Math.sin(ang) * 108;
  const beam = `<path d="M ${lx} ${ly - 10} L ${N.a[0]} ${N.a[1]} L ${lx + 8} ${ly + 8} Z" fill="#7fe6ff" opacity="0.22" filter="url(#smBlur3)"/>`;

  // Cosmic critter squinting into the eyepiece.
  const ex = px + Math.cos(ang) * -76, ey = py + Math.sin(ang) * -76;
  const kr = 46, kx = ex - 22, ky = ey + 12;
  let speck = "";
  for (const [a, b, s] of [[-0.5, 0.35, 3], [0.1, 0.62, 2.5], [0.55, 0.4, 2], [-0.2, -0.75, 2], [0.62, -0.1, 2.5]]) {
    speck += `<circle cx="${kx + a * kr}" cy="${ky + b * kr}" r="${s}" fill="#fff" opacity="0.75"/>`;
  }
  const critter = `
    ${ball(kx, ky, kr, COSMIC, { glow: true })}
    ${speck}
    <!-- one eye squeezed shut, the other pressed to the eyepiece -->
    <path d="M ${kx - kr * 0.5} ${ky - kr * 0.22} Q ${kx - kr * 0.32} ${ky - kr * 0.36} ${kx - kr * 0.14} ${ky - kr * 0.22}" fill="none" stroke="#14102e" stroke-width="${kr * 0.1}" stroke-linecap="round"/>
    ${eye(kx + kr * 0.4, ky - kr * 0.22, kr * 0.22, kr * 0.27, 0.9, -0.5, kr * 0.12)}
    <path d="M ${kx - kr * 0.22} ${ky + kr * 0.28} Q ${kx + kr * 0.05} ${ky + kr * 0.5} ${kx + kr * 0.3} ${ky + kr * 0.26}" fill="none" stroke="#14102e" stroke-width="${kr * 0.09}" stroke-linecap="round"/>
    <ellipse cx="${kx - kr * 0.55}" cy="${ky + kr * 0.15}" rx="${kr * 0.13}" ry="${kr * 0.08}" fill="#ff8ad0" opacity="0.55"/>
    <!-- tiny orbiting moon -->
    <ellipse cx="${kx}" cy="${ky - kr * 0.95}" rx="${kr * 0.85}" ry="${kr * 0.2}" fill="none" stroke="#ffe08a" stroke-width="2" opacity="0.7" transform="rotate(-12 ${kx} ${ky - kr * 0.95})"/>
    <circle cx="${kx + kr * 0.78}" cy="${ky - kr * 1.08}" r="${kr * 0.11}" fill="#ffe08a"/>`;

  // Stone ledge: top surface + bricked front.
  const ledgeTop = 372;
  let bricks = "";
  const rows = [ledgeTop + 14, ledgeTop + 40];
  rows.forEach((y, i) => {
    for (let x = -40 + (i % 2) * 34; x < W + 40; x += 68) {
      bricks += `<rect x="${x + 2}" y="${y + 2}" width="64" height="23" rx="5" fill="#2a2458" stroke="#120f30" stroke-width="2"/>
        <rect x="${x + 6}" y="${y + 4}" width="56" height="4" rx="2" fill="#4a4294" opacity="0.6"/>`;
    }
  });

  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">
  <defs>
    <linearGradient id="smSky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#0D0F26"/><stop offset="0.5" stop-color="#141038"/><stop offset="1" stop-color="#2c2170"/>
    </linearGradient>
    <radialGradient id="smGoal" cx="0.4" cy="0.35" r="0.7">
      <stop offset="0" stop-color="#ffffff"/><stop offset="0.45" stop-color="#ffe9a8"/><stop offset="1" stop-color="#ffbf3a"/>
    </radialGradient>
    <linearGradient id="smBrass" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#ffe2a0"/><stop offset="0.4" stop-color="#d9a441"/><stop offset="1" stop-color="#7a4e1c"/>
    </linearGradient>
    <radialGradient id="smPlanet" cx="0.35" cy="0.3" r="0.8">
      <stop offset="0" stop-color="#ffd6f0"/><stop offset="0.5" stop-color="#d47ac0"/><stop offset="1" stop-color="#5a2a7a"/>
    </radialGradient>
    <linearGradient id="smLedge" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#5a5296"/><stop offset="1" stop-color="#2e2860"/>
    </linearGradient>
    <linearGradient id="smFade" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#0D0F26" stop-opacity="0"/><stop offset="1" stop-color="#0D0F26" stop-opacity="0.6"/>
    </linearGradient>
    <filter id="smBlur3" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="3"/></filter>
    <filter id="smBlur8" x="-80%" y="-80%" width="260%" height="260%"><feGaussianBlur stdDeviation="8"/></filter>
    <filter id="smBlur24" x="-80%" y="-80%" width="260%" height="260%"><feGaussianBlur stdDeviation="24"/></filter>
    <filter id="smBlur40" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="40"/></filter>
  </defs>

  <rect width="${W}" height="${H}" fill="url(#smSky)"/>
  <!-- nebula clouds -->
  <ellipse cx="500" cy="150" rx="230" ry="90" fill="#7b5cff" opacity="0.35" filter="url(#smBlur40)" transform="rotate(-22 500 150)"/>
  <ellipse cx="560" cy="110" rx="130" ry="50" fill="#ff8ad0" opacity="0.22" filter="url(#smBlur40)" transform="rotate(-22 560 110)"/>
  <ellipse cx="400" cy="210" rx="140" ry="50" fill="#3ee6ff" opacity="0.14" filter="url(#smBlur40)" transform="rotate(-22 400 210)"/>
  ${stars}
  ${faint}
  <!-- ringed planet -->
  <circle cx="110" cy="92" r="58" fill="#d47ac0" opacity="0.2" filter="url(#smBlur24)"/>
  <ellipse cx="110" cy="92" rx="66" ry="14" fill="none" stroke="#ffd6a8" stroke-width="5" opacity="0.5" transform="rotate(-18 110 92)"/>
  <circle cx="110" cy="92" r="36" fill="url(#smPlanet)"/>
  <path d="M 76 82 Q 110 76 144 88" fill="none" stroke="#ffd6f0" stroke-width="4" opacity="0.35"/>
  <path d="M 78 102 Q 110 96 142 106" fill="none" stroke="#5a2a7a" stroke-width="4" opacity="0.35"/>
  <path d="M 44 110 A 66 14 -18 0 0 176 70" fill="none" stroke="#ffe2c0" stroke-width="5" opacity="0.85" transform="rotate(0)"/>
  <!-- shooting star -->
  <line x1="300" y1="40" x2="370" y2="62" stroke="#fff" stroke-width="2.5" stroke-linecap="round" opacity="0.8"/>
  <line x1="250" y1="26" x2="300" y2="40" stroke="#c9a6ff" stroke-width="1.5" stroke-linecap="round" opacity="0.4"/>

  <!-- the route constellation -->
  ${route}
  ${beam}

  <!-- distant observatory dome silhouette -->
  <path d="M 560 372 L 560 318 Q 600 270 640 318 L 640 372 Z" fill="#1a1546"/>
  <path d="M 594 284 L 616 278 L 622 300 L 600 306 Z" fill="#0e0b28"/>
  <rect x="586" y="330" width="14" height="20" rx="7" fill="#ffcf6b" opacity="0.85"/>
  <circle cx="593" cy="340" r="20" fill="#ffcf6b" opacity="0.25" filter="url(#smBlur8)"/>
  <path d="M 520 372 L 520 344 L 680 344 L 680 372 Z" fill="#1a1546"/>
  <path d="M 520 344 L 530 334 L 540 344 L 550 334 L 560 344 M 640 344 L 650 334 L 660 344 L 670 334 L 680 344" fill="#1a1546"/>

  <!-- stone ledge -->
  <path d="M -10 ${ledgeTop} Q 360 ${ledgeTop - 14} 730 ${ledgeTop} L 730 ${ledgeTop + 16} Q 360 ${ledgeTop + 2} -10 ${ledgeTop + 16} Z" fill="url(#smLedge)" stroke="#120f30" stroke-width="2"/>
  <path d="M -10 ${ledgeTop + 1} Q 360 ${ledgeTop - 13} 730 ${ledgeTop + 1}" fill="none" stroke="#a89cf0" stroke-width="2" opacity="0.6"/>
  <rect x="-10" y="${ledgeTop + 14}" width="${W + 20}" height="${H - ledgeTop}" fill="#1c1844"/>
  ${bricks}
  <rect x="0" y="${ledgeTop}" width="${W}" height="${H - ledgeTop}" fill="url(#smFade)"/>

  <!-- telescope + critter -->
  <ellipse cx="${kx + 40}" cy="${ky + 20}" rx="120" ry="70" fill="${COSMIC}" opacity="0.18" filter="url(#smBlur24)"/>
  ${tube}
  <g data-layer="critter" data-move="idle 3 0.5 0">${critter}</g>

  <!-- star chart scroll + candle on the ledge -->
  <g transform="rotate(-6 440 362)">
    <rect x="392" y="352" width="96" height="16" rx="8" fill="#e9dcc0" stroke="#7a5a30" stroke-width="2"/>
    <circle cx="392" cy="360" r="9" fill="#d8c49a" stroke="#7a5a30" stroke-width="2"/><circle cx="392" cy="360" r="3.5" fill="#7a5a30"/>
    <line x1="412" y1="356" x2="470" y2="356" stroke="#7a5ab0" stroke-width="1.5" stroke-dasharray="3 3"/>
    <circle cx="430" cy="356" r="2.4" fill="#7a5ab0"/><circle cx="456" cy="356" r="2.4" fill="#7a5ab0"/>
  </g>
  <circle cx="500" cy="340" r="26" fill="#ffcf6b" opacity="0.3" filter="url(#smBlur8)"/>
  <rect x="494" y="342" width="12" height="26" rx="3" fill="#efe3c8" stroke="#7a5a30" stroke-width="1.5"/>
  <path d="M 500 342 Q 494 334 500 324 Q 506 334 500 342 Z" fill="#ffcf6b"/>
  <path d="M 500 340 Q 497 335 500 330 Q 503 335 500 340 Z" fill="#fff6d8"/>
  ${twinkle(690, 60, 7, "#fff", 0.8)}${twinkle(40, 280, 6, "#e3d4ff", 0.7)}
</svg>`;
}

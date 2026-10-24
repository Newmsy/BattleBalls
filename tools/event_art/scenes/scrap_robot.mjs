// Tech family: a junkyard scrap heap at night. A broken, cute ball-shaped robot
// slumps in the heap; one eye blinks on (cyan). Cables, gears, a dangling plug.
// A curious critter pokes it with a stick.
import { ball, eye, shade, INK } from "../../brand/parts.mjs";

const TE = "#9AA8C7";
const CY = "#3EE6FF";

function rng(seed) {
  let s = seed;
  return () => ((s = (s * 16807) % 2147483647) / 2147483647);
}

// A gear: toothed ring with a hub hole.
function gear(cx, cy, r, teeth, col, rot = 0, op = 1) {
  let d = "";
  for (let k = 0; k < teeth * 2; k++) {
    const a0 = rot + (k * Math.PI) / teeth, a1 = rot + ((k + 1) * Math.PI) / teeth;
    const rr = k % 2 ? r * 0.82 : r;
    d += `${k ? "L" : "M"} ${(cx + Math.cos(a0) * rr).toFixed(1)} ${(cy + Math.sin(a0) * rr).toFixed(1)} L ${(cx + Math.cos(a1) * rr).toFixed(1)} ${(cy + Math.sin(a1) * rr).toFixed(1)} `;
  }
  return `<g opacity="${op}"><path d="${d}Z" fill="${col}" stroke="#0e0c22" stroke-width="2" stroke-linejoin="round"/>
    <circle cx="${cx}" cy="${cy}" r="${r * 0.5}" fill="none" stroke="${shade(col, 0.3)}" stroke-width="${r * 0.08}" opacity="0.6"/>
    <circle cx="${cx}" cy="${cy}" r="${r * 0.22}" fill="#0e0c22"/></g>`;
}

export default function () {
  const R = rng(59);
  const rx = 384, ry = 214, rr = 80; // robot centre and radius

  // Stars.
  let stars = "";
  for (let k = 0; k < 50; k++) {
    stars += `<circle cx="${(R() * 720).toFixed(1)}" cy="${(R() * 170).toFixed(1)}" r="${(0.5 + R() * 1.2).toFixed(1)}" fill="#dfe8ff" opacity="${(0.25 + R() * 0.55).toFixed(2)}"/>`;
  }
  // Chain-link fence (diamond mesh) on the far left and right.
  let mesh = "";
  for (let x = -20; x < 740; x += 18) mesh += `<line x1="${x}" y1="150" x2="${x + 90}" y2="250"/><line x1="${x + 90}" y1="150" x2="${x}" y2="250"/>`;
  // Scrap junk pieces for the heap: plates, pipes, tyres, gears, springs.
  const plate = (x, y, w, h, rot, col) => `<g transform="rotate(${rot} ${x} ${y})">
      <rect x="${x - w / 2}" y="${y - h / 2}" width="${w}" height="${h}" rx="3" fill="${col}" stroke="#0e0c22" stroke-width="2"/>
      <rect x="${x - w / 2}" y="${y - h / 2}" width="${w}" height="${h * 0.22}" fill="#fff" opacity="0.12"/>
      <circle cx="${x - w / 2 + 6}" cy="${y - h / 2 + 6}" r="2" fill="#0e0c22" opacity="0.6"/><circle cx="${x + w / 2 - 6}" cy="${y - h / 2 + 6}" r="2" fill="#0e0c22" opacity="0.6"/></g>`;
  const pipe = (x1, y1, x2, y2, w, col) => `
      <line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" stroke="#0e0c22" stroke-width="${w + 4}" stroke-linecap="round"/>
      <line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" stroke="${col}" stroke-width="${w}" stroke-linecap="round"/>
      <line x1="${x1}" y1="${y1 - w * 0.25}" x2="${x2}" y2="${y2 - w * 0.25}" stroke="#fff" stroke-width="${w * 0.2}" stroke-linecap="round" opacity="0.25"/>
      <ellipse cx="${x2}" cy="${y2}" rx="${w * 0.3}" ry="${w * 0.5}" fill="#0e0c22"/>`;
  const tyre = (x, y, r, rot) => `<g transform="rotate(${rot} ${x} ${y})">
      <ellipse cx="${x}" cy="${y}" rx="${r}" ry="${r * 0.45}" fill="#14122a" stroke="#0a0818" stroke-width="2"/>
      <ellipse cx="${x}" cy="${y}" rx="${r * 0.55}" ry="${r * 0.22}" fill="#06050f"/>
      <path d="M ${x - r} ${y} A ${r} ${r * 0.45} 0 0 1 ${x + r * 0.4} ${y - r * 0.42}" fill="none" stroke="${TE}" stroke-width="2" opacity="0.4"/></g>`;

  // Back heap (silhouettes) and mid heap.
  let backJunk = "";
  for (let k = 0; k < 16; k++) {
    const x = R() * 720, y = 230 + R() * 40;
    backJunk += `<rect x="${x.toFixed(1)}" y="${y.toFixed(1)}" width="${(20 + R() * 50).toFixed(1)}" height="${(8 + R() * 18).toFixed(1)}" fill="#1a1a3c" transform="rotate(${(R() * 50 - 25).toFixed(1)} ${x.toFixed(1)} ${y.toFixed(1)})"/>`;
  }

  // Sparks / fireflies of light (cyan specks from the robot).
  let specks = "";
  for (let k = 0; k < 26; k++) {
    const x = 120 + R() * 500, y = 50 + R() * 300;
    specks += `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="${(0.8 + R() * 2).toFixed(1)}" fill="${R() < 0.7 ? CY : "#ffd96b"}" opacity="${(0.3 + R() * 0.5).toFixed(2)}"/>`;
  }

  // The robot: a dented metal ball, slumped (tilted), face screen with one eye on.
  const tilt = 14;
  const robot = `
    <g transform="rotate(${tilt} ${rx} ${ry})">
      <!-- antenna, bent -->
      <path d="M ${rx + 10} ${ry - rr + 4} L ${rx + 14} ${ry - rr - 26} L ${rx + 38} ${ry - rr - 40}" fill="none" stroke="#0e0c22" stroke-width="8" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="M ${rx + 10} ${ry - rr + 4} L ${rx + 14} ${ry - rr - 26} L ${rx + 38} ${ry - rr - 40}" fill="none" stroke="${TE}" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
      <circle cx="${rx + 40}" cy="${ry - rr - 42}" r="7" fill="#5a6488" stroke="#0e0c22" stroke-width="2"/>
      <!-- ear bolts -->
      <rect x="${rx - rr - 12}" y="${ry - 16}" width="20" height="32" rx="6" fill="url(#srMetalD)" stroke="#0e0c22" stroke-width="2.5"/>
      <rect x="${rx + rr - 8}" y="${ry - 16}" width="20" height="32" rx="6" fill="url(#srMetalD)" stroke="#0e0c22" stroke-width="2.5"/>
      ${ball(rx, ry, rr, TE, { glow: false })}
      <!-- panel seams and rivets -->
      <path d="M ${rx - rr} ${ry + 20} Q ${rx} ${ry + 44} ${rx + rr} ${ry + 20}" fill="none" stroke="#3a4262" stroke-width="3"/>
      <path d="M ${rx - rr * 0.5} ${ry - rr * 0.86} Q ${rx - rr * 0.72} ${ry} ${rx - rr * 0.48} ${ry + rr * 0.88}" fill="none" stroke="#3a4262" stroke-width="2" opacity="0.6"/>
      ${[[-0.7, 0.42], [-0.35, 0.5], [0, 0.53], [0.35, 0.5], [0.7, 0.42]].map(([a, b]) => `<circle cx="${rx + a * rr}" cy="${ry + b * rr}" r="3" fill="#4a5478" stroke="#d6defa" stroke-width="0.8"/>`).join("")}
      <!-- dent with scratches -->
      <path d="M ${rx + rr * 0.38} ${ry + rr * 0.62} q 10 -8 22 -2 q -4 10 -18 10 Z" fill="#5a6488" opacity="0.8"/>
      <path d="M ${rx - rr * 0.8} ${ry - rr * 0.1} l 14 6 M ${rx - rr * 0.76} ${ry - rr * 0.02} l 10 4" stroke="#d6defa" stroke-width="1.4" opacity="0.6"/>
      <!-- rust streak -->
      <path d="M ${rx - rr * 0.2} ${ry + rr * 0.56} q 4 14 -2 30" fill="none" stroke="#a0603a" stroke-width="5" opacity="0.5" stroke-linecap="round"/>
      <!-- face screen -->
      <rect x="${rx - rr * 0.68}" y="${ry - rr * 0.5}" width="${rr * 1.36}" height="${rr * 0.78}" rx="${rr * 0.3}" fill="#0b0d22" stroke="#2a3050" stroke-width="5"/>
      <rect x="${rx - rr * 0.68}" y="${ry - rr * 0.5}" width="${rr * 1.36}" height="${rr * 0.78}" rx="${rr * 0.3}" fill="url(#srScreen)"/>
      <!-- dead left eye: cracked, dark -->
      <rect x="${rx - rr * 0.48}" y="${ry - rr * 0.2}" width="${rr * 0.32}" height="${rr * 0.08}" rx="3" fill="#2a3256"/>
      <!-- right eye blinking on -->
      <ellipse cx="${rx + rr * 0.3}" cy="${ry - rr * 0.12}" rx="${rr * 0.3}" ry="${rr * 0.3}" fill="${CY}" opacity="0.55" filter="url(#srBlurM)"/>
      <ellipse cx="${rx + rr * 0.3}" cy="${ry - rr * 0.12}" rx="${rr * 0.15}" ry="${rr * 0.18}" fill="${CY}"/>
      <ellipse cx="${rx + rr * 0.3}" cy="${ry - rr * 0.12}" rx="${rr * 0.08}" ry="${rr * 0.1}" fill="#e6fdff"/>
      <circle cx="${rx + rr * 0.26}" cy="${ry - rr * 0.18}" r="${rr * 0.03}" fill="#fff"/>
      <path d="M ${rx + rr * 0.1} ${ry - rr * 0.28} Q ${rx + rr * 0.3} ${ry - rr * 0.34} ${rx + rr * 0.5} ${ry - rr * 0.28} L ${rx + rr * 0.5} ${ry - rr * 0.2} Q ${rx + rr * 0.3} ${ry - rr * 0.14} ${rx + rr * 0.1} ${ry - rr * 0.2} Z" fill="#0b0d22"/>
      <path d="M ${rx + rr * 0.12} ${ry - rr * 0.2} Q ${rx + rr * 0.3} ${ry - rr * 0.14} ${rx + rr * 0.48} ${ry - rr * 0.2}" fill="none" stroke="${CY}" stroke-width="1.5" opacity="0.8"/>
      <!-- boot-up ring -->
      <circle cx="${rx + rr * 0.3}" cy="${ry - rr * 0.12}" r="${rr * 0.26}" fill="none" stroke="${CY}" stroke-width="1.5" opacity="0.5" stroke-dasharray="4 4"/>
      <!-- little wobbly mouth line, half lit -->
      <path d="M ${rx - rr * 0.14} ${ry + rr * 0.14} q ${rr * 0.08} ${rr * 0.06} ${rr * 0.16} 0 q ${rr * 0.08} -${rr * 0.06} ${rr * 0.16} 0" fill="none" stroke="${CY}" stroke-width="3" stroke-linecap="round" opacity="0.7"/>
      <!-- screen crack across the dead eye -->
      <path d="M ${rx - rr * 0.6} ${ry - rr * 0.42} l ${rr * 0.2} ${rr * 0.18} l -${rr * 0.04} ${rr * 0.12} l ${rr * 0.22} ${rr * 0.1} M ${rx - rr * 0.4} ${ry - rr * 0.24} l ${rr * 0.08} -${rr * 0.18}" fill="none" stroke="#c9d6ff" stroke-width="1.6" opacity="0.7"/>
      <!-- screen glare -->
      <path d="M ${rx - rr * 0.56} ${ry - rr * 0.4} L ${rx - rr * 0.3} ${ry - rr * 0.4} L ${rx - rr * 0.5} ${ry + rr * 0.12} L ${rx - rr * 0.6} ${ry + rr * 0.12} Z" fill="#fff" opacity="0.06"/>
      <!-- scanlines on the screen -->
      ${[...Array(9)].map((_, k) => `<rect x="${rx - rr * 0.64}" y="${ry - rr * 0.46 + k * rr * 0.08}" width="${rr * 1.28}" height="1.2" fill="#000" opacity="0.35"/>`).join("")}
      <!-- open hatch with cables spilling out -->
      <path d="M ${rx + rr * 0.3} ${ry + rr * 0.6} L ${rx + rr * 0.7} ${ry + rr * 0.36} L ${rx + rr * 0.84} ${ry + rr * 0.58} L ${rx + rr * 0.48} ${ry + rr * 0.84} Z" fill="#0b0d22"/>
      <path d="M ${rx + rr * 0.7} ${ry + rr * 0.36} L ${rx + rr * 1.02} ${ry + rr * 0.3} L ${rx + rr * 1.12} ${ry + rr * 0.52} L ${rx + rr * 0.84} ${ry + rr * 0.58} Z" fill="url(#srMetalD)" stroke="#0e0c22" stroke-width="2"/>
    </g>`;
  // Cables from the hatch (drawn unrotated, positions picked to match).
  const cables = `
    <path d="M 452 286 C 470 320 440 340 470 360 C 494 376 520 350 536 370" fill="none" stroke="#0e0c22" stroke-width="9" stroke-linecap="round"/>
    <path d="M 452 286 C 470 320 440 340 470 360 C 494 376 520 350 536 370" fill="none" stroke="#ff4fb8" stroke-width="5" stroke-linecap="round"/>
    <path d="M 460 282 C 500 290 510 320 548 318" fill="none" stroke="#0e0c22" stroke-width="8" stroke-linecap="round"/>
    <path d="M 460 282 C 500 290 510 320 548 318" fill="none" stroke="#ffd23f" stroke-width="4" stroke-linecap="round"/>
    <!-- the dangling plug, hanging off the heap edge -->
    <path d="M 446 290 C 452 320 498 314 506 356 L 508 386" fill="none" stroke="#0e0c22" stroke-width="8" stroke-linecap="round"/>
    <path d="M 446 290 C 452 320 498 314 506 356 L 508 386" fill="none" stroke="${CY}" stroke-width="4" stroke-linecap="round"/>
    <rect x="497" y="384" width="22" height="26" rx="5" fill="url(#srMetalD)" stroke="#0e0c22" stroke-width="2.5"/>
    <rect x="501" y="408" width="4" height="12" fill="#d6defa" stroke="#0e0c22" stroke-width="1"/><rect x="511" y="408" width="4" height="12" fill="#d6defa" stroke="#0e0c22" stroke-width="1"/>
    <rect x="500" y="388" width="16" height="4" fill="#fff" opacity="0.25"/>
    <!-- spark at a frayed wire -->
    <path d="M 548 318 l 10 -6 l -4 8 l 12 -2 l -10 8" fill="none" stroke="#fff3a0" stroke-width="2" stroke-linejoin="round"/>
    <circle cx="552" cy="318" r="10" fill="#fff3a0" opacity="0.5" filter="url(#srBlurS)"/>`;

  // The curious critter on the left, poking the robot with a stick.
  const kx = 214, ky = 286, kr = 36, kc = "#FF7AC8";
  const critter = `
    <ellipse cx="${kx + 4}" cy="${ky + kr - 2}" rx="${kr * 1.05}" ry="8" fill="#000" opacity="0.45"/>
    <!-- the stick -->
    <line x1="${kx + 30}" y1="${ky + 18}" x2="${rx - rr * 0.92}" y2="${ry + 22}" stroke="#0e0c22" stroke-width="8" stroke-linecap="round"/>
    <line x1="${kx + 30}" y1="${ky + 18}" x2="${rx - rr * 0.92}" y2="${ry + 22}" stroke="#a87a4e" stroke-width="4.5" stroke-linecap="round"/>
    <path d="M ${kx + 74} ${ky - 4} l 8 -10" stroke="#a87a4e" stroke-width="3" stroke-linecap="round"/>
    ${ball(kx, ky, kr, kc, { glow: false })}
    <!-- cyan rim light from the robot eye -->
    <path d="M ${kx + kr * 0.3} ${ky - kr * 0.95} A ${kr} ${kr} 0 0 1 ${kx + kr * 0.98} ${ky + kr * 0.15}" fill="none" stroke="${CY}" stroke-width="3" opacity="0.7" stroke-linecap="round"/>
    <path d="M ${kx - 8} ${ky - kr + 4} q -2 -18 10 -22 q -4 10 4 20 Z" fill="${shade(kc, 0.35)}" stroke="${shade(kc, -0.5)}" stroke-width="2.5"/>
    ${eye(kx + 2, ky - 8, 9, 12, 0.85, -0.3, 5)}${eye(kx + 24, ky - 8, 9, 12, 0.85, -0.3, 5)}
    <ellipse cx="${kx + 14}" cy="${ky + 13}" rx="4" ry="5" fill="${INK}"/>
    <!-- nub hand holding the stick -->
    <ellipse cx="${kx + 32}" cy="${ky + 18}" rx="7" ry="6" fill="${shade(kc, 0.15)}" stroke="${shade(kc, -0.5)}" stroke-width="2.5"/>
    <!-- poke impact ticks -->
    <path d="M ${rx - rr * 0.98} ${ry + 4} l -8 -8 M ${rx - rr * 1.02} ${ry + 20} l -12 0 M ${rx - rr * 0.98} ${ry + 36} l -8 8" stroke="#e6ecff" stroke-width="2.5" stroke-linecap="round"/>`;

  return `<svg xmlns="http://www.w3.org/2000/svg" width="720" height="440" viewBox="0 0 720 440">
  <defs>
    <linearGradient id="srSky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#0a0b20"/><stop offset="0.6" stop-color="#16193e"/><stop offset="1" stop-color="#232a5a"/>
    </linearGradient>
    <radialGradient id="srHalo" cx="50%" cy="50%" r="50%">
      <stop offset="0" stop-color="${CY}" stop-opacity="0.3"/><stop offset="0.5" stop-color="#6f7cff" stop-opacity="0.12"/><stop offset="1" stop-color="#6f7cff" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="srLamp" cx="50%" cy="0%" r="100%">
      <stop offset="0" stop-color="#ffd96b" stop-opacity="0.32"/><stop offset="1" stop-color="#ffd96b" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="srMetalD" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#c9d2ec"/><stop offset="0.45" stop-color="#7a86a8"/><stop offset="1" stop-color="#3a4262"/>
    </linearGradient>
    <linearGradient id="srHeap" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#2c3060"/><stop offset="1" stop-color="#0c0b20"/>
    </linearGradient>
    <radialGradient id="srScreen" cx="72%" cy="40%" r="70%">
      <stop offset="0" stop-color="${CY}" stop-opacity="0.35"/><stop offset="0.6" stop-color="${CY}" stop-opacity="0.05"/><stop offset="1" stop-color="${CY}" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="srVig" cx="50%" cy="46%" r="72%">
      <stop offset="0.55" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.65"/>
    </radialGradient>
    <filter id="srBlurS" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="3"/></filter>
    <filter id="srBlurM" x="-80%" y="-80%" width="260%" height="260%"><feGaussianBlur stdDeviation="8"/></filter>
    <filter id="srBlurL" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="20"/></filter>
  </defs>

  <rect width="720" height="440" fill="url(#srSky)"/>
  ${stars}
  <!-- distant city glow and crane -->
  <rect x="0" y="180" width="720" height="70" fill="#3a3a8a" opacity="0.25" filter="url(#srBlurL)"/>
  <g fill="#121232">
    <path d="M 560 250 L 572 70 L 584 70 L 596 250 Z"/>
    <path d="M 520 78 L 720 64 L 720 76 L 520 90 Z"/>
    <path d="M 572 70 L 578 40 L 584 70 Z"/>
  </g>
  <g stroke="#121232" stroke-width="2">${[0, 1, 2, 3, 4, 5, 6, 7].map((k) => `<line x1="${572 + (k % 2) * 12}" y1="${80 + k * 22}" x2="${584 - (k % 2) * 12}" y2="${102 + k * 22}"/>`).join("")}</g>
  <line x1="690" y1="68" x2="690" y2="140" stroke="#121232" stroke-width="2"/>
  <path d="M 676 140 L 704 140 L 698 156 L 682 156 Z" fill="#121232"/>
  <circle cx="584" cy="64" r="4" fill="#ff4f6e"/><circle cx="584" cy="64" r="12" fill="#ff4f6e" opacity="0.35" filter="url(#srBlurS)"/>
  <!-- far junk piles -->
  <path d="M 0 256 Q 60 200 130 214 Q 180 178 240 222 L 280 250 L 0 270 Z" fill="#1a1a40"/>
  <path d="M 470 258 Q 540 196 620 222 Q 680 200 720 214 L 720 270 L 470 270 Z" fill="#1a1a40"/>
  <!-- chain-link fence -->
  <g stroke="#3a4270" stroke-width="1.2" opacity="0.35">${mesh}</g>
  <rect x="0" y="146" width="720" height="4" fill="#2a3060" opacity="0.8"/>
  ${[40, 220, 500, 680].map((x) => `<rect x="${x}" y="140" width="6" height="120" fill="#22264e"/>`).join("")}
  <!-- ground -->
  <rect x="0" y="252" width="720" height="188" fill="#12122e"/>
  ${backJunk}

  <!-- hanging work lamp (top left) -->
  <line x1="150" y1="0" x2="150" y2="54" stroke="#0e0c22" stroke-width="2.5"/>
  <path d="M 134 54 L 166 54 L 174 72 L 126 72 Z" fill="#3a4262" stroke="#0e0c22" stroke-width="2"/>
  <ellipse cx="150" cy="74" rx="8" ry="5" fill="#fff4c0"/>
  <path d="M 126 72 L 174 72 L 300 320 L 20 320 Z" fill="url(#srLamp)" filter="url(#srBlurM)"/>
  <circle cx="150" cy="78" r="20" fill="#ffd96b" opacity="0.45" filter="url(#srBlurM)"/>

  <!-- halo behind the robot -->
  <ellipse cx="${rx}" cy="${ry}" rx="260" ry="200" fill="url(#srHalo)"/>

  <!-- the scrap heap -->
  <path d="M 160 340 Q 200 270 270 262 Q 320 230 384 250 Q 460 236 520 268 Q 590 280 620 340 L 640 440 L 140 440 Z" fill="url(#srHeap)"/>
  <path d="M 160 340 Q 200 270 270 262 Q 320 230 384 250 Q 460 236 520 268 Q 590 280 620 340" fill="none" stroke="${CY}" stroke-width="2.5" opacity="0.35"/>
  ${plate(250, 292, 70, 30, -18, "#4a5478")}
  ${plate(540, 300, 80, 34, 22, "#3e4870")}
  ${tyre(300, 330, 44, -10)}
  ${pipe(470, 250, 600, 230, 18, "#6a76a0")}
  ${pipe(220, 260, 300, 236, 12, "#7a5a8a")}
  ${gear(586, 270, 30, 10, "#5a6488", 0.2)}
  ${gear(268, 244, 22, 8, "#4a5478", 0.5)}
  ${plate(430, 360, 110, 40, 6, "#343c66")}
  ${tyre(560, 380, 50, 8)}
  <!-- spring -->
  <path d="M 196 316 ${[...Array(7)].map((_, k) => `q ${k % 2 ? 10 : -10} -5 0 -10`).join(" ")}" fill="none" stroke="#9aa8c7" stroke-width="3"/>

  <!-- robot shadow and the robot -->
  <ellipse cx="${rx + 6}" cy="${ry + rr + 10}" rx="${rr * 1.1}" ry="16" fill="#000" opacity="0.5"/>
  ${robot}
  <!-- junk in front of the robot, half burying it -->
  ${plate(330, 300, 90, 30, 12, "#4a5478")}
  ${gear(436, 302, 26, 9, "#7a86a8", 0.1)}
  ${pipe(300, 326, 360, 352, 14, "#5a6488")}
  ${cables}

  ${critter}

  <!-- foreground junk silhouettes framing the bottom corners -->
  <path d="M 0 380 Q 40 360 90 374 L 120 360 L 150 380 L 160 440 L 0 440 Z" fill="#0a0a1e"/>
  ${gear(70, 412, 40, 12, "#14152e", 0.3)}
  <path d="M 600 440 L 620 396 L 680 380 L 720 392 L 720 440 Z" fill="#0a0a1e"/>
  <path d="M 620 396 L 680 380 L 720 392" fill="none" stroke="${TE}" stroke-width="2" opacity="0.35"/>

  ${specks}
  <rect width="720" height="440" fill="url(#srVig)"/>
</svg>`;
}

// Ember forge: a stone forge roaring in a cave workshop. On the glowing hot
// anvil sits a radiant boon gem, sparks flying; a Fire critter blacksmith in a
// tiny leather apron, goggles pushed up, rests a hammer on its shoulder. Fire family.
import { ball, eye, brow, shade, INK } from "../../brand/parts.mjs";

const W = 720, H = 440;
const FI = "#FF6A3D";

function rng(seed) {
  let s = seed;
  return () => ((s = (s * 16807) % 2147483647) / 2147483647);
}

const twinkle = (x, y, s, col = "#fff", o = 1) =>
  `<path d="M ${x} ${y - s} Q ${x} ${y} ${x + s} ${y} Q ${x} ${y} ${x} ${y + s} Q ${x} ${y} ${x - s} ${y} Q ${x} ${y} ${x} ${y - s} Z" fill="${col}" opacity="${o}"/>`;

// Hanging tool silhouettes on the back wall (lit by the forge on their left edge).
function hammerTool(x, y, s) {
  return `<line x1="${x}" y1="${y - 10}" x2="${x}" y2="${y}" stroke="#1a0e1c" stroke-width="2"/>
    <rect x="${x - 3 * s}" y="${y}" width="${6 * s}" height="${44 * s}" rx="${2 * s}" fill="#3a2230"/>
    <rect x="${x - 13 * s}" y="${y + 40 * s}" width="${26 * s}" height="${13 * s}" rx="${2 * s}" fill="#2e2434"/>
    <rect x="${x - 13 * s}" y="${y + 40 * s}" width="${4 * s}" height="${13 * s}" fill="#ff8a4a" opacity="0.5"/>`;
}
function tongsTool(x, y, s) {
  return `<line x1="${x}" y1="${y - 10}" x2="${x}" y2="${y}" stroke="#1a0e1c" stroke-width="2"/>
    <circle cx="${x}" cy="${y + 2}" r="${4 * s}" fill="none" stroke="#2e2434" stroke-width="${3 * s}"/>
    <path d="M ${x - 2 * s} ${y + 4 * s} L ${x - 7 * s} ${y + 50 * s} L ${x - 3 * s} ${y + 62 * s} M ${x + 2 * s} ${y + 4 * s} L ${x + 7 * s} ${y + 50 * s} L ${x + 3 * s} ${y + 62 * s}" fill="none" stroke="#2e2434" stroke-width="${3.5 * s}" stroke-linecap="round"/>
    <path d="M ${x - 2 * s} ${y + 4 * s} L ${x - 7 * s} ${y + 50 * s}" stroke="#ff8a4a" stroke-width="${1.2 * s}" opacity="0.5"/>`;
}
function horseshoe(x, y, s) {
  return `<line x1="${x}" y1="${y - 10}" x2="${x}" y2="${y}" stroke="#1a0e1c" stroke-width="2"/>
    <path d="M ${x - 12 * s} ${y + 4 * s} Q ${x - 14 * s} ${y + 30 * s} ${x} ${y + 30 * s} Q ${x + 14 * s} ${y + 30 * s} ${x + 12 * s} ${y + 4 * s}" fill="none" stroke="#3a2a3e" stroke-width="${6 * s}" stroke-linecap="round"/>
    <path d="M ${x - 12 * s} ${y + 4 * s} Q ${x - 14 * s} ${y + 30 * s} ${x} ${y + 30 * s}" fill="none" stroke="#ff9a5a" stroke-width="${1.5 * s}" opacity="0.6"/>`;
}

export default function () {
  const R = rng(41);

  // ---- back wall stones (cave masonry) ----
  let stones = "";
  for (let row = 0; row < 8; row++) {
    const y = 20 + row * 34;
    const off = (row % 2) * 30;
    for (let x = -40 + off; x < W + 40; x += 58 + R() * 10) {
      const w = 50 + R() * 10, h = 28 + R() * 4;
      // Light falls off away from the forge (left-centre).
      const d = Math.hypot(x + w / 2 - 170, y + h / 2 - 190);
      const lit = Math.max(0, 1 - d / 420);
      const base = shade("#2a1830", lit * 0.18);
      stones += `<rect x="${x.toFixed(1)}" y="${y.toFixed(1)}" width="${w.toFixed(1)}" height="${h.toFixed(1)}" rx="7" fill="${base}" stroke="#120a18" stroke-width="2"/>`;
      if (lit > 0.15) stones += `<path d="M ${(x + 6).toFixed(1)} ${(y + h - 3).toFixed(1)} L ${(x + w - 6).toFixed(1)} ${(y + h - 3).toFixed(1)}" stroke="#ff8a4a" stroke-width="2" opacity="${(lit * 0.45).toFixed(2)}" stroke-linecap="round"/>`;
    }
  }

  // ---- embers & sparks ----
  let embers = "";
  for (let k = 0; k < 40; k++) {
    const x = 40 + R() * 640, y = 20 + R() * 300;
    const r = 0.9 + R() * 2.2;
    const c = R() < 0.5 ? "#ffd36a" : "#ff8a4a";
    embers += `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="${r.toFixed(1)}" fill="${c}" opacity="${(0.4 + R() * 0.5).toFixed(2)}"/>`;
  }
  // Sparks bursting from the gem on the anvil: curved streaks flying out and arcing down.
  const gx = 354, gy = 242;
  let sparks = "";
  for (let k = 0; k < 30; k++) {
    const a = -Math.PI * (0.06 + R() * 0.88);
    const d0 = 40 + R() * 20, d1 = d0 + 40 + R() * 120;
    const x0 = gx + Math.cos(a) * d0, y0 = gy + Math.sin(a) * d0 * 0.8;
    const x1 = gx + Math.cos(a) * d1, y1 = gy + Math.sin(a) * d1 * 0.8 + (d1 - d0) * 0.25;
    const mx = (x0 + x1) / 2, my = (y0 + y1) / 2 - 18;
    const wdt = 1.2 + R() * 1.8;
    const c = R() < 0.55 ? "#fff1a0" : "#ffb24a";
    sparks += `<path d="M ${x0.toFixed(1)} ${y0.toFixed(1)} Q ${mx.toFixed(1)} ${my.toFixed(1)} ${x1.toFixed(1)} ${y1.toFixed(1)}" fill="none" stroke="${c}" stroke-width="${wdt.toFixed(1)}" stroke-linecap="round" opacity="${(0.55 + R() * 0.45).toFixed(2)}"/>`;
    sparks += `<circle cx="${x1.toFixed(1)}" cy="${y1.toFixed(1)}" r="${(wdt * 1.2).toFixed(1)}" fill="#fff6c8"/>`;
  }
  // Smoke wisps in the chimney / ceiling.
  let smoke = "";
  for (let k = 0; k < 6; k++) {
    const x = 140 + k * 14 + R() * 20, y = 10 + R() * 50;
    smoke += `<ellipse cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" rx="${(24 + R() * 20).toFixed(1)}" ry="${(12 + R() * 8).toFixed(1)}" fill="#3a2440" opacity="0.6"/>`;
  }

  // ---- the forge (left of centre) ----
  const fx = 170, mouthY = 210; // mouth centre
  let flames = "";
  for (let k = 0; k < 9; k++) {
    const x = fx - 58 + k * 14.5 + (R() - 0.5) * 6;
    const h = 40 + R() * 46 - Math.abs(k - 4) * 4;
    const w = 10 + R() * 7;
    flames += `<path d="M ${x - w} ${mouthY + 34} Q ${x - w * 0.6} ${mouthY + 34 - h * 0.6} ${x + (R() - 0.5) * 8} ${mouthY + 34 - h} Q ${x + w * 0.7} ${mouthY + 34 - h * 0.5} ${x + w} ${mouthY + 34} Z" fill="${k % 2 ? "#ff8a3a" : "#ffb24a"}"/>`;
  }
  let inner = "";
  for (let k = 0; k < 6; k++) {
    const x = fx - 40 + k * 16 + (R() - 0.5) * 6;
    const h = 22 + R() * 28;
    inner += `<path d="M ${x - 7} ${mouthY + 34} Q ${x - 4} ${mouthY + 34 - h * 0.6} ${x} ${mouthY + 34 - h} Q ${x + 5} ${mouthY + 34 - h * 0.5} ${x + 7} ${mouthY + 34} Z" fill="#fff1a0"/>`;
  }
  let coals = "";
  for (let k = 0; k < 12; k++) {
    const x = fx - 62 + k * 11.5, y = mouthY + 36 + R() * 6;
    coals += `<ellipse cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" rx="${(7 + R() * 4).toFixed(1)}" ry="${(5 + R() * 2).toFixed(1)}" fill="${R() < 0.5 ? "#4a1a22" : "#6a2420"}" stroke="#ffb24a" stroke-width="1.4"/>`;
  }
  // Brick arch around the forge mouth.
  let arch = "";
  const ar = 84;
  for (let k = 0; k <= 8; k++) {
    const a = Math.PI + (k / 8) * Math.PI;
    const a0 = a - 0.17, a1 = a + 0.17;
    const p = (ang, rr) => `${(fx + Math.cos(ang) * rr).toFixed(1)} ${(mouthY + 40 + Math.sin(ang) * rr).toFixed(1)}`;
    arch += `<path d="M ${p(a0, ar)} L ${p(a1, ar)} L ${p(a1, ar + 24)} L ${p(a0, ar + 24)} Z" fill="${k === 4 ? "#6a4256" : "#4a2e44"}" stroke="#140a18" stroke-width="2" stroke-linejoin="round"/>`;
    arch += `<path d="M ${p(a0, ar + 1)} L ${p(a1, ar + 1)}" stroke="#ffb07a" stroke-width="2.5" opacity="0.75"/>`;
  }

  // ---- anvil (centre) ----
  const ax = 360, at = 282; // face top
  const anvil = `
    <!-- stump -->
    <path d="M 300 352 L 306 398 Q 360 412 414 398 L 420 352 Z" fill="url(#efWood)" stroke="#140a12" stroke-width="2.5"/>
    <ellipse cx="360" cy="352" rx="60" ry="10" fill="#6a3a2a" stroke="#140a12" stroke-width="2.5"/>
    <path d="M 320 366 q 4 14 0 26 M 400 364 q -4 14 0 28 M 360 370 l 0 30" stroke="#2a1418" stroke-width="2" fill="none" opacity="0.7"/>
    <!-- body -->
    <path d="M 316 350 L 326 330 Q 340 322 344 306 L 376 306 Q 380 322 394 330 L 404 350 Z" fill="url(#efIron)" stroke="#120a16" stroke-width="3" stroke-linejoin="round"/>
    <path d="M 316 350 L 326 330 Q 340 322 344 306 L 376 306 Q 380 322 394 330 L 404 350 Z" fill="url(#efHotBody)"/>
    <path d="M 352 310 l -3 12 l 5 8 l -4 12 M 372 316 l 4 10 l -3 10" stroke="#ffd36a" stroke-width="1.8" fill="none" opacity="0.9"/>
    <path d="M 252 290 Q 280 284 300 ${at} L 440 ${at} L 444 ${at + 4} L 444 ${at + 22} Q 420 ${at + 24} 404 ${at + 28} L 316 ${at + 28} Q 300 ${at + 24} 290 ${at + 16} Q 268 ${at + 12} 252 290 Z" fill="url(#efIron)" stroke="#120a16" stroke-width="3" stroke-linejoin="round"/>
    <!-- hot glowing face -->
    <path d="M 256 289 Q 282 283 302 ${at + 1} L 440 ${at + 1} L 442 ${at + 8} L 300 ${at + 8} Q 280 ${at + 9} 256 290 Z" fill="url(#efHotFace)"/>
    <path d="M 290 ${at + 8} L 444 ${at + 8} L 444 ${at + 22} Q 420 ${at + 24} 404 ${at + 28} L 316 ${at + 28} Q 300 ${at + 24} 290 ${at + 16} Z" fill="url(#efHotSide)" opacity="0.85"/>
    <ellipse cx="${ax - 6}" cy="${at + 4}" rx="70" ry="6" fill="#fff4c0" opacity="0.85" filter="url(#efBlur3)"/>
    <path d="M 340 ${at + 8} l -4 10 l 6 6 M 392 ${at + 8} l 3 8 l -5 8" stroke="#fff1a0" stroke-width="1.6" fill="none" opacity="0.8"/>
    <!-- rim light from the forge on the left -->
    <path d="M 252 290 Q 268 ${at + 12} 290 ${at + 16}" stroke="#ffd36a" stroke-width="2" fill="none"/>
    <path d="M 326 330 L 316 350" stroke="#ff9a4a" stroke-width="2.5" opacity="0.8"/>`;

  // ---- the boon gem on the anvil ----
  const gs = 34;
  let rays = "";
  for (let k = 0; k < 14; k++) {
    const a = (k / 14) * Math.PI * 2 + 0.1;
    const l = k % 2 ? 70 : 118;
    const w = k % 2 ? 0.05 : 0.08;
    rays += `<path d="M ${gx} ${gy} L ${(gx + Math.cos(a - w) * l).toFixed(1)} ${(gy + Math.sin(a - w) * l).toFixed(1)} L ${(gx + Math.cos(a + w) * l).toFixed(1)} ${(gy + Math.sin(a + w) * l).toFixed(1)} Z" fill="#fff1a0"/>`;
  }
  const P = (dx, dy) => `${gx + dx * gs} ${gy + dy * gs}`;
  const gem = `
    <circle cx="${gx}" cy="${gy}" r="120" fill="#ff9a3a" opacity="0.35" filter="url(#efBlur40)"/>
    <g opacity="0.32" filter="url(#efBlur3)">${rays}</g>
    <circle cx="${gx}" cy="${gy}" r="58" fill="#ffe08a" opacity="0.55" filter="url(#efBlur12)"/>
    <ellipse cx="${gx}" cy="${at + 2}" rx="34" ry="6" fill="#fff" opacity="0.7" filter="url(#efBlur3)"/>
    <!-- faceted gem: crown + pavilion -->
    <path d="M ${P(-1, -0.25)} L ${P(-0.55, -0.85)} L ${P(0.55, -0.85)} L ${P(1, -0.25)} L ${P(0, 1.1)} Z" fill="url(#efGem)" stroke="#8a2a10" stroke-width="3" stroke-linejoin="round"/>
    <path d="M ${P(-1, -0.25)} L ${P(1, -0.25)}" stroke="#fff1b0" stroke-width="2"/>
    <path d="M ${P(-0.55, -0.85)} L ${P(-0.3, -0.25)} L ${P(0, -0.85)} L ${P(0.3, -0.25)} L ${P(0.55, -0.85)}" fill="none" stroke="#fff1b0" stroke-width="1.6" opacity="0.9"/>
    <path d="M ${P(-0.55, -0.85)} L ${P(-0.3, -0.25)} L ${P(0.3, -0.25)} L ${P(0.55, -0.85)} Z" fill="#fff" opacity="0.28"/>
    <path d="M ${P(-1, -0.25)} L ${P(-0.3, -0.25)} L ${P(0, 1.1)} Z" fill="#fff" opacity="0.22"/>
    <path d="M ${P(0.3, -0.25)} L ${P(1, -0.25)} L ${P(0, 1.1)} Z" fill="#7a1a10" opacity="0.28"/>
    <path d="M ${P(-0.3, -0.25)} L ${P(0, 1.1)} L ${P(0.3, -0.25)}" fill="none" stroke="#ffe6a0" stroke-width="1.4" opacity="0.8"/>
    ${twinkle(gx - gs * 0.5, gy - gs * 0.6, 9, "#fff")}
    ${twinkle(gx + gs * 1.35, gy - gs * 1.15, 14, "#fff6c8")}
    ${twinkle(gx - gs * 1.6, gy - gs * 0.2, 8, "#fff6c8", 0.9)}`;

  // ---- tongs leaning on the anvil + quench bucket ----
  const tongs = `
    <path d="M 264 404 L 300 300 M 278 406 L 304 300" stroke="#1a1020" stroke-width="7" stroke-linecap="round"/>
    <path d="M 264 404 L 300 300 M 278 406 L 304 300" stroke="#4a3a52" stroke-width="3.5" stroke-linecap="round"/>
    <circle cx="302" cy="302" r="5" fill="#2a2030" stroke="#ffb07a" stroke-width="1.5"/>
    <path d="M 300 300 q -6 -12 -2 -20 M 304 300 q 8 -10 6 -20" stroke="#2a2030" stroke-width="5" fill="none" stroke-linecap="round"/>
    <path d="M 300 300 q -6 -12 -2 -20" stroke="#ff9a4a" stroke-width="1.6" fill="none" opacity="0.8"/>`;
  const bucket = `
    <ellipse cx="150" cy="414" rx="52" ry="9" fill="#000" opacity="0.4"/>
    <path d="M 108 352 L 116 410 Q 150 420 184 410 L 192 352 Z" fill="url(#efWood)" stroke="#140a12" stroke-width="2.5"/>
    <path d="M 110 366 Q 150 374 190 366 M 113 394 Q 150 402 187 394" stroke="#2a2030" stroke-width="5" fill="none"/>
    <path d="M 110 366 Q 150 374 190 366" stroke="#ff9a5a" stroke-width="1.5" fill="none" opacity="0.6"/>
    <ellipse cx="150" cy="352" rx="42" ry="9" fill="#1a2a4a" stroke="#140a12" stroke-width="2.5"/>
    <ellipse cx="144" cy="351" rx="22" ry="3.5" fill="#ff9a4a" opacity="0.5"/>
    <g filter="url(#efBlur6)" opacity="0.5">
      <path d="M 130 344 q -10 -20 4 -36 q 12 -14 0 -34" stroke="#e8d8f0" stroke-width="7" fill="none" stroke-linecap="round"/>
      <path d="M 160 344 q 10 -18 -2 -30 q -10 -14 4 -30" stroke="#e8d8f0" stroke-width="5" fill="none" stroke-linecap="round"/>
    </g>`;

  // ---- Fire critter blacksmith (right of centre) ----
  const kx = 528, ky = 312, kr = 54;
  const apronCol = "#8a5640";
  const critter = `
    <ellipse cx="${kx + 6}" cy="${ky + kr + 4}" rx="${kr * 1.05}" ry="10" fill="#000" opacity="0.5"/>
    <!-- hammer handle behind the body, resting on the shoulder -->
    <g transform="rotate(32 ${kx + 46} ${ky - 6})">
      <rect x="${kx + 41}" y="${ky - 82}" width="10" height="104" rx="4" fill="#6a3a24" stroke="#1a0e12" stroke-width="2.5"/>
      <rect x="${kx + 43}" y="${ky - 80}" width="3" height="96" fill="#b0704a" opacity="0.7"/>
      <rect x="${kx + 20}" y="${ky - 104}" width="52" height="28" rx="5" fill="url(#efHammer)" stroke="#120a16" stroke-width="3"/>
      <rect x="${kx + 20}" y="${ky - 104}" width="52" height="7" rx="3" fill="#c8b8e0" opacity="0.6"/><rect x="${kx + 20}" y="${ky - 104}" width="8" height="28" rx="3" fill="#ffb07a" opacity="0.7"/>
    </g>
    ${ball(kx, ky, kr, FI, { glow: true })}
    <!-- flame tuft -->
    <path d="M ${kx - 22} ${ky - kr + 10} Q ${kx - 34} ${ky - kr - 22} ${kx - 14} ${ky - kr - 40} Q ${kx - 12} ${ky - kr - 18} ${kx - 2} ${ky - kr - 14} Q ${kx + 2} ${ky - kr - 40} ${kx + 22} ${ky - kr - 50} Q ${kx + 14} ${ky - kr - 26} ${kx + 26} ${ky - kr - 12} Q ${kx + 36} ${ky - kr - 26} ${kx + 40} ${ky - kr - 30} Q ${kx + 42} ${ky - kr - 4} ${kx + 26} ${ky - kr + 10} Z" fill="url(#efTuft)" stroke="${shade(FI, -0.5)}" stroke-width="2.5" stroke-linejoin="round"/>
    <path d="M ${kx - 6} ${ky - kr + 4} Q ${kx - 10} ${ky - kr - 12} ${kx} ${ky - kr - 22} Q ${kx + 4} ${ky - kr - 10} ${kx + 14} ${ky - kr - 8} Q ${kx + 12} ${ky - kr + 2} ${kx + 8} ${ky - kr + 6} Z" fill="#fff4b0"/>
    <!-- goggles pushed up on the brow -->
    <path d="M ${kx - kr * 0.96} ${ky - kr * 0.42} Q ${kx} ${ky - kr * 0.66} ${kx + kr * 0.96} ${ky - kr * 0.42}" fill="none" stroke="#3a2230" stroke-width="7"/>
    ${[-1, 1].map((s) => `
      <circle cx="${kx + s * 18}" cy="${ky - kr * 0.62}" r="14" fill="#2a2030" stroke="#c98a4a" stroke-width="3.5"/>
      <circle cx="${kx + s * 18}" cy="${ky - kr * 0.62}" r="9.5" fill="url(#efLens)"/>
      <path d="M ${kx + s * 18 - 6} ${ky - kr * 0.62 - 3} q 3 -5 8 -5" stroke="#fff" stroke-width="2.4" fill="none" stroke-linecap="round" opacity="0.9"/>`).join("")}
    <rect x="${kx - 5}" y="${ky - kr * 0.66}" width="10" height="5" rx="2" fill="#c98a4a"/>
    <!-- eyes looking at the gem, determined brows -->
    ${eye(kx - 18, ky - 4, 10, 12, -0.85, -0.3, 6)}${eye(kx + 12, ky - 4, 10, 12, -0.85, -0.3, 6)}
    ${brow(kx - 28, ky - 20, kx - 10, ky - 16, 4.5)}${brow(kx + 4, ky - 16, kx + 22, ky - 21, 4.5)}
    <!-- proud grin -->
    <path d="M ${kx - 20} ${ky + 12} Q ${kx - 6} ${ky + 26} ${kx + 8} ${ky + 13}" fill="${INK}" stroke="${INK}" stroke-width="3" stroke-linejoin="round"/>
    <path d="M ${kx - 17} ${ky + 13} Q ${kx - 6} ${ky + 17} ${kx + 5} ${ky + 14} L ${kx + 4} ${ky + 17} Q ${kx - 6} ${ky + 20} ${kx - 15} ${ky + 16} Z" fill="#fff"/>
    <ellipse cx="${kx - 34}" cy="${ky + 10}" rx="7" ry="4" fill="#ffd0a0" opacity="0.5"/>
    <ellipse cx="${kx + 26}" cy="${ky + 10}" rx="7" ry="4" fill="#ffd0a0" opacity="0.5"/>
    <!-- tiny leather apron -->
    <path d="M ${kx - 26} ${ky + 26} L ${kx + 22} ${ky + 26} Q ${kx + 30} ${ky + 44} ${kx + 26} ${ky + kr - 2} Q ${kx - 2} ${ky + kr + 6} ${kx - 30} ${ky + kr - 2} Q ${kx - 34} ${ky + 44} ${kx - 26} ${ky + 26} Z" fill="url(#efApron)" stroke="${shade(apronCol, -0.6)}" stroke-width="2.5" stroke-linejoin="round"/>
    <path d="M ${kx - 26} ${ky + 26} Q ${kx - 42} ${ky + 16} ${kx - kr + 2} ${ky + 8} M ${kx + 22} ${ky + 26} Q ${kx + 38} ${ky + 16} ${kx + kr - 2} ${ky + 8}" stroke="${shade(apronCol, -0.4)}" stroke-width="3.5" fill="none" stroke-linecap="round"/>
    <rect x="${kx - 12}" y="${ky + 34}" width="18" height="12" rx="2" fill="${shade(apronCol, -0.25)}" stroke="${shade(apronCol, -0.6)}" stroke-width="1.8"/>
    <path d="M ${kx - 12} ${ky + 38} L ${kx + 6} ${ky + 38}" stroke="#d8a070" stroke-width="1.2" stroke-dasharray="2 2"/>
    <!-- stubby paw gripping the hammer -->
    <ellipse cx="${kx + 44}" cy="${ky - 6}" rx="11" ry="10" fill="${shade(FI, 0.1)}" stroke="${shade(FI, -0.5)}" stroke-width="2.5"/>
    <path d="M ${kx + 38} ${ky - 10} q 6 -2 12 0 M ${kx + 38} ${ky - 4} q 6 -2 12 0" stroke="${shade(FI, -0.5)}" stroke-width="1.6" fill="none"/>
    <!-- forge light on its left side -->
    <path d="M ${kx - kr + 4} ${ky - 20} A ${kr - 2} ${kr - 2} 0 0 0 ${kx - 20} ${ky + kr - 6}" fill="none" stroke="#fff1a0" stroke-width="3" opacity="0.6"/>`;

  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">
  <defs>
    <linearGradient id="efWall" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#0D0F26"/><stop offset="0.5" stop-color="#1e1230"/><stop offset="1" stop-color="#3a1a2a"/>
    </linearGradient>
    <linearGradient id="efFloor" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#4a2430"/><stop offset="0.5" stop-color="#2a1424"/><stop offset="1" stop-color="#140a18"/>
    </linearGradient>
    <radialGradient id="efFloorGlow" cx="0.5" cy="0.5" r="0.5">
      <stop offset="0" stop-color="#ff9a3a" stop-opacity="0.55"/><stop offset="1" stop-color="#ff6a3d" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="efMouth" cx="0.5" cy="0.75" r="0.75">
      <stop offset="0" stop-color="#fff3b0"/><stop offset="0.35" stop-color="#ffb24a"/><stop offset="0.75" stop-color="#e2461e"/><stop offset="1" stop-color="#5a1420"/>
    </radialGradient>
    <linearGradient id="efHood" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#2a1830"/><stop offset="0.5" stop-color="#4a2c44"/><stop offset="1" stop-color="#24142a"/>
    </linearGradient>
    <linearGradient id="efIron" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#5a4a6a"/><stop offset="0.5" stop-color="#2e2440"/><stop offset="1" stop-color="#1a1428"/>
    </linearGradient>
    <linearGradient id="efHotFace" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#ff7a2e"/><stop offset="0.45" stop-color="#fff1a0"/><stop offset="0.7" stop-color="#ffd36a"/><stop offset="1" stop-color="#ff6a2e"/>
    </linearGradient>
    <linearGradient id="efHotSide" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#ff7a2e"/><stop offset="0.6" stop-color="#c8341e" stop-opacity="0.6"/><stop offset="1" stop-color="#6a1a24" stop-opacity="0"/>
    </linearGradient>
    <linearGradient id="efWood" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#9a5a3a"/><stop offset="0.5" stop-color="#5a3024"/><stop offset="1" stop-color="#2e1620"/>
    </linearGradient>
    <radialGradient id="efGem" cx="0.4" cy="0.3" r="0.8">
      <stop offset="0" stop-color="#fffbe0"/><stop offset="0.35" stop-color="#ffd36a"/><stop offset="0.7" stop-color="#ff7a2e"/><stop offset="1" stop-color="#c8341e"/>
    </radialGradient>
    <linearGradient id="efHammer" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#8a7aa0"/><stop offset="0.5" stop-color="#4a3e5e"/><stop offset="1" stop-color="#2a2236"/>
    </linearGradient>
    <linearGradient id="efTuft" x1="0" y1="1" x2="0" y2="0">
      <stop offset="0" stop-color="#ff7a2e"/><stop offset="0.6" stop-color="#ffb24a"/><stop offset="1" stop-color="#ffe27a"/>
    </linearGradient>
    <radialGradient id="efLens" cx="0.35" cy="0.3" r="0.8">
      <stop offset="0" stop-color="#ffe7a0"/><stop offset="0.5" stop-color="#ff9a3a"/><stop offset="1" stop-color="#8a2a20"/>
    </radialGradient>
    <linearGradient id="efApron" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#c8865a"/><stop offset="0.6" stop-color="#8a5640"/><stop offset="1" stop-color="#5a3428"/>
    </linearGradient>
    <linearGradient id="efHotBody" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#ff6a2e" stop-opacity="0.85"/><stop offset="0.6" stop-color="#c8341e" stop-opacity="0.35"/><stop offset="1" stop-color="#6a1a24" stop-opacity="0"/>
    </linearGradient>
    <radialGradient id="efVig" cx="50%" cy="50%" r="72%">
      <stop offset="0.6" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.65"/>
    </radialGradient>
    <filter id="efBlur3" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="3"/></filter>
    <filter id="efBlur6" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="6"/></filter>
    <filter id="efBlur12" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="12"/></filter>
    <filter id="efBlur40" x="-80%" y="-80%" width="260%" height="260%"><feGaussianBlur stdDeviation="40"/></filter>
  </defs>

  <!-- back wall -->
  <rect width="${W}" height="${H}" fill="url(#efWall)"/>
  ${stones}
  <rect width="${W}" height="${H}" fill="url(#efWall)" opacity="0.35"/>
  <!-- warm light pooled on the wall around the forge -->
  <ellipse cx="${fx}" cy="210" rx="230" ry="170" fill="#ff6a3d" opacity="0.28" filter="url(#efBlur40)"/>

  <!-- tool rack on the right wall -->
  <rect x="440" y="96" width="250" height="10" rx="4" fill="#4a2a24" stroke="#140a12" stroke-width="2"/>
  <rect x="440" y="96" width="250" height="3" fill="#c87a4a" opacity="0.5"/>
  ${hammerTool(470, 116, 1)}${tongsTool(520, 116, 1)}${horseshoe(572, 116, 1)}${hammerTool(620, 116, 0.8)}${tongsTool(668, 116, 0.85)}
  <!-- shelf with jars and a cooling gem -->
  <rect x="580" y="206" width="140" height="9" rx="3" fill="#4a2a24" stroke="#140a12" stroke-width="2"/>
  <rect x="598" y="178" width="22" height="28" rx="5" fill="#3a2a44" stroke="#140a12" stroke-width="2"/>
  <rect x="630" y="186" width="18" height="20" rx="4" fill="#4a3a2a" stroke="#140a12" stroke-width="2"/>
  <circle cx="676" cy="196" r="10" fill="#6f2a20" stroke="#140a12" stroke-width="2"/>
  <circle cx="673" cy="193" r="3" fill="#ff9a5a" opacity="0.6"/>

  <!-- chimney + forge hood -->
  <path d="M ${fx - 60} -10 L ${fx + 60} -10 L ${fx + 70} 80 L ${fx - 70} 80 Z" fill="url(#efHood)" stroke="#120a16" stroke-width="3"/>
  <g filter="url(#efBlur12)">${smoke}</g>
  <path d="M ${fx - 118} 120 L ${fx - 74} 70 L ${fx + 74} 70 L ${fx + 118} 120 Z" fill="url(#efHood)" stroke="#120a16" stroke-width="3" stroke-linejoin="round"/>
  <path d="M ${fx - 118} 120 L ${fx + 118} 120" stroke="#ffb07a" stroke-width="3" opacity="0.6"/>
  <rect x="${fx - 126}" y="118" width="252" height="12" rx="3" fill="#3a2234" stroke="#120a16" stroke-width="2.5"/>
  <!-- forge body -->
  <path d="M ${fx - 118} 130 L ${fx + 118} 130 L ${fx + 124} 300 L ${fx - 124} 300 Z" fill="#2e1c34" stroke="#120a16" stroke-width="3"/>
  <path d="M ${fx - 118} 130 L ${fx + 118} 130 L ${fx + 124} 300 L ${fx - 124} 300 Z" fill="url(#efWall)" opacity="0.4"/>
  ${arch}
  <!-- the roaring mouth -->
  <path d="M ${fx - ar} ${mouthY + 40} A ${ar} ${ar} 0 0 1 ${fx + ar} ${mouthY + 40} L ${fx + ar} ${mouthY + 52} L ${fx - ar} ${mouthY + 52} Z" fill="url(#efMouth)"/>
  <g filter="url(#efBlur3)">${flames}</g>
  ${flames}
  ${inner}
  ${coals}
  <ellipse cx="${fx}" cy="${mouthY + 10}" rx="${ar * 1.3}" ry="${ar}" fill="#ff8a3a" opacity="0.35" filter="url(#efBlur12)"/>
  <!-- hearth ledge -->
  <rect x="${fx - 132}" y="${mouthY + 50}" width="264" height="18" rx="4" fill="#4a2e44" stroke="#120a16" stroke-width="2.5"/>
  <path d="M ${fx - 128} ${mouthY + 52} L ${fx + 128} ${mouthY + 52}" stroke="#ffd36a" stroke-width="3" opacity="0.85"/>
  <!-- bellows at the forge's side -->
  <path d="M 6 278 L 40 250 Q 70 246 74 270 Q 70 294 40 292 Z" fill="#6a3a2a" stroke="#140a12" stroke-width="2.5"/>
  <path d="M 30 258 l 0 32 M 44 254 l 0 38 M 58 254 l 0 36" stroke="#3a1a18" stroke-width="2" opacity="0.8"/>
  <path d="M 74 270 L 100 266" stroke="#3a2a3e" stroke-width="7" stroke-linecap="round"/>

  <!-- floor -->
  <path d="M 0 296 Q 360 282 720 296 L 720 440 L 0 440 Z" fill="url(#efFloor)"/>
  <path d="M 0 296 Q 360 282 720 296" stroke="#ff9a4a" stroke-width="2" opacity="0.35" fill="none"/>
  ${[[60, 330, 70], [210, 318, 60], [470, 320, 64], [620, 340, 74], [120, 400, 80], [560, 410, 90]].map(([x, y, w]) => `<path d="M ${x - w / 2} ${y} Q ${x} ${y - 7} ${x + w / 2} ${y}" stroke="#140a18" stroke-width="2.5" fill="none" opacity="0.8"/>`).join("")}
  <ellipse cx="300" cy="350" rx="300" ry="70" fill="url(#efFloorGlow)"/>

  ${bucket}
  <ellipse cx="362" cy="400" rx="80" ry="12" fill="#000" opacity="0.45"/>
  <ellipse cx="350" cy="300" rx="130" ry="42" fill="#ff6a2e" opacity="0.6" filter="url(#efBlur12)"/>
  ${anvil}
  ${tongs}
  ${gem}
  <g data-layer="critter" data-move="idle 3 0.6 0">${critter}</g>

  <!-- foreground framing silhouettes -->
  <path d="M 0 0 L 0 120 Q 18 90 14 60 Q 30 40 26 0 Z" fill="#0a0612"/>
  <path d="M 720 0 L 720 150 Q 700 120 706 80 Q 690 50 698 0 Z" fill="#0a0612"/>
  <path d="M 720 440 L 720 380 Q 690 372 668 390 Q 648 404 640 440 Z" fill="#0a0612"/>
  <path d="M 668 390 Q 690 372 720 380" stroke="#ff8a4a" stroke-width="2" opacity="0.4" fill="none"/>
  <path d="M 230 0 L 238 22 L 246 0 Z M 470 0 L 476 30 L 484 0 Z M 520 0 L 524 16 L 530 0 Z" fill="#0a0612"/>

  <g filter="url(#efBlur3)" opacity="0.8">${sparks}</g>
  ${sparks}
  <g>${embers}</g>
  <g filter="url(#efBlur3)" opacity="0.7">${embers}</g>
  <rect width="${W}" height="${H}" fill="url(#efVig)"/>
</svg>`;
}

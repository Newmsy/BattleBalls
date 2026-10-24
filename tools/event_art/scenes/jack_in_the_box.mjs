// Toybox family: a big harlequin jack-in-the-box alone in a toy room at night.
// The lid has crept open; two glowing eyes peek out of the warm gap and the
// crank has turned by itself. Toy blocks and a drum lie around; a small critter
// hides behind the drum.
import { ball, eye, brow, shade, INK } from "../../brand/parts.mjs";

const TB = "#FFC93C";

function rng(seed) {
  let s = seed;
  return () => ((s = (s * 16807) % 2147483647) / 2147483647);
}
const f = (n) => n.toFixed(1);
const twinkle = (x, y, s, col = "#fff", o = 1) =>
  `<path d="M ${x} ${y - s} Q ${x} ${y} ${x + s} ${y} Q ${x} ${y} ${x} ${y + s} Q ${x} ${y} ${x - s} ${y} Q ${x} ${y} ${x} ${y - s} Z" fill="${col}" opacity="${o}"/>`;

// 5-point star path.
function star(x, y, r, rot = 0) {
  let d = "";
  for (let k = 0; k < 10; k++) {
    const a = ((rot + k * 36 - 90) * Math.PI) / 180, rr = k % 2 ? r * 0.45 : r;
    d += `${k ? "L" : "M"} ${f(x + Math.cos(a) * rr)} ${f(y + Math.sin(a) * rr)} `;
  }
  return d + "Z";
}

// Harlequin diamonds on an s x s local square (two colours alternating).
function harlequin(s, n, c1, c2) {
  const w = s / n, h = s / 2;
  let out = `<rect width="${s}" height="${s}" fill="${c2}"/>`;
  for (let row = 0; row < 3; row++) {
    for (let col = 0; col <= n; col++) {
      const x = col * w + (row % 2 ? w / 2 : 0) - w / 2 + w / 2, y = row * h - h / 2 + (row % 2 ? 0 : 0);
      const cx = (row % 2 ? col * w : col * w + w / 2), cy = row * h;
      void x; void y;
      out += `<path d="M ${f(cx)} ${f(cy - h / 2)} L ${f(cx + w / 2)} ${f(cy)} L ${f(cx)} ${f(cy + h / 2)} L ${f(cx - w / 2)} ${f(cy)} Z" fill="${c1}"/>`;
    }
  }
  return out;
}

// Toy block in 3/4 view; symbol on the front face (no letters).
function block(x, y, s, col, sym, { rot = 0, side = 1 } = {}) {
  const d = s * 0.32 * side, e = -s * 0.24;
  const front = `M ${x} ${y} L ${x + s} ${y} L ${x + s} ${y + s} L ${x} ${y + s} Z`;
  const top = `M ${x} ${y} L ${x + s} ${y} L ${x + s + d} ${y + e} L ${x + d} ${y + e} Z`;
  const sideP = side > 0
    ? `M ${x + s} ${y} L ${x + s + d} ${y + e} L ${x + s + d} ${y + s + e} L ${x + s} ${y + s} Z`
    : `M ${x} ${y} L ${x + d} ${y + e} L ${x + d} ${y + s + e} L ${x} ${y + s} Z`;
  const cx = x + s / 2, cy = y + s / 2;
  const symCol = shade(col, -0.55);
  const symbol = sym === "star"
    ? `<path d="${star(cx, cy + s * 0.03, s * 0.3)}" fill="${symCol}"/>`
    : sym === "circle"
      ? `<circle cx="${cx}" cy="${cy}" r="${s * 0.24}" fill="none" stroke="${symCol}" stroke-width="${s * 0.1}"/>`
      : sym === "heart"
        ? `<path d="M ${cx} ${cy + s * 0.26} l ${-s * 0.24} ${-s * 0.24} c ${-s * 0.14} ${-s * 0.16} ${s * 0.08} ${-s * 0.34} ${s * 0.24} ${-s * 0.14} c ${s * 0.16} ${-s * 0.2} ${s * 0.38} ${-s * 0.02} ${s * 0.24} ${s * 0.14} Z" fill="${symCol}"/>`
        : `<path d="M ${cx} ${cy - s * 0.26} L ${cx + s * 0.27} ${cy + s * 0.22} L ${cx - s * 0.27} ${cy + s * 0.22} Z" fill="${symCol}"/>`;
  return `<g transform="rotate(${rot} ${cx} ${cy})">
    <path d="${sideP}" fill="${shade(col, -0.45)}" stroke="#1a0f20" stroke-width="2.5" stroke-linejoin="round"/>
    <path d="${top}" fill="${shade(col, 0.25)}" stroke="#1a0f20" stroke-width="2.5" stroke-linejoin="round"/>
    <path d="${front}" fill="${col}" stroke="#1a0f20" stroke-width="2.5" stroke-linejoin="round"/>
    <rect x="${x + s * 0.1}" y="${y + s * 0.1}" width="${s * 0.8}" height="${s * 0.8}" rx="${s * 0.08}" fill="none" stroke="${shade(col, 0.4)}" stroke-width="${s * 0.05}" opacity="0.8"/>
    ${symbol}
    <path d="M ${x + 3} ${y + 3} L ${x + s - 3} ${y + 3}" stroke="#fff" stroke-width="2" opacity="0.45" stroke-linecap="round"/>
  </g>`;
}

export default function () {
  const R = rng(41);

  // Box geometry: front face square, oblique depth up-right.
  const S = 150, X = 284, Y = 238, DX = 46, DY = -32;
  const lidA = 0.8; // how far the lid is lifted (rad-ish)
  const LX = X + DX, LY = Y + DY; // back-left hinge corner
  const fwd = [-DX * Math.cos(lidA), -DY * Math.cos(lidA) - S * 0.5 * Math.sin(lidA)]; // hinge -> lid front
  const lf = [LX + fwd[0], LY + fwd[1]]; // lid front-left corner

  // Wallpaper: faint star + dot pattern.
  let paper = "";
  for (let y = 20; y < 300; y += 52) {
    for (let x = ((y / 52) % 2) * 36 - 10; x < 740; x += 72) {
      paper += `<path d="${star(x, y, 7, 0)}" fill="#22285e"/><circle cx="${x + 36}" cy="${y + 4}" r="2.5" fill="#22285e"/>`;
    }
  }
  // Dust motes in the warm light.
  let motes = "";
  for (let k = 0; k < 26; k++) {
    const x = 220 + R() * 300, y = 40 + R() * 200;
    motes += `<circle cx="${f(x)}" cy="${f(y)}" r="${f(0.8 + R() * 1.8)}" fill="#ffe9a8" opacity="${(0.25 + R() * 0.5).toFixed(2)}"/>`;
  }
  let winStars = "";
  for (let k = 0; k < 16; k++) winStars += `<circle cx="${f(60 + R() * 120)}" cy="${f(52 + R() * 100)}" r="${f(0.6 + R() * 1.2)}" fill="#dfe8ff" opacity="${(0.4 + R() * 0.5).toFixed(2)}"/>`;
  // Floor planks.
  let planks = "";
  for (let k = -8; k <= 8; k++) {
    planks += `<line x1="${360 + k * 46}" y1="318" x2="${360 + k * 150}" y2="440" stroke="#0e0c22" stroke-width="2.5" opacity="0.7"/>`;
  }

  // Front face and side face patterns via transforms of a local S x S square.
  const frontPat = `<g transform="translate(${X} ${Y})">
      <clipPath id="jbClipF"><rect width="${S}" height="${S}"/></clipPath>
      <g clip-path="url(#jbClipF)">${harlequin(S, 3, TB, "#e2483f")}
        <rect width="${S}" height="${S}" fill="url(#jbFrontLight)"/></g>
    </g>`;
  const sidePat = `<g transform="matrix(${DX / S} ${DY / S} 0 1 ${X + S} ${Y})">
      <clipPath id="jbClipS"><rect width="${S}" height="${S}"/></clipPath>
      <g clip-path="url(#jbClipS)">${harlequin(S, 3, shade(TB, -0.45), shade("#7a3cc8", -0.45))}</g>
    </g>`;
  const trim = (pts) => `<path d="M ${pts.map((p) => p.map(f).join(" ")).join(" L ")} Z" fill="none" stroke="url(#jbGold)" stroke-width="9" stroke-linejoin="round"/>
    <path d="M ${pts.map((p) => p.map(f).join(" ")).join(" L ")} Z" fill="none" stroke="#3a1a10" stroke-width="1.5" stroke-linejoin="round" opacity="0.7"/>`;

  // Opening (dark interior with warm glow) and the eyes inside.
  const op = [[X, Y], [X + S, Y], [X + S + DX, Y + DY], [X + DX, Y + DY]];
  const opening = `<path d="M ${op.map((p) => p.map(f).join(" ")).join(" L ")} Z" fill="#120808"/>
    <path d="M ${op.map((p) => p.map(f).join(" ")).join(" L ")} Z" fill="url(#jbInner)"/>`;
  const ex = X + S / 2 + DX * 0.5, ey = Y + DY * 0.5;
  const eyes = [-1, 1].map((d) => {
    const x = ex + d * 21;
    return `<ellipse cx="${x}" cy="${ey}" rx="22" ry="15" fill="${TB}" opacity="0.85" filter="url(#jbGlowS)"/>
      <path d="M ${x - d * 12} ${ey + 1} L ${x + d * 15} ${ey - 7} Q ${x + d * 14} ${ey + 9} ${x} ${ey + 9} Q ${x - d * 10} ${ey + 8} ${x - d * 12} ${ey + 1} Z" fill="#fff6c8"/>
      <ellipse cx="${x + 4}" cy="${ey + 2}" rx="3" ry="4.6" fill="#3a1a00"/>`;
  }).join("");

  // Lid (lifted), seen from above-front; its top is a parallelogram.
  const lid = [[lf[0], lf[1]], [lf[0] + S, lf[1]], [LX + S, LY], [LX, LY]];
  const lidEdge = 12;
  const lidSvg = `
    <path d="M ${f(lf[0])} ${f(lf[1])} L ${f(lf[0] + S)} ${f(lf[1])} L ${f(lf[0] + S)} ${f(lf[1] + lidEdge)} L ${f(lf[0])} ${f(lf[1] + lidEdge)} Z" fill="#a8243a" stroke="#1a0f20" stroke-width="2.5"/>
    <path d="M ${f(lf[0] + S)} ${f(lf[1])} L ${f(LX + S)} ${f(LY)} L ${f(LX + S)} ${f(LY + 6)} L ${f(lf[0] + S)} ${f(lf[1] + lidEdge)} Z" fill="#6a1428" stroke="#1a0f20" stroke-width="2"/>
    <path d="M ${lid.map((p) => p.map(f).join(" ")).join(" L ")} Z" fill="url(#jbLid)" stroke="#1a0f20" stroke-width="2.5" stroke-linejoin="round"/>
    ${trim(lid)}
    <g transform="matrix(1 0 ${f((LX - lf[0]) / S)} ${f((LY - lf[1]) / S)} ${f(lf[0])} ${f(lf[1])})">
      <path d="${star(S / 2, S / 2, 34)}" fill="${TB}" stroke="#7a4a10" stroke-width="3"/>
      <path d="${star(S / 2, S / 2, 20)}" fill="#fff1b0" opacity="0.6"/>
    </g>
    <!-- warm light spilling under the lid edge -->
    <path d="M ${f(lf[0] + 6)} ${f(lf[1] + lidEdge)} L ${f(lf[0] + S - 6)} ${f(lf[1] + lidEdge)}" stroke="${TB}" stroke-width="5" opacity="0.8" filter="url(#jbGlowS)"/>`;

  // Crank on the right side face, turning on its own.
  const sx = X + S + DX * 0.5, sy = Y + S * 0.5 + DY * 0.5;
  const crank = `
    <ellipse cx="${sx}" cy="${sy}" rx="9" ry="13" fill="url(#jbGold)" stroke="#3a1a10" stroke-width="2"/>
    <path d="M ${sx} ${sy} L ${sx + 40} ${sy - 4}" stroke="#3a1a10" stroke-width="10" stroke-linecap="round"/>
    <path d="M ${sx} ${sy} L ${sx + 40} ${sy - 4}" stroke="url(#jbGoldV)" stroke-width="6" stroke-linecap="round"/>
    <path d="M ${sx + 40} ${sy - 4} L ${sx + 48} ${sy + 36}" stroke="#3a1a10" stroke-width="10" stroke-linecap="round"/>
    <path d="M ${sx + 40} ${sy - 4} L ${sx + 48} ${sy + 36}" stroke="url(#jbGoldV)" stroke-width="6" stroke-linecap="round"/>
    <path d="M ${sx + 48} ${sy + 36} L ${sx + 66} ${sy + 34}" stroke="#3a1a10" stroke-width="9" stroke-linecap="round"/>
    <rect x="${sx + 56}" y="${sy + 24}" width="26" height="20" rx="10" fill="url(#jbKnob)" stroke="#3a0a14" stroke-width="2.5"/>
    <ellipse cx="${sx + 64}" cy="${sy + 29}" rx="6" ry="3" fill="#fff" opacity="0.6"/>
    <!-- motion arcs -->
    <path d="M ${sx + 92} ${sy + 4} A 50 50 0 0 1 ${sx + 82} ${sy + 62}" fill="none" stroke="#fff1b0" stroke-width="3" stroke-linecap="round" opacity="0.75"/>
    <path d="M ${sx + 104} ${sy + 14} A 56 56 0 0 1 ${sx + 96} ${sy + 58}" fill="none" stroke="#fff1b0" stroke-width="2" stroke-linecap="round" opacity="0.45"/>
    <path d="M ${sx + 78} ${sy + 66} l 10 -2 l -4 10" fill="none" stroke="#fff1b0" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" opacity="0.75"/>`;

  // Box body.
  const sideFace = [[X + S, Y], [X + S + DX, Y + DY], [X + S + DX, Y + S + DY], [X + S, Y + S]];
  const box = `
    <ellipse cx="${X + S / 2 + 20}" cy="${Y + S + 6}" rx="${S * 0.78}" ry="18" fill="#000" opacity="0.55" filter="url(#jbBlurS)"/>
    ${sidePat}
    <path d="M ${sideFace.map((p) => p.map(f).join(" ")).join(" L ")} Z" fill="url(#jbSideShade)"/>
    ${trim(sideFace)}
    ${frontPat}
    ${trim([[X, Y], [X + S, Y], [X + S, Y + S], [X, Y + S]])}
    ${[[X, Y], [X + S, Y], [X, Y + S], [X + S, Y + S], [X + S + DX, Y + DY], [X + S + DX, Y + S + DY]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="8" fill="url(#jbGoldBall)" stroke="#3a1a10" stroke-width="1.5"/>`).join("")}
    <!-- centre medallion on the front -->
    <circle cx="${X + S / 2}" cy="${Y + S / 2}" r="30" fill="#2a1450" stroke="url(#jbGold)" stroke-width="6"/>
    <path d="${star(X + S / 2, Y + S / 2 + 2, 20)}" fill="${TB}"/>
    <!-- rim light from the window (left) -->
    <path d="M ${X + 2} ${Y + 6} L ${X + 2} ${Y + S - 6}" stroke="#9fc4ff" stroke-width="3" opacity="0.6"/>
    ${opening}
    ${eyes}
`;

  // Toy drum (right foreground).
  const dx = 588, dy = 360, drx = 50, dry = 15, dh = 50;
  let zig = "";
  for (let k = 0; k < 6; k++) {
    const a0 = Math.PI * (k / 6), a1 = Math.PI * ((k + 0.5) / 6), a2 = Math.PI * ((k + 1) / 6);
    const px = (a) => dx - Math.cos(a) * drx, pyT = (a) => dy + Math.sin(a) * dry + 6, pyB = (a) => dy + dh + Math.sin(a) * dry - 6;
    zig += `<path d="M ${f(px(a0))} ${f(pyT(a0))} L ${f(px(a1))} ${f(pyB(a1))} L ${f(px(a2))} ${f(pyT(a2))}" fill="none" stroke="#ffe9a8" stroke-width="2.5"/>`;
  }
  const drum = `
    <ellipse cx="${dx + 6}" cy="${dy + dh + 12}" rx="${drx + 10}" ry="12" fill="#000" opacity="0.5" filter="url(#jbBlurS)"/>
    <path d="M ${dx - drx} ${dy} L ${dx - drx} ${dy + dh} A ${drx} ${dry} 0 0 0 ${dx + drx} ${dy + dh} L ${dx + drx} ${dy} Z" fill="url(#jbDrum)" stroke="#1a0f20" stroke-width="2.5"/>
    ${zig}
    <path d="M ${dx - drx} ${dy + 4} A ${drx} ${dry} 0 0 0 ${dx + drx} ${dy + 4}" fill="none" stroke="url(#jbGold)" stroke-width="7"/>
    <path d="M ${dx - drx} ${dy + dh - 3} A ${drx} ${dry} 0 0 0 ${dx + drx} ${dy + dh - 3}" fill="none" stroke="url(#jbGold)" stroke-width="7"/>
    <ellipse cx="${dx}" cy="${dy}" rx="${drx}" ry="${dry}" fill="#f4e6c8" stroke="#1a0f20" stroke-width="2.5"/>
    <ellipse cx="${dx - 10}" cy="${dy - 3}" rx="${drx * 0.6}" ry="${dry * 0.5}" fill="#fff" opacity="0.45"/>
    <path d="M ${dx - 64} ${dy + dh + 18} L ${dx - 4} ${dy - 6}" stroke="#3a1a10" stroke-width="7" stroke-linecap="round"/>
    <path d="M ${dx - 64} ${dy + dh + 18} L ${dx - 4} ${dy - 6}" stroke="#d8a060" stroke-width="4" stroke-linecap="round"/>
    <circle cx="${dx - 4}" cy="${dy - 6}" r="7" fill="#ff5a6a" stroke="#3a0a14" stroke-width="2"/>`;

  // Critter hiding behind the drum, peeking at the box.
  const cx = 622, cy = 322, cr = 42, cc = "#3fa9f5";
  const ce = cy - cr * 0.12;
  const critter = `
    ${ball(cx, cy, cr, cc, { glow: false })}
    <path d="M ${cx - cr * 0.9} ${cy - cr * 0.3} A ${cr} ${cr} 0 0 1 ${cx - cr * 0.2} ${cy - cr * 0.98}" fill="none" stroke="#ffe9a8" stroke-width="3" opacity="0.75" stroke-linecap="round"/>
    ${eye(cx - cr * 0.34, ce, cr * 0.22, cr * 0.3, -0.9, -0.1, cr * 0.11)}
    ${eye(cx + cr * 0.28, ce, cr * 0.22, cr * 0.3, -0.9, -0.1, cr * 0.11)}
    ${brow(cx - cr * 0.56, ce - cr * 0.34, cx - cr * 0.16, ce - cr * 0.48, cr * 0.07)}
    ${brow(cx + cr * 0.06, ce - cr * 0.48, cx + cr * 0.48, ce - cr * 0.36, cr * 0.07)}
    <path d="M ${cx + cr * 0.75} ${cy - cr * 0.85} q 8 10 0 16 q -8 -6 0 -16 Z" fill="#bfefff" stroke="#5a9ac8" stroke-width="1"/>
    <!-- little paws gripping the drum rim -->
    <ellipse cx="${cx - cr * 0.55}" cy="${dy - 2}" rx="9" ry="6" fill="${shade(cc, 0.1)}" stroke="${shade(cc, -0.5)}" stroke-width="2"/>
    <ellipse cx="${cx - cr * 0.1}" cy="${dy - 1}" rx="9" ry="6" fill="${shade(cc, 0.1)}" stroke="${shade(cc, -0.5)}" stroke-width="2"/>`;

  // Hanging star mobile from the ceiling (left of the window light).
  const mob = (x, len, r, col) => `<line x1="${x}" y1="0" x2="${x}" y2="${len}" stroke="#4a4a80" stroke-width="1.5"/>
    <path d="${star(x, len + r, r, 8)}" fill="${col}" stroke="${shade(col, -0.5)}" stroke-width="2"/>`;

  return `<svg xmlns="http://www.w3.org/2000/svg" width="720" height="440" viewBox="0 0 720 440">
  <defs>
    <radialGradient id="jbBg" cx="50%" cy="48%" r="72%">
      <stop offset="0" stop-color="#2a2460"/><stop offset="0.55" stop-color="#141236"/><stop offset="1" stop-color="#0a0a1e"/>
    </radialGradient>
    <radialGradient id="jbHalo" cx="50%" cy="50%" r="50%">
      <stop offset="0" stop-color="${TB}" stop-opacity="0.45"/><stop offset="0.5" stop-color="#ff9a3c" stop-opacity="0.15"/><stop offset="1" stop-color="${TB}" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="jbFloor" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#2a1e3e"/><stop offset="1" stop-color="#0c0a1a"/>
    </linearGradient>
    <linearGradient id="jbNightSky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#0d1238"/><stop offset="1" stop-color="#2a3a8a"/>
    </linearGradient>
    <linearGradient id="jbGold" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#fff1b0"/><stop offset="0.45" stop-color="#ffc93c"/><stop offset="1" stop-color="#a8620e"/>
    </linearGradient>
    <linearGradient id="jbGoldV" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#fff1b0"/><stop offset="1" stop-color="#c98a14"/>
    </linearGradient>
    <radialGradient id="jbGoldBall" cx="0.35" cy="0.3" r="0.8">
      <stop offset="0" stop-color="#fff6d0"/><stop offset="0.5" stop-color="#ffc93c"/><stop offset="1" stop-color="#8a500e"/>
    </radialGradient>
    <radialGradient id="jbKnob" cx="0.35" cy="0.3" r="0.8">
      <stop offset="0" stop-color="#ffb0b8"/><stop offset="0.5" stop-color="#ff4f5e"/><stop offset="1" stop-color="#8a1424"/>
    </radialGradient>
    <linearGradient id="jbFrontLight" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#fff" stop-opacity="0.15"/><stop offset="0.5" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#0a0820" stop-opacity="0.45"/>
    </linearGradient>
    <linearGradient id="jbSideShade" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#000" stop-opacity="0.15"/><stop offset="1" stop-color="#000" stop-opacity="0.45"/>
    </linearGradient>
    <linearGradient id="jbLid" x1="0" y1="1" x2="0" y2="0">
      <stop offset="0" stop-color="#e2483f"/><stop offset="1" stop-color="#8a1e3a"/>
    </linearGradient>
    <radialGradient id="jbInner" cx="0.5" cy="0.5" r="0.6">
      <stop offset="0" stop-color="#ff9a3c" stop-opacity="0.55"/><stop offset="1" stop-color="#ff9a3c" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="jbDrum" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#4a2aa0"/><stop offset="0.35" stop-color="#7a4ae0"/><stop offset="1" stop-color="#241052"/>
    </linearGradient>
    <linearGradient id="jbBeam" x1="0" y1="1" x2="0" y2="0">
      <stop offset="0" stop-color="${TB}" stop-opacity="0.45"/><stop offset="1" stop-color="${TB}" stop-opacity="0"/>
    </linearGradient>
    <linearGradient id="jbMoonBeam" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#9fc4ff" stop-opacity="0.22"/><stop offset="1" stop-color="#9fc4ff" stop-opacity="0"/>
    </linearGradient>
    <radialGradient id="jbVig" cx="50%" cy="46%" r="72%">
      <stop offset="0.5" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.7"/>
    </radialGradient>
    <filter id="jbGlowS" x="-80%" y="-80%" width="260%" height="260%"><feGaussianBlur stdDeviation="4"/></filter>
    <filter id="jbGlowL" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="20"/></filter>
    <filter id="jbBlurS" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="5"/></filter>
    <filter id="jbBlurM" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="9"/></filter>
  </defs>

  <rect width="720" height="440" fill="url(#jbBg)"/>
  <g opacity="0.8">${paper}</g>

  <!-- window with moon, top-left -->
  <rect x="44" y="38" width="150" height="128" rx="6" fill="url(#jbNightSky)"/>
  ${winStars}
  <circle cx="150" cy="78" r="30" fill="#cfe0ff" opacity="0.35" filter="url(#jbBlurS)"/>
  <circle cx="150" cy="78" r="17" fill="#eef3ff"/>
  <circle cx="158" cy="72" r="15" fill="#2a3a8a" opacity="0.0"/>
  <rect x="44" y="38" width="150" height="128" rx="6" fill="none" stroke="#3a3070" stroke-width="10"/>
  <line x1="119" y1="38" x2="119" y2="166" stroke="#3a3070" stroke-width="7"/>
  <line x1="44" y1="102" x2="194" y2="102" stroke="#3a3070" stroke-width="7"/>
  <rect x="34" y="166" width="170" height="10" rx="3" fill="#3a3070"/>
  <path d="M 194 40 L 440 300 L 330 330 L 44 168 Z" fill="url(#jbMoonBeam)" filter="url(#jbBlurM)"/>

  <!-- shelf with toy silhouettes, right wall -->
  <rect x="500" y="150" width="200" height="9" rx="2" fill="#2a2252"/>
  <rect x="500" y="150" width="200" height="2" fill="${TB}" opacity="0.25"/>
  <g fill="#1c1840">
    <circle cx="530" cy="130" r="20"/><circle cx="514" cy="112" r="8"/><circle cx="546" cy="112" r="8"/><ellipse cx="530" cy="146" rx="18" ry="8"/>
    <path d="M 586 150 L 586 110 L 596 92 L 606 110 L 606 150 Z"/><path d="M 580 150 L 586 132 L 586 150 Z"/><path d="M 612 150 L 606 132 L 606 150 Z"/>
    <rect x="636" y="110" width="34" height="40" rx="4"/><circle cx="653" cy="100" r="11"/><line x1="653" y1="89" x2="653" y2="78" stroke="#1c1840" stroke-width="3"/>
  </g>
  <path d="M 512 112 A 20 20 0 0 1 530 110" stroke="${TB}" stroke-width="2" fill="none" opacity="0.4"/>

  <!-- star mobile -->
  ${mob(250, 40, 11, "#8fe6ff")}${mob(282, 68, 9, TB)}${mob(310, 30, 8, "#ff7ac8")}
  <path d="M 236 0 L 324 0" stroke="#4a4a80" stroke-width="2"/>

  <!-- skirting + floor -->
  <rect x="0" y="300" width="720" height="18" fill="#1a1640"/>
  <rect x="0" y="300" width="720" height="3" fill="#3a3478"/>
  <rect x="0" y="318" width="720" height="122" fill="url(#jbFloor)"/>
  ${planks}

  <!-- warm halo and glow pool -->
  <ellipse cx="380" cy="240" rx="300" ry="210" fill="url(#jbHalo)"/>
  <ellipse cx="380" cy="400" rx="230" ry="36" fill="${TB}" opacity="0.28" filter="url(#jbGlowL)"/>
  <!-- light beams escaping the lid -->
  <path d="M ${X + 10} ${Y - 2} L ${X + S + DX - 6} ${Y + DY + 2} L ${X + S + 120} -10 L ${X - 70} -10 Z" fill="url(#jbBeam)" opacity="0.6" filter="url(#jbBlurM)"/>

  ${box}
  ${lidSvg}
  ${crank}

  <!-- scattered blocks, left -->
  ${block(92, 330, 54, "#5fd068", "star")}
  ${block(118, 280, 48, "#3fa9f5", "circle", { rot: -8 })}
  ${block(186, 372, 40, "#ff7ac8", "heart", { rot: 14 })}
  ${block(470, 394, 34, "#b07cff", "triangle", { rot: -20, side: -1 })}
  ${drum}
  ${critter}
  ${motes}
  ${twinkle(X + S + DX + 18, Y + DY - 40, 7, "#fff1b0", 0.9)}
  ${twinkle(X - 22, Y - 28, 5, "#fff1b0", 0.7)}
  <rect width="720" height="440" fill="url(#jbVig)"/>
</svg>`;
}

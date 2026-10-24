// Fire family: a narrow, crumbling rock bridge over glowing magma, embers rising,
// a far ledge where the path carries on. A shortcut: hot and risky.
import { ball, eye, shade, INK } from "../../brand/parts.mjs";

const FI = "#FF7A45";

function rng(seed) {
  let s = seed;
  return () => ((s = (s * 16807) % 2147483647) / 2147483647);
}
const lerp = (a, b, t) => a + (b - a) * t;
const pt = (p) => `${p[0].toFixed(1)} ${p[1].toFixed(1)}`;

export default function () {
  const R = rng(23);

  // Bridge centreline from near ledge to far ledge, with a gentle arch.
  const A = [196, 344], B = [516, 192];
  const C = (t) => [lerp(A[0], B[0], t), lerp(A[1], B[1], t) - Math.sin(Math.PI * t) * 34];
  const W = (t) => lerp(40, 15, t); // half width
  const D = (t) => lerp(40, 14, t); // thickness
  const back = (t) => { const c = C(t), w = W(t); return [c[0] - w * 0.42, c[1] - w * 0.5]; };
  const front = (t) => { const c = C(t), w = W(t); return [c[0] + w * 0.42, c[1] + w * 0.5]; };
  const under = (t) => { const f = front(t); return [f[0], f[1] + D(t)]; };

  // Blocks along the bridge, with one missing gap and a loose block.
  const N = 11, gap = 6;
  let blocks = "", sides = "";
  for (let k = 0; k < N; k++) {
    if (k === gap) continue;
    const t0 = k / N + 0.006, t1 = (k + 1) / N - 0.006;
    const drop = k === gap + 1 ? 5 : k === gap - 1 ? 2 : 0;
    const dy = (p) => [p[0], p[1] + drop];
    const b0 = dy(back(t0)), b1 = dy(back(t1)), f0 = dy(front(t0)), f1 = dy(front(t1)), u0 = dy(under(t0)), u1 = dy(under(t1));
    const shadeT = 0.15 + R() * 0.12;
    blocks += `<path d="M ${pt(b0)} L ${pt(b1)} L ${pt(f1)} L ${pt(f0)} Z" fill="${shade("#8a5a64", shadeT - 0.15)}" stroke="#1a0d1e" stroke-width="1.5" stroke-linejoin="round"/>`;
    blocks += `<path d="M ${pt(b0)} L ${pt(b1)}" stroke="#ffb07a" stroke-width="1.5" opacity="0.35"/>`;
    sides += `<path d="M ${pt(f0)} L ${pt(f1)} L ${pt(u1)} L ${pt(u0)} Z" fill="url(#lbSide)" stroke="#1a0d1e" stroke-width="1.5" stroke-linejoin="round"/>`;
    if (k % 3 === 1) {
      const m = front((t0 + t1) / 2);
      sides += `<path d="M ${m[0] - 3} ${m[1] + 4} l 4 8 l -3 8" fill="none" stroke="#ffb24a" stroke-width="1.6" opacity="0.9"/>`;
    }
  }
  // Hanging rock drips under the bridge.
  let drips = "";
  for (let k = 1; k < 10; k++) {
    if (k === gap) continue;
    const t = k / 10 + 0.03;
    const u = under(t);
    const len = 8 + R() * 18 * (1 - t);
    drips += `<path d="M ${u[0] - 7} ${u[1] - 2} L ${u[0]} ${u[1] + len} L ${u[0] + 7} ${u[1] - 2} Z" fill="#3a1e30"/>`;
  }
  // Falling block from the gap.
  const g = C((gap + 0.5) / N);
  const falling = `
    <g transform="translate(${g[0] + 8} ${g[1] + 78}) rotate(24)">
      <rect x="-10" y="-8" width="20" height="16" rx="2" fill="#5a3c5e" stroke="#1a0d1e" stroke-width="1.5"/>
      <rect x="-10" y="2" width="20" height="6" fill="#ff8a3a" opacity="0.7"/>
    </g>
    <circle cx="${g[0] - 4}" cy="${g[1] + 56}" r="2.5" fill="#5a3c5e"/>
    <circle cx="${g[0] + 18}" cy="${g[1] + 50}" r="2" fill="#5a3c5e"/>`;
  // Splash where an earlier piece hit the lava.
  const sx = g[0] + 20, sy = 372;
  const splash = `
    <ellipse cx="${sx}" cy="${sy}" rx="30" ry="7" fill="#fff1a0" opacity="0.8" filter="url(#lbGlowS)"/>
    <path d="M ${sx - 16} ${sy} q -6 -22 -2 -30 q 6 14 8 30 Z M ${sx + 2} ${sy - 2} q 0 -30 6 -40 q 4 20 0 40 Z M ${sx + 16} ${sy} q 8 -16 16 -18 q -6 10 -8 18 Z" fill="#ffd36a"/>
    <circle cx="${sx - 10}" cy="${sy - 40}" r="3" fill="#ffd36a"/><circle cx="${sx + 22}" cy="${sy - 30}" r="2.5" fill="#ffb24a"/>`;

  // Lava crust plates.
  let crust = "";
  for (let k = 0; k < 34; k++) {
    const x = R() * 760 - 20, y = 250 + Math.pow(R(), 0.8) * 200;
    const s = (0.3 + (y - 250) / 200) * (18 + R() * 30);
    const pts = [];
    for (let j = 0; j < 6; j++) {
      const a = (j / 6) * Math.PI * 2 + R() * 0.5;
      pts.push(`${(x + Math.cos(a) * s * (0.7 + R() * 0.5)).toFixed(1)},${(y + Math.sin(a) * s * 0.35 * (0.7 + R() * 0.5)).toFixed(1)}`);
    }
    crust += `<polygon points="${pts.join(" ")}" fill="#3a1424" opacity="${0.55 + R() * 0.35}" stroke="#ff9a3a" stroke-width="1.2" stroke-opacity="0.7"/>`;
  }
  // Embers rising.
  let embers = "";
  for (let k = 0; k < 46; k++) {
    const x = 40 + R() * 640, y = 30 + R() * 360;
    const r = 1 + R() * 2.8;
    const c = R() < 0.5 ? "#ffd36a" : FI;
    embers += `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="${r.toFixed(1)}" fill="${c}" opacity="${(0.5 + R() * 0.5).toFixed(2)}"/>`;
    if (k % 4 === 0) embers += `<line x1="${x}" y1="${y}" x2="${x - 3}" y2="${y + 12}" stroke="${c}" stroke-width="${r * 0.8}" stroke-linecap="round" opacity="0.4"/>`;
  }
  // Heat shimmer lines.
  let shimmer = "";
  for (let k = 0; k < 7; k++) {
    const x = 60 + R() * 600, y = 140 + R() * 140;
    shimmer += `<path d="M ${x} ${y} q 6 -8 0 -16 q -6 -8 0 -16 q 6 -8 0 -16" fill="none" stroke="#ffcf9a" stroke-width="1.5" opacity="0.18"/>`;
  }

  // The little Fire-family critter at the near end, peeking at the crossing.
  const kx = 206, ky = 318, kr = 26;
  const critter = `
    <ellipse cx="${kx + 4}" cy="${ky + kr - 2}" rx="${kr}" ry="6" fill="#000" opacity="0.45"/>
    ${ball(kx, ky, kr, FI, { glow: true })}
    <path d="M ${kx - 10} ${ky - kr + 4} q -2 -18 8 -24 q 0 10 6 12 q 4 -10 12 -10 q -4 12 -4 22 Z" fill="#ffd36a" stroke="${shade(FI, -0.5)}" stroke-width="2"/>
    ${eye(kx - 2, ky - 4, 7, 9, 0.8, -0.3, 4)}${eye(kx + 16, ky - 4, 7, 9, 0.8, -0.3, 4)}
    <path d="M ${kx + 2} ${ky + 12} q 6 -4 12 0" fill="none" stroke="${INK}" stroke-width="3" stroke-linecap="round"/>
    <path d="M ${kx - 20} ${ky - 18} q 6 8 0 12 q -6 -4 0 -12 Z" fill="#bfefff"/>`;

  return `<svg xmlns="http://www.w3.org/2000/svg" width="720" height="440" viewBox="0 0 720 440">
  <defs>
    <linearGradient id="lbSky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#0D0F26"/><stop offset="0.45" stop-color="#2a1640"/><stop offset="0.75" stop-color="#5a1e3a"/><stop offset="1" stop-color="#8a2e2e"/>
    </linearGradient>
    <linearGradient id="lbLava" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#ff5a2a"/><stop offset="0.35" stop-color="#ff9a3a"/><stop offset="0.7" stop-color="#ffc85a"/><stop offset="1" stop-color="#ff8a3a"/>
    </linearGradient>
    <radialGradient id="lbLavaHot" cx="50%" cy="50%" r="50%">
      <stop offset="0" stop-color="#fff3b0" stop-opacity="0.85"/><stop offset="1" stop-color="#ffd36a" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="lbSide" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#3a2038"/><stop offset="0.6" stop-color="#6a2e30"/><stop offset="1" stop-color="#c4562e"/>
    </linearGradient>
    <linearGradient id="lbCliff" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#4a3050"/><stop offset="0.5" stop-color="#2a1630"/><stop offset="1" stop-color="#8a3a2a"/>
    </linearGradient>
    <linearGradient id="lbCliffNear" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#3a2440"/><stop offset="0.6" stop-color="#1e1024"/><stop offset="1" stop-color="#6a2a24"/>
    </linearGradient>
    <radialGradient id="lbVig" cx="50%" cy="50%" r="72%">
      <stop offset="0.6" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.6"/>
    </radialGradient>
    <filter id="lbGlowS" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="3"/></filter>
    <filter id="lbGlowL" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="18"/></filter>
    <filter id="lbHaze" x="-20%" y="-50%" width="140%" height="200%"><feGaussianBlur stdDeviation="8"/></filter>
  </defs>

  <rect width="720" height="440" fill="url(#lbSky)"/>
  <!-- distant volcano and ridges -->
  <path d="M 0 210 L 70 170 L 120 186 L 190 120 L 230 128 L 268 96 L 300 100 L 360 168 L 420 150 L 500 190 L 560 160 L 620 176 L 720 140 L 720 260 L 0 260 Z" fill="#2e1638" opacity="0.9"/>
  <path d="M 252 108 L 268 96 L 300 100 L 314 114 Z" fill="#ff7a45" opacity="0.6"/>
  <ellipse cx="282" cy="92" rx="60" ry="24" fill="#ff7a45" opacity="0.35" filter="url(#lbGlowL)"/>
  <path d="M 280 100 q -6 30 -20 50 q -6 20 -24 40" fill="none" stroke="#ff9a3a" stroke-width="3" opacity="0.7"/>
  <!-- smoke plume -->
  <g filter="url(#lbHaze)" opacity="0.55">
    <ellipse cx="286" cy="70" rx="30" ry="18" fill="#4a2a4e"/><ellipse cx="300" cy="44" rx="40" ry="20" fill="#3a2244"/><ellipse cx="324" cy="22" rx="52" ry="18" fill="#2c1a3c"/>
  </g>
  <path d="M 0 240 L 90 200 L 160 222 L 240 196 L 330 230 L 420 210 L 470 226 L 470 280 L 0 280 Z" fill="#3a1a38"/>
  <path d="M 0 240 L 90 200 L 160 222 L 240 196 L 330 230 L 420 210 L 470 226" fill="none" stroke="#ff7a45" stroke-width="2" opacity="0.4"/>

  <!-- magma -->
  <rect x="0" y="244" width="720" height="196" fill="url(#lbLava)"/>
  <ellipse cx="360" cy="360" rx="300" ry="70" fill="url(#lbLavaHot)"/>
  ${crust}
  <rect x="0" y="244" width="720" height="40" fill="#5a1e3a" opacity="0.5" filter="url(#lbHaze)"/>
  <!-- glow rising off the magma -->
  <rect x="0" y="200" width="720" height="80" fill="#ff7a45" opacity="0.18" filter="url(#lbGlowL)"/>

  <!-- far ledge with the path continuing -->
  <path d="M 478 212 Q 500 188 540 184 L 600 170 Q 650 150 720 150 L 720 300 Q 640 290 560 300 Q 510 296 478 268 Z" fill="url(#lbCliff)"/>
  <path d="M 478 212 Q 500 188 540 184 L 600 170 Q 650 150 720 150" fill="none" stroke="#ffb07a" stroke-width="2.5" opacity="0.55"/>
  <path d="M 520 192 Q 580 180 610 158 Q 640 136 650 112 L 664 112 Q 660 142 628 168 Q 600 190 540 198 Z" fill="#7a5070" opacity="0.85"/>
  <!-- path slips over a rise between two rock spires -->
  <path d="M 604 160 Q 612 120 622 96 L 636 86 Q 644 110 648 150 Z" fill="#2e1834" stroke="#ffb07a" stroke-width="1.5" stroke-opacity="0.55" stroke-linejoin="round"/>
  <path d="M 664 146 Q 668 110 674 88 L 686 80 Q 692 110 694 152 Z" fill="#2e1834" stroke="#ffb07a" stroke-width="1.5" stroke-opacity="0.55" stroke-linejoin="round"/>
  <ellipse cx="657" cy="108" rx="16" ry="14" fill="#ffcf8a" opacity="0.45" filter="url(#lbGlowS)"/>
  ${[[560, 188], [598, 172], [626, 150], [646, 124]].map(([x, y], i) => `<circle cx="${x}" cy="${y}" r="${5 - i}" fill="#ffd36a"/><circle cx="${x}" cy="${y}" r="${12 - i * 2}" fill="#ff9a3a" opacity="0.5" filter="url(#lbGlowS)"/>`).join("")}
  <!-- torch on the far end -->
  <rect x="528" y="146" width="4" height="40" fill="#2a1630"/>
  <circle cx="530" cy="140" r="16" fill="#ff9a3a" opacity="0.6" filter="url(#lbGlowS)"/>
  <path d="M 530 128 q 8 10 4 18 q -4 3 -8 0 q -4 -8 4 -18 Z" fill="#ffd36a"/>
  <!-- cliff under the far ledge (rocky spires) -->
  <path d="M 478 268 L 470 330 L 500 300 L 520 360 L 548 304 L 590 330 L 610 298 L 660 340 L 720 300 L 720 300 Q 640 290 560 300 Q 510 296 478 268 Z" fill="#2a1428"/>

  <!-- bridge -->
  <ellipse cx="${C(0.5)[0]}" cy="${C(0.5)[1] + 120}" rx="140" ry="14" fill="#3a1424" opacity="0.5" filter="url(#lbHaze)"/>
  ${sides}${drips}${blocks}
  <ellipse cx="${g[0] + 4}" cy="${g[1] + 30}" rx="16" ry="30" fill="#ffd36a" opacity="0.35" filter="url(#lbGlowS)"/>
  ${falling}
  ${splash}

  <!-- near ledge -->
  <path d="M 0 300 Q 90 300 170 322 Q 232 334 250 356 Q 240 400 200 440 L 0 440 Z" fill="url(#lbCliffNear)"/>
  <path d="M 0 300 Q 90 300 170 322 Q 232 334 250 356" fill="none" stroke="#ffb07a" stroke-width="2.5" opacity="0.6"/>
  <path d="M 70 340 l 20 22 l -6 20 l 18 24 M 150 352 l 10 18 l -8 14" fill="none" stroke="#ff8a3a" stroke-width="2" opacity="0.75" filter="url(#lbGlowS)"/>
  <path d="M 70 340 l 20 22 l -6 20 l 18 24 M 150 352 l 10 18 l -8 14" fill="none" stroke="#ffd36a" stroke-width="1.2"/>
  <g data-layer="critter" data-move="idle 4 0.9 0">${critter}</g>
  <!-- foreground rocks bottom right, framing -->
  <path d="M 600 440 Q 620 392 664 384 Q 706 382 720 396 L 720 440 Z" fill="#1a0c1c"/>
  <path d="M 600 440 Q 620 392 664 384 Q 706 382 720 396" fill="none" stroke="#ff9a3a" stroke-width="2" opacity="0.5"/>

  ${shimmer}
  <g>${embers}</g>
  <g filter="url(#lbGlowS)" opacity="0.7">${embers}</g>
  <rect width="720" height="440" fill="url(#lbVig)"/>
</svg>`;
}

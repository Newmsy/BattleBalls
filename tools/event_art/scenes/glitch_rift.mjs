// Glitch family: the arena floor has split open into a jagged rift of static,
// pixels and scanlines (magenta + cyan, chromatic aberration). A golden orb
// floats inside it. A critter leans over the edge to peer in.
import { ball, eye, shade, INK } from "../../brand/parts.mjs";

const MG = "#FF4FB8";
const CY = "#3EE6FF";
const GOLD = "#FFD23F";

function rng(seed) {
  let s = seed;
  return () => ((s = (s * 16807) % 2147483647) / 2147483647);
}

export default function () {
  const R = rng(47);
  const ox = 362, oy = 240; // orb centre

  // Rift outline: jagged far edge (top) and near edge (bottom), a lens across the floor.
  const far = [[118, 262], [150, 240], [176, 248], [204, 218], [240, 226], [262, 196], [300, 204], [326, 178], [362, 190], [392, 170], [420, 188], [452, 176], [480, 200], [516, 192], [540, 216], [576, 210], [604, 236], [636, 250]];
  const near = [[636, 250], [600, 270], [574, 264], [548, 292], [512, 286], [486, 312], [446, 302], [420, 330], [384, 318], [352, 340], [320, 322], [288, 334], [258, 312], [226, 318], [206, 296], [176, 296], [150, 276], [118, 262]];
  const poly = (pts, dx = 0, dy = 0) => pts.map(([x, y]) => `${x + dx},${y + dy}`).join(" ");
  const riftPts = [...far, ...near.slice(1)];
  const rift = poly(riftPts);
  // The far wall of the rift: a slab face hanging below the far edge.
  const wall = `${poly(far)} ${poly([...far].reverse(), 0, 30)}`;

  // Static noise inside the rift.
  let noise = "";
  for (let k = 0; k < 520; k++) {
    const x = 110 + R() * 540, y = 166 + R() * 180;
    const w = 2 + R() * (R() < 0.15 ? 26 : 7), h = 2 + R() * 3;
    const r = R();
    const c = r < 0.38 ? MG : r < 0.76 ? CY : r < 0.9 ? "#ffffff" : "#6f6bff";
    noise += `<rect x="${x.toFixed(1)}" y="${y.toFixed(1)}" width="${w.toFixed(1)}" height="${h.toFixed(1)}" fill="${c}" opacity="${(0.15 + R() * 0.6).toFixed(2)}"/>`;
  }
  // Displaced horizontal glitch bands.
  let bands = "";
  for (let k = 0; k < 14; k++) {
    const y = 172 + R() * 170, h = 2 + R() * 9, x = 100 + R() * 300, w = 80 + R() * 260;
    bands += `<rect x="${x.toFixed(1)}" y="${y.toFixed(1)}" width="${w.toFixed(1)}" height="${h.toFixed(1)}" fill="${R() < 0.5 ? MG : CY}" opacity="${(0.25 + R() * 0.35).toFixed(2)}"/>`;
  }
  // Scanlines.
  let scan = "";
  for (let y = 160; y < 350; y += 4) scan += `<rect x="100" y="${y}" width="560" height="1.6" fill="#05030f" opacity="0.45"/>`;

  // Floor grid in perspective (vanishing point high centre).
  let grid = "";
  const vy = -260;
  for (let k = -14; k <= 14; k++) {
    const xb = 360 + k * 70;
    grid += `<line x1="${360 + (xb - 360) * ((150 - vy) / (440 - vy))}" y1="150" x2="${xb}" y2="440"/>`;
  }
  for (let k = 0; k < 9; k++) {
    const t = k / 8;
    const y = 150 + Math.pow(t, 1.7) * 290;
    grid += `<line x1="0" y1="${y.toFixed(1)}" x2="720" y2="${y.toFixed(1)}"/>`;
  }

  // Floating pixel debris rising out of the rift (chunks of floor tiles + pixels).
  let debris = "";
  for (let k = 0; k < 38; k++) {
    const x = 140 + R() * 460, y = 40 + R() * 200;
    const s = 3 + R() * 9;
    const c = R() < 0.45 ? MG : R() < 0.85 ? CY : "#fff";
    debris += `<rect x="${x.toFixed(1)}" y="${y.toFixed(1)}" width="${s.toFixed(1)}" height="${s.toFixed(1)}" fill="${c}" opacity="${(0.35 + R() * 0.55).toFixed(2)}"/>`;
  }
  const chunk = (x, y, s, rot) => `<g transform="translate(${x} ${y}) rotate(${rot})">
      <rect x="${-s - 2}" y="${-s * 0.6}" width="${s * 2}" height="${s * 1.2}" fill="${MG}" opacity="0.6"/>
      <rect x="${-s + 2}" y="${-s * 0.6}" width="${s * 2}" height="${s * 1.2}" fill="${CY}" opacity="0.6"/>
      <rect x="${-s}" y="${-s * 0.6}" width="${s * 2}" height="${s * 1.2}" fill="#2a2470" stroke="#8f7bff" stroke-width="1.5"/>
      <rect x="${-s}" y="${s * 0.25}" width="${s * 2}" height="${s * 0.35}" fill="#151038"/>
    </g>`;

  // The golden orb with pixel-step halo and sparkles.
  const twinkle = (x, y, s, col) =>
    `<path d="M ${x} ${y - s} Q ${x} ${y} ${x + s} ${y} Q ${x} ${y} ${x} ${y + s} Q ${x} ${y} ${x - s} ${y} Q ${x} ${y} ${x} ${y - s} Z" fill="${col}"/>`;
  let pxHalo = "";
  for (let k = 0; k < 18; k++) {
    const a = (k / 18) * Math.PI * 2 + R() * 0.2, d = 50 + R() * 26;
    const s = 3 + R() * 5;
    pxHalo += `<rect x="${(ox + Math.cos(a) * d - s / 2).toFixed(1)}" y="${(oy + Math.sin(a) * d - s / 2).toFixed(1)}" width="${s.toFixed(1)}" height="${s.toFixed(1)}" fill="${R() < 0.7 ? "#ffe680" : "#fff"}" opacity="${(0.5 + R() * 0.5).toFixed(2)}"/>`;
  }
  const orbR = 38;
  const orb = `
    <circle cx="${ox}" cy="${oy}" r="${orbR * 3}" fill="${GOLD}" opacity="0.28" filter="url(#grBlurL)"/>
    <circle cx="${ox}" cy="${oy}" r="${orbR * 1.5}" fill="#ffe680" opacity="0.6" filter="url(#grBlurM)"/>
    <!-- chromatic ghosts of the orb -->
    <circle cx="${ox - 5}" cy="${oy}" r="${orbR}" fill="${MG}" opacity="0.55"/>
    <circle cx="${ox + 5}" cy="${oy}" r="${orbR}" fill="${CY}" opacity="0.55"/>
    <circle cx="${ox}" cy="${oy}" r="${orbR}" fill="url(#grOrb)" stroke="#b07a10" stroke-width="2.5"/>
    <circle cx="${ox}" cy="${oy}" r="${orbR * 0.62}" fill="none" stroke="#fff6c8" stroke-width="2" opacity="0.55"/>
    <path d="M ${ox - orbR * 0.62} ${oy - orbR * 0.2} A ${orbR * 0.66} ${orbR * 0.66} 0 0 1 ${ox - orbR * 0.05} ${oy - orbR * 0.66}" fill="none" stroke="#fff" stroke-width="5" stroke-linecap="round" opacity="0.85"/>
    <circle cx="${ox + orbR * 0.42}" cy="${oy + orbR * 0.45}" r="3" fill="#fff" opacity="0.7"/>
    <!-- a slice of the orb displaced sideways: glitch -->
    <g clip-path="url(#grSlice)"><circle cx="${ox + 10}" cy="${oy}" r="${orbR}" fill="url(#grOrb)"/></g>
    ${pxHalo}
    ${twinkle(ox + 50, oy - 40, 12, "#fff6c8")}${twinkle(ox - 56, oy + 26, 8, "#ffe680")}${twinkle(ox + 30, oy + 54, 6, "#fff")}`;

  // Critter on the right lip of the rift, leaning over to peer in.
  const kx = 572, ky = 284, kr = 36, kc = "#5FD068";
  const critter = `
    <ellipse cx="${kx + 4}" cy="${ky + kr - 2}" rx="${kr * 1.05}" ry="8" fill="#000" opacity="0.45"/>
    <g transform="rotate(-16 ${kx} ${ky + kr})">
      ${ball(kx, ky, kr, kc, { glow: false })}
      <!-- rift light washing its left side -->
      <path d="M ${kx - kr * 0.2} ${ky + kr * 0.98} A ${kr} ${kr} 0 0 1 ${kx - kr * 0.6} ${ky - kr * 0.8}" fill="none" stroke="${CY}" stroke-width="4" opacity="0.8" stroke-linecap="round"/>
      <path d="M ${kx - kr * 0.85} ${ky + kr * 0.5} A ${kr} ${kr} 0 0 1 ${kx - kr * 0.95} ${ky - kr * 0.2}" fill="none" stroke="${GOLD}" stroke-width="3" opacity="0.7" stroke-linecap="round"/>
      <path d="M ${kx - 6} ${ky - kr + 4} l -4 -16 l 8 6 l 4 -12 l 4 16 Z" fill="${shade(kc, 0.35)}" stroke="${shade(kc, -0.5)}" stroke-width="2.5" stroke-linejoin="round"/>
      ${eye(kx - 14, ky - 4, 9, 12, -0.85, 0.5, 5)}${eye(kx + 8, ky - 4, 9, 12, -0.85, 0.5, 5)}
      <ellipse cx="${kx - 8}" cy="${ky + 16}" rx="5" ry="6" fill="${INK}"/>
      <ellipse cx="${kx - 8}" cy="${ky + 18}" rx="3" ry="2.4" fill="#ff7ab8"/>
      <!-- gold reflected in its eyes -->
      <circle cx="${kx - 20}" cy="${ky - 1}" r="1.8" fill="${GOLD}"/><circle cx="${kx + 2}" cy="${ky - 1}" r="1.8" fill="${GOLD}"/>
    </g>
`;

  return `<svg xmlns="http://www.w3.org/2000/svg" width="720" height="440" viewBox="0 0 720 440">
  <defs>
    <linearGradient id="grSky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#090818"/><stop offset="0.6" stop-color="#1a1240"/><stop offset="1" stop-color="#2a1a5e"/>
    </linearGradient>
    <linearGradient id="grFloor" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#1e1850"/><stop offset="0.5" stop-color="#16123e"/><stop offset="1" stop-color="#0a0820"/>
    </linearGradient>
    <linearGradient id="grDeep" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#05030f"/><stop offset="0.5" stop-color="#1a0a3a"/><stop offset="1" stop-color="#05030f"/>
    </linearGradient>
    <linearGradient id="grWall" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#3a2e8a"/><stop offset="0.3" stop-color="#1a1448"/><stop offset="1" stop-color="#08061a" stop-opacity="0"/>
    </linearGradient>
    <radialGradient id="grOrb" cx="0.36" cy="0.32" r="0.8">
      <stop offset="0" stop-color="#fffbe0"/><stop offset="0.35" stop-color="#ffe680"/><stop offset="0.75" stop-color="${GOLD}"/><stop offset="1" stop-color="#d89a12"/>
    </radialGradient>
    <radialGradient id="grGlowFloor" cx="50%" cy="50%" r="50%">
      <stop offset="0" stop-color="${MG}" stop-opacity="0.45"/><stop offset="0.5" stop-color="#6f6bff" stop-opacity="0.18"/><stop offset="1" stop-color="#6f6bff" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="grVig" cx="50%" cy="48%" r="72%">
      <stop offset="0.55" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.7"/>
    </radialGradient>
    <clipPath id="grClip"><polygon points="${rift}"/></clipPath>
    <clipPath id="grSlice"><rect x="${ox - 60}" y="${oy + 6}" width="120" height="9"/></clipPath>
    <filter id="grBlurS" x="-40%" y="-40%" width="180%" height="180%"><feGaussianBlur stdDeviation="3"/></filter>
    <filter id="grBlurM" x="-80%" y="-80%" width="260%" height="260%"><feGaussianBlur stdDeviation="10"/></filter>
    <filter id="grBlurL" x="-80%" y="-80%" width="260%" height="260%"><feGaussianBlur stdDeviation="26"/></filter>
  </defs>

  <rect width="720" height="440" fill="url(#grSky)"/>
  <!-- arena back wall: stadium rim with neon strip and far lights -->
  <path d="M 0 150 Q 360 112 720 150 L 720 0 L 0 0 Z" fill="#0c0a24"/>
  <path d="M 0 120 Q 360 82 720 120 L 720 150 Q 360 112 0 150 Z" fill="#17123c"/>
  ${[...Array(18)].map((_, k) => { const x = 20 + k * 40; const y = 108 - Math.sin((x / 720) * Math.PI) * 30; return `<rect x="${x}" y="${y}" width="22" height="10" rx="2" fill="#241c5a"/>`; }).join("")}
  <path d="M 0 150 Q 360 112 720 150" fill="none" stroke="#8f7bff" stroke-width="7" opacity="0.5" filter="url(#grBlurS)"/>
  <path d="M 0 150 Q 360 112 720 150" fill="none" stroke="#c2b5ff" stroke-width="2.5"/>
  ${[90, 250, 470, 630].map((x) => `<circle cx="${x}" cy="40" r="26" fill="#8f7bff" opacity="0.22" filter="url(#grBlurM)"/><circle cx="${x}" cy="40" r="5" fill="#d9d0ff"/>`).join("")}

  <!-- arena floor -->
  <path d="M 0 150 Q 360 112 720 150 L 720 440 L 0 440 Z" fill="url(#grFloor)"/>
  <g stroke="#8f7bff" stroke-opacity="0.16" stroke-width="1.5">${grid}</g>
  <ellipse cx="360" cy="262" rx="360" ry="150" fill="url(#grGlowFloor)"/>

  <!-- floor crack lines spreading from the rift -->
  <g fill="none" stroke="${CY}" stroke-width="2" opacity="0.7" stroke-linejoin="round">
    <path d="M 118 262 L 80 270 L 56 262 L 20 278"/><path d="M 636 250 L 668 244 L 690 256 L 720 250"/>
    <path d="M 352 340 L 344 372 L 356 396 L 340 440"/><path d="M 486 312 L 506 340 L 540 352"/>
    <path d="M 226 318 L 206 346 L 170 356"/><path d="M 326 178 L 318 160"/><path d="M 452 176 L 462 158"/>
  </g>
  <g fill="none" stroke="${MG}" stroke-width="2" opacity="0.5" stroke-linejoin="round" transform="translate(-3 1)">
    <path d="M 118 262 L 80 270 L 56 262 L 20 278"/><path d="M 352 340 L 344 372 L 356 396 L 340 440"/><path d="M 226 318 L 206 346 L 170 356"/>
  </g>

  <!-- the rift: deep void, static, bands, scanlines -->
  <polygon points="${rift}" fill="${MG}" opacity="0.55" filter="url(#grBlurM)"/>
  <polygon points="${rift}" fill="url(#grDeep)"/>
  <g clip-path="url(#grClip)">
    ${noise}
    ${bands}
    <polygon points="${wall}" fill="url(#grWall)"/>
    ${[...Array(9)].map((_, k) => `<line x1="${far[k * 2][0]}" y1="${far[k * 2][1]}" x2="${far[k * 2][0]}" y2="${far[k * 2][1] + 26}" stroke="#05030f" stroke-width="2"/>`).join("")}
    <ellipse cx="${ox}" cy="${oy + 10}" rx="190" ry="70" fill="${GOLD}" opacity="0.18" filter="url(#grBlurM)"/>
    <ellipse cx="${ox}" cy="350" rx="260" ry="40" fill="${MG}" opacity="0.35" filter="url(#grBlurM)"/>
    ${scan}
  </g>
  <!-- chromatic aberration edge -->
  <polygon points="${poly(riftPts, -4, 0)}" fill="none" stroke="${MG}" stroke-width="3" stroke-linejoin="round" opacity="0.95"/>
  <polygon points="${poly(riftPts, 4, 1)}" fill="none" stroke="${CY}" stroke-width="3" stroke-linejoin="round" opacity="0.95"/>
  <polygon points="${rift}" fill="none" stroke="#ffffff" stroke-width="1.6" stroke-linejoin="round" opacity="0.9"/>
  <!-- near lip: floor slab thickness catching light -->
  <polyline points="${poly(near, 0, 3)}" fill="none" stroke="#2a2470" stroke-width="6" stroke-linejoin="round"/>

  <!-- floating floor chunks -->
  ${chunk(208, 150, 14, -18)}${chunk(520, 132, 11, 22)}${chunk(440, 92, 8, -8)}${chunk(270, 86, 7, 30)}
  ${debris}

  <!-- the golden orb -->
  <!-- living layers (render.mjs): the orb hovers, the critter idles -->
  <g data-layer="orb" data-move="bob 6 0.6 0">${orb}</g>

  <g data-layer="critter" data-move="idle 4 0.7 0.4">${critter}</g>

  <!-- foreground floor slab corner, left, framing -->
  <path d="M 0 360 L 120 372 L 150 440 L 0 440 Z" fill="#0d0a26"/>
  <path d="M 0 360 L 120 372 L 150 440" fill="none" stroke="#8f7bff" stroke-width="2" opacity="0.5"/>

  <!-- whole-frame glitch slices -->
  <rect x="0" y="58" width="720" height="3" fill="${CY}" opacity="0.18"/>
  <rect x="0" y="386" width="720" height="2" fill="${MG}" opacity="0.22"/>
  <rect width="720" height="440" fill="url(#grVig)"/>
</svg>`;
}

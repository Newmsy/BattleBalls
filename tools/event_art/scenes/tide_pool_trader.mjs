// Tide pool trader: a hermit-crab merchant critter (Sea family) in a big
// decorated shell beside a glowing tide pool at night, holding up two critter
// balls in bubbles to trade. The right one has a gold rim: the "upgrade".
import { ball, eye, brow, shade } from "../../brand/parts.mjs";

const SEA = "#3EA8FF";
const W = 720, H = 440;

// Small 4-point twinkle.
const twinkle = (x, y, s, col = "#fff", o = 1) =>
  `<path d="M ${x} ${y - s} Q ${x} ${y} ${x + s} ${y} Q ${x} ${y} ${x} ${y + s} Q ${x} ${y} ${x - s} ${y} Q ${x} ${y} ${x} ${y - s} Z" fill="${col}" opacity="${o}"/>`;

// A Button (shop currency): cream/gold disc, teal rim, four holes.
const button = (x, y, r, rot = 0) => `
  <g transform="rotate(${rot} ${x} ${y})">
    <ellipse cx="${x + r * 0.1}" cy="${y + r * 0.18}" rx="${r}" ry="${r * 0.9}" fill="#000" opacity="0.35"/>
    <circle cx="${x}" cy="${y}" r="${r}" fill="#2bb7a8"/>
    <circle cx="${x}" cy="${y}" r="${r * 0.8}" fill="url(#tpButton)"/>
    <circle cx="${x}" cy="${y}" r="${r * 0.62}" fill="none" stroke="#c99a3c" stroke-width="${r * 0.08}" opacity="0.7"/>
    ${[[-1, -1], [1, -1], [-1, 1], [1, 1]].map(([a, b]) => `<circle cx="${x + a * r * 0.24}" cy="${y + b * r * 0.24}" r="${r * 0.12}" fill="#6b4a1c"/>`).join("")}
    <ellipse cx="${x - r * 0.35}" cy="${y - r * 0.4}" rx="${r * 0.28}" ry="${r * 0.14}" fill="#fff" opacity="0.6" transform="rotate(-35 ${x - r * 0.35} ${y - r * 0.4})"/>
  </g>`;

// A small critter ball with a simple happy face.
function mini(cx, cy, r, col, { look = [0, 0], mood = "smile" } = {}) {
  const ey = cy - r * 0.12;
  const mouth =
    mood === "o"
      ? `<ellipse cx="${cx}" cy="${cy + r * 0.38}" rx="${r * 0.12}" ry="${r * 0.15}" fill="#14102e"/>`
      : `<path d="M ${cx - r * 0.28} ${cy + r * 0.3} Q ${cx} ${cy + r * 0.6} ${cx + r * 0.28} ${cy + r * 0.3}" fill="none" stroke="#14102e" stroke-width="${r * 0.1}" stroke-linecap="round"/>`;
  return `${ball(cx, cy, r, col, { glow: false })}
    ${eye(cx - r * 0.32, ey, r * 0.2, r * 0.26, look[0], look[1], r * 0.11)}
    ${eye(cx + r * 0.32, ey, r * 0.2, r * 0.26, look[0], look[1], r * 0.11)}
    ${mouth}`;
}

// A trade bubble holding a critter; gold = rare rim with sparkles.
function bubble(cx, cy, r, inner, gold) {
  const rim = gold
    ? `<circle cx="${cx}" cy="${cy}" r="${r + 6}" fill="none" stroke="#ffd23f" stroke-width="10" opacity="0.5" filter="url(#tpBlur6)"/>
       <circle cx="${cx}" cy="${cy}" r="${r + 1}" fill="none" stroke="url(#tpGold)" stroke-width="6"/>
       <circle cx="${cx}" cy="${cy}" r="${r - 4}" fill="none" stroke="#fff1b0" stroke-width="1.5" opacity="0.8"/>
       ${twinkle(cx + r * 0.78, cy - r * 0.8, 13, "#fff6c8")}
       ${twinkle(cx - r * 0.95, cy + r * 0.45, 8, "#ffe27a")}
       ${twinkle(cx + r * 1.05, cy + r * 0.35, 6, "#fff6c8", 0.8)}`
    : `<circle cx="${cx}" cy="${cy}" r="${r}" fill="none" stroke="#bfe8ff" stroke-width="3" opacity="0.75"/>`;
  return `
  <circle cx="${cx}" cy="${cy}" r="${r * 1.25}" fill="${gold ? "#ffd23f" : "#7fd0ff"}" opacity="${gold ? 0.22 : 0.16}" filter="url(#tpBlur18)"/>
  <circle cx="${cx}" cy="${cy}" r="${r}" fill="url(#tpBubble)"/>
  ${inner}
  <circle cx="${cx}" cy="${cy}" r="${r}" fill="url(#tpBubbleSheen)"/>
  ${rim}
  <path d="M ${cx - r * 0.72} ${cy - r * 0.2} A ${r * 0.76} ${r * 0.76} 0 0 1 ${cx - r * 0.1} ${cy - r * 0.74}" fill="none" stroke="#fff" stroke-width="${r * 0.09}" stroke-linecap="round" opacity="0.75"/>
  <circle cx="${cx + r * 0.5}" cy="${cy + r * 0.55}" r="${r * 0.06}" fill="#fff" opacity="0.6"/>`;
}

// The hermit crab: big spiral shell (behind), Sea-blue ball body, eye stalks,
// claws reaching out to the two bubbles.
function crab(cx, cy, r) {
  const sx = cx + r * 0.55, sy = cy - r * 0.75; // shell centre
  // Spiral shell: a stack of shrinking whorls.
  let whorls = "";
  const steps = [
    [0, 0, 1.7, "#c2477a"],
    [0.2, -0.14, 1.28, "#d9588c"],
    [0.36, -0.28, 0.9, "#e872a2"],
    [0.42, -0.34, 0.55, "#f48fb8"],
    [0.48, -0.4, 0.3, "#ffb0cf"],
  ];
  for (const [ox, oy, k, col] of steps) {
    const x = sx + ox * r, y = sy + oy * r;
    whorls += `<ellipse cx="${x}" cy="${y}" rx="${r * k}" ry="${r * k * 0.92}" fill="${col}" stroke="${shade(col, -0.45)}" stroke-width="${r * 0.045}"/>
      <ellipse cx="${x - r * k * 0.3}" cy="${y - r * k * 0.42}" rx="${r * k * 0.42}" ry="${r * k * 0.16}" fill="#fff" opacity="0.22" transform="rotate(-30 ${x - r * k * 0.3} ${y - r * k * 0.42})"/>`;
  }
  // Ridges along the outer whorl.
  let ridges = "";
  for (let k = 0; k < 9; k++) {
    const a = Math.PI * 0.95 + k * 0.32;
    const x1 = sx + Math.cos(a) * r * 1.2, y1 = sy + Math.sin(a) * r * 1.1;
    const x2 = sx + Math.cos(a) * r * 1.5, y2 = sy + Math.sin(a) * r * 1.38;
    ridges += `<line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" stroke="#8a2c57" stroke-width="${r * 0.05}" stroke-linecap="round" opacity="0.7"/>`;
  }
  // Decorations: pearls, a sea-glass gem, a little lantern hanging off the tip.
  const pearl = (x, y, pr) => `<circle cx="${x}" cy="${y}" r="${pr}" fill="url(#tpPearl)" stroke="#a88fb0" stroke-width="1"/>`;
  const deco = `
    ${pearl(sx - r * 1.05, sy + r * 0.5, r * 0.11)}${pearl(sx - r * 0.82, sy + r * 0.85, r * 0.09)}${pearl(sx - r * 1.25, sy + r * 0.05, r * 0.08)}
    ${pearl(sx + r * 1.35, sy + r * 0.3, r * 0.1)}${pearl(sx + r * 1.12, sy + r * 0.8, r * 0.08)}
    <polygon points="${sx + r * 0.95},${sy - r * 0.95} ${sx + r * 1.15},${sy - r * 0.78} ${sx + r * 1.02},${sy - r * 0.52} ${sx + r * 0.8},${sy - r * 0.7}" fill="#5CFFD8" stroke="#1d8f86" stroke-width="2"/>
    <polygon points="${sx + r * 0.95},${sy - r * 0.95} ${sx + r * 1.15},${sy - r * 0.78} ${sx + r * 0.96},${sy - r * 0.76}" fill="#d8fff6" opacity="0.8"/>
    ${button(sx - r * 0.35, sy - r * 1.0, r * 0.2, 15)}
    ${button(sx + r * 0.6, sy + r * 1.05, r * 0.17, -20)}`;
  // Lantern on a string from the shell tip.
  const tx = sx + r * 0.95, ty = sy - r * 0.95;
  const lantern = `
    <path d="M ${sx + r * 0.6} ${sy - r * 0.62} Q ${sx + r * 1.4} ${sy - r * 1.3} ${sx + r * 1.75} ${sy - r * 0.75}" fill="none" stroke="#3a2a55" stroke-width="3"/>
    <line x1="${sx + r * 1.75}" y1="${sy - r * 0.75}" x2="${sx + r * 1.75}" y2="${sy - r * 0.5}" stroke="#3a2a55" stroke-width="2.5"/>
    <circle cx="${sx + r * 1.75}" cy="${sy - r * 0.28}" r="${r * 0.6}" fill="#ffcf6b" opacity="0.35" filter="url(#tpBlur18)"/>
    <rect x="${sx + r * 1.6}" y="${sy - r * 0.52}" width="${r * 0.3}" height="${r * 0.08}" rx="3" fill="#6b4a1c"/>
    <ellipse cx="${sx + r * 1.75}" cy="${sy - r * 0.28}" rx="${r * 0.17}" ry="${r * 0.21}" fill="url(#tpLamp)" stroke="#8a5a1c" stroke-width="2"/>
    <rect x="${sx + r * 1.63}" y="${sy - r * 0.09}" width="${r * 0.24}" height="${r * 0.07}" rx="3" fill="#6b4a1c"/>`;
  void tx; void ty;

  // Legs peeking from below the body.
  const leg = (x, dir) =>
    `<path d="M ${x} ${cy + r * 0.6} q ${dir * r * 0.35} ${r * 0.05} ${dir * r * 0.5} ${r * 0.42}" fill="none" stroke="${shade(SEA, -0.45)}" stroke-width="${r * 0.2}" stroke-linecap="round"/>
     <path d="M ${x} ${cy + r * 0.6} q ${dir * r * 0.35} ${r * 0.05} ${dir * r * 0.5} ${r * 0.42}" fill="none" stroke="${shade(SEA, -0.1)}" stroke-width="${r * 0.11}" stroke-linecap="round"/>`;

  // Claw arm reaching to (tx, ty), pincer cupped up under the bubble.
  const claw = (x0, y0, x1, y1, dir) => {
    const mx = (x0 + x1) / 2 + dir * r * 0.05, my = Math.max(y0, y1) + r * 0.25;
    const pc = shade("#ff8a5c", 0);
    return `
    <path d="M ${x0} ${y0} Q ${mx} ${my} ${x1} ${y1}" fill="none" stroke="${shade(SEA, -0.5)}" stroke-width="${r * 0.26}" stroke-linecap="round"/>
    <path d="M ${x0} ${y0} Q ${mx} ${my} ${x1} ${y1}" fill="none" stroke="${shade(SEA, -0.05)}" stroke-width="${r * 0.15}" stroke-linecap="round"/>
    <circle cx="${mx}" cy="${my - r * 0.12}" r="${r * 0.12}" fill="${shade(SEA, -0.15)}" stroke="${shade(SEA, -0.5)}" stroke-width="3"/>
    <g transform="translate(${x1} ${y1})">
      <path d="M ${-dir * r * 0.05} ${r * 0.1} C ${-dir * r * 0.45} ${r * 0.05} ${-dir * r * 0.5} ${-r * 0.35} ${-dir * r * 0.22} ${-r * 0.42} C ${-dir * r * 0.18} ${-r * 0.2} ${dir * r * 0.0} ${-r * 0.1} ${dir * r * 0.05} ${-r * 0.02} Z"
        fill="${pc}" stroke="${shade(pc, -0.5)}" stroke-width="3.5" stroke-linejoin="round"/>
      <path d="M ${dir * r * 0.05} ${r * 0.12} C ${dir * r * 0.4} ${r * 0.08} ${dir * r * 0.48} ${-r * 0.25} ${dir * r * 0.3} ${-r * 0.36} C ${dir * r * 0.22} ${-r * 0.16} ${dir * r * 0.08} ${-r * 0.06} ${-dir * r * 0.02} ${-r * 0.0} Z"
        fill="${shade(pc, -0.1)}" stroke="${shade(pc, -0.5)}" stroke-width="3.5" stroke-linejoin="round"/>
      <ellipse cx="${-dir * r * 0.22}" cy="${-r * 0.22}" rx="${r * 0.07}" ry="${r * 0.14}" fill="#fff" opacity="0.4" transform="rotate(${dir * 20} ${-dir * r * 0.22} ${-r * 0.22})"/>
    </g>`;
  };

  // Eyes on the face; two feelers on top; one brow cocked (salesman).
  const ey = cy - r * 0.22;
  const exL = cx - r * 0.34, exR = cx + r * 0.34;
  const feeler = (x0, x1, y1) =>
    `<path d="M ${x0} ${cy - r * 0.85} Q ${(x0 + x1) / 2} ${y1 + r * 0.05} ${x1} ${y1}" fill="none" stroke="${shade(SEA, -0.5)}" stroke-width="${r * 0.09}" stroke-linecap="round"/>
     <circle cx="${x1}" cy="${y1}" r="${r * 0.09}" fill="#9be8ff" stroke="${shade(SEA, -0.5)}" stroke-width="2"/>`;
  return `
  <!-- shell -->
  <g>
    <ellipse cx="${sx + r * 0.1}" cy="${sy + r * 0.2}" rx="${r * 1.9}" ry="${r * 1.7}" fill="#ff7fb8" opacity="0.12" filter="url(#tpBlur18)"/>
    ${whorls}${ridges}${deco}
  </g>
  ${feeler(cx - r * 0.2, cx - r * 0.45, cy - r * 1.45)}${feeler(cx + r * 0.15, cx + r * 0.2, cy - r * 1.55)}
  ${leg(cx - r * 0.55, -1)}${leg(cx - r * 0.2, -1)}${leg(cx + r * 0.3, 1)}${leg(cx + r * 0.62, 1)}
  ${ball(cx, cy, r, SEA, { glow: false })}
  <!-- pool light from below -->
  <ellipse cx="${cx}" cy="${cy + r * 0.62}" rx="${r * 0.78}" ry="${r * 0.3}" fill="#7ff0ff" opacity="0.35" filter="url(#tpBlur6)"/>
  <ellipse cx="${cx + r * 0.1}" cy="${cy + r * 0.25}" rx="${r * 0.4}" ry="${r * 0.22}" fill="${shade(SEA, 0.5)}" opacity="0.35"/>
  ${eye(exL, ey, r * 0.23, r * 0.28, 0.6, -0.2, r * 0.12)}
  ${eye(exR, ey, r * 0.23, r * 0.28, 0.6, -0.2, r * 0.12)}
  <ellipse cx="${exL}" cy="${ey - r * 0.17}" rx="${r * 0.25}" ry="${r * 0.12}" fill="${shade(SEA, -0.15)}"/>
  ${brow(exL - r * 0.24, ey - r * 0.38, exL + r * 0.2, ey - r * 0.3, r * 0.08)}
  ${brow(exR - r * 0.2, ey - r * 0.46, exR + r * 0.26, ey - r * 0.56, r * 0.08)}
  <!-- sly merchant smirk -->
  <path d="M ${cx - r * 0.32} ${cy + r * 0.22} Q ${cx + r * 0.05} ${cy + r * 0.58} ${cx + r * 0.42} ${cy + r * 0.12}" fill="#14102e" stroke="#14102e" stroke-width="${r * 0.06}" stroke-linejoin="round"/>
  <path d="M ${cx - r * 0.26} ${cy + r * 0.24} Q ${cx + r * 0.05} ${cy + r * 0.34} ${cx + r * 0.36} ${cy + r * 0.16} L ${cx + r * 0.3} ${cy + r * 0.25} Q ${cx + r * 0.05} ${cy + r * 0.36} ${cx - r * 0.2} ${cy + r * 0.3} Z" fill="#fff"/>
  <ellipse cx="${cx - r * 0.62}" cy="${cy + r * 0.2}" rx="${r * 0.13}" ry="${r * 0.08}" fill="#ff8ad0" opacity="0.45"/>
  <ellipse cx="${cx + r * 0.66}" cy="${cy + r * 0.14}" rx="${r * 0.13}" ry="${r * 0.08}" fill="#ff8ad0" opacity="0.45"/>
  ${claw(cx - r * 0.85, cy + r * 0.1, cx - r * 2.95, cy - r * 0.3, -1)}
  ${claw(cx + r * 0.85, cy + r * 0.1, cx + r * 3.0, cy - r * 0.38, 1)}`;
}

function rock(d, col = "#1c1a44", lit = "#3a3a7a") {
  return `<path d="${d}" fill="${col}" stroke="#0a0920" stroke-width="2"/>
    <path d="${d}" fill="url(#tpRockLit)" opacity="0.9"/>
    <path d="${d}" fill="none" stroke="${lit}" stroke-width="2" opacity="0.5"/>`;
}

function seaweed(x, y, h, col, sway) {
  return `<path d="M ${x} ${y} C ${x + sway} ${y - h * 0.3} ${x - sway} ${y - h * 0.6} ${x + sway * 0.6} ${y - h}" fill="none" stroke="${shade(col, -0.4)}" stroke-width="10" stroke-linecap="round"/>
    <path d="M ${x} ${y} C ${x + sway} ${y - h * 0.3} ${x - sway} ${y - h * 0.6} ${x + sway * 0.6} ${y - h}" fill="none" stroke="${col}" stroke-width="5" stroke-linecap="round"/>`;
}

function starfish(x, y, r, col, rot) {
  let d = "";
  for (let k = 0; k < 10; k++) {
    const a = (rot + k * 36 - 90) * (Math.PI / 180);
    const rr = k % 2 ? r * 0.45 : r;
    d += `${k ? "L" : "M"} ${x + Math.cos(a) * rr} ${y + Math.sin(a) * rr} `;
  }
  return `<path d="${d}Z" fill="${col}" stroke="${shade(col, -0.5)}" stroke-width="2.5" stroke-linejoin="round"/>
    <circle cx="${x}" cy="${y}" r="${r * 0.15}" fill="${shade(col, 0.4)}"/>`;
}

export default function () {
  // Stars
  let stars = "";
  let seed = 7;
  const rnd = () => ((seed = (seed * 16807) % 2147483647) / 2147483647);
  for (let k = 0; k < 70; k++) {
    const x = rnd() * W, y = rnd() * 170, s = rnd();
    stars += `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="${(0.6 + s * 1.4).toFixed(2)}" fill="#dfe8ff" opacity="${(0.25 + s * 0.6).toFixed(2)}"/>`;
  }
  // Glints on the sea
  let glints = "";
  for (let k = 0; k < 26; k++) {
    const y = 192 + rnd() * 40, x = 262 + (rnd() - 0.5) * (60 + (y - 190) * 3);
    glints += `<rect x="${x.toFixed(1)}" y="${y.toFixed(1)}" width="${(6 + rnd() * 16).toFixed(1)}" height="1.6" rx="0.8" fill="#cfe6ff" opacity="${(0.25 + rnd() * 0.45).toFixed(2)}"/>`;
  }
  // Rising bubbles in the pool
  let bubs = "";
  for (let k = 0; k < 14; k++) {
    const x = 170 + rnd() * 380, y = 340 + rnd() * 70, r = 2 + rnd() * 5;
    bubs += `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="${r.toFixed(1)}" fill="none" stroke="#c8fbff" stroke-width="1.3" opacity="${(0.35 + rnd() * 0.4).toFixed(2)}"/>`;
  }
  // Trail bubbles under each trade bubble
  const trail = (x, y) =>
    [[0, 0, 7], [-10, 26, 5], [6, 46, 3.5]].map(([dx, dy, r]) => `<circle cx="${x + dx}" cy="${y + dy}" r="${r}" fill="url(#tpBubble)" stroke="#c8f0ff" stroke-width="1.4" opacity="0.8"/>`).join("");

  const cx = 360, cy = 262, r = 62;
  const bl = [178, 156, 60], br = [552, 148, 64];

  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">
  <defs>
    <linearGradient id="tpSky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#0D0F26"/><stop offset="0.6" stop-color="#141038"/><stop offset="1" stop-color="#2c2170"/>
    </linearGradient>
    <linearGradient id="tpSea" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#1d2a6e"/><stop offset="1" stop-color="#0e1336"/>
    </linearGradient>
    <radialGradient id="tpMoon" cx="0.4" cy="0.4" r="0.7">
      <stop offset="0" stop-color="#ffffff"/><stop offset="0.6" stop-color="#e6ecff"/><stop offset="1" stop-color="#aeb9ef"/>
    </radialGradient>
    <radialGradient id="tpPool" cx="0.5" cy="0.45" r="0.6">
      <stop offset="0" stop-color="#9bfbff"/><stop offset="0.35" stop-color="#3ee6ff"/><stop offset="0.75" stop-color="#2466c9"/><stop offset="1" stop-color="#162a6a"/>
    </radialGradient>
    <radialGradient id="tpBubble" cx="0.5" cy="0.5" r="0.5">
      <stop offset="0" stop-color="#9fdcff" stop-opacity="0.06"/><stop offset="0.75" stop-color="#7fc8ff" stop-opacity="0.16"/><stop offset="1" stop-color="#d6f2ff" stop-opacity="0.55"/>
    </radialGradient>
    <radialGradient id="tpBubbleSheen" cx="0.3" cy="0.25" r="0.9">
      <stop offset="0" stop-color="#ffffff" stop-opacity="0.28"/><stop offset="0.35" stop-color="#ffffff" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="tpGold" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#fff1b0"/><stop offset="0.45" stop-color="#ffd23f"/><stop offset="1" stop-color="#c98a14"/>
    </linearGradient>
    <radialGradient id="tpButton" cx="0.35" cy="0.3" r="0.8">
      <stop offset="0" stop-color="#fff6dc"/><stop offset="0.6" stop-color="#f3d58e"/><stop offset="1" stop-color="#c99a3c"/>
    </radialGradient>
    <radialGradient id="tpPearl" cx="0.35" cy="0.3" r="0.8">
      <stop offset="0" stop-color="#ffffff"/><stop offset="0.7" stop-color="#efe3f6"/><stop offset="1" stop-color="#bba6cc"/>
    </radialGradient>
    <radialGradient id="tpLamp" cx="0.45" cy="0.4" r="0.7">
      <stop offset="0" stop-color="#fffbe0"/><stop offset="0.6" stop-color="#ffd36b"/><stop offset="1" stop-color="#e08a2a"/>
    </radialGradient>
    <linearGradient id="tpRockLit" x1="0" y1="1" x2="0" y2="0">
      <stop offset="0" stop-color="#3ee6ff" stop-opacity="0.35"/><stop offset="0.5" stop-color="#3ee6ff" stop-opacity="0"/>
    </linearGradient>
    <filter id="tpBlur6" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="6"/></filter>
    <filter id="tpBlur18" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="18"/></filter>
    <filter id="tpBlur40" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="40"/></filter>
    <clipPath id="tpPoolClip"><ellipse cx="360" cy="378" rx="250" ry="46"/></clipPath>
  </defs>

  <!-- sky -->
  <rect width="${W}" height="${H}" fill="url(#tpSky)"/>
  ${stars}
  <circle cx="262" cy="58" r="70" fill="#9fb4ff" opacity="0.25" filter="url(#tpBlur18)"/>
  <circle cx="262" cy="58" r="26" fill="url(#tpMoon)"/>
  <circle cx="552" cy="62" r="30" fill="#141038" opacity="0.0"/>
  <circle cx="254" cy="52" r="4.5" fill="#c3cbef" opacity="0.6"/><circle cx="270" cy="66" r="3" fill="#c3cbef" opacity="0.6"/>

  <!-- sea + far rocks -->
  <rect x="0" y="190" width="${W}" height="250" fill="url(#tpSea)"/>
  <rect x="0" y="188" width="${W}" height="4" fill="#5b6fd0" opacity="0.35"/>
  ${glints}
  <path d="M 0 200 L 40 182 L 70 190 L 110 170 L 150 186 L 175 196 L 175 230 L 0 230 Z" fill="#161440" opacity="0.9"/>
  <path d="M 600 200 L 640 178 L 690 186 L 720 174 L 720 230 L 600 230 Z" fill="#161440" opacity="0.9"/>

  <!-- shore rocks (midground) -->
  ${rock("M -10 300 Q 20 240 90 250 Q 150 240 190 290 Q 240 320 260 360 L -10 380 Z", "#1a1842")}
  ${rock("M 720 290 Q 690 240 620 252 Q 560 248 520 300 Q 480 330 470 360 L 720 380 Z", "#1a1842")}
  ${rock("M 250 330 Q 280 296 360 300 Q 440 296 470 330 L 470 350 L 250 350 Z", "#221f52", "#4a4a9a")}
  ${seaweed(70, 300, 70, "#5CFF9A", 14)}${seaweed(92, 304, 48, "#3fd98a", -10)}
  ${seaweed(650, 296, 66, "#5CFF9A", -14)}${seaweed(628, 302, 42, "#3fd98a", 10)}

  <!-- the glowing tide pool -->
  <ellipse cx="360" cy="378" rx="300" ry="80" fill="#3ee6ff" opacity="0.35" filter="url(#tpBlur40)"/>
  <ellipse cx="360" cy="380" rx="262" ry="54" fill="#0c0b26"/>
  <ellipse cx="360" cy="378" rx="250" ry="46" fill="url(#tpPool)"/>
  <g clip-path="url(#tpPoolClip)">
    <ellipse cx="360" cy="352" rx="120" ry="16" fill="#3EA8FF" opacity="0.5" filter="url(#tpBlur6)"/>
    <ellipse cx="${cx}" cy="350" rx="70" ry="22" fill="#1a3a9a" opacity="0.55" filter="url(#tpBlur6)"/>
    <ellipse cx="420" cy="346" rx="70" ry="14" fill="#c2477a" opacity="0.3" filter="url(#tpBlur6)"/>
    <ellipse cx="380" cy="372" rx="60" ry="12" fill="#ffffff" opacity="0.18" filter="url(#tpBlur6)"/>
    <path d="M 160 372 Q 200 366 240 372 T 320 372" fill="none" stroke="#e3feff" stroke-width="2" opacity="0.5"/>
    <path d="M 400 392 Q 440 386 480 392 T 560 392" fill="none" stroke="#e3feff" stroke-width="2" opacity="0.4"/>
    <path d="M 250 404 Q 290 398 330 404" fill="none" stroke="#e3feff" stroke-width="2" opacity="0.35"/>
    ${starfish(230, 398, 16, "#FF8AD0", 10)}
    ${starfish(505, 404, 13, "#ffb35c", -15)}
    <circle cx="430" cy="410" r="8" fill="#c27bff" opacity="0.8"/><circle cx="444" cy="414" r="5" fill="#c27bff" opacity="0.7"/>
  </g>
  ${bubs}

  <!-- the trader -->
  <ellipse cx="${cx + 15}" cy="${cy + r * 0.95}" rx="${r * 1.6}" ry="${r * 0.25}" fill="#000" opacity="0.4" filter="url(#tpBlur6)"/>
  <!-- living layers (render.mjs): the trader idles, the trade bubbles float -->
  <g data-layer="crab" data-move="idle 3 0.6 0">${crab(cx, cy, r)}</g>

  <!-- trade bubbles -->
  <g data-layer="left" data-move="bob 6 0.5 0">${bubble(bl[0], bl[1], bl[2], mini(bl[0], bl[1] + 2, 34, "#5CFF9A", { look: [0.4, 0.1] }), false)}</g>
  <g data-layer="right" data-move="bob 6 0.5 0.5">${bubble(br[0], br[1], br[2], mini(br[0], br[1] + 2, 37, "#C9A6FF", { look: [-0.4, 0.1], mood: "o" }), true)}</g>

  <!-- foreground rocks, framing the pool -->
  ${rock("M -10 440 L -10 372 Q 30 350 80 366 Q 130 380 150 420 L 160 440 Z", "#141236", "#3a3a8a")}
  ${rock("M 730 440 L 730 362 Q 690 346 640 362 Q 590 380 575 420 L 570 440 Z", "#141236", "#3a3a8a")}
  ${button(118, 404, 13, 20)}${button(140, 418, 10, -10)}
  ${starfish(612, 400, 18, "#FF7A45", 20)}
  ${twinkle(300, 120, 6, "#cfe6ff", 0.8)}${twinkle(430, 40, 5, "#cfe6ff", 0.7)}
</svg>`;
}

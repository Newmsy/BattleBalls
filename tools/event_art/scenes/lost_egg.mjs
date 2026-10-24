// Lost Egg: a Common Nature summon egg in a mossy nest of glowing grass at
// night, tapping from inside: a short crack with green light leaking out.
import { egg } from "./_egg_parts.mjs";
import { shade } from "../../brand/parts.mjs";

const NAT = "#5CFF9A";

function seeded(seed) {
  let s = seed;
  return () => ((s = (s * 16807) % 2147483647) / 2147483647);
}

export default function lostEgg() {
  const R = seeded(11);
  const W = 720, H = 440;
  const ex = 362, ey = 232, es = 92; // egg centre and pixels per unit

  // Background trees: soft dark trunks and round canopies.
  const trees = [
    [60, 150, 120, "#121a3c"], [185, 125, 90, "#151e46"], [585, 130, 95, "#151e46"], [690, 160, 120, "#121a3c"],
    [-10, 220, 110, "#121a3c"], [740, 230, 110, "#121a3c"],
  ]
    .map(([x, y, r, c]) => `<rect x="${x - r * 0.08}" y="${y}" width="${r * 0.16}" height="${H}" fill="${shade(c, -0.25)}"/>
      <circle cx="${x}" cy="${y}" r="${r}" fill="${c}"/><circle cx="${x - r * 0.45}" cy="${y + r * 0.35}" r="${r * 0.7}" fill="${c}"/><circle cx="${x + r * 0.5}" cy="${y + r * 0.3}" r="${r * 0.65}" fill="${c}"/>
      <circle cx="${x - r * 0.25}" cy="${y - r * 0.3}" r="${r * 0.55}" fill="${shade(c, 0.06)}" opacity="0.5"/>`)
    .join("");

  // Stars.
  let stars = "";
  for (let k = 0; k < 40; k++) stars += `<circle cx="${R() * W}" cy="${R() * 140}" r="${0.6 + R() * 1.3}" fill="#e8ecff" opacity="${0.25 + R() * 0.6}"/>`;

  // Fireflies.
  const flies = [[150, 250], [210, 190], [520, 175], [600, 260], [280, 140], [470, 120], [110, 330], [640, 335], [430, 300]]
    .map(([x, y], k) => `<circle cx="${x}" cy="${y}" r="${7 + (k % 3) * 2}" fill="${NAT}" opacity="0.35" filter="url(#le_g6)"/><circle cx="${x}" cy="${y}" r="${1.8 + (k % 2)}" fill="#eaffef"/>`)
    .join("");

  // Grass blades: a curved tapering blade path.
  const blade = (x, y, h, lean, w, fill, op = 1) => {
    const tx = x + lean, ty = y - h;
    return `<path d="M ${x - w} ${y} Q ${x - w * 0.3 + lean * 0.35} ${y - h * 0.55} ${tx} ${ty} Q ${x + w * 0.5 + lean * 0.4} ${y - h * 0.5} ${x + w} ${y} Z" fill="${fill}" opacity="${op}"/>`;
  };
  // Back grass (dark) behind the nest and glowing grass tips.
  let backGrass = "", glowGrass = "", frontGrass = "";
  for (let k = 0; k < 46; k++) {
    const x = 30 + k * 14.5 + R() * 8;
    backGrass += blade(x, 352, 40 + R() * 45, (R() - 0.5) * 30, 5, "#173a3d");
  }
  for (let k = 0; k < 18; k++) {
    const side = k % 2 ? 1 : -1;
    const x = ex + side * (115 + R() * 120);
    const h = 45 + R() * 50;
    glowGrass += blade(x, 350, h, side * (8 + R() * 18), 3.5, "url(#le_blade)");
  }
  for (let k = 0; k < 34; k++) {
    const x = 25 + k * 21 + R() * 10;
    if (Math.abs(x - ex) < 120) continue;
    frontGrass += blade(x, 446, 55 + R() * 55, (R() - 0.5) * 34, 7, k % 3 ? "#0f2a2e" : "#13363a");
  }

  // Nest: back rim of twigs, the egg, then front rim, moss and twigs.
  const nx = ex, ny = 318;
  let twigsBack = "", twigsFront = "";
  for (let k = 0; k < 16; k++) {
    const a = Math.PI + (k / 15) * Math.PI;
    const x = nx + Math.cos(a) * 128, y = ny + Math.sin(a) * 26;
    const len = 50 + R() * 30, r = (R() - 0.5) * 0.8 + (Math.cos(a) * 0.3);
    twigsBack += `<line x1="${x - Math.cos(r) * len / 2}" y1="${y - Math.sin(r) * len / 2}" x2="${x + Math.cos(r) * len / 2}" y2="${y + Math.sin(r) * len / 2}" stroke="${k % 2 ? "#4a3a52" : "#3b2f47"}" stroke-width="${5 + R() * 3}" stroke-linecap="round"/>`;
  }
  for (let k = 0; k < 22; k++) {
    const t = k / 21;
    const x = nx - 140 + t * 280, y = ny + 8 + Math.sin(t * Math.PI) * 24 + (R() - 0.5) * 10;
    const len = 46 + R() * 34, r = (R() - 0.5) * 0.9;
    const c = ["#6a5470", "#5a4762", "#7a6280"][k % 3];
    twigsFront += `<line x1="${x - Math.cos(r) * len / 2}" y1="${y - Math.sin(r) * len / 2}" x2="${x + Math.cos(r) * len / 2}" y2="${y + Math.sin(r) * len / 2}" stroke="${shade(c, -0.35)}" stroke-width="${8 + R() * 3}" stroke-linecap="round"/>
      <line x1="${x - Math.cos(r) * len / 2}" y1="${y - Math.sin(r) * len / 2 - 1.5}" x2="${x + Math.cos(r) * len / 2}" y2="${y + Math.sin(r) * len / 2 - 1.5}" stroke="${c}" stroke-width="${4.5 + R() * 2}" stroke-linecap="round"/>`;
  }
  // Moss tufts along the nest lip.
  let moss = "";
  for (let k = 0; k < 15; k++) {
    const t = k / 14;
    const x = nx - 135 + t * 270, y = ny - 4 + Math.sin(t * Math.PI) * 14;
    const r = 14 + R() * 10;
    moss += `<circle cx="${x}" cy="${y}" r="${r}" fill="#1f6b4a"/><circle cx="${x - r * 0.25}" cy="${y - r * 0.3}" r="${r * 0.62}" fill="#2f9a63"/><circle cx="${x - r * 0.35}" cy="${y - r * 0.45}" r="${r * 0.25}" fill="#7dffb5" opacity="0.55"/>`;
  }
  // Mushrooms with glowing caps.
  const shroom = (x, y, s, col) => `<ellipse cx="${x}" cy="${y - s * 1.2}" rx="${s * 1.6}" ry="${s}" fill="${col}" opacity="0.45" filter="url(#le_g6)"/>
    <path d="M ${x - s * 0.28} ${y} L ${x - s * 0.2} ${y - s * 1.1} L ${x + s * 0.2} ${y - s * 1.1} L ${x + s * 0.28} ${y} Z" fill="#cfd6ee"/>
    <path d="M ${x - s * 1.05} ${y - s * 1.05} Q ${x} ${y - s * 2.2} ${x + s * 1.05} ${y - s * 1.05} Z" fill="${col}"/>
    <circle cx="${x - s * 0.35}" cy="${y - s * 1.45}" r="${s * 0.15}" fill="#fff" opacity="0.8"/><circle cx="${x + s * 0.3}" cy="${y - s * 1.3}" r="${s * 0.11}" fill="#fff" opacity="0.7"/>`;

  // Tap marks: little arcs just outside the shell where it's knocking.
  const tap = (x, y, a, n) => {
    let s = "";
    for (let k = 0; k < n; k++) {
      const rr = 10 + k * 9;
      const a0 = a - 0.5, a1 = a + 0.5;
      s += `<path d="M ${x + Math.cos(a0) * rr} ${y + Math.sin(a0) * rr} A ${rr} ${rr} 0 0 1 ${x + Math.cos(a1) * rr} ${y + Math.sin(a1) * rr}" fill="none" stroke="#d9ffe8" stroke-width="3.2" stroke-linecap="round" opacity="${0.85 - k * 0.25}"/>`;
    }
    return s;
  };

  // A small shell chip that has popped off the crack.
  const chip = `<g transform="translate(${ex + 96} ${ey - 46}) rotate(25)"><polygon points="-7,-5 8,-7 6,6 -5,5" fill="#a1b890" stroke="#c9d3e0" stroke-width="1.6" stroke-linejoin="round"/></g>`;

  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">
  <defs>
    <linearGradient id="le_sky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#0D0F26"/><stop offset="0.55" stop-color="#141038"/><stop offset="1" stop-color="#1b2a55"/>
    </linearGradient>
    <radialGradient id="le_moon" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#dfe6ff" stop-opacity="0.5"/><stop offset="1" stop-color="#7b8cff" stop-opacity="0"/></radialGradient>
    <radialGradient id="le_pool" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="${NAT}" stop-opacity="0.55"/><stop offset="0.5" stop-color="${NAT}" stop-opacity="0.18"/><stop offset="1" stop-color="${NAT}" stop-opacity="0"/></radialGradient>
    <radialGradient id="le_back" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#2c2170" stop-opacity="0.9"/><stop offset="1" stop-color="#2c2170" stop-opacity="0"/></radialGradient>
    <linearGradient id="le_ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#16314a"/><stop offset="1" stop-color="#0a1426"/></linearGradient>
    <linearGradient id="le_blade" x1="0" y1="1" x2="0" y2="0"><stop offset="0" stop-color="#1c5a48"/><stop offset="0.6" stop-color="#3fd98a"/><stop offset="1" stop-color="#c8ffe0"/></linearGradient>
    <filter id="le_g6" x="-100%" y="-100%" width="300%" height="300%"><feGaussianBlur stdDeviation="6"/></filter>
    <filter id="le_g14" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="14"/></filter>
    <filter id="le_g30" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="30"/></filter>
    <radialGradient id="le_vig" cx="0.5" cy="0.48" r="0.75"><stop offset="0.6" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#05061a" stop-opacity="0.7"/></radialGradient>
  </defs>
  <rect width="${W}" height="${H}" fill="url(#le_sky)"/>
  ${stars}
  <circle cx="455" cy="62" r="120" fill="url(#le_moon)"/>
  <circle cx="455" cy="62" r="26" fill="#eef1ff" opacity="0.92"/><circle cx="466" cy="55" r="24" fill="#141038" opacity="0.9"/>
  <ellipse cx="${ex}" cy="200" rx="300" ry="190" fill="url(#le_back)"/>
  <g opacity="0.95">${trees}</g>
  <rect x="0" y="210" width="${W}" height="120" fill="#1b2a55" opacity="0.35" filter="url(#le_g30)"/>
  <path d="M 0 330 Q 180 300 360 312 Q 560 300 720 335 L 720 440 L 0 440 Z" fill="url(#le_ground)"/>
  ${backGrass}
  <ellipse cx="${ex}" cy="${ny + 10}" rx="270" ry="80" fill="url(#le_pool)"/>
  ${glowGrass}
  ${shroom(178, 352, 15, "#3EA8FF")}${shroom(204, 356, 10, "#5CFF9A")}${shroom(560, 354, 13, "#B88CFF")}
  <ellipse cx="${nx}" cy="${ny + 34}" rx="160" ry="22" fill="#05061a" opacity="0.6" filter="url(#le_g6)"/>
  <ellipse cx="${nx}" cy="${ny}" rx="135" ry="34" fill="#2a2036"/>
  <ellipse cx="${nx}" cy="${ny - 4}" rx="112" ry="22" fill="#170f22"/>
  ${twigsBack}
  <ellipse cx="${ex}" cy="${ey - 30}" rx="125" ry="140" fill="${NAT}" opacity="0.16" filter="url(#le_g30)"/>
  <ellipse cx="${ex}" cy="${ny - 6}" rx="70" ry="10" fill="#05061a" opacity="0.6" filter="url(#le_g6)"/>
  ${egg(ex, ey, es, { family: "nature", rarity: "common", seed: 4, cracked: 0.5, crackGlow: "#9dffc4", tilt: -6 })}
  <!-- rim light from the leaking glow -->
  <circle cx="${ex - 18}" cy="${ey - 10}" r="22" fill="#b6ffd2" opacity="0.5" filter="url(#le_g14)"/>
  ${tap(ex + 70, ey - 70, -0.8, 3)}${tap(ex - 74, ey - 64, -2.3, 2)}
  ${chip}
  ${moss}
  ${twigsFront}
  ${flies}
  ${frontGrass}
  <rect width="${W}" height="${H}" fill="url(#le_vig)"/>
</svg>`;
}

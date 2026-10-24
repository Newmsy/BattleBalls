// Cosmic habitat: a little moon/asteroid surface in deep space. Nebula wash,
// dense star field, a big ringed planet hanging upper right (dim), a comet
// streaking top left, floating rocks and soft violet crystals. Signature
// light: cool violet-blue starlight from a bright star behind the stage.
// Stage: a flat crater-rim rock at (200, 330).
import { blurs, critter, sky, motes, sparkle, shade, rng, f } from "./_p.mjs";
import { W, H, SX, SY, fades, withHero } from "./_hab.mjs";

export const size = [W, H];
const INKD = "#0c0a24";

// A floating rock: lumpy polygon with a lit top-left edge.
function rock(x, y, r, col, seed, o = 1) {
  const R = rng(seed);
  const n = 9, pts = [];
  for (let k = 0; k < n; k++) {
    const a = (k / n) * Math.PI * 2, rr = r * (0.78 + R() * 0.3);
    pts.push([x + Math.cos(a) * rr, y + Math.sin(a) * rr * 0.8]);
  }
  const d = "M " + pts.map((p) => `${f(p[0])} ${f(p[1])}`).join(" L ") + " Z";
  return `<g opacity="${o}"><path d="${d}" fill="${col}" stroke="${INKD}" stroke-width="${f(Math.max(1.5, r * 0.08))}" stroke-linejoin="round"/>
    <path d="${d}" fill="${shade(col, -0.35)}" transform="translate(${f(r * 0.18)} ${f(r * 0.2)}) scale(0.82)" transform-origin="${f(x)} ${f(y)}"/>
    <circle cx="${f(x - r * 0.25)}" cy="${f(y - r * 0.1)}" r="${f(r * 0.18)}" fill="${shade(col, -0.25)}"/>
    <path d="M ${f(pts[4][0])} ${f(pts[4][1])} L ${f(pts[5][0])} ${f(pts[5][1])} L ${f(pts[6][0])} ${f(pts[6][1])}" fill="none" stroke="#b9c4ff" stroke-width="${f(Math.max(1, r * 0.07))}" stroke-linecap="round" opacity="0.6"/></g>`;
}

// Crater on the ground: a squashed ellipse with dark bowl and lit far rim.
function crater(x, y, rx, o = 1) {
  const ry = rx * 0.28;
  return `<g opacity="${o}"><ellipse cx="${x}" cy="${y}" rx="${rx}" ry="${ry}" fill="#2a2458"/>
    <ellipse cx="${x}" cy="${y + ry * 0.15}" rx="${rx * 0.86}" ry="${ry * 0.74}" fill="#16133a"/>
    <path d="M ${x - rx * 0.86} ${y + ry * 0.1} Q ${x} ${y + ry * 1.05} ${x + rx * 0.86} ${y + ry * 0.1}" fill="none" stroke="#6a64c0" stroke-width="${Math.max(1, rx * 0.06)}" opacity="0.6"/></g>`;
}

function crystal(x, y, s, o = 1) {
  return `<g opacity="${o}" transform="translate(${x} ${y}) scale(${s})">
    <circle cx="0" cy="-20" r="26" fill="#9a8cff" opacity="0.35" filter="url(#bl12)"/>
    <path d="M -12 0 L -16 -22 L -8 -34 L -2 -6 Z" fill="#7b77ff" stroke="${INKD}" stroke-width="2" stroke-linejoin="round"/>
    <path d="M -4 0 L -2 -42 L 8 -52 L 12 -4 Z" fill="#a9a4ff" stroke="${INKD}" stroke-width="2" stroke-linejoin="round"/>
    <path d="M 6 0 L 14 -24 L 22 -20 L 16 2 Z" fill="#8a84f0" stroke="${INKD}" stroke-width="2" stroke-linejoin="round"/>
    <path d="M 1 -38 L 3 -8" stroke="#e8e6ff" stroke-width="2" stroke-linecap="round" opacity="0.8"/></g>`;
}

function scene() {
  const R = rng(71);
  // Nebula wash: big soft blobs.
  let neb = "";
  [[160, 120, 260, 90, "#5a3aa8", 0.35], [420, 70, 220, 70, "#3a5ab0", 0.3], [620, 200, 240, 80, "#6a2a8a", 0.22], [300, 200, 200, 60, "#7b77ff", 0.18], [90, 40, 160, 50, "#a050a0", 0.18], [60, 200, 170, 60, "#b0488a", 0.2], [470, 150, 150, 50, "#2a8ab0", 0.16], [740, 30, 140, 50, "#3a6ab0", 0.14]].forEach(([x, y, rx, ry, c, o]) => {
    neb += `<ellipse cx="${x}" cy="${y}" rx="${rx}" ry="${ry}" fill="${c}" opacity="${o}" filter="url(#bl40)" transform="rotate(-12 ${x} ${y})"/>`;
  });
  // Dust lanes inside nebula.
  neb += `<path d="M 40 150 Q 200 90 380 120 Q 480 140 560 100" fill="none" stroke="#c8b8ff" stroke-width="18" opacity="0.06" filter="url(#bl12)"/>`;
  // Extra tiny star dust.
  let dust = "";
  for (let k = 0; k < 140; k++) dust += `<circle cx="${f(R() * W)}" cy="${f(R() * 300)}" r="${f(0.4 + R() * 0.6)}" fill="#e4e0ff" opacity="${f(0.2 + R() * 0.4)}"/>`;
  // Signature star: bright blue-violet star behind/above the stage.
  const star = `
    <circle cx="300" cy="150" r="220" fill="#7b77ff" opacity="0.16" filter="url(#bl40)"/>
    <circle cx="300" cy="150" r="80" fill="#a8b4ff" opacity="0.3" filter="url(#bl24)"/>
    <circle cx="300" cy="150" r="22" fill="#dfe4ff" opacity="0.8" filter="url(#bl6)"/>
    <circle cx="300" cy="150" r="7" fill="#ffffff"/>
    <path d="M 300 96 L 302 148 L 300 204 L 298 148 Z M 246 150 L 300 148 L 354 150 L 300 152 Z" fill="#e8ecff" opacity="0.85"/>
    <path d="M 300 120 L 301 149 L 330 150 L 301 151 L 300 180 L 299 151 L 270 150 L 299 149 Z" fill="#fff" transform="rotate(45 300 150)" opacity="0.5"/>`;
  // Ringed planet upper right, dim and calm.
  const px = 610, py = 110;
  const planet = `
    <circle cx="${px}" cy="${py}" r="100" fill="#6a5ad0" opacity="0.14" filter="url(#bl32)"/>
    <ellipse cx="${px}" cy="${py}" rx="128" ry="26" fill="none" stroke="#8a7ac8" stroke-width="10" opacity="0.45" transform="rotate(-16 ${px} ${py})"/>
    <circle cx="${px}" cy="${py}" r="62" fill="url(#hcPlanet)"/>
    <path d="M ${px - 60} ${py - 10} Q ${px} ${py - 22} ${px + 60} ${py - 4}" fill="none" stroke="#b07a9a" stroke-width="7" opacity="0.5"/>
    <path d="M ${px - 56} ${py + 18} Q ${px} ${py + 6} ${px + 58} ${py + 22}" fill="none" stroke="#4a3a88" stroke-width="9" opacity="0.5"/>
    <path d="M ${px - 44} ${py - 38} Q ${px - 56} ${py - 10} ${px - 46} ${py + 24}" fill="none" stroke="#d8d0ff" stroke-width="3" stroke-linecap="round" opacity="0.5"/>
    <defs><clipPath id="hcRingF"><rect x="${px - 140}" y="${py}" width="280" height="80"/></clipPath></defs>
    <g transform="rotate(-16 ${px} ${py})"><g clip-path="url(#hcRingF)">
      <ellipse cx="${px}" cy="${py}" rx="128" ry="26" fill="none" stroke="#b8a8e8" stroke-width="10" opacity="0.8"/>
      <ellipse cx="${px}" cy="${py}" rx="112" ry="21" fill="none" stroke="#5a4a98" stroke-width="3" opacity="0.7"/>
      <ellipse cx="${px}" cy="${py}" rx="138" ry="29" fill="none" stroke="#e8c8a8" stroke-width="2" opacity="0.4"/>
    </g></g>
    <circle cx="${px + 98}" cy="${py + 56}" r="9" fill="#9a90d8" opacity="0.7"/>`;
  // Comet top left.
  const comet = `
    <path d="M 196 34 L 60 92" stroke="#9ad8ff" stroke-width="10" stroke-linecap="round" opacity="0.18" filter="url(#bl6)"/>
    <path d="M 196 34 Q 120 64 30 100" fill="none" stroke="url(#hcTail)" stroke-width="4" stroke-linecap="round"/>
    <path d="M 196 34 Q 132 56 70 74" fill="none" stroke="url(#hcTail)" stroke-width="2" stroke-linecap="round" opacity="0.6"/>
    <circle cx="198" cy="33" r="10" fill="#bfe8ff" opacity="0.5" filter="url(#bl4)"/>
    <circle cx="198" cy="33" r="3.4" fill="#ffffff"/>`;
  // Floating far rocks.
  const rocks = `${rock(470, 210, 14, "#3e3880", 3, 0.85)}${rock(500, 240, 7, "#3a3478", 5, 0.75)}${rock(720, 250, 18, "#33306c", 7, 0.7)}${rock(40, 50, 10, "#3e3880", 9, 0.7)}${rock(380, 40, 6, "#3e3880", 11, 0.7)}`;
  // Far horizon of the little moon (curved), mid ridge, near ground.
  const ground = `
    <path d="M -20 300 Q 390 236 800 286 L 800 460 L -20 460 Z" fill="#2c2766"/>
    <path d="M -20 300 Q 390 236 800 286" fill="none" stroke="#9a9cff" stroke-width="3" opacity="0.55"/>
    <path d="M -20 300 Q 390 236 800 286" fill="none" stroke="#9a9cff" stroke-width="12" opacity="0.18" filter="url(#bl6)"/>
    ${crater(470, 284, 40, 0.9)}${crater(610, 290, 54, 0.8)}${crater(720, 298, 30, 0.7)}${crater(90, 300, 34, 0.8)}
    <path d="M -20 334 Q 260 306 520 320 Q 660 328 800 314 L 800 460 L -20 460 Z" fill="#221e56"/>
    ${crater(540, 352, 70, 0.9)}${crater(700, 340, 40, 0.7)}
    <path d="M -20 380 Q 200 360 420 372 Q 560 380 800 368 L 800 460 L -20 460 Z" fill="#1a1748"/>`;
  // Tiny cosmic critters far away with their orbit rings.
  const bg = `
    ${critter(470, 268, 8, "#7b77ff", { acc: "orbit", mood: "happy", look: [-0.6, 0], rim: "#c9d0ff", rimSide: -1 })}
    ${critter(96, 286, 7, "#8a86ff", { acc: "orbit", mood: "sleepy", rim: "#c9d0ff", rimSide: 1 })}
    ${critter(540, 172, 6, "#7b77ff", { acc: "orbit", mood: "cheer", rim: "#c9d0ff", rimSide: -1 })}`;
  // Stage: a flat crater-rim rock in the starlight.
  const stage = `
    <ellipse cx="${SX + 20}" cy="${SY - 6}" rx="210" ry="64" fill="#9aa4ff" opacity="0.16" filter="url(#bl24)"/>
    <ellipse cx="${SX}" cy="${SY + 50}" rx="160" ry="18" fill="#08061c" opacity="0.6" filter="url(#bl8)"/>
    <path d="M ${SX - 132} ${SY + 2} L ${SX - 118} ${SY + 36} L ${SX - 60} ${SY + 52} L ${SX + 30} ${SY + 54} L ${SX + 104} ${SY + 42} L ${SX + 134} ${SY + 6} Z" fill="#1c1a4a" stroke="${INKD}" stroke-width="3" stroke-linejoin="round"/>
    <path d="M ${SX - 60} ${SY + 52} L ${SX - 50} ${SY + 24} M ${SX + 30} ${SY + 54} L ${SX + 40} ${SY + 22} M ${SX + 104} ${SY + 42} L ${SX + 100} ${SY + 18}" stroke="#2c2866" stroke-width="2.5" fill="none"/>
    <path d="M ${SX - 132} ${SY + 2} L ${SX - 108} ${SY - 18} L ${SX - 40} ${SY - 26} L ${SX + 50} ${SY - 24} L ${SX + 114} ${SY - 12} L ${SX + 134} ${SY + 6} L ${SX + 104} ${SY + 22} L ${SX} ${SY + 30} L ${SX - 104} ${SY + 22} Z" fill="#4a4698" stroke="${INKD}" stroke-width="3" stroke-linejoin="round"/>
    <path d="M ${SX - 100} ${SY - 10} L ${SX - 36} ${SY - 18} L ${SX + 48} ${SY - 16} L ${SX + 104} ${SY - 6} L ${SX + 44} ${SY + 8} L ${SX - 64} ${SY + 8} Z" fill="#5c58b0"/>
    ${[[-70, 2, 9], [30, 6, 12], [80, -6, 6], [-20, -12, 5]].map(([dx, dy, r]) => `<ellipse cx="${SX + dx}" cy="${SY + dy}" rx="${r}" ry="${r * 0.32}" fill="#3a3680"/><path d="M ${SX + dx - r} ${SY + dy} Q ${SX + dx} ${SY + dy + r * 0.45} ${SX + dx + r} ${SY + dy}" fill="none" stroke="#8a88e0" stroke-width="1.4" opacity="0.7"/>`).join("")}
    <ellipse cx="${SX + 16}" cy="${SY - 8}" rx="84" ry="12" fill="#c9d0ff" opacity="0.3" filter="url(#bl8)"/>
    <path d="M ${SX - 108} ${SY - 18} L ${SX - 40} ${SY - 26} L ${SX + 50} ${SY - 24} L ${SX + 114} ${SY - 12}" fill="none" stroke="#c9d0ff" stroke-width="2.2" opacity="0.7" stroke-linejoin="round"/>
    ${sparkle(SX + 52, SY - 24, 5, "#e8ecff", 0.9)}${sparkle(SX - 106, SY - 16, 3.5, "#e8ecff", 0.7)}`;
  // Near: crater rim boulders and crystals flanking the stage.
  const near = `
    ${crystal(388, 360, 1.1)}
    ${crystal(-6, 372, 1.3, 0.95)}
    ${rock(350, 382, 20, "#3a3680", 13)}${rock(420, 392, 12, "#34307a", 17)}
    ${rock(36, 400, 22, "#34307a", 19)}
    ${crater(250, 420, 60, 0.6)}`;

  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${blurs()}
  <defs>
    <linearGradient id="hcSky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0a0a22"/><stop offset="0.55" stop-color="#16143e"/><stop offset="1" stop-color="#252060"/></linearGradient>
    <radialGradient id="hcPlanet" cx="0.32" cy="0.3" r="0.85"><stop offset="0" stop-color="#9a88d8"/><stop offset="0.55" stop-color="#5a4aa0"/><stop offset="1" stop-color="#2a2260"/></radialGradient>
    <linearGradient id="hcTail" x1="1" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#e8f6ff" stop-opacity="0.9"/><stop offset="1" stop-color="#9ad8ff" stop-opacity="0"/></linearGradient>
  </defs>
  <rect width="${W}" height="${H}" fill="url(#hcSky)"/>
  ${neb}${dust}
  ${sky(83, 80, 0, 0, 780, 260)}
  ${star}${planet}${comet}${rocks}
  ${ground}${bg}
  ${stage}${near}
  ${motes(29, 18, 0, 140, 780, 400, ["#c9d0ff", "#a8b4ff", "#e6e0ff"])}
  ${fades("hc", { right: 0.42 })}
  </svg>`;
}

export const many = {
  hab_cosmic: scene,
  hab_cosmic_ctx: withHero(scene, "#7b77ff", "orbit", "#c9d0ff"),
};
export default scene;

// Toybox habitat: a kid's bedroom at night, seen at toy scale. A moon-shaped
// night-light plugged in by the skirting board pours warm gold across the
// floorboards; block towers, a wind-up train on a wooden track, a toy rocket
// (right, kept dim) and a moonlit window corner. Signature light: night-light
// gold. Stage: a big wooden toy drum at (200, 330).
import { blurs, critter, motes, sparkle, shade, rng, f } from "./_p.mjs";
import { W, H, SX, SY, fades, withHero } from "./_hab.mjs";

export const size = [W, H];

const INKD = "#1a1230";
// Darken a group (instead of group opacity, which lets the wall show through).
const DIMS = [];
function dim(o) {
  if (o >= 1) return "";
  const id = `htDim${Math.round(o * 100)}`;
  if (!DIMS.includes(o)) DIMS.push(o);
  return `filter="url(#${id})"`;
}
const dimDefs = () => DIMS.map((o) => `<filter id="htDim${Math.round(o * 100)}" color-interpolation-filters="sRGB"><feComponentTransfer>${["R", "G", "B"].map((c) => `<feFunc${c} type="linear" slope="${o}" intercept="${c === "B" ? 0.03 : 0.01}"/>`).join("")}</feComponentTransfer></filter>`).join("");

// A wooden toy block (front face + top + side) with an embossed shape, no letters.
function block(x, y, s, col, mark = "star", o = 1, lit = 0.12) {
  const top = shade(col, 0.22 + lit), side = shade(col, -0.32), face = col;
  const d = s * 0.28;
  let m = "";
  const cx = x + s / 2, cy = y + s / 2, mr = s * 0.26, mc = shade(col, -0.22);
  if (mark === "star") {
    let p = "";
    for (let k = 0; k < 10; k++) {
      const a = -Math.PI / 2 + (k * Math.PI) / 5, rr = k % 2 ? mr * 0.45 : mr;
      p += `${f(cx + Math.cos(a) * rr)},${f(cy + Math.sin(a) * rr)} `;
    }
    m = `<polygon points="${p}" fill="${mc}"/>`;
  } else if (mark === "circle") m = `<circle cx="${f(cx)}" cy="${f(cy)}" r="${f(mr * 0.8)}" fill="none" stroke="${mc}" stroke-width="${f(s * 0.07)}"/>`;
  else if (mark === "tri") m = `<path d="M ${f(cx)} ${f(cy - mr)} L ${f(cx + mr)} ${f(cy + mr * 0.7)} L ${f(cx - mr)} ${f(cy + mr * 0.7)} Z" fill="${mc}"/>`;
  else if (mark === "heart") m = `<path d="M ${f(cx)} ${f(cy + mr * 0.8)} C ${f(cx - mr * 1.4)} ${f(cy - mr * 0.2)} ${f(cx - mr * 0.6)} ${f(cy - mr * 1.1)} ${f(cx)} ${f(cy - mr * 0.35)} C ${f(cx + mr * 0.6)} ${f(cy - mr * 1.1)} ${f(cx + mr * 1.4)} ${f(cy - mr * 0.2)} ${f(cx)} ${f(cy + mr * 0.8)} Z" fill="${mc}"/>`;
  return `<g ${dim(o)}>
    <path d="M ${f(x)} ${f(y)} L ${f(x + d)} ${f(y - d * 0.7)} L ${f(x + s + d)} ${f(y - d * 0.7)} L ${f(x + s)} ${f(y)} Z" fill="${top}" stroke="${INKD}" stroke-width="${f(s * 0.035)}" stroke-linejoin="round"/>
    <path d="M ${f(x + s)} ${f(y)} L ${f(x + s + d)} ${f(y - d * 0.7)} L ${f(x + s + d)} ${f(y + s - d * 0.7)} L ${f(x + s)} ${f(y + s)} Z" fill="${side}" stroke="${INKD}" stroke-width="${f(s * 0.035)}" stroke-linejoin="round"/>
    <rect x="${f(x)}" y="${f(y)}" width="${f(s)}" height="${f(s)}" rx="${f(s * 0.06)}" fill="${face}" stroke="${INKD}" stroke-width="${f(s * 0.035)}"/>
    <rect x="${f(x + s * 0.12)}" y="${f(y + s * 0.12)}" width="${f(s * 0.76)}" height="${f(s * 0.76)}" rx="${f(s * 0.08)}" fill="none" stroke="${shade(col, 0.18)}" stroke-width="${f(s * 0.04)}" opacity="0.7"/>
    ${m}</g>`;
}

// Moon-shaped plug-in night-light (the signature light source).
function nightLight(x, y, s) {
  return `
    <circle cx="${x}" cy="${y}" r="${260 * s}" fill="#ffb347" opacity="0.16" filter="url(#bl40)"/>
    <circle cx="${x}" cy="${y}" r="${120 * s}" fill="#ffc96a" opacity="0.32" filter="url(#bl32)"/>
    <circle cx="${x}" cy="${y}" r="${62 * s}" fill="#ffe2a0" opacity="0.5" filter="url(#bl16)"/>
    <rect x="${x - 18 * s}" y="${y + 10 * s}" width="${36 * s}" height="${48 * s}" rx="${6 * s}" fill="#d9c9a8" stroke="${INKD}" stroke-width="${2.5 * s}"/>
    <rect x="${x - 10 * s}" y="${y + 30 * s}" width="${20 * s}" height="${12 * s}" rx="${3 * s}" fill="#b8a888"/>
    <defs><mask id="htMoonM"><circle cx="${x}" cy="${y}" r="${40 * s}" fill="#fff"/><circle cx="${x + 24 * s}" cy="${y - 12 * s}" r="${34 * s}" fill="#000"/></mask></defs>
    <g mask="url(#htMoonM)">
      <circle cx="${x}" cy="${y}" r="${40 * s}" fill="url(#htMoon)"/>
      <circle cx="${x}" cy="${y}" r="${40 * s}" fill="none" stroke="#c8892a" stroke-width="${5 * s}"/>
    </g>
    <path d="M ${x - 30 * s} ${y - 12 * s} Q ${x - 30 * s} ${y + 18 * s} ${x - 6 * s} ${y + 30 * s}" fill="none" stroke="#fffbe8" stroke-width="${4 * s}" stroke-linecap="round" opacity="0.8"/>
    <path d="M ${x - 22 * s} ${y + 4 * s} q ${4 * s} ${4 * s} ${8 * s} 0" fill="none" stroke="#a8641e" stroke-width="${2.6 * s}" stroke-linecap="round"/>
    <circle cx="${x - 20 * s}" cy="${y + 14 * s}" r="${3.4 * s}" fill="#ff9a7a" opacity="0.6"/>
    <path d="M ${x - 12 * s} ${y + 36 * s} Q ${x} ${y + 42 * s} ${x + 12 * s} ${y + 36 * s}" fill="none" stroke="#ffe7a8" stroke-width="${2 * s}" opacity="0"/>`;
}

// Wind-up train engine (facing left) with a key on top.
function engine(x, y, s, o = 1) {
  return `<g ${dim(o)} transform="translate(${x} ${y}) scale(${s})">
    <rect x="-34" y="-30" width="54" height="22" rx="5" fill="#c94a4a" stroke="${INKD}" stroke-width="2.4"/>
    <rect x="6" y="-50" width="26" height="42" rx="4" fill="#3d6fb0" stroke="${INKD}" stroke-width="2.4"/>
    <rect x="11" y="-45" width="16" height="12" rx="2" fill="#ffd98a" opacity="0.85"/>
    <path d="M 2 -52 L 36 -52 L 32 -58 L 6 -58 Z" fill="#c94a4a" stroke="${INKD}" stroke-width="2.4" stroke-linejoin="round"/>
    <path d="M -26 -30 L -28 -48 L -16 -48 L -18 -30 Z" fill="#2e2a40" stroke="${INKD}" stroke-width="2.4" stroke-linejoin="round"/>
    <path d="M -34 -12 L -44 -6 L -34 -6 Z" fill="#e0b040" stroke="${INKD}" stroke-width="2" stroke-linejoin="round"/>
    ${[-22, 0, 20].map((wx) => `<circle cx="${wx}" cy="-6" r="8" fill="#e0b040" stroke="${INKD}" stroke-width="2.4"/><circle cx="${wx}" cy="-6" r="2.6" fill="${INKD}"/>`).join("")}
    <path d="M -6 -30 L -6 -40 M -14 -44 Q -6 -36 2 -44 Q -6 -52 -14 -44 Z" fill="#e0b040" stroke="${INKD}" stroke-width="2"/>
    <circle cx="-34" cy="-22" r="3" fill="#ffe7a8"/></g>`;
}

function wagon(x, y, s, col, o = 1) {
  return `<g ${dim(o)} transform="translate(${x} ${y}) scale(${s})">
    <rect x="-24" y="-28" width="48" height="20" rx="4" fill="${col}" stroke="${INKD}" stroke-width="2.4"/>
    <path d="M -22 -24 L 22 -24" stroke="${shade(col, 0.3)}" stroke-width="2.4" stroke-linecap="round"/>
    ${[-12, 12].map((wx) => `<circle cx="${wx}" cy="-6" r="7" fill="#e0b040" stroke="${INKD}" stroke-width="2.4"/><circle cx="${wx}" cy="-6" r="2.2" fill="${INKD}"/>`).join("")}
    <path d="M -24 -14 L -34 -14" stroke="${INKD}" stroke-width="2.4"/></g>`;
}

// Toy rocket standing on its fins.
function rocket(x, y, s, o = 1) {
  return `<g ${dim(o)} transform="translate(${x} ${y}) scale(${s})">
    <path d="M -22 -40 L -46 -6 L -40 4 L -20 -10 Z" fill="#b8403e" stroke="${INKD}" stroke-width="3" stroke-linejoin="round"/>
    <path d="M 22 -40 L 46 -6 L 40 4 L 20 -10 Z" fill="#8e2e34" stroke="${INKD}" stroke-width="3" stroke-linejoin="round"/>
    <path d="M -24 -6 Q -30 -90 0 -150 Q 30 -90 24 -6 Z" fill="#e8dcc6" stroke="${INKD}" stroke-width="3" stroke-linejoin="round"/>
    <path d="M 6 -142 Q 26 -90 20 -8 L 24 -6 Q 30 -90 0 -150 Z" fill="#b8a888" opacity="0.8"/>
    <path d="M -15 -122 Q 0 -130 15 -122 Q 8 -140 0 -150 Q -8 -140 -15 -122 Z" fill="#c94a4a" stroke="${INKD}" stroke-width="3" stroke-linejoin="round"/>
    <circle cx="0" cy="-82" r="13" fill="#3d6fb0" stroke="${INKD}" stroke-width="3"/>
    <circle cx="0" cy="-82" r="8" fill="#9ec4f0" opacity="0.6"/>
    <circle cx="-4" cy="-86" r="3" fill="#fff" opacity="0.7"/>
    <path d="M -24 -30 Q 0 -24 24 -30" fill="none" stroke="#c94a4a" stroke-width="6"/>
    <path d="M -10 -6 L 10 -6 L 6 6 L -6 6 Z" fill="#5a5470" stroke="${INKD}" stroke-width="3" stroke-linejoin="round"/>
    <path d="M -20 -100 Q -24 -60 -18 -20" fill="none" stroke="#ffe7a8" stroke-width="3" stroke-linecap="round" opacity="0.55"/></g>`;
}

function scene() {
  const R = rng(57);
  // Back wall with a soft starry wallpaper and the skirting board.
  let paper = "";
  for (let k = 0; k < 46; k++) {
    const x = R() * 800 - 10, y = R() * 250;
    const r = 3 + R() * 3;
    if (k % 3 === 0) paper += `<path d="M ${f(x + r)} ${f(y - r)} A ${f(r * 1.2)} ${f(r * 1.2)} 0 1 0 ${f(x + r)} ${f(y + r)} A ${f(r)} ${f(r)} 0 1 1 ${f(x + r)} ${f(y - r)} Z" fill="#4a4688" opacity="0.4"/>`;
    else paper += sparkle(+f(x), +f(y), r, "#4e4a90", 0.45);
  }
  const wall = `
    <rect width="${W}" height="292" fill="url(#htWall)"/>
    ${[90, 250, 410, 570, 730].map((x) => `<rect x="${x}" y="0" width="34" height="292" fill="#2a2756" opacity="0.35"/>`).join("")}
    ${paper}`;
  // Moonlit window corner (top left) with a curtain.
  const win = `
    <rect x="-20" y="-10" width="128" height="124" fill="#1c3266"/>
    <rect x="-20" y="-10" width="128" height="124" fill="url(#htWin)"/>
    <circle cx="54" cy="40" r="17" fill="#e8eeff" opacity="0.9"/><circle cx="54" cy="40" r="34" fill="#a8c4ff" opacity="0.3" filter="url(#bl12)"/>
    ${[[16, 22], [88, 70], [30, 86], [94, 18], [72, 96]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="1.4" fill="#dfe8ff" opacity="0.8"/>`).join("")}
    <path d="M 46 -10 L 46 114 M -20 52 L 108 52" stroke="#2b2350" stroke-width="7"/>
    <rect x="-20" y="-10" width="128" height="124" fill="none" stroke="#3a2f5e" stroke-width="10"/>
    <rect x="-24" y="112" width="140" height="10" rx="3" fill="#4a3c6e" stroke="${INKD}" stroke-width="2"/>
    <path d="M 108 -10 Q 132 40 118 100 Q 128 130 140 150 L 150 146 Q 140 100 150 50 Q 146 10 154 -10 Z" fill="#5a3a6e" stroke="${INKD}" stroke-width="2.5"/>
    <path d="M 124 -6 Q 136 50 128 120" fill="none" stroke="#7a5690" stroke-width="3" opacity="0.7"/>
    <path d="M 0 114 L 120 114 L 200 292 L 60 292 Z" fill="#9ec0ff" opacity="0.05"/>`;
  // Skirting board + floorboards in perspective, warm near the light.
  const vp = [300, 120];
  let boards = "";
  for (let k = -12; k <= 16; k++) {
    const xb = 300 + k * 74;
    boards += `<path d="M ${f(vp[0] + (xb - vp[0]) * 0.0)} 292 L ${f(xb)} 460" stroke="#2a1a24" stroke-width="2" opacity="0.5"/>`;
  }
  // Fix: draw floor seams from skirting line toward the viewer converging upward.
  boards = "";
  for (let k = -10; k <= 14; k++) {
    const xt = 300 + k * 40, xb = 300 + k * 110;
    boards += `<path d="M ${xt} 292 L ${xb} 460" stroke="#2a1622" stroke-width="2" opacity="0.55"/>`;
  }
  [[312, 0.3], [338, 0.6], [376, 0.9]].forEach(([y]) => (boards += `<path d="M 0 ${y} L ${W} ${y}" stroke="#2a1622" stroke-width="1.2" opacity="0.18"/>`));
  const floor = `
    <rect x="0" y="292" width="${W}" height="168" fill="url(#htFloor)"/>
    ${boards}
    <rect x="0" y="280" width="${W}" height="14" fill="#3a2e5a" stroke="${INKD}" stroke-width="2"/>
    <path d="M 0 282 L ${W} 282" stroke="#5a4a80" stroke-width="2" opacity="0.7"/>
    <ellipse cx="300" cy="330" rx="300" ry="60" fill="#ffb347" opacity="0.22" filter="url(#bl32)"/>`;
  // Night-light plugged in just above the skirting board, right of the stage.
  const light = `${nightLight(392, 226, 0.95)}`;
  // Mid: wooden train track oval behind on the right, train on it.
  const track = `
    <ellipse cx="610" cy="324" rx="200" ry="34" fill="none" stroke="#5a3a2e" stroke-width="16"/>
    <ellipse cx="610" cy="324" rx="200" ry="34" fill="none" stroke="#7a5038" stroke-width="10"/>
    <ellipse cx="610" cy="324" rx="200" ry="34" fill="none" stroke="#3a2420" stroke-width="2" stroke-dasharray="3 14"/>
    <path d="M 410 324 Q 412 340 440 348" fill="none" stroke="#ffcf80" stroke-width="2" opacity="0.4"/>`;
  const train = `${wagon(670, 362, 0.8, "#4a8a5a", 0.6)}${wagon(624, 362, 0.8, "#c99a3a", 0.62)}${engine(560, 362, 0.85, 0.7)}`;
  // Far toybox critters: one riding the wagon, one peeking from the blocks.
  const bg = `
    ${critter(624, 330, 8, "#ffc93c", { acc: "propeller", mood: "cheer", rim: "#ffd98a", rimSide: -1 })}
    ${critter(486, 300, 7, "#f2b830", { acc: "propeller", mood: "happy", look: [-0.6, 0], rim: "#ffd98a", rimSide: -1 })}
    ${critter(96, 264, 7.5, "#ffc93c", { acc: "propeller", mood: "sleepy", rim: "#ffd98a", rimSide: 1 })}`;
  // Block towers: left edge tall stack, small stack right of night light, far stack on right.
  const towers = `
    ${block(-14, 300, 58, "#3d6fb0", "star")}${block(-6, 242, 58, "#c94a4a", "circle")}${block(-18, 184, 58, "#e0b040", "tri", 1, 0.2)}${block(0, 126, 52, "#4a8a5a", "heart", 1, 0.2)}
    ${block(456, 276, 30, "#c94a4a", "heart", 0.8)}${block(490, 276, 30, "#3d6fb0", "circle", 0.8)}${block(472, 246, 30, "#e0b040", "star", 0.8, 0.25)}
    ${block(560, 252, 34, "#4a6a9a", "tri", 0.55)}${block(560, 218, 34, "#7a4a5a", "star", 0.55)}`;
  const rkt = `<ellipse cx="704" cy="300" rx="50" ry="8" fill="#000" opacity="0.4" filter="url(#bl4)"/>${rocket(704, 296, 0.95, 0.5)}`;
  // Stage: a big wooden toy drum lit by the night-light.
  const zig = [];
  for (let k = 0; k <= 10; k++) zig.push(`${f(SX - 120 + k * 24)},${k % 2 ? SY + 46 : SY + 8}`);
  const stage = `
    <ellipse cx="${SX + 20}" cy="${SY + 6}" rx="210" ry="62" fill="#ffc96a" opacity="0.22" filter="url(#bl24)"/>
    <ellipse cx="${SX}" cy="${SY + 60}" rx="150" ry="16" fill="#120a18" opacity="0.6" filter="url(#bl8)"/>
    <path d="M ${SX - 122} ${SY} L ${SX - 122} ${SY + 40} Q ${SX} ${SY + 78} ${SX + 122} ${SY + 40} L ${SX + 122} ${SY} Z" fill="url(#htDrum)" stroke="${INKD}" stroke-width="3"/>
    <polyline points="${zig.join(" ")}" fill="none" stroke="#f0d79a" stroke-width="3" opacity="0.85"/>
    ${zig.map((p) => { const [x, y] = p.split(","); return `<circle cx="${x}" cy="${y}" r="3.4" fill="#e0b040" stroke="${INKD}" stroke-width="1.4"/>`; }).join("")}
    <path d="M ${SX - 122} ${SY + 40} Q ${SX} ${SY + 78} ${SX + 122} ${SY + 40}" fill="none" stroke="#f0c048" stroke-width="9"/>
    <path d="M ${SX - 122} ${SY + 40} Q ${SX} ${SY + 78} ${SX + 122} ${SY + 40}" fill="none" stroke="${INKD}" stroke-width="2.4" transform="translate(0 5)"/>
    <ellipse cx="${SX}" cy="${SY}" rx="122" ry="28" fill="#f0c048" stroke="${INKD}" stroke-width="3"/>
    <ellipse cx="${SX}" cy="${SY - 1}" rx="112" ry="23" fill="url(#htSkin)"/>
    <ellipse cx="${SX + 26}" cy="${SY - 3}" rx="62" ry="10" fill="#fff6d8" opacity="0.5" filter="url(#bl6)"/>
    <path d="M ${SX + 30} ${SY - 22} Q ${SX + 96} ${SY - 18} ${SX + 112} ${SY - 2}" fill="none" stroke="#fff3c4" stroke-width="3" stroke-linecap="round" opacity="0.8"/>
    <path d="M ${SX + 100} ${SY + 8} L ${SX + 100} ${SY + 50}" stroke="#ffe7a8" stroke-width="3" opacity="0.4" stroke-linecap="round"/>`;
  // Foreground: drumsticks and a fallen block bottom-right of the stage; marbles.
  const near = `
    <path d="M 334 410 L 420 388" stroke="#120a18" stroke-width="8" stroke-linecap="round" opacity="0.5" filter="url(#bl3)"/><path d="M 330 404 L 418 380" stroke="#c99a5a" stroke-width="7" stroke-linecap="round"/><circle cx="420" cy="379" r="7" fill="#e8c890" stroke="${INKD}" stroke-width="2"/>
    <path d="M 330 404 L 418 380" stroke="${INKD}" stroke-width="1.6" opacity="0.4" transform="translate(0 3)"/>
    ${block(360, 344, 34, "#4a8a5a", "star", 1, 0.25)}
    <circle cx="80" cy="398" r="9" fill="#6aa8e0" stroke="${INKD}" stroke-width="2"/><circle cx="77" cy="395" r="2.5" fill="#fff" opacity="0.7"/>
    <circle cx="452" cy="400" r="7" fill="#e07a6a" stroke="${INKD}" stroke-width="2"/><circle cx="450" cy="398" r="2" fill="#fff" opacity="0.7"/>`;
  // Paper stars hanging from the ceiling (mobile), top centre/right, dim.
  const hang = [[300, 70, 9], [356, 40, 7], [452, 96, 8], [520, 50, 6], [640, 80, 7]].map(([x, y, r]) => {
    let p = "";
    for (let k = 0; k < 10; k++) { const a = -Math.PI / 2 + (k * Math.PI) / 5, rr = k % 2 ? r * 0.48 : r; p += `${f(x + Math.cos(a) * rr)},${f(y + Math.sin(a) * rr)} `; }
    return `<path d="M ${x} 0 L ${x} ${y - r}" stroke="#6a5a90" stroke-width="1" opacity="0.6"/><polygon points="${p}" fill="#e8c860" opacity="0.75" stroke="${INKD}" stroke-width="1.2"/>`;
  }).join("");

  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${blurs()}
  <defs>
    <linearGradient id="htWall" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#14122e"/><stop offset="0.6" stop-color="#241f4a"/><stop offset="1" stop-color="#352a58"/></linearGradient>
    <linearGradient id="htWin" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#2a4a8a" stop-opacity="0.6"/><stop offset="1" stop-color="#0e1a40" stop-opacity="0.4"/></linearGradient>
    <linearGradient id="htFloor" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6a4434"/><stop offset="0.5" stop-color="#4a2e2e"/><stop offset="1" stop-color="#26182a"/></linearGradient>
    <linearGradient id="htDrum" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#7a2e36"/><stop offset="0.45" stop-color="#b8443e"/><stop offset="0.8" stop-color="#d8604a"/><stop offset="1" stop-color="#a8403e"/></linearGradient>
    <radialGradient id="htMoon" cx="0.35" cy="0.4" r="0.8"><stop offset="0" stop-color="#fffbe8"/><stop offset="0.6" stop-color="#ffe7a0"/><stop offset="1" stop-color="#f0b850"/></radialGradient>
    <radialGradient id="htSkin" cx="0.62" cy="0.4" r="0.7"><stop offset="0" stop-color="#fff2d0"/><stop offset="0.6" stop-color="#ecd6a6"/><stop offset="1" stop-color="#c8a878"/></radialGradient>
    ${dimDefs()}
  </defs>
  ${wall}${win}${hang}
  ${floor}${light}
  ${towers}${track}${rkt}${train}${bg}
  ${stage}${near}
  ${motes(61, 22, 0, 120, 780, 400, ["#ffe2a0", "#ffd98a", "#fff3d0"])}
  ${fades("ht", { right: 0.42 })}
  </svg>`;
}

export const many = {
  hab_toybox: scene,
  hab_toybox_ctx: withHero(scene, "#ffc93c", "propeller", "#ffd98a"),
};
export default scene;

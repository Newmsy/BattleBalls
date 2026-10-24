// Fusion Lab chamber (game/ui/fuse_art, the Fuse tab's stage): a round dais with three glowing pedestals (where the
// game stands the three copies) feeding a hovering core, under a big reactor
// ring humming on the back wall. Bubbling glass tubes either side, cables on
// the floor. Top-left kept dark and calm for the screen title. The pedestals
// are empty: the game draws the critters on top, so the art never changes.
// band: true gives the short 720x220 header band (fuse_band.mjs).
// PADS and CORE must match fuse_screen.gd.
import { motes, shade, rng, sparkle } from "./_banner_parts.mjs";
import { blurs } from "./_shop_charge_pad_glow_chest_parts.mjs";
import { f } from "./_map_token.mjs";

export const size = [720, 680];
export const dir = "game/ui/fuse_art";
export const W = 720, H = 680;
const OFF = 80; // headroom above the ring for the title
// Pedestal centres (top of the emitter pad); the game places slots here.
export const PADS = [[360, 382 + OFF, 0.82], [184, 506 + OFF, 1], [536, 506 + OFF, 1]];
export const CORE = [360, 452 + OFF];

const VIO = "#b98cff", CY = "#5ce1ff", PK = "#ff7ad9";

function wall(R, h) {
  let out = `<defs>
    <linearGradient id="lcWall" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#151036"/><stop offset="1" stop-color="#211a52"/></linearGradient>
  </defs><rect width="${W}" height="${h}" fill="url(#lcWall)"/>`;
  // Riveted plates, staggered rows, dimmer towards the top.
  for (let row = 0; row < 6; row++) {
    const y = row * 70 - 10, off = row % 2 ? 60 : 0;
    for (let x = -off; x < W; x += 120) {
      const o = 0.25 + row * 0.07;
      out += `<rect x="${x + 3}" y="${y + 3}" width="114" height="64" rx="6" fill="#2a2260" opacity="${f(o)}"/>
        <rect x="${x + 3}" y="${y + 3}" width="114" height="3" rx="1.5" fill="#4a3f94" opacity="${f(o)}"/>`;
      for (const [rx, ry] of [[10, 10], [110, 10], [10, 60], [110, 60]])
        out += `<circle cx="${x + rx}" cy="${y + ry}" r="2.2" fill="#3c3384" opacity="${f(o + 0.15)}"/>`;
    }
  }
  // Wall pipes running across behind the ring.
  out += `<path d="M -10 160 L 190 160 Q 210 160 210 140 L 210 60" fill="none" stroke="#120d30" stroke-width="16"/>
    <path d="M -10 160 L 190 160 Q 210 160 210 140 L 210 60" fill="none" stroke="#3a3180" stroke-width="10"/>
    <path d="M -10 157 L 190 157" stroke="#5a4fb0" stroke-width="2" opacity="0.6"/>
    <path d="M 730 196 L 530 196 Q 512 196 512 176 L 512 40" fill="none" stroke="#120d30" stroke-width="16"/>
    <path d="M 730 196 L 530 196 Q 512 196 512 176 L 512 40" fill="none" stroke="#3a3180" stroke-width="10"/>
    <path d="M 730 193 L 530 193" stroke="#5a4fb0" stroke-width="2" opacity="0.6"/>`;
  for (const [x, y] of [[120, 160], [620, 196]])
    out += `<rect x="${x - 7}" y="${y - 10}" width="14" height="20" rx="3" fill="#251d5a" stroke="#120d30" stroke-width="2"/>`;
  // Little status lights along the pipes.
  for (const [x, y, c] of [[60, 160, CY], [90, 160, VIO], [660, 196, PK], [690, 196, CY]])
    out += `<circle cx="${x}" cy="${y}" r="7" fill="${c}" opacity="0.4" filter="url(#bl3)"/><circle cx="${x}" cy="${y}" r="3" fill="${c}"/>`;
  return out;
}

// The reactor ring on the back wall: thick metal torus, glowing inner rim,
// swirling energy disc, clamps.
function ring(cx, cy, r) {
  let out = `<defs>
    <radialGradient id="lcDisc" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#f4eaff" stop-opacity="0.9"/><stop offset="0.25" stop-color="${VIO}" stop-opacity="0.65"/><stop offset="0.7" stop-color="#5a3fd0" stop-opacity="0.35"/><stop offset="1" stop-color="#2a1a70" stop-opacity="0.1"/></radialGradient>
    <linearGradient id="lcMetal" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5a52a8"/><stop offset="0.5" stop-color="#2c2668"/><stop offset="1" stop-color="#1a1546"/></linearGradient>
  </defs>
  <circle cx="${cx}" cy="${cy}" r="${r + 40}" fill="${VIO}" opacity="0.18" filter="url(#bl24)"/>
  <circle cx="${cx}" cy="${cy}" r="${r - 14}" fill="url(#lcDisc)"/>`;
  // Swirl arms inside the disc.
  for (let k = 0; k < 5; k++) {
    const a0 = (k / 5) * Math.PI * 2;
    let d = "";
    for (let t = 0; t <= 1.001; t += 0.1) {
      const a = a0 + t * 2.2, rr = (r - 22) * (1 - t * 0.85);
      d += `${t ? "L" : "M"} ${f(cx + Math.cos(a) * rr)} ${f(cy + Math.sin(a) * rr)} `;
    }
    out += `<path d="${d}" fill="none" stroke="${k % 2 ? CY : "#efe2ff"}" stroke-width="${k % 2 ? 2.5 : 3.5}" stroke-linecap="round" opacity="0.55"/>`;
  }
  out += `<circle cx="${cx}" cy="${cy}" r="18" fill="#fff" opacity="0.85" filter="url(#bl6)"/>
    <circle cx="${cx}" cy="${cy}" r="${r}" fill="none" stroke="#0e0a28" stroke-width="40"/>
    <circle cx="${cx}" cy="${cy}" r="${r}" fill="none" stroke="url(#lcMetal)" stroke-width="32"/>
    <circle cx="${cx}" cy="${cy}" r="${r + 10}" fill="none" stroke="#7a70d0" stroke-width="2" opacity="0.5"/>
    <circle cx="${cx}" cy="${cy}" r="${r - 15}" fill="none" stroke="${CY}" stroke-width="7" opacity="0.6" filter="url(#bl4)"/>
    <circle cx="${cx}" cy="${cy}" r="${r - 15}" fill="none" stroke="#d6f8ff" stroke-width="2.5"/>`;
  // Segment lights round the torus.
  for (let k = 0; k < 16; k++) {
    const a = (k / 16) * Math.PI * 2, x = cx + Math.cos(a) * r, y = cy + Math.sin(a) * r;
    out += `<circle cx="${f(x)}" cy="${f(y)}" r="3.2" fill="${k % 4 ? "#9d8cff" : PK}" opacity="${k % 4 ? 0.7 : 1}"/>`;
  }
  // Four clamps.
  for (const a of [Math.PI / 4, (3 * Math.PI) / 4, (5 * Math.PI) / 4, (7 * Math.PI) / 4]) {
    const x = cx + Math.cos(a) * r, y = cy + Math.sin(a) * r, deg = (a * 180) / Math.PI;
    out += `<g transform="rotate(${f(deg)} ${f(x)} ${f(y)})"><rect x="${f(x - 26)}" y="${f(y - 13)}" width="52" height="26" rx="6" fill="#1f1950" stroke="#0e0a28" stroke-width="3"/>
      <rect x="${f(x - 22)}" y="${f(y - 10)}" width="44" height="5" rx="2" fill="#6a60c0" opacity="0.7"/></g>`;
  }
  return out;
}

// A tall glass tube full of bubbling liquid.
function tube(x, y0, y1, w, col, R) {
  const h = y1 - y0;
  let out = `<rect x="${x - w / 2 - 14}" y="${y0 + 20}" width="${w + 28}" height="${h - 20}" fill="${col}" opacity="0.14" filter="url(#bl16)"/>
    <rect x="${x - w / 2}" y="${y0}" width="${w}" height="${h}" rx="${w / 2}" fill="#1b1648" opacity="0.8"/>
    <rect x="${x - w / 2 + 4}" y="${y0 + h * 0.22}" width="${w - 8}" height="${h * 0.78 - 4}" rx="${w / 2 - 4}" fill="${col}" opacity="0.55"/>
    <rect x="${x - w / 2 + 4}" y="${y0 + h * 0.22}" width="${w - 8}" height="10" rx="5" fill="${shade(col, 0.5)}" opacity="0.9"/>`;
  for (let k = 0; k < 14; k++) {
    const by = y0 + h * 0.26 + R() * h * 0.7, bx = x - w / 2 + 10 + R() * (w - 20), br = 2 + R() * 5;
    out += `<circle cx="${f(bx)}" cy="${f(by)}" r="${f(br)}" fill="none" stroke="${shade(col, 0.6)}" stroke-width="1.6" opacity="0.8"/>`;
  }
  out += `<rect x="${x - w / 2 + 6}" y="${y0 + 8}" width="7" height="${h - 16}" rx="3.5" fill="#fff" opacity="0.22"/>
    <rect x="${x - w / 2}" y="${y0}" width="${w}" height="${h}" rx="${w / 2}" fill="none" stroke="#8f86e0" stroke-width="2.5" opacity="0.55"/>
    <rect x="${x - w / 2 - 8}" y="${y0 - 14}" width="${w + 16}" height="26" rx="6" fill="#2c2668" stroke="#0e0a28" stroke-width="3"/>
    <rect x="${x - w / 2 - 8}" y="${y1 - 12}" width="${w + 16}" height="30" rx="6" fill="#2c2668" stroke="#0e0a28" stroke-width="3"/>
    <rect x="${x - w / 2 - 4}" y="${y0 - 10}" width="${w + 8}" height="4" rx="2" fill="#6a60c0" opacity="0.8"/>
    <rect x="${x - w / 2 - 4}" y="${y1 - 8}" width="${w + 8}" height="4" rx="2" fill="#6a60c0" opacity="0.8"/>`;
  return out;
}

function floor(y0) {
  let out = `<defs><linearGradient id="lcFloor" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#1c1648"/><stop offset="1" stop-color="#0f0c2a"/></linearGradient></defs>
    <rect x="0" y="${y0}" width="${W}" height="${H - y0}" fill="url(#lcFloor)"/>
    <rect x="0" y="${y0}" width="${W}" height="3" fill="#3a3180" opacity="0.8"/>`;
  // Perspective grid converging on the centre.
  for (let k = -8; k <= 8; k++)
    out += `<line x1="${360 + k * 30}" y1="${y0}" x2="${360 + k * 150}" y2="${H}" stroke="#4a3fa0" stroke-width="1.2" opacity="0.28"/>`;
  for (let k = 1; k < 7; k++) {
    const y = y0 + (H - y0) * Math.pow(k / 7, 1.6);
    out += `<line x1="0" y1="${f(y)}" x2="${W}" y2="${f(y)}" stroke="#4a3fa0" stroke-width="1.2" opacity="0.22"/>`;
  }
  return out;
}

function cables() {
  return `<path d="M 74 440 Q 70 520 20 560 Q 0 575 -10 576" fill="none" stroke="#0c0922" stroke-width="13" stroke-linecap="round"/>
    <path d="M 74 440 Q 70 520 20 560 Q 0 575 -10 576" fill="none" stroke="#2a2470" stroke-width="8" stroke-linecap="round"/>
    <path d="M 646 440 Q 650 530 712 566" fill="none" stroke="#0c0922" stroke-width="13" stroke-linecap="round"/>
    <path d="M 646 440 Q 650 530 712 566" fill="none" stroke="#2a2470" stroke-width="8" stroke-linecap="round"/>
    <path d="M 100 420 Q 140 440 120 470" fill="none" stroke="#0c0922" stroke-width="9"/>
    <path d="M 100 420 Q 140 440 120 470" fill="none" stroke="#352c86" stroke-width="5"/>`;
}

// The round dais with three channels feeding the core.
function dais(cx, cy) {
  const rx = 300, ry = 108, th = 30;
  let out = `<defs>
    <linearGradient id="lcSide" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#140f38"/><stop offset="0.5" stop-color="#2c2470"/><stop offset="1" stop-color="#140f38"/></linearGradient>
    <radialGradient id="lcTop" cx="0.5" cy="0.45" r="0.6"><stop offset="0" stop-color="#3a2f8c"/><stop offset="0.7" stop-color="#271f66"/><stop offset="1" stop-color="#1c1650"/></radialGradient>
  </defs>
  <ellipse cx="${cx}" cy="${cy + th + 14}" rx="${rx + 26}" ry="${ry * 0.55}" fill="#000" opacity="0.55" filter="url(#bl12)"/>
  <path d="M ${cx - rx} ${cy} L ${cx - rx} ${cy + th} A ${rx} ${ry} 0 0 0 ${cx + rx} ${cy + th} L ${cx + rx} ${cy} Z" fill="url(#lcSide)"/>
  <path d="M ${cx - rx} ${cy + th} A ${rx} ${ry} 0 0 0 ${cx + rx} ${cy + th}" fill="none" stroke="${VIO}" stroke-width="3" opacity="0.45"/>`;
  // Side light strips.
  for (let k = 1; k < 12; k++) {
    const a = Math.PI - (k / 12) * Math.PI, x = cx + Math.cos(a) * rx, y = cy + Math.sin(a) * ry + th / 2;
    out += `<rect x="${f(x - 7)}" y="${f(y - 3)}" width="14" height="6" rx="3" fill="${k % 3 ? "#7a6cf0" : CY}" opacity="0.8"/>`;
  }
  out += `<ellipse cx="${cx}" cy="${cy}" rx="${rx}" ry="${ry}" fill="url(#lcTop)" stroke="#5a4fc0" stroke-width="3"/>
    <ellipse cx="${cx}" cy="${cy}" rx="${rx - 22}" ry="${ry - 9}" fill="none" stroke="${VIO}" stroke-width="2.5" stroke-dasharray="16 10" opacity="0.6"/>
    <ellipse cx="${cx}" cy="${cy}" rx="${rx * 0.55}" ry="${ry * 0.55}" fill="none" stroke="#4a40a8" stroke-width="2"/>
    <ellipse cx="${cx}" cy="${cy}" rx="${rx * 0.25}" ry="${ry * 0.25}" fill="#160f40" stroke="#6a5ed8" stroke-width="2"/>`;
  // Channels from each pad to the core: dark groove + glowing filament.
  for (const [x, y] of PADS) {
    const py = y + 22;
    out += `<line x1="${x}" y1="${py}" x2="${cx}" y2="${cy}" stroke="#0e0a2c" stroke-width="12" stroke-linecap="round"/>
      <line x1="${x}" y1="${py}" x2="${cx}" y2="${cy}" stroke="${CY}" stroke-width="6" stroke-linecap="round" opacity="0.5" filter="url(#bl3)"/>
      <line x1="${x}" y1="${py}" x2="${cx}" y2="${cy}" stroke="#d6f8ff" stroke-width="2" stroke-linecap="round"/>`;
  }
  return out;
}

// A pedestal: short metal drum with a glowing emitter pad and a soft beam.
function pad(x, y, s) {
  const rx = 66 * s, ry = 21 * s, h = 26 * s;
  return `<ellipse cx="${x}" cy="${y + h + 4}" rx="${rx + 8}" ry="${ry}" fill="#000" opacity="0.5" filter="url(#bl4)"/>
    <path d="M ${x - rx} ${y} L ${x - rx} ${y + h} A ${rx} ${ry} 0 0 0 ${x + rx} ${y + h} L ${x + rx} ${y} Z" fill="url(#lcSide)"/>
    <path d="M ${x - rx} ${y + h * 0.55} A ${rx} ${ry} 0 0 0 ${x + rx} ${y + h * 0.55}" fill="none" stroke="${CY}" stroke-width="${3 * s}" opacity="0.8"/>
    <ellipse cx="${x}" cy="${y}" rx="${rx}" ry="${ry}" fill="#2c2470" stroke="#6a5ed8" stroke-width="3"/>
    <ellipse cx="${x}" cy="${y}" rx="${rx * 0.78}" ry="${ry * 0.74}" fill="${CY}" opacity="0.55" filter="url(#bl4)"/>
    <ellipse cx="${x}" cy="${y}" rx="${rx * 0.72}" ry="${ry * 0.66}" fill="#7feaff" opacity="0.75"/>
    <ellipse cx="${x}" cy="${y}" rx="${rx * 0.42}" ry="${ry * 0.38}" fill="#e6fdff"/>
    <path d="M ${x - rx * 0.7} ${y} L ${x - rx * 0.45} ${y - 150 * s} L ${x + rx * 0.45} ${y - 150 * s} L ${x + rx * 0.7} ${y} Z" fill="${CY}" opacity="0.13" filter="url(#bl6)"/>`;
}

function core(cx, cy, top) {
  return `<path d="M ${cx - 10} ${cy} L ${cx - 4} ${top} L ${cx + 4} ${top} L ${cx + 10} ${cy} Z" fill="#efe2ff" opacity="0.35" filter="url(#bl6)"/>
    <line x1="${cx}" y1="${cy - 20}" x2="${cx}" y2="${top}" stroke="#fff" stroke-width="2" opacity="0.6"/>
    <circle cx="${cx}" cy="${cy - 26}" r="44" fill="${VIO}" opacity="0.45" filter="url(#bl16)"/>
    <polygon points="${cx},${cy - 60} ${cx + 18},${cy - 30} ${cx},${cy - 2} ${cx - 18},${cy - 30}" fill="#d9c8ff" stroke="#6a4fd8" stroke-width="3" stroke-linejoin="round"/>
    <polygon points="${cx},${cy - 60} ${cx + 18},${cy - 30} ${cx},${cy - 30}" fill="#fff" opacity="0.8"/>
    <polygon points="${cx},${cy - 2} ${cx - 18},${cy - 30} ${cx},${cy - 30}" fill="#9c7cff" opacity="0.8"/>
    ${sparkle(cx + 22, cy - 58, 8, "#fff", 0.9)}${sparkle(cx - 26, cy - 14, 5, "#d6f8ff", 0.8)}`;
}

export default function ({ band = false } = {}) {
  const R = rng(17);
  if (band) {
    // Header band: ring pushed right, tubes either side of it, title space left.
    return `<svg xmlns="http://www.w3.org/2000/svg" width="720" height="220" viewBox="0 0 720 220">${blurs()}
      ${wall(R, 220)}
      <g transform="translate(212 -46) scale(0.78)">${ring(360, 200, 128)}</g>
      ${tube(672, 34, 236, 50, PK, R)}${tube(318, 50, 236, 40, CY, R)}
      ${motes(4, 16, 300, 20, 720, 210, [VIO, CY, "#fff"])}
      <rect width="720" height="220" fill="url(#lcFadeL)"/>
      <defs><linearGradient id="lcFadeL" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#0D0F26" stop-opacity="0.7"/><stop offset="0.45" stop-color="#0D0F26" stop-opacity="0"/></linearGradient></defs>
    </svg>`;
  }
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${blurs()}
    ${wall(R, 400 + OFF)}
    <g transform="translate(0 ${OFF})">
    ${ring(360, 236, 150)}
    ${tube(74, 70, 440, 64, CY, R)}${tube(646, 70, 440, 64, PK, R)}
    </g>
    ${floor(396 + OFF)}
    <g transform="translate(0 ${OFF})">${cables()}</g>
    ${dais(CORE[0], CORE[1])}
    ${pad(...PADS[0])}
    ${core(CORE[0], CORE[1] + 14, 236 + OFF)}
    ${pad(...PADS[1])}${pad(...PADS[2])}
    ${motes(9, 30, 120, 60, 600, 640, [VIO, CY, "#fff", PK])}
    <defs>
      <linearGradient id="lcTopFade" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0D0F26" stop-opacity="0"/><stop offset="0.9" stop-color="#0D0F26" stop-opacity="0"/><stop offset="1" stop-color="#0D0F26" stop-opacity="0.8"/></linearGradient>
    </defs>
    <rect width="${W}" height="${H}" fill="url(#lcTopFade)"/>
  </svg>`;
}

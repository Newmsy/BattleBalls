// Boon banner, a reward moment: above a little shrine pedestal a boon shield
// floats inside a glass orb, bursting with light; sparks spiral up from the
// pedestal and a happy critter gazes up at it.
import { svg, blurs, sparkle } from "./_shop_charge_pad_glow_chest_parts.mjs";
import { critter, shadow, sky, motes, edges, FAM, star5, rng, shade } from "./_banner_parts.mjs";

const OX = 372, OY = 150, OR = 74; // the orb
const TEAL = "#3EE6D8", VIO = "#b98cff", GOLD = "#ffd34e";

function backdrop() {
  // Ruined temple columns at the sides, hills, a soft teal sky glow behind the orb.
  const column = (x, h, w, o) => `<g opacity="${o}">
      <rect x="${x - w / 2}" y="${320 - h}" width="${w}" height="${h}" fill="#221c5e"/>
      ${[0.2, 0.5, 0.8].map((t) => `<line x1="${x - w / 2 + w * t}" y1="${330 - h}" x2="${x - w / 2 + w * t}" y2="312" stroke="#16123f" stroke-width="3"/>`).join("")}
      <rect x="${x - w / 2 - 8}" y="${320 - h - 14}" width="${w + 16}" height="16" rx="3" fill="#2c2570"/>
      <rect x="${x - w / 2 - 6}" y="306" width="${w + 12}" height="16" rx="3" fill="#2c2570"/>
      <rect x="${x - w / 2}" y="${320 - h}" width="5" height="${h}" fill="#5a50b0" opacity="0.4"/></g>`;
  return `
  <defs>
    <radialGradient id="bbBg" cx="0.52" cy="0.36" r="0.8"><stop offset="0" stop-color="#2e5a8a"/><stop offset="0.25" stop-color="#2c2170"/><stop offset="0.65" stop-color="#141038"/><stop offset="1" stop-color="#0D0F26"/></radialGradient>
    <linearGradient id="bbGround" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#241d66"/><stop offset="1" stop-color="#0D0F26"/></linearGradient>
  </defs>
  <rect width="720" height="440" fill="url(#bbBg)"/>
  ${sky(41, 110, 0, 0, 720, 280)}
  <path d="M 0 286 Q 140 246 280 272 Q 420 240 560 266 Q 650 250 720 270 L 720 330 L 0 330 Z" fill="#1a1550"/>
  ${column(84, 190, 40, 0.95)}
  ${column(164, 130, 34, 0.75)}
  ${column(636, 200, 40, 0.95)}
  <!-- broken column stub on the right -->
  <path d="M 540 320 L 540 238 L 552 228 L 562 240 L 574 232 L 574 320 Z" fill="#221c5e" opacity="0.75"/>
  <path d="M 0 316 Q 360 296 720 316 L 720 440 L 0 440 Z" fill="url(#bbGround)"/>
  <ellipse cx="${OX}" cy="352" rx="250" ry="50" fill="${TEAL}" opacity="0.18" filter="url(#bl24)"/>`;
}

function rays() {
  let out = "";
  const n = 18;
  for (let k = 0; k < n; k++) {
    const a = (k / n) * Math.PI * 2 + 0.1;
    const w = 0.05 + (k % 3) * 0.025;
    const L = 300 + (k % 2) * 120;
    out += `<polygon points="${OX},${OY} ${OX + Math.cos(a - w) * L},${OY + Math.sin(a - w) * L} ${OX + Math.cos(a + w) * L},${OY + Math.sin(a + w) * L}" fill="url(#bbRay)" opacity="${k % 2 ? 0.4 : 0.7}"/>`;
  }
  return `
  <defs><radialGradient id="bbRay" gradientUnits="userSpaceOnUse" cx="${OX}" cy="${OY}" r="400"><stop offset="0" stop-color="#e8fffb" stop-opacity="0.8"/><stop offset="0.3" stop-color="${TEAL}" stop-opacity="0.35"/><stop offset="1" stop-color="${VIO}" stop-opacity="0"/></radialGradient></defs>
  <circle cx="${OX}" cy="${OY}" r="190" fill="${TEAL}" opacity="0.22" filter="url(#bl40)"/>
  <g filter="url(#bl4)">${out}</g>`;
}

function pedestal() {
  const top = 300, w = 70;
  return `
  <defs>
    <linearGradient id="bbStone" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#2a2468"/><stop offset="0.45" stop-color="#5a50b0"/><stop offset="1" stop-color="#211c58"/></linearGradient>
    <linearGradient id="bbBeam" x1="0" y1="1" x2="0" y2="0"><stop offset="0" stop-color="${TEAL}" stop-opacity="0.7"/><stop offset="1" stop-color="${TEAL}" stop-opacity="0"/></linearGradient>
  </defs>
  ${shadow(OX, 384, 110, 0.6)}
  <!-- beam from the pedestal up into the orb -->
  <path d="M ${OX - 40} ${top} L ${OX - 60} ${OY} L ${OX + 60} ${OY} L ${OX + 40} ${top} Z" fill="url(#bbBeam)" filter="url(#bl6)"/>
  <!-- base steps -->
  <path d="M ${OX - w - 30} 362 L ${OX + w + 30} 362 L ${OX + w + 34} 384 L ${OX - w - 34} 384 Z" fill="#2a2468" stroke="#0e0b28" stroke-width="2.5"/>
  <rect x="${OX - w - 30}" y="361" width="${(w + 30) * 2}" height="4" fill="#7a70d0" opacity="0.6"/>
  <!-- column -->
  <path d="M ${OX - w + 18} ${top + 14} L ${OX + w - 18} ${top + 14} L ${OX + w - 8} 362 L ${OX - w + 8} 362 Z" fill="url(#bbStone)" stroke="#0e0b28" stroke-width="2.5"/>
  ${[-0.5, 0, 0.5].map((t) => `<line x1="${OX + t * (w - 20)}" y1="${top + 18}" x2="${OX + t * (w - 10)}" y2="358" stroke="#16123f" stroke-width="3" opacity="0.6"/>`).join("")}
  <!-- glowing rune band -->
  <rect x="${OX - w + 14}" y="330" width="${(w - 14) * 2}" height="8" fill="${TEAL}" opacity="0.6" filter="url(#bl3)"/>
  ${[-36, -18, 0, 18, 36].map((dx) => `<rect x="${OX + dx - 4}" y="331" width="8" height="6" rx="2" fill="#c8fff9"/>`).join("")}
  <!-- top dish -->
  <ellipse cx="${OX}" cy="${top + 12}" rx="${w + 6}" ry="16" fill="#1e1a4a" stroke="#0e0b28" stroke-width="2.5"/>
  <ellipse cx="${OX}" cy="${top + 6}" rx="${w}" ry="15" fill="#3a3290" stroke="#c8fff9" stroke-width="2.5"/>
  <ellipse cx="${OX}" cy="${top + 6}" rx="${w - 16}" ry="9" fill="${TEAL}" opacity="0.8" filter="url(#bl4)"/>
  <ellipse cx="${OX}" cy="${top + 6}" rx="${w - 30}" ry="5" fill="#fff"/>`;
}

// The boon: a heater shield with a star, floating in a glass orb.
function orb() {
  const s = 46; // shield half-width
  const sh = `M ${OX - s} ${OY - s * 0.95} Q ${OX} ${OY - s * 1.2} ${OX + s} ${OY - s * 0.95} L ${OX + s} ${OY - s * 0.1} Q ${OX + s * 0.9} ${OY + s * 0.85} ${OX} ${OY + s * 1.25} Q ${OX - s * 0.9} ${OY + s * 0.85} ${OX - s} ${OY - s * 0.1} Z`;
  const shIn = `M ${OX - s * 0.76} ${OY - s * 0.76} Q ${OX} ${OY - s * 0.95} ${OX + s * 0.76} ${OY - s * 0.76} L ${OX + s * 0.76} ${OY - s * 0.1} Q ${OX + s * 0.68} ${OY + s * 0.66} ${OX} ${OY + s * 0.98} Q ${OX - s * 0.68} ${OY + s * 0.66} ${OX - s * 0.76} ${OY - s * 0.1} Z`;
  return `
  <defs>
    <radialGradient id="bbGlass" cx="0.38" cy="0.32" r="0.75"><stop offset="0" stop-color="#ffffff" stop-opacity="0.35"/><stop offset="0.55" stop-color="${TEAL}" stop-opacity="0.12"/><stop offset="0.9" stop-color="${VIO}" stop-opacity="0.35"/><stop offset="1" stop-color="#ffffff" stop-opacity="0.6"/></radialGradient>
    <linearGradient id="bbShield" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#8ff8ee"/><stop offset="0.5" stop-color="#22b8b0"/><stop offset="1" stop-color="#0b5a62"/></linearGradient>
    <linearGradient id="bbShieldIn" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9a7bff"/><stop offset="1" stop-color="#3a2a9a"/></linearGradient>
    <linearGradient id="bbGold" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff4c0"/><stop offset="0.5" stop-color="${GOLD}"/><stop offset="1" stop-color="#c07a1a"/></linearGradient>
  </defs>
  <circle cx="${OX}" cy="${OY}" r="${OR * 1.4}" fill="#e8fffb" opacity="0.4" filter="url(#bl24)"/>
  <circle cx="${OX}" cy="${OY}" r="${OR}" fill="#1a2a6a" opacity="0.55"/>
  <circle cx="${OX}" cy="${OY}" r="${OR * 0.75}" fill="${TEAL}" opacity="0.45" filter="url(#bl12)"/>
  <!-- shield -->
  <path d="${sh}" fill="${TEAL}" opacity="0.6" filter="url(#bl8)" transform="translate(0 2)"/>
  <path d="${sh}" fill="url(#bbGold)" stroke="#6a3e0a" stroke-width="3" stroke-linejoin="round"/>
  <path d="${shIn}" fill="url(#bbShieldIn)" stroke="#2a1a6a" stroke-width="2"/>
  <path d="M ${OX - s * 0.76} ${OY - s * 0.76} Q ${OX} ${OY - s * 0.95} ${OX + s * 0.76} ${OY - s * 0.76} L ${OX + s * 0.76} ${OY - s * 0.2} Q ${OX} ${OY - s * 0.05} ${OX - s * 0.76} ${OY - s * 0.2} Z" fill="#fff" opacity="0.14"/>
  <polygon points="${star5(OX, OY + 2, s * 0.52, 0.48)}" fill="${GOLD}" opacity="0.7" filter="url(#bl4)"/>
  <polygon points="${star5(OX, OY + 2, s * 0.46, 0.48)}" fill="url(#bbGold)" stroke="#8a5210" stroke-width="2.5" stroke-linejoin="round"/>
  <circle cx="${OX}" cy="${OY + 2}" r="${s * 0.1}" fill="#fff"/>
  <!-- glass orb over everything -->
  <circle cx="${OX}" cy="${OY}" r="${OR}" fill="url(#bbGlass)" stroke="#e8fffb" stroke-width="3"/>
  <circle cx="${OX}" cy="${OY}" r="${OR + 6}" fill="none" stroke="${TEAL}" stroke-width="6" opacity="0.5" filter="url(#bl4)"/>
  <path d="M ${OX - OR * 0.72} ${OY - OR * 0.2} A ${OR * 0.76} ${OR * 0.76} 0 0 1 ${OX - OR * 0.2} ${OY - OR * 0.72}" fill="none" stroke="#fff" stroke-width="7" stroke-linecap="round" opacity="0.75"/>
  <circle cx="${OX + OR * 0.5}" cy="${OY + OR * 0.52}" r="5" fill="#fff" opacity="0.6"/>
  <!-- orbiting ring -->
  <ellipse cx="${OX}" cy="${OY}" rx="${OR * 1.45}" ry="${OR * 0.32}" fill="none" stroke="${GOLD}" stroke-width="3" opacity="0.8" transform="rotate(-14 ${OX} ${OY})" stroke-dasharray="70 18 12 18"/>`;
}

function sparks() {
  const r = rng(9);
  let out = "";
  // Spiral of sparks rising from the dish into the orb.
  for (let k = 0; k < 22; k++) {
    const t = k / 22;
    const a = t * Math.PI * 4;
    const x = OX + Math.cos(a) * (60 - t * 30), y = 300 - t * 150 + Math.sin(a) * 8;
    out += `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="${(2 + (1 - t) * 2).toFixed(1)}" fill="${k % 3 ? "#c8fff9" : GOLD}" opacity="${(0.4 + 0.5 * Math.cos(a) * 0.5 + 0.3).toFixed(2)}"/>`;
  }
  // Burst sparkles around the orb.
  for (let k = 0; k < 14; k++) {
    const a = r() * Math.PI * 2, d = OR * (1.35 + r() * 1.2);
    out += sparkle(OX + Math.cos(a) * d * 1.3, OY + Math.sin(a) * d * 0.9, 4 + r() * 8, k % 3 ? "#e8fffb" : "#ffe9a8", 0.7 + r() * 0.3);
  }
  return out;
}

export default () =>
  svg(`${blurs()}
  ${backdrop()}
  ${rays()}
  ${motes(17, 24, 90, 60, 650, 380, [TEAL, GOLD, VIO])}
  ${pedestal()}
  ${orb()}
  ${sparks()}
  <!-- the happy critter, looking up at its new boon -->
  <circle cx="198" cy="330" r="80" fill="${FAM.sweet}" opacity="0.25" filter="url(#bl24)"/>
  ${shadow(198, 392, 52, 0.55)}
  ${critter(198, 340, 56, FAM.sweet, { acc: "ears", mood: "wow", look: [0.75, -0.65], rim: "#c8fff9", rimSide: 1, tilt: 8 })}
  ${sparkle(256, 262, 10, "#fff")}
  ${sparkle(140, 286, 6, "#ffd0ea", 0.8)}
  <!-- a tiny friend peeking from the right -->
  ${shadow(560, 380, 30, 0.5)}
  ${critter(560, 360, 30, FAM.frost, { acc: "crystal", mood: "cheer", tilt: -10 })}
  ${edges()}`);

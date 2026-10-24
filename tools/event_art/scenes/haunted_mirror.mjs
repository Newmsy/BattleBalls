// Spooky family: an ornate standing mirror in a dark manor. A critter looks in
// from the foreground; its reflection grins back as a ghost. Candles, purple mist.
import { ball, eye, brow, grin, shade, INK } from "../../brand/parts.mjs";

const SP = "#B88CFF";

function rng(seed) {
  let s = seed;
  return () => ((s = (s * 16807) % 2147483647) / 2147483647);
}

// Candle on a tall stick with a flame and warm-violet glow.
function candle(x, baseY, h, { lean = 0, melt = 1 } = {}) {
  const top = baseY - h;
  return `
  <ellipse cx="${x}" cy="${baseY + 2}" rx="26" ry="6" fill="#000" opacity="0.45"/>
  <path d="M ${x - 20} ${baseY} q 20 -10 40 0 Z" fill="#2a2148"/>
  <rect x="${x - 4}" y="${top + 34}" width="8" height="${h - 38}" fill="url(#hmBrass)"/>
  <ellipse cx="${x}" cy="${top + 64}" rx="9" ry="4" fill="#4a3c78"/>
  <path d="M ${x - 16} ${top + 34} q 16 8 32 0 l -4 8 q -12 5 -24 0 Z" fill="url(#hmBrass)"/>
  <rect x="${x - 9}" y="${top + 2}" width="18" height="34" rx="3" fill="url(#hmWax)"/>
  <path d="M ${x - 9} ${top + 6} q 3 ${10 * melt} 0 ${16 * melt} q 3 4 5 -2 q 1 -8 2 -14 Z" fill="#efe6ff"/>
  <path d="M ${x + 9} ${top + 6} q -3 ${6 * melt} -1 ${10 * melt} q 2 3 1 -10 Z" fill="#efe6ff"/>
  <line x1="${x}" y1="${top + 2}" x2="${x}" y2="${top - 4}" stroke="#2a1a3a" stroke-width="2"/>
  <circle cx="${x}" cy="${top - 14}" r="34" fill="#ffb86a" opacity="0.28" filter="url(#hmGlowL)"/>
  <path d="M ${x} ${top - 32} q ${10 + lean} 14 ${6} ${26} q -6 6 -12 0 q -4 -12 ${6 + lean * 0.3} -26 Z" fill="#ffcf6a"/>
  <path d="M ${x} ${top - 22} q 5 9 3 15 q -3 3 -6 0 q -1 -8 3 -15 Z" fill="#fff6d8"/>`;
}

export default function () {
  const R = rng(11);
  const mx = 380, my = 212, mrx = 112, mry = 138;

  // Damask-ish wallpaper: rows of small diamonds and dots.
  let paper = "";
  for (let y = 10; y < 380; y += 46) {
    for (let x = ((y / 46) % 2) * 32 - 10; x < 740; x += 64) {
      paper += `<path d="M ${x} ${y - 12} l 9 12 l -9 12 l -9 -12 Z" fill="#2a2066"/><circle cx="${x + 32}" cy="${y}" r="2.5" fill="#2a2066"/>`;
    }
  }
  // Mist wisps.
  let mist = "";
  for (let k = 0; k < 9; k++) {
    const x = R() * 720, y = 330 + R() * 90;
    mist += `<ellipse cx="${x}" cy="${y}" rx="${90 + R() * 120}" ry="${16 + R() * 18}" fill="${SP}" opacity="${0.22 + R() * 0.18}"/>`;
  }
  // Dust motes / spirit sparks.
  let motes = "";
  for (let k = 0; k < 22; k++) {
    const x = 60 + R() * 600, y = 40 + R() * 320;
    motes += `<circle cx="${x}" cy="${y}" r="${0.8 + R() * 2}" fill="#e8dcff" opacity="${0.3 + R() * 0.5}"/>`;
  }

  // Frame ornaments: scroll crest on top, side scrolls, bottom bat-wing.
  const crest = `
    <path d="M ${mx - 60} ${my - mry + 6} q 20 -46 60 -50 q 40 4 60 50 q -26 -22 -60 -24 q -34 2 -60 24 Z" fill="url(#hmFrame)" stroke="#1a1130" stroke-width="2"/>
    <circle cx="${mx}" cy="${my - mry - 36}" r="13" fill="url(#hmFrame)" stroke="#1a1130" stroke-width="2"/>
    <circle cx="${mx}" cy="${my - mry - 36}" r="6" fill="${SP}"/>
    <circle cx="${mx}" cy="${my - mry - 36}" r="10" fill="${SP}" opacity="0.6" filter="url(#hmGlowS)"/>
    <path d="M ${mx - 74} ${my - mry + 22} q -30 -10 -26 -36 q 10 18 30 14" fill="none" stroke="url(#hmFrame)" stroke-width="7" stroke-linecap="round"/>
    <path d="M ${mx + 74} ${my - mry + 22} q 30 -10 26 -36 q -10 18 -30 14" fill="none" stroke="url(#hmFrame)" stroke-width="7" stroke-linecap="round"/>`;
  const sides = [-1, 1].map((d) => `
    <path d="M ${mx + d * (mrx + 10)} ${my - 30} q ${d * 26} 30 0 60" fill="none" stroke="url(#hmFrame)" stroke-width="8" stroke-linecap="round"/>
    <circle cx="${mx + d * (mrx + 22)}" cy="${my}" r="6" fill="url(#hmFrame)"/>`).join("");
  const bottom = `
    <path d="M ${mx - 46} ${my + mry - 4} q 20 30 46 34 q 26 -4 46 -34 q -20 10 -46 12 q -26 -2 -46 -12 Z" fill="url(#hmFrame)" stroke="#1a1130" stroke-width="2"/>`;

  // The ghost reflection: pale, translucent, grinning, with a wispy tail.
  const gx = mx + 4, gy = my - 4, gr = 74;
  const ghost = `
    <g opacity="0.95">
      <path d="M ${gx - gr} ${gy + 6} Q ${gx - gr} ${gy + gr + 40} ${gx - 30} ${gy + gr + 54} q 14 -18 28 4 q 14 -24 30 -2 q 20 -16 22 -40 Q ${gx + gr} ${gy + gr} ${gx + gr} ${gy}"
        fill="#d9c8ff" opacity="0.55" filter="url(#hmBlurS)"/>
      ${ball(gx, gy, gr, "#cbb6ff", { glow: true })}
      <ellipse cx="${gx}" cy="${gy + gr * 0.3}" rx="${gr * 0.95}" ry="${gr * 0.6}" fill="#8f6fe0" opacity="0.18"/>
      <!-- tuft, same as the real critter's -->
      <path d="M ${gx - 4} ${gy - gr + 4} q -16 -30 6 -38 q -2 18 12 32 Z" fill="#e6dbff" stroke="${shade("#cbb6ff", -0.5)}" stroke-width="3"/>
      <!-- glowing hollow eyes -->
      <ellipse cx="${gx - gr * 0.34}" cy="${gy - gr * 0.16}" rx="${gr * 0.25}" ry="${gr * 0.3}" fill="#2a1452"/>
      <ellipse cx="${gx + gr * 0.34}" cy="${gy - gr * 0.16}" rx="${gr * 0.25}" ry="${gr * 0.3}" fill="#2a1452"/>
      <circle cx="${gx - gr * 0.3}" cy="${gy - gr * 0.12}" r="${gr * 0.12}" fill="#7dffe0" filter="url(#hmGlowS)"/>
      <circle cx="${gx + gr * 0.38}" cy="${gy - gr * 0.12}" r="${gr * 0.12}" fill="#7dffe0" filter="url(#hmGlowS)"/>
      <circle cx="${gx - gr * 0.3}" cy="${gy - gr * 0.12}" r="${gr * 0.08}" fill="#eafff8"/>
      <circle cx="${gx + gr * 0.38}" cy="${gy - gr * 0.12}" r="${gr * 0.08}" fill="#eafff8"/>
      ${brow(gx - gr * 0.58, gy - gr * 0.56, gx - gr * 0.16, gy - gr * 0.42, gr * 0.08)}
      ${brow(gx + gr * 0.58, gy - gr * 0.56, gx + gr * 0.16, gy - gr * 0.42, gr * 0.08)}
      <!-- wide mischievous grin with fangs -->
      <path d="M ${gx - gr * 0.5} ${gy + gr * 0.22} Q ${gx} ${gy + gr * 0.36} ${gx + gr * 0.5} ${gy + gr * 0.16} Q ${gx + gr * 0.36} ${gy + gr * 0.72} ${gx} ${gy + gr * 0.7} Q ${gx - gr * 0.38} ${gy + gr * 0.7} ${gx - gr * 0.5} ${gy + gr * 0.22} Z" fill="${INK}"/>
      <path d="M ${gx - gr * 0.32} ${gy + gr * 0.27} l ${gr * 0.07} ${gr * 0.16} l ${gr * 0.07} ${-gr * 0.14} Z" fill="#fff"/>
      <path d="M ${gx + gr * 0.18} ${gy + gr * 0.27} l ${gr * 0.07} ${gr * 0.16} l ${gr * 0.07} ${-gr * 0.17} Z" fill="#fff"/>
      <ellipse cx="${gx + gr * 0.02}" cy="${gy + gr * 0.6}" rx="${gr * 0.2}" ry="${gr * 0.08}" fill="#ff7ab8"/>
    </g>`;

  // Real critter in the foreground, seen from behind (no face), same tuft.
  const cx = 150, cy = 352, cr = 54;
  const critter = `
    <ellipse cx="${cx + 6}" cy="${cy + cr - 2}" rx="${cr * 1.05}" ry="12" fill="#000" opacity="0.5"/>
    ${ball(cx, cy, cr, "#3EA8FF", { glow: false })}
    <circle cx="${cx}" cy="${cy}" r="${cr}" fill="url(#hmBack)"/>
    <ellipse cx="${cx + cr * 0.55}" cy="${cy - cr * 0.1}" rx="${cr * 0.3}" ry="${cr * 0.75}" fill="#ffb86a" opacity="0.22" filter="url(#hmBlurS)"/>
    <path d="M ${cx - 4} ${cy - cr + 4} q -14 -26 6 -34 q -2 16 11 28 Z" fill="${shade("#3EA8FF", 0.3)}" stroke="${shade("#3EA8FF", -0.5)}" stroke-width="3"/>
    <!-- rim light from the mirror -->
    <path d="M ${cx + cr * 0.3} ${cy - cr * 0.95} A ${cr} ${cr} 0 0 1 ${cx + cr} ${cy + cr * 0.05}" fill="none" stroke="#e6d8ff" stroke-width="3" opacity="0.8" stroke-linecap="round"/>
    <!-- a little nervous sweat drop -->
    <path d="M ${cx + cr * 0.8} ${cy - cr * 0.9} q 8 10 0 16 q -8 -6 0 -16 Z" fill="#bfefff"/>`;

  return `<svg xmlns="http://www.w3.org/2000/svg" width="720" height="440" viewBox="0 0 720 440">
  <defs>
    <radialGradient id="hmBg" cx="52%" cy="40%" r="70%">
      <stop offset="0" stop-color="#2c2170"/><stop offset="0.55" stop-color="#141038"/><stop offset="1" stop-color="#0a0a1e"/>
    </radialGradient>
    <radialGradient id="hmHalo" cx="50%" cy="50%" r="50%">
      <stop offset="0" stop-color="${SP}" stop-opacity="0.5"/><stop offset="1" stop-color="${SP}" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="hmGlass" cx="50%" cy="42%" r="62%">
      <stop offset="0" stop-color="#3b2a7a"/><stop offset="0.6" stop-color="#1c1448"/><stop offset="1" stop-color="#0c0a24"/>
    </radialGradient>
    <linearGradient id="hmFrame" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#b9a0e8"/><stop offset="0.35" stop-color="#6c52a8"/><stop offset="0.7" stop-color="#3a2a68"/><stop offset="1" stop-color="#1e1640"/>
    </linearGradient>
    <linearGradient id="hmBrass" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#3a2e60"/><stop offset="0.4" stop-color="#8a76c0"/><stop offset="1" stop-color="#2a2048"/>
    </linearGradient>
    <linearGradient id="hmWax" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#cfc0f0"/><stop offset="0.5" stop-color="#f4eeff"/><stop offset="1" stop-color="#a596cc"/>
    </linearGradient>
    <linearGradient id="hmFloor" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#1e1748"/><stop offset="1" stop-color="#0a0818"/>
    </linearGradient>
    <linearGradient id="hmCurtain" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#2a0f3e"/><stop offset="0.3" stop-color="#4a1c60"/><stop offset="0.6" stop-color="#2a0f3e"/><stop offset="1" stop-color="#3c1650"/>
    </linearGradient>
    <radialGradient id="hmBack" cx="0.85" cy="0.2" r="1">
      <stop offset="0" stop-color="#0a0820" stop-opacity="0"/><stop offset="0.55" stop-color="#0a0820" stop-opacity="0.35"/><stop offset="1" stop-color="#0a0820" stop-opacity="0.75"/>
    </radialGradient>
    <radialGradient id="hmVig" cx="50%" cy="46%" r="72%">
      <stop offset="0.55" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.65"/>
    </radialGradient>
    <filter id="hmGlowS" x="-80%" y="-80%" width="260%" height="260%"><feGaussianBlur stdDeviation="3"/></filter>
    <filter id="hmGlowL" x="-80%" y="-80%" width="260%" height="260%"><feGaussianBlur stdDeviation="14"/></filter>
    <filter id="hmBlurS" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="6"/></filter>
    <filter id="hmMist" x="-30%" y="-100%" width="160%" height="300%"><feGaussianBlur stdDeviation="14"/></filter>
    <clipPath id="hmClip"><ellipse cx="${mx}" cy="${my}" rx="${mrx}" ry="${mry}"/></clipPath>
  </defs>

  <rect width="720" height="440" fill="url(#hmBg)"/>
  <g opacity="0.8">${paper}</g>
  <!-- wainscot -->
  <rect x="0" y="300" width="720" height="80" fill="#160f36"/>
  <rect x="0" y="300" width="720" height="4" fill="#3a2e78"/>
  ${[0, 1, 2, 3, 4, 5, 6].map((k) => `<rect x="${12 + k * 104}" y="314" width="88" height="56" rx="4" fill="none" stroke="#2a2160" stroke-width="2"/>`).join("")}
  <!-- floor -->
  <rect x="0" y="378" width="720" height="62" fill="url(#hmFloor)"/>
  ${[0, 1, 2, 3, 4, 5, 6, 7, 8].map((k) => `<line x1="${k * 90 - 20}" y1="378" x2="${k * 110 - 140}" y2="440" stroke="#2a2160" stroke-width="2" opacity="0.6"/>`).join("")}

  <!-- curtains at the edges -->
  <path d="M 0 0 L 92 0 Q 70 140 96 260 Q 60 300 74 440 L 0 440 Z" fill="url(#hmCurtain)"/>
  <path d="M 720 0 L 628 0 Q 650 140 624 260 Q 660 300 646 440 L 720 440 Z" fill="url(#hmCurtain)"/>
  <path d="M 0 0 L 720 0 L 720 22 Q 360 52 0 22 Z" fill="#3a1450"/>
  <path d="M 0 22 Q 360 52 720 22" fill="none" stroke="#b88cff" stroke-width="2" opacity="0.35"/>

  <!-- halo behind the mirror -->
  <ellipse cx="${mx}" cy="${my}" rx="280" ry="230" fill="url(#hmHalo)"/>

  <!-- mirror shadow and stand -->
  <ellipse cx="${mx}" cy="388" rx="150" ry="14" fill="#000" opacity="0.55"/>
  <path d="M ${mx - 90} 386 q 10 -40 40 -46 l 8 8 q -24 8 -34 38 Z" fill="url(#hmFrame)"/>
  <path d="M ${mx + 90} 386 q -10 -40 -40 -46 l -8 8 q 24 8 34 38 Z" fill="url(#hmFrame)"/>

  <!-- mirror glass and reflection -->
  <ellipse cx="${mx}" cy="${my}" rx="${mrx}" ry="${mry}" fill="url(#hmGlass)"/>
  <g clip-path="url(#hmClip)">
    <!-- reflected room: far candle glow and wallpaper hint -->
    <circle cx="${mx - 70}" cy="${my + 30}" r="50" fill="#ffb86a" opacity="0.15" filter="url(#hmGlowL)"/>
    <ellipse cx="${mx}" cy="${my + mry - 10}" rx="${mrx}" ry="40" fill="${SP}" opacity="0.35" filter="url(#hmMist)"/>
    ${ghost}
    <!-- glass sheen -->
    <path d="M ${mx - mrx} ${my - 40} L ${mx - 20} ${my - mry} L ${mx + 10} ${my - mry} L ${mx - mrx} ${my + 20} Z" fill="#fff" opacity="0.07"/>
    <path d="M ${mx - mrx} ${my + 50} L ${mx + 40} ${my - mry} L ${mx + 54} ${my - mry} L ${mx - mrx} ${my + 74} Z" fill="#fff" opacity="0.05"/>
  </g>
  <!-- frame -->
  <ellipse cx="${mx}" cy="${my}" rx="${mrx + 6}" ry="${mry + 6}" fill="none" stroke="${SP}" stroke-width="8" opacity="0.55" filter="url(#hmGlowS)"/>
  <ellipse cx="${mx}" cy="${my}" rx="${mrx + 8}" ry="${mry + 8}" fill="none" stroke="url(#hmFrame)" stroke-width="16"/>
  <ellipse cx="${mx}" cy="${my}" rx="${mrx + 8}" ry="${mry + 8}" fill="none" stroke="#1a1130" stroke-width="2" opacity="0.6" stroke-dasharray="3 9"/>
  <ellipse cx="${mx}" cy="${my}" rx="${mrx + 1}" ry="${mry + 1}" fill="none" stroke="#e6d8ff" stroke-width="1.5" opacity="0.7"/>
  ${crest}${sides}${bottom}

  <!-- candles -->
  ${candle(214, 384, 150, { lean: -2 })}
  ${candle(560, 384, 176, { lean: 3, melt: 1.4 })}
  ${candle(604, 386, 110, { lean: 1, melt: 0.7 })}

  ${motes}
  <!-- purple mist rolling across the floor -->
  <g filter="url(#hmMist)">${mist}</g>

  ${critter}
  <ellipse cx="160" cy="420" rx="160" ry="22" fill="${SP}" opacity="0.3" filter="url(#hmMist)"/>
  <ellipse cx="520" cy="414" rx="200" ry="20" fill="${SP}" opacity="0.25" filter="url(#hmMist)"/>

  <rect width="720" height="440" fill="url(#hmVig)"/>
</svg>`;
}

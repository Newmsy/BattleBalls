// Home, Adventure door, Glow Garden: mossy stepping stones wind through a
// night meadow of giant glowing mushrooms and bell flowers to an archway of
// vines, with fireflies everywhere. The first zone, so it's the gentlest.
import { svg, stagePath, hero, guardian, sky, motes, rng, shade, f, W, H } from "./_zone_parts.mjs";

export const size = [720, 440];
export const dir = "game/ui/home_art";

function mushroom(x, y, s, cap, glow) {
  return `<ellipse cx="${x}" cy="${y - s * 1.1}" rx="${s * 1.4}" ry="${s * 0.9}" fill="${glow}" opacity="0.25" filter="url(#bl12)"/>
    <path d="M ${x - s * 0.22} ${y} Q ${x - s * 0.3} ${y - s * 0.6} ${x - s * 0.16} ${y - s * 1.1} L ${x + s * 0.16} ${y - s * 1.1} Q ${x + s * 0.3} ${y - s * 0.6} ${x + s * 0.22} ${y} Z" fill="#e8e0c8" stroke="#3a3248" stroke-width="2"/>
    <path d="M ${x - s} ${y - s * 1.02} Q ${x - s * 0.9} ${y - s * 1.8} ${x} ${y - s * 1.84} Q ${x + s * 0.9} ${y - s * 1.8} ${x + s} ${y - s * 1.02} Q ${x} ${y - s * 1.2} ${x - s} ${y - s * 1.02} Z" fill="${cap}" stroke="${shade(cap, -0.55)}" stroke-width="2.5"/>
    <path d="M ${x - s * 0.7} ${y - s * 1.3} Q ${x - s * 0.4} ${y - s * 1.7} ${x + s * 0.1} ${y - s * 1.72}" fill="none" stroke="#fff" stroke-width="${s * 0.08}" opacity="0.35" stroke-linecap="round"/>
    ${[[-0.45, -1.4, 0.13], [0.2, -1.55, 0.1], [0.55, -1.25, 0.09], [-0.1, -1.25, 0.07]].map(([a, b, r]) => `<circle cx="${f(x + a * s)}" cy="${f(y + b * s)}" r="${f(r * s)}" fill="${glow}"/>`).join("")}`;
}

function bell(x, y, h, col) {
  return `<path d="M ${x} ${y} Q ${x + 6} ${y - h * 0.6} ${x - 4} ${y - h}" fill="none" stroke="#2f6a4a" stroke-width="3"/>
    <path d="M ${x - 4} ${y - h} q -10 4 -10 16 q 10 -4 10 -4 q 0 0 10 4 q 0 -12 -10 -16 Z" fill="${col}" stroke="${shade(col, -0.5)}" stroke-width="1.5"/>
    <circle cx="${x - 4}" cy="${y - h + 14}" r="7" fill="${col}" opacity="0.5" filter="url(#bl4)"/>`;
}

export default function () {
  const R = rng(14);
  const gx = 604, gy = 246;
  // Vine archway with glowing blossoms.
  let blossoms = "";
  for (let k = 0; k < 9; k++) {
    const a = Math.PI + (k / 8) * Math.PI;
    const x = gx + Math.cos(a) * 52, y = gy - 70 + Math.sin(a) * 66;
    const c = ["#ffd36b", "#ff8ad0", "#7dffb0"][k % 3];
    blossoms += `<circle cx="${f(x)}" cy="${f(y)}" r="9" fill="${c}" opacity="0.5" filter="url(#bl4)"/><circle cx="${f(x)}" cy="${f(y)}" r="4.5" fill="${c}"/>`;
  }
  const gate = `
    <ellipse cx="${gx}" cy="${gy - 50}" rx="60" ry="70" fill="#7dffb0" opacity="0.22" filter="url(#bl16)"/>
    <path d="M ${gx - 44} ${gy} L ${gx - 44} ${gy - 70} Q ${gx} ${gy - 128} ${gx + 44} ${gy - 70} L ${gx + 44} ${gy} Z" fill="url(#ggDoor)"/>
    <path d="M ${gx - 52} ${gy + 2} L ${gx - 52} ${gy - 70} Q ${gx} ${gy - 140} ${gx + 52} ${gy - 70} L ${gx + 52} ${gy + 2}" fill="none" stroke="#1e4a34" stroke-width="16" stroke-linecap="round"/>
    <path d="M ${gx - 52} ${gy + 2} L ${gx - 52} ${gy - 70} Q ${gx} ${gy - 140} ${gx + 52} ${gy - 70} L ${gx + 52} ${gy + 2}" fill="none" stroke="#3f8a5a" stroke-width="6" stroke-dasharray="14 10" stroke-linecap="round"/>
    ${[[-58, -40], [56, -96], [-30, -126], [40, -20]].map(([dx, dy], k) => `<path d="M ${gx + dx} ${gy + dy} q ${k % 2 ? 14 : -14} -6 ${k % 2 ? 18 : -18} 6 q ${k % 2 ? -10 : 10} 4 ${k % 2 ? -18 : 18} -6 Z" fill="#5fd068" stroke="#1e4a34" stroke-width="1.5"/>`).join("")}
    ${blossoms}`;
  // Hills and tree silhouettes.
  const trees = [[60, 236, 1.1], [180, 226, 0.8], [700, 232, 1.0]].map(([x, y, s]) =>
    `<path d="M ${x} ${y} L ${x} ${y - 40 * s}" stroke="#16243a" stroke-width="${8 * s}"/><circle cx="${x}" cy="${y - 62 * s}" r="${34 * s}" fill="#16243a"/><circle cx="${x - 20 * s}" cy="${y - 44 * s}" r="${22 * s}" fill="#16243a"/><circle cx="${x + 22 * s}" cy="${y - 46 * s}" r="${24 * s}" fill="#16243a"/>`).join("");
  // Grass tufts in the meadow.
  let grass = "";
  for (let k = 0; k < 70; k++) {
    const x = R() * 740 - 10, y = 252 + R() * 190, h = 6 + R() * 12 * (0.5 + (y - 252) / 190);
    grass += `<path d="M ${f(x)} ${f(y)} q -3 ${f(-h * 0.6)} -6 ${f(-h)} M ${f(x)} ${f(y)} q 1 ${f(-h * 0.7)} 2 ${f(-h * 1.2)} M ${f(x)} ${f(y)} q 4 ${f(-h * 0.5)} 7 ${f(-h * 0.9)}" stroke="${R() < 0.5 ? "#2f6a4a" : "#3a8a5a"}" stroke-width="2" fill="none" stroke-linecap="round"/>`;
  }
  return svg(`
  <defs>
    <linearGradient id="ggSky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0c1030"/><stop offset="0.5" stop-color="#173a5a"/><stop offset="0.6" stop-color="#1f5a5a"/><stop offset="1" stop-color="#1f5a5a"/></linearGradient>
    <linearGradient id="ggGround" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#1f4a3e"/><stop offset="1" stop-color="#0d1f24"/></linearGradient>
    <radialGradient id="ggDoor" cx="0.5" cy="0.65" r="0.65"><stop offset="0" stop-color="#e6fff0"/><stop offset="0.35" stop-color="#7dffb0"/><stop offset="0.85" stop-color="#2a8a6a"/><stop offset="1" stop-color="#14403a"/></radialGradient>
  </defs>
  <rect width="${W}" height="${H}" fill="url(#ggSky)"/>
  ${sky(23, 70, 0, 0, 720, 190)}
  <circle cx="150" cy="96" r="30" fill="#f4f0d8" opacity="0.9"/><circle cx="150" cy="96" r="60" fill="#d8f4e0" opacity="0.15" filter="url(#bl16)"/>
  <path d="M 0 230 Q 120 196 260 214 Q 380 228 470 204 Q 600 178 720 206 L 720 260 L 0 260 Z" fill="#183a44"/>
  ${trees}
  <path d="M 0 250 Q 200 236 380 248 Q 560 258 720 242 L 720 440 L 0 440 Z" fill="url(#ggGround)"/>
  ${grass}
  ${mushroom(420, 250, 34, "#7b77ff", "#b8b4ff")}${mushroom(470, 258, 20, "#ff8ad0", "#ffd0ec")}${mushroom(250, 300, 26, "#3fa9f5", "#bfe8ff")}
  ${bell(520, 262, 46, "#ffd36b")}${bell(536, 258, 34, "#7dffb0")}${bell(330, 270, 40, "#ff8ad0")}
  ${stagePath(gx, gy, { top: "#4a5a5a", hi: "#6a7a70", side: "#13222a", glow: "#7dffb0", halo: "#5cff9a" })}
  ${gate}
  ${guardian(670, 252, "#9aa0b8", "leaf", "#7dffb0", "#1e3a34")}
  ${mushroom(60, 440, 50, "#5a4ab0", "#9a8cff")}
  ${hero("#7dffb0", 170, 398)}
  ${motes(9, 40, 0, 120, 720, 420, ["#d8ff7a", "#7dffb0", "#ffe9a8"])}`);
}

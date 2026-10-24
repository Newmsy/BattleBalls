// Home, Adventure door, Bramble Hollow: root-stones lead through a dusky
// forest hollow, between curling thorn brambles, to a glowing door in the
// trunk of a huge old tree. Moss green and plum.
import { svg, stagePath, hero, guardian, sky, motes, rng, shade, f, W, H } from "./_zone_parts.mjs";

export const size = [720, 440];
export const dir = "game/ui/home_art";

function bramble(x, y, s, flip = 1, col = "#3a2a4a") {
  let thorns = "";
  for (let k = 0; k < 7; k++) {
    const t = k / 7, a = t * Math.PI * 1.6;
    const px = x + flip * Math.cos(a) * (60 - t * 30) * s, py = y - t * 110 * s - Math.sin(a) * 20 * s;
    thorns += `<path d="M ${f(px - 4)} ${f(py)} L ${f(px + flip * 10 * s)} ${f(py - 8 * s)} L ${f(px + 3)} ${f(py + 4)} Z" fill="${shade(col, 0.15)}"/>`;
  }
  return `<path d="M ${x} ${y} C ${x + flip * 70 * s} ${y - 30 * s} ${x + flip * 50 * s} ${y - 100 * s} ${x} ${y - 90 * s} C ${x - flip * 40 * s} ${y - 80 * s} ${x - flip * 20 * s} ${y - 130 * s} ${x + flip * 20 * s} ${y - 130 * s}" fill="none" stroke="${col}" stroke-width="${9 * s}" stroke-linecap="round"/>${thorns}`;
}

export default function () {
  const R = rng(51);
  const gx = 604, gy = 246;
  // Far trunks in the haze.
  let trunks = "";
  for (let k = 0; k < 9; k++) {
    const x = 20 + k * 82 + R() * 30, w = 16 + R() * 18;
    trunks += `<rect x="${f(x)}" y="0" width="${f(w)}" height="260" fill="${k % 2 ? "#2a2348" : "#241e40"}"/>`;
  }
  // The great tree with its door.
  const tree = `<path d="M ${gx - 90} 260 Q ${gx - 70} 160 ${gx - 76} 0 L ${gx + 84} 0 Q ${gx + 74} 160 ${gx + 100} 260 Z" fill="#3a2a30" stroke="#1a1018" stroke-width="3"/>
    ${[-50, -20, 20, 50].map((d) => `<path d="M ${gx + d} 0 Q ${gx + d * 1.1} 120 ${gx + d * 1.2} 250" fill="none" stroke="#2a1c22" stroke-width="3"/>`).join("")}
    <path d="M ${gx - 90} 260 Q ${gx - 130} 250 ${gx - 150} 268 M ${gx + 100} 260 Q ${gx + 140} 248 ${gx + 160} 266" stroke="#3a2a30" stroke-width="14" stroke-linecap="round" fill="none"/>
    <ellipse cx="${gx}" cy="${gy - 50}" rx="48" ry="62" fill="#c8ff7a" opacity="0.3" filter="url(#bl16)"/>
    <path d="M ${gx - 34} ${gy} L ${gx - 34} ${gy - 64} Q ${gx} ${gy - 112} ${gx + 34} ${gy - 64} L ${gx + 34} ${gy} Z" fill="url(#bhDoor)" stroke="#1a1018" stroke-width="4"/>
    ${[0, 1, 2].map((k) => `<circle cx="${gx - 18 + k * 18}" cy="${gy - 70 + (k === 1 ? -10 : 0)}" r="4" fill="#fffbd0"/>`).join("")}
    <path d="M ${gx - 40} ${gy - 120} q 12 -16 24 -4 q -6 10 -24 4 Z M ${gx + 20} ${gy - 140} q 16 -10 24 4 q -12 6 -24 -4 Z" fill="#7fbf4a" stroke="#2a4a1a" stroke-width="1.5"/>`;
  const shrooms = [[452, 262, 12], [470, 266, 8], [700, 270, 10], [250, 300, 10]].map(([x, y, s]) =>
    `<rect x="${x - s * 0.2}" y="${y - s}" width="${s * 0.4}" height="${s}" fill="#e8dcc8"/><path d="M ${x - s} ${y - s} Q ${x} ${y - s * 2} ${x + s} ${y - s} Z" fill="#ff8ad0"/><circle cx="${x}" cy="${y - s * 1.2}" r="${s * 1.4}" fill="#ff8ad0" opacity="0.25" filter="url(#bl6)"/>`).join("");
  let ferns = "";
  for (let k = 0; k < 40; k++) {
    const x = R() * 740 - 10, y = 262 + R() * 180, h = 10 + R() * 18;
    ferns += `<path d="M ${f(x)} ${f(y)} q -8 ${f(-h * 0.6)} -16 ${f(-h)} M ${f(x)} ${f(y)} q 8 ${f(-h * 0.6)} 16 ${f(-h)} M ${f(x)} ${f(y)} l 0 ${f(-h * 1.1)}" stroke="${R() < 0.5 ? "#3a6a3a" : "#4a7a3a"}" stroke-width="2.5" fill="none" stroke-linecap="round"/>`;
  }
  return svg(`
  <defs>
    <linearGradient id="bhBg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#120f2a"/><stop offset="0.6" stop-color="#2a2a4a"/><stop offset="1" stop-color="#3a3a4a"/></linearGradient>
    <linearGradient id="bhGround" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2a3a2a"/><stop offset="1" stop-color="#0f160f"/></linearGradient>
    <radialGradient id="bhDoor" cx="0.5" cy="0.65" r="0.65"><stop offset="0" stop-color="#fffbd0"/><stop offset="0.4" stop-color="#d8ff7a"/><stop offset="0.9" stop-color="#5a8a2a"/><stop offset="1" stop-color="#2a4a1a"/></radialGradient>
  </defs>
  <rect width="${W}" height="${H}" fill="url(#bhBg)"/>
  ${trunks}
  <rect width="${W}" height="260" fill="#9bd84a" opacity="0.05"/>
  ${[0, 1, 2].map((k) => `<path d="M ${150 + k * 120} 0 L ${100 + k * 140} 260 L ${150 + k * 140} 260 L ${180 + k * 120} 0 Z" fill="#e8ffd0" opacity="0.05"/>`).join("")}
  ${tree}
  <path d="M 0 256 Q 200 244 380 254 Q 560 262 720 250 L 720 440 L 0 440 Z" fill="url(#bhGround)"/>
  ${ferns}${shrooms}
  ${bramble(380, 262, 0.9, 1)}${bramble(36, 300, 1.3, 1, "#2e2240")}${bramble(700, 330, 1.1, -1, "#2e2240")}
  ${stagePath(gx, gy, { top: "#5a4a3a", hi: "#7a6a4a", side: "#1a140f", glow: "#d8ff7a", halo: "#9bd84a" })}
  ${guardian(676, 252, "#9bd84a", "leaf", "#d8ff7a", "#2a2018")}
  ${hero("#d8ff7a", 160, 398)}
  ${motes(52, 34, 0, 60, 720, 420, ["#d8ff7a", "#fff2b0", "#ff8ad0"])}`);
}

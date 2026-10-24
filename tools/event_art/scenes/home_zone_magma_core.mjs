// Home, Adventure door, Magma Core: stage stones cross a crusted lava lake to
// an obsidian gate glowing with embers, under a smoking volcano.
import { svg, stagePath, hero, guardian, plates, sky, motes, rng, f, W, H } from "./_zone_parts.mjs";

export const size = [720, 440];
export const dir = "game/ui/home_art";

export default function () {
  const R = rng(5);
  const hz = 244; // lava horizon
  const volcano = `
    <path d="M 300 ${hz + 2} L 452 100 Q 470 88 488 100 L 640 ${hz + 2} Z" fill="#2a1840"/>
    <path d="M 452 100 Q 470 88 488 100 L 520 132 Q 498 126 478 138 Q 462 124 440 132 Z" fill="#40204a"/>
    <path d="M 456 104 Q 470 94 484 104 Q 470 110 456 104 Z" fill="#ffb347"/>
    <ellipse cx="470" cy="102" rx="40" ry="14" fill="#ff7a2a" opacity="0.55" filter="url(#bl12)"/>
    <path d="M 466 108 Q 458 140 470 170 Q 482 200 462 ${hz}" fill="none" stroke="#ff8a3d" stroke-width="4" stroke-linecap="round" opacity="0.9"/>
    <path d="M 466 108 Q 458 140 470 170 Q 482 200 462 ${hz}" fill="none" stroke="#ffd36b" stroke-width="1.5" stroke-linecap="round"/>
    <path d="M 476 110 Q 500 150 494 180 Q 490 210 512 ${hz}" fill="none" stroke="#ff6a3d" stroke-width="3" stroke-linecap="round" opacity="0.75"/>
    <path d="M 440 132 L 300 ${hz} L 380 ${hz} Q 400 190 440 132 Z" fill="#1c1030" opacity="0.7"/>`;
  let smoke = "";
  for (let k = 0; k < 9; k++) {
    const t = k / 8;
    smoke += `<circle cx="${f(470 + t * 150 + R() * 14)}" cy="${f(86 - t * 50 + R() * 10)}" r="${f(16 + t * 26)}" fill="${k < 3 ? "#5a2a48" : "#3a2448"}" opacity="${f(0.75 - t * 0.45)}"/>`;
  }
  const gx = 604, gy = 246;
  const gate = `
    <ellipse cx="${gx}" cy="${gy - 40}" rx="56" ry="66" fill="#ff6a3d" opacity="0.35" filter="url(#bl16)"/>
    <path d="M ${gx - 40} ${gy} L ${gx - 40} ${gy - 70} Q ${gx} ${gy - 120} ${gx + 40} ${gy - 70} L ${gx + 40} ${gy} Z" fill="url(#mcPortal)"/>
    <path d="M ${gx - 28} ${gy - 40} Q ${gx} ${gy - 80} ${gx + 22} ${gy - 46} Q ${gx + 4} ${gy - 66} ${gx - 14} ${gy - 46}" fill="none" stroke="#fff3c4" stroke-width="2.5" opacity="0.8" stroke-linecap="round"/>
    <path d="M ${gx - 30} ${gy - 16} Q ${gx} ${gy - 54} ${gx + 30} ${gy - 20}" fill="none" stroke="#ffd36b" stroke-width="2" opacity="0.7" stroke-linecap="round"/>
    ${[-1, 1].map((d) => `<path d="M ${gx + d * 40} ${gy + 4} L ${gx + d * 40} ${gy - 74} Q ${gx + d * 46} ${gy - 96} ${gx + d * 58} ${gy - 100} L ${gx + d * 60} ${gy + 4} Z" fill="#1c1030" stroke="#0b0614" stroke-width="2.5"/>
      <path d="M ${gx + d * 46} ${gy - 20} l ${d * 6} -14 l ${-d * 3} -10 l ${d * 5} -12" fill="none" stroke="#ff8a3d" stroke-width="2" opacity="0.85"/>`).join("")}
    <path d="M ${gx - 62} ${gy - 100} Q ${gx} ${gy - 140} ${gx + 62} ${gy - 100}" fill="none" stroke="#1c1030" stroke-width="12" stroke-linecap="round"/>
    <path d="M ${gx - 62} ${gy - 100} Q ${gx} ${gy - 140} ${gx + 62} ${gy - 100}" fill="none" stroke="#ff8a3d" stroke-width="1.5" opacity="0.5"/>
    <circle cx="${gx}" cy="${gy - 121}" r="7" fill="#ffd36b"/><circle cx="${gx}" cy="${gy - 121}" r="14" fill="#ffb347" opacity="0.45" filter="url(#bl6)"/>`;
  return svg(`
  <defs>
    <linearGradient id="mcSky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0d0b26"/><stop offset="0.45" stop-color="#2a1448"/><stop offset="0.56" stop-color="#5a1e40"/><stop offset="1" stop-color="#5a1e40"/></linearGradient>
    <linearGradient id="mcLava" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ff8a3d"/><stop offset="0.25" stop-color="#d8442a"/><stop offset="1" stop-color="#4a1028"/></linearGradient>
    <radialGradient id="mcPortal" cx="0.5" cy="0.6" r="0.6"><stop offset="0" stop-color="#fff0b0"/><stop offset="0.35" stop-color="#ffb347"/><stop offset="0.8" stop-color="#ff5a2a"/><stop offset="1" stop-color="#6a1a3a"/></radialGradient>
  </defs>
  <rect width="${W}" height="${H}" fill="url(#mcSky)"/>
  ${sky(11, 60, 0, 0, 720, 190)}
  <path d="M 0 226 Q 80 190 170 208 Q 240 220 300 200 L 340 ${hz} L 0 ${hz} Z" fill="#1e1236"/>
  <path d="M 600 ${hz} Q 650 200 720 210 L 720 ${hz} Z" fill="#1e1236"/>
  ${smoke}${volcano}
  <rect x="0" y="${hz - 2}" width="${W}" height="${H - hz + 2}" fill="url(#mcLava)"/>
  <rect x="0" y="${hz - 4}" width="${W}" height="10" fill="#ffd36b" opacity="0.5" filter="url(#bl4)"/>
  ${plates(7, 90, hz + 12, 440, { fill: "#2a1430", stroke: "#ffb347", so: 0.7, size: 30 })}
  ${motes(3, 34, 0, 150, 720, 420, ["#ffd36b", "#ff8a3d", "#ffb347"])}
  ${stagePath(gx, gy)}${gate}
  ${guardian(668, 252, "#ff6a3d", "flame", "#ffd36b")}
  ${hero("#ffb347")}
  <path d="M 0 390 Q 60 370 110 392 L 124 440 L 0 440 Z" fill="#1c1030"/>`);
}

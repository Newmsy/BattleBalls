// Home, Adventure door, Frostbite Caves: ice floes cross a frozen lake inside
// a crystal cave to a gate of ice, with an aurora showing through the cave
// mouth and icicles hanging from the roof. Pale blue and violet.
import { svg, stagePath, hero, guardian, plates, sky, motes, rng, f, W, H } from "./_zone_parts.mjs";

export const size = [720, 440];
export const dir = "game/ui/home_art";

function crystal(x, y, h, w, col, tilt = 0) {
  return `<g transform="rotate(${tilt} ${x} ${y})">
    <path d="M ${x - w} ${y} L ${x - w * 0.8} ${y - h * 0.8} L ${x} ${y - h} L ${x + w * 0.8} ${y - h * 0.8} L ${x + w} ${y} Z" fill="${col}" stroke="#1a2a5a" stroke-width="2"/>
    <path d="M ${x} ${y - h} L ${x + w * 0.8} ${y - h * 0.8} L ${x + w} ${y} L ${x} ${y} Z" fill="#000" opacity="0.18"/>
    <path d="M ${x - w * 0.5} ${y - h * 0.15} L ${x - w * 0.45} ${y - h * 0.75}" stroke="#fff" stroke-width="2" opacity="0.6"/></g>`;
}

export default function () {
  const R = rng(41);
  const gx = 604, gy = 246;
  // Aurora ribbons in the cave mouth.
  const aurora = [0, 1, 2].map((k) => `<path d="M ${120 + k * 30} ${150 - k * 16} C ${240} ${60 - k * 10} ${380} ${150 - k * 20} ${520} ${70 + k * 8} S ${640} ${110} ${700} ${60 + k * 10}" fill="none" stroke="${["#5cffb8", "#8fe6ff", "#b88cff"][k]}" stroke-width="${18 - k * 4}" opacity="0.35" filter="url(#bl8)"/>`).join("");
  // Icicles along the cave roof.
  let icicles = "";
  for (let x = -10; x < 730; x += 18 + R() * 16) {
    const h = 14 + R() * 46, y = 26 + Math.sin(x * 0.02) * 10;
    icicles += `<path d="M ${f(x - 7)} ${f(y)} L ${f(x)} ${f(y + h)} L ${f(x + 7)} ${f(y)} Z" fill="#a8d8ff" opacity="0.85"/><path d="M ${f(x - 2)} ${f(y)} L ${f(x)} ${f(y + h * 0.7)}" stroke="#fff" stroke-width="1.5" opacity="0.6"/>`;
  }
  const gate = `<ellipse cx="${gx}" cy="${gy - 56}" rx="62" ry="72" fill="#8fe6ff" opacity="0.25" filter="url(#bl16)"/>
    <path d="M ${gx - 42} ${gy} L ${gx - 42} ${gy - 74} Q ${gx} ${gy - 124} ${gx + 42} ${gy - 74} L ${gx + 42} ${gy} Z" fill="url(#fcDoor)"/>
    ${crystal(gx - 50, gy + 4, 120, 16, "#c8ecff", -4)}${crystal(gx + 50, gy + 4, 120, 16, "#c8ecff", 4)}
    ${crystal(gx - 28, gy - 100, 50, 12, "#e6f6ff", -30)}${crystal(gx, gy - 112, 58, 12, "#e6f6ff", 0)}${crystal(gx + 28, gy - 100, 50, 12, "#e6f6ff", 30)}
    <path d="M ${gx - 22} ${gy - 30} l 22 -40 l 22 40" fill="none" stroke="#fff" stroke-width="2" opacity="0.6"/>`;
  return svg(`
  <defs>
    <linearGradient id="fcSky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0a1230"/><stop offset="1" stop-color="#1e3a6a"/></linearGradient>
    <linearGradient id="fcIce" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5a8ac8"/><stop offset="0.3" stop-color="#2a4a8a"/><stop offset="1" stop-color="#121e44"/></linearGradient>
    <radialGradient id="fcDoor" cx="0.5" cy="0.6" r="0.65"><stop offset="0" stop-color="#ffffff"/><stop offset="0.4" stop-color="#bfefff"/><stop offset="0.85" stop-color="#5a9ad8"/><stop offset="1" stop-color="#2a4a8a"/></radialGradient>
    <radialGradient id="fcMouth" cx="0.5" cy="0.6" r="0.6"><stop offset="0" stop-color="#1a3a6a"/><stop offset="1" stop-color="#0a1230"/></radialGradient>
  </defs>
  <rect width="${W}" height="${H}" fill="#0c1430"/>
  <path d="M 40 248 Q 60 60 360 40 Q 660 60 690 248 Z" fill="url(#fcSky)"/>
  ${sky(19, 50, 80, 50, 660, 200)}
  ${aurora}
  <path d="M 120 248 L 200 170 L 250 200 L 320 150 L 380 196 L 440 160 L 520 210 L 580 180 L 640 248 Z" fill="#2a3e78"/>
  <path d="M 0 0 L 720 0 L 720 248 L 690 248 Q 660 60 360 40 Q 60 60 40 248 L 0 248 Z" fill="#162250"/>
  <path d="M 40 248 Q 60 60 360 40 Q 660 60 690 248" fill="none" stroke="#5a7ac8" stroke-width="4" opacity="0.6"/>
  ${icicles}
  ${crystal(70, 250, 90, 22, "#8fc8ff", -8)}${crystal(110, 252, 56, 14, "#b88cff", 6)}${crystal(680, 250, 70, 18, "#8fc8ff", 8)}
  <rect x="0" y="246" width="${W}" height="${H - 246}" fill="url(#fcIce)"/>
  <rect x="0" y="244" width="${W}" height="6" fill="#e6f6ff" opacity="0.5" filter="url(#bl3)"/>
  ${plates(11, 40, 262, 440, { fill: "#3a5a9a", stroke: "#bfe8ff", so: 0.5, size: 34 })}
  ${[0, 1, 2, 3, 4, 5].map((k) => `<path d="M ${80 + k * 110} ${300 + (k % 2) * 60} l 30 8 l 20 -6 l 26 10" fill="none" stroke="#e6f6ff" stroke-width="1.5" opacity="0.4"/>`).join("")}
  ${stagePath(gx, gy, { top: "#bfe0ff", hi: "#e6f6ff", side: "#2a4a8a", glow: "#ffffff", halo: "#8fe6ff" })}
  ${gate}
  ${guardian(670, 252, "#8fe6ff", "crystal", "#ffffff", "#2a4a8a")}
  ${hero("#bfefff", 160, 398)}
  ${motes(41, 46, 0, 60, 720, 420, ["#ffffff", "#e6f6ff", "#bfefff"])}`);
}

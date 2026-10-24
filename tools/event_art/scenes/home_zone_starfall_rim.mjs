// Home, Adventure door, Starfall Rim: stepping rocks float over the starry
// void from a crater's edge to a ring gate of gold light, while shooting stars
// fall past a big ringed planet. Deep blue and gold.
import { svg, stagePath, hero, guardian, sky, motes, rng, shade, f, W, H } from "./_zone_parts.mjs";

export const size = [720, 440];
export const dir = "game/ui/home_art";

export default function () {
  const R = rng(71);
  const GD = "#ffd23d";
  const gx = 604, gy = 246;
  // Ringed planet: the ring's back half goes behind the ball, the front half over it.
  const planet = `<circle cx="300" cy="120" r="90" fill="#9a8cff" opacity="0.15" filter="url(#bl16)"/>
    <g transform="rotate(-12 300 124)"><ellipse cx="300" cy="124" rx="130" ry="24" fill="none" stroke="#c8b070" stroke-width="6" opacity="0.6"/></g>
    <circle cx="300" cy="120" r="70" fill="url(#srPlanet)"/>
    <path d="M 236 110 Q 300 96 366 112" stroke="#4a3a8a" stroke-width="6" fill="none" opacity="0.5"/>
    <path d="M 240 140 Q 300 128 362 142" stroke="#4a3a8a" stroke-width="4" fill="none" opacity="0.4"/>
    <g transform="rotate(-12 300 124)"><path d="M 170 124 A 130 24 0 0 0 430 124" fill="none" stroke="#ffe08a" stroke-width="6" opacity="0.8"/></g>`;
  const shooting = [[140, 40, 60], [520, 30, 80], [620, 120, 50], [420, 180, 40]].map(([x, y, l]) =>
    `<path d="M ${x} ${y} l ${-l} ${l * 0.45}" stroke="url(#srTail)" stroke-width="3" stroke-linecap="round"/><circle cx="${x}" cy="${y}" r="3.5" fill="#fff8d0"/><circle cx="${x}" cy="${y}" r="9" fill="${GD}" opacity="0.4" filter="url(#bl4)"/>`).join("");
  // Floating rocks in the void beyond the rim.
  let rocks = "";
  for (let k = 0; k < 8; k++) {
    const x = R() * 720, y = 200 + R() * 60, s = 6 + R() * 14;
    rocks += `<path d="M ${f(x - s)} ${f(y)} L ${f(x - s * 0.4)} ${f(y - s * 0.7)} L ${f(x + s * 0.6)} ${f(y - s * 0.5)} L ${f(x + s)} ${f(y + s * 0.2)} L ${f(x + s * 0.2)} ${f(y + s * 0.8)} Z" fill="#3a3466" stroke="#120f2a" stroke-width="1.5"/>`;
  }
  // Ground: the crater rim, cratered rock.
  let craters = "";
  for (let k = 0; k < 14; k++) {
    const x = R() * 720, y = 300 + R() * 140, s = 12 + R() * 24 * (0.5 + (y - 300) / 140);
    craters += `<ellipse cx="${f(x)}" cy="${f(y)}" rx="${f(s)}" ry="${f(s * 0.35)}" fill="#1e1a40"/><path d="M ${f(x - s)} ${f(y)} A ${f(s)} ${f(s * 0.35)} 0 0 0 ${f(x + s)} ${f(y)}" fill="none" stroke="#6a62a8" stroke-width="1.5" opacity="0.6"/>`;
  }
  const gate = `<circle cx="${gx}" cy="${gy - 64}" r="80" fill="${GD}" opacity="0.2" filter="url(#bl16)"/>
    <circle cx="${gx}" cy="${gy - 64}" r="52" fill="url(#srDoor)"/>
    <circle cx="${gx}" cy="${gy - 64}" r="58" fill="none" stroke="#5a4a2a" stroke-width="12"/>
    <circle cx="${gx}" cy="${gy - 64}" r="58" fill="none" stroke="${GD}" stroke-width="4"/>
    ${[0, 1, 2, 3, 4, 5, 6, 7].map((k) => { const a = k * Math.PI / 4; return `<circle cx="${f(gx + Math.cos(a) * 58)}" cy="${f(gy - 64 + Math.sin(a) * 58)}" r="5" fill="#fff8d0"/>`; }).join("")}
    <path d="M ${gx - 22} ${gy - 64} a 22 22 0 1 1 22 22" fill="none" stroke="#fff" stroke-width="2.5" opacity="0.6"/>
    <path d="M ${gx - 34} ${gy + 4} L ${gx - 20} ${gy - 14} L ${gx + 20} ${gy - 14} L ${gx + 34} ${gy + 4} Z" fill="#3a3466" stroke="#120f2a" stroke-width="2"/>`;
  return svg(`
  <defs>
    <linearGradient id="srSky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#07071c"/><stop offset="0.6" stop-color="#14123a"/><stop offset="1" stop-color="#1e1a4a"/></linearGradient>
    <radialGradient id="srPlanet" cx="0.35" cy="0.3" r="0.8"><stop offset="0" stop-color="#b8a8ff"/><stop offset="0.5" stop-color="#6a5ac8"/><stop offset="1" stop-color="#2a2268"/></radialGradient>
    <linearGradient id="srTail" x1="1" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff8d0"/><stop offset="1" stop-color="${GD}" stop-opacity="0"/></linearGradient>
    <linearGradient id="srGround" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3a3466"/><stop offset="1" stop-color="#12102a"/></linearGradient>
    <radialGradient id="srDoor" cx="0.5" cy="0.5" r="0.55"><stop offset="0" stop-color="#fffbe0"/><stop offset="0.4" stop-color="${GD}"/><stop offset="0.85" stop-color="#c87a2a"/><stop offset="1" stop-color="#5a3a6a"/></radialGradient>
  </defs>
  <rect width="${W}" height="${H}" fill="url(#srSky)"/>
  ${sky(73, 120, 0, 0, 720, 260)}
  <path d="M 0 200 Q 200 160 420 190 Q 560 210 720 170" fill="none" stroke="#9a8cff" stroke-width="40" opacity="0.06" filter="url(#bl12)"/>
  ${planet}${shooting}${rocks}
  <path d="M 0 262 Q 120 244 250 256 Q 420 270 560 252 Q 650 242 720 250 L 720 440 L 0 440 Z" fill="url(#srGround)"/>
  <path d="M 0 262 Q 120 244 250 256 Q 420 270 560 252 Q 650 242 720 250" fill="none" stroke="#8a80d8" stroke-width="2" opacity="0.6"/>
  ${craters}
  ${[[90, 280, 14, "#ffd23d"], [470, 276, 10, "#9a8cff"], [690, 300, 12, "#ffd23d"]].map(([x, y, s, c]) => `<path d="M ${x - s * 0.5} ${y} L ${x} ${y - s * 2} L ${x + s * 0.5} ${y} Z" fill="${c}" opacity="0.85"/><circle cx="${x}" cy="${y - s}" r="${s * 1.4}" fill="${c}" opacity="0.25" filter="url(#bl6)"/>`).join("")}
  ${stagePath(gx, gy, { top: "#4a4280", hi: "#6a62a8", side: "#120f2a", glow: GD, halo: GD })}
  ${gate}
  ${guardian(676, 252, "#6f6bff", "orbit", GD, "#2a2458")}
  ${hero(GD, 160, 398)}
  ${motes(74, 30, 0, 60, 720, 420, [GD, "#fff8d0", "#9a8cff"])}`);
}

// Home, Adventure door, Circuit Lab: glowing floor pads lead across a
// circuit-board floor to a round blast door, past a crackling tesla coil and
// a wall of monitors. Cyan and steel.
import { svg, stagePath, hero, guardian, sky, motes, rng, shade, f, W, H } from "./_zone_parts.mjs";

export const size = [720, 440];
export const dir = "game/ui/home_art";

export default function () {
  const R = rng(31);
  const CY = "#39d7ff";
  const gx = 604, gy = 246;
  // Back wall panels with monitors.
  let wall = "";
  for (let x = 0; x < 720; x += 90) wall += `<rect x="${x + 2}" y="40" width="86" height="208" fill="#1a2140" stroke="#0c1024" stroke-width="3"/><line x1="${x + 10}" y1="60" x2="${x + 80}" y2="60" stroke="#2a3460" stroke-width="2"/>`;
  const monitors = [[130, 96, 88, 60], [236, 84, 70, 48], [236, 140, 70, 40], [330, 104, 60, 44]].map(([x, y, w, h], k) => `
    <rect x="${x}" y="${y}" width="${w}" height="${h}" rx="6" fill="#0c1428" stroke="#3a4a78" stroke-width="3"/>
    <rect x="${x + 5}" y="${y + 5}" width="${w - 10}" height="${h - 10}" rx="3" fill="${["#0f3a4a", "#1a2a5a", "#3a1a4a", "#0f3a3a"][k]}"/>
    ${k === 0 ? `<path d="M ${x + 10} ${y + 40} l 12 -10 l 10 6 l 14 -18 l 12 10 l 16 -12" fill="none" stroke="${CY}" stroke-width="2.5"/>` : ""}
    ${k === 1 ? `${[0, 1, 2, 3].map((j) => `<rect x="${x + 12 + j * 13}" y="${y + 34 - j * 6}" width="8" height="${6 + j * 6}" fill="#5cff9a"/>`).join("")}` : ""}
    ${k === 2 ? `<circle cx="${x + 35}" cy="${y + 20}" r="10" fill="none" stroke="#ff8ad0" stroke-width="2.5"/><circle cx="${x + 35}" cy="${y + 20}" r="3" fill="#ff8ad0"/>` : ""}
    ${k === 3 ? `${[0, 1, 2].map((j) => `<rect x="${x + 10}" y="${y + 12 + j * 8}" width="${20 + R() * 22}" height="3" fill="${CY}" opacity="0.8"/>`).join("")}` : ""}
    <rect x="${x}" y="${y}" width="${w}" height="${h}" rx="6" fill="${CY}" opacity="0.06"/>`).join("");
  // Circuit traces on the floor.
  let traces = "";
  for (let k = 0; k < 26; k++) {
    const x = R() * 720, y = 262 + R() * 170, l = 30 + R() * 90, d = R() < 0.5 ? 1 : -1;
    traces += `<path d="M ${f(x)} ${f(y)} l ${f(l * 0.6)} 0 l ${f(l * 0.3)} ${f(d * l * 0.12)} l ${f(l * 0.4)} 0" fill="none" stroke="${CY}" stroke-width="2" opacity="${f(0.2 + R() * 0.3)}"/><circle cx="${f(x)}" cy="${f(y)}" r="3" fill="${CY}" opacity="0.6"/>`;
  }
  // Tesla coil with arcs.
  const tx = 470, ty = 250;
  const coil = `<rect x="${tx - 18}" y="${ty - 8}" width="36" height="12" rx="3" fill="#3a4470" stroke="#0c1024" stroke-width="2"/>
    ${[0, 1, 2, 3, 4, 5].map((k) => `<rect x="${tx - 10}" y="${ty - 20 - k * 13}" width="20" height="10" rx="3" fill="${k % 2 ? "#c8783a" : "#e89a4a"}" stroke="#5a2a10" stroke-width="1.5"/>`).join("")}
    <line x1="${tx}" y1="${ty - 96}" x2="${tx}" y2="${ty - 104}" stroke="#8a94b8" stroke-width="4"/>
    <ellipse cx="${tx}" cy="${ty - 112}" rx="24" ry="12" fill="#9aa8c7" stroke="#2a3050" stroke-width="2.5"/>
    <ellipse cx="${tx - 6}" cy="${ty - 116}" rx="10" ry="4" fill="#e8eeff" opacity="0.7"/>
    <circle cx="${tx}" cy="${ty - 112}" r="40" fill="${CY}" opacity="0.25" filter="url(#bl12)"/>
    <path d="M ${tx + 20} ${ty - 118} l 18 -10 l -4 12 l 22 -14 l -8 14 l 18 -6" fill="none" stroke="#dffaff" stroke-width="2.5" stroke-linejoin="round"/>
    <path d="M ${tx - 22} ${ty - 110} l -16 -12 l 2 12 l -20 -8 l 8 12 l -16 2" fill="none" stroke="#dffaff" stroke-width="2" stroke-linejoin="round"/>`;
  // Round blast door.
  const gate = `<circle cx="${gx}" cy="${gy - 64}" r="74" fill="${CY}" opacity="0.18" filter="url(#bl16)"/>
    <rect x="${gx - 70}" y="${gy - 140}" width="140" height="144" rx="10" fill="#222a4a" stroke="#0c1024" stroke-width="3"/>
    <circle cx="${gx}" cy="${gy - 64}" r="56" fill="#2e3a64" stroke="#0c1024" stroke-width="3"/>
    <circle cx="${gx}" cy="${gy - 64}" r="46" fill="url(#clDoor)"/>
    ${[0, 1, 2, 3, 4, 5].map((k) => { const a = k * Math.PI / 3; return `<line x1="${f(gx + Math.cos(a) * 14)}" y1="${f(gy - 64 + Math.sin(a) * 14)}" x2="${f(gx + Math.cos(a) * 44)}" y2="${f(gy - 64 + Math.sin(a) * 44)}" stroke="#0c2a3a" stroke-width="3"/>`; }).join("")}
    <circle cx="${gx}" cy="${gy - 64}" r="14" fill="#e6fbff" stroke="#0c2a3a" stroke-width="3"/>
    <circle cx="${gx}" cy="${gy - 64}" r="56" fill="none" stroke="${CY}" stroke-width="3" stroke-dasharray="10 8" opacity="0.8"/>
    ${[-1, 1].map((d) => `<rect x="${gx + d * 62 - 4}" y="${gy - 132}" width="8" height="128" fill="#ffd36b" opacity="0.85"/>${[0, 1, 2, 3, 4].map((k) => `<path d="M ${gx + d * 62 - 4} ${gy - 124 + k * 26} l 8 -10 l 0 8 l -8 10 Z" fill="#1a1a2a"/>`).join("")}`).join("")}`;
  return svg(`
  <defs>
    <linearGradient id="clBg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0b0f26"/><stop offset="1" stop-color="#16204a"/></linearGradient>
    <linearGradient id="clFloor" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#1a2a50"/><stop offset="1" stop-color="#0a1024"/></linearGradient>
    <radialGradient id="clDoor" cx="0.5" cy="0.45" r="0.6"><stop offset="0" stop-color="#bff8ff"/><stop offset="0.5" stop-color="${CY}"/><stop offset="1" stop-color="#1a5a7a"/></radialGradient>
  </defs>
  <rect width="${W}" height="${H}" fill="url(#clBg)"/>
  ${wall}
  <rect x="0" y="0" width="720" height="40" fill="#0c1024"/>
  ${[90, 270, 450, 630].map((x) => `<rect x="${x - 40}" y="28" width="80" height="8" rx="4" fill="#e6fbff" opacity="0.8"/><path d="M ${x - 40} 36 L ${x - 90} 250 L ${x + 90} 250 L ${x + 40} 36 Z" fill="#bff8ff" opacity="0.04"/>`).join("")}
  ${monitors}
  <path d="M 0 248 L 720 248 L 720 440 L 0 440 Z" fill="url(#clFloor)"/>
  <line x1="0" y1="248" x2="720" y2="248" stroke="${CY}" stroke-width="2" opacity="0.5"/>
  ${traces}
  ${coil}
  ${stagePath(gx, gy, { top: "#2a3a64", hi: "#3a4e80", side: "#0a1024", glow: CY, halo: CY })}
  ${gate}
  ${guardian(674, 254, "#9aa8c7", "antenna", CY, "#1a2440")}
  ${hero(CY, 160, 398)}
  ${motes(4, 22, 0, 100, 720, 420, [CY, "#bff8ff"])}`);
}

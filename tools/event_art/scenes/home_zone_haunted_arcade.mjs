// Home, Adventure door, Haunted Arcade: lit floor tiles lead through a
// foggy, abandoned arcade of flickering cabinets to a giant cabinet whose
// screen is a glowing portal. A ghost drifts by. Violet and pink.
import { svg, stagePath, hero, guardian, sky, motes, rng, shade, f, W, H } from "./_zone_parts.mjs";

export const size = [720, 440];
export const dir = "game/ui/home_art";

function cabinet(x, y, s, body, screen, lit = true) {
  return `<g transform="translate(${x} ${y}) scale(${s})">
    <path d="M -30 0 L -30 -120 L -24 -134 L 24 -134 L 30 -120 L 30 0 Z" fill="${body}" stroke="#0a0618" stroke-width="3"/>
    <rect x="-26" y="-134" width="52" height="16" rx="3" fill="${shade(body, 0.25)}"/>
    <rect x="-22" y="-112" width="44" height="40" rx="4" fill="#0a0618"/>
    <rect x="-19" y="-109" width="38" height="34" rx="3" fill="${screen}" opacity="${lit ? 0.9 : 0.25}"/>
    ${lit ? `<rect x="-19" y="-109" width="38" height="34" rx="3" fill="${screen}" opacity="0.5" filter="url(#bl6)"/>` : ""}
    <path d="M -28 -66 L 28 -66 L 32 -52 L -32 -52 Z" fill="${shade(body, -0.3)}" stroke="#0a0618" stroke-width="2"/>
    <circle cx="-14" cy="-60" r="3.5" fill="#ff4f7a"/><circle cx="0" cy="-60" r="3.5" fill="#ffd36b"/><line x1="14" y1="-58" x2="16" y2="-66" stroke="#0a0618" stroke-width="3"/>
  </g>`;
}

export default function () {
  const R = rng(61);
  const PU = "#c77dff";
  const gx = 604, gy = 246;
  // Neon shapes on the back wall (a star, a heart, a zigzag).
  const neon = [
    `<path d="M 150 70 l 8 18 l 20 2 l -15 13 l 5 20 l -18 -10 l -18 10 l 5 -20 l -15 -13 l 20 -2 Z" fill="none" stroke="#ffd36b" stroke-width="3"/>`,
    `<path d="M 300 80 q -14 -14 -24 0 q -8 14 24 34 q 32 -20 24 -34 q -10 -14 -24 0 Z" fill="none" stroke="#ff4fd8" stroke-width="3"/>`,
    `<path d="M 400 70 l 20 20 l 20 -20 l 20 20 l 20 -20" fill="none" stroke="#39d7ff" stroke-width="3"/>`,
  ].map((p) => `<g opacity="0.95">${p}</g><g filter="url(#bl4)" opacity="0.8">${p}</g>`).join("");
  // Floor: checker tiles in perspective.
  let tiles = "";
  for (let r = 0; r < 8; r++) {
    const y0 = 250 + Math.pow(r / 8, 1.6) * 190, y1 = 250 + Math.pow((r + 1) / 8, 1.6) * 190;
    for (let c = -8; c < 9; c++) {
      if ((r + c) % 2) continue;
      const xa = 360 + c * (40 + r * 14), xb = 360 + (c + 1) * (40 + r * 14), xc = 360 + (c + 1) * (40 + (r + 1) * 14), xd = 360 + c * (40 + (r + 1) * 14);
      tiles += `<path d="M ${f(xa)} ${f(y0)} L ${f(xb)} ${f(y0)} L ${f(xc)} ${f(y1)} L ${f(xd)} ${f(y1)} Z" fill="#2a1a48"/>`;
    }
  }
  // Fog banks.
  let fog = "";
  for (let k = 0; k < 10; k++) fog += `<ellipse cx="${f(R() * 720)}" cy="${f(250 + R() * 40)}" rx="${f(90 + R() * 120)}" ry="${f(14 + R() * 12)}" fill="#b88cff" opacity="0.16"/>`;
  // The big cabinet gate: a portal screen.
  const gate = `<ellipse cx="${gx}" cy="${gy - 70}" rx="70" ry="80" fill="${PU}" opacity="0.3" filter="url(#bl16)"/>
    <path d="M ${gx - 58} ${gy + 4} L ${gx - 58} ${gy - 140} L ${gx - 48} ${gy - 160} L ${gx + 48} ${gy - 160} L ${gx + 58} ${gy - 140} L ${gx + 58} ${gy + 4} Z" fill="#3a1a5a" stroke="#0a0618" stroke-width="3"/>
    <rect x="${gx - 50}" y="${gy - 160}" width="100" height="22" rx="4" fill="#5a2a8a"/>
    ${[0, 1, 2, 3, 4].map((k) => `<circle cx="${gx - 36 + k * 18}" cy="${gy - 149}" r="4" fill="${["#ff4fd8", "#ffd36b", "#39d7ff", "#5cff9a", "#ff4fd8"][k]}"/>`).join("")}
    <path d="M ${gx - 38} ${gy} L ${gx - 38} ${gy - 82} Q ${gx} ${gy - 130} ${gx + 38} ${gy - 82} L ${gx + 38} ${gy} Z" fill="url(#haDoor)" stroke="#0a0618" stroke-width="4"/>
    <path d="M ${gx - 22} ${gy - 30} q 22 -46 44 0 M ${gx - 14} ${gy - 50} q 14 -24 28 0" fill="none" stroke="#fff" stroke-width="2.5" opacity="0.6"/>`;
  const ghost = (x, y, s) => `<g transform="translate(${x} ${y}) scale(${s})" opacity="0.85">
    <ellipse cx="0" cy="6" rx="34" ry="36" fill="#ff9ae6" opacity="0.3" filter="url(#bl12)"/>
    <path d="M -24 30 L -24 0 Q -24 -26 0 -26 Q 24 -26 24 0 L 24 30 Q 16 22 8 30 Q 0 22 -8 30 Q -16 22 -24 30 Z" fill="#f6e8ff" stroke="#8a5ab0" stroke-width="2.5"/>
    <ellipse cx="-8" cy="-2" rx="4" ry="6" fill="#2a1a48"/><ellipse cx="8" cy="-2" rx="4" ry="6" fill="#2a1a48"/><ellipse cx="0" cy="12" rx="4" ry="5" fill="#2a1a48"/></g>`;
  return svg(`
  <defs>
    <linearGradient id="haBg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0d0a24"/><stop offset="1" stop-color="#2a1448"/></linearGradient>
    <linearGradient id="haFloor" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#1e1238"/><stop offset="1" stop-color="#0c0820"/></linearGradient>
    <radialGradient id="haDoor" cx="0.5" cy="0.6" r="0.65"><stop offset="0" stop-color="#fff0ff"/><stop offset="0.35" stop-color="#ff9ae6"/><stop offset="0.8" stop-color="${PU}"/><stop offset="1" stop-color="#3a1a5a"/></radialGradient>
  </defs>
  <rect width="${W}" height="${H}" fill="url(#haBg)"/>
  ${neon}
  ${cabinet(70, 252, 1.0, "#2a1a4a", "#39d7ff")}${cabinet(146, 248, 0.86, "#3a1a3a", "#ff4fd8", false)}${cabinet(230, 246, 0.8, "#1a2a4a", "#5cff9a")}${cabinet(318, 244, 0.72, "#2a1a4a", "#ffd36b", false)}${cabinet(390, 244, 0.7, "#3a1a3a", "#ff4fd8")}
  <path d="M 0 248 L 720 248 L 720 440 L 0 440 Z" fill="url(#haFloor)"/>
  ${tiles}
  ${fog}
  ${gate}
  ${ghost(470, 120, 0.9)}${ghost(70, 110, 0.55)}
  ${stagePath(gx, gy, { top: "#4a2a7a", hi: "#6a3a9a", side: "#0c0820", glow: "#ff9ae6", halo: PU })}
  ${guardian(676, 252, "#c77dff", "horns", "#ff9ae6", "#2a1448")}
  ${hero("#ff9ae6", 160, 398)}
  ${motes(62, 26, 0, 60, 720, 420, ["#ff9ae6", "#c77dff", "#39d7ff"])}`);
}

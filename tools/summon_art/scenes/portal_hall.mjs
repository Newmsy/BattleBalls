// The Summon tab's backdrop: the Portal Hall. The carved stone portal (a gem
// per family) stands on its steps in a moonlit hall, and an egg of every
// family rests in a twig nest in a crescent in front of it. The game crops it
// to the room it has and draws the moving vortex over the portal's opening
// (PORTAL below), so the painting itself stays still.
import { blurs, motes, shade, f } from "./_p.mjs";
import { egg } from "./_eggs.mjs";
import { portal, nest, lantern, hall, vines } from "./_summon_parts.mjs";

export const size = [720, 760];
// Portal centre and opening radius, mirrored by summon_screen.gd _Hall.
export const PORTAL = [360, 300, 170 * 0.74];

export default hero;

function hero() {
  const W = 720, H = 760, floorY = 520;
  const px = 360, py = 300, pr = 170;
  // Nine families in a crescent of nests (back row first so the front overlaps).
  const ring = [
    ["spooky", "uncommon", 92, 520, 92], ["tech", "common", 628, 520, 92],
    ["sea", "rare", 150, 590, 104], ["sweet", "uncommon", 570, 590, 104],
    ["nature", "common", 70, 660, 112], ["toybox", "epic", 650, 660, 112],
    ["cosmic", "legendary", 360, 700, 132], ["frost", "rare", 216, 690, 120], ["fire", "epic", 504, 690, 120],
  ];
  let nests = "";
  ring.forEach(([fam, rar, x, y, w], k) => {
    const [b, fr] = nest(x, y, w, { seed: 20 + k });
    nests += b + egg(x, y - w * 0.3, w * 0.33, { family: fam, rarity: rar, seed: 4 + k, tilt: (k % 2 ? 1 : -1) * (4 + (k % 3) * 3) }) + fr;
  });
  // Floor steps leading up to the plinth.
  const steps = [0, 1, 2].map((k) => {
    const y = py + pr * 1.1 + k * 22, hw = pr * 1.25 + k * 40;
    return `<path d="M ${f(px - hw)} ${f(y)} L ${f(px + hw)} ${f(y)} L ${f(px + hw + 14)} ${f(y + 22)} L ${f(px - hw - 14)} ${f(y + 22)} Z" fill="${shade("#2e2a4e", -k * 0.06)}" stroke="#14112a" stroke-width="3"/>
      <rect x="${f(px - hw)}" y="${f(y)}" width="${f(hw * 2)}" height="3" fill="#6a6290" opacity="0.45"/>`;
  }).join("");
  // Two pillars framing the portal.
  const pillar = (x) => `<rect x="${x - 26}" y="40" width="52" height="${floorY - 40}" fill="#2a2648"/>
    <rect x="${x - 26}" y="40" width="14" height="${floorY - 40}" fill="#36315c"/>
    <rect x="${x - 34}" y="28" width="68" height="20" rx="4" fill="#3a3460"/>
    <rect x="${x - 34}" y="${floorY - 18}" width="68" height="20" rx="4" fill="#3a3460"/>`;
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${blurs()}
  ${hall(W, H, floorY, { windows: [[96, 120], [W - 96, 120]], winW: 84 })}
  <rect width="${W}" height="${H}" fill="#0D0F26" opacity="0.3"/>
  ${pillar(150)}${pillar(570)}
  ${vines(9, W, 22, 120)}
  ${lantern(150, 180, 15, "#ffcf7a", 150)}${lantern(570, 180, 15, "#ffcf7a", 150)}
  ${steps}
  ${portal(px, py, pr)}
  <ellipse cx="${px}" cy="${floorY + 90}" rx="330" ry="90" fill="#8f6bff" opacity="0.12" filter="url(#bl24)"/>
  ${nests}
  ${motes(14, 30, 40, 60, 680, 640, ["#cbb8ff", "#ffe0a6", "#bfe9ff"])}
  <defs><linearGradient id="herofade" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0D0F26" stop-opacity="0.7"/><stop offset="0.14" stop-color="#0D0F26" stop-opacity="0"/><stop offset="0.86" stop-color="#0D0F26" stop-opacity="0"/><stop offset="1" stop-color="#0D0F26" stop-opacity="0.9"/></linearGradient></defs>
  <rect width="${W}" height="${H}" fill="url(#herofade)"/>
</svg>`;
}

// Daily board Quests door (game/ui/screens/week_screen.gd): the fair's quest
// board at sunrise, notes pinned up with ticks, and the rewards waiting on a
// cart beside it (an energy bolt, two eggs, a pile of coins). A wide 720x240
// band shown cover-cropped across the board's bottom card; the left is calm for
// the caption.
import { svg, dawn, critter, shadow, sparkle, stringLights, motes, bottomFade, rng, f, LIGHTS, GOLD, CYAN } from "./_daily_parts.mjs";

export const size = [720, 240];
export const dir = "game/ui/home_art";
const W = 720, H = 240;

// A pinned paper note with a few scribble lines and a tick or a star.
function note(x, y, w, h, rot, mark, R) {
  let lines = "";
  for (let k = 0; k < 3; k++) lines += `<line x1="${f(x + 8)}" y1="${f(y + 14 + k * 10)}" x2="${f(x + w - 10 - R() * 14)}" y2="${f(y + 14 + k * 10)}" stroke="#8a6a4a" stroke-width="2.5" stroke-linecap="round" opacity="0.7"/>`;
  const m = mark === "tick"
    ? `<path d="M ${x + w - 22} ${y + h - 16} l 6 7 l 12 -14" fill="none" stroke="#3aa860" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>`
    : mark === "star" ? `<path d="M ${x + w - 14} ${y + h - 24} l 3.5 7 l 7.5 1 l -5.5 5 l 1.5 7.5 l -7 -3.5 l -7 3.5 l 1.5 -7.5 l -5.5 -5 l 7.5 -1 Z" fill="${GOLD}" stroke="#8a5a1a" stroke-width="1.5"/>` : "";
  return `<g transform="rotate(${rot} ${x + w / 2} ${y + h / 2})">
    <rect x="${x + 3}" y="${y + 4}" width="${w}" height="${h}" rx="3" fill="#000" opacity="0.3"/>
    <rect x="${x}" y="${y}" width="${w}" height="${h}" rx="3" fill="#f4e6c8" stroke="#8a6a4a" stroke-width="1.5"/>
    ${lines}${m}
    <circle cx="${x + w / 2}" cy="${y + 4}" r="4.5" fill="${["#ff6a5a", "#5ce1ff", "#ffd36b"][Math.floor(R() * 3)]}" stroke="#2a1a1a" stroke-width="1.2"/></g>`;
}

// A matte egg with a soft band pattern.
const egg = (x, y, s, col, band) => `${shadow(x, y + s * 0.62, s * 0.55, 0.5)}
  <ellipse cx="${x}" cy="${y}" rx="${s * 0.5}" ry="${s * 0.64}" fill="${col}" stroke="#2a1a30" stroke-width="2.5"/>
  <path d="M ${x - s * 0.48} ${y + 2} Q ${x} ${y + s * 0.16} ${x + s * 0.48} ${y + 2} L ${x + s * 0.44} ${y + s * 0.2} Q ${x} ${y + s * 0.34} ${x - s * 0.44} ${y + s * 0.2} Z" fill="${band}" opacity="0.9"/>
  <ellipse cx="${x - s * 0.18}" cy="${y - s * 0.3}" rx="${s * 0.1}" ry="${s * 0.16}" fill="#fff" opacity="0.35"/>`;

const coin = (x, y, r) => `<ellipse cx="${x}" cy="${y}" rx="${r}" ry="${r * 0.45}" fill="#e0a23e" stroke="#7a4a1a" stroke-width="1.5"/>
  <ellipse cx="${x}" cy="${y - 2}" rx="${r}" ry="${r * 0.45}" fill="${GOLD}" stroke="#7a4a1a" stroke-width="1.5"/>
  <ellipse cx="${x}" cy="${y - 2}" rx="${r * 0.55}" ry="${r * 0.22}" fill="none" stroke="#c88a2e" stroke-width="1.5"/>`;

export default () => {
  const R = rng(61);
  // The board: two posts, a little shingled roof, cork face.
  const bx = 300, by = 70, bw = 220, bh = 120;
  let notes = "";
  [[bx + 14, by + 14, 58, 48, -5, "tick"], [bx + 82, by + 10, 60, 52, 3, "star"], [bx + 152, by + 16, 54, 46, -2, ""],
    [bx + 24, by + 66, 56, 44, 4, ""], [bx + 92, by + 70, 62, 42, -3, "tick"], [bx + 160, by + 66, 50, 44, 6, "tick"]]
    .forEach(([x, y, w, h, rot, m]) => { notes += note(x, y, w, h, rot, m, R); });
  const board = `${shadow(bx + bw / 2, by + bh + 52, 150, 0.55)}
    <rect x="${bx + 14}" y="${by + 20}" width="12" height="${bh + 30}" fill="#6a3e2a" stroke="#2a160e" stroke-width="2"/>
    <rect x="${bx + bw - 26}" y="${by + 20}" width="12" height="${bh + 30}" fill="#6a3e2a" stroke="#2a160e" stroke-width="2"/>
    <rect x="${bx}" y="${by}" width="${bw}" height="${bh}" rx="6" fill="#b07a4a" stroke="#3a2010" stroke-width="4"/>
    <rect x="${bx + 8}" y="${by + 8}" width="${bw - 16}" height="${bh - 16}" rx="3" fill="#c8925a"/>
    ${Array.from({ length: 40 }, () => `<circle cx="${f(bx + 10 + R() * (bw - 20))}" cy="${f(by + 10 + R() * (bh - 20))}" r="1.4" fill="#8a5a2a" opacity="0.6"/>`).join("")}
    <path d="M ${bx - 18} ${by + 2} L ${bx + bw / 2} ${by - 34} L ${bx + bw + 18} ${by + 2} Z" fill="#ff6a5a" stroke="#5a2e2a" stroke-width="3" stroke-linejoin="round"/>
    ${Array.from({ length: 5 }, (_, k) => `<path d="M ${bx - 8 + k * 50} ${by - 4} L ${bx + bw / 2} ${by - 30}" stroke="#f4e6c8" stroke-width="7" opacity="0.8"/>`).join("")}
    <path d="M ${bx - 18} ${by + 2} L ${bx + bw / 2} ${by - 34} L ${bx + bw + 18} ${by + 2}" fill="none" stroke="#5a2e2a" stroke-width="3" stroke-linejoin="round"/>
    <circle cx="${bx + bw / 2}" cy="${by - 34}" r="6" fill="${GOLD}" stroke="#7a4a1a" stroke-width="2"/>
    ${notes}`;
  // Reward cart to the right: wheels, a crate, the rewards on top.
  const cx = 600, cy = 186;
  const cart = `${shadow(cx, cy + 30, 80, 0.55)}
    <rect x="${cx - 70}" y="${cy - 22}" width="140" height="40" rx="5" fill="#8a5a3a" stroke="#2a160e" stroke-width="3"/>
    <rect x="${cx - 70}" y="${cy - 22}" width="140" height="8" fill="#c08a5a"/>
    ${[cx - 44, cx + 44].map((x) => `<circle cx="${x}" cy="${cy + 22}" r="15" fill="#3a2418" stroke="#140a06" stroke-width="3"/><circle cx="${x}" cy="${cy + 22}" r="5" fill="#c08a5a"/>`).join("")}
    ${coin(cx + 40, cy - 22, 15)}${coin(cx + 52, cy - 28, 13)}${coin(cx + 30, cy - 30, 12)}${coin(cx + 44, cy - 36, 12)}
    ${egg(cx - 36, cy - 48, 40, "#c8b4e8", "#8a6ac0")}${egg(cx - 2, cy - 44, 34, "#a8d8a8", "#5a9a6a")}
    <circle cx="${cx + 2}" cy="${cy - 92}" r="30" fill="${CYAN}" opacity="0.28" filter="url(#bl12)"/>
    <path d="M ${cx + 8} ${cy - 122} L ${cx - 12} ${cy - 88} L ${cx + 2} ${cy - 88} L ${cx - 8} ${cy - 60} L ${cx + 18} ${cy - 98} L ${cx + 4} ${cy - 98} L ${cx + 14} ${cy - 122} Z" fill="#fff2a0" stroke="#b07a1a" stroke-width="2.5" stroke-linejoin="round"/>
    ${sparkle(cx + 26, cy - 112, 9, "#fff8dc", 0.95)}${sparkle(cx + 64, cy - 52, 7, "#fff8dc", 0.85)}`;
  // A critter on tiptoe pinning one more note, another reading the board.
  const kids = `${shadow(268, 214, 26, 0.55)}${critter(268, 186, 24, "#ffc93c", { acc: "propeller", mood: "cheer", tilt: 10, look: [0.6, -0.5] })}
    <g transform="rotate(-12 296 150)">${note(286, 132, 34, 30, 0, "", R)}</g>
    ${shadow(470, 222, 22, 0.55)}${critter(470, 198, 20, "#3fa9f5", { acc: "fin", mood: "happy", look: [-0.6, -0.6] })}`;
  return svg(W, H, `${dawn("qd", W, H, 150, { sx: 410, sr: 40 })}
  ${stringLights(-10, 26, 360, 44, 14, 14, LIGHTS, 5)}${stringLights(340, 44, 730, 22, 14, 14, LIGHTS, 5)}
  ${board}${cart}${kids}
  ${motes(67, 14, 0, 40, W, 230, ["#ffe2a0", "#ffd36b"])}
  <defs><linearGradient id="qdL" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#0D0F26" stop-opacity="0.75"/><stop offset="0.34" stop-color="#0D0F26" stop-opacity="0"/></linearGradient></defs>
  <rect width="${W}" height="${H}" fill="url(#qdL)"/>${bottomFade("qdF", W, H, 0.65)}`);
};

// Home screen: painted round tokens for the door actions, in the Bounce Run map-node style
// (shared _map_token frame): Spire, Bosses, Trick Shot, Bounce Run, Quests,
// Ghost Arena, Friends and a lock, plus an empty gold frame that the game
// fills with today's Fight of the Day faces.
import { token, twinkle } from "./_map_token.mjs";
import { critter, sparkle } from "./_banner_parts.mjs";

export const size = [160, 160];
export const transparent = true;
export const dir = "game/ui/home_art";

const GOLD = "#ffd36b", ORANGE = "#ff8a3d", CYAN = "#5ce1ff", PINK = "#ff4fd8", VIOLET = "#9a8cff";

const spire = () => token(GOLD, `
  <path d="M 80 26 L 92 60 L 88 60 L 96 112 L 64 112 L 72 60 L 68 60 Z" fill="#f4e2b0" stroke="#7a4a1a" stroke-width="3" stroke-linejoin="round"/>
  <path d="M 80 26 L 92 60 L 88 60 L 96 112 L 80 112 Z" fill="#c89a4a"/>
  ${[72, 86, 100].map((y) => `<rect x="76" y="${y}" width="8" height="8" rx="2" fill="#ffd36b" stroke="#7a4a1a" stroke-width="1.5"/>`).join("")}
  <path d="M 54 118 Q 80 108 106 118 L 106 124 L 54 124 Z" fill="#5a3a5a"/>
  <circle cx="80" cy="24" r="5" fill="#fff4d0"/><circle cx="80" cy="24" r="12" fill="${GOLD}" opacity="0.5" filter="url(#bl6)"/>
  ${twinkle(112, 42, 7, "#fff8dc", 0.9)}`, { face: "#e0a23e" });

const bosses = () => token(ORANGE, `
  <g transform="rotate(-35 80 84)">
    <rect x="74" y="58" width="12" height="68" rx="4" fill="#8a5a3a" stroke="#3a1a10" stroke-width="3"/>
    <rect x="76" y="62" width="4" height="60" fill="#b8805a"/>
    <rect x="50" y="36" width="60" height="32" rx="6" fill="#9aa0b8" stroke="#2a2440" stroke-width="3"/>
    <rect x="50" y="36" width="60" height="10" rx="5" fill="#d8dcea"/>
    <rect x="66" y="36" width="8" height="32" fill="#6a6e88"/>
  </g>
  ${sparkle(46, 104, 9, "#ffd36b", 0.95)}${sparkle(114, 46, 6, "#fff", 0.8)}`, { face: "#c8502a" });

const trick = () => token(GOLD, `
  ${[44, 34, 24, 14, 6].map((r, k) => `<circle cx="80" cy="84" r="${r}" fill="${["#f4e6c8", "#ff6a5a", "#f4e6c8", "#ff6a5a", GOLD][k]}" stroke="#5a2e2a" stroke-width="${k ? 1.2 : 3}"/>`).join("")}
  <line x1="84" y1="80" x2="124" y2="44" stroke="#3a2a1a" stroke-width="4" stroke-linecap="round"/>
  <path d="M 118 46 l 12 -10 l -2 10 l 10 0 l -12 10 Z" fill="${CYAN}" stroke="#1a4a6a" stroke-width="1.5"/>`, { face: "#d89a3e" });

const bounce = () => token(CYAN, `
  <path d="M 30 112 Q 48 48 72 108 Q 90 64 108 104" fill="none" stroke="#e6fbff" stroke-width="3" stroke-dasharray="2 7" stroke-linecap="round" opacity="0.8"/>
  <path d="M 28 116 L 132 116" stroke="#1a4a6a" stroke-width="4" stroke-linecap="round"/>
  ${critter(112, 78, 20, "#ffc93c", { mood: "cheer", tilt: 12 })}
  ${twinkle(46, 50, 6, "#fff", 0.9)}`, { face: "#2a8ab0" });

const lock = () => token("#8a86b0", `
  <rect x="56" y="76" width="48" height="40" rx="8" fill="#b8b4d8" stroke="#2a2648" stroke-width="3"/>
  <path d="M 64 76 L 64 64 Q 64 46 80 46 Q 96 46 96 64 L 96 76" fill="none" stroke="#b8b4d8" stroke-width="8"/>
  <path d="M 64 76 L 64 64 Q 64 46 80 46 Q 96 46 96 64 L 96 76" fill="none" stroke="#2a2648" stroke-width="2" opacity="0.5"/>
  <circle cx="80" cy="92" r="6" fill="#2a2648"/><rect x="77" y="94" width="6" height="12" rx="2" fill="#2a2648"/>`, { face: "#4a4670" });

// Quests: a pinned note with a tick and a star sticker.
const quests = () => token(GOLD, `
  <g transform="rotate(-6 80 84)">
    <rect x="50" y="44" width="62" height="78" rx="5" fill="#f4e6c8" stroke="#8a6a4a" stroke-width="3"/>
    ${[62, 76, 90].map((y, k) => `<line x1="60" y1="${y}" x2="${100 - k * 8}" y2="${y}" stroke="#8a6a4a" stroke-width="4" stroke-linecap="round" opacity="0.7"/>`).join("")}
    <path d="M 62 104 l 8 9 l 16 -18" fill="none" stroke="#3aa860" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/>
    <circle cx="81" cy="46" r="6" fill="#ff6a5a" stroke="#2a1a1a" stroke-width="1.5"/>
  </g>
  ${sparkle(112, 106, 10, GOLD, 0.95)}${twinkle(48, 40, 6, "#fff", 0.9)}`, { face: "#d89a3e" });

const ghost = () => token(PINK, `
  <path d="M 52 120 L 52 76 Q 52 40 80 40 Q 108 40 108 76 L 108 120 Q 100 110 94 120 Q 87 110 80 120 Q 73 110 66 120 Q 59 110 52 120 Z" fill="#f6e8ff" stroke="#8a5ab0" stroke-width="3"/>
  <ellipse cx="70" cy="74" rx="6" ry="9" fill="#2a1a48"/><ellipse cx="90" cy="74" rx="6" ry="9" fill="#2a1a48"/>
  <circle cx="68" cy="71" r="2" fill="#fff"/><circle cx="88" cy="71" r="2" fill="#fff"/>
  <ellipse cx="80" cy="94" rx="6" ry="5" fill="#2a1a48"/>
  <ellipse cx="62" cy="86" rx="5" ry="3" fill="#ff9ae6" opacity="0.6"/><ellipse cx="98" cy="86" rx="5" ry="3" fill="#ff9ae6" opacity="0.6"/>`, { face: "#8a2a90" });

const friends = () => token(VIOLET, `
  ${critter(62, 92, 22, "#3fa9f5", { acc: "fin", mood: "cheer" })}
  ${critter(100, 92, 22, "#ff7ac8", { acc: "ears", mood: "cheer" })}
  <path d="M 80 56 q -8 -10 -14 -2 q -4 8 14 18 q 18 -10 14 -18 q -6 -8 -14 2 Z" fill="#ff6a8a" stroke="#7a1a3a" stroke-width="2"/>`, { face: "#5a4ac0" });

export const many = {
  tok_spire: spire, tok_bosses: bosses, tok_trick: trick, tok_bounce: bounce, tok_quests: quests,
  tok_ghost: ghost, tok_friends: friends, tok_lock: lock,
  tok_frame_gold: () => token(GOLD, "", { face: "#c88a3e" }),
};
export default spire;

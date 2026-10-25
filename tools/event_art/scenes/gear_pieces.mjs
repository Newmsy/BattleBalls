// Gear pieces: one family of objects, one per gear type, shown wherever a
// piece of gear is (Bag rows, gear sheet, merge popup, critter page). The slot
// sets the shape (Shells = a heater shield, Cores = an orb in a four-prong
// setting, Charms = a pendant on a ring), all in the same forged metal, lit
// from the top left with the same outline; the type is the emblem inlaid on
// it, and the enamel behind the emblem is the piece's rarity colour (1 star
// grey ... 5 stars gold). No tile: the game draws the tile and tier rim.
// 12 types x 5 tiers -> game/ui/gear_art/gear_<type>_<tier>.png.
import { f } from "./_map_token.mjs";

export const size = [192, 192];
export const transparent = true;
export const dir = "game/ui/gear_art";


const INK = "#1a1430";
const TIER = ["#c9d3e0", "#4cd98a", "#3d9bff", "#b366ff", "#ffc23d"];
const METAL = ["#f3e6c8", "#c9b48a", "#7d6a52"]; // light, mid, dark brass-steel

const defs = (enamel) => `<defs>
  <linearGradient id="mt" x1="0.15" y1="0" x2="0.85" y2="1"><stop offset="0" stop-color="${METAL[0]}"/><stop offset="0.5" stop-color="${METAL[1]}"/><stop offset="1" stop-color="${METAL[2]}"/></linearGradient>
  <radialGradient id="en" cx="0.36" cy="0.3" r="0.85"><stop offset="0" stop-color="${mix(enamel, "#ffffff", 0.12)}"/><stop offset="0.5" stop-color="${mix(enamel, "#0d0f26", 0.12)}"/><stop offset="1" stop-color="${mix(enamel, "#0d0f26", 0.55)}"/></radialGradient>
</defs>`;

const rgb = (h) => [0, 2, 4].map((i) => parseInt(h.slice(1 + i, 3 + i), 16));
function mix(a, b, t) { return "#" + rgb(a).map((v, i) => Math.round(v + (rgb(b)[i] - v) * t).toString(16).padStart(2, "0")).join(""); }

const ground = `<ellipse cx="80" cy="134" rx="40" ry="6" fill="#000" opacity="0.35"/>`;
const hi = (d) => `<path d="${d}" stroke="#fff" stroke-width="4" fill="none" stroke-linecap="round" opacity="0.55"/>`;

// --- Slot bodies: metal frame + enamel field; `em` is drawn on the field. ---
function shield(em, id) {
  const out = "M 80 26 Q 104 34 124 32 Q 128 92 80 132 Q 32 92 36 32 Q 56 34 80 26 Z";
  const inn = "M 80 38 Q 99 44 113 43 Q 114 88 80 118 Q 46 88 47 43 Q 61 44 80 38 Z";
  const spikes = id !== "thorn_shell" ? "" : [[30, 50, -1, 0.2], [28, 74, -1, 0.1], [40, 98, -1, -0.3], [130, 50, 1, 0.2], [132, 74, 1, 0.1], [120, 98, 1, -0.3], [80, 18, 0, -1]].map(([x, y, d, t]) => d ? `<path d="M ${x + d * 10} ${y - 8} L ${x - d * 8} ${y + t * 14} L ${x + d * 10} ${y + 8} Z" fill="${METAL[0]}" stroke="${INK}" stroke-width="3" stroke-linejoin="round"/>` : `<path d="M 70 30 L 80 ${y} L 90 30 Z" fill="${METAL[0]}" stroke="${INK}" stroke-width="3" stroke-linejoin="round"/>`).join("");
  return `${ground}${spikes}<path d="${out}" fill="url(#mt)" stroke="${INK}" stroke-width="4" stroke-linejoin="round"/>
    <path d="${inn}" fill="url(#en)" stroke="${INK}" stroke-width="2.5" stroke-linejoin="round"/>
    ${[[42, 38], [118, 38], [80, 126]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="3" fill="${METAL[0]}" stroke="${INK}" stroke-width="1.5"/>`).join("")}
    <g>${em}</g>${hi("M 44 40 Q 60 36 76 32")}`;
}
function orb(em) {
  const prong = (a) => { const c = Math.cos(a), s = Math.sin(a); return `<path d="M ${f(80 + c * 30)} ${f(80 + s * 30)} Q ${f(80 + c * 48)} ${f(80 + s * 48)} ${f(80 + c * 40 - s * 8)} ${f(80 + s * 40 + c * 8)} L ${f(80 + c * 40 + s * 8)} ${f(80 + s * 40 - c * 8)} Z" fill="url(#mt)" stroke="${INK}" stroke-width="3" stroke-linejoin="round"/>`; };
  return `${ground}
    <path d="M 56 118 L 104 118 L 112 132 L 48 132 Z" fill="url(#mt)" stroke="${INK}" stroke-width="3.5" stroke-linejoin="round"/>
    <circle cx="80" cy="78" r="44" fill="url(#mt)" stroke="${INK}" stroke-width="4"/>
    <circle cx="80" cy="78" r="34" fill="url(#en)" stroke="${INK}" stroke-width="2.5"/>
    ${[-0.785, 0.785, 2.356, 3.927].map((a) => `<circle cx="${f(80 + Math.cos(a) * 39)}" cy="${f(78 + Math.sin(a) * 39)}" r="3" fill="${METAL[0]}" stroke="${INK}" stroke-width="1.5"/>`).join("")}
    <g>${em}</g>${hi("M 52 62 Q 58 46 74 40")}`;
}
function pendant(em) {
  return `${ground}
    <circle cx="80" cy="26" r="9" fill="none" stroke="${INK}" stroke-width="7"/><circle cx="80" cy="26" r="9" fill="none" stroke="${METAL[1]}" stroke-width="3.5"/>
    <path d="M 80 34 Q 120 44 118 82 Q 116 116 80 132 Q 44 116 42 82 Q 40 44 80 34 Z" fill="url(#mt)" stroke="${INK}" stroke-width="4" stroke-linejoin="round"/>
    <path d="M 80 46 Q 108 54 107 83 Q 105 110 80 121 Q 55 110 53 83 Q 52 54 80 46 Z" fill="url(#en)" stroke="${INK}" stroke-width="2.5"/>
    <g>${em}</g>${hi("M 50 66 Q 56 50 72 42")}`;
}

// --- Emblems (centre ~80,82; cream inlay with one type colour) ---
const CREAM = "#fff6e0";
const E = {
  iron_shell: `<path d="M 74 52 h 12 v 20 h 18 v 12 h -18 v 24 h -12 v -24 h -18 v -12 h 18 Z" fill="${CREAM}" stroke="${INK}" stroke-width="2.5" stroke-linejoin="round"/>`,
  bubble_shell: `<circle cx="80" cy="80" r="22" fill="#d6f6ff" fill-opacity="0.35" stroke="${CREAM}" stroke-width="3"/>
    <path d="M 80 94 Q 64 83 66 73 Q 68 66 74 67 Q 78 68 80 73 Q 82 68 86 67 Q 92 66 94 73 Q 96 83 80 94 Z" fill="#ff6a86" stroke="${INK}" stroke-width="2.5" stroke-linejoin="round"/>
    <circle cx="70" cy="68" r="3" fill="#fff" opacity="0.9"/>`,
  thorn_shell: `${[-38, 38].map((r) => `<g transform="rotate(${r} 80 82)"><path d="M 80 54 L 80 110" stroke="${INK}" stroke-width="9" stroke-linecap="round"/><path d="M 80 54 L 80 110" stroke="#8a5a3a" stroke-width="5" stroke-linecap="round"/>
    ${[62, 76, 90, 102].map((y, k) => { const d = k % 2 ? 1 : -1; return `<path d="M 80 ${y - 4} L ${80 + d * 13} ${y - 8} L 80 ${y + 3} Z" fill="${CREAM}" stroke="${INK}" stroke-width="1.8" stroke-linejoin="round"/>`; }).join("")}</g>`).join("")}`,
  spring_shell: `${[0, 1, 2, 3, 4].map((k) => `<path d="M 60 ${106 - k * 11} Q 80 ${96 - k * 11} 100 ${106 - k * 11}" fill="none" stroke="${INK}" stroke-width="8" stroke-linecap="round"/><path d="M 60 ${106 - k * 11} Q 80 ${96 - k * 11} 100 ${106 - k * 11}" fill="none" stroke="#ffb35a" stroke-width="4" stroke-linecap="round"/>`).join("")}
    <circle cx="80" cy="50" r="7" fill="${CREAM}" stroke="${INK}" stroke-width="2.5"/>`,
  spike_core: `<path d="${Array.from({ length: 16 }, (_, k) => { const a = (k / 16) * Math.PI * 2 - 1.57, r = k % 2 ? 11 : 26; return `${k ? "L" : "M"} ${f(80 + Math.cos(a) * r)} ${f(78 + Math.sin(a) * r)}`; }).join(" ")} Z" fill="${CREAM}" stroke="${INK}" stroke-width="2.5" stroke-linejoin="round"/>
    <circle cx="80" cy="78" r="6" fill="#ff8a3d" stroke="${INK}" stroke-width="2"/>`,
  echo_core: `<circle cx="80" cy="78" r="7" fill="#c9a2ff" stroke="${INK}" stroke-width="2.5"/>
    ${[14, 21, 28].map((r, k) => `<path d="M ${f(80 - r * 0.7)} ${f(78 - r * 0.7)} A ${r} ${r} 0 0 0 ${f(80 - r * 0.7)} ${f(78 + r * 0.7)} M ${f(80 + r * 0.7)} ${f(78 - r * 0.7)} A ${r} ${r} 0 0 1 ${f(80 + r * 0.7)} ${f(78 + r * 0.7)}" fill="none" stroke="${CREAM}" stroke-width="${4 - k * 0.6}" stroke-linecap="round" opacity="${1 - k * 0.2}"/>`).join("")}`,
  leech_core: `<path d="M 80 52 Q 98 74 96 86 Q 94 100 80 100 Q 66 100 64 86 Q 62 74 80 52 Z" fill="#e8405a" stroke="${INK}" stroke-width="2.5" stroke-linejoin="round"/>
    <path d="M 73 84 l 3 8 l 3 -8 M 81 84 l 3 8 l 3 -8" fill="${CREAM}" stroke="${CREAM}" stroke-width="1.5" stroke-linejoin="round"/>
    <ellipse cx="74" cy="74" rx="3" ry="5" fill="#fff" opacity="0.7" transform="rotate(25 74 74)"/>`,
  ricochet_core: `<path d="M 58 60 L 74 92 L 88 64 L 102 92" fill="none" stroke="${INK}" stroke-width="8" stroke-linecap="round" stroke-linejoin="round"/>
    <path d="M 58 60 L 74 92 L 88 64 L 102 92" fill="none" stroke="${CREAM}" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
    <circle cx="102" cy="92" r="6" fill="#ffd36b" stroke="${INK}" stroke-width="2"/>`,
  overclock_charm: `<circle cx="80" cy="84" r="20" fill="${CREAM}" stroke="${INK}" stroke-width="2.5"/>
    ${[0, 1, 2, 3].map((k) => { const a = k * 1.5708; return `<line x1="${f(80 + Math.cos(a) * 15)}" y1="${f(84 + Math.sin(a) * 15)}" x2="${f(80 + Math.cos(a) * 18)}" y2="${f(84 + Math.sin(a) * 18)}" stroke="${INK}" stroke-width="2.5"/>`; }).join("")}
    <path d="M 80 84 L 80 66 A 18 18 0 0 1 96 76 Z" fill="#ff8a3d" opacity="0.55"/>
    <line x1="80" y1="84" x2="93" y2="76" stroke="#d8402a" stroke-width="3.5" stroke-linecap="round"/><circle cx="80" cy="84" r="2.5" fill="${INK}"/>`,
  jet_charm: `<g transform="rotate(35 80 84)"><path d="M 80 58 Q 92 70 90 100 L 70 100 Q 68 70 80 58 Z" fill="${CREAM}" stroke="${INK}" stroke-width="2.5" stroke-linejoin="round"/>
    <path d="M 70 90 L 62 102 L 70 100 Z M 90 90 L 98 102 L 90 100 Z" fill="#5fd068" stroke="${INK}" stroke-width="2" stroke-linejoin="round"/>
    <circle cx="80" cy="76" r="5" fill="#5ce1ff" stroke="${INK}" stroke-width="2"/>
    <path d="M 74 102 Q 80 116 86 102 Z" fill="#ff8a3d" stroke="${INK}" stroke-width="2" stroke-linejoin="round"/></g>`,
  ward_charm: `<path d="M 80 60 L 98 70 L 98 92 L 80 104 L 62 92 L 62 70 Z" fill="none" stroke="${CREAM}" stroke-width="4" stroke-linejoin="round"/>
    <path d="M 80 68 L 80 96 M 70 76 L 80 84 L 90 76" stroke="#5ce1ff" stroke-width="4.5" fill="none" stroke-linecap="round" stroke-linejoin="round"/>`,
  phoenix_charm: `<g transform="rotate(14 80 84)"><path d="M 80 56 Q 98 70 94 90 Q 90 104 80 110 Q 70 104 66 90 Q 62 70 80 56 Z" fill="#ff8a3d" stroke="${INK}" stroke-width="2.5" stroke-linejoin="round"/>
    <path d="M 80 66 Q 88 76 86 90 Q 84 100 80 104 Q 76 100 74 90 Q 72 76 80 66 Z" fill="#ffd36b"/>
    <path d="M 80 60 L 80 112" stroke="${INK}" stroke-width="2.5" stroke-linecap="round"/></g>`,
};

const SLOT_OF = (id) => id.endsWith("shell") ? "Shell" : id.endsWith("core") ? "Core" : "Charm";
const BODY = { Shell: shield, Core: orb, Charm: pendant };

export function piece(id, tier) {
  const slot = SLOT_OF(id);
  return `<svg xmlns="http://www.w3.org/2000/svg" width="192" height="192" viewBox="0 0 160 160">${defs(TIER[tier - 1])}<g transform="translate(80 80) scale(1.08) translate(-80 -79)">${BODY[slot](E[id], id)}</g></svg>`;
}

export const many = {};
for (const id of Object.keys(E)) for (let t = 1; t <= 5; t++) many[`gear_${id}_${t}`] = () => piece(id, t);
export default many.gear_iron_shell_1;

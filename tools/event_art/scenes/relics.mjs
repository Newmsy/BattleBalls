// Bounce Run relics: one keepsake per relic, each a thing taken from the
// critter whose ability the relic tames (Fin's tooth, Clockwork's wind-up
// key, Old Oak's acorn). Same painted look as the gear pieces: ink outline,
// lit from the top left, a soft ground shadow, no tile (the game draws the
// tile, family rim and the critter's face badge). 30 relics ->
// game/bounce_run/art/relics/relic_<critter>.png.
import { f } from "./_map_token.mjs";

export const size = [192, 192];
export const transparent = true;
export const dir = "game/bounce_run/art/relics";

const INK = "#1a1430";
const CREAM = "#fff6e0";
const rgb = (h) => [0, 2, 4].map((i) => parseInt(h.slice(1 + i, 3 + i), 16));
const mix = (a, b, t) => "#" + rgb(a).map((v, i) => Math.round(v + (rgb(b)[i] - v) * t).toString(16).padStart(2, "0")).join("");
const lite = (c, t = 0.45) => mix(c, "#ffffff", t);
const dark = (c, t = 0.45) => mix(c, "#0d0f26", t);

// Gradient defs. Ids carry the relic's name so many icons can share one page.
let P = "";
const lg = (id, c, x1 = 0.15, y1 = 0, x2 = 0.85, y2 = 1) => `<linearGradient id="${P}${id}" x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}"><stop offset="0" stop-color="${lite(c)}"/><stop offset="0.5" stop-color="${c}"/><stop offset="1" stop-color="${dark(c)}"/></linearGradient>`;
const rg = (id, c, cx = 0.36, cy = 0.3) => `<radialGradient id="${P}${id}" cx="${cx}" cy="${cy}" r="0.85"><stop offset="0" stop-color="${lite(c, 0.5)}"/><stop offset="0.5" stop-color="${c}"/><stop offset="1" stop-color="${dark(c, 0.55)}"/></radialGradient>`;
const u = (id) => `url(#${P}${id})`;
const O = (w = 4) => `stroke="${INK}" stroke-width="${w}" stroke-linejoin="round" stroke-linecap="round"`;
const hi = (d, w = 4, o = 0.55) => `<path d="${d}" stroke="#fff" stroke-width="${w}" fill="none" stroke-linecap="round" opacity="${o}"/>`;
const ground = (rx = 40, y = 136) => `<ellipse cx="80" cy="${y}" rx="${rx}" ry="6" fill="#000" opacity="0.35"/>`;
const spark = (x, y, s, c = "#fff", o = 1) => `<path d="M ${f(x)} ${f(y - s)} Q ${f(x + s * 0.18)} ${f(y - s * 0.18)} ${f(x + s)} ${f(y)} Q ${f(x + s * 0.18)} ${f(y + s * 0.18)} ${f(x)} ${f(y + s)} Q ${f(x - s * 0.18)} ${f(y + s * 0.18)} ${f(x - s)} ${f(y)} Q ${f(x - s * 0.18)} ${f(y - s * 0.18)} ${f(x)} ${f(y - s)} Z" fill="${c}" opacity="${o}"/>`;
const cord = (x1, y1, x2, y2, c = "#8a5a3a") => `<path d="M ${x1} ${y1} Q ${(x1 + x2) / 2} ${Math.min(y1, y2) - 18} ${x2} ${y2}" fill="none" stroke="${INK}" stroke-width="6" stroke-linecap="round"/><path d="M ${x1} ${y1} Q ${(x1 + x2) / 2} ${Math.min(y1, y2) - 18} ${x2} ${y2}" fill="none" stroke="${c}" stroke-width="2.6" stroke-linecap="round"/>`;
const star = (cx, cy, r1, r2, n = 5, rot = -Math.PI / 2) => Array.from({ length: n * 2 }, (_, k) => { const a = rot + (k * Math.PI) / n, r = k % 2 ? r2 : r1; return `${k ? "L" : "M"} ${f(cx + Math.cos(a) * r)} ${f(cy + Math.sin(a) * r)}`; }).join(" ") + " Z";
const ring = (cx, cy, r, k) => Array.from({ length: k }, (_, i) => [cx + Math.cos((i / k) * 6.283 - 1.57) * r, cy + Math.sin((i / k) * 6.283 - 1.57) * r]);

// --- The keepsakes (viewBox 0 0 160 160, object centred ~(80, 78)) ---------
const R = {
  // NATURE
  spiker: () => `<defs>${lg("a", "#5cc95a")}</defs>${ground(30)}${cord(52, 46, 108, 46)}
    <path d="M 80 132 Q 60 98 64 60 Q 70 40 80 22 Q 90 40 96 60 Q 100 98 80 132 Z" fill="${u("a")}" ${O()}/>
    <path d="M 80 34 Q 76 70 80 120" stroke="${dark("#5cc95a", 0.3)}" stroke-width="2.5" fill="none" stroke-linecap="round"/>
    <rect x="66" y="56" width="28" height="9" rx="4" fill="#8a5a3a" ${O(3)}/>${hi("M 72 92 Q 68 72 74 50")}`,
  swarm: () => `<defs>${lg("a", "#f4b400")}${lg("w", "#e8f4ff")}</defs>${ground(44)}
    ${[[56, 92], [80, 80], [104, 92], [68, 112], [92, 112], [56, 70], [104, 70]].map(([x, y], i) => `<path d="M ${x} ${y - 13} L ${x + 12} ${y - 6} L ${x + 12} ${y + 7} L ${x} ${y + 14} L ${x - 12} ${y + 7} L ${x - 12} ${y - 6} Z" fill="${i % 3 ? u("a") : "#ffd36b"}" ${O(3.5)}/><path d="M ${x - 6} ${y - 2} L ${x + 6} ${y - 2} L ${x + 4} ${y + 6} L ${x - 4} ${y + 6} Z" fill="${dark("#f4b400", 0.35)}" opacity="0.6"/>`).join("")}
    <path d="M 72 124 Q 74 136 78 128 Q 80 138 84 126" fill="#ffd36b" ${O(2.5)}/>
    <g transform="translate(108 42) rotate(-18)"><ellipse cx="-6" cy="-10" rx="9" ry="6" fill="${u("w")}" ${O(2.5)} opacity="0.95"/><ellipse cx="6" cy="-10" rx="9" ry="6" fill="${u("w")}" ${O(2.5)} opacity="0.95"/>
      <ellipse cx="0" cy="0" rx="14" ry="10" fill="#ffd36b" ${O(3)}/><path d="M -4 -9 v 18 M 4 -9 v 18" stroke="${INK}" stroke-width="3.5"/><circle cx="10" cy="-2" r="2" fill="${INK}"/></g>`,
  mossy: () => `<defs>${rg("s", "#8d99ae")}${lg("m", "#40916c")}</defs>${ground(44)}
    <path d="M 40 112 Q 34 76 62 62 Q 90 52 112 68 Q 130 84 120 114 Q 102 132 74 130 Q 46 128 40 112 Z" fill="${u("s")}" ${O()}/>
    <path d="M 44 92 Q 46 66 72 60 Q 98 54 116 74 Q 110 70 100 74 Q 92 66 82 72 Q 70 64 62 74 Q 50 74 44 92 Z" fill="${u("m")}" ${O(3)}/>
    ${[[56, 72], [74, 64], [94, 64], [108, 72]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="5" fill="${lite("#40916c", 0.3)}" ${O(2)}/>`).join("")}
    <path d="M 84 62 Q 84 44 80 36" stroke="${INK}" stroke-width="5" fill="none" stroke-linecap="round"/><path d="M 84 62 Q 84 44 80 36" stroke="#74c69d" stroke-width="2.5" fill="none" stroke-linecap="round"/>
    <path d="M 80 40 Q 66 30 60 40 Q 70 48 80 40 Z M 81 40 Q 92 26 102 34 Q 94 46 81 40 Z" fill="#74c69d" ${O(2.5)}/>
    ${hi("M 52 102 Q 54 116 66 122", 3.5, 0.4)}`,
  old_oak: () => `<defs>${rg("n", "#a0682f")}${lg("c", "#6f4518")}${lg("l", "#5fa84a")}</defs>${ground(36)}
    <path d="M 46 70 Q 46 116 80 134 Q 114 116 114 70 Z" fill="${u("n")}" ${O()}/>
    <path d="M 38 72 Q 36 48 80 44 Q 124 48 122 72 Q 80 82 38 72 Z" fill="${u("c")}" ${O()}/>
    ${[[52, 60], [66, 56], [80, 54], [94, 56], [108, 60], [60, 68], [80, 66], [100, 68]].map(([x, y]) => `<path d="M ${x - 5} ${y} L ${x} ${y - 4} L ${x + 5} ${y}" stroke="${dark("#6f4518", 0.4)}" stroke-width="2" fill="none"/>`).join("")}
    <path d="M 80 44 Q 78 32 84 24" stroke="${INK}" stroke-width="7" fill="none" stroke-linecap="round"/><path d="M 80 44 Q 78 32 84 24" stroke="#6f4518" stroke-width="3.5" fill="none" stroke-linecap="round"/>
    <path d="M 84 30 Q 104 12 124 22 Q 120 40 98 40 Q 90 38 84 30 Z" fill="${u("l")}" ${O(3)}/><path d="M 88 32 Q 104 26 118 24" stroke="${dark("#5fa84a", 0.4)}" stroke-width="2" fill="none"/>
    ${hi("M 56 86 Q 58 108 72 120")}`,
  // SEA
  bubbles: () => `<defs>${lg("h", "#ff7ac8")}<radialGradient id="${P}b" cx="0.35" cy="0.3" r="0.8"><stop offset="0" stop-color="#ffffff" stop-opacity="0.9"/><stop offset="0.6" stop-color="#9ff3f6" stop-opacity="0.35"/><stop offset="1" stop-color="#6fe3e8" stop-opacity="0.7"/></radialGradient></defs>${ground(30)}
    <path d="M 66 132 L 74 82" stroke="${INK}" stroke-width="11" stroke-linecap="round"/><path d="M 66 132 L 74 82" stroke="${u("h")}" stroke-width="6" stroke-linecap="round"/>
    <circle cx="80" cy="56" r="27" fill="${u("b")}" stroke="#6fe3e8" stroke-width="2.5"/>
    <circle cx="80" cy="56" r="27" fill="none" stroke="${INK}" stroke-width="7"/><circle cx="80" cy="56" r="27" fill="none" stroke="${u("h")}" stroke-width="4"/>
    <circle cx="116" cy="34" r="12" fill="${u("b")}" stroke="${INK}" stroke-width="2.5"/><circle cx="112" cy="30" r="3" fill="#fff"/>
    <circle cx="124" cy="62" r="7" fill="${u("b")}" stroke="${INK}" stroke-width="2"/>
    ${hi("M 64 48 Q 68 38 78 35", 4, 0.8)}`,
  fin: () => `<defs>${lg("t", "#f3ead8")}</defs>${ground(28)}${cord(46, 42, 114, 42, "#4f8fb8")}
    <circle cx="80" cy="46" r="7" fill="none" stroke="${INK}" stroke-width="6"/><circle cx="80" cy="46" r="7" fill="none" stroke="#c9b48a" stroke-width="3"/>
    <path d="M 56 56 Q 80 50 104 56 Q 100 70 96 84 Q 88 112 80 132 Q 72 112 64 84 Q 60 70 56 56 Z" fill="${u("t")}" ${O()}/>
    ${[[64, 70], [70, 92], [76, 114]].map(([x, y]) => `<path d="M ${x} ${y} l 4 -3" stroke="${dark("#f3ead8", 0.35)}" stroke-width="2" stroke-linecap="round"/>`).join("")}
    <path d="M 56 56 Q 80 64 104 56" fill="none" stroke="${INK}" stroke-width="2.5"/>
    ${hi("M 68 66 Q 72 92 78 116", 4, 0.7)}`,
  clam: () => `<defs>${lg("s", "#f7c6d9")}<radialGradient id="${P}p" cx="0.35" cy="0.3" r="0.8"><stop offset="0" stop-color="#ffffff"/><stop offset="0.6" stop-color="#f0e6ff"/><stop offset="1" stop-color="#b8a6d9"/></radialGradient></defs>${ground(48)}
    <path d="M 30 112 Q 32 70 80 62 Q 128 70 130 112 Q 80 126 30 112 Z" fill="${u("s")}" ${O()}/>
    ${[-40, -20, 0, 20, 40].map((dx) => `<path d="M ${80 + dx * 0.25} 68 Q ${80 + dx * 0.9} 88 ${80 + dx * 1.15} 116" stroke="${dark("#f7c6d9", 0.3)}" stroke-width="2.5" fill="none"/>`).join("")}
    <path d="M 46 112 Q 80 96 114 112 Q 80 120 46 112 Z" fill="${dark("#f7c6d9", 0.5)}" opacity="0.6"/>
    <circle cx="80" cy="96" r="17" fill="${u("p")}" ${O(3.5)}/><circle cx="74" cy="90" r="5" fill="#fff"/>
    ${spark(110, 60, 8)}${spark(44, 70, 5, "#fff", 0.8)}`,
  kraken: () => `<defs>${lg("k", "#8e3bbd")}</defs>${ground(34)}
    <path d="M 58 132 Q 46 96 66 74 Q 86 52 104 60 Q 122 70 112 88 Q 102 102 90 92 Q 82 84 90 78" fill="none" stroke="${INK}" stroke-width="27" stroke-linecap="round"/>
    <path d="M 58 132 Q 46 96 66 74 Q 86 52 104 60 Q 122 70 112 88 Q 102 102 90 92 Q 82 84 90 78" fill="none" stroke="${u("k")}" stroke-width="20" stroke-linecap="round"/>
    ${[[60, 116], [58, 100], [64, 84], [76, 70], [92, 62], [106, 68], [110, 82]].map(([x, y]) => `<circle cx="${x + 5}" cy="${y + 4}" r="4" fill="#f2c4e6" stroke="${INK}" stroke-width="1.8"/>`).join("")}
    ${hi("M 52 110 Q 50 92 62 78", 4, 0.45)}`,
  // TECH
  bolt: () => `<defs>${lg("m", "#9aa8c7")}${lg("b", "#3a3aff")}</defs>${ground(32)}
    <path d="M 56 132 L 56 110 L 68 100 L 92 100 L 104 110 L 104 132 Z" fill="${u("m")}" ${O()}/><circle cx="80" cy="116" r="8" fill="${dark("#9aa8c7", 0.5)}" ${O(2.5)}/>
    <path d="M 80 100 L 80 44" stroke="${INK}" stroke-width="10" stroke-linecap="round"/><path d="M 80 100 L 80 44" stroke="#5a5aff" stroke-width="5" stroke-linecap="round"/>
    <path d="M 84 16 L 68 44 L 80 44 L 74 66 L 96 34 L 84 34 Z" fill="#ffe66b" ${O(3.5)}/>
    ${spark(110, 38, 8, "#ffe66b")}${spark(50, 48, 6, "#ffe66b", 0.85)}${hi("M 62 112 L 62 126", 3.5, 0.5)}`,
  laser: () => `<defs>${lg("m", "#9aa8c7")}<radialGradient id="${P}g" cx="0.35" cy="0.3" r="0.8"><stop offset="0" stop-color="#ffffff"/><stop offset="0.5" stop-color="#7fe3ff"/><stop offset="1" stop-color="#1d7fb8"/></radialGradient></defs>${ground(36)}
    <path d="M 18 110 L 70 80" stroke="#ff4d6d" stroke-width="7" stroke-linecap="round" opacity="0.55"/><path d="M 18 110 L 70 80" stroke="#ffd1d9" stroke-width="2.5" stroke-linecap="round"/>
    <path d="M 64 134 L 70 112 L 90 112 L 96 134 Z" fill="${u("m")}" ${O(3.5)}/><path d="M 80 112 L 80 100" stroke="${INK}" stroke-width="8"/>
    <circle cx="80" cy="70" r="34" fill="${u("m")}" ${O()}/><circle cx="80" cy="70" r="24" fill="${u("g")}" ${O(3)}/>
    <path d="M 92 64 L 142 40" stroke="#ff4d6d" stroke-width="7" stroke-linecap="round" opacity="0.55"/><path d="M 92 64 L 142 40" stroke="#ffd1d9" stroke-width="2.5" stroke-linecap="round"/>
    <circle cx="72" cy="62" r="7" fill="#fff" opacity="0.9"/>`,
  megabot: () => `<defs>${lg("r", "#d9e2f0")}${lg("f", "#3d5a80")}</defs>${ground(28)}
    <g transform="rotate(30 80 80)">
    <path d="M 66 108 Q 80 132 94 108 Z" fill="#ff8a3d" ${O(3)}/><path d="M 72 108 Q 80 122 88 108 Z" fill="#ffd36b"/>
    <path d="M 66 96 L 50 116 L 66 110 Z M 94 96 L 110 116 L 94 110 Z" fill="${u("f")}" ${O(3)}/>
    <path d="M 80 20 Q 98 40 96 110 L 64 110 Q 62 40 80 20 Z" fill="${u("r")}" ${O()}/>
    <path d="M 70 42 Q 80 32 90 42" fill="none" stroke="#e8405a" stroke-width="5"/>
    <circle cx="80" cy="66" r="9" fill="#5ce1ff" ${O(3)}/><path d="M 72 92 L 88 92" stroke="#3d5a80" stroke-width="5"/>
    ${hi("M 70 50 Q 68 76 70 100", 4, 0.6)}</g>`,
  clockwork: () => `<defs>${lg("g", "#e0b43a")}</defs>${ground(30)}
    <g transform="rotate(-30 80 80)">
    ${[[56, 50], [104, 50]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="21" fill="${u("g")}" ${O()}/><circle cx="${x}" cy="${y}" r="9" fill="${dark("#c9a227", 0.6)}" ${O(3)}/>`).join("")}
    <circle cx="80" cy="58" r="13" fill="${u("g")}" ${O()}/>
    <path d="M 74 66 L 74 128 L 86 128 L 86 66 Z" fill="${u("g")}" ${O()}/>
    <path d="M 86 100 L 98 100 L 98 110 L 92 110 L 92 118 L 86 118 Z" fill="${u("g")}" ${O(3)}/>
    ${hi("M 44 42 Q 50 34 58 33", 3.5, 0.7)}${hi("M 77 72 L 77 118", 2.5, 0.5)}</g>
    ${spark(124, 116, 6)}`,
  // SWEET
  crumb: () => `<defs>${rg("c", "#c98a4b")}</defs>${ground(42)}
    <path d="M 34 96 Q 32 54 72 42 Q 104 36 118 56 Q 110 58 110 66 Q 100 66 102 76 Q 94 80 100 90 Q 112 92 124 88 Q 122 120 84 130 Q 40 130 34 96 Z" fill="${u("c")}" ${O()}/>
    ${[[56, 70], [76, 60], [62, 98], [84, 104], [52, 84], [100, 110], [80, 82]].map(([x, y], i) => `<ellipse cx="${x}" cy="${y}" rx="${i % 2 ? 5 : 6.5}" ry="${i % 2 ? 4 : 5}" fill="#4a2c17" transform="rotate(${i * 37} ${x} ${y})"/>`).join("")}
    <circle cx="128" cy="62" r="5" fill="${u("c")}" ${O(2.5)}/><circle cx="134" cy="80" r="3.5" fill="${u("c")}" ${O(2)}/>
    ${hi("M 44 86 Q 46 62 66 50", 4, 0.45)}`,
  jawbreaker: () => `<defs>${rg("j", "#2ec4b6")}<clipPath id="${P}cl"><circle cx="80" cy="80" r="44"/></clipPath></defs>${ground(40)}
    <circle cx="80" cy="80" r="44" fill="${u("j")}"/>
    <g clip-path="url(#${P}cl)">${[["#ff7ac8", 34], ["#ffd36b", 24], ["#9b5de5", 14]].map(([c, r]) => `<circle cx="80" cy="80" r="${r}" fill="none" stroke="${c}" stroke-width="7" opacity="0.85"/>`).join("")}
      <path d="M 20 64 Q 80 50 140 64" stroke="#fff" stroke-width="6" opacity="0.35" fill="none"/></g>
    <circle cx="80" cy="80" r="44" fill="none" stroke="${INK}" stroke-width="4"/>
    <ellipse cx="62" cy="58" rx="12" ry="7" fill="#fff" opacity="0.75" transform="rotate(-30 62 58)"/>`,
  pucker: () => `<defs>${rg("g", "#7b2cbf")}${lg("l", "#5fa84a")}</defs>${ground(34)}
    <path d="M 80 40 Q 82 28 90 22" stroke="${INK}" stroke-width="6" fill="none" stroke-linecap="round"/><path d="M 80 40 Q 82 28 90 22" stroke="#6f4518" stroke-width="3" fill="none" stroke-linecap="round"/>
    <path d="M 86 30 Q 106 16 122 28 Q 112 44 92 38 Z" fill="${u("l")}" ${O(3)}/>
    ${[[66, 54], [94, 54], [80, 50], [58, 78], [80, 76], [102, 78], [68, 100], [92, 100], [80, 122]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="15" fill="${u("g")}" ${O(3.5)}/><circle cx="${x - 5}" cy="${y - 5}" r="3.5" fill="#fff" opacity="0.6"/>`).join("")}
    <path d="M 118 100 Q 128 114 120 122 Q 110 118 118 100 Z" fill="#d4ff3a" ${O(2.5)}/>`,
  // FROST
  frost: () => `<defs>${lg("i", "#bfe9ff", 0, 0, 1, 0)}</defs>${ground(26)}
    <path d="M 52 24 L 108 24 Q 110 36 100 40 L 92 92 L 86 82 L 80 136 L 72 76 L 66 86 L 60 40 Q 50 36 52 24 Z" fill="${u("i")}" ${O()}/>
    <path d="M 52 24 L 108 24 Q 110 36 100 40 Q 80 46 60 40 Q 50 36 52 24 Z" fill="#fff" ${O(3)}/>
    ${hi("M 68 46 L 76 106", 4, 0.8)}${spark(112, 70, 7)}${spark(46, 104, 5, "#fff", 0.8)}`,
  blizz: () => `<defs>${lg("i", "#90e0ef")}</defs>${ground(30)}
    <g transform="translate(80 76)">${[0, 60, 120].map((r) => `<g transform="rotate(${r})"><path d="M 0 -48 L 0 48 M -11 -36 L 0 -26 L 11 -36 M -11 36 L 0 26 L 11 36" stroke="${INK}" stroke-width="12" fill="none" stroke-linecap="round" stroke-linejoin="round"/></g>`).join("")}
    ${[0, 60, 120].map((r) => `<g transform="rotate(${r})"><path d="M 0 -48 L 0 48 M -11 -36 L 0 -26 L 11 -36 M -11 36 L 0 26 L 11 36" stroke="${u("i")}" stroke-width="6" fill="none" stroke-linecap="round" stroke-linejoin="round"/></g>`).join("")}
    <path d="${star(0, 0, 14, 7, 6)}" fill="#fff" ${O(3)}/></g>
    ${spark(126, 36, 6)}`,
  frostfang: () => `<defs>${lg("i", "#bfe9ff")}${rg("p", "#6d6875")}</defs>${ground(38)}
    <path d="M 40 96 Q 40 64 80 60 Q 120 64 120 96 Q 120 128 80 130 Q 40 128 40 96 Z" fill="${u("p")}" ${O()}/>
    ${[[46, 52, -20], [68, 34, -6], [92, 34, 6], [114, 52, 20]].map(([x, y, r]) => `<g transform="rotate(${r} ${x} ${y})"><ellipse cx="${x}" cy="${y}" rx="11" ry="14" fill="${u("p")}" ${O(3.5)}/><path d="M ${x - 6} ${y - 10} L ${x} ${y - 30} L ${x + 6} ${y - 10} Z" fill="${u("i")}" ${O(3)}/></g>`).join("")}
    <path d="M 58 92 Q 80 76 102 92 Q 104 116 80 118 Q 56 116 58 92 Z" fill="${u("i")}" ${O(3)} opacity="0.95"/>
    ${hi("M 48 90 Q 52 74 68 68", 3.5, 0.45)}`,
  // TOYBOX
  drum: () => `<defs>${lg("w", "#e6b36b")}${rg("t", "#e63946")}</defs>${ground(44)}
    ${[[-28, "#e63946"], [28, "#f1f3f5"]].map(([r, tip]) => `<g transform="rotate(${r} 80 84)"><path d="M 80 132 L 80 40" stroke="${INK}" stroke-width="13" stroke-linecap="round"/><path d="M 80 132 L 80 40" stroke="#e6b36b" stroke-width="8"/><path d="M 77 128 L 77 46" stroke="#fff2d6" stroke-width="2.5" opacity="0.7" stroke-linecap="round"/><circle cx="80" cy="34" r="12" fill="${tip}" ${O(3.5)}/><circle cx="76" cy="30" r="3.5" fill="#fff" opacity="0.7"/></g>`).join("")}
    ${[[40, 112], [120, 112]].map(([x, y]) => `<path d="M ${x - 10} ${y} q 10 -8 20 0" stroke="#ffd36b" stroke-width="3.5" fill="none" stroke-linecap="round"/>`).join("")}`,
  mortar: () => `<defs>${lg("s", "#5c6b3a")}${lg("b", "#ffc93c")}</defs>${ground(26)}
    <path d="M 60 130 L 60 70 Q 60 30 80 18 Q 100 30 100 70 L 100 130 Z" fill="${u("s")}" ${O()}/>
    <path d="M 60 96 L 100 96 L 100 108 L 60 108 Z" fill="${u("b")}" ${O(3)}/>
    <path d="${star(80, 64, 12, 5)}" fill="${u("b")}" ${O(2.5)}/>
    <path d="M 56 130 L 104 130" stroke="${INK}" stroke-width="7" stroke-linecap="round"/>
    ${hi("M 66 50 Q 66 76 66 90", 4, 0.5)}`,
  jackpot: () => `<defs>${lg("g", "#ffc93c")}${rg("c", "#e0115f")}</defs>${ground(40)}
    <circle cx="80" cy="80" r="46" fill="${u("g")}" ${O()}/><circle cx="80" cy="80" r="36" fill="none" stroke="${dark("#ffc93c", 0.35)}" stroke-width="2.5" stroke-dasharray="4 5"/>
    <path d="M 64 62 L 96 62 L 84 104 L 72 104 L 82 72 L 64 72 Z" fill="${u("c")}" ${O(3.5)}/>
    ${hi("M 46 64 Q 52 44 70 38", 4, 0.7)}${spark(126, 42, 8)}${spark(36, 118, 6, "#fff", 0.8)}`,
  // SPOOKY
  puppeteer: () => `<defs>${lg("w", "#c08552")}</defs>${ground(40)}
    ${[[52, 132], [72, 132], [94, 132], [114, 132]].map(([x, y], i) => `<path d="M ${[56, 70, 92, 108][i]} ${i % 3 ? 52 : 38} L ${x} ${y}" stroke="#f3ead8" stroke-width="1.8" opacity="0.85"/>`).join("")}
    <path d="M 40 38 L 120 38" stroke="${INK}" stroke-width="14" stroke-linecap="round"/><path d="M 40 38 L 120 38" stroke="#c08552" stroke-width="9" stroke-linecap="round"/>
    <path d="M 80 16 L 80 74" stroke="${INK}" stroke-width="14" stroke-linecap="round"/><path d="M 80 16 L 80 74" stroke="#c08552" stroke-width="9" stroke-linecap="round"/>
    <path d="M 60 52 L 100 52" stroke="${INK}" stroke-width="12" stroke-linecap="round"/><path d="M 60 52 L 100 52" stroke="#c08552" stroke-width="7" stroke-linecap="round"/>
    ${[[52, 132], [72, 132], [94, 132], [114, 132]].map(([x, y]) => `<circle cx="${x}" cy="${y - 4}" r="4" fill="#e8405a" stroke="${INK}" stroke-width="2"/>`).join("")}`,
  ghost: () => `<defs>${lg("m", "#7d6a52")}<radialGradient id="${P}g" cx="0.5" cy="0.55" r="0.6"><stop offset="0" stop-color="#ffffff"/><stop offset="0.5" stop-color="#e3d6ff"/><stop offset="1" stop-color="#9b7cff" stop-opacity="0.6"/></radialGradient></defs>${ground(30)}
    <circle cx="80" cy="22" r="8" fill="none" stroke="${INK}" stroke-width="6"/><circle cx="80" cy="22" r="8" fill="none" stroke="#c9b48a" stroke-width="3"/>
    <path d="M 58 40 L 102 40 L 96 32 L 64 32 Z" fill="${u("m")}" ${O(3.5)}/>
    <path d="M 60 40 L 60 116 L 100 116 L 100 40 Z" fill="#2a1f4a" ${O()}/>
    <path d="M 64 44 L 96 44 L 96 112 L 64 112 Z" fill="${u("g")}"/>
    <path d="M 68 100 Q 68 66 80 62 Q 92 66 92 100 L 88 96 L 84 100 L 80 96 L 76 100 L 72 96 Z" fill="#fff" stroke="${INK}" stroke-width="2"/>
    <circle cx="76" cy="78" r="2.5" fill="${INK}"/><circle cx="84" cy="78" r="2.5" fill="${INK}"/>
    <path d="M 60 78 L 100 78" stroke="${INK}" stroke-width="2.5" opacity="0.6"/><path d="M 80 40 L 80 116" stroke="${INK}" stroke-width="2.5" opacity="0.35"/>
    <path d="M 54 116 L 106 116 L 102 130 L 58 130 Z" fill="${u("m")}" ${O(3.5)}/>`,
  foxfire: () => `<defs>${lg("m", "#fff1e8")}${lg("e", "#ffb4a2")}</defs>${ground(38)}
    <path d="M 36 26 L 62 50 Q 80 44 98 50 L 124 26 Q 130 70 112 98 Q 96 124 80 130 Q 64 124 48 98 Q 30 70 36 26 Z" fill="${u("m")}" ${O()}/>
    <path d="M 42 36 L 58 52 L 48 62 Z M 118 36 L 102 52 L 112 62 Z" fill="${u("e")}" ${O(2.5)}/>
    <path d="M 52 78 Q 62 70 72 80 Q 62 82 52 78 Z M 108 78 Q 98 70 88 80 Q 98 82 108 78 Z" fill="#e8405a" ${O(2.5)}/>
    <path d="M 74 112 Q 80 118 86 112 L 80 106 Z" fill="${INK}"/>
    <path d="M 80 54 Q 86 60 80 70 Q 74 60 80 54 Z" fill="#ff6a2a" ${O(2)}/>
    ${[[24, 96], [136, 96]].map(([x, y]) => `<path d="M ${x} ${y + 12} Q ${x - 10} ${y} ${x} ${y - 14} Q ${x + 10} ${y} ${x} ${y + 12} Z" fill="#ffb4a2" opacity="0.85" ${O(2.5)}/><path d="M ${x} ${y + 8} Q ${x - 4} ${y + 2} ${x} ${y - 6} Q ${x + 4} ${y + 2} ${x} ${y + 8} Z" fill="#fff"/>`).join("")}`,
  // FIRE
  magmo: () => `<defs>${rg("r", "#3a2a2a")}</defs>${ground(44)}
    <path d="M 34 110 L 44 70 L 70 46 L 104 50 L 126 78 L 124 112 L 96 128 L 58 128 Z" fill="${u("r")}" ${O()}/>
    <path d="M 52 74 L 70 86 L 64 104 M 70 86 L 94 80 L 110 96 M 94 80 L 98 58 M 64 104 L 88 112" stroke="#ff4500" stroke-width="6" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
    <path d="M 52 74 L 70 86 L 64 104 M 70 86 L 94 80 L 110 96 M 94 80 L 98 58 M 64 104 L 88 112" stroke="#ffd36b" stroke-width="2.5" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
    <path d="M 80 30 Q 72 18 80 8 Q 88 18 80 30 Z" fill="#ff8a3d" opacity="0.8"/>
    ${hi("M 44 96 L 50 74 L 66 58", 3.5, 0.3)}`,
  drako: () => `<defs>${lg("s", "#2b9348")}</defs>${ground(34)}
    <path d="M 80 18 Q 122 40 118 84 Q 112 120 80 134 Q 48 120 42 84 Q 38 40 80 18 Z" fill="${u("s")}" ${O()}/>
    <path d="M 80 34 Q 108 52 104 86 Q 100 112 80 122 Q 60 112 56 86 Q 52 52 80 34 Z" fill="none" stroke="${lite("#2b9348", 0.3)}" stroke-width="3"/>
    <path d="M 80 30 L 80 128" stroke="${dark("#2b9348", 0.35)}" stroke-width="3"/>
    <path d="M 80 62 Q 70 74 74 90 Q 66 84 66 74 Q 60 90 70 102 Q 80 110 90 102 Q 100 90 94 74 Q 94 84 86 90 Q 90 74 80 62 Z" fill="#ff8a3d" ${O(2.5)}/>
    ${hi("M 52 70 Q 54 46 72 34", 4, 0.5)}`,
  supernova: () => `<defs><radialGradient id="${P}s" cx="0.4" cy="0.35" r="0.8"><stop offset="0" stop-color="#ffffff"/><stop offset="0.45" stop-color="#ffd6a5"/><stop offset="1" stop-color="#ff8a3d"/></radialGradient></defs>${ground(34)}
    ${Array.from({ length: 12 }, (_, k) => { const a = (k / 12) * 6.283; const r1 = 50, r2 = k % 2 ? 58 : 66; return `<path d="M ${f(80 + Math.cos(a) * r1)} ${f(76 + Math.sin(a) * r1)} L ${f(80 + Math.cos(a) * r2)} ${f(76 + Math.sin(a) * r2)}" stroke="#ffd6a5" stroke-width="4" stroke-linecap="round" opacity="0.8"/>`; }).join("")}
    <path d="${star(80, 76, 46, 22, 5)}" fill="${u("s")}" ${O()}/>
    <circle cx="80" cy="80" r="9" fill="#fff" opacity="0.9"/>`,
  // COSMIC
  comet: () => `<defs>${rg("c", "#ff5ad1")}<linearGradient id="${P}t" x1="1" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ff5ad1" stop-opacity="0.9"/><stop offset="1" stop-color="#6f6bff" stop-opacity="0"/></linearGradient></defs>${ground(30)}
    <path d="M 98 48 Q 60 64 18 132 Q 74 100 112 70 Z" fill="${u("t")}"/>
    ${[[60, 98], [42, 116], [74, 86]].map(([x, y], i) => spark(x, y, 5 - i, "#fff", 0.85)).join("")}
    <path d="${star(110, 56, 30, 14, 5, -1.2)}" fill="${u("c")}" ${O()}/>
    <circle cx="104" cy="50" r="5" fill="#fff" opacity="0.8"/>`,
  gravity: () => `<defs>${rg("p", "#5b4bd6")}</defs>${ground(40)}
    <path d="M 22 90 Q 80 60 138 70" fill="none" stroke="${INK}" stroke-width="10" stroke-linecap="round"/>
    <circle cx="80" cy="76" r="34" fill="${u("p")}" ${O()}/>
    <path d="M 52 64 Q 80 56 108 66 M 48 84 Q 80 76 112 86" stroke="${lite("#5b4bd6", 0.25)}" stroke-width="3" fill="none" opacity="0.7"/>
    <path d="M 22 90 Q 80 104 138 70" fill="none" stroke="${INK}" stroke-width="10" stroke-linecap="round"/><path d="M 22 90 Q 80 104 138 70" fill="none" stroke="#ff8a3d" stroke-width="5" stroke-linecap="round"/>
    <circle cx="128" cy="40" r="9" fill="#ff8a3d" ${O(3)}/><circle cx="125" cy="37" r="2.5" fill="#fff"/>
    ${hi("M 58 60 Q 64 48 78 46", 4, 0.6)}`,
  blackhole: () => `<defs><radialGradient id="${P}v" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#000"/><stop offset="0.7" stop-color="#0d0b17"/><stop offset="1" stop-color="#7a4bff"/></radialGradient></defs>${ground(40)}
    <ellipse cx="80" cy="78" rx="62" ry="18" fill="none" stroke="#b07cff" stroke-width="5" opacity="0.6" transform="rotate(-14 80 78)"/>
    <circle cx="80" cy="78" r="38" fill="url(#${P}v)" ${O()}/>
    <path d="M 18 92 Q 80 104 142 64" fill="none" stroke="${INK}" stroke-width="9" stroke-linecap="round"/><path d="M 18 92 Q 80 104 142 64" fill="none" stroke="#e3d6ff" stroke-width="4" stroke-linecap="round"/>
    ${[[66, 66], [92, 72], [74, 88]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="1.8" fill="#fff" opacity="0.8"/>`).join("")}
    <path d="M 56 60 Q 64 48 80 46" stroke="#b07cff" stroke-width="3" fill="none" opacity="0.8" stroke-linecap="round"/>`,
};

export const IDS = Object.keys(R);

export function relic(id, prefix = "") {
  P = (prefix || id) + "_";
  return `<svg xmlns="http://www.w3.org/2000/svg" width="192" height="192" viewBox="0 0 160 160">${R[id]()}</svg>`;
}

export const many = {};
for (const id of IDS) many[`relic_${id}`] = () => relic(id);
export default many.relic_spiker;

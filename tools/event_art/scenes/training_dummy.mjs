// Training Dummy: a Toybox-family squeaky bop-bag on a spring, painted with
// a target and a goofy face, mid-wobble in a playroom at night, toy blocks
// stacked around it.
import { shade } from "../../brand/parts.mjs";

const TOY = "#FFD34E";

function seeded(seed) {
  let s = seed;
  return () => ((s = (s * 16807) % 2147483647) / 2147483647);
}

// An isometric toy block: three faces, an inset emblem on the front.
function block(x, y, s, col, emblem, emCol, tilt = 0) {
  const d = s * 0.42; // depth offset
  const top = `${x},${y} ${x + s},${y} ${x + s + d * 0.6},${y - d * 0.6} ${x + d * 0.6},${y - d * 0.6}`;
  const side = `${x + s},${y} ${x + s + d * 0.6},${y - d * 0.6} ${x + s + d * 0.6},${y + s - d * 0.6} ${x + s},${y + s}`;
  const mx = x + s / 2, my = y + s / 2, r = s * 0.28;
  let em = "";
  if (emblem === "star") {
    let pts = "";
    for (let k = 0; k < 10; k++) {
      const a = -Math.PI / 2 + (k * Math.PI) / 5, rr = k % 2 ? r * 0.45 : r;
      pts += `${mx + Math.cos(a) * rr},${my + Math.sin(a) * rr} `;
    }
    em = `<polygon points="${pts}" fill="${emCol}" stroke-linejoin="round"/>`;
  } else if (emblem === "circle") em = `<circle cx="${mx}" cy="${my}" r="${r}" fill="${emCol}"/>`;
  else if (emblem === "tri") em = `<polygon points="${mx},${my - r} ${mx + r},${my + r * 0.75} ${mx - r},${my + r * 0.75}" fill="${emCol}" stroke="${emCol}" stroke-width="${s * 0.05}" stroke-linejoin="round"/>`;
  else em = `<path d="M ${mx} ${my + r * 0.8} C ${mx - r * 1.4} ${my - r * 0.2} ${mx - r * 0.5} ${my - r * 1.2} ${mx} ${my - r * 0.35} C ${mx + r * 0.5} ${my - r * 1.2} ${mx + r * 1.4} ${my - r * 0.2} ${mx} ${my + r * 0.8} Z" fill="${emCol}"/>`;
  return `<g transform="rotate(${tilt} ${x + s / 2} ${y + s})">
    <polygon points="${top}" fill="${shade(col, 0.25)}"/>
    <polygon points="${side}" fill="${shade(col, -0.35)}"/>
    <rect x="${x}" y="${y}" width="${s}" height="${s}" fill="${col}"/>
    <rect x="${x + s * 0.1}" y="${y + s * 0.1}" width="${s * 0.8}" height="${s * 0.8}" rx="${s * 0.08}" fill="none" stroke="${shade(col, -0.2)}" stroke-width="${s * 0.05}"/>
    ${em}
    <rect x="${x}" y="${y}" width="${s}" height="${s}" fill="url(#td_blockshade)"/>
  </g>`;
}

export default function trainingDummy() {
  const R = seeded(5);
  const W = 720, H = 440;
  const FLOOR = 300;

  // Wallpaper: little stars.
  let paper = "";
  for (let j = 0; j < 7; j++)
    for (let i = 0; i < 16; i++) {
      const x = i * 48 + (j % 2) * 24 + 10, y = j * 44 + 18;
      paper += `<circle cx="${x}" cy="${y}" r="2.2" fill="#3a3380" opacity="0.7"/>`;
    }

  // Floorboards.
  let boards = "";
  for (let k = 0; k < 7; k++) {
    const y = FLOOR + 8 + k * k * 3.2 + k * 8;
    boards += `<line x1="0" y1="${y}" x2="${W}" y2="${y}" stroke="#1c1638" stroke-width="2"/>`;
  }
  for (let k = 0; k < 14; k++) {
    const x = 60 + k * 60 + R() * 20;
    boards += `<line x1="${x}" y1="${FLOOR + 8 + (k % 3) * 20}" x2="${x + (x - 360) * 0.08}" y2="${FLOOR + 28 + (k % 3) * 20}" stroke="#1c1638" stroke-width="2"/>`;
  }

  // The dummy: a rounded bop-bag body, tilted mid-wobble about its base.
  const bx = 360, base = 330; // pivot at the top of the spring
  const bw = 82, top = 82;
  const body = `M ${bx - bw * 0.62} ${base - 18}
    C ${bx - bw * 1.1} ${base - 90} ${bx - bw * 0.95} ${top + 70} ${bx - bw * 0.72} ${top + 40}
    C ${bx - bw * 0.55} ${top - 2} ${bx + bw * 0.55} ${top - 2} ${bx + bw * 0.72} ${top + 40}
    C ${bx + bw * 0.95} ${top + 70} ${bx + bw * 1.1} ${base - 90} ${bx + bw * 0.62} ${base - 18}
    Q ${bx} ${base + 4} ${bx - bw * 0.62} ${base - 18} Z`;
  const tcx = bx, tcy = 222; // target centre on the belly
  const rings = [[56, "#fff4e0"], [46, "#ff5a6e"], [34, "#fff4e0"], [23, "#ff5a6e"], [12, "#fff4e0"]]
    .map(([r, c]) => `<ellipse cx="${tcx}" cy="${tcy}" rx="${r}" ry="${r * 0.95}" fill="${c}"/>`)
    .join("");
  // Painted face up top: simple dot eyes with catch-lights and a stitched grin.
  const fy = 140;
  const face = `
    <ellipse cx="${bx - 24}" cy="${fy}" rx="13" ry="15" fill="#fff"/><ellipse cx="${bx + 24}" cy="${fy}" rx="13" ry="15" fill="#fff"/>
    <circle cx="${bx - 21}" cy="${fy + 2}" r="7.5" fill="#14102e"/><circle cx="${bx + 27}" cy="${fy + 2}" r="7.5" fill="#14102e"/>
    <circle cx="${bx - 24}" cy="${fy - 1}" r="2.6" fill="#fff"/><circle cx="${bx + 24}" cy="${fy - 1}" r="2.6" fill="#fff"/>
    <ellipse cx="${bx - 44}" cy="${fy + 18}" rx="9" ry="5" fill="#ff8a6e" opacity="0.7"/><ellipse cx="${bx + 44}" cy="${fy + 18}" rx="9" ry="5" fill="#ff8a6e" opacity="0.7"/>
    <path d="M ${bx - 18} ${fy + 22} Q ${bx} ${fy + 36} ${bx + 18} ${fy + 22}" fill="none" stroke="#14102e" stroke-width="4" stroke-linecap="round"/>
    <path d="M ${bx + 6} ${fy + 28} q 4 8 9 0" fill="#ff5a7a" stroke="#14102e" stroke-width="2.5"/>`;
  // Spring coils between dummy and base.
  let spring = "";
  for (let k = 0; k < 5; k++) {
    const y = base + 2 + k * 9;
    spring += `<ellipse cx="${bx}" cy="${y}" rx="${30}" ry="7" fill="none" stroke="#5b5f86" stroke-width="7"/>`;
  }
  for (let k = 0; k < 5; k++) {
    const y = base + 2 + k * 9;
    spring += `<path d="M ${bx - 30} ${y} A 30 7 0 0 0 ${bx + 30} ${y}" fill="none" stroke="#c9d0f5" stroke-width="5"/><path d="M ${bx - 24} ${y + 4} A 30 7 0 0 0 ${bx - 6} ${y + 7}" fill="none" stroke="#fff" stroke-width="2" opacity="0.8"/>`;
  }

  // Wobble arcs and squeak puffs.
  const arcs = `
    <path d="M ${bx - 130} 120 Q ${bx - 150} 175 ${bx - 136} 230" fill="none" stroke="${TOY}" stroke-width="5" stroke-linecap="round" opacity="0.75"/>
    <path d="M ${bx - 152} 140 Q ${bx - 168} 180 ${bx - 158} 220" fill="none" stroke="${TOY}" stroke-width="4" stroke-linecap="round" opacity="0.4"/>
    <path d="M ${bx + 128} 128 Q ${bx + 146} 175 ${bx + 134} 222" fill="none" stroke="${TOY}" stroke-width="4" stroke-linecap="round" opacity="0.45"/>`;
  const squeak = [[bx + 70, 68, 0.6], [bx + 98, 50, 0.9], [bx + 86, 92, 0.3]]
    .map(([x, y, a]) => `<line x1="${x}" y1="${y}" x2="${x + Math.cos(-a) * 18}" y2="${y + Math.sin(-a) * 18}" stroke="#fff4c2" stroke-width="5" stroke-linecap="round"/>`)
    .join("");

  // Fairy-light string across the top of the wall.
  let lights = "";
  const lc = ["#FFD34E", "#FF8AD0", "#3EE6FF", "#5CFF9A", "#C9A6FF"];
  let wire = "";
  for (let x = 0; x <= W; x += 6) wire += `${x},${26 + 22 * Math.sin(Math.PI * ((x % 180) / 180))} `;
  lights += `<polyline points="${wire}" fill="none" stroke="#2c2170" stroke-width="2.5"/>`;
  for (let k = 0; k < 18; k++) {
    const x = 20 + k * 40;
    const y = 26 + 22 * Math.sin(Math.PI * ((x % 180) / 180)) + 7;
    const c = lc[k % lc.length];
    lights += `<circle cx="${x}" cy="${y}" r="11" fill="${c}" opacity="0.5" filter="url(#td_g6)"/><rect x="${x - 3}" y="${y - 10}" width="6" height="5" fill="#3a3380"/><ellipse cx="${x}" cy="${y}" rx="4.5" ry="6" fill="${c}"/>`;
  }

  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">
  <defs>
    <linearGradient id="td_wall" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0D0F26"/><stop offset="1" stop-color="#22205a"/></linearGradient>
    <linearGradient id="td_floor" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2c2150"/><stop offset="1" stop-color="#141038"/></linearGradient>
    <radialGradient id="td_lamp" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="${TOY}" stop-opacity="0.45"/><stop offset="0.5" stop-color="#ff9a4e" stop-opacity="0.12"/><stop offset="1" stop-color="#ff9a4e" stop-opacity="0"/></radialGradient>
    <radialGradient id="td_moonbeam" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#bfd4ff" stop-opacity="0.35"/><stop offset="1" stop-color="#bfd4ff" stop-opacity="0"/></radialGradient>
    <radialGradient id="td_body" cx="0.3" cy="0.25" r="0.9"><stop offset="0" stop-color="${shade(TOY, 0.4)}"/><stop offset="0.45" stop-color="${TOY}"/><stop offset="1" stop-color="${shade(TOY, -0.45)}"/></radialGradient>
    <linearGradient id="td_bodyshade" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#000" stop-opacity="0"/><stop offset="0.6" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#1a0f3a" stop-opacity="0.45"/></linearGradient>
    <linearGradient id="td_blockshade" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.12"/><stop offset="1" stop-color="#14102e" stop-opacity="0.3"/></linearGradient>
    <radialGradient id="td_base" cx="0.4" cy="0.3" r="0.8"><stop offset="0" stop-color="#ff8a9a"/><stop offset="0.5" stop-color="#ff5a6e"/><stop offset="1" stop-color="#8a1f3a"/></radialGradient>
    <radialGradient id="td_rug" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#3EA8FF" stop-opacity="0.35"/><stop offset="1" stop-color="#3EA8FF" stop-opacity="0.12"/></radialGradient>
    <filter id="td_g6" x="-100%" y="-100%" width="300%" height="300%"><feGaussianBlur stdDeviation="6"/></filter>
    <filter id="td_g16" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="16"/></filter>
    <clipPath id="td_bodyclip"><path d="${body}"/></clipPath>
    <radialGradient id="td_vig" cx="0.5" cy="0.45" r="0.75"><stop offset="0.6" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#05061a" stop-opacity="0.7"/></radialGradient>
  </defs>
  <rect width="${W}" height="${FLOOR}" fill="url(#td_wall)"/>
  ${paper}
  <!-- window with moon -->
  <g>
    <rect x="70" y="70" width="130" height="140" rx="10" fill="#0a0c22" stroke="#3a3380" stroke-width="8"/>
    <circle cx="160" cy="112" r="20" fill="#eef1ff"/><circle cx="168" cy="106" r="18" fill="#0a0c22"/>
    <circle cx="100" cy="160" r="1.6" fill="#fff"/><circle cx="125" cy="95" r="1.3" fill="#fff"/><circle cx="180" cy="180" r="1.4" fill="#fff"/>
    <line x1="135" y1="70" x2="135" y2="210" stroke="#3a3380" stroke-width="6"/><line x1="70" y1="140" x2="200" y2="140" stroke="#3a3380" stroke-width="6"/>
    <path d="M 56 60 Q 70 140 60 226 L 84 226 Q 92 140 84 60 Z" fill="#5a3a8a"/><path d="M 214 60 Q 200 140 210 226 L 186 226 Q 178 140 186 60 Z" fill="#5a3a8a"/>
  </g>
  <ellipse cx="150" cy="330" rx="160" ry="60" fill="url(#td_moonbeam)"/>
  <!-- shelf with silhouettes -->
  <rect x="510" y="120" width="160" height="10" rx="3" fill="#2c2170"/>
  <circle cx="540" cy="104" r="16" fill="#1d1848"/><rect x="570" y="86" width="26" height="34" rx="4" fill="#1d1848"/><path d="M 615 120 L 630 82 L 645 120 Z" fill="#1d1848"/>
  ${lights}
  <!-- lamp glow -->
  <ellipse cx="620" cy="240" rx="260" ry="200" fill="url(#td_lamp)"/>
  <rect x="0" y="${FLOOR}" width="${W}" height="${H - FLOOR}" fill="url(#td_floor)"/>
  <rect x="0" y="${FLOOR - 6}" width="${W}" height="10" fill="#1d1848"/>
  ${boards}
  <!-- rug -->
  <ellipse cx="360" cy="372" rx="250" ry="52" fill="url(#td_rug)"/>
  <ellipse cx="360" cy="372" rx="226" ry="44" fill="none" stroke="#3EA8FF" stroke-width="3" stroke-dasharray="10 8" opacity="0.5"/>
  <!-- night lamp -->
  <g>
    <circle cx="640" cy="236" r="44" fill="${TOY}" opacity="0.35" filter="url(#td_g16)"/>
    <rect x="634" y="250" width="12" height="52" fill="#3a3380"/><ellipse cx="640" cy="302" rx="26" ry="7" fill="#2c2170"/>
    <path d="M 608 256 Q 610 214 640 210 Q 670 214 672 256 Z" fill="#ffe28a"/><path d="M 608 256 Q 640 266 672 256" fill="none" stroke="#ffb64e" stroke-width="4"/>
  </g>

  <!-- block stacks -->
  <ellipse cx="150" cy="378" rx="96" ry="14" fill="#05061a" opacity="0.55" filter="url(#td_g6)"/>
  ${block(84, 300, 74, "#3EA8FF", "star", "#FFD34E")}${block(164, 312, 62, "#5CFF9A", "circle", "#ff5a6e")}${block(112, 230, 66, "#FF8AD0", "tri", "#fff4e0", -8)}
  <ellipse cx="560" cy="392" rx="90" ry="14" fill="#05061a" opacity="0.55" filter="url(#td_g6)"/>
  ${block(510, 322, 66, "#C9A6FF", "heart", "#FF8AD0")}${block(588, 340, 50, "#FF7A45", "star", "#fff4e0", 14)}

  <!-- the dummy -->
  <ellipse cx="${bx}" cy="392" rx="108" ry="16" fill="#05061a" opacity="0.7" filter="url(#td_g6)"/>
  <ellipse cx="${bx}" cy="${base + 52}" rx="70" ry="18" fill="#8a1f3a"/>
  <ellipse cx="${bx}" cy="${base + 46}" rx="70" ry="18" fill="url(#td_base)"/>
  <ellipse cx="${bx - 22}" cy="${base + 40}" rx="18" ry="5" fill="#fff" opacity="0.35"/>
  ${spring}
  <ellipse cx="${bx}" cy="200" rx="140" ry="150" fill="${TOY}" opacity="0.14" filter="url(#td_g16)"/>
  ${arcs}
  <g transform="rotate(7 ${bx} ${base})">
    <path d="${body}" fill="url(#td_body)" stroke="${shade(TOY, -0.55)}" stroke-width="4"/>
    <g clip-path="url(#td_bodyclip)">
      ${rings}
      <path d="M ${bx - 120} ${base - 40} Q ${bx} ${base - 10} ${bx + 120} ${base - 40} L ${bx + 120} ${base + 20} L ${bx - 120} ${base + 20} Z" fill="#ff5a6e"/>
      <path d="M ${bx - 120} ${base - 40} Q ${bx} ${base - 10} ${bx + 120} ${base - 40}" fill="none" stroke="#fff4e0" stroke-width="5" stroke-dasharray="2 9" stroke-linecap="round"/>
      <rect x="${bx - 120}" y="60" width="240" height="300" fill="url(#td_bodyshade)"/>
      <ellipse cx="${bx + bw * 1.0}" cy="200" rx="26" ry="120" fill="#ffb64e" opacity="0.55" filter="url(#td_g6)"/>
      <ellipse cx="${bx - bw * 1.05}" cy="230" rx="16" ry="90" fill="#bfd4ff" opacity="0.3" filter="url(#td_g6)"/>
      <ellipse cx="${bx + 10}" cy="${tcy + 4}" rx="9" ry="5" fill="#14102e" opacity="0.3" transform="rotate(-20 ${bx + 10} ${tcy + 4})"/>
    </g>
    ${face}
    <ellipse cx="${bx - 40}" cy="${top + 30}" rx="18" ry="9" fill="#fff" opacity="0.4" transform="rotate(-35 ${bx - 40} ${top + 30})"/>
    <!-- squeaker nub -->
    <rect x="${bx - 9}" y="${top - 12}" width="18" height="16" rx="5" fill="#ff5a6e" stroke="#8a1f3a" stroke-width="3"/>
  </g>
  ${squeak}
  ${block(232, 362, 44, "#FFD34E", "heart", "#ff5a6e", -22)}
  <rect width="${W}" height="${H}" fill="url(#td_vig)"/>
</svg>`;
}

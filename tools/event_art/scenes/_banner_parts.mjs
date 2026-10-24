// Shared pieces for the Bounce Run screen banners (banner_*.mjs): a cute
// critter with family accessories and moods, night sky, light motes and the
// navy edge fade that blends a banner into the #0D0F26 page.
import { ball, eye, shade, INK } from "../../brand/parts.mjs";
import { sparkle, blush, rng } from "./_shop_charge_pad_glow_chest_parts.mjs";

let uid = 0;
const nid = (p) => `${p}${uid++}`;

export const FAM = {
  nature: "#5fd068", sea: "#3fa9f5", tech: "#9aa8c7", sweet: "#ff7ac8", frost: "#8fe6ff",
  toybox: "#ffc93c", spooky: "#b07cff", fire: "#ff6a3d", cosmic: "#7b77ff",
};

// Accessory drawn behind the body (so it peeks out of the outline).
function accessory(kind, cx, cy, r, col) {
  const dk = shade(col, -0.5);
  const st = `stroke="${dk}" stroke-width="${r * 0.06}" stroke-linejoin="round"`;
  switch (kind) {
    case "leaf": // a sprout with two leaves
      return `<path d="M ${cx} ${cy - r * 0.9} Q ${cx + r * 0.05} ${cy - r * 1.2} ${cx - r * 0.02} ${cy - r * 1.32}" fill="none" stroke="#2f7a3a" stroke-width="${r * 0.08}" stroke-linecap="round"/>
        <path d="M ${cx} ${cy - r * 1.28} Q ${cx - r * 0.45} ${cy - r * 1.55} ${cx - r * 0.62} ${cy - r * 1.22} Q ${cx - r * 0.3} ${cy - r * 1.1} ${cx} ${cy - r * 1.28} Z" fill="#7ee08a" ${st}/>
        <path d="M ${cx} ${cy - r * 1.24} Q ${cx + r * 0.4} ${cy - r * 1.5} ${cx + r * 0.55} ${cy - r * 1.18} Q ${cx + r * 0.28} ${cy - r * 1.06} ${cx} ${cy - r * 1.24} Z" fill="#5fd068" ${st}/>`;
    case "fin": // a sea fin on top
      return `<path d="M ${cx - r * 0.45} ${cy - r * 0.8} Q ${cx - r * 0.1} ${cy - r * 1.55} ${cx + r * 0.45} ${cy - r * 1.35} Q ${cx + r * 0.2} ${cy - r * 1.05} ${cx + r * 0.35} ${cy - r * 0.85} Z" fill="${shade(col, 0.25)}" ${st}/>
        <path d="M ${cx - r * 0.2} ${cy - r * 0.95} Q ${cx} ${cy - r * 1.3} ${cx + r * 0.3} ${cy - r * 1.3}" fill="none" stroke="${shade(col, 0.6)}" stroke-width="${r * 0.04}" opacity="0.7"/>`;
    case "antenna":
      return `<path d="M ${cx + r * 0.1} ${cy - r * 0.9} L ${cx + r * 0.22} ${cy - r * 1.42}" stroke="${dk}" stroke-width="${r * 0.07}" stroke-linecap="round"/>
        <circle cx="${cx + r * 0.22}" cy="${cy - r * 1.48}" r="${r * 0.3}" fill="#3EE6FF" opacity="0.5" filter="url(#bl6)"/>
        <circle cx="${cx + r * 0.22}" cy="${cy - r * 1.48}" r="${r * 0.13}" fill="#bff8ff" stroke="${dk}" stroke-width="${r * 0.04}"/>`;
    case "ears": // sweet bunny-ish ears
      return [-1, 1].map((d) => `<ellipse cx="${cx + d * r * 0.45}" cy="${cy - r * 1.05}" rx="${r * 0.2}" ry="${r * 0.42}" fill="${col}" ${st} transform="rotate(${d * 18} ${cx + d * r * 0.45} ${cy - r * 1.05})"/>
        <ellipse cx="${cx + d * r * 0.45}" cy="${cy - r * 1.02}" rx="${r * 0.09}" ry="${r * 0.27}" fill="#ffd0ea" transform="rotate(${d * 18} ${cx + d * r * 0.45} ${cy - r * 1.05})"/>`).join("");
    case "crystal": // frost shards
      return `<polygon points="${cx - r * 0.35},${cy - r * 0.8} ${cx - r * 0.22},${cy - r * 1.35} ${cx - r * 0.06},${cy - r * 0.85}" fill="#d9fbff" ${st}/>
        <polygon points="${cx - r * 0.08},${cy - r * 0.9} ${cx + r * 0.1},${cy - r * 1.55} ${cx + r * 0.28},${cy - r * 0.88}" fill="#bff4ff" ${st}/>
        <polygon points="${cx + r * 0.25},${cy - r * 0.82} ${cx + r * 0.42},${cy - r * 1.22} ${cx + r * 0.52},${cy - r * 0.7}" fill="#d9fbff" ${st}/>`;
    case "propeller": // toybox beanie propeller
      return `<path d="M ${cx - r * 0.5} ${cy - r * 0.78} Q ${cx} ${cy - r * 1.18} ${cx + r * 0.5} ${cy - r * 0.78} Z" fill="#ff5a6e" ${st}/>
        <line x1="${cx}" y1="${cy - r * 1.0}" x2="${cx}" y2="${cy - r * 1.22}" stroke="${dk}" stroke-width="${r * 0.06}"/>
        <ellipse cx="${cx - r * 0.25}" cy="${cy - r * 1.24}" rx="${r * 0.26}" ry="${r * 0.07}" fill="#3EE6FF" ${st}/>
        <ellipse cx="${cx + r * 0.25}" cy="${cy - r * 1.24}" rx="${r * 0.26}" ry="${r * 0.07}" fill="#5CFF9A" ${st}/>
        <circle cx="${cx}" cy="${cy - r * 1.24}" r="${r * 0.07}" fill="#ffd34e" ${st}/>`;
    case "horns": // spooky little horns
      return [-1, 1].map((d) => `<path d="M ${cx + d * r * 0.3} ${cy - r * 0.85} Q ${cx + d * r * 0.55} ${cy - r * 1.4} ${cx + d * r * 0.72} ${cy - r * 1.3} Q ${cx + d * r * 0.62} ${cy - r * 1.05} ${cx + d * r * 0.62} ${cy - r * 0.7} Z" fill="#5a3a9a" ${st}/>`).join("");
    case "flame": { // three licking tongues of fire
      const f = (k, sc, dy) => `M ${cx - r * 0.5 * sc} ${cy - r * 0.7 + dy}
        Q ${cx - r * 0.78 * sc} ${cy - r * 1.12 * sc + dy} ${cx - r * 0.5 * sc} ${cy - r * 1.48 * sc + dy}
        Q ${cx - r * 0.38 * sc} ${cy - r * 1.22 * sc + dy} ${cx - r * 0.18 * sc} ${cy - r * 1.18 * sc + dy}
        Q ${cx - r * 0.24 * sc} ${cy - r * 1.62 * sc + dy} ${cx + r * 0.08 * sc} ${cy - r * 1.92 * sc + dy}
        Q ${cx + r * 0.06 * sc} ${cy - r * 1.5 * sc + dy} ${cx + r * 0.3 * sc} ${cy - r * 1.3 * sc + dy}
        Q ${cx + r * 0.4 * sc} ${cy - r * 1.5 * sc + dy} ${cx + r * 0.6 * sc} ${cy - r * 1.58 * sc + dy}
        Q ${cx + r * 0.8 * sc} ${cy - r * 1.12 * sc + dy} ${cx + r * 0.5 * sc} ${cy - r * 0.7 + dy} Z`;
      return `<path d="${f(0, 1, 0)}" fill="#ff6a3d" opacity="0.6" filter="url(#bl4)"/>
        <path d="${f(0, 1, 0)}" fill="#ff8a2a" ${st}/>
        <path d="${f(1, 0.72, r * 0.1)}" fill="#ffc23d"/>
        <path d="${f(2, 0.45, r * 0.2)}" fill="#fff0a0"/>`;
    }
    case "orbit": // cosmic ring + moon (drawn over the body by the caller instead)
      return "";
    default:
      return "";
  }
}

// A critter: body, accessory, face. mood: happy | wow | tired | determined | sleepy | cheer.
// look: pupil direction [lx, ly]. rim: optional rim-light colour from a light source side (+1 right / -1 left).
export function critter(cx, cy, r, col, { acc = null, mood = "happy", look = [0, 0], rim = null, rimSide = 1, glow = false, sx = 1, sy = 1, tilt = 0, blushOn = true } = {}) {
  const g = nid("cr");
  const ey = cy - r * 0.16;
  const ex = r * 0.34;
  let face = "";
  if (mood === "sleepy" || mood === "tired") {
    face += [-1, 1].map((d) => `<path d="M ${cx + d * ex - r * 0.17} ${ey + r * 0.02} Q ${cx + d * ex} ${ey + r * 0.16} ${cx + d * ex + r * 0.17} ${ey + r * 0.02}" fill="none" stroke="${INK}" stroke-width="${r * 0.08}" stroke-linecap="round"/>`).join("");
    if (mood === "tired") {
      // heavy, droopy lids: half-open eyes whose lids slope down to the outer corners
      face = [-1, 1].map((d) => {
        const x = cx + d * ex, px = x + look[0] * r * 0.07, w = r * 0.2;
        const yo = ey + r * 0.06, yi = ey - r * 0.07; // outer corner sits lower
        const yl = d > 0 ? yi : yo, yr = d > 0 ? yo : yi;
        const cid = `${g}e${d > 0 ? "r" : "l"}`;
        return `<defs><clipPath id="${cid}"><path d="M ${x - w} ${yl} L ${x + w} ${yr} A ${w} ${r * 0.22} 0 0 1 ${x - w} ${yl} Z"/></clipPath></defs>
        <path d="M ${x - w} ${yl} L ${x + w} ${yr} A ${w} ${r * 0.22} 0 0 1 ${x - w} ${yl} Z" fill="#fff"/>
        <g clip-path="url(#${cid})"><circle cx="${px}" cy="${ey + r * 0.1}" r="${r * 0.105}" fill="${INK}"/>
        <circle cx="${px - r * 0.04}" cy="${ey + r * 0.07}" r="${r * 0.035}" fill="#fff"/></g>
        <path d="M ${x - w * 1.08} ${yl} L ${x + w * 1.08} ${yr}" stroke="${INK}" stroke-width="${r * 0.065}" stroke-linecap="round"/>`;
      }).join("");
      face += `<path d="M ${cx - r * 0.16} ${cy + r * 0.3} Q ${cx} ${cy + r * 0.42} ${cx + r * 0.16} ${cy + r * 0.3}" fill="none" stroke="${INK}" stroke-width="${r * 0.07}" stroke-linecap="round"/>`;
    } else {
      face += `<path d="M ${cx - r * 0.13} ${cy + r * 0.32} Q ${cx} ${cy + r * 0.4} ${cx + r * 0.13} ${cy + r * 0.32}" fill="none" stroke="${INK}" stroke-width="${r * 0.07}" stroke-linecap="round"/>`;
    }
  } else if (mood === "cheer") {
    // ^^ closed happy eyes + big open smile
    face += [-1, 1].map((d) => `<path d="M ${cx + d * ex - r * 0.16} ${ey + r * 0.06} Q ${cx + d * ex} ${ey - r * 0.16} ${cx + d * ex + r * 0.16} ${ey + r * 0.06}" fill="none" stroke="${INK}" stroke-width="${r * 0.085}" stroke-linecap="round"/>`).join("");
    face += `<path d="M ${cx - r * 0.26} ${cy + r * 0.18} Q ${cx} ${cy + r * 0.2} ${cx + r * 0.26} ${cy + r * 0.18} Q ${cx + r * 0.2} ${cy + r * 0.52} ${cx} ${cy + r * 0.52} Q ${cx - r * 0.2} ${cy + r * 0.52} ${cx - r * 0.26} ${cy + r * 0.18} Z" fill="${INK}"/>
      <ellipse cx="${cx}" cy="${cy + r * 0.44}" rx="${r * 0.12}" ry="${r * 0.07}" fill="#ff5a7a"/>`;
  } else {
    const big = mood === "wow" ? 1.12 : 1;
    face += eye(cx - ex, ey, r * 0.2 * big, r * 0.25 * big, look[0], look[1], r * 0.115);
    face += eye(cx + ex, ey, r * 0.2 * big, r * 0.25 * big, look[0], look[1], r * 0.115);
    if (mood === "wow") {
      face += `<ellipse cx="${cx}" cy="${cy + r * 0.36}" rx="${r * 0.11}" ry="${r * 0.14}" fill="${INK}"/>`;
    } else if (mood === "determined") {
      face += `<line x1="${cx - ex - r * 0.2}" y1="${ey - r * 0.36}" x2="${cx - ex + r * 0.16}" y2="${ey - r * 0.26}" stroke="${INK}" stroke-width="${r * 0.08}" stroke-linecap="round"/>
        <line x1="${cx + ex + r * 0.2}" y1="${ey - r * 0.36}" x2="${cx + ex - r * 0.16}" y2="${ey - r * 0.26}" stroke="${INK}" stroke-width="${r * 0.08}" stroke-linecap="round"/>
        <path d="M ${cx - r * 0.2} ${cy + r * 0.28} Q ${cx} ${cy + r * 0.44} ${cx + r * 0.22} ${cy + r * 0.26}" fill="none" stroke="${INK}" stroke-width="${r * 0.08}" stroke-linecap="round"/>`;
    } else {
      face += `<path d="M ${cx - r * 0.2} ${cy + r * 0.26} Q ${cx} ${cy + r * 0.46} ${cx + r * 0.2} ${cy + r * 0.26}" fill="none" stroke="${INK}" stroke-width="${r * 0.08}" stroke-linecap="round"/>`;
    }
  }
  if (blushOn) face += blush(cx - r * 0.58, cy + r * 0.14, r * 0.13) + blush(cx + r * 0.58, cy + r * 0.14, r * 0.13);
  let orbit = "";
  if (acc === "orbit") {
    orbit = `<ellipse cx="${cx}" cy="${cy - r * 0.2}" rx="${r * 1.25}" ry="${r * 0.28}" fill="none" stroke="#ffe08a" stroke-width="${r * 0.05}" opacity="0.75" transform="rotate(-14 ${cx} ${cy - r * 0.2})"/>
      <circle cx="${cx + r * 1.1}" cy="${cy - r * 0.5}" r="${r * 0.12}" fill="#ffe08a"/>`;
    for (const [a, b, s] of [[-0.5, 0.45, 0.06], [0.1, 0.66, 0.05], [0.55, 0.45, 0.045], [-0.15, -0.72, 0.045], [0.66, -0.15, 0.05]])
      orbit += `<circle cx="${cx + a * r}" cy="${cy + b * r}" r="${r * s}" fill="#fff" opacity="0.7"/>`;
  }
  const rimPath = rim
    ? `<defs><linearGradient id="${g}rim" x1="${rimSide > 0 ? 0 : 1}" y1="0" x2="${rimSide > 0 ? 1 : 0}" y2="0.2"><stop offset="0.55" stop-color="${rim}" stop-opacity="0"/><stop offset="1" stop-color="${rim}" stop-opacity="0.75"/></linearGradient></defs>
      <ellipse cx="${cx}" cy="${cy}" rx="${r * sx}" ry="${r * sy}" fill="url(#${g}rim)"/>`
    : "";
  return `<g transform="rotate(${tilt} ${cx} ${cy + r})">
    ${accessory(acc, cx, cy, r, col)}
    ${ball(cx, cy, r, col, { sx, sy, glow })}
    ${rimPath}
    ${face}
    ${orbit}
  </g>`;
}

// Ground contact shadow.
export const shadow = (cx, y, rx, o = 0.5) =>
  `<ellipse cx="${cx}" cy="${y}" rx="${rx}" ry="${rx * 0.2}" fill="#000" opacity="${o}" filter="url(#bl4)"/>`;

// Night sky stars with a few twinkles.
export function sky(seed, n, x0, y0, x1, y1) {
  const r = rng(seed);
  let out = "";
  for (let k = 0; k < n; k++) {
    const x = x0 + r() * (x1 - x0), y = y0 + r() * (y1 - y0), s = r();
    const col = s > 0.85 ? "#ffe9c4" : s > 0.7 ? "#cfe0ff" : "#ece6ff";
    out += `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="${(0.5 + s * s * 1.7).toFixed(2)}" fill="${col}" opacity="${(0.25 + s * 0.65).toFixed(2)}"/>`;
  }
  for (let k = 0; k < 5; k++) out += sparkle(x0 + r() * (x1 - x0), y0 + r() * (y1 - y0), 3 + r() * 4, "#efe8ff", 0.6 + r() * 0.3);
  return out;
}

// Floating light motes rising from a region.
export function motes(seed, n, x0, y0, x1, y1, cols) {
  const r = rng(seed);
  let out = "";
  for (let k = 0; k < n; k++) {
    const x = x0 + r() * (x1 - x0), y = y0 + r() * (y1 - y0), s = 1.2 + r() * 2.6;
    const c = cols[k % cols.length];
    out += `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="${(s * 2.4).toFixed(1)}" fill="${c}" opacity="0.25" filter="url(#bl3)"/><circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="${s.toFixed(1)}" fill="${c}" opacity="${(0.5 + r() * 0.5).toFixed(2)}"/>`;
  }
  return out;
}

// Edge fade into the #0D0F26 page: a radial vignette plus a stronger left/right
// and bottom fade so a wide banner melts into the screen.
export function edges(strength = 1) {
  const g = nid("ed");
  return `<defs>
    <radialGradient id="${g}v" cx="0.5" cy="0.46" r="0.72"><stop offset="0.55" stop-color="#0D0F26" stop-opacity="0"/><stop offset="1" stop-color="#0D0F26" stop-opacity="${0.75 * strength}"/></radialGradient>
    <linearGradient id="${g}h" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#0D0F26" stop-opacity="${0.85 * strength}"/><stop offset="0.12" stop-color="#0D0F26" stop-opacity="0"/><stop offset="0.88" stop-color="#0D0F26" stop-opacity="0"/><stop offset="1" stop-color="#0D0F26" stop-opacity="${0.85 * strength}"/></linearGradient>
    <linearGradient id="${g}b" x1="0" y1="0" x2="0" y2="1"><stop offset="0.82" stop-color="#0D0F26" stop-opacity="0"/><stop offset="1" stop-color="#0D0F26" stop-opacity="${0.9 * strength}"/></linearGradient>
  </defs>
  <rect width="720" height="440" fill="url(#${g}v)"/><rect width="720" height="440" fill="url(#${g}h)"/><rect width="720" height="440" fill="url(#${g}b)"/>`;
}

// A five-point star polygon string.
export function star5(cx, cy, r, inner = 0.45, rot = 0) {
  let pts = "";
  for (let k = 0; k < 10; k++) {
    const a = -Math.PI / 2 + rot + (k * Math.PI) / 5;
    const rr = k % 2 ? r * inner : r;
    pts += `${(cx + Math.cos(a) * rr).toFixed(1)},${(cy + Math.sin(a) * rr).toFixed(1)} `;
  }
  return pts;
}

// A plump gold star with glow and gloss.
export function goldStar(cx, cy, r, { lit = true, rot = 0 } = {}) {
  const g = nid("gs");
  if (!lit)
    return `<polygon points="${star5(cx, cy, r, 0.5, rot)}" fill="#2a2458" stroke="#4a4294" stroke-width="${r * 0.12}" stroke-linejoin="round"/>`;
  return `<defs><radialGradient id="${g}" cx="0.4" cy="0.3" r="0.8"><stop offset="0" stop-color="#fffbe0"/><stop offset="0.45" stop-color="#ffd34e"/><stop offset="1" stop-color="#e08a1a"/></radialGradient></defs>
    <polygon points="${star5(cx, cy, r * 1.3, 0.5, rot)}" fill="#ffd34e" opacity="0.6" filter="url(#bl${r > 20 ? 8 : 4})"/>
    <polygon points="${star5(cx, cy, r, 0.5, rot)}" fill="url(#${g})" stroke="#a85a10" stroke-width="${r * 0.1}" stroke-linejoin="round"/>
    <ellipse cx="${cx - r * 0.22}" cy="${cy - r * 0.22}" rx="${r * 0.18}" ry="${r * 0.1}" fill="#fff" opacity="0.7" transform="rotate(-30 ${cx - r * 0.22} ${cy - r * 0.22})"/>`;
}

export { shade, INK, sparkle, blush, rng };

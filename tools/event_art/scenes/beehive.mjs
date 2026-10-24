// Nature family: a night forest. A big golden hive hangs from a glowing,
// moss-lit branch; honey drips from its tip into a glowing pool. Little bee
// critters buzz around it, and a small critter peeks out of a bush, tempted.
import { ball, eye, shade, INK } from "../../brand/parts.mjs";

const NAT = "#5fd068";
const W = 720, H = 440;

function rng(seed) {
  let s = seed;
  return () => ((s = (s * 16807) % 2147483647) / 2147483647);
}
const f = (n) => n.toFixed(1);

const twinkle = (x, y, s, col = "#fff", o = 1) =>
  `<path d="M ${x} ${y - s} Q ${x} ${y} ${x + s} ${y} Q ${x} ${y} ${x} ${y + s} Q ${x} ${y} ${x - s} ${y} Q ${x} ${y} ${x} ${y - s} Z" fill="${col}" opacity="${o}"/>`;

// A honey drop (teardrop) pointing up, glossy.
const drop = (x, y, s) => `
  <path d="M ${x} ${y - s * 1.6} Q ${x + s * 0.2} ${y - s * 0.8} ${x + s} ${y} A ${s} ${s} 0 1 1 ${x - s} ${y} Q ${x - s * 0.2} ${y - s * 0.8} ${x} ${y - s * 1.6} Z" fill="url(#bhHoney)" stroke="#a8600c" stroke-width="1.5"/>
  <ellipse cx="${x - s * 0.35}" cy="${y - s * 0.1}" rx="${s * 0.22}" ry="${s * 0.38}" fill="#fff" opacity="0.75"/>`;

// A bee critter: yellow ball with ink stripes, wings, antennae, stinger.
let beeN = 0;
function bee(cx, cy, r, { look = [0, 0], mood = "smile", tilt = 0, flip = 1 } = {}) {
  const id = `bhBee${beeN++}`;
  const ey = cy - r * 0.08;
  const mouth = mood === "o"
    ? `<ellipse cx="${cx + flip * r * 0.05}" cy="${cy + r * 0.42}" rx="${r * 0.1}" ry="${r * 0.13}" fill="${INK}"/>`
    : `<path d="M ${cx - r * 0.22 + flip * r * 0.05} ${cy + r * 0.34} Q ${cx + flip * r * 0.05} ${cy + r * 0.6} ${cx + r * 0.22 + flip * r * 0.05} ${cy + r * 0.34}" fill="none" stroke="${INK}" stroke-width="${r * 0.1}" stroke-linecap="round"/>`;
  const wing = (dx, rot, s) => `<ellipse cx="${cx + dx * r}" cy="${cy - r * 0.95}" rx="${r * 0.42 * s}" ry="${r * 0.7 * s}" fill="url(#bhWing)" stroke="#e6f6ff" stroke-width="1.8" transform="rotate(${rot} ${cx + dx * r} ${cy - r * 0.95})"/>`;
  const ant = (d) => `<path d="M ${cx + d * r * 0.25} ${cy - r * 0.85} Q ${cx + d * r * 0.35} ${cy - r * 1.35} ${cx + d * r * 0.62} ${cy - r * 1.4}" fill="none" stroke="${INK}" stroke-width="${r * 0.08}" stroke-linecap="round"/>
    <circle cx="${cx + d * r * 0.62}" cy="${cy - r * 1.4}" r="${r * 0.11}" fill="${INK}"/>`;
  return `<g transform="rotate(${tilt} ${cx} ${cy})">
    <circle cx="${cx}" cy="${cy}" r="${r * 1.7}" fill="#ffd23f" opacity="0.18" filter="url(#bhBlur6)"/>
    ${wing(-0.45, -28, 1)}${wing(0.4, 24, 0.9)}
    ${ant(-1)}${ant(1)}
    <path d="M ${cx - flip * r * 0.95} ${cy + r * 0.1} l ${-flip * r * 0.35} ${r * 0.08} l ${flip * r * 0.3} ${r * 0.16} Z" fill="${INK}"/>
    ${ball(cx, cy, r, "#ffc93c", { glow: false })}
    <defs><clipPath id="${id}"><circle cx="${cx}" cy="${cy}" r="${r * 0.97}"/></clipPath></defs>
    <g clip-path="url(#${id})" opacity="0.92">
      <path d="M ${cx - flip * r * 0.42} ${cy - r} q ${-flip * r * 0.22} ${r} 0 ${r * 2}" fill="none" stroke="${INK}" stroke-width="${r * 0.2}"/>
      <path d="M ${cx - flip * r * 0.84} ${cy - r} q ${-flip * r * 0.14} ${r} 0 ${r * 2}" fill="none" stroke="${INK}" stroke-width="${r * 0.2}"/>
    </g>
    <ellipse cx="${cx - r * 0.38}" cy="${cy - r * 0.46}" rx="${r * 0.22}" ry="${r * 0.12}" fill="#fff" opacity="0.5" transform="rotate(-35 ${cx - r * 0.38} ${cy - r * 0.46})"/>
    ${eye(cx + flip * r * 0.02 - r * 0.0, ey, r * 0.17, r * 0.22, look[0], look[1], r * 0.1)}
    ${eye(cx + flip * r * 0.42, ey, r * 0.17, r * 0.22, look[0], look[1], r * 0.1)}
    ${mouth}
    <ellipse cx="${cx + flip * r * 0.62}" cy="${cy + r * 0.24}" rx="${r * 0.12}" ry="${r * 0.07}" fill="#ff7a6a" opacity="0.6"/>
  </g>`;
}

// Motion lines behind a flying bee.
const buzz = (x, y, d) => `<path d="M ${x} ${y} q ${d * 10} -6 ${d * 20} 0 M ${x + d * 4} ${y + 9} q ${d * 8} -5 ${d * 16} 0" fill="none" stroke="#fff3b0" stroke-width="2" stroke-linecap="round" opacity="0.55"/>`;

// The skep hive: stacked golden bands hanging from the branch.
function hive(cx, top) {
  // band k: centre y and half width, from top to bottom (bell shape)
  const bands = [];
  const n = 7;
  for (let k = 0; k < n; k++) {
    const t = k / (n - 1);
    const y = top + 22 + t * 156;
    const rx = 34 + Math.sin(Math.PI * (0.04 + t * 0.86)) * 86;
    bands.push([y, rx]);
  }
  let body = "";
  for (let k = 0; k < n; k++) {
    const [y, rx] = bands[k];
    const ry = 16 + rx * 0.06;
    body += `<ellipse cx="${cx}" cy="${y}" rx="${rx}" ry="${ry}" fill="url(#bhHive)" stroke="#8a4a0c" stroke-width="3"/>
      <ellipse cx="${cx}" cy="${y}" rx="${rx}" ry="${ry}" fill="url(#bhHiveSide)"/>
      <path d="M ${cx - rx * 0.7} ${y - ry * 0.55} Q ${cx - rx * 0.2} ${y - ry * 1.0} ${cx + rx * 0.15} ${y - ry * 0.9}" fill="none" stroke="#fff3b0" stroke-width="3" stroke-linecap="round" opacity="0.6"/>`;
  }
  // honey drips running down the bands
  let drips = "";
  for (const [k, ox, len] of [[1, -0.55, 22], [2, 0.42, 30], [3, -0.2, 18], [4, 0.6, 26], [5, -0.5, 20], [2, -0.75, 16]]) {
    const [y, rx] = bands[k];
    const x = cx + ox * rx, y0 = y + 14;
    drips += `<path d="M ${x - 7} ${y0 - 6} L ${x - 5} ${y0 + len} A 5.5 5.5 0 0 0 ${x + 6} ${y0 + len} L ${x + 7} ${y0 - 6} Z" fill="url(#bhHoney)" stroke="#a8600c" stroke-width="1.5"/>
      <path d="M ${x - 2.5} ${y0} L ${x - 2} ${y0 + len - 2}" stroke="#fff" stroke-width="2" stroke-linecap="round" opacity="0.7"/>`;
  }
  // entrance
  const [ey, erx] = bands[4];
  const ent = `
    <ellipse cx="${cx + erx * 0.1}" cy="${ey + 2}" rx="26" ry="17" fill="#ffb02a" opacity="0.9" filter="url(#bhBlur6)"/>
    <ellipse cx="${cx + erx * 0.1}" cy="${ey + 2}" rx="20" ry="13" fill="#3a1a08" stroke="#8a4a0c" stroke-width="3"/>
    <ellipse cx="${cx + erx * 0.1}" cy="${ey + 6}" rx="13" ry="6" fill="#ff9a1a" opacity="0.8"/>
    <circle cx="${cx + erx * 0.1 - 5}" cy="${ey}" r="2.6" fill="#fff6c8"/><circle cx="${cx + erx * 0.1 + 6}" cy="${ey + 1}" r="2.6" fill="#fff6c8"/>`;
  // the long drip from the tip, stretching down
  const [by, brx] = bands[n - 1];
  const tipY = by + 24;
  const tip = `
    <path d="M ${cx - brx * 0.55} ${by + 8} Q ${cx} ${tipY + 16} ${cx + brx * 0.55} ${by + 8} Q ${cx} ${by + 30} ${cx - brx * 0.55} ${by + 8} Z" fill="url(#bhHoney)"/>
    <path d="M ${cx - 9} ${tipY + 4} Q ${cx - 2} ${tipY + 20} ${cx - 5} ${tipY + 52} A 7.5 7.5 0 0 0 ${cx + 9} ${tipY + 54} Q ${cx + 4} ${tipY + 20} ${cx + 11} ${tipY + 4} Z" fill="url(#bhHoney)" stroke="#a8600c" stroke-width="1.5"/>
    <path d="M ${cx - 3} ${tipY + 14} Q ${cx - 1} ${tipY + 30} ${cx - 2} ${tipY + 48}" stroke="#fff" stroke-width="2.4" stroke-linecap="round" opacity="0.75"/>`;
  return { svg: `
    <ellipse cx="${cx}" cy="${top + 100}" rx="170" ry="140" fill="#ffc93c" opacity="0.3" filter="url(#bhBlur40)"/>
    <path d="M ${cx - 20} ${top - 8} Q ${cx} ${top + 24} ${cx + 20} ${top - 8} Z" fill="#7a3a0c"/>
    ${body}${drips}${ent}${tip}`, tipX: cx + 2, tipY: tipY + 54 };
}

// A leafy bush clump: overlapping circles.
function bush(cx, cy, s, col, R) {
  let out = "";
  const blobs = [[-1.1, 0.2, 0.7], [-0.55, -0.35, 0.85], [0.1, -0.55, 0.95], [0.75, -0.3, 0.8], [1.2, 0.2, 0.65], [0, 0.15, 1]];
  for (const [a, b, k] of blobs) out += `<circle cx="${f(cx + a * s)}" cy="${f(cy + b * s)}" r="${f(k * s * 0.7)}" fill="${shade(col, -0.25)}" stroke="#0a1a14" stroke-width="2.5"/>`;
  for (const [a, b, k] of blobs) out += `<circle cx="${f(cx + a * s - k * s * 0.12)}" cy="${f(cy + b * s - k * s * 0.18)}" r="${f(k * s * 0.5)}" fill="${col}" opacity="0.55"/>`;
  for (let k = 0; k < 10; k++) {
    const x = cx + (R() - 0.5) * s * 2.4, y = cy + (R() - 0.7) * s * 1.1;
    out += `<path d="M ${f(x)} ${f(y)} q 6 -8 12 -2 q -6 6 -12 2 Z" fill="${shade(col, 0.35)}" opacity="0.7"/>`;
  }
  return out;
}

// A glowing mushroom.
const shroom = (x, y, s, col) => `
  <ellipse cx="${x}" cy="${y - s * 1.1}" rx="${s * 1.6}" ry="${s * 1.1}" fill="${col}" opacity="0.4" filter="url(#bhBlur6)"/>
  <path d="M ${x - s * 0.22} ${y} L ${x - s * 0.16} ${y - s} L ${x + s * 0.16} ${y - s} L ${x + s * 0.22} ${y} Z" fill="#e8e0f0" stroke="#3a2a4a" stroke-width="1.5"/>
  <path d="M ${x - s} ${y - s * 0.95} Q ${x} ${y - s * 1.9} ${x + s} ${y - s * 0.95} Z" fill="${col}" stroke="${shade(col, -0.5)}" stroke-width="1.5"/>
  <circle cx="${x - s * 0.35}" cy="${y - s * 1.28}" r="${s * 0.13}" fill="#fff" opacity="0.8"/><circle cx="${x + s * 0.3}" cy="${y - s * 1.15}" r="${s * 0.1}" fill="#fff" opacity="0.8"/>`;

export default function () {
  const R = rng(57);

  // Stars through the canopy.
  let stars = "";
  for (let k = 0; k < 50; k++) {
    const x = R() * W, y = R() * 160, s = R();
    stars += `<circle cx="${f(x)}" cy="${f(y)}" r="${(0.5 + s * 1.3).toFixed(2)}" fill="#e6f0ff" opacity="${(0.2 + s * 0.6).toFixed(2)}"/>`;
  }
  // Far tree trunks (two layers).
  let far = "", mid = "";
  for (let k = 0; k < 11; k++) {
    const x = -20 + k * 72 + R() * 30, w = 16 + R() * 14;
    far += `<path d="M ${f(x)} 440 L ${f(x + w * 0.2)} 40 L ${f(x + w * 0.8)} 40 L ${f(x + w)} 440 Z" fill="#132a3a" opacity="0.9"/>`;
    far += `<ellipse cx="${f(x + w / 2)}" cy="${f(40 + R() * 40)}" rx="${f(50 + R() * 30)}" ry="${f(36 + R() * 16)}" fill="#11243a"/>`;
  }
  for (const [x, w] of [[40, 40], [148, 30], [560, 34], [660, 46]]) {
    mid += `<path d="M ${x} 440 Q ${x + 6} 200 ${x + w * 0.3} 0 L ${x + w * 0.9} 0 Q ${x + w - 4} 200 ${x + w + 8} 440 Z" fill="#0e1e2c" stroke="#2a5a4a" stroke-width="2"/>
      <path d="M ${x + w * 0.85} 0 Q ${x + w - 6} 200 ${x + w + 6} 440" fill="none" stroke="#5fd068" stroke-width="2" opacity="0.25"/>`;
  }
  // Fireflies.
  let flies = "";
  for (let k = 0; k < 30; k++) {
    const x = R() * W, y = 60 + R() * 330, r = 1.2 + R() * 2;
    const c = R() < 0.6 ? "#d8ff7a" : "#ffe08a";
    flies += `<circle cx="${f(x)}" cy="${f(y)}" r="${f(r * 3)}" fill="${c}" opacity="0.25" filter="url(#bhBlur3)"/><circle cx="${f(x)}" cy="${f(y)}" r="${f(r)}" fill="${c}" opacity="${(0.6 + R() * 0.4).toFixed(2)}"/>`;
  }
  // The glowing branch across the top with moss and leaves.
  const branchD = "M -20 64 Q 120 40 250 58 Q 330 70 420 52 Q 540 30 740 60";
  let leaves = "";
  for (let k = 0; k < 22; k++) {
    const x = R() * 720, y = 46 + Math.sin(x / 90) * 8 + R() * 10;
    const rot = (R() - 0.5) * 120 + (R() < 0.5 ? 0 : 180);
    leaves += `<path d="M ${f(x)} ${f(y)} q 10 -14 26 -8 q -10 14 -26 8 Z" fill="${R() < 0.5 ? "#5fd068" : "#3fae6a"}" stroke="#14381e" stroke-width="1.5" transform="rotate(${f(rot)} ${f(x)} ${f(y)})"/>`;
  }
  let moss = "";
  for (let k = 0; k < 26; k++) {
    const x = R() * 720, y = 52 + Math.sin(x / 110) * 6 - 6;
    moss += `<circle cx="${f(x)}" cy="${f(y)}" r="${f(2 + R() * 3)}" fill="#b6ff8a" opacity="${(0.6 + R() * 0.4).toFixed(2)}"/>`;
  }
  // hanging glowing vines from the branch
  let vines = "";
  for (const [x, len] of [[90, 120], [150, 70], [580, 100], [640, 140]]) {
    vines += `<path d="M ${x} 58 Q ${x + 8} ${58 + len / 2} ${x - 4} ${58 + len}" fill="none" stroke="#2f7a3a" stroke-width="3"/>`;
    for (let j = 1; j < 5; j++) vines += `<circle cx="${f(x + 2 + Math.sin(j) * 4)}" cy="${f(58 + (len * j) / 5)}" r="3" fill="#b6ff8a" opacity="0.85"/><circle cx="${f(x + 2 + Math.sin(j) * 4)}" cy="${f(58 + (len * j) / 5)}" r="7" fill="#b6ff8a" opacity="0.25" filter="url(#bhBlur3)"/>`;
  }

  const hv = hive(360, 58);

  // Falling honey drops between tip and pool.
  const poolY = 384;
  const falling = drop(hv.tipX, 316, 7) + drop(hv.tipX, 350, 5);

  // Honey pool + splash ripples.
  const pool = `
    <ellipse cx="360" cy="${poolY}" rx="220" ry="58" fill="#ffc93c" opacity="0.35" filter="url(#bhBlur40)"/>
    <ellipse cx="360" cy="${poolY + 4}" rx="164" ry="36" fill="#3a1e08"/>
    <ellipse cx="360" cy="${poolY}" rx="156" ry="31" fill="url(#bhPool)"/>
    <ellipse cx="${hv.tipX}" cy="${poolY - 4}" rx="34" ry="8" fill="none" stroke="#fff3b0" stroke-width="2.5" opacity="0.8"/>
    <ellipse cx="${hv.tipX}" cy="${poolY - 4}" rx="62" ry="14" fill="none" stroke="#fff3b0" stroke-width="2" opacity="0.45"/>
    <ellipse cx="${hv.tipX}" cy="${poolY - 4}" rx="94" ry="20" fill="none" stroke="#fff3b0" stroke-width="1.5" opacity="0.25"/>
    <path d="M ${hv.tipX - 10} ${poolY - 6} q -4 -14 -1 -20 q 4 10 5 20 Z M ${hv.tipX + 6} ${poolY - 6} q 4 -12 10 -14 q -4 8 -4 14 Z" fill="#ffd23f"/>
    <ellipse cx="300" cy="${poolY - 12}" rx="60" ry="6" fill="#fff" opacity="0.25"/>`;

  // Peeking critter in the bush (bottom left), only the top shows.
  const px = 146, py = 318, pr = 32;
  const peeker = `
    <g>
      <path d="M ${px - 2} ${py - pr * 0.95} Q ${px + 3} ${py - pr * 1.3} ${px - 1} ${py - pr * 1.45}" fill="none" stroke="#2f7a3a" stroke-width="4" stroke-linecap="round"/>
      <path d="M ${px - 1} ${py - pr * 1.4} Q ${px - 18} ${py - pr * 1.65} ${px - 24} ${py - pr * 1.3} Q ${px - 12} ${py - pr * 1.2} ${px - 1} ${py - pr * 1.4} Z" fill="#7ee08a" stroke="#1e5a2a" stroke-width="2"/>
      <path d="M ${px} ${py - pr * 1.36} Q ${px + 16} ${py - pr * 1.6} ${px + 22} ${py - pr * 1.25} Q ${px + 10} ${py - pr * 1.16} ${px} ${py - pr * 1.36} Z" fill="${NAT}" stroke="#1e5a2a" stroke-width="2"/>
      ${ball(px, py, pr, NAT, { glow: false })}
      <ellipse cx="${px + pr * 0.4}" cy="${py - pr * 0.1}" rx="${pr * 0.7}" ry="${pr * 0.8}" fill="#ffc93c" opacity="0.22" filter="url(#bhBlur6)"/>
      ${eye(px - pr * 0.3, py - pr * 0.3, pr * 0.22, pr * 0.28, 0.75, -0.25, pr * 0.13)}
      ${eye(px + pr * 0.36, py - pr * 0.3, pr * 0.22, pr * 0.28, 0.75, -0.25, pr * 0.13)}
    </g>`;

  // Grass tufts.
  let grass = "";
  for (let k = 0; k < 40; k++) {
    const x = R() * W, y = 405 + R() * 40, h = 12 + R() * 22, d = (R() - 0.5) * 14;
    grass += `<path d="M ${f(x - 3)} ${f(y)} Q ${f(x + d * 0.4)} ${f(y - h * 0.6)} ${f(x + d)} ${f(y - h)} Q ${f(x + d * 0.2 + 2)} ${f(y - h * 0.5)} ${f(x + 3)} ${f(y)} Z" fill="${R() < 0.5 ? "#1e4a2a" : "#2a6a36"}"/>`;
  }

  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">
  <defs>
    <linearGradient id="bhSky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#0D0F26"/><stop offset="0.5" stop-color="#0f1e36"/><stop offset="1" stop-color="#12302e"/>
    </linearGradient>
    <radialGradient id="bhHive" cx="0.4" cy="0.25" r="0.8">
      <stop offset="0" stop-color="#fff0a0"/><stop offset="0.45" stop-color="#ffc93c"/><stop offset="1" stop-color="#d0801a"/>
    </radialGradient>
    <linearGradient id="bhHiveSide" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#5fd068" stop-opacity="0.25"/><stop offset="0.25" stop-color="#5fd068" stop-opacity="0"/><stop offset="0.7" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#3a1a08" stop-opacity="0.45"/>
    </linearGradient>
    <linearGradient id="bhHoney" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#fff0a0"/><stop offset="0.5" stop-color="#ffb21a"/><stop offset="1" stop-color="#e07a0a"/>
    </linearGradient>
    <radialGradient id="bhPool" cx="0.5" cy="0.4" r="0.6">
      <stop offset="0" stop-color="#fff3b0"/><stop offset="0.4" stop-color="#ffc93c"/><stop offset="0.8" stop-color="#e88a12"/><stop offset="1" stop-color="#a8500a"/>
    </radialGradient>
    <radialGradient id="bhWing" cx="0.4" cy="0.35" r="0.7">
      <stop offset="0" stop-color="#ffffff" stop-opacity="0.85"/><stop offset="1" stop-color="#bfe8ff" stop-opacity="0.3"/>
    </radialGradient>
    <linearGradient id="bhBranch" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#6a4a3a"/><stop offset="1" stop-color="#2a1a1a"/>
    </linearGradient>
    <linearGradient id="bhGround" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#173a2e"/><stop offset="1" stop-color="#0a1418"/>
    </linearGradient>
    <radialGradient id="bhVig" cx="50%" cy="48%" r="72%">
      <stop offset="0.6" stop-color="#05061a" stop-opacity="0"/><stop offset="1" stop-color="#05061a" stop-opacity="0.65"/>
    </radialGradient>
    <filter id="bhBlur3" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="3"/></filter>
    <filter id="bhBlur6" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="6"/></filter>
    <filter id="bhBlur18" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="18"/></filter>
    <filter id="bhBlur40" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="40"/></filter>
  </defs>

  <rect width="${W}" height="${H}" fill="url(#bhSky)"/>
  ${stars}
  <circle cx="610" cy="120" r="70" fill="#bfe8ff" opacity="0.18" filter="url(#bhBlur18)"/>
  <circle cx="610" cy="120" r="22" fill="#eef6ff" opacity="0.9"/>
  ${far}
  <rect x="0" y="230" width="${W}" height="210" fill="#12302e" opacity="0.5" filter="url(#bhBlur18)"/>
  ${mid}

  <!-- ground -->
  <path d="M 0 330 Q 180 314 360 326 Q 540 312 720 330 L 720 440 L 0 440 Z" fill="url(#bhGround)"/>
  <path d="M 0 330 Q 180 314 360 326 Q 540 312 720 330" fill="none" stroke="#5fd068" stroke-width="2" opacity="0.3"/>

  ${pool}

  <!-- branch -->
  <path d="${branchD}" fill="none" stroke="#b6ff8a" stroke-width="40" opacity="0.25" filter="url(#bhBlur18)"/>
  <path d="${branchD}" fill="none" stroke="#1a0e10" stroke-width="28" stroke-linecap="round"/>
  <path d="${branchD}" fill="none" stroke="url(#bhBranch)" stroke-width="22" stroke-linecap="round"/>
  <path d="M -20 56 Q 120 32 250 50 Q 330 62 420 44 Q 540 22 740 52" fill="none" stroke="#b6ff8a" stroke-width="4" stroke-linecap="round" opacity="0.8"/>
  <path d="M 520 44 Q 560 10 610 0" fill="none" stroke="#1a0e10" stroke-width="14" stroke-linecap="round"/>
  <path d="M 520 42 Q 560 8 610 -2" fill="none" stroke="#5a3a2e" stroke-width="9" stroke-linecap="round"/>
  ${moss}${vines}${leaves}

  <!-- the hive -->
  ${hv.svg}
  ${falling}

  <!-- bees -->
  ${buzz(176, 164, -1)}${bee(220, 160, 24, { look: [0.6, 0.2], flip: 1, tilt: -6 })}
  ${buzz(560, 132, 1)}${bee(512, 136, 22, { look: [-0.6, 0.1], flip: -1, tilt: 8, mood: "o" })}
  ${buzz(600, 262, 1)}${bee(552, 262, 19, { look: [-0.7, -0.3], flip: -1, tilt: -4 })}
  ${buzz(228, 288, -1)}${bee(262, 270, 16, { look: [0.5, -0.4], flip: 1, tilt: 10 })}

  <!-- bushes, peeking critter, mushrooms -->
  ${bush(612, 370, 52, "#2f7a3a", R)}
  ${shroom(560, 392, 13, "#8fe6ff")}${shroom(582, 398, 9, "#8fe6ff")}
  ${peeker}
  ${bush(128, 396, 50, "#2f7a3a", R)}
  ${shroom(218, 402, 11, "#ff7ac8")}
  ${grass}
  ${flies}
  ${twinkle(300, 210, 8, "#fff6c8", 0.9)}${twinkle(430, 120, 7, "#fff6c8", 0.8)}${twinkle(410, 360, 6, "#fff", 0.8)}
  <rect width="${W}" height="${H}" fill="url(#bhVig)"/>
</svg>`;
}

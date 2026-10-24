// Frozen vault: a block of glacier ice on a snow drift, with a glowing
// diamond boon badge frozen inside. Icicles, snowfall, an aurora, and a small
// Frost critter peeking at the prize. Frost family.
import { ball, eye, shade } from "../../brand/parts.mjs";

const W = 720, H = 440;
const FROST = "#BFEFFF";

const twinkle = (x, y, s, col = "#fff", o = 1) =>
  `<path d="M ${x} ${y - s} Q ${x} ${y} ${x + s} ${y} Q ${x} ${y} ${x} ${y + s} Q ${x} ${y} ${x - s} ${y} Q ${x} ${y} ${x} ${y - s} Z" fill="${col}" opacity="${o}"/>`;

// Hanging icicle from (x, y), length l, width w.
const icicle = (x, y, l, w) => `
  <path d="M ${x - w / 2} ${y} Q ${x - w * 0.15} ${y + l * 0.6} ${x} ${y + l} Q ${x + w * 0.15} ${y + l * 0.6} ${x + w / 2} ${y} Z" fill="url(#fvIcicle)" stroke="#e8fbff" stroke-width="1.2" stroke-opacity="0.7"/>
  <path d="M ${x - w * 0.18} ${y + 2} Q ${x - w * 0.08} ${y + l * 0.45} ${x - 1} ${y + l * 0.8}" fill="none" stroke="#fff" stroke-width="${Math.max(1.2, w * 0.12)}" stroke-linecap="round" opacity="0.8"/>`;

// The boon badge: a rounded diamond with a gold rim, gem face and star.
function badge(cx, cy, s) {
  const d = (k) => `M ${cx} ${cy - s * k} Q ${cx + s * k * 0.08} ${cy - s * k * 0.92} ${cx + s * k} ${cy} Q ${cx + s * k * 0.08} ${cy + s * k * 0.92} ${cx} ${cy + s * k} Q ${cx - s * k * 0.08} ${cy + s * k * 0.92} ${cx - s * k} ${cy} Q ${cx - s * k * 0.08} ${cy - s * k * 0.92} ${cx} ${cy - s * k} Z`;
  let star = "";
  for (let k = 0; k < 10; k++) {
    const a = -Math.PI / 2 + (k * Math.PI) / 5;
    const rr = k % 2 ? s * 0.17 : s * 0.4;
    star += `${k ? "L" : "M"} ${cx + Math.cos(a) * rr} ${cy + Math.sin(a) * rr} `;
  }
  return `
  <path d="${d(1)}" fill="url(#fvGold)" stroke="#8a5a10" stroke-width="3"/>
  <path d="${d(0.8)}" fill="url(#fvGem)" stroke="#fff1b0" stroke-width="2"/>
  <path d="M ${cx} ${cy - s * 0.8} L ${cx + s * 0.8} ${cy} L ${cx} ${cy} Z" fill="#fff" opacity="0.18"/>
  <path d="M ${cx - s * 0.8} ${cy} L ${cx} ${cy + s * 0.8} L ${cx} ${cy} Z" fill="#000" opacity="0.15"/>
  <path d="${star}Z" fill="#fff8d0" stroke="#ffd23f" stroke-width="2" stroke-linejoin="round"/>
  <circle cx="${cx}" cy="${cy - s}" r="${s * 0.08}" fill="#fff6c8"/><circle cx="${cx + s}" cy="${cy}" r="${s * 0.08}" fill="#fff6c8"/>
  <circle cx="${cx}" cy="${cy + s}" r="${s * 0.08}" fill="#fff6c8"/><circle cx="${cx - s}" cy="${cy}" r="${s * 0.08}" fill="#fff6c8"/>`;
}

export default function () {
  let seed = 11;
  const rnd = () => ((seed = (seed * 16807) % 2147483647) / 2147483647);
  let stars = "";
  for (let k = 0; k < 60; k++) {
    const x = rnd() * W, y = rnd() * 180, s = rnd();
    stars += `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="${(0.6 + s * 1.3).toFixed(2)}" fill="#e6f4ff" opacity="${(0.25 + s * 0.55).toFixed(2)}"/>`;
  }
  let snow = "";
  for (let k = 0; k < 70; k++) {
    const x = 20 + rnd() * (W - 40), y = 20 + rnd() * 360, s = rnd();
    snow += `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="${(1 + s * 2.6).toFixed(2)}" fill="#ffffff" opacity="${(0.3 + s * 0.6).toFixed(2)}"/>`;
  }
  // Frost bubbles trapped in the ice.
  let trapped = "";
  for (let k = 0; k < 22; k++) {
    const x = 262 + rnd() * 190, y = 160 + rnd() * 160, r = 1.5 + rnd() * 4;
    trapped += `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="${r.toFixed(1)}" fill="#ffffff" opacity="${(0.25 + rnd() * 0.4).toFixed(2)}"/>`;
  }

  // Ice block geometry (front face + top + right side, slight 3/4 view).
  const fx = 248, fy = 150, fw = 214, fh = 190, dx = 40, dy = -30;
  const front = `M ${fx + 14} ${fy} L ${fx + fw - 10} ${fy + 4} Q ${fx + fw} ${fy + 6} ${fx + fw} ${fy + 18} L ${fx + fw - 4} ${fy + fh - 12} Q ${fx + fw - 6} ${fy + fh} ${fx + fw - 18} ${fy + fh} L ${fx + 12} ${fy + fh - 4} Q ${fx} ${fy + fh - 6} ${fx + 2} ${fy + fh - 18} L ${fx} ${fy + 14} Q ${fx + 2} ${fy} ${fx + 14} ${fy} Z`;
  const top = `M ${fx + 14} ${fy} L ${fx + 14 + dx} ${fy + dy} L ${fx + fw - 6 + dx} ${fy + dy + 6} L ${fx + fw - 10} ${fy + 4} Z`;
  const side = `M ${fx + fw - 10} ${fy + 4} L ${fx + fw - 6 + dx} ${fy + dy + 6} L ${fx + fw - 6 + dx} ${fy + fh + dy} L ${fx + fw - 18} ${fy + fh} Q ${fx + fw - 6} ${fy + fh} ${fx + fw - 4} ${fy + fh - 12} L ${fx + fw} ${fy + 18} Z`;
  const bx = fx + fw / 2 + 6, by = fy + fh / 2 + 2;

  // Icicles along the front top edge and the side.
  const icicles = [
    [fx + 22, fy + 2, 34, 12], [fx + 44, fy + 3, 22, 9], [fx + 70, fy + 3, 46, 14], [fx + 98, fy + 4, 26, 10],
    [fx + 128, fy + 4, 38, 13], [fx + 156, fy + 5, 20, 8], [fx + 182, fy + 5, 42, 13], [fx + 204, fy + 6, 24, 9],
  ].map(([x, y, l, w]) => icicle(x, y, l, w)).join("");

  // Little Frost critter peeking from the drift at the left.
  const kx = 150, ky = 338, kr = 38;
  const critter = `
    ${ball(kx, ky, kr, FROST, { glow: true })}
    <path d="M ${kx - kr * 0.55} ${ky - kr * 0.75} L ${kx - kr * 0.4} ${ky - kr * 1.25} L ${kx - kr * 0.18} ${ky - kr * 0.88} L ${kx} ${ky - kr * 1.4} L ${kx + kr * 0.2} ${ky - kr * 0.88} L ${kx + kr * 0.42} ${ky - kr * 1.25} L ${kx + kr * 0.55} ${ky - kr * 0.75} Z" fill="#e9fbff" stroke="#6fb8d6" stroke-width="2.5" stroke-linejoin="round"/>
    ${eye(kx - kr * 0.3, ky - kr * 0.15, kr * 0.22, kr * 0.28, 0.85, -0.35, kr * 0.13)}
    ${eye(kx + kr * 0.32, ky - kr * 0.15, kr * 0.22, kr * 0.28, 0.85, -0.35, kr * 0.13)}
    <ellipse cx="${kx + kr * 0.05}" cy="${ky + kr * 0.4}" rx="${kr * 0.13}" ry="${kr * 0.16}" fill="#14102e"/>
    <circle cx="${kx - kr * 0.62}" cy="${ky + kr * 0.15}" r="${kr * 0.06}" fill="#7fd0ee"/><circle cx="${kx - kr * 0.5}" cy="${ky + kr * 0.3}" r="${kr * 0.05}" fill="#7fd0ee"/>
    <circle cx="${kx + kr * 0.62}" cy="${ky + kr * 0.15}" r="${kr * 0.06}" fill="#7fd0ee"/>`;

  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">
  <defs>
    <linearGradient id="fvSky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#0D0F26"/><stop offset="0.55" stop-color="#141038"/><stop offset="1" stop-color="#1f2a6a"/>
    </linearGradient>
    <linearGradient id="fvAurora" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#5CFFD8" stop-opacity="0"/><stop offset="0.3" stop-color="#5CFFD8" stop-opacity="0.7"/>
      <stop offset="0.65" stop-color="#8fb8ff" stop-opacity="0.6"/><stop offset="1" stop-color="#C9A6FF" stop-opacity="0"/>
    </linearGradient>
    <linearGradient id="fvCliff" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#4a6bb8"/><stop offset="1" stop-color="#1c2258"/>
    </linearGradient>
    <linearGradient id="fvCliffFar" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#2e3f88"/><stop offset="1" stop-color="#171a4a"/>
    </linearGradient>
    <linearGradient id="fvSnow" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#d6e6ff"/><stop offset="0.45" stop-color="#8aa6dc"/><stop offset="1" stop-color="#34418a"/>
    </linearGradient>
    <linearGradient id="fvSnowFar" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#7f97d0"/><stop offset="1" stop-color="#26306e"/>
    </linearGradient>
    <linearGradient id="fvFront" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#e6fbff" stop-opacity="0.55"/><stop offset="0.35" stop-color="#9fe3ff" stop-opacity="0.2"/>
      <stop offset="0.7" stop-color="#5aa8ea" stop-opacity="0.25"/><stop offset="1" stop-color="#3a6cc8" stop-opacity="0.65"/>
    </linearGradient>
    <linearGradient id="fvTop" x1="0" y1="1" x2="0" y2="0">
      <stop offset="0" stop-color="#e9fbff" stop-opacity="0.9"/><stop offset="1" stop-color="#b6e8ff" stop-opacity="0.8"/>
    </linearGradient>
    <linearGradient id="fvSide" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#4f8fdc" stop-opacity="0.75"/><stop offset="1" stop-color="#2b4fa8" stop-opacity="0.85"/>
    </linearGradient>
    <linearGradient id="fvCore" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#2a5fb8"/><stop offset="1" stop-color="#1a2f78"/>
    </linearGradient>
    <linearGradient id="fvIcicle" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#e9fbff" stop-opacity="0.95"/><stop offset="1" stop-color="#8fd8ff" stop-opacity="0.75"/>
    </linearGradient>
    <linearGradient id="fvGold" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#fff1b0"/><stop offset="0.45" stop-color="#ffd23f"/><stop offset="1" stop-color="#c98a14"/>
    </linearGradient>
    <radialGradient id="fvGem" cx="0.4" cy="0.35" r="0.8">
      <stop offset="0" stop-color="#e4d4ff"/><stop offset="0.5" stop-color="#9b7bff"/><stop offset="1" stop-color="#4b2fb0"/>
    </radialGradient>
    <radialGradient id="fvHalo" cx="0.5" cy="0.5" r="0.5">
      <stop offset="0" stop-color="#fff6c8" stop-opacity="0.95"/><stop offset="0.35" stop-color="#9fe8ff" stop-opacity="0.6"/><stop offset="1" stop-color="#3EA8FF" stop-opacity="0"/>
    </radialGradient>
    <filter id="fvBlur3" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="3"/></filter>
    <filter id="fvBlur8" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="8"/></filter>
    <filter id="fvBlur24" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="24"/></filter>
    <filter id="fvBlur50" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="50"/></filter>
    <linearGradient id="fvVignette" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0.65" stop-color="#0D0F26" stop-opacity="0"/><stop offset="1" stop-color="#0D0F26" stop-opacity="0.4"/>
    </linearGradient>
    <radialGradient id="fvSide2" cx="0.5" cy="0.5" r="0.5">
      <stop offset="0.6" stop-color="#0D0F26" stop-opacity="0"/><stop offset="1" stop-color="#0D0F26" stop-opacity="0.35"/>
    </radialGradient>
    <clipPath id="fvFrontClip"><path d="${front}"/></clipPath>
  </defs>

  <!-- sky + aurora -->
  <rect width="${W}" height="${H}" fill="url(#fvSky)"/>
  ${stars}
  <path d="M -20 110 C 120 40 240 120 380 70 C 500 30 600 90 740 50 L 740 90 C 600 130 500 70 380 112 C 240 160 120 80 -20 150 Z" fill="url(#fvAurora)" opacity="0.5" filter="url(#fvBlur8)"/>
  <path d="M -20 80 C 140 30 260 90 400 50 C 520 20 620 60 740 30" fill="none" stroke="url(#fvAurora)" stroke-width="6" opacity="0.6" filter="url(#fvBlur3)"/>

  <!-- far glacier cliffs -->
  <path d="M 0 250 L 0 170 L 40 150 L 70 176 L 110 130 L 150 160 L 190 140 L 230 190 L 230 260 Z" fill="url(#fvCliffFar)"/>
  <path d="M 490 260 L 500 180 L 540 140 L 580 166 L 620 120 L 660 152 L 700 136 L 720 150 L 720 260 Z" fill="url(#fvCliffFar)"/>
  <path d="M 110 130 L 124 148 L 112 146 L 102 142 Z M 620 120 L 634 140 L 620 136 L 608 134 Z" fill="#cfe8ff" opacity="0.7"/>
  <path d="M 0 270 Q 120 236 240 258 Q 360 242 480 256 Q 600 236 720 260 L 720 300 L 0 300 Z" fill="url(#fvSnowFar)"/>

  <!-- cold light pooling around the block -->
  <ellipse cx="${bx + 10}" cy="${by}" rx="250" ry="170" fill="#3EA8FF" opacity="0.32" filter="url(#fvBlur50)"/>
  <ellipse cx="${bx}" cy="${by}" rx="120" ry="110" fill="#bfefff" opacity="0.18" filter="url(#fvBlur24)"/>

  <!-- ground shadow + snow drift (mid) -->
  <ellipse cx="${bx + 20}" cy="${fy + fh + 4}" rx="170" ry="20" fill="#0b0d2a" opacity="0.55" filter="url(#fvBlur8)"/>
  <path d="M 0 440 L 0 320 Q 100 300 200 318 Q 300 330 360 336 Q 470 330 560 312 Q 650 298 720 316 L 720 440 Z" fill="url(#fvSnow)"/>

  <!-- the ice block: back core, the badge frozen inside, then translucent faces -->
  <path d="${side}" fill="url(#fvSide)" stroke="#d8f6ff" stroke-width="2" stroke-linejoin="round"/>
  <path d="${front}" fill="url(#fvCore)"/>
  <g clip-path="url(#fvFrontClip)">
    <circle cx="${bx}" cy="${by}" r="125" fill="url(#fvHalo)"/>
    ${[0, 1, 2, 3, 4, 5, 6, 7].map((k) => {
      const a = (k * Math.PI) / 4 + 0.2;
      return `<path d="M ${bx} ${by} L ${bx + Math.cos(a - 0.08) * 160} ${by + Math.sin(a - 0.08) * 160} L ${bx + Math.cos(a + 0.08) * 160} ${by + Math.sin(a + 0.08) * 160} Z" fill="#e9fbff" opacity="0.22"/>`;
    }).join("")}
    <g transform="rotate(-8 ${bx} ${by})">${badge(bx, by, 62)}</g>
    ${trapped}
    <path d="${front}" fill="url(#fvFront)"/>
    <circle cx="${bx}" cy="${by}" r="70" fill="#fff1b0" opacity="0.35" filter="url(#fvBlur24)"/>
    <g transform="rotate(-8 ${bx} ${by})" opacity="0.7">${badge(bx, by, 62)}</g>
    <!-- cracks and facets -->
    <path d="M ${fx + 10} ${fy + 60} L ${fx + 60} ${fy + 84} L ${fx + 74} ${fy + 130} M ${fx + 60} ${fy + 84} L ${fx + 30} ${fy + 120}" fill="none" stroke="#f2fdff" stroke-width="1.8" opacity="0.7"/>
    <path d="M ${fx + fw - 6} ${fy + 120} L ${fx + fw - 50} ${fy + 140} L ${fx + fw - 64} ${fy + 186}" fill="none" stroke="#f2fdff" stroke-width="1.6" opacity="0.6"/>
    <path d="M ${fx} ${fy} L ${fx + 90} ${fy} L ${fx} ${fy + 110} Z" fill="#ffffff" opacity="0.14"/>
    <path d="M ${fx + 24} ${fy + 22} L ${fx + 70} ${fy + 22} L ${fx + 24} ${fy + 74} Z" fill="#ffffff" opacity="0.18"/>
  </g>
  <path d="${front}" fill="none" stroke="#e9fbff" stroke-width="3" stroke-linejoin="round"/>
  <path d="${top}" fill="url(#fvTop)" stroke="#ffffff" stroke-width="2" stroke-linejoin="round"/>
  <!-- snow cap on top -->
  <path d="M ${fx + 4} ${fy + 4} Q ${fx + 10} ${fy - 14} ${fx + 40} ${fy - 18} Q ${fx + 70} ${fy - 34} ${fx + 110} ${fy - 24} Q ${fx + 150} ${fy - 36} ${fx + 190} ${fy - 20} Q ${fx + fw + 24} ${fy - 24} ${fx + fw + 30} ${fy - 10} Q ${fx + fw + 14} ${fy + 2} ${fx + fw - 4} ${fy + 8} Q ${fx + 150} ${fy + 2} ${fx + 100} ${fy + 8} Q ${fx + 50} ${fy + 2} ${fx + 4} ${fy + 4} Z" fill="url(#fvSnow)" stroke="#ffffff" stroke-width="1.5"/>
  ${icicles}
  ${icicle(fx + fw + 6, fy + 14, 30, 10)}${icicle(fx + fw + 22, fy + 2, 22, 8)}

  <!-- snow piled against the base (front drift) -->
  <path d="M ${fx - 40} ${fy + fh + 12} Q ${fx - 10} ${fy + fh - 22} ${fx + 40} ${fy + fh - 6} Q ${fx + 90} ${fy + fh - 18} ${fx + 120} ${fy + fh + 2} Q ${fx + 170} ${fy + fh - 14} ${fx + fw + 10} ${fy + fh - 4} Q ${fx + fw + 60} ${fy + fh - 20} ${fx + fw + 80} ${fy + fh + 14} Z" fill="url(#fvSnow)"/>
  <path d="M ${fx + 40} ${fy + fh - 6} Q ${fx + 90} ${fy + fh - 18} ${fx + 120} ${fy + fh + 2}" fill="none" stroke="#9fe8ff" stroke-width="2.5" opacity="0.7"/>

  <!-- foreground: critter peeking, snow banks, ice shards -->
  <path d="M 0 440 L 0 360 Q 60 344 120 362 Q 170 372 200 400 Q 230 420 240 440 Z" fill="url(#fvSnow)"/>
  <path d="M 720 440 L 720 350 Q 660 336 600 356 Q 560 370 540 400 Q 520 420 515 440 Z" fill="url(#fvSnow)"/>
  <path d="M 560 380 L 578 318 L 594 384 Z" fill="url(#fvIcicle)" stroke="#e8fbff" stroke-width="1.5"/>
  <path d="M 588 386 L 612 300 L 630 388 Z" fill="url(#fvIcicle)" stroke="#e8fbff" stroke-width="1.5"/>
  <path d="M 620 390 L 640 336 L 652 392 Z" fill="url(#fvIcicle)" stroke="#e8fbff" stroke-width="1.5"/>
  <path d="M 612 300 L 604 344 L 612 382" fill="none" stroke="#fff" stroke-width="2" opacity="0.7"/>
  <ellipse cx="${bx + 10}" cy="${fy + fh + 26}" rx="200" ry="34" fill="#7fe0ff" opacity="0.3" filter="url(#fvBlur24)"/>
  <rect width="${W}" height="${H}" fill="url(#fvVignette)"/>
  <rect width="${W}" height="${H}" fill="url(#fvSide2)"/>
  ${critter}
  ${snow}
  ${twinkle(bx + 66, by - 74, 12, "#fff6c8")}${twinkle(bx - 74, by + 52, 8, "#e9fbff")}${twinkle(fx + fw + 44, fy - 6, 9, "#ffffff", 0.9)}
</svg>`;
}

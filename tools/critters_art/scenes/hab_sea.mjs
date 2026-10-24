// Sea habitat: a moonlit tide-pool cove. Cobalt night, a low moon laying a
// shimmering path across the sea, a rocky arch on the right (dim), coral
// fans and anemones glowing softly, tide pools. Signature light: azure moon
// path + coral-pink bioluminescence. Stage: a flat barnacled coral shelf.
import { blurs, critter, sky, motes, sparkle, shade, rng, f } from "./_p.mjs";
import { W, H, SX, SY, fades, withHero } from "./_hab.mjs";

export const size = [W, H];

function coralFan(x, y, s, col, o = 1) {
  let br = "";
  const R = rng(Math.round(x * 7 + y));
  const grow = (px, py, a, len, d) => {
    if (d > 4) return;
    const nx = px + Math.cos(a) * len, ny = py + Math.sin(a) * len;
    br += `<path d="M ${f(px)} ${f(py)} L ${f(nx)} ${f(ny)}" stroke="${col}" stroke-width="${f((5 - d) * 1.1 * s)}" stroke-linecap="round"/>`;
    grow(nx, ny, a - 0.35 - R() * 0.2, len * 0.7, d + 1);
    grow(nx, ny, a + 0.35 + R() * 0.2, len * 0.7, d + 1);
  };
  grow(x, y, -Math.PI / 2, 22 * s, 0);
  return `<g opacity="${o}"><ellipse cx="${x}" cy="${y - 30 * s}" rx="${40 * s}" ry="${30 * s}" fill="${col}" opacity="0.18" filter="url(#bl12)"/>${br}</g>`;
}

function anemone(x, y, s, col) {
  let t = "";
  for (let k = 0; k < 9; k++) {
    const a = -Math.PI / 2 + (k - 4) * 0.28;
    const ex = x + Math.cos(a) * 18 * s, ey = y + Math.sin(a) * 18 * s;
    t += `<path d="M ${x} ${y} Q ${f(x + Math.cos(a) * 10 * s + 3 * s)} ${f(y + Math.sin(a) * 10 * s)} ${f(ex)} ${f(ey)}" stroke="${col}" stroke-width="${f(3 * s)}" stroke-linecap="round" fill="none"/>
      <circle cx="${f(ex)}" cy="${f(ey)}" r="${f(2 * s)}" fill="${shade(col, 0.5)}"/>`;
  }
  return `<ellipse cx="${x}" cy="${y - 10 * s}" rx="${22 * s}" ry="${16 * s}" fill="${col}" opacity="0.25" filter="url(#bl6)"/>${t}
    <ellipse cx="${x}" cy="${y + 2 * s}" rx="${9 * s}" ry="${5 * s}" fill="${shade(col, -0.4)}"/>`;
}

function blob(cx, cy, rx, ry, seed) {
  const R = rng(seed);
  const pts = Array.from({ length: 18 }, (_, k) => {
    const a = (k / 18) * Math.PI * 2, m = 0.92 + R() * 0.12;
    return [cx + Math.cos(a) * rx * m, cy + Math.sin(a) * ry * m];
  });
  let d = `M ${f((pts[0][0] + pts[17][0]) / 2)} ${f((pts[0][1] + pts[17][1]) / 2)}`;
  pts.forEach((p, k) => { const n = pts[(k + 1) % 18]; d += ` Q ${f(p[0])} ${f(p[1])} ${f((p[0] + n[0]) / 2)} ${f((p[1] + n[1]) / 2)}`; });
  return d + " Z";
}

function rock(d, col = "#16284a", top = "#24406a") {
  return `<path d="${d}" fill="${col}" stroke="#0a1428" stroke-width="2.5" stroke-linejoin="round"/>`;
}

function scene() {
  const R = rng(91);
  const mx = 330, my = 150;
  const moon = `
    <circle cx="${mx}" cy="${my}" r="140" fill="#4a8aff" opacity="0.16" filter="url(#bl40)"/>
    <circle cx="${mx}" cy="${my}" r="60" fill="#bfe0ff" opacity="0.3" filter="url(#bl16)"/>
    <circle cx="${mx}" cy="${my}" r="34" fill="url(#heMoon)"/>
    <circle cx="${mx + 9}" cy="${my - 6}" r="6" fill="#a8c8ee" opacity="0.5"/><circle cx="${mx - 10}" cy="${my + 10}" r="4" fill="#a8c8ee" opacity="0.5"/>`;
  // Sea with horizon and moon-path glints.
  let glints = "";
  for (let k = 0; k < 40; k++) {
    const t = R(), y = 236 + t * 70, w = 4 + t * 26, x = mx + (R() - 0.5) * (30 + t * 160);
    glints += `<rect x="${f(x - w / 2)}" y="${f(y)}" width="${f(w)}" height="${f(1.2 + t * 1.6)}" rx="1" fill="#d6ecff" opacity="${f(0.35 + R() * 0.5)}"/>`;
  }
  let waves = "";
  for (let k = 0; k < 26; k++) {
    const x = R() * 780, y = 240 + R() * 70, w = 10 + R() * 30;
    waves += `<path d="M ${f(x)} ${f(y)} q ${f(w / 2)} -3 ${f(w)} 0" stroke="#5a8ad0" stroke-width="1.2" fill="none" opacity="${f(0.25 + R() * 0.25)}"/>`;
  }
  const sea = `
    <rect x="0" y="232" width="${W}" height="${H - 232}" fill="url(#heSea)"/>
    <rect x="0" y="230" width="${W}" height="4" fill="#9cc8ff" opacity="0.35" filter="url(#bl2)"/>
    <ellipse cx="${mx}" cy="270" rx="70" ry="46" fill="#6aa8ff" opacity="0.22" filter="url(#bl16)"/>
    ${waves}${glints}`;
  // Far headland + rock arch on the right (dim).
  const far = `
    <path d="M 0 234 Q 40 214 90 220 Q 130 206 170 222 L 190 234 Z" fill="#132a50"/>
    <path d="M 440 236 L 470 180 Q 500 150 540 150 L 600 160 Q 650 150 690 170 L 730 236 Z" fill="#12244a"/>
    <path d="M 560 236 Q 566 196 600 192 Q 632 194 640 236 Z" fill="#1e3c6e" opacity="0.8"/>
    <path d="M 640 236 L 660 120 Q 700 90 780 96 L 780 236 Z" fill="#10203f"/>`;
  // Near rocks framing: left boulders, right shoreline rocks (dark, calm).
  const near = `
    ${rock("M -10 460 L -10 290 Q 20 270 50 280 Q 80 290 86 330 Q 96 380 70 460 Z", "#12223f")}
    <path d="M 0 292 Q 30 278 56 286" stroke="#4a7ac0" stroke-width="2" fill="none" opacity="0.5"/>
    ${rock("M 360 460 L 380 380 Q 420 350 470 360 Q 520 372 560 400 L 600 460 Z", "#0f1d38")}
    <path d="M 520 340 Q 560 306 610 318 Q 650 330 664 346 Z" fill="#132648"/>
    <path d="M 530 330 Q 566 310 606 320" stroke="#4a7ac0" stroke-width="1.6" fill="none" opacity="0.45"/>
    <path d="M 514 342 Q 590 350 670 344" stroke="#7aa8e0" stroke-width="1.5" fill="none" opacity="0.4"/>
    <path d="M 680 352 Q 720 300 780 304 L 790 356 Z" fill="#0f1f3c"/>
    <path d="M 674 354 Q 730 360 790 354" stroke="#7aa8e0" stroke-width="1.5" fill="none" opacity="0.35"/>`;
  // Tide pools with reflected glow at the front.
  const pools = `
    <ellipse cx="440" cy="392" rx="44" ry="9" fill="#2a5a9a" opacity="0.8"/>
    <ellipse cx="434" cy="390" rx="22" ry="3" fill="#bfe0ff" opacity="0.4"/>
    <ellipse cx="60" cy="406" rx="30" ry="6" fill="#2a5a9a" opacity="0.7"/>`;
  // Stage: a flat coral/barnacle shelf in shallow water.
  const stage = `
    <ellipse cx="${SX}" cy="${SY}" rx="200" ry="50" fill="#6aa8ff" opacity="0.14" filter="url(#bl24)"/>
    <ellipse cx="${SX}" cy="${SY + 26}" rx="170" ry="16" fill="#9cc8ff" opacity="0.25" filter="url(#bl6)"/>
    <path d="M ${SX - 150} ${SY + 26} Q ${SX} ${SY + 40} ${SX + 150} ${SY + 26}" stroke="#bfe0ff" stroke-width="1.5" fill="none" opacity="0.6"/>
    <path d="${blob(SX, SY + 12, 128, 30, 3)}" fill="#22264e" stroke="#0a1428" stroke-width="3"/>
    <path d="${blob(SX, SY, 124, 24, 7)}" fill="#4a4e86" stroke="#0a1428" stroke-width="3" stroke-linejoin="round"/>
    <path d="${blob(SX - 6, SY - 4, 100, 15, 11)}" fill="#5c62a0"/>
    ${[[-60, -2, 12, "#3a8a8a"], [44, -6, 10, "#8a4a8a"], [-100, 10, 9, "#3a8a8a"], [100, 4, 8, "#8a4a8a"]].map(([dx, dy, r, c]) => `<ellipse cx="${SX + dx}" cy="${SY + dy}" rx="${r}" ry="${r * 0.35}" fill="${c}" opacity="0.7"/>`).join("")}
    ${[[-104, 4, 5], [-92, 12, 4], [-80, 18, 3.5], [96, 6, 5], [86, 14, 4], [108, 12, 3], [-20, 22, 3.5], [30, 22, 4]].map(([dx, dy, r]) => `<circle cx="${SX + dx}" cy="${SY + dy}" r="${r}" fill="#c8c2d8" stroke="#2a2e5a" stroke-width="1.2"/><circle cx="${SX + dx}" cy="${SY + dy - r * 0.2}" r="${r * 0.35}" fill="#2a2e5a"/>`).join("")}
    <path d="M ${SX - 100} ${SY - 10} Q ${SX} ${SY - 26} ${SX + 100} ${SY - 10}" stroke="#bfe0ff" stroke-width="2" fill="none" opacity="0.5"/>
    <ellipse cx="${SX + 4}" cy="${SY - 4}" rx="76" ry="10" fill="#bfe0ff" opacity="0.28" filter="url(#bl8)"/>
    ${[[-40, -2], [16, 4], [60, -4], [-74, 2]].map(([dx, dy]) => `<path d="M ${SX + dx} ${SY + dy} l 4 -2 l 4 2 l -4 2 Z" fill="#ff8aa8" opacity="0.6"/>`).join("")}`;
  // Coral and anemones around the shelf edges (outside reserved circle).
  const coral = `
    ${coralFan(46, 392, 1.3, "#ff7a9a")}
    ${coralFan(352, 374, 1.0, "#ff9a7a")}
    ${coralFan(388, 386, 0.7, "#c070d0")}
    ${anemone(320, 378, 1.0, "#ff8ab8")}
    ${anemone(96, 400, 0.9, "#8ad8ff")}
    ${anemone(500, 384, 0.7, "#ff8ab8")}`;
  // Background sea critters: one in the far shallows, one on the arch rocks.
  const bg = `${critter(560, 314, 9, "#3fa9f5", { acc: "fin", mood: "happy", look: [-0.5, 0], rim: "#bfe0ff", rimSide: -1 })}
    ${critter(120, 238, 6.5, "#3fa9f5", { acc: "fin", mood: "sleepy", rim: "#bfe0ff", rimSide: 1 })}`;
  let spk = "";
  [[290, 250, 4], [372, 262, 3], [330, 290, 5]].forEach(([x, y, r]) => (spk += sparkle(x, y, r, "#e6f4ff", 0.7)));

  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${blurs()}
  <defs>
    <linearGradient id="heSky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0a0f2a"/><stop offset="0.6" stop-color="#16285a"/><stop offset="1" stop-color="#28488a"/></linearGradient>
    <linearGradient id="heSea" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#1f4482"/><stop offset="0.4" stop-color="#163266"/><stop offset="1" stop-color="#0d1a3a"/></linearGradient>
    <radialGradient id="heMoon" cx="0.4" cy="0.38" r="0.7"><stop offset="0" stop-color="#ffffff"/><stop offset="0.7" stop-color="#dcecff"/><stop offset="1" stop-color="#a8c8f0"/></radialGradient>
  </defs>
  <rect width="${W}" height="${H}" fill="url(#heSky)"/>
  ${sky(97, 70, 0, 0, 780, 220)}
  ${moon}${far}${sea}${bg}${near}${pools}${stage}${coral}${spk}
  ${motes(29, 22, 0, 200, 780, 420, ["#8ad8ff", "#ff9ab8", "#d6ecff"])}
  ${fades("he", { right: 0.42 })}
  </svg>`;
}

export const many = {
  hab_sea: scene,
  hab_sea_ctx: withHero(scene, "#3fa9f5", "fin", "#bfe0ff"),
};
export default scene;

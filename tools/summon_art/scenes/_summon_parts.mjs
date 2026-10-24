// Shared pieces for the Summon screen paintings: the carved stone portal (the
// in-game _Portal: stone ring, 9 family gems, plinth, soft vortex), twig nests
// and a moonlit stone hall. Matte stone and shells; light comes from the vortex
// and a few lanterns, never neon outlines.
import { shade, rng, f } from "./_p.mjs";
import { FAMILY_INK } from "./_eggs.mjs";

let uid = 0;
const nid = (p) => `${p}${uid++}`;
const FAMS = ["nature", "sea", "tech", "sweet", "frost", "toybox", "spooky", "fire", "cosmic"];

// The portal ring centred at (cx, cy), outer radius r. glow scales the vortex light.
export function portal(cx, cy, r, { glow = 1, plinth = true } = {}) {
  const g = nid("pt");
  const ri = r * 0.74; // inner opening
  // Vortex: layered soft spiral arms.
  let arms = "";
  for (let k = 0; k < 4; k++) {
    const a0 = (k * Math.PI) / 2;
    let d = "";
    for (let i = 0; i <= 28; i++) {
      const t = i / 28, a = a0 + t * 3.4, rr = ri * (0.08 + t * 0.92);
      d += `${i ? "L" : "M"} ${f(cx + Math.cos(a) * rr)} ${f(cy + Math.sin(a) * rr * 0.98)} `;
    }
    arms += `<path d="${d}" fill="none" stroke="#cbb8ff" stroke-width="${f(r * 0.07)}" stroke-linecap="round" opacity="0.22" filter="url(#bl4)"/>
      <path d="${d}" fill="none" stroke="#e6dcff" stroke-width="${f(r * 0.022)}" stroke-linecap="round" opacity="0.45"/>`;
  }
  const R = rng(31);
  let specks = "";
  for (let k = 0; k < 18; k++) {
    const a = R() * Math.PI * 2, rr = ri * (0.2 + R() * 0.75);
    specks += `<circle cx="${f(cx + Math.cos(a) * rr)}" cy="${f(cy + Math.sin(a) * rr)}" r="${f(0.8 + R() * 1.6)}" fill="#f2ecff" opacity="${f(0.3 + R() * 0.6)}"/>`;
  }
  // Stone blocks around the ring.
  let blocks = "";
  const nb = 18;
  for (let k = 0; k < nb; k++) {
    const a0 = (k / nb) * Math.PI * 2 + 0.02, a1 = ((k + 1) / nb) * Math.PI * 2 - 0.02;
    const p = (a, rr) => `${f(cx + Math.cos(a) * rr)} ${f(cy + Math.sin(a) * rr)}`;
    const lit = Math.sin((a0 + a1) / 2) < 0 ? 0.08 : -0.12; // top lit by moon
    const left = Math.cos((a0 + a1) / 2) < 0 ? 0.04 : -0.02;
    blocks += `<path d="M ${p(a0, ri)} L ${p(a0, r)} A ${r} ${r} 0 0 1 ${p(a1, r)} L ${p(a1, ri)} A ${ri} ${ri} 0 0 0 ${p(a0, ri)} Z" fill="${shade("#4a4466", lit + left)}" stroke="#221d38" stroke-width="${f(r * 0.018)}"/>`;
  }
  // Inner bevel lit by the vortex.
  const bevel = `<circle cx="${cx}" cy="${cy}" r="${f(ri + r * 0.02)}" fill="none" stroke="#b9a6ff" stroke-width="${f(r * 0.03)}" opacity="${0.45 * glow}"/>`;
  // Family gems set into the ring: one per family, keystone on top.
  let gems = "";
  FAMS.forEach((fam, k) => {
    const a = -Math.PI / 2 + ((k + 0.5) / 9) * Math.PI * 2;
    const gx = cx + Math.cos(a) * (ri + r) / 2, gy = cy + Math.sin(a) * (ri + r) / 2, s = r * 0.075;
    const col = FAMILY_INK[fam];
    gems += `<circle cx="${f(gx)}" cy="${f(gy)}" r="${f(s * 2.2)}" fill="${col}" opacity="${0.18 * glow}" filter="url(#bl6)"/>
      <path d="M ${f(gx)} ${f(gy - s * 1.3)} L ${f(gx + s)} ${f(gy)} L ${f(gx)} ${f(gy + s * 1.3)} L ${f(gx - s)} ${f(gy)} Z" fill="${shade(col, -0.25)}" stroke="#1c1830" stroke-width="${f(s * 0.3)}" stroke-linejoin="round"/>
      <path d="M ${f(gx)} ${f(gy - s * 1.3)} L ${f(gx + s)} ${f(gy)} L ${f(gx)} ${f(gy)} Z" fill="${shade(col, 0.15)}"/>
      <circle cx="${f(gx - s * 0.25)}" cy="${f(gy - s * 0.45)}" r="${f(s * 0.22)}" fill="#fff" opacity="0.7"/>`;
  });
  const key = `<path d="M ${f(cx - r * 0.13)} ${f(cy - r * 1.04)} L ${f(cx + r * 0.13)} ${f(cy - r * 1.04)} L ${f(cx + r * 0.1)} ${f(cy - r * 0.8)} L ${f(cx - r * 0.1)} ${f(cy - r * 0.8)} Z" fill="#5a5478" stroke="#221d38" stroke-width="${f(r * 0.018)}"/>
    <circle cx="${cx}" cy="${f(cy - r * 0.92)}" r="${f(r * 0.045)}" fill="#ffc23d" opacity="0.9"/>`;
  const pl = plinth
    ? `<ellipse cx="${cx}" cy="${f(cy + r * 1.12)}" rx="${f(r * 1.25)}" ry="${f(r * 0.12)}" fill="#000" opacity="0.5" filter="url(#bl8)"/>
    <path d="M ${f(cx - r * 1.15)} ${f(cy + r * 1.1)} L ${f(cx - r * 1.0)} ${f(cy + r * 0.98)} L ${f(cx + r * 1.0)} ${f(cy + r * 0.98)} L ${f(cx + r * 1.15)} ${f(cy + r * 1.1)} Z" fill="#3a3456" stroke="#1c1830" stroke-width="${f(r * 0.015)}"/>
    <path d="M ${f(cx - r * 0.8)} ${f(cy + r * 0.99)} L ${f(cx - r * 0.66)} ${f(cy + r * 0.88)} L ${f(cx + r * 0.66)} ${f(cy + r * 0.88)} L ${f(cx + r * 0.8)} ${f(cy + r * 0.99)} Z" fill="#4c4670" stroke="#1c1830" stroke-width="${f(r * 0.015)}"/>
    <rect x="${f(cx - r * 1.0)}" y="${f(cy + r * 0.98)}" width="${f(r * 2)}" height="${f(r * 0.03)}" fill="#6a6290" opacity="0.6"/>`
    : "";
  return `<defs>
    <radialGradient id="${g}v" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#f4eaff"/><stop offset="0.18" stop-color="#a98cff"/><stop offset="0.6" stop-color="#4a2e9a"/><stop offset="1" stop-color="#1c1450"/></radialGradient>
    <radialGradient id="${g}h" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#8f6bff" stop-opacity="${0.5 * glow}"/><stop offset="1" stop-color="#8f6bff" stop-opacity="0"/></radialGradient>
  </defs>
  <circle cx="${cx}" cy="${cy}" r="${f(r * 2.1)}" fill="url(#${g}h)"/>
  ${pl}
  <circle cx="${cx}" cy="${cy}" r="${f(ri)}" fill="url(#${g}v)"/>
  ${arms}${specks}
  <circle cx="${cx}" cy="${cy}" r="${f(ri * 0.16)}" fill="#fff" opacity="0.85" filter="url(#bl4)"/>
  ${blocks}${bevel}${gems}${key}`;
}

// A twig nest seen slightly from above. Returns [back, front] so an egg or
// critter can sit between them. w = nest width.
export function nest(cx, cy, w, { seed = 3, moss = true } = {}) {
  const R = rng(seed);
  const rx = w / 2, ry = w * 0.16;
  let back = `<ellipse cx="${cx}" cy="${f(cy + ry * 0.9)}" rx="${f(rx * 1.1)}" ry="${f(ry * 0.8)}" fill="#000" opacity="0.5" filter="url(#bl4)"/>
    <ellipse cx="${cx}" cy="${cy}" rx="${f(rx)}" ry="${f(ry * 1.2)}" fill="#2a2036"/>
    <ellipse cx="${cx}" cy="${f(cy - ry * 0.15)}" rx="${f(rx * 0.8)}" ry="${f(ry * 0.75)}" fill="#150f20"/>`;
  for (let k = 0; k < 12; k++) {
    const a = Math.PI + (k / 11) * Math.PI;
    const x = cx + Math.cos(a) * rx * 0.92, y = cy + Math.sin(a) * ry;
    const len = w * (0.2 + R() * 0.12), r = (R() - 0.5) * 0.8 + Math.cos(a) * 0.3;
    back += `<line x1="${f(x - (Math.cos(r) * len) / 2)}" y1="${f(y - (Math.sin(r) * len) / 2)}" x2="${f(x + (Math.cos(r) * len) / 2)}" y2="${f(y + (Math.sin(r) * len) / 2)}" stroke="${k % 2 ? "#4a3a52" : "#3b2f47"}" stroke-width="${f(w * 0.022 + R() * w * 0.012)}" stroke-linecap="round"/>`;
  }
  let front = "";
  for (let k = 0; k < 16; k++) {
    const t = k / 15;
    const x = cx - rx * 1.02 + t * rx * 2.04, y = cy + ry * 0.3 + Math.sin(t * Math.PI) * ry * 0.95 + (R() - 0.5) * ry * 0.4;
    const len = w * (0.18 + R() * 0.14), r = (R() - 0.5) * 0.9;
    const c = ["#6a5470", "#5a4762", "#7a6280"][k % 3], sw = w * 0.034 + R() * w * 0.012;
    front += `<line x1="${f(x - (Math.cos(r) * len) / 2)}" y1="${f(y - (Math.sin(r) * len) / 2)}" x2="${f(x + (Math.cos(r) * len) / 2)}" y2="${f(y + (Math.sin(r) * len) / 2)}" stroke="${shade(c, -0.35)}" stroke-width="${f(sw)}" stroke-linecap="round"/>
      <line x1="${f(x - (Math.cos(r) * len) / 2)}" y1="${f(y - (Math.sin(r) * len) / 2 - sw * 0.25)}" x2="${f(x + (Math.cos(r) * len) / 2)}" y2="${f(y + (Math.sin(r) * len) / 2 - sw * 0.25)}" stroke="${c}" stroke-width="${f(sw * 0.55)}" stroke-linecap="round"/>`;
  }
  if (moss)
    for (let k = 0; k < 4; k++) {
      const t = (k + 0.3 + R() * 0.4) / 4, x = cx - rx * 0.9 + t * rx * 1.8, y = cy + Math.sin(t * Math.PI) * ry * 0.7, r = w * (0.04 + R() * 0.035);
      front = `<circle cx="${f(x)}" cy="${f(y)}" r="${f(r)}" fill="#1c4a40"/><circle cx="${f(x + r * 0.7)}" cy="${f(y + r * 0.2)}" r="${f(r * 0.7)}" fill="#1c4a40"/><circle cx="${f(x - r * 0.2)}" cy="${f(y - r * 0.35)}" r="${f(r * 0.55)}" fill="#2a6a52"/>` + front;
    }
  return [back, front];
}

// Hanging paper lantern with a warm, soft (not neon) light.
export function lantern(x, y, s, col = "#ffcf7a", rope = 60) {
  return `<line x1="${x}" y1="${f(y - rope)}" x2="${x}" y2="${f(y - s)}" stroke="#4a4070" stroke-width="${f(Math.max(1.5, s * 0.12))}"/>
    <circle cx="${x}" cy="${y}" r="${f(s * 3.2)}" fill="${col}" opacity="0.16" filter="url(#bl12)"/>
    <ellipse cx="${x}" cy="${y}" rx="${f(s * 0.85)}" ry="${f(s)}" fill="${shade(col, -0.15)}"/>
    <ellipse cx="${f(x - s * 0.2)}" cy="${f(y - s * 0.1)}" rx="${f(s * 0.45)}" ry="${f(s * 0.7)}" fill="${shade(col, 0.35)}" opacity="0.9"/>
    <rect x="${f(x - s * 0.45)}" y="${f(y - s * 1.08)}" width="${f(s * 0.9)}" height="${f(s * 0.2)}" rx="${f(s * 0.06)}" fill="#3a2a40"/>
    <rect x="${f(x - s * 0.45)}" y="${f(y + s * 0.9)}" width="${f(s * 0.9)}" height="${f(s * 0.2)}" rx="${f(s * 0.06)}" fill="#3a2a40"/>`;
}

// Stone hall backdrop: dark wall of big blocks, two arched windows with stars,
// moonlight shafts. Fills (0,0)-(W,H) with floor starting at floorY.
export function hall(W, H, floorY, { seed = 4, windows = [[120, 60], [W - 120, 60]], winW = 90 } = {}) {
  const R = rng(seed);
  let wall = "";
  for (let row = 0; row * 46 < floorY; row++) {
    const off = row % 2 ? -40 : 0;
    for (let x = off; x < W; x += 80) {
      const v = (R() - 0.5) * 0.08;
      wall += `<rect x="${x + 2}" y="${row * 46 + 2}" width="76" height="42" rx="5" fill="${shade("#1e1a3c", v)}"/>`;
    }
  }
  let wins = "";
  for (const [wx, wy] of windows) {
    const h = winW * 1.5;
    const arch = `M ${wx - winW / 2} ${wy + h} L ${wx - winW / 2} ${wy + winW / 2} A ${winW / 2} ${winW / 2} 0 0 1 ${wx + winW / 2} ${wy + winW / 2} L ${wx + winW / 2} ${wy + h} Z`;
    let st = "";
    for (let k = 0; k < 10; k++) st += `<circle cx="${f(wx - winW / 2 + R() * winW)}" cy="${f(wy + 8 + R() * (h - 12))}" r="${f(0.6 + R() * 1.4)}" fill="#efeaff" opacity="${f(0.4 + R() * 0.5)}"/>`;
    wins += `<path d="${arch}" fill="#2a2d6a" stroke="#141030" stroke-width="10"/>${st}
      <path d="${arch}" fill="none" stroke="#5a5490" stroke-width="3"/>
      <line x1="${wx}" y1="${wy}" x2="${wx}" y2="${wy + h}" stroke="#141030" stroke-width="5"/>
      <path d="M ${wx - winW / 2} ${wy + h} L ${wx + winW / 2} ${wy + h} L ${wx + winW * 1.6} ${floorY + 60} L ${wx - winW * 0.2} ${floorY + 60} Z" fill="#b8b4ff" opacity="0.05"/>`;
  }
  const floor = `<rect x="0" y="${floorY}" width="${W}" height="${H - floorY}" fill="#17142e"/>
    ${Array.from({ length: 9 }, (_, k) => `<line x1="${f(W / 2 + (k - 4) * 40)}" y1="${floorY}" x2="${f(W / 2 + (k - 4) * 220)}" y2="${H}" stroke="#0e0c20" stroke-width="3"/>`).join("")}
    ${Array.from({ length: 5 }, (_, k) => { const y = floorY + (H - floorY) * Math.pow((k + 1) / 6, 1.5); return `<line x1="0" y1="${f(y)}" x2="${W}" y2="${f(y)}" stroke="#0e0c20" stroke-width="3"/>`; }).join("")}
    <rect x="0" y="${floorY - 4}" width="${W}" height="8" fill="#2c2850"/>`;
  return `<rect width="${W}" height="${H}" fill="#120f2a"/>${wall}${wins}${floor}`;
}

// Hanging vines along the top edge.
export function vines(seed, W, n, maxLen) {
  const R = rng(seed);
  let out = "";
  for (let k = 0; k < n; k++) {
    const x = R() * W, len = maxLen * (0.3 + R() * 0.7);
    out += `<path d="M ${f(x)} -4 Q ${f(x + (R() - 0.5) * 30)} ${f(len * 0.5)} ${f(x + (R() - 0.5) * 16)} ${f(len)}" fill="none" stroke="#1d3a3a" stroke-width="3" stroke-linecap="round"/>`;
    for (let j = 1; j < 5; j++) {
      const y = (len * j) / 5, lx = x + (R() - 0.5) * 12;
      out += `<ellipse cx="${f(lx + (j % 2 ? 5 : -5))}" cy="${f(y)}" rx="6" ry="3" transform="rotate(${j % 2 ? 30 : -30} ${f(lx)} ${f(y)})" fill="${j % 2 ? "#2b5a4c" : "#24493f"}"/>`;
    }
  }
  return out;
}

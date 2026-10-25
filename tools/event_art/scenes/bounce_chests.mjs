// Bounce Run reward chests, five tiers (bronze, silver, gold, crystal,
// champion). Each tier is two pictures on the same 400x360 transparent
// canvas so they stack pixel-exactly: chest_<tier>_base.png (the box on its
// contact shadow, with the open interior and its warm glow painted above
// the rim at y~174) and chest_<tier>_lid.png (just the closed lid, which
// covers the rim and the whole interior). The game swings the lid away
// around the hinge point HINGE (200, 180), the lid's back/bottom edge.
import { shade } from "../../brand/parts.mjs";
import { blurs, sparkle, rng } from "./_shop_charge_pad_glow_chest_parts.mjs";

export const size = [400, 360];
export const transparent = true;
export const HINGE = [200, 180];

const W = 400, H = 360, CX = 200;
const RIM = 174; // where the lid closes (top of the body's rim band)
const LIP = 184; // bottom edge of the closed lid
const f = (n) => (typeof n === "number" ? +n.toFixed(1) : n);
const wrap = (body) => `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${blurs()}${body}</svg>`;

// Metal gradient stops [hi, mid, lo] for bands and plates.
const BRONZE_M = ["#ffc79a", "#c9773f", "#6e3418"];
const STEEL_M = ["#f3f7ff", "#a3b0c9", "#4b5774"];
const GOLD_M = ["#fff1b8", "#eab448", "#8a5418"];

const TIERS = {
  bronze: {
    L: 104, R: 296, bot: 290, top: 76,
    body: ["#a0603a", "#70391f", "#3c1b12"], fill: "planks",
    band: BRONZE_M, ink: "#2c120a", rim: "#ffb27a", rimO: 0.45,
    glow: "#ff9a3c", core: "#ffe2a6", inner: "#1c0c0c",
    gem: null, corners: false, feet: false, studs: 0,
  },
  silver: {
    L: 102, R: 298, bot: 291, top: 74,
    body: ["#d9e1ee", "#8f9cb8", "#46506c"], fill: "plates",
    band: ["#ffffff", "#b8c3da", "#566282"], ink: "#18203a", rim: "#8fdcff", rimO: 0.7,
    glow: "#ffcf7a", core: "#fff1cc", inner: "#10121e",
    gem: "#4fb8ff", corners: true, feet: false, studs: 0,
  },
  gold: {
    L: 100, R: 300, bot: 292, top: 72,
    body: ["#ffd27a", "#d48f2c", "#7a4410"], fill: "emboss",
    band: GOLD_M, ink: "#3e2206", rim: "#fff0a8", rimO: 0.6,
    glow: "#ffc24a", core: "#fff4c8", inner: "#1c0e06",
    gem: "#ff2d55", corners: true, feet: true, studs: 0,
  },
  crystal: {
    L: 98, R: 302, bot: 293, top: 70,
    body: ["#c8f6ff", "#3ab8e8", "#0e4a7a"], fill: "crystal",
    band: STEEL_M, ink: "#0c2238", rim: "#a8f6ff", rimO: 0.75,
    glow: "#9ff0ff", core: "#ffffff", inner: "#061424",
    gem: "#6ff2ff", corners: true, feet: true, studs: 0,
  },
  champion: {
    L: 86, R: 314, bot: 304, top: 56,
    body: ["#9a46c8", "#5a1c8e", "#26093e"], fill: "royal",
    band: GOLD_M, ink: "#22062e", rim: "#ff7ad8", rimO: 0.7,
    glow: "#ffb84a", core: "#fff0c0", inner: "#1a0624",
    gem: "#ff3fc0", corners: true, feet: true, studs: 4,
  },
};

const lg = (id, stops, x2 = 0, y2 = 1) =>
  `<linearGradient id="${id}" x1="0" y1="0" x2="${x2}" y2="${y2}">${stops.map((c, k) => `<stop offset="${f(k / (stops.length - 1))}" stop-color="${c}"/>`).join("")}</linearGradient>`;

// Shared geometry for a tier.
function geo(t) {
  const { L, R, bot, top } = t;
  const Ll = L - 5, Rl = R + 5, ys = top + 46;
  const s1 = L + 26, s2 = R - 48, sw = 22; // strap x positions (body and lid line up)
  return {
    L, R, bot, top, Ll, Rl, ys, s1, s2, sw,
    body: `M ${L} ${RIM} L ${R} ${RIM} L ${R - 3} ${bot} Q ${CX} ${bot + 5} ${L + 3} ${bot} Z`,
    lid: (i = 0) => `M ${Ll + i} ${LIP} L ${Ll + i} ${ys} Q ${Ll + i} ${top + i} ${CX} ${top + i} Q ${Rl - i} ${top + i} ${Rl - i} ${ys} L ${Rl - i} ${LIP} Z`,
  };
}

const rivet = (x, y, r, ink, hi) => `<circle cx="${f(x)}" cy="${f(y)}" r="${r}" fill="${ink}" opacity="0.85"/><circle cx="${f(x - r * 0.3)}" cy="${f(y - r * 0.35)}" r="${f(r * 0.45)}" fill="${hi}" opacity="0.8"/>`;

// A metal bar with a highlight line and an ink outline.
const bar = (x, y, w, h, t, gid, rx = 4) =>
  `<rect x="${f(x)}" y="${f(y)}" width="${f(w)}" height="${f(h)}" rx="${rx}" fill="url(#${gid})" stroke="${t.ink}" stroke-width="2.4"/>
   <rect x="${f(x + 3)}" y="${f(y + 2)}" width="${f(w - 6)}" height="${f(Math.min(3, h * 0.18))}" rx="1.5" fill="#fff" opacity="0.4"/>`;

// A faceted gem (round-ish brilliant) at cx, cy.
function gem(cx, cy, r, col, p) {
  const pts = (k, rr, off = 0) => [...Array(k)].map((_, i) => {
    const a = -Math.PI / 2 + off + (i * 2 * Math.PI) / k;
    return [cx + Math.cos(a) * rr, cy + Math.sin(a) * rr * 1.08];
  });
  const o = pts(8, r), n = pts(8, r * 0.52, Math.PI / 8);
  let fac = "";
  for (let i = 0; i < 8; i++) {
    const a = o[i], b = o[(i + 1) % 8], c = n[i];
    const lit = Math.cos(((i + 0.5) / 8) * 2 * Math.PI + 2.4);
    fac += `<polygon points="${f(a[0])},${f(a[1])} ${f(b[0])},${f(b[1])} ${f(c[0])},${f(c[1])}" fill="${shade(col, lit > 0 ? lit * 0.45 : lit * 0.5)}"/>`;
    const d = n[(i + 7) % 8];
    fac += `<polygon points="${f(a[0])},${f(a[1])} ${f(c[0])},${f(c[1])} ${f(d[0])},${f(d[1])}" fill="${shade(col, lit > 0 ? lit * 0.25 : lit * 0.65)}"/>`;
  }
  return `<defs><radialGradient id="${p}gt" cx="0.4" cy="0.35" r="0.7"><stop offset="0" stop-color="${shade(col, 0.65)}"/><stop offset="0.6" stop-color="${col}"/><stop offset="1" stop-color="${shade(col, -0.4)}"/></radialGradient></defs>
  <circle cx="${cx}" cy="${cy}" r="${r * 1.5}" fill="${col}" opacity="0.4" filter="url(#bl4)"/>
  <polygon points="${o.map((q) => q.map(f).join(",")).join(" ")}" fill="${shade(col, -0.6)}" stroke="${shade(col, -0.7)}" stroke-width="${f(r * 0.22)}" stroke-linejoin="round"/>
  ${fac}
  <polygon points="${n.map((q) => q.map(f).join(",")).join(" ")}" fill="url(#${p}gt)"/>
  <ellipse cx="${f(cx - r * 0.22)}" cy="${f(cy - r * 0.28)}" rx="${f(r * 0.22)}" ry="${f(r * 0.14)}" fill="#fff" opacity="0.85" transform="rotate(-30 ${f(cx - r * 0.22)} ${f(cy - r * 0.28)})"/>`;
}

// Jittered triangle facets filling a box, for the crystal panels.
function facets(x0, y0, x1, y1, seed, base) {
  const r = rng(seed);
  const nx = 3, ny = 3;
  const P = [];
  for (let j = 0; j <= ny; j++) {
    P.push([]);
    for (let i = 0; i <= nx; i++) {
      const edge = i == 0 || i == nx || j == 0 || j == ny;
      const jx = edge && (i == 0 || i == nx) ? 0 : (r() - 0.5) * 0.5;
      const jy = edge && (j == 0 || j == ny) ? 0 : (r() - 0.5) * 0.5;
      P[j].push([x0 + ((i + jx) / nx) * (x1 - x0), y0 + ((j + jy) / ny) * (y1 - y0)]);
    }
  }
  let out = "";
  for (let j = 0; j < ny; j++) for (let i = 0; i < nx; i++) {
    const a = P[j][i], b = P[j][i + 1], c = P[j + 1][i + 1], d = P[j + 1][i];
    const tris = (i + j) % 2 ? [[a, b, c], [a, c, d]] : [[a, b, d], [b, c, d]];
    for (const tr of tris) {
      const my = (tr[0][1] + tr[1][1] + tr[2][1]) / 3, mx = (tr[0][0] + tr[1][0] + tr[2][0]) / 3;
      const v = 0.55 - ((my - y0) / (y1 - y0)) * 0.9 - ((mx - x0) / (x1 - x0)) * 0.25 + (r() - 0.5) * 0.55;
      const col = v > 0 ? shade(base, Math.min(0.8, v)) : shade(base, Math.max(-0.6, v));
      out += `<polygon points="${tr.map((q) => q.map(f).join(",")).join(" ")}" fill="${col}" stroke="#e6fdff" stroke-width="0.8" stroke-opacity="0.45" stroke-linejoin="round"/>`;
    }
  }
  return out;
}

// The surface pattern of the body front or the lid face, clipped by caller.
function surface(t, g, p, x0, y0, x1, y1, seed) {
  if (t.fill == "planks") {
    let s = "";
    for (let y = y0 + 26; y < y1; y += 26) s += `<line x1="${x0}" y1="${y}" x2="${x1}" y2="${y}" stroke="#2a120c" stroke-width="2.2" opacity="0.65"/><line x1="${x0}" y1="${y + 2}" x2="${x1}" y2="${y + 2}" stroke="#d08a5a" stroke-width="1" opacity="0.25"/>`;
    const r = rng(seed);
    for (let k = 0; k < 14; k++) {
      const y = y0 + 8 + r() * (y1 - y0 - 12), x = x0 + r() * (x1 - x0 - 50), w = 24 + r() * 40;
      s += `<path d="M ${f(x)} ${f(y)} Q ${f(x + w / 2)} ${f(y - 2 + r() * 4)} ${f(x + w)} ${f(y)}" fill="none" stroke="#2a120c" stroke-width="1.2" opacity="0.35"/>`;
    }
    return s;
  }
  if (t.fill == "plates") {
    let s = "";
    for (let y = y0 + 4; y < y1; y += 5) s += `<line x1="${x0}" y1="${y}" x2="${x1}" y2="${y}" stroke="#fff" stroke-width="0.8" opacity="${0.05 + ((y * 7) % 5) * 0.012}"/>`;
    return s + `<rect x="${x0}" y="${y0}" width="${x1 - x0}" height="${y1 - y0}" fill="url(#${p}sheen)"/>`;
  }
  if (t.fill == "emboss") {
    let s = "";
    for (let x = x0 - (y1 - y0); x < x1; x += 22)
      s += `<line x1="${x}" y1="${y1}" x2="${x + (y1 - y0)}" y2="${y0}" stroke="#5a300c" stroke-width="1.4" opacity="0.22"/><line x1="${x + (y1 - y0)}" y1="${y1}" x2="${x}" y2="${y0}" stroke="#5a300c" stroke-width="1.4" opacity="0.22"/>`;
    return s + `<rect x="${x0}" y="${y0}" width="${x1 - x0}" height="${y1 - y0}" fill="url(#${p}sheen)"/>`;
  }
  if (t.fill == "royal") {
    let s = "";
    for (let x = x0 - (y1 - y0); x < x1; x += 26)
      s += `<line x1="${x}" y1="${y1}" x2="${x + (y1 - y0)}" y2="${y0}" stroke="#ffd36b" stroke-width="1.2" opacity="0.28"/><line x1="${x + (y1 - y0)}" y1="${y1}" x2="${x}" y2="${y0}" stroke="#ffd36b" stroke-width="1.2" opacity="0.28"/>`;
    // tufts at the lattice crossings
    for (let y = y0; y < y1 + 13; y += 13) for (let x = x0; x < x1 + 13; x += 13)
      if (((x - x0) / 13 + (y - y0) / 13) % 2 == 0) s += `<circle cx="${x}" cy="${y}" r="1.6" fill="#ffe7a0" opacity="0.5"/>`;
    return s + `<rect x="${x0}" y="${y0}" width="${x1 - x0}" height="${y1 - y0}" fill="url(#${p}sheen)"/>`;
  }
  return "";
}

function defsFor(t, p) {
  return `<defs>
    ${lg(p + "body", t.body, 0.35, 1)}
    ${lg(p + "band", t.band)}
    ${lg(p + "bandH", t.band, 1, 0)}
    <linearGradient id="${p}shade" x1="0" y1="0" x2="0" y2="1"><stop offset="0.35" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.4"/></linearGradient>
    <linearGradient id="${p}sheen" x1="0" y1="0" x2="1" y2="0.3"><stop offset="0" stop-color="#fff" stop-opacity="0.18"/><stop offset="0.35" stop-color="#fff" stop-opacity="0"/><stop offset="0.75" stop-color="#000" stop-opacity="0.08"/><stop offset="1" stop-color="#000" stop-opacity="0.2"/></linearGradient>
    <linearGradient id="${p}rimL" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="${t.rim}" stop-opacity="${t.rimO}"/><stop offset="0.12" stop-color="${t.rim}" stop-opacity="0"/><stop offset="0.88" stop-color="${t.rim}" stop-opacity="0"/><stop offset="1" stop-color="${t.rim}" stop-opacity="${t.rimO * 0.8}"/></linearGradient>
    <linearGradient id="${p}lidG" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="${shade(t.body[1], -0.15)}"/><stop offset="0.22" stop-color="${t.body[0]}"/><stop offset="0.55" stop-color="${t.body[1]}"/><stop offset="1" stop-color="${t.body[2]}"/></linearGradient>
  </defs>`;
}

// ---------- base ----------
function base(name) {
  const t = TIERS[name], g = geo(t), p = name[0] + "b";
  const { L, R, bot, s1, s2, sw } = g;
  const backY = RIM - 38, inset = 14;
  const mouth = `M ${L + 1} ${RIM + 2} L ${R - 1} ${RIM + 2} L ${R - inset} ${backY} L ${L + inset} ${backY} Z`;
  let out = defsFor(t, p);

  // contact shadow and (for the top tiers) a soft backlight aura
  out += `<ellipse cx="${CX}" cy="${bot + 6}" rx="${(R - L) / 2 + 26}" ry="15" fill="#000" opacity="0.5" filter="url(#bl6)"/>
    <ellipse cx="${CX}" cy="${bot + 2}" rx="${(R - L) / 2 - 6}" ry="7" fill="#000" opacity="0.45" filter="url(#bl3)"/>`;

  // interior: back wall, glow from the treasure, bloom kept inside the lid's outline
  out += `<defs>
    <mask id="${p}lidC" maskUnits="userSpaceOnUse" x="0" y="0" width="${W}" height="${H}"><path d="${g.lid(18)}" fill="#fff" filter="url(#bl6)"/></mask>
    <clipPath id="${p}mouth"><path d="${mouth}"/></clipPath>
    <linearGradient id="${p}wall" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${t.inner}"/><stop offset="1" stop-color="${shade(t.glow, -0.45)}"/></linearGradient>
  </defs>
  <g mask="url(#${p}lidC)">
    <ellipse cx="${CX}" cy="${RIM - 14}" rx="${(R - L) / 2 - 6}" ry="50" fill="${t.glow}" opacity="0.5" filter="url(#bl16)"/>
    <ellipse cx="${CX}" cy="${RIM - 30}" rx="${(R - L) / 2 - 40}" ry="26" fill="${t.core}" opacity="0.35" filter="url(#bl12)"/>
    ${[-56, -20, 20, 56].map((dx, k) => `<path d="M ${CX + dx * 0.7 - 10} ${RIM - 8} L ${CX + dx * 1.3 - 6} ${g.top + 30} L ${CX + dx * 1.3 + 8} ${g.top + 30} L ${CX + dx * 0.7 + 10} ${RIM - 8} Z" fill="${t.core}" opacity="${k % 3 ? 0.22 : 0.15}" filter="url(#bl4)"/>`).join("")}
  </g>
  <path d="${mouth}" fill="url(#${p}wall)" stroke="${t.ink}" stroke-width="2.5" stroke-linejoin="round"/>
  <g clip-path="url(#${p}mouth)">
    <ellipse cx="${CX}" cy="${RIM + 4}" rx="${(R - L) / 2 - 8}" ry="22" fill="${t.glow}" opacity="0.9" filter="url(#bl8)"/>
    <ellipse cx="${CX}" cy="${RIM + 2}" rx="${(R - L) / 2 - 36}" ry="12" fill="${t.core}" filter="url(#bl4)"/>
    ${[[-62, 2, 26], [-24, -4, 30], [16, -2, 28], [56, 3, 26]].map(([dx, dy, r]) => `<ellipse cx="${CX + dx}" cy="${RIM + dy + 8}" rx="${r}" ry="${r * 0.55}" fill="${t.core}" opacity="0.75" filter="url(#bl3)"/>`).join("")}
    ${[[-70, -2], [-40, -8], [-10, -11], [22, -9], [50, -6], [76, -1], [-56, -14], [36, -16]].map(([dx, dy], k) => `<ellipse cx="${CX + dx}" cy="${RIM + dy + 4}" rx="${5 + (k % 3)}" ry="${3 + (k % 2)}" fill="#fff" opacity="0.8"/>`).join("")}
    <rect x="${L}" y="${backY}" width="${R - L}" height="10" fill="#000" opacity="0.35" filter="url(#bl3)"/>
  </g>
  <path d="M ${L + inset} ${backY} L ${R - inset} ${backY}" stroke="url(#${p}band)" stroke-width="5" stroke-linecap="round"/>
  <path d="M ${L + inset} ${backY} L ${R - inset} ${backY}" stroke="${t.ink}" stroke-width="1.4" opacity="0.6" transform="translate(0 -3)"/>
  <path d="M ${L + 1} ${RIM + 2} L ${L + inset} ${backY} M ${R - 1} ${RIM + 2} L ${R - inset} ${backY}" stroke="url(#${p}band)" stroke-width="4" stroke-linecap="round"/>
  ${[0, 1, 2, 3].map((k) => sparkle(CX - 60 + k * 40 + (k % 2) * 8, RIM - 40 - (k % 2) * 22, 3 + (k % 2) * 2, t.core, 0.75)).join("")}`;

  // feet
  if (t.feet) {
    for (const x of [L + 14, R - 14]) out += `<path d="M ${x - 14} ${bot - 6} L ${x + 14} ${bot - 6} L ${x + 10} ${bot + 8} Q ${x} ${bot + 13} ${x - 10} ${bot + 8} Z" fill="url(#${p}band)" stroke="${t.ink}" stroke-width="2.2" stroke-linejoin="round"/>`;
  }

  // body
  out += `<defs><clipPath id="${p}bodyC"><path d="${g.body}"/></clipPath></defs>
  <path d="${g.body}" fill="url(#${p}body)"/>
  <g clip-path="url(#${p}bodyC)">`;
  if (t.fill == "crystal") {
    const panels = [[L, s1], [s1 + sw, s2], [s2 + sw, R]];
    out += `<rect x="${L}" y="${RIM}" width="${R - L}" height="${bot - RIM + 8}" fill="#0e3a5e"/>`;
    panels.forEach(([a, b], k) => (out += facets(a, RIM + 14, b, bot - 14, 11 + k, "#38c6f0")));
    out += `<ellipse cx="${CX}" cy="${(RIM + bot) / 2}" rx="${(R - L) / 2}" ry="40" fill="#bff8ff" opacity="0.18" filter="url(#bl12)"/>`;
  } else out += surface(t, g, p, L, RIM, R, bot + 6, 5);
  out += `<path d="${g.body}" fill="url(#${p}shade)"/>
    <rect x="${L}" y="${RIM}" width="${R - L}" height="${bot - RIM}" fill="url(#${p}rimL)"/>
    <rect x="${L}" y="${RIM + 14}" width="${R - L}" height="26" fill="${t.glow}" opacity="0.12" filter="url(#bl6)"/>
  </g>
  <path d="${g.body}" fill="none" stroke="${t.ink}" stroke-width="3" stroke-linejoin="round"/>`;

  // gold-tier embossed panel frames
  if (t.fill == "emboss" || t.fill == "royal") {
    for (const [a, b] of [[L + 6, s1 - 5], [s2 + sw + 5, R - 6]])
      out += `<rect x="${a}" y="${RIM + 22}" width="${b - a}" height="${bot - RIM - 46}" rx="5" fill="none" stroke="${t.fill == "royal" ? "#ffd36b" : "#ffe9a0"}" stroke-width="2" opacity="0.55"/>
      <rect x="${a + 1.5}" y="${RIM + 23.5}" width="${b - a}" height="${bot - RIM - 46}" rx="5" fill="none" stroke="#000" stroke-width="1.5" opacity="0.25"/>`;
  }

  // straps
  for (const x of [s1, s2]) {
    out += bar(x, RIM + 8, sw, bot - RIM - 20, t, p + "bandH", 3);
    out += rivet(x + sw / 2, RIM + 24, 2.6, t.ink, t.band[0]) + rivet(x + sw / 2, bot - 22, 2.6, t.ink, t.band[0]);
    if (t.fill == "crystal" || t.fill == "royal") out += rivet(x + sw / 2, (RIM + bot) / 2, 2.6, t.ink, t.band[0]);
  }
  if (t.studs) for (const x of [s1, s2]) out += gem(x + sw / 2, (RIM + bot) / 2, 5.5, k2(x) ? "#5ce1ff" : t.gem, p + "s" + x);

  // corner caps
  if (t.corners) {
    const cap = (x, y, sx, sy) => `<path d="M ${x} ${y} L ${x + sx * 30} ${y} L ${x + sx * 30} ${y + sy * 7} L ${x + sx * 8} ${y + sy * 7} L ${x + sx * 8} ${y + sy * 30} L ${x} ${y + sy * 30} Z" fill="url(#${p}band)" stroke="${t.ink}" stroke-width="2.2" stroke-linejoin="round"/>
      <path d="M ${x + sx * 8} ${y + sy * 7} L ${x + sx * 26} ${y + sy * 7} L ${x + sx * 8} ${y + sy * 25} Z" fill="url(#${p}band)" stroke="${t.ink}" stroke-width="1.8" stroke-linejoin="round"/>${rivet(x + sx * 12, y + sy * 11, 2.2, t.ink, t.band[0])}`;
    out += cap(L - 1, RIM + 14, 1, 1) + cap(R + 1, RIM + 14, -1, 1) + cap(L + 2, bot - 14, 1, -1) + cap(R - 2, bot - 14, -1, -1);
  }

  // rim band and bottom band
  out += bar(L - 7, RIM, R - L + 14, 16, t, p + "band", 5);
  out += `<rect x="${L - 7}" y="${RIM}" width="${R - L + 14}" height="4" rx="2" fill="${t.core}" opacity="0.7"/>`;
  out += bar(L - 5, bot - 16, R - L + 10, 16, t, p + "band", 5);
  for (const x of [L + 2, s1 + sw / 2, s2 + sw / 2, R - 2]) out += rivet(x, bot - 8, 2.4, t.ink, t.band[0]);
  for (const x of [L + 2, R - 2]) out += rivet(x, RIM + 8, 2.4, t.ink, t.band[0]);
  if (name == "champion") {
    // a gold scalloped trim along the bottom band
    let sc = "";
    for (let x = L + 14; x < R - 10; x += 18) sc += `<path d="M ${x - 8} ${bot - 16} Q ${x} ${bot - 26} ${x + 8} ${bot - 16}" fill="none" stroke="#ffe7a0" stroke-width="2" opacity="0.8"/>`;
    out += sc;
  }

  // rim lights on the body sides
  out += `<path d="M ${L + 2} ${RIM + 18} L ${L + 4} ${bot - 20}" stroke="${t.rim}" stroke-width="2.5" opacity="${t.rimO}" stroke-linecap="round"/>
    <path d="M ${R - 2} ${RIM + 18} L ${R - 4} ${bot - 20}" stroke="${t.rim}" stroke-width="2.5" opacity="${t.rimO * 0.8}" stroke-linecap="round"/>`;

  // lock plate (the hasp on the lid drops over its top)
  const lp = 196, lw = name == "champion" ? 32 : 27, lh = name == "champion" ? 46 : 40;
  out += `<path d="M ${CX - lw} ${lp} L ${CX + lw} ${lp} L ${CX + lw} ${lp + lh * 0.65} Q ${CX} ${lp + lh * 1.25} ${CX - lw} ${lp + lh * 0.65} Z" fill="url(#${p}band)" stroke="${t.ink}" stroke-width="2.6" stroke-linejoin="round"/>
    <path d="M ${CX - lw + 5} ${lp + 4} L ${CX + lw - 5} ${lp + 4} L ${CX + lw - 5} ${lp + lh * 0.62} Q ${CX} ${lp + lh * 1.12} ${CX - lw + 5} ${lp + lh * 0.62} Z" fill="none" stroke="${t.ink}" stroke-width="1.4" opacity="0.45"/>`;
  const gy = lp + lh * 0.55;
  if (t.gem) out += gem(CX, gy, name == "champion" ? 11 : 9, t.gem, p + "lk");
  else out += `<circle cx="${CX}" cy="${gy - 3}" r="5" fill="${t.ink}"/><path d="M ${CX - 3} ${gy} L ${CX + 3} ${gy} L ${CX + 2} ${gy + 10} L ${CX - 2} ${gy + 10} Z" fill="${t.ink}"/>`;

  // crystal: glints on the facets
  if (t.fill == "crystal") out += [[L + 24, 214, 6], [CX + 52, 258, 7], [R - 22, 236, 5], [CX - 56, 270, 4]].map(([x, y, r]) => sparkle(x, y, r, "#ffffff", 0.95)).join("");
  if (name == "gold") out += sparkle(R - 18, 202, 5, "#fff8dc", 0.9);
  if (name == "champion") out += [[L + 10, 196, 6], [R - 8, 270, 5]].map(([x, y, r]) => sparkle(x, y, r, "#fff0c0", 0.95)).join("");
  return wrap(out);
}
const k2 = (x) => x > CX;

// ---------- lid ----------
function lid(name) {
  const t = TIERS[name], g = geo(t), p = name[0] + "l";
  const { L, R, top, Ll, Rl, ys, s1, s2, sw } = g;
  let out = defsFor(t, p);
  out += `<defs><clipPath id="${p}C"><path d="${g.lid()}"/></clipPath>
    <linearGradient id="${p}dome" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.22"/><stop offset="0.35" stop-color="#fff" stop-opacity="0.05"/><stop offset="0.55" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.32"/></linearGradient>
    <linearGradient id="${p}top" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#000" stop-opacity="0.35"/><stop offset="1" stop-color="#000" stop-opacity="0"/></linearGradient></defs>
  <path d="${g.lid()}" fill="url(#${p}lidG)"/>
  <g clip-path="url(#${p}C)">`;
  if (t.fill == "crystal") {
    out += `<rect x="${Ll}" y="${top}" width="${Rl - Ll}" height="${LIP - top}" fill="#0e3a5e"/>`;
    [[Ll, s1], [s1 + sw, s2], [s2 + sw, Rl]].forEach(([a, b], k) => (out += facets(a, top - 4, b, LIP - 14, 31 + k, "#38c6f0")));
  } else out += surface(t, g, p, Ll, top, Rl, LIP, 9);
  out += `<rect x="${Ll}" y="${top}" width="${Rl - Ll}" height="${LIP - top}" fill="url(#${p}dome)"/>
    <rect x="${Ll}" y="${top}" width="${Rl - Ll}" height="14" fill="url(#${p}top)"/>
    <rect x="${Ll}" y="${top}" width="${Rl - Ll}" height="${LIP - top}" fill="url(#${p}rimL)"/>`;
  // straps over the dome
  if (name != "champion") {
    for (const x of [s1, s2]) out += `<rect x="${x}" y="${top - 2}" width="${sw}" height="${LIP - top}" fill="url(#${p}bandH)" stroke="${t.ink}" stroke-width="2.4"/>
      <rect x="${x}" y="${top - 2}" width="${sw}" height="${LIP - top}" fill="url(#${p}dome)"/>
      <line x1="${x + 4}" y1="${top + 10}" x2="${x + 4}" y2="${LIP - 20}" stroke="#fff" stroke-width="2" opacity="0.35"/>`;
  } else {
    // champion: gold trim following the dome, and side straps
    for (const x of [s1 - 8, s2 + 8]) out += `<rect x="${x}" y="${top - 2}" width="${sw}" height="${LIP - top}" fill="url(#${p}bandH)" stroke="${t.ink}" stroke-width="2.4"/><rect x="${x}" y="${top - 2}" width="${sw}" height="${LIP - top}" fill="url(#${p}dome)"/>`;
  }
  out += `</g>`;
  if (name == "champion") out += `<path d="${g.lid(4)}" fill="none" stroke="#ffe08a" stroke-width="3" opacity="0.7"/>`;
  out += `<path d="${g.lid()}" fill="none" stroke="${name == "champion" ? "url(#" + p + "band)" : t.ink}" stroke-width="${name == "champion" ? 7 : 3}" stroke-linejoin="round"/>`;
  if (name == "champion") out += `<path d="${g.lid(-3.5)}" fill="none" stroke="${t.ink}" stroke-width="2" stroke-linejoin="round"/>`;
  // rim light on the dome's edges
  out += `<path d="M ${Ll + 3} ${LIP - 24} L ${Ll + 3} ${ys} Q ${Ll + 3} ${top + 3} ${CX - 40} ${top + 3}" fill="none" stroke="${t.rim}" stroke-width="2.5" opacity="${t.rimO}" stroke-linecap="round"/>
    <path d="M ${Rl - 3} ${LIP - 24} L ${Rl - 3} ${ys + 4}" fill="none" stroke="${t.rim}" stroke-width="2.5" opacity="${t.rimO * 0.8}" stroke-linecap="round"/>
    <ellipse cx="${CX - 40}" cy="${top + 16}" rx="56" ry="8" fill="#fff" opacity="0.12" filter="url(#bl4)"/>`;

  // strap rivets
  const sx = name == "champion" ? [s1 - 8, s2 + 8] : [s1, s2];
  for (const x of sx) out += rivet(x + sw / 2, top + 22, 2.6, t.ink, t.band[0]) + rivet(x + sw / 2, LIP - 30, 2.6, t.ink, t.band[0]);

  // lid lip band
  out += bar(Ll - 3, LIP - 20, Rl - Ll + 6, 20, t, p + "band", 6);
  for (const x of [Ll + 6, sx[0] + sw / 2, sx[1] + sw / 2, Rl - 6]) out += rivet(x, LIP - 10, 2.4, t.ink, t.band[0]);

  // top corner caps
  if (t.corners) {
    out += `<defs><clipPath id="${p}cc"><circle cx="${Ll + 14}" cy="${top + 20}" r="34"/><circle cx="${Rl - 14}" cy="${top + 20}" r="34"/></clipPath></defs>
      <g clip-path="url(#${p}cc)"><path d="${g.lid(3)}" fill="none" stroke="${t.ink}" stroke-width="14"/><path d="${g.lid(3)}" fill="none" stroke="url(#${p}band)" stroke-width="10"/><path d="${g.lid(1)}" fill="none" stroke="#fff" stroke-width="1.6" opacity="0.5"/></g>
      ${rivet(Ll + 8, ys - 8, 2.4, t.ink, t.band[0])}${rivet(Rl - 8, ys - 8, 2.4, t.ink, t.band[0])}`;
  }

  // champion emblem: gold medallion with a star under a little crown
  if (name == "champion") {
    const ey = top + 66, er = 30;
    let star = "";
    for (let k = 0; k < 10; k++) {
      const a = -Math.PI / 2 + (k * Math.PI) / 5, rr = k % 2 ? er * 0.27 : er * 0.62;
      star += `${f(CX + Math.cos(a) * rr)},${f(ey + 2 + Math.sin(a) * rr)} `;
    }
    out += `<defs><radialGradient id="${p}med" cx="0.4" cy="0.35" r="0.7"><stop offset="0" stop-color="#7a2aa8"/><stop offset="1" stop-color="#2a0a44"/></radialGradient>
      ${lg(p + "star", ["#fff6cc", "#ffd36b", "#c07a1e"])}</defs>
      <circle cx="${CX}" cy="${ey}" r="${er + 14}" fill="#ffb84a" opacity="0.25" filter="url(#bl8)"/>
      <circle cx="${CX}" cy="${ey}" r="${er + 4}" fill="url(#${p}band)" stroke="${t.ink}" stroke-width="2.6"/>
      ${[...Array(12)].map((_, k) => { const a = (k * Math.PI) / 6; return `<circle cx="${f(CX + Math.cos(a) * (er + 0.5))}" cy="${f(ey + Math.sin(a) * (er + 0.5))}" r="1.6" fill="${t.ink}" opacity="0.6"/>`; }).join("")}
      <circle cx="${CX}" cy="${ey}" r="${er - 4}" fill="url(#${p}med)" stroke="${t.ink}" stroke-width="2"/>
      <polygon points="${star}" fill="url(#${p}star)" stroke="#6a3a08" stroke-width="2" stroke-linejoin="round"/>
      <polygon points="${star}" fill="none" stroke="#fff6cc" stroke-width="0.8" opacity="0.7" transform="translate(-0.6 -0.6)"/>
      <path d="M ${CX - 22} ${ey - er + 2} L ${CX - 26} ${ey - er - 22} L ${CX - 12} ${ey - er - 10} L ${CX} ${ey - er - 28} L ${CX + 12} ${ey - er - 10} L ${CX + 26} ${ey - er - 22} L ${CX + 22} ${ey - er + 2} Q ${CX} ${ey - er - 4} ${CX - 22} ${ey - er + 2} Z" fill="url(#${p}star)" stroke="#5a2e06" stroke-width="2.2" stroke-linejoin="round"/>
      <path d="M ${CX - 22} ${ey - er + 1} Q ${CX} ${ey - er - 5} ${CX + 22} ${ey - er + 1}" fill="none" stroke="#5a2e06" stroke-width="1.6"/>
      ${[[-26, -22], [0, -28], [26, -22]].map(([dx, dy]) => `<circle cx="${CX + dx}" cy="${ey - er + dy}" r="3.4" fill="#fff0c0" stroke="#5a2e06" stroke-width="1.5"/>`).join("")}
      ${gem(CX, ey - er - 8, 4.2, "#5ce1ff", p + "cg")}
      ${sparkle(CX + 34, ey - 34, 7, "#fff6cc", 0.95)}${sparkle(Ll + 20, top + 52, 5, "#fff0c0", 0.85)}`;
    for (const x of [s1 + 30, s2 - 8]) out += gem(x, LIP - 10, 5, k2(x) ? "#5ce1ff" : t.gem, p + "lp" + x);
  }
  if (name == "crystal") out += [[s1 + sw + 18, top + 22, 7], [s2 - 16, top + 56, 5], [Rl - 22, top + 40, 6], [Ll + 18, top + 70, 4], [CX + 6, top + 96, 4]].map(([x, y, r]) => sparkle(x, y, r, "#ffffff", 0.95)).join("");
  if (name == "gold") {
    // a ruby set in the middle of the lid
    out += `<ellipse cx="${CX}" cy="${top + 58}" rx="20" ry="16" fill="url(#${p}band)" stroke="${t.ink}" stroke-width="2.2"/>` + gem(CX, top + 58, 9, t.gem, p + "md") + sparkle(Rl - 28, top + 30, 5, "#fff8dc", 0.9);
  }
  if (name == "silver") out += `<ellipse cx="${CX}" cy="${top + 58}" rx="16" ry="12" fill="url(#${p}band)" stroke="${t.ink}" stroke-width="2"/>` + gem(CX, top + 58, 6.5, t.gem, p + "md");

  // hasp hanging over the lock plate
  const hw = name == "champion" ? 17 : 14;
  out += `<path d="M ${CX - hw} ${LIP - 22} L ${CX + hw} ${LIP - 22} L ${CX + hw} ${LIP + 14} Q ${CX} ${LIP + 26} ${CX - hw} ${LIP + 14} Z" fill="url(#${p}band)" stroke="${t.ink}" stroke-width="2.4" stroke-linejoin="round"/>
    <rect x="${CX - hw + 4}" y="${LIP - 19}" width="3" height="${30}" rx="1.5" fill="#fff" opacity="0.4"/>
    ${rivet(CX, LIP - 12, 2.8, t.ink, t.band[0])}${rivet(CX, LIP + 8, 2.4, t.ink, t.band[0])}`;
  return wrap(out);
}

export const many = Object.fromEntries(
  Object.keys(TIERS).flatMap((n) => [[`chest_${n}_base`, () => base(n)], [`chest_${n}_lid`, () => lid(n)]]),
);

export default () => base("gold");

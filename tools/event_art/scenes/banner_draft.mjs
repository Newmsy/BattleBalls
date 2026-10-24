// Draft banner, "pick your trio": under a starry portal gate six critters wait
// on pedestals; three of them have hopped forward onto spotlit pedestals,
// lit up and ready, while the other three wait dimmer at the back.
import { svg, blurs, sparkle, stars } from "./_shop_charge_pad_glow_chest_parts.mjs";
import { critter, shadow, sky, motes, edges, FAM, shade } from "./_banner_parts.mjs";

const GX = 360, GTOP = 34, GW = 172, GBASE = 286; // gate centre, top, half width, base

function backdrop() {
  return `
  <defs>
    <radialGradient id="bdBg" cx="0.5" cy="0.42" r="0.8"><stop offset="0" stop-color="#3a2a86"/><stop offset="0.4" stop-color="#211a5c"/><stop offset="0.75" stop-color="#131036"/><stop offset="1" stop-color="#0D0F26"/></radialGradient>
    <linearGradient id="bdFloor" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2a2170"/><stop offset="0.5" stop-color="#1a1548"/><stop offset="1" stop-color="#0D0F26"/></linearGradient>
  </defs>
  <rect width="720" height="440" fill="url(#bdBg)"/>
  ${sky(12, 120, 0, 0, 720, 270)}
  <ellipse cx="200" cy="110" rx="200" ry="60" fill="#7b5cff" opacity="0.18" filter="url(#bl40)" transform="rotate(-12 200 110)"/>
  <ellipse cx="560" cy="90" rx="180" ry="50" fill="#ff8ad0" opacity="0.12" filter="url(#bl40)" transform="rotate(10 560 90)"/>
  <!-- distant hills -->
  <path d="M 0 262 Q 120 222 240 250 Q 360 230 480 250 Q 600 220 720 258 L 720 300 L 0 300 Z" fill="#1c1652"/>
  <!-- stage floor -->
  <path d="M 0 270 Q 360 250 720 270 L 720 440 L 0 440 Z" fill="url(#bdFloor)"/>
  ${(() => {
    let g = "";
    for (let k = -9; k <= 9; k++) g += `<line x1="${GX + k * 26}" y1="262" x2="${GX + k * 120}" y2="440" stroke="#8f7bff" stroke-width="1" opacity="0.13"/>`;
    for (const y of [282, 304, 334, 374, 424]) g += `<line x1="0" y1="${y}" x2="720" y2="${y}" stroke="#8f7bff" stroke-width="1" opacity="0.1"/>`;
    return g;
  })()}`;
}

function gate() {
  // Arch: two pillars and a round top; the inside is a swirling star portal.
  const inner = `M ${GX - GW + 26} ${GBASE} L ${GX - GW + 26} ${GTOP + GW - 10} A ${GW - 26} ${GW - 26} 0 0 1 ${GX + GW - 26} ${GTOP + GW - 10} L ${GX + GW - 26} ${GBASE} Z`;
  const outer = `M ${GX - GW} ${GBASE} L ${GX - GW} ${GTOP + GW - 10} A ${GW} ${GW} 0 0 1 ${GX + GW} ${GTOP + GW - 10} L ${GX + GW} ${GBASE} Z`;
  let swirl = "";
  for (let k = 0; k < 5; k++) {
    const rr = 40 + k * 26;
    swirl += `<ellipse cx="${GX}" cy="${GTOP + GW + 20}" rx="${rr}" ry="${rr * 0.8}" fill="none" stroke="${k % 2 ? "#3EE6FF" : "#b98cff"}" stroke-width="${3 - k * 0.3}" stroke-dasharray="${30 + k * 14} ${40 + k * 10}" opacity="${0.5 - k * 0.07}" transform="rotate(${k * 37} ${GX} ${GTOP + GW + 20})"/>`;
  }
  let runes = "";
  for (let k = 0; k <= 8; k++) {
    const a = Math.PI + (k * Math.PI) / 8;
    const x = GX + Math.cos(a) * (GW - 13), y = GTOP + GW - 10 + Math.sin(a) * (GW - 13);
    runes += `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="4" fill="${k % 2 ? "#3EE6FF" : "#ffd34e"}"/><circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="9" fill="${k % 2 ? "#3EE6FF" : "#ffd34e"}" opacity="0.35" filter="url(#bl3)"/>`;
  }
  return `
  <defs>
    <radialGradient id="bdPortal" cx="0.5" cy="0.62" r="0.7"><stop offset="0" stop-color="#7f6bff"/><stop offset="0.35" stop-color="#3b2a9a"/><stop offset="0.8" stop-color="#160f48"/><stop offset="1" stop-color="#0e0a30"/></radialGradient>
    <linearGradient id="bdStone" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#2a2468"/><stop offset="0.5" stop-color="#4a40a0"/><stop offset="1" stop-color="#231e5a"/></linearGradient>
    <clipPath id="bdIn"><path d="${inner}"/></clipPath>
  </defs>
  <path d="${outer}" fill="#8f7bff" opacity="0.35" filter="url(#bl16)"/>
  <path d="${outer}" fill="url(#bdStone)" stroke="#120f30" stroke-width="3"/>
  <path d="M ${GX - GW + 8} ${GBASE} L ${GX - GW + 8} ${GTOP + GW - 10} A ${GW - 8} ${GW - 8} 0 0 1 ${GX + GW - 8} ${GTOP + GW - 10} L ${GX + GW - 8} ${GBASE}" fill="none" stroke="#c2b5ff" stroke-width="2" opacity="0.5"/>
  <path d="${inner}" fill="url(#bdPortal)"/>
  <g clip-path="url(#bdIn)">
    ${stars(77, 70, GX - GW, GTOP, GX + GW, GBASE, "#ffffff")}
    ${swirl}
    <ellipse cx="${GX}" cy="${GBASE - 10}" rx="${GW}" ry="60" fill="#c8b8ff" opacity="0.35" filter="url(#bl24)"/>
  </g>
  <path d="${inner}" fill="none" stroke="#3EE6FF" stroke-width="8" opacity="0.55" filter="url(#bl6)"/>
  <path d="${inner}" fill="none" stroke="#c8fbff" stroke-width="2.5"/>
  ${runes}
  <!-- keystone gem -->
  <polygon points="${GX},${GTOP - 14} ${GX + 18},${GTOP + 6} ${GX},${GTOP + 26} ${GX - 18},${GTOP + 6}" fill="#ffd34e" stroke="#8a5a10" stroke-width="2.5"/>
  <polygon points="${GX},${GTOP - 14} ${GX - 18},${GTOP + 6} ${GX - 6},${GTOP + 6} ${GX},${GTOP - 4}" fill="#fff" opacity="0.6"/>
  <circle cx="${GX}" cy="${GTOP + 6}" r="34" fill="#ffd34e" opacity="0.35" filter="url(#bl12)"/>
  <!-- pillar bases -->
  ${[-1, 1].map((d) => `<rect x="${GX + d * (GW - 13) - 24}" y="${GBASE - 10}" width="48" height="16" rx="4" fill="#3a3290" stroke="#120f30" stroke-width="2.5"/>`).join("")}`;
}

// Round pedestal with a glowing rim; lit pedestals throw a spotlight upward.
function pedestal(cx, top, w, col, lit) {
  const h = w * 0.34, ry = w * 0.22;
  return `
  ${lit ? `<path d="M ${cx - w * 0.9} ${top} L ${cx - w * 0.35} -20 L ${cx + w * 0.35} -20 L ${cx + w * 0.9} ${top} Z" fill="${col}" opacity="0.26" filter="url(#bl8)"/>
    <ellipse cx="${cx}" cy="${top + h}" rx="${w * 1.5}" ry="${ry * 1.6}" fill="${col}" opacity="0.35" filter="url(#bl12)"/>` : ""}
  <path d="M ${cx - w} ${top} L ${cx - w} ${top + h} A ${w} ${ry} 0 0 0 ${cx + w} ${top + h} L ${cx + w} ${top} Z" fill="${lit ? shade(col, -0.55) : "#1e1a4a"}" stroke="#0e0b28" stroke-width="2"/>
  <path d="M ${cx - w} ${top + h * 0.45} A ${w} ${ry} 0 0 0 ${cx + w} ${top + h * 0.45}" fill="none" stroke="${lit ? col : "#4a4294"}" stroke-width="${lit ? 3 : 2}" opacity="${lit ? 0.9 : 0.5}"/>
  <ellipse cx="${cx}" cy="${top}" rx="${w}" ry="${ry}" fill="${lit ? shade(col, -0.2) : "#2c2664"}" stroke="${lit ? shade(col, 0.5) : "#4a4294"}" stroke-width="${lit ? 3 : 2}"/>
  ${lit ? `<ellipse cx="${cx}" cy="${top}" rx="${w * 0.8}" ry="${ry * 0.7}" fill="${shade(col, 0.6)}" opacity="0.55" filter="url(#bl4)"/>` : ""}`;
}

function dim(content) {
  return `<g opacity="0.92">${content}</g>`;
}

export default () => {
  // Back row (waiting): sweet, toybox, spooky.
  const back = [
    [96, 246, 31, FAM.sweet, "ears", [0.5, 0.2]],
    [360, 180, 26, FAM.toybox, "propeller", [0, 0.6]],
    [624, 246, 31, FAM.spooky, "horns", [-0.5, 0.2]],
  ];
  // Front row (picked): nature, fire (centre), sea.
  const front = [
    [222, 292, 51, FAM.nature, "leaf", "happy", [0.2, -0.2], -6],
    [360, 306, 60, FAM.fire, "flame", "determined", [0, 0.1], 0],
    [498, 292, 51, FAM.sea, "fin", "happy", [-0.2, -0.2], 6],
  ];
  let backArt = "";
  for (const [x, y, r, col, acc, look] of back) {
    const art = `${pedestal(x, y + r * 0.92, r * 1.05, col, false)}${critter(x, y, r, col, { acc, look, mood: "happy" })}`;
    backArt += `<g>${art}<g opacity="0.42"><ellipse cx="${x}" cy="${y - r * 0.2}" rx="${r * 1.35}" ry="${r * 1.7}" fill="#0D0F26" filter="url(#bl4)"/></g></g>`;
  }
  let frontPeds = "", frontArt = "";
  for (const [k, [x, y, r, col, acc, mood, look, tilt]] of front.entries()) {
    frontPeds += pedestal(x, y + r * 0.92, r * 1.12, col, true);
    // Each pick idles on its own living layer (render.mjs), out of step.
    frontArt += `
      <circle cx="${x}" cy="${y}" r="${r * 1.45}" fill="${col}" opacity="0.4" filter="url(#bl16)"/>
      ${shadow(x, y + r * 0.95, r * 0.8, 0.45)}
      <g data-layer="pick${k}" data-move="idle 4 0.6 ${(k / 3).toFixed(2)}">${critter(x, y, r, col, { acc, mood, look, tilt, rim: "#fff0c8", rimSide: x < 360 ? 1 : x > 360 ? -1 : 1 })}</g>`;
  }
  // Hop arcs: little dotted bounce trails from the back line to each pick.
  const hops = [
    [130, 262, 196, 276],
    [590, 262, 524, 276],
  ].map(([x0, y0, x1, y1]) => `<path d="M ${x0} ${y0} Q ${(x0 + x1) / 2} ${y0 - 60} ${x1} ${y1 - 40}" fill="none" stroke="#fff" stroke-width="2.5" stroke-dasharray="2 8" stroke-linecap="round" opacity="0.4"/>`).join("");
  const spark =
    sparkle(158, 222, 9, "#c8ffd8") + sparkle(296, 226, 11, "#ffe0b0") + sparkle(430, 218, 10, "#ffe0b0") + sparkle(568, 222, 9, "#c8f0ff") +
    sparkle(270, 330, 6, "#fff", 0.8) + sparkle(452, 340, 6, "#fff", 0.8);
  return svg(`${blurs()}
  ${backdrop()}
  ${gate()}
  ${backArt}
  ${motes(5, 26, 140, 160, 580, 400, ["#ffd34e", "#3EE6FF", "#c8b8ff", "#5CFF9A"])}
  ${hops}
  ${frontPeds}
  ${frontArt}
  ${spark}
  ${edges()}`);
};

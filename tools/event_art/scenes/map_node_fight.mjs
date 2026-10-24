// Map node token: a normal fight. Two critter balls smack together with a
// bright impact burst between them, on a cyan badge.
import { ball, eye, burst, INK } from "../../brand/parts.mjs";
import { token, twinkle } from "./_map_token.mjs";

export const size = [160, 160];
export const transparent = true;

const CY = "#3ee6ff";

export default () =>
  token(CY, `
  <!-- motion streaks -->
  <g stroke-linecap="round" opacity="0.7">
    <line x1="22" y1="104" x2="40" y2="98" stroke="${CY}" stroke-width="5"/>
    <line x1="26" y1="118" x2="42" y2="111" stroke="${CY}" stroke-width="4" opacity="0.6"/>
    <line x1="138" y1="58" x2="120" y2="64" stroke="#ff6aa8" stroke-width="5"/>
    <line x1="134" y1="44" x2="118" y2="51" stroke="#ff6aa8" stroke-width="4" opacity="0.6"/>
  </g>
  ${ball(54, 98, 27, CY, { sx: 0.88, sy: 1.06, glow: true })}
  ${ball(106, 64, 25, "#ff6aa8", { sx: 0.88, sy: 1.06, glow: true })}
  <!-- determined faces, eyes locked on each other -->
  ${eye(48, 96, 6, 7.5, 1, -0.8, 3.6)}${eye(62, 94, 5.2, 6.8, 1, -0.8, 3.2)}
  <line x1="42" y1="85" x2="55" y2="89" stroke="${INK}" stroke-width="3.2" stroke-linecap="round"/>
    <path d="M 50 110 Q 56 107 62 110" fill="none" stroke="${INK}" stroke-width="3" stroke-linecap="round"/>
  ${eye(112, 62, 5.8, 7.2, -1, 0.8, 3.4)}${eye(99, 65, 5, 6.5, -1, 0.8, 3)}
  <line x1="118" y1="51" x2="106" y2="55" stroke="${INK}" stroke-width="3.2" stroke-linecap="round"/>
  <path d="M 102 77 Q 108 74 114 77" fill="none" stroke="${INK}" stroke-width="3" stroke-linecap="round"/>
  ${burst(81, 80, 17, 8, 0.2)}
  ${twinkle(118, 104, 6, "#fff6c0", 0.9)}${twinkle(44, 52, 5, "#c8f8ff", 0.85)}`);

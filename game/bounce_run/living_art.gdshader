// A painting that breathes: up to four soft elliptical spots of the picture
// bob, sway or glow, plus a slow light sweep. Render only. The time comes
// from LivingArt (a uniform, not TIME) so it only redraws on the shared
// idle clock and stays cheap on battery.
shader_type canvas_item;

uniform float t = 0.0;
uniform int count = 0;
uniform vec4 spot_rect[4]; // centre x, centre y, radius x, radius y (UV)
uniform vec4 spot_move[4]; // kind (1 bob, 2 sway, 3 glow, 4 flicker), amount, speed (Hz), phase
uniform vec4 glow_col[4];
uniform float sweep = 0.0; // 1 = a soft light band crosses now and then
// Home door paintings (HomePainting) also round their corners and darken
// their top and bottom under the door's words. px_size 0 turns this off.
uniform vec2 px_size = vec2(0.0); // drawn size in pixels
uniform float corner = 0.0; // corner radius in pixels
uniform vec4 fade = vec4(0.0); // top fade end (0-1 of the height), its strength, bottom fade start, its strength
uniform vec3 fade_col = vec3(0.05, 0.06, 0.15);
varying vec2 local;

void vertex() {
	local = VERTEX;
}

float mask(vec2 uv, vec4 r) {
	vec2 d = (uv - r.xy) / r.zw;
	return 1.0 - smoothstep(0.55, 1.0, length(d));
}

void fragment() {
	vec2 uv = UV;
	vec3 add = vec3(0.0);
	for (int i = 0; i < 4; i++) {
		if (i >= count) break;
		vec4 r = spot_rect[i];
		vec4 m = spot_move[i];
		float w = sin(6.2831853 * (t * m.z + m.w));
		if (m.x < 1.5) {
			uv.y -= m.y * w * mask(UV, r); // bob
		} else if (m.x < 2.5) {
			uv.x -= m.y * w * mask(UV, r) * (r.y + r.w - UV.y) / (2.0 * r.w); // sway, pinned at the bottom
		}
	}
	vec4 c = texture(TEXTURE, uv);
	for (int i = 0; i < 4; i++) {
		if (i >= count) break;
		vec4 m = spot_move[i];
		if (m.x > 2.5) {
			float w = m.x < 3.5 ? 0.5 + 0.5 * sin(6.2831853 * (t * m.z + m.w))
				: 0.5 + 0.25 * sin(6.2831853 * (t * m.z + m.w)) + 0.25 * sin(6.2831853 * (t * m.z * 2.7 + m.w));
			add += glow_col[i].rgb * m.y * w * mask(UV, spot_rect[i]) * (0.4 + c.rgb);
		}
	}
	if (sweep > 0.0) {
		float x = fract(t * 0.07) * 3.0 - 1.0; // crosses in the first third of each 14 s
		float band = exp(-pow((UV.x + UV.y * 0.35 - x) * 6.0, 2.0));
		add += vec3(0.10, 0.11, 0.16) * band * sweep * c.rgb * 2.0;
	}
	vec3 rgb = c.rgb + add;
	float a = c.a;
	if (px_size.x > 0.0) {
		float y = local.y / px_size.y;
		float shade = max(fade.y * (1.0 - smoothstep(0.0, fade.x, y)), fade.w * smoothstep(fade.z, 1.0, y));
		rgb = mix(rgb, fade_col, shade);
		vec2 q = abs(local - px_size * 0.5) - (px_size * 0.5 - corner);
		a *= 1.0 - smoothstep(-0.75, 0.75, length(max(q, 0.0)) - corner);
	}
	COLOR = vec4(rgb, a) * COLOR;
}

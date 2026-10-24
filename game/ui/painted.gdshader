// A painting inside a rounded frame (painted.gd): corners cut by a rounded-rect
// mask, optional dark scrims at the top / right / bottom so text reads on it,
// and an optional fade to transparent at the bottom so it melts into its card.
shader_type canvas_item;

uniform vec2 size = vec2(100.0);
uniform vec4 radius = vec4(0.0); // top-left, top-right, bottom-right, bottom-left
uniform float top_dark = 0.0; // darkening at the top edge, fading out by 45%
uniform float right_dark = 0.0; // darkening at the right edge, fading out by 35%
uniform float bottom_dark = 0.0; // darkening at the bottom edge, fading out by 40%
uniform float bottom_fade = 0.0; // the lowest share of the height that fades to transparent
uniform vec3 dark = vec3(0.043, 0.039, 0.122);

varying vec2 local;

void vertex() {
	local = VERTEX;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	vec2 uv = local / size;
	float d = top_dark * smoothstep(0.45, 0.0, uv.y)
		+ right_dark * smoothstep(0.35, 1.0, uv.x)
		+ bottom_dark * smoothstep(0.6, 1.0, uv.y);
	c.rgb = mix(c.rgb, dark, clamp(d, 0.0, 0.92));
	if (bottom_fade > 0.0)
		c.a *= smoothstep(1.0, 1.0 - bottom_fade, uv.y);
	// Rounded corners: distance into the corner circle of whichever quadrant.
	float r = uv.x < 0.5 ? (uv.y < 0.5 ? radius.x : radius.w) : (uv.y < 0.5 ? radius.y : radius.z);
	vec2 q = abs(local - size * 0.5) - (size * 0.5 - vec2(r));
	float dist = length(max(q, 0.0)) - r;
	c.a *= clamp(0.5 - dist, 0.0, 1.0);
	COLOR = c;
}

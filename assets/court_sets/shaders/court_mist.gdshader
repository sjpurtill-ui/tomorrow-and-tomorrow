shader_type spatial;
// The red mist that paints the hall (the cannon): laid over the whole view,
// a blotched red veil that drips at the top edge, then drains away.
render_mode unshaded, blend_mix, depth_test_disabled, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec3 colour : source_color = vec3(0.78, 0.04, 0.07);
uniform float amount = 0.0;
uniform float seed = 0.0;

void vertex() {
	POSITION = vec4(VERTEX.xy * 2.0, 0.0, 1.0);
}

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash2(i), hash2(i + vec2(1, 0)), f.x), mix(hash2(i + vec2(0, 1)), hash2(i + vec2(1, 1)), f.x), f.y);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float blot = noise2(uv * vec2(9.0, 5.0) + seed) * 0.6 + noise2(uv * vec2(23.0, 13.0) - seed) * 0.4;
	// drips run down from the top as the mist settles
	float drip = smoothstep(0.55, 0.9, noise2(vec2(uv.x * 40.0 + seed, 0.0))) * (1.0 - smoothstep(0.0, 0.35 * amount, 1.0 - uv.y));
	float a = clamp(amount * (0.45 + 0.6 * blot) + drip * 0.6 * amount, 0.0, 0.92);
	ALBEDO = colour * (0.8 + 0.3 * blot);
	ALPHA = a;
}

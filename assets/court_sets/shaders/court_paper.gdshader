shader_type spatial;
// Laid over the whole view, nearest the lens: the court is a painting on warm
// paper. The corners sink into a soft brown vignette, a fixed paper grain sits
// over everything (it does not crawl), and the light is graded a touch warm.
render_mode unshaded, blend_mix, depth_test_disabled, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec3 vignette_colour : source_color = vec3(0.16, 0.10, 0.06);
uniform float vignette = 0.42;
uniform float vignette_start = 0.55;
uniform float grain = 0.05;
uniform vec3 paper : source_color = vec3(0.93, 0.86, 0.72);

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
	vec2 e = (uv - 0.5) * 2.0;
	// an oval vignette that follows the frame's own shape
	float r = length(e * vec2(1.0, 0.85));
	float v = smoothstep(vignette_start, 1.45, r) * vignette;
	// paper: a fixed fibre grain at the screen's own scale
	vec2 px = uv * VIEWPORT_SIZE;
	float fib = noise2(px * 0.55) * 0.5 + noise2(px * 0.13 + 7.0) * 0.3 + noise2(vec2(px.x * 0.04, px.y * 0.6)) * 0.2;
	float g = (fib - 0.5) * grain;
	vec3 col = mix(paper, vignette_colour, step(0.0, -g));
	ALBEDO = mix(col, vignette_colour, clamp(v / max(v + abs(g), 1e-4), 0.0, 1.0));
	ALPHA = clamp(v + abs(g), 0.0, 1.0);
}

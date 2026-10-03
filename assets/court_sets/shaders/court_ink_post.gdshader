shader_type spatial;
// The court's ink line, drawn once over the whole stage (a quad on the lens),
// in place of the inked shells round every figure and every piece of the set.
// It works from depth alone (the game's renderer keeps no normal buffer):
// where the inverse depth is not flat across a pixel's neighbours there is a
// silhouette or a fold, and it is inked, a little outside the nearer form as
// the old shells were. Lines are thicker near, thinner far, waver a little as
// a brush does, and lift here and there. Transparent things (fire, smoke, the
// ink-wash distance with its own ridge line) are not in the depth: no line.
render_mode unshaded, blend_mix, depth_test_disabled, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest, repeat_disable;
uniform vec3 ink : source_color = vec3(0.17, 0.13, 0.09);
uniform float width_near = 2.2;
uniform float width_far = 1.1;
uniform float near_dist = 3.0;
uniform float far_dist = 26.0;
// how far from flat (relative, in inverse depth) a line starts and is full
uniform float edge_lo = 0.012;
uniform float edge_hi = 0.045;
uniform float strength = 1.0;
uniform float wobble_px = 0.6;
uniform float lift = 0.25;
// lines fade out beyond this distance (the far land has its own wash line)
uniform float fade_from = 30.0;
uniform float fade_to = 60.0;
// 1: show the depth as grey (to check what the line sees)
uniform int debug = 0;

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

// view depth (metres) at a screen point; the sky gives a very large number
float view_z(vec2 uv, mat4 inv_proj) {
	float d = texture(depth_tex, uv).r;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec3 ndc = vec3(uv, d) * 2.0 - 1.0;
#else
	vec3 ndc = vec3(uv * 2.0 - 1.0, d);
#endif
	vec4 v = inv_proj * vec4(ndc, 1.0);
	return max(-v.z / v.w, 0.01);
}

void fragment() {
	vec2 px = 1.0 / VIEWPORT_SIZE;
	vec2 uv = SCREEN_UV;
	// a brush's waver: the samples shift a fraction of a pixel along the line
	vec2 wob = vec2(noise2(uv * VIEWPORT_SIZE * 0.035), noise2(uv * VIEWPORT_SIZE * 0.035 + 17.0)) - 0.5;
	uv += wob * wobble_px * px;
	float zc = view_z(uv, INV_PROJECTION_MATRIX);
	float w = mix(width_near, width_far, smoothstep(near_dist, far_dist, zc));
	vec2 o = px * w;
	float ic = 1.0 / zc;
	float worst = 0.0;
	float nearer = 0.0;
	// four directions: across, up, and the two diagonals
	for (int k = 0; k < 8; k++) {
		int j = k % 4;
		vec2 dir = j == 0 ? vec2(1.0, 0.0) : (j == 1 ? vec2(0.0, 1.0) : (j == 2 ? vec2(0.7071, 0.7071) : vec2(0.7071, -0.7071)));
		vec2 step_o = o * (k < 4 ? 1.0 : 0.5);
		float za = view_z(uv + dir * step_o, INV_PROJECTION_MATRIX);
		float zb = view_z(uv - dir * step_o, INV_PROJECTION_MATRIX);
		float ia = 1.0 / za;
		float ib = 1.0 / zb;
		// flat ground or a flat wall has a straight inverse depth: no line
		float bend = abs(ia + ib - 2.0 * ic) / max(ic, 1e-4);
		worst = max(worst, bend);
		// is a neighbour nearer than us (we are just outside a nearer form)?
		nearer = max(nearer, min(za, zb) * 1.04 < zc ? 1.0 : 0.0);
	}
	float line = smoothstep(edge_lo, edge_hi, worst);
	// lines sit outside the nearer form, as the shells did; folds inside stay light
	line *= mix(0.4, 1.0, nearer);
	// the brush lifts now and then, and thins in the distance
	float lifted = 1.0 - lift * smoothstep(0.55, 0.85, noise2(uv * VIEWPORT_SIZE * 0.012 + 3.0));
	line *= lifted * (1.0 - smoothstep(fade_from, fade_to, zc));
	ALBEDO = ink;
	ALPHA = clamp(line * strength, 0.0, 1.0);
	if (debug == 1) {
		// red: view depth / 20 m; green: the raw depth x 20; blue: the line
		ALBEDO = vec3(clamp(zc / 20.0, 0.0, 1.0), clamp(texture(depth_tex, SCREEN_UV).r * 20.0, 0.0, 1.0), line);
		ALPHA = 1.0;
	}
}

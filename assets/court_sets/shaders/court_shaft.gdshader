shader_type spatial;
// The sun's shaft through the smoke hole: a soft column of lit smoke,
// brightest in its heart, fading at its edges and toward the floor; slow
// wisps drift through it.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec3 colour : source_color = vec3(1.0, 0.86, 0.62);
uniform float strength = 0.22;
// 0: a crisp column; 1: soft all the way, its edges lost in the air
uniform float soft = 0.0;
// where along the shaft (0 top, 1 foot) it fades out: a beam onto someone
// fades above their head, so it never paints over them (the pool lights them)
uniform float fade_from = 0.82;
uniform float fade_to = 1.0;

varying vec3 v_local;
varying vec3 v_world;

void vertex() {
	v_local = VERTEX;
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash3(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.1, 0.2, 0.3));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise3(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash3(i), hash3(i + vec3(1, 0, 0)), f.x), mix(hash3(i + vec3(0, 1, 0)), hash3(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(hash3(i + vec3(0, 0, 1)), hash3(i + vec3(1, 0, 1)), f.x), mix(hash3(i + vec3(0, 1, 1)), hash3(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

void fragment() {
	// the cylinder runs -0.5..0.5 along its own y; the top is the hole
	float along = clamp(0.5 - v_local.y, 0.0, 1.0);
	float edge = pow(clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), mix(1.6, 3.5, soft));
	float wisp = noise3(v_world * 1.4 + vec3(0.0, -TIME * 0.12, TIME * 0.05)) * 0.6 + noise3(v_world * 3.1 + vec3(TIME * 0.07, 0.0, 0.0)) * 0.4;
	float a = edge * (0.55 + 0.9 * wisp) * mix(1.0, 0.35, along) * smoothstep(0.0, mix(0.08, 0.3, soft), along) * (1.0 - smoothstep(min(fade_from, mix(0.82, 0.5, soft)), fade_to, along));
	ALBEDO = colour * a * strength;
}

shader_type spatial;
// The court's sets (assets/court_sets, made by tools/blender/court_set.py):
// painted, not photographed. Real lights (the sun, the fire, the bounce) fall
// on it in two soft tones, the way the figures' toon shader shades them; the
// baked shade in the hollows (vertex R) darkens the paint, trodden or handled
// places (vertex G) wear toward a second colour, each piece varies a little
// (vertex B), and a slow mottle and a paper grain keep big surfaces painterly.
// Far pieces sink into the haze of the air.
render_mode cull_back, depth_draw_opaque, specular_disabled;

uniform vec3 albedo : source_color = vec3(0.5, 0.45, 0.4);
uniform vec3 albedo_worn : source_color = vec3(0.5, 0.45, 0.4);
uniform float variation = 0.10;
uniform float mottle = 0.10;
uniform float mottle_scale = 0.55;
uniform float grain = 0.05;
uniform float ao_amount = 1.0;
uniform float band_soft = 0.22;
uniform float wrap = 0.0;
uniform float half_tone = 0.22;
uniform vec3 emission_color : source_color = vec3(1.0, 0.42, 0.10);
uniform float emission_amount = 0.0;
uniform float emission_flicker = 0.0;
uniform vec3 haze_color : source_color = vec3(0.78, 0.80, 0.80);
uniform float haze_start = 40.0;
uniform float haze_end = 160.0;
uniform float haze_max = 0.0;
uniform float rim_amount = 0.0;

varying vec4 v_col;
varying vec3 v_world;

void vertex() {
	v_col = COLOR;
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
	vec3 base = mix(albedo, albedo_worn, clamp(v_col.g, 0.0, 1.0));
	base *= 1.0 + (v_col.b - 0.5) * 2.0 * variation;
	float m = noise3(v_world * mottle_scale) * 0.65 + noise3(v_world * mottle_scale * 2.7 + 3.1) * 0.35;
	base *= 1.0 + (m - 0.5) * 2.0 * mottle;
	float g = noise3(v_world * 38.0) * 0.6 + noise3(v_world * 11.0) * 0.4;
	base *= 1.0 + (g - 0.5) * grain;
	float ao = mix(1.0, v_col.r, ao_amount);
	base *= mix(1.0, ao, 0.55);
	float dist = length(v_world - CAMERA_POSITION_WORLD);
	float haze = haze_max * smoothstep(haze_start, haze_end, dist);
	ALBEDO = mix(base, haze_color, haze);
	AO = ao;
	AO_LIGHT_AFFECT = 0.25;
	ROUGHNESS = 1.0;
	float flick = 1.0;
	if (emission_flicker > 0.0) {
		flick = 1.0 - emission_flicker + emission_flicker * (0.55 + 0.45 * sin(TIME * 7.3 + v_world.x * 9.0 + v_world.z * 5.0) * sin(TIME * 3.1 + v_world.z * 7.0));
	}
	EMISSION = emission_color * emission_amount * flick + haze_color * haze * 0.55;
	if (rim_amount > 0.0) {
		float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
		EMISSION += vec3(1.0, 0.86, 0.66) * rim_amount * fres;
	}
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float lit = smoothstep(-0.04 - wrap, band_soft - wrap, ndl);
	float half_lit = smoothstep(-0.6, -0.15, ndl) * half_tone;
	float tone = max(lit * ATTENUATION, half_lit * min(1.0, ATTENUATION * 1.5));
	DIFFUSE_LIGHT += LIGHT_COLOR * tone / PI;
}

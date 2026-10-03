shader_type spatial;
// A lit twin of J's figure toon (scripts/shaders/court_figure_toon.gdshader),
// offered so the figures take the set's real light: the fire's warm key, the
// sky's fill, the hall's darkness, the door's daylight on their rims, and the
// sun's shadows. Same uniforms, same vertex colours (R baked shade; G/B/A the
// skin an outfit covers), same grain and rim, so a material made by
// CourtFigure3D.material() keeps every parameter when its shader is swapped:
//     made.shader = preload("res://assets/court_sets/shaders/court_figure_lit.gdshader")
// The light() below is the set's own (court_set_toon.gdshader): two soft tones,
// a half-tone, the shade tinted toward the skin's own warm shadow.
// Both sides are drawn: an open garment (a hide cape, a sleeve's mouth) shows
// its inside, not the ink shell behind it (the black holes of a one-sided toon).
render_mode cull_disabled, depth_draw_opaque, specular_disabled;

uniform vec3 albedo : source_color = vec3(0.6, 0.5, 0.4);
uniform vec3 shade_tint : source_color = vec3(0.56, 0.46, 0.44);
uniform vec3 key_dir = vec3(-0.35, 0.65, 0.68);
uniform vec3 key_color : source_color = vec3(1.0, 0.97, 0.92);
uniform vec3 rim_color : source_color = vec3(1.0, 0.84, 0.60);
uniform float rim_amount = 0.14;
uniform float ao_amount = 1.0;
uniform float band_soft = 0.16;
uniform float grain = 0.05;
uniform int cover_channel = 0;
uniform bool flat_colour = false;
// How much of the old fixed key still shows (0: the set's lights only).
uniform float fixed_key = 0.0;
instance uniform float dim = 1.0;

varying float v_ao;
varying float v_cover;
varying vec3 v_obj;

void vertex() {
	v_ao = COLOR.r;
	v_cover = cover_channel == 1 ? COLOR.g : (cover_channel == 2 ? COLOR.b : (cover_channel == 3 ? COLOR.a : 0.0));
	v_obj = VERTEX;
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
	if (v_cover > 0.5) {
		discard;
	}
	vec3 base = albedo * mix(1.0, v_ao, ao_amount);
	if (!flat_colour) {
		float g = noise3(v_obj * 46.0) * 0.6 + noise3(v_obj * 13.0) * 0.4;
		base *= 1.0 + (g - 0.5) * grain;
	}
	ALBEDO = base * dim;
	ROUGHNESS = 1.0;
	AO = mix(1.0, v_ao, ao_amount);
	AO_LIGHT_AFFECT = 0.35;
	if (!flat_colour) {
		float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
		EMISSION = rim_color * rim_amount * fres * base * 0.6 * dim;
		if (fixed_key > 0.0) {
			vec3 n = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
			float ndl = dot(n, normalize(key_dir));
			EMISSION += base * key_color * smoothstep(-0.02, band_soft, ndl) * fixed_key * dim;
		}
	}
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float lit = smoothstep(-0.02, band_soft, ndl);
	float half_lit = smoothstep(-0.42, -0.18, ndl) * 0.30;
	float tone = max(lit * ATTENUATION, half_lit * min(1.0, ATTENUATION * 1.5));
	// the shade side keeps a warm tint of the skin's own shadow, not grey
	vec3 tint = mix(shade_tint, vec3(1.0), tone);
	DIFFUSE_LIGHT += LIGHT_COLOR * tint * tone / PI;
	if (flat_colour) {
		DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * 0.15 / PI;
	}
}

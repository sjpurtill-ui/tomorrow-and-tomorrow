shader_type spatial;
// Court figures standing in a modelled court (scripts/hud/court_set_3d.gd):
// the same painted look as court_figure_toon.gdshader, but lit by the set's
// own lights (the sun or the shaft from the smoke hole, the fire, the warm
// bounce), in two soft tones as the set itself is shaded, so a person stands
// IN the light of the place and in the shadows of its posts and of each other.
// Vertex colour R is the baked shade; on the body, G/B/A mark skin covered by
// the hide, tunic and robe outfits: the worn outfit's channel is hidden.
render_mode cull_back, depth_draw_opaque, specular_disabled;

uniform vec3 albedo : source_color = vec3(0.6, 0.5, 0.4);
uniform vec3 shade_tint : source_color = vec3(0.56, 0.46, 0.44);
uniform vec3 key_dir = vec3(-0.35, 0.65, 0.68);
uniform vec3 key_color : source_color = vec3(1.0, 0.97, 0.92);
uniform vec3 rim_color : source_color = vec3(1.0, 0.84, 0.60);
uniform float rim_amount = 0.14;
uniform float ao_amount = 1.0;
uniform float band_soft = 0.10;
uniform float grain = 0.05;
uniform int cover_channel = 0;
// Skin: the edge between light and shade warms, as light does under skin.
uniform vec3 terminator : source_color = vec3(0.0, 0.0, 0.0);
uniform bool flat_colour = false;
// Hair and beards: fine strands down the fall of the hair, and a soft sheen.
uniform float strands = 0.0;
uniform float sheen = 0.0;
// How much of its own colour a person keeps where no light reaches (warm, never black).
uniform float fill = 0.16;
// How dark the sun's shadows fall on a person (1: as dark as on the ground).
uniform float shadow_amount = 0.6;
// Per figure: the speaker a little in the light, listeners a little back.
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
	vec3 base = albedo * mix(1.0, v_ao, ao_amount * 0.8);
	if (!flat_colour) {
		float g = noise3(v_obj * 46.0) * 0.6 + noise3(v_obj * 13.0) * 0.4;
		base *= 1.0 + (g - 0.5) * grain;
	}
	if (strands > 0.0) {
		// streaks that run down the hair, finer across than along
		float s = noise3(vec3(v_obj.x * 210.0, v_obj.y * 16.0, v_obj.z * 210.0)) * 0.65 + noise3(vec3(v_obj.x * 90.0, v_obj.y * 7.0, v_obj.z * 90.0)) * 0.35;
		base *= 1.0 + (s - 0.5) * strands * 2.0;
	}
	ALBEDO = base * dim;
	ROUGHNESS = 1.0;
	AO = mix(1.0, v_ao, 0.5);
	AO_LIGHT_AFFECT = 0.2;
	// a warm floor of colour in the deepest shade, and a rim of the sky
	vec3 glow = base * shade_tint * fill * dim;
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	glow += rim_color * rim_amount * fres * 0.35;
	if (sheen > 0.0) {
		// a band of light along the hair, where it turns toward the key
		vec3 n = normalize(NORMAL);
		vec3 key_view = normalize((VIEW_MATRIX * vec4(key_dir, 0.0)).xyz);
		float band = smoothstep(0.55, 0.85, dot(n, normalize(key_view + VIEW)));
		glow += albedo * key_color * band * sheen * 1.4;
	}
	EMISSION = glow;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	if (flat_colour) {
		DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * 0.9 / PI;
	} else {
		float lit = smoothstep(-0.02, band_soft, ndl);
		float half_lit = smoothstep(-0.42, -0.18, ndl) * 0.30;
		// The sun's shadows fall on a person softened (their own hair and arms
		// would stipple them); the fire's reach is as it is.
		float att = LIGHT_IS_DIRECTIONAL ? mix(1.0, ATTENUATION, shadow_amount) : ATTENUATION;
		float tone = max(lit * att, half_lit * min(1.0, att * 1.5));
		float edge = clamp(tone * (1.0 - tone) * 4.0, 0.0, 1.0);
		DIFFUSE_LIGHT += LIGHT_COLOR * (vec3(tone) + terminator * edge * 0.30) / PI;
	}
}

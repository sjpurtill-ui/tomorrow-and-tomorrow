shader_type spatial;
// Court figures standing in a modelled court (scripts/hud/court_set_3d.gd):
// the same painted look as court_figure_toon.gdshader, but lit by the set's
// own lights (the sun or the shaft from the smoke hole, the fire, the warm
// bounce), in two soft tones as the set itself is shaded, so a person stands
// IN the light of the place and in the shadows of its posts and of each other.
// Vertex colour R is the baked shade; on the body, G/B/A mark skin covered by
// the hide, tunic and robe outfits: the worn outfit's channel is hidden.
// Both sides are drawn (M's lit twin): an open garment, a cape or a sleeve's
// mouth shows its inside, not a black hole; the shade side keeps a warm tint.
render_mode cull_disabled, depth_draw_opaque;

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
// Hair and beards: where they meet the skin (vertex colour G, baked by
// court_figures.py) they break into strokes over it, never a cut edge;
// stubble is strokes all over. UV is the rest position, so it keeps still.
uniform float stipple = 0.0;
// The painted face (Body skin) and hair cards: court_figure_face.gdshaderinc.
uniform bool face_paint = false;
uniform float card = 0.0;
uniform bool skin = false;
uniform bool brow = false;
uniform bool teeth = false;
instance uniform vec4 face_a = vec4(0.0);
instance uniform vec4 face_b = vec4(0.0);
// How much of its own colour a person keeps where no light reaches (warm, never black).
uniform float fill = 0.16;
// How dark the sun's shadows fall on a person (1: as dark as on the ground).
uniform float shadow_amount = 0.6;
// A soft light from where we look (the god's eye): a face turned to us is
// never lost in the dark, however the place is lit behind it.
uniform float front_fill = 0.30;
// Per figure: the speaker a little in the light, listeners a little back.
instance uniform float dim = 1.0;

varying float v_ao;
varying float v_cover;
varying float v_edge;
varying vec2 v_rest;
varying vec2 v_face2;
varying vec2 v_face;
varying float v_card;
varying vec3 v_obj;

void vertex() {
	v_ao = COLOR.r;
	v_cover = cover_channel == 1 ? COLOR.g : (cover_channel == 2 ? COLOR.b : (cover_channel == 3 ? COLOR.a : 0.0));
	v_obj = VERTEX;
	v_edge = COLOR.g;
	v_rest = UV;
	// glTF stores V flipped (1 - v): the face's up, a card's along
	v_face2 = vec2(UV2.x, 1.0 - UV2.y);
	v_face = vec2(UV.x, 1.0 - UV.y);
	v_card = COLOR.b;
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

#include "res://scripts/shaders/court_figure_face.gdshaderinc"

// How deep a skin is (0 the fairest, 1 the deepest), from its colour.
float skin_depth() {
	float lum = dot(albedo, vec3(0.299, 0.587, 0.114));
	return 1.0 - smoothstep(0.03, 0.45, lum);
}

void fragment() {
	if (brow && texture(brow_mask, v_rest).a < 0.32) { discard; }
	if (v_cover > 0.5) {
		discard;
	}
	if (card > 0.0) {
		// a card of strands: it thins toward its end and its sides
		float n_card = noise3(vec3(v_face.x * 9.0 + v_card * 40.0, v_face.y * 0.8, v_card * 13.0));
		if (!card_strand(v_face, v_card, n_card)) {
			discard;
		}
	}
	if (stipple > 0.0) {
		float st = noise3(vec3(v_rest.x * 900.0, v_rest.y * 330.0, 0.5)) * 0.7 + noise3(vec3(v_rest.x * 2100.0, v_rest.y * 700.0, 3.1)) * 0.3;
		if (st < v_edge * 1.1 * stipple - 0.1) {
			discard;
		}
	}
	vec3 base = albedo * mix(1.0, v_ao, ao_amount * 0.8);
	if (teeth) { base *= texture(teeth_mask, v_rest).rgb; }
	if (face_paint) {
		base = paint_face(base, v_face, v_face2, face_a, face_b, skin_depth());
		NORMAL = face_normal(VERTEX, normalize(NORMAL), v_face, v_face2, face_a.x);
	}
	if (card > 0.0) {
		base *= (0.94 + 0.12 * v_card) * (0.90 + 0.20 * noise3(vec3(v_face.x * 30.0 + v_card * 9.0, v_face.y * 2.0, 1.7)));
	}
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
	float facing = clamp(dot(normalize(NORMAL), VIEW), 0.0, 1.0);
	glow += base * key_color * front_fill * (skin || flat_colour ? 0.55 : 1.0) * smoothstep(0.15, 0.85, facing) * dim;
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
		// the painted eyes and mouth take the light the face round them takes,
		// a little softer: never brighter than the skin in shadow
		float soft = smoothstep(-0.35, 0.45, ndl);
		DIFFUSE_LIGHT += LIGHT_COLOR * soft * mix(1.0, ATTENUATION, shadow_amount) * 0.9 / PI;
	} else {
		float lit = smoothstep(-0.02, band_soft, ndl);
		float half_lit = smoothstep(-0.42, -0.18, ndl) * 0.30;
		if (skin) {
			lit = 0.10 + 0.90 * smoothstep(-0.35, 0.95, ndl);
			half_lit = 0.0;
		}
		// The sun's shadows fall on a person softened (their own hair and arms
		// would stipple them); the fire's reach is as it is.
		float att = LIGHT_IS_DIRECTIONAL ? mix(1.0, ATTENUATION, shadow_amount) : ATTENUATION;
		float tone = max(lit * att, half_lit * min(1.0, att * 1.5));
		float edge = clamp(tone * (1.0 - tone) * 4.0, 0.0, 1.0);
		// the shade keeps a warm tint of the stuff's own shadow, not grey
		vec3 tint = mix(shade_tint, vec3(1.0), tone);
		vec3 lc = LIGHT_COLOR;
		if (skin) {
			float depth = skin_depth();
			// deep skin keeps its depth: the fire's orange is tamed on it
			float l = dot(lc, vec3(0.299, 0.587, 0.114));
			lc = mix(lc, vec3(l), 0.40 * depth);
			// fair skin: light warms under it at the edge of the shade
			float wrap = smoothstep(-0.45, 0.15, ndl) * (1.0 - lit);
			DIFFUSE_LIGHT += lc * vec3(0.55, 0.20, 0.12) * wrap * att * (1.0 - depth) * 0.55 / PI;
			// deep skin: a cool soft highlight where the light glances back
			float sp = pow(clamp(dot(NORMAL, normalize(LIGHT + VIEW)), 0.0, 1.0), 24.0) * att;
			SPECULAR_LIGHT += mix(LIGHT_COLOR, vec3(l), 0.65) * sp * (0.018 + 0.045 * depth);
		}
		DIFFUSE_LIGHT += lc * (tint * tone + terminator * edge * 0.30) / PI;
	}
}

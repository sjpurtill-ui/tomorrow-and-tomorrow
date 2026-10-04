shader_type spatial;
// Court figures (assets/court_figures, made by tools/blender/court_figures.py):
// flat colour in two soft tones under one key light (the fire, the window),
// baked shade in the hollows, a little paper grain and a warm rim.
// Unshaded on purpose: the stage decides the light, the same on every GPU.
// Vertex colour R is the baked shade; on the body, G/B/A mark skin covered
// by the hide, tunic and robe outfits: the worn outfit's channel is hidden.
render_mode unshaded, cull_back, depth_draw_opaque;

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
instance uniform vec4 face_a = vec4(0.0);
instance uniform vec4 face_b = vec4(0.0);
// Per figure: the speaker a little in the light, listeners a little back.
instance uniform float dim = 1.0;

varying float v_ao;
varying float v_cover;
varying float v_edge;
varying vec2 v_rest;
varying vec2 v_face2;
varying vec2 v_face;
varying float v_card;
varying vec3 v_world_normal;
varying vec3 v_obj;

void vertex() {
	v_ao = COLOR.r;
	v_cover = cover_channel == 1 ? COLOR.g : (cover_channel == 2 ? COLOR.b : (cover_channel == 3 ? COLOR.a : 0.0));
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
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
	vec3 base = albedo * mix(1.0, v_ao, ao_amount);
	if (face_paint) {
		base = paint_face(base, v_face, v_face2, face_a, face_b, skin_depth());
		NORMAL = face_normal(VERTEX, normalize(NORMAL), v_face, v_face2, face_a.x);
	}
	if (card > 0.0) {
		base *= (0.94 + 0.12 * v_card) * (0.90 + 0.20 * noise3(vec3(v_face.x * 30.0 + v_card * 9.0, v_face.y * 2.0, 1.7)));
	}
	if (strands > 0.0) {
		float s = noise3(vec3(v_obj.x * 210.0, v_obj.y * 16.0, v_obj.z * 210.0)) * 0.65 + noise3(vec3(v_obj.x * 90.0, v_obj.y * 7.0, v_obj.z * 90.0)) * 0.35;
		base *= 1.0 + (s - 0.5) * strands * 2.0;
	}
	if (flat_colour) {
		ALBEDO = albedo * min(dim, 1.0);
	} else {
		vec3 n = skin ? normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz) : normalize(v_world_normal);
		float ndl = dot(n, normalize(key_dir));
		float lit = smoothstep(-0.02, band_soft, ndl);
		float half_tone = smoothstep(-0.42, -0.18, ndl) * 0.30;
		float tone = max(lit, half_tone);
		if (skin) {
			tone = 0.10 + 0.90 * smoothstep(-0.35, 0.95, ndl);
		}
		float g = noise3(v_obj * 46.0) * 0.6 + noise3(v_obj * 13.0) * 0.4;
		base *= 1.0 + (g - 0.5) * grain;
		vec3 col = mix(base * shade_tint, base * key_color, tone);
		float edge = clamp(tone * (1.0 - tone) * 4.0, 0.0, 1.0);
		col += base * terminator * edge * 0.35;
		float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
		col += rim_color * rim_amount * fres * (0.35 + 0.65 * lit);
		if (sheen > 0.0) {
			vec3 key_view = normalize((VIEW_MATRIX * vec4(key_dir, 0.0)).xyz);
			float band = smoothstep(0.55, 0.85, dot(normalize(NORMAL), normalize(key_view + VIEW)));
			col += albedo * key_color * band * sheen * 1.4;
		}
		ALBEDO = col * dim;
	}
}

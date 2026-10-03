shader_type spatial;
// One person in a modelled court, drawn in as few pieces as can be: the lit
// figure shader (court_figure_lit.gdshader) for every part of them at once.
// Each figure's visible parts are merged into a handful of meshes
// (court_figure_merge.gd); every vertex says which part it is (CUSTOM0.r, a
// slot: skin, hair, a hair card, brows, mouth, stubble, cloth, leather, wood,
// clay, the lid line, iris, pupil, the catch of light, the white of the eye)
// and the slot's colour and manner come from this figure's arrays. Skinning
// and morphs cost per piece, not per vertex: one piece instead of fifteen.
// Vertex colour R is the baked shade; on the skin G/B/A mark skin an outfit
// covers; on hair G is how near its edge, on a card B is the card's own.
render_mode cull_disabled, depth_draw_opaque;

const int S_SKIN = 0;
const int S_HAIR = 1;
const int S_CARD = 2;
const int S_STUBBLE = 5;

uniform vec3 slot_albedo[17];
// band_soft, rim, strands, sheen
uniform vec4 slot_a[17];
// grain, fill, stipple, card
uniform vec4 slot_b[17];
// flat, skin (painted face, skin's light), cover, unused
uniform vec4 slot_c[17];
uniform vec3 key_dir = vec3(-0.35, 0.65, 0.68);
uniform vec3 key_color : source_color = vec3(1.0, 0.97, 0.92);
uniform vec3 rim_color : source_color = vec3(1.0, 0.84, 0.60);
uniform vec3 skin_shade : source_color = vec3(0.70, 0.52, 0.47);
uniform vec3 other_shade : source_color = vec3(0.56, 0.46, 0.44);
uniform vec3 skin_terminator : source_color = vec3(0.30, 0.10, 0.05);
uniform int cover_channel = 0;
uniform float shadow_amount = 0.6;
uniform float front_fill = 0.30;
instance uniform vec4 face_a = vec4(0.0);
instance uniform vec4 face_b = vec4(0.0);
instance uniform float dim = 1.0;

varying flat int v_slot;
varying float v_ao;
varying float v_cover;
varying float v_edge;
varying vec2 v_rest;
varying vec2 v_face2;
varying vec2 v_face;
varying float v_card;
varying vec3 v_obj;

void vertex() {
	v_slot = int(CUSTOM0.r + 0.5);
	v_ao = COLOR.r;
	v_cover = 0.0;
	if (v_slot == S_SKIN) {
		v_cover = cover_channel == 1 ? COLOR.g : (cover_channel == 2 ? COLOR.b : (cover_channel == 3 ? COLOR.a : 0.0));
	}
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

float slot_depth(vec3 a) {
	float lum = dot(a, vec3(0.299, 0.587, 0.114));
	return 1.0 - smoothstep(0.03, 0.45, lum);
}

void fragment() {
	int s = v_slot;
	if (v_cover > 0.5) {
		discard;
	}
	vec4 pa = slot_a[s];
	vec4 pb = slot_b[s];
	vec4 pc = slot_c[s];
	if (pb.w > 0.0) {
		float n_card = noise3(vec3(v_face.x * 9.0 + v_card * 40.0, v_face.y * 0.8, v_card * 13.0));
		if (!card_strand(v_face, v_card, n_card)) {
			discard;
		}
	}
	if (pb.z > 0.0) {
		float st = noise3(vec3(v_rest.x * 900.0, v_rest.y * 330.0, 0.5)) * 0.7 + noise3(vec3(v_rest.x * 2100.0, v_rest.y * 700.0, 3.1)) * 0.3;
		if (st < v_edge * 1.1 * pb.z - 0.1) {
			discard;
		}
	}
	vec3 albedo = slot_albedo[s];
	bool flat_colour = pc.x > 0.5;
	bool skin = pc.y > 0.5;
	vec3 base = albedo * mix(1.0, v_ao, 0.8);
	if (skin) {
		base = paint_face(base, v_face, v_face2, face_a, face_b, slot_depth(albedo));
	}
	if (pb.w > 0.0) {
		base *= (0.88 + 0.24 * v_card) * (0.86 + 0.28 * noise3(vec3(v_face.x * 30.0 + v_card * 9.0, v_face.y * 2.0, 1.7)));
	}
	if (!flat_colour && pb.x > 0.0) {
		float g = noise3(v_obj * 46.0) * 0.6 + noise3(v_obj * 13.0) * 0.4;
		base *= 1.0 + (g - 0.5) * pb.x;
	}
	if (pa.z > 0.0) {
		float sn = noise3(vec3(v_obj.x * 210.0, v_obj.y * 16.0, v_obj.z * 210.0)) * 0.65 + noise3(vec3(v_obj.x * 90.0, v_obj.y * 7.0, v_obj.z * 90.0)) * 0.35;
		base *= 1.0 + (sn - 0.5) * pa.z * 2.0;
	}
	ALBEDO = base * dim;
	ROUGHNESS = 1.0;
	AO = mix(1.0, v_ao, 0.5);
	AO_LIGHT_AFFECT = 0.2;
	vec3 shade = skin ? skin_shade : other_shade;
	vec3 glow = base * shade * pb.y * dim;
	float facing = clamp(dot(normalize(NORMAL), VIEW), 0.0, 1.0);
	glow += base * key_color * front_fill * smoothstep(0.15, 0.85, facing) * dim;
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	glow += rim_color * pa.y * fres * 0.35;
	if (pa.w > 0.0) {
		vec3 n = normalize(NORMAL);
		vec3 key_view = normalize((VIEW_MATRIX * vec4(key_dir, 0.0)).xyz);
		float band = smoothstep(0.55, 0.85, dot(n, normalize(key_view + VIEW)));
		glow += albedo * key_color * band * pa.w * 1.4;
	}
	EMISSION = glow;
}

void light() {
	int s = v_slot;
	vec4 pa = slot_a[s];
	vec4 pc = slot_c[s];
	float ndl = dot(NORMAL, LIGHT);
	if (pc.x > 0.5) {
		float soft = smoothstep(-0.35, 0.45, ndl);
		DIFFUSE_LIGHT += LIGHT_COLOR * soft * mix(1.0, ATTENUATION, shadow_amount) * 0.9 / PI;
	} else {
		bool skin = pc.y > 0.5;
		float lit = smoothstep(-0.02, pa.x, ndl);
		float half_lit = smoothstep(-0.42, -0.18, ndl) * 0.30;
		float att = LIGHT_IS_DIRECTIONAL ? mix(1.0, ATTENUATION, shadow_amount) : ATTENUATION;
		float tone = max(lit * att, half_lit * min(1.0, att * 1.5));
		float edge = clamp(tone * (1.0 - tone) * 4.0, 0.0, 1.0);
		vec3 tint = mix(skin ? skin_shade : other_shade, vec3(1.0), tone);
		vec3 lc = LIGHT_COLOR;
		vec3 term = vec3(0.0);
		if (skin) {
			float depth = slot_depth(slot_albedo[s]);
			float l = dot(lc, vec3(0.299, 0.587, 0.114));
			lc = mix(lc, vec3(l), 0.40 * depth);
			float wrap = smoothstep(-0.45, 0.15, ndl) * (1.0 - lit);
			DIFFUSE_LIGHT += lc * vec3(0.55, 0.20, 0.12) * wrap * att * (1.0 - depth) * 0.55 / PI;
			float sp = pow(clamp(dot(reflect(-LIGHT, NORMAL), VIEW), 0.0, 1.0), 9.0) * att;
			SPECULAR_LIGHT += vec3(0.80, 0.88, 1.0) * l * sp * 0.12 * depth;
			term = skin_terminator;
		}
		DIFFUSE_LIGHT += lc * (tint * tone + term * edge * 0.30) / PI;
	}
}

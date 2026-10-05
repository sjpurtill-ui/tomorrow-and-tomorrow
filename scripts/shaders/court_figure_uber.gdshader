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

uniform vec3 slot_albedo[18];
// band_soft, rim, strands, sheen
uniform vec4 slot_a[18];
// grain, fill, stipple, card
uniform vec4 slot_b[18];
// flat, skin (painted face, skin's light), glow (shines of itself), unused
uniform vec4 slot_c[18];
uniform vec3 key_dir = vec3(-0.35, 0.65, 0.68);
uniform vec3 key_color : source_color = vec3(1.0, 0.97, 0.92);
uniform vec3 rim_color : source_color = vec3(1.0, 0.84, 0.60);
uniform vec3 skin_shade : source_color = vec3(0.70, 0.52, 0.47);
uniform vec3 other_shade : source_color = vec3(0.56, 0.46, 0.44);
uniform vec3 skin_terminator : source_color = vec3(0.30, 0.10, 0.05);
uniform int cover_channel = 0;
uniform float shadow_amount = 0.6;
uniform float front_fill = 0.30;
// The fire's light thrown back up from the floor, warm, under the chin and nose.
uniform vec3 bounce_color : source_color = vec3(1.0, 0.60, 0.32);
uniform float bounce = 0.16;
// The court's executions (court_figure_gore.gd): what a person becomes. All 0
// on the living, and set only on the materials of someone being put to death.
// gore_inside: a cut-open piece shows red flesh inside its skin (the back faces).
uniform float gore_inside = 0.0;
// charred: soot-black with embers glowing in the cracks; crumble: falls to ash, top down.
uniform float charred = 0.0;
uniform float crumble = 0.0;
// bronze: a gleaming statue (the pose is frozen by the figure).
uniform float bronze = 0.0;
// rug: flattened to a hide on the floor, lying on their back (the figure is
// stilled in its rest pose); rug_roll: rolled up from the feet, 0..1.
uniform float rug = 0.0;
uniform float rug_roll = 0.0;
uniform float rug_height = 1.72;
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
varying float v_height;

void vertex() {
	v_height = VERTEX.y;
	if (rug > 0.0) {
		// lying on their back, head away from the feet, pressed flat and spread
		float h = rug_height;
		vec3 v = VERTEX;
		vec3 flat_pos = vec3(v.x * 1.32, 0.012 + (v.z + 0.16) * 0.045, h * 0.5 - v.y * 1.04);
		// rolled up from the feet (+z end): wound round a cylinder
		float r = 0.07;
		float rolled = rug_roll * h * 1.04;
		float front = h * 0.5 - rolled;
		if (rug_roll > 0.0 && flat_pos.z > front) {
			float u = flat_pos.z - front;
			float a = u / r;
			flat_pos = vec3(flat_pos.x, r - cos(a) * (r - flat_pos.y), front + sin(a) * (r - flat_pos.y));
		}
		VERTEX = mix(VERTEX, flat_pos, rug);
		NORMAL = normalize(mix(NORMAL, vec3(0.0, 1.0, 0.0), rug * 0.85));
	}
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
	if (crumble > 0.0) {
		// ash falls from the top down, in flakes
		float flake = noise3(v_obj * 55.0) * 0.6 + noise3(v_obj * 13.0) * 0.4;
		float top = clamp(v_height / max(rug_height, 0.5), 0.0, 1.0);
		if (flake + (1.0 - top) * 0.9 < crumble * 1.9) {
			discard;
		}
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
	if (s == 17) { base *= texture(teeth_mask, v_rest).rgb; }
	if (s == 16) {
		// The upper lid shades the sclera; its corners turn into the socket.
		float upper_lid = smoothstep(0.30, 1.0, v_rest.y);
		float corners = smoothstep(0.25, 0.50, abs(v_rest.x - 0.5));
		base *= 0.98 - upper_lid * 0.30 - corners * 0.15;
	} else if (s == 13) {
		vec2 iris = (v_rest - 0.5) * 2.0;
		float radius = length(iris);
		float angle = atan(iris.y, iris.x);
		// Radial fibres, an amber inner ring and the dark outer limbus.
		// Fade the fibres when the iris is only a few pixels across.
		float detail = 1.0 - smoothstep(0.045, 0.18, fwidth(radius));
		float fibres = sin(angle * 47.0 + sin(angle * 11.0) * 1.8 + radius * 14.0);
		base *= (1.04 + fibres * 0.16 * detail) * (1.0 - 0.48 * smoothstep(0.77, 1.0, radius));
		base = mix(base, base * vec3(1.22, 1.08, 0.78), face_ell(vec2(radius - 0.49, 0.0), vec2(0.15, 1.0)) * 0.35);
	} else if (s == 15) {
		// A small corneal glint rather than a white button over the pupil.
		if (length(v_rest - 0.5) > 0.34) { discard; }
	} else if (s == 3) {
		if (texture(brow_mask, v_rest).a < 0.32) { discard; }
		float strokes = noise3(vec3(v_rest.x * 75.0, v_rest.y * 6.0, 4.1));
		base *= 0.92 + 0.16 * strokes;
	}
	if (skin) {
		base = paint_face(base, v_face, v_face2, face_a, face_b, slot_depth(albedo));
		NORMAL = face_normal(VERTEX, normalize(NORMAL), v_face, v_face2, face_a.x);
	}
	if (pb.w > 0.0) {
		base *= (0.94 + 0.12 * v_card) * (0.90 + 0.20 * noise3(vec3(v_face.x * 30.0 + v_card * 9.0, v_face.y * 2.0, 1.7)));
	}
	if (!flat_colour && pb.x > 0.0) {
		float g = noise3(v_obj * 46.0) * 0.6 + noise3(v_obj * 13.0) * 0.4;
		base *= 1.0 + (g - 0.5) * pb.x;
	}
	if (pa.z > 0.0) {
		float sn = noise3(vec3(v_obj.x * 210.0, v_obj.y * 16.0, v_obj.z * 210.0)) * 0.65 + noise3(vec3(v_obj.x * 90.0, v_obj.y * 7.0, v_obj.z * 90.0)) * 0.35;
		base *= 1.0 + (sn - 0.5) * pa.z * 2.0;
	}
	if (gore_inside > 0.0 && !FRONT_FACING && s != S_HAIR && s != S_CARD) {
		// cut open: red, wet flesh inside the skin (cloth stays cloth inside)
		float meat = noise3(v_obj * 70.0) * 0.6 + noise3(v_obj * 18.0) * 0.4;
		vec3 flesh = mix(vec3(0.42, 0.02, 0.02), vec3(0.78, 0.10, 0.08), meat);
		if (s == S_SKIN) {
			base = flesh;
		}
	}
	if (bronze > 0.0) {
		// cast bronze: warm metal, greener in the hollows (vertex shade), polished on the high places
		vec3 metal = mix(vec3(0.20, 0.30, 0.20), vec3(0.62, 0.40, 0.16), smoothstep(0.35, 0.9, v_ao));
		metal *= 0.92 + 0.16 * noise3(v_obj * 9.0);
		base = mix(base, metal, bronze);
	}
	if (charred > 0.0) {
		float scorch = smoothstep(noise3(v_obj * 11.0) * 0.55, 0.85, charred);
		vec3 injured = skin ? vec3(0.20, 0.045, 0.025) : base * 0.35;
		vec3 ash = mix(vec3(0.022, 0.017, 0.015), vec3(0.12, 0.105, 0.09), noise3(v_obj * 32.0));
		base = mix(mix(base, injured, charred), ash, scorch);
	}
	ALBEDO = base * dim;
	ROUGHNESS = 1.0;
	AO = mix(1.0, v_ao, 0.5);
	AO_LIGHT_AFFECT = 0.2;
	float depth = skin ? slot_depth(albedo) : 0.0;
	vec3 shade = skin ? mix(skin_shade, vec3(0.50, 0.56, 0.74), 0.55 * depth) : other_shade;
	vec3 glow = base * shade * pb.y * dim;
	float facing = clamp(dot(normalize(NORMAL), VIEW), 0.0, 1.0);
	float face_fill = skin ? 0.55 : (flat_colour ? 0.55 : 1.0);
	glow += base * key_color * front_fill * face_fill * smoothstep(0.15, 0.85, facing) * dim;
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	// deep skin takes a cool rim from the sky, so its features part from each other
	vec3 rim = skin ? mix(rim_color, vec3(0.62, 0.76, 1.0), depth) : rim_color;
	glow += rim * (pa.y + 0.22 * depth) * fres * 0.35;
	// the fire's light from the floor, under the chin, the nose and the brows
	vec3 n_world = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	glow += base * bounce_color * bounce * (skin ? 0.85 : 0.8) * (1.0 - smoothstep(-0.60, 0.10, n_world.y)) * dim;
	// the catch of light in the eye shines of itself; the whites a little
	glow += albedo * pc.z * dim;
	if (pa.w > 0.0) {
		vec3 n = normalize(NORMAL);
		vec3 key_view = normalize((VIEW_MATRIX * vec4(key_dir, 0.0)).xyz);
		float band = smoothstep(0.55, 0.85, dot(n, normalize(key_view + VIEW)));
		glow += albedo * key_color * band * pa.w * 1.4;
	}
	if (gore_inside > 0.0 && !FRONT_FACING && s == S_SKIN) {
		glow += base * 0.35;
	}
	if (bronze > 0.0) {
		glow = mix(glow, base * 0.10 + vec3(1.0, 0.82, 0.50) * pow(fres, 1.5) * 0.45, bronze);
	}
	if (charred > 0.0) {
		// Sparse, fixed fissures under the soot; no swimming neon spots.
		float crack = noise3(v_obj * vec3(29.0, 16.0, 29.0));
		float ember = (1.0 - smoothstep(0.012, 0.036, abs(crack - 0.52))) * smoothstep(0.55, 0.78, noise3(v_obj * 9.0));
		glow = mix(glow, base * 0.10 + vec3(0.6, 0.09, 0.012) * ember * (0.35 + 0.1 * sin(TIME * 2.0)), charred);
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
		if (skin) {
			// Continuous form: the cheek, socket and jaw keep their curvature
			// as they turn. Cloth retains the court's painted bands.
			lit = 0.10 + 0.90 * smoothstep(-0.35, 0.95, ndl);
			half_lit = 0.0;
		}
		float att = LIGHT_IS_DIRECTIONAL ? mix(1.0, ATTENUATION, shadow_amount) : ATTENUATION;
		float tone = max(lit * att, half_lit * min(1.0, att * 1.5));
		float edge = clamp(tone * (1.0 - tone) * 4.0, 0.0, 1.0);
		float sdepth = skin ? slot_depth(slot_albedo[s]) : 0.0;
		vec3 shade_c = skin ? mix(skin_shade, vec3(0.50, 0.56, 0.74), 0.55 * sdepth) : other_shade;
		vec3 tint = mix(shade_c, vec3(1.0), tone);
		vec3 lc = LIGHT_COLOR;
		vec3 term = vec3(0.0);
		if (skin) {
			float depth = slot_depth(slot_albedo[s]);
			float l = dot(lc, vec3(0.299, 0.587, 0.114));
			lc = mix(lc, vec3(l), 0.40 * depth);
			float wrap = smoothstep(-0.45, 0.15, ndl) * (1.0 - lit);
			DIFFUSE_LIGHT += lc * vec3(0.55, 0.20, 0.12) * wrap * att * (1.0 - depth) * 0.55 / PI;
			float sp = pow(clamp(dot(NORMAL, normalize(LIGHT + VIEW)), 0.0, 1.0), 24.0) * att;
			SPECULAR_LIGHT += mix(LIGHT_COLOR, vec3(l), 0.65) * sp * (0.018 + 0.045 * depth);
			term = skin_terminator;
		}
		DIFFUSE_LIGHT += lc * (tint * tone + term * edge * 0.30) / PI;
		if (bronze > 0.0) {
			vec3 h = normalize(LIGHT + VIEW);
			float spec = pow(clamp(dot(NORMAL, h), 0.0, 1.0), 40.0) * att;
			SPECULAR_LIGHT += LIGHT_COLOR * vec3(1.0, 0.85, 0.55) * spec * 1.6 * bronze;
		}
	}
}

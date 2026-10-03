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
uniform bool flat_colour = false;

varying float v_ao;
varying float v_cover;
varying vec3 v_world_normal;
varying vec3 v_obj;

void vertex() {
	v_ao = COLOR.r;
	v_cover = cover_channel == 1 ? COLOR.g : (cover_channel == 2 ? COLOR.b : (cover_channel == 3 ? COLOR.a : 0.0));
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
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
	if (flat_colour) {
		ALBEDO = albedo;
	} else {
		vec3 n = normalize(v_world_normal);
		float ndl = dot(n, normalize(key_dir));
		float lit = smoothstep(-0.02, band_soft, ndl);
		float half_tone = smoothstep(-0.42, -0.18, ndl) * 0.30;
		float tone = max(lit, half_tone);
		float g = noise3(v_obj * 46.0) * 0.6 + noise3(v_obj * 13.0) * 0.4;
		base *= 1.0 + (g - 0.5) * grain;
		vec3 col = mix(base * shade_tint, base * key_color, tone);
		float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
		col += rim_color * rim_amount * fres * (0.35 + 0.65 * lit);
		ALBEDO = col;
	}
}

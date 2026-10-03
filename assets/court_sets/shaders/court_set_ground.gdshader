shader_type spatial;
// The ground of the court: grass and earth painted in broad patches, trodden
// bare where people walk and sit (vertex G), the baked shade under every log
// and stone (vertex R), and the far land sinking into the haze.
render_mode cull_back, depth_draw_opaque, specular_disabled;

uniform vec3 grass : source_color = vec3(0.45, 0.47, 0.27);
uniform vec3 grass_dry : source_color = vec3(0.60, 0.55, 0.34);
uniform vec3 earth : source_color = vec3(0.52, 0.41, 0.29);
uniform vec3 earth_dark : source_color = vec3(0.36, 0.28, 0.20);
uniform vec3 haze_color : source_color = vec3(0.78, 0.80, 0.80);
uniform float haze_start = 22.0;
uniform float haze_end = 140.0;
uniform float haze_max = 0.45;
uniform float straw = 0.0;
uniform vec3 straw_colour : source_color = vec3(0.68, 0.58, 0.36);
uniform float ao_amount = 1.0;
uniform float band_soft = 0.30;
uniform vec3 hearth : source_color = vec3(0.24, 0.20, 0.17);
uniform float hearth_radius = 1.0;
uniform vec2 hearth_scale = vec2(1.0, 1.0);
// The season: snow lying (melted where people tread and near the fire),
// summer's dry grass, autumn's fallen leaves, spring's flowers in the grass.
uniform float snow = 0.0;
uniform float dry = 0.0;
uniform float leaves = 0.0;
uniform float flowers = 0.0;

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
	vec3 p = v_world;
	float big = noise3(p * 0.22) * 0.6 + noise3(p * 0.61 + 7.0) * 0.4;
	float mid = noise3(p * 1.7 + 2.0);
	float fine = noise3(p * 9.0) * 0.5 + noise3(p * 23.0) * 0.5;
	vec3 g = mix(grass, grass_dry, clamp(smoothstep(0.35, 0.75, big) + dry * 0.8, 0.0, 1.0));
	g = mix(g, vec3(0.74, 0.64, 0.40), dry * 0.45 * smoothstep(0.3, 0.7, mid));
	g *= 0.88 + 0.24 * mid;
	// strokes of grass: a little streaky along one way, like a brush
	float streak = noise3(vec3(p.x * 6.0, 0.0, p.z * 1.4));
	g *= 0.94 + 0.12 * streak;
	vec3 e = mix(earth, earth_dark, smoothstep(0.3, 0.8, mid) * 0.5);
	e *= 0.92 + 0.16 * fine;
	float wear = clamp(v_col.g, 0.0, 1.0);
	float edge = smoothstep(0.25, 0.65, wear + (mid - 0.5) * 0.45);
	vec3 col = mix(g, e, edge);
	if (straw > 0.0) {
		float st = smoothstep(0.55, 0.75, noise3(vec3(p.x * 14.0, 0.0, p.z * 3.0)));
		col = mix(col, straw_colour * (0.85 + 0.3 * fine), st * straw);
	}
	if (flowers > 0.0) {
		float fl = step(0.86, noise3(p * 7.0)) * (1.0 - edge) * flowers;
		col = mix(col, mix(vec3(0.95, 0.92, 0.80), vec3(0.92, 0.78, 0.30), step(0.5, noise3(p * 3.0))), fl);
	}
	if (leaves > 0.0) {
		float lf = step(0.72, noise3(vec3(p.x * 6.0, 0.0, p.z * 6.0)) * 0.7 + noise3(p * 17.0) * 0.3);
		col = mix(col, mix(vec3(0.62, 0.32, 0.12), vec3(0.75, 0.55, 0.18), noise3(p * 9.0)), lf * leaves * (1.0 - edge * 0.6));
	}
	// the hearth's scorched ring
	vec2 hq = p.xz / hearth_scale;
	float hd = length(hq);
	col = mix(col, hearth, (1.0 - smoothstep(hearth_radius * 0.55, hearth_radius * 1.25, hd)) * 0.85);
	col *= 1.0 + (fine - 0.5) * 0.06;
	if (snow > 0.0) {
		float melt = 1.0 - smoothstep(hearth_radius * 1.4, hearth_radius * 2.8, hd);
		float trod = smoothstep(0.35, 0.8, wear + (mid - 0.5) * 0.3);
		float drift = smoothstep(0.25, 0.55, big + 0.2);
		float cover = clamp(snow * drift * (1.0 - melt) * (1.0 - trod * 0.75), 0.0, 1.0);
		vec3 white = vec3(0.92, 0.94, 0.97) * (0.95 + 0.07 * fine);
		col = mix(col, mix(white, vec3(0.62, 0.58, 0.55), trod * 0.4), cover);
	}
	float ao = mix(1.0, v_col.r, ao_amount);
	col *= mix(1.0, ao, 0.6);
	float dist = length(v_world - CAMERA_POSITION_WORLD);
	float haze = haze_max * smoothstep(haze_start, haze_end, dist);
	ALBEDO = mix(col, haze_color, haze);
	EMISSION = haze_color * haze * 0.45;
	AO = ao;
	AO_LIGHT_AFFECT = 0.3;
	ROUGHNESS = 1.0;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float lit = smoothstep(-0.05, band_soft, ndl);
	DIFFUSE_LIGHT += LIGHT_COLOR * lit * ATTENUATION / PI;
}

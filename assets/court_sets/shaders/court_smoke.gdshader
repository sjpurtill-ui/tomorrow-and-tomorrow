shader_type spatial;
// A puff of smoke (one particle): soft and uneven, warm low by the fire and
// greyer as it rises; it fades in and out over its life (COLOR.a).
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec3 warm : source_color = vec3(0.78, 0.66, 0.54);
uniform vec3 cool : source_color = vec3(0.70, 0.71, 0.72);
uniform float opacity = 0.22;
uniform float fire_y = 0.0;

varying vec2 v_uv;
varying float v_height;
varying vec4 v_colour;

void vertex() {
	v_height = MODEL_MATRIX[3].y - fire_y;
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	v_uv = UV;
	v_colour = COLOR;
}

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash2(i), hash2(i + vec2(1, 0)), f.x), mix(hash2(i + vec2(0, 1)), hash2(i + vec2(1, 1)), f.x), f.y);
}

void fragment() {
	vec2 q = v_uv - 0.5;
	float r = length(q) * 2.0;
	float seed = v_colour.b * 10.0;
	float n = noise2(v_uv * 3.0 + seed + TIME * 0.05) * 0.6 + noise2(v_uv * 7.0 - seed) * 0.4;
	float puff = 1.0 - smoothstep(0.35, 1.0, r + (n - 0.5) * 0.7);
	vec3 col = mix(warm, cool, smoothstep(0.4, 3.0, v_height));
	ALBEDO = col * (0.85 + 0.3 * n);
	ALPHA = puff * opacity * v_colour.a;
}

shader_type spatial;
// A tongue of the fire: a card that always turns its face to the camera
// about the vertical, its flame drawn from scrolling noise, a white-gold
// heart going orange then red at the ragged edge. No CPU work per frame.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

uniform float seed = 0.0;
uniform float speed = 1.0;
uniform float strength = 1.0;
uniform vec3 core : source_color = vec3(1.0, 0.80, 0.42);
uniform vec3 mid : source_color = vec3(0.98, 0.46, 0.12);
uniform vec3 edge : source_color = vec3(0.62, 0.16, 0.04);

varying vec2 v_uv;

void vertex() {
	// billboard about Y: the card stays upright and faces the camera
	vec3 cam = INV_VIEW_MATRIX[3].xyz - MODEL_MATRIX[3].xyz;
	cam.y = 0.0;
	cam = normalize(cam + vec3(1e-4, 0.0, 0.0));
	vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), cam));
	float sx = length(MODEL_MATRIX[0].xyz);
	float sy = length(MODEL_MATRIX[1].xyz);
	vec3 world = MODEL_MATRIX[3].xyz + right * VERTEX.x * sx + vec3(0.0, 1.0, 0.0) * VERTEX.y * sy;
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(world, 1.0);
	v_uv = UV;
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
	vec2 uv = v_uv;
	float y = 1.0 - uv.y;
	float x = (uv.x - 0.5) * 2.0;
	float t = TIME * speed + seed * 13.0;
	float n = noise2(vec2(x * 2.2 + seed, y * 3.0 - t * 2.4)) * 0.6 + noise2(vec2(x * 5.0 - seed, y * 6.5 - t * 4.1)) * 0.4;
	float sway = (noise2(vec2(t * 0.9, seed)) - 0.5) * 0.5 * y;
	float width = mix(0.78, 0.04, pow(y, 0.85));
	float body = 1.0 - smoothstep(width * 0.55, width, abs(x - sway));
	float flame = body * smoothstep(1.0, 0.55, y + (n - 0.5) * 0.55) * smoothstep(0.0, 0.08, y);
	flame = clamp(flame * (0.75 + n * 0.6), 0.0, 1.0);
	vec3 col = mix(edge, mid, smoothstep(0.15, 0.55, flame));
	col = mix(col, core, smoothstep(0.62, 0.95, flame) * (1.0 - y * 0.6));
	ALBEDO = col * flame * strength * 1.15;
	ALPHA = flame;
}

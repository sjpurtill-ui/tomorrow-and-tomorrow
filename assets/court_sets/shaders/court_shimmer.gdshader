shader_type spatial;
// The air shaking above the fire: a card turned to the camera that bends what
// is behind it a pixel or two, strongest just above the flames and gone by
// the top. Reads the screen once (the opaque scene), so it is cheap.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float strength = 0.006;

varying vec2 v_uv;

void vertex() {
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
	float y = 1.0 - v_uv.y;
	float x = (v_uv.x - 0.5) * 2.0;
	float mask = (1.0 - smoothstep(0.4, 1.0, abs(x))) * smoothstep(0.0, 0.2, y) * (1.0 - smoothstep(0.55, 1.0, y));
	vec2 n = vec2(noise2(vec2(x * 6.0, y * 9.0 - TIME * 3.2)), noise2(vec2(x * 7.0 + 3.0, y * 8.0 - TIME * 2.7))) - 0.5;
	vec2 suv = SCREEN_UV + n * strength * mask;
	ALBEDO = textureLod(screen_tex, suv, 0.0).rgb;
	ALPHA = mask;
}

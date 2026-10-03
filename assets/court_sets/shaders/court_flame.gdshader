shader_type spatial;
// The fire: a card turned to the camera about the vertical, holding a cluster
// of tongues that lick up and split, each flickering on its own beat, warped
// by rising turbulence; white-gold at the roots, orange, then red and
// thinning to nothing at the tips. Two or three cards at different depths
// make the fire. No CPU work per frame.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform float seed = 0.0;
uniform float speed = 1.0;
uniform float strength = 1.0;
uniform int tongues = 4;
// the god's presence: the fire leans (+ toward the card's right) and dips
uniform float lean = 0.0;
uniform float height_mul = 1.0;
uniform vec3 core : source_color = vec3(1.0, 0.86, 0.52);
uniform vec3 mid : source_color = vec3(1.0, 0.50, 0.12);
uniform vec3 edge : source_color = vec3(0.70, 0.17, 0.04);

varying vec2 v_uv;

void vertex() {
	vec3 cam = INV_VIEW_MATRIX[3].xyz - MODEL_MATRIX[3].xyz;
	cam.y = 0.0;
	cam = normalize(cam + vec3(1e-4, 0.0, 0.0));
	vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), cam));
	float sx = length(MODEL_MATRIX[0].xyz);
	float sy = length(MODEL_MATRIX[1].xyz);
	// the card's foot stays on the fire; its height and lean change above it
	float up = (VERTEX.y + 0.5) * sy * height_mul;
	vec3 foot = MODEL_MATRIX[3].xyz - vec3(0.0, 0.5 * sy, 0.0);
	vec3 world = foot + right * (VERTEX.x * sx + lean * up * (VERTEX.y + 0.5)) + vec3(0.0, up, 0.0);
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(world, 1.0);
	v_uv = UV;
}

float hash1(float n) {
	return fract(sin(n * 91.345) * 47453.5453);
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
	float t = TIME * speed + seed * 17.0;
	// rising turbulence bends everything as it climbs
	vec2 warp = vec2(noise2(vec2(x * 1.6 + seed, y * 2.6 - t * 2.2)) - 0.5, noise2(vec2(x * 2.1 - seed, y * 3.3 - t * 2.9)) - 0.5);
	float xw = x + warp.x * 0.55 * y;
	float yw = y + warp.y * 0.18;
	float heat = 0.0;
	for (int i = 0; i < 6; i++) {
		if (i >= tongues) {
			break;
		}
		float fi = float(i);
		float ox = (hash1(fi + seed * 3.0) - 0.5) * 1.1;
		// each tongue rises and falls on its own beat
		float beat = 0.62 + 0.38 * noise2(vec2(t * (1.6 + hash1(fi + 7.0)), fi * 5.3 + seed));
		float h = mix(0.45, 1.0, hash1(fi + 11.0 + seed)) * beat;
		float tlean = (noise2(vec2(t * 0.8, fi + seed * 2.0)) - 0.5) * 0.6;
		float yy = yw / max(h, 0.05);
		float w = mix(0.42, 0.02, pow(clamp(yy, 0.0, 1.0), 0.7)) * mix(0.8, 1.2, hash1(fi + 3.0));
		float dx = abs(xw - ox - tlean * yy * yy);
		float tongue = (1.0 - smoothstep(w * 0.45, w, dx)) * (1.0 - smoothstep(0.75, 1.0, yy));
		heat = max(heat, tongue * (1.0 - yy * 0.55));
	}
	// a glowing bed at the root
	heat = max(heat, (1.0 - smoothstep(0.0, 0.16, y)) * (1.0 - smoothstep(0.5, 1.0, abs(x))) * 0.9);
	float n = noise2(vec2(xw * 4.0, yw * 7.0 - t * 4.5));
	heat = clamp(heat * (0.8 + n * 0.45) - smoothstep(0.6, 1.0, y) * 0.25, 0.0, 1.0);
	vec3 col = mix(edge, mid, smoothstep(0.08, 0.5, heat));
	col = mix(col, core, smoothstep(0.55, 0.92, heat) * (1.0 - y * 0.7));
	ALBEDO = col * heat * strength * 1.2;
	ALPHA = heat;
}

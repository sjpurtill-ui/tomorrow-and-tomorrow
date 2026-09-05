shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_disabled;

uniform bool layered = false;
varying vec3 ground_position;
varying vec3 ground_normal;

float grain_hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float grain(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(grain_hash(i), grain_hash(i + vec2(1, 0)), f.x),
		mix(grain_hash(i + vec2(0, 1)), grain_hash(i + vec2(1, 1)), f.x), f.y);
}
float filtered_grain(vec2 p) {
	float footprint = max(length(dFdx(p)), length(dFdy(p)));
	float detail = 1.0 - smoothstep(0.18, 0.75, footprint);
	return mix(0.5, grain(p), detail);
}
float face_grain(float frequency, vec3 weights) {
	// All faces receive detail; a horizontal projection alone stretches walls.
	vec3 p = ground_position * frequency;
	return filtered_grain(p.yz) * weights.x
		+ filtered_grain(p.xz) * weights.y
		+ filtered_grain(p.xy) * weights.z;
}
void vertex() {
	ground_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	ground_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}
void fragment() {
	vec3 weights = abs(normalize(ground_normal));
	weights *= weights;
	weights *= weights;
	weights /= max(weights.x + weights.y + weights.z, 0.001);
	// World units are kilometres: broad weathering, metre patches, fine grain.
	float weathering = face_grain(180.0, weights);
	float patches = face_grain(620.0, weights);
	float minerals = face_grain(2200.0, weights);
	float bedding = 0.0;
	if (layered) {
		float phase = ground_position.y * 2600.0 + grain(ground_position.xz * 160.0) * 0.6;
		float resolved = 1.0 - smoothstep(0.35, 1.4, fwidth(phase));
		float exposed_face = 1.0 - smoothstep(0.20, 0.75, abs(normalize(ground_normal).y));
		bedding = (1.0 - smoothstep(0.035, 0.18, abs(sin(phase)))) * resolved * exposed_face;
	}
	ALBEDO = COLOR.rgb * (0.73 + weathering * 0.26 + patches * 0.16 + minerals * 0.08)
		* (1.0 - bedding * 0.16);
	ROUGHNESS = 0.93 + patches * 0.05;
}

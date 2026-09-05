shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

uniform vec2 occurrence_center = vec2(0.0);
uniform vec2 sediment_axis = vec2(1.0, 0.0);
uniform bool layered = false;
varying vec3 ground_position;

float soil_hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float soil_noise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(soil_hash(i), soil_hash(i + vec2(1, 0)), f.x),
		mix(soil_hash(i + vec2(0, 1)), soil_hash(i + vec2(1, 1)), f.x), f.y);
}
float filtered_soil(vec2 p) {
	float footprint = max(length(dFdx(p)), length(dFdy(p)));
	return mix(0.5, soil_noise(p), 1.0 - smoothstep(0.2, 0.8, footprint));
}
void vertex() {
	ground_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec2 offset = ground_position.xz - occurrence_center;
	vec2 local = vec2(dot(offset, sediment_axis), dot(offset, vec2(-sediment_axis.y, sediment_axis.x)));
	// Tens-of-metres exposures, with elongated patches along layered outcrops.
	vec2 broad_scale = layered ? vec2(12.0, 24.0) : vec2(18.0);
	float broad = filtered_soil(local * broad_scale + vec2(13.7, -8.2));
	float fragments = filtered_soil(local * 70.0 + vec2(-3.1, 41.6));
	float exposure = smoothstep(0.30, 0.68, broad * 0.75 + fragments * 0.25);
	ALBEDO = COLOR.rgb * (0.90 + fragments * 0.18);
	// The existing mesh alpha owns occurrence bounds and discovery masking.
	ALPHA = COLOR.a * exposure * 0.65;
}

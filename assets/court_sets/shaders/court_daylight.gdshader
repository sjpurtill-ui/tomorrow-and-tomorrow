shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec3 colour : source_color = vec3(1.0, 0.9, 0.72);
uniform float strength = 0.045;
varying vec3 world_point;

void vertex() {
	world_point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// The opening stays clear. Light becomes legible a little way inside,
	// then disappears softly before the floor and around the prism edges.
	float across = smoothstep(0.0, 0.22, UV.x) * (1.0 - smoothstep(0.78, 1.0, UV.x));
	float along = smoothstep(0.0, 0.14, UV.y) * (1.0 - smoothstep(0.62, 1.0, UV.y));
	float edge = pow(abs(dot(NORMAL, VIEW)), 1.8);
	float wisp = 0.87 + 0.08 * sin(world_point.x * 4.7 + world_point.y * 2.3 + TIME * 0.19)
		+ 0.05 * sin(world_point.z * 3.4 - world_point.y * 5.1 - TIME * 0.13);
	ALBEDO = colour * strength * across * along * edge * wisp;
}

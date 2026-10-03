shader_type spatial;
// The pool of the god's light on the ground about the one addressed: a soft
// glow laid on the floor, so the light reads even where the beam itself is
// lost against the daylight or cut by the frame's edge.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec3 colour : source_color = vec3(1.0, 0.86, 0.58);
uniform float strength = 0.0;

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float d = length(p);
	float pool = (1.0 - smoothstep(0.15, 1.0, d));
	pool *= pool;
	ALBEDO = colour * pool * strength;
}

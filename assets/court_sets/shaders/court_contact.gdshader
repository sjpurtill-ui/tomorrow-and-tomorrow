shader_type spatial;
// The soft shade right under someone's feet (or an animal's), where the open
// sky cannot reach: it keeps everyone ON the ground.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

instance uniform float strength = 0.55;
uniform vec3 tint : source_color = vec3(0.16, 0.11, 0.07);

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float d = length(p);
	float a = 1.0 - smoothstep(0.05, 1.0, d);
	ALBEDO = tint;
	ALPHA = a * a * strength;
}

shader_type spatial;
// A spark rising from the fire: a tiny bright point that cools as it climbs
// (COLOR.a is what is left of its life).
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec3 hot : source_color = vec3(1.0, 0.78, 0.38);
uniform vec3 cold : source_color = vec3(0.9, 0.25, 0.05);

varying vec2 v_uv;
varying vec4 v_colour;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	v_uv = UV;
	v_colour = COLOR;
}

void fragment() {
	float r = length(v_uv - 0.5) * 2.0;
	float spot = 1.0 - smoothstep(0.0, 1.0, r);
	float life = v_colour.a;
	ALBEDO = mix(cold, hot, life) * spot * (0.6 + life * 1.4);
	ALPHA = spot * life;
}

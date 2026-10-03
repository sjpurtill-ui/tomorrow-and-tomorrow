shader_type spatial;
// A mote of dust drifting in the light: under the open sky it glints faintly
// everywhere; in a hall it shows only inside the sun's shaft.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec3 colour : source_color = vec3(1.0, 0.92, 0.75);
uniform float brightness = 0.55;
uniform vec3 shaft_top = vec3(0.0, 5.0, 0.0);
uniform vec3 shaft_dir = vec3(0.0, -1.0, 0.0);
uniform float shaft_radius = 0.0;

varying vec2 v_uv;
varying vec4 v_colour;
varying vec3 v_pos;

void vertex() {
	v_pos = MODEL_MATRIX[3].xyz;
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	v_uv = UV;
	v_colour = COLOR;
}

void fragment() {
	float r = length(v_uv - 0.5) * 2.0;
	float spot = 1.0 - smoothstep(0.1, 1.0, r);
	float inside = 1.0;
	if (shaft_radius > 0.0) {
		vec3 d = normalize(shaft_dir);
		vec3 rel = v_pos - shaft_top;
		float along = dot(rel, d);
		float off = length(rel - d * along);
		inside = (1.0 - smoothstep(shaft_radius * 0.6, shaft_radius * 1.15, off)) * step(0.0, along);
		inside = max(inside, 0.1);
	}
	ALBEDO = colour * spot * brightness * inside * v_colour.a;
	ALPHA = spot;
}

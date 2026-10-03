shader_type spatial;
// The ink line round a court figure: the back faces pushed out along the
// normal by a fixed number of screen pixels, drawn in iron-gall ink.
// Used as the next pass of court_figure_toon.gdshader materials.
render_mode unshaded, cull_front, depth_draw_opaque;

uniform vec3 ink : source_color = vec3(0.165, 0.133, 0.090);
uniform float width_px = 1.7;
uniform int cover_channel = 0;

varying float v_cover;

void vertex() {
	v_cover = cover_channel == 1 ? COLOR.g : (cover_channel == 2 ? COLOR.b : (cover_channel == 3 ? COLOR.a : 0.0));
	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	vec3 nv = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec2 nc = (PROJECTION_MATRIX * vec4(nv, 0.0)).xy;
	float l = length(nc);
	if (l > 1e-5) {
		clip.xy += nc / l * width_px * 2.0 / VIEWPORT_SIZE * clip.w;
	}
	POSITION = clip;
}

void fragment() {
	if (v_cover > 0.5) {
		discard;
	}
	ALBEDO = ink;
}

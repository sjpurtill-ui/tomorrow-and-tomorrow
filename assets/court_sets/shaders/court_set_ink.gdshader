shader_type spatial;
// The ink line round the set's pieces, as the figures have theirs
// (scripts/shaders/court_figure_ink.gdshader): the back faces pushed out by a
// few screen pixels and drawn in iron-gall ink, thinner with distance so the
// far land is not scribbled over.
render_mode unshaded, cull_front, depth_draw_opaque, shadows_disabled;

uniform vec3 ink : source_color = vec3(0.17, 0.13, 0.09);
uniform float width_px = 1.4;
uniform float fade_near = 9.0;
uniform float fade_far = 30.0;

void vertex() {
	vec4 view = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec4 clip = PROJECTION_MATRIX * view;
	vec3 nv = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec2 nc = (PROJECTION_MATRIX * vec4(nv, 0.0)).xy;
	float l = length(nc);
	float dist = -view.z;
	float w = width_px * mix(1.0, 0.35, smoothstep(fade_near, fade_far, dist));
	if (l > 1e-5) {
		clip.xy += nc / l * w * 2.0 / VIEWPORT_SIZE * clip.w;
	}
	POSITION = clip;
}

void fragment() {
	ALBEDO = ink;
}

shader_type spatial;
// Nation border ink (nation_border_ink.gd), as the scouts' chart ink: each
// vertex is an anchor on the line plus an offset in UV2, a fraction of the
// view height the line was built for. Scaling it by the view height here
// keeps every hairline and band the same width on screen at every zoom, so
// zooming within the view's step never rebuilds a border. The view height is
// measured at each vertex's depth, so a tilted view keeps an even line.
render_mode unshaded, blend_mix, depth_test_disabled, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

// The ink's strength at this zoom (nation_borders.ink_fade).
uniform float fade = 1.0;

void vertex() {
	vec4 view_position = MODELVIEW_MATRIX*vec4(VERTEX, 1.0);
	// abs(): the compatibility renderer flips Y in the projection.
	float view_height = 2.0*max(-view_position.z, 0.000001)/max(abs(PROJECTION_MATRIX[1][1]), 0.0001);
	VERTEX.xz += UV2*view_height;
}

void fragment() {
	ALBEDO = COLOR.rgb;
	ALPHA = COLOR.a*fade;
}

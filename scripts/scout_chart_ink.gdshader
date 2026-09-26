shader_type spatial;
// Scout chart ink (scout_chart_stroke.gd, Ink): each vertex is an anchor on the
// route plus an offset in UV2, a fraction of the view height the stroke was
// built for. Scaling it by the view height here keeps the line, its halo and
// its direction ticks the same width on screen at every zoom, so zooming never
// rebuilds the route. The view height is measured at each vertex's depth, so
// a tilted view keeps an even line from near to far.
render_mode unshaded, blend_mix, depth_test_disabled, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

void vertex() {
	vec4 view_position = MODELVIEW_MATRIX*vec4(VERTEX, 1.0);
	// abs(): the compatibility renderer flips Y in the projection.
	float view_height = 2.0*max(-view_position.z, 0.000001)/max(abs(PROJECTION_MATRIX[1][1]), 0.0001);
	VERTEX.xz += UV2*view_height;
}

// A returned chart is set as a row of round ink dots, an explorer's track,
// rather than hard-cut dashes. Both sizes are fractions of the view height
// the stroke was built for (UV: along, across), like its width. 0 draws a
// continuous line.
uniform float dot_period = 0.0;
uniform float dot_radius = 0.0;

void fragment() {
	ALBEDO = COLOR.rgb;
	ALPHA = COLOR.a;
	if (dot_period > 0.0) {
		float along = (fract(UV.x/dot_period)-0.5)*dot_period;
		float distance_to_dot = length(vec2(along, UV.y));
		float soft = max(fwidth(distance_to_dot), 0.000001);
		ALPHA *= 1.0-smoothstep(dot_radius-soft*0.5, dot_radius+soft*0.75, distance_to_dot);
	}
}

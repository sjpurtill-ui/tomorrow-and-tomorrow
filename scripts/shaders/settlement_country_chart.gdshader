shader_type spatial;
// Retained chart strokes, using the same anchor+offset construction as scout
// and border ink. Only the ink grows: buildings retain their physical scale.
render_mode unshaded, blend_mix, depth_test_disabled, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
varying float chart_weight;
void vertex() {
	vec4 clip=PROJECTION_MATRIX*(MODELVIEW_MATRIX*vec4(VERTEX,1.0));
	float view_height=2.0*abs(clip.w)/max(abs(PROJECTION_MATRIX[1][1]),0.0001);
	float pixel_km=view_height/max(VIEWPORT_SIZE.y,1.0);
	float diameter=min(4.0,pixel_km*14.0);
	VERTEX.xz+=UV2*diameter;
	chart_weight=smoothstep(2.0,6.0,view_height)*(1.0-smoothstep(600.0,1600.0,view_height));
}
void fragment() {
	float edge=max(fwidth(UV.y),0.001);
	// Centre the antialiasing ramp on the edge. An inward-only ramp erased
	// most of a subpixel stroke when the world cap took over.
	float coverage=1.0-smoothstep(1.0-edge,1.0+edge,abs(UV.y));
	ALBEDO=COLOR.rgb;
	ALPHA=COLOR.a*chart_weight*coverage;
}

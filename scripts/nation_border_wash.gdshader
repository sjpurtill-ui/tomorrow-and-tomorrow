shader_type spatial;
// NATION WASHES (nation_border_layer.gd): each people's land in its colour,
// thinning toward its edge (the vertex colours, nation_border_partition.gd),
// over the chart and under the border ink and the marks.
// The mesh arrives already cut along the meeting lines and, at its grid's
// scale, along the shore. Here the shore is made exact: over the streamed
// terrain patch it is the same smooth sea-level contour the land and the
// coastal water share (map_coast.gdshaderinc); beyond it the macro raster
// decides, as it does for the planet mesh. A wash never tints sea or lake.
render_mode unshaded, blend_mix, depth_test_disabled, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

#include "res://scripts/coast_mask.gdshaderinc"
#include "res://scripts/map_coast.gdshaderinc"

// The whole layer's strength at this zoom (nation_borders.wash_fade).
uniform float fade = 1.0;

varying vec3 world_position;
varying vec3 relative_position;

void vertex() {
	world_position = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	relative_position = world_position-CAMERA_POSITION_WORLD;
}

void fragment() {
	// Before anything that could diverge (derivatives need whole quads).
	float pixel_world = max(length(dFdx(relative_position.xz)),length(dFdy(relative_position.xz)));
	// Beyond the streamed patch the macro raster draws the coast (at sea level,
	// as the ocean plane yields to it); over the patch, its smooth contour
	// (exactly as the river ink gives way to the sea).
	float raster = coast_mask_ready() ? coast_mask_height(world_position.xz) : 1.0;
	float land = smoothstep(0.0, max(fwidth(raster), 0.0005), raster);
	vec2 rel = world_position.xz-terrain_grid.xy;
	if (coast_patch_ready() && coast_patch_contains(rel)) {
		land = smoothstep(-0.0015, 0.0015, coast_patch_ground(rel, pixel_world, 0.0));
	}
	ALBEDO = COLOR.rgb;
	ALPHA = COLOR.a*fade*land;
}

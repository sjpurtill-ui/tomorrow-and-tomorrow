// One smooth shoreline for a streamed terrain patch, shared by the patch's land
// and the coastal water drawn over it (codex/map-2).
//
// The patch mesh is a grid of alternating-diagonal triangles. Where such a grid
// crosses sea level the contour is a chain of straight chords that change
// direction at every triangle, so once a cell spans several screen pixels
// (the regional view) every coast read as a row of sawteeth. Here the shore is
// the sea-level contour of a Catmull-Rom surface through the same vertex
// heights: it passes through every sampled height (no island is smoothed away)
// and its contour has no corners. Land and water evaluate the identical
// function at the same point, so they always agree on where the shore is.
// Both inputs are grid-relative: `rel` = world xz minus the patch centre (km).
// Include after coast_mask.gdshaderinc (it uses coast_feather_hash).

uniform sampler2D terrain_heights : filter_nearest, repeat_disable;
// centre.xy, span (km), vertices per side.
uniform vec4 terrain_grid = vec4(0.0);

float coast_patch_height_at(ivec2 texel) {
	int last = int(terrain_grid.w)-1;
	return texelFetch(terrain_heights, clamp(texel, ivec2(0), ivec2(last)), 0).r;
}

bool coast_patch_ready() {
	return terrain_grid.z > 0.0 && terrain_grid.w >= 2.0;
}

bool coast_patch_contains(vec2 rel) {
	return max(abs(rel.x), abs(rel.y)) < terrain_grid.z*0.5;
}

// Screen pixels one patch cell spans at this fragment.
float coast_patch_cell_px(float pixel_world) {
	return terrain_grid.z/max(terrain_grid.w-1.0, 1.0)/max(pixel_world, 0.000001);
}

// The mesh's own surface: the alternating triangle interpolation of
// TerrainPatchBuilder (not bilinear). `spread` is the height range of the cell.
float coast_patch_triangle(vec2 rel, out float spread) {
	vec2 cell = clamp((rel/terrain_grid.z+0.5)*(terrain_grid.w-1.0), vec2(0.0), vec2(terrain_grid.w-1.001));
	ivec2 base = ivec2(floor(cell));
	vec2 f = fract(cell);
	float a = coast_patch_height_at(base);
	float b = coast_patch_height_at(base+ivec2(1,0));
	float c = coast_patch_height_at(base+ivec2(1,1));
	float d = coast_patch_height_at(base+ivec2(0,1));
	spread = max(max(a,b),max(c,d))-min(min(a,b),min(c,d));
	if (mod(float(base.x+base.y), 2.0) < 1.0) {
		return f.x>=f.y ? a+(b-a)*f.x+(c-b)*f.y : a+(c-d)*f.x+(d-a)*f.y;
	}
	return f.x+f.y<=1.0 ? a+(b-a)*f.x+(d-a)*f.y : c+(d-c)*(1.0-f.x)+(b-c)*(1.0-f.y);
}

vec4 coast_catmull_rom(float t) {
	return vec4(
		t*(-0.5+t*(1.0-0.5*t)),
		1.0+t*t*(-2.5+1.5*t),
		t*(0.5+t*(2.0-1.5*t)),
		t*t*(-0.5+0.5*t));
}

float coast_patch_row(ivec2 at, vec4 weights) {
	return dot(weights, vec4(
		coast_patch_height_at(at+ivec2(-1,0)),
		coast_patch_height_at(at),
		coast_patch_height_at(at+ivec2(1,0)),
		coast_patch_height_at(at+ivec2(2,0))));
}

float coast_patch_smooth(vec2 rel) {
	vec2 cell = clamp((rel/terrain_grid.z+0.5)*(terrain_grid.w-1.0), vec2(0.0), vec2(terrain_grid.w-1.001));
	ivec2 base = ivec2(floor(cell));
	vec2 f = fract(cell);
	vec4 wx = coast_catmull_rom(f.x);
	vec4 wy = coast_catmull_rom(f.y);
	return wy.x*coast_patch_row(base+ivec2(0,-1), wx)
		+wy.y*coast_patch_row(base, wx)
		+wy.z*coast_patch_row(base+ivec2(0,1), wx)
		+wy.w*coast_patch_row(base+ivec2(0,2), wx);
}

// A faint world-anchored wobble at about a cell's scale. Added only near the
// shore, it breaks the rounded squares a lone vertex draws in any smooth grid
// surface into the irregular bays and points of a real coast.
float coast_patch_wobble(vec2 rel) {
	vec2 cell = (rel/terrain_grid.z+0.5)*(terrain_grid.w-1.0)*0.62;
	vec2 i = floor(cell);
	vec2 f = fract(cell);
	f = f*f*(3.0-2.0*f);
	float a = coast_feather_hash(i+vec2(71.0, 13.0));
	float b = coast_feather_hash(i+vec2(72.0, 13.0));
	float c = coast_feather_hash(i+vec2(71.0, 14.0));
	float d = coast_feather_hash(i+vec2(72.0, 14.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y)-0.5;
}

// Ground height (km) as the map should draw its shore. Near the shoreline, and
// once a cell is big enough on screen for its chords to show, this is the
// smooth surface; well inland, well offshore, or close up (where the mesh is
// already finer than a pixel) it is the mesh itself, at four texel reads
// instead of sixteen. The two are blended, never switched, so no seam or
// stray contour line appears where one gives way to the other.
float coast_patch_ground(vec2 rel, float pixel_world, float sea) {
	float spread;
	float mesh_height = coast_patch_triangle(rel, spread);
	float mesh_weight = max(1.0-smoothstep(1.0, 1.5, coast_patch_cell_px(pixel_world)),
		smoothstep(spread*3.0+0.0015, spread*4.0+0.002, abs(mesh_height-sea)));
	if (mesh_weight >= 1.0) { return mesh_height; }
	float smooth_height = coast_patch_smooth(rel)+coast_patch_wobble(rel)*spread*0.30;
	return mix(smooth_height, mesh_height, mesh_weight);
}

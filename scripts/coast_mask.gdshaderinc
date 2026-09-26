// Shared land/sea agreement and soft streamed-patch edges (codex/coast-render).
//
// Every terrain layer samples the same height authority, but the coarse planet
// mesh (~83 km triangles) and the planet ocean plane decided the shoreline by
// intersecting geometry, so outside a streamed patch the coast was a crude
// polygon that disagreed with the patch. When the per-seed macro rasters are
// ready (exact heights on ~21 km and ~7 km lattices) the far layers instead
// read land/sea from them per pixel. Streamed patches dissolve over their outer
// margin along an organic world-space pattern instead of ending in a square.

uniform sampler2D coast_level0 : filter_linear, repeat_disable;
uniform sampler2D coast_level1 : filter_linear, repeat_disable;
// Colour (to_rgba32 bytes, so ABGR) and climate/geology fields of the same lattices.
uniform sampler2D coast_color0 : filter_linear, repeat_disable;
uniform sampler2D coast_color1 : filter_linear, repeat_disable;
uniform sampler2D coast_fields0 : filter_linear, repeat_disable;
uniform sampler2D coast_fields1 : filter_linear, repeat_disable;
// origin.xy, cell.xy (km) of each raster; zero cell = not ready.
uniform vec4 coast_grid0 = vec4(0.0);
uniform vec4 coast_grid1 = vec4(0.0);

const float COAST_FEATHER_START = 0.82;
// The planet layer stays drawn beyond this, under the patch's inner margin, so
// oblique views of uneven relief cannot open a gap between the two surfaces.
const float COAST_CUTOUT_CORE = 0.72;

float coast_level_height(sampler2D level, vec4 grid, vec2 xz) {
	vec2 size = vec2(textureSize(level, 0));
	vec2 uv = ((xz-grid.xy)/grid.zw+0.5)/size;
	return texture(level, uv).r;
}

vec4 coast_level_sample(sampler2D level, vec4 grid, vec2 xz) {
	vec2 size = vec2(textureSize(level, 0));
	return texture(level, ((xz-grid.xy)/grid.zw+0.5)/size);
}

bool coast_mask_ready() {
	return coast_grid0.z > 0.0;
}

bool coast_in_level1(vec2 xz) {
	if (coast_grid1.z <= 0.0) { return false; }
	vec2 cell = (xz-coast_grid1.xy)/coast_grid1.zw;
	vec2 size = vec2(textureSize(coast_level1, 0));
	return all(greaterThanEqual(cell, vec2(1.0))) && all(lessThanEqual(cell, size-2.0));
}

// Height (km) from the finest ready raster. Only meaningful when ready.
float coast_mask_height(vec2 xz) {
	if (coast_in_level1(xz)) { return coast_level_height(coast_level1, coast_grid1, xz); }
	return coast_level_height(coast_level0, coast_grid0, xz);
}

// Vertex attributes of the planet mesh, re-read from the finest raster exactly
// as TerrainMacroRender packs them for continental patches.
void coast_far_surface(vec2 xz, inout vec4 color, inout vec2 climate, inout vec2 geology) {
	vec4 packed_color;
	vec4 fields;
	if (coast_in_level1(xz)) {
		packed_color = coast_level_sample(coast_color1, coast_grid1, xz);
		fields = coast_level_sample(coast_fields1, coast_grid1, xz);
	} else {
		packed_color = coast_level_sample(coast_color0, coast_grid0, xz);
		fields = coast_level_sample(coast_fields0, coast_grid0, xz);
	}
	color = packed_color.abgr;
	fields = fields.abgr;
	climate = vec2(1.0+fields.x, fields.y);
	geology = fields.zw;
}

float coast_feather_hash(vec2 cell) {
	uvec2 c = uvec2(ivec2(floor(cell)));
	uint h = (c.x*1597334677u)^(c.y*3812015801u);
	h = (h^(h>>16u))*2246822519u;
	h = (h^(h>>13u))*3266489917u;
	return float(h^(h>>16u))/4294967295.0;
}

float coast_feather_noise(vec2 p) {
	float total = 0.0;
	float amplitude = 0.55;
	for (int octave = 0; octave < 3; octave++) {
		vec2 i = floor(p);
		vec2 f = fract(p);
		f = f*f*(3.0-2.0*f);
		total += amplitude*mix(mix(coast_feather_hash(i), coast_feather_hash(i+vec2(1.0,0.0)), f.x),
			mix(coast_feather_hash(i+vec2(0.0,1.0)), coast_feather_hash(i+vec2(1.0)), f.x), f.y);
		p = vec2(p.x*1.87-p.y*0.93, p.x*0.93+p.y*1.87)+vec2(31.7,-17.3);
		amplitude *= 0.45;
	}
	return total/0.9;
}

// 0 inside the patch core, rising to 1 at the patch boundary.
float coast_patch_edge(vec2 xz, vec4 patch_rect) {
	if (patch_rect.w < 0.5 || patch_rect.z <= 0.0) { return 0.0; }
	vec2 offset = abs(xz-patch_rect.xy);
	return max(offset.x, offset.y)/(patch_rect.z*0.5);
}

// True where a streamed patch gives way to the layer beneath it. The boundary
// wanders through the outer margin of the patch (beyond the view it was built for) along world-anchored noise.
bool coast_patch_yields(vec2 xz, vec4 patch_rect) {
	float edge = coast_patch_edge(xz, patch_rect);
	if (edge < COAST_FEATHER_START) { return false; }
	if (edge >= 0.995) { return true; }
	float threshold = smoothstep(COAST_FEATHER_START, 0.995, edge);
	return coast_feather_noise((xz-patch_rect.xy)/(patch_rect.z*0.03)) < threshold;
}

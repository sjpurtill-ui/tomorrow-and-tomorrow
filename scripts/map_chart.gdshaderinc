// THE KNOWN LAND AS A HAND-COLOURED CHART (codex/map-beauty)
//
// Close up the land is painted (world_beauty.gdshaderinc). From the regional
// view outward it is drawn the way a surveyor's fair copy is drawn: the sheet
// is even, the land takes flat watercolour washes chosen by its climate,
// relief is shaded from the north-west, and everything else is ink. None of
// the painted land's photographic grain, noise mottling or brushwork reaches
// this scale, so hills, water, woods and places read first.
//
// The chart is carried as emission, like the blank vellum of the unknown
// (map_palette.gdshaderinc): no sun angle, cast shadow or cloud can blot it.
// The terrain shader crossfades into it by view scale (mc_chart_weight), so a
// zoom out of the valley is a painting turning into its map, never a pop.
//
// Include after map_palette.gdshaderinc (MAP_*, map_paper_*), coast_mask,
// map_coast (the streamed patch's heights) and world_beauty (wb_contours).
// Values are linear. No derivatives are taken here, so every function is safe
// inside the terrain shader's branches.

// Where the chart takes over, in km per design pixel (1/1080 of the view's
// height, the unit map_glyph and the rivers use). Nothing of it at the
// 50,000 ft view, all of it at the Region view, at any window size or aspect.
const float MC_CHART_FROM = 0.010;
const float MC_CHART_FULL = 0.032;

// km per design pixel at a fragment `view_offset` (world position minus the
// camera's) away, for the view's `projection`. Taken from the distance, not
// from screen derivatives: those step a little at every mesh triangle (each
// is tilted differently), and a crossfade weight read from them paints the
// triangles in as facets. The distance is smooth across the whole surface.
float mc_design_km(vec3 view_offset, mat4 projection) {
	return length(view_offset)*2.0/max(abs(projection[1][1])*1080.0, 0.0001);
}

float mc_chart_weight(float design_km) {
	return smoothstep(MC_CHART_FROM, MC_CHART_FULL, design_km);
}

// The sheet under the washes: the unknown's vellum, a shade cleaner where the
// land has been surveyed.
const vec3 MC_PAPER = vec3(0.690, 0.625, 0.500);

// Washes: what each pigment lets through (it multiplies the paper). Muted,
// the olive, straw and slate of an old hand-coloured survey, never neon.
const vec3 MC_WASH_MEADOW = vec3(0.790, 0.880, 0.720);
const vec3 MC_WASH_LUSH = vec3(0.720, 0.850, 0.700);
const vec3 MC_WASH_STEPPE = vec3(0.965, 0.930, 0.800);
const vec3 MC_WASH_DRYLAND = vec3(1.000, 0.965, 0.870);
const vec3 MC_WASH_WETLAND = vec3(0.740, 0.840, 0.820);
const vec3 MC_WASH_TUNDRA = vec3(0.940, 0.960, 0.990);
const vec3 MC_WASH_UPLAND = vec3(0.890, 0.860, 0.840);
const vec3 MC_WASH_WOOD = vec3(0.580, 0.720, 0.600);
const vec3 MC_WASH_WOOD_COLD = vec3(0.540, 0.670, 0.640);
const vec3 MC_WASH_WOOD_DRY = vec3(0.700, 0.790, 0.640);
const vec3 MC_WASH_SNOW = vec3(1.120, 1.150, 1.230);
// Grass resting through the cold months: the meadow wash gone to straw.
const vec3 MC_WASH_RESTING = vec3(0.930, 0.900, 0.780);
// The sea: a pale slate wash on the same paper, a little deeper offshore.
const vec3 MC_WASH_SEA_SHALLOW = vec3(0.640, 0.820, 0.920);
const vec3 MC_WASH_SEA = vec3(0.540, 0.730, 0.900);

// The land's climate at chart scale from the vertex fields the painted land
// reads (surface COLOR, UV): (rain, warmth, woodland cover). A continental
// mesh samples woodland too sparsely to trust, so there the climate's own
// mean stands in, exactly as the painted path reconstructs it.
vec3 mc_fields(vec4 surface_color, vec2 surface_uv, float pixel_world, bool use_woodland, float height) {
	bool physical = surface_uv.x >= 0.999;
	float rain = physical ? clamp(surface_uv.x-1.0, 0.0, 1.0) : clamp((surface_color.g-surface_color.r)*4.0+0.48, 0.0, 1.0);
	float warm = physical ? surface_uv.y : 0.55;
	float wood = clamp(surface_color.a, 0.0, 1.0);
	if (use_woodland && physical) {
		float mean = clamp((rain-0.40)*2.6, 0.0, 1.0)*clamp((surface_uv.y-0.16)*3.4, 0.0, 1.0);
		if (height > 3.2) { mean *= 1.0-clamp((height-3.2)/5.2, 0.0, 0.74); }
		wood = mix(mean*0.61, wood, 1.0-smoothstep(0.55, 4.50, pixel_world));
	}
	return vec3(rain, warm, wood);
}

// The paper's own texture, held at a constant size on screen so it never
// swims or pops while zooming: a fine tooth a few pixels across and faint
// laid fibres, over a formation so gentle the sheet still reads as one even
// tone. Blended across zoom octaves like the unknown's sheet. About -1..1.
float mc_grain_octave(vec2 p) {
	float tooth = map_paper_noise(p*34.0+vec2(11.0, -5.0))-0.5;
	vec2 q = vec2(p.x*0.94+p.y*0.34, -p.x*0.34+p.y*0.94);
	float fibre = map_paper_noise(q*vec2(3.0, 19.0)+vec2(7.0, -3.0))-0.5;
	float formation = map_paper_noise(p*0.8+vec2(-23.0, 9.0))-0.5;
	return tooth*0.55+fibre*0.45+formation*0.60;
}

float mc_grain(vec2 world_xz, float camera_height) {
	float octave = log2(max(camera_height, 0.001)*0.05);
	float scale = exp2(floor(octave));
	float blend = fract(octave);
	return mix(mc_grain_octave(world_xz/scale), mc_grain_octave(world_xz/(scale*2.0)), blend);
}

// Woodland at chart scale: broad stands where the cover passes about a half,
// with a soft watercolour edge; no crowns, no speckle.
float mc_stand(float woodland) {
	return smoothstep(0.30, 0.56, woodland);
}

// The wash for this land. `temperature` today's ground temperature (C) from
// the season, `snow` how much snow lies (0-1).
vec3 mc_wash(float rain, float warm, float height, float stand, float temperature, float snow) {
	float lush = smoothstep(0.52, 0.86, rain);
	float dry = 1.0-smoothstep(0.26, 0.50, rain);
	float arid = (1.0-smoothstep(0.08, 0.26, rain))*smoothstep(0.35, 0.65, warm);
	float cold = 1.0-smoothstep(0.13, 0.30, warm);
	vec3 open = mix(MC_WASH_MEADOW, MC_WASH_LUSH, lush);
	open = mix(open, MC_WASH_STEPPE, dry);
	open = mix(open, MC_WASH_DRYLAND, arid);
	float marsh = smoothstep(0.72, 0.92, rain)*(1.0-smoothstep(0.15, 0.9, height));
	open = mix(open, MC_WASH_WETLAND, marsh*0.70);
	open = mix(open, MC_WASH_TUNDRA, cold*0.85);
	// Grass rests to straw in the cold months where it grows at all.
	float resting = (1.0-smoothstep(2.0, 13.0, temperature))*smoothstep(0.20, 0.55, rain)*(1.0-cold);
	open = mix(open, MC_WASH_RESTING, resting*0.55);
	vec3 wood = mix(MC_WASH_WOOD, MC_WASH_WOOD_COLD, max(cold, 1.0-smoothstep(0.25, 0.45, warm))*0.8);
	wood = mix(wood, MC_WASH_WOOD_DRY, dry*0.7);
	vec3 wash = mix(open, wood, stand);
	// Bare high ground above the treeline.
	wash = mix(wash, MC_WASH_UPLAND, smoothstep(4.5, 9.0, height)*0.75);
	return mix(wash, MC_WASH_SNOW, clamp(snow, 0.0, 1.0));
}

// The landform the chart draws, generalised the way a cartographer
// generalises it: the broad hills, ridges and valleys carry the light, and
// the small ridges of the ground only whisper, so the sheet reads as land
// and never as a corrugated texture. Heights come from the streamed patch
// (map_coast.gdshaderinc) where it covers the view, elsewhere the macro
// raster. Returns (generalised height, its screen-pixel rate); `normal` is
// the generalised normal. The rate is the height's slope times the pixel
// footprint: no derivatives, so it is safe inside the terrain's branches.
float mc_height_at(vec2 xz, bool on_patch) {
	if (on_patch) {
		float spread;
		return coast_patch_triangle(xz-terrain_grid.xy, spread);
	}
	return coast_mask_height(xz);
}

// Derivative of coast_catmull_rom's weights (map_coast.gdshaderinc).
vec4 mc_catmull_rom_slope(float t) {
	return vec4(-0.5+t*(2.0-1.5*t), t*(-5.0+4.5*t), 0.5+t*(4.0-4.5*t), t*(-1.0+1.5*t));
}

// The streamed patch's heights as one smooth (Catmull-Rom) surface through
// its samples, with its exact slope: smooth to the first derivative, so
// relief shaded from it shows no triangle facets and no cell seams.
// `rel` world xz minus the patch centre. Returns the height; `gradient` km/km.
float mc_patch_smooth(vec2 rel, out vec2 gradient) {
	float cells = max(terrain_grid.w-1.0, 1.0);
	vec2 cell = clamp((rel/terrain_grid.z+0.5)*cells, vec2(0.0), vec2(terrain_grid.w-1.001));
	ivec2 base = ivec2(floor(cell));
	vec2 f = fract(cell);
	vec4 wx = coast_catmull_rom(f.x);
	vec4 wy = coast_catmull_rom(f.y);
	vec4 dx = mc_catmull_rom_slope(f.x);
	vec4 dy = mc_catmull_rom_slope(f.y);
	vec4 r0 = vec4(coast_patch_height_at(base+ivec2(-1,-1)), coast_patch_height_at(base+ivec2(0,-1)), coast_patch_height_at(base+ivec2(1,-1)), coast_patch_height_at(base+ivec2(2,-1)));
	vec4 r1 = vec4(coast_patch_height_at(base+ivec2(-1,0)), coast_patch_height_at(base), coast_patch_height_at(base+ivec2(1,0)), coast_patch_height_at(base+ivec2(2,0)));
	vec4 r2 = vec4(coast_patch_height_at(base+ivec2(-1,1)), coast_patch_height_at(base+ivec2(0,1)), coast_patch_height_at(base+ivec2(1,1)), coast_patch_height_at(base+ivec2(2,1)));
	vec4 r3 = vec4(coast_patch_height_at(base+ivec2(-1,2)), coast_patch_height_at(base+ivec2(0,2)), coast_patch_height_at(base+ivec2(1,2)), coast_patch_height_at(base+ivec2(2,2)));
	vec4 across = vec4(dot(wx, r0), dot(wx, r1), dot(wx, r2), dot(wx, r3));
	vec4 across_slope = vec4(dot(dx, r0), dot(dx, r1), dot(dx, r2), dot(dx, r3));
	float cell_km = terrain_grid.z/cells;
	gradient = vec2(dot(wy, across_slope), dot(dy, across))/cell_km;
	return dot(wy, across);
}

vec2 mc_landform(vec2 xz, float height, float pixel_world, bool use_patch, out vec3 normal) {
	normal = vec3(0.0, 1.0, 0.0);
	vec2 rel = xz-terrain_grid.xy;
	float cell = terrain_grid.z/max(terrain_grid.w-1.0, 1.0);
	bool on_patch = use_patch && coast_patch_ready();
	if (on_patch && max(abs(rel.x), abs(rel.y))+max(cell*5.0, pixel_world*28.0) >= terrain_grid.z*0.5) { on_patch = false; }
	if (!on_patch) {
		if (!coast_mask_ready()) { return vec2(height, 0.0); }
		cell = coast_grid1.z > 0.0 ? coast_grid1.z : coast_grid0.z;
	}
	// The broad form, from four samples several cells out: wide enough that
	// the mesh's triangle facets average away.
	float broad = max(cell*5.0, pixel_world*28.0);
	vec4 b = vec4(mc_height_at(xz-vec2(broad, 0.0), on_patch), mc_height_at(xz+vec2(broad, 0.0), on_patch),
		mc_height_at(xz-vec2(0.0, broad), on_patch), mc_height_at(xz+vec2(0.0, broad), on_patch));
	vec2 gradient = vec2(b.y-b.x, b.w-b.z)/(2.0*broad);
	float local = dot(b, vec4(0.25));
	if (on_patch) {
		// The finer form (a cell or two) from the smooth surface, whispering.
		vec2 fine_gradient;
		local = mix(mc_patch_smooth(rel, fine_gradient), local, 0.72);
		gradient = mix(fine_gradient, gradient, 0.70);
	}
	normal = normalize(vec3(-gradient.x, 1.0, -gradient.y));
	// Near the shore keep the true height, so contours never cross the coast.
	return vec2(mix(height, local, smoothstep(0.004, 0.03, min(height, local))), length(gradient)*pixel_world);
}

// The sea at chart scale: a pale slate wash on the same paper as the land,
// deepening a little over deep water, so the coast is the edge of the land's
// colour and never a black gulf. `depth` km below sea level.
vec3 mc_chart_sea(float depth, vec2 world_xz, float camera_height) {
	vec3 paper = MC_PAPER*(1.0+mc_grain(world_xz, camera_height)*0.030);
	return paper*mix(MC_WASH_SEA_SHALLOW, MC_WASH_SEA, smoothstep(0.01, 0.9, depth));
}

// Relief shading, as a copper-plate survey is washed: slopes facing the
// north-west light lift a little and warm, slopes turned away take a cool
// grey-violet shade. Flat ground keeps its wash. Relief is exaggerated more
// the wider the view, the cartographer's rule, so the continent keeps its
// ranges and the region its hills.
vec3 mc_relief(vec3 c, vec3 normal, float design_km) {
	float exaggeration = clamp(3.5*pow(max(design_km, 0.0001)/0.03, 0.35), 3.0, 12.0);
	vec3 n = normalize(vec3(normal.x*exaggeration, max(normal.y, 0.05), normal.z*exaggeration));
	const vec3 sun = vec3(-0.4609, 0.7815, -0.4208);
	float d = dot(n, sun)-sun.y;
	float shade = clamp(-d*1.15, 0.0, 0.58);
	float lit = clamp(d*1.10, 0.0, 0.30);
	c *= mix(vec3(1.0), vec3(0.66, 0.68, 0.80), shade);
	c *= mix(vec3(1.0), vec3(1.12, 1.08, 0.97), lit);
	return c;
}

// The known world's edge as a drying wash: within a few dozen pixels of the
// frontier ink the washes thin raggedly back to bare paper, with a faint
// pigment rim where the wash dried. `inland_px` screen pixels inland.
vec3 mc_frontier_wash(vec3 chart, vec3 paper, float inland_px, vec2 world_xz, float pixel_world) {
	if (inland_px > 60.0) { return chart; }
	float blot = map_paper_noise(world_xz/max(pixel_world*38.0, 0.00001))*0.7
		+map_paper_noise(world_xz/max(pixel_world*9.0, 0.00001)+vec2(3.1, -7.7))*0.3;
	float d = inland_px+(blot-0.5)*26.0;
	float thin = 1.0-smoothstep(2.0, 34.0, d);
	float rim = 1.0-smoothstep(0.0, 2.5, abs(d-3.0));
	chart = mix(chart, paper, thin*0.60);
	return chart*(1.0-rim*0.10);
}

// The known land at chart scale. `landform` and `light_normal` from
// mc_landform, `rain`/`warm`/`woodland` from mc_fields (woodland already
// cleared where it was cut), `temperature` and `snow` from the season and the
// sky, `coast_height`/`coast_height_px` the shore height and its screen rate,
// `frontier_px` pixels inland from the frontier ink (a large number when far
// from it), `resources` the resource view (0-1).
vec3 mc_chart_ground(vec3 ground, vec2 landform, vec3 light_normal, float pixel_world, float design_km, float rain, float warm, float woodland, float slope, float temperature, float snow, float coast_height, float coast_height_px, float frontier_px, float camera_height, float resources) {
	vec3 paper = MC_PAPER*(1.0+mc_grain(ground.xz, camera_height)*0.030);
	float stand = mc_stand(woodland)*(1.0-smoothstep(0.42, 0.82, slope));
	vec3 chart = paper*mc_wash(rain, warm, ground.y, stand, temperature, snow);
	// The resource view reads as land cover here too.
	chart = mix(chart, chart*vec3(0.80, 1.12, 0.84), resources*stand*0.60);
	chart = mc_relief(chart, light_normal, design_km);
	// Engraved contours (world_beauty): faint sepia over the washes.
	float contour = wb_contours(landform.x, landform.y, pixel_world);
	chart = mix(chart, MAP_SEPIA, contour*0.18);
	// The coast is one inked line where the land rises out of the sea.
	float shore_px = coast_height/max(coast_height_px, 0.0000001);
	float coast_ink = (1.0-smoothstep(0.9, 1.9, shore_px))*step(0.0, coast_height);
	chart = mix(chart, MAP_INK*1.3, coast_ink*0.85);
	return mc_frontier_wash(chart, paper, frontier_px, ground.xz, pixel_world);
}

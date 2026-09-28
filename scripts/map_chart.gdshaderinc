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
// Include after map_palette.gdshaderinc (MAP_*, map_paper_*), coast_mask
// and map_coast (the streamed patch's heights).
// Values are linear. No derivatives are taken here, so every function is safe
// inside the terrain shader's branches.

// Where the chart takes over, in km per design pixel (1/1080 of the view's
// height, the unit map_glyph and the rivers use). Nothing of it at the
// 50,000 ft view, all of it at the Region view, at any window size or aspect.
// The streamed patch's heights again, with box-filtered mip levels, for the
// generalised landform (local_terrain.gd binds it with terrain_heights).
uniform sampler2D chart_relief : filter_linear_mipmap, repeat_disable;
// Its land cover likewise (terrain_patch_builder.gd `cover`): woodland,
// rainfall, warmth, and land (1) or water (0).
uniform sampler2D chart_cover : filter_linear_mipmap, repeat_disable;
// Every place the chart draws worked land round (scripts/chart_places.gd):
// x, z, how far its fields reach (km), 0 ours or 1 a stranger's.
uniform int chart_place_count = 0;
uniform vec4 chart_places[24];
// The same places' built ground: radius (km), 1 walled + 2 ruined, the
// holder's colour packed r*65536+g*256+b (0-255), its strength.
uniform vec4 chart_towns[24];

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
const vec3 MC_WASH_UPLAND = vec3(0.860, 0.830, 0.840);
const vec3 MC_WASH_SUMMIT = vec3(1.060, 1.050, 1.080);
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
	// Height as a layer-tinted survey shows it: rising ground warms toward
	// buff, the high country greys to bare stone above the treeline, and the
	// summits lighten, as the heights catch the light on a relief map.
	wash *= mix(vec3(1.0), vec3(1.03, 0.97, 0.88), smoothstep(0.8, 3.5, height)*0.55);
	wash = mix(wash, MC_WASH_UPLAND, smoothstep(3.8, 7.0, height)*0.80);
	wash = mix(wash, MC_WASH_SUMMIT, smoothstep(6.5, 9.5, height)*0.65);
	return mix(wash, MC_WASH_SNOW, clamp(snow, 0.0, 1.0));
}

// Derivative of coast_catmull_rom's weights (map_coast.gdshaderinc).
vec4 mc_catmull_rom_slope(float t) {
	return vec4(-0.5+t*(2.0-1.5*t), t*(-5.0+4.5*t), 0.5+t*(4.0-4.5*t), t*(-1.0+1.5*t));
}

float mc_level_height(ivec2 texel, int level, ivec2 size) {
	return texelFetch(chart_relief, clamp(texel, ivec2(0), size-ivec2(1)), level).r;
}

// The streamed patch's heights at mip `level` (each texel the mean of
// 2^level x 2^level samples: a true low-pass, where sparse point samples
// would alias every bump into the slope) as one smooth Catmull-Rom surface,
// with its exact slope: no triangle facets, no cell seams. `rel` world xz
// minus the patch centre. Returns the height; `gradient` km/km.
float mc_patch_bicubic(vec2 rel, int level, out vec2 gradient) {
	ivec2 size = textureSize(chart_relief, level);
	float scale = exp2(float(level));
	float cells = max(terrain_grid.w-1.0, 1.0);
	vec2 texel = clamp(((rel/terrain_grid.z+0.5)*cells+0.5)/scale-0.5, vec2(0.0), vec2(size)-1.001);
	ivec2 base = ivec2(floor(texel));
	vec2 f = fract(texel);
	vec4 wx = coast_catmull_rom(f.x);
	vec4 wy = coast_catmull_rom(f.y);
	vec4 dx = mc_catmull_rom_slope(f.x);
	vec4 dy = mc_catmull_rom_slope(f.y);
	vec4 r0 = vec4(mc_level_height(base+ivec2(-1,-1), level, size), mc_level_height(base+ivec2(0,-1), level, size), mc_level_height(base+ivec2(1,-1), level, size), mc_level_height(base+ivec2(2,-1), level, size));
	vec4 r1 = vec4(mc_level_height(base+ivec2(-1,0), level, size), mc_level_height(base, level, size), mc_level_height(base+ivec2(1,0), level, size), mc_level_height(base+ivec2(2,0), level, size));
	vec4 r2 = vec4(mc_level_height(base+ivec2(-1,1), level, size), mc_level_height(base+ivec2(0,1), level, size), mc_level_height(base+ivec2(1,1), level, size), mc_level_height(base+ivec2(2,1), level, size));
	vec4 r3 = vec4(mc_level_height(base+ivec2(-1,2), level, size), mc_level_height(base+ivec2(0,2), level, size), mc_level_height(base+ivec2(1,2), level, size), mc_level_height(base+ivec2(2,2), level, size));
	vec4 across = vec4(dot(wx, r0), dot(wx, r1), dot(wx, r2), dot(wx, r3));
	vec4 across_slope = vec4(dot(dx, r0), dot(dx, r1), dot(dx, r2), dot(dx, r3));
	gradient = vec2(dot(wy, across_slope), dot(dy, across))*cells/(terrain_grid.z*scale);
	return dot(wy, across);
}

// The landform the chart draws, generalised the way a cartographer
// generalises it: the broad hills, ridges and valleys carry the light, and
// the small ridges of the ground only whisper, so the sheet reads as land
// and never as a corrugated texture. Heights come from the streamed patch
// (map_coast.gdshaderinc) where it covers the view, elsewhere the macro
// raster. Returns (generalised height, its screen-pixel rate); `normal` is
// the generalised normal. The rate is the height's slope times the pixel
// footprint: no derivatives, so it is safe inside the terrain's branches.
vec2 mc_landform(vec2 xz, float height, float pixel_world, float design_km, bool use_patch, out vec3 normal, out float prominence) {
	normal = vec3(0.0, 1.0, 0.0);
	prominence = 1.0;
	vec2 rel = xz-terrain_grid.xy;
	float cell = terrain_grid.z/max(terrain_grid.w-1.0, 1.0);
	// The scale the chart generalises to: about 9 km at the Region view (the
	// ground's small hills stay a whisper under the ranges and valleys),
	// 20 km at the next widening, 55 km across a continent.
	float broad = max(cell*3.0, 9.0*pow(max(design_km, 0.0001)/0.078, 0.6));
	bool on_patch = use_patch && coast_patch_ready() && max(abs(rel.x), abs(rel.y))+broad < terrain_grid.z*0.5
		&& textureSize(chart_relief, 0).x == int(terrain_grid.w);
	vec2 gradient;
	float local;
	if (on_patch) {
		// The form from two box-filtered levels, blended so it never steps
		// as the view widens.
		float level = clamp(log2(broad/cell/3.5), 0.0, 5.0);
		int l0 = int(floor(level));
		vec2 g0; vec2 g1;
		float h0 = mc_patch_bicubic(rel, l0, g0);
		float h1 = mc_patch_bicubic(rel, l0+1, g1);
		gradient = mix(g0, g1, fract(level));
		local = mix(h0, h1, fract(level));
		prominence = smoothstep(0.012, 0.05, length(g1));
	} else {
		if (!coast_mask_ready()) { return vec2(height, 0.0); }
		float raster = max(coast_grid1.z > 0.0 ? coast_grid1.z : coast_grid0.z, broad*0.5);
		vec4 b = vec4(coast_mask_height(xz-vec2(raster, 0.0)), coast_mask_height(xz+vec2(raster, 0.0)),
			coast_mask_height(xz-vec2(0.0, raster)), coast_mask_height(xz+vec2(0.0, raster)));
		gradient = vec2(b.y-b.x, b.w-b.z)/(2.0*raster);
		local = dot(b, vec4(0.25));
		prominence = smoothstep(0.012, 0.05, length(gradient));
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

// Water-line ink: the slate blue of the rivers, a little softer.
const vec3 MC_WATER_INK = vec3(0.070, 0.135, 0.170);

// Signed distance from the shore as the map draws it, in screen pixels:
// positive over water, negative over land. The shore is the one the land and
// the sea already cut the coast along (map_coast coast_patch_ground: the
// smooth surface through the patch heights, wobbled a little so it reads as
// bays and points), measured from its own value and slope, so every coastal
// line drawn from this lies exactly on the coast. First order, so exact near
// the shore where the lines are drawn; a large value when the patch does not
// cover the point or no shore is near. No derivatives.
float mc_shore_px(vec2 xz, float pixel_world) {
	vec2 rel = xz-terrain_grid.xy;
	if (!coast_patch_ready() || max(abs(rel.x), abs(rel.y)) > terrain_grid.z*0.49
			|| textureSize(chart_relief, 0).x != int(terrain_grid.w)) { return 1.0e6; }
	vec2 gradient;
	float h = mc_patch_bicubic(rel, 0, gradient);
	float slope = max(length(gradient), 0.00001);
	float px = max(pixel_world, 0.000001);
	if (abs(h)/slope > px*40.0) { return h > 0.0 ? -1.0e6 : 1.0e6; }
	// The visible shore: the value and slope of the very surface the coast
	// is cut along (a forward difference half a pixel across).
	float step = px*0.5;
	float v = coast_patch_ground(rel, pixel_world, 0.0);
	vec2 dv = vec2(coast_patch_ground(rel+vec2(step, 0.0), pixel_world, 0.0)-v,
		coast_patch_ground(rel+vec2(0.0, step), pixel_world, 0.0)-v)/step;
	return -v/max(length(dv), slope*0.25)/px;
}

// The patch's land cover averaged over about `width_px` screen pixels round
// `xz` (its box-filtered levels, trilinear): (woodland, rainfall, warmth,
// land share). Land share 0.5 is the shore with every jag smaller than the
// width smoothed away. (-1) when the patch's cover is not bound here.
vec4 mc_cover(vec2 xz, float width_px, float pixel_world) {
	vec2 rel = xz-terrain_grid.xy;
	if (!coast_patch_ready() || textureSize(chart_cover, 0).x != int(terrain_grid.w)
			|| max(abs(rel.x), abs(rel.y)) > terrain_grid.z*0.5) { return vec4(-1.0); }
	float cells = max(terrain_grid.w-1.0, 1.0);
	vec2 uv = ((rel/terrain_grid.z+0.5)*cells+0.5)/terrain_grid.w;
	float cell_px = terrain_grid.z/cells/max(pixel_world, 0.000001);
	return textureLod(chart_cover, uv, max(log2(width_px/cell_px), 0.0));
}

// The same, averaged over about `width_km` on the ground: the same answer
// for every pixel that asks about one place.
vec4 mc_cover_km(vec2 xz, float width_km) {
	vec2 rel = xz-terrain_grid.xy;
	if (!coast_patch_ready() || textureSize(chart_cover, 0).x != int(terrain_grid.w)
			|| max(abs(rel.x), abs(rel.y)) > terrain_grid.z*0.5) { return vec4(-1.0); }
	float cells = max(terrain_grid.w-1.0, 1.0);
	vec2 uv = ((rel/terrain_grid.z+0.5)*cells+0.5)/terrain_grid.w;
	return textureLod(chart_cover, uv, max(log2(width_km*cells/terrain_grid.z), 0.0));
}

// The coast's own ink, half of it drawn by the land and half by the sea
// from the same shore, so the line is crisp and even. `shore_px` from
// mc_shore_px (either sign). Returns ink coverage.
float mc_coast_ink(float shore_px) {
	return 1.0-smoothstep(0.55, 1.35, abs(shore_px));
}

// The sea drawn as an engraver draws it: three water-lines, each one long
// continuous stroke following an ever smoother shore (the land blurred over
// about three times the line's distance out, so every jag, inlet and islet
// smaller than that is smoothed away), and a sparse stipple of fine dots
// only in the inshore water, thinning out within a stroke's length of the
// land. Everything is held at a constant size on screen.
// `offshore_px` from mc_shore_px. `land1..3`: the land share round here
// blurred over 14, 27 and 45 pixels (mc_cover().w, -1 when not available),
// and `land1_px..land3_px` their screen-pixel rates (fwidth, taken by the
// caller outside any branch).
float mc_isoline(float land, float land_px, float level, float width) {
	return 1.0-smoothstep(width*0.5, width*0.5+0.70, abs(land-level)/max(land_px, 0.00001));
}

vec3 mc_waterlines(vec3 sea, float offshore_px, float land1, float land1_px, float land2, float land2_px, float land3, float land3_px, vec2 xz, float pixel_world) {
	float lines;
	if (land1 >= 0.0) {
		// 0.5 lies on the blurred shore; 0.25 and 0.17 lie about a quarter
		// and a third of the blur width out to sea: 3.5, 9 and 15 px.
		lines = mc_isoline(land1, land1_px, 0.25, 0.90)*0.64*step(1.5, offshore_px);
		lines = max(lines, mc_isoline(land2, land2_px, 0.17, 0.80)*0.46*step(offshore_px, 60.0));
		lines = max(lines, mc_isoline(land3, land3_px, 0.17, 0.70)*0.30*step(offshore_px, 90.0));
	} else {
		lines = (1.0-smoothstep(0.42, 1.15, abs(offshore_px-4.0)))*0.64*step(1.5, offshore_px);
	}
	sea = mix(sea, MC_WATER_INK*1.4, lines*0.75);
	// Stipple: fine dots one to a small cell, only close inshore.
	float inshore = land3 < 0.0 ? 1.0-smoothstep(8.0, 22.0, offshore_px) : smoothstep(0.06, 0.30, land3);
	if (inshore <= 0.0) { return sea; }
	float octave = log2(max(pixel_world, 0.000001)*6.0/0.001);
	float level = floor(octave);
	float blend = fract(octave);
	float dots = 0.0;
	for (int k = 0; k < 2; k++) {
		float cell = 0.001*exp2(level+float(k));
		vec2 p = xz/cell;
		vec2 c = floor(p);
		vec2 centre = c+0.2+0.6*vec2(map_paper_hash(c+vec2(3.0, 7.0)), map_paper_hash(c+vec2(-11.0, 5.0)));
		float keep = step(map_paper_hash(c+vec2(13.0, -2.0)), 0.42*inshore);
		float d = length(p-centre)*cell/max(pixel_world, 0.000001);
		dots = max(dots, (1.0-smoothstep(0.30, 0.80, d))*keep*(k == 0 ? 1.0-blend : blend));
	}
	return mix(sea, MC_WATER_INK*1.6, dots*0.34*step(2.5, offshore_px));
}

// Relief lighting, as a copper-plate survey is washed: how much this ground
// faces the north-west light compared with flat ground (-1..1), from the
// generalised landform. Relief is exaggerated more the wider the view, the
// cartographer's rule, so the continent keeps its ranges and the region its
// hills.
float mc_light(vec3 normal, float design_km) {
	float exaggeration = clamp(4.2*pow(max(design_km, 0.0001)/0.03, 0.35), 3.2, 14.0);
	vec3 n = normalize(vec3(normal.x*exaggeration, max(normal.y, 0.05), normal.z*exaggeration));
	const vec3 sun = vec3(-0.4609, 0.7815, -0.4208);
	return dot(n, sun)-sun.y;
}

// Slopes facing the light lift a little and warm, slopes turned away take a
// cool grey-violet shade. Flat ground keeps its wash.
// `prominence` (0-1) how much this is real relief (a range, a valley wall)
// rather than the small hills of a rolling plain: those only whisper.
vec3 mc_relief(vec3 c, float light, float prominence) {
	float strength = mix(0.45, 1.0, prominence);
	float shade = clamp(-light*1.15, 0.0, 0.58)*strength;
	float lit = clamp(light*1.10, 0.0, 0.30)*strength;
	c *= mix(vec3(1.0), vec3(0.66, 0.68, 0.80), shade);
	c *= mix(vec3(1.0), vec3(1.12, 1.08, 0.97), lit);
	return c;
}

// Contours as an engraver cuts them: lines of equal height, a little heavier
// where the ground is steep, faint on the flats where they would only
// wander, every fourth an index line; a shade darker on slopes turned from
// the light and lighter on the lit ones (illuminated contours, restrained).
// Where they would crowd into a smear they give way to hachures. `height`
// the generalised height, `slope` its gradient (km/km), `light` from
// mc_light. The interval doubles as the view widens, blended so no line
// pops. Returns ink coverage (0-1).
float mc_contours(float height, float slope, float pixel_world, float light) {
	if (height <= 0.004) { return 0.0; }
	float octave = log2(max(pixel_world, 0.000001)/0.012);
	float level = floor(octave);
	float blend = fract(octave);
	float heavy = smoothstep(0.04, 0.30, slope);
	float coverage = 0.0;
	for (int k = 0; k < 2; k++) {
		float interval = 0.025*exp2(level+float(k));
		float fade = k == 0 ? 1.0-blend : blend;
		float u = height/interval;
		// Contour units per screen pixel, so widths are held in pixels.
		float per_px = max(slope*pixel_world/interval, 0.00001);
		float d = abs(fract(u+0.5)-0.5)/per_px;
		float index = 1.0-step(0.5, abs(mod(floor(u+0.5), 4.0)));
		float half_w = mix(0.42, 0.80, heavy)*mix(1.0, 1.40, index);
		float line = 1.0-smoothstep(half_w-0.30, half_w+0.45, d);
		float crowd = 1.0-smoothstep(0.16, 0.26, per_px);
		coverage = max(coverage, line*fade*crowd*mix(0.55, 1.0, index));
	}
	float flats = mix(0.22, 1.0, smoothstep(0.010, 0.045, slope));
	return coverage*flats*mix(1.0, 0.55, clamp(light*2.0, 0.0, 1.0));
}

// Hachures (Lehmann's rule): on steep ground, where contours would crowd,
// short strokes run down the fall line in rows between the contour levels,
// thicker the steeper the slope, the way copper-plate surveys drew their
// escarpments. Strokes are held about 4.5 pixels apart; their bearing is
// quantised to sixteen and eased between neighbours so no swirl or seam
// shows, and rows are staggered like a hand-cut plate. `gradient` km/km.
// Returns ink coverage (0-1).
float mc_hachure_set(vec2 xz, float bearing, float spacing_km, float pixel_world, float stagger, float half_w) {
	vec2 across = vec2(cos(bearing), sin(bearing));
	float u = dot(xz, across)/spacing_km+stagger;
	float d = abs(fract(u)-0.5)*spacing_km/max(pixel_world, 0.000001);
	return 1.0-smoothstep(half_w-0.30, half_w+0.40, d);
}

float mc_hachures(vec2 xz, float height, vec2 gradient, float pixel_world) {
	float slope = length(gradient);
	if (slope < 0.015 || height <= 0.004) { return 0.0; }
	float octave = log2(max(pixel_world, 0.000001)/0.012);
	float level = floor(octave);
	float blend = fract(octave);
	// The strokes run along the fall line; `across` is perpendicular to it.
	float angle = atan(-gradient.x, gradient.y);
	float bin = fract(angle/3.14159265)*16.0;
	float k0 = floor(bin);
	float ease = smoothstep(0.30, 0.70, bin-k0);
	float half_w = mix(0.35, 0.85, smoothstep(0.06, 0.45, slope));
	float coverage = 0.0;
	for (int k = 0; k < 2; k++) {
		float interval = 0.025*exp2(level+float(k));
		float fade = k == 0 ? 1.0-blend : blend;
		// Only where this interval's contours would crowd (closer than ~8 px).
		float spacing_px = interval/max(slope*pixel_world, 0.000001);
		float steep = 1.0-smoothstep(5.0, 9.0, spacing_px);
		if (steep*fade <= 0.001) { continue; }
		// Rows two contour intervals tall, so each stroke reads as a stroke;
		// where even those would be a few pixels (a sea cliff seen from afar)
		// they would only stipple, and the shading carries the slope.
		float row_px = 2.0*spacing_px;
		steep *= smoothstep(4.5, 7.0, row_px);
		if (steep*fade <= 0.001) { continue; }
		float v = height/(interval*2.0);
		float row = fract(v);
		float dash = smoothstep(0.03, 0.10, row)*(1.0-smoothstep(0.90, 0.97, row));
		float stagger = mod(floor(v), 2.0)*0.5;
		float spacing_km = 4.5*pixel_world;
		float a = mc_hachure_set(xz, k0*3.14159265/16.0, spacing_km, pixel_world, stagger, half_w);
		float b = mc_hachure_set(xz, (k0+1.0)*3.14159265/16.0, spacing_km, pixel_world, stagger, half_w);
		coverage = max(coverage, mix(a, b, ease)*dash*steep*fade);
	}
	return coverage;
}

// The direction up the screen, on the ground (world x, z), from the view's
// inverse matrix: map symbols drawn in profile stand upright however the
// camera is turned.
vec2 mc_screen_up(mat4 inv_view) {
	vec2 up = inv_view[1].xz;
	if (dot(up, up) < 0.000001) { up = -inv_view[2].xz; }
	return dot(up, up) > 0.000001 ? normalize(up) : vec2(0.0, -1.0);
}

// Height (km) averaged over about `scale_km` round `xz`: the streamed
// patch's box-filtered levels where it covers the point (one filtered read),
// else the macro raster; -1 when neither is ready.
float mc_relief_height(vec2 xz, float scale_km, bool use_patch) {
	vec2 rel = xz-terrain_grid.xy;
	if (use_patch && coast_patch_ready() && max(abs(rel.x), abs(rel.y)) < terrain_grid.z*0.5
			&& textureSize(chart_relief, 0).x == int(terrain_grid.w)) {
		float cells = max(terrain_grid.w-1.0, 1.0);
		vec2 uv = ((rel/terrain_grid.z+0.5)*cells+0.5)/terrain_grid.w;
		return textureLod(chart_relief, uv, max(log2(scale_km*cells/terrain_grid.z), 0.0)).r;
	}
	if (coast_mask_ready()) { return coast_mask_height(xz); }
	return -1.0;
}

// Mountains at the far views, drawn the way old surveys drew ranges: small
// inked peaks in profile, lit from the west with the east face hatched,
// larger the higher the ground, standing wherever the land rises high and
// rugged (never on a smooth high plain). They stand upright however the map
// is turned, and the peak lower on the screen covers the ones behind it.
float mc_segment_distance(vec2 p, vec2 a, vec2 b) {
	vec2 ab = b-a;
	return length(p-a-ab*clamp(dot(p-a, ab)/dot(ab, ab), 0.0, 1.0));
}

// The peak of cell `c` in the grid at `level` (cells 8 x 2^level km):
// (centre xz, size km, height class 0-1; 0 when the cell has none).
vec4 mc_peak_at(vec2 c, float level, bool use_patch) {
	float cell = 8.0*exp2(level);
	vec2 salt = level*vec2(37.0, 91.0);
	vec2 jitter = vec2(map_paper_hash(c+vec2(11.0, 3.0)+salt), map_paper_hash(c+vec2(-7.0, 19.0)+salt));
	vec2 centre = (c+0.25+0.5*jitter)*cell;
	float h = mc_relief_height(centre, cell*0.35, use_patch);
	if (h < 2.6) { return vec4(centre, 0.0, 0.0); }
	float slope = length(vec2(mc_relief_height(centre+vec2(cell*0.5, 0.0), cell*0.35, use_patch)-h,
		mc_relief_height(centre+vec2(0.0, cell*0.5), cell*0.35, use_patch)-h))/(cell*0.5);
	float high = smoothstep(2.8, 6.0, h)*max(smoothstep(0.012, 0.05, slope), smoothstep(6.0, 8.0, h));
	if (high <= 0.05 || map_paper_hash(c+vec2(5.0, 5.0)+salt) > 0.12+0.66*high) { return vec4(centre, 0.0, 0.0); }
	return vec4(centre, cell*mix(0.85, 1.35, high), high);
}

// One peak drawn at `centre`, `size` km across, class `high`, seed `seed`:
// (outline ink, paper fill, hatching) coverage, and in `depth` how far down
// the screen it stands (for which peak covers which).
vec3 mc_peak_marks(vec2 xz, vec2 centre, float size, float high, float seed, vec2 up, float pixel_world) {
	vec2 d = xz-centre;
	vec2 q = vec2(dot(d, vec2(-up.y, up.x)), dot(d, up))/max(size, 0.0001);
	if (abs(q.x) > 0.60 || q.y < -0.40 || q.y > 0.80) { return vec3(0.0); }
	vec2 left = vec2(-0.50, -0.32);
	vec2 apex = vec2((seed-0.5)*0.26, mix(0.36, 0.66, high));
	vec2 right = vec2(0.50, -0.32);
	float px = size/max(pixel_world, 0.000001);
	// Flanks sweep in a little toward the summit, as a pen draws them.
	float t = clamp((q.y-left.y)/(apex.y-left.y), 0.0, 1.0);
	float bow = t*(1.0-t)*0.10;
	float x_left = mix(left.x, apex.x, t)+bow;
	float x_right = mix(right.x, apex.x, t)-bow;
	float inside = step(left.y, q.y)*step(q.y, apex.y)*step(x_left, q.x)*step(q.x, x_right);
	float lean_l = (apex.y-left.y)/length(apex-left);
	float lean_r = (apex.y-right.y)/length(apex-right);
	float dl = abs(q.x-x_left)*lean_l*px;
	float dr = abs(q.x-x_right)*lean_r*px;
	float in_height = step(left.y-0.02, q.y)*step(q.y, apex.y+0.02);
	float tip = length(q-apex)*px;
	float outline = (1.0-smoothstep(0.55, 1.35, min(min(dl, dr*0.85), tip)))*max(in_height, 1.0-step(0.0, tip-1.4))*smoothstep(-0.34, -0.22, q.y);
	if (inside <= 0.0 && outline <= 0.0) { return vec3(0.0); }
	// The east face in shade: fine strokes parallel to its flank.
	float east = step(mix(apex.x, apex.x*0.4+0.08, 1.0-t), q.x)*inside;
	vec2 flank = normalize(right-apex);
	float across = dot(q-apex, vec2(-flank.y, flank.x))*px;
	float hatch = (1.0-smoothstep(0.30, 0.85, abs(fract(across/2.7)-0.5)*2.7))*east;
	return vec3(outline, inside, hatch);
}

// The peaks, faded in as the view widens past the Region. Held about 34
// design pixels apart: as the view widens past an octave, every fourth peak
// grows and slides into the place of the coarser grid's peak while the other
// three fade, so at the octave both grids are the same and nothing pops.
vec3 mc_mountains(vec2 xz, float design_km, float pixel_world, bool use_patch, vec2 up) {
	float show = smoothstep(0.30, 0.80, design_km);
	if (show <= 0.0 || mc_relief_height(xz, 34.0*design_km*0.5, use_patch) < 1.6) { return vec3(0.0); }
	float octave = log2(34.0*design_km/8.0);
	float level = floor(octave);
	float grow = smoothstep(0.35, 0.65, fract(octave));
	float cell = 8.0*exp2(level);
	float front = -1.0e9;
	vec3 fading = vec3(0.0);
	// This level's peaks that do not carry on to the coarser grid: fading.
	if (grow < 0.99) {
		vec2 ic = floor(xz/cell);
		for (int y = -1; y <= 1; y++) {
			for (int x = -1; x <= 1; x++) {
				vec2 c = ic+vec2(float(x), float(y));
				if (all(equal(mod(c, 2.0), vec2(0.0)))) { continue; }
				vec4 peak = mc_peak_at(c, level, use_patch);
				float depth = -dot(peak.xy, up);
				if (peak.w <= 0.0 || depth <= front) { continue; }
				vec3 marks = mc_peak_marks(xz, peak.xy, peak.z*mix(1.0, 0.7, grow), peak.w, map_paper_hash(c+vec2(2.0, -9.0)+level*vec2(37.0, 91.0)), up, pixel_world);
				if (marks.x+marks.y <= 0.0) { continue; }
				front = depth;
				fading = marks*(1.0-grow);
			}
		}
	}
	// Each coarser peak, grown from the child that carries it on, drawn over
	// the fading ones.
	front = -1.0e9;
	vec3 best = vec3(0.0);
	vec2 ip = floor(xz/(2.0*cell));
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 parent_cell = ip+vec2(float(x), float(y));
			vec4 child = mc_peak_at(parent_cell*2.0, level, use_patch);
			vec4 parent = mc_peak_at(parent_cell, level+1.0, use_patch);
			float present = mix(step(0.001, child.w), step(0.001, parent.w), grow);
			if (present <= 0.01) { continue; }
			vec2 centre = mix(child.xy, parent.xy, grow);
			float size = mix(child.w > 0.0 ? child.z : parent.z*0.5, parent.w > 0.0 ? parent.z : child.z*1.2, grow);
			float high = mix(child.w > 0.0 ? child.w : parent.w, parent.w > 0.0 ? parent.w : child.w, grow);
			float seed = mix(map_paper_hash(parent_cell*2.0+vec2(2.0, -9.0)+level*vec2(37.0, 91.0)), map_paper_hash(parent_cell+vec2(2.0, -9.0)+(level+1.0)*vec2(37.0, 91.0)), grow);
			float depth = -dot(centre, up);
			if (depth <= front) { continue; }
			vec3 marks = mc_peak_marks(xz, centre, size, high, seed, up, pixel_world);
			if (marks.x+marks.y <= 0.0) { continue; }
			front = depth;
			best = marks*present;
		}
	}
	float covered = 1.0-best.y;
	return vec3(max(best.x, fading.x*covered), max(best.y, fading.y), max(best.z, fading.z*covered))*show;
}

// -- Woods, marsh and worked land in the same ink --------------------------

// How much of the ground at `xz` place `i` works (0-1): its reach, thinning
// raggedly outward.
float mc_worked_share(vec2 xz, vec4 place, int i) {
	float reach = place.z;
	vec2 offset = xz-place.xy;
	float d2 = dot(offset, offset);
	if (reach <= 0.0 || d2 > reach*reach*1.6) { return 0.0; }
	float ragged = map_paper_noise(offset/max(reach*0.35, 0.01)+vec2(float(i)*5.1, 3.7))-0.5;
	return 1.0-smoothstep(0.62, 1.0, sqrt(d2)/reach+ragged*0.30);
}

// The place whose worked land reaches over `xz` (within `margin_km` more),
// or -1: the trees ask it whether their spot is cleared.
int mc_nearest_place(vec2 xz, float margin_km) {
	int best = -1;
	float best_d = 1.0e9;
	for (int i = 0; i < 24; i++) {
		if (i >= chart_place_count) { break; }
		vec4 place = chart_places[i];
		float d = length(xz-place.xy)-(place.z*1.3+margin_km);
		if (d < 0.0 && d < best_d) { best_d = d; best = i; }
	}
	return best;
}

// One small symbol drawn in profile, upright on the screen, `size` km tall:
// kind 0 a tree (a round crown, or a narrow conifer when `variant` > 0.5,
// on a short trunk, the east side of the crown in shade), kind 1 a tuft of
// marsh reeds (three strokes over a short water line). Returns (ink, fill,
// shade) coverage.
vec3 mc_symbol_marks(int kind, vec2 xz, vec2 centre, float size, float variant, vec2 up, float pixel_world) {
	vec2 d = xz-centre;
	vec2 q = vec2(dot(d, vec2(-up.y, up.x)), dot(d, up))/max(size, 0.000001);
	if (abs(q.x) > 0.60 || abs(q.y) > 0.72) { return vec3(0.0); }
	float px = size/max(pixel_world, 0.000001);
	if (kind == 1) {
		// Reeds: a short water line and three strokes rising from it.
		float water = (1.0-smoothstep(0.40, 1.05, abs(q.y+0.30)*px))*(1.0-smoothstep(0.34, 0.44, abs(q.x)));
		float reeds = 0.0;
		for (int k = -1; k <= 1; k++) {
			float x0 = float(k)*0.19;
			float top = k == 0 ? 0.30 : 0.10;
			float stroke = (1.0-smoothstep(0.30, 0.95, abs(q.x-x0-(q.y+0.30)*float(k)*0.18)*px))*step(-0.30, q.y)*step(q.y, top);
			reeds = max(reeds, stroke);
		}
		return vec3(max(water, reeds), 0.0, 0.0);
	}
	float trunk = (1.0-smoothstep(0.30, 0.85, abs(q.x)*px))*step(-0.52, q.y)*step(q.y, -0.10);
	float inside;
	float edge;
	float east;
	if (variant > 0.5) {
		vec2 apex = vec2(0.0, 0.62);
		vec2 left = vec2(-0.27, -0.22);
		vec2 right = vec2(0.27, -0.22);
		float t = clamp((q.y-left.y)/(apex.y-left.y), 0.0, 1.0);
		inside = step(left.y, q.y)*step(q.y, apex.y)*step(abs(q.x), mix(right.x, 0.0, t));
		edge = min(min(mc_segment_distance(q, left, apex), mc_segment_distance(q, apex, right)), mc_segment_distance(q, left, right))*px;
		east = step(0.02, q.x);
	} else {
		vec2 crown = vec2(0.0, 0.14);
		float r = 0.36;
		float dist = length(q-crown);
		inside = step(dist, r);
		edge = abs(dist-r)*px;
		east = smoothstep(-0.06, 0.10, dot(q-crown, vec2(0.80, -0.60)));
	}
	float outline = 1.0-smoothstep(0.40, 1.10, edge);
	return vec3(max(outline, trunk*(1.0-inside)), inside, inside*east);
}

// How much this is marsh (0-1): very wet ground low by its rivers and
// shores, from the patch's blurred cover (rainfall) and the height, as the
// simulation's own wet-meadow land lies (rain above ~0.7, under ~0.9 km).
float mc_marsh(vec4 cover, float height) {
	return smoothstep(0.62, 0.78, cover.y)*(1.0-smoothstep(0.35, 0.95, height))*(1.0-smoothstep(0.45, 0.70, cover.x));
}

// The symbol of cell `c` in the grid at `level` (cells base_km x 2^level):
// (centre xz, variant, present 0-1). Trees stand where the blurred woodland
// makes a stand, conifers where it is cold; reeds where the land is low and
// wet (marsh). Every read is of the patch's box-filtered cover.
vec4 mc_symbol_at(int kind, vec2 c, float level, float base_km, float pixel_world, int near_place) {
	float cell = base_km*exp2(level);
	vec2 salt = level*vec2(53.0, 17.0)+float(kind)*vec2(211.0, -97.0);
	vec2 jitter = vec2(map_paper_hash(c+vec2(3.0, 11.0)+salt), map_paper_hash(c+vec2(-9.0, 4.0)+salt));
	vec2 centre = (c+0.2+0.6*jitter)*cell;
	// Blurred by the symbol's own cell, so every pixel of it decides alike.
	vec4 cover = mc_cover_km(centre, cell*0.6);
	if (cover.w < 0.5) { return vec4(centre, 0.0, 0.0); }
	float want;
	float variant = 0.0;
	if (kind == 1) {
		want = mc_marsh(cover, mc_relief_height(centre, cell*0.5, true))*0.62;
	} else {
		// Trees mark the wood, they do not fill it: the wash carries a large
		// wood, the trees stand mainly along its margins (where the wider
		// ground round a tree is not all wood), with a sparse sprinkle inside,
		// sparser still as the view widens.
		float stand = smoothstep(0.30, 0.58, cover.x);
		float wide = smoothstep(0.35, 0.60, mc_cover_km(centre, cell*3.0).x);
		float margin = stand*(1.0-smoothstep(0.70, 0.95, wide));
		float inside = stand*smoothstep(0.70, 0.95, wide);
		float far = smoothstep(2.5, 5.0, level);
		want = margin*mix(0.40, 0.22, far)+inside*mix(0.10, 0.025, far);
		// Cleared where a place works the land.
		if (near_place >= 0) { want *= 1.0-mc_worked_share(centre, chart_places[near_place], near_place); }
		float cold = 1.0-smoothstep(0.26, 0.42, cover.z);
		variant = step(map_paper_hash(c+vec2(1.0, -5.0)+salt), cold);
	}
	if (want <= 0.02 || map_paper_hash(c+vec2(7.0, 7.0)+salt) > want) { return vec4(centre, variant, 0.0); }
	return vec4(centre, variant, 1.0);
}

// The front-most symbol covering `xz`, held about `cell_px` design pixels
// apart and passed across zoom octaves the way the peaks are (each coarser
// symbol grows out of the child that carries it on; the others fade), so a
// wood never pops or doubles as the view widens. Returns (ink, fill, shade).
vec3 mc_symbols(int kind, vec2 xz, float cell_px, float design_km, float pixel_world, vec2 up, float base_km, int near_place) {
	float octave = log2(max(cell_px*design_km/base_km, 0.000001));
	float level = floor(octave);
	// The hand-over takes a fifth of an octave: through the rest of the
	// zoom every symbol stands crisp, never half-faded.
	float grow = smoothstep(0.40, 0.60, fract(octave));
	float cell = base_km*exp2(level);
	float size_scale = kind == 1 ? 0.70 : 0.95;
	float front = -1.0e9;
	vec3 fading = vec3(0.0);
	if (grow < 0.99) {
		vec2 ic = floor(xz/cell);
		for (int y = -1; y <= 1; y++) {
			for (int x = -1; x <= 1; x++) {
				vec2 c = ic+vec2(float(x), float(y));
				if (all(equal(mod(c, 2.0), vec2(0.0)))) { continue; }
				vec4 symbol = mc_symbol_at(kind, c, level, base_km, pixel_world, near_place);
				float depth = -dot(symbol.xy, up);
				if (symbol.w <= 0.0 || depth <= front) { continue; }
				vec3 marks = mc_symbol_marks(kind, xz, symbol.xy, cell*size_scale*mix(1.0, 0.75, grow), symbol.z, up, pixel_world);
				if (marks.x+marks.y <= 0.0) { continue; }
				front = depth;
				fading = marks*(1.0-grow);
			}
		}
	}
	front = -1.0e9;
	vec3 best = vec3(0.0);
	vec2 ip = floor(xz/(2.0*cell));
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 parent_cell = ip+vec2(float(x), float(y));
			vec4 child = mc_symbol_at(kind, parent_cell*2.0, level, base_km, pixel_world, near_place);
			vec4 parent = mc_symbol_at(kind, parent_cell, level+1.0, base_km, pixel_world, near_place);
			float present = mix(child.w, parent.w, grow);
			if (present <= 0.01) { continue; }
			vec2 centre = mix(child.xy, parent.xy, grow);
			float depth = -dot(centre, up);
			if (depth <= front) { continue; }
			float variant = grow < 0.5 ? child.z : parent.z;
			vec3 marks = mc_symbol_marks(kind, xz, centre, cell*size_scale*mix(1.0, 2.0, grow), variant, up, pixel_world);
			if (marks.x+marks.y <= 0.0) { continue; }
			front = depth;
			best = marks*present;
		}
	}
	float covered = 1.0-best.y;
	return vec3(max(best.x, fading.x*covered), max(best.y, fading.y), max(best.z, fading.z*covered));
}

// Worked land round the places: fields drawn as parcels of fine parallel
// hatching (each laid its own way) and pasture as a sparse scatter of dots,
// thinning raggedly toward the edge of what a place farms. Parcels are a
// fixed size on the ground, so they never pop; the hatching is held about
// three pixels apart and blended across zoom octaves on shared lines.
// Returns (field ink, pasture ink, worked share 0-1).
vec3 mc_farmland(vec2 xz, float pixel_world) {
	float worked = 0.0;
	for (int i = 0; i < 24; i++) {
		if (i >= chart_place_count) { break; }
		worked = max(worked, mc_worked_share(xz, chart_places[i], i));
	}
	if (worked <= 0.0) { return vec3(0.0); }
	// Parcels about 700 m across on a gently wandering grid.
	float parcel_km = 0.7;
	vec2 p = xz/parcel_km;
	vec2 cell = floor(p+vec2(map_paper_noise(p*0.37)-0.5, map_paper_noise(p*0.37+vec2(9.0, 4.0))-0.5)*0.5);
	float kind = map_paper_hash(cell+vec2(19.0, -7.0));
	float angle = floor(map_paper_hash(cell+vec2(-3.0, 23.0))*4.0)*0.785398;
	vec2 across = vec2(cos(angle), sin(angle));
	float octave = log2(max(pixel_world*3.0/0.001, 0.000001));
	float level = floor(octave);
	float blend = fract(octave);
	float hatch = 0.0;
	for (int k = 0; k < 2; k++) {
		float spacing = 0.001*exp2(level+float(k));
		float u = dot(xz, across)/spacing;
		float line = 1.0-smoothstep(0.30, 0.85, abs(fract(u)-0.5)*spacing/max(pixel_world, 0.000001));
		hatch = max(hatch, line*(k == 0 ? 1.0-blend : 1.0));
	}
	// Parcels too small on screen to draw give way to the map's sign for
	// worked land: one fine diagonal hatch over it all.
	float resolved = 1.0-smoothstep(0.45, 0.90, pixel_world/parcel_km*8.0);
	float diagonal = 0.0;
	for (int k = 0; k < 2; k++) {
		float spacing = 0.001*exp2(level+float(k))*1.4;
		float u = dot(xz, vec2(0.7071, 0.7071))/spacing;
		float line = 1.0-smoothstep(0.30, 0.85, abs(fract(u)-0.5)*spacing/max(pixel_world, 0.000001));
		diagonal = max(diagonal, line*(k == 0 ? 1.0-blend : 1.0));
	}
	float fields = mix(diagonal*0.55, kind < 0.58 ? hatch : 0.0, resolved);
	// Pasture dots one to a small cell of a zoom octave, blended across
	// octaves so they never swim or pop.
	float speck = 0.0;
	float dot_octave = log2(max(pixel_world*5.0/0.001, 0.000001));
	for (int k = 0; k < 2; k++) {
		float dot_km = 0.001*exp2(floor(dot_octave)+float(k));
		vec2 dot_cell = floor(xz/dot_km);
		vec2 dot_at = (dot_cell+0.2+0.6*vec2(map_paper_hash(dot_cell+vec2(4.0, 9.0)), map_paper_hash(dot_cell+vec2(-2.0, 1.0))))*dot_km;
		float one = (1.0-smoothstep(0.35, 0.85, length(xz-dot_at)/max(pixel_world, 0.000001)))*step(map_paper_hash(dot_cell+vec2(-6.0, 2.0)), 0.45);
		speck = max(speck, one*(k == 0 ? 1.0-fract(dot_octave) : fract(dot_octave)));
	}
	float pasture = mix(speck*0.5, kind >= 0.58 && kind < 0.86 ? speck : 0.0, resolved);
	return vec3(fields*worked, pasture*worked, worked);
}

// -- Towns as small plans in ink --------------------------------------------

vec3 mc_unpack_colour(float packed) {
	float r = floor(packed/65536.0);
	float g = floor((packed-r*65536.0)/256.0);
	float b = packed-r*65536.0-g*256.0;
	return vec3(r, g, b)/255.0;
}

// Every place's built ground as an old chart draws a town: a light wash of
// its holder's colour (the same colour its mark on the map wears), blocks of
// houses in ink between the streets, densest at the market in the middle
// and thinning raggedly outward, and a wall round it if it has one, with
// small towers along it. Blocks are fixed on the ground (a zoom never
// rearranges a town) and melt into one even tone before they could shimmer.
// A burned town keeps only broken blocks and no colour. Returns the chart
// with the towns drawn on it.
vec3 mc_towns(vec3 chart, vec2 xz, float pixel_world, vec3 paper) {
	for (int i = 0; i < 24; i++) {
		if (i >= chart_place_count) { break; }
		vec4 place = chart_places[i];
		vec4 town = chart_towns[i];
		float r = town.x;
		vec2 offset = xz-place.xy;
		if (r <= 0.0 || dot(offset, offset) > r*r*1.5) { continue; }
		float d = length(offset);
		float r_px = r/max(pixel_world, 0.000001);
		// Smaller than its mark on the map: the mark alone says it.
		float shown = smoothstep(4.0, 9.0, r_px);
		if (shown <= 0.0) { continue; }
		float walled = mod(town.y, 2.0);
		float ruined = step(1.5, town.y);
		float seed = map_paper_hash(place.xy*0.37+vec2(float(i), 3.0));
		// The built edge wanders; a walled town stops at its wall.
		float ragged = (map_paper_noise(offset/max(r*0.30, 0.001)+vec2(seed*40.0, 7.0))-0.5)*(1.0-walled*0.8);
		float edge = d/r+ragged*0.35;
		float built = 1.0-smoothstep(0.80, 1.0, edge);
		// The holder's colour, washed lightly (ours: the paper, a shade warmer).
		vec3 accent = mc_unpack_colour(town.z);
		float strength = town.w*(1.0-ruined);
		vec3 wash = mix(paper*vec3(0.97, 0.93, 0.86), paper*mix(vec3(1.0), accent*1.25, 0.55), step(0.01, strength));
		chart = mix(chart, wash, built*0.55*shown);
		// Blocks on a street grid laid its own way, about a fifth of the
		// town's radius across, a little crooked from one to the next.
		float angle = seed*1.5708;
		vec2 axis = vec2(cos(angle), sin(angle));
		vec2 local = vec2(dot(offset, axis), dot(offset, vec2(-axis.y, axis.x)));
		float cell = r*0.19;
		vec2 c = floor(local/cell);
		vec2 f = fract(local/cell);
		vec2 lean = (vec2(map_paper_hash(c+vec2(2.0, 9.0)), map_paper_hash(c+vec2(-4.0, 1.0)))-0.5)*0.10;
		float in_block = step(abs(f.x-0.5+lean.x), 0.35)*step(abs(f.y-0.5+lean.y), 0.32);
		float centre_d = length((c+0.5)*cell)/r;
		float keep = map_paper_hash(c+vec2(seed*91.0, 13.0));
		float density = 1.0-smoothstep(0.45, 1.0, centre_d+ragged*0.25);
		density *= mix(1.0, 0.45, ruined);
		// The market: the blocks nearest the middle stay open.
		float market = step(centre_d, 0.14);
		float block = in_block*step(keep, density)*(1.0-market)*built;
		// Too small to draw one by one: an even tone of the same ink.
		float cell_px = cell/max(pixel_world, 0.000001);
		float resolved = smoothstep(2.2, 3.6, cell_px);
		float ink = mix(built*0.42*(1.0-ruined*0.4), block, resolved);
		chart = mix(chart, MAP_INK*1.35, ink*0.72*shown);
		// The wall, with small towers along it.
		if (walled > 0.5) {
			float wall_px = abs(d-r*1.02)/max(pixel_world, 0.000001);
			float wall = 1.0-smoothstep(0.55, 1.25, wall_px);
			float around = atan(offset.y, offset.x)*r/max(pixel_world, 0.000001);
			float tower = (1.0-smoothstep(1.2, 2.0, length(vec2(abs(fract(around/14.0)-0.5)*14.0, wall_px))))*step(wall_px, 2.5);
			chart = mix(chart, MAP_INK*1.3, max(wall, tower)*0.85*shown*(1.0-ruined*0.5));
		}
	}
	return chart;
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
vec3 mc_chart_ground(vec3 ground, vec2 landform, vec3 light_normal, float prominence, float pixel_world, float design_km, float rain, float warm, float woodland, float slope, float temperature, float snow, float coast_height, float coast_height_px, float frontier_px, float camera_height, float resources, bool use_patch, vec2 screen_up) {
	vec3 paper = MC_PAPER*(1.0+mc_grain(ground.xz, camera_height)*0.030);
	// Woods as broad masses: the patch's woodland blurred over a few pixels
	// (the per-vertex field alone mottles into camouflage), cleared where a
	// place works the land.
	// Blurred wider as the view widens, so the woods stay broad masses and
	// never print the small gaps of the woodland field as camouflage.
	vec4 cover = use_patch ? mc_cover(ground.xz, mix(8.0, 22.0, smoothstep(0.10, 0.45, design_km)), pixel_world) : vec4(-1.0);
	vec3 farm = use_patch ? mc_farmland(ground.xz, pixel_world) : vec3(0.0);
	float wood = cover.x < 0.0 ? woodland : cover.x;
	float stand = mc_stand(wood)*(1.0-smoothstep(0.42, 0.82, slope))*(1.0-farm.z*0.85);
	vec3 chart = paper*mc_wash(rain, warm, ground.y, stand, temperature, snow);
	// Worked land takes a warmer straw wash under its hatching.
	chart = mix(chart, chart*vec3(1.06, 1.02, 0.84), farm.z*0.40*(1.0-snow));
	// The resource view reads as land cover here too.
	chart = mix(chart, chart*vec3(0.80, 1.12, 0.84), resources*stand*0.60);
	float light = mc_light(light_normal, design_km);
	chart = mc_relief(chart, light, prominence);
	// Engraved relief in sepia ink: contours on the gentler ground, hachures
	// where it steepens.
	vec2 gradient = -light_normal.xz/max(light_normal.y, 0.05);
	float slope_km = length(gradient);
	float contour = mc_contours(landform.x, slope_km, pixel_world, light);
	// Hachures only on real relief (a range's flank, a valley wall), never
	// as a stipple along every little sea cliff.
	float hachure = mc_hachures(ground.xz, landform.x, gradient, pixel_world)*prominence;
	chart = mix(chart, MAP_SEPIA, max(contour*0.30, hachure*0.28));
	// Fields hatched and pasture dotted in sepia ink.
	chart = mix(chart, MAP_SEPIA, farm.x*0.34+farm.y*0.30);
	// The towns themselves, as small plans in ink.
	if (use_patch) { chart = mc_towns(chart, ground.xz, pixel_world, paper); }
	if (use_patch) {
		// Marsh: a wet blue-green wash, and tufts of reeds in water ink.
		float marsh = cover.x < 0.0 ? 0.0 : mc_marsh(cover, landform.x);
		chart = mix(chart, chart*vec3(0.88, 0.97, 1.02), marsh*0.55);
		if (marsh > 0.01 || mc_cover(ground.xz, 24.0, pixel_world).y > 0.60) {
			vec3 reeds = mc_symbols(1, ground.xz, 11.0, design_km, pixel_world, screen_up, 0.05, -1);
			chart = mix(chart, MC_WATER_INK*1.3, reeds.x*0.66);
		}
		// Woods as small inked trees in profile over their wash, thinning
		// toward the continent view.
		if (stand > 0.0 || mc_cover(ground.xz, 24.0, pixel_world).x > 0.18) {
			int near_place = mc_nearest_place(ground.xz, pixel_world*20.0);
			vec3 trees = mc_symbols(0, ground.xz, 9.0, design_km, pixel_world, screen_up, 0.05, near_place);
			trees *= 1.0-smoothstep(0.35, 1.4, design_km)*0.55;
			vec3 crown = paper*mc_wash(rain, warm, ground.y, 1.0, temperature, snow);
			chart = mix(chart, crown*1.04, trees.y*0.85);
			chart = mix(chart, crown*vec3(0.62, 0.70, 0.66), trees.z*0.65);
			chart = mix(chart, MAP_INK*1.25, trees.x*0.66);
		}
	}
	// Ranges as inked peaks at the far views.
	vec3 peaks = mc_mountains(ground.xz, design_km, pixel_world, use_patch, screen_up);
	chart = mix(chart, paper*vec3(1.02, 1.00, 0.97), peaks.y*0.88);
	chart = mix(chart, MAP_SEPIA, peaks.z*0.50);
	chart = mix(chart, MAP_INK, peaks.x*0.85);
	// The coast is one inked line where the land rises out of the sea: the
	// land's half of it (the sea draws the other half from the same shore).
	// Where the streamed patch does not reach, the height's own rate.
	float shore_px = use_patch ? mc_shore_px(ground.xz, pixel_world) : 1.0e6;
	float coast_ink = abs(shore_px) < 1.0e5 ? mc_coast_ink(shore_px)
		: (1.0-smoothstep(0.9, 1.9, coast_height/max(coast_height_px, 0.0000001)))*step(0.0, coast_height);
	chart = mix(chart, MAP_INK*1.3, coast_ink*0.85);
	return mc_frontier_wash(chart, paper, frontier_px, ground.xz, pixel_world);
}

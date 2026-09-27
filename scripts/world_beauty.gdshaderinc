// World beauty (codex/world-beauty): the known land as a painted landscape.
//
// The terrain shader builds a rich, detailed ground from climate, geology and
// photographic grain, but all of that detail used to be graded to one olive-
// brown. This file repaints it:
//  - wb_biome_palette(): a painter's palette chosen by the same climate fields
//    the simulation uses (rain, warmth, woodland, elevation). Meadow, steppe,
//    drylands, wetland, woodland and cold country each get their own colour
//    and blend continuously, so borders read as transitions.
//  - wb_paint(): a gradient map. The ground's own light and dark detail is kept,
//    but its hue comes from the palette, with cool shadows and warm lights.
//  - wb_light(): a low warm key light from the north-west with a cool sky fill
//    on the shaded side, plus valley shade from local relief, at every zoom.
//  - wb_air(): gentle aerial perspective toward a pale warm haze.
// Visual only. Values are linear albedo. Pure arithmetic, no texture reads.

const vec3 WB_LUMA = vec3(0.2126, 0.7152, 0.0722);

// sRGB (0-1) to linear, accurate to a few thousandths; folds to constants.
vec3 wb_srgb(vec3 c) {
	return c*(c*(c*0.305306011+0.682171111)+0.012522878);
}

float wb_luma(vec3 c) {
	return dot(c, WB_LUMA);
}

// The palette, in sRGB. Muted like an old hand-coloured map, never neon, but
// with real green in wet country and real ochre in dry country.
const vec3 WB_MEADOW_LUSH = vec3(0.440, 0.520, 0.340);  // #708557 wet meadow
const vec3 WB_MEADOW = vec3(0.530, 0.560, 0.380);  // #878F61 grassland
const vec3 WB_STEPPE = vec3(0.640, 0.600, 0.440);  // #A39970 dry grass
const vec3 WB_DRYLAND = vec3(0.720, 0.640, 0.500);  // #B8A380 sun-scoured
const vec3 WB_WETLAND = vec3(0.400, 0.470, 0.390);  // #667863 wet meadows
const vec3 WB_WOOD = vec3(0.310, 0.400, 0.270);  // #4F6645 broadleaf
const vec3 WB_WOOD_COLD = vec3(0.250, 0.340, 0.290);  // #40574A conifer
const vec3 WB_WOOD_DRY = vec3(0.420, 0.440, 0.300);  // #6B704D open woodland
const vec3 WB_TUNDRA = vec3(0.570, 0.570, 0.520);  // #919185 cold barrens
const vec3 WB_UPLAND = vec3(0.560, 0.540, 0.500);  // #8F8A80 bare upland

// rain, warm: the terrain's precipitation and temperature fields (0-1).
// forest: rendered woodland cover. height: km above sea. pattern: a broad
// world-anchored noise (0-1) that lets the painter vary the wash.
vec3 wb_biome_palette(float rain, float warm, float forest, float height, float pattern) {
	float lush = smoothstep(0.52, 0.86, rain);
	float dry = 1.0-smoothstep(0.26, 0.50, rain);
	float arid = (1.0-smoothstep(0.08, 0.26, rain))*smoothstep(0.35, 0.65, warm);
	float cold = 1.0-smoothstep(0.13, 0.30, warm);
	vec3 open = mix(WB_MEADOW, WB_MEADOW_LUSH, lush);
	open = mix(open, WB_STEPPE, dry);
	open = mix(open, WB_DRYLAND, arid);
	// Low, very wet ground is marsh-green and grey.
	float marsh = smoothstep(0.72, 0.92, rain)*(1.0-smoothstep(0.15, 0.9, height));
	open = mix(open, WB_WETLAND, marsh*0.65);
	open = mix(open, WB_TUNDRA, cold*0.85);
	// A painter's broken wash: warmer straw in one field, cooler green in the next.
	open *= mix(vec3(1.04, 1.02, 0.94), vec3(0.96, 1.00, 1.05), pattern);
	vec3 wood = mix(WB_WOOD, WB_WOOD_COLD, max(cold, 1.0-smoothstep(0.25, 0.45, warm))*0.8);
	wood = mix(wood, WB_WOOD_DRY, dry*0.7);
	wood *= mix(vec3(1.03, 1.02, 0.95), vec3(0.95, 1.0, 1.04), pattern);
	vec3 c = mix(open, wood, clamp(forest, 0.0, 1.0));
	// Bare high ground above the treeline.
	float alpine = smoothstep(4.5, 9.0, height);
	c = mix(c, WB_UPLAND, alpine*0.7);
	return wb_srgb(clamp(c, vec3(0.0), vec3(1.0)));
}

// Gradient map: keep the ground's light/dark detail, take hue from the palette.
// `reference` is the typical luma of this ground before painting, so average
// ground lands exactly on the palette colour. `amount` fades the effect.
vec3 wb_paint(vec3 earth, vec3 palette, float reference, float amount) {
	float l = wb_luma(earth);
	float d = clamp(l/max(reference, 0.0001), 0.20, 2.60);
	// Keep the ground's grain crisp: a touch more contrast than the source.
	d = pow(d, 1.15);
	vec3 painted = palette*d;
	// Shadows go cool and a little blue, lights go warm, as in gouache.
	painted *= mix(vec3(0.90, 0.96, 1.08), vec3(1.04, 1.01, 0.96), smoothstep(0.55, 1.45, d));
	// Keep a share of the ground's own hue (dry patches, soil, worn ground).
	vec3 native_hue = earth/max(l, 0.0001)*wb_luma(painted);
	painted = mix(painted, native_hue, 0.35);
	return mix(earth, max(painted, vec3(0.0)), clamp(amount, 0.0, 1.0));
}

// Key light: low and warm from the north-west (the same side as the chart
// hillshade), sky fill cool. `relief` is the slope-driven light term in about
// [-1,1]: positive facing the sun, negative turned away. `valley` in [0,1]
// darkens ground lying below its surroundings. Colour and value both shift.
vec3 wb_light(vec3 earth, float relief, float valley, float strength) {
	float lit = clamp(relief, -1.0, 1.0)*strength;
	vec3 warm = vec3(1.10, 1.03, 0.88);
	vec3 cool = vec3(0.74, 0.82, 0.98);
	vec3 tint = lit >= 0.0 ? mix(vec3(1.0), warm, lit) : mix(vec3(1.0), cool, -lit);
	earth *= tint;
	// Valley shade: cool and soft, the way a painter deepens a hollow.
	earth *= mix(vec3(1.0), vec3(0.80, 0.86, 0.96), clamp(valley, 0.0, 1.0));
	return earth;
}

// Aerial perspective: a pale, slightly blue-warm air toward the distance.
const vec3 WB_AIR = vec3(0.52, 0.50, 0.44);

vec3 wb_air(vec3 c, float weight) {
	return mix(c, WB_AIR, clamp(weight, 0.0, 0.45));
}

// The final grade keeps the painted palette's hue but caps chroma relative
// to brightness, so no season, texture or light can push the land to neon
// (spring flush and summer straw used to turn it chartreuse).
vec3 wb_grade(vec3 c) {
	float l = wb_luma(c);
	float green_excess = max(c.g-max(c.r, c.b)*1.30, 0.0);
	c.r += green_excess*0.30;
	c.g -= green_excess*0.20;
	float lo = min(c.r, min(c.g, c.b));
	float hi = max(c.r, max(c.g, c.b));
	float chroma = hi-lo;
	float limit = 0.42*l+0.004;
	vec3 grey = vec3(wb_luma(c));
	c = grey+(c-grey)*min(1.0, limit/max(chroma, 0.00001));
	c *= l/max(wb_luma(c), 0.0001);
	return max(c, vec3(0.0));
}

// Direction toward the key light, in the ground plane (world x, z): the same
// north-west sun as the terrain hillshade.
const vec2 WB_SUN_XZ = vec2(-0.7385, -0.6743);

// Canopy volume at stand edges. `forest` is the rendered woodland cover and
// `ground_xz` a smooth world position (camera-relative); its screen
// derivatives turn the cover's screen gradient into a world direction.
// Call only from the main fragment path (it uses derivatives).
vec3 wb_canopy_edges(vec3 earth, float forest, vec2 ground_xz, float pixel_world) {
	vec2 dpdx = dFdx(ground_xz);
	vec2 dpdy = dFdy(ground_xz);
	vec2 dm = vec2(dFdx(forest), dFdy(forest));
	mat2 jac = mat2(vec2(dpdx.x, dpdy.x), vec2(dpdx.y, dpdy.y));
	float det = determinant(jac);
	if (abs(det) < 1e-14) { return earth; }
	vec2 grad = inverse(jac)*dm;           // cover change per km, pointing into the wood
	float per_px = length(grad)*pixel_world;
	if (per_px < 0.004) { return earth; }
	vec2 inward = grad/max(length(grad), 1e-9);
	// +1 where the edge faces the sun, -1 where it faces away.
	float facing = dot(-inward, WB_SUN_XZ);
	float edge = smoothstep(0.004, 0.05, per_px);
	float rim = smoothstep(0.25, 0.55, forest)*(1.0-smoothstep(0.70, 0.95, forest));
	float spill = smoothstep(0.03, 0.30, forest)*(1.0-smoothstep(0.55, 0.85, forest));
	float lit = max(facing, 0.0)*rim*edge;
	float shade = max(-facing, 0.0)*max(rim, spill)*edge;
	earth = mix(earth, earth*vec3(1.22, 1.14, 0.92), lit*0.55);
	earth = mix(earth, earth*vec3(0.58, 0.64, 0.78), shade*0.60);
	return earth;
}

// Brushwork: a faint wash of strokes held at a constant size on screen, the
// way a painted map shows the brush at any distance. Two octaves one power of
// two apart, blended by the zoom's fractional octave, so it never pops.
// Strokes run a little off east-west, like a wash laid across the sheet.
// Returns about -1..1. Uses map_paper_noise (map_palette.gdshaderinc).
float wb_brush(vec2 world_xz, float camera_height) {
	float octave = log2(max(camera_height, 0.001)*0.08);
	float scale = exp2(floor(octave));
	float blend = fract(octave);
	vec2 p = world_xz/scale;
	vec2 q = vec2(p.x*0.96+p.y*0.28, -p.x*0.28+p.y*0.96)*vec2(0.9, 3.2);
	float a = map_paper_noise(q)*0.65+map_paper_noise(q*2.3+vec2(5.0, -7.0))*0.35;
	float b = map_paper_noise(q*0.5)*0.65+map_paper_noise(q*1.15+vec2(5.0, -7.0))*0.35;
	return (mix(a, b, blend)-0.5)*2.0;
}

// Apply the brushwork: a small warm/cool and light/dark shift of the wash.
vec3 wb_brushwork(vec3 c, float stroke, float amount) {
	vec3 warm = vec3(1.05, 1.02, 0.93);
	vec3 cool = vec3(0.95, 0.99, 1.05);
	vec3 shifted = c*mix(cool, warm, stroke*0.5+0.5)*(1.0+stroke*0.05);
	return mix(c, shifted, clamp(amount, 0.0, 1.0));
}

// Chart contours: fine sepia lines of equal height, as an engraved survey
// sheet draws them, over the painted relief. The interval doubles as the view
// widens so lines stay a comfortable distance apart; each fourth line is an
// index contour, a little heavier. Returns ink coverage (0-1).
// `height_px` is fwidth(height) (take it before any discard).
float wb_contours(float height, float height_px, float pixel_world) {
	if (height <= 0.004) { return 0.0; }
	float octave = log2(max(pixel_world, 0.000001)/0.012);
	float level = floor(octave);
	float blend = fract(octave);
	float coverage = 0.0;
	for (int k = 0; k < 2; k++) {
		float interval = 0.025*exp2(level+float(k));
		float weight = k == 0 ? 1.0-blend : blend;
		float u = height/interval;
		float px = max(height_px/interval, 0.00001);
		float d = abs(fract(u+0.5)-0.5)/px;
		float line = 1.0-smoothstep(0.35, 1.05, d);
		float index = 1.0-step(0.5, abs(mod(floor(u+0.5), 4.0)));
		// Where contours crowd (steep ground) they would merge into a smear.
		float crowd = smoothstep(0.40, 0.18, px);
		coverage = max(coverage, line*weight*crowd*mix(0.55, 1.0, index));
	}
	return coverage;
}

// The known world's edge as a watercolour wash: the land's paint thins toward
// the frontier ink over a ragged band a few dozen pixels wide, and pigment
// pools in a faint darker rim right at the edge, the way a wash dries on
// paper. `inland_px` is the distance in screen pixels inland from the ink;
// `scale` fades the effect in at chart zoom.
vec3 wb_frontier_wash(vec3 earth, float inland_px, vec2 world_xz, float pixel_world, float scale) {
	if (scale <= 0.0 || inland_px > 60.0) { return earth; }
	float blot = map_paper_noise(world_xz/max(pixel_world*38.0, 0.00001))*0.7
		+map_paper_noise(world_xz/max(pixel_world*9.0, 0.00001)+vec2(3.1, -7.7))*0.3;
	float d = inland_px+(blot-0.5)*26.0;
	float thin = 1.0-smoothstep(2.0, 34.0, d);
	float rim = 1.0-smoothstep(0.0, 2.5, abs(d-3.0));
	vec3 paper = MAP_VELLUM*0.62;
	earth = mix(earth, earth*0.50+paper*0.50, thin*0.55*scale);
	earth *= 1.0-rim*0.12*scale;
	return earth;
}

// -- Woodland as canopy ------------------------------------------------------
// Woodland density used to shade open ground a little darker, so a forest read
// as dark grass. Here it becomes stands: an organic edge where density passes
// about one half, small groves scattered in half-wooded country, and inside a
// canopy of crowns, each lit on its north-west side with shaded gaps between.
// The crowns are held at a constant size on screen (individual trees close up,
// clumps and then a stippled wash further out), blended across octaves so the
// canopy never pops while zooming.

vec2 wb_cell_jitter(vec2 cell) {
	return vec2(map_paper_hash(cell+vec2(17.0, 31.0)), map_paper_hash(cell+vec2(-5.0, 11.0)));
}

// One octave of crowns at `p` (in crown units): round crowns of varied size,
// each lit on its sunward side, with shaded understory showing between.
// Returns (brightness, gap).
vec2 wb_crown_octave(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float cover = 0.0;
	float bright = 0.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 cell = i+g;
			vec2 jitter = wb_cell_jitter(cell);
			vec2 r = f-(g+0.1+jitter*0.8);       // from crown centre to pixel
			float radius = 0.42+map_paper_hash(cell+vec2(9.0, 3.0))*0.34;
			float d = length(r)/radius;
			float crown = 1.0-smoothstep(0.70, 1.0, d);
			if (crown <= cover) { continue; }
			float lit = clamp(dot(r/radius, WB_SUN_XZ)*1.25, -1.0, 1.0)*(1.0-d*0.35);
			float tone = map_paper_hash(cell+vec2(41.0, -23.0));
			cover = crown;
			bright = 0.84+lit*0.36+(tone-0.5)*0.20;
		}
	}
	return vec2(mix(0.62, bright, cover), 1.0-cover);
}

// Canopy tone at `world_xz` for a pixel `pixel_world` km wide. Returns
// (brightness multiplier, gap darkness 0-1, per-crown warm/cool 0-1).
vec3 wb_canopy(vec2 world_xz, float pixel_world) {
	float crown_km = max(pixel_world*9.0, 0.009);
	float level = log2(crown_km/0.009);
	float scale = 0.009*exp2(floor(level));
	float blend = fract(level);
	vec2 a = wb_crown_octave(world_xz/scale);
	vec2 b = wb_crown_octave(world_xz/(scale*2.0)+vec2(7.3, -2.9));
	vec2 m = mix(a, b, blend);
	float hue = map_paper_noise(world_xz/(scale*3.0)+vec2(-11.0, 5.0));
	return vec3(m.x, m.y, hue);
}

// Stand coverage from woodland density (0-1) and two broad world noises (0-1).
// `pixel_world` smooths stands into broad masses at chart zoom, where the
// fine edge noise would only speckle.
float wb_stand(float woodland, float noise_a, float noise_b, float pixel_world) {
	float chart = smoothstep(0.12, 0.8, pixel_world);
	float edge_noise = ((noise_a-0.5)*0.34+(noise_b-0.5)*0.16)*(1.0-chart*0.8);
	float stand = smoothstep(mix(0.40, 0.30, chart), mix(0.50, 0.62, chart), woodland+edge_noise);
	// Groves: clumps in half-wooded and parkland country, close views only.
	float grove = smoothstep(0.64, 0.74, noise_b*0.7+noise_a*0.3)*smoothstep(0.12, 0.32, woodland)*(1.0-chart);
	return max(stand, grove*0.9);
}

// Paint the stand. `wood` is the palette's woodland colour for this climate
// (linear), `reference` the typical luma of its ground.
vec3 wb_woodland(vec3 earth, float stand, vec3 wood, vec2 world_xz, float pixel_world) {
	if (stand <= 0.001) { return earth; }
	vec3 canopy = wb_canopy(world_xz, pixel_world);
	// Canopy detail softens into a stippled wash at chart zoom.
	float detail = 1.0-smoothstep(0.05, 0.5, pixel_world)*0.80;
	// Canopy is painted a little lighter than its ground's palette: a forest
	// on a painted map is a rich mass of green, never a black stain.
	vec3 c = wood*1.9*mix(1.0, canopy.x, detail);
	c = mix(c, c*vec3(0.62, 0.70, 0.82), canopy.y*0.50*detail);
	c *= mix(vec3(1.05, 1.03, 0.90), vec3(0.93, 1.0, 1.07), canopy.z);
	return mix(earth, c, clamp(stand, 0.0, 1.0));
}

// -- Wind over the land (map_wind from scripts/map_ambience.gd) --------------
// Gusts roll across open grass as travelling bands of paler, bent-over stems,
// and ripple faintly over the canopy, downwind at the speed of the live wind.
// Close views only. `wind` is map_wind (xy direction, z strength, w gust),
// `clock` map_wind_clock, `motion` 0 under reduced motion (the bands then
// hold still). Returns about -1..1 (0 when unresolved or calm).
float wb_wind_waves(vec2 world_xz, float pixel_world, vec4 wind, float clock, float motion) {
	float resolved = 1.0-smoothstep(0.004, 0.012, pixel_world);
	float strength = clamp(wind.z, 0.0, 1.0)*(0.7+0.3*clamp(wind.w, 0.0, 1.0));
	if (resolved <= 0.0 || strength <= 0.02) { return 0.0; }
	vec2 dir = length(wind.xy) > 0.001 ? normalize(wind.xy) : vec2(1.0, 0.0);
	vec2 across = vec2(-dir.y, dir.x);
	float t = clock*motion;
	// Position along the wind, in km; bands about 35 m apart travel downwind.
	float along = dot(world_xz, dir);
	float side = dot(world_xz, across);
	float bend = (map_paper_noise(vec2(along, side)*18.0+vec2(4.0, -9.0))-0.5)*1.6;
	float band = sin((along-t*0.006)*180.0+bend*3.0);
	// Gusts come in patches a few hundred metres across, drifting with the wind.
	float gust = smoothstep(0.35, 0.80, map_paper_noise((world_xz-dir*t*0.004)*3.2+vec2(-3.0, 7.0)));
	return band*gust*strength*resolved;
}

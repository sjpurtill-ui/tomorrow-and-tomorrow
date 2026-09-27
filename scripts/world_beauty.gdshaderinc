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
const vec3 WB_WOOD = vec3(0.270, 0.340, 0.250);  // #455740 broadleaf
const vec3 WB_WOOD_COLD = vec3(0.220, 0.290, 0.260);  // #384A42 conifer
const vec3 WB_WOOD_DRY = vec3(0.380, 0.400, 0.280);  // #616647 open woodland
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

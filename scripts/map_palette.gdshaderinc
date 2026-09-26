// The map palette (docs/ART_DIRECTION.md): the land is an old hand-coloured
// map in low warm light, never a saturated satellite photograph. Every ground,
// canopy and land-cover shader ends with this grade so all zooms agree.
//  - Greens that outrun red are pulled toward olive and ochre (grass lands
//    near #6E7F3E-#8A8A4A, canopy near #3E4A2C, dry ground near #A89468).
//  - Chroma is capped (about 45% saturation) and luminance is preserved, so
//    relief, crowns and soil contrast survive the grade.
// Values are linear albedo. Pure arithmetic: no texture reads.

const vec3 MAP_LUMA = vec3(0.2126, 0.7152, 0.0722);

vec3 map_palette_grade(vec3 c) {
	float luma_in = dot(c, MAP_LUMA);
	float green_excess = max(c.g - max(c.r, c.b), 0.0);
	c.r += green_excess * 0.46;
	c.g -= green_excess * 0.16;
	c.b *= 0.90;
	float luma_mid = dot(c, MAP_LUMA);
	c = mix(vec3(luma_mid), c, 0.58);
	// Hold the original exposure (the grade changes hue, not light)
	// and lift it a touch: the olive key reads darker than the neon it replaces.
	c *= 1.05 * luma_in / max(dot(c, MAP_LUMA), 0.0001);
	return max(c, vec3(0.0));
}

// Distance haze toward parchment. Albedo-space: lit by the warm key light
// this reads as the page colour, the way a painted map fades at its margins.
const vec3 MAP_HAZE = vec3(0.50, 0.455, 0.37);

vec3 map_haze(vec3 c, float weight) {
	return mix(c, MAP_HAZE, clamp(weight, 0.0, 0.40));
}

// The unknown is blank chart vellum, not a black void: unlit (so no hidden
// relief or coastline shows through), identical over land and sea, with a faint
// paper mottle held at a constant on-screen size at every zoom.
const vec3 MAP_VELLUM = vec3(0.60, 0.515, 0.375);
// Engraving ink for the frontier of the known world.
const vec3 MAP_INK = vec3(0.105, 0.080, 0.055);

float map_paper_hash(vec2 p) {
	uvec2 cell = uvec2(ivec2(floor(p)));
	uint h = (cell.x*1597334677u)^(cell.y*3812015801u);
	h = (h^(h>>16u))*2246822519u;
	h = (h^(h>>13u))*3266489917u;
	return float(h^(h>>16u))/4294967295.0;
}

float map_paper_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f*f*(3.0-2.0*f);
	return mix(mix(map_paper_hash(i), map_paper_hash(i+vec2(1.0,0.0)), f.x),
		mix(map_paper_hash(i+vec2(0.0,1.0)), map_paper_hash(i+vec2(1.0,1.0)), f.x), f.y);
}

// `camera_height` is CAMERA_POSITION_WORLD.y (km). The grain scale follows it,
// not each surface's own pixel footprint, so land and sea meshes that meet in
// the unknown carry exactly the same paper. Two octaves one power of two apart
// are blended by the zoom's fractional octave: the grain never pops on zoom.
vec3 map_unknown(vec2 world_xz, float camera_height) {
	float octave = log2(max(camera_height, 0.001)*0.05);
	float scale = exp2(floor(octave));
	float blend = fract(octave);
	vec2 p = world_xz/scale;
	float coarse = mix(map_paper_noise(p), map_paper_noise(p*0.5+vec2(31.0,-17.0)), blend);
	float fine = mix(map_paper_noise(p*6.0+vec2(-9.0,5.0)), map_paper_noise(p*3.0+vec2(13.0,29.0)), blend);
	float mottle = (coarse-0.5)*0.10+(fine-0.5)*0.035;
	return MAP_VELLUM*(1.0+mottle);
}

// Frontier of the known world, drawn as one fine ink line with a faint sepia
// shadow on the unknown side. `discovered` is the raw charted-ground mask and
// `pixels_per_unit` how many screen pixels one unit of that mask spans here.
// Returns (ink coverage, shadow weight, crisp reveal): the charted land runs
// right up to the ink instead of dissolving into the paper well inside it.
vec3 map_frontier(float discovered, float pixels_per_unit) {
	float distance_px = (discovered-0.30)*pixels_per_unit;
	float ink = 1.0-smoothstep(0.55, 1.35, abs(distance_px));
	float shadow = (1.0-smoothstep(0.0, 7.0, -distance_px))*step(distance_px, 0.0);
	// Land starts beneath the ink, so no sliver of paper shows between them.
	float crisp = smoothstep(-0.4, 0.9, distance_px);
	return vec3(ink, shadow, crisp);
}

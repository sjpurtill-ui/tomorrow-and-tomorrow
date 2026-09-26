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

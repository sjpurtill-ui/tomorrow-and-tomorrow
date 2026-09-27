// Still water (codex/beauty-2): ponds, meres and lagoons read as water.
//
// The sea shader paints water by depth below sea level: a deep slate sea,
// a green shelf, pale shallows over a sandy bed, then surf and engraved
// water-lines at the shore. A small hollow that dips a metre below sea level
// inside woodland or behind a beach got all of that at once (every pixel is
// "shallow", every edge a shore), so it read as a flat grey-white splotch.
// Here such water is recognised as enclosed (ringed by dry land) and painted
// as a still pool: dark and clear in the middle, a reed-green margin, a fine
// ink rim, and the pale cool sky mirrored in it toward the horizon. No surf
// breaks on a pond. Include after map_coast.gdshaderinc.

// Share (0-1) of eight points on a ring of radius `r` km around `rel` (patch
// relative) that are dry land on the streamed patch's own surface.
float wbw_ring_land(vec2 rel, float r, float sea) {
	float land = 0.0;
	float spread;
	for (int k = 0; k < 8; k++) {
		float a = float(k)*0.7853982+0.39;
		land += step(sea, coast_patch_triangle(rel+vec2(cos(a), sin(a))*r, spread));
	}
	return land/8.0;
}

// 1 for water ringed by land at two scales (a pond or a closed lagoon),
// 0 for open sea. `pixel_world` km per screen pixel: the rings widen with
// the view, so a lagoon a few pixels wide is still recognised at chart zoom.
float wbw_enclosure(vec2 rel, float pixel_world, float sea) {
	float r = clamp(pixel_world*26.0, 0.12, 4.0);
	float near_ring = wbw_ring_land(rel, r, sea);
	if (near_ring < 0.55) { return 0.0; }
	float far_ring = wbw_ring_land(rel, r*2.3, sea);
	return smoothstep(0.55, 0.90, near_ring)*smoothstep(0.40, 0.85, far_ring);
}

// A still pool. `shore_px` screen pixels from the water's edge, `view_slant`
// horizontal over vertical distance to the camera (0 looking straight down),
// `screen_uv` for the mirrored sky, `close` 1 at settlement/valley zoom.
vec3 wbw_still_water(float shore_px, float view_slant, vec2 screen_uv, float close) {
	// Dark peaty centre, clearer olive-slate toward the edge.
	vec3 deep = vec3(0.070, 0.105, 0.110);
	vec3 margin = vec3(0.150, 0.200, 0.170);
	float inner = smoothstep(1.5, 12.0, shore_px);
	vec3 water = mix(margin, deep, inner);
	// The open sky mirrored in still water: stronger the more obliquely it
	// is seen, and paler toward the top of the view (the horizon side).
	vec3 sky = mix(vec3(0.46, 0.52, 0.56), vec3(0.62, 0.66, 0.66), clamp(1.0-screen_uv.y, 0.0, 1.0));
	float mirror = mix(0.16, 0.42, smoothstep(0.2, 1.6, view_slant));
	water = mix(water, sky, mirror*inner);
	// Reeds and waterweed at the margin (close views), then a fine ink rim.
	float reeds = (1.0-smoothstep(1.0, 3.5, shore_px))*close;
	water = mix(water, vec3(0.21, 0.24, 0.15), reeds*0.55);
	float rim = 1.0-smoothstep(0.4, 1.3, shore_px);
	water = mix(water, vec3(0.105, 0.080, 0.055)*1.3, rim*0.55);
	return water;
}

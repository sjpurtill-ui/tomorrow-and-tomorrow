shader_type spatial;
// THE SUPPLY MAP'S WASH (hud/supply_map.gd): one lattice draped over the
// known land, painted per pixel from what the supply model gives there
// (supply_state.gd), as a surveyor would colour a campaign chart:
//   a sap-green wash where a band would be fed, ochre where it would go
//   short, oxblood hatched where it would starve;
//   a fine ink line where one gives way to the next.
// The zones come from the interpolated share itself, not from the corner
// colours, so their edges stay crisp at any zoom however coarse the cells.
// Hatching is laid on the land at a fixed spacing on screen, so it holds
// still while the map pans. Drawn over the chart, under the ink and marks.
render_mode unshaded, blend_mix, depth_test_disabled, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

// Vertex COLOR: r = share of a day's food a band would get there (0..1),
// g = share of a carried load that arrives (the haul), a = known land (0/1).
uniform vec4 well_color : source_color = vec4(0.431, 0.541, 0.290, 1.0);
uniform vec4 short_color : source_color = vec4(0.741, 0.573, 0.227, 1.0);
uniform vec4 starve_color : source_color = vec4(0.604, 0.259, 0.212, 1.0);
uniform vec4 ink_color : source_color = vec4(0.169, 0.129, 0.094, 1.0);
// Wash strength, and the whole layer's fade with the zoom.
uniform float wash = 0.26;
uniform float fade = 1.0;
uniform float well_from = 0.75;
uniform float starve_below = 0.45;
// Hatching: screen pixels between strokes, and the stroke's half width.
uniform float hatch_px = 9.0;
uniform float hatch_half_px = 0.7;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float ratio = COLOR.r;
	float known = COLOR.a;
	// Kilometres per screen pixel here (the perspective map camera; the
	// compatibility renderer flips Y in the projection, hence abs()).
	float km_px = length(world_position - CAMERA_POSITION_WORLD) * 2.0 / max(abs(PROJECTION_MATRIX[1][1]) * VIEWPORT_SIZE.y, 0.0001);
	// The share's change across one pixel: edges and lines one pixel soft.
	float w = max(fwidth(ratio), 0.00001);
	float well = smoothstep(well_from - w, well_from + w, ratio);
	float starve = 1.0 - smoothstep(starve_below - w, starve_below + w, ratio);
	vec3 colour = mix(short_color.rgb, well_color.rgb, well);
	colour = mix(colour, starve_color.rgb, starve);
	float alpha = wash * (0.9 - 0.2 * well + 0.3 * starve);
	// Diagonal hatching over the country where a band would starve.
	float u = (world_position.x + world_position.z) / max(km_px * hatch_px * 1.41421356, 0.0000001);
	float from_stroke = abs(fract(u) - 0.5) * hatch_px;
	float hatch = (1.0 - smoothstep(hatch_half_px, hatch_half_px + 0.9, from_stroke)) * starve;
	colour = mix(colour, starve_color.rgb * 0.62, hatch * 0.85);
	alpha = max(alpha, hatch * 0.5);
	// Ink where the country turns: fed to short, short to starving.
	float line_well = 1.0 - smoothstep(0.55, 1.35, abs(ratio - well_from) / w);
	float line_starve = 1.0 - smoothstep(0.55, 1.35, abs(ratio - starve_below) / w);
	float line = max(line_well * 0.6, line_starve * 0.85);
	colour = mix(colour, ink_color.rgb, line);
	alpha = max(alpha, line * 0.55);
	ALBEDO = colour;
	ALPHA = clamp(alpha, 0.0, 1.0) * known * fade;
}

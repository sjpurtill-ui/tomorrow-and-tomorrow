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

// The grid (hud/supply_map.gd), one texel a lattice node: r = share of a
// day's food a band would get there (0..1), g = share of a carried load that
// arrives (the haul), b = known land (0/1). Read with a cubic B-spline, so
// the zones' edges run in smooth curves however coarse the lattice.
uniform sampler2D supply_grid : filter_linear, repeat_disable;
uniform float grid_texels = 65.0;
uniform vec4 well_color : source_color = vec4(0.431, 0.541, 0.290, 1.0);
uniform vec4 short_color : source_color = vec4(0.741, 0.573, 0.227, 1.0);
uniform vec4 starve_color : source_color = vec4(0.604, 0.259, 0.212, 1.0);
uniform vec4 ink_color : source_color = vec4(0.169, 0.129, 0.094, 1.0);
// A paper veil quiets the chart's own colours under the wash, so the three
// states read at a glance (a map mode, as HOI4's supply view flattens its).
uniform vec4 veil_color : source_color = vec4(0.937, 0.902, 0.831, 1.0);
uniform float veil = 0.3;
// Wash strength, and the whole layer's fade with the zoom.
uniform float wash = 0.5;
uniform float fade = 1.0;
uniform float well_from = 0.75;
uniform float starve_below = 0.45;
// Hatching: screen pixels between strokes, and the stroke's half width.
uniform float hatch_px = 9.0;
uniform float hatch_half_px = 0.7;

varying vec3 world_position;

// Cubic B-spline weights, and the grid read with four linear taps.
vec4 bspline(float v) {
	vec4 n = vec4(1.0, 2.0, 3.0, 4.0) - v;
	vec4 s = n * n * n;
	float x = s.x;
	float y = s.y - 4.0 * s.x;
	float z = s.z - 4.0 * s.y + 6.0 * s.x;
	float w = 6.0 - x - y - z;
	return vec4(x, y, z, w) * (1.0 / 6.0);
}

vec4 grid_at(vec2 uv) {
	vec2 size = vec2(grid_texels);
	vec2 texel = uv * size - 0.5;
	vec2 f = fract(texel);
	texel -= f;
	vec4 xc = bspline(f.x);
	vec4 yc = bspline(f.y);
	vec4 c = texel.xxyy + vec2(-0.5, 1.5).xyxy;
	vec4 s = vec4(xc.xz + xc.yw, yc.xz + yc.yw);
	vec4 o = (c + vec4(xc.yw, yc.yw) / s) / size.xxyy;
	vec4 s0 = texture(supply_grid, o.xz);
	vec4 s1 = texture(supply_grid, o.yz);
	vec4 s2 = texture(supply_grid, o.xw);
	vec4 s3 = texture(supply_grid, o.yw);
	float sx = s.x / (s.x + s.y);
	float sy = s.z / (s.z + s.w);
	return mix(mix(s3, s2, sx), mix(s1, s0, sx), sy);
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec4 grid = grid_at(UV);
	float ratio = grid.r;
	float known = smoothstep(0.3, 0.7, grid.b);
	// Kilometres per screen pixel here (the perspective map camera; the
	// compatibility renderer flips Y in the projection, hence abs()).
	float km_px = length(world_position - CAMERA_POSITION_WORLD) * 2.0 / max(abs(PROJECTION_MATRIX[1][1]) * VIEWPORT_SIZE.y, 0.0001);
	// The share's change across one pixel: edges and lines one pixel soft.
	float w = max(fwidth(ratio), 0.00001);
	float well = smoothstep(well_from - w, well_from + w, ratio);
	float starve = 1.0 - smoothstep(starve_below - w, starve_below + w, ratio);
	vec3 tint = mix(short_color.rgb, well_color.rgb, well);
	tint = mix(tint, starve_color.rgb, starve);
	vec3 colour = mix(tint, veil_color.rgb, veil);
	float alpha = wash * (0.92 - 0.12 * well + 0.04 * starve);
	// Diagonal hatching over the country where a band would starve.
	float u = (world_position.x + world_position.z) / max(km_px * hatch_px * 1.41421356, 0.0000001);
	float from_stroke = abs(fract(u) - 0.5) * hatch_px;
	float hatch = (1.0 - smoothstep(hatch_half_px, hatch_half_px + 0.9, from_stroke)) * starve;
	colour = mix(colour, starve_color.rgb * 0.62, hatch * 0.8);
	alpha = max(alpha, hatch * 0.42);
	// Ink where the country turns: fed to short, short to starving.
	float line_well = 1.0 - smoothstep(0.55, 1.35, abs(ratio - well_from) / w);
	float line_starve = 1.0 - smoothstep(0.55, 1.35, abs(ratio - starve_below) / w);
	float line = max(line_well * 0.6, line_starve * 0.85);
	colour = mix(colour, ink_color.rgb, line);
	alpha = max(alpha, line * 0.55);
	ALBEDO = colour;
	ALPHA = clamp(alpha, 0.0, 1.0) * known * fade;
}

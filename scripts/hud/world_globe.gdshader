// The world view (hud/world_globe.gd): a parchment-and-ink globe drawn in one
// canvas pass. Each pixel casts a ray at a unit sphere; where it lands, the
// known-map image (world_globe_chart.gd) says how much of that ground our
// people know, whether it is land, and how high. Unknown ground is blank vellum
// under a faint graticule: the image holds nothing for it, so nothing unseen
// can show. Known land is a hand-coloured wash with hill shading and an ink
// coast; known sea a verdigris wash with engraved water-lines; the edge of
// the known world is one fine ink line with a sepia shade outside it.
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D known_map : filter_linear_mipmap, repeat_enable;
uniform sampler2D previous_map : filter_linear_mipmap, repeat_enable;
// Signed distance to the nearest walked route's centre line (L) and whether a
// route is near at all (A); see world_globe_chart.gd.
uniform sampler2D route_map : filter_linear_mipmap, repeat_enable;
uniform sampler2D previous_route_map : filter_linear_mipmap, repeat_enable;
// 0 shows previous_map, 1 known_map: new knowledge inks in over the old.
uniform float map_mix = 1.0;
uniform float chart_alpha = 1.0;
uniform mat3 globe_from_view = mat3(1.0);
uniform float eye_distance = 4.4;
uniform float tan_half_fov = 0.26795;
uniform vec2 view_size = vec2(1920.0, 1080.0);
uniform vec2 globe_center = vec2(960.0, 540.0);
uniform float globe_radius_px = 400.0;
uniform float opacity = 1.0;
uniform float backdrop_alpha = 1.0;
// How much a small known patch glows (strong from afar, gone up close).
uniform float halo_strength = 1.0;
// Near the map's own scale the globe takes the map's colours, so the
// hand-over between them is a dissolve, not a change of paint.
uniform float map_likeness = 0.0;
uniform vec3 map_vellum = vec3(0.737, 0.651, 0.478);
// The far-lands chart as it shows on screen (map_chart.gdshaderinc).
uniform vec3 map_land = vec3(0.665, 0.672, 0.455);
uniform vec3 map_land_dry = vec3(0.73, 0.69, 0.54);
uniform vec3 map_sea = vec3(0.53, 0.62, 0.58);

uniform vec3 paper = vec3(0.925, 0.886, 0.792);
uniform vec3 paper_edge = vec3(0.60, 0.50, 0.38);
uniform vec3 ink = vec3(0.15, 0.11, 0.075);
uniform vec3 sepia = vec3(0.42, 0.31, 0.20);
// Washes in the map's palette (docs/ART_DIRECTION.md), laid on vellum.
uniform vec3 land_low = vec3(0.74, 0.68, 0.50);
uniform vec3 land_green = vec3(0.57, 0.62, 0.38);
uniform vec3 land_high = vec3(0.67, 0.61, 0.50);
uniform vec3 sea_shallow = vec3(0.60, 0.70, 0.68);
uniform vec3 sea_deep = vec3(0.44, 0.56, 0.57);
// How strongly the sea wash is laid on (land is 1).
uniform float sea_wash = 0.62;
// The warm wash over well-walked country.
uniform vec3 region_tint = vec3(0.91, 0.85, 0.73);
uniform vec3 glow = vec3(0.86, 0.68, 0.36);
uniform vec3 backdrop_center = vec3(0.24, 0.19, 0.14);
uniform vec3 backdrop_edge = vec3(0.09, 0.07, 0.05);

const float TAU_C = 6.28318530718;
const float PI_C = 3.14159265359;

float hash3(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.71, 0.113, 0.419));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = mix(mix(hash3(i), hash3(i + vec3(1.0, 0.0, 0.0)), f.x),
		mix(hash3(i + vec3(0.0, 1.0, 0.0)), hash3(i + vec3(1.0, 1.0, 0.0)), f.x), f.y);
	float b = mix(mix(hash3(i + vec3(0.0, 0.0, 1.0)), hash3(i + vec3(1.0, 0.0, 1.0)), f.x),
		mix(hash3(i + vec3(0.0, 1.0, 1.0)), hash3(i + vec3(1.0, 1.0, 1.0)), f.x), f.y);
	return mix(a, b, f.z);
}

// A hairline of about one pixel at `distance_px` from a line.
float hairline(float distance_px) {
	return 1.0 - smoothstep(0.35, 1.15, distance_px);
}

vec4 chart_sample(vec2 uv, vec2 ddx, vec2 ddy) {
	vec4 now = textureGrad(known_map, uv, ddx, ddy);
	if (map_mix >= 0.999) {
		return now;
	}
	return mix(textureGrad(previous_map, uv, ddx, ddy), now, map_mix);
}

vec2 route_sample(vec2 uv, vec2 ddx, vec2 ddy) {
	vec2 now = textureGrad(route_map, uv, ddx, ddy).ra;
	if (map_mix >= 0.999) {
		return now;
	}
	return mix(textureGrad(previous_route_map, uv, ddx, ddy).ra, now, map_mix);
}

vec4 chart_lod(vec2 uv, float lod) {
	vec4 now = textureLod(known_map, uv, lod);
	if (map_mix >= 0.999) {
		return now;
	}
	return mix(textureLod(previous_map, uv, lod), now, map_mix);
}

void fragment() {
	vec2 pixel = UV * view_size;
	vec2 rel = (pixel - globe_center) / (view_size.y * 0.5);
	vec3 dir = normalize(vec3(rel.x * tan_half_fov, -rel.y * tan_half_fov, -1.0));
	vec3 eye = vec3(0.0, 0.0, eye_distance);
	float b = dot(eye, dir);
	float c0 = eye_distance * eye_distance - 1.0;
	float disc = b * b - c0;
	// Closest distance of the ray to the centre: 1 at the limb.
	float closest = sqrt(max(eye_distance * eye_distance - b * b, 0.0));
	float px = max(fwidth(closest), 0.000001);
	float inside = (1.0 - closest) / px;
	float cover = clamp(inside + 0.5, 0.0, 1.0);
	vec3 hit;
	if (disc >= 0.0) {
		hit = eye + dir * (-b - sqrt(disc));
	} else {
		// Just off the globe: the nearest limb point keeps derivatives smooth.
		hit = eye + dir * (-b);
	}
	vec3 n = normalize(hit);
	vec3 g = globe_from_view * n;
	float lat = asin(clamp(g.y, -1.0, 1.0));
	float lon = atan(g.x, g.z);
	vec2 uv = vec2(lon / TAU_C + 0.5, 0.5 - lat / PI_C);
	// Seam-safe gradients: the longitude wrap must not pick the blurriest mip.
	float u_wrapped = fract(uv.x + 0.5);
	vec2 du_a = vec2(dFdx(uv.x), dFdy(uv.x));
	vec2 du_b = vec2(dFdx(u_wrapped), dFdy(u_wrapped));
	vec2 du = dot(du_a, du_a) <= dot(du_b, du_b) ? du_a : du_b;
	vec2 ddx = vec2(du.x, dFdx(uv.y));
	vec2 ddy = vec2(du.y, dFdy(uv.y));
	vec2 texels = vec2(2048.0, 1024.0);
	float footprint = max(length(ddx * texels), length(ddy * texels));
	float lod = log2(max(footprint, 1.0));

	// --- Terra incognita: vellum, a little fibre, a faint graticule -----------
	float mottle = noise3(g * 6.0) - 0.5;
	float fibre = noise3(g * vec3(38.0, 110.0, 38.0) + vec3(3.0, 1.0, 7.0)) - 0.5;
	vec3 color = mix(paper, map_vellum, map_likeness) * (1.0 + mottle * 0.075 + fibre * 0.03);
	// Now and then a faint rust spot, as old vellum has.
	float fox = smoothstep(0.91, 0.96, noise3(g * 19.0 + vec3(11.0, 5.0, 2.0)));
	color = mix(color, color * vec3(0.90, 0.84, 0.74), fox * 0.18);

	float lat_deg = degrees(lat);
	float lon_deg = degrees(lon);
	float lon_deg_wrapped = mod(lon_deg + 360.0, 360.0);
	float lat_fw = max(fwidth(lat_deg), 0.00001);
	float lon_fw = max(min(fwidth(lon_deg), fwidth(lon_deg_wrapped)), 0.00001);
	float lat_off = abs(fract(lat_deg / 15.0 + 0.5) - 0.5) * 15.0;
	float lon_off = abs(fract(lon_deg / 15.0 + 0.5) - 0.5) * 15.0;
	float polar_fade = 1.0 - smoothstep(72.0, 84.0, abs(lat_deg));
	float graticule = max(hairline(lat_off / lat_fw), hairline(lon_off / lon_fw) * polar_fade);
	// Five-degree lines join in, fainter, once they fall well apart on screen.
	float fine_weight = smoothstep(40.0, 90.0, 5.0 / lat_fw);
	if (fine_weight > 0.0) {
		float lat_fine = abs(fract(lat_deg / 5.0 + 0.5) - 0.5) * 5.0;
		float lon_fine = abs(fract(lon_deg / 5.0 + 0.5) - 0.5) * 5.0;
		graticule = max(graticule, max(hairline(lat_fine / lat_fw), hairline(lon_fine / lon_fw) * polar_fade) * 0.55 * fine_weight);
	}
	float equator = hairline(abs(lat_deg) / lat_fw);

	// --- What our people know -------------------------------------------------
	vec4 k = chart_sample(uv, ddx, ddy);
	float known_share = k.r;
	float inv = 1.0 / max(known_share, 1.0 / 255.0);
	float land = clamp(k.g * inv, 0.0, 1.0);
	float height01 = clamp(k.b * inv, 0.0, 1.0);
	float height_km = mix(-4.0, 8.0, height01);
	// Known ground is laid on as a wash whose edge feathers into the vellum:
	// no hard outline, so a route reads as a soft band, not a tube.
	float known = smoothstep(0.04, 0.85, known_share) * chart_alpha;

	// Hill shading from the neighbouring heights, one footprint away.
	vec2 step_uv = max(vec2(1.0) / texels, vec2(footprint) / texels);
	vec4 kx = chart_lod(uv + vec2(step_uv.x, 0.0), lod);
	vec4 ky = chart_lod(uv + vec2(0.0, step_uv.y), lod);
	float hx = mix(-4.0, 8.0, clamp(kx.b / max(kx.r, 1.0 / 255.0), 0.0, 1.0));
	float hy = mix(-4.0, 8.0, clamp(ky.b / max(ky.r, 1.0 / 255.0), 0.0, 1.0));
	// Only where the ground is broadly known: the thin edges carry too few
	// samples for a slope.
	float valid = step(0.6, kx.r) * step(0.6, ky.r) * smoothstep(0.6, 0.9, known_share);
	// Height change per kilometre, exaggerated as a chart's hill shading is.
	vec2 slope = vec2(hx - height_km, hy - height_km) * valid / max(step_uv.x * 40075.0, 1.0) * 14.0;
	float shade = clamp(1.0 + dot(slope, vec2(-0.55, -0.83)), 0.74, 1.16);

	// Greenness from a softer sample: broad country colour, not speckle.
	vec4 soft = chart_lod(uv, clamp(lod + 1.0, 0.0, 10.0));
	float green = clamp(soft.a / max(soft.r, 1.0 / 255.0), 0.0, 1.0);
	float elevation = clamp(height_km / 4.5, 0.0, 1.0);
	float greenness = smoothstep(0.3, 0.7, green) * 0.85;
	vec3 land_color = mix(land_low, land_green, greenness);
	land_color = mix(land_color, land_high, smoothstep(0.12, 0.9, elevation));
	land_color = mix(land_color, mix(map_land_dry, map_land, greenness), map_likeness);
	land_color *= mix(1.0, shade, smoothstep(0.02, 0.2, elevation) * 0.85 + 0.15);
	float depth = clamp(-height_km / 2.8, 0.0, 1.0);
	vec3 sea_color = mix(mix(sea_shallow, sea_deep, smoothstep(0.02, 0.75, depth)), map_sea, map_likeness);
	float land_weight = smoothstep(0.40, 0.60, land);
	// Sea takes a lighter wash than land (full strength at the map's own scale).
	float wash = mix(mix(sea_wash, 1.0, land_weight), 1.0, map_likeness);
	vec3 known_color = mix(sea_color, land_color, land_weight) * (1.0 + mottle * 0.04 + fibre * 0.015);

	// Engraved water-lines along the coast: two lines of the blurred shore.
	vec4 kb = chart_lod(uv, clamp(lod + 1.6, 0.0, 10.0));
	float blurred_land = clamp(kb.g / max(kb.r, 1.0 / 255.0), 0.0, 1.0);
	float bl_fw = max(fwidth(blurred_land), 0.0001);
	float water_lines = hairline(abs(blurred_land - 0.30) / bl_fw) * 0.55 + hairline(abs(blurred_land - 0.12) / bl_fw) * 0.32;
	water_lines *= (1.0 - land_weight) * smoothstep(0.8, 0.96, kb.r);
	known_color = mix(known_color, sea_deep * 0.85, water_lines * 0.35);

	// Coast: one ink line where land meets sea, only where the known ground is
	// broad (a narrow route's few samples would scribble a false shore).
	float coast_px = abs(land - 0.5) / max(fwidth(land), 0.0001);
	float coast = hairline(coast_px * 0.8) * smoothstep(0.7, 0.95, known_share) * smoothstep(0.7, 0.9, kb.r);
	known_color = mix(known_color, mix(sepia, ink, 0.6), coast * 0.7);

	// Where routes crowd, the country between them reads as explored: a
	// neutral warm wash that says nothing of land or sea there.
	float crowd = chart_lod(uv, clamp(lod + 3.0, 0.0, 10.0)).r;
	float region = smoothstep(0.26, 0.58, crowd) * chart_alpha * (1.0 - map_likeness);
	color = mix(color, color * region_tint, region * 0.75);

	color = mix(color, known_color, known * wash);
	color = mix(color, sepia, graticule * mix(0.20, 0.12, known) + equator * 0.10);

	// Each walked route: a fine inked line along its middle, at any zoom (the
	// routes image holds the distance to the nearest route's centre line).
	vec2 route_field = route_sample(uv, ddx, ddy);
	float gap_texels = abs(route_field.x - 0.5) * 2.0 * 2.0;
	float gap_px = gap_texels * 2.0 / max(footprint, 0.0001);
	// A real route is within a texel; midway between two routes the sign also
	// flips, but far from both, so nearness keeps that from drawing a line.
	// Where routes crowd into explored country the lines give way to the wash.
	float route = (1.0 - smoothstep(0.25, 0.95, gap_px)) * smoothstep(0.6, 0.78, route_field.y) * chart_alpha * (1.0 - map_likeness) * (1.0 - region * 0.75);
	color = mix(color, mix(sepia, ink, 0.3), route * 0.55);

	// A small known patch still shows from afar: a soft warm glow around it,
	// blurred over five taps so the coarse mip never shows its squares.
	vec2 tap = vec2(10.0 / 2048.0, 10.0 / 1024.0);
	float far_share = (chart_lod(uv, 4.0).r * 2.0 + chart_lod(uv + vec2(tap.x, 0.0), 4.0).r + chart_lod(uv - vec2(tap.x, 0.0), 4.0).r
		+ chart_lod(uv + vec2(0.0, tap.y), 4.0).r + chart_lod(uv - vec2(0.0, tap.y), 4.0).r) / 6.0;
	float halo = sqrt(clamp(far_share * 10.0, 0.0, 1.0)) * (1.0 - known) * chart_alpha * halo_strength;
	color = mix(color, glow, halo * 0.22);

	// --- Light on a paper sphere ----------------------------------------------
	vec3 light_dir = normalize(vec3(-0.50, 0.62, 0.72));
	float lambert = max(dot(n, light_dir), 0.0);
	color *= 0.80 + 0.28 * lambert;
	float rim = pow(1.0 - clamp(n.z, 0.0, 1.0), 2.4);
	color = mix(color, color * paper_edge / max(paper, vec3(0.01)), rim * 0.55);
	vec3 reflected = reflect(-light_dir, n);
	color += vec3(1.0, 0.96, 0.88) * pow(max(reflected.z, 0.0), 38.0) * 0.07;
	float outline = 1.0 - smoothstep(0.5, 1.6, inside);
	color = mix(color, ink, outline * 0.85);

	// --- The dark table around it -----------------------------------------------
	vec2 bp = (UV - 0.5) * vec2(view_size.x / view_size.y, 1.0);
	float vignette = smoothstep(0.25, 1.1, length(bp));
	vec3 back = mix(backdrop_center, backdrop_edge, vignette);
	vec2 from_centre = pixel - globe_center;
	float r_here = length(from_centre);
	float shadow = 1.0 - smoothstep(0.82, 1.32, length(from_centre - vec2(0.05, 0.08) * globe_radius_px) / max(globe_radius_px, 1.0));
	back *= 1.0 - shadow * 0.45;
	// A thin engraved meridian ring, marked every ten degrees.
	float canvas_px = max(fwidth(pixel.x), 0.0001);
	float ring_r = globe_radius_px * 1.055 + 6.0;
	float ring = hairline(abs(r_here - ring_r) / canvas_px);
	float angle = atan(from_centre.y, from_centre.x);
	float tick_arc = abs(fract(angle / (TAU_C / 36.0) + 0.5) - 0.5) * (TAU_C / 36.0) * r_here;
	float tick = hairline(tick_arc / canvas_px) * step(ring_r, r_here) * step(r_here, ring_r + 7.0);
	vec3 ring_ink = mix(back, vec3(0.72, 0.60, 0.40), 0.55);
	back = mix(back, ring_ink, max(ring, tick * 0.8));

	vec3 final_color = mix(back, color, cover);
	float alpha = mix(backdrop_alpha, 1.0, cover) * opacity;
	COLOR = vec4(final_color, alpha);
}

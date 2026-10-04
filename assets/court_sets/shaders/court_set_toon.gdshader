shader_type spatial;
// The court's sets (assets/court_sets, made by tools/blender/court_set.py):
// painted, not photographed. Real lights (the sun, the fire, the bounce) fall
// on it in two soft tones, as the figures are shaded; the baked shade in the
// hollows (vertex R) darkens the paint, trodden or handled places (vertex G)
// wear toward a second colour, each piece varies a little (vertex B).
// A pattern is painted from the UVs (court_set_kit.py says what they mean):
//  1 bark (furrows inked along the log)   2 end grain (rings, heart, checks)
//  3 hide (blotches, smoked edges, scars)  4 painted shield (motif 0..2)
//  5 woven cloth (bands, a zigzag border)  6 carpet (border and lozenges)
//  7 thatch (strands)                       8 reed matting (over and under)
//  9 planks (grain, seams)                 10 plaster (stains, fallen patches)
// 11 mudbrick courses                       12 dressed stone blocks
// 13 flagstones (by the world, not UV)  14 charred wood (cracks glow low down)
// 15 weathered stone with lichen       16 finished veneer (no plank joints)
// 17 regular modern floor tiles        18 subdued woven upholstery
// 19 leaded diamond glazing            20 small rectangular window panes
render_mode cull_back, depth_draw_opaque, specular_disabled;

uniform vec3 albedo : source_color = vec3(0.5, 0.45, 0.4);
uniform vec3 albedo_worn : source_color = vec3(0.5, 0.45, 0.4);
uniform vec3 accent_a : source_color = vec3(0.6, 0.25, 0.15);
uniform vec3 accent_b : source_color = vec3(0.85, 0.78, 0.62);
uniform vec3 ink : source_color = vec3(0.17, 0.13, 0.09);
uniform int pattern = 0;
uniform int motif = 0;
uniform float pattern_scale = 1.0;
uniform float variation = 0.10;
uniform float mottle = 0.10;
uniform float mottle_scale = 0.55;
uniform float grain = 0.05;
uniform float ao_amount = 1.0;
uniform float band_soft = 0.22;
uniform float wrap = 0.0;
uniform float half_tone = 0.22;
uniform vec3 emission_color : source_color = vec3(1.0, 0.42, 0.10);
uniform float emission_amount = 0.0;
uniform float emission_flicker = 0.0;
uniform vec3 haze_color : source_color = vec3(0.78, 0.80, 0.80);
uniform float haze_start = 40.0;
uniform float haze_end = 160.0;
uniform float haze_max = 0.0;
uniform float rim_amount = 0.0;
uniform float sheen_amount = 0.0;
uniform float sheen_power = 40.0;
uniform float glazing = 0.0;
// The season: snow lies on what faces the sky (not near the fire, not in a
// hall), dust and dryness in summer.
uniform float snow = 0.0;
uniform vec3 fire_pos = vec3(0.0, 0.0, 0.0);
uniform float dry = 0.0;
// a gust (the god's wrath) moves the hides: they billow along the wind,
// more toward their tops, as a stretched skin does between its stakes
uniform float gust = 0.0;
uniform vec3 wind = vec3(1.0, 0.0, 0.3);

varying vec4 v_col;
varying vec3 v_world;

void vertex() {
	v_col = COLOR;
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	if (gust > 0.0) {
		float lift = smoothstep(0.15, 1.5, v_world.y);
		float flap = 0.55 + 0.45 * sin(TIME * 9.0 + v_world.x * 3.1 + v_world.z * 2.3);
		vec3 d = wind * gust * 0.09 * lift * flap;
		VERTEX += inverse(mat3(MODEL_MATRIX)) * d;
		v_world += d;
	}
}

float hash3(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.1, 0.2, 0.3));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise3(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash3(i), hash3(i + vec3(1, 0, 0)), f.x), mix(hash3(i + vec3(0, 1, 0)), hash3(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(hash3(i + vec3(0, 0, 1)), hash3(i + vec3(1, 0, 1)), f.x), mix(hash3(i + vec3(0, 1, 1)), hash3(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash2(i), hash2(i + vec2(1, 0)), f.x), mix(hash2(i + vec2(0, 1)), hash2(i + vec2(1, 1)), f.x), f.y);
}

// a line of ink where v crosses a level, about w wide
float inkline(float v, float w) {
	return 1.0 - smoothstep(0.0, w, abs(v));
}

vec3 paint(vec3 base, vec2 uv, float seed) {
	vec3 col = base;
	if (pattern == 1) {
		// bark: furrows running along the log, inked here and there, lighter ridges
		vec2 p = uv * pattern_scale;
		float n = noise2(vec2(p.x * 9.0 + seed * 7.0, p.y * 1.6));
		float n2 = noise2(vec2(p.x * 21.0 - seed * 3.0, p.y * 3.4 + 4.0));
		float ridge = abs(n - 0.5) * 2.0;
		col *= 0.78 + 0.34 * smoothstep(0.15, 0.85, ridge);
		float furrow = (1.0 - smoothstep(0.03, 0.12, abs(n2 - 0.5))) * step(0.45, noise2(vec2(p.x * 5.0, p.y * 0.7 + seed)));
		col = mix(col, ink, furrow * 0.65);
		float lichen = smoothstep(0.72, 0.8, noise2(p * vec2(4.0, 2.0) + seed * 11.0));
		col = mix(col, vec3(0.55, 0.57, 0.48), lichen * 0.35);
	} else if (pattern == 2) {
		// end grain: rings about a darker heart, the sapwood paler, a bark rim, checks
		vec2 q = uv;
		float r = length(q);
		float a = atan(q.y, q.x);
		float wob = noise2(vec2(a * 2.0 + seed * 5.0, r * 3.0)) * 0.08;
		float rings = abs(fract((r + wob) * 7.0) - 0.5);
		col *= 0.88 + 0.12 * smoothstep(0.0, 0.25, rings);
		col = mix(col, col * 0.62, 1.0 - smoothstep(0.08, 0.3, r));
		col = mix(col, col * 1.12, smoothstep(0.72, 0.86, r));
		col = mix(col, ink * 1.4, smoothstep(0.9, 0.97, r));
		float check = 1.0 - smoothstep(0.0, 0.035, abs(sin(a * 1.5 + seed * 9.0 + noise2(vec2(r * 4.0, seed)) * 0.6)));
		col = mix(col, ink, check * smoothstep(0.18, 0.4, r) * (1.0 - smoothstep(0.8, 0.95, r)) * step(0.5, fract(seed * 7.3)) * 0.8);
		float check2 = 1.0 - smoothstep(0.0, 0.03, abs(sin(a * 1.0 + seed * 3.0 + 1.0)));
		col = mix(col, ink, check2 * smoothstep(0.45, 0.6, r) * (1.0 - smoothstep(0.85, 0.95, r)) * 0.7);
	} else if (pattern == 3) {
		// a hide: big blotches, darker smoked edges, a few scars and lacing holes
		vec2 p = uv;
		float b = noise2(p * vec2(3.0, 2.2) + seed * 13.0) * 0.6 + noise2(p * vec2(9.0, 7.0) + seed * 5.0) * 0.4;
		col *= 0.82 + 0.36 * b;
		float edge = min(min(p.x, 1.0 - p.x), min(p.y, 1.0 - p.y));
		col = mix(col * 0.66, col, smoothstep(0.0, 0.12, edge + (noise2(p * 14.0 + seed) - 0.5) * 0.05));
		float hair = noise2(vec2(p.x * 80.0, p.y * 12.0 + seed * 3.0));
		col *= 0.95 + 0.08 * hair;
		float scar = 1.0 - smoothstep(0.0, 0.012, abs(noise2(p * 4.0 + seed * 21.0) - 0.5));
		col = mix(col, ink, scar * step(0.66, noise2(p * 2.0 + seed * 2.0)) * 0.18);
		float holes = step(0.82, fract(p.y * 9.0)) * step(0.94, 1.0 - edge * 12.0);
		col = mix(col, ink, holes * 0.4);
	} else if (pattern == 4) {
		// a painted shield: (turn, radius); the paint chipped where it is worn
		float t = uv.x;
		float r = uv.y;
		vec3 paintc = col;
		if (motif == 0) {
			paintc = mix(paintc, accent_a, step(0.28, r) * step(r, 0.46));
			paintc = mix(paintc, accent_b, step(0.62, r) * step(r, 0.74));
			paintc = mix(paintc, accent_a, step(0.86, r));
			paintc = mix(paintc, accent_b, step(r, 0.14));
		} else if (motif == 1) {
			float wedge = step(0.5, fract(t * 4.0));
			paintc = mix(paintc, accent_a, wedge * step(r, 0.84));
			paintc = mix(paintc, accent_b, step(0.84, r));
			paintc = mix(paintc, ink, inkline(fract(t * 4.0) - 0.5, 0.02) * step(r, 0.84) + inkline(fract(t * 4.0), 0.02) * step(r, 0.84));
		} else {
			float rays = step(0.5, fract(t * 12.0)) * step(0.26, r) * step(r, 0.6 + 0.08 * sin(t * 6.2832 * 12.0));
			paintc = mix(paintc, accent_a, step(r, 0.24));
			paintc = mix(paintc, accent_a, rays);
			float zig = 0.82 + 0.05 * abs(fract(t * 18.0) - 0.5) * 2.0;
			paintc = mix(paintc, accent_b, step(zig, r));
		}
		paintc = mix(paintc, ink, inkline(r - 0.995, 0.02));
		float chip = smoothstep(0.62, 0.7, noise2(vec2(t * 40.0, r * 8.0) + seed * 9.0));
		col = mix(paintc, col * 0.9, chip * 0.8);
	} else if (pattern == 5) {
		// woven cloth (u across, v down): bands, pinstripes, a zigzag border at the foot
		vec2 p = uv;
		float band = floor(p.y * 7.0);
		float k = mod(band, 3.0);
		vec3 bc = k < 0.5 ? col : (k < 1.5 ? accent_a : accent_b);
		float inband = fract(p.y * 7.0);
		bc = mix(bc, ink, inkline(inband - 0.5, 0.03) * 0.5);
		float zig = abs(fract(p.x * 10.0) - 0.5) * 0.08;
		float border = step(0.86 + zig, p.y);
		bc = mix(bc, accent_a * 0.8, border);
		bc = mix(bc, ink, inkline(p.y - (0.86 + zig), 0.008) * 0.8);
		float weave = sin(p.x * 900.0) * sin(p.y * 700.0);
		col = bc * (0.93 + 0.07 * weave);
	} else if (pattern == 6) {
		// a carpet (u across, v along): a border with a running zigzag, lozenges in the field
		vec2 p = uv;
		float bx = min(p.x, 1.0 - p.x);
		vec3 c = col;
		vec2 f = vec2(p.x * 3.0, p.y * 18.0);
		float loz = abs(fract(f.x) - 0.5) + abs(fract(f.y) - 0.5);
		c = mix(c, accent_b, step(loz, 0.28) * step(0.16, bx));
		c = mix(c, accent_a, step(loz, 0.13) * step(0.16, bx));
		float zig = 0.06 + 0.03 * abs(fract(p.y * 40.0) - 0.5) * 2.0;
		c = mix(c, accent_a, step(bx, 0.16));
		c = mix(c, accent_b, step(bx, zig) * step(0.03, bx));
		c = mix(c, ink, inkline(bx - 0.16, 0.006) * 0.7);
		col = c * (0.94 + 0.06 * sin(p.x * 600.0) * sin(p.y * 900.0));
	} else if (pattern == 7) {
		// thatch: bundles of straw, streaked and tufted
		vec2 p = uv * pattern_scale;
		float s = noise2(vec2(p.x * 70.0, p.y * 3.0 + seed));
		float s2 = noise2(vec2(p.x * 160.0, p.y * 6.0));
		col *= 0.78 + 0.3 * s + 0.12 * s2;
		col = mix(col, ink, (1.0 - smoothstep(0.0, 0.05, abs(s2 - 0.5))) * 0.35);
		col *= 0.9 + 0.1 * step(0.5, fract(p.y * 9.0 + s * 0.3));
	} else if (pattern == 8) {
		// reed matting: strands over and under
		vec2 p = uv * pattern_scale * 14.0;
		vec2 c = floor(p);
		float flip = mod(c.x + c.y, 2.0);
		float strand = flip > 0.5 ? fract(p.y) : fract(p.x);
		float along = flip > 0.5 ? p.x : p.y;
		col *= 0.8 + 0.3 * sin(strand * 3.1416) + 0.06 * noise2(vec2(along * 3.0, c.x + c.y));
		col = mix(col, ink, inkline(strand, 0.08) * 0.35);
	} else if (pattern == 9) {
		// planks: grain along the board, the seams between boards
		vec2 p = uv * pattern_scale;
		float g = noise2(vec2(p.x * 1.2 + seed * 3.0, p.y * 22.0));
		col *= 0.86 + 0.24 * g;
		float knot = 1.0 - smoothstep(0.0, 0.06, length(fract(p * vec2(0.7, 3.0) + seed) - 0.5));
		col = mix(col, ink, knot * 0.4);
		col = mix(col, ink, inkline(fract(p.y * 4.0) - 0.5, 0.012) * 0.5);
	} else if (pattern == 10) {
		// plaster over mudbrick: soft stains, dirt rising from the floor, patches
		// fallen away to show the courses beneath
		vec2 p = uv;
		float st = noise2(p * 0.8 + seed) * 0.6 + noise2(p * 3.0) * 0.4;
		col *= 0.9 + 0.16 * st;
		col = mix(col, col * 0.72, (1.0 - smoothstep(0.0, 1.1, v_world.y)) * 0.55);
		float fall = smoothstep(0.66, 0.7, noise2(p * 0.9 + seed * 5.0 + 2.0));
		vec2 b = vec2(p.x / 0.38 + step(1.0, mod(floor(p.y / 0.13), 2.0)) * 0.5, p.y / 0.13);
		float mortar = max(inkline(fract(b.x) - 0.5, 0.03 * 3.0) * 0.0, max(inkline(fract(b.y), 0.08), inkline(fract(b.x), 0.03)));
		vec3 brick = accent_b * (0.85 + 0.25 * hash2(floor(b)));
		brick = mix(brick, brick * 0.55, mortar);
		col = mix(col, brick, fall);
		col = mix(col, ink, inkline(noise2(p * 0.9 + seed * 5.0 + 2.0) - 0.66, 0.006) * 0.8);
	} else if (pattern == 11) {
		// mudbrick courses
		vec2 p = uv;
		vec2 b = vec2(p.x / 0.38 + step(1.0, mod(floor(p.y / 0.13), 2.0)) * 0.5, p.y / 0.13);
		float mortar = max(inkline(fract(b.y), 0.09), inkline(fract(b.x), 0.035));
		col *= 0.84 + 0.3 * hash2(floor(b) + seed);
		col = mix(col, col * 0.6, mortar);
	} else if (pattern == 12) {
		// dressed stone: blocks in courses, each its own tone, chisel marks, dark joints
		vec2 p = uv;
		float row = floor(p.y / 0.46);
		vec2 b = vec2(p.x / 0.82 + mod(row, 2.0) * 0.5, p.y / 0.46);
		vec2 cell = floor(b);
		float tone = hash2(cell + seed);
		col *= 0.86 + 0.2 * tone;
		vec2 fb = fract(b);
		float joint = max(inkline(fb.y, 0.03), max(inkline(fb.x, 0.018), max(inkline(1.0 - fb.y, 0.03), inkline(1.0 - fb.x, 0.018))));
		col = mix(col, col * 0.84, smoothstep(0.08, 0.0, min(min(fb.x, 1.0 - fb.x) * 2.0, min(fb.y, 1.0 - fb.y))));
		col *= 0.95 + 0.08 * noise2(p * 18.0 + cell);
		col = mix(col, ink * 1.3, joint * 0.75);
	} else if (pattern == 14) {
		// charred wood: black, cracked in small blocks, a grey bloom of ash
		vec2 p = uv * vec2(26.0, 7.0);
		col *= 0.8 + 0.4 * noise2(p + seed * 4.0);
		col = mix(col, vec3(0.42, 0.40, 0.37), smoothstep(0.6, 0.8, noise2(uv * vec2(9.0, 3.0) + seed)) * 0.5);
	} else if (pattern == 15) {
		// weathered stone: streaks down the face, pale and orange lichen
		vec2 p = uv;
		col *= 0.86 + 0.24 * noise2(p * vec2(3.0, 0.8) + seed * 5.0);
		col *= 0.93 + 0.1 * noise2(vec2(p.x * 22.0, p.y * 2.0));
		float l1 = smoothstep(0.62, 0.7, noise2(p * 3.4 + seed * 9.0) * 0.7 + noise2(p * 11.0) * 0.3);
		float l2 = smoothstep(0.7, 0.76, noise2(p * 5.1 + seed * 2.0 + 7.0));
		col = mix(col, vec3(0.70, 0.72, 0.58), l1 * 0.75);
		col = mix(col, vec3(0.78, 0.50, 0.22), l2 * 0.7);
		col = mix(col, ink, (1.0 - smoothstep(0.0, 0.04, abs(noise2(p * vec2(1.2, 4.0) + seed) - 0.5))) * 0.3);
	} else if (pattern == 16) {
		float g = noise2(uv * vec2(1.1, 28.0) + seed * 3.0);
		col *= 0.94 + 0.12 * g;
	} else if (pattern == 17) {
		vec2 p = v_world.xz / 0.8;
		vec2 f = fract(p);
		float edge = min(min(f.x, 1.0-f.x), min(f.y, 1.0-f.y));
		col *= 0.97 + 0.06 * hash2(floor(p));
		col = mix(col * 0.72, col, smoothstep(0.002, 0.008, edge));
	} else if (pattern == 18) {
		vec2 threads = sin(uv * 280.0);
		col *= 0.98 + 0.02 * threads.x * threads.y;
	} else if (pattern == 19 || pattern == 20) {
		// Early glazing is assembled from small pieces, not modern plate glass.
		vec2 p = pattern == 19 ? vec2(v_world.x + v_world.y, v_world.x - v_world.y) / 0.28 : v_world.xy / vec2(0.38, 0.48);
		vec2 f = fract(p);
		float edge = min(min(f.x, 1.0-f.x), min(f.y, 1.0-f.y));
		col *= 0.92 + 0.16 * hash2(floor(p));
		col = mix(vec3(0.26, 0.29, 0.27), col, smoothstep(0.008, 0.02, edge));
	} else if (pattern == 13) {
		// flagstones on the floor (by the world: no seam shows)
		vec2 p = v_world.xz;
		float row = floor(p.y / 0.75);
		vec2 b = vec2(p.x / 1.05 + hash2(vec2(row, 3.0)) * 0.8, p.y / 0.75);
		vec2 cell = floor(b);
		col *= 0.84 + 0.24 * hash2(cell);
		vec2 fb = fract(b);
		float joint = max(inkline(fb.y, 0.025), inkline(fb.x, 0.018));
		col *= 0.94 + 0.08 * noise2(p * 6.0);
		col = mix(col, ink * 1.2, joint * 0.7);
	}
	return col;
}

// how much a charred log glows: in its cracks, and most near its burning foot
float char_glow(vec2 uv, float seed) {
	if (pattern != 14) {
		return 0.0;
	}
	float crack = 1.0 - smoothstep(0.0, 0.06, abs(noise2(vec2(uv.x * 26.0 + seed * 9.0, uv.y * 7.0)) - 0.5));
	float cells = smoothstep(0.55, 0.75, noise2(uv * vec2(18.0, 6.0) + seed * 3.0));
	float foot = 1.0 - smoothstep(0.05, 0.35, uv.y);
	float flick = 0.7 + 0.3 * sin(TIME * 5.0 + seed * 20.0 + uv.y * 9.0);
	return clamp(max(crack * 0.8, cells * 0.5) * (0.25 + 0.75 * foot) * flick, 0.0, 1.0);
}

void fragment() {
	vec2 uv = vec2(UV.x, 1.0 - UV.y);
	float seed = v_col.b;
	vec3 base = mix(albedo, albedo_worn, clamp(v_col.g, 0.0, 1.0));
	base *= 1.0 + (v_col.b - 0.5) * 2.0 * variation;
	float m = noise3(v_world * mottle_scale) * 0.65 + noise3(v_world * mottle_scale * 2.7 + 3.1) * 0.35;
	base *= 1.0 + (m - 0.5) * 2.0 * mottle;
	if (pattern > 0) {
		base = paint(base, uv, seed);
	}
	float g = noise3(v_world * 38.0) * 0.6 + noise3(v_world * 11.0) * 0.4;
	base *= 1.0 + (g - 0.5) * grain;
	if (dry > 0.0) {
		base = mix(base, base * vec3(1.08, 1.0, 0.82), dry);
	}
	if (snow > 0.0) {
		vec3 wn = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
		float up = smoothstep(0.35, 0.8, wn.y);
		float near_fire = 1.0 - smoothstep(1.2, 2.6, length(v_world.xz - fire_pos.xz));
		float patchy = smoothstep(0.3, 0.6, noise3(v_world * 1.7) + 0.25);
		float cover = clamp(up * patchy * snow * (1.0 - near_fire), 0.0, 1.0);
		base = mix(base, vec3(0.93, 0.95, 0.98) * (0.94 + 0.08 * g), cover);
	}
	float ao = mix(1.0, v_col.r, ao_amount);
	base *= mix(1.0, ao, 0.55);
	float dist = length(v_world - CAMERA_POSITION_WORLD);
	float haze = haze_max * smoothstep(haze_start, haze_end, dist);
	ALBEDO = mix(base, haze_color, haze);
	if (glazing > 0.0) {
		vec3 normal_world = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
		vec3 reflection = reflect(normalize(v_world - CAMERA_POSITION_WORLD), normal_world);
		float sky = smoothstep(-0.22, 0.58, reflection.y);
		vec3 reflected = mix(vec3(0.31, 0.39, 0.38), vec3(0.65, 0.79, 0.84), sky);
		float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
		ALBEDO = mix(ALBEDO, reflected, glazing * (0.55 + 0.45 * fresnel));
	}
	AO = ao;
	AO_LIGHT_AFFECT = 0.25;
	ROUGHNESS = 1.0;
	float flick = 1.0;
	if (emission_flicker > 0.0) {
		flick = 1.0 - emission_flicker + emission_flicker * (0.55 + 0.45 * sin(TIME * 7.3 + v_world.x * 9.0 + v_world.z * 5.0) * sin(TIME * 3.1 + v_world.z * 7.0));
	}
	float glow = pattern == 14 ? char_glow(uv, seed) : 1.0;
	EMISSION = emission_color * emission_amount * flick * glow + haze_color * haze * 0.55;
	if (rim_amount > 0.0) {
		float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
		EMISSION += vec3(1.0, 0.86, 0.66) * rim_amount * fres;
	}
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float lit = smoothstep(-0.04 - wrap, band_soft - wrap, ndl);
	float half_lit = smoothstep(-0.6, -0.15, ndl) * half_tone;
	float tone = max(lit * ATTENUATION, half_lit * min(1.0, ATTENUATION * 1.5));
	DIFFUSE_LIGHT += LIGHT_COLOR * tone / PI;
	if (sheen_amount > 0.0) {
		float reflected = pow(max(dot(NORMAL, normalize(LIGHT + VIEW)), 0.0), sheen_power);
		// A broad painted highlight with a softer shoulder, not a sharp white
		// point that flickers as the conversation camera moves.
		float highlight = smoothstep(0.10, 0.58, reflected);
		SPECULAR_LIGHT += LIGHT_COLOR * ATTENUATION * SPECULAR_AMOUNT * highlight * sheen_amount / PI;
	}
}

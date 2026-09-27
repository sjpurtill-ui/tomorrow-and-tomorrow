// THE GROUND OF A LIVED PLACE (codex/beauty-3, codex/beauty-4): included by
// the terrain shader in local_terrain.gd, after world_beauty.gdshaderinc.
//
// 1. The worn ground of every settlement the camera visits, painted into the
//    land itself from small textures that scripts/settlement_grounds.gd
//    rasterizes from the real layout (plots, buildings, routes) whenever the
//    fabric changes. Four slots (home, other towns, seen foreign cities) share
//    two texture arrays:
//      R  trodden bare earth: paths, door yards, the hearth ground, work yards
//      G  grass worn short and pale around the dwellings
//      B  ash, charcoal and midden stains
//    Edges wander on small noise and carry a faint drawn line, like a
//    hand-coloured plan. Beyond a few metres a pixel it fades out.
// 2. Close meadow: at settlement zoom open grass is painted in brush dabs of a
//    few related greens and straw, with tussocks lit on their sunward side,
//    so no view is a flat lime sheet or a photographic mottle.
// 3. Winter: feet keep the paths open; trodden snow turns to dark slush.
// Visual only. Precise at any world position: all noise runs on local
// coordinates (settlement metres, or the terrain's surface frame).

uniform sampler2DArray settlement_ground : filter_linear_mipmap, repeat_disable;
// Worked ground (fields and kitchen gardens): R cover, G row angle, B phase +
// 8 x pattern + 64 if worked, A crop family x 16 + cover (settlement_grounds.gd).
uniform sampler2DArray settlement_fields : filter_linear, repeat_disable;
// Each slot's square: origin split into an exact multiple of 64 km (x, y) and
// a small remainder (z, w), all in world km.
uniform vec4 sg_origins[4];
// size (km), strength (0 disables), -, -
uniform vec4 sg_frames[4];

float sg_hash(vec2 p) {
	vec3 q = fract(vec3(p.xyx)*0.1031);
	q += dot(q, q.yzx+33.33);
	return fract((q.x+q.y)*q.z);
}

float sg_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f*f*(3.0-2.0*f);
	return mix(mix(sg_hash(i), sg_hash(i+vec2(1.0, 0.0)), f.x),
		mix(sg_hash(i+vec2(0.0, 1.0)), sg_hash(i+vec2(1.0, 1.0)), f.x), f.y);
}

// The slot whose square holds this fragment (-1 if none), and the fragment's
// metres within it (precise: see surface_precision).
int settlement_ground_slot(vec2 surface_position_km, vec2 surface_origin_km, out vec2 local_m) {
	local_m = vec2(-1.0);
	for (int s = 0; s < 4; s++) {
		if (sg_frames[s].y <= 0.0) { continue; }
		vec2 cells = surface_origin_km-sg_origins[s].xy;
		vec2 m = (surface_position_km+cells-sg_origins[s].zw)*1000.0;
		float size_m = sg_frames[s].x*1000.0;
		if (m.x > 0.0 && m.y > 0.0 && m.x < size_m && m.y < size_m) { local_m = m; return s; }
	}
	return -1;
}

// How far the settlement has cleared the wood here (0-1): wherever its
// yards and paths lie, blurred to a few tens of metres, so the trees stand
// back from the houses in a ragged ring.
float settlement_clearing(int slot, vec2 local_m, float pixel_m) {
	if (slot < 0) { return 0.0; }
	float size_m = sg_frames[slot].x*1000.0;
	vec2 uv = local_m/size_m;
	vec4 coarse = textureLod(settlement_ground, vec3(uv, float(slot)), 5.0);
	float lived = max(coarse.g*1.4, coarse.r);
	float ragged = sg_noise(local_m*0.045+vec2(3.0, -1.0))*0.7+sg_noise(local_m*0.13)*0.3;
	float fade = smoothstep(0.02, 0.18, min(min(uv.x, uv.y), min(1.0-uv.x, 1.0-uv.y))+(ragged-0.5)*0.10);
	return smoothstep(0.03, 0.18, lived+(ragged-0.5)*0.16)*fade*sg_frames[slot].y;
}

// The worn ground over `earth`. `slot` and `local_m` from
// settlement_ground_slot; `pixel_m` metres per pixel. `trodden` returns how
// bare the ground is here (for the winter paths). Returns the repainted colour.
vec3 settlement_ground_paint(vec3 earth, int slot, vec2 local_m, float pixel_m, inout float trodden) {
	if (slot < 0) { return earth; }
	float size_m = sg_frames[slot].x*1000.0;
	float strength = sg_frames[slot].y*(1.0-smoothstep(2.5, 6.0, pixel_m));
	if (strength <= 0.0) { return earth; }
	vec2 uv = local_m/size_m;
	float layer = float(slot);
	// Untouched meadow costs one coarse look (a mip a few metres across).
	vec4 coarse = textureLod(settlement_ground, vec3(uv, layer), 2.0);
	if (max(max(coarse.r, coarse.g), coarse.b) < 0.003) { return earth; }
	// Wander the edges a little (in metres, so they hold still as you zoom).
	float wobble = sg_noise(local_m*0.55);
	vec2 warp = (vec2(sg_noise(local_m*0.21+vec2(3.0, 9.0)), wobble)-0.5)*1.4/size_m;
	vec4 g = texture(settlement_ground, vec3(uv+warp, layer));
	float fade = smoothstep(0.0, 0.03, min(min(uv.x, uv.y), min(1.0-uv.x, 1.0-uv.y)));
	g *= fade*strength;
	float luma = dot(earth, vec3(0.2126, 0.7152, 0.0722));
	float close = 1.0-smoothstep(0.25, 0.9, pixel_m);
	// Dry trodden loam, a little paler than the grass it wears through (so it
	// reads as dust in any biome's light), palest where feet pass most.
	// Edges wander on a broad noise and only a little on the fine one, so a
	// half-worn yard reads as one patch, not a leopard's spots.
	float drift = sg_noise(local_m*0.16+vec2(-4.0, 7.0));
	float bare = smoothstep(0.30, 0.62, g.r+(drift-0.5)*0.24+(wobble-0.5)*0.08);
	float heart = smoothstep(0.62, 0.95, g.r);
	float ground_luma = clamp(luma, 0.16, 0.55);
	vec3 soil = vec3(0.98, 0.83, 0.60)*ground_luma*mix(0.92, 1.10, heart);
	// Worn grass: shorter, paler, a little straw in it, and the soil showing
	// through in scuffed patches where feet cut corners.
	float worn = smoothstep(0.02, 0.55, g.g+(wobble-0.5)*0.12);
	vec3 short_grass = mix(earth, vec3(luma)*vec3(1.22, 1.12, 0.82), 0.45)*1.04;
	earth = mix(earth, short_grass, worn*0.75);
	float scuff = smoothstep(0.60, 0.88, sg_noise(local_m*0.30+vec2(-7.0, 3.0))+(g.g-0.5)*0.4)*worn;
	earth = mix(earth, soil*0.96, scuff*0.40);
	// Foot marks and damp ruts close up, never a hard-edged grain.
	float grit = sg_noise(local_m*3.1);
	soil *= 1.0+(grit-0.5)*mix(0.08, 0.22, close);
	float tuft = 0.0;
	if (close > 0.0 && bare > 0.0) {
		// Which way the way runs, from the slope of its wear a few metres
		// across: wheel ruts and foot-worn streaks lie along it, the crown
		// between them paler, damp in the ruts.
		vec2 texel = 4.0/vec2(textureSize(settlement_ground, 0).xy);
		float wx = textureLod(settlement_ground, vec3(uv+vec2(texel.x, 0.0), layer), 2.0).r-textureLod(settlement_ground, vec3(uv-vec2(texel.x, 0.0), layer), 2.0).r;
		float wy = textureLod(settlement_ground, vec3(uv+vec2(0.0, texel.y), layer), 2.0).r-textureLod(settlement_ground, vec3(uv-vec2(0.0, texel.y), layer), 2.0).r;
		vec2 grad = vec2(wx, wy);
		float directed = smoothstep(0.02, 0.10, length(grad));
		vec2 across_dir = directed > 0.0 ? normalize(grad) : vec2(1.0, 0.0);
		float along_m = dot(local_m, vec2(-across_dir.y, across_dir.x));
		float across_m = dot(local_m, across_dir);
		float streak = sg_noise(vec2(along_m*0.12, across_m*1.9)+vec2(2.0, 8.0));
		float rut = mix(smoothstep(0.62, 0.80, sg_noise(local_m*vec2(0.9, 0.35)+vec2(2.0, 8.0))), smoothstep(0.58, 0.78, streak), directed)*heart*close;
		soil *= 1.0-rut*0.16;
		soil *= 1.0+directed*heart*close*(smoothstep(0.30, 0.10, streak))*0.06;
		// A tuft of grass survives here and there at the edge of the bare ground.
		tuft = smoothstep(0.55, 0.75, sg_noise(local_m*1.3+vec2(11.0, 5.0)))*(1.0-heart);
	}
	float trod = bare*(1.0-tuft*0.55);
	earth = mix(earth, soil, trod);
	trodden = trod;
	// The drawn edge: a faint iron-gall line where grass gives way to earth.
	float edge = bare*(1.0-bare)*4.0;
	earth *= 1.0-edge*0.14*(1.0-smoothstep(1.2, 3.5, pixel_m));
	// Ash and middens: grey-brown, darkest at the heart.
	float ash = smoothstep(0.12, 0.55, g.b+(wobble-0.5)*0.20);
	earth = mix(earth, mix(vec3(0.16, 0.14, 0.12), vec3(0.075, 0.065, 0.058), smoothstep(0.5, 0.9, g.b)), ash*0.85);
	return earth;
}

// Worked fields and kitchen gardens: tilled ridges along each field's rows,
// the crop of its season (green, gold, stubble or weedy fallow), a thin
// headland of grass and a drawn edge. Ridges filter to their average colour
// before they could shimmer, so from far up a field is a clean coloured parcel.
vec3 settlement_fields_paint(vec3 earth, int slot, vec2 local_m, float pixel_m) {
	if (slot < 0) { return earth; }
	float size_m = sg_frames[slot].x*1000.0;
	float strength = sg_frames[slot].y*(1.0-smoothstep(4.0, 9.0, pixel_m));
	if (strength <= 0.0) { return earth; }
	vec2 uv = local_m/size_m;
	float layer = float(slot);
	// Most ground is not worked: one plain look before any noise.
	if (textureLod(settlement_fields, vec3(uv, layer), 0.0).r < 0.001) { return earth; }
	vec2 warp = (vec2(sg_noise(local_m*0.13+vec2(3.0, 9.0)), sg_noise(local_m*0.13+vec2(-5.0, 1.0)))-0.5)*0.5/size_m;
	// Four half-texel taps: a smooth edge, never the texels' staircase.
	vec2 half_texel = 0.5/vec2(textureSize(settlement_fields, 0).xy);
	float cover = 0.25*(texture(settlement_fields, vec3(uv+warp+half_texel, layer)).r+texture(settlement_fields, vec3(uv+warp-half_texel, layer)).r
		+texture(settlement_fields, vec3(uv+warp+vec2(half_texel.x, -half_texel.y), layer)).r+texture(settlement_fields, vec3(uv+warp+vec2(-half_texel.x, half_texel.y), layer)).r);
	if (cover < 0.02) { return earth; }
	ivec2 dims = textureSize(settlement_fields, 0).xy;
	ivec2 texel = clamp(ivec2(uv*vec2(dims)), ivec2(0), dims-ivec2(1));
	vec4 code = texelFetch(settlement_fields, ivec3(texel, slot), 0);
	if (code.r < 0.5) {
		// A border texel: borrow the field's code from a neighbour inside it.
		for (int k = 0; k < 4; k++) {
			ivec2 o = k == 0 ? ivec2(1, 0) : (k == 1 ? ivec2(-1, 0) : (k == 2 ? ivec2(0, 1) : ivec2(0, -1)));
			vec4 n = texelFetch(settlement_fields, ivec3(clamp(texel+o, ivec2(0), dims-ivec2(1)), slot), 0);
			if (n.r > 0.5) { code = n; }
		}
		if (code.r < 0.5) { return earth; }
	}
	int bits = int(code.b*255.0+0.5);
	int phase = bits & 7;
	int pattern = (bits >> 3) & 7;
	bool worked = bits >= 64;
	int packed = int(code.a*255.0+0.5);
	int crop = packed >> 4;
	float growth = float(packed & 15)/15.0;
	float angle = code.g*3.14159265;
	vec2 dir = vec2(cos(angle), sin(angle));
	float along = dot(local_m, dir);
	float across = dot(local_m, vec2(-dir.y, dir.x));
	float w = pattern == 1 ? 1.6 : (pattern == 2 ? 1.25 : (pattern == 4 ? 0.75 : 0.9));
	// Household tenure: strips a few metres wide, each worked by its own
	// hands, a little different in tone and in how far on the crop is.
	float strip_w = pattern == 3 ? 7.0 : (pattern == 2 ? 14.0 : 5.0);
	float strip = sg_hash(vec2(floor(across/strip_w), pattern == 0 ? floor(along/11.0) : 0.0));
	float row = across/w;
	float ridge_amp = smoothstep(2.5, 5.0, w/max(pixel_m, 0.001));
	float ridge = mix(0.5, 0.5+0.5*cos(row*6.2831853), ridge_amp*(pattern == 4 ? 1.0 : 0.8));
	// A furrow between strips shows until a pixel spans it.
	float to_balk = strip_w*(0.5-abs(fract(across/strip_w)-0.5));
	float balk = (1.0-smoothstep(0.0, 0.35, to_balk))*(1.0-smoothstep(0.6, 1.4, pixel_m));
	// Tilled loam in the local light: furrows in shade, crests catching it.
	// (Mostly the region's light, only a little of the meadow's own mottle.)
	float L = mix(clamp(dot(earth, vec3(0.2126, 0.7152, 0.0722)), 0.16, 0.55), 0.34, 0.6);
	vec3 furrow = vec3(0.98, 0.80, 0.58)*L;
	vec3 crest = vec3(1.22, 1.02, 0.74)*L;
	vec3 soil = mix(furrow, crest, ridge)*(0.93+0.14*strip);
	// Kitchen gardens are dug deep and dark, and kept.
	if (pattern == 4) { soil *= 0.74; }
	if (pattern == 1) {
		// Beds with a damp channel between them.
		float channel = 1.0-smoothstep(0.0, 0.10, abs(fract(row)-0.5)-0.38);
		soil = mix(soil, soil*0.55, channel*0.8*ridge_amp);
	}
	// The crop of the season (colours in the local light; a crop field reads
	// deeper and more even than the meadow round it, ripe grain gold).
	vec3 green = (crop == 1 ? vec3(0.42, 0.76, 0.14) : (crop == 3 ? vec3(0.42, 0.80, 0.34) : vec3(0.52, 0.86, 0.14)))*L;
	if (crop == 4) {
		float bed = sg_hash(vec2(floor(row), floor(along/3.0)));
		green = mix(vec3(0.46, 0.76, 0.22), vec3(0.74, 0.86, 0.30), bed)*L;
	}
	vec3 ripe = (crop == 0 ? vec3(1.78, 1.26, 0.36) : (crop == 1 ? vec3(0.50, 0.80, 0.18) : (crop == 3 ? vec3(1.40, 1.22, 0.62) : vec3(1.30, 1.14, 0.46))))*L;
	vec3 straw = vec3(1.55, 1.36, 0.86)*L;
	float plants = sg_noise(vec2(along*2.3, row*3.0))*0.5+0.5*sg_noise(local_m*0.7);
	float grown = clamp(growth+(strip-0.5)*0.25, 0.0, 1.0);
	vec3 field = soil;
	if (phase == 2) {
		// Plants in rows, closing over the soil as they grow.
		float closed = smoothstep(0.15, 0.65, grown+(plants-0.5)*0.25+(ridge-0.5)*0.45);
		field = mix(soil, green*(0.94+0.12*strip), closed);
	}
	else if (phase == 3) { field = mix(soil, ripe*(0.92+0.16*strip), smoothstep(0.05, 0.40, ridge*0.6+plants*0.4+0.2)); }
	else if (phase == 4) { field = mix(soil, straw, 0.35+0.35*ridge); }
	else if (phase >= 5) {
		// Fallow: weeds and grass take the beds back, the ridges still
		// showing where hands keep it worked.
		float weeds = smoothstep(0.35, 0.75, plants+(strip-0.5)*0.4);
		vec3 grassy = mix(earth, soil, worked ? 0.30 : 0.10);
		field = mix(worked ? soil : mix(soil, earth, 0.4), grassy, weeds*(worked ? 0.55 : 0.85));
		if (phase == 6) { field = mix(field, straw*0.8, 0.25*plants); }
	}
	field *= 1.0-balk*0.18;
	// Edge: a thin grass headland and a drawn line.
	float inside = smoothstep(0.45, 0.62, cover);
	float edge = smoothstep(0.30, 0.45, cover)*(1.0-smoothstep(0.50, 0.66, cover));
	earth = mix(earth, field, inside*strength);
	earth *= 1.0-edge*0.22*strength*(1.0-smoothstep(1.5, 4.0, pixel_m));
	return earth;
}

// One octave of brush dabs: a jittered grid of short strokes (elongated a
// little along the wash, each turned a little its own way) whose tones blend
// where they overlap, the way wet strokes do. Returns (distance to the nearest
// stroke's edge 0-1+, the blended tone 0-1, the nearest stroke's second tone
// 0-1, how the nearest stroke's top faces the sun -1..1).
// `wide` searches the 3 x 3 cells round the fragment; otherwise strokes sit
// closer to their cells and only the 2 x 2 nearest are searched (cheaper, for
// the broad wash that is also drawn from higher up).
vec4 sg_dabs(vec2 p, bool wide) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float best = 9.0;
	vec4 out_dab = vec4(9.0, 0.5, 0.5, 0.0);
	float weight = 0.0;
	float tone = 0.0;
	ivec2 lo = wide ? ivec2(-1) : ivec2(step(f, vec2(0.5)))*-1;
	ivec2 hi = wide ? ivec2(1) : lo+ivec2(1);
	for (int y = lo.y; y <= hi.y; y++) {
		for (int x = lo.x; x <= hi.x; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 cell = i+g;
			float h0 = map_paper_hash(cell);
			float h1 = map_paper_hash(cell+vec2(17.0, -5.0));
			float h2 = map_paper_hash(cell+vec2(-29.0, 13.0));
			vec2 r = f-(g+0.5+(vec2(h0, h1)-0.5)*(wide ? 0.75 : 0.5));
			float a = 0.30+(h2-0.5)*0.9;
			vec2 d = vec2(cos(a), sin(a));
			vec2 q = vec2(dot(r, d), dot(r, vec2(-d.y, d.x)));
			float e = length(q*vec2(0.80, 1.55))/(0.52+0.22*h1);
			float h3 = map_paper_hash(cell+vec2(41.0, 7.0));
			float w = exp(-3.5*e*e);
			weight += w;
			tone += h3*w;
			if (e < best) {
				best = e;
				out_dab = vec4(e, h3, h0, dot(r/max(length(r), 0.001), vec2(0.7385, 0.6743)));
			}
		}
	}
	// Mostly the nearest stroke's own tone, softened toward its neighbours'.
	out_dab.y = mix(out_dab.y, tone/max(weight, 0.0001), 0.55);
	return out_dab;
}

// Close meadow: open grass painted in dabs at three scales (patches of a few
// metres, clumps, and tussocks up close), from a calm base in the region's own
// palette colour. `open` is 1 on open grassland (0 under woods, rock, water or
// snow); `palette` the biome palette colour (linear) that the land is painted in.
vec3 settlement_meadow(vec3 earth, vec2 surface_position_km, vec2 surface_origin_km, float pixel_m, float open, vec3 palette) {
	// Fades in below a few metres a pixel (the valley view keeps its wash).
	float near = (1.0-smoothstep(1.2, 4.0, pixel_m))*open;
	if (near <= 0.0) { return earth; }
	float close = (1.0-smoothstep(0.35, 1.6, pixel_m))*open;
	// A precise local frame: metres from the camera's 64 km cell.
	vec2 p = surface_position_km*1000.0;
	vec2 cell = mod(surface_origin_km, vec2(512.0))*1000.0;
	p += cell;
	float luma = dot(earth, vec3(0.2126, 0.7152, 0.0722));
	float pal_luma = max(dot(palette, vec3(0.2126, 0.7152, 0.0722)), 0.001);
	// A calm base: the ground's own light in the region's palette hue (the
	// photograph's colour mottle goes), a little greener than lime and a
	// value lower, the way a painter lays grass under warm light.
	vec3 calm = palette/pal_luma*luma;
	vec3 base = mix(earth, calm, 0.70*near);
	float base_luma = dot(base, vec3(0.2126, 0.7152, 0.0722));
	base = mix(vec3(base_luma), base, mix(1.0, 0.88, near))*vec3(0.96, 1.0, 0.98);
	base *= mix(1.0, 0.80, near);
	// Moisture a dozen metres across: lusher, cooler hollows and drier,
	// warmer rises, laid as broad washes under the strokes.
	float moist = sg_noise(p*0.075+vec2(5.0, -3.0))*0.65+sg_noise(p*0.19)*0.35;
	base *= mix(vec3(1.0), mix(vec3(0.90, 0.97, 0.95), vec3(1.07, 1.03, 0.90), smoothstep(0.25, 0.75, moist)), near);
	vec3 deep = base*vec3(0.80, 0.88, 0.85);
	vec3 sage = mix(base, vec3(dot(base, vec3(0.2126, 0.7152, 0.0722)))*vec3(0.98, 1.05, 1.02), 0.30)*1.05;
	vec3 straw = mix(base, vec3(dot(base, vec3(0.2126, 0.7152, 0.0722)))*vec3(1.26, 1.12, 0.78), 0.55);
	// Patches (3 m): broad dabs of related greens, a little straw on the rises.
	vec3 c = base;
	// Strokes under two pixels only speckle: from higher up the washes carry it.
	float stroke_w = near*(1.0-smoothstep(0.9, 1.7, pixel_m));
	if (stroke_w > 0.0) {
		vec4 broad = sg_dabs(p/3.2, false);
		float t = clamp(broad.y*0.75+(1.0-moist)*0.5-0.12, 0.0, 1.0);
		vec3 tone = t < 0.5 ? mix(deep, base, t*2.0) : mix(base, sage, t*2.0-1.0);
		tone = mix(tone, straw, smoothstep(0.80, 0.95, broad.z)*smoothstep(0.45, 0.70, 1.0-moist));
		float soft = 1.0-smoothstep(0.70, 1.30, broad.x);
		c = mix(c, tone, (0.48+0.25*soft)*stroke_w);
	}
	// Clumps (1.3 m) and tussocks (0.45 m): each lit on its sunward side,
	// shaded on the far side, dark where it meets the next.
	float clump_w = (1.0-smoothstep(0.18, 0.40, pixel_m))*close;
	if (clump_w > 0.0) {
		vec4 clump = sg_dabs(p/1.3+vec2(3.7, -1.9), true);
		float body = 1.0-smoothstep(0.55, 1.05, clump.x);
		float lit = -clump.w*(1.0-clump.x*0.4);
		vec3 tone = mix(c, clump.y < 0.3 ? deep : (clump.y > 0.88 ? straw : sage), 0.22);
		tone *= 1.0+lit*0.12;
		c = mix(c, mix(c*0.91, tone, body), clump_w*0.80);
	}
	float tuft_w = (1.0-smoothstep(0.07, 0.16, pixel_m))*close;
	if (tuft_w > 0.0) {
		vec4 tuft = sg_dabs(p/0.45+vec2(-8.1, 2.3), false);
		float body = 1.0-smoothstep(0.50, 1.0, tuft.x);
		float lit = -tuft.w*(1.0-tuft.x*0.5);
		c *= 1.0+(body*(lit*0.16+0.02)-(1.0-body)*0.06)*tuft_w;
	}
	// Grain within a stroke, like dry brush on paper.
	float fine = 1.0-smoothstep(0.12, 0.45, pixel_m);
	float blade = sg_noise(vec2(p.x*2.6+p.y*0.9, p.y*2.6-p.x*0.9)*vec2(1.0, 3.0));
	c *= 1.0+(blade-0.5)*0.10*fine*open;
	// Flowers, very sparse: cream and a little madder, only up close.
	vec2 fc = floor(p*1.4);
	float f = map_paper_hash(fc);
	if (f > 0.988 && fine > 0.0) {
		vec2 at = fract(p*1.4)-vec2(map_paper_hash(fc+17.0), map_paper_hash(fc-9.0))*0.6-0.2;
		float dot_ = 1.0-smoothstep(0.10, 0.20, length(at));
		vec3 bloom = f > 0.9965 ? vec3(0.56, 0.28, 0.24) : vec3(0.72, 0.69, 0.55);
		c = mix(c, bloom, dot_*fine*0.80);
	}
	return mix(earth, c, open);
}

// Winter on the settlement's ground: `before` is the colour before snow and
// frost were laid, `after` with them, `trodden` from settlement_ground_paint.
// Feet keep the paths open: the snow on them is trodden into grey-brown slush
// with darker wheel and foot ruts, and the path's edge is a crisp line.
vec3 settlement_winter_paths(vec3 before, vec3 after, float trodden, vec2 local_m, float pixel_m) {
	if (trodden <= 0.01) { return after; }
	float white_before = min(before.r, min(before.g, before.b));
	float white_after = min(after.r, min(after.g, after.b));
	float snow = clamp((white_after-white_before)*2.6, 0.0, 1.0);
	if (snow <= 0.01) { return after; }
	float rut = sg_noise(local_m*vec2(1.6, 0.5)+vec2(4.0, -2.0));
	vec3 slush = mix(vec3(0.20, 0.18, 0.16), vec3(0.42, 0.42, 0.41), smoothstep(0.35, 0.75, rut));
	slush = mix(slush, before*0.70, 0.30);
	// Heaped snow at the path's shoulder, cleaner than the open ground.
	float path = smoothstep(0.25, 0.65, trodden);
	float shoulder = smoothstep(0.08, 0.30, trodden)*(1.0-path);
	vec3 c = mix(after, slush, path*snow);
	c = mix(c, max(after, vec3(0.86, 0.88, 0.90)), shoulder*snow*0.55);
	// The drawn edge of the cleared path.
	c *= 1.0-path*(1.0-path)*4.0*0.18*snow*(1.0-smoothstep(1.2, 3.5, pixel_m));
	return c;
}

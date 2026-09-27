// THE GROUND OF A LIVED PLACE (codex/beauty-3): included by the terrain
// shader in local_terrain.gd, after world_beauty.gdshaderinc.
//
// 1. The home settlement's worn ground, painted into the land itself from a
//    small texture that scripts/settlement_grounds.gd rasterizes from the real
//    layout (plots, buildings, routes) whenever the fabric changes:
//      R  trodden bare earth: paths, door yards, the hearth ground, work yards
//      G  grass worn short and pale around the dwellings
//      B  ash, charcoal and midden stains
//    Edges wander on small noise and carry a faint drawn line, like a
//    hand-coloured plan. Beyond a few metres a pixel it fades out.
// 2. Close meadow: at settlement zoom the open grass breaks into tussocks,
//    drier straw patches and a few flowers, so no view is a flat lime field.
// Visual only. Precise at any world position: all noise runs on local
// coordinates (settlement metres, or the terrain's surface frame).

uniform sampler2D settlement_ground : filter_linear_mipmap, repeat_disable;
// Worked ground (fields and kitchen gardens): R cover, G row angle, B phase +
// 8 x pattern + 64 if worked, A crop family x 16 + cover (settlement_grounds.gd).
uniform sampler2D settlement_fields : filter_linear, repeat_disable;
// Settlement square: origin split into an exact multiple of 64 km (x, y) and a
// small remainder (z, w), all in world km.
uniform vec4 settlement_ground_origin = vec4(0.0);
// size (km), strength (0 disables), -, -
uniform vec4 settlement_ground_frame = vec4(1.0, 0.0, 0.0, 0.0);

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

// Settlement-local metres for a fragment (precise: see surface_precision).
vec2 sg_local_m(vec2 surface_position_km, vec2 surface_origin_km) {
	vec2 cells = surface_origin_km-settlement_ground_origin.xy;
	return (surface_position_km+cells-settlement_ground_origin.zw)*1000.0;
}

// The worn ground over `earth`. `local_m` from sg_local_m; `pixel_m` metres
// per pixel. Returns the repainted colour.
vec3 settlement_ground_paint(vec3 earth, vec2 local_m, float pixel_m) {
	float size_m = settlement_ground_frame.x*1000.0;
	float strength = settlement_ground_frame.y*(1.0-smoothstep(2.5, 6.0, pixel_m));
	if (strength <= 0.0) { return earth; }
	vec2 uv = local_m/size_m;
	if (uv.x <= 0.0 || uv.y <= 0.0 || uv.x >= 1.0 || uv.y >= 1.0) { return earth; }
	// Wander the edges a little (in metres, so they hold still as you zoom).
	float wobble = sg_noise(local_m*0.55)*0.65+sg_noise(local_m*1.9+vec2(7.1, -3.3))*0.35;
	vec2 warp = (vec2(sg_noise(local_m*0.21+vec2(3.0, 9.0)), sg_noise(local_m*0.21+vec2(-5.0, 1.0)))-0.5)*1.4/size_m;
	vec4 g = texture(settlement_ground, uv+warp);
	float fade = smoothstep(0.0, 0.03, min(min(uv.x, uv.y), min(1.0-uv.x, 1.0-uv.y)));
	g *= fade*strength;
	float luma = dot(earth, vec3(0.2126, 0.7152, 0.0722));
	// Worn grass: shorter, paler, a little straw in it.
	float worn = smoothstep(0.02, 0.55, g.g+(wobble-0.5)*0.12);
	vec3 short_grass = mix(earth, vec3(luma)*vec3(1.28, 1.14, 0.80), 0.55)*1.08;
	earth = mix(earth, short_grass, worn*0.80);
	// Trodden earth: warm dry loam, paler where feet pass most.
	float bare = smoothstep(0.30, 0.62, g.r+(wobble-0.5)*0.34);
	float heart = smoothstep(0.62, 0.95, g.r);
	// Dry trodden loam, a little paler than the grass it wears through (so it
	// reads as dust in any biome's light), palest where feet pass most.
	float ground_luma = clamp(luma, 0.16, 0.55);
	vec3 soil = vec3(0.98, 0.83, 0.60)*ground_luma*mix(0.92, 1.10, heart);
	// Foot marks and damp ruts close up, never a hard-edged grain.
	float grit = sg_noise(local_m*3.1)*0.6+sg_noise(local_m*7.3+vec2(1.7, 4.2))*0.4;
	float close = 1.0-smoothstep(0.25, 0.9, pixel_m);
	soil *= 1.0+(grit-0.5)*mix(0.08, 0.22, close);
	float rut = smoothstep(0.62, 0.80, sg_noise(local_m*vec2(0.9, 0.35)+vec2(2.0, 8.0)))*heart*close;
	soil *= 1.0-rut*0.12;
	// A tuft of grass survives here and there at the edge of the bare ground.
	float tuft = smoothstep(0.55, 0.75, sg_noise(local_m*1.3+vec2(11.0, 5.0)))*(1.0-heart);
	earth = mix(earth, soil, bare*(1.0-tuft*0.55));
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
vec3 settlement_fields_paint(vec3 earth, vec2 local_m, float pixel_m) {
	float size_m = settlement_ground_frame.x*1000.0;
	float strength = settlement_ground_frame.y*(1.0-smoothstep(4.0, 9.0, pixel_m));
	if (strength <= 0.0) { return earth; }
	vec2 uv = local_m/size_m;
	if (uv.x <= 0.0 || uv.y <= 0.0 || uv.x >= 1.0 || uv.y >= 1.0) { return earth; }
	vec2 warp = (vec2(sg_noise(local_m*0.13+vec2(3.0, 9.0)), sg_noise(local_m*0.13+vec2(-5.0, 1.0)))-0.5)*0.9/size_m;
	float cover = texture(settlement_fields, uv+warp).r;
	if (cover < 0.02) { return earth; }
	ivec2 dims = textureSize(settlement_fields, 0);
	ivec2 texel = clamp(ivec2(uv*vec2(dims)), ivec2(0), dims-ivec2(1));
	vec4 code = texelFetch(settlement_fields, texel, 0);
	if (code.r < 0.5) {
		// A border texel: borrow the field's code from a neighbour inside it.
		for (int k = 0; k < 4; k++) {
			ivec2 o = k == 0 ? ivec2(1, 0) : (k == 1 ? ivec2(-1, 0) : (k == 2 ? ivec2(0, 1) : ivec2(0, -1)));
			vec4 n = texelFetch(settlement_fields, clamp(texel+o, ivec2(0), dims-ivec2(1)), 0);
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
	// Household parcels in a mosaic: each strip a little different.
	float parcel = sg_hash(vec2(floor(along/9.0), floor(across/(w*6.0))));
	float row = across/w;
	float ridge_amp = smoothstep(1.4, 3.5, w/max(pixel_m, 0.001));
	float ridge = mix(0.5, 0.5+0.5*cos(row*6.2831853), ridge_amp*0.8);
	// Tilled loam in the local light: furrows in shade, crests catching it.
	float field_luma = clamp(dot(earth, vec3(0.2126, 0.7152, 0.0722)), 0.16, 0.55);
	vec3 furrow = vec3(0.98, 0.80, 0.58)*field_luma;
	vec3 crest = vec3(1.22, 1.02, 0.74)*field_luma;
	vec3 soil = mix(furrow, crest, ridge)*(0.92+0.16*parcel);
	if (pattern == 1) {
		// Beds with a damp channel between them.
		float channel = 1.0-smoothstep(0.0, 0.10, abs(fract(row)-0.5)-0.38);
		soil = mix(soil, vec3(0.105, 0.100, 0.090), channel*0.7*ridge_amp);
	}
	// The crop of the season, on the ridges.
	// Crop colours relative to the local light (the grade keeps them in palette).
	vec3 green = (crop == 1 ? vec3(0.62, 0.92, 0.40) : (crop == 3 ? vec3(0.66, 0.88, 0.70) : vec3(0.78, 0.98, 0.42)))*field_luma;
	if (crop == 4) {
		float bed = sg_hash(vec2(floor(row), floor(along/3.0)));
		green = mix(vec3(0.62, 0.95, 0.42), vec3(0.95, 0.98, 0.50), bed)*field_luma;
	}
	vec3 ripe = (crop == 0 ? vec3(1.30, 1.05, 0.52) : (crop == 3 ? vec3(0.80, 0.88, 1.00) : vec3(0.95, 0.92, 0.48)))*field_luma;
	vec3 straw = vec3(1.20, 1.05, 0.72)*field_luma;
	float plants = sg_noise(vec2(along*2.3, row*3.0))*0.5+0.5*sg_noise(local_m*0.7);
	vec3 field = soil;
	float leafy = 0.0;
	if (phase == 2) {
		// Plants in rows: clumps along each ridge, closing up as they grow.
		leafy = growth;
		float clumps = smoothstep(0.35, 0.65, plants+ridge*0.5+growth*0.3-0.35);
		field = mix(soil, green, clumps*mix(0.55, 0.9, growth));
	}
	else if (phase == 3) { field = mix(soil, ripe, 0.85*smoothstep(0.1, 0.5, ridge+plants*0.4)); }
	else if (phase == 4) { field = mix(soil, straw, 0.55*ridge); }
	else if (phase >= 5) {
		// Fallow: weeds and grass take the beds back, the ridges still
		// showing where hands keep it worked.
		float weeds = smoothstep(0.35, 0.75, plants+(parcel-0.5)*0.4);
		vec3 grassy = mix(earth, soil, worked ? 0.30 : 0.10);
		field = mix(worked ? soil : mix(soil, earth, 0.4), grassy, weeds*(worked ? 0.55 : 0.85));
		if (phase == 6) { field = mix(field, straw*0.8, 0.25*plants); }
	}
	// Edge: a thin grass headland and a drawn line.
	float inside = smoothstep(0.45, 0.62, cover);
	float edge = smoothstep(0.30, 0.45, cover)*(1.0-smoothstep(0.50, 0.66, cover));
	earth = mix(earth, field, inside*strength);
	earth *= 1.0-edge*0.22*strength*(1.0-smoothstep(1.5, 4.0, pixel_m));
	return earth;
}

// Close meadow: tussocks, straw patches and a few flowers on open grass.
// `open` is 1 on open grassland (0 under woods, rock, water or snow).
vec3 settlement_meadow(vec3 earth, vec2 surface_position_km, vec2 surface_origin_km, float pixel_m, float open) {
	float close = (1.0-smoothstep(0.35, 1.6, pixel_m))*open;
	if (close <= 0.0) { return earth; }
	// A precise local frame: metres from the camera's 64 km cell.
	vec2 p = surface_position_km*1000.0;
	vec2 cell = mod(surface_origin_km, vec2(512.0))*1000.0;
	p += cell;
	float luma = dot(earth, vec3(0.2126, 0.7152, 0.0722));
	// Drier patches a few metres across, lusher hollows between.
	float patch = sg_noise(p*0.11)*0.6+sg_noise(p*0.37+vec2(4.0, 1.0))*0.4;
	vec3 straw = vec3(luma)*vec3(1.34, 1.16, 0.74);
	earth = mix(earth, straw, smoothstep(0.52, 0.80, patch)*0.30*close);
	earth *= 1.0-smoothstep(0.40, 0.15, patch)*0.10*close;
	// Tussocks: dark clumps with lit tops, a metre or so across.
	float clump = sg_noise(p*0.9+vec2(-2.0, 7.0));
	float fine = 1.0-smoothstep(0.12, 0.45, pixel_m);
	float blade = sg_noise(vec2(p.x*2.6+p.y*0.9, p.y*2.6-p.x*0.9)*vec2(1.0, 3.0));
	earth *= 1.0+(clump-0.5)*0.22*close+(blade-0.5)*0.16*fine*open;
	// Flowers, very sparse: cream and a little madder, only up close.
	vec2 fc = floor(p*1.4);
	float f = sg_hash(fc);
	if (f > 0.985 && fine > 0.0) {
		vec2 at = fract(p*1.4)-vec2(sg_hash(fc+17.0), sg_hash(fc-9.0))*0.6-0.2;
		float dot_ = 1.0-smoothstep(0.10, 0.20, length(at));
		vec3 bloom = f > 0.9955 ? vec3(0.62, 0.30, 0.26) : vec3(0.78, 0.74, 0.58);
		earth = mix(earth, bloom, dot_*fine*0.85);
	}
	return earth;
}

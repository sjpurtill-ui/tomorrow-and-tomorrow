shader_type spatial;
// Chart marks for places (resource_icons.settlement_atlas): a flat inked glyph
// that faces the screen at a constant pixel size, drawn over the map.
// The mark's size comes from its node or instance scale, read as a radius in
// kilometres at the current zoom (the existing locator sizing), so the same
// scale that used to size the 3D token now sizes the glyph in pixels. A zero
// scale hides the mark. The glyph cell comes from the instance's custom data
// (MultiMesh) or `glyph_index` (a single mark).
render_mode unshaded, blend_mix, depth_test_disabled, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform sampler2D glyphs : source_color, filter_linear_mipmap, repeat_disable;
uniform float glyph_count = 8.0;
uniform bool use_instance_glyph = false;
instance uniform float glyph_index = 0.0;
// Sizes are design pixels: 1/1080 of the view's height, the HUD's own unit,
// so marks keep their proportion to the interface at any window size.
// Pixels of glyph diameter per pixel of locator radius.
uniform float pixels_per_radius = 4.8;
uniform float min_diameter_px = 14.0;
uniform float max_diameter_px = 40.0;
// When positive, a constant size that ignores the scale (scale still hides).
uniform float fixed_diameter_px = 0.0;
// The people's own place (local_terrain settlement_blip): a fine gold ring at
// `home_ring_radius` (a fraction of the mark's square) set on a paper keyline,
// and `mark_alpha` to fade the mark in as the view leaves its fabric.
uniform bool home_ring = false;
instance uniform float home_ring_radius = 0.0;
instance uniform float mark_alpha = 1.0;
// A people's colour washed into the paper of their town's mark (linear RGB;
// alpha is the strength, zero for none). Ink, halo and gold stay as drawn.
instance uniform vec4 accent = vec4(0.0);
varying float cell;
varying float diameter;

void vertex() {
	float radius_km = length(MODEL_MATRIX[0].xyz);
	// Face the screen (the billboard of BaseMaterial3D), without the scale.
	MODELVIEW_MATRIX = VIEW_MATRIX*mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	float depth = max(-(MODELVIEW_MATRIX*vec4(0.0, 0.0, 0.0, 1.0)).z, 0.000001);
	// Kilometres per design pixel at this depth (perspective map camera). The
	// compatibility renderer flips Y in the projection, hence the abs().
	float km_per_px = 2.0*depth/max(abs(PROJECTION_MATRIX[1][1])*1080.0, 0.0001);
	float radius_px = radius_km/km_per_px;
	float diameter_px = radius_km > 0.0 ? clamp(radius_px*pixels_per_radius, min_diameter_px, max_diameter_px) : 0.0;
	if (fixed_diameter_px > 0.0 && radius_km > 0.0) { diameter_px = fixed_diameter_px; }
	VERTEX = vec3(VERTEX.xy*diameter_px*km_per_px, 0.0);
	diameter = diameter_px;
	cell = use_instance_glyph ? INSTANCE_CUSTOM.x : glyph_index;
}

void fragment() {
	vec2 uv = vec2((clamp(UV.x, 0.002, 0.998)+floor(cell+0.5))/glyph_count, UV.y);
	vec4 mark = texture(glyphs, uv);
	ALBEDO = mark.rgb;
	ALPHA = mark.a*COLOR.a;
	if (accent.a > 0.0) {
		float paper = step(0.9, mark.a)*smoothstep(0.5, 0.75, dot(mark.rgb, vec3(0.3333)));
		ALBEDO = mix(ALBEDO, ALBEDO*accent.rgb, paper*accent.a);
	}
	if (home_ring && home_ring_radius > 0.0) {
		float from_ring_px = abs(length(UV-vec2(0.5))-home_ring_radius)*diameter;
		float keyline = (1.0-smoothstep(1.2, 2.2, from_ring_px))*0.55;
		float gold = 1.0-smoothstep(0.45, 1.05, from_ring_px);
		// Linear colours: paper #F1E7CF, brass gold #A88A4A.
		vec3 ring = mix(vec3(0.879, 0.799, 0.624), vec3(0.392, 0.254, 0.069), gold);
		float ring_alpha = max(keyline, gold);
		ALBEDO = mix(ring, ALBEDO, ALPHA);
		ALPHA = max(ALPHA, ring_alpha);
	}
	ALPHA *= mark_alpha;
}

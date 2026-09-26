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
varying float cell;

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
	cell = use_instance_glyph ? INSTANCE_CUSTOM.x : glyph_index;
}

void fragment() {
	vec2 uv = vec2((clamp(UV.x, 0.002, 0.998)+floor(cell+0.5))/glyph_count, UV.y);
	vec4 mark = texture(glyphs, uv);
	ALBEDO = mark.rgb;
	ALPHA = mark.a*COLOR.a;
}

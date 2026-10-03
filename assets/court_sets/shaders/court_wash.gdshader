shader_type spatial;
// The land beyond the court, laid in as ink-wash: each layer (a curtain made
// by court_set_kit.far_layer) is a flat wash of one colour, inked along its
// ridge and its tree canopies, darker just under the ridge and bleeding
// paler toward its foot, granulated like pigment on rough paper. The further
// layers are fainter and bluer in the air. Unlit on purpose: the distance
// does not take the fire's light, only the sky's.
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec3 wash : source_color = vec3(0.42, 0.47, 0.38);
uniform vec3 air : source_color = vec3(0.80, 0.82, 0.80);
uniform float airiness = 0.2;
uniform vec3 ink : source_color = vec3(0.22, 0.20, 0.17);
uniform float ink_amount = 0.75;
uniform float ink_width = 0.18;
uniform float bleed = 3.0;
uniform float granulate = 0.10;
// a tree line shows its trunks and the shadows under the crowns
uniform float trunks = 0.0;
// how far below the ridge the wash takes to come in (metres): a soft edge
uniform float feather = 0.35;
uniform float snow = 0.0;

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash2(i), hash2(i + vec2(1, 0)), f.x), mix(hash2(i + vec2(0, 1)), hash2(i + vec2(1, 1)), f.x), f.y);
}

void fragment() {
	// UV.x runs along the layer (metres); depth below the ridge in metres
	// (the glTF flip makes it 1 - v)
	float along = UV.x;
	float depth = 1.0 - UV.y;
	float d = max(depth, 0.0);
	// the wash pools darker just under the ridge, then fades down
	float pool = exp(-d / max(bleed, 0.01));
	vec3 col = mix(mix(wash, air, 0.3), wash * 0.86, pool);
	if (trunks > 0.0) {
		float stem = 1.0 - smoothstep(0.0, 0.035, abs(fract(along * 0.3 + noise2(vec2(along * 0.1, 1.0)) * 2.0) - 0.5));
		float under = smoothstep(1.0, 2.6, d) * (1.0 - smoothstep(4.0, 6.5, d));
		col = mix(col, ink, stem * under * trunks * step(0.45, noise2(vec2(along * 0.9, 5.0))));
		col = mix(col, col * 0.78, smoothstep(1.2, 2.2, d) * (1.0 - smoothstep(3.5, 5.5, d)) * trunks);
	}
	// granulation and brush texture
	float g = noise2(vec2(along * 0.6, d * 1.4)) * 0.6 + noise2(vec2(along * 2.3, d * 3.1)) * 0.4;
	col *= 1.0 + (g - 0.5) * granulate * 2.0;
	// soft horizontal brush drags, never vertical stripes
	float streak = noise2(vec2(along * 0.12, d * 2.2));
	col *= 0.985 + 0.03 * streak;
	// the inked ridge, a little below the soft top, broken like a brush lifting
	float lift = smoothstep(0.25, 0.4, noise2(vec2(along * 0.35, 3.0)));
	float at = d - feather * 0.55;
	float line = (1.0 - smoothstep(ink_width * 0.3, ink_width, abs(at))) * ink_amount * (0.35 + 0.65 * lift) * step(0.0, at + ink_width);
	col = mix(col, ink, line);
	if (snow > 0.0) {
		// snow on the ridges and the tops of the far woods
		float cap = (1.0 - smoothstep(0.0, 1.4 + 1.6 * noise2(vec2(along * 0.04, 1.0)), d)) * snow;
		col = mix(col, vec3(0.88, 0.90, 0.94), cap * 0.75);
	}
	col = mix(col, air, airiness);
	ALBEDO = col;
	// the top of the wash comes in softly, unevenly, like wet paint
	float edge = feather * (0.7 + 0.6 * noise2(vec2(along * 0.15, 2.0)));
	ALPHA = smoothstep(0.0, max(edge, 0.01), d);
}

shader_type spatial;
// A pot on the boil: laid over the broth, bubbles swell up in it, catch the
// light and pop, faster as `boil` rises (0 still, 1 a rolling boil); a skin
// of scum drifts round the edge. Drawn only while something boils.
render_mode unshaded, depth_draw_opaque, cull_disabled, shadows_disabled, fog_disabled;

uniform vec3 broth : source_color = vec3(0.5, 0.36, 0.2);
uniform vec3 scum : source_color = vec3(0.66, 0.55, 0.38);
uniform float boil = 1.0;
uniform float seed = 0.0;

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	if (r > 1.0) {
		discard;
	}
	vec3 col = broth * (0.85 + 0.15 * sin(r * 9.0 - TIME * 1.5 * boil));
	// scum round the edge
	col = mix(col, scum, smoothstep(0.72, 0.98, r) * 0.6);
	// bubbles: a grid of cells, each one swelling and popping on its own clock
	vec2 g = p * 4.5;
	vec2 cell = floor(g);
	for (int i = -1; i <= 1; i++) {
		for (int j = -1; j <= 1; j++) {
			vec2 c = cell + vec2(float(i), float(j));
			float h = hash2(c + seed);
			if (h > 0.25 + 0.55 * boil) {
				continue;
			}
			vec2 centre = c + 0.5 + 0.35 * vec2(hash2(c + 3.1), hash2(c + 7.7)) - 0.17;
			float life = fract(TIME * (0.5 + 1.4 * boil) * (0.6 + h) + h * 7.0);
			float size = 0.12 + 0.3 * life * (0.5 + h);
			float d = length(g - centre);
			float ring = smoothstep(size, size - 0.06, d) * step(life, 0.9);
			float rim = smoothstep(size - 0.1, size - 0.03, d) * ring;
			col = mix(col, broth * 1.25, ring * 0.6);
			col = mix(col, vec3(1.0, 0.93, 0.8), rim * 0.55);
			// the glint on its top
			col = mix(col, vec3(1.0), smoothstep(size * 0.35, 0.0, length(g - centre - vec2(-size * 0.3, size * 0.3))) * ring * 0.7);
		}
	}
	ALBEDO = col;
}

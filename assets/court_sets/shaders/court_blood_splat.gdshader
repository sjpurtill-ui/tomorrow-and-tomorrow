shader_type spatial;
// A splat of blood, cartoon-bright: a blob with a ragged rim, a few flung
// satellite drops, a wet highlight while fresh, going dark and dull as it
// dries. Laid flat on the floor (a MultiMesh: INSTANCE_CUSTOM = seed, alpha,
// dryness, splash), or stuck on someone as a small sticker (instance
// uniform `sticker`, same channels).
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec3 fresh : source_color = vec3(0.86, 0.04, 0.07);
uniform vec3 deep : source_color = vec3(0.55, 0.0, 0.04);
uniform vec3 dried : source_color = vec3(0.30, 0.06, 0.05);
instance uniform vec4 sticker = vec4(0.0);

varying vec4 v_data;

void vertex() {
	v_data = sticker.g > 0.0 ? sticker : INSTANCE_CUSTOM;
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

void fragment() {
	float seed = v_data.r * 97.0;
	float alpha = v_data.g;
	float dry = v_data.b;
	float splash = v_data.a;
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	float a = atan(p.y, p.x);
	// a ragged main blob, lobed by noise round its edge
	float edge = 0.48 + 0.16 * noise2(vec2(a * 2.2 + seed, seed)) + 0.08 * noise2(vec2(a * 7.0 - seed, 3.0));
	float blob = 1.0 - smoothstep(edge - 0.04, edge, r);
	// fingers flung out along the splash
	float fingers = step(0.78, noise2(vec2(a * 6.0 + seed * 1.7, 1.0))) * (1.0 - smoothstep(edge, edge + 0.32 * splash, r)) * step(edge - 0.05, r);
	// satellite drops
	float drops = 0.0;
	for (int k = 0; k < 5; k++) {
		float fk = float(k);
		float da = hash2(vec2(seed, fk)) * 6.2832;
		float dr = 0.62 + 0.3 * hash2(vec2(fk, seed));
		vec2 c = vec2(cos(da), sin(da)) * dr * (0.6 + 0.4 * splash);
		float size = 0.04 + 0.05 * hash2(vec2(fk * 3.0, seed));
		drops = max(drops, 1.0 - smoothstep(size * 0.8, size, length(p - c)));
	}
	float shape = max(blob, max(fingers, drops));
	if (shape < 0.01) {
		discard;
	}
	vec3 col = mix(fresh, deep, smoothstep(0.0, edge, edge - r) * 0.6);
	// a wet highlight on the fresh blood
	float hl = (1.0 - smoothstep(0.0, 0.12, length(p - vec2(-0.16, 0.18)))) * (1.0 - dry);
	col = mix(col, vec3(1.0, 0.78, 0.76), hl * 0.6);
	col = mix(col, dried, dry);
	ALBEDO = col;
	ALPHA = shape * alpha * mix(1.0, 0.75, dry);
}

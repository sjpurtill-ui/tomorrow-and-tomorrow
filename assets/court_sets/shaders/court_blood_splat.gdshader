shader_type spatial;
// A splat of blood, cartoon-bright: a blob with a ragged rim, a few flung
// satellite drops, a wet highlight while fresh, going dark and dull as it
// dries. Laid flat on the floor (a MultiMesh: INSTANCE_CUSTOM = seed, alpha,
// dryness, splash), or stuck on someone as a small sticker (instance
// uniform `sticker`, same channels).
// Cheap per pixel: the rim's raggedness is read from a small noise texture
// (court_blood.gd makes it once), and the satellite drops are placed once
// per corner in vertex(), not per pixel.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec3 fresh : source_color = vec3(0.86, 0.04, 0.07);
uniform vec3 deep : source_color = vec3(0.55, 0.0, 0.04);
uniform vec3 dried : source_color = vec3(0.30, 0.06, 0.05);
uniform sampler2D ragged : filter_linear, repeat_enable;
instance uniform vec4 sticker = vec4(0.0);

varying vec4 v_data;
varying vec4 v_drops_a;
varying vec4 v_drops_b;
varying vec4 v_sizes;

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	v_data = sticker.g > 0.0 ? sticker : INSTANCE_CUSTOM;
	float seed = v_data.r * 97.0;
	float reach = 0.6 + 0.4 * v_data.a;
	vec2 c[4];
	for (int k = 0; k < 4; k++) {
		float fk = float(k);
		float da = hash2(vec2(seed, fk)) * 6.2832;
		float dr = (0.62 + 0.3 * hash2(vec2(fk, seed))) * reach;
		c[k] = vec2(cos(da), sin(da)) * dr;
	}
	v_drops_a = vec4(c[0], c[1]);
	v_drops_b = vec4(c[2], c[3]);
	v_sizes = vec4(hash2(vec2(0.0, seed)), hash2(vec2(3.0, seed)), hash2(vec2(6.0, seed)), hash2(vec2(9.0, seed))) * 0.05 + 0.04;
}

void fragment() {
	float seed = v_data.r;
	float alpha = v_data.g;
	float dry = v_data.b;
	float splash = v_data.a;
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	if (r > 1.05) {
		discard;
	}
	vec2 dir = p / max(r, 0.0001);
	// a ragged main blob: the rim's wobble read round a circle of the noise
	vec2 ring = dir * 0.22 + vec2(seed, seed * 1.7);
	float edge = 0.46 + 0.2 * texture(ragged, ring).r + 0.08 * texture(ragged, ring * 3.1).r;
	float blob = 1.0 - smoothstep(edge - 0.04, edge, r);
	// fingers flung out along the splash
	float fingers = step(0.72, texture(ragged, dir * 0.5 + vec2(seed * 2.3, 0.5)).r) * (1.0 - smoothstep(edge, edge + 0.32 * splash, r)) * step(edge - 0.05, r);
	// satellite drops (placed in vertex())
	float drops = max(max(1.0 - smoothstep(v_sizes.x * 0.8, v_sizes.x, length(p - v_drops_a.xy)), 1.0 - smoothstep(v_sizes.y * 0.8, v_sizes.y, length(p - v_drops_a.zw))),
		max(1.0 - smoothstep(v_sizes.z * 0.8, v_sizes.z, length(p - v_drops_b.xy)), 1.0 - smoothstep(v_sizes.w * 0.8, v_sizes.w, length(p - v_drops_b.zw))));
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

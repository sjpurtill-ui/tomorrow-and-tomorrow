// The painted face and the hair cards of the court figures (included by
// court_figure_toon.gdshader and court_figure_lit.gdshader).
// The face: the body's UV is face space, measured on a 0.282 m head from the
// chin (x across, the figure's left +; y up), UV2 is (how much the skin faces
// forward, 1 on the head and neck), written by tools/blender/court_figures.py.
// Every person's own: face_a (years 0..1, freckles 0..1, a shaved man's
// shadow of beard 0..1, their seed 0..1) and face_b (blush 0..1), set on
// their Body by court_figure_3d.gd. The paint is colour only: the lights of
// the place still shade it.

float face_ell(vec2 d, vec2 r) {
	return 1.0 - smoothstep(0.0, 1.0, length(d / r));
}

float face_seg(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

float face_hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// depth: 0 the fairest skin, 1 the deepest.
vec3 paint_face(vec3 base, vec2 F, vec2 G, vec4 fa, vec4 fb, float depth) {
	if (G.y < 0.5) {
		return base;
	}
	float front = clamp(G.x * 1.4, 0.0, 1.0);
	float ax = abs(F.x);
	float y = F.y;
	vec3 c = base;
	// fair skin has a pink undertone; deep skin keeps its own depth
	c = mix(c, c * vec3(1.05, 0.91, 0.90), (1.0 - depth) * 0.8);
	// the sockets: shade above and about the eye, deepest at the inner corner
	float sock = face_ell(vec2(ax - 0.033, y - 0.141), vec2(0.028, 0.019)) * front;
	float inner = face_ell(vec2(ax - 0.020, y - 0.139), vec2(0.010, 0.012)) * front;
	c *= mix(vec3(1.0), vec3(0.83, 0.77, 0.80), clamp(sock * 0.75 + inner * 0.55, 0.0, 1.0));
	float under = face_ell(vec2(ax - 0.036, y - 0.121), vec2(0.020, 0.008)) * front;
	c *= 1.0 - under * (0.06 + 0.12 * fa.x);
	// the brow ridge catches the light
	c *= 1.0 + face_ell(vec2(ax - 0.034, y - 0.167), vec2(0.030, 0.010)) * front * 0.05;
	// the nose: shade down its sides, the nostrils dark, shade under it
	float nside = face_ell(vec2(ax - 0.014, y - 0.112), vec2(0.006, 0.022)) * front;
	float nostril = face_ell(vec2(ax - 0.0080, y - 0.0890), vec2(0.0034, 0.0022)) * (1.0 - smoothstep(0.25, 0.65, G.x));
	float under_nose = face_ell(vec2(F.x, y - 0.082), vec2(0.011, 0.0045));
	c *= 1.0 - nside * 0.08 - under_nose * 0.06;
	c *= 1.0 - nostril * 0.38;
	// warm cheeks (most on fair skin)
	float cheek = face_ell(vec2(ax - 0.046, y - 0.098), vec2(0.026, 0.020)) * front;
	c = mix(c, c * vec3(1.06, 0.85, 0.81), cheek * (0.25 + 0.45 * fb.x) * (1.0 - 0.6 * depth));
	// the lips: their own colour, a catch of light below, the corners dark
	float upper = face_ell(vec2(F.x, y - 0.0590), vec2(0.0215, 0.0052));
	float lower = face_ell(vec2(F.x, y - 0.0485), vec2(0.0190, 0.0064));
	vec3 lip = mix(c * vec3(0.86, 0.50, 0.50), c * vec3(0.64, 0.42, 0.52), depth);
	c = mix(c, lip, clamp((upper + lower) * 1.4, 0.0, 1.0));
	c = mix(c, c * vec3(1.10, 1.04, 1.02), face_ell(vec2(F.x, y - 0.0465), vec2(0.010, 0.0024)) * 0.35);
	float corner = face_ell(vec2(ax - 0.0185, y - 0.0548), vec2(0.0032, 0.0034));
	c *= 1.0 - corner * 0.60;
	// shade under the line of the jaw and down the throat
	c *= 1.0 - smoothstep(0.012, -0.022, y) * 0.10;
	// years: the folds from nose to mouth, crow's feet, lines on the brow
	float age = fa.x;
	if (age > 0.01) {
		float fold = 1.0 - smoothstep(0.0011, 0.0032, face_seg(vec2(ax, y), vec2(0.0155, 0.0870), vec2(0.0258, 0.0512)));
		c *= 1.0 - fold * front * (0.08 + 0.22 * age);
		float crow = 0.0;
		for (int i = 0; i < 3; i++) {
			float a = -0.40 + 0.40 * float(i);
			vec2 o = vec2(0.0545, 0.1375);
			crow = max(crow, 1.0 - smoothstep(0.0006, 0.0017, face_seg(vec2(ax, y), o, o + vec2(cos(a), sin(a)) * 0.011)));
		}
		c *= 1.0 - crow * smoothstep(0.25, 1.0, age) * 0.24;
		float lines = smoothstep(0.5, 1.0, age) * front * (0.5 + 0.5 * sin(y * 1300.0)) * face_ell(vec2(F.x, y - 0.192), vec2(0.046, 0.017));
		c *= 1.0 - lines * 0.12;
	}
	// a shaved man's shadow of beard on the jaw, chin and upper lip
	if (fa.z > 0.01) {
		float area = smoothstep(0.092, 0.060, y) * smoothstep(-0.022, 0.010, y) * (1.0 - smoothstep(0.050, 0.066, ax));
		area = max(area, face_ell(vec2(F.x, y - 0.071), vec2(0.023, 0.008)));
		area *= 1.0 - clamp(upper + lower, 0.0, 1.0);
		float stub = face_hash(floor(F * 2600.0));
		// on deep skin a shadow of beard barely shows; on fair skin it greys the jaw
		c = mix(c, c * vec3(0.74, 0.76, 0.82), area * fa.z * (0.30 + 0.25 * stub) * (1.0 - 0.7 * depth));
	}
	// freckles over the nose and cheeks
	if (fa.y > 0.01) {
		vec2 cell = floor(F * 900.0);
		float h = face_hash(cell + fa.w * 97.0);
		float spot = (1.0 - smoothstep(0.18, 0.34, length(fract(F * 900.0) - 0.5))) * step(1.0 - fa.y * 0.35, h);
		float zone = face_ell(vec2(ax - 0.030, y - 0.103), vec2(0.050, 0.030)) * front;
		c *= 1.0 - spot * zone * 0.24;
	}
	// a mole of their own, now and then
	vec2 mole = vec2(mix(-0.050, 0.050, fract(fa.w * 13.7)), mix(0.030, 0.130, fract(fa.w * 7.3)));
	float m = (1.0 - smoothstep(0.0012, 0.0021, length(F - mole))) * step(0.5, fract(fa.w * 3.1));
	c *= 1.0 - m * 0.45;
	return c;
}

// A hair card: strands across it, finer toward their ends. false: no strand here.
bool card_strand(vec2 uv, float id, float n_coarse) {
	float keep = n_coarse - uv.y * 0.72 - abs(uv.x - 0.5) * 0.9 * uv.y;
	return keep > 0.10;
}

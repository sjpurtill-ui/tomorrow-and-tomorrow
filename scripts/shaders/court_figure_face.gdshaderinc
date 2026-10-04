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

// Shallow surface relief. Face UVs travel with the skin and
// expression morphs; screen derivatives provide a frame without requiring
// tangents on these untextured, skinned meshes. This adds soft lid/lip/cheek
// form without moving the skin through the eye and mouth decals.
vec3 face_normal(vec3 position, vec3 normal, vec2 F, vec2 G, float age) {
	float ax = abs(F.x);
	float relief = 0.0016 * (1.0 - 0.2 * age) * face_ell(vec2(ax - 0.043, F.y - 0.108), vec2(0.026, 0.023));
	relief += 0.00028 * face_ell(vec2(ax - 0.035, F.y - 0.123), vec2(0.023, 0.006));
	relief += 0.0010 * face_ell(vec2(ax - 0.034, F.y - 0.154), vec2(0.031, 0.012));
	relief += 0.0010 * face_ell(vec2(F.x, F.y - 0.048), vec2(0.020, 0.006));
	relief += 0.0006 * face_ell(vec2(F.x, F.y - 0.061), vec2(0.022, 0.005));
	relief -= 0.0005 * face_ell(vec2(F.x, F.y - 0.075), vec2(0.004, 0.010));
	relief -= 0.0005 * face_ell(vec2(F.x, F.y - 0.035), vec2(0.016, 0.005));
	relief *= smoothstep(0.12, 0.65, G.x) * smoothstep(0.5, 0.9, G.y);
	vec3 dx = dFdx(position);
	vec3 dy = dFdy(position);
	vec3 rx = cross(dy, normal);
	vec3 ry = cross(normal, dx);
	float det = dot(dx, rx);
	vec3 grad = sign(det) * (dFdx(relief) * rx + dFdy(relief) * ry);
	return normalize(max(abs(det), 1e-12) * normal - grad);
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
	c *= mix(vec3(1.0), vec3(0.83, 0.77, 0.80), clamp(sock * 0.45 + inner * 0.40, 0.0, 1.0));
	float under = face_ell(vec2(ax - 0.036, y - 0.121), vec2(0.020, 0.008)) * front;
	c *= 1.0 - under * (0.03 + 0.07 * fa.x);
	// the planes of the head: a lit brow and forehead, the cheekbone high,
	// the hollow under it, the temple and the side of the jaw turned away
	c *= 1.0 + face_ell(vec2(ax - 0.034, y - 0.167), vec2(0.030, 0.010)) * front * (0.06 + 0.08 * depth);
	c *= 1.0 + face_ell(vec2(ax, y - 0.205), vec2(0.050, 0.035)) * front * 0.05;
	c *= 1.0 + face_ell(vec2(ax - 0.046, y - 0.106), vec2(0.022, 0.011)) * (0.08 + 0.06 * depth);
	c *= 1.0 - face_ell(vec2(ax - 0.052, y - 0.074), vec2(0.020, 0.017)) * 0.10;
	c *= 1.0 - face_ell(vec2(ax - 0.064, y - 0.150), vec2(0.014, 0.026)) * 0.06;
	c *= 1.0 - smoothstep(0.040, 0.062, ax) * smoothstep(0.075, 0.035, y) * smoothstep(-0.01, 0.01, y) * 0.08;
	// the bridge of the nose catches the light (most on deep skin)
	c *= 1.0 + face_ell(vec2(ax, y - 0.123), vec2(0.0045, 0.024)) * front * (0.05 + 0.08 * depth);
	// the nose: shade down its sides, the nostrils dark, shade under it
	float nside = face_ell(vec2(ax - 0.014, y - 0.112), vec2(0.006, 0.022)) * front;
	float nostril = face_ell(vec2(ax - 0.0080, y - 0.0890), vec2(0.0034, 0.0022)) * (1.0 - smoothstep(0.25, 0.65, G.x));
	float under_nose = face_ell(vec2(F.x, y - 0.082), vec2(0.011, 0.0045));
	c *= 1.0 - nside * 0.08 - under_nose * 0.04;
	// the underside of the nose is a mid tone, not a hole: only the nostrils are dark
	float nose_under = face_ell(vec2(ax - 0.004, y - 0.0895), vec2(0.016, 0.006)) * (1.0 - smoothstep(0.20, 0.60, G.x));
	c *= 1.0 + nose_under * 0.18;
	c *= 1.0 - nostril * 0.38;
	// warm cheeks (most on fair skin)
	float cheek = face_ell(vec2(ax - 0.046, y - 0.098), vec2(0.026, 0.020)) * front;
	c = mix(c, c * vec3(1.06, 0.85, 0.81), cheek * (0.25 + 0.45 * fb.x) * (1.0 - 0.6 * depth));
	// the lips: their own colour, a catch of light below, the corners dark
	float upper = face_ell(vec2(F.x, y - 0.0590), vec2(0.0215, 0.0052));
	float lower = face_ell(vec2(F.x, y - 0.0485), vec2(0.0190, 0.0064));
	vec3 lip = mix(c * vec3(0.93, 0.66, 0.63), c * vec3(0.78, 0.57, 0.60), depth);
	c = mix(c, lip, clamp((upper + lower) * 1.15, 0.0, 1.0));
	c = mix(c, c * vec3(1.10, 1.04, 1.02), face_ell(vec2(F.x, y - 0.0465), vec2(0.010, 0.0024)) * (0.35 + 0.35 * depth));
	float corner = face_ell(vec2(ax - 0.0185, y - 0.0548), vec2(0.0032, 0.0034));
	c *= 1.0 - corner * 0.28;
	// shade under the line of the jaw and down the throat
	c *= 1.0 - smoothstep(0.012, -0.022, y) * 0.10;
	// years: the folds from nose to mouth, crow's feet, lines on the brow
	float age = fa.x;
	if (age > 0.01) {
		float fold = 1.0 - smoothstep(0.0011, 0.0032, face_seg(vec2(ax, y), vec2(0.0155, 0.0870), vec2(0.0258, 0.0512)));
		c *= 1.0 - fold * front * (0.035 + 0.10 * age);
		float crow = 0.0;
		for (int i = 0; i < 3; i++) {
			float a = -0.40 + 0.40 * float(i);
			vec2 o = vec2(0.0545, 0.1375);
			crow = max(crow, 1.0 - smoothstep(0.0006, 0.0017, face_seg(vec2(ax, y), o, o + vec2(cos(a), sin(a)) * 0.011)));
		}
		c *= 1.0 - crow * smoothstep(0.25, 1.0, age) * 0.14;
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
		vec2 centre = vec2(face_hash(cell + 3.7), face_hash(cell + 19.3)) * 0.5 + 0.25;
		float radius = mix(0.11, 0.27, face_hash(cell + 8.1));
		float aa = max(length(fwidth(F * 900.0)), 0.035);
		float spot = (1.0 - smoothstep(radius * 0.55, radius + aa, length(fract(F * 900.0) - centre))) * step(1.0 - fa.y * 0.24, h);
		float zone = face_ell(vec2(ax - 0.030, y - 0.103), vec2(0.050, 0.030)) * front;
		c *= 1.0 - spot * zone * 0.24;
	}
	// a mole of their own, now and then
	vec2 mole = vec2(mix(-0.050, 0.050, fract(fa.w * 13.7)), mix(0.030, 0.130, fract(fa.w * 7.3)));
	float m = (1.0 - smoothstep(0.0012, 0.0021, length(F - mole))) * step(0.5, fract(fa.w * 3.1));
	c *= 1.0 - m * 0.45;
	// All facial markings belong to the face, including lips and moles.
	// Projected coordinates alone also occur on the back of the head.
	return mix(base, c, smoothstep(0.06, 0.48, G.x));
}

// A hair card: strands across it, finer toward their ends. false: no strand here.
bool card_strand(vec2 uv, float id, float n_coarse) {
	float keep = n_coarse - uv.y * 0.72 - abs(uv.x - 0.5) * 0.9 * uv.y;
	return keep > 0.10;
}

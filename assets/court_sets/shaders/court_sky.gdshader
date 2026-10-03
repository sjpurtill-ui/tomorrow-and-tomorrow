shader_type sky;
// The sky over the court in constant daylight, painted: a warm wash at the
// horizon going to a clear blue, banks of soft clouds low over the land (where
// the court's camera sees them) with lit tops, shaded bellies and a darker
// bloom at their edges like watercolour, and a glow about the sun.
render_mode use_half_res_pass;

uniform vec3 zenith : source_color = vec3(0.42, 0.58, 0.74);
uniform vec3 top : source_color = vec3(0.55, 0.68, 0.80);
uniform vec3 horizon : source_color = vec3(0.93, 0.86, 0.70);
uniform vec3 below : source_color = vec3(0.70, 0.66, 0.54);
uniform vec3 cloud : source_color = vec3(0.99, 0.95, 0.88);
uniform vec3 cloud_shade : source_color = vec3(0.70, 0.70, 0.74);
uniform vec3 sun_glow : source_color = vec3(1.0, 0.86, 0.62);
uniform float cloud_cover = 0.5;

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash2(i), hash2(i + vec2(1, 0)), f.x), mix(hash2(i + vec2(0, 1)), hash2(i + vec2(1, 1)), f.x), f.y);
}

float fbm(vec2 p) {
	float a = 0.5;
	float s = 0.0;
	for (int i = 0; i < 5; i++) {
		s += a * noise2(p);
		p = p * 2.07 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return s;
}

float clouds(vec2 q, float el) {
	// banks low over the land, thinning higher up
	float profile = smoothstep(-0.01, 0.05, el) * (1.0 - smoothstep(0.18, 0.45, el));
	float c = fbm(q);
	return c * (0.55 + 0.6 * profile) - (1.0 - cloud_cover) * 0.55;
}

void sky() {
	float y = EYEDIR.y;
	float el = asin(clamp(y, -1.0, 1.0));
	vec3 col = mix(horizon, top, smoothstep(0.0, 0.32, el));
	col = mix(col, zenith, smoothstep(0.3, 1.1, el));
	col = mix(below, col, smoothstep(-0.08, 0.01, el));
	if (!AT_CUBEMAP_PASS && el > -0.02) {
		float az = atan(EYEDIR.x, EYEDIR.z);
		vec2 q = vec2(az * 2.4, el * 9.0) + vec2(TIME * 0.002, 0.0);
		float c = clouds(q, el);
		float c_up = clouds(q + vec2(0.0, 0.18), el + 0.02);
		float body = smoothstep(0.26, 0.34, c);
		float rim = smoothstep(0.26, 0.29, c) - smoothstep(0.29, 0.36, c);
		float lit = clamp((c - c_up) * 4.0 + 0.5, 0.0, 1.0);
		vec3 cc = mix(cloud_shade, cloud, lit);
		cc = mix(cc, horizon, smoothstep(0.05, -0.01, el) * 0.5);
		col = mix(col, cc, body * 0.92);
		col = mix(col, cloud_shade * 0.82, rim * 0.35);
	}
	if (LIGHT0_ENABLED) {
		float s = max(dot(EYEDIR, LIGHT0_DIRECTION), 0.0);
		col += sun_glow * (pow(s, 32.0) * 0.4 + pow(s, 5.0) * 0.1);
	}
	COLOR = col;
}

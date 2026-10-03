shader_type sky;
// The sky over the court in constant daylight: a painted wash from a warm
// horizon to a deeper blue, broad soft clouds, the glow about the sun.
render_mode use_half_res_pass;

uniform vec3 top : source_color = vec3(0.47, 0.60, 0.72);
uniform vec3 horizon : source_color = vec3(0.86, 0.84, 0.76);
uniform vec3 below : source_color = vec3(0.62, 0.58, 0.48);
uniform vec3 cloud : source_color = vec3(0.97, 0.94, 0.88);
uniform vec3 cloud_shade : source_color = vec3(0.72, 0.74, 0.78);
uniform vec3 sun_glow : source_color = vec3(1.0, 0.90, 0.70);
uniform float cloud_cover = 0.45;

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
	for (int i = 0; i < 4; i++) {
		s += a * noise2(p);
		p = p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return s;
}

void sky() {
	float y = EYEDIR.y;
	vec3 col = mix(horizon, top, smoothstep(0.0, 0.55, y));
	col = mix(below, col, smoothstep(-0.12, 0.02, y));
	if (!AT_CUBEMAP_PASS && y > 0.0) {
		vec2 uv = EYEDIR.xz / (y + 0.18) * 1.2;
		float c = fbm(uv * 1.1 + vec2(TIME * 0.004, 0.0));
		float cl = smoothstep(1.0 - cloud_cover, 1.0 - cloud_cover + 0.25, c) * smoothstep(0.0, 0.18, y);
		float shade = smoothstep(0.4, 0.9, fbm(uv * 2.3 + 4.0));
		col = mix(col, mix(cloud, cloud_shade, shade * 0.6), cl * 0.85);
	}
	if (LIGHT0_ENABLED) {
		float s = max(dot(EYEDIR, LIGHT0_DIRECTION), 0.0);
		col += sun_glow * pow(s, 24.0) * 0.35 + sun_glow * pow(s, 4.0) * 0.08;
	}
	COLOR = col;
}

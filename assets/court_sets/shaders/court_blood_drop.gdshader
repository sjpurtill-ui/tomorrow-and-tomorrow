shader_type spatial;
// A flying drop of blood (one particle): a bright round-headed teardrop, its
// tail streaming back along its flight (the particle's Y follows its
// velocity), a glint on its head.
// Alpha-tested and depth-writing, so the stage's ink outlines it like everything else.
render_mode unshaded, depth_draw_opaque, cull_disabled, shadows_disabled, fog_disabled;

uniform vec3 fresh : source_color = vec3(0.9, 0.05, 0.08);
uniform vec3 deep : source_color = vec3(0.58, 0.0, 0.04);
// the quad's width over its height
uniform float aspect = 0.62;

varying vec4 v_colour;

void vertex() {
	v_colour = COLOR;
}

void fragment() {
	// q: the quad in units of its half-height, head (the way it flies) at -y
	vec2 p = (UV - 0.5) * 2.0;
	vec2 q = vec2(p.x * aspect, p.y);
	float r = aspect * 0.92;
	vec2 head = vec2(0.0, -1.0 + r + 0.02);
	float in_head = 1.0 - smoothstep(r - 0.05, r, length(q - head));
	float t = clamp((q.y - head.y) / (1.0 - head.y), 0.0, 1.0);
	float half_w = r * pow(1.0 - t, 1.4);
	float in_tail = step(head.y, q.y) * (1.0 - smoothstep(half_w - 0.04, half_w, abs(q.x)));
	float body = max(in_head, in_tail);
	if (body < 0.02) {
		discard;
	}
	vec3 col = mix(fresh, deep, smoothstep(0.0, 1.0, t) * 0.7 + smoothstep(r * 0.4, r, length(q - head)) * 0.3);
	float hl = 1.0 - smoothstep(0.0, r * 0.38, length(q - head - vec2(-r * 0.35, -r * 0.3)));
	col = mix(col, vec3(1.0, 0.86, 0.84), hl * 0.8);
	ALBEDO = col;
	ALPHA = body * v_colour.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}

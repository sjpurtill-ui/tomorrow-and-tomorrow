shader_type spatial;
// The geyser's jet: one ribbon along the arc a squirt of blood flies (worked
// out here from its launch velocity and gravity), turned to face the camera,
// thick and bright, pulsing with blobs that run up it with the heartbeat,
// breaking into gobbets toward its far end. `reach` grows it out of the neck,
// `tail` lets it go at the end. Drawn only while it squirts.
// Alpha-tested and depth-writing, so the stage's ink outlines it like everything else.
render_mode unshaded, depth_draw_opaque, cull_disabled, shadows_disabled, fog_disabled;

uniform vec3 fresh : source_color = vec3(0.92, 0.05, 0.08);
uniform vec3 deep : source_color = vec3(0.56, 0.0, 0.04);
uniform vec3 velocity = vec3(0.0, 5.0, 1.5);
uniform float gravity = 9.8;
uniform float flight = 1.1;
uniform float width = 0.05;
uniform float reach = 1.0;
uniform float tail = 0.0;
uniform float beat = 3.0;

varying float v_t;

void vertex() {
	float t = UV.y;
	float s = t * flight;
	vec3 at = velocity * s + vec3(0.0, -0.5 * gravity * s * s, 0.0);
	vec3 along = normalize(velocity + vec3(0.0, -gravity * s, 0.0));
	vec3 eye = (inverse(MODEL_MATRIX) * vec4(INV_VIEW_MATRIX[3].xyz, 1.0)).xyz;
	vec3 side = normalize(cross(along, eye - at));
	// thick out of the neck, fanning a little as it rises, thinning as it falls
	float w = width * (0.9 + 0.7 * smoothstep(0.0, 0.5, t) - 0.5 * smoothstep(0.6, 1.0, t));
	VERTEX = at + side * (UV.x - 0.5) * 2.0 * w;
	v_t = t;
}

float hash1(float x) {
	return fract(sin(x * 127.1) * 43758.5453);
}

float noise1(float x) {
	float i = floor(x);
	float f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(hash1(i), hash1(i + 1.0), f);
}

void fragment() {
	float t = v_t;
	if (t > reach || t < tail) {
		discard;
	}
	float across = abs(UV.x - 0.5) * 2.0;
	// blobs pumping up the jet with the heart
	float run = t * 9.0 - TIME * beat * 2.2;
	float swell = 0.72 + 0.28 * sin(run * 6.2832 / 2.2);
	// toward the end it comes apart into gobbets
	float gaps = smoothstep(0.55, 0.95, t) * step(0.55, noise1(t * 26.0 - TIME * beat * 3.0));
	float edge = swell * (1.0 - 0.25 * noise1(t * 40.0 + TIME * 7.0));
	float body = (1.0 - smoothstep(edge - 0.12, edge, across)) * (1.0 - gaps);
	// a soft cap at the head of the growing jet
	body *= 1.0 - smoothstep(reach - 0.03, reach, t) * step(reach, 0.999);
	if (body < 0.02) {
		discard;
	}
	vec3 col = mix(fresh, deep, smoothstep(0.2, 1.0, across) * 0.8);
	// a wet streak of light down its middle
	col = mix(col, vec3(1.0, 0.82, 0.8), (1.0 - smoothstep(0.0, 0.22, abs(UV.x - 0.38))) * 0.55 * swell);
	ALBEDO = col;
	ALPHA = body;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}

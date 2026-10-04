shader_type spatial;
// The ink line round a court figure: the back faces pushed out along the
// normal by a fixed number of screen pixels, drawn in iron-gall ink.
// Used as the next pass of court_figure_toon.gdshader materials.
render_mode unshaded, cull_front, depth_draw_opaque;

uniform vec3 ink : source_color = vec3(0.165, 0.133, 0.090);
uniform float width_px = 1.7;
uniform int cover_channel = 0;
uniform float stipple = 0.0;
uniform bool skin = false;

varying float v_cover;
varying float v_edge;
varying vec2 v_rest;
varying vec2 v_face;
varying float v_head;

float hash3(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.1, 0.2, 0.3));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise3(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash3(i), hash3(i + vec3(1, 0, 0)), f.x), mix(hash3(i + vec3(0, 1, 0)), hash3(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(hash3(i + vec3(0, 0, 1)), hash3(i + vec3(1, 0, 1)), f.x), mix(hash3(i + vec3(0, 1, 1)), hash3(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

void vertex() {
	v_edge = COLOR.g;
	v_rest = UV;
	v_face = vec2(UV.x, 1.0 - UV.y);
	v_head = 1.0 - UV2.y;
	v_cover = cover_channel == 1 ? COLOR.g : (cover_channel == 2 ? COLOR.b : (cover_channel == 3 ? COLOR.a : 0.0));
	vec3 view_position = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec4 clip = PROJECTION_MATRIX * vec4(view_position, 1.0);
	vec3 nv = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec2 nc = (PROJECTION_MATRIX * vec4(nv, 0.0)).xy;
	float l = length(nc);
	if (l > 1e-5) {
		clip.xy += nc / l * width_px * 2.0 / VIEWPORT_SIZE * clip.w;
	}
	// Keep the ink behind the painted surface at concave folds. XY-only
	// expansion otherwise pulls back faces over the chest and collar.
	// clip.w supports perspective and orthographic cameras; abs handles
	// render targets whose projection flips the vertical axis.
	float pixel_size = 2.0 * clip.w / (VIEWPORT_SIZE.y * abs(PROJECTION_MATRIX[1][1]));
	view_position.z -= width_px * pixel_size;
	vec4 recessed = PROJECTION_MATRIX * vec4(view_position, 1.0);
	clip.z = recessed.z / recessed.w * clip.w;
	POSITION = clip;
}

void fragment() {
	if (v_cover > 0.5) {
		discard;
	}
	if (skin && v_head > 0.5 && abs(v_face.x) < 0.055 && v_face.y > 0.065 && v_face.y < 0.165) {
		discard;
	}
	// no ink round the strokes where hair thins out over the skin
	if (stipple > 0.0 && v_edge > 0.05) {
		discard;
	}
	ALBEDO = ink;
}

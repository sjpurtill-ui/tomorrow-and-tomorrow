shader_type spatial;
// The ink line round a merged court figure (court_figure_uber.gdshader): the
// back faces pushed out a few pixels, only for the slots that are inked
// (inked: bit n for slot n; hair, cards, beards, brows, the eyes and mouth
// are not), and never where an outfit hides the skin.
render_mode unshaded, cull_front, depth_draw_opaque;

uniform vec3 ink : source_color = vec3(0.165, 0.133, 0.090);
uniform float width_px = 1.7;
uniform int cover_channel = 0;
uniform int inked = 0;

varying flat int v_slot;
varying float v_cover;
varying vec2 v_face;
varying float v_head;

void vertex() {
	v_slot = int(CUSTOM0.r + 0.5);
	v_face = vec2(UV.x, 1.0 - UV.y);
	v_head = 1.0 - UV2.y;
	v_cover = 0.0;
	if (v_slot == 0) {
		v_cover = cover_channel == 1 ? COLOR.g : (cover_channel == 2 ? COLOR.b : (cover_channel == 3 ? COLOR.a : 0.0));
	}
	vec3 view_position = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec4 clip = PROJECTION_MATRIX * vec4(view_position, 1.0);
	vec3 nv = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec2 nc = (PROJECTION_MATRIX * vec4(nv, 0.0)).xy;
	float l = length(nc);
	// Fine facial contours: a full garment-width outline turns small
	// concavities beside the nose into black slits at conversation distance.
	float width = width_px * (v_slot == 0 && UV2.y < 0.5 ? 0.42 : 1.0);
	if (l > 1e-5) {
		clip.xy += nc / l * width * 2.0 / VIEWPORT_SIZE * clip.w;
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
	if (v_cover > 0.5 || ((inked >> v_slot) & 1) == 0) {
		discard;
	}
	// The nose is lit geometry. An expanded inverted hull draws black
	// seams across its alar folds and bridge, even inside the face.
	if (v_slot == 0 && v_head > 0.5 && abs(v_face.x) < 0.055 && v_face.y > 0.065 && v_face.y < 0.165) {
		discard;
	}
	ALBEDO = ink;
}

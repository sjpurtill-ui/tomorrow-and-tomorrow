extends RefCounted
## MAP LIFE IN INK (codex/beauty-2): people, birds, herds and boats drawn by
## hand, the way an illustrated chart shows life on the land.
##
## Every representative is one camera-facing quad whose fragment shader draws
## the creature from signed-distance shapes: a wash of colour inside a fine
## iron-gall ink line held at about one screen pixel, and a soft cool shadow
## where it stands. Poses are animated in the shader from one clock (walking
## legs, swinging axes, wingbeats, grazing heads, paddle strokes), so the CPU
## cost is the same few uniform writes as before. Each figure keeps a minimum
## size on screen (bounded, never a giant) so it reads at its zoom.
## Procedural only: no image assets. Bounded counts stay with the callers
## (living_map.gd, map_ambience.gd, rite_marks.gd).

const QUAD_EXTENT:=Vector2(1.0,1.0)

static var _quad:QuadMesh
static var _materials:Dictionary={}

## The shared quad every sprite draws on (the shader places its corners).
static func quad()->QuadMesh:
	if _quad==null:
		_quad=QuadMesh.new()
		_quad.size=QUAD_EXTENT
	return _quad

## One material per kind: "person", "bird", "beast" or "boat".
static func material(kind:String)->ShaderMaterial:
	if _materials.has(kind) and is_instance_valid(_materials[kind]):return _materials[kind]
	var shader:=Shader.new()
	shader.code=shader_code(kind)
	var m:=ShaderMaterial.new()
	m.shader=shader
	_materials[kind]=m
	return m

static func shader_code(kind:String)->String:
	match kind:
		"person":return HEAD+PERSON
		"bird":return HEAD+BIRD
		"beast":return HEAD+BEAST
		"boat":return HEAD+BOAT
	return HEAD+PERSON

## Shared header: the billboard, the minimum on-screen size, and the ink.
## A kind supplies figure_box() (the drawing's extent in figure metres),
## place() (where its feet stand, in model space, and which way it faces)
## and draw() (the picture).
const HEAD:="""
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, skip_vertex_transform, fog_disabled;
uniform float anim_clock = 0.0;
uniform float clock = 0.0;
// Figure metres per model unit (the caller's instance scale is read too).
uniform float figure_unit = 0.0;
// The figure is never drawn smaller than this many pixels tall, nor more
// than max_swell times its true size.
uniform float min_px = 10.0;
uniform float max_swell = 3.0;
uniform float legibility = 1.0;
const vec3 INK = vec3(0.16, 0.12, 0.085);
const vec3 SHADE = vec3(0.10, 0.12, 0.16);
varying vec2 v_p;
varying vec4 v_custom;
varying vec3 v_color;
varying float v_flip;
varying float v_time;

vec2 rot2(vec2 v, float a) { float c = cos(a); float s = sin(a); return vec2(c*v.x-s*v.y, s*v.x+c*v.y); }
float sd_seg(vec2 p, vec2 a, vec2 b, float r) {
	vec2 pa = p-a; vec2 ba = b-a;
	float h = clamp(dot(pa, ba)/max(dot(ba, ba), 1e-6), 0.0, 1.0);
	return length(pa-ba*h)-r;
}
float sd_seg2(vec2 p, vec2 a, vec2 b, float ra, float rb) {
	vec2 pa = p-a; vec2 ba = b-a;
	float h = clamp(dot(pa, ba)/max(dot(ba, ba), 1e-6), 0.0, 1.0);
	return length(pa-ba*h)-mix(ra, rb, h);
}
float sd_circle(vec2 p, vec2 c, float r) { return length(p-c)-r; }
float sd_ellipse(vec2 p, vec2 c, vec2 r) {
	vec2 q = (p-c)/r;
	return (length(q)-1.0)*min(r.x, r.y);
}
// Paint one shape over the picture: a wash inside a fine ink line (about a
// pixel wide at any size), anti-aliased. `px` figure metres per pixel.
void ink_layer(inout vec4 acc, float d, vec3 fill, float px) {
	float outer = 1.0-smoothstep(-0.5*px, 0.5*px, d-0.55*px);
	if (outer <= 0.0) { return; }
	float inner = 1.0-smoothstep(-0.5*px, 0.5*px, d+0.25*px);
	vec3 c = mix(INK, fill, inner);
	acc.rgb = mix(acc.rgb, c, outer);
	acc.a = outer+acc.a*(1.0-outer);
}
// A line of ink only (tools, paddles, wing strokes).
void ink_line(inout vec4 acc, float d, float px) {
	float a = 1.0-smoothstep(-0.5*px, 0.5*px, d-0.5*px);
	acc.rgb = mix(acc.rgb, INK, a);
	acc.a = a+acc.a*(1.0-a);
}
// A soft cool shadow on the ground under the feet.
void ground_shadow(inout vec4 acc, vec2 p, vec2 c, vec2 r, float strength) {
	float e = length((p-c)/r);
	float a = (1.0-smoothstep(0.35, 1.0, e))*strength;
	acc.rgb = mix(acc.rgb, SHADE, a);
	acc.a = a+acc.a*(1.0-a);
}
"""

## People at work: a side view in a tunic, the pose chosen by the caller
## (INSTANCE_CUSTOM: phase, pose (+100 still), carrying, pace), facing the
## way they walk. The same codes as living_map.gd's POSES.
const PERSON:="""
void vertex() {
	vec4 feet = MODELVIEW_MATRIX*vec4(0.0, 0.0, 0.0, 1.0);
	float scale = length(MODEL_MATRIX[0].xyz);
	vec3 facing = normalize((MODEL_MATRIX*vec4(0.0, 0.0, -1.0, 0.0)).xyz+vec3(1e-6));
	v_flip = dot(facing, INV_VIEW_MATRIX[0].xyz) >= 0.0 ? 1.0 : -1.0;
	float px_world = 2.0*max(-feet.z, 0.001)/(PROJECTION_MATRIX[1][1]*VIEWPORT_SIZE.y);
	// Children (INSTANCE_CUSTOM.z of 2) keep a smaller least size than adults.
	float child = step(1.5, INSTANCE_CUSTOM.z);
	float swell = clamp(min_px*(1.0-0.34*child)*px_world/(1.8*scale), 1.0, max_swell);
	float s = scale*swell;
	v_p = vec2(mix(-1.15, 1.15, UV.x), mix(2.15, -0.40, UV.y));
	// Stand the drawing a little toward the eye, by its own height: seen from
	// high above, a swelled figure lies almost along the ground and the land
	// behind its feet would otherwise swallow it (codex/beauty-3).
	vec3 at = feet.xyz+normalize(-feet.xyz)*(0.0004+s*2.4);
	VERTEX = at+vec3(v_p.x*s, v_p.y*s, 0.0);
	NORMAL = vec3(0.0, 0.0, 1.0);
	v_custom = INSTANCE_CUSTOM;
	v_color = COLOR.rgb;
	v_time = anim_clock*max(INSTANCE_CUSTOM.w, 0.2)+INSTANCE_CUSTOM.x*6.2831;
}
void fragment() {
	vec2 p = vec2(v_p.x*v_flip, v_p.y);
	float px = max(fwidth(v_p.y), 1e-5);
	float code = v_custom.y;
	float still = code > 99.5 ? 1.0 : 0.0;
	float pose = floor(mod(code, 100.0)+0.5);
	float child = step(1.5, v_custom.z);
	float carry = v_custom.z*(1.0-child);
	float t = v_time;
	float stride = 0.0; float arm_b = 0.0; float arm_f = 0.0; float bend = 0.0;
	float crouch = 0.0; float bob = 0.0; float tool_len = 0.0;
	vec2 tool_dir = vec2(0.0, 1.0);
	bool swing_tool = false;
	if (pose < 0.5 || pose == 6.0) {
		float w = pose == 6.0 ? 0.55 : 1.0;
		float s = sin(t*7.0)*(1.0-still);
		stride = 0.30*w*s; arm_b = 0.45*w*s; arm_f = -arm_b;
		bob = 0.04*abs(cos(t*7.0))*(1.0-still);
		if (pose == 6.0) { bend = -0.30-0.15*still; arm_b = 0.25+0.2*still; arm_f = arm_b; }
		if (carry > 0.5) { arm_b = 0.95; arm_f = 0.95; }
	} else if (pose == 1.0) {
		bend = -0.95+0.12*sin(t*1.7);
		arm_b = 1.15+0.35*sin(t*3.1); arm_f = 1.0+0.35*sin(t*3.1+1.9);
	} else if (pose == 2.0) {
		float s = sin(t*5.0);
		bend = -0.22; arm_f = 1.5+1.3*max(s, -0.4); arm_b = 1.2+0.9*max(s, -0.4); tool_len = 0.75; swing_tool = true;
	} else if (pose == 3.0) {
		bend = -0.06; arm_b = 1.0; arm_f = 1.1+0.06*sin(t*1.3); tool_len = 2.6;
		tool_dir = normalize(vec2(0.85, 0.55));
	} else if (pose == 4.0) {
		crouch = 1.0; bend = -0.30; arm_b = 1.0+0.25*sin(t*1.1); arm_f = 0.9+0.25*sin(t*1.4+1.0);
	} else if (pose == 5.0) {
		arm_f = 0.4+0.6*max(0.0, sin(t*1.3)); bend = 0.03*sin(t*0.7);
	} else if (pose == 7.0) {
		arm_f = 0.35; tool_len = 2.0; tool_dir = vec2(0.0, 1.0);
	} else {
		crouch = 1.0; bend = -0.45; arm_f = 1.2+0.7*max(sin(t*6.0), -0.3); arm_b = 1.0; tool_len = 0.35; swing_tool = true;
	}
	float drop = crouch*0.30;
	vec2 hip = vec2(0.0, 0.90-drop+bob);
	vec2 up = rot2(vec2(0.0, 1.0), bend);
	vec2 shoulder = hip+up*0.50;
	vec2 head = shoulder+up*0.27;
	// Legs: hip, knee, foot. Walking swings the feet; crouching folds the knees.
	vec2 foot_f = vec2(stride+crouch*0.18, 0.0);
	vec2 foot_b = vec2(-stride+crouch*0.02, 0.0);
	vec2 knee_f = mix(hip, foot_f, 0.5)+vec2(0.05+crouch*0.30, crouch*0.05);
	vec2 knee_b = mix(hip, foot_b, 0.5)+vec2(0.03+crouch*0.24, crouch*0.02);
	vec2 hand_b = shoulder+rot2(rot2(vec2(0.0, -0.52), arm_b), bend);
	vec2 hand_f = shoulder+rot2(rot2(vec2(0.0, -0.52), arm_f), bend);
	vec3 skin = vec3(0.62, 0.46, 0.34);
	vec3 legs = vec3(0.40, 0.33, 0.25);
	// Undyed hide and wool read light against the grass, like a painted figure.
	vec3 cloth = min(v_color*1.28, vec3(1.0));
	// Lit from the upper left, as the land is: a touch warmer high up.
	cloth *= 0.92+0.16*smoothstep(0.8, 1.5, p.y);
	vec4 acc = vec4(0.0);
	ground_shadow(acc, p, vec2(0.10, 0.0), vec2(0.62, 0.13), 0.30);
	ink_layer(acc, min(sd_seg(p, hip, knee_b, 0.085), sd_seg(p, knee_b, foot_b, 0.075)), legs*0.85, px);
	ink_layer(acc, sd_seg(p, shoulder, hand_b, 0.075), cloth*0.82, px);
	if (carry > 0.5) { ink_layer(acc, sd_circle(p, shoulder+up*(-0.08)+vec2(-0.26, 0.0), 0.24), vec3(0.55, 0.45, 0.29), px); }
	ink_layer(acc, min(sd_seg(p, hip, knee_f, 0.09), sd_seg(p, knee_f, foot_f, 0.08)), legs, px);
	// Tunic: a tapered body, wider at the hem.
	float body = sd_seg2(p, hip-up*0.12, shoulder, 0.22, 0.16);
	ink_layer(acc, body, cloth, px);
	// A child's head is larger for its body.
	float head_r = 0.14*(1.0+0.28*child);
	ink_layer(acc, sd_circle(p, head, head_r), skin, px);
	// Hair or a hood, on the back of the head.
	ink_layer(acc, sd_circle(p, head+vec2(-0.05, 0.05)*(1.0+0.28*child), 0.105*(1.0+0.28*child)), vec3(0.24, 0.19, 0.14), px);
	ink_layer(acc, sd_seg(p, shoulder, hand_f, 0.075), cloth*0.95, px);
	if (tool_len > 0.0) {
		vec2 dir = swing_tool ? rot2(rot2(vec2(1.0, 0.0), arm_f), bend) : tool_dir;
		vec2 tip = hand_f+dir*tool_len;
		ink_line(acc, sd_seg(p, hand_f, tip, 0.028), px);
		if (swing_tool) { ink_layer(acc, sd_circle(p, tip, 0.07), vec3(0.42, 0.40, 0.37), px); }
	}
	if (acc.a < 0.01) { discard; }
	ALBEDO = acc.rgb;
	ALPHA = acc.a;
}
"""

## Birds wheeling in loose circles, flapping and gliding: two ink wing
## strokes over a pale wash (gulls over water, rooks over the woods).
const BIRD:="""
void vertex() {
	vec4 r = INSTANCE_CUSTOM;
	float radius = 0.05*r.y;
	float t = clock*0.23*r.z+r.x*6.2831;
	vec3 at = vec3(cos(t)*radius, 0.0, sin(t)*radius*0.72);
	at.x += sin(t*2.3+r.w*9.0)*radius*0.16;
	at.y += sin(t*1.7+r.w*5.0)*0.004;
	vec4 center = MODELVIEW_MATRIX*vec4(at, 1.0);
	float px_world = 2.0*max(-center.z, 0.001)/(PROJECTION_MATRIX[1][1]*VIEWPORT_SIZE.y);
	// A wingspan of about 1.4 m, never under min_px pixels across.
	float s = 0.0007*clamp(min_px*px_world/0.0014, 1.0, max_swell*2.0);
	v_p = vec2(mix(-1.25, 1.25, UV.x), mix(0.95, -0.75, UV.y));
	VERTEX = center.xyz+vec3(v_p.x*s, v_p.y*s, 0.0);
	NORMAL = vec3(0.0, 0.0, 1.0);
	v_custom = r;
	v_color = COLOR.rgb;
	// Flap in bursts, then glide.
	float burst = step(0.1, sin(clock*0.9+r.w*11.0));
	v_time = sin(clock*16.0+r.w*40.0)*burst;
	v_flip = burst;
}
void fragment() {
	vec2 p = v_p;
	float px = max(fwidth(v_p.y), 1e-5);
	float flap = v_time;
	vec2 elbow = vec2(0.42, 0.10+0.22*flap);
	vec2 tip = vec2(1.05, -0.05+0.55*flap+0.18*(1.0-v_flip));
	vec2 q = vec2(abs(p.x), p.y);
	float wing = min(sd_seg2(q, vec2(0.0, -0.02), elbow, 0.10, 0.08), sd_seg2(q, elbow, tip, 0.08, 0.02));
	float body = sd_ellipse(p, vec2(0.0, -0.04), vec2(0.10, 0.20));
	vec4 acc = vec4(0.0);
	ink_layer(acc, min(wing, body), v_color, px);
	if (acc.a < 0.01) { discard; }
	ALBEDO = acc.rgb;
	ALPHA = acc.a;
}
"""

## A grazing herd: heads down most of the time, drifting slowly over the
## ground, legs stepping when an animal walks on (INSTANCE_CUSTOM.xy phase).
const BEAST:="""
void vertex() {
	vec4 r = INSTANCE_CUSTOM;
	float t = clock*0.06+r.x*6.2831;
	vec2 path = vec2(sin(t)+0.4*sin(t*2.7+r.y*7.0), cos(t*0.8+r.y*3.0))*0.006;
	vec2 step_dir = vec2(cos(t)+1.08*cos(t*2.7+r.y*7.0), -0.8*sin(t*0.8+r.y*3.0));
	float walking = smoothstep(0.35, 0.8, sin(clock*0.21+r.y*12.0));
	vec3 local = vec3(path.x, 0.0, path.y)*mix(0.35, 1.0, walking);
	vec4 feet = MODELVIEW_MATRIX*vec4(local, 1.0);
	vec3 heading = normalize((MODEL_MATRIX*vec4(step_dir.x, 0.0, step_dir.y, 0.0)).xyz+vec3(1e-6));
	v_flip = dot(heading, INV_VIEW_MATRIX[0].xyz) >= 0.0 ? 1.0 : -1.0;
	float px_world = 2.0*max(-feet.z, 0.001)/(PROJECTION_MATRIX[1][1]*VIEWPORT_SIZE.y);
	float scale = 0.0016;
	float s = scale*clamp(min_px*px_world/(2.2*scale), 1.0, max_swell);
	v_p = vec2(mix(-1.45, 1.55, UV.x), mix(1.85, -0.35, UV.y));
	vec3 at = feet.xyz+normalize(-feet.xyz)*(0.0004+s*2.0);
	VERTEX = at+vec3(v_p.x*s, v_p.y*s, 0.0);
	NORMAL = vec3(0.0, 0.0, 1.0);
	v_custom = vec4(r.xy, walking, 0.0);
	v_color = COLOR.rgb;
	v_time = clock;
}
void fragment() {
	vec2 p = vec2(v_p.x*v_flip, v_p.y);
	float px = max(fwidth(v_p.y), 1e-5);
	float walking = v_custom.z;
	float c = v_time;
	float graze = (1.0-walking)*(0.9+0.1*sin(c*2.2+v_custom.x*30.0));
	float swing = sin(c*6.0+v_custom.x*20.0)*0.22*walking;
	vec2 withers = vec2(0.46, 1.12);
	vec2 head = mix(vec2(0.98, 1.38), vec2(0.86, 0.26), graze);
	vec3 coat = v_color;
	vec3 far_coat = coat*0.78;
	vec4 acc = vec4(0.0);
	ground_shadow(acc, p, vec2(0.05, 0.0), vec2(1.05, 0.16), 0.30);
	// Far legs, then the body, then the near legs, neck and head.
	ink_layer(acc, min(sd_seg(p, vec2(0.42, 0.95), vec2(0.42-swing, 0.0), 0.06), sd_seg(p, vec2(-0.40, 0.95), vec2(-0.40+swing, 0.0), 0.06)), far_coat, px);
	ink_layer(acc, sd_seg(p, vec2(-0.62, 1.02), vec2(-0.74, 0.62), 0.035), far_coat, px);
	float body = sd_ellipse(p, vec2(0.0, 1.02), vec2(0.64, 0.27));
	ink_layer(acc, body, coat*(0.94+0.14*smoothstep(0.9, 1.25, p.y)), px);
	ink_layer(acc, min(sd_seg(p, vec2(0.34, 0.95), vec2(0.34+swing, 0.0), 0.065), sd_seg(p, vec2(-0.48, 0.95), vec2(-0.48-swing, 0.0), 0.065)), coat*0.9, px);
	ink_layer(acc, sd_seg2(p, withers, head, 0.15, 0.10), coat, px);
	ink_layer(acc, sd_ellipse(p, head+vec2(0.08, -0.02), vec2(0.18, 0.11)), coat*0.92, px);
	if (acc.a < 0.01) { discard; }
	ALBEDO = acc.rgb;
	ALPHA = acc.a;
}
"""

## Dugouts working the water: a gentle bob, one paddler's stroke, and a few
## pale ripples at the waterline. Working slowly along the channel and back.
const BOAT:="""
void vertex() {
	vec4 r = INSTANCE_CUSTOM;
	float t = clock*0.05+r.x*6.2831;
	float along = sin(t)*0.018;
	vec3 local = vec3(0.0, sin(clock*1.2+r.x*11.0)*0.0002, along);
	vec4 center = MODELVIEW_MATRIX*vec4(local, 1.0);
	// Bow toward +Z; it faces the way it is going along the channel.
	vec3 heading = normalize((MODEL_MATRIX*vec4(0.0, 0.0, cos(t) >= 0.0 ? 1.0 : -1.0, 0.0)).xyz+vec3(1e-6));
	v_flip = dot(heading, INV_VIEW_MATRIX[0].xyz) >= 0.0 ? 1.0 : -1.0;
	float px_world = 2.0*max(-center.z, 0.001)/(PROJECTION_MATRIX[1][1]*VIEWPORT_SIZE.y);
	float scale = 0.0016;
	float s = scale*clamp(min_px*px_world/(4.4*scale), 1.0, max_swell);
	v_p = vec2(mix(-2.8, 2.8, UV.x), mix(1.75, -0.55, UV.y));
	vec3 at = center.xyz+normalize(-center.xyz)*(0.0004+s*1.5);
	VERTEX = at+vec3(v_p.x*s, v_p.y*s, 0.0);
	NORMAL = vec3(0.0, 0.0, 1.0);
	v_custom = r;
	v_color = COLOR.rgb;
	v_time = clock;
}
void fragment() {
	vec2 p = vec2(v_p.x*v_flip, v_p.y);
	float px = max(fwidth(v_p.y), 1e-5);
	float c = v_time;
	float roll = sin(c*1.7+v_custom.y*9.0)*0.05;
	p = rot2(p, -roll);
	vec4 acc = vec4(0.0);
	// Ripples: short pale strokes along the waterline, drifting astern.
	float drift = fract(c*0.35+v_custom.x);
	for (int k = 0; k < 3; k++) {
		float x0 = -2.6-float(k)*0.55-drift*0.5;
		float ripple = sd_seg(p, vec2(x0, -0.06-0.05*float(k)), vec2(x0+0.45, -0.06-0.05*float(k)), 0.02);
		float a = (1.0-smoothstep(-0.5*px, 0.5*px, ripple-0.4*px))*(0.55-0.15*float(k));
		acc.rgb = mix(acc.rgb, vec3(0.80, 0.82, 0.76), a); acc.a = a+acc.a*(1.0-a);
	}
	float stroke = sin(c*2.6+v_custom.y*4.0);
	vec2 hands = vec2(-0.25, 0.78);
	vec2 blade = hands+rot2(vec2(0.0, -1.35), stroke*0.55-0.25);
	vec3 cloth = vec3(0.52, 0.40, 0.30);
	// Paddler: a seated body and head above the gunwale.
	ink_layer(acc, sd_seg2(p, vec2(-0.55, 0.28), vec2(-0.48, 0.86), 0.20, 0.15), cloth, px);
	ink_layer(acc, sd_circle(p, vec2(-0.44, 1.06), 0.14), vec3(0.62, 0.46, 0.34), px);
	ink_line(acc, sd_seg(p, hands+vec2(0.0, 0.25), blade, 0.03), px);
	ink_layer(acc, sd_ellipse(p, blade, vec2(0.07, 0.16)), vec3(0.36, 0.27, 0.18), px);
	// The hull: a log hollowed out, bow and stern turned up a little.
	float hull = sd_seg2(p, vec2(-2.05, 0.20), vec2(2.05, 0.16), 0.24, 0.20);
	hull = max(hull, p.y-0.34-0.10*smoothstep(1.4, 2.1, abs(p.x)));
	ink_layer(acc, hull, v_color*(0.9+0.2*smoothstep(0.0, 0.3, p.y)), px);
	if (acc.a < 0.01) { discard; }
	ALBEDO = acc.rgb;
	ALPHA = acc.a;
}
"""

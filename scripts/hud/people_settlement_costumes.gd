extends RefCounted
## Private People-view garments. The map's material and visibility policy stay
## unchanged. Shared billboard placement, work poses and tool animation are reused.
## These are bounded illustrations of known methods, not individual issued stock.
## No date, population size, building tier or research-in-progress unlocks attire.
const Ink = preload("res://scripts/map_life_ink.gd")
const HIDE_PALETTE: Array[Color] = [Color("967651"), Color("796047"), Color("b49b73"), Color("69523e"), Color("aa8860")]
const WOVEN_PALETTE: Array[Color] = [Color("c3b38c"), Color("a5936e"), Color("8b795e"), Color("d0c3a2"), Color("75634d")]
const RELEVANT := ["cordage", "fiber_grading", "bone_needle_sewing", "plain_weaving", "garment_pattern_cutting", "layered_clothing_design"]
const PEOPLE_ATLAS := "res://assets/ui/people/settlement-people-v1.png"
const ATLAS_COLUMNS := 6
const ATLAS_ROWS := 4
static var _atlas_texture: Texture2D

## `known` is the actual known_discoveries ledger (IDs). Optional context may
## contain an already-read adoption map and household goods coverage. Without
## measured coverage everyone retains basic wraps; knowledge is only a ceiling.
## Do not pass discovery_log: a record of a question is not acquired knowledge.
static func appearance(known: Array, recorded: Dictionary = {}) -> Dictionary:
	var methods: Dictionary = {}
	var evidence: Array[String] = []
	var adoption: Dictionary = recorded.get("adoption", {}) if recorded.get("adoption", {}) is Dictionary else {}
	for id: String in RELEVANT:
		if id not in known: continue
		var spread := float(adoption.get(id, 0.0))
		if recorded.has("adoption") and (not is_finite(spread) or spread < 0.1): continue
		methods[id] = true
		evidence.append(id)
	var sewn: bool = methods.has("bone_needle_sewing")
	var woven: bool = methods.has("plain_weaving")
	var fitted: bool = woven and sewn and methods.has("garment_pattern_cutting")
	var stage := 3 if fitted else (2 if woven else (1 if sewn else 0))
	var supplied := clampf(float(recorded.get("coverage", 0.0)), 0.0, 1.0)
	if not is_finite(supplied): supplied = 0.0
	var palette := WOVEN_PALETTE.duplicate() if woven else HIDE_PALETTE.duplicate()
	var uniforms := {"garment_stage": float(stage), "garment_supply": supplied,
		"garment_tied": methods.has("cordage"), "garment_sewn": sewn, "garment_layers": methods.has("layered_clothing_design"),
		"garment_light": palette[3] if woven else palette[0], "garment_dark": palette[4] if woven else palette[3]}
	return {"style": ["hide and fiber wraps", "joined hide wraps", "woven drapes", "cut woven tunics"][stage],
		"evidence": evidence, "palette": palette, "uniforms": uniforms, "key": hash([evidence, uniforms])}

## Only the painting between the shared pose calculation and tool strokes is
## replaced. The shared source remains untouched, including children/carrying,
## crouching, walking, gathering, chopping, fishing, learning and watch poses.
static func shader_code() -> String:
	var paint_start := Ink.PERSON.find("\tvec3 skin =")
	var tools_start := Ink.PERSON.find("\tif (tool_len > 0.0) {")
	assert(paint_start >= 0 and tools_start > paint_start, "Shared People pose boundary changed")
	return Ink.HEAD + GARMENT_HELPERS + Ink.PERSON.substr(0, paint_start) + GARMENT_PAINT + Ink.PERSON.substr(tools_start)

## The private illustrated view opts into this shader. The original map and
## procedural fallback remain unchanged. A complete cell keeps all poses on the
## same foot baseline; cropping each pose separately would stretch a crouch.
static func atlas_texture() -> Texture2D:
	if _atlas_texture != null: return _atlas_texture
	if not FileAccess.file_exists(PEOPLE_ATLAS): return null
	var source := Image.load_from_file(PEOPLE_ATLAS)
	if source == null or source.is_empty(): return null
	if source.get_width() % ATLAS_COLUMNS != 0 or source.get_height() % ATLAS_ROWS != 0: return null
	_atlas_texture = ImageTexture.create_from_image(source)
	return _atlas_texture

static func atlas_layout() -> PackedVector4Array:
	var texture := atlas_texture()
	var frames := PackedVector4Array()
	if texture == null: return frames
	var dimensions := Vector2(texture.get_width(), texture.get_height())
	var cell := dimensions / Vector2(ATLAS_COLUMNS, ATLAS_ROWS)
	for row in ATLAS_ROWS:
		for column in ATLAS_COLUMNS:
			# Sample texel centres to prevent neighbouring cells bleeding through
			# minified alpha edges. Transparent RGB is never drawn as a backdrop.
			var origin := (Vector2(column, row) * cell + Vector2.ONE * .5) / dimensions
			var extent := (cell - Vector2.ONE) / dimensions
			frames.append(Vector4(origin.x, origin.y, extent.x, extent.y))
	return frames

static func painterly_shader_code() -> String:
	var fragment := Ink.PERSON.find("void fragment()")
	assert(fragment > 0, "Shared People vertex boundary changed")
	return Ink.HEAD.replace("depth_draw_never", "depth_prepass_alpha") + GARMENT_HELPERS + PAINTERLY_UNIFORMS + Ink.PERSON.substr(0, fragment) + PAINTERLY_PAINT

const PAINTERLY_UNIFORMS := """
uniform sampler2D people_atlas : source_color, filter_linear, repeat_disable;
uniform vec4 people_frames[24];
"""

const PAINTERLY_PAINT := """
void fragment() {
    if (!map_people_visible) { discard; }
    vec2 p = vec2(v_p.x*v_flip, v_p.y);
    float pose = floor(mod(v_custom.y,100.0)+0.5);
    bool still = v_custom.y > 99.5;
    bool child = v_custom.z > 1.5;
    bool carrying = v_custom.z > 0.5 && !child;
    // The same stable per-person supply sample as the wrap shader: knowing a
    // method never outfits everybody, and missing issue records keep row zero.
    float sample_id = fract(v_custom.x*11.971+0.07);
    int row = sample_id < garment_supply ? int(clamp(garment_stage,0.0,3.0)+0.5) : 0;
    int frame = 0;
    bool walking = (pose < 0.5 || pose == 6.0) && !still;
    if (carrying) { frame = 3; }
    else if (walking) { frame = 1 + int(mod(floor(v_time*2.2),2.0)); }
    else if (pose == 4.0 || pose >= 8.0) { frame = 5; }
    else if (pose == 1.0 || pose == 2.0 || pose == 3.0) { frame = 4; }
    // Small local motion keeps a carried load or working posture alive while
    // all route positions, pace and representative counts remain caller-owned.
    float bob = walking ? abs(sin(v_time*6.9))*0.018 : 0.0;
    p.y -= bob;
    if (frame == 4 || frame == 5) {
        p.x -= sin(v_time*2.4)*0.018*smoothstep(0.2,1.3,p.y);
    }
    vec2 local_uv = vec2(p.x/1.85+0.5,1.0-p.y/1.85);
    vec4 paint = vec4(0.0);
    if (all(greaterThanEqual(local_uv,vec2(0.0))) && all(lessThanEqual(local_uv,vec2(1.0)))) {
        vec4 region = people_frames[row*6+frame];
        paint = texture(people_atlas,region.xy+local_uv*region.zw);
        // Carrying has one upper-body painting. Reuse the matching attire's
        // walking legs below the knee so a moving carrier does not glide.
        if (carrying && walking && local_uv.y > 0.70) {
            int stride_frame = 1 + int(mod(floor(v_time*2.2),2.0));
            vec4 stride_region = people_frames[row*6+stride_frame];
            vec4 stride_paint = texture(people_atlas,stride_region.xy+local_uv*stride_region.zw);
            paint = mix(paint,stride_paint,smoothstep(0.70,0.73,local_uv.y));
        }
    }
    // Keep the original role's simple tools visible; the atlas contains no
    // invented equipment. Warm wood/stone strokes fit the painted figures.
    float tool = 0.0;
    vec3 tool_color = vec3(0.34,0.25,0.15);
    float px = max(fwidth(v_p.y),0.003);
    if (!carrying && pose == 7.0) {
        tool = 1.0-smoothstep(0.018,0.018+px,sd_seg(p,vec2(0.32,0.03),vec2(0.32,1.72),0.0));
    } else if (!carrying && pose == 3.0) {
        tool = 1.0-smoothstep(0.013,0.013+px,sd_seg(p,vec2(0.29,0.77),vec2(1.08,1.40),0.0));
    } else if (!carrying && (pose == 2.0 || pose >= 8.0)) {
        vec2 hand = pose == 2.0 ? vec2(0.30,0.77) : vec2(0.48,0.07);
        vec2 tip = hand+rot2(vec2(0.0,pose == 2.0 ? 0.43 : 0.20),sin(v_time*4.0)*0.35);
        tool = 1.0-smoothstep(0.015,0.015+px,sd_seg(p,hand,tip,0.0));
    }
    float variation = mix(0.94,1.04,fract(v_custom.x*17.731+0.21));
    vec3 color = paint.rgb*variation;
    if (tool > paint.a) { color = tool_color; }
    float alpha = max(paint.a,tool);
    if (alpha < 0.03) { discard; }
    ALBEDO = color;
    ALPHA = alpha;
    ALPHA_SCISSOR_THRESHOLD = 0.03;
}
"""

const GARMENT_HELPERS := """
uniform float garment_stage = 0.0;
uniform float garment_supply = 1.0;
uniform bool garment_tied = false;
uniform bool garment_sewn = false;
uniform bool garment_layers = false;
uniform vec4 garment_light : source_color = vec4(0.59, 0.46, 0.32, 1.0);
uniform vec4 garment_dark : source_color = vec4(0.41, 0.32, 0.24, 1.0);

float cloth_side(vec2 a, vec2 b, vec2 p) {
    vec2 edge = b-a; vec2 q = p-a;
    return edge.x*q.y-edge.y*q.x;
}
// Clockwise convex cloth outline: an angular drape, not a rounded shirt body.
float cloth_panel(vec2 p, vec2 a, vec2 b, vec2 c, vec2 d, vec2 e) {
    float edge = min(min(sd_seg(p,a,b,0.0),sd_seg(p,b,c,0.0)),
        min(sd_seg(p,c,d,0.0),min(sd_seg(p,d,e,0.0),sd_seg(p,e,a,0.0))));
    float side = max(max(cloth_side(a,b,p),cloth_side(b,c,p)),
        max(cloth_side(c,d,p),max(cloth_side(d,e,p),cloth_side(e,a,p))));
    return side <= 0.0 ? -edge : edge;
}
"""

const GARMENT_PAINT := """
    float variation = fract(v_custom.x*17.731+0.21);
    float supplied = step(fract(v_custom.x*11.971+0.07), garment_supply);
    float stage = garment_stage*supplied;
    bool woven = stage >= 1.5;
    bool fitted = stage >= 2.5;
    // Natural skin variation is independent of discovery and occupation.
    vec3 skin = mix(vec3(0.43,0.29,0.20),vec3(0.69,0.51,0.36),fract(v_custom.x*7.317+0.31));
    vec3 hide = mix(vec3(0.44,0.33,0.22),vec3(0.68,0.54,0.36),variation);
    vec3 cloth = woven ? mix(garment_dark.rgb,garment_light.rgb,variation) : hide;
    vec3 hair = mix(vec3(0.15,0.11,0.075),vec3(0.28,0.20,0.12),variation);
    vec2 q = rot2(p-hip,-bend);
    // Irregular lower edges and diagonal folds keep the early silhouette a
    // shoulder wrap; even later tunics cover the upper legs instead of pants.
    float hem = -0.32-0.09*variation;
    float rough = woven ? 0.0 : sin(q.x*41.0+variation*13.0)*0.012;
    vec2 cloth_p = q+vec2(0.0,rough);
    float cloth_shape = cloth_panel(cloth_p,vec2(-0.18,0.55),
        vec2(fitted ? 0.18 : 0.05,fitted ? 0.55 : 0.45),vec2(0.20,0.16),
        vec2(0.29,hem),vec2(-0.29,hem+(fitted ? 0.0 : 0.14)));
    vec4 acc = vec4(0.0);
    ground_shadow(acc,p,vec2(0.10,0.0),vec2(0.62,0.13),0.30);
    // Bare lower legs and forearms are visible. The footwrap stops at the
    // ankle; there is no full brown leg capsule that reads as trousers.
    ink_layer(acc,min(sd_seg(p,hip,knee_b,0.080),sd_seg(p,knee_b,foot_b,0.066)),skin*0.78,px);
    ink_layer(acc,sd_seg2(p,foot_b+vec2(-0.02,0.07),foot_b+vec2(0.085,0.005),0.07,0.08),hide*0.68,px);
    ink_layer(acc,sd_seg(p,shoulder,hand_b,0.065),skin*0.83,px);
    if (garment_layers && supplied > 0.5) {
        float cape = cloth_panel(q,vec2(-0.20,0.55),vec2(0.02,0.50),vec2(0.09,0.14),vec2(-0.27,-0.19),vec2(-0.36,-0.08));
        ink_layer(acc,cape,cloth*0.76,px);
    }
    ink_layer(acc,sd_seg(p,shoulder,mix(shoulder,hand_b,0.27),0.10),cloth*0.80,px);
    if (carry > 0.5) { ink_layer(acc,sd_circle(p,shoulder+up*(-0.08)+vec2(-0.26,0.0),0.24),vec3(0.51,0.40,0.25),px); }
    ink_layer(acc,min(sd_seg(p,hip,knee_f,0.085),sd_seg(p,knee_f,foot_f,0.071)),skin,px);
    ink_layer(acc,sd_seg2(p,foot_f+vec2(-0.02,0.07),foot_f+vec2(0.10,0.005),0.075,0.085),hide*0.76,px);
    ink_layer(acc,sd_seg(p,shoulder+up*0.06,head,0.060),skin,px);
    float fold = smoothstep(-0.10,0.10,q.x+q.y*0.28);
    ink_layer(acc,cloth_shape,cloth*(0.87+0.15*fold),px);
    // One diagonal overlap is visible on the wrap. A narrow cord is only
    // drawn after the actual binding method is known.
    if (cloth_shape < -px) {
        ink_layer(acc,sd_seg(q,vec2(-0.11,0.48),vec2(0.13,hem+0.08),0.008),cloth*0.69,px*0.65);
        if (garment_tied) { ink_layer(acc,sd_seg(q,vec2(-0.24,0.02),vec2(0.24,0.00),0.015),hide*0.61,px*0.65); }
        if (garment_sewn && supplied > 0.5) {
            float stitch = step(0.54,fract((q.y-hem)*17.0));
            if (stitch > 0.5) { ink_layer(acc,sd_seg(q,vec2(-0.20,hem+0.06),vec2(-0.14,0.35),0.006),cloth*0.58,px*0.55); }
        }
    }
    float head_r = 0.14*(1.0+0.28*child);
    ink_layer(acc,sd_circle(p,head,head_r),skin,px);
    ink_layer(acc,sd_circle(p,head+vec2(-0.05,0.05)*(1.0+0.28*child),0.105*(1.0+0.28*child)),hair,px);
    ink_layer(acc,sd_seg(p,shoulder,hand_f,0.065),skin,px);
    // The near shoulder is bare in the earliest wrap. Woven/structured
    // garments have a short draped sleeve, never a modern cuffed shirt.
    if (woven) { ink_layer(acc,sd_seg(p,shoulder,mix(shoulder,hand_f,fitted ? 0.34 : 0.21),0.096),cloth*0.93,px); }
"""

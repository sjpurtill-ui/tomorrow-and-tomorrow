extends RefCounted
## Private People-view garments. The map's material and visibility policy stay
## unchanged. Shared billboard placement, work poses and tool animation are reused.
## These are bounded illustrations of known methods, not individual issued stock.
## No date, population size, building tier or research-in-progress unlocks attire.
const Ink = preload("res://scripts/map_life_ink.gd")
const HIDE_PALETTE: Array[Color] = [Color("967651"), Color("796047"), Color("b49b73"), Color("69523e"), Color("aa8860")]
const WOVEN_PALETTE: Array[Color] = [Color("c3b38c"), Color("a5936e"), Color("8b795e"), Color("d0c3a2"), Color("75634d")]
const RELEVANT := ["cordage", "fiber_grading", "bone_needle_sewing", "plain_weaving", "garment_pattern_cutting", "layered_clothing_design"]

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

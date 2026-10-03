extends SkeletonModifier3D
## Court acting (K): how each person of the court moves, looks and speaks.
##
## The figure (court_figure_3d.gd, J) plays its stance clip on its own
## AnimationPlayer: that is the base. This modifier runs after it on the
## same skeleton and adds, every frame, without allocating:
##  - a reaction layer: clips from the shared library (gasp, flinch, laugh,
##    bows, kneel, defiant, talking gestures...; made in Blender by
##    tools/blender/court_anims.py, one armature-only .glb a body in
##    assets/court_figures/anims/ and their face curves in court_anims.json)
##    sampled and blended over the stance with eased weights per part of the
##    body, so a sitter keeps their seat, a staff-holder keeps their staff,
##    and a new reaction crossfades from the last;
##  - life: breathing at their own rate, a weight shift every so often, a
##    slow sway, blinks every 2-6 s (and on a big turn of the head), idle
##    glances that never stare out at the viewer, trembling at high dread;
##  - looking: head, neck and chest turn toward a point or a person on a
##    springy, slightly overshooting curve, inside human limits;
##  - mood: joy, fear, anger, scorn, awe and tiredness in the face (mood
##    morphs, brows, lids) and the set of the body, eased, never popped;
##  - speech: the mouth opens and shapes from the words' syllables, the head
##    beats on stressed words, the hands take a gesture now and then.
## Presentation only: nothing here reads or changes the game's state. The
## director (court_director.gd, L) decides who reacts and how; this is the
## vocabulary and the performance.
##
## Use (static, on a CourtFigure3D; preload this script as Acting):
##   Acting.play(fig, "gasp", {blend, loop, speed, hold, out, at})  -> seconds
##   Acting.look_toward(fig, Vector3 | figure Node3D | null, weight)   (look_at on the hook)
##   Acting.set_mood(fig, {joy, fear, anger, scorn, awe, tired} | "warm"...)
##   Acting.speak(fig, text, seconds)
##   Acting.idle(fig, stance_id, {seat})   the figure's own stances, or cord,
##       bundle, guard (on the staff), log (seated; seat: the mark's height), fire
##   Acting.gesture(fig, one of GESTURES, or any clip)
##   Acting.hush(fig, true)    the god speaks: stillness
##   Acting.stop(fig)          let go of a held reaction
##   Acting.exit_plan(style) -> [{clip, seconds, move, face}]   how to leave the hall
##   Acting.service()   the object for CourtStage.acting: play(body, act, args),
##       set_mood(body, vector) (a passing beat), mood(body, args), look_at,
##       speak, gesture, idle, hush, stop; the director's acts (ACT_MAP) become
##       clips, gestures or faces here, sided by where args.at stands
## A planted staff stays planted (its hand is held by IK under the breathing),
## and a reaction that moves the head has the head: idle glances wait.
## Figure axes (skeleton space): +X the figure's left, +Y up, +Z its front.

const Self:=preload("res://scripts/hud/court_acting.gd")
const DIR:="res://assets/court_figures/anims/"
const MANIFEST_PATH:=DIR+"court_anims.json"
enum {CH_JAW,CH_SMILE,CH_TIGHT,CH_WORRY,CH_STERN,CH_BROWS,CH_LIDS,CH_PUFF,CH_SNEER,CH_EYES_X,CH_EYES_Y,CH_FROWN,CH_COUNT}
const CHANNELS:=["jaw","smile","tight","worry","stern","brows","lids","puff","sneer","eyes_x","eyes_y","frown"]
const FACE_REST:=[0.0,0.0,0.0,0.0,0.0,0.0,1.0,0.0,0.0,0.0,0.0,0.0]
enum {M_JOY,M_FEAR,M_ANGER,M_SCORN,M_AWE,M_TIRED,M_COUNT}
const MOODS:=["joy","fear","anger","scorn","awe","tired"]
## The figure's own mood words (court_figure_3d.gd MOODS) as ours.
const FIGURE_MOODS:={"warm":{"joy":0.55},"neutral":{},"afraid":{"fear":0.7},"defiant":{"anger":0.5,"scorn":0.3},"grieved":{"tired":0.45,"fear":0.2}}
const SEATED:=["sit","crouch"]
## The arms a held prop keeps busy (they do not drop the bowl to gasp).
const PROP_ARMS:={"staff":["arm_R"],"bowl":["arm_L","arm_R"]}
const GESTURES:=["nod","nod_eager","shake","tilt","shrug","double_take","jolt","settle","flinch_small","gulp","tremble","freeze","straighten","shift",
	"nod_slow","look_round","deflate","lean_in","nod_proud","jerk_head","nod_on"]
const GESTURE_LEN:=[0.65,1.35,1.25,1.7,1.5,1.3,0.8,1.6,0.7,0.7,1.6,0.9,0.9,0.2,
	1.8,1.6,2.0,1.6,1.4,0.7,2.2]
## The director's acts (court_director.gd ACTS) as this layer performs them:
## [kind, name, amount]. kind: "clip" (a library clip; a name ending "_" takes
## _l or _r from where args.at stands), "gesture" (procedural, on top of
## anything), "look" or "face" (only the look and face the beat carries).
## Anything else falls back to the figure's own clip the beat names.
const ACT_MAP:={
	"kneel":["clip","kneel"],"kneel_bound":["clip","kneel_bound"],"prostrate":["clip","kneel"],
	"bow":["clip","bow_deep"],"bow_deep":["clip","bow_overdeep"],"bow_small":["clip","bow_shallow",1.0,"speed"],"bow_early":["clip","bow_shallow",1.0,"speed"],
	"double_bow":["clip","bow_shallow",1.0,"speed"],"copy":["clip","bow_shallow",1.0,"speed"],"plead":["clip","talk_plead"],
	"stand_firm":["clip","defiant"],"cross_arms":["clip","defiant"],"stiffen":["gesture","straighten"],"straighten":["gesture","straighten"],
	"recover":["gesture","straighten"],"gulp":["gesture","gulp"],"exhale":["gesture","settle"],"pretend_calm":["gesture","settle",0.6],
	"freeze":["gesture","freeze"],"flinch":["clip","flinch"],"knees_knock":["clip","knees_knock"],"tremble":["gesture","tremble"],
	"step_back":["clip","step_back"],"gasp":["clip","gasp"],"hand_to_mouth":["clip","gasp"],"nod":["gesture","nod"],
	"shake_head":["gesture","shake"],"side_eye":["clip","side_eye_"],"exchange_look":["gesture","tilt",0.6],"stifle_laugh":["clip","laugh_stifled"],
	"elbow":["clip","elbow_"],"wobble":["clip","wobble"],"double_take":["gesture","double_take"],"hide_behind":["clip","hide_behind_"],
	"peek_out":["clip","peek_out_"],"faint":["clip","faint_"],"half_catch":["clip","half_catch_"],"drop_bowl":["clip","drop_bowl"],
	"doze":["clip","doze"],"jerk_awake":["clip","jerk_awake"],"yawn":["clip","yawn"],"snap_alert":["clip","snap_alert"],
	"hesitate":["gesture","tilt",0.7],"sympathetic_look":["gesture","tilt",0.5],"face_fall":["gesture","settle",1.2],"bolt":["clip","bolt_"],
	"shrug":["gesture","shrug",0.55],"struggle_bundle":["clip","struggle_bundle"],"set_down_bundle":["clip","set_down_bundle"],
	"lift_bundle":["clip","lift_bundle"],"scratch":["clip","scratch_head"],"fidget":["gesture","settle",0.7],"shift_weight":["gesture","shift"],
	"glance_up":["gesture","flinch_small",0.4],"laugh":["clip","laugh"],"look_up":["look",""],"hold_gaze":["look",""],"look_at":["look",""],
	"look_away":["look",""],"watch_go":["look",""],"look_wrong_way":["look",""],"late_lift":["look",""],"glance_door":["look",""],
	"eye_food":["look",""],"beam":["face",""],"smile_warm":["face",""],"smirk":["face",""],"grimace":["face",""],"eyes_narrow":["face",""],
	"lips_pressed":["face",""],"stricken":["face",""],"head_down":["face",""],"lean_in":["face",""],"mutter":["face",""],"lick_lips":["face",""],
	"laugh_polite":["clip","laugh_polite"],"chuckle":["clip","laugh_polite"],"cough":["clip","cough"],"cover_mouth":["clip","cough"],
	"keep_apart":["clip","keep_apart_"],"edge_away":["clip","keep_apart_"],"rub_belly":["clip","rub_belly"],"pat_belly":["clip","pat_belly"],
	"sharpen_spear":["clip","sharpen_spear"],"rub_hands":["clip","rub_hands"],"stamp_feet":["clip","stamp_feet"],"swat_fly":["clip","swat_fly"],
	"stretch":["clip","stretch"],"whisper":["clip","whisper_"],"wring_hands":["clip","wring_hands"],"shush":["clip","shush_"],
	"fan_self":["clip","fan_self"],"bored":["clip","stance_guard"],"stand_guard":["gesture","straighten"],"hurry":["gesture","jolt",0.6],
	# round 3: the rest of the director's words
	"cover_eyes":["clip","cover_eyes_"],"make_room":["clip","make_room_"],"grab":["clip","grab_"],"count_fingers":["clip","count_fingers"],
	"point":["clip","point_"],"point_up":["clip","point_up"],"raise_finger":["clip","raise_finger"],"lower_finger":["clip","lower_finger"],
	"nod_along":["gesture","nod_slow"],"soft_clap":["clip","clap_soft"],"clap_soft":["clip","clap_soft"],"edge_forward":["clip","edge_forward"],
	"check_room":["gesture","look_round"],"shoo":["clip","shoo_"],"tug_sleeve":["clip","tug_sleeve_"],"over_thank":["clip","over_thank"],
	"deflate_polite":["gesture","deflate"],"nod_too_much":["gesture","nod_on"],"clear_throat":["clip","clear_throat"],
	"smooth_clothes":["clip","smooth_clothes"],"catch_eye":["gesture","lean_in"],"sit_down":["clip","sit_floor"],"doze_off":["clip","doze"],
	"glum":["gesture","deflate",0.7],"enter_wrong":["gesture","look_round"],"hurry_round":["gesture","jolt",0.6],"gape":["face",""],
	"wave":["clip","wave"],"nudge":["clip","elbow_"],"gawk":["face",""],"wipe_hands":["clip","wipe_hands"],"bow_wrong":["clip","bow_deep"],
	"mortified":["clip","mortified"],"nod_proud":["gesture","nod_proud"],"count_heads":["clip","count_heads"],"study_posts":["clip","stroke_chin"],
	"turn_stone":["clip","fiddle"],"study_roof":["clip","thumb_measure"],"work_knot":["clip","fiddle"],"eye_stores":["face",""],
	"watch_guards":["face",""],"watch_god":["face",""],"line_up":["clip","arrange_floor"],"tend_hurt":["gesture","tilt",0.6],
	"back_out_bowing":["clip","back_out"],"bump_post":["clip","bump_post"],"bow_to_post":["clip","bow_shallow"],"storm_off":["clip","storm_walk"],
	"stop_short":["clip","storm_stop"],"come_back":["clip","storm_walk"],"come_back_for":["clip","storm_walk"],"hurry_after":["gesture","jolt",0.6],
	"snore":["clip","doze"],"snatch_up":["clip","snatch_up"],"jerk_head":["gesture","jerk_head"],"sniff_disdain":["clip","sniff_disdain"],
	"brush_sleeve":["clip","brush_sleeve"],"bow_curt":["clip","bow_shallow",1.0,"speed"],"startle":["gesture","jolt"],"appraise":["clip","stroke_chin"],
	"rub_hands_greedy":["clip","rub_hands_greedy"],"stare_down":["gesture","straighten"],"blink_first":["face",""],"breath":["gesture","settle",0.6],
	"swat_miss":["clip","swat_fly"],"scribble":["clip","scribble"],"shake_hand":["clip","shake_hand"],"scratch_out":["clip","scribble"],
	"stomach_growl":["clip","rub_belly"],"floor_creak":["gesture","freeze"],"swallow_loud":["gesture","gulp"],"stifle_cough":["clip","stifle_cough"],
	"bubble":["face",""],"giggle":["clip","laugh_stifled"],
	# round 4: a child's words (anyone can take them; a child does them its own way)
	"shushed":["gesture","freeze"],"run_to":["clip","run"],"cling":["clip","hide_behind_"],"sit_cross":["clip","sit_cross"],
	# executions: the room's business (the acts themselves are in EXEC_PLANS)
	"wipe_face":["clip","room_wipe_face"],"vomit":["clip","room_vomit"],"cover_eyes_peek":["clip","room_cover_eyes_peek"],
	"applaud_alone":["clip","room_applaud_alone"],"flinch_splash":["clip","room_flinch_splash"],"wince_crunch":["clip","room_wince_crunch"],
}
## A child does the same words its own way (J's child body; only its library
## has these clips): hides behind a grown-up's legs and peeks, copies the bow
## badly, fidgets, waves at the god with both arms, giggles into its hands,
## freezes stiff when shushed, runs to a parent and clings, sits cross-legged.
const CHILD_ACTS:={"copy":["clip","child_copy_bow"],"bow_wrong":["clip","child_copy_bow"],"bow_early":["clip","child_copy_bow"],
	"fidget":["clip","child_fidget"],"freeze":["clip","child_shushed"],"shushed":["clip","child_shushed"],
	"stifle_laugh":["clip","child_giggle"],"giggle":["clip","child_giggle"],"laugh":["clip","child_giggle"],
	"run_to":["clip","child_run"],"cling":["clip","child_cling_"],"sit_down":["clip","sit_cross"],"wave":["clip","child_wave"],
	"hide_behind":["clip","child_hide_behind_"],"peek_out":["clip","child_peek_out_"],"cover_eyes_peek":["clip","child_cover_eyes_peek"]}
## And any clip asked for by name: a child's own version where it has one.
const CHILD_CLIPS:={"hide_behind_l":"child_hide_behind_l","hide_behind_r":"child_hide_behind_r","peek_out_l":"child_peek_out_l",
	"peek_out_r":"child_peek_out_r","wave":"child_wave","laugh_stifled":"child_giggle","run":"child_run","sit_floor":"sit_cross",
	"room_cover_eyes_peek":"child_cover_eyes_peek"}
## Executions (court_night/EXECUTIONS.md): cartoon slapstick, timed to the
## frame. Each act is a plan the director stages: its roles (a clip each, all
## starting at the act's 0), where each stands and faces in the victim's frame
## (x the victim's left, z the victim's front, toward the god; metres for a
## 1.72 m victim: scale by the victim's height), the props a hand holds (drive
## them with hold()), the fixed things (block, pot) the clips are built round,
## the body parts that fly or roll (part_at() moves them; J's pre-split parts:
## origin at the part's middle, +Z its face's front, +Y up), and the room's
## cues: when the hall should flinch, wipe, be sick, applaud. The clips' own
## events (cue signal) carry the same moments for blood (M), sound (N) and the
## split body (J). The engine has already put the person to death; this only
## shows it, and never on a child.
const EXEC_PLANS:={
	"club_home_run":{"length":8.6,"needs":[],
		"roles":{
			"victim":{"clip":"exec_club_victim","at":[0.0,0.0,0.0],"yaw":0.0,"kneels":true},
			"executioner":{"clip":"exec_club_batter","at":[-0.20,0.0,-0.95],"yaw":0.0,"props":{"R":"club"}},
			"cook":{"clip":"exec_cook_lid","at":[3.4,0.0,0.3],"yaw":0.0,"props":{"R":"ladle","L":"lid"}}},
		"things":{"pot":{"at":[3.4,0.0,0.82],"rim":0.55},"lid":{"at":[3.74,0.0,0.6],"on_floor":true}},
		"parts":[{"part":"head","of":"victim","t0":3.62,"t1":5.0,"kind":"arc","to":"pot","apex":2.4,"spins":2.5,"then":"in_pot"}],
		"cues":[{"t":0.0,"cue":"hush"},{"t":0.45,"cue":"tap"},{"t":0.95,"cue":"tap"},{"t":1.6,"cue":"call_shot"},{"t":3.25,"cue":"held_breath"},
			{"t":3.62,"cue":"impact"},{"t":5.0,"cue":"plop"},{"t":6.0,"cue":"thud"},{"t":7.6,"cue":"lid"},{"t":8.0,"cue":"after"}],
		"room":{"call_shot":["look_at:pot"],"impact":["flinch_splash","gasp","faint_"],"plop":["look_at:pot"],"after":["applaud_alone","vomit","cover_eyes_peek","gulp"]}},
	"three_swing_beheading":{"length":11.6,"needs":["bronze"],
		"roles":{
			"victim":{"clip":"exec_block_victim","at":[0.0,0.0,0.0],"yaw":0.0,"kneels":true},
			"executioner":{"clip":"exec_axe_headsman","at":[0.70,0.0,0.36],"yaw":-90.0,"props":{"R":"axe"}}},
		"things":{"block":{"at":[0.0,0.0,0.41],"top":0.575}},
		"parts":[{"part":"head","of":"victim","t0":8.7,"t1":10.1,"kind":"roll","to":[0.0,0.0,1.9],"face":"god","then":"blink","blink_t":10.9}],
		"cues":[{"t":0.0,"cue":"hush"},{"t":1.95,"cue":"thunk"},{"t":3.4,"cue":"free"},{"t":5.5,"cue":"clang"},{"t":6.75,"cue":"glare"},
			{"t":8.7,"cue":"impact"},{"t":8.75,"cue":"splash"},{"t":10.9,"cue":"head_blink"},{"t":11.0,"cue":"after"}],
		"room":{"thunk":["flinch_small"],"clang":["wince"],"impact":["flinch_splash","faint_"],"splash":["wipe_face"],"head_blink":["double_take"],
			"after":["applaud_alone","vomit","cover_eyes_peek","gulp"]}},
	"dog_dinner":{"length":12.0,"needs":["dogs"],
		"roles":{
			"victim":{"clips":[{"clip":"exec_dog_down","t":0.0},{"clip":"exec_dog_claw","t":1.2,"move":[0.0,0.0,-0.9],"until":2.2},
				{"clip":"exec_dog_grip","t":2.2},{"clip":"exec_dog_claw","t":5.0,"move":[0.0,0.0,-0.9],"until":6.6}],"at":[0.0,0.0,0.0],"yaw":0.0}},
		"things":{"grip":{"at":[0.0,0.1,1.12],"note":"what the hands clamp on at 2.2 s: a post's foot, the hearth stone, or nothing"}},
		"parts":[],
		"cues":[{"t":0.0,"cue":"grab"},{"t":0.6,"cue":"thud"},{"t":2.95,"cue":"tug"},{"t":3.8,"cue":"slip"},{"t":4.35,"cue":"wave_goodbye"},
			{"t":6.6,"cue":"out_of_sight"},{"t":7.0,"cue":"crunch"},{"t":7.6,"cue":"crunch"},{"t":8.2,"cue":"crunch"},{"t":10.6,"cue":"bone_dropped"},{"t":11.0,"cue":"after"}],
		"room":{"grab":["gasp"],"out_of_sight":["look_at:windbreak"],"crunch":["wince_crunch"],"bone_dropped":["look_at:bone","look_at:god"],
			"after":["applaud_alone","vomit","gulp"]}},
}
## The beats in a clip for the stage (time order): court_anims.json "events".
static func events(clip:String)->Array:
	if _events.has(clip):return _events[clip]
	var out:Array=(clip_meta(clip).get("events",[]) as Array).duplicate()
	out.sort_custom(func(x,y):return float(x.get("t",0.0))<float(y.get("t",0.0)))
	_events[clip]=out
	return out
static var _events:Dictionary={}

## One execution's plan (EXEC_PLANS), or {}.
static func exec_plan(act:String)->Dictionary:
	return EXEC_PLANS.get(act,{})

## Where a flying or rolling part is at act time t: "arc" from `from` to `to`
## over the plan's t0..t1, as high as `apex` metres, turning over `spins`
## times; "roll" along the floor from `from` to `to`, bumping, and coming to
## rest upright with its face toward `face` (a direction). Presentation only.
static func part_at(spec:Dictionary,from:Vector3,to:Vector3,t:float,face:=Vector3.FORWARD)->Transform3D:
	var t0:=float(spec.get("t0",0.0));var t1:=float(spec.get("t1",t0+1.0))
	var u:=clampf((t-t0)/maxf(t1-t0,0.01),0.0,1.0)
	var travel:=Vector3(to.x-from.x,0.0,to.z-from.z)
	var side:=travel.cross(Vector3.UP).normalized() if travel.length()>0.01 else Vector3.RIGHT
	if String(spec.get("kind","arc"))=="roll":
		var e:=1.0-pow(1.0-u,2.2)
		var pos:=from.lerp(to,e)
		pos.y+=absf(sin(e*PI*3.0))*0.10*(1.0-e)*(1.0 if u<1.0 else 0.0)
		var turns:=maxf(1.0,roundf(travel.length()/(TAU*0.11)))
		var rolled:=Basis(side,-turns*TAU*e)
		var rest:=Basis.looking_at(-face.normalized() if face.length()>0.01 else Vector3.FORWARD,Vector3.UP)
		var settle:=smoothstep(0.82,1.0,u)
		return Transform3D(Basis(rolled.get_rotation_quaternion().slerp(rest.get_rotation_quaternion(),settle)),pos)
	var apex:=float(spec.get("apex",2.0))
	var mid_y:=lerpf(from.y,to.y,0.5)
	var h:=maxf(apex-mid_y,0.0)
	var p:=from.lerp(to,u)
	p.y+=4.0*h*u*(1.0-u)
	return Transform3D(Basis(side,-float(spec.get("spins",2.0))*TAU*u),p)

## The director's face words (docs/COURT_STAGE_3D.md section 3) on this layer's
## channels: [channel, gain, second channel or -1, gain].
const FACE_WORDS:={"brows_up":[5,1.0,-1,0.0],"brows_down":[4,0.8,5,-0.6],"brows_worried":[3,1.0,-1,0.0],"lips_pressed":[2,1.0,-1,0.0],
	"eyes_wide":[6,0.35,-1,0.0],"eyes_narrow":[6,-0.45,-1,0.0],"jaw_open":[0,1.0,-1,0.0],"smile":[1,1.0,-1,0.0],"sneer":[8,1.0,-1,0.0],
	"cheeks_puff":[7,1.0,-1,0.0],"blink":[6,-0.95,-1,0.0],"frown":[11,1.0,-1,0.0]}
## Shape keys each face channel can drive, best first (J's contract names, then the mood morphs).
const SHAPES:={
	"smile":[["smile",1.0],["mood_smile",1.0]],
	"tight":[["lips_pressed",1.0],["mood_tight",1.0]],
	"worry":[["brows_worried",1.0],["mood_worry",1.0]],
	"stern":[["brows_down",1.0],["mood_stern",1.0]],
	"frown":[["frown",1.0],["mood_tight",0.35],["mood_worry",0.25]],
	"puff":[["cheeks_puff",1.0],["mood_tight",0.45],["mood_smile",0.2]],
	"sneer":[["sneer",1.0],["mood_stern",0.35],["mood_smile",0.15]],
}
const VISEMES:=["v_aa","v_ee","v_oo","v_mm","v_fv"]
## Morphs this layer owns and keeps at 0 (J's mood morphs: the moods come
## through the expression morphs here, and must not be doubled).
const OWNED_ZERO:=["mood_smile","mood_tight","mood_worry","mood_stern"]
## Where the eyes look, if the face has morphs for it: [morph, channel, gain].
const EYE_SHAPES:=[["eyes_left",9,1.0],["eyes_right",9,-1.0],["eyes_up",10,1.0],["eyes_down",10,-1.0]]
## Talking gestures speech may use: [clip, hands it needs, what the line is like].
const TALK_GESTURES:=[["talk_emphatic","R","!"],["talk_hesitant","LR","?"],["talk_plead","LR","?"],["talk_explain","R","."],["talk_one","R","."],["talk_dismiss","R","-"]]

static var _manifest:Dictionary={}
static var _anims:Dictionary={}
static var _maps:Dictionary={}
static var _faces:Dictionary={}
static var _rests:Dictionary={}       # variant -> {bone: the library rig's local rest}
static var _corr:Dictionary={}        # variant -> Array[Quaternion] by the figure's bone: library rest -> figure rest
static var _hips_off:Dictionary={}    # variant -> Vector3
## The whole court is out of sight (its window closed): nobody is moved.
static var paused_all:=false
## Time spent acting (microseconds, all figures) and how many figure-frames: for profiling.
static var prof_usec:=0
static var prof_steps:=0
## Blend-shape writes made (for profiling: each one may re-deform a mesh).
static var prof_morph_writes:=0
## A morph below this weight is set to 0; a change smaller than MORPH_STEP is not written.
const MORPH_FLOOR:=0.03
const MORPH_STEP:=0.01
## The face's detail by its height on screen (pixels): below FACE_NONE no
## morphs at all (the body still acts), below FACE_LOW only the lids and the jaw.
const FACE_NONE:=26.0
const FACE_LOW:=80.0

# --- a reaction being played -----------------------------------------------------

class Layer:
	var clip:=""
	var anim:Animation
	var map:PackedInt32Array
	var face:Array=[]
	var t:=0.0
	var length:=1.0
	var speed:=1.0
	var hold:=false
	var loop:=false
	var blend_in:=0.15
	var blend_out:=0.5
	var weights:PackedFloat32Array
	var corr:Array[Quaternion]=[]
	var hips_off:=Vector3.ZERO
	var fade_from:=-1.0
	var fade_len:=0.4
	var gain:=1.0
	var face_fps:=15.0
	var born:=0.0
	var exec:=false
	var events:Array=[]
	var ev_i:=0
	var held_from:=PackedFloat32Array([-1e9,-1e9])
	var held_until:=PackedFloat32Array([1e9,1e9])

	func weight()->float:
		var w:=1.0
		if blend_in>0.0:w=smoothstep(0.0,blend_in,t-born)
		if not hold and not loop:w*=1.0-smoothstep(length-blend_out,length,t)
		if fade_from>=0.0:w*=1.0-smoothstep(fade_from,fade_from+fade_len,t)
		return w*gain

	func done()->bool:
		if fade_from>=0.0 and t>=fade_from+fade_len:return true
		return not hold and not loop and t>=length

	func at()->float:
		if loop:return fmod(t,length)
		return minf(t,length)

	func face_value(ch:int,rest:float)->float:
		var curve:PackedFloat32Array=face[ch]
		if curve.is_empty():return rest
		var x:=at()*face_fps
		var i:=int(x)
		if i>=curve.size()-1:return curve[curve.size()-1]
		var u:=x-float(i)
		return curve[i]*(1.0-u)+curve[i+1]*u

# --- the library ---------------------------------------------------------------------

static func manifest()->Dictionary:
	if _manifest.is_empty():
		var text:=FileAccess.get_file_as_string(MANIFEST_PATH)
		var parsed:Variant=JSON.parse_string(text) if not text.is_empty() else null
		_manifest=parsed if parsed is Dictionary else {"clips":{}}
	return _manifest

static func clips()->Array:
	return (manifest().get("clips",{}) as Dictionary).keys()

static func has_clip(clip:String)->bool:
	return (manifest().get("clips",{}) as Dictionary).has(clip)

static func clip_meta(clip:String)->Dictionary:
	return (manifest().get("clips",{}) as Dictionary).get(clip,{})

static func clip_length(clip:String)->float:
	return float(clip_meta(clip).get("length",0.0))

## The clips of one body, as Animations (loaded once a body, shared by everyone of it).
static func library(variant:String)->Dictionary:
	if _anims.has(variant):return _anims[variant]
	var out:={}
	var file:=String((manifest().get("files",{}) as Dictionary).get(variant,"court_anims_%s.glb" % variant))
	var made:=load_glb(DIR+file)
	var rests:={}
	if made!=null:
		for node in made.find_children("*","Skeleton3D",true,false):
			var sk:=node as Skeleton3D
			for i in sk.get_bone_count():rests[sk.get_bone_name(i)]=sk.get_bone_rest(i)
		for node in made.find_children("*","AnimationPlayer",true,false):
			var player:=node as AnimationPlayer
			for name in player.get_animation_list():
				var clean:=String(name).get_slice("/",String(name).get_slice_count("/")-1)
				out[clean]=player.get_animation(name)
		made.free()
	# the right-hand twins the file leaves out, each its left one in a mirror
	for clip:String in (manifest().get("clips",{}) as Dictionary):
		var from:=String(clip_meta(clip).get("mirror_of",""))
		if from.is_empty() or out.has(clip) or not out.has(from):continue
		out[clip]=mirrored(out[from] as Animation,clip)
	_anims[variant]=out
	_rests[variant]=rests
	return out

## A clip turned into its mirror image (left for right): each .L bone's track
## goes to its .R twin and back; a rotation (x, y, z, w) in a bone's own frame
## becomes (x, -y, -z, w) (J's rig is symmetric: its left and right rests are
## mirrors this way to 0.01 degrees) and the hips move -x for x.
static func mirrored(src:Animation,name:String)->Animation:
	var m:=src.duplicate(true) as Animation
	m.resource_name=name
	for tr in m.get_track_count():
		var path:=m.track_get_path(tr)
		if path.get_subname_count()<1:continue
		var bone:=String(path.get_subname(0))
		var twin:=bone
		if bone.ends_with(".L"):twin=bone.left(-2)+".R"
		elif bone.ends_with(".R"):twin=bone.left(-2)+".L"
		if twin!=bone:m.track_set_path(tr,NodePath(String(path.get_concatenated_names())+":"+twin))
		match m.track_get_type(tr):
			Animation.TYPE_ROTATION_3D:
				for k in m.track_get_key_count(tr):
					var q:Quaternion=m.track_get_key_value(tr,k)
					m.track_set_key_value(tr,k,Quaternion(q.x,-q.y,-q.z,q.w))
			Animation.TYPE_POSITION_3D:
				for k in m.track_get_key_count(tr):
					var v:Vector3=m.track_get_key_value(tr,k)
					m.track_set_key_value(tr,k,Vector3(-v.x,v.y,v.z))
	return m

## How the library's rig sits on a figure's own skeleton: each bone's rest
## turned onto the figure's (identity while they match), the hips' offset.
## A body rebuilt since the library was made still takes its clips.
static func _fit(variant:String,skel:Skeleton3D)->void:
	if _corr.has(variant):return
	library(variant)
	var rests:Dictionary=_rests.get(variant,{})
	var corr:Array[Quaternion]=[]
	corr.resize(skel.get_bone_count())
	var off:=Vector3.ZERO
	for i in skel.get_bone_count():
		corr[i]=Quaternion.IDENTITY
		var name:=skel.get_bone_name(i)
		if not rests.has(name):continue
		var mine:Transform3D=rests[name]
		var theirs:=skel.get_bone_rest(i)
		corr[i]=theirs.basis.get_rotation_quaternion()*mine.basis.get_rotation_quaternion().inverse()
		if name=="hips":off=theirs.origin-mine.origin
	_corr[variant]=corr
	_hips_off[variant]=off

## A library file read as it is (no import step: the same data in every
## checkout and in the player's game); an imported copy only if that fails.
static func load_glb(path:String)->Node:
	if FileAccess.file_exists(path):
		var doc:=GLTFDocument.new()
		var state:=GLTFState.new()
		if doc.append_from_file(path,state)==OK:
			var made:=doc.generate_scene(state)
			if made!=null:return made
	if ResourceLoader.exists(path):
		var packed:=load(path) as PackedScene
		if packed!=null:return packed.instantiate()
	return null

## The AnimationLibrary of one body, for anyone who wants to play the clips
## on an AnimationPlayer ("act/<clip>" on a figure's player).
static var _libraries:Dictionary={}
static func animation_library(variant:String)->AnimationLibrary:
	return _shared_library(variant)

static func _shared_library(variant:String)->AnimationLibrary:
	if _libraries.has(variant):return _libraries[variant]
	var lib:=AnimationLibrary.new()
	var anims:=library(variant)
	for name:String in anims:lib.add_animation(StringName(name),anims[name])
	_libraries[variant]=lib
	return lib

## [track, bone, kind(0 rotation, 1 position, 2 scale)] for a clip on a skeleton of a body.
static func _map_for(variant:String,clip:String,skel:Skeleton3D)->PackedInt32Array:
	var key:="%s|%s" % [variant,clip]
	if _maps.has(key):return _maps[key]
	var out:=PackedInt32Array()
	var anim:Animation=library(variant).get(clip)
	if anim!=null:
		for tr in anim.get_track_count():
			var kind:=-1
			match anim.track_get_type(tr):
				Animation.TYPE_ROTATION_3D:kind=0
				Animation.TYPE_POSITION_3D:kind=1
				Animation.TYPE_SCALE_3D:kind=2
			if kind<0:continue
			var path:=anim.track_get_path(tr)
			if path.get_subname_count()<1:continue
			var bone:=skel.find_bone(String(path.get_subname(0)))
			if bone<0:continue
			out.append(tr);out.append(bone);out.append(kind)
	_maps[key]=out
	return out

static func _face_for(clip:String)->Array:
	if _faces.has(clip):return _faces[clip]
	var curves:Dictionary=clip_meta(clip).get("face",{})
	var out:=[]
	for ch:String in CHANNELS:
		var arr:=PackedFloat32Array()
		for v in curves.get(ch,[]):arr.append(float(v))
		out.append(arr)
	_faces[clip]=out
	return out

# --- the static API ------------------------------------------------------------------

## What the stage plugs in (docs/COURT_STAGE_3D.md §5: CourtStage.acting):
## an object whose play / look_at / mood / set_mood / speak / gesture / idle /
## hush / stop take the figure first.
static func service()->RefCounted:
	return Service.new()

## Each takes the figure first, then either the plain arguments or the
## director's lowered beat args (court_director.gd lower(): play {clip,
## fallback, hold, speed, blend, at}, mood {vector, name, face, dur, hold},
## look_at {target: "god", "god_up", "away" or a cast key, weight}) and the
## stage (court_stage.gd), which finds the god's point and the cast by key.
class Service extends RefCounted:
	func play(fig:Node3D,what:Variant="",opts:Variant=null,stage:Object=null)->float:
		if what is Dictionary:return Self.perform(fig,what,opts if opts is Object else stage)
		# the stage's beat: play(body, act, args) with the director's args
		if opts is Dictionary and ((opts as Dictionary).has("beat") or (opts as Dictionary).has("fallback")):
			var args:=(opts as Dictionary).duplicate()
			if not args.has("beat"):args["beat"]=String(what)
			return Self.perform(fig,args,stage)
		return Self.play(fig,String(what),opts if opts is Dictionary else {})
	func look_at(fig:Node3D,target:Variant=null,weight:Variant=1.0,stage:Object=null)->void:
		if target is Dictionary:
			var st:Object=weight if weight is Object else stage
			Self.look_toward(fig,Self.resolve(fig,(target as Dictionary).get("target",null),st),float((target as Dictionary).get("weight",0.8)))
		else:Self.look_toward(fig,Self.resolve(fig,target,stage),float(weight) if not weight is Object else 1.0)
	## From the stage a mood is a beat's (it passes and the person's own returns):
	## a plain vector lasts a moment; a beat's args carry its face and time.
	func set_mood(fig:Node3D,mood_value:Variant=null,_stage:Object=null)->void:
		if mood_value is Dictionary and not (mood_value as Dictionary).has("vector") and not (mood_value as Dictionary).has("dur"):
			Self.set_mood(fig,{"vector":mood_value,"dur":1.6,"hold":false})
		else:Self.set_mood(fig,mood_value)
	func mood(fig:Node3D,mood_value:Variant=null,stage:Object=null)->void:set_mood(fig,mood_value,stage)
	func speak(fig:Node3D,text:Variant="",seconds:Variant=2.0,opts:Variant=null)->void:
		if text is Dictionary:
			Self.speak(fig,String((text as Dictionary).get("text","")),float((text as Dictionary).get("seconds",2.0)),text)
		else:Self.speak(fig,String(text),float(seconds) if not seconds is Object else 2.0,opts if opts is Dictionary else {})
	func gesture(fig:Node3D,what:Variant="",amount:Variant=1.0,toward:=1.0)->void:
		if what is Dictionary:Self.perform(fig,what,amount if amount is Object else null)
		else:Self.gesture(fig,String(what),float(amount) if not amount is Object else 1.0,toward)
	func idle(fig:Node3D,stance_id:Variant="",_stage:Object=null)->void:
		if stance_id is Dictionary:
			var d:=stance_id as Dictionary
			Self.idle(fig,String(d.get("stance","")),{"seat":float(d.seat)} if d.has("seat") else {})
		else:Self.idle(fig,String(stance_id))
	func clip_length(clip:String)->float:return Self.clip_length(clip)
	func has_clip(clip:String)->bool:return Self.has_clip(clip)
	func exit_plan(style:String)->Array:return Self.exit_plan(style)
	func hush(fig:Node3D,on:Variant=true,_stage:Object=null)->void:Self.hush(fig,bool(on) if not on is Dictionary else true)
	func stop(fig:Node3D,blend:Variant=-1.0,_stage:Object=null)->void:Self.stop(fig,float(blend) if not blend is Dictionary else -1.0)

## A point or figure to look at from the director's words: "god", "god_up"
## (the voice above), "away" (off to one side and down), a cast key, or
## anything look_toward takes.
static func resolve(fig:Node3D,target:Variant,stage:Object)->Variant:
	if not (target is String or target is StringName):return target
	var word:=String(target)
	if word.is_empty():return null
	if word=="god" or word=="god_up":
		if stage!=null and stage.has_method(&"god_point"):return stage.call(&"god_point",word=="god_up")
		return fig.global_position+fig.global_transform.basis*Vector3(0.0,2.6,3.0)
	if word=="away":
		var away:=-1.0 if (hash(String(fig.name))&1)==0 else 1.0
		return fig.global_position+fig.global_transform.basis*Vector3(2.5*away,0.6,0.4)
	if stage!=null and stage.has_method(&"figure"):
		var other:Variant=stage.call(&"figure",word)
		if other is Object and is_instance_valid(other) and (other as Object).get(&"body3d") is Node3D:return (other as Object).get(&"body3d")
	return null

## A beat of the director's, performed: its act as a clip, a gesture or only
## its look and face, else the figure's own clip it names; returns seconds.
static func perform(fig:Node3D,args:Dictionary,stage:Object=null)->float:
	var a=of(fig)
	if a==null:return 0.0
	if stage==null:stage=a.stage_of()
	var act:=String(args.get("beat",args.get("clip","")))
	var at_key:=String(args.get("at",""))
	var other:Variant=resolve(fig,at_key,stage) if not at_key.is_empty() else null
	var spec:Array=ACT_MAP.get(act,["clip",act] if has_clip(act) else [])
	if a.variant=="child" and CHILD_ACTS.has(act):spec=CHILD_ACTS[act]
	var opts:={}
	# the acting's clips keep their own timing; the director's speed only where
	# the act is about it (a curt bow, a hurried one)
	if args.has("speed") and spec.size()>3 and String(spec[3])=="speed":opts["speed"]=float(args.speed)
	if bool(args.get("hold",false)):opts["hold"]=true
	if spec.is_empty():
		var fallback:=String(args.get("fallback",""))
		if not fallback.is_empty():return a.act(fallback,{"blend":float(args.get("blend",0.25))})
		return 0.0
	match String(spec[0]):
		"clip":
			var clip:=String(spec[1])
			if clip.ends_with("_"):clip+=a.side_of(other)
			if not has_clip(clip):
				clip=String(args.get("fallback",""))
				if args.has("blend"):opts["blend"]=float(args.blend)
			var secs:float=a.act(clip,opts)
			if clip.begins_with("half_catch") and other is Node3D:a.catch(other as Node3D)
			return secs
		"gesture":
			var gname:=String(spec[1])
			a.do_gesture(gname,float(spec[2]) if spec.size()>2 else 1.0,1.0 if a.side_of(other)=="l" else -1.0)
			return float(GESTURE_LEN[GESTURES.find(gname)]) if GESTURES.has(gname) else 0.0
	return float(args.get("dur",0.8))

## The acting on a figure (made the first time it is asked for).
static func of(fig:Node3D)->Node:
	if fig==null or not is_instance_valid(fig):return null
	var existing:Variant=fig.get_meta(&"court_acting") if fig.has_meta(&"court_acting") else null
	var skel:=fig.get(&"skeleton") as Skeleton3D
	if existing is Node and is_instance_valid(existing) and (existing as Node).get_script()==Self and (existing as Node).get(&"skel")==skel:return existing
	if skel==null:return null
	var actor:Node=Self.new()
	actor.name="Acting"
	actor.call(&"_bind",fig,skel)
	skel.add_child(actor)
	fig.set_meta(&"court_acting",actor)
	return actor

static func play(fig:Node3D,clip:String,opts:={})->float:
	var a=of(fig)
	return a.act(clip,opts) if a!=null else 0.0

## (look_at on the stage's hook; here it may not shadow Node3D.look_at)
static func look_toward(fig:Node3D,target:Variant,weight:=1.0)->void:
	var a=of(fig)
	if a!=null:a.look(target,weight)

## mood: {joy, fear, anger, scorn, awe, tired} (0..1 each), or one of the
## figure's mood words (warm, neutral, afraid, defiant, grieved).
static func set_mood(fig:Node3D,mood:Variant)->void:
	var a=of(fig)
	if a==null:return
	if mood is Dictionary:a.feel(mood)
	elif mood is String or mood is StringName:a.feel(FIGURE_MOODS.get(String(mood),{}))

static func speak(fig:Node3D,text:String,seconds:float,opts:={})->void:
	var a=of(fig)
	if a!=null:a.talk(text,seconds,opts)

## stance_id: one of the figure's own (stand, hip, folded, clasped, belt,
## staff, bowl, sit, crouch) or one of the acting's: cord, bundle, guard (on
## the figure's staff), log (seated, an elder's way; opts.seat: the seat's
## height in the hall's metres, from the set's mark: the body sits on it
## whatever its size, so the stage need not lift them), fire (crouched by
## the fire, warming their hands).
static func idle(fig:Node3D,stance_id:String,opts:={})->void:
	var a=of(fig)
	if a!=null:a.rest_in(stance_id,opts)

## The acting's own stances and the figure's stance (and prop) each stands on.
const OWN_STANCES:={"cord":"stand","bundle":"stand","guard":"staff","log":"sit","fire":"crouch","cross":"sit","fidget":"stand"}

## How a stage takes someone out of the hall, step by step (the stage moves and
## turns the body; this says what it plays): [{clip, seconds, move, face}].
## move: metres toward the way out for a 1.72 m body (negative: back the way
## they came); seconds 0: as long as the move takes at the clip's own speed
## (court_anims.json speed_mps). face: "out" turned to the way out, "back"
## turned back the way they came, "god" facing the god. Styles: bow (bows,
## backs away bowing, bumps a post, turns and walks out), storm, storm_back
## (storms off, stops, comes back for what they forgot, storms off again),
## sober (cast out: slow, head down), led (seized or condemned: bound, led).
static func exit_plan(style:String)->Array:
	match style:
		"bow":return [{"clip":"bow_deep","seconds":2.2,"move":0.0,"face":"god"},{"clip":"back_out","seconds":0.0,"move":0.9,"face":"god"},
			{"clip":"bump_post","seconds":1.7,"move":0.0,"face":"god"},{"clip":"walk_out","seconds":0.0,"move":-1.0,"face":"out"}]
		"storm":return [{"clip":"storm_walk","seconds":0.0,"move":-1.0,"face":"out"}]
		"storm_back":return [{"clip":"storm_walk","seconds":0.0,"move":1.4,"face":"out"},{"clip":"storm_stop","seconds":1.8,"move":0.0,"face":"out"},
			{"clip":"storm_walk","seconds":0.0,"move":-1.4,"face":"back"},{"clip":"snatch_up","seconds":1.2,"move":0.0,"face":"back"},
			{"clip":"storm_walk","seconds":0.0,"move":-1.0,"face":"out"}]
		"sober":return [{"clip":"walk_sober","seconds":0.0,"move":-1.0,"face":"out"}]
		"led":return [{"clip":"walk_led","seconds":0.0,"move":-1.0,"face":"out"}]
	return [{"clip":"walk_out","seconds":0.0,"move":-1.0,"face":"out"}]

## A prop held in a fist (side "R" or "L"): drawn every frame where the fist
## closes (fist_frame). M's props: origin at the grip, +Y along the handle to
## the head, +Z the blade's edge (a lid: +Y down to the lid).
static func hold(fig:Node3D,node:Node3D,side:="R")->void:
	var a=of(fig)
	if a!=null:a._held[1 if side=="R" else 0]=node

## Let go of what that hand holds: it stays where it is.
static func release(fig:Node3D,side:="R")->void:
	var a=of(fig)
	if a!=null:a._held[1 if side=="R" else 0]=null

static func gesture(fig:Node3D,name:String,amount:=1.0,toward:=1.0)->void:
	var a=of(fig)
	if a!=null:a.do_gesture(name,amount,toward)

static func hush(fig:Node3D,on:=true)->void:
	var a=of(fig)
	if a!=null:a.hushed=on

static func stop(fig:Node3D,blend:=-1.0)->void:
	var a=of(fig)
	if a!=null:a.let_go(blend)

## How lively the idle life is (fidgets, glances, shifts): 0 still .. 1 as people are.
static func set_ambient(fig:Node3D,level:float)->void:
	var a=of(fig)
	if a!=null:a.ambient=clampf(level,0.0,1.0)

## Points in the hall an idle glance may fall on (neighbours, the fire, a gift).
static func set_glance_points(fig:Node3D,points:PackedVector3Array)->void:
	var a=of(fig)
	if a!=null:a.glance_points=points

# --- one figure ----------------------------------------------------------------------

var fig:Node3D
var skel:Skeleton3D
var variant:=""
var body_k:=1.0
var rng:=RandomNumberGenerator.new()
var hushed:=false
var ambient:=1.0
var glance_points:=PackedVector3Array()
## Bones the tests (and captures) want to see after each frame, and where they were.
var capture_bones:=PackedInt32Array()
var captured:=PackedVector3Array()

var _n:=0
var _rest_g:Array[Quaternion]=[]
var _rest_gi:Array[Quaternion]=[]
var b_root:=-1
var b_hips:=-1
var b_spine:=-1
var b_chest:=-1
var b_neck:=-1
var b_head:=-1
var b_jaw:=-1
var b_eye:=PackedInt32Array([-1,-1])
var b_brow:=PackedInt32Array([-1,-1])
var b_sh:=PackedInt32Array([-1,-1])
var b_thigh:=PackedInt32Array([-1,-1])
var b_hand:=PackedInt32Array([-1,-1])
var b_fingers:=PackedInt32Array([-1,-1])
var b_index:=PackedInt32Array([-1,-1])
## The props the hands hold (0 the left, 1 the right): each drawn at its fist
## every frame (fist_frame), between the playing clip's props_from and
## props_until for that hand; let go, a prop stays where it was.
var _held:Array=[null,null]
## An execution's beats as the playing clip passes them (its court_anims.json
## events: {t, name, part, bone, dir...}): for blood, sound and the split body.
signal cue(fig:Node3D,event:Dictionary)
var b_upper:=PackedInt32Array([-1,-1])
var b_fore:=PackedInt32Array([-1,-1])
## A hand held where the clips put it (a staff planted on the floor), whatever
## the breathing, the sway and the turn of the chest do above it.
var _pin_on:=PackedInt32Array([0,0])
var _pin_at:Array[Transform3D]=[Transform3D.IDENTITY,Transform3D.IDENTITY]
var _eye_axis:=PackedInt32Array([1,1])
var _jaw_v:=1
var _jaw_h:=0
var _brow_up:=PackedVector3Array([Vector3.UP,Vector3.UP])
var _hips_side:=Vector3.RIGHT
var _groups:Dictionary={}

var _a:Layer
var _b:Layer
## The acting's own stance under everything (and, for the seat, its higher twin).
var base_stance:=""
var _base:Layer
var _base_hi:Layer
var _base_out:Layer
var _base_mix:=0.0

# procedural state
var _acc:=PackedVector3Array()       # per bone: degrees about X, Y, Z (figure axes, rest frame)
var _touched:=PackedInt32Array()     # bones with something in _acc this frame
var _hips_move:=Vector3.ZERO
var _face:=PackedFloat32Array()
var face_now:=PackedFloat32Array()   # the face as last shown (tests read it)
var lids_now:=1.0                    # the eyelids as last shown, blinks and all
var _mood_target:=PackedFloat32Array()
var _mood:=PackedFloat32Array()
var _mood_explicit:=false
var _fig_mood:=""
var _clock:=0.0
var _seed:=0.0
var _breath:=0.0
var _breath_period:=3.6
var _blink_wait:=2.0
var _blink_t:=-1.0
var _blink_double:=false
var _shift:=0.0
var _shift_from:=0.0
var _shift_to:=0.0
var _shift_u:=1.0
var _shift_wait:=6.0
var _fidget_wait:=30.0
var _tremble:=0.0

# looking
var _look_kind:=0                    # 0 none, 1 point, 2 node, 3 figure
var _look_point:=Vector3.ZERO
var _look_node:Node3D
var _look_weight:=1.0
var _look_w:=0.0
var _yaw:=0.0
var _pitch:=0.0
var _yaw_v:=0.0
var _pitch_v:=0.0
var _have_aim:=false
var look_yaw:=0.0                    # the last correction given to the head (degrees; tests read it)
var _glance:=Vector3.ZERO
var _glance_wait:=1.0
var _saccade:=Vector2.ZERO
var _saccade_wait:=0.8

# gestures
var _g:=-1
var _g_t:=0.0
var _g_amount:=1.0
var _g_dir:=1.0

# speech
var _syl_t:=PackedFloat32Array()
var _syl_len:=PackedFloat32Array()
var _syl_open:=PackedFloat32Array()
var _syl_shape:=PackedInt32Array()
var _beats:=PackedFloat32Array()
var _speech_t:=-1.0
var _speech_len:=0.0
var _syl_i:=0
var _beat_i:=0
var _beat_at:=-10.0
var _gest_t:=PackedFloat32Array()
var _gest_clip:=PackedStringArray()
var _gest_i:=0
var speaking:=false

# the face's morphs
var _sk_mesh:Array[MeshInstance3D]=[]
var _sk_index:=PackedInt32Array()
var _sk_value:=PackedFloat32Array()
var _sk_last:=PackedFloat32Array()
var _sk_from_ch:=PackedInt32Array()
var _sk_from_key:=PackedInt32Array()
var _sk_from_gain:=PackedFloat32Array()
var _vis_key:=PackedInt32Array([-1,-1,-1,-1,-1])
var _view_container:CanvasItem
var _consts:Dictionary={}
var _mood_face:=PackedFloat32Array()
var _vis_amt:=PackedFloat32Array([0.0,0.0,0.0,0.0,0.0])
## The jaw_open, brows_up, brows_down, eyes_wide and blink morphs (-1: the bones do it).
var _x_key:=PackedInt32Array([-1,-1,-1,-1,-1])
var _vis_from:=PackedInt32Array()
var _vis_to:=PackedInt32Array()
var _x_from:=PackedInt32Array()
var _x_to:=PackedInt32Array()
var _x_amt:=PackedFloat32Array([0.0,0.0,0.0,0.0,0.0])
var _sk_low:=PackedByteArray()     # 1: kept on a low-detail face (lids, jaw)
var _lod:=2
var _lod_wait:=0.0
var face_px:=0.0                   # the face's height on screen at the last look
var _refresh:=0.0
var _beat_mood:=PackedFloat32Array([0.0,0.0,0.0,0.0,0.0,0.0])
var _beat_face:=PackedFloat32Array([0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0])
var _beat_t:=-1.0
var _beat_len:=1.0
var _beat_hold:=false
var _beat_w:=0.0
var _still:=1.0

func _bind(figure:Node3D,skeleton:Skeleton3D)->void:
	fig=figure;skel=skeleton
	var script:=fig.get_script() as Script
	if script!=null:_consts=script.get_script_constant_map()
	variant=String(fig.get(&"variant"))
	body_k=float(fig.get(&"body_height"))/1.72 if fig.get(&"body_height")!=null else 1.0
	var who:=String(fig.get_meta(&"person_name",fig.name))
	rng.seed=hash(who)
	_seed=rng.randf()
	_n=skel.get_bone_count()
	_rest_g.resize(_n);_rest_gi.resize(_n)
	for i in _n:
		var q:=skel.get_bone_global_rest(i).basis.get_rotation_quaternion()
		_rest_g[i]=q;_rest_gi[i]=q.inverse()
	b_root=skel.find_bone("root");b_hips=skel.find_bone("hips");b_spine=skel.find_bone("spine");b_chest=skel.find_bone("chest")
	b_neck=skel.find_bone("neck");b_head=skel.find_bone("head");b_jaw=skel.find_bone("jaw")
	for s in 2:
		var sd:=".L" if s==0 else ".R"
		b_eye[s]=skel.find_bone("eye"+sd);b_brow[s]=skel.find_bone("brow"+sd);b_sh[s]=skel.find_bone("shoulder"+sd)
		b_thigh[s]=skel.find_bone("thigh"+sd);b_hand[s]=skel.find_bone("hand"+sd)
		b_fingers[s]=skel.find_bone("fingers"+sd);b_index[s]=skel.find_bone("index"+sd)
		b_upper[s]=skel.find_bone("upper_arm"+sd);b_fore[s]=skel.find_bone("forearm"+sd)
		if b_eye[s]>=0:_eye_axis[s]=_axis_along(b_eye[s],Vector3.UP)
		if b_brow[s]>=0:
			var head_basis:=skel.get_bone_global_rest(skel.get_bone_parent(b_brow[s])).basis
			_brow_up[s]=head_basis.inverse()*Vector3.UP
	if b_jaw>=0:
		_jaw_v=_axis_along(b_jaw,Vector3.UP)
		_jaw_h=_axis_along(b_jaw,Vector3.RIGHT)
	if b_hips>=0:
		var parent:=skel.get_bone_parent(b_hips)
		var pb:=skel.get_bone_global_rest(parent).basis if parent>=0 else Basis.IDENTITY
		_hips_side=pb.inverse()*Vector3.RIGHT
	for name:String in (manifest().get("groups",{}) as Dictionary):
		var idx:=PackedInt32Array()
		for bone_name in (manifest().groups[name] as Array):
			var b:=skel.find_bone(String(bone_name))
			if b>=0:idx.append(b)
		_groups[name]=idx
	_acc.resize(_n);_acc.fill(Vector3.ZERO)
	_face.resize(CH_COUNT);face_now.resize(CH_COUNT);_mood_face.resize(CH_COUNT)
	for i in CH_COUNT:_face[i]=FACE_REST[i];face_now[i]=FACE_REST[i]
	_mood_target.resize(M_COUNT);_mood_target.fill(0.0)
	_mood.resize(M_COUNT);_mood.fill(0.0)
	_breath_period=3.3+rng.randf()*1.4
	_breath=rng.randf()
	_blink_wait=rng.randf_range(0.5,3.5)
	_shift_wait=rng.randf_range(3.0,12.0)
	_fidget_wait=rng.randf_range(18.0,45.0)
	_glance_wait=rng.randf_range(0.5,2.5)
	_bind_face()
	_mark_low()
	if fig.has_method(&"add_library") and not library(variant).is_empty():
		fig.call(&"add_library","act",_shared_library(variant))
	# J's head-turn modifiers give way: this turns the head (and follows their gaze point).
	var looks:Variant=fig.get(&"_looks")
	if looks is Array:
		for m in looks:
			if m is SkeletonModifier3D:(m as SkeletonModifier3D).active=false

func _axis_along(bone:int,dir:Vector3)->int:
	var basis:=skel.get_bone_global_rest(bone).basis
	var best:=0
	var score:=-1.0
	for i in 3:
		var d:=absf(basis[i].normalized().dot(dir))
		if d>score:score=d;best=i
	return best

## The face's morphs again (the figure was dressed again: other hair, a beard).
func rebind_face()->void:
	_sk_mesh.clear();_sk_index.clear();_sk_value.clear();_sk_last.clear()
	_sk_from_ch.clear();_sk_from_key.clear();_sk_from_gain.clear()
	_vis_from.clear();_vis_to.clear();_x_from.clear();_x_to.clear()
	_vis_key.fill(-1);_x_key.fill(-1)
	_bind_face()
	_mark_low()

func _mark_low()->void:
	_sk_low.resize(_sk_mesh.size());_sk_low.fill(0)
	for i in _x_from.size():
		if _x_from[i] in [0,3,4]:_sk_low[_x_to[i]]=1

## How much of the face to drive: 2 all, 1 the lids and jaw, 0 none (by the
## head's height on screen, checked a few times a second).
func _face_lod(dt:float)->int:
	# a face at rest (small or out of the camera's view) looks again every
	# frame, so one the camera cuts to has its expression from the first frame
	_lod_wait-=dt
	if _lod_wait>0.0 and _lod!=0:return _lod
	_lod_wait=0.3
	var vp:=get_viewport()
	var cam:=vp.get_camera_3d() if vp!=null else null
	if cam==null or b_head<0:
		_lod=2;return _lod
	var head:=skel.global_transform*skel.get_bone_global_pose(b_head).origin
	if not cam.is_position_in_frustum(head):
		face_px=0.0;_lod=0;return _lod
	var tall:=float(fig.get(&"head_height")) if fig.get(&"head_height")!=null else 0.25
	tall*=fig.global_transform.basis.get_scale().y
	var h:=float(vp.get_visible_rect().size.y)
	if cam.projection==Camera3D.PROJECTION_ORTHOGONAL:
		face_px=tall/maxf(cam.size,0.001)*h
	else:
		var d:=maxf((head-cam.global_position).dot(-cam.global_transform.basis.z),0.05)
		face_px=tall/(2.0*d*tan(deg_to_rad(cam.fov*0.5)))*h
	_lod=0 if face_px<FACE_NONE else (1 if face_px<FACE_LOW else 2)
	return _lod

func _bind_face()->void:
	var meshes:Array=[]
	var listed:Variant=fig.get(&"_meshes")
	if listed is Array:
		for m in listed:
			if not m is MeshInstance3D:continue
			var part:=String((m as MeshInstance3D).name)
			if part in ["Mouth","Brows","Eyes","Body"] or ((part.begins_with("beard_") or part.begins_with("hair_")) and (m as MeshInstance3D).visible):meshes.append(m)
	var keys:={}
	for ch:String in SHAPES:
		for pair:Array in SHAPES[ch]:
			var found:=false
			for m:MeshInstance3D in meshes:
				var idx:=m.find_blend_shape_by_name(StringName(String(pair[0])))
				if idx<0:continue
				found=true
				var key:="%d|%d" % [m.get_instance_id(),idx]
				if not keys.has(key):
					keys[key]=_sk_mesh.size()
					_sk_mesh.append(m);_sk_index.append(idx);_sk_value.append(0.0);_sk_last.append(-1.0)
				_sk_from_ch.append(CHANNELS.find(ch));_sk_from_key.append(int(keys[key]));_sk_from_gain.append(float(pair[1]))
			# a contract key (smile...) wins over the mood morph standing in for it
			if found and String(pair[0]).find("mood_")<0:break
	for e:Array in EYE_SHAPES:
		for m:MeshInstance3D in meshes:
			var idx:=m.find_blend_shape_by_name(StringName(String(e[0])))
			if idx<0:continue
			var key:="%d|%d" % [m.get_instance_id(),idx]
			if not keys.has(key):
				keys[key]=_sk_mesh.size()
				_sk_mesh.append(m);_sk_index.append(idx);_sk_value.append(0.0);_sk_last.append(-1.0)
			_sk_from_ch.append(int(e[1]));_sk_from_key.append(int(keys[key]));_sk_from_gain.append(float(e[2]))
			break
	# every mesh that carries the morph moves with it: the painted mouth, the
	# skin under it, and a beard riding the jaw
	for v in VISEMES.size():
		for m:MeshInstance3D in meshes:
			var idx:=m.find_blend_shape_by_name(StringName(VISEMES[v]))
			if idx<0:continue
			_vis_key[v]=_sk_mesh.size()
			_vis_from.append(v);_vis_to.append(_sk_mesh.size())
			_sk_mesh.append(m);_sk_index.append(idx);_sk_value.append(0.0);_sk_last.append(-1.0)
	# J's expression morphs for the jaw, the brows and the lids (else the bones do it)
	for pair:Array in [["jaw_open",0],["brows_up",1],["brows_down",2],["eyes_wide",3],["blink",4]]:
		for m:MeshInstance3D in meshes:
			var idx:=m.find_blend_shape_by_name(StringName(String(pair[0])))
			if idx<0:continue
			_x_key[int(pair[1])]=_sk_mesh.size()
			_x_from.append(int(pair[1]));_x_to.append(_sk_mesh.size())
			_sk_mesh.append(m);_sk_index.append(idx);_sk_value.append(0.0);_sk_last.append(-1.0)
	for name:String in OWNED_ZERO:
		for m:MeshInstance3D in meshes:
			var idx:=m.find_blend_shape_by_name(StringName(name))
			if idx<0:continue
			_sk_mesh.append(m);_sk_index.append(idx);_sk_value.append(0.0);_sk_last.append(-1.0)

# --- instance API ----------------------------------------------------------------------

func act(clip:String,opts:={})->float:
	# a child's own version; a child's clip asked of a grown-up: the grown-up's
	if variant=="child" and CHILD_CLIPS.has(clip) and owns(String(CHILD_CLIPS[clip])):clip=String(CHILD_CLIPS[clip])
	elif has_clip(clip) and not owns(clip):
		for k:String in CHILD_CLIPS:
			if String(CHILD_CLIPS[k])==clip and owns(k):
				clip=k;break
	if not has_clip(clip) or not owns(clip):
		# not ours: the figure's own clip, on its own player
		if fig.has_method(&"play") and fig.get(&"player")!=null and (fig.get(&"player") as AnimationPlayer).has_animation(clip):
			fig.call(&"play",clip,float(opts.get("blend",0.3)),0.0)
			return float(fig.call(&"clip_length",clip))
		return 0.0
	var layer:=_layer(clip,opts)
	if layer==null:return 0.0
	if _a!=null and not _a.done():
		_b=_a
		_b.fade_from=_b.t
		_b.fade_len=maxf(layer.blend_in,0.12)
	_a=layer
	return layer.length/layer.speed

func _layer(clip:String,opts:Dictionary)->Layer:
	var meta:=clip_meta(clip)
	var layer:=Layer.new()
	layer.clip=clip
	layer.anim=library(variant).get(clip)
	if layer.anim==null:return null
	layer.map=_map_for(variant,clip,skel)
	_fit(variant,skel)
	layer.corr=_corr[variant]
	layer.hips_off=_hips_off[variant]
	layer.face=_face_for(clip)
	layer.face_fps=float(manifest().get("face_fps",15.0))
	layer.length=float(meta.get("length",layer.anim.length))
	layer.speed=maxf(0.05,float(opts.get("speed",1.0)))
	layer.hold=bool(opts.get("hold",meta.get("hold",false)))
	layer.loop=bool(opts.get("loop",meta.get("loop",false)))
	layer.blend_in=float(opts.get("blend",meta.get("blend_in",0.16)))
	layer.blend_out=float(opts.get("out",meta.get("blend_out",0.5)))
	layer.gain=clampf(float(opts.get("weight",1.0)),0.0,1.0)
	layer.t=float(opts.get("at",0.0))
	layer.weights=_weights_for(meta,opts)
	layer.born=layer.t
	layer.exec=String(meta.get("kind",""))=="exec"
	layer.events=events(clip)
	while layer.ev_i<layer.events.size() and float((layer.events[layer.ev_i] as Dictionary).get("t",0.0))<layer.t:layer.ev_i+=1
	var pf:Dictionary=meta.get("props_from",{});var pu:Dictionary=meta.get("props_until",{})
	for s in 2:
		var side:="L" if s==0 else "R"
		layer.held_from[s]=float(pf.get(side,-1e9));layer.held_until[s]=float(pu.get(side,1e9))
	return layer

func _weights_for(meta:Dictionary,opts:Dictionary)->PackedFloat32Array:
	var w:=PackedFloat32Array()
	w.resize(_n);w.fill(0.0)
	var groups:Dictionary=(meta.get("groups",{}) as Dictionary).duplicate()
	for k:String in (opts.get("groups",{}) as Dictionary):groups[k]=float(opts.groups[k])
	var stance:=String(fig.get(&"stance"))
	var seated:=stance in SEATED or (not base_stance.is_empty() and bool(clip_meta("stance_"+("log_low" if base_stance=="log" else base_stance)).get("seated",false)))
	# an execution's clip moves the whole body whatever the stance under it
	var whole:=String(meta.get("kind",""))=="exec"
	if seated and not whole and not bool(meta.get("stance",false)) and not bool(opts.get("force_legs",false)):groups["legs"]=0.0
	if PROP_ARMS.has(stance) and not whole and not bool(meta.get("stance",false)) and String(meta.get("prop",""))!=stance and not bool(opts.get("drop_prop",false)):
		for arm:String in PROP_ARMS[stance]:groups[arm]=0.0
	for name:String in groups:
		var idx:PackedInt32Array=_groups.get(name,PackedInt32Array())
		var gw:=clampf(float(groups[name]),0.0,1.0)
		for b in idx:w[b]=gw
	return w

func look(target:Variant,weight:=1.0)->void:
	_look_weight=clampf(weight,0.0,1.0)
	if target==null:
		_look_kind=0;_look_node=null
	elif target is Vector3:
		_look_kind=1;_look_point=target;_look_node=null
	elif target is Node3D:
		_look_node=target
		_look_kind=3 if (target as Node3D).has_method(&"head_top") else 2

func feel(mood:Dictionary)->void:
	if mood.has("vector") or mood.has("face") or mood.has("dur"):
		_beat_feel(mood);return
	_mood_explicit=true
	for i in M_COUNT:_mood_target[i]=clampf(float(mood.get(MOODS[i],0.0)),0.0,1.0)

## A beat's mood and face (the director's): eased in, held for its seconds
## (or until the next one, when it holds), eased out; on top of the person's own mood.
func _beat_feel(args:Dictionary)->void:
	var vector:Dictionary=args.get("vector",{}) if args.get("vector") is Dictionary else {}
	for i in M_COUNT:_beat_mood[i]=clampf(float(vector.get(MOODS[i],0.0)),0.0,1.0)
	_beat_face.fill(0.0)
	var words:Dictionary=args.get("face",{}) if args.get("face") is Dictionary else {}
	for w:String in words:
		var map:Array=FACE_WORDS.get(w,[])
		if map.is_empty():continue
		var v:=clampf(float(words[w]),0.0,1.0)
		_beat_face[int(map[0])]+=v*float(map[1])
		if int(map[2])>=0:_beat_face[int(map[2])]+=v*float(map[3])
	_beat_t=0.0
	_beat_len=maxf(0.2,float(args.get("dur",1.0)))
	_beat_hold=bool(args.get("hold",false))

## A half-catch takes the one who is fainting: their fall becomes the caught
## fall (slower, into the catcher's arms), at the same moment of it, toward the catcher.
func catch(other:Node3D)->void:
	var them=of(other)
	if them==null or them._a==null or not String(them._a.clip).begins_with("faint_"):return
	var toward:String=them.side_of(fig)
	var caught:="faint_caught_"+toward
	if not has_clip(caught):return
	var at:float=them._a.t
	them.act(caught,{"at":at,"blend":0.15})
	# and the catch meets the fall where it is (they were already going down)
	if _a!=null and String(_a.clip).begins_with("half_catch") and at<0.45:
		_a.t=at;_a.born=at

## Which way another stands from this person: "l" (their left) or "r".
func side_of(other:Variant)->String:
	var at:=Vector3.ZERO
	if other is Node3D and is_instance_valid(other):at=(other as Node3D).global_position
	elif other is Vector3:at=other
	else:return "l" if (hash(String(fig.name))&1)==0 else "r"
	var local:=fig.global_transform.affine_inverse()*at
	return "l" if local.x>=0.0 else "r"

func rest_in(stance_id:String,opts:={})->void:
	let_go(0.45)
	rebind_face()
	var own:=String(OWN_STANCES.get(stance_id,""))
	var under:=own if not own.is_empty() else stance_id
	# a seat from the set's mark: the figure's own stool only when none is given
	if stance_id=="log" and opts.has("seat"):under="stand"
	if fig.get(&"stance")!=null and under in (_consts.get("STANCES",[]) as Array):
		fig.set(&"stance",under)
	if fig.has_method(&"rest_clip") and fig.has_method(&"play"):
		fig.call(&"play",String(fig.call(&"rest_clip")),0.45,-1.0)
	_set_base(stance_id,opts)

## The base under everything: one of the acting's stances (or none).
func _set_base(stance_id:String,opts:Dictionary)->void:
	base_stance=""
	if _base!=null:
		_base_out=_base;_base_out.fade_from=_base_out.t;_base_out.fade_len=0.6
		_base=null;_base_hi=null
	if not OWN_STANCES.has(stance_id):return
	var clip:="stance_"+stance_id
	var hi:=""
	_base_mix=0.0
	if stance_id=="log":
		clip="stance_log_low";hi="stance_log_high"
		var low:=float(clip_meta("stance_log_low").get("seat",0.30))
		var high:=float(clip_meta("stance_log_high").get("seat",0.46))
		# the mark's seat is in the hall's metres: for this body as a 1.72 m one
		var tall:=body_k*maxf(fig.global_transform.basis.get_scale().y if fig.is_inside_tree() else fig.scale.y,0.01)
		var seat:=float(opts.get("seat",0.43*tall))/tall
		_base_mix=clampf((seat-low)/maxf(high-low,0.01),0.0,1.0)
	if not owns(clip):return
	base_stance=stance_id
	_base=_layer(clip,{"loop":true,"blend":0.6})
	_base.t=rng.randf()*_base.length
	_base.born=_base.t
	if not hi.is_empty() and owns(hi):
		_base_hi=_layer(hi,{"loop":true,"blend":0.6})
		_base_hi.t=_base.t
		_base_hi.born=_base.t
		_base_hi.gain=_base_mix

## Whether this body's library has the clip (a child's clips are only on the child).
func owns(clip:String)->bool:
	return has_clip(clip) and library(variant).has(clip)

func let_go(blend:=-1.0)->void:
	for layer in [_a,_b]:
		if layer!=null and (layer as Layer).fade_from<0.0:
			(layer as Layer).fade_from=(layer as Layer).t
			(layer as Layer).fade_len=blend if blend>0.0 else (layer as Layer).blend_out

## A gesture: one of GESTURES (procedural, on top of anything), else a clip
## of the library, else one of the figure's own clips.
func do_gesture(name:String,amount:=1.0,toward:=1.0)->void:
	var i:=GESTURES.find(name)
	if i<0:
		act(name)
		return
	_g=i;_g_t=0.0;_g_amount=amount;_g_dir=signf(toward) if toward!=0.0 else 1.0

## The words as the mouth will say them: syllables spread over the seconds the
## bubble takes, pauses at commas and full stops, stressed words beat.
func talk(text:String,seconds:float,opts:={})->void:
	_syl_t.clear();_syl_len.clear();_syl_open.clear();_syl_shape.clear();_beats.clear()
	_gest_t.clear();_gest_clip.clear()
	var units:=0.0
	var starts:=PackedFloat32Array()
	var stress:=PackedFloat32Array()
	var mark:=""
	var index:=0
	for raw in text.replace("\n"," ").split(" ",false):
		var word:=raw.strip_edges()
		var tail:=""
		while not word.is_empty() and ",.;:!?-–—\"')".contains(word[word.length()-1]):
			tail=word[word.length()-1]+tail;word=word.substr(0,word.length()-1)
		word=word.lstrip("\"'(")
		if word.is_empty():continue
		if units>0.0:units+=0.3
		var first:=word[0]
		var stressed:=word.length()>=6 or (index>0 and first==first.to_upper() and first!=first.to_lower()) or tail.contains("!")
		if stressed:stress.append(units)
		for shape in _syllables(word):
			starts.append(units);_syl_shape.append(shape)
			_syl_open.append(1.0 if shape==0 else (0.55 if shape==1 else (0.75 if shape==2 else 0.25)))
			units+=1.0
		if tail.contains(".") or tail.contains("!") or tail.contains("?"):units+=2.4
		elif not tail.is_empty() and not tail.contains("'") and not tail.contains(")") and not tail.contains("\""):units+=1.4
		if tail.contains("!"):mark="!"
		elif tail.contains("?") and mark!="!":mark="?"
		index+=1
	if units<=0.0 or seconds<=0.05:
		_syl_shape.clear();_syl_open.clear();return
	var per:=seconds*0.92/units
	for u in starts:
		_syl_t.append(u*per);_syl_len.append(per*0.95)
	var last:=-1.0
	for u in stress:
		var bt:=u*per
		if bt-last>=0.45:_beats.append(bt);last=bt
	_speech_t=0.0;_speech_len=seconds;_syl_i=0;_beat_i=0;_beat_at=-10.0
	speaking=true
	# a gesture or two, where the stance leaves a hand free and nothing is held
	if bool(opts.get("gestures",true)) and seconds>=1.4:
		var free:=_free_hands()
		var g_at:=_beats[0] if not _beats.is_empty() else 0.3
		var count:=1 if seconds<4.5 else 2
		for n in count:
			var pick:=_pick_talk_gesture(mark,free,n)
			if pick.is_empty():break
			_gest_t.append(maxf(0.15,g_at-0.35));_gest_clip.append(pick)
			g_at+=maxf(2.4,seconds*0.5)
	_gest_i=0

func _free_hands()->String:
	if not base_stance.is_empty():
		return String(clip_meta("stance_"+("log_low" if base_stance=="log" else base_stance)).get("hands","LR"))
	var hands:Dictionary=_consts.get("FREE_HANDS",{})
	return String(hands.get(String(fig.get(&"stance")),"LR"))

func _pick_talk_gesture(mark:String,free:String,n:int)->String:
	var choices:=PackedStringArray()
	for g:Array in TALK_GESTURES:
		var hands:=String(g[1])
		var ok:=true
		for h in hands:
			if not free.contains(h):ok=false
		if not ok:continue
		if mark=="!" and String(g[2])=="!":choices.append(String(g[0]))
		elif mark=="?" and String(g[2])=="?":choices.append(String(g[0]))
		elif mark=="" and String(g[2])==".":choices.append(String(g[0]))
	if choices.is_empty():
		for g:Array in TALK_GESTURES:
			if String(g[2])=="." and free.contains("R"):choices.append(String(g[0]))
	if choices.is_empty():return ""
	return choices[(rng.randi()+n)%choices.size()]

## Syllables of a word, as mouth shapes: 0 open (a), 1 wide (e, i), 2 round (o, u),
## 3 closed (m, b, p first), 4 lip on teeth (f, v first).
static func _syllables(word:String)->PackedInt32Array:
	var out:=PackedInt32Array()
	var w:=word.to_lower()
	var in_vowel:=false
	var first:=w[0] if not w.is_empty() else ""
	if first in ["m","b","p"]:out.append(3)
	elif first in ["f","v"]:out.append(4)
	for i in w.length():
		var c:=w[i]
		var v:=c in ["a","e","i","o","u","y"]
		if v and not in_vowel:
			out.append(0 if c=="a" else (1 if c in ["e","i","y"] else 2))
		in_vowel=v
	# a final silent e, and -es and -ed that add no beat (stores, loved; not boxes, wanted)
	var n:=w.length()
	if n>3 and out.size()>1:
		if w.ends_with("e") and not w.ends_with("le"):out.remove_at(out.size()-1)
		elif w.ends_with("es") and not "sxzh".contains(w[n-3]):out.remove_at(out.size()-1)
		elif w.ends_with("ed") and not "td".contains(w[n-3]):out.remove_at(out.size()-1)
	if out.is_empty():out.append(0)
	return out

# --- every frame ---------------------------------------------------------------------

func _notification(what:int)->void:
	if what==NOTIFICATION_VISIBILITY_CHANGED:
		if not is_visible_in_tree():_have_aim=false

func _process_modification_with_delta(delta:float)->void:
	step(delta)

## One frame of acting (the skeleton calls it after the clips each frame).
func step(delta:float)->void:
	if skel==null or fig==null or not is_instance_valid(fig):return
	if paused_all or not is_visible_in_tree() or not _view_shown():return
	var t0:=Time.get_ticks_usec()
	_step(delta)
	prof_usec+=Time.get_ticks_usec()-t0
	prof_steps+=1

func _step(delta:float)->void:
	var dt:=clampf(delta,0.0,0.1)
	_clock+=dt
	_acc.fill(Vector3.ZERO)
	_touched.clear()
	_hips_move=Vector3.ZERO
	var walking:=String(fig.get(&"clip")).begins_with("walk") or (_a!=null and String(clip_meta(_a.clip).get("kind",""))=="walk")
	if walking and String(fig.get(&"clip")).begins_with("walk"):
		let_go(0.3)
	_moods(dt)
	# the stance of their own under it all, then the reactions, the fading one first
	if _base_out!=null:
		_base_out.t+=dt
		if _base_out.done():_base_out=null
		else:_sample(_base_out)
	if _base!=null and not walking:
		_base.t+=dt
		_sample(_base)
		if _base_hi!=null:
			_base_hi.t=_base.t
			_sample(_base_hi)
	var face_w:=0.0
	if _b!=null:
		_b.t+=dt*_b.speed
		if _b.done():_b=null
		else:_sample(_b)
	if _a!=null:
		_a.t+=dt*_a.speed
		_cues()
		if _a.done():_a=null
		else:
			_sample(_a)
			face_w=_a.weight()
	# an execution's clip plays as written: no glances, no weight shifts on top
	if _a!=null and _a.exec and _a.weight()>0.3:walking=true
	# the staff stays planted: its hand is held where the clips put it
	_pin_on[1]=1 if String(fig.get(&"stance"))=="staff" and not walking and b_hand[1]>=0 and b_fore[1]>=0 and b_upper[1]>=0 else 0
	for s in 2:
		if _pin_on[s]==1:_pin_at[s]=skel.get_bone_global_pose(b_hand[s])
	_life(dt,walking)
	_gesture(dt)
	_speech(dt)
	_apply_acc()
	_look(dt,walking)
	for s in 2:
		if _pin_on[s]==1:_pin_hand(s)
	_face_out(dt,face_w)
	if _held[0]!=null or _held[1]!=null:_drive_props()
	if not capture_bones.is_empty():
		captured.resize(capture_bones.size())
		for i in capture_bones.size():
			var b:=capture_bones[i]
			captured[i]=skel.global_transform*skel.get_bone_global_pose(b).origin if b>=0 else Vector3.ZERO

## Where a closed fist (0 left, 1 right) holds a handle, from the posed bones
## alone: the origin in the curled fingers, +Y out of the thumb side along the
## handle, +Z where the knuckles point (the same sum as the Blender clips'
## court_anims_exec.fist, so a prop lands where the swing aims it).
func fist_frame(s:int)->Transform3D:
	if b_hand[s]<0 or b_fingers[s]<0 or b_index[s]<0:return Transform3D.IDENTITY
	var g:=skel.global_transform
	var w:=g*skel.get_bone_global_pose(b_hand[s]).origin
	var p:=g*skel.get_bone_global_pose(b_fingers[s]).origin
	var i:=g*skel.get_bone_global_pose(b_index[s]).origin
	var u:=(i-p).normalized()
	var a:=((p-w)-u*(p-w).dot(u)).normalized()
	var n:=a.cross(u) if s==0 else u.cross(a)
	var d:=(i-p).length()
	return Transform3D(Basis(u.cross(a),u,a),p-a*(0.39*d)+n*(0.65*d))

func _drive_props()->void:
	for s in 2:
		var node:Variant=_held[s]
		if node==null:continue
		if not is_instance_valid(node):
			_held[s]=null;continue
		if _a!=null and (_a.t<_a.held_from[s] or _a.t>_a.held_until[s]):continue
		(node as Node3D).global_transform=fist_frame(s)

func _cues()->void:
	var layer:=_a
	if layer==null or layer.events.is_empty() or layer.loop:return
	while layer.ev_i<layer.events.size() and float((layer.events[layer.ev_i] as Dictionary).get("t",0.0))<=layer.t:
		cue.emit(fig,layer.events[layer.ev_i])
		layer.ev_i+=1

func _view_shown()->bool:
	if _view_container==null:
		var vp:=get_viewport()
		if vp is SubViewport and vp.get_parent() is CanvasItem:_view_container=vp.get_parent() as CanvasItem
		else:return true
	return _view_container.is_visible_in_tree()

func _sample(layer:Layer)->void:
	var w:=layer.weight()
	if w<=0.001:return
	var at:=layer.at()
	var map:=layer.map
	var anim:=layer.anim
	var i:=0
	while i<map.size():
		var b:=map[i+1]
		var gw:=layer.weights[b]*w
		if gw>0.001:
			match map[i+2]:
				0:
					var q:=layer.corr[b]*anim.rotation_track_interpolate(map[i],at)
					skel.set_bone_pose_rotation(b,skel.get_bone_pose_rotation(b).slerp(q,gw))
				1:
					var p:=anim.position_track_interpolate(map[i],at)+(layer.hips_off if b==b_hips else Vector3.ZERO)
					skel.set_bone_pose_position(b,skel.get_bone_pose_position(b).lerp(p,gw))
				2:
					var s:=anim.scale_track_interpolate(map[i],at)
					skel.set_bone_pose_scale(b,skel.get_bone_pose_scale(b).lerp(s,gw))
		i+=3

func _add(b:int,x:float,y:float,z:float)->void:
	if b<0:return
	_acc[b]+=Vector3(x,y,z)
	if not _touched.has(b):_touched.append(b)

func _apply_acc()->void:
	for b in _touched:
		var e:=_acc[b]
		if e.length_squared()<1e-8:continue
		var q:=Quaternion.from_euler(Vector3(deg_to_rad(e.x),deg_to_rad(e.y),deg_to_rad(e.z)))
		skel.set_bone_pose_rotation(b,skel.get_bone_pose_rotation(b)*(_rest_gi[b]*q*_rest_g[b]))
	if b_hips>=0 and _hips_move.length_squared()>1e-10:
		skel.set_bone_pose_position(b_hips,skel.get_bone_pose_position(b_hips)+_hips_move)

## The figure's mood (its own words, or what set_mood gave), eased.
func _moods(dt:float)->void:
	if not _mood_explicit:
		var m:=String(fig.get(&"mood")) if fig.get(&"mood")!=null else "neutral"
		if m!=_fig_mood:
			_fig_mood=m
			var d:Dictionary=FIGURE_MOODS.get(m,{})
			for i in M_COUNT:_mood_target[i]=float(d.get(MOODS[i],0.0))
	# a beat's mood comes in quickly, stays its time, goes
	if _beat_t>=0.0:
		_beat_t+=dt
		var w:=smoothstep(0.0,0.15,_beat_t)
		if not _beat_hold:w*=1.0-smoothstep(_beat_len,_beat_len+0.35,_beat_t)
		_beat_w=w
		if not _beat_hold and _beat_t>_beat_len+0.35:
			_beat_t=-1.0;_beat_w=0.0
	var k:=1.0-exp(-dt*2.2)
	var kb:=1.0-exp(-dt*9.0)
	for i in M_COUNT:
		var want:=maxf(_mood_target[i],_beat_mood[i]*_beat_w)
		_mood[i]=lerpf(_mood[i],want,kb if want>_mood[i] and _beat_w>0.0 else k)

## Breathing, a weight shift now and then, sway, the set of a mood, trembling,
## idle fidgets and glances.
func _life(dt:float,walking:bool)->void:
	var fear:=_mood[M_FEAR];var joy:=_mood[M_JOY];var anger:=_mood[M_ANGER];var scorn:=_mood[M_SCORN];var awe:=_mood[M_AWE];var tired:=_mood[M_TIRED]
	var still:=(0.45 if hushed else 1.0)*_still
	_still=minf(1.0,_still+dt*2.0)
	# breath: faster and shallower in fear, slow and deep when tired, held when hushed
	var period:=_breath_period*(1.0-0.35*fear+0.30*tired)*(1.25 if hushed else 1.0)
	_breath=fmod(_breath+dt/period,1.0)
	var br:=sin(TAU*_breath)*(0.75-0.25*fear+0.4*tired)*(0.6 if hushed else 1.0)
	_add(b_spine,-0.5*br,0.0,0.0);_add(b_chest,-0.9*br,0.0,0.0);_add(b_neck,0.4*br,0.0,0.0);_add(b_head,0.5*br,0.0,0.0)
	_add(b_sh[0],0.0,0.0,0.7*br);_add(b_sh[1],0.0,0.0,-0.7*br)
	if walking:return
	# weight from foot to foot every so often
	_shift_wait-=dt*ambient*still
	if _shift_wait<=0.0 and _shift_u>=1.0:
		_shift_from=_shift;_shift_to=(rng.randf_range(0.5,1.0)*(-1.0 if _shift>0.0 else 1.0)) if rng.randf()<0.8 else 0.0
		_shift_u=0.0;_shift_wait=rng.randf_range(8.0,20.0)
	if _shift_u<1.0:
		_shift_u=minf(1.0,_shift_u+dt/1.5)
		_shift=lerpf(_shift_from,_shift_to,smoothstep(0.0,1.0,_shift_u))
	var s:=_shift+0.35*scorn
	if String(fig.get(&"stance")) in SEATED:
		# a sitter shifts on the seat: the body leans a little, the hips stay
		_add(b_spine,0.0,-0.5*s,1.4*s);_add(b_chest,0.0,-0.4*s,0.8*s);_add(b_head,0.0,0.4*s,-0.6*s)
	else:
		_hips_move+=_hips_side*(0.011*s*body_k)
		_add(b_hips,0.0,1.0*s,-1.6*s)
		_add(b_thigh[0],0.0,0.0,1.6*s);_add(b_thigh[1],0.0,0.0,1.6*s)
		_add(b_spine,0.0,-0.4*s,1.0*s);_add(b_chest,0.0,-0.3*s,0.8*s);_add(b_head,0.0,0.3*s,-0.5*s)
	# a slow sway nobody chooses
	var c:=_clock+_seed*40.0
	var n1:=sin(c*0.71)*0.6+sin(c*1.13+1.7)*0.4
	var n2:=sin(c*0.53+0.4)*0.6+sin(c*0.97+2.9)*0.4
	var n3:=sin(c*0.37+1.1)*0.5+sin(c*0.83+0.3)*0.5
	_add(b_head,0.5*n2*still,0.9*n1*still,0.4*n3*still)
	_add(b_chest,0.2*n3*still,0.3*n1*still,0.3*n2*still)
	# the set of the mood
	_add(b_spine,2.0*fear+3.5*tired-0.5*joy,0.0,0.0)
	_add(b_chest,3.0*fear+1.5*anger+3.0*tired-2.0*joy-3.0*awe-1.0*scorn,0.0,0.0)
	_add(b_neck,2.0*fear+1.0*anger-2.0*awe,0.0,0.0)
	_add(b_head,5.0*fear+3.0*anger+6.0*tired-2.0*joy-5.0*awe-4.0*scorn,0.0,-3.0*scorn)
	for sd in 2:
		var m:=1.0 if sd==0 else -1.0
		_add(b_sh[sd],0.0,m*(-4.0*fear+2.0*anger),m*(6.0*fear+2.0*anger-3.0*tired))
	# dread shakes them
	var shake:=clampf((fear-0.45)*2.0,0.0,1.0)
	_tremble=lerpf(_tremble,shake,1.0-exp(-dt*3.0))
	if _tremble>0.01:
		var a:=_tremble
		var t1:=sin(TAU*(9.1*_clock+_seed))*0.6+sin(TAU*(13.7*_clock+0.3))*0.4
		var t2:=sin(TAU*(7.3*_clock+0.6))*0.6+sin(TAU*(11.9*_clock+0.1+_seed))*0.4
		_add(b_head,0.8*a*t2,0.0,0.7*a*t1);_add(b_chest,0.4*a*t1,0.0,0.3*a*t2)
		_add(b_sh[0],0.0,0.0,1.0*a*t1);_add(b_sh[1],0.0,0.0,-1.0*a*t1)
		_add(b_hand[0],1.5*a*t2,0.0,1.2*a*t1);_add(b_hand[1],1.5*a*t1,0.0,1.2*a*t2)
	# now and then, a small fidget of their own (never while hushed, speaking or reacting)
	_fidget_wait-=dt*ambient
	if _fidget_wait<=0.0:
		_fidget_wait=rng.randf_range(25.0,60.0)
		if not hushed and not speaking and _a==null and ambient>0.3:
			if _free_hands().contains("R") and has_clip("scratch_head") and rng.randf()<0.6:act("scratch_head")
			else:do_gesture("settle",0.8)

## The small procedural gestures (additive on whatever the body is doing).
func _gesture(dt:float)->void:
	if _g<0:return
	_g_t+=dt
	var length:float=GESTURE_LEN[_g]
	var u:=_g_t/length
	if u>=1.0:_g=-1;return
	var a:=_g_amount
	var env:=smoothstep(0.0,0.12,u)*(1.0-smoothstep(0.75,1.0,u))
	match _g:
		0: # nod
			var p:=pow(sin(PI*u),1.4)
			_add(b_head,9.0*a*p,0.0,0.0);_add(b_neck,3.0*a*p,0.0,0.0)
		1: # nod eagerly: three quick nods, brows up, a smile
			var p:=maxf(0.0,sin(TAU*2.6*u))*(1.0-u*0.6)
			_add(b_head,11.0*a*p,0.0,0.0);_add(b_neck,4.0*a*p,0.0,0.0);_add(b_chest,2.0*a*p,0.0,0.0)
			_face[CH_BROWS]+=0.45*a*env;_face[CH_SMILE]+=0.45*a*env
		2: # shake the head: no
			var y:=sin(TAU*2.4*u)*(1.0-u)
			_add(b_head,1.5*a*env,13.0*a*y,0.0);_add(b_neck,0.0,4.0*a*y,0.0)
			_face[CH_TIGHT]+=0.35*a*env;_face[CH_BROWS]-=0.2*a*env
		3: # tilt: puzzled, curious
			_add(b_head,2.0*a*env,2.0*a*env*_g_dir,-9.0*a*env*_g_dir);_add(b_neck,0.0,0.0,-2.0*a*env*_g_dir)
			_face[CH_BROWS]+=0.4*a*env;_face[CH_WORRY]+=0.2*a*env
		4: # shrug
			var up:=smoothstep(0.0,0.2,u)*(1.0-smoothstep(0.55,0.9,u))
			_add(b_sh[0],0.0,-3.0*a*up,14.0*a*up);_add(b_sh[1],0.0,3.0*a*up,-14.0*a*up)
			_add(b_head,-1.0*a*up,0.0,-5.0*a*up*_g_dir);_add(b_chest,-1.5*a*up,0.0,0.0)
			_face[CH_BROWS]+=0.7*a*up;_face[CH_TIGHT]+=0.35*a*up;_face[CH_FROWN]+=0.25*a*up
		5: # double take: a glance, away again, then the snap back with wide eyes
			var g1:=smoothstep(0.05,0.15,u)*(1.0-smoothstep(0.22,0.34,u))
			var g2:=smoothstep(0.5,0.58,u)*(1.0-smoothstep(0.85,1.0,u))
			_add(b_head,-2.0*a*g2,(10.0*g1+20.0*g2)*a*_g_dir,0.0);_add(b_neck,0.0,6.0*a*g2*_g_dir,0.0);_add(b_chest,-2.0*a*g2,3.0*a*g2*_g_dir,0.0)
			_face[CH_LIDS]+=0.35*a*g2;_face[CH_BROWS]+=0.9*a*g2;_face[CH_JAW]+=0.25*a*g2
		6: # jolt: startled awake, or by a sound
			var j:=(1.0-smoothstep(0.0,1.0,u))*smoothstep(0.0,0.05,u)
			_hips_move+=Vector3(0.0,0.012*a*j*body_k,0.0)
			_add(b_chest,-4.0*a*j,0.0,0.0);_add(b_head,-7.0*a*j,0.0,0.0)
			_add(b_sh[0],0.0,0.0,8.0*a*j);_add(b_sh[1],0.0,0.0,-8.0*a*j)
			_face[CH_LIDS]+=0.4*a*j;_face[CH_BROWS]+=0.8*a*j
		7: # settle: a breath out, shoulders down
			var e:=sin(PI*u)
			_add(b_chest,2.5*a*e,0.0,0.0);_add(b_head,2.0*a*e,0.0,0.0)
			_add(b_sh[0],0.0,0.0,-4.0*a*e);_add(b_sh[1],0.0,0.0,4.0*a*e)
			_face[CH_LIDS]-=0.15*a*e
		8: # a small flinch
			var f:=(1.0-smoothstep(0.1,1.0,u))*smoothstep(0.0,0.06,u)
			_add(b_head,-5.0*a*f,6.0*a*f*_g_dir,0.0);_add(b_sh[0],0.0,0.0,7.0*a*f);_add(b_sh[1],0.0,0.0,-7.0*a*f)
			_face[CH_LIDS]-=0.6*a*f;_face[CH_TIGHT]+=0.5*a*f
		9: # a hard swallow: the chin dips and comes up, the shoulders rise a little
			var g:=sin(PI*smoothstep(0.1,0.55,u))
			_add(b_head,4.0*a*g,0.0,0.0);_add(b_neck,2.0*a*g,0.0,0.0)
			_add(b_sh[0],0.0,0.0,3.0*a*g);_add(b_sh[1],0.0,0.0,-3.0*a*g)
			_face[CH_TIGHT]+=0.6*a*env;_face[CH_WORRY]+=0.4*a*env;_face[CH_LIDS]+=0.15*a*g
		10: # trembling all over
			_tremble=maxf(_tremble,a*env)
		11: # freeze: no breath, no sway, eyes wide
			_still=minf(_still,1.0-env)
			_face[CH_LIDS]+=0.3*a*env
		12: # straighten up: chest out, chin up, shoulders back
			_add(b_chest,-4.0*a*env,0.0,0.0);_add(b_spine,-2.0*a*env,0.0,0.0);_add(b_head,-3.0*a*env,0.0,0.0)
			_add(b_sh[0],0.0,3.0*a*env,0.0);_add(b_sh[1],0.0,-3.0*a*env,0.0)
		13: # shift the weight now
			_shift_wait=0.0
		14: # two slow grave nods (agreeing, as if they had said it)
			var p:=pow(maxf(0.0,sin(TAU*u*2.0)),1.3)*env
			_add(b_head,8.0*a*p,0.0,0.0);_add(b_neck,3.0*a*p,0.0,0.0);_add(b_chest,1.5*a*p,0.0,0.0)
			_face[CH_STERN]+=0.35*a*env;_face[CH_TIGHT]+=0.35*a*env
		15: # a look round the room: one way, the other, back
			var y:=sin(TAU*u)*(1.0-smoothstep(0.85,1.0,u))
			_add(b_head,-2.0*a*env,0.0,22.0*a*y*_g_dir);_add(b_neck,0.0,0.0,8.0*a*y*_g_dir);_add(b_chest,0.0,0.0,4.0*a*y*_g_dir)
			_face[CH_BROWS]+=0.4*a*env;_face[CH_EYES_X]+=0.8*y*_g_dir
		16: # deflate: the shoulders sink, the chest drops, the head goes down a little
			var d:=smoothstep(0.0,0.4,u)*(1.0-smoothstep(0.75,1.0,u))
			_add(b_chest,6.0*a*d,0.0,0.0);_add(b_spine,3.0*a*d,0.0,0.0);_add(b_head,6.0*a*d,0.0,0.0)
			_add(b_sh[0],0.0,3.0*a*d,-6.0*a*d);_add(b_sh[1],0.0,-3.0*a*d,6.0*a*d)
			_face[CH_WORRY]+=0.5*a*d;_face[CH_LIDS]-=0.15*a*d
		17: # lean in, eager, to catch an eye
			_add(b_spine,4.0*a*env,0.0,0.0);_add(b_chest,3.0*a*env,0.0,0.0);_add(b_head,-6.0*a*env,0.0,-4.0*a*env*_g_dir)
			_hips_move+=Vector3(0.0,0.0,0.02*a*env*body_k)
			_face[CH_BROWS]+=0.5*a*env;_face[CH_SMILE]+=0.3*a*env;_face[CH_LIDS]+=0.12*a*env
		18: # a proud nod: chest up, one slow nod
			var n:=pow(maxf(0.0,sin(PI*clampf((u-0.2)/0.6,0.0,1.0))),1.2)
			_add(b_chest,-4.0*a*env,0.0,0.0);_add(b_head,-3.0*a*env+9.0*a*n,0.0,0.0)
			_face[CH_SMILE]+=0.4*a*env
		19: # a jerk of the head toward a side: come on
			var j:=sin(PI*clampf(u/0.45,0.0,1.0))
			_add(b_head,-3.0*a*j,0.0,18.0*a*j*_g_dir);_add(b_neck,0.0,0.0,6.0*a*j*_g_dir)
			_face[CH_STERN]+=0.4*a*env;_face[CH_BROWS]-=0.3*a*env
		20: # nodding, and nodding, and nodding
			var p:=maxf(0.0,sin(TAU*4.5*u))*env
			_add(b_head,9.0*a*p,0.0,0.0);_add(b_neck,3.0*a*p,0.0,0.0)
			_face[CH_SMILE]+=0.4*a*env;_face[CH_BROWS]+=0.3*a*env

## The mouth on the words, beats of the head, and gestures on cue.
func _speech(dt:float)->void:
	_face[CH_JAW]=0.0
	if _speech_t<0.0:speaking=false;return
	_speech_t+=dt
	if _speech_t>_speech_len:
		_speech_t=-1.0;speaking=false;return
	while _syl_i<_syl_t.size()-1 and _speech_t>=_syl_t[_syl_i+1]:_syl_i+=1
	var open:=0.0
	if not _syl_t.is_empty():
		var st:=_syl_t[_syl_i]
		var x:=(_speech_t-st)/maxf(_syl_len[_syl_i],0.01)
		if x>=0.0 and x<=1.15:
			var shape:=_syl_shape[_syl_i]
			var env:=smoothstep(0.0,0.3,x)*(1.0-smoothstep(0.6,1.1,x))
			if shape==3:open=-0.35*(1.0-smoothstep(0.0,0.5,x))
			elif shape==4:open=0.1*env
			else:open=_syl_open[_syl_i]*env
			_viseme(shape,env)
	_face[CH_JAW]=open
	# a beat of the head on a stressed word
	while _beat_i<_beats.size() and _speech_t>=_beats[_beat_i]:
		_beat_at=_speech_t;_beat_i+=1
	var since:=_speech_t-_beat_at
	if since>=0.0 and since<0.45:
		var p:=sin(PI*since/0.45)
		_add(b_head,5.0*p,0.0,0.0);_add(b_neck,1.5*p,0.0,0.0)
		_face[CH_BROWS]+=0.3*p
	# a slow turn of the head through the sentence
	_add(b_head,0.0,2.0*sin(_speech_t*1.3+_seed*6.0),1.5*sin(_speech_t*0.9))
	while _gest_i<_gest_t.size() and _speech_t>=_gest_t[_gest_i]:
		var held:=_a!=null and _a.hold
		if not held:act(_gest_clip[_gest_i])
		_gest_i+=1

func _has_visemes()->bool:
	return _vis_key[0]>=0

func _viseme(shape:int,amount:float)->void:
	if shape>=0 and shape<_vis_amt.size():_vis_amt[shape]=amount

## Head, neck and chest turn toward what they attend to, on a spring.
func _look(dt:float,walking:bool)->void:
	if b_head<0 or b_neck<0:return
	var target:=Vector3.ZERO
	var want:=0.0
	var have:=false
	match _look_kind:
		1:target=_look_point;have=true
		2:
			if is_instance_valid(_look_node):target=_look_node.global_position;have=true
		3:
			if is_instance_valid(_look_node):target=(_look_node.call(&"head_top") as Vector3)-Vector3(0.0,0.10*_look_node.global_transform.basis.get_scale().y,0.0);have=true
	if have:
		want=_look_weight
	elif bool(fig.get(&"_gaze_on")) and fig.get(&"gaze") is Node3D:
		# the stage's own gaze point (court_figure_3d look_at_point), as strongly as it asks
		target=(fig.get(&"gaze") as Node3D).global_position;have=true;want=_gaze_weight()
	elif not walking:
		# idle: glances about the hall, never out at the viewer
		_glance_wait-=dt*(0.5 if hushed else 1.0)
		if _glance_wait<=0.0 or _glance==Vector3.ZERO:
			_glance_wait=rng.randf_range(2.5,7.0)
			_glance=_pick_glance()
		target=_glance;have=true;want=0.6*ambient
	# a reaction that moves the head has it: idle glances stop, a look asked
	# for keeps only a little pull (a talking gesture keeps the look whole)
	var taken:=_head_taken()
	if taken>0.0:want*=1.0-taken*(1.0 if _look_kind==0 and not bool(fig.get(&"_gaze_on")) else 0.7)
	_look_w=lerpf(_look_w,want,1.0-exp(-dt*(9.0 if taken>0.0 else 4.0)))
	if not have or _look_w<0.01:
		look_yaw=0.0;return
	var to_skel:=skel.global_transform.affine_inverse()
	var head_g:=skel.get_bone_global_pose(b_head)
	var eye:=head_g.origin+head_g.basis.get_rotation_quaternion()*_rest_gi[b_head]*Vector3(0.0,0.10*body_k,0.08*body_k)
	var d:=(to_skel*target)-eye
	if d.length_squared()<1e-6:return
	d=d.normalized()
	var want_yaw:=rad_to_deg(atan2(d.x,d.z))
	var want_pitch:=rad_to_deg(-asin(clampf(d.y,-1.0,1.0)))
	want_yaw=clampf(want_yaw,-80.0,80.0)
	want_pitch=clampf(want_pitch,-38.0,32.0)
	if not _have_aim:
		_yaw=want_yaw;_pitch=want_pitch;_yaw_v=0.0;_pitch_v=0.0;_have_aim=true
	elif absf(want_yaw-_yaw)>25.0 and _blink_t<0.0:
		_blink_wait=0.0   # people blink as they turn their head far
	# a spring: eases out, a little past, settles (about 0.35 s for a big turn)
	var w0:=11.0
	var zeta:=0.78
	var steps:=int(ceil(dt/0.0167))
	var h:=dt/float(maxi(steps,1))
	for i in steps:
		_yaw_v+=((want_yaw-_yaw)*w0*w0-_yaw_v*2.0*zeta*w0)*h;_yaw+=_yaw_v*h
		_pitch_v+=((want_pitch-_pitch)*w0*w0-_pitch_v*2.0*zeta*w0)*h;_pitch+=_pitch_v*h
	# where the head faces now (the clip and everything above)
	var face:=head_g.basis.get_rotation_quaternion()*_rest_gi[b_head]*Vector3.BACK
	var cur_yaw:=rad_to_deg(atan2(face.x,face.z))
	var cur_pitch:=rad_to_deg(-asin(clampf(face.y,-1.0,1.0)))
	var dyaw:=clampf(wrapf(_yaw-cur_yaw,-180.0,180.0),-75.0,75.0)*_look_w
	var dpitch:=clampf(_pitch-cur_pitch,-40.0,35.0)*_look_w
	look_yaw=dyaw
	# the eyes: small jumps while they attend, and they lead a turn of the head
	_saccade_wait-=dt
	if _saccade_wait<=0.0:
		_saccade_wait=rng.randf_range(0.35,1.8)*(0.6 if speaking else 1.0)
		_saccade=Vector2(rng.randf_range(-0.14,0.14),rng.randf_range(-0.08,0.08))
	var lead:=clampf((want_yaw-cur_yaw-dyaw)/35.0,-1.0,1.0)*_look_w
	_face[CH_EYES_X]+=lead
	_face[CH_EYES_Y]+=clampf(-(want_pitch-cur_pitch-dpitch)/30.0,-1.0,1.0)*_look_w
	# shared down the neck: the chest a little, the neck more, the head the rest
	var spine_g:=skel.get_bone_global_pose(b_spine).basis.get_rotation_quaternion() if b_spine>=0 else Quaternion.IDENTITY
	var chest_l:=skel.get_bone_pose_rotation(b_chest) if b_chest>=0 else Quaternion.IDENTITY
	var chest_g:=spine_g*chest_l
	if b_chest>=0:
		var qc:=Quaternion(Vector3.UP,deg_to_rad(0.18*dyaw))
		chest_l=spine_g.inverse()*qc*spine_g*chest_l
		skel.set_bone_pose_rotation(b_chest,chest_l)
		chest_g=spine_g*chest_l
	var neck_l:=skel.get_bone_pose_rotation(b_neck)
	var neck_g:=chest_g*neck_l
	var right:=(neck_g*_rest_gi[b_neck]*Vector3.RIGHT).normalized()
	var qn:=Quaternion(Vector3.UP,deg_to_rad(0.35*dyaw))*Quaternion(right,deg_to_rad(0.42*dpitch))
	neck_l=chest_g.inverse()*qn*chest_g*neck_l
	skel.set_bone_pose_rotation(b_neck,neck_l)
	neck_g=chest_g*neck_l
	var head_l:=skel.get_bone_pose_rotation(b_head)
	var head_q:=neck_g*head_l
	right=(head_q*_rest_gi[b_head]*Vector3.RIGHT).normalized()
	var qh:=Quaternion(Vector3.UP,deg_to_rad(0.47*dyaw))*Quaternion(right,deg_to_rad(0.58*dpitch))
	skel.set_bone_pose_rotation(b_head,neck_g.inverse()*qh*neck_g*head_l)

## How much the reactions playing now drive the head (0..1).
func _head_taken()->float:
	var w:=0.0
	for layer:Layer in [_a,_b]:
		if layer==null or b_head<0:continue
		if String(clip_meta(layer.clip).get("kind",""))=="talk":continue
		w=maxf(w,layer.weight()*layer.weights[b_head])
	return clampf(w,0.0,1.0)

func _gaze_weight()->float:
	var looks:Variant=fig.get(&"_looks")
	if looks is Array:
		for m in looks:
			if m is SkeletonModifier3D and String((m as Node).name)=="Look_head":
				var full:=float((m as Object).get_meta("weight",0.85))
				return clampf(float((m as Object).get(&"influence"))/maxf(full,0.01),0.0,1.0)
	return 0.95

## The stage this figure stands on (for the god's point and the cast by key).
var _stage_ref:WeakRef
func stage_of()->Object:
	if _stage_ref!=null and _stage_ref.get_ref()!=null:return _stage_ref.get_ref()
	var n:Node=fig
	while n!=null:
		if n.has_method(&"god_point") and n.has_method(&"figure"):
			_stage_ref=weakref(n);return n
		n=n.get_parent()
	return null

## Two-bone IK: the upper arm and forearm turned in their own bend plane so the
## wrist is back on its mark, and the hand set back to its turn.
func _pin_hand(s:int)->void:
	var up:=b_upper[s];var fo:=b_fore[s];var ha:=b_hand[s]
	var g_up:=skel.get_bone_global_pose(up)
	var g_fo:=skel.get_bone_global_pose(fo)
	var g_ha:=skel.get_bone_global_pose(ha)
	var S:=g_up.origin;var E:=g_fo.origin;var W:=g_ha.origin
	var T:=_pin_at[s].origin
	if W.distance_squared_to(T)<1e-8:return
	var a:=S.distance_to(E);var b:=E.distance_to(W)
	var d:=clampf(S.distance_to(T),absf(a-b)+0.001,a+b-0.001)
	var u:=(T-S).normalized()
	var cos_a:=clampf((a*a+d*d-b*b)/(2.0*a*d),-1.0,1.0)
	var pole:=(E-S)-u*(E-S).dot(u)
	if pole.length_squared()<1e-10:return
	pole=pole.normalized()
	var E2:=S+u*(a*cos_a)+pole*(a*sqrt(maxf(0.0,1.0-cos_a*cos_a)))
	var parent:=skel.get_bone_parent(up)
	var g_parent:=skel.get_bone_global_pose(parent) if parent>=0 else Transform3D.IDENTITY
	var q1:=Quaternion((E-S).normalized(),(E2-S).normalized())
	var up_q:=q1*g_up.basis.get_rotation_quaternion()
	skel.set_bone_pose_rotation(up,(g_parent.basis.get_rotation_quaternion().inverse()*up_q).normalized())
	var w1:=E2+q1*(W-E)
	var q2:=Quaternion((w1-E2).normalized(),(T-E2).normalized())
	var fo_q:=q2*q1*g_fo.basis.get_rotation_quaternion()
	skel.set_bone_pose_rotation(fo,(up_q.inverse()*fo_q).normalized())
	skel.set_bone_pose_rotation(ha,(fo_q.inverse()*_pin_at[s].basis.get_rotation_quaternion()).normalized())

func _pick_glance()->Vector3:
	var at:=skel.global_transform*skel.get_bone_global_pose(b_head).origin if b_head>=0 else fig.global_position+Vector3.UP*1.5
	var basis:=fig.global_transform.basis
	var sc:=basis.get_scale().y
	if not glance_points.is_empty() and rng.randf()<0.55:
		return glance_points[rng.randi()%glance_points.size()]
	# the floor before them, or aside at another's head height: down and away from the viewer
	var side:=rng.randf_range(-1.0,1.0)
	var fwd:=(basis*Vector3.BACK).normalized()
	var left:=(basis*Vector3.RIGHT).normalized()
	if rng.randf()<0.5:
		return at+fwd*2.2*sc+left*side*1.1*sc+Vector3.DOWN*1.1*sc
	return at+fwd*1.2*sc+left*signf(side)*1.6*sc+Vector3.DOWN*0.2*sc

## The face: mood, the clip's face, the words and blinks, onto bones and morphs.
func _face_out(dt:float,face_w:float)->void:
	var joy:=_mood[M_JOY];var fear:=_mood[M_FEAR];var anger:=_mood[M_ANGER];var scorn:=_mood[M_SCORN];var awe:=_mood[M_AWE];var tired:=_mood[M_TIRED]
	_mood_face[CH_JAW]=0.2*awe
	_mood_face[CH_SMILE]=0.8*joy
	_mood_face[CH_TIGHT]=0.45*fear+0.35*anger
	_mood_face[CH_WORRY]=0.8*fear+0.25*tired
	_mood_face[CH_STERN]=0.8*anger+0.3*scorn
	_mood_face[CH_BROWS]=0.8*awe+0.3*fear-0.6*anger+0.2*joy
	_mood_face[CH_LIDS]=1.0+0.25*awe+0.12*fear-0.35*tired-0.2*scorn-0.08*anger
	_mood_face[CH_PUFF]=0.0
	_mood_face[CH_SNEER]=0.7*scorn
	_mood_face[CH_EYES_X]=_saccade.x
	_mood_face[CH_EYES_Y]=_saccade.y
	_mood_face[CH_FROWN]=0.35*fear+0.3*tired
	for ch in CH_COUNT:
		var v:=_mood_face[ch]
		if _a!=null and face_w>0.0:
			var curve:PackedFloat32Array=_a.face[ch]
			if not curve.is_empty():v=lerpf(v,_a.face_value(ch,FACE_REST[ch]),face_w)
		v+=_beat_face[ch]*_beat_w
		if ch==CH_JAW:v=maxf(v,0.0)+_face[CH_JAW]
		elif ch==CH_LIDS:v*=_face[CH_LIDS]
		else:v+=_face[ch]
		face_now[ch]=v
	# reset the per-frame additions (rest values)
	for ch in CH_COUNT:_face[ch]=FACE_REST[ch]
	# blinks: shut fast, open slower; now and then twice
	var blink:=1.0
	_blink_wait-=dt*(1.6 if speaking else 1.0)*(1.3 if fear>0.5 else 1.0)
	if _blink_t<0.0 and _blink_wait<=0.0:_blink_t=0.0
	if _blink_t>=0.0:
		_blink_t+=dt
		var x:=_blink_t
		blink=1.0-smoothstep(0.0,0.07,x) if x<0.08 else (0.0 if x<0.10 else smoothstep(0.10,0.22,x))
		if _blink_t>=0.22:
			_blink_t=-1.0
			if not _blink_double and rng.randf()<0.15:_blink_double=true;_blink_wait=0.08
			else:_blink_double=false;_blink_wait=rng.randf_range(2.0,6.0)
	var lids:=clampf(face_now[CH_LIDS],0.05,1.45)*blink
	lids_now=lids
	for s in 2:
		var b:=b_eye[s]
		if b<0 or _x_key[4]>=0:continue
		var sc:=Vector3.ONE
		sc[_eye_axis[s]]=maxf(lids,0.05)
		skel.set_bone_pose_scale(b,sc)
	# the jaw: the words' shapes, or what the clip and mood give it
	if b_jaw>=0 and _x_key[0]<0:
		var cur:=skel.get_bone_pose_scale(b_jaw)
		var jaw:=face_now[CH_JAW]
		var sc:=Vector3.ONE
		var open:=1.0+1.5*jaw
		if not speaking:open=maxf(open,cur[_jaw_v])
		sc[_jaw_v]=maxf(0.45,open)
		if speaking and _syl_i<_syl_shape.size():
			var shape:=_syl_shape[_syl_i]
			if shape==2:sc[_jaw_h]=0.78
			elif shape==1:sc[_jaw_h]=1.12
		skel.set_bone_pose_scale(b_jaw,sc)
	# brows up and down
	var lift:=clampf(face_now[CH_BROWS],-1.2,1.4)*0.0045*body_k
	for s in 2:
		var b:=b_brow[s]
		if b<0 or _x_key[1]>=0:continue
		skel.set_bone_pose_position(b,skel.get_bone_pose_position(b)+_brow_up[s]*lift)
	# the morphs
	_sk_value.fill(0.0)
	for i in _vis_from.size():_sk_value[_vis_to[i]]+=_vis_amt[_vis_from[i]]
	_vis_amt.fill(0.0)
	for i in _sk_from_ch.size():
		var ch:=_sk_from_ch[i]
		if ch<0:continue
		_sk_value[_sk_from_key[i]]+=face_now[ch]*_sk_from_gain[i]
	# the jaw, brows and lids on their morphs (J's: eyes_wide is 1.28 open, blink 0.06)
	_x_amt[0]=clampf(face_now[CH_JAW],0.0,1.0) if not (speaking and _has_visemes() and _lod==2) else 0.0
	_x_amt[1]=maxf(0.0,face_now[CH_BROWS])
	_x_amt[2]=maxf(0.0,-face_now[CH_BROWS])
	_x_amt[3]=maxf(0.0,(lids-1.0)/0.28)
	_x_amt[4]=maxf(0.0,(1.0-lids)/0.94)
	for i in _x_from.size():_sk_value[_x_to[i]]+=_x_amt[_x_from[i]]
	# A face too small on screen to read keeps its morphs at rest: every morph
	# at any weight costs a pass over its mesh each frame. Small weights snap
	# to 0 for the same reason; only real changes are written; now and then
	# what the meshes hold is compared (anything else that set one is undone).
	var lod:=_face_lod(dt)
	_refresh-=dt
	var check:=_refresh<=0.0
	if check:_refresh=0.5
	for k in _sk_value.size():
		var v:=clampf(_sk_value[k],0.0,1.0)
		if v<MORPH_FLOOR or lod==0 or (lod==1 and not _sk_low[k]):v=0.0
		if absf(v-_sk_last[k])>MORPH_STEP or (v==0.0 and _sk_last[k]!=0.0) or check:
			var m:=_sk_mesh[k]
			if not is_instance_valid(m):continue
			if check and absf(m.get_blend_shape_value(_sk_index[k])-v)<=MORPH_STEP*0.5 and _sk_last[k]>=0.0:continue
			_sk_last[k]=v
			m.set_blend_shape_value(_sk_index[k],v)
			prof_morph_writes+=1

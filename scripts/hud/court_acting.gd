class_name CourtActing
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
## Use (static, on a CourtFigure3D):
##   CourtActing.play(fig, "gasp", {blend, loop, speed, hold, out})  -> seconds
##   CourtActing.look_at(fig, Vector3 | figure Node3D | null, weight)
##   CourtActing.set_mood(fig, {joy, fear, anger, scorn, awe, tired})
##   CourtActing.speak(fig, text, seconds)
##   CourtActing.idle(fig, stance_id)
##   CourtActing.gesture(fig, "nod" | "nod_eager" | "shake" | "tilt" | "shrug" | "double_take" | "jolt" | "settle" | "flinch_small")
##   CourtActing.hush(fig, true)    the god speaks: stillness
##   CourtActing.stop(fig)          let go of a held reaction
## Figure axes (skeleton space): +X the figure's left, +Y up, +Z its front.

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
const GESTURES:=["nod","nod_eager","shake","tilt","shrug","double_take","jolt","settle","flinch_small"]
const GESTURE_LEN:=[0.65,1.35,1.25,1.7,1.5,1.3,0.8,1.6,0.7]
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
## Where the eyes look, if the face has morphs for it: [morph, channel, gain].
const EYE_SHAPES:=[["eyes_left",9,1.0],["eyes_right",9,-1.0],["eyes_up",10,1.0],["eyes_down",10,-1.0]]
## Talking gestures speech may use: [clip, hands it needs, what the line is like].
const TALK_GESTURES:=[["talk_emphatic","R","!"],["talk_hesitant","LR","?"],["talk_plead","LR","?"],["talk_explain","R","."],["talk_one","R","."],["talk_dismiss","R","-"]]

static var _manifest:Dictionary={}
static var _anims:Dictionary={}
static var _maps:Dictionary={}
static var _faces:Dictionary={}
## The whole court is out of sight (its window closed): nobody is moved.
static var paused_all:=false

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
	var fade_from:=-1.0
	var fade_len:=0.4
	var gain:=1.0
	var face_fps:=15.0

	func weight()->float:
		var w:=1.0
		if blend_in>0.0:w=smoothstep(0.0,blend_in,t)
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
	var path:=DIR+file
	if ResourceLoader.exists(path):
		var packed:=load(path) as PackedScene
		var made:Node=packed.instantiate() if packed!=null else null
		if made!=null:
			for node in made.find_children("*","AnimationPlayer",true,false):
				var player:=node as AnimationPlayer
				for name:StringName in player.get_animation_list():
					var clean:=String(name).get_slice("/",String(name).get_slice_count("/")-1)
					out[clean]=player.get_animation(name)
			made.free()
	_anims[variant]=out
	return out

## The AnimationLibrary of one body, for anyone who wants to play the clips on an AnimationPlayer.
static func animation_library(variant:String)->AnimationLibrary:
	var lib:=AnimationLibrary.new()
	var anims:=library(variant)
	for name:String in anims:lib.add_animation(StringName(name),anims[name])
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

## The acting on a figure (made the first time it is asked for).
static func of(fig:Node3D)->CourtActing:
	if fig==null or not is_instance_valid(fig):return null
	var existing:Variant=fig.get_meta(&"court_acting",null)
	var skel:=fig.get(&"skeleton") as Skeleton3D
	if existing is CourtActing and is_instance_valid(existing) and (existing as CourtActing).skel==skel:return existing
	if skel==null:return null
	var actor:=CourtActing.new()
	actor.name="Acting"
	actor._bind(fig,skel)
	skel.add_child(actor)
	fig.set_meta(&"court_acting",actor)
	return actor

static func play(fig:Node3D,clip:String,opts:={})->float:
	var a:=of(fig)
	return a.act(clip,opts) if a!=null else 0.0

static func look_at(fig:Node3D,target:Variant,weight:=1.0)->void:
	var a:=of(fig)
	if a!=null:a.look(target,weight)

static func set_mood(fig:Node3D,mood:Dictionary)->void:
	var a:=of(fig)
	if a!=null:a.feel(mood)

static func speak(fig:Node3D,text:String,seconds:float,opts:={})->void:
	var a:=of(fig)
	if a!=null:a.talk(text,seconds,opts)

static func idle(fig:Node3D,stance_id:String)->void:
	var a:=of(fig)
	if a!=null:a.rest_in(stance_id)

static func gesture(fig:Node3D,name:String,amount:=1.0,toward:=1.0)->void:
	var a:=of(fig)
	if a!=null:a.do_gesture(name,amount,toward)

static func hush(fig:Node3D,on:=true)->void:
	var a:=of(fig)
	if a!=null:a.hushed=on

static func stop(fig:Node3D,blend:=-1.0)->void:
	var a:=of(fig)
	if a!=null:a.let_go(blend)

## How lively the idle life is (fidgets, glances, shifts): 0 still .. 1 as people are.
static func set_ambient(fig:Node3D,level:float)->void:
	var a:=of(fig)
	if a!=null:a.ambient=clampf(level,0.0,1.0)

## Points in the hall an idle glance may fall on (neighbours, the fire, a gift).
static func set_glance_points(fig:Node3D,points:PackedVector3Array)->void:
	var a:=of(fig)
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
var _eye_axis:=PackedInt32Array([1,1])
var _jaw_v:=1
var _jaw_h:=0
var _brow_up:=PackedVector3Array([Vector3.UP,Vector3.UP])
var _hips_side:=Vector3.RIGHT
var _groups:Dictionary={}

var _a:Layer
var _b:Layer

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

func _bind_face()->void:
	var meshes:Array=[]
	var listed:Variant=fig.get(&"_meshes")
	if listed is Array:
		for m in listed:
			if m is MeshInstance3D and String((m as MeshInstance3D).name) in ["Mouth","Brows","Eyes","Body"]:meshes.append(m)
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
	for v in VISEMES.size():
		for m:MeshInstance3D in meshes:
			var idx:=m.find_blend_shape_by_name(StringName(VISEMES[v]))
			if idx<0:continue
			_vis_key[v]=_sk_mesh.size()
			_sk_mesh.append(m);_sk_index.append(idx);_sk_value.append(0.0);_sk_last.append(-1.0)
			break

# --- instance API ----------------------------------------------------------------------

func act(clip:String,opts:={})->float:
	if not has_clip(clip):
		# not ours: the figure's own clip, on its own player
		if fig.has_method(&"play") and fig.get(&"player")!=null and (fig.get(&"player") as AnimationPlayer).has_animation(clip):
			fig.call(&"play",clip,float(opts.get("blend",0.3)),0.0)
			return float(fig.call(&"clip_length",clip))
		return 0.0
	var meta:=clip_meta(clip)
	var layer:=Layer.new()
	layer.clip=clip
	layer.anim=library(variant).get(clip)
	if layer.anim==null:return 0.0
	layer.map=_map_for(variant,clip,skel)
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
	if _a!=null and not _a.done():
		_b=_a
		_b.fade_from=_b.t
		_b.fade_len=maxf(layer.blend_in,0.12)
	_a=layer
	return layer.length/layer.speed

func _weights_for(meta:Dictionary,opts:Dictionary)->PackedFloat32Array:
	var w:=PackedFloat32Array()
	w.resize(_n);w.fill(0.0)
	var groups:Dictionary=(meta.get("groups",{}) as Dictionary).duplicate()
	for k:String in (opts.get("groups",{}) as Dictionary):groups[k]=float(opts.groups[k])
	var stance:=String(fig.get(&"stance"))
	if stance in SEATED and not bool(opts.get("force_legs",false)):groups["legs"]=0.0
	if PROP_ARMS.has(stance) and not bool(opts.get("drop_prop",false)):
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
	_mood_explicit=true
	for i in M_COUNT:_mood_target[i]=clampf(float(mood.get(MOODS[i],0.0)),0.0,1.0)

func rest_in(stance_id:String)->void:
	let_go(0.45)
	if fig.get(&"stance")!=null and stance_id in (_consts.get("STANCES",[]) as Array):
		fig.set(&"stance",stance_id)
	if fig.has_method(&"rest_clip") and fig.has_method(&"play"):
		fig.call(&"play",String(fig.call(&"rest_clip")),0.45,-1.0)

func let_go(blend:=-1.0)->void:
	for layer in [_a,_b]:
		if layer!=null and (layer as Layer).fade_from<0.0:
			(layer as Layer).fade_from=(layer as Layer).t
			(layer as Layer).fade_len=blend if blend>0.0 else (layer as Layer).blend_out

func do_gesture(name:String,amount:=1.0,toward:=1.0)->void:
	var i:=GESTURES.find(name)
	if i<0:return
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
	for raw in text.replace("
"," ").split(" ",false):
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
	# a final silent e
	if w.length()>3 and w.ends_with("e") and out.size()>2:out.remove_at(out.size()-1)
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
	var dt:=clampf(delta,0.0,0.1)
	_clock+=dt
	_acc.fill(Vector3.ZERO)
	_touched.clear()
	_hips_move=Vector3.ZERO
	var walking:=String(fig.get(&"clip")).begins_with("walk")
	if walking:
		let_go(0.3)
	_moods(dt)
	# the reaction layers, the fading one first
	var face_w:=0.0
	if _b!=null:
		_b.t+=dt*_b.speed
		if _b.done():_b=null
		else:_sample(_b)
	if _a!=null:
		_a.t+=dt*_a.speed
		if _a.done():_a=null
		else:
			_sample(_a)
			face_w=_a.weight()
	_life(dt,walking)
	_gesture(dt)
	_speech(dt)
	_apply_acc()
	_look(dt,walking)
	_face_out(dt,face_w)
	if not capture_bones.is_empty():
		captured.resize(capture_bones.size())
		for i in capture_bones.size():
			var b:=capture_bones[i]
			captured[i]=skel.global_transform*skel.get_bone_global_pose(b).origin if b>=0 else Vector3.ZERO

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
					var q:=anim.rotation_track_interpolate(map[i],at)
					skel.set_bone_pose_rotation(b,skel.get_bone_pose_rotation(b).slerp(q,gw))
				1:
					var p:=anim.position_track_interpolate(map[i],at)
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
	var k:=1.0-exp(-dt*2.2)
	for i in M_COUNT:_mood[i]=lerpf(_mood[i],_mood_target[i],k)

## Breathing, a weight shift now and then, sway, the set of a mood, trembling,
## idle fidgets and glances.
func _life(dt:float,walking:bool)->void:
	var fear:=_mood[M_FEAR];var joy:=_mood[M_JOY];var anger:=_mood[M_ANGER];var scorn:=_mood[M_SCORN];var awe:=_mood[M_AWE];var tired:=_mood[M_TIRED]
	var still:=0.45 if hushed else 1.0
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
		# the stage's own gaze point (court_figure_3d look_at_point)
		target=(fig.get(&"gaze") as Node3D).global_position;have=true;want=0.95
	elif not walking:
		# idle: glances about the hall, never out at the viewer
		_glance_wait-=dt*(0.5 if hushed else 1.0)
		if _glance_wait<=0.0 or _glance==Vector3.ZERO:
			_glance_wait=rng.randf_range(2.5,7.0)
			_glance=_pick_glance()
		target=_glance;have=true;want=0.6*ambient
	_look_w=lerpf(_look_w,want,1.0-exp(-dt*4.0))
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
		if b<0:continue
		var sc:=Vector3.ONE
		sc[_eye_axis[s]]=maxf(lids,0.05)
		skel.set_bone_pose_scale(b,sc)
	# the jaw: the words' shapes, or what the clip and mood give it
	if b_jaw>=0:
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
		if b<0:continue
		skel.set_bone_pose_position(b,skel.get_bone_pose_position(b)+_brow_up[s]*lift)
	# the morphs
	_sk_value.fill(0.0)
	for v in VISEMES.size():
		if _vis_key[v]>=0:_sk_value[_vis_key[v]]+=_vis_amt[v]
	_vis_amt.fill(0.0)
	for i in _sk_from_ch.size():
		var ch:=_sk_from_ch[i]
		if ch<0:continue
		_sk_value[_sk_from_key[i]]+=face_now[ch]*_sk_from_gain[i]
	for k in _sk_value.size():
		var v:=clampf(_sk_value[k],0.0,1.0)
		if absf(v-_sk_last[k])>0.004:
			_sk_last[k]=v
			var m:=_sk_mesh[k]
			if is_instance_valid(m):m.set_blend_shape_value(_sk_index[k],v)

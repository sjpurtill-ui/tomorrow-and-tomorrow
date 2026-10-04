extends Node3D
## One person of the court as a modelled, animated figure.
## The figures are made in Blender by tools/blender/court_figures.py: six
## bodies (male/female, young/adult/old), each one .glb in
## assets/court_figures/ holding every hair style, beard and outfit as
## separate meshes, and every clip (idle, talk, listen, bow, kneel, walk...).
## This node shows one hair, at most one beard and one outfit, colours the
## material slots (SKIN, HAIR, CLOTH_A/B/C, LEATHER...) from a look
## (CourtStage.figure_look makes looks), and plays clips with a short blend.
## Materials are shared between figures of the same colours; nothing here
## runs per frame.
## A look: {variant, outfit, hair, beard, skin, hair_colour, cloth:[a,b,c],
## leather, without:[pieces not worn], stance, face:{shape: -1..1}}.
## Every person keeps a stance for life (standing easy, hand on hip, arms
## folded, hands clasped, thumbs in the belt, leaning on a staff, holding a
## bowl, seated on a log, crouched); their face is their own (morph targets
## from their people's family face); their head turns to whoever they attend
## to (look_at), and their mood shows in brows, mouth and the set of the head.

const DIR:="res://assets/court_figures/"
const TOON:=preload("res://scripts/shaders/court_figure_toon.gdshader")
## Each person's own shade of their people's look (hair, skin, build, dress, stance).
const FigureLook:=preload("res://scripts/hud/court_figure_look.gd")
## In a lit court a person's visible parts are merged into a few pieces.
const Merge:=preload("res://scripts/hud/court_figure_merge.gd")
const Wardrobe:=preload("res://scripts/hud/court_wardrobe.gd")
## In a modelled court (court_set_3d.gd) the figures take the set's own light.
const TOON_LIT:=preload("res://scripts/shaders/court_figure_lit.gdshader")
const INK:=preload("res://scripts/shaders/court_figure_ink.gdshader")
const VARIANTS:=["male_adult","female_adult","male_old","female_old","male_young","female_young"]
## Every body there is: the six grown ones and a child of seven or eight.
const BODIES:=["male_adult","female_adult","male_old","female_old","male_young","female_young","child"]
const OUTFITS:={"hide":1,"tunic":2,"robe":3,"medieval":1,"courtcoat":1,"formal":1,"business":1}
const STANCES:=["stand","hip","folded","clasped","belt","staff","bowl","sit","crouch"]
## Which hands a stance leaves free to talk with (both: "talk_both" can be used).
const FREE_HANDS:={"stand":"LR","hip":"R","folded":"","clasped":"LR","belt":"R","staff":"L","bowl":"","sit":"LR","crouch":"R"}
const PROPS:={"staff":"prop_staff","bowl":"prop_bowl","sit":"prop_stool"}
const LOOP_CLIPS:=["stand","hip","folded","clasped","belt","staff","bowl","sit","crouch",
	"stand_talk","hip_talk","folded_talk","clasped_talk","belt_talk","staff_talk","bowl_talk","sit_talk","crouch_talk","talk_both","walk_in","walk_out"]
const CLIPS:=["stand","hip","folded","clasped","belt","staff","bowl","sit","crouch","stand_talk","talk_both","bow","kneel","point","raise_hand","walk_in","walk_out"]
const FACE_SHAPES:=["jaw","chin","cheek","nose","bridge","nose_wide","brow","lips","ears","long","round","aged"]
## Moods the engine's regard and posture show: [mouth/brow morphs, head pitch (deg, + is down)].
const MOODS:={"warm":[{"mood_smile":0.55},-2.0],"neutral":[{},0.0],"afraid":[{"mood_tight":0.55,"mood_worry":0.7},12.0],
	"defiant":[{"mood_stern":0.65,"mood_tight":0.25},-9.0],"grieved":[{"mood_worry":0.8},8.0]}
const FACE_PARTS:=["Body","Eyes","Brows","Mouth"]
## Slots drawn flat (no light): the painted eyes and mouth.
const FLAT_SLOTS:=["EYES","EYE_WHITE","EYE_SHINE","MOUTH","IRIS","PUPIL"]
## The iris, pupil and catch of light are drawn only over the white of the
## eye (a stencil the white writes), so they roll inside the lids (morphs
## eyes_left/right/up/down) and the lids cut them as they close.
const STENCIL_READ:=["IRIS","PUPIL","EYE_SHINE"]
const STENCIL_WRITE:=["EYE_WHITE"]
## What a person may carry between their hands for a while (a gift of food).
const CARRIED:={"bundle":"prop_bundle","cord":"prop_cord"}
## Face parts that never cast a shadow (they lie on the skin).
const NO_SHADOW:=["Eyes","Brows","Mouth","hair_shaved","beard_stubble"]
## The height every clip is made for; shorter bodies are drawn shorter.
const REFERENCE_HEIGHT:=1.72
## How fast the walk clips carry a 1.72 m body, in metres a second.
const WALK_SPEED:={"walk_in":1.18,"walk_out":0.92}

## Shared materials kept at most (oldest let go; figures already dressed keep theirs).
const MATERIAL_LIMIT:=256
static var _scenes:Dictionary={}
static var _materials:Dictionary={}
static var _shaders:Dictionary={}
static var _inks:Dictionary={}
static var _manifest:Dictionary={}
static var key_dir:=Vector3(-0.35,0.65,0.68)
## Off for a run (tests, or a machine where the models fail): the court falls
## back to its painted figures.
static var enabled:=true

var look:Dictionary={}
var variant:=""
var model:Node3D
var skeleton:Skeleton3D
var player:AnimationPlayer
var clip:=""
## Travel speed / the authored walk speed. Acting walks use this clock too.
var locomotion_rate:=1.0
var head_bone:=-1
var head_height:=0.28
var body_height:=1.72
var _base_height:=1.72
## What is shown and driven (the merged pieces and the props, or the parts).
var _meshes:Array[MeshInstance3D]=[]
## Every part the body's .glb has (hair styles, beards, outfits, face parts, props).
var _parts:Array[MeshInstance3D]=[]
## The merged pieces (Body, Rest, Hair, Eyes) when the figure stands in a lit court.
var _merged:Dictionary={}
var _merge_root:Node3D
var _plain_skin:Mesh
var _wardrobe_skin:Mesh
var _wardrobe_loaded:=false
var _wardrobe_outfit:=""
static var _uber:Array=[]
var _yaw_tween:Tween
## What they keep doing at rest, and the mood the engine gives them.
var stance:="stand"
var mood:="neutral"
## Where they look: a point in the hall, eased toward by the head and neck.
var gaze:Node3D
var _looks:Array[LookAtModifier3D]=[]
var _gaze_tween:Tween
var _gaze_on:=false
## A seat the set gives them (its height): their own stool is not shown.
var seat_height:=-1.0
## The acting may sit on the floor over this figure's ordinary seated clip.
## Its unskinned stool must not remain inside the lowered torso.
var floor_seated:=false:
	set(value):
		floor_seated=value
		_props_for(clip)

static func manifest()->Dictionary:
	if _manifest.is_empty():
		var text:=FileAccess.get_file_as_string(DIR+"court_figures.json")
		var parsed:Variant=JSON.parse_string(text) if not text.is_empty() else null
		_manifest=parsed if parsed is Dictionary else {"variants":[]}
	return _manifest

static func scene_for(variant_name:String)->PackedScene:
	if not variant_name in BODIES:variant_name="male_adult"
	if not _scenes.has(variant_name):
		var path:=DIR+"court_figure_%s.glb" % variant_name
		_scenes[variant_name]=load(path) as PackedScene if ResourceLoader.exists(path) else null
	return _scenes[variant_name]

## Whether the modelled figures can be shown at all.
static func available()->bool:
	return enabled and scene_for("male_adult")!=null

## The shared material for a slot in a colour (skin also knows which outfit
## hides it). lit: in a modelled court, under its lights; inked: an outline.
static func material(slot:String,colour:Color,cover:=0,lit:=false,inked:=true)->ShaderMaterial:
	# Colours are kept to a few steps a channel, so the cache stays small.
	colour=Color(snappedf(colour.r,1.0/48.0),snappedf(colour.g,1.0/48.0),snappedf(colour.b,1.0/48.0))
	var key:="%s|%s|%d|%d|%d" % [slot,colour.to_html(false),cover,int(lit),int(inked)]
	if _materials.has(key):return _materials[key]
	if _materials.size()>=MATERIAL_LIMIT:_materials.erase(_materials.keys()[0])
	var made:=ShaderMaterial.new()
	made.shader=shader_for(lit,"read" if slot in STENCIL_READ else ("write" if slot in STENCIL_WRITE else ("card" if slot=="HAIR_CARD" else "")))
	made.set_shader_parameter("albedo",colour)
	made.set_shader_parameter("cover_channel",cover)
	made.set_shader_parameter("key_dir",key_dir)
	if slot in FLAT_SLOTS:
		made.set_shader_parameter("flat_colour",true)
	else:
		if slot=="SKIN":
			made.set_shader_parameter("shade_tint",Color(0.70,0.52,0.47))
			made.set_shader_parameter("band_soft",0.34)
			# the painted face (court_figure_face.gdshaderinc) and skin's own light
			made.set_shader_parameter("face_paint",true)
			made.set_shader_parameter("skin",true)
			made.set_shader_parameter("terminator",Color(0.30,0.10,0.05))
		if slot=="HAIR_CARD":
			made.set_shader_parameter("card",1.0)
			made.set_shader_parameter("rim_amount",0.30)
			made.set_shader_parameter("sheen",0.18)
			made.set_shader_parameter("grain",0.0)
		if slot=="HAIR":
			made.set_shader_parameter("rim_amount",0.22)
			made.set_shader_parameter("strands",0.24)
			made.set_shader_parameter("sheen",0.22)
			made.set_shader_parameter("band_soft",0.30)
		if slot=="STUBBLE":made.set_shader_parameter("grain",0.35)
		# hair breaks into strokes where it meets the skin (stubble all over)
		if slot in ["HAIR","STUBBLE"]:made.set_shader_parameter("stipple",1.0)
		if lit:
			made.set_shader_parameter("fill",0.22 if slot=="SKIN" else 0.16)
			if slot=="SKIN":made.set_shader_parameter("grain",0.025)
		if inked and not slot in ["BROW","STUBBLE","HAIR_CARD"]:made.next_pass=_ink(cover,slot=="HAIR")
	_materials[key]=made
	return made

## The figure shader: unshaded (painted light) or lit by a set; for the eyes,
## the white writes a stencil and the iris, pupil and catch of light read it
## (drawn after everything solid, so the white is always there first).
static func shader_for(lit:bool,stencil:="")->Shader:
	var base:Shader=TOON_LIT if lit else TOON
	if stencil.is_empty():return base
	var key:="%d|%s" % [int(lit),stencil]
	if _shaders.has(key):return _shaders[key]
	var code:=base.code
	if stencil=="card":
		# hair cards: both sides of a strip of strands
		code=code.replace("cull_back","cull_disabled")
	elif stencil=="write":
		code=code.replace("render_mode ","stencil_mode write, compare_always, 1;\nrender_mode ")
	else:
		code=code.replace("depth_draw_opaque","depth_draw_never").replace("render_mode ","stencil_mode read, compare_equal, 1;\nrender_mode blend_mix, shadows_disabled, ")
		code=code.replace("void fragment() {","void fragment() {\n\tALPHA = 1.0;")
	var made:=Shader.new();made.code=code
	_shaders[key]=made
	return made

## The darkest hair keeps a little tone, so its strands and sheen still read.
static func readable_hair(colour:Color)->Color:
	if colour.v>=0.20:return colour
	return Color.from_hsv(colour.h,colour.s*0.85,lerpf(colour.v,0.20,0.6))

static func _ink(cover:int,stippled:=false)->ShaderMaterial:
	var key:="%d|%d" % [cover,int(stippled)]
	if not _inks.has(key):
		var ink:=ShaderMaterial.new();ink.shader=INK
		ink.set_shader_parameter("cover_channel",cover)
		ink.set_shader_parameter("stipple",1.0 if stippled else 0.0)
		_inks[key]=ink
	return _inks[key]

## The fire moved, or a window: every figure's key light at once.
static func set_key_light(direction:Vector3)->void:
	key_dir=direction.normalized()
	for made:ShaderMaterial in _materials.values():made.set_shader_parameter("key_dir",key_dir)
	var alive:=[]
	for ref:WeakRef in _uber:
		var made:=ref.get_ref() as ShaderMaterial
		if made!=null:made.set_shader_parameter("key_dir",key_dir);alive.append(ref)
	_uber=alive

static func height_of(variant_name:String)->float:
	for entry:Dictionary in manifest().get("variants",[]):
		if String(entry.get("variant",""))==variant_name:return float(entry.get("height",REFERENCE_HEIGHT))
	return REFERENCE_HEIGHT

## Dress for a look; the body is only made again when its variant changes.
func setup(look_in:Dictionary)->bool:
	look=FigureLook.vary(look_in)
	var wanted:=String(look.get("variant","male_adult"))
	if not wanted in BODIES:wanted="male_adult"
	# a child's body not built yet: the slightest grown body stands in
	if wanted=="child" and scene_for("child")==null:wanted="female_young"
	if wanted!=variant or not is_instance_valid(model):
		var packed:=scene_for(wanted)
		if packed==null:return false
		if is_instance_valid(model):model.queue_free()
		model=packed.instantiate() as Node3D
		if model==null:return false
		model.name="Model"
		add_child(model)
		variant=wanted
		var skeletons:=model.find_children("*","Skeleton3D",true,false)
		skeleton=skeletons[0] as Skeleton3D if not skeletons.is_empty() else null
		var players:=model.find_children("*","AnimationPlayer",true,false)
		player=players[0] as AnimationPlayer if not players.is_empty() else null
		head_bone=skeleton.find_bone("head") if skeleton!=null else -1
		_meshes.clear();_parts.clear();_merged.clear();_merge_root=null
		_plain_skin=null;_wardrobe_skin=null;_wardrobe_loaded=false;_wardrobe_outfit=""
		for node in model.find_children("*","MeshInstance3D",true,false):_parts.append(node as MeshInstance3D)
		for node in _parts:
			if String(node.name)=="Body":_plain_skin=node.mesh
		_meshes=_parts.duplicate()
		for entry:Dictionary in manifest().get("variants",[]):
			if String(entry.get("variant",""))==variant:
				head_height=float(entry.get("head_top",1.72))-float(entry.get("chin",1.44))
				_base_height=float(entry.get("height",REFERENCE_HEIGHT))
		if player!=null:
			for name:String in LOOP_CLIPS:
				if player.has_animation(name):player.get_animation(name).loop_mode=Animation.LOOP_LINEAR
		_make_gaze()
		clip=""
	stance=String(look.get("stance","stand"))
	if not stance in STANCES:stance="stand"
	# Their build and height: the model scaled about the feet.
	var shape:=FigureLook.scale_of(look)
	model.scale=shape
	body_height=_base_height*shape.y
	_dress()
	_face()
	set_mood(String(look.get("mood","neutral")))
	return true

## The head and neck turn toward a point in the hall (LookAtModifier3D after
## the clip), so a person attends to whoever speaks without leaving their stance.
func _make_gaze()->void:
	_looks.clear()
	if skeleton==null:return
	gaze=Node3D.new();gaze.name="Gaze";gaze.top_level=true
	add_child(gaze)
	for pair:Array in [["neck",0.40,40.0,22.0],["head",0.85,62.0,34.0]]:
		if skeleton.find_bone(String(pair[0]))<0:continue
		var look:=LookAtModifier3D.new();look.name="Look_"+String(pair[0])
		look.bone_name=String(pair[0])
		look.forward_axis=SkeletonModifier3D.BONE_AXIS_PLUS_Z
		look.primary_rotation_axis=Vector3.AXIS_Y
		look.use_secondary_rotation=true
		look.duration=0.45;look.transition_type=Tween.TRANS_SINE;look.ease_type=Tween.EASE_IN_OUT
		look.use_angle_limitation=true;look.symmetry_limitation=true
		look.primary_limit_angle=deg_to_rad(float(pair[2]));look.secondary_limit_angle=deg_to_rad(float(pair[3]))
		look.primary_damp_threshold=0.85;look.secondary_damp_threshold=0.85
		look.influence=0.0
		look.set_meta("weight",float(pair[1]))
		skeleton.add_child(look)
		look.target_node=look.get_path_to(gaze)
		_looks.append(look)

## Attend to a point in the hall (world space); null: look where the body faces.
func look_at_point(target:Variant,time:=0.45,weight:=1.0)->void:
	if _looks.is_empty() or gaze==null:return
	if _gaze_tween and _gaze_tween.is_valid():_gaze_tween.kill()
	_gaze_on=target!=null
	if target!=null:
		gaze.global_position=(target as Vector3)+Vector3(0.0,-_mood_drop(),0.0)*global_transform.basis.get_scale().y
	if not is_inside_tree() or time<=0.0:
		for look in _looks:look.influence=float(look.get_meta("weight"))*weight if _gaze_on else 0.0
		return
	_gaze_tween=create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	for look in _looks:_gaze_tween.tween_property(look,"influence",float(look.get_meta("weight"))*clampf(weight,0.0,1.0) if _gaze_on else 0.0,time)

func _mood_drop()->float:
	## The head lowers in fear and lifts in defiance: the gaze point moves.
	return tan(deg_to_rad(float((MOODS.get(mood,MOODS.neutral) as Array)[1])))*2.0

## Their mood shows: "warm", "neutral", "afraid", "defiant", "grieved".
func set_mood(name:String)->void:
	if not MOODS.has(name):name="neutral"
	mood=name
	# K's acting reads `mood` and owns the face morphs once it is bound.
	if has_meta(&"court_acting"):return
	var keys:Dictionary=(MOODS[name] as Array)[0]
	for mesh_node in _meshes:
		if not String(mesh_node.name) in ["Mouth","Brows","Body"]:continue
		for key in ["mood_smile","mood_tight","mood_worry","mood_stern"]:
			var index:=mesh_node.find_blend_shape_by_name(StringName(key))
			if index>=0:mesh_node.set_blend_shape_value(index,float(keys.get(key,0.0)))

## Their own face: the morph targets of their people's family face and theirs.
func _face()->void:
	var face:Dictionary=look.get("face",{})
	for mesh_node in _parts:
		if mesh_node.mesh==null:continue
		# Every morph starts at rest; only this person's own are set.
		for index in mesh_node.get_blend_shape_count():mesh_node.set_blend_shape_value(index,0.0)
		if not mesh_node.visible:continue
		for shape:String in FACE_SHAPES:
			var index:=mesh_node.find_blend_shape_by_name(StringName("face_"+shape))
			if index>=0:mesh_node.set_blend_shape_value(index,clampf(float(face.get(shape,0.0)),-1.0,1.0))

## Expressions and visemes (docs/COURT_STAGE_3D.md §3): drives the named
## morph targets where the body has them, else their nearest stand-ins.
const EXPRESSION_STANDINS:={"smile":{"mood_smile":1.0},"lips_pressed":{"mood_tight":1.0},"frown":{"mood_tight":0.6,"mood_stern":0.5},
	"brows_worried":{"mood_worry":1.0},"brows_down":{"mood_stern":1.0},"brows_up":{"mood_worry":0.5},"sneer":{"mood_stern":0.6,"mood_tight":0.4}}
func set_expression(values:Dictionary)->void:
	if has_meta(&"court_acting"):return
	var standins:={}
	for name in values:
		var value:=clampf(float(values[name]),0.0,1.0)
		var found:=false
		for mesh_node in _meshes:
			if mesh_node.mesh==null:continue
			var index:=mesh_node.find_blend_shape_by_name(StringName(name))
			if index>=0:mesh_node.set_blend_shape_value(index,value);found=true
		if not found and EXPRESSION_STANDINS.has(name):
			for key in EXPRESSION_STANDINS[name]:standins[key]=maxf(float(standins.get(key,0.0)),value*float(EXPRESSION_STANDINS[name][key]))
	for key in standins:
		for mesh_node in _meshes:
			if not String(mesh_node.name) in ["Mouth","Brows","Body"]:continue
			var index:=mesh_node.find_blend_shape_by_name(StringName(key))
			if index>=0:mesh_node.set_blend_shape_value(index,float(standins[key]))

## Another library of clips (K's): its clips play as "<name>/<clip>".
func add_library(name:String,library:AnimationLibrary)->void:
	if player==null or library==null:return
	if player.has_animation_library(name):player.remove_animation_library(name)
	player.add_animation_library(name,library)

## The clip a stance rests in, and the one it talks in.
func rest_clip()->String:
	return stance

func talk_clip(both_hands:=false)->String:
	if both_hands and FREE_HANDS.get(stance,"")=="LR" and not stance in ["sit","crouch"]:return "talk_both"
	return stance+"_talk"

func _dress()->void:
	var outfit:=String(look.get("outfit","tunic"))
	if outfit in Wardrobe.OUTFITS and outfit!=_wardrobe_outfit:_load_wardrobe(outfit)
	for body in _parts:
		if String(body.name)=="Body":
			var skin_mesh:Mesh=_wardrobe_skin if outfit in Wardrobe.OUTFITS and _wardrobe_skin!=null else _plain_skin
			if body.mesh!=skin_mesh:body.mesh=skin_mesh
	var hair:="hair_"+String(look.get("hair","cropped"))
	var beard:=String(look.get("beard",""))
	if not beard.is_empty() and not beard.begins_with("beard_"):beard="beard_"+beard
	var hidden_pieces:Array=look.get("without",[])
	var skin:=Color(look.get("skin",Color("bd8659")))
	var hair_colour:=readable_hair(Color(look.get("hair_colour",Color("2b2018"))))
	var lit:=bool(look.get("lit",false))
	var merging:=lit and Merge.enabled and skeleton!=null
	var colours:={
		"SKIN":skin,"HAIR":hair_colour,"BROW":hair_colour.darkened(0.22),
		"EYES":Color("120a06"),"EYE_WHITE":Color("e9dfcb"),"EYE_SHINE":Color("fffdf6"),
		"IRIS":Color(look.get("eye_colour",Color("5a3a22"))),"PUPIL":Color("140d08"),
		"MOUTH":Color("2a0d0a").lerp(skin.darkened(0.7),0.35),"HAIR_CARD":hair_colour,"LEATHER":Color(look.get("leather",Color("5b3b24"))),
		"STUBBLE":skin.lerp(hair_colour,0.42).darkened(0.08),"WOOD":Color("6b4a2e"),"CLAY":Color("a0603a"),
	}
	var cloth:Array=look.get("cloth",[Color("b07a35"),Color("6e5541"),Color("a8432f")])
	for i in 3:colours["CLOTH_"+"ABC"[i]]=Color(cloth[i]) if i<cloth.size() else Color("8a7a66")
	for mesh_node in _parts:
		var part:=String(mesh_node.name)
		var shown:=part in FACE_PARTS or part==hair or part==beard or (part.begins_with(outfit+"_") and not part in hidden_pieces) or part==String(PROPS.get(stance,"-"))
		if part=="prop_stool" and (floor_seated or seat_height>=0.0):shown=false
		mesh_node.visible=shown
		# The source parts retain geometry, skin and morphs for later redressing,
		# but only the merged pieces draw them. Hidden shader materials still
		# reserve instance-uniform buffer space (16 slots per mesh on GL).
		if (merging and not part.begins_with("prop_")) or (not shown and not part in CARRIED.values()):
			_release_draw_materials(mesh_node)
			continue
		if mesh_node.mesh==null:continue
		# In a lit court they cast shadows (not the paint on the skin).
		# (hair and beards neither: their shade on the brow reads as a dark band)
		var shadows:=lit and not part in NO_SHADOW and not part.begins_with("hair_") and not part.begins_with("beard_")
		mesh_node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Beards and hair have no inked edge: they grow out of the skin, and
		# hair's outline is its cards of strands, not a drawn helmet's edge.
		var inked:=not part.begins_with("beard_") and not part.begins_with("hair_")
		for surface in mesh_node.mesh.get_surface_count():
			var source:=mesh_node.mesh.surface_get_material(surface)
			var slot:=source.resource_name if source!=null else "CLOTH_A"
			if part=="Brows":slot="BROW"
			var cover:=int(OUTFITS.get(outfit,0)) if part=="Body" else 0
			mesh_node.set_surface_override_material(surface,material(slot,colours.get(slot,Color("8a7a66")),cover,lit,inked))
		if part=="Body":_paint_face(mesh_node,beard)
	if merging:_merge_parts(colours,int(OUTFITS.get(outfit,0)),beard)
	else:_unmerge()

func _release_draw_materials(node:MeshInstance3D)->void:
	for surface in node.get_surface_override_material_count():
		if node.get_surface_override_material(surface)!=null:node.set_surface_override_material(surface,null)

func _load_wardrobe(outfit:String)->void:
	if skeleton==null:return
	var skin:Skin=null
	for body in _parts:
		if String(body.name)=="Body":skin=body.skin;break
	if skin==null:return
	var pieces:=Wardrobe.parts(variant,skin,skeleton)
	if not pieces.has("WardrobeBody"):return
	_wardrobe_skin=pieces.WardrobeBody
	# Only the chosen outfit needs render instances; the shared mesh cache keeps
	# all four available for redressing without reimporting or replacing the rig.
	for part:MeshInstance3D in _parts.duplicate():
		if not _wardrobe_outfit.is_empty() and String(part.name).begins_with(_wardrobe_outfit+"_"):
			_parts.erase(part);part.free()
	for name:String in pieces:
		if not name.begins_with(outfit+"_"):continue
		var node:=MeshInstance3D.new();node.name=name;node.mesh=pieces[name];node.skin=skin
		skeleton.add_child(node);node.skeleton=NodePath("..")
		_parts.append(node)
	_wardrobe_loaded=true
	_wardrobe_outfit=outfit

## The visible parts as a few merged pieces (court_figure_merge.gd): Body
## (skin, brows, mouth, beard, lid line; the moving morphs), Rest (the
## outfit), Hair (hair and cards) and Eyes (whites, and what shows in them).
func _merge_parts(colours:Dictionary,cover:int,beard:String)->void:
	var groups:={"Body":[],"Rest":[],"Hair":[],"Eyes":[]}
	var names:=PackedStringArray()
	var skin_res:Skin=null
	for mesh_node in _parts:
		var part:=String(mesh_node.name)
		if not mesh_node.visible or mesh_node.mesh==null or part.begins_with("prop_"):continue
		names.append(part)
		if skin_res==null:skin_res=mesh_node.skin
		for surface in mesh_node.mesh.get_surface_count():
			var source:=mesh_node.mesh.surface_get_material(surface)
			var slot:=source.resource_name if source!=null else "CLOTH_A"
			if part=="Brows":slot="BROW"
			var entry:=[mesh_node,surface,slot]
			if part=="Eyes":(groups.Body if slot=="EYES" else groups.Eyes).append(entry)
			elif part in ["Body","Brows","Mouth"] or part.begins_with("beard_"):groups.Body.append(entry)
			elif part.begins_with("hair_"):groups.Hair.append(entry)
			else:groups.Rest.append(entry)
	var face:Dictionary=look.get("face",{})
	var face_key:=PackedStringArray()
	for shape:String in FACE_SHAPES:face_key.append("%.2f" % float(face.get(shape,0.0)))
	var made:=Merge.meshes("%s|%s|%s" % [variant,",".join(names),",".join(face_key)],groups,face)
	if not is_instance_valid(_merge_root):
		_merge_root=Node3D.new();_merge_root.name="Merged";skeleton.add_child(_merge_root)
	var opaque:=Merge.material(colours,cover,key_dir)
	var write:=Merge.material(colours,cover,key_dir,"write")
	var read:=Merge.material(colours,cover,key_dir,"read")
	# Keep render resources alive until every merged child has been destroyed.
	# Immediate scene teardown otherwise releases an eye material too early.
	_merge_root.set_meta(&"draw_materials",[opaque,write,read])
	for m in [opaque,write,read]:_uber.append(weakref(m))
	_meshes.clear()
	for group in ["Body","Rest","Hair","Eyes"]:
		var node:=_merged.get(group) as MeshInstance3D
		if not made.has(group):
			if node!=null:
				node.visible=false
				_release_draw_materials(node)
			continue
		if node==null:
			node=MeshInstance3D.new();node.name=group
			_merge_root.add_child(node)
			node.skeleton=NodePath("../..")
			_merged[group]=node
		node.skin=skin_res
		node.mesh=made[group]
		node.visible=true
		for i in node.get_blend_shape_count():node.set_blend_shape_value(i,0.0)
		if group=="Eyes":
			node.set_surface_override_material(0,write)
			if node.mesh.get_surface_count()>1:node.set_surface_override_material(1,read)
		else:
			node.set_surface_override_material(0,opaque)
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON if group in ["Body","Rest"] else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_meshes.append(node)
	if _merged.has("Body"):_paint_face(_merged.Body,beard)
	# the parts step aside (the props stay, shown by their stance)
	for mesh_node in _parts:
		if String(mesh_node.name).begins_with("prop_"):_meshes.append(mesh_node)
		else:mesh_node.visible=false

# --- Put to death (court_figure_gore.gd: the court's executions) ---------------------

const Gore:=preload("res://scripts/hud/court_figure_gore.gd")

## Can gore be shown on this person (never a child)?
func gore_allowed()->bool:
	return Gore.allowed(self)

## When an execution starts: cut the meshes and keep the pose for the blow.
func gore_prepare()->void:
	Gore.prepare(self)

## The body comes apart now ("head", "limbs", "all", "halves"): {name: piece}.
func gore_split(cut:="head")->Dictionary:
	return Gore.split(self,cut)

## Gone from the hall, the pieces in its place: nothing of it runs.
func _vanish_for_gore()->void:
	visible=false
	if player!=null:player.stop()
	set_process(false)
	for node in skeleton.get_children():
		if node is SkeletonModifier3D:(node as SkeletonModifier3D).active=false

## Back to the parts as they are (no lit court: the studio, the flat stage).
func _unmerge()->void:
	for node in _merged.values():
		if is_instance_valid(node):
			(node as MeshInstance3D).visible=false
			_release_draw_materials(node)
	_meshes=_parts.duplicate()

## Their own painted face (court_figure_face.gdshaderinc): years, freckles,
## a shaved man's shadow of beard, their seed, and how readily they colour.
func _paint_face(body:MeshInstance3D,beard:String)->void:
	var years:=FigureLook.years_of(look)
	var seed_value:=FigureLook.seed_of(look)
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value+101
	var age:=clampf(float(years-26)/40.0,0.0,1.0)
	var skin:=Color(look.get("skin",Color("bd8659")))
	var fair:=skin.get_luminance()>0.55
	var freckles:=rng.randf_range(0.4,1.0) if rng.randf()<(0.45 if fair else 0.12) and years<60 else 0.0
	var male:=variant.begins_with("male")
	var shadow:=0.0
	if male and years>=17 and (beard.is_empty() or beard=="beard_moustache"):shadow=rng.randf_range(0.25,0.85)
	var blush:=0.8 if variant=="child" else (0.6 if variant.begins_with("female") else 0.25)
	body.set_instance_shader_parameter("face_a",Vector4(age,freckles,shadow,float(seed_value%9973)/9973.0))
	body.set_instance_shader_parameter("face_b",Vector4(blush,0.0,0.0,0.0))

## A prop shows only in the stance that holds it (not while walking or bowing).
func _props_for(name:String)->void:
	var held:=String(PROPS.get(stance,""))
	var holding:=name==stance or name==stance+"_talk"
	for mesh_node in _meshes:
		var part:=String(mesh_node.name)
		if part.begins_with("prop_") and not part in CARRIED.values():mesh_node.visible=holding and part==held and not (part=="prop_stool" and (floor_seated or seat_height>=0.0))

func _mesh_named(part:String)->MeshInstance3D:
	for mesh_node in _meshes:
		if String(mesh_node.name)==part:return mesh_node
	return null

# --- Carrying and dropping ------------------------------------------------------

var _carried:MeshInstance3D
var _carry_on:=false
var _hand_l:=-1
var _hand_r:=-1
var _dropped:Array[Node3D]=[]

func _ready()->void:
	set_process(_carry_on)

## They carry something between their hands (a bundle of food): it rides
## between the hands, whatever the clip does with them, until set down.
func carry(what:String,on:=true)->void:
	var node:=_mesh_named(String(CARRIED.get(what,"")))
	if node==null:return
	if _carried!=null and _carried!=node:_carried.visible=false
	_carried=node
	node.visible=on
	node.top_level=on
	_carry_on=on
	if skeleton!=null:
		_hand_l=skeleton.find_bone("hand.L");_hand_r=skeleton.find_bone("hand.R")
	set_process(on)
	if on:_process(0.0)

## What they carry is set down where it is, on the ground, and stays there.
func set_down()->void:
	if _carried==null or not _carry_on:return
	_carry_on=false;set_process(false)
	var at:=_carried.global_position
	_carried.global_position=Vector3(at.x,global_position.y+0.115*body_height/REFERENCE_HEIGHT,at.z)

## Is it in their hands?
func carrying()->bool:
	return _carry_on

func _process(_delta:float)->void:
	if not _carry_on or _carried==null or skeleton==null or _hand_l<0 or _hand_r<0 or not is_inside_tree():return
	var xf:=skeleton.global_transform
	var pl:=xf*skeleton.get_bone_global_pose(_hand_l).origin
	var pr:=xf*skeleton.get_bone_global_pose(_hand_r).origin
	var basis:=global_transform.basis.orthonormalized()
	var k:=body_height/REFERENCE_HEIGHT
	_carried.global_transform=Transform3D(basis*Basis.from_scale(Vector3.ONE*global_transform.basis.get_scale().x),(pl+pr)*0.5+basis.z*0.07*k-Vector3(0.0,0.05*k,0.0))

## They drop what they hold (the bowl): it falls from the hand to the floor
## and lies there; they stand empty-handed from then on.
func drop_held(empty_stance:="stand")->Node3D:
	var held:=String(PROPS.get(stance,""))
	if held.is_empty() or held=="prop_stool":return null
	var node:=_mesh_named(held)
	if node==null or skeleton==null:return null
	var hand:=skeleton.find_bone("hand.R")
	var fallen:=MeshInstance3D.new();fallen.name="Dropped_"+held
	fallen.mesh=node.mesh
	for surface in node.mesh.get_surface_count():fallen.set_surface_override_material(surface,node.get_surface_override_material(surface))
	fallen.cast_shadow=node.cast_shadow
	# where the hand holds it now: the bone's pose against its rest
	var rel:=skeleton.global_transform.affine_inverse()*node.global_transform
	var posed:=skeleton.global_transform*skeleton.get_bone_global_pose(hand)*skeleton.get_bone_global_rest(hand).affine_inverse()*rel
	var holder:Node=get_parent() if get_parent()!=null else self
	holder.add_child(fallen)
	fallen.global_transform=posed
	_dropped.append(fallen)
	node.visible=false
	stance=empty_stance if empty_stance in STANCES else "stand"
	play(rest_clip(),0.3)
	if is_inside_tree():
		var floor_y:=global_position.y+0.03*body_height/REFERENCE_HEIGHT
		var fall:=fallen.create_tween()
		fall.tween_property(fallen,"global_position:y",floor_y,0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		fall.parallel().tween_property(fallen,"rotation:z",fallen.rotation.z+deg_to_rad(28.0),0.34)
		fall.tween_property(fallen,"global_position:y",floor_y+0.035,0.09).set_ease(Tween.EASE_OUT)
		fall.tween_property(fallen,"global_position:y",floor_y,0.09).set_ease(Tween.EASE_IN)
	return fallen

## Play a clip, blending from the last one; once-only clips hold their end.
## at: start this far in (a different breath for each person at rest).
func play(name:String,blend:=0.25,at:=-1.0)->void:
	if player==null or not player.has_animation(name):return
	if name==clip and at<0.0 and player.is_playing():return
	set_locomotion_rate(1.0)
	clip=name
	_props_for(name)
	player.play(name,blend)
	if at>=0.0:player.seek(fmod(at,player.get_animation(name).length),true)

func set_locomotion_rate(rate:float)->void:
	locomotion_rate=maxf(rate,0.0)
	if player!=null:player.speed_scale=locomotion_rate

func clip_length(name:String)->float:
	return player.get_animation(name).length if player!=null and player.has_animation(name) else 0.0

## Light on this person: above 1 in the light, below 1 a little back.
func set_light(amount:float)->void:
	for mesh_node in _meshes:
		if mesh_node.visible:mesh_node.set_instance_shader_parameter("dim",amount)

## Turn to face a way (degrees about the vertical; 0 faces the viewer).
func face(yaw_degrees:float,time:=0.3)->void:
	if _yaw_tween and _yaw_tween.is_valid():_yaw_tween.kill()
	if time<=0.0 or not is_inside_tree():
		rotation_degrees.y=yaw_degrees;return
	_yaw_tween=create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Angles wrap at 180 degrees; cross that seam by the short turn.
	var target:=rotation.y+wrapf(deg_to_rad(yaw_degrees)-rotation.y,-PI,PI)
	_yaw_tween.tween_property(self,"rotation:y",target,time)

## The top of the head in world space (speech bubbles hang above it).
func head_top()->Vector3:
	if skeleton==null or head_bone<0:return global_position+Vector3.UP*body_height*global_transform.basis.get_scale().y
	var pose:=skeleton.global_transform*skeleton.get_bone_global_pose(head_bone)
	return pose.origin+pose.basis.y.normalized()*head_height*1.04*global_transform.basis.get_scale().y*(model.scale.y if is_instance_valid(model) else 1.0)

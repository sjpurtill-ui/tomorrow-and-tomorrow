extends Node3D
## One person of the court as a modelled, animated figure.
## The figures are made in Blender by tools/blender/court_figures.py: six
## bodies (male/female, young/adult/old), each one .glb in
## assets/court_figures/ holding every hair style, beard and outfit as
## separate meshes, and every clip (idle, talk, listen, bow, kneel, walk...).
## This node shows one hair, at most one beard and one outfit, colours the
## material slots (SKIN, HAIR, CLOTH_A/B/C, LEATHER...) from a look, and
## plays clips with a short blend. Materials are shared between figures of
## the same colours; nothing is allocated per frame.
## A look: {variant, outfit, hair, beard, skin, hair_colour, cloth:[a,b,c], leather}.

const DIR:="res://assets/court_figures/"
const TOON:=preload("res://scripts/shaders/court_figure_toon.gdshader")
const INK:=preload("res://scripts/shaders/court_figure_ink.gdshader")
const VARIANTS:=["male_adult","female_adult","male_old","female_old","male_young","female_young"]
const OUTFITS:={"hide":1,"tunic":2,"robe":3}
const LOOP_CLIPS:=["idle","idle_clasped","talk","talk_both","listen_l","listen_r","look_up","walk_in","walk_out"]
const FACE_PARTS:=["Body","Eyes","Brows","Mouth"]
## Slots drawn flat (no light): the painted eyes and mouth.
const FLAT_SLOTS:=["EYES","EYE_SHINE","MOUTH"]

static var _scenes:Dictionary={}
static var _materials:Dictionary={}
static var _inks:Dictionary={}
static var _manifest:Dictionary={}
static var key_dir:=Vector3(-0.35,0.65,0.68)

var look:Dictionary={}
var model:Node3D
var skeleton:Skeleton3D
var player:AnimationPlayer
var clip:=""
var head_bone:=-1
var head_height:=0.28

static func manifest()->Dictionary:
	if _manifest.is_empty():
		var text:=FileAccess.get_file_as_string(DIR+"court_figures.json")
		var parsed:Variant=JSON.parse_string(text) if not text.is_empty() else null
		_manifest=parsed if parsed is Dictionary else {"variants":[]}
	return _manifest

static func scene_for(variant:String)->PackedScene:
	if not variant in VARIANTS:variant="male_adult"
	if not _scenes.has(variant):
		var path:=DIR+"court_figure_%s.glb" % variant
		_scenes[variant]=load(path) as PackedScene if ResourceLoader.exists(path) else null
	return _scenes[variant]

static func available()->bool:
	return scene_for("male_adult")!=null

## The shared material for a slot in a colour (skin also knows which outfit hides it).
static func material(slot:String,colour:Color,cover:=0)->ShaderMaterial:
	var key:="%s|%s|%d" % [slot,colour.to_html(false),cover]
	if _materials.has(key):return _materials[key]
	var made:=ShaderMaterial.new();made.shader=TOON
	made.set_shader_parameter("albedo",colour)
	made.set_shader_parameter("cover_channel",cover)
	made.set_shader_parameter("key_dir",key_dir)
	if slot in FLAT_SLOTS:
		made.set_shader_parameter("flat_colour",true)
	else:
		if slot=="SKIN":made.set_shader_parameter("shade_tint",Color(0.66,0.50,0.46))
		if slot=="HAIR":made.set_shader_parameter("rim_amount",0.22)
		made.next_pass=_ink(cover)
	_materials[key]=made
	return made

static func _ink(cover:int)->ShaderMaterial:
	if not _inks.has(cover):
		var ink:=ShaderMaterial.new();ink.shader=INK
		ink.set_shader_parameter("cover_channel",cover)
		_inks[cover]=ink
	return _inks[cover]

## The fire moved, or a window: every figure's key light at once.
static func set_key_light(direction:Vector3)->void:
	key_dir=direction.normalized()
	for made:ShaderMaterial in _materials.values():made.set_shader_parameter("key_dir",key_dir)

func setup(look_in:Dictionary)->bool:
	look=look_in
	var packed:=scene_for(String(look.get("variant","male_adult")))
	if packed==null:return false
	if is_instance_valid(model):model.queue_free()
	model=packed.instantiate() as Node3D
	model.name="Model"
	add_child(model)
	var skeletons:=model.find_children("*","Skeleton3D",true,false)
	skeleton=skeletons[0] as Skeleton3D if not skeletons.is_empty() else null
	var players:=model.find_children("*","AnimationPlayer",true,false)
	player=players[0] as AnimationPlayer if not players.is_empty() else null
	if skeleton!=null:head_bone=skeleton.find_bone("head")
	for entry:Dictionary in manifest().get("variants",[]):
		if String(entry.get("variant",""))==String(look.get("variant","")):
			head_height=float(entry.get("head_top",1.72))-float(entry.get("chin",1.44))
	_dress()
	if player!=null:
		for name:String in LOOP_CLIPS:
			if player.has_animation(name):player.get_animation(name).loop_mode=Animation.LOOP_LINEAR
	return true

func _dress()->void:
	var outfit:=String(look.get("outfit","tunic"))
	var hair:="hair_"+String(look.get("hair","cropped"))
	var beard:=String(look.get("beard",""))
	if not beard.is_empty() and not beard.begins_with("beard_"):beard="beard_"+beard
	var hidden_pieces:Array=look.get("without",[])
	var colours:={
		"SKIN":Color(look.get("skin",Color("bd8659"))),
		"HAIR":Color(look.get("hair_colour",Color("2b2018"))),
		"EYES":Color("1c140f"),"EYE_SHINE":Color("f4ead8"),
		"MOUTH":Color(look.get("skin",Color("bd8659"))).darkened(0.62),
		"LEATHER":Color(look.get("leather",Color("5b3b24"))),
	}
	var cloth:Array=look.get("cloth",[Color("b07a35"),Color("6e5541"),Color("a8432f")])
	for i in 3:colours["CLOTH_"+"ABC"[i]]=Color(cloth[i]) if i<cloth.size() else Color("8a7a66")
	for node in model.find_children("*","MeshInstance3D",true,false):
		var mesh_node:=node as MeshInstance3D
		var part:=String(mesh_node.name)
		var shown:=part in FACE_PARTS or part==hair or part==beard or (part.begins_with(outfit+"_") and not part in hidden_pieces)
		mesh_node.visible=shown
		if not shown or mesh_node.mesh==null:continue
		mesh_node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for surface in mesh_node.mesh.get_surface_count():
			var source:=mesh_node.mesh.surface_get_material(surface)
			var slot:=source.resource_name if source!=null else "CLOTH_A"
			var cover:=int(OUTFITS.get(outfit,0)) if part=="Body" else 0
			mesh_node.set_surface_override_material(surface,material(slot,colours.get(slot,Color("8a7a66")),cover))

## Play a clip, blending from the last one; once-only clips hold their end.
func play(name:String,blend:=0.25,at:=-1.0)->void:
	if player==null or not player.has_animation(name):return
	clip=name
	player.play(name,blend)
	if at>=0.0:
		player.seek(at,true)

## The top of the head in world space (speech bubbles hang above it).
func head_top()->Vector3:
	if skeleton==null or head_bone<0:return global_position+Vector3.UP*1.7*scale.y
	var pose:=skeleton.global_transform*skeleton.get_bone_global_pose(head_bone)
	return pose.origin+pose.basis.y.normalized()*head_height*1.02*global_transform.basis.get_scale().y

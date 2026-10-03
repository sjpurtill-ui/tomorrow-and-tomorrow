extends Node3D
## An animal of the court: a modelled, rigged and animated beast (made in
## Blender by tools/blender/court_animals.py, assets/court_sets/animals/) that
## lives on the set (court_set_3d.gd). Left to itself it does what such an
## animal does about a fire full of people: it dozes, sniffs about, sits and
## scratches, wanders to another spot. The director (court_director.gd) can
## take it in hand for a beat:
##   sniff_at(point_or_node)   go and sniff something (the envoy's gift)
##   steal_scrap(point)        trot to it, grab it, and make off out the door
##   on_god("speaks"|"wrath"|"favour")   ears up and a tilt; cower and
##                             tremble; a wag
##   sit(), lie(), scratch(), bark(), wag(), look_up(), tilt(), cower()
## Presentation only. Nothing is allocated per frame; it stops when the court
## is hidden (set_active).

signal arrived

const DIR:="res://assets/court_sets/animals/"
const MANIFEST:=DIR+"court_animals.json"
const TOON:=preload("res://assets/court_sets/shaders/court_set_toon.gdshader")
const INK:=preload("res://assets/court_sets/shaders/court_set_ink.gdshader")
## N (court sound): the open court's sound hears the beast's own clips. Looked
## up, not preloaded, so the set stands on its own where the sound is not built.
const SOUND_PATH:="res://scripts/hud/court_sound.gd"
static var _sound:Script
static var _sound_checked:=false
## Each species' paint by slot.
const PALETTE:={
	"dog":{"COAT":"a06c3b","COAT_LIGHT":"e0c99e","COAT_DARK":"5f4027","NOSE":"1d1612","EYE":"150f0c","EYE_SHINE":"fbf6ea"},
	"goat":{"COAT":"e6d6b4","COAT_DARK":"3e2c20","NOSE":"3a2c26","HOOF":"2c241e","HORN":"8c8070","EYE":"120c08","EYE_AMBER":"b8862e"},
	"pig":{"COAT":"c48f78","COAT_DARK":"4a3428","NOSE":"d99a8a","HOOF":"3a2c24","EYE":"120c08","EYE_SHINE":"fbf6ea"},
	"cattle":{"COAT":"8a4a2a","COAT_DARK":"2e211a","COAT_LIGHT":"e2d4b8","NOSE":"2a1c18","HOOF":"2a221c","HORN":"d8ccb0","EYE":"120c08","EYE_SHINE":"fbf6ea"},
	"bear":{"COAT":"5e3f26","COAT_DARK":"3a2616","COAT_LIGHT":"9a7650","NOSE":"161010","EYE":"0e0a08","EYE_SHINE":"fbf6ea"},
	"elephant":{"COAT":"7c7672","COAT_DARK":"615b57","HOOF":"4a4542","TUSK":"eee6d2","EYE":"120c08","EYE_SHINE":"fbf6ea"},
}
## Each herd beast's own coats (a herd is never one beast painted ten times).
const SPECIES_COATS:={
	"pig":{"pink":{"COAT":"d9a090","COAT_DARK":"b9786a"},"black":{"COAT":"3a2c26","COAT_DARK":"231a16"},
		"spotted":{"COAT":"d4a48e","COAT_DARK":"2e221c"},"bristly":{"COAT":"7a5a44","COAT_DARK":"4a3428"}},
	"cattle":{"red":{"COAT":"8a4a2a","COAT_DARK":"5a2e1a"},"black":{"COAT":"2a2220","COAT_DARK":"1a1412","COAT_LIGHT":"d8cbb0"},
		"dun":{"COAT":"b89a6e","COAT_DARK":"8a6e4a"},"pied":{"COAT":"e4dacb","COAT_DARK":"2a2220"}},
}
## The camp dogs' coats (a pack is never one dog painted five times).
const COATS:={
	"black":{"COAT":"2a2420","COAT_LIGHT":"8a7a66","COAT_DARK":"151210"},
	"grey":{"COAT":"7c7670","COAT_LIGHT":"d6d0c4","COAT_DARK":"3e3a36"},
	"cream":{"COAT":"cdb48a","COAT_LIGHT":"efe4cc","COAT_DARK":"8a6a44"},
	"brindle":{"COAT":"6e4a2a","COAT_LIGHT":"c2a274","COAT_DARK":"2e2016"},
}
## A species' own clip for each of the court's animal acts (the dog's names).
const CLIP_MAP:={
	"goat":{"sniff":"graze","sit":"lie","sit_idle":"lie_idle","scratch":"graze","cower":"startle","cower_idle":"look",
		"wag":"bleat","tilt":"look","look_up":"look","bark":"bleat","grab":"graze","trot":"walk"},
	"pig":{"sniff":"idle","sit":"idle","sit_idle":"idle","scratch":"idle","lie":"idle","lie_idle":"idle","stand_up":"idle",
		"cower":"squeal","cower_idle":"idle","wag":"squeal","tilt":"idle","look_up":"idle","bark":"squeal","grab":"eat",
		"tug":"eat","crunch":"eat","carry":"trot"},
	"cattle":{"sniff":"idle","sit":"idle","sit_idle":"idle","scratch":"idle","lie":"idle","lie_idle":"idle","stand_up":"idle",
		"cower":"look","cower_idle":"look","wag":"idle","tilt":"look","look_up":"look","bark":"look","grab":"idle",
		"trot":"gallop","tug":"pull","crunch":"idle","carry":"walk"},
	"bear":{"sniff":"idle","sit":"idle","sit_idle":"idle","scratch":"idle","lie":"idle","lie_idle":"idle","stand_up":"idle",
		"cower":"idle","cower_idle":"idle","wag":"idle","tilt":"idle","look_up":"rear","bark":"burp","grab":"gulp",
		"trot":"walk","tug":"walk","crunch":"gulp","carry":"walk"},
	"elephant":{"sniff":"idle","sit":"idle","sit_idle":"idle","scratch":"idle","lie":"idle","lie_idle":"idle","stand_up":"idle",
		"cower":"trumpet","cower_idle":"idle","wag":"idle","tilt":"idle","look_up":"trumpet","bark":"trumpet","grab":"stomp",
		"trot":"walk","tug":"walk","crunch":"stomp","carry":"walk"},
}
## What a one-off clip settles into when it ends.
const AFTER:={"sit":"sit_idle","lie":"lie_idle","cower":"cower_idle","stand_up":"idle","look_up":"idle","bark":"idle","grab":"idle","tilt":"idle",
	"bleat":"idle","startle":"look","look":"idle",
	"squeal":"idle","shake_hoof":"idle","gulp":"idle","burp":"idle","spit":"idle","stomp":"idle","shake_foot":"idle","trumpet":"idle"}
## Clips the animal is down in (it must stand up before it walks).
const DOWN:=["sit","sit_idle","scratch","lie","lie_idle"]
## Keep clear of the fire by this much when walking past it.
const FIRE_CLEAR:=1.05

## Whether the beasts carry their own inked shells (off when the set inks the
## whole stage in one pass).
static var hull_ink:=true
static var _manifest:Dictionary={}
static var _scenes:Dictionary={}
static var _materials:Dictionary={}
static var _ink_material:ShaderMaterial

var species:=""
var info:Dictionary={}
var model:Node3D
var player:AnimationPlayer
var clip:=""
var rng:=RandomNumberGenerator.new()
## "calm", "afraid", "glad": how it carries itself now.
var mood:="calm"
var active:=true
var shade:MeshInstance3D
var _set:WeakRef
var _speed:=0.0
var _gait:="walk"
var _moving:=false
var _move_epoch:=0
var _path:PackedVector3Array=PackedVector3Array()
var _arrive:Callable=Callable()
var _yaw:=0.0
var _yaw_goal:=0.0
var _turning:=false
## Seconds until the animal next decides what to do by itself.
var _think:=2.0
## Seconds the director still holds it (it does nothing of its own meanwhile).
var _held:=0.0
var _after_hold:Callable=Callable()

static func manifest()->Dictionary:
	if _manifest.is_empty():
		var text:=FileAccess.get_file_as_string(MANIFEST)
		var parsed:Variant=JSON.parse_string(text) if not text.is_empty() else null
		_manifest=parsed if parsed is Dictionary else {"species":{}}
	return _manifest

static func scene_for(species_name:String)->PackedScene:
	if not _scenes.has(species_name):
		var entry:Dictionary=(manifest().get("species",{}) as Dictionary).get(species_name,{})
		var path:=DIR+String(entry.get("glb","court_%s.glb" % species_name))
		_scenes[species_name]=load(path) as PackedScene if not entry.is_empty() and ResourceLoader.exists(path) else null
	return _scenes[species_name]

static func available(species_name:String)->bool:
	return scene_for(species_name)!=null

## Make this animal for a set. seed_value keeps its ways the same each time.
var coat:=""
## What it has in its mouth (a thighbone, a head...), or null.
var carried:Node3D

func setup(species_name:String,court_set:Node3D,seed_value:=0,coat_name:="")->bool:
	coat=coat_name
	var packed:=scene_for(species_name)
	if packed==null:return false
	species=species_name
	info=(manifest().get("species",{}) as Dictionary).get(species,{})
	name="Animal_"+species
	_set=weakref(court_set)
	rng.seed=hash("%s|%d" % [species,seed_value])
	model=packed.instantiate() as Node3D
	model.name="Model"
	add_child(model)
	var players:=model.find_children("*","AnimationPlayer",true,false)
	player=players[0] as AnimationPlayer if not players.is_empty() else null
	if player!=null:
		var clips:Dictionary=info.get("clips",{})
		for clip_name in clips.keys():
			if player.has_animation(clip_name):
				player.get_animation(clip_name).loop_mode=Animation.LOOP_LINEAR if bool(clips[clip_name].get("loop",false)) else Animation.LOOP_NONE
		player.animation_finished.connect(_on_finished)
	_dress()
	# its shadow pool sized to the beast (the dog's is 0.42 x 0.78)
	var k:=float(info.get("height",0.74))/0.74
	shade=load("res://scripts/hud/court_set_3d.gd").call("contact_shadow",0.42*k,0.78*k,0.5)
	add_child(shade)
	return true

func _dress()->void:
	var paint:Dictionary=(PALETTE.get(species,{}) as Dictionary).duplicate()
	var coats:Dictionary=SPECIES_COATS.get(species,COATS)
	for slot in (coats.get(coat,{}) as Dictionary).keys():paint[slot]=coats[coat][slot]
	for node in model.find_children("*","MeshInstance3D",true,false):
		var mesh_node:=node as MeshInstance3D
		mesh_node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		if mesh_node.mesh==null:continue
		for surface in mesh_node.mesh.get_surface_count():
			var source:=mesh_node.mesh.surface_get_material(surface)
			var slot:=source.resource_name if source!=null else "COAT"
			mesh_node.set_surface_override_material(surface,_material(slot,Color(String(paint.get(slot,"8a6a48")))))

static func _material(slot:String,colour:Color)->ShaderMaterial:
	var key:="%s|%s|%s" % [slot,colour.to_html(false),hull_ink]
	if _materials.has(key):return _materials[key]
	var made:=ShaderMaterial.new();made.shader=TOON
	made.set_shader_parameter("albedo",colour);made.set_shader_parameter("albedo_worn",colour)
	made.set_shader_parameter("mottle",0.06);made.set_shader_parameter("variation",0.0)
	made.set_shader_parameter("grain",0.04);made.set_shader_parameter("wrap",0.15)
	match slot:
		"EYE_SHINE":made.set_shader_parameter("emission_color",Color(1,1,1));made.set_shader_parameter("emission_amount",0.8)
		"EYE","NOSE":made.set_shader_parameter("rim_amount",0.25)
		_:made.set_shader_parameter("rim_amount",0.10)
	if hull_ink and not slot in ["EYE","EYE_SHINE"]:
		if _ink_material==null:
			_ink_material=ShaderMaterial.new();_ink_material.shader=INK
		made.next_pass=_ink_material
	_materials[key]=made
	return made

func court_set()->Node3D:
	return _set.get_ref() as Node3D if _set!=null else null

## Start the animal on a mark of the set, at rest there.
func start_at(mark_name:String)->void:
	var cs:=court_set()
	if cs==null:return
	var m:Marker3D=cs.call("mark",mark_name)
	if m==null:return
	position=m.position
	var z:=-m.basis.z
	_yaw=atan2(z.x,z.z)+rng.randf_range(-0.6,0.6);_yaw_goal=_yaw
	rotation.y=_yaw
	# the dog's first spot is by the fire, lying down
	if mark_name=="animal_0" and species=="dog":
		play("lie_idle",0.0,rng.randf()*4.0)
		_think=rng.randf_range(6.0,14.0)
	else:
		play("idle",0.0,rng.randf()*3.0)
		_think=rng.randf_range(2.0,6.0)

## The court is open (on) or hidden (off).
func set_active(on:bool)->void:
	active=on
	set_process(on)
	if player!=null:player.speed_scale=1.0 if on else 0.0

func _ready()->void:
	set_process(active)

# --- Clips --------------------------------------------------------------------------

func play(clip_name:String,blend:=0.25,at:=-1.0)->void:
	clip_name=String((CLIP_MAP.get(species,{}) as Dictionary).get(clip_name,clip_name))
	if player==null or not player.has_animation(clip_name):return
	if clip_name==clip and at<0.0 and player.is_playing():return
	clip=clip_name
	player.play(clip_name,blend)
	# N (court sound): heard doing what it does (sniff, scratch, bark, lie, wag, walk...)
	var sound:=_court_sound()
	if sound!=null:sound.call("animal",species,clip_name,self)
	if at>=0.0:player.seek(fmod(at,player.get_animation(clip_name).length),true)

static func _court_sound()->Object:
	if not _sound_checked:
		_sound_checked=true
		if ResourceLoader.exists(SOUND_PATH):_sound=load(SOUND_PATH) as Script
	if _sound==null:return null
	var current:Variant=_sound.get("current")
	if typeof(current)!=TYPE_OBJECT or not is_instance_valid(current):return null
	return current if (current as Object).has_method("animal") else null

func _on_finished(finished:StringName)->void:
	var next:=String(AFTER.get(String(finished),""))
	if next=="idle" and mood=="glad":next="wag"
	if not next.is_empty() and not _moving:play(next,0.3)

func is_down()->bool:
	return clip in DOWN

func clip_length(clip_name:String)->float:
	clip_name=String((CLIP_MAP.get(species,{}) as Dictionary).get(clip_name,clip_name))
	return player.get_animation(clip_name).length if player!=null and player.has_animation(clip_name) else 0.0

# --- Moving -------------------------------------------------------------------------

## Walk (or trot) to a point on the ground, round the fire, then do `then`.
func go_to(point:Vector3,gait:="walk",then:=Callable())->void:
	_move_epoch+=1
	var epoch:=_move_epoch
	_arrive=then
	_gait=gait if gait in ["walk","trot","carry","tug","gallop","pull"] else "walk"
	# dragging something heavy: backwards, braced, slow
	_speed=0.55 if _gait=="tug" else float((info.get("speeds",{}) as Dictionary).get(_gait,0.8))
	_path=_route(position,Vector3(point.x,0.0,point.z))
	if is_down():
		# up first, then off
		play("stand_up",0.2)
		var wait:=create_tween();wait.tween_interval(clip_length("stand_up")*0.8)
		wait.tween_callback(func()->void:if epoch==_move_epoch:_set_off())
	else:
		_set_off()

func _set_off()->void:
	_moving=not _path.is_empty()
	if _moving:play(_gait,0.25)
	else:_finish_move()

## Let an interrupted scene release its dog without leaving fetch/drag callbacks.
func cancel_action(home:Variant=null)->void:
	_move_epoch+=1
	if home is Transform3D:transform=home
	_yaw=rotation.y;_yaw_goal=_yaw
	_moving=false;_path.clear();_arrive=Callable()
	_held=0.0;_after_hold=Callable();_turning=false
	drop_carried()
	_think=2.0
	play("idle",0.2)

## A straight line, or round the fire if the line would cross it.
func _route(from:Vector3,to:Vector3)->PackedVector3Array:
	var out:=PackedVector3Array()
	var cs:=court_set()
	var fire:=Vector3.ZERO
	if cs!=null and cs.call("has_mark","fire"):fire=(cs.call("mark","fire") as Marker3D).position
	var seg:=to-from
	var t:=clampf((fire-from).dot(seg)/maxf(seg.length_squared(),0.0001),0.0,1.0)
	var near:=from+seg*t
	var off:=Vector3(near.x-fire.x,0.0,near.z-fire.z)
	if off.length()<FIRE_CLEAR and seg.length()>0.5:
		if off.length()<0.05:off=Vector3(-seg.z,0.0,seg.x)
		out.append(fire+off.normalized()*(FIRE_CLEAR+0.25))
	out.append(to)
	return out

func _process(delta:float)->void:
	if _moving:_step(delta)
	elif _turning:
		_yaw=rotate_toward(_yaw,_yaw_goal,delta*3.0)
		rotation.y=_yaw
		if is_equal_approx(_yaw,_yaw_goal):_turning=false
	if _held>0.0:
		_held-=delta
		if _held<=0.0:
			_held=0.0
			if _after_hold.is_valid():
				var then:=_after_hold;_after_hold=Callable();then.call()
		return
	if not _moving:
		_think-=delta
		if _think<=0.0:_decide()

func _step(delta:float)->void:
	if _path.is_empty():
		_moving=false;_finish_move();return
	var goal:=_path[0]
	var to:=Vector3(goal.x-position.x,0.0,goal.z-position.z)
	var d:=to.length()
	if d<0.06:
		_path.remove_at(0)
		if _path.is_empty():
			_moving=false;_finish_move()
		return
	var want:=atan2(to.x,to.z)
	# dragging, it backs along the way with its head to what it pulls
	var back:=_gait=="tug"
	var face_want:=want+PI if back else want
	_yaw=rotate_toward(_yaw,face_want,delta*4.5)
	rotation.y=_yaw
	# slow in the turns and as it comes up to the spot
	var facing:=cos(angle_difference(_yaw,face_want))
	var pace:=_speed*clampf(facing,0.15,1.0)*clampf(d/0.35,0.35,1.0)
	var step:=minf(d,pace*delta)
	position+=Vector3(sin(_yaw),0.0,cos(_yaw))*step*(-1.0 if back else 1.0)

func _finish_move()->void:
	var then:=_arrive;_arrive=Callable()
	if then.is_valid():then.call()
	else:play("wag" if mood=="glad" else "idle",0.3)
	arrived.emit()

## Turn to face a point.
func face_toward(point:Vector3)->void:
	_yaw_goal=atan2(point.x-position.x,point.z-position.z)
	_turning=true

# --- What it does by itself ---------------------------------------------------------

func _decide()->void:
	var cs:=court_set()
	if cs==null:return
	if herded:
		_think=99.0;return
	if mood=="afraid":
		# it stays low a while, then gets up again
		mood="calm";play("stand_up",0.3);_think=rng.randf_range(3.0,5.0);return
	var roll:=rng.randf()
	if clip in ["lie","lie_idle"] and roll<0.55:
		_think=rng.randf_range(5.0,10.0);return
	if roll<0.22:
		if not is_down():play("idle",0.3)
		_think=rng.randf_range(3.0,7.0)
	elif roll<0.45:
		# off to sniff at something nearby: the stores, someone's feet, the edge of the fire
		var spots:Array[Marker3D]=cs.call("marks_for","animal_")
		var crowd:Array[Marker3D]=cs.call("marks_for","officials_")
		var pool:Array[Vector3]=[]
		for m in spots:pool.append(m.position)
		for m in crowd:pool.append(m.position+Vector3(0.35,0.0,0.45))
		var target:=pool[rng.randi()%pool.size()]+Vector3(rng.randf_range(-0.4,0.4),0.0,rng.randf_range(-0.4,0.4))
		_think=99.0
		go_to(target,"walk",_sniff_here)
	elif roll<0.68:
		play("sit",0.3);_think=rng.randf_range(5.0,10.0)
		if rng.randf()<0.5:
			var later:=create_tween();later.tween_interval(rng.randf_range(2.0,4.0))
			later.tween_callback(_maybe_scratch)
	elif roll<0.84:
		var fire_spot:Marker3D=cs.call("mark","animal_0")
		if fire_spot!=null and position.distance_to(fire_spot.position)>0.6:
			_think=99.0
			go_to(fire_spot.position,"walk",_lie_here)
		else:
			_lie_here()
	else:
		var spots2:Array[Marker3D]=cs.call("marks_for","animal_")
		var pick:=spots2[rng.randi()%spots2.size()]
		_think=99.0
		go_to(pick.position,"walk",_idle_here)

func _sniff_here()->void:
	play("sniff",0.3);_think=rng.randf_range(2.5,4.5)

func _lie_here()->void:
	play("lie",0.3);_think=rng.randf_range(10.0,18.0)

func _idle_here()->void:
	play("idle",0.3);_think=rng.randf_range(2.0,5.0)

func _maybe_scratch()->void:
	if clip=="sit_idle" and _held<=0.0:
		play("scratch",0.2)
		var stop:=create_tween();stop.tween_interval(rng.randf_range(1.3,2.2))
		stop.tween_callback(_end_scratch)

func _end_scratch()->void:
	if clip=="scratch":play("sit_idle",0.25)

## The director holds the animal for a while; then it goes back to its ways.
func hold(seconds:float,then:=Callable())->void:
	_held=maxf(_held,seconds);_after_hold=then
	_think=maxf(_think,0.5)

# --- What the director can ask ------------------------------------------------------

func sit()->void:
	hold(4.0);play("sit",0.25)

func lie()->void:
	hold(6.0);play("lie",0.3)

func scratch(seconds:=1.8)->void:
	var wait:=0.0
	if not is_down():
		play("sit",0.2);wait=clip_length("sit")
	hold(wait+seconds+0.4)
	var later:=create_tween();later.tween_interval(wait)
	later.tween_callback(_start_scratch)
	later.tween_interval(seconds)
	later.tween_callback(_end_scratch)

func _start_scratch()->void:
	play("scratch",0.2)

func bark(times:=1)->void:
	hold(0.55*times+0.4)
	var seq:=create_tween()
	for i in times:
		seq.tween_callback(_bark_once)
		seq.tween_interval(0.5)

func _bark_once()->void:
	clip="";play("bark",0.08)

func wag(seconds:=2.5)->void:
	mood="glad";hold(seconds,_calm);play("wag",0.2)

func _calm()->void:
	mood="calm"
	if clip=="wag":play("idle",0.3)

func look_up()->void:
	hold(2.0);play("look_up",0.2)

func tilt()->void:
	hold(2.8);play("tilt",0.2)

## Down low, ears flat, tail tucked, trembling, for a while (the god's wrath).
func cower(seconds:=4.5)->void:
	mood="afraid";_moving=false;_path.clear()
	hold(seconds,_recover)
	play("cower",0.15)

func _recover()->void:
	mood="calm";play("stand_up",0.4);_think=rng.randf_range(2.0,4.0)

## Go and sniff something: a point or someone (a Node3D), then come away.
func sniff_at(target:Variant,seconds:=3.0)->void:
	var at:=Vector3.ZERO
	if target is Node3D:at=(target as Node3D).global_position
	elif target is Vector3:at=target
	var away:=Vector3(position.x-at.x,0.0,position.z-at.z)
	if away.length()<0.01:away=Vector3(0.0,0.0,1.0)
	hold(30.0)
	go_to(at+away.normalized()*0.42,"walk",_sniff_target.bind(at,seconds))

func _sniff_target(at:Vector3,seconds:float)->void:
	face_toward(at);play("sniff",0.25)
	_held=0.0;hold(seconds,_idle_here)

## Trot to a scrap, snatch it, and make off out of the door with it.
func steal_scrap(at:Vector3,exit_mark:="door_out")->void:
	hold(30.0)
	var cs:=court_set()
	var out:=Vector3(-6.0,0.0,1.0)
	if cs!=null and cs.call("has_mark",exit_mark):out=(cs.call("mark",exit_mark) as Marker3D).position
	var away:=Vector3(position.x-at.x,0.0,position.z-at.z)
	if away.length()<0.01:away=Vector3(0.0,0.0,1.0)
	go_to(at+away.normalized()*0.38,"trot",_grab_scrap.bind(at,out))

func _grab_scrap(at:Vector3,out:Vector3)->void:
	face_toward(at);play("grab",0.1)
	_held=0.0;hold(clip_length("grab")+0.05,_run_off.bind(out))

func _run_off(out:Vector3)->void:
	hold(30.0)
	go_to(out,"trot",_gone)

func _gone()->void:
	visible=false
	_held=0.0;hold(9999.0)

## Take something in the mouth (a thighbone, a head): it rides the jaw.
func carry(prop:Node3D)->bool:
	if prop==null or model==null:return false
	var skels:=model.find_children("*","Skeleton3D",true,false)
	if skels.is_empty():return false
	var skel:=skels[0] as Skeleton3D
	var bone:="jaw" if skel.find_bone("jaw")>=0 else "head"
	var attach:=skel.get_node_or_null("Mouth") as BoneAttachment3D
	if attach==null:
		attach=BoneAttachment3D.new();attach.name="Mouth";attach.bone_name=bone
		skel.add_child(attach)
	if prop.get_parent()!=null:prop.get_parent().remove_child(prop)
	attach.add_child(prop)
	# crosswise in the teeth, a little ahead of the jaw's root
	prop.transform=Transform3D(Basis.IDENTITY,Vector3(0.0,0.06,0.02))
	carried=prop
	return true

## Let go of what it carries, onto the ground in front of it.
func drop_carried()->Node3D:
	if carried==null or not is_instance_valid(carried):return null
	var thing:=carried;carried=null
	var where:=global_position+global_transform.basis.z*0.45
	var cs:=court_set()
	thing.get_parent().remove_child(thing)
	(cs if cs!=null else get_parent()).add_child(thing)
	thing.global_transform=Transform3D(Basis(Vector3.UP,rotation.y),Vector3(where.x,0.04,where.z))
	return thing

## Go and bring something back: trot to it, take it, trot to `to`, drop it
## there and wag (the dog with the thighbone at the god's feet).
func fetch(thing:Node3D,to:Vector3)->void:
	if thing==null:return
	hold(60.0)
	go_to(thing.global_position,"trot",_fetch_take.bind(thing,to))

func _fetch_take(thing:Node3D,to:Vector3)->void:
	if not is_instance_valid(thing):cancel_action();return
	play("grab",0.1)
	carry(thing)
	_held=0.0;hold(clip_length("grab"),_fetch_bring.bind(to))

func _fetch_bring(to:Vector3)->void:
	hold(60.0)
	go_to(to,"carry",_fetch_drop)

func _fetch_drop()->void:
	drop_carried()
	_held=0.0;wag(3.0)

## Brought in for an act: it stands where it is put until the director moves it.
var herded:=false

## One of its own acts, start to end, then back to standing: the bear's
## "rear", "gulp", "burp", "spit"; the ox's "shake_hoof"; the elephant's
## "stomp", "shake_foot", "trumpet"; the pig's "squeal". `then` when done.
func perform(clip_name:String,then:=Callable())->float:
	var seconds:=clip_length(clip_name)
	if seconds<=0.0:
		if then.is_valid():then.call()
		return 0.0
	_moving=false;_path.clear()
	_held=0.0;hold(seconds,then if then.is_valid() else _idle_here)
	clip="";play(clip_name,0.15)
	return seconds

## Go to a spot and feed there (the pigs at the pen, act 9): trot over,
## then eat in a frenzy for `seconds`.
func feed_at(point:Vector3,seconds:=6.0)->void:
	_held=0.0;hold(60.0)
	var cs:=court_set()
	var local:=cs.to_local(point) if cs!=null and cs.is_inside_tree() else point
	go_to(local,"trot",_feed_here.bind(seconds,point))

func _feed_here(seconds:float,point:Vector3)->void:
	face_toward(point)
	_held=0.0;hold(seconds,_idle_here)
	play("eat",0.2)

## Run (a stampede, act 8) to `point` at the gallop.
func stampede_to(point:Vector3,then:=Callable())->void:
	_held=0.0;hold(60.0)
	var cs:=court_set()
	go_to(cs.to_local(point) if cs!=null and cs.is_inside_tree() else point,"gallop",then)

## Off out of the door at a trot, and gone (the pack, when it is done).
func leave(exit_mark:="door_out")->void:
	var cs:=court_set()
	var out:=Vector3(-6.0,0.0,1.0)
	if cs!=null and cs.call("has_mark",exit_mark):out=(cs.call("mark",exit_mark) as Marker3D).position
	_held=0.0;hold(30.0)
	go_to(out,"trot",_gone)

## Drag something off along `points` (global; the set's drag_route()), backing
## away with it braced in its jaws; at the end it lies down to it (crunch).
func drag_off(points:Array,then:=Callable())->void:
	_held=0.0;hold(120.0)
	_drag_next(points.duplicate(),then)

func _drag_next(points:Array,then:Callable)->void:
	if points.is_empty():
		_held=0.0
		if then.is_valid():then.call()
		else:crunch(6.0)
		return
	var p:Vector3=points.pop_front()
	var cs:=court_set()
	var local:=cs.to_local(p) if cs!=null and cs.is_inside_tree() else p
	go_to(local,"tug",_drag_next.bind(points,then))

## Pull at something, braced, head wrenching (dragging a body off): seconds.
func tug(seconds:=2.5)->void:
	hold(seconds,_idle_here)
	play("tug",0.15)

## Down over something, gnawing (the crunching behind the windbreak): seconds.
func crunch(seconds:=3.0)->void:
	hold(seconds,_recover)
	play("crunch",0.2)

## The god acts: "speaks" (ears up, a tilt), "wrath" (it cowers), "favour" (a wag).
func on_god(kind:String)->void:
	match kind:
		"wrath":cower(rng.randf_range(4.0,6.0))
		"favour":wag(3.0)
		_:
			if is_down():look_up()
			elif rng.randf()<0.5:tilt()
			else:look_up()

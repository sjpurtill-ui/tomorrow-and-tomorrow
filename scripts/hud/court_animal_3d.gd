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
## Each species' paint by slot.
const PALETTE:={
	"dog":{"COAT":"a06c3b","COAT_LIGHT":"e0c99e","COAT_DARK":"5f4027","NOSE":"1d1612","EYE":"150f0c","EYE_SHINE":"fbf6ea"},
}
## What a one-off clip settles into when it ends.
const AFTER:={"sit":"sit_idle","lie":"lie_idle","cower":"cower_idle","stand_up":"idle","look_up":"idle","bark":"idle","grab":"idle","tilt":"idle"}
## Clips the animal is down in (it must stand up before it walks).
const DOWN:=["sit","sit_idle","scratch","lie","lie_idle"]
## Keep clear of the fire by this much when walking past it.
const FIRE_CLEAR:=1.05

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
func setup(species_name:String,court_set:Node3D,seed_value:=0)->bool:
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
	shade=load("res://scripts/hud/court_set_3d.gd").call("contact_shadow",0.42,0.78,0.5)
	add_child(shade)
	return true

func _dress()->void:
	var paint:Dictionary=PALETTE.get(species,{})
	for node in model.find_children("*","MeshInstance3D",true,false):
		var mesh_node:=node as MeshInstance3D
		mesh_node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		if mesh_node.mesh==null:continue
		for surface in mesh_node.mesh.get_surface_count():
			var source:=mesh_node.mesh.surface_get_material(surface)
			var slot:=source.resource_name if source!=null else "COAT"
			mesh_node.set_surface_override_material(surface,_material(slot,Color(String(paint.get(slot,"8a6a48")))))

static func _material(slot:String,colour:Color)->ShaderMaterial:
	var key:="%s|%s" % [slot,colour.to_html(false)]
	if _materials.has(key):return _materials[key]
	var made:=ShaderMaterial.new();made.shader=TOON
	made.set_shader_parameter("albedo",colour);made.set_shader_parameter("albedo_worn",colour)
	made.set_shader_parameter("mottle",0.06);made.set_shader_parameter("variation",0.0)
	made.set_shader_parameter("grain",0.04);made.set_shader_parameter("wrap",0.15)
	match slot:
		"EYE_SHINE":made.set_shader_parameter("emission_color",Color(1,1,1));made.set_shader_parameter("emission_amount",0.8)
		"EYE","NOSE":made.set_shader_parameter("rim_amount",0.25)
		_:made.set_shader_parameter("rim_amount",0.10)
	if not slot in ["EYE","EYE_SHINE"]:
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
	var z:=m.basis.z
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
	if player==null or not player.has_animation(clip_name):return
	if clip_name==clip and at<0.0 and player.is_playing():return
	clip=clip_name
	player.play(clip_name,blend)
	if at>=0.0:player.seek(fmod(at,player.get_animation(clip_name).length),true)

func _on_finished(finished:StringName)->void:
	var next:=String(AFTER.get(String(finished),""))
	if next=="idle" and mood=="glad":next="wag"
	if not next.is_empty() and not _moving:play(next,0.3)

func is_down()->bool:
	return clip in DOWN

func clip_length(clip_name:String)->float:
	return player.get_animation(clip_name).length if player!=null and player.has_animation(clip_name) else 0.0

# --- Moving -------------------------------------------------------------------------

## Walk (or trot) to a point on the ground, round the fire, then do `then`.
func go_to(point:Vector3,gait:="walk",then:=Callable())->void:
	_arrive=then
	_gait=gait if gait in ["walk","trot"] else "walk"
	_speed=float((info.get("speeds",{}) as Dictionary).get(_gait,0.8))
	_path=_route(position,Vector3(point.x,0.0,point.z))
	if is_down():
		# up first, then off
		play("stand_up",0.2)
		var wait:=create_tween();wait.tween_interval(clip_length("stand_up")*0.8);wait.tween_callback(_set_off)
	else:
		_set_off()

func _set_off()->void:
	_moving=not _path.is_empty()
	if _moving:play(_gait,0.25)
	else:_finish_move()

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
	_yaw=rotate_toward(_yaw,want,delta*4.5)
	rotation.y=_yaw
	# slow in the turns and as it comes up to the spot
	var facing:=cos(angle_difference(_yaw,want))
	var pace:=_speed*clampf(facing,0.15,1.0)*clampf(d/0.35,0.35,1.0)
	var step:=minf(d,pace*delta)
	position+=Vector3(sin(_yaw),0.0,cos(_yaw))*step

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

## The god acts: "speaks" (ears up, a tilt), "wrath" (it cowers), "favour" (a wag).
func on_god(kind:String)->void:
	match kind:
		"wrath":cower(rng.randf_range(4.0,6.0))
		"favour":wag(3.0)
		_:
			if is_down():look_up()
			elif rng.randf()<0.5:tilt()
			else:look_up()

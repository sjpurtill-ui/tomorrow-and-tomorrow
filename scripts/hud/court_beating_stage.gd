extends Node
## Nonfatal court punishment. This scene owns presentation only, never adjudication.
const Acting:=preload("res://scripts/hud/court_acting.gd")
const Attack:=preload("res://scripts/hud/court_beating_attack.gd")
const Movement:=preload("res://scripts/hud/court_exec_stage.gd")
const Executions:=preload("res://scripts/hud/court_executions.gd")
const Director:=preload("res://scripts/hud/court_director.gd")
signal finished
var stage:Control
var victim:=""
var style:="full"
var attackers:Array[String]=[]
var impact_count:=0
var max_contact_gap:=0.0
var elapsed:=0.0
var _start:=0.0
var _end:=0.0
var _begun:=false
var _ended:=false
var _movement:Node
var _saved:Dictionary={}
var _tweens:Array[Tween]=[]
var _modifiers:Array[SkeletonModifier3D]=[]
var _reaction:SkeletonModifier3D
var _court:Node3D
var _returning:=false
var _attack_framed:=false

func _init()->void:set_process(false)

func begin(on_stage:Control,victim_key:String,actor_key:String,how:String)->bool:
	stage=on_stage;victim=victim_key;style=how
	var f:Variant=_figure(victim)
	if f==null or f.body3d==null or f.leaving or Executions.is_child(f.person) or style=="off":return false
	_court=stage.get("court_set") as Node3D
	if _court==null:return false
	_movement=Movement.new();_movement.set("stage",stage);_movement.set("victim",victim)
	var cast:Array=Director.normal_cast(stage.call("cast_list"),Director.normal_facts(stage.get("facts")))
	var candidates:Array[String]=[]
	for entry:Dictionary in cast:
		var key:=String(entry.get("key",""));var who:Variant=_figure(key)
		if who==null or who.body3d==null or who.leaving or key==victim or Executions.is_child(who.person):continue
		if not eligible_attacker(entry):continue
		if key==actor_key:candidates.push_front(key)
		else:candidates.append(key)
	if not actor_key.is_empty() and not actor_key in candidates:
		set_meta("fallback_reason","The adjudicated actor is not an eligible adult in this court.");_dispose_movement();return false
	var routes:Array[PackedVector3Array]=[]
	var body:Node3D=f.body3d
	var camera:Camera3D=stage.get("camera") as Camera3D
	var front:=Vector3(0,0,1) if camera==null else camera.global_position-body.global_position
	front.y=0.0;front=front.normalized()
	for key:String in candidates:
		if attackers.size()>=3:break
		var destination:=body.global_position+front.rotated(Vector3.UP,deg_to_rad([78.0,180.0,282.0][attackers.size()]))*0.62
		destination.y=body.global_position.y
		var route:PackedVector3Array=_movement.call("_walk_path",key,destination)
		if route.size()<2:
			if key==actor_key:
				set_meta("fallback_reason","The adjudicated actor cannot reach the victim.");_dispose_movement();return false
			continue
		attackers.append(key);routes.append(route)
	if attackers.size()<2:_dispose_movement();attackers.clear();set_meta("fallback_reason","Fewer than two reachable adult court supporters.");return false
	_begun=true
	_save(victim)
	body.play("stand",0.12);Acting.stop(body,0.0)
	Acting.play(body,"kneel_bound",{"blend":0.12,"hold":true})
	Acting.set_mood(body,{"fear":1.0,"tired":0.85})
	_reaction=Attack.new();_reaction.configure(body,body,0,true)
	body.skeleton.add_child(_reaction);_modifiers.append(_reaction)
	_start=2.6
	for i in attackers.size():
		var key:=attackers[i];var who:Variant=_figure(key);var other:Node3D=who.body3d
		_save(key);Acting.stop(other,0.0);other.play("walk_in",0.15,0.0)
		var duration:=clampf(Movement._walk_length(routes[i])/1.4,0.45,3.8)
		_start=maxf(_start,duration+0.3)
		var tween:=create_tween();_tweens.append(tween)
		Movement._queue_walk(tween,who,other,routes[i],duration)
		tween.tween_callback(_ready_attacker.bind(key,i))
	_end=_start+Attack.PERIOD*float(Attack.STRIKES)+0.96+1.25
	set_process(true);_publish("approach")
	return true

static func eligible_attacker(entry:Dictionary)->bool:
	var member:=Director.member(entry)
	if int(member.age)<18 or String(member.role)=="attendant":return false
	var kind:=String(member.kind)
	if kind not in ["official","hearth_chief","guard","door_guard","commoner","elder"]:return false
	# Appearance ancestry is not allegiance: a naturalized officeholder is ours.
	# Foreign guards remain part of an envoy's retinue, never this punishment.
	return kind!="guard" or String(member.people) in ["","player"]

func _figure(key:String)->Variant:return stage.call("figure",key) if is_instance_valid(stage) else null

func _save(key:String)->void:
	var f:Variant=_figure(key);var b:Node3D=f.body3d
	var props:Array=[]
	for name:String in ["prop_staff","prop_bowl"]:
		for p:Node3D in b.find_children(name,"MeshInstance3D",true,false):props.append({"node":p,"visible":p.visible});p.visible=false
	var acting:=Acting.of(b)
	_saved[key]={"nudge":f.nudge,"rotation":b.rotation,"clip":String(f.rest_clip),"lift":f.lift,"visible":b.visible,"mood":b.mood,"stance":b.stance,"props":props,"idle":f.idle,"ambient":float(acting.ambient) if acting!=null else 1.0}
	f.idle=false;Acting.set_ambient(b,0.0)
	var prior:Variant=f.get("_act")
	if prior is Tween and prior.is_valid():prior.kill()
	b.stance="stand"
	if b.player!=null:b.player.speed_scale=1.0
	if acting!=null:
		acting.set("_speech_t",-1.0);acting.set("speaking",false);acting.set("_g",-1)
		acting.set("_a",null);acting.set("_b",null)
		acting.set("_attention_until",-1.0);acting.set("_look_kind",0);acting.set("_look_weight",0.0)

func _ready_attacker(key:String,index:int)->void:
	if _ended:return
	var f:Variant=_figure(key);var v:Variant=_figure(victim)
	if f==null or v==null:return
	var b:Node3D=f.body3d
	b.set_locomotion_rate(1.0);b.play("stand",0.15)
	var toward:Vector3=v.body3d.global_position-b.global_position
	b.face(rad_to_deg(atan2(toward.x,toward.z))-rad_to_deg(b.get_parent_node_3d().global_rotation.y),0.2)
	var modifier:=Attack.new();modifier.configure(b,v.body3d,index)
	b.skeleton.add_child(modifier);_modifiers.append(modifier)
	modifier.contact.connect(_impact)

func _process(delta:float)->void:
	if _ended:return
	elapsed+=delta
	if _returning:return
	if not _attack_framed and elapsed>=_start:
		_attack_framed=true
		if stage.has_method("frame_beating"):stage.call("frame_beating")
	for modifier:SkeletonModifier3D in _modifiers:
		if is_instance_valid(modifier):modifier.set("clock",elapsed-_start)
	_publish("approach" if elapsed<_start else ("aftermath" if elapsed>_end-1.25 else "beating"))
	if elapsed>=_end:_return_home()

func _impact(index:int,point:Vector3,gap:float)->void:
	if _ended:return
	impact_count+=1;max_contact_gap=maxf(max_contact_gap,gap)
	_reaction.call("hit")
	var f:Variant=_figure(victim)
	if f==null:return
	var body:Node3D=f.body3d
	var sound:Variant=stage.get("_sound")
	if is_instance_valid(sound):
		sound.call("cue","gore_splat" if style=="full" else "slap",body,{"variant":impact_count%(3 if style=="full" else 2),"db":-5.0})
	if style=="full" and _court.has_method("blood"):
		var blood:Node3D=_court.call("blood")
		if impact_count%2==1:blood.call("stain_figure",body,2,body.get_meta("beating_rendered_bone_frames",{}))
		var at:=_court.to_local(point);at.y=0.0
		at+=Vector3(sin(float(impact_count)*2.4)*0.23,0.0,cos(float(impact_count)*2.4)*0.23)
		blood.call("splat",at,0.12+float(impact_count)*0.018,0.92,0.0,0.65)
	set_meta("last_attacker",index);set_meta("last_contact",point)
	_publish("beating")

func _publish(state:String)->void:
	set_meta("beating_state",state);set_meta("attackers",attackers.duplicate());set_meta("attacker_count",attackers.size())
	var participants:Array[String]=[victim];participants.append_array(attackers);set_meta("participant_keys",participants)
	set_meta("impact_count",impact_count);set_meta("max_contact_gap",max_contact_gap);set_meta("elapsed",elapsed)
	var f:Variant=_figure(victim)
	set_meta("victim_visible",f!=null and f.body3d!=null and f.body3d.visible)

func skip()->void:_finish()
func cancel()->void:_finish()

func _return_home()->void:
	_returning=true;_publish("returning")
	for modifier:SkeletonModifier3D in _modifiers:
		if is_instance_valid(modifier):modifier.call("cancel");modifier.queue_free()
	_modifiers.clear()
	var longest:=0.3
	for key:String in attackers:
		var f:Variant=_figure(key)
		if f==null or f.body3d==null:continue
		var body:Node3D=f.body3d
		var destination:Vector3=f.spot.to_global(f._path_at(f.stroll)+Vector3(_saved[key].nudge))
		var path:PackedVector3Array=_movement.call("_walk_path",key,destination)
		if path.size()<2:continue
		var duration:=clampf(Movement._walk_length(path)/1.5,0.3,2.8)
		longest=maxf(longest,duration)
		Acting.stop(body,0.1);body.play("walk_in",0.15)
		var tween:=create_tween();_tweens.append(tween)
		Movement._queue_walk(tween,f,body,path,duration)
	var end:=create_tween();_tweens.append(end)
	end.tween_interval(longest+0.05);end.tween_callback(_finish)

func _dispose_movement()->void:
	if is_instance_valid(_movement):_movement.free()
	_movement=null

func _finish()->void:
	if _ended:return
	_ended=true;set_process(false)
	for tween:Tween in _tweens:
		if tween.is_valid():tween.kill()
	_tweens.clear()
	for modifier:SkeletonModifier3D in _modifiers:
		if is_instance_valid(modifier):modifier.call("cancel");modifier.queue_free()
	_modifiers.clear()
	for key:String in _saved:
		var f:Variant=_figure(key)
		if f==null or f.body3d==null:continue
		var b:Node3D=f.body3d;var saved:Dictionary=_saved[key]
		Acting.stop(b,0.0);Acting.set_ambient(b,float(saved.ambient))
		f.nudge=saved.nudge;f.lift=saved.lift;f.idle=saved.idle
		b.rotation=saved.rotation;b.visible=saved.visible;b.mood=saved.mood;b.stance=saved.stance
		Acting.set_mood(b,String(saved.mood))
		b.face(rad_to_deg((saved.rotation as Vector3).y),0.0)
		b.play(String(saved.clip),0.15);b.set_locomotion_rate(1.0)
		for prop:Dictionary in saved.props:
			if is_instance_valid(prop.node):prop.node.visible=prop.visible
	_saved.clear();_dispose_movement();_publish("ended")
	finished.emit()
	if is_inside_tree():queue_free()

func _exit_tree()->void:
	if not _ended:_finish()

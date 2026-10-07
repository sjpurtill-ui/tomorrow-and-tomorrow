extends Node
## A physical custody presentation. The caller supplies the adjudicated departure.
const Acting:=preload("res://scripts/hud/court_acting.gd")
const Grip:=preload("res://scripts/hud/court_custody_grip.gd")
const Movement:=preload("res://scripts/hud/court_exec_stage.gd")
const Beating:=preload("res://scripts/hud/court_beating_stage.gd")
const Director:=preload("res://scripts/hud/court_director.gd")
const Executions:=preload("res://scripts/hud/court_executions.gd")
const Paths:=preload("res://scripts/hud/court_paths.gd")
const Motion:=preload("res://scripts/hud/motion.gd")
const APPROACH_RADIUS:=0.50
const CONVOY_GAP:=0.75
const ESCORT_SPEED:=0.85
const RETURN_SPEED:=1.15
const ESCORT_STALL_TIMEOUT:=2.0
signal finished
var stage:Control
var victim:=""
var depart:=false
var presentation_mode:="detain"
var support_keys:Array[String]=[]
var elapsed:=0.0
var grip_contacts:=0
var max_grip_gap:=0.0
var escorted:=false
var _court:Node3D
var _movement:Node
var _saved:Dictionary={}
var _tweens:Array[Tween]=[]
var _grips:Array[SkeletonModifier3D]=[]
var _receiver:SkeletonModifier3D
var _cord:Node3D
var _out_paths:Dictionary={}
var _state:="idle"
var _start:=0.0
var _bound_at:=-1.0
var _begun:=false
var _ended:=false
var _walkers:Array[Dictionary]=[]
var _return_queue:Array[String]=[]
var _escort_stalled_for:=0.0
var _phase_at:=0.0

func _init()->void:name="CustodyStage";set_process(false)

func begin(on_stage:Control,victim_key:String,actor_key:String,should_depart:bool,presentation:="detain")->bool:
	stage=on_stage;victim=victim_key;depart=should_depart;presentation_mode=presentation
	if presentation_mode not in ["detain","exile"] or (presentation_mode=="exile" and not depart):return false
	var f:Variant=_figure(victim)
	if f==null or f.body3d==null or f.leaving or Executions.is_child(f.person):return false
	_court=stage.get("court_set") as Node3D
	if _court==null:return false
	_movement=Movement.new();_movement.set("stage",stage);_movement.set("victim",victim)
	var cast:Array=Director.normal_cast(stage.call("cast_list"),Director.normal_facts(stage.get("facts")))
	var candidates:Array[String]=[]
	var priorities:Dictionary={}
	for entry:Dictionary in cast:
		var key:=String(entry.get("key",""));var who:Variant=_figure(key)
		if who==null or who.body3d==null or who.leaving or not who.body3d.visible or key==victim or not eligible_support(entry,who.person):continue
		candidates.append(key)
		priorities[key]=-1 if key==actor_key else (0 if String(Director.member(entry).kind) in ["guard","door_guard"] else 1)
	candidates.sort_custom(func(a:String,b:String)->bool:return int(priorities[a])<int(priorities[b]))
	if not actor_key.is_empty() and not candidates.has(actor_key):return _reject("The adjudicated actor is not an eligible adult in this court.")
	var routes:Array[PackedVector3Array]=[]
	var destinations:Array[Vector3]=[]
	var body:Node3D=f.body3d
	var exit_point:=Vector3.ZERO
	if depart:
		if not _court.has_method("door_points"):return _reject("This court has no checked exit.")
		var doors:Array=_court.call("door_points")
		if doors.size()<2:return _reject("This court has no checked exit.")
		exit_point=doors[1]
	for key:String in candidates:
		if support_keys.size()==2:break
		var to:=exile_approach_point(body,exit_point,support_keys.size()) if presentation_mode=="exile" else approach_point(body,support_keys.size())
		var path:PackedVector3Array=_movement.call("_walk_path",key,to)
		if path.size()<2:
			if key==actor_key:return _reject("The adjudicated actor cannot reach the victim.")
			continue
		support_keys.append(key);routes.append(path);destinations.append(to)
	if support_keys.size()!=2:return _reject("Two reachable adult court supporters are required.")
	if depart:
		var ignored:Array[String]=[victim];ignored.append_array(support_keys)
		_out_paths[victim]=_path_from(body.global_position,exit_point,ignored)
		for i in support_keys.size():_out_paths[support_keys[i]]=_path_from(destinations[i],exit_point,ignored)
		for path:PackedVector3Array in _out_paths.values():
			if path.size()<2:return _reject("The custody party cannot reach the actual court door.")
	_begun=true
	_save(victim)
	Acting.stop(body,0.0);body.play("stand",0.15)
	if presentation_mode=="detain":
		Acting.set_mood(body,{"fear":0.6,"tired":0.25})
		_receiver=Grip.new();_receiver.configure(body,body,0,true);body.skeleton.add_child(_receiver)
		_cord=Grip.make_cord(body);_receiver.cord=_cord
	else:Acting.set_mood(body,{"fear":0.15,"tired":0.15})
	_start=0.4
	for i in support_keys.size():
		var key:=support_keys[i];_save(key)
		var who:Variant=_figure(key);var other:Node3D=who.body3d
		Acting.stop(other,0.0);other.play("walk_in",0.15,0.0)
		var duration:=clampf(Movement._walk_length(routes[i])/1.2,0.45,4.0)
		_start=maxf(_start,duration+0.3)
		var tween:=_tween();Movement._queue_walk(tween,who,other,routes[i],duration)
		tween.tween_callback(_ready_support.bind(key,i))
	set_process(true);_publish("approach")
	if Motion.reduced():call_deferred("skip")
	return true

static func approach_point(body:Node3D,slot:int)->Vector3:
	var point:=body.global_position+body.global_basis.x.normalized()*(APPROACH_RADIUS if slot==0 else -APPROACH_RADIUS)
	point.y=body.global_position.y
	return point

static func exile_approach_point(body:Node3D,door:Vector3,slot:int)->Vector3:
	# The named actor indicates the exit from its side of the target, so the
	# target cannot hide an arm extended through them toward the doorway.
	var first:=0 if approach_point(body,0).distance_squared_to(door)<=approach_point(body,1).distance_squared_to(door) else 1
	return approach_point(body,first if slot==0 else 1-first)

static func eligible_support(entry:Dictionary,person:Dictionary)->bool:
	return not Executions.is_child(person) and Beating.eligible_attacker(entry)

func _reject(reason:String)->bool:
	set_meta("fallback_reason",reason);_dispose_movement();support_keys.clear();return false

func _figure(key:String)->Variant:return stage.call("figure",key) if is_instance_valid(stage) else null
func _tween()->Tween:
	var tween:=create_tween();_tweens.append(tween);return tween

func _save(key:String)->void:
	var f:Variant=_figure(key);var b:Node3D=f.body3d
	var props:Array=[]
	for name:String in ["prop_staff","prop_bowl"]:
		for prop:Node3D in b.find_children(name,"MeshInstance3D",true,false):props.append({"node":prop,"visible":prop.visible});prop.visible=false
	var actor:=Acting.of(b)
	_saved[key]={"figure":f,"nudge":f.nudge,"rotation":b.rotation,"world":b.global_position,"clip":String(f.rest_clip),"lift":f.lift,"leaving":f.leaving,"visible":b.visible,"mood":b.mood,"stance":b.stance,"props":props,"idle":f.idle,"ambient":float(actor.ambient) if actor!=null else 1.0}
	f.idle=false;Acting.set_ambient(b,0.0)
	for name:String in ["_act","_step","_lean","_bob"]:
		var prior:Variant=f.get(name)
		if prior is Tween and prior.is_valid():prior.kill()
	b.stance="stand"
	if b.player!=null:b.player.speed_scale=1.0
	if actor!=null:
		actor.set("_speech_t",-1.0);actor.set("speaking",false);actor.set("_g",-1);actor.set("_a",null);actor.set("_b",null)
		actor.set("_attention_until",-1.0);actor.set("_look_kind",0);actor.set("_look_weight",0.0)

func _ready_support(key:String,slot:int)->void:
	if _ended:return
	var f:Variant=_figure(key);var v:Variant=_figure(victim)
	if f==null or v==null:return
	var body:Node3D=f.body3d;body.set_locomotion_rate(1.0);body.play("stand",0.15)
	if presentation_mode=="exile":
		_face_toward(body,v.body3d.global_position,0.25)
		Acting.look_toward(body,v.body3d,0.8)
		return
	body.face(rad_to_deg(v.body3d.global_rotation.y-body.get_parent_node_3d().global_rotation.y),0.15)
	Acting.play(body,"grab_r" if slot==0 else "grab_l",{"blend":0.15,"hold":true})
	var modifier:=Grip.new();modifier.configure(body,v.body3d,slot);body.skeleton.add_child(modifier)
	modifier.acquired.connect(_gripped);_grips.append(modifier)

func _process(delta:float)->void:
	if _ended:return
	elapsed+=delta
	if _state=="approach" and elapsed>=_start:
		if presentation_mode=="exile":
			_phase_at=elapsed;_publish("confront")
			var body:Node3D=_figure(victim).body3d
			Acting.gesture(body,"freeze",0.45)
			Acting.look_toward(body,_figure(support_keys[0]).body3d,0.7)
		else:_publish("grip")
		if stage.has_method("frame_custody"):stage.call("frame_custody")
	if _state=="grip":
		for modifier:SkeletonModifier3D in _grips:modifier.weight=smoothstep(0.0,0.65,elapsed-_start)
		if grip_contacts>=2 and elapsed>=_start+1.0:
			_bound_at=elapsed;_publish("binding")
		elif elapsed>_start+3.0:
			set_meta("fallback_reason","The supporters could not establish physical contact.");cancel()
	elif _state=="binding":
		_receiver.bound_weight=smoothstep(0.0,0.75,elapsed-_bound_at)
		if elapsed>=_bound_at+1.35:
			_figure(victim).body3d.set_meta("custody_bound",true)
			if depart:_escort()
			else:_return_supports()
	elif _state=="confront" and elapsed>=_phase_at+0.6:
		_point_to_exit()
	elif _state=="door_gesture" and elapsed>=_phase_at+1.2:
		_phase_at=elapsed;_publish("turn")
		var body:Node3D=_figure(victim).body3d
		var path:PackedVector3Array=_out_paths[victim]
		_face_toward(body,path_point(path,0.6),0.4)
		Acting.look_toward(body,path[-1]+Vector3.UP*1.3,0.6)
		Acting.gesture(body,"deflate",0.55)
	elif _state=="turn" and elapsed>=_phase_at+0.45:
		_escort()
	if _state=="escort":_advance_escort(delta)
	elif _state=="returning":_advance_return(delta)
	set_meta("elapsed",elapsed)

func _point_to_exit()->void:
	_phase_at=elapsed;_publish("door_gesture")
	var key:=support_keys[0];var body:Node3D=_figure(key).body3d
	var path:PackedVector3Array=_out_paths[key];var door:=path[-1]
	var side:=1.0 if body.to_local(door).x>=0.0 else -1.0
	var clip:="point_l" if side>0.0 else "point_r"
	var direction:=door-body.global_position
	# The authored index points sideways and forward (.6, .78), not straight
	# ahead. Turn that actual pointing direction toward the court's exit.
	var yaw:=atan2(direction.x,direction.z)-atan2(side*0.6,0.78)
	body.face(rad_to_deg(yaw-body.get_parent_node_3d().global_rotation.y),0.25)
	Acting.play(body,clip,{"blend":0.12})
	Acting.look_toward(body,door+Vector3.UP*1.3,0.6)
	set_meta("gesture_actor",key);set_meta("gesture_clip",clip);set_meta("gesture_target",door)

static func _face_toward(body:Node3D,point:Vector3,seconds:float)->void:
	var direction:=point-body.global_position
	if Vector2(direction.x,direction.z).length_squared()<0.000001:return
	var yaw:=atan2(direction.x,direction.z)-body.get_parent_node_3d().global_rotation.y
	body.face(rad_to_deg(yaw),seconds)

func _gripped(_slot:int,gap:float)->void:
	grip_contacts+=1;max_grip_gap=maxf(max_grip_gap,gap)
	set_meta("grip_contacts",grip_contacts);set_meta("max_grip_gap",max_grip_gap)

func _stop_grips()->void:
	for modifier:SkeletonModifier3D in _grips:
		if is_instance_valid(modifier):modifier.call("cancel");modifier.queue_free()
	_grips.clear()

func _escort()->void:
	_stop_grips();_publish("escort")
	var frame_points:=PackedVector3Array()
	for path:PackedVector3Array in _out_paths.values():
		# Endpoint first; at most 24 points across this three-person party.
		for fraction:float in [1.0,0.0,0.33,0.66]:
			var point:=path[roundi(float(path.size()-1)*fraction)]
			frame_points.append(point);frame_points.append(point+Vector3.UP*1.9)
	set_meta("frame_points",frame_points)
	if stage.has_method("frame_custody"):stage.call("frame_custody")
	# The supporter nearer the exit leads. Equal physical speed and clearance,
	# rather than different duration clamps, keep the party from converging.
	var lead:=0 if Movement._walk_length(_out_paths[support_keys[0]])<=Movement._walk_length(_out_paths[support_keys[1]]) else 1
	var keys:Array[String]=[support_keys[lead],victim,support_keys[1-lead]]
	_walkers.clear();_escort_stalled_for=0.0
	for key:String in keys:_walkers.append({"key":key,"path":_out_paths[key],"distance":0.0,"started":false,"done":false})
	set_meta("convoy_order",keys);set_meta("convoy_gap",CONVOY_GAP)

func _advance_escort(delta:float)->void:
	var complete:=0
	var advanced:=false
	for i in _walkers.size():
		var walker:Dictionary=_walkers[i]
		if bool(walker.done):complete+=1;continue
		var here:=path_point(walker.path,float(walker.distance))
		if i>0 and not bool(_walkers[i-1].done):
			var ahead:=path_point(_walkers[i-1].path,float(_walkers[i-1].distance))
			if here.distance_to(ahead)<CONVOY_GAP:continue
		var blockers:=PackedVector3Array()
		for j in _walkers.size():
			if j!=i and not bool(_walkers[j].done):blockers.append(path_point(_walkers[j].path,float(_walkers[j].distance)))
		var next:=clear_step(walker.path,float(walker.distance),minf(ESCORT_SPEED*delta,0.08),blockers)
		if next<=float(walker.distance)+0.000001:continue
		_move_walker(walker,next,ESCORT_SPEED,delta)
		advanced=true
		if float(walker.distance)>=Movement._walk_length(walker.path)-0.0001:
			walker.done=true;complete+=1
			var f:Variant=_figure(String(walker.key))
			# All three have crossed the real outside endpoint. Nobody waits
			# visibly on that point for the following body to walk into them.
			if String(walker.key)==victim:_departed()
			elif f!=null:f.body3d.visible=false
	if complete==_walkers.size():
		_return_supports();return
	_escort_stalled_for=0.0 if advanced else _escort_stalled_for+delta
	if _escort_stalled_for>=ESCORT_STALL_TIMEOUT:
		set_meta("fallback_reason","The checked escort routes cannot keep the party clear; completing the authorized custody outcome.")
		skip()

func _move_walker(walker:Dictionary,distance:float,speed:float,delta:float)->void:
	var f:Variant=_figure(String(walker.key));var body:Node3D=f.body3d
	if not bool(walker.started):
		walker.started=true;body.visible=true
		Acting.stop(body,0.1);body.play("walk_out" if String(walker.key)==victim else "walk_in",0.15)
		if String(walker.key)==victim:Acting.play(body,"walk_sober" if presentation_mode=="exile" else "walk_led",{"blend":0.15,"loop":true})
		var pace:=float(Movement.Figure3D.WALK_SPEED.walk_in)*float(body.body_height)/Movement.Figure3D.REFERENCE_HEIGHT
		body.set_locomotion_rate(speed/maxf(pace,0.1))
	walker.distance=distance
	var point:=path_point(walker.path,distance)
	var before:=path_point(walker.path,maxf(0.0,distance-0.05))
	var direction:=point-before
	if direction.length_squared()>0.000001:
		var yaw:=atan2(direction.x,direction.z)-body.get_parent_node_3d().global_rotation.y
		body.face(rad_to_deg(lerp_angle(body.rotation.y,yaw,minf(1.0,delta*12.0))),0.0)
	f.nudge=f.spot.to_local(point)-f._path_at(f.stroll)
	body.global_position=point

static func path_point(path:PackedVector3Array,distance:float)->Vector3:
	if path.is_empty():return Vector3.ZERO
	for i in range(1,path.size()):
		var length:=path[i-1].distance_to(path[i])
		if distance<=length:return path[i-1].lerp(path[i],distance/maxf(length,0.000001))
		distance-=length
	return path[-1]

## One bounded movement step on a previously checked path. An initially close
## grip formation may separate, but no step may make that existing gap smaller.
static func clear_step(path:PackedVector3Array,distance:float,step:float,blockers:PackedVector3Array,gap:=CONVOY_GAP)->float:
	var from:=path_point(path,distance)
	var high:=minf(distance+step,Movement._walk_length(path))
	var allowed:=func(at:float)->bool:
		var point:=path_point(path,at)
		for blocker:Vector3 in blockers:
			if point.distance_to(blocker)<minf(gap,from.distance_to(blocker))-0.000001:return false
		return true
	if allowed.call(high):return high
	var low:=distance
	for attempt in 8:
		var middle:float=(low+high)*0.5
		if allowed.call(middle):low=middle
		else:high=middle
	return low

func _departed()->void:
	var f:Variant=_figure(victim)
	if f==null:return
	f.leaving=true;f.body3d.visible=false;escorted=true
	set_meta("escorted",true);f.body3d.set_meta("custody_departed",true)

func _return_supports()->void:
	_stop_grips();_publish("returning")
	_walkers.clear();_return_queue.assign(support_keys)
	_next_return()

func _next_return()->void:
	if _return_queue.is_empty():_finish(true);return
	var key:=String(_return_queue.pop_front());var f:Variant=_figure(key)
	# Return separately; the other supporter remains outside the doorway.
	var ignored:Array[String]=[key]
	var path:=_path_from(f.body3d.global_position,_saved[key].world,ignored)
	if path.size()<2:
		_restore(f.body3d,_saved[key]);_next_return();return
	_walkers.assign([{"key":key,"path":path,"distance":0.0,"started":false,"done":false}])

func _advance_return(delta:float)->void:
	if _walkers.is_empty():return
	var walker:Dictionary=_walkers[0]
	var next:=minf(float(walker.distance)+RETURN_SPEED*delta,Movement._walk_length(walker.path))
	_move_walker(walker,next,RETURN_SPEED,delta)
	if next>=Movement._walk_length(walker.path)-0.0001:
		var f:Variant=_figure(String(walker.key));_restore(f.body3d,_saved[walker.key])
		_walkers.clear();_next_return()

func _path_from(from:Vector3,to:Vector3,ignored:Array[String])->PackedVector3Array:
	var room:=Paths.room_of(_court)
	if room==null:return PackedVector3Array()
	var start:=_court.to_local(from);var goal:=_court.to_local(to)
	var people:Array=[]
	for key:String in stage.get("cast_order"):
		if ignored.has(key):continue
		var f:Variant=_figure(key)
		if f==null or f.body3d==null or f.leaving or not f.body3d.visible:continue
		var at:=_court.to_local(f.body3d.global_position);people.append(Vector3(at.x,at.z,0.3))
	var first:=Vector2(start.x,start.z);var last:=Vector2(goal.x,goal.z)
	var route:=Paths.route_with_seats(_court,room,first,last,people)
	if route.is_empty() and Paths._seat_at(_court,first)==null and Paths._seat_at(_court,last)==null:route=Movement._seat_route(_court,room,first,last,people)
	var path:=PackedVector3Array()
	for at:Vector2 in route:path.append(_court.to_global(Vector3(at.x,start.y,at.y)))
	return path

func _publish(state:String)->void:
	_state=state;set_meta("custody_state",state);set_meta("victim",victim);set_meta("depart",depart);set_meta("escorted",escorted)
	set_meta("presentation",presentation_mode)
	set_meta("support_keys",support_keys.duplicate());set_meta("attackers",support_keys.duplicate())
	var keys:Array[String]=[victim];keys.append_array(support_keys);set_meta("participant_keys",keys)
	set_meta("grip_contacts",grip_contacts);set_meta("max_grip_gap",max_grip_gap)

func skip()->void:_finish(true)
func cancel()->void:_finish(false)

func _dispose_movement()->void:
	if is_instance_valid(_movement):_movement.free()
	_movement=null

func _finish(complete:bool)->void:
	if _ended:return
	_ended=true;set_process(false)
	for tween:Tween in _tweens:
		if tween.is_valid():tween.kill()
	_tweens.clear();_walkers.clear();_return_queue.clear();_stop_grips()
	for key:String in support_keys:
		var f:Variant=_figure(key)
		if f!=null and f.body3d!=null and _saved.has(key):_restore(f.body3d,_saved[key])
	var f:Variant=_figure(victim)
	if _begun and f!=null and f.body3d!=null:
		var body:Node3D=f.body3d
		if complete and not depart:
			_receiver.bound_weight=1.0;_receiver.cord=_cord
			body.set_meta("custody_bound",true);body.set_meta("custody_restore",_saved[victim])
			_receiver=null;_cord=null
		elif (complete and depart) or escorted:
			if not escorted:
				var path:PackedVector3Array=_out_paths.get(victim,PackedVector3Array())
				if not path.is_empty():f.nudge=f.spot.to_local(path[-1])-f._path_at(f.stroll)
			_departed()
		else:
			_restore(body,_saved[victim])
			if presentation_mode=="detain":body.set_meta("custody_bound",false)
	if is_instance_valid(_receiver):_receiver.call("cancel");_receiver.queue_free()
	if is_instance_valid(_cord):_cord.queue_free()
	_receiver=null;_cord=null;_saved.clear();_dispose_movement()
	_publish("departed" if escorted else ("bound" if complete and _begun else "cancelled"))
	finished.emit()
	if is_inside_tree():queue_free()

static func _restore(body:Node3D,saved:Dictionary)->void:
	var f:Variant=saved.get("figure")
	if not is_instance_valid(f):return
	Acting.stop(body,0.0);Acting.set_ambient(body,float(saved.ambient))
	f.nudge=saved.nudge;f.lift=saved.lift;f.idle=saved.idle;f.leaving=bool(saved.get("leaving",false))
	body.rotation=saved.rotation;body.visible=saved.visible;body.mood=saved.mood;body.stance=saved.stance
	Acting.set_mood(body,String(saved.mood));body.face(rad_to_deg((saved.rotation as Vector3).y),0.0)
	body.play(String(saved.clip),0.15);body.set_locomotion_rate(1.0)
	for prop:Dictionary in saved.props:
		if is_instance_valid(prop.node):prop.node.visible=prop.visible

static func release_binding(body:Node3D)->void:
	if not is_instance_valid(body):return
	for node:Node in body.find_children("CustodyBinding*","",true,false):
		if node.has_method("cancel"):node.call("cancel")
		node.queue_free()
	var saved:Dictionary=body.get_meta("custody_restore",{})
	if not saved.is_empty():_restore(body,saved)
	for key:String in ["custody_bound","custody_restore","custody_rendered_bone_frames"]:
		if body.has_meta(key):body.remove_meta(key)

func _exit_tree()->void:
	if not _ended:_finish(false)

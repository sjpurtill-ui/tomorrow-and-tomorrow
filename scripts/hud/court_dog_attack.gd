extends Node
## A presentation-only, three-dog contact controller. Its clock belongs to
## CourtExecStage's cancellable tween; no autonomous timers or routes survive it.
const MAX_DOGS:=3
const MAX_TRACES:=18
var dogs:Array[Node3D]=[]
var body:Node3D
var court:Node3D
var skeleton:Skeleton3D
var feet:PackedInt32Array=PackedInt32Array()
var forward:=Vector3.FORWARD
var state:="approach"
var elapsed:=0.0
var contacts:=0
var tug_samples:=0
var _latched:PackedByteArray=PackedByteArray()
var _last_trace:=Vector3.ZERO
var _trace_count:=0
var _trace:Callable

func setup(pack:Array,victim:Node3D,on_court:Node3D,direction:Vector3,trace:=Callable())->void:
	body=victim;court=on_court;forward=direction.normalized();_trace=trace
	skeleton=body.get("skeleton") as Skeleton3D
	for i in mini(pack.size(),MAX_DOGS):
		var dog:Node3D=pack[i]
		if not is_instance_valid(dog):continue
		dogs.append(dog);_latched.append(0)
		feet.append(skeleton.find_bone("foot.L" if i%2==0 else "foot.R") if skeleton!=null else -1)
		dog.call("cancel_action");dog.call("hold",60.0)
		dog.call("play","tug",0.18,float(i)*0.23)
	_last_trace=body.global_position
	_publish()

func target_for(index:int)->Vector3:
	if skeleton!=null and feet[index]>=0:
		var frame:=skeleton.global_transform*skeleton.get_bone_global_pose(feet[index])
		# Third dog takes the trouser cuff above the first ankle, from the side.
		return frame*Vector3(0,-0.10 if index==2 else 0.01,0)
	return body.global_position+forward*0.52+forward.cross(Vector3.UP)*(float(index)-1.0)*0.15

func advance(time:float)->void:
	if state in ["cancelled","aftermath","settled"] or not is_instance_valid(body):return
	var delta:=maxf(time-elapsed,0.0);elapsed=time
	var up:=court.global_basis.y.normalized()
	for i in dogs.size():
		var dog:Node3D=dogs[i]
		if not is_instance_valid(dog):continue
		var target:=target_for(i)
		var side_angle:float=[-0.65,0.60,-1.45][i]
		var face:=(-forward).rotated(up,side_angle)
		var local_face:=dog.get_parent_node_3d().global_basis.inverse()*face
		dog.rotation.y=rotate_toward(dog.rotation.y,atan2(local_face.x,local_face.z),delta*5.0)
		dog.call("_apply_bite_pose",dog.call("_mouth_skeleton"),target,false)
		var offset:Vector3=target-dog.call("mouth_world")
		offset-=up*offset.dot(up)
		if _latched[i]==0:
			# A visible approach, with a bounded last step before purchase.
			dog.global_position+=offset.limit_length(delta*3.6)
			if offset.length()<=maxf(delta*3.6,0.09):_latched[i]=1
		dog.call("bite_at",target,_latched[i]==1)
		dog.set_meta("execution_contact",_latched[i]==1)
		dog.set_meta("execution_tug_phase",fmod(elapsed+float(i)*0.23,0.8))
	contacts=0
	for latched:int in _latched:contacts+=latched
	if contacts>0:
		state="tug";tug_samples+=1
		var at:=body.global_position
		if _trace.is_valid() and _trace_count<MAX_TRACES and at.distance_to(_last_trace)>0.22:
			_trace.call(_last_trace,at,_trace_count);_last_trace=at;_trace_count+=1
	_publish()

func settle(seconds:float)->void:
	if state=="cancelled":return
	state="aftermath"
	for dog:Node3D in dogs:
		if not is_instance_valid(dog):continue
		dog.call("cancel_action");dog.call("hold",maxf(seconds,0.0))
		dog.call("play","crunch",0.15)
		dog.set_meta("execution_aftermath_origin",dog.global_position)
	set_meta("aftermath_seconds",maxf(seconds,0.0));_publish()

func finish_aftermath()->void:
	if state!="aftermath":return
	state="settled"
	for dog:Node3D in dogs:
		if not is_instance_valid(dog):continue
		dog.call("cancel_action");dog.call("hold",60.0);dog.call("play","lie_idle",0.25)
	_publish()

func cancel()->void:
	state="cancelled"
	for dog:Node3D in dogs:
		if is_instance_valid(dog):dog.call("cancel_action")
	contacts=0;_publish()

func _exit_tree()->void:
	if state!="cancelled":cancel()

func _publish()->void:
	set_meta("pack_count",dogs.size());set_meta("attack_state",state)
	set_meta("contact_count",contacts);set_meta("tug_samples",tug_samples)
	set_meta("trace_count",_trace_count)

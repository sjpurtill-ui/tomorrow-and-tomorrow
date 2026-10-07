extends SkeletonModifier3D
## A bounded, nonfatal contact performance, applied after ordinary court acting.
## No saved person or injury state is read or changed here.
const Acting:=preload("res://scripts/hud/court_acting.gd")
const PERIOD:=1.65
const STRIKES:=4
const CONTACT_START:=0.38
const CONTACT_END:=0.52
signal contact(index:int,point:Vector3,gap:float)
var body:Node3D
var victim:Node3D
var index:=0
var clock:=-1.0
var is_victim:=false
var recoil:=0.0
var received:=0
var contacts:=0
var max_gap:=0.0
var _last_strike:=-1
var _cancelled:=false

func configure(on_body:Node3D,on_victim:Node3D,slot:int,receiving:=false)->void:
	body=on_body;victim=on_victim;index=slot;is_victim=receiving
	name="BeatingReaction" if receiving else "BeatingContact"
	if receiving and body.has_meta("beating_rendered_bone_frames"):body.remove_meta("beating_rendered_bone_frames")

func hit()->void:
	received+=1;recoil=1.0

func cancel()->void:
	_cancelled=true;active=false

func _process_modification_with_delta(delta:float)->void:
	apply_pose(delta)

func apply_pose(delta:float)->void:
	if _cancelled or clock<0.0 or not is_instance_valid(body):return
	var sk:=get_skeleton()
	if sk==null:return
	if is_victim:
		recoil=maxf(0.0,recoil-delta*3.8)
		var collapse:=smoothstep(3.2,6.3,clock)
		_rotate(sk,"spine",Vector3.RIGHT,0.15+collapse*0.55+recoil*0.25)
		_rotate(sk,"chest",Vector3.RIGHT,0.12+sin(clock*9.0)*0.035+recoil*0.20)
		_rotate(sk,"head",Vector3.FORWARD,(1.0 if received%2==0 else -1.0)*recoil*0.25)
		_rotate(sk,"head",Vector3.RIGHT,0.18+collapse*0.12)
		for side:String in ["L","R"]:
			_rotate(sk,"upper_arm."+side,Vector3.RIGHT,-0.22-collapse*0.35)
			_rotate(sk,"forearm."+side,Vector3.RIGHT,-0.35-recoil*0.18)
		set_meta("recoil",recoil);set_meta("collapse",collapse)
		var frames:Dictionary={}
		for bone_name:String in ["chest","head"]:
			var bone:=sk.find_bone(bone_name)
			if bone>=0:frames[bone_name]=sk.global_transform*sk.get_bone_global_pose(bone)
		# SkeletonModifier poses are restored after this skeleton renders. Other
		# skeletons must use this final posed frame, not read the restored bones.
		body.set_meta("beating_rendered_bone_frames",frames)
		_publish_rendered_bounds(sk)
		return
	if not is_instance_valid(victim):return
	var local_time:=clock-float(index)*0.48
	if local_time<0.0 or local_time>=float(STRIKES)*PERIOD:
		_publish_rendered_bounds(sk)
		return
	var strike:=int(local_time/PERIOD)
	var phase:=fmod(local_time,PERIOD)
	var side:=1 if (strike+index)%2==0 else 0
	var scale:=float(body.get("body_height"))/1.72
	var attack_weight:=smoothstep(0.0,0.14,phase)*(1.0-smoothstep(0.82,1.15,phase))
	var frames:Dictionary=victim.get_meta("beating_rendered_bone_frames",{})
	if not frames.get("chest") is Transform3D:
		set_meta("contact_phase",false)
		return
	_rotate(sk,"spine",Vector3.RIGHT,0.28*attack_weight)
	_rotate(sk,"chest",Vector3.UP,(1.0 if side==1 else -1.0)*0.20*attack_weight)
	_clench(sk,side,attack_weight)
	var target:=target_point()
	var actor:=Acting.of(body)
	if actor==null:return
	var at:Vector3=actor.fist_frame(side).origin
	var away:=(body.global_position-victim.global_position).normalized()
	var up:=body.global_basis.y.normalized()
	var windup:=target+away*0.38*scale+up*0.35*scale
	var travel:=smoothstep(0.13,CONTACT_START,phase) if phase<=CONTACT_END else 1.0-smoothstep(CONTACT_END,1.02,phase)
	var wanted:=at.lerp(windup.lerp(target,travel),attack_weight)
	# Correct the wrist for the real closed-fist offset, in skeleton coordinates.
	# Two bounded passes handle the imported rig's hand orientation.
	for pass_index in 2:
		var hand:=sk.find_bone("hand.R" if side==1 else "hand.L")
		if hand<0:return
		var fist:Vector3=actor.fist_frame(side).origin
		var wrist:=sk.global_transform*sk.get_bone_global_pose(hand).origin
		solve_arm(sk,side,sk.to_local(wrist+wanted-fist))
	var fist:Vector3=actor.fist_frame(side).origin
	var gap:=fist.distance_to(target)
	set_meta("contact_point",target);set_meta("fist_point",fist)
	set_meta("contact_gap",gap);set_meta("strike",strike);set_meta("side",side)
	set_meta("contact_phase",phase>=CONTACT_START and phase<=CONTACT_END)
	_publish_rendered_bounds(sk)
	if phase>=CONTACT_START and phase<=CONTACT_END and _last_strike!=strike and gap<=0.05:
		_last_strike=strike;contacts+=1;max_gap=maxf(max_gap,gap)
		contact.emit(index,target,gap)

static func _clench(sk:Skeleton3D,side:int,weight:float)->void:
	# court_anims_exec.fist's authored curl, transformed from the figure axes
	# into each imported bone's rest frame, just as the animation baker does.
	var suffix:=".R" if side==1 else ".L"
	var sign_value:=-1.0 if side==1 else 1.0
	for row:Array in [["fingers",96.0],["index",88.0],["thumb",46.0]]:
		var bone:=sk.find_bone(String(row[0])+suffix)
		if bone<0:continue
		var rest:=sk.get_bone_global_rest(bone).basis.get_rotation_quaternion()
		var curl:=Quaternion(Vector3.FORWARD,deg_to_rad(float(row[1])*sign_value))
		var closed:=sk.get_bone_rest(bone).basis.get_rotation_quaternion()*(rest.inverse()*curl*rest)
		sk.set_bone_pose_rotation(bone,sk.get_bone_pose_rotation(bone).slerp(closed,weight).normalized())

func _publish_rendered_bounds(sk:Skeleton3D)->void:
	var feet:=PackedVector3Array()
	for bone_name:String in ["foot.L","foot.R"]:
		var bone:=sk.find_bone(bone_name)
		if bone>=0:feet.append(sk.global_transform*sk.get_bone_global_pose(bone).origin)
	body.set_meta("beating_rendered_bounds",{"head":body.call("head_top"),"feet":feet})

func target_point()->Vector3:
	var frames:Dictionary=victim.get_meta("beating_rendered_bone_frames",{})
	if not frames.get("chest") is Transform3D:return victim.global_position
	var frame:Transform3D=frames.chest
	var direction:=body.global_position-frame.origin;direction.y=0.0
	# The nearest shoulder/upper torso surface; never a point inside the body.
	return frame.origin+direction.normalized()*0.14+frame.basis.y.normalized()*0.08

static func _rotate(sk:Skeleton3D,bone_name:String,axis:Vector3,angle:float)->void:
	var bone:=sk.find_bone(bone_name)
	if bone>=0:sk.set_bone_pose_rotation(bone,sk.get_bone_pose_rotation(bone)*Quaternion(axis,angle))

## Same two-bone construction used by court acting's planted hand.
static func solve_arm(sk:Skeleton3D,side:int,target:Vector3)->void:
	var suffix:=".R" if side==1 else ".L"
	var upper:=sk.find_bone("upper_arm"+suffix);var fore:=sk.find_bone("forearm"+suffix);var hand:=sk.find_bone("hand"+suffix)
	if mini(upper,mini(fore,hand))<0:return
	var u:=sk.get_bone_global_pose(upper);var f:=sk.get_bone_global_pose(fore);var h:=sk.get_bone_global_pose(hand)
	var shoulder:=u.origin;var elbow:=f.origin;var wrist:=h.origin
	var a:=shoulder.distance_to(elbow);var b:=elbow.distance_to(wrist)
	if a<0.001 or b<0.001 or shoulder.distance_squared_to(target)<0.000001:return
	var distance:=clampf(shoulder.distance_to(target),absf(a-b)+0.001,a+b-0.001)
	var direction:=(target-shoulder).normalized()
	var cosine:=clampf((a*a+distance*distance-b*b)/(2.0*a*distance),-1.0,1.0)
	var pole:=(elbow-shoulder)-direction*(elbow-shoulder).dot(direction)
	if pole.length_squared()<0.000001:pole=direction.cross(Vector3.UP)
	if pole.length_squared()<0.000001:pole=Vector3.RIGHT
	var next_elbow:=shoulder+direction*(a*cosine)+pole.normalized()*a*sqrt(maxf(0.0,1.0-cosine*cosine))
	var parent:=sk.get_bone_parent(upper)
	var parent_frame:=sk.get_bone_global_pose(parent) if parent>=0 else Transform3D.IDENTITY
	var q1:=Quaternion((elbow-shoulder).normalized(),(next_elbow-shoulder).normalized())
	var upper_q:=q1*u.basis.get_rotation_quaternion()
	sk.set_bone_pose_rotation(upper,(parent_frame.basis.get_rotation_quaternion().inverse()*upper_q).normalized())
	var next_wrist:=next_elbow+q1*(wrist-elbow)
	var q2:=Quaternion((next_wrist-next_elbow).normalized(),(target-next_elbow).normalized())
	var fore_q:=q2*q1*f.basis.get_rotation_quaternion()
	sk.set_bone_pose_rotation(fore,(upper_q.inverse()*fore_q).normalized())
	sk.set_bone_pose_rotation(hand,(fore_q.inverse()*h.basis.get_rotation_quaternion()).normalized())

extends SkeletonModifier3D
## Court custody contact and binding, entirely presentation-owned.
const Acting:=preload("res://scripts/hud/court_acting.gd")
const Arms:=preload("res://scripts/hud/court_beating_attack.gd")
signal acquired(index:int,gap:float)
var body:Node3D
var victim:Node3D
var index:=0
var receiving:=false
var weight:=0.0
var bound_weight:=0.0
var cord:Node3D
var _acquired:=false
var _cancelled:=false

func configure(on_body:Node3D,on_victim:Node3D,slot:int,receiver:=false)->void:
	body=on_body;victim=on_victim;index=slot;receiving=receiver
	name="CustodyBindingPose" if receiving else "CustodyGrip"
	if receiving and body.has_meta("custody_rendered_bone_frames"):body.remove_meta("custody_rendered_bone_frames")

func cancel()->void:_cancelled=true;active=false
func _process_modification_with_delta(_delta:float)->void:apply_pose()

func apply_pose()->void:
	if _cancelled or not is_instance_valid(body):return
	var sk:=get_skeleton()
	if sk==null:return
	if receiving:
		if bound_weight>0.0:
			var hips:=sk.find_bone("hips")
			var anchor:Vector3=sk.global_transform*sk.get_bone_global_pose(hips).origin if hips>=0 else body.global_position+Vector3.UP*0.9
			var size:=float(body.get("body_height"))/1.72
			for side in 2:
				var hand:=sk.find_bone("hand.L" if side==0 else "hand.R")
				if hand<0:continue
				var wrist:=sk.global_transform*sk.get_bone_global_pose(hand).origin
				var wanted:=anchor+body.global_basis*(Vector3(0.065 if side==0 else -0.065,0.07,0.22)*size)
				Arms.solve_arm(sk,side,sk.to_local(wrist.lerp(wanted,bound_weight)))
				Arms._clench(sk,side,bound_weight*0.55)
		var frames:Dictionary={}
		for bone_name:String in ["head","chest","upper_arm.L","upper_arm.R","forearm.L","forearm.R","hand.L","hand.R"]:
			var bone:=sk.find_bone(bone_name)
			if bone>=0:frames[bone_name]=sk.global_transform*sk.get_bone_global_pose(bone)
		body.set_meta("custody_rendered_bone_frames",frames)
		if is_instance_valid(cord):_place_cord(frames)
		_bounds(sk)
		return
	if not is_instance_valid(victim):return
	var frames:Dictionary=victim.get_meta("custody_rendered_bone_frames",{})
	var suffix:=".L" if index==0 else ".R"
	if not frames.has("upper_arm"+suffix) or not frames.has("forearm"+suffix):return
	var first:Transform3D=frames["upper_arm"+suffix]
	var last:Transform3D=frames["forearm"+suffix]
	var target:=first.origin.lerp(last.origin,0.5)
	target+=(body.global_position-target).normalized()*0.045
	var side:=1 if index==0 else 0
	var actor:=Acting.of(body)
	if actor==null:return
	Arms._clench(sk,side,weight*0.8)
	var desired:Vector3=actor.fist_frame(side).origin.lerp(target,weight)
	for pass_index in 2:
		var hand:=sk.find_bone("hand.R" if side==1 else "hand.L")
		if hand<0:return
		var fist:Vector3=actor.fist_frame(side).origin
		var wrist:=sk.global_transform*sk.get_bone_global_pose(hand).origin
		Arms.solve_arm(sk,side,sk.to_local(wrist+desired-fist))
	var fist:Vector3=actor.fist_frame(side).origin
	var gap:=fist.distance_to(target)
	set_meta("contact_point",target);set_meta("fist_point",fist);set_meta("contact_gap",gap)
	set_meta("contact_phase",weight>=0.99);set_meta("side",side)
	_bounds(sk)
	if not _acquired and weight>=0.99 and gap<=0.05:
		_acquired=true;acquired.emit(index,gap)

func _bounds(sk:Skeleton3D)->void:
	var feet:=PackedVector3Array()
	for name:String in ["foot.L","foot.R"]:
		var bone:=sk.find_bone(name)
		if bone>=0:feet.append(sk.global_transform*sk.get_bone_global_pose(bone).origin)
	body.set_meta("custody_rendered_bounds",{"head":body.call("head_top"),"feet":feet})

static func make_cord(on_body:Node3D)->Node3D:
	var root:=Node3D.new();root.name="CustodyBinding";on_body.add_child(root)
	var material:=StandardMaterial3D.new();material.albedo_color=Color("977746");material.roughness=1.0
	for side in 2:
		var loop:=MeshInstance3D.new();loop.name="WristLoop%d" % side
		var torus:=TorusMesh.new();torus.inner_radius=0.026;torus.outer_radius=0.042;torus.rings=12;torus.ring_segments=6
		loop.mesh=torus;loop.material_override=material;root.add_child(loop)
	var tie:=MeshInstance3D.new();tie.name="Tie"
	var cylinder:=CylinderMesh.new();cylinder.top_radius=0.009;cylinder.bottom_radius=0.009;cylinder.height=1.0;cylinder.radial_segments=6
	tie.mesh=cylinder;tie.material_override=material;root.add_child(tie)
	root.visible=false
	return root

func _place_cord(frames:Dictionary)->void:
	if not frames.has("hand.L") or not frames.has("hand.R"):return
	var left:Transform3D=frames["hand.L"];var right:Transform3D=frames["hand.R"]
	for side in 2:
		var frame:=left if side==0 else right
		var elbow:Transform3D=frames["forearm.L" if side==0 else "forearm.R"]
		var loop:=cord.get_node("WristLoop%d" % side) as Node3D
		loop.global_transform=Transform3D(_along(frame.origin-elbow.origin),frame.origin)
	var tie:=cord.get_node("Tie") as Node3D
	var difference:=right.origin-left.origin
	tie.global_transform=Transform3D(_along(difference)*Basis.from_scale(Vector3(1,difference.length(),1)),left.origin.lerp(right.origin,0.5))
	cord.set_meta("wrist_points",PackedVector3Array([left.origin,right.origin]))
	cord.visible=bound_weight>=0.95

static func _along(direction:Vector3)->Basis:
	var y:=direction.normalized() if direction.length_squared()>0.000001 else Vector3.UP
	var x:=y.cross(Vector3.FORWARD if absf(y.dot(Vector3.FORWARD))<0.95 else Vector3.RIGHT).normalized()
	return Basis(x,y,x.cross(y).normalized())

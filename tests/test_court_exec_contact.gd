extends GdUnitTestSuite
## Authored execution tools meet their targets in the frame the clip's event
## is delivered. No wall clock or rendering is involved in these checks.
const Figure:=preload("res://scripts/hud/court_figure_3d.gd")
const Acting:=preload("res://scripts/hud/court_acting.gd")
const Props:=preload("res://scripts/hud/court_exec_props.gd")
const Exec:=preload("res://scripts/hud/court_exec_stage.gd")
const Stage:=preload("res://scripts/hud/court_stage.gd")

class Court extends Node3D:
	var facts:={"era_tags":["metal","pottery"]}
	var kind:="execution_contact_test"
class Rig extends RefCounted:
	var base_yaw:=-15.0
class TestStage extends Control:
	var court_set:Node3D
	var rig:=Rig.new()
	var figures:Dictionary={}
	func figure(key:String)->Variant:return figures.get(key)

func _plan(act:String,variant:="male_adult",tall:=1.0,approach:=false)->Dictionary:
	var stage:TestStage=auto_free(TestStage.new());add_child(stage)
	stage.court_set=Court.new();stage.add_child(stage.court_set)
	var plan:=Acting.exec_plan(act)
	for key:String in plan.roles:
		var role:Dictionary=plan.roles[key]
		var f:=Stage.Figure.new();stage.add_child(f)
		f.spot=Node3D.new();stage.court_set.add_child(f.spot)
		var at:Array=role.at
		f.spot.position=Vector3(at[0],at[1],at[2])
		var b:=Figure.new();f.spot.add_child(b)
		b.setup({"variant":variant,"outfit":"tunic","stance":"stand","tall":tall})
		b.rotation.y=deg_to_rad(float(role.yaw))
		b.player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		f.body3d=b;f._stage=weakref(stage)
		if approach and key!="victim":f.nudge=Vector3(2,0,0)
		stage.figures[key]=f
	var scene:=Exec.new();stage.add_child(scene)
	scene.stage=stage;scene.victim="victim";scene.style="mild"
	scene._plan_start({"act":act,"ex":"executioner","cook":"cook"})
	for f in stage.figures.values():
		if f.body3d._yaw_tween!=null:f.body3d._yaw_tween.custom_step(1.0)
		Acting.of(f.body3d).active=false
	return {"stage":stage,"scene":scene}

func _pose(b:Node3D,t:float)->void:
	b.skeleton.reset_bone_poses();b.player.advance(0.0)
	var a=Acting.of(b);a._a.t=t;a._a.ev_i=a._a.events.size()
	a.step(0.0);b.skeleton.force_update_all_bone_transforms()

func _head_vertices(b:Node3D)->PackedVector3Array:
	var out:=PackedVector3Array()
	for m:MeshInstance3D in b._parts:
		if m.name!="Body":continue
		var poses:Array[Transform3D]=[];var head:Array[bool]=[]
		for j in m.skin.get_bind_count():
			var name:=String(m.skin.get_bind_name(j))
			poses.append(b.skeleton.global_transform*b.skeleton.get_bone_global_pose(b.skeleton.find_bone(name))*m.skin.get_bind_pose(j))
			head.append(name in ["head","jaw"])
		for surface in m.mesh.get_surface_count():
			var arr:=m.mesh.surface_get_arrays(surface)
			var vertices:PackedVector3Array=arr[Mesh.ARRAY_VERTEX]
			var bones:PackedInt32Array=arr[Mesh.ARRAY_BONES];var weights:PackedFloat32Array=arr[Mesh.ARRAY_WEIGHTS]
			for i in vertices.size():
				var p:=Vector3.ZERO;var head_weight:=0.0
				for k in 4:
					var bone:=bones[i*4+k];var w:=weights[i*4+k]
					p+=(poses[bone]*vertices[i])*w
					if head[bone]:head_weight+=w
				if head_weight>0.5:out.append(p)
	return out

func _head_gap(club:MeshInstance3D,head:PackedVector3Array)->float:
	var nearest:=INF
	for surface in club.mesh.get_surface_count():
		var vertices:PackedVector3Array=club.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
		for v in vertices:
			if v.y<0.60:continue
			var at:=club.to_global(v)
			for h in head:nearest=minf(nearest,at.distance_squared_to(h))
	return sqrt(nearest)

func test_the_authored_club_reaches_the_head_at_its_impact_frame()->void:
	var setup:=_plan("club_home_run")
	var scene:Node=setup.scene;var stage:TestStage=setup.stage
	var victim:Node3D=stage.figure("victim").body3d
	var batter:Node3D=stage.figure("executioner").body3d
	var club:MeshInstance3D=scene._things.club
	# The swing is baked at 30fps; 3.6333 is the first frame after its 3.62s
	# impact event at both 30fps and 60fps. Check the exact event time too.
	for t:float in [3.62,ceil(3.62*30.0)/30.0]:
		_pose(victim,t);_pose(batter,t)
		var head:=_head_vertices(victim)
		assert_int(head.size()).is_greater(0)
		assert_float(_head_gap(club,head)).is_less(0.20 if t==3.62 else 0.035)
		var fist:Transform3D=Acting.of(batter).fist_frame(1)
		assert_vector(club.to_global(Vector3(0,0.1,0))).is_equal_approx(fist.origin,Vector3.ONE*0.001)

func test_authored_cook_tools_follow_the_fists_and_the_lid_can_be_released()->void:
	var setup:=_plan("club_home_run")
	var scene:Node=setup.scene;var stage:TestStage=setup.stage
	var cook:Node3D=stage.figure("cook").body3d
	var lid:Node3D=scene._things.lid
	var before_pickup:=lid.global_transform
	_pose(cook,2.0)
	assert_bool(lid.global_transform.is_equal_approx(before_pickup)).is_true()
	_pose(cook,7.4)
	for side:String in ["L","R"]:
		var prop:Node3D=scene._things["lid" if side=="L" else "ladle"]
		var grip:Array=Props.info(String(prop.get_meta("prop"))).get("grip",[0,0,0])
		assert_vector(prop.to_global(Vector3(grip[0],grip[1],grip[2]))).is_equal_approx(Acting.of(cook).fist_frame(0 if side=="L" else 1).origin,Vector3.ONE*0.001)
	scene._on_cook_cue(cook,{"name":"lid"})
	var resting:=lid.global_transform
	_pose(cook,8.0)
	assert_bool(lid.global_transform.is_equal_approx(resting)).is_true()
	assert_object(lid.get_parent()).is_same(scene._things.pot)

func test_normal_hand_props_keep_their_existing_socket()->void:
	var setup:=_plan("three_swing_beheading")
	var stage:TestStage=setup.stage
	var b:Node3D=stage.figure("executioner").body3d
	var prop:=Props.make("club")
	assert_bool(Props.hold(prop,b,"hand.L")).is_true()
	assert_bool(prop.get_parent() is BoneAttachment3D).is_true()
	assert_bool(prop.transform.basis.is_equal_approx(Props.GRIP_BASIS)).is_true()
	assert_vector(prop.position).is_equal_approx(Props.PALM-Props.GRIP_BASIS*Vector3(0,0.1,0),Vector3.ONE*0.001)

func test_the_authored_axe_edge_reaches_the_neck_and_the_first_block_strike()->void:
	var setup:=_plan("three_swing_beheading")
	var scene:Node=setup.scene;var stage:TestStage=setup.stage
	var victim:Node3D=stage.figure("victim").body3d
	var headsman:Node3D=stage.figure("executioner").body3d
	var axe:Node3D=scene._things.axe
	for t:float in [1.95,5.5,8.7]:
		_pose(victim,t);_pose(headsman,t)
		var edge:=axe.to_global(Vector3(0,0.82,0.24))
		var fist:Transform3D=Acting.of(headsman).fist_frame(1)
		var intended:=fist*Vector3(0,0.66*float(headsman.body_height)/Figure.REFERENCE_HEIGHT,0)
		assert_vector(edge).is_equal_approx(intended,Vector3.ONE*0.001)
		assert_vector(axe.to_global(Vector3(0,0.08,0))).is_equal_approx(fist.origin,Vector3.ONE*0.001)
		var sk:Skeleton3D=victim.skeleton
		var neck:=sk.global_transform*sk.get_bone_global_pose(sk.find_bone("neck")).origin
		assert_float(edge.distance_to(neck)).is_less(0.12)
	# The held first stroke remains on the block's footprint, in front of
	# the neck, instead of missing off to the side with the old hand socket.
	_pose(headsman,2.0)
	var edge:=axe.to_global(Vector3(0,0.82,0.24))
	var block:Node3D=scene._things.block
	var local:=block.to_local(edge)
	assert_float(absf(local.x)).is_less(0.30)
	assert_float(absf(local.z)).is_less(0.30)
	assert_float(local.y).is_between(0.35,0.45)
	var block_top:=block.to_global(Vector3(0,0.45,0)).y
	assert_float(block_top).is_equal_approx(0.575*float(victim.body_height)/Figure.REFERENCE_HEIGHT,0.001)

func test_axe_contact_and_block_support_scale_with_the_body()->void:
	for appearance:Array in [["male_adult",0.9],["female_adult",1.1]]:
		var setup:=_plan("three_swing_beheading",appearance[0],appearance[1])
		var stage:TestStage=setup.stage;var scene:Node=setup.scene
		var victim:Node3D=stage.figure("victim").body3d
		var ex:Node3D=stage.figure("executioner").body3d
		_pose(victim,8.7);_pose(ex,8.7)
		var edge:Vector3=scene._things.axe.to_global(Vector3(0,0.82,0.24))
		var sk:Skeleton3D=victim.skeleton
		var neck:=sk.global_transform*sk.get_bone_global_pose(sk.find_bone("neck")).origin
		assert_float(edge.distance_to(neck)).is_less(0.16)
		var block_top:float=scene._things.block.to_global(Vector3(0,0.45,0)).y
		assert_float(block_top).is_equal_approx(0.575*float(victim.body_height)/Figure.REFERENCE_HEIGHT,0.001)

func test_arrival_restores_the_authored_heading_and_keeps_the_lid_at_rest()->void:
	var setup:=_plan("club_home_run","male_adult",1.0,true)
	var scene:Node=setup.scene;var stage:TestStage=setup.stage
	var cook:Node3D=stage.figure("cook").body3d
	var lid:Node3D=scene._things.lid
	var resting:=lid.global_transform
	# Simulate a routed walk ending with a different tangent. The execution
	# must take its authored heading after the final walking segment.
	cook.face(140.0,0.0)
	Acting.of(cook).step(0.01)
	assert_bool(lid.global_transform.is_equal_approx(resting)).is_true()
	for t:Tween in scene._tweens:
		if t.is_valid():t.custom_step(1.41)
	cook._yaw_tween.custom_step(0.21)
	assert_float(absf(angle_difference(cook.global_rotation.y,deg_to_rad(-15)))).is_less(0.001)
	_pose(cook,2.0)
	assert_bool(lid.global_transform.is_equal_approx(resting)).is_true()
	_pose(cook,7.4)
	assert_bool(lid.global_transform.is_equal_approx(resting)).is_false()

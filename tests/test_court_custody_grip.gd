extends GdUnitTestSuite
const Grip:=preload("res://scripts/hud/court_custody_grip.gd")
const Custody:=preload("res://scripts/hud/court_custody_stage.gd")
const Figure:=preload("res://scripts/hud/court_figure_3d.gd")
const Acting:=preload("res://scripts/hud/court_acting.gd")
const Director:=preload("res://scripts/hud/court_director.gd")

class Convoy extends Custody:
	var bodies:Dictionary={}
	var completed:=false
	var fallback_calls:=0
	func _figure(key:String)->Variant:return {"body3d":bodies[key]}
	func _move_walker(walker:Dictionary,distance:float,_speed:float,_delta:float)->void:
		walker.distance=distance
		bodies[walker.key].position=path_point(walker.path,distance)
	func _departed()->void:bodies[victim].visible=false
	func _return_supports()->void:completed=true
	func skip()->void:fallback_calls+=1;completed=true

func _body(parent:Node3D,variant:String)->Node3D:
	var body:=Figure.new();parent.add_child(body)
	assert_bool(body.setup({"variant":variant,"outfit":"tunic","stance":"stand"})).is_true()
	body.player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	Acting.of(body).active=false
	return body

func _fixture(rotated:bool,slot:int,variant:="male_adult")->Dictionary:
	var court:Node3D=auto_free(Node3D.new());add_child(court)
	if rotated:court.transform=Transform3D(Basis(Vector3.UP,1.13),Vector3(7,1.2,-4))
	var victim:=_body(court,"female_adult")
	var actor:=_body(court,variant)
	actor.global_position=Custody.approach_point(victim,slot)
	actor.rotation.y=victim.rotation.y
	var receive:=Grip.new();receive.configure(victim,victim,0,true);victim.skeleton.add_child(receive);receive.active=false
	var guard:=Grip.new();guard.configure(actor,victim,slot);actor.skeleton.add_child(guard);guard.active=false;guard.weight=1.0
	return {"court":court,"victim":victim,"actor":actor,"receive":receive,"guard":guard}

func _pose(f:Dictionary,bound:float)->void:
	f.victim.skeleton.reset_bone_poses();f.victim.player.advance(0.0)
	f.receive.bound_weight=bound;f.receive.apply_pose()
	f.actor.skeleton.reset_bone_poses();f.actor.player.advance(0.0)
	Acting.play(f.actor,"grab_r" if f.guard.index==0 else "grab_l",{"blend":0.0,"hold":true})
	Acting.of(f.actor)._a.t=1.3;Acting.of(f.actor).step(0.0)
	f.guard.apply_pose()

func test_two_actual_grips_follow_both_rendered_upper_arms_while_binding()->void:
	var maximum:=0.0
	for rotated:bool in [false,true]:
		for variant:String in ["male_adult","female_adult","male_old"]:
			for slot in 2:
				var f:=_fixture(rotated,slot,variant)
				for bound:float in [0.0,0.5,1.0]:
					_pose(f,bound)
					var gap:=float(f.guard.get_meta("contact_gap",INF));maximum=maxf(maximum,gap)
					assert_float(gap).override_failure_message("%s slot%d bound%.1f gap%.5f" % [variant,slot,bound,gap]).is_less_equal(0.05)
				assert_bool(f.guard._acquired).is_true()
	print("CUSTODY_CONTACT max_gap_m=",maximum)

func test_grip_targets_survive_other_skeleton_restoring_its_pose()->void:
	var f:=_fixture(true,0);_pose(f,1.0)
	var target:Vector3=f.guard.get_meta("contact_point")
	var frames:Dictionary=f.victim.get_meta("custody_rendered_bone_frames")
	f.victim.skeleton.reset_bone_poses();f.victim.player.advance(0.0)
	f.actor.skeleton.reset_bone_poses();f.actor.player.advance(0.0);f.guard.apply_pose()
	assert_float((f.guard.get_meta("contact_point") as Vector3).distance_to(target)).is_less(0.0001)
	assert_float(float(f.guard.get_meta("contact_gap"))).is_less_equal(0.05)
	var restored:Transform3D=f.victim.skeleton.global_transform*f.victim.skeleton.get_bone_global_pose(f.victim.skeleton.find_bone("hand.L"))
	assert_float(restored.origin.distance_to((frames["hand.L"] as Transform3D).origin)).is_greater(0.1)

func test_cord_follows_both_actual_wrist_frames_and_is_bounded_geometry()->void:
	var f:=_fixture(true,1)
	var cord:=Grip.make_cord(f.victim);f.receive.cord=cord
	_pose(f,0.5);assert_bool(cord.visible).is_false()
	_pose(f,1.0);assert_bool(cord.visible).is_true()
	assert_int(cord.get_child_count()).is_equal(3)
	var frames:Dictionary=f.victim.get_meta("custody_rendered_bone_frames")
	var points:PackedVector3Array=cord.get_meta("wrist_points")
	for side in 2:
		var expected:Transform3D=frames["hand.L" if side==0 else "hand.R"]
		assert_float(points[side].distance_to(expected.origin)).is_less(0.0001)
		assert_float(cord.get_child(side).global_position.distance_to(expected.origin)).is_less(0.0001)
	assert_float(points[0].distance_to(points[1])).is_between(0.08,0.22)

func test_cancel_stops_grip_and_never_hides_or_splits_anyone()->void:
	var f:=_fixture(false,0);_pose(f,0.0)
	f.guard.cancel();f.guard.remove_meta("contact_point");_pose(f,1.0)
	assert_bool(f.guard.has_meta("contact_point")).is_false()
	assert_bool(f.actor.visible and f.victim.visible).is_true()
	assert_object(f.victim.skeleton).is_not_null()

func test_persistent_binding_release_is_idempotent_and_removes_modifier_and_cord()->void:
	var f:=_fixture(false,0)
	f.receive.cord=Grip.make_cord(f.victim);f.victim.set_meta("custody_bound",true)
	_pose(f,1.0)
	Custody.release_binding(f.victim);Custody.release_binding(f.victim)
	await await_idle_frame()
	assert_bool(f.victim.has_meta("custody_bound")).is_false()
	assert_object(f.victim.get_node_or_null("CustodyBinding")).is_null()
	assert_object(f.victim.skeleton.get_node_or_null("CustodyBindingPose")).is_null()
	assert_bool(f.victim.visible).is_true()

func test_raw_child_identity_cannot_become_supporter_through_default_age()->void:
	var child:Dictionary={"kind":"child"}
	var rows:=Director.normal_cast([{"key":"child","role":"court","person":child}],{})
	assert_bool(Custody.eligible_support(rows[0],child)).is_false()
	assert_bool(Custody.eligible_support({"role":"court","age":30},{"age":30})).is_true()
	assert_bool(Custody.eligible_support({"role":"court","age":17},{"age":17})).is_false()

func test_unequal_exit_paths_keep_clearance_round_corner_and_do_not_stack_at_door()->void:
	var scene:Convoy=auto_free(Convoy.new())
	scene.stage=auto_free(Control.new());scene.victim="held";scene.support_keys.assign(["near","far"])
	# A half-metre grip formation converges onto one checked doorway route.
	# Unequal individual durations previously made these bodies overtake/stack.
	scene._out_paths={
		"near":PackedVector3Array([Vector3(-0.5,0,0),Vector3(-3,0,0),Vector3(-3,0,-2)]),
		"held":PackedVector3Array([Vector3.ZERO,Vector3(-1.8,0,0),Vector3(-3,0,0),Vector3(-3,0,-2)]),
		"far":PackedVector3Array([Vector3(0.5,0,0),Vector3(-0.8,0,0),Vector3(-3,0,0),Vector3(-3,0,-2)])}
	for key:String in scene._out_paths:
		var body:Node3D=auto_free(Node3D.new());scene.bodies[key]=body
		body.position=scene._out_paths[key][0]
	scene._escort()
	var minimum:=INF;var formed_minimum:=INF
	for tick in 900:
		scene._advance_escort(1.0/30.0)
		var visible:Array=[]
		for body:Node3D in scene.bodies.values():
			if body.visible:visible.append(body)
		for a in visible.size():
			for b in range(a+1,visible.size()):
				var gap:float=visible[a].position.distance_to(visible[b].position)
				minimum=minf(minimum,gap)
				if tick>=60:formed_minimum=minf(formed_minimum,gap)
		if scene.completed:break
	assert_bool(scene.completed).override_failure_message("Checked convoy must reach the exit, not deadlock at its corner.").is_true()
	assert_float(minimum).is_greater_equal(0.499)
	assert_float(formed_minimum).is_greater_equal(Custody.CONVOY_GAP-0.001)
	for body:Node3D in scene.bodies.values():
		assert_bool(body.visible).is_false()
		assert_float(body.position.distance_to(Vector3(-3,0,-2))).is_less(0.001)
	assert_int(scene.fallback_calls).is_zero()

func test_stalled_convoy_completes_authorized_outcome_after_bounded_wait()->void:
	var scene:Convoy=auto_free(Convoy.new())
	scene.stage=auto_free(Control.new());scene.victim="held";scene.depart=true;scene.support_keys.assign(["near","far"])
	# The selected lead's first segment passes through the prisoner. Nobody
	# can advance without breaking clearance, but the modal must not stay locked.
	scene._out_paths={
		"near":PackedVector3Array([Vector3(-0.5,0,0),Vector3.ZERO,Vector3(4,0,0)]),
		"held":PackedVector3Array([Vector3.ZERO,Vector3(4,0,0)]),
		"far":PackedVector3Array([Vector3(0.5,0,0),Vector3.ZERO,Vector3(4,0,0)])}
	for key:String in scene._out_paths:
		var body:Node3D=auto_free(Node3D.new());scene.bodies[key]=body
		body.position=scene._out_paths[key][0]
	scene._escort()
	for tick in 57:scene._advance_escort(1.0/30.0)
	assert_int(scene.fallback_calls).is_zero()
	for tick in 7:
		if scene.completed:break
		scene._advance_escort(1.0/30.0)
	assert_int(scene.fallback_calls).is_equal(1)
	assert_bool(scene.depart).is_true()
	assert_str(String(scene.get_meta("fallback_reason",""))).contains("authorized custody outcome")

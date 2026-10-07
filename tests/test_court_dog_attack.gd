extends GdUnitTestSuite
const Animal:=preload("res://scripts/hud/court_animal_3d.gd")
const Attack:=preload("res://scripts/hud/court_dog_attack.gd")
const Figure:=preload("res://scripts/hud/court_figure_3d.gd")
const Acting:=preload("res://scripts/hud/court_acting.gd")
const Exec:=preload("res://scripts/hud/court_exec_stage.gd")

class Court extends Node3D:
	var animals:Array=[]
	func has_mark(_key:String)->bool:return false

class TestStage extends Control:
	var court_set:Node3D
	var figures:Dictionary={}
	func figure(key:String)->Variant:return figures.get(key)

func _fixture(rotated:=false)->Dictionary:
	var court:Court=auto_free(Court.new());add_child(court)
	if rotated:court.transform=Transform3D(Basis(Vector3.UP,1.17),Vector3(7.0,2.0,-4.0))
	var body:=Figure.new();court.add_child(body)
	assert_bool(body.setup({"variant":"male_adult","outfit":"tunic","stance":"stand"})).is_true()
	body.player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	Acting.of(body).active=false
	var dogs:Array=[]
	for i in 3:
		var dog:=Animal.new();court.add_child(dog)
		assert_bool(dog.setup("dog",court,70+i)).is_true()
		dog.position=Vector3((float(i)-1.0)*0.6,0,-1.1)
		dog.set_process(false)
		dog.player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		dogs.append(dog);court.animals.append(dog)
	var attack:=Attack.new();court.add_child(attack)
	attack.setup(dogs,body,court,court.global_basis*Vector3.FORWARD)
	return {"court":court,"body":body,"dogs":dogs,"attack":attack}

func _sample(f:Dictionary,time:float,clip_name:String,clip_time:float,drag:float)->void:
	var body:Node3D=f.body
	body.position.z=-drag
	body.skeleton.reset_bone_poses()
	body.player.advance(0.0)
	Acting.play(body,clip_name,{"blend":0.0})
	var acting:=Acting.of(body)
	acting._a.t=clip_time;acting._a.ev_i=acting._a.events.size();acting.step(0.0)
	body.skeleton.force_update_all_bone_transforms()
	for i in f.dogs.size():
		var dog:Node3D=f.dogs[i]
		var sk:Skeleton3D=dog._mouth_skeleton()
		sk.reset_bone_poses();dog.player.seek(fmod(time+float(i)*0.23,0.8),true)
		sk.force_update_all_bone_transforms()
	f.attack.advance(time)
	for i in f.dogs.size():
		var dog:Node3D=f.dogs[i]
		# AnimationMixer restores authored source poses before its modifiers.
		# The rendered pass must solve in one application, not accumulate the
		# controller's earlier approach estimate as an accidental second solve.
		var sk:Skeleton3D=dog._mouth_skeleton()
		sk.reset_bone_poses();dog.player.seek(fmod(time+float(i)*0.23,0.8),true)
		sk.force_update_all_bone_transforms()
		dog._apply_bite_pose(dog._mouth_skeleton(),f.attack.target_for(i),f.attack._latched[i]==1)

func test_posed_ankles_remain_in_the_jaws_through_both_drag_bursts()->void:
	for rotated:bool in [false,true]:
		var f:=_fixture(rotated)
		for i in 100:
			var t:=float(i+1)*0.05
			var drag:=minf(t,1.0)*0.8+maxf(t-3.4,0.0)*0.8
			_sample(f,t,"exec_dog_grip" if t>=1.0 and t<3.4 else "exec_dog_claw",fmod(t,1.0),drag)
			if t<0.8:continue
			assert_int(f.attack.contacts).is_equal(3)
			for n in 3:
				var dog:Node3D=f.dogs[n]
				assert_float(dog.mouth_world().distance_to(f.attack.target_for(n))).is_less(0.035)
				assert_float(dog.position.y).is_equal_approx(0.0,0.001)
				assert_bool(dog._moving).is_false()
		assert_int(f.attack.tug_samples).is_greater(30)

func test_approach_is_speed_bounded_and_has_distinct_tug_phases()->void:
	var f:=_fixture()
	for dog:Node3D in f.dogs:dog.position+=Vector3(5,0,0)
	var before:Vector3=f.dogs[0].global_position
	_sample(f,0.02,"exec_dog_claw",0.3,0.0)
	assert_float(f.dogs[0].global_position.distance_to(before)).is_less_equal(0.073)
	assert_int(f.attack.contacts).is_equal(0)
	assert_bool(f.dogs[0].get_meta("execution_tug_phase")!=f.dogs[1].get_meta("execution_tug_phase")).is_true()

func test_aftermath_stays_at_current_endpoint_and_cannot_resume_following()->void:
	var f:=_fixture(true)
	_sample(f,1.0,"exec_dog_claw",0.3,1.2)
	var positions:Array=[]
	for dog:Node3D in f.dogs:positions.append(dog.global_position)
	f.attack.settle(2.4)
	f.body.position.z-=4.0
	f.attack.advance(10.0)
	for i in 3:
		var dog:Node3D=f.dogs[i]
		assert_vector(dog.global_position).is_equal(positions[i])
		assert_float(dog._held).is_equal(2.4)
		assert_bool(dog._moving).is_false()
		assert_bool(dog._arrive.is_valid()).is_false()
	f.attack.finish_aftermath()
	assert_str(f.attack.state).is_equal("settled")
	for dog:Node3D in f.dogs:assert_str(dog.clip).is_equal("lie_idle")
	f.attack.cancel();f.attack.advance(20.0)
	assert_str(f.attack.state).is_equal("cancelled")

func test_cancel_kills_pending_barks_scratches_and_wake_routes()->void:
	var f:=_fixture()
	var dog:Node3D=f.dogs[0]
	dog.bite_at(f.attack.target_for(0),false)
	dog.scratch(2.0);dog.bark(5);dog.play("lie_idle",0.0)
	dog.go_to(Vector3(5,0,1),"trot")
	var actions:Array=dog._action_tweens.duplicate()
	assert_int(actions.size()).is_greater_equal(3)
	dog.cancel_action()
	for action:Tween in actions:assert_bool(action.is_valid()).is_false()
	assert_int(dog._action_tweens.size()).is_equal(0)
	assert_bool(dog._moving).is_false()
	assert_bool(dog._after_hold.is_valid()).is_false()
	assert_bool(dog._bite_pose.active).is_false()

func test_drag_trace_is_full_style_only_bounded_and_uses_court_floor()->void:
	var stage:TestStage=auto_free(TestStage.new());add_child(stage)
	var court:=Court.new();stage.add_child(court);stage.court_set=court
	court.transform=Transform3D(Basis(Vector3.UP,0.9),Vector3(4,3,-8))
	var scene:=Exec.new();stage.add_child(scene);scene.stage=stage
	var a:=court.to_global(Vector3(0,0,0));var b:=court.to_global(Vector3(0.1,0,0.3))
	scene.style="mild";scene._dog_drag_trace(a,b,0)
	assert_int(scene._made.size()).is_equal(0)
	scene.style="full";scene._dog_drag_trace(a,b,0)
	assert_int(scene._made.size()).is_equal(1)
	var mark:MeshInstance3D=scene._made[0]
	assert_float(mark.position.y).is_equal_approx(0.008,0.0001)
	assert_float(mark.mesh.size.z).is_less_equal(0.32)
	assert_float(mark.mesh.size.x).is_less(0.08)

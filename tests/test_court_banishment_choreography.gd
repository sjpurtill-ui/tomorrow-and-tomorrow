extends GdUnitTestSuite
const Custody:=preload("res://scripts/hud/court_custody_stage.gd")
const Body:=preload("res://scripts/hud/court_figure_3d.gd")
const Acting:=preload("res://scripts/hud/court_acting.gd")
const Motion:=preload("res://scripts/hud/motion.gd")

class Court extends Node3D:
	var kind:="banishment_choreography_test"
	var marks:Dictionary={}
	func door_points()->Array:return [to_global(Vector3(-3,0,0)),to_global(Vector3(-4,0,0))]

class Figure extends Node:
	var person:Dictionary={"age":35,"kind":"guard"}
	var body3d:Node3D
	var spot:Node3D
	var leaving:=false
	var idle:=true
	var lift:=0.0
	var rest_clip:="stand"
	var stroll:=0.0
	var nudge:=Vector3.ZERO:
		set(value):
			nudge=value
			if is_instance_valid(body3d):body3d.global_position=spot.to_global(value)
	var _act:Tween
	var _step:Tween
	var _lean:Tween
	var _bob:Tween
	func _path_at(_along:float)->Vector3:return Vector3.ZERO

class Stage extends Control:
	var court_set:Court
	var facts:Dictionary={}
	var cast_order:Array[String]=["target","named","guard"]
	var figures:Dictionary={}
	func figure(key:String)->Variant:return figures.get(key)
	func cast_list()->Array:
		var out:Array=[]
		for key:String in cast_order:out.append({"key":key,"role":"main" if key=="target" else "court","person":figures[key].person})
		return out

var _reduced:=false
func before_test()->void:_reduced=Motion.reduce_motion;Motion.reduce_motion=false
func after_test()->void:Motion.reduce_motion=_reduced

func _fixture(rotated:=false,mode:="exile")->Dictionary:
	var stage:Stage=auto_free(Stage.new());add_child(stage)
	stage.court_set=Court.new();stage.add_child(stage.court_set)
	if rotated:stage.court_set.transform=Transform3D(Basis(Vector3.UP,1.13),Vector3(7,1.2,-4))
	for index in stage.cast_order.size():
		var key:=stage.cast_order[index];var f:=Figure.new();stage.add_child(f);stage.figures[key]=f
		f.person={"age":35,"kind":"guard","name":key}
		f.spot=Node3D.new();stage.court_set.add_child(f.spot)
		f.spot.position=Vector3(0 if index==0 else (2 if index==1 else -2),0,0)
		f.body3d=Body.new();stage.court_set.add_child(f.body3d)
		assert_bool(f.body3d.setup({"variant":"female_adult" if index==0 else "male_adult","outfit":"tunic","stance":"stand"})).is_true()
		f.nudge=Vector3.ZERO
		f.body3d.player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		Acting.of(f.body3d).active=false
	var scene:=Custody.new();stage.add_child(scene)
	assert_bool(scene.begin(stage,"target","named",true,mode)).is_true()
	scene.set_process(false)
	return {"stage":stage,"scene":scene,"body":stage.figures.target.body3d}

func _arrive(f:Dictionary)->void:
	for tween:Tween in f.scene._tweens:
		if tween.is_valid():tween.custom_step(10.0)
	f.scene._process(f.scene._start)

func test_exile_confronts_points_turns_and_walks_with_free_hands()->void:
	var f:=_fixture();var scene:Node=f.scene
	assert_object(scene._receiver).is_null();assert_object(scene._cord).is_null()
	_arrive(f)
	assert_str(String(scene.get_meta("custody_state"))).is_equal("confront")
	assert_int(scene._grips.size()).is_zero()
	scene._process(0.61)
	assert_str(String(scene.get_meta("custody_state"))).is_equal("door_gesture")
	assert_str(String(scene.get_meta("gesture_actor"))).is_equal("named")
	assert_float((scene.get_meta("gesture_target") as Vector3).distance_to(f.stage.court_set.door_points()[1])).is_less(0.0001)
	scene._process(1.21)
	assert_str(String(scene.get_meta("custody_state"))).is_equal("turn")
	scene._process(0.46)
	assert_str(String(scene.get_meta("custody_state"))).is_equal("escort")
	for tick in 90:scene._process(1.0/60.0)
	assert_str(Acting.of(f.body)._a.clip).is_equal("walk_sober")
	assert_bool(f.body.has_meta("custody_bound")).is_false()
	assert_int(f.body.find_children("CustodyBinding*","",true,false).size()).is_zero()
	scene.cancel()

func test_authored_pointing_hand_indicates_actual_door_in_translated_rotated_court()->void:
	for rotated:bool in [false,true]:
		var f:=_fixture(rotated);_arrive(f);f.scene._process(0.61)
		var actor:Node3D=f.stage.figures.named.body3d
		actor._yaw_tween.custom_step(0.3)
		actor.skeleton.reset_bone_poses();actor.player.advance(0.0)
		var acting:=Acting.of(actor);acting._a.t=0.7;acting.step(0.0)
		var side:=".L" if String(f.scene.get_meta("gesture_clip"))=="point_l" else ".R"
		var index:int=actor.skeleton.find_bone("index"+side)
		var frame:Transform3D=actor.skeleton.global_transform*actor.skeleton.get_bone_global_pose(index)
		var aim:=Vector2(frame.basis.y.x,frame.basis.y.z).normalized()
		var to:Vector3=f.scene.get_meta("gesture_target")-frame.origin
		var alignment:=aim.dot(Vector2(to.x,to.z).normalized())
		assert_float(alignment).override_failure_message("Actual rendered index must indicate the exit, including rotated court coordinates.").is_greater(0.85)
		f.scene.cancel()

func test_exile_skip_and_cancel_restore_supporters_without_persistent_bonds()->void:
	for skip:bool in [false,true]:
		var f:=_fixture();_arrive(f);f.scene._process(0.61)
		var count:=[0];f.scene.finished.connect(func()->void:count[0]+=1)
		if skip:f.scene.skip()
		else:f.scene.cancel()
		assert_int(count[0]).is_equal(1)
		assert_bool(f.body.visible).is_equal(not skip)
		assert_bool(f.stage.figures.target.leaving).is_equal(skip)
		assert_bool(f.body.has_meta("custody_bound")).is_false()
		for key:String in ["named","guard"]:
			assert_vector(f.stage.figures[key].nudge).is_equal(Vector3.ZERO)
			assert_bool(f.stage.figures[key].body3d.visible).is_true()

func test_default_detention_still_creates_actual_restraints()->void:
	var f:=_fixture(false,"detain")
	assert_object(f.scene._receiver).is_not_null();assert_object(f.scene._cord).is_not_null()
	_arrive(f)
	assert_str(String(f.scene.get_meta("custody_state"))).is_equal("grip")
	assert_int(f.scene._grips.size()).is_equal(2)
	f.scene.cancel()

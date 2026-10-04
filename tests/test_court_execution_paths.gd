extends GdUnitTestSuite
## Headless: synthetic fixtures cover timing and cancellation; imported full halls
## reproduce seated departures, and a real figure reaches its authored strike.

const Exec:=preload("res://scripts/hud/court_exec_stage.gd")
const Paths:=preload("res://scripts/hud/court_paths.gd")
const Figure3D:=preload("res://scripts/hud/court_figure_3d.gd")
const CourtSet:=preload("res://scripts/hud/court_set_3d.gd")
const Acting:=preload("res://scripts/hud/court_acting.gd")

class TestSet extends Node3D:
	var kind:="execution_path_test"
	var marks:Dictionary={}
	func has_mark(key:String)->bool:return marks.has(key)
	func mark(key:String)->Marker3D:return marks.get(key)
	func add_mark(key:String,at:Vector3)->void:
		var node:=Marker3D.new();node.name=key;add_child(node);node.position=at;marks[key]=node

class TestFigure extends Node:
	var spot:Node3D
	var body3d:Node3D
	var stroll:=0.0
	var rest_clip:="bowl"
	var leaving:=false
	var nudge:=Vector3.ZERO:
		set(value):
			nudge=value
			if is_instance_valid(body3d):body3d.position=value
	func _path_at(_along:float)->Vector3:return Vector3.ZERO
	func _vanish()->void:
		leaving=true
		body3d.hide()

class TestStage extends Control:
	var court_set:Node3D
	var rig:Variant
	var cast_order:Array[String]=[]
	var figures:Dictionary={}
	func figure(key:String)->Variant:return figures.get(key)

func _fixture(at:Vector3)->Dictionary:
	var stage:Control=auto_free(TestStage.new());add_child(stage)
	var court:=TestSet.new();stage.add_child(court);stage.court_set=court
	court.add_mark("fire",Vector3.ZERO)
	court.add_mark("door",Vector3(-5,0,-3));court.add_mark("door_out",Vector3(-6,0,-3))
	court.add_mark("far",Vector3(6,0,5))
	var f:=_person(stage,"cook",at)
	var exec:=Exec.new();stage.add_child(exec);exec.stage=stage;exec.victim="absent"
	return {"stage":stage,"court":court,"figure":f,"body":f.body3d,"exec":exec}

func _person(stage:Control,key:String,at:Vector3)->TestFigure:
	var f:=TestFigure.new();stage.add_child(f)
	f.spot=Node3D.new();stage.court_set.add_child(f.spot);f.spot.position=at
	f.body3d=Figure3D.new();f.spot.add_child(f.body3d)
	var player:=AnimationPlayer.new();f.body3d.add_child(player);f.body3d.player=player
	player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var library:=AnimationLibrary.new()
	for clip:String in ["walk_in","stand","bowl","sit"]:
		var animation:=Animation.new();animation.length=1.0;library.add_animation(clip,animation)
	player.add_animation_library("",library)
	stage.cast_order.append(key);stage.figures[key]=f
	return f

func _clear_of_hearth(body:Node3D,court:Node3D)->void:
	var at:=court.to_local(body.global_position)
	assert_float(Vector2(at.x,at.z).length()).override_failure_message("execution walk crossed the hearth").is_greater(Paths.FIRE_RADIUS)
	if String(court.get("kind"))=="longhouse":
		assert_bool(absf(at.x)<2.12 and absf(at.z)<0.68).override_failure_message("execution walk crossed the long stone hearth").is_false()

func test_cook_detours_keep_duration_and_stride_in_both_halls()->void:
	# Authored officials_1 and cook-plan endpoints for the fire ring/longhouse.
	for pair:Array in [[Vector3(1.55,0,1.75),Vector3(-1.296857,0,-0.969674)],
			[Vector3(1.5,0,1.55),Vector3(-1.346857,0,-1.269674)]]:
		var fx:=_fixture(pair[0]);var exec:Node=fx.exec;var body:Node3D=fx.body
		var path:PackedVector3Array=exec.call("_walk_path","cook",pair[1])
		var length:float=Exec._walk_length(path)
		assert_int(path.size()).is_greater(2)
		assert_float(length).is_greater((pair[0] as Vector3).distance_to(pair[1]))
		exec.call("_walk_to","cook",pair[1],1.4,"stand")
		var journey:Tween=exec._moving.cook;journey.pause()
		var pace:=float(Figure3D.WALK_SPEED.walk_in)*float(body.body_height)/Figure3D.REFERENCE_HEIGHT
		assert_float(body.locomotion_rate).is_equal_approx(length/(1.4*pace),0.001)
		for i in 28:
			journey.custom_step(0.05);_clear_of_hearth(body,fx.court)
		journey.custom_step(0.001)
		assert_vector(body.global_position).is_equal_approx(pair[1],Vector3.ONE*0.001)
		assert_str(String(body.clip)).is_equal("stand")
		assert_float(body.locomotion_rate).is_equal(1.0)

func test_route_uses_current_people_and_transformed_set_coordinates()->void:
	var fx:=_fixture(Vector3(-3,0,3));var stage:Control=fx.stage;var court:Node3D=fx.court
	var blocker:=_person(stage,"watcher",Vector3(0,0,4))
	blocker.nudge=Vector3(0,0,-1)
	court.position=Vector3(7,0,-2);court.rotation.y=0.7
	var target:=court.to_global(Vector3(3,0,3))
	var path:PackedVector3Array=fx.exec.call("_walk_path","cook",target)
	assert_int(path.size()).is_greater(2)
	fx.exec.call("_walk_to","cook",target,2.0,"stand")
	var journey:Tween=fx.exec._moving.cook;journey.pause()
	for i in 40:
		journey.custom_step(0.05)
		assert_float((fx.body as Node3D).global_position.distance_to(blocker.body3d.global_position)).is_greater(0.45)
	journey.custom_step(0.001)
	assert_vector((fx.body as Node3D).global_position).is_equal_approx(target,Vector3.ONE*0.001)

func test_a_walk_starts_with_the_short_turn_across_the_angle_seam()->void:
	var fx:=_fixture(Vector3(-3,0,3));var body:Node3D=fx.body
	body.face(179.0,0.0)
	var heading:=deg_to_rad(-179.0)
	var target:=body.global_position+Vector3(sin(heading),0,cos(heading))*0.6
	fx.exec.call("_walk_to","cook",target,1.0,"stand")
	var journey:Tween=fx.exec._moving.cook;journey.pause()
	body._yaw_tween.pause();body._yaw_tween.custom_step(0.09)
	assert_float(body.rotation_degrees.y).is_equal_approx(180.0,0.02)
	body._yaw_tween.custom_step(0.091)
	assert_float(body.rotation_degrees.y).is_equal_approx(181.0,0.02)
	journey.custom_step(1.001)
	assert_vector(body.global_position).is_equal_approx(target,Vector3.ONE*0.001)

func test_return_detours_and_interrupted_approach_cannot_resume()->void:
	var fx:=_fixture(Vector3(1.55,0,1.75));var exec:Node=fx.exec;var body:Node3D=fx.body
	var home:=body.global_position
	exec.call("_walk_to","cook",Vector3(-1.296857,0,-0.969674),1.4,"stand")
	var journey:Tween=exec._moving.cook;journey.pause();journey.custom_step(1.401)
	var before:=get_tree().get_processed_tweens()
	exec.call("finish")
	var returning:Tween
	for tween:Tween in get_tree().get_processed_tweens():
		if not tween in before and tween!=body._yaw_tween:returning=tween
	assert_object(returning).is_not_null()
	returning.pause()
	await await_idle_frame()
	assert_bool(is_instance_valid(exec)).is_false()
	for i in 51:
		returning.custom_step(0.05);_clear_of_hearth(body,fx.court)
	assert_vector(body.global_position).is_equal_approx(home,Vector3.ONE*0.001)
	assert_float(body.locomotion_rate).is_equal(1.0)
	# skip() kills the shared movement/arrival tween before restoring the home.
	exec=Exec.new();fx.stage.add_child(exec);exec.stage=fx.stage;exec.victim="absent"
	exec.call("_walk_to","cook",Vector3(-1.296857,0,-0.969674),1.4,"stand")
	journey=exec._moving.cook;journey.pause();journey.custom_step(0.3)
	exec.call("skip")
	assert_bool(journey.is_valid()).is_false()
	assert_vector(body.global_position).is_equal_approx(home,Vector3.ONE*0.001)
	assert_str(String(body.clip)).is_equal("bowl")
	assert_float(body.locomotion_rate).is_equal(1.0)

func test_seated_executioner_leaves_real_longhouse_bench_without_crossing_table()->void:
	var stage:Control=auto_free(TestStage.new());add_child(stage)
	var court:Node3D=CourtSet.build("longhouse",{"seed":313131})
	assert_object(court.model).is_not_null()
	stage.add_child(court);stage.court_set=court
	var start:Vector3=court.mark("crowd_3").position
	var f:=_person(stage,"executioner",start)
	f.body3d.stance="sit";f.rest_clip="sit"
	var exec:=Exec.new();stage.add_child(exec);exec.stage=stage;exec.victim="absent"
	var target:=Vector3(-0.416861,0,1.670674)
	var room:=Paths.room_of(court)
	var baseline:=Paths.route(room,Vector2(start.x,start.z),Vector2(target.x,target.z))
	assert_int(baseline.size()).override_failure_message("fixture must reproduce the deep-bench route failure").is_equal(0)
	var path:PackedVector3Array=exec.call("_walk_path","executioner",target)
	print("SEATED_EXECUTION_ROUTE ",path)
	assert_int(path.size()).override_failure_message("seated executioner cannot reach the block").is_greater(2)
	# The raised obstacle grid still includes the adjoining 0.74m feast board.
	var high:=Exec._above_seat_obstacles(court,room,0.57)
	var board:=room.square(Vector2(3.6,-2.7))
	assert_int(high[board.y*room.width+board.x]).is_equal(1)
	exec.call("_walk_to","executioner",target,1.4,"stand")
	var journey:Tween=exec._moving.executioner;journey.pause()
	for i in 56:
		journey.custom_step(0.025)
		var at:=Vector2(f.body3d.position.x+f.spot.position.x,f.body3d.position.z+f.spot.position.z)
		assert_int(high[room.square(at).y*room.width+room.square(at).x]).override_failure_message("bench exit crossed table/wall geometry at %s" % at).is_equal(0)
		_clear_of_hearth(f.body3d,court)
	journey.custom_step(0.001)
	assert_vector(f.body3d.global_position).is_equal_approx(target,Vector3.ONE*0.001)
	# Temporary seat clearance never opens the shared room permanently.
	assert_int(Paths.route(room,Vector2(start.x,start.z),Vector2(target.x,target.z)).size()).is_equal(0)
	var back:PackedVector3Array=exec.call("_walk_path","executioner",start)
	assert_int(back.size()).is_greater(2)

func test_real_seat_routes_preserve_the_limit_of_safe_departures()->void:
	for kind:String in ["fire_ring","longhouse"]:
		var stage:Control=auto_free(TestStage.new());add_child(stage)
		var court:Node3D=CourtSet.build(kind,{"seed":313131})
		assert_object(court.model).is_not_null()
		stage.add_child(court);stage.court_set=court
		var f:=_person(stage,"actor",Vector3.ZERO)
		f.body3d.stance="sit";f.rest_clip="sit"
		var exec:=Exec.new();stage.add_child(exec);exec.stage=stage;exec.victim="absent"
		var target:Vector3=court.mark("petitioner").position
		for mark:Node3D in court.marks.values():
			if not bool(mark.get_meta("sit",false)):continue
			f.spot.position=mark.position
			var path:PackedVector3Array=exec.call("_walk_path","actor",target)
			if kind=="longhouse" and String(mark.name) in ["crowd_1","high_seat"]:
				# These do not join the ordinary grid within the bounded seat
				# neighbourhood. Selection must reject an unreachable performer;
				# the walker must never invent a straight crossing through solids.
				assert_int(path.size()).is_equal(0)
			else:assert_int(path.size()).override_failure_message("%s/%s is trapped" % [kind,mark.name]).is_greater(1)

func test_real_seated_headsman_reaches_the_block_before_his_authored_clip()->void:
	var stage:Control=auto_free(TestStage.new());add_child(stage)
	var court:Node3D=CourtSet.build("longhouse",{"seed":313131,"era_tags":["metal","pottery"]})
	assert_object(court.model).is_not_null()
	stage.add_child(court);stage.court_set=court;stage.rig=court.rig
	for key:String in ["victim","executioner"]:
		var mark:Node3D=court.mark("petitioner" if key=="victim" else "crowd_3")
		var f:=_person(stage,key,mark.position)
		f.body3d.free();f.body3d=Figure3D.new();f.spot.add_child(f.body3d)
		assert_bool(f.body3d.setup({"variant":"male_adult","outfit":"tunic","stance":"stand" if key=="victim" else "sit"})).is_true()
		f.rest_clip="stand" if key=="victim" else "sit"
		f.body3d.player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var exec:=Exec.new();stage.add_child(exec);exec.stage=stage;exec.victim="victim";exec.style="mild"
	exec.call("_plan_start",{"act":"three_swing_beheading","ex":"executioner"})
	var target:Vector3=exec.call("_plan_at",[0.70,0,0.36])
	for tween:Tween in exec._tweens:tween.pause();tween.custom_step(1.401)
	var headsman:Node3D=stage.figure("executioner").body3d
	assert_float(headsman.global_position.distance_to(target)).override_failure_message("authored strike started from the distant bench").is_less(0.25)
	assert_str(String(Acting.of(headsman)._a.clip)).is_equal("exec_axe_headsman")
	assert_float(float(Acting.of(headsman)._a.t)).is_less(1.5)
	exec.call("skip")

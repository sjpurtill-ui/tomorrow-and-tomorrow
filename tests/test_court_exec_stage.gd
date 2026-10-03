extends GdUnitTestSuite
## AN EXECUTION IN THE MODELLED COURT (court_stage.gd execute, court_exec_stage.gd).
## - it plays only on someone standing in the hall, never on a child, never
##   under gore "off";
## - a club home run takes their head off and into the pot, and they are gone
##   at the end; a click brings it all to its end at once;
## - "mild" makes no blood and no flying head;
## - the old sober exit is not played again for one already put to death.
## Presentation only. Offline; never calls a real API or writes a save file.

const Fixtures:=preload("res://tests/court_eval/fixtures.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const Modal:=preload("res://scripts/hud/audience_modal.gd")
const Stage:=preload("res://scripts/hud/court_stage.gd")
const CourtSet:=preload("res://scripts/hud/court_set_3d.gd")
const Figure3D:=preload("res://scripts/hud/court_figure_3d.gd")
const Executions:=preload("res://scripts/hud/court_executions.gd")
const Acting:=preload("res://scripts/hud/court_acting.gd")

var _root_size:=Vector2i.ZERO

func before_test()->void:
	Stage.directing=true
	Stage.director=null
	Stage.acting=null
	Stage.use_sets=true
	Fixtures.new(self).base(false)
	_root_size=get_tree().root.size
	get_tree().root.size=Vector2i(1920,1080)

func after_test()->void:
	Stage.director=null
	Stage.acting=null
	Executions.gore="full"
	Executions.last_used=""
	get_tree().root.size=_root_size

func _ready_or_skip()->bool:
	return CourtSet.available() and Figure3D.available()

func _home_audience()->String:
	var marshal:Dictionary=GovernmentPeopleSystem.officeholder("Marshal")
	var target:={"person_id":int(marshal.get("person_id",0))} if not marshal.is_empty() else (Hall.summonable()[0].target as Dictionary)
	return String(Hall.summon(target).get("id",""))

func _open(id:String)->Control:
	var modal:Control=auto_free(Modal.new())
	modal.audience_id=id
	add_child(modal)
	for i in 4:await await_idle_frame()
	modal.skip_reveal()
	await await_idle_frame()
	modal.court_stage.settle()
	return modal

func _named(stage:Control,prefix:String)->int:
	var n:=0
	for node in stage.court_set.find_children(prefix+"*","",true,false):
		if is_instance_valid(node) and not (node as Node).is_queued_for_deletion():n+=1
	return n

func test_a_club_home_run_takes_the_head_into_the_pot_and_a_click_ends_it()->void:
	if not _ready_or_skip():return
	var modal:Control=await _open(_home_audience())
	var stage:Control=modal.court_stage
	var main:Stage.Figure=stage.figure(Stage.MAIN)
	assert_bool(stage.execute("club",Stage.MAIN,"","Heha")).is_true()
	assert_bool(stage.executing()).is_true()
	# run it to just after the blow
	for i in 40:await await_idle_frame()
	var exec:Node=stage.get_node("Execution")
	# to just after the blow (the plan's clips run on their own clock)
	for i in 4:
		for t in stage._beat_sets:
			if t is Tween and (t as Tween).is_valid():(t as Tween).custom_step(1.4)
		for j in 30:await await_idle_frame()
	await get_tree().create_timer(3.0).timeout
	assert_bool(exec._things.has("pot")).is_true()
	assert_bool(exec._things.has("head:main")).override_failure_message("no head came off by %s" % str(exec._things.keys())).is_true()
	# a click: everything to its end
	stage.skip_execution()
	await await_idle_frame()
	await await_idle_frame()
	assert_bool(stage.executing()).is_false()
	assert_bool(main.leaving).is_true()
	assert_bool(main.body3d.visible).is_false()
	assert_bool(is_instance_valid(exec)).is_false()
	assert_str(String(stage._caption.label.text) if is_instance_valid(stage._caption) else "").contains("cooking pot")
	# the leave-taking does not play the sober fall again
	stage.conclude(0.0,"fall")
	assert_bool(main.body3d.visible).is_false()

func test_mild_makes_no_blood_and_no_flying_head()->void:
	if not _ready_or_skip():return
	Executions.gore="mild"
	var modal:Control=await _open(_home_audience())
	var stage:Control=modal.court_stage
	assert_bool(stage.execute("behead",Stage.MAIN,"","Heha")).is_true()
	for i in 4:
		for t in stage._beat_sets:
			if t is Tween and (t as Tween).is_valid():(t as Tween).custom_step(2.0)
		await await_idle_frame()
		var exec:Node=stage.get_node_or_null("Execution")
		if exec!=null:assert_bool(exec._things.has("head:main")).is_false()
		assert_int(_named(stage,"ExecBlood")).is_equal(0)
		assert_int(_named(stage,"ExecPool")).is_equal(0)
		assert_int(_named(stage,"Piece_")).is_equal(0)

func test_never_on_a_child_and_never_under_off()->void:
	if not _ready_or_skip():return
	var modal:Control=await _open(_home_audience())
	var stage:Control=modal.court_stage
	Executions.gore="off"
	assert_bool(stage.execute("club",Stage.MAIN)).is_false()
	Executions.gore="full"
	var main:Stage.Figure=stage.figure(Stage.MAIN)
	main.person["age"]=9
	assert_bool(stage.execute("club",Stage.MAIN)).is_false()
	assert_bool(stage.executing()).is_false()

func test_parked_methods_cannot_start_or_leave_an_execution_running()->void:
	if not _ready_or_skip():return
	var modal:Control=await _open(_home_audience())
	var stage:Control=modal.court_stage
	var main:Stage.Figure=stage.figure(Stage.MAIN)
	var prior_done:bool=stage.exec_done
	var prior_method:String=stage.exec_method
	var prior_events:int=stage._event_index
	for id:String in Executions.ids()+["", "not_a_method"]:
		if Executions.is_staged(id):continue
		assert_bool(stage.execute(id,Stage.MAIN)).override_failure_message(id).is_false()
		# Direct events must not queue the parked method's sound or reactions.
		stage.event("execution",{"method":id,"victim":Stage.MAIN,"style":"full"})
		assert_object(stage.get_node_or_null("Execution")).is_null()
		assert_bool(stage.executing()).is_false()
		assert_bool(stage.exec_done).is_equal(prior_done)
		assert_str(stage.exec_method).is_equal(prior_method)
		assert_int(stage._event_index).is_equal(prior_events)
		assert_bool(main.leaving).is_false()
		assert_bool(main.body3d.visible).is_true()

func test_approaching_a_set_mark_moves_and_skip_restores_the_survivor()->void:
	if not _ready_or_skip():return
	var modal:Control=await _open(_home_audience())
	var stage:Control=modal.court_stage
	var key:=""
	for candidate:String in stage.cast_order:
		if candidate!=Stage.MAIN and stage.figure(candidate).body3d!=null:key=candidate;break
	assert_str(key).is_not_empty()
	var f:Stage.Figure=stage.figure(key)
	var before:=f.nudge
	assert_bool(stage.execute("fire",Stage.MAIN)).is_true()
	var exec:Node=stage.get_node("Execution")
	exec.call("_approach",key,"petitioner",1.0,0.5,0.1)
	for t in exec._tweens:
		if t is Tween and (t as Tween).is_valid():(t as Tween).custom_step(0.11)
	assert_float(f.nudge.distance_to(before)).is_greater(0.05)
	stage.skip_execution()
	assert_vector(f.nudge).is_equal(before)
	assert_float(f.body3d.locomotion_rate).is_equal(1.0)
	await await_idle_frame()
	assert_bool(stage.executing()).is_false()

func test_skipping_dogs_releases_the_court_dog_and_removes_the_extra_pack()->void:
	if not _ready_or_skip():return
	var modal:Control=await _open(_home_audience())
	var stage:Control=modal.court_stage
	var court:Node3D=stage.court_set
	var dog:Node3D=court.call("animal","dog")
	assert_object(dog).is_not_null()
	var before:=dog.transform
	var animals:int=court.animals.size()
	assert_bool(stage.execute("dogs",Stage.MAIN)).is_true()
	var exec:Node=stage.get_node("Execution")
	exec.call("_pack_come",{"more":2})
	assert_int(court.animals.size()).is_equal(animals+2)
	exec.call("_pack_fetch",{"to":"god_feet"})
	stage.skip_execution()
	await await_idle_frame()
	assert_int(court.animals.size()).is_equal(animals)
	assert_bool(dog._moving).is_false()
	assert_bool(dog._arrive.is_valid()).is_false()
	assert_bool(dog._after_hold.is_valid()).is_false()
	assert_object(dog.carried).is_null()
	assert_bool(dog.transform.is_equal_approx(before)).is_true()
	assert_float(float(dog._yaw)).is_equal_approx(dog.rotation.y,0.001)

func test_soundtrack_start_is_owned_by_the_same_cancellable_beats()->void:
	if not _ready_or_skip():return
	var modal:Control=await _open(_home_audience())
	var stage:Control=modal.court_stage
	assert_object(stage._sound).is_not_null()
	var sound:Node=stage._sound
	var count:=int(sound.get("_act_n"))
	var beats:Array=stage.call("_exec_in_step",[{"t":5.0,"who":"exec","act":"blow","args":{}}],{"method":"club","victim":Stage.MAIN,"style":"full"})
	assert_int(int(sound.get("_act_n"))).is_equal(count)

	var starts:=0
	for beat:Dictionary in beats:
		if String(beat.act)=="soundtrack":starts+=1;assert_float(float(beat.t)).is_equal_approx(1.83,0.01)
	assert_int(starts).is_equal(1)
	assert_bool(stage.execute("club",Stage.MAIN)).is_true()
	stage.hush(20.0)
	stage.exec_caption_override="The engine's exact account."
	stage.skip_execution()
	assert_float(stage._hush_until).is_less_equal(float(stage.call("_now")))
	assert_str(String(stage._caption.label.text)).is_equal("The engine's exact account.")
	await get_tree().create_timer(2.0).timeout
	assert_int(int(sound.get("_act_n"))).is_equal(count)

func test_a_terminal_order_keeps_the_victim_until_the_execution_finishes()->void:
	if not _ready_or_skip():return
	var audience:=Hall.debug_force("petition")
	assert_bool(audience.is_empty()).is_false()
	var modal:Control=await _open(String(audience.id))
	var stage:Control=modal.court_stage
	var main:Stage.Figure=stage.figure(Stage.MAIN)
	var order:="Put %s to death in the fire." % String(main.person.get("name",""))
	var result:Dictionary=modal.office_order(order)
	if not bool(result.get("removed",false)):result=modal.office_order("I said it: "+order)
	assert_bool(bool(result.get("removed",false))).is_true()
	assert_bool(modal._executed).is_true()
	# Finish reading immediately, while the 1.4-second entrance delay is pending.
	for i in 12:
		modal.skip_reveal()
		await await_idle_frame()
	assert_bool(stage.exec_done).is_false()
	assert_bool(main.leaving).is_false()
	await get_tree().create_timer(1.6).timeout
	assert_bool(stage.executing()).is_true()
	assert_bool(main.leaving).is_false()
	var shots:=0
	var blow:=0.0
	var finish:=0.0
	for beat:Dictionary in stage._last_beats:
		if String(beat.get("act",""))=="shot":
			shots+=1
			assert_int(int(beat.args.weight)).is_equal(5)
		if String(beat.get("act",""))=="blow":blow=float(beat.t)
		if String(beat.get("act",""))=="end":finish=float(beat.t)
	assert_int(shots).is_greater(0)
	assert_float(blow).is_greater(0.0)
	var scene:Tween=stage._beats
	await get_tree().create_timer(maxf(blow-scene.get_total_elapsed_time()-0.15,0.02)).timeout
	assert_bool(main.leaving).is_false()
	assert_bool(stage.exec_done).is_false()
	assert_int(stage._shot_weight).is_equal(5)
	assert_float(stage._shot_until).is_greater(float(stage.call("_now")))
	await get_tree().create_timer(maxf(finish-scene.get_total_elapsed_time()-0.15,0.02)).timeout
	var caption_before:=String(stage._caption.label.text)
	assert_str(caption_before).is_not_empty()
	await get_tree().create_timer(0.45).timeout
	assert_bool(stage.exec_done).is_true()
	assert_bool(main.leaving).is_true()
	assert_str(stage._shot_name).is_equal("wide")
	assert_int(stage._shot_weight).is_equal(0)
	assert_float(stage._shot_until).is_less_equal(float(stage.call("_now")))
	assert_str(String(stage.rig.current_shot)).is_equal("wide")
	assert_float(float(stage.rig._duration)).is_equal_approx(0.6,0.001)
	assert_str(String(stage._caption.label.text)).is_equal(caption_before)

func test_planned_approach_matches_stride_and_restores_the_base_clip()->void:
	if not _ready_or_skip():return
	var modal:Control=await _open(_home_audience())
	var stage:Control=modal.court_stage
	var key:=""
	for candidate:String in stage.cast_order:
		if candidate!=Stage.MAIN and stage.figure(candidate).body3d!=null:key=candidate;break
	var f:Stage.Figure=stage.figure(key)
	f.nudge+=Vector3(4.0,0.0,0.0)
	assert_bool(stage.execute("club",Stage.MAIN)).is_true()
	for t:Tween in stage._beat_sets:t.kill()
	stage._beat_sets.clear()
	var exec:Node=stage.get_node("Execution")
	var from:=f.body3d.global_position
	exec.call("_plan_start",{"act":"club_home_run","ex":key})
	var to:Vector3=exec.call("_plan_at",[-0.95,0.0,0.2])
	var distance:=Vector2(to.x-from.x,to.z-from.z).length()
	assert_float(distance).is_greater(1.68) # The approach duration is capped at 1.4 seconds.
	var pace:=float(Figure3D.WALK_SPEED.walk_in)*float(f.body3d.body_height)/Figure3D.REFERENCE_HEIGHT
	assert_float(f.body3d.locomotion_rate).is_equal_approx(distance/(1.4*pace),0.001)
	assert_str(f.body3d.clip).is_equal("walk_in")
	for t in exec._tweens:
		if t is Tween and (t as Tween).is_valid():(t as Tween).custom_step(1.41)
	assert_float(f.body3d.locomotion_rate).is_equal(1.0)
	assert_str(f.body3d.clip).is_equal("stand")
	for part:String in ["prop_staff","prop_bowl"]:
		for prop:MeshInstance3D in f.body3d.find_children(part,"MeshInstance3D",true,false):assert_bool(prop.visible).is_false()
	stage.skip_execution()

func test_a_survivor_turns_smoothly_back_after_walking_home()->void:
	if not _ready_or_skip():return
	var modal:Control=await _open(_home_audience())
	var stage:Control=modal.court_stage
	var key:=""
	for candidate:String in stage.cast_order:
		if candidate!=Stage.MAIN and stage.figure(candidate).body3d!=null:key=candidate;break
	var f:Stage.Figure=stage.figure(key)
	var body:=f.body3d
	assert_bool(stage.execute("fire",Stage.MAIN)).is_true()
	for t:Tween in stage._beat_sets:t.kill()
	stage._beat_sets.clear()
	var exec:Node=stage.get_node("Execution")
	body.face(179.0,0.0)
	exec.call("_remember",key)
	var home:=f.nudge
	var heading:=deg_to_rad(-179.0)+body.get_parent_node_3d().global_rotation.y
	f.nudge-=f.spot.global_transform.basis.inverse()*Vector3(sin(heading),0.0,cos(heading))*0.6
	var before:=get_tree().get_processed_tweens()
	exec.call("_restore_survivors")
	var journey:Tween
	for t:Tween in get_tree().get_processed_tweens():
		if not t in before and t!=body._yaw_tween:journey=t
	assert_object(journey).is_not_null()
	body._yaw_tween.custom_step(0.21)
	var walking_yaw:=body.rotation.y
	journey.custom_step(0.6)
	assert_vector(f.nudge).is_equal(home)
	assert_float(body.rotation.y).is_equal_approx(walking_yaw,0.001)
	assert_float(f.body3d.locomotion_rate).is_equal(1.0)
	body._yaw_tween.custom_step(0.1)
	assert_float(absf(body.rotation.y-walking_yaw)).is_between(0.001,deg_to_rad(2.0))
	body._yaw_tween.custom_step(0.11)
	assert_float(absf(angle_difference(body.rotation.y,deg_to_rad(179.0)))).is_less(0.001)
	stage.skip_execution()
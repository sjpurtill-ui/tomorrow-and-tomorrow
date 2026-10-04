extends GdUnitTestSuite
## Actual longhouse seating may have no safe route. Implicit performers can
## be recast, but an explicit adjudicated actor must never be substituted.

const WorldFixtures:=preload("res://tests/court_eval/fixtures.gd")
const Modal:=preload("res://scripts/hud/audience_modal.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const Stage:=preload("res://scripts/hud/court_stage.gd")
const Exec:=preload("res://scripts/hud/court_exec_stage.gd")
const Director:=preload("res://scripts/hud/court_director.gd")
const Acting:=preload("res://scripts/hud/court_acting.gd")
const Backdrop:=preload("res://scripts/hud/court_backdrop.gd")

var _root_size:=Vector2i.ZERO
var _modals:Array[Control]=[]

func before_test()->void:
	WorldFixtures.new(self).base(false)
	Stage.directing=true;Stage.director=null;Stage.acting=null;Stage.use_sets=true
	Backdrop.tier_override=1
	_root_size=get_tree().root.size;get_tree().root.size=Vector2i(1920,1080)

func after_test()->void:
	# Dispose the stages' delayed callbacks before clearing their shared service.
	for modal in _modals:
		if is_instance_valid(modal):modal.free()
	_modals.clear()
	Stage.director=null;Stage.acting=null;Backdrop.tier_override=-1
	get_tree().root.size=_root_size

func _open()->Control:
	var marshal:Dictionary=GovernmentPeopleSystem.officeholder("Marshal")
	var target:Dictionary={"person_id":int(marshal.get("person_id",0))} if not marshal.is_empty() else Hall.summonable()[0].target
	var modal:Control=auto_free(Modal.new())
	_modals.append(modal)
	modal.audience_id=String(Hall.summon(target).get("id",""));add_child(modal)
	for i in 4:await await_idle_frame()
	modal.skip_reveal();modal.court_stage.settle()
	return modal.court_stage

func _blocked_actor(stage:Control,kind:="commoner")->String:
	var key:=""
	for candidate:String in stage.cast_order:
		var f:Stage.Figure=stage.figure(candidate)
		if candidate!=Stage.MAIN and f.body3d!=null and int(f.person.get("age",30))>=18:key=candidate;break
	var actor:Stage.Figure=stage.figure(key)
	# Enclose a non-main adult behind a real model obstacle before the new
	# room is cached. Reachability varies with destination and set dressing;
	# this must not depend on crowd_1 being blocked in every rendered hall.
	actor.spot.position=stage.court_set.mark("high_seat").position
	actor.nudge=Vector3.ZERO;actor.stroll=0.0;actor.body3d.stance="sit";actor._sync()
	var barrier:=MeshInstance3D.new();barrier.name="ExecutionCastingBarrier"
	var box:=BoxMesh.new();box.size=Vector3(2.0,1.5,2.0);barrier.mesh=box
	stage.court_set.model.add_child(barrier)
	barrier.position=actor.spot.position+Vector3(0,0.75,0)
	stage.extras[key]={"key":key,"role":"crowd","kind":kind,"age":45,"name":"Blocked helper","courage":1.0,"x":0.4}
	return key

func _choices(stage:Control,method:String,ex:="")->Dictionary:
	var probe:=Exec.new();probe.stage=stage;probe.method=method;probe.victim=Stage.MAIN
	var event:={"kind":"execution","method":method,"victim":Stage.MAIN,"ex":ex}
	var possible:=probe.prepare_support_roles(event)
	probe.free()
	return {"event":event,"possible":possible,"roles":Director.execution_roles(event,stage.cast_list(),stage.facts)}

func _plan(stage:Control)->Dictionary:
	for beat:Dictionary in stage._last_beats:
		if String(beat.get("act",""))=="plan":return beat.args
	return {}

func test_implicit_weapon_actor_uses_a_reachable_adult_in_the_real_longhouse()->void:
	for method:String in ["club","behead"]:
		var stage:=await _open()
		var blocked:=_blocked_actor(stage)
		var choices:=_choices(stage,method)
		assert_bool(blocked in choices.event.reachable_roles.executioner).is_false()
		assert_bool(choices.possible).is_true()
		assert_bool(stage.execute(method,Stage.MAIN,"","","mild")).is_true()
		var plan:=_plan(stage)
		assert_str(String(plan.ex)).is_not_equal(blocked)
		assert_bool(String(plan.ex) in choices.event.reachable_roles.executioner).is_true()
		await get_tree().create_timer(3.2).timeout
		var exec:Node=stage.get_node_or_null("Execution")
		assert_object(exec).is_not_null()
		if exec!=null:
			var body:Node3D=stage.figure(String(plan.ex)).body3d
			var role:Dictionary=Acting.exec_plan(String(plan.act)).roles.executioner
			var at:Vector3=exec.call("_plan_at",role.at)
			assert_float(Vector2(body.global_position.x-at.x,body.global_position.z-at.z).length()).is_less(0.25)
			assert_str(String(Acting.of(body)._a.clip)).is_equal(String(role.clip))
		stage.skip_execution()
		await await_idle_frame()

func test_blocked_cook_is_recast_but_explicit_blocked_executioner_is_not()->void:
	var stage:=await _open()
	var blocked:=_blocked_actor(stage,"elder")
	var choices:=_choices(stage,"club")
	assert_bool(blocked in choices.event.reachable_roles.cook).is_false()
	assert_bool(choices.possible).is_true()
	assert_bool(stage.execute("club",Stage.MAIN,String(choices.roles.ex),"","mild")).is_true()
	assert_str(String(_plan(stage).cook)).is_not_equal(blocked)
	stage.skip_execution();await await_idle_frame()
	# A fresh court retains the engine's identity and declines the visual act.
	stage=await _open();blocked=_blocked_actor(stage)
	stage.exec_done=false
	assert_bool(stage.execute("behead",Stage.MAIN,blocked,"","mild")).is_false()
	assert_bool(stage.exec_done).is_true()
	assert_bool(stage.executing()).is_false()
	assert_object(stage.get_node_or_null("Execution")).is_null()
	assert_bool(stage.figure(Stage.MAIN).body3d.visible).is_true()

func test_a_doorway_arrival_does_not_hide_the_unreachable_final_seat()->void:
	var stage:=await _open()
	var blocked:=_blocked_actor(stage)
	var actor:Stage.Figure=stage.figure(blocked)
	actor._path=PackedVector3Array([Vector3.ZERO,actor.spot.to_local(stage.court_set.mark("door").global_position)])
	actor.stroll=1.0;actor._sync()
	var choices:=_choices(stage,"behead")
	assert_bool(blocked in choices.event.reachable_roles.executioner).is_false()

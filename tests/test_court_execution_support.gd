extends GdUnitTestSuite
## A cook acting an authored plan is unavailable for crowd performances.

const Director:=preload("res://scripts/hud/court_director.gd")
const Fixtures:=preload("res://tests/test_court_director.gd")
const Acting:=preload("res://scripts/hud/court_acting.gd")
const WorldFixtures:=preload("res://tests/court_eval/fixtures.gd")
const Modal:=preload("res://scripts/hud/audience_modal.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const Stage:=preload("res://scripts/hud/court_stage.gd")
const CourtSet:=preload("res://scripts/hud/court_set_3d.gd")
const Figure3D:=preload("res://scripts/hud/court_figure_3d.gd")

var _root_size:=Vector2i.ZERO

func after_test()->void:
	Stage.director=null;Stage.acting=null
	if _root_size!=Vector2i.ZERO:get_tree().root.size=_root_size

func _cast(kind:String)->Array:
	var cast:=Fixtures.home_cast().slice(0,2)
	cast.append({"key":"support","role":"crowd","kind":kind,"name":"Cook",
		"age":8 if kind=="child" else 45,"courage":0.05,"dread":0.9,"x":0.41,"quirk":"flatterer"})
	return cast

func test_an_authored_cook_never_gets_a_crowd_performance_before_the_lid_finishes()->void:
	for kind:String in ["elder","commoner","scribe","guard","child"]:
		for dread:float in [0.1,0.95]:
			for style:String in ["full","mild"]:
				for seed in 12:
					var cast:=_cast(kind)
					var facts:=Fixtures.full_facts(60)
					facts["people_dread"]=dread
					var event:={"kind":"execution","method":"club","victim":"main","ex":"p1","style":style}
					var beats:=Director.beats_for(event,cast,facts,seed)
					var plan_at:=-1.0;var end_at:=-1.0
					for beat:Dictionary in beats:
						assert_str(String(beat.who)).override_failure_message("%s cook interrupted by %s" % [kind,beat]).is_not_equal("support")
						if String(beat.who)=="exec" and String(beat.act)=="plan":
							assert_str(String(beat.args.cook)).is_equal("support")
							plan_at=float(beat.t)
						if String(beat.who)=="exec" and String(beat.act)=="end":end_at=float(beat.t)
					assert_float(plan_at).is_greater_equal(0.0)
					var plan:=Acting.exec_plan("club_home_run")
					assert_str(String(plan.roles.cook.clip)).is_equal("exec_cook_lid")
					assert_float(end_at-plan_at).is_greater(Director._plan_cue(plan,"lid",7.6))

func test_an_unused_cook_remains_available_to_react_in_other_methods()->void:
	for method:String in ["behead","dogs","fire"]:
		var seen:=false
		for seed in 12:
			var beats:=Director.beats_for({"kind":"execution","method":method,"victim":"main","ex":"p1","style":"full"},_cast("elder"),Fixtures.full_facts(60),seed)
			for beat:Dictionary in beats:
				if String(beat.who)=="support":seen=true
		assert_bool(seen).override_failure_message("unused cook was excluded from %s" % method).is_true()

func test_actual_cook_keeps_the_authored_clip_until_the_lid_is_on_the_pot()->void:
	if not CourtSet.available() or not Figure3D.available():return
	WorldFixtures.new(self).base(false)
	Stage.directing=true;Stage.director=null;Stage.acting=null;Stage.use_sets=true
	_root_size=get_tree().root.size;get_tree().root.size=Vector2i(1920,1080)
	var marshal:Dictionary=GovernmentPeopleSystem.officeholder("Marshal")
	var target:Dictionary={"person_id":int(marshal.get("person_id",0))} if not marshal.is_empty() else Hall.summonable()[0].target
	var modal:Control=auto_free(Modal.new())
	modal.audience_id=String(Hall.summon(target).get("id",""))
	add_child(modal)
	for i in 4:await await_idle_frame()
	modal.skip_reveal();modal.court_stage.settle()
	var stage:Control=modal.court_stage
	assert_bool(stage.execute("club",Stage.MAIN,"","","mild")).is_true()
	var exec:Node=stage.get_node("Execution")
	var saw_cook:=false;var seated_lid:=false
	var deadline:=Time.get_ticks_msec()+12000
	while Time.get_ticks_msec()<deadline and is_instance_valid(exec):
		await get_tree().create_timer(0.05).timeout
		if not is_instance_valid(exec):break
		var key:=String(exec._plan_keys.get("cook",""))
		if key.is_empty():continue
		var actor:Node=Acting.of(stage.figure(key).body3d)
		if actor._a!=null and String(actor._a.clip)=="exec_cook_lid":saw_cook=true
		if saw_cook:
			assert_object(actor._a).is_not_null()
			if actor._a!=null:assert_str(String(actor._a.clip)).is_equal("exec_cook_lid")
		var lid:Node=exec._things.get("lid")
		var pot:Node=exec._things.get("pot")
		if is_instance_valid(lid) and is_instance_valid(pot) and lid.get_parent()==pot:
			seated_lid=true;break
	assert_bool(saw_cook).is_true()
	assert_bool(seated_lid).override_failure_message("the real authored cook never completed the lid cue").is_true()
	stage.skip_execution()

extends GdUnitTestSuite
## The real modal must distinguish a staged pack from ambient hall animals.
## No live API, save write, or direct bypass of the method-selection path.
const Fixtures:=preload("res://tests/court_eval/fixtures.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const Modal:=preload("res://scripts/hud/audience_modal.gd")
const Stage:=preload("res://scripts/hud/court_stage.gd")
const CourtSet:=preload("res://scripts/hud/court_set_3d.gd")
const Figure:=preload("res://scripts/hud/court_figure_3d.gd")
const Executions:=preload("res://scripts/hud/court_executions.gd")
const Backdrop:=preload("res://scripts/hud/court_backdrop.gd")
const Voice:=preload("res://scripts/character_voice.gd")
var _root_size:=Vector2i.ZERO

func before_test()->void:
	Fixtures.new(self).base(false)
	Stage.directing=true;Stage.director=null;Stage.acting=null;Stage.use_sets=true
	Backdrop.tier_override=-1;Backdrop.Stages.stage_override="";Voice.knowledge_override.clear()
	# Normal factual chapter selection: neither a pinned early room nor an
	# artificial removal of its resident dog can reproduce the actual bug.
	GameState.known_discoveries.assign(["temple_high_steward","pictographic_records","plain_weaving"])
	GameState.elapsed_days=600*365
	Executions.gore="full";Executions.last_used=""
	_root_size=get_tree().root.size;get_tree().root.size=Vector2i(1920,1080)

func after_test()->void:
	Backdrop.tier_override=-1;Backdrop.Stages.stage_override="";Voice.knowledge_override.clear()
	Stage.director=null;Stage.acting=null;Executions.gore="full";Executions.last_used=""
	get_tree().root.size=_root_size

func _open_later_court()->Control:
	assert_bool(CourtSet.available() and Figure.available()).override_failure_message("Imported court and figure models are required for this regression").is_true()
	var marshal:Dictionary=GovernmentPeopleSystem.officeholder("Marshal")
	var target:Dictionary={"person_id":int(marshal.get("person_id",0))} if not marshal.is_empty() else Hall.summonable()[0].target
	var modal:Control=auto_free(Modal.new())
	modal.audience_id=String(Hall.summon(target).get("id",""));add_child(modal)
	for index in 4:await await_idle_frame()
	modal.skip_reveal();await await_idle_frame();modal.court_stage.settle()
	var stage:Control=modal.court_stage
	assert_str(String(stage.facts.presentation.period)).is_equal("ancient")
	assert_str(String(stage.court_set.kind)).is_equal("chapter_03")
	assert_object(stage.court_set.animal("dog")).is_null()
	return modal

func test_death_menu_offers_hounds_without_a_resident_dog()->void:
	var modal:Control=await _open_later_court()
	modal._build_orders_row()
	var menu:MenuButton=modal.orders_row.get_node("Order_PutToDeath")
	var found:=false
	for item:Dictionary in menu.get_meta("items",[]):
		if String(item.label)=="Death by hounds":
			found=true
			assert_str(String(item.text)).contains("by the dogs")
	assert_bool(found).override_failure_message("Ambient animals are absent, but a staged pack must remain in the actual death menu").is_true()

func test_explicit_dogs_order_reaches_modal_execution_unchanged()->void:
	var modal:Control=await _open_later_court()
	var stage:Control=modal.court_stage
	assert_bool(modal.show_execution("Feed them to the dogs.",{})).is_true()
	assert_str(stage.exec_method).override_failure_message("The actual modal must not silently substitute another execution").is_equal("dogs")
	await get_tree().create_timer(1.6).timeout
	assert_bool(stage.executing()).is_true()
	if stage.executing():
		assert_str(stage._exec.method).is_equal("dogs")
		stage.skip_execution()
		await await_idle_frame()

func test_pack_has_three_dogs_and_cleans_up_when_no_resident_is_borrowed()->void:
	var modal:Control=await _open_later_court()
	var stage:Control=modal.court_stage
	var court:Node3D=stage.court_set
	var before:int=court.animals.size()
	assert_bool(stage.execute("dogs",Stage.MAIN)).is_true()
	var execution:Node=stage.get_node("Execution")
	execution.call("_pack_come",{"more":2})
	assert_int(execution._pack.size()).is_equal(3)
	assert_int(court.animals.size()).is_equal(before+3)
	stage.skip_execution()
	await await_idle_frame();await await_idle_frame()
	assert_int(court.animals.size()).is_equal(before)
	assert_object(court.animal("dog")).is_null()
	assert_bool(stage.executing()).is_false()

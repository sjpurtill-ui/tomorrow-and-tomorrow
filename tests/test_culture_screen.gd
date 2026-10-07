extends GdUnitTestSuite
## THE CULTURE SCREEN (hud/culture_model.gd, hud/culture_panel.gd): it says
## what our culture DOES, in the engine's numbers: the ledger of every lever
## the course and the values move, the course by its share of memory, all ten
## values lived and upheld with the gap that costs cohesion, how our leaders
## behave, and what draws others. War conduct is not culture and is not here.

const Model:=preload("res://scripts/hud/culture_model.gd")
const CulturePanel:=preload("res://scripts/hud/culture_panel.gd")
const Ambition:=preload("res://scripts/ambition_effects.gd")
const ValuesModel:=preload("res://scripts/societal_values_model.gd")

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(991704)
	GovernmentPeopleSystem.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"]
	SettlementModel.ensure_founded();GovernmentPeopleSystem.initialize()
	PeopleDirection.reset_for_new_world()
	PeopleDirection.choose("inquiry")

func after_test()->void:
	WorldSimulation.clear()

func _block()->Dictionary:
	var noop:=func()->void:pass
	return {"type":"culture","culture":Model.snapshot(),"lived_values":GameState.societal_values.get("lived",{}),"on_direction":noop,"on_council":noop,"on_capacities":noop}

func test_the_ledger_adds_course_and_values_in_the_engines_own_numbers()->void:
	var snap:=Model.snapshot()
	var knowledge:Dictionary={}
	for r:Dictionary in snap.ledger:
		if String(r.id)=="knowledge": knowledge=r
	assert_bool(knowledge.is_empty()).override_failure_message("a people of ideas moves learning").is_false()
	assert_float(float(knowledge.course)).is_equal_approx(Ambition.effect("knowledge_gain"),0.0001)
	assert_float(float(knowledge.values)).is_equal_approx(ValuesModel.simulation_effect(GameState.societal_values,"knowledge"),0.0001)
	assert_float(float(knowledge.total)).is_equal_approx(float(knowledge.course)+float(knowledge.values),0.0001)

func test_the_course_its_share_and_the_research_it_leans()->void:
	var course:Dictionary=Model.snapshot().course
	assert_str(String(course.current)).is_equal("inquiry")
	assert_array(course.remembered as Array).is_not_empty()
	assert_float(float((course.remembered as Array)[0].share)).is_equal_approx(1.0,0.001)
	var leaned:=false
	for r:Dictionary in course.research:
		if String(r.domain)=="knowledge" and float(r.multiplier)>1.0: leaned=true
	assert_bool(leaned).is_true()

func test_all_ten_values_lived_and_upheld_and_the_gap_that_costs_cohesion()->void:
	var snap:=Model.snapshot()
	assert_int((snap.values as Array).size()).is_equal(10)
	var a:Dictionary=snap.alignment
	assert_float(float(a.cohesion)).is_equal_approx(ValuesModel.simulation_effect(GameState.societal_values,"cohesion"),0.0001)
	assert_float(float(a.legitimacy)).is_equal_approx(ValuesModel.simulation_effect(GameState.societal_values,"legitimacy"),0.0001)

func test_our_leaders_temper_and_what_draws_others()->void:
	var snap:=Model.snapshot()
	assert_int((snap.leaders.sides as Array).size()).is_equal(5)
	assert_str(String(snap.leaders.work)).is_not_empty()
	assert_float(float(snap.others.allure)).is_between(0.0,1.0)

func test_the_page_draws_what_culture_does_and_holds_still_between_days()->void:
	var panel:Control=auto_free(CulturePanel.new());add_child(panel)
	var block:=_block()
	panel.setup(block)
	var text:=""
	for label in panel.find_children("*","Label",true,false): text+=(label as Label).text+"\n"
	for heading in ["WHO WE ARE","WHAT OUR WAYS DO TO THE REALM","THE COURSE WE FOLLOW","WHAT WE LIVE BY","HOW OUR LEADERS BEHAVE","HOW OTHERS SEE OUR WAYS"]:
		assert_str(text).contains(heading)
	assert_str(text).not_contains("REPUTATION FROM OUR CONDUCT")
	assert_object(panel.find_child("Ledger",true,false)).is_not_null()
	# A new day with the same rounded figures keeps every node.
	var first:=panel.get_child(0)
	assert_bool(panel.update_block(_block())).is_true()
	assert_object(panel.get_child(0)).is_same(first)

extends GdUnitTestSuite

const Build=preload("res://scripts/settlement_construction.gd")
const Craft=preload("res://scripts/opening_craft_practice.gd")
const SettlementModelScript=preload("res://scripts/settlement_model.gd")

var model:Node

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(8713)
	DiscoverySystem.reset_for_new_world()
	DiscoverySystem.initialize()
	GameState.set_process(false)
	CivilizationSystem.set_process(false)
	MilitaryCampaign.set_process(false)
	GameState.initialize_population_model()
	GameState.settlement_site_committed=true
	GameState.settlement_founded_at=Vector3.ZERO
	GameState.settlement_completed=["Hearth Circle","Lean-to Shelters","Open Work Area"]
	GameState.population_allocations.merge({"Construction":100,"Logistics":10,"Crafting":10},true)
	GameState.resource_stockpiles={"Joined Timber Components":10.0,"Timber":50.0,"Fiber Plants":40.0,"Clay":20.0,"Stone":30.0}
	GameState.known_discoveries=[]
	GameState.discovery_adoption={}
	model=auto_free(SettlementModelScript.new())
	model.ensure_founded()

func after_test()->void:
	WorldSimulation.clear()
	GameState.set_process(true)
	CivilizationSystem.set_process(true)
	MilitaryCampaign.set_process(true)

func _definition()->Dictionary:
	for candidate:Dictionary in Build._settlement_definitions():
		if String(candidate.name)=="Framed Hall":return candidate
	return {}

func _know_framing()->void:
	GameState.known_discoveries.append("framed_construction")
	GameState.discovery_adoption.framed_construction=1.0

func _build_hall()->Dictionary:
	_know_framing()
	GameState.settlement_projects["Framed Hall"]=22.0
	var events:=Build.process_day()
	assert_array(events).has_size(1)
	var morphology_events:Array[Dictionary]=[]
	model._synchronize_early_works(30,morphology_events)
	assert_bool(morphology_events.any(func(event:Dictionary)->bool:return String(event.get("title",""))=="A Framed Hall Rose")).is_true()
	for plot:Dictionary in GameState.settlement_plots:
		if String(plot.get("form",""))=="timber_frame_hall":return plot
	return {}

func test_framed_hall_is_hidden_without_knowledge_staff_or_joined_components()->void:
	var definition:=_definition()
	assert_dict(definition).is_not_empty()
	assert_bool(Build._settlement_project_available(definition)).is_false()
	_know_framing()
	GameState.population_allocations.Construction=0
	assert_bool(Build._settlement_project_available(definition)).is_false()
	GameState.population_allocations.Construction=100
	GameState.resource_stockpiles["Joined Timber Components"]=0.0
	assert_bool(Build._settlement_project_available(definition)).is_false()

func test_knowledge_alone_provides_no_framed_construction_effects()->void:
	_know_framing()
	DiscoverySystem.refresh_operating_effects()
	assert_float(Craft.factor("framed_construction")).is_equal(0.0)
	assert_float(DiscoverySystem.effect("housing_output")).is_equal(0.0)
	assert_float(DiscoverySystem.effect("construction_rate")).is_equal(0.0)
	assert_float(DiscoverySystem.effect("disaster_resilience")).is_equal(0.0)

func test_project_consumes_materials_and_converts_existing_communal_ground()->void:
	var timber_before:=float(GameState.resource_stockpiles.Timber)
	var components_before:=float(GameState.resource_stockpiles["Joined Timber Components"])
	var communal_polygon:PackedVector2Array
	for plot:Dictionary in GameState.settlement_plots:
		if String(plot.get("form",""))=="open_hearth_yard":communal_polygon=(plot.polygon as PackedVector2Array).duplicate()
	var hall:=_build_hall()
	assert_dict(hall).is_not_empty()
	assert_array(hall.polygon).is_equal(communal_polygon)
	assert_str(String(hall.roof_plan)).is_equal("thatched_ridge")
	assert_float(float(hall.roof_coverage)).is_greater_equal(0.58)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_less(timber_before)
	assert_float(float(GameState.resource_stockpiles["Joined Timber Components"])).is_less(components_before)
	var paid_event:Dictionary={}
	for event:Dictionary in GameState.building_ledger:
		if String(event.get("kind",""))=="Framed Hall":paid_event=event
	assert_dict(paid_event).is_not_empty()
	assert_str(String(paid_event.form)).is_equal("timber_frame_hall")
	assert_bool(bool(paid_event.counts_materials)).is_true()

func test_completed_staffed_hall_activates_bounded_effects()->void:
	var hall:=_build_hall()
	assert_dict(hall).is_not_empty()
	DiscoverySystem.refresh_operating_effects()
	var coverage:=Craft.factor("framed_construction")
	assert_float(coverage).is_between(0.50,1.0)
	assert_float(DiscoverySystem.effect("housing_output")).is_equal_approx(0.10*coverage,0.000001)
	assert_float(DiscoverySystem.effect("construction_rate")).is_equal_approx(0.08*coverage,0.000001)

func test_hall_condition_and_builder_withdrawal_scale_or_end_operation()->void:
	var hall:=_build_hall()
	hall.condition=0.40
	DiscoverySystem.refresh_operating_effects()
	assert_float(Craft.factor("framed_construction")).is_equal_approx(0.40,0.000001)
	assert_float(DiscoverySystem.effect("disaster_resilience")).is_equal_approx(0.012,0.000001)
	GameState.population_allocations.Construction=0
	DiscoverySystem.refresh_operating_effects()
	assert_float(Craft.factor("framed_construction")).is_equal(0.0)
	assert_float(DiscoverySystem.effect("disaster_resilience")).is_equal(0.0)

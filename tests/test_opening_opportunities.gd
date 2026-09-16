extends GdUnitTestSuite
const O=preload("res://scripts/opening_opportunities.gd")

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(8675309)
	DiscoverySystem.reset_for_new_world()
	DiscoverySystem.initialize()
	for role:String in GameState.POPULATION_ROLES:GameState.population_allocations[role]=0.0
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)

func after_test()->void:
	WorldSimulation.clear()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)

func advance_days(count:int,context:Dictionary)->void:
	for day in count:
		GameState.elapsed_days=day
		O.advance(context)

func test_root_questions_need_distinct_lived_evidence()->void:
	for id:String in O.RULES:
		assert_bool(O.ready(id)).is_false()
		assert_bool(DiscoverySystem._discovery_is_eligible(DiscoverySystem.discovery_definition(id),0)).is_false()
	GameState.population_allocations.Food=1.0
	advance_days(18,{"foraging":1.0})
	assert_bool(O.ready("seasonal_patterns")).is_true()
	assert_bool(DiscoverySystem._discovery_is_eligible(DiscoverySystem.discovery_definition("seasonal_patterns"),18)).is_true()
	for id:String in O.RULES:
		if id!="seasonal_patterns":assert_float(O.progress(id)).is_equal(0.0)

func test_travel_exposes_routes_without_unlocking_settlement_questions()->void:
	advance_days(8,{"traveling":true,"travel":1.0,"foraging":0.0})
	assert_bool(O.ready("route_memory")).is_true()
	assert_bool(O.ready("drainage")).is_false()
	assert_bool(O.ready("labor_rotations")).is_false()

func test_settlement_work_exposes_drainage_labor_tallies_and_watch_separately()->void:
	GameState.settlement_site_committed=true
	GameState.population_allocations={"Food":0.0,"Survey":0.0,"Extraction":0.0,"Construction":3.0,"Crafting":2.0,"Logistics":2.0,"Knowledge":0.0,"Administration":2.0,"Defense":2.0}
	GameState.resource_stockpiles={"Timber":25.0}
	advance_days(6,{"settled":true,"precipitation":1.0,"foraging":0.0})
	assert_bool(O.ready("drainage")).is_true()
	assert_bool(O.ready("tallies")).is_false()
	assert_bool(O.ready("labor_rotations")).is_false()
	assert_bool(O.ready("watch_rotation")).is_false()
	advance_days_from(6,6,{"settled":true,"precipitation":0.0,"foraging":0.0})
	assert_bool(O.ready("tallies")).is_true()
	assert_bool(O.ready("labor_rotations")).is_true()
	assert_bool(O.ready("watch_rotation")).is_false()
	advance_days_from(12,8,{"settled":true,"precipitation":0.0,"foraging":0.0})
	assert_bool(O.ready("watch_rotation")).is_true()

func advance_days_from(first:int,count:int,context:Dictionary)->void:
	for day in range(first,first+count):
		GameState.elapsed_days=day
		O.advance(context)

func test_wound_and_plant_evidence_require_their_physical_cases()->void:
	GameState.civilian_injuries.limited=1.0
	advance_days(3,{"freshwater":1.0,"foraging":0.0})
	assert_bool(O.ready("wound_cleaning")).is_true()
	assert_bool(O.ready("herbal_classification")).is_false()
	GameState.civilian_injuries={"limited":0.0,"severe":0.0}
	GameState.resource_deposits=[{"resource":"Medicinal Plants","stage":"recognized"}]
	GameState.population_allocations.Food=1.0
	advance_days_from(3,8,{"freshwater":0.0,"foraging":1.0})
	assert_bool(O.ready("herbal_classification")).is_true()

func test_returned_studied_knowledge_is_a_slower_alternative_to_local_cases()->void:
	GameState.society_exchange.collections["visit:watch"]={"id":"visit:watch","kind":"knowledge","study":1.0,"returned_day":4}
	GameState.society_exchange.evidence.watch_rotation="visit:watch"
	GameState.elapsed_days=3
	assert_bool(O.ready("watch_rotation")).is_false()
	GameState.elapsed_days=4
	assert_bool(O.ready("watch_rotation")).is_true()

func test_state_is_bounded_valid_and_owned_by_each_civilization()->void:
	O.record("route_memory",1000.0)
	assert_float(O.progress("route_memory")).is_equal(float(O.RULES.route_memory.goal))
	assert_bool(O.valid(JSON.parse_string(JSON.stringify(GameState.opening_opportunities)))).is_true()
	var malformed:=GameState.opening_opportunities.duplicate(true);malformed.evidence.route_memory=-1
	assert_bool(O.valid(malformed)).is_false()
	WorldSimulation.create_actor("opportunity_neighbor",321)
	WorldSimulation.scoped("opportunity_neighbor",func()->void:
		assert_float(O.progress("route_memory")).is_equal(0.0)
		O.record("route_memory",2.0)
		assert_float(O.progress("route_memory")).is_equal(2.0)
	)
	var payload:=WorldSimulation.export_state()
	assert_str(WorldSimulation.validate_payload(payload)).is_empty()
	payload.actors.opportunity_neighbor.state.GameState.opening_opportunities.evidence.route_memory=-1
	assert_str(WorldSimulation.validate_payload(payload)).is_equal("Invalid civilization opening opportunity records.")
	assert_float(O.progress("route_memory")).is_equal(float(O.RULES.route_memory.goal))

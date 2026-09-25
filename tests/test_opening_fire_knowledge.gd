extends GdUnitTestSuite

const Paths=preload("res://scripts/knowledge_pathways.gd")
const Requirements=preload("res://scripts/technology_requirements.gd")
const Fire=preload("res://scripts/fire_practice.gd")
const Meals=preload("res://scripts/food_preparation.gd")
const FIRE_IDS=["ember_tending","friction_fire_ignition","percussion_fire_ignition","hearth_heat_retention","fuel_air_drying"]

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(4021)
	DiscoverySystem.reset_for_new_world()
	DiscoverySystem.initialize()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	DiscoverySystem.latest_context={"fire":1.0,"food":1.0,"clay":1.0,"timber":1.0,"crafting":1.0}

func after_test()->void:
	WorldSimulation.clear()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)

func test_authored_fire_practices_are_live_unique_discoveries()->void:
	for id:String in FIRE_IDS:
		var entry:=DiscoverySystem.discovery_definition(id)
		assert_bool(entry.is_empty()).override_failure_message(id).is_false()
		assert_str(String(entry.get("production_contract",""))).is_not_empty()
		assert_bool(entry.get("effects",{}).is_empty()).is_true()
	var live_ids:Array=[]
	for entry:Dictionary in DiscoverySystem.technology_catalog:live_ids.append(String(entry.id))
	for id:String in FIRE_IDS:assert_int(live_ids.count(id)).is_equal(1)

func test_fire_is_first_preserved_then_deliberately_recreated()->void:
	assert_bool(Paths.ready(DiscoverySystem.discovery_definition("ember_tending"),0)).is_true()
	assert_bool(Paths.ready(DiscoverySystem.discovery_definition("friction_fire_ignition"),0)).is_false()
	assert_bool(Paths.ready(DiscoverySystem.discovery_definition("percussion_fire_ignition"),0)).is_false()
	GameState.known_discoveries.append("ember_tending")
	# 600-year design: both deliberate ignitions follow preserved fire directly.
	assert_bool(Paths.ready(DiscoverySystem.discovery_definition("friction_fire_ignition"),0)).is_true()
	assert_bool(Paths.ready(DiscoverySystem.discovery_definition("percussion_fire_ignition"),0)).is_true()

func test_cooking_and_charcoal_cannot_precede_a_controlled_hearth()->void:
	GameState.known_discoveries.assign(["ember_tending","food_drying"])
	assert_bool(Paths.ready(DiscoverySystem.discovery_definition("hearth_roasting_control"),0)).is_false()
	assert_bool(Paths.ready(DiscoverySystem.discovery_definition("charcoal"),0)).is_false()
	GameState.known_discoveries.append("hearth_heat_retention")
	assert_bool(Paths.ready(DiscoverySystem.discovery_definition("hearth_roasting_control"),0)).is_true()
	# 600-year design: charcoal is learned from earth-oven cooking over a kept hearth.
	assert_bool(Paths.ready(DiscoverySystem.discovery_definition("charcoal"),0)).is_false()
	GameState.known_discoveries.append("earth_oven_cooking")
	assert_bool(Paths.ready(DiscoverySystem.discovery_definition("charcoal"),0)).is_true()

func test_preservation_and_ceramics_keep_branches_without_bypassing_fire()->void:
	var smoking:=DiscoverySystem.discovery_definition("smoking")
	var firing:=DiscoverySystem.discovery_definition("pit_firing")
	GameState.known_discoveries.assign(["food_drying","clay_shaping"])
	assert_bool(Paths.ready(smoking,0)).is_false()
	assert_bool(Paths.ready(firing,0)).is_false()
	GameState.known_discoveries.append("hearth_heat_retention")
	# 600-year design: smoking also rests on tended embers; firing on the kept hearth.
	assert_bool(Paths.ready(smoking,0)).is_false()
	assert_bool(Paths.ready(firing,0)).is_true()
	GameState.known_discoveries.append("ember_tending")
	assert_bool(Paths.ready(smoking,0)).is_true()
	assert_str(String(Paths.chosen(smoking,0).id)).is_equal("local")
	assert_str(String(Paths.chosen(firing,0).id)).is_equal("experimental")
	GameState.known_discoveries.erase("food_drying")
	GameState.known_discoveries.append("charcoal")
	# Charcoal remains an optional approach; it no longer replaces food drying.
	assert_bool(Paths.ready(smoking,0)).is_false()
	assert_bool(Paths.ready(firing,0)).is_true()
	assert_str(String(Paths.chosen(firing,0).id)).is_equal("local")

func test_opening_fire_repairs_leave_the_live_graph_reachable()->void:
	var graph:Array=[]
	for entry:Dictionary in DiscoverySystem.technology_catalog:graph.append(Paths.graph_entry(entry))
	var dormant=preload("res://tools/technology-review/dormant_or_audit.gd")
	graph=dormant.factor_common(graph,DiscoverySystem.technology_catalog)
	assert_array(Requirements.validate(graph,dormant.pending(graph))).is_empty()

func test_first_tended_fire_is_physical_and_consumes_daily_fuel()->void:
	GameState.settlement_site_committed=true
	GameState.known_discoveries.assign(["ember_tending"])
	GameState.resource_stockpiles.Timber=0.10
	var report:=Fire.advance(1,false,false)
	assert_bool(report.available).is_true()
	assert_str(String(report.source)).is_equal("found_or_transferred")
	assert_float(float(report.maintenance_timber)).is_equal_approx(Fire.MAINTENANCE_TIMBER,.000001)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal_approx(.10-Fire.MAINTENANCE_TIMBER,.000001)

func test_unfueled_embers_die_and_knowledge_does_not_supply_heat()->void:
	GameState.settlement_site_committed=true
	GameState.known_discoveries.assign(["ember_tending","hearth_heat_retention","hearth_roasting_control"])
	GameState.fire_practice={"initialized":true,"embers":.50,"last_day":-1,"source":"found_or_transferred","last_event":"","fuel_today":0.0,"ignitions":0,"extinctions":0}
	GameState.resource_stockpiles.Timber=0.0
	var report:=Fire.advance(1,true,false)
	assert_bool(report.available).is_false()
	assert_int(int(report.extinctions)).is_equal(1)
	assert_str(String(Meals.plan(10,20,false).method)).is_empty()

func test_deliberate_ignition_restores_fire_from_actual_material()->void:
	GameState.settlement_site_committed=true
	GameState.known_discoveries.assign(["ember_tending","friction_fire_ignition","hearth_heat_retention","hearth_roasting_control"])
	GameState.fire_practice={"initialized":true,"embers":0.0,"last_day":-1,"source":"none","last_event":"","fuel_today":0.0,"ignitions":0,"extinctions":1}
	GameState.resource_stockpiles.Timber=0.10
	var report:=Fire.advance(2,true,false)
	assert_bool(report.available).is_true()
	assert_str(String(report.source)).is_equal("friction")
	assert_int(int(report.ignitions)).is_equal(1)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal_approx(.10-Fire.FRICTION_TIMBER,.000001)
	GameState.discovery_adoption.hearth_roasting_control=1.0
	GameState.food_stocks={"Fresh plants":20.0}
	assert_str(String(Meals.plan(10,20,false).method)).is_equal("hearth_roasting_control")

func test_failed_percussion_attempt_returns_unusable_tinder_stock()->void:
	GameState.settlement_site_committed=true
	GameState.known_discoveries.assign(["ember_tending","percussion_fire_ignition"])
	GameState.fire_practice={"initialized":true,"embers":0.0,"last_day":-1,"source":"none","last_event":"","fuel_today":0.0,"ignitions":0,"extinctions":0}
	GameState.resource_stockpiles.Timber=0.10;GameState.resource_stockpiles.Stone=0.0
	var report:=Fire.advance(3,true,false)
	assert_bool(report.available).is_false()
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal_approx(.10,.000001)
	assert_float(float(GameState.resource_stockpiles.Stone)).is_equal_approx(0.0,.000001)

func test_fire_state_is_reflected_and_valid_for_save_roundtrip()->void:
	GameState.fire_practice={"initialized":true,"embers":.72,"last_day":14,"source":"friction","last_event":"Embers were sheltered and fed","fuel_today":.015,"ignitions":2,"extinctions":1}
	var captured:Dictionary=SaveSystem._capture_reflected(GameState,[])
	assert_bool(Fire.valid(captured.fire_practice)).is_true()
	GameState.fire_practice=Fire.empty_state()
	SaveSystem._apply_reflected(GameState,{"fire_practice":bytes_to_var(var_to_bytes(captured.fire_practice))})
	assert_float(float(GameState.fire_practice.embers)).is_equal_approx(.72,.000001)
	assert_int(int(GameState.fire_practice.ignitions)).is_equal(2)

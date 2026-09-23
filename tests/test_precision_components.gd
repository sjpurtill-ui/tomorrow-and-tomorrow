extends GdUnitTestSuite
const K=preload("res://scripts/precision_component_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
const ITEMS=["precision_reamers","pilot_bored_sleeves_20","reamed_sleeves_20","turned_shafts_20","fit_gauges_20","interchangeable_bearings_20","bearing_assembled_motors","slotting_rams","slotted_drive_hubs","progressive_keyway_broaches","broached_drive_hubs","keyed_friction_clutches","gear_shaping_cutters","shaped_gear_sets"]
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("precision",1209)
func after_test()->void:
	WorldSimulation.clear();GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
func learn(id:String)->void:
	if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
	WorldSimulation.state.discovery_adoption[id]=1.0
func test_five_original_definitions_and_fourteen_actual_routes()->void:
	WorldSimulation.scoped("precision",func()->void:
		assert_int(K.entries().size()).is_equal(5)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		var expected={"reamed_bore_finishing":["column_drilling_machines","dimensional_metrology"],"reciprocating_profile_slotting":["crank_linkages","toolbit_heat_treatment"],"gear_shaping_generation":["gear_tooth_generation","precision_machinery"],"progressive_profile_broaching":["toolbit_heat_treatment","precision_machinery"],"interchangeable_component_fits":["dimensional_metrology","workshop_standards"]}
		for e:Dictionary in K.entries():
			assert_array(e.requires_all).is_equal(expected[e.id]);assert_array(e.requires_any).is_empty()
		for item:String in ITEMS:assert_bool(I.product(item).is_empty()).is_false())
func test_rough_wrong_profile_and_missing_tools_block_without_payment()->void:
	WorldSimulation.scoped("precision",func()->void:
		var state=WorldSimulation.state;var spec:=I.product("interchangeable_bearings_20");learn(spec.gate)
		for field:String in ["materials","tooling"]:
			for r:String in spec[field]:state.resource_stockpiles[r]=10.0
		state.resource_stockpiles["20 mm Reamed Sleeves"]=0.0
		state.resource_stockpiles["20 mm Pilot-Bored Sleeves"]=10.0;state.resource_stockpiles["Shaft Bearings"]=10.0
		var before:Dictionary=state.resource_stockpiles.duplicate(true)
		assert_bool(WorldSimulation.military.start_production_line("interchangeable_bearings_20",1).has("error")).is_true()
		assert_dict(state.resource_stockpiles).is_equal(before)
		state.resource_stockpiles["20 mm Reamed Sleeves"]=10.0;state.resource_stockpiles["20 mm Fit Gauge Sets"]=0.0
		before=state.resource_stockpiles.duplicate(true)
		assert_bool(WorldSimulation.military.start_production_line("interchangeable_bearings_20",1).has("error")).is_true()
		assert_dict(state.resource_stockpiles).is_equal(before))

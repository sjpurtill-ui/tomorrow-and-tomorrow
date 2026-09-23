extends GdUnitTestSuite
const K=preload("res://scripts/abrasive_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
const ITEMS=["fused_abrasive_alumina", "graded_alumina_grain", "vitrified_abrasive_bond", "green_abrasive_wheels", "fired_abrasive_wheels", "checked_abrasive_wheels", "abrasive_dressing_tools", "dressed_abrasive_wheels", "grinding_spindle_units", "cylindrical_grinding_fixtures", "centerless_regulating_wheels", "centerless_support_sets", "surface_grinding_fixtures", "oversize_plain_shaft_blanks", "cylindrical_ground_shaft_candidates", "centerless_ground_shaft_candidates", "checked_cylindrical_shafts", "checked_centerless_shafts", "motor_mount_plate_blanks", "surface_ground_mount_candidates", "checked_ground_mounts", "abrasive_hide_glue", "abrasive_maker_coated_web", "abrasive_sized_web", "checked_dry_abrasive_belts", "abrasive_belt_stands", "motor_housing_edge_blanks", "belt_finished_housing_candidates", "checked_deburred_housings", "ground_shaft_bearing_assemblies", "ground_component_motors"]
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("abrasive",1209)
func after_test()->void:
	WorldSimulation.clear();GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
func learn(id:String)->void:
	if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
	WorldSimulation.state.discovery_adoption[id]=1.0
func test_original_five_predicates_and_registered_routes()->void:
	WorldSimulation.scoped("abrasive",func()->void:
		assert_int(K.entries().size()).is_equal(5)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		var expected={"abrasive_grinding_control":["comparative_mineral_hardness","precision_machinery"],"centerless_grinding":["abrasive_grinding_control","precision_machinery"],"cylindrical_grinding":["centre_lathe_assembly","abrasive_grinding_control"],"surface_grinding":["machine_way_scraping","abrasive_grinding_control"],"abrasive_belt_finishing":["abrasive_grinding_control","belt_power_transmission"]}
		for e:Dictionary in K.entries():
			assert_array(e.requires_all).is_equal(expected[e.id]);assert_array(e.requires_any).is_empty()
		for id:String in ITEMS:assert_bool(I.product(id).is_empty()).is_false())
func test_raw_wheels_wrong_shapes_and_uninspected_parts_cannot_substitute()->void:
	WorldSimulation.scoped("abrasive",func()->void:
		for pair:Array in [["dressed_abrasive_wheels","Checked Abrasive Wheels"],["centerless_ground_shaft_candidates","Oversize Plain Shaft Blanks"],["ground_shaft_bearing_assemblies","20 mm Ground Shafts"],["ground_component_motors","Ground Motor Mount Plates"],["belt_finished_housing_candidates","Checked Dry Abrasive Belts"]]:
			var spec:=I.product(pair[0]);learn(spec.gate)
			for field:String in ["materials","tooling"]:
				for r:String in spec[field]:WorldSimulation.state.resource_stockpiles[r]=100.0
			WorldSimulation.state.resource_stockpiles[pair[1]]=0.0
			for r:String in ["Refined Alumina","Fired Abrasive Wheels","20 mm Turned Shafts","Motor Mount Plate Blanks","Sized Dry Abrasive Web"]:WorldSimulation.state.resource_stockpiles[r]=100.0
			var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
			assert_bool(WorldSimulation.military.start_production_line(pair[0],1).has("error")).is_true()
			assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(before))
func test_legacy_candidate_stock_cannot_gain_free_provenance()->void:
	WorldSimulation.scoped("abrasive",func()->void:
		var spec:=I.product("checked_ground_mounts");learn(spec.gate)
		for field:String in ["materials","tooling"]:
			for r:String in spec[field]:WorldSimulation.state.resource_stockpiles[r]=100.0
		var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
		assert_bool(WorldSimulation.military.start_production_line("checked_ground_mounts",1).has("error")).is_true()
		assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(before))
func test_lot_capacity_blocks_admission_and_malformed_lots_reject()->void:
	WorldSimulation.scoped("abrasive",func()->void:
		var Q=preload("res://scripts/abrasive_inspection.gd")
		for n:int in range(Q.LIMIT):Q.record({"item":"fired_abrasive_wheels","id":n+1,"completed":1},1)
		var spec:=I.product("fired_abrasive_wheels");learn(spec.gate)
		for field:String in ["materials","tooling"]:
			for r:String in spec[field]:WorldSimulation.state.resource_stockpiles[r]=1000.0
		var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
		assert_bool(WorldSimulation.military.start_production_line("fired_abrasive_wheels",1).has("error")).is_true()
		assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(before)
		assert_bool(Q.valid(Q.data())).is_true()
		var malformed:Dictionary=Q.data().duplicate(true);malformed.records["1"].remaining=-1
		assert_bool(Q.valid(malformed)).is_false())

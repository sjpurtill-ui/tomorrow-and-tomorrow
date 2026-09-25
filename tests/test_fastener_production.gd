extends GdUnitTestSuite
const K=preload("res://scripts/fastener_knowledge.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("fasteners",1032)

func after_test()->void:WorldSimulation.clear()

func setup()->void:
	var state=WorldSimulation.state
	state.settlement_site_committed=true;state.convoy_traveling=false
	state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0
	state.population_allocations.Crafting=40;state.population_allocations.Logistics=12
	state.resource_stockpiles.clear()
	for resource:String in ["Timber","Stone","Wrought Iron","Steel","Steel Sheets","Charcoal","Coal","Freshwater","Copper Wire","Insulated Cable","Metalworking Lathes","Steel Tool Bits","Machine Bench Vises","Surface Plates","Column Drills","Drill Bits","Horizontal Mills","Drill Jigs","Basic Machine Tool Sets","Machinist Straightedges"]:state.resource_stockpiles[resource]=10000.0
	for entry:Dictionary in WorldSimulation.discovery.technology_catalog:
		if entry.id not in state.known_discoveries:state.known_discoveries.append(entry.id)
		state.discovery_adoption[entry.id]=1.0

func test_thread_methods_reconverge_but_keep_shared_measurement_and_nut_foundations()->void:
	WorldSimulation.scoped("fasteners",func()->void:
		setup();var state=WorldSimulation.state;var discovery=WorldSimulation.discovery
		var entry:=discovery.discovery_definition("matched_thread_inspection")
		var day:=int(ceil(discovery.research_600_earliest_year(entry)*365.0)) # once its era has come
		state.known_discoveries.erase("matched_thread_inspection")
		state.known_discoveries.erase("external_thread_cutting");state.known_discoveries.erase("bolt_thread_rolling")
		assert_bool(discovery._discovery_is_eligible(entry,day)).is_false()
		state.known_discoveries.append("external_thread_cutting");assert_bool(discovery._discovery_is_eligible(entry,day)).is_true()
		state.known_discoveries.erase("external_thread_cutting");state.known_discoveries.append("bolt_thread_rolling")
		assert_bool(discovery._discovery_is_eligible(entry,day)).is_true()
		state.known_discoveries.erase("thread_pitch_gauging");assert_bool(discovery._discovery_is_eligible(entry,day)).is_false()
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),discovery.technology_catalog)).is_empty()
	)

func test_missing_components_and_unknown_methods_never_create_fasteners()->void:
	WorldSimulation.scoped("fasteners",func()->void:
		setup();var state=WorldSimulation.state
		var before:Dictionary=state.resource_stockpiles.duplicate(true)
		assert_bool(WorldSimulation.military.start_production_line("machine_fastener_sets",1).has("error")).is_true()
		assert_dict(state.resource_stockpiles).is_equal(before)
		state.known_discoveries.erase("bolt_blank_forging")
		assert_bool(WorldSimulation.military.start_production_line("bolt_blanks",1).has("error")).is_true()
		assert_dict(state.resource_stockpiles).is_equal(before)
	)

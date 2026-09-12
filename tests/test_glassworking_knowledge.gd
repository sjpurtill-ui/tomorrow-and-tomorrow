extends GdUnitTestSuite
const K=preload("res://scripts/glassworking_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("glassworker",995)
func after_test()->void:WorldSimulation.clear()
func prepare(item:String)->Dictionary:
	var r:=I.product(item);var state=WorldSimulation.state
	state.known_discoveries.append(r.gate);state.discovery_adoption[r.gate]=1.0
	for material:String in r.materials:state.resource_stockpiles[material]=20.0
	for material:String in r.tooling:state.resource_stockpiles[material]=20.0
	assert_bool(WorldSimulation.military.start_production_line(item,1).get("ok",false)).is_true()
	return WorldSimulation.military.equipment_queue.back()
func test_six_distinct_contracts_and_paid_vessel_methods()->void:
	WorldSimulation.scoped("glassworker",func()->void:
		assert_int(K.entries().size()).is_equal(6)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		for item:String in ["core_glass_vessels","blown_glass_vessels","mold_glass_vessels","pressed_glass_vessels"]:
			WorldSimulation.state.resource_stockpiles["Glass Vessels"]=0.0
			var job:=prepare(item);var r:=I.product(item)
			var glass:=float(WorldSimulation.state.resource_stockpiles.Glass)
			P.advance(WorldSimulation.military,job,float(r.days))
			assert_float(float(WorldSimulation.state.resource_stockpiles["Glass Vessels"])).is_equal(1.0)
			assert_float(float(WorldSimulation.state.resource_stockpiles.Glass)).is_equal_approx(glass-float(r.materials.Glass),.000001)
			assert_bool(WorldSimulation.military.cancel_equipment_job(int(job.id)).get("cancelled",false)).is_true()
	)
func test_drawn_tubes_and_real_hydrogen_are_consumed_by_apparatus_work()->void:
	WorldSimulation.scoped("glassworker",func()->void:
		var tube:=prepare("drawn_glass_tubes")
		P.advance(WorldSimulation.military,tube,3.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Glass Tubes"])).is_equal(1.0)
		assert_bool(WorldSimulation.military.cancel_equipment_job(int(tube.id)).get("cancelled",false)).is_true()
		var r:=I.product("hydrogen_worked_glassware");var state=WorldSimulation.state
		state.known_discoveries.append(r.gate);state.discovery_adoption[r.gate]=1.0
		state.resource_stockpiles["Glass Vessels"]=.5;state.resource_stockpiles.Hydrogen=.2
		for material:String in r.tooling:state.resource_stockpiles[material]=20.0
		assert_bool(WorldSimulation.military.start_production_line("hydrogen_worked_glassware",1).get("ok",false)).is_true()
		var job:Dictionary=WorldSimulation.military.equipment_queue.back()
		state.resource_stockpiles.Hydrogen=0.0
		var before:Dictionary=state.resource_stockpiles.duplicate(true)
		P.advance(WorldSimulation.military,job,3.0)
		assert_dict(state.resource_stockpiles).is_equal(before)
		state.resource_stockpiles.Hydrogen=.2
		P.advance(WorldSimulation.military,job,3.0)
		assert_float(float(state.resource_stockpiles["Laboratory Glassware"])).is_equal(1.0)
		assert_float(float(state.resource_stockpiles["Glass Tubes"])).is_equal(0.0)
		assert_float(float(state.resource_stockpiles.Hydrogen)).is_equal(0.0)
	)
func test_prepared_vessels_are_paid_once_as_brine_line_tooling()->void:
	WorldSimulation.scoped("glassworker",func()->void:
		var state=WorldSimulation.state
		state.known_discoveries.append("brine_purification");state.discovery_adoption.brine_purification=1.0
		state.resource_stockpiles.merge({"Glass Vessels":2.0,"Clay":2.0,"Salt":2.0,"Freshwater":6.0},true)
		assert_bool(WorldSimulation.military.start_production_line("vessel_purified_brine",2).get("ok",false)).is_true()
		var job:Dictionary=WorldSimulation.military.equipment_queue.back()
		assert_float(float(state.resource_stockpiles["Glass Vessels"])).is_equal(0.0)
		P.advance(WorldSimulation.military,job,2.5);P.advance(WorldSimulation.military,job,2.5)
		assert_float(float(state.resource_stockpiles["Purified Brine"])).is_equal(2.0)
		assert_float(float(state.resource_stockpiles["Glass Vessels"])).is_equal(0.0)
		assert_float(float(state.resource_stockpiles.Salt)).is_equal(0.0)
	)
func test_apparatus_silicon_route_needs_its_own_knowledge_and_shared_power()->void:
	WorldSimulation.scoped("glassworker",func()->void:
		var state=WorldSimulation.state
		state.known_discoveries.append("hydrogen_flame_glassworking");state.discovery_adoption.hydrogen_flame_glassworking=1.0
		assert_bool(P.recipe(WorldSimulation.military,"apparatus_refined_silicon").has("error")).is_true()
		var job:=prepare("apparatus_refined_silicon");var before:Dictionary=state.resource_stockpiles.duplicate(true)
		P.advance(WorldSimulation.military,job,10.0)
		assert_dict(state.resource_stockpiles).is_equal(before)
		state.technology_operations.last_day=int(state.elapsed_days);state.technology_operations.services.electricity=1.5
		P.advance(WorldSimulation.military,job,5.0)
		var saved:Dictionary=JSON.parse_string(JSON.stringify(job))
		assert_str(P.validate_saved({"equipment_queue":[saved]})).is_empty()
		state.technology_operations.services.electricity=1.5
		P.advance(WorldSimulation.military,saved,5.0);P.advance(WorldSimulation.military,saved,5.0)
		assert_float(float(state.resource_stockpiles["Purified Silicon"])).is_equal(1.0)
		assert_float(float(state.technology_operations.services.electricity)).is_equal(0.0)
	)

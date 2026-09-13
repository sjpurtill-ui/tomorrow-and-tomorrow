extends GdUnitTestSuite
const K=preload("res://scripts/metal_process_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const Ops=preload("res://scripts/technology_operations.gd")
const ITEMS=["annealed_copper","annealed_copper_wire","case_hardened_gears","fed_copper_castings","brazed_steel_fittings","cast_fitted_vessels","arc_welded_panels","welded_pressure_vessels","spot_welded_panels","metal_cart_beds","continuous_steel_slabs","slab_rolled_sheets"]
const INTERMEDIATES=["Annealed Copper","Cast Copper Housings","Brazed Steel Fittings","Arc-Welded Panels","Spot-Welded Panels","Steel Slabs"]
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("metal",120)
func after_test()->void:WorldSimulation.clear()
func learn(id:String)->void:
	if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
	WorldSimulation.state.discovery_adoption[id]=1.0
func prepare()->void:
	var s=WorldSimulation.state;s.settlement_site_committed=true;s.convoy_traveling=false
	s.population_allocations.Crafting=100;s.population_allocations.Logistics=100;s.population_health=1.0;s.simulation_metrics.labor_efficiency=1.0
	for e:Dictionary in K.entries():
		learn(e.id)
		for id:String in e.requires_all:learn(id)
		for group:Array in e.requires_any:learn(group[0])
	for item:String in ITEMS:
		var spec:=I.product(item);learn(spec.gate)
		for resource:String in spec.materials.keys()+spec.tooling.keys():
			if resource not in INTERMEDIATES:s.resource_stockpiles[resource]=1000.0
func make(item:String,target:int)->void:
	var started:=WorldSimulation.military.start_production_line(item,target)
	assert_bool(started.get("ok",false)).override_failure_message(str(started)).is_true()
	if not started.get("ok",false):return
	var job:Dictionary=WorldSimulation.military.equipment_queue.back()
	if float(I.product(item).get("power",0))>0:
		WorldSimulation.state.elapsed_days+=1;Ops.advance(int(WorldSimulation.state.elapsed_days))
	P.advance(WorldSimulation.military,job,1000)
	assert_int(int(job.completed)).is_greater(0)
	WorldSimulation.military.cancel_equipment_job(int(job.id))
func generator()->void:
	var spec:Dictionary=Ops.PLANTS.steam_generator;learn(spec.gate)
	for id:String in spec.requires:learn(id)
	for resource:String in spec.cost:
		if resource!="Pressure Vessels":WorldSimulation.state.resource_stockpiles[resource]=100.0
	WorldSimulation.state.resource_stockpiles.Coal=100.0;WorldSimulation.state.resource_stockpiles.Freshwater=100.0
	assert_bool(Ops.install("steam_generator").get("ok",false)).is_true()
	for day in range(1,16):WorldSimulation.state.elapsed_days=day;Ops.advance(day)
	assert_float(Ops.service("electricity")).is_greater(0.0)
func test_seven_methods_keep_distinct_paid_operating_recipes()->void:
	WorldSimulation.scoped("metal",func()->void:
		assert_int(K.entries().size()).is_equal(7)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		for item:String in ITEMS:assert_bool(I.product(item).is_empty()).is_false()
		assert_float(float(I.product("arc_welded_panels").power)).is_greater(0.0)
		assert_bool(I.product("spot_welded_panels").materials.has("Steel Wire")).is_false()
	)
func test_cast_brazed_parts_commission_actual_fuel_consuming_generator()->void:
	WorldSimulation.scoped("metal",func()->void:
		prepare();var copper:=float(WorldSimulation.state.resource_stockpiles["Refined Copper"])
		make("fed_copper_castings",1);make("brazed_steel_fittings",2);make("cast_fitted_vessels",1)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Refined Copper"])).is_less(copper)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Cast Copper Housings"])).is_equal(0.0)
		assert_bool(WorldSimulation.military.start_production_line("arc_welded_panels",1).get("ok",false)).is_true()
		generator();P.advance(WorldSimulation.military,WorldSimulation.military.equipment_queue.back(),100)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Arc-Welded Panels"])).is_equal(1.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Pressure Vessels"])).is_equal(0.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles.Coal)).is_less(100.0)
	)
func test_annealed_wire_and_carburized_gears_feed_existing_equipment()->void:
	WorldSimulation.scoped("metal",func()->void:
		prepare();WorldSimulation.state.resource_stockpiles["Copper Wire"]=0.0;WorldSimulation.state.resource_stockpiles["Gear Sets"]=0.0
		make("annealed_copper",3);make("annealed_copper_wire",3);make("case_hardened_gears",1)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Annealed Copper"])).is_equal(0.0)
		learn("electric_motors");WorldSimulation.state.resource_stockpiles["Basic Machine Tool Sets"]=1.0;WorldSimulation.state.resource_stockpiles["Insulated Cable"]=2.0
		make("electric_motor",1);assert_float(float(WorldSimulation.state.resource_stockpiles["Copper Wire"])).is_equal(0.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Electric Motors"])).is_equal(1.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Gear Sets"])).is_equal(1.0)
	)
func test_welding_and_casting_wait_for_shared_power_and_consume_it_once()->void:
	WorldSimulation.scoped("metal",func()->void:
		prepare();WorldSimulation.state.resource_stockpiles["Pressure Vessels"]=1.0
		var start:=WorldSimulation.military.start_production_line("arc_welded_panels",2);assert_bool(start.get("ok",false)).is_true()
		var job:Dictionary=WorldSimulation.military.equipment_queue.back();var stock:=WorldSimulation.state.resource_stockpiles.duplicate(true)
		P.advance(WorldSimulation.military,job,100);assert_float(float(job.progress_days)).is_equal(0.0);assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(stock)
		generator();var electricity:=Ops.service("electricity");P.advance(WorldSimulation.military,job,100)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Arc-Welded Panels"])).is_equal(1.0)
		assert_float(Ops.service("electricity")).is_equal_approx(electricity-2.0,.000001)
		P.advance(WorldSimulation.military,job,100);assert_int(int(job.completed)).is_equal(1)
		WorldSimulation.state.elapsed_days=16;Ops.advance(16);P.advance(WorldSimulation.military,job,100)
		assert_int(int(job.completed)).is_equal(2);WorldSimulation.military.cancel_equipment_job(int(job.id))
		make("spot_welded_panels",1);make("continuous_steel_slabs",1)
		assert_float(Ops.service("electricity")).is_equal_approx(0.0,.000001)
		WorldSimulation.state.resource_stockpiles["Cart Beds"]=0.0;make("metal_cart_beds",1)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Spot-Welded Panels"])).is_equal(0.0)
		WorldSimulation.state.resource_stockpiles["Steel Sheets"]=0.0;make("slab_rolled_sheets",1)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Steel Slabs"])).is_equal(0.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Steel Sheets"])).is_equal(1.0)
	)
func test_missing_parts_preserve_tooling_and_partial_work_roundtrips()->void:
	WorldSimulation.scoped("metal",func()->void:
		prepare();var stock:=WorldSimulation.state.resource_stockpiles.duplicate(true)
		assert_bool(WorldSimulation.military.start_production_line("cast_fitted_vessels",1).has("error")).is_true();assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(stock)
		assert_bool(WorldSimulation.military.start_production_line("annealed_copper",1).get("ok",false)).is_true()
		var job:Dictionary=WorldSimulation.military.equipment_queue.back();P.advance(WorldSimulation.military,job,1)
		assert_float(float(WorldSimulation.state.resource_stockpiles.get("Annealed Copper",0))).is_equal(0.0)
		var saved:Dictionary=bytes_to_var(var_to_bytes(job));assert_str(P.validate_saved({"equipment_queue":[saved]})).is_empty()
		P.advance(WorldSimulation.military,saved,1);P.advance(WorldSimulation.military,saved,100)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Annealed Copper"])).is_equal(1.0)
	)
func test_imported_welded_parts_make_vessels_without_welding_mastery()->void:
	WorldSimulation.scoped("metal",func()->void:
		prepare();WorldSimulation.state.known_discoveries.erase("arc_welding_processes")
		WorldSimulation.state.resource_stockpiles["Arc-Welded Panels"]=1.0;WorldSimulation.state.resource_stockpiles["Brazed Steel Fittings"]=.5
		make("welded_pressure_vessels",1)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Pressure Vessels"])).is_equal(1.0)
		assert_bool("arc_welding_processes" in WorldSimulation.state.known_discoveries).is_false()
	)

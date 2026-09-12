extends GdUnitTestSuite
const K=preload("res://scripts/fastener_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const Supply=preload("res://scripts/civilian_production_planner.gd")
const C=preload("res://scripts/civilization_controller.gd")

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

func manufacture(resource:String,target:int,made:Dictionary)->void:
	var host=WorldSimulation.military
	for step in 600:
		if float(WorldSimulation.state.resource_stockpiles.get(resource,0))>=target:return
		var order:=Supply.supply(resource,target,{})
		assert_dict(order).is_not_empty()
		if order.is_empty():return
		C.production_order("fasteners",order)
		var changed:=false
		for job:Dictionary in host.equipment_queue:
			if String(job.item)!=String(order.item):continue
			var prior:=int(job.completed)
			P.advance(host,job,float(job.work_per_item)*float(order.target))
			changed=int(job.completed)>prior
			if changed:made[job.item]=true
		assert_bool(changed).is_true()
		if not changed:return
	assert_float(float(WorldSimulation.state.resource_stockpiles.get(resource,0))).is_greater_equal(target)

func test_all_joint_practices_feed_paid_motor_and_pressure_vessel_assembly()->void:
	WorldSimulation.scoped("fasteners",func()->void:
		setup();var state=WorldSimulation.state;var made:Dictionary={}
		var initial:=float(state.resource_stockpiles["Wrought Iron"])
		for entry:Dictionary in K.entries():manufacture(String(I.PRODUCTS[entry.production_items[0]].output),1,made)
		for entry:Dictionary in K.entries():
			var exercised:=false
			for item:String in entry.production_items:exercised=exercised or made.has(item)
			assert_bool(exercised).is_true()
		for item:String in ["fastened_electric_motors","riveted_pressure_vessels"]:
			var recipe:Dictionary=I.PRODUCTS[item]
			for resource:String in recipe.materials:
				if float(state.resource_stockpiles.get(resource,0))<float(recipe.materials[resource]):manufacture(resource,ceili(float(recipe.materials[resource])),made)
			var target:=int(state.resource_stockpiles.get(recipe.output,0))+1
			C.production_order("fasteners",{"item":item,"target":target})
			var job:Dictionary=WorldSimulation.military.equipment_queue[0]
			assert_str(String(job.item)).is_equal(item)
			P.advance(WorldSimulation.military,job,float(recipe.days))
			assert_float(float(state.resource_stockpiles[recipe.output])).is_equal(float(target))
		assert_float(float(state.resource_stockpiles["Wrought Iron"])).is_less(initial)
		assert_float(preload("res://scripts/technology_operations.gd").service("mechanical_work")).is_equal(0.0)
	)

func test_thread_methods_reconverge_but_keep_shared_measurement_and_nut_foundations()->void:
	WorldSimulation.scoped("fasteners",func()->void:
		setup();var state=WorldSimulation.state;var discovery=WorldSimulation.discovery
		var entry:=discovery.discovery_definition("matched_thread_inspection")
		state.known_discoveries.erase("matched_thread_inspection")
		state.known_discoveries.erase("external_thread_cutting");state.known_discoveries.erase("bolt_thread_rolling")
		assert_bool(discovery._discovery_is_eligible(entry,0)).is_false()
		state.known_discoveries.append("external_thread_cutting");assert_bool(discovery._discovery_is_eligible(entry,0)).is_true()
		state.known_discoveries.erase("external_thread_cutting");state.known_discoveries.append("bolt_thread_rolling")
		assert_bool(discovery._discovery_is_eligible(entry,0)).is_true()
		state.known_discoveries.erase("thread_pitch_gauging");assert_bool(discovery._discovery_is_eligible(entry,0)).is_false()
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

func test_fractional_rivet_work_survives_json_and_reuses_paid_tooling()->void:
	WorldSimulation.scoped("fasteners",func()->void:
		setup();var state=WorldSimulation.state;var host=WorldSimulation.military
		var before:=float(state.resource_stockpiles["Wrought Iron"])
		assert_bool(host.start_production_line("rivet_blanks",2).get("ok",false)).is_true()
		P.advance(host,host.equipment_queue[0],1.0)
		var restored:Dictionary=JSON.parse_string(JSON.stringify(host.equipment_queue[0]))
		assert_float(float(restored.progress_days)).is_equal(1.0)
		assert_float(float(state.resource_stockpiles.get("Rivet Blanks",0))).is_equal(0.0)
		P.advance(host,restored,3.0)
		assert_float(float(state.resource_stockpiles["Rivet Blanks"])).is_equal(2.0)
		assert_float(absf(float(state.resource_stockpiles["Wrought Iron"])-(before-1.8))).is_less(.000001)
		assert_float(float(P.installed_tooling(restored)["Wrought Iron"])).is_equal(1.0)
	)

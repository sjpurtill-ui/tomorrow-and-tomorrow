extends GdUnitTestSuite
const K=preload("res://scripts/machine_tool_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const Ops=preload("res://scripts/technology_operations.gd")
const Supply=preload("res://scripts/civilian_production_planner.gd")
const Controller=preload("res://scripts/civilization_controller.gd")

func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("machinist",1030)

func after_test()->void:WorldSimulation.clear()

func setup()->void:
	var state=WorldSimulation.state
	state.settlement_site_committed=true;state.convoy_traveling=false
	state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0
	state.population_allocations.Crafting=40;state.population_allocations.Logistics=12
	state.resource_stockpiles.clear()
	for resource:String in ["Timber","Stone","Clay","Wrought Iron","Steel","Refined Copper","Charcoal","Fine Sand","Freshwater","Shaft Bearings","Gear Sets","Optical Lenses"]:state.resource_stockpiles[resource]=100000.0
	for entry:Dictionary in WorldSimulation.discovery.technology_catalog:
		if entry.id not in state.known_discoveries:state.known_discoveries.append(entry.id)
		state.discovery_adoption[entry.id]=1.0

func manufacture(resource:String,target:int)->Dictionary:
	var host=WorldSimulation.military;var made:Dictionary={}
	for step in 1200:
		if float(WorldSimulation.state.resource_stockpiles.get(resource,0))>=target:break
		var order:=Supply.supply(resource,target,{})
		assert_dict(order).is_not_empty()
		if order.is_empty():break
		Controller.production_order("machinist",order)
		var progressed:=false
		for job:Dictionary in host.equipment_queue:
			if String(job.item)!=String(order.item):continue
			var prior:=int(job.completed)
			P.advance(host,job,float(job.work_per_item)*float(order.target))
			progressed=int(job.completed)>prior
			if progressed:made[job.item]=true
		assert_bool(progressed).is_true()
		if not progressed:break
	return made

func test_precision_toolroom_is_manufactured_before_it_can_operate()->void:
	WorldSimulation.scoped("machinist",func()->void:
		setup();var state=WorldSimulation.state
		var iron:=float(state.resource_stockpiles["Wrought Iron"])
		var made:=manufacture("Precision Machine Tool Sets",1)
		assert_float(float(state.resource_stockpiles.get("Precision Machine Tool Sets",0))).is_equal(1.0)
		assert_int(made.size()).is_equal(24)
		if float(state.resource_stockpiles.get("Precision Machine Tool Sets",0))<1:return
		assert_float(float(state.resource_stockpiles["Wrought Iron"])).is_less(iron)
		assert_float(Ops.service("mechanical_work")).is_equal(0.0)
		# Other installed-workshop inputs are explicit upstream fixtures.
		for resource:String in ["Programmable Controllers","Electric Motors","Insulated Cable"]:state.resource_stockpiles[resource]=10.0
		assert_bool(Ops.install("programmable_workshop").get("ok",false)).is_true()
		assert_float(float(state.resource_stockpiles["Precision Machine Tool Sets"])).is_equal(0.0)
		for day in range(1,12):state.elapsed_days=day;Ops.advance(day)
		assert_int(int(Ops.data().plants.programmable_workshop.installed)).is_equal(1)
		assert_float(Ops.service("mechanical_work")).is_equal(0.0)
		Ops.data().plants.solar_array={"installed":1,"building":0,"work":0.0,"enabled":true}
		state.elapsed_days=12;Ops.advance(12)
		assert_float(Ops.service("mechanical_work")).is_equal(6.0)
		assert_float(float(Ops.data().workers)).is_greater(0.0)
		assert_bool(Ops.valid(JSON.parse_string(JSON.stringify(Ops.data())))).is_true()
	)

func test_motor_manufacture_bootstraps_without_electricity_and_pays_tools_once()->void:
	WorldSimulation.scoped("machinist",func()->void:
		setup();var state=WorldSimulation.state;var host=WorldSimulation.military
		state.resource_stockpiles["Copper Wire"]=6.0;state.resource_stockpiles["Insulated Cable"]=4.0
		assert_array(P.startup_blockers(host,"electric_motor")).is_not_empty()
		var made:=manufacture("Basic Machine Tool Sets",1)
		assert_int(made.size()).is_greater_equal(14)
		assert_float(float(state.resource_stockpiles.get("Basic Machine Tool Sets",0))).is_equal(1.0)
		Controller.production_order("machinist",{"item":"electric_motor","target":2})
		var job:Dictionary={}
		for candidate:Dictionary in host.equipment_queue:
			if candidate.item=="electric_motor":job=candidate
		assert_dict(job).is_not_empty()
		if job.is_empty():return
		assert_float(float(state.resource_stockpiles["Basic Machine Tool Sets"])).is_equal(0.0)
		P.advance(host,job,12.0);P.advance(host,job,12.0)
		assert_float(float(state.resource_stockpiles["Electric Motors"])).is_equal(2.0)
		assert_float(float(state.resource_stockpiles["Copper Wire"])).is_equal(0.0)
		assert_float(Ops.service("electricity")).is_equal(0.0)
	)

func test_all_four_workshop_installations_require_their_physical_tool_sets()->void:
	WorldSimulation.scoped("machinist",func()->void:
		setup();var state=WorldSimulation.state
		for id:String in ["powered_workshop","controlled_workshop","sequenced_workshop","programmable_workshop"]:
			var kit:="Basic Machine Tool Sets" if id=="powered_workshop" else "Precision Machine Tool Sets"
			for resource:String in Ops.PLANTS[id].cost:
				state.resource_stockpiles[resource]=0.0 if resource==kit else float(Ops.PLANTS[id].cost[resource])
			var before:Dictionary=state.resource_stockpiles.duplicate(true)
			assert_bool(Ops.install(id).has("error")).is_true()
			assert_dict(state.resource_stockpiles).is_equal(before)
			state.resource_stockpiles[kit]=1.0
			assert_bool(Ops.install(id).get("ok",false)).is_true()
			assert_float(float(state.resource_stockpiles[kit])).is_equal(0.0)
		assert_float(Ops.service("mechanical_work")).is_equal(0.0)
	)

func test_missing_reference_tools_or_unknown_practice_prevents_scraping()->void:
	WorldSimulation.scoped("machinist",func()->void:
		setup();var state=WorldSimulation.state;var host=WorldSimulation.military
		assert_array(P.startup_blockers(host,"scraped_machine_ways")).is_not_empty()
		state.resource_stockpiles["Surface Plates"]=1.0;state.resource_stockpiles["Machinist Straightedges"]=1.0
		state.known_discoveries.erase("machine_way_scraping");state.discovery_adoption.erase("machine_way_scraping")
		var before:Dictionary=state.resource_stockpiles.duplicate(true)
		assert_bool(host.start_production_line("scraped_machine_ways",1).has("error")).is_true()
		assert_dict(state.resource_stockpiles).is_equal(before)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
	)

func test_fractional_machine_parts_survive_serialization_without_repaying_tooling()->void:
	WorldSimulation.scoped("machinist",func()->void:
		setup();var state=WorldSimulation.state;var host=WorldSimulation.military
		assert_bool(host.start_production_line("surface_plates",1).get("ok",false)).is_true()
		var job:Dictionary=host.equipment_queue.back();P.advance(host,job,2.5)
		var stone:=float(state.resource_stockpiles.Stone)
		var payload:Dictionary=JSON.parse_string(JSON.stringify({"equipment_queue":host.equipment_queue}))
		assert_str(P.validate_saved(payload)).is_empty()
		P.advance(host,payload.equipment_queue[0],2.5)
		assert_float(float(state.resource_stockpiles.Stone)).is_equal(stone-1.5)
		assert_float(float(state.resource_stockpiles["Surface Plates"])).is_equal(1.0)
	)

func test_retooling_retains_paid_tools_but_never_uses_them_as_batch_inputs()->void:
	WorldSimulation.scoped("machinist",func()->void:
		setup();var state=WorldSimulation.state;var host=WorldSimulation.military
		state.resource_stockpiles.Stone=20.0;state.resource_stockpiles.Limestone=10.0
		assert_bool(host.start_production_line("surface_plates",1).get("ok",false)).is_true()
		var job:Dictionary=host.equipment_queue.back();P.advance(host,job,5.0)
		assert_float(float(state.resource_stockpiles.Stone)).is_equal(11.0)
		assert_bool(host.retool_production_line(int(job.id),"glass_batch").get("ok",false)).is_true()
		assert_float(float(state.resource_stockpiles.Stone)).is_equal(5.0)
		assert_float(float(job.installed_tooling.Stone)).is_equal(12.0)
		assert_bool(host.retool_production_line(int(job.id),"surface_plates").get("ok",false)).is_true()
		assert_float(float(state.resource_stockpiles.Stone)).is_equal(5.0)
		P.advance(host,job,5.0)
		# Existing stock target is already met; consume a reference plate to
		# demonstrate the replenishment batch still pays its own raw stone.
		state.resource_stockpiles["Surface Plates"]=0.0;P.advance(host,job,5.0)
		assert_float(float(state.resource_stockpiles.Stone)).is_equal(2.0)
		assert_float(float(job.installed_tooling.Stone)).is_equal(12.0)
		assert_array(P.startup_blockers(host,"surface_plates",P.installed_tooling(job))).is_not_empty()
		assert_array(P.startup_blockers(host,"glass_batch")).is_not_empty()
	)

func test_retained_tooling_survives_save_and_rejects_invalid_quantities()->void:
	WorldSimulation.scoped("machinist",func()->void:
		setup();var host=WorldSimulation.military
		assert_bool(host.start_production_line("surface_plates",1).get("ok",false)).is_true()
		var job:Dictionary=host.equipment_queue.back()
		var payload:Dictionary=JSON.parse_string(JSON.stringify({"equipment_queue":host.equipment_queue}))
		assert_str(P.validate_saved(payload)).is_empty()
		assert_dict(P.installed_tooling(payload.equipment_queue[0])).is_equal({"Stone":6.0})
		payload.equipment_queue[0].installed_tooling.Stone=-1.0
		assert_str(P.validate_saved(payload)).is_not_empty()
		payload.equipment_queue[0].installed_tooling={"imaginary_tool":1.0}
		assert_str(P.validate_saved(payload)).is_not_empty()
		payload.equipment_queue[0].installed_tooling={"Stone":NAN}
		assert_str(P.validate_saved(payload)).is_not_empty()
		job.erase("installed_tooling")
		assert_dict(P.installed_tooling(job)).is_equal({"Stone":6.0})
		assert_str(P.validate_saved({"equipment_queue":host.equipment_queue})).is_empty()
	)

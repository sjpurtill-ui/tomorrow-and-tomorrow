extends GdUnitTestSuite
const K=preload("res://scripts/cartwright_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const Planner=preload("res://scripts/cart_supply_planner.gd")
const Controller=preload("res://scripts/civilization_controller.gd")

func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("carter",1012)

func after_test()->void:WorldSimulation.clear()

func setup()->void:
	var state=WorldSimulation.state;var host=WorldSimulation.military
	state.initialize_population_model();state.ensure_population_total(400)
	state.settlement_site_committed=true;state.convoy_traveling=false
	state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0
	state.population_allocations.Crafting=40;state.population_allocations.Logistics=8
	state.resource_stockpiles.clear()
	for resource:String in ["Timber","Stone","Wrought Iron","Charcoal","Woven Cloth","Rope Coils","Treenails"]:state.resource_stockpiles[resource]=20000.0
	for entry:Dictionary in WorldSimulation.discovery.technology_catalog:
		if entry.id not in state.known_discoveries:state.known_discoveries.append(entry.id)
		state.discovery_adoption[entry.id]=1.0
	host.home_army.troops=48

func forget(id:String)->void:
	WorldSimulation.state.known_discoveries.erase(id);WorldSimulation.state.discovery_adoption.erase(id)

func test_recursive_orders_build_carts_that_increase_staffed_delivery_capacity()->void:
	WorldSimulation.scoped("carter",func()->void:
		setup();var host=WorldSimulation.military;var state=WorldSimulation.state
		var before:=host._daily_delivery_capacity();var provision:=host._field_transport_delivery_ratio()
		var timber:=float(state.resource_stockpiles.Timber);var made:Dictionary={}
		for step in 100:
			var order:=Planner.recommendation()
			if order.is_empty():break
			Controller.production_order("carter",order)
			var progressed:=false
			for job:Dictionary in host.equipment_queue:
				if String(job.item)!=String(order.item):continue
				var prior:=int(job.completed)
				P.advance(host,job,float(job.work_per_item)*float(order.target))
				progressed=int(job.completed)>prior
				if progressed:made[job.item]=true
			assert_bool(progressed).is_true()
		assert_float(float(state.resource_stockpiles.get("Transport Carts",0))).is_equal(2.0)
		assert_int(made.size()).is_greater_equal(10)
		assert_float(float(state.resource_stockpiles.Timber)).is_less(timber)
		assert_float(host._daily_delivery_capacity()).is_greater(before)
		assert_float(host._field_transport_delivery_ratio()).is_greater(provision)
		assert_dict(Planner.recommendation()).is_empty()
		state.population_allocations.Logistics=0
		assert_float(host._daily_delivery_capacity()).is_equal(0.0)
		assert_dict(Planner.recommendation()).is_empty()
	)

func test_running_gear_reconverges_after_either_wheel_method()->void:
	WorldSimulation.scoped("carter",func()->void:
		setup();var discovery=WorldSimulation.discovery
		var entry:=discovery.discovery_definition("cart_running_gear")
		forget("solid_wheel_assembly");forget("spoked_wheel_assembly");forget("cart_running_gear")
		assert_bool(discovery._discovery_is_eligible(entry,0)).is_false()
		WorldSimulation.state.known_discoveries.append("solid_wheel_assembly")
		assert_bool(discovery._discovery_is_eligible(entry,0)).is_true()
		forget("solid_wheel_assembly");WorldSimulation.state.known_discoveries.append("spoked_wheel_assembly")
		assert_bool(discovery._discovery_is_eligible(entry,0)).is_true()
		forget("cart_bed_framing")
		assert_bool(discovery._discovery_is_eligible(entry,0)).is_false()
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),discovery.technology_catalog)).is_empty()
	)

func test_legacy_batch_api_reserves_actual_kits_and_refunds_only_unfinished_work()->void:
	WorldSimulation.scoped("carter",func()->void:
		setup();var host=WorldSimulation.military;var state=WorldSimulation.state
		assert_bool(host.transport_cart_quote(2).has("error")).is_true()
		state.resource_stockpiles["Cart Assembly Kits"]=2.0
		var raw_before:=float(state.resource_stockpiles.Timber)
		var receipt:=host.queue_transport_cart_production(2)
		assert_bool(receipt.has("queued")).is_true()
		assert_float(float(state.resource_stockpiles["Cart Assembly Kits"])).is_equal(0.0)
		assert_float(float(state.resource_stockpiles.Timber)).is_equal(raw_before)
		var job:Dictionary=host.equipment_queue.back()
		assert_dict(job.reserved_materials).is_equal({"Cart Assembly Kits":2.0})
		assert_bool(host.cancel_equipment_job(int(job.id)).has("cancelled")).is_true()
		assert_float(float(state.resource_stockpiles["Cart Assembly Kits"])).is_equal(2.0)
		assert_float(float(state.resource_stockpiles.get("Transport Carts",0))).is_equal(0.0)
	)

func test_planner_blocks_shortages_unknown_methods_pause_and_absent_demand()->void:
	WorldSimulation.scoped("carter",func()->void:
		setup();var state=WorldSimulation.state;var host=WorldSimulation.military
		assert_dict(Planner.recommendation()).is_not_empty()
		state.resource_stockpiles.Timber=0.0
		assert_dict(Planner.recommendation()).is_empty()
		state.resource_stockpiles.Timber=20000.0
		forget("cart_running_gear")
		assert_dict(Planner.recommendation()).is_empty()
		state.known_discoveries.append("cart_running_gear");state.discovery_adoption.cart_running_gear=1.0
		assert_bool(host.start_production_line("bored_wheel_hubs",4).get("ok",false)).is_true()
		host.equipment_queue.back().paused=true
		assert_dict(Planner.recommendation()).is_empty()
		host.equipment_queue.clear();host.home_army.troops=0
		assert_dict(Planner.recommendation()).is_empty()
	)

func test_old_cart_reservations_and_persistent_partial_work_are_preserved()->void:
	WorldSimulation.scoped("carter",func()->void:
		setup();var host=WorldSimulation.military;var state=WorldSimulation.state
		host.equipment_queue.append({"id":1,"job_type":"transport","item":"transport_cart","count":1,"completed":0,"progress_days":0.0,"work_per_item":5.0,"required_days":5.0})
		host._normalize_equipment_jobs()
		assert_dict(host.equipment_queue[0].reserved_materials).is_equal({"Timber":8.0,"Fiber Plants":1.5})
		host.equipment_queue.clear();state.resource_stockpiles["Cart Assembly Kits"]=1.0
		assert_bool(host.start_production_line("transport_cart",1).get("ok",false)).is_true()
		var job:Dictionary=host.equipment_queue.back()
		P.advance(host,job,.5)
		var payload:Dictionary=JSON.parse_string(JSON.stringify({"equipment_queue":host.equipment_queue}))
		assert_str(P.validate_saved(payload)).is_empty()
		P.advance(host,payload.equipment_queue[0],.5)
		assert_float(float(state.resource_stockpiles["Cart Assembly Kits"])).is_equal(0.0)
		assert_float(float(state.resource_stockpiles["Transport Carts"])).is_equal(1.0)
	)

func test_basic_and_sleeved_assemblies_consume_distinct_components()->void:
	WorldSimulation.scoped("carter",func()->void:
		setup();var state=WorldSimulation.state;var host=WorldSimulation.military
		for item:String in ["cart_assembly_kits","sleeved_cart_kits"]:
			var recipe:=I.product(item)
			for resource:String in recipe.materials:state.resource_stockpiles[resource]=float(recipe.materials[resource])+float(recipe.tooling.get(resource,0))
			for resource:String in recipe.tooling:
				if not recipe.materials.has(resource):state.resource_stockpiles[resource]=float(recipe.tooling[resource])
			var target:=int(state.resource_stockpiles.get("Cart Assembly Kits",0))+1
			assert_bool(host.start_production_line(item,target).get("ok",false)).is_true()
			var job:Dictionary=host.equipment_queue.back();P.advance(host,job,float(recipe.days))
			assert_int(int(job.completed)).is_equal(1)
			for resource:String in recipe.materials:assert_float(float(state.resource_stockpiles[resource])).is_equal(0.0)
			host.cancel_equipment_job(int(job.id))
		assert_float(float(state.resource_stockpiles["Cart Assembly Kits"])).is_equal(2.0)
		assert_float(float(I.PRODUCTS.sleeved_cart_kits.days)).is_less(float(I.PRODUCTS.cart_assembly_kits.days))
	)

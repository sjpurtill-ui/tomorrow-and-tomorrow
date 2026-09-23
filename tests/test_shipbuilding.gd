extends GdUnitTestSuite
const K=preload("res://scripts/shipbuilding_knowledge.gd")
const P=preload("res://scripts/persistent_production.gd")
const J=preload("res://scripts/joint_force_catalog.gd")
const Planner=preload("res://scripts/joint_manufacturing_planner.gd")
const Controller=preload("res://scripts/civilization_controller.gd")

func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("shipwright",921)

func after_test()->void:WorldSimulation.clear()

func setup()->void:
	var state=WorldSimulation.state
	state.initialize_population_model();state.ensure_population_total(400)
	state.settlement_site_committed=true;state.convoy_traveling=false
	state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0;state.population_allocations.Crafting=40
	state.settlement_completed.assign(["Hearth Circle"]);WorldSimulation.settlements.ensure_founded()
	for resource:String in ["Timber","Stone","Wrought Iron","Fiber Plants","Woven Cloth","Spun Yarn","Bitumen"]:state.resource_stockpiles[resource]=20000.0
	for entry:Dictionary in WorldSimulation.discovery.technology_catalog:
		if entry.id not in state.known_discoveries:state.known_discoveries.append(entry.id)
		state.discovery_adoption[entry.id]=1.0
	var op=WorldSimulation.military.joint_operations
	# Isolated completed harbor fixture; build-base geography has separate coverage.
	op.state.bases.append({"id":1,"owner":"player","city_id":String(state.player_settlements[0].id),"name":"Test shipyard","domain":"navy","position":{"x":0.0,"z":0.0},"capacity":20,"condition":1.0,"construction_work":30.0,"required_work":30.0})

## Stocks exactly `count` batches of a ship recipe plus its launch tooling;
## hull parts, sails and cradles are paid as raw materials and Civilian Goods.
func stock_recipe(recipe:Dictionary,count:float)->void:
	var stock:Dictionary=WorldSimulation.state.resource_stockpiles
	for resource:String in recipe.materials:stock[resource]=float(recipe.materials[resource])*count
	for resource:String in recipe.tooling:stock[resource]=float(stock.get(resource,0) if recipe.materials.has(resource) else 0.0)+float(recipe.tooling[resource])

func assert_spent(recipe:Dictionary)->void:
	for resource:String in recipe.materials:assert_float(float(WorldSimulation.state.resource_stockpiles[resource])).override_failure_message(resource).is_equal_approx(0.0,.0001)
	for resource:String in recipe.tooling:assert_float(float(WorldSimulation.state.resource_stockpiles[resource])).override_failure_message(resource).is_equal_approx(0.0,.0001)

func test_ship_reaches_inventory_through_planned_paid_work()->void:
	WorldSimulation.scoped("shipwright",func()->void:
		setup();var host=WorldSimulation.military;var state=WorldSimulation.state
		var definition:=P.recipe(host,"convoy_transport_equipment")
		assert_bool(definition.has("error")).is_false()
		assert_bool(definition.materials.has("Launch Cradles") or definition.materials.has("Sail Sets") or definition.tooling.has("Launch Cradles")).is_false()
		assert_float(float(definition.materials.get("Civilian Goods",0))).is_greater(0.0)
		stock_recipe(definition,1.0)
		var plan:=Planner.plan(host,"convoy_transport_equipment")
		assert_bool(bool(plan.get("ready",false))).is_true()
		Controller.production_order("shipwright",{"item":"convoy_transport_equipment","target":1})
		var progressed:=false
		for job:Dictionary in host.equipment_queue:
			if String(job.item)!="convoy_transport_equipment":continue
			P.advance(host,job,float(job.work_per_item));progressed=int(job.completed)>0
		assert_bool(progressed).is_true()
		assert_int(int(host.military_inventory.get("convoy_transport_equipment",0))).is_equal(1)
		assert_spent(definition)
		assert_str(P.validate_saved({"equipment_queue":host.equipment_queue})).is_empty()
		assert_int(host.joint_operations.state.forces.size()).is_equal(0)
		var people:=float(state.population_total)
		var committed:=int(host._mobilized_count())
		assert_bool(host.joint_operations.commission(1,"convoy_transport",1).get("ok",false)).is_true()
		assert_int(int(host.military_inventory.convoy_transport_equipment)).is_equal(0)
		assert_int(host._mobilized_count()-committed).is_equal(12)
		assert_float(float(state.population_total)).is_equal(people)
	)

func test_each_sailing_role_requires_materials_and_paid_launch_tooling()->void:
	WorldSimulation.scoped("shipwright",func()->void:
		setup();var host=WorldSimulation.military;var state=WorldSimulation.state
		for id:String in ["sailing_warship","sailing_frigate","ship_of_line","convoy_transport"]:
			var unit:Dictionary=J.UNITS[id];var recipe:=P.recipe(host,unit.equipment)
			for resource:String in recipe.materials:state.resource_stockpiles[resource]=0.0
			for resource:String in recipe.tooling:state.resource_stockpiles[resource]=0.0
			assert_array(P.startup_blockers(host,unit.equipment)).is_not_empty()
			stock_recipe(recipe,2.0)
			assert_bool(host.start_production_line(unit.equipment,2).get("ok",false)).is_true()
			if host.equipment_queue.is_empty():return
			var job:Dictionary=host.equipment_queue.back()
			P.advance(host,job,float(recipe.work_per_item))
			assert_int(int(host.military_inventory[unit.equipment])).is_equal(1)
			assert_bool(Planner.plan(host,unit.equipment).get("ready",false)).is_true()
			host.military_inventory[unit.equipment]=0
			assert_bool(Planner.plan(host,unit.equipment).get("ready",false)).is_true()
			P.advance(host,job,float(recipe.work_per_item))
			assert_int(int(host.military_inventory[unit.equipment])).is_equal(1)
			assert_spent(recipe)
			host.cancel_equipment_job(int(job.id))
	)

func test_shortages_unknown_methods_and_paused_lines_prevent_orders()->void:
	WorldSimulation.scoped("shipwright",func()->void:
		setup();var host=WorldSimulation.military;var state=WorldSimulation.state
		var definition:=P.recipe(host,"convoy_transport_equipment");stock_recipe(definition,1.0)
		assert_dict(Planner.plan(host,"convoy_transport_equipment")).is_not_empty()
		var goods:=float(state.resource_stockpiles["Civilian Goods"])
		state.resource_stockpiles["Civilian Goods"]=0.0
		assert_dict(Planner.plan(host,"convoy_transport_equipment")).is_empty()
		state.resource_stockpiles["Civilian Goods"]=goods
		var gate:=String(J.UNITS.convoy_transport.gate)
		state.known_discoveries.erase(gate);state.discovery_adoption.erase(gate)
		assert_dict(Planner.plan(host,"convoy_transport_equipment")).is_empty()
		state.known_discoveries.append(gate);state.discovery_adoption[gate]=1.0
		assert_bool(host.start_production_line("convoy_transport_equipment",10).get("ok",false)).is_true()
		if host.equipment_queue.is_empty():return
		host.equipment_queue.back().paused=true
		assert_dict(Planner.plan(host,"convoy_transport_equipment")).is_empty()
	)

func test_shipbuilding_knowledge_matches_technology_catalog()->void:
	WorldSimulation.scoped("shipwright",func()->void:
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
	)

func test_retained_legacy_ship_line_preserves_its_paid_recipe_and_progress()->void:
	WorldSimulation.scoped("shipwright",func()->void:
		setup();var host=WorldSimulation.military;var state=WorldSimulation.state
		var definition:=P.recipe(host,"convoy_transport_equipment")
		stock_recipe(definition,1.0)
		assert_bool(host.start_production_line("convoy_transport_equipment",1).get("ok",false)).is_true()
		if host.equipment_queue.is_empty():return
		state.resource_stockpiles.Timber=20000.0;state.resource_stockpiles["Fiber Plants"]=20000.0
		var job:Dictionary=host.equipment_queue.back()
		job.materials={"Timber":200.0,"Fiber Plants":40.0};job.progress_days=30.0
		var saved:Dictionary=JSON.parse_string(JSON.stringify({"equipment_queue":host.equipment_queue}))
		assert_str(P.validate_saved(saved)).is_empty()
		var restored:Dictionary=saved.equipment_queue[0]
		var timber:=float(state.resource_stockpiles.Timber)
		P.advance(host,restored,30.0)
		assert_float(float(state.resource_stockpiles.Timber)).is_equal(timber-100.0)
		assert_int(int(host.military_inventory.convoy_transport_equipment)).is_equal(1)
	)

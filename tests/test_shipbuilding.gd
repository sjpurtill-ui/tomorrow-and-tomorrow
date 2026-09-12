extends GdUnitTestSuite
const K=preload("res://scripts/shipbuilding_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
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

func test_components_reach_ship_inventory_through_planned_paid_work()->void:
	WorldSimulation.scoped("shipwright",func()->void:
		setup();var host=WorldSimulation.military;var state=WorldSimulation.state
		var start_timber:=float(state.resource_stockpiles.Timber)
		var finished:=false;var components:Dictionary={}
		for step in 100:
			var plan:=Planner.plan(host,"convoy_transport_equipment")
			assert_dict(plan).is_not_empty()
			if plan.is_empty():break
			var order:Dictionary={"item":"convoy_transport_equipment","target":1} if bool(plan.ready) else plan.upstream
			Controller.production_order("shipwright",order)
			var progressed:=false
			for job:Dictionary in host.equipment_queue:
				if String(job.item)!=String(order.item):continue
				var old:=int(job.completed)
				P.advance(host,job,float(job.work_per_item)*float(order.target))
				progressed=int(job.completed)>old
				if progressed:components[String(job.item)]=true
			assert_bool(progressed).is_true()
			if int(host.military_inventory.get("convoy_transport_equipment",0))==1:finished=true;break
		assert_bool(finished).is_true()
		assert_int(components.size()).is_greater_equal(10)
		assert_float(float(state.resource_stockpiles.Timber)).is_less(start_timber)
		assert_float(float(state.resource_stockpiles.get("Launch Cradles",0))).is_equal(0.0)
		assert_float(float(state.resource_stockpiles.get("Sail Sets",0))).is_equal(0.0)
		assert_str(P.validate_saved({"equipment_queue":host.equipment_queue})).is_empty()
		assert_int(host.joint_operations.state.forces.size()).is_equal(0)
		var people:=float(state.population_total)
		var committed:=int(host._mobilized_count())
		assert_bool(host.joint_operations.commission(1,"convoy_transport",1).get("ok",false)).is_true()
		assert_int(int(host.military_inventory.convoy_transport_equipment)).is_equal(0)
		assert_int(host._mobilized_count()-committed).is_equal(12)
		assert_float(float(state.population_total)).is_equal(people)
	)

func test_each_sailing_role_requires_components_and_paid_launch_tooling()->void:
	WorldSimulation.scoped("shipwright",func()->void:
		setup();var host=WorldSimulation.military;var state=WorldSimulation.state
		for id:String in ["sailing_warship","sailing_frigate","ship_of_line","convoy_transport"]:
			var unit:Dictionary=J.UNITS[id];var recipe:=P.recipe(host,unit.equipment)
			assert_array(P.startup_blockers(host,unit.equipment)).is_not_empty()
			for resource:String in recipe.materials:state.resource_stockpiles[resource]=float(recipe.materials[resource])*2.0
			state.resource_stockpiles["Launch Cradles"]=1.0
			assert_bool(host.start_production_line(unit.equipment,2).get("ok",false)).is_true()
			var job:Dictionary=host.equipment_queue.back()
			P.advance(host,job,float(recipe.work_per_item))
			assert_int(int(host.military_inventory[unit.equipment])).is_equal(1)
			assert_bool(Planner.plan(host,unit.equipment).get("ready",false)).is_true()
			host.military_inventory[unit.equipment]=0
			assert_bool(Planner.plan(host,unit.equipment).get("ready",false)).is_true()
			P.advance(host,job,float(recipe.work_per_item))
			assert_int(int(host.military_inventory[unit.equipment])).is_equal(1)
			for resource:String in recipe.materials:assert_float(float(state.resource_stockpiles[resource])).is_equal(0.0)
			assert_float(float(state.resource_stockpiles["Launch Cradles"])).is_equal(0.0)
			host.cancel_equipment_job(int(job.id))
	)

func test_shortages_unknown_methods_and_paused_lines_prevent_orders()->void:
	WorldSimulation.scoped("shipwright",func()->void:
		setup();var host=WorldSimulation.military;var state=WorldSimulation.state
		assert_dict(Planner.plan(host,"convoy_transport_equipment")).is_not_empty()
		state.resource_stockpiles.Timber=0.0
		assert_dict(Planner.plan(host,"convoy_transport_equipment")).is_empty()
		state.resource_stockpiles.Timber=20000.0
		state.known_discoveries.erase("sail_seaming");state.discovery_adoption.erase("sail_seaming")
		assert_dict(Planner.plan(host,"convoy_transport_equipment")).is_empty()
		state.known_discoveries.append("sail_seaming");state.discovery_adoption.sail_seaming=1.0
		assert_bool(host.start_production_line("laid_rope",10).get("ok",false)).is_true()
		host.equipment_queue.back().paused=true
		assert_dict(Planner.plan(host,"convoy_transport_equipment")).is_empty()
	)

func test_alternative_hull_methods_have_different_actual_material_costs()->void:
	WorldSimulation.scoped("shipwright",func()->void:
		setup();var host=WorldSimulation.military;var state=WorldSimulation.state
		for item:String in ["carvel_hull_sections","clinker_hull_sections","heavy_carvel_hull_sections"]:
			var recipe:=I.product(item)
			for resource:String in recipe.materials:state.resource_stockpiles[resource]=float(recipe.materials[resource])+float(recipe.tooling.get(resource,0))
			for resource:String in recipe.tooling:
				if not recipe.materials.has(resource):state.resource_stockpiles[resource]=float(recipe.tooling[resource])
			var target:=int(state.resource_stockpiles.get(String(recipe.output),0))+1
			assert_bool(host.start_production_line(item,target).get("ok",false)).is_true()
			var job:Dictionary=host.equipment_queue.back();P.advance(host,job,float(recipe.days))
			assert_int(int(job.completed)).is_equal(1)
			for resource:String in recipe.materials:assert_float(float(state.resource_stockpiles[resource])).is_equal(0.0)
			host.cancel_equipment_job(int(job.id))
		assert_float(float(state.resource_stockpiles["Hull Sections"])).is_equal(2.0)
		assert_float(float(state.resource_stockpiles["Heavy Hull Sections"])).is_equal(1.0)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
	)

func test_retained_legacy_ship_line_preserves_its_paid_recipe_and_progress()->void:
	WorldSimulation.scoped("shipwright",func()->void:
		setup();var host=WorldSimulation.military;var state=WorldSimulation.state
		var definition:=P.recipe(host,"convoy_transport_equipment")
		for resource:String in definition.materials:state.resource_stockpiles[resource]=float(definition.materials[resource])
		state.resource_stockpiles["Launch Cradles"]=1.0
		assert_bool(host.start_production_line("convoy_transport_equipment",1).get("ok",false)).is_true()
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

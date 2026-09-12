extends GdUnitTestSuite
const B=preload("res://scripts/building_material_operations.gd")
const K=preload("res://scripts/building_material_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("builders",1301)
func after_test()->void:WorldSimulation.clear()
func learn(id:String)->void:
	if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
	WorldSimulation.state.discovery_adoption[id]=1.0
func test_construction_catalog_has_valid_causal_and_production_contracts()->void:
	WorldSimulation.scoped("builders",func()->void:
		assert_int(K.entries().size()).is_equal(22)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
	)
func test_mortar_requires_paid_inputs_and_work()->void:
	WorldSimulation.scoped("builders",func()->void:
		var state=WorldSimulation.state
		for item:String in ["quicklime","slaked_lime","building_mortar"]:
			var spec:=I.product(item);learn(spec.gate)
			for resource:String in spec.materials:
				if resource not in ["Quicklime","Slaked Lime"]:state.resource_stockpiles[resource]=float(spec.materials[resource])
			for resource:String in spec.tooling:state.resource_stockpiles[resource]=float(state.resource_stockpiles.get(resource,0))+float(spec.tooling[resource])
			assert_bool(WorldSimulation.military.start_production_line(item,1).get("ok",false)).is_true()
			var job:Dictionary=WorldSimulation.military.equipment_queue.back()
			P.advance(WorldSimulation.military,job,float(spec.days))
			assert_int(int(job.completed)).is_equal(1)
			WorldSimulation.military.cancel_equipment_job(int(job.id))
		assert_float(float(state.resource_stockpiles["Building Mortar"])).is_equal(1.0)
		assert_float(float(state.resource_stockpiles["Quicklime"])).is_equal(0.0)
		assert_float(float(state.resource_stockpiles["Slaked Lime"])).is_equal(0.0)
	)
func test_curing_needs_elapsed_supplied_intervals_after_building_work()->void:
	WorldSimulation.scoped("builders",func()->void:
		learn("concrete_mix_design");learn("concrete_formwork_systems")
		var profile:Dictionary={}
		for option:Dictionary in B.options():
			if option.building_materials.id=="cast_concrete":profile=option.building_materials
		assert_bool(B.valid(profile)).is_true()
		var plot:={"construction_progress":0.0,"building_materials":profile}
		plot.construction_progress=B.progress(plot,100.0,30)
		assert_float(plot.construction_progress).is_equal(.99)
		WorldSimulation.state.resource_stockpiles.Freshwater=0.0
		assert_float(B.progress(plot,100.0,60)).is_equal(.99)
		assert_float(float(plot.curing_work_days)).is_equal(0.0)
		WorldSimulation.state.resource_stockpiles.Freshwater=2.0
		assert_float(B.progress(plot,100.0,90)).is_equal(.99)
		assert_float(float(plot.curing_work_days)).is_equal(30.0)
		var saved:Dictionary=JSON.parse_string(JSON.stringify(plot))
		assert_float(B.progress(saved,100.0,90)).is_equal(.99)
		assert_float(B.progress(saved,100.0,120)).is_equal(1.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles.Freshwater)).is_equal(0.0)
	)
func test_fabric_requires_compatible_repair_stock_and_does_not_upgrade_old_buildings()->void:
	WorldSimulation.scoped("builders",func()->void:
		learn("lime_mortar")
		var profile:Dictionary=B.options()[0].building_materials
		var plot:={"building_materials":profile}
		WorldSimulation.state.resource_stockpiles["Building Mortar"]=0.0
		assert_float(B.supplied_maintenance(plot,.1)).is_equal(0.0)
		WorldSimulation.state.resource_stockpiles["Building Mortar"]=.1
		assert_float(B.supplied_maintenance(plot,.1)).is_equal_approx(.05,.000001)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Building Mortar"])).is_equal(0.0)
		assert_float(B.decay_factor({})).is_equal(1.0)
		assert_float(B.decay_factor(plot)).is_equal(.75)
	)

func test_rival_workshops_prepare_paid_mortar_chain_for_housing_demand()->void:
	WorldSimulation.scoped("builders",func()->void:
		var state=WorldSimulation.state
		state.settlement_site_committed=true;state.convoy_traveling=false
		state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0
		state.population_allocations.Construction=10;state.population_allocations.Crafting=10
		learn("lime_mortar");learn("lime_burning")
		for material:String in ["Limestone","Timber","Clay","Stone","Fine Sand","Freshwater"]:state.resource_stockpiles[material]=20.0
		state.resource_stockpiles["Quicklime"]=0.0;state.resource_stockpiles["Slaked Lime"]=0.0;state.resource_stockpiles["Building Mortar"]=0.0
		var planner=preload("res://scripts/building_material_investment.gd")
		var order:Dictionary=planner.recommendation()
		assert_str(order.get("item","")).is_equal("quicklime")
		var stone:float=state.resource_stockpiles.Stone
		preload("res://scripts/civilization_controller.gd").civilian_orders("builders",{})
		assert_int(WorldSimulation.military.equipment_queue.size()).is_equal(1)
		assert_str(WorldSimulation.military.equipment_queue[0].item).is_equal("quicklime")
		assert_float(float(state.resource_stockpiles.Stone)).is_less(stone)
	)
func test_new_fabric_cannot_skip_curing_through_instant_household_infill()->void:
	WorldSimulation.scoped("builders",func()->void:
		learn("lime_mortar")
		var recipe:Dictionary=B.options()[0]
		var events:Array[Dictionary]=[]
		assert_bool(WorldSimulation.settlements._attempt_household_infill(30,recipe,events,0)).is_false()
		assert_array(events).is_empty()
	)

func test_invalid_curing_state_is_rejected_in_secondary_cities()->void:
	WorldSimulation.scoped("builders",func()->void:
		learn("lime_mortar")
		var plot:={"building_materials":B.options()[0].building_materials,"curing_started_day":30,"curing_last_day":60,"curing_work_days":0.0}
		var state:={"player_settlements":[{"local_resources":{"settlement_plots":[plot]}}]}
		assert_bool(B.valid_state(state)).is_true()
		plot.curing_work_days=INF;assert_bool(B.valid_state(state)).is_false()
		plot.curing_work_days=31.0;assert_bool(B.valid_state(state)).is_false()
		assert_bool(B.valid_state({})).is_true()
		assert_bool(B.valid_plot({"curing_started_day":10})).is_false()
	)

extends GdUnitTestSuite
const K=preload("res://scripts/abrasive_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const F=preload("res://scripts/civilian_production_planner.gd")
const Ops=preload("res://scripts/technology_operations.gd")
const ITEMS=["fused_abrasive_alumina", "graded_alumina_grain", "vitrified_abrasive_bond", "green_abrasive_wheels", "fired_abrasive_wheels", "checked_abrasive_wheels", "abrasive_dressing_tools", "dressed_abrasive_wheels", "grinding_spindle_units", "cylindrical_grinding_fixtures", "centerless_regulating_wheels", "centerless_support_sets", "surface_grinding_fixtures", "oversize_plain_shaft_blanks", "cylindrical_ground_shaft_candidates", "centerless_ground_shaft_candidates", "checked_cylindrical_shafts", "checked_centerless_shafts", "motor_mount_plate_blanks", "surface_ground_mount_candidates", "checked_ground_mounts", "abrasive_hide_glue", "abrasive_maker_coated_web", "abrasive_sized_web", "checked_dry_abrasive_belts", "abrasive_belt_stands", "motor_housing_edge_blanks", "belt_finished_housing_candidates", "checked_deburred_housings", "ground_shaft_bearing_assemblies", "ground_component_motors"]
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("abrasive",1209)
func after_test()->void:
	WorldSimulation.clear();GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
func learn(id:String)->void:
	if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
	WorldSimulation.state.discovery_adoption[id]=1.0
func outputs()->Array[String]:
	var out:Array[String]=[]
	for item:String in ITEMS:
		var name:=String(I.product(item).output)
		if name not in out:out.append(name)
	return out
func prepare()->void:
	var state=WorldSimulation.state
	state.settlement_site_committed=true;state.convoy_traveling=false
	state.population_health=1;state.simulation_metrics.labor_efficiency=1
	state.population_allocations.Crafting=100;state.population_allocations.Logistics=100
	var made:=outputs()
	for item:String in ITEMS:
		var spec:=I.product(item);learn(spec.gate)
		for field:String in ["materials","tooling"]:
			for r:String in spec[field]:
				if r not in made:state.resource_stockpiles[r]=1000.0
	for r:String in made:state.resource_stockpiles[r]=0.0
	Ops.data().last_day=int(state.elapsed_days);Ops.data().services={"electricity":1000.0}
func provision(item:String)->Dictionary:
	var spec:=I.product(item);learn(spec.gate)
	for field:String in ["materials","tooling"]:
		for r:String in spec[field]:WorldSimulation.state.resource_stockpiles[r]=100.0
	WorldSimulation.state.resource_stockpiles[spec.output]=0.0
	Ops.data().last_day=int(WorldSimulation.state.elapsed_days);Ops.data().services={"electricity":1000.0}
	return start(item,1)
func start(item:String,target:int)->Dictionary:
	var result:=WorldSimulation.military.start_production_line(item,target)
	assert_bool(result.get("ok",false)).override_failure_message(str(result)).is_true()
	return WorldSimulation.military.equipment_queue.back() if result.get("ok",false) else {}
func make(item:String,target:int)->void:
	var job:=start(item,target)
	if job.is_empty():return
	P.advance(WorldSimulation.military,job,1000)
	assert_float(float(WorldSimulation.state.resource_stockpiles.get(I.product(item).output,0))).is_greater_equal(float(target))
	WorldSimulation.military.cancel_equipment_job(int(job.id))
func test_original_five_predicates_and_registered_routes()->void:
	WorldSimulation.scoped("abrasive",func()->void:
		assert_int(K.entries().size()).is_equal(5)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		var expected={"abrasive_grinding_control":["comparative_mineral_hardness","precision_machinery"],"centerless_grinding":["abrasive_grinding_control","precision_machinery"],"cylindrical_grinding":["centre_lathe_assembly","abrasive_grinding_control"],"surface_grinding":["machine_way_scraping","abrasive_grinding_control"],"abrasive_belt_finishing":["abrasive_grinding_control","belt_power_transmission"]}
		for e:Dictionary in K.entries():
			assert_array(e.requires_all).is_equal(expected[e.id]);assert_array(e.requires_any).is_empty()
		for id:String in ITEMS:assert_bool(I.product(id).is_empty()).is_false())
func test_all_recipes_pay_work_material_and_power_across_partial_save()->void:
	WorldSimulation.scoped("abrasive",func()->void:
		for id:String in ITEMS:
			var spec:=I.product(id);var job:=provision(id)
			if job.is_empty():return
			var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
			var power:=Ops.service("electricity")
			P.advance(WorldSimulation.military,job,float(spec.days)/2)
			assert_int(int(job.completed)).is_equal(0)
			var saved:Dictionary=bytes_to_var(var_to_bytes(job))
			assert_str(P.validate_saved({"equipment_queue":[saved]})).is_empty()
			P.advance(WorldSimulation.military,saved,float(spec.days)/2)
			assert_float(float(WorldSimulation.state.resource_stockpiles[spec.output])).is_equal(1.0)
			for r:String in spec.materials:assert_float(float(before[r])-float(WorldSimulation.state.resource_stockpiles[r])).is_equal_approx(float(spec.materials[r]),.000001)
			assert_float(power-Ops.service("electricity")).is_equal_approx(float(spec.get("power",0)),.000001)
			WorldSimulation.military.cancel_equipment_job(int(job.id)))
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
func test_missing_cooling_or_power_stops_grinding_without_cost_or_output()->void:
	WorldSimulation.scoped("abrasive",func()->void:
		var job:=provision("cylindrical_ground_shaft_candidates")
		WorldSimulation.state.resource_stockpiles.Freshwater=0.0
		var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
		P.advance(WorldSimulation.military,job,3)
		assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(before)
		WorldSimulation.state.resource_stockpiles.Freshwater=100.0;Ops.data().services.electricity=0.0
		before=WorldSimulation.state.resource_stockpiles.duplicate(true);P.advance(WorldSimulation.military,job,3)
		assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(before)
		assert_int(int(job.completed)).is_equal(0))
func test_paid_abrasive_chain_reaches_motor_without_granted_intermediates()->void:
	WorldSimulation.scoped("abrasive",func()->void:
		prepare()
		var state=WorldSimulation.state
		state.resource_stockpiles["Electric Motors"]=4.0
		# Only pre-existing feed/tools are provisioned; every new intermediate starts empty.
		for step:Array in [["fused_abrasive_alumina",40],["graded_alumina_grain",30],["vitrified_abrasive_bond",6],["green_abrasive_wheels",15],["fired_abrasive_wheels",12],["checked_abrasive_wheels",10],["abrasive_dressing_tools",3],["dressed_abrasive_wheels",8],["grinding_spindle_units",3],["cylindrical_grinding_fixtures",1],["centerless_regulating_wheels",1],["centerless_support_sets",1],["surface_grinding_fixtures",1],["oversize_plain_shaft_blanks",6],["cylindrical_ground_shaft_candidates",3],["checked_cylindrical_shafts",2],["centerless_ground_shaft_candidates",3],["checked_centerless_shafts",4],["motor_mount_plate_blanks",3],["surface_ground_mount_candidates",3],["checked_ground_mounts",2],["abrasive_hide_glue",3],["abrasive_maker_coated_web",4],["abrasive_sized_web",4],["checked_dry_abrasive_belts",3],["abrasive_belt_stands",1],["motor_housing_edge_blanks",3],["belt_finished_housing_candidates",3],["checked_deburred_housings",2],["ground_shaft_bearing_assemblies",2]]:
			make(step[0],step[1])
		# Electric motors were initial capital for the grinding machines; discard any
		# unspent fixture stock before checking newly assembled motor output.
		state.resource_stockpiles["Electric Motors"]=0.0
		make("ground_component_motors",1)
		assert_float(float(state.resource_stockpiles["Electric Motors"])).is_equal(1.0)
		assert_float(float(state.resource_stockpiles["20 mm Interchangeable Bearing Assemblies"])).is_equal(0.0)
		assert_float(float(state.resource_stockpiles["Ground Motor Mount Plates"])).is_equal(1.0)
		assert_float(float(state.resource_stockpiles["Deburred Motor Housings"])).is_equal(1.0))

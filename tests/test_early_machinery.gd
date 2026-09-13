extends GdUnitTestSuite
const Site=preload("res://scripts/water_hammer_site.gd")
const Ops=preload("res://scripts/technology_operations.gd")
const P=preload("res://scripts/persistent_production.gd")
const I=preload("res://scripts/civilian_industry.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("machines",4986)
func after_test()->void:
	WorldSimulation.clear();GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
func context()->Dictionary:
	return {"settlement_origin":Vector3.ZERO,"water_conveyance_sources":[{"id":"river:a","kind":"River","revealed":true,"position":Vector3(.2,0,0)}],"environment_profile":{"mean_temperature_c":20.0,"seasonality_c":0.0,"precipitation":.6}}
func setup()->void:
	var s=WorldSimulation.state
	s.settlement_site_committed=true;s.convoy_traveling=false;s.elapsed_days=0
	s.population_allocations.Crafting=20;s.population_health=1.0;s.simulation_metrics.labor_efficiency=1.0
	WorldSimulation.discovery.latest_context=context()
	for spec:Dictionary in Ops.PLANTS.values():
		for gate:String in [spec.gate]+spec.requires:
			if gate not in s.known_discoveries:s.known_discoveries.append(gate)
			s.discovery_adoption[gate]=1.0
		for item:String in spec.cost:s.resource_stockpiles[item]=100.0
		for item:String in spec.inputs:s.resource_stockpiles[item]=100.0
func test_river_identity_distance_climate_and_migration_are_required()->void:
	var c:=context();var site:=Site.select(c)
	assert_bool(Site.valid(site)).is_true()
	assert_float(float(Site.assessment(site,c,0).capacity)).is_equal(2.0)
	c.environment_profile.mean_temperature_c=-5.0
	assert_float(float(Site.assessment(site,c,0).capacity)).is_equal(0.0)
	c=context();c.environment_profile.precipitation=.05
	assert_float(float(Site.assessment(site,c,0).capacity)).is_equal(0.0)
	c=context();c.water_conveyance_sources[0].id="replacement"
	assert_float(float(Site.assessment(site,c,0).capacity)).is_equal(0.0)
	c=context();c.settlement_origin=Vector3(2,0,0)
	assert_float(float(Site.assessment(site,c,0).capacity)).is_equal(0.0)
	c=context();c.water_conveyance_sources[0].kind="Surface drainage"
	assert_dict(Site.select(c)).is_empty()
func test_saved_site_rejects_nonfinite_coordinates_and_roundtrips()->void:
	var site:=Site.select(context())
	assert_bool(Site.valid(JSON.parse_string(JSON.stringify(site)))).is_true()
	site.source[0]=INF
	assert_bool(Site.valid(site)).is_false()
func test_paid_commissioning_and_shared_river_budget()->void:
	WorldSimulation.scoped("machines",func()->void:
		setup();assert_bool(Ops.install("water_hammer",4).get("ok",false)).is_true()
		assert_float(float(WorldSimulation.state.resource_stockpiles["Water Hammer Drives"])).is_equal(96.0)
		assert_float(Ops.service("hammer_work")).is_equal(0.0)
		for day:int in range(1,25):
			WorldSimulation.state.elapsed_days=day;Ops.advance(day)
		assert_float(Ops.service("hammer_work")).is_less_equal(8.0)
		assert_float(Ops.service("hammer_work")).is_greater(0.0)
		var used:=Ops.consume_service("hammer_work",3.0)
		var remaining:=Ops.service("hammer_work")
		assert_float(used).is_equal(3.0)
		Ops.advance(24)
		assert_float(Ops.service("hammer_work")).is_equal(remaining)
		assert_bool(Ops.valid(JSON.parse_string(JSON.stringify(Ops.data())))).is_true()
		WorldSimulation.state.elapsed_days=25
		assert_float(Ops.service("hammer_work")).is_equal(0.0))
func test_secondary_settlement_cannot_consume_or_reset_primary_service()->void:
	WorldSimulation.scoped("machines",func()->void:
		setup();Ops.data().last_day=0;Ops.data().services={"hammer_work":4.0}
		WorldSimulation.state.resource_settlement_id="secondary"
		assert_float(Ops.consume_service("hammer_work",2)).is_equal(0.0)
		Ops.advance(1)
		assert_float(float(Ops.data().services.hammer_work)).is_equal(4.0)
		WorldSimulation.state.resource_settlement_id=""
		assert_float(Ops.consume_service("hammer_work",2)).is_equal(2.0))
func test_forging_spends_partial_service_and_materials_without_free_output()->void:
	WorldSimulation.scoped("machines",func()->void:
		setup();var item:="water_hammered_armor_plates";var spec:=I.product(item)
		WorldSimulation.state.known_discoveries.append(spec.gate);WorldSimulation.state.discovery_adoption[spec.gate]=1.0
		for resource:String in spec.materials:WorldSimulation.state.resource_stockpiles[resource]=100.0
		for resource:String in spec.tooling:WorldSimulation.state.resource_stockpiles[resource]=100.0
		assert_bool(WorldSimulation.military.start_production_line(item,2).get("ok",false)).is_true()
		var job:Dictionary=WorldSimulation.military.equipment_queue.back()
		P.advance(WorldSimulation.military,job,100)
		assert_float(float(job.last_work)).is_equal(0.0)
		Ops.data().last_day=0;Ops.data().services={"hammer_work":1.0}
		var iron:=float(WorldSimulation.state.resource_stockpiles["Wrought Iron"])
		P.advance(WorldSimulation.military,job,100)
		assert_float(float(job.progress_days)).is_equal(.75)
		assert_float(Ops.service("hammer_work")).is_equal(0.0)
		assert_float(iron-float(WorldSimulation.state.resource_stockpiles["Wrought Iron"])).is_equal_approx(.55,.000001)
		assert_float(float(WorldSimulation.state.resource_stockpiles.get("Armor Plates",0))).is_equal(0.0)
		Ops.data().services.hammer_work=1.0
		P.advance(WorldSimulation.military,job,100)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Armor Plates"])).is_equal(1.0))
func test_dependency_audit_rejects_unprovided_work_service()->void:
	var products:Dictionary={"press":{"gate":"press","output":"Pressed","days":1.0,"materials":{},"services":{"unmade_work":1.0}}}
	var result:Dictionary=preload("res://tools/production_dependency_audit.gd").audit(products,{},[],["press"])
	assert_bool(result.errors.is_empty()).is_false()
func provision(item:String,target:int=1)->Dictionary:
	var spec:=I.product(item);var state=WorldSimulation.state
	if spec.gate not in state.known_discoveries:state.known_discoveries.append(spec.gate)
	state.discovery_adoption[spec.gate]=1.0
	for resource:String in spec.materials:state.resource_stockpiles[resource]=100.0
	for resource:String in spec.tooling:state.resource_stockpiles[resource]=100.0
	assert_bool(WorldSimulation.military.start_production_line(item,target).get("ok",false)).is_true()
	return WorldSimulation.military.equipment_queue.back()
func test_all_fourteen_routes_pay_work_materials_and_use_existing_outputs()->void:
	WorldSimulation.scoped("machines",func()->void:
		setup()
		for item:String in ["bow_drill_sets","bow_drilled_axle_boxes","treadle_lathes","treadle_turned_axles","mechanical_screw_presses","screw_dewatered_paper","fitted_screw_printing","cam_follower_sets","cam_pressed_paper","woven_drive_belts","belt_drive_sets","water_hammer_drives","water_hammered_armor_plates","water_hammered_bolt_blanks"]:
			var spec:=I.product(item);var job:=provision(item)
			WorldSimulation.state.resource_stockpiles[spec.output]=0.0
			Ops.data().last_day=0;Ops.data().services={"electricity":10.0,"hammer_work":8.0}
			var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
			P.advance(WorldSimulation.military,job,float(spec.days)/2)
			assert_float(float(WorldSimulation.state.resource_stockpiles[spec.output])).is_equal(0.0)
			P.advance(WorldSimulation.military,job,float(spec.days)/2)
			assert_float(float(WorldSimulation.state.resource_stockpiles[spec.output])).override_failure_message(item).is_equal(1.0)
			for resource:String in spec.materials:assert_float(float(before[resource])-float(WorldSimulation.state.resource_stockpiles[resource])).override_failure_message(item+resource).is_equal_approx(float(spec.materials[resource]),.000001)
			assert_float(Ops.service("electricity")).is_equal(10.0-float(spec.get("power",0)))
			WorldSimulation.military.cancel_equipment_job(int(job.id)))
func test_real_downstream_demand_commissions_one_hammer_and_respects_missing_site()->void:
	WorldSimulation.scoped("machines",func()->void:
		setup();var job:=provision("lamellar_armor",32)
		WorldSimulation.state.resource_stockpiles["Armor Plates"]=0.0
		var planner=preload("res://scripts/water_hammer_investment.gd")
		assert_str(planner.recommendation().get("plant","")).is_equal("water_hammer")
		job.paused=true;assert_dict(planner.recommendation()).is_empty();job.paused=false
		WorldSimulation.discovery.latest_context.water_conveyance_sources=[]
		assert_dict(planner.recommendation()).is_empty()
		WorldSimulation.discovery.latest_context=context()
		assert_bool(Ops.install("water_hammer").get("ok",false)).is_true()
		assert_dict(planner.recommendation()).is_empty())
func test_manual_forging_remains_available_without_hammer_service()->void:
	WorldSimulation.scoped("machines",func()->void:
		setup();var job:=provision("iron_armor_plates")
		P.advance(WorldSimulation.military,job,4)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Armor Plates"])).is_equal(1.0)
		assert_float(Ops.service("hammer_work")).is_equal(0.0))
func test_full_save_restores_site_partial_forging_and_spent_daily_service()->void:
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	WorldSimulation.scoped("machines",func()->void:
		setup();Ops.install("water_hammer")
		var job:=provision("water_hammered_armor_plates",2)
		Ops.data().last_day=0;Ops.data().services={"hammer_work":2.0}
		P.advance(WorldSimulation.military,job,.75))
	var slot:="early_machinery_%d"%OS.get_process_id()
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	WorldSimulation.clear();var result:=SaveSystem.load_game(slot)
	DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_bool(result.get("ok",false)).override_failure_message(str(result)).is_true()
	if not result.get("ok",false):return
	WorldSimulation.scoped("machines",func()->void:
		assert_bool(Site.valid(Ops.data().plants.water_hammer.river_site)).is_true()
		assert_float(Ops.service("hammer_work")).is_equal(1.0)
		Ops.advance(0);assert_float(Ops.service("hammer_work")).is_equal(1.0)
		var job:Dictionary=WorldSimulation.military.equipment_queue.back()
		assert_float(float(job.progress_days)).is_equal(.75)
		P.advance(WorldSimulation.military,job,.75)
		assert_float(Ops.service("hammer_work")).is_equal(0.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Armor Plates"])).is_equal(1.0))
func test_actual_daily_step_rejects_deleted_source_without_spending_stale_river_service()->void:
	WorldSimulation.scoped("machines",func()->void:
		setup();Ops.install("water_hammer")
		Ops.data().plants.water_hammer.installed=1;Ops.data().plants.water_hammer.building=0
		var today:=context();today.water_conveyance_sources=[]
		preload("res://scripts/civilization_day.gd").advance(1,today)
		assert_float(Ops.service("hammer_work")).is_equal(0.0)
		assert_float(float(Ops.data().plants.water_hammer.running_units)).is_equal(0.0)
		assert_float(float(Ops.data().inputs.get("Rope Coils",0))).is_equal(0.0))
func test_actual_daily_step_rejects_moved_home_using_todays_context()->void:
	WorldSimulation.scoped("machines",func()->void:
		setup();Ops.install("water_hammer")
		Ops.data().plants.water_hammer.installed=1;Ops.data().plants.water_hammer.building=0
		var today:=context();today.settlement_origin=Vector3(2,0,0);today.origin=Vector3(2,0,0)
		preload("res://scripts/civilization_day.gd").advance(1,today)
		assert_float(Ops.service("hammer_work")).is_equal(0.0)
		assert_float(float(Ops.data().plants.water_hammer.running_units)).is_equal(0.0))

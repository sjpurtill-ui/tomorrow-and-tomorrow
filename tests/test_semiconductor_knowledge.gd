extends GdUnitTestSuite
const Knowledge=preload("res://scripts/semiconductor_knowledge.gd")
const Industry=preload("res://scripts/civilian_industry.gd")
const Production=preload("res://scripts/persistent_production.gd")
const Ops=preload("res://scripts/technology_operations.gd")
const P=preload("res://scripts/knowledge_pathways.gd")
func before_test()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(34141);DiscoverySystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();DiscoverySystem.initialize()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.elapsed_days=100000
func after_test()->void:
	GameState.elapsed_days=0;WorldSimulation.clear()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
func factory()->void:
	GameState.elapsed_days=0;GameState.settlement_site_committed=true;GameState.convoy_traveling=false
	GameState.population_health=1.0;GameState.simulation_metrics.labor_efficiency=1.0
	GameState.population_allocations.Crafting=100;GameState.population_allocations.Logistics=100
	for entry:Dictionary in DiscoverySystem.technology_catalog:
		GameState.known_discoveries.append(entry.id);GameState.discovery_adoption[entry.id]=1.0
	GameState.resource_stockpiles.clear()
	for resource:String in ["Fine Sand","Coal","Graphite","Salt","Freshwater","Phosphate Rock","Refined Copper","Timber","Stone","Clay"]:GameState.resource_stockpiles[resource]=1000.0
	for item:String in ["silicon_feedstock","purified_silicon","silicon_boules","silicon_wafers","solar_cells","solar_modules"]:
		for resource:String in Industry.product(item).tooling:GameState.resource_stockpiles[resource]=1000.0
	GameState.technology_operations.plants.steam_generator={"installed":1,"building":0,"work":0.0,"enabled":true}
func day()->void:
	GameState.elapsed_days+=1;Ops.advance(GameState.elapsed_days)
func test_authored_catalog_contracts_and_peaceful_reachability()->void:
	assert_int(Knowledge.entries().size()).is_equal(14)
	assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(Knowledge.entries(),DiscoverySystem.technology_catalog)).is_empty()
	var known:Array=[];var changed:=true
	while changed:
		changed=false
		for entry:Dictionary in DiscoverySystem.technology_catalog:
			if entry.dynamic=="security" or entry.id in known:continue
			for route:Dictionary in P.routes_for(entry,known,{}):
				if route.ready:known.append(entry.id);changed=true;break
	assert_bool("photovoltaic_power" in known).is_true()
func test_empirical_routes_reconverge_without_requiring_band_theory()->void:
	GameState.known_discoveries.assign(["chemical_distillation","electrical_measurement"])
	var doping:=P.chosen(DiscoverySystem.discovery_definition("semiconductor_doping"),100000)
	assert_str(String(doping.id)).is_equal("empirical")
	assert_float(float(doping.progress_multiplier)).is_equal(.65)
	GameState.known_discoveries.assign(["electrical_measurement","photoconductivity","electrochemical_cells"])
	assert_str(String(P.chosen(DiscoverySystem.discovery_definition("photovoltaic_conversion"),100000).id)).is_equal("empirical")
	GameState.known_discoveries.erase("electrical_measurement")
	assert_bool(P.ready(DiscoverySystem.discovery_definition("photovoltaic_conversion"),100000)).is_false()
func test_manufactured_silicon_chain_supplies_a_real_commissioned_array()->void:
	factory()
	var job:Dictionary={}
	for item:String in ["silicon_feedstock","purified_silicon","silicon_boules","silicon_wafers","solar_cells","solar_modules"]:
		var target:=1 if item=="solar_modules" else 2
		if job.is_empty():
			assert_bool(MilitaryCampaign.start_production_line(item,target).get("ok",false)).is_true()
			job=MilitaryCampaign.equipment_queue.back()
		else:
			assert_bool(MilitaryCampaign.retool_production_line(int(job.id),item).get("ok",false)).is_true()
			MilitaryCampaign.configure_production_line(int(job.id),target,false)
		for n in 40:
			day();Production.advance(MilitaryCampaign,job,100)
			if Production.stock(MilitaryCampaign,job)>=target:break
		assert_int(Production.stock(MilitaryCampaign,job)).override_failure_message(item+" did not produce its downstream input").is_equal(target)
	assert_float(float(GameState.resource_stockpiles["Solar Cells"])).is_equal(0.0)
	assert_bool(Ops.install("solar_array").get("ok",false)).is_true()
	assert_float(float(GameState.resource_stockpiles["Photovoltaic Modules"])).is_equal(0.0)
	assert_int(int(Ops.data().plants.solar_array.installed)).is_equal(0)
	for n in 6:day()
	assert_int(int(Ops.data().plants.solar_array.installed)).is_equal(1)
func test_solar_generation_displaces_coal_and_does_not_create_stored_energy()->void:
	factory()
	Ops.data().plants.solar_array={"installed":1,"building":0,"work":0.0,"enabled":true}
	Ops.data().plants.cold_store={"installed":1,"building":0,"work":0.0,"enabled":true}
	GameState.resource_stockpiles.Bitumen=10.0
	var coal:float=GameState.resource_stockpiles.Coal
	day()
	assert_float(Ops.service("cold_storage")).is_equal(200.0)
	assert_float(float(GameState.resource_stockpiles.Coal)).is_equal(coal)
	assert_float(Ops.service("electricity")).is_equal(0.0)
	assert_float(absf(float(Ops.data().workers)-1.15)).is_less(.000001)
	Ops.set_enabled("solar_array",false);day()
	assert_float(float(GameState.resource_stockpiles.Coal)).is_less(coal)
func test_solar_and_steam_share_only_unmet_demand()->void:
	factory()
	Ops.data().plants.solar_array={"installed":1,"building":0,"work":0.0,"enabled":true}
	Ops.data().plants.cold_store={"installed":2,"building":0,"work":0.0,"enabled":true}
	GameState.resource_stockpiles.Bitumen=10.0
	day()
	assert_float(Ops.service("cold_storage")).is_equal(400.0)
	assert_float(absf(float(Ops.data().inputs.Coal)-.1)).is_less(.000001)
func test_solar_requires_commissioning_and_actual_operators()->void:
	factory();GameState.resource_stockpiles["Photovoltaic Modules"]=1.0
	assert_float(Ops.service("electricity")).is_equal(0.0)
	Ops.install("solar_array");GameState.population_allocations.Crafting=0
	for n in 7:day()
	assert_int(int(Ops.data().plants.solar_array.installed)).is_equal(0)
	assert_float(Ops.service("electricity")).is_equal(0.0)
func test_new_array_save_round_trip_and_scaled_service_bounds()->void:
	factory();Ops.data().plants.solar_array={"installed":1000,"building":0,"work":0.0,"enabled":true}
	var saved:Dictionary=JSON.parse_string(JSON.stringify(Ops.data()))
	assert_bool(Ops.valid(saved)).is_true()
	saved.services["electricity"]=23000.0
	assert_bool(Ops.valid(saved)).is_true()
	saved.services["electricity"]=23001.0
	assert_bool(Ops.valid(saved)).is_false()

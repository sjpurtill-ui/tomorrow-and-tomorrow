extends GdUnitTestSuite
const E=preload("res://scripts/society_exchange.gd")
const P=preload("res://scripts/knowledge_pathways.gd")
const Purchase=preload("res://scripts/research_purchase.gd")
const L=preload("res://scripts/research_licenses.gd")
const Production=preload("res://scripts/persistent_production.gd")
func before_test()->void:
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(777);DiscoverySystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();FoodSystem.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	GameState.ensure_population_total(200);GameState.settlement_site_committed=true;GameState.housing_capacity=280
	GameState.population_allocations.Knowledge=30;GameState.population_allocations.Administration=12
	GameState.food_security=1;GameState.population_health=.95;GameState.water_metrics={"intake_ratio":1.0}
	GameState.simulation_metrics={"food_days":60,"food_intake_ratio":1.0,"security":.9,"cohesion":.9}
	GameState.resource_stockpiles.Food=20000;GameState.food_stocks={"Preserved food":20000.0}
	CivilizationSystem.set_scout_geography_authority(func(_p:Vector2)->bool:return true)
	WorldSimulation.create_actor("neighbor",777,Vector2(30,0));WorldSimulation.actors.neighbor.controller="manual"
	WorldSimulation.scoped("neighbor",func()->void:
		WorldSimulation.state.ensure_population_total(200);WorldSimulation.state.settlement_site_committed=true;WorldSimulation.state.housing_capacity=140
		WorldSimulation.state.food_security=.6;WorldSimulation.state.population_health=.7
		WorldSimulation.state.simulation_metrics={"food_days":30,"food_intake_ratio":1.0,"security":.3,"cohesion":.3}
		WorldSimulation.state.population_allocations.Crafting=8
		WorldSimulation.state.resource_stockpiles.Clay=20.0;WorldSimulation.state.resource_stockpiles.Food=20000
		WorldSimulation.state.food_stocks={"Preserved food":20000.0}
		WorldSimulation.state.known_discoveries.assign(["clay_shaping"]);WorldSimulation.state.discovery_adoption.clay_shaping=1.0
		E.policy("balanced","open"))
	CivilizationSystem.civilizations.clear();CivilizationSystem.civilizations.append({"id":"neighbor","name":"Neighbor","world_position":Vector2(30,0),"strategic_regions":[],"player_relation":{"opinion":.3,"at_war":false}})
	DiscoverySystem.initialize()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)

func after_test()->void:
	GameState.elapsed_days=0
	WorldSimulation.clear();GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)


func prepare()->void:
	GameState.elapsed_days=100000
	GameState.known_discoveries.assign(["workshop_standards","material_accounting"])
	E.owner_state("neighbor").known_discoveries.append("glassmaking");E.owner_state("neighbor").discovery_adoption.glassmaking=1.0
	GameState.population_allocations.Crafting=20
	GameState.resource_stockpiles.merge({"Fine Sand":20.0,"Limestone":20.0,"Timber":50.0,"Clay":20.0},true)
	GameState.resource_stockpiles.Stone=1000.0
	CivilizationSystem.civilizations[0].merge({"population":200,"production":.5,"logistics":.5,"food_days":30,"military_population":10},true)
	E.owner_state("neighbor").population_allocations.Knowledge=20
	CivilizationSystem.civilizations[0].player_relation.merge({"contact_level":2,"home_location_known":true,"home_position":{"x":30.0,"z":0.0}},true)
	CivilizationSystem.civilizations[0].strategic_regions=[{"id":"neighbor_city","role":"capital","name":"Neighbor city","map_x":.5,"map_y":.5,"position":Vector2(30,0),"controller":"neighbor","fortification":.2,"damage":0.0,"population":200,"strategic_weight":1.0}]

func license_trip(subject:String="glassmaking")->Dictionary:
	assert_bool(L.dispatch("neighbor",subject,"Stone").get("ok",false)).is_true()
	var mission:Dictionary=CivilizationSystem.diplomatic_mission
	E.envoy_arrived(CivilizationSystem,mission,int(mission.arrival_day))
	Purchase.prepare_return(mission)
	GameState.elapsed_days=int(mission.return_day)
	E.returned(mission,int(mission.return_day))
	return mission
func test_paid_contract_arrives_once_without_granting_knowledge()->void:
	prepare()
	var before:=float(GameState.resource_stockpiles.Stone)
	assert_bool(L.dispatch("neighbor","glassmaking","Stone").get("ok",false)).is_true()
	var mission:Dictionary=CivilizationSystem.diplomatic_mission
	assert_float(float(GameState.resource_stockpiles.Stone)).is_equal(before-float(mission.gift_amount))
	assert_bool(L.active("glassmaking")).is_false()
	E.envoy_arrived(CivilizationSystem,mission,int(mission.arrival_day));Purchase.prepare_return(mission)
	E.returned(mission,int(mission.return_day)-1)
	assert_dict(L.records()).is_empty()
	GameState.elapsed_days=int(mission.return_day);E.returned(mission,int(mission.return_day))
	assert_bool(L.active("glassmaking")).is_true()
	var expires:=int(L.records().glassmaking.expires_day)
	E.returned(mission,int(mission.return_day)+100)
	assert_int(int(L.records().glassmaking.expires_day)).is_equal(expires)
	assert_bool("glassmaking" in GameState.known_discoveries).is_false()
	assert_bool(E.valid(JSON.parse_string(JSON.stringify(E.data())))).is_true()
func test_licensed_work_pays_inputs_at_reduced_rate_and_expiry_stops_it()->void:
	prepare();license_trip()
	assert_bool(MilitaryCampaign.start_production_line("glass_batch",10).get("ok",false)).is_true()
	var job:Dictionary=MilitaryCampaign.equipment_queue.back()
	var sand:=float(GameState.resource_stockpiles["Fine Sand"])
	Production.advance(MilitaryCampaign,job,3.0)
	assert_int(int(job.completed)).is_equal(0)
	assert_float(float(job.progress_days)).is_equal_approx(1.95,.000001)
	assert_float(float(GameState.resource_stockpiles["Fine Sand"])).is_equal_approx(sand-1.3,.000001)
	var view:=Production.snapshot(MilitaryCampaign,job,3.0,1.0)
	assert_bool(view.licensed).is_true()
	assert_float(float(view.forecast_output_per_day)).is_greater(0.0)
	GameState.elapsed_days=int(L.records().glassmaking.expires_day)
	var stocks:=GameState.resource_stockpiles.duplicate(true)
	Production.advance(MilitaryCampaign,job,100.0)
	assert_dict(GameState.resource_stockpiles).is_equal(stocks)
	GameState.known_discoveries.append("glassmaking");GameState.discovery_adoption.glassmaking=1.0
	Production.advance(MilitaryCampaign,job,1.05)
	assert_int(int(job.completed)).is_equal(1)
	assert_bool(Production.snapshot(MilitaryCampaign,job,3.0,1.0).licensed).is_false()
func test_supplier_withdrawal_and_war_interrupt_without_erasing_goods()->void:
	prepare();license_trip();GameState.resource_stockpiles.Glass=2.0
	E.owner_state("neighbor").society_exchange.sharing_policy="guarded"
	assert_bool(L.active("glassmaking")).is_false()
	E.owner_state("neighbor").society_exchange.sharing_policy="open"
	CivilizationSystem.civilizations[0].player_relation.at_war=true
	assert_bool(L.active("glassmaking")).is_false()
	CivilizationSystem.civilizations[0].player_relation.at_war=false
	assert_bool(L.active("glassmaking")).is_true()
	assert_float(float(GameState.resource_stockpiles.Glass)).is_equal(2.0)
func test_refusal_returns_payment_once_and_quote_hides_supplier_knowledge()->void:
	prepare()
	var offer:=L.quote("neighbor","glassmaking","Stone")
	E.owner_state("neighbor").known_discoveries.clear()
	assert_dict(L.quote("neighbor","glassmaking","Stone")).is_equal(offer)
	var before:=float(GameState.resource_stockpiles.Stone)
	var mission:=license_trip()
	assert_bool(mission.research_refused).is_true()
	assert_float(float(GameState.resource_stockpiles.Stone)).is_equal(before)
	E.returned(mission,int(mission.return_day)+1)
	assert_float(float(GameState.resource_stockpiles.Stone)).is_equal(before)
	assert_dict(L.records()).is_empty()
func test_invalid_contract_terms_and_cross_mode_flags_are_rejected()->void:
	prepare();var mission:=license_trip()
	var saved:Dictionary=JSON.parse_string(JSON.stringify(E.data()))
	saved.production_licenses.glassmaking.expires_day+=1
	assert_bool(E.valid(saved)).is_false()
	var invalid:=mission.duplicate(true);invalid.research_mode="purchase"
	assert_bool(E.valid_mission(invalid)).is_false()
	invalid=mission.duplicate(true);invalid.license_authorized=false
	assert_bool(E.valid_mission(invalid)).is_false()
func test_missing_local_workshop_capability_and_nonproduction_subjects_are_rejected()->void:
	prepare()
	assert_bool(L.quote("neighbor","formation_drill","Stone").has("error")).is_true()
	GameState.known_discoveries.erase("material_accounting")
	assert_bool(L.dispatch("neighbor","glassmaking","Stone").has("error")).is_true()
func test_normal_envoy_processing_pays_supplier_and_renewal_requires_new_trip()->void:
	prepare();WorldSimulation.enabled=true
	var supplier:=E.owner_state("neighbor")
	var before:=float(supplier.resource_stockpiles.get("Stone",0))
	assert_bool(L.dispatch("neighbor","glassmaking","Stone").get("ok",false)).is_true()
	var mission:Dictionary=CivilizationSystem.diplomatic_mission
	var payment:=float(mission.gift_amount)
	GameState.elapsed_days=int(mission.arrival_day);CivilizationSystem._process_diplomatic_mission(int(mission.arrival_day))
	assert_float(float(supplier.resource_stockpiles.get("Stone",0))).is_equal(before)
	GameState.elapsed_days=int(mission.return_day);CivilizationSystem._process_diplomatic_mission(int(mission.return_day))
	assert_float(float(supplier.resource_stockpiles.Stone)).is_equal_approx(before+payment,.000001)
	assert_bool(L.active("glassmaking")).is_true()
	assert_bool(L.quote("neighbor","glassmaking","Stone").has("error")).is_true()
	GameState.elapsed_days=int(L.records().glassmaking.expires_day)-30
	assert_bool(L.quote("neighbor","glassmaking","Stone").has("error")).is_false()
	var expires:=int(L.records().glassmaking.expires_day)
	license_trip()
	assert_int(int(L.records().glassmaking.expires_day)).is_greater(expires)
func test_licensed_power_demand_is_real_and_zero_power_blocks_consumption()->void:
	prepare()
	var supplier:=E.owner_state("neighbor");supplier.known_discoveries.append("chloralkali_cells");supplier.discovery_adoption.chloralkali_cells=1.0
	E.data()["production_licenses"]={"chloralkali_cells":{"source":"neighbor","issued_day":100000,"expires_day":100365}}
	var recipe:Dictionary=preload("res://scripts/civilian_industry.gd").product("chloralkali_batch")
	for material:String in recipe.materials:GameState.resource_stockpiles[material]=20.0
	for material:String in recipe.tooling:GameState.resource_stockpiles[material]=20.0
	assert_bool(MilitaryCampaign.start_production_line("chloralkali_batch",1).get("ok",false)).is_true()
	assert_float(preload("res://scripts/technology_operations.gd").workshop_power_demand()).is_equal(2.0)
	var job:Dictionary=MilitaryCampaign.equipment_queue.back()
	var before:=GameState.resource_stockpiles.duplicate(true)
	Production.advance(MilitaryCampaign,job,100.0)
	assert_dict(GameState.resource_stockpiles).is_equal(before)
	assert_int(int(job.completed)).is_equal(0)
func test_saved_licensed_job_and_register_remain_separate_from_mastery()->void:
	prepare();license_trip()
	assert_bool(MilitaryCampaign.start_production_line("glass_batch",1).get("ok",false)).is_true()
	var job:Dictionary=MilitaryCampaign.equipment_queue.back()
	Production.advance(MilitaryCampaign,job,1.0)
	var saved_register:Dictionary=JSON.parse_string(JSON.stringify(E.data()))
	var saved_job:Dictionary=JSON.parse_string(JSON.stringify(job))
	assert_bool(E.valid(saved_register)).is_true()
	assert_str(Production.validate_saved({"equipment_queue":[saved_job]})).is_empty()
	GameState.society_exchange=saved_register
	assert_bool(L.active("glassmaking")).is_true()
	Production.advance(MilitaryCampaign,saved_job,4.0)
	assert_int(int(saved_job.completed)).is_equal(1)
	assert_bool("glassmaking" in GameState.known_discoveries).is_false()
func test_research_support_panel_offers_license_with_real_quote()->void:
	prepare()
	var panel:=preload("res://scripts/hud/research_purchase_panel.gd").new()
	panel.subject="glassmaking";add_child(panel)
	assert_str(String(panel.modes.get_selected_metadata())).is_equal("license")
	assert_bool(panel.summary.text.contains("365 days")).is_true()
	assert_bool(panel.send.disabled).is_false()
	assert_dict(L.records()).is_empty()
	panel.free()

func test_known_but_unadopted_technology_keeps_license_renewal_visible()->void:
	prepare();license_trip()
	CivilizationSystem.diplomatic_mission.clear()
	GameState.known_discoveries.append("glassmaking")
	GameState.discovery_adoption.glassmaking=.05
	GameState.elapsed_days=int(L.records().glassmaking.expires_day)-30
	const Panel=preload("res://scripts/hud/research_purchase_panel.gd")
	assert_bool(Panel.visible_for("glassmaking",true,true)).is_true()
	assert_bool(Panel.visible_for("glassmaking",false,true)).is_false()
	var panel:=Panel.new();panel.subject="glassmaking";add_child(panel)
	assert_str(String(panel.modes.get_selected_metadata())).is_equal("license")
	assert_bool(panel.send.disabled).is_false()
	panel.free()
	GameState.discovery_adoption.glassmaking=.10
	assert_bool(Panel.visible_for("glassmaking",true,true)).is_false()
const AI=preload("res://scripts/license_acquisition_planner.gd")
func paper_license_need()->void:
	prepare()
	GameState.resource_stockpiles["Paper Pulp"]=5.0;GameState.resource_stockpiles["Fiber Plants"]=10.0;GameState.resource_stockpiles.Freshwater=10.0
	E.owner_state("neighbor").known_discoveries.append("paper_making");E.owner_state("neighbor").discovery_adoption.paper_making=1.0
	E.data().collections["paper_lead"]={"id":"paper_lead","kind":"knowledge","name":"Paper account","source_id":"neighbor","source_name":"Neighbor","position":{"x":30.0,"z":0.0},"observed_day":99990,"returned_day":100000,"discovery_id":"paper_making","study":1.0,"work":90.0,"signals":["crafting"]}
	var study:Dictionary=E.data().collections.paper_lead.duplicate(true)
	study.id="unfinished";study.study=0.0;study.discovery_id="clay_shaping";study.work=240.0
	E.data().collections.unfinished=study
func test_ai_license_uses_examined_lead_without_hidden_supplier_knowledge()->void:
	paper_license_need()
	var order:=AI.recommendation()
	assert_str(String(order.get("kind",""))).is_equal("research_license")
	assert_str(String(order.get("subject",""))).is_equal("paper_making")
	E.owner_state("neighbor").known_discoveries.erase("paper_making")
	assert_dict(AI.recommendation()).is_equal(order)
	E.data().collections.paper_lead.study=.5;assert_dict(AI.recommendation()).is_empty()
	E.data().collections.paper_lead.study=1.0;E.data().collections.paper_lead.returned_day=100001
	assert_dict(AI.recommendation()).is_empty()
func test_ai_license_dispatch_pays_without_instant_contract_or_discovery()->void:
	paper_license_need()
	var before:=float(GameState.resource_stockpiles.Stone)
	assert_bool(preload("res://scripts/civilization_controller.gd").license_acquisition_orders("player",{})).is_true()
	assert_str(String(CivilizationSystem.diplomatic_mission.get("research_mode",""))).is_equal("license")
	assert_float(float(GameState.resource_stockpiles.Stone)).is_less(before)
	assert_bool(L.active("paper_making")).is_false()
	assert_bool(GameState.known_discoveries.has("paper_making")).is_false()
	assert_dict(AI.recommendation()).is_empty()
func test_ai_license_requires_real_need_inputs_staff_and_reserves()->void:
	paper_license_need()
	assert_dict(AI.recommendation({"hungry":true})).is_empty()
	assert_dict(AI.recommendation({"at_war":true})).is_empty()
	GameState.resource_stockpiles["Paper Pulp"]=0.0;assert_dict(AI.recommendation()).is_empty();GameState.resource_stockpiles["Paper Pulp"]=5.0
	GameState.resource_stockpiles.Paper=10.0;assert_dict(AI.recommendation()).is_empty();GameState.resource_stockpiles.Paper=0.0
	GameState.population_allocations.Crafting=0;assert_dict(AI.recommendation()).is_empty();GameState.population_allocations.Crafting=20
	GameState.known_discoveries.append("paper_making");GameState.discovery_adoption.paper_making=1.0
	assert_dict(AI.recommendation()).is_empty()
	GameState.known_discoveries.erase("paper_making")
	GameState.resource_stockpiles.Stone=100.0
	assert_dict(AI.recommendation()).is_empty()
func test_ai_renews_needed_line_from_own_contract_and_obeys_retry_window()->void:
	prepare();license_trip();CivilizationSystem.diplomatic_mission={}
	assert_bool(MilitaryCampaign.start_production_line("glass_batch",10).get("ok",false)).is_true()
	assert_dict(AI.recommendation()).is_empty()
	GameState.elapsed_days=int(L.records().glassmaking.expires_day)-90
	assert_str(AI.recommendation().subject).is_equal("glassmaking")
	CivilizationSystem.diplomatic_history.append({"civ_id":"neighbor","research_mode":"license","research_subject":"glassmaking","returned_day":int(GameState.elapsed_days)-10})
	assert_dict(AI.recommendation()).is_empty()
	GameState.elapsed_days+=30
	assert_str(AI.recommendation().subject).is_equal("glassmaking")
	MilitaryCampaign.equipment_queue[0].paused=true
	assert_dict(AI.recommendation()).is_empty()
func fertilizer_license_need()->void:
	prepare()
	GameState.population_allocations.Knowledge=0;GameState.population_allocations.Food=30
	GameState.simulation_metrics.cultivation_base_harvest=100.0
	for id:String in ["seed_selection","nutrient_response_trials"]:GameState.known_discoveries.append(id);GameState.discovery_adoption[id]=1.0
	GameState.resource_stockpiles.Nitrates=10.0;GameState.resource_stockpiles["Phosphate Rock"]=10.0;GameState.resource_stockpiles.Freshwater=20.0
	for id:String in ["mineral_nitrate_dressing","phosphate_dressing"]:
		E.owner_state("neighbor").known_discoveries.append(id);E.owner_state("neighbor").discovery_adoption[id]=1.0
		E.data().collections[id]={"id":id,"kind":"knowledge","name":"Examined fertilizer account","source_id":"neighbor","source_name":"Neighbor","position":{"x":30.0,"z":0.0},"observed_day":99990,"returned_day":100000,"discovery_id":id,"study":1.0,"work":90.0,"signals":["food"]}
func test_ai_fertilizer_licenses_use_examined_prospects_for_both_nutrients()->void:
	fertilizer_license_need()
	var order:=AI.recommendation()
	assert_str(String(order.get("subject",""))).is_equal("mineral_nitrate_dressing")
	E.owner_state("neighbor").known_discoveries.erase("mineral_nitrate_dressing")
	assert_dict(AI.recommendation()).is_equal(order)
	E.data().collections.phosphate_dressing.study=.5
	assert_dict(AI.recommendation()).is_empty()
	E.data().collections.phosphate_dressing.study=1.0;E.data().collections.phosphate_dressing.returned_day=100001
	assert_dict(AI.recommendation()).is_empty()
func test_ai_fertilizer_licenses_accept_domestic_complement_and_avoid_redundant_contracts()->void:
	fertilizer_license_need()
	E.data().collections.erase("phosphate_dressing")
	GameState.known_discoveries.append("phosphate_dressing");GameState.discovery_adoption.phosphate_dressing=1.0
	assert_str(String(AI.recommendation().subject)).is_equal("mineral_nitrate_dressing")
	GameState.known_discoveries.append("mineral_nitrate_dressing");GameState.discovery_adoption.mineral_nitrate_dressing=1.0
	assert_dict(AI.recommendation()).is_empty()
func test_ai_fertilizer_license_refuses_missing_complement_or_absent_cultivation()->void:
	fertilizer_license_need()
	GameState.resource_stockpiles["Phosphate Rock"]=0.0
	assert_dict(AI.recommendation()).is_empty()
	GameState.resource_stockpiles["Soluble Phosphate"]=5.0
	assert_str(String(AI.recommendation().subject)).is_equal("mineral_nitrate_dressing")
	GameState.population_allocations.Food=0;assert_dict(AI.recommendation()).is_empty();GameState.population_allocations.Food=30
	GameState.convoy_traveling=true;assert_dict(AI.recommendation()).is_empty();GameState.convoy_traveling=false
	GameState.simulation_metrics.cultivation_base_harvest=0.0;assert_dict(AI.recommendation()).is_empty()
func test_two_paid_fertilizer_licenses_enable_slow_manufacture_without_local_invention()->void:
	fertilizer_license_need()
	var before:=float(GameState.resource_stockpiles.Stone)
	for expected:String in ["mineral_nitrate_dressing","phosphate_dressing"]:
		assert_str(String(AI.recommendation().subject)).is_equal(expected)
		assert_bool(preload("res://scripts/civilization_controller.gd").license_acquisition_orders("player",{})).is_true()
		var mission:Dictionary=CivilizationSystem.diplomatic_mission
		assert_bool(L.active(expected)).is_false()
		E.envoy_arrived(CivilizationSystem,mission,int(mission.arrival_day));Purchase.prepare_return(mission)
		GameState.elapsed_days=int(mission.return_day);E.returned(mission,int(mission.return_day))
		assert_bool(L.active(expected)).is_true()
		assert_bool(GameState.known_discoveries.has(expected)).is_false()
		CivilizationSystem.diplomatic_mission={}
	assert_float(float(GameState.resource_stockpiles.Stone)).is_less(before)
	var industry=preload("res://scripts/civilian_industry.gd")
	for item:String in ["nitrate_fertilizer","ground_phosphate_fertilizer"]:
		var recipe:Dictionary=industry.product(item)
		assert_bool(MilitaryCampaign.start_production_line(item,1).get("ok",false)).is_true()
		var job:Dictionary=MilitaryCampaign.equipment_queue.back()
		Production.advance(MilitaryCampaign,job,float(recipe.days))
		assert_int(int(job.completed)).is_equal(0)
		assert_float(float(job.progress_days)).is_equal_approx(float(recipe.days)*.65,.000001)
		Production.advance(MilitaryCampaign,job,float(recipe.days)*.35/.65)
		assert_int(int(job.completed)).is_equal(1)
		MilitaryCampaign.cancel_equipment_job(int(job.id))
	assert_float(float(preload("res://scripts/crop_nutrition.gd").cultivation(100,true).bonus)).is_equal(12.5)
	assert_bool(GameState.known_discoveries.has("mineral_nitrate_dressing")).is_false()
	assert_bool(GameState.known_discoveries.has("phosphate_dressing")).is_false()
func operating_license_need()->void:
	prepare();GameState.population_allocations.Knowledge=0
	GameState.population_health=1.0;GameState.simulation_metrics.labor_efficiency=1.0
	const Ops=preload("res://scripts/technology_operations.gd")
	Ops.data().plants.pneumatic_workshop={"installed":1,"building":0,"work":0.0,"enabled":true}
	Ops.data().plants.solar_array={"installed":1,"building":0,"work":0.0,"enabled":true}
	for item:String in preload("res://scripts/civilian_industry.gd").product("compressed_air").tooling:GameState.resource_stockpiles[item]=10.0
	GameState.resource_stockpiles["Compressed Air"]=0.0
	var id:="compressed_air_systems"
	E.owner_state("neighbor").known_discoveries.append(id);E.owner_state("neighbor").discovery_adoption[id]=1.0
	E.data().collections[id]={"id":id,"kind":"knowledge","name":"Examined compressor account","source_id":"neighbor","source_name":"Neighbor","position":{"x":30.0,"z":0.0},"observed_day":99990,"returned_day":100000,"discovery_id":id,"study":1.0,"work":90.0,"signals":["crafting"]}
func test_operating_license_uses_examined_need_without_reading_hidden_provider_methods()->void:
	operating_license_need()
	var order:=AI.recommendation();assert_str(String(order.get("subject",""))).is_equal("compressed_air_systems")
	E.owner_state("neighbor").known_discoveries.erase("compressed_air_systems")
	assert_dict(AI.recommendation()).is_equal(order)
	E.data().collections.compressed_air_systems.study=.5;assert_dict(AI.recommendation()).is_empty()
	E.data().collections.compressed_air_systems.study=1.0;E.data().collections.compressed_air_systems.returned_day=100001
	assert_dict(AI.recommendation()).is_empty()
func test_operating_license_needs_power_tooling_active_machinery_and_no_domestic_route()->void:
	operating_license_need()
	const Ops=preload("res://scripts/technology_operations.gd")
	Ops.data().plants.pneumatic_workshop.enabled=false;assert_dict(AI.recommendation()).is_empty();Ops.data().plants.pneumatic_workshop.enabled=true
	Ops.data().plants.solar_array.enabled=false;assert_dict(AI.recommendation()).is_empty();Ops.data().plants.solar_array.enabled=true
	GameState.resource_stockpiles["Pressure Vessels"]=0.0;assert_dict(AI.recommendation()).is_empty();GameState.resource_stockpiles["Pressure Vessels"]=10.0
	GameState.resource_stockpiles["Compressed Air"]=15.0;assert_dict(AI.recommendation()).is_empty();GameState.resource_stockpiles["Compressed Air"]=0.0
	GameState.known_discoveries.append("compressed_air_systems");GameState.discovery_adoption.compressed_air_systems=1.0
	assert_dict(AI.recommendation()).is_empty()
func test_paid_compressor_license_runs_press_at_reduced_manufacturing_rate()->void:
	operating_license_need()
	const Ops=preload("res://scripts/technology_operations.gd")
	const C=preload("res://scripts/civilization_controller.gd")
	var before:=float(GameState.resource_stockpiles.Stone)
	assert_bool(C.license_acquisition_orders("player",{})).is_true()
	var mission:Dictionary=CivilizationSystem.diplomatic_mission
	E.envoy_arrived(CivilizationSystem,mission,int(mission.arrival_day));Purchase.prepare_return(mission)
	GameState.elapsed_days=int(mission.return_day);E.returned(mission,int(mission.return_day))
	assert_float(float(GameState.resource_stockpiles.Stone)).is_less(before)
	assert_bool(L.active("compressed_air_systems")).is_true()
	assert_bool(GameState.known_discoveries.has("compressed_air_systems")).is_false()
	C.civilian_orders("player",{})
	assert_str(String(MilitaryCampaign.equipment_queue[0].item)).is_equal("compressed_air")
	var job:Dictionary=MilitaryCampaign.equipment_queue[0]
	GameState.elapsed_days+=1;Ops.advance(int(GameState.elapsed_days));Production.advance(MilitaryCampaign,job,1.0)
	assert_float(float(job.progress_days)).is_equal_approx(.65,.000001)
	for day in 4:
		GameState.elapsed_days+=1;Ops.advance(int(GameState.elapsed_days));Production.advance(MilitaryCampaign,job,1.0)
	assert_float(Ops.service("mechanical_work")).is_greater(0.0)
	assert_bool(GameState.known_discoveries.has("compressed_air_systems")).is_false()

func test_paused_operating_input_line_does_not_trigger_new_license()->void:
	operating_license_need()
	MilitaryCampaign.equipment_queue.append({"persistent":true,"paused":true,"item":"compressed_air"})
	assert_dict(AI.recommendation()).is_empty()

func test_paid_polymer_license_processes_imported_measured_feed_slowly_without_mastery()->void:
	prepare()
	var subject:="polymer_molecular_weight_control"
	E.owner_state("neighbor").known_discoveries.append(subject)
	E.owner_state("neighbor").discovery_adoption[subject]=1.0
	var payment_before:=float(GameState.resource_stockpiles.Stone)
	license_trip(subject)
	assert_float(float(GameState.resource_stockpiles.Stone)).is_less(payment_before)
	assert_bool(L.active(subject)).is_true()
	assert_bool(subject in GameState.known_discoveries).is_false()
	var spec:Dictionary=preload("res://scripts/civilian_industry.gd").product("characterized_controlled_peg")
	for item:String in spec.tooling:GameState.resource_stockpiles[item]=100.0
	GameState.resource_stockpiles["Size-Characterized PEG Batches"]=2.0
	GameState.resource_stockpiles["Freshwater"]=2.0
	var ops=preload("res://scripts/technology_operations.gd")
	ops.data().last_day=int(GameState.elapsed_days);ops.data().services={"electricity":10.0}
	assert_bool(MilitaryCampaign.start_production_line("characterized_controlled_peg",2).get("ok",false)).is_true()
	var job:Dictionary=MilitaryCampaign.equipment_queue.back()
	Production.advance(MilitaryCampaign,job,4.0)
	assert_int(int(job.completed)).is_equal(0)
	assert_float(float(job.progress_days)).is_equal_approx(2.6,.000001)
	assert_float(float(GameState.resource_stockpiles["Size-Characterized PEG Batches"])).is_equal_approx(1.35,.000001)
	Production.advance(MilitaryCampaign,job,4.0)
	assert_int(int(job.completed)).is_equal(1)
	assert_float(float(GameState.resource_stockpiles["Size-Qualified PEG"])).is_equal(1.0)
	assert_bool(subject in GameState.known_discoveries).is_false()
	assert_bool("ring_opening_polymerization" in GameState.known_discoveries).is_false()
	GameState.elapsed_days=int(L.records()[subject].expires_day)
	ops.data().last_day=int(GameState.elapsed_days);ops.data().services={"electricity":10.0}
	var before:=GameState.resource_stockpiles.duplicate(true)
	Production.advance(MilitaryCampaign,job,100.0)
	assert_dict(GameState.resource_stockpiles).is_equal(before)
	assert_int(int(job.completed)).is_equal(1)

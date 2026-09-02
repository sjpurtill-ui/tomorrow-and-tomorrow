class_name SettlementModelTest
extends GdUnitTestSuite

const SETTLEMENT_MODEL_SCRIPT:=preload("res://scripts/settlement_model.gd")
const TEST_SEED:=772241

var model:Node

func before_test()->void:
	model=auto_free(SETTLEMENT_MODEL_SCRIPT.new())
	_reset_fixture(TEST_SEED)

func _reset_fixture(seed:int)->void:
	GameState.reset_for_new_world(seed)
	GameState.initialize_population_model()
	GameState.settlement_completed=["Hearth Circle"]
	GameState.settlement_founded_at=Vector3(14.0,0.0,-9.0)
	GameState.elapsed_days=19.0
	CivilizationSystem.reset_for_new_world()
	CivilizationSystem.register_player_origin(Vector2(GameState.settlement_founded_at.x,GameState.settlement_founded_at.z))
	model.ensure_founded()

func _count_use(land_use:String)->int:
	var count:=0
	for plot in GameState.settlement_plots:
		if String(plot.get("land_use",""))==land_use: count+=1
	return count

func test_founding_creates_complete_functional_plot_set()->void:
	assert_int(GameState.settlement_plots.size()).is_between(18,30)
	var uses:Dictionary={}
	var residents:=0
	for plot in GameState.settlement_plots:
		uses[String(plot.land_use)]=true
		residents+=int(plot.resident_count)
	for required_use in ["residential_compound","communal","storage","workshop","water","waste"]:
		assert_bool(uses.has(required_use)).is_true()
	assert_int(residents).is_equal(GameState.population_total)
	assert_int(GameState.settlement_nuclei.size()).is_equal(1)
	assert_str(String(GameState.settlement_nuclei[0].kind)).is_equal("founding_hearth")

func test_portable_founding_shelters_convert_in_place_after_lean_to_work()->void:
	var founding_ground:Dictionary={}
	for plot in GameState.settlement_plots:
		if String(plot.land_use) not in ["residential_compound","mixed_household"]: continue
		assert_str(String(plot.form)).is_equal("portable_shelter_cluster")
		founding_ground[int(plot.id)]=(plot.polygon as PackedVector2Array).duplicate()
	GameState.settlement_completed.append("Lean-to Shelters")
	GameState.elapsed_days=30.0
	model.process_month()
	for plot in GameState.settlement_plots:
		var plot_id:=int(plot.id)
		if not founding_ground.has(plot_id): continue
		assert_str(String(plot.form)).is_equal("lean_to_household_cluster")
		assert_array(plot.polygon).is_equal(founding_ground[plot_id])

func test_all_plots_have_valid_persistent_geometry_and_schema()->void:
	assert_array(model.validate_state()).is_empty()
	var ids:Dictionary={}
	for plot in GameState.settlement_plots:
		assert_int((plot.polygon as PackedVector2Array).size()).is_between(5,8)
		assert_float(float(plot.area_ha)).is_greater(0.0)
		assert_bool(ids.has(int(plot.id))).is_false()
		ids[int(plot.id)]=true

func test_initial_extent_is_human_scale()->void:
	var minimum:=Vector2(INF,INF)
	var maximum:=Vector2(-INF,-INF)
	for plot in GameState.settlement_plots:
		for point in plot.polygon:
			minimum.x=minf(minimum.x,point.x)
			minimum.y=minf(minimum.y,point.y)
			maximum.x=maxf(maximum.x,point.x)
			maximum.y=maxf(maximum.y,point.y)
	var extent:=maxf(maximum.x-minimum.x,maximum.y-minimum.y)
	assert_float(extent).is_between(0.10,0.22)


func test_coastal_site_advantage_is_modest_intrinsic_and_exposure_has_a_cost()->void:
	var previous_levels:=ProgressionSystem.domain_levels.duplicate(true)
	for domain in ["infrastructure","logistics","knowledge"]: ProgressionSystem.domain_levels[domain]=0
	var coast:Dictionary=model.coastal_site_profile({
		"shoreline_access":1.0,"marine_opportunity":0.9,"salt_opportunity":0.8,
		"storm_exposure":0.7,"erosion_exposure":0.6,"open_water_exposure":0.9
	})
	assert_bool(bool(coast.coastal)).is_true()
	assert_float(float(coast.food_output_bonus)).is_between(0.01,0.08)
	assert_float(float(coast.foraging_bonus)).is_between(0.01,0.06)
	assert_float(float(coast.maintenance_pressure)).is_greater(0.0)
	assert_float(float(coast.claim_multiplier)).is_less(1.0)
	assert_float(float(coast.maritime_movement_factor)).is_equal(0.0)
	assert_float(float(coast.maritime_trade_factor)).is_equal(0.0)
	ProgressionSystem.domain_levels=previous_levels


func test_coastal_maritime_reach_remains_research_gated()->void:
	var context:={"shoreline_access":1.0,"marine_opportunity":1.0,"open_water_exposure":1.0}
	var previous_levels:=ProgressionSystem.domain_levels.duplicate(true)
	ProgressionSystem.domain_levels["infrastructure"]=2
	ProgressionSystem.domain_levels["logistics"]=2
	ProgressionSystem.domain_levels["knowledge"]=2
	var movement:Dictionary=model.coastal_site_profile(context)
	assert_bool(bool(movement.movement_knowledge_ready)).is_true()
	assert_bool(bool(movement.trade_knowledge_ready)).is_false()
	assert_float(float(movement.maritime_movement_factor)).is_greater(0.0)
	ProgressionSystem.domain_levels["infrastructure"]=3
	ProgressionSystem.domain_levels["logistics"]=3
	var trade:Dictionary=model.coastal_site_profile(context)
	assert_bool(bool(trade.trade_knowledge_ready)).is_true()
	assert_float(float(trade.maritime_trade_factor)).is_greater(0.0)
	ProgressionSystem.domain_levels=previous_levels


func test_inland_settlement_receives_no_coastal_bonus()->void:
	var inland:Dictionary=model.coastal_site_profile({})
	assert_bool(bool(inland.coastal)).is_false()
	assert_float(float(inland.food_output_bonus)).is_equal(0.0)
	assert_float(float(inland.foraging_bonus)).is_equal(0.0)


func test_coastal_geography_keeps_real_shore_bearing_and_distance()->void:
	var sanitized:Dictionary=model._sanitized_territory_context({
		"shoreline_access":0.9,"coast_direction":Vector2(3.0,-4.0),
		"nearest_open_water_km":2.75
	})
	assert_float(Vector2(sanitized.coast_direction).x).is_equal_approx(0.6,0.0001)
	assert_float(Vector2(sanitized.coast_direction).y).is_equal_approx(-0.8,0.0001)
	assert_float(float(sanitized.nearest_open_water_km)).is_equal_approx(2.75,0.0001)

func test_settlement_border_is_bounded_irregular_and_expands_with_supported_population()->void:
	var initial:Dictionary=model.settlement_network_snapshot()
	assert_int(int(initial.count)).is_equal(1)
	assert_int(int(initial.runtime_people_entities)).is_equal(0)
	var first:Dictionary=initial.settlements[0]
	var initial_radius:=float(first.claim_radius_km)
	assert_int((first.boundary as PackedVector2Array).size()).is_equal(model.SETTLEMENT_BORDER_VERTICES)
	assert_float(initial_radius).is_between(0.32,2.0)
	GameState.ensure_population_total(2400)
	GameState.population_allocations["Survey"]=80
	GameState.population_allocations["Administration"]=70
	GameState.simulation_metrics["logistics"]=0.68
	GameState.elapsed_days+=730.0
	var expanded:Dictionary=model.settlement_network_snapshot().settlements[0]
	assert_float(float(expanded.claim_radius_km)).is_greater(initial_radius)
	assert_float(float(expanded.controlled_area_km2)).is_greater(float(first.controlled_area_km2))
	assert_int((expanded.boundary as PackedVector2Array).size()).is_equal(model.SETTLEMENT_BORDER_VERTICES)

func test_founding_lifecycle_stops_calling_committed_ground_a_convoy()->void:
	GameState.settlement_completed=[]
	GameState.settlement_site_committed=false
	GameState.settlement_convoy={}
	assert_str(GameState.settlement_lifecycle_phase()).is_equal("founding_expedition")
	assert_bool(GameState.founding_expedition_active()).is_true()
	GameState.settlement_site_committed=true
	assert_str(GameState.settlement_lifecycle_phase()).is_equal("founding_site")
	assert_bool(GameState.founding_expedition_active()).is_false()
	GameState.settlement_completed=["Hearth Circle"]
	assert_str(GameState.settlement_lifecycle_phase()).is_equal("established_network")
	GameState.settlement_convoy={"active":true}
	assert_str(GameState.settlement_lifecycle_phase()).is_equal("expansion_convoy")

func test_model_rejects_an_uncharted_convoy_destination_even_without_the_ui()->void:
	GameState.ensure_population_total(1000)
	GameState.resource_stockpiles={"Food":100000.0,"Timber":1000.0,"Fiber Plants":1000.0}
	var destination:=Vector2(GameState.settlement_founded_at.x+500.0,GameState.settlement_founded_at.z)
	var assessment:Dictionary=model.known_land_assessment(destination)
	assert_bool(bool(assessment.known)).is_false()
	var quote:Dictionary=model.settlement_convoy_quote(destination,30.0)
	assert_bool(bool(quote.ok)).is_false()
	assert_str(String(quote.reason)).contains("uncharted")

func test_convoy_quote_requires_a_continuous_returned_chart_and_real_travel_time()->void:
	GameState.ensure_population_total(1000)
	GameState.resource_stockpiles={"Food":1_000_000.0,"Timber":1000.0,"Fiber Plants":1000.0}
	var origin:=Vector2(GameState.settlement_founded_at.x,GameState.settlement_founded_at.z)
	var charted_destination:=origin+Vector2(64.0,0.0)
	var timed:Dictionary=model.settlement_convoy_quote(charted_destination,0.1)
	assert_bool(bool(timed.ok)).is_true()
	assert_float(float(timed.duration_days)).is_equal_approx(4.0,0.001)
	var disconnected_destination:=origin+Vector2(180.0,0.0)
	CivilizationSystem._add_revealed_area(disconnected_destination,42.0,"isolated returned chart")
	assert_bool(bool(model.known_land_assessment(disconnected_destination).known)).is_true()
	var disconnected:Dictionary=model.settlement_convoy_quote(disconnected_destination,20.0)
	assert_bool(bool(disconnected.ok)).is_false()
	assert_bool(bool(disconnected.get("known_route",true))).is_false()
	assert_str(String(disconnected.reason)).contains("route crosses uncharted ground")

func test_access_axes_make_the_fixed_border_follow_rivers_routes_and_work()->void:
	var settlement_id:=String(GameState.player_settlements[0].id)
	var axes:Array[Dictionary]=[]
	for index in 16:
		axes.append({"kind":"river" if index==0 else "route","direction":Vector2.RIGHT.rotated(float(index)*0.01),"influence":1.0})
	var update:Dictionary=model.set_settlement_territory_context(settlement_id,{"terrain_permeability":0.9,"water_access":1.0,"work_access":0.8,"travel_access":0.8,"access_axes":axes})
	assert_bool(bool(update.ok)).is_true()
	assert_int(int(update.axis_count)).is_equal(model.MAX_TERRITORY_ACCESS_AXES)
	var settlement:Dictionary=model.settlement_network_snapshot().settlements[0]
	var center:Vector2=settlement.position
	var east:=0.0
	var west:=0.0
	for point in (settlement.boundary as PackedVector2Array):
		east=maxf(east,point.x-center.x)
		west=maxf(west,center.x-point.x)
	assert_float(east).is_greater(west)
	assert_float(float(settlement.territory_drivers.water)).is_equal(1.0)
	assert_float(float(settlement.territory_drivers.work)).is_greater_equal(0.8)

func test_paid_aggregate_convoy_seeds_a_second_settlement_without_creating_people_entities()->void:
	GameState.ensure_population_total(1000)
	GameState.food_stocks={"Fresh plants":0.0,"Fresh meat":0.0,"Fish":0.0,"Dry staples":5000.0,"Preserved food":1000.0}
	GameState.resource_stockpiles={"Food":6000.0,"Timber":500.0,"Fiber Plants":500.0}
	var destination:=Vector2(GameState.settlement_founded_at.x+8.0,GameState.settlement_founded_at.z)
	var quote:Dictionary=model.settlement_convoy_quote(destination,1.0)
	assert_bool(bool(quote.ok)).is_true()
	var quoted_sources:=0
	for amount in (quote.population_sources as Dictionary).values(): quoted_sources+=int(amount)
	assert_int(quoted_sources).is_equal(int(quote.population))
	var food_before:=float(GameState.resource_stockpiles.Food)
	var timber_before:=float(GameState.resource_stockpiles.Timber)
	var started:Dictionary=model.begin_settlement_convoy(destination,1.0)
	assert_bool(bool(started.ok)).is_true()
	assert_bool(bool(GameState.settlement_convoy.active)).is_true()
	assert_dict(GameState.settlement_convoy.population_sources).is_equal(quote.population_sources)
	var convoy_profile:=GameState.population_function_profile({"total_absent":int(quote.population),"by_function":quote.population_sources})
	assert_int(int(convoy_profile.absent)).is_equal(int(quote.population))
	assert_int(int(convoy_profile.accounted)).is_equal(GameState.population_total)
	assert_float(float(GameState.resource_stockpiles.Food)).is_less(food_before)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_less(timber_before)
	assert_int(roundi(model.primary_population_exact())).is_equal(960)
	assert_str(String(GameState.food_issue_history.back().category)).is_equal("settlement_convoy")
	assert_bool(bool(GameState.food_issue_history.back().charged_at_departure)).is_true()
	GameState.elapsed_days=float(GameState.settlement_convoy.arrival_day)
	model.update_settlement_convoy(destination,1.0)
	var completed:Dictionary=model.complete_settlement_convoy(destination)
	assert_bool(bool(completed.ok)).is_true()
	var network:Dictionary=model.settlement_network_snapshot()
	assert_int(int(network.count)).is_equal(2)
	assert_int(int(network.runtime_people_entities)).is_equal(0)
	var represented:=0
	for settlement in network.settlements: represented+=int(settlement.population)
	assert_int(represented).is_equal(GameState.population_total)
	assert_array(model.validate_settlement_network()).is_empty()

func test_convoy_cannot_arrive_early_or_found_anywhere_except_its_approved_site()->void:
	GameState.ensure_population_total(1000)
	GameState.resource_stockpiles={"Food":100000.0,"Timber":1000.0,"Fiber Plants":1000.0}
	var destination:=Vector2(GameState.settlement_founded_at.x+8.0,GameState.settlement_founded_at.z)
	var started:Dictionary=model.begin_settlement_convoy(destination,1.0)
	assert_bool(bool(started.ok)).is_true()
	model.update_settlement_convoy(destination,1.0)
	assert_float(float(GameState.settlement_convoy.progress)).is_equal(0.0)
	assert_bool(bool(model.complete_settlement_convoy(destination).ok)).is_false()
	GameState.elapsed_days=float(GameState.settlement_convoy.arrival_day)
	model.update_settlement_convoy(destination,1.0)
	var diverted:Dictionary=model.complete_settlement_convoy(destination+Vector2(1.0,0.0))
	assert_bool(bool(diverted.ok)).is_false()
	assert_str(String(diverted.reason)).contains("approved")
	assert_bool(bool(model.complete_settlement_convoy(destination).ok)).is_true()

func test_billion_person_civilization_keeps_fixed_border_resolution()->void:
	GameState.ensure_population_total(1_000_000_000)
	var network:Dictionary=model.settlement_network_snapshot()
	assert_int(int(network.count)).is_equal(1)
	assert_int((network.settlements[0].boundary as PackedVector2Array).size()).is_equal(model.SETTLEMENT_BORDER_VERTICES)
	assert_int(int(network.runtime_people_entities)).is_equal(0)
	var territory:Dictionary=model.territory_control_snapshot()
	assert_int(int(territory.settlement_claim_count)).is_equal(1)
	assert_int(int(territory.runtime_people_entities)).is_equal(0)
	assert_bool(bool(territory.bounded)).is_true()

func test_conquest_uses_the_existing_bounded_strategic_region_in_the_territory_snapshot()->void:
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	var regions:Array=civ.strategic_regions
	var original:Dictionary=(regions[0] as Dictionary).duplicate(true)
	var occupied:Dictionary=original.duplicate(true)
	occupied["controller"]="player"
	occupied["integration"]=0.24
	occupied["resistance"]=0.63
	occupied["occupation_turns"]=3
	regions[0]=occupied
	civ["strategic_regions"]=regions
	CivilizationSystem.civilizations[0]=civ
	var territory:Dictionary=model.territory_control_snapshot()
	assert_int(int(territory.occupied_region_count)).is_equal(1)
	assert_int(int(territory.record_count)).is_equal(int(territory.settlement_claim_count)+1)
	assert_int(int(territory.record_count)).is_less_equal(int(territory.record_limit))
	assert_str(String(territory.occupied_regions[0].id)).is_equal(String(occupied.id))
	assert_float(float(territory.occupied_regions[0].integration)).is_equal_approx(0.24,0.0001)
	regions[0]=original
	civ["strategic_regions"]=regions
	CivilizationSystem.civilizations[0]=civ

func test_same_seed_produces_identical_plot_history()->void:
	var first:=GameState.settlement_plots.duplicate(true)
	_reset_fixture(TEST_SEED)
	var second:=GameState.settlement_plots.duplicate(true)
	assert_int(first.size()).is_equal(second.size())
	for index in first.size():
		assert_int(int(first[index].id)).is_equal(int(second[index].id))
		assert_str(String(first[index].land_use)).is_equal(String(second[index].land_use))
		assert_array(first[index].polygon).is_equal(second[index].polygon)
		assert_float(float(first[index].condition)).is_equal_approx(float(second[index].condition),0.000001)

func test_population_change_does_not_move_existing_plots()->void:
	var polygons:Array=[]
	for plot in GameState.settlement_plots: polygons.append((plot.polygon as PackedVector2Array).duplicate())
	GameState.ensure_population_total(220)
	model.ensure_founded()
	model.rebuild_summary()
	for index in polygons.size(): assert_array(GameState.settlement_plots[index].polygon).is_equal(polygons[index])

func test_damage_and_abandonment_persist_without_erasing_lineage()->void:
	var plot_id:=int(GameState.settlement_plots[0].id)
	var polygon:PackedVector2Array=GameState.settlement_plots[0].polygon.duplicate()
	model.apply_plot_damage(plot_id,0.72,"Camp fire")
	assert_bool(String(GameState.settlement_plots[0].status) in ["damaged","ruin"]).is_true()
	assert_array(GameState.settlement_plots[0].polygon).is_equal(polygon)
	model.abandon_plot(plot_id,"Unsafe after fire")
	assert_str(String(GameState.settlement_plots[0].status)).is_equal("vacant")
	assert_array(GameState.settlement_plots[0].polygon).is_equal(polygon)
	assert_int(GameState.settlement_plot_history.size()).is_greater(GameState.settlement_plots.size())


func test_siege_damage_changes_one_bounded_contiguous_aggregate_area()->void:
	var original_count:=GameState.settlement_plots.size()
	var affected:Array[int]=model.apply_bounded_siege_damage(9413,0.32,0.48,"home siege combat")
	assert_int(affected.size()).is_between(1,mini(model.MAX_BATTLE_DAMAGED_PLOTS,original_count))
	assert_int(GameState.settlement_plots.size()).is_equal(original_count)
	var affected_centers:Array[Vector2]=[]
	for plot in GameState.settlement_plots:
		if int(plot.get("id",-1)) not in affected: continue
		assert_bool(String(plot.get("status","")) in ["damaged","ruin"]).is_true()
		affected_centers.append(Vector2(plot.get("centroid",Vector2.ZERO)))
	var maximum_span:=0.0
	for a in affected_centers:
		for b in affected_centers: maximum_span=maxf(maximum_span,a.distance_to(b))
	assert_float(maximum_span).is_less(0.20)
	assert_array(model.validate_state()).is_empty()

func test_population_alone_cannot_create_a_town()->void:
	GameState.ensure_population_total(5000)
	GameState.simulation_metrics["logistics"]=0.05
	GameState.simulation_metrics["legitimacy"]=0.25
	GameState.settlement_completed=["Hearth Circle"]
	var summary:Dictionary=model.rebuild_summary()
	assert_bool(String(summary.classification) not in ["town","city","metropolis"]).is_true()
	assert_bool((summary.limiting_factors as Array).is_empty()).is_false()

func test_household_growth_requires_pressure_labor_and_delivered_materials()->void:
	var original_residential:=_count_use("residential_compound")
	GameState.ensure_population_total(240)
	GameState.population_allocations["Construction"]=8
	GameState.resource_stockpiles={}
	GameState.elapsed_days=60.0
	model.process_month()
	assert_int(_count_use("residential_compound")).is_equal(original_residential)
	assert_int(_count_use("temporary_encampment")).is_greater(0)
	GameState.resource_stockpiles={"Timber":8.0,"Fiber Plants":6.0}
	GameState.elapsed_days=90.0
	model.process_month()
	assert_int(_count_use("residential_compound")).is_equal(original_residential+1)
	var growth_plot:Dictionary=GameState.settlement_plots.back()
	assert_str(String(growth_plot.status)).is_equal("under_construction")
	assert_str(String(growth_plot.growth_cause)).contains("materials")
	assert_float(float(GameState.resource_stockpiles.Timber)).is_less(8.0)
	assert_int(GameState.settlement_routes.size()).is_greater(0)

func test_growth_plot_completes_without_moving_older_ground()->void:
	var first_polygon:PackedVector2Array=GameState.settlement_plots[0].polygon.duplicate()
	GameState.ensure_population_total(240)
	GameState.population_allocations["Construction"]=8
	GameState.resource_stockpiles={"Timber":8.0,"Fiber Plants":6.0}
	GameState.elapsed_days=60.0
	model.process_month()
	var growth_id:=int(GameState.settlement_plots.back().id)
	for day in [90.0,120.0]:
		GameState.elapsed_days=day
		model.process_month()
	var completed:Dictionary={}
	for plot in GameState.settlement_plots:
		if int(plot.id)==growth_id: completed=plot
	assert_str(String(completed.status)).is_equal("active")
	assert_array(GameState.settlement_plots[0].polygon).is_equal(first_polygon)

func test_depopulation_creates_visible_vacancy_and_reoccupation_without_erasure()->void:
	var original_count:=GameState.settlement_plots.size()
	var first_polygon:PackedVector2Array=GameState.settlement_plots[0].polygon.duplicate()
	GameState.population_total=1
	GameState.population_exact=1.0
	for month in range(1,9):
		GameState.elapsed_days=float(month*30)
		model.process_month()
	var vacant_count:=0
	var reclaimed_signal:=0.0
	for plot in GameState.settlement_plots:
		if String(plot.status)=="vacant":
			vacant_count+=1
			reclaimed_signal=maxf(reclaimed_signal,float(plot.get("reclamation",0.0)))
	assert_int(vacant_count).is_greater(0)
	assert_float(reclaimed_signal).is_greater(0.0)
	assert_int(GameState.settlement_plots.size()).is_equal(original_count)
	assert_array(GameState.settlement_plots[0].polygon).is_equal(first_polygon)
	GameState.population_total=120
	GameState.population_exact=120.0
	GameState.elapsed_days=270.0
	model.process_month()
	var reoccupied:=0
	for plot in GameState.settlement_plots:
		if String(plot.get("reoccupation_state",""))=="reoccupied": reoccupied+=1
	assert_int(reoccupied).is_greater(0)

func test_two_centuries_of_supplied_growth_stays_bounded_and_valid()->void:
	GameState.population_allocations["Construction"]=10
	GameState.simulation_metrics["labor_efficiency"]=0.78
	GameState.resource_stockpiles={"Timber":80.0,"Fiber Plants":80.0}
	for month in range(1,2401):
		if month%3==0:
			GameState.population_total+=1
			GameState.population_exact=float(GameState.population_total)
		GameState.resource_stockpiles["Timber"]=maxf(80.0,float(GameState.resource_stockpiles.get("Timber",0.0)))
		GameState.resource_stockpiles["Fiber Plants"]=maxf(80.0,float(GameState.resource_stockpiles.get("Fiber Plants",0.0)))
		GameState.elapsed_days=float(month*30)
		model.process_month()
	assert_array(model.validate_state()).is_empty()
	assert_int(GameState.settlement_plots.size()).is_between(60,190)
	var maximum_extent:=0.0
	for plot in GameState.settlement_plots:
		for point in plot.polygon: maximum_extent=maxf(maximum_extent,point.length())
	assert_float(maximum_extent*2.0).is_less(1.8)
	var main_approaches:=0
	for route in GameState.settlement_routes:
		if String(route.get("hierarchy",""))=="main_approach": main_approaches+=1
	assert_int(main_approaches).is_less_equal(clampi(1+floori(float(GameState.population_total)/1800.0),1,8))
	assert_int(GameState.settlement_plot_history.size()).is_greater(GameState.settlement_plots.size())

func test_cultivation_requires_discovery_food_labor_and_surveyed_fertile_ground()->void:
	var original_count:=GameState.settlement_plots.size()
	GameState.elapsed_days=60.0
	model.process_month()
	assert_int(GameState.settlement_plots.size()).is_equal(original_count)
	GameState.known_discoveries.append("seed_selection")
	GameState.elapsed_days=90.0
	model.process_month()
	assert_int(GameState.settlement_plots.size()).is_equal(original_count)
	GameState.resource_deposits.append({"id":"fertile_test","resource":"Fertile Soil","stage":"surveyed","position":GameState.settlement_founded_at+Vector3(2.0,0.0,1.0)})
	GameState.elapsed_days=120.0
	model.process_month()
	assert_int(GameState.settlement_plots.size()).is_equal(original_count+1)
	var field:Dictionary=GameState.settlement_plots.back()
	assert_str(String(field.land_use)).is_equal("field")
	assert_str(String(field.form)).is_equal("hand_cultivated_clearance")
	assert_int(int(field.worker_count)).is_greater(0)

func test_cultivated_ground_scales_with_allocated_food_labor()->void:
	GameState.known_discoveries.append("seed_selection")
	GameState.resource_deposits.append({"id":"fertile_scale_test","resource":"Fertile Soil","stage":"surveyed","position":GameState.settlement_founded_at+Vector3(1.0,0.0,0.5)})
	GameState.population_allocations["Food"]=36
	for day in [60.0,90.0,120.0]:
		GameState.elapsed_days=day
		model.process_month()
	var fields:Array[Dictionary]=[]
	var total_capacity:=0
	for plot in GameState.settlement_plots:
		if String(plot.get("land_use",""))!="field": continue
		fields.append(plot)
		total_capacity+=int(plot.get("worker_capacity",0))
	assert_int(fields.size()).is_equal(3)
	assert_int(total_capacity).is_equal(36)

func test_field_seasons_change_visual_state_without_rewriting_geometry()->void:
	GameState.known_discoveries.append("seed_selection")
	GameState.resource_deposits.append({"id":"fertile_season_test","resource":"Fertile Soil","stage":"surveyed","position":GameState.settlement_founded_at+Vector3(1.0,0.0,0.5)})
	GameState.population_allocations["Food"]=12
	GameState.elapsed_days=60.0
	model.process_month()
	var field:Dictionary=GameState.settlement_plots.back()
	var field_polygon:PackedVector2Array=(field.polygon as PackedVector2Array).duplicate()
	var revision_before:=GameState.morphology_revision
	model.call("_update_field_seasons",210)
	assert_str(String(field.get("cultivation_phase",""))).is_equal("mature")
	assert_float(float(field.get("crop_cover",0.0))).is_greater(0.85)
	assert_array(field.polygon).is_equal(field_polygon)
	assert_int(GameState.morphology_revision).is_equal(revision_before+1)
	model.call("_update_field_seasons",210)
	assert_int(GameState.morphology_revision).is_equal(revision_before+1)

func test_workshop_growth_requires_practice_craft_labor_builders_and_materials()->void:
	var original_count:=GameState.settlement_plots.size()
	GameState.settlement_completed.append("Open Work Area")
	GameState.population_allocations["Crafting"]=12
	GameState.population_allocations["Construction"]=8
	GameState.resource_stockpiles={}
	GameState.elapsed_days=60.0
	model.process_month()
	assert_int(GameState.settlement_plots.size()).is_equal(original_count)
	GameState.resource_stockpiles={"Timber":7.0,"Fiber Plants":4.0}
	GameState.elapsed_days=90.0
	model.process_month()
	assert_int(GameState.settlement_plots.size()).is_equal(original_count+1)
	var workshop:Dictionary=GameState.settlement_plots.back()
	assert_str(String(workshop.land_use)).is_equal("workshop")
	assert_str(String(workshop.status)).is_equal("under_construction")
	assert_str(String(workshop.growth_cause)).contains("craft")
	assert_float(float(GameState.resource_stockpiles.Timber)).is_less(7.0)

func test_storage_growth_requires_storage_practice_and_logistics_pressure()->void:
	var original_count:=GameState.settlement_plots.size()
	GameState.settlement_completed.append("Storage Pits")
	GameState.population_allocations["Logistics"]=10
	GameState.population_allocations["Construction"]=8
	GameState.resource_stockpiles={"Timber":7.0,"Fiber Plants":4.0}
	GameState.elapsed_days=60.0
	model.process_month()
	assert_int(GameState.settlement_plots.size()).is_equal(original_count+1)
	var storage:Dictionary=GameState.settlement_plots.back()
	assert_str(String(storage.land_use)).is_equal("storage")
	assert_float(float(storage.storage_capacity)).is_greater(4.0)
	assert_str(String(storage.growth_cause)).contains("logistics")

func test_role_reallocation_visibly_idles_and_reopens_working_ground()->void:
	GameState.known_discoveries.append("seed_selection")
	GameState.resource_deposits.append({"id":"fertile_test","resource":"Fertile Soil","stage":"surveyed","position":GameState.settlement_founded_at+Vector3(2.0,0.0,1.0)})
	GameState.elapsed_days=60.0
	model.process_month()
	var field:Dictionary=GameState.settlement_plots.back()
	assert_str(String(field.land_use)).is_equal("field")
	GameState.population_allocations["Food"]=0
	for month in range(3,10):
		GameState.elapsed_days=float(month*30)
		model.process_month()
	assert_int(int(field.worker_count)).is_equal(0)
	assert_str(String(field.status)).is_equal("vacant")
	assert_float(float(field.get("reclamation",0.0))).is_greater(0.0)
	GameState.population_allocations["Food"]=12
	GameState.elapsed_days=300.0
	model.process_month()
	assert_int(int(field.worker_count)).is_greater(0)
	assert_str(String(field.status)).is_equal("active")

func test_overflow_population_claims_temporary_ground_without_free_housing()->void:
	GameState.ensure_population_total(420)
	GameState.population_allocations["Construction"]=4
	GameState.population_allocations["Logistics"]=4
	GameState.resource_stockpiles={}
	GameState.elapsed_days=60.0
	model.process_month()
	var camp:Dictionary={}
	for plot in GameState.settlement_plots:
		if String(plot.get("land_use",""))=="temporary_encampment":
			camp=plot
			break
	assert_bool(camp.is_empty()).is_false()
	assert_int(int(camp.get("resident_capacity",-1))).is_equal(0)
	assert_int(int(camp.get("resident_count",0))).is_greater(0)
	assert_float(float(camp.get("roof_coverage",1.0))).is_less(0.10)
	assert_str(String(camp.get("repair_state",""))).is_equal("awaiting_materials")
	var camp_density:=float(camp.get("resident_count",0))/maxf(0.001,float(camp.get("area_ha",0.0)))
	assert_float(camp_density).is_between(100.0,520.0)
	var summary:Dictionary=model.rebuild_summary()
	assert_int(int(summary.get("population_without_permanent_housing",0))).is_greater(0)
	assert_int(int(summary.get("temporary_camp_population",0))).is_greater(0)
	assert_array(model.validate_state()).is_empty()
	# Once durable capacity exceeds the population, inherited camp ground empties
	# rather than being silently promoted into free permanent housing.
	GameState.population_total=1
	var events:Array[Dictionary]=[]
	for day in [90,120,150]: model.call("_update_overflow_encampments",day,events)
	assert_int(int(camp.get("resident_count",-1))).is_equal(0)
	assert_str(String(camp.get("status",""))).is_equal("vacant")
	# Temporary cover leaves an archaeological trace in history, but the physical
	# ground is reclaimed instead of hardening into a permanent building ruin.
	for month in range(6,72):
		var day:=month*30
		model.call("_update_overflow_encampments",day,events)
		model.call("_process_occupancy_and_maintenance",day,events)
	assert_str(String(camp.get("status",""))).is_equal("reclaimed")
	assert_str(String(camp.get("repair_state",""))).is_equal("ground_reclaimed")

func test_resource_backed_infill_adds_capacity_without_rewriting_plot_geometry()->void:
	GameState.ensure_population_total(280)
	GameState.population_allocations["Construction"]=12
	GameState.population_allocations["Logistics"]=6
	GameState.resource_stockpiles={"Timber":30.0,"Fiber Plants":24.0}
	var inherited_geometry:Dictionary={}
	var inherited_capacity:Dictionary={}
	for plot in GameState.settlement_plots:
		if String(plot.get("land_use","")) not in ["residential_compound","mixed_household"]: continue
		inherited_geometry[int(plot.id)]=(plot.polygon as PackedVector2Array).duplicate()
		inherited_capacity[int(plot.id)]=int(plot.get("resident_capacity",0))
	GameState.elapsed_days=120.0
	model.process_month()
	var infilled:Dictionary={}
	for plot in GameState.settlement_plots:
		if int(plot.get("infill_units",0))>0:
			infilled=plot
			break
	assert_bool(infilled.is_empty()).is_false()
	var plot_id:=int(infilled.id)
	assert_array(infilled.polygon).is_equal(inherited_geometry[plot_id])
	assert_int(int(infilled.resident_capacity)).is_greater(int(inherited_capacity[plot_id]))
	assert_float(float(infilled.roof_coverage)).is_greater(0.30)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_less(30.0)
	assert_array(model.validate_state()).is_empty()

func test_elapsed_centuries_alone_do_not_repaint_inherited_fabric()->void:
	var original_polygons:Dictionary={}
	for plot in GameState.settlement_plots:
		original_polygons[int(plot.id)]=(plot.polygon as PackedVector2Array).duplicate()
	GameState.settlement_founded_day=0
	GameState.elapsed_days=65700.0
	for role in GameState.population_allocations: GameState.population_allocations[role]=0
	var events:Array[Dictionary]=[]
	model._evolve_inherited_fabric(65700,events)
	assert_array(events).is_empty()
	for plot in GameState.settlement_plots:
		assert_int(int(plot.get("fabric_generation",0))).is_equal(0)
		assert_array(plot.polygon).is_equal(original_polygons[int(plot.id)])

func test_supported_fabric_evolves_in_place_and_records_route_surface()->void:
	GameState.settlement_founded_day=0
	GameState.settlement_completed=["Hearth Circle","Lean-to Shelters","Storage Pits","Open Work Area","Gathering Yard"]
	GameState.population_allocations["Construction"]=50
	GameState.population_allocations["Crafting"]=22
	GameState.population_allocations["Logistics"]=12
	GameState.simulation_metrics["labor_efficiency"]=0.72
	GameState.resource_stockpiles["Timber"]=120.0
	GameState.resource_stockpiles["Fiber Plants"]=80.0
	GameState.settlement_nuclei.append({"id":2,"kind":"market_crossing","position":Vector2(0.11,0.03),"pull":0.72,"active":true,"created_day":1200,"absorbed_day":-1})
	var original_polygons:Dictionary={}
	for plot in GameState.settlement_plots:
		original_polygons[int(plot.id)]=(plot.polygon as PackedVector2Array).duplicate()
	var events:Array[Dictionary]=[]
	model._evolve_inherited_fabric(9000,events)
	assert_int(events.size()).is_equal(1)
	var changed_plot_id:=int(events[0].plot_id)
	var changed:Dictionary={}
	for plot in GameState.settlement_plots:
		if int(plot.id)==changed_plot_id: changed=plot
		assert_array(plot.polygon).is_equal(original_polygons[int(plot.id)])
	assert_dict(changed).is_not_empty()
	assert_int(int(changed.fabric_generation)).is_equal(1)
	assert_str(String(changed.morphology_era)).is_equal("foothold")
	var frontage_id:=int(changed.frontage_route_id)
	var surfaced:=false
	for route in GameState.settlement_routes:
		if int(route.id)==frontage_id:
			surfaced=String(route.get("surface",""))=="cleared_earth"
	assert_bool(surfaced).is_true()

func test_later_functional_districts_require_matching_roles_age_and_materials()->void:
	GameState.settlement_founded_day=0
	GameState.settlement_completed=["Hearth Circle","Lean-to Shelters","Open Work Area"]
	GameState.population_allocations["Construction"]=18
	GameState.population_allocations["Crafting"]=0
	GameState.population_allocations["Logistics"]=100
	GameState.resource_stockpiles={"Timber":80.0,"Fiber Plants":50.0}
	var events:Array[Dictionary]=[]
	model._attempt_functional_growth(5475,events)
	assert_str(String(GameState.settlement_plots.back().land_use)).is_equal("market")

	_reset_fixture(TEST_SEED+1)
	GameState.settlement_founded_day=0
	GameState.settlement_completed=["Hearth Circle","Lean-to Shelters","Open Work Area"]
	GameState.population_allocations["Construction"]=18
	GameState.population_allocations["Administration"]=100
	GameState.resource_stockpiles={"Timber":80.0,"Fiber Plants":50.0}
	events.clear()
	model._attempt_functional_growth(10950,events)
	assert_str(String(GameState.settlement_plots.back().land_use)).is_equal("civic")

	_reset_fixture(TEST_SEED+2)
	GameState.settlement_founded_day=0
	GameState.settlement_completed=["Hearth Circle","Lean-to Shelters","Open Work Area"]
	GameState.known_discoveries.append("stone_selection")
	GameState.population_allocations["Construction"]=18
	GameState.population_allocations["Extraction"]=100
	GameState.resource_stockpiles={"Stone":80.0,"Timber":50.0}
	events.clear()
	model._attempt_functional_growth(18250,events)
	assert_str(String(GameState.settlement_plots.back().land_use)).is_equal("dirty_industry")

func test_growth_rejects_submerged_ground_before_scoring_access()->void:
	var context:={
		"settlement_origin":GameState.settlement_founded_at,
		"buildable_land_at":func(_x:float,_z:float)->bool: return false
	}
	var score:float=model._growth_site_score(Vector2(1.0,1.0),0.006,"residential_compound",context)
	assert_float(score).is_less(-9000.0)

func test_later_material_transition_is_seeded_and_physically_paid()->void:
	GameState.known_discoveries.append("stone_selection")
	GameState.resource_stockpiles["Stone"]=50.0
	GameState.resource_stockpiles["Timber"]=20.0
	var candidate_plot:Dictionary={}
	for plot in GameState.settlement_plots:
		if absi(int(plot.get("seed",1)))%10 in [0,3,6,8]:
			candidate_plot=plot
			break
	assert_dict(candidate_plot).is_not_empty()
	candidate_plot["fabric_generation"]=6
	var cost:Dictionary=model._fabric_upgrade_cost(candidate_plot,7)
	var stone_before:=float(GameState.resource_stockpiles.Stone)
	var events:Array[Dictionary]=[]
	model._apply_fabric_upgrade({"plot":candidate_plot,"next_tier":7,"cost":cost},25550,events)
	assert_str(String(candidate_plot.material_family)).is_equal("stone")
	assert_float(float(GameState.resource_stockpiles.Stone)).is_less(stone_before)
	assert_int(int(candidate_plot.fabric_generation)).is_equal(7)
	assert_array(events).has_size(1)

func test_mature_population_founds_paid_connected_quarter_beyond_inherited_core()->void:
	GameState.settlement_founded_day=0
	GameState.ensure_population_total(6200)
	GameState.population_allocations["Construction"]=80
	GameState.population_allocations["Logistics"]=45
	GameState.population_allocations["Administration"]=24
	GameState.simulation_metrics["logistics"]=0.52
	GameState.known_discoveries.append("route_memory")
	GameState.resource_stockpiles={"Timber":120.0,"Fiber Plants":90.0}
	var original_plot_count:=GameState.settlement_plots.size()
	var original_nucleus_count:=GameState.settlement_nuclei.size()
	var original_extent:=0.0
	for plot in GameState.settlement_plots:
		original_extent=maxf(original_extent,Vector2(plot.centroid).length())
	var timber_before:=float(GameState.resource_stockpiles.Timber)
	var events:Array[Dictionary]=[]
	var flat_context:={
		"settlement_origin":GameState.settlement_founded_at,
		"buildable_land_at":func(_x:float,_z:float)->bool: return true,
		"terrain_height_at":func(_x:float,_z:float)->float: return 0.0,
		"river_distance_at":func(_x:float,_z:float)->float: return INF
	}
	model._attempt_mature_district_expansion(1800,events,flat_context)
	assert_int(GameState.settlement_nuclei.size()).is_equal(original_nucleus_count+1)
	assert_str(String(GameState.settlement_nuclei.back().kind)).is_equal("satellite_quarter")
	assert_int(GameState.settlement_plots.size()).is_greater(original_plot_count)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_less(timber_before)
	assert_array(events).has_size(1)
	assert_int(int(events[0].plots)).is_greater_equal(3)
	var expanded_extent:=0.0
	for plot in GameState.settlement_plots:
		expanded_extent=maxf(expanded_extent,Vector2(plot.centroid).length())
	assert_float(expanded_extent).is_greater(original_extent+0.06)
	var connector_found:=false
	for route in GameState.settlement_routes:
		if String(route.get("kind",""))=="district_connector" and String(route.get("hierarchy",""))=="main_approach":
			connector_found=true
			assert_int((route.points as PackedVector2Array).size()).is_equal(6)
	assert_bool(connector_found).is_true()
	assert_array(model.validate_state()).is_empty()

func test_population_alone_cannot_found_a_satellite_quarter()->void:
	GameState.settlement_founded_day=0
	GameState.ensure_population_total(6200)
	GameState.resource_stockpiles={"Timber":120.0,"Fiber Plants":90.0}
	var original_plots:=GameState.settlement_plots.size()
	var original_nuclei:=GameState.settlement_nuclei.size()
	var events:Array[Dictionary]=[]
	model._attempt_mature_district_expansion(1800,events,{})
	assert_array(events).is_empty()
	assert_int(GameState.settlement_plots.size()).is_equal(original_plots)
	assert_int(GameState.settlement_nuclei.size()).is_equal(original_nuclei)

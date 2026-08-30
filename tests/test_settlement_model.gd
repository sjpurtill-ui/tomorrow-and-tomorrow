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
	GameState.initialize_citizen_registry()
	GameState.settlement_completed=["Hearth Circle"]
	GameState.settlement_founded_at=Vector3(14.0,0.0,-9.0)
	GameState.elapsed_days=19.0
	model.ensure_founded()

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
	GameState.ensure_living_population(220)
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

func test_population_alone_cannot_create_a_town()->void:
	GameState.ensure_living_population(5000)
	GameState.simulation_metrics["logistics"]=0.05
	GameState.simulation_metrics["legitimacy"]=0.25
	GameState.settlement_completed=["Hearth Circle"]
	var summary:Dictionary=model.rebuild_summary()
	assert_bool(String(summary.classification) not in ["town","city","metropolis"]).is_true()
	assert_bool((summary.limiting_factors as Array).is_empty()).is_false()

func test_household_growth_requires_pressure_labor_and_delivered_materials()->void:
	var original_count:=GameState.settlement_plots.size()
	GameState.ensure_living_population(240)
	GameState.population_allocations["Construction"]=8
	GameState.resource_stockpiles={}
	GameState.elapsed_days=60.0
	model.process_month()
	assert_int(GameState.settlement_plots.size()).is_equal(original_count)
	GameState.resource_stockpiles={"Timber":8.0,"Fiber Plants":6.0}
	GameState.elapsed_days=90.0
	model.process_month()
	assert_int(GameState.settlement_plots.size()).is_equal(original_count+1)
	var growth_plot:Dictionary=GameState.settlement_plots.back()
	assert_str(String(growth_plot.status)).is_equal("under_construction")
	assert_str(String(growth_plot.growth_cause)).contains("materials")
	assert_float(float(GameState.resource_stockpiles.Timber)).is_less(8.0)
	assert_int(GameState.settlement_routes.size()).is_greater(0)

func test_growth_plot_completes_without_moving_older_ground()->void:
	var first_polygon:PackedVector2Array=GameState.settlement_plots[0].polygon.duplicate()
	GameState.ensure_living_population(240)
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

extends GdUnitTestSuite

func before_test()->void:
	GameState.reset_for_new_world(9191)
	CivilizationSystem.reset_for_new_world()
	CivilizationSystem.ground_survey_authority=func(_point:Vector2)->Dictionary: return {"biome":"steppe","label":"dry steppe","height":1.0}

func after_test()->void:
	CivilizationSystem.ground_survey_authority=Callable()

func test_annual_expedition_creates_a_strategic_find()->void:
	var route:Array=[{"x":0.0,"z":0.0},{"x":500.0,"z":100.0},{"x":1200.0,"z":300.0},{"x":2000.0,"z":500.0}]
	var mission:={"mission_id":12,"duration_days":365}
	var salt_before:=float(GameState.resource_stockpiles.get("Salt",0))
	CivilizationSystem._resolve_scout_windfalls(mission,route,1524)
	var deposits:Array=mission.discoveries.filter(func(item:Dictionary)->bool: return String(item.kind)=="resource")
	assert_int(deposits.size()).is_greater_equal(1)
	assert_str(String(deposits[0].resource)).is_equal("Salt")
	assert_bool(GameState.resource_deposits.any(func(item:Dictionary)->bool: return String(item.id)==String(deposits[0].deposit_id) and String(item.stage)=="recognized")).is_true()
	assert_float(float(GameState.resource_stockpiles.get("Salt",0))).is_equal(salt_before)
	assert_bool(mission.discoveries.any(func(item:Dictionary)->bool: return String(item.get("resource",""))=="Fiber Plants")).is_false()

func test_terrain_and_recognition_gate_the_resource_reward()->void:
	var rng:=RandomNumberGenerator.new()
	rng.seed=12
	assert_str(ExpeditionFindings.resource_for({"biome":"water"},1524,rng,true)).is_empty()
	assert_str(ExpeditionFindings.resource_for({"biome":"woodland"},1524,rng,true)).is_equal("Medicinal Plants")
	assert_str(ExpeditionFindings.resource_for({"biome":"upland"},1524,rng,true)).is_equal("Flint")
	assert_str(ExpeditionFindings.resource_for({"biome":"steppe"},0,rng,true)).is_not_equal("Salt")
	var late_finds:Dictionary={}
	for i in 40: late_finds[ExpeditionFindings.resource_for({"biome":"upland"},365*100,rng,true)]=true
	assert_bool(late_finds.has("Copper Ore") and late_finds.has("Tin Ore") and late_finds.has("Iron Ore")).is_true()

func test_no_deposits_are_invented_on_open_water()->void:
	CivilizationSystem.ground_survey_authority=func(_point:Vector2)->Dictionary: return {"biome":"water"}
	var route:Array=[{"x":0,"z":0},{"x":100,"z":0},{"x":300,"z":0},{"x":500,"z":0}]
	var mission:={"mission_id":12,"duration_days":365}
	var before:=GameState.resource_deposits.size()
	CivilizationSystem._resolve_scout_windfalls(mission,route,1524)
	assert_int(GameState.resource_deposits.size()).is_equal(before)

func test_older_reports_gain_the_design_without_new_rewards()->void:
	var old:={"day":100,"duration_days":30,"windfalls":["The party brought back 4 timber."],"route":[]}
	var provider:RefCounted=load("res://scripts/hud/content/dock_detail_scout_report.gd").new(null,null,old)
	var view:Dictionary=provider.tab(0)
	assert_int(provider.meta().subtabs.size()).is_equal(2)
	assert_str(JSON.stringify(view)).contains("The party brought back 4 timber.")
	assert_bool(old.has("discoveries")).is_false()

func test_return_pipeline_persists_discoveries_and_actual_journey_length()->void:
	var mission:={"mission_id":55,"start_day":1100,"duration_days":365,"personnel":6,"target_kind":"explore","route":[{"x":0,"z":0},{"x":500,"z":200},{"x":1100,"z":400},{"x":1700,"z":700}]}
	CivilizationSystem.scout_missions.append(mission)
	CivilizationSystem._complete_scout_mission(mission,1524)
	assert_int(CivilizationSystem.scout_reports.size()).is_equal(1)
	var report:Dictionary=CivilizationSystem.scout_reports[0]
	assert_int(int(report.actual_days)).is_equal(424)
	assert_int(report.discoveries.size()).is_greater_equal(2)
	var snapshot:=CivilizationSystem.export_state()
	CivilizationSystem.scout_reports.clear()
	var loaded:=CivilizationSystem.import_state(snapshot)
	assert_str(String(loaded.get("error",""))).is_empty()
	if CivilizationSystem.scout_reports.is_empty(): return
	assert_int(int(CivilizationSystem.scout_reports[0].actual_days)).is_equal(424)
	assert_array(CivilizationSystem.scout_reports[0].discoveries).is_equal(report.discoveries)

func test_legacy_fiber_is_a_resupply_note_not_the_headline()->void:
	var old:={"day":1524,"windfalls":["They mark a workable fiber plants occurrence about 3612 km out."],"route":[]}
	var provider:RefCounted=load("res://scripts/hud/content/dock_detail_scout_report.gd").new(null,null,old)
	assert_str(JSON.stringify(provider.tab(0))).contains("What sustained the journey")
	assert_str(JSON.stringify(provider.tab(1))).contains("3612 km")
	assert_bool(old.has("discoveries")).is_false()

func test_old_save_retires_landmarks_and_keeps_real_findings()->void:
	var snapshot:=CivilizationSystem.export_state()
	var original_range:=CivilizationSystem.scout_one_way_range(365)
	snapshot["landmarks"]=[{"id":"old_place","name":"The Old Stones"}]
	snapshot["next_landmark_id"]=2
	snapshot["scout_reports"]=[{"day":100,"discoveries":[{"kind":"landmark","title":"The Old Stones"},{"kind":"resource","title":"Salt"}],"windfalls":["They name The Old Stones along the route — one more waymark extending range.","Carried 4 timber home."],"journal":["They steered by The Old Stones.","Across dry steppe."]}]
	var loaded:=CivilizationSystem.import_state(snapshot)
	assert_str(String(loaded.get("error",""))).is_empty()
	var saved:=CivilizationSystem.export_state()
	assert_bool(saved.has("landmarks")).is_false()
	assert_bool(saved.has("next_landmark_id")).is_false()
	assert_float(CivilizationSystem.scout_one_way_range(365)).is_equal(original_range)
	var restored:Dictionary=CivilizationSystem.scout_reports[0]
	assert_int(restored.discoveries.size()).is_equal(1)
	assert_str(String(restored.discoveries[0].title)).is_equal("Salt")
	assert_array(restored.windfalls).is_equal(["Carried 4 timber home."])
	assert_array(restored.journal).is_equal(["Across dry steppe."])

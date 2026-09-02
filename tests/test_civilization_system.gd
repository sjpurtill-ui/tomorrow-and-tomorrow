extends GdUnitTestSuite

const CIVILIZATION_SYSTEM_SCRIPT:=preload("res://scripts/civilization_system.gd")

var system:Node

func before_test()->void:
	GameState.reset_for_new_world(112358)
	GameState.resource_stockpiles={"Food":5000.0}
	GameState.settlement_site_committed=true
	MilitaryCampaign.reset_for_new_world()
	system=auto_free(CIVILIZATION_SYSTEM_SCRIPT.new())
	system.reset_for_new_world()
	system.set_scout_geography_authority(func(_position:Vector2)->bool: return true)
	_set_all_contacted_and_located()


func _set_all_contacted_and_located()->void:
	for index in system.civilizations.size():
		var civ:Dictionary=system.civilizations[index]
		civ.player_relation["contact_level"]=2
		civ.player_relation["contact_intelligence"]=0.65
		civ.player_relation["met_day"]=0
		civ.player_relation["home_location_known"]=true
		civ.player_relation["home_position"]={"x":float(index+1)*50.0,"z":float(index+1)*17.0}
		system.civilizations[index]=civ


func _hide_all_contacts()->void:
	for index in system.civilizations.size():
		var civ:Dictionary=system.civilizations[index]
		civ.player_relation["contact_level"]=0
		civ.player_relation["contact_intelligence"]=0.0
		civ.player_relation["met_day"]=-1
		civ.player_relation["treaty"]="none"
		civ.player_relation["at_war"]=false
		civ.player_relation["trade"]=0.0
		system.civilizations[index]=civ


func test_unmet_civilizations_are_absent_from_player_knowledge()->void:
	_hide_all_contacts()
	var known:Dictionary=system.known_competition_snapshot()
	assert_int((known.leaders as Array).size()).is_equal(1)
	assert_int(int(known.contacted_count)).is_equal(0)
	assert_bool(bool(known.global_rank_hidden)).is_true()
	assert_dict(system.known_civilization_snapshot(String(system.civilizations[0].id))).is_empty()
	assert_bool(system.player_action_availability(String(system.civilizations[0].id),"open_trade").has("error")).is_true()


func test_known_foreign_snapshot_never_leaks_exact_population_or_unearned_regions()->void:
	var civ:Dictionary=system.civilizations[0]
	var civ_id:=String(civ.id)
	var relation:Dictionary=civ.player_relation
	relation["contact_level"]=2
	relation["contact_intelligence"]=0.19
	relation["home_location_known"]=true
	relation["home_position"]={"x":1200.0,"z":900.0}
	civ["player_relation"]=relation
	system.civilizations[0]=civ
	var first_contact:Dictionary=system.known_civilization_snapshot(civ_id)
	assert_bool(first_contact.has("population")).is_false()
	assert_bool(first_contact.has("controlled_population")).is_false()
	assert_bool(first_contact.has("cohorts")).is_false()
	assert_bool(first_contact.has("population_estimate_low")).is_false()
	assert_array(first_contact.get("strategic_regions",[])).is_empty()
	assert_int(int(first_contact.get("home_regions_total",0))).is_equal(-1)
	system.civilizations[0].player_relation["contact_intelligence"]=0.30
	var bounded_report:Dictionary=system.known_civilization_snapshot(civ_id)
	assert_bool(bounded_report.has("population")).is_false()
	assert_bool(bounded_report.has("population_estimate_low")).is_true()
	assert_bool(bounded_report.has("population_estimate_high")).is_true()
	assert_float(float(bounded_report.population_estimate_low)).is_less(float(bounded_report.population_estimate_high))
	assert_array(bounded_report.get("strategic_regions",[])).is_empty()
	system.civilizations[0].player_relation["contact_intelligence"]=0.60
	system.civilizations[0].player_relation["home_location_known"]=false
	system.civilizations[0].player_relation["home_position"]={}
	assert_array(system.known_civilization_snapshot(civ_id).get("strategic_regions",[])).is_empty()
	system.civilizations[0].player_relation["home_location_known"]=true
	system.civilizations[0].player_relation["home_position"]={"x":1200.0,"z":900.0}
	var mapped_report:Dictionary=system.known_civilization_snapshot(civ_id)
	assert_int((mapped_report.get("strategic_regions",[]) as Array).size()).is_equal(system.STRATEGIC_REGIONS_PER_CIV)
	assert_bool(mapped_report.has("population")).is_false()


func test_army_destinations_require_region_intelligence_and_revealed_ground()->void:
	var civ:Dictionary=system.civilizations[0]
	var civ_id:=String(civ.id)
	civ.player_relation["contact_level"]=2
	civ.player_relation["contact_intelligence"]=0.54
	civ.player_relation["home_location_known"]=true
	civ.player_relation["home_position"]={"x":1200.0,"z":900.0}
	system.civilizations[0]=civ
	system.revealed_areas.clear()
	system._add_revealed_area(Vector2(1200.0,900.0),300.0,"returned test chart")
	var low_intelligence:=(system.military_movement_destinations() as Array).filter(func(destination:Dictionary)->bool: return String(destination.get("civ_id",""))==civ_id)
	assert_array(low_intelligence).is_empty()
	system.civilizations[0].player_relation["contact_intelligence"]=0.65
	var mapped:=(system.military_movement_destinations() as Array).filter(func(destination:Dictionary)->bool: return String(destination.get("civ_id",""))==civ_id)
	assert_int(mapped.size()).is_equal(system.STRATEGIC_REGIONS_PER_CIV)
	system.revealed_areas.clear()
	system._add_revealed_area(Vector2.ZERO,72.0,"founding knowledge")
	var outside_chart:=(system.military_movement_destinations() as Array).filter(func(destination:Dictionary)->bool: return String(destination.get("civ_id",""))==civ_id)
	assert_array(outside_chart).is_empty()


func test_scouts_reveal_nothing_until_their_return_then_chart_route_and_contact()->void:
	_hide_all_contacts()
	system.register_player_origin(Vector2.ZERO)
	var original_areas:=(system.fog_snapshot().areas as Array).size()
	var food_before:=FoodSystem.total_stored()
	var short_quote:Dictionary=system.scout_mission_quote(30)
	var long_quote:Dictionary=system.scout_mission_quote(365)
	assert_float(float(long_quote.provisions)).is_greater(float(short_quote.provisions))
	var sent:Dictionary=system.dispatch_scouts(365)
	assert_bool(bool(sent.get("ok",false))).is_true()
	assert_int(GameState.food_issue_history.size()).is_equal(1)
	var scout_issue:Dictionary=GameState.food_issue_history[0]
	assert_str(String(scout_issue.category)).is_equal("scouting")
	assert_float(float(scout_issue.amount)).is_equal_approx(float((system.scout_missions[0] as Dictionary).provisions),0.001)
	assert_int(int(scout_issue.duration_days)).is_equal(365)
	assert_float(float(scout_issue.stock_before)-float(scout_issue.stock_after)).is_equal_approx(float(scout_issue.amount),0.001)
	assert_bool(bool(scout_issue.charged_at_departure)).is_true()
	assert_bool(bool(scout_issue.recurring)).is_false()
	var food_account:Dictionary=FoodSystem.food_account_snapshot(365)
	assert_int((food_account.active_mission_provisions as Array).size()).is_equal(1)
	assert_float(float(food_account.withdrawn_today)).is_equal_approx(float(scout_issue.amount),0.001)
	var commitments:Dictionary=system.player_population_commitments()
	assert_int(int(commitments.total_absent)).is_equal(int((system.scout_missions[0] as Dictionary).personnel))
	assert_int(int((commitments.by_function as Dictionary).productive)).is_equal(int((system.scout_missions[0] as Dictionary).personnel))
	assert_int(int(system.player_population_function_profile().accounted)).is_equal(GameState.population_total)
	# Put one test polity on the already-generated expedition route. Production
	# worlds remain planetary in scale; this fixture proves that an actual crossed
	# route becomes contact only after the physical report returns.
	var mission_route:Array=(system.scout_missions[0] as Dictionary).route
	var encounter_waypoint:Dictionary=mission_route[mission_route.size()/2]
	var contact_civ:Dictionary=system.civilizations[0]
	contact_civ["position"]=Vector2(float(encounter_waypoint.x)/18000.0,float(encounter_waypoint.z)/9000.0)
	contact_civ["military_readiness"]=0.0
	contact_civ["logistics"]=0.0
	contact_civ["knowledge"]=0.0
	system.civilizations[0]=contact_civ
	system.scout_missions[0]["concealment"]=1.0
	system.scout_missions[0]["evasion"]=1.0
	assert_float(FoodSystem.total_stored()).is_less(food_before)
	assert_float(float(system.player_effects().get("scout_labor_absence",0.0))).is_greater(0.0)
	var in_transit_map:Dictionary=system.discovery_map_snapshot()
	assert_bool(bool(in_transit_map.active_scout_party)).is_true()
	assert_int((in_transit_map.returned_reports as Array).size()).is_equal(0)
	assert_bool(in_transit_map.has("active_route")).is_false()
	system.advance_to_day(364)
	assert_bool(bool(system.exploration_status().active)).is_true()
	assert_int((system.fog_snapshot().areas as Array).size()).is_equal(original_areas)
	assert_int(int(system.known_competition_snapshot().contacted_count)).is_equal(0)
	system.advance_to_day(365)
	assert_bool(bool(system.exploration_status().active)).is_false()
	assert_float(float(system.player_effects().get("scout_labor_absence",0.0))).is_equal(0.0)
	assert_int(int(system.player_population_commitments().total_absent)).is_equal(0)
	assert_int((system.fog_snapshot().areas as Array).size()).is_greater(original_areas)
	assert_int(int(system.exploration_status().report_count)).is_equal(1)
	var returned_map:Dictionary=system.discovery_map_snapshot()
	assert_bool(bool(returned_map.active_scout_party)).is_false()
	assert_int((returned_map.returned_reports as Array).size()).is_equal(1)
	assert_int((((returned_map.returned_reports as Array)[0] as Dictionary).route as Array).size()).is_greater(1)
	assert_int(int(system.known_competition_snapshot().contacted_count)).is_greater_equal(1)
	var latest_report:Dictionary=system.exploration_status().latest_report
	assert_int((latest_report.get("contact_records",[]) as Array).size()).is_equal((latest_report.get("contacts",[]) as Array).size())
	assert_int(system.contact_encounters_snapshot().size()).is_greater_equal(1)
	for encounter_variant in system.contact_encounters_snapshot():
		var encounter:Dictionary=encounter_variant
		assert_str(String(encounter.source)).is_equal("returned_scout_report")
		assert_bool((encounter.position as Dictionary).has("x")).is_true()
		assert_bool((encounter.position as Dictionary).has("z")).is_true()
	assert_array(system.validate_state()).is_empty()


func test_returned_scout_trail_reveals_only_its_narrow_physical_corridor()->void:
	system.revealed_areas.clear()
	var route:Array=[{"x":0.0,"z":0.0},{"x":1000.0,"z":1000.0},{"x":2000.0,"z":1000.0}]
	system._add_revealed_trail(route,18.0,"returned scout trail",90)
	assert_int(system.revealed_areas.size()).is_equal(1)
	var trail:Dictionary=system.revealed_areas[0]
	assert_str(String(trail.get("kind",""))).is_equal("trail")
	assert_int((trail.get("points",[]) as Array).size()).is_equal(3)
	assert_bool(system._position_is_revealed(Vector2(500.0,500.0))).is_true()
	assert_bool(system._position_is_revealed(Vector2(1500.0,1000.0))).is_true()
	# This point lies inside the route's enormous bounding rectangle but was never
	# crossed. A circle or bounding-region reveal would incorrectly expose it.
	assert_bool(system._position_is_revealed(Vector2(200.0,900.0))).is_false()
	assert_bool(system._position_is_revealed(Vector2(1000.0,1040.0))).is_false()
	assert_array(system.validate_state()).is_empty()


func test_v8_reveal_migration_removes_inflated_consolidated_circle_and_rebuilds_report_trail()->void:
	var old_state:Dictionary=system.export_state()
	old_state["version"]=8
	old_state["revealed_areas"]=[
		{"x":900.0,"z":500.0,"radius":4200.0,"source":"consolidated chart","day":50},
		{"x":0.0,"z":0.0,"radius":42.0,"source":"returned scout chart","day":90},
		{"x":1000.0,"z":1000.0,"radius":42.0,"source":"returned scout chart","day":90}
	]
	old_state["scout_reports"]=[{"day":90,"route":[{"x":0.0,"z":0.0},{"x":1000.0,"z":1000.0}],"return_route":[{"x":1000.0,"z":1000.0},{"x":0.0,"z":0.0}]}]
	var result:Dictionary=system.import_state(old_state)
	assert_bool(bool(result.get("ok",false))).is_true()
	var maximum_radius:=0.0
	var trails:=0
	for record_variant in system.revealed_areas:
		var record:Dictionary=record_variant
		maximum_radius=maxf(maximum_radius,float(record.get("radius",0.0)))
		if String(record.get("kind",""))=="trail": trails+=1
	assert_float(maximum_radius).is_less_equal(72.0)
	assert_int(trails).is_equal(1)
	assert_bool(system._position_is_revealed(Vector2(500.0,500.0))).is_true()
	assert_bool(system._position_is_revealed(Vector2(-1200.0,1800.0))).is_false()
	assert_array(system.validate_state()).is_empty()


func test_scout_route_planner_keeps_every_segment_on_authoritative_land()->void:
	system.set_scout_geography_authority(func(_position:Vector2)->bool: return true)
	var plan:Dictionary=system._plan_scout_land_route(Vector2.ZERO,Vector2(180.0,75.0))
	assert_bool(bool(plan.get("ok",false))).is_true()
	assert_str(String(plan.get("travel_mode",""))).is_equal("land")
	assert_bool(system._scout_route_is_land(plan.get("route",[]))).is_true()
	assert_float(float(plan.get("distance_km",0.0))).is_equal_approx(Vector2(180.0,75.0).length(),0.01)


func test_unknown_geography_is_not_silently_treated_as_land()->void:
	system.set_scout_geography_authority(Callable())
	var quote:Dictionary=system.scout_mission_quote(30,"open_world")
	assert_bool(bool(quote.get("can_dispatch",true))).is_false()
	assert_str(String(quote.get("blocker",""))).contains("Unknown ground cannot be assumed to be land")
	assert_bool(system.dispatch_scouts(30,"open_world").has("error")).is_true()


func test_scout_route_detours_around_a_peninsula_instead_of_drawing_through_water()->void:
	var peninsula_land:=func(position:Vector2)->bool:
		return not (position.x>=40.0 and position.x<=60.0 and absf(position.y)<=20.0)
	system.set_scout_geography_authority(peninsula_land)
	var plan:Dictionary=system._plan_scout_land_route(Vector2.ZERO,Vector2(100.0,0.0))
	assert_bool(bool(plan.get("ok",false))).is_true()
	var route:Array=plan.get("route",[])
	assert_int(route.size()).is_greater_equal(3)
	assert_bool(system._scout_route_is_land(route)).is_true()
	assert_float(float(plan.get("distance_km",0.0))).is_greater(100.0)
	var cleared_coast:=false
	for point_variant in route:
		var point:Dictionary=point_variant
		if absf(float(point.get("z",0.0)))>20.0: cleared_coast=true
	assert_bool(cleared_coast).is_true()


func test_ocean_separated_known_target_is_blocked_before_people_or_food_depart()->void:
	var separated_islands:=func(position:Vector2)->bool:
		return position.x<=20.0 or position.x>=80.0
	system.set_scout_geography_authority(separated_islands)
	system.register_player_origin(Vector2.ZERO)
	var civ:Dictionary=system.civilizations[0]
	civ.player_relation["contact_level"]=2
	civ.player_relation["home_location_known"]=true
	civ.player_relation["home_position"]={"x":100.0,"z":0.0}
	system.civilizations[0]=civ
	var food_before:=FoodSystem.total_stored()
	var target_id:="settlement:%s" % String(civ.id)
	var quote:Dictionary=system.scout_mission_quote(30,target_id)
	assert_bool(bool(quote.get("can_dispatch",true))).is_false()
	assert_str(String(quote.get("blocker",""))).contains("land-only route")
	var dispatch:Dictionary=system.dispatch_scouts(30,target_id)
	assert_bool(dispatch.has("error")).is_true()
	assert_float(FoodSystem.total_stored()).is_equal_approx(food_before,0.001)
	assert_array(system.scout_missions).is_empty()


func test_returned_report_and_world_map_preserve_the_exact_physical_land_trail()->void:
	var peninsula_land:=func(position:Vector2)->bool:
		return not (position.x>=40.0 and position.x<=60.0 and absf(position.y)<=20.0)
	system.set_scout_geography_authority(peninsula_land)
	system.register_player_origin(Vector2.ZERO)
	var civ:Dictionary=system.civilizations[0]
	civ.player_relation["contact_level"]=2
	civ.player_relation["home_location_known"]=true
	civ.player_relation["home_position"]={"x":100.0,"z":0.0}
	civ.player_relation["at_war"]=false
	system.civilizations[0]=civ
	var target_id:="settlement:%s" % String(civ.id)
	assert_bool(bool(system.dispatch_scouts(30,target_id).get("ok",false))).is_true()
	var departed_route:Array=((system.scout_missions[0] as Dictionary).route as Array).duplicate(true)
	assert_bool(system._scout_route_is_land(departed_route)).is_true()
	system.scout_missions[0]["concealment"]=1.0
	system.scout_missions[0]["evasion"]=1.0
	system.advance_to_day(30)
	assert_array(system.scout_missions).is_empty()
	var report:Dictionary=system.scout_reports[0]
	assert_array(report.route).is_equal(departed_route)
	assert_array(report.return_route).is_equal(system._reverse_scout_route(departed_route))
	assert_str(String(report.travel_mode)).is_equal("land")
	var map_report:Dictionary=(system.discovery_map_snapshot().returned_reports as Array)[0]
	assert_array(map_report.route).is_equal(departed_route)
	assert_array(map_report.return_route).is_equal(report.return_route)
	assert_bool(system._scout_route_is_land(map_report.route)).is_true()


func test_contact_sites_unlock_targeted_investigation_and_confirm_nearby_home_settlements()->void:
	var civ:Dictionary=system.civilizations[0]
	civ["position"]=Vector2(0.001,0.0)
	var relation:Dictionary=civ.player_relation
	relation["contact_level"]=2
	relation["contact_intelligence"]=0.25
	relation["met_day"]=1
	relation["contact_source"]="returned_scout_report"
	relation["contact_formation_kind"]="encountered people"
	relation["encounter_position"]={"x":0.0,"z":0.0}
	relation["home_location_known"]=false
	relation["home_position"]={}
	civ["player_relation"]=relation
	system.civilizations[0]=civ
	system.register_player_origin(Vector2.ZERO)
	var contact_target:="contact:%s" % String(civ.id)
	var target_ids:Array[String]=[]
	for option in system.scout_target_options(): target_ids.append(String(option.id))
	assert_array(target_ids).contains([contact_target])
	assert_bool(target_ids.has("settlement:%s" % String(civ.id))).is_false()
	var before_encounter:Dictionary=system.contact_encounters_snapshot()[0]
	assert_bool(bool(before_encounter.get("home_location_known",false))).is_false()
	assert_dict(before_encounter.get("home_position",{})).is_empty()
	assert_bool(bool(system.dispatch_scouts(30,contact_target).get("ok",false))).is_true()
	system.scout_missions[0]["concealment"]=1.0
	system.scout_missions[0]["evasion"]=1.0
	system.advance_to_day(30)
	var resolved:Dictionary=(system.civilizations[0].player_relation as Dictionary)
	assert_bool(bool(resolved.get("home_location_known",false))).is_true()
	assert_bool((resolved.get("home_position",{}) as Dictionary).has("x")).is_true()
	var settlement_target:="settlement:%s" % String(civ.id)
	target_ids.clear()
	for option in system.scout_target_options(): target_ids.append(String(option.id))
	assert_array(target_ids).contains([settlement_target])
	var confirmed_encounter:Dictionary=system.contact_encounters_snapshot()[0]
	assert_bool(bool(confirmed_encounter.get("home_location_known",false))).is_true()
	assert_bool((confirmed_encounter.get("home_position",{}) as Dictionary).has("x")).is_true()
	assert_array(system.validate_state()).is_empty()


func test_returning_scouts_can_recruit_a_small_aggregate_wandering_group()->void:
	var population_before:=GameState.population_total
	var recruitment_mission:Dictionary={"mission_id":99,"duration_days":365,"target_id":"open_world","target_kind":"explore"}
	var recruited:=0
	for day in range(1,200):
		recruited=system._resolve_scout_recruitment(recruitment_mission,day)
		if recruited>0: break
	assert_int(recruited).is_between(2,12)
	assert_int(GameState.population_total).is_equal(population_before+recruited)
	assert_float(float(GameState.population_cohorts.get("working_age",0.0))).is_greater(0.0)


func test_an_encounter_site_is_not_a_diplomatic_destination()->void:
	var civ:Dictionary=system.civilizations[0]
	var relation:Dictionary=civ.player_relation
	relation["contact_level"]=2
	relation["contact_source"]="returned_scout_report"
	relation["encounter_position"]={"x":24.0,"z":0.0}
	relation["home_location_known"]=false
	relation["home_position"]={}
	civ["player_relation"]=relation
	system.civilizations[0]=civ
	var quote:Dictionary=system.diplomatic_mission_quote(String(civ.id),"","open_trade")
	assert_bool(quote.has("error")).is_true()
	assert_str(String(quote.error)).contains("settlement is still unlocated")
	var leaked_destinations:=(system.military_movement_destinations() as Array).filter(func(destination:Dictionary)->bool: return String(destination.get("civ_id",""))==String(civ.id))
	assert_int(leaked_destinations.size()).is_equal(0)
	assert_bool(system.dispatch_diplomat(String(civ.id),"","open_trade").has("error")).is_true()
	assert_bool(bool(system.civilizations[0].player_relation.home_location_known)).is_false()
	assert_bool(bool(system.diplomatic_mission_status().active)).is_false()


func test_diplomats_carry_a_deducted_gift_and_report_only_after_the_round_trip()->void:
	var civ:Dictionary=system.civilizations[0]
	var relation:Dictionary=civ.player_relation
	relation["contact_level"]=2
	relation["contact_intelligence"]=0.30
	relation["contact_source"]="returned_scout_report"
	relation["encounter_position"]={"x":24.0,"z":0.0}
	relation["home_location_known"]=true
	relation["home_position"]={"x":24.0,"z":0.0}
	relation["home_location_source"]="returned contact investigation"
	relation["at_war"]=false
	civ["player_relation"]=relation
	system.civilizations[0]=civ
	system.register_player_origin(Vector2.ZERO)
	var quote:Dictionary=system.diplomatic_mission_quote(String(civ.id),"Food")
	assert_bool(bool(quote.get("ok",false))).is_true()
	var food_before:=FoodSystem.total_stored()
	var opinion_before:=float(relation.opinion)
	var intelligence_before:=float(relation.contact_intelligence)
	var revealed_before:int=system.revealed_areas.size()
	assert_bool(bool(system.dispatch_diplomat(String(civ.id),"Food").get("ok",false))).is_true()
	assert_float(FoodSystem.total_stored()).is_less(food_before)
	assert_int(GameState.food_issue_history.size()).is_equal(2)
	assert_str(String(GameState.food_issue_history[0].category)).is_equal("diplomacy")
	assert_bool(bool(system.diplomatic_mission_status().active)).is_true()
	var envoy_commitments:Dictionary=system.player_population_commitments()
	assert_int(int((envoy_commitments.by_function as Dictionary).support)).is_equal(int(quote.personnel))
	assert_float(float(system.player_effects().labor_absence)).is_greater(0.0)
	GameState.elapsed_days=float(quote.travel_days)
	system.advance_to_day(int(quote.travel_days))
	assert_str(String(system.diplomatic_mission_status().stage)).is_equal("returning")
	assert_int(system.diplomatic_history.size()).is_equal(0)
	assert_float(float(system.civilizations[0].player_relation.contact_intelligence)).is_equal_approx(intelligence_before,0.0001)
	assert_int(int(system.civilizations[0].player_relation.last_observed_day)).is_not_equal(int(quote.travel_days))
	assert_int(system.revealed_areas.size()).is_equal(revealed_before)
	GameState.elapsed_days=float(quote.total_days)
	system.advance_to_day(int(quote.total_days))
	assert_bool(bool(system.diplomatic_mission_status().active)).is_false()
	assert_int(system.diplomatic_history.size()).is_equal(1)
	assert_float(float((system.civilizations[0].player_relation as Dictionary).opinion)).is_greater(opinion_before)
	assert_float(float(system.civilizations[0].player_relation.contact_intelligence)).is_greater(intelligence_before)
	assert_int(int(system.civilizations[0].player_relation.last_observed_day)).is_equal(int(quote.total_days))
	assert_int((system.diplomatic_history[0].observations as Array).size()).is_greater_equal(3)
	assert_int(system.revealed_areas.size()).is_greater(revealed_before)
	assert_array(system.validate_state()).is_empty()


func test_treaties_require_a_physical_round_trip_and_distance_changes_the_delay()->void:
	var civ:Dictionary=system.civilizations[0]
	var civ_id:=String(civ.id)
	var relation:Dictionary=civ.player_relation
	relation["contact_level"]=2
	relation["contact_intelligence"]=0.35
	relation["contact_source"]="returned_scout_report"
	relation["encounter_position"]={"x":34.0,"z":0.0}
	relation["home_location_known"]=true
	relation["home_position"]={"x":34.0,"z":0.0}
	relation["home_location_source"]="returned contact investigation"
	relation["opinion"]=0.42
	relation["treaty"]="none"
	civ["player_relation"]=relation
	system.civilizations[0]=civ
	system.register_player_origin(Vector2.ZERO)
	var direct:Dictionary=system.conduct_player_action(civ_id,"open_trade")
	assert_bool(direct.has("error")).is_true()
	assert_bool(bool(direct.get("requires_envoy",false))).is_true()
	assert_str(String(system.civilizations[0].player_relation.treaty)).is_equal("none")
	var near_quote:Dictionary=system.diplomatic_mission_quote(civ_id,"","open_trade")
	assert_bool(bool(near_quote.get("ok",false))).is_true()
	system.civilizations[0].player_relation["home_position"]={"x":340.0,"z":0.0}
	var far_quote:Dictionary=system.diplomatic_mission_quote(civ_id,"","open_trade")
	assert_int(int(far_quote.total_days)).is_greater(int(near_quote.total_days))
	system.civilizations[0].player_relation["home_position"]={"x":34.0,"z":0.0}
	assert_bool(bool(system.dispatch_diplomat(civ_id,"","open_trade").get("ok",false))).is_true()
	assert_str(String(system.civilizations[0].player_relation.treaty)).is_equal("none")
	GameState.elapsed_days=float(near_quote.travel_days)
	system.advance_to_day(int(near_quote.travel_days))
	assert_str(String(system.diplomatic_mission_status().stage)).is_equal("returning")
	assert_str(String(system.civilizations[0].player_relation.treaty)).is_equal("none")
	GameState.elapsed_days=float(near_quote.total_days)
	system.advance_to_day(int(near_quote.total_days))
	assert_bool(bool(system.diplomatic_mission_status().active)).is_false()
	assert_str(String(system.civilizations[0].player_relation.treaty)).is_equal("trade")
	assert_bool(bool(system.diplomatic_history[0].accepted)).is_true()
	assert_array(system.validate_state()).is_empty()


func test_computer_civilizations_also_wait_for_carried_treaty_messages()->void:
	var first:Dictionary=system.civilizations[0]
	var second:Dictionary=system.civilizations[1]
	first["position"]=Vector2(0.10,0.10)
	second["position"]=Vector2(0.105,0.10)
	system.civilizations[0]=first
	system.civilizations[1]=second
	var relation:Dictionary=(first.relations as Dictionary).get(String(second.id),{})
	relation["opinion"]=0.70
	relation["border_tension"]=0.05
	relation["treaty"]="none"
	relation["at_war"]=false
	relation["pending_message"]=""
	system._set_pair_relation(0,1,relation)
	system._process_intercivilization_relations(30)
	var proposed:Dictionary=(system.civilizations[0].relations as Dictionary)[String(second.id)]
	assert_str(String(proposed.get("treaty","none"))).is_equal("none")
	assert_str(String(proposed.get("pending_message",""))).is_equal("trade")
	var due_day:=int(proposed.get("pending_message_due_day",-1))
	assert_int(due_day).is_greater(30)
	system._process_intercivilization_relations(due_day-1)
	var in_transit:Dictionary=(system.civilizations[0].relations as Dictionary)[String(second.id)]
	assert_str(String(in_transit.get("treaty","none"))).is_equal("none")
	system._process_intercivilization_relations(due_day)
	var delivered:Dictionary=(system.civilizations[0].relations as Dictionary)[String(second.id)]
	assert_str(String(delivered.get("treaty","none"))).is_equal("trade")
	assert_str(String(delivered.get("pending_message",""))).is_equal("")


func test_war_declaration_begins_when_the_carried_message_arrives_not_at_departure()->void:
	var civ:Dictionary=system.civilizations[0]
	var civ_id:=String(civ.id)
	civ.player_relation["contact_source"]="returned_scout_report"
	civ.player_relation["encounter_position"]={"x":51.0,"z":0.0}
	civ.player_relation["home_location_known"]=true
	civ.player_relation["home_position"]={"x":51.0,"z":0.0}
	civ.player_relation["home_location_source"]="returned contact investigation"
	civ.player_relation["at_war"]=false
	civ.player_relation["treaty"]="none"
	system.civilizations[0]=civ
	system.register_player_origin(Vector2.ZERO)
	var quote:Dictionary=system.diplomatic_mission_quote(civ_id,"","declare_war")
	assert_bool(bool(quote.get("ok",false))).is_true()
	assert_bool(bool(system.dispatch_diplomat(civ_id,"","declare_war").get("ok",false))).is_true()
	assert_bool(bool(system.civilizations[0].player_relation.at_war)).is_false()
	GameState.elapsed_days=float(int(quote.travel_days)-1)
	system.advance_to_day(int(quote.travel_days)-1)
	assert_bool(bool(system.civilizations[0].player_relation.at_war)).is_false()
	GameState.elapsed_days=float(quote.travel_days)
	system.advance_to_day(int(quote.travel_days))
	assert_bool(bool(system.civilizations[0].player_relation.at_war)).is_true()
	assert_str(String(system.diplomatic_mission_status().stage)).is_equal("returning")


func test_planetary_geography_prevents_automatic_early_contact()->void:
	_hide_all_contacts()
	system.register_player_origin(Vector2.ZERO)
	var nearest_home:=INF
	for civ in system.civilizations: nearest_home=minf(nearest_home,system._civilization_world_position(civ).length())
	assert_float(nearest_home).is_greater_equal(2000.0)
	for formation in system.foreign_formations:
		var closest:=Geometry2D.get_closest_point_to_segment(Vector2.ZERO,formation.point_a,formation.point_b)
		assert_float(closest.length()).is_greater(1000.0)
	assert_bool(bool(system.dispatch_scouts(180).get("ok",false))).is_true()
	system.advance_to_day(180)
	assert_int(int(system.known_competition_snapshot().contacted_count)).is_equal(0)
	assert_int(int(system.local_observation_snapshot().visible_count)).is_equal(0)
	assert_array(system.validate_state()).is_empty()


func test_intercepted_player_scouts_lose_the_entire_unreturned_report()->void:
	_hide_all_contacts()
	system.register_player_origin(Vector2.ZERO)
	var original_areas:=(system.fog_snapshot().areas as Array).size()
	var population_before:=GameState.population_total
	assert_bool(bool(system.dispatch_scouts(90).get("ok",false))).is_true()
	var route:Array=(system.scout_missions[0] as Dictionary).route
	var hazard_waypoint:Dictionary=route[route.size()/2]
	var intercepting_civ:Dictionary=system.civilizations[0]
	intercepting_civ["position"]=Vector2(float(hazard_waypoint.x)/18000.0,float(hazard_waypoint.z)/9000.0)
	system.civilizations[0]=intercepting_civ
	var interception:Dictionary=system._resolve_player_scout_interception(system.scout_missions[0],90,0.0,1.0)
	assert_bool(bool(interception.get("intercepted",false))).is_true()
	assert_str(String(interception.get("fate",""))).is_equal("destroyed")
	system._fail_player_scout_mission(system.scout_missions[0],interception,90)
	assert_bool(bool(system.exploration_status().active)).is_false()
	assert_int((system.fog_snapshot().areas as Array).size()).is_equal(original_areas)
	assert_int(int(system.exploration_status().report_count)).is_equal(0)
	assert_int(int(system.known_competition_snapshot().contacted_count)).is_equal(0)
	assert_int(GameState.population_total).is_less(population_before)
	assert_str(String(system.exploration_status().last_outcome.message)).not_contains("civ_")
	assert_array(system.validate_state()).is_empty()


func test_foreign_scouts_report_only_after_homecoming_and_can_be_captured()->void:
	_hide_all_contacts()
	system.register_player_origin(Vector2.ZERO)
	var scout_index:int=-1
	for index in system.foreign_formations.size():
		if String(system.foreign_formations[index].kind)=="scout": scout_index=index; break
	assert_int(scout_index).is_greater_equal(0)
	var scout:Dictionary=system.foreign_formations[scout_index]
	var civ_id:String=String(scout.civ_id)
	scout["point_a"]=Vector2(40.0,0.0)
	scout["point_b"]=Vector2.ZERO
	scout["depart_day"]=0
	scout["disabled_until_day"]=0
	scout["evaded_until_day"]=0
	scout["leg_days"]=10.0
	scout["last_report_cycle"]=0
	scout["concealment"]=0.0
	scout["evasion"]=0.0
	system.foreign_formations[scout_index]=scout
	system._process_foreign_scout_reports(19)
	var civ_index:int=int(system._civilization_index(civ_id))
	assert_float(float(system.civilizations[civ_index].player_relation.rival_player_intelligence)).is_equal(0.0)
	system._process_foreign_scout_reports(20)
	assert_float(float(system.civilizations[civ_index].player_relation.rival_player_intelligence)).is_greater(0.0)
	# Reset the carried report and catch the party before its next homecoming.
	var relation:Dictionary=system.civilizations[civ_index].player_relation
	relation["rival_player_intelligence"]=0.0
	relation["rival_contact_level"]=0
	var reset_civ:Dictionary=system.civilizations[civ_index]
	reset_civ["player_relation"]=relation
	system.civilizations[civ_index]=reset_civ
	GameState.elapsed_days=21.0
	scout=system.foreign_formations[scout_index]
	scout["depart_day"]=21
	scout["disabled_until_day"]=0
	scout["evaded_until_day"]=0
	scout["last_report_cycle"]=0
	scout["point_a"]=Vector2.ZERO
	scout["point_b"]=Vector2.ZERO
	system.foreign_formations[scout_index]=scout
	system._process_local_observation(21,true)
	var capture:Dictionary=system.resolve_foreign_scout_interception(String(scout.id),"capture",0.0)
	assert_bool(bool(capture.get("success",false))).is_true()
	assert_bool(bool(capture.get("report_denied",false))).is_true()
	assert_int(system.foreign_scout_reports_denied).is_equal(1)
	assert_int(system.captured_scouts_snapshot().size()).is_equal(1)
	assert_int(int(MilitaryCampaign.prisoner_custody_snapshot().prisoners)).is_greater(0)
	system._process_foreign_scout_reports(41)
	assert_float(float(system.civilizations[civ_index].player_relation.rival_player_intelligence)).is_equal(0.0)
	assert_array(system.validate_state()).is_empty()


func test_captured_scouts_support_questioning_coercion_and_unreliable_torture()->void:
	_hide_all_contacts()
	system.register_player_origin(Vector2.ZERO)
	var scout_index:int=-1
	for index in system.foreign_formations.size():
		if String(system.foreign_formations[index].kind)=="scout": scout_index=index; break
	var scout:Dictionary=system.foreign_formations[scout_index]
	scout["point_a"]=Vector2.ZERO
	scout["point_b"]=Vector2(80.0,0.0)
	scout["depart_day"]=0
	scout["disabled_until_day"]=0
	scout["evaded_until_day"]=0
	scout["concealment"]=0.0
	scout["evasion"]=0.0
	scout["strength_share"]=0.20
	system.foreign_formations[scout_index]=scout
	GameState.elapsed_days=1.0
	system._process_local_observation(1,true)
	var capture:Dictionary=system.resolve_foreign_scout_interception(String(scout.id),"capture",0.0)
	var civ_id:String=String(capture.civilization_id)
	var intel_before:float=float(system.civilizations[system._civilization_index(civ_id)].player_relation.contact_intelligence)
	var questioning:Dictionary=system.interrogate_captured_scouts(civ_id,"question",0.0,0.0)
	assert_bool(bool(questioning.get("truthful",false))).is_true()
	assert_float(float(questioning.get("intelligence_gain",0.0))).is_greater(0.0)
	assert_float(float(system.civilizations[system._civilization_index(civ_id)].player_relation.contact_intelligence)).is_greater(intel_before)
	GameState.elapsed_days=2.0
	var legitimacy_before:float=float(GameState.simulation_metrics.legitimacy)
	var cohesion_before:float=float(GameState.simulation_metrics.cohesion)
	var torture:Dictionary=system.interrogate_captured_scouts(civ_id,"torture",0.0,0.99)
	assert_bool(bool(torture.get("disclosed",false))).is_true()
	assert_bool(bool(torture.get("truthful",true))).is_false()
	assert_float(float(GameState.simulation_metrics.legitimacy)).is_less(legitimacy_before)
	assert_float(float(GameState.simulation_metrics.cohesion)).is_less(cohesion_before)
	assert_float(float(MilitaryCampaign.war_reputation_snapshot().grievance)).is_greater(0.0)
	assert_array(system.validate_state()).is_empty()


func test_every_contender_uses_the_same_score_pillars_and_victory_gates()->void:
	var snapshot:Dictionary=system.competition_snapshot()
	for contender_variant in snapshot.leaders:
		var contender:Dictionary=contender_variant
		assert_int((contender.score_breakdown as Dictionary).size()).is_equal(system.SCORE_DOMAINS.size())
		assert_dict(contender.victory_requirements).contains_keys(["sustainability","rank","domains","lead_margin","currently_qualifies"])
	var player:Dictionary=(snapshot.leaders as Array).filter(func(entry:Dictionary)->bool: return String(entry.id)=="player")[0]
	var rival:Dictionary=(snapshot.leaders as Array).filter(func(entry:Dictionary)->bool: return String(entry.id)!="player")[0]
	for field in ["controlled_population","knowledge","production","logistics","health","cohesion","institutions","territory","military_population","military_readiness","food_days"]:
		rival[field]=player[field]
	assert_float(float(system._score_values(rival))).is_equal_approx(float(system._score_values(player)),0.0001)


func test_contacts_do_not_reveal_the_scoring_ontology_without_social_knowledge()->void:
	var knowledge:Dictionary=system.strategic_knowledge_snapshot()
	assert_int(int(knowledge.stage)).is_equal(0)
	assert_bool(bool(knowledge.framework_known)).is_false()
	assert_int(int(knowledge.total_domains)).is_equal(-1)
	assert_array(knowledge.known_domains).is_empty()
	var known:Dictionary=system.known_competition_snapshot()
	assert_int(int(known.player_rank)).is_equal(-1)
	assert_dict(known.leader).is_empty()
	assert_dict(known.domain_leaders).is_empty()
	assert_str(String(known.victory_rule)).not_contains("seven")
	for profile_variant in known.leaders:
		var profile:Dictionary=profile_variant
		assert_bool(profile.has("score")).is_false()
		assert_bool(profile.has("score_breakdown")).is_false()
		assert_bool(profile.has("victory_requirements")).is_false()


func test_records_contact_and_inference_progressively_reveal_strategic_comparison()->void:
	GameState.known_discoveries.assign(["tallies","standard_measures"])
	GameState.discovery_adoption={"tallies":0.40,"standard_measures":0.40}
	var measures:Dictionary=system.strategic_knowledge_snapshot()
	assert_int(int(measures.stage)).is_equal(2)
	assert_int((measures.known_domains as Array).size()).is_equal(4)
	assert_int(int(measures.total_domains)).is_equal(-1)
	GameState.known_discoveries.assign(["tallies","standard_measures","census_rolls"])
	GameState.discovery_adoption["census_rolls"]=0.40
	var framework:Dictionary=system.strategic_knowledge_snapshot()
	assert_int(int(framework.stage)).is_equal(3)
	assert_int(int(framework.total_domains)).is_equal(system.SCORE_DOMAINS.size())
	assert_bool(bool(framework.exact_scoring_known)).is_false()
	assert_bool((system.known_competition_snapshot().leaders[0] as Dictionary).has("score")).is_false()
	GameState.known_discoveries.append("statistical_inference")
	GameState.discovery_adoption["statistical_inference"]=0.50
	var formal:Dictionary=system.strategic_knowledge_snapshot()
	assert_int(int(formal.stage)).is_equal(4)
	assert_bool(bool(formal.exact_scoring_known)).is_true()
	var known:Dictionary=system.known_competition_snapshot()
	assert_int(int(known.player_rank)).is_greater(0)
	assert_bool((known.leaders[0] as Dictionary).has("score")).is_true()
	assert_str(String(known.victory_rule)).contains("seven")


func test_world_uses_fixed_aggregate_civilization_records()->void:
	assert_int(system.civilizations.size()).is_between(system.MIN_RIVAL_CIVILIZATIONS,system.MAX_RIVAL_CIVILIZATIONS)
	assert_int(system.foreign_formations.size()).is_equal(system.civilizations.size()*system.FOREIGN_FORMATIONS_PER_CIV)
	for civ in system.civilizations:
		assert_int((civ.cohorts as Dictionary).size()).is_equal(6)
		assert_int((civ.strategic_regions as Array).size()).is_equal(system.STRATEGIC_REGIONS_PER_CIV)
		assert_float(float(civ.population)).is_greater(0.0)
	assert_array(system.validate_state()).is_empty()


func test_excess_mobilization_is_withheld_from_civilian_functions_and_labor()->void:
	GameState.ensure_population_total(100_000)
	var allocated_defense:=int(GameState.population_allocations.Defense)
	MilitaryCampaign.aggregate_recruits=allocated_defense+4_000
	var military_commitment:Dictionary=MilitaryCampaign.population_commitment_snapshot()
	assert_int(int(military_commitment.excess_beyond_defense)).is_equal(4_000)
	assert_int((military_commitment.records as Array).size()).is_equal(4)
	var commitments:Dictionary=system.player_population_commitments()
	assert_int(int(commitments.mobilized_total)).is_equal(allocated_defense+4_000)
	var profile:Dictionary=system.player_population_function_profile()
	assert_int(int(profile.accounted)).is_equal(GameState.population_total)
	assert_int(int(profile.mobilized)).is_equal(allocated_defense+4_000)
	assert_int(int((profile.mobilized_from as Dictionary).productive)).is_equal(4_000)
	assert_int(int(system.player_effects().mobilization_labor_displacement)).is_equal(4_000)
	assert_float(float(system.player_effects().labor_absence)).is_greater(0.0)


func test_new_world_starts_isolated_without_forced_foreign_visitors()->void:
	_hide_all_contacts()
	var routes_before:Array[Dictionary]=system.foreign_formations.duplicate(true)
	system.register_player_origin(Vector2.ZERO)
	var observation:Dictionary=system.local_observation_snapshot()
	assert_int(int(observation.visible_count)).is_equal(0)
	assert_int(int(system.known_competition_snapshot().contacted_count)).is_equal(0)
	assert_array(system.foreign_formations).is_equal(routes_before)
	for civ in system.civilizations:
		assert_int(int(civ.player_relation.contact_level)).is_equal(0)
		assert_int(int(civ.player_relation.met_day)).is_equal(-1)
	assert_array(system.validate_state()).is_empty()


func test_nearby_foreign_formation_is_visible_before_its_civilization_is_known()->void:
	_hide_all_contacts()
	system.register_player_origin(Vector2.ZERO)
	var formation:Dictionary=system.foreign_formations[0]
	formation["point_a"]=Vector2(24.0,0.0)
	formation["point_b"]=Vector2(24.0,0.0)
	formation["depart_day"]=0
	formation["leg_days"]=60.0
	system.foreign_formations[0]=formation
	system._process_local_observation(1,true)
	var observation:Dictionary=system.local_observation_snapshot()
	assert_int(int(observation.visible_count)).is_greater_equal(1)
	var sighting:Dictionary=(observation.visible as Array).filter(func(entry:Dictionary)->bool: return String(entry.id)==String(formation.id))[0]
	assert_bool(bool(sighting.identified)).is_false()
	assert_str(String(sighting.label)).is_equal("UNIDENTIFIED FOREIGN FORMATION")
	assert_bool(sighting.has("readiness")).is_false()
	assert_float(float(sighting.readiness_estimate_low)).is_less(float(formation.readiness))
	assert_float(float(sighting.readiness_estimate_high)).is_greater(float(formation.readiness))
	assert_int(int(system.civilizations[0].player_relation.contact_level)).is_equal(1)
	assert_dict(system.known_civilization_snapshot(String(system.civilizations[0].id))).is_empty()
	assert_array(system.contact_encounters_snapshot()).is_empty()
	var sighting_events:=(GameState.simulation_events as Array).filter(func(event:Dictionary)->bool: return String(event.get("kind",""))=="unit_sighting")
	assert_int(sighting_events.size()).is_equal(1)
	assert_str(String(sighting_events[0].title)).is_equal("Foreign unit sighted")
	assert_float(float((sighting_events[0].position as Dictionary).x)).is_equal_approx(24.0,0.01)
	assert_array(system.validate_state()).is_empty()


func test_departed_formation_report_is_historical_not_live_tracking()->void:
	_hide_all_contacts()
	system.register_player_origin(Vector2.ZERO)
	var formation:Dictionary=system.foreign_formations[0]
	formation["point_a"]=Vector2(24.0,0.0)
	formation["point_b"]=Vector2(24.0,0.0)
	formation["depart_day"]=0
	formation["leg_days"]=60.0
	system.foreign_formations[0]=formation
	system._process_local_observation(1,true)
	var observed:Dictionary=(system.local_observation_snapshot().visible as Array).filter(func(entry:Dictionary)->bool: return String(entry.id)==String(formation.id))[0]
	var observed_position:Dictionary=(observed.position as Dictionary).duplicate(true)
	var observed_day:=int(observed.last_seen_day)
	formation=system.foreign_formations[0]
	formation["point_a"]=Vector2(500.0,0.0)
	formation["point_b"]=Vector2(600.0,0.0)
	formation["depart_day"]=2
	system.foreign_formations[0]=formation
	system._process_local_observation(2,true)
	var snapshot:Dictionary=system.local_observation_snapshot()
	assert_int((snapshot.visible as Array).filter(func(entry:Dictionary)->bool: return String(entry.id)==String(formation.id)).size()).is_equal(0)
	var historical:Dictionary=(snapshot.recent as Array).filter(func(entry:Dictionary)->bool: return String(entry.id)==String(formation.id))[0]
	assert_bool(bool(historical.visible)).is_false()
	assert_int(int(historical.last_seen_day)).is_equal(observed_day)
	assert_float(float((historical.position as Dictionary).x)).is_equal_approx(float(observed_position.x),0.001)
	assert_int((system.discovery_map_snapshot().visible_formations as Array).filter(func(entry:Dictionary)->bool: return String(entry.id)==String(formation.id)).size()).is_equal(0)


func test_formation_entering_direct_contact_range_reveals_its_civilization()->void:
	_hide_all_contacts()
	system.register_player_origin(Vector2.ZERO)
	var formation:Dictionary=system.foreign_formations[0]
	formation["point_a"]=Vector2(4.0,0.0)
	formation["point_b"]=Vector2(4.0,0.0)
	formation["depart_day"]=0
	formation["leg_days"]=60.0
	system.foreign_formations[0]=formation
	system._process_local_observation(2,true)
	var observation:Dictionary=system.local_observation_snapshot()
	var sighting:Dictionary=(observation.visible as Array).filter(func(entry:Dictionary)->bool: return String(entry.id)==String(formation.id))[0]
	assert_bool(bool(sighting.identified)).is_true()
	assert_int(int(system.civilizations[0].player_relation.contact_level)).is_equal(2)
	assert_dict(system.known_civilization_snapshot(String(system.civilizations[0].id))).is_not_empty()
	var relation:Dictionary=system.civilizations[0].player_relation
	assert_str(String(relation.contact_source)).is_equal("local_formation")
	assert_float(float((relation.encounter_position as Dictionary).x)).is_equal_approx(4.0,0.01)
	var contact_events:=(GameState.simulation_events as Array).filter(func(event:Dictionary)->bool: return String(event.get("kind",""))=="first_contact")
	assert_int(contact_events.size()).is_equal(1)
	assert_str(String(contact_events[0].title)).contains(String(system.civilizations[0].name))
	assert_array(system.validate_state()).is_empty()


func test_campaign_front_exposes_exactly_one_enemy_region_at_a_time()->void:
	var civ:Dictionary=system.civilizations[0]
	var targets:Array=system.campaign_targets(String(civ.id))
	assert_int(targets.size()).is_equal(system.STRATEGIC_REGIONS_PER_CIV)
	var available:=targets.filter(func(region:Dictionary)->bool: return bool(region.available))
	assert_int(available.size()).is_equal(1)
	assert_int(int(available[0].approach_index)).is_equal(0)
	var blocked:Dictionary=system.offensive_campaign_data(String(civ.id),50,String(targets[1].id))
	assert_bool(blocked.has("error")).is_true()


func test_war_plans_are_explicit_bounded_and_lock_when_war_begins()->void:
	var civ_id:=String(system.civilizations[0].id)
	var target:Dictionary=system.campaign_targets(civ_id)[0]
	var options:Array=system.war_goal_options(civ_id,String(target.id))
	assert_int(options.size()).is_equal(3)
	assert_bool(bool(options[0].available)).is_true()
	var planned:Dictionary=system.set_player_war_goal(civ_id,"break_power",String(target.id))
	assert_bool(bool(planned.get("ok",false))).is_true()
	assert_str(String(system.civilizations[0].player_relation.war_goal)).is_equal("break_power")
	assert_bool(bool(system.conduct_player_action(civ_id,"declare_war",true).get("ok",false))).is_true()
	assert_bool(system.set_player_war_goal(civ_id,"limited",String(target.id)).has("error")).is_true()
	assert_array(system.validate_state()).is_empty()


func test_limited_objective_capture_creates_war_score_and_completion()->void:
	var civ:Dictionary=system.civilizations[0]
	var civ_id:=String(civ.id)
	var target:Dictionary=system.campaign_targets(civ_id)[0]
	assert_bool(bool(system.set_player_war_goal(civ_id,"limited",String(target.id)).get("ok",false))).is_true()
	assert_bool(bool(system.conduct_player_action(civ_id,"declare_war",true).get("ok",false))).is_true()
	var result:={"home_side":"attacker","campaign_mode":"offensive","target_region_id":String(target.id),"attacker":{"name":"HOME HOST","dead":1},"defender":{"name":String(civ.name),"dead":3},"termination":{"type":"surrender","captor":"HOME HOST","defeated":String(civ.name),"prisoners":1}}
	system.resolve_player_battle(civ_id,result)
	var objective:Dictionary=system.war_objective_status(civ_id)
	assert_bool(bool(objective.complete)).is_true()
	assert_float(float(system.civilizations[0].player_relation.war_score)).is_greater(0.0)
	assert_float(float(system.civilizations[0].player_relation.rival_war_exhaustion)).is_greater(0.0)


func test_strategic_forecast_uses_real_defender_and_changes_outlook_not_enemy_size()->void:
	var civ_id:=String(system.civilizations[0].id)
	var target:Dictionary=system.campaign_targets(civ_id)[0]
	MilitaryCampaign.home_army={"troops":5,"readiness":0.45,"supply_level":0.80,"formations":[]}
	var weak:Dictionary=system.strategic_assessment(civ_id,String(target.id))
	MilitaryCampaign.home_army={"troops":5000,"readiness":0.90,"supply_level":1.0,"formations":[]}
	var strong:Dictionary=system.strategic_assessment(civ_id,String(target.id))
	assert_int(int(weak.enemy_estimate)).is_equal(int(strong.enemy_estimate))
	assert_float(float(strong.power_ratio)).is_greater(float(weak.power_ratio))
	assert_str(String(weak.outlook)).is_not_equal(String(strong.outlook))


func test_war_exhaustion_ripples_into_player_effects_and_recovers_in_peace()->void:
	var civ:Dictionary=system.civilizations[0]
	civ.player_relation["at_war"]=true
	civ.player_relation["treaty"]="war"
	civ.player_relation["war_goal"]="defend"
	system.civilizations[0]=civ
	system.advance_to_day(30)
	var wartime:=float(system.player_effects().war_exhaustion)
	assert_float(wartime).is_greater(0.0)
	system.civilizations[0].player_relation["at_war"]=false
	system.civilizations[0].player_relation["treaty"]="truce"
	system.advance_to_day(60)
	assert_float(float(system.civilizations[0].player_relation.player_war_exhaustion)).is_less(wartime)


func test_same_seed_produces_the_same_competitors()->void:
	var first:Array=system.export_state().civilizations
	system.reset_for_new_world()
	_set_all_contacted_and_located()
	assert_array(system.export_state().civilizations).is_equal(first)


func test_strategic_turn_changes_population_strategy_and_power_without_growing_state_shape()->void:
	var records:int=system.civilizations.size()
	var relations:int=(system.civilizations[0].relations as Dictionary).size()
	var before_population:=float(system.civilizations[0].population)
	system.advance_to_day(3650)
	assert_int(system.civilizations.size()).is_equal(records)
	assert_int((system.civilizations[0].relations as Dictionary).size()).is_equal(relations)
	assert_float(float(system.civilizations[0].population)).is_not_equal(before_population)
	assert_bool(system.STRATEGIES.has(String(system.civilizations[0].strategy))).is_true()
	assert_array(system.validate_state()).is_empty()


func test_player_foreign_policy_changes_real_trade_and_war_state()->void:
	var civ:Dictionary=system.civilizations[0]
	civ.player_relation["opinion"]=0.40
	system.civilizations[0]=civ
	var trade:Dictionary=system.conduct_player_action(String(civ.id),"open_trade",true)
	assert_bool(bool(trade.get("ok",false))).is_true()
	assert_int(int(system.player_effects().active_trade_partners)).is_equal(1)
	var war:Dictionary=system.conduct_player_action(String(civ.id),"declare_war",true)
	assert_bool(bool(war.get("ok",false))).is_true()
	assert_bool(bool(system.civilizations[0].player_relation.at_war)).is_true()
	assert_int(system.pending_player_incidents.size()).is_equal(0)
	var offensive:Dictionary=system.offensive_campaign_data(String(civ.id),50)
	assert_bool(offensive.has("error")).is_false()
	assert_int(int(offensive.strength)).is_between(3,88)
	assert_float(float(offensive.terrain_defense)).is_between(1.04,1.22)


func test_standing_actions_are_idempotent_and_cannot_create_contradictory_war_state()->void:
	var civ_id:=String(system.civilizations[0].id)
	system.civilizations[0].player_relation["opinion"]=0.40
	assert_bool(bool(system.conduct_player_action(civ_id,"open_trade",true).get("ok",false))).is_true()
	var opinion_after_trade:=float(system.civilizations[0].player_relation.opinion)
	assert_bool(system.conduct_player_action(civ_id,"open_trade",true).has("error")).is_true()
	assert_float(float(system.civilizations[0].player_relation.opinion)).is_equal(opinion_after_trade)
	assert_bool(bool(system.conduct_player_action(civ_id,"declare_war",true).get("ok",false))).is_true()
	assert_bool(system.conduct_player_action(civ_id,"declare_war",true).has("error")).is_true()
	assert_bool(system.conduct_player_action(civ_id,"contain").has("error")).is_true()
	assert_str(String(system.civilizations[0].player_relation.treaty)).is_equal("war")
	assert_float(float(system.civilizations[0].player_relation.trade)).is_equal(0.0)


func test_food_aid_is_removed_from_authoritative_typed_stores_and_cannot_reappear()->void:
	FoodSystem.reset_for_new_world()
	FoodSystem.initialize()
	var before:=float(GameState.resource_stockpiles.get("Food",0.0))
	var result:Dictionary=system.conduct_player_action(String(system.civilizations[0].id),"send_aid",true)
	assert_bool(bool(result.get("ok",false))).is_true()
	var after:=float(GameState.resource_stockpiles.get("Food",0.0))
	assert_float(after).is_less(before)
	FoodSystem._sync_total()
	assert_float(float(GameState.resource_stockpiles.get("Food",0.0))).is_equal_approx(after,0.0001)


func test_peace_removes_queued_incidents_and_stale_incidents_are_never_consumed()->void:
	var civ:Dictionary=system.civilizations[0]
	civ.player_relation["at_war"]=true
	civ.player_relation["treaty"]="war"
	civ.player_relation["opinion"]=0.60
	civ.player_relation["last_incident_day"]=-9999
	system.civilizations[0]=civ
	system._queue_player_incident_if_due(civ,civ.player_relation,120)
	assert_int(system.pending_player_incidents.size()).is_equal(1)
	var peace:Dictionary=system.conduct_player_action(String(civ.id),"seek_peace",true)
	assert_bool(bool(peace.get("ok",false))).is_true()
	assert_int(system.pending_player_incidents.size()).is_equal(0)
	assert_dict(system.consume_player_incident()).is_empty()
	assert_int(int(system.civilizations[0].player_relation.truce_until_day)).is_greater(int(GameState.elapsed_days))
	assert_bool(system.conduct_player_action(String(civ.id),"declare_war",true).has("error")).is_true()


func test_non_turn_updates_cannot_advance_victory_and_terminal_outcomes_do_not_revert()->void:
	var civ_id:=String(system.civilizations[0].id)
	system.civilizations[0].player_relation["opinion"]=0.40
	system.dominance_turns=5
	assert_bool(bool(system.conduct_player_action(civ_id,"open_trade",true).get("ok",false))).is_true()
	assert_int(system.dominance_turns).is_equal(5)
	system.competition_outcome="victory"
	system.advance_to_day(30)
	assert_str(system.competition_outcome).is_equal("victory")


func test_rival_battle_accounting_uses_the_actual_enemy_side_and_enemy_prisoners_only()->void:
	var civ:Dictionary=system.civilizations[0]
	var before_population:=float(civ.population)
	var before_military:=float(civ.military_population)
	var before_wins:=int(civ.wars_won)
	var result:={"home_side":"defender","attacker":{"name":String(civ.name),"dead":7},"defender":{"name":"HOME HOST","dead":3},"termination":{"type":"surrender","captor":String(civ.name),"defeated":"HOME HOST","prisoners":20}}
	system.resolve_player_battle(String(civ.id),result)
	assert_float(float(system.civilizations[0].population)).is_equal_approx(before_population-7.0,0.0001)
	assert_float(float(system.civilizations[0].military_population)).is_equal_approx(maxf(0.0,before_military-7.0),0.0001)
	assert_int(int(system.civilizations[0].wars_won)).is_equal(before_wins+1)


func test_territory_moves_only_when_the_campaign_direction_can_change_control()->void:
	var civ:Dictionary=system.civilizations[0]
	var civ_id:=String(civ.id)
	var rival_before:=float(civ.territory)
	var player_before:float=system._player_territory()
	var offensive_win:={"home_side":"attacker","campaign_mode":"offensive","attacker":{"name":"HOME HOST","dead":0},"defender":{"name":String(civ.name),"dead":0},"termination":{"type":"surrender","captor":"HOME HOST","defeated":String(civ.name),"prisoners":0}}
	system.resolve_player_battle(civ_id,offensive_win)
	assert_float(float(system.civilizations[0].territory)).is_equal_approx(rival_before-0.025,0.0001)
	assert_float(system._player_territory()).is_equal_approx(player_before+0.025,0.0001)
	var rival_after_conquest:=float(system.civilizations[0].territory)
	var player_after_conquest:float=system._player_territory()
	var offensive_loss:={"home_side":"attacker","campaign_mode":"offensive","attacker":{"name":"HOME HOST","dead":0},"defender":{"name":String(civ.name),"dead":0},"termination":{"type":"surrender","captor":String(civ.name),"defeated":"HOME HOST","prisoners":0}}
	system.resolve_player_battle(civ_id,offensive_loss)
	assert_float(float(system.civilizations[0].territory)).is_equal_approx(rival_after_conquest,0.0001)
	assert_float(system._player_territory()).is_equal_approx(player_after_conquest,0.0001)
	var defensive_loss:=offensive_loss.duplicate(true)
	defensive_loss["home_side"]="defender"
	defensive_loss["campaign_mode"]="defensive"
	defensive_loss["attacker"]={"name":String(civ.name),"dead":0}
	defensive_loss["defender"]={"name":"HOME HOST","dead":0}
	system.resolve_player_battle(civ_id,defensive_loss)
	assert_float(float(system.civilizations[0].territory)).is_equal_approx(rival_after_conquest+0.018,0.0001)
	assert_float(system._player_territory()).is_equal_approx(player_after_conquest-0.018,0.0001)


func test_decisive_offensive_victory_captures_the_selected_region_and_unlocks_the_next()->void:
	var civ:Dictionary=system.civilizations[0]
	var civ_id:=String(civ.id)
	var target:Dictionary=system.campaign_targets(civ_id)[0]
	var rival_territory_before:=float(civ.territory)
	var controlled_before:=float(system._public_profile(civ).controlled_population)
	var result:={"home_side":"attacker","campaign_mode":"offensive","target_region_id":String(target.id),"attacker":{"name":"HOME HOST","dead":1},"defender":{"name":String(civ.name),"dead":2},"termination":{"type":"surrender","captor":"HOME HOST","defeated":String(civ.name),"prisoners":1}}
	var outcome:Dictionary=system.resolve_player_battle(civ_id,result)
	assert_bool(bool(outcome.get("region_captured",false))).is_true()
	assert_str(String(system.region_snapshot(civ_id,String(target.id)).controller)).is_equal("player")
	assert_float(float(system.civilizations[0].territory)).is_less(rival_territory_before)
	assert_float(float(system._public_profile(system.civilizations[0]).controlled_population)).is_less(controlled_before)
	var next_targets:Array=system.campaign_targets(civ_id)
	assert_bool(bool(next_targets[1].available)).is_true()
	assert_bool(bool(next_targets[0].available)).is_false()
	assert_array(system.validate_state()).is_empty()


func test_recapture_restores_the_same_region_and_does_not_manufacture_territory()->void:
	var civ:Dictionary=system.civilizations[0]
	var civ_id:=String(civ.id)
	var target:Dictionary=system.campaign_targets(civ_id)[0]
	var starting_rival_territory:=float(civ.territory)
	var starting_player_balance:float=system.player_territory_balance
	var capture_result:={"home_side":"attacker","campaign_mode":"offensive","target_region_id":String(target.id),"attacker":{"name":"HOME HOST","dead":0},"defender":{"name":String(civ.name),"dead":0},"termination":{"type":"surrender","captor":"HOME HOST","defeated":String(civ.name),"prisoners":0}}
	system.resolve_player_battle(civ_id,capture_result)
	var recapture_result:={"home_side":"defender","campaign_mode":"defensive","target_region_id":String(target.id),"attacker":{"name":String(civ.name),"dead":0},"defender":{"name":"HOME HOST","dead":0},"termination":{"type":"surrender","captor":String(civ.name),"defeated":"HOME HOST","prisoners":0}}
	var outcome:Dictionary=system.resolve_player_battle(civ_id,recapture_result)
	assert_bool(bool(outcome.get("region_recaptured",false))).is_true()
	assert_str(String(system.region_snapshot(civ_id,String(target.id)).controller)).is_equal(civ_id)
	assert_float(float(system.civilizations[0].territory)).is_equal_approx(starting_rival_territory,0.0001)
	assert_float(system.player_territory_balance).is_equal_approx(starting_player_balance,0.0001)


func test_unsupported_occupation_creates_relief_resistance_and_uprising_pressure()->void:
	var civ:Dictionary=system.civilizations[0]
	var civ_id:=String(civ.id)
	var target:Dictionary=system.campaign_targets(civ_id)[0]
	var capture_result:={"home_side":"attacker","campaign_mode":"offensive","target_region_id":String(target.id),"attacker":{"name":"HOME HOST","dead":0},"defender":{"name":String(civ.name),"dead":0},"termination":{"type":"surrender","captor":"HOME HOST","defeated":String(civ.name),"prisoners":0}}
	system.resolve_player_battle(civ_id,capture_result)
	var region:Dictionary=system.civilizations[0].strategic_regions[0]
	region["occupation_turns"]=3
	region["resistance"]=0.88
	region["integration"]=0.0
	region["damage"]=0.30
	system.civilizations[0].strategic_regions[0]=region
	var pressure:Dictionary=system._occupation_uprising_pressure(system.civilizations[0])
	assert_bool(bool(pressure.get("eligible",false))).is_true()
	assert_float(float(pressure.get("chance",0.0))).is_greater(0.06)
	var effects:Dictionary=system.player_effects()
	assert_float(float(effects.occupation_relief_demand)).is_greater(0.0)
	assert_float(float(effects.occupation_burden)).is_greater(0.0)


func test_total_urban_control_changes_strategy_status_and_peace_leverage()->void:
	var civ_id:=String(system.civilizations[0].id)
	for region_index in system.STRATEGIC_REGIONS_PER_CIV:
		var civ:Dictionary=system.civilizations[0]
		var target:Dictionary=system.campaign_targets(civ_id)[region_index]
		var capture_result:={"home_side":"attacker","campaign_mode":"offensive","target_region_id":String(target.id),"attacker":{"name":"HOME HOST","dead":0},"defender":{"name":String(civ.name),"dead":0},"termination":{"type":"surrender","captor":"HOME HOST","defeated":String(civ.name),"prisoners":0}}
		system.resolve_player_battle(civ_id,capture_result)
	var occupied:Dictionary=system._player_occupation_status(system.civilizations[0])
	assert_int(int(occupied.region_count)).is_equal(system.STRATEGIC_REGIONS_PER_CIV)
	assert_bool(bool(occupied.capital_occupied)).is_true()
	assert_str(system._choose_strategy(system.civilizations[0])).is_equal("fortification")
	var profile:Dictionary=system._public_profile(system.civilizations[0])
	assert_int(int(profile.home_regions_controlled)).is_equal(0)
	assert_str(String(profile.strategic_status)).is_equal("CAPITAL LOST")
	system.civilizations[0].player_relation["at_war"]=true
	system.civilizations[0].player_relation["treaty"]="war"
	system.civilizations[0].player_relation["opinion"]=-0.60
	assert_bool(system.player_action_availability(civ_id,"seek_peace").has("error")).is_false()


func test_foreign_ai_holding_is_reachable_and_liberated_without_starting_a_hidden_occupation()->void:
	var occupier:Dictionary=system.civilizations[0]
	var original_owner:Dictionary=system.civilizations[1]
	var ai_result:Dictionary=system._resolve_ai_region_control(occupier,original_owner,true,30)
	assert_bool(bool(ai_result.changed)).is_true()
	system.civilizations[0]=ai_result.first
	system.civilizations[1]=ai_result.second
	var occupied_region_id:=String(ai_result.region_id)
	var targets:Array=system.campaign_targets(String(occupier.id))
	var foreign_targets:=targets.filter(func(region:Dictionary)->bool: return bool(region.get("foreign_holding",false)))
	assert_int(foreign_targets.size()).is_equal(1)
	assert_bool(bool(foreign_targets[0].available)).is_true()
	system.civilizations[0].player_relation["at_war"]=true
	system.civilizations[0].player_relation["treaty"]="war"
	var campaign:Dictionary=system.offensive_campaign_data(String(occupier.id),100,occupied_region_id)
	assert_bool(campaign.has("error")).is_false()
	assert_bool(bool(campaign.liberation_campaign)).is_true()
	var territory_before:=float(system.civilizations[0].territory)+float(system.civilizations[1].territory)
	var battle:={"home_side":"attacker","campaign_mode":"offensive","target_region_id":occupied_region_id,"attacker":{"name":"HOME HOST","dead":0},"defender":{"name":String(occupier.name),"dead":0},"termination":{"type":"surrender","captor":"HOME HOST","defeated":String(occupier.name),"prisoners":0}}
	var outcome:Dictionary=system.resolve_player_battle(String(occupier.id),battle)
	assert_bool(bool(outcome.get("region_liberated",false))).is_true()
	assert_str(String(system.region_snapshot(String(original_owner.id),occupied_region_id).controller)).is_equal(String(original_owner.id))
	assert_float(float(system.civilizations[0].territory)+float(system.civilizations[1].territory)).is_equal_approx(territory_before,0.0001)
	assert_float(float(system.player_territory_balance)).is_equal(0.0)
	assert_array(system.validate_state()).is_empty()


func test_import_rejects_incomplete_or_asymmetric_state_without_mutating_live_world()->void:
	var original:Dictionary=system.export_state()
	var incomplete:Dictionary=original.duplicate(true)
	incomplete.civilizations[0].erase("position")
	assert_bool(system.import_state(incomplete).has("error")).is_true()
	assert_array(system.export_state().civilizations).is_equal(original.civilizations)
	var asymmetric:Dictionary=original.duplicate(true)
	var first_id:=String(asymmetric.civilizations[0].id)
	var second_id:=String(asymmetric.civilizations[1].id)
	asymmetric.civilizations[0].relations[second_id]["opinion"]=0.99
	assert_bool(system.import_state(asymmetric).has("error")).is_true()
	assert_array(system.export_state().civilizations).is_equal(original.civilizations)
	var malformed:Dictionary=original.duplicate(true)
	malformed.civilizations[0]["allocations"]=[]
	assert_bool(system.import_state(malformed).has("error")).is_true()
	assert_array(system.export_state().civilizations).is_equal(original.civilizations)


func test_export_survives_a_real_json_round_trip()->void:
	var civ:Dictionary=system.civilizations[0]
	var target:Dictionary=system.campaign_targets(String(civ.id))[0]
	system.resolve_player_battle(String(civ.id),{"home_side":"attacker","campaign_mode":"offensive","target_region_id":String(target.id),"attacker":{"name":"HOME HOST","dead":0},"defender":{"name":String(civ.name),"dead":0},"termination":{"type":"surrender","captor":"HOME HOST","defeated":String(civ.name),"prisoners":0}})
	var encoded:=JSON.stringify(system.export_state())
	var parsed:Variant=JSON.parse_string(encoded)
	assert_bool(parsed is Dictionary).is_true()
	var imported:Dictionary=system.import_state(parsed)
	assert_bool(bool(imported.get("ok",false))).is_true()
	assert_str(String(system.region_snapshot(String(civ.id),String(target.id)).controller)).is_equal("player")
	assert_array(system.validate_state()).is_empty()
	assert_int(JSON.stringify(system.export_state()).length()).is_less(250_000)


func test_age_cohorts_change_over_time_and_continue_to_conserve_population()->void:
	var before:Dictionary=system.civilizations[0].cohorts.duplicate(true)
	var before_population:=float(system.civilizations[0].population)
	system.advance_to_day(3650)
	var after:Dictionary=system.civilizations[0].cohorts
	assert_float(float(after.children)/float(system.civilizations[0].population)).is_not_equal(float(before.children)/before_population)
	assert_array(system.validate_state()).is_empty()


func test_victory_is_attainable_from_aggregate_domain_leadership()->void:
	GameState.ensure_population_total(1_000_000_000_000)
	GameState.population_health=0.99
	GameState.food_security=1.0
	GameState.combined_intelligence=1.0
	GameState.simulation_metrics.merge({"material_capacity":1.0,"logistics":1.0,"cohesion":1.0,"security":1.0,"food_days":180.0,"legitimacy":1.0},true)
	GameState.society_capacities["institutions"]=1.0
	MilitaryCampaign.aggregate_recruits=300_000_000_000
	system.advance_to_day(20*365+12*30)
	assert_str(system.competition_outcome).is_equal("victory")
	assert_int(system.dominance_turns).is_greater_equal(12)


func test_rival_wins_only_by_satisfying_the_same_twelve_turn_rule()->void:
	var rival:Dictionary=system.civilizations[0]
	rival["population"]=1_000_000_000.0
	rival["cohorts"]=system._scaled_cohorts(rival.cohorts,1_000_000_000.0)
	rival["knowledge"]=1.0
	rival["production"]=1.0
	rival["logistics"]=1.0
	rival["health"]=1.0
	rival["cohesion"]=1.0
	rival["institutions"]=1.0
	rival["food_days"]=180.0
	rival["territory"]=4.0
	rival["military_population"]=100_000_000.0
	rival["military_readiness"]=1.0
	system.civilizations[0]=rival
	for turn in 12:
		system._rebuild_competition(true,20*365+(turn+1)*30)
	assert_str(system.competition_outcome).is_equal("defeat")
	assert_str(system.competition_winner_id).is_equal(String(rival.id))
	assert_int(int(system.contender_dominance_turns.get(String(rival.id),0))).is_equal(12)


func test_defeat_requires_twelve_monthly_collapse_turns_under_real_hostility()->void:
	GameState.population_health=0.05
	GameState.food_security=0.05
	GameState.simulation_metrics["legitimacy"]=0.05
	for index in system.civilizations.size():
		system.civilizations[index].player_relation["at_war"]=true
		system.civilizations[index].player_relation["treaty"]="war"
		system.civilizations[index].player_relation["border_tension"]=1.0
	system.advance_to_day(12*30)
	assert_str(system.competition_outcome).is_equal("defeat")
	assert_int(system.collapse_turns).is_equal(12)


func test_rivals_trade_and_fight_each_other_without_player_scripts()->void:
	system.advance_to_day(36_500)
	var interactions:=0
	var wars_recorded:=0
	for civ in system.civilizations:
		for other_id in (civ.relations as Dictionary):
			if String(civ.id)>=String(other_id): continue
			var relation:Dictionary=civ.relations[other_id]
			if bool(relation.get("at_war",false)) or float(relation.get("trade",0.0))>0.0: interactions+=1
	for event in system.world_events:
		if String(event.get("domain",""))=="war": wars_recorded+=1
	assert_int(interactions).is_greater(0)
	assert_int(wars_recorded).is_greater(0)


func test_competition_includes_player_and_every_rival_with_explicit_victory_state()->void:
	var snapshot:Dictionary=system.competition_snapshot()
	assert_int((snapshot.leaders as Array).size()).is_equal(system.civilizations.size()+1)
	assert_int(int(snapshot.player_rank)).is_between(1,system.civilizations.size()+1)
	assert_bool(["ongoing","victory","defeat"].has(String(snapshot.outcome))).is_true()
	assert_str(String(snapshot.victory_rule)).contains("four strategic domains")


func test_billion_scale_does_not_change_record_count_or_save_size_class()->void:
	GameState.ensure_population_total(1_000_000_000)
	for index in system.civilizations.size():
		var civ:Dictionary=system.civilizations[index]
		civ["population"]=1_000_000_000.0
		civ["cohorts"]=system._scaled_cohorts(civ.cohorts,1_000_000_000.0)
		system.civilizations[index]=civ
	system.advance_to_day(36_500)
	assert_int(system.civilizations.size()).is_between(system.MIN_RIVAL_CIVILIZATIONS,system.MAX_RIVAL_CIVILIZATIONS)
	# Richer bounded war, intelligence, and travel histories increased the fixed
	# record payload without making it depend on population; the payload scales
	# only with the world's drawn rival count, never with entity counts.
	assert_int(JSON.stringify(system.export_state()).length()).is_less(60_000+system.civilizations.size()*30_000)
	assert_array(system.validate_state()).is_empty()


func test_rivals_pay_for_training_and_develop_command_under_the_same_strategy_layer()->void:
	var rival:Dictionary=system.civilizations[0].duplicate(true)
	rival["strategy"]="expansion"
	rival["knowledge"]=0.70
	rival["institutions"]=0.65
	rival["logistics"]=0.70
	rival["food_days"]=80.0
	rival["command_readiness"]=0.40
	rival["military_readiness"]=0.45
	var food_before:=float(rival.food_days)
	var command_before:=float(rival.command_readiness)
	var readiness_before:=float(rival.military_readiness)
	var cycles_before:=int(rival.get("training_cycles",0))
	var advanced:Dictionary=system._advance_rival_military_training(rival,{"military":0.30},0.0)
	assert_str(String(advanced.training_focus)).is_equal("war_games")
	assert_float(float(advanced.food_days)).is_less(food_before)
	assert_float(float(advanced.command_readiness)).is_greater(command_before)
	assert_float(float(advanced.military_readiness)).is_greater(readiness_before)
	assert_int(int(advanced.training_cycles)).is_equal(cycles_before+1)
	assert_bool(not advanced.has("generals") and not advanced.has("units")).is_true()


func test_every_rival_automatically_chooses_the_same_kind_of_founding_focus()->void:
	var represented:Dictionary={}
	for rival in system.civilizations:
		var focus_id:=String(rival.get("founding_focus",""))
		assert_bool(focus_id in GameState.FOUNDING_FOCUS_ORDER).is_true()
		represented[focus_id]=true
		assert_bool(not rival.has("founders") and not rival.has("citizens")).is_true()
	assert_int(represented.size()).is_equal(GameState.FOUNDING_FOCUS_ORDER.size())
	assert_array(system.validate_state()).is_empty()


func test_foreign_founding_focus_requires_sustained_intelligence()->void:
	var civ_id:=String(system.civilizations[0].id)
	var rival:Dictionary=system.civilizations[0]
	rival.player_relation["contact_intelligence"]=0.40
	system.civilizations[0]=rival
	assert_str(String(system.known_civilization_snapshot(civ_id).get("founding_focus",""))).is_equal("unknown")
	rival=system.civilizations[0]
	rival.player_relation["contact_intelligence"]=0.70
	system.civilizations[0]=rival
	assert_str(String(system.known_civilization_snapshot(civ_id).get("founding_focus","unknown"))).is_equal(String(rival.founding_focus))


func test_founding_focus_creates_comparative_strengths_from_equal_inputs()->void:
	var base:Dictionary={"population":120.0,"food_days":30.0,"food_capacity":120.0,"health":0.65,"cohesion":0.55,"knowledge":0.20,"production":0.20,"logistics":0.20,"institutions":0.25,"ecology":0.80,"military_readiness":0.45,"command_readiness":0.40,"military_share":0.05,"military_population":6.0,"diplomacy":0.45}
	var inquiry:=base.duplicate(true); inquiry["founding_focus"]="inquiry"; inquiry=system._apply_rival_founding_focus_start(inquiry)
	var industry:=base.duplicate(true); industry["founding_focus"]="industry"; industry=system._apply_rival_founding_focus_start(industry)
	var defense:=base.duplicate(true); defense["founding_focus"]="defense"; defense=system._apply_rival_founding_focus_start(defense)
	assert_float(float(inquiry.knowledge)).is_greater(float(industry.knowledge))
	assert_float(float(industry.production)).is_greater(float(inquiry.production))
	assert_float(float(defense.military_readiness)).is_greater(float(inquiry.military_readiness))
	assert_float(float(defense.command_readiness)).is_greater(float(inquiry.command_readiness))

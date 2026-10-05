extends GdUnitTestSuite
## Peoples live far apart in one region of the planet (civilization_start.gd:
## about 1,100 km between neighbours), so nobody is met in the first decades and the court has no foreign business
## until someone's party really walks that far. Twenty generated worlds, each
## measured between the real founding sites (local_terrain._civilization_start),
## with contact decided by the real code paths: our returned party
## (_complete_scout_mission) and their parties seen from home or on our road
## (_process_local_observation, _resolve_route_military_sightings).
const Start=preload("res://scripts/civilization_start.gd")
const Controller=preload("res://scripts/civilization_controller.gd")
const Hall=preload("res://scripts/audience_hall.gd")

const SEEDS:=[7932,15851,23770,31689,39608,47527,55446,63365,71284,79203,87122,95041,102960,110879,118798,126717,134636,142555,150474,158393]
## No foreign town may stand within this distance of one of ours unless someone
## travels far. 1,000 km is about two months' walk at a caravan's 16 km a day,
## and a young people's known country (110 km, 18 km more a year) reaches that
## far only after about fifty years.
const FAR_RADIUS_KM:=900.0
## The boldest ruler settles new towns this far from home (civilization_strategy.gd
## settle_distance, 16 + 24 × boldness).
const BOLDEST_SETTLE_KM:=40.0
## A founding camp that finds no water where it stands moves at most this far
## before founding (civilization_controller.gd, the founding search).
const FOUNDING_MOVE_KM:=40.0
## Nobody even glimpses anybody for this many years, with the route lore a
## people has by then (the route_speed of a few wayfinding practices).
const GLIMPSE_YEARS:=15
const GLIMPSE_LORE:=0.3
## Nobody reaches anybody's home for this many years, even with route lore at
## the engine's cap (no mounts in the stone age).
const MEET_YEARS:=25
const LORE_CAP:=0.6

var _sites:Dictionary={}
var _opponents:=12

func before()->void:
	_opponents=GameState.opponent_count
	GameState.opponent_count=12

func after()->void:
	GameState.opponent_count=_opponents
	Hall.envoys_only=false

func before_test()->void:
	WorldSimulation.clear()
	GameState.set_process(false); CivilizationSystem.set_process(false); MilitaryCampaign.set_process(false)

func after_test()->void:
	Hall.envoys_only=false

## The world for `seed`: every people (ours first) at its real founding site,
## as start_world puts them. Returns those sites.
func _world(seed_value:int)->Array:
	GameState.reset_for_new_world(seed_value);GameState.civic_api_enabled=false
	CivilizationSystem.reset_for_new_world();ForeignDiplomacy.reset_for_new_world()
	if not _sites.has(seed_value):
		var terrain=preload("res://scripts/local_terrain.gd").new()
		terrain._configure_seamless_world();terrain._configure_shape();terrain._configure_noise();terrain._prepare_river_course()
		var sites:Array=[terrain._civilization_start(Start.candidate(seed_value,0))]
		for civ:Dictionary in CivilizationSystem.civilizations:sites.append(terrain._civilization_start(CivilizationSystem._civilization_world_position(civ)))
		terrain.free()
		_sites[seed_value]=sites
	var sites:Array=_sites[seed_value]
	CivilizationSystem.player_world_origin=sites[0]
	for index in CivilizationSystem.civilizations.size():
		var site:Vector2=sites[index+1]
		CivilizationSystem.civilizations[index].position=Vector2(site.x/CivilizationSystem.CIVILIZATION_WORLD_RADIUS_X_KM,site.y/CivilizationSystem.CIVILIZATION_WORLD_RADIUS_Z_KM)
	CivilizationSystem.foreign_formations.clear()
	GameState.settlement_site_committed=true;GameState.settlement_founded_day=0;GameState.settlement_completed=["Hearth Circle"]
	return sites

## Known country after `years` with route lore `lore` (scout_known_reach_km).
func _reach(years:int,lore:float)->float:
	return CivilizationSystem.SCOUT_KNOWN_REACH_START_KM+float(years)*CivilizationSystem.SCOUT_KNOWN_REACH_KM_PER_YEAR*(1.0+lore*1.5)

## Every party of every people at the edge of its known country, walking
## straight at the others: theirs toward us, ours toward each of them and all
## round. Contact is then whatever the real paths make of it.
func _walk_to_the_edges(sites:Array,reach:float,day:int,seed_value:int)->void:
	var home:Vector2=sites[0]
	GameState.elapsed_days=day
	for index in CivilizationSystem.civilizations.size():
		var theirs:Vector2=sites[index+1]
		var edge:=theirs+theirs.direction_to(home)*reach
		CivilizationSystem.foreign_formations.append({"id":"far_test_%d" % index,"civ_id":String(CivilizationSystem.civilizations[index].id),"kind":"scout","point_a":theirs,"point_b":edge,"command_position":{"x":edge.x,"z":edge.y},"depart_day":0,"leg_days":float(day),"strength_share":.01,"readiness":.5,"concealment":.0,"evasion":.0,"disabled_until_day":0,"evaded_until_day":0,"last_interception_day":-9999})
	CivilizationSystem._process_local_observation(day,true)
	var bearings:Array=[]
	for index in range(1,sites.size()):bearings.append(home.direction_to(sites[index]))
	for spoke in 12:bearings.append(Vector2.from_angle(TAU*float(spoke)/12.0))
	var route:Array=[]
	for bearing:Vector2 in bearings:
		var edge:=home+bearing*reach
		route.append({"x":home.x,"z":home.y});route.append({"x":edge.x,"z":edge.y})
	route.append({"x":home.x,"z":home.y})
	var party:={"mission_id":900+seed_value%97,"start_day":day-365,"duration_days":365,"personnel":6,"target_kind":"long_journey","route":route}
	CivilizationSystem.scout_missions.append(party)
	CivilizationSystem._complete_scout_mission(party,day)

func _contact_levels()->Dictionary:
	var levels:={}
	for civ:Dictionary in CivilizationSystem.civilizations:
		var level:=int((civ.player_relation as Dictionary).get("contact_level",0))
		if level>0:levels[String(civ.name)]=level
	return levels

func test_every_people_lives_far_from_every_other()->void:
	for seed_value:int in SEEDS:
		GameState.reset_for_new_world(seed_value)
		CivilizationSystem.reset_for_new_world()
		assert_int(CivilizationSystem.civilizations.size()).is_equal(12)
		var seats:Array=[Start.candidate(seed_value,0)]
		for civ:Dictionary in CivilizationSystem.civilizations:
			var seat:=CivilizationSystem._civilization_world_position(civ)
			assert_float(Start.separation(seat,seats)).override_failure_message("seed %d: %s is %.0f km from another people" % [seed_value,String(civ.name),Start.separation(seat,seats)]).is_greater_equal(Start.SEAT_SEPARATION_KM)
			assert_bool(Start.supports_founders(PlanetEnvironment.profile_at(seat))).is_true()
			seats.append(seat)

func test_no_foreign_town_can_stand_near_ours_without_long_journeys()->void:
	# The farthest any people's leaders found a town from their first site:
	# the founding camp's move, then the boldest settling ring around home.
	var ring:=0.0
	for point:Vector2 in Controller.expansion_candidates(Vector2.ZERO,BOLDEST_SETTLE_KM):ring=maxf(ring,point.length())
	var spread:=FOUNDING_MOVE_KM+ring
	for seed_value:int in SEEDS:
		var sites:=_world(seed_value)
		for index in range(1,sites.size()):
			var gap:=(sites[0] as Vector2).distance_to(sites[index])-2.0*spread
			assert_float(gap).override_failure_message("seed %d: a town of people %d could stand %.0f km from one of ours" % [seed_value,index,gap]).is_greater_equal(FAR_RADIUS_KM)

func test_nobody_is_even_glimpsed_in_the_first_three_decades()->void:
	for seed_value:int in SEEDS:
		var sites:=_world(seed_value)
		_walk_to_the_edges(sites,_reach(GLIMPSE_YEARS,GLIMPSE_LORE),GLIMPSE_YEARS*365,seed_value)
		assert_dict(_contact_levels()).override_failure_message("seed %d: seen %s within %d years" % [seed_value,str(_contact_levels()),GLIMPSE_YEARS]).is_empty()

func test_nobody_is_met_in_the_first_four_decades_even_with_the_most_route_lore()->void:
	var day:=MEET_YEARS*365
	var reach:=_reach(MEET_YEARS,LORE_CAP)
	for seed_value:int in SEEDS:
		var sites:=_world(seed_value)
		GameState.elapsed_days=day
		assert_float(CivilizationSystem.scout_known_reach_km()).is_less_equal(reach)
		_walk_to_the_edges(sites,reach,day,seed_value)
		# Parties may glimpse each other on the road (in some worlds they do);
		# nobody reaches anyone's home.
		for civ:Dictionary in CivilizationSystem.civilizations:
			assert_int(int((civ.player_relation as Dictionary).get("contact_level",0))).override_failure_message("seed %d: met %s within %d years" % [seed_value,String(civ.name),MEET_YEARS]).is_less(2)
			assert_dict(ForeignDiplomacy.civilization(String(civ.id))).is_empty()
		# A glimpse on the road brings no envoy and no foreign business to the hall.
		Hall.envoys_only=true
		for later in range(day,day+30):
			GameState.elapsed_days=later
			assert_array(Hall.daily(later)).is_empty()
		assert_array((Hall.state().occasions as Array).filter(func(o:Variant)->bool:return o is Dictionary and String((o as Dictionary).get("civ_id",""))!="")).is_empty()

func test_a_party_that_walks_all_the_way_meets_them()->void:
	var sites:=_world(SEEDS[0])
	var day:=120*365
	GameState.elapsed_days=day
	var home:Vector2=sites[0]
	var nearest:=1
	for index in range(1,sites.size()):
		if home.distance_to(sites[index])<home.distance_to(sites[nearest]):nearest=index
	var theirs:Vector2=sites[nearest]
	# Turning back well short of their country meets no one.
	var short:=home+home.direction_to(theirs)*(home.distance_to(theirs)-300.0)
	var turned:={"mission_id":71,"start_day":day-400,"duration_days":400,"personnel":6,"target_kind":"long_journey","route":[{"x":home.x,"z":home.y},{"x":short.x,"z":short.y},{"x":home.x,"z":home.y}]}
	CivilizationSystem.scout_missions.append(turned)
	CivilizationSystem._complete_scout_mission(turned,day)
	assert_int(int(CivilizationSystem.civilizations[nearest-1].player_relation.get("contact_level",0))).is_equal(0)
	# Walking on to their home is first contact, told as our scouts' report.
	var there:=theirs-home.direction_to(theirs)*20.0
	var reached:={"mission_id":72,"start_day":day-400,"duration_days":400,"personnel":6,"target_kind":"long_journey","route":[{"x":home.x,"z":home.y},{"x":there.x,"z":there.y},{"x":home.x,"z":home.y}]}
	CivilizationSystem.scout_missions.append(reached)
	CivilizationSystem._complete_scout_mission(reached,day+1)
	var met:Dictionary=CivilizationSystem.civilizations[nearest-1]
	assert_int(int(met.player_relation.get("contact_level",0))).is_equal(2)
	assert_str(String(met.player_relation.get("contact_source",""))).is_equal("returned_scout_report")
	# Their party that really walks into our home country is met the same way.
	var other_index:=nearest%CivilizationSystem.civilizations.size()
	var other:Dictionary=CivilizationSystem.civilizations[other_index]
	CivilizationSystem.foreign_formations.append({"id":"far_test_arrival","civ_id":String(other.id),"kind":"scout","point_a":sites[other_index+1],"point_b":home,"command_position":{"x":home.x,"z":home.y},"depart_day":0,"leg_days":float(day),"strength_share":.01,"readiness":.5,"concealment":.0,"evasion":.0,"disabled_until_day":0,"evaded_until_day":0,"last_interception_day":-9999})
	CivilizationSystem._process_local_observation(day+2,true)
	other=CivilizationSystem.civilizations[other_index]
	assert_int(int(other.player_relation.get("contact_level",0))).is_equal(2)
	assert_str(String(other.player_relation.get("contact_source",""))).is_equal("local_formation")

func test_before_contact_the_court_has_no_foreign_business()->void:
	_world(SEEDS[1])
	Hall.envoys_only=true
	for day in range(1,3*365):
		GameState.elapsed_days=day
		assert_array(Hall.daily(day)).is_empty()
	for civ:Dictionary in CivilizationSystem.civilizations:assert_dict(ForeignDiplomacy.civilization(String(civ.id))).is_empty()
	assert_array((Hall.state().occasions as Array).filter(func(o:Variant)->bool:return o is Dictionary and String((o as Dictionary).get("civ_id",""))!="")).is_empty()
	assert_array(Hall.waiting()).is_empty()

func test_a_saved_world_keeps_its_peoples_where_they_were()->void:
	# Worlds made before keep their stored homes, near or far: no town moves.
	GameState.reset_for_new_world(SEEDS[2])
	CivilizationSystem.reset_for_new_world()
	var near:=Start.candidate(SEEDS[2],0)+Vector2(300.0,0.0)
	CivilizationSystem.civilizations[0].position=Vector2(near.x/CivilizationSystem.CIVILIZATION_WORLD_RADIUS_X_KM,near.y/CivilizationSystem.CIVILIZATION_WORLD_RADIUS_Z_KM)
	var saved:=CivilizationSystem.export_state()
	CivilizationSystem.reset_for_new_world()
	assert_str(String(CivilizationSystem.import_state(saved).get("error",""))).is_empty()
	assert_float(CivilizationSystem._civilization_world_position(CivilizationSystem.civilizations[0]).distance_to(near)).is_less(1.0)

func test_peoples_share_two_continents_six_or_seven_each()->void:
	# "6-7 on one continent and 6-7 on another (think Europe and Asia)."
	for seed_value in SEEDS.slice(0,6):
		var sites:=_world(seed_value)
		var ours:=Start.region_centre(seed_value,0)
		var other:=Start.region_centre(seed_value,1)
		assert_float(ours.distance_to(other)).is_greater_equal(Start.CONTINENT_APART_KM)
		var with_us:=0
		for site:Vector2 in sites:
			if site.distance_to(ours)<site.distance_to(other): with_us+=1
		assert_int(with_us).override_failure_message("seed %d: %d peoples on our continent" % [seed_value,with_us]).is_between(6,8)

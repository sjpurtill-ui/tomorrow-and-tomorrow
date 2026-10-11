extends GdUnitTestSuite
## Expeditions (expedition.gd): a push in one direction by land or sea whose
## chance of coming home halves every endurance-length out, rolled once when
## due; home, it charts a wide band and counts its dead; lost, it is overdue,
## then given up with everyone in it.
const System=preload("res://scripts/civilization_system.gd")
const Expedition=preload("res://scripts/expedition.gd")
const SeaVoyage=preload("res://scripts/sea_voyage.gd")
const OCEAN_SHIPS:=["river_craft","hide_covered_boats","plank_extended_dugouts","sail_panel_cutting","sail_seaming","wayfinding_stars","coastal_watercraft","mast_making","carvel_frame_construction","galley_navigation","ocean_sailing"]
var system:Node

## A continent running east from the coast at x = -40 (sea to the west).
static func _continent()->Callable:
	return func(point:Vector2)->bool:return point.x>=-40.0 and point.x<=4000.0 and absf(point.y)<900.0

## A home island (x -40..0) and a far shore beyond `gap` km of open sea.
static func _ocean(gap:float)->Callable:
	return func(point:Vector2)->bool:return (point.x>=-40.0 and point.x<=0.0 and absf(point.y)<30.0) or point.x>gap

func before_test()->void:
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(271828);ProgressionSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();FoodSystem.reset_for_new_world()
	GameState.ensure_population_total(2000);GameState.settlement_site_committed=true
	GameState.resource_stockpiles.Food=80000.0;GameState.food_stocks={"Preserved food":80000.0}
	system=auto_free(System.new());system.reset_for_new_world();system.register_player_origin(Vector2(-6.0,0.0))
	system.set_scout_geography_authority(_continent())

func after_test()->void:
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)

func _know(ids:Array)->void:
	for id:String in ids:
		if not id in GameState.known_discoveries:GameState.known_discoveries.append(id)
		GameState.discovery_adoption[id]=1.0

func test_the_chance_of_coming_home_halves_every_endurance_out()->void:
	var half:=Expedition.endurance_km(false)
	assert_float(half).is_greater(300.0)
	assert_float(Expedition.return_chance(half,false)).is_equal_approx(0.5,0.001)
	assert_float(Expedition.return_chance(half*2.0,false)).is_equal_approx(0.25,0.001)
	assert_float(Expedition.return_chance(100.0,false)).is_greater(Expedition.return_chance(1000.0,false))
	# No boats, no sea.
	assert_float(Expedition.endurance_km(true)).is_equal(0.0)
	_know(OCEAN_SHIPS)
	assert_float(Expedition.endurance_km(true)).is_greater(1000.0)

func test_a_land_push_goes_its_way_until_the_reach_or_the_land_runs_out()->void:
	var east:=Expedition.quote("east",1200.0,false,40,system)
	assert_bool(bool(east.ok)).override_failure_message(str(east.get("blocker",""))).is_true()
	assert_float(float(east.km)).is_between(900.0,1260.0)
	assert_int((east.route_plan.route as Array).size()).is_less_equal(Expedition.ROUTE_POINTS)
	for p:Dictionary in east.route_plan.route:assert_bool(system._scout_land_at(Vector2(float(p.x),float(p.z)))).is_true()
	assert_float(float(east.chance)).is_equal_approx(Expedition.return_chance(float(east.km),false),0.0001)
	assert_float(float(east.provisions)).is_equal(40.0*float(east.days)*Expedition.RATION)
	# West is the sea at once: no way on foot.
	var west:=Expedition.quote("west",600.0,false,40,system)
	assert_bool(bool(west.ok)).is_false()
	# By sea without ships: refused with the reason.
	var sail:=Expedition.quote("east",600.0,true,40,system)
	assert_str(String(sail.blocker)).contains("rivers")

func test_one_that_comes_home_charts_a_wide_band_and_counts_its_dead()->void:
	var food:=FoodSystem.total_stored()
	var sent:=Expedition.send("east",600.0,false,40,system)
	assert_bool(bool(sent.get("ok",false))).override_failure_message(str(sent)).is_true()
	assert_float(FoodSystem.total_stored()).is_less(food)
	var mission:Dictionary=system.scout_missions[0]
	# Rolled home: the seeded roll is set beneath the stated chance.
	mission.expedition.rolled=0.0
	var before:=GameState.population_total
	system._complete_scout_mission(mission,int(mission.actual_return_day))
	assert_array(system.scout_missions).is_empty()
	var trail:Dictionary=system.revealed_areas[-1]
	assert_str(String(trail.source)).is_equal("returned expedition")
	assert_float(float(trail.radius)).is_equal(Expedition.REVEAL_KM)
	assert_int(GameState.population_total).is_less_equal(before)
	var log:Array=Expedition.history(system)
	assert_str(String(log[-1].outcome)).is_equal("home")

func test_one_that_is_lost_is_overdue_then_given_up_with_everyone()->void:
	var sent:=Expedition.send("east",2500.0,false,30,system)
	assert_bool(bool(sent.get("ok",false))).override_failure_message(str(sent)).is_true()
	var mission:Dictionary=system.scout_missions[0]
	var due:=int(mission.actual_return_day)
	# Make the roll go against them: the chance set beneath any roll.
	mission.expedition.chance=-1.0
	system._complete_scout_mission(mission,due)
	assert_int(system.scout_missions.size()).is_equal(1)
	assert_bool(bool(mission.expedition.lost)).is_true()
	assert_int(int(mission.actual_return_day)).is_greater(due)
	assert_str(String(GameState.simulation_events[0].title)).is_equal("THE EXPEDITION IS OVERDUE")
	var before:=GameState.population_total
	system._complete_due_scout_missions(int(mission.actual_return_day))
	assert_array(system.scout_missions).is_empty()
	assert_int(GameState.population_total).is_equal(before-30)
	assert_str(String(GameState.simulation_events[0].title)).is_equal("THE EXPEDITION IS GIVEN UP")
	assert_str(String(Expedition.history(system)[-1].outcome)).is_equal("lost")

func test_ocean_ships_cross_open_sea_that_coast_boats_cannot()->void:
	system.set_scout_geography_authority(_ocean(400.0))
	_know(OCEAN_SHIPS)
	var craft:=SeaVoyage.capability()
	assert_float(float(craft.offshore_km)).is_greater(400.0)
	var q:=Expedition.quote("east",1500.0,true,60,system)
	assert_bool(bool(q.ok)).override_failure_message(str(q.get("blocker",""))).is_true()
	assert_float(float(q.km)).is_greater(400.0)
	assert_float(float(q.chance)).is_less(0.9)
	var sent:=Expedition.send("east",1500.0,true,60,system)
	assert_bool(bool(sent.get("ok",false))).is_true()
	assert_str(String(system.scout_missions[0].travel_mode)).is_equal("sea")
	# Only two at once.
	Expedition.send("east",1500.0,true,60,system)
	assert_str(String(Expedition.quote("east",1500.0,true,60,system).blocker)).contains("already away")

func test_the_planner_card_states_the_odds_and_sends_them()->void:
	var host:=Node3D.new();add_child(host)
	var saved:=CivilizationSystem.scout_land_authority
	CivilizationSystem.register_player_origin(Vector2(-6.0,0.0))
	CivilizationSystem.set_scout_geography_authority(_continent())
	var planner:Node=load("res://scripts/hud/expedition_planner.gd").open(host)
	planner.set("heading","east");planner.set("reach_km",600.0)
	planner.call("requote")
	await get_tree().process_frame
	await get_tree().process_frame
	var current:Dictionary=planner.get("current")
	assert_bool(bool(current.get("ok",false))).override_failure_message(str(current.get("blocker",""))).is_true()
	var words:PackedStringArray=[]
	for n:Node in (planner.get("card") as Node).find_children("*","",true,false):
		if n is Label:words.append((n as Label).text)
		elif n is Button:words.append((n as Button).text)
	var text:=" | ".join(words)
	assert_str(text).contains("in 100 come home").contains("Send them").contains("Lost: all 40 die")
	planner.call("send")
	assert_int(preload("res://scripts/expedition.gd").away().size()).is_equal(1)
	CivilizationSystem.scout_missions.clear()
	CivilizationSystem.set_scout_geography_authority(saved)
	host.queue_free()

## Home country x -40..600, 400 km of open sea, and a far land beyond x 1000.
static func _two_lands()->Callable:
	return func(point:Vector2)->bool:return (point.x>=-40.0 and point.x<=600.0 and absf(point.y)<300.0) or (point.x>1000.0 and point.x<3000.0 and absf(point.y)<900.0)

const COAST_BOATS:=["river_craft","hide_covered_boats","plank_extended_dugouts","sail_panel_cutting","sail_seaming","wayfinding_stars"]

func test_by_sea_they_walk_to_the_far_shore_and_sail_on_past_where_the_boats_dare()->void:
	system.set_scout_geography_authority(_two_lands())
	_know(COAST_BOATS)
	var craft:=SeaVoyage.capability()
	assert_float(float(craft.offshore_km)).is_less(100.0)
	var q:=Expedition.quote("east",1200.0,true,40,system)
	assert_bool(bool(q.ok)).override_failure_message(str(q.get("blocker",""))).is_true()
	# On foot across our own land first, then the crossing, then ashore beyond.
	assert_float(float(q.walk_km)).is_greater(450.0)
	assert_float(float(q.open_km)).is_greater(float(craft.offshore_km))
	assert_float(float(q.km)).is_greater(1000.0)
	var route:Array=q.route_plan.route
	var voyage:Dictionary=q.route_plan.voyage
	var landing:Dictionary=route[int(voyage.landing_index)]
	assert_float(float(landing.x)).is_greater(1000.0)
	for k in range(1,int(voyage.sea_start)):assert_bool(system._scout_land_at(Vector2(float(route[k].x),float(route[k].z)))).is_true()
	# The stated odds: the walk at the land's endurance, open water in full, coast water a fifth.
	# Ashore they push on inland along the heading.
	assert_float(float(q.inland_km)).is_greater(Expedition.INLAND_MIN_KM-1.0)
	var last:Dictionary=route[-1]
	assert_float(float(last.x)).is_greater(float(landing.x)+100.0)
	var want:=pow(0.5,(float(q.walk_km)+float(q.inland_km))/Expedition.endurance_km(false))*pow(0.5,(float(q.coast_km)*Expedition.COAST_WEIGHT+float(q.open_km))/Expedition.endurance_km(true))
	assert_float(float(q.chance)).is_equal_approx(clampf(want,0.01,0.99),0.0001)
	assert_float(float(q.chance)).is_less(0.5)
	assert_float(float(q.fresh_km)).is_greater(900.0)
	assert_bool(bool(q.stale)).is_false()

func test_a_way_already_charted_is_said_to_bring_home_little()->void:
	system.revealed_areas.append({"x":0.0,"z":0.0,"radius":2000.0})
	system.fog_revision+=1
	var q:=Expedition.quote("east",600.0,false,40,system)
	assert_bool(bool(q.ok)).is_true()
	assert_float(float(q.fresh_km)).is_less(1.0)
	assert_bool(bool(q.stale)).is_true()

func test_an_expedition_meets_the_people_of_the_country_it_enters()->void:
	system.initialize()
	if system.civilizations.is_empty():return
	var civ:Dictionary=system.civilizations[0]
	# Their home 120 km off the track: too far for scouts (58 km), not for an expedition.
	civ.position=Vector2(700.0/system.CIVILIZATION_WORLD_RADIUS_X_KM,120.0/system.CIVILIZATION_WORLD_RADIUS_Z_KM)
	var sent:=Expedition.send("east",1200.0,false,40,system)
	assert_bool(bool(sent.get("ok",false))).override_failure_message(str(sent)).is_true()
	var mission:Dictionary=system.scout_missions[0]
	mission.expedition.rolled=0.0
	system._complete_scout_mission(mission,int(mission.actual_return_day))
	assert_int(int((system.civilizations[0].player_relation as Dictionary).contact_level)).is_equal(2)

func test_signs_of_a_people_are_followed_overland_or_come_home_as_a_rumour()->void:
	system.initialize()
	if system.civilizations.is_empty():return
	var civ:Dictionary=system.civilizations[0]
	# Their home 300 km off the track across dry land: too far to meet outright, near enough to go and look.
	civ.position=Vector2(700.0/system.CIVILIZATION_WORLD_RADIUS_X_KM,300.0/system.CIVILIZATION_WORLD_RADIUS_Z_KM)
	var route:Array=[{"x":-6.0,"z":0.0},{"x":1200.0,"z":0.0}]
	assert_bool(Expedition.followed_signs(system,route,Vector2(700,300)).is_finite()).is_true()
	# Over water (north of the continent's shore at 900): no way, so no meeting.
	assert_bool(Expedition.followed_signs(system,route,Vector2(700,1000)).is_finite()).is_false()
	# Too far off to have seen anything.
	assert_bool(Expedition.followed_signs(system,route,Vector2(700,600)).is_finite()).is_false()
	var sent:=Expedition.send("east",1200.0,false,40,system)
	assert_bool(bool(sent.get("ok",false))).override_failure_message(str(sent)).is_true()
	var mission:Dictionary=system.scout_missions[0]
	mission.expedition.rolled=0.0
	system._complete_scout_mission(mission,int(mission.actual_return_day))
	assert_int(int((system.civilizations[0].player_relation as Dictionary).contact_level)).is_equal(2)

func test_a_party_that_came_in_boats_coasts_round_to_a_harbour_home()->void:
	# Two lands with a 100 km strait between: no way overland from one to the other.
	system.set_scout_geography_authority(func(point:Vector2)->bool:return (point.x>=-40.0 and point.x<=600.0 and absf(point.y)<300.0) or (point.x>700.0 and point.x<2000.0 and absf(point.y)<300.0))
	var track:Array=[{"x":720.0,"z":0.0},{"x":1200.0,"z":0.0}]
	# A home by the water across the strait: reached in boats, not on foot.
	assert_bool(Expedition.followed_signs(system,track,Vector2(590,0),false).is_finite()).is_false()
	assert_bool(Expedition.followed_signs(system,track,Vector2(590,0),true).is_finite()).is_true()
	# A home far inland of that shore: boats do not reach it.
	assert_bool(Expedition.followed_signs(system,track,Vector2(450,0),true).is_finite()).is_false()

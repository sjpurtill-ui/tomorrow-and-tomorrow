extends GdUnitTestSuite
## PLACES OF THE ONE SEAT (settlement_places.gd): families settle apart in
## named places that are shares of the one ledger. A place is founded on a
## coast before a lake, a river or dry ground; its people are the realm's
## times its share, so the realm's count never changes; shares move once a
## month; a shore place works the coast for the whole people; a flood can
## come in at a place by the water; an emptied place is left as a ruin.

const Places:=preload("res://scripts/settlement_places.gd")
const OneSeat:=preload("res://scripts/one_seat.gd")
const HOME:=Vector2(14.0,-9.0)
## The sea begins this far east of the seat; a river runs north-south west of it.
const SEA_EAST_KM:=24.0
const RIVER_WEST_KM:=9.0

var _processing:Dictionary={}

func before()->void:
	for node:Node in [GameState,CivilizationSystem,MilitaryCampaign,ProgressionSystem]:_processing[node]=node.is_processing()

func after()->void:
	Places.geography_hook=Callable()
	WorldSimulation.context_provider=Callable()
	GameState.elapsed_days=0
	MilitaryCampaign.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	GameState.reset_for_new_world(74017)
	PeopleDirection.reset_for_new_world()
	WorldSimulation.clear()
	for node:Node in _processing:node.set_process(bool(_processing[node]))

func after_test()->void:
	Places.geography_hook=Callable()
	WorldSimulation.context_provider=Callable()
	WorldSimulation.clear()

func _seat(people:int=2000)->void:
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(716203)
	GovernmentPeopleSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	PeopleDirection.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.ensure_population_total(people)
	GameState.settlement_name="Keansburg"
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	GameState.settlement_founded_at=Vector3(HOME.x,0.0,HOME.y)
	GameState.resource_stockpiles={"Food":60000.0,"Timber":500.0,"Fiber Plants":500.0}
	GameState.simulation_metrics["food_days"]=120.0
	CivilizationSystem.register_player_origin(HOME)
	SettlementModel.ensure_founded()
	GovernmentPeopleSystem.initialize()
	PeopleDirection.ensure()

## Sea to the east (if `sea`), a river to the west (if `river`), land elsewhere.
func _world(sea:bool,river:bool)->void:
	Places.geography_hook=func()->Dictionary:
		return {"height_at":func(x:float,_z:float)->float:return -1.0 if sea and x>HOME.x+SEA_EAST_KM else 1.0,
			"river_distance_at":func(x:float,_z:float)->float:return absf(x-(HOME.x-RIVER_WEST_KM)) if river else INF}

func _rng(value:int)->RandomNumberGenerator:
	var rng:=RandomNumberGenerator.new();rng.seed=value
	return rng

func test_a_new_place_goes_to_the_coast_before_a_nearer_river()->void:
	_seat()
	_world(true,true)
	for value in 6:
		var site:=Places.choose_site(HOME,2000.0,_rng(value))
		assert_str(String(site.get("kind",""))).is_equal("coast")
		var at:Vector2=site.position
		assert_float(at.x).is_between(HOME.x+SEA_EAST_KM-1.6,HOME.x+SEA_EAST_KM)
		# It faces the sea, to the east.
		assert_float((site.facing as Vector2).x).is_greater(0.7)

func test_without_a_shore_in_reach_a_place_goes_to_the_river()->void:
	_seat()
	_world(false,true)
	var site:=Places.choose_site(HOME,2000.0,_rng(3))
	assert_str(String(site.get("kind",""))).is_equal("river")

func test_dry_ground_only_within_the_worked_land()->void:
	_seat()
	_world(false,false)
	var site:=Places.choose_site(HOME,2000.0,_rng(5))
	assert_str(String(site.get("kind",""))).is_equal("inland")
	assert_float(float(site.distance_km)).is_less_equal(maxf(3.0+Places.MIN_SPACING_KM,OneSeat.reach_km())+0.01)

func test_no_place_before_there_is_room_and_food()->void:
	_seat(300)
	_world(true,true)
	for month in 24:Places.monthly(month*Places.PASS_DAYS)
	assert_int(Places.list().size()).is_equal(0)
	_seat(2000)
	_world(true,true)
	GameState.simulation_metrics["food_days"]=5.0
	for month in 24:Places.monthly(month*Places.PASS_DAYS)
	assert_int(Places.list().size()).is_equal(0)

func test_places_are_founded_on_the_coast_and_share_the_one_ledger()->void:
	_seat(4000)
	_world(true,true)
	var total:=float(GameState.population_exact)
	for month in 12*30:
		GameState.elapsed_days=month*Places.PASS_DAYS
		Places.monthly(month*Places.PASS_DAYS)
	var places:=Places.list()
	assert_int(places.size()).is_equal(Places.room(total))
	assert_str(String(places[0].kind)).is_equal("coast")
	# Names are unique and known to the namer.
	var used:=SettlementModel.names_in_use()
	var names:={}
	for place:Dictionary in places:
		assert_bool(used.has(String(place.name).to_lower())).is_true()
		assert_bool(names.has(String(place.name))).is_false()
		names[String(place.name)]=true
	# The realm's count is unchanged; the places and the seat add up to it.
	assert_float(float(GameState.population_exact)).is_equal(total)
	var sum:=Places.seat_people()
	for place:Dictionary in places:sum+=Places.people(place)
	assert_int(sum).is_between(roundi(total)-places.size(),roundi(total)+places.size())
	assert_float(Places.away_share()).is_less_equal(Places.away_limit(total)+0.001)
	assert_float(Places.away_share()).is_greater(0.05)
	# No place's record holds people, stores or labour of its own.
	for place:Dictionary in places:
		for key in ["population","population_share","city_resources","resource_stockpiles","labor"]:assert_bool(place.has(key)).is_false()

func test_the_pass_runs_once_a_month()->void:
	_seat(4000)
	_world(true,true)
	Places.monthly(0)
	var seat:=OneSeat.seat_record()
	assert_int(int(seat.places_day)).is_equal(0)
	for day in range(1,Places.PASS_DAYS):Places.monthly(day)
	assert_int(int(seat.places_day)).is_equal(0)
	Places.monthly(Places.PASS_DAYS)
	assert_int(int(seat.places_day)).is_equal(Places.PASS_DAYS)

func test_a_shore_place_works_the_coast_for_the_whole_people()->void:
	_seat(4000)
	_world(true,false)
	var seat:=OneSeat.seat_record()
	var before:=SettlementModel.coastal_site_profile(seat)
	var place:=Places.found(0,{"position":HOME+Vector2(SEA_EAST_KM-0.4,0.0),"kind":"coast","shoreline":0.97,"marine":0.8,"open_water":0.6},4000.0)
	place["share"]=0.08
	var after:=SettlementModel.coastal_site_profile(seat)
	assert_float(float(after.shoreline_access)).is_greater(float(before.shoreline_access)+0.5)
	assert_float(float(after.marine_opportunity)).is_greater(float(before.marine_opportunity))
	assert_float(float(after.storm_exposure)).is_greater(float(before.storm_exposure))
	assert_bool(Places.words().contains(String(place.name))).is_true()

func test_a_flood_comes_in_at_a_place_by_the_water_and_sets_it_back()->void:
	_seat(4000)
	_world(true,true)
	var place:=Places.found(0,{"position":HOME+Vector2(-RIVER_WEST_KM,0.0),"kind":"river"},4000.0)
	place["share"]=0.1
	assert_float(Places.flood_exposure()).is_greater(0.9)
	var chosen:=Places.flood_place(_rng(1),0.0,400)
	assert_str(String(chosen.get("id",""))).is_equal(String(place.id))
	assert_int(int(place.setback_until)).is_equal(400+Places.FLOOD_SETBACK_DAYS)
	assert_float(Places.pull(place,500)).is_less(Places.pull(place,400+Places.FLOOD_SETBACK_DAYS+1))

func test_an_emptied_place_is_left_as_a_ruin()->void:
	_seat(4000)
	_world(true,true)
	var place:=Places.found(0,{"position":HOME+Vector2(-RIVER_WEST_KM,0.0),"kind":"river"},4000.0)
	place["share"]=0.0005
	place["founded_day"]=0
	# The people have shrunk below the room for a place.
	GameState.ensure_population_total(300)
	var day:=Places.ABANDON_AFTER_DAYS+Places.PASS_DAYS
	OneSeat.seat_record()["places_day"]=day-Places.PASS_DAYS
	var result:=Places.monthly(day)
	assert_bool(result.has("left")).is_true()
	assert_str(String(place.status)).is_equal("ruin")
	assert_int(Places.people(place)).is_equal(0)
	assert_int(Places.ruins().size()).is_equal(1)

func test_the_art_snapshot_is_a_plain_copy()->void:
	_seat(4000)
	_world(true,false)
	var place:=Places.found(0,{"position":HOME+Vector2(SEA_EAST_KM-0.4,0.0),"kind":"coast","shoreline":0.9,"open_water":0.6},4000.0)
	var view:=Places.snapshot()
	assert_int((view.places as Array).size()).is_equal(1)
	var drawn:Dictionary=view.places[0]
	for key in ["id","name","position","kind","status","people","share","trend","age_days","flooded","shoreline","open_water","facing","founded_day","left_day"]:assert_bool(drawn.has(key)).is_true()
	drawn["share"]=0.9
	assert_float(float(place.share)).is_less(0.5)

## Six centuries of monthly passes as the people grow from 150 to 60,000:
## places come one at a time, seasons apart, coast first; the pass stays
## cheap. Prints the founding years and names for review.
func test_six_centuries_of_places_come_seasons_apart()->void:
	_seat(150)
	_world(true,true)
	var founded:=[]
	var started:=Time.get_ticks_usec()
	var passes:=0
	for month in 600*12:
		var day:=month*Places.PASS_DAYS
		var year:=float(month)/12.0
		GameState.elapsed_days=day
		GameState.population_exact=150.0*pow(400.0,year/600.0)
		GameState.population_total=roundi(GameState.population_exact)
		var result:=Places.monthly(day)
		passes+=1
		if result.has("founded"):founded.append([snappedf(year,0.1),String(result.founded.name),String(result.founded.kind),roundi(GameState.population_exact)])
	var per_pass_us:=float(Time.get_ticks_usec()-started)/float(passes)
	print("PLACES CADENCE: %d founded, %.1f us a pass" % [founded.size(),per_pass_us])
	for entry:Array in founded:print("  year %s: %s (%s) at %d people" % entry)
	assert_int(founded.size()).is_equal(Places.room(60000.0))
	assert_str(String(founded[0][2])).is_equal("coast")
	# None before there was room for it; none two in one season.
	for index in founded.size():
		assert_int(int(founded[index][3])).is_greater_equal(roundi(Places.PEOPLE_PER_PLACE*pow(index+1,2))-1)
		if index>0:assert_float(float(founded[index][0])-float(founded[index-1][0])).is_greater_equal(0.08)
	assert_float(per_pass_us).is_less(2000.0)

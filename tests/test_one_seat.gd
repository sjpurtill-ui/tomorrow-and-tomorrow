extends GdUnitTestSuite
## ONE SEAT (one_seat.gd): every people grows outward from its one seat and
## founds no separate towns. A town standing apart in an older world comes
## home with its people and stores; the realm's count does not change. The
## seat's reach for timber, stone and fibre grows with its people, and its
## stage (settlement, town of districts, county, state, country) is read
## from its people and districts.

const OneSeat:=preload("res://scripts/one_seat.gd")
const Span:=preload("res://scripts/day_span.gd")
const Controller:=preload("res://scripts/civilization_controller.gd")
const HOME:=Vector2(14.0,-9.0)

var _processing:Dictionary={}

func before()->void:
	for node:Node in [GameState,CivilizationSystem,MilitaryCampaign,ProgressionSystem]:_processing[node]=node.is_processing()

func after()->void:
	WorldSimulation.context_provider=Callable()
	CivilizationSystem.set_scout_geography_authority(Callable())
	GameState.elapsed_days=0
	MilitaryCampaign.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	GameState.reset_for_new_world(74017)
	PeopleDirection.reset_for_new_world()
	WorldSimulation.clear()
	for node:Node in _processing:node.set_process(bool(_processing[node]))

func after_test()->void:
	WorldSimulation.context_provider=Callable()
	CivilizationSystem.set_scout_geography_authority(Callable())
	WorldSimulation.clear()

func _seat()->void:
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(716203)
	GovernmentPeopleSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	PeopleDirection.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.ensure_population_total(1000)
	GameState.settlement_name="Keansburg"
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	GameState.settlement_founded_at=Vector3(HOME.x,0.0,HOME.y)
	GameState.resource_stockpiles={"Food":6000.0,"Timber":500.0,"Fiber Plants":500.0}
	CivilizationSystem.register_player_origin(HOME)
	SettlementModel.ensure_founded()
	GovernmentPeopleSystem.initialize()
	PeopleDirection.ensure()
	CivilizationSystem._add_revealed_area(HOME,80.0,"scout report")
	CivilizationSystem.set_scout_geography_authority(func(_p:Vector2)->bool:return true)
	WorldSimulation.context_provider=func(_origin:Vector2)->Dictionary:
		return {"environment_profile":{"food_potential":.6,"water_access":.72,"woodland":.3},"surface_water_distance_km":0.4,"surface_water_recognized":true}

func _town(name:String,position:Vector2,people:float)->Dictionary:
	var sequence:=int(GameState.next_player_settlement_id)
	var record:={"id":"settlement_%03d" % sequence,"sequence":sequence,"primary":false,"name":name,"position":position,"population_share":people/GameState.population_exact,
		"founded_day":0,"status":"established","source_settlement_id":"","territory_context":{},"environment_profile":{},"auto_manage":true,"management_focus":"establishment","leader_person_id":0}
	GameState.next_player_settlement_id+=1
	GameState.player_settlements.append(record)
	SettlementModel._ensure_city_resources(record)
	return record

func test_towns_standing_apart_come_home_with_their_people_and_stores()->void:
	_seat()
	var total:=GameState.population_exact
	var east:=_town("Ashleyton",HOME+Vector2(18,0),120.0)
	_town("Rivermeet",HOME+Vector2(-30,4),80.0)
	east.local_resources.resource_stockpiles["Timber"]=40.0
	var held:=float(GameState.resource_stockpiles.get("Timber",0.0))
	var folded:=OneSeat.fold_towns(300)
	assert_int(folded.size()).is_equal(2)
	# Only the seat is left, and every person of the realm lives in it.
	assert_int(GameState.player_settlements.size()).is_equal(1)
	assert_bool(bool(GameState.player_settlements[0].primary)).is_true()
	assert_float(GameState.population_exact).is_equal(total)
	assert_float(SettlementModel.primary_population_exact()).is_equal_approx(total,.001)
	# What they owned came with them.
	assert_float(float(GameState.resource_stockpiles.get("Timber",0.0))).is_equal_approx(held+40.0,.001)
	# Nothing more to fold the next day.
	assert_int(OneSeat.fold_towns(301).size()).is_equal(0)

func test_a_town_held_by_another_people_is_not_folded()->void:
	_seat()
	var held:=_town("Ashleyton",HOME+Vector2(18,0),60.0)
	held["occupied_by"]="civ_03"
	assert_int(OneSeat.fold_towns(300).size()).is_equal(0)
	assert_int(GameState.player_settlements.size()).is_equal(2)

func test_no_caravan_leaves_to_found_a_separate_town()->void:
	_seat()
	var quote:=SettlementModel.settlement_convoy_quote(HOME+Vector2(24,0),0)
	assert_bool(bool(quote.get("ok",true))).is_false()
	assert_str(String(quote.get("reason",""))).is_equal(OneSeat.NO_NEW_TOWNS)
	var went:=SettlementModel.begin_settlement_convoy(HOME+Vector2(24,0),0.0)
	assert_bool(bool(went.get("ok",true))).is_false()
	assert_bool(bool(GameState.settlement_convoy.get("active",false))).is_false()

func test_the_leaders_council_looks_for_no_land()->void:
	_seat()
	var plan:={"expansion_months":1,"hungry":false,"at_war":false,"expansion_food":0.0,"settle_distance":20.0,"settle_margin_days":45.0,
		"personality":{"empathy":.5,"openness":.5,"discipline":.5,"risk_tolerance":.5,"assertiveness":.5}}
	GameState.elapsed_days=300
	Controller.expansion_orders("player",plan)
	assert_bool(bool(GameState.settlement_convoy.get("active",false))).is_false()
	assert_int(GameState.player_settlements.size()).is_equal(1)

func test_the_court_is_told_the_seat_grows_instead()->void:
	_seat()
	var said:Dictionary=preload("res://scripts/realm_orders.gd")._found({})
	assert_bool(bool(said.get("ok",true))).is_false()
	assert_str(JSON.stringify(said)).contains("grows outward")

func test_reach_grows_with_the_people()->void:
	_seat()
	GameState.population_exact=500.0
	assert_int(OneSeat.reach_rings()).is_equal(3)
	GameState.population_exact=10000.0
	assert_int(OneSeat.reach_rings()).is_equal(6)
	GameState.population_exact=100000.0
	assert_int(OneSeat.reach_rings()).is_equal(13)
	GameState.population_exact=1.0e9
	assert_int(OneSeat.reach_rings()).is_equal(OneSeat.MAX_REACH_RINGS)
	assert_int(WorldSimulation.resources.max_surface_front_ring()).is_equal(OneSeat.MAX_REACH_RINGS)

func test_stages_need_both_people_and_districts()->void:
	_seat()
	GameState.settlement_nuclei=[{"id":1,"active":true}]
	GameState.population_exact=50000.0
	# Many people in one centre are still one settlement: districts come first.
	assert_str(String(OneSeat.stage().id)).is_equal("settlement")
	GameState.settlement_nuclei=[{"id":1,"active":true},{"id":2,"active":true},{"id":3,"active":true},{"id":4,"active":true}]
	assert_str(String(OneSeat.stage().id)).is_equal("county")
	assert_str(String((OneSeat.stage().next as Dictionary).id)).is_equal("state")
	assert_str(OneSeat.stage_words()).contains("A state at 150,000 people")
	GameState.population_exact=3000.0
	assert_str(String(OneSeat.stage().id)).is_equal("town")

func test_a_left_town_does_not_hold_its_people_to_daily_steps()->void:
	_seat()
	GameState.simulation_metrics["food_days"]=40.0
	GameState.simulation_metrics["water_intake_ratio"]=1.0
	var left:=_town("Ashleyton",HOME+Vector2(18,0),0.0)
	left["status"]="abandoned"
	left["resource_metrics"]={}
	assert_int(Span.food_span()).is_equal(20)

func test_a_crowded_fed_seat_claims_land_and_its_land_carries_more()->void:
	_seat()
	var EarlyLife:=preload("res://scripts/early_life_conditions.gd")
	GameState.simulation_metrics["food_days"]=200.0
	var before:=EarlyLife.carrying_capacity(GameState,DiscoverySystem)
	# Not crowded: no new land.
	GameState.population_exact=before*0.3
	assert_bool(OneSeat.claim_land(400)).is_false()
	# Crowded and fed: the next ring of land, and the land carries more.
	GameState.population_exact=before*0.9
	assert_bool(OneSeat.claim_land(400)).is_true()
	assert_float(EarlyLife.carrying_capacity(GameState,DiscoverySystem)).is_greater(before*1.5)
	# At most once in LAND_CLAIM_DAYS.
	assert_bool(OneSeat.claim_land(400+OneSeat.LAND_CLAIM_DAYS-1)).is_false()
	# Hungry: it does not reach out.
	GameState.simulation_metrics["food_days"]=5.0
	assert_bool(OneSeat.claim_land(400+OneSeat.LAND_CLAIM_DAYS)).is_false()

func test_folded_towns_leave_their_land_with_the_seat()->void:
	_seat()
	_town("Ashleyton",HOME+Vector2(18,0),120.0)
	_town("Rivermeet",HOME+Vector2(-30,4),80.0)
	OneSeat.fold_towns(300)
	assert_int(int(OneSeat.seat_record().get("land_claims",0))).is_equal(2)

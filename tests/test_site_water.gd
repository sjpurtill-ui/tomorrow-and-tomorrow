extends GdUnitTestSuite
## "Why would the computer settle me where there is NO WATER!" The leaders
## founded Ashleyton on dry ground: every site was judged by the capital's
## own water ledger (a river 0.4 km from the capital), so any place inherited
## the capital's water. One reading now (resource_system.site_water): a site
## drinks only from water within 6 km of the site itself, by the very search
## the new town's own day makes. The leaders' council, the court's "found a
## town" and the settle order all refuse dry ground; the coast's salt water
## is no drinking water; a town already dry is left for one with water
## (dry_towns.gd); and no two towns of any peoples share a name.

const Controller:=preload("res://scripts/civilization_controller.gd")
const Orders:=preload("res://scripts/civilization_orders.gd")
const DryTowns:=preload("res://scripts/dry_towns.gd")
const DayJob:=preload("res://scripts/day_job.gd")
const HOME:=Vector2(14.0,-9.0)

var _processing:Dictionary={}
## Water distance (km) the fake map reports at a point.
var _water_at:Callable=func(_point:Vector2)->float:return INF

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

## A settled people of 1,000 with food and materials to spare; the capital's
## own water ledger has a river 0.4 km away. The map reports water at each
## point by `_water_at` (km; INF for none) and calls the ground near the
## coast (profile water_access .72, coastal) everywhere.
func _settled_world()->void:
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
	GameState.food_stocks={"Fresh plants":0.0,"Fresh meat":0.0,"Fish":0.0,"Dry staples":5000.0,"Preserved food":1000.0}
	GameState.resource_stockpiles={"Food":6000.0,"Timber":500.0,"Fiber Plants":500.0}
	CivilizationSystem.register_player_origin(HOME)
	SettlementModel.ensure_founded()
	GovernmentPeopleSystem.initialize()
	PeopleDirection.ensure()
	# The capital's own ledger: a river 0.4 km away, plenty to drink.
	GameState.water_metrics={"source_accessible":true,"recognized":true,"source_distance_km":0.4,"source_kind":"river","source_id":"home_river","source_origin":"mapped_hydrology","supports_drinking":true,"intake_ratio":1.0}
	# All the land around is charted, dry land.
	CivilizationSystem._add_revealed_area(HOME,80.0,"scout report")
	CivilizationSystem.set_scout_geography_authority(func(_p:Vector2)->bool:return true)
	WorldSimulation.context_provider=func(origin:Vector2)->Dictionary:
		return {"environment_profile":{"food_potential":.6,"water_access":.72,"coastal":true,"woodland":.3},"surface_water_distance_km":float(_water_at.call(origin)),"surface_water_recognized":true}

func _plan()->Dictionary:
	return {"expansion_months":1,"hungry":false,"at_war":false,"expansion_food":0.0,"settle_distance":20.0,"settle_margin_days":45.0,
		"personality":{"empathy":.5,"openness":.5,"discipline":.5,"risk_tolerance":.5,"assertiveness":.5}}

func _site(water_km:float)->Dictionary:
	return {"origin":Vector3(40,0,0),"surface_water_distance_km":water_km}

# --------------------------------------------------------------------------
# One reading of a place's water
# --------------------------------------------------------------------------

func test_a_site_drinks_from_its_own_water_never_the_capitals()->void:
	_settled_world()
	for dry:float in [INF,20.0,6.1]:
		var water:=ResourceSystem.site_water(_site(dry))
		assert_bool(bool(water.accessible)).override_failure_message("water at %s km" % dry).is_false()
		assert_float(float(water.household_share)).is_equal(0.0)
	for wet:float in [0.5,3.0,6.0]:
		var water:=ResourceSystem.site_water(_site(wet))
		assert_bool(bool(water.accessible)).is_true()
		assert_float(float(water.distance_km)).is_equal(wet)
		assert_str(String(water.origin)).is_equal("mapped_hydrology")
	# Beside the water the families fetch all of it; a long carry, less.
	assert_float(float(ResourceSystem.site_water(_site(0.5)).household_share)).is_equal(1.0)
	assert_float(float(ResourceSystem.site_water(_site(5.0)).household_share)).is_less(0.5)

## The town's own day finds exactly the source the site test found.
func test_the_towns_day_and_the_site_test_agree()->void:
	_settled_world()
	for km:float in [INF,20.0,3.0]:
		var context:=_site(km)
		ResourceSystem._process_water_flow(context)
		var site:=ResourceSystem.site_water(context)
		assert_bool(bool(GameState.water_metrics.source_accessible)).is_equal(bool(site.accessible))
		assert_float(float(GameState.water_metrics.source_distance_km)).is_equal(float(site.distance_km) if bool(site.accessible) else -1.0)

## A people's own found sources count where they live: a surveyed spring
## within 6 km, never one farther off.
func test_found_sources_count_by_the_same_rule()->void:
	_settled_world()
	var spring:Array=[{"resource":"Freshwater","stage":"surveyed","position":Vector3(44,0,0),"quality":.9,"id":"spring"}]
	assert_bool(bool(ResourceSystem.site_water(_site(INF),spring).accessible)).is_true()
	assert_float(float(ResourceSystem.site_water(_site(INF),spring).distance_km)).is_equal_approx(4.0,.0001)
	spring[0].position=Vector3(50,0,0)
	assert_bool(bool(ResourceSystem.site_water(_site(INF),spring).accessible)).is_false()

# --------------------------------------------------------------------------
# The leaders' council, the court and the settle order
# --------------------------------------------------------------------------

func test_the_leaders_refuse_a_site_with_no_water_though_the_capital_has_it()->void:
	_settled_world()
	var point:=HOME+Vector2(20,0)
	for dry:float in [INF,20.0]:
		_water_at=func(_p:Vector2)->float:return dry
		assert_dict(Controller.expansion_site(point,_plan(),{})).is_empty()
	_water_at=func(_p:Vector2)->float:return 5.0
	var site:=Controller.expansion_site(point,_plan(),{})
	assert_bool(site.is_empty()).is_false()
	assert_float(float((site.water as Dictionary).distance_km)).is_equal(5.0)

func test_the_leaders_council_sends_no_settlers_to_dry_ground()->void:
	_settled_world()
	GameState.elapsed_days=90.0
	_water_at=func(_p:Vector2)->float:return INF
	DayJob.run_parts(Controller.expansion_order_steps("player",func()->Dictionary:return _plan()))
	assert_bool(bool(GameState.settlement_convoy.get("active",false))).is_false()

func test_the_leaders_council_settles_where_there_is_water()->void:
	_settled_world()
	GameState.elapsed_days=90.0
	_water_at=func(_p:Vector2)->float:return 1.0
	DayJob.run_parts(Controller.expansion_order_steps("player",func()->Dictionary:return _plan()))
	assert_bool(bool(GameState.settlement_convoy.get("active",false))).is_true()
	var destination:Vector2=GameState.settlement_convoy.destination
	assert_bool(bool(ResourceSystem.site_water(preload("res://scripts/civilization_day.gd").context(destination)).accessible)).is_true()

func test_the_court_founds_no_town_on_dry_ground()->void:
	_settled_world()
	var Realm:=load("res://scripts/realm_orders.gd")
	_water_at=func(_p:Vector2)->float:return 20.0
	var refused:Dictionary=Realm._found({})
	assert_bool(bool(refused.ok)).is_false()
	assert_str(String(refused.says)).contains("drinking water within 6 km")
	assert_bool(bool(GameState.settlement_convoy.get("active",false))).is_false()
	_water_at=func(_p:Vector2)->float:return 1.0
	var went:Dictionary=Realm._found({})
	assert_bool(bool(went.ok)).override_failure_message(str(went)).is_true()

func test_the_settle_order_needs_water_at_the_place_itself()->void:
	_settled_world()
	var point:=HOME+Vector2(20,0)
	for dry:float in [INF,20.0]:
		_water_at=func(_p:Vector2)->float:return dry
		var refused:=Orders.execute({"kind":"settle","destination":point})
		assert_str(String(refused.get("error",""))).contains("drinking water within 6 km")
	_water_at=func(_p:Vector2)->float:return 1.0
	var went:=Orders.execute({"kind":"settle","destination":point})
	assert_bool(bool(went.get("ok",false))).override_failure_message(str(went)).is_true()

## The sea's salt water adds nothing to a site's worth; fresh water does.
func test_salt_coast_is_not_drinking_water_in_the_leaders_judgment()->void:
	_settled_world()
	var coast:={"origin":Vector3(40,0,0),"environment_profile":{"food_potential":.6,"water_access":.72,"coastal":true},"surface_water_distance_km":INF}
	var inland:={"origin":Vector3(40,0,0),"environment_profile":{"food_potential":.6,"water_access":0.0},"surface_water_distance_km":INF}
	assert_float(Controller.expansion_site_value(coast,_plan())).is_equal(Controller.expansion_site_value(inland,_plan()))
	var river:=inland.duplicate(true);river.surface_water_distance_km=0.5
	var far:=inland.duplicate(true);far.surface_water_distance_km=5.0
	assert_float(Controller.expansion_site_value(river,_plan())).is_greater(Controller.expansion_site_value(far,_plan()))
	assert_float(Controller.expansion_site_value(far,_plan())).is_greater(Controller.expansion_site_value(inland,_plan()))

# --------------------------------------------------------------------------
# A town already dry is left for one with water
# --------------------------------------------------------------------------

func _town(name:String,position:Vector2,people:float)->Dictionary:
	var sequence:=int(GameState.next_player_settlement_id)
	var record:={"id":"settlement_%03d" % sequence,"sequence":sequence,"primary":false,"name":name,"position":position,"population_share":people/GameState.population_exact,
		"founded_day":0,"status":"established","source_settlement_id":"","territory_context":{},"environment_profile":{},"auto_manage":true,"management_focus":"establishment","leader_person_id":0}
	GameState.next_player_settlement_id+=1
	GameState.player_settlements.append(record)
	SettlementModel._ensure_city_resources(record)
	return record

## The town's own water ledger, day by day: no source, `intake` drunk.
func _dry_days(record:Dictionary,days:int,today:int,intake:float=0.0)->void:
	var history:Array=record.local_resources.water_history
	history.clear()
	for day in range(today-days+1,today+1):history.append({"day":day,"source_distance_km":-1.0,"intake_ratio":intake})

func test_a_dry_town_is_left_for_the_nearest_town_with_water()->void:
	_settled_world()
	var today:=200
	GameState.elapsed_days=float(today)
	var dry:=_town("Ashleyton",HOME+Vector2(18,0),12.0)
	_dry_days(dry,9,today)
	var total:=GameState.population_exact
	var capital:=SettlementModel.primary_population_exact()
	var left:=DryTowns.daily(today)
	assert_int(left.size()).is_equal(1)
	assert_str(String(dry.status)).is_equal("abandoned")
	assert_float(float(dry.population_share)).is_equal(0.0)
	# The same people, in the capital: the realm's count is unchanged.
	assert_float(GameState.population_exact).is_equal(total)
	assert_float(SettlementModel.primary_population_exact()).is_equal_approx(capital+12.0,.001)
	assert_int(int(left[0].people)).is_equal(12)
	# Told plainly, once.
	var told:Dictionary=(GameState.chronicle.entries as Array)[0]
	assert_str(String(told.title)).is_equal("Ashleyton abandoned: no water")
	assert_str(String(told.text)).is_equal("Ashleyton had no drinking water within 6 km for 9 days. Its 12 people have gone to Keansburg, a day's walk away, where there is water. Ashleyton stands empty.")
	# Nobody lives there: no day is run, the map shows it empty, and the
	# check does not find it again.
	SettlementModel.process_city_resources(String(dry.id),_site(INF))
	assert_int(int(dry.get("last_resource_day",-1))).is_equal(-1)
	for town:Dictionary in SettlementModel.settlement_network_snapshot().settlements:
		if String(town.id)==String(dry.id):assert_int(int(town.population)).is_equal(0)
	assert_int(DryTowns.daily(today+1).size()).is_equal(0)
	# No caravan sets out from the empty place.
	var quote:=SettlementModel.settlement_convoy_quote(HOME+Vector2(24,0),0)
	assert_str(String(quote.get("origin_id",""))).is_not_equal(String(dry.id))

func test_the_families_go_to_the_nearest_town_that_has_water()->void:
	_settled_world()
	var today:=200
	GameState.elapsed_days=float(today)
	var dry:=_town("Ashleyton",HOME+Vector2(30,0),12.0)
	var wet:=_town("Riverford",HOME+Vector2(36,0),50.0)
	wet.local_resources.water_metrics={"source_accessible":true,"source_distance_km":0.3}
	var stale:=_town("Thornby",HOME+Vector2(28,0),30.0)
	_dry_days(dry,8,today)
	var total:=GameState.population_exact
	DryTowns.daily(today)
	assert_str(String(dry.status)).is_equal("abandoned")
	assert_float(float(wet.population_share)*GameState.population_exact).is_equal_approx(62.0,.001)
	# A town with no water ledger yet is not a place to go, and is not left.
	assert_float(float(stale.population_share)*GameState.population_exact).is_equal_approx(30.0,.001)
	assert_str(String(stale.status)).is_equal("established")
	assert_float(GameState.population_exact).is_equal(total)

func test_a_town_is_not_left_too_soon()->void:
	_settled_world()
	var today:=200
	GameState.elapsed_days=float(today)
	# Six dry days: they wait a little longer.
	var recent:=_town("Ashleyton",HOME+Vector2(18,0),12.0)
	_dry_days(recent,6,today)
	# Rain and cisterns keep them drinking: they stay.
	var cisterns:=_town("Dryhollow",HOME+Vector2(-18,0),12.0)
	_dry_days(cisterns,30,today,1.0)
	assert_int(DryTowns.daily(today).size()).is_equal(0)
	assert_str(String(recent.status)).is_equal("established")
	assert_str(String(cisterns.status)).is_equal("established")
	# With no town of theirs that has water, they have nowhere to go.
	GameState.water_metrics.source_accessible=false
	_dry_days(recent,9,today)
	assert_int(DryTowns.daily(today).size()).is_equal(0)
	assert_str(String(recent.status)).is_equal("established")

## The same rule for a computer-run people, in its own ledger; the god's
## Chronicle is not told of it.
func test_a_computer_peoples_dry_town_is_left_by_the_same_rule()->void:
	_settled_world()
	WorldSimulation.create_actor("gamma",4242,Vector2.ZERO)
	var entries:=(GameState.chronicle.get("entries",[]) as Array).size()
	var left:Array=WorldSimulation.scoped("gamma",func()->Array:
		var people=WorldSimulation.state
		people.initialize_population_model();people.ensure_population_total(400)
		people.settlement_site_committed=true;people.settlement_completed.assign(["Hearth Circle"])
		WorldSimulation.settlements.ensure_founded()
		people.water_metrics={"source_accessible":true,"source_distance_km":0.5}
		var sequence:=int(people.next_player_settlement_id)
		var record:={"id":"settlement_%03d" % sequence,"sequence":sequence,"primary":false,"name":"Dustwell","position":Vector2(20,0),"population_share":20.0/people.population_exact,"founded_day":0,"status":"established"}
		people.next_player_settlement_id+=1
		people.player_settlements.append(record)
		WorldSimulation.settlements._ensure_city_resources(record)
		for day in range(92,101):record.local_resources.water_history.append({"day":day,"source_distance_km":-1.0,"intake_ratio":0.0})
		return DryTowns.daily(100)
	)
	assert_int(left.size()).is_equal(1)
	assert_int(int(left[0].people)).is_equal(20)
	assert_str(String(WorldSimulation.actors.gamma.systems.GameState.player_settlements.back().status)).is_equal("abandoned")
	assert_int((GameState.chronicle.get("entries",[]) as Array).size()).is_equal(entries)

## Ashleyton left for lack of water, its families in Keansburg (the capital).
func _left_town(today:int=200)->Dictionary:
	GameState.elapsed_days=float(today)
	var dry:=_town("Ashleyton",HOME+Vector2(18,0),12.0)
	_dry_days(dry,9,today)
	return dry

## 1. What they own goes with them: stores, food and the cargo on its way.
func test_the_families_take_their_stores_and_cargo_with_them()->void:
	_settled_world()
	var dry:=_left_town()
	var capital_id:=String(SettlementModel.selected_settlement().id)
	SettlementModel.with_city_resources(String(dry.id),func()->void:
		GameState.resource_stockpiles["Timber"]=40.0
		FoodSystem.receive_external_food(300.0))
	GameState.city_trade_shipments.append({"id":901,"source_id":capital_id,"source_name":"Keansburg","destination_id":String(dry.id),"destination_name":"Ashleyton","resource":"Stone","quantity":7.0,"departure_day":199.0,"arrival_day":205.0,"travel_days":6.0,"status":"in_transit","day":199})
	var timber:=float(GameState.resource_stockpiles.get("Timber",0.0))
	var food:=FoodSystem.total_stored()
	var left:=DryTowns.daily(200)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal_approx(timber+40.0,.001)
	assert_float(FoodSystem.total_stored()).is_equal_approx(food+300.0,.001)
	assert_float(float(GameState.resource_stockpiles.Food)).is_equal_approx(FoodSystem.total_stored(),.001)
	var empty:Dictionary=SettlementModel.with_city_resources(String(dry.id),func()->Dictionary:return {"food":FoodSystem.total_stored(),"timber":float(GameState.resource_stockpiles.get("Timber",0.0))})
	assert_float(float(empty.food)).is_equal(0.0)
	assert_float(float(empty.timber)).is_equal(0.0)
	assert_str(String(GameState.city_trade_shipments.back().destination_id)).is_equal(capital_id)
	assert_int(int(left[0].redirected)).is_equal(1)
	assert_str(String((GameState.chronicle.entries as Array)[0].text)).contains("They took its stores with them.")
	# Cargo that reaches the empty place anyway goes on to where they went.
	GameState.city_trade_shipments.append({"id":902,"source_id":capital_id,"source_name":"Keansburg","destination_id":String(dry.id),"destination_name":"Ashleyton","resource":"Clay","quantity":5.0,"departure_day":195.0,"arrival_day":199.0,"travel_days":4.0,"status":"in_transit","day":195,"transport_mode":"cart"})
	var clay:=float(GameState.resource_stockpiles.get("Clay",0.0))
	SettlementModel.receive_city_trade_arrivals()
	assert_float(float(GameState.resource_stockpiles.get("Clay",0.0))).is_equal_approx(clay+5.0,.001)

## 2. Nobody lives there: no one-person floor, kept at 0 by every rebuild.
func test_an_empty_place_counts_nobody_and_stays_empty()->void:
	_settled_world()
	var dry:=_left_town()
	DryTowns.daily(200)
	assert_float(SettlementModel._settlement_population(dry)).is_equal(0.0)
	# Deaths elsewhere rebuild every town's share from its count.
	MilitaryCampaign.recovery._lose_people(3,"test")
	assert_float(float(dry.population_share)).is_equal(0.0)
	assert_int(preload("res://scripts/civilization_combat.gd").watch_of(dry)).is_equal(0)

## 3. A caravan coming home to a place its people left goes on to them.
func test_a_caravan_coming_home_finds_its_people()->void:
	_settled_world()
	var dry:=_left_town()
	DryTowns.daily(200)
	var convoy:={"active":true,"origin_id":String(dry.id),"origin_name":"Ashleyton","population_share":40.0/GameState.population_exact,"materials_committed":{"Timber":4.0}}
	GameState.settlement_convoy=convoy
	# Forty settlers on the road, counted in no town until they are back.
	var capital:=SettlementModel.primary_population_exact()
	var food:=FoodSystem.total_stored()
	var back:Dictionary=preload("res://scripts/caravan_system.gd")._dissolve_home(convoy,{"food":120.0,"population":40})
	assert_float(float(dry.population_share)).is_equal(0.0)
	assert_float(SettlementModel.primary_population_exact()).is_equal_approx(capital+40.0,.001)
	assert_float(FoodSystem.total_stored()).is_equal_approx(food+120.0,.001)
	assert_str(String(back.reason)).is_equal("The caravan returned to Keansburg.")

## 4. The named people who lived there live where they went; nobody leads
## the empty place, now or later.
func test_its_named_people_go_with_them()->void:
	_settled_world()
	ForeignDiplomacy.reset_for_new_world()
	var dry:=_left_town()
	GovernmentPeopleSystem.people.append({"person_id":9001,"name":"Orla Fenn","status":"active","home_settlement_id":String(dry.id),"local_leader_of":String(dry.id),"office_key":""})
	dry["leader_person_id"]=9001
	var Persons:=load("res://scripts/court_persons.gd")
	Persons.people().append({"id":"cp_test","name":"Tam","status":"living","settlement_id":String(dry.id),"village":"Ashleyton"})
	DryTowns.daily(200)
	var capital_id:=String(SettlementModel.selected_settlement().id)
	var orla:Dictionary=GovernmentPeopleSystem.people.back()
	assert_int(int(dry.leader_person_id)).is_equal(0)
	assert_str(String(orla.local_leader_of)).is_equal("")
	assert_str(String(orla.home_settlement_id)).is_equal(capital_id)
	assert_str(String(Persons.by_id("cp_test").settlement_id)).is_equal(capital_id)
	assert_str(String(Persons.by_id("cp_test").village)).is_equal("Keansburg")
	GovernmentPeopleSystem._ensure_local_leaders()
	assert_int(int(dry.leader_person_id)).is_equal(0)
	# Nor can the god name anyone to lead it (court or the people's page).
	var named:=GovernmentPeopleSystem.assign_settlement_leader(String(dry.id),9001)
	assert_bool(bool(named.ok)).is_false()
	assert_str(String(named.reason)).contains("Nobody lives in")
	assert_int(int(dry.leader_person_id)).is_equal(0)
	assert_str(String(orla.home_settlement_id)).is_equal(capital_id)
	ForeignDiplomacy.reset_for_new_world()

## 5. An empty place is not one of the towns we live in: not for the land we
## work, the hearths an aim counts, the nearest town for deliveries, or
## orders to build or turn its work.
func test_an_empty_place_is_not_counted_among_our_towns()->void:
	_settled_world()
	var Early:=preload("res://scripts/early_life_conditions.gd")
	var Aims:=load("res://scripts/legacy_aims.gd")
	var hearths:int=Aims._hearths()
	var dry:=_left_town()
	var riverford:=_town("Riverford",HOME+Vector2(25,0),50.0)
	DryTowns.daily(200)
	assert_str(String(dry.status)).is_equal("abandoned")
	assert_int(SettlementModel.lived_in().size()).is_equal(2)
	assert_int(int(Aims._hearths())).is_equal(hearths+1)
	# The land worked counts the two towns lived in, not the empty third.
	GameState.player_settlements.erase(dry)
	var two:=Early.carrying_capacity(GameState,DiscoverySystem)
	GameState.player_settlements.append(dry)
	assert_float(Early.carrying_capacity(GameState,DiscoverySystem)).is_equal_approx(two,.0001)
	dry["status"]="established"
	assert_float(Early.carrying_capacity(GameState,DiscoverySystem)).is_greater(two)
	dry["status"]="abandoned"
	# The nearest town for deliveries is the capital, not the nearer empty place.
	assert_str(String(SettlementModel.delivery_reach(String(riverford.id)).get("nearest",""))).is_not_equal("Ashleyton")
	var built:Dictionary=preload("res://scripts/settlement_construction.gd").set_priority(String(dry.id),"")
	assert_str(String(built.get("error",""))).is_equal("Nobody lives in Ashleyton now: its people left for lack of water.")
	var turned:Dictionary=GovernmentPeopleSystem.set_settlement_focus(String(dry.id),"shelter")
	assert_str(String(turned.get("reason",""))).is_equal("Nobody lives in Ashleyton now: its people left for lack of water.")

## The families go where people drank their fill, before a nearer town that
## went short.
func test_they_go_where_water_is_enough_before_a_nearer_town_short_of_it()->void:
	_settled_world()
	var today:=200
	GameState.elapsed_days=float(today)
	var dry:=_town("Ashleyton",HOME+Vector2(30,0),12.0)
	var short:=_town("Thinwell",HOME+Vector2(33,0),20.0)
	short.local_resources.water_metrics={"source_accessible":true,"source_distance_km":5.5,"intake_ratio":0.6}
	_dry_days(dry,9,today)
	var left:=DryTowns.daily(today)
	assert_str(String(left[0].to_name)).is_equal("Keansburg")
	assert_float(float(short.population_share)*GameState.population_exact).is_equal_approx(20.0,.001)

# --------------------------------------------------------------------------
# One name, one town
# --------------------------------------------------------------------------

func test_a_new_town_takes_no_name_another_people_already_uses()->void:
	_settled_world()
	var destination:=HOME+Vector2(20,0)
	var first:=SettlementModel.suggested_settlement_name(destination,"Keansburg")
	# A rival people already has a town by that name.
	WorldSimulation.create_actor("gamma",4242,Vector2.ZERO)
	WorldSimulation.actors.gamma.systems.GameState.player_settlements.append({"id":"settlement_009","name":first,"primary":false,"position":Vector2(300,0),"population_share":0.1})
	var second:=SettlementModel.suggested_settlement_name(destination,"Keansburg")
	assert_str(second).is_not_equal(first)
	assert_bool(SettlementModel.names_in_use().has(second.to_lower())).is_false()
	# And a region we know of another people.
	CivilizationSystem.civilizations.append({"id":"probe_people","strategic_regions":[{"name":second}]})
	var third:=SettlementModel.suggested_settlement_name(destination,"Keansburg")
	CivilizationSystem.civilizations.pop_back()
	assert_str(third).is_not_equal(second)
	assert_str(third).is_not_equal(first)

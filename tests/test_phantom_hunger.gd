extends GdUnitTestSuite
## The user's live play: 157 people, stores for 210 days, food brought in at
## over twice the need, a band camped about 25 km out and 17 holding Tsaren.
## The People screen said eight went short and a child was buried with "Food
## stores were exhausted". Soldiers' undelivered rations were being counted as
## hunger at home. Home intake now comes from home need and home meals; the
## band's shortfall stays with the band; the held town feeds its garrison.

const Rations:=preload("res://scripts/field_rations.gd")
const Supply:=preload("res://scripts/supply_state.gd")
const Kpi:=preload("res://scripts/hud/civilization_kpi_model.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")

var _processing:Dictionary={}
var civ_id:=""
var town_id:=""

func before_test()->void:
	if _processing.is_empty():
		for node:Node in [GameState,CivilizationSystem,MilitaryCampaign]: _processing[node]=node.is_processing()
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(5151);GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	FoodSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	GameState.ensure_population_total(157);GameState.housing_capacity=200
	GameState.settlement_site_committed=true;GameState.convoy_traveling=false;GameState.resource_settlement_id=""
	GameState.settlement_name="Seanstone"
	GameState.population_allocations.Logistics=0
	GameState.food_stocks={FoodSystem.FRESH:400.0,FoodSystem.STORED:30000.0}
	GameState.elapsed_days=400
	GameState.malnutrition_burden=0.0;GameState.nutrition_reserve=0.6;GameState.consecutive_food_shortage_days=0.0
	FoodSystem._lever_cache.clear()
	MilitaryCampaign.home_army=MilitaryCampaign._empty_home_army()
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ_id=String(civ.id)
	var region:Dictionary=civ.strategic_regions[CivilizationSystem._frontline_region_index(civ)]
	region["name"]="Tsaren";region["population"]=300.0
	town_id=String(region.id)

func after_test()->void:
	FoodSystem._lever_cache.clear()
	MilitaryCampaign.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	DiscoverySystem.reset_for_new_world()
	GameState.reset_for_new_world(5151)
	WorldSimulation.clear()
	for node:Node in _processing: node.set_process(bool(_processing[node]))

func _band_out(troops:int=30,km:float=25.0)->Dictionary:
	var origin:=CivilizationSystem.player_world_origin
	var at:={"x":origin.x+km,"z":origin.y}
	# Camped there long enough to eat out the country round it. On fresh
	# ground a band this small lives off the land in full (supply_state.gd).
	var band:={"army_id":7,"name":"LEVY BAND 1","troops":troops,"status":"stationed","location_id":"field","position":at,
		"camp_at":at.duplicate(),"forage_eaten":Supply.FORAGE_FEEDS*Supply.CAMP_FORAGE_DAYS,
		"formations":[],"supply_level":1.0,"commander":{"name":"Rovik Ashdown","logistics":0.3}}
	MilitaryCampaign.field_armies.assign([band])
	return band

func _hold_tsaren(troops:int=17,resistance:float=0.3)->void:
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	var ri:=CivilizationSystem._region_index(civ,town_id)
	civ.strategic_regions[ri]["controller"]="player"
	civ.strategic_regions[ri]["resistance"]=resistance
	MilitaryCampaign.occupation_forces.assign([{"civ_id":civ_id,"region_id":town_id,"region_name":"Tsaren","troops":troops,"formations":[],"supply_level":1.0,"commander":{"name":"Rovik Ashdown"}}])


func test_full_stores_and_a_poorly_supplied_band_leave_home_fed()->void:
	_band_out()
	assert_float(MilitaryCampaign.field_provision_delivery_ratio()).is_less(0.6)
	var result:Dictionary=FoodSystem.process_day({"traveling":false},1.0,0.9)
	# Home eats in full; the band's missing rations are the band's.
	assert_float(float(result.food_intake_ratio)).is_equal(1.0)
	assert_float(float(result.food_home_eaten)).is_equal_approx(float(result.food_home_need),0.0001)
	assert_float(float(result.army_provisions_short)).is_greater(0.0)
	var band:Dictionary=MilitaryCampaign.field_armies[0]
	assert_float(float(band.provision_ratio)).is_less(Rations.HUNGRY_BELOW)
	assert_float(float(band.provisions_foraged_today)).is_greater(0.0)
	# A few days of it and the band is told short of food, 25 km out.
	for day in 3: FoodSystem.process_day({"traveling":false},1.0,0.9)
	band=MilitaryCampaign.field_armies[0]
	assert_bool(Rations.is_hungry(band)).is_true()
	assert_float(float(GameState.malnutrition_burden)).is_less(0.03)
	var lines:=Rations.hungry_lines(MilitaryCampaign,CivilizationSystem.player_world_origin)
	assert_int(lines.size()).is_equal(1)
	assert_str(lines[0]).starts_with("Rovik's band is ")
	assert_str(lines[0]).ends_with(", about 25 km out.")

func test_people_screen_counts_home_folk_fed()->void:
	_band_out()
	var result:Dictionary=FoodSystem.process_day({"traveling":false},1.0,0.9)
	GameState.simulation_metrics.merge(result,true)
	var totals:=Kpi.snapshot()
	var fed:=EraWords.fed(int(totals.population),float(totals.food_eaten),float(totals.food_need))
	assert_int(fed).is_equal(int(totals.population))

func test_no_hunger_deaths_at_home_while_the_band_goes_short()->void:
	_band_out()
	GameState.consecutive_food_shortage_days=12.0
	GameState.malnutrition_burden=0.0
	ConsequenceEngine.process_day({"traveling":false})
	var hunger:=float((GameState.simulation_metrics.get("mortality_components",{}) as Dictionary).get("Hunger",-1.0))
	assert_float(hunger).is_equal(0.0)
	# Old shortage days from before the fix wear off once home is fed.
	assert_float(GameState.consecutive_food_shortage_days).is_less(12.0)

func test_real_famine_at_home_still_kills_and_says_the_stores_ran_out()->void:
	GameState.food_stocks={FoodSystem.FRESH:0.0,FoodSystem.STORED:0.0}
	GameState.resource_stockpiles["Food"]=0.0
	# The land gives nothing: wild food stripped, fields bare.
	for source in ["Wild gathering","Hunting","Fishing","Cultivation"]: GameState.food_source_health[source]=0.0
	GameState.consecutive_food_shortage_days=30.0
	ConsequenceEngine.process_day({"traveling":false})
	assert_float(float(GameState.simulation_metrics.get("food_intake_ratio",1.0))).is_less(0.5)
	var hunger:=float((GameState.simulation_metrics.get("mortality_components",{}) as Dictionary).get("Hunger",0.0))
	assert_float(hunger).is_greater(0.05)
	assert_str(ConsequenceEngine._hunger_detail(0.0,0.1)).contains("stores ran out")

func test_hunger_words_never_claim_empty_stores_when_they_are_full()->void:
	ConsequenceEngine._home_intake_today=1.0
	var said:=ConsequenceEngine._hunger_detail(210.0,2.84)
	assert_str(said).not_contains("ran out")
	assert_str(said).not_contains("%")
	ConsequenceEngine._home_intake_today=0.9
	assert_str(ConsequenceEngine._hunger_detail(210.0,2.84)).not_contains("ran out")

func test_the_garrison_of_a_held_town_eats_from_the_town()->void:
	_hold_tsaren()
	var credit:Dictionary=MilitaryCampaign.draw_delivered_field_rations(20.0)
	assert_float(float(credit.total)).is_greater(15.0)
	# Nothing reaches them from home at all; the town still feeds them.
	MilitaryCampaign.record_daily_provisions(20.0,0.0,credit)
	var garrison:Dictionary=MilitaryCampaign.occupation_forces[0]
	assert_float(float(garrison.provision_ratio)).is_greater_equal(Rations.HUNGRY_BELOW)
	assert_float(float(garrison.provisions_local_today)).is_greater(15.0)
	assert_bool(Rations.is_hungry(garrison)).is_false()

func test_garrison_rations_from_the_town_do_not_empty_home_stores()->void:
	_hold_tsaren()
	var result:Dictionary=FoodSystem.process_day({"traveling":false},1.0,0.9)
	assert_float(float(result.food_intake_ratio)).is_equal(1.0)
	assert_float(float(MilitaryCampaign.occupation_forces[0].provision_ratio)).is_greater_equal(Rations.HUNGRY_BELOW)

func test_a_resentful_town_feeds_less_but_never_nothing()->void:
	assert_float(Rations.occupation_local_share({"controller":"player","resistance":1.0})).is_equal_approx(0.5,0.0001)
	assert_float(Rations.occupation_local_share({"controller":"player","resistance":0.0})).is_equal_approx(0.95,0.0001)
	assert_float(Rations.occupation_local_share({"controller":"rival","resistance":0.0})).is_equal(0.0)

extends GdUnitTestSuite
## NO PEOPLE STARVES OR DIES OUT THROUGH ITS OWN MANAGEMENT. Two peoples of
## the player's year-187 world collapsed by rules, not by war:
## - the Oruq stopped having children at 49 people with 13 of their scouts
##   held abroad for good (each counted as one mother away) and died out of
##   old age; the Belath were on the same road (11 held, 1 mother of 43);
## - the Aruven kept commissioning war canoes until every adult was at the
##   paddles (the gate only counted adults), so nobody got food, and nothing
##   sent the crews home: 25 canoes, 100 crew, and the people starved.
## Every people, the god's and its rivals', runs on the same rules here:
## held scouts come home or die; people away take their share of mothers;
## a ruler's ships and wings come out of the army's own share of the people;
## a hungry people lays its ships up and sends its men home to the food.

const C:=preload("res://scripts/civilization_controller.gd")
const Day:=preload("res://scripts/civilization_day.gd")
const ORIGIN:=Vector2(14.0,-9.0)

var _processing:Dictionary={}

func before()->void:
	for node:Node in [GameState,CivilizationSystem,MilitaryCampaign,ProgressionSystem]:_processing[node]=node.is_processing()

func after()->void:
	for node:Node in _processing:node.set_process(bool(_processing[node]))

func before_test()->void:
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(51787);GameState.civic_api_enabled=false
	ResourceSystem.reset_for_new_world();FoodSystem.reset_for_new_world();SettlementModel.reset_for_new_world()
	DiscoverySystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world();PeopleDirection.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.ensure_population_total(120)
	GameState.housing_capacity=160
	GameState.settlement_name="Caerst"
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	GameState.settlement_founded_at=Vector3(ORIGIN.x,0.0,ORIGIN.y)
	GameState.elapsed_days=100*365
	CivilizationSystem.register_player_origin(ORIGIN)
	SettlementModel.ensure_founded()
	GovernmentPeopleSystem.initialize()
	PeopleDirection.ensure()

func after_test()->void:
	GameState.elapsed_days=0
	MilitaryCampaign.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	ResourceSystem.reset_for_new_world()
	SettlementModel.reset_for_new_world()
	DiscoverySystem.reset_for_new_world()
	PeopleDirection.reset_for_new_world()
	GameState.reset_for_new_world(74017)
	WorldSimulation.clear()

## A naval base at home and `canoes` war canoes standing by in it, four
## paddlers each, as a ruler's commissions leave them.
func _fleet(canoes:int)->void:
	var op=MilitaryCampaign.joint_operations
	var city:=String(GameState.player_settlements[0].id)
	op.state.bases.append({"id":1,"owner":"player","city_id":city,"name":"Caerst Naval Base","domain":"navy","position":{"x":ORIGIN.x,"z":ORIGIN.y},"capacity":20,"condition":1.0,"construction_work":30.0,"required_work":30.0})
	for i in canoes:
		var id:=10+i
		op.state.forces.append({"id":id,"owner":"player","name":"War Canoes Task Force","domain":"navy","base_id":1,"units":{"war_canoe":1},"authorized":{"war_canoe":1},
			"mission":"hold","region":{},"status":"Standing by at base","training":1.0,"condition":1.0,"experience":0.0,"efficiency":0.0,"auto_replace":true,"repair_threshold":.6,
			"fuel_used":0,"loss_fraction":0.0,"damage":0.0,"position":{"x":ORIGIN.x,"z":ORIGIN.y},"route":[],"carrier_id":0,"fleet_id":id,"regions":[]})
	op.state.next_id=100

## The day's context at home, with the river close by (a bare test world
## has no measured water; the long run is about food, not thirst).
func _watered()->Dictionary:
	var context:=Day.context(ORIGIN)
	context.merge({"surface_water_distance_km":0.4,"freshwater":1.0},true)
	return context

func _hungry()->Dictionary:
	return {"hungry":true,"food_shortage":true,"at_war":false}

# --------------------------------------------------------------------------
# Scouts held abroad (the Oruq, the Belath)
# --------------------------------------------------------------------------

func test_scouts_held_abroad_come_home_or_die_and_never_outnumber_the_people()->void:
	var holder:=String(CivilizationSystem.civilizations[0].id)
	var day:=int(GameState.elapsed_days)
	CivilizationSystem.captured_player_scouts[holder]={"count":12,"captured_day":day}
	var people:=GameState.population_total
	# Held, they are away: counted out of those who can work and bear children.
	assert_int(int(CivilizationSystem.player_population_commitments().total_absent)).is_equal(12)
	# Within a month nothing changes.
	var early:=CivilizationSystem.age_held_scouts(day+10)
	assert_int(int(early.home)+int(early.died)).is_equal(0)
	var home:=0;var died:=0
	for month in 24:
		var step:=CivilizationSystem.age_held_scouts(day+30*(month+1))
		home+=int(step.home);died+=int(step.died)
	var left:=int((CivilizationSystem.captured_player_scouts.get(holder,{}) as Dictionary).get("count",0))
	# Every one is accounted for: home, dead there, or still held.
	assert_int(home+died+left).is_equal(12)
	# About a quarter a year get home and about one in twelve dies held:
	# two years, about five home and one or two dead.
	assert_int(home).is_between(4,7)
	assert_int(died).is_between(1,3)
	# The dead are counted dead once; those home were never counted gone.
	assert_int(GameState.population_total).is_equal(people-died)
	assert_int(int(CivilizationSystem.player_population_commitments().total_absent)).is_equal(left)
	# Told in the people's own record.
	var told:=false
	for event:Dictionary in CivilizationSystem.world_events:
		if String(event.get("kind",""))=="held_scouts":told=true
	assert_bool(told).is_true()

func test_a_people_never_has_more_held_abroad_than_it_has_adults()->void:
	var holder:=String(CivilizationSystem.civilizations[0].id)
	var day:=int(GameState.elapsed_days)
	# The Oruq: 13 held, a people of one.
	CivilizationSystem.captured_player_scouts[holder]={"count":500,"captured_day":day,"aged_day":day}
	var people:=GameState.population_total
	var adults:=floori(float(GameState.population_cohorts.working_age))
	var step:=CivilizationSystem.age_held_scouts(day)
	assert_int(int((CivilizationSystem.captured_player_scouts[holder] as Dictionary).count)).is_equal(adults)
	assert_int(int(step.gone)).is_equal(500-adults)
	# Nobody is counted dead twice: they were already gone with their people.
	assert_int(GameState.population_total).is_equal(people)

func test_scouts_held_by_the_gods_people_wait_for_the_court()->void:
	var day:=int(GameState.elapsed_days)
	CivilizationSystem.captured_player_scouts["human"]={"count":3,"captured_day":day}
	CivilizationSystem.age_held_scouts(day+5*365)
	assert_int(int((CivilizationSystem.captured_player_scouts["human"] as Dictionary).count)).is_equal(3)

func test_people_away_take_their_share_of_the_mothers_not_one_each()->void:
	GameState.ensure_population_total(43)
	var adults:=float(GameState.population_cohorts.working_age)
	var context:={"health":0.97,"food_security":0.98,"housing_ratio":1.12,"cohesion":0.96}
	var pregnancy:=GameState.pregnancy_cohorts.duplicate(true)
	var cohorts:=GameState.population_cohorts.duplicate(true)
	var at_home:=float(GameState.process_reproduction_day(context.merged({"absent_adults":0.0})).annual_conceptions_expected)
	GameState.pregnancy_cohorts=pregnancy.duplicate(true);GameState.population_cohorts=cohorts.duplicate(true)
	# Belath, year 187: 11 of about 38 adults held abroad.
	var away:=float(GameState.process_reproduction_day(context.merged({"absent_adults":11.0})).annual_conceptions_expected)
	GameState.pregnancy_cohorts=pregnancy.duplicate(true);GameState.population_cohorts=cohorts.duplicate(true)
	var everyone:=float(GameState.process_reproduction_day(context.merged({"absent_adults":adults})).annual_conceptions_expected)
	assert_float(at_home).is_greater(0.5)
	# About their share fewer (11 of the adults), never one mother each
	# (which left Belath one mother and a third of a child a year).
	var share:=11.0/adults
	assert_float(away/at_home).is_between(1.0-share-0.12,1.0-share+0.05)
	var mothers:=GameState._reproductive_age_population()
	assert_float(away/at_home).is_greater(maxf(0.0,(mothers-11.0)/mothers)+0.15)
	assert_float(everyone).is_equal_approx(0.0,0.001)

# --------------------------------------------------------------------------
# Ships' crews and hunger (the Aruven)
# --------------------------------------------------------------------------

func test_ships_crews_come_out_of_the_armys_share_and_never_while_hungry()->void:
	# Aruven before the famine: about 150 people, 100 adults, a ruler whose
	# army may take a little under 8 in 100 (11 people).
	var share_cap:=roundi(150.0*0.076)
	assert_bool(C.may_commission(4,4,share_cap,100,false)).is_true()
	assert_bool(C.may_commission(8,4,share_cap,100,false)).is_false()
	# Under the old gate (adults only) the 25th canoe still fit.
	assert_bool(96+4<=100).is_true()
	assert_bool(C.may_commission(96,4,share_cap,100,false)).is_false()
	# A hungry people builds no ships at all.
	assert_bool(C.may_commission(0,4,share_cap,100,true)).is_false()

func test_a_fleet_of_every_adult_leaves_nobody_to_get_food()->void:
	var adults:=floori(float(GameState.population_cohorts.working_age))
	_fleet(ceili(float(adults)/4.0))
	# The mechanism that starved the Aruven: every civilian hand displaced.
	assert_float(GameState.civilian_workforce_fraction()).is_less(0.05)
	assert_float(GameState.effective_workers("Food")).is_less(1.0)

func test_a_hungry_ruler_lays_up_its_ships_and_sends_the_crews_home()->void:
	_fleet(20)
	var crew:=int(MilitaryCampaign.joint_operations.personnel())
	assert_int(crew).is_equal(80)
	var gear:=int(MilitaryCampaign.military_inventory.get("war_canoe_equipment",0))
	# Fed: nothing is laid up.
	var calm:=C.hunger_stand_down("player",{"hungry":false,"food_shortage":false,"at_war":false},0)
	assert_int(int(calm.laid_up)).is_equal(0)
	assert_int(MilitaryCampaign.joint_operations.state.forces.size()).is_equal(20)
	# Hungry at peace: every canoe at its base is laid up, its crew home.
	var out:=C.hunger_stand_down("player",_hungry(),0)
	assert_int(int(out.laid_up)).is_equal(20)
	assert_int(int(out.released)).is_equal(80)
	assert_int(MilitaryCampaign.joint_operations.state.forces.size()).is_equal(0)
	# The craft go back to the stores, ready again when the people are fed.
	assert_int(int(MilitaryCampaign.military_inventory.get("war_canoe_equipment",0))).is_equal(gear+20)
	assert_int(MilitaryCampaign._mobilized_count()).is_less_equal(int(GameState.population_allocations.get("Defense",0)))
	assert_float(GameState.civilian_workforce_fraction()).is_greater(0.95)
	assert_float(GameState.effective_workers("Food")).is_greater(10.0)

func test_at_war_a_hungry_ruler_keeps_only_the_ordinary_share_under_arms()->void:
	_fleet(10)
	var out:=C.hunger_stand_down("player",{"hungry":true,"food_shortage":true,"at_war":true},12)
	# 40 crew, keep 12: canoes are laid up until no more than 12 are at the paddles.
	assert_int(MilitaryCampaign._mobilized_count()).is_less_equal(12)
	assert_int(int(out.laid_up)).is_equal(7)

## The long run: a people of 120 with every adult in its canoes and nothing
## put by. Its ruler reviews each month as the controller does; within the
## first review its crews are home, it gets food again, and three months on
## it is fed and nearly whole (none starve to nothing).
func test_a_starving_fleet_people_sends_its_crews_home_and_lives()->void:
	var adults:=floori(float(GameState.population_cohorts.working_age))
	_fleet(ceili(float(adults)/4.0))
	FoodSystem.reset_for_new_world()
	GameState.food_stocks={"Fresh food":0.0,"Stored food":0.0}
	GameState.resource_stockpiles["Food"]=0.0
	var start:=GameState.population_total
	var produced_after_review:=0.0
	for i in 90:
		var day:=int(GameState.elapsed_days)+1
		Day.advance(day,_watered())
		if i==0:
			# The first day, every hand at the paddles: nothing got, nothing eaten.
			assert_float(float(GameState.simulation_metrics.get("food_production",-1.0))).is_equal_approx(0.0,0.01)
			assert_float(float(GameState.simulation_metrics.get("food_intake_ratio",1.0))).is_less(0.05)
			# The ruler sees it at once (food days 0, intake 0): hungry, short.
			var plan:=C.current_plan("player")
			assert_bool(bool(plan.food_shortage)).is_true()
		# The ruler's monthly review (civilization_controller.military_orders).
		if i%30==0:C.hunger_stand_down("player",C.current_plan("player"),0)
		if i==5:produced_after_review=float(GameState.simulation_metrics.get("food_production",0.0))
	assert_int(MilitaryCampaign.joint_operations.state.forces.size()).is_equal(0)
	assert_float(produced_after_review).is_greater(float(GameState.simulation_metrics.get("food_consumption",0.0)))
	assert_float(float(GameState.simulation_metrics.get("food_production",0.0))).is_greater(float(GameState.simulation_metrics.get("food_consumption",0.0))*0.9)
	assert_float(float(GameState.simulation_metrics.get("food_intake_ratio",0.0))).is_greater_equal(0.99)
	assert_int(GameState.population_total).is_greater_equal(roundi(start*0.97))

extends GdUnitTestSuite
## KEEPING WATCH IS THE MILITARY (docs/PEOPLE_FIRST.md, workstream E;
## scripts/watch_military.gd). The share of the people set to keep watch is
## the military's manpower: there is no separate recruiting, raising the
## share raises manpower, and drill happens within the watch over time. The
## watch splits into the home guard (spread over home and the towns by
## their people, the defender ledger) and the offensive troops (the bands).
## Bands away do not defend. An older save's army folds into the watch
## without losing or making anyone. Every people follows the same rules.

const Watch:=preload("res://scripts/watch_military.gd")
const Combat:=preload("res://scripts/civilization_combat.gd")
const Council:=preload("res://scripts/war_council.gd")
const DAY:=preload("res://scripts/civilization_day.gd")
const Controller:=preload("res://scripts/civilization_controller.gd")

const TOWN:="settlement_002"

var _processing:Dictionary={}


func before_test()->void:
	if _processing.is_empty():
		for node:Node in [GameState,CivilizationSystem,MilitaryCampaign,ProgressionSystem]:_processing[node]=node.is_processing()
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(6062);GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world();FoodSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	SettlementModel.reset_for_new_world();PeopleDirection.reset_for_new_world()
	GameState.ensure_population_total(400);GameState.housing_capacity=500
	GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"];GameState.settlement_name="SEANSTONE"
	GameState.resource_stockpiles["Food"]=100000.0
	SettlementModel.ensure_founded()
	MilitaryCampaign.home_army=MilitaryCampaign._empty_home_army()


func after_test()->void:
	GameState.elapsed_days=0
	MilitaryCampaign.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	DiscoverySystem.reset_for_new_world()
	SettlementModel.reset_for_new_world()
	GameState.reset_for_new_world(74017)
	PeopleDirection.reset_for_new_world()
	WorldSimulation.clear()
	WorldSimulation.context_provider=Callable()
	for node:Node in _processing:node.set_process(bool(_processing[node]))


## A second town where a quarter of the people live.
func _second_town()->void:
	var second:Dictionary={"id":TOWN,"sequence":2,"primary":false,"name":"Valebridge","position":Vector2(100,0),"population_share":.25,"founded_day":0,"status":"established","territory_context":{},"environment_profile":{}}
	GameState.player_settlements.append(second);GameState.next_player_settlement_id=3;SettlementModel._ensure_city_resources(second)


## The watch set to `share` of the people, filled at home.
func _watch(share:float)->int:
	MilitaryCampaign.set_watch_share(share)
	MilitaryCampaign.keep_watch()
	return MilitaryCampaign.watch_manpower()


## Everyone the watch accounts for, part by part (watch_military reading).
func _parts(r:Dictionary)->int:
	return int(r.guard)+int(r.offensive)+int(r.not_ready)


# ---------------------------------------------------------------------------
# The watch share is the manpower
# ---------------------------------------------------------------------------

func test_the_watch_share_is_the_manpower()->void:
	var watch:=_watch(0.05)
	assert_int(watch).is_equal(roundi(float(GameState.population_total)*0.05))
	assert_int(int(GameState.population_allocations.Defense)).is_equal(watch)
	# Everyone keeping watch is under arms, at home, counted once.
	assert_int(MilitaryCampaign._mobilized_count()).is_equal(watch)
	assert_int(int(MilitaryCampaign.home_army.troops)).is_equal(watch)
	assert_int(int(MilitaryCampaign.personnel_ledger().total)).is_equal(watch)
	# One ledger: the watch is the Defense work, so nobody else's work is
	# displaced by it.
	assert_float(GameState.civilian_workforce_fraction()).is_equal(1.0)
	# Raising the share raises the manpower, and the day's keeping does it.
	MilitaryCampaign.set_watch_share(0.10)
	var day:=int(GameState.elapsed_days)+1
	GameState.elapsed_days=day;MilitaryCampaign.last_processed_day=day
	MilitaryCampaign._process_military_day()
	assert_int(MilitaryCampaign.watch_manpower()).is_equal(roundi(float(GameState.population_total)*0.10))
	assert_int(MilitaryCampaign._mobilized_count()).is_equal(MilitaryCampaign.watch_manpower())


func test_there_is_no_recruit_step()->void:
	var watch:=_watch(0.05)
	var r:Dictionary=MilitaryCampaign.raise_recruits(10)
	# Calling ten up sets ten more to keep watch: the share rises by them.
	assert_int(int(r.raised)).is_equal(10)
	assert_int(MilitaryCampaign.watch_manpower()).is_equal(watch+10)
	MilitaryCampaign.keep_watch()
	# Nobody waits to be called up or sits in a course: they join the watch.
	assert_int(int(MilitaryCampaign.aggregate_recruits)).is_equal(0)
	assert_bool(MilitaryCampaign.training_queue.is_empty()).is_true()
	assert_int(int(MilitaryCampaign.home_army.troops)).is_equal(watch+10)
	assert_int(MilitaryCampaign._mobilized_count()).is_equal(MilitaryCampaign.watch_manpower())
	# They join raw and drill within the watch over time.
	var drill:=Watch.drill_of(MilitaryCampaign.home_army.formations)
	assert_float(drill).is_less_equal(Watch.START_DRILL+0.0001)
	for i in 120:Watch.drill_day(MilitaryCampaign)
	var drilled:=Watch.drill_of(MilitaryCampaign.home_army.formations)
	assert_float(drilled).is_greater(drill+0.05)
	# Never past what our people can teach the unarmed and the armed.
	for f in MilitaryCampaign.home_army.formations:
		var formation:Dictionary=f
		assert_float(float(formation.training)).is_less_equal(float(MilitaryCampaign._training_quality(String(formation.unit),float(formation.experience)))+0.0001)


func test_a_people_given_to_war_drills_a_little_harder()->void:
	# A balanced watch (5 in 100 of the people or fewer) has no edge: the
	# historical ranges hold.
	_watch(0.05)
	assert_float(Watch.martial_edge(MilitaryCampaign)).is_equal(0.0)
	for i in 400:Watch.drill_day(MilitaryCampaign)
	var balanced:=Watch.drill_of(MilitaryCampaign.home_army.formations)
	# All in on war: a fifth of the people keep watch. More of them, a little
	# better drilled, never wildly so; and many fewer at other work.
	var food_before:=int(GameState.population_allocations.Food)
	MilitaryCampaign.set_watch_share(0.20)
	assert_float(Watch.martial_edge(MilitaryCampaign)).is_equal(1.0)
	assert_int(int(GameState.population_allocations.Food)).is_less(food_before)
	for f in MilitaryCampaign.home_army.formations:(f as Dictionary)["training"]=balanced
	for i in 400:Watch.drill_day(MilitaryCampaign)
	var martial:=Watch.drill_of(MilitaryCampaign.home_army.formations)
	assert_float(martial).is_greater(balanced)
	assert_float(martial-balanced).is_less_equal(Watch.MARTIAL_DRILL+0.0001)
	var r:=MilitaryCampaign.watch_reading()
	assert_float(float(r.martial_drill)).is_equal_approx(Watch.MARTIAL_DRILL,0.0001)


func test_arms_pass_through_the_one_weapons_accessor()->void:
	var item:=String(Watch.arms_kit(MilitaryCampaign).item)
	MilitaryCampaign.military_inventory[item]=12
	_watch(0.05)
	# Twelve sets taken from the store for the twenty who joined; the rest
	# fight with what comes to hand.
	assert_int(Watch.weapons_held(MilitaryCampaign,item)).is_equal(0)
	var issued:=0
	for f in MilitaryCampaign.home_army.formations:issued+=int((f as Dictionary).equipment)
	assert_int(issued).is_equal(12)
	# Sent home to their work, their sets go back to the store.
	MilitaryCampaign.set_watch_share(0.0)
	assert_int(int(MilitaryCampaign.home_army.troops)).is_equal(0)
	assert_int(Watch.weapons_held(MilitaryCampaign,item)).is_equal(12)
	# What the watch carries is read from its own formations: one ledger.
	MilitaryCampaign._rebuild_home_army_with([{"id":77,"unit":"levy","weapon":"spear","count":6,"authorized_count":6,"equipment":4,"equipment_required":6,"ammunition":0,"ammunition_required":0,"training":0.4,"experience":0.0,"personnel_condition":1.0}])
	assert_int(Watch.weapons_carried(MilitaryCampaign)).is_equal(4)


func test_no_drill_when_the_training_policy_suspends_it()->void:
	_watch(0.05)
	MilitaryCampaign.training_staff.set_policy("army","suspended")
	var before:=Watch.drill_of(MilitaryCampaign.home_army.formations)
	for i in 30:Watch.drill_day(MilitaryCampaign)
	assert_float(Watch.drill_of(MilitaryCampaign.home_army.formations)).is_equal(before)


func test_lowering_the_watch_sends_the_least_drilled_home_never_a_band()->void:
	var watch:=_watch(0.10)
	for f in MilitaryCampaign.home_army.formations:(f as Dictionary)["training"]=0.6
	MilitaryCampaign.raise_recruits(6)
	MilitaryCampaign.keep_watch()
	var drill:=Watch.drill_of(MilitaryCampaign.home_army.formations)
	assert_bool(MilitaryCampaign.create_field_army(12).has("ok")).is_true()
	var band:Dictionary=MilitaryCampaign.field_armies[0]
	band["location_id"]="the_marches";band["status"]="stationed"
	var serving:=MilitaryCampaign._mobilized_count()
	assert_int(serving).is_equal(watch+6)
	var people:=GameState.population_exact
	MilitaryCampaign.set_watch_share(0.05)
	var lower:=MilitaryCampaign.watch_manpower()
	# Everyone above the share at home went back to work; the band is whole.
	assert_int(int(MilitaryCampaign.field_armies[0].troops)).is_equal(12)
	assert_int(MilitaryCampaign._mobilized_count()).is_equal(lower)
	assert_int(int(MilitaryCampaign.home_army.troops)).is_equal(lower-12)
	# The least drilled formations go first; nobody's drill is lost by it.
	assert_float(Watch.drill_of(MilitaryCampaign.home_army.formations)).is_greater_equal(drill-0.0001)
	# Sent home to work, not lost.
	assert_float(GameState.population_exact).is_equal(people)
	# A band larger than the share stays out; the people above the share are
	# away from their work until it comes home.
	MilitaryCampaign.set_watch_share(0.0)
	assert_int(int(MilitaryCampaign.field_armies[0].troops)).is_equal(12)
	assert_int(int(MilitaryCampaign.home_army.troops)).is_equal(0)
	assert_float(GameState.civilian_workforce_fraction()).is_less(1.0)


# ---------------------------------------------------------------------------
# The split: home guard and offensive troops
# ---------------------------------------------------------------------------

func test_the_split_between_home_guard_and_offensive_troops_adds_up()->void:
	var watch:=_watch(0.10)
	var split:=MilitaryCampaign.set_watch_split(0.25)
	assert_bool(split.has("ok")).is_true()
	var r:=MilitaryCampaign.watch_reading()
	assert_int(int(r.guard_target)).is_equal(roundi(float(watch)*0.25))
	assert_int(int(r.guard)).is_equal(int(r.guard_target))
	assert_int(int(r.offensive_home)).is_equal(watch-int(r.guard))
	assert_int(_parts(r)).is_equal(int(r.serving))
	# The war council sends only the offensive troops; the home guard stays.
	var forces:Dictionary=Council._forces()
	assert_int(int(forces.keep)).is_equal(int(r.guard))
	assert_int(int(forces.free)).is_equal(int(r.offensive_home))
	# A band formed from them is still the offensive troops, counted once.
	assert_bool(MilitaryCampaign.create_field_army(12).has("ok")).is_true()
	r=MilitaryCampaign.watch_reading()
	assert_int(int(r.away)).is_equal(12)
	assert_int(int(r.offensive)).is_equal(watch-int(r.guard))
	assert_int(_parts(r)).is_equal(int(r.serving))
	assert_int(int(r.serving)).is_equal(watch)
	# More at home: the guard grows from those at home, none made.
	MilitaryCampaign.set_watch_split(0.75)
	r=MilitaryCampaign.watch_reading()
	assert_int(int(r.guard)).is_equal(mini(roundi(float(watch)*0.75),int(r.at_home)))
	assert_int(_parts(r)).is_equal(int(r.serving))


func test_a_computer_rulers_split_follows_its_temper()->void:
	var bold:=Watch.default_home_share({"assertiveness":0.9,"risk_tolerance":0.9,"empathy":0.1})
	var careful:=Watch.default_home_share({"assertiveness":0.1,"risk_tolerance":0.1,"empathy":0.9})
	assert_float(bold).is_less(careful)
	assert_float(Watch.default_home_share({"assertiveness":0.5,"risk_tolerance":0.5,"empathy":0.5},true)).is_less(Watch.default_home_share({"assertiveness":0.5,"risk_tolerance":0.5,"empathy":0.5},false))
	for share in [bold,careful]:
		assert_float(share).is_between(0.10,0.60)


# ---------------------------------------------------------------------------
# The defender ledger follows
# ---------------------------------------------------------------------------

func test_the_home_guard_defends_home_and_the_towns_by_their_people()->void:
	_second_town()
	var watch:=_watch(0.10)
	MilitaryCampaign.set_watch_split(0.5)
	var guard:=int(MilitaryCampaign.watch_reading().guard)
	var ledger:=Combat.guard_ledger()
	var home_id:=String(Combat._home_record().id)
	# Spread by their people: a quarter of the people, a quarter of the guard.
	assert_int(int(ledger[TOWN].watch)).is_equal(roundi(float(guard)*0.25))
	assert_int(int(ledger[TOWN].watch)+int(ledger[home_id].watch)).is_equal(guard)
	# The townsfolk still rise beside them.
	assert_int(int(ledger[TOWN].rise)).is_greater(0)
	var town_force:=Combat.town_watch(TOWN)
	assert_int(int(town_force.troops)).is_equal(int(ledger[TOWN].watch)+int(ledger[TOWN].rise))
	# Home stands with everyone at home but the guard posted in the town.
	var posted:=Combat.posted_away()
	assert_int(posted).is_equal(int(ledger[TOWN].watch))
	var home_force:=MilitaryCampaign._home_defense_force(false)
	var rise:=int(Combat.home_militia().rise)
	assert_int(int(home_force.troops)).is_equal(watch-posted+rise)
	var parts:=Combat.home_defenders()
	assert_int(int(parts.trained)+int(parts.watch)+int(parts.rise)).is_equal(int(home_force.troops))
	assert_int(Combat.defenders(home_id)).is_equal(int(home_force.troops))
	assert_int(Combat.defenders(TOWN)).is_equal(int(town_force.troops))
	# The guard posted away comes back to home's formations after a fight at
	# home: nobody is made or lost by the posting.
	var mustered:=MilitaryCampaign._home_defense_force(true)
	var back:Dictionary=mustered.get("posted_guard",{})
	var taken:=0
	for key in back:taken+=int((back[key] as Dictionary).count)
	assert_int(taken).is_equal(posted)
	var fought:Array=[]
	for f in mustered.formations:
		if int((f as Dictionary).get("id",-1))!=int(mustered.get("emergency_militia_id",-2)):fought.append((f as Dictionary).duplicate(true))
	MilitaryCampaign.home_army["formations"]=fought
	MilitaryCampaign.home_army["troops"]=watch-posted
	MilitaryCampaign._return_posted_guard(back)
	assert_int(int(MilitaryCampaign.home_army.troops)).is_equal(watch)
	var counted:=0
	for f in MilitaryCampaign.home_army.formations:counted+=int((f as Dictionary).count)
	assert_int(counted).is_equal(watch)


func test_the_guard_posted_away_leaves_home_as_well_armed_as_before()->void:
	_second_town()
	GameState.population_allocations["Defense"]=40
	# Forty spearmen at home, half of them with spears in hand.
	var sets:int=MilitaryCampaign._equipment_required_for("spearman",40)
	MilitaryCampaign._rebuild_home_army_with([{"id":5,"unit":"spearman","weapon":"spear","count":40,"authorized_count":40,"equipment":sets/2,"equipment_required":sets,"ammunition":0,"ammunition_required":0,"training":0.5,"experience":0.0,"personnel_condition":1.0}])
	MilitaryCampaign.next_formation_id=6
	MilitaryCampaign.set_watch_split(0.5)
	var posted:=Combat.posted_away()
	assert_int(posted).is_greater(0)
	var force:=MilitaryCampaign._home_defense_force(true)
	for f in force.formations:
		var formation:Dictionary=f
		if int(formation.get("id",0))!=5:continue
		# Those left at home keep the same share of their gear in hand: the
		# places of those posted away went with them.
		assert_int(int(formation.count)).is_equal(40-posted)
		assert_int(int(formation.authorized_count)).is_equal(40-posted)
		assert_float(float(formation.equipment)/float(formation.equipment_required)).is_equal_approx(0.5,0.08)
	# Back after the fight: the same places, gear and men.
	var fought:Array=(force.formations as Array).filter(func(f:Dictionary)->bool:return int(f.get("id",0))==5).map(func(f:Dictionary)->Dictionary:return f.duplicate(true))
	MilitaryCampaign.home_army["formations"]=fought
	MilitaryCampaign.home_army["troops"]=40-posted
	MilitaryCampaign._return_posted_guard(force.posted_guard)
	var home:Dictionary=MilitaryCampaign.home_army.formations[0]
	assert_int(int(home.count)).is_equal(40)
	assert_int(int(home.authorized_count)).is_equal(40)
	assert_int(int(home.equipment)).is_equal(sets/2)
	assert_int(int(home.equipment_required)).is_equal(sets)
	# The guard in the town carries its share of the arms too.
	var town:=Combat.town_watch(TOWN)
	var guard_block:Dictionary=(town.formations as Array)[0]
	assert_str(String(guard_block.weapon)).is_equal("spear")
	assert_float(float(guard_block.equipment)/float(guard_block.equipment_required)).is_equal_approx(0.5,0.15)


func test_a_town_fight_while_home_fights_takes_its_guard_off_that_fight()->void:
	_second_town()
	var watch:=_watch(0.10)
	MilitaryCampaign.set_watch_split(1.0)
	var mustered:=MilitaryCampaign._home_defense_force(true)
	var posted:=Watch.posted_men(mustered.posted_guard)
	assert_int(posted).is_greater(0)
	# A fight at home is still being fought.
	MilitaryCampaign.own_engagements["home_fight"]={"id":"home_fight","home_force_kind":"field","home_force_id":0,"home_side":"defender","defender":mustered,"attacker":{},"status":"active"}
	assert_bool(Watch.home_fight_pending(MilitaryCampaign)).is_true()
	# Nothing moves at home meanwhile, whatever the share says.
	GameState.population_allocations["Defense"]=watch+20
	assert_int(int(MilitaryCampaign.keep_watch().joined)).is_equal(0)
	GameState.population_allocations["Defense"]=watch
	var parts:Dictionary=Combat.guard_ledger()[TOWN]
	var share:=float(int(parts.watch))/float(int(parts.watch)+int(parts.rise))
	MilitaryCampaign._apply_town_watch_result(TOWN,{},[{"defender_casualties":{"killed":4,"wounded":2}}],"defender")
	var dead:=roundi(4.0*share);var hurt:=roundi(2.0*share)
	# The host at home is untouched; what the fight gives back lost them.
	assert_int(int(MilitaryCampaign.home_army.troops)).is_equal(watch)
	assert_int(Watch.posted_men(mustered.posted_guard)).is_equal(posted-dead-hurt)
	# The fight at home ends with no loss: the host is those who fought and
	# the posted guard given back; the dead stay dead, the hurt mend.
	MilitaryCampaign.own_engagements.erase("home_fight")
	var fought:Array=(mustered.formations as Array).filter(func(f:Dictionary)->bool:return int(f.get("id",-1))!=int(mustered.get("emergency_militia_id",-2))).map(func(f:Dictionary)->Dictionary:return f.duplicate(true))
	MilitaryCampaign.home_army["formations"]=fought
	MilitaryCampaign.home_army["troops"]=watch-posted
	MilitaryCampaign._return_posted_guard(mustered.posted_guard)
	assert_int(int(MilitaryCampaign.home_army.troops)).is_equal(watch-dead-hurt)
	assert_int(int(MilitaryCampaign.home_army.get("wounded_pool",0))).is_equal(hurt)
	assert_int(MilitaryCampaign._mobilized_count()).is_equal(watch-dead)


func test_more_at_home_calls_idle_bands_home()->void:
	var watch:=_watch(0.10)
	MilitaryCampaign.set_watch_split(0.2)
	assert_bool(MilitaryCampaign.create_field_army(30).has("ok")).is_true()
	assert_int(int(MilitaryCampaign.home_army.troops)).is_equal(watch-30)
	# All of the watch kept home: the idle band at home folds back into it.
	var result:=MilitaryCampaign.set_watch_split(1.0)
	assert_int(int(result.called)).is_equal(30)
	assert_bool(MilitaryCampaign.field_armies.is_empty()).is_true()
	assert_int(int(MilitaryCampaign.watch_reading().guard)).is_equal(watch)


func test_a_swing_of_one_moves_nobody()->void:
	var watch:=_watch(0.05)
	GameState.population_allocations["Defense"]=watch+1
	assert_int(int(MilitaryCampaign.keep_watch().joined)).is_equal(0)
	GameState.population_allocations["Defense"]=watch+2
	assert_int(int(MilitaryCampaign.keep_watch().joined)).is_equal(2)
	GameState.population_allocations["Defense"]=watch+1
	assert_int(int(MilitaryCampaign.keep_watch().released)).is_equal(0)


func test_those_away_do_not_build_walls_or_keep_order_at_home()->void:
	var watch:=_watch(0.10)
	assert_int(MilitaryCampaign.watch_at_home()).is_equal(watch)
	assert_bool(MilitaryCampaign.create_field_army(15).has("ok")).is_true()
	MilitaryCampaign.field_armies[0]["location_id"]="the_marches"
	assert_int(MilitaryCampaign.watch_at_home()).is_equal(watch-15)


func test_a_towns_guard_losses_come_off_the_watch()->void:
	_second_town()
	var watch:=_watch(0.10)
	MilitaryCampaign.set_watch_split(1.0)
	var ledger:=Combat.guard_ledger()
	var guard:=int(ledger[TOWN].watch);var rise:=int(ledger[TOWN].rise)
	assert_int(guard).is_greater(0)
	var people:=GameState.population_exact
	MilitaryCampaign._apply_town_watch_result(TOWN,{},[{"defender_casualties":{"killed":4,"wounded":2}}],"defender")
	var dead_guard:=roundi(4.0*float(guard)/float(guard+rise))
	var hurt_guard:=roundi(2.0*float(guard)/float(guard+rise))
	assert_float(GameState.population_exact).is_equal_approx(people-4.0,0.001)
	assert_int(int(MilitaryCampaign.home_army.troops)).is_equal(watch-dead_guard-hurt_guard)
	assert_int(int(MilitaryCampaign.home_army.get("wounded_pool",0))).is_equal(hurt_guard)
	# The hurt still serve (mending); only the dead left the ledger.
	assert_int(MilitaryCampaign._mobilized_count()).is_equal(watch-dead_guard)


func test_offensive_troops_away_do_not_defend()->void:
	_second_town()
	var watch:=_watch(0.10)
	MilitaryCampaign.set_watch_split(0.25)
	var guard:=int(MilitaryCampaign.watch_reading().guard)
	assert_bool(MilitaryCampaign.create_field_army(watch-guard).has("ok")).is_true()
	var band:Dictionary=MilitaryCampaign.field_armies[0]
	band["location_id"]="the_marches";band["status"]="stationed"
	# Only the home guard is left at home; the band defends nothing.
	var ledger:=Combat.guard_ledger()
	var spread:=0
	for id in ledger:spread+=int((ledger[id] as Dictionary).watch)
	assert_int(spread).is_equal(guard)
	var home_force:=MilitaryCampaign._home_defense_force(false)
	assert_int(int(home_force.troops)).is_equal(guard-Combat.posted_away()+int(Combat.home_militia().rise))
	assert_int(int(Combat.home_defenders().trained)).is_equal(0)


# ---------------------------------------------------------------------------
# An older save
# ---------------------------------------------------------------------------

func test_an_older_saves_army_folds_into_the_watch_without_losing_or_making_anyone()->void:
	# An older army: thirty under arms at home, twelve recruits waiting,
	# eight in a drill course and a band of ten in the field, on a watch of
	# eight. Saved before the watch was the army.
	GameState.population_allocation_percentages["Defense"]=2.0
	GameState.synchronize_population_allocations()
	MilitaryCampaign.military_inventory["improvised"]=int(MilitaryCampaign.military_inventory.get("improvised",0))+40
	MilitaryCampaign._rebuild_home_army_with([{"id":1,"unit":"levy","weapon":"improvised","count":40,"authorized_count":40,"equipment":40,"equipment_required":40,"ammunition":0,"ammunition_required":0,"training":0.6,"experience":0.1,"personnel_condition":1.0}])
	MilitaryCampaign.next_formation_id=2
	assert_bool(MilitaryCampaign.create_field_army(10).has("ok")).is_true()
	MilitaryCampaign.field_armies[0]["location_id"]="the_marches"
	MilitaryCampaign.aggregate_recruits=12
	MilitaryCampaign.training_queue.append({"id":1,"mode":"new","unit":"levy","weapon":"improvised","count":8,"initial_count":8,"experience":0.0,"progress_days":20.0,"required_days":60.0,"injury_accumulator":0.0})
	MilitaryCampaign.next_training_order_id=2
	var payload:=MilitaryCampaign.export_state()
	payload.erase("watch_version");payload.erase("watch_folded");payload.erase("watch_home_share");payload.erase("watch_home_auto")
	var serving:=MilitaryCampaign._mobilized_count()
	assert_int(serving).is_equal(30+10+12+8)
	var people:=GameState.population_exact
	assert_bool(MilitaryCampaign.import_state(bytes_to_var(var_to_bytes(payload))).has("ok")).is_true()
	assert_bool(MilitaryCampaign.watch_folded).is_false()
	var kept:=MilitaryCampaign.keep_watch()
	assert_bool(MilitaryCampaign.watch_folded).is_true()
	assert_int(int(kept.folded)).is_equal(20)
	# Recruits and trainees became the watch at home; the band is still out.
	assert_int(int(MilitaryCampaign.aggregate_recruits)).is_equal(0)
	assert_bool(MilitaryCampaign.training_queue.is_empty()).is_true()
	assert_int(int(MilitaryCampaign.home_army.troops)).is_equal(30+12+8)
	assert_int(int(MilitaryCampaign.field_armies[0].troops)).is_equal(10)
	# Nobody lost, nobody made: the watch share rose to hold them all.
	assert_int(MilitaryCampaign._mobilized_count()).is_equal(serving)
	assert_int(MilitaryCampaign.watch_manpower()).is_equal(serving)
	assert_float(GameState.population_exact).is_equal(people)
	# The next days keep it so.
	for i in 3:MilitaryCampaign.keep_watch()
	assert_int(MilitaryCampaign._mobilized_count()).is_equal(serving)


func test_a_new_save_keeps_the_split()->void:
	_watch(0.05)
	MilitaryCampaign.set_watch_split(0.3)
	var payload:=MilitaryCampaign.export_state()
	MilitaryCampaign.set_watch_split(0.9)
	assert_bool(MilitaryCampaign.import_state(bytes_to_var(var_to_bytes(payload))).has("ok")).is_true()
	assert_float(MilitaryCampaign.watch_split()).is_equal_approx(0.3,0.0001)
	assert_bool(MilitaryCampaign.watch_folded).is_true()


# ---------------------------------------------------------------------------
# Every people the same
# ---------------------------------------------------------------------------

func test_a_hungry_computer_people_at_peace_sends_its_watch_home_and_the_path_takes_it_back()->void:
	WorldSimulation.context_provider=func(_origin:Vector2)->Dictionary:return {"environment_profile":PlanetEnvironment.profile_at(Vector2.ZERO),"surface_water_distance_km":.1,"surface_water_recognized":true}
	WorldSimulation.create_actor("alpha",777,Vector2.ZERO)
	WorldSimulation.actors.alpha.systems.CivilizationSystem.scout_land_authority=func(_point:Vector2)->bool:return true
	WorldSimulation.actors.alpha.controller="manual"
	assert_bool(WorldSimulation.submit("alpha",{"kind":"found"}).get("ok",false)).is_true()
	var out:Dictionary=WorldSimulation.scoped("alpha",func()->Dictionary:
		var mc:Variant=WorldSimulation.military
		var pop:=int(WorldSimulation.state.population_total)
		mc.set_watch_share(0.10)
		var before:=int(mc._mobilized_count())
		# A famine at peace: the watch above its peacetime share goes home.
		var keep:=roundi(float(pop)*0.03)
		Controller.hunger_stand_down("alpha",{"hungry":true,"food_shortage":true,"at_war":false},keep)
		var hungry:=int(mc._mobilized_count())
		var watch_hungry:=int(mc.watch_manpower())
		# The famine over: the ruler's temper keeps more than the path, so the
		# watch is held at the temper's share again.
		mc.watch_path_share=0.0
		Controller.interim_watch(mc,roundi(float(pop)*0.06),{})
		var held:=int(mc.watch_manpower())
		# The path keeps as many as the temper: the hold goes.
		mc.watch_path_share=0.5
		Controller.interim_watch(mc,roundi(float(pop)*0.06),{})
		return {"pop":pop,"before":before,"hungry":hungry,"watch_hungry":watch_hungry,"keep":keep,"held":held,"hold":float(mc.watch_work_share)})
	assert_int(int(out.before)).is_greater(int(out.keep))
	assert_int(int(out.hungry)).is_less_equal(int(out.keep))
	assert_int(int(out.watch_hungry)).is_less_equal(int(out.keep)+1)
	assert_int(int(out.held)).is_equal(roundi(float(out.pop)*0.06))
	assert_float(float(out.hold)).is_equal(-1.0)


func test_a_computer_people_keeps_its_watch_by_the_same_rules()->void:
	WorldSimulation.context_provider=func(_origin:Vector2)->Dictionary:return {"environment_profile":PlanetEnvironment.profile_at(Vector2.ZERO),"surface_water_distance_km":.1,"surface_water_recognized":true}
	WorldSimulation.create_actor("alpha",777,Vector2.ZERO)
	WorldSimulation.actors.alpha.systems.CivilizationSystem.scout_land_authority=func(_point:Vector2)->bool:return true
	WorldSimulation.actors.alpha.controller="manual"
	assert_bool(WorldSimulation.submit("alpha",{"kind":"found"}).get("ok",false)).is_true()
	var out:Dictionary=WorldSimulation.scoped("alpha",func()->Dictionary:
		var mc:Variant=WorldSimulation.military
		mc.set_watch_share(0.05)
		mc.keep_watch()
		var r:Dictionary=mc.watch_reading()
		var split:Dictionary=mc.set_watch_split(0.3)
		return {"watch":int(mc.watch_manpower()),"serving":int(mc._mobilized_count()),"home":int(mc.home_army.get("troops",0)),"auto":float(mc.watch_home_auto),"recruits":int(mc.aggregate_recruits),"split":float(mc.watch_split()),"ok":split.has("ok"),"parts":_parts(r),"total":int(r.serving)})
	assert_int(int(out.watch)).is_greater(0)
	assert_int(int(out.serving)).is_equal(int(out.watch))
	assert_int(int(out.home)).is_equal(int(out.watch))
	assert_int(int(out.recruits)).is_equal(0)
	assert_int(int(out.parts)).is_equal(int(out.total))
	# Its split by temper until its ruler sets one.
	assert_float(float(out.auto)).is_between(0.10,0.60)
	assert_bool(bool(out.ok)).is_true()
	assert_float(float(out.split)).is_equal_approx(0.3,0.0001)
	# The god's people are untouched by it.
	assert_int(int(MilitaryCampaign.home_army.get("troops",0))).is_equal(0)

extends GdUnitTestSuite
## KEEPING ARMIES IN THE FIELD (scripts/field_sustainment.gd): hunger costs a
## band men by stated rates and every one of them is accounted for (sick,
## gone home, dead); the sick come back when fed; fodder, fuel and rounds are
## a second share that weakens only the kits that need them; losses are
## replaced by drafts trained at the Reinforce pace who walk out and join,
## counted as field personnel the whole way; drafts survive a save. Drafts
## come from the army's size the ruler set (army_levy_law.gd): within it new
## men are called up; at it, only those already called up may go.

const Sustainment:=preload("res://scripts/field_sustainment.gd")
const Combat:=preload("res://scripts/combat_simulator.gd")

func before_test()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(4242);MilitaryCampaign.reset_for_new_world()
	GameState.settlement_site_committed=true;GameState.settlement_founded_at=Vector3.ZERO
	MilitaryCampaign.home_army=MilitaryCampaign._empty_home_army()

func after_test()->void:
	WorldSimulation.clear()

func _formation(id:int,unit:String,weapon:String,count:int,authorized:int=-1)->Dictionary:
	var sim=MilitaryCampaign.simulator
	var full:=count if authorized<0 else authorized
	var sets:int=sim.equipment_required_for_weapon(weapon,full)
	return {"id":id,"unit":unit,"weapon":weapon,"count":count,"authorized_count":full,"equipment":sets,"equipment_required":sets,"ammunition":0,"ammunition_required":0,"training":0.7,"experience":0.2,"personnel_condition":1.0}

func _band(id:int,formations:Array,x:float=40.0)->Dictionary:
	var force:Dictionary=MilitaryCampaign.simulator.create_formation_force("Band %d" % id,formations,1.0,1.0)
	force.merge({"army_id":id,"status":"stationed","location_id":"field","position":{"x":x,"z":0.0},"supply_level":1.0},true)
	return force

func test_hunger_costs_men_at_the_stated_rate_and_every_man_is_accounted_for()->void:
	var force:=_band(1,[_formation(1,"spearman","spear",600),_formation(2,"archer","bow",300)])
	force["provision_ratio"]=0.0
	force["hungry_days"]=5.0
	var before:=int(force.troops)
	var lost:={"sick":0,"deserted":0,"dead":0}
	for day in 30:
		var today:Dictionary=MilitaryCampaign.sustainment.hunger_day(force,1.0)
		for key in lost: lost[key]=int(lost[key])+int(today[key])
	var total:=int(lost.sick)+int(lost.deserted)+int(lost.dead)
	# No food at all for a month: about a quarter of the band (1.1% a day).
	assert_float(float(total)/before).is_between(0.24,0.30)
	assert_int(int(force.troops)+total).is_equal(before)
	assert_int(int(force.wounded_pool)).is_equal(int(lost.sick))
	assert_float(float(lost.sick)/total).is_between(0.40,0.50)
	assert_float(float(lost.dead)/total).is_between(0.15,0.25)
	assert_dict(force.hunger_losses as Dictionary).is_equal(lost)

func test_a_fed_band_or_a_short_first_day_costs_nothing()->void:
	var force:=_band(1,[_formation(1,"spearman","spear",300)])
	force["provision_ratio"]=0.9;force["hungry_days"]=6.0
	assert_int(int(MilitaryCampaign.sustainment.hunger_day(force,1.0).dead)).is_equal(0)
	force["provision_ratio"]=0.2;force["hungry_days"]=1.0
	for day in 10: MilitaryCampaign.sustainment.hunger_day(force,1.0)
	assert_int(int(force.troops)).is_equal(300)

func test_the_sick_rejoin_their_places_when_fed()->void:
	var force:=_band(1,[_formation(1,"spearman","spear",200,300)])
	# Battle wounded heal by the medical rules; only the hunger-sick come back here.
	force["wounded_pool"]=100
	force["provision_ratio"]=1.0
	for day in 20: MilitaryCampaign.sustainment.recovery_day(force,1.0)
	assert_int(int(force.wounded_pool)).is_equal(100)
	force["hunger_sick"]=100
	for day in 60: MilitaryCampaign.sustainment.recovery_day(force,1.0)
	assert_int(int(force.troops)+int(force.wounded_pool)).is_equal(300)
	assert_int(int(force.wounded_pool)).is_less(15)
	assert_int(int(force.formations[0].count)).is_less_equal(300)
	force["provision_ratio"]=0.3
	var sick:=int(force.wounded_pool)
	MilitaryCampaign.sustainment.recovery_day(force,1.0)
	assert_int(int(force.wounded_pool)).is_equal(sick)

func test_stores_are_a_second_share_that_horses_can_graze_and_tanks_cannot()->void:
	var tanks:=_band(1,[_formation(1,"armored_formation","armored_vehicle",50)])
	var horse:=_band(2,[_formation(1,"cavalry","lance",100)])
	var spears:=_band(3,[_formation(1,"spearman","spear",100)])
	assert_float(Sustainment.stores_share(tanks,0.5,0.8)).is_equal_approx(0.5,0.0001)
	assert_float(Sustainment.stores_share(horse,0.5,0.8)).is_equal_approx(0.9,0.0001)
	assert_float(Sustainment.stores_share(spears,0.0,0.0)).is_equal(1.0)
	# Short stores weaken tanks and horses, not spearmen.
	assert_float(Combat.stores_factor("armored_vehicle",0.2)).is_less(0.5)
	assert_float(Combat.stores_factor("spear",0.0)).is_equal(1.0)
	var enemy:=_band(9,[_formation(1,"rifle_infantry","service_rifle",200)])
	var full:float=MilitaryCampaign.simulator.evaluate_force(tanks,enemy,1.0)[0].attack
	tanks["stores_share"]=0.2
	var short:float=MilitaryCampaign.simulator.evaluate_force(tanks,enemy,1.0)[0].attack
	assert_float(short).is_less(full*0.5)

func _draftable_world()->void:
	GameState.population_cohorts["working_age"]=500.0
	GameState.population_allocations["Defense"]=500
	GameState.population_allocations["Logistics"]=40

func test_losses_are_replaced_by_drafts_who_walk_out_and_join()->void:
	_draftable_world()
	var band:=_band(7,[_formation(11,"levy","improvised",20,30)],30.0)
	MilitaryCampaign.field_armies.assign([band])
	var mobilized_before:int=MilitaryCampaign._mobilized_count()
	var started:Array=MilitaryCampaign.sustainment.draft_day()
	assert_int(started.size()).is_equal(1)
	assert_int(int(started[0].count)).is_equal(10)
	var order:Dictionary=MilitaryCampaign.training_queue[-1]
	assert_str(String(order.mode)).is_equal("field_draft")
	assert_int(int(order.field_army_id)).is_equal(7)
	# The Reinforce pace: 0.58 of a full course.
	assert_float(float(order.required_days)).is_equal_approx(maxf(3.0,preload("res://scripts/military_unit_catalog.gd").training_days("levy")*0.58),0.001)
	# A second day does not draft the same places twice.
	assert_int(MilitaryCampaign.sustainment.draft_day().size()).is_equal(0)
	var mobilized_training:int=MilitaryCampaign._mobilized_count()
	assert_int(mobilized_training).is_equal(mobilized_before+10)
	# Training done: they leave for the band and are counted on the road.
	order.progress_days=order.required_days
	MilitaryCampaign.training_queue.erase(order)
	var draft:Dictionary=MilitaryCampaign.sustainment.dispatch(order)
	assert_int(MilitaryCampaign._mobilized_count()).is_equal(mobilized_training)
	assert_int(int(draft.arrive_day)).is_greater(int(GameState.elapsed_days))
	# On the road the band cannot take them yet.
	assert_int(MilitaryCampaign.sustainment.arrivals_day().size()).is_equal(0)
	GameState.elapsed_days=int(draft.arrive_day)
	var joined:Array=MilitaryCampaign.sustainment.arrivals_day()
	assert_int(joined.size()).is_equal(1)
	assert_int(int(MilitaryCampaign.field_armies[0].formations[0].count)).is_equal(30)
	assert_int(int(MilitaryCampaign.field_armies[0].troops)).is_equal(30)
	assert_int(MilitaryCampaign.field_drafts.size()).is_equal(0)
	assert_int(MilitaryCampaign._mobilized_count()).is_equal(mobilized_training)

func test_a_draft_whose_band_is_gone_comes_home()->void:
	MilitaryCampaign.field_drafts.assign([{"army_id":99,"formation_id":1,"unit":"levy","weapon":"improvised","count":8,"equipment":8,"training":0.4,"left_day":0,"arrive_day":0}])
	var stock:=int(MilitaryCampaign.military_inventory.get("improvised",0))
	var mobilized:int=MilitaryCampaign._mobilized_count()
	MilitaryCampaign.sustainment.arrivals_day()
	# Trained men join the army at home as a formation of their own, their
	# gear with them; nobody is lost or made.
	assert_int(int(MilitaryCampaign.home_army.troops)).is_equal(8)
	var home:Dictionary=(MilitaryCampaign.home_army.formations as Array)[-1]
	assert_float(float(home.training)).is_greater_equal(0.4)
	assert_int(int(home.equipment)+int(MilitaryCampaign.military_inventory.improvised)).is_equal(stock+8)
	assert_int(MilitaryCampaign._mobilized_count()).is_equal(mobilized)
	assert_int(MilitaryCampaign.field_drafts.size()).is_equal(0)

func test_last_priority_bands_are_not_redrafted()->void:
	_draftable_world()
	var band:=_band(3,[_formation(5,"levy","improvised",10,20)])
	band["priority"]="last"
	MilitaryCampaign.field_armies.assign([band])
	assert_int(MilitaryCampaign.sustainment.draft_day().size()).is_equal(0)

func test_drafts_on_the_road_survive_a_save()->void:
	MilitaryCampaign.field_drafts.assign([{"army_id":4,"formation_id":2,"unit":"levy","weapon":"improvised","count":5,"equipment":5,"training":0.4,"left_day":1,"arrive_day":9}])
	var saved:Dictionary=MilitaryCampaign.export_state()
	MilitaryCampaign.field_drafts.clear()
	assert_dict(MilitaryCampaign.import_state(saved)).not_contains_keys(["error"])
	assert_int(MilitaryCampaign.field_drafts.size()).is_equal(1)
	assert_int(int(MilitaryCampaign.field_drafts[0].arrive_day)).is_equal(9)
	assert_bool(Sustainment.valid_drafts([{"army_id":-1}])).is_false()

func test_drafts_come_from_the_army_size_the_ruler_set()->void:
	_draftable_world()
	GameState.population_allocations["Defense"]=0
	GameState.ensure_population_total(1000)
	var band:=_band(7,[_formation(11,"levy","improvised",20,30)],30.0)
	MilitaryCampaign.field_armies.assign([band])
	# "A few of the young": 10 of 1,000. The band's 20 already stand above it.
	MilitaryCampaign.army_levy_level="few"
	assert_int(MilitaryCampaign.sustainment.draft_day().size()).is_equal(0)
	assert_str(String(MilitaryCampaign.field_armies[0].draft_block)).is_equal("at_level")
	# Men the player already called up may go.
	MilitaryCampaign.aggregate_recruits=10
	assert_int(MilitaryCampaign.sustainment.draft_day().size()).is_equal(1)

func test_no_drafts_for_a_band_cut_off_or_starving()->void:
	_draftable_world()
	GameState.population_allocations["Logistics"]=0
	var band:=_band(7,[_formation(11,"levy","improvised",20,30)],30.0)
	MilitaryCampaign.field_armies.assign([band])
	assert_int(MilitaryCampaign.sustainment.draft_day().size()).is_equal(0)
	assert_str(String(MilitaryCampaign.field_armies[0].draft_block)).is_equal("cut_off")
	GameState.population_allocations["Logistics"]=40
	MilitaryCampaign.field_armies[0]["hungry_days"]=5.0
	assert_int(MilitaryCampaign.sustainment.draft_day().size()).is_equal(0)
	assert_str(String(MilitaryCampaign.field_armies[0].draft_block)).is_equal("hungry")

func test_a_draft_brings_gear_only_for_the_real_gap_and_none_is_lost()->void:
	_draftable_world()
	# 20 of 30 men but all 30 sets: the band needs men, not spears.
	var formation:=_formation(11,"spearman","spear",20,30)
	var band:=_band(7,[formation],30.0)
	MilitaryCampaign.field_armies.assign([band])
	MilitaryCampaign.military_inventory["spear"]=50
	MilitaryCampaign.sustainment.draft_day()
	var order:Dictionary=MilitaryCampaign.training_queue[-1]
	MilitaryCampaign.training_queue.erase(order)
	var draft:Dictionary=MilitaryCampaign.sustainment.dispatch(order)
	assert_int(int(draft.equipment)).is_equal(0)
	var stock:=int(MilitaryCampaign.military_inventory.spear)
	GameState.elapsed_days=int(draft.arrive_day)
	MilitaryCampaign.sustainment.arrivals_day()
	var joined:Dictionary=MilitaryCampaign.field_armies[0].formations[0]
	assert_int(int(joined.count)).is_equal(30)
	assert_int(int(joined.equipment)).is_equal(30)
	assert_int(int(joined.authorized_count)).is_equal(30)
	assert_int(int(MilitaryCampaign.military_inventory.spear)).is_equal(stock)

func test_a_save_taken_while_drafts_train_loads()->void:
	_draftable_world()
	var band:=_band(7,[_formation(11,"levy","improvised",20,30)],30.0)
	MilitaryCampaign.field_armies.assign([band])
	MilitaryCampaign.home_army=MilitaryCampaign._empty_home_army()
	assert_int(MilitaryCampaign.sustainment.draft_day().size()).is_equal(1)
	var saved:Dictionary=MilitaryCampaign.export_state()
	var result:Dictionary=MilitaryCampaign.import_state(saved)
	assert_dict(result).not_contains_keys(["error"])
	var drafting:=MilitaryCampaign.training_queue.filter(func(o:Dictionary)->bool:return String(o.get("mode",""))=="field_draft")
	assert_int(drafting.size()).is_equal(1)

func test_the_personnel_ledger_adds_up_with_drafts_on_the_road()->void:
	MilitaryCampaign.field_drafts.assign([{"army_id":4,"formation_id":2,"unit":"levy","weapon":"improvised","count":6,"equipment":0,"training":0.4,"left_day":1,"arrive_day":9}])
	var ledger:Dictionary=MilitaryCampaign.personnel_ledger()
	var parts:=0
	for key in ["naval_air","home","field","occupation","recruits","training","recovering","missing","replacements"]: parts+=int(ledger[key])
	assert_int(parts).is_equal(int(ledger.total))
	assert_int(int(ledger.replacements)).is_equal(6)

func test_a_bad_saved_draft_is_dropped_alone()->void:
	var kept:=Sustainment.clean_drafts([{"army_id":4,"formation_id":2,"unit":"levy","weapon":"improvised","count":5,"equipment":5,"arrive_day":9},{"army_id":-1},{"army_id":3,"formation_id":1,"unit":"","weapon":"spear","count":2,"equipment":0,"arrive_day":1}])
	assert_int(kept.size()).is_equal(1)

func test_a_band_at_rest_regains_heart_by_its_supply_and_a_hungry_one_loses_it()->void:
	var band:=_band(1,[_formation(1,"spearman","spear",200)])
	band["morale"]=0.4;band["supply_level"]=1.0;band["provision_ratio"]=1.0
	for day in 25: MilitaryCampaign.sustainment.rest_day(band,1.0)
	assert_float(float(band.morale)).is_equal_approx(1.0,0.001)
	var half:=_band(2,[_formation(1,"spearman","spear",200)])
	half["morale"]=0.4;half["supply_level"]=0.5;half["provision_ratio"]=0.8
	for day in 60: MilitaryCampaign.sustainment.rest_day(half,1.0)
	assert_float(float(half.morale)).is_equal_approx(0.55+0.45*0.5,0.001)
	var hungry:=_band(3,[_formation(1,"spearman","spear",200)])
	hungry["morale"]=0.9;hungry["hungry_days"]=6.0;hungry["provision_ratio"]=0.2
	for day in 10: MilitaryCampaign.sustainment.rest_day(hungry,1.0)
	assert_float(float(hungry.morale)).is_less(0.9)
	assert_float(float(hungry.morale)).is_greater_equal(Sustainment.MORALE_HUNGER_FLOOR)

func test_battle_wounded_heal_in_a_supplied_camp_and_medics_double_it()->void:
	var plain:=_band(1,[_formation(1,"spearman","spear",100,200)])
	plain["wounded_pool"]=100;plain["supply_level"]=1.0;plain["provision_ratio"]=1.0
	var cared:=_band(2,[_formation(1,"spearman","spear",100,200),_formation(2,"medical_detachment","medical_kit",10)])
	cared["wounded_pool"]=100;cared["supply_level"]=1.0;cared["provision_ratio"]=1.0
	for day in 20:
		MilitaryCampaign.sustainment.rest_day(plain,1.0)
		MilitaryCampaign.sustainment.rest_day(cared,1.0)
	var healed_plain:=100-int(plain.wounded_pool)
	var healed_cared:=100-int(cared.wounded_pool)
	assert_int(healed_plain).is_between(20,35)
	assert_int(healed_cared).is_greater(healed_plain)
	assert_int(int(plain.troops)+int(plain.wounded_pool)).is_equal(200)

func test_a_band_trend_is_sampled_kept_and_told_only_as_far_as_reports_go()->void:
	var band:=_band(3,[_formation(1,"spearman","spear",200)])
	band["provision_ratio"]=0.8;band["morale"]=0.7
	MilitaryCampaign.field_armies.assign([band])
	for day in 200:
		GameState.elapsed_days=1000+day
		MilitaryCampaign.field_armies[0]["troops"]=200-day/2
		MilitaryCampaign.sustainment.trend_day()
	var trend:Array=MilitaryCampaign.field_armies[0].trend
	# Every five days, the last four months kept.
	assert_int(trend.size()).is_equal(Sustainment.TREND_KEEP)
	assert_int(int(trend[1][0])-int(trend[0][0])).is_equal(Sustainment.TREND_EVERY)
	assert_int(int(trend[-1][0])).is_equal(1195)
	assert_array(trend[-1]).is_equal([1195,103,80,70])
	# Home knows only up to the last runner's day.
	var known:=Sustainment.trend_known(MilitaryCampaign.field_armies[0],1150)
	assert_int(int(known[-1][0])).is_equal(1150)
	var BandTrend:=preload("res://scripts/hud/band_trend.gd")
	assert_str(BandTrend.words(known)).contains("now 125")
	assert_str(BandTrend.words(known)).contains("Supply 80%, now 80%")

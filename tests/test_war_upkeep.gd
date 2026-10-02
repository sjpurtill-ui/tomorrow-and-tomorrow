extends GdUnitTestSuite
## THE WAR LEADER KEEPS ARMIES FULL, FED AND RESTED, AND BATTLES END SENSIBLY
## (scripts/band_upkeep.gd, field_sustainment.gd, supply_state.gd,
## army_lines.gd, town_hold.gd, civilization_combat.gd, military_campaign.gd).
##
## The player's own save (year 187, 535 people): Ennis's band, 4 of 13, will
## gone, a third fed and hungry, was still out after losing at Eldwick; Hewin's
## band sat at 4 of 20. Now a band below the strength line or the one break
## line comes back to rest, the drafts and the reserve at home refill it from
## the size the ruler set, weak bands in one place join, hunger wears will
## down without pinning it, the country round a long camp is eaten out, a
## garrison takes only what its town needs, every town has guards, and home
## is never given away by pulling back.

const Lines:=preload("res://scripts/army_lines.gd")
const Hold:=preload("res://scripts/town_hold.gd")
const Sustainment:=preload("res://scripts/field_sustainment.gd")
const Supply:=preload("res://scripts/supply_state.gd")
const Rations:=preload("res://scripts/field_rations.gd")
const Combat:=preload("res://scripts/civilization_combat.gd")
const Levy:=preload("res://scripts/army_levy_law.gd")
const Route:=preload("res://scripts/army_land_route.gd")

var _processing:Dictionary={}


func _land(_p:Vector2)->bool:
	return true


func before_test()->void:
	if _processing.is_empty():
		for node:Node in [GameState,CivilizationSystem,MilitaryCampaign,ProgressionSystem]: _processing[node]=node.is_processing()
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(5357);GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world();FoodSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	GameState.ensure_population_total(535);GameState.housing_capacity=800
	GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	GameState.settlement_name="Seanstone"
	GameState.resource_stockpiles["Food"]=1000000.0
	GameState.elapsed_days=187*365
	GameState.population_cohorts["working_age"]=300.0
	GameState.population_allocations["Defense"]=0
	GameState.population_allocations["Logistics"]=40
	MilitaryCampaign.home_army=MilitaryCampaign._empty_home_army()
	MilitaryCampaign.last_processed_day=int(GameState.elapsed_days)
	Route.clear_cache()
	CivilizationSystem.set_scout_geography_authority(Callable(self,"_land"))


func after_test()->void:
	CivilizationSystem.set_scout_geography_authority(Callable())
	Route.clear_cache()
	GameState.elapsed_days=0
	MilitaryCampaign.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	DiscoverySystem.reset_for_new_world()
	GameState.reset_for_new_world(74017)
	ProgressionSystem.reset_for_new_world()
	HistoricalFigures.reset_for_new_world()
	WorldSimulation.clear()
	for node:Node in _processing: node.set_process(bool(_processing[node]))


func _home()->Vector2:
	return CivilizationSystem.player_world_origin


func _formation(id:int,unit:String,weapon:String,count:int,authorized:int=-1)->Dictionary:
	var sim=MilitaryCampaign.simulator
	var full:=count if authorized<0 else authorized
	var sets:int=sim.equipment_required_for_weapon(weapon,full)
	return {"id":id,"unit":unit,"weapon":weapon,"count":count,"authorized_count":full,"equipment":sets,"equipment_required":sets,"ammunition":0,"ammunition_required":0,"training":0.6,"experience":0.1,"personnel_condition":1.0}


## A band of ours in the field, `km` east of home (0: at home).
func _band(id:int,formations:Array,km:float=30.0,commander:Dictionary={})->Dictionary:
	var force:Dictionary=MilitaryCampaign.simulator.create_formation_force("Band %d" % id,formations,0.8,0.8)
	var at:=_home()+Vector2(km,0.0)
	force.merge({"army_id":id,"status":"stationed","location_id":"player_home" if km==0.0 else "field","location_name":"Seanstone" if km==0.0 else "the field",
		"position":{"x":at.x,"z":at.y},"supply_level":1.0,"provision_ratio":1.0,"runner_count":2,"last_runner_departure_day":int(GameState.elapsed_days)},true)
	force["commander"]=commander if not commander.is_empty() else MilitaryCampaign.simulator.create_commander("FIELD STAFF",0.5,0.5,0.5,0.5)
	MilitaryCampaign.next_field_army_id=maxi(MilitaryCampaign.next_field_army_id,id+1)
	for f in formations: MilitaryCampaign.next_formation_id=maxi(MilitaryCampaign.next_formation_id,int((f as Dictionary).id)+1)
	return force


func _general(name:String,figure:String,command:float)->Dictionary:
	var commander:Dictionary=MilitaryCampaign.simulator.create_commander(name,command,0.5,0.5,0.5)
	commander["figure_id"]=figure
	return commander


func _people_under_arms()->int:
	return int(MilitaryCampaign.personnel_ledger().total)


# --- 1. A band below strength refills from the size the ruler set ------------

func test_a_band_below_strength_refills_from_the_army_size_the_ruler_set()->void:
	# Hewin's band: 4 of 20, out in the field. The ruler keeps "a levy from
	# every hearth" (5%): 27 of 535.
	MilitaryCampaign.army_levy_level="many"
	MilitaryCampaign.field_armies.assign([_band(7,[_formation(11,"levy","improvised",4,20)])])
	var read:Dictionary=Levy.reading(MilitaryCampaign)
	assert_int(int(read.target)).is_equal(27)
	assert_int(MilitaryCampaign.sustainment.levy_room()).is_equal(27-4)
	var before:=_people_under_arms()
	var started:Array=MilitaryCampaign.sustainment.draft_day()
	assert_int(started.size()).is_equal(1)
	# All sixteen empty places are drafted, from the room the size leaves.
	assert_int(int(started[0].count)).is_equal(16)
	var order:Dictionary=MilitaryCampaign.training_queue[-1]
	assert_str(String(order.mode)).is_equal("field_draft")
	assert_int(int(order.field_army_id)).is_equal(7)
	assert_int(_people_under_arms()).is_equal(before+16)
	# Their drill done, they walk out and join: 20 of 20.
	MilitaryCampaign.training_queue.erase(order)
	var draft:Dictionary=MilitaryCampaign.sustainment.dispatch(order)
	GameState.elapsed_days=int(draft.arrive_day)
	MilitaryCampaign.sustainment.arrivals_day()
	assert_int(int(MilitaryCampaign.field_armies[0].troops)).is_equal(20)
	assert_int(_people_under_arms()).is_equal(before+16)


func test_drafts_stop_at_the_size_the_ruler_set_and_say_so()->void:
	# A few of the young (1%): 5 of 535. The band of 4 of 20 already holds
	# almost all of it: one more may come, no more.
	MilitaryCampaign.army_levy_level="few"
	MilitaryCampaign.field_armies.assign([_band(7,[_formation(11,"levy","improvised",4,20)])])
	assert_int(MilitaryCampaign.sustainment.levy_room()).is_equal(1)
	assert_int(MilitaryCampaign.sustainment.draft_day().size()).is_equal(0)
	# Fewer than the smallest draft (three men) could come: the places stay
	# open, and the block says why in words the ruler can act on.
	assert_str(String(MilitaryCampaign.field_armies[0].get("draft_block",""))).is_equal("at_level")
	assert_str(Sustainment.block_words("at_level")).contains("Raise how many serve")
	# Never "+0 coming": nothing is coming, and the screens get the reason.
	var coming:Dictionary=MilitaryCampaign.sustainment.drafts_for(7)
	assert_int(int(coming.on_road)+int(coming.in_training)).is_equal(0)
	assert_str(String(coming.block)).is_not_equal("no_people")
	assert_str(String(coming.block_words)).contains("the size you set")
	# The ruler raises the share: the drafts come.
	MilitaryCampaign.army_levy_level="war"
	assert_int(MilitaryCampaign.sustainment.draft_day().size()).is_equal(1)
	assert_str(String(MilitaryCampaign.field_armies[0].get("draft_block",""))).is_equal("")


func test_without_a_size_set_the_bands_are_kept_at_the_strength_they_were_formed_with()->void:
	MilitaryCampaign.army_levy_level=""
	MilitaryCampaign.field_armies.assign([_band(7,[_formation(11,"levy","improvised",4,20)])])
	var started:Array=MilitaryCampaign.sustainment.draft_day()
	assert_int(started.size()).is_equal(1)
	assert_int(int(started[0].count)).is_equal(16)


func test_a_band_at_home_takes_trained_men_from_the_reserve_at_once()->void:
	MilitaryCampaign.army_levy_level="many"
	# Twelve trained spearmen in the levy at home (no watch kept: Defense 0).
	MilitaryCampaign._rebuild_home_army_with([_formation(40,"levy","improvised",12)])
	assert_int(MilitaryCampaign.sustainment.home_reserve()).is_equal(12)
	MilitaryCampaign.field_armies.assign([_band(7,[_formation(11,"levy","improvised",4,13)],0.0)])
	assert_bool(MilitaryCampaign.at_home_point(MilitaryCampaign.field_armies[0])).is_true()
	var before:=_people_under_arms()
	var started:Array=MilitaryCampaign.sustainment.draft_day()
	assert_int(started.size()).is_equal(1)
	assert_str(String(started[0].get("from",""))).is_equal("reserve")
	# Nine places, nine men, no drill: the band is whole the same day.
	assert_int(int(MilitaryCampaign.field_armies[0].troops)).is_equal(13)
	assert_int(int(MilitaryCampaign.home_army.troops)).is_equal(3)
	assert_int(_people_under_arms()).is_equal(before)


# --- 2. A garrison is refilled --------------------------------------------------

func test_a_garrison_is_refilled()->void:
	MilitaryCampaign.army_levy_level="war"
	var garrison:Dictionary=MilitaryCampaign.simulator.create_formation_force("OCCUPATION • Tsaren",[_formation(21,"levy","improvised",10,20)],0.8,0.8)
	var town:=_home()+Vector2(20.0,0.0)
	garrison.merge({"civ_id":"rival","region_id":"tsaren","region_name":"Tsaren","required":4.0,"supply_level":1.0,"provision_ratio":1.0,"position":{"x":town.x,"z":town.y},"commander":MilitaryCampaign._garrison_captain()},true)
	MilitaryCampaign.occupation_forces.assign([garrison])
	var started:Array=MilitaryCampaign.sustainment.draft_day()
	assert_int(started.size()).is_equal(1)
	assert_int(int(started[0].count)).is_equal(10)
	var order:Dictionary=MilitaryCampaign.training_queue[-1]
	assert_str(String(order.get("garrison",""))).is_equal("rival/tsaren")
	# The save keeps a garrison's draft as valid.
	assert_array(MilitaryCampaign.validate_state().filter(func(e:String)->bool:return "replacement draft" in e)).is_empty()
	MilitaryCampaign.training_queue.erase(order)
	var draft:Dictionary=MilitaryCampaign.sustainment.dispatch(order)
	assert_str(String(draft.get("garrison",""))).is_equal("rival/tsaren")
	GameState.elapsed_days=int(draft.arrive_day)
	assert_int(MilitaryCampaign.sustainment.arrivals_day().size()).is_equal(1)
	assert_int(int(MilitaryCampaign.occupation_forces[0].troops)).is_equal(20)
	var coming:Dictionary=MilitaryCampaign.sustainment.drafts_for_force(MilitaryCampaign.occupation_forces[0])
	assert_int(int(coming.on_road)+int(coming.in_training)).is_equal(0)


# --- 3. Hunger wears will down; it never pins it at nothing ---------------------

func test_hunger_lowers_will_but_does_not_pin_it_at_nothing()->void:
	var fed_down:=_band(1,[_formation(1,"spearman","spear",200)])
	fed_down["morale"]=0.9;fed_down["hungry_days"]=6.0;fed_down["provision_ratio"]=0.2
	for day in 10: MilitaryCampaign.sustainment.rest_day(fed_down,1.0)
	assert_float(float(fed_down.morale)).is_less(0.9)
	# Starved long enough, will settles on the floor: below the break line,
	# so the band breaks and the war leader brings it back to be fed.
	for day in 200: MilitaryCampaign.sustainment.rest_day(fed_down,1.0)
	assert_float(float(fed_down.morale)).is_equal_approx(Sustainment.MORALE_HUNGER_FLOOR,0.0001)
	assert_float(Sustainment.MORALE_HUNGER_FLOOR).is_greater(0.0)
	assert_bool(Lines.broken(float(fed_down.morale))).is_true()
	# Ennis's band came out of a lost fight with no will left: hungry, it no
	# longer stays at nothing but regains a little toward that floor.
	var beaten:=_band(2,[_formation(1,"levy","improvised",4,13)])
	beaten["morale"]=0.0;beaten["hungry_days"]=8.0;beaten["provision_ratio"]=0.37
	for day in 5: MilitaryCampaign.sustainment.rest_day(beaten,1.0)
	assert_float(float(beaten.morale)).is_greater(0.0)
	assert_float(float(beaten.morale)).is_less_equal(Sustainment.MORALE_HUNGER_FLOOR)


# --- 4. One break line, read by every check -------------------------------------

func test_one_break_line_is_used_everywhere()->void:
	assert_float(Lines.BREAK).is_equal(0.25)
	assert_str(Lines.BREAK_WORDS).is_equal("breaks when will falls below a quarter")
	assert_float(MilitaryCampaign.MORALE_BREAK).is_equal(Lines.BREAK)
	assert_float(CombatSimulator.MORALE_BREAK_AT).is_equal(Lines.BREAK)
	assert_float(preload("res://scripts/hud/army_marks.gd").BROKEN_MORALE).is_equal(Lines.BREAK)
	assert_float(Sustainment.MORALE_HUNGER_FLOOR).is_less(Lines.BREAK)
	# The fight: a side just under the line is broken, just over it is not.
	var sim:CombatSimulator=MilitaryCampaign.simulator
	assert_str(sim._outcome(100,100,0.26,0.24)).is_equal("attacker_victory")
	assert_str(sim._outcome(100,100,0.24,0.26)).is_equal("defender_victory")
	assert_str(sim._outcome(100,100,0.26,0.26)).is_equal("inconclusive")
	var force:Dictionary=sim.create_formation_force("Test",[_formation(1,"levy","spear",10)],0.24,0.5)
	assert_bool(bool(sim._force_result(force,10,10,0.24).routed)).is_true()
	assert_bool(bool(sim._force_result(force,10,10,0.26).routed)).is_false()
	# Our side pulls out of a fight below the same line, a band too when it has
	# lost half the men it took in; home only when it breaks.
	var ours:={"morale":0.24,"troops":20}
	assert_str(MilitaryCampaign._our_battle_order({"home_side":"attacker","home_force_kind":"field_army","attacker":ours,"attacker_initial":20})).is_equal("retreat")
	ours.morale=0.26
	assert_str(MilitaryCampaign._our_battle_order({"home_side":"attacker","home_force_kind":"field_army","attacker":ours,"attacker_initial":20})).is_equal("hold")
	ours.troops=9
	assert_str(MilitaryCampaign._our_battle_order({"home_side":"attacker","home_force_kind":"field_army","attacker":ours,"attacker_initial":20})).is_equal("retreat")
	assert_str(MilitaryCampaign._our_battle_order({"home_side":"defender","home_force_kind":"field","defender":ours,"defender_initial":20})).is_equal("hold")
	# The war leader's rest reads the same line.
	assert_bool(Lines.unfit({"morale":0.24,"troops":20,"formations":[_formation(1,"levy","spear",20)]})).is_true()
	assert_bool(Lines.unfit({"morale":0.26,"troops":20,"formations":[_formation(1,"levy","spear",20)]})).is_false()


# --- 5. Weak bands in one place join under the senior general -------------------

func test_weak_bands_in_one_place_merge_under_the_senior_general()->void:
	var tavo:=_general("Tavo Kesh","figure_7",0.7)
	var rovik:=_general("Rovik Ash","figure_3",0.4)
	MilitaryCampaign.field_armies.assign([
		_band(3,[_formation(31,"levy","improvised",5,20)],30.0,rovik),
		_band(5,[_formation(51,"levy","improvised",6,20),_formation(52,"archer","bow",2,5)],30.0,tavo),
		_band(9,[_formation(91,"levy","improvised",18,20)],60.0)])
	MilitaryCampaign.field_armies[0]["wounded_pool"]=3
	# A draft in drill for Rovik's band follows the men.
	MilitaryCampaign.training_queue.append({"id":900,"mode":"field_draft","field_army_id":3,"target_formation_id":31,"unit":"levy","weapon":"improvised","count":4,"initial_count":4,"progress_days":0.0,"required_days":20.0})
	MilitaryCampaign.next_training_order_id=901
	var before:=_people_under_arms()
	var merged:int=MilitaryCampaign.upkeep.merge_day(int(GameState.elapsed_days))
	assert_int(merged).is_equal(1)
	assert_int(MilitaryCampaign.field_armies.size()).is_equal(2)
	# Tavo commands better: Rovik's men join his band.
	assert_int(MilitaryCampaign._field_army_index(3)).is_equal(-1)
	var band:Dictionary=MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(5)]
	assert_str(String((band.commander as Dictionary).name)).is_equal("Tavo Kesh")
	assert_int(int(band.troops)).is_equal(13)
	assert_int(Lines.full_strength(band)).is_equal(45)
	assert_int(int(band.get("wounded_pool",0))).is_equal(3)
	assert_int(int(MilitaryCampaign.training_queue[-1].field_army_id)).is_equal(5)
	# The strong band elsewhere is untouched; nobody is lost or made.
	assert_int(int(MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(9)].troops)).is_equal(18)
	assert_int(_people_under_arms()).is_equal(before)
	assert_array(MilitaryCampaign.validate_state().filter(func(e:String)->bool:return e.begins_with("Field army"))).is_empty()


# --- 6. The country round a long camp is eaten out ------------------------------

func test_forage_runs_out_on_a_long_camp()->void:
	var band:=_band(4,[_formation(1,"levy","improvised",20)],40.0)
	# Twenty men live off ordinary country in full at first.
	assert_float(Rations.forage_share(band)).is_equal(1.0)
	var fed_days:=0
	for day in 200:
		var share:=Rations.forage_share(band)
		if share>=Rations.HUNGRY_BELOW: fed_days+=1
		Supply.eat_camp(band,share*20.0,1.0)
	# About three months, then the country round the camp is eaten out.
	assert_int(fed_days).is_between(80,130)
	assert_float(Rations.forage_share(band)).is_less(Rations.HUNGRY_BELOW)
	assert_float(float(band.camp_days)).is_equal(200.0)
	assert_float(float(band.forage_left)).is_less(0.5)
	# A host of a hundred and fifty eats it out in days.
	var host:=_band(5,[_formation(1,"levy","improvised",150)],80.0)
	var days:=0
	while Rations.forage_share(host)>=Rations.HUNGRY_BELOW and days<60:
		Supply.eat_camp(host,Rations.forage_share(host)*150.0,1.0); days+=1
	assert_int(days).is_between(3,9)
	# Moving on, it is fresh country again.
	band["status"]="moving"
	Supply.eat_camp(band,0.0,1.0)
	band["status"]="stationed"
	assert_float(Rations.forage_share(band)).is_equal(1.0)
	# The supply words say so while they are camped there.
	var report:={"ratio":0.5,"forage_left":0.2,"camp_days":90.0,"force_kind":"field","days":1.0,"hub":"Seanstone"}
	assert_str(Supply.words(report)).contains("eaten out")


# --- 7. A broken band withdraws -------------------------------------------------

func test_a_broken_band_out_in_the_field_comes_back_to_rest_and_refills()->void:
	# Ennis's band: 4 of 13, will gone, a third fed and hungry, still out
	# where it lost.
	MilitaryCampaign.army_levy_level="many"
	var ennis:=_band(12,[_formation(121,"levy","improvised",4,13)],30.0,_general("Ennis Vale","figure_12",0.5))
	ennis["morale"]=0.0;ennis["provision_ratio"]=0.37;ennis["hungry_days"]=14.0
	MilitaryCampaign.field_armies.assign([ennis])
	MilitaryCampaign.upkeep.day()
	var band:Dictionary=MilitaryCampaign.field_armies[0]
	assert_bool(bool(band.resting)).is_true()
	assert_str(String(band.rest_reason)).is_equal("broken")
	assert_str(String(band.status)).is_equal("moving")
	assert_str(String(band.destination_id)).is_equal("player_home")
	assert_str(String(band.command_status)).is_equal(MilitaryCampaign.upkeep.WITHDRAWING)
	# It is not sent to fight meanwhile.
	assert_bool(Lines.unfit(band)).is_true()
	# Home: fed by hand, the drafts come from the size the ruler set.
	var at:=_home()
	band.merge({"status":"stationed","location_id":"player_home","position":{"x":at.x,"z":at.y},"destination_id":""},true)
	band["hungry_days"]=0.0;band["provision_ratio"]=1.0
	MilitaryCampaign.upkeep.day()
	assert_str(String(band.command_status)).is_equal(MilitaryCampaign.upkeep.RESTING)
	var started:Array=MilitaryCampaign.sustainment.draft_day()
	assert_int(started.size()).is_equal(1)
	assert_int(int(started[0].count)).is_equal(9)
	var order:Dictionary=MilitaryCampaign.training_queue[-1]
	MilitaryCampaign.training_queue.erase(order)
	var draft:Dictionary=MilitaryCampaign.sustainment.dispatch(order)
	GameState.elapsed_days=int(draft.arrive_day)
	MilitaryCampaign.sustainment.arrivals_day()
	assert_int(int(band.troops)).is_equal(13)
	# Rested in camp, fed, it is ready again.
	for day in 40: MilitaryCampaign.sustainment.rest_day(band,1.0)
	MilitaryCampaign.upkeep.day()
	assert_bool(bool(band.resting)).is_false()
	assert_str(String(band.command_status)).is_equal("Rested and ready")


func test_a_broken_band_will_not_be_sent_to_attack()->void:
	var weak:=_band(6,[_formation(61,"levy","spear",4,20)],0.5)
	MilitaryCampaign.field_armies.assign([weak])
	MilitaryCampaign.active_threat={"campaign_mode":"offensive","field_army_id":6,"source_civ_id":"rival","enemy_force":MilitaryCampaign.simulator.create_formation_force("Them",[_formation(1,"levy","spear",10)],0.7,0.6),"seed":5,"terrain_defense":1.0}
	var result:Dictionary=MilitaryCampaign.begin_threat_engagement(false)
	assert_bool(bool(result.get("unfit",false))).is_true()
	assert_str(String(result.error)).contains("not fit to attack")
	assert_dict(MilitaryCampaign.active_threat).is_empty()
	assert_dict(MilitaryCampaign.active_engagement).is_empty()


# --- 8. A garrison takes only what its town needs ------------------------------

func test_a_garrison_takes_only_what_its_town_needs_and_leaves_no_army_of_nobody()->void:
	var rovik:=_general("Rovik Ash","figure_3",0.6)
	var band:=_band(8,[_formation(81,"levy","spear",40)],20.0,rovik)
	band["readiness"]=1.0
	MilitaryCampaign.field_armies.assign([band])
	var region:={"id":"tsaren","name":"Tsaren"}
	var garrison:Dictionary=MilitaryCampaign.establish_occupation_force("rival",region,10.0,8)
	var need:=Hold.need(10.0,1.0,0.9)
	assert_int(int(garrison.troops)).is_equal(need)
	assert_bool(need<40).is_true()
	# The rest stay a band under their general; the garrison serves under the
	# war leader, not under a second copy of the general.
	var left:Dictionary=MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(8)]
	assert_int(int(left.troops)).is_equal(40-need)
	assert_str(String((left.commander as Dictionary).get("figure_id",""))).is_equal("figure_3")
	assert_str(String((garrison.commander as Dictionary).get("figure_id",""))).is_not_equal("figure_3")
	assert_str(String((garrison.commander as Dictionary).get("name",""))).is_equal(String((MilitaryCampaign.home_army.commander as Dictionary).get("name","")))
	assert_bool(Hold.holds(MilitaryCampaign.occupation_forces[0],10.0)).is_true()
	# A town that needs every man: the band becomes its garrison, general and
	# all, and no band of nobody is left behind.
	var second:=_band(9,[_formation(91,"levy","spear",12)],25.0,_general("Hewin Dale","figure_4",0.5))
	second["readiness"]=1.0
	second["wounded_pool"]=2
	MilitaryCampaign.field_armies.append(second)
	var all:Dictionary=MilitaryCampaign.establish_occupation_force("rival",{"id":"varrow","name":"Varrow"},30.0,9)
	assert_int(int(all.troops)).is_equal(12)
	assert_int(MilitaryCampaign._field_army_index(9)).is_equal(-1)
	assert_str(String((all.commander as Dictionary).get("figure_id",""))).is_equal("figure_4")
	assert_int(int(MilitaryCampaign.occupation_force_for_region("rival","varrow").get("wounded_pool",0))).is_equal(2)
	for army in MilitaryCampaign.field_armies: assert_int(int((army as Dictionary).troops)).is_greater(0)


# --- 9. Every town has guards ---------------------------------------------------

func test_a_town_that_is_not_home_has_its_own_watch()->void:
	GameState.population_allocations["Defense"]=40
	var second:Dictionary={"id":"settlement_002","sequence":2,"primary":false,"name":"Harbor","position":Vector2(100,0),"population_share":.25,"founded_day":0,"status":"established","territory_context":{},"environment_profile":{}}
	GameState.player_settlements.append(second);GameState.next_player_settlement_id=3;SettlementModel._ensure_city_resources(second)
	var watch:Dictionary=Combat.town_watch("settlement_002")
	# A quarter of the people live there: a quarter of the forty on defence,
	# beside a quarter of the townsfolk who rise (civilization_combat
	# guard_ledger).
	var parts:Dictionary=Combat.guard_ledger().get("settlement_002",{})
	assert_int(int(parts.watch)).is_equal(10)
	assert_int(int(parts.rise)).is_greater(0)
	assert_int(int(watch.troops)).is_equal(10+int(parts.rise))
	assert_str(String(watch.town_watch)).is_equal("settlement_002")
	# Their fight is the town's own: its dead die there, home's levy is untouched.
	var people:=GameState.population_total
	var levy_before:=int(MilitaryCampaign.home_army.troops)
	MilitaryCampaign._apply_town_watch_result("settlement_002",{"captured_in_battle":2},[{"defender_casualties":{"killed":3,"wounded":2}}],"defender")
	assert_int(GameState.population_total).is_equal(people-3)
	assert_int(int(MilitaryCampaign.home_army.troops)).is_equal(levy_before)
	assert_int(int(MilitaryCampaign.home_army.captured_pool)).is_equal(2)


# --- 10. Pulling back never gives home away -------------------------------------

func _home_besieged()->String:
	FoodSystem.initialize();FoodSystem.receive_external_food(100000)
	var civ:Dictionary=CivilizationSystem.civilizations[0];civ.player_relation.at_war=true
	MilitaryCampaign._create_civilization_threat({"source_civ_id":civ.id,"source_name":civ.name,"strength":1000,"incident_kind":"campaign"},"defensive")
	assert_bool(MilitaryCampaign.begin_siege().get("ok",false)).is_true()
	return String(civ.id)


func test_a_withdrawal_never_gives_home_away()->void:
	var civ_id:=_home_besieged()
	var siege_id:=String(MilitaryCampaign.active_siege.id)
	var pulled:Dictionary=MilitaryCampaign.siege_order(siege_id,"withdraw")
	assert_bool(pulled.has("error")).is_true()
	assert_bool(bool(pulled.get("surrender_only",false))).is_true()
	assert_bool(MilitaryCampaign.recovery.home_unavailable()).is_false()
	assert_dict(MilitaryCampaign.active_siege).is_not_empty()
	# The ruler's own word yields it.
	assert_bool(MilitaryCampaign.siege_order(siege_id,"surrender").has("ok")).is_true()
	assert_bool(MilitaryCampaign.recovery.home_unavailable()).is_true()
	assert_str(String(SettlementModel.settlement_record(String(MilitaryCampaign.recovery.data.occupied[0].city_id)).occupied_by)).is_equal(civ_id)


func test_pulling_back_from_a_fight_at_home_keeps_home()->void:
	_home_besieged()
	MilitaryCampaign.active_threat=MilitaryCampaign.active_siege.threat.duplicate(true)
	MilitaryCampaign.active_siege.clear()
	GameState.population_allocations["Defense"]=20
	assert_bool(MilitaryCampaign.begin_threat_engagement(false).has("error")).is_false()
	var food_before:=float(GameState.resource_stockpiles.get("Food",0.0))
	var result:Dictionary=MilitaryCampaign.advance_engagement("retreat")
	assert_str(String(result.outcome)).is_equal("defender_retreat")
	assert_bool(MilitaryCampaign.recovery.home_unavailable()).is_false()
	var outcome:Dictionary=result.strategic_outcome
	assert_bool(bool((outcome.player_occupation as Dictionary).get("surrender_only",false))).is_true()
	# Kept out of home, they carried off what they could.
	assert_bool(outcome.has("raid_losses")).is_true()
	assert_float(float(GameState.resource_stockpiles.get("Food",0.0))).is_less(food_before)
	var said:=MilitaryCampaign.battle_report_text(MilitaryCampaign.battle_history[0])
	assert_str(said).contains("it is still ours")


func test_a_lost_fight_at_home_is_not_the_loss_of_home()->void:
	_home_besieged()
	MilitaryCampaign.active_threat=MilitaryCampaign.active_siege.threat.duplicate(true)
	MilitaryCampaign.active_siege.clear()
	GameState.population_allocations["Defense"]=20
	assert_bool(MilitaryCampaign.begin_threat_engagement(false).has("error")).is_false()
	# A thousand broke our watch and could hold the town; still it is ours.
	MilitaryCampaign.active_engagement.attacker.supply_level=1.0
	MilitaryCampaign.active_engagement.defender.troops=0
	var result:=MilitaryCampaign._finish_active_engagement(false,{"outcome":"attacker_victory","winner":MilitaryCampaign.active_engagement.attacker.name,"termination":{"type":"rout","captor":MilitaryCampaign.active_engagement.attacker.name,"defeated":MilitaryCampaign.active_engagement.defender.name}})
	assert_bool(bool(result.strategic_outcome.decisive)).is_true()
	assert_bool(MilitaryCampaign.recovery.home_unavailable()).is_false()
	assert_str(String(result.strategic_outcome.message)).contains("only if its ruler yields it")


# --- Half pace counts in the one march estimate --------------------------------

func test_half_pace_counts_in_the_march_estimate()->void:
	# No carriers for a band already out: a band of twenty lives off the
	# land the whole way, at half pace.
	GameState.population_allocations["Logistics"]=0
	var band:=_band(3,[_formation(31,"levy","spear",20)],40.0)
	MilitaryCampaign.field_armies.assign([band])
	assert_float(float(MilitaryCampaign.carrier_reading().food)).is_less(0.05)
	var from:=_home()+Vector2(40.0,0.0)
	var road:Dictionary=MilitaryCampaign.field_route(from,from+Vector2(60.0,0.0),band)
	assert_bool(road.has("error")).override_failure_message(str(road)).is_false()
	var mix:=preload("res://scripts/march_terrain.gd").mix_of(band)
	var packed:Array=MilitaryCampaign._march_packed(road,mix)
	var full_pace:=preload("res://scripts/march_terrain.gd").days(from,packed,MilitaryCampaign._field_army_speed(band),int(GameState.elapsed_days),mix)
	var days:=MilitaryCampaign.march_days(band,road)
	assert_int(days).is_greater(full_pace)
	assert_int(days).is_less_equal(full_pace*2+1)
	var plan:Dictionary=MilitaryCampaign.march_supply(band,road)
	assert_int(int(plan.days)).is_equal(days)
	assert_float(float(plan.half_pace)).is_greater(0.5)
	# Sent on that road, the band's own reckoning of the days is the same.
	var live:Dictionary=MilitaryCampaign.field_armies[0]
	live["status"]="moving"
	MilitaryCampaign._set_march_route(live,road)
	assert_float(float(live.march_slowing)).is_greater(1.5)
	assert_int(MilitaryCampaign._march_days_left(live,from)).is_equal(days)


# --- One supply number ----------------------------------------------------------

func test_one_supply_number_on_the_band_its_runner_and_its_report()->void:
	var band:=_band(2,[_formation(21,"levy","spear",30)],40.0)
	# Eating every ration though its stores' condition lags behind.
	band["provision_ratio"]=1.0;band["supply_level"]=0.68
	assert_float(Supply.fed(band)).is_equal(1.0)
	var told:Dictionary=MilitaryCampaign._army_report_snapshot(band)
	assert_float(float(told.provision_ratio)).is_equal(1.0)
	assert_float(float(told.supply_level)).is_equal(1.0)
	# The army bar reads the runner's number: fed, not "short of food".
	var Bar:=preload("res://scripts/hud/army_bar_model.gd")
	band["last_report"]=told
	assert_str(String(Bar.known_supply(MilitaryCampaign,band).get("state",""))).is_equal("well")

extends GdUnitTestSuite
## ARMS WIRING (workstreams D and E): the makers' arms (weapons_stock.gd)
## reach the watch through the military's one weapons accessor
## (watch_military.gd): a made set becomes the watch's own kit in a joiner's
## hands; what the watch carries is read from its formations (no second
## count); kits handed back on a stand-down go to the armoury, never traded;
## sets lost in battle are kept on the arms record; the War screen's "armed"
## says the same.

const Watch:=preload("res://scripts/watch_military.gd")
const Arms:=preload("res://scripts/weapons_stock.gd")
const Ledger:=preload("res://scripts/trade_ledger.gd")

var _processing:Dictionary={}


func before_test()->void:
	if _processing.is_empty():
		for node:Node in [GameState,CivilizationSystem,MilitaryCampaign,ProgressionSystem]:_processing[node]=node.is_processing()
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(6063);GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world();FoodSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	SettlementModel.reset_for_new_world();PeopleDirection.reset_for_new_world()
	GameState.ensure_population_total(400);GameState.housing_capacity=500
	GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"];GameState.settlement_name="SEANSTONE"
	GameState.resource_stockpiles["Food"]=100000.0
	SettlementModel.ensure_founded()
	# The founders' practices (founding_knowledge.gd): hafted weapons among them.
	for id:String in preload("res://scripts/founding_knowledge.gd").PRACTICES:
		if id not in GameState.known_discoveries:GameState.known_discoveries.append(id)
		GameState.discovery_adoption[id]=1.0
	MilitaryCampaign.home_army=MilitaryCampaign._empty_home_army()
	for item in MilitaryCampaign.military_inventory.keys():MilitaryCampaign.military_inventory[item]=0
	GameState.resource_stockpiles[Arms.GOOD]=0.0


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
	for node:Node in _processing:node.set_process(bool(_processing[node]))


func _watch(share:float)->int:
	MilitaryCampaign.set_watch_share(share)
	MilitaryCampaign.keep_watch()
	return MilitaryCampaign.watch_manpower()

func _kit()->String:
	return String(Watch.arms_kit(MilitaryCampaign).item)

func _carried_at_home()->int:
	var carried:=0
	for f in MilitaryCampaign.home_army.get("formations",[]):carried+=int((f as Dictionary).get("equipment",0))
	return carried


func test_the_watch_has_a_kit_made_arms_can_become()->void:
	# The test world's people can arm line foot: made sets have a kit to become.
	assert_str(_kit()).is_not_equal("improvised")
	assert_str(Arms.kit_item()).is_equal(_kit())


func test_made_arms_reach_those_who_join_the_watch()->void:
	var item:=_kit()
	GameState.resource_stockpiles[Arms.GOOD]=12.0
	assert_int(Watch.weapons_held(MilitaryCampaign,item)).is_equal(12)
	var joined:=_watch(0.05)
	assert_int(joined).is_greater(12)
	# Twelve made sets went into the joiners' hands as the watch's kit; the
	# rest fight with what comes to hand.
	assert_float(Arms.stock()).is_equal_approx(0.0,0.0001)
	assert_int(_carried_at_home()).is_equal(12)
	for f in MilitaryCampaign.home_army.formations:assert_str(String((f as Dictionary).weapon)).is_equal(item)
	# What the watch carries is read from its formations: one ledger.
	assert_int(Arms.weapons_issued()).is_equal(12)
	assert_int(Arms.weapons_issued()).is_equal(Watch.weapons_carried(MilitaryCampaign))


func test_arms_wanted_counts_each_set_once()->void:
	var item:=_kit()
	GameState.resource_stockpiles[Arms.GOOD]=12.0
	var watch:=_watch(0.05)
	# Carried twelve, none held: the rest of the watch is still to arm.
	assert_int(Arms.arms_wanted()).is_equal(watch-12)
	# Three more made: held for the kit, not carried yet; wanted falls by three.
	GameState.resource_stockpiles[Arms.GOOD]=3.0
	assert_int(Arms.arms_wanted()).is_equal(watch-15)
	# The daily delivery puts them into the formations' hands: still counted once.
	var delivered:=MilitaryCampaign._deliver_inventory_replacements(1000.0)
	assert_int(delivered).is_equal(3)
	assert_float(Arms.stock()).is_equal_approx(0.0,0.0001)
	assert_int(Arms.weapons_issued()).is_equal(15)
	assert_int(Arms.arms_wanted()).is_equal(watch-15)
	# The makers plan for what is still wanted, no more.
	GameState.elapsed_days=5
	assert_int(int(Arms.plan_day().wanted)).is_equal(watch-15)


func test_a_stand_down_hands_the_kit_back_to_the_armoury()->void:
	var item:=_kit()
	GameState.resource_stockpiles[Arms.GOOD]=12.0
	_watch(0.05)
	var returned_before:=float(Arms.record().returned)
	MilitaryCampaign.set_watch_share(0.0)
	assert_int(int(MilitaryCampaign.home_army.troops)).is_equal(0)
	# Back as the kit, in the armoury: it arms the watch again, never traded.
	assert_int(int(MilitaryCampaign.military_inventory.get(item,0))).is_equal(12)
	assert_float(Arms.stock()).is_equal_approx(0.0,0.0001)
	assert_int(Watch.weapons_held(MilitaryCampaign,item)).is_equal(12)
	assert_int(Arms.weapons_issued()).is_equal(0)
	assert_float(Arms.trade_holding()).is_equal_approx(0.0,0.0001)
	assert_float(float(Arms.record().returned)-returned_before).is_equal_approx(12.0,0.0001)
	# The next to join take them up again.
	_watch(0.05)
	assert_int(_carried_at_home()).is_equal(12)


func test_sets_lost_in_battle_are_kept_on_the_arms_record()->void:
	GameState.resource_stockpiles[Arms.GOOD]=20.0
	_watch(0.05)
	var carried:=Arms.weapons_issued()
	assert_int(carried).is_equal(20)
	var lost_before:=float(Arms.record().lost)
	var enemy:={"formations":[{"unit":"levy","count":60,"training":0.9,"personnel_condition":1.0,"weapon":"spear","equipment":60,"equipment_required":60}],"supply_level":1.0}
	var result:Dictionary=MilitaryCampaign.simulator.simulate(MilitaryCampaign.home_army,enemy,{"seed":4242,"max_rounds":6})
	MilitaryCampaign._commit_campaign_battle(result)
	var gone:=carried-Arms.weapons_issued()
	assert_int(gone).is_greater_equal(0)
	assert_float(float(Arms.record().lost)-lost_before).is_equal_approx(float(gone),0.0001)


func test_the_war_screen_says_how_the_watch_is_armed()->void:
	GameState.resource_stockpiles[Arms.GOOD]=10.0
	var watch:=_watch(0.05)
	var required:=0
	for f in MilitaryCampaign.home_army.formations:required+=int((f as Dictionary).get("equipment_required",(f as Dictionary).count))
	var reading:=Watch.reading(MilitaryCampaign)
	assert_float(float(reading.armed)).is_equal_approx(float(Arms.weapons_issued())/float(required),0.0001)
	assert_float(float(reading.armed)).is_equal_approx(10.0/float(required),0.0001)
	assert_int(watch).is_greater(10)


func test_an_old_armourys_kits_of_another_kind_are_never_sold_and_never_stand_for_the_watchs_own()->void:
	var item:=_kit()
	var other:="bow" if item!="bow" else "spear"
	MilitaryCampaign.military_inventory[other]=30
	var watch:=_watch(0.05)
	# Bows in the armoury do not arm the watch's own kit and do not stop the makers.
	assert_int(Watch.weapons_held(MilitaryCampaign,item)).is_equal(0)
	assert_int(Arms.arms_wanted()).is_equal(watch)
	assert_float(Arms.trade_holding()).is_equal_approx(0.0,0.0001)


## Knowledge held at an adoption.
func _know(id:String,adoption:float)->void:
	if id not in GameState.known_discoveries:GameState.known_discoveries.append(id)
	GameState.discovery_adoption[id]=adoption

func test_the_kit_follows_the_makers_age_never_a_weapon_merely_known()->void:
	# Stone age: spears.
	assert_str(_kit()).is_equal("spear")
	assert_str(String((Arms.arms_age().age as Dictionary).id)).is_equal("stone")
	# Rifles and muskets merely understood (known, practice not learned): the
	# kit stays what the makers make, never a prototype cohort.
	_know("metallic_cartridges",0.05)
	_know("matchlock_drill",0.05)
	assert_str(_kit()).is_equal("spear")
	var watch:=_watch(0.05)
	for f in MilitaryCampaign.home_army.formations:
		assert_str(String((f as Dictionary).weapon)).is_equal("spear")
		assert_bool(bool((f as Dictionary).get("prototype",false))).is_false()
		assert_int(int((f as Dictionary).get("ammunition_required",0))).is_equal(0)
	assert_int(watch).is_greater(0)
	# Bronze learned: the makers make bronze arms, and the kit is a bronze weapon.
	_know("bronze_weaponry",1.0)
	GameState.elapsed_days=3
	assert_str(String((Arms.arms_age().age as Dictionary).id)).is_equal("bronze")
	assert_bool(_kit() in ["sword_shield","axe"]).is_true()
	assert_float(float(Arms.cost_per_fighter().maker_days)).is_equal(16.0)


func test_spearmen_with_no_gear_are_armed_by_bronze_age_makers()->void:
	# The probe: twenty spearmen at home, none armed; bronze learned; twenty made sets.
	MilitaryCampaign._rebuild_home_army_with([{"id":41,"unit":"spearman","weapon":"spear","count":20,"authorized_count":20,"equipment":0,"equipment_required":20,"ammunition":0,"ammunition_required":0,"training":0.4,"experience":0.0,"personnel_condition":1.0}])
	_know("bronze_weaponry",1.0)
	GameState.elapsed_days=4
	assert_bool(_kit()!="spear").is_true()
	# Their gap is one made sets can fill (an older smith still makes spears).
	assert_float(Arms.arms_gaps()).is_greater_equal(20.0)
	GameState.resource_stockpiles[Arms.GOOD]=20.0
	var delivered:=MilitaryCampaign._deliver_inventory_replacements(1000.0)
	assert_int(delivered).is_equal(20)
	assert_int(_carried_at_home()).is_equal(20)
	assert_float(Arms.stock()).is_equal_approx(0.0,0.0001)


func test_an_older_saves_levy_with_what_comes_to_hand_takes_up_made_arms()->void:
	# An older save: twenty levy at home with improvised arms, nothing else.
	MilitaryCampaign.military_inventory["improvised"]=0
	MilitaryCampaign._rebuild_home_army_with([{"id":42,"unit":"levy","weapon":"improvised","count":20,"authorized_count":20,"equipment":20,"equipment_required":20,"ammunition":0,"ammunition_required":0,"training":0.3,"experience":0.0,"personnel_condition":1.0}])
	MilitaryCampaign.set_watch_share(20.0/float(GameState.population_total))
	# The makers see them as wanting arms (no deadlock): all twenty.
	assert_int(Arms.arms_wanted()).is_greater_equal(20)
	GameState.elapsed_days=6
	assert_int(int(Arms.plan_day().wanted)).is_greater_equal(20)
	# Made sets come: the levy takes up the made kit, its old arms to the armoury.
	GameState.resource_stockpiles[Arms.GOOD]=8.0
	var men:=Watch.rekit_for_made(MilitaryCampaign)
	assert_int(men).is_equal(20)
	var levy:Dictionary=MilitaryCampaign.home_army.formations[0]
	assert_str(String(levy.weapon)).is_equal(_kit())
	assert_int(int(MilitaryCampaign.military_inventory.improvised)).is_equal(20)
	MilitaryCampaign._deliver_inventory_replacements(1000.0)
	assert_int(_carried_at_home()).is_equal(8)
	assert_int(Arms.weapons_issued()).is_equal(8)
	# Still wanted: the twelve they lack, nothing tradeable meanwhile.
	assert_int(Arms.arms_wanted()).is_equal(12)
	assert_float(Arms.trade_holding()).is_equal_approx(0.0,0.0001)


func test_gear_reserved_for_drill_and_on_the_road_is_not_wanted_again()->void:
	var watch:=_watch(0.05)
	var before:=Arms.arms_gaps()
	# A drill order whose twenty sets are reserved: no more are wanted for it.
	MilitaryCampaign.training_queue.append({"id":901,"mode":"new","unit":"spearman","weapon":"spear","count":20,"initial_count":20,"reserved_equipment":20,"progress_days":0.0,"required_days":30.0})
	assert_float(Arms.arms_gaps()).is_equal_approx(before,0.0001)
	# Half reserved: ten more wanted.
	(MilitaryCampaign.training_queue.back() as Dictionary)["reserved_equipment"]=10
	assert_float(Arms.arms_gaps()).is_equal_approx(before+10.0,0.0001)
	MilitaryCampaign.training_queue.pop_back()
	# Sets on the road to a band cover its gap.
	MilitaryCampaign.field_drafts.append({"weapon":"spear","equipment":5,"count":5})
	assert_float(Arms.arms_gaps()).is_equal_approx(maxf(0.0,before-5.0),0.0001)
	MilitaryCampaign.field_drafts.pop_back()
	assert_int(watch).is_greater(0)

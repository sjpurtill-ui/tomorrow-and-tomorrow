extends GdUnitTestSuite
## DISBANDED MEANS DISBANDED, AND PEACE MADE STAYS MADE. The user, on the
## year-212 save: "My military leader, lorn, keeps sending and resending and
## resending people to negotiate peace over and over. even though it has been
## established." and "All mechanics for disbanded armies seem to fail. They
## just retrain them."
## What the save showed:
## - A band home from its raid rested at home for ten years, still marked as
##   out against Ildor, so the feud read as hot; every 120 days the war leader
##   sent messengers and the feud was "settled" again (15 times).
## - The band never finished resting: its empty places were one here and two
##   there, too few to call a draft for, so it waited for drafts that never
##   came, and nothing could fold it back.
## - "Disband the army" was not read at all ("dismiss the army" even read as
##   demoting someone); a stand-down took the watch, which the watch's own
##   drill then made again, and the army's share called the rest up again.
## KEEPING WATCH IS THE MILITARY (watch_military.gd): the watch share is the
## army's size; standing people down lowers it, so nobody is called up in
## their place.

const Council:=preload("res://scripts/war_council.gd")
const WAR:=preload("res://scripts/war_loop.gd")
const Route:=preload("res://scripts/army_land_route.gd")
const Law:=preload("res://scripts/army_levy_law.gd")
const HomeOrders:=preload("res://scripts/home_orders.gd")
const CC:=preload("res://scripts/court_commands.gd")

var civ_id:=""
var city_id:=""
var _processing:Dictionary={}

func _land(_p:Vector2)->bool:
	return true

func before_test()->void:
	if _processing.is_empty():
		for node:Node in [GameState,CivilizationSystem,MilitaryCampaign,ProgressionSystem]: _processing[node]=node.is_processing()
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(74017);GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world();FoodSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world();ForeignDiplomacy.ensure();GovernmentPeopleSystem.reset_for_new_world()
	GameState.ensure_population_total(900);GameState.housing_capacity=1000
	GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	GameState.select_founding_focus("provision")
	GameState.settlement_name="Seanstone"
	GameState.society_capacities["institutions"]=0.4
	GovernmentPeopleSystem._update_government_stage(false)
	GovernmentPeopleSystem.initialize()
	GameState.resource_stockpiles["Food"]=1000000.0
	GameState.elapsed_days=88*365
	Route.clear_cache()
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ["name"]="Ildor"
	civ_id=String(civ.id)
	var relation:Dictionary=civ.player_relation
	relation.at_war=false; relation.treaty="none"; relation.contact_level=2; relation.home_location_known=true; relation.met_day=0
	var region:Dictionary=civ.strategic_regions[CivilizationSystem._frontline_region_index(civ)]
	region["name"]="Eldwick"
	city_id=String(region.id)
	CivilizationSystem.set_scout_geography_authority(Callable(self,"_land"))
	# Ten keep the watch at home: set to defence work.
	GameState.population_allocations["Defense"]=10

func after_test()->void:
	CivilizationSystem.set_scout_geography_authority(Callable())
	Route.clear_cache()
	GameState.elapsed_days=0
	MilitaryCampaign.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	DiscoverySystem.reset_for_new_world()
	GameState.reset_for_new_world(74017)
	ProgressionSystem.reset_for_new_world()
	WorldSimulation.clear()
	WorldSimulation.context_provider=Callable()

func _train(count:int,drill:float=0.6)->void:
	MilitaryCampaign.military_inventory["improvised"]=int(MilitaryCampaign.military_inventory.get("improvised",0))+count
	MilitaryCampaign.raise_recruits(count)
	MilitaryCampaign.start_training("levy","improvised",count)
	MilitaryCampaign._complete_training(MilitaryCampaign.training_queue[0].duplicate(true))
	MilitaryCampaign.training_queue.clear()
	for f in MilitaryCampaign.home_army.get("formations",[]): (f as Dictionary)["training"]=maxf(float((f as Dictionary).get("training",0.0)),drill)

## A band of `count` formed at home and given a raid's errand against Ildor
## that is over (`phase`), resting at home when `resting`.
func _band(count:int,name:String,phase:="home",resting:=true)->int:
	var made:Dictionary=MilitaryCampaign.create_field_army(count,name)
	assert_bool(made.has("army")).override_failure_message(str(made)).is_true()
	var army_id:=int((made.army as Dictionary).army_id)
	var band:Dictionary=_army(army_id)
	band["council"]={"civ":civ_id,"act":"punish","city":city_id,"name":"Eldwick","since":int(GameState.elapsed_days)-3600,"phase":phase,"formed":true}
	band["resting"]=resting
	band["departure_day"]=int(GameState.elapsed_days)-3700;band["arrival_day"]=int(GameState.elapsed_days)-3600
	return army_id

## A band away from home, standing at Eldwick.
func _band_away(count:int,name:String)->int:
	var army_id:=_band(count,name,"home",false)
	var band:Dictionary=_army(army_id)
	band.erase("council")
	band["status"]="stationed";band["location_id"]=city_id;band["location_name"]="Eldwick";band["destination_id"]=""
	band["position"]={"x":CivilizationSystem.player_world_origin.x-20.0,"z":CivilizationSystem.player_world_origin.y+8.0}
	return army_id

func _army(army_id:int)->Dictionary:
	var index:=MilitaryCampaign._field_army_index(army_id)
	return MilitaryCampaign.field_armies[index] if index>=0 else {}

func _told(words:String)->int:
	var n:=0
	for e in (GameState.chronicle.get("entries",[]) as Array):
		if String((e as Dictionary).get("text","")).contains(words) or String((e as Dictionary).get("title","")).contains(words): n+=1
	return n

func _days(n:int)->void:
	for i in n:
		GameState.elapsed_days=int(GameState.elapsed_days)+1
		var day:=int(GameState.elapsed_days)
		MilitaryCampaign.last_processed_day=day
		MilitaryCampaign._process_military_day()
		WAR.daily(day)
		Council.day(day)

# ---------------------------------------------------------------------------
# Peace made stays made
# ---------------------------------------------------------------------------

func test_a_band_resting_at_home_after_its_raid_is_not_out_against_them()->void:
	_train(60)
	var army_id:=_band(30,"Raiders for Eldwick")
	assert_bool(WAR._bands_out(civ_id)).is_false()
	# Out on its raid it is.
	_army(army_id).council["phase"]="out"
	assert_bool(WAR._bands_out(civ_id)).is_true()

func test_the_feud_settled_is_never_settled_again()->void:
	_train(60)
	var day:=int(GameState.elapsed_days)
	WAR.blood_feud(civ_id,day,"the killing of their envoy Qira")
	WAR.front(civ_id).merge({"their_dead":3,"our_dead":6,"pending":{}},true)
	# The god said: seek peace. The messengers came back with it.
	WAR.front(civ_id)["stance"]="peace"
	WAR._end_feud(civ_id,day,"parley","Lorn's messengers came back: Ildor will send no more raiders, and the feud is set down.")
	assert_int(_told("feud is set down")).is_equal(1)
	# The word to seek peace has done its work.
	assert_str(String(WAR.front(civ_id).get("stance",""))).is_empty()
	# An old save keeps the word and a band home from the raid, resting.
	WAR.front(civ_id)["stance"]="peace"
	_band(30,"Raiders for Eldwick")
	assert_bool(Council.fighting(civ_id)).is_false()
	for year in 3:
		GameState.elapsed_days=day+200*(year+1)
		Council.sit(int(GameState.elapsed_days))
		assert_dict(WAR.front(civ_id).get("op",{}) as Dictionary).is_empty()
	assert_str(String(WAR.front(civ_id).get("stance",""))).is_empty()
	# Messengers already on the road come back to a peace that holds: nothing
	# is settled twice.
	WAR._resolve_op(civ_id,{"objective":"war_parley","start":day,"due":day+20,"general":"Lorn"},int(GameState.elapsed_days))
	assert_int(_told("feud is set down")).is_equal(1)
	assert_int(_told("Will Not Talk")).is_equal(0)

func test_a_truce_ends_the_word_to_seek_peace()->void:
	WAR.front(civ_id)["stance"]="peace"
	WAR.front(civ_id)["war"]={"start":int(GameState.elapsed_days)-30,"our_dead":2,"their_dead":2}
	WAR._close_war(civ_id,int(GameState.elapsed_days),"truce","The messengers came back with a truce.")
	assert_str(String(WAR.front(civ_id).get("stance",""))).is_empty()
	# Another word given stays.
	WAR.front(civ_id)["stance"]="defend"
	WAR._close_war(civ_id,int(GameState.elapsed_days),"truce","Again.")
	assert_str(String(WAR.front(civ_id).get("stance",""))).is_equal("defend")

# ---------------------------------------------------------------------------
# Disbanded means disbanded
# ---------------------------------------------------------------------------

func test_the_court_reads_disbanding_the_army()->void:
	for said in ["Disband the army","disband our army","dismiss the army","stand down the army","stand the army down","send the army home","disband all the soldiers","send the soldiers back to the fields","release the army","demobilize the army","disband the bands"]:
		var r:=HomeOrders.read(said)
		assert_str(String(r.get("kind",""))).override_failure_message("'%s' was not a stand-down: %s" % [said,str(r)]).is_equal("stand_down")
		assert_bool(bool(r.get("all",false))).override_failure_message("'%s' did not mean all of them" % said).is_true()
	assert_str(String(CC.classify("dismiss the army").get("verb",""))).is_equal("home")
	# Not ours, not fighters, or one person: never a stand-down.
	for said in ["everyone come home","Dismiss the war chief","send the scouting band home","Strip Kavu of his office","release the prisoners","Dismiss Tahu"]:
		assert_str(String(HomeOrders.read(said).get("kind",""))).override_failure_message("'%s' was read as a stand-down" % said).is_not_equal("stand_down")
	# A number is a number.
	var five:=HomeOrders.read("send 5 of the soldiers home")
	assert_int(int(five.count)).is_equal(5)
	assert_bool(bool(five.all)).is_false()

func test_disbanding_the_army_sends_everyone_home_and_nobody_is_called_up_again()->void:
	_train(70)
	Law.choose(MilitaryCampaign,"war")
	MilitaryCampaign.training_queue.clear(); MilitaryCampaign.aggregate_recruits=0
	var resting:=_band(30,"Raiders for Eldwick")
	var away:=_band_away(10,"Host at Eldwick")
	var done:=HomeOrders.perform(HomeOrders.read("Disband the army"))
	assert_bool(bool(done.ok)).override_failure_message(str(done)).is_true()
	# The band resting at home folded back and went home with the rest; the
	# watch is the army, so nobody is left keeping it; the band away goes
	# home when it comes back.
	assert_dict(_army(resting)).is_empty()
	assert_int(int(MilitaryCampaign.home_army.get("troops",0))).is_equal(0)
	assert_dict(_army(away)).is_not_empty()
	assert_int(MilitaryCampaign.watch_manpower()).is_equal(0)
	assert_str(Law.reading(MilitaryCampaign).name).is_equal("0%")
	var says:=String(done.says)
	for words in ["go home","turn for home","Nobody keeps watch"]: assert_str(says).contains(words)
	# Nobody is called up again.
	assert_int(int(Law.keep(MilitaryCampaign,int(GameState.elapsed_days),true).joined)).is_equal(0)
	MilitaryCampaign._ensure_automatic_basic_training()
	assert_int(MilitaryCampaign._automatic_basic_trainees()).is_equal(0)
	_days(12)
	assert_int(MilitaryCampaign.aggregate_recruits).is_equal(0)
	assert_bool(MilitaryCampaign.training_queue.is_empty()).is_true()
	assert_int(int(MilitaryCampaign.home_army.get("troops",0))).is_equal(0)
	# The band away comes home and its men go back to work too.
	_army(away)["status"]="stationed"; _army(away)["location_id"]="player_home"
	Law.keep(MilitaryCampaign,10,true)
	Council.fold_idle_bands()
	Law.keep(MilitaryCampaign,10,true)
	assert_dict(_army(away)).is_empty()
	assert_int(Law.under_arms(MilitaryCampaign)).is_equal(0)

func test_sending_some_home_lowers_the_share_to_what_is_left()->void:
	_train(37)
	Law.choose(MilitaryCampaign,"some")
	var people:=int(WorldSimulation.state.population_total)
	assert_int(Law.under_arms(MilitaryCampaign)).is_equal(Law.target_men("some",people))
	var done:=HomeOrders.perform(HomeOrders.read("send 7 of the soldiers home"))
	assert_int(int(done.count)).is_equal(7)
	var left:=Law.under_arms(MilitaryCampaign)
	assert_int(left).is_equal(Law.target_men("some",people)-7)
	# The watch fell by them: those sent home are not called up again.
	assert_int(MilitaryCampaign.watch_manpower()).is_equal(left)
	assert_str(Law.reading(MilitaryCampaign).level).starts_with("share:")
	assert_str(String(done.says)).contains("%d keep watch" % left)
	# The war leader neither calls up nor sends home anyone on its account.
	var kept:=Law.keep(MilitaryCampaign,int(GameState.elapsed_days),true)
	assert_int(int(kept.joined)+int(kept.released)).is_equal(0)
	assert_int(Law.under_arms(MilitaryCampaign)).is_equal(left)

func test_one_band_named_is_disbanded_whole()->void:
	_train(60)
	var raiders:=_band(30,"Raiders for Eldwick")
	var read:=HomeOrders.read("disband the raiders for eldwick")
	assert_int(int(read.get("band",0))).is_equal(raiders)
	var done:=HomeOrders.perform(read)
	assert_bool(bool(done.ok)).is_true()
	assert_dict(_army(raiders)).is_empty()
	assert_int(int(MilitaryCampaign.home_army.get("troops",0))).is_equal(30)
	assert_str(String(done.says)).contains("is no more")
	# One out: it turns for home to be stood down.
	var host:=_band_away(10,"Host at Eldwick")
	var out:=HomeOrders.perform(HomeOrders.read("disband the host at eldwick"))
	assert_str(String(out.says)).contains("turns for home")
	assert_str(String(_army(host).get("destination_id",""))).is_equal("player_home")

func test_a_band_is_never_formed_from_the_home_guard()->void:
	_train(10)
	MilitaryCampaign.keep_watch()
	MilitaryCampaign.set_watch_split(0.5)
	assert_int(int(Council._forces().free)).is_greater(0)
	assert_int(int(Council._forces().keep)).is_equal(int(MilitaryCampaign.watch_reading().guard))
	# All of the watch kept at home: nobody is free for a band.
	MilitaryCampaign.set_watch_split(1.0)
	assert_int(int(Council._forces().free)).is_equal(0)

func test_a_band_resting_with_scattered_empty_places_is_ready_again()->void:
	_train(40)
	var army_id:=_band(16,"Raiders for Eldwick")
	var band:=_army(army_id)
	# Eight places of two with one man each: half its men, three in four
	# needed to be rested, and no gap big enough for a draft.
	var formations:Array=[]
	for i in 8: formations.append({"id":900+i,"unit":"levy","weapon":"improvised","count":1,"authorized_count":2,"equipment":2,"equipment_required":2,"training":0.6,"experience":0.0,"personnel_condition":1.0})
	band["formations"]=formations
	band["troops"]=8
	band["morale"]=1.0
	band["rest_place"]=""
	MilitaryCampaign.sustainment.draft_day()
	assert_str(String(_army(army_id).get("draft_block",""))).is_equal("few")
	MilitaryCampaign.upkeep.day()
	assert_bool(bool(_army(army_id).get("resting",false))).is_false()

func test_the_army_size_has_none_and_reads_a_share_left_by_a_stand_down()->void:
	assert_str(Law.level_name("none")).is_equal("0%")
	assert_int(Law.target_men("none",900)).is_equal(0)
	assert_str(Law.level_name("share:0.0222")).is_equal("2%")
	assert_str(Law.level_name("share:0.004")).is_equal("0.4%")
	assert_dict(Law.level("share:1.5")).is_empty()
	# The level survives a save.
	MilitaryCampaign.army_levy_level="share:0.02222"
	var saved:Dictionary=MilitaryCampaign.export_state()
	assert_str(String(saved.army_levy_level)).is_equal("share:0.02222")

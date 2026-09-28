extends GdUnitTestSuite
## After a victory the general settles the captives and spoils himself, at
## once, by the ruler's standing word or the era's custom and his own nature,
## and says so in one line of his report. Nothing waits on the ruler: no
## march, recruiting or day's step is held up by it. The ruler can change it
## in court for a while, only by what is still in our hands. A strike by
## night goes in at a stated chance of reaching the enemy unseen.

const Tactics:=preload("res://scripts/battle_tactics.gd")
const Account:=preload("res://scripts/battle_account.gd")
const WO:=preload("res://scripts/court_war_orders.gd")

var _processing:Dictionary={}
var civ_id:=""


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
	GameState.resource_stockpiles["Food"]=5000.0
	GameState.elapsed_days=88*365
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ["name"]="Esurai"
	civ_id=String(civ.id)


func after_test()->void:
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
	for node:Node in _processing: node.set_process(bool(_processing[node]))


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

## A victory's aftermath as the resolver leaves it: twelve captives, food,
## a cart and six spears taken.
func _aftermath()->Dictionary:
	return {"type":"surrender","captor":"Rovik's band","defeated":"Esurai band","home_force_name":"Rovik's band","prisoners":12,
		"spoils":{"supplies":40,"carts":1,"weapons":{"spear":6},"consumables":{},"wealth":0},"captured_general":false,"commander":"Tavo Esurai"}


func _result(seed:int=5)->Dictionary:
	return {"home_side":"attacker","attacker":{"name":"Rovik's band","commander":{"name":"Rovik Longstride"}},"defender":{"name":"Esurai band"},
		"threat":{"source_name":"Esurai","source_civ_id":civ_id},"seed":seed,"id":"b-%d" % seed}


func _stock(item:String)->float:
	return float(GameState.resource_stockpiles.get(item,0.0))


# ---------------------------------------------------------------------------
# The general settles it
# ---------------------------------------------------------------------------

func test_the_general_settles_by_the_standing_word_and_the_ledger_adds_up()->void:
	MilitaryCampaign.set_aftermath_practice("prisoners","enslave")
	MilitaryCampaign.set_aftermath_practice("spoils","army stores")
	var bound:=_stock("Forced Labor"); var food:=_stock("Food"); var carts:=_stock("Transport Carts")
	var spears:=int(MilitaryCampaign.military_inventory.get("spear",0))
	var settled:=MilitaryCampaign._settle_aftermath(_aftermath(),_result())
	assert_dict(MilitaryCampaign.pending_aftermath).is_empty()
	assert_str(String(settled.line)).is_equal("Rovik sent twelve captives home as bondservants; the spoils went to the stores, as you ordered.")
	# Every number the line gives is in the ledger.
	assert_float(_stock("Forced Labor")-bound).is_equal_approx(12.0,0.001)
	assert_float(_stock("Food")-food).is_equal_approx(40.0,0.001)
	assert_float(_stock("Transport Carts")-carts).is_equal_approx(1.0,0.001)
	assert_int(int(MilitaryCampaign.military_inventory.get("spear",0))-spears).is_equal(6)
	assert_int(MilitaryCampaign.settlements.size()).is_equal(1)


func test_left_to_himself_the_general_follows_custom_and_never_kills_captives()->void:
	for name in ["Rovik Longstride","Ada Marrow","Tesh Kell","Orun Vale","Mira Stone","Kel Adder","Sura Wynn","Bram Holt"]:
		var practice:=MilitaryCampaign._general_practice(name,true)
		assert_str(String(practice.prisoners)).is_not_equal("execute")
		assert_str(String(practice.general)).is_not_equal("execute")
		assert_bool(String(practice.prisoners) in ["release","enslave","ransom","hold"]).is_true()
		# His nature is his for life: the same answer every time.
		assert_dict(MilitaryCampaign._general_practice(name,true)).is_equal(practice)
	# No people to pay: nobody is kept for a ransom that cannot come.
	MilitaryCampaign.set_aftermath_practice("prisoners","ransom")
	assert_str(String(MilitaryCampaign._practice_for("Rovik Longstride",false).prisoners)).is_equal("hold")


func test_a_victory_in_the_field_leaves_nothing_waiting_and_nothing_blocked()->void:
	# A band of 120 against 30: a victory, settled the day it ends.
	MilitaryCampaign.military_inventory["improvised"]=120
	MilitaryCampaign.raise_recruits(160)
	MilitaryCampaign.start_training("levy","improvised",160)
	MilitaryCampaign._complete_training(MilitaryCampaign.training_queue[0].duplicate(true))
	MilitaryCampaign.training_queue.clear()
	var made:Dictionary=MilitaryCampaign.create_field_army(120)
	var army_id:=int((made.army as Dictionary).army_id)
	var index:=MilitaryCampaign._field_army_index(army_id)
	var origin:Vector2=CivilizationSystem.player_world_origin
	MilitaryCampaign.field_armies[index]["position"]={"x":origin.x+5.0,"z":origin.y}
	MilitaryCampaign.field_armies[index]["status"]="stationed"
	var band:Dictionary=MilitaryCampaign.simulator.create_formation_force("Esurai band",[{"unit":"levy","weapon":"improvised","count":30,"equipment":0,"training":0.25}],0.6,0.3)
	MilitaryCampaign.active_threat={"id":"c","title":"x","incident_kind":"campaign","campaign_mode":"offensive","source_civ_id":civ_id,"source_name":"Esurai","field_encounter":true,"formation_id":"f1",
		"target_region_id":"","target_region_name":"the field contact","field_army_id":army_id,"enemy_force":band,"terrain_defense":1.0,"seed":31,"deadline_day":99999,"discovered_day":int(GameState.elapsed_days),
		"target_position":{"x":origin.x+5.2,"z":origin.y}}
	MilitaryCampaign.begin_threat_engagement()
	var days:=0
	while not MilitaryCampaign.own_engagements.is_empty() and days<10:
		MilitaryCampaign._fight_own_battles_day(); days+=1
	var record:Dictionary=MilitaryCampaign.battle_history[0]
	assert_str(String(record.outcome)).is_equal("attacker_victory")
	# Nothing waits on the ruler.
	assert_dict(MilitaryCampaign.pending_aftermath).is_empty()
	var settled:Dictionary=record.get("aftermath_settled",{})
	if int((record.termination as Dictionary).get("prisoners",0))>0:
		assert_str(String(settled.get("line",""))).is_not_empty()
		# The general's report says it in one line.
		var account:=Account.build(record,Account.gather(record))
		assert_str(String(account.now)).contains(String(settled.line))
		assert_str(Account.text(account)).not_contains("wait on your word first")
	# No march, recruiting, new band or day's step is held up.
	assert_str(String(WO.forces({}).busy)).is_equal("")
	assert_str(MilitaryCampaign.template_recruitment_blocker()).not_contains("aftermath")
	var formed:Dictionary=MilitaryCampaign.create_field_army(10)
	assert_bool(formed.has("error")).override_failure_message(str(formed)).is_false()


# ---------------------------------------------------------------------------
# The ruler changes it in court
# ---------------------------------------------------------------------------

func test_freeing_the_bondservants_frees_those_still_here_and_no_more()->void:
	MilitaryCampaign.set_aftermath_practice("prisoners","enslave")
	MilitaryCampaign._settle_aftermath(_aftermath(),_result())
	var bound:=_stock("Forced Labor")
	var legitimacy:=float(GameState.simulation_metrics.get("legitimacy",0.5))
	var freed:=MilitaryCampaign.revise_settlement("prisoners","release")
	assert_bool(freed.has("error")).override_failure_message(str(freed)).is_false()
	assert_int(int(freed.moved)).is_equal(12)
	assert_str(String(freed.done)).is_equal("Twelve captives set free.")
	assert_float(bound-_stock("Forced Labor")).is_equal_approx(12.0,0.001)
	assert_float(float(GameState.simulation_metrics.get("legitimacy",0.5))).is_greater(legitimacy)
	# Once they are gone they cannot be taken back.
	var again:=MilitaryCampaign.revise_settlement("prisoners","enslave")
	assert_str(String(again.get("reason",""))).is_equal("gone")
	assert_str(String(again.error)).contains("let go")


func test_giving_the_spoils_to_the_warriors_moves_what_the_stores_still_hold()->void:
	MilitaryCampaign.set_aftermath_practice("spoils","army stores")
	MilitaryCampaign._settle_aftermath(_aftermath(),_result())
	# Some of the food was eaten meanwhile: only what is left can go.
	GameState.resource_stockpiles["Food"]=25.0
	var morale:=float(MilitaryCampaign.home_army.get("morale",0.0))
	var given:=MilitaryCampaign.revise_settlement("spoils","reward troops")
	assert_bool(given.has("error")).override_failure_message(str(given)).is_false()
	assert_float(_stock("Food")).is_equal_approx(0.0,0.001)
	assert_int(int(MilitaryCampaign.military_inventory.get("spear",0))).is_equal(0)
	assert_str(String(given.done)).is_equal("25 food, 1 cart, 6 weapons went from the stores to the warriors.")
	assert_float(float(MilitaryCampaign.home_army.get("morale",0.0))).is_greater_equal(morale)
	# Given once; the stores are not emptied twice.
	assert_str(String(MilitaryCampaign.revise_settlement("spoils","return property").get("reason",""))).is_equal("done")


func test_after_the_window_it_is_done()->void:
	MilitaryCampaign._settle_aftermath(_aftermath(),_result())
	GameState.elapsed_days=float(GameState.elapsed_days)+MilitaryCampaign.SETTLE_WINDOW_DAYS+1
	var late:=MilitaryCampaign.revise_settlement("prisoners","release")
	# Held captives can still be freed from custody; others were settled for good.
	if String(MilitaryCampaign.settlements[0].prisoner_policy)!="hold": assert_str(String(late.get("reason",""))).is_equal("too_late")


func test_the_court_reads_captive_and_spoils_orders()->void:
	MilitaryCampaign.set_aftermath_practice("prisoners","enslave")
	MilitaryCampaign._settle_aftermath(_aftermath(),_result())
	var free:=WO.read("Free the captives")
	assert_str(String(free.kind)).is_equal("captives")
	assert_str(String(free.part)).is_equal("prisoners")
	assert_str(String(free.policy)).is_equal("release")
	assert_bool(bool(free.standing)).is_false()
	var done:=WO.perform(free)
	assert_str(String(done.verdict)).is_equal("fate")
	# What was done, then who they were (from the fight's own record).
	assert_str(String(done.says)).starts_with("Twelve captives set free.")
	assert_str(String(done.says)).contains("They were the Esurai we took")
	assert_str(String(done.outcome)).is_equal("Twelve captives set free.")
	var standing:=WO.read("From now on, give the spoils to the warriors")
	assert_str(String(standing.part)).is_equal("spoils")
	assert_str(String(standing.policy)).is_equal("reward troops")
	assert_bool(bool(standing.standing)).is_true()
	var set:=WO.perform(standing)
	assert_str(String(set.says)).is_equal("From now on, after every fight, the spoils go to the warriors.")
	assert_str(String(MilitaryCampaign.aftermath_practice.spoils)).is_equal("reward troops")
	assert_str(String(WO.read("Always ransom the captives").policy)).is_equal("ransom")
	# Nothing to act on and no standing word: not a captives order at all
	# (a held town's bound people are the garrison's business).
	MilitaryCampaign.settlements.clear()
	assert_str(String(WO.read("Free the captives").get("kind",""))).is_not_equal("captives")


func test_an_older_save_waiting_on_the_ruler_settles_itself()->void:
	MilitaryCampaign.pending_aftermath=_aftermath()
	MilitaryCampaign.battle_history=[_result(9)]
	var settled:=MilitaryCampaign.settle_pending_aftermath()
	assert_dict(MilitaryCampaign.pending_aftermath).is_empty()
	assert_str(String(settled.line)).is_not_empty()
	assert_str(String(MilitaryCampaign.battle_history[0].aftermath_settled.line)).is_equal(String(settled.line))
	# The standing word and the settlements are saved with the game.
	MilitaryCampaign.set_aftermath_practice("prisoners","release")
	var saved:=MilitaryCampaign.export_state()
	MilitaryCampaign.reset_for_new_world()
	assert_bool(MilitaryCampaign.import_state(saved).has("error")).is_false()
	assert_str(String(MilitaryCampaign.aftermath_practice.prisoners)).is_equal("release")
	assert_int(MilitaryCampaign.settlements.size()).is_equal(1)


# ---------------------------------------------------------------------------
# A strike by night
# ---------------------------------------------------------------------------

func test_the_chance_of_reaching_them_unseen_follows_what_is_really_there()->void:
	var base:={"troops":17,"march_days":2,"watchers":40.0,"alert":0.0,"cover":1.0,"tactics":0.5}
	var chance:=float(Tactics.surprise_odds(base).chance)
	assert_float(chance).is_between(Tactics.SURPRISE_MIN,Tactics.SURPRISE_MAX)
	var more:=base.duplicate(); more["troops"]=2000
	var far:=base.duplicate(); far["march_days"]=12
	var watched:=base.duplicate(); watched["watchers"]=600.0
	var wary:=base.duplicate(); wary["alert"]=1.0
	var woods:=base.duplicate(); woods["cover"]=Tactics.cover_of("forest")
	assert_float(float(Tactics.surprise_odds(more).chance)).is_less(chance)
	assert_float(float(Tactics.surprise_odds(far).chance)).is_less(chance)
	assert_float(float(Tactics.surprise_odds(watched).chance)).is_less(chance)
	assert_float(float(Tactics.surprise_odds(wary).chance)).is_less(chance)
	assert_float(float(Tactics.surprise_odds(woods).chance)).is_greater(chance)
	# Seventeen, two days out, against forty at war with us: about 1 in 3.
	assert_str(Tactics.chance_words(float(Tactics.surprise_odds(wary).chance))).is_equal("about 1 in 3")
	assert_str(Tactics.chance_words(0.5)).is_equal("about even")
	# A general never chooses a night attack on his own.
	assert_bool(Tactics.available_ids({"known":[],"profile":{"troops":17},"role":"attacker"},{"kind":"field","terrain":1.0}).has("night_attack")).is_false()


func test_a_night_attack_is_rolled_once_at_the_stated_chance_and_hits_hard_when_unseen()->void:
	var plan:={"attacker":{"id":"head_on","profile":{},"options":["head_on"],"since":0},"defender":{"id":"ambush","profile":{},"options":["head_on","ambush"],"since":0}}
	var unseen:=Tactics.night_approach(plan,"attacker",1.0,7)
	assert_str(String(unseen.attacker.id)).is_equal("night_attack")
	assert_bool(bool(unseen.attacker.surprise.unseen)).is_true()
	# Caught asleep, they have no time for anything clever.
	assert_str(String(unseen.defender.id)).is_equal("head_on")
	var seen:=Tactics.night_approach(plan,"attacker",0.0,7)
	assert_str(String(seen.attacker.id)).is_equal("night_attack_seen")
	assert_str(String(seen.defender.id)).is_equal("ambush")
	# Unseen: the first exchange falls far harder on them than on us.
	var first:=Tactics.round_effects(unseen,1,0.5,0.7,0.7)
	assert_float(float(first.defender)).is_greater(float(first.attacker)*2.0)
	assert_str(String(first.event)).is_equal("We fell on them while they slept.")
	# Seen: the dark costs the attackers.
	var met:=Tactics.round_effects(seen,1,0.5,0.7,0.7)
	assert_float(float(met.attacker)).is_greater(1.0)
	# The same seed gives the same roll: the record never rolls again.
	assert_dict(Tactics.night_approach(plan,"attacker",0.4,11)).is_equal(Tactics.night_approach(plan,"attacker",0.4,11))


func test_the_report_says_whether_they_were_seen_and_what_the_chance_was()->void:
	var record:={"home_side":"attacker","attacker":{"name":"Rovik's band","initial_troops":17,"remaining_troops":15,"morale":0.7,"commander":{"name":"Rovik Longstride"}},
		"defender":{"name":"Esurai band","initial_troops":40,"remaining_troops":10,"morale":0.1},"threat":{"source_name":"Esurai","field_encounter":true},
		"termination":{"type":"rout","captor":"Rovik's band","defeated":"Esurai band"},"outcome":"attacker_victory","rounds":[{"attacker_losses":2,"defender_losses":30}],
		"tactics":{"attacker":{"id":"night_attack","surprise":{"chance":0.32,"unseen":true}},"defender":{"id":"head_on"}},"seed":3,"day":int(GameState.elapsed_days)}
	var account:=Account.build(record,{"stage":"hearth"})
	assert_str(String(account.tactics.ours)).contains("We reached them in the dark unseen; the chance of that had been about 1 in 3.")
	assert_str(String(account.tactics.ours)).starts_with("We crept up on them in the dark.")

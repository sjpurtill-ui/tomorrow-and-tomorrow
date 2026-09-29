extends GdUnitTestSuite
## The battle report tells the user what happened, plainly and truthfully.
## The user's first attack (20 levies against Tsaren, of the Esurai) came back
## as "Attacker Victory at the field contact against Esurai. Our force: 15
## remaining; 0 lost or removed from the field; morale 52%." These tests pin:
## - every fighter is accounted for (sent = present + killed + wounded +
##   captured + fled + detached + earlier fights);
## - the report for a victory at the ditch, a defeat and a town taken;
## - the "what happens next" line follows the real operation state;
## - a beaten band cannot be "fought" again with no exchanges;
## - the replay reads the recorded rounds and never resolves them again;
## - no jargon reaches the player.

const Account:=preload("res://scripts/battle_account.gd")
const ReportPanel:=preload("res://scripts/hud/battle_report_panel.gd")
const Record:=preload("res://scripts/battle_record.gd")
const Route:=preload("res://scripts/army_land_route.gd")

const JARGON:=["Attacker Victory","Defender Victory","attacker_victory","field contact","FIELD STAFF","morale ","%","remaining;","lost or removed","offensive operation","LEVY BAND","_"]

var _processing:Dictionary={}
var city_id:=""
var civ_id:=""
var city:=Vector2.ZERO

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

func _round(n:int,ours:Array,theirs:Array,label:="Sustained combat",event:="No decisive local event.",our_morale:=0.8,their_morale:=0.7)->Dictionary:
	## ours/theirs: [killed, wounded, fled]
	var ol:=int(ours[0])+int(ours[1])+int(ours[2]); var tl:=int(theirs[0])+int(theirs[1])+int(theirs[2])
	return {"round":n,"intensity":label,"event":event,"tactic_event":"",
		"attacker_losses":ol,"defender_losses":tl,"attacker_morale":our_morale,"defender_morale":their_morale,
		"attacker_casualties":{"killed":ours[0],"wounded":ours[1],"scattered":ours[2]},
		"defender_casualties":{"killed":theirs[0],"wounded":theirs[1],"scattered":theirs[2]},
		"attacker_cohort_losses":[ol],"defender_cohort_losses":[tl]}

func _ditch_battle()->Dictionary:
	## Rovik's 20 levies against five Esurai behind a ditch before Tsaren.
	var rounds:=[_round(1,[0,1,0],[0,0,1],"Skirmishing"),_round(2,[1,1,0],[1,0,0]),_round(3,[0,0,1],[0,1,0],"Close engagement","",0.66,0.3)]
	return {"seed":4242,"day":34826,"home_side":"attacker","home_force_kind":"field_army","home_force_id":1,"outcome":"attacker_victory",
		"campaign_mode":"offensive","field_encounter":false,"target_region_id":"civ_01_region_05","target_region_name":"Tsaren",
		"threat":{"source_name":"Esurai","source_civ_id":"civ_01","target_region_name":"Tsaren"},
		"attacker":{"name":"LEVY BAND 1","initial_troops":20,"remaining_troops":16,"morale":0.66,"commander":{"name":"Rovik Longstride","figure_id":"figure_x"}},
		"defender":{"name":"Tsaren defenders","initial_troops":5,"remaining_troops":2,"morale":0.3,"commander":{"name":"Masu of Ashbank"}},
		"rounds":rounds,"termination":{"type":"withdrawal","captor":"LEVY BAND 1","defeated":"Tsaren defenders","prisoners":1,"commander_fate":"escaped"},
		"tactics":{"attacker":{"id":"head_on"},"defender":{"id":"fortified_camp"}},"strategic_outcome":{}}

func _state(army_troops:int,extra:Dictionary={})->Dictionary:
	var state:={"stage":"hearth","today":34826,"army":{"troops":army_troops},"operation":{"sent":20,"day":34800}}
	state.merge(extra,true)
	return state

func _balanced(ours:Dictionary)->bool:
	var in_fight:=int(ours.killed)+int(ours.wounded)+int(ours.fled)+int(ours.get("unsorted",0))+int(ours.captured)+int(ours.detached)+int(ours.present)
	return in_fight==int(ours.in_fight) and int(ours.sent)==int(ours.in_fight)+int(ours.earlier)+int(ours.elsewhere)

func _assert_plain(text:String)->void:
	for word in JARGON:
		assert_bool(text.contains(word)).override_failure_message("Jargon '%s' in: %s" % [word,text]).is_false()
	# No shouted words: only kickers are capitals, never report prose.
	var shout:=RegEx.new(); shout.compile("\\b[A-Z]{4,}\\b")
	assert_object(shout.search(text)).override_failure_message("Capitals in: "+text).is_null()

# ---------------------------------------------------------------------------
# Pure account
# ---------------------------------------------------------------------------

func test_victory_at_the_ditch_reads_plainly_and_balances()->void:
	var account:=Account.build(_ditch_battle(),_state(16))
	assert_str(String(account.headline)).is_equal("Rovik's band drove the Esurai from the ditch before Tsaren.")
	var ours:Dictionary=account.ours
	assert_int(int(ours.in_fight)).is_equal(20)
	assert_int(int(ours.killed)).is_equal(1)
	assert_int(int(ours.wounded)).is_equal(2)
	assert_int(int(ours.fled)).is_equal(1)
	assert_int(int(ours.present)).is_equal(16)
	assert_bool(_balanced(ours)).is_true()
	assert_str(String(ours.morale_words)).is_equal("steady")
	assert_str(String(account.tactics.ours)).is_equal("We met them head-on.")
	assert_str(String(account.tactics.theirs)).is_equal("They fought from behind a ditch and stakes.")
	# Their side is what we saw: five, counted one by one, one taken.
	assert_bool(bool(account.theirs.exact)).is_true()
	assert_int(int(account.theirs.seen_low)).is_equal(5)
	assert_int(int(account.theirs.taken)).is_equal(1)
	assert_str(String(account.now)).contains("they still hold the town; the gate is shut")
	assert_str(String(account.next)).contains("waits outside Tsaren for your word")
	assert_array(account.phases).is_not_empty()
	assert_str(String(account.phases[0])).starts_with("In the first exchange there was only skirmishing")
	var labels:Array=[]
	for action:Dictionary in account.actions: labels.append(String(action.label))
	assert_array(labels).contains_exactly(["Watch the battle","Talk to Rovik","Continue"])
	_assert_plain(Account.text(account))

func test_defeat_reports_captives_and_the_real_state()->void:
	var record:=_ditch_battle()
	record.outcome="defender_victory"
	record.attacker.remaining_troops=9; record.attacker.morale=0.12
	record.rounds=[_round(1,[2,3,1],[0,1,0]),_round(2,[1,2,2],[0,0,0],"Violent crisis","Hill Guard catches the assault in a killing ground.",0.12,0.8)]
	record.termination={"type":"pursuit","captor":"Tsaren defenders","defeated":"LEVY BAND 1","prisoners":2,"commander_fate":"escaped"}
	var account:=Account.build(record,_state(7))
	assert_str(String(account.kind)).is_equal("lost")
	assert_str(String(account.headline)).is_equal("The Esurai threw back Rovik's band before Tsaren.")
	var ours:Dictionary=account.ours
	assert_int(int(ours.captured)).is_equal(2)
	assert_int(int(ours.present)).is_equal(7)
	assert_bool(_balanced(ours)).is_true()
	assert_str(String(ours.morale_words)).is_equal("broken")
	assert_str(String(account.now)).contains("is beaten and has pulled back")
	assert_str(" ".join(PackedStringArray(account.phases))).contains("In the second exchange the Esurai caught the attack in a killing ground.")
	_assert_plain(Account.text(account))

func test_town_taken_says_who_holds_it_and_asks_what_next()->void:
	var record:=_ditch_battle()
	record.strategic_outcome={"region_captured":true}
	record.detached=12
	var account:=Account.build(record,_state(4,{"garrison":{"troops":12}}))
	assert_str(String(account.kind)).is_equal("taken")
	assert_str(String(account.headline)).is_equal("Rovik's band took Tsaren.")
	assert_str(String(account.now)).starts_with("Tsaren is ours. Rovik left twelve fighters to hold it.")
	assert_str(String(account.next)).contains("What becomes of Tsaren and its people is for you to say")
	var ours:Dictionary=account.ours
	assert_int(int(ours.detached)).is_equal(12)
	assert_int(int(ours.present)).is_equal(4)
	assert_bool(_balanced(ours)).is_true()
	_assert_plain(Account.text(account))

func test_the_band_that_fought_is_explained_against_the_band_that_set_out()->void:
	## The user's puzzle: twenty set out, fifteen fought, the report said
	## "15 remaining; 0 lost". Earlier fights now explain the difference.
	var record:=_ditch_battle()
	record.attacker.initial_troops=15; record.attacker.remaining_troops=15
	record.rounds=[]
	record.defender.initial_troops=4
	var account:=Account.build(record,_state(15,{"earlier":{"killed":1,"wounded":2,"fled":2,"captured":0,"detached":0,"fights":1}}))
	assert_str(String(account.kind)).is_equal("uncontested")
	assert_str(String(account.headline)).is_equal("The Esurai did not stand: Rovik's band found them already scattered before Tsaren.")
	assert_bool(_balanced(account.ours)).is_true()
	assert_int(int(account.ours.elsewhere)).is_equal(0)
	assert_str(Account.sent_line(account.ours)).is_equal("Of the 20 who set out, five were lost or hurt in the earlier fight.")
	# Nothing was fought, so there is nothing to watch.
	for action:Dictionary in account.actions: assert_str(String(action.id)).is_not_equal("watch")
	_assert_plain(Account.text(account))

func test_what_happens_next_follows_the_operation()->void:
	var record:=_ditch_battle()
	record.field_encounter=true; record.target_region_name="the field contact"; record.target_region_id=""
	var marching:=Account.build(record,_state(16,{"marching_to":{"name":"Tsaren","days":3,"kind":"attack"},"near":"Tsaren"}))
	assert_str(String(marching.headline)).is_equal("Rovik's band drove the Esurai from the ditch near Tsaren.")
	assert_str(String(marching.now)).starts_with("Rovik's band goes on toward Tsaren with 16 fighters, steady.")
	assert_str(String(marching.next)).is_equal("Rovik means to attack it on arrival, about three days from now.")
	var besieging:=Account.build(_ditch_battle(),_state(16,{"siege":{"days":3,"target_name":"Tsaren"}}))
	assert_str(String(besieging.now)).is_equal("Day 3 of the siege of Tsaren.")
	var going_home:=Account.build(_ditch_battle(),_state(16,{"marching_to":{"name":"home","days":5,"kind":"home"}}))
	assert_str(String(going_home.now)).starts_with("Rovik's band is on the road home")
	var again:=Account.build(_ditch_battle(),_state(16,{"engaged_again":true}))
	assert_str(String(again.now)).is_equal("Rovik's band is fighting again already.")
	var captives:=Account.build(_ditch_battle(),_state(16,{"aftermath_pending":true}))
	assert_str(String(captives.actions[-1].label)).is_equal("Decide the captives")
	for account in [marching,besieging,going_home,again,captives]: _assert_plain(Account.text(account))

func test_morale_has_words_not_numbers()->void:
	assert_str(Account.morale_words(0.52)).is_equal("shaken but holding")
	assert_str(Account.morale_words(0.9)).is_equal("in good heart")
	assert_str(Account.morale_words(0.1)).is_equal("broken")

# ---------------------------------------------------------------------------
# Real campaign: accounting and the phantom battles
# ---------------------------------------------------------------------------

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
	GameState.resource_stockpiles["Food"]=1000000.0
	GameState.elapsed_days=88*365
	Route.clear_cache()
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ["name"]="Esurai"
	civ_id=String(civ.id)
	var relation:Dictionary=civ.player_relation
	relation.contact_level=2; relation.home_location_known=true
	var region:Dictionary=civ.strategic_regions[CivilizationSystem._frontline_region_index(civ)]
	region["name"]="Tsaren"
	city_id=String(region.id)
	CivilizationSystem.city_intelligence.publish("player",CivilizationSystem.city_intelligence.capture("player",city_id,.8,int(GameState.elapsed_days),"scout report","test"),int(GameState.elapsed_days))
	city=CivilizationSystem.player_world_origin+Vector2(-20.0,8.0)
	CivilizationSystem.city_intelligence.records.player[city_id]["position"]={"x":city.x,"z":city.y}
	CivilizationSystem.set_scout_geography_authority(Callable(self,"_land"))

func _land(_p:Vector2)->bool:
	return true

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
	for node:Node in _processing: node.set_process(bool(_processing[node]))

func _army_at_the_town(count:int)->int:
	MilitaryCampaign.raise_recruits(count)
	MilitaryCampaign.start_training("levy","improvised",count)
	MilitaryCampaign._complete_training(MilitaryCampaign.training_queue[0].duplicate(true))
	MilitaryCampaign.training_queue.clear()
	var made:=MilitaryCampaign.create_field_army(count)
	var army_id:=int((made.army as Dictionary).army_id)
	var index:=MilitaryCampaign._field_army_index(army_id)
	MilitaryCampaign.field_armies[index]["position"]={"x":city.x+0.2,"z":city.y}
	MilitaryCampaign.field_armies[index]["status"]="stationed"
	return army_id

func _fight_to_the_end()->Dictionary:
	var guard:=0
	while not MilitaryCampaign.active_engagement.is_empty() and guard<40:
		MilitaryCampaign.active_engagement.erase("awaiting_player_view")
		MilitaryCampaign.advance_engagement("hold"); guard+=1
	return MilitaryCampaign.battle_history[0] if not MilitaryCampaign.battle_history.is_empty() else {}

func test_a_real_town_attack_accounts_for_every_fighter()->void:
	var army_id:=_army_at_the_town(20)
	var order:=MilitaryCampaign.order_city_operation(army_id,civ_id,city_id)
	assert_bool(order.has("error")).override_failure_message(str(order)).is_false()
	var index:=MilitaryCampaign._field_army_index(army_id)
	assert_str(String(MilitaryCampaign.field_armies[index].get("location_name",""))).is_equal("Tsaren")
	assert_int(int((MilitaryCampaign.field_armies[index].get("operation",{}) as Dictionary).get("sent",0))).is_equal(20)
	var record:=_fight_to_the_end()
	assert_dict(record).is_not_empty()
	assert_bool(record.has("detached")).is_true()
	var account:=Account.build(record,Account.gather(record))
	var ours:Dictionary=account.ours
	assert_bool(_balanced(ours)).override_failure_message(str(ours)).is_true()
	assert_int(int(ours.sent)).is_equal(20)
	# What the report says is still with the band is what the army holds.
	var still:=MilitaryCampaign._field_army_index(army_id)
	var troops:=int(MilitaryCampaign.field_armies[still].get("troops",0)) if still>=0 else 0
	assert_int(int(ours.present)).is_equal(troops)
	# Soldiers left as a garrison are the town's occupation force.
	var garrison:=MilitaryCampaign.occupation_force_for_region(civ_id,city_id)
	assert_int(int(ours.detached)).is_equal(int(garrison.get("troops",0)))
	if String(account.kind)=="taken": assert_str(String(account.now)).starts_with("Tsaren is ours.")
	_assert_plain(Account.text(account))
	# The council hears the same plain account.
	var matter:Dictionary={}
	for m:Dictionary in GameState.council_inbox:
		if int(m.get("battle_seed",-1))==int(record.seed): matter=m
	assert_str(String(matter.get("text",""))).is_equal(Account.text(account))

## The user's Isolo: five levies standing at a town with nobody under arms.
## It falls the day they go in. Before, it became a battle nobody fought
## ("neither side is giving ground"), the band stuck "in battle" and deaf to
## orders; and the report said their side "Had no".
func test_an_undefended_town_falls_at_once_and_is_told_plainly()->void:
	var army_id:=_army_at_the_town(5)
	var nobody:Dictionary=MilitaryCampaign.simulator.create_formation_force("Tsaren watch",[],0.6,0.6)
	nobody["commander"]=MilitaryCampaign.simulator.create_commander("Masu of Ashbank",0.5,0.5,0.5,0.5)
	MilitaryCampaign.active_threat={"id":"t0","title":"Campaign for Tsaren","incident_kind":"campaign","campaign_mode":"offensive","source_civ_id":civ_id,"source_name":"Esurai",
		"field_encounter":false,"formation_id":"","target_region_id":city_id,"target_region_name":"Tsaren","field_army_id":army_id,"enemy_force":nobody,"terrain_defense":1.05,"seed":17,"deadline_day":99999}
	var result:=MilitaryCampaign.begin_threat_engagement()
	assert_bool(result.has("error")).override_failure_message(str(result)).is_false()
	# Settled the day it began: no battle left standing, the band free for orders.
	assert_dict(MilitaryCampaign.active_engagement).is_empty()
	assert_bool(MilitaryCampaign._army_in_battle(army_id)).is_false()
	var record:Dictionary=MilitaryCampaign.battle_history[0]
	assert_int(int((record.defender as Dictionary).initial_troops)).is_equal(0)
	assert_str(String(record.outcome)).is_equal("attacker_victory")
	var account:=Account.build(record,Account.gather(record))
	var told:=Account.text(account)
	assert_str(told).not_contains("giving ground")
	if String(account.kind)=="taken":
		assert_str(String(account.headline)).contains("nobody stood to defend it")
		assert_array(account.phases).is_equal(["There was nobody under arms to meet us."])
	_assert_plain(told)
	# Their side is one plain row, never "Had no" beside "Killed: none".
	var panel:=ReportPanel.new()
	panel.account=account
	assert_array(panel._their_rows()).is_equal([["Stood to fight","nobody",true]])
	assert_str(panel._their_note()).not_contains("Few enough to count")
	panel.free()


## A fight won before a town too few or too hungry to hold says why, with
## the engine's own numbers (siege_recovery.gd capture_capacity).
func test_a_town_not_held_says_why_with_the_numbers()->void:
	var short:=Account.hold_shortfall({"message":"The attackers won the battle, but their 5 survivors provide 1.6 effective personnel; holding this city needs 3. Your city remains independent despite the defeat."})
	assert_int(int(short.troops)).is_equal(5)
	assert_float(float(short.effective)).is_equal_approx(1.6,0.01)
	assert_int(int(short.required)).is_equal(3)
	assert_str(Account.hold_words(short)).is_equal("our five are hungry and worn: they count for about one at holding a town, and it needs three,")
	assert_dict(Account.hold_shortfall({"message":"The city is occupied."})).is_empty()
	var record:=_ditch_battle()
	record.strategic_outcome={"region_captured":false,"message":"The attackers won the battle, but their 16 survivors provide 3.2 effective personnel; holding this city needs 7. Your city remains independent despite the defeat."}
	var account:=Account.build(record,_state(16))
	assert_str(String(account.now)).starts_with("We won the fight at Tsaren, but our 16 are hungry and worn")
	assert_str(String(account.now)).contains("it needs seven")
	assert_str(String(account.next)).contains("Send more fighters")
	_assert_plain(Account.text(account))


func test_a_broken_band_cannot_be_fought_again_with_no_exchanges()->void:
	## The "waves": a beaten band with its morale gone was re-engaged and
	## each time "defeated" with no blow struck and nothing lost.
	var army_id:=_army_at_the_town(20)
	var broken:Dictionary=MilitaryCampaign.simulator.create_formation_force("Esurai band",[{"unit":"levy","weapon":"improvised","count":4,"equipment":4}],0.1,0.3)
	MilitaryCampaign.active_threat={"id":"contact","title":"x","incident_kind":"campaign","campaign_mode":"offensive","source_civ_id":civ_id,"source_name":"Esurai","field_encounter":true,"formation_id":"f1",
		"target_region_id":"","target_region_name":"the field contact","field_army_id":army_id,"enemy_force":broken,"terrain_defense":1.04,"seed":7,"deadline_day":99999,"target_position":{"x":city.x,"z":city.y}}
	var before:=MilitaryCampaign.battle_history.size()
	var result:=MilitaryCampaign.begin_threat_engagement()
	assert_bool(bool(result.get("nobody_to_fight",false))).is_true()
	assert_dict(MilitaryCampaign.active_engagement).is_empty()
	assert_dict(MilitaryCampaign.active_threat).is_empty()
	assert_int(MilitaryCampaign.battle_history.size()).is_equal(before)

# ---------------------------------------------------------------------------
# Replay: recorded rounds, never resolved again
# ---------------------------------------------------------------------------

func test_replay_reads_recorded_rounds_without_resolving_again()->void:
	var army_id:=_army_at_the_town(20)
	MilitaryCampaign.order_city_operation(army_id,civ_id,city_id)
	var record:=_fight_to_the_end()
	var history_before:=JSON.stringify(MilitaryCampaign.battle_history)
	var view:=Record.view(record,{"stage":"hearth","left_name":"Rovik's band","right_name":"the Esurai"})
	# The start is everyone drawn up; the phases end where the record ends.
	var s:=Account.sides(record)
	var start:=0
	for plate in view.start.left.front+view.start.left.rear: start+=int(plate.men)
	assert_int(start).is_equal(int((record[s.home] as Dictionary).initial_troops))
	assert_int(int(view.sides.left.totals.went_in)).is_equal(int((record[s.home] as Dictionary).initial_troops))
	var shown_rounds:=0
	for phase in view.phases: shown_rounds+=int(phase.to)-int(phase.from)+1
	assert_int(shown_rounds).is_equal((record.rounds as Array).size())
	for phase in view.phases:
		for line in phase.events: _assert_plain(String(line))
	# Replaying changes nothing in the campaign.
	assert_str(JSON.stringify(MilitaryCampaign.battle_history)).is_equal(history_before)
	assert_dict(MilitaryCampaign.active_engagement).is_empty()

func test_report_panel_shows_the_account_and_three_plain_actions()->void:
	var army_id:=_army_at_the_town(20)
	MilitaryCampaign.order_city_operation(army_id,civ_id,city_id)
	var record:=_fight_to_the_end()
	var host:=Node.new(); host.set("game_speed",0.0); add_child(host)
	var panel:Control=ReportPanel.open(host,int(record.seed))
	await get_tree().process_frame
	assert_object(panel).is_not_null()
	var headline:Label=panel.find_child("Headline",true,false)
	assert_str(headline.text).is_equal(String(panel.account.headline))
	_assert_plain(headline.text)
	var labels:Array=[]
	for id in panel.buttons: labels.append((panel.buttons[id] as Button).text)
	assert_int(labels.size()).is_less_equal(3)
	for text in labels: _assert_plain(String(text))
	panel._act("continue")
	await get_tree().process_frame
	assert_bool(host.has_meta(ReportPanel.META)).is_false()
	host.queue_free()

# ---------------------------------------------------------------------------
# War planning, the war chart and the army card
# ---------------------------------------------------------------------------

func test_war_planning_speaks_plainly_and_shows_the_last_fight()->void:
	var army_id:=_army_at_the_town(20)
	MilitaryCampaign.order_city_operation(army_id,civ_id,city_id)
	_fight_to_the_end()
	MilitaryCampaign.pending_aftermath.clear()
	var content:RefCounted=load("res://scripts/hud/content/dock_detail_war_planning.gd").new(null,null)
	var tab:Dictionary=content.tab(0)
	var text:=JSON.stringify(tab.get("kpis",[]))+JSON.stringify(tab.get("brief",{}))
	for block:Dictionary in tab.get("blocks",[]):
		text+=String(block.get("heading",""))+String(block.get("text",""))
		for item:Dictionary in block.get("items",[]): text+=String(item.get("label",""))+String(item.get("name",""))+String(item.get("sub",""))
	for word in ["Mercy 0","Fear 0","Grievance","PRAGMATIC","BALANCED","\"none\"","prisoners","REPUTATION"]:
		assert_bool(text.contains(word)).override_failure_message("War planning still says '%s'" % word).is_false()
	assert_str(text).contains("THE LAST FIGHT")
	assert_str(text).contains("Watch the battle")

func test_a_finished_fight_stays_on_the_war_chart_for_days()->void:
	var Overlay:=preload("res://scripts/hud/war_front_overlay.gd")
	var record:=_ditch_battle()
	assert_array(Overlay.recent_battles([record],34826+3)).has_size(1)
	assert_array(Overlay.recent_battles([record],34826+Overlay.RECENT_BATTLE_DAYS+1)).is_empty()

func test_army_card_says_what_the_army_is_doing()->void:
	var army_id:=_army_at_the_town(20)
	var index:=MilitaryCampaign._field_army_index(army_id)
	MilitaryCampaign.field_armies[index]["position"]={"x":city.x+15.0,"z":city.y}
	var order:=MilitaryCampaign.order_city_operation(army_id,civ_id,city_id)
	assert_bool(bool(order.get("queued",false))).override_failure_message(str(order)).is_true()
	index=MilitaryCampaign._field_army_index(army_id)
	var words:=Account.doing(MilitaryCampaign.field_armies[index])
	assert_str(words).starts_with("marching to attack Tsaren")
	_assert_plain(words)

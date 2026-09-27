extends GdUnitTestSuite
## Battles scale with the odds (user: "I put 20 soldiers up against 2, and it
## took 3 rounds and quite a while ... They're just two dots, basically, and
## they should be ripped to pieces almost instantly.").
## - At about five to one, or a handful against three times its number, the
##   small side is overrun in one exchange, the same day, and the big side
##   loses almost nobody (a handful may be hurt; no superhumans either way).
## - Comparable forces still fight over several exchanges.
## - The report tells it in one short beat.
## - A tiny party gets no front, face-off or battle line on the map, and no
##   ground band in the battle view.

const Sim:=preload("res://scripts/combat_simulator.gd")
const Account:=preload("res://scripts/battle_account.gd")
const Replay:=preload("res://scripts/battle_replay.gd")
const Model:=preload("res://scripts/war_front_model.gd")
const Overlay:=preload("res://scripts/hud/war_front_overlay.gd")
const Front:=preload("res://scripts/army_front_visual.gd")

var _processing:Dictionary={}
var civ_id:=""


func _band(sim:CombatSimulator,name:String,count:int,morale:=0.7,readiness:=0.6)->Dictionary:
	var force:=sim.create_formation_force(name,[{"unit":"levy","weapon":"improvised","count":count,"equipment":count,"training":0.4}],morale,readiness)
	force["commander"]=sim.create_commander(name+" leader",0.55,0.55,0.5,0.6)
	return force


# ---------------------------------------------------------------------------
# The resolver
# ---------------------------------------------------------------------------

func test_twenty_against_two_is_one_exchange_with_almost_no_loss()->void:
	var sim:=Sim.new()
	var our_losses:=0
	var trials:=200
	for seed in trials:
		var result:=sim.simulate(_band(sim,"Ours",20),_band(sim,"Theirs",2),{"seed":1000+seed,"max_rounds":1})
		assert_str(String(result.outcome)).is_equal("attacker_victory")
		assert_int(int(result.round_count)).is_equal(1)
		assert_str(String((result.termination as Dictionary).type)).is_equal("overrun")
		# Nobody of theirs is left standing to fight on.
		assert_bool(bool((result.defender as Dictionary).routed)).is_true()
		var down:=int((result.defender as Dictionary).casualties)+int((result.termination as Dictionary).prisoners)+int((result.termination as Dictionary).get("scattered",0))
		assert_int(down).is_equal(2)
		our_losses+=int((result.attacker as Dictionary).casualties)
	# At most one of ours hurt on average; in practice far fewer.
	assert_float(float(our_losses)/float(trials)).is_less_equal(1.0)
	assert_float(float(our_losses)/float(trials)).is_less(0.5)


func test_defending_handful_is_overrun_too()->void:
	var sim:=Sim.new()
	var result:=sim.simulate(_band(sim,"Raiders",2),_band(sim,"Watch",20),{"seed":77,"terrain_defense":1.1})
	assert_str(String(result.outcome)).is_equal("defender_victory")
	assert_int(int(result.round_count)).is_equal(1)


func test_comparable_forces_still_fight_several_exchanges()->void:
	var sim:=Sim.new()
	var total:=0
	var overruns:=0
	var trials:=60
	for seed in trials:
		var result:=sim.simulate(_band(sim,"Ours",50),_band(sim,"Theirs",45),{"seed":5000+seed})
		total+=int(result.round_count)
		if String((result.termination as Dictionary).get("type",""))=="overrun": overruns+=1
	assert_int(overruns).is_equal(0)
	assert_float(float(total)/float(trials)).is_greater_equal(3.0)


func test_lopsided_fights_end_sooner_than_even_ones()->void:
	var sim:=Sim.new()
	var even:=0; var lopsided:=0
	for seed in 60:
		even+=int(sim.simulate(_band(sim,"Ours",60),_band(sim,"Theirs",60),{"seed":800+seed}).round_count)
		lopsided+=int(sim.simulate(_band(sim,"Ours",120),_band(sim,"Theirs",40),{"seed":800+seed}).round_count)
	assert_int(lopsided).is_less(even)


func test_a_large_overrun_stays_within_historical_bounds()->void:
	## 5000 against 800: the small host breaks at once, but it is not wiped
	## out to a man and the victors take real, modest losses.
	var sim:=Sim.new()
	var result:=sim.simulate(_band(sim,"Ours",5000),_band(sim,"Theirs",800),{"seed":42})
	assert_int(int(result.round_count)).is_equal(1)
	assert_str(String((result.termination as Dictionary).type)).is_equal("overrun")
	var theirs_down:=int((result.defender as Dictionary).casualties)
	assert_int(theirs_down).is_between(80,700)
	var ours_down:=int((result.attacker as Dictionary).casualties)
	assert_int(ours_down).is_between(1,250)


func test_a_few_well_armed_are_not_overrun_by_a_larger_rabble()->void:
	## Odds come from fighting power with the numbers to match, not headcount.
	assert_str(Sim.overrun_side(10.0,60.0,30,10)).is_equal("")
	assert_str(Sim.overrun_side(60.0,55.0,30,10)).is_equal("")
	assert_str(Sim.overrun_side(100.0,15.0,20,20)).is_equal("")
	assert_str(Sim.overrun_side(100.0,10.0,20,2)).is_equal("defender")
	assert_str(Sim.overrun_side(10.0,100.0,2,20)).is_equal("attacker")


# ---------------------------------------------------------------------------
# The campaign: settled the same day, one short report
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


func _army(count:int)->int:
	MilitaryCampaign.raise_recruits(count)
	MilitaryCampaign.start_training("levy","improvised",count)
	MilitaryCampaign._complete_training(MilitaryCampaign.training_queue[0].duplicate(true))
	MilitaryCampaign.training_queue.clear()
	var made:=MilitaryCampaign.create_field_army(count)
	var army_id:=int((made.army as Dictionary).army_id)
	var index:=MilitaryCampaign._field_army_index(army_id)
	var origin:Vector2=CivilizationSystem.player_world_origin
	MilitaryCampaign.field_armies[index]["position"]={"x":origin.x+5.0,"z":origin.y}
	MilitaryCampaign.field_armies[index]["status"]="stationed"
	return army_id


func _contact(army_id:int,enemy:Dictionary)->void:
	var origin:Vector2=CivilizationSystem.player_world_origin
	MilitaryCampaign.active_threat={"id":"contact","title":"x","incident_kind":"campaign","campaign_mode":"offensive","source_civ_id":civ_id,"source_name":"Esurai","field_encounter":true,"formation_id":"f1",
		"target_region_id":"","target_region_name":"the field contact","field_army_id":army_id,"enemy_force":enemy,"terrain_defense":1.0,"seed":11,"deadline_day":99999,"target_position":{"x":origin.x+5.2,"z":origin.y}}


func test_twenty_against_two_is_settled_the_day_contact_is_made()->void:
	var army_id:=_army(20)
	_contact(army_id,_band(MilitaryCampaign.simulator,"Esurai band",2,0.62,0.6))
	var today:=int(GameState.elapsed_days)
	var started:=[]
	var listener:=func(engagement:Dictionary)->void: started.append(engagement)
	MilitaryCampaign.battle_started.connect(listener)
	var result:=MilitaryCampaign.begin_threat_engagement()
	MilitaryCampaign.battle_started.disconnect(listener)
	assert_bool(result.has("error")).override_failure_message(str(result)).is_false()
	# No battle left running, no battle screen to sit through: the report is filed today.
	assert_dict(MilitaryCampaign.active_engagement).is_empty()
	assert_array(started).is_empty()
	assert_int(int(GameState.elapsed_days)).is_equal(today)
	assert_array(MilitaryCampaign.battle_history).is_not_empty()
	var record:Dictionary=MilitaryCampaign.battle_history[0]
	assert_int((record.rounds as Array).size()).is_equal(1)
	assert_int(int(record.get("day",-1))).is_equal(today)
	assert_int(int((record.attacker as Dictionary).casualties)).is_less_equal(1)
	# One short beat in the report and the replay.
	var account:=Account.build(record,{"stage":"hearth"})
	assert_str(String(account.kind)).is_equal("won")
	assert_str(String(account.headline)).contains("overran two of the Esurai")
	assert_int((account.phases as Array).size()).is_equal(1)
	assert_str(String(account.phases[0])).starts_with("It was over at once:")
	assert_str(String(account.duration)).is_equal("half an hour")
	var frames:=Replay.frames(record,"hearth")
	assert_int(frames.size()).is_equal(2)
	assert_str(String(frames[-1].caption)).contains("overran")
	assert_str(String(frames[-1].caption)).not_contains("lines fought")


func test_a_lopsided_day_of_fighting_does_not_drag_across_days()->void:
	## 60 against 20: not an overrun at the first blow, but decided within the
	## day it is fought, not one exchange a day for a week.
	var army_id:=_army(60)
	# Their 20 are armed and drilled like ours: three to one, man for man.
	var ours:Dictionary=MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(army_id)]
	var theirs:Dictionary=MilitaryCampaign.simulator.create_formation_force("Esurai band",[{"unit":"levy","weapon":"improvised","count":20,"equipment":0,"training":0.25}],float(ours.get("morale",0.5)),float(ours.get("readiness",0.12)))
	_contact(army_id,theirs)
	var result:=MilitaryCampaign.begin_threat_engagement()
	assert_bool(result.has("error")).override_failure_message(str(result)).is_false()
	var engagement:=MilitaryCampaign.active_engagement
	assert_dict(engagement).is_not_empty()
	var odds:float=MilitaryCampaign.simulator.odds_of(engagement.attacker,engagement.defender,1.0)
	assert_float(odds).override_failure_message("odds %.2f" % odds).is_between(2.5,5.0)
	var days:=0
	while not MilitaryCampaign.active_engagement.is_empty() and days<12:
		MilitaryCampaign.active_engagement.erase("awaiting_player_view")
		MilitaryCampaign.fight_engagement_day("hold"); days+=1
	assert_dict(MilitaryCampaign.active_engagement).is_empty()
	assert_int(days).is_less_equal(2)
	assert_str(String(MilitaryCampaign.battle_history[0].outcome)).is_equal("attacker_victory")


# ---------------------------------------------------------------------------
# The map and the battle view
# ---------------------------------------------------------------------------

func test_tiny_party_is_not_a_line_holder()->void:
	assert_bool(Model.tiny(2.0)).is_true()
	assert_bool(Model.tiny(40.0,3000.0)).is_true()
	assert_bool(Model.tiny(2500.0,3000.0)).is_false()
	assert_bool(Model.skirmish(20,2)).is_true()
	assert_bool(Model.skirmish(300,280)).is_false()


func test_tiny_party_gets_no_front_band()->void:
	var friendly:=[{"id":"1","army_id":1,"pos":Vector2(0,0),"strength":3000.0}]
	var party:=[{"id":"p","pos":Vector2(2.0,0.2),"strength":2.0,"low":2,"high":2,"age_days":0}]
	for mode in ["front","theatre"]:
		var built:=Overlay.compose({"mode":mode,"stage":"lettered","home":Vector2(-6,0),"friendly":friendly,"enemy":party})
		assert_array(built.fronts).override_failure_message(mode).is_empty()
		assert_array(built.pockets).is_empty()
	# A host against three scouts: no face-off line either.
	var host:=Overlay.compose({"mode":"host","stage":"lettered","home":Vector2(-6,0),"friendly":[{"id":"1","army_id":1,"pos":Vector2(0,0),"strength":400.0}],
		"enemy":[{"id":"s","pos":Vector2(1.2,0.4),"strength":3.0,"low":3,"high":3,"age_days":0}]})
	assert_array(host.faceoffs).is_empty()
	# The party is still marked, as a small band of its own.
	var theirs:=(host.marks as Array).filter(func(m:Dictionary)->bool: return String(m.side)=="theirs")
	assert_int(theirs.size()).is_equal(1)
	assert_int(int(theirs[0].troops)).is_equal(3)


func test_substantial_forces_still_get_their_front()->void:
	var friendly:=[{"id":"1","army_id":1,"pos":Vector2(0,0),"strength":3000.0}]
	var enemy:=[{"id":"a","pos":Vector2(6,0),"strength":2500.0,"low":2500,"high":2500,"age_days":0},{"id":"p","pos":Vector2(1.5,3.0),"strength":2.0,"low":2,"high":2,"age_days":0}]
	var built:=Overlay.compose({"mode":"front","stage":"lettered","home":Vector2(-6,0),"friendly":friendly,"enemy":enemy})
	assert_int((built.fronts as Array).size()).is_greater_equal(1)
	var host:=Overlay.compose({"mode":"host","stage":"lettered","home":Vector2(-6,0),"friendly":[{"id":"1","army_id":1,"pos":Vector2(0,0),"strength":400.0}],
		"enemy":[{"id":"h","pos":Vector2(1.2,0.4),"strength":350.0,"low":350,"high":350,"age_days":0}]})
	assert_array(host.faceoffs).is_not_empty()


func test_skirmish_clash_is_a_mark_not_two_lines()->void:
	var built:=Overlay.compose({"mode":"raid","stage":"hearth","home":Vector2.ZERO,"friendly":[{"id":"1","army_id":1,"pos":Vector2(4,1),"strength":20.0}],"enemy":[],
		"engagements":[{"pos":Vector2(4.3,1),"axis":Vector2.RIGHT,"ours":"head_on","theirs":"head_on","rounds":1,"army_id":1,"our_troops":20,"their_troops":2},
			{"pos":Vector2(9,1),"axis":Vector2.RIGHT,"ours":"head_on","theirs":"head_on","rounds":1,"army_id":2,"our_troops":40,"their_troops":35}]})
	assert_bool(bool(built.clashes[0].skirmish)).is_true()
	assert_bool(bool(built.clashes[1].skirmish)).is_false()


func test_a_handful_has_no_ground_band()->void:
	var two:={"troops":2,"formations":[{"id":1,"count":2,"unit":"levy"}]}
	var sections:=Front.layout(two,1.0)
	assert_int(sections.size()).is_equal(1)
	assert_bool(bool(sections[0].tiny)).is_true()
	var node:=Front.new()
	add_child(node)
	node.configure(two,Color.RED,1.0,0.0,true)
	assert_int(int(node.surface_node.get_meta("triangle_count"))).is_equal(0)
	node.configure({"troops":200,"formations":[{"id":1,"count":200,"unit":"levy"}]},Color.RED,1.0,0.0,true)
	assert_int(int(node.surface_node.get_meta("triangle_count"))).is_greater(0)
	node.queue_free()

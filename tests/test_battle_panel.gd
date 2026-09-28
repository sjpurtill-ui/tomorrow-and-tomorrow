extends GdUnitTestSuite
## The battle panel (hud/battle_panel.gd) and BattleView: every way into a
## battle lands on the panel; the panel reads plainly (12 px and up, only
## kickers in capitals, every number labelled), shows the line and the
## reserve block by block, steps through the phases of a finished battle,
## and never fights a battle again.

const Sim:=preload("res://scripts/combat_simulator.gd")
const Tactics:=preload("res://scripts/battle_tactics.gd")
const View:=preload("res://scripts/hud/battle_view.gd")

var _processing:Dictionary={}


func before_test()->void:
	if _processing.is_empty():
		for node:Node in [GameState,CivilizationSystem,MilitaryCampaign,ProgressionSystem]: _processing[node]=node.is_processing()
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(74017);GameState.civic_api_enabled=false
	MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	GameState.ensure_population_total(900)
	GameState.settlement_site_committed=true
	GameState.elapsed_days=88*365


func after_test()->void:
	GameState.elapsed_days=0
	MilitaryCampaign.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	GameState.reset_for_new_world(74017)
	WorldSimulation.clear()
	for node:Node in _processing: node.set_process(bool(_processing[node]))


func _force(sim:CombatSimulator,name:String,parts:Array,morale:=0.8)->Dictionary:
	var formations:Array=[]
	for part in parts:
		formations.append({"unit":String(part[0]),"weapon":String(part[1]),"count":int(part[2]),"equipment":int(part[2]),"training":0.7})
	var force:=sim.create_formation_force(name,formations,morale,0.8)
	force["commander"]=sim.create_commander(name+" Longstride",0.7,0.7,0.5,0.7)
	return force


func _big_record()->Dictionary:
	var sim:=Sim.new()
	var a:=_force(sim,"Rovik",[["rifle_infantry","service_rifle",34000],["machine_gun_company","machine_gun",3000],["field_artillery","field_gun",3000]])
	var d:=_force(sim,"Masu",[["rifle_infantry","service_rifle",30000],["machine_gun_company","machine_gun",2500],["field_artillery","field_gun",2500]],0.75)
	var known:=["metallic_cartridges","formation_drill","field_fortifications","automatic_actions","indirect_fire","military_staffs"]
	var plan:=Tactics.plan({"attacker":{"force":a,"known":known},"defender":{"force":d,"known":known}},{"kind":"field","terrain":1.0},4)
	var result:=sim.simulate(a,d,{"seed":8,"tactics":plan,"ground":{"kind":"open"}})
	result["home_side"]="attacker"
	result["day"]=int(GameState.elapsed_days)
	result["threat"]={"source_name":"Esurai","target_region_name":"Tsaren"}
	result["target_region_name"]="Tsaren"
	return result


func _host()->Node:
	var host:=Node.new(); host.set("game_speed",0.0)
	add_child(host)
	return host


func _labels(root:Node)->Array:
	return root.find_children("*","Label",true,false)


func _assert_readable(panel:Control)->void:
	var shout:=RegEx.new(); shout.compile("\\b[A-Z]{4,}\\b")
	for label:Label in _labels(panel):
		var size:=label.get_theme_font_size("font_size")
		assert_int(size).override_failure_message("%s at %d px" % [label.text,size]).is_greater_equal(12)
		# Only 12 px kickers may be in capitals.
		if size>12 and label.text.strip_edges()!="": assert_object(shout.search(label.text)).override_failure_message("Capitals in: "+label.text).is_null()
		for word in ["attacker_victory","_","NaN","null","cohesion","morale","frontage"]:
			assert_bool(label.text.contains(word)).override_failure_message("'%s' in: %s" % [word,label.text]).is_false()


func test_a_big_finished_battle_opens_on_its_result_and_steps_back()->void:
	var record:=_big_record()
	MilitaryCampaign.battle_history.push_front(record.duplicate(true))
	var before:=JSON.stringify(MilitaryCampaign.battle_history)
	var host:=_host()
	var panel:Control=View.open(int(record.seed),host)
	await get_tree().process_frame
	assert_object(panel).is_not_null()
	assert_bool(bool(panel.live)).is_false()
	var phases:=(panel.view.phases as Array).size()
	assert_int(int(panel.step)).is_equal(phases)
	assert_bool(bool(panel.view.skirmish)).is_false()
	var headline:Label=panel.find_child("Headline",true,false)
	assert_str(headline.text).is_equal(String(panel.view.phrase))
	# The line and the reserve: regiments in the line, the rest summed up.
	var plates:=panel.find_children("*","Control",true,false).filter(func(n:Node)->bool: return n.get_script()!=null and "data" in n)
	assert_int(plates.size()).is_greater(4)
	_assert_readable(panel)
	# Step back to the start and forward again: the campaign is untouched.
	panel._select(0)
	await get_tree().process_frame
	assert_int(int(panel.step)).is_equal(0)
	assert_str((panel.find_child("Headline",true,false) as Label).text).is_not_empty()
	panel._select(1)
	await get_tree().process_frame
	_assert_readable(panel)
	assert_str(JSON.stringify(MilitaryCampaign.battle_history)).is_equal(before)
	panel.close()
	await get_tree().process_frame
	assert_bool(host.has_meta(View.META)).is_false()
	host.queue_free()


func test_a_skirmish_is_a_card()->void:
	var sim:=Sim.new()
	var result:=sim.simulate(_force(sim,"Ours",[["levy","improvised",20]]),_force(sim,"Theirs",[["levy","improvised",2]]),{"seed":3})
	result["home_side"]="attacker"
	result["threat"]={"source_name":"Esurai"}
	var host:=_host()
	var panel:Control=View.open(result,host)
	await get_tree().process_frame
	assert_bool(bool(panel.view.skirmish)).is_true()
	assert_object(panel.find_child("Card",true,false)).is_not_null()
	assert_object(panel.find_child("Sheet",true,false)).is_null()
	_assert_readable(panel)
	panel.close()
	host.queue_free()


func test_live_battles_are_listed_and_followed_without_fighting()->void:
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("Home",[{"id":1,"unit":"line_infantry","weapon":"spear","count":300,"equipment":300}],1,1)
	MilitaryCampaign.active_threat={"seed":741,"name":"Invasion","enemy_force":MilitaryCampaign.simulator.create_formation_force("Invaders",[{"id":2,"unit":"line_infantry","weapon":"spear","count":280,"equipment":280}],1,1),"campaign_mode":"defensive","source_name":"Esurai"}
	var engagement:=MilitaryCampaign.begin_threat_engagement()
	assert_bool(engagement.has("error")).is_false()
	var listed:=View.list_now()
	assert_int(listed.size()).is_equal(1)
	var entry:Dictionary=listed[0]
	for key in ["id","x","z","sides","progress","status","day","place_name"]: assert_bool(entry.has(key)).override_failure_message(key).is_true()
	assert_str(String(entry.sides.a.civ_id)).is_equal("player")
	assert_int(int(entry.sides.a.troops)).is_greater(0)
	assert_float(float(entry.progress)).is_between(-1.0,1.0)
	# The map's battle marks open the panel on the engagement by its id.
	var before:=MilitaryCampaign.engagement_snapshot()
	MilitaryCommandUI.open_engagement(String(entry.id))
	await get_tree().process_frame
	var panel:Control=MilitaryCommandUI.battle_graphics
	assert_object(panel).is_not_null()
	assert_bool(bool(panel.live)).is_true()
	assert_str(String(panel.view.status)).is_equal("Drawn up, about to fight")
	assert_dict(MilitaryCampaign.engagement_snapshot()).is_equal(before)
	# A day passes: the panel follows the fight.
	MilitaryCampaign.fight_engagement_day("hold")
	panel.poll=1.0
	panel._process(0.1)
	if not MilitaryCampaign.active_engagement.is_empty():
		assert_str(String(panel.view.status)).starts_with("Fighting")
	_assert_readable(panel)
	panel.close()
	await get_tree().process_frame
	assert_bool(MilitaryCommandUI.battle_open()).is_false()


func test_every_way_in_lands_on_the_panel()->void:
	var record:=_big_record()
	MilitaryCampaign.battle_history.push_front(record.duplicate(true))
	# The old entry point (reports, Chronicle, war planning, the map's older marks).
	MilitaryCommandUI._open_battle_graphics(0,int(record.seed))
	await get_tree().process_frame
	var panel:Control=MilitaryCommandUI.battle_graphics
	assert_object(panel).is_not_null()
	assert_str(String(panel.get_script().resource_path)).is_equal("res://scripts/hud/battle_panel.gd")
	panel.close()
	await get_tree().process_frame
	# Nothing to show: nothing opens.
	assert_object(View.open("no such battle",_host())).is_null()

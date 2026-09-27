extends Node
## Captures of the battle report and the battle view for one recorded fight:
## Rovik's 20 levies meet an Esurai band behind a ditch and stakes on the way
## to Tsaren (the user's first attack, rebuilt as a fixture from the real
## resolver). Run only through tools/run_isolated_gpu_probe.ps1:
##   -- --shot=report|battle --out=<folder>
## Works on the old code too (the "before" plates): it uses the new report
## card and replay when they exist, and the old dialog otherwise.

var shot:="report"
var out:="res://artifacts/battle_clarity"
var civ_id:=""
var city_id:=""
var city:=Vector2.ZERO


func _ready()->void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="): shot=arg.trim_prefix("--shot=")
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	get_window().size=Vector2i(1600,900)
	var backdrop:=ColorRect.new(); backdrop.color=Color("56604a"); backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var layer:=CanvasLayer.new(); layer.layer=-5; add_child(layer); layer.add_child(backdrop)
	_setup()
	var seed:=_fight()
	await get_tree().process_frame
	if shot=="report": await _report(seed)
	else: await _battle(seed)
	print("BATTLE_CLARITY_CAPTURE_PASS ",shot)
	get_tree().quit(0)


func _setup()->void:
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(74017);GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world();FoodSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	GameState.ensure_population_total(160);GameState.housing_capacity=300
	GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	GameState.select_founding_focus("provision")
	GameState.settlement_name="Seanstone"
	GameState.resource_stockpiles["Food"]=100000.0
	GameState.elapsed_days=34826
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ["name"]="Esurai"; civ_id=String(civ.id)
	var relation:Dictionary=civ.player_relation
	relation.contact_level=2; relation.home_location_known=true
	var region:Dictionary=civ.strategic_regions[CivilizationSystem._frontline_region_index(civ)]
	region["name"]="Tsaren"; city_id=String(region.id)
	CivilizationSystem.city_intelligence.publish("player",CivilizationSystem.city_intelligence.capture("player",city_id,.8,int(GameState.elapsed_days),"scout report","capture"),int(GameState.elapsed_days))
	city=CivilizationSystem.player_world_origin+Vector2(-20.0,8.0)
	CivilizationSystem.city_intelligence.records.player[city_id]["position"]={"x":city.x,"z":city.y}


## The fight, from the real resolver: head-on against a ditch and stakes.
func _fight()->int:
	MilitaryCampaign.raise_recruits(20)
	MilitaryCampaign.start_training("levy","improvised",20)
	MilitaryCampaign._complete_training(MilitaryCampaign.training_queue[0].duplicate(true))
	MilitaryCampaign.training_queue.clear()
	var made:=MilitaryCampaign.create_field_army(20)
	var army_id:=int((made.army as Dictionary).army_id)
	var index:=MilitaryCampaign._field_army_index(army_id)
	var army:Dictionary=MilitaryCampaign.field_armies[index]
	army["commander"]=MilitaryCampaign.simulator.create_commander("Rovik Longstride",0.69,0.66,0.55,0.74)
	army["position"]={"x":city.x+3.0,"z":city.y+1.0}
	army["name"]="Host marching on Tsaren"
	MilitaryCampaign.field_armies[index]=army
	var plan:={"attacker":{"id":"head_on","profile":{},"shape":"clash"},"defender":{"id":"fortified_camp","profile":{},"shape":"camp"}}
	var chosen:Dictionary={}
	var fallback:Dictionary={}
	for attempt in 400:
		var theirs:Dictionary=MilitaryCampaign.simulator.create_formation_force("Esurai band",[{"unit":"levy","weapon":"improvised","count":6,"equipment":6,"training":0.4}],0.62,0.6)
		theirs["commander"]=MilitaryCampaign.simulator.create_commander("Masu of Ashbank",0.58,0.55,0.56,0.65)
		var result:Dictionary=MilitaryCampaign.simulator.simulate(MilitaryCampaign.field_armies[index].duplicate(true),theirs,{"seed":9100+attempt,"terrain_defense":1.04,"tactics":plan})
		if String(result.outcome)=="attacker_victory" and fallback.is_empty(): fallback=result
		if String(result.outcome)=="attacker_victory" and int(result.round_count)>=3:
			chosen=result; break
	if chosen.is_empty(): chosen=fallback
	print("FIXTURE seed=%d rounds=%d outcome=%s" % [int(chosen.get("seed",0)),int(chosen.get("round_count",0)),String(chosen.get("outcome",""))])
	var record:={"seed":int(chosen.seed),"outcome":String(chosen.outcome),"winner":String(chosen.winner),"round_count":int(chosen.round_count),"rounds":chosen.rounds,
		"attacker":chosen.attacker,"defender":chosen.defender,"home_side":"attacker","home_force_kind":"field_army","home_force_id":army_id,"campaign_mode":"offensive",
		"field_encounter":true,"formation_id":"","target_region_id":"","target_region_name":"the field contact",
		"threat":{"source_name":"Esurai","source_civ_id":civ_id,"field_encounter":true,"target_position":{"x":city.x+2.5,"z":city.y+1.0}},
		"terrain_defense":1.04,"termination":chosen.termination,"tactics":plan,"orders":{"retreated":false}}
	MilitaryCampaign._commit_campaign_battle(record)
	index=MilitaryCampaign._field_army_index(army_id)
	# Still on the road to Tsaren after the fight.
	MilitaryCampaign.field_armies[index]["city_operation"]={"civ_id":civ_id,"region_id":city_id,"besiege":false,"raid":false}
	MilitaryCampaign.field_armies[index]["status"]="moving"
	MilitaryCampaign.field_armies[index]["arrival_day"]=int(GameState.elapsed_days)+1
	MilitaryCampaign.field_armies[index]["operation"]={"objective":city_id,"sent":20,"day":34800}
	MilitaryCampaign.pending_aftermath.clear()
	return int(chosen.seed)


func _report(seed:int)->void:
	var panel_path:="res://scripts/hud/battle_report_panel.gd"
	if ResourceLoader.exists(panel_path):
		var host:=Node.new(); add_child(host)
		load(panel_path).open(host,seed)
	else:
		# main's dialog, exactly as local_terrain._show_military_attention builds it.
		var dialog:=ConfirmationDialog.new()
		dialog.theme=HudTokens.control_theme()
		dialog.title="BATTLE REPORT"
		dialog.dialog_text=MilitaryCampaign.battle_report_text(MilitaryCampaign.battle_history[0])
		dialog.min_size=Vector2i(650,260)
		dialog.ok_button_text="OPEN WAR PLANNING"
		dialog.cancel_button_text="STAY PAUSED"
		add_child(dialog)
		dialog.popup_centered()
	for i in 30: await get_tree().process_frame
	await _save("report")


func _battle(seed:int)->void:
	MilitaryCommandUI._open_battle_graphics(0,seed)
	var screen:Control=MilitaryCommandUI.battle_graphics
	var replaying:=screen!=null and "replay_only" in screen and bool(screen.get("replay_only"))
	for i in 20: await get_tree().process_frame
	await _wait(1.2)
	await _save("battle_drawn_up" if replaying else "battle")
	if not replaying: return
	await _wait(3.4)
	await _save("battle_exchange")
	var guard:=0.0
	while is_instance_valid(screen) and String(screen.get("phase"))!="ended" and guard<60.0:
		await _wait(0.5); guard+=0.5
	await _wait(0.6)
	await _save("battle_result")


func _wait(seconds:float)->void:
	await get_tree().create_timer(seconds).timeout


func _save(name:String)->void:
	await RenderingServer.frame_post_draw
	var path:=ProjectSettings.globalize_path(out.path_join(name+".png"))
	get_viewport().get_texture().get_image().save_png(path)
	print("SAVED ",path)

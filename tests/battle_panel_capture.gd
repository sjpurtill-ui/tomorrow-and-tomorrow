extends Node
## Captures of the battle panel (hud/battle_panel.gd) for review:
##   a  twenty against two: the skirmish card
##   b  about 120 against 90 in the first age, mid-fight
##   c  about 40,000 against 35,000 in the rifle age, mid-fight, reserves waiting
##   d  a finished battle stepped back to its middle phase
## Run through tools/run_isolated_gpu_probe.ps1 with -UserArguments "--out=DIR".
## Quits when done.

const View:=preload("res://scripts/hud/battle_view.gd")
const Tactics:=preload("res://scripts/battle_tactics.gd")

var out:="user://battle_panel_capture"
var game_speed:=0.0


func _set_game_speed(speed:float)->void:
	game_speed=speed


func _ready()->void:
	for arg in OS.get_cmdline_user_args():
		if String(arg).begins_with("--out="): out=String(arg).trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out) if out.begins_with("user://") or out.begins_with("res://") else out)
	var background:=ColorRect.new(); background.color=Color("6e7f3e"); background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var layer:=CanvasLayer.new(); layer.layer=-1; add_child(layer); layer.add_child(background)
	for node:Node in [GameState,CivilizationSystem,MilitaryCampaign]: node.set_process(false)
	GameState.reset_for_new_world(74017); GameState.civic_api_enabled=false
	CivilizationSystem.reset_for_new_world(); MilitaryCampaign.reset_for_new_world()
	GameState.ensure_population_total(900); GameState.settlement_site_committed=true
	GameState.settlement_name="Seanstone"
	GameState.elapsed_days=88*365
	await get_tree().process_frame
	await _skirmish()
	await _early()
	await _later()
	await _finished()
	print("BATTLE_PANEL_CAPTURE_DONE")
	get_tree().quit()


func _force(name:String,parts:Array,morale:=0.8,general:="")->Dictionary:
	var formations:Array=[]
	var id:=1
	for part in parts:
		formations.append({"id":id,"unit":String(part[0]),"weapon":String(part[1]),"count":int(part[2]),"authorized_count":int(part[2]),"equipment":int(part[2]),"training":0.7})
		id+=1
	var force:Dictionary=MilitaryCampaign.simulator.create_formation_force(name,formations,morale,0.8)
	force["commander"]=MilitaryCampaign.simulator.create_commander(general if general!="" else name,0.72,0.7,0.5,0.72)
	return force


## A defensive battle at home: our army against theirs, fought `exchanges` in.
func _home_battle(ours:Dictionary,theirs:Dictionary,exchanges:int,seed:int)->void:
	MilitaryCampaign.active_engagement.clear()
	MilitaryCampaign.home_army=ours
	MilitaryCampaign.active_threat={"id":"capture","seed":seed,"title":"x","incident_kind":"campaign","campaign_mode":"defensive","source_civ_id":"","source_name":"Esurai",
		"enemy_force":theirs,"terrain_defense":1.0,"deadline_day":99999,"discovered_day":int(GameState.elapsed_days)-1}
	var started:Dictionary=MilitaryCampaign.begin_threat_engagement(false)
	if started.has("error"): push_warning("CAPTURE could not start the battle: "+str(started.error))
	for exchange in exchanges:
		if MilitaryCampaign.active_engagement.is_empty(): break
		MilitaryCampaign.advance_engagement("hold")
	if MilitaryCampaign.active_engagement.is_empty(): push_warning("CAPTURE the battle ended before the capture")


func _open(target:Variant)->Control:
	var panel:=View.open(target,self)
	for i in 12: await get_tree().process_frame
	return panel


func _save(name:String)->void:
	for i in 4: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var path:=out.path_join(name+".png")
	var absolute:=ProjectSettings.globalize_path(path) if path.begins_with("user://") or path.begins_with("res://") else path
	get_viewport().get_texture().get_image().save_png(absolute)
	print("SAVED ",absolute)


func _close_all()->void:
	View.close_open(self)
	for i in 4: await get_tree().process_frame


func _skirmish()->void:
	GameState.known_discoveries=[]
	var ours:=_force("Rovik's band",[["levy","spear",20]],0.8,"Rovik Longstride")
	var theirs:=_force("Esurai scouts",[["levy","improvised",2]],0.6,"Masu")
	var result:Dictionary=MilitaryCampaign.simulator.simulate(ours,theirs,{"seed":5})
	result["home_side"]="attacker"; result["day"]=int(GameState.elapsed_days)
	result["threat"]={"source_name":"Esurai","field_encounter":true}
	result["id"]="skirmish"
	MilitaryCampaign._commit_campaign_battle(result)
	MilitaryCampaign.pending_aftermath.clear()
	await _open(int(result.seed))
	await _save("a_skirmish_20_v_2")
	await _close_all()


func _early()->void:
	GameState.known_discoveries=["hafted_weapons","bow_craft"]
	var ours:=_force("Rovik's band",[["levy","spear",90],["archer","bow",30]],0.8,"Rovik Longstride")
	var theirs:=_force("Esurai band",[["levy","improvised",70],["slinger","sling",20]],0.75,"Masu of Ashbank")
	_home_battle(ours,theirs,2,1117)
	await _open(String(MilitaryCampaign.active_engagement.get("id","")))
	await _save("b_early_120_v_90_mid_fight")
	await _close_all()


func _later()->void:
	GameState.known_discoveries=["writing","printing_process","metallic_cartridges","formation_drill","field_fortifications","automatic_actions","indirect_fire","military_staffs"]
	var ours:=_force("Home army",[["rifle_infantry","service_rifle",34000],["machine_gun_company","machine_gun",3000],["field_artillery","field_gun",3000]],0.85,"Rovik Longstride")
	var theirs:=_force("Esurai army",[["rifle_infantry","service_rifle",30000],["machine_gun_company","machine_gun",2500],["field_artillery","field_gun",2500]],0.8,"Masu of Ashbank")
	_home_battle(ours,theirs,5,2203)
	await _open(String(MilitaryCampaign.active_engagement.get("id","")))
	await _save("c_later_40000_v_35000_mid_fight")
	await _close_all()


func _finished()->void:
	GameState.known_discoveries=["writing","hafted_weapons","bow_craft","shield_wall","formation_drill","domesticated_mounts","bronze_weaponry"]
	var ours:=_force("Rovik's host",[["spearman","spear",5200],["archer","bow",900],["cavalry","lance",700]],0.82,"Rovik Longstride")
	var theirs:=_force("Esurai host",[["spearman","spear",5600],["slinger","sling",800]],0.78,"Masu of Ashbank")
	var known:=["hafted_weapons","bow_craft","shield_wall","formation_drill","domesticated_mounts","bronze_weaponry"]
	var plan:=Tactics.plan({"attacker":{"force":ours,"known":known},"defender":{"force":theirs,"known":known}},{"kind":"field","terrain":1.0},12)
	var result:Dictionary=MilitaryCampaign.simulator.simulate(ours,theirs,{"seed":31,"tactics":plan,"ground":{"kind":"ford"}})
	result["home_side"]="attacker"; result["day"]=int(GameState.elapsed_days)
	result["threat"]={"source_name":"Esurai","target_region_name":"Tsaren","field_encounter":true}
	result["ground"]={"kind":"ford","label":"a ford"}
	result["id"]="finished"
	MilitaryCampaign.battle_history.push_front(result)
	var panel:=await _open(int(result.seed))
	var phases:=(panel.view.phases as Array).size()
	panel._select(maxi(1,(phases+1)/2))
	for i in 6: await get_tree().process_frame
	await _save("d_finished_middle_phase")
	panel._select(phases)
	await _save("d_finished_result")
	await _close_all()

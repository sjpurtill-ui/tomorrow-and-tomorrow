extends Control
## TEST CAPTURE (not the game): a lopsided fight, 20 of ours against 2 of
## theirs, drawn the two ways the player sees it: the battle replay and the
## war map. Run only through tools/run_isolated_gpu_probe.ps1:
##   res://tests/battle_scale_capture.tscn -- --shot=battle|map --out=<dir>
## The battle is resolved by the real resolver; the map plates run the real
## war_front_overlay composition over a plain chart ground. It never writes
## a save and quits by itself.

const Overlay:=preload("res://scripts/hud/war_front_overlay.gd")

var shot:="battle"
var out:="res://artifacts/battle_scale"
var plates:Array=[]
var index:=-1
var current:Dictionary={}
var overlay:Control
var frames:=0


func _ready()->void:
	get_tree().create_timer(80.0).timeout.connect(func()->void: get_tree().quit(3))
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="): shot=arg.trim_prefix("--shot=")
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	if not out.begins_with("res://") and not out.is_absolute_path(): out=ProjectSettings.globalize_path("res://"+out)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	get_window().size=Vector2i(1600,900)
	if shot=="map":
		_map_plates()
		return
	var backdrop:=ColorRect.new(); backdrop.color=Color("56604a"); backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var layer:=CanvasLayer.new(); layer.layer=-5; add_child(layer); layer.add_child(backdrop)
	_setup()
	var seed:=_fight()
	await get_tree().process_frame
	await _battle(seed)
	print("BATTLE_SCALE_CAPTURE_PASS battle")
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
	civ["name"]="Esurai"


## 20 levies meet a band of two in the open, resolved exchange by exchange
## the way a live engagement is (one exchange a call), until it ends.
func _fight()->int:
	MilitaryCampaign.raise_recruits(20)
	MilitaryCampaign.start_training("levy","improvised",20)
	MilitaryCampaign._complete_training(MilitaryCampaign.training_queue[0].duplicate(true))
	MilitaryCampaign.training_queue.clear()
	var made:=MilitaryCampaign.create_field_army(20)
	var army_id:=int((made.army as Dictionary).army_id)
	var index_:=MilitaryCampaign._field_army_index(army_id)
	var army:Dictionary=MilitaryCampaign.field_armies[index_]
	army["commander"]=MilitaryCampaign.simulator.create_commander("Rovik Longstride",0.69,0.66,0.55,0.74)
	var origin:Vector2=CivilizationSystem.player_world_origin
	army["position"]={"x":origin.x+6.0,"z":origin.y+2.0}
	MilitaryCampaign.field_armies[index_]=army
	var theirs:Dictionary=MilitaryCampaign.simulator.create_formation_force("Esurai band",[{"unit":"levy","weapon":"improvised","count":2,"equipment":2,"training":0.4}],0.62,0.6)
	theirs["commander"]=MilitaryCampaign.simulator.create_commander("Masu of Ashbank",0.58,0.55,0.56,0.65)
	var plan:={"attacker":{"id":"head_on","profile":{},"shape":"clash"},"defender":{"id":"head_on","profile":{},"shape":"clash"}}
	var ours:Dictionary=MilitaryCampaign.field_armies[index_].duplicate(true)
	var rounds:Array=[]
	var result:Dictionary={}
	var a:=ours; var d:=theirs
	for exchange in 12:
		result=MilitaryCampaign.simulator.simulate(a,d,{"seed":9100+(exchange+1)*7919,"terrain_defense":1.0,"max_rounds":1,"tactics":plan,"round_offset":exchange})
		if (result.rounds as Array).is_empty(): break
		var r:Dictionary=(result.rounds[0] as Dictionary).duplicate(true); r["round"]=exchange+1
		rounds.append(r)
		a=MilitaryCampaign._force_from_round_result(a,result.attacker)
		d=MilitaryCampaign._force_from_round_result(d,result.defender)
		if String(result.outcome) not in ["inconclusive","continued"]: break
	var attacker_result:Dictionary=MilitaryCampaign.simulator._force_result(a,20,int(a.troops),float(a.morale))
	var defender_result:Dictionary=MilitaryCampaign.simulator._force_result(d,2,int(d.troops),float(d.morale))
	print("FIXTURE exchanges=%d outcome=%s ours_lost=%d theirs_lost=%d" % [rounds.size(),String(result.get("outcome","")),20-int(a.troops),2-int(d.troops)])
	var record:={"seed":9100,"outcome":String(result.get("outcome","")),"winner":String(result.get("winner","")),"round_count":rounds.size(),"rounds":rounds,
		"attacker":attacker_result,"defender":defender_result,"home_side":"attacker","home_force_kind":"field_army","home_force_id":army_id,"campaign_mode":"offensive",
		"field_encounter":true,"formation_id":"","target_region_id":"","target_region_name":"the field contact",
		"threat":{"source_name":"Esurai","source_civ_id":String(CivilizationSystem.civilizations[0].id),"field_encounter":true,"target_position":{"x":origin.x+6.0,"z":origin.y+2.5}},
		"terrain_defense":1.0,"termination":result.get("termination",{}),"tactics":plan,"orders":{"retreated":false}}
	MilitaryCampaign._commit_campaign_battle(record)
	MilitaryCampaign.pending_aftermath.clear()
	var account:=preload("res://scripts/battle_account.gd").build(MilitaryCampaign.battle_history[0],{"stage":"hearth"})
	print("REPORT ",preload("res://scripts/battle_account.gd").text(account))
	return 9100


func _battle(seed:int)->void:
	# The battle panel (hud/battle_panel.gd): the result, then the two sides drawn up.
	MilitaryCommandUI._open_battle_graphics(0,seed)
	var panel:Control=MilitaryCommandUI.battle_graphics
	for i in 20: await get_tree().process_frame
	await _save("battle_result")
	if not is_instance_valid(panel): return
	panel.call("_select",0)
	for i in 8: await get_tree().process_frame
	await _save("battle_drawn_up")


func _wait(seconds:float)->void:
	await get_tree().create_timer(seconds).timeout


func _save(name:String)->void:
	await RenderingServer.frame_post_draw
	var path:=ProjectSettings.globalize_path(out.path_join(name+".png"))
	get_viewport().get_texture().get_image().save_png(path)
	print("SAVED ",path)


# --- Map plates ------------------------------------------------------------------

func _map_plates()->void:
	overlay=Overlay.new()
	add_child(overlay)
	overlay.project=func(p:Vector2)->Vector2: return _to_screen(p)
	overlay.band_override="local"
	plates=[_hearth_skirmish(),_host_against_scouts(),_front_against_party()]
	_next()


func _next()->void:
	index+=1
	if index>=plates.size():
		print("BATTLE_SCALE_CAPTURE_PASS map %d plates" % plates.size())
		get_tree().quit(0); return
	current=plates[index]
	overlay.set_scene(Overlay.compose(current.inputs),true)
	frames=0
	queue_redraw()


func _process(_delta:float)->void:
	if shot!="map" or index<0 or index>=plates.size(): return
	frames+=1
	if frames==4:
		var image:=get_viewport().get_texture().get_image()
		var path:=ProjectSettings.globalize_path(out.path_join("map_%s.png" % current.name))
		image.save_png(path)
		print("SAVED ",path)
		_next()


func _to_screen(p:Vector2)->Vector2:
	var view:Dictionary=current.get("view",{"centre":Vector2.ZERO,"scale":40.0})
	return size*0.5+((p-(view.centre as Vector2))*float(view.scale))


## Hearth age: our 20 fall on their 2 in the open.
func _hearth_skirmish()->Dictionary:
	var home:=Vector2(0,0)
	return {"name":"hearth_20_vs_2","title":"Hearth age: our 20 fall on their 2","view":{"centre":Vector2(4.0,1.0),"scale":150.0},
		"inputs":{"mode":"raid","stage":"hearth","home":home,
			"friendly":[{"id":"1","army_id":1,"pos":Vector2(4.4,1.0),"strength":20.0}],
			"enemy":[{"id":"e1","pos":Vector2(5.0,1.2),"strength":2.0,"low":2,"high":2,"age_days":0,"marked":true}],
			"engagements":[{"pos":Vector2(4.7,1.1),"axis":Vector2(1,0.3).normalized(),"ours":"head_on","theirs":"head_on","rounds":1,"phase_ours":"hold","phase_theirs":"hold","army_id":1,"our_troops":20,"their_troops":2}]}}


## A host of 400 comes up on three of their scouts.
func _host_against_scouts()->Dictionary:
	var home:=Vector2(-6,0)
	return {"name":"host_400_vs_3","title":"Host age: our 400 come on 3 of theirs","view":{"centre":Vector2(1.0,0.5),"scale":120.0},
		"inputs":{"mode":"host","stage":"lettered","home":home,
			"friendly":[{"id":"1","army_id":1,"pos":Vector2(0.4,0.3),"strength":400.0}],
			"enemy":[{"id":"e1","pos":Vector2(1.6,0.7),"strength":3.0,"low":3,"high":3,"age_days":0,"marked":true}]}}


## A regiment-scale army facing both a real host and a party of two.
func _front_against_party()->Dictionary:
	var home:=Vector2(-6,0)
	return {"name":"front_3000_vs_2","title":"Front age: our 3000 face their 2500 and a party of 2","view":{"centre":Vector2(3.0,1.0),"scale":60.0},
		"inputs":{"mode":"front","stage":"lettered","home":home,
			"friendly":[{"id":"1","army_id":1,"pos":Vector2(0,-3),"strength":3000.0},{"id":"2","army_id":2,"pos":Vector2(0.5,5),"strength":1500.0}],
			"enemy":[{"id":"a","pos":Vector2(6,-2.5),"strength":2500.0,"low":2500,"high":2500,"age_days":1,"marked":true},{"id":"b","pos":Vector2(3.2,5.4),"strength":2.0,"low":2,"high":2,"age_days":0,"marked":true}]}}


func _draw()->void:
	if shot!="map" or current.is_empty(): return
	draw_rect(Rect2(Vector2.ZERO,size),Color("#8a8a4a"))
	var rng:=RandomNumberGenerator.new(); rng.seed=hash(String(current.name))
	for k in 70:
		var c:=Vector2(rng.randf()*size.x,rng.randf()*size.y)
		draw_circle(c,rng.randf_range(20,90),Color("#6e7f3e") if k%3 else Color("#3e4a2c"),true)
	draw_rect(Rect2(16,16,size.x-32,34),Color("#efe6d4",0.92))
	draw_string(ThemeDB.fallback_font,Vector2(28,39),"TEST CAPTURE · %s" % String(current.title),HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#1f1a14"))

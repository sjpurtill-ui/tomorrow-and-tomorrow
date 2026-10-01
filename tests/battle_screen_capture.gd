extends Control
## TEST CAPTURE (not the game): the battle screen (hud/battle_panel.gd) on
## battles of every age, played through the real engine by the battle
## evaluation's own runners (tests/battle_eval/runners.gd), in the light and
## the dark paper:
##   stone       a first-age fight of bands, a day in
##   classical   four thousand force a ford, a day in, then its end
##   gunpowder   musket, pike, horse and guns, two days in
##   modern      forty thousand with armour and guns, two days in
##   siege       Seanstone ringed, then its palisade stormed
##   pass, forest, hills   the narrow pass, a forest edge, broken hills
## Run only through tools/run_isolated_gpu_probe.ps1 with
## -UserArguments "--capture-dir=<absolute dir>". Quits by itself.

const Runners:=preload("res://tests/battle_eval/runners.gd")
const Scenarios:=preload("res://tests/battle_eval/scenarios.gd")
const View:=preload("res://scripts/hud/battle_view.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")
const Motion:=preload("res://scripts/hud/motion.gd")

var directory:=""
var runner:RefCounted
var game_speed:=0.0
## Only these captures (comma list of names), when given.
var only:PackedStringArray=[]


func _set_game_speed(speed:float)->void:
	game_speed=speed


func _ready()->void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Motion.reduce_motion=false
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="): directory=argument.trim_prefix("--capture-dir=")
		if argument.begins_with("--only="): only=argument.trim_prefix("--only=").split(",")
	if directory=="": directory=ProjectSettings.globalize_path("user://battle_screen_capture")
	DirAccess.make_dir_recursive_absolute(directory)
	var ground:=ColorRect.new(); ground.color=Color("#8a8a6a"); ground.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); ground.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(ground)
	runner=Runners.new(self)
	await get_tree().process_frame
	if _wanted("stone"): await _stone()
	if _wanted("classical"): await _classical()
	if _wanted("gunpowder"): await _gunpowder()
	if _wanted("modern"): await _modern()
	if _wanted("siege"): await _siege()
	if _wanted("pass"): await _pass()
	if _wanted("forest"): await _ground("stone_forest_edge","stone_forest_edge_day1")
	if _wanted("hills"): await _ground("battle_in_the_hills","stone_hills_day1")
	T.set_color_mode("light")
	print("BATTLE_SCREEN_CAPTURE_DONE %s" % directory)
	get_tree().quit(0)


func _wanted(name:String)->bool:
	return only.is_empty() or only.has(name)


func _scenario(id:String)->Dictionary:
	for s:Dictionary in Scenarios.all():
		if String(s.id)==id: return s.duplicate(true)
	return {}


## The scenario's world, its armies drawn up (the runner's own steps).
func _begin(id:String)->Dictionary:
	var s:=_scenario(id)
	runner.s=s; runner.fails=[]; runner.notes=[]; runner.resolved=[]; runner.traces={}
	runner.water=[]; runner.hills=[]; runner.forest=[]; runner.river=[]
	runner.reset_world(s)
	return s


func _field(s:Dictionary,at:Vector2=Vector2(5.0,0.0))->String:
	var a:int=runner.our_army(s.get("ours",[]),{"morale":float(s.get("our_morale",0.8)),"at":s.get("at",at)})
	var enemy:Dictionary=runner.their_force(s.get("theirs",[]),{"morale":float(s.get("their_morale",0.7)),"readiness":runner.army(a).get("readiness",0.6)})
	var opts:={"seed":int(s.get("seed",11))}
	if s.has("toward"): opts["toward"]=s.toward
	var started:Dictionary=runner.field_contact(a,enemy,opts)
	return String(started.get("id",""))


func _days(n:int)->void:
	for i in n:
		if View.live_engagements().is_empty(): return
		runner.day()


# --- The battles ------------------------------------------------------------------------

func _stone()->void:
	var s:=_begin("stone_120v90")
	var id:=_field(s)
	_days(1)
	await _both(id,"stone_120v90_day1")


func _classical()->void:
	var s:=_begin("classical_ford_crossing")
	var id:=_field(s)
	_days(1)
	await _both(id,"classical_ford_day1")
	_days(12)
	await _both(id,"classical_ford_finished")
	await _both(id,"classical_ford_drawn_up",0)


func _gunpowder()->void:
	var s:=_begin("gunpowder_8000v7000")
	var id:=_field(s)
	_days(2)
	await _both(id,"gunpowder_8000v7000_day2")
	_days(12)
	await _both(id,"gunpowder_8000v7000_finished_day1",1)


func _modern()->void:
	var s:=_begin("modern_40000v35000")
	var id:=_field(s,Vector2(8.0,-3.0))
	_days(2)
	await _both(id,"modern_40000v35000_day2")


## A first-age fight on its own ground (a forest edge, broken hills), a day in.
func _ground(scenario:String,name:String)->void:
	var s:=_begin(scenario)
	var id:=_field(s)
	_days(1)
	await _both(id,name)


func _pass()->void:
	var s:=_begin("bronze_pass_reserves")
	var id:=_field(s)
	_days(2)
	await _both(id,"bronze_pass_day2")


## A host of four hundred rings Seanstone behind its palisade, then storms
## it (the home siege runner's steps).
func _siege()->void:
	var s:=_begin("home_besieged")
	runner.home_watch(s.get("ours",[]),int(s.get("watch",120)))
	MilitaryCampaign.settlement_defense={"stage":3,"integrity":1.0,"project_stage":-1,"project_progress":0.0,"project_work":0.0,"reserved_materials":{},"completed_day":0}
	var enemy:Dictionary=runner.their_force(s.get("theirs",[]),{"morale":0.8,"readiness":0.6})
	MilitaryCampaign._create_civilization_threat({"id":"host","source_civ_id":runner.civ_id,"source_name":"Esurai","incident_kind":"campaign","strength":int(enemy.troops),"technology":0.3,"readiness":0.6},"defensive")
	MilitaryCampaign.active_threat["enemy_force"]=enemy
	MilitaryCampaign.active_threat["estimated_strength"]=int(enemy.troops)
	MilitaryCampaign.active_threat["deadline_day"]=int(GameState.elapsed_days)
	MilitaryCampaign.active_threat["seed"]=int(s.get("seed",11))
	runner.day()
	if MilitaryCampaign.active_siege.is_empty(): push_warning("CAPTURE the host did not ring Seanstone"); return
	for n in int(s.get("siege_days",4)):
		runner.day()
		if MilitaryCampaign.active_siege.is_empty(): break
	if MilitaryCampaign.active_siege.is_empty(): push_warning("CAPTURE the siege ended by itself"); return
	var order:Dictionary=MilitaryCampaign.siege_order(String(MilitaryCampaign.active_siege.id),"assault")
	if order.has("error"): push_warning("CAPTURE the storm did not begin: %s" % String(order.error)); return
	var live:=View.live_engagements()
	var id:=String((live[0] as Dictionary).get("id","")) if not live.is_empty() else ""
	if id!="":
		_days(1)
		if not View.live_engagements().is_empty(): await _both(id,"siege_seanstone_storm_day1")
	_days(12)
	var history:Array=MilitaryCampaign.battle_history
	if not history.is_empty(): await _both(int((history[0] as Dictionary).get("seed",-1)),"siege_seanstone_storm_finished")


# --- Photographs --------------------------------------------------------------------------

## The battle screen in the light paper, then the dark; at a given day of
## the battle when `day` is 0 or more.
func _both(target:Variant,name:String,day:int=-1)->void:
	for mode in ["light","dark"]:
		T.set_color_mode(mode)
		await _panel(target,"%s_%s" % [name,mode],day)
	T.set_color_mode("light")


func _panel(target:Variant,name:String,day:int=-1)->void:
	var panel:=View.open(target,self)
	if panel==null: push_warning("CAPTURE no battle %s to open" % str(target)); return
	if day>=0: panel.call("_select",day,false)
	# Past the panel's fade-in (timed in seconds; the probe draws frames fast).
	await get_tree().create_timer(1.6).timeout
	for i in 4: await get_tree().process_frame
	await _save(name)
	View.close_open(self)
	for i in 4: await get_tree().process_frame


func _save(name:String)->void:
	for i in 4: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var path:=directory.path_join(name+".png")
	get_viewport().get_texture().get_image().save_png(path)
	print("SAVED ",path)

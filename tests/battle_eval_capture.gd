extends Control
## TEST CAPTURE (not the game): three battle evaluation scenarios, played
## through the real engine (tests/battle_eval/runners.gd), photographed mid
## battle for review: the battle panel (hud/battle_view.gd open) and the war
## chart's own marks (hud/war_front_overlay.gd collect -> compose -> draw).
##   battle_in_the_hills  a first-age fight of bands on broken ground, a day in
##   modern_40000v35000   an armoured battle, reserves waiting, two days in
##   two_battles_at_once  two of our fights and a rival fight our band sees
##   home_besieged        a host rings Seanstone: the siege mark, both sides
## Run only through tools/run_isolated_gpu_probe.ps1 with
## -UserArguments "--capture-dir=<absolute dir>". Quits by itself.

const Runners:=preload("res://tests/battle_eval/runners.gd")
const Scenarios:=preload("res://tests/battle_eval/scenarios.gd")
const Overlay:=preload("res://scripts/hud/war_front_overlay.gd")
const View:=preload("res://scripts/hud/battle_view.gd")
const Motion:=preload("res://scripts/hud/motion.gd")

var directory:=""
var runner:RefCounted
var overlay:Control
var centre:=Vector2.ZERO
var scale_px:=40.0
var game_speed:=0.0


func _set_game_speed(speed:float)->void:
	game_speed=speed


func _ready()->void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Motion.reduce_motion=false
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="): directory=argument.trim_prefix("--capture-dir=")
	if directory=="": directory=ProjectSettings.globalize_path("user://battle_eval_capture")
	DirAccess.make_dir_recursive_absolute(directory)
	var ground:=ColorRect.new(); ground.color=Color("#d9ccaa"); ground.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); ground.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(ground)
	runner=Runners.new(self)
	await get_tree().process_frame
	await _stone()
	await _modern()
	await _two_and_a_rival()
	await _siege_at_home()
	print("BATTLE_EVAL_CAPTURE_DONE %s" % directory)
	get_tree().quit(0)


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


func _field(s:Dictionary,at:Vector2,seed_offset:int=0)->String:
	var a:int=runner.our_army(s.get("ours",[]),{"morale":float(s.get("our_morale",0.8)),"at":at})
	var enemy:Dictionary=runner.their_force(s.get("theirs",[]),{"morale":float(s.get("their_morale",0.7)),"readiness":runner.army(a).get("readiness",0.6)})
	var started:Dictionary=runner.field_contact(a,enemy,{"seed":int(s.get("seed",11))+seed_offset,"formation":"f%d" % a})
	return String(started.get("id",""))


func _days(n:int)->void:
	for i in n:
		if View.live_engagements().is_empty(): return
		runner.day()


# --- The three -------------------------------------------------------------------------

func _stone()->void:
	var s:=_begin("battle_in_the_hills")
	var id:=_field(s,Vector2(5.0,0.0))
	_days(1)
	await _map("hills_120v110_map",40.0)
	await _panel(id,"hills_120v110_panel")
	# The same fight to its end, read back from its record.
	_days(8)
	await _panel(id,"hills_120v110_finished_panel")


func _modern()->void:
	var s:=_begin("modern_40000v35000")
	var id:=_field(s,Vector2(8.0,-3.0))
	_days(2)
	await _panel(id,"modern_40000v35000_panel")
	await _map("modern_40000v35000_map",18.0)


func _two_and_a_rival()->void:
	var s:=_begin("two_battles_at_once")
	var spec:Array=[{"unit":"spearman","weapon":"shield_spear","count":400},{"unit":"archer","weapon":"bow","count":100}]
	var first:=_field({"ours":spec,"theirs":[{"unit":"spearman","weapon":"shield_spear","count":380},{"unit":"archer","weapon":"bow","count":90}],"seed":101},Vector2(4.0,-6.0))
	_field({"ours":spec,"theirs":[{"unit":"spearman","weapon":"shield_spear","count":390},{"unit":"archer","weapon":"bow","count":100}],"seed":118},Vector2(9.0,-2.0),17)
	# The rivals' fight, near one of our bands.
	var rival:=_scenario("rival_battle_seen")
	runner.s=rival
	WorldSimulation.create_actor(runner.civ_id,Runners.WORLD_SEED,runner.city)
	WorldSimulation.create_actor(runner.civ2_id,Runners.WORLD_SEED+1,runner.city2)
	WorldSimulation.enabled=true
	var place:Vector2=runner.home+Vector2(12.0,-4.0)
	WorldSimulation.scoped(runner.civ_id,func()->void:
		var m:Node=WorldSimulation.military
		var additions:Array=runner.formations([{"unit":"levy","weapon":"spear","count":300}],false)
		var fid:=1000
		for f in additions: f["id"]=fid; fid+=1
		m._rebuild_home_army_with(additions)
		var formed:Dictionary=m.create_field_army(300,"Esurai host")
		if formed.has("error"): return
		var aid:=int((formed.army as Dictionary).army_id)
		var index:int=m._field_army_index(aid)
		m.field_armies[index]["position"]={"x":place.x,"z":place.y}
		var enemy:Dictionary=m.simulator.create_formation_force("Cedar League band",runner.formations([{"unit":"levy","weapon":"spear","count":260}],false),0.75,0.6)
		enemy["commander"]=m.simulator.create_commander("Oru Vell",0.5,0.5,0.5,0.55)
		m.active_threat={"id":"rival","title":"x","incident_kind":"campaign","campaign_mode":"offensive","source_civ_id":runner.civ2_id,"source_name":"Cedar League","field_encounter":true,"formation_id":"cedar",
			"target_region_id":"","target_region_name":"","field_army_id":aid,"enemy_force":enemy,"terrain_defense":1.0,"seed":161,"deadline_day":99999,"discovered_day":int(WorldSimulation.state.elapsed_days),
			"target_position":{"x":place.x+0.3,"z":place.y}}
		m.begin_threat_engagement(false))
	_days(1)
	WorldSimulation.scoped(runner.civ_id,func()->void:
		WorldSimulation.state.elapsed_days=GameState.elapsed_days
		WorldSimulation.military.last_processed_day=int(WorldSimulation.state.elapsed_days)
		WorldSimulation.military._fight_own_battles_day())
	await _panel(first,"two_battles_panel_first")
	await _map("two_battles_and_a_rival_map",26.0)
	WorldSimulation.enabled=false
	WorldSimulation.clear()


## A host of four hundred rings Seanstone behind its palisade (the runner's
## own steps, _run_home_siege), two days into the siege.
func _siege_at_home()->void:
	var s:=_begin("home_besieged")
	runner.home_watch(s.get("ours",[]),int(s.get("watch",120)))
	MilitaryCampaign.settlement_defense={"stage":2,"integrity":1.0,"project_stage":-1,"project_progress":0.0,"project_work":0.0,"reserved_materials":{},"completed_day":0}
	var enemy:Dictionary=runner.their_force(s.get("theirs",[]),{"morale":0.8,"readiness":0.6})
	MilitaryCampaign._create_civilization_threat({"id":"host","source_civ_id":runner.civ_id,"source_name":"Esurai","incident_kind":"campaign","strength":int(enemy.troops),"technology":0.3,"readiness":0.6},"defensive")
	MilitaryCampaign.active_threat["enemy_force"]=enemy
	MilitaryCampaign.active_threat["estimated_strength"]=int(enemy.troops)
	MilitaryCampaign.active_threat["deadline_day"]=int(GameState.elapsed_days)
	MilitaryCampaign.active_threat["seed"]=int(s.get("seed",11))
	runner.day()
	if MilitaryCampaign.active_siege.is_empty(): push_warning("CAPTURE the host did not ring Seanstone"); return
	runner.day(); runner.day()
	await _map("home_besieged_map",40.0)


# --- Photographs --------------------------------------------------------------------------

func _panel(id:String,name:String)->void:
	var panel:=View.open(id,self)
	if panel==null: push_warning("CAPTURE no battle %s to open" % id); return
	# Past the panel's fade-in (timed in seconds; the probe draws frames fast).
	await get_tree().create_timer(1.2).timeout
	for i in 4: await get_tree().process_frame
	await _save(name)
	View.close_open(self)
	for i in 4: await get_tree().process_frame


## The war chart as the game composes it from the live campaign, centred on
## our battles.
func _map(name:String,px_per_km:float)->void:
	if is_instance_valid(overlay): overlay.queue_free()
	overlay=Overlay.new()
	add_child(overlay)
	overlay.set_process(false)
	overlay.terrain=self
	overlay.project=func(p:Vector2)->Vector2: return _to_screen(p)
	var inputs:Dictionary=overlay.collect()
	var battles:Array=inputs.get("battles",[])
	var sum:=Vector2.ZERO
	for b in battles: sum+=(b as Dictionary).pos
	centre=sum/float(maxi(1,battles.size())) if not battles.is_empty() else runner.home
	scale_px=px_per_km
	overlay.band_override="local" if px_per_km>=30.0 else "front"
	overlay.set_scene(Overlay.compose(inputs),true)
	overlay.anim_clock=1.2
	for i in 6: await get_tree().process_frame
	overlay.queue_redraw()
	print("CAPTURE %s battles=%d marks=%d" % [name,battles.size(),(overlay.scene.get("marks",[]) as Array).size()])
	for b in battles: print("  battle %s %s a=%d b=%d progress=%.2f day=%d status=%s" % [String(b.id),String(b.place_name),int(b.sides.a.troops),int(b.sides.b.troops),float(b.progress),int(b.day),String(b.status)])
	await _save(name)
	overlay.queue_free()


func _to_screen(p:Vector2)->Vector2:
	return size*0.5+(p-centre)*scale_px


func _save(name:String)->void:
	for i in 4: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var path:=directory.path_join(name+".png")
	get_viewport().get_texture().get_image().save_png(path)
	print("SAVED ",path)

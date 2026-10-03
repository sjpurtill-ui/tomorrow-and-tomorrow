extends "res://tests/audience_modal_probe.gd"
## How long the first opening of the modelled court takes, and whether
## warming it beforehand (court_prewarm.gd) costs the running game anything.
##   --mode=cold     open the court cold
##   --mode=parts    time each heavy piece cold (bodies, the set, the acting's
##                   library, the sound), then open
##   --mode=prewarm  start the warm-up as the game would, wait for it (the
##                   longest frame meanwhile is the cost to the game), then open
## Each prints COURT_OPEN lines: the open call itself (ms), the longest frame
## in the two seconds after, and a second open for comparison. Windowed on a
## private desktop (tools/run_isolated_gpu_probe.ps1), vsync off.

const Backdrop:=preload("res://scripts/hud/court_backdrop.gd")
const Figure3D:=preload("res://scripts/hud/court_figure_3d.gd")
const CourtSet:=preload("res://scripts/hud/court_set_3d.gd")
const Acting:=preload("res://scripts/hud/court_acting.gd")

var mode:="cold"

func _ready()->void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--mode="):mode=arg.trim_prefix("--mode=")
	capture=DisplayServer.get_name()!="headless"
	Backdrop.tier_override=0
	_setup_world()
	var terrain:=TerrainDouble.new();terrain.name="TerrainDouble";add_child(terrain)
	var director:=Director.new();director.terrain=terrain;add_child(director)
	if "force_offline" in director.voice:director.voice.force_offline=true
	if capture:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		get_window().size=Vector2i(1536,864);get_window().content_scale_size=Vector2i(1536,864)
	await _frames(30)
	HudTokens.set_color_mode("light")
	match mode:
		"parts":_parts()
		"prewarm":await _prewarm()
		"inside":
			_parts()
			await _inside()
	await _open(director,"first")
	await _open(director,"second")
	print("COURT_OPEN DONE")
	get_tree().quit(0)

func _ms(start:int)->float:
	return float(Time.get_ticks_usec()-start)/1000.0

func _parts()->void:
	var t:=Time.get_ticks_usec()
	for v:String in Figure3D.BODIES:Figure3D.scene_for(v)
	print("COURT_OPEN part bodies_ms=%.1f" % _ms(t))
	t=Time.get_ticks_usec()
	CourtSet.scene_for(CourtSet.kind_for(Backdrop.current_stage(),0))
	print("COURT_OPEN part set_ms=%.1f" % _ms(t))
	t=Time.get_ticks_usec()
	Acting.manifest()
	print("COURT_OPEN part acting_manifest_ms=%.1f" % _ms(t))
	for v:String in ["male_adult","female_adult","male_old","female_old","male_young","female_young","child"]:
		t=Time.get_ticks_usec()
		Acting.library(v)
		print("COURT_OPEN part acting_library_%s_ms=%.1f" % [v,_ms(t)])

## What the open itself spends once the files are in: the set built, its
## walking room read, people made (a new look each: their merged pieces).
func _inside()->void:
	const Paths:=preload("res://scripts/hud/court_paths.gd")
	const Stage:=preload("res://scripts/hud/court_stage.gd")
	var kind:=CourtSet.kind_for(Backdrop.current_stage(),0)
	var t:=Time.get_ticks_usec()
	var made:Node3D=CourtSet.build(kind,{"food":0.6,"tier":0,"seed":3})
	print("COURT_OPEN inside set_build_ms=%.1f" % _ms(t))
	t=Time.get_ticks_usec()
	add_child(made)
	print("COURT_OPEN inside set_enter_tree_ms=%.1f" % _ms(t))
	t=Time.get_ticks_usec()
	Paths.room_of(made)
	print("COURT_OPEN inside walking_room_ms=%.1f" % _ms(t))
	t=Time.get_ticks_usec()
	Paths.room_of(made)
	print("COURT_OPEN inside walking_room_again_ms=%.1f" % _ms(t))
	for i in 4:
		var person:={"name":"Probe Person %d" % i,"person_id":9000+i,"age":[30,52,24,67][i],"sex":["male","female"][i%2]}
		var look:Dictionary=Stage.figure_look(person,{}).duplicate();look["lit"]=true
		var body:=Figure3D.new()
		t=Time.get_ticks_usec()
		body.setup(look)
		var setup_ms:=_ms(t)
		t=Time.get_ticks_usec()
		made.add_child(body)
		print("COURT_OPEN inside figure_%d setup_ms=%.1f enter_tree_ms=%.1f variant=%s" % [i,setup_ms,_ms(t),String(body.variant)])
	await _frames(5)
	made.queue_free()
	await _frames(5)

func _prewarm()->void:
	var Prewarm:Script=load("res://scripts/hud/court_prewarm.gd") if ResourceLoader.exists("res://scripts/hud/court_prewarm.gd") else null
	if Prewarm==null:print("COURT_OPEN no prewarm");return
	var start:=Time.get_ticks_usec()
	Prewarm.call("start",self)
	var worst:=0.0;var frames:=0;var over:=0
	var last:=Time.get_ticks_usec()
	while not bool(Prewarm.get("done")) and _ms(start)<20000.0:
		await get_tree().process_frame
		var now:=Time.get_ticks_usec()
		var dt:=float(now-last)/1000.0;last=now
		worst=maxf(worst,dt);frames+=1
		if dt>16.7:over+=1
	print("COURT_OPEN prewarm done=%s wall_ms=%.0f frames=%d longest_frame_ms=%.1f frames_over_16ms=%d" % [Prewarm.get("done"),_ms(start),frames,worst,over])

func _open(director:Node,label:String)->void:
	var audience:=Hall.debug_force("petition")
	if audience.is_empty():print("COURT_OPEN no petition");return
	var id:=String(audience.id)
	var t:=Time.get_ticks_usec()
	var modal:Control=director.open_audience(id)
	var call_ms:=_ms(t)
	var worst:=0.0
	var last:=Time.get_ticks_usec()
	var until:=Time.get_ticks_usec()+2000000
	var frames:=0
	while Time.get_ticks_usec()<until:
		await get_tree().process_frame
		var now:=Time.get_ticks_usec()
		worst=maxf(worst,float(now-last)/1000.0);last=now;frames+=1
	var people:=0
	if is_instance_valid(modal) and is_instance_valid(modal.court_stage):
		for key in modal.court_stage.cast_order:
			var f:Variant=modal.court_stage.figure(key)
			if f!=null and f.body3d!=null:people+=1
	print("COURT_OPEN %s mode=%s open_call_ms=%.1f longest_frame_after_ms=%.1f frames_in_2s=%d people=%d" % [label,mode,call_ms,worst,frames,people])
	if is_instance_valid(modal):
		modal.make_them_wait()
		if is_instance_valid(modal) and modal.has_method("_close"):modal.call("_close")
	await _frames(10)

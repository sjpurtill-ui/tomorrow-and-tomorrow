extends "res://tests/audience_modal_probe.gd"
## Two scenes of the modelled court, for review: the real Court modal, the
## real engine, the director (L), the acting (K), the set (M) and the figures.
##   --only=wrath   the god's wrath falls on the one before them
##   --only=gift    an envoy's gift of food is accepted
##   --tier=0|1     the fire circle (0) or the longhouse (1)
## Run windowed on a private desktop with Godot's movie writer, so every frame
## is kept at a steady 12 a second whatever the machine (run_movie.ps1 passes
## --write-movie <dir>/f.png --fixed-fps 12); tools/court_clip_gif.py makes
## the GIF. Presentation only: the engine decides what happens.

const Backdrop:=preload("res://scripts/hud/court_backdrop.gd")

var only:="wrath"
var tier:=0

func _ready()->void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):only=arg.trim_prefix("--only=")
		if arg.begins_with("--tier="):tier=int(arg.trim_prefix("--tier="))
	capture=DisplayServer.get_name()!="headless"
	Backdrop.tier_override=tier
	_setup_world()
	var terrain:=TerrainDouble.new();terrain.name="TerrainDouble";add_child(terrain)
	var director:=Director.new();director.terrain=terrain;add_child(director)
	if "force_offline" in director.voice:director.voice.force_offline=true
	await _frames(2)
	if capture:
		get_window().size=Vector2i(1536,864);get_window().content_scale_size=Vector2i(1536,864)
		await _frames(3)
	HudTokens.set_color_mode("light")
	if only=="gift":await _gift(director)
	else:await _wrath(director)
	print("COURT_MORNING_CLIP PASS" if failures.is_empty() else "COURT_MORNING_CLIP FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)

func _wait(seconds:float)->void:
	await get_tree().create_timer(seconds).timeout

func _wrath(director:Node)->void:
	var audience:=Hall.debug_force("petition")
	if audience.is_empty():_fail("no petition");return
	var id:=String(audience.id)
	var modal:Control=director.open_audience(id)
	await _wait_scene(modal,id,1)
	print("MARK opened")
	await _wait(4.5)
	Hall.append_line(id,{"speaker":"You","role":"ruler","person_id":0,"civ_id":"","text":"Two men and a boy at the ford, and you come to me only now?","day":int(GameState.elapsed_days),"aside":false})
	await _wait(4.0)
	print("MARK wrath")
	var result:Dictionary=modal.divine("terrify")
	print("WRATH ",result.get("ok",false)," response ",result.get("response",""))
	await _wait(8.0)
	print("MARK end")

func _gift(director:Node)->void:
	var audience:={}
	for i in 8:
		var made:=Hall.debug_force("gift")
		if made.is_empty():continue
		audience=made
		if String((made.get("terms",{}) as Dictionary).get("resource",""))=="Food":break
	if audience.is_empty():_fail("no gift");return
	var id:=String(audience.id)
	var modal:Control=director.open_audience(id)
	await _wait_scene(modal,id,1)
	print("MARK opened ",(audience.get("terms",{}) as Dictionary))
	await _wait(5.0)
	var chosen:=""
	for option:Dictionary in Hall.options(id):
		if String(option.get("id","")).contains("accept") and bool(option.get("enabled",true)):chosen=String(option.id);break
	if chosen.is_empty():_fail("no accept option");return
	print("MARK accept ",chosen)
	var result:Dictionary=modal.choose(chosen)
	print("ACCEPT ",result.get("ok",false))
	await _wait(8.0)
	print("MARK end")

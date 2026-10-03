extends "res://tests/audience_modal_probe.gd"
## A short clip of the court as a stage, for review: a summoned official is
## answered, the god speaks, the hall shows a bow, the god's wrath falls, and
## they take their leave. Frames at 12 a second go to
## res://reports/court_figures/clip_<tag>/ (reports/ is ignored by git);
## tools/court_clip_gif.py turns them into a GIF.
## Windowed only, on a private desktop (tools/run_isolated_gpu_probe.ps1).
##   powershell -File tools/run_isolated_gpu_probe.ps1 -Godot <godot> -Project <worktree> -Scene res://tests/court_stage_clip.tscn -LogFile <log>

const FPS:=12.0
var frame_dir:=""
var frame:=0

func _ready()->void:
	capture=DisplayServer.get_name()!="headless"
	_setup_world()
	var terrain:=TerrainDouble.new();terrain.name="TerrainDouble";add_child(terrain)
	var director:=Director.new();director.terrain=terrain;add_child(director)
	if "force_offline" in director.voice:director.voice.force_offline=true
	await _frames(2)
	if capture:
		get_window().size=Vector2i(1536,864);get_window().content_scale_size=Vector2i(1536,864)
		await _frames(3)
	HudTokens.set_color_mode("light")
	await _home(director)
	await _envoy(director)
	print("COURT_STAGE_CLIP PASS" if failures.is_empty() else "COURT_STAGE_CLIP FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)

func _roll(seconds:float)->void:
	## Let the hall play for a while, keeping a frame every 1/FPS.
	var until:=Time.get_ticks_msec()+int(seconds*1000.0)
	while Time.get_ticks_msec()<until:
		await get_tree().create_timer(1.0/FPS).timeout
		if capture:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(frame_dir+"f%04d.png" % frame)
		frame+=1

func _start(tag:String)->void:
	frame=0
	frame_dir=ProjectSettings.globalize_path("res://reports/court_figures/clip_%s/" % tag)
	if capture:DirAccess.make_dir_recursive_absolute(frame_dir)

func _home(director:Node)->void:
	_start("home")
	var audience:=Hall.debug_force("petition")
	if audience.is_empty():_fail("no petition");return
	var id:=String(audience.id)
	var modal:Control=director.open_audience(id)
	await _wait_scene(modal,id,1)
	await _roll(3.0)
	var court:Array=Hall.court(id)
	if not court.is_empty():
		Hall.append_line(id,{"speaker":String(court[0].name),"role":"official","person_id":int(court[0].person_id),"civ_id":"","text":"The watch at the ford is two men and a boy. Two men and a boy.","day":int(GameState.elapsed_days),"aside":false})
	await _roll(4.0)
	Hall.append_line(id,{"speaker":"You","role":"ruler","person_id":0,"civ_id":"","text":"Then the watch is doubled before the moon is full.","day":int(GameState.elapsed_days),"aside":false})
	await _roll(3.5)
	var speaker:Dictionary=Hall.find(id).speaker
	Hall.append_line(id,{"speaker":"","role":"narrator","person_id":0,"civ_id":"","text":"[%s bows low.]" % String(speaker.name),"day":int(GameState.elapsed_days),"aside":false,"about":String(speaker.name)})
	await _roll(3.0)
	modal.divine("terrify")
	await _roll(4.0)
	modal.make_them_wait()
	await _roll(2.5)

func _envoy(director:Node)->void:
	_start("envoy")
	var audience:=Hall.debug_force("gift")
	if audience.is_empty():audience=Hall.debug_force("news")
	if audience.is_empty():_fail("no envoy");return
	var id:=String(audience.id)
	var modal:Control=director.open_audience(id)
	await _wait_scene(modal,id,1)
	await _roll(6.0)
	modal.make_them_wait()
	await _roll(1.0)

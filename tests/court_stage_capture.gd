extends "res://tests/audience_modal_probe.gd"
## Review captures of the court as a stage (scripts/hud/court_stage.gd): a
## summoned official answering the god, the god's words from above, a caption,
## the "Earlier" history, an envoy with their company, and the court at rest.
## Windowed only (tools/run_isolated_gpu_probe.ps1, on a private desktop); it
## writes res://reports/court_stage/*.png (reports/ is ignored by git).
## Headless it only checks that every view builds.
##   powershell -File tools/run_isolated_gpu_probe.ps1 -Godot <godot> -Project <worktree> -Scene res://tests/court_stage_capture.tscn -LogFile <log>

const Stage:=preload("res://scripts/hud/court_stage.gd")

func _ready()->void:
	capture=DisplayServer.get_name()!="headless"
	out_dir=ProjectSettings.globalize_path("res://reports/court_stage/")
	if capture:DirAccess.make_dir_recursive_absolute(out_dir)
	_setup_world()
	var terrain:=TerrainDouble.new();terrain.name="TerrainDouble";add_child(terrain)
	var director:=Director.new();director.terrain=terrain;add_child(director)
	if "force_offline" in director.voice:director.voice.force_offline=true
	await _frames(2)
	for view in [Vector2i(1920,1080),Vector2i(1280,720)]:
		if capture:
			get_window().size=view;get_window().content_scale_size=view
			await _frames(3)
		var tag:="%dx%d" % [view.x,view.y]
		HudTokens.set_color_mode("light")
		await _home(director,tag)
		await _envoy(director,tag)
		await _rest(director,tag)
		if not capture:break
	if capture:
		HudTokens.set_color_mode("dark")
		get_window().size=Vector2i(1920,1080);get_window().content_scale_size=Vector2i(1920,1080)
		await _frames(3)
		await _home(director,"1920x1080-dark")
		HudTokens.set_color_mode("light")
	if failures.is_empty():
		print("COURT_STAGE_CAPTURE PASS")
		get_tree().quit(0)
	else:
		for failure in failures:printerr("COURT_STAGE_CAPTURE FAIL: ",failure)
		get_tree().quit(1)

func _shot(label:String)->void:
	if not capture:return
	await _frames(4)
	await RenderingServer.frame_post_draw
	var path:=out_dir+"court-stage-"+label+".png"
	get_viewport().get_texture().get_image().save_png(path)
	print("COURT_STAGE capture ",path)

func _home(director:Node,tag:String)->void:
	var audience:=Hall.debug_force("petition")
	if audience.is_empty():_fail("no petition");return
	var id:=String(audience.id)
	var modal:Control=director.open_audience(id)
	await _wait_scene(modal,id,1)
	if not is_instance_valid(modal.court_stage):_fail("the home audience has no stage");return
	# The god speaks, the court answers, and a fact of the hall is told.
	var before:=(Hall.find(id).lines as Array).size()
	modal.speech_input.text="Tell me plainly what you need, and who stands in your way."
	modal._speak()
	await _wait_scene(modal,id,before+2)
	await get_tree().create_timer(1.6).timeout
	modal.skip_reveal()
	await _shot("home-%s" % tag)
	# The god's own words, from above, as they come.
	Hall.append_line(id,{"speaker":"You","role":"ruler","person_id":0,"civ_id":"","text":"Then let the stores be counted again before the moon is full.","day":int(GameState.elapsed_days),"aside":false})
	modal.skip_reveal()
	await _shot("home-god-%s" % tag)
	Hall.append_line(id,{"speaker":"","role":"narrator","person_id":0,"civ_id":"","text":"[The headman bows and sends for the tally-keeper.]","day":int(GameState.elapsed_days),"aside":false})
	var court:Array=Hall.court(id)
	if not court.is_empty():
		Hall.append_line(id,{"speaker":String(court[0].name),"role":"official","person_id":int(court[0].person_id),"civ_id":"","text":"I will stand by the store-pits myself while they count.","day":int(GameState.elapsed_days),"aside":false})
	modal.skip_reveal()
	await _shot("home-witness-%s" % tag)
	modal.toggle_popover("WhatWasSaid")
	await _shot("home-earlier-%s" % tag)
	modal.toggle_popover("WhatWasSaid")
	modal.make_them_wait()
	await _frames(2)

func _envoy(director:Node,tag:String)->void:
	var audience:=Hall.debug_force("gift")
	if audience.is_empty():audience=Hall.debug_force("news")
	if audience.is_empty():_fail("no envoy");return
	var id:=String(audience.id)
	var modal:Control=director.open_audience(id)
	await _wait_scene(modal,id,1)
	await get_tree().create_timer(1.6).timeout
	modal.skip_reveal()
	if not is_instance_valid(modal.court_stage):_fail("the envoy audience has no stage");return
	await _shot("envoy-%s" % tag)
	modal.make_them_wait()
	await _frames(2)

func _rest(director:Node,tag:String)->void:
	var court:Control=director.open_court()
	await _frames(4)
	if court.find_children("Seat_*","Control",true,false).is_empty():_fail("nobody stands in the court at rest")
	await _shot("rest-%s" % tag)
	court._close()
	await _frames(2)

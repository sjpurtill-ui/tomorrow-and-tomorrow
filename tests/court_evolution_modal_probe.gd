extends "res://tests/audience_modal_probe.gd"
## Actual audience UI and live court roster at selected dated capabilities.
## This is a diagnostic world, not a campaign simulation or the player game.
const Reference:=preload("res://tests/court_eval/progression_fixture.gd")
const CourtSet:=preload("res://scripts/hud/court_set_3d.gd")
const Chapters:=preload("res://scripts/hud/court_chapters.gd")

func _ready()->void:
	capture=DisplayServer.get_name()!="headless"
	out_dir=ProjectSettings.globalize_path("res://reports/court_evolution_modal/")
	if capture:DirAccess.make_dir_recursive_absolute(out_dir)
	_setup_world()
	var terrain:=TerrainDouble.new();add_child(terrain)
	var director:=Director.new();director.terrain=terrain;add_child(director)
	director.voice.force_offline=true
	CourtSet.quality="high"
	var year:=3000
	for argument:String in OS.get_cmdline_user_args():
		if argument.begins_with("--year="):year=int(argument.trim_prefix("--year="))
	GameState.elapsed_days=year*365.0
	GameState.known_discoveries.assign(Reference.known_at(year))
	for dimensions:Vector2i in [Vector2i(1920,1080),Vector2i(1280,720)]:
		get_window().size=dimensions;get_window().content_scale_size=dimensions
		await _frames(3)
		var audience:=Hall.debug_force("petition")
		if audience.is_empty():_fail("No petition for actual court");break
		var modal:Control=director.open_audience(String(audience.id))
		if modal==null:_fail("Actual audience did not open");break
		await _wait_scene(modal,String(audience.id),1)
		modal.court_stage.settle();modal.court_stage.frame_cast(0.0)
		await _frames(8)
		if String(modal.court_stage.court_set.kind)!=String(Chapters.for_owner().set_kind):_fail("Actual modal uses wrong room")
		if not get_viewport().get_visible_rect().encloses(modal.card.get_global_rect()):_fail("Actual modal escapes viewport")
		if capture:await _capture("%04d-%dx%d-room" % [year,dimensions.x,dimensions.y])
		var main=modal.court_stage.figure("main")
		if main!=null:
			modal.court_stage.say("main","We ask you to hear the council's report.",true)
			await get_tree().create_timer(.7).timeout
			if capture:await _capture("%04d-%dx%d-speaking" % [year,dimensions.x,dimensions.y])
		modal.make_them_wait();await _frames(5)
	CourtSet.quality="auto"
	print("COURT_EVOLUTION_MODAL PASS year=%d" % year if failures.is_empty() else "COURT_EVOLUTION_MODAL FAIL "+str(failures))
	get_tree().quit(0 if failures.is_empty() else 1)

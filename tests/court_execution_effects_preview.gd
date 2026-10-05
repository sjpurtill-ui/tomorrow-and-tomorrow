extends "res://tests/audience_modal_probe.gd"
const Backdrop:=preload("res://scripts/hud/court_backdrop.gd")
var method:="behead"
func _ready()->void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--method="):method=arg.trim_prefix("--method=")
	Backdrop.tier_override=0
	preload("res://tests/court_eval/fixtures.gd").new(self).base(false)
	GameState.known_discoveries.append("bronze_alloying")
	var terrain:=TerrainDouble.new();add_child(terrain)
	var director:=Director.new();director.terrain=terrain;add_child(director)
	director.voice.force_offline=true
	get_window().size=Vector2i(1280,720);get_window().content_scale_size=Vector2i(1280,720)
	await _frames(3)
	var marshal:=GovernmentPeopleSystem.officeholder("Marshal")
	var target:={"person_id":int(marshal.get("person_id",0))} if not marshal.is_empty() else (Hall.summonable()[0].target as Dictionary)
	var audience:=Hall.summon(target)
	var modal:Control=director.open_audience(String(audience.id))
	await _frames(8)
	modal.skip_reveal();modal.court_stage.settle()
	await get_tree().create_timer(1.0).timeout
	var stage:Control=modal.court_stage
	stage.execute(method,"main")
	var folder:=ProjectSettings.globalize_path("res://artifacts/execution-preview/"+method+"/")
	DirAccess.make_dir_recursive_absolute(folder)
	var log:=FileAccess.open(folder+"frames.csv",FileAccess.WRITE)
	log.store_line("frame,seconds,wound_error")
	var captures:Array[Image]=[]
	var start:=Time.get_ticks_msec()
	var saw_effect:=false
	for i in 300:
		await get_tree().create_timer(0.075).timeout
		await RenderingServer.frame_post_draw
		captures.append(stage.view3d.get_texture().get_image())
		var error:=0.0
		var effect:Node=stage.court_set.get_node_or_null("WoundFlow" if method=="behead" else "BodyFire")
		if effect!=null:
			saw_effect=true
			if method=="behead":error=effect.drops.global_position.distance_to(effect.source.global_position)
			if error>0.03:_fail("blood is detached from the visible stump")
		log.store_line("%d,%.3f,%.5f" % [i,float(Time.get_ticks_msec()-start)/1000.0,error])
		if stage.exec_done and i>30:break
	for i in captures.size():captures[i].save_png(folder+"frame_%04d.png" % i)
	if not saw_effect:_fail("execution never created the requested effect")
	stage.skip_execution()
	await _frames(3)
	if stage.court_set.get_node_or_null("WoundFlow")!=null or stage.court_set.get_node_or_null("BodyFire")!=null:_fail("effects survived skip/end")
	print("EXECUTION_EFFECTS_PREVIEW ",method," PASS" if failures.is_empty() else " FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)

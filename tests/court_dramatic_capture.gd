extends "res://tests/audience_modal_probe.gd"
## Private actual-modal replay. Events explicitly supply fixture adjudication;
## no new outcome or balance rule is introduced by the presentation layer.
## Run --year=1400 or --year=3000; --reduced tests static accessible framing.
const Reference:=preload("res://tests/court_eval/progression_fixture.gd")
const Motion:=preload("res://scripts/hud/motion.gd")

func _ready()->void:
	capture=DisplayServer.get_name()!="headless"
	var year:=3000
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--year="):year=int(arg.trim_prefix("--year="))
		if arg=="--reduced":Motion.reduce_motion=true
	out_dir=ProjectSettings.globalize_path("res://reports/court_dramatic/%d%s/" % [year,"-reduced" if Motion.reduce_motion else ""])
	DirAccess.make_dir_recursive_absolute(out_dir)
	_setup_world()
	GameState.elapsed_days=year*365.0;GameState.known_discoveries.assign(Reference.known_at(year))
	get_window().size=Vector2i(1280,720);get_window().content_scale_size=Vector2i(1280,720)
	var terrain:=TerrainDouble.new();add_child(terrain)
	var director:=Director.new();director.terrain=terrain;add_child(director);director.voice.force_offline=true
	var audience:=Hall.debug_force("petition")
	var modal:Control=director.open_audience(String(audience.id))
	await _wait_scene(modal,String(audience.id),1)
	var stage:Control=modal.court_stage
	stage.settle();stage.frame_cast(0.0)
	await _frames(12)
	var overlay:=CanvasLayer.new();add_child(overlay)
	var label:=Label.new();overlay.add_child(label);label.position=Vector2(24,12)
	label.add_theme_font_size_override("font_size",16);label.add_theme_color_override("font_color",Color.WHITE)
	label.add_theme_color_override("font_shadow_color",Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x",2);label.add_theme_constant_override("shadow_offset_y",2)
	Engine.max_fps=30
	var start:float=stage._now();var sent:=0;var frame:=0;var frames:Array=[];var phases:Array=[]
	while stage._now()-start<24.0:
		var t:float=stage._now()-start
		if sent==0:
			stage.say("main","The council has heard our report. We ask you to listen.")
			label.text="Ordinary audience";sent=1
		elif sent==1 and t>=2.0:
			stage.god_says("You have been heard. Speak plainly.")
			label.text="Address: anticipation, one move, then stillness";sent=2
		elif sent==2 and t>=8.0:
			stage.god_says("Your service has pleased me.")
			stage.event("divine",{"action":"bless","target":"main","response":"blessed"})
			label.text="Favour: fixture response is blessed";sent=3
		elif sent==3 and t>=14.0:
			stage.god_says("You will answer for this.")
			stage.event("divine",{"action":"terrify","target":"main","response":"cower"})
			label.text="Wrath: fixture response is cower; full body stays in frame";sent=4
		elif sent==4 and t>=21.0:
			stage.say("main","I have heard you.")
			label.text="New speech: old camera callbacks cannot return";sent=5
		if phases.size()<sent:phases.append({"phase":sent,"time":t,"label":label.text})
		var row:={"time":stage._now()-start,"phase":sent,"shot":stage._shot_name,"moving":stage.rig.is_moving(),"position":str(stage.camera.global_position),"fov":stage.camera.fov}
		if Motion.reduce_motion and stage.rig.is_moving():_fail("reduced motion camera moved")
		if capture:
			await RenderingServer.frame_post_draw
			var filename:="frame_%04d.jpg" % frame
			get_viewport().get_texture().get_image().save_jpg(out_dir.path_join(filename),0.96)
			row["file"]=filename
		frames.append(row);frame+=1
		await _frames(1)
	var file:=FileAccess.open(out_dir.path_join("timing.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"frames":frames,"duration":stage._now()-start,"phases":phases,"reduced_motion":Motion.reduce_motion},"\t"));file.close()
	var compressed:=frames.any(func(row:Dictionary)->bool:return row.shot=="push_in" and not row.moving)
	if not compressed:_fail("no composed camera hold")
	print("COURT_DRAMATIC %s frames=%d phases=%d" % ["PASS" if failures.is_empty() and sent==5 else "FAIL",frame,sent])
	get_tree().quit(0 if failures.is_empty() and sent==5 else 1)

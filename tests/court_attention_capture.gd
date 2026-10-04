extends "res://tests/audience_modal_probe.gd"
## Actual audience roster and room. Private diagnostic only; no player launch.
## Frames carry real elapsed times in timing.json for normal-speed playback.
const Reference:=preload("res://tests/court_eval/progression_fixture.gd")
const Acting:=preload("res://scripts/hud/court_acting.gd")

func _ready()->void:
	capture=DisplayServer.get_name()!="headless"
	out_dir=ProjectSettings.globalize_path("res://reports/court_attention/")
	DirAccess.make_dir_recursive_absolute(out_dir)
	_setup_world()
	GameState.elapsed_days=3000*365.0
	GameState.known_discoveries.assign(Reference.known_at(3000))
	get_window().size=Vector2i(1600,900);get_window().content_scale_size=Vector2i(1600,900)
	var terrain:=TerrainDouble.new();add_child(terrain)
	var director:=Director.new();director.terrain=terrain;add_child(director)
	director.voice.force_offline=true
	var audience:=Hall.debug_force("petition")
	var modal:Control=director.open_audience(String(audience.id))
	await _wait_scene(modal,String(audience.id),1)
	var stage:Control=modal.court_stage
	stage.settle();stage.frame_cast(0.0)
	await _frames(12)
	var people:Array[String]=[]
	for key:String in stage.cast_order:
		if key!="main" and stage.figure(key)!=null:people.append(key)
	if people.size()<2:
		printerr("COURT_ATTENTION FAIL insufficient listeners");get_tree().quit(1);return
	var overlay:=CanvasLayer.new();add_child(overlay)
	var label:=Label.new();overlay.add_child(label)
	label.position=Vector2(24,18);label.add_theme_font_size_override("font_size",20)
	label.add_theme_color_override("font_color",Color.WHITE)
	label.add_theme_color_override("font_shadow_color",Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x",2);label.add_theme_constant_override("shadow_offset_y",2)
	Engine.max_fps=30
	var start:float=stage._now()
	var sent:=0;var frame:=0;var frames:Array=[]
	while stage._now()-start<10.0:
		var t:float=stage._now()-start
		if sent==0:
			stage.say("main","The council has heard our report. We ask you to listen.")
			label.text="Petitioner speaks — listeners notice in sequence";sent=1
		elif sent==1 and t>=2.7:
			stage._beat({"who":people[1],"act":"look_at","args":{"target":"away","dur":1.2}})
			label.text="A brief glance, then a different speaker";sent=2
		elif sent==2 and t>=3.0:
			stage.say(people[0],"We can explain the proposal. Let us take it one step at a time.")
			label.text="Official speaks — old attention yields";sent=3
		elif sent==3 and t>=6.3:
			stage.god_says("You have been heard. Continue.")
			label.text="The god speaks — one staggered response, then quiet recovery";sent=4
		if capture:
			await RenderingServer.frame_post_draw
			var filename:="frame_%04d.jpg" % frame
			get_viewport().get_texture().get_image().save_jpg(out_dir.path_join(filename),0.97)
			frames.append({"file":filename,"time":stage._now()-start})
		frame+=1
		await _frames(1)
	var file:=FileAccess.open(out_dir.path_join("timing.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"frames":frames,"duration":stage._now()-start,"speakers":["main",people[0],"god"]},"\t"));file.close()
	print("COURT_ATTENTION PASS frames=%d phases=%d" % [frame,sent])
	get_tree().quit(0 if sent==4 else 1)

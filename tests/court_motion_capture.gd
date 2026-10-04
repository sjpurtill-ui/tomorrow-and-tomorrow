extends "res://tests/audience_modal_probe.gd"
## Private GPU review of the real court's entrances, spoken interruptions and
## storm exits. Run through tools/run_isolated_gpu_probe.ps1; no saves or APIs.

const Backdrop:=preload("res://scripts/hud/court_backdrop.gd")
const Stage:=preload("res://scripts/hud/court_stage.gd")

func _ready()->void:
	capture=DisplayServer.get_name()!="headless"
	_setup_world()
	var terrain:=TerrainDouble.new();terrain.name="TerrainDouble";add_child(terrain)
	var director:=Director.new();director.terrain=terrain;add_child(director)
	director.voice.force_offline=true
	await _frames(2)
	get_window().size=Vector2i(1536,864)
	get_window().content_scale_size=Vector2i(1536,864)
	for tier in [0,1]:
		Backdrop.tier_override=tier
		var audience:=Hall.debug_force("petition")
		if audience.is_empty():_fail("no petition");continue
		var id:=String(audience.id)
		var modal:Control=director.open_audience(id)
		await _wait_scene(modal,id,1)
		var stage:Control=modal.court_stage
		stage.settle()
		var person:Stage.Figure=stage.figure(Stage.MAIN)
		person.enter_from(-1.0,1.0)
		# Diagnostic framing includes the doorway and the feet for gait review.
		# It is deliberately wider than the player's conversation camera.
		var points:=PackedVector3Array()
		for local in person._path:
			var foot:=person.spot.to_global(local)
			points.append(foot+Vector3(-0.4,0.0,0.0))
			points.append(foot+Vector3(0.4,person.body3d.body_height+0.2,0.0))
		stage.rig.frame_points(points)
		await _record(stage,"tier%d-enter" % tier,12)
		stage.say(Stage.MAIN,"I am coming to answer you.",true)
		await _record(stage,"tier%d-answer" % tier,24)
		stage.settle()
		person.leave(-1.0,1.0,0.0,"storm")
		await _record(stage,"tier%d-storm" % tier,36)
		stage.settle()
		if person.body3d.visible:_fail("departed person still visible")
		modal.queue_free()
		await _frames(3)
	Backdrop.tier_override=-1
	print("COURT_MOTION_CAPTURE PASS" if failures.is_empty() else "COURT_MOTION_CAPTURE FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)

func _record(stage:Control,tag:String,count:int)->void:
	var folder:=ProjectSettings.globalize_path("res://reports/court_motion/"+tag)
	if capture:DirAccess.make_dir_recursive_absolute(folder)
	for i in count:
		await get_tree().create_timer(1.0/12.0).timeout
		if capture:
			await RenderingServer.frame_post_draw
			stage.view3d.get_texture().get_image().save_png(folder+"/f%04d.png" % i)

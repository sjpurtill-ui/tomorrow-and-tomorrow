extends "res://tests/audience_modal_probe.gd"
## An execution at court, end to end, for review: the real Court modal and
## engine; the god gives the order from the "Put to death" menu; the engine
## decides; the hall shows it done (court_executions.gd, the director's
## scene, court_exec_stage.gd).
##   --only=club|behead|dogs|...   the method the god asks for
##   --tier=0|1                    the fire circle (0) or the longhouse (1)
## For the review reel the people here are given bronze (the axe) so the
## three-swing beheading can play in either hall. Windowed on a private
## desktop with Godot's movie writer (--write-movie <dir>/f.png --fixed-fps
## 12). Presentation only: the engine decides who dies.

const Backdrop:=preload("res://scripts/hud/court_backdrop.gd")
const Executions:=preload("res://scripts/hud/court_executions.gd")

var only:="club"
var tier:=0
var frame_dir:=""
var frame_index:=0
var review_stage:Control

func _ready()->void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):only=arg.trim_prefix("--only=")
		if arg.begins_with("--tier="):tier=int(arg.trim_prefix("--tier="))
		if arg=="--capture-frames":frame_dir="res://reports/court_execution_review/"
	capture=DisplayServer.get_name()!="headless"
	if not frame_dir.is_empty():
		frame_dir=ProjectSettings.globalize_path(frame_dir+"%s-tier%d/" % [only,tier])
		DirAccess.make_dir_recursive_absolute(frame_dir)
	Backdrop.tier_override=tier
	_setup_world()
	if only=="behead" and not GameState.known_discoveries.has("bronze_alloying"):GameState.known_discoveries.append("bronze_alloying")
	var terrain:=TerrainDouble.new();terrain.name="TerrainDouble";add_child(terrain)
	var director:=Director.new();director.terrain=terrain;add_child(director)
	if "force_offline" in director.voice:director.voice.force_offline=true
	await _frames(2)
	if capture:
		get_window().size=Vector2i(1536,864);get_window().content_scale_size=Vector2i(1536,864)
		await _frames(3)
	HudTokens.set_color_mode("light")
	await _execute(director)
	print("COURT_EXECUTION_CLIP PASS" if failures.is_empty() else "COURT_EXECUTION_CLIP FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)

func _wait(seconds:float)->void:
	if frame_dir.is_empty() or not capture:
		await get_tree().create_timer(seconds).timeout
		return
	var deadline:=Time.get_ticks_msec()+int(seconds*1000.0)
	while Time.get_ticks_msec()<deadline:
		await get_tree().create_timer(0.25).timeout
		if is_instance_valid(review_stage):
			await RenderingServer.frame_post_draw
			review_stage.view3d.get_texture().get_image().save_png(frame_dir+"frame_%04d.png" % frame_index)
			frame_index+=1

func _execute(director:Node)->void:
	var audience:=Hall.debug_force("petition")
	if audience.is_empty():_fail("no petition");return
	var id:=String(audience.id)
	var modal:Control=director.open_audience(id)
	await _wait_scene(modal,id,1)
	review_stage=modal.court_stage
	print("MARK opened")
	await _wait(4.0)
	var name:=String((Hall.find(id).get("speaker",{}) as Dictionary).get("name",""))
	var order:="Put %s to death %s." % [name,String(Executions.ORDER_WORDS.get(only,"before the court"))]
	print("MARK order ",order)
	var result:Dictionary=modal.office_order(order)
	print("ORDER executed=",result.get("executed",false)," removed=",result.get("removed",false)," verb=",result.get("verb",""))
	if not bool(result.get("removed",false)):
		await _wait(2.0)
		result=modal.office_order("I said it: "+order)
		print("ORDER again executed=",result.get("executed",false)," removed=",result.get("removed",false))
	await _wait(2.0)
	print("EXEC method=",modal.court_stage.exec_method if is_instance_valid(modal.court_stage) else "")
	await _wait(16.5)
	print("MARK end")
	if not frame_dir.is_empty():print("COURT_EXECUTION_REVIEW wrote ",frame_index," frames to ",frame_dir)

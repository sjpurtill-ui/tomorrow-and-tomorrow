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
const Acting:=preload("res://scripts/hud/court_acting.gd")

var only:="club"
var tier:=0
var frame_dir:=""
var frame_index:=0
var review_stage:Control
var saw_execution:=false
var seen_things:Dictionary={}
var checked_marks:Dictionary={}
var bad_marks:Dictionary={}

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
	var deadline:=Time.get_ticks_msec()+int(seconds*1000.0)
	while Time.get_ticks_msec()<deadline:
		await get_tree().create_timer(0.25).timeout
		if is_instance_valid(review_stage):
			var current:Node=review_stage.get_node_or_null("Execution")
			if current!=null:
				saw_execution=true
				for key in current._things:seen_things[key]=true
				_check_plan_marks(current)
			if not frame_dir.is_empty() and capture:
				await RenderingServer.frame_post_draw
				review_stage.view3d.get_texture().get_image().save_png(frame_dir+"frame_%04d.png" % frame_index)
				frame_index+=1

func _check_plan_marks(current:Node)->void:
	# A split alone is not proof of staging: a failed route can leave the
	# executioner swinging several metres away while the victim still splits.
	for role:String in current._plan.get("roles",{}):
		if role=="victim":continue
		var key:=String(current._plan_keys.get(role,""))
		var body:Node3D=current.call("_body",key)
		if body==null:continue
		var actor=Acting.of(body)
		if actor==null or actor._a==null:continue
		if not String(actor._a.clip).begins_with("exec_") or float(actor._a.t)<1.6:continue
		var expected:Vector3=current.call("_plan_at",current._plan.roles[role].at)
		var error:=Vector2(body.global_position.x-expected.x,body.global_position.z-expected.z).length()
		checked_marks[role]=true
		if error>0.25 and not bad_marks.has(role):
			bad_marks[role]=error
			_fail("%s performs %.2f m away from its authored mark" % [role,error])

func _execute(director:Node)->void:
	var audience:=Hall.debug_force("petition")
	if audience.is_empty():_fail("no petition");return
	var id:=String(audience.id)
	var modal:Control=director.open_audience(id)
	await _wait_scene(modal,id,1)
	review_stage=modal.court_stage
	print("MARK opened")
	await _wait(4.0)
	# This diagnostic reviews the full scene without changing saved preferences.
	Executions.gore="full"
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
	# Entering cast members can delay the first beat. Wait for the actual end,
	# then record recovery as well, instead of truncating a longer arrival.
	var finish_deadline:=Time.get_ticks_msec()+30000
	while not bool(review_stage.exec_done) and Time.get_ticks_msec()<finish_deadline:
		await _wait(0.25)
	await _wait(3.0)
	print("MARK end")
	print("EXEC REVIEW saw_execution=",saw_execution," done=",review_stage.exec_done," things=",seen_things.keys())
	if not saw_execution:_fail("the order never started an execution")
	if not bool(review_stage.exec_done):_fail("the execution never finished")
	if only in ["club","behead"] and not seen_things.has("head:main"):_fail("the execution never reached its impact")
	if only in ["club","behead"] and not checked_marks.has("executioner"):_fail("the executioner's authored performance was not observed")
	if only=="club" and not checked_marks.has("cook"):_fail("the cook's authored performance was not observed")
	if not frame_dir.is_empty():print("COURT_EXECUTION_REVIEW wrote ",frame_index," frames to ",frame_dir)

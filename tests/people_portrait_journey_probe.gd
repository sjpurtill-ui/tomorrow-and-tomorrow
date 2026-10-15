extends "res://tests/own_town_capture.gd"
## Actual HUD proof for the portrait screen. Private desktop and isolated data only.
const ROLES:=["Food","Survey","Extraction","Construction","Crafting","Logistics","Knowledge","Administration","Defense"]
const Manual=preload("res://scripts/manual_work.gd")
const Shares=preload("res://scripts/hud/people_workforce_cast.gd")
var failures:Array[String]=[]
var checks:=0
var art_case:="early"
var art_mode:="dark"
var capture_prefix:="portrait"
var audit_terrain:Node
var geometry_only:=false

func _ready()->void:
	if not "Test" in OS.get_user_data_dir():push_error("Portrait probe requires isolated Test data");get_tree().quit(2);return
	get_tree().create_timer(240.0).timeout.connect(func():get_tree().quit(3))
	for argument:String in OS.get_cmdline_user_args():
		if argument.begins_with("--case="):art_case=argument.trim_prefix("--case=")
		elif argument.begins_with("--mode="):art_mode=argument.trim_prefix("--mode=")
		elif argument.begins_with("--prefix="):capture_prefix=argument.trim_prefix("--prefix=")
		elif argument=="--geometry-only":geometry_only=true
	var config:=ConfigFile.new();config.set_value("display","visual_system",1);config.set_value("display","color_theme",art_mode);config.save("user://display.cfg")
	_world("late" if art_case=="mature" else "early")
	GameState.civic_api_enabled=false;GameState.select_founding_focus("provision");PeopleDirection.choose("makers")
	get_window().size=Vector2i(1600,1000);get_window().content_scale_size=Vector2i(1600,1000)
	audit_terrain=load("res://local_terrain.tscn").instantiate();audit_terrain.set("suppress_naming_prompt",true);add_child(audit_terrain)
	await _frames(50);audit_terrain.call("_set_game_speed",0)
	for director:Node in get_tree().get_nodes_in_group("court_director"):director.set_process(false)
	if is_instance_valid(PeopleDirection.panel):PeopleDirection.panel.queue_free()
	if is_instance_valid(audit_terrain.get("settlement_naming_panel")):audit_terrain.get("settlement_naming_panel").queue_free()
	await _frames(10)
	var hud:Control=audit_terrain.get("hud")
	var center:Vector3=GameState.settlement_founded_at
	var land:=func(point:Vector2)->bool:return bool(audit_terrain.call("_settlement_stage_land_at",point+Vector2(center.x,center.z)))
	audit_terrain.call("_organic_town_plan",center,land);await _frames(4)
	var fabric_before:=var_to_bytes([GameState.settlement_plots,GameState.settlement_routes])
	hud.section_requested.emit("overview",0);hud.force_dock_layout();await _frames(20)
	var board:Control=hud.dock.find_child("CivilizationPeopleScreen",true,false)
	_expect(board!=null,"Actual provider opens portrait People screen")
	if board==null:get_tree().quit(1);return
	_expect(board.settlement_view.get_script().resource_path.ends_with("people_town_portrait_view.gd"),"Production uses new portrait renderer")
	_expect(board.settlement_view.texture!=null,"Actual portrait asset loaded")
	var stage_info:Dictionary=board.settlement_view.portrait_stage()
	if not geometry_only:_expect(String(stage_info.get("id",""))==("town" if art_case=="mature" else "camp"),"Population selects the appropriate portrait stage")
	_expect(int(board.data.settlement_view.population)==(2400 if art_case=="mature" else 93),"Portrait population is actual full population")
	_expect(not board.figure_legend.visible and board.figure_legend.text.is_empty(),"No obsolete hundred-figure claim")
	_expect(board.settlement_view.workforce_people().is_empty(),"Portrait creates no walking cast")
	await _capture("overview-wide");_check_layout(board,"wide overview");_check_markers(board,"wide")
	var original:Dictionary=GameState.population_allocations.duplicate(true)
	var original_mode:bool=PeopleDirection.automatic_work
	for role:String in ROLES:
		var marker:Button=board.markers[role].button
		await _click(marker.get_global_rect().get_center());await _settle(board)
		_expect(board.active_role==role and board.settlement_view.focused_role==role,"Actual area control selects "+role)
		_check_layout(board,role)
		_expect(GameState.population_allocations==original and PeopleDirection.automatic_work==original_mode,"Reading area does not change work: "+role)
		if role in ["Food","Crafting","Knowledge"]:await _capture(role.to_lower()+"-wide")
		await _click(board.overview_button.get_global_rect().get_center());await _settle(board)
		_expect(board.active_role=="","Whole town returns from "+role)
	# Real image hotspot, distinct from the overlaid label button.
	var image_point:=_exposed_hotspot(board,"Knowledge")
	_expect(image_point.x>=0,"Image has a clickable Learning area outside its label")
	if image_point.x>=0:await _click(board.settlement_view.global_position+image_point)
	await _settle(board)
	_expect(board.active_role=="Knowledge","Photograph work area resolves to its role")
	board.settlement_view.pan_view(Vector2(12,6));await _frames(20)
	var current_share:int=Manual.percents().Knowledge
	var fixed_button:Rect2=board.five_button.get_global_rect()
	var fixed_portrait:Rect2=board.settlement_view.get_global_rect()
	var fixed_sidebar:Rect2=board.sidebar.get_global_rect()
	var fixed_navigation:Dictionary=board.settlement_view.navigation_state()
	var fixed_scroll:int=hud.dock.body_scroll.scroll_vertical
	await _click(fixed_button.get_center());await _frames(10)
	_expect(int(Manual.percents().Knowledge)==current_share+5,"A real +5 click applies immediately")
	_expect(not PeopleDirection.automatic_work,"Immediate adjustment takes original manual control")
	_expect(board.find_child("ApplyWorkDraft",true,false)==null and board.find_child("CancelWorkDraft",true,false)==null,"No redundant Apply or Cancel")
	for click in 3:await _click(board.increase_button.get_global_rect().get_center())
	await _frames(8)
	_expect(int(Manual.percents().Knowledge)==current_share+8,"Three rapid clicks retain every percentage-point command")
	_expect(board.five_button.get_global_rect()==fixed_button,"Allocation button never shifts")
	_expect(board.settlement_view.get_global_rect()==fixed_portrait and board.sidebar.get_global_rect()==fixed_sidebar,"Portrait and sidebar bounds remain fixed")
	_expect(board.settlement_view.navigation_state()==fixed_navigation,"Allocation preserves portrait zoom and pan")
	_expect(hud.dock.body_scroll.scroll_vertical==fixed_scroll,"Allocation preserves actual dock scroll")
	_check_counts(board);await _capture("knowledge-after-clicks-wide")
	current_share=int(Manual.percents().Knowledge);GameState.elapsed_days+=1;hud.live_refresh_dock();await _frames(8)
	await _click(board.decrease_button.get_global_rect().get_center());await _frames(8)
	_expect(int(Manual.percents().Knowledge)==current_share-1,"A later click captures the current day even when headcounts round unchanged")
	_check_counts(board)
	get_window().size=Vector2i(1024,720);get_window().content_scale_size=Vector2i(1024,720);hud.force_dock_layout();await _frames(15)
	_check_layout(board,"narrow Learning");await _capture("knowledge-narrow")
	await _click(board.overview_button.get_global_rect().get_center());await _settle(board)
	_check_markers(board,"narrow");await _capture("overview-narrow")
	await _click((board.markers.Food.button as Button).get_global_rect().get_center());await _settle(board)
	_check_layout(board,"narrow Food");await _capture("food-narrow")
	fixed_button=board.increase_button.get_global_rect();fixed_navigation=board.settlement_view.navigation_state();fixed_scroll=hud.dock.body_scroll.scroll_vertical
	await _click(fixed_button.get_center());await _frames(10)
	_expect(board.increase_button.get_global_rect()==fixed_button,"Narrow click retains button position")
	_expect(board.settlement_view.navigation_state()==fixed_navigation and hud.dock.body_scroll.scroll_vertical==fixed_scroll,"Narrow click retains photo and scroll")
	await _check_population_images(board)
	get_window().size=Vector2i(2869,1337);get_window().content_scale_size=Vector2i(2869,1337);hud.force_dock_layout();await _frames(15)
	await _click(board.overview_button.get_global_rect().get_center());await _settle(board)
	_check_layout(board,"ultrawide overview");_check_markers(board,"ultrawide");await _capture("overview-ultrawide")
	_expect(var_to_bytes([GameState.settlement_plots,GameState.settlement_routes])==fabric_before,"Portrait and allocations preserve recorded town fabric")
	print("PEOPLE_PORTRAIT_JOURNEY ",checks," checks; failures: ",failures)
	# Stop only this isolated fixture's background sampler before autoload teardown.
	PlanetEnvironment.set_macro_bake_enabled(false)
	audit_terrain.queue_free();await _frames(2)
	get_tree().quit(0 if failures.is_empty() else 1)

func _check_population_images(board:Control)->void:
	var original:Dictionary=board.data.duplicate(true)
	var navigation:Dictionary=board.settlement_view.navigation_state()
	var button:Rect2=board.increase_button.get_global_rect()
	var actual_population:int=GameState.population_total
	for sample:Dictionary in [{"population":93,"id":"camp"},{"population":150,"id":"hearth"},{"population":400,"id":"village"},{"population":1500,"id":"town"},{"population":6000,"id":"large_town"}]:
		var updated:=original.duplicate(true);updated.settlement_view.population=int(sample.population)
		board.update_block(updated);await _frames(3)
		_expect(board.settlement_view.portrait_stage().id==sample.id,"Real population-tier artwork loads: "+String(sample.id))
		_expect(board.settlement_view.texture!=null,"Population-tier texture is present: "+String(sample.id))
		_expect(board.settlement_view.navigation_state()==navigation and board.increase_button.get_global_rect()==button,"Artwork growth preserves photo navigation and controls: "+String(sample.id))
	board.update_block(original);await _frames(3)
	_expect(int(GameState.population_total)==actual_population,"Portrait tier changes never write population")
func _settle(board:Control)->void:
	# Private GPU frame rate is uncapped; a frame count is not an animation duration.
	var deadline:=Time.get_ticks_msec()+2400
	while Time.get_ticks_msec()<deadline:
		var state:Dictionary=board.settlement_view.navigation_state()
		var center:Vector2=state.center;var desired:Vector2=state.desired_center
		if center.is_equal_approx(desired) and is_equal_approx(float(state.zoom),float(state.desired_zoom)):break
		await get_tree().process_frame
	await _frames(2)
func _frames(count:int)->void:
	for frame in count:await get_tree().process_frame
func _click(at:Vector2)->void:
	for pressed:bool in [true,false]:
		var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;event.position=at;event.global_position=at;get_viewport().push_input(event,true)
		await get_tree().process_frame
func _expect(ok:bool,description:String)->void:
	checks+=1
	if not ok:failures.append(description);push_error(description)
func _exposed_hotspot(board:Control,role:String)->Vector2:
	var image:Rect2=board.settlement_view.visible_image_rect()
	for y in range(int(image.position.y)+4,int(image.end.y)-4,6):
		for x in range(int(image.position.x)+4,int(image.end.x)-4,6):
			var point:=Vector2(x,y)
			if board.settlement_view.role_at(point)!=role:continue
			var blocked:=false
			for marker:Dictionary in board.markers.values():
				if (marker.node as Control).get_rect().has_point(point):blocked=true;break
			if not blocked and not board.navigation_surface.get_rect().has_point(point):return point
	return Vector2(-1,-1)
func _check_counts(board:Control)->void:
	var counts:Dictionary={}
	for task:Dictionary in board.data.labor.tasks:counts[String(task.id)]=int(task.count)
	_expect(board.settlement_view.workforce_percentages()==Shares.apportion(counts),"Displayed percentages use actual effective headcounts")
	_expect(not board._showing_preview,"Displayed work is current, not a staged draft")
func _check_markers(board:Control,label:String)->void:
	_expect(board.markers.size()==9,"All nine areas reachable: "+label)
	var rectangles:Array[Rect2]=[]
	for role:String in ROLES:
		var marker:Control=board.markers[role].node;var rectangle:=marker.get_global_rect()
		_expect(marker.is_visible_in_tree() and board.settlement_view.get_global_rect().encloses(rectangle),"Area pill stays in portrait: "+label+" "+role)
		for other:Rect2 in rectangles:_expect(not rectangle.intersects(other),"Area pills do not collide: "+label+" "+role)
		rectangles.append(rectangle)
func _check_layout(board:Control,label:String)->void:
	var sidebar:Rect2=board.sidebar.get_global_rect();var portrait:Rect2=board.settlement_view.get_global_rect()
	_expect(not sidebar.intersects(portrait),"Sidebar never covers portrait: "+label)
	_expect(portrait.size.x>sidebar.size.x,"Portrait remains primary: "+label)
	_expect(sidebar.end.y<=get_viewport().get_visible_rect().size.y+1,"Sidebar fits viewport: "+label)
	_expect(sidebar.encloses(board.food_back.get_global_rect()),"Food and warnings fit sidebar: "+label)
	if not board.active_role.is_empty():
		_expect(sidebar.encloses(board.focus_panel.get_global_rect()) and sidebar.encloses(board.evidence_panel.get_global_rect()),"Assignment and effects fit sidebar: "+label)
		_expect(not board.focus_panel.get_global_rect().intersects(board.evidence_panel.get_global_rect()),"Assignment and metrics stay separate: "+label)
		_expect(not board.evidence_panel.get_global_rect().intersects(board.food_back.get_global_rect()),"Metrics and food stay separate: "+label)
func _capture(label:String)->void:
	await RenderingServer.frame_post_draw
	var folder:="res://artifacts/popup-audit/people-portrait/"+capture_prefix+"-"+art_case+"-"+art_mode
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	get_viewport().get_texture().get_image().save_png(folder.path_join(label+".png"))

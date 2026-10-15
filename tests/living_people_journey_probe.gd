extends "res://tests/own_town_capture.gd"
## Private integration journey through the actual terrain, HUD and provider.
## No player save is read or written. Run only on the isolated test desktop.
const ROLES:=["Food","Survey","Extraction","Construction","Crafting","Logistics","Knowledge","Administration","Defense"]
var failures:Array[String]=[]
var checks:=0
var audit_terrain:Node
var art_case:="early"
var art_mode:="dark"
var capture_prefix:="illustrated"

func _ready()->void:
	if not "Test" in OS.get_user_data_dir():
		push_error("Living People probe requires isolated Test user data");get_tree().quit(2);return
	get_tree().create_timer(240.0).timeout.connect(func():get_tree().quit(3))
	for argument:String in OS.get_cmdline_user_args():
		if argument.begins_with("--case="):art_case=argument.trim_prefix("--case=")
		elif argument.begins_with("--mode="):art_mode=argument.trim_prefix("--mode=")
		elif argument.begins_with("--prefix="):capture_prefix=argument.trim_prefix("--prefix=")
	# Terrain creates DisplayPreferences, which reloads the isolated config.
	# Set that source before it builds any actual HUD controls.
	var display_config:=ConfigFile.new()
	display_config.set_value("display","visual_system",1)
	display_config.set_value("display","color_theme",art_mode)
	display_config.save("user://display.cfg")
	_world("late" if art_case=="mature" else art_case)
	GameState.civic_api_enabled=false
	GameState.select_founding_focus("provision");PeopleDirection.choose("makers")
	if art_case=="mature":_prepare_mature_fabric()
	get_window().size=Vector2i(1600,1000);get_window().content_scale_size=Vector2i(1600,1000)
	audit_terrain=load("res://local_terrain.tscn").instantiate();audit_terrain.set("suppress_naming_prompt",true);add_child(audit_terrain)
	await _frames(50);audit_terrain.call("_set_game_speed",0)
	# The stale-day check below must not launch an unrelated envoy over captures.
	for director:Node in get_tree().get_nodes_in_group("court_director"):
		director.set_process(false)
	if is_instance_valid(PeopleDirection.panel):PeopleDirection.panel.queue_free()
	if is_instance_valid(audit_terrain.get("settlement_naming_panel")):audit_terrain.get("settlement_naming_panel").queue_free()
	await _frames(10)
	var hud:Control=audit_terrain.get("hud")
	# Complete the main map's existing saved-placement writer before taking
	# the read-only baseline. Otherwise an asynchronous map job, unrelated to
	# opening People, publishes visual_building_sites during this journey.
	var center:Vector3=GameState.settlement_founded_at
	var land:=func(point:Vector2)->bool:return bool(audit_terrain.call("_settlement_stage_land_at",point+Vector2(center.x,center.z)))
	audit_terrain.call("_organic_town_plan",center,land)
	await _frames(4)
	_expect(T.is_light()==(art_mode=="light"),"Requested display palette is active")
	var fabric_before:=var_to_bytes([GameState.settlement_plots,GameState.settlement_routes])
	var plots_before:=GameState.settlement_plots.duplicate(true)
	hud.section_requested.emit("overview",0);hud.force_dock_layout();await _frames(12)
	var board:Control=hud.dock.find_child("CivilizationPeopleScreen",true,false)
	_expect(board!=null,"Actual People provider uses the living screen")
	if board==null:get_tree().quit(1);return
	await _capture("overview-wide")
	_check_markers(board,"wide")
	var initial_height:float=board.stage.custom_minimum_size.y
	hud.dock.body_scroll.scroll_vertical=130;await _frames(8)
	_expect(absf(board.stage.custom_minimum_size.y-initial_height)<1.0,"Scrolling does not enlarge the living scene")
	hud.dock.body_scroll.scroll_vertical=0;await _frames(4)
	var original:Dictionary=GameState.population_allocations.duplicate(true)
	var original_mode:bool=PeopleDirection.automatic_work
	for role:String in ROLES:
		hud.focus_people_work(role);await _frames(50)
		board=hud.dock.find_child("CivilizationPeopleScreen",true,false)
		_expect(board!=null,"Category navigation retains actual screen: "+role)
		if board==null:continue
		_expect(String(board.active_role)==role,"Category focused: "+role)
		_expect(String(board.settlement_view.focused_role)==role,"Camera focused: "+role)
		_expect(board.focus_panel.is_visible_in_tree(),"Local work controls visible: "+role)
		_expect(board.focus_panel.get_global_rect().end.x<=get_window().size.x+1,"Local controls stay on screen: "+role)
		_expect(board.stage.get_global_rect().encloses(board.evidence_panel.get_global_rect()),"Consequence graphics remain inside scene: "+role)
		_check_local_annotations(board,role)
		var anchor:Vector2=board.stage.global_position+board.anchors.get(role,Vector2.ZERO)
		_expect(not board.focus_panel.get_global_rect().has_point(anchor) and not board.evidence_panel.get_global_rect().has_point(anchor),"Selected work area is not covered by its controls: "+role)
		_expect(GameState.population_allocations==original and PeopleDirection.automatic_work==original_mode,"Reading work changes no allocation: "+role)
		await _capture(role.to_lower()+"-focus-wide")
		_expect(hud.handle_escape(),"Escape consumed at work focus")
		_expect(hud.dock.visible and String(board.active_role)=="","Escape returns to settlement image: "+role)
	# A real shortage/learning draft: it must remain a proposal until Apply.
	hud.focus_people_work("Knowledge");await _frames(8)
	board=hud.dock.find_child("CivilizationPeopleScreen",true,false)
	var increase:=board.find_child("DraftFive",true,false) as Button
	_expect(increase!=null,"Assignment step exists")
	if increase:
		increase.pressed.emit();await _frames(8)
		_expect(not board.draft_stale,"Learning effects capture is a current proposal")
		_expect(not (board.draft.get("commands",[]) as Array).is_empty(),"Worker change creates draft")
		_expect(GameState.population_allocations==original and PeopleDirection.automatic_work==original_mode,"Preview preserves current workers and delegation")
		await _capture("learning-draft-wide")
		_check_local_annotations(board,"learning draft")
	# Fast-world invalidation must not apply a stale allocation.
	GameState.elapsed_days+=1
	hud.live_refresh_dock();await _frames(6)
	board=hud.dock.find_child("CivilizationPeopleScreen",true,false)
	var apply:=board.find_child("ApplyWorkDraft",true,false) as Button
	if apply:apply.pressed.emit();await _frames(8)
	_expect(GameState.population_allocations==original and PeopleDirection.automatic_work==original_mode,"Stale Apply does not change work")
	var cancel:=board.find_child("CancelWorkDraft",true,false) as Button
	if cancel:cancel.pressed.emit();await _frames(4)
	# Reading a focused area also needs a refresh path as the world advances,
	# even when no worker edit has been proposed.
	GameState.elapsed_days+=1
	hud.live_refresh_dock();await _frames(6)
	board=hud.dock.find_child("CivilizationPeopleScreen",true,false)
	apply=board.find_child("ApplyWorkDraft",true,false) as Button
	_expect(apply!=null and not apply.disabled,"Unchanged stale reading can refresh")
	if apply and not apply.disabled:apply.pressed.emit();await _frames(6)
	_expect(not board.draft_stale,"Refreshing unchanged readings clears stale state")
	_expect(GameState.population_allocations==original and PeopleDirection.automatic_work==original_mode,"Refreshing unchanged readings preserves work and delegation")
	get_window().size=Vector2i(1024,720);get_window().content_scale_size=Vector2i(1024,720)
	hud.force_dock_layout();await _frames(10)
	await _capture("focused-narrow")
	_expect(board.get_global_rect().end.x<=1025,"Narrow People scene fits horizontally")
	_expect(board.focus_panel.get_global_rect().end.x<=1025,"Narrow assignment controls fit horizontally")
	hud.focus_people_work("Food");await _frames(50)
	board=hud.dock.find_child("CivilizationPeopleScreen",true,false)
	await _capture("food-focus-narrow")
	hud.handle_escape();await _frames(6);await _capture("overview-narrow")
	_check_markers(board,"narrow")
	get_window().size=Vector2i(2869,1337);get_window().content_scale_size=Vector2i(2869,1337)
	hud.force_dock_layout();await _frames(16)
	await _capture("overview-ultrawide");_check_markers(board,"ultrawide")
	var available_width:float=hud._dock_width(hud.dock,get_viewport().get_visible_rect().size.x)
	_expect(absf(hud.dock.size.x-available_width)<2,"Illustrated settlement uses the available wide screen")
	hud.focus_people_work("Construction");await _frames(40)
	board=hud.dock.find_child("CivilizationPeopleScreen",true,false)
	await _capture("construction-focus-ultrawide");_check_local_annotations(board,"ultrawide building")
	get_window().size=Vector2i(1024,720);get_window().content_scale_size=Vector2i(1024,720)
	hud.force_dock_layout();await _frames(12)
	_check_local_annotations(board,"repeated narrow resize")
	if var_to_bytes([GameState.settlement_plots,GameState.settlement_routes])!=fabric_before:
		for index in mini(plots_before.size(),GameState.settlement_plots.size()):
			var before:Dictionary=plots_before[index];var after:Dictionary=GameState.settlement_plots[index]
			for key in after:
				if var_to_bytes(before.get(key))!=var_to_bytes(after[key]):print("FABRIC_DIFF ",after.get("id")," ",key)
	_expect(var_to_bytes([GameState.settlement_plots,GameState.settlement_routes])==fabric_before,"Reading and previewing the illustration preserves recorded fabric")
	print("LIVING_PEOPLE_JOURNEY ",checks," checks; failures: ",failures)
	get_tree().quit(0 if failures.is_empty() else 1)

func _frames(count:int)->void:
	for frame in count:await get_tree().process_frame

func _prepare_mature_fabric()->void:
	# Isolated representative state using the existing upgrade writer. The
	# renderer must observe these records; no calendar-based reskin is allowed.
	GameState.known_discoveries.append_array(["clay_shaping","stone_selection"])
	for plot:Dictionary in GameState.settlement_plots:
		if String(plot.get("land_use","")) not in ["residential_compound","mixed_household","workshop","storage","civic"]:continue
		for generation in range(1,5):
			var events:Array[Dictionary]=[]
			SettlementModel._apply_fabric_upgrade({"plot":plot,"next_tier":generation,"cost":SettlementModel._fabric_upgrade_cost(plot,generation)},GameState.elapsed_days,events)
	if GameState.settlement_plots.size()>3:
		GameState.settlement_plots[2].status="under_construction"
		GameState.settlement_plots[2].construction_progress=.58
		GameState.settlement_plots[3].condition=.35
		GameState.settlement_plots[3].damage={"fire":.4}
	GameState.morphology_revision+=1

func _expect(ok:bool,description:String)->void:
	checks+=1
	if not ok:failures.append(description);push_error(description)

func _check_markers(board:Control,label:String)->void:
	_expect(board.markers.size()==9,"All work categories available: "+label)
	var inside:=true;var separate:=true;var rectangles:Array[Rect2]=[]
	for marker:Dictionary in board.markers.values():
		var rectangle:Rect2=(marker.node as Control).get_global_rect()
		inside=inside and board.stage.get_global_rect().encloses(rectangle)
		for other:Rect2 in rectangles:separate=separate and not rectangle.intersects(other)
		rectangles.append(rectangle)
	_expect(inside,"Category controls stay inside the scene: "+label)
	_expect(separate,"Category controls do not overlap: "+label)

func _capture(label:String)->void:
	await RenderingServer.frame_post_draw
	var folder:="res://artifacts/popup-audit/living-people/"+capture_prefix+"-"+art_case+"-"+art_mode
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	get_viewport().get_texture().get_image().save_png(folder.path_join(label+".png"))

func _check_local_annotations(board:Control,label:String)->void:
	var scene:Rect2=board.stage.get_global_rect()
	var action:Rect2=board.focus_panel.get_global_rect()
	var consequence:Rect2=board.evidence_panel.get_global_rect()
	_expect(scene.encloses(action) and scene.encloses(consequence),"Local annotations remain in the scene: "+label)
	_expect(not action.intersects(consequence),"Assignment and consequence remain separate: "+label)
	# Compact bounds supplement the visual review; this does not claim the
	# bounding rectangles measure the visible ink of transparent annotations.
	_expect(action.get_area()+consequence.get_area()<scene.get_area()*.25,"Local controls leave most of the worksite visible: "+label)
	var strip:Control=board.get("food_strip")
	if is_instance_valid(strip) and strip.is_visible_in_tree():
		_expect(scene.encloses(strip.get_global_rect()),"Food cost diagram remains inside the scene: "+label)
		_expect(not action.intersects(strip.get_global_rect()) and not consequence.intersects(strip.get_global_rect()),"Food diagram does not cover local annotations: "+label)

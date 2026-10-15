extends "res://tests/own_town_capture.gd"
## Private integration journey through the actual terrain, HUD and provider.
## No player save is read or written. Run only on the isolated test desktop.
const ROLES:=["Food","Survey","Extraction","Construction","Crafting","Logistics","Knowledge","Administration","Defense"]
var failures:Array[String]=[]
var checks:=0
var audit_terrain:Node

func _ready()->void:
	if not "Test" in OS.get_user_data_dir():
		push_error("Living People probe requires isolated Test user data");get_tree().quit(2);return
	get_tree().create_timer(240.0).timeout.connect(func():get_tree().quit(3))
	_world("early")
	GameState.civic_api_enabled=false
	GameState.select_founding_focus("provision");PeopleDirection.choose("makers")
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
		_expect(not (board.draft.get("commands",[]) as Array).is_empty(),"Worker change creates draft")
		_expect(GameState.population_allocations==original and PeopleDirection.automatic_work==original_mode,"Preview preserves current workers and delegation")
		await _capture("learning-draft-wide")
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
	print("LIVING_PEOPLE_JOURNEY ",checks," checks; failures: ",failures)
	get_tree().quit(0 if failures.is_empty() else 1)

func _frames(count:int)->void:
	for frame in count:await get_tree().process_frame

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
	var folder:="res://artifacts/popup-audit/living-people"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	get_viewport().get_texture().get_image().save_png(folder.path_join(label+".png"))

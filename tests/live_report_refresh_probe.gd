extends Node

const TERRAIN_SCENE:=preload("res://local_terrain.tscn")
var failures:Array[String]=[]


func _ready()->void:
	GameState.reset_for_new_world(190887)
	DiscoverySystem.reset_for_new_world()
	ProgressionSystem.reset_for_new_world()
	ResourceSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	ConsequenceEngine.reset_for_new_world()
	AdvisorSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	var terrain:=TERRAIN_SCENE.instantiate()
	add_child(terrain)
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(terrain.founding_focus_panel and terrain.founding_focus_panel.is_visible_in_tree(),"new-world founding-focus screen did not open")
	_expect(terrain.map_help_panel and not terrain.map_help_panel.visible and terrain.map_help_button and not terrain.map_help_button.visible,"map help remained visible beneath the blocking founding-focus screen")
	terrain._toggle_map_help()
	_expect(not terrain.map_help_panel.visible and not terrain.map_help_button.visible,"map help could be reopened while the founding-focus screen owned interaction")
	# This probe audits reports after the new-world setup choice has been resolved;
	# startup choice overlays are intentionally live-refresh blockers.
	if terrain.founding_focus_panel and is_instance_valid(terrain.founding_focus_panel): terrain.founding_focus_panel.queue_free()
	terrain.founding_focus_panel=null
	if terrain.world_menu_panel and is_instance_valid(terrain.world_menu_panel): terrain.world_menu_panel.queue_free()
	terrain.world_menu_panel=null
	await get_tree().process_frame
	terrain._open_provisions_panel()
	await get_tree().process_frame
	await get_tree().process_frame
	await _expect_stable_refresh(terrain,"provisions")
	_expect(terrain.provisions_panel.find_children("*","ScrollContainer",true,false).is_empty(),"main Provisions dashboard still requires scrolling")
	var columns:=terrain.provisions_panel.find_child("ProvisionDashboardColumns",true,false) as Control
	_expect(columns!=null,"Provisions dashboard columns are missing")
	if columns:
		_expect(columns.get_child_count()==3,"Provisions dashboard does not show stores, daily flow, and consumers together")
		_expect(_inside_viewport(columns,terrain.get_viewport().get_visible_rect()),"Provisions dashboard leaves the supported 1280×720 viewport")
	for required_button in ["OPEN DETAILS & HISTORY","RETURN TO MAP"]:
		var found:=false
		for button in terrain.provisions_panel.find_children("*","Button",true,false):
			if String(button.text)==required_button:
				found=true
				_expect(_inside_viewport(button,terrain.get_viewport().get_visible_rect()),"Provisions '%s' action is outside the viewport" % required_button)
		_expect(found,"Provisions '%s' action is missing" % required_button)
	terrain.provisions_panel.queue_free()
	terrain.provisions_panel=null
	await get_tree().process_frame
	terrain._open_population_ledger()
	await get_tree().process_frame
	GameState.ensure_population_total(GameState.population_total+25)
	await _expect_stable_refresh(terrain,"population")
	terrain.population_ledger_panel.queue_free()
	terrain.population_ledger_panel=null
	await get_tree().process_frame
	terrain._open_council_panel()
	await get_tree().process_frame
	await _expect_stable_refresh(terrain,"council")
	var council_input:LineEdit=null
	for candidate in terrain.council_panel.find_children("*","LineEdit",true,false): council_input=candidate; break
	_expect(council_input!=null,"Council directive field is missing")
	if council_input:
		council_input.text="unfinished directive must survive"
		terrain.live_report_refresh_signatures["council"]=terrain._live_report_signature("council")
		var council_panel_id:int=terrain.council_panel.get_instance_id()
		GameState.elapsed_days+=1.0
		terrain._refresh_live_reports()
		await get_tree().process_frame
		_expect(terrain.council_panel.get_instance_id()==council_panel_id,"Council rebuilt while directive text was in progress")
		_expect(council_input.text=="unfinished directive must survive","Council live refresh erased directive text")
	terrain.council_panel.queue_free()
	terrain.council_panel=null
	await get_tree().process_frame
	terrain._open_materials_panel()
	await get_tree().process_frame
	await _expect_stable_refresh(terrain,"materials")
	_expect(terrain.materials_panel.find_children("*","ScrollContainer",true,false).is_empty(),"main Material Flow dashboard still requires scrolling")
	var material_table:=terrain.materials_panel.find_child("MaterialFlowTable",true,false) as Control
	_expect(material_table!=null and _inside_viewport(material_table,terrain.get_viewport().get_visible_rect()),"Material Flow table is missing or outside the viewport")
	terrain.active_foreign_alert={"alert_key":"first","kind":"first_contact","day":1,"title":"First contact","description":"A bounded test contact was observed."}
	terrain.foreign_alert_queue.clear()
	terrain.foreign_alert_queue.append({"alert_key":"second","kind":"unit_sighting","day":1})
	terrain._render_active_foreign_alert()
	terrain._arbitrate_notification_overlays()
	_expect(not terrain.foreign_alert_panel.visible,"foreign alert remained above the Materials modal")
	_expect(String(terrain.active_foreign_alert.get("alert_key",""))=="first" and terrain.foreign_alert_queue.size()==1,"alert deferral lost or reordered queued events")
	terrain.materials_panel.queue_free()
	terrain.materials_panel=null
	await get_tree().process_frame
	terrain._arbitrate_notification_overlays()
	await get_tree().process_frame
	_expect(terrain.foreign_alert_panel.visible,"deferred foreign alert was not presented after the modal closed")
	_expect(_inside_viewport(terrain.foreign_alert_panel,terrain.get_viewport().get_visible_rect()),"deferred foreign alert is not fully bounded inside the viewport")
	# Every other continuously updating report uses the same stable-root
	# foundation. Each changed signature must synchronously replace contents
	# without replacing or hiding the mounted report root.
	terrain._open_knowledge_panel()
	await get_tree().process_frame
	await get_tree().process_frame
	var research_scroll:ScrollContainer=null
	for scroll_candidate in terrain.knowledge_panel.find_children("*","ScrollContainer",true,false):
		var candidate:=scroll_candidate as ScrollContainer
		if candidate.get_v_scroll_bar().max_value>8.0:
			research_scroll=candidate
			break
	var expected_scroll:=0
	if research_scroll is ScrollContainer:
		research_scroll.scroll_vertical=mini(80,roundi(research_scroll.get_v_scroll_bar().max_value))
		expected_scroll=research_scroll.scroll_vertical
	var focused_research_button:Button=null
	for button_candidate in terrain.knowledge_panel.find_children("*","Button",true,false):
		if String(button_candidate.text)=="+":
			focused_research_button=button_candidate
			focused_research_button.grab_focus()
			break
	await _expect_stable_refresh(terrain,"research")
	var refreshed_research_scroll:ScrollContainer=null
	for scroll_candidate in terrain.knowledge_panel.find_children("*","ScrollContainer",true,false):
		var candidate:=scroll_candidate as ScrollContainer
		if candidate.get_v_scroll_bar().max_value>8.0:
			refreshed_research_scroll=candidate
			break
	if refreshed_research_scroll:
		_expect(abs(refreshed_research_scroll.scroll_vertical-expected_scroll)<=1,"Research report lost its scroll position during live refresh (expected %d, got %d)" % [expected_scroll,refreshed_research_scroll.scroll_vertical])
	var restored_focus:=get_viewport().gui_get_focus_owner() as Button
	_expect(focused_research_button==null or (restored_focus!=null and restored_focus.text=="+"),"Research report lost button focus during live refresh")
	terrain.knowledge_panel.queue_free()
	terrain.knowledge_panel=null
	await get_tree().process_frame
	for report_case in [
		["society","_open_society_panel"],
		["progression","_open_progression_panel"],
		["civilizations","_open_civilizations_panel"]
	]:
		terrain.call(String(report_case[1]))
		await get_tree().process_frame
		await _expect_stable_refresh(terrain,String(report_case[0]))
		var report_panel:=terrain._live_report_panel(String(report_case[0])) as Control
		if report_panel and is_instance_valid(report_panel): report_panel.queue_free()
		terrain._set_live_report_panel(String(report_case[0]),null)
		await get_tree().process_frame
	if failures.is_empty():
		print("LIVE_REPORT_REFRESH_PROBE PASS")
		get_tree().quit(0)
	else:
		for failure in failures: push_error("LIVE_REPORT_REFRESH_PROBE "+failure)
		get_tree().quit(1)


func _inside_viewport(control:Control,viewport_rect:Rect2)->bool:
	var rect:=control.get_global_rect()
	return rect.position.x>=viewport_rect.position.x-1.0 and rect.position.y>=viewport_rect.position.y-1.0 and rect.end.x<=viewport_rect.end.x+1.0 and rect.end.y<=viewport_rect.end.y+1.0


func _expect_stable_refresh(terrain:Node,kind:String)->void:
	var panel:=terrain._live_report_panel(kind) as Control
	_expect(panel!=null and is_instance_valid(panel),"%s report did not open" % kind.capitalize())
	if panel==null or not is_instance_valid(panel): return
	terrain._refresh_live_reports()
	var root_id:=panel.get_instance_id()
	var first_content_id:=panel.get_child(0).get_instance_id() if panel.get_child_count()>0 else 0
	var was_visible:=panel.visible
	GameState.elapsed_days+=1.0
	terrain._refresh_live_reports()
	var refreshed:=terrain._live_report_panel(kind) as Control
	_expect(refreshed!=null and is_instance_valid(refreshed),"%s report disappeared during live refresh" % kind.capitalize())
	if refreshed==null or not is_instance_valid(refreshed): return
	_expect(refreshed.get_instance_id()==root_id,"%s report replaced its visible root during live refresh" % kind.capitalize())
	_expect(refreshed.visible==was_visible and refreshed.is_visible_in_tree(),"%s report toggled visibility during live refresh" % kind.capitalize())
	_expect(refreshed.get_child_count()>0,"%s report was left empty after live refresh" % kind.capitalize())
	await get_tree().process_frame
	await get_tree().process_frame
	refreshed=terrain._live_report_panel(kind) as Control
	_expect(refreshed.get_instance_id()==root_id,"%s report root changed on the frame after live refresh" % kind.capitalize())
	_expect(refreshed.get_child_count()>0,"%s report was empty when its atomic replacement committed" % kind.capitalize())
	if first_content_id!=0 and refreshed.get_child_count()>0:
		_expect(refreshed.get_child(0).get_instance_id()!=first_content_id,"%s report signature changed without updating its contents" % kind.capitalize())


func _expect(condition:bool,message:String)->void:
	if not condition: failures.append(message)

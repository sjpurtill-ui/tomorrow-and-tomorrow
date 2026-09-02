extends Node

const TERRAIN_SCENE:=preload("res://local_terrain.tscn")
const FIT_SCRIPT:=preload("res://scripts/viewport_fit_panel.gd")
var failures:Array[String]=[]


func _ready()->void:
	GameState.reset_for_new_world(810221)
	DiscoverySystem.reset_for_new_world(); ProgressionSystem.reset_for_new_world(); ResourceSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world(); ConsequenceEngine.reset_for_new_world(); AdvisorSystem.reset_for_new_world(); CivilizationSystem.reset_for_new_world()
	var terrain:=TERRAIN_SCENE.instantiate()
	add_child(terrain)
	await get_tree().process_frame; await get_tree().process_frame
	if terrain.founding_focus_panel and is_instance_valid(terrain.founding_focus_panel): terrain.founding_focus_panel.queue_free()
	terrain.founding_focus_panel=null
	await get_tree().process_frame

	terrain._open_settlement_dashboard(); await _audit_after_frames("Settlement",terrain.settlement_dashboard_panel)
	# A fresh-world report is deceptively short. Reproduce a long-running game's
	# demographic and consequence history so data growth cannot turn text into the
	# microscopic block that this probe previously missed.
	var original_demographics:Array=GameState.demographic_ledger.duplicate(true)
	var original_events:Array=GameState.simulation_events.duplicate(true)
	GameState.demographic_ledger.clear(); GameState.simulation_events.clear()
	for history_index in 48:
		GameState.demographic_ledger.append({"kind":"birth" if history_index%3==0 else "death","count":1+(history_index%4),"cause":"Births" if history_index%3==0 else "Age and current conditions","start_day":history_index*40,"end_day":history_index*40+2,"location":"Test settlement","population_after":120+history_index,"description":"A concrete aggregate demographic record preserved for a saturated-screen legibility check.","water_intake_ratio":0.9,"health":0.78,"housing_ratio":0.95})
		GameState.simulation_events.append({"day":history_index*30,"domain":"society","title":"Recorded consequence %d" % history_index,"description":"A wider consequence remains readable without shrinking the entire population report."})
	terrain._open_population_ledger(); await _audit_after_frames("Population",terrain.population_ledger_panel)
	var population_pages:=terrain.population_ledger_panel.find_child("PopulationDetailPages",true,false) as TabContainer
	if population_pages==null or population_pages.get_tab_count()!=3: failures.append("Population does not divide growing history into three readable pages")
	if population_pages:
		for population_control_variant in population_pages.find_children("*","Control",true,false):
			var population_control:=population_control_variant as Control
			if population_control.get_script()==FIT_SCRIPT: failures.append("Population history still uses whole-ledger scaling")
	GameState.demographic_ledger=original_demographics; GameState.simulation_events=original_events
	terrain._open_provisions_panel(); await _audit_after_frames("Provisions",terrain.provisions_panel)
	var provision_details:=_press_named(terrain.provisions_panel,"OPEN DETAILS & HISTORY")
	if provision_details: await _audit_after_frames("Provisions details",terrain.provisions_panel)
	terrain._open_materials_panel(); await _audit_after_frames("Materials",terrain.materials_panel)
	var material_details:=_press_named(terrain.materials_panel,"SOURCE DETAILS")
	if material_details: await _audit_after_frames("Material details",terrain.materials_panel)
	terrain._open_systems_hub(); await _audit_after_frames("Civilization hub",terrain.systems_hub_panel)
	terrain._open_knowledge_panel(); await _audit_after_frames("Research",terrain.knowledge_panel)
	terrain._open_council_panel(); await _audit_after_frames("Council",terrain.council_panel)
	terrain._open_government_panel(); await _audit_after_frames("Leadership",terrain.government_panel)
	terrain._open_advisor_candidates("Steward"); await _audit_after_frames("Institutional slates",terrain.leader_panel)
	terrain._open_society_panel(); await _audit_after_frames("Society",terrain.society_panel)
	terrain._open_values_panel(); await _audit_after_frames("Values",terrain.society_panel)
	terrain._open_progression_panel(); await _audit_after_frames("Progression",terrain.progression_panel)
	terrain._open_civilizations_panel(); await _audit_after_frames("World",terrain.civilizations_panel)
	if not CivilizationSystem.civilizations.is_empty():
		var civ:Dictionary=CivilizationSystem.civilizations[0]
		var relation:Dictionary=civ.get("player_relation",{})
		relation["contact_level"]=2; relation["met_day"]=0; relation["contact_intelligence"]=0.45
		relation["encounter_position"]={"x":CivilizationSystem.player_world_origin.x+22.0,"z":CivilizationSystem.player_world_origin.y+8.0}
		civ["player_relation"]=relation; CivilizationSystem.civilizations[0]=civ; CivilizationSystem._rebuild_competition()
		terrain._open_civilization_report(String(civ.id)); await _audit_after_frames("Foreign intelligence",terrain.civilization_report_panel)
	terrain._open_scout_dispatch_panel(); await _audit_after_frames("Scout dispatch",terrain.scout_dispatch_panel)
	terrain._open_diplomat_dispatch_panel(); await _audit_after_frames("Diplomat dispatch",terrain.diplomat_dispatch_panel)
	terrain._open_world_menu(); await _audit_after_frames("World menu",terrain.world_menu_panel)
	GameState.settlement_site_committed=true
	terrain._open_settlement_naming_panel(); await _audit_after_frames("Settlement naming",terrain.settlement_naming_panel)
	MilitaryCommandUI.modal.show(); await _audit_after_frames("Military command",MilitaryCommandUI.modal)

	if failures.is_empty():
		print("MODAL_FIT_PROBE PASS  •  all screens bounded  •  no scrolling")
		get_tree().quit(0)
	else:
		for failure in failures: push_error("MODAL_FIT_PROBE "+failure)
		get_tree().quit(1)


func _audit_after_frames(label:String,screen:Control)->void:
	await get_tree().process_frame; await get_tree().process_frame
	if screen==null or not is_instance_valid(screen): failures.append(label+" did not open"); return
	for scroll_variant in screen.find_children("*","ScrollContainer",true,false):
		var scroll:=scroll_variant as ScrollContainer
		if scroll.is_visible_in_tree(): failures.append(label+" still contains a visible scrollbar")
	var viewport:=get_viewport().get_visible_rect()
	for button_variant in screen.find_children("*","Button",true,false):
		var button:=button_variant as Button
		if not button.is_visible_in_tree(): continue
		var rect:=button.get_global_rect()
		if rect.position.x<viewport.position.x-1.0 or rect.position.y<viewport.position.y-1.0 or rect.end.x>viewport.end.x+1.0 or rect.end.y>viewport.end.y+1.0:
			failures.append("%s button '%s' is outside the viewport: %s" % [label,button.text,rect])
	for fit_variant in screen.find_children("*","Control",true,false):
		var fit:=fit_variant as Control
		if fit.get_script()!=FIT_SCRIPT: continue
		fit._fit_content()
		if float(fit.effective_scale)<0.42: failures.append("%s requires unreadable %.0f%% scaling; split it into another page" % [label,float(fit.effective_scale)*100.0])
	for label_variant in screen.find_children("*","Label",true,false):
		var text_label:=label_variant as Label
		if not text_label.is_visible_in_tree() or text_label.text.strip_edges().is_empty(): continue
		var rendered_font:=float(text_label.get_theme_font_size("font_size"))*absf(text_label.get_global_transform().get_scale().x)
		if rendered_font<5.5: failures.append("%s rendered '%s' at an unreadable %.1fpx" % [label,text_label.text.left(32),rendered_font])


func _press_named(root:Control,text_value:String)->bool:
	for button_variant in root.find_children("*","Button",true,false):
		var button:=button_variant as Button
		if button.text==text_value:
			button.pressed.emit()
			return true
	return false

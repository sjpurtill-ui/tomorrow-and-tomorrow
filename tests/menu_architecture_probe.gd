extends Node

const TERRAIN_SCENE:=preload("res://local_terrain.tscn")
var failures:Array[String]=[]


func _ready()->void:
	GameState.reset_for_new_world(803177)
	DiscoverySystem.reset_for_new_world()
	ProgressionSystem.reset_for_new_world()
	ResourceSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	ConsequenceEngine.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	GameState.select_founding_focus("provision")
	var terrain:=TERRAIN_SCENE.instantiate()
	add_child(terrain)
	await get_tree().process_frame
	await get_tree().process_frame
	if terrain.founding_focus_panel and is_instance_valid(terrain.founding_focus_panel): terrain.founding_focus_panel.queue_free()
	terrain.founding_focus_panel=null
	await get_tree().process_frame
	var viewport_rect:=terrain.get_viewport().get_visible_rect()
	var nav_nodes:Array[Control]=[
		terrain.population_summary_label,
		terrain.provisions_button,
		terrain.interface_layer.find_child("NavCivilization",true,false),
		terrain.world_competition_button,
		MilitaryCommandUI.open_button
	]
	var labels:Array[String]=["SETTLEMENT","ECONOMY","CIVILIZATION","WORLD","MILITARY"]
	for index in labels.size():
		var nav:=nav_nodes[index]
		_expect(nav!=null,"missing primary destination %s" % labels[index])
		if nav:
			_expect(labels[index] in String(nav.get("text")),"primary destination %s has ambiguous label '%s'" % [labels[index],String(nav.get("text"))])
			_expect(_inside_viewport(nav,viewport_rect),"primary destination %s is outside 1280×720" % labels[index])
	_expect(terrain.materials_button and not terrain.materials_button.visible,"legacy Materials chip remained in primary navigation")

	terrain._open_settlement_dashboard()
	await get_tree().process_frame
	_expect(terrain.settlement_dashboard_panel!=null,"Settlement destination did not open")
	_expect(terrain.settlement_dashboard_panel.find_children("*","ScrollContainer",true,false).is_empty(),"Settlement overview requires scrolling")
	var settlement_cards:Node=terrain.settlement_dashboard_panel.find_child("SettlementSummaryCards",true,false)
	_expect(settlement_cards and settlement_cards.get_child_count()==3,"Settlement overview is not a three-card summary")

	terrain._open_provisions_panel()
	await get_tree().process_frame
	_expect(terrain.settlement_dashboard_panel==null,"Economy stacked above Settlement")
	_expect(terrain.provisions_panel!=null and terrain.provisions_panel.find_children("*","ScrollContainer",true,false).is_empty(),"Economy overview is missing or scrolls")
	_expect(_has_button(terrain.provisions_panel,"MATERIAL FLOW"),"Economy cannot reach Material Flow")

	terrain._open_systems_hub()
	await get_tree().process_frame
	_expect(terrain.provisions_panel==null,"Civilization stacked above Economy")
	_expect(terrain.systems_hub_panel!=null and terrain.systems_hub_panel.find_children("*","ScrollContainer",true,false).is_empty(),"Civilization overview is missing or scrolls")
	var civilization_cards:Node=terrain.systems_hub_panel.find_child("CivilizationSummaryCards",true,false)
	_expect(civilization_cards and civilization_cards.get_child_count()==3,"Civilization overview does not consolidate Development, Society, and Government")

	terrain._open_civilizations_panel()
	await get_tree().process_frame
	_expect(terrain.systems_hub_panel==null,"World stacked above Civilization")
	_expect(terrain.civilizations_panel!=null and terrain.civilizations_panel.find_children("*","ScrollContainer",true,false).is_empty(),"World overview is missing or scrolls")
	_expect(_has_text(terrain.civilizations_panel,"WORLD STRATEGY"),"World overview has no clear heading")

	# Military refuses to open behind another primary destination.
	MilitaryCommandUI._toggle()
	_expect(not MilitaryCommandUI.modal.visible,"Military opened behind World")
	terrain._close_civilizations_panel()
	await get_tree().process_frame
	MilitaryCommandUI._toggle()
	_expect(MilitaryCommandUI.modal.visible,"Military destination did not open from the map")
	_expect(MilitaryCommandUI.command_tabs and MilitaryCommandUI.command_tabs.get_tab_count()==5,"Military command is not split into five focused sections")
	var military_scroll_visible:=false
	for military_scroll_variant in MilitaryCommandUI.modal.find_children("*","ScrollContainer",true,false):
		var military_scroll:=military_scroll_variant as Control
		if military_scroll and military_scroll.is_visible_in_tree(): military_scroll_visible=true
	_expect(not military_scroll_visible,"Military primary dashboard requires scrolling")
	MilitaryCommandUI.modal.hide()

	if failures.is_empty():
		print("MENU_ARCHITECTURE_PROBE PASS")
		get_tree().quit(0)
	else:
		for failure in failures: push_error("MENU_ARCHITECTURE_PROBE "+failure)
		get_tree().quit(1)


func _has_button(root:Node,caption:String)->bool:
	for candidate_variant in root.find_children("*","Button",true,false):
		var candidate:=candidate_variant as Button
		if candidate and String(candidate.text)==caption: return true
	return false


func _has_text(root:Node,needle:String)->bool:
	for candidate_variant in root.find_children("*","Label",true,false):
		var candidate:=candidate_variant as Label
		if candidate and needle in candidate.text: return true
	return false


func _inside_viewport(control:Control,viewport_rect:Rect2)->bool:
	if control==null or not control.is_visible_in_tree(): return false
	var rect:=control.get_global_rect()
	return rect.position.x>=viewport_rect.position.x and rect.position.y>=viewport_rect.position.y and rect.end.x<=viewport_rect.end.x and rect.end.y<=viewport_rect.end.y


func _expect(condition:bool,message:String)->void:
	if not condition: failures.append(message)

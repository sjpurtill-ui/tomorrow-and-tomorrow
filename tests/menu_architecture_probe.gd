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
	_expect(terrain.hud!=null,"Command Rail HUD missing")
	var nav_names:Array[String]=["RailSettlement","RailEconomy","RailCivilization","RailInquiry","RailWorld","RailMilitary"]
	var labels:Array[String]=["SETTLEMENT","ECONOMY","CIVILIZATION","INQUIRY","WORLD","MILITARY"]
	for index in labels.size():
		var nav:=terrain.hud.find_child(nav_names[index],true,false) as Control
		_expect(nav!=null,"missing rail destination %s" % labels[index])
		if nav:
			_expect(_inside_viewport(nav,viewport_rect),"rail destination %s is outside the reference viewport" % labels[index])
	_expect(terrain.hud.find_child("RailMenu",true,false)!=null,"rail MENU button missing")
	_expect(terrain.hud.find_child("TimePill",true,false)!=null,"time pill missing")
	_expect(terrain.hud.find_child("KpiStrip",true,false)!=null,"KPI strip missing")
	_expect(terrain.hud.find_child("MapToolbar",true,false)!=null,"map toolbar missing")

	# Settlement and Economy live in the slide-out dock: the map stays visible
	# (no dimmer, no full-screen Control) while their numbers are open.
	terrain._on_hud_section_requested("settlement",0)
	await get_tree().process_frame
	_expect(terrain.hud.dock.visible,"Settlement dock did not open")
	_expect(terrain.hud.active_section=="settlement","rail did not mark Settlement active")
	_expect(_has_text(terrain.hud.dock,"LABOR ALLOCATION"),"Settlement dock is missing labor allocation")
	var dock_rect:Rect2=(terrain.hud.dock as Control).get_global_rect()
	_expect(dock_rect.size.x<viewport_rect.size.x*0.5,"dock covers the map like a modal")

	terrain._on_hud_section_requested("economy",0)
	await get_tree().process_frame
	_expect(terrain.hud.dock.visible and terrain.hud.active_section=="economy","Economy did not replace Settlement in the dock")
	_expect(_has_text(terrain.hud.dock,"TODAY'S FLOW"),"Economy dock is missing today's flow")
	terrain._on_hud_section_requested("economy",1)
	await get_tree().process_frame
	_expect(_has_text(terrain.hud.dock,"RECOGNIZED MATERIALS"),"Economy cannot reach Material Flow")

	terrain._on_hud_section_requested("civ",0)
	await get_tree().process_frame
	_expect(terrain.hud.dock.visible and terrain.hud.active_section=="civ","Civilization did not open in the dock")
	_expect(_has_text(terrain.hud.dock,"TWELVE CAPACITIES"),"Civilization dock is missing the twelve capacities")
	terrain._on_hud_section_requested("civ",2)
	await get_tree().process_frame
	_expect(terrain.hud.dock.find_child("SovereignOrderInput",true,false)!=null,"Council dock is missing the sovereign order input")

	terrain._on_hud_section_requested("inquiry",0)
	await get_tree().process_frame
	_expect(terrain.hud.dock.visible and terrain.hud.active_section=="inquiry","Inquiry did not open in the dock")
	_expect(_has_text(terrain.hud.dock,"ATTENTION BY DOMAIN"),"Inquiry dock is missing attention allocation")

	terrain._on_hud_section_requested("world",0)
	await get_tree().process_frame
	_expect(terrain.hud.dock.visible and terrain.hud.active_section=="world","World did not open in the dock")
	_expect(_has_text(terrain.hud.dock,"KNOWN CONTACTS"),"World dock is missing known contacts")
	terrain._on_hud_section_requested("",0)
	await get_tree().process_frame

	terrain._on_hud_section_requested("military",0)
	await get_tree().process_frame
	_expect(terrain.hud.dock.visible and terrain.hud.active_section=="military","Military did not open in the dock")
	_expect(_has_text(terrain.hud.dock,"PERSONNEL"),"Military dock is missing the personnel readout")
	terrain._open_war_planning()
	_expect(MilitaryCommandUI.modal.visible,"war planning did not open from the military dock")
	_expect(MilitaryCommandUI.command_tabs and MilitaryCommandUI.command_tabs.get_tab_count()==5,"war planning is not split into five focused sections")
	MilitaryCommandUI.modal.hide()
	terrain._on_hud_section_requested("",0)
	await get_tree().process_frame

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

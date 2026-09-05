extends Node

const TERRAIN_SCENE:=preload("res://local_terrain.tscn")
var failures:Array[String]=[]


func _ready()->void:
	GameState.reset_for_new_world(314159)
	DiscoverySystem.reset_for_new_world()
	ResourceSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	GameState.select_founding_focus("provision")
	var terrain:=TERRAIN_SCENE.instantiate()
	add_child(terrain)
	await get_tree().process_frame
	await get_tree().process_frame
	var viewport_size:=get_viewport().get_visible_rect().size
	_expect(terrain.map_help_button!=null and terrain.map_help_panel!=null,"normal play did not construct compact map help")
	var visible_surface_resources:=ResourceSystem.visible_deposits()
	_expect(visible_surface_resources.size()>=4,"founding expedition recognized no practical surface resources")
	_expect(terrain.hud and terrain.hud.find_child("RailSettlement",true,false)!=null,"command rail did not expose Settlement as a direct destination")
	_expect(terrain.hud and terrain.hud.find_child("RailEconomy",true,false)!=null,"command rail did not expose Economy as a direct destination")
	_expect(ResourceSystem.stored_bulk()>0.0,"physical founding cargo disappeared before the first simulation tick")
	var opening_water:Dictionary=ResourceSystem.water_access_snapshot(terrain._discovery_context())
	_expect(bool(opening_water.get("recognized",false)) and String(opening_water.get("source_origin",""))=="mapped_hydrology","charted fresh water was absent at the start of the game")
	terrain._open_materials_panel()
	var water_listed:=false
	for water_label_variant in terrain.materials_panel.find_children("*","Label",true,false):
		var water_label:=water_label_variant as Label
		if water_label and "FRESH WATER" in water_label.text:
			water_listed=true
			break
	_expect(water_listed,"material resource report omitted recognized fresh water before the first simulation tick")
	terrain.materials_panel.queue_free()
	terrain.materials_panel=null
	var opening_resource_clusters:Array[Dictionary]=terrain._bounded_resource_overlay_selection(visible_surface_resources,Vector2(terrain.camera_target.x,terrain.camera_target.z),terrain.camera.size,func(position:Vector3)->bool: return terrain._world_position_is_revealed(position))
	_expect(not opening_resource_clusters.is_empty(),"resource mode showed no recognized resource on the opening regional map")
	if terrain.map_help_panel:
		_expect(terrain.map_help_panel.visible,"first-use map help was not visible on a normal new game")
		_expect(terrain.map_help_panel.position.x>=0.0 and terrain.map_help_panel.position.y>=46.0,"map help began outside the usable viewport")
		_expect(terrain.map_help_panel.position.x+terrain.map_help_panel.size.x<=viewport_size.x,"map help overflowed the right viewport edge")
		_expect(terrain.map_help_panel.position.y+terrain.map_help_panel.size.y<=viewport_size.y,"map help overflowed the bottom viewport edge")
	_expect(terrain.map_help_body and "Click land" in terrain.map_help_body.text and "FOUND SETTLEMENT" in terrain.map_help_body.text,"first-use help did not explain the immediate founding action")
	_expect(terrain.map_help_body and "WASD" not in terrain.map_help_body.text and "Middle-drag" not in terrain.map_help_body.text,"first-use help dumped camera controls into the primary instruction")
	var settle_button:=terrain.hud.find_child("ToolbarSettle",true,false) as Button
	_expect(settle_button and "FOUND SETTLEMENT" in settle_button.text and not settle_button.disabled,"founding action was not explicit on the map toolbar")
	var diplomat_button:=terrain.hud.find_child("ToolbarDiplomat",true,false) as Button
	_expect(diplomat_button and diplomat_button.disabled and "foreign settlement" in diplomat_button.tooltip_text,"diplomacy did not expose its physical-destination blocker")
	var resources_toggle:=terrain.hud.find_child("LayerResources",true,false) as Button
	_expect(resources_toggle!=null,"resource layer toggle missing from the map toolbar")
	var toolbar_node:=terrain.hud.find_child("MapToolbar",true,false) as Control
	_expect(toolbar_node and toolbar_node.get_global_rect().end.x<=viewport_size.x and toolbar_node.get_global_rect().end.y<=viewport_size.y,"map toolbar was not a bounded lower map control")
	terrain._inspect_location(terrain.world_start_position)
	_expect(terrain.lens_panel==null,"retired Lens was constructed during normal inspection")
	_expect(terrain.map_selection_marker and terrain.map_selection_marker.visible,"normal land inspection produced no temporary visual marker")
	if terrain.map_selection_marker:
		_expect(is_equal_approx(terrain.map_selection_marker.scale.x,terrain.map_selection_marker.scale.y) and is_equal_approx(terrain.map_selection_marker.scale.y,terrain.map_selection_marker.scale.z),"temporary ground locator was stretched into a vertical capsule")
	_expect(terrain.travel_status_label and ("SELECTED" in terrain.travel_status_label.text or "GROUND" in terrain.travel_status_label.text),"land inspection produced no readable result or next step")
	terrain._dismiss_map_help()
	_expect(not terrain.map_help_panel.visible,"first-use helper could not be dismissed")
	terrain._toggle_map_help()
	_expect(terrain.map_help_panel.visible,"MAP HELP could not reopen the dismissed guide")
	# Routine unit sightings stay on the map/World indicator and never interrupt.
	# First contact remains historically important: if a report owns the interaction
	# layer, it waits below it and appears only after the player returns to the map.
	terrain.foreign_alert_queue.clear()
	terrain.active_foreign_alert={}
	terrain.foreign_alert_panel.visible=false
	terrain._on_diplomatic_event({
		"kind":"unit_sighting","formation_id":"routine_probe","day":2,
		"title":"Foreign movement","description":"A distant formation crossed the known horizon."
	})
	_expect(terrain.foreign_alert_queue.is_empty() and terrain.active_foreign_alert.is_empty(),"routine foreign sighting created an interrupting alert")
	terrain.event_report_button.visible=true
	terrain._refresh_event_report()
	_expect(not terrain.event_report_button.visible,"routine birth/death report remained visible on the left side")
	var report_blocker:=Control.new()
	report_blocker.name="ProbeOpenReport"
	report_blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	terrain.interface_layer.add_child(report_blocker)
	terrain.provisions_panel=report_blocker
	terrain._on_diplomatic_event({
		"kind":"first_contact","formation_id":"probe_formation","civ_id":"probe_civ","day":2,
		"title":"First contact","description":"A foreign party met the settlement directly."
	})
	_expect(terrain.active_foreign_alert.is_empty() and terrain.foreign_alert_queue.size()==1,"foreign alert did not defer while a report owned the interaction layer")
	_expect(not terrain.foreign_alert_panel.visible and not terrain.foreign_alert_panel.is_visible_in_tree(),"foreign alert remained visible or interactive above an open report")
	terrain._arbitrate_notification_overlays()
	_expect(not terrain.map_help_panel.visible and not terrain.map_help_button.visible,"map help remained visible or clickable beneath an open report")
	report_blocker.visible=false
	terrain._arbitrate_notification_overlays()
	_expect(not terrain.active_foreign_alert.is_empty() and terrain.foreign_alert_panel.visible,"deferred foreign alert did not appear after the report closed")
	_expect(terrain.map_help_panel.visible and terrain.map_help_button.visible,"map help did not return after the player returned to the map")
	var alert_rect:Rect2=terrain.foreign_alert_panel.get_rect()
	_expect(alert_rect.position.x>=0.0 and alert_rect.position.y>=0.0 and alert_rect.end.x<=viewport_size.x and alert_rect.end.y<=viewport_size.y,"deferred foreign alert was not clamped inside the viewport: rect=%s viewport=%s" % [alert_rect,viewport_size])
	var visible_alert_buttons:=0
	for alert_button_variant in terrain.foreign_alert_panel.find_children("*","Button",true,false):
		var alert_button:=alert_button_variant as Button
		if alert_button==null or not alert_button.is_visible_in_tree(): continue
		visible_alert_buttons+=1
		var button_rect:Rect2=alert_button.get_global_rect()
		_expect(not alert_button.disabled and button_rect.position.x>=0.0 and button_rect.position.y>=0.0 and button_rect.end.x<=viewport_size.x and button_rect.end.y<=viewport_size.y,"foreign alert action was disabled or outside the clickable viewport: %s rect=%s" % [alert_button.text,button_rect])
	_expect(visible_alert_buttons>=2,"foreign alert exposed no visible map/dismiss actions")
	report_blocker.visible=true
	terrain._arbitrate_notification_overlays()
	_expect(not terrain.foreign_alert_panel.visible and not terrain.foreign_alert_panel.is_visible_in_tree(),"active foreign alert was not suppressed when a report opened over it")
	report_blocker.visible=false
	terrain._finish_active_foreign_alert()
	terrain.provisions_panel=null
	report_blocker.queue_free()
	var river_z:float=terrain.world_start_position.z
	var river_x:float=terrain._world_river_x(river_z)
	var river_assessment:Dictionary=terrain._settlement_surface_assessment(Vector3(river_x,terrain._height_at(river_x,river_z),river_z))
	_expect(not bool(river_assessment.get("valid",true)) and "RIVER CHANNEL" in String(river_assessment.get("reason","")),"rendered river channel was accepted as a settlement site")
	terrain.settlement_convoy_targeting=true
	var river_screen:Vector2=terrain.camera.unproject_position(Vector3(river_x,terrain._height_at(river_x,river_z),river_z))
	terrain._update_settlement_convoy_preview(river_screen)
	_expect(not terrain.settlement_convoy_hover_valid and terrain.settlement_convoy_preview and terrain.settlement_convoy_preview.visible,"later settlement preview did not render the river site as blocked")
	_expect(terrain.settlement_convoy_instruction_label and "RIVER CHANNEL" in terrain.settlement_convoy_instruction_label.text,"later settlement preview did not explain its river blocker")
	terrain.settlement_convoy_targeting=false
	if terrain.settlement_convoy_preview: terrain.settlement_convoy_preview.visible=false
	var original_marker_position:Vector3=terrain.settler_marker.position
	terrain.settler_marker.position=Vector3(river_x,terrain._height_at(river_x,river_z)+0.002,river_z)
	terrain._start_settlement_here()
	_expect(not GameState.settlement_site_committed,"direct founding command bypassed river-channel validation")
	terrain.settler_marker.position=original_marker_position
	if failures.is_empty():
		print("MAP_ONBOARDING_UI_PROBE PASS")
		get_tree().quit(0)
	else:
		for failure in failures: push_error("MAP_ONBOARDING_UI_PROBE "+failure)
		get_tree().quit(1)


func _expect(condition:bool,message:String)->void:
	if not condition: failures.append(message)

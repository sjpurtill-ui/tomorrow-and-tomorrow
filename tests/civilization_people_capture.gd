extends "res://tests/own_town_capture.gd"
## Private TEST scene only. Actual provider, HUD, living renderer and draft API.
var audit_terrain:Node
var failures:Array[String]=[]
var out_prefix:="first"
var risk_case:=""
func _ready()->void:
	if not "Test" in OS.get_user_data_dir():push_error("Requires isolated Test user data");get_tree().quit(2);return
	get_tree().create_timer(180.0).timeout.connect(func():get_tree().quit(3))
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--prefix="):out_prefix=arg.trim_prefix("--prefix=")
		elif arg.begins_with("--risk="):risk_case=arg.trim_prefix("--risk=")
	var mode:="light" if "--light" in OS.get_cmdline_user_args() else "dark"
	var config:=ConfigFile.new();config.set_value("display","visual_system",1);config.set_value("display","color_theme",mode);config.save("user://display.cfg")
	_world("late" if "--late" in OS.get_cmdline_user_args() else "early")
	GameState.select_founding_focus("provision");PeopleDirection.choose("makers")
	audit_terrain=load("res://local_terrain.tscn").instantiate();audit_terrain.set("suppress_naming_prompt",true);add_child(audit_terrain)
	await _frames(45);audit_terrain.call("_set_game_speed",0)
	if is_instance_valid(PeopleDirection.panel):PeopleDirection.panel.queue_free()
	if is_instance_valid(audit_terrain.get("settlement_naming_panel")):audit_terrain.get("settlement_naming_panel").queue_free()
	await _frames(5)
	var hud=audit_terrain.get("hud")
	if risk_case!="":_prepare_risk()
	for canvas:Vector2i in [Vector2i(1600,1000),Vector2i(2869,1337),Vector2i(1024,768)]:
		get_window().size=canvas;get_window().content_scale_size=canvas
		audit_terrain.call("_on_hud_section_requested","overview",0);hud.force_dock_layout();await _frames(12)
		var screen=hud.dock.find_child("CivilizationPeopleScreen",true,false)
		if screen==null:failures.append("Actual People route absent");break
		screen._cancel_draft();screen._return_overview();hud.dock.body_scroll.scroll_vertical=0;await _frames(25)
		await _capture("overview",canvas.x,mode)
		if screen.markers.size()!=9:failures.append("Missing work area")
		_check_markers(screen,canvas.x)
		if hud.dock.get_global_rect().end.x>get_viewport().get_visible_rect().size.x+1:failures.append("Spatial shell exceeds viewport")
		var before:=var_to_bytes([GameState.population_allocations,PeopleDirection.automatic_work,PeopleDirection.work_baseline])
		(screen.markers.Food.button as Button).pressed.emit();await _frames(35)
		if risk_case!="":
			await _capture("food-current",canvas.x,mode)
			screen._step(-20);await _frames(5)
		await _capture("food",canvas.x,mode)
		if risk_case!="":
			if not screen.forecast.get("warnings",[]).any(func(w:Dictionary)->bool:return w.kind=="safeguard"):failures.append("Risk fixture missed actual safeguard")
			if risk_case=="shortage" and String(screen.forecast.get("after",{}).get("food",{}).get("hunger_risk",""))!="now":failures.append("Risk fixture missed genuine current shortage")
			if not screen.stage.get_global_rect().encloses(screen.focus_panel.get_global_rect()):failures.append("Risk controls exceed scene at %d"%canvas.x)
			print("PEOPLE_RISK ",risk_case," ",screen.forecast.get("after",{}).get("food",{}).get("hunger_risk")," ",screen.forecast.get("warnings",[]))
		screen.focus_work("Construction");screen.five_button.pressed.emit();await _frames(35)
		await _capture("building-draft",canvas.x,mode)
		if before!=var_to_bytes([GameState.population_allocations,PeopleDirection.automatic_work,PeopleDirection.work_baseline]):failures.append("Preview changed live allocations")
		if not screen.stage.get_global_rect().encloses(screen.focus_panel.get_global_rect()):failures.append("Draft panel exceeds scene at %d"%canvas.x)
		if not screen.stage.get_global_rect().encloses(screen.evidence_panel.get_global_rect()):failures.append("Consequences exceed scene at %d"%canvas.x)
		if screen.food_strip.visible and not screen.stage.get_global_rect().encloses(screen.food_strip.get_global_rect()):failures.append("Food consequence exceeds scene at %d"%canvas.x)
		var worksite:Vector2=screen.anchors.get("Construction",Vector2.ZERO)
		if screen.focus_panel.get_rect().has_point(worksite) or screen.evidence_panel.get_rect().has_point(worksite):failures.append("Annotations obscure selected worksite at %d"%canvas.x)
		if screen.get_global_rect().end.x>canvas.x+1:failures.append("People content exceeds viewport")
		screen._cancel_draft();screen._return_overview()
	print("CIVILIZATION_PEOPLE_CAPTURE ",failures)
	get_tree().quit(0 if failures.is_empty() else 1)
func _frames(count:int)->void:
	for i in count:await get_tree().process_frame
func _capture(kind:String,width:int,mode:String)->void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts/people-living-b")
	get_viewport().get_texture().get_image().save_png("res://artifacts/people-living-b/%s-%s-%s-%d.png"%[out_prefix,kind,mode,width])

## Deterministic isolated scenario, evaluated by the real food/safeguard model.
func _prepare_risk()->void:
	GameState.simulation_metrics.merge({"food_production":10.0,"food_consumption":93.0,"food_total_stock":10.0,"food_net":-83.0,"food_projected_days":0.1,"food_intake_ratio":0.5,"food_labor_share":0.42},true)
	GameState.food_stocks={"Fresh food":0.0,"Stored food":10.0}
	GameState.resource_stockpiles["Food"]=10.0
	if risk_case=="shortage":
		GameState.food_stocks={"Fresh food":0.0,"Stored food":0.0}
		GameState.resource_stockpiles["Food"]=0.0
		GameState.food_source_health={"Wild gathering":0.12,"Hunting":0.12,"Fishing":0.12,"Cultivation":0.12}
		GameState.simulation_metrics.merge({"food_production":0.0,"food_total_stock":0.0,"food_net":-93.0,"food_intake_ratio":0.0},true)

func _check_markers(screen:Control,width:int)->void:
	var occupied:Array[Rect2]=[]
	for role:String in screen.markers:
		var marker:Control=screen.markers[role].node
		var rect:=marker.get_global_rect()
		if not screen.stage.get_global_rect().encloses(rect):failures.append("%s marker exceeds scene at %d"%[role,width])
		for prior:Rect2 in occupied:
			if rect.intersects(prior):failures.append("Work markers overlap at %d"%width)
		occupied.append(rect)

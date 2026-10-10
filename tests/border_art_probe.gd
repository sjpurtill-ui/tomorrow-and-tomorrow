extends Node3D
## Private TEST fixture: real BorderMap controls and FortBorder ledger on a
## flat inspection ground. Actual terrain evidence is captured separately with
## tools/border_map_capture.gd. Never loads or writes a player save.
## Run through tools/run_isolated_gpu_probe.ps1, --out=res://artifacts/border-art
## Add --verify for interaction/layout assertions; headless also supports these.

const BorderMap := preload("res://scripts/hud/border_map.gd")
const Forts := preload("res://scripts/fort_border.gd")
const T := preload("res://scripts/hud/hud_tokens.gd")
const Icons := preload("res://scripts/resource_icons.gd")

class Snapshot extends "res://scripts/save_system.gd":
	var source := ""
	func slot_path(_slot:String) -> String: return source

var camera: Camera3D
var hud: Control
var world_globe: Node
var _border_watch_day := -1
var map: Node
var out := "res://artifacts/border-art"
var failures: Array[String] = []
var captures: Array[Dictionary] = []
var checks := 0
var verify := false
var title: Label
var ground_ink: Control
var fixture_day := 0

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
		if arg == "--verify": verify = true
	if not OS.get_user_data_dir().contains("QA"):
		push_error("Border art probe requires an isolated QA custom user directory.")
		get_tree().quit(2); return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	if "--terrain" in OS.get_cmdline_user_args():
		await _real_map()
		return
	for node in get_tree().root.get_children():
		if node != self: node.set_process(false); node.set_physics_process(false)
	WorldSimulation.clear()
	GameState.reset_for_new_world(424242)
	GameState.civic_api_enabled = false
	GameState.settlement_site_committed = true
	GameState.settlement_founded_at = Vector3.ZERO
	GameState.player_settlements = [{"id":"seat", "primary":true, "position":Vector2.ZERO, "claim_radius_km":5.0}]
	GameState.ensure_population_total(5000)
	GameState.population_allocation_percentages = {"Defense":20.0,"Food":80.0}
	GameState.synchronize_population_allocations()
	GameState.resource_stockpiles = {"Timber":5000.0, "Stone":5000.0, "Fiber Plants":500.0, "Clay":500.0, "Food":50000.0}
	GameState.known_discoveries = ["joinery"]
	GameState.border_forts = {"seeded":true}
	CivilizationSystem.civilizations.clear()
	CivilizationSystem.revealed_areas = [{"x":0.0, "z":0.0, "radius":400.0}]
	CivilizationSystem.fog_revision += 1
	CivilizationSystem.scout_land_authority = func(_at:Vector2)->bool: return true
	fixture_day = GameState.elapsed_days
	_setup_view()
	T.set_color_mode("light")
	_new_map()
	await _capture("empty", "First border: no forts")
	GameState.known_discoveries = []
	_refresh()
	_pointer(Vector2(60,-70))
	await _capture("watch_camp", "Earliest watch camp: placement quote")
	GameState.known_discoveries = ["joinery"]
	_pointer(Vector2(80,-70))
	await _capture("placement", "Palisade: valid placement quote")
	_pointer(Vector2.ZERO)
	await _capture("blocked_home", "Placement blocked: home country")
	_pointer(Vector2(80,-70))
	GameState.resource_stockpiles["Timber"] = 10.0
	(map.get("chart") as Control).call("forget")
	await _capture("blocked_materials", "Placement blocked: timber shortage")
	GameState.resource_stockpiles["Timber"] = 5000.0
	_seed_forts()
	_refresh()
	_pointer(Vector2.INF)
	await _capture("overview", "Three posts: connected border and building fort")
	map.call("open_note", 1)
	await _capture("standing", "Standing palisade: garrison, condition and upkeep")
	map.call("open_note", 3)
	await _capture("building", "Fort under construction: work and time remaining")
	map.call("open_note", 1)
	map.call("start_move", 1)
	_pointer(Vector2(75,-65))
	await _capture("move", "Moving a fort: cost and changed border")
	map.call("_let_go")
	_pointer(Vector2.INF)
	Forts.set_border_share(0.05)
	_refresh()
	map.call("open_note", 1)
	await _capture("short_staff", "Short garrisons: five percent of the watch sent out")
	if verify: await _interactions()
	Forts.set_border_share(0.5)
	T.set_color_mode("dark")
	_new_map()
	map.call("open_note", 1)
	await _capture("dark", "Night palette: border and standing fort")
	T.set_color_mode("light")
	get_window().size = Vector2i(1152,720)
	get_window().content_scale_size = Vector2i(1152,720)
	_new_map()
	map.call("open_note", 2)
	await _capture("small", "1152 × 720: card fit and controls")
	_check(GameState.elapsed_days == fixture_day, "Opening, inspecting and capturing the border advances no game time")
	var file := FileAccess.open(out.path_join("audit.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"scope":"TEST fixture, actual BorderMap controls and FortBorder rules; flat inspection ground, no player save", "passed":failures.is_empty(), "checks":checks, "failures":failures, "captures":captures, "day":GameState.elapsed_days}, "\t"))
	print("BORDER_ART_PROBE ", "PASS" if failures.is_empty() else "FAIL", " checks=",checks," captures=",captures.size()," out=",out)
	get_tree().quit(0 if failures.is_empty() else 1)

func _setup_view() -> void:
	get_window().title = "TEST · Border art inspection"
	get_window().size = Vector2i(1600,900)
	get_window().content_scale_size = Vector2i(1600,900)
	camera = Camera3D.new(); camera.projection = Camera3D.PROJECTION_ORTHOGONAL; camera.size = 280.0
	add_child(camera); camera.position = Vector3(10,300,0); camera.look_at(Vector3(10,0,0),Vector3.FORWARD); camera.current = true
	var canvas := CanvasLayer.new(); canvas.layer = -1; add_child(canvas)
	ground_ink = FixtureGround.new(); ground_ink.set("host",self); canvas.add_child(ground_ink)
	var labels := CanvasLayer.new(); labels.layer = 100; add_child(labels)
	title = Label.new(); title.position = Vector2(26,20); title.add_theme_font_size_override("font_size",18)
	title.add_theme_color_override("font_color",Color("343129")); title.add_theme_color_override("font_shadow_color",Color("f6efdf"))
	title.add_theme_constant_override("shadow_offset_x",1); title.add_theme_constant_override("shadow_offset_y",1); labels.add_child(title)

func _new_map() -> void:
	if is_instance_valid(map): remove_child(map); map.free()
	map = BorderMap.ensure(self); map.call("set_enabled",true)
	_pointer(Vector2.INF)

func _seed_forts() -> void:
	var data := Forts.ledger()
	data.forts = [
		{"id":1,"kind":"palisade_fort","x":80.0,"z":0.0,"status":"standing","condition":0.86,"progress":6000.0,"name":"East Ridge"},
		{"id":2,"kind":"palisade_fort","x":0.0,"z":80.0,"status":"standing","condition":1.0,"progress":6000.0,"name":"River Gate"},
		{"id":3,"kind":"palisade_fort","x":-70.0,"z":-55.0,"status":"building","condition":1.0,"progress":2500.0,"name":"Alder Watch"}]
	data.next_id = 4; data.border_share = 0.5
	ground_ink.queue_redraw()

func _refresh() -> void:
	map.call("_changed")
	ground_ink.queue_redraw()

func _pointer(at:Vector2) -> void:
	(map.get("chart") as Control).set("pointer_override", map.call("screen_of",at) if at.is_finite() else Vector2(-100,-100))
	(map.get("chart") as Control).call("forget")

func _rendered_ground_height_at(_at:Vector2) -> float: return 0.0

func _terrain_hit(screen:Vector2) -> Dictionary:
	var hit:Variant = Plane(Vector3.UP,0.0).intersects_ray(camera.project_ray_origin(screen),camera.project_ray_normal(screen))
	return {"position":hit} if hit is Vector3 else {}

func _settle() -> void:
	for i in 8: await get_tree().process_frame
	map.call("_process",0.6)
	(map.get("chart") as Control).call("_process",0.6)
	for i in 5: await get_tree().process_frame

func _capture(key:String,description:String) -> void:
	title.text = "TEST · " + description + "\nReal border controls · staged ledger · flat inspection ground"
	if is_instance_valid(ground_ink): ground_ink.queue_redraw()
	await _settle()
	var entry := {"key":key,"description":description,"viewport":str(get_viewport().get_visible_rect().size),"cards":[]}
	for property in ["key_card","note"]:
		var card:Control = map.get(property)
		if is_instance_valid(card) and card.visible:
			entry.cards.append({"name":property,"rect":str(card.get_global_rect())})
			if verify: _check(get_viewport().get_visible_rect().encloses(card.get_global_rect()),key+": "+property+" fits the viewport")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		_check(get_viewport().get_texture().get_image().save_png(out.path_join(key+".png")) == OK,"Saved "+key)
	captures.append(entry)
	print("BORDER_ART_CAPTURE ",key," ",entry.cards)

func _real_map() -> void:
	var source := "res://artifacts/organic-places/current.save"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--save="): source = arg.trim_prefix("--save=")
	var path := ProjectSettings.globalize_path(source).replace("\\","/").simplify_path()
	var allowed := ProjectSettings.globalize_path("res://artifacts/").replace("\\","/").simplify_path().trim_suffix("/")+"/"
	if not path.begins_with(allowed) or not FileAccess.file_exists(source):
		push_error("Copy the source save into this worktree's ignored artifacts directory first.")
		get_tree().quit(2); return
	var source_hash := FileAccess.get_sha256(source)
	var snapshot := Snapshot.new(); snapshot.source = source; add_child(snapshot)
	for node in get_tree().root.get_children():
		if node != self: node.set_process(false); node.set_physics_process(false)
	var result:Dictionary = snapshot.load_game("copy")
	if result.has("error"): push_error(str(result)); get_tree().quit(2); return
	GameState.civic_api_enabled = false
	if PeopleDirection.needs_century_choice(): PeopleDirection.choose(String(PeopleDirection.AMBITIONS.keys()[0]))
	for node in get_tree().root.get_children():
		if node != self: node.set_process(false); node.set_physics_process(false)
	fixture_day = int(GameState.elapsed_days)
	var terrain:Node3D = load("res://local_terrain.tscn").instantiate(); add_child(terrain)
	terrain.call("_set_game_speed",0)
	get_window().title = "TEST · Border art on copied campaign terrain"
	get_window().size = Vector2i(1600,900); get_window().content_scale_size = Vector2i(1600,900)
	var deadline := Time.get_ticks_msec()+240000
	while not terrain.macro_render.ready() and Time.get_ticks_msec() < deadline: await get_tree().process_frame
	_check(terrain.macro_render.ready(),"Real terrain finished its macro preparation")
	var center := Forts.seat()
	CivilizationSystem._add_revealed_area(center,240.0,"private border visual inspection")
	GameState.resource_stockpiles = {"Timber":5000.0,"Stone":5000.0,"Fiber Plants":500.0,"Clay":500.0,"Food":50000.0}
	GameState.known_discoveries.append("joinery")
	GameState.border_forts = {"seeded":true,"forts":[],"next_id":4,"border_share":0.5}
	var offsets := [Vector2(80,0),Vector2(0,80),Vector2(-70,-55)]
	for i in offsets.size():
		var at := _land_near(terrain,center+Vector2(offsets[i]))
		Forts.forts().append({"id":i+1,"kind":"palisade_fort","x":at.x,"z":at.y,"status":"standing" if i<2 else "building","condition":0.86 if i==0 else 1.0,"progress":6000.0 if i<2 else 2500.0,"name":["East Ridge","River Gate","Alder Watch"][i]})
	terrain.set("_border_watch_day",-1)
	terrain.call("set_camera_distance_level",2)
	camera = terrain.get("camera")
	camera.size = 230.0; terrain.set("zoom_target_size",-1.0); terrain.set("zoom_preset_active",false)
	terrain.set("camera_yaw",0.0)
	terrain.call("_set_camera_target",Vector3(center.x,terrain.call("_height_at",center.x,center.y),center.y))
	terrain.call("_update_camera"); terrain.call("_update_scale_lod")
	for stream_pass in 2:
		var guard := 0
		while terrain.get("terrain_patch_job") != null and guard < 2000:
			terrain.call("_advance_terrain_patch"); await get_tree().process_frame; guard += 1
		terrain.call("_update_world_streaming")
	BorderMap.set_shown(terrain,true); map = BorderMap.find(terrain)
	var labels := CanvasLayer.new(); labels.layer = 100; add_child(labels)
	title = Label.new(); title.position = Vector2(190,44); title.add_theme_font_size_override("font_size",16)
	title.add_theme_color_override("font_color",Color("f8eed7")); title.add_theme_color_override("font_shadow_color",Color("201d14"))
	title.add_theme_constant_override("shadow_offset_x",1); title.add_theme_constant_override("shadow_offset_y",1); labels.add_child(title)
	for i in 40: await get_tree().process_frame
	_pointer(Vector2.INF); await _real_capture("terrain_overview","Three authored border posts on copied campaign terrain")
	map.call("open_note",1); await _real_capture("terrain_standing","Standing fort inspected on the map")
	map.call("_close_note")
	var placement := _land_near(terrain,center+Vector2(65,-75))
	_pointer(placement); await _real_capture("terrain_placement","Placement quote and proposed ground")
	map.call("open_note",1); map.call("start_move",1)
	_pointer(placement); await _real_capture("terrain_move","Moving a fort on the map")
	_check(FileAccess.get_sha256(source)==source_hash,"Copied source save unchanged")
	_check(GameState.elapsed_days==fixture_day,"Real-map inspection advances no game time")
	var file := FileAccess.open(out.path_join("terrain-audit.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"scope":"TEST: authored palisade posts on actual copied-save terrain, frozen simulation; no player save writes", "passed":failures.is_empty(),"checks":checks,"failures":failures,"captures":captures,"day":fixture_day,"source_sha256":source_hash},"\t"))
	print("BORDER_ART_TERRAIN ","PASS" if failures.is_empty() else "FAIL"," checks=",checks," captures=",captures.size())
	get_tree().quit(0 if failures.is_empty() else 1)

func _real_capture(key:String,description:String) -> void:
	title.text = "TEST · "+description+"\nAuthored fort ledger · actual saved terrain · frozen day"
	await _settle()
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		_check(get_viewport().get_texture().get_image().save_png(out.path_join(key+".png"))==OK,"Saved "+key)
	captures.append({"key":key,"description":description})
	print("BORDER_ART_CAPTURE ",key)

func _land_near(terrain:Node,wanted:Vector2) -> Vector2:
	for ring in 12:
		for bearing in 16:
			var at := wanted+Vector2.from_angle(TAU*float(bearing)/16.0)*float(ring)*6.0
			if bool(terrain.call("_scout_land_at",at)): return at
	return wanted

func _button(name:String) -> Button:
	return map.find_child(name,true,false) as Button

func _interactions() -> void:
	map.call("open_note",1); await _settle()
	var ledger_before := hash(var_to_bytes(GameState.border_forts))
	var stock_before := hash(var_to_bytes(GameState.resource_stockpiles))
	map.call("click",(map.get("key_card") as Control).get_global_rect().get_center())
	_check(hash(var_to_bytes(GameState.border_forts)) == ledger_before and hash(var_to_bytes(GameState.resource_stockpiles)) == stock_before,"Clicking the border card never places or moves a fort")
	map.call("click",(map.get("note") as Control).get_global_rect().get_center())
	_check(hash(var_to_bytes(GameState.border_forts)) == ledger_before,"Clicking a fort note never places a fort")
	map.call("start_move",1)
	var escape := InputEventKey.new(); escape.pressed = true; escape.keycode = KEY_ESCAPE
	map.call("_unhandled_input",escape)
	_check(int(map.get("moving")) == -1 and int(map.get("selected")) == 1,"Escape cancels a move and restores the selected fort")
	_check(hash(var_to_bytes(GameState.border_forts)) == ledger_before,"Cancelling a move does not mutate the fort ledger")
	map.call("_unhandled_input",escape)
	_check(int(map.get("selected")) == -1,"Second Escape closes the fort note")
	map.call("open_note",1); await _settle()
	var before_words := _all_text(map.get("note"))
	Forts.find_fort(1).condition = 0.31
	await _settle()
	_check(_all_text(map.get("note")) != before_words,"An open fort note refreshes when its condition changes")
	Forts.find_fort(1).condition = 0.86
	map.call("_close_note")
	_pointer(Vector2(80,-70)); await _settle()
	GameState.resource_stockpiles["Timber"] = 10.0
	await _settle()
	var quote:Dictionary = (map.get("chart") as Control).get("_quote")
	_check(not (quote.get("short",{}) as Dictionary).is_empty(),"A stationary placement quote refreshes after stores change")
	GameState.resource_stockpiles["Timber"] = 5000.0
	_pointer(Vector2.INF)
	for share in [0.0,1.0]:
		Forts.set_border_share(share); _refresh(); await _settle()
		var sign := "−" if share == 0.0 else "+"
		var found := false
		for button in map.find_children("*","Button",true,false):
			if button.text == sign: found = true; _check(button.disabled,"Watch share "+sign+" is disabled at its bound")
		_check(found,"Share stepper is present: "+sign)
	Forts.set_border_share(0.05); _refresh(); await _settle()
	var man := _button("ManEveryFort")
	_check(man != null,"Understaffed border offers ManEveryFort")
	if man != null:
		man.pressed.emit(); await _settle()
		var watch := Forts.watch()
		_check(int(watch.garrisons.get(1,0)) == 60 and int(watch.garrisons.get(3,0)) == 60,"Man every fort fills actual garrisons")
	map.call("open_note",1); await _settle()
	var close_note := _button("CloseFortNote")
	_check(close_note != null,"Fort note has a direct close control")
	if close_note != null: close_note.pressed.emit(); _check(int(map.get("selected")) == -1,"Close control closes the fort note")
	var close_map := _button("CloseBorder")
	_check(close_map != null,"Border card has a direct close control")
	if close_map != null:
		close_map.pressed.emit(); _check(not bool(map.get("enabled")),"Close control exits border mode")
	map.call("set_enabled",true)
	var preserved_forts := GameState.border_forts.duplicate(true)
	var preserved_stores := GameState.resource_stockpiles.duplicate(true)
	var count := Forts.forts().size()
	var place_at := Vector2(80,-70)
	map.call("click",map.call("screen_of",place_at))
	await _settle()
	var created_id := int(map.get("selected"))
	var created := Forts.find_fort(created_id)
	_check(Forts.forts().size()==count+1 and not created.is_empty() and String(created.get("status",""))=="building","Clicking valid ground starts actual fort construction")
	_check(is_instance_valid(map.get("note")) and (map.get("note") as Control).visible,"A newly placed fort immediately opens its construction note")
	_check(float(GameState.resource_stockpiles.Timber)==float(preserved_stores.Timber)-220.0,"Placement pays the actual palisade timber cost")
	if not created.is_empty():
		map.call("start_move",created_id)
		var move_at := Vector2(115,-75)
		map.call("click",map.call("screen_of",move_at))
		await _settle()
		var moved := Forts.find_fort(created_id)
		_check(int(map.get("selected"))==created_id and int(map.get("moving"))==-1 and Forts.forts().size()==count+1,"Moving keeps the fort identity and selects its result")
		_check(Forts._pos(moved).distance_to(move_at)<0.01 and String(moved.status)=="building","Moved fort resumes construction at the clicked position")
		_check(is_instance_valid(map.get("note")) and (map.get("note") as Control).visible,"A moved fort immediately opens its construction note")
	map.call("_close_note")
	GameState.border_forts=preserved_forts; GameState.resource_stockpiles=preserved_stores
	_refresh()
	T.set_color_mode("dark"); await _settle()
	_check(((map.get("key_card") as Control).get_theme_stylebox("panel") as StyleBoxFlat).bg_color==T.PAPER_RAISED,"An already open border card adopts its night background")
	T.set_color_mode("light"); await _settle()
	_check(((map.get("key_card") as Control).get_theme_stylebox("panel") as StyleBoxFlat).bg_color==T.PAPER_RAISED,"An already open border card returns to its paper background")

func _all_text(node:Node) -> String:
	if not is_instance_valid(node): return ""
	var result := ""
	if node is Label: result += (node as Label).text+"\n"
	for child in node.get_children(): result += _all_text(child)
	return result

func _check(ok:bool,description:String) -> void:
	checks += 1
	if not ok: failures.append(description); push_error("BORDER_ART_CHECK: "+description)

class FixtureGround extends Control:
	var host:Node3D
	func _ready() -> void: mouse_filter = MOUSE_FILTER_IGNORE; set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	func _draw() -> void:
		draw_rect(get_viewport_rect(),Color("d9d4bd"))
		for x in range(-250,251,25):
			var a:Vector2 = host.camera.unproject_position(Vector3(x,0,-180)); var b:Vector2 = host.camera.unproject_position(Vector3(x,0,180))
			draw_line(a,b,Color("c9c8b1"),1.0,true)
		for y in range(-175,176,25):
			var a:Vector2 = host.camera.unproject_position(Vector3(-280,0,y)); var b:Vector2 = host.camera.unproject_position(Vector3(280,0,y))
			draw_line(a,b,Color("c9c8b1"),1.0,true)
		var home:Vector2 = host.camera.unproject_position(Vector3.ZERO)
		draw_circle(home,8.0,Color("83754e")); draw_string(T.font("ui"),home+Vector2(12,5),"Seat",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("504b3b"))
		for fort:Dictionary in Forts.forts():
			var at:Vector2 = host.camera.unproject_position(Vector3(Forts._pos(fort).x,0,Forts._pos(fort).y))
			var texture := Icons.chart_texture("fort:"+String(fort.kind)+(":building" if String(fort.status)=="building" else ""),Color("7b2a7a"),64)
			draw_texture_rect(texture,Rect2(at-Vector2(20,20),Vector2(40,40)),false)

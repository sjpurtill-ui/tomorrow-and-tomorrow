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
	ground_ink.queue_redraw()
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

extends Node
## Private GPU acceptance using the actual map, loaded from an isolated save.
var terrain: Node
func _ready() -> void:
	if not OS.get_user_data_dir().to_lower().contains("acceptance"):
		get_tree().quit(2); return
	call_deferred("run")

func run() -> void:
	var loaded := SaveSystem.load_game("village-preview")
	if loaded.has("error"):
		push_error("An isolated copy of a campaign is required for this preview.")
		get_tree().quit(2); return
	get_window().size = Vector2i(1600, 1050)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	terrain = load("res://local_terrain.tscn").instantiate()
	add_child(terrain)
	await get_tree().process_frame
	terrain.game_speed = 0.0
	preload("res://scripts/hud/hud_tokens.gd").set_color_mode("dark")
	preload("res://scripts/hud/motion.gd").reduce_motion = true
	GameState.settlement_portrait_history = {}
	var before: Vector3 = terrain.camera_target
	var before_size: float = terrain.camera.size
	terrain.hud.open_dock("settlement", 0)
	var deadline := Time.get_ticks_msec() + 150000
	var id := String(GameState.selected_player_settlement_id)
	while preload("res://scripts/hud/village_view_record.gd").views(GameState.settlement_portrait_history, id).is_empty() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	var output := "res://artifacts/living-village"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	await _capture(output + "/overview.png")
	get_window().size=Vector2i(1024,900)
	for frame in 15:await get_tree().process_frame
	terrain.hud.force_dock_layout()
	for frame in 10:await get_tree().process_frame
	await _capture(output + "/overview-narrow.png")
	get_window().size=Vector2i(1600,1050)
	for frame in 15:await get_tree().process_frame
	terrain.hud.force_dock_layout()
	var structures:=0
	for mesh:MultiMeshInstance3D in terrain.find_children("SettlementArchitecture_*","MultiMeshInstance3D",true,false): structures+=mesh.multimesh.instance_count
	print("VILLAGE_PORTRAIT_STATE albums=",GameState.settlement_portrait_history.size()," structures=",structures," camera_span=",terrain.camera.size)
	if structures==0:push_error("Recorded occupied homes were not rendered");get_tree().quit(1);return
	if GameState.settlement_portrait_history.is_empty():
		push_error("No actual view recorded before deadline");get_tree().quit(1);return
	var recorded:Array=preload("res://scripts/hud/village_view_record.gd").views(GameState.settlement_portrait_history,id)
	if int(recorded[0].population)!=roundi(SettlementModel.primary_population_exact()):
		push_error("Recorded population disagrees with settlement ledger");get_tree().quit(1);return
	terrain.hud.open_dock("settlement", 1)
	for frame in 20: await get_tree().process_frame
	await _capture(output + "/history.png")
	# The same observed image/metadata must survive the game's real save codec.
	var captured:Dictionary=SaveSystem._capture_reflected(GameState,SaveSystem.REFLECT_SKIP.get("GameState",[]))
	var album:Dictionary=bytes_to_var(var_to_bytes(captured)).settlement_portrait_history
	if album!=GameState.settlement_portrait_history:push_error("Album was lost through save serialization");get_tree().quit(1);return
	if terrain.camera_target.distance_to(before) > 0.0001 or absf(terrain.camera.size - before_size) > 0.0001:
		push_error("Portrait did not restore the map camera");get_tree().quit(1);return
	terrain.hud.open_dock("settlement", 0)
	for frame in 20: await get_tree().process_frame
	var visit := terrain.hud.find_child("VisitVillage", true, false) as Button
	if visit == null:push_error("Visit action missing");get_tree().quit(1);return
	visit.pressed.emit()
	for frame in 3: await get_tree().process_frame
	if terrain.hud.dock.visible:push_error("Visit did not return to map");get_tree().quit(1);return
	await _capture(output + "/visit.png")
	print("LIVING_VILLAGE_PREVIEW_OK")
	get_tree().quit(0)

func _capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(path))

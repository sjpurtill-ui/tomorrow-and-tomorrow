extends VBoxContainer
## A second camera in the actual map World3D. Temporarily focus the map's detail
## streamer on the portrait; restore the prior map view on dismissal. No clone,
## generated village, terrain replacement, or simulation advancement.
const T := preload("res://scripts/hud/hud_tokens.gd")
const Record := preload("res://scripts/hud/village_view_record.gd")
var terrain: Node
var on_visit: Callable
var state: Dictionary = {}
var view: SubViewport
var lens: Camera3D
var picture: TextureRect
var caption: Label
var change_line: Label
var saved_camera: Dictionary = {}
var elapsed := 0.0
var stable_seconds := 0.0
var keep_view := false
var capture_pending := false
var frame_span := 0.0
var was_visible := false

func setup(block: Dictionary) -> void:
	theme = T.control_theme()
	terrain = block.get("terrain")
	on_visit = block.get("on_visit", Callable())
	state = block.get("state", {})
	name = "LivingVillageView"
	add_theme_constant_override("separation", 9)
	picture = TextureRect.new()
	picture.name = "ActualSettlement"
	picture.custom_minimum_size = Vector2(280, 360)
	picture.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picture.size_flags_vertical = Control.SIZE_EXPAND_FILL
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	picture.tooltip_text = "Visit this place on the map"
	add_child(picture)
	var visit := Button.new()
	visit.name = "VisitVillage"
	visit.flat = true
	visit.text = "Visit the village ↗"
	visit.size_flags_horizontal = Control.SIZE_SHRINK_END
	visit.pressed.connect(_visit)
	add_child(visit)
	picture.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			accept_event(); _visit())
	caption = T.make_label("Preparing the settlement view…", 15, T.GOLD_TEXT)
	caption.add_theme_font_override("font", T.font("voice"))
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(caption)
	change_line = T.make_label("", 13, T.TEXT_SOFT)
	change_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	change_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(change_line)
	if not is_instance_valid(terrain) or not terrain.has_method("_update_camera"):
		caption.text = "The settlement view is available on the map."
		visit.disabled = true
		set_process(false)
		return
	view = SubViewport.new()
	view.name = "VillageWorldView"
	view.size = Vector2i(1200, 540)
	view.world_3d = terrain.get_viewport().world_3d
	view.transparent_bg = false
	view.gui_disable_input = true
	view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	view.msaa_3d = Viewport.MSAA_2X
	add_child(view)
	lens = Camera3D.new()
	view.add_child(lens)
	lens.current = true
	picture.texture = view.get_texture()
	_update_words()

func _process(delta: float) -> void:
	if view == null or not is_instance_valid(terrain): return
	var showing := is_visible_in_tree()
	if showing and not was_visible: _acquire()
	if not showing and was_visible: _release()
	was_visible = showing
	if not showing: return
	elapsed += delta
	if elapsed >= 0.5:
		elapsed = 0.0
		_refresh_state()
		_frame()
	var main: Camera3D = terrain.get("camera")
	if main == null: return
	lens.transform = main.global_transform
	lens.projection = main.projection
	lens.fov = main.fov
	lens.size = main.size
	lens.near = main.near
	lens.far = main.far
	lens.environment = main.environment
	var ready := _ready_to_record()
	stable_seconds = stable_seconds + delta if ready else 0.0
	if stable_seconds > 1.5 and not capture_pending and DisplayServer.get_name() != "headless":
		var why := Record.reason(GameState.settlement_portrait_history, state)
		if not why.is_empty(): _capture(why)

func _acquire() -> void:
	if not saved_camera.is_empty(): return
	var main: Camera3D = terrain.get("camera")
	if main == null: return
	keep_view = false
	stable_seconds = 0.0
	terrain.set_meta("village_portrait", get_instance_id())
	saved_camera = {"size": main.size}
	for key: String in ["camera_target", "camera_yaw", "camera_pitch", "zoom_target_size", "zoom_preset_active", "zoom_log_velocity", "north_reset_active", "pan_coast_velocity", "key_pan_velocity"]:
		saved_camera[key] = terrain.get(key)
	terrain.set("zoom_target_size", -1.0)
	terrain.set("zoom_preset_active", false)
	terrain.set("north_reset_active", false)
	terrain.set("pan_coast_velocity", Vector3.ZERO)
	terrain.set("key_pan_velocity", Vector2.ZERO)
	_frame()
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS

func _frame() -> void:
	if saved_camera.is_empty(): return
	var p: Vector2 = state.get("position", Vector2.ZERO)
	var aim := Vector3(p.x, float(terrain.call("_height_at", p.x, p.y)), p.y)
	# North stays at the back of the image. The founding point stays centered;
	# framing widens in discrete steps so growth does not create camera drift.
	var span := ceilf(float(state.get("span", 0.12)) / 0.025) * 0.025
	for prior: Dictionary in Record.views(GameState.settlement_portrait_history, String(state.get("id", ""))):
		span = maxf(span, float(prior.get("span", span)))
	frame_span = maxf(frame_span, span)
	terrain.set("camera_target", aim)
	terrain.set("camera_yaw", PI * 0.5)
	terrain.set("camera_pitch", deg_to_rad(-52.0))
	(terrain.get("camera") as Camera3D).size = frame_span
	terrain.call("_update_camera")
	terrain.call("_update_scale_lod")

func _release() -> void:
	if saved_camera.is_empty() or not is_instance_valid(terrain): return
	if terrain.get_meta("village_portrait", 0) == get_instance_id(): terrain.remove_meta("village_portrait")
	if not keep_view:
		for key: String in saved_camera:
			if key != "size": terrain.set(key, saved_camera[key])
		(terrain.get("camera") as Camera3D).size = float(saved_camera.size)
		terrain.call("_update_camera")
		terrain.call("_update_scale_lod")
	saved_camera.clear()
	if view != null: view.render_target_update_mode = SubViewport.UPDATE_DISABLED

func _exit_tree() -> void:
	_release()

func _visit() -> void:
	keep_view = true
	if on_visit.is_valid(): on_visit.call()

func _refresh_state() -> void:
	var id := String(state.get("id", ""))
	var fresh := Record.current(id)
	if fresh.is_empty(): return
	state = fresh
	_update_words()

func _update_words() -> void:
	caption.text = "%s · %s · live from the map" % [String(state.get("name", "Our village")), Record.date(int(state.get("day", 0)))]
	change_line.text = Record.changes(GameState.settlement_portrait_history, state)

func _ready_to_record() -> bool:
	if terrain.has_method("settlement_patch_stats"):
		var stats: Dictionary = terrain.call("settlement_patch_stats")
		if int(stats.get("pending", 0)) > 0 or int(stats.get("installed", 0)) == 0: return false
	# The terrain streamer must have finished the current close view too.
	if terrain.get("terrain_patch_job") != null or terrain.get("close_terrain_job") != null: return false
	return true

func _capture(why: String) -> void:
	capture_pending = true
	var observation := state.duplicate(true)
	observation["span"] = frame_span
	await RenderingServer.frame_post_draw
	if not is_inside_tree() or not is_visible_in_tree():
		capture_pending = false
		return
	if int(observation.day) != int(GameState.elapsed_days) or not _ready_to_record():
		capture_pending = false
		return # Wait for a frame whose image and ledger describe the same day.
	var image := view.get_texture().get_image()
	if image != null and not image.is_empty():
		image.resize(960, 432, Image.INTERPOLATE_LANCZOS)
		Record.append_view(GameState.settlement_portrait_history, observation, image.save_webp_to_buffer(true, 0.72), why)
	capture_pending = false
	_update_words()

extends Node3D

## Asset viewer: three presentation models, independent of simulated population.
var unit_ids: Array[String] = ["levy", "line_infantry", "skirmisher"]
var unit_labels: Array[String] = ["LEVY / STONE CLUB", "LINE INFANTRY / SPEAR & SHIELD", "SKIRMISHER / BOW"]
var model_spacing := 2.3
var preview_title := "TOMORROW AND TOMORROW — FOUNDING FORCES"
var players: Array[AnimationPlayer] = []
var camera: Camera3D
var yaw := 0.18
var distance := 5.6
var selected_clip := "idle"
var slow_motion := false
var minimum_distance := 4.0
var maximum_distance := 15.0

func _ready() -> void:
	DisplayServer.window_set_title(preview_title)
	get_viewport().msaa_3d = Viewport.MSAA_4X
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("18242b")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("e4dfce")
	settings.ambient_light_energy = 0.4
	environment.environment = settings
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-48, -32, 0)
	light.light_energy = 0.8
	light.shadow_enabled = true
	add_child(light)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(200, 200)
	ground.mesh = plane
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("33413e")
	material.roughness = 0.95
	ground.material_override = material
	ground.position.y = -0.015
	add_child(ground)
	for i in unit_ids.size():
		var packed := load("res://assets/models/basic_units/%s.glb" % unit_ids[i]) as PackedScene
		var unit := packed.instantiate() as Node3D
		unit.position.x = (i - (unit_ids.size() - 1) * 0.5) * model_spacing
		add_child(unit)
		var player := unit.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if player:
			players.append(player)
			for clip in ["idle", "walk"]:
				if player.has_animation(clip):
					player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
		var caption := Label3D.new()
		caption.text = unit_labels[i]
		caption.font_size = 32
		caption.pixel_size = 0.003
		caption.position = Vector3((i - (unit_ids.size() - 1) * 0.5) * model_spacing, 0.1, 1.15 if model_spacing < 3 else 1.85)
		caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(caption)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = distance
	add_child(camera)
	_update_camera()
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := VBoxContainer.new()
	panel.position = Vector2(28, 22)
	layer.add_child(panel)
	var title := Label.new()
	title.text = preview_title
	title.add_theme_font_size_override("font_size", 24)
	panel.add_child(title)
	var help := Label.new()
	help.text = "Drag to orbit • Scroll to zoom • Select an animation to play the units"
	panel.add_child(help)
	var buttons := HBoxContainer.new()
	panel.add_child(buttons)
	for clip in ["idle", "walk", "attack", "death"]:
		var button := Button.new()
		button.text = clip.to_upper()
		button.custom_minimum_size = Vector2(110, 38)
		button.pressed.connect(_play.bind(clip))
		buttons.add_child(button)
	var slow := CheckButton.new()
	slow.text = "SLOW MOTION"
	slow.toggled.connect(func(enabled: bool) -> void:
		slow_motion = enabled
		for player in players: player.speed_scale = 0.35 if enabled else 1.0)
	buttons.add_child(slow)
	_play("idle")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--clip="): _play(arg.trim_prefix("--clip="))
		if arg.begins_with("--time="):
			for player in players:
				player.seek(float(arg.trim_prefix("--time=")),true); player.speed_scale = 0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			await get_tree().process_frame
			await get_tree().process_frame
			get_viewport().get_texture().get_image().save_png(arg.trim_prefix("--capture="))
			get_tree().quit()

func _play(clip: String) -> void:
	selected_clip = clip
	for player in players:
		player.stop()
		player.play(clip)
		player.advance(0.0)

func _update_camera() -> void:
	camera.position = Vector3(sin(yaw) * 10.0, 5.0, cos(yaw) * 10.0)
	camera.look_at(Vector3(0, 1.15, 0))
	camera.size = distance

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		yaw -= event.relative.x * 0.008
		_update_camera()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: distance = maxf(minimum_distance, distance - 0.5)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN: distance = minf(maximum_distance, distance + 0.5)
		_update_camera()

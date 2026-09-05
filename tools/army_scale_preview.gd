extends Node3D

const FIGURES := preload("res://scripts/army_figure_formation.gd")
var armies: Array[Node3D] = []
var camera: Camera3D
var target := Vector3(0,1,0)
var yaw := 0.3
var zoom := 50.0
var summary: Label
var strength := 10000
var roster_mode := 0
var army_half_offset := 18.0

func _ready() -> void:
	DisplayServer.window_set_title("Army scale — representative formations")
	get_viewport().msaa_3d = Viewport.MSAA_4X
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("18242b")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("e4dfce")
	environment.ambient_light_energy = 0.45
	world.environment = environment; add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48,-30,0); sun.light_energy = 0.9; sun.shadow_enabled = true; add_child(sun)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new(); plane.size = Vector2(2000,2000); ground.mesh = plane
	var material := StandardMaterial3D.new(); material.albedo_color = Color("465747"); ground.material_override = material
	ground.position.y = -0.025; add_child(ground)
	for i in 2:
		var army := FIGURES.new(); army.position.x = -18 if i == 0 else 18
		add_child(army); armies.append(army)
	camera = Camera3D.new(); camera.projection = Camera3D.PROJECTION_ORTHOGONAL; add_child(camera)
	_update_camera()
	var layer := CanvasLayer.new(); add_child(layer)
	var panel := VBoxContainer.new(); panel.position = Vector2(24,18); layer.add_child(panel)
	var title := Label.new(); title.text = "ARMY SCALE / FORMATION VIEW"; title.add_theme_font_size_override("font_size",24); panel.add_child(title)
	summary = Label.new(); panel.add_child(summary)
	var roster := OptionButton.new()
	for label in ["Founding forces", "Reinforcements", "Mixed army", "Industrial forces", "Early historical forces", "Classical land forces", "Medieval forces"]: roster.add_item(label)
	roster.item_selected.connect(func(index: int) -> void:
		roster_mode = index; _set_strength(strength); _view("Overview"))
	panel.add_child(roster)
	var sizes := HBoxContainer.new(); panel.add_child(sizes)
	for count in [100,1000,10000,100000,1000000,1000000000]:
		var button := Button.new(); button.text = str(count) if count < 1000 else (str(count/1000)+"K" if count < 1000000 else ("1M" if count == 1000000 else "1B"))
		button.pressed.connect(_set_strength.bind(count)); sizes.add_child(button)
	var actions := HBoxContainer.new(); panel.add_child(actions)
	for clip in ["idle","walk","attack","death"]:
		var button := Button.new(); button.text = clip.to_upper()
		button.pressed.connect(func() -> void:
			for army in armies: army.set_animation(clip,true))
		actions.add_child(button)
	var views := HBoxContainer.new(); panel.add_child(views)
	for name in ["Overview","Formation","Inspect"]:
		var button := Button.new(); button.text = name
		button.pressed.connect(_view.bind(name)); views.add_child(button)
	var help := Label.new(); help.text = "Scroll to zoom • Left-drag to orbit • Right-drag to pan\nBoth armies have the selected strength. Figures represent groups, not individual soldiers."
	panel.add_child(help)
	_set_strength(strength)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--roster="):
			roster_mode = clampi(int(arg.trim_prefix("--roster=")),0,6)
			roster.select(roster_mode); _set_strength(strength); _view("Overview")
		if arg.begins_with("--view="): _view(arg.trim_prefix("--view="))
		if arg.begins_with("--strength="): _set_strength(int(arg.trim_prefix("--strength=")))
		if arg.begins_with("--clip="):
			for army in armies: army.set_animation(arg.trim_prefix("--clip="),true)
		if arg.begins_with("--time="):
			for army in armies:
				army.clock = float(arg.trim_prefix("--time=")); army.animation_speed = 0
				army._process(0.0)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			await get_tree().process_frame
			await get_tree().process_frame
			get_viewport().get_texture().get_image().save_png(arg.trim_prefix("--capture="))
			get_tree().quit()

func _set_strength(value: int) -> void:
	strength = value
	var ids: Array = ["levy","line_infantry","skirmisher"] if roster_mode == 0 else (["cavalry","siege_engineer","field_artillery"] if roster_mode == 1 else FIGURES.UNIT_IDS)
	if roster_mode == 3: ids = ["rifle_infantry","machine_gun_company","motorized_infantry"]
	if roster_mode == 4: ids = FIGURES.HISTORICAL_IDS
	if roster_mode == 5: ids = FIGURES.CLASSICAL_IDS
	if roster_mode == 6: ids = FIGURES.MEDIEVAL_IDS
	var counts := {}
	var remaining := value
	for i in ids.size():
		counts[ids[i]] = value / ids.size() if i < ids.size()-1 else remaining
		remaining -= int(counts[ids[i]])
	var visual_spacing: float = [1.25, 3.2, 9.0, 5.0, 5.0, 6.0, 9.0][roster_mode]
	var columns := ceili(sqrt(float(FIGURES.figure_budget(value)) * 1.6))
	army_half_offset = maxf(18.0 if roster_mode == 0 else 48.0, columns * visual_spacing * 0.5 + 12.0)
	for i in armies.size():
		armies[i].position.x = -army_half_offset if i == 0 else army_half_offset
		armies[i].configure(counts,Color("67b4cf") if i==0 else Color("cf6658"))
	summary.text = "%s troops per army • %d representatives per army • %d shared mesh batches total\nArmy size changes ranks and footprint. Units keep their physical size." % [str(value), int(armies[0].figure_count), armies[0].batches.size()*2]

func _view(name: String) -> void:
	target = Vector3(0,1,0) if name == "Overview" else Vector3(-army_half_offset,1,0)
	zoom = maxf(50.0 if roster_mode == 0 else 120.0, army_half_offset * 2.4) if name == "Overview" else ((30.0 if roster_mode == 0 else maxf(80.0, army_half_offset * 1.4)) if name == "Formation" else 5.0)
	_update_camera()

func _update_camera() -> void:
	camera.position = target + Vector3(sin(yaw)*60,48,cos(yaw)*60)
	camera.look_at(target); camera.size = zoom

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT: yaw -= event.relative.x*0.006
		if event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
			target += camera.global_basis.x * -event.relative.x*zoom/720.0
			target += Vector3(sin(yaw),0,cos(yaw))*-event.relative.y*zoom/720.0
		_update_camera()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: zoom = maxf(2.0,zoom/1.16)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN: zoom = minf(120.0,zoom*1.16)
		_update_camera()

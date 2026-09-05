extends "res://tools/basic_units_preview.gd"

var naval := false

func _init() -> void:
	unit_ids.assign(["pike_phalanx", "legionary_infantry", "war_elephant"])
	unit_labels.assign(["PIKE PHALANX", "LEGIONARY INFANTRY", "WAR ELEPHANT"])
	model_spacing = 4.2
	distance = 10.0
	maximum_distance = 24.0
	preview_title = "TOMORROW AND TOMORROW — CLASSICAL FORCES"
	if "--siege" in OS.get_cmdline_user_args():
		unit_ids.assign(["battering_ram", "siege_tower"])
		unit_labels.assign(["BATTERING RAM", "SIEGE TOWER"])
		model_spacing = 6.0
		distance = 12.0
		preview_title = "TOMORROW AND TOMORROW — CLASSICAL SIEGE"
	if "--naval" in OS.get_cmdline_user_args():
		naval = true
		unit_ids.assign(["trireme"])
		unit_labels.assign(["TRIREME / ROW • RAM • DISABLED"])
		distance = 29.0
		minimum_distance = 12.0
		maximum_distance = 55.0
		yaw = 0.75
		preview_title = "TOMORROW AND TOMORROW — CLASSICAL NAVY"

func _ready() -> void:
	# The base viewer also handles command-line capture. Configure water before it
	# captures by using the tree's child-entered signal during scene setup.
	if naval: child_entered_tree.connect(_water)
	super._ready()

func _water(child: Node) -> void:
	if child is MeshInstance3D and child.mesh is PlaneMesh:
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("225563")
		material.roughness = 0.28
		child.material_override = material

func _update_camera() -> void:
	camera.position = Vector3(sin(yaw) * 30.0, 18.0, cos(yaw) * 30.0)
	camera.look_at(Vector3(0, 2.0, 0))
	camera.size = distance

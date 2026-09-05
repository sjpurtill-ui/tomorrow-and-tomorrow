extends "res://tools/classical_units_preview.gd"

func _init() -> void:
	unit_ids.assign(["armored_foot", "pavise_crossbowman", "longbowman"])
	unit_labels.assign(["ARMORED FOOT SOLDIER", "PAVISE CROSSBOWMAN", "LONGBOWMAN"])
	model_spacing = 2.8
	distance = 7.0
	maximum_distance = 30.0
	preview_title = "TOMORROW AND TOMORROW — MEDIEVAL INFANTRY"
	if "--siege" in OS.get_cmdline_user_args():
		unit_ids.assign(["counterweight_trebuchet", "hand_cannon_team", "bombard"])
		unit_labels.assign(["COUNTERWEIGHT TREBUCHET", "HAND-CANNON TEAM", "BOMBARD"])
		model_spacing = 5.5
		distance = 18.0
		preview_title = "TOMORROW AND TOMORROW — MEDIEVAL SIEGE & GUNPOWDER"

func _update_camera() -> void:
	camera.position = Vector3(sin(yaw) * 30.0, 18.0, cos(yaw) * 30.0)
	camera.look_at(Vector3(0, 3.0 if "--siege" in OS.get_cmdline_user_args() else 1.3, 0))
	camera.size = distance

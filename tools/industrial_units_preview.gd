extends "res://tools/basic_units_preview.gd"

func _init() -> void:
	unit_ids.assign(["rifle_infantry", "machine_gun_company", "motorized_infantry"])
	unit_labels.assign(["RIFLE INFANTRY", "MACHINE-GUN COMPANY", "MOTORIZED INFANTRY"])
	model_spacing = 4.2
	distance = 9.0
	preview_title = "TOMORROW AND TOMORROW — INDUSTRIAL FORCES"

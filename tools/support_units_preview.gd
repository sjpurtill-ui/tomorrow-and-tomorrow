extends "res://tools/basic_units_preview.gd"

func _init() -> void:
	unit_ids.assign(["cavalry", "siege_engineer", "field_artillery"])
	unit_labels.assign(["CAVALRY / MOUNTED LANCER", "SIEGE ENGINEERS / BALLISTA", "FIELD ARTILLERY / CANNON"])
	model_spacing = 4.2
	distance = 8.8
	preview_title = "TOMORROW AND TOMORROW — REINFORCEMENTS"

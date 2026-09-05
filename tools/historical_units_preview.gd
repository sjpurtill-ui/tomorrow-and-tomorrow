extends "res://tools/basic_units_preview.gd"

func _init() -> void:
	unit_ids.assign(["slinger", "javelin_skirmisher", "crossbow_infantry"])
	unit_labels.assign(["SLINGER", "JAVELIN SKIRMISHER", "CROSSBOW INFANTRY"])
	model_spacing = 2.8
	distance = 6.8
	preview_title = "TOMORROW AND TOMORROW — EARLY RANGED FORCES"
	if "--mounted" in OS.get_cmdline_user_args():
		unit_ids.assign(["chariot_archer", "horse_archer", "camel_cavalry"])
		unit_labels.assign(["CHARIOT ARCHER", "HORSE ARCHER", "CAMEL CAVALRY"])
		model_spacing = 4.2
		distance = 10.0
		preview_title = "TOMORROW AND TOMORROW — EARLY MOUNTED FORCES"

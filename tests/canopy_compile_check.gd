extends Node

func _ready()->void:
	if not OS.get_user_data_dir().ends_with("TomorrowCanopyTransitionTests"):
		push_error("Isolated canopy userdata is required.");get_tree().quit(2);return
	var errors:=0
	for path:String in ["res://tests/canopy_transition_probe.gd","res://tests/seasonal_landscape_probe.gd"]:
		var script:=load(path) as GDScript
		var valid:=script!=null and script.can_instantiate()
		print("CANOPY_COMPILE ",path," ","PASS" if valid else "FAIL")
		if not valid:errors+=1
	WorldSimulation.clear()
	get_tree().quit(errors)

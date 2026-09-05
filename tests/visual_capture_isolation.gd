extends Node

## Capture-only QA harness. It runs the real terrain capture path, then disables
## one named render layer before the built-in 18-frame screenshot delay. This
## lets visual regression work identify which bounded layer caused an artifact
## without adding diagnostic flags or branches to production rendering code.

const TERRAIN_SCENE:=preload("res://local_terrain.tscn")

var terrain:Node3D


func _initialize()->void:
	pass


func _ready()->void:
	# Every isolation image must contain the same terrain, settlement history and
	# camera target; otherwise a moving artifact could be mistaken for a layer fix.
	GameState.reset_for_new_world(864209)
	DiscoverySystem.reset_for_new_world()
	ResourceSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	MilitaryCampaign.reset_for_new_world()
	GameState.select_founding_focus("provision")
	if _has_argument("--qa-war-markers"): _seed_war_markers(Vector2.ZERO)
	terrain=TERRAIN_SCENE.instantiate()
	add_child(terrain)
	call_deferred("_isolate_requested_layer")


func _isolate_requested_layer()->void:
	await get_tree().process_frame
	if _has_argument("--qa-war-markers"):
		var center:=Vector2(terrain.camera_target.x,terrain.camera_target.z)
		_seed_war_markers(center)
		terrain._refresh_player_field_army_markers()
	var isolate:=_argument_value("--qa-isolate=")
	match isolate:
		"woodland":
			var woodland:=terrain.get_node_or_null("WoodlandCanopy") as GeometryInstance3D
			if woodland: woodland.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		"understory":
			var understory:=terrain.find_child("WoodlandUnderstory",true,false) as GeometryInstance3D
			if understory: understory.visible=false
		"close_vegetation":
			var close_vegetation:Node3D=terrain.get("close_vegetation_root")
			if close_vegetation: close_vegetation.visible=false
		"sun_shadows":
			for child in terrain.get_children():
				if child is DirectionalLight3D: (child as DirectionalLight3D).shadow_enabled=false
		"territory":
			if terrain.get("settlement_border_root"):
				(terrain.get("settlement_border_root") as Node3D).visible=false


func _argument_value(prefix:String)->String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with(prefix): return argument.trim_prefix(prefix)
	return ""


func _has_argument(expected:String)->bool:
	return expected in OS.get_cmdline_user_args()


func _seed_war_markers(center:Vector2)->void:
	MilitaryCampaign.field_armies.assign([
		{"army_id":1,"name":"FIRST MANEUVER ARMY","troops":1200,"position":{"x":center.x,"z":center.y},"status":"stationed","location_name":"HOME","supply_level":0.84},
		{"army_id":2,"name":"NORTHERN FIELD ARMY","troops":4800,"position":{"x":center.x+0.42,"z":center.y-0.18},"status":"moving","distance_remaining_km":92.0,"arrival_day":420,"supply_level":0.63},
		{"army_id":3,"name":"RESERVE FIELD ARMY","troops":25000,"position":{"x":center.x-0.36,"z":center.y+0.24},"status":"stationed","location_name":"RIVER CROSSING","supply_level":0.91}
	])

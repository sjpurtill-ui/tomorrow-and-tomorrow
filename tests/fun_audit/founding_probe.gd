extends Node
## FUN AUDIT founding probe: where each seed's people start, without playing.
## Boots the real local_terrain.tscn per seed and reads the ground at the
## founding camp (terrain._survey_ground_at, the same authority as the map).
##   <godot> --headless --path <worktree> res://tests/fun_audit/founding_probe.tscn -- --seeds=1,2,3 --out=<file>
## Requires the worktree override.cfg (isolated userdata). Never saves.

func _arg(n:String,f:String)->String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--%s="%n):return a.substr(n.length()+3)
	return f

func _ready()->void:
	if not OS.get_user_data_dir().ends_with("Tests"):
		push_error("needs isolated userdata");get_tree().quit(2);return
	var out:=FileAccess.open(_arg("out","user://founding_probe.jsonl"),FileAccess.WRITE)
	for part in _arg("seeds","424242").split(","):
		var seed_value:=int(part)
		GameState.reset_for_new_world(seed_value)
		DiscoverySystem.reset_for_new_world();ResourceSystem.reset_for_new_world();FoodSystem.reset_for_new_world()
		CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world()
		GameState.civic_api_enabled=false
		var t0:=Time.get_ticks_msec()
		var terrain:Node=load("res://local_terrain.tscn").instantiate();add_child(terrain)
		await get_tree().process_frame;await get_tree().process_frame
		var at:Vector3=terrain.world_start_position
		var ground:Dictionary=terrain._survey_ground_at(Vector2(at.x,at.z))
		var setting:=_setting(seed_value,ground)
		var row:={"seed":seed_value,"biome":String(ground.get("biome","")),"label":String(ground.get("label","")),"coastal":bool(ground.get("coastal",false)),"relief":snappedf(float(ground.get("relief",0)),0.01),"height":snappedf(float(ground.get("height",0)),0.01),"woodland":snappedf(float(ground.get("woodland",0)),0.01),"precip":snappedf(float(ground.get("precipitation",0)),0.01),"water_km":snappedf(float(ground.get("river_distance_km",0)),0.1),"province":GameState.province_terrain,"setting":setting,"ms":Time.get_ticks_msec()-t0}
		out.store_line(JSON.stringify(row));out.flush()
		print("FOUNDING ",JSON.stringify(row))
		terrain.queue_free()
		await get_tree().process_frame;await get_tree().process_frame
	out.close()
	get_tree().quit(0)


## The kind of country the start was chosen for (builds without settings: "").
static func _setting(seed_value:int,ground:Dictionary)->String:
	var start:GDScript=load("res://scripts/civilization_start.gd")
	for m in start.get_script_method_list():
		if String(m.name)=="setting_of":return String(start.call("setting_of",start.call("candidate",seed_value,0),ground))
	return ""

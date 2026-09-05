extends Node
func _ready()->void:
	var meta:=SaveSystem.save_metadata()
	var result:=SaveSystem.load_game()
	if result.has("error"):push_error(str(result));get_tree().quit(1);return
	var before:Dictionary={"population":GameState.population_total,"seed":GameState.world_seed,"day":GameState.elapsed_days,"name":GameState.settlement_name,"weights":GameState.research_allocations.duplicate(true),"known":GameState.known_discoveries.duplicate(),"cities":GameState.player_settlements.duplicate(true)}
	assert(int(meta.population)==GameState.population_total)
	assert(float(meta.elapsed_days)==GameState.elapsed_days)
	var terrain:=preload("res://local_terrain.tscn").instantiate()
	add_child(terrain);terrain._set_game_speed(0)
	await get_tree().process_frame;await get_tree().process_frame
	print("CAMPAIGN_RESUME_COMPARE before=",before.day," after=",GameState.elapsed_days," before_name=",before.name," after_name=",GameState.settlement_name," speed=",terrain.game_speed)
	assert(GameState.population_total==int(before.population));assert(GameState.world_seed==int(before.seed))
	assert(GameState.elapsed_days==float(before.day));assert(GameState.settlement_name==String(before.name))
	assert(GameState.research_allocations==before.weights);assert(GameState.known_discoveries==before.known)
	for old:Dictionary in before.cities:
		var city:=SettlementModel.settlement_record(String(old.id))
		assert(city.get("management_focus","")==old.get("management_focus",""))
		assert(city.get("auto_manage",true)==old.get("auto_manage",true))
	print("RELEASE_CAMPAIGN_PASS release=",ProjectSettings.get_setting("application/config/version")," name=",GameState.settlement_name," day=",GameState.elapsed_days," population=",GameState.population_total," seed=",GameState.world_seed," cities=",GameState.player_settlements.size())
	get_tree().quit()

extends Node
func _ready()->void:
	GameState.reset_for_new_world(73129)
	DiscoverySystem.reset_for_new_world()
	ProgressionSystem.reset_for_new_world()
	ResourceSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	GameState.select_founding_focus("inquiry")
	var terrain:=preload("res://local_terrain.tscn").instantiate()
	add_child(terrain)
	await get_tree().process_frame
	await get_tree().process_frame
	terrain._set_game_speed(0.0)
	CivilizationSystem.set_process(false)
	terrain.set_process(false)
	GameState.elapsed_days=365.0
	var provider:RefCounted=load("res://scripts/hud/content/dock_content_inquiry.gd").new(terrain,terrain.hud)
	var total:=DiscoverySystem.technology_catalog.size()
	for domain in provider.DOMAIN_COLORS:
		provider.tree_domain=String(domain)
		terrain.hud.dock.present(provider,1)
		await get_tree().process_frame
		assert(not DiscoverySystem.technology_tree(String(domain)).is_empty(),"Every domain must have real technology choices")
	GameState.known_discoveries.append("seasonal_patterns")
	GameState.discovery_log.push_front({"id":"seasonal_patterns","day":364})
	assert(not provider._latest_discovery_block().is_empty())
	for tab_index in [0,2]:
		terrain.hud.dock.present(provider,tab_index)
		await get_tree().process_frame
	provider._research_technology("tallies")
	assert(String(GameState.research_targets.get("knowledge::Preserved knowledge",""))=="tallies")
	GameState.discovery_progress["tallies"]=0.75
	var saved:=SaveSystem.save_game("technology_tree_probe")
	assert(bool(saved.get("ok",false)))
	GameState.research_targets.clear()
	assert(bool(SaveSystem.load_game("technology_tree_probe").get("ok",false)))
	CivilizationSystem.set_process(false)
	assert(String(GameState.research_targets.get("knowledge::Preserved knowledge",""))=="tallies")
	assert(float(GameState.discovery_progress.tallies)==0.75)
	DirAccess.remove_absolute(SaveSystem.slot_path("technology_tree_probe"))
	print("TECHNOLOGY_TREE_PROBE_PASS: %d distinct technologies; 12 rendered branches; target and progress survive save/load" % total)
	get_tree().quit()

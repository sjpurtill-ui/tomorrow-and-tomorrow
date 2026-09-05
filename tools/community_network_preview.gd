extends Node
func _ready()->void:
	if "--sample-contacts" in OS.get_cmdline_user_args():
		GameState.reset_for_new_world(190887)
		CivilizationSystem.reset_for_new_world(); CivilizationSystem.initialize()
		for civ:Dictionary in CivilizationSystem.civilizations:
			civ.player_relation.contact_level=2
			civ.player_relation.home_location_known=false
	CommunityNetwork.open_network()
	if "--sample-contacts" in OS.get_cmdline_user_args():
		CommunityNetwork.panel.selected=String(CivilizationSystem.civilizations[0].id)
		CommunityNetwork.panel._refresh()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			await get_tree().create_timer(.5).timeout
			get_viewport().get_texture().get_image().save_png(arg.trim_prefix("--capture="))
			get_tree().quit()

extends Node
func _ready()->void:
	DisplayServer.window_set_title("TEST CAPTURE · Council of Nations · closes automatically")
	GameState.reset_for_new_world(424242)
	CivilizationSystem.reset_for_new_world(); CivilizationSystem.initialize()
	ForeignDiplomacy.reset_for_new_world(); ForeignDiplomacy.ensure()
	var civ:Dictionary=CivilizationSystem.civilizations[0]; var id:=String(civ.id)
	civ.player_relation.contact_level=2; civ.player_relation.home_location_known=true; civ.player_relation.opinion=.5
	civ.player_relation.home_position={"x":1,"z":0}
	FoodSystem.reset_for_new_world(); FoodSystem.initialize(); FoodSystem.receive_external_food(10000)
	ForeignDiplomacy.commitments.send(id,ForeignDiplomacy.commitments.terms("found_faction","routes"))
	GameState.elapsed_days=int(CivilizationSystem.diplomatic_mission.return_day)
	CivilizationSystem._process_diplomatic_mission(int(GameState.elapsed_days))
	var council=preload("res://scripts/commitment_screen.gd").new(); council.civ_id=id; add_child(council)
	await get_tree().process_frame; await get_tree().process_frame; await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/commitment-council.png")
	var valid:bool=get_viewport().get_visible_rect().encloses(council.send_button.get_global_rect()) and council.summary.size.y>150
	print("COMMITMENT_UI ","PASS" if valid else "FAIL")
	get_tree().quit(0 if valid else 1)

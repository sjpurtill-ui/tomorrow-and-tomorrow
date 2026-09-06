extends "res://tests/manual_city_assault.gd"
func _ready()->void:
	fixture_attacker_count=600;fixture_population=30000;fixture_equipment=600
	await super._ready()
	for frame in 10:await get_tree().process_frame
	var marker:Node3D=terrain.player_field_army_markers[str(army_id)]
	await click(terrain.camera.unproject_position(marker.global_position))
	for frame in 8:await get_tree().process_frame
	await click(attack_button.get_global_rect().get_center())
	for frame in 10:await get_tree().process_frame
	var hud:BattleGraphicsScreen=MilitaryCommandUI.battle_graphics
	assert(is_instance_valid(hud))
	for cycle in 30:
		if hud.phase=="ended":break
		if hud.phase=="orders":
			await click(hud.targets.get_child(0).get_global_rect().get_center())
			await click(hud.order_buttons.charge.get_global_rect().get_center())
			await click(hud.resolve_button.get_global_rect().get_center())
			for frame in 4:await get_tree().process_frame
		if hud.phase=="resolving":await click(hud.skip_button.get_global_rect().get_center())
		if hud.phase=="result":await click(hud.result_primary.get_global_rect().get_center())
		for frame in 4:await get_tree().process_frame
	assert(hud.phase=="ended")
	print("VICTORY_OUTCOME ",MilitaryCampaign.battle_history[0].outcome," surviving=",MilitaryCampaign.battle_history[0].attacker.remaining_troops)
	await _hud_capture("real-city-ended")
	assert(CivilizationSystem.region_snapshot(civ_id,city_id).controller=="player")
	assert(CivilizationSystem.occupation_control(civ_id,city_id).controlled)
	await _hud_capture("real-city-victory")
	await click(hud.result_primary.get_global_rect().get_center())
	if is_instance_valid(hud) and hud.phase=="aftermath":
		await _hud_capture("real-victory-aftermath")
		await click(hud.result_primary.get_global_rect().get_center())
	if is_instance_valid(hud):await click(hud.result_primary.get_global_rect().get_center())
	assert(MilitaryCampaign.pending_aftermath.is_empty())
	preload("res://scripts/hud/occupation_view.gd").open(civ_id,city_id)
	for frame in 10:await get_tree().process_frame
	print("FULL_CITY_VICTORY_PASS real simulated 600-versus-119 battle ends; city captured only with sufficient surviving strength; actual garrison effective; aftermath resolved and occupation opened")
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/real-victory-occupation.png")
	get_tree().quit()

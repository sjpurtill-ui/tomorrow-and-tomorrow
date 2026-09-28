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
	var panel:Control=MilitaryCommandUI.battle_graphics
	assert(is_instance_valid(panel))
	# The general fights it through the calendar; the panel follows.
	for day in 40:
		if MilitaryCampaign.active_engagement.is_empty():break
		MilitaryCampaign.fight_engagement_day("hold")
		for frame in 3:await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout
	assert(MilitaryCampaign.active_engagement.is_empty())
	print("VICTORY_OUTCOME ",MilitaryCampaign.battle_history[0].outcome," surviving=",MilitaryCampaign.battle_history[0].attacker.remaining_troops)
	await _hud_capture("real-city-ended")
	assert(CivilizationSystem.region_snapshot(civ_id,city_id).controller=="player")
	assert(CivilizationSystem.occupation_control(civ_id,city_id).controlled)
	if not MilitaryCampaign.pending_aftermath.is_empty():MilitaryCampaign.resolve_aftermath("hold","army stores","hold")
	if is_instance_valid(MilitaryCommandUI.battle_graphics):MilitaryCommandUI.battle_graphics.call("close")
	assert(MilitaryCampaign.pending_aftermath.is_empty())
	var field:Dictionary=MilitaryCampaign.field_armies[0]
	assert(int(field.last_report.troops)==int(field.troops))
	assert(int(field.troops)+int(MilitaryCampaign.occupation_forces[0].troops)==589)
	action_panel.get_parent().hide()
	terrain._refresh_player_field_army_markers()
	preload("res://scripts/hud/occupation_view.gd").open(civ_id,city_id)
	for frame in 10:await get_tree().process_frame
	print("FULL_CITY_VICTORY_PASS real simulated 600-versus-119 battle ends; city captured only with sufficient surviving strength; actual garrison effective; aftermath resolved and occupation opened")
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/real-victory-occupation.png")
	get_tree().quit()

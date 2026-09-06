extends "res://tests/field_army_journey.gd"
func after_deployment()->void:
	# Authored coastal placement isolates order failure/recovery. This is not
	# progression evidence for the separate unreset new-game journey.
	var water:=Vector2.ZERO
	for distance in [1000,2000,4000,6000,8000]:
		for angle in 32:
			var point:Vector2=Vector2.RIGHT.rotated(angle*TAU/32)*distance
			if not terrain._scout_land_at(point):water=point;break
		if water!=Vector2.ZERO:break
	assert(water!=Vector2.ZERO)
	var dry:=Vector2.ZERO
	for step in 20:
		var midpoint:=dry.lerp(water,.5)
		if terrain._scout_land_at(midpoint):dry=midpoint
		else:water=midpoint
	var direction:=water.normalized();var shore:=dry
	dry=shore-direction*8;water=shore+direction*8
	assert(terrain._scout_land_at(dry) and not terrain._scout_land_at(water))
	var army:Dictionary=MilitaryCampaign.field_armies[0]
	army.position={"x":dry.x,"z":dry.y};army.location_id="field_position";army.location_name="Coastal test camp";army.last_report=MilitaryCampaign._army_report_snapshot(army)
	CivilizationSystem._add_revealed_area(shore,100.0,"authored coastal order fixture")
	hud.close_dock();terrain.camera.size=100;terrain._set_camera_target(Vector3(shore.x,terrain._height_at(shore.x,shore.y),shore.y));terrain._update_camera()
	for frame in 80:await get_tree().process_frame
	terrain._refresh_player_field_army_markers();await frames()
	var marker:Node3D=terrain.player_field_army_markers[str(army.army_id)]
	await mouse(terrain.camera.unproject_position(marker.global_position),MOUSE_BUTTON_LEFT);assert(terrain.selected_army_id==int(army.army_id))
	var before:Dictionary=army.position.duplicate()
	await mouse(terrain.camera.unproject_position(Vector3(water.x,terrain._height_at(water.x,water.y),water.y)),MOUSE_BUTTON_RIGHT)
	assert(army.position==before and army.status=="stationed")
	assert("WATER" in terrain.travel_status_label.text.to_upper());assert(hud.action_feedback.visible);await capture("field-water-blocked")
	# Actual provision processing reduces stored force condition and speed.
	var full_speed:=MilitaryCampaign._field_army_speed(army)
	for day in 30:MilitaryCampaign.record_daily_provisions(100,0)
	army=MilitaryCampaign.field_armies[0];assert(MilitaryCampaign._field_army_speed(army)<full_speed)
	var inland:=dry-direction*6
	await mouse(terrain.camera.unproject_position(Vector3(inland.x,terrain._height_at(inland.x,inland.y),inland.y)),MOUSE_BUTTON_RIGHT)
	assert(army.status=="moving");assert("march is slowed" in terrain.travel_status_label.text)
	await capture("field-low-supply-order")
	await wait_for_arrival();await capture("field-coastal-recovery")
	await click_control(hud.rail_buttons.military);await click_control(hud.dock.tab_buttons[3]);await capture("field-supply-recovery-options")
	print("FIELD_DISRUPTION_PASS actual coastal terrain UI water rejection without movement; real provision shortfall lowers pace; inland order explains slower march; normal-time arrival and Supply recovery screen")

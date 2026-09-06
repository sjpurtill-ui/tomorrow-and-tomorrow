extends "res://tests/army_preparation_probe.gd"
func mouse(point:Vector2,button:int)->void:
	for down in [true,false]:
		var event:=InputEventMouseButton.new();event.position=point;event.button_index=button;event.pressed=down;Input.parse_input_event(event);await get_tree().process_frame
	await frames()
func wait_for_arrival()->void:
	hud.close_dock();await frames();await click_control(hud.speed_buttons[5]);assert(terrain.game_speed==5)
	var deadline:=Time.get_ticks_msec()+12000
	while MilitaryCampaign.field_armies[0].status=="moving" and Time.get_ticks_msec()<deadline:await get_tree().process_frame
	await click_control(hud.speed_buttons[0]);assert(MilitaryCampaign.field_armies[0].status=="stationed")
func after_deployment()->void:
	hud.close_dock();await frames();terrain._refresh_player_field_army_markers();await frames()
	var army_id:=int(MilitaryCampaign.field_armies[0].army_id)
	var marker:Node3D=terrain.player_field_army_markers[str(army_id)]
	await mouse(terrain.camera.unproject_position(marker.global_position),MOUSE_BUTTON_LEFT)
	assert(terrain.selected_army_id==army_id)
	await capture("field-selected")
	var origin:Dictionary=MilitaryCampaign.field_armies[0].position.duplicate()
	var destination:=Vector2.ZERO
	for x in [700,800,900,500,400]:
		for y in [400,500,350,550]:
			var point:=Vector2(x,y);var hit:Dictionary=terrain._terrain_hit(point)
			if hit.is_empty():continue
			var pos:Vector3=hit.position;var target:=Vector2(pos.x,pos.z)
			var distance:=target.distance_to(Vector2(origin.x,origin.z))
			if distance<3 or distance>35 or not CivilizationSystem._position_is_revealed(target) or not CivilizationSystem._scout_land_at(target):continue
			destination=point;break
		if destination!=Vector2.ZERO:break
	assert(destination!=Vector2.ZERO,"A charted dry destination must be reachable on the actual map")
	await mouse(destination,MOUSE_BUTTON_RIGHT)
	assert(MilitaryCampaign.field_armies[0].status=="moving")
	assert(MilitaryCampaign.field_armies[0].position==origin,"An order cannot teleport the army")
	assert("marches" in terrain.travel_status_label.text)
	await capture("field-order")
	await wait_for_arrival();await capture("field-arrived")
	assert(MilitaryCampaign.field_armies[0].location_id=="field_position")
	await click_control(hud.speed_buttons[5])
	var report_deadline:=Time.get_ticks_msec()+12000
	while String(MilitaryCampaign.field_armies[0].last_report.get("location_name",""))!="MARKED GROUND" and Time.get_ticks_msec()<report_deadline:await get_tree().process_frame
	await click_control(hud.speed_buttons[0])
	assert(String(MilitaryCampaign.field_armies[0].last_report.location_name)=="MARKED GROUND")
	terrain._refresh_player_field_army_markers();await capture("field-arrival-reported")
	await click_control(hud.rail_buttons.military);await click_label("FIELD ARMIES")
	await click_label("DISBAND SELECTED")
	assert(MilitaryCampaign.field_armies.size()==1)
	assert("home" in terrain.travel_status_label.text.to_lower())
	await capture("field-disband-blocked")
	await click_label("RETURN SELECTED");assert(MilitaryCampaign.field_armies[0].status=="moving")
	await wait_for_arrival();assert(MilitaryCampaign.field_armies[0].location_id=="player_home")
	await capture("field-home")
	print("FIELD_ARMY_JOURNEY_PASS actual trained/deployed army selected by mouse; right-click charted dry destination, no teleport, normal-time arrival and actual runner delivery; disband away rejected with feedback; return order and normal-time home arrival")

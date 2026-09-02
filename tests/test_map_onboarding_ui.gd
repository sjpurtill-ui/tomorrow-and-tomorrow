extends GdUnitTestSuite

const RENDERER:=preload("res://scripts/local_terrain.gd")

var renderer:Node3D


func before_test()->void:
	GameState.reset_for_new_world(741991)
	renderer=auto_free(RENDERER.new())
	renderer._configure_shape()
	renderer._configure_noise()
	renderer._prepare_river_course()


func test_keyboard_navigation_uses_screen_axes_after_camera_rotation()->void:
	var screen_right:=Vector3(0.6,0.0,0.8)
	var screen_up:=Vector3(-0.8,0.0,0.6)
	var right:Vector3=renderer._camera_keyboard_movement(Vector2.RIGHT,screen_right,screen_up,5.0)
	var up:Vector3=renderer._camera_keyboard_movement(Vector2.UP,screen_right,screen_up,5.0)
	assert_float(right.x).is_equal_approx(3.0,0.0001)
	assert_float(right.z).is_equal_approx(4.0,0.0001)
	assert_float(up.x).is_equal_approx(-4.0,0.0001)
	assert_float(up.z).is_equal_approx(3.0,0.0001)


func test_grab_drag_makes_ground_follow_the_pointer()->void:
	var screen_right:=Vector3(0.6,0.0,0.8)
	var screen_up:=Vector3(-0.8,0.0,0.6)
	var drag_right:Vector3=renderer._camera_grab_movement(Vector2(10.0,0.0),screen_right,screen_up,0.2)
	var drag_down:Vector3=renderer._camera_grab_movement(Vector2(0.0,10.0),screen_right,screen_up,0.2)
	assert_float(drag_right.x).is_equal_approx(-1.2,0.0001)
	assert_float(drag_right.z).is_equal_approx(-1.6,0.0001)
	assert_float(drag_down.x).is_equal_approx(-1.6,0.0001)
	assert_float(drag_down.z).is_equal_approx(1.2,0.0001)


func test_first_use_help_names_one_contextual_next_action_without_a_control_glossary()->void:
	var founding:Dictionary=renderer._map_help_presentation(false,false,false)
	assert_str(String(founding.title)).is_equal("FIND A HOME")
	assert_str(String(founding.body)).contains("Click land")
	assert_str(String(founding.body)).contains("toolbar")
	assert_str(String(founding.body)).contains("FOUND SETTLEMENT")
	assert_str(String(founding.body)).not_contains("WASD")
	assert_str(String(founding.body)).not_contains("Middle-drag")
	var targeting:Dictionary=renderer._map_help_presentation(true,true,false)
	assert_str(String(targeting.title)).is_equal("CHOOSE DRY LAND")
	assert_str(String(targeting.body)).contains("Green")
	assert_str(String(targeting.body)).contains("red")
	assert_str(String(targeting.body)).contains("Right-click")
	var settled:Dictionary=renderer._map_help_presentation(true,false,false)
	assert_str(String(settled.body)).contains("Click a known place")
	assert_str(String(settled.body)).contains("Double-click")


func test_action_presentations_put_blockers_and_next_steps_on_the_action()->void:
	var scout:Dictionary=renderer._scout_action_presentation({}, {
		"can_dispatch":false,"blocker":"Requires 42.0 Food; only 12.0 is stored."
	})
	assert_bool(bool(scout.disabled)).is_true()
	assert_str(String(scout.label)).contains("BLOCKED")
	assert_str(String(scout.label)).contains("NEEDS FOOD")
	assert_str(String(scout.tooltip)).contains("NEXT")
	var diplomats:Dictionary=renderer._diplomat_action_presentation({},0)
	assert_bool(bool(diplomats.disabled)).is_true()
	assert_str(String(diplomats.label)).contains("LOCATE A FOREIGN SETTLEMENT FIRST")
	assert_str(String(diplomats.tooltip)).contains("encounter site is not a diplomatic destination")


func test_active_missions_remain_available_as_review_actions()->void:
	var scout:Dictionary=renderer._scout_action_presentation({"active":true,"days_remaining":18},{})
	var diplomats:Dictionary=renderer._diplomat_action_presentation({"active":true,"days_remaining":31},0)
	assert_bool(bool(scout.disabled)).is_false()
	assert_str(String(scout.label)).contains("REVIEW SCOUT PARTY")
	assert_bool(bool(diplomats.disabled)).is_false()
	assert_str(String(diplomats.label)).contains("REVIEW DIPLOMATS")


func test_blocked_scout_duration_is_visible_without_relying_on_a_tooltip()->void:
	var text:String=renderer._scout_mission_card_text(30,{
		"personnel":8,"provisions":132.0,"one_way_range_km":318.0,
		"risk":{"label":"LOW"},"can_dispatch":false,
		"blocker":"Requires 132.0 Food; only 30.0 is stored."
	})
	assert_str(text).contains("SEND FOR 30 DAYS")
	assert_str(text).contains("BLOCKED")
	assert_str(text).contains("Requires 132.0 Food")


func test_temporary_selection_marker_keeps_a_fixed_screen_footprint()->void:
	var site_radius:float=renderer._map_selection_radius(4.0,720.0)
	var regional_radius:float=renderer._map_selection_radius(400.0,720.0)
	assert_float(site_radius/4.0).is_equal_approx(regional_radius/400.0,0.0001)
	assert_float(site_radius).is_greater(0.004)
	assert_float(regional_radius).is_less(220.0)


func test_same_day_foreign_sightings_merge_into_one_bounded_alert()->void:
	var merged:Dictionary={"kind":"unit_sighting","day":44,"description":"First formation.","group_count":1}
	for index in 7:
		merged=renderer._merge_foreign_sighting_alert(merged,{"description":"Formation %d." % index})
	assert_int(int(merged.group_count)).is_equal(8)
	assert_int((merged.group_descriptions as Array).size()).is_equal(3)


func test_rendered_river_channel_is_a_hard_invalid_settlement_surface()->void:
	var z:=0.0
	var river_x:float=renderer._world_river_x(z)
	var channel:Dictionary=renderer._settlement_surface_assessment(Vector3(river_x,1.0,z))
	var bank:Dictionary=renderer._settlement_surface_assessment(Vector3(river_x+0.18,1.0,z))
	var dry_land:Dictionary=renderer._settlement_surface_assessment(Vector3(river_x+0.40,1.0,z))
	assert_bool(bool(channel.valid)).is_false()
	assert_str(String(channel.reason)).contains("RIVER CHANNEL")
	assert_bool(bool(bank.valid)).is_false()
	assert_bool(bool(dry_land.valid)).is_true()


func test_direct_founding_command_cannot_bypass_river_validation()->void:
	var marker:Area3D=auto_free(Area3D.new())
	marker.position=Vector3(renderer._world_river_x(0.0),1.0,0.0)
	renderer.settler_marker=marker
	renderer._start_settlement_here()
	assert_bool(GameState.settlement_site_committed).is_false()


func test_rendered_tributary_and_its_immediate_bank_are_blocked_but_dry_bank_is_valid()->void:
	var sites:=_tributary_channel_and_dry_bank()
	assert_bool(not sites.is_empty()).is_true()
	if sites.is_empty(): return
	var channel:Dictionary=renderer._settlement_surface_assessment(sites.channel)
	var dry_bank:Dictionary=renderer._settlement_surface_assessment(sites.dry_bank)
	assert_bool(bool(channel.get("valid",true))).is_false()
	assert_str(String(channel.get("reason",""))).contains("TRIBUTARY CHANNEL")
	assert_bool(bool(dry_bank.get("valid",false))).is_true()
	assert_float(float(dry_bank.get("river_distance_km",0.0))).is_greater(RENDERER.TRIBUTARY_SETTLEMENT_CLEARANCE_KM)


func test_direct_founding_command_also_rejects_rendered_tributaries()->void:
	var sites:=_tributary_channel_and_dry_bank()
	assert_bool(not sites.is_empty()).is_true()
	if sites.is_empty(): return
	var marker:Area3D=auto_free(Area3D.new())
	marker.position=sites.channel
	renderer.settler_marker=marker
	renderer._start_settlement_here()
	assert_bool(GameState.settlement_site_committed).is_false()


func test_later_settlement_preview_and_begin_share_the_river_blocker()->void:
	var destination:=Vector3(renderer._world_river_x(0.0),1.0,0.0)
	var feedback:Label=auto_free(Label.new()) as Label
	renderer.settlement_convoy_instruction_label=feedback
	# This is the same assessment consumed by the red/green placement preview.
	var preview_assessment:Dictionary=renderer._settlement_convoy_site_assessment(destination)
	assert_bool(bool(preview_assessment.get("valid",true))).is_false()
	assert_str(String(preview_assessment.get("reason",""))).contains("RIVER CHANNEL")
	renderer._begin_settlement_convoy(destination)
	assert_object(renderer.settlement_convoy_confirm_panel).is_null()
	assert_str(feedback.text).contains("RIVER CHANNEL")
	assert_dict(renderer.settlement_convoy_pending_quote).is_empty()


func test_confirmation_construction_and_final_commit_both_recheck_river_ground()->void:
	var destination:=Vector3(renderer._world_river_x(0.0),1.0,0.0)
	var feedback:Label=auto_free(Label.new()) as Label
	renderer.settlement_convoy_instruction_label=feedback
	renderer._open_settlement_convoy_confirmation(destination,{"distance_km":5.0},{"ok":true,"duration_days":1.0})
	assert_object(renderer.settlement_convoy_confirm_panel).is_null()
	assert_str(feedback.text).contains("RIVER CHANNEL")
	assert_dict(renderer.settlement_convoy_pending_quote).is_empty()
	# Even stale/tampered confirmation state must fail at the final mutation boundary.
	renderer.settlement_convoy_pending_destination=destination
	renderer.settlement_convoy_pending_quote={"ok":true,"duration_days":1.0}
	renderer.settlement_convoy_confirm_status=auto_free(Label.new()) as Label
	renderer.settlement_convoy_confirm_button=auto_free(Button.new()) as Button
	renderer._confirm_settlement_convoy()
	assert_bool(renderer.settlement_convoy_confirm_button.disabled).is_true()
	assert_str(renderer.settlement_convoy_confirm_status.text).contains("RIVER CHANNEL")
	assert_dict(renderer.settlement_convoy_pending_quote).contains_key_value("duration_days",1.0)


func test_mapped_hydrology_wins_over_an_arbitrary_freshwater_occurrence_in_player_facing_access()->void:
	GameState.resource_deposits=[{
		"id":"legacy_random_freshwater_point","resource":"Freshwater","stage":"surveyed",
		"quality":0.8,"position":Vector3(40.0,0.0,0.0)
	}]
	GameState.resource_stockpiles["Freshwater"]=0.0
	ResourceSystem.process_day({
		"origin":Vector3.ZERO,
		"surface_water_distance_km":2.75,
		"surface_water_kind":"visible river or drainage",
		"surface_water_id":"local_surface_hydrology"
	})
	var access:Dictionary=ResourceSystem.water_access_snapshot()
	assert_bool(bool(access.get("recognized",false))).is_true()
	assert_str(String(access.get("source_origin",""))).is_equal("mapped_hydrology")
	assert_str(String(access.get("source_id",""))).is_equal("local_surface_hydrology")
	assert_float(float(access.get("distance_km",-1.0))).is_equal_approx(2.75,0.0001)


func _tributary_channel_and_dry_bank()->Dictionary:
	if renderer.world_tributary_courses.is_empty():
		renderer.world_tributary_courses=renderer._seeded_world_tributaries()
	for course_variant in renderer.world_tributary_courses:
		var course:Array=course_variant
		for point_index in range(2,course.size()-2):
			var channel:Vector3=course[point_index]
			if renderer._main_river_distance_at(channel.x,channel.z)<2.0: continue
			var before:Vector3=course[point_index-1]
			var after:Vector3=course[point_index+1]
			var tangent:=Vector2(after.x-before.x,after.z-before.z).normalized()
			if tangent.length_squared()<0.5: continue
			var normal:=Vector2(-tangent.y,tangent.x)
			for side in [-1.0,1.0]:
				var bank_2d:=Vector2(channel.x,channel.z)+normal*float(side)*0.16
				var dry_bank:=Vector3(bank_2d.x,renderer._height_at(bank_2d.x,bank_2d.y),bank_2d.y)
				if renderer._main_river_distance_at(dry_bank.x,dry_bank.z)<=RENDERER.MAIN_RIVER_SETTLEMENT_CLEARANCE_KM: continue
				if renderer._nearest_tributary_distance_at(bank_2d)<=RENDERER.TRIBUTARY_SETTLEMENT_CLEARANCE_KM: continue
				if not bool(renderer._settlement_surface_assessment(dry_bank).get("valid",false)): continue
				return {
					"channel":Vector3(channel.x,renderer._height_at(channel.x,channel.z),channel.z),
					"dry_bank":dry_bank
				}
	return {}

extends GdUnitTestSuite

const PRESENTATION:=preload("res://scripts/warfare_map_presentation.gd")


func test_compact_strength_preserves_exact_owned_and_uncertain_foreign_counts()->void:
	assert_str(PRESENTATION.counter_strength({"troops":1200})).is_equal("1.2K")
	assert_str(PRESENTATION.counter_strength({"troops":0})).is_equal("0")
	assert_str(PRESENTATION.counter_strength({"strength_low":900,"strength_high":1500})).is_equal("~900–1.5K")
	assert_str(PRESENTATION.counter_strength({"strength_low":1200,"strength_high":1200})).is_equal("~1.2K")
	assert_str(PRESENTATION.counter_strength({"strength_high":500})).is_equal("~500")
	assert_str(PRESENTATION.counter_strength({})).is_equal("?")


func test_map_label_requires_viewport_and_hud_clearance()->void:
	var viewport:=Rect2(0,0,1440,900)
	var pill:=Rect2(500,10,400,50)
	assert_bool(PRESENTATION.label_rect_is_clear(Rect2(600,320,240,40),viewport,[pill])).is_true()
	assert_bool(PRESENTATION.label_rect_is_clear(Rect2(600,20,240,40),viewport,[pill])).is_false()
	assert_bool(PRESENTATION.label_rect_is_clear(Rect2(-20,320,240,40),viewport,[])).is_false()
	assert_bool(PRESENTATION.label_rect_is_clear(Rect2(600,880,240,40),viewport,[])).is_false()


func test_player_marker_communicates_owner_strength_readiness_supply_and_selection()->void:
	var marker:=PRESENTATION.player_marker(_army(7,12_500),48.0,true)
	assert_bool(bool(marker.visible)).is_true()
	assert_bool(bool(marker.selected)).is_true()
	assert_str(String(marker.owner_label)).is_equal("YOU")
	assert_str(String(marker.label)).contains("12.5K")
	assert_str(String(marker.label)).contains("SOLDIERS")
	assert_str(String(marker.label)).contains("READY 78%")
	assert_str(String(marker.label)).contains("SUPPLY 64%")
	assert_str(String(marker.color)).is_equal(PRESENTATION.PLAYER_COLOR)
	assert_str(String(marker.selection_color)).is_equal(PRESENTATION.PLAYER_SELECTED_COLOR)


func test_world_scale_hides_formation_detail_but_preserves_aggregate_front()->void:
	var snapshot:=PRESENTATION.build_snapshot(12_000.0,[_army(1,90_000)],[ _foreign() ],[_front()],[_home(),_objective()],{},1)
	assert_str(String(snapshot.band)).is_equal("world")
	assert_bool(bool(snapshot.player[0].visible)).is_false()
	assert_bool(bool(snapshot.foreign[0].visible)).is_false()
	assert_int(snapshot.fronts.size()).is_equal(1)
	assert_bool(bool(snapshot.fronts[0].visible)).is_true()
	assert_str(String(snapshot.fronts[0].label)).contains("WAR OF THE NORTH ROAD")
	assert_str(String(snapshot.fronts[0].label)).contains("43%")


func test_moving_army_exposes_one_bounded_path_and_objective()->void:
	var army:=_army(3,5_000)
	army["status"]="moving"
	army["destination_id"]="region_alpha"
	army["destination_name"]="North Road"
	army["destination_position"]={"x":180.0,"z":90.0}
	army["distance_remaining_km"]=120.0
	army["arrival_day"]=42
	var marker:=PRESENTATION.player_marker(army,320.0,false)
	assert_bool(bool(marker.show_path)).is_true()
	assert_bool(bool(marker.show_objective_label)).is_false()
	assert_str(String(marker.destination_id)).is_equal("region_alpha")
	assert_dict(marker.destination_position).is_not_empty()
	var world_marker:=PRESENTATION.player_marker(army,12_000.0,false)
	assert_bool(bool(world_marker.show_path)).is_false()


func test_billion_strength_changes_label_not_runtime_shape()->void:
	var armies:Array=[]
	for army_id in 30: armies.append(_army(army_id+1,1_000_000_000))
	var sightings:Array=[]
	for sighting_id in 70:
		var sighting:=_foreign(); sighting["id"]="foreign_%d" % sighting_id; sightings.append(sighting)
	var fronts:Array=[]
	for front_id in 20:
		var front:=_front(); front["id"]="front_%d" % front_id; fronts.append(front)
	var snapshot:=PRESENTATION.build_snapshot(400.0,armies,sightings,fronts,[_home(),_objective()],{},0)
	assert_int(snapshot.player.size()).is_equal(PRESENTATION.MAX_PLAYER_MARKERS)
	assert_int(snapshot.foreign.size()).is_equal(PRESENTATION.MAX_FOREIGN_MARKERS)
	assert_int(snapshot.fronts.size()).is_equal(PRESENTATION.MAX_FRONT_MARKERS)
	assert_str(String(snapshot.player[0].label)).contains("12.00B")
	assert_bool(bool(snapshot.bounded)).is_true()


func test_formation_echelon_is_bounded_and_reports_scale_without_more_units()->void:
	assert_int(PRESENTATION.formation_echelon(120)).is_equal(1)
	assert_int(PRESENTATION.formation_echelon(1200)).is_equal(2)
	assert_int(PRESENTATION.formation_echelon(12_000)).is_equal(3)
	assert_int(PRESENTATION.formation_echelon(1_000_000_000)).is_equal(4)
	var billion:=PRESENTATION.player_marker(_army(1,1_000_000_000),48.0,false)
	assert_int(int(billion.echelon)).is_equal(4)


func test_counter_role_and_era_follow_real_aggregate_composition()->void:
	var artillery_army:=_army(2,12_000)
	artillery_army.formations=[
		{"unit":"rifle_infantry","count":9000},
		{"unit":"modern_artillery","count":3000}
	]
	var view:=PRESENTATION.player_marker(artillery_army,48.0,false)
	assert_str(String(view.formation_role)).is_equal("artillery")
	assert_str(String(view.formation_unit)).is_equal("rifle_infantry")
	assert_int(int(view.formation_era)).is_equal(3)
	var levy_army:=_army(3,12_000)
	levy_army.formations=[{"unit":"levy","count":12_000}]
	var levy_view:=PRESENTATION.player_marker(levy_army,48.0,false)
	assert_str(String(levy_view.formation_role)).is_equal("infantry")
	assert_int(int(levy_view.formation_era)).is_equal(0)


func test_formation_condition_is_aggregate_bounded_and_damage_sensitive()->void:
	var army:=_army(4,1000)
	army["wounded_pool"]=220
	army["scattered_pool"]=120
	army["captured_pool"]=60
	army["formations"]=[{"unit":"levy","count":1000,"equipment_condition":0.48}]
	var state:Dictionary=PRESENTATION.formation_visual_state(army)
	assert_str(String(state.damage_state)).is_equal("damaged")
	assert_float(float(state.damage_ratio)).is_between(0.30,0.62)
	assert_int(int(state.element_budget)).is_equal(7)
	var view:=PRESENTATION.player_marker(army,48.0,false)
	assert_str(String(view.damage_state)).is_equal("damaged")
	assert_float(float(view.damage_ratio)).is_greater(0.0)
	assert_str(String(view.label)).contains("DAMAGED")


func test_readiness_changes_formation_order_without_adding_map_elements()->void:
	var ready:=_army(5,5000)
	var broken:=_army(6,5000)
	broken["readiness"]=0.18
	var ready_state:Dictionary=PRESENTATION.formation_visual_state(ready)
	var broken_state:Dictionary=PRESENTATION.formation_visual_state(broken)
	assert_str(String(ready_state.order_state)).is_equal("ordered")
	assert_str(String(broken_state.order_state)).is_equal("broken")
	assert_float(float(broken_state.scatter)).is_greater(float(ready_state.scatter))
	assert_int(int(broken_state.element_budget)).is_equal(int(ready_state.element_budget))


func test_local_formation_report_stays_in_two_compact_lines()->void:
	var army:=_army(1,12_500)
	army.status="moving"
	army.destination_name="North Road"
	army.destination_position={"x":20.0,"z":10.0}
	army.arrival_day=84
	var view:=PRESENTATION.player_marker(army,48.0,true)
	assert_int(String(view.label).split("\n").size()).is_equal(2)
	assert_str(String(view.label)).contains("READY 78%")
	assert_str(String(view.label)).contains("SUPPLY 64%")
	assert_float(absf(float(view.heading))).is_greater(0.01)


func test_visible_scout_label_tells_the_player_how_to_act()->void:
	var scout:=_foreign()
	scout["identified"]=false
	scout["civilization"]=""
	scout["carries_report"]=true
	var view:=PRESENTATION.foreign_marker(scout,48.0)
	assert_str(String(view.label)).contains("FOREIGN SCOUTS")
	assert_str(String(view.label)).contains("CLICK TO INTERCEPT")
	assert_int(String(view.label).split("\n").size()).is_equal(2)


func test_unknown_objectives_do_not_receive_invented_map_coordinates()->void:
	var snapshot:=PRESENTATION.build_snapshot(400.0,[],[],[_front()],[_home()],{},0)
	assert_array(snapshot.fronts).is_empty()


func test_regional_stacked_armies_collapse_to_one_aggregate_label()->void:
	var armies:Array=[]
	for army_id in 12:
		var army:=_army(army_id+1,1000+army_id*100)
		army.position={"x":float(army_id%3),"z":float(army_id%2)}
		armies.append(army)
	var snapshot:=PRESENTATION.build_snapshot(320.0,armies,[],[],[_home()],{},0)
	var visible_labels:Array=snapshot.player.filter(func(view:Dictionary)->bool: return bool(view.show_label))
	assert_int(visible_labels.size()).is_equal(1)
	assert_str(String(visible_labels[0].label)).contains("12 ARMIES")
	var occupied_display_slots:Dictionary={}
	for view in snapshot.player:
		var offset:Dictionary=view.get("display_offset",{})
		var slot:="%.3f:%.3f" % [float(offset.get("x",0.0)),float(offset.get("z",0.0))]
		assert_bool(occupied_display_slots.has(slot)).is_false()
		occupied_display_slots[slot]=true


func test_close_separated_armies_keep_individual_labels_and_locations()->void:
	var first:=_army(1,100)
	var second:=_army(2,200)
	first.position={"x":0.0,"z":0.0}
	second.position={"x":0.3,"z":0.0}
	var snapshot:=PRESENTATION.build_snapshot(0.7,[first,second],[],[],[],{},0)
	for view in snapshot.player:
		assert_bool(bool(view.show_label)).is_true()
		assert_int(int(view.get("cluster_count",0))).is_equal(1)
		assert_float(float(view.display_offset.x)).is_equal(0.0)
		assert_float(float(view.display_offset.z)).is_equal(0.0)


func test_close_distinct_opponents_do_not_share_a_contact_lane()->void:
	var army:=_army(1,100)
	army.position={"x":0.0,"z":0.0}
	var sighting:=_foreign()
	sighting.position={"x":0.3,"z":0.0}
	var snapshot:=PRESENTATION.build_snapshot(0.7,[army],[sighting],[],[],{},0)
	assert_bool(bool(snapshot.player[0].get("contested_location",false))).is_false()
	assert_bool(bool(snapshot.foreign[0].get("contested_location",false))).is_false()


func test_close_colocated_armies_still_receive_separate_counter_slots()->void:
	var first:=_army(1,100)
	var second:=_army(2,200)
	first.position={"x":0.0,"z":0.0}
	second.position={"x":0.0,"z":0.0}
	var snapshot:=PRESENTATION.build_snapshot(0.7,[first,second],[],[],[],{},0)
	assert_float(absf(float(snapshot.player[0].display_offset.x)-float(snapshot.player[1].display_offset.x))).is_greater(PRESENTATION.marker_scale(0.7)*6.0)
	var labels:Array=snapshot.player.filter(func(view:Dictionary)->bool: return bool(view.show_label))
	assert_int(labels.size()).is_equal(1)
	assert_str(String(labels[0].label)).contains("2 ARMIES")


func test_counter_clearance_tracks_close_zoom_and_caps_regionally()->void:
	assert_float(PRESENTATION.marker_ground_clearance(0.7)).is_less(0.001)
	assert_float(PRESENTATION.marker_ground_clearance(0.001)).is_greater(0.0)
	assert_float(PRESENTATION.marker_ground_clearance(320.0)).is_equal(0.18)
	assert_float(PRESENTATION.marker_ground_clearance(12000.0)).is_equal(0.18)


func test_regional_foreign_stack_uses_unique_nonoverlapping_counter_slots()->void:
	var sightings:Array=[]
	for sighting_id in 8:
		var sighting:=_foreign()
		sighting["id"]="foreign_%d" % sighting_id
		sighting["position"]={"x":12.0,"z":8.0}
		sightings.append(sighting)
	var snapshot:=PRESENTATION.build_snapshot(320.0,[],sightings,[],[_home()],{},0)
	var occupied_display_slots:Dictionary={}
	var minimum_spacing:=float(snapshot.marker_scale)*6.25
	for view in snapshot.foreign:
		var offset:Dictionary=view.get("display_offset",{})
		var point:=Vector2(float(offset.get("x",0.0)),float(offset.get("z",0.0)))
		var slot:="%.3f:%.3f" % [point.x,point.y]
		assert_bool(occupied_display_slots.has(slot)).is_false()
		for occupied_variant in occupied_display_slots.values():
			assert_float(point.distance_to(occupied_variant as Vector2)).is_greater_equal(minimum_spacing*0.75)
		occupied_display_slots[slot]=point
	var visible_labels:Array=snapshot.foreign.filter(func(view:Dictionary)->bool: return bool(view.show_label))
	assert_int(visible_labels.size()).is_equal(1)
	assert_str(String(visible_labels[0].label)).contains("8 ARMIES")


func test_opposing_formations_at_one_location_receive_separate_faction_lanes()->void:
	var army:=_army(1,4000)
	army["position"]={"x":12.0,"z":8.0}
	var sighting:=_foreign()
	sighting["position"]={"x":12.0,"z":8.0}
	var snapshot:=PRESENTATION.build_snapshot(320.0,[army],[sighting],[],[_home()],{},1)
	var player_offset:Dictionary=snapshot.player[0].display_offset
	var foreign_offset:Dictionary=snapshot.foreign[0].display_offset
	assert_bool(bool(snapshot.player[0].contested_location)).is_true()
	assert_bool(bool(snapshot.foreign[0].contested_location)).is_true()
	assert_float(absf(float(player_offset.x)-float(foreign_offset.x))).is_greater_equal(float(snapshot.marker_scale)*7.4)
	assert_bool(bool(snapshot.player[0].show_label)).is_true()
	assert_bool(bool(snapshot.foreign[0].show_label)).is_false()
	assert_bool(bool(snapshot.foreign[0].label_suppressed_by_contact)).is_true()


func test_foreign_sighting_only_claims_movement_when_observed()->void:
	var stationary:=PRESENTATION.foreign_marker(_foreign(),48.0)
	assert_bool(bool(stationary.moving)).is_false()
	var moving_sighting:=_foreign()
	moving_sighting["movement_observed"]=true
	moving_sighting["heading"]=1.25
	var moving:=PRESENTATION.foreign_marker(moving_sighting,48.0)
	assert_bool(bool(moving.moving)).is_true()
	assert_float(float(moving.heading)).is_equal_approx(1.25,0.001)


func test_observed_foreign_damage_and_identified_role_reach_the_fixed_counter()->void:
	var sighting:=_foreign()
	sighting["identified"]=true
	sighting["formation_role"]="artillery"
	sighting["formation_era"]=2
	sighting["damage_estimate"]=0.47
	var view:Dictionary=PRESENTATION.foreign_marker(sighting,48.0)
	assert_str(String(view.formation_role)).is_equal("artillery")
	assert_int(int(view.formation_era)).is_equal(2)
	assert_str(String(view.damage_state)).is_equal("damaged")
	assert_float(float(view.damage_ratio)).is_equal_approx(0.47,0.001)
	assert_str(String(view.label)).contains("DAMAGED")


func test_occupation_front_is_distinct_from_battle_and_generic_objective()->void:
	var front:=_front()
	front["occupation_personnel"]=3200
	var view:=PRESENTATION.front_marker(front,_objective(),320.0,false)
	assert_bool(bool(view.occupation_active)).is_true()
	assert_int(int(view.occupation_personnel)).is_equal(3200)
	assert_str(String(view.phase)).is_equal("OCCUPATION")
	assert_str(String(view.label)).contains("OCCUPATION FRONT")


func test_continental_label_budget_prioritizes_selected_and_moving_armies()->void:
	var armies:Array=[]
	for army_id in 8:
		var army:=_army(army_id+1,2000+army_id*100)
		army.position={"x":float(army_id)*500.0,"z":float(army_id%2)*500.0}
		if army_id==1:
			army.status="moving"; army.destination_name="NORTH ROAD"
		armies.append(army)
	var snapshot:=PRESENTATION.build_snapshot(3200.0,armies,[],[],[_home()],{},3)
	var visible_labels:Array=snapshot.player.filter(func(view:Dictionary)->bool: return bool(view.show_label))
	assert_int(visible_labels.size()).is_less_equal(3)
	assert_bool(bool(snapshot.player[1].show_label)).is_true()
	assert_bool(bool(snapshot.player[2].show_label)).is_true()


func test_world_fronts_are_clustered_and_label_budget_is_bounded()->void:
	var fronts:Array=[]
	var destinations:Array=[_home()]
	for front_id in 8:
		var front:=_front(); front.id="front_%d" % front_id; front.target_region_id="region_%d" % front_id; fronts.append(front)
		destinations.append({"id":"region_%d" % front_id,"position":{"x":float(front_id%2)*80.0,"z":float(front_id%3)*80.0}})
	var snapshot:=PRESENTATION.build_snapshot(12_000.0,[],[],fronts,destinations,{},0)
	var visible_labels:Array=snapshot.fronts.filter(func(view:Dictionary)->bool: return bool(view.show_label))
	assert_int(visible_labels.size()).is_equal(1)
	assert_str(String(visible_labels[0].label)).contains("8 ACTIVE WARS")


func test_ground_scale_keeps_units_visible_and_correctly_scaled()->void:
	var snapshot:=PRESENTATION.build_snapshot(7.99,[_army(1,1000)],[_foreign()],[_front()],[_home(),_objective()],{},1)
	assert_bool(bool(snapshot.player[0].visible)).is_true()
	assert_bool(bool(snapshot.player[0].show_label)).is_true()
	assert_bool(bool(snapshot.foreign[0].visible)).is_true()
	assert_float(float(snapshot.player[0].scale)).is_equal_approx(7.99*0.016,0.001)
	assert_str(String(snapshot.player[0].label)).contains("SOLDIERS")
	assert_bool(bool(snapshot.fronts[0].visible)).is_false()
	assert_bool(bool(snapshot.fronts[0].show_label)).is_false()


func _army(army_id:int,troops:int)->Dictionary:
	return {"army_id":army_id,"name":"First Field Army","troops":troops,"readiness":0.78,"supply_level":0.64,"status":"stationed","location_name":"HOME","position":{"x":0.0,"z":0.0}}


func _foreign()->Dictionary:
	return {"id":"foreign_1","label":"CEDAR HOST","civ_id":"cedar","civilization":"Cedar League","identified":true,"hostile":true,"carries_report":false,"strength_estimate_low":900,"strength_estimate_high":1500,"readiness_estimate_low":0.42,"readiness_estimate_high":0.66,"distance_km":18.0,"position":{"x":12.0,"z":8.0}}


func _front()->Dictionary:
	return {"id":"front_cedar","war_name":"War of the North Road","opponent":"Cedar League","target_region_id":"region_alpha","target":"North Road","objective":"Take North Road","progress":0.43,"field_personnel":2200,"inbound_personnel":800,"occupation_personnel":0,"readiness":0.61,"supply":0.72}


func _home()->Dictionary:
	return {"id":"player_home","position":{"x":0.0,"z":0.0}}


func _objective()->Dictionary:
	return {"id":"region_alpha","position":{"x":180.0,"z":90.0}}

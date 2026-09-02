extends GdUnitTestSuite

const PRESENTATION:=preload("res://scripts/warfare_map_presentation.gd")


func test_player_marker_communicates_owner_strength_readiness_supply_and_selection()->void:
	var marker:=PRESENTATION.player_marker(_army(7,12_500),48.0,true)
	assert_bool(bool(marker.visible)).is_true()
	assert_bool(bool(marker.selected)).is_true()
	assert_str(String(marker.owner_label)).is_equal("YOU")
	assert_str(String(marker.label)).contains("12.5K")
	assert_str(String(marker.label)).contains("READY 78%")
	assert_str(String(marker.label)).contains("SUPPLY 64%")
	assert_str(String(marker.color)).is_equal(PRESENTATION.PLAYER_SELECTED_COLOR)


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
	assert_int(int(view.formation_era)).is_equal(3)
	var levy_army:=_army(3,12_000)
	levy_army.formations=[{"unit":"levy","count":12_000}]
	var levy_view:=PRESENTATION.player_marker(levy_army,48.0,false)
	assert_str(String(levy_view.formation_role)).is_equal("infantry")
	assert_int(int(levy_view.formation_era)).is_equal(0)


func test_local_formation_report_stays_in_three_compact_lines()->void:
	var army:=_army(1,12_500)
	army.status="moving"
	army.destination_name="North Road"
	army.destination_position={"x":20.0,"z":10.0}
	army.arrival_day=84
	var view:=PRESENTATION.player_marker(army,48.0,true)
	assert_int(String(view.label).split("\n").size()).is_equal(3)
	assert_str(String(view.label)).contains("READY 78%")
	assert_str(String(view.label)).contains("SUPPLY 64%")
	assert_float(absf(float(view.heading))).is_greater(0.01)


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


func test_ground_scale_hides_all_warfare_tokens_and_labels()->void:
	var snapshot:=PRESENTATION.build_snapshot(7.99,[_army(1,1000)],[_foreign()],[_front()],[_home(),_objective()],{},1)
	assert_bool(bool(snapshot.player[0].visible)).is_false()
	assert_bool(bool(snapshot.player[0].show_label)).is_false()
	assert_bool(bool(snapshot.foreign[0].visible)).is_false()
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

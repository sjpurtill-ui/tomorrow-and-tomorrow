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


func test_visual_grammar_distinguishes_battlefield_roles_and_eras()->void:
	var ancient:=PRESENTATION.formation_visual_profile(_formation_force("levy","improvised",1000))
	var medieval:=PRESENTATION.formation_visual_profile(_formation_force("cavalry","lance",1000))
	var early_modern:=PRESENTATION.formation_visual_profile(_formation_force("field_artillery","field_gun",1000))
	var industrial:=PRESENTATION.formation_visual_profile(_formation_force("rifle_infantry","service_rifle",1000))
	var mechanized:=PRESENTATION.formation_visual_profile(_formation_force("motorized_infantry","motorized_kit",1000))
	var modern:=PRESENTATION.formation_visual_profile(_formation_force("armored_formation","armored_vehicle",1000))
	assert_str(String(ancient.role)).is_equal("infantry")
	assert_str(String(ancient.symbol_family)).is_equal("rank_block")
	assert_str(String(medieval.role)).is_equal("mobile")
	assert_str(String(medieval.era)).is_equal("medieval")
	assert_str(String(early_modern.role)).is_equal("artillery")
	assert_str(String(early_modern.era)).is_equal("early_modern")
	assert_str(String(industrial.era)).is_equal("industrial")
	assert_str(String(mechanized.era)).is_equal("mechanized")
	assert_str(String(modern.role)).is_equal("armored")
	assert_str(String(modern.era)).is_equal("modern")
	assert_str(String(modern.symbol_family)).is_equal("armored_wedge")


func test_readiness_and_damage_change_treatment_inside_the_same_budget()->void:
	var intact_force:=_formation_force("line_infantry","spear",1000)
	intact_force.readiness=0.9
	var battered_force:=_formation_force("line_infantry","spear",500)
	battered_force.readiness=0.28
	battered_force.formations[0].authorized_count=1000
	battered_force.formations[0].personnel_condition=0.5
	var intact:=PRESENTATION.formation_visual_profile(intact_force)
	var battered:=PRESENTATION.formation_visual_profile(battered_force)
	assert_str(String(intact.readiness_state)).is_equal("ordered")
	assert_str(String(intact.damage_state)).is_equal("intact")
	assert_str(String(battered.readiness_state)).is_equal("disordered")
	assert_str(String(battered.damage_state)).is_equal("battered")
	assert_bool(bool(battered.fractured)).is_true()
	assert_int(int(battered.missing_elements)).is_greater(0)
	assert_int(int(intact.element_budget)).is_equal(int(battered.element_budget))
	assert_int(int(battered.element_budget)).is_less_equal(PRESENTATION.MAX_FORMATION_VISUAL_ELEMENTS)


func test_billion_personnel_never_increase_formation_primitive_budget()->void:
	var thousand:=PRESENTATION.formation_visual_profile(_formation_force("armored_formation","armored_vehicle",1000))
	var billion:=PRESENTATION.formation_visual_profile(_formation_force("armored_formation","armored_vehicle",1_000_000_000))
	assert_int(int(billion.element_budget)).is_equal(int(thousand.element_budget))
	assert_int(int(billion.visible_elements)).is_equal(int(thousand.visible_elements))
	assert_int(int(billion.element_budget)).is_less_equal(PRESENTATION.MAX_FORMATION_VISUAL_ELEMENTS)


func test_unidentified_foreign_movement_does_not_invent_role_or_era()->void:
	var sighting:=_foreign()
	sighting.identified=false
	sighting.erase("kind")
	var marker:=PRESENTATION.foreign_marker(sighting,48.0)
	assert_str(String(marker.role)).is_equal("unknown")
	assert_str(String(marker.era)).is_equal("unknown")
	assert_bool(bool(marker.visual_profile.era_known)).is_false()


func test_identified_scout_uses_scout_screen_without_inventing_an_era()->void:
	var sighting:=_foreign()
	sighting.kind="scout"
	sighting.carries_report=true
	var marker:=PRESENTATION.foreign_marker(sighting,48.0)
	assert_str(String(marker.role)).is_equal("scout")
	assert_str(String(marker.symbol_family)).is_equal("scout_screen")
	assert_str(String(marker.era)).is_equal("unknown")


func _army(army_id:int,troops:int)->Dictionary:
	return {"army_id":army_id,"name":"First Field Army","troops":troops,"readiness":0.78,"supply_level":0.64,"status":"stationed","location_name":"HOME","position":{"x":0.0,"z":0.0}}


func _formation_force(unit:String,weapon:String,count:int)->Dictionary:
	return {"troops":count,"readiness":0.78,"formations":[{"unit":unit,"weapon":weapon,"count":count,"authorized_count":count,"personnel_condition":1.0}]}


func _foreign()->Dictionary:
	return {"id":"foreign_1","label":"CEDAR HOST","civ_id":"cedar","civilization":"Cedar League","identified":true,"hostile":true,"carries_report":false,"strength_estimate_low":900,"strength_estimate_high":1500,"readiness_estimate_low":0.42,"readiness_estimate_high":0.66,"distance_km":18.0,"position":{"x":12.0,"z":8.0}}


func _front()->Dictionary:
	return {"id":"front_cedar","war_name":"War of the North Road","opponent":"Cedar League","target_region_id":"region_alpha","target":"North Road","objective":"Take North Road","progress":0.43,"field_personnel":2200,"inbound_personnel":800,"occupation_personnel":0,"readiness":0.61,"supply":0.72}


func _home()->Dictionary:
	return {"id":"player_home","position":{"x":0.0,"z":0.0}}


func _objective()->Dictionary:
	return {"id":"region_alpha","position":{"x":180.0,"z":90.0}}

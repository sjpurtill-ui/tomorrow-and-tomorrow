extends "res://tests/test_surprise_hostilities.gd"
func test_nearby_order_attacks_without_registration_and_preserves_personnel()->void:
	var f:=_peace_fixture()
	MilitaryCampaign.field_armies[0].location_id="field_position"
	MilitaryCampaign.field_armies[0].position=CivilizationSystem.city_intelligence.known("player",f.region).position.duplicate(true)
	var population:=GameState.population_total
	assert_bool(MilitaryCampaign.order_city_operation(f.army,f.civ,f.region).has("error")).is_false()
	assert_bool(CivilizationSystem.civilizations[0].player_relation.at_war).is_true()
	assert_int(GameState.population_total).is_equal(population)
func test_far_order_marches_then_attacks_and_does_not_start_war_on_departure()->void:
	var f:=_peace_fixture()
	var position:Dictionary=CivilizationSystem.city_intelligence.known("player",f.region).position
	MilitaryCampaign.field_armies[0].position={"x":float(position.x)+10,"z":float(position.z)}
	MilitaryCampaign.field_armies[0].location_id="field_position"
	assert_bool(MilitaryCampaign.order_city_operation(f.army,f.civ,f.region).get("queued",false)).is_true()
	assert_bool(CivilizationSystem.civilizations[0].player_relation.at_war).is_false()
	var saved:Dictionary=MilitaryCampaign.export_state()
	assert_bool(MilitaryCampaign.import_state(saved).has("ok")).is_true()
	for day in 20:
		if not MilitaryCampaign.active_engagement.is_empty():break
		GameState.elapsed_days+=1;MilitaryCampaign._process_field_army_movement_day()
	assert_dict(MilitaryCampaign.active_engagement).is_not_empty()
	assert_bool(CivilizationSystem.civilizations[0].player_relation.at_war).is_true()
func test_new_movement_cancels_queued_attack()->void:
	var f:=_peace_fixture();MilitaryCampaign.field_armies[0].position={"x":0,"z":0}
	MilitaryCampaign.order_city_operation(f.army,f.civ,f.region)
	MilitaryCampaign.return_field_army(f.army)
	assert_bool(MilitaryCampaign.field_armies[0].has("city_operation")).is_false()
	assert_bool(CivilizationSystem.civilizations[0].player_relation.at_war).is_false()
func test_empty_army_cannot_move_and_keeps_scattered_record()->void:
	var f:=_peace_fixture();MilitaryCampaign.field_armies[0].troops=0;MilitaryCampaign.field_armies[0].scattered_pool=2
	assert_bool(MilitaryCampaign.order_city_operation(f.army,f.civ,f.region).has("error")).is_true()
	assert_bool(MilitaryCampaign.move_field_army(f.army,f.region).has("error")).is_true()
	assert_int(int(MilitaryCampaign.field_armies[0].scattered_pool)).is_equal(2)
func test_death_rows_group_counts_but_not_different_places_or_causes()->void:
	var ledger:Array=[{"kind":"death","count":1,"day":61,"location":"SeanTown in The Known World","cause":"Natural causes"},{"kind":"death","count":2,"day":65,"location":"SeanTown in The Known World","cause":"Natural causes"},{"kind":"death","count":1,"day":65,"location":"Other","cause":"Natural causes"},{"kind":"death","count":1,"day":65,"location":"SeanTown in The Known World","cause":"Battle"}]
	var before:=ledger.duplicate(true)
	var rows:=preload("res://scripts/hud/content/dock_detail_population_ledger.gd").grouped_deaths(ledger)
	assert_int(rows.size()).is_equal(3)
	assert_str(String(rows[0].value)).is_equal("3 deaths")
	assert_str(String(rows[0].name)).is_equal("SeanTown")
	assert_array(ledger).is_equal(before)

func test_selected_army_is_used_when_two_are_at_city()->void:
	var f:=_peace_fixture()
	var second:Dictionary=MilitaryCampaign.field_armies[0].duplicate(true)
	second.army_id=99;second.name="Selected second army"
	second.position=CivilizationSystem.city_intelligence.known("player",f.region).position.duplicate(true)
	MilitaryCampaign.field_armies.append(second)
	assert_bool(MilitaryCampaign.order_city_operation(99,f.civ,f.region).has("error")).is_false()
	assert_int(int(MilitaryCampaign.active_engagement.threat.field_army_id)).is_equal(99)

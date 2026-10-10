extends GdUnitTestSuite
## Reviewed lifecycle transitions: real transfers survive changed destinations,
## battle reservations and failed roads without duplicate troops or orders.
const Fixture:=preload("res://tests/test_border_deployment_refresh.gd")
const Council:=preload("res://scripts/war_council.gd")
const Defense:=preload("res://scripts/border_defense.gd")
var f:Node
func before_test()->void:
	f=Fixture.new();add_child(f);f.before_test()
func after_test()->void:
	f.after_test();f.free()
func _army(id:int)->Dictionary:
	var index:=MilitaryCampaign._field_army_index(id)
	return MilitaryCampaign.field_armies[index] if index>=0 else {}
func _growth()->Array:
	f._deploy(1000);f._home(19200)
	Council.order(String(f.fixture.civ_id),"defend")
	var band:Dictionary=MilitaryCampaign.field_armies[0]
	var drafts:=MilitaryCampaign.field_armies.filter(func(row:Dictionary)->bool:return int(row.get("border_reinforcement",{}).get("army_id",-1))==int(band.army_id))
	return [band,drafts[0]]
func test_reinforcements_return_physically_when_destination_band_is_retasked()->void:
	var pair:=_growth();var target:Dictionary=pair[0];var draft:Dictionary=pair[1]
	GameState.elapsed_days+=1;MilitaryCampaign._process_field_army_movement_day()
	var where:Dictionary=draft.position.duplicate(true);var id:=int(draft.army_id)
	MilitaryCampaign.move_field_army_to_position(int(target.army_id),f.fixture.origin.x+5,f.fixture.origin.y,"Other duty")
	Council.order(String(f.fixture.civ_id),"defend")
	assert_dict(draft.position).is_equal(where)
	assert_bool(draft.has("border_reinforcement")).is_false()
	assert_str(String(draft.destination_id)).is_equal("player_home")
	assert_bool(target.has("council")).is_false()
	assert_int(f._total()).is_equal(20000)
	f._march();Council.sit(int(GameState.elapsed_days))
	assert_int(f._total()).is_equal(20000)
	assert_bool(_army(id).is_empty()).is_true()
	assert_vector(Defense.point(target.position)).is_equal(f.fixture.origin+Vector2(5,0))
func test_reinforcements_keep_their_ledger_when_destination_band_is_destroyed()->void:
	var pair:=_growth();var target:Dictionary=pair[0];var draft:Dictionary=pair[1]
	GameState.elapsed_days+=1;MilitaryCampaign._process_field_army_movement_day()
	var where:Dictionary=draft.position.duplicate(true)
	MilitaryCampaign.field_armies.remove_at(MilitaryCampaign._field_army_index(int(target.army_id)))
	Council.order(String(f.fixture.civ_id),"defend")
	assert_dict(draft.position).is_equal(where)
	assert_str(String(draft.destination_id)).is_equal("player_home")
	assert_int(f._total()).is_equal(19900)
	f._march();Council.sit(int(GameState.elapsed_days))
	assert_int(f._total()).is_equal(19900)
func test_arrived_reinforcements_wait_for_target_battle_and_merge_once()->void:
	var pair:=_growth();var target:Dictionary=pair[0];var draft:Dictionary=pair[1]
	f._march()
	MilitaryCampaign.own_engagements["reserved"]={"home_force_kind":"field_army","home_force_id":int(target.army_id)}
	for i in 3:Council.order(String(f.fixture.civ_id),"defend")
	assert_int(int(target.troops)).is_equal(100)
	assert_int(int(draft.troops)).is_equal(1900)
	assert_int(f._total()).is_equal(20000)
	MilitaryCampaign.own_engagements.clear()
	for i in 3:Council.order(String(f.fixture.civ_id),"defend")
	assert_int(int(target.troops)).is_equal(2000)
	assert_int(f._total()).is_equal(20000)
	assert_int(MilitaryCampaign.field_armies.size()).is_equal(8)
func test_changed_border_recovers_after_no_land_route_without_clearing_assignment()->void:
	f._deploy(20000)
	GameState.border_forts.forts.append({"id":1,"kind":"earthwork_fort","x":f.fixture.origin.x+50,"z":f.fixture.origin.y,"status":"standing","condition":1.0})
	CivilizationSystem.set_scout_geography_authority(func(at:Vector2)->bool:return at.distance_to(f.fixture.origin)<30 or at.distance_to(f.fixture.origin)>40)
	var old:Dictionary=MilitaryCampaign.field_armies[0].position.duplicate(true)
	Council.order(String(f.fixture.civ_id),"defend")
	var band:Dictionary=MilitaryCampaign.field_armies[0]
	assert_dict(band.position).is_equal(old)
	assert_bool(band.has("border_sector")).is_true()
	assert_array(Array(Defense.coverage(band))).is_empty()
	Council.order(String(f.fixture.civ_id),"defend")
	assert_bool(band.has("council")).is_true()
	CivilizationSystem.set_scout_geography_authority(func(_at:Vector2)->bool:return true)
	Council.order(String(f.fixture.civ_id),"defend")
	assert_str(String(band.status)).is_equal("moving")
	assert_dict(band.position).is_equal(old)
	assert_int(f._total()).is_equal(20000)
func test_two_front_arrivals_cannot_reserve_same_legacy_defender_twice()->void:
	f.fixture._start_world()
	CivilizationSystem.civilizations[0].player_relation.at_war=true
	var results:=[]
	for i in 2:
		var made:=MilitaryCampaign.create_field_army(200)
		var army:=_army(int(made.army.army_id))
		army.position={"x":f.fixture.origin.x+2.7,"z":f.fixture.origin.y}
		var p:=Defense.point(army.position)
		var contact:=Defense.first_contact(p,p,MilitaryCampaign.command_hierarchy.land.enemies(int(GameState.elapsed_days)),army)
		results.append(MilitaryCampaign.launch_front_contact(int(army.army_id),contact))
	print("REVIEW2_DUPLICATE ",{"battles":MilitaryCampaign.own_engagements.size(),"second":results[1].get("error","")})
	assert_int(MilitaryCampaign.own_engagements.size()).is_equal(1)
	assert_bool(results[1].has("error")).is_true()

func test_reserved_hungry_post_cannot_reappear_over_its_replacement()->void:
	f._deploy(20000)
	var original:Dictionary=MilitaryCampaign.field_armies[0]
	var slot:=int(original.border_sector.index)
	var before:Dictionary=original.position.duplicate(true)
	MilitaryCampaign.own_engagements["reserved"]={"home_force_kind":"field_army","home_force_id":int(original.army_id)}
	original.provision_ratio=0.1
	f._home(8000);Council.order(String(f.fixture.civ_id),"defend")
	assert_bool(original.has("border_sector")).is_false()
	assert_dict(original.position).is_equal(before)
	assert_bool(MilitaryCampaign.command_hierarchy.battle.engaged(int(original.army_id))).is_true()
	original.provision_ratio=1.0;MilitaryCampaign.own_engagements.clear()
	Council.order(String(f.fixture.civ_id),"defend")
	var same_slot:=MilitaryCampaign.field_armies.filter(func(row:Dictionary)->bool:return row.has("border_sector") and int(row.border_sector.index)==slot and String(row.council.get("phase",""))!="home")
	print("REVIEW2_DUPLICATE_POST ",{"slot":slot,"count":same_slot.size(),"men":same_slot.map(func(row:Dictionary)->int:return int(row.troops)),"total":f._total()})
	assert_int(same_slot.size()).is_equal(1)
func test_returning_border_band_accepts_new_explicit_duty()->void:
	f._deploy(20000)
	var band:Dictionary=MilitaryCampaign.field_armies[0]
	Council.order(String(f.fixture.civ_id),"leave")
	var destination:Vector2=f.fixture.origin+Vector2(5,0)
	var moved:=MilitaryCampaign.move_field_army_to_position(int(band.army_id),destination.x,destination.y,"New duty")
	assert_bool(moved.has("ok")).is_true()
	Council.sit(int(GameState.elapsed_days))
	print("REVIEW2_RETURN_RETASK ",{"destination":band.destination_position,"name":band.destination_name,"council":band.get("council",{})})
	assert_vector(Defense.point(band.destination_position)).is_equal(destination)
	assert_bool(band.has("council")).is_false()
	f._march();Council.sit(int(GameState.elapsed_days))
	assert_bool(_army(int(band.army_id)).is_empty()).is_false()
	assert_vector(Defense.point(band.position)).is_equal(destination)
	assert_bool(band.has("council")).is_false()

func test_returning_band_keeps_new_city_destination_as_well_as_map_posts()->void:
	f._deploy(20000)
	var band:Dictionary=MilitaryCampaign.field_armies[0]
	Council.order(String(f.fixture.civ_id),"leave")
	var moved:=MilitaryCampaign.move_field_army(int(band.army_id),String(f.fixture.city_id))
	assert_bool(moved.has("ok")).override_failure_message(str(moved)).is_true()
	Council.sit(int(GameState.elapsed_days))
	assert_str(String(band.destination_id)).is_equal(String(f.fixture.city_id))
	assert_bool(band.has("council")).is_false()

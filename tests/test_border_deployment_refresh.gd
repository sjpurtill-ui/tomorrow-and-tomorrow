extends GdUnitTestSuite
const Fixture:=preload("res://tests/test_border_defense_campaign.gd")
const Council:=preload("res://scripts/war_council.gd")
const Defense:=preload("res://scripts/border_defense.gd")
const Forts:=preload("res://scripts/fort_border.gd")
var fixture:Node
func before_test()->void:
	fixture=Fixture.new();add_child(fixture)
func after_test()->void:
	fixture.after_test();fixture.free()
func _home(n:int)->void:
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("Reserve",[{"id":999,"unit":"levy","weapon":"improvised","count":n,"equipment":n,"training":0.8}],0.9,0.9)
	MilitaryCampaign.home_army.provision_ratio=1.0;MilitaryCampaign.home_army.supply_level=1.0
func _deploy(n:int)->void:
	fixture._start_world();GameState.ensure_population_total(100000)
	GameState.border_forts={"forts":[],"border_share":0.0,"next_id":1,"seeded":true}
	CivilizationSystem._add_revealed_area(fixture.origin,200,"deployment survey")
	CivilizationSystem.foreign_formations.clear()
	for discovery in ["military_staffs","radio_telegraphy"]:
		if not discovery in GameState.known_discoveries:GameState.known_discoveries.append(discovery)
		GameState.discovery_adoption[discovery]=1.0
	_home(n);Council.order(String(fixture.civ_id),"defend")
	for day in 6:
		GameState.elapsed_days+=1;MilitaryCampaign._process_field_army_movement_day()
func _field_men()->int:
	var n:=0
	for band:Dictionary in MilitaryCampaign.field_armies:n+=int(band.troops)
	return n
func _march(days:int=8)->void:
	for day in days:
		GameState.elapsed_days+=1;MilitaryCampaign._process_field_army_movement_day()
func _held()->float:
	var km:=0.0
	for band:Dictionary in MilitaryCampaign.field_armies:km+=Defense.length(Defense.coverage(band,int(GameState.elapsed_days)))
	return km
func _total()->int:
	return int(MilitaryCampaign.home_army.troops)+_field_men()
func _grow_border()->void:
	_deploy(1000)
	var before:=_field_men();var held:=_held()
	var ids:=MilitaryCampaign.field_armies.map(func(band:Dictionary)->int:return int(band.army_id))
	_home(20000-before)
	Council.order(String(fixture.civ_id),"defend")
	assert_int(_total()).is_equal(20000)
	assert_int(int(MilitaryCampaign.home_army.troops)).is_equal(4000)
	assert_int(MilitaryCampaign.field_armies.size()).is_between(9,16)
	assert_float(_held()).is_equal_approx(held,0.001)
	for band:Dictionary in MilitaryCampaign.field_armies:
		if ids.has(int(band.army_id)):assert_int(int(band.troops)).is_equal(100)
		else:
			assert_str(String(band.status)).is_equal("moving")
			assert_vector(Defense.point(band.position)).is_equal(fixture.origin)
			assert_array(Array(Defense.coverage(band))).is_empty()
	Council.order(String(fixture.civ_id),"defend")
	assert_int(MilitaryCampaign.field_armies.size()).is_equal(16)
	# A save/load on the road must preserve the transfers, not repeat them.
	var loaded:=MilitaryCampaign.import_state(JSON.parse_string(JSON.stringify(MilitaryCampaign.export_state())))
	assert_bool(loaded.has("ok")).override_failure_message(str(loaded)).is_true()
	_march();Council.order(String(fixture.civ_id),"defend")
	assert_int(MilitaryCampaign.field_armies.size()).is_equal(8)
	assert_int(_total()).is_equal(20000)
	for band:Dictionary in MilitaryCampaign.field_armies:
		assert_bool(ids.has(int(band.army_id))).is_true()
		assert_int(int(band.troops)).is_equal(2000)
func test_real_reinforcements_fill_old_thin_sectors_only_after_arriving()->void:
	_grow_border()
	var outline:PackedVector2Array=Forts.outline().points
	var perimeter:=Defense.length(outline)+outline[-1].distance_to(outline[0])
	assert_float(_held()).is_equal_approx(perimeter,0.05)
	# Sample both directions and both owners over the whole closed perimeter,
	# including every sector seam; summed length alone cannot prove closure.
	var forces:Array=JSON.parse_string(JSON.stringify(MilitaryCampaign.field_armies))
	for band:Dictionary in forces:band["owner"]="defender"
	for i in 64:
		var outside:Vector2=fixture.origin+Vector2.RIGHT.rotated(TAU*float(i)/64.0)*40.0
		var inwards:=Defense.first_contact(outside,fixture.origin,forces,{"troops":200,"owner":"invader"})
		var outwards:=Defense.first_contact(fixture.origin,outside,forces,{"troops":200,"owner":"invader"})
		assert_dict(inwards).override_failure_message("Unheld radial approach %d" % i).is_not_empty()
		assert_dict(outwards).override_failure_message("Unheld reverse approach %d" % i).is_not_empty()
	for band:Dictionary in forces:band.owner="invader"
	assert_dict(Defense.first_contact(fixture.origin+Vector2(40,0),fixture.origin,forces,{"troops":200,"owner":"defender"})).is_not_empty()
func test_new_fort_border_remarches_existing_people_without_remote_coverage()->void:
	_deploy(20000)
	var old:={}
	for band:Dictionary in MilitaryCampaign.field_armies:old[int(band.army_id)]=band.position.duplicate(true)
	GameState.border_forts.forts.append({"id":1,"kind":"earthwork_fort","x":fixture.origin.x+50,"z":fixture.origin.y,"status":"standing","condition":1.0})
	Council.order(String(fixture.civ_id),"defend")
	var moving:=0
	for band:Dictionary in MilitaryCampaign.field_armies:
		assert_dict(band.position).is_equal(old[int(band.army_id)])
		if String(band.status)=="moving":
			moving+=1
			assert_array(Array(Defense.coverage(band))).is_empty()
	assert_int(moving).is_greater(0)
	assert_int(_total()).is_equal(20000)
	_march(18);Council.order(String(fixture.civ_id),"defend")
	var current:Dictionary=Forts.outline()
	for band:Dictionary in MilitaryCampaign.field_armies:
		assert_array(Array(Defense.points(band.border_sector.outline))).is_equal(Array(current.points))
		assert_vector(Defense.point(band.position)).is_equal(Defense.point(band.border_sector.anchor))
		assert_array(Array(Defense.coverage(band))).is_not_empty()
func test_reassigned_band_keeps_new_duty_and_vacates_its_border_slot()->void:
	_deploy(20000)
	var band:Dictionary=MilitaryCampaign.field_armies[0];var id:=int(band.army_id);var slot:=int(band.border_sector.index)
	var moved:=MilitaryCampaign.move_field_army_to_position(id,fixture.origin.x,fixture.origin.y,"Other duty")
	assert_bool(moved.has("ok")).is_true()
	Council.order(String(fixture.civ_id),"defend")
	assert_bool(band.has("council")).is_false()
	assert_bool(band.has("border_sector")).is_false()
	assert_str(String(band.destination_name)).is_equal("Other duty")
	# The watch still owns the entire old reserve. New actual trained people
	# give the council spare troops with which to fill the vacated station.
	_home(6000);Council.order(String(fixture.civ_id),"defend")
	var replacements:=MilitaryCampaign.field_armies.filter(func(actual:Dictionary)->bool:return actual.has("border_sector") and int(actual.border_sector.index)==slot)
	assert_int(replacements.size()).is_equal(1)
	if replacements.is_empty():return
	assert_int(int(replacements[0].army_id)).is_not_equal(id)
	_march();Council.sit(int(GameState.elapsed_days))
	assert_int(MilitaryCampaign._field_army_index(id)).is_greater_equal(0)
	band=MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(id)]
	assert_vector(Defense.point(band.position)).is_equal(fixture.origin)
	assert_str(String(band.status)).is_equal("stationed")
	assert_bool(band.has("council")).is_false()
	assert_int(_total()).is_equal(22000)
func test_reserved_band_waits_for_new_station_and_reinforcements_do_not_merge_remotely()->void:
	_deploy(1000)
	var band:Dictionary=MilitaryCampaign.field_armies[0]
	var old:Dictionary=band.position.duplicate(true)
	MilitaryCampaign.own_engagements["reserved"]={"home_force_kind":"field_army","home_force_id":int(band.army_id)}
	GameState.border_forts.forts.append({"id":1,"kind":"earthwork_fort","x":fixture.origin.x+50,"z":fixture.origin.y,"status":"standing","condition":1.0})
	_home(19200);Council.order(String(fixture.civ_id),"defend")
	assert_dict(band.position).is_equal(old)
	assert_str(String(band.status)).is_equal("stationed")
	assert_array(Array(Defense.coverage(band))).is_empty()
	assert_int(int(band.troops)).is_equal(100)
	MilitaryCampaign.own_engagements.clear();Council.order(String(fixture.civ_id),"defend")
	assert_str(String(band.status)).is_equal("moving")
	assert_array(Array(Defense.coverage(band))).is_empty()
	assert_int(_total()).is_equal(20000)

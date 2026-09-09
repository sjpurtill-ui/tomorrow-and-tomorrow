extends GdUnitTestSuite
class Map extends "res://scripts/local_terrain.gd":
	func _ready()->void:pass
	func _process(_delta:float)->void:pass
	func _height_at(_x:float,_z:float)->float:return 0.0
	func _close_surface_height_at(_x:float,_z:float)->float:return 0.0
func before_test()->void:
	GameState.reset_for_new_world(424242)
	CivilizationSystem.reset_for_new_world();CivilizationSystem.initialize()
func reported_city()->Dictionary:
	var id:=String(CivilizationSystem.civilizations[0].strategic_regions[-1].id)
	var intel= CivilizationSystem.city_intelligence
	intel.publish("player",intel.capture("player",id,.85,10,"Scout report","physical_visit"),12)
	return intel.known("player",id)

func test_known_names_visible_and_clickable_at_every_distance()->void:
	var city:=reported_city()
	var map:Node3D=auto_free(Map.new());add_child(map)
	map.camera=Camera3D.new();map.add_child(map.camera)
	map.camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	map.camera_target=Vector3(float(city.position.x),0,float(city.position.z))
	for index in 4:
		map.set_camera_distance_level(index);map.camera.size=map.zoom_target_size;map._update_camera()
		map._refresh_contact_encounter_markers()
		assert_bool(map.contact_encounter_markers.has(city.city_id)).is_true()
		var marker:Node3D=map.contact_encounter_markers[city.city_id]
		var label:=marker.get_node("SettlementLabel") as Label3D
		assert_bool(label.visible).is_true()
		assert_bool(label.text.contains(String(city.name))).is_true()
		assert_bool(label.text.contains("est.")).is_true()
		assert_int(label.render_priority).is_equal(11)
		map._normalize_aerial_labels()
		map._refresh_contact_encounter_markers()
		assert_int(label.font_size).is_equal(40 if map.camera.size>1600.0 or map.camera.size<=2.4 else 48)
		var flag:=label.get_node("CivilizationFlag") as Sprite3D
		assert_bool(flag.fixed_size and flag.no_depth_test).is_true()
		assert_bool(flag.texture!=null and flag.offset.x<0).is_true()
		assert_bool(label.modulate==preload("res://scripts/city_map_identity.gd").foreign(String(city.controller)).color).is_true()
		var pixel_size:=flag.pixel_size
		map._normalize_aerial_labels();map._refresh_contact_encounter_markers()
		assert_float(flag.pixel_size).is_equal(pixel_size)
		map.city_labels.refresh()
		assert_array(map.city_labels.cards).has_size(1)
		assert_int(label.layers).is_equal(0)
		var hit:Dictionary=map._city_from_screen(map.city_labels.cards[0].rect.get_center())
		assert_str(String(hit.get("city_id",""))).is_equal(String(city.city_id))

func test_map_summary_reads_reported_estimates_and_leaves_full_report_optional()->void:
	var city:=reported_city()
	var provider:=preload("res://scripts/hud/content/dock_detail_foreign_city.gd").new(null,null,String(city.city_id))
	var before:Dictionary=provider.tab(0)
	assert_str(String(provider.meta().title)).is_equal(String(city.name))
	assert_int(before.blocks[0].items.size()).is_equal(7)
	CivilizationSystem.civilizations[0].strategic_regions[-1].population*=100
	assert_array(provider.tab(0).blocks[0].items).is_equal(before.blocks[0].items)
	assert_bool(is_instance_valid(CivilizationSystem.city_intelligence.screen_layer)).is_false()

func test_flags_share_civilization_identity_and_follow_reported_control()->void:
	var city:=reported_city()
	var map:Node3D=auto_free(Map.new());add_child(map)
	map.camera=Camera3D.new();map.add_child(map.camera)
	map.camera_target=Vector3(float(city.position.x),0,float(city.position.z))
	map.set_camera_distance_level(2);map.camera.size=map.zoom_target_size;map._update_camera()
	map._refresh_contact_encounter_markers()
	var marker:Node3D=map.contact_encounter_markers[city.city_id]
	var label:=marker.get_node("SettlementLabel") as Label3D
	var identity=preload("res://scripts/city_map_identity.gd")
	var original:Texture2D=label.get_node("CivilizationFlag").texture
	assert_bool(original==identity.foreign(String(city.civ_id)).texture).is_true()
	var other_id:=String(CivilizationSystem.civilizations[1].id)
	city.controller=other_id;city.observed_day+=1;city.reported_day+=1
	CivilizationSystem.city_intelligence.publish("player",city,int(city.reported_day))
	map._refresh_contact_encounter_markers()
	assert_bool(marker==map.contact_encounter_markers[city.city_id]).is_true()
	assert_bool(label.get_node("CivilizationFlag").texture==identity.foreign(other_id).texture).is_true()
	assert_bool(label.modulate==identity.foreign(other_id).color).is_true()
	assert_bool(original!=identity.foreign(other_id).texture).is_true()

extends GdUnitTestSuite
const Record := preload("res://scripts/hud/village_view_record.gd")

func _state(day: int = 0) -> Dictionary:
	return {"id":"home", "name":"Ashfire", "day":day, "population":155, "works":3, "field_ha":1.2}

func _image() -> PackedByteArray:
	var image := Image.create(24, 12, false, Image.FORMAT_RGB8)
	image.fill(Color.DARK_GREEN)
	return image.save_webp_to_buffer()

func test_first_view_is_observed_now_not_backdated_to_founding() -> void:
	var album := {}
	var state := _state(6000)
	assert_str(Record.reason(album, state)).is_equal("First recorded view")
	assert_bool(Record.append_view(album, state, _image(), Record.reason(album, state))).is_true()
	assert_int(Record.views(album, "home")[0].day).is_equal(6000)
	assert_bool(Record.append_view(album, _state(40), _image(), "Another year")).is_false()
	assert_bool(Record.append_view(album, state, _image(), "Another year")).is_false()

func test_album_is_bounded_and_preserves_first_and_latest_views() -> void:
	var album := {}
	for year in 40:
		var state := _state(year * 365)
		assert_bool(Record.append_view(album, state, _image(), Record.reason(album, state))).is_true()
	var entries := Record.views(album, "home")
	assert_int(entries.size()).is_equal(Record.MAX_VIEWS)
	assert_int(entries[0].day).is_equal(0)
	assert_int(entries[-1].day).is_equal(39 * 365)
	assert_array(Record.views(album, "another-town")).is_empty()

func test_only_recorded_changes_trigger_views_and_comparisons() -> void:
	var album := {}
	Record.append_view(album, _state(), _image(), "First recorded view")
	assert_str(Record.reason(album, _state(1))).is_empty()
	var later := _state(400); later.population=175; later.works=5; later.field_ha=1.7
	assert_str(Record.reason(album, later)).is_equal("New building work")
	assert_str(Record.changes(album, later)).contains("+20 people").contains("+2 completed works").contains("+0.50 ha")
	assert_str(Record.changes(album, _state(100))).not_contains("+0")
	var built:=_state(500);built["fabric"]=100
	Record.append_view(album,built,_image(),"The village changed")
	var damaged:=built.duplicate();damaged.day=501;damaged.fabric=101
	assert_str(Record.reason(album,damaged)).is_equal("The village changed")

func test_images_and_metadata_roundtrip_through_save_serialization() -> void:
	var album := {}
	Record.append_view(album, _state(800), _image(), "First recorded view")
	var decoded: Dictionary = bytes_to_var(var_to_bytes(album))
	var entry: Dictionary = Record.views(decoded, "home")[0]
	var image := Image.new()
	assert_int(image.load_webp_from_buffer(entry.image)).is_equal(OK)
	assert_int(image.get_width()).is_equal(24)
	assert_int(entry.day).is_equal(800)
	assert_bool(Record.append_view(album, _state(900), PackedByteArray(), "Another year")).is_false()

func test_observations_use_actual_plot_geometry_and_field_area() -> void:
	var plots := [{"land_use":"field", "area_ha":0.4, "polygon":PackedVector2Array([Vector2(0.1,0.0),Vector2(0.2,0.1)])},
		{"land_use":"residential_compound", "polygon":PackedVector2Array([Vector2(0.1,0.1)])},
		{"land_use":"field", "status":"ruin", "area_ha":2.0, "polygon":PackedVector2Array([Vector2(20,20)])}]
	var state := Record.observations({"id":"home", "population":155}, plots, ["Hearth Circle"], 34)
	assert_float(state.field_ha).is_equal_approx(0.4, 0.001)
	assert_float(state.span).is_between(0.18, 0.19)
	assert_int(state.works).is_equal(1)
	assert_int(state.population).is_equal(155)

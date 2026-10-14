extends GdUnitTestSuite
const Reading=preload("res://scripts/hud/production_needs_reading.gd")

func test_many_formation_needs_remain_searchable_and_live_without_a_long_default_list()->void:
	var entries:Array=[]
	for i in 19:entries.append({"who":"River force %d" % i,"count":20+i})
	var reading:Control=auto_free(Reading.new());add_child(reading);reading.update_entries(entries)
	assert_int(reading.reading.text.split("\n").size()).is_equal(4)
	assert_str(reading.browse.text).is_equal("All 19 formation needs")
	reading.browse.pressed.emit()
	assert_int(reading.reading.text.split("\n").size()).is_equal(7)
	reading.next.pressed.emit();reading.next.pressed.emit();reading.next.pressed.emit()
	assert_str(reading.reading.text).contains("River Force 18 · 38 needed")
	assert_bool(reading.next.disabled).is_true()
	reading.search.text="force 18";reading.search.text_changed.emit(reading.search.text)
	entries[18].count=42;reading.update_entries(entries)
	assert_str(reading.search.text).is_equal("force 18")
	assert_str(reading.reading.text).contains("River Force 18 · 42 needed")
	reading.browse.pressed.emit()
	assert_int(reading.reading.text.split("\n").size()).is_equal(4)
	assert_bool(reading.search.visible).is_false()

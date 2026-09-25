extends GdUnitTestSuite
## Early war on the map reads as a feud between neighbours: a short tag near
## the border, plain words on hover, no percentages, and never over a city.
const Marks:=preload("res://scripts/war_map_marks.gd")
const Overlay:=preload("res://scripts/hud/war_map_overlay.gd")
const Presentation:=preload("res://scripts/warfare_map_presentation.gd")


func test_tags_and_hover_words_follow_the_era()->void:
	assert_str(Marks.war_tag("Ankora","hearth",3*365)).is_equal("Feud with Ankora")
	assert_str(Marks.war_tag("Ankora","lettered",100)).is_equal("War with Ankora")
	assert_str(Marks.war_tag("Ankora","reckoned",2*365+10)).is_equal("War with Ankora · year 3")
	var info:={"enemy":"Ankora","days":3*365,"our_dead":6,"their_dead":3,"leader":"Hena","harm":{"target":"racks","days_ago":12},"field":40}
	assert_str(Marks.details(info,"hearth")).is_equal("Ankora's men raid our drying racks. Three winters now. 6 of ours dead, 3 of theirs. Hena leads our fighters.")
	assert_str(Marks.details(info,"lettered")).contains("Three years now.")
	assert_str(Marks.details(info,"hearth")).not_contains("in the field")
	assert_str(Marks.details(info,"reckoned")).contains("40 of ours in the field.")
	# The army-scale front label of the old map never reaches a stone-age player.
	var front:={"id":"front_ankora","opponent":"Ankora","war_name":"Seanston–Ankora War (Year 3)","target":"Wasani","target_region_id":"","progress":0.5,"field_personnel":0,"readiness":0.0,"supply":0.0}
	var army:={"army_id":1,"name":"First Band","troops":7,"readiness":0.4,"supply_level":0.3,"position":{"x":0.0,"z":0.0},"formations":[{"unit":"levy","count":7}]}
	var destinations:=[{"id":"player_home","position":{"x":0.0,"z":0.0}}]
	for camera_size in [20.0,320.0]:
		var early:=Presentation.build_snapshot(camera_size,[army],[],[front],destinations,{},0,"hearth")
		for view:Dictionary in early.player+early.fronts:
			for banned in ["%","READY","SUPPLY","FIELD"]:
				assert_str(String(view.label)).not_contains(banned)
	assert_str(String(Presentation.build_snapshot(20.0,[army],[],[front],destinations,{},0,"hearth").fronts[0].label)).is_equal("Feud with Ankora")
	# The statistical age keeps its figures, and the stage never leaks to later calls.
	assert_str(String(Presentation.build_snapshot(20.0,[army],[],[],destinations,{},0,"reckoned").player[0].label)).contains("%")
	assert_str(Presentation.words_stage).is_equal("reckoned")
	assert_float(Marks.raid_alpha(0)).is_equal(1.0)
	assert_float(Marks.raid_alpha(Marks.RAID_FADE_DAYS)).is_equal(0.0)


func test_war_tags_never_cover_city_tags()->void:
	var bounds:=Rect2(Vector2(90,100),Vector2(1100,600))
	var anchor:=Vector2(600,400)
	# A city tag and its pin sit right where the war mark is.
	var city:=Rect2(Vector2(540,370),Vector2(150,30))
	var reserved:Array[Rect2]=[city,Rect2(Vector2(592,392),Vector2(16,16))]
	var entries:Array[Dictionary]=[
		{"id":"war:ankora","anchor":anchor,"extent":Vector2(140,22),"foreign":false},
		{"id":"war:tolo","anchor":anchor+Vector2(30,10),"extent":Vector2(130,22),"foreign":false},
	]
	var result:=Overlay.arrange_tags(entries,bounds,{},reserved)
	assert_int(result.cards.size()).is_equal(2)
	for card:Dictionary in result.cards:
		var rect:Rect2=card.rect
		assert_bool(bounds.encloses(rect)).is_true()
		for obstacle:Rect2 in reserved: assert_bool(rect.intersects(obstacle)).is_false()
		# Stays close to its own mark.
		assert_float(rect.get_center().distance_to(Vector2(card.anchor))).is_less(160.0)
	assert_bool((result.cards[0].rect as Rect2).intersects(result.cards[1].rect)).is_false()
	# The contested border is a short line across the way between the peoples.
	var segment:=Marks.border_segment(Vector2.ZERO,Vector2(20,0))
	assert_float(segment[0].distance_to(segment[1])).is_less_equal(12.0)
	assert_float(absf(segment[0].x-10.0)).is_less(0.01)

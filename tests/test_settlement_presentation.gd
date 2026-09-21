extends GdUnitTestSuite
const Portrait:=preload("res://scripts/hud/person_portrait.gd")
const History:=preload("res://scripts/hud/settlement_history_data.gd")
func test_person_identity_survives_office_changes_and_serialization()->void:
	var person:={"person_id":14,"name":"Ashfield","title":"Steward"}
	var before:=Portrait.texture(person) as AtlasTexture
	var restored:Dictionary=JSON.parse_string(JSON.stringify(person));restored.title="Local leader";restored["id"]=200
	var after:=Portrait.texture(restored) as AtlasTexture
	assert_vector(before.region.position).is_equal(after.region.position)
	assert_int(Portrait.index_for({"person_id":15})).is_not_equal(Portrait.index_for(person))
	assert_int(Portrait.index_for({"person_id":14,"portrait_index":2})).is_equal(2)
func test_history_orders_newest_first_and_keeps_city_scope()->void:
	var discoveries:Array=[{"id":"cordage","name":"Cordage","day":900},{"id":"fire","name":"Fire","day":30}]
	var buildings:Array=[{"settlement_id":"home","day":700,"kind":"Framed Hall","event":"built"},{"settlement_id":"other","day":800,"kind":"Public Stores"}]
	var events:=History.events({"id":"home","name":"Home","founded_day":10},discoveries,buildings)
	assert_int(events.size()).is_equal(4)
	assert_int(events[0].day).is_equal(900)
	assert_str(events[0].scope).is_equal("Civilization")
	assert_int(events[1].day).is_equal(700)
	assert_str(events[1].scope).is_equal("Home")
	assert_int(events[3].day).is_equal(10)
	assert_bool(discoveries[0].has("scope")).is_false()
func test_history_does_not_truncate_to_three_events()->void:
	var discoveries:Array=[]
	for day in 40:discoveries.append({"name":"Recorded event", "day":day})
	assert_int(History.events({"id":"home"},discoveries,[]).size()).is_equal(40)

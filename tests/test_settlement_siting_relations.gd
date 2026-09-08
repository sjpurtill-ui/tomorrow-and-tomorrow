extends GdUnitTestSuite
const Siting:=preload("res://scripts/settlement_siting_relations.gd")

class Society extends Node:
	var civilizations:Array[Dictionary]=[]
	var city_intelligence=preload("res://scripts/city_intelligence.gd").new(self)
	var events:Array[String]=[]
	func _civilization_world_position(civ:Dictionary)->Vector2:return civ.world
	func _region_location(city_id:String)->Dictionary:
		for i:int in civilizations.size():
			for j:int in civilizations[i].strategic_regions.size():
				if civilizations[i].strategic_regions[j].id==city_id:return {"owner_index":i,"region_index":j}
		return {}
	func _record_world_event(_title:String,message:String,_category:String,_day:int)->void:events.append(message)

var society:Society
var siting:RefCounted

func before_test()->void:
	society=auto_free(Society.new())
	society.civilizations=[{"id":"rival","name":"Neighbors","world":Vector2.ZERO,"player_relation":{"opinion":0.0,"border_tension":0.0,"contact_level":2},"strategic_regions":[{"id":"capital","name":"River City","controller":"rival","role":"capital","map_x":.5,"map_y":.5}]}]
	siting=Siting.new(society)

func _report(city_id:String,owner:String,position:Vector2)->Dictionary:
	return society.city_intelligence.location_record({"city_id":city_id,"civ_id":owner,"name":city_id.capitalize(),"position":{"x":position.x,"z":position.y}},10,"returned report","test")

func test_closer_means_strictly_greater_resentment_with_no_penalty_beyond_range()->void:
	assert_float(Siting.penalty_at(2)).is_greater(Siting.penalty_at(10))
	assert_float(Siting.penalty_at(10)).is_greater(Siting.penalty_at(20))
	assert_float(Siting.penalty_at(20)).is_greater(Siting.penalty_at(29))
	assert_float(Siting.penalty_at(0)).is_equal(.7)
	assert_float(Siting.penalty_at(30)).is_equal(0.0)
	assert_float(Siting.penalty_at(100)).is_equal(0.0)

func test_preview_uses_returned_cities_without_revealing_hidden_neighbors()->void:
	var preview:Dictionary=siting.preview(Vector2(2,0))
	assert_float(preview.penalty).is_equal(0.0)
	assert_str(preview.text).contains("unlocated")
	society.city_intelligence.records={"player":{"capital":_report("capital","rival",Vector2.ZERO)}}
	preview=siting.preview(Vector2(2,0))
	assert_float(preview.penalty).is_equal(Siting.penalty_at(2))
	assert_str(preview.title).contains("SEVERE")
	assert_str(preview.text).contains("2.0 km")
	assert_float(society.civilizations[0].player_relation.opinion).is_equal(0.0)

func test_founding_within_city_sight_provokes_real_relations_once()->void:
	siting.founded("new_city","New City",Vector2(2,0),12)
	var relation:Dictionary=society.civilizations[0].player_relation
	assert_float(relation.opinion).is_equal_approx(-Siting.penalty_at(2),.00001)
	assert_float(relation.border_tension).is_equal_approx(Siting.penalty_at(2),.00001)
	assert_bool(society.city_intelligence.known("rival","new_city").is_empty()).is_false()
	assert_int(relation.rival_contact_level).is_equal(2)
	var opinion:float=relation.opinion
	siting.founded("new_city","New City",Vector2(2,0),13)
	for day:int in range(14,50):relation=siting.apply_observed(society.civilizations[0],relation,day)
	assert_float(relation.opinion).is_equal(opinion)
	assert_int(society.events.size()).is_equal(1)

func test_distant_foundation_waits_for_rivals_report_then_applies_the_same_curve()->void:
	siting.founded("new_city","New City",Vector2(20,0),12)
	var relation:Dictionary=society.civilizations[0].player_relation
	assert_float(relation.opinion).is_equal(0.0)
	society.city_intelligence.publish("rival",_report("new_city","player",Vector2(20,0)),30)
	relation=siting.apply_observed(society.civilizations[0],relation,30)
	assert_float(relation.opinion).is_equal_approx(-Siting.penalty_at(20),.00001)

func test_multiple_foreign_cities_do_not_charge_same_civilization_twice()->void:
	society.civilizations[0].strategic_regions.append({"id":"district","name":"Another City","controller":"rival","role":"town","map_x":.51,"map_y":.5})
	siting.founded("new_city","New City",Vector2(3,0),12)
	var relation:Dictionary=society.civilizations[0].player_relation
	assert_int(relation.settlement_encroachment.size()).is_equal(1)
	assert_float(relation.opinion).is_equal_approx(-Siting.penalty_at(.8),.00001)

func test_each_additional_player_city_can_create_an_additional_grievance()->void:
	siting.founded("one","One",Vector2(10,0),12)
	var first:float=society.civilizations[0].player_relation.opinion
	siting.founded("two","Two",Vector2(-10,0),20)
	var relation:Dictionary=society.civilizations[0].player_relation
	assert_float(relation.opinion).is_equal_approx(first*2,.00001)
	assert_int(relation.settlement_encroachment.size()).is_equal(2)

func test_occupied_city_does_not_resent_its_own_players_new_settlement()->void:
	society.civilizations[0].strategic_regions[0].controller="player"
	siting.founded("new_city","New City",Vector2(2,0),12)
	assert_float(society.civilizations[0].player_relation.opinion).is_equal(0.0)
	var known:=_report("capital","rival",Vector2.ZERO);known.controller="player"
	society.city_intelligence.records={"player":{"capital":known}}
	assert_float(siting.preview(Vector2(2,0)).penalty).is_equal(0.0)

func test_unidentified_settlement_report_cannot_be_used_to_blame_player()->void:
	society.city_intelligence.records={"rival":{"unidentified":_report("unidentified","",Vector2(2,0))}}
	var relation:Dictionary=siting.apply_observed(society.civilizations[0],society.civilizations[0].player_relation,12)
	assert_float(relation.opinion).is_equal(0.0)

func test_relation_normalization_and_serialization_preserve_grievance_deduplication()->void:
	siting.founded("new_city","New City",Vector2(2,0),12)
	var relation:Dictionary=society.civilizations[0].player_relation
	var restored:Dictionary=JSON.parse_string(JSON.stringify(relation))
	restored=CivilizationSystem._relation_with_strategy_defaults(restored)
	var opinion:float=restored.opinion
	restored=siting.apply_observed(society.civilizations[0],restored,100)
	assert_float(restored.opinion).is_equal(opinion)
	assert_int(restored.settlement_encroachment.size()).is_equal(1)

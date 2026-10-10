extends GdUnitTestSuite
## A general may use a dated chart to choose a road, without knowing hidden
## armies, changing the capital objective, or manufacturing an observation.
const Fixture:=preload("res://tests/test_war_council.gd")
const Council:=preload("res://scripts/war_council.gd")
const Defense:=preload("res://scripts/border_defense.gd")
var fixture:Node
var army:Dictionary
var capital:Vector2
var line:Array

func before_test()->void:
	fixture=Fixture.new();add_child(fixture);fixture.before_test()
	var origin:Vector2=CivilizationSystem.player_world_origin
	capital=origin+Vector2(20,0)
	fixture._place_town(capital);fixture._counted(20.0);fixture._train(300)
	CivilizationSystem._add_revealed_area(origin,80.0,"returned approach survey")
	CivilizationSystem.foreign_formations.clear();CivilizationSystem.foreign_sightings.clear()
	var made:Dictionary=MilitaryCampaign.create_field_army(200,"Capital host")
	var id:=int(made.army.army_id)
	var ordered:Dictionary=MilitaryCampaign.order_city_operation(id,String(fixture.civ_id),String(fixture.city_id),true)
	assert_bool(ordered.has("error")).override_failure_message(str(ordered)).is_false()
	army=MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(id)]
	line=Defense.packed(PackedVector2Array([origin+Vector2(10,-3),origin+Vector2(10,3)]))
	# These tests supply returned reports, rather than trigger a new live look.
	CivilizationSystem.last_observation_day=int(GameState.elapsed_days)

func after_test()->void:
	fixture.after_test();fixture.free()

func _report(age:int)->void:
	var middle:=Defense.point(line[0]).lerp(Defense.point(line[-1]),0.5)
	CivilizationSystem.foreign_sightings.assign([{"formation_id":"charted-front","civ_id":String(fixture.civ_id),"kind":"patrol","position":{"x":middle.x,"z":middle.y},"strength":100.0,"readiness":0.8,"visible":false,"last_seen_day":int(GameState.elapsed_days)-age,"defense_points":line.duplicate(true)}])

func test_recent_observed_line_changes_approach_but_keeps_same_capital()->void:
	_report(5)
	var before:Dictionary=army.city_operation.duplicate(true)
	var reports:Array=CivilizationSystem.foreign_sightings.duplicate(true)
	var direct:Array=army.march_route.duplicate(true)
	assert_bool(Council._observed_approach(int(army.army_id),String(fixture.civ_id))).is_true()
	assert_dict(army.city_operation).is_equal(before)
	assert_str(String(army.destination_id)).is_equal(String(fixture.city_id))
	assert_bool(Defense.point(army.march_route[-1]).is_equal_approx(capital)).is_true()
	assert_bool(army.march_route!=direct).is_true()
	assert_float(float(army.distance_remaining_km)).is_greater(20.0)
	assert_float(float(army.distance_remaining_km)).is_less_equal(37.0)
	assert_array(CivilizationSystem.foreign_sightings).is_equal(reports)
	var known:=[{"id":"charted-front","troops":100,"defense_points":line}]
	assert_dict(Council._reported_contact(CivilizationSystem.player_world_origin,army.march_route,known,army)).is_empty()

func test_stale_report_and_unseen_real_line_do_not_invent_a_flank()->void:
	_report(31)
	var direct:Array=army.march_route.duplicate(true)
	var objective:Dictionary=army.city_operation.duplicate(true)
	assert_bool(Council._observed_approach(int(army.army_id),String(fixture.civ_id))).is_false()
	assert_array(army.march_route).is_equal(direct)
	# Even a real line in the backend is no route-planning knowledge until seen.
	CivilizationSystem.foreign_sightings.clear()
	CivilizationSystem.foreign_formations.assign([{"id":"unseen-front","civ_id":String(fixture.civ_id),"kind":"patrol","actual_troops":100,"defense_points":line.duplicate(true),"command_position":line[0]}])
	assert_bool(Council._observed_approach(int(army.army_id),String(fixture.civ_id))).is_false()
	assert_array(army.march_route).is_equal(direct)
	assert_dict(army.city_operation).is_equal(objective)
	assert_bool(Defense.point(army.march_route[-1]).is_equal_approx(capital)).is_true()
	assert_array(CivilizationSystem.foreign_sightings).is_empty()

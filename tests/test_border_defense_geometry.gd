extends GdUnitTestSuite
const Defense:=preload("res://scripts/border_defense.gd")

func test_far_world_sweep_remains_contact_after_position_is_packed()->void:
	var origin:=Vector2(12345.678,-19876.543)
	var army:={"troops":1900}
	var enemy:={"id":"rival:army:8","troops":830,"position":origin+Vector2(6,0),"defense_points":[origin+Vector2(6,-5),origin+Vector2(6,5)]}
	var hit:=Defense.first_contact(origin,origin+Vector2(20,0),[enemy],army)
	assert_dict(hit).is_not_empty()
	if hit.is_empty():return
	var stored:={"x":float(hit.point.x),"z":float(hit.point.y)}
	var at:=Defense.point(JSON.parse_string(JSON.stringify(stored)))
	assert_dict(Defense.first_contact(at,at,[enemy],army)).is_not_empty()
	assert_dict(Defense.first_contact(origin,origin,[enemy],army)).is_empty()

func _coast(at:Vector2)->bool:
	return at.x>=-2.0 and at.x<=3.0

func test_coast_clips_connected_station_without_bridging_water()->void:
	var line:=PackedVector2Array([Vector2(-10,0),Vector2(10,0)])
	var dry:=Defense.land_span(line,Callable(self,"_coast"))
	assert_int(dry.size()).is_greater_equal(2)
	if dry.size()<2:return
	assert_bool(dry[0].x>=-2.01 and dry[0].x<-1.9).is_true()
	assert_bool(dry[-1].x<=3.01 and dry[-1].x>2.9).is_true()
	assert_float(Defense.length(dry)).is_between(4.98,5.01)
	assert_array(Defense.land_span(PackedVector2Array([Vector2(5,0),Vector2(10,0)]),Callable(self,"_coast"))).is_empty()

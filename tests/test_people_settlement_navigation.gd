extends GdUnitTestSuite
const View=preload("res://scripts/hud/people_settlement_view.gd")
const Fixture=preload("res://tests/city_evolution_visual_fixture.gd")

func _town()->Control:
	var plot:=Fixture.plot(1);plot.land_use="field"
	var town:Control=auto_free(View.new());add_child(town);town.size=Vector2(1000,620)
	town.configure({"plots":[plot],"routes":[],"population":24,"origin":Vector3.ZERO})
	town.focus_role("Food");town._process(2.0)
	return town

func _button(town:Control,at:Vector2,pressed:bool)->void:
	var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT
	event.position=at;event.pressed=pressed;town._input_view(event)

func test_visible_parcel_is_clickable_away_from_its_label_and_drag_never_selects()->void:
	var town:=_town();var hits:Array[String]=[]
	town.role_selected.connect(func(role:String):hits.append(role))
	var polygon:PackedVector2Array=town.role_anchor_metadata().Food.polygons[0]
	var middle:=Vector2.ZERO
	for vertex in polygon:middle+=vertex/polygon.size()
	var click:=middle.lerp(polygon[0],.65)
	assert_bool(Geometry2D.is_point_in_polygon(click,polygon)).is_true()
	assert_float(click.distance_to(town.role_screen_positions().Food)).is_greater(42.0)
	_button(town,click,true);_button(town,click,false)
	assert_array(hits).is_equal(["Food"])
	hits.clear();_button(town,click,true)
	var movement:=InputEventMouseMotion.new();movement.position=click+Vector2(60,20)
	movement.relative=Vector2(60,20);movement.button_mask=MOUSE_BUTTON_MASK_LEFT
	town._input_view(movement);_button(town,movement.position,false)
	assert_array(hits).is_empty()

func test_pan_zoom_and_resize_keep_art_angle_and_selected_area_recoverable()->void:
	var town:=_town();var center:Vector3=town._desired_target;var span:float=town._desired_span
	var angle:=Vector2(town._yaw,town._pitch)
	town.pan_view(Vector2(100,40));town.zoom_view(.8)
	assert_bool((town._desired_target as Vector3).distance_to(center)>.0001).is_true()
	assert_float(town._desired_span).is_less(span)
	assert_that(Vector2(town._yaw,town._pitch)).is_equal(angle)
	# The closest permitted zoom must move the camera, not just the saved span.
	town._span=.018;town._position_camera()
	var farther:float=town.camera.position.distance_to(town._target)
	town._span=.012;town._position_camera()
	assert_float(town.camera.position.distance_to(town._target)).is_less(farther*.8)
	assert_str(town.focused_role).is_equal("Food")
	var manual_span:float=town._desired_span
	town.size=Vector2(760,560);town._resize_view()
	assert_float(town._desired_span).is_equal(manual_span)
	town.reset_navigation()
	assert_that(town._desired_target).is_equal(center)
	assert_str(town.focused_role).is_equal("Food")
	assert_that(Vector2(town._yaw,town._pitch)).is_equal(angle)

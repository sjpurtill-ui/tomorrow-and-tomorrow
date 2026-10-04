extends GdUnitTestSuite
const View:=preload("res://scripts/settlement_ground_view.gd")

func _camera(size:Vector2i,pitch:float,yaw:float,span:float=2.4)->Camera3D:
	var viewport:=auto_free(SubViewport.new()) as SubViewport
	viewport.size=size;viewport.own_world_3d=true
	add_child(viewport)
	var camera:=Camera3D.new()
	viewport.add_child(camera)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=span
	camera.rotation=Vector3(pitch,yaw,0)
	camera.position=camera.basis.z*maxf(40.0,span*8.0)
	return camera

func _assert_coverage(rect:Rect2)->void:
	var layout:Dictionary=View.tile_layout(rect)
	var side:float=layout.side
	var start:Vector2=Vector2(layout.cell)*side
	var cover:=Rect2(start,Vector2.ONE*side*2.0)
	# Vector2 stores single precision; this tolerance is less than one millimetre.
	assert_bool(cover.grow(.000001).encloses(rect.abs())).is_true()
	assert_float(side).is_greater_equal(maxf(rect.abs().size.x,rect.abs().size.y))
	assert_float(float(layout.pad)/side).is_equal(1.0/16.0)
	var tiles:Array[Rect2]=[]
	for y in 2:
		for x in 2:tiles.append(Rect2(start+Vector2(x,y)*side,Vector2.ONE*side))
	assert_int(tiles.size()).is_equal(4)
	for point:Vector2 in [rect.abs().position,rect.abs().end,rect.abs().get_center()]:
		var found:=false
		for tile in tiles:
			if tile.grow(.000001).has_point(point):found=true
		assert_bool(found).is_true()

func test_tile_layout_covers_scale_thresholds_and_negative_grid_phases()->void:
	for span:float in [.14,.511999,.512,.512001,1.024,1.024001,2.4,8.0]:
		var side:float=View.tile_layout(Rect2(Vector2.ZERO,Vector2.ONE*span)).side
		for x:float in [-2.99,-1.51,-1.0,-.01,0,.01,.49,.99]:
			for y:float in [-1.99,-.49,0,.99]:_assert_coverage(Rect2(Vector2(x,y)*side,Vector2(span,span*.61)))
	assert_int(int(View.tile_layout(Rect2(0,0,.512,.1)).level)).is_equal(0)
	assert_int(int(View.tile_layout(Rect2(0,0,.512001,.1)).level)).is_equal(1)
	assert_int(int(View.tile_layout(Rect2(0,0,1.024,.1)).level)).is_equal(1)
	assert_int(int(View.tile_layout(Rect2(0,0,1.024001,.1)).level)).is_equal(2)

func test_camera_rect_covers_real_corner_rays_across_aspect_yaw_and_pitch()->void:
	for size:Vector2i in [Vector2i(320,1600),Vector2i(1600,320),Vector2i(1920,1080),Vector2i(1080,1920)]:
		for pitch:float in [-PI*.5,-.98,-.4]:
			for yaw:float in [0.0,PI*.25,PI*.5]:
				var camera:=_camera(size,pitch,yaw)
				var rect:=View.camera_rect(camera,Vector3.ZERO)
				for corner:Vector2 in [Vector2.ZERO,Vector2(size.x,0),Vector2(size),Vector2(0,size.y)]:
					var origin:=camera.project_ray_origin(corner)
					var direction:=camera.project_ray_normal(corner)
					var hit:=origin+direction*(-origin.y/direction.y)
					assert_bool(rect.has_point(Vector2(hit.x,hit.z))).is_true()
				_assert_coverage(rect)

func test_camera_rect_translates_with_target_height_and_world_position()->void:
	var camera:=_camera(Vector2i(1920,1080),-.6,PI*.3)
	var first:=View.camera_rect(camera,Vector3.ZERO)
	var target:=Vector3(812.25,3.0,-41.5)
	camera.position+=target
	var moved:=View.camera_rect(camera,target)
	assert_float(moved.size.distance_to(first.size)).is_less(.001)
	assert_float(moved.position.distance_to(first.position+Vector2(target.x,target.z))).is_less(.001)
	_assert_coverage(Rect2(moved.position-Vector2(target.x,target.z),moved.size))

func test_invalid_or_horizon_cameras_use_finite_bounded_fallback()->void:
	var target:=Vector3(12,0,-8)
	for pitch:float in [0.0,.4]:
		var camera:=_camera(Vector2i(1600,320),pitch,0)
		var rect:=View.camera_rect(camera,target)
		assert_bool(rect.position.is_finite() and rect.size.is_finite()).is_true()
		assert_float(maxf(rect.size.x,rect.size.y)).is_less_equal(View.MAX_VIEW_SPAN_KM)
		assert_bool(rect.has_point(Vector2(target.x,target.z))).is_true()
		_assert_coverage(rect)
	var missing:=View.camera_rect(null,target)
	assert_float(missing.size.x).is_greater(0)
	assert_bool(missing.has_point(Vector2(target.x,target.z))).is_true()

func test_layout_is_stable_within_a_cell_and_changes_level_at_wider_view()->void:
	var first:Dictionary=View.tile_layout(Rect2(.1,.2,.3,.25))
	var moved:Dictionary=View.tile_layout(Rect2(.12,.22,.3,.25))
	assert_dict(moved).is_equal(first)
	var wider:Dictionary=View.tile_layout(Rect2(.1,.2,2.4,1.8))
	assert_int(int(wider.level)).is_greater(int(first.level))
	assert_float(float(first.side)).is_equal(float(Vector2(.512,0).x))
	_assert_coverage(Rect2(.1,.2,2.4,1.8))

func test_reversed_and_empty_rectangles_keep_finite_base_coverage()->void:
	_assert_coverage(Rect2(Vector2(.4,.1),Vector2(-.2,-.3)))
	var empty:Dictionary=View.tile_layout(Rect2())
	assert_int(int(empty.level)).is_equal(0)
	assert_float(float(empty.side)).is_equal(float(Vector2(.512,0).x))

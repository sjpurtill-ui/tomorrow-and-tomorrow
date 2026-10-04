extends GdUnitTestSuite
const Ground:=preload("res://scripts/settlement_grounds.gd")

func before_test()->void:
	GameState.reset_for_new_world(625114)
	GameState.settlement_founded_at=Vector3(812.25,0,-41.5)
	Ground.clear()

func _plot(id:int,at:Vector2,use:="residential_compound")->Dictionary:
	return {"id":id,"seed":id,"centroid":at,"polygon":PackedVector2Array([at+Vector2(-.02,-.02),at+Vector2(.02,-.02),at+Vector2(.02,.02),at+Vector2(-.02,.02)]),"land_use":use,"status":"active","form":"durable_household_cluster","area_ha":.16,"cultivation_phase":"growing","crop_cover":.6}

func _data()->Dictionary:
	var plots:Array[Dictionary]=[_plot(1,Vector2.ZERO),_plot(129,Vector2(2.05,.04)),_plot(130,Vector2(2.10,.08),"field")]
	var routes:Array[Dictionary]=[{"id":1,"active":true,"width_m":4.0,"surface_tier":3,"traffic":1.0,"points":PackedVector2Array([Vector2(1.95,.04),Vector2(2.22,.04)])}]
	var buildings:Array=[{"position":Vector2.ZERO,"angle":0.0,"radius":.004,"plot":plots[0]},{"position":Vector2(2.05,.04),"angle":0.0,"radius":.004,"plot":plots[1]}]
	return {"plots":plots,"routes":routes,"plan":{"buildings":buildings}}

func _build(data:Dictionary)->void:
	Ground.build(data.plan,data.plots,data.routes,GameState.settlement_founded_at)

func _serve(at:Vector2)->void:
	var home:=GameState.settlement_founded_at
	for pass_index in 5:Ground.serve(Vector2(home.x,home.z)+at,.6)

func _tile_at(local:Vector2)->int:
	var home:=GameState.settlement_founded_at
	var world:=Vector2(home.x,home.z)+local
	for slot in range(Ground.CITY_SLOTS,Ground.SLOTS):
		if Ground.slot_frames[slot].y>0.0 and Ground.slot_rect(slot).grow(-Ground.TILE_PAD_KM).has_point(world):return slot
	return -1

func _pixel(slot:int,local:Vector2,fields:=false)->Color:
	var home:=GameState.settlement_founded_at
	var world:=Vector2(home.x,home.z)+local
	var uv:Vector2=(world-Ground.slot_rect(slot).position)/Ground.slot_rect(slot).size
	var cached:Dictionary=Ground._tile_cache[Ground.slot_signatures[slot]]
	var img:Image=cached.fields if fields else cached.ground
	return img.get_pixelv(Vector2i(uv*Ground.RES))

func test_frontier_ground_extends_without_repainting_or_moving_the_old_centre()->void:
	var data:=_data()
	var initial_plots:Array[Dictionary]=[data.plots[0]]
	var no_routes:Array[Dictionary]=[]
	Ground.build({"buildings":[data.plan.buildings[0]]},initial_plots,no_routes,GameState.settlement_founded_at)
	var old_origin:=Ground.slot_origins[0]
	var old_signature:=Ground.slot_signatures[0]
	var old_usec:int=Ground.report.build_usec
	var before:Dictionary=data.duplicate(true)
	_build(data);_serve(Vector2(2.05,.04))
	assert_vector(Ground.slot_origins[0]).is_equal(old_origin)
	assert_int(Ground.slot_signatures[0]).is_equal(old_signature)
	assert_int(int(Ground.report.build_usec)).is_equal(old_usec)
	var slot:=_tile_at(Vector2(2.05,.04))
	assert_int(slot).is_greater_equal(Ground.CITY_SLOTS)
	if slot<0:return
	assert_float(_pixel(slot,Vector2(2.05,.04)).r).is_greater(.6)
	assert_dict(data).is_equal(before)
	var builds:=Ground.tile_builds
	_build(data);_serve(Vector2(2.05,.04))
	assert_int(Ground.tile_builds).is_equal(builds)

func test_recorded_route_geometry_and_field_season_invalidate_only_relevant_ground()->void:
	var data:=_data();_build(data);_serve(Vector2(2.05,.04))
	var core:=Ground.slot_signatures[0]
	var slot:=_tile_at(Vector2(2.10,.08))
	assert_int(slot).is_greater_equal(Ground.CITY_SLOTS)
	if slot<0:return
	var old:=Ground.slot_signatures[slot]
	data.plots[2].cultivation_phase="harvested"
	data.routes[0].points=PackedVector2Array([Vector2(1.95,.05),Vector2(2.22,.05)])
	_build(data);_serve(Vector2(2.05,.04))
	assert_int(Ground.slot_signatures[0]).is_equal(core)
	assert_int(Ground.slot_signatures[slot]).is_not_equal(old)
	assert_int(roundi(_pixel(slot,Vector2(2.10,.08),true).b*255.0)&7).is_equal(Ground.PHASES.find("harvested"))

func test_padded_tiles_agree_across_a_recorded_road_and_reuse_cached_images()->void:
	var data:=_data();_build(data);_serve(Vector2(2.048,.04))
	var left:=_tile_at(Vector2(2.045,.04));var right:=_tile_at(Vector2(2.051,.04))
	assert_int(left).is_greater_equal(Ground.CITY_SLOTS)
	assert_int(right).is_greater_equal(Ground.CITY_SLOTS)
	if left<0 or right<0:return
	assert_int(left).is_not_equal(right)
	assert_float(absf(_pixel(left,Vector2(2.045,.04)).r-_pixel(right,Vector2(2.051,.04)).r)).is_less(.15)
	var builds:=Ground.tile_builds
	_serve(Vector2(12,12));_serve(Vector2(2.048,.04))
	assert_int(Ground.tile_builds).is_equal(builds)
	assert_int(Ground.tile_cache_hits).is_greater(0)
	assert_int(Ground._tile_cache.size()).is_less_equal(Ground.MAX_TILE_CACHE)

func test_removed_frontier_and_new_world_leave_no_ghost_ground_or_requests()->void:
	var data:=_data();_build(data);_serve(Vector2(2.05,.04))
	data.plots.resize(1);data.plan.buildings.resize(1);data.routes.clear()
	_build(data);_serve(Vector2(2.05,.04))
	assert_int(_tile_at(Vector2(2.05,.04))).is_equal(-1)
	Ground.clear()
	assert_array(Ground._home_args).is_empty()
	assert_dict(Ground._tile_cache).is_empty()
	assert_int(Ground.slot_keys.count("")).is_equal(Ground.SLOTS)

func test_regional_road_paints_only_its_on_tile_span_and_cache_stays_bounded()->void:
	var data:=_data()
	data.routes[0].points=PackedVector2Array([Vector2(-300,.04),Vector2(300,.04)])
	_build(data)
	for index in 8:_serve(Vector2(2.05+index*1.024,.04))
	assert_int(Ground._tile_cache.size()).is_less_equal(Ground.MAX_TILE_CACHE)
	assert_int(Ground.tile_builds).is_greater(Ground.MAX_TILE_CACHE)
	for slot in range(Ground.CITY_SLOTS,Ground.SLOTS):
		if Ground.slot_frames[slot].y<=0:continue
		assert_int(int(Ground.slot_reports[slot].stamps)).is_less(6000)
		assert_float(float(Ground.slot_reports[slot].texel_m)).is_less(1.2)

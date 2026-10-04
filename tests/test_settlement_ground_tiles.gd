extends GdUnitTestSuite
const Ground:=preload("res://scripts/settlement_grounds.gd")

func before_test()->void:
	GameState.reset_for_new_world(625114)
	GameState.settlement_founded_at=Vector3(812.25,0,-41.5)
	Ground.clear()
	Ground.set_approaches({})

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
	var world:=Vector2(home.x,home.z)+at
	for pass_index in 5:Ground.serve(world,.6,Rect2(world-Vector2.ONE*.128,Vector2.ONE*.256))

func _tile_at(local:Vector2)->int:
	var home:=GameState.settlement_founded_at
	var world:=Vector2(home.x,home.z)+local
	for slot in range(Ground.CITY_SLOTS,Ground.SLOTS):
		if Ground.slot_frames[slot].y>0.0 and Ground.slot_rect(slot).grow(-Ground.slot_frames[slot].z).has_point(world):return slot
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

func test_approach_only_changes_refresh_pending_and_resident_requests()->void:
	var data:=_data();_build(data);_serve(Vector2(2.05,.04))
	var revision:=Ground._home_revision
	var at:=Vector2(GameState.settlement_founded_at.x,GameState.settlement_founded_at.z)
	Ground.set_approaches({"home":{"center":at,"bearings":[0.25]}})
	assert_int(Ground._home_revision).is_not_equal(revision)
	_serve(Vector2(2.05,.04))
	for key:String in Ground._tile_inputs:
		var slot:=Ground.slot_keys.find(key)
		assert_int(slot).is_greater_equal(Ground.CITY_SLOTS)
		if slot>=Ground.CITY_SLOTS:assert_int(Ground.slot_signatures[slot]).is_equal(int(Ground._tile_inputs[key].signature))
	var count:=Ground.tile_builds
	_serve(Vector2(2.05,.04))
	assert_int(Ground.tile_builds).is_equal(count)

func test_field_tracks_are_derived_before_cropping_hearth_and_route_context()->void:
	var field:=_plot(1,Vector2(.51,.10),"field")
	field.polygon=PackedVector2Array([Vector2(.49,.09),Vector2(.53,.09),Vector2(.53,.11),Vector2(.49,.11)])
	var hearth:=_plot(2,Vector2(.65,.10));hearth.form="open_hearth_yard"
	var plots:Array[Dictionary]=[field,hearth]
	var routes:Array[Dictionary]=[{"id":1,"points":PackedVector2Array([Vector2(.4,.2),Vector2(.45,.2)])}]
	Ground.build({},plots,routes,GameState.settlement_founded_at)
	var left:=Ground._in_rect({},plots,routes,Rect2(0,0,.512,.512).grow(.032))
	var right:=Ground._in_rect({},plots,routes,Rect2(.512,0,.512,.512).grow(.032))
	assert_array(left.plan._ground_paths).has_size(1)
	assert_array(right.plan._ground_paths).is_equal(left.plan._ground_paths)
	var track:PackedVector2Array=left.plan._ground_paths[0].points
	assert_vector(track[0]).is_equal(Vector2(.65,.10))
	assert_vector(track[-1]).is_equal(Vector2(.53,.10))
	# A field outside the left job still contributes the part of its path
	# that crosses it; filtering whole plots must not amputate the track.
	field.centroid=Vector2(.78,.20)
	field.polygon=PackedVector2Array([Vector2(.76,.18),Vector2(.8,.18),Vector2(.8,.22),Vector2(.76,.22)])
	plots=[field]
	Ground.build({},plots,routes,GameState.settlement_founded_at)
	left=Ground._in_rect({},plots,routes,Rect2(0,0,.512,.512).grow(.032))
	assert_array(left.plots).is_empty()
	assert_array(left.plan._ground_paths).has_size(1)


func test_wide_view_uses_four_coarser_tiles_without_changing_the_founding_core()->void:
	var data:=_data()
	var field:=_plot(500,Vector2(4,0),"field")
	field.polygon=PackedVector2Array([Vector2(1.8,-1.2),Vector2(6.2,-1.2),Vector2(6.2,1.2),Vector2(1.8,1.2)])
	data.plots.append(field)
	_build(data);_serve(Vector2(2.05,.04))
	var original_core:=Ground.slot_signatures[0]
	var original_origin:=Ground.slot_origins[0]
	var old_keys:=Ground.slot_keys.duplicate()
	var world:=Vector2(GameState.settlement_founded_at.x,GameState.settlement_founded_at.z)
	var view:=Rect2(world+Vector2(2,-1),Vector2(4,2))
	# The previous complete view remains installed while replacement raster
	# work is spread across service calls, rather than going bare for frames.
	Ground.serve(view.get_center(),3.0,view)
	assert_array(Array(Ground.slot_keys)).is_equal(Array(old_keys))
	for pass_index in 5:Ground.serve(view.get_center(),3.0,view)
	for corner:Vector2 in [Vector2(2,-1),Vector2(6,-1),Vector2(6,1),Vector2(2,1)]:
		var slot:=_tile_at(corner)
		assert_int(slot).is_greater_equal(Ground.CITY_SLOTS)
		if slot>=Ground.CITY_SLOTS:assert_float(_pixel(slot,corner,true).r).is_greater(.9)
	assert_int(Ground.slot_signatures[0]).is_equal(original_core)
	assert_vector(Ground.slot_origins[0]).is_equal(original_origin)
	assert_int(Ground._tile_cache.size()).is_less_equal(Ground.MAX_TILE_CACHE)
	var builds:=Ground.tile_builds
	for pass_index in 5:Ground.serve(view.get_center(),3.0,view)
	assert_int(Ground.tile_builds).is_equal(builds)

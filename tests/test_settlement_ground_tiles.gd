extends GdUnitTestSuite
const Ground:=preload("res://scripts/settlement_grounds.gd")

## Retain the former stamp-by-stamp path as a pixel oracle for the line fast
## path. This catches shifted samples, changed overlap, and tile-edge clipping.
func _reference_line(painter:Dictionary,points:PackedVector2Array,radius:float,alpha:float,channel:Color)->void:
	if points.size()<2:return
	var texel:float=painter.texel
	var spacing:=maxf(radius*0.45,texel*0.7)
	var overlap:=maxf(1.0,radius*2.0/spacing*0.55)
	var per:=1.0-pow(1.0-clampf(alpha,0.0,0.98),1.0/overlap)
	for i in range(1,points.size()):
		var a:=points[i-1];var b:=points[i]
		var steps:=maxi(1,ceili(a.distance_to(b)/spacing))
		var window:=Ground._line_window(a,b,Rect2(Vector2(painter.corner),Vector2.ONE*texel*Ground.RES).grow(radius+texel*2.0))
		if window.x>window.y:continue
		for s in range(maxi(0,floori(window.x*steps)),mini(steps,ceili(window.y*steps)+1)):
			Ground._stamp(painter,a.lerp(b,float(s)/float(steps)),radius,per,channel)
	Ground._stamp(painter,points[-1],radius,per,channel)

func _assert_line_matches_reference(points:PackedVector2Array,radius:float,alpha:float,channel:Color,corner:Vector2,side:float)->void:
	var expected:=Image.create_empty(Ground.RES,Ground.RES,false,Image.FORMAT_RGBA8)
	expected.fill(Color(.1,.2,.3,1))
	var actual:Image=expected.duplicate()
	var reference:={"image":expected,"corner":corner,"texel":side/Ground.RES,"stamps":0}
	var optimized:={"image":actual,"corner":corner,"texel":side/Ground.RES,"stamps":0}
	_reference_line(reference,points,radius,alpha,channel)
	Ground._line(optimized,points,radius,alpha,channel)
	assert_bool(actual.get_data()==expected.get_data()).is_true()
	assert_int(int(optimized.stamps)).is_equal(int(reference.stamps))

func test_line_fast_path_preserves_each_pixel_and_stamp_at_clipped_edges()->void:
	var cases:Array[Dictionary]=[
		{"points":PackedVector2Array([Vector2(-3,.1),Vector2(3,.1)]),"radius":.0007,"alpha":.7,"channel":Color(1,0,0)},
		{"points":PackedVector2Array([Vector2(-.02,-.03),Vector2(.15,.19),Vector2(.32,.03),Vector2(.63,.4)]),"radius":.0088,"alpha":.1,"channel":Color(0,1,0)},
		{"points":PackedVector2Array([Vector2(.1,.1),Vector2(.1,.1),Vector2(.12,.08)]),"radius":.00001,"alpha":1.0,"channel":Color(0,0,1)},
		{"points":PackedVector2Array([Vector2(-.3,.28),Vector2(.8,.28)]),"radius":.14,"alpha":.34,"channel":Color(0,1,0)},
		{"points":PackedVector2Array([Vector2(-8,-8),Vector2(-7,-7)]),"radius":.003,"alpha":.9,"channel":Color(1,0,0)}]
	for entry in cases:_assert_line_matches_reference(entry.points,entry.radius,entry.alpha,entry.channel,Vector2.ZERO,.56)

func test_line_fast_path_preserves_padded_tile_samples_at_negative_grid_phase()->void:
	var points:=PackedVector2Array([Vector2(-.7,-.02),Vector2(-.49,.03),Vector2(.09,-.015),Vector2(.63,.08)])
	for corner:Vector2 in [Vector2(-.544,-.032),Vector2(-.032,-.032),Vector2(-.544,-.608)]:
		_assert_line_matches_reference(points,.0012,.78,Color(1,0,0),corner,.576)

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

func test_recorded_home_ground_does_not_overlay_synthetic_fields_or_clearings()->void:
	var data:=_data();_build(data);_serve(Vector2(2.05,.04))
	assert_vector(Ground.slot_halos[0]).is_equal(Vector4.ZERO)
	for slot in range(Ground.CITY_SLOTS,Ground.SLOTS):assert_vector(Ground.slot_halos[slot]).is_equal(Vector4.ZERO)
	_serve(Vector2(12,12));_serve(Vector2(2.05,.04))
	data.plots[0].status="ruin";_build(data)
	assert_vector(Ground.slot_halos[0]).is_equal(Vector4.ZERO)
	var other:=GameState.settlement_founded_at+Vector3(20,0,0)
	Ground.build_other("seen-town",data.plan,data.plots,data.routes,other)
	var foreign_slot:=Ground.slot_keys.find("seen-town")
	assert_int(foreign_slot).is_between(1,Ground.CITY_SLOTS-1)
	assert_float(Ground.slot_halos[foreign_slot].y).is_greater(0.0)

func test_pending_window_finishes_from_its_snapshot_when_live_records_and_labor_change()->void:
	GameState.population_allocations={"Food":20}
	var data:=_data();_build(data)
	var home:=Vector2(GameState.settlement_founded_at.x,GameState.settlement_founded_at.z)
	var at:=home+Vector2(2.05,.04)
	var view:=Rect2(at-Vector2.ONE*.128,Vector2.ONE*.256)
	Ground.serve(at,.6,view)
	var pending_keys:Dictionary={}
	for key:String in Ground._tile_inputs:pending_keys[key]=int(Ground._tile_inputs[key].signature)
	GameState.population_allocations={"Logistics":20}
	data.plots[2].cultivation_phase="harvested"
	data.routes[0].points[0]=Vector2(1.95,.06)
	for pass_index in 5:Ground.serve(at,.6,view)
	for key:String in pending_keys:
		var slot:=Ground.slot_keys.find(key)
		assert_int(slot).is_greater_equal(Ground.CITY_SLOTS)
		if slot>=Ground.CITY_SLOTS:assert_int(Ground.slot_signatures[slot]).is_equal(int(pending_keys[key]))
	assert_int(Ground.tile_builds).is_less_equal(4)
	# Publishing a new source revision then brings the changed crop forward.
	_build(data);_serve(Vector2(2.05,.04))
	var slot:=_tile_at(Vector2(2.10,.08))
	assert_int(roundi(_pixel(slot,Vector2(2.10,.08),true).b*255.0)&7).is_equal(Ground.PHASES.find("harvested"))

func test_fallback_household_clearing_participates_in_cache_identity()->void:
	var plots:Array[Dictionary]=[_plot(1,Vector2.ZERO)]
	var routes:Array[Dictionary]=[]
	Ground.build({},plots,routes,GameState.settlement_founded_at)
	var old_key:=Ground.signature
	var old_revision:=Ground._home_revision
	assert_float(Ground.texture.get_image().get_pixel(256,256).g).is_greater(.1)
	Ground.build({"buildings":[]},plots,routes,GameState.settlement_founded_at)
	assert_int(Ground.signature).is_not_equal(old_key)
	assert_int(Ground._home_revision).is_not_equal(old_revision)
	assert_int(int(Ground.report.stamps)).is_equal(0)
	_serve(Vector2.ZERO)
	# Inspect the CPU paint result: Dummy rendering retains an ImageTexture's
	# initial image in get_image() even after update(), unlike the real GPU.
	var slot:=_tile_at(Vector2.ZERO)
	assert_int(slot).is_greater_equal(Ground.CITY_SLOTS)
	if slot>=Ground.CITY_SLOTS:assert_float(_pixel(slot,Vector2.ZERO).g).is_equal(0.0)

func test_unpainted_129th_household_growth_and_repair_reuse_the_core_image()->void:
	var plots:Array[Dictionary]=[]
	var routes:Array[Dictionary]=[]
	var buildings:Array=[]
	for index in 128:
		var plot:=_plot(index+1,Vector2(.04+(index%12)*.039,.04+(index/12)*.039))
		plots.append(plot)
		buildings.append({"position":plot.centroid,"angle":0.0,"radius":.004,"plot":plot})
	var plan:={"buildings":buildings}
	Ground.build(plan,plots,routes,GameState.settlement_founded_at)
	var signature:=Ground.signature
	var usec:int=Ground.report.build_usec
	var revision:=Ground._home_revision
	# The detailed plan has reached its budget. This adjoining record still
	# belongs to the model and source revision, but adds no ground stamps or
	# frame extent until its own renderer contributes a building/clearing.
	var adjoining:=_plot(129,Vector2(.04+8*.039,.04+10*.039))
	plots.append(adjoining)
	for status:String in ["active","damaged","active"]:
		adjoining.status=status
		adjoining.damage={"fire":.4} if status=="damaged" else {}
		Ground.build(plan,plots,routes,GameState.settlement_founded_at)
		assert_int(Ground._home_revision).is_not_equal(revision)
		revision=Ground._home_revision
		assert_int(Ground.signature).is_equal(signature)
		assert_int(int(Ground.report.build_usec)).is_equal(usec)

func test_painted_fields_frontages_buildings_fire_service_and_frame_still_invalidate()->void:
	for change:String in ["field","frontage","building","fire","service","frame","route","midden"]:
		Ground.clear()
		var house:=_plot(1,Vector2(.04,.04));house.frontage_route_id=1
		var field:=_plot(2,Vector2(.14,.08),"field")
		var other:=_plot(3,Vector2(.3,.1))
		var plots:Array[Dictionary]=[house,field,other]
		var routes:Array[Dictionary]=[
			{"id":1,"active":true,"points":PackedVector2Array([Vector2(0,.08),Vector2(.32,.08)])},
			{"id":2,"active":true,"points":PackedVector2Array([Vector2.ZERO,Vector2(.32,0)])}]
		var record:={"position":house.centroid,"angle":0.0,"radius":.004,"plot":house}
		var plan:={"buildings":[record]}
		Ground.build(plan,plots,routes,GameState.settlement_founded_at)
		var before:=Ground.signature
		match change:
			"field":field.cultivation_phase="harvested"
			"frontage":house.frontage_route_id=2
			"building":record.radius=.007
			"fire":house.damage={"fire":.8}
			"service":other.form="open_work_yard"
			"frame":other.centroid=Vector2(.42,.2)
			"route":routes[0].points[1]=Vector2(.3,.11)
			"midden":other.form="refuse_and_latrine_ground";other.status="ruin"
		Ground.build(plan,plots,routes,GameState.settlement_founded_at)
		assert_int(Ground.signature).is_not_equal(before)

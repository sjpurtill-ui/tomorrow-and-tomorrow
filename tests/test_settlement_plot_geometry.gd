extends GdUnitTestSuite
const Geometry:=preload("res://scripts/settlement_plot_geometry.gd")
const SEED:=772241

func _plots()->Array:
	return [{"id":1,"centroid":Vector2.ZERO,"polygon":PackedVector2Array([Vector2(-.005,-.005),Vector2(.005,-.005),Vector2(.005,.005),Vector2(-.005,.005)]),"land_use":"communal","status":"active"}]

func _nuclei()->Array:
	return [{"id":1,"position":Vector2.ZERO,"pull":1.0,"active":true}]

func _grow(count:int,context:Dictionary={})->Dictionary:
	var plots:=_plots()
	var routes:Array=[]
	for id in range(2,count+2):
		var geometry:=Geometry.household(SEED,id,plots,routes,_nuclei(),context)
		if geometry.is_empty(): break
		var center:=Geometry.polygon_centroid(geometry.polygon)
		var nearest:Vector2=plots[0].centroid
		for plot:Dictionary in plots:
			if center.distance_to(plot.centroid)<center.distance_to(nearest): nearest=plot.centroid
		routes.append({"points":Geometry.route_points(center,nearest,id,SEED),"active":true})
		plots.append({"id":id,"centroid":center,"polygon":geometry.polygon,"land_use":"residential_compound","status":"active"})
	return {"plots":plots,"routes":routes}

func test_growth_adds_ground_without_moving_or_mutating_inherited_parcels()->void:
	var young:=_grow(12)
	var mature:=_grow(44)
	assert_int(young.plots.size()).is_equal(13)
	assert_int(mature.plots.size()).is_equal(45)
	for index in young.plots.size():
		assert_dict(mature.plots[index]).is_equal(young.plots[index])
	for index in young.routes.size():
		assert_dict(mature.routes[index]).is_equal(young.routes[index])
	var original:Dictionary=mature.duplicate(true)
	var next:=Geometry.household(SEED,46,mature.plots,mature.routes,_nuclei())
	assert_dict(next).is_not_empty()
	assert_dict(mature).is_equal(original)
	assert_int((next.polygon as PackedVector2Array).size()).is_between(5,8)

func test_terrain_and_route_access_shape_accretion_not_discovery()->void:
	var context:={"buildable_land_at":func(x:float,_z:float)->bool:return x>=-.009}
	var grow:=_grow(20,context)
	assert_int(grow.plots.size()).is_equal(21)
	for plot:Dictionary in grow.plots.slice(1):
		# The selector evaluates the proposed centre; its irregular vertices can
		# overhang by their 7-10m radius, just as root settlement parcels do.
		assert_float(float(plot.centroid.x)).is_greater(-.012)
	var plots:=_plots()
	var routes:=[{"points":PackedVector2Array([Vector2.ZERO,Vector2(.12,0)]),"active":true}]
	var near:=Geometry.site_score(Vector2(.08,.005),.007,"residential_compound",plots,routes,_nuclei())
	var far:=Geometry.site_score(Vector2(-.08,.005),.007,"residential_compound",plots,routes,_nuclei())
	assert_float(near).is_greater(far)
	var before:=Geometry.household(SEED,2,plots,routes,_nuclei(),context)
	context["visible_at"]=func(_x:float,_z:float)->bool:return false
	assert_dict(Geometry.household(SEED,2,plots,routes,_nuclei(),context)).is_equal(before)

func test_terrain_callbacks_use_explicit_world_origin_without_mutating_context()->void:
	var visited:Array[Vector2]=[]
	var context:={"settlement_origin":Vector3(14034,9,-2900),"buildable_land_at":func(x:float,z:float)->bool:visited.append(Vector2(x,z));return true}
	var before:=context.duplicate(false)
	assert_float(Geometry.terrain_score(Vector2(.04,-.03),context)).is_equal(0.0)
	assert_array(visited).is_equal([Vector2(14034.04,-2900.03)])
	assert_dict(context).is_equal(before)

func test_water_steep_land_and_river_channel_reject_growth()->void:
	var blocked:=[
		{"buildable_land_at":func(_x:float,_z:float)->bool:return false},
		{"terrain_height_at":func(x:float,_z:float)->float:return x*.5},
		{"river_distance_at":func(_x:float,_z:float)->float:return .01}]
	for context:Dictionary in blocked:
		assert_float(Geometry.terrain_score(Vector2(.04,.03),context)).is_less(-9000.0)
		assert_dict(Geometry.household(SEED,2,_plots(),[],_nuclei(),context)).is_empty()

func test_household_attempts_and_callback_work_are_bounded()->void:
	var calls:={"land":0,"height":0,"river":0}
	var context:={
		"buildable_land_at":func(_x:float,_z:float)->bool:calls.land+=1;return true,
		"terrain_height_at":func(_x:float,_z:float)->float:calls.height+=1;return .5,
		"river_distance_at":func(_x:float,_z:float)->float:calls.river+=1;return .16}
	assert_dict(Geometry.household(SEED,2,_plots(),[],_nuclei(),context)).is_not_empty()
	assert_int(calls.land).is_between(1,72)
	assert_int(calls.height).is_equal(calls.land*4)
	assert_int(calls.river).is_equal(calls.land)

func test_supplied_rng_preserves_follow_on_construction_draws()->void:
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d:settlement_growth:%d" % [SEED,2])
	var before:=rng.state
	var given:=Geometry.household(SEED,2,_plots(),[],_nuclei(),{},rng)
	assert_dict(given).is_equal(Geometry.household(SEED,2,_plots(),[],_nuclei()))
	assert_int(rng.state).is_not_equal(before)
	# Frozen against the pre-extraction root model (adea08b5). Guard its
	# follow-on capacity/hazard draws as well as the selected location.
	assert_int(rng.state).is_equal(-3444248481538234857)
	assert_vector(given.center).is_equal(Vector2(.0168296080082655,.00412882072851062))
	assert_float(given.radius).is_equal_approx(.00899650529026985,1e-12)
	assert_int(rng.randi_range(7,10)).is_equal(8)
	assert_float(rng.randf_range(.08,.20)).is_equal_approx(.153317362070084,1e-12)

func test_routes_keep_real_endpoints_and_bounded_bends()->void:
	var start:=Vector2(.080,.034)
	var finish:=Vector2(.01,-.025)
	for founding in [false,true]:
		var points:=Geometry.route_points(start,finish,7,SEED,founding)
		assert_int(points.size()).is_equal(4)
		assert_vector(points[0]).is_equal(start)
		assert_vector(points[3]).is_equal(finish)
		for point in points:
			assert_float(point.distance_to(Geometry2D.get_closest_point_to_segment(point,start,finish))).is_less_equal(.005001)
	assert_array(Geometry.route_points(start,start,7,SEED)).is_equal(PackedVector2Array([start,start,start,start]))

func test_founding_reserves_hearth_and_keeps_functional_ground_human_scale()->void:
	var rng:=RandomNumberGenerator.new()
	rng.seed=SEED
	assert_vector(Geometry.founding_center(SEED,0,24,"communal",rng,0)).is_equal(Vector2.ZERO)
	for index in 18:
		var point:=Geometry.founding_center(SEED,index,24,"residential_compound",rng,0)
		assert_float(point.length()).is_between(.013999,.055)
	for use in ["water","waste"]:
		assert_float(Geometry.founding_center(SEED,23,24,use,rng,0).length()).is_between(.065,.106)

func test_founding_geometry_matches_pre_extraction_root_fixture()->void:
	# Original settlement_model.gd at adea08b5; preserve float32 positions and
	# RNG consumption so the remaining founding record is unchanged as well.
	var cases:=[
		["residential_compound",Vector2(0.0185712724924088,-0.00709958607330918),1982242971601000051],
		["storage",Vector2(0.00858205556869507,-0.00316722877323627),1982242971601000051],
		["water",Vector2(-0.0504992380738258,0.0513418354094028),-3376787958293191623],
		["waste",Vector2(0.0325508043169975,-0.0821395143866539),-3376787958293191623]
	]
	for fixture:Array in cases:
		var rng:=RandomNumberGenerator.new()
		rng.seed=SEED
		assert_vector(Geometry.founding_center(SEED,7,24,fixture[0],rng,2)).is_equal(fixture[1])
		assert_int(rng.state).is_equal(fixture[2])

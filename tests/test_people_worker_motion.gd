extends GdUnitTestSuite
const View=preload("res://scripts/hud/people_settlement_view.gd")
const Fixture=preload("res://tests/city_evolution_visual_fixture.gd")

func test_heading_matches_real_displacement_out_and_back()->void:
	for heading in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN,Vector2(1,1).normalized(),Vector2(-1,1).normalized()]:
		var walk:Dictionary={"path":PackedVector2Array([Vector2.ZERO,heading*.02]),"phase":0.0,"speed":.001}
		for time in [2.0,12.0,22.0,32.0]:
			var state:Dictionary=View._worker_sample(walk,time)
			var next:Dictionary=View._worker_sample(walk,time+.01)
			assert_float(Vector2(state.direction).normalized().dot(Vector2(next.position-state.position).normalized())).is_greater(.999)
	var task:Dictionary={"stationary":Vector2(.01,.02),"target":Vector2(.009,.02)}
	assert_float(Vector2(View._worker_sample(task,100).direction).distance_to(Vector2(-.001,0))).is_less(.000001)

func test_visual_routes_detour_around_building_and_hearth_without_record_writes()->void:
	var town:Control=auto_free(View.new())
	town._key=812;town._bounds=Rect2(-.025,-.015,.05,.03)
	town._building_plan={"buildings":[{"position":Vector2(-.006,0),"radius":.004}]}
	town.snapshot={"plots":[{"form":"open_hearth_yard","status":"active","centroid":Vector2(.008,0)}],"routes":[{"active":true,"points":PackedVector2Array([Vector2(-.023,0),Vector2(.023,0)])}]}
	var before:=var_to_bytes(town.snapshot)
	var obstacles:Array[Dictionary]=town._worker_blockers()
	var paths:Array[PackedVector2Array]=town._worker_routes(obstacles)
	assert_int(paths.size()).is_equal(1)
	assert_int(paths[0].size()).is_greater(2)
	for p in range(1,paths[0].size()):
		for obstacle:Dictionary in obstacles:
			var nearest:=Geometry2D.get_closest_point_to_segment(obstacle.center,paths[0][p-1],paths[0][p])
			assert_float(nearest.distance_to(obstacle.center)).is_greater_equal(float(obstacle.radius))
	assert_that(var_to_bytes(town.snapshot)).is_equal(before)

func test_allocations_do_not_create_empty_ground_work_actions()->void:
	var context:Dictionary={"plots":[Fixture.plot(1)],"routes":[{"id":1,"active":true,"points":PackedVector2Array([Vector2(-.025,.022),Vector2(.025,.022)])}],"population":93,"origin":Vector3.ZERO,"allocations":{"Knowledge":30,"Defense":30,"Food":30}}
	var town:Control=auto_free(View.new());add_child(town);town.size=Vector2(900,600);town.configure(context)
	assert_int(town.visual_people_count).is_greater(0)
	for walk:Dictionary in town._walks:assert_bool(walk.has("stationary")).is_false()
	# A real rendered bench enables a nearby, facing task; it creates no site.
	var bench:=Node3D.new();bench.name="Workplace_bench";bench.position=Vector3(.025,0,.025);town.model.add_child(bench)
	context.allocations={"Crafting":30};town.update_state(context)
	var tasks:=0
	for walk:Dictionary in town._walks:
		if not walk.has("stationary"):continue
		tasks+=1
		assert_str(walk.source).is_equal("bench")
		assert_int(walk.pose).is_equal(8)
		assert_float(Vector2(walk.stationary).distance_to(Vector2(.025,.025))).is_less(0.0011)
		assert_float(Vector2(walk.target).distance_to(Vector2(.025,.025))).is_less(0.00001)
	assert_int(tasks).is_equal(1)

func test_actual_supply_delivery_pauses_loads_and_returns_empty()->void:
	var delivery:Dictionary={"path":PackedVector2Array([Vector2.ZERO,Vector2(.004,0)]),"length":.004,"speed":.001,"phase":0.0,"pause":1.0,"delivery":true,"pickup_target":Vector2(0,.001),"drop_target":Vector2(.004,.001)}
	var pickup:Dictionary=View._worker_sample(delivery,.5)
	assert_int(pickup.pose).is_equal(8);assert_bool(pickup.carrying).is_false()
	assert_that(pickup.position).is_equal(Vector2.ZERO)
	var outbound:Dictionary=View._worker_sample(delivery,3)
	assert_bool(outbound.carrying).is_true();assert_float(outbound.direction.x).is_greater(0)
	assert_float(outbound.traveled).is_equal(.002)
	var unload:Dictionary=View._worker_sample(delivery,5.5)
	assert_int(unload.pose).is_equal(100);assert_bool(unload.carrying).is_true()
	assert_that(unload.position).is_equal(Vector2(.004,0))
	assert_float(View._worker_sample(delivery,5.1).traveled).is_equal(float(unload.traveled))
	var returning:Dictionary=View._worker_sample(delivery,8)
	assert_bool(returning.carrying).is_false();assert_float(returning.direction.x).is_less(0)
	assert_float(returning.traveled).is_equal(.006)

extends GdUnitTestSuite
const Placement=preload("res://scripts/settlement_life_placement.gd")
const Living=preload("res://scripts/living_map.gd")
const Early=preload("res://scripts/early_settlement_visual.gd")
const Fixture=preload("res://tests/city_evolution_visual_fixture.gd")

func _plot(id:int,at:Vector2,half:=Vector2(.004,.005))->Dictionary:
	var polygon:=PackedVector2Array()
	for corner in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:polygon.append(at+corner*half)
	return {"id":id,"seed":12,"land_use":"mixed_household","fabric_generation":9,"storeys":3,"status":"active","frontage_route_id":1,"centroid":at,"visual_building_sites":[{"id":str(id),"position":at,"angle":0.0,"footprint":polygon}]}

func test_frontage_is_outside_the_real_building_and_inputs_are_unchanged()->void:
	var plots:=[_plot(1,Vector2.ZERO)]
	var routes:=[{"id":1,"active":true,"points":PackedVector2Array([Vector2(-.03,.01),Vector2(.03,.01)])}]
	var original:=var_to_bytes([plots,routes])
	var placement:=Placement.new();placement.configure(plots,routes)
	assert_int(placement.entries.size()).is_equal(1)
	assert_bool(placement.open_at(placement.entries[0].door)).is_true()
	assert_float(placement.entries[0].door.y).is_greater(.005+Placement.CLEARANCE)
	assert_float(placement.entries[0].frontage.y).is_equal_approx(.01,.00000001)
	assert_bool(var_to_bytes([plots,routes])==original).is_true()

func test_worker_path_detours_around_multiple_footprints_and_is_cached_by_value()->void:
	var placement:=Placement.new()
	placement.configure([_plot(1,Vector2.ZERO),_plot(2,Vector2(.012,.005))],[])
	var from:=Vector2(-.015,0);var to:=Vector2(.025,0)
	assert_bool(placement.clear_segment(from,to)).is_false()
	var path:=placement.route(from,to)
	assert_int(path.size()).is_greater(2)
	assert_vector(path[0]).is_equal(from);assert_vector(path[-1]).is_equal(to)
	for i in range(1,path.size()):assert_bool(placement.clear_segment(path[i-1],path[i])).is_true()
	var again:=placement.route(from,to)
	assert_bool(again==path).is_true()
	again[0]=Vector2(100,100)
	assert_vector(placement.route(from,to)[0]).is_equal(from)
	assert_bool(placement.route(Vector2.ZERO,to).is_empty()).is_true()

func test_road_route_uses_active_frontage_and_never_crosses_a_building_or_water()->void:
	var placement:=Placement.new()
	var routes:=[{"id":1,"active":true,"points":PackedVector2Array([Vector2(-.03,.01),Vector2(.03,.01)])}]
	placement.configure([_plot(1,Vector2.ZERO)],routes)
	var from:=Vector2(-.025,.007);var to:=Vector2(.025,.007)
	var path:=placement.route(from,to)
	assert_int(path.size()).is_greater(2)
	var on_road:=false
	for point in path:if is_equal_approx(point.y,.01):on_road=true
	assert_bool(on_road).is_true()
	for i in range(1,path.size()):assert_bool(placement.clear_segment(path[i-1],path[i])).is_true()
	placement.configure([],[])
	assert_bool(placement.route(from,to,func(p:Vector2)->bool:return absf(p.x)>.004).is_empty()).is_true()

func test_paths_and_graph_inputs_stay_bounded()->void:
	var placement:=Placement.new();placement.configure([],[])
	for i in Placement.MAX_CACHED_PATHS+10:placement.route(Vector2(i*.001,0),Vector2(i*.001,.01))
	assert_int(placement.paths.size()).is_equal(Placement.MAX_CACHED_PATHS)
	placement.configure([],[])
	assert_bool(placement.paths.is_empty()).is_true()

func test_aggregate_parcels_are_conservative_obstacles_without_fake_chimneys()->void:
	var plot:=_plot(129,Vector2.ZERO)
	plot.polygon=plot.visual_building_sites[0].footprint
	plot.erase("visual_building_sites")
	plot.building_materials={"applied":["wall_chimneys"]}
	var placement:=Placement.new()
	placement.configure([plot],[{"id":1,"points":PackedVector2Array([Vector2(-.03,.01),Vector2(.03,.01)])}])
	assert_bool(placement.open_at(Vector2.ZERO)).is_false()
	assert_bool(placement.entries[0].rendered).is_false()
	assert_bool(placement.open_at(placement.entries[0].door)).is_true()

func test_chimney_sources_match_rendered_caps_not_population_or_modern_vents()->void:
	GameState.reset_for_new_world(42)
	var plot:=_plot(1,Vector2.ZERO)
	assert_bool(Placement.chimney_outlets(plot).is_empty()).is_true()
	plot.building_materials={"applied":["wall_chimneys"]}
	plot.roof_plan="fired_tile_roof"
	var sources:=Placement.chimney_outlets(plot)
	assert_int(sources.size()).is_equal(2)
	for source in sources:assert_float(source.y).is_equal_approx((3.1*3+1.4+.94)*.001,.000001)
	plot.roof_plan="rubble_slab"
	var low:=Placement.chimney_outlets(plot)
	# The existing flat terrace has no chimney mesh despite the installed
	# practice; presentation must follow that actual geometry, not infer one.
	assert_bool(low.is_empty()).is_true()
	plot.seed=14;plot.roof_plan="fired_tile_roof"
	var corner:=Placement.chimney_outlets(plot)
	plot.roof_plan="rubble_slab";low=Placement.chimney_outlets(plot)
	assert_int(corner.size()).is_equal(1);assert_int(low.size()).is_equal(1)
	if not low.is_empty() and not corner.is_empty():assert_float(low[0].y).is_less(corner[0].y)
	plot.fabric_generation=12
	assert_bool(Placement.chimney_outlets(plot).is_empty()).is_true()

func test_actual_modern_placement_produces_clear_frontages_and_routes()->void:
	Fixture.initialize()
	var snapshot:=Fixture.snapshot(3000)
	var plan:=Early.layout(snapshot.plots,snapshot.routes,func(_p:Vector2)->bool:return true)
	Early.remember_layout(plan,snapshot.plots)
	var placement:=Placement.new();placement.configure(snapshot.plots,snapshot.routes)
	assert_int(placement.entries.size()).is_greater(40)
	var tested:=0;var routed:=0;var started:=Time.get_ticks_usec()
	for i in range(0,placement.entries.size()-1,5):
		var from:Vector2=placement.entries[i].door;var to:Vector2=placement.entries[i+1].door
		if not from.is_finite() or not to.is_finite():continue
		var path:=placement.route(from,to)
		tested+=1
		if path.size()>1:routed+=1
		for j in range(1,path.size()):assert_bool(placement.clear_segment(path[j-1],path[j])).is_true()
	print("CITY_LIFE_PATHS ",tested," representative routes / ",routed," reached in ",(Time.get_ticks_usec()-started)/1000.0,"ms; footprints=",placement.obstacles.size())
	assert_int(tested).is_greater(20)
	assert_int(routed).is_equal(tested)

class Host extends Node3D:
	var settler_marker:=Node3D.new()
	var camera:=Camera3D.new()
	var camera_target:=Vector3.ZERO
	var game_speed:=1.0
	var travel_active:=false
	var seasonal_materials:Array[WeakRef]=[]
	func _init()->void:
		add_child(settler_marker);add_child(camera);camera.size=.2
	func _height_at(x:float,_z:float)->float:return .1+sin(x*120.0)*.002
	func _settlement_stage_land_at(_point:Vector2)->bool:return true
	func _speed_hours_per_second()->float:return 24.0

func test_live_workers_follow_clear_routes_at_constant_speed_without_a_phantom_city_hearth()->void:
	Fixture.initialize()
	var snapshot:=Fixture.snapshot(3000)
	var plan:=Early.layout(snapshot.plots,snapshot.routes,func(_p:Vector2)->bool:return true)
	Early.remember_layout(plan,snapshot.plots)
	GameState.settlement_founded_at=Vector3(12,.1,-8);GameState.settlement_site_committed=true
	GameState.population_total=200
	GameState.population_allocations={"Crafting":40,"Logistics":40,"Construction":20,"Administration":10,"Knowledge":10}
	var host:Host=auto_free(Host.new());add_child(host)
	host.camera.position=GameState.settlement_founded_at+Vector3(0,.2,.1)
	var layer:Node3D=Living.new();layer.terrain=host;host.add_child(layer);layer.set_process(false)
	assert_bool(layer.hearth_active).is_false()
	assert_int(layer.smoke_mm.multimesh.visible_instance_count).is_equal(0)
	assert_int(layer.workers.size()).is_equal(Living.figure_budget(200))
	var worker:Dictionary=layer.workers[0]
	var from:Vector2=layer.navigation.entries[0].door
	var to:Vector2=layer.navigation.entries[10].door
	layer._set_path(worker,from,to)
	worker.pose=Living.POSES.walk
	worker.h0=layer._local_height(from);worker.h1=layer._local_height(to);worker.hm=layer._local_height(from.lerp(to,.5))
	assert_bool(worker.blocked).is_false()
	assert_int(worker.path.size()).is_greater(2)
	var length:float=worker.path_lengths[-1]
	assert_float(worker.dur).is_equal_approx(maxf(.6,length/(Living.WALK_MPS*Living.UNIT*layer._pace())),.00001)
	for sample in 41:
		worker.t=worker.dur*sample/40.0
		var transform:Transform3D=layer._worker_transform(worker,false)
		var p:=Vector2(transform.origin.x,transform.origin.z)
		assert_bool(layer.navigation.open_at(p)).is_true()
		assert_float(absf(transform.origin.y-layer._local_height(p))).is_less(.0001)
	# A geometry refresh invalidates the path cache, even without plot count or
	# fifteen-day bucket changes. Existing actors retain their representative IDs.
	layer.navigation.paths["stale"]=PackedVector2Array()
	GameState.settlement_plots[0].status="reclaimed"
	layer._refresh_site()
	assert_bool(layer.navigation.paths.has("stale")).is_false()
	assert_int(layer.workers.size()).is_equal(Living.figure_budget(200))

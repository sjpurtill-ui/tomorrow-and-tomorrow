extends GdUnitTestSuite
## The living map (fun audit #6): a bounded crowd that shows the real labour
## mix, hearth smoke that grows with the people, births, burials and scouts
## marked on the map, and the seasonal shader told the year's direction.
const Living:=preload("res://scripts/living_map.gd")

class Host extends Node3D:
	var settler_marker:=Node3D.new()
	var camera:=Camera3D.new()
	var camera_target:=Vector3.ZERO
	var game_speed:=4.0
	var travel_active:=false
	var seasonal_materials:Array[WeakRef]=[]
	func _init()->void:
		add_child(settler_marker)
		add_child(camera)
		camera.size=0.14
	func _height_at(_x:float,_z:float)->float:return 0.1
	func _speed_hours_per_second()->float:return 24.0

func before_test()->void:
	GameState.reset_for_new_world(4242)
	GameState.population_total=120
	GameState.population_allocations={"Food":30,"Survey":6,"Extraction":8,"Construction":8,"Crafting":5,"Logistics":5,"Knowledge":4,"Administration":3,"Defense":3}
	GameState.simulation_metrics["food_sources"]=[{"name":"Wild gathering","produced":60.0},{"name":"Hunting","produced":0.0},{"name":"Fishing","produced":40.0},{"name":"Cultivation","produced":0.0}]
	GameState.settlement_site_committed=true
	GameState.settlement_founded_at=Vector3(12.0,0.1,-8.0)
	GameState.hearth_season={"start_day":0,"born":0,"buried":0}

func _host()->Host:
	var host:Host=auto_free(Host.new())
	add_child(host)
	host.camera.position=GameState.settlement_founded_at+Vector3(0,0.2,0.1)
	return host

func test_figure_budget_is_bounded_and_grows_slowly()->void:
	assert_int(Living.figure_budget(0)).is_equal(0)
	assert_int(Living.figure_budget(5)).is_equal(5)
	assert_int(Living.figure_budget(120)).is_equal(24)
	assert_int(Living.figure_budget(480)).is_equal(Living.MAX_WORKERS)
	assert_int(Living.figure_budget(5000000)).is_equal(Living.MAX_WORKERS)

func test_food_workers_split_by_what_food_came_from()->void:
	var shares:=Living.activity_shares()
	assert_float(float(shares.gather)).is_equal_approx(18.0,0.001)
	assert_float(float(shares.fish)).is_equal_approx(12.0,0.001)
	assert_bool(shares.has("hunt")).is_true()
	assert_float(float(shares.hunt)).is_equal_approx(0.0,0.001)
	assert_float(float(shares.build)).is_equal_approx(8.0,0.001)
	assert_float(float(shares.watch)).is_equal_approx(3.0,0.001)

func test_visible_mix_matches_real_labour_within_one_figure()->void:
	var shares:=Living.activity_shares()
	var total:=0.0
	for key in shares:total+=float(shares[key])
	for budget in [8,17,24,40]:
		var counts:=Living.allocate(shares,budget)
		var assigned:=0
		for key in counts:
			assigned+=int(counts[key])
			assert_float(absf(float(counts[key])-float(budget)*float(shares[key])/total)).is_less(1.0)
		assert_int(assigned).is_equal(budget)

func test_smoke_grows_with_the_people_but_is_capped()->void:
	assert_int(Living.plume_count(0)).is_equal(0)
	assert_int(Living.plume_count(12)).is_equal(1)
	assert_int(Living.plume_count(120)).is_equal(5)
	assert_int(Living.plume_count(9000000)).is_equal(Living.MAX_PLUMES)

func test_layer_shows_the_workers_and_reports_them_against_labour()->void:
	var host:=_host()
	Living.refresh(host)
	var layer:=host.get_node_or_null(Living.NODE_NAME)
	assert_object(layer).is_not_null()
	var report:Dictionary=layer.activity_report()
	assert_int(int(report.workers)).is_equal(24)
	assert_float(float(report.max_share_error)).is_less_equal(1.0/24.0+0.001)
	assert_int(int(report.plumes)).is_equal(5)
	# One draw call per batch; never more instances than the cap.
	var workers:MultiMeshInstance3D=layer.get("worker_mm")
	assert_int(workers.multimesh.instance_count).is_equal(Living.MAX_WORKERS)
	assert_int(workers.multimesh.visible_instance_count).is_equal(24)

func test_births_burials_and_scouts_leave_marks_on_the_map()->void:
	var host:=_host()
	Living.refresh(host)
	var layer:=host.get_node(Living.NODE_NAME)
	GameState.hearth_season={"start_day":0,"born":1,"buried":1}
	Living.refresh(host)
	var report:Dictionary=layer.activity_report()
	assert_int(int(report.flares)).is_equal(1)
	assert_int(int(report.event_walkers)).is_greater_equal(5)
	# A new season's tally counts from zero again.
	GameState.hearth_season={"start_day":91,"born":1,"buried":0}
	Living.refresh(host)
	assert_int(int(layer.activity_report().flares)).is_equal(2)
	CivilizationSystem.scout_report_returned.emit({"personnel":4,"lost_personnel":1,"return_route":[{"x":13.0,"z":-8.0},{"x":12.2,"z":-8.0},{"x":12.0,"z":-8.0}]})
	var walkers:Array=layer.get("events")
	var party:=walkers.filter(func(w:Dictionary)->bool:return String(w.kind)=="party")
	assert_int(party.size()).is_equal(3)
	# The party comes in from the side its road leads (east here).
	assert_float((party[0].points[0] as Vector2).x).is_greater(0.2)
	assert_int(walkers.size()).is_less_equal(Living.MAX_EVENT_FIGURES)

func test_marks_stay_bounded_under_a_flood_of_deaths()->void:
	var host:=_host()
	Living.refresh(host)
	var layer:=host.get_node(Living.NODE_NAME)
	for day in 20:
		GameState.hearth_season={"start_day":0,"born":(day+1)*5,"buried":(day+1)*7}
		Living.refresh(host)
	var report:Dictionary=layer.activity_report()
	assert_int(int(report.flares)).is_less_equal(Living.MAX_FLARES)
	assert_int(int(report.event_walkers)).is_less_equal(Living.MAX_EVENT_FIGURES)

func test_seasonal_shader_learns_the_direction_of_the_year()->void:
	var host:=_host()
	var material:=ShaderMaterial.new()
	host.seasonal_materials.append(weakref(material))
	GameState.elapsed_days=10.0
	Living.refresh(host)
	assert_float(float(material.get_shader_parameter("season_contrast"))).is_equal(1.0)
	assert_float(float(material.get_shader_parameter("season_turn"))).is_greater(0.9)
	GameState.elapsed_days=190.0
	Living.refresh(host)
	assert_float(float(material.get_shader_parameter("season_turn"))).is_less(-0.9)

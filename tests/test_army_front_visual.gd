extends GdUnitTestSuite
const FRONT := preload("res://scripts/army_front_visual.gd")
const VIEW := preload("res://scripts/battle_diorama.gd")
const MAP := preload("res://scripts/local_terrain.gd")

func force(count: int = 1000) -> Dictionary:
	return {"troops":count,"formations":[{"id":1,"count":count,"unit":"line_infantry","equipment":count}],"readiness":0.8,"morale":0.9}

func area(sections: Array) -> float:
	var value := 0.0
	for section in sections: value += FRONT.area_of(section.polygon)
	return value

func bounds(sections: Array) -> Rect2:
	var result := Rect2()
	var first := true
	for section in sections:
		for point in section.polygon:
			if first: result=Rect2(point,Vector2.ZERO);first=false
			else: result=result.expand(point)
	return result

func before_test() -> void:
	GameState.reset_for_new_world(741991)
	MilitaryCampaign.reset_for_new_world()

func test_strength_area_deployment_and_facing_are_physically_consistent() -> void:
	var full := FRONT.layout(force())
	var half := FRONT.layout(force(500))
	assert_float(area(half)/area(full)).is_equal_approx(0.5,0.0001)
	var march := FRONT.layout(force(),0)
	assert_float(area(march)).is_equal_approx(area(full),0.1)
	assert_float(bounds(full).size.x).is_greater(bounds(march).size.x)
	assert_float(bounds(full).size.y).is_less(bounds(march).size.y)
	var turned := FRONT.layout(force(),1,PI/2)
	assert_float(bounds(turned).size.y).is_equal_approx(bounds(full).size.x,0.01)
	assert_array(FRONT.layout(force(0))).is_empty()
	assert_array(FRONT.layout({})).is_empty()
	var captured := force(); captured.status="captured"
	assert_array(FRONT.layout(captured)).is_empty()

func test_explicit_detachments_bend_without_connecting_gaps() -> void:
	var army := {"troops":200,"formations":[{"id":1,"count":100,"deployment_position_m":Vector2(-100,0),"front_bend_m":8},{"id":2,"count":100,"deployment_position_m":Vector2(100,80),"status":"reserve"}]}
	var sections := FRONT.layout(army)
	assert_int(sections.size()).is_equal(2)
	assert_vector(sections[0].center).is_equal(Vector2(-100,0))
	assert_vector(sections[1].center).is_equal(Vector2(100,80))
	assert_array(Geometry2D.intersect_polygons(sections[0].polygon,sections[1].polygon)).is_empty()
	var node: ArmyFrontVisual = auto_free(FRONT.new())
	node.land = func(_point: Vector2) -> bool: return false
	node.configure(army,Color.BLUE,1,0,true)
	assert_bool(node.surface_node.mesh == null).is_true()

func test_unknown_and_dated_foreign_observations_never_read_live_forces() -> void:
	var sighting := {"id":"old","position":{"x":3,"z":4},"strength_estimate_low":80,"strength_estimate_high":120,"day":9,"identified":false,"formations":[{"count":999999}],"troops":999999}
	var view := WarfareMapPresentation.foreign_marker(sighting,1)
	assert_int(FRONT.active_count(view.front_force)).is_equal(100)
	assert_int(int(view.observed_day)).is_equal(9)
	assert_int(view.front_force.get("formations",[]).size()).is_equal(0)
	var unknown := WarfareMapPresentation.foreign_marker({"id":"unknown"},1)
	assert_array(FRONT.layout(unknown.front_force)).is_empty()

func test_interpolation_pause_and_large_bounds_do_not_mutate_input() -> void:
	var node: ArmyFrontVisual = auto_free(FRONT.new())
	var source := force(); var copy := source.duplicate(true)
	node.configure(source,Color.BLUE,0,0,true)
	node.configure(source,Color.BLUE,1)
	var before := node.displayed_sections()
	node.advance(1,true)
	assert_array(node.displayed_sections()).is_equal(before)
	node.advance(1)
	assert_float(area(node.displayed_sections())).is_equal_approx(4000,0.1)
	assert_dict(source).is_equal(copy)
	var huge := force(1000000000)
	node.configure(huge,Color.BLUE,1,0,true)
	assert_int(node.surface_node.get_meta("triangle_count")).is_greater(0)
	assert_int(node.surface_node.get_meta("triangle_count")).is_less_equal(FRONT.MAX_SECTIONS*FRONT.SAMPLES*2)
	assert_int(node.get_child_count()).is_equal(1)

func test_invasion_renderer_and_replay_do_not_resolve_again() -> void:
	GameState.ensure_population_total(10000)
	MilitaryCampaign.home_army = MilitaryCampaign.simulator.create_formation_force("Home",[{"id":1,"unit":"line_infantry","weapon":"spear","count":300}],1,1)
	MilitaryCampaign.active_threat = {"seed":741,"name":"Invasion","enemy_force":MilitaryCampaign.simulator.create_formation_force("Invaders",[{"id":2,"unit":"line_infantry","weapon":"spear","count":250}],1,1),"campaign_mode":"defensive"}
	var engagement := MilitaryCampaign.begin_threat_engagement()
	assert_bool(engagement.has("error")).is_false()
	var view: BattleDiorama = auto_free(VIEW.new())
	add_child(view)
	view.reset(engagement.attacker,engagement.defender)
	assert_int(view.representative_count()).is_equal(0)
	assert_int(view.generals.size()).is_equal(0)
	var before := MilitaryCampaign.engagement_snapshot()
	var simulated: Dictionary = MilitaryCampaign.simulator.simulate(engagement.attacker,engagement.defender,{"seed":81,"max_rounds":1})
	for replay in 3:
		view.apply_snapshot(simulated.attacker,simulated.defender,simulated.rounds[0],simulated.outcome)
		view._process(1)
	assert_dict(MilitaryCampaign.engagement_snapshot()).is_equal(before)
	view.playback_speed=0
	var clock := view.clock; view._process(1)
	assert_float(view.clock).is_equal(clock)

func test_real_map_hook_cancels_camera_scale_and_stack_offsets() -> void:
	var renderer: Node3D = auto_free(MAP.new())
	renderer.camera_target=Vector3(1,0,2)
	renderer._configure_seamless_world(); renderer._configure_shape(); renderer._configure_noise(); renderer._prepare_river_course()
	var camera: Camera3D = auto_free(Camera3D.new()); renderer.camera=camera
	var marker: Node3D = auto_free(Node3D.new())
	var army := force(100); army.position={"x":1.0,"z":2.0}
	var first := PackedVector3Array()
	for size in [0.1,1.0,8.0,80.0]:
		camera.size=size; marker.scale=Vector3.ONE*WarfareMapPresentation.marker_scale(size)
		marker.position=Vector3(size,0,size) # Cosmetic screen-space stack displacement.
		var presentation := WarfareMapPresentation.player_marker(army,size)
		renderer._apply_physical_army_front(marker,presentation)
		var front: ArmyFrontVisual = marker.get_node("OccupiedArmyGround")
		front.advance(1)
		var vertices := PackedVector3Array()
		for section in front.sections:
			for p in section.polygon: vertices.append(marker.transform*front.transform*Vector3(p.x,0,p.y))
		if first.is_empty(): first=vertices
		else:
			for i in vertices.size(): assert_float(vertices[i].distance_to(first[i])).is_less(0.00003)
	var hidden := WarfareMapPresentation.foreign_marker({"visible":false,"last_seen_day":5,"strength_estimate_low":10},1)
	assert_bool(hidden.visible).is_false()
	assert_int(hidden.observed_day).is_equal(5)

func test_alive_noncombat_pools_do_not_inflate_footprint() -> void:
	var army := force(100)
	var expected := area(FRONT.layout(army))
	army.wounded_pool=900;army.scattered_pool=300;army.captured_pool=200;army.dead=700
	assert_float(area(FRONT.layout(army))).is_equal(expected)

func test_siege_uses_two_bounded_fronts_and_no_unknown_camps_or_fire() -> void:
	var scene:Node3D=auto_free(load("res://scripts/siege_city_scene.gd").new())
	add_child(scene)
	var snapshot:Dictionary={"id":"test","population":1000,"defense_stage":3,"damage":0.2,"mode":"offensive","own_force":force(1000),"battle":{},"battle_active":false,"blockade":0.9}
	var saved:=snapshot.duplicate(true)
	scene.configure(snapshot)
	assert_int(scene.figure_count).is_equal(0)
	assert_int(scene.units.get_child_count()).is_equal(2)
	assert_array(scene.figure_groups[1].sections).is_empty()
	assert_dict(snapshot).is_equal(saved)
	var count:int=scene.city.get_child_count()
	for i in 3:scene.configure(snapshot)
	assert_int(scene.city.get_child_count()).is_equal(count)
	assert_int(scene.units.get_child_count()).is_equal(2)

func test_capture_ledger_excludes_prisoners_without_killing_or_mutating_them() -> void:
	var army:=force(100);army.name="Defeated"
	var visual:=FRONT.combat_force(army,{"defeated":"Defeated","prisoners":35})
	assert_int(FRONT.active_count(visual)).is_equal(65)
	assert_int(army.troops).is_equal(100)
	assert_float(area(FRONT.layout(visual))).is_equal_approx(260,0.01)
	assert_int(FRONT.active_count(FRONT.combat_force(army,{"defeated":"Other","prisoners":35}))).is_equal(100)

func test_overflow_cohorts_keep_equipment_area_with_bounded_geometry() -> void:
	var forms:Array=[]
	for i in 100:forms.append({"id":i,"count":100,"unit":"armored_formation","equipment":10})
	var sections:=FRONT.layout({"troops":10000,"formations":forms})
	assert_int(sections.size()).is_equal(FRONT.MAX_SECTIONS)
	assert_float(area(sections)).is_equal_approx(60000,2)

func test_occupation_front_terrain_hook_updates_losses_and_respects_pause_and_parent_visibility() -> void:
	var renderer:Node3D=auto_free(MAP.new())
	renderer._configure_seamless_world();renderer._configure_shape();renderer._configure_noise();renderer._prepare_river_course()
	var revealed:Array=CivilizationSystem.revealed_areas.duplicate(true)
	CivilizationSystem.revealed_areas.append({"x":0,"z":0,"radius":10})
	var army:=force(100);army.army_id=-7;army.garrison_visual=true;army.position={"x":0,"z":0}
	renderer._refresh_close_army_figures([army],-1)
	var marker:Node3D=renderer.close_army_figures["-7"]
	# Mount only the created marker, avoiding a full player terrain initialization.
	var host:Node3D=auto_free(Node3D.new());add_child(host)
	renderer.remove_child(marker);host.add_child(marker)
	var front:ArmyFrontVisual=marker.get_node("OccupiedArmyGround")
	assert_bool(front.is_visible_in_tree()).is_true()
	assert_float(area(front.displayed_sections())).is_equal_approx(400,0.01)
	army.troops=50;army.formations[0].count=50
	var saved:=army.duplicate(true)
	renderer._refresh_close_army_figures([army],-1)
	renderer.game_speed=0;renderer._advance_physical_army_fronts(1)
	assert_float(area(front.displayed_sections())).is_equal_approx(400,0.01)
	renderer.game_speed=1
	marker.hide();renderer._advance_physical_army_fronts(1)
	assert_bool(front.visible).is_true()
	assert_float(area(front.displayed_sections())).is_equal_approx(400,0.01)
	marker.show();host.hide();renderer._advance_physical_army_fronts(1)
	assert_float(area(front.displayed_sections())).is_equal_approx(400,0.01)
	host.show();renderer._advance_physical_army_fronts(1)
	assert_float(area(front.displayed_sections())).is_equal_approx(200,0.01)
	assert_dict(army).is_equal(saved)
	CivilizationSystem.revealed_areas=revealed

func test_siege_termination_only_change_updates_captured_footprint() -> void:
	var scene:Node3D=auto_free(load("res://scripts/siege_city_scene.gd").new());add_child(scene)
	var defender:=force(100);defender.name="Defeated"
	var snapshot:Dictionary={"id":"capture","population":1000,"defense_stage":3,"damage":0,"mode":"offensive","own_force":force(100),"battle":{"attacker":force(100),"defender":defender},"battle_active":false}
	scene.configure(snapshot)
	var front:ArmyFrontVisual=scene.figure_groups[1]
	assert_float(area(front.displayed_sections())).is_equal_approx(400,0.01)
	snapshot.battle.termination={"defeated":"Defeated","prisoners":35}
	var saved:=snapshot.duplicate(true)
	scene.configure(snapshot)
	assert_float(area(front.displayed_sections())).is_equal_approx(260,0.01)
	assert_dict(snapshot).is_equal(saved)
	snapshot.battle.termination.prisoners=100
	scene.configure(snapshot)
	assert_array(front.displayed_sections()).is_empty()
	assert_int(snapshot.battle.defender.troops).is_equal(100)
	assert_int(scene.units.get_child_count()).is_equal(2)

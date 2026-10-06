extends GdUnitTestSuite
const Policy=preload("res://scripts/map_people_policy.gd")
const Living=preload("res://scripts/living_map.gd")
const Ambience=preload("res://scripts/map_ambience.gd")
const Rites=preload("res://scripts/rite_marks.gd")
const Ink=preload("res://scripts/map_life_ink.gd")

func test_map_people_policy_has_no_population_or_zoom_exception()->void:
	assert_bool(Policy.show_people()).is_false()
	for count in [0,1,120,1000,25000,1000000000]:
		assert_int(Policy.representative_count(count)).is_equal(0)

func test_workers_children_returning_scouts_and_processions_never_spawn()->void:
	var population:float=GameState.population_exact
	var living:Node3D=auto_free(Living.new())
	# Exercise the producers directly without constructing the terrain/smoke.
	living.worker_mm=living._figure_batch("Workers",Living.MAX_WORKERS)
	living.child_mm=living._figure_batch("Children",Living.MAX_CHILDREN)
	living.event_mm=living._figure_batch("Processions",Living.MAX_EVENT_FIGURES)
	living.settled=true;living.homes.assign([Vector2.ZERO])
	living._refresh_workers();living._refresh_children()
	living._on_scout_returned({"personnel":12,"day":10})
	var route:Array[Vector2]=[Vector2.ZERO,Vector2(0.1,0.1)]
	living._add_group("procession",12,route,0,1.0,2.0,false)
	assert_array(living.workers).is_empty();assert_array(living.children).is_empty();assert_array(living.events).is_empty()
	for node:MultiMeshInstance3D in [living.worker_mm,living.child_mm,living.event_mm]:
		assert_int(node.multimesh.instance_count).is_equal(0)
		assert_int(node.multimesh.visible_instance_count).is_equal(0)
		assert_bool(node.visible).is_false()
	assert_float(GameState.population_exact).is_equal(population)

func test_great_work_builders_and_rite_mourners_are_suppressed_but_fire_stays()->void:
	var ambience:Node3D=auto_free(Ambience.new())
	ambience.builders=MultiMeshInstance3D.new();ambience.add_child(ambience.builders)
	ambience.builders.multimesh=MultiMesh.new()
	ambience._refresh_builders()
	assert_array(ambience.builder_sites).is_empty()
	assert_bool(ambience.builders.visible).is_false()
	assert_int(ambience.builders.multimesh.visible_instance_count).is_equal(0)
	var rites:Node3D=auto_free(Rites.new())
	var procession:=Node3D.new();rites.add_child(procession)
	rites._procession(procession)
	assert_bool(procession.get_node_or_null("Walkers")==null).is_true()
	assert_array(rites._rings).is_empty()
	assert_bool(procession.get_child_count()>0).is_true()

func test_map_people_shader_is_hidden_and_boat_hull_is_retained()->void:
	assert_bool(bool(Ink.material("person").get_shader_parameter("map_people_visible"))).is_false()
	assert_str(Ink.shader_code("person")).contains("if (!map_people_visible) { discard; }")
	assert_str(Ink.shader_code("boat")).contains("if (map_people_visible)")
	assert_str(Ink.shader_code("boat")).contains("float hull")
	assert_str(Ink.shader_code("bird")).not_contains("if (!map_people_visible)")

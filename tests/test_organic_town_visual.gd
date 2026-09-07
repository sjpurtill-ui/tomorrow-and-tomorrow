extends GdUnitTestSuite

const TOWN := preload("res://scripts/organic_town_visual.gd")
const RENDERER := preload("res://scripts/local_terrain.gd")

func fixture(count: int = 12) -> Dictionary:
	var plots: Array[Dictionary] = []
	var routes: Array[Dictionary] = []
	for index in count:
		var center := Vector2(float(index % 12) * 0.05, float(index / 12) * 0.06)
		var polygon := PackedVector2Array([center + Vector2(-0.019,-0.021), center + Vector2(0.022,-0.019), center + Vector2(0.019,0.021), center + Vector2(-0.021,0.019)])
		plots.append({"id": index + 1, "seed": 177 + index * 31, "centroid": center, "polygon": polygon, "frontage_route_id": index + 1, "area_ha": 0.16, "roof_coverage": 0.35, "resident_count": 20, "material_family": "organic", "material_mix": {"Timber": 0.38, "Fiber Plants": 0.42}, "land_use": "residential_compound", "form": "timber_household", "roof_plan": "timber_ridge", "condition": 0.9, "status": "active", "created_day": 40})
		routes.append({"id": index + 1, "width_m": 1.2, "points": PackedVector2Array([center + Vector2(-0.025,0), center + Vector2(0.004,0.001), center + Vector2(0.023,0.014)])})
	return {"plots": plots, "routes": routes}

func dry(_point: Vector2) -> bool: return true

func identities(plan: Dictionary) -> Array:
	var result := []
	for record in plan.buildings: result.append([record.id, record.position, record.angle, record.variant])
	return result

func test_layout_is_stable_under_population_condition_and_input_order_changes() -> void:
	var data := fixture()
	var before := data.duplicate(true)
	var first := TOWN.layout(data.plots, data.routes, dry)
	assert_int(first.buildings.size()).is_greater(24)
	assert_array(data.plots).is_equal(before.plots)
	for plot in data.plots:
		plot.resident_count += 1
		plot.condition = 0.5
		plot.status = "damaged"
	data.plots.reverse()
	assert_array(identities(TOWN.layout(data.plots, data.routes, dry))).is_equal(identities(first))

func test_footprints_are_inside_plots_clear_of_each_other_roads_and_water() -> void:
	var data := fixture()
	var first := TOWN.layout(data.plots, data.routes, func(point: Vector2) -> bool: return point.y < 0.009)
	assert_int(first.buildings.size()).is_greater(0)
	for record in first.buildings:
		assert_array(Geometry2D.clip_polygons(record.footprint, record.plot.polygon)).is_empty()
		for corner in record.footprint: assert_float(corner.y).is_less(0.009)
		for other in first.buildings:
			if record.id != other.id: assert_array(Geometry2D.intersect_polygons(record.footprint, other.footprint)).is_empty()
		for route in data.routes:
			for segment in range(1, route.points.size()):
				var stroke := Geometry2D.offset_polyline(PackedVector2Array([route.points[segment - 1], route.points[segment]]), TOWN.route_half_width(route))
				for polygon in stroke: assert_array(Geometry2D.intersect_polygons(record.footprint, polygon)).is_empty()
	assert_array(TOWN.layout(data.plots, data.routes, func(_point: Vector2) -> bool: return false).buildings).is_empty()

func test_history_gates_and_large_population_budget() -> void:
	var data := fixture(128)
	assert_bool(TOWN.enabled(data.plots, 1000)).is_true()
	assert_bool(TOWN.enabled(data.plots, 1000000000)).is_false()
	assert_int(TOWN.layout(data.plots, data.routes, dry).buildings.size()).is_between(1, TOWN.MAX_BUILDINGS)
	var plot: Dictionary = data.plots[0].duplicate(true)
	for roof in ["round_thatch", "rubble_slab", "courtyard_flat", "ridge_light_shelter"]:
		plot.roof_plan = roof
		assert_bool(TOWN.supports(plot)).is_false()
	plot.roof_plan = "timber_ridge"
	plot.material_family = "stone"
	assert_bool(TOWN.supports(plot)).is_false()
	plot.material_family = "organic"
	plot.storeys = 2
	assert_bool(TOWN.supports(plot)).is_false()

func test_imported_dimensions_vertex_colors_and_batched_condition() -> void:
	for index in TOWN.KIT.size():
		var mesh := TOWN.kit_mesh(index)
		var bounds := mesh.get_aabb()
		assert_float(bounds.size.y).is_between(5.0, 10.0)
		assert_float(bounds.position.y).is_between(-0.001, 0.001)
		assert_int(mesh.get_surface_count()).is_equal(1)
		assert_int(mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR].size()).is_greater(0)
	var data := fixture()
	var plan := TOWN.layout(data.plots, data.routes, dry)
	var parent: Node3D = auto_free(Node3D.new())
	TOWN.render(plan, Vector3.ZERO, func(_x: float, _z: float) -> float: return 0.25, parent)
	assert_int(parent.get_child_count()).is_between(1, 7)
	var count := 0
	for node in parent.get_children():
		if not node is MultiMeshInstance3D: continue
		count += node.multimesh.instance_count
		var transform: Transform3D = node.get_meta("source_transforms")[0]
		assert_float(transform.basis.x.length()).is_equal_approx(0.001, 0.000001)
		assert_float(transform.origin.y).is_equal_approx(0.2504, 0.00001)
		assert_bool(node.material_override.vertex_color_use_as_albedo).is_true()
	assert_int(count).is_equal(plan.buildings.size())
	for plot in data.plots: plot.status = "ruin"
	var ruin_parent: Node3D = auto_free(Node3D.new())
	TOWN.render(TOWN.layout(data.plots, data.routes, dry), Vector3.ZERO, func(_x: float, _z: float) -> float: return 0.25, ruin_parent)
	assert_int(ruin_parent.get_child_count()).is_equal(0)

func test_real_inherited_plot_sizes_can_accept_the_kit_without_replanning_routes() -> void:
	GameState.reset_for_new_world(772241)
	GameState.initialize_population_model()
	GameState.settlement_completed = ["Hearth Circle"]
	SettlementModel.ensure_founded()
	# Simulate recorded completion of permanent timber houses; no founding tents
	# are silently upgraded by the renderer itself.
	for plot in GameState.settlement_plots:
		if String(plot.land_use) in ["residential_compound", "mixed_household"]:
			plot.form = "timber_and_fibre_household"
			plot.roof_plan = "timber_ridge"
	var plan := TOWN.layout(GameState.settlement_plots, GameState.settlement_routes, dry)
	assert_int(plan.buildings.size()).is_greater(0)
	print("INHERITED_TOWN plots=%d homes=%d" % [GameState.settlement_plots.size(), plan.buildings.size()])

func test_renderer_uses_identical_world_transforms_at_every_camera_distance() -> void:
	GameState.reset_for_new_world(741991)
	var data := fixture(4)
	GameState.settlement_plots = data.plots
	GameState.settlement_routes = data.routes
	var renderer: Node3D = auto_free(RENDERER.new())
	renderer._configure_seamless_world()
	renderer._configure_shape()
	renderer._configure_noise()
	renderer._prepare_river_course()
	renderer.footprint_population = 1000
	var camera: Camera3D = auto_free(Camera3D.new())
	renderer.camera = camera
	# Locate dry real terrain using the same predicate as production.
	var center := Vector3.ZERO
	var found := false
	for x in range(-10, 11):
		for z in range(-10, 11):
			if renderer._settlement_stage_land_at(Vector2(x, z)):
				center = Vector3(x, 0, z)
				found = true
				break
		if found: break
	assert_bool(found).is_true()
	var reference: Array = []
	for size in [0.12, 1.0, 3.0, 16.0, 100.0]:
		camera.size = size
		var parent: Node3D = auto_free(Node3D.new())
		renderer._create_plot_fabric(center, data.plots, renderer._settlement_morphology_lod(), parent)
		var transforms: Array = []
		for node in parent.get_children():
			if node.has_meta("source_transforms"): transforms.append_array(node.get_meta("source_transforms"))
		assert_int(transforms.size()).is_greater(0)
		if reference.is_empty(): reference = transforms
		else: assert_array(transforms).is_equal(reference)
		assert_bool(parent.has_node("PersistentSettlementDensity")).is_false()
	# Existing houses persist across the early-town population boundary; the
	# broader mature land-cover renderer is a separate, unchanged layer.
	for population in [1001, 5000, 5001, 1000000000]:
		renderer.footprint_population = population
		var grown: Node3D = auto_free(Node3D.new())
		renderer._create_plot_fabric(center, data.plots, 0, grown)
		var grown_transforms: Array = []
		for node in grown.get_children():
			if node.has_meta("source_transforms"): grown_transforms.append_array(node.get_meta("source_transforms"))
		assert_array(grown_transforms).is_equal(reference)
	renderer.footprint_population = 1000
	# Current politics must not rotate or replace existing houses.
	GameState.societal_values = {"hierarchy": 0.95, "tradition": 0.05}
	var repeated: Node3D = auto_free(Node3D.new())
	renderer._create_plot_fabric(center, data.plots, 0, repeated)
	var repeated_transforms: Array = []
	for node in repeated.get_children():
		if node.has_meta("source_transforms"): repeated_transforms.append_array(node.get_meta("source_transforms"))
	assert_array(repeated_transforms).is_equal(reference)
	var defense_parent: Node3D = auto_free(Node3D.new())
	var profile: Dictionary = renderer._settlement_expansion_visual_profile({"classification": "village", "population": 1000})
	renderer._create_settlement_stage_landscape(center, profile, data.plots, 0, defense_parent, {"stage": 2, "integrity": 1.0, "construction": {}})
	assert_bool(defense_parent.has_node("PersistentSettlementDefenseGround") or defense_parent.has_node("PersistentSettlementDefenseMassing")).is_true()
	assert_bool(defense_parent.has_node("PersistentUrbanSystems")).is_false()

func test_no_fit_omits_legacy_roofs_and_restores_real_extent() -> void:
	GameState.reset_for_new_world(741991)
	var data := fixture(1)
	data.plots[0].polygon = PackedVector2Array([Vector2(-0.001,-0.001), Vector2(0.001,-0.001), Vector2(0.001,0.001), Vector2(-0.001,0.001)])
	var plan := TOWN.layout(data.plots, data.routes, dry)
	assert_array(plan.buildings).is_empty()
	assert_bool(plan.replaced.has(1)).is_false()
	GameState.settlement_plots = data.plots
	GameState.settlement_routes = data.routes
	var renderer: Node3D = auto_free(RENDERER.new())
	renderer._configure_seamless_world()
	renderer._configure_shape()
	renderer._configure_noise()
	renderer._prepare_river_course()
	renderer.footprint_population = 1000
	var parent: Node3D = auto_free(Node3D.new())
	renderer._create_plot_fabric(Vector3.ZERO, data.plots, 0, parent)
	assert_bool(parent.has_node("PersistentRoofFabric")).is_false()
	var profile: Dictionary = renderer._settlement_expansion_visual_profile({"classification": "village", "population": 1000})
	var expected: Dictionary = renderer._settlement_stage_visual_layout(profile, 1000, data.plots)
	renderer._create_settlement_stage_landscape(Vector3.ZERO, profile, data.plots, 0, parent, {"stage": 0, "integrity": 1.0, "construction": {}})
	assert_float(renderer.rendered_settlement_stage_radius).is_equal(float(expected.radius))

func test_construction_fire_and_reoccupation_keep_reserved_sites() -> void:
	var data := fixture(4)
	var initial := TOWN.layout(data.plots, data.routes, dry)
	for state in ["under_construction", "ruin", "reclaimed"]:
		for plot in data.plots: plot.status = state
		var plan := TOWN.layout(data.plots, data.routes, dry)
		assert_array(identities(plan)).is_equal(identities(initial))
		var parent: Node3D = auto_free(Node3D.new())
		TOWN.render(plan, Vector3.ZERO, func(_x: float, _z: float) -> float: return 0.0, parent)
		assert_int(parent.get_child_count()).is_equal(0)
	for plot in data.plots:
		plot.status = "active"
		plot.damage = {"structural": 0.8, "fire": 0.9}
	var damaged: Node3D = auto_free(Node3D.new())
	TOWN.render(TOWN.layout(data.plots, data.routes, dry), Vector3.ZERO, func(_x: float, _z: float) -> float: return 0.0, damaged)
	assert_int(damaged.get_child_count()).is_equal(0)
	for plot in data.plots: plot.damage = {}
	assert_array(identities(TOWN.layout(data.plots, data.routes, dry))).is_equal(identities(initial))

func test_gardens_use_clear_leftover_ground_and_market_gets_hall() -> void:
	var data := fixture(4)
	data.plots[0].land_use = "market"
	var plan := TOWN.layout(data.plots, data.routes, dry)
	var gardens := 0
	var halls := 0
	for record in plan.buildings:
		if int(record.variant) == 4: halls += 1
		if not record.has("garden"): continue
		gardens += 1
		assert_array(Geometry2D.clip_polygons(record.garden, record.plot.polygon)).is_empty()
		for other in plan.buildings: assert_array(Geometry2D.intersect_polygons(record.garden, other.footprint)).is_empty()
	assert_int(halls).is_equal(1)
	assert_int(gardens).is_greater(0)

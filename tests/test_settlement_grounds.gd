extends GdUnitTestSuite
## Settlement art round three (codex/beauty-3): the worn ground painted from
## the real fabric, coded building shapes, the furniture of daily life, the
## later-town fixture and the map ticker. Visual only: nothing here may
## change the simulation's records.
const GROUNDS := preload("res://scripts/settlement_grounds.gd")
const GROUND := preload("res://scripts/early_settlement_ground.gd")
const SHAPES := preload("res://scripts/settlement_kit_shapes.gd")
const EARLY := preload("res://scripts/early_settlement_visual.gd")
const TOWN := preload("res://scripts/organic_town_visual.gd")
const TICKER := preload("res://scripts/hud/map_ticker_style.gd")

func before_test() -> void:
	GameState.reset_for_new_world(910141)
	GROUNDS.clear()

func _village() -> Dictionary:
	var plots: Array[Dictionary] = []
	var routes: Array[Dictionary] = [
		{"id":1,"active":true,"kind":"desire_path","hierarchy":"lane","width_m":2.0,"traffic":1.0,"points":PackedVector2Array([Vector2(-.04,0),Vector2(0,0),Vector2(.04,.002)])},
		{"id":2,"active":true,"kind":"desire_path","hierarchy":"path","width_m":1.0,"traffic":.5,"points":PackedVector2Array([Vector2(0,0),Vector2(.001,.035)])}]
	plots.append({"id":1,"seed":7,"centroid":Vector2(0,0),"polygon":_square(Vector2.ZERO,.006),"land_use":"communal","form":"maintained_gathering_ground","status":"active","area_ha":.01})
	plots.append({"id":2,"seed":8,"centroid":Vector2(.02,-.015),"polygon":_square(Vector2(.02,-.015),.01),"frontage_route_id":1,"land_use":"residential_compound","form":"durable_household_cluster","material_family":"organic","roof_plan":"round_thatch","status":"active","condition":.9,"area_ha":.04,"roof_coverage":.3,"storeys":1})
	plots.append({"id":3,"seed":9,"centroid":Vector2(-.03,.03),"polygon":_square(Vector2(-.03,.03),.012),"frontage_route_id":2,"land_use":"field","form":"worked_clearance","status":"active","cultivation_phase":"growing","crop_family":"grain","crop_cover":.6,"field_pattern":"irrigated_beds","worker_count":8})
	return {"plots":plots,"routes":routes}

func _square(c: Vector2, h: float) -> PackedVector2Array:
	return PackedVector2Array([c+Vector2(-h,-h),c+Vector2(h,-h),c+Vector2(h,h),c+Vector2(-h,h)])

## The painted square's local coordinates of a settlement-local point.
func _sample(image: Image, center: Vector3, local: Vector2) -> Color:
	var world := Vector2(center.x, center.z) + local
	var uv := (world - (GROUNDS.origin_hi + GROUNDS.origin_lo)) / GROUNDS.size_km
	return image.get_pixelv(Vector2i(clampi(int(uv.x * image.get_width()), 0, image.get_width() - 1), clampi(int(uv.y * image.get_height()), 0, image.get_height() - 1)))

func test_worn_ground_follows_routes_homes_and_fields_without_touching_records() -> void:
	var data := _village()
	var before: Dictionary = data.duplicate(true)
	var plan := EARLY.layout(data.plots, data.routes, func(_p: Vector2) -> bool: return true)
	var center := Vector3(812.25, 0.0, -41.5)
	GROUNDS.build(plan, data.plots, data.routes, center)
	assert_object(GROUNDS.texture).is_not_null()
	assert_float(GROUNDS.strength).is_equal(1.0)
	var image: Image = GROUNDS.texture.get_image()
	# Bare earth on the lane, grass untouched far from anything.
	assert_float(_sample(image, center, Vector2(-.03, 0)).r).is_greater(.5)
	assert_float(_sample(image, center, Vector2(.05, .06)).r).is_less(.05)
	# Ash at the hearth.
	assert_float(_sample(image, center, Vector2.ZERO).b).is_greater(.3)
	# The field is worked ground with its recorded season.
	var fields: Image = GROUNDS.fields_texture.get_image()
	var code := _sample(fields, center, Vector2(-.03, .03))
	assert_float(code.r).is_equal(1.0)
	assert_int(int(round(code.b * 255.0)) & 7).is_equal(GROUNDS.PHASES.find("growing"))
	assert_int((int(round(code.b * 255.0)) >> 3) & 7).is_equal(GROUNDS.PATTERNS.find("irrigated_beds"))
	assert_dict(data).is_equal(before)
	# Unchanged fabric is not repainted.
	var stamps := int(GROUNDS.report.stamps)
	var usec := int(GROUNDS.report.build_usec)
	GROUNDS.build(plan, data.plots, data.routes, center)
	assert_int(int(GROUNDS.report.build_usec)).is_equal(usec)
	assert_int(int(GROUNDS.report.stamps)).is_equal(stamps)

func test_precise_split_origin_and_only_the_home_settlement_repaints() -> void:
	var data := _village()
	var plan := EARLY.layout(data.plots, data.routes, func(_p: Vector2) -> bool: return true)
	var home := Vector3(-11246.46, 3.0, 4439.19)
	GameState.settlement_founded_at = home
	GameState.player_settlements.clear()
	GROUNDS.build_if_home(plan, data.plots, data.routes, home)
	assert_object(GROUNDS.texture).is_not_null()
	# The origin splits into an exact multiple of 64 km and a small remainder.
	assert_float(fmod(absf(GROUNDS.origin_hi.x), 64.0)).is_equal_approx(0.0, 1e-9)
	assert_float(absf(GROUNDS.origin_lo.x)).is_less(64.0)
	var painted: Vector2 = GROUNDS.origin_hi + GROUNDS.origin_lo
	# A secondary city drawn through the same renderers leaves it alone.
	GROUNDS.build_if_home(plan, data.plots, data.routes, home + Vector3(30.0, 0, 0))
	assert_vector(GROUNDS.origin_hi + GROUNDS.origin_lo).is_equal(painted)

func test_coded_shapes_fit_the_authored_envelopes_and_face_outward() -> void:
	for name in ["round_household", "carried_round", "carried_ridge", "rooted_lean_to", "raised_store", "covered_workshop", "earthen_household"]:
		var mesh: Mesh = EARLY.kit_mesh(name)
		var authored: Mesh = EARLY._imported_mesh(name)
		assert_bool(mesh != authored).is_true()
		var a := mesh.get_aabb(); var b := authored.get_aabb()
		assert_vector(a.size).is_equal_approx(Vector3(b.size.x, b.end.y - b.position.y, b.size.z), Vector3.ONE * .02)
		var arrays := mesh.surface_get_arrays(0)
		assert_int((arrays[Mesh.ARRAY_COLOR] as PackedColorArray).size()).is_greater(0)
		# Seen from above, far more of each building faces the sky than the
		# ground (roofs outweigh eave undersides): the normals point outward.
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var up := 0.0
		for i in range(0, vertices.size(), 3):
			var area := (vertices[i + 1] - vertices[i]).cross(vertices[i + 2] - vertices[i]).length() * .5
			up += normals[i].y * area
		assert_float(up).is_greater(0.0)
	# The rubble house keeps its authored mesh and importer LODs.
	assert_bool(EARLY.kit_mesh("rubble_household") == EARLY._imported_mesh("rubble_household")).is_true()
	for index in TOWN.KIT.size():
		var bounds := TOWN.kit_mesh(index).get_aabb()
		assert_float(bounds.size.y).is_between(5.0, 10.0)
	for prop in ["woodpile", "drying_rack", "hide_frame", "hearth_ring", "bench", "pots", "quern", "well", "water_jars", "midden", "kiln", "loom", "pen_wattle", "pen_stone", "frame", "timber_stack"]:
		var mesh := SHAPES.prop(prop)
		assert_object(mesh).is_not_null()
		assert_float(mesh.get_aabb().size.length()).is_between(.3, 14.0)

func test_props_follow_knowledge_land_and_footprints() -> void:
	var data := _village()
	var plan := EARLY.layout(data.plots, data.routes, func(_p: Vector2) -> bool: return true)
	# Nothing tamed: no pens, no animals.
	GameState.discovery_log = []
	GameState.known_discoveries = []
	var parent: Node3D = auto_free(Node3D.new())
	GROUND.render(plan, data.plots, data.routes, Vector3.ZERO, func(_x: float, _z: float) -> float: return 0.0, func(_p: Vector2) -> bool: return true, parent)
	assert_bool(parent.has_node("PenAnimals")).is_false()
	var objects := parent.get_node_or_null("EarlyCommunalObjects")
	assert_object(objects).is_not_null()
	assert_bool(objects.has_node("Prop_pen_wattle")).is_false()
	assert_bool(objects.has_node("Prop_drying_rack")).is_false()
	# Tamed animals and food drying known: pens with a bounded few animals.
	GameState.discovery_log = [{"id":"animal_taming"}, {"id":"indirect_solar_food_drying"}]
	var tamed: Node3D = auto_free(Node3D.new())
	GROUND.render(plan, data.plots, data.routes, Vector3.ZERO, func(_x: float, _z: float) -> float: return 0.0, func(_p: Vector2) -> bool: return true, tamed)
	var animals := tamed.get_node_or_null("PenAnimals") as MultiMeshInstance3D
	assert_object(animals).is_not_null()
	assert_int(animals.multimesh.instance_count).is_less_equal(GROUND.MAX_PENS * GROUND.ANIMALS_PER_PEN)
	# No prop ever stands on water, or inside a building.
	var drowned: Node3D = auto_free(Node3D.new())
	GROUND.render(plan, data.plots, data.routes, Vector3.ZERO, func(_x: float, _z: float) -> float: return 0.0, func(_p: Vector2) -> bool: return false, drowned)
	assert_int(drowned.get_child_count()).is_equal(0)
	for batch in tamed.get_node("EarlyCommunalObjects").get_children():
		if not batch is MultiMeshInstance3D or String(batch.name).begins_with("PropShadow"): continue
		var mm: MultiMesh = (batch as MultiMeshInstance3D).multimesh
		for i in mm.instance_count:
			var at := mm.get_instance_transform(i).origin
			for record in plan.buildings:
				assert_float(Vector2(at.x, at.z).distance_to(Vector2(record.position))).is_greater(float(record.radius) * .99)

func test_later_town_fixture_places_its_houses_and_halls() -> void:
	var town: Dictionary = preload("res://tests/town_fixture.gd").build()
	var plots: Array[Dictionary] = []; plots.assign(town.plots)
	var routes: Array[Dictionary] = []; routes.assign(town.routes)
	assert_bool(EARLY.enabled(plots)).is_true()
	var plan := EARLY.layout(plots, routes, func(_p: Vector2) -> bool: return true)
	var housed := {}
	for record in plan.buildings: housed[int(record.plot_id)] = true
	var houses := 0; var placed := 0
	for plot in plots:
		if String(plot.land_use) in ["residential_compound", "mixed_household"]:
			houses += 1
			if housed.has(int(plot.id)): placed += 1
	assert_float(float(placed) / float(houses)).is_greater(.8)

func test_ticker_slip_fits_its_text_and_hides_when_empty() -> void:
	var label: Label = auto_free(Label.new())
	TICKER.style(label)
	label.text = "HEARTH-TALE: THE RIVER ROSE  •  Two homes were lost."
	TICKER.fit(label, 1600.0)
	assert_float(label.self_modulate.a).is_equal(1.0)
	assert_int(label.get_theme_font_size("font_size")).is_greater_equal(12)
	var wide := label.size.x
	assert_float(wide).is_between(200.0, 1600.0)
	assert_float(label.position.x + wide * .5).is_equal_approx(TICKER.HudT.RAIL_WIDTH + (1600.0 - TICKER.HudT.RAIL_WIDTH) * .5, 1.0)
	label.text = ""
	TICKER.fit(label, 1600.0)
	assert_float(label.self_modulate.a).is_equal(0.0)

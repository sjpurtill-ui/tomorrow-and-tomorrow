extends GdUnitTestSuite
## Map beauty round five (codex/beauty-5): the roads between places, the
## peoples' own towns, the held palisade line and the lived dwellings.
## Visual only: nothing here may change the simulation's records.
const ROADS := preload("res://scripts/settlement_roads.gd")
const FOREIGN := preload("res://scripts/foreign_settlement_visual.gd")
const SHAPES := preload("res://scripts/settlement_kit_shapes.gd")
const GROUNDS := preload("res://scripts/settlement_grounds.gd")

func before_test() -> void:
	GameState.reset_for_new_world(515151)
	GROUNDS.clear()

func _places(points: Array) -> Array:
	var out: Array = []
	for i in points.size(): out.append([points[i], 0.1, ("p:%d" % i) if i < 2 else ("f:%d" % i)])
	return out

func test_links_join_every_near_place_once_and_skip_the_far_ones() -> void:
	var places := _places([Vector2(0, 0), Vector2(10, 0), Vector2(10, 12), Vector2(-8, 3), Vector2(400, 400)])
	var links: Array = ROADS.links(places)
	var seen := {}
	for link in links:
		var key := ROADS._key(places[link[0]][2], places[link[1]][2])
		assert_bool(seen.has(key)).is_false()
		seen[key] = true
		# Never a road across hundreds of kilometres.
		assert_float((places[link[0]][0] as Vector2).distance_to(places[link[1]][0])).is_less_equal(ROADS.MAX_LINK_KM)
	# The four near places are joined by a spanning tree (three links).
	assert_int(links.size()).is_equal(3)
	assert_array(ROADS.links(_places([Vector2.ZERO]))).is_empty()

## The kind of road drawn (and the march pace on it) follows what is known;
## how well the builders keep them is the ink's quality alone
## (built_fabric.gd ink_quality), never a vanishing road.
func _lay_roads(index: float) -> void:
	GameState.fabric_realm = {"v": 1, "xp": 0.0, "decay_day": 0, "wall_builders": 0.0, "towns": {"home": {"day": 0, "pop": 100.0, "places": 100, "quality": 0.0, "roads": index, "beauty_points": 0.0, "beauty": 0.0, "cover": 0.0, "stone": 0.0}}}

func test_road_knowledge_follows_the_discovery_log() -> void:
	_lay_roads(0.0)
	assert_dict(ROADS.knowledge()).is_equal({"tier": 0, "bridge": 0})
	GameState.discovery_log.append({"id": "cart_running_gear"})
	assert_int(int(ROADS.knowledge().tier)).is_equal(1)
	GameState.discovery_log.append({"id": "timber_bridges"})
	GameState.discovery_log.append({"id": "graded_roads"})
	var know: Dictionary = ROADS.knowledge()
	assert_int(int(know.tier)).is_equal(2)
	assert_int(int(know.bridge)).is_equal(1)

func test_unkept_roads_keep_their_kind_and_only_the_ink_roughens() -> void:
	GameState.discovery_log.append({"id": "cart_running_gear"})
	GameState.discovery_log.append({"id": "graded_roads"})
	GameState.known_discoveries.append("graded_roads")
	_lay_roads(0.1)
	assert_int(int(ROADS.knowledge().tier)).is_equal(2)
	var FABRIC := preload("res://scripts/built_fabric.gd")
	assert_float(FABRIC.ink_quality(GameState)).is_equal_approx(0.1 / 0.7, 0.001)
	_lay_roads(0.7)
	assert_float(FABRIC.ink_quality(GameState)).is_equal_approx(1.0, 0.001)

func test_easing_keeps_the_ends_where_the_towns_are() -> void:
	var line := PackedVector2Array([Vector2(0, 0), Vector2(1, 1), Vector2(2, 0), Vector2(3, 1)])
	var eased: PackedVector2Array = ROADS._chaikin(line)
	assert_vector(eased[0]).is_equal(line[0])
	assert_vector(eased[eased.size() - 1]).is_equal(line[line.size() - 1])
	assert_int(eased.size()).is_greater(line.size())

func test_approaches_wear_a_track_out_of_the_home_ground_and_repaint_once() -> void:
	var plots: Array[Dictionary] = [{"id":1,"seed":7,"centroid":Vector2(0,0),"land_use":"communal","form":"maintained_gathering_ground","status":"active","area_ha":.01}]
	var routes: Array[Dictionary] = []
	var center := Vector3(10.0, 0.0, 20.0)
	GROUNDS.build({"buildings":[]}, plots, routes, center)
	var before := GROUNDS.signature
	GROUNDS.set_approaches({"a":{"center":Vector2(10.0, 20.0),"bearings":[0.4]}})
	assert_int(GROUNDS.signature).is_not_equal(before)
	var after := GROUNDS.signature
	GROUNDS.set_approaches({"a":{"center":Vector2(10.0, 20.0),"bearings":[0.4]}})
	assert_int(GROUNDS.signature).is_equal(after)
	# A cultivated halo is set for the home slot.
	assert_float(GROUNDS.slot_halos[0].x).is_greater(0.2)

func test_foreign_towns_are_organic_bounded_and_built_in_their_peoples_way() -> void:
	var styles := {}
	for i in 24:
		var report := {"city_id":"c%d" % i,"civ_id":"civ%d" % i,"position":{"x":float(i)*50.0,"z":0.0},"fields":{"population":{"low":400,"high":400}}}
		var visual: Node3D = auto_free(FOREIGN.new())
		visual.build(report, func(_x: float, _z: float) -> float: return 0.1)
		styles[visual.people_style] = true
		var count := 0
		var spots: Array[Vector2] = []
		for child in visual.get_children():
			if child is MultiMeshInstance3D and String(child.name).begins_with("ForeignHouses_"):
				count += child.multimesh.instance_count
				for transform: Transform3D in child.get_meta("source_transforms"):
					spots.append(Vector2(transform.origin.x, transform.origin.z))
		assert_int(count).is_equal(visual.building_count)
		assert_int(count).is_between(12, FOREIGN.MAX_BUILDINGS)
		# No two houses stand on each other.
		for a in spots.size():
			for b in range(a + 1, spots.size()):
				assert_float(spots[a].distance_to(spots[b])).is_greater(0.004)
	# Different peoples build differently.
	assert_int(styles.size()).is_greater(1)

func test_lived_dwellings_never_grow_past_their_envelope() -> void:
	for seed in 200:
		var basis: Basis = SHAPES.lived_basis(float(seed) * 0.3, seed)
		assert_float(basis.x.length()).is_less_equal(0.001)
		assert_float(basis.z.length()).is_less_equal(0.001)
		assert_float(basis.x.length()).is_greater(0.00083)
	for name in ["dugout", "coracle", "weir", "jetty", "quay"]:
		assert_object(SHAPES.prop(name)).is_not_null()

func test_palisade_line_is_held_across_the_pockets_and_never_moves_inward() -> void:
	var terrain: Node3D = auto_free(load("res://scripts/local_terrain.gd").new())
	# A cross-shaped town: long arms north, south, east and west, pockets between.
	var segments := 36
	var envelope := PackedFloat32Array()
	for k in segments:
		var angle := TAU * float(k) / float(segments)
		var arm := pow(absf(cos(2.0 * angle)), 6.0)
		envelope.append(0.08 + 0.10 * arm)
	var held: PackedFloat32Array = terrain._settlement_wall_hull(envelope, 0.0)
	assert_int(held.size()).is_equal(segments)
	var deepest_pocket := 1.0
	var deepest_held := 1.0
	for k in segments:
		assert_float(held[k]).is_greater_equal(envelope[k] - 0.000001)
		var neighbours := (envelope[(k + segments - 1) % segments] + envelope[(k + 1) % segments]) * 0.5
		deepest_pocket = minf(deepest_pocket, envelope[k] / maxf(neighbours, 0.0001))
		deepest_held = minf(deepest_held, held[k] / maxf((held[(k + segments - 1) % segments] + held[(k + 1) % segments]) * 0.5, 0.0001))
	# The pockets between the arms are mostly filled.
	var pocket := held[segments / 8]
	assert_float(pocket).is_greater(envelope[segments / 8] + 0.03)
	assert_float(deepest_held).is_greater(deepest_pocket)

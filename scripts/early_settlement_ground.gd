extends RefCounted
## Human-scale working ground attached to recorded buildings and service parcels.
## Geometry is in kilometres; no population, research or cultural style switches
## of the recorded buildings themselves.
##
## (codex/beauty-3) The worn ground itself (paths, door yards, the hearth
## ground, worked fields and kitchen gardens) is painted into the land by
## settlement_grounds.gd. This file places the furniture of daily life on it,
## as instanced low-poly props in the settlement ink (settlement_kit_shapes.gd):
## Household wood, pottery, racks, grain and nets are owned by the global
## close-view settlement_yard_details layer. They are never duplicated here.
## - at the hearth: the fire ring and log benches round it, and a woodpile;
## - at work yards: a kiln, pots, a loom or a hide frame, by what is known;
## - at the water point: a well once wells are known, water jars before;
## - a midden at the refuse ground; a rising frame and stacked timber where a
##   building is going up;
## - pens with a few animals once animals are tamed (bounded).
## Every prop respects the land (never in water) and the buildings' footprints.
const EARLY := preload("res://scripts/early_settlement_visual.gd")
const SHAPES := preload("res://scripts/settlement_kit_shapes.gd")
const GROUNDS := preload("res://scripts/settlement_grounds.gd")
const SERVICE_FORMS := ["open_hearth_yard", "guarded_cache", "lined_storage_pits", "open_work_yard", "carried_water_point", "refuse_and_latrine_ground", "maintained_gathering_ground"]
const HEARTH_FORMS := ["open_hearth_yard", "maintained_gathering_ground"]
const WORK_FORMS := ["open_work_yard", "covered_work_yard", "sheltered_work_area", "timber_work_shelter", "household_craft_yard"]
const MAX_PROPS := 400
const MAX_PENS := 2
const ANIMALS_PER_PEN := 5
const UNIT := 0.001

static var _pen_material: ShaderMaterial

static func handles(plot: Dictionary) -> bool:
	return EARLY.supports(plot) or String(plot.get("form", "")) in SERVICE_FORMS or String(plot.get("land_use", "")) == "field"

## What the people know that shows on the ground (from the discovery log).
static func known_crafts() -> Dictionary:
	var ids: Dictionary = {}
	for entry in GameState.discovery_log:
		if entry is Dictionary: ids[String(entry.get("id", ""))] = true
	for id in GameState.known_discoveries: ids[String(id)] = true
	var any := func(list: Array) -> bool:
		for id in list:
			if ids.has(id): return true
		return false
	return {
		"drying": any.call(["indirect_solar_food_drying", "smoking", "fish_drying", "meat_drying", "food_drying"]),
		"hides": any.call(["hide_tanning", "hide_smoke_curing", "hide_scraping"]),
		"pottery": any.call(["painted_pottery", "clay_shaping", "pottery", "coiled_pottery"]),
		"kiln": any.call(["kiln_control", "kiln_firing"]),
		"weaving": any.call(["plain_weaving", "horizontal_ground_loom", "warp_weighted_looms"]),
		"well": any.call(["well_siting", "lined_well_shafts"]),
		"tamed": any.call(["animal_taming", "herding_rotas", "herd_size_limits"]),
		"herding": any.call(["herding_rotas", "herd_size_limits"]),
		"stone_walls": any.call(["dry_stone_walls"]),
		"grinding": any.call(["flour_sifting", "grain_grinding", "saddle_quern", "mixed_grain_legume_meals"]),
		"weirs": any.call(["fish_weirs_and_traps", "weir_fish_gaps", "fish_run_weir_opening", "licensed_estuary_weirs"]),
		"landing": any.call(["river_landings", "plank_extended_dugouts", "stone_quays", "stone_jetty_harbors"]),
		"quay": any.call(["stone_quays", "stone_jetty_harbors"]),
		"hide_boats": any.call(["hide_covered_boats", "reed_bundle_boats"]),
		"carts": any.call(["solid_wheel_assembly", "spoked_wheel_assembly", "cart_running_gear", "cart_bed_framing", "transport_cart", "sleeved_cart_assembly", "wheel"]),
	}

static func render(plan: Dictionary, plots: Array[Dictionary], routes: Array[Dictionary], center: Vector3, height: Callable, land: Callable, parent: Node3D, paint_ground:=true) -> void:
	# The worn ground of the home settlement (painted into the terrain).
	if paint_ground:GROUNDS.build_if_home(plan, plots, routes, center)
	var crafts := known_crafts()
	var placed: Dictionary = {}   # prop name -> Array[Transform3D]
	var blocked: Array[Vector3] = [] # x, z, radius (km) of every footprint and prop
	for record in plan.buildings:
		var position: Vector2 = record.position
		blocked.append(Vector3(position.x, position.y, maxf(float(record.get("radius", .003)), .0018)))
	var total := [0]
	var put := func(name: String, at: Vector2, yaw: float, radius: float) -> bool:
		if name in ["woodpile","pots","drying_rack","stored_grain","fishing_net"]:return false
		if total[0] >= MAX_PROPS: return false
		if not bool(land.call(at)): return false
		for other in blocked:
			if Vector2(other.x, other.y).distance_to(at) < other.z + radius * 0.8: return false
		blocked.append(Vector3(at.x, at.y, radius))
		var world := at + Vector2(center.x, center.z)
		var basis := Basis(Vector3.UP, yaw).scaled(Vector3.ONE * UNIT)
		if not placed.has(name): placed[name] = []
		placed[name].append(Transform3D(basis, Vector3(world.x, float(height.call(world.x, world.y)) + .00002, world.y)))
		total[0] += 1
		return true
	# Household furniture belongs to the one near-camera yard budget. Public
	# service furniture and construction equipment stay in this existing layer.
	for record in plan.buildings:
		var plot: Dictionary = record.plot
		var status := String(plot.get("status", "active"))
		var use := String(plot.get("land_use", ""))
		var position: Vector2 = record.position
		var angle := float(record.angle)
		var forward := Vector2(sin(angle), cos(angle))
		var side := forward.orthogonal()
		var radius := maxf(float(record.get("radius", .003)), .0018)
		var roll := absi(int(plot.get("seed", 1)) + int(record.get("id", 0)) * 13) % 12
		if status == "under_construction":
			# The building's own footprint is free while it goes up.
			for i in range(blocked.size() - 1, -1, -1):
				if Vector2(blocked[i].x, blocked[i].y) == position: blocked.remove_at(i)
			put.call("frame", position, angle, radius * .5)
			put.call("timber_stack", position + side * (radius + .003), angle + PI * .5, .002)
			continue
		if status in ["vacant", "ruin", "reclaimed"]: continue
		if use in ["residential_compound", "mixed_household"]:
			continue
		elif use == "workshop":
			if crafts.kiln and roll % 2 == 0: put.call("kiln", position + side * (radius + .0022), angle, .0014)
			if crafts.pottery: put.call("pots", position + forward * (radius + .0012), angle, .0007)
			if crafts.weaving and roll % 3 == 0: put.call("loom", position - side * (radius + .0015), angle + PI * .5, .0011)
			if crafts.hides and roll % 4 == 1: put.call("hide_frame", position - forward * (radius + .0017), angle, .0011)
			if roll % 2 == 1: put.call("woodpile", position + side * (radius + .0014), angle, .0011)
	# Service grounds.
	var hearth := Vector2.INF
	for plot in plots:
		var form := String(plot.get("form", ""))
		var status := String(plot.get("status", "active"))
		if form not in SERVICE_FORMS and form not in WORK_FORMS: continue
		var c: Vector2 = plot.get("centroid", Vector2.ZERO)
		var angle := float(absi(int(plot.get("seed", 1))) % 628) * .01
		if form in HEARTH_FORMS:
			if hearth == Vector2.INF: hearth = c
			if status in ["vacant", "reclaimed"]: continue
			# The living map lights its own fire ring at the settlement's
			# heart (living_map.gd); a second hearth gets its own stones.
			if c.length() > .005: put.call("hearth_ring", c, angle, .0012)
			else: blocked.append(Vector3(c.x, c.y, .0022))
			for k in 4:
				var a := angle + TAU * float(k) / 4.0 + .35
				put.call("bench", c + Vector2.from_angle(a) * .0034, -a, .0012)
			put.call("woodpile", c + Vector2.from_angle(angle + 2.3) * .0062, angle, .0011)
		if status in ["vacant", "ruin", "reclaimed", "under_construction"]: continue
		if form == "carried_water_point":
			if crafts.well: put.call("well", c, angle, .0012)
			else: put.call("water_jars", c, angle, .0008)
		elif form == "refuse_and_latrine_ground":
			put.call("midden", c, angle, .0017)
		elif form in WORK_FORMS:
			if crafts.kiln: put.call("kiln", c + Vector2.from_angle(angle) * .005, angle, .0014)
			if crafts.weaving: put.call("loom", c - Vector2.from_angle(angle) * .005, angle, .0011)
		elif form in ["guarded_cache", "lined_storage_pits"]:
			put.call("pots", c, angle, .0008)
	# Market days (codex/beauty-4): stalls round the market ground and along
	# the plaza, their awnings turned to the trade; baskets between them.
	var market_count := 0
	for plot in plots:
		if String(plot.get("land_use", "")) != "market" or String(plot.get("status", "active")) in ["vacant", "ruin", "reclaimed", "under_construction"]: continue
		var c: Vector2 = plot.get("centroid", Vector2.ZERO)
		var base := float(absi(int(plot.get("seed", 1))) % 628) * .01
		var ring := clampf(sqrt(maxf(float(plot.get("area_ha", .05)), .005) / 100.0 / PI) * 1.05, .007, .016)
		for k in 7:
			var a := base + TAU * float(k) / 7.0
			var at := c + Vector2.from_angle(a) * ring
			if put.call("stall", at, atan2(-(c - at).x, -(c - at).y) + PI, .0016): market_count += 1
			if k % 2 == 0: put.call("baskets", c + Vector2.from_angle(a + .45) * ring * .82, a, .0007)
	if market_count > 0 and hearth != Vector2.INF:
		for k in 5:
			var a := float(k) * 1.2566 + .3
			var at := hearth + Vector2.from_angle(a) * .0105
			put.call("stall", at, atan2(-(hearth - at).x, -(hearth - at).y) + PI, .0016)
	# Carts stand by the stores and workshops on made streets, once the
	# people build them.
	if crafts.carts:
		var carts := 0
		for record in plan.buildings:
			if carts >= 6: break
			var plot: Dictionary = record.plot
			if String(plot.get("land_use", "")) not in ["storage", "workshop", "market"]: continue
			var forward := Vector2(sin(float(record.angle)), cos(float(record.angle)))
			var at: Vector2 = Vector2(record.position) + forward * (maxf(float(record.get("radius", .003)), .0018) + .0028) + forward.orthogonal() * .0022
			if put.call("cart", at, float(record.angle) + PI * .5 + float(carts % 3) * .3, .0015): carts += 1
	for plot in plots:
		if String(plot.get("form", "")) == "refuse_and_latrine_ground" and String(plot.get("status", "")) == "ruin":
			put.call("midden", plot.get("centroid", Vector2.ZERO), 0.4, .0017)
	# Pens with animals, on open ground at the settlement's edge.
	var pens: Array[Vector2] = []
	if crafts.tamed and not plan.buildings.is_empty():
		var home := hearth if hearth != Vector2.INF else Vector2.ZERO
		var reach := 0.0
		for record in plan.buildings: reach = maxf(reach, Vector2(record.position).distance_to(home))
		reach = minf(reach, .12)
		var wanted := mini(2 if crafts.herding else 1, MAX_PENS)
		var route_points: Array[PackedVector2Array] = []
		for route in routes: route_points.append(GROUNDS._points(route))
		for step in 32:
			if pens.size() >= wanted: break
			var a := float(step) * 2.39996 + .7
			var at := home + Vector2.from_angle(a) * (reach * .8 + .012 + float(step / 8) * .006)
			var on_route := false
			for points in route_points:
				for i in range(1, points.size()):
					if Geometry2D.get_closest_point_to_segment(at, points[i - 1], points[i]).distance_to(at) < .0065: on_route = true
			if on_route: continue
			if put.call("pen_stone" if crafts.stone_walls else "pen_wattle", at, a + PI * .5, .0052):
				pens.append(at)
	_commit_props(placed, parent)
	if not pens.is_empty(): _add_animals(pens, center, height, parent)

static func _commit_props(placed: Dictionary, parent: Node3D) -> void:
	if placed.is_empty(): return
	var material := preload("res://scripts/settlement_ink.gd").material()
	var root := Node3D.new(); root.name = "EarlyCommunalObjects"
	parent.add_child(root)
	for name in placed:
		var mesh := SHAPES.prop(String(name))
		if mesh == null: continue
		var transforms: Array[Transform3D] = []
		transforms.assign(placed[name])
		var batch := MultiMesh.new(); batch.transform_format = MultiMesh.TRANSFORM_3D
		batch.use_colors = true; batch.mesh = mesh; batch.instance_count = transforms.size()
		for i in transforms.size():
			batch.set_instance_transform(i, transforms[i]); batch.set_instance_color(i, Color.WHITE)
		var node := MultiMeshInstance3D.new(); node.name = "Prop_" + String(name)
		node.multimesh = batch; node.material_override = material
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(node)
		if String(name) not in ["hearth_ring", "midden"]:
			preload("res://scripts/settlement_ink.gd").add_ground_shadows(root, "PropShadow_" + String(name), transforms, mesh.get_aabb())

## A few animals in each pen, drawn in ink (map_life_ink.gd's beasts). The
## instance is scaled down so the beasts' walk stays inside the fence; their
## drawn size does not depend on it.
static func _add_animals(pens: Array[Vector2], center: Vector3, height: Callable, parent: Node3D) -> void:
	var batch := MultiMesh.new(); batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_colors = true; batch.use_custom_data = true
	batch.mesh = preload("res://scripts/map_life_ink.gd").quad()
	batch.instance_count = pens.size() * ANIMALS_PER_PEN
	var rng := RandomNumberGenerator.new(); rng.seed = hash(pens)
	var coats := [Color(0.80, 0.75, 0.62), Color(0.46, 0.34, 0.23), Color(0.30, 0.25, 0.20), Color(0.70, 0.62, 0.48)]
	var index := 0
	for pen in pens:
		for k in ANIMALS_PER_PEN:
			var at := pen + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(0.0, .0012)
			var world := at + Vector2(center.x, center.z)
			var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * .42)
			batch.set_instance_transform(index, Transform3D(basis, Vector3(world.x, float(height.call(world.x, world.y)), world.y)))
			batch.set_instance_custom_data(index, Color(rng.randf(), rng.randf(), 0, 0))
			batch.set_instance_color(index, coats[rng.randi_range(0, coats.size() - 1)])
			index += 1
	var node := MultiMeshInstance3D.new(); node.name = "PenAnimals"
	node.multimesh = batch; node.material_override = pen_material()
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The shader draws each beast away from its instance point: cull by the pens.
	var bounds := AABB(Vector3(pens[0].x + center.x, center.y - .05, pens[0].y + center.z), Vector3.ZERO)
	for pen in pens: bounds = bounds.expand(Vector3(pen.x + center.x, center.y, pen.y + center.z))
	node.custom_aabb = bounds.grow(.02)
	parent.add_child(node)

## The penned animals' own ink material; its clock runs with the fire
## (settlement_ink.set_clock).
static func pen_material() -> ShaderMaterial:
	if _pen_material and is_instance_valid(_pen_material): return _pen_material
	_pen_material = (preload("res://scripts/map_life_ink.gd").material("beast").duplicate() as ShaderMaterial)
	_pen_material.set_shader_parameter("min_px", 12.0)
	_pen_material.set_shader_parameter("max_swell", 2.5)
	preload("res://scripts/settlement_ink.gd").keep_time(_pen_material)
	return _pen_material

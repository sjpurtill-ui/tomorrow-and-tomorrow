extends RefCounted
## A bounded visual interpretation of recorded plots; never a population authority.
## All dimensions here are kilometres. GLB geometry is in metres.
const MAX_BUILDINGS := 512
const MAX_PLOTS := 512
const MAX_POPULATION := 5000
const KIT := ["house_narrow", "house_compact", "house_medium", "house_wide", "market_hall", "house_small"]
static var meshes: Dictionary = {}
static var material: Material

static func supports(plot: Dictionary) -> bool:
	return String(plot.get("land_use", "")) in ["residential_compound", "mixed_household", "market"] \
		and String(plot.get("roof_plan", "")) in ["timber_ridge", "tapered_thatch", "long_thatch"] \
		and String(plot.get("material_family", "")) in ["organic", "timber"] \
		and int(plot.get("storeys", 1)) == 1 \
		and String(plot.get("form", "")) not in ["portable_shelter_cluster", "light_shelter_cluster", "emergency_open_encampment"]

static func has_inherited_kit(plots: Array[Dictionary]) -> bool:
	for plot in plots:
		if int(plot.get("id", 0)) <= MAX_PLOTS and supports(plot): return true
	return false

static func enabled(plots: Array[Dictionary], population: int) -> bool:
	if population > MAX_POPULATION or plots.size() > MAX_PLOTS: return false
	return has_inherited_kit(plots)

static func route_half_width(route: Dictionary) -> float:
	var kind := String(route.get("kind", "desire_path"))
	var hierarchy := String(route.get("hierarchy", "path"))
	var minimum := 0.00034 if kind == "field_track" else (0.00014 if kind == "camp_path" else 0.00058)
	if hierarchy == "farm_lane": minimum = 0.00058
	elif hierarchy == "lane": minimum = 0.00082
	elif hierarchy == "main_approach": minimum = 0.00128
	var width := maxf(minimum, float(route.get("width_m", 1.2)) * 0.0005)
	# Paving changes the surface, not a recorded lane's physical width. The
	# old surface-tier multiplier turned 0.72 m field tracks into 6.4 m roads,
	# also reserving that invented width against neighboring house placement.
	return width

static func bounds(polygon: PackedVector2Array) -> Rect2:
	var rect := Rect2(polygon[0], Vector2.ZERO)
	for point in polygon: rect = rect.expand(point)
	return rect

static func layout(plots: Array[Dictionary], routes: Array[Dictionary], land: Callable, changed_plots:Dictionary={}) -> Dictionary:
	var records: Array[Dictionary] = []
	var replaced: Dictionary = {}
	var ordered := plots.duplicate()
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.id) < int(b.id))
	var segments: Array[Dictionary] = []
	var road_envelopes: Array[PackedVector2Array] = []
	for route in routes:
		if not bool(route.get("active", true)): continue
		var points: PackedVector2Array = route.get("points", PackedVector2Array())
		road_envelopes.append_array(Geometry2D.offset_polyline(points, route_half_width(route) * 1.02))
		for index in range(1, points.size()):
			if points[index].distance_to(points[index - 1]) < 0.0001: continue
			road_envelopes.append_array(Geometry2D.offset_polyline(PackedVector2Array([points[index - 1], points[index]]), route_half_width(route) * 1.02))
			segments.append({"a": points[index - 1], "b": points[index], "width": route_half_width(route), "id": int(route.id)})
	var obstacles: Array[Dictionary] = []
	for plot in ordered:
		var polygon: PackedVector2Array = plot.get("polygon", PackedVector2Array())
		if not supports(plot) and polygon.size() >= 3 and String(plot.get("land_use", "")) not in ["field", "pasture", "water", "waste", "vacant"]:
			obstacles.append({"polygon": polygon, "bounds": bounds(polygon)})
	var road_bounds: Array[Rect2] = []
	for road in road_envelopes: road_bounds.append(bounds(road))
	# Reserve saved physical buildings before attempting any new sites. Growth,
	# road maintenance and changes in occupancy cannot relocate an existing home.
	for plot in ordered:
		if not supports(plot) or int(plot.get("id",0))>MAX_PLOTS:continue
		if String(plot.get("visual_sites_form",""))!=String(plot.get("visual_form",plot.get("form",""))):continue
		for site:Dictionary in plot.get("visual_building_sites",[]):
			if records.size()>=MAX_BUILDINGS:break
			var retained:=site.duplicate(true);retained["plot"]=plot
			records.append(retained);replaced[int(plot.id)]=true
	for plot in ordered:
		if int(plot.get("id", 0)) > MAX_PLOTS or not supports(plot): continue
		# An unchanged parcel has already exhausted its deterministic site search.
		# Reserve its saved sites above, but never retry hundreds of failed infill
		# positions merely because another quarter acquired a new household.
		if not changed_plots.is_empty() and not changed_plots.has(int(plot.id)):continue
		var polygon: PackedVector2Array = plot.get("polygon", PackedVector2Array())
		if polygon.size() < 3: continue
		# Reserve each plot's sites even while ruined/constructing, so a neighbour
		# cannot move into them on the next camera or condition refresh.
		var frontage: Array[Dictionary] = []
		for segment in segments:
			if int(segment.id) == int(plot.get("frontage_route_id", -1)): frontage.append(segment)
		if frontage.is_empty(): continue # No invented street or historical orientation.
		var compact_extent: Vector2 = plot.get("placement_half_extent", Vector2.ZERO)
		var roof_area := maxf(8.0,compact_extent.x*compact_extent.y*4000000.0) if compact_extent != Vector2.ZERO else 24.0
		var target := clampi(floori(float(plot.get("area_ha", 0.0)) * 10000.0 * float(plot.get("roof_coverage", 0.3)) / roof_area), 1, 8)
		if String(plot.land_use) == "market": target = 1
		var rng := RandomNumberGenerator.new()
		rng.seed = int(plot.get("seed", plot.id))
		var accepted := 0
		for retained in records:
			if int(retained.plot_id)==int(plot.id):accepted+=1
		for attempt in (1216 if compact_extent != Vector2.ZERO else 192):
			if accepted >= target or records.size() >= MAX_BUILDINGS: break
			var variant := 4 if String(plot.land_use) == "market" else (5 if attempt >= 96 else (absi(int(plot.get("seed", 1))) + attempt) % 4)
			# Circumscribed roof envelope, including overhang and front porch.
			var dimensions: Vector2 = [Vector2(2.343, 4.196), Vector2(2.679, 3.704), Vector2(2.996, 3.361), Vector2(3.380, 3.044), Vector2(5.940, 6.975), Vector2(2.119, 2.377)][variant] * 0.001 + Vector2.ONE * 0.0003
			# Compact shelters use their authored envelope rather than the larger
			# timber-house reservation, leaving usable shared space between doors.
			if compact_extent != Vector2.ZERO: dimensions = compact_extent + Vector2.ONE * .0003
			var radius := dimensions.length()
			var segment: Dictionary = frontage[attempt % frontage.size()]
			var along: Vector2 = (segment.b - segment.a).normalized()
			var normal := Vector2(-along.y, along.x) * (1.0 if attempt % 2 == 0 else -1.0)
			var position: Vector2 = segment.a.lerp(segment.b, rng.randf_range(0.04, 0.96)) + normal * (dimensions.y + 0.0008 + rng.randf_range(0.0003, 0.0012))
			if attempt % 2 == 1:
				# Irregular short-lane heads may have useful frontage between the
				# side and end positions. Fit within the recorded parcel, facing
				# the closest point of its lane; never add random roof rotation.
				var parcel_bounds := bounds(polygon)
				position = parcel_bounds.position + parcel_bounds.size * Vector2(rng.randf(), rng.randf())
				var nearest := Vector2.ZERO
				var nearest_distance := INF
				for lane in frontage:
					var point := Geometry2D.get_closest_point_to_segment(position, lane.a, lane.b)
					if point.distance_squared_to(position) < nearest_distance:
						nearest_distance = point.distance_squared_to(position)
						nearest = point
				if nearest_distance < 0.00000001: continue
				normal = (position - nearest).normalized()
				along = Vector2(-normal.y, normal.x)
			if compact_extent != Vector2.ZERO and attempt < 48:
				# Households share a small court at their inherited path head. Doors
				# face this common space; later infill uses the same reserved pattern.
				var court: Vector2 = plot.get("centroid", bounds(polygon).get_center())
				var heading := float(absi(int(plot.get("seed",1))) % 6283) * .001
				var slot := attempt % 6
				var ring := attempt / 6
				normal = Vector2.from_angle(heading + float(slot)*TAU/6)
				along = Vector2(-normal.y, normal.x)
				position = court + normal * (.0045 + float(ring)*.00055)
			var footprint := PackedVector2Array()
			for corner in [Vector2(-1,-1), Vector2(1,-1), Vector2(1,1), Vector2(-1,1)]:
				footprint.append(position + along * corner.x * dimensions.x + normal * corner.y * dimensions.y)
			if not Geometry2D.clip_polygons(footprint, polygon).is_empty(): continue
			var footprint_bounds := bounds(footprint)
			var clear := true
			for road_index in road_envelopes.size():
				if not footprint_bounds.intersects(road_bounds[road_index]): continue
				if not Geometry2D.intersect_polygons(footprint, road_envelopes[road_index]).is_empty():
					clear = false
					break
			if not clear: continue
			for obstacle in obstacles:
				if footprint_bounds.intersects(obstacle.bounds) and not Geometry2D.intersect_polygons(footprint, obstacle.polygon).is_empty():
					clear = false
					break
			if not clear: continue
			for previous in records:
				if not footprint_bounds.intersects(previous.bounds): continue
				if not Geometry2D.intersect_polygons(footprint, previous.footprint).is_empty():
					clear = false
					break
			if not clear: continue
			for sample in 9:
				var point := position
				if sample < 4: point = footprint[sample]
				elif sample < 8: point = footprint[sample - 4].lerp(footprint[(sample - 3) % 4], 0.5)
				if not bool(land.call(point)):
					clear = false
					break
			if not clear: continue
			var forward := -normal
			records.append({"id": "%d:%d" % [int(plot.id), attempt], "plot_id": int(plot.id), "position": position, "radius": radius, "footprint": footprint, "bounds": footprint_bounds, "angle": atan2(forward.x, forward.y), "variant": variant, "plot": plot})
			accepted += 1
		if accepted > 0: replaced[int(plot.id)] = true
	for record in records:
		if int(record.variant) == 4: continue
		var forward := Vector2(sin(float(record.angle)), cos(float(record.angle)))
		var side := Vector2(forward.y, -forward.x)
		var rear := Vector2(record.position) - forward * (float(record.radius) + 0.0013)
		var patch := PackedVector2Array([rear-side*0.0015-forward*0.0012, rear+side*0.0015-forward*0.0012, rear+side*0.0015+forward*0.0012, rear-side*0.0015+forward*0.0012])
		if not Geometry2D.clip_polygons(patch, record.plot.polygon).is_empty(): continue
		var clear := true
		var patch_bounds := bounds(patch)
		for other in records:
			if patch_bounds.intersects(other.bounds) and not Geometry2D.intersect_polygons(patch, other.footprint).is_empty(): clear = false
		for road_index in road_envelopes.size():
			if patch_bounds.intersects(road_bounds[road_index]) and not Geometry2D.intersect_polygons(patch, road_envelopes[road_index]).is_empty(): clear = false
		for point in patch:
			if not bool(land.call(point)): clear = false
		if clear: record["garden"] = patch
	return {"buildings": records, "replaced": replaced}

static func kit_mesh(index: int) -> Mesh:
	if meshes.has(index): return meshes[index]
	var imported := _imported_mesh(index)
	# Thatched timber houses coded in settlement_kit_shapes.gd, fitted to the
	# authored envelope (placement unchanged); the market hall stays authored.
	var coded: Mesh = preload("res://scripts/settlement_kit_shapes.gd").mesh(KIT[index], imported.get_aabb())
	meshes[index] = coded if coded != null else imported
	return meshes[index]

static var imported_meshes: Dictionary = {}

static func _imported_mesh(index: int) -> Mesh:
	if imported_meshes.has(index): return imported_meshes[index]
	var scene: PackedScene = load("res://assets/buildings/organic_town/%s.glb" % KIT[index])
	var root := scene.instantiate()
	var source: MeshInstance3D = root.find_children("*", "MeshInstance3D", true, false)[0]
	# Exported nodes carry no scale/rotation; bake transforms so this remains true
	# if the exporter later changes its hierarchy.
	var transform := source.transform
	var ancestor := source.get_parent()
	while ancestor is Node3D:
		transform = ancestor.transform * transform
		ancestor = ancestor.get_parent()
	if transform.is_equal_approx(Transform3D.IDENTITY):
		# Preserve importer-generated LOD index buffers and shadow meshes. These
		# simplify the SAME roof/framing geometry as its projected size decreases.
		imported_meshes[index] = source.mesh
	else:
		var surface := SurfaceTool.new()
		for part in source.mesh.get_surface_count(): surface.append_from(source.mesh, part, transform)
		imported_meshes[index] = surface.commit()

	root.free()
	return imported_meshes[index]

static func render(plan: Dictionary, center: Vector3, height: Callable, parent: Node3D) -> void:
	if material == null:
		# Painted in the map's ink (scripts/settlement_ink.gd), vertex colours kept.
		material = preload("res://scripts/settlement_ink.gd").material()
	_render_gardens(plan, center, height, parent)
	for variant in KIT.size():
		var visible: Array[Dictionary] = []
		for record in plan.buildings:
			if int(record.variant) != variant: continue
			var plot: Dictionary = record.plot
			if String(plot.get("status", "active")) in ["ruin", "reclaimed"]: continue
			if String(plot.get("status", "")) == "under_construction": continue
			if float(plot.get("damage", {}).get("structural", 0.0)) > 0.65: continue
			visible.append(record)
		if visible.is_empty(): continue
		var batch := MultiMesh.new()
		batch.transform_format = MultiMesh.TRANSFORM_3D
		batch.use_colors = true
		batch.use_custom_data = true
		batch.mesh = kit_mesh(variant)
		batch.instance_count = visible.size()
		var transforms: Array[Transform3D] = []
		for index in visible.size():
			var record := visible[index]
			var point: Vector2 = record.position + Vector2(center.x, center.z)
			var base: float = height.call(point.x, point.y)
			# Each house a little its own size and lean (settlement_kit_shapes.gd).
			var transform := Transform3D(preload("res://scripts/settlement_kit_shapes.gd").lived_basis(float(record.angle), hash(Vector2(record.position))), Vector3(point.x, base + 0.0004, point.y))
			transforms.append(transform)
			batch.set_instance_transform(index, transform)
			var plot: Dictionary = record.plot
			var wear := 1.0 - clampf(float(plot.get("condition", 1.0)), 0.0, 1.0)
			var fire := clampf(float(plot.get("damage", {}).get("fire", 0.0)), 0.0, 1.0)
			# Weathering greys the straw and daub; only fire blackens (codex/beauty-5).
			batch.set_instance_color(index, Color.WHITE.lerp(Color(0.70, 0.66, 0.60), wear * 0.35).lerp(Color(0.30, 0.27, 0.23), fire))
		var node := MultiMeshInstance3D.new()
		node.name = "OrganicTown_%s" % KIT[variant]
		node.set_meta("source_transforms", transforms)
		node.set_meta("cultural_codes",preload("res://scripts/settlement_ink.gd").apply_culture(batch,visible))
		node.multimesh = batch
		node.material_override = material
		parent.add_child(node)
		# Soft shadows where each building stands (settlement_ink.gd).
		preload("res://scripts/settlement_ink.gd").add_ground_shadows(parent, "GroundShadow_%s" % KIT[variant], transforms, kit_mesh(variant).get_aabb())

static func _render_gardens(plan: Dictionary, center: Vector3, height: Callable, parent: Node3D) -> void:
	# Visual household land use only; these beds grant no production or workers.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := 0
	for record in plan.buildings:
		if not record.has("garden") or String(record.plot.get("status", "active")) not in ["active", "stressed", "damaged"]: continue
		if float(record.plot.get("damage", {}).get("structural", 0.0)) > 0.65: continue
		var garden: PackedVector2Array = record.garden
		# Tilled beds (codex/beauty-5): rows of crop between strips of warm dug
		# loam, each bed a little further on than the next; never a dark slab.
		var rows := 9
		var bed_seed := absi(hash(Vector2(record.position)))
		for row in rows:
			var start := float(row) / float(rows)
			var end := float(row + 1) / float(rows)
			var corners := PackedVector2Array([garden[0].lerp(garden[1], start), garden[0].lerp(garden[1], end), garden[3].lerp(garden[2], end), garden[3].lerp(garden[2], start)])
			var grown := float((bed_seed >> (row % 12)) % 7) / 6.0
			var color := Color("#8e9a52").lerp(Color("#a9a45c"), grown * 0.6) if row % 2 == 0 else Color("#9c7d58").lerp(Color("#8a6c4a"), grown * 0.5)
			color = color.lerp(Color("#8a7c62"), 1.0 - clampf(float(record.plot.get("condition", 1.0)), 0.0, 1.0))
			for index in [0,2,1,0,3,2]:
				var point := corners[index] + Vector2(center.x, center.z)
				surface.set_color(color)
				surface.add_vertex(Vector3(point.x, float(height.call(point.x, point.y)) + 0.00035, point.y))
		count += 1
	if count == 0: return
	surface.generate_normals()
	var node := MeshInstance3D.new()
	node.name = "OrganicHouseholdGardens"
	node.mesh = surface.commit()
	# Painted like the houses but with no drawn silhouette: a bed is ground.
	node.material_override = preload("res://scripts/settlement_ink.gd").ground_material()
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)

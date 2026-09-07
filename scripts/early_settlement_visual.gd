extends RefCounted
## Built-form adapter: observes completed plot records, never unlocks construction.
## No population, calendar, stockpile, or research lookup can restyle an old house.
const TOWN := preload("res://scripts/organic_town_visual.gd")
const KIT := ["carried_ridge", "carried_round", "rooted_lean_to", "round_household", "earthen_household", "rubble_household", "raised_store", "covered_workshop"]
static var meshes: Dictionary = {}
static var material: StandardMaterial3D

static func kind(plot: Dictionary) -> String:
	if int(plot.get("storeys",1)) != 1: return ""
	var form := String(plot.get("form",""))
	var use := String(plot.get("land_use",""))
	var family := String(plot.get("material_family",""))
	var roof := String(plot.get("roof_plan",""))
	if use in ["residential_compound","mixed_household","temporary_encampment"]:
		if form in ["portable_shelter_cluster","light_shelter_cluster","emergency_open_encampment"]:
			return "carried_round" if roof == "round_light_shelter" else "carried_ridge"
		if form == "lean_to_household_cluster": return "rooted_lean_to"
		if family == "earth" and form != "": return "earthen_household"
		if family == "stone" and form != "": return "rubble_household"
		if family in ["organic","timber"] and form != "":
			if roof in ["round_thatch","round_light_shelter"]: return "round_household"
			# Early conversion records retain their founding roof designation. The
			# recorded completed form takes precedence over that historical label.
			if roof in ["ridge_light_shelter","tapered_light_shelter"]: return "timber_household"
	if use == "workshop" and form in ["sheltered_work_area","timber_work_shelter","covered_work_yard","household_craft_yard","specialist_craft_cluster","route_side_workshop","workshop_frontage"]:
		if family in ["organic","timber"]: return "covered_workshop"
	if use == "storage" and form in ["raised_timber_store","protected_household_store","communal_store","granary_compound"]:
		if family in ["organic","timber"]: return "raised_store"
	return ""

static func supports(plot: Dictionary) -> bool:
	return not kind(plot).is_empty() or TOWN.supports(plot)

static func enabled(plots: Array[Dictionary]) -> bool:
	# Representation budget, not a population/era style gate. Larger fabrics keep
	# their inherited kit; additional unsupported plots retain the legacy renderer.
	if plots.size() > TOWN.MAX_PLOTS: return false
	for plot in plots:
		if int(plot.get("id",0)) <= TOWN.MAX_PLOTS and supports(plot): return true
	return false

static func has_kit(plots: Array[Dictionary]) -> bool:
	for plot in plots:
		if int(plot.get("id",0)) <= TOWN.MAX_PLOTS and supports(plot): return true
	return false

static func layout(plots: Array[Dictionary], routes: Array[Dictionary], land: Callable) -> Dictionary:
	var proxies: Array[Dictionary] = plots.duplicate(true)
	var originals: Dictionary = {}
	for plot in plots: originals[int(plot.id)] = plot
	for plot in proxies:
		if kind(plot).is_empty(): continue
		# Reuse the checked footprint/road/water solver, retaining plot identity and
		# reserved future household sites. This is a display copy, not a conversion.
		plot.material_family = "organic"; plot.roof_plan = "timber_ridge"
		plot.form = "timber_household"; plot.land_use = "residential_compound"
	var plan := TOWN.layout(proxies,routes,land)
	for record in plan.buildings:
		var original: Dictionary = originals[int(record.plot_id)]
		record.plot = original.duplicate(true)
		record["early_kind"] = kind(original)
		if String(record.early_kind) in KIT:
			record.erase("garden")
	return plan

static func kit_mesh(name: String) -> Mesh:
	if meshes.has(name): return meshes[name]
	var scene: PackedScene = load("res://assets/buildings/early_settlement/%s.glb" % name)
	var root := scene.instantiate()
	var surface := SurfaceTool.new()
	for child in root.find_children("*","MeshInstance3D",true,false):
		var transform: Transform3D = child.transform
		var ancestor: Node = child.get_parent()
		while ancestor is Node3D:
			transform = ancestor.transform * transform; ancestor = ancestor.get_parent()
		for part in child.mesh.get_surface_count(): surface.append_from(child.mesh,part,transform)
	meshes[name] = surface.commit(); root.free()
	return meshes[name]

static func render(plan: Dictionary, center: Vector3, height: Callable, parent: Node3D) -> void:
	var inherited := {"buildings":[],"replaced":plan.replaced}
	for record in plan.buildings:
		if String(record.get("early_kind","")) not in KIT: inherited.buildings.append(record)
	TOWN.render(inherited,center,height,parent)
	if material == null:
		material = StandardMaterial3D.new(); material.vertex_color_use_as_albedo = true
		material.roughness = .95; material.cull_mode = BaseMaterial3D.CULL_DISABLED
	for name in KIT:
		var visible: Array[Dictionary] = []
		for record in plan.buildings:
			if String(record.get("early_kind","")) != name: continue
			var plot: Dictionary = record.plot
			if String(plot.get("status","active")) in ["ruin","vacant","reclaimed","under_construction"]: continue
			if float(plot.get("damage",{}).get("structural",0)) > .65: continue
			visible.append(record)
		if visible.is_empty(): continue
		var batch := MultiMesh.new(); batch.transform_format = MultiMesh.TRANSFORM_3D
		batch.use_colors = true; batch.mesh = kit_mesh(name); batch.instance_count = visible.size()
		var transforms: Array[Transform3D] = []
		for i in visible.size():
			var record := visible[i]; var point: Vector2 = record.position + Vector2(center.x,center.z)
			var transform := Transform3D(Basis(Vector3.UP,float(record.angle)).scaled(Vector3.ONE*.001),Vector3(point.x,float(height.call(point.x,point.y))+.0001,point.y))
			transforms.append(transform); batch.set_instance_transform(i,transform)
			var plot: Dictionary = record.plot
			var wear := 1-clampf(float(plot.get("condition",1)),0,1)
			var fire := clampf(float(plot.get("damage",{}).get("fire",0)),0,1)
			batch.set_instance_color(i,Color.WHITE.lerp(Color(.3,.27,.23),maxf(wear*.55,fire)))
		var node := MultiMeshInstance3D.new(); node.name = "EarlySettlement_"+name
		node.multimesh = batch; node.material_override = material
		node.set_meta("source_transforms",transforms); parent.add_child(node)

extends RefCounted
## Built-form adapter: observes completed plot records, never unlocks construction.
## No population, calendar, stockpile, or research lookup can restyle an old house.
const LATE := preload("res://scripts/settlement_architecture_kit.gd")
const TOWN := preload("res://scripts/organic_town_visual.gd")
const KIT := ["carried_ridge", "carried_round", "rooted_lean_to", "round_household", "earthen_household", "rubble_household", "raised_store", "covered_workshop"]
# Only recorded early forms belong in this adapter. Later/unknown forms retain
# legacy coverage even if their inherited roof/material resembles an early house.
const HOUSEHOLD_FORMS := ["timber_household", "timber_and_fibre_household", "earthen_household", "dry_stone_household", "durable_household_cluster", "joined_kin_compound", "courtyard_household_compound"]
const MARKET_FORMS := ["covered_exchange_court", "periodic_market_court", "maintained_gathering_ground", "customary_precinct", "durable_assembly_compound"]
static var meshes: Dictionary = {}
static var material: StandardMaterial3D

static func kind(plot: Dictionary) -> String:
	var late:=LATE.kind(plot)
	if late!="":return late
	if int(plot.get("storeys",1)) != 1: return ""
	var form := String(plot.get("form",""))
	var use := String(plot.get("land_use",""))
	var family := String(plot.get("material_family",""))
	var roof := String(plot.get("roof_plan",""))
	if use in ["residential_compound","mixed_household","temporary_encampment"]:
		if form in ["portable_shelter_cluster","light_shelter_cluster","emergency_open_encampment"]:
			return "carried_round" if roof == "round_light_shelter" else "carried_ridge"
		if form == "lean_to_household_cluster": return "rooted_lean_to"
		if form not in HOUSEHOLD_FORMS: return ""
		if family == "earth": return "earthen_household"
		if family == "stone": return "rubble_household"
		if family in ["organic","timber"]:
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
	if not kind(plot).is_empty(): return true
	var form := String(plot.get("form",""))
	var use := String(plot.get("land_use",""))
	var eligible := (use in ["residential_compound","mixed_household"] and form in HOUSEHOLD_FORMS) or (use == "market" and form in MARKET_FORMS)
	return eligible and TOWN.supports(plot)

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
		if not supports(plot):
			# Keep the obstacle polygon, but prevent the older broad timber predicate
			# from re-admitting a later/unknown form inside the shared solver.
			plot["roof_plan"] = "unsupported_early_adapter_form"
			continue
		plot["visual_form"]=kind(plot)
		if kind(plot).is_empty(): continue
		if kind(plot) in KIT or LATE.kind(plot)!="":
			var envelope := (LATE.mesh_for_plot(plot) if LATE.kind(plot)!="" else kit_mesh(kind(plot))).get_aabb()
			var extent := envelope.position.abs().max(envelope.end.abs())
			plot["placement_half_extent"] = Vector2(extent.x, extent.z) * .001
		# Reuse the checked footprint/road/water solver, retaining plot identity and
		# reserved future household sites. This is a display copy, not a conversion.
		plot.storeys=1
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

static func remember_layout(plan:Dictionary,plots:Array[Dictionary])->void:
	# Called explicitly by the live renderer. Saved plot geometry owns these sites;
	# the pure layout function used by previews/tests never changes simulation data.
	var by_plot:Dictionary={}
	for record:Dictionary in plan.buildings:
		var site:=record.duplicate(true);site.erase("plot");site.erase("garden");site.erase("early_kind")
		var id:=int(record.plot_id)
		if not by_plot.has(id):by_plot[id]=[]
		by_plot[id].append(site)
	for plot in plots:
		if by_plot.has(int(plot.id)):
			plot["visual_building_sites"]=by_plot[int(plot.id)]
			plot["visual_sites_form"]=kind(plot) if not kind(plot).is_empty() else String(plot.get("form",""))

static func kit_mesh(name: String) -> Mesh:
	if meshes.has(name): return meshes[name]
	var scene: PackedScene = load("res://assets/buildings/early_settlement/%s.glb" % name)
	var root := scene.instantiate()
	var children := root.find_children("*","MeshInstance3D",true,false)
	if children.size() == 1:
		var child: MeshInstance3D = children[0]
		var transform := child.transform
		var ancestor: Node = child.get_parent()
		while ancestor is Node3D:
			transform = ancestor.transform * transform; ancestor = ancestor.get_parent()
		if transform.is_equal_approx(Transform3D.IDENTITY):
			# Preserve importer LOD index buffers and shadow mesh, not just vertices.
			meshes[name] = child.mesh; root.free(); return meshes[name]
	# Unusual multi-mesh/nonidentity authored scenes require transform baking.
	# This fallback flattens the mesh and cannot retain imported LOD/shadow data.
	var surface := SurfaceTool.new()
	for child in children:
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
		if String(record.get("early_kind","")) not in KIT and LATE.kind(record.plot)=="": inherited.buildings.append(record)
	TOWN.render(inherited,center,height,parent)
	LATE.render(plan,center,height,parent)
	if material == null:
		material = StandardMaterial3D.new(); material.vertex_color_use_as_albedo = true
		material.roughness = .95; material.cull_mode = BaseMaterial3D.CULL_DISABLED
	for name in KIT:
		var visible: Array[Dictionary] = []
		for record in plan.buildings:
			if String(record.get("early_kind","")) != name: continue
			var plot: Dictionary = record.plot
			if String(plot.get("status","active")) in ["ruin","reclaimed","under_construction"]: continue
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

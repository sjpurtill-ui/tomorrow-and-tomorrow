extends RefCounted
## Built-form adapter: observes recorded plot work, never unlocks construction.
## No population, calendar, stockpile, or research lookup can restyle an old house.
const LATE := preload("res://scripts/settlement_architecture_kit.gd")
const TOWN := preload("res://scripts/organic_town_visual.gd")
const CONSTRUCTION := preload("res://scripts/settlement_construction_state.gd")
const CONSTRUCTION_MESH := preload("res://scripts/settlement_construction_mesh.gd")
const KIT := ["carried_ridge", "carried_round", "rooted_lean_to", "round_household", "earthen_household", "rubble_household", "raised_store", "covered_workshop"]
# Only recorded early forms belong in this adapter. Later/unknown forms retain
# legacy coverage even if their inherited roof/material resembles an early house.
const HOUSEHOLD_FORMS := ["timber_household", "timber_and_fibre_household", "earthen_household", "dry_stone_household", "durable_household_cluster", "joined_kin_compound", "courtyard_household_compound"]
const MARKET_FORMS := ["covered_exchange_court", "periodic_market_court", "maintained_gathering_ground", "customary_precinct", "durable_assembly_compound"]
static var meshes: Dictionary = {}
static var material: Material

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
	# Detail admission is bounded per plot; extra fields must not change the
	# ground presentation beneath homes already admitted to the kit.
	for plot in plots:
		if int(plot.get("id",0)) <= TOWN.MAX_PLOTS and supports(plot): return true
	return false

static func has_kit(plots: Array[Dictionary]) -> bool:
	for plot in plots:
		if int(plot.get("id",0)) <= TOWN.MAX_PLOTS and supports(plot): return true
	return false

static func layout(plots: Array[Dictionary], routes: Array[Dictionary], land: Callable, changed_plots:Dictionary={}) -> Dictionary:
	# Adapter fields are top-level values; nested geometry is observed only.
	# Copying saved sites into every proxy and every returned building turned a
	# single-parcel update into repeated copies of the full inherited fabric.
	var proxies:Array[Dictionary]=[]
	for plot in plots:proxies.append(plot.duplicate(false))
	var originals: Dictionary = {}
	for plot in plots: originals[int(plot.id)] = plot
	for plot in proxies:
		if not supports(plot):
			# Keep the obstacle polygon, but prevent the older broad timber predicate
			# from re-admitting a later/unknown form inside the shared solver.
			plot["roof_plan"] = "unsupported_early_adapter_form"
			continue
		plot["visual_form"]=kind(plot) if not kind(plot).is_empty() else String(plot.get("form",""))
		# A completed upgrade changes architecture, not the location of an existing
		# home. Later kit envelopes can exceed founding parcels; retain recorded
		# sites and fit the new mesh inside their already reserved footprint.
		if LATE.kind(plot)!="" and String(plot.get("visual_sites_form",""))!=String(plot.visual_form):
			var inherited:Array=[]
			var parcel:PackedVector2Array=plot.get("polygon",PackedVector2Array())
			for saved:Dictionary in plot.get("visual_building_sites",[]):
				var footprint:PackedVector2Array=saved.get("footprint",PackedVector2Array())
				if footprint.size()<3 or parcel.size()<3:continue
				if not Geometry2D.clip_polygons(footprint,parcel).is_empty():continue
				var site:=saved.duplicate(true);site["fit_inherited_site"]=true
				inherited.append(site)
			if not inherited.is_empty():
				plot["visual_building_sites"]=inherited
				plot["visual_sites_form"]=plot.visual_form
		if LATE.kind(plot)=="" and kind(plot) not in KIT and TOWN.supports(plot) and LATE.installed_features(plot)>0:
			# Variant is selected inside TOWN.layout; reserve the maximum envelope
			# of its finite kit so overlays cannot bypass road/neighbor clearance.
			var reserved:=Vector2.ZERO
			for variant in TOWN.KIT.size():
				var bounds:=TOWN.kit_mesh(variant).get_aabb()
				bounds=bounds.merge(LATE.early_detail_mesh(bounds,"town",LATE.installed_features(plot)).get_aabb())
				var extent:=bounds.position.abs().max(bounds.end.abs())
				reserved=reserved.max(Vector2(extent.x,extent.z)*.001)
			plot["placement_half_extent"]=reserved
		if kind(plot).is_empty(): continue
		if kind(plot) in KIT or LATE.kind(plot)!="":
			var envelope := (LATE.mesh_for_plot(plot) if LATE.kind(plot)!="" else kit_mesh(kind(plot))).get_aabb()
			if LATE.kind(plot)=="" and LATE.installed_features(plot)>0:
				envelope=envelope.merge(LATE.early_detail_mesh(envelope,kind(plot),LATE.installed_features(plot)).get_aabb())
			var extent := envelope.position.abs().max(envelope.end.abs())
			plot["placement_half_extent"] = Vector2(extent.x, extent.z) * .001
			if LATE.kind(plot)!="":
				# A late prototype describes a whole block, while many real lots are
				# still household sized. Reserve a compact version through the same
				# road/parcel/land solver instead of silently omitting the building.
				var parcel:PackedVector2Array=plot.get("polygon",PackedVector2Array())
				if parcel.size()>=3:
					var size:=TOWN.bounds(parcel).size
					var limit:=maxf(.0018,minf(size.x,size.y)*.15)
					var half:Vector2=plot.placement_half_extent
					if maxf(half.x,half.y)>limit:
						plot.placement_half_extent=half*(limit/maxf(half.x,half.y))
						plot["fit_compact_site"]=true
		# Reuse the checked footprint/road/water solver, retaining plot identity and
		# reserved future household sites. This is a display copy, not a conversion.
		plot.storeys=1
		plot.material_family = "organic"; plot.roof_plan = "timber_ridge"
		plot.form = "timber_household"; plot.land_use = "residential_compound"
	var plan := TOWN.layout(proxies,routes,land,changed_plots)
	# Round huts and tents turn their doors to the hearth (codex/beauty-5): a
	# round footprint is the same whichever way it faces, so the solver's
	# clearances still hold.
	var hearth := Vector2.ZERO
	for plot in plots:
		if String(plot.get("form","")) in ["open_hearth_yard","maintained_gathering_ground"] and String(plot.get("status","active")) not in ["vacant","reclaimed","ruin"]:
			var c: Variant = plot.get("centroid",Vector2.ZERO)
			if c is Vector2: hearth = c; break
	for record in plan.buildings:
		if bool(record.plot.get("fit_compact_site",false)):record["fit_inherited_site"]=true
		var original: Dictionary = originals[int(record.plot_id)]
		record.plot = original.duplicate(false)
		record["early_kind"] = kind(original)
		if String(record.early_kind) in KIT:
			record.erase("garden")
		if String(record.early_kind) in ["round_household","carried_round"]:
			var to_hearth: Vector2 = hearth-Vector2(record.position)
			if to_hearth.length() > .004: record.angle = atan2(to_hearth.x,to_hearth.y)
	return plan

static func remember_layout(plan:Dictionary,plots:Array[Dictionary])->void:
	# Called explicitly by the live renderer. Saved plot geometry owns these sites;
	# the pure layout function used by previews/tests never changes simulation data.
	var by_plot:Dictionary={}
	for record:Dictionary in plan.buildings:
		var site:=record.duplicate(false);site.erase("plot");site.erase("garden");site.erase("early_kind")
		site=site.duplicate(true)
		var id:=int(record.plot_id)
		if not by_plot.has(id):by_plot[id]=[]
		by_plot[id].append(site)
	for plot in plots:
		if by_plot.has(int(plot.id)):
			plot["visual_building_sites"]=by_plot[int(plot.id)]
			plot["visual_sites_form"]=kind(plot) if not kind(plot).is_empty() else String(plot.get("form",""))

static func kit_mesh(name: String) -> Mesh:
	if meshes.has(name): return meshes[name]
	var imported := _imported_mesh(name)
	# Coded low-poly forms (settlement_kit_shapes.gd) fitted to the authored
	# envelope, so placement is unchanged; the authored mesh stays where no
	# coded form exists (the rubble household).
	var coded: Mesh = preload("res://scripts/settlement_kit_shapes.gd").mesh(name, imported.get_aabb())
	meshes[name] = coded if coded != null else imported
	return meshes[name]

static var imported_meshes: Dictionary = {}

static func _imported_mesh(name: String) -> Mesh:
	if imported_meshes.has(name): return imported_meshes[name]
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
			imported_meshes[name] = child.mesh; root.free(); return imported_meshes[name]
	# Unusual multi-mesh/nonidentity authored scenes require transform baking.
	# This fallback flattens the mesh and cannot retain imported LOD/shadow data.
	var surface := SurfaceTool.new()
	for child in children:
		var transform: Transform3D = child.transform
		var ancestor: Node = child.get_parent()
		while ancestor is Node3D:
			transform = ancestor.transform * transform; ancestor = ancestor.get_parent()
		for part in child.mesh.get_surface_count(): surface.append_from(child.mesh,part,transform)
	imported_meshes[name] = surface.commit(); root.free()
	return imported_meshes[name]

static func render(plan: Dictionary, center: Vector3, height: Callable, parent: Node3D) -> void:
	var complete:Array=[]
	var work:Array[Dictionary]=[]
	var states:Dictionary={}
	for record:Dictionary in plan.buildings:
		var plot:Dictionary=record.plot
		var id:=int(record.plot_id)
		if not states.has(id):states[id]=CONSTRUCTION.state(plot)
		var current:Dictionary=states[id]
		if current.mode!="" and String(plot.get("status","active")) not in ["ruin","reclaimed"] and float(plot.get("damage",{}).get("structural",0))<=.65:
			work.append({"record":record,"state":current})
		if current.mode!="new":complete.append(record)
	var completed_plan:={"buildings":complete,"replaced":plan.replaced}
	var inherited := {"buildings":[],"replaced":plan.replaced}
	for record in complete:
		if String(record.get("early_kind","")) not in KIT and LATE.kind(record.plot)=="": inherited.buildings.append(record)
	TOWN.render(inherited,center,height,parent)
	LATE.render(completed_plan,center,height,parent)
	_render_installed_early_details(completed_plan,center,height,parent)
	if material == null:
		# Painted in the map's ink (scripts/settlement_ink.gd), vertex colours kept.
		material = preload("res://scripts/settlement_ink.gd").material()
	for name in KIT:
		var visible: Array[Dictionary] = []
		for record in complete:
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
			# Each dwelling a little its own size and lean (settlement_kit_shapes.gd).
			var transform := Transform3D(preload("res://scripts/settlement_kit_shapes.gd").lived_basis(float(record.angle),hash(Vector2(record.position))),Vector3(point.x,float(height.call(point.x,point.y))+.0001,point.y))
			transforms.append(transform); batch.set_instance_transform(i,transform)
			var plot: Dictionary = record.plot
			var wear := 1-clampf(float(plot.get("condition",1)),0,1)
			var fire := clampf(float(plot.get("damage",{}).get("fire",0)),0,1)
			# Weathering greys the straw and daub; only fire blackens (codex/beauty-5).
			batch.set_instance_color(i,Color.WHITE.lerp(Color(.70,.66,.60),wear*.35).lerp(Color(.3,.27,.23),fire))
		var node := MultiMeshInstance3D.new(); node.name = "EarlySettlement_"+name
		node.multimesh = batch; node.material_override = material
		node.set_meta("source_transforms",transforms); parent.add_child(node)
		# Soft shadows where each building stands (settlement_ink.gd).
		preload("res://scripts/settlement_ink.gd").add_ground_shadows(parent,"GroundShadow_"+name,transforms,kit_mesh(name).get_aabb())
	_render_construction(work,center,height,parent)

static func _render_construction(work:Array[Dictionary],center:Vector3,height:Callable,parent:Node3D)->void:
	var groups:Dictionary={}
	for entry:Dictionary in work:
		var record:Dictionary=entry.record;var plot:Dictionary=record.plot
		var name:=String(record.get("early_kind",""))
		var late:=LATE.kind(plot)!=""
		var town:=not late and name not in KIT and TOWN.supports(plot)
		var source:Mesh
		if late:source=LATE.mesh_for_plot(plot)
		elif name in KIT:source=kit_mesh(name)
		elif town:source=TOWN.kit_mesh(clampi(int(record.get("variant",0)),0,TOWN.KIT.size()-1))
		else:continue
		var retrofit:=String(entry.state.mode)=="retrofit"
		var stage:=int(entry.state.stage)
		var key:=CONSTRUCTION_MESH.cache_key(source,plot,stage,retrofit)
		if not groups.has(key):
			var mesh:Mesh=CONSTRUCTION_MESH.retrofit_mesh(source,plot,stage) if retrofit else CONSTRUCTION_MESH.mesh(source,plot,stage)
			if mesh==null:continue
			groups[key]={"mesh":mesh,"records":[],"state":entry.state,"late":late,"town":town}
		groups[key].records.append(record)
	for key:String in groups:
		var group:Dictionary=groups[key]
		var batch:=MultiMesh.new();batch.transform_format=MultiMesh.TRANSFORM_3D;batch.use_colors=true
		batch.mesh=group.mesh;batch.instance_count=group.records.size()
		var transforms:Array[Transform3D]=[]
		for index in group.records.size():
			var record:Dictionary=group.records[index];var plot:Dictionary=record.plot
			var point:Vector2=record.position+Vector2(center.x,center.z)
			var basis:Basis=LATE.site_basis(record) if bool(group.late) else preload("res://scripts/settlement_kit_shapes.gd").lived_basis(float(record.angle),hash(Vector2(record.position)))
			var transform:=Transform3D(basis,Vector3(point.x,float(height.call(point.x,point.y))+(.0004 if bool(group.town) else .0001),point.y))
			transforms.append(transform);batch.set_instance_transform(index,transform)
			var wear:=1-clampf(float(plot.get("condition",1)),0,1)
			var tint:=Color.WHITE
			if bool(group.late):
				tint=[Color("fff7e8"),Color("e8eee6"),Color("e7e1d9"),Color("eedbd0")][posmod(int(plot.get("seed",1)),4)]
				tint=tint.lerp(Color("b2a38a"),wear*.3)
			else:tint=tint.lerp(Color(.70,.66,.60),wear*.35).lerp(Color(.3,.27,.23),clampf(float(plot.get("damage",{}).get("fire",0)),0,1))
			batch.set_instance_color(index,tint)
		var node:=MultiMeshInstance3D.new();node.name="Construction_"+str(hash(key));node.multimesh=batch
		node.material_override=preload("res://scripts/settlement_ink.gd").architecture_material() if bool(group.late) else material
		node.set_meta("source_transforms",transforms);node.set_meta("construction_mode",group.state.mode);node.set_meta("construction_stage",group.state.stage)
		parent.add_child(node)
		if String(group.state.mode)=="new":preload("res://scripts/settlement_ink.gd").add_ground_shadows(parent,"GroundShadowConstruction_"+str(hash(key)),transforms,batch.mesh.get_aabb())

static func _render_installed_early_details(plan:Dictionary,center:Vector3,height:Callable,parent:Node3D)->void:
	var groups:Dictionary={}
	for record:Dictionary in plan.buildings:
		var plot:Dictionary=record.plot
		if LATE.kind(plot)!="":continue
		if String(plot.get("status","active")) in ["ruin","reclaimed","under_construction"]:continue
		if float(plot.get("damage",{}).get("structural",0))>.65:continue
		var flags:=LATE.installed_features(plot)
		if flags==0:continue
		var name:=String(record.get("early_kind",""))
		var source:Mesh
		if name in KIT:source=kit_mesh(name)
		elif TOWN.supports(plot):source=TOWN.kit_mesh(clampi(int(record.get("variant",0)),0,TOWN.KIT.size()-1))
		else:continue
		var mesh:=LATE.early_detail_mesh(source.get_aabb(),name,flags)
		var key:=str(mesh.get_instance_id())
		if not groups.has(key):groups[key]={"mesh":mesh,"records":[]}
		groups[key].records.append(record)
	if material==null:
		material=preload("res://scripts/settlement_ink.gd").material()
	for key:String in groups:
		var group:Dictionary=groups[key]
		var batch:=MultiMesh.new();batch.transform_format=MultiMesh.TRANSFORM_3D;batch.mesh=group.mesh;batch.instance_count=group.records.size()
		for i in group.records.size():
			var record:Dictionary=group.records[i]
			var point:Vector2=record.position+Vector2(center.x,center.z)
			batch.set_instance_transform(i,Transform3D(Basis(Vector3.UP,float(record.angle)).scaled(Vector3.ONE*.001),Vector3(point.x,float(height.call(point.x,point.y))+.0001,point.y)))
		var node:=MultiMeshInstance3D.new();node.name="InstalledEarlyDetails_"+key;node.multimesh=batch;node.material_override=material;parent.add_child(node)

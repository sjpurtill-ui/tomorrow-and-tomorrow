extends Node
## Exhaustive catalog presentation probe. Prepared records, never a campaign.
## Actual Model/View/Stage; one process, bounded contact pages and ceremonies.
const Concept = preload("res://scripts/wonder_concept.gd")
const Catalog = preload("res://scripts/undertaking_catalog.gd")
const Design = preload("res://scripts/hud/great_work_design.gd")
const Model = preload("res://scripts/hud/great_work_model.gd")
const View = preload("res://scripts/hud/great_work_view.gd")
const Stage = preload("res://scripts/hud/great_work_ceremony_stage.gd")
const Fixture = preload("res://tests/great_works_experience_probe.gd")
const GW = preload("res://scripts/great_works.gd")
const U = preload("res://scripts/undertaking_system.gd")
const T = preload("res://scripts/hud/hud_tokens.gd")
const REPRESENTATIVE_TIERS = {"ring":0,"mound":0,"stair":1,"tower":4,"hall":1,"cistern":1,"granary":1,"bridge":2,"causeway":1,"dam":5,"colossus":2,"garden":1,"observatory":3,"gate":2,"canal":2,"archive":3,"amphitheatre":2,"lighthouse":4}
const REPRESENTATIVE_MATERIALS = {"tower":"iron","hall":"timber","cistern":"brick","granary":"timber","causeway":"earth","dam":"concrete","garden":"earth","archive":"brick","lighthouse":"iron"}
const TIER_KNOWN = [[],["masonry_bond_patterns","joinery"],["voussoir_arch_assembly","plain_weaving"],["masonry_buttressing","fitted_tailoring","broad_treadle_loom"],["steel_refining","rotative_steam_engine","sewing_machine_mechanisms"],["concrete_mix_design","electrical_generators","radio_broadcasting","garment_size_grading","solid_state_lighting"]]
const TIER_YEARS = [0,650,1300,2000,2700,3000]

var capture := false
var strict := false
var inventory_only := false
var variants := false
var six_cast := false
var only_group := "all"
var only_design := ""
var out := "res://artifacts/great-work-catalog"
var checks := 0
var failures: Array[String] = []
var specs: Array[Dictionary] = []
var page: Control
var context: Dictionary = {}
var ritual_ids := {}
var ritual_shapes := {}
var report := {"prepared_records":true,"catalog":[],"geometry":[],"views":[],"ceremonies":[],"images":[],"checks":[],"variant_count":0,"purpose_variants":[]}

func _ready() -> void: _run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.has("--great-work-catalog") or not bool(ProjectSettings.get_setting("application/config/use_custom_user_dir",false)) or not OS.get_user_data_dir().to_lower().contains("acceptance"):
		printerr("Requires --great-work-catalog and isolated acceptance userdata.")
		get_tree().quit(2)
		return
	capture = args.has("--capture")
	strict = args.has("--require-authored")
	inventory_only = args.has("--inventory-only")
	variants = args.has("--variants")
	six_cast = args.has("--six-cast")
	for arg in args:
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
		if arg.begins_with("--group="): only_group = arg.trim_prefix("--group=")
		if arg.begins_with("--design="): only_design = arg.trim_prefix("--design=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	_disable_simulation()
	_inventory()
	if not inventory_only:
		_structure()
		if variants: _variants()
		if only_group in ["all","construction"]: await _contact_pages()
		if only_group in ["all","ceremonies"]:
			_setup_people()
			for spec in specs: await _ceremony(spec)
	await _clear()
	report["passed"] = checks - failures.size()
	report["total"] = checks
	report["failures"] = failures
	report["requires_authored"] = strict
	report["inventory_only"] = inventory_only
	report["six_cast"] = six_cast
	report["display"] = DisplayServer.get_name()
	report["engine"] = Engine.get_version_info().string
	var filename := "capture.json" if capture else "functional.json"
	var file := FileAccess.open(out.path_join(filename),FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(report,"  "))
	print("GREAT_WORK_CATALOG_ACCEPTANCE ",JSON.stringify({"passed":report.passed,"total":checks,"failures":failures,"report":out.path_join(filename),"inventory_only":inventory_only}))
	get_tree().quit(0 if failures.is_empty() else 1)

func _disable_simulation() -> void:
	for node in get_tree().root.get_children():
		if node != self:
			node.set_process(false)
			node.set_physics_process(false)

func _inventory() -> void:
	var index := 0
	for form: String in Concept.FORMS:
		var purpose := _purpose(form)
		var material := String(REPRESENTATIVE_MATERIALS.get(form,"stone"))
		var tier := int(REPRESENTATIVE_TIERS[form])
		var id := Concept.make_id(form,purpose,"grand",material,tier,"catalog%02d" % index)
		specs.append({"index":index,"design_id":"form:"+form,"id":id,"title":form.capitalize(),"form":form,"material":material,"purpose":purpose,"tier":tier,"legacy":false})
		index += 1
	for definition: Dictionary in Catalog.all():
		var design := Design.describe({"id":definition.id})
		specs.append({"index":index,"design_id":"legacy:"+String(definition.id),"id":definition.id,"title":definition.title,"form":design.form,"material":design.material,"purpose":definition.purpose,"tier":0,"legacy":true})
		index += 1
	_check(Concept.FORMS.size() == 18 and Catalog.all().size() == 12 and specs.size() == 30,"Inventory contains all 18 form families and 12 legacy IDs")
	var seen := {}
	for spec in specs:
		_check(not Catalog.get_definition(String(spec.id)).is_empty() and not seen.has(spec.design_id),String(spec.design_id)+" resolves uniquely through the actual catalog")
		var design := Design.describe({"id":spec.id})
		_check(design.valid and design.design_id == spec.design_id and design.construction_labels.size() == 4,String(spec.design_id)+" has a valid presentation identity and four named construction phases")
		seen[spec.design_id] = true
		report.catalog.append(spec.duplicate())
	if not only_design.is_empty(): specs = specs.filter(func(s:Dictionary)->bool:return String(s.design_id) in only_design.split(","))
	_check(not specs.is_empty(),"At least one selected catalog entry exists")

func _purpose(form: String) -> String:
	for purpose: String in Concept.PURPOSES:
		if form in Concept.PURPOSES[purpose].forms: return purpose
	return "bind_tribes"

func _record(spec: Dictionary, fraction: float, status: String = "") -> Dictionary:
	return {"id":spec.id,"progress":float(Catalog.get_definition(String(spec.id)).work)*fraction,"status":status if not status.is_empty() else ("functioning" if fraction >= 1.0 else "building"),"condition":1.0,"last_work":10.0 if fraction > 0 and fraction < 1 else 0.0,"custom_name":spec.title,"outcome":"success" if fraction >= 1 else "","work_scale":1.0}

func _structure() -> void:
	var complete_shapes := {}
	for spec in specs:
		for fraction in [0.0,.3,.7,1.0]:
			var work := _record(spec,fraction)
			var before := var_to_bytes(work)
			var built: Dictionary = Model.build(work,{"plan":true,"workers":true,"scaffolds":true})
			var geometry := _geometry(built.root)
			var bounds: AABB = built.bounds
			_check(bounds.position.is_finite() and bounds.size.is_finite() and bounds.size.x > 0 and bounds.size.y > 0 and bounds.size.z > 0 and geometry.finite and geometry.vertices > 0,"%s %.1f has finite nonempty geometry and bounds" % [spec.design_id,fraction])
			_check(is_equal_approx(float(built.progress),fraction) and var_to_bytes(work) == before,"%s %.1f reads progress without changing its source record" % [spec.design_id,fraction])
			if strict:
				_check(String(built.description.get("design_id","")) == String(spec.design_id),"%s %.1f selects the authored design identity" % [spec.design_id,fraction])
				_check(String(built.root.get_meta("design_id","")) == String(spec.design_id),"%s %.1f installs the authored model profile" % [spec.design_id,fraction])
			if fraction == 1.0:
				if strict: _check(not complete_shapes.has(geometry.shape_hash),String(spec.design_id)+" has distinct completed geometry rather than a shared fallback")
				complete_shapes[geometry.shape_hash] = spec.design_id
			report.geometry.append({"design_id":spec.design_id,"fraction":fraction,"bounds":str(bounds),"geometry":geometry,"description":built.description})
			built.root.free()
			if fraction < 1:
				_check(Model.describe(_record(spec,fraction,"functioning")).state != "standing",String(spec.design_id)+" incomplete fraction cannot become complete from a status label")

func _geometry(root: Node3D) -> Dictionary:
	var vertices := 0
	var finite := true
	var digest := HashingContext.new()
	digest.start(HashingContext.HASH_SHA256)
	for child: MeshInstance3D in root.find_children("*","MeshInstance3D",true,false):
		# Geometry fingerprints exclude optional plan/scaffold/people and all colours.
		if child.name in ["Scaffolding","UnbuiltPlan","Builders","Ground","Courses"]: continue
		digest.update(var_to_bytes(child.transform))
		for surface in child.mesh.get_surface_count():
			var arrays := child.mesh.surface_get_arrays(surface)
			var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			vertices += points.size()
			for point in points: finite = finite and point.is_finite()
			digest.update(points.to_byte_array())
			if arrays[Mesh.ARRAY_INDEX] is PackedInt32Array: digest.update((arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).to_byte_array())
	return {"vertices":vertices,"finite":finite,"shape_hash":digest.finish().hex_encode()}

func _variants() -> void:
	# Exhaust all encoded material/tier/ambition combinations at standing state;
	# the canonical 30 entries separately cover four construction stages.
	for spec in specs:
		if spec.legacy: continue
		for material: String in Concept.FORMS[spec.form].materials:
			for tier in 6:
				for ambition: String in Concept.AMBITIONS:
					var variant := spec.duplicate()
					variant.id = Concept.make_id(spec.form,spec.purpose,ambition,material,tier,"variant")
					var built: Dictionary = Model.build(_record(variant,1),{})
					var geometry := _geometry(built.root)
					var bounds: AABB = built.bounds
					_check(geometry.finite and geometry.vertices > 0 and bounds.position.is_finite() and bounds.size.is_finite(),"%s/%s/tier%d/%s builds finite completed geometry" % [spec.design_id,material,tier,ambition])
					if strict: _check(String(built.description.get("design_id","")) == String(spec.design_id),"%s/%s/tier%d/%s retains its authored profile" % [spec.design_id,material,tier,ambition])
					built.root.free()
					report.variant_count += 1
		for purpose: String in Concept.PURPOSES:
			var variant := spec.duplicate()
			variant.id = Concept.make_id(spec.form,purpose,"grand",spec.material,int(spec.tier),"purpose")
			var work := _record(variant,1.0)
			var design := Design.describe(work)
			var built: Dictionary = Model.build(work,{})
			var geometry := _geometry(built.root)
			_check(design.purpose == purpose and not String(design.purpose_emblem).is_empty() and geometry.finite and geometry.vertices > 0,String(spec.design_id)+" supports purpose "+purpose+" with its actual emblem and finite geometry")
			report.purpose_variants.append({"design_id":spec.design_id,"purpose":purpose,"emblem":design.purpose_emblem,"geometry":geometry})
			built.root.free()

func _clear() -> void:
	if is_instance_valid(page): page.queue_free()
	await _frames(3)

func _base_page(dimensions: Vector2i, title: String) -> VBoxContainer:
	get_window().size = dimensions
	page = PanelContainer.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.add_theme_stylebox_override("panel",T.flat(T.PAPER,T.RULE,1,0,12))
	add_child(page)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",10)
	page.add_child(column)
	column.add_child(T.make_label(title,22,T.INK))
	return column

func _contact_pages() -> void:
	T.set_color_mode("light")
	for start in range(0,specs.size(),6):
		await _clear()
		var column := _base_page(Vector2i(2400,1800),"PREPARED CATALOG RECORDS · Construction 0 / 30 / 70 / 100 percent · page %d" % (start/6+1))
		var grid := GridContainer.new()
		grid.columns = 3
		grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_child(grid)
		var mounted: Array = []
		for index in range(start,mini(start+6,specs.size())):
			var spec := specs[index]
			var card := VBoxContainer.new()
			card.custom_minimum_size = Vector2(784,852)
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			grid.add_child(card)
			card.add_child(T.make_label("%02d · %s · %s" % [spec.index+1,spec.design_id,spec.title],17,T.INK))
			card.add_child(T.make_label("Prepared tier %d · %s · %s" % [spec.tier,spec.material,spec.purpose],13,T.INK_MUTED))
			var phases := GridContainer.new()
			phases.columns = 2
			phases.size_flags_vertical = Control.SIZE_EXPAND_FILL
			card.add_child(phases)
			for fraction in [0.0,.3,.7,1.0]:
				var view: Control = View.make(_record(spec,fraction),390)
				view.custom_minimum_size.x = 388
				phases.add_child(view)
				mounted.append({"view":view,"spec":spec,"fraction":fraction})
		await _frames(14)
		for item in mounted:
			var view: Control = item.view
			var identity: int = view.model_root.get_instance_id()
			var builds := int(view.report().builds)
			view.orbit_by(Vector2(20,-4)); view.zoom_by(.4)
			_check(view.model_root.get_instance_id() == identity and int(view.report().builds) == builds,String(item.spec.design_id)+" camera retains phase "+str(item.fraction)+" geometry")
			view.reset_view()
		await _frames(8)
		for item in mounted:
			var view: Control = item.view
			_check(Rect2(Vector2.ZERO,Vector2(get_window().size)).encloses(view.get_global_rect()),String(item.spec.design_id)+" phase "+str(item.fraction)+" fits its contact page")
			report.views.append({"design_id":item.spec.design_id,"fraction":item.fraction,"report":view.report(),"rect":str(view.get_global_rect())})
		# One actual pixel sleep/wake pair for every catalog design, at standing.
		for item in mounted:
			if item.fraction == 1 and DisplayServer.get_name() != "headless": await _pixel_idle(item.view,String(item.spec.design_id))
		await _capture("catalog-%02d" % (start/6+1))

func _pixel_idle(view: Control, design: String) -> void:
	await RenderingServer.frame_post_draw
	var pixels: PackedByteArray = view.viewport.get_texture().get_image().get_data()
	view.model_root.visible = false
	await _frames(3)
	await RenderingServer.frame_post_draw
	var slept: bool = pixels == view.viewport.get_texture().get_image().get_data()
	view.orbit_by(Vector2(1,0))
	await _frames(3)
	await RenderingServer.frame_post_draw
	var woke: bool = pixels != view.viewport.get_texture().get_image().get_data()
	_check(slept and woke,design+" actual viewport sleeps without requests and wakes on camera input")
	view.model_root.visible = true
	view.orbit_by(Vector2(-1,0))
	await _frames(3)

func _setup_people() -> void:
	var fixture := Fixture.new()
	fixture._setup_world()
	var city: Dictionary = fixture.city
	# Optional maximum-cast fixture adds two actual seeded actors through the
	# same world helper; all four envoys still resolve through CharacterVoice.
	if six_cast:
		fixture._stock_actor("rival_c",600)
		fixture._stock_actor("rival_d",550)
		CivilizationSystem.civilizations.append(fixture._civ("rival_c","Third Assembly",300,.3,Vector2(-30,0)))
		CivilizationSystem.civilizations.append(fixture._civ("rival_d","Fourth Assembly",300,.3,Vector2(0,-30)))
	fixture.free()
	var id := Concept.make_id("ring","bind_tribes","modest","stone",0,"matrixpeople")
	var commissioned := GW.commission(String(city.id),{"id":id,"name":"Prepared Builder Commission"},"modest","player",func(_point:Vector2)->float:return 0.0,func(_point:Vector2)->bool:return true)
	var work := U.find(city,String(commissioned.get("id","")))
	_check(not work.is_empty(),"One actual commission supplies the catalog fixture's recorded builder")
	context = {"key":"catalog","architect":work.get("architect",{}),"official":GovernmentPeopleSystem.officeholder("Steward"),"attendees":[{"civ_id":"rival_a","name":"Kel Adun"},{"civ_id":"rival_b","name":"Qingshan"}]}
	if six_cast:
		context.attendees.append({"civ_id":"rival_c","name":"Third Assembly"})
		context.attendees.append({"civ_id":"rival_d","name":"Fourth Assembly"})
	_disable_simulation()

func _capabilities(spec: Dictionary) -> void:
	GameState.known_discoveries.clear()
	GameState.discovery_adoption.clear()
	var known: Array = TIER_KNOWN[int(spec.tier)].duplicate()
	var definition := Catalog.get_definition(String(spec.id))
	if not definition.get("requires",[]).is_empty(): known.append(definition.requires[0])
	if not spec.legacy:
		for id in Concept.MATERIALS[String(spec.material)].requires: known.append(id)
	for id: String in known:
		if id not in GameState.known_discoveries: GameState.known_discoveries.append(id)
		GameState.discovery_adoption[id] = 1.0
	GameState.elapsed_days = float(TIER_YEARS[int(spec.tier)])*365.0
	DiscoverySystem.refresh_operating_effects()

func _ceremony(spec: Dictionary) -> void:
	print("CATALOG_CEREMONY ",spec.design_id)
	await _clear()
	_capabilities(spec)
	T.set_color_mode("dark" if int(spec.index)%2 else "light")
	var column := _base_page(Vector2i(1280,900),"PREPARED PRESENTATION · %02d · %s · %s" % [spec.index+1,spec.design_id,spec.title])
	var detail := T.make_label("",15,T.INK_MUTED)
	column.add_child(detail)
	var work := _record(spec,1.0)
	var before := var_to_bytes(work)
	var scene: Control = Stage.make(work,context,760)
	scene.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scene.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(scene)
	await _frames(12)
	scene.show_work(); scene.settle()
	await _frames(4)
	var diagnostics: Dictionary = scene.diagnostics()
	var ritual_geometry := _geometry(scene._props)
	detail.text = "Tier %d / year %d · %s · ritual %s · %s / %s / %s" % [spec.tier,TIER_YEARS[int(spec.tier)],String(diagnostics.get("mode","")),String(diagnostics.get("ritual_id","BASELINE")),String(diagnostics.get("prop","")),String(diagnostics.get("action","")),String(diagnostics.get("formation",""))]
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_check(int(diagnostics.cast_count) >= 2 and int(diagnostics.cast_count) <= 6 and int(diagnostics.body_count) == int(diagnostics.cast_count),String(spec.design_id)+" mounts its bounded recorded court cast")
	if six_cast: _check(int(diagnostics.cast_count) == 6,String(spec.design_id)+" exercises the maximum six-person gathering")
	_check(int(diagnostics.mesh_count) > 0 and not diagnostics.committed and not diagnostics.viewport_active,String(spec.design_id)+" presents and settles a real completed monument")
	if strict:
		_check(String(diagnostics.get("design_id","")) == String(spec.design_id),String(spec.design_id)+" dedication retains the authored work identity")
		var ritual_id := String(diagnostics.get("ritual_id",""))
		_check(not ritual_id.is_empty() and not ritual_ids.has(ritual_id),String(spec.design_id)+" has its own catalog ritual profile")
		_check(ritual_geometry.finite and ritual_geometry.vertices > 0 and not ritual_shapes.has(ritual_geometry.shape_hash),String(spec.design_id)+" has distinct physical ritual geometry beyond its label or colors")
		ritual_ids[ritual_id] = true
		ritual_shapes[ritual_geometry.shape_hash] = true
	_check(_fits_camera(scene.lens,scene._bounds,scene.view.size),String(spec.design_id)+" whole-work camera contains its completed bounds")
	await _capture("%02d-%s-before" % [spec.index+1,String(spec.design_id).replace(":","-")])
	scene.dedication(); scene.settle()
	await _frames(4)
	var after: Dictionary = scene.diagnostics()
	_check(after.committed and after.model_node_id == diagnostics.model_node_id and int(after.build_count) == int(diagnostics.build_count) and not after.viewport_active,String(spec.design_id)+" ritual retains geometry and returns to idle")
	_check(var_to_bytes(work) == before,String(spec.design_id)+" presentation leaves the prepared work record unchanged")
	scene.dedication(); scene.settle()
	_check(scene.diagnostics().model_node_id == diagnostics.model_node_id,String(spec.design_id)+" repeated presentation action retains the same scene")
	await _capture("%02d-%s-after" % [spec.index+1,String(spec.design_id).replace(":","-")])
	report.ceremonies.append({"design_id":spec.design_id,"year":TIER_YEARS[int(spec.tier)],"before":diagnostics,"after":after,"bounds":str(scene._bounds),"ritual_geometry":ritual_geometry})

func _fits_camera(camera: Camera3D, bounds: AABB, extent: Vector2i) -> bool:
	var frame := Rect2(Vector2.ZERO,Vector2(extent)).grow(1.0)
	for corner in 8:
		var point := bounds.get_endpoint(corner)
		if camera.is_position_behind(point) or not frame.has_point(camera.unproject_position(point)): return false
	return true

func _frames(count: int) -> void:
	for frame in count: await get_tree().process_frame

func _capture(id: String) -> void:
	if not capture or DisplayServer.get_name() == "headless": return
	await _frames(4)
	await RenderingServer.frame_post_draw
	_check(get_viewport().get_texture().get_image().save_png(out.path_join(id+".png")) == OK,"Capture saves "+id)
	report.images.append(id+".png")

func _check(ok: bool, message: String) -> void:
	checks += 1
	report.checks.append({"ok":ok,"message":message})
	if not ok:
		failures.append(message)
		printerr("GREAT_WORK_CATALOG_FAILED ",message)

extends GdUnitTestSuite
const EARLY := preload("res://scripts/early_settlement_visual.gd")
const TOWN := preload("res://scripts/organic_town_visual.gd")
const MAP := preload("res://scripts/local_terrain.gd")

func fixture(form: String = "portable_shelter_cluster", family: String = "organic", roof: String = "ridge_light_shelter") -> Dictionary:
	var plots: Array[Dictionary] = [{"id":1,"seed":91,"centroid":Vector2.ZERO,"polygon":PackedVector2Array([Vector2(-.02,-.02),Vector2(.02,-.02),Vector2(.02,.02),Vector2(-.02,.02)]),"frontage_route_id":1,"area_ha":.16,"roof_coverage":.3,"resident_count":12,"material_family":family,"land_use":"residential_compound","form":form,"roof_plan":roof,"status":"active","condition":.9}]
	var routes: Array[Dictionary] = [{"id":1,"kind":"camp_path","width_m":.6,"points":PackedVector2Array([Vector2(-.025,0),Vector2(.025,0)])}]
	return {"plots":plots,"routes":routes}

func dry(_point: Vector2) -> bool: return true

func before_test() -> void:
	GameState.reset_for_new_world(910137)

func test_completed_forms_drive_the_progression_without_population_or_date_swaps() -> void:
	var data := fixture(); var before := data.duplicate(true)
	var camp := EARLY.layout(data.plots,data.routes,dry)
	assert_int(camp.buildings.size()).is_greater(0)
	assert_str(camp.buildings[0].early_kind).is_equal("carried_ridge")
	data.plots[0].resident_count=2000;data.plots[0].created_day=-200000
	GameState.elapsed_days=200000;GameState.known_discoveries=["clay_shaping","stone_selection"]
	var same := EARLY.layout(data.plots,data.routes,dry)
	assert_str(same.buildings[0].early_kind).is_equal("carried_ridge")
	assert_vector(same.buildings[0].position).is_equal(camp.buildings[0].position)
	data.plots[0].form="lean_to_household_cluster"
	var lean := EARLY.layout(data.plots,data.routes,dry)
	assert_str(lean.buildings[0].early_kind).is_equal("rooted_lean_to")
	assert_vector(lean.buildings[0].position).is_equal(camp.buildings[0].position)
	data.plots[0].form="durable_household_cluster"
	assert_str(EARLY.kind(data.plots[0])).is_equal("timber_household")
	assert_str(before.plots[0].form).is_equal("portable_shelter_cluster")

func test_actual_household_recipe_requires_delivered_resources_and_research() -> void:
	GameState.resource_stockpiles={"Clay":100,"Stone":100,"Timber":0,"Fiber Plants":100}
	GameState.known_discoveries=[]
	assert_dict(SettlementModel._available_household_recipe()).is_empty()
	GameState.known_discoveries=["clay_shaping"]
	var recipe: Dictionary=SettlementModel._available_household_recipe()
	assert_str(recipe.family).is_equal("earth")
	var data:=fixture(String(recipe.form),String(recipe.family),"courtyard_flat")
	assert_str(EARLY.kind(data.plots[0])).is_equal("earthen_household")
	GameState.resource_stockpiles={"Stone":100,"Timber":1,"Fiber Plants":0,"Clay":0}
	GameState.known_discoveries=[]
	assert_dict(SettlementModel._available_household_recipe()).is_empty()
	GameState.known_discoveries=["stone_selection"]
	recipe=SettlementModel._available_household_recipe()
	assert_str(recipe.family).is_equal("stone")
	data=fixture(String(recipe.form),String(recipe.family),"rubble_slab")
	assert_str(EARLY.kind(data.plots[0])).is_equal("rubble_household")

func test_actual_early_work_completion_changes_form_without_replanning_the_settlement() -> void:
	GameState.initialize_population_model();GameState.settlement_completed=["Hearth Circle"]
	SettlementModel.ensure_founded()
	var initial:=EARLY.layout(GameState.settlement_plots,GameState.settlement_routes,dry)
	assert_int(initial.buildings.size()).is_greater(0)
	var routes:=GameState.settlement_routes.duplicate(true)
	GameState.settlement_completed.append("Lean-to Shelters")
	var events:Array[Dictionary]=[]
	SettlementModel._synchronize_early_works(5,events)
	var after:=EARLY.layout(GameState.settlement_plots,GameState.settlement_routes,dry)
	var rooted:=0
	for record in after.buildings:
		if record.early_kind=="rooted_lean_to":rooted+=1
	assert_int(rooted).is_greater(0)
	assert_array(GameState.settlement_routes).is_equal(routes)
	assert_int(events.size()).is_greater(0)

func test_workshops_and_stores_require_their_recorded_completed_form() -> void:
	var plot:Dictionary=fixture().plots[0]
	plot.land_use="workshop";plot.form="open_work_yard"
	assert_str(EARLY.kind(plot)).is_empty()
	plot.form="sheltered_work_area"
	assert_str(EARLY.kind(plot)).is_equal("covered_workshop")
	plot.land_use="storage";plot.form="guarded_cache"
	assert_str(EARLY.kind(plot)).is_empty()
	plot.form="lined_storage_pits"
	assert_str(EARLY.kind(plot)).is_empty()
	plot.form="raised_timber_store"
	assert_str(EARLY.kind(plot)).is_equal("raised_store")

func test_mesh_envelopes_scale_and_ruin_respect_the_shared_placement_contract() -> void:
	for name in EARLY.KIT:
		var mesh:=EARLY.kit_mesh(name);var envelope:=mesh.get_aabb()
		assert_float(envelope.size.x).is_less(4.2)
		assert_float(envelope.size.z).is_less(4.7)
		assert_float(envelope.size.y).is_between(.7,3.6)
		assert_int(mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR].size()).is_greater(0)
	var data:=fixture();var saved:=data.duplicate(true)
	var plan:=EARLY.layout(data.plots,data.routes,dry)
	var parent:Node3D=auto_free(Node3D.new())
	EARLY.render(plan,Vector3.ZERO,func(_x:float,_z:float)->float:return .5,parent)
	assert_int(parent.get_child_count()).is_equal(1)
	var transform:Transform3D=parent.get_child(0).get_meta("source_transforms")[0]
	assert_float(transform.basis.x.length()).is_equal_approx(.001,.000001)
	assert_float(transform.origin.y).is_equal_approx(.5001,.000001)
	assert_dict(data).is_equal(saved)
	data.plots[0].status="ruin"
	var ruined:Node3D=auto_free(Node3D.new())
	EARLY.render(EARLY.layout(data.plots,data.routes,dry),Vector3.ZERO,func(_x:float,_z:float)->float:return 0,ruined)
	assert_int(ruined.get_child_count()).is_equal(0)
	assert_array(EARLY.layout(data.plots,data.routes,func(_p:Vector2)->bool:return false).buildings).is_empty()

func test_founding_terrain_hook_uses_the_same_recorded_kit_across_population_and_zoom() -> void:
	GameState.initialize_population_model();GameState.settlement_completed=["Hearth Circle"]
	SettlementModel.ensure_founded()
	var renderer:Node3D=auto_free(MAP.new())
	renderer._configure_seamless_world();renderer._configure_shape();renderer._configure_noise();renderer._prepare_river_course()
	for population in [40,2000,20000]:
		renderer.footprint_population=population
		assert_bool(renderer._organic_town_enabled()).is_true()
	var camera:Camera3D=auto_free(Camera3D.new());renderer.camera=camera
	var first:Array=[]
	for zoom in [.1,1,10]:
		camera.size=zoom
		var parent:Node3D=auto_free(Node3D.new())
		renderer._create_plot_fabric(GameState.settlement_founded_at,GameState.settlement_plots,0,parent)
		var transforms:Array=[]
		for child in parent.get_children():
			if String(child.name).begins_with("EarlySettlement_"):transforms.append_array(child.get_meta("source_transforms"))
		assert_int(transforms.size()).is_greater(0)
		if first.is_empty():first=transforms
		else:assert_array(transforms).is_equal(first)

func test_mixed_resource_town_keeps_inherited_styles_and_bounded_representatives() -> void:
	var plots:Array[Dictionary]=[];var routes:Array[Dictionary]=[]
	for i in 100:
		var data:=fixture();var plot:Dictionary=data.plots[0];var offset:=Vector2((i%10)*.06,(i/10)*.06)
		plot.id=i+1;plot.frontage_route_id=i+1;plot.resident_count=20;plot.centroid=offset
		for p in plot.polygon.size():plot.polygon[p]+=offset
		var route:Dictionary=data.routes[0];route.id=i+1
		for p in route.points.size():route.points[p]+=offset
		if i%4==1:plot.form="lean_to_household_cluster"
		elif i%4==2:plot.form="earthen_household";plot.material_family="earth";plot.roof_plan="courtyard_flat"
		elif i%4==3:plot.form="dry_stone_household";plot.material_family="stone";plot.roof_plan="rubble_slab"
		plots.append(plot);routes.append(route)
	var plan:=EARLY.layout(plots,routes,dry)
	assert_int(plan.buildings.size()).is_between(100,TOWN.MAX_BUILDINGS)
	var kinds:Dictionary={}
	for record in plan.buildings:kinds[record.early_kind]=true
	assert_int(kinds.size()).is_equal(4)
	assert_bool(EARLY.enabled(plots)).is_true()
	var source:=plots.duplicate(true)
	GameState.societal_values["architecture"]={"monumentality":1.0,"civic_space":0.1,"permeability":0.0}
	var unchanged:=EARLY.layout(plots,routes,dry)
	for i in plan.buildings.size():
		assert_str(unchanged.buildings[i].early_kind).is_equal(plan.buildings[i].early_kind)
		assert_vector(unchanged.buildings[i].position).is_equal(plan.buildings[i].position)
	assert_array(plots).is_equal(source)

func test_advanced_and_unknown_forms_cannot_enter_through_either_adapter_path() -> void:
	for form in ["industrial_age_tenement_block","metropolitan_mixed_block","unrecognized_household","inherited_urban_block"]:
		for family in ["organic","timber","earth","stone"]:
			for roof in ["ridge_light_shelter","timber_ridge","round_thatch"]:
				var data:=fixture(form,family,roof)
				assert_str(EARLY.kind(data.plots[0])).is_empty()
				assert_bool(EARLY.supports(data.plots[0])).is_false()
				assert_array(EARLY.layout(data.plots,data.routes,dry).buildings).is_empty()
	for form in EARLY.HOUSEHOLD_FORMS:
		for family in ["organic","earth","stone"]:
			var data:=fixture(form,family,"ridge_light_shelter")
			assert_bool(EARLY.supports(data.plots[0])).is_true()
			assert_int(EARLY.layout(data.plots,data.routes,dry).buildings.size()).is_greater(0)

func test_imported_mesh_identity_and_lod_shadow_resources_are_retained() -> void:
	var scene:PackedScene=load("res://assets/buildings/early_settlement/rubble_household.glb")
	var root:Node=auto_free(scene.instantiate())
	var imported:Mesh=root.find_children("*","MeshInstance3D",true,false)[0].mesh
	var runtime:Mesh=EARLY.kit_mesh("rubble_household")
	assert_bool(runtime==imported).is_true()
	assert_bool(runtime.shadow_mesh==imported.shadow_mesh).is_true()
	var lods:Array=RenderingServer.mesh_get_surface(imported.get_rid(),0).get("lods",[])
	assert_int(lods.size()).is_greater(0)
	assert_array(RenderingServer.mesh_get_surface(runtime.get_rid(),0).get("lods",[])).is_equal(lods)

func test_completed_shelters_do_not_spawn_a_duplicate_primitive_camp() -> void:
	var renderer:Node3D=auto_free(MAP.new())
	renderer.settlement_visual_root=auto_free(Node3D.new())
	renderer._spawn_settlement_structure("Lean-to Shelters")
	assert_int(renderer.settlement_visual_root.get_child_count()).is_equal(0)

func test_no_fit_early_household_never_falls_back_to_legacy_roofs() -> void:
	var data:=fixture()
	data.routes.clear()
	GameState.settlement_plots.assign(data.plots)
	GameState.settlement_routes.clear()
	var renderer:Node3D=auto_free(MAP.new())
	var camera:Camera3D=auto_free(Camera3D.new());renderer.camera=camera
	var parent:Node3D=auto_free(Node3D.new())
	renderer._create_plot_fabric(Vector3.ZERO,GameState.settlement_plots,0,parent)
	assert_bool(parent.has_node("PersistentRoofFabric")).is_false()
	assert_bool(parent.has_node("PersistentWallFabric")).is_false()

func test_compact_asset_fits_a_parcel_too_narrow_for_old_house_envelope() -> void:
	var data:=fixture("lean_to_household_cluster")
	data.plots[0].polygon=PackedVector2Array([Vector2(-.0021,.001),Vector2(.0021,.001),Vector2(.0021,.009),Vector2(-.0021,.009)])
	var plan:=EARLY.layout(data.plots,data.routes,dry)
	assert_int(plan.buildings.size()).is_greater(0)
	for record in plan.buildings:
		assert_array(Geometry2D.clip_polygons(record.footprint,data.plots[0].polygon)).is_empty()

func test_neighborhood_ground_replaces_parcel_mats_and_service_monuments() -> void:
	GameState.initialize_population_model();GameState.settlement_completed=["Hearth Circle"]
	SettlementModel.ensure_founded()
	var renderer:Node3D=auto_free(MAP.new())
	renderer._configure_seamless_world();renderer._configure_shape();renderer._configure_noise();renderer._prepare_river_course()
	var camera:Camera3D=auto_free(Camera3D.new());renderer.camera=camera
	var parent:Node3D=auto_free(Node3D.new())
	renderer._create_persistent_settlement_routes(Vector3.ZERO,GameState.settlement_routes,parent)
	renderer._create_plot_fabric(Vector3.ZERO,GameState.settlement_plots,0,parent)
	assert_bool(parent.has_node("PersistentPlotGround")).is_false()
	assert_bool(parent.has_node("PersistentDesirePaths")).is_false()
	assert_bool(parent.has_node("EarlyWorkingGround")).is_true()
	assert_bool(parent.has_node("EarlyCommunalObjects")).is_true()

func test_working_ground_respects_water_and_does_not_mutate_history() -> void:
	var ground:=preload("res://scripts/early_settlement_ground.gd")
	var data:=fixture();data.plots[0].form="open_hearth_yard";data.plots[0].land_use="communal"
	var before:=data.duplicate(true)
	var parent:Node3D=auto_free(Node3D.new())
	ground.render({"buildings":[]},data.plots,data.routes,Vector3.ZERO,func(_x:float,_y:float)->float:return 0,func(_p:Vector2)->bool:return false,parent)
	assert_int(parent.get_child_count()).is_equal(0)
	assert_dict(data).is_equal(before)

func test_vacant_intact_buildings_stay_visible_and_saved_sites_survive_road_changes()->void:
	var data:=fixture()
	var plan:=EARLY.layout(data.plots,data.routes,func(_p:Vector2)->bool:return true)
	assert_int(plan.buildings.size()).is_greater(0)
	EARLY.remember_layout(plan,data.plots)
	var sites:Dictionary={}
	for record in plan.buildings:sites[record.id]=record.position
	for plot in data.plots:plot.status="vacant";plot.condition=.6
	for route in data.routes:route.width_m=float(route.get("width_m",1))+.6
	var next:=EARLY.layout(data.plots,data.routes,func(_p:Vector2)->bool:return true)
	for record in next.buildings:
		if sites.has(record.id):assert_vector(record.position).is_equal(sites[record.id])
	assert_int(next.buildings.size()).is_greater_equal(sites.size())
	var parent:Node3D=auto_free(Node3D.new())
	EARLY.render(next,Vector3.ZERO,func(_x:float,_z:float)->float:return 0.0,parent)
	assert_int(parent.get_child_count()).is_greater(0)

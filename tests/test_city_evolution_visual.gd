extends GdUnitTestSuite
const Fixture=preload("res://tests/city_evolution_visual_fixture.gd")
const Town=preload("res://scripts/organic_town_visual.gd")
const Kit=preload("res://scripts/settlement_architecture_kit.gd")
func before_test()->void:Fixture.initialize()

func test_supported_parcel_after_detailed_budget_still_has_roofs()->void:
	var snapshot:=Fixture.snapshot(3000)
	var p:Dictionary=snapshot.plots[-1].duplicate(true);p.id=Town.MAX_PLOTS+1
	snapshot.plots.assign([p]);GameState.settlement_plots=snapshot.plots
	var renderer:=Fixture.FlatRenderer.new();var parent:Node3D=auto_free(Node3D.new())
	var result:=Fixture.render(renderer,snapshot,parent)
	assert_int(result.detailed_buildings).is_equal(0)
	assert_int(result.fallback_roof_vertices).is_greater(0)
	renderer.settlement_fabric_shader=null;renderer.free()

func test_placed_kit_buildings_do_not_receive_duplicate_fallback_roofs()->void:
	var snapshot:=Fixture.snapshot(3000)
	snapshot.plots.assign([snapshot.plots[0]])
	var renderer:=Fixture.FlatRenderer.new();var parent:Node3D=auto_free(Node3D.new())
	var result:=Fixture.render(renderer,snapshot,parent)
	assert_int(result.detailed_buildings).is_greater(0)
	assert_int(result.fallback_roof_vertices).is_equal(0)
	renderer.settlement_fabric_shader=null;renderer.free()

func test_modern_roofs_close_each_volume_without_pitched_gables_or_extra_storeys()->void:
	for type:String in Kit.TYPES:
		for floors in [1,3,8,18]:
			var mesh:=Kit.mesh_for("modern_"+type,floors)
			var max_height:float=3.1*floors if type not in ["workshop","warehouse"] else maxf(4.0,minf(3.1*floors,9.0))
			assert_float(mesh.get_aabb().end.y).override_failure_message(type+" adds an unrecorded floor or roof above its volume").is_less_equal(max_height+.7)
			var arrays:=mesh.surface_get_arrays(0)
			var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
			if indices.is_empty():
				for index in vertices.size():indices.append(index)
			var pitched:=false
			for triangle in range(0,indices.size(),3):
				var normal:Vector3=(vertices[indices[triangle+1]]-vertices[indices[triangle]]).cross(vertices[indices[triangle+2]]-vertices[indices[triangle]]).normalized()
				if absf(normal.y)>=.001 and absf(normal.y)<=.999:pitched=true;break
			assert_bool(pitched).override_failure_message(type+" retains a pitched preindustrial gable").is_false()

func test_mixed_placed_overbudget_and_no_fit_parcels_preserve_placement_rejection()->void:
	var snapshot:=Fixture.snapshot(3000)
	var placed:Dictionary=snapshot.plots[0]
	var overbudget:Dictionary=snapshot.plots[1];overbudget.id=Town.MAX_PLOTS+1
	var no_fit:Dictionary=snapshot.plots[2];no_fit.frontage_route_id=999
	snapshot.plots.assign([placed,overbudget,no_fit])
	var renderer:=Fixture.FlatRenderer.new();var parent:Node3D=auto_free(Node3D.new())
	var result:=Fixture.render(renderer,snapshot,parent)
	var plan:Dictionary=renderer._organic_town_plan(Vector3.ZERO,func(_p:Vector2)->bool:return true)
	assert_bool(plan.replaced.has(placed.id)).is_true()
	assert_bool(plan.replaced.has(overbudget.id)).is_false()
	assert_bool(plan.replaced.has(no_fit.id)).is_false()
	var roofs:=SurfaceTool.new();roofs.begin(Mesh.PRIMITIVE_TRIANGLES)
	var walls:=SurfaceTool.new();walls.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p in [overbudget]:
		var count:Dictionary=renderer._append_satellite_roof_fabric(roofs,walls,p,Vector3.ZERO,0,true)
		assert_int(count.roofs).is_greater(0)
	assert_int(result.fallback_roof_vertices).is_equal(roofs.commit().surface_get_array_len(0))
	assert_object(parent.get_node_or_null("PersistentPlotGround")).is_not_null()
	assert_object(parent.get_node_or_null("PersistentPlotBoundaries")).is_not_null()
	renderer.settlement_fabric_shader=null;renderer.free()

func test_two_hundred_year_snapshots_keep_capacity_and_visible_roofs_through_year_three_thousand()->void:
	var previous_capacity:=0;var previous_height:=0.0;var previous_coverage:=0
	var renderer:=Fixture.FlatRenderer.new()
	for year in range(0,3001,200):
		var snapshot:=Fixture.snapshot(year);var parent:=Node3D.new()
		var result:=Fixture.render(renderer,snapshot,parent)
		var plan:Dictionary=renderer._organic_town_plan(Vector3.ZERO,func(_p:Vector2)->bool:return true)
		var covered:Dictionary=plan.replaced.duplicate()
		# Each legal prepared lot outside the detailed budget survives in fallback.
		for p:Dictionary in snapshot.plots:
			if int(p.id)>Town.MAX_PLOTS:
				var roofs:=SurfaceTool.new();roofs.begin(Mesh.PRIMITIVE_TRIANGLES)
				var walls:=SurfaceTool.new();walls.begin(Mesh.PRIMITIVE_TRIANGLES)
				var count:Dictionary=renderer._append_satellite_roof_fabric(roofs,walls,p,Vector3.ZERO,0,true)
				assert_int(count.roofs).override_failure_message("Missing legal parcel "+str(p.id)).is_greater(0)
				if count.roofs>0:covered[p.id]=true
		assert_int(snapshot.capacity).is_greater_equal(previous_capacity)
		assert_int(covered.size()).is_greater_equal(previous_coverage)
		assert_float(result.height_m).is_greater_equal(previous_height)
		assert_int(result.detailed_buildings).is_less_equal(512)
		previous_capacity=snapshot.capacity;previous_height=result.height_m;previous_coverage=covered.size()
		parent.free()
	renderer.settlement_fabric_shader=null;renderer.free()

func test_thin_roof_outline_uses_surface_normals_without_changing_legacy_material()->void:
	var ink:=preload("res://scripts/settlement_ink.gd")
	var legacy:=ink.material()
	var architecture:=ink.architecture_material()
	assert_object(ink.architecture_material()).is_same(architecture)
	assert_object(architecture).is_not_same(legacy)
	assert_bool(legacy.next_pass.get_shader_parameter("surface_normals")).is_false()
	assert_bool(architecture.next_pass.get_shader_parameter("surface_normals")).is_true()
	ink.set_pixel(.00037)
	assert_float(architecture.next_pass.get_shader_parameter("pixel_km")).is_equal_approx(.00037,.000001)
	assert_float(legacy.next_pass.get_shader_parameter("pixel_km")).is_equal_approx(.00037,.000001)
	ink.set_hearth(Vector3(1,2,3),.4)
	assert_bool(architecture.get_shader_parameter("hearth")==legacy.get_shader_parameter("hearth")).is_true()
	ink.set_clock(7.25)
	assert_float(architecture.get_shader_parameter("anim_clock")).is_equal(7.25)
	ink.set_hearth(Vector3.ZERO,0.0)

func test_population_extent_is_continuous_at_all_classification_thresholds()->void:
	var renderer:=Fixture.FlatRenderer.new()
	var plots:Array[Dictionary]=[]
	var stages:=["camp","hamlet","village","town","city","metropolis","megalopolis"]
	var thresholds:=[80,400,2500,18000,1000000,10000000]
	for index in thresholds.size():
		var people:int=thresholds[index]
		var old:Dictionary=renderer._settlement_stage_visual_layout({"stage":index},people-1,plots)
		var next:Dictionary=renderer._settlement_stage_visual_layout({"stage":index+1},people,plots)
		assert_float(next.radius).override_failure_message(stages[index]+" -> "+stages[index+1]+" shrinks").is_greater_equal(old.radius)
		assert_float(next.radius/old.radius).is_less(1.02)
		var same_people:Dictionary=renderer._settlement_stage_visual_layout({"stage":index+1},people-1,plots)
		assert_float(same_people.radius).is_equal(old.radius)
	var p:=Fixture.plot(1);p.polygon=PackedVector2Array([Vector2(-2,-2),Vector2(2,-2),Vector2(2,2),Vector2(-2,2)])
	plots.append(p)
	assert_float(renderer._settlement_stage_visual_layout({"stage":0},1,plots).radius).is_equal_approx(sqrt(8.0)*1.05,.000001)
	assert_float(renderer._settlement_stage_visual_layout({"stage":6},1000000000,plots).radius).is_less_equal(340.0)
	renderer.free()

func test_overbudget_roofs_stay_inside_parcel_and_off_streets_and_unsafe_ground()->void:
	var placement:=preload("res://scripts/settlement_fallback_placement.gd")
	var parcel:=PackedVector2Array([Vector2(-.02,-.02),Vector2(.02,-.02),Vector2(.02,.02),Vector2(-.02,.02)])
	var safe:=PackedVector2Array([Vector2(-.005,-.005),Vector2(.005,-.005),Vector2(.005,.005),Vector2(-.005,.005)])
	var routes:Array[Dictionary]=[]
	var dry:=func(_p:Vector2)->bool:return true
	var flat:=func(_p:Vector2)->float:return 0.0
	assert_bool(placement.fits(safe,parcel,routes,dry,flat)).is_true()
	var outside:=safe.duplicate();outside[0]=Vector2(-.03,-.005)
	assert_bool(placement.fits(outside,parcel,routes,dry,flat)).is_false()
	routes.append({"id":1,"width_m":2,"points":PackedVector2Array([Vector2(-.03,0),Vector2(.03,0)])})
	assert_bool(placement.fits(safe,parcel,routes,dry,flat)).is_false()
	routes.clear()
	assert_bool(placement.fits(safe,parcel,routes,func(p:Vector2)->bool:return p.x<.004,flat)).is_false()
	assert_bool(placement.fits(safe,parcel,routes,dry,func(p:Vector2)->float:return p.x)).is_false()
	var snapshot:=Fixture.snapshot(3000)
	var p:Dictionary=snapshot.plots[-1].duplicate(true);p.id=Town.MAX_PLOTS+1;p.polygon=parcel;p.centroid=Vector2.ZERO;p.frontage_route_id=1
	GameState.settlement_routes=[{"id":1,"active":true,"points":PackedVector2Array([Vector2(-.02,-.019),Vector2(.02,-.019)]),"width_m":2.0}]
	var renderer:=Fixture.FlatRenderer.new()
	var roofs:=SurfaceTool.new();roofs.begin(Mesh.PRIMITIVE_TRIANGLES)
	var walls:=SurfaceTool.new();walls.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count:Dictionary=renderer._append_satellite_roof_fabric(roofs,walls,p,Vector3.ZERO,0,true)
	assert_int(count.roofs).is_greater(0)
	var points:PackedVector3Array=roofs.commit_to_arrays()[Mesh.ARRAY_VERTEX]
	var all_inside:=true
	for vertex in points:
		if not Geometry2D.is_point_in_polygon(Vector2(vertex.x,vertex.z),parcel):all_inside=false;break
	assert_bool(all_inside).is_true()
	renderer.free()

func test_one_storey_expansion_roofs_remain_above_yards_after_detail_budget()->void:
	var snapshot:=Fixture.snapshot(200)
	var p:Dictionary=snapshot.plots[0].duplicate(true)
	p.id=Town.MAX_PLOTS+1;p.storeys=1;p.status="stressed";p.condition=.05
	snapshot.plots.assign([p]);GameState.settlement_plots=snapshot.plots
	var renderer:=Fixture.FlatRenderer.new();var parent:Node3D=auto_free(Node3D.new())
	var result:=Fixture.render(renderer,snapshot,parent)
	assert_int(result.fallback_roof_vertices).is_greater(0)
	var roof:=parent.get_node_or_null("PersistentRoofFabric") as MeshInstance3D
	assert_object(roof).is_not_null()
	if roof!=null:
		for name in ["PersistentPlotGround","PersistentYardVariation","PersistentSettlementDensity"]:
			var ground:=parent.get_node_or_null(name) as MeshInstance3D
			if ground!=null:
				assert_float(ground.mesh.get_aabb().end.y).override_failure_message(name+" buries an occupied roof").is_less(roof.mesh.get_aabb().position.y)
	renderer.settlement_fabric_shader=null;renderer.free()

func test_expansion_parcel_after_old_128_limit_has_detailed_buildings()->void:
	var snapshot:=Fixture.snapshot(3000)
	var p:Dictionary=snapshot.plots[0].duplicate(true);p.id=129
	snapshot.plots.assign([p]);GameState.settlement_plots=snapshot.plots
	var renderer:=Fixture.FlatRenderer.new();var parent:Node3D=auto_free(Node3D.new())
	var result:=Fixture.render(renderer,snapshot,parent)
	assert_int(result.detailed_buildings).is_greater(0)
	assert_int(result.fallback_roof_vertices).is_equal(0)
	renderer.settlement_fabric_shader=null;renderer.free()

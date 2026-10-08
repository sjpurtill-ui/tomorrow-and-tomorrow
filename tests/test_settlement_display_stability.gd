extends GdUnitTestSuite
## A fixed camera observes growth; it must not receive a fresh sample of towns.
const EARLY=preload("res://scripts/early_settlement_visual.gd")

class Terrain extends "res://scripts/local_terrain.gd":
	var roofs:Dictionary={}
	var live_architecture:Dictionary={"axiality":.5,"monumentality":.5,"civic_space":.5,"permeability":.5,"defensive_depth":.5,"terrain_conformity":.5}
	func _ready()->void:pass
	func _process(_delta:float)->void:pass
	func _height_at(_x:float,_z:float)->float:return 1.0
	func _close_surface_height_at(_x:float,_z:float)->float:return 1.0
	func _terrain_contour_angle(_point:Vector2,fallback:float)->float:return fallback
	func _settlement_stage_land_at(_point:Vector2)->bool:return true
	func _settlement_architecture_profile()->Dictionary:
		return live_architecture
	func _append_roof_footprint(_surface:SurfaceTool,center:Vector3,local_center:Vector2,right:Vector2,forward:Vector2,_color:Color,lift:float,_atlas_cell:Vector2i,variant:int,_roof_plan:String,_texture_seed:=0,_late_atlas:=false)->void:
		roofs[variant]=[center,local_center,right,forward,lift]
	func _append_roof_wall_skirt(_surface:SurfaceTool,_center:Vector3,_local_center:Vector2,_right:Vector2,_forward:Vector2,_plot:Dictionary,_roof_lift:float)->int:return 1
	func _append_irregular_roof_patch(_surface:SurfaceTool,_center:Vector3,_local_center:Vector2,_right:Vector2,_forward:Vector2,_color:Color,_lift:float,_atlas_cell:Vector2i,_texture_seed:int,_late_atlas:=false)->void:pass

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(491720)

func _terrain()->Terrain:
	var terrain:Terrain=auto_free(Terrain.new())
	terrain.camera=Camera3D.new();terrain.add_child(terrain.camera)
	terrain.camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	terrain.camera.size=1.0
	return terrain

func test_one_new_plot_does_not_replace_existing_detail_membership()->void:
	var terrain:=_terrain()
	var budget:int=terrain._settlement_detail_plot_budget(1)
	assert_int(budget).is_equal(768)
	var changed:Array[int]=[]
	for id in range(1,budget+1):
		var plot:Dictionary={"id":id,"status":"active","land_use":"residential_compound"}
		var was_visible:bool=terrain._settlement_plot_has_detail(plot,id,budget,1)
		var now_visible:bool=terrain._settlement_plot_has_detail(plot,id,budget+1,1)
		if was_visible!=now_visible:changed.append(id)
	assert_array(changed).is_empty()

func test_one_new_plot_does_not_replace_existing_density_membership()->void:
	var terrain:=_terrain()
	var changed:Array[int]=[]
	for id in range(1,385):
		# Unknown completed forms really use the aggregate fallback, including
		# plots inside the detailed kit's numeric budget.
		var plot:Dictionary={"id":id,"status":"active","land_use":"residential_compound","form":"aggregate_household"}
		var was_visible:bool=terrain._settlement_plot_has_aggregate_density(plot,id,384,1)
		var now_visible:bool=terrain._settlement_plot_has_aggregate_density(plot,id,385,1)
		if was_visible!=now_visible:changed.append(id)
	assert_array(changed).is_empty()

func test_real_view_admission_retains_members_refills_removed_slots_and_is_bounded()->void:
	var terrain:=_terrain()
	var plots:Array[Dictionary]=[]
	for id in range(1,851):plots.append({"id":id,"status":"active","land_use":"residential_compound"})
	var first:Dictionary=terrain._settlement_plot_admission(Vector3.ZERO,plots,1)
	assert_int(first.detail.size()).is_equal(768)
	assert_int(first.density.size()).is_equal(384)
	plots.append({"id":851,"status":"active","land_use":"residential_compound"})
	var appended:Dictionary=terrain._settlement_plot_admission(Vector3.ZERO,plots,1)
	assert_dict(appended).is_equal(first)
	plots.remove_at(0)
	var pruned:Dictionary=terrain._settlement_plot_admission(Vector3.ZERO,plots,1)
	assert_bool(pruned.detail.has(1)).is_false();assert_bool(pruned.density.has(1)).is_false()
	assert_int(pruned.detail.size()).is_equal(768);assert_int(pruned.density.size()).is_equal(384)
	for id:int in first.detail:
		if id!=1:assert_bool(pruned.detail.has(id)).is_true()
	for id:int in first.density:
		if id!=1:assert_bool(pruned.density.has(id)).is_true()
	assert_bool(pruned.detail.has(769)).is_true();assert_bool(pruned.density.has(385)).is_true()
	plots[0].status="vacant"
	var vacant:Dictionary=terrain._settlement_plot_admission(Vector3.ZERO,plots,1)
	assert_dict(vacant.detail).is_equal(pruned.detail)
	assert_bool(vacant.detail.has(2)).is_true()
	# A different city's same numeric plot IDs have their own retained sample.
	var other:Array[Dictionary]=[{"id":900,"status":"active","land_use":"residential_compound"}]
	var separate:Dictionary=terrain._settlement_plot_admission(Vector3(1,0,0),other,1)
	assert_array(separate.detail.keys()).is_equal([900])
	for index in 70:terrain._settlement_plot_admission(Vector3(index+2,0,0),other,1)
	assert_int(terrain.settlement_plot_admissions.size()).is_less_equal(64)
	GameState.world_seed+=1
	terrain._settlement_plot_admission(Vector3.ZERO,other,1)
	assert_int(terrain.settlement_plot_admissions.size()).is_equal(1)

func _fallback_roofs(terrain:Terrain,plot:Dictionary)->Dictionary:
	terrain.roofs.clear()
	var roof:=SurfaceTool.new();roof.begin(Mesh.PRIMITIVE_TRIANGLES)
	var wall:=SurfaceTool.new();wall.begin(Mesh.PRIMITIVE_TRIANGLES)
	var counts:Dictionary=terrain._append_satellite_roof_fabric(roof,wall,plot,Vector3(4,0,6),0)
	assert_int(int(counts.roofs)).is_equal(terrain.roofs.size())
	return terrain.roofs.duplicate(true)

func test_one_more_resident_keeps_existing_fallback_roof_geometry()->void:
	var terrain:=_terrain()
	var plot:Dictionary={"id":900,"seed":91,"centroid":Vector2.ZERO,
		"polygon":PackedVector2Array([Vector2(-.04,-.04),Vector2(.04,-.04),Vector2(.04,.04),Vector2(-.04,.04)]),
		"area_ha":.64,"roof_coverage":.18,"resident_count":22,"frontage_route_id":-1,
		"land_use":"residential_compound","form":"aggregate_household","material_family":"timber",
		"roof_plan":"timber_ridge","storeys":1,"fabric_generation":0,"status":"active","condition":1.0,"created_day":0.0}
	var first:=_fallback_roofs(terrain,plot)
	assert_int(first.size()).is_greater(0)
	var polygon:PackedVector2Array=plot.polygon.duplicate()
	plot.resident_count=23
	var next:=_fallback_roofs(terrain,plot)
	assert_array(Array(plot.polygon)).is_equal(Array(polygon))
	for id:int in first:
		assert_bool(next.has(id)).is_true()
		if next.has(id):assert_array(next[id]).is_equal(first[id])

func test_fallback_ignores_daily_route_and_culture_drift_and_infill_appends_slots()->void:
	var terrain:=_terrain()
	var plot:Dictionary={"id":900,"seed":91,"centroid":Vector2.ZERO,
		"polygon":PackedVector2Array([Vector2(-.04,-.04),Vector2(.04,-.04),Vector2(.04,.04),Vector2(-.04,.04)]),
		"area_ha":.12,"roof_coverage":.18,"resident_count":22,"frontage_route_id":1,
		"land_use":"residential_compound","form":"aggregate_household","material_family":"timber",
		"roof_plan":"timber_ridge","storeys":1,"fabric_generation":0,"status":"active","condition":1.0,"created_day":0.0}
	GameState.settlement_routes=[{"id":1,"active":true,"points":PackedVector2Array([Vector2(-.04,0),Vector2(.04,0)]),"traffic":.1,"condition":.1}]
	var first:=_fallback_roofs(terrain,plot)
	assert_int(first.size()).is_greater(0);assert_int(first.size()).is_less(14)
	GameState.settlement_routes[0].traffic=.95;GameState.settlement_routes[0].condition=.9
	terrain.live_architecture={"axiality":.95,"monumentality":.95,"civic_space":.95,"permeability":.95,"defensive_depth":.95,"terrain_conformity":.95}
	assert_dict(_fallback_roofs(terrain,plot)).is_equal(first)
	plots_infill(terrain,plot,first)

func plots_infill(terrain:Terrain,plot:Dictionary,first:Dictionary)->void:
	plot["infill_units"]=1
	var grown:=_fallback_roofs(terrain,plot)
	assert_int(grown.size()).is_equal(first.size()+1)
	for id:int in first:assert_array(grown[id]).is_equal(first[id])

func test_completed_early_form_change_keeps_remembered_house_positions()->void:
	var plots:Array[Dictionary]=[{"id":1,"seed":91,"centroid":Vector2.ZERO,
		"polygon":PackedVector2Array([Vector2(-.02,-.02),Vector2(.02,-.02),Vector2(.02,.02),Vector2(-.02,.02)]),
		"frontage_route_id":1,"area_ha":.16,"roof_coverage":.3,"resident_count":12,
		"material_family":"organic","land_use":"residential_compound","form":"timber_household",
		"roof_plan":"round_thatch","storeys":1,"status":"active","condition":1.0}]
	var routes:Array[Dictionary]=[{"id":1,"kind":"camp_path","width_m":.6,
		"points":PackedVector2Array([Vector2(-.025,0),Vector2(.025,0)])}]
	var dry:Callable=func(_point:Vector2)->bool:return true
	var initial:Dictionary=EARLY.layout(plots,routes,dry)
	assert_int(initial.buildings.size()).is_greater(0)
	EARLY.remember_layout(initial,plots)
	plots[0].form="earthen_household";plots[0].material_family="earth";plots[0].roof_plan="courtyard_flat"
	var final:Dictionary=EARLY.layout(plots,routes,dry)
	var by_id:Dictionary={}
	for record:Dictionary in final.buildings:by_id[record.id]=record
	for previous:Dictionary in initial.buildings:
		assert_bool(by_id.has(previous.id)).is_true()
		if not by_id.has(previous.id):continue
		var current:Dictionary=by_id[previous.id]
		assert_str(String(current.early_kind)).is_equal("earthen_household")
		assert_vector(current.position).is_equal(previous.position)
		assert_array(Array(current.footprint)).is_equal(Array(previous.footprint))
		var mesh:Mesh=EARLY.kit_mesh("earthen_household")
		var basis:Basis=EARLY.site_basis(current)
		for corner in 8:
			var point:Vector3=basis*mesh.get_aabb().get_endpoint(corner)
			assert_bool(Geometry2D.is_point_in_polygon(Vector2(point.x,point.z)+Vector2(current.position),current.footprint)).is_true()
	var parent:Node3D=auto_free(Node3D.new())
	EARLY.render(final,Vector3.ZERO,func(_x:float,_z:float)->float:return 0.0,parent)
	var rendered:MultiMeshInstance3D=parent.get_node("EarlySettlement_earthen_household")
	assert_int(rendered.multimesh.instance_count).is_equal(final.buildings.size())
	# Dummy rendering does not preserve MultiMesh server readback. These are
	# the exact transforms passed to set_instance_transform, also retained by
	# the construction and ordinary kit renderers for headless validation.
	var transforms:Array=rendered.get_meta("source_transforms")
	assert_int(transforms.size()).is_equal(final.buildings.size())
	for index in final.buildings.size():
		assert_bool((transforms[index] as Transform3D).basis.is_equal_approx(EARLY.site_basis(final.buildings[index]))).is_true()

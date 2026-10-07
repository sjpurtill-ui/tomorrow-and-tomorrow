extends GdUnitTestSuite
const Construction:=preload("res://scripts/settlement_construction_mesh.gd")
const Early:=preload("res://scripts/early_settlement_visual.gd")
const Late:=preload("res://scripts/settlement_architecture_kit.gd")

func before_test()->void:Construction.clear_cache()

func _vertices(mesh:Mesh)->PackedVector3Array:
	var vertices:=PackedVector3Array()
	for surface in mesh.get_surface_count():vertices.append_array(mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX])
	return vertices

func _roof_count(mesh:Mesh)->int:
	var count:=0
	for surface in mesh.get_surface_count():
		var colors:PackedColorArray=mesh.surface_get_arrays(surface)[Mesh.ARRAY_COLOR]
		for color:Color in colors:
			if color.a>=.915 and color.a<=.985:count+=1
	return count

func test_early_and_later_stages_keep_exact_footprint_and_return_original_roof_mesh()->void:
	var examples:Array=[
		{"source":Early.kit_mesh("carried_ridge"),"plot":{"material_family":"organic"}},
		{"source":Early.kit_mesh("raised_store"),"plot":{"material_family":"timber"}},
		{"source":Early.kit_mesh("covered_workshop"),"plot":{"material_family":"timber"}},
		{"source":Early.kit_mesh("round_household"),"plot":{"material_family":"timber"}},
		{"source":Early.kit_mesh("earthen_household"),"plot":{"material_family":"earth"}},
		{"source":Late.mesh_for("masonry_courtyard",3,0,"brick|tile"),"plot":{"material_family":"brick"}},
		{"source":Late.mesh_for("modern_terrace",8,0,"stone|slate"),"plot":{"material_family":"concrete"}}]
	for example:Dictionary in examples:
		var source:Mesh=example.source;var bounds:=source.get_aabb()
		var stages:Array[Mesh]=[]
		for stage in 3:
			var built:=Construction.mesh(source,example.plot,stage)
			assert_object(built).is_not_null()
			if built==null:continue
			stages.append(built)
			for vertex:Vector3 in _vertices(built):
				assert_bool(bounds.grow(.0001).has_point(vertex)).override_failure_message("Construction cannot grow or move the recorded footprint.").is_true()
			assert_int(int(built.get_meta("construction_stage"))).is_equal(stage)
		assert_int(stages.size()).is_equal(3)
		if stages.size()==3:
			assert_float(stages[0].get_aabb().end.y).is_less_equal(bounds.position.y+.241)
			assert_float(stages[1].get_aabb().end.y).is_greater(stages[0].get_aabb().end.y+.3)
		assert_object(Construction.mesh(source,example.plot,3)).is_same(source)
		assert_object(Construction.mesh(source,example.plot,4)).is_same(source)
		assert_object(Construction.retrofit_mesh(source,example.plot,0)).is_not_null()

func test_original_wall_vertices_and_materials_are_retained_without_roof_or_glass()->void:
	var source:=Late.mesh_for("masonry_corner",2,0,"brick|tile")
	var original:Dictionary={}
	for surface in source.get_surface_count():
		var arrays:=source.surface_get_arrays(surface)
		var points:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var colors:PackedColorArray=arrays[Mesh.ARRAY_COLOR]
		for index in points.size():original[str(points[index])+str(colors[index])]=true
	var walls:=Construction.mesh(source,{"material_family":"brick"},2)
	assert_int(_roof_count(source)).is_greater(0)
	assert_int(_roof_count(walls)).is_zero()
	for surface in walls.get_surface_count():
		var arrays:=walls.surface_get_arrays(surface)
		var points:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var colors:PackedColorArray=arrays[Mesh.ARRAY_COLOR]
		for index in points.size():assert_bool(original.has(str(points[index])+str(colors[index]))).is_true()
	assert_int(_vertices(walls).size()).is_less(_vertices(source).size())

func test_courtyard_frame_follows_wings_instead_of_filling_the_court()->void:
	var source:=Late.mesh_for("masonry_courtyard",3,0,"stone|tile")
	var frame:=Construction.mesh(source,{"material_family":"stone"},1)
	for vertex:Vector3 in _vertices(frame):
		if vertex.y<0.65:continue # the recorded yard and basin stay at ground level
		assert_bool(absf(vertex.x)<1.5 and vertex.z> -2.5 and vertex.z<3.0).is_false()
	assert_int(int(frame.get_meta("construction_frame_edges"))).is_between(1,Construction.MAX_FRAME_EDGES)

func test_refit_is_only_bounded_scaffolding_and_does_not_mutate_source_or_record()->void:
	var source:=Late.mesh_for("industrial_warehouse",2,0,"brick|slate")
	var plot:Dictionary={"material_family":"brick","status":"active","fabric_job":{"work":30,"required_work":100}}
	var before:=plot.duplicate(true);var source_before:=_vertices(source)
	var overlay:=Construction.retrofit_mesh(source,plot,1)
	assert_object(overlay).is_not_null()
	assert_bool(bool(overlay.get_meta("construction_retrofit_overlay"))).is_true()
	var limits:=source.get_aabb().grow(.121)
	for point:Vector3 in _vertices(overlay):assert_bool(limits.has_point(point)).is_true()
	assert_array(_vertices(source)).is_equal(source_before)
	assert_dict(plot).is_equal(before)
	assert_int(_roof_count(overlay)).is_zero()

func test_progress_changes_reuse_same_cached_milestone_geometry()->void:
	var source:=Early.kit_mesh("round_household")
	var a:Dictionary={"material_family":"timber","construction_progress":.26,"id":10}
	var b:Dictionary={"material_family":"timber","construction_progress":.49,"id":999}
	assert_object(Construction.mesh(source,a,1)).is_same(Construction.mesh(source,b,1))
	assert_object(Construction.mesh(source,a,0)).is_not_same(Construction.mesh(source,a,1))
	assert_object(Construction.retrofit_mesh(source,a,1)).is_not_same(Construction.mesh(source,a,1))
	assert_int(Construction._cache.size()).is_equal(3)

func test_frame_and_cache_have_hard_bounds_and_oversized_sources_are_rejected()->void:
	var source:=Late.mesh_for("modern_terrace",18,0,"stone|slate")
	var frame:=Construction.mesh(source,{"material_family":"concrete"},1)
	assert_object(frame).is_not_null()
	if frame!=null:
		var maximum:=int(frame.get_meta("construction_source_triangles"))*2+Construction.MAX_FRAME_EDGES*(Construction.MAX_FRAME_LEVELS+2)*12
		assert_int(int(frame.get_meta("construction_triangles"))).is_less_equal(maximum)
	for index in Construction.MAX_CACHE_ENTRIES+3:
		Construction._remember(Construction._cache,"bound%d" % index,source,Construction.MAX_CACHE_ENTRIES)
	assert_int(Construction._cache.size()).is_equal(Construction.MAX_CACHE_ENTRIES)
	var oversized:=ArrayMesh.new();var arrays:Array=[];arrays.resize(Mesh.ARRAY_MAX)
	var points:=PackedVector3Array();points.resize((Construction.MAX_SOURCE_TRIANGLES+1)*3)
	for index in points.size():points[index]=Vector3(float(index%3),float((index+1)%3),0)
	arrays[Mesh.ARRAY_VERTEX]=points;oversized.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	assert_object(Construction.mesh(oversized,{},1)).is_null()

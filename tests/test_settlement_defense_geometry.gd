extends GdUnitTestSuite

const Geometry:=preload("res://scripts/settlement_defense_geometry.gd")

# Exercise the actual mesh path without loading terrain, assets, or a player scene.
class SlopedTerrain extends "res://scripts/local_terrain.gd":
	func _ready()->void:pass
	func _process(_delta:float)->void:pass
	func _settlement_stage_land_at(_point:Vector2)->bool:return true
	func _close_surface_height_at(x:float,z:float)->float:return 0.4+x*0.03+z*0.02


func before_test()->void:
	GameState.reset_for_new_world(91357)


func _square()->PackedVector2Array:
	return PackedVector2Array([Vector2(-0.1,-0.1),Vector2(0.1,-0.1),Vector2(0.1,0.1),Vector2(-0.1,0.1)])


func _length(records:Array)->float:
	var result:=0.0
	for item:Dictionary in records:result+=float(item.end)-float(item.start)
	return result


func _surface()->SurfaceTool:
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	return surface


func _layout()->Dictionary:
	# Multiple district anchors used to produce three separate fortified islands.
	return {"radius":0.9,"axis":0.23,"seed":91357,
		"cores":[Vector2(-0.05,0),Vector2(0.06,0.01),Vector2(0.0,0.07)],
		"corridor_angles":[0.0,PI]}


func _plots()->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for index in 8:
		var at:=Vector2.from_angle(float(index)*TAU/8.0)*0.065
		var right:=Vector2(0.015,0)
		var forward:=Vector2(0,0.012)
		result.append({"id":index+1,"land_use":"residential_compound","status":"active",
			"centroid":at,"area_ha":0.072,
			"polygon":PackedVector2Array([at-right-forward,at+right-forward,at+right+forward,at-right+forward])})
	# A real long parcel corner must count; centroid/area approximations miss it.
	result[0].polygon=PackedVector2Array([Vector2(0.05,-0.012),Vector2(0.125,-0.012),Vector2(0.125,0.012),Vector2(0.05,0.012)])
	return result


func _draw(terrain:Node3D,stage:int=4,integrity:float=1.0,completion:float=1.0,constructing:bool=false)->Dictionary:
	return terrain._append_settlement_defense_visuals(_surface(),_surface(),Vector3.ZERO,
		_layout(),3670,stage,integrity,completion,constructing,_plots())


func test_whole_perimeter_has_shared_endpoints_and_no_missing_panels()->void:
	var result:=Geometry.outline_layout(_square(),[],0.006)
	assert_float(float(result.length)).is_equal_approx(0.8,0.000001)
	assert_array(result.gates).is_empty()
	assert_int(result.segments.size()).is_equal(4)
	assert_float(_length(result.segments)).is_equal_approx(0.8,0.000001)
	for index in result.segments.size():
		var current:Dictionary=result.segments[index]
		var next:Dictionary=result.segments[(index+1)%result.segments.size()]
		assert_vector(Vector2(current.b)).is_equal_approx(Vector2(next.a),Vector2.ONE*0.000001)


func test_gate_cuts_metres_of_wall_instead_of_deleting_a_whole_panel()->void:
	var bearings:Array[float]=[0.0,PI]
	var result:=Geometry.outline_layout(_square(),bearings,0.006)
	assert_int(result.gates.size()).is_equal(2)
	assert_float(_length(result.gates)).is_equal_approx(0.012,0.000001)
	assert_float(_length(result.segments)).is_equal_approx(0.788,0.000001)
	for gate:Dictionary in result.gates:
		assert_float(Vector2(gate.a).distance_to(Vector2(gate.b))).is_equal_approx(0.006,0.000001)
		# Both exact opening ends still meet a wall, rather than detached slabs.
		var before:=false
		var after:=false
		for segment:Dictionary in result.segments:
			before=before or Vector2(segment.b).is_equal_approx(Vector2(gate.a))
			after=after or Vector2(segment.a).is_equal_approx(Vector2(gate.b))
		assert_bool(before).is_true()
		assert_bool(after).is_true()


func test_gate_crossing_first_corner_keeps_exact_total_opening()->void:
	var bearings:Array[float]=[-3.0*PI/4.0]
	var result:=Geometry.outline_layout(_square(),bearings,0.008)
	assert_float(_length(result.gates)).is_equal_approx(0.008,0.000001)
	assert_float(_length(result.segments)).is_equal_approx(0.792,0.000001)
	# The opening wraps across the first/last edges, leaving the other two whole.
	var whole_edges:=0
	for segment:Dictionary in result.segments:
		if Vector2(segment.a).distance_to(Vector2(segment.b))>0.1999:whole_edges+=1
	assert_int(whole_edges).is_equal(2)


func test_damage_or_unbuilt_edges_are_omitted_without_bridging_them()->void:
	var result:=Geometry.outline_layout(_square(),[],0.006,PackedByteArray([1,0,1,0]))
	assert_int(result.segments.size()).is_equal(2)
	assert_float(_length(result.segments)).is_equal_approx(0.4,0.000001)
	for segment:Dictionary in result.segments:
		assert_int(int(segment.edge)%2).is_equal(0)
		assert_float(Vector2(segment.a).distance_to(Vector2(segment.b))).is_equal_approx(0.2,0.000001)


func test_shared_arc_anchors_follow_the_actual_edges_and_wrap()->void:
	assert_vector(Geometry.point_at(_square(),0.3)).is_equal_approx(Vector2(0.1,0),Vector2.ONE*0.000001)
	assert_vector(Geometry.point_at(_square(),1.1)).is_equal_approx(Vector2(0.1,0),Vector2.ONE*0.000001)
	assert_vector(Geometry.point_at(_square(),-0.1)).is_equal_approx(Vector2(-0.1,0),Vector2.ONE*0.000001)
	assert_vector(Geometry.tangent_at(_square(),0.3)).is_equal_approx(Vector2.DOWN,Vector2.ONE*0.000001)


func test_masonry_dimensions_are_house_scale_and_damage_never_enlarges_them()->void:
	var whole:=Geometry.dimensions(4)
	var damaged:=Geometry.dimensions(4,0.3)
	assert_float(float(whole.height)*1000.0).is_between(4.0,8.0)
	assert_float(float(whole.half_width)*2000.0).is_between(1.0,3.0)
	assert_float(float(whole.tower_height)*1000.0).is_between(float(whole.height)*1000.0,10.0)
	assert_float(float(whole.tower_half_width)*2000.0).is_between(3.0,6.0)
	assert_float(float(whole.gate_clear_width)*1000.0).is_between(3.0,8.0)
	assert_float(float(whole.base_lift)*1000.0).is_between(0.0,0.25)
	assert_float(float(damaged.height)).is_less_equal(float(whole.height))
	assert_float(float(damaged.tower_height)).is_less_equal(float(whole.tower_height))
	assert_float(float(Geometry.dimensions(3).height)*1000.0).is_between(2.0,4.5)


func test_completed_masonry_is_one_enclosure_covering_real_built_polygons()->void:
	var terrain:Node3D=auto_free(SlopedTerrain.new())
	var result:=_draw(terrain)
	assert_int(result.enclosures.size()).is_equal(1)
	if result.enclosures.size()!=1:return
	var ring:Dictionary=result.enclosures[0]
	var outline:PackedVector2Array=ring.outline
	assert_int(outline.size()).is_between(12,96)
	for plot:Dictionary in _plots():
		for point:Vector2 in plot.polygon:
			assert_bool(Geometry2D.is_point_in_polygon(point,outline)).is_true()
	assert_int(ring.segments.size()).is_greater(0)
	assert_int(ring.gates.size()).is_between(1,6)


func test_breaches_and_construction_reduce_wall_without_moving_the_enclosure()->void:
	var terrain:Node3D=auto_free(SlopedTerrain.new())
	var whole:=_draw(terrain)
	var damaged:=_draw(terrain,4,0.3)
	var building:=_draw(terrain,4,1.0,0.35,true)
	assert_int(whole.enclosures.size()).is_equal(1)
	assert_int(damaged.enclosures.size()).is_equal(1)
	assert_int(building.enclosures.size()).is_equal(1)
	if whole.enclosures.is_empty() or damaged.enclosures.is_empty() or building.enclosures.is_empty():return
	var reference:Dictionary=whole.enclosures[0]
	for partial:Dictionary in [damaged.enclosures[0],building.enclosures[0]]:
		assert_array(Array(partial.outline)).contains_exactly(Array(reference.outline))
		assert_float(_length(partial.segments)).is_between(0.00001,_length(reference.segments)-0.00001)
	assert_int(int(_draw(terrain,0).get("mass",-1))).is_equal(0)
	assert_int(int(_draw(terrain,4,1.0,0.0,true).get("mass",-1))).is_equal(0)


func test_gate_towers_touch_the_same_wall_and_leave_gate_passage_clear()->void:
	var terrain:Node3D=auto_free(SlopedTerrain.new())
	var result:=_draw(terrain)
	assert_int(result.enclosures.size()).is_equal(1)
	if result.enclosures.is_empty():return
	var ring:Dictionary=result.enclosures[0]
	var outline:PackedVector2Array=ring.outline
	assert_int(ring.towers.size()).is_between(2,7)
	for tower:Dictionary in ring.towers:
		var point:Vector2=tower.position
		var wall_distance:=INF
		for segment:Dictionary in ring.segments:
			wall_distance=minf(wall_distance,point.distance_to(Geometry2D.get_closest_point_to_segment(point,segment.a,segment.b)))
		assert_float(wall_distance).is_less_equal(0.000001)
		assert_vector(point).is_equal_approx(Geometry.point_at(outline,float(tower.distance)),Vector2.ONE*0.000001)
		for gate:Dictionary in ring.gates:
			var nearest:=Geometry2D.get_closest_point_to_segment(point,gate.a,gate.b)
			assert_float(point.distance_to(nearest)).is_greater_equal(float(tower.half_width)*0.95)


func test_emitted_wall_bases_follow_slope_and_use_normal_depth_testing()->void:
	var terrain:Node3D=auto_free(SlopedTerrain.new())
	var parent:Node3D=auto_free(Node3D.new())
	var surface:=_surface()
	var center:=Vector3(4.0,0.0,7.0)
	var dimensions:=Geometry.dimensions(4)
	terrain._append_settlement_defense_wall_segment(surface,center,Vector2(-0.05,0),Vector2(0.05,0),
		float(dimensions.half_width),float(dimensions.height),Color.GRAY)
	terrain._commit_settlement_surface(surface,"PersistentSettlementDefenseMassing",parent,false)
	var node:MeshInstance3D=parent.get_node_or_null("PersistentSettlementDefenseMassing")
	assert_object(node).is_not_null()
	if node==null:return
	assert_bool(node.material_override is StandardMaterial3D).is_true()
	assert_bool(node.material_override.no_depth_test).is_false()
	var vertices:PackedVector3Array=node.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var base_count:=0
	var roof_count:=0
	for vertex:Vector3 in vertices:
		var lift:=vertex.y-float(terrain._close_surface_height_at(vertex.x,vertex.z))
		if absf(lift-float(dimensions.base_lift))<0.000001:base_count+=1
		elif absf(lift-float(dimensions.base_lift)-float(dimensions.height))<0.000001:roof_count+=1
		else:assert_float(lift).is_between(0.0,float(dimensions.base_lift)+float(dimensions.height)+0.000001)
	assert_int(base_count).is_greater(0)
	assert_int(roof_count).is_greater(0)


func test_mitred_endpoints_do_not_twist_first_and_last_grounded_bays()->void:
	var terrain:Node3D=auto_free(SlopedTerrain.new())
	var surface:=_surface()
	var outline:=_square()
	var dimensions:=Geometry.dimensions(4)
	var half_width:=float(dimensions.half_width)
	terrain._append_settlement_defense_wall_segment(surface,Vector3.ZERO,outline[0],outline[1],
		half_width,float(dimensions.height),Color.GRAY,
		Geometry.side_at(outline,0.0,half_width),Geometry.side_at(outline,0.2,half_width))
	var mesh:=surface.commit()
	var vertices:PackedVector3Array=mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var roof_triangles:=0
	var orientation:=0.0
	for index in range(0,vertices.size(),3):
		var roof:=true
		for vertex:Vector3 in [vertices[index],vertices[index+1],vertices[index+2]]:
			var lift:=vertex.y-float(terrain._close_surface_height_at(vertex.x,vertex.z))
			roof=roof and absf(lift-float(dimensions.base_lift)-float(dimensions.height))<0.000001
		if not roof:continue
		var a:=Vector2(vertices[index].x,vertices[index].z)
		var b:=Vector2(vertices[index+1].x,vertices[index+1].z)
		var c:=Vector2(vertices[index+2].x,vertices[index+2].z)
		var signed_area:=(b-a).cross(c-a)
		if orientation==0.0:orientation=signf(signed_area)
		assert_float(signed_area*orientation).is_greater(0.0)
		roof_triangles+=1
	assert_int(roof_triangles).is_greater(4)

extends GdUnitTestSuite
const Figure=preload("res://scripts/hud/court_figure_3d.gd")
const Fit=preload("res://scripts/hud/court_tunic_fit.gd")
const Audit=preload("res://tools/court_acting_audit.gd")

func _part(f:Node,name:String)->MeshInstance3D:
	for p:MeshInstance3D in f._parts:
		if String(p.name)==name:return p
	return null

func test_all_tunics_ease_only_the_lower_front_without_changing_body_masks_or_skinning()->void:
	for variant:String in Figure.BODIES:
		var f:=Figure.new();add_child(f);f.setup({"variant":variant,"outfit":"robe","lit":false})
		var body:=_part(f,"Body");var body_source:=body.mesh;var body_data:Array=body.mesh.get("_surfaces").duplicate(true)
		var tunic:=_part(f,"tunic_body");var source:=tunic.mesh;var raw:Array=source.get("_surfaces").duplicate(true)
		f.look.outfit="tunic";f._dress();var fitted:=tunic.mesh
		assert_object(body.mesh).is_same(body_source)
		assert_bool(body.mesh.get("_surfaces")==body_data).is_true()
		assert_object(fitted).is_not_same(source)
		var changed:=0;var protected:=0
		for surface in source.get_surface_count():
			assert_bool(int(source.surface_get_format(surface))&Mesh.ARRAY_FLAG_COMPRESS_ATTRIBUTES==0).is_true()
			var before:=source.surface_get_arrays(surface);var after:=fitted.surface_get_arrays(surface)
			for channel in Mesh.ARRAY_MAX:
				if channel!=Mesh.ARRAY_VERTEX:assert_bool(before[channel]==after[channel]).is_true()
			assert_bool(source.surface_get_blend_shape_arrays(surface)==fitted.surface_get_blend_shape_arrays(surface)).is_true()
			for vertex in before[Mesh.ARRAY_VERTEX].size():
				var a:Vector3=before[Mesh.ARRAY_VERTEX][vertex];var b:Vector3=after[Mesh.ARRAY_VERTEX][vertex]
				assert_bool(a.x==b.x and a.y==b.y).is_true()
				assert_float(b.z-a.z).is_between(-.0000001,Fit.EASE_METRES*f._base_height/1.72+.0000001)
				if a!=b:
					changed+=1
					assert_float(a.z).is_greater(.015*f._base_height/1.72)
					assert_float(a.y).is_less(f._base_height*.59)
					assert_float(a.y).is_greater(source.get_aabb().position.y+.06*f._base_height/1.72)
				else:protected+=1
		assert_int(changed).is_greater(20);assert_int(protected).is_greater(500)
		assert_bool(source.get("_surfaces")==raw).is_true()
		assert_object(Fit.fitted(source,f._base_height)).is_same(fitted)
		f.look.outfit="hide";f._dress();assert_object(body.mesh).is_same(body_source)
		f.look.outfit="tunic";f._dress();assert_object(tunic.mesh).is_same(fitted)
		f.free()
	assert_int(Fit._cache.size()).is_less_equal(Fit.CACHE_LIMIT)

func _skinned(part:MeshInstance3D,f:Node3D)->Dictionary:
	var surface:=Audit._surface(part);var probe:=Audit._new_probe("ray","points")
	for vertex in surface.v.size():Audit._add_vertex(probe,part,f.skeleton,surface,vertex)
	Audit._finish(probe);var points:=Audit._skin(probe,Audit._pose(f.skeleton,false))
	for vertex in points.size():points[vertex]=f.skeleton.global_transform*points[vertex]
	return {"points":points,"triangles":surface.i}

func _distance(mesh:Dictionary,from:Vector3,direction:Vector3)->float:
	var nearest:=INF
	for index in range(0,mesh.triangles.size(),3):
		var a:Vector3=mesh.points[mesh.triangles[index]];var b:Vector3=mesh.points[mesh.triangles[index+1]];var c:Vector3=mesh.points[mesh.triangles[index+2]]
		var hit=Geometry3D.ray_intersects_triangle(from,direction,a,b,c)
		if hit!=null:nearest=minf(nearest,from.distance_to(hit))
	return nearest

func test_actual_walking_skin_spots_are_covered_by_cloth_instead_of_erased()->void:
	# Exact camera and original defect pixels from the normal-ink pose fixture.
	var camera:=Transform3D(Basis.from_euler(Vector3(deg_to_rad(-6.5),0,0)),Vector3.ZERO)
	var d:=maxf(4.6*1.05*.5/(tan(deg_to_rad(15))*1536.0/864.0),2.05*.62/tan(deg_to_rad(15)))
	camera.origin=Vector3(0,2.05*.5+d*tan(deg_to_rad(6.5)),d)
	for row in 2:
		var f:=Figure.new();add_child(f);f.setup({"variant":"male_adult" if row==0 else "female_adult","outfit":"tunic","lit":false,"stance":"stand","hair":"cropped","cloth":[Color("466557"),Color("ece5d4"),Color("a88949")]})
		f.player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL;f.play("walk_out",0.0,0.0)
		f.position=Vector3((float(row)-1.5)*1.1,0,0);f.rotation_degrees.y=-20;f.skeleton.force_update_all_bone_transforms()
		var center:=Vector2i(240,539) if row==0 else Vector2i(592,558)
		var body:=_skinned(_part(f,"Body"),f)
		var tunic:=_part(f,"tunic_body");var fixed:=tunic.mesh
		var fitted_mesh:=_skinned(tunic,f)
		tunic.mesh=tunic.get_meta(&"tunic_source_mesh");var original_mesh:=_skinned(tunic,f);tunic.mesh=fixed
		var reproduced:=0;var uncorrected:=0
		for x in range(center.x-4,center.x+5,2):
			for y in range(center.y-8,center.y+9,2):
				var direction:=camera.basis*Vector3((x-768)/432.0*tan(deg_to_rad(15)),(432-y)/432.0*tan(deg_to_rad(15)),-1).normalized()
				var body_distance:=_distance(body,camera.origin,direction)
				var source_distance:=_distance(original_mesh,camera.origin,direction)
				if body_distance>=source_distance-.0001:continue
				reproduced+=1
				var fitted_distance:=_distance(fitted_mesh,camera.origin,direction)
				if fitted_distance+.0001>=body_distance:uncorrected+=1
		print("TUNIC_RAY ",f.variant," original_protrusions=",reproduced," remaining=",uncorrected)
		assert_int(reproduced).is_greater(0)
		assert_int(uncorrected).is_equal(0)
		f.free()

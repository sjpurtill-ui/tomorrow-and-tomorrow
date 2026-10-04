extends GdUnitTestSuite
const Daylight=preload("res://scripts/hud/court_daylight.gd")
const CourtSet=preload("res://scripts/hud/court_set_3d.gd")

func test_daylight_uses_authored_openings_and_stops_at_the_floor()->void:
	var direction:=Vector3(.15,-.75,.62).normalized()
	var rays:=Daylight.build([[-3.0,1.4,1.2,2.8],[3.0,1.2,1.4,2.9]],direction,Color.WHITE,.055)
	assert_int(rays.size()).is_equal(2)
	for ray in rays:
		var arrays:=ray.mesh.surface_get_arrays(0)
		var points:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		assert_int(points.size()).is_equal(24)
		var floor_count:=0;var source_count:=0
		for point in points:
			assert_bool(point.is_finite()).is_true()
			assert_float(point.y).is_greater_equal(.0449)
			if absf(point.y-.045)<.0001:floor_count+=1
			if absf(point.z+3.78)<.0001:source_count+=1
		assert_int(floor_count).is_equal(12);assert_int(source_count).is_equal(12)
		assert_int(ray.cast_shadow).is_equal(GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
		ray.free()

func test_outward_light_or_missing_openings_cannot_make_a_ghost_beam()->void:
	for direction:Vector3 in [Vector3(0,-1,-1),Vector3(0,0,1),Vector3(0,1,1)]:
		assert_array(Daylight.build([[0,1,1,2]],direction,Color.WHITE,.06)).is_empty()
	assert_array(Daylight.build([],Vector3(0,-1,1),Color.WHITE,.06)).is_empty()
	assert_array(Daylight.build([[0,1,2,1],[1,-2,1,2]],Vector3(0,-1,1),Color.WHITE,.06)).is_empty()

func test_many_openings_are_bounded_and_renewal_mirrors_the_rays()->void:
	var openings:=[[-4.0,1,1,3],[-2.0,1,1,3],[0,1,1,3],[2.0,1,1,3],[4.0,1,1,3]]
	var rays:=Daylight.build(openings,Vector3(0,-1,1).normalized(),Color.WHITE,.06,-3.78,-1.04)
	assert_int(rays.size()).is_equal(Daylight.MAX_RAYS)
	assert_float(rays[0].mesh.get_aabb().get_center().x).is_equal_approx(4.16,.001)
	assert_float(rays[1].mesh.get_aabb().get_center().x).is_equal_approx(-4.16,.001)
	for ray in rays:ray.free()

func _room()->Node3D:
	var made:=CourtSet.build("chapter_15",{"dogs":false,"herds":false,"fowl":false,"chapter":{"set_kind":"chapter_15","index":15,"design":15,"capabilities":{}}})
	add_child(made);auto_free(made)
	return made

func test_hard_finishes_differ_from_paper_and_plaster()->void:
	var room:=_room()
	assert_float(float(room._material("WINDOW_GLASS",false).get_shader_parameter("glazing"))).is_greater(.1)
	for slot in ["METAL","BRONZE","CERAMIC"]:
		assert_float(float(room._material(slot,false).get_shader_parameter("sheen_amount"))).is_greater(.05)
	for slot in ["PAPER","PLASTER","HIDE"]:
		var sheen:Variant=room._material(slot,false).get_shader_parameter("sheen_amount")
		assert_float(0.0 if sheen==null else float(sheen)).is_equal(0.0)

func test_window_fill_yields_to_the_gods_voice_and_returns_exactly()->void:
	var room:=_room();var before:Array=[]
	assert_int(room.fill_lights.size()).is_greater(0)
	for fill in room.fill_lights:before.append(fill.light_energy)
	room.god_light(Vector3(0,1,0),"wrath",0.0,0.0)
	for i in before.size():assert_float(room.fill_lights[i].light_energy).is_less(float(before[i])*.8)
	room.god_light(null,"off",0.0,0.0)
	for i in before.size():assert_float(room.fill_lights[i].light_energy).is_equal_approx(float(before[i]),.00001)

func test_authored_daylight_obeys_quality_and_divine_focus()->void:
	var room:=_room()
	assert_int(room._window_daylight.size()).is_between(1,Daylight.MAX_RAYS)
	var strengths:Array=[]
	for ray:MeshInstance3D in room._window_daylight:
		strengths.append(float(ray.material_override.get_shader_parameter("strength")))
	room.set_quality("low")
	for ray:MeshInstance3D in room._window_daylight:assert_bool(ray.visible).is_false()
	room.set_quality("high")
	for ray:MeshInstance3D in room._window_daylight:assert_bool(ray.visible).is_true()
	room.god_light(Vector3(0,1,0),"wrath",0.0,0.0)
	for i in strengths.size():
		assert_float(float(room._window_daylight[i].material_override.get_shader_parameter("strength"))).is_less(float(strengths[i])*.5)
	room.god_light(null,"off",0.0,0.0)
	for i in strengths.size():
		assert_float(float(room._window_daylight[i].material_override.get_shader_parameter("strength"))).is_equal_approx(float(strengths[i]),.00001)

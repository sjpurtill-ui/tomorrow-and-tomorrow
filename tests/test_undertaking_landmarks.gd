extends GdUnitTestSuite
const Sites=preload("res://scripts/undertaking_sites.gd")
const Visual=preload("res://scripts/undertaking_map_visual.gd")
const Catalog=preload("res://scripts/undertaking_catalog.gd")
func test_site_search_is_stable_avoids_water_slopes_and_other_sites()->void:
	var city:={"id":"test","position":Vector2(10,10),"undertakings":[]}
	var height:=func(_p:Vector2)->float:return 0.0
	var land:=func(p:Vector2)->bool:return p.x>=10
	var first:=Sites.choose(city,[],17,height,land)
	assert_dict(first).is_not_empty()
	assert_dict(Sites.choose(city,[],17,height,land)).is_equal(first)
	assert_float(first.position.x-Sites.RADIUS).is_greater_equal(10.0)
	city.undertakings=[{"site":first}]
	var second:=Sites.choose(city,[],17,height,land)
	assert_dict(second).is_not_empty()
	assert_float(first.position.distance_to(second.position)).is_greater_equal(.165)
	assert_dict(Sites.choose(city,[],17,height,func(_p:Vector2)->bool:return false)).is_empty()
	assert_dict(Sites.choose(city,[],17,func(p:Vector2)->float:return p.x,land)).is_empty()
	assert_bool(Sites.valid({"position":Vector2(NAN,0),"angle":0.0})).is_false()
func test_every_landmark_batches_geometry_and_stays_human_scale()->void:
	var city:={"id":"test","position":Vector2.ZERO,"undertakings":[]}
	for d:Dictionary in Catalog.all():city.undertakings.append({"id":d.id,"status":"functioning","progress":d.work,"condition":1.0})
	var before:Dictionary=city.duplicate(true)
	var parent:=Node3D.new();add_child(parent)
	Visual.render([city],parent,func(_x:float,_z:float)->float:return .15)
	assert_int(parent.get_child_count()).is_equal(Catalog.all().size())
	for root:Node3D in parent.get_children():
		assert_int(root.get_child_count()).is_equal(2)
		var mesh:MeshInstance3D=root.get_node("Landmark")
		assert_int(mesh.mesh.get_surface_count()).is_equal(1)
		assert_float(mesh.mesh.get_aabb().size.x).is_less(.14)
		assert_float(mesh.mesh.get_aabb().size.z).is_less(.14)
		assert_float(mesh.mesh.get_aabb().size.y).is_less(.04)
		assert_int(mesh.mesh.surface_get_array_len(0)).is_less(15000)
	assert_dict(city).is_equal(before)
	parent.free()
func test_visual_cache_ignores_daily_noise_but_tracks_construction_and_name()->void:
	var r:={"id":"ancestor_ring","status":"building","progress":1.0,"condition":1.0}
	var cities:Array=[{"id":"test","position":Vector2.ZERO,"undertakings":[r]}]
	var first:=Visual.signature(cities)
	r.last_day=50;r.last_work=2.0;r.progress=3.0
	assert_str(Visual.signature(cities)).is_equal(first)
	r.progress=400.0
	assert_str(Visual.signature(cities)).is_not_equal(first)
	var next:=Visual.signature(cities)
	r.custom_name="A remembered name"
	assert_str(Visual.signature(cities)).is_not_equal(next)

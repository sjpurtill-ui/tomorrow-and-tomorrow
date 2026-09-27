extends GdUnitTestSuite
## Close woods (codex/beauty-2): 3D crowns streamed around the camera in
## bounded chunks, grown from each world cell's own seed, fading in over the
## painted canopy and stepping aside inside the home patch.
const Woods:=preload("res://scripts/close_woods.gd")
const Cover:=preload("res://scripts/landscape_cover.gd")

class Host extends Node3D:
	const SEA_LEVEL:=0.0
	var camera:=Camera3D.new()
	var camera_target:=Vector3(10.0,0.2,-4.0)
	var close_vegetation_center:=Vector2(INF,INF)
	var close_vegetation_root:Node3D=null
	var woodland:=0.9
	var materials_made:=0
	func _init()->void:
		add_child(camera)
		camera.size=0.2
	func _biome_at(_x:float,_z:float,_h:float=NAN)->Dictionary:
		return {"id":"temperate_forest","woodland":woodland,"temperature":0.55,"precipitation":0.7}
	func _vegetation_climate(_p:Vector3)->Color:return Color(0.55,0.7,0.0,0.0)
	func _close_surface_height_at(_x:float,_z:float)->float:return 0.2
	func _camera_in_motion()->bool:return false
	func _create_irregular_canopy_mesh(radius:float,height:float)->Mesh:
		var mesh:=SphereMesh.new();mesh.radius=radius;mesh.height=height
		return mesh
	func _vegetation_surface_material(_kind:int,_variant:=-1)->ShaderMaterial:
		materials_made+=1
		var material:=ShaderMaterial.new()
		material.shader=Shader.new()
		material.shader.code="shader_type spatial;\nuniform float lod_fade;\nuniform vec4 close_patch;\nvoid fragment(){ALBEDO=vec3(lod_fade)+close_patch.xyz*0.0;}"
		return material

func _host()->Host:
	var host:Host=auto_free(Host.new())
	add_child(host)
	return host

func _build_all(layer:Node)->void:
	for i in 400:
		layer._frame(1.0/60.0)
		if layer.queue.is_empty():break

func test_chunks_are_bounded_and_fade_in()->void:
	var host:=_host()
	var layer:Node=Woods.ensure(host)
	assert_object(layer).is_not_null()
	_build_all(layer)
	var report:Dictionary=layer.report()
	assert_int(int(report.queued)).is_equal(0)
	assert_int(int(report.chunks)).is_less_equal(Woods.MAX_CHUNKS)
	assert_int(int(report.built)).is_greater(0)
	assert_int(int(report.crowns)).is_less_equal(int(report.built)*Woods.MAX_CROWNS_PER_CHUNK)
	# Materials come from a bounded pool: one per built chunk at most.
	assert_int(host.materials_made).is_less_equal(int(report.built))
	# Fading in over time, never popping in at full strength.
	for cell in layer.chunks:
		var record:Dictionary=layer.chunks[cell]
		if int(record.get("crowns",0))>0:assert_float(float(record.fade)).is_greater(0.0)

func test_the_same_cell_always_grows_the_same_trees()->void:
	var host:=_host()
	var layer:Node=Woods.ensure(host)
	var cell:=Vector2i(62,-25)
	var a:={"cell":cell,"cursor":0}
	var b:={"cell":cell,"cursor":0}
	while not layer._build_step(a,Time.get_ticks_usec(),1000000):pass
	while not layer._build_step(b,Time.get_ticks_usec(),1000000):pass
	assert_int((a.transforms as Array).size()).is_greater(0)
	assert_array(a.transforms).is_equal(b.transforms)

func test_open_ground_grows_no_crowns_and_the_home_patch_keeps_its_own()->void:
	var host:=_host()
	var layer:Node=Woods.ensure(host)
	host.woodland=0.0
	var open:={"cell":Vector2i(62,-25),"cursor":0}
	while not layer._build_step(open,Time.get_ticks_usec(),1000000):pass
	assert_int((open.transforms as Array).size()).is_equal(0)
	host.woodland=0.9
	host.close_vegetation_root=auto_free(Node3D.new())
	host.close_vegetation_center=Vector2(62.5*Woods.CHUNK_KM,-24.5*Woods.CHUNK_KM)
	var home:={"cell":Vector2i(62,-25),"cursor":0}
	while not layer._build_step(home,Time.get_ticks_usec(),1000000):pass
	for t:Transform3D in home.transforms:
		assert_float(Vector2(t.origin.x,t.origin.z).distance_to(host.close_vegetation_center)).is_greater(Cover.PATCH_INNER_KM)

func test_zooming_out_hides_the_layer()->void:
	var host:=_host()
	var layer:Node=Woods.ensure(host)
	_build_all(layer)
	host.camera.size=5.0
	for i in 60:layer._frame(1.0/30.0)
	assert_int(int(layer.report().visible)).is_equal(0)

extends SceneTree

func _initialize()->void:
	call_deferred("capture")

func capture()->void:
	var scene:=Node3D.new()
	root.add_child(scene)
	var renderer:Node3D=load("res://scripts/local_terrain.gd").new()
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=0.21
	camera.position=Vector3(0,1,0)
	scene.add_child(camera)
	camera.look_at(Vector3.ZERO,Vector3.FORWARD)
	var environment:=WorldEnvironment.new()
	environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color("637049")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_energy=0.6
	scene.add_child(environment)
	var sun:=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-55,-25,0)
	scene.add_child(sun)
	for tier in 6:
		var parent:=Node3D.new()
		scene.add_child(parent)
		var routes:Array[Dictionary]=[{"active":true,"kind":"desire_path","hierarchy":"main_approach","surface_tier":tier,"condition":0.8,"points":PackedVector2Array([Vector2(-0.10,0),Vector2(0.10,0)])}]
		renderer._create_persistent_settlement_routes(Vector3.ZERO,routes,parent)
		var patch:=parent.get_node("PersistentDesirePaths") as MeshInstance3D
		# Flatten only the test strip; keep production width, color and material.
		var arrays:=patch.mesh.surface_get_arrays(0)
		var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		for index in vertices.size(): vertices[index].y=0.0
		arrays[Mesh.ARRAY_VERTEX]=vertices
		var mesh:=ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		patch.mesh=mesh
		parent.position.z=(float(tier)-2.5)*0.033
		var label:=Label3D.new()
		label.text="SURFACE TIER %d" % tier
		label.font_size=12
		label.fixed_size=true
		label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		label.position=Vector3(0,0.001,parent.position.z+0.012)
		scene.add_child(label)
	for frame in 8: await process_frame
	await RenderingServer.frame_post_draw
	var path:=ProjectSettings.globalize_path("res://artifacts/road-materials.png")
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var result:=root.get_texture().get_image().save_png(path)
	renderer.free()
	print("ROAD_MATERIAL_CAPTURE ",path," result=",result)
	quit(result)

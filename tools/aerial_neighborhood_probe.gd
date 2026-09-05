extends SceneTree

func _initialize()->void:
	call_deferred("capture")

func capture()->void:
	var scene:=Node3D.new()
	root.add_child(scene)
	# Load after autoload registration; the production terrain references them.
	var renderer:Node3D=load("res://scripts/local_terrain.gd").new()
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=1.85
	camera.position=Vector3(0,3,0)
	scene.add_child(camera)
	camera.look_at(Vector3.ZERO,Vector3.FORWARD)
	renderer.camera=camera
	var environment:=WorldEnvironment.new()
	environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color("172422")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color=Color("e3d9be")
	environment.environment.ambient_light_energy=0.6
	scene.add_child(environment)
	var sun:=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-55,-25,0)
	scene.add_child(sun)
	var names:=["GREAT","OKAY","FINE","NORMAL","BAD","POOR","DAMAGED","DESTROYED"]
	for condition in 8:
		var center:=Vector3((float(condition%4)-1.5)*0.73,0,(float(condition/4)-0.5)*0.82)
		var surface:=SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for offset in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,-1),Vector2(1,1),Vector2(-1,1)]:
			surface.set_normal(Vector3.UP)
			surface.set_color(Color(0.50,0.44,0.34,0.72))
			surface.set_uv(Vector2.ZERO)
			surface.set_uv2(Vector2(0,8.0+(float(condition)+0.31)/16.0))
			surface.add_vertex(center+Vector3(offset.x*0.32,0,offset.y*0.32))
		var patch:=MeshInstance3D.new()
		patch.mesh=surface.commit()
		patch.material_override=renderer._settlement_fabric_material(5,0.48)
		scene.add_child(patch)
		var label:=Label3D.new()
		label.text=names[condition]
		label.font_size=22
		label.fixed_size=true
		label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		label.position=center+Vector3(0,0.02,0.35)
		scene.add_child(label)
	for frame in 8: await process_frame
	await RenderingServer.frame_post_draw
	var filename:="neighborhood-conditions.png"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): filename=argument.trim_prefix("--output=").get_file()
	var path:=ProjectSettings.globalize_path("res://artifacts/"+filename)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var result:=root.get_texture().get_image().save_png(path)
	renderer.free()
	print("NEIGHBORHOOD_CAPTURE ",path," result=",result)
	quit(result)

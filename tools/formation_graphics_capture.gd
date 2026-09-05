extends SceneTree

func _initialize()->void:
	call_deferred("capture")

func capture()->void:
	var scene:=Node3D.new()
	root.add_child(scene)
	var environment:=WorldEnvironment.new()
	environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color("172422")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color=Color("e3d9be")
	environment.environment.ambient_light_energy=0.6
	scene.add_child(environment)
	var light:=DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-55,-25,0)
	light.shadow_enabled=true
	scene.add_child(light)
	var floor_mesh:=MeshInstance3D.new()
	var plane:=PlaneMesh.new()
	plane.size=Vector2(200,200)
	floor_mesh.mesh=plane
	var material:=StandardMaterial3D.new()
	material.albedo_color=Color("48523c")
	floor_mesh.material_override=material
	floor_mesh.position.y=-0.05
	scene.add_child(floor_mesh)
	var figures:=ArmyFigureFormation.new()
	scene.add_child(figures)
	figures.configure({"line_infantry":700,"skirmisher":200,"cavalry":100,"siege_engineer":30},Color("b84736"))
	figures.set_process(false)
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=25
	camera.position=Vector3(24,36,36)
	scene.add_child(camera)
	camera.look_at(Vector3.ZERO)
	for frame in 15: await process_frame
	await RenderingServer.frame_post_draw
	var path:="C:/Users/sjpur/tt-gameplay-graphics/artifacts/formation-review.png"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="): path=arg.trim_prefix("--capture=")
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var result:=root.get_texture().get_image().save_png(path)
	print("FORMATION_CAPTURE ",path," result=",result)
	quit(result)

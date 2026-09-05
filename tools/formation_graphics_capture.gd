extends SceneTree

func _initialize()->void:
	call_deferred("capture")

func capture()->void:
	var preset:="mixed"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--preset="): preset=arg.trim_prefix("--preset=")
	var compositions:={
		"mixed":{"line_infantry":700,"skirmisher":200,"cavalry":100,"siege_engineer":30},
		"classical":{"pike_phalanx":800,"legionary_infantry":700,"war_elephant":150,"battering_ram":80},
		"medieval":{"armored_foot":800,"longbowman":500,"cavalry":250,"counterweight_trebuchet":120},
		"industrial":{"rifle_infantry":1200,"machine_gun_company":300,"field_artillery":200,"motorized_infantry":250},
		"siege":{"counterweight_trebuchet":1000,"bombard":1000,"siege_tower":500},
	}
	if not compositions.has(preset):
		push_error("Unknown formation capture preset: "+preset)
		quit(1)
		return
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
	figures.configure(compositions[preset],Color("b84736"))
	figures.set_process(false)
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	# Include the full layout rather than accidentally cropping long support
	# formations. Figure asset bounds also include animation/projectile padding.
	var layout_extent:=Vector2.ZERO
	for batch:MultiMeshInstance3D in figures.batches.values():
		for index in batch.multimesh.instance_count:
			var point:=batch.multimesh.get_instance_transform(index).origin
			layout_extent.x=maxf(layout_extent.x,absf(point.x))
			layout_extent.y=maxf(layout_extent.y,absf(point.z))
	camera.size=maxf(25.0,maxf(layout_extent.x,layout_extent.y)*2.4+16.0)
	plane.size=Vector2.ONE*maxf(200.0,camera.size*3.0)
	camera.position=Vector3(24,36,36)
	scene.add_child(camera)
	camera.look_at(Vector3.ZERO)
	for frame in 15: await process_frame
	await RenderingServer.frame_post_draw
	var path:=ProjectSettings.globalize_path("res://artifacts/formation-"+preset+".png")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="): path=arg.trim_prefix("--capture=")
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var result:=root.get_texture().get_image().save_png(path)
	print("FORMATION_CAPTURE ",path," result=",result)
	quit(result)

extends SceneTree

func _initialize()->void:
	call_deferred("capture")

func capture()->void:
	var scene:=Node3D.new()
	root.add_child(scene)
	var renderer:Node3D=load("res://scripts/local_terrain.gd").new()
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=0.18
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
	var phases:=["prepared","growing","mature","harvested","fallow","stressed"]
	for index in phases.size():
		var center:=Vector3((float(index%3)-1.0)*0.085,0,(float(index/3)-0.5)*0.086)
		var plot:={"land_use":"field","cultivation_phase":phases[index],"crop_family":"grain","seed":13,"id":4,"condition":1.0,"prosperity":0.4,"status":"active"}
		var color:Color=renderer._settlement_plot_color(plot)
		var surface:=SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for offset in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,-1),Vector2(1,1),Vector2(-1,1)]:
			surface.set_normal(Vector3.UP)
			surface.set_color(color)
			surface.set_uv(Vector2(0.125,0.625))
			surface.set_uv2(Vector2.ZERO)
			surface.add_vertex(center+Vector3(offset.x*0.036,0,offset.y*0.031))
		var patch:=MeshInstance3D.new()
		patch.mesh=surface.commit()
		patch.material_override=renderer._settlement_fabric_material(1,0.74)
		scene.add_child(patch)
		var label:=Label3D.new()
		label.text=phases[index].to_upper()
		label.font_size=18
		label.fixed_size=true
		label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		label.position=center+Vector3(0,0.001,0.037)
		scene.add_child(label)
	for frame in 8: await process_frame
	await RenderingServer.frame_post_draw
	var filename:="field-materials.png"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): filename=argument.trim_prefix("--output=").get_file()
	var path:=ProjectSettings.globalize_path("res://artifacts/"+filename)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var result:=root.get_texture().get_image().save_png(path)
	renderer.free()
	print("FIELD_MATERIAL_CAPTURE ",path," result=",result)
	quit(result)

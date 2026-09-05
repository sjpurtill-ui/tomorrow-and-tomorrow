extends SceneTree

func _initialize()->void:
	call_deferred("capture")

func capture()->void:
	var scene:=Node3D.new()
	root.add_child(scene)
	var renderer:Node3D=load("res://scripts/local_terrain.gd").new()
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=0.030
	camera.position=Vector3(0,1,0)
	scene.add_child(camera)
	camera.look_at(Vector3.ZERO,Vector3.FORWARD)
	var sun:=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-60,-25,0)
	scene.add_child(sun)
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for point in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,-1),Vector2(1,1),Vector2(-1,1)]:
		surface.set_normal(Vector3.UP)
		surface.set_color(Color(0.6,0.5,0.35,0.9))
		surface.set_uv(Vector2(0.03,0.03)+(point+Vector2.ONE)*0.09)
		surface.set_uv2(Vector2.ZERO)
		surface.add_vertex(Vector3(point.x*0.035,0,point.y*0.020))
	var roof:=MeshInstance3D.new()
	roof.mesh=surface.commit()
	roof.material_override=renderer._settlement_fabric_material(3,0.62)
	roof.material_override.render_priority=4
	scene.add_child(roof)
	var front:Node3D=renderer._create_warfare_front_marker("LayerProbe")
	front.scale=Vector3.ONE*0.002
	front.get_node("FrontLabel").visible=false
	scene.add_child(front)
	for frame in 8: await process_frame
	await RenderingServer.frame_post_draw
	var filename:="front-layer.png"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): filename=argument.trim_prefix("--output=").get_file()
	var path:=ProjectSettings.globalize_path("res://artifacts/"+filename)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var result:=root.get_texture().get_image().save_png(path)
	renderer.free()
	print("FRONT_LAYER_CAPTURE ",path," result=",result)
	quit(result)

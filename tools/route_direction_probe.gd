extends SceneTree

func _initialize()->void:
	call_deferred("capture")

func capture()->void:
	var scene:=Node3D.new()
	root.add_child(scene)
	var renderer:Node3D=load("res://scripts/local_terrain.gd").new()
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=70.0
	camera.position=Vector3(0,100,0)
	scene.add_child(camera)
	camera.look_at(Vector3.ZERO,Vector3.FORWARD)
	var environment:=WorldEnvironment.new()
	environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color("22342d")
	scene.add_child(environment)
	var sun:=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-60,-25,0)
	scene.add_child(sun)
	var directions:=[Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT]
	var names:=["NORTH","EAST","SOUTH","WEST"]
	for row in 2:
		for column in 4:
			var center:=Vector3((float(column)-1.5)*23,0,(float(row)-0.5)*30)
			var delta:=Vector3(directions[column].x,0,directions[column].y)*8
			var start:=center-delta
			var finish:=center+delta
			var path:Node3D
			if row==0:
				path=renderer._create_player_field_army_path({"id":"probe","scale":1.0},start,finish,"local")
				path.get_node("MovementObjective").visible=false
			else:
				path=renderer._create_player_scout_route_marker({"mission_id":"probe"},[{"x":start.x,"z":start.z},{"x":finish.x,"z":finish.z}],"local")
				path.get_node("ScoutOrderLabel").visible=false
			scene.add_child(path)
			var label:=Label3D.new()
			label.text=("ARMY " if row==0 else "SCOUT ORDER ")+names[column]
			label.font_size=24
			label.pixel_size=0.0025
			label.fixed_size=true
			label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
			label.position=center+Vector3(0,0,11)
			scene.add_child(label)
	for frame in 8: await process_frame
	await RenderingServer.frame_post_draw
	var filename:="route-directions.png"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): filename=argument.trim_prefix("--output=").get_file()
	var path:=ProjectSettings.globalize_path("res://artifacts/"+filename)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var result:=root.get_texture().get_image().save_png(path)
	renderer.free()
	print("ROUTE_DIRECTION_CAPTURE ",path," result=",result)
	quit(result)

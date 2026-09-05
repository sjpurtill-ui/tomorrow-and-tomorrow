extends SceneTree

func _initialize()->void:
	call_deferred("capture")

func capture()->void:
	var scene:=Node3D.new()
	root.add_child(scene)
	var renderer:Node3D=load("res://scripts/local_terrain.gd").new()
	var units:Array=preload("res://scripts/military_unit_catalog.gd").ARCHETYPES.keys()
	var rows:=ceili(float(units.size())/4.0)
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	camera.fov=35.0
	camera.size=float(rows)*19.0+4.0
	camera.position=Vector3(0,camera.size/(2.0*tan(deg_to_rad(35.0)*0.5)),0)
	scene.add_child(camera)
	camera.look_at(Vector3.ZERO,Vector3.FORWARD)
	renderer.camera=camera
	var environment:=WorldEnvironment.new()
	environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color("22342d")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_energy=0.6
	scene.add_child(environment)
	var sun:=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-55,-25,0)
	scene.add_child(sun)
	for index in units.size():
		var center:=Vector3((float(index%4)-1.5)*16.0,0,(float(index/4)-float(rows-1)*0.5)*19.0)
		var marker:Node3D=renderer._create_warfare_formation_marker("Icon%d" % index,true)
		scene.add_child(marker)
		marker.position=center
		var army:={"army_id":index+1,"troops":1200,"readiness":0.85,"supply_level":0.8,"formations":[{"unit":units[index],"count":1200}]}
		var view:=WarfareMapPresentation.player_marker(army,60.0)
		view.show_label=false
		renderer._apply_warfare_formation_view(marker,view)
		var label:=Label3D.new()
		label.text=String(units[index]).replace("_"," ").to_upper()
		label.font_size=32
		label.pixel_size=0.0003125
		label.outline_size=6
		label.fixed_size=true
		label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		label.position=center+Vector3(0,0.1,6.0)
		scene.add_child(label)
	for frame in 8: await process_frame
	await RenderingServer.frame_post_draw
	var filename:="military-glyphs.png"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): filename=argument.trim_prefix("--output=").get_file()
	var path:=ProjectSettings.globalize_path("res://artifacts/"+filename)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var result:=root.get_texture().get_image().save_png(path)
	renderer.free()
	print("MILITARY_GLYPH_CAPTURE ",path," result=",result)
	quit(result)

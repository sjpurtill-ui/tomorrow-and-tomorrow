extends Node3D
## Private-desktop shader/pose proof, not a playable game or historical census.
const Costumes = preload("res://scripts/hud/people_settlement_costumes.gd")
const Ink = preload("res://scripts/map_life_ink.gd")
var paints: Array[ShaderMaterial] = []

func _ready() -> void:
	if "test" not in OS.get_user_data_dir().to_lower(): push_error("Test user data required"); get_tree().quit(2); return
	get_window().size = Vector2i(1800,1100)
	get_window().content_scale_size = Vector2i(1800,1100)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("353b31")
	add_child(world)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 0.014
	camera.position = Vector3(0,0,0.04)
	camera.near = 0.0001
	add_child(camera)
	camera.look_at(Vector3.ZERO)
	camera.make_current()
	var labels := CanvasLayer.new()
	add_child(labels)
	var painterly := "--painterly" in OS.get_cmdline_user_args()
	var stages: Array = [[],["bone_needle_sewing","cordage"],["plain_weaving","cordage"],["plain_weaving","bone_needle_sewing","garment_pattern_cutting","cordage"]]
	var poses: Array = [100,0,0,100,2,4,3,7,8] if painterly else [0,1,2,4,5,7]
	for row in stages.size():
		var look := Costumes.appearance(stages[row], {"coverage": 1.0})
		var shader := Shader.new()
		shader.code = Costumes.painterly_shader_code() if painterly else Costumes.shader_code()
		var paint := ShaderMaterial.new()
		paint.shader = shader
		if painterly:
			paint.set_shader_parameter("people_atlas",Costumes.atlas_texture())
			paint.set_shader_parameter("people_frames",Costumes.atlas_layout())
			for parameter:String in Costumes.motion_uniforms():paint.set_shader_parameter(parameter,Costumes.motion_uniforms()[parameter])
		paint.set_shader_parameter("map_people_visible",true)
		paint.set_shader_parameter("min_px",9.0)
		paint.set_shader_parameter("max_swell",1.3)
		for key: String in look.uniforms: paint.set_shader_parameter(key,look.uniforms[key])
		paints.append(paint)
		var batch := MultiMesh.new()
		batch.transform_format = MultiMesh.TRANSFORM_3D
		batch.use_custom_data = true
		batch.use_colors = true
		batch.mesh = Ink.quad()
		batch.instance_count = poses.size()
		for column in poses.size():
			batch.set_instance_transform(column,Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*0.001),Vector3(-0.009+column*(.018/(poses.size()-1)),0.0041-row*0.0033,0)))
			var phase_column := 2 if painterly and column==3 else column
			var carried := column in [2,3] if painterly else column==0
			batch.set_instance_custom_data(column,Color(fmod(phase_column*0.618,1.0),poses[column],1.0 if carried else 0.0,0.75))
			batch.set_instance_color(column,look.palette[column%look.palette.size()])
		var people := MultiMeshInstance3D.new()
		people.multimesh = batch
		people.material_override = paint
		people.custom_aabb = AABB(Vector3(-0.1,-0.1,-0.1),Vector3.ONE*0.2)
		add_child(people)
		var title := Label.new()
		title.text = "TEST · " + String(look.style)
		title.position = Vector2(32,20+row*259)
		title.add_theme_font_size_override("font_size",21)
		labels.add_child(title)
	for i in 10: await get_tree().process_frame
	for time: float in [0.0,0.65]:
		for paint in paints: paint.set_shader_parameter("anim_clock",time)
		for i in 4: await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var frame := get_viewport().get_texture().get_image()
		var target := "res://artifacts/people-costumes-%s%s.png" % ["painted-" if painterly else "","still" if time==0 else "motion"]
		var saved := frame.save_png(ProjectSettings.globalize_path(target))
		if saved != OK: push_error("Could not save costume proof"); get_tree().quit(1); return
	print("PEOPLE_COSTUMES_CAPTURE four actual method states; ",poses.size()," existing poses; two animation phases; painterly=",painterly)
	get_tree().quit(0)

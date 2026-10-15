extends Node3D
## Isolated native art proof. Figures here are atlas samples, not a game census.
const Costumes=preload("res://scripts/hud/people_settlement_costumes.gd")
const Ink=preload("res://scripts/map_life_ink.gd")
var paint:ShaderMaterial
var batch:MultiMesh
var labels:CanvasLayer

func _ready()->void:
	if "test" not in OS.get_user_data_dir().to_lower():push_error("Test user data required");get_tree().quit(2);return
	get_window().size=Vector2i(1800,1000);get_window().content_scale_size=Vector2i(1800,1000)
	var environment:=WorldEnvironment.new();environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color("30392e");add_child(environment)
	var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=.02;camera.position=Vector3(0,0,.04);camera.near=.0001
	add_child(camera);camera.look_at(Vector3.ZERO);camera.make_current()
	labels=CanvasLayer.new();add_child(labels)
	var shader:=Shader.new();shader.code=Costumes.painterly_shader_code()
	paint=ShaderMaterial.new();paint.shader=shader
	paint.set_shader_parameter("people_atlas",Costumes.atlas_texture());paint.set_shader_parameter("people_frames",Costumes.atlas_layout())
	for parameter:String in Costumes.cast_uniforms():paint.set_shader_parameter(parameter,Costumes.cast_uniforms()[parameter])
	paint.set_shader_parameter("map_people_visible",true);paint.set_shader_parameter("motion_phase_supplied",true)
	paint.set_shader_parameter("min_px",1.0);paint.set_shader_parameter("max_swell",1.0)
	var look:=Costumes.appearance(["plain_weaving","bone_needle_sewing","garment_pattern_cutting"],{"coverage":1.0})
	for parameter:String in look.uniforms:paint.set_shader_parameter(parameter,look.uniforms[parameter])
	batch=MultiMesh.new();batch.transform_format=MultiMesh.TRANSFORM_3D;batch.use_custom_data=true;batch.use_colors=true;batch.mesh=Ink.quad();batch.instance_count=36
	var people:=MultiMeshInstance3D.new();people.multimesh=batch;people.material_override=paint
	people.custom_aabb=AABB(Vector3(-.1,-.1,-.1),Vector3.ONE*.2);add_child(people)
	for role in 9:
		var origin:=Vector2((role%3)*600,(role/3)*330)
		_label(Costumes.ROLES[role],origin+Vector2(24,24),24)
		_label("Native scale",origin+Vector2(395,170),16)
		for sex in 2:
			_figure(role*4+sex,origin+Vector2(120+sex*190,260),.0014,role,sex,Costumes.WORK_POSE,0)
			_figure(role*4+2+sex,origin+Vector2(425+sex*90,260),.000333,role,sex,Costumes.WORK_POSE,0)
	await _capture("roles")
	for child in labels.get_children():child.queue_free()
	batch.instance_count=32
	for sex in 2:
		for carrying in 2:
			var row:=sex*2+carrying
			_label(("Man" if sex else "Woman")+(" carrying" if carrying else " walking"),Vector2(24,30+row*240),22)
			for frame in 4:
				var index:=row*8+frame*2
				_figure(index,Vector2(240+frame*390,210+row*240),.0010,5,sex,0,float(frame)/4,carrying==1)
				_figure(index+1,Vector2(330+frame*390,210+row*240),.000333,5,sex,0,float(frame)/4,carrying==1)
	await _capture("motion")
	print("PEOPLE_CAST_CAPTURE 18 complete roles; both sexes; four whole-body phases; native samples; encoded stages conservative")
	get_tree().quit(0)

func _figure(index:int,at:Vector2,scale:float,role:int,sex:int,pose:int,phase:float,carrying:bool=false)->void:
	var position:=Vector3((at.x-900)/50000,(500-at.y)/50000,0)
	batch.set_instance_transform(index,Transform3D(Basis(Vector3.UP,PI*.5).scaled(Vector3.ONE*scale),position))
	batch.set_instance_custom_data(index,Color(0,pose,Costumes.instance_code(role,sex,carrying),phase))
	batch.set_instance_color(index,Color.WHITE)

func _label(value:String,at:Vector2,font_size:int)->void:
	var label:=Label.new();label.text=value;label.position=at;label.add_theme_font_size_override("font_size",font_size);labels.add_child(label)

func _capture(name:String)->void:
	for i in 6:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var result:=get_viewport().get_texture().get_image().save_png("res://artifacts/people-cast-"+name+".png")
	if result!=OK:push_error("Could not save cast proof");get_tree().quit(1)

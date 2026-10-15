extends Control
## Native A/B minification proof: same atlas, identity, position and pose. Only
## edge preparation, mip sampling and alpha coverage differ. No simulation is used.
const Costumes=preload("res://scripts/hud/people_settlement_costumes.gd")
const Ink=preload("res://scripts/map_life_ink.gd")
const OUTPUT="res://artifacts/people-cast-clarity"
var stages:Array[Dictionary]=[]
var results:Array[Dictionary]=[]
var failures:Array[String]=[]

func _ready()->void:
	if "test" not in OS.get_user_data_dir().to_lower():get_tree().quit(2);return
	get_window().size=Vector2i(1600,1000);get_window().content_scale_size=Vector2i(1600,1000)
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	var backdrop:=ColorRect.new();backdrop.color=Color("354333");backdrop.size=Vector2(1600,1000);add_child(backdrop)
	_label("PRIVATE TEST · Stable small figures during quarter-pixel movement",Vector2(20,15),24)
	_label("Original linear sampling",Vector2(250,55),20);_label("Filtered sampling",Vector2(850,55),20)
	stages=[_stage(false),_stage(true)]
	for pixels:int in [16,32]:
		for activity in 18:
			var readings:Array=[[],[]]
			for step in 8:
				for index in 2:
					var stage:Dictionary=stages[index]
					var scale:=float(pixels)*.02/(96*1.85*float(Costumes.ROLE_HEIGHTS[activity]))
					var position:=Vector3(float(step)*.25*.02/96,-.005,0)
					stage.batch.set_instance_transform(0,Transform3D(Basis(Vector3.UP,PI*.5).scaled(Vector3.ONE*scale),position))
					stage.batch.set_instance_custom_data(0,Color(.13,20,Costumes.instance_code(activity/2,activity%2),0))
				for wait in 2:await get_tree().process_frame
				await RenderingServer.frame_post_draw
				for index in 2:
					var image:Image=stages[index].viewport.get_texture().get_image()
					var coverage:=0.0
					for y in image.get_height():
						for x in image.get_width():coverage+=image.get_pixel(x,y).a
					readings[index].append(coverage)
					if activity in [0,9,16] and step in [0,2,4,6]:
						var row:=[0,9,16].find(activity)+(3 if pixels==32 else 0)
						var picture:=TextureRect.new();picture.texture=ImageTexture.create_from_image(image);picture.position=Vector2(220+index*600+step/2*100,100+row*145);picture.size=Vector2(96,96);add_child(picture)
			var before:=_variation(readings[0]);var after:=_variation(readings[1])
			results.append({"activity":activity,"pixels":pixels,"original_span":before,"filtered_span":after,"original_coverage":readings[0],"filtered_coverage":readings[1]})
			if activity in [0,9,16]:
				var row:=[0,9,16].find(activity)+(3 if pixels==32 else 0)
				_label("%s · %dpx"%[Costumes.ROLES[activity/2],pixels],Vector2(20,120+row*145),18)
				_label("Alpha coverage fluctuation %.2f → %.2f"%[before,after],Vector2(220,196+row*145),14)
	for wait in 3:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUTPUT+"/comparison.png")
	for pixels:int in [16,32]:
		var original:=0.0;var filtered:=0.0;var count:=0
		for result:Dictionary in results:
			if result.pixels!=pixels:continue
			original+=result.original_span;filtered+=result.filtered_span;count+=1
			if float(result.filtered_coverage.min())<=0:failures.append("Invisible pose %d at%dpx"%[result.activity,pixels])
		if count!=18 or filtered>=original*.6:failures.append("Subpixel coverage remains unstable at%dpx: %.2f→%.2f"%[pixels,original/maxi(1,count),filtered/maxi(1,count)])
	var file:=FileAccess.open(OUTPUT+"/report.json",FileAccess.WRITE);file.store_string(JSON.stringify({"results":results,"failures":failures},"\t"));file.close()
	print("PEOPLE_CAST_CLARITY ",results.size()," paired figures; ",failures)
	get_tree().quit(0 if failures.is_empty() else 1)

func _variation(values:Array)->float:
	return float(values.max())-float(values.min())

func _stage(filtered:bool)->Dictionary:
	var viewport:=SubViewport.new();viewport.size=Vector2i(96,96);viewport.transparent_bg=true;viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(viewport)
	var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=.02;camera.position=Vector3(0,0,.04);camera.near=.0001;viewport.add_child(camera);camera.look_at(Vector3.ZERO);camera.make_current()
	var shader:=Shader.new();shader.code=Costumes.painterly_shader_code() if filtered else Costumes.painterly_shader_code().replace("filter_linear_mipmap","filter_linear").replace("ALPHA = alpha;","ALPHA = alpha; ALPHA_SCISSOR_THRESHOLD = 0.03;")
	var material:=ShaderMaterial.new();material.shader=shader;material.set_shader_parameter("people_atlas",Costumes.atlas_texture());material.set_shader_parameter("people_frames",Costumes.atlas_layout())
	for parameter:String in Costumes.cast_uniforms():material.set_shader_parameter(parameter,Costumes.cast_uniforms()[parameter])
	if not filtered:material.set_shader_parameter("role_atlas",ImageTexture.create_from_image(Image.load_from_file(Costumes.ROLE_ATLAS)))
	material.set_shader_parameter("map_people_visible",true);material.set_shader_parameter("motion_phase_supplied",true);material.set_shader_parameter("min_px",1.0);material.set_shader_parameter("max_swell",1.0)
	var batch:=MultiMesh.new();batch.transform_format=MultiMesh.TRANSFORM_3D;batch.use_custom_data=true;batch.use_colors=true;batch.mesh=Ink.quad();batch.instance_count=1;batch.set_instance_color(0,Color.WHITE)
	var node:=MultiMeshInstance3D.new();node.multimesh=batch;node.material_override=material;node.custom_aabb=AABB(Vector3(-.1,-.1,-.1),Vector3.ONE*.2);viewport.add_child(node)
	return {"viewport":viewport,"batch":batch}

func _label(value:String,at:Vector2,font_size:int)->void:
	var label:=Label.new();label.text=value;label.position=at;label.add_theme_font_size_override("font_size",font_size);add_child(label)

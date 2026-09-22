extends Node
## Isolated reference specimen: existing saved fabric, built once, three cameras.
class Terrain extends "res://scripts/local_terrain.gd":
	func _ready()->void:pass
	func _process(_delta:float)->void:pass
	func _close_surface_height_at(x:float,z:float)->float:
		var point:=Vector2(x,z)
		if RENDERED_SURFACE.contains(point,river_terrain_grid) and not rendered_regional_heights.is_empty():
			return RENDERED_SURFACE.sample(point,river_terrain_grid,func(cell:Vector2i)->float:return rendered_regional_heights[cell.y*int(river_terrain_grid.w)+cell.x])
		return _height_at(x,z)
func _ready()->void:call_deferred("run")
func run()->void:
	if DisplayServer.get_name()=="headless" or "--settlement-reference" not in OS.get_cmdline_user_args():get_tree().quit(2);return
	var payload:=SaveSystem._read_payload("quicksave")
	if payload.is_empty():get_tree().quit(2);return
	GameState.reset_for_new_world(int(payload.metadata.world_seed))
	SaveSystem._apply_reflected(GameState,payload.reflected_GameState)
	GameState.civic_api_enabled=false
	for node in get_tree().root.get_children():
		if node!=self:node.set_process(false);node.set_physics_process(false)
	var terrain:=Terrain.new();add_child(terrain)
	terrain._configure_seamless_world();terrain._configure_shape();terrain._configure_noise()
	var center:Vector3=GameState.settlement_founded_at
	var ground:float=terrain._height_at(center.x,center.z)
	var mask:=Image.create(2,2,false,Image.FORMAT_L8);mask.fill(Color.WHITE)
	terrain.discovery_mask_texture=ImageTexture.create_from_image(mask)
	var environment:=WorldEnvironment.new()
	environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color("91a5ad")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color=Color("d6e0dc")
	environment.environment.ambient_light_energy=.4
	add_child(environment)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-48,-38,0);sun.light_energy=.82;sun.shadow_enabled=true;sun.directional_shadow_max_distance=8;add_child(sun)
	var builder=preload("res://scripts/terrain_patch_builder.gd").new(257,6.0,Vector2(center.x,center.z),terrain._height_at,terrain._terrain_color_at,terrain._terrain_surface_fields_at,terrain._terrain_seasonality_at)
	while not builder.advance(5000):await get_tree().process_frame
	terrain._install_regional_patch({"center":Vector2(center.x,center.z),"span":6.0,"resolution":257,"mesh":builder.commit(),"heights":builder.heights})
	terrain._build_water()
	var clearings:=PackedVector4Array()
	for plot:Dictionary in GameState.settlement_plots:
		if String(plot.get("status","active")) in ["vacant","reclaimed"]:continue
		var local:Vector2=plot.get("centroid",Vector2.ZERO)
		var radius:=.008
		for point:Vector2 in plot.get("polygon",PackedVector2Array()):radius=maxf(radius,point.distance_to(local))
		clearings.append(Vector4(center.x+local.x,center.z+local.y,radius*1.15,.03))
		if clearings.size()==32:break
	var area_count:=clearings.size();clearings.resize(32)
	var ground_material:ShaderMaterial=terrain.regional_terrain_patch.material_override
	var shader:Shader=ground_material.shader.duplicate()
	shader.code=shader.code.replace("float edge=sqrt(sqrt(dot(squared,squared)));","float edge=length(offset);")
	shader.code=shader.code.replace("float scallop=0.08+sin(point.x*3.1+point.y*1.7)*0.035+sin(point.x*1.3-point.y*4.1)*0.035;","float scallop=sin(point.x*193.0+point.y*127.0)*0.09+sin(point.x*89.0-point.y*173.0)*0.05;")
	shader.code=shader.code.replace("smoothstep(0.82,1.0,edge)","smoothstep(0.40,1.0,edge)")
	ground_material.shader=shader
	terrain.regional_terrain_patch.material_override.set_shader_parameter("woodland_area_count",area_count)
	terrain.regional_terrain_patch.material_override.set_shader_parameter("woodland_areas",clearings)
	var fabric:=Node3D.new();terrain.add_child(fabric)
	var begin:=Time.get_ticks_usec()
	terrain._create_plot_fabric(center,GameState.settlement_plots,1,fabric)
	terrain._create_persistent_settlement_routes(center,GameState.settlement_routes,fabric)
	var build_ms:float=(Time.get_ticks_usec()-begin)/1000.0
	var identities:Array=[]
	for child in fabric.get_children():
		if child is MeshInstance3D:identities.append(child.mesh.get_rid())
		elif child is MultiMeshInstance3D:identities.append(child.multimesh.get_rid())
	var camera:=Camera3D.new();camera.fov=35;camera.near=.0001;camera.far=30;camera.current=true;terrain.add_child(camera)
	var hud:=CanvasLayer.new();add_child(hud)
	var title:=Label.new();title.position=Vector2(24,18);title.add_theme_font_size_override("font_size",22);hud.add_child(title)
	var outputs:Array=[]
	for feet in [1000,3000,10000]:
		var altitude:float=feet*.0003048
		camera.position=Vector3(center.x,ground+altitude,center.z+altitude*.35)
		camera.look_at(Vector3(center.x,ground,center.z))
		title.text="GROUNDING PROTOTYPE · %s ft · same buildings, no rebuild" % feet
		for frame in 12:await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var path:="res://artifacts/settlement-prototype-%d.png" % feet
		get_viewport().get_texture().get_image().save_png(path)
		outputs.append({"feet":feet,"image":path,"draw_calls":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),"rendered_primitives":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)})
	var same:Array=[]
	for child in fabric.get_children():
		if child is MeshInstance3D:same.append(child.mesh.get_rid())
		elif child is MultiMeshInstance3D:same.append(child.multimesh.get_rid())
	var result:={"city":GameState.settlement_name,"plots":GameState.settlement_plots.size(),"build_ms":build_ms,"geometry_unchanged":same==identities,"views":outputs}
	FileAccess.open("res://artifacts/settlement-prototype.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("SETTLEMENT_REFERENCE ",JSON.stringify(result))
	get_tree().quit(0 if same==identities else 1)
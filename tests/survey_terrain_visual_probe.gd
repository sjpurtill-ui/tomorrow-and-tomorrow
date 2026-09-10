extends Node
## Isolated capture-only fixtures using the actual lens and terrain material.
const Card=preload("res://scripts/hud/resource_survey_card.gd")
class Terrain extends "res://scripts/local_terrain.gd":
	var rain:=.25
	func _ready()->void:pass
	func _process(_dt:float)->void:pass
	func _climate_at(_x:float,_z:float,_height:float)->Dictionary:return {"temperature":.8,"precipitation":rain,"river_distance":100.0}
var output:="res://artifacts/resource-survey/"
func _ready()->void:
	get_window().title="TEST — survey and terrain capture"
	get_window().mode=Window.MODE_MINIMIZED
	call_deferred("run")
func settle()->void:
	for i in 8:await get_tree().process_frame;RenderingServer.force_draw(false)
func label(parent:Node,text:String,at:Vector2)->void:
	var title:=Label.new();title.text=text;title.position=at;title.add_theme_font_size_override("font_size",18);parent.add_child(title)
func patch(parent:Node3D,material:ShaderMaterial,color:Color,left:float,right:float,extent:float)->void:
	var s:=SurfaceTool.new();s.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p:Vector3 in [Vector3(left,0,-extent),Vector3(right,0,-extent),Vector3(left,0,extent),Vector3(right,0,-extent),Vector3(right,0,extent),Vector3(left,0,extent)]:
		s.set_normal(Vector3.UP);s.set_color(color);s.add_vertex(p)
	var mesh:=MeshInstance3D.new();mesh.mesh=s.commit();mesh.material_override=material;parent.add_child(mesh)
func run()->void:
	for node:Node in [GameState,MilitaryCampaign,CivilizationSystem]:node.set_process(false)
	GameState.reset_for_new_world(42)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var terrain:=Terrain.new();terrain.detail_noise=FastNoiseLite.new()
	var canvas:=SubViewport.new();canvas.size=Vector2i(1040,760);canvas.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(canvas)
	canvas.add_child(terrain)
	var material:=terrain._create_terrain_material()
	var fog:=Image.create(2,2,false,Image.FORMAT_RGBA8);fog.fill(Color.WHITE);material.set_shader_parameter("discovery_mask",ImageTexture.create_from_image(fog))
	var dry:Color=terrain._terrain_color_at(0,0,1.5)
	terrain.rain=.55
	var wet:Color=terrain._terrain_color_at(0,0,1.5)
	var errors:=0
	var grid:=Image.create(1040,800,false,Image.FORMAT_RGB8);grid.fill(Color("10191e"))
	for index in 4:
		var width:float=[2.0,10.0,200.0,2000.0][index]
		var view:=SubViewport.new();view.size=Vector2i(1040,200);view.own_world_3d=true;view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(view)
		var world:=Node3D.new();view.add_child(world)
		patch(world,material,dry,-width/2,0,width)
		patch(world,material,wet,0,width/2,width)
		var environment:=WorldEnvironment.new();var env:=Environment.new();env.background_mode=Environment.BG_COLOR;env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color.WHITE;env.ambient_light_energy=1.0;environment.environment=env;world.add_child(environment)
		var cam:=Camera3D.new();cam.projection=Camera3D.PROJECTION_ORTHOGONAL;cam.keep_aspect=Camera3D.KEEP_HEIGHT;cam.size=width/5.2;cam.far=width*3;cam.position=Vector3(0,width,0);world.add_child(cam);cam.look_at(Vector3.ZERO,Vector3.FORWARD)
		label(view,"DRYLANDS                         |                         GRASSLAND · %.0f km wide" % width,Vector2(16,12))
		await settle()
		var img:=view.get_texture().get_image();img.convert(Image.FORMAT_RGB8);grid.blit_rect(img,Rect2i(0,0,1040,200),Vector2i(0,index*200))
		var dry_mean:=Vector3.ZERO;var wet_mean:=Vector3.ZERO
		for y in range(50,190,5):
			for x in range(60,460,5):
				var a:=img.get_pixel(x,y);var b:=img.get_pixel(x+520,y)
				dry_mean+=Vector3(a.r,a.g,a.b);wet_mean+=Vector3(b.r,b.g,b.b)
		print("BIOME_RENDER ",width," dry r/g ",dry_mean.x/maxf(.01,dry_mean.y)," wet r/g ",wet_mean.x/maxf(.01,wet_mean.y))
		if dry_mean.x<=dry_mean.y or wet_mean.x>=wet_mean.y:errors+=1
		view.queue_free()
	grid.save_png(output+"biome-scales.png")
	var background:=ColorRect.new();background.size=Vector2(1040,760);background.color=Color("5c523d");canvas.add_child(background)
	label(canvas,"MAP SURVEY · sample disclosed resources",Vector2(26,28))
	var layer:=CanvasLayer.new();canvas.add_child(layer);terrain._build_lens(layer)
	terrain.lens_body.visible=false;terrain.lens_survey.visible=true;terrain.lens_panel.visible=true
	terrain.lens_location_label.text="2.4 km northeast of the city"
	terrain.lens_survey.show_survey([
		{"id":"clay","resource":"Clay","distance_km":2.4,"knowledge":"surveyed","quality":"good","abundance":"abundant","retrievable":true,"blockers":[]},
		{"id":"stone","resource":"Stone","distance_km":5.1,"knowledge":"surveyed","quality":"ordinary","abundance":"limited","retrievable":false,"blockers":["carrying route not established"]},
		{"id":"copper","resource":"Copper Ore","distance_km":12.0,"knowledge":"indicated","quality":"unknown","abundance":"unknown","retrievable":false,"blockers":["deposit has not been surveyed"]}
	],{"id":"steppe","label":"sun-scoured drylands","tree_cover":0.0,"stone":"scattered","soil":"low","fiber":"sparse"})
	await settle();canvas.get_texture().get_image().save_png(output+"survey.png")
	terrain.lens_survey.resource_cards[0].expand.pressed.emit()
	await settle();canvas.get_texture().get_image().save_png(output+"survey-detail.png")
	print("SURVEY_TERRAIN_CAPTURE ","PASS" if errors==0 else "FAIL")
	canvas.queue_free();await settle();WorldSimulation.clear();get_tree().quit(errors)

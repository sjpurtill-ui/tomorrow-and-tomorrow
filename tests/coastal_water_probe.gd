extends Node
## Native, capture-only checks of the actual ocean shader and terrain mesh.
const BUILDER:=preload("res://scripts/terrain_patch_builder.gd")
class Terrain extends "res://scripts/local_terrain.gd":
	func _ready()->void:pass
	func _process(_delta:float)->void:pass
	func _climate_at(_x:float,_z:float,_height:float)->Dictionary:return {"temperature":.77,"precipitation":.26,"river_distance":100.0}
	func _height_at(x:float,z:float)->float:return x*.04+sin(z*3)*.008+sin(z*11)*.002
var errors:=0
func _ready()->void:
	get_window().title="TEST — Coastal water audit";get_window().mode=Window.MODE_MINIMIZED;call_deferred("run")
func check(condition:bool,message:String)->void:
	print("COASTAL ","PASS " if condition else "FAIL ",message)
	if not condition:errors+=1
func settle()->void:
	for frame in 8:await get_tree().process_frame;RenderingServer.force_draw(false)
func texture(value:float,resolution:int=3)->ImageTexture:
	var image:=Image.create(resolution,resolution,false,Image.FORMAT_RF);image.fill(Color(value,0,0));return ImageTexture.create_from_image(image)
func fog(value:Color)->ImageTexture:
	var image:=Image.create(2,2,false,Image.FORMAT_RGBA8);image.fill(value);return ImageTexture.create_from_image(image)
func sample(view:SubViewport,camera:Camera3D,point:Vector3)->Color:
	var pixel:=Vector2i(camera.unproject_position(point));var image:=view.get_texture().get_image()
	return image.get_pixel(clampi(pixel.x,0,image.get_width()-1),clampi(pixel.y,0,image.get_height()-1))
func difference(a:Color,b:Color)->float:return Vector3(a.r-b.r,a.g-b.g,a.b-b.b).length()
func luminance_range(image:Image)->float:
	var low:=1.0;var high:=0.0
	for y in range(40,image.get_height()-40,40):
		for x in range(40,image.get_width()-40,40):
			var value:=image.get_pixel(x,y).get_luminance();low=minf(low,value);high=maxf(high,value)
	return high-low
func run()->void:
	for node:Node in [GameState,MilitaryCampaign,CivilizationSystem]:node.set_process(false)
	GameState.reset_for_new_world(424242)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/coastal-water"))
	var view:=SubViewport.new();view.size=Vector2i(1080,720);view.own_world_3d=true;view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(view)
	var terrain:=Terrain.new();view.add_child(terrain)
	terrain.world_width=40075.0;terrain.world_depth=20004.0
	terrain.terrain_noise=FastNoiseLite.new();terrain.terrain_noise.seed=42
	terrain.moisture_noise=FastNoiseLite.new();terrain.moisture_noise.seed=51
	terrain.detail_noise=FastNoiseLite.new();terrain.detail_noise.seed=73
	terrain.discovery_mask_texture=fog(Color.WHITE)
	var builder:=BUILDER.new(161,8.0,Vector2.ZERO,terrain._height_at,terrain._terrain_color_at)
	while not builder.advance(100000):pass
	terrain._install_regional_patch({"mesh":builder.commit(),"center":Vector2.ZERO,"span":8.0,"resolution":161,"heights":builder.heights})
	terrain._build_water();var material:=terrain.coastal_water_material;material.set_shader_parameter("wave_speed",0.0)
	var environment:=WorldEnvironment.new();var env:=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color("182420");env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color.WHITE;env.ambient_light_energy=.70;environment.environment=env;view.add_child(environment)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-55,-30,0);sun.light_energy=.65;view.add_child(sun)
	var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=2.84;camera.near=.05;camera.far=10;camera.position=Vector3(0,5,0);view.add_child(camera);camera.look_at(Vector3.ZERO,Vector3.FORWARD)
	await settle();view.get_texture().get_image().save_png("res://artifacts/coastal-water/coast.png")
	camera.projection=Camera3D.PROJECTION_PERSPECTIVE;camera.fov=35;camera.far=100000;camera.position=Vector3(0,3.048,1.8);camera.look_at(Vector3.ZERO,Vector3.UP)
	await settle();view.get_texture().get_image().save_png("res://artifacts/coastal-water/coast-perspective.png")
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.far=10;camera.position=Vector3(0,5,0);camera.look_at(Vector3.ZERO,Vector3.FORWARD);await settle()
	var lowland:=Vector3(.15,terrain._height_at(.15,0)+.0006,0)
	var with_water:=sample(view,camera,lowland)
	var coast_samples:Array=[]
	for i in 24:
		var z:=float(i)/23.0*2.0-1.0
		var shoreline_x:=-(sin(z*3)*.008+sin(z*11)*.002+.0006)/.04
		for side:float in [-1.0,1.0]:
			var point:=Vector3(shoreline_x+side*.04,0,z)
			coast_samples.append({"point":point,"land":side>0,"color":sample(view,camera,point)})
	terrain.ocean_surface.hide();await settle();var dry_ground:=sample(view,camera,lowland)
	check(difference(with_water,dry_ground)<.005,"6.6 m coastal ground remains dry")
	var incorrect_coast:=0
	for item:Dictionary in coast_samples:
		var changed:=difference(item.color,sample(view,camera,item.point))>.025
		if changed==item.land:incorrect_coast+=1
	check(incorrect_coast==0,"48 samples follow true shoreline without depth holes: "+str(incorrect_coast)+" wrong")
	terrain.ocean_surface.show();terrain.ocean_surface.position.y=.012;await settle()
	check(difference(sample(view,camera,lowland),dry_ground)>.025,"fixture reproduces flooding with old +12 m sea surface")
	terrain.ocean_surface.position.y=0
	# Isolate water for depth, interpolation, zoom and fog checks.
	terrain.regional_terrain_patch.hide();material.set_shader_parameter("terrain_grid",Vector4(0,0,10,3))
	var colors:Array[Color]=[]
	for depth:float in [.003,.05,.8]:
		material.set_shader_parameter("terrain_heights",texture(-depth));await settle();colors.append(sample(view,camera,Vector3.ZERO))
	check(colors[0].get_luminance()>colors[1].get_luminance()+.02 and colors[1].get_luminance()>colors[2].get_luminance()+.02,"real depth distinguishes shallows, shelf and deep water")
	check(colors[0].g>colors[0].b and colors[2].b>colors[2].g,"bed-tinted shallows transition to blue open water")
	# Shader interpolation must agree with rays against both triangle diagonals.
	var varied:=BUILDER.new(3,2.0,Vector2.ZERO,func(x:float,z:float)->float:return -.04-(x*x+z*z+x*z)*.04,func(_x:float,_z:float,_h:float)->Color:return Color.WHITE)
	while not varied.advance(100000):pass
	var image:=Image.create_from_data(3,3,false,Image.FORMAT_RF,varied.heights.to_byte_array());var varied_texture:=ImageTexture.create_from_image(image)
	material.set_shader_parameter("terrain_grid",Vector4(0,0,2,3));camera.size=.001
	for point:Vector2 in [Vector2(-.7,-.2),Vector2(-.2,-.7),Vector2(.2,-.7),Vector2(.7,-.2)]:
		var bed:=NAN
		for i in range(0,varied.indices.size(),3):
			var hit=Geometry3D.ray_intersects_triangle(Vector3(point.x,10,point.y),Vector3.DOWN,varied.vertices[varied.indices[i]],varied.vertices[varied.indices[i+1]],varied.vertices[varied.indices[i+2]])
			if hit is Vector3:bed=hit.y;break
		camera.position=Vector3(point.x,5,point.y);material.set_shader_parameter("terrain_heights",varied_texture);await settle();var actual:=sample(view,camera,Vector3(point.x,0,point.y))
		material.set_shader_parameter("terrain_heights",texture(bed));await settle()
		check(not is_nan(bed) and difference(actual,sample(view,camera,Vector3(point.x,0,point.y)))<.008,"GPU bed matches mesh ray at "+str(point))
	# At distant scales waves must resolve to a calm surface, not moving noise.
	camera.position=Vector3(0,5000,0);camera.far=10000;material.set_shader_parameter("wave_speed",1.0)
	for scale:Dictionary in terrain.CAMERA_DISTANCE_LEVELS:
		var span:=minf(scale.width_km*3.0,920.0)
		var flat:=BUILDER.new(33,span,Vector2.ZERO,func(_x:float,_z:float)->float:return -.1,func(_x:float,_z:float,_h:float)->Color:return Color.WHITE)
		while not flat.advance(100000):pass
		terrain._install_regional_patch({"mesh":flat.commit(),"center":Vector2.ZERO,"span":span,"resolution":33,"heights":flat.heights});terrain.regional_terrain_patch.hide()
		camera.size=scale.width_km;await settle();var first:=view.get_texture().get_image();await settle();var second:=view.get_texture().get_image()
		second.save_png("res://artifacts/coastal-water/scale-"+String(scale.name).replace(",","").replace(" ","-")+".png")
		var corner:=second.get_pixel(8,8)
		check(corner.b>corner.g,"water fills view at "+scale.name)
		if scale.width_km>=150:check(first.get_data()==second.get_data(),"no unresolved animated detail at "+scale.name)
		if scale.width_km>=3000:
			check(luminance_range(second)>.008,"continental ocean retains broad static basin structure")
			var real_bed:=sample(view,camera,Vector3.ZERO);material.set_shader_parameter("terrain_heights",texture(-.002,33));await settle()
			check(difference(real_bed,sample(view,camera,Vector3.ZERO))<.005,"continental color cannot reveal the moving regional depth patch")
	material.set_shader_parameter("discovery_mask",fog(Color.BLACK));material.set_shader_parameter("fog_current_origin",Vector2(100000,100000));material.set_shader_parameter("terrain_heights",texture(-.8,33));camera.size=2.84
	await settle();var unknown:=view.get_texture().get_image();material.set_shader_parameter("terrain_heights",texture(-.002,33));await settle();var hidden_shallows:=view.get_texture().get_image()
	check(unknown.get_data()==hidden_shallows.get_data(),"fog hides bed depth and moving highlights")
	view.queue_free();await settle();WorldSimulation.clear();print("COASTAL_WATER_CAPTURE ","PASS" if errors==0 else "FAIL");get_tree().quit(errors)

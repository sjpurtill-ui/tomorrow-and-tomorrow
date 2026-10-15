extends Node3D
## Private native scenery proof. The player game and its saves are never opened.
const World=preload("res://scripts/hud/people_work_world.gd")
const OUTPUT="res://artifacts/people-work-world"
var camera:Camera3D

func _ready()->void:
	if "test" not in OS.get_user_data_dir().to_lower():push_error("Isolated Test user data required");get_tree().quit(2);return
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	var environment:=WorldEnvironment.new();environment.environment=Environment.new();environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color("37442c");add_child(environment)
	var result:=World.render(self,func(at:Vector2,lift:float)->Vector3:return Vector3(at.x,lift,at.y))
	camera=Camera3D.new();camera.near=.0001;camera.far=2;camera.fov=42;add_child(camera)
	for dimensions:Vector2i in [Vector2i(1600,1000),Vector2i(1024,768)]:
		get_window().size=dimensions;get_window().content_scale_size=dimensions
		_look(result.overview_center,.090)
		await _capture("overview-"+str(dimensions.x))
	for role:String in ["Food","Crafting","Administration","Logistics"]:
		_look(result.zones[role].focus_center,result.zones[role].focus_span)
		await _capture(role.to_lower()+"-1024")
	print("PEOPLE_WORK_WORLD_NATIVE PASS ",result.zones.size()," zones")
	get_tree().quit(0)

func _look(at:Vector2,span:float)->void:
	var target:=Vector3(at.x,0,at.y)
	var offset:=Vector3(sin(-.60)*cos(.61),sin(.61),cos(-.60)*cos(.61))
	camera.position=target+offset*span/(2*tan(deg_to_rad(camera.fov*.5)));camera.look_at(target)

func _capture(label:String)->void:
	for tick in 12:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUTPUT+"/"+label+".png")

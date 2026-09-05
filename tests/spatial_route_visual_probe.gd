extends Node2D
const Urban=preload("res://tests/spatial_experiment_urban.gd")
var fronts:Array=[]

func _ready()->void:
	AudioServer.set_bus_mute(0,true)
	get_window().size=Vector2i(1600,540)
	get_window().content_scale_size=Vector2i(1600,540)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	for index in 4:
		var front:=Urban.new(); front.build([0.01,0.025,0.1,0.25][index]); fronts.append(front)
		var image:=Image.create_empty(400,400,false,Image.FORMAT_RGB8)
		for y in 400:
			for x in 400:
				image.set_pixel(x,y,Color("615b50") if Urban.building_at(Vector2(x,y)*0.005) else Color("172b2c"))
		var view:=Sprite2D.new(); view.texture=ImageTexture.create_from_image(image); view.centered=false
		view.position=Vector2(index*400,70); add_child(view)
		for number in [0,3,6]:
			var line:=Line2D.new(); line.width=2.0; line.default_color=[Color("e6bd63"),Color("72ced4"),Color("e78383")][number/3]
			for point in front.compressed(front.path(number)): line.add_point(Vector2(index*400,70)+point*200.0)
			add_child(line)
	queue_redraw()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/spatial-route-comparison.png")
	print("SPATIAL_ROUTE_VISUAL_DONE")
	get_tree().quit()

func _draw()->void:
	draw_string(ThemeDB.fallback_font,Vector2(20,26),"EXPERIMENT ONLY: 2km city fronts · grid stays invisible · lines are compressed routes",HORIZONTAL_ALIGNMENT_LEFT,-1,20)
	for index in 4:
		draw_string(ThemeDB.fallback_font,Vector2(index*400+20,56),"%dm planning cells" % [10,25,100,250][index],HORIZONTAL_ALIGNMENT_LEFT,-1,18)
	draw_string(ThemeDB.fallback_font,Vector2(20,506),"Buildings: grey · roads: dark · coarse routes can cut through unsampled buildings. This is synthetic geometry, not the game's city art.",HORIZONTAL_ALIGNMENT_LEFT,-1,17)

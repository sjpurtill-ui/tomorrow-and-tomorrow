extends Node
const T:=preload("res://scripts/hud/hud_tokens.gd")
const Dock:=preload("res://scripts/hud/dock_panel.gd")
class Provider extends RefCounted:
	func meta()->Dictionary:return {"title":"A people we know","subtabs":[]}
	func signature()->Array:return []
	func tab(_sub:int)->Dictionary:return {"kpis":[
		{"label":"FIRST MET","value":"Year 96 · Spring","delta":"at the northern river crossing","tip":"The first meeting recorded by our scouts."},
		{"label":"FOUND","value":"Year 112 · Autumn","delta":"the seat and three outlying settlements","tip":"The latest place returned by a traveler."},
		{"label":"LAST WORD","value":"Things may improve","glance":true,"delta":"Things may improve when both sides have enough food and the roads are open again."},
		{"label":"OUR STANDING","value":"Guarded friendship","glance":true,"delta":"The speaker has welcomed the latest envoy."}],"blocks":[]}
func _ready()->void:
	if not "Test" in OS.get_user_data_dir():get_tree().quit(2);return
	get_tree().create_timer(30).timeout.connect(func():get_tree().quit(3))
	get_window().size=Vector2i(1024,720);get_window().content_scale_size=Vector2i(1024,720)
	var errors:Array=[]
	for mode in ["dark","light"]:
		T.set_color_mode(mode)
		var dock:=Dock.new();add_child(dock);dock.position=Vector2(24,20);dock.size=Vector2(570,680);dock.present(Provider.new(),0)
		for frame in 12:await get_tree().process_frame
		for tile:Control in dock.kpi_row.get_children():
			for label:Label in tile.find_children("*","Label",true,false):
				var rect:=label.get_global_rect();var outer:=tile.get_global_rect()
				if rect.position.x<outer.position.x-1 or rect.end.x>outer.end.x+1:errors.append("KPI label outside its cell: "+label.text)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://artifacts/kpi-wrapping-"+mode+".png"))
		dock.queue_free();await get_tree().process_frame
	print("KPI_WRAPPING_CHECKS ",errors);get_tree().quit(0 if errors.is_empty() else 1)

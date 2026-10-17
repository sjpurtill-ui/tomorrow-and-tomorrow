extends Node
## Offscreen native-rendered capture of the real category navigation and dock.
## Isolated userdata required. The invisible test process exits after captures.
const Fixture=preload("res://tests/hoi4_production_capture.gd")
const Rail=preload("res://scripts/hud/command_rail_hud.gd")
const Dock=preload("res://scripts/hud/dock_panel.gd")
const Provider=preload("res://scripts/hud/content/dock_content_production.gd")
func _ready()->void:
	get_window().title="TEST — Production navigation capture"
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS,true)
	DisplayServer.window_set_position(Vector2i(-10000,-10000))
	call_deferred("run")
func run()->void:
	for singleton:Node in [GameState,MilitaryCampaign,CivilizationSystem]:singleton.set_process(false)
	var output:="/tmp/tat-production-correction"
	DirAccess.make_dir_recursive_absolute(output)
	for state in ["early","catalog","late","civilian"]:
		if state=="late":Fixture.seed_late()
		else:Fixture.seed_early()
		var viewport:=SubViewport.new();viewport.size=Vector2i(1280,900);viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(viewport)
		var ground:=ColorRect.new();ground.color=Color("566044");ground.size=Vector2(1280,900);viewport.add_child(ground)
		var rail:=Rail.new()
		var provider=Provider.new(null,null)
		rail.providers={"production":provider,"economy":load("res://scripts/hud/content/dock_content_economy.gd").new(null,null)}
		var dock:=Dock.new();viewport.add_child(dock);dock.position=Vector2(78,45);dock.size=Vector2(620,840)
		dock.siblings=rail._pages_of(Rail.category_of("production"));dock.category_title="Economy";dock.present(provider,1 if state=="civilian" else 0)
		dock.size.x=rail._dock_width(dock,1280)
		if state=="catalog":dock.find_child("IllustratedProductionQueue",true,false)._show_workspace("recipes")
		for frame in 20:await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var result:=viewport.get_texture().get_image().save_png(output.path_join(state+".png"))
		print("PRODUCTION_CAPTURE ",state," ",result," width=",dock.size.x)
		for row:Node in dock.find_children("Line?","",true,false):
			if row is Control:print("ROW ",row.name," ",row.size)
		rail.free();viewport.queue_free();await get_tree().process_frame
	WorldSimulation.clear();get_tree().quit()

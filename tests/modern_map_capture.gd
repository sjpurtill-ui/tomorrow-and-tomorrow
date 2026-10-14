extends Node
## Actual small map overlays in isolated fresh fixture state. No save or player launch.
const T=preload("res://scripts/hud/hud_tokens.gd")
var terrain:Node
var output:="res://artifacts/popup-audit/map"
func frames(n:int=10)->void:
	for i in n:await get_tree().process_frame
func shot(label:String)->void:
	await frames();await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output.path_join(label+".png"))
func _ready()->void:call_deferred("run")
func run()->void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	GameState.reset_for_new_world(424242);GameState.civic_api_enabled=false
	GameState.select_founding_focus("provision")
	terrain=load("res://local_terrain.tscn").instantiate();add_child(terrain)
	terrain.display_preferences.ui_scale=1.0;terrain.display_preferences.color_theme="dark";T.set_color_mode("dark");terrain.display_preferences.apply()
	await frames(24)
	if WorldSimulation.direction.needs_century_choice():WorldSimulation.direction.choose(String(PeopleDirection.AMBITIONS.keys()[0]))
	if is_instance_valid(PeopleDirection.panel):PeopleDirection.panel.queue_free()
	if is_instance_valid(terrain.founding_focus_panel):terrain.founding_focus_panel.queue_free();terrain.founding_focus_panel=null
	terrain._set_game_speed(0);await frames()
	var home:Vector3=terrain.settler_marker.position
	for dimensions in [Vector2i(1440,900),Vector2i(1024,720)]:
		get_window().size=dimensions;get_window().content_scale_size=dimensions;await frames()
		terrain._inspect_location(home+Vector3(0.35,0,0.2));await shot("ground-%d" % dimensions.x);terrain._close_lens()
		terrain._inspect_location(home+Vector3(900,0,900));await shot("uncharted-%d" % dimensions.x);terrain._close_lens()
		terrain._open_founding_site_guide(home);await shot("site-%d" % dimensions.x);terrain._close_founding_site_guide()
		terrain._toggle_map_help();await shot("help-%d" % dimensions.x);terrain._dismiss_map_help()
	var notices=preload("res://scripts/hud/notification_stack.gd").ensure(terrain,terrain.hud)
	notices._capture_standing();await shot("notices")
	notices.toggle_log();await shot("notice-log");notices.toggle_log()
	terrain.open_world_globe();await frames(30);await shot("world-globe")
	if is_instance_valid(terrain.world_globe):terrain.world_globe.close()
	print("MODERN_MAP_CAPTURE PASS")
	get_tree().quit(0)

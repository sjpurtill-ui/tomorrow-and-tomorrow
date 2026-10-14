extends Node
## All live later-service pages in isolated fixture state; no save or player launch.
const Fixture=preload("res://tests/military_visual_roster_probe.gd")
const Roster=preload("res://scripts/hud/military_roster_screen.gd")
const T=preload("res://scripts/hud/hud_tokens.gd")
func _ready()->void:call_deferred("run")
func settle()->void:
	for frame in 8:
		await get_tree().process_frame
		RenderingServer.force_draw(false)
func run()->void:
	for node in [GameState,MilitaryCampaign,CivilizationSystem]:node.set_process(false)
	var fixture:=preload("res://tests/audience_hall_probe.gd").new()
	fixture._base();fixture._people(5000);fixture._refill();fixture._next_door()
	for material in ["Food","Timber","Stone","Iron Ore"]:GameState.resource_stockpiles[material]=100000.0
	var services:=Fixture.new()
	services.add_service_force("navy");services.add_service_force("air")
	MilitaryCampaign.joint_operations.advance(1)
	var output:="res://artifacts/popup-audit/services"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	for dimensions in [Vector2i(1440,900),Vector2i(1024,720)]:
		get_window().size=dimensions;get_window().content_scale_size=dimensions
		for domain in ["navy","air"]:
			var panel=load("res://scripts/hud/%s_command_panel.gd" % ("naval" if domain=="navy" else "air")).new();add_child(panel)
			await settle()
			for page in panel.pages.get_tab_count():
				panel.pages.current_tab=page;await settle()
				assert(get_viewport().get_visible_rect().encloses(panel.panel.get_global_rect()),"Service panel escapes viewport")
				get_viewport().get_texture().get_image().save_png(output.path_join("%s-command-%d-%d.png" % [domain,page,dimensions.x]))
			panel.queue_free();await get_tree().process_frame
			var roster:=Roster.new();roster.service=domain;add_child(roster);roster.panel.theme=T.control_theme();await settle()
			for page in ["leaders","forces","recruitment","training","support","wars"]:
				roster._show_page(page);await settle()
				assert(get_viewport().get_visible_rect().encloses(roster.panel.get_global_rect()),"Service roster escapes viewport")
				get_viewport().get_texture().get_image().save_png(output.path_join("%s-roster-%s-%d.png" % [domain,page,dimensions.x]))
			roster.queue_free();await get_tree().process_frame
	fixture.free();services.free();WorldSimulation.clear()
	print("MODERN_SERVICE_CAPTURE PASS")
	get_tree().quit(0)

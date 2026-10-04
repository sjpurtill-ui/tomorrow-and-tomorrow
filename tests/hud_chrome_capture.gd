extends Node
## Isolated render of the real HUD controls with a fixed presentation fixture.
## Never loads or saves a campaign; use the private-desktop GPU launcher.
const T:=preload("res://scripts/hud/hud_tokens.gd")
class ChromeOnly extends "res://scripts/hud/command_rail_hud.gd":
	func _ready()->void:
		theme=Tokens.control_theme()
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		_build_frame();_build_rail();_build_time_pill();_build_kpi_strip()
		get_viewport().size_changed.connect(_layout)
		_layout()

var failures:Array[String]=[]

func _ready()->void:
	if not OS.get_user_data_dir().get_file().contains("Test"):
		get_tree().quit(2);return
	var dark:="dark" in OS.get_cmdline_user_args()
	T.set_color_mode("dark" if dark else "light")
	if "world" in OS.get_cmdline_user_args():
		await _world_capture()
		return
	GameState.known_discoveries.append("printing_process")
	get_window().content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	var background:=ColorRect.new()
	background.color=T.PAPER_SUNK.lerp(T.GREEN,.25)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var hud:=ChromeOnly.new();add_child(hud)
	hud.set_process(false)
	hud.time_text.text="[b]Year 164 · Winter[/b] · Hot →"
	hud._style_speed_controls(5)
	var fixture:={
		"population":["1,047 people","born 43 · buried 33",T.GREEN],
		"food":["187 days","of food",T.GREEN],
		"water":["5.4 days","of drinking water",T.TEAL],
		"goods":["100%","more made",T.GREEN],
		"health":["34 years","150 in 1,000 infants lost",T.AMBER],
		"science":["73.5","92 scholars",T.GOLD],
		"gdp":["764 hands","0.73 each",T.BLUE]}
	for id in fixture:
		var f:Array=fixture[id];hud._update_kpi(id,f[0],f[1],f[2],"")
	hud._refresh_words()
	hud.drawer_open=true;hud._sync_drawer()
	hud._set_badge("chronicle","3",T.RED)
	var dir:="res://reports/hud_chrome/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	for dimensions in [Vector2i(1920,1080),Vector2i(1280,720),Vector2i(1138,640)]:
		get_window().size=dimensions
		await _frames(4);hud._layout();await _frames(4)
		var bounds:=Rect2(Vector2.ZERO,Vector2(dimensions))
		for id in hud.kpi_chips:
			var chip:Control=hud.kpi_chips[id].chip
			if not chip.visible:continue
			if not bounds.encloses(chip.get_global_rect()):failures.append("KPI off screen: %s %s" % [id,dimensions])
			if chip.get_global_rect().intersects(hud.time_pill.get_global_rect()):failures.append("KPI over clock: %s %s" % [id,dimensions])
			for key in ["caption","value","delta"]:
				var line:Label=hud.kpi_chips[id][key]
				if not chip.get_global_rect().encloses(line.get_global_rect()):failures.append("KPI line clipped: %s %s" % [id,key])
			var note:Label=hud.kpi_chips[id].delta
			if note.get_global_rect().end.y>chip.get_global_rect().end.y-2:failures.append("note overlaps bottom rule: "+String(id))
		for id in hud.rail_buttons:
			var button:Button=hud.rail_buttons[id]
			var label:Label=hud.rail_labels[id]
			if label.get_minimum_size().x>button.size.x:failures.append("rail label too wide: "+String(id))
			if label.get_global_rect().end.x>button.get_global_rect().end.x:failures.append("rail content overflows: "+String(id))
		await _capture(dir+"%s-%d.png" % ["dark" if dark else "light",dimensions.x])
	# The negative report must not move the strip or hide the urgent readings.
	var old_rect:Rect2=hud.kpi_strip.get_global_rect()
	hud._update_kpi("food","0 days","shortage −99,999 days",T.RED,"")
	hud._layout();await _frames(3)
	if hud.kpi_strip.get_global_rect()!=old_rect:failures.append("warning resized the status strip")
	hud.rail_buttons.overview.grab_focus()
	await _capture(dir+"%s-warning-focus.png" % ["dark" if dark else "light"])
	hud.drawer_open=false;hud._sync_drawer();await _frames(3)
	if hud.drawer_box.get_parent().visible:failures.append("closed drawer leaves its frame visible")
	await _capture(dir+"%s-closed.png" % ["dark" if dark else "light"])
	print("HUD_CHROME_RESULT ",JSON.stringify({"failures":failures,"palette":T.color_mode}))
	get_tree().quit(0 if failures.is_empty() else 1)

func _capture(path:String)->void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)

func _frames(count:int)->void:
	for i in count:await get_tree().process_frame

func _world_capture()->void:
	# A disposable new world, never a player save or a player-facing launch.
	get_window().content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	get_window().size=Vector2i(1920,1080)
	GameState.reset_for_new_world(424242)
	DiscoverySystem.reset_for_new_world();ResourceSystem.reset_for_new_world();FoodSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world()
	GameState.civic_api_enabled=false
	var terrain:Node=load("res://local_terrain.tscn").instantiate()
	add_child(terrain)
	await _frames(20)
	PeopleDirection.choose("makers")
	if is_instance_valid(PeopleDirection.panel):PeopleDirection.panel.queue_free()
	await _frames(4)
	terrain._start_settlement_here()
	await _frames(4)
	if is_instance_valid(terrain.settlement_naming_panel):terrain.settlement_naming_panel.queue_free()
	terrain._set_game_speed(0)
	terrain.hud.drawer_open=true;terrain.hud._sync_drawer()
	await _frames(8)
	var path:="res://reports/hud_chrome/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))
	await _capture(path+"world-"+T.color_mode+".png")
	print("HUD_CHROME_WORLD_RESULT ",JSON.stringify({"palette":T.color_mode,"seed":424242,"paused":true}))
	get_tree().quit(0)

extends RefCounted
## THE GAME MENU: pause, save and load, the AI reply setting, a new world,
## display settings and the controls. Paper and ink. Anything that throws
## away play (load, restart, a new world) asks once before it happens.
## The map owns the actions; this file owns the words and the layout.

const T:=preload("res://scripts/hud/hud_tokens.gd")
const Kit:=preload("res://scripts/hud/paper_kit.gd")

## Builds the menu over the map. Returns the full-screen root; the card is
## its "PauseMenuBody" child. `terrain` supplies the actions.
static func open(terrain:Node,layer:Node)->Control:
	var root:=Control.new()
	root.name="GameMenu"
	root.z_index=100
	root.set_meta("responsive_scroll_layout",true)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter=Control.MOUSE_FILTER_STOP
	root.theme=T.control_theme()
	layer.add_child(root)
	var scrim:=ColorRect.new()
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.color=T.SCRIM
	root.add_child(scrim)
	var card:=Kit.panel(Color(0,0,0,0),24.0)
	card.name="PauseMenuBody"
	card.size=Vector2(680,minf(820,terrain.get_viewport().get_visible_rect().size.y-32))
	root.add_child(card)
	var scroll:=ScrollContainer.new()
	scroll.name="PauseMenuScroll"
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	card.add_child(scroll)
	var content:=VBoxContainer.new()
	content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",10)
	scroll.add_child(content)

	Kit.label(content,"Paused · version %s" % String(ProjectSettings.get_setting("application/config/version","in development")),"kicker")
	Kit.label(content,String(terrain._settlement_display_name()),"title")
	Kit.label(content,"%s · %d people" % [Kit.when(int(GameState.elapsed_days)),GameState.population_total],"body")
	var session:=HBoxContainer.new()
	session.add_theme_constant_override("separation",8)
	content.add_child(session)
	var resume:=Kit.button(session,"Resume",true,Callable(terrain,"_close_world_menu"))
	resume.name="Resume"
	resume.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	resume.custom_minimum_size.y=42
	var quit:=Kit.button(session,"Quit…",false,Callable(terrain,"_request_quit"),"Asks whether to save first")
	quit.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	quit.custom_minimum_size.y=42

	# Save and load -----------------------------------------------------
	content.add_child(HSeparator.new())
	Kit.label(content,"Save and load","kicker")
	var save_status:=Kit.label(content,saved_words(SaveSystem.save_metadata()),"body")
	save_status.name="SaveStatus"
	var save_row:=HBoxContainer.new()
	save_row.add_theme_constant_override("separation",8)
	content.add_child(save_row)
	var save:=Kit.button(save_row,"Save",false,func()->void:
		var result:Dictionary=SaveSystem.save_game()
		_say(save_status,String(result.get("message","")) if not result.has("error") else String(result.error),result.has("error")))
	save.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var load_button:=Kit.button(save_row,"Load saved game",false,Callable(),"Go back to the saved game")
	load_button.name="LoadSaved"
	load_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	load_button.disabled=SaveSystem.save_metadata().is_empty()
	if load_button.disabled:load_button.tooltip_text="There is no saved game yet."
	load_button.pressed.connect(func()->void:
		confirm(root,"Load the saved game?","Anything that happened since you last saved will be lost.","Load it",func()->void:
			var error:String=terrain._load_saved_world()
			if error!="":_say(save_status,error,true)))

	# AI replies ---------------------------------------------------------
	content.add_child(HSeparator.new())
	Kit.label(content,"How your people answer","kicker")
	var ai_status:=Kit.label(content,"","body")
	ai_status.name="AiStatus"
	var ai_row:=HBoxContainer.new()
	ai_row.add_theme_constant_override("separation",8)
	content.add_child(ai_row)
	var ai_toggle:=Kit.button(ai_row,"",false)
	ai_toggle.name="AiToggle"
	var ai_settings:=Kit.button(ai_row,"AI connection…",false,Callable(PronouncementInterpreter,"open_connection_settings"),"Set the key the game uses for written replies")
	ai_settings.name="AiSettings"
	var refresh_ai:=func()->void:
		var words:=ai_words(bool(GameState.civic_api_enabled),bool(PronouncementInterpreter.configuration_status().get("configured",false)))
		ai_status.text=String(words.status)
		ai_toggle.text=String(words.button)
		ai_toggle.tooltip_text=String(words.tip)
	refresh_ai.call()
	ai_toggle.pressed.connect(func()->void:
		PronouncementInterpreter.set_api_enabled(not bool(GameState.civic_api_enabled))
		refresh_ai.call()
		if terrain.get("hud") and terrain.hud.has_method("request_immediate_dock_refresh"):terrain.hud.request_immediate_dock_refresh())

	# New world ----------------------------------------------------------
	content.add_child(HSeparator.new())
	Kit.label(content,"Start again","kicker")
	var new_row:=HBoxContainer.new()
	new_row.add_theme_constant_override("separation",8)
	content.add_child(new_row)
	var restart:=Kit.button(new_row,"Restart this world",false,func()->void:
		confirm(root,"Restart this world?","Your people start again on day one on the same land. Everything since then is lost unless you have saved it.","Restart",Callable(terrain,"_restart_world").bind(GameState.world_seed)),"Same land, a fresh start")
	restart.name="RestartWorld"
	restart.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var fresh:=Kit.button(new_row,"New world",false,func()->void:
		confirm(root,"Start a new world?","A different land and different neighbours. This game is lost unless you have saved it.","Start a new world",Callable(terrain,"_restart_random_world")),"A different land")
	fresh.name="NewWorld"
	fresh.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var options_toggle:=Kit.quiet_button(content,"New world options ▸")
	options_toggle.alignment=HORIZONTAL_ALIGNMENT_LEFT
	var options:=VBoxContainer.new()
	options.name="NewWorldOptions"
	options.add_theme_constant_override("separation",6)
	options.visible=false
	content.add_child(options)
	options_toggle.pressed.connect(func()->void:
		options.visible=not options.visible
		options_toggle.text="New world options ▾" if options.visible else "New world options ▸")
	var seed_row:=HBoxContainer.new()
	seed_row.add_theme_constant_override("separation",8)
	options.add_child(seed_row)
	Kit.label(seed_row,"World number","body",Color(0,0,0,0),false)
	var seed_input:=LineEdit.new()
	seed_input.name="WorldSeed"
	seed_input.text=str(GameState.world_seed)
	seed_input.tooltip_text="The same number always makes the same land."
	seed_input.custom_minimum_size=Vector2(180,36)
	seed_input.add_theme_font_size_override("font_size",15)
	seed_row.add_child(seed_input)
	var neighbours_row:=HBoxContainer.new()
	neighbours_row.add_theme_constant_override("separation",8)
	options.add_child(neighbours_row)
	Kit.label(neighbours_row,"Other peoples","body",Color(0,0,0,0),false)
	for count:int in [6,12,24,36]:
		var choice:=Button.new()
		choice.text="%d%s" % [count," (usual)" if count==12 else ""]
		choice.toggle_mode=true
		choice.button_pressed=count==GameState.opponent_count
		choice.tooltip_text="How many other peoples share a new world. This game keeps its neighbours."
		choice.add_theme_font_size_override("font_size",14)
		choice.pressed.connect(func()->void:
			GameState.opponent_count=count
			for sibling in neighbours_row.get_children():
				if sibling is Button:(sibling as Button).button_pressed=sibling==choice)
		neighbours_row.add_child(choice)
	var seed_status:=Kit.label(options,"","note")
	Kit.button(options,"Start a world with this number",false,func()->void:
		if not seed_input.text.strip_edges().is_valid_int():
			_say(seed_status,"Type a whole number, such as 184271.",true)
			return
		confirm(root,"Start a new world?","This game is lost unless you have saved it.","Start",Callable(terrain,"_restart_with_entered_seed")))
	terrain.set("world_seed_input",seed_input)
	terrain.set("world_seed_status",seed_status)

	# Display and controls -----------------------------------------------
	content.add_child(HSeparator.new())
	if terrain.get("display_preferences"):
		terrain.display_preferences.add_controls(content)
		terrain.display_preferences.add_navigation_controls(content)
	content.add_child(HSeparator.new())
	Kit.label(content,"Controls","kicker")
	Kit.label(content,controls_words(GameState.settlement_site_committed),"body")
	resume.grab_focus.call_deferred()
	return root

static func _say(label:Label,text:String,problem:bool=false)->void:
	if not is_instance_valid(label):return
	label.text=text
	label.add_theme_color_override("font_color",Kit.text_color(T.RED) if problem else T.BODY)

static func saved_words(meta:Dictionary)->String:
	if meta.is_empty():return "Nothing has been saved yet."
	return "Last saved: %s, %s, %d people." % [String(meta.get("settlement_name","")) if String(meta.get("settlement_name",""))!="" else "your people",Kit.when(int(meta.get("elapsed_days",0))).to_lower(),int(meta.get("population",0))]

static func ai_words(enabled:bool,configured:bool)->Dictionary:
	if enabled and configured:
		return {"status":"Written replies are on: type anything and your people answer in their own words.","button":"Turn off","tip":"Turn written replies off. The game then sends nothing over the network and offers set choices instead."}
	if enabled:
		return {"status":"Written replies are on, but no key is set, so your people answer from set choices.","button":"Turn off","tip":"Add a key under AI connection, or turn written replies off."}
	return {"status":"Written replies are off: your people answer from set choices.","button":"Turn on","tip":"Turn written replies on. They need a key, set under AI connection."}

static func controls_words(site_committed:bool)->String:
	var lines:=PackedStringArray()
	lines.append("Left-click land: look at its ground and water.")
	if not site_committed:lines.append("Right-click land: walk the travellers there.")
	lines.append("Click a city or a band of strangers: see what we know of it.")
	lines.append("Move the map: drag with the middle button, slide two fingers, or press W A S D. Shift and middle-drag turns it.")
	lines.append("Zoom: scroll, pinch, or the Up and Down keys.")
	lines.append("Time: 0 pauses; 1 to 5 run the days faster. Esc opens this menu.")
	return "\n".join(lines)

## One question before an action that throws away play.
static func confirm(host:Control,question:String,consequence:String,yes:String,on_yes:Callable)->Control:
	var parts:=Kit.modal(host,480.0,T.RED,"ConfirmDiscard")
	var overlay:Control=parts[0]
	var column:VBoxContainer=parts[1]
	Kit.label(column,question,"title")
	var body:=Kit.label(column,consequence,"body")
	body.custom_minimum_size.x=420
	var footer:=HBoxContainer.new()
	footer.alignment=BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation",10)
	column.add_child(footer)
	var keep:=Kit.button(footer,"Keep playing",false,func()->void:overlay.queue_free())
	keep.name="KeepPlaying"
	var go:=Kit.button(footer,yes,true,func()->void:
		overlay.queue_free()
		if on_yes.is_valid():on_yes.call())
	go.name="ConfirmYes"
	keep.grab_focus.call_deferred()
	return overlay

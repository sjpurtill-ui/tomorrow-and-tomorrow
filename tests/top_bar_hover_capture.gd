extends Node
## Visual check of the top bar's hover cards: hovers every top-bar chip and
## control with real pointer motion and captures what opens. Isolated userdata
## only (override.cfg); never saves.
##   run through tools/run_isolated_gpu_probe.ps1 with
##   -UserArguments "--out=<dir> --tag=<before|after> [--dark]"
var terrain:Node
var out_dir:=""
var tag:="after"
var capture:=true

func _ready()->void:
	if not OS.get_user_data_dir().get_file().contains("Test"):get_tree().quit(2);return
	var dark:=false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):out_dir=a.substr(6)
		if a.begins_with("--tag="):tag=a.substr(6)
		if a=="--dark":dark=true
		if a=="--nocap":capture=false
	if out_dir=="":out_dir=OS.get_user_data_dir()+"/hover_capture/"
	DirAccess.make_dir_recursive_absolute(out_dir)
	if dark:
		preload("res://scripts/hud/hud_tokens.gd").set_color_mode("dark")
		get_tree().root.theme=preload("res://scripts/hud/hud_tokens.gd").control_theme()
		tag+="-dark"
	GameState.reset_for_new_world(424242)
	DiscoverySystem.reset_for_new_world();ResourceSystem.reset_for_new_world();FoodSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world()
	GameState.civic_api_enabled=false
	terrain=load("res://local_terrain.tscn").instantiate();add_child(terrain)
	await _frames(30)
	PeopleDirection.choose("makers")
	if is_instance_valid(PeopleDirection.panel):PeopleDirection.panel.queue_free()
	await _frames(10)
	terrain._start_settlement_here()
	await _frames(10)
	if is_instance_valid(terrain.settlement_naming_panel):terrain.settlement_naming_panel.queue_free()
	terrain._set_game_speed(5)
	for i in 120:
		terrain.advance_world_time(1.0)
		_release()
		if i%10==0:await get_tree().process_frame
	terrain._set_game_speed(0)
	await _frames(30)
	var hud:Node=terrain.hud
	hud.refresh_information_bar()
	await _frames(10)
	var targets:Array=[]
	for id in ["population","food","water","goods","health","science","gdp"]:
		var chip:Control=hud.kpi_chips[id].chip
		if chip.is_visible_in_tree():targets.append([id,chip])
	targets.append(["time",hud.time_text])
	targets.append(["pause",hud.pause_button])
	targets.append(["speed3",hud.speed_buttons[3]])
	var view:=get_viewport().get_visible_rect().size
	for target in targets:
		var control:Control=target[1]
		await _move(control.get_global_rect().get_center())
		await get_tree().create_timer(0.9).timeout
		await _frames(3)
		_report(String(target[0]),control,view)
		await _cap("%s-%s" % [tag,target[0]])
		await _move(Vector2(view.x*0.5,view.y*0.6))
		await get_tree().create_timer(0.4).timeout
	# Switching straight from one chip to the next must not blink or stack.
	if targets.size()>=2:
		await _move((targets[0][1] as Control).get_global_rect().get_center())
		await get_tree().create_timer(0.9).timeout
		await _move((targets[1][1] as Control).get_global_rect().get_center())
		await _frames(4)
		print("HOVER_SWITCH open_cards=%d" % _open_cards().size())
		await _cap("%s-switch" % tag)
		await _move(Vector2(view.x*0.5,view.y*0.6))
		await get_tree().create_timer(0.3).timeout
		print("HOVER_LEAVE open_cards=%d" % _open_cards().size())
	# The card's own palette in dark mode (the bar behind it stays as built).
	if not dark and targets.size()>=2:
		var T:=preload("res://scripts/hud/hud_tokens.gd")
		T.set_color_mode("dark")
		for index in [1,3]:
			var control:Control=targets[index][1]
			await _move(control.get_global_rect().get_center())
			await get_tree().create_timer(0.9).timeout
			await _frames(3)
			_report("dark-"+String(targets[index][0]),control,view)
			await _cap("%s-darkcard-%s" % [tag,targets[index][0]])
			await _move(Vector2(view.x*0.5,view.y*0.6))
			await get_tree().create_timer(0.4).timeout
		T.set_color_mode("light")
	if not capture:
		for id in ["population","food","water","goods","health","science","gdp"]:
			print("HOVER_SPEC %s %s" % [id,JSON.stringify(preload("res://scripts/hud/kpi_detail_data.gd").card(id))])
	print("TOP_BAR_HOVER_CAPTURE DONE %s" % tag)
	get_tree().quit(0)

func _open_cards()->Array:
	var found:=[]
	for node in get_tree().root.find_children("*","",true,false):
		if node is Control and (node.name=="HoverCard" or node.name=="KpiDetailPanel") and (node as Control).is_visible_in_tree():found.append(node)
	return found

func _report(id:String,control:Control,view:Vector2)->void:
	var cards:=_open_cards()
	if cards.is_empty():
		print("HOVER %s no-card (built-in tooltip or none) text=%s" % [id,control.tooltip_text.left(60)])
		return
	for card:Control in cards:
		var r:=card.get_global_rect();var a:=control.get_global_rect()
		var host:Node=card.get_parent()
		var anchor_name:String=String(host.anchor.name) if "anchor" in host and is_instance_valid(host.anchor) else "?"
		var words:=PackedStringArray()
		for label in card.find_children("*","Label",true,false):words.append((label as Label).text)
		print("HOVER_TEXT %s | %s" % [id," | ".join(words)])
		print("HOVER %s card=%s size=%s on_screen=%s covers_anchor=%s anchor=%s anchor_rect=%s view=%s" % [id,card.get_global_rect().position,r.size,Rect2(Vector2.ZERO,view).encloses(r),r.intersects(a),anchor_name,a,view])

func _move(pos:Vector2)->void:
	# A private desktop has no real pointer: tell the viewport the pointer is
	# inside, then move it through Input as a player's mouse would.
	get_viewport().notification(Node.NOTIFICATION_VP_MOUSE_ENTER)
	var ev:=InputEventMouseMotion.new()
	var window_pos:=get_tree().root.get_final_transform()*pos
	ev.position=window_pos;ev.global_position=window_pos
	Input.parse_input_event(ev)
	Input.flush_buffered_events()
	await _frames(2)

func _release()->void:
	if terrain.game_speed<=0.0:
		if terrain.military_attention_dialog and is_instance_valid(terrain.military_attention_dialog):terrain.military_attention_dialog.queue_free()
		preload("res://scripts/hud/simulation_pause.gd").owners.erase(terrain.get_instance_id())
		terrain._set_game_speed(5)
	var dir:Node=get_tree().get_first_node_in_group("court_director")
	if dir and is_instance_valid(dir.modal):
		dir.modal.queue_free()
		preload("res://scripts/hud/simulation_pause.gd").owners.erase(terrain.get_instance_id())

func _frames(k:int)->void:
	for i in k:await get_tree().process_frame

func _cap(label:String)->void:
	if not capture:return
	await RenderingServer.frame_post_draw
	var p:=out_dir.path_join(label+".png")
	get_viewport().get_texture().get_image().save_png(p)
	print("HOVER capture ",p)

extends Node
## Visual check of the map's own cards (ground survey, founding site review,
## map help, road notice, first-contact alert, game menu, rename and settler
## cards, map contact). Run only through tools/run_isolated_gpu_probe.ps1:
##   res://tests/map_cards_capture.tscn -- --ux=<card> --out=<png path>
## It opens the real map, puts the century choice behind it, opens one card
## and saves one image. It never writes a save.

var terrain:Node

func _ready()->void:
	var mode:="lens"
	var out:=""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--ux="):mode=argument.trim_prefix("--ux=")
		elif argument.begins_with("--out="):out=argument.trim_prefix("--out=")
	GameState.select_founding_focus("provision")
	terrain=load("res://local_terrain.tscn").instantiate()
	add_child(terrain)
	for frame in 20:await get_tree().process_frame
	if WorldSimulation.direction.needs_century_choice():WorldSimulation.direction.choose(String(PeopleDirection.AMBITIONS.keys()[0]))
	if is_instance_valid(PeopleDirection.panel):PeopleDirection.panel.queue_free()
	terrain.set("game_speed",0.0)
	for frame in 5:await get_tree().process_frame
	var home:Vector3=terrain.settler_marker.position
	match mode:
		"lens":
			terrain._inspect_location(home+Vector3(0.35,0,0.2))
		"site":
			terrain._open_founding_site_guide(home)
		"help":
			terrain._toggle_map_help()
		"road":
			terrain._issue_travel_council_report("departure",0.0)
		"alert":
			terrain._on_diplomatic_event({"kind":"first_contact","civ_id":"capture","day":int(GameState.elapsed_days),"title":"Strangers at the ford","description":"Our hunters met a band of strangers at the river ford, two days' walk to the east. They traded words and a little dried fish, then went their way.","position":{"x":home.x+3.0,"z":home.z}})
		"menu":
			terrain._open_world_menu()
		"uncharted":
			terrain._inspect_location(home+Vector3(900,0,900))
		"settler":
			# The settler card with sample facts, as it looks over the map.
			preload("res://scripts/hud/caravan_panel.gd").open_settler_card(terrain.interface_layer,{"name":"Waterford","origin_name":"Ashford","leader":"Tilla","leader_summary":"Seasoned on the road","people":40,"food_days":38.0,"journey":"6 days","distance_km":24.0,"supplies":"40.0 timber and 12.0 plant fiber","water_title":"Fresh water nearby","water_text":"Stream · 0.4 km W. Dry ground near known fresh water.","ready":true,"advice":"Tilla: two camps by the stream, then over the ridge. Enough for the march and about 30 days to establish the new home."},func():pass,func():pass)
		"all":
			# Headless smoke: every card opens and closes on the real map.
			terrain._inspect_location(home+Vector3(0.35,0,0.2))
			terrain._inspect_location(home+Vector3(900,0,900))
			terrain._close_lens()
			terrain._open_founding_site_guide(home)
			terrain._close_founding_site_guide()
			terrain._toggle_map_help()
			terrain._issue_travel_council_report("departure",0.0)
			terrain._on_diplomatic_event({"kind":"first_contact","civ_id":"","day":int(GameState.elapsed_days),"title":"Strangers at the ford","description":"Our hunters met strangers.","position":{"x":home.x+3.0,"z":home.z}})
			terrain._open_world_menu()
			for frame in 4:await get_tree().process_frame
			terrain._close_world_menu()
			terrain._on_hud_section_requested("economy",0)
			terrain._on_hud_section_requested("",0)
			terrain.advance_world_time(3.0) if terrain.has_method("advance_world_time") else null
	for frame in 12:await get_tree().process_frame
	RenderingServer.force_draw(true,0.0)
	await get_tree().process_frame
	if out!="" and DisplayServer.get_name()!="headless":
		var image:=get_viewport().get_texture().get_image()
		if image:image.save_png(out)
	print("MAP CARDS CAPTURE ",mode," -> ",out)
	get_tree().quit()

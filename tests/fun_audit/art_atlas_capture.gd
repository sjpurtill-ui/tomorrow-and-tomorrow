extends "res://tests/fun_audit/wave2_capture.gd"
## Art fix (codex/art-atlas) captures: The People, the research atlas and the
## discovery card mid-reveal and settled. Isolated userdata; never saves.

func _ready()->void:
	if not OS.get_user_data_dir().ends_with("Tests"):
		push_error("needs isolated userdata");get_tree().quit(2);return
	out_dir=_arg("out-dir",ProjectSettings.globalize_path("user://art_atlas_capture/"))
	DirAccess.make_dir_recursive_absolute(out_dir)
	var size:=Vector2i(1600,900)
	get_window().size=size;get_window().content_scale_size=size
	GameState.reset_for_new_world(int(_arg("seed","424242")))
	DiscoverySystem.reset_for_new_world();ResourceSystem.reset_for_new_world();FoodSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world()
	GameState.civic_api_enabled=false
	terrain=load("res://local_terrain.tscn").instantiate();add_child(terrain)
	await _frames(30)
	PeopleDirection.choose(_arg("ambition","makers"))
	if is_instance_valid(PeopleDirection.panel):PeopleDirection.panel.queue_free()
	await _frames(60)
	var tries:=0
	while not GameState.settlement_site_committed and tries<40:
		tries+=1
		terrain._start_settlement_here()
		if not GameState.settlement_site_committed:
			terrain.advance_world_time(1.0);_clear();await _frames(2)
	if is_instance_valid(terrain.settlement_naming_panel):terrain.settlement_naming_panel.queue_free()
	await _advance_to(int(_arg("day","420")))
	await _look_at_hearth(OPENING_FEET)
	# Chronicle notices are set aside so each capture shows one screen.
	preload("res://scripts/chronicle.gd").pending_cards.clear()
	var card:Variant=terrain.hud.get_meta("chronicle_card") if terrain.hud.has_meta("chronicle_card") else null
	if is_instance_valid(card):card.queue.clear();card.dismiss()
	await _frames(30)
	# 1. The People: faces at the fire.
	terrain._on_hud_section_requested("overview",0)
	await _frames(60)
	await _cap("b1-people")
	terrain._on_hud_section_requested("",0)
	await _frames(10)
	# 2. The research atlas.
	preload("res://scripts/hud/knowledge_atlas.gd").open(terrain,terrain.hud,"inquiry")
	await _frames(60)
	await _cap("b2-research-atlas")
	var atlas_layer:Node=terrain.hud.get_meta("knowledge_atlas")
	atlas_layer.get_child(0).set_view("known")
	await _frames(40)
	await _cap("b3-research-known")
	atlas_layer.queue_free()
	await _frames(10)
	# 3. The discovery card: mid-reveal and settled.
	var id:=String(GameState.known_discoveries[-1]) if not GameState.known_discoveries.is_empty() else "cordage"
	preload("res://scripts/hud/discovery_popup.gd").announce(terrain,terrain.hud,[{"id":id,"day":int(GameState.elapsed_days)}])
	await _frames(24)
	await _cap("b4-discovery-reveal")
	await _frames(120)
	await _cap("b5-discovery-card")
	print("ART_ATLAS_CAPTURE DONE")
	get_tree().quit(0)

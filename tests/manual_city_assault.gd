extends Node
var terrain:Node
var city_id:String
var civ_id:String
var army_id:int
func _ready()->void:
	assert(OS.get_user_data_dir().ends_with("TomorrowAndTomorrow_CityAssault_Test"))
	GameState.reset_for_new_world(74017)
	GameState.ensure_population_total(10000)
	GameState.settlement_name="TEST HOME"
	GameState.settlement_site_committed=true
	GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world();ProgressionSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world();ForeignDiplomacy.ensure();FoodSystem.reset_for_new_world()
	GameState.resource_stockpiles["Food"]=1000000.0
	assert(int(MilitaryCampaign.raise_recruits(180).get("raised",0))==180)
	var training:=MilitaryCampaign.start_training("levy","improvised",180)
	assert(not training.has("error"))
	MilitaryCampaign._complete_training(MilitaryCampaign.training_queue[0].duplicate(true));MilitaryCampaign.training_queue.clear()
	var formed:=MilitaryCampaign.create_field_army(180);assert(not formed.has("error"))
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ_id=String(civ.id);civ.name="TEST CITY COUNCIL"
	civ.population=3000.0;civ.cohorts=CivilizationSystem._scaled_cohorts(civ.cohorts,3000.0)
	civ.military_population=500.0;civ.knowledge=.15;civ.logistics=.6;civ.military_readiness=.65;civ.command_readiness=.55;civ.cohesion=.65;civ.institutions=.45;civ.food_days=90.0
	civ.player_relation.at_war=false;civ.player_relation.treaty="none";civ.player_relation.war_id=""
	civ.player_relation.contact_level=2;civ.player_relation.contact_intelligence=.9;civ.player_relation.home_location_known=true
	var region:Dictionary=civ.strategic_regions[CivilizationSystem._frontline_region_index(civ)]
	city_id=String(region.id);region.name="TEST RIVER CITY";region.population=600.0;region.strategic_weight=.25;region.fortification=.2;region.damage=0.0;region.controller=civ_id
	var other_total:=0.0
	for other:Dictionary in civ.strategic_regions:
		if String(other.id)!=city_id:other_total+=float(other.population)
	for other:Dictionary in civ.strategic_regions:
		if String(other.id)!=city_id:other.population=float(other.population)*2400.0/maxf(1,other_total)
	CivilizationSystem.city_intelligence.publish("player",CivilizationSystem.city_intelligence.capture("player",city_id,.95,0,"TEST SETUP: complete scenario briefing","manual-assault"),0)
	var report:Dictionary=CivilizationSystem.city_intelligence.known("player",city_id)
	var army:Dictionary=MilitaryCampaign.field_armies[0];army_id=int(army.army_id)
	army.name="TEST ASSAULT ARMY";army.location_id=city_id;army.location_name=String(region.name);army.position=report.position.duplicate(true);army.position.x=float(army.position.x)+.06;army.status="stationed";army.supply_level=1.0;army.morale=.85
	for formation:Dictionary in army.formations:formation.personnel_condition=1.0;formation.drill_skill=.65
	MilitaryCampaign._refresh_readiness()
	CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	terrain=preload("res://local_terrain.tscn").instantiate();get_tree().root.add_child.call_deferred(terrain)
	await get_tree().process_frame
	get_tree().current_scene=terrain;terrain._set_game_speed(0)
	terrain._focus_known_city(city_id);terrain.selected_army_id=army_id
	for frame in 70:await get_tree().process_frame
	var incident:=CivilizationSystem.offensive_campaign_data(civ_id,180,city_id)
	assert(not incident.has("error"));assert(MilitaryCampaign.active_engagement.is_empty())
	var layer:=CanvasLayer.new();layer.layer=150;add_child(layer)
	var panel:=PanelContainer.new();panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE);layer.add_child(panel)
	var bar:=HBoxContainer.new();panel.add_child(bar)
	var label:=Label.new();label.text="  TEST ONLY  •  180 attackers / %d defenders / 600 residents  •  seed 74017  •  campaign isolated" % int(incident.strength);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;bar.add_child(label)
	var report_button:=Button.new();report_button.text="CITY / ATTACK";bar.add_child(report_button);report_button.pressed.connect(func():CivilizationSystem.city_intelligence.open(city_id))
	var reset:=Button.new();reset.text="RESET TEST";bar.add_child(reset);reset.pressed.connect(func():OS.create_process(OS.get_executable_path(),["--path",ProjectSettings.globalize_path("res://"),"res://tests/manual_city_assault.tscn"]);get_tree().quit())
	CivilizationSystem.city_intelligence.open(city_id)
	get_window().title="CITY ASSAULT TEST — 180 vs %d — NOT YOUR CAMPAIGN" % int(incident.strength)
	print("MANUAL_ASSAULT_READY ",JSON.stringify({"seed":74017,"attackers":180,"defenders":incident.strength,"residents":600,"occupation_required":incident.occupation_required,"paused":terrain.game_speed==0,"battle_started":not MilitaryCampaign.active_engagement.is_empty(),"user_data":OS.get_user_data_dir(),"city":city_id,"army":army_id}))
	if "--verify-setup" in OS.get_cmdline_user_args():
		for frame in 15:await get_tree().process_frame
		var screen=CivilizationSystem.city_intelligence.screen_layer.get_child(0)
		assert(screen.attack.visible and not screen.attack.disabled and screen.attack.text=="ATTACK NOW")
		assert(MilitaryCampaign.active_engagement.is_empty() and MilitaryCampaign.pending_aftermath.is_empty())
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://artifacts/manual-assault-ready.png")
		print("MANUAL_SETUP_VERIFIED: Attack Now enabled; no battle played; no campaign save loaded")
		get_tree().quit()

extends Node
var terrain:Node
var city_id:String
var civ_id:String
var army_id:int
var attack_button:Button
var action_panel:PanelContainer
var action_note:Label
func _ready()->void:
	assert(OS.get_user_data_dir().ends_with("TomorrowAndTomorrow_CityAssault_Test"))
	GameState.reset_for_new_world(74017)
	PeopleDirection.reset_for_new_world();PeopleDirection.choose("military")
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
	army.last_report=MilitaryCampaign._army_report_snapshot(army)
	CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	terrain=preload("res://local_terrain.tscn").instantiate()
	var score:=terrain.get_node_or_null("Score") as AudioStreamPlayer
	if score:score.autoplay=false;score.volume_db=-80.0
	get_tree().root.add_child.call_deferred(terrain)
	await get_tree().process_frame
	get_tree().current_scene=terrain;terrain._set_game_speed(0)
	terrain._focus_known_city(city_id);terrain.selected_army_id=-1
	terrain.camera.size=maxf(.24,terrain.camera.size);terrain._update_camera();terrain._update_scale_lod()
	for frame in 70:await get_tree().process_frame
	var incident:=CivilizationSystem.offensive_campaign_data(civ_id,180,city_id)
	assert(not incident.has("error"));assert(MilitaryCampaign.active_engagement.is_empty())
	var layer:=CanvasLayer.new();layer.layer=150;add_child(layer)
	var panel:=PanelContainer.new();panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE);layer.add_child(panel)
	var bar:=HBoxContainer.new();panel.add_child(bar)
	var label:=Label.new();label.text="  TEST ONLY  •  180 attackers / %d defenders / 600 residents  •  seed 74017  •  campaign isolated" % int(incident.strength);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;bar.add_child(label)
	var report_button:=Button.new();report_button.text="CITY REPORT";bar.add_child(report_button);report_button.pressed.connect(func():CivilizationSystem.city_intelligence.open(city_id))
	var reset:=Button.new();reset.text="RESET TEST";bar.add_child(reset);reset.pressed.connect(func():OS.create_process(OS.get_executable_path(),["--path",ProjectSettings.globalize_path("res://"),"res://tests/manual_city_assault.tscn"]);get_tree().quit())
	action_panel=PanelContainer.new();action_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT);action_panel.position=Vector2(get_viewport().get_visible_rect().size.x-370,86);action_panel.size=Vector2(340,100);layer.add_child(action_panel)
	var actions:=VBoxContainer.new();action_panel.add_child(actions)
	action_note=Label.new();action_note.text="TEST ASSAULT ARMY selected\nTarget: Test River City";actions.add_child(action_note)
	attack_button=Button.new();attack_button.text="ATTACK TEST RIVER CITY";attack_button.custom_minimum_size.y=46;actions.add_child(attack_button);attack_button.pressed.connect(_attack)
	action_panel.visible=false
	get_window().title="CITY ASSAULT TEST — 180 vs %d — NOT YOUR CAMPAIGN" % int(incident.strength)
	print("MANUAL_ASSAULT_READY ",JSON.stringify({"seed":74017,"attackers":180,"defenders":incident.strength,"residents":600,"occupation_required":incident.occupation_required,"paused":terrain.game_speed==0,"battle_started":not MilitaryCampaign.active_engagement.is_empty(),"user_data":OS.get_user_data_dir(),"city":city_id,"army":army_id}))
	if "--verify-setup" in OS.get_cmdline_user_args():
		for frame in 15:await get_tree().process_frame
		assert(not is_instance_valid(CivilizationSystem.city_intelligence.screen_layer))
		assert(not is_instance_valid(terrain.founding_focus_panel) and not is_instance_valid(PeopleDirection.panel))
		assert(terrain.selected_army_id==-1 and not action_panel.visible)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://artifacts/manual-map-ready.png")
		var marker:Node3D=terrain.player_field_army_markers[str(army_id)]
		assert(marker.visible)
		await click(terrain.camera.unproject_position(marker.global_position))
		for frame in 5:await get_tree().process_frame
		assert(terrain.selected_army_id==army_id and action_panel.visible)
		await click(attack_button.get_global_rect().get_center())
		for frame in 20:await get_tree().process_frame
		assert(not MilitaryCampaign.active_engagement.is_empty())
		assert(int(MilitaryCampaign.active_engagement.round)==0 and terrain.game_speed==0)
		assert(is_instance_valid(MilitaryCommandUI.battle_graphics) and MilitaryCommandUI.battle_graphics.is_visible_in_tree())
		assert(not is_instance_valid(terrain.founding_focus_panel) and not is_instance_valid(PeopleDirection.panel))
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://artifacts/manual-map-battle.png")
		print("MANUAL_MAP_INPUT_PASS: actual army mouse click -> contextual attack mouse click -> visible battle round0; no founding screen; music muted")
		get_tree().quit()

func _process(_delta:float)->void:
	if is_instance_valid(action_panel):
		action_panel.visible=terrain.selected_army_id==army_id and MilitaryCampaign.active_engagement.is_empty() and MilitaryCampaign.pending_aftermath.is_empty() and not is_instance_valid(CivilizationSystem.city_intelligence.screen_layer)
func _attack()->void:
	var result:=MilitaryCampaign.order_city_operation(army_id,civ_id,city_id)
	print("MANUAL_ATTACK_RESULT ",JSON.stringify({"error":result.get("error",""),"battle_started":not MilitaryCampaign.active_engagement.is_empty()}))
	if result.has("error"):action_note.text=String(result.error)
func click(point:Vector2)->void:
	var motion:=InputEventMouseMotion.new();motion.position=point;motion.global_position=point;get_viewport().push_input(motion,true)
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new();event.position=point;event.global_position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;get_viewport().push_input(event,true)
		await get_tree().process_frame

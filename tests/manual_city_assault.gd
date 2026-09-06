extends Node
var terrain:Node
var city_id:String
var civ_id:String
var army_id:int
var attack_button:Button
var action_panel:PanelContainer
var action_note:Label
var fixture_attacker_count:=180
var fixture_population:=10000
var fixture_equipment:=0
func _ready()->void:
	assert(OS.get_user_data_dir().ends_with("TomorrowAndTomorrow_CityAssault_Test") or OS.get_user_data_dir().ends_with("TomorrowAndTomorrow_FocusedJourney_Test"))
	GameState.reset_for_new_world(74017)
	PeopleDirection.reset_for_new_world();PeopleDirection.choose("military")
	GameState.ensure_population_total(fixture_population)
	GameState.settlement_name="TEST HOME"
	GameState.settlement_site_committed=true
	GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world();ProgressionSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world();ForeignDiplomacy.ensure();FoodSystem.reset_for_new_world()
	GameState.resource_stockpiles["Food"]=1000000.0
	MilitaryCampaign.military_inventory.improvised=fixture_equipment
	assert(int(MilitaryCampaign.raise_recruits(fixture_attacker_count).get("raised",0))==fixture_attacker_count)
	var training:=MilitaryCampaign.start_training("levy","improvised",fixture_attacker_count)
	assert(not training.has("error"))
	MilitaryCampaign._complete_training(MilitaryCampaign.training_queue[0].duplicate(true));MilitaryCampaign.training_queue.clear()
	var formed:=MilitaryCampaign.create_field_army(fixture_attacker_count);assert(not formed.has("error"))
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
	# Scenario placement must validate its whole footprint, not just the polity anchor.
	var previous_city:=Vector2(float(report.position.x),float(report.position.z))
	var safe_city:=Vector2.INF
	for ring in range(1,31):
		for sector in 16:
			var candidate:=previous_city+Vector2.from_angle(float(sector)*TAU/16.0)*float(ring)*2.0
			var dry:=true
			for dx in [-3.0,0.0,3.0]:
				for dz in [-3.0,0.0,3.0]:
					if terrain._height_at(candidate.x+dx,candidate.y+dz)<.18:dry=false
			if dry:safe_city=candidate;break
		if safe_city!=Vector2.INF:break
	assert(safe_city!=Vector2.INF)
	var previous_home:=CivilizationSystem._civilization_world_position(civ)
	var relocated_home:=previous_home+safe_city-previous_city
	civ.position=Vector2(relocated_home.x/CivilizationSystem.CIVILIZATION_WORLD_RADIUS_X_KM,relocated_home.y/CivilizationSystem.CIVILIZATION_WORLD_RADIUS_Z_KM)
	CivilizationSystem.city_intelligence.publish("player",CivilizationSystem.city_intelligence.capture("player",city_id,.95,0,"TEST SETUP: verified dry site","manual-assault-dry"),0)
	report=CivilizationSystem.city_intelligence.known("player",city_id)
	army.position=report.position.duplicate(true);army.position.x=float(army.position.x)+.06
	army.last_report=MilitaryCampaign._army_report_snapshot(army)
	print("DRY_SITE ",JSON.stringify({"position":report.position,"height":terrain._height_at(float(report.position.x),float(report.position.z)),"minimum_sampled_margin":.18,"sample_radius_km":3}))
	terrain._focus_known_city(city_id);terrain.selected_army_id=-1
	terrain.camera.size=maxf(.24,terrain.camera.size);terrain._update_camera();terrain._update_scale_lod()
	for frame in 70:await get_tree().process_frame
	if "--diagnose-water" in OS.get_cmdline_user_args():
		terrain.camera.size=1.5;terrain._update_camera();terrain._update_scale_lod()
		for frame in 40:await get_tree().process_frame
		print("WATER_DIAG ",JSON.stringify({"city":report.position,"height":terrain._height_at(float(report.position.x),float(report.position.z)),"near":terrain.camera.near,"far":terrain.camera.far}))
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://artifacts/water-before.png")
		for mesh in terrain.get_children():
			if mesh is MeshInstance3D and mesh.mesh is PlaneMesh and mesh.material_override is ShaderMaterial and "ROUGHNESS=0.40" in mesh.material_override.shader.code:
				print("WATER_PLANE_HIDDEN ",mesh.mesh.size);mesh.hide()
		for frame in 5:await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://artifacts/water-after.png")
		get_tree().quit();return
	var incident:=CivilizationSystem.offensive_campaign_data(civ_id,180,city_id)
	assert(not incident.has("error"));assert(MilitaryCampaign.active_engagement.is_empty())
	var layer:=CanvasLayer.new();layer.layer=150;add_child(layer)
	var panel:=PanelContainer.new();panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE);layer.add_child(panel)
	var bar:=HBoxContainer.new();panel.add_child(bar)
	var label:=Label.new();label.text="  NEW BATTLE HUD · TEST ONLY  •  180 attackers / %d defenders / 600 residents  •  seed 74017  •  campaign isolated" % int(incident.strength);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;label.add_theme_font_size_override("font_size",12);bar.add_child(label)
	var report_button:=Button.new();report_button.text="CITY REPORT";bar.add_child(report_button);report_button.pressed.connect(func():CivilizationSystem.city_intelligence.open(city_id))
	var reset:=Button.new();reset.text="RESET TEST";bar.add_child(reset);reset.pressed.connect(func():OS.create_process(OS.get_executable_path(),["--path",ProjectSettings.globalize_path("res://"),"--fullscreen","res://tests/manual_city_assault.tscn"]);get_tree().quit())
	action_panel=PanelContainer.new();action_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT);action_panel.position=Vector2(get_viewport().get_visible_rect().size.x-370,86);action_panel.size=Vector2(340,100);layer.add_child(action_panel)
	var actions:=VBoxContainer.new();action_panel.add_child(actions)
	action_note=Label.new();action_note.text="TEST ASSAULT ARMY selected\nTarget: Test River City";actions.add_child(action_note)
	attack_button=Button.new();attack_button.text="ATTACK TEST RIVER CITY";attack_button.custom_minimum_size.y=46;actions.add_child(attack_button);attack_button.pressed.connect(_attack)
	action_panel.visible=false
	get_window().title="NEW BATTLE HUD · CITY ASSAULT TEST — 180 vs %d — NOT YOUR CAMPAIGN" % int(incident.strength)
	print("MANUAL_ASSAULT_READY ",JSON.stringify({"seed":74017,"attackers":fixture_attacker_count,"defenders":incident.strength,"residents":600,"occupation_required":incident.occupation_required,"paused":terrain.game_speed==0,"battle_started":not MilitaryCampaign.active_engagement.is_empty(),"user_data":OS.get_user_data_dir(),"city":city_id,"army":army_id}))
	if "--verify-setup" in OS.get_cmdline_user_args() or "--verify-hud" in OS.get_cmdline_user_args():
		for frame in 15:await get_tree().process_frame
		assert(not is_instance_valid(CivilizationSystem.city_intelligence.screen_layer))
		assert(not is_instance_valid(terrain.founding_focus_panel) and not is_instance_valid(PeopleDirection.panel))
		assert(terrain.selected_army_id==-1 and not action_panel.visible)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://artifacts/manual-map-ready.png")
		for size:float in [.055,.24,1.5,6.0]:
			terrain.camera.size=size;terrain._update_camera();terrain._update_scale_lod()
			for frame in 15:await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://artifacts/dry-zoom-%s.png" % str(size))
		terrain.camera.size=.24;terrain._update_camera();terrain._update_scale_lod()
		for frame in 15:await get_tree().process_frame
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
		if "--verify-hud" in OS.get_cmdline_user_args():await _verify_hud()
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
func _verify_hud()->void:
	var hud:BattleGraphicsScreen=MilitaryCommandUI.battle_graphics
	await _hud_capture("orders")
	await click(hud.camera_buttons.frontline.get_global_rect().get_center());assert(hud.view.zoom==32)
	await click(hud.camera_buttons.overview.get_global_rect().get_center());assert(hud.view.zoom==(220 if hud.view.live_terrain!=null else 85) and not hud.view.cinematic)
	assert(hud.phase=="orders" and hud.resolve_button.disabled)
	await click(hud.targets.get_child(0).get_global_rect().get_center())
	await click(hud.order_buttons.charge.get_global_rect().get_center())
	assert(hud._orders().get("0",{}).get("kind","")=="charge")
	await click(hud.order_buttons.hold.get_global_rect().get_center())
	assert(not hud.resolve_button.disabled)
	await click(hud.resolve_button.get_global_rect().get_center())
	assert(hud.phase=="resolving" and hud.resolve_count==1)
	await click(hud.pause_button.get_global_rect().get_center())
	var paused_at:=hud.elapsed;var committed:=MilitaryCampaign.export_state().duplicate(true)
	for frame in 10:await get_tree().process_frame
	assert(hud.elapsed==paused_at)
	await click(hud.pause_button.get_global_rect().get_center())
	await get_tree().create_timer(2.0).timeout
	await click(hud.pause_button.get_global_rect().get_center())
	await _hud_capture("resolving")
	await click(hud.skip_button.get_global_rect().get_center())
	assert(hud.phase in ["result","ended"] and hud.resolve_count==1)
	assert(MilitaryCampaign.export_state()==committed)
	await _hud_capture("result")
	await click(hud.replay_button.get_global_rect().get_center())
	assert(hud.replaying and hud.phase=="resolving")
	await click(hud.skip_button.get_global_rect().get_center())
	assert(not hud.replaying and hud.resolve_count==1 and MilitaryCampaign.export_state()==committed)
	get_window().size=Vector2i(1000,720)
	for frame in 10:await get_tree().process_frame
	await _hud_capture("small-result")
	if hud.phase=="result":
		await click(hud.result_primary.get_global_rect().get_center())
		assert(hud.phase=="orders")
		await _hud_capture("small-orders")
		var actual_forces:Array=hud.cached_forces.duplicate(true)
		for side in 2:
			var sample:Dictionary=hud.cached_forces[side].formations[0].duplicate(true);hud.cached_forces[side].formations=[]
			for i in 13:
				var f:Dictionary=sample.duplicate(true);f.count=10;hud.cached_forces[side].formations.append(f)
		get_window().size=Vector2i(900,700)
		for frame in 6:await get_tree().process_frame
		hud._rebuild_orders();hud._phase_ui()
		await _hud_capture("small-roster-many")
		await click(hud.small_toggle.get_global_rect().get_center())
		await _hud_capture("small-targets-many")
		hud.cached_forces=actual_forces;hud._rebuild_orders();hud._phase_ui()
		get_window().size=Vector2i(1000,720)
		for frame in 6:await get_tree().process_frame
		if "--verify-retreat" in OS.get_cmdline_user_args():
			await click(hud.retreat_button.get_global_rect().get_center())
			await click(hud.skip_button.get_global_rect().get_center())
		else:
			for round_index in 15:
				if hud.phase=="ended":break
				if hud.phase=="result":await click(hud.result_primary.get_global_rect().get_center())
				hud._hold_all()
				await click(hud.resolve_button.get_global_rect().get_center())
				await click(hud.skip_button.get_global_rect().get_center())
	assert(hud.phase=="ended" and MilitaryCampaign.active_engagement.is_empty())
	await _hud_capture("ended")
	if not MilitaryCampaign.pending_aftermath.is_empty():
		await click(hud.result_primary.get_global_rect().get_center())
		assert(hud.phase=="aftermath")
		await _hud_capture("aftermath")
		await click(hud.result_primary.get_global_rect().get_center())
		assert(MilitaryCampaign.pending_aftermath.is_empty())
	# Exercise the victory policy panel with a clearly synthetic UI fixture only.
	# The real 180-v-119 baseline above remains unchanged and is recorded first.
	if "--verify-aftermath" in OS.get_cmdline_user_args():
		MilitaryCampaign.pending_aftermath={"type":"surrender","captor":"TEST ASSAULT ARMY","home_force_name":"TEST ASSAULT ARMY","prisoners":8,"captured_general":false,"spoils":{}}
		hud._show_result();hud._phase_ui()
		await click(hud.result_primary.get_global_rect().get_center())
		assert(hud.phase=="aftermath")
		await _hud_capture("aftermath-fixture")
		await click(hud.result_primary.get_global_rect().get_center())
		assert(MilitaryCampaign.pending_aftermath.is_empty())
	await click(hud.result_primary.get_global_rect().get_center())
	for frame in 5:await get_tree().process_frame
	assert(not is_instance_valid(MilitaryCommandUI.battle_graphics))
	assert(not MilitaryCommandUI.modal.visible)
	print("HUD_MOUSE_PASS orders,target,charge,hold,resolve-once,pause,skip,replay-without-state-change,next-orders,ended; aftermath_pending=",not MilitaryCampaign.pending_aftermath.is_empty()," retreat_test=", "--verify-retreat" in OS.get_cmdline_user_args())
func _hud_capture(suffix:String)->void:
	for frame in 6:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var hud:BattleGraphicsScreen=MilitaryCommandUI.battle_graphics
	for node in hud.find_children("*","Button",true,false):
		if not node.is_visible_in_tree():continue
		var rect:Rect2=node.get_global_rect()
		if node.is_ancestor_of(hud.bottom):continue
		if hud.left_panel.is_ancestor_of(node) or hud.right_panel.is_ancestor_of(node):assert(rect.end.y<=hud.bottom.position.y,"Order panel overlaps bottom controls: "+node.text)
		assert(rect.position.x>=-1 and rect.position.y>=-1 and rect.end.x<=hud.size.x+1 and rect.end.y<=hud.size.y+1,"HUD button outside window: "+node.text+str(rect)+str(hud.size))
	get_viewport().get_texture().get_image().save_png("res://artifacts/battle-hud-"+suffix+".png")

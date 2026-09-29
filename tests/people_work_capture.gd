extends Node
## TEST CAPTURE HARNESS, not the game: renders The People view (the rail's
## "The People", dock_content_overview.gd) on a prepared test world and saves
## it, for UX review of who does the daily work. Run it only through
## tools/run_isolated_gpu_probe.ps1 with user arguments
##   --case=early|late --out=<absolute png path>
##   [--mode=dark] [--work=leaders|ruler] [--scroll=<pixels>|labor] [--dump]
## early: a hearth of about ninety souls; late: a large lettered town.
## --work=ruler puts the daily work in the ruler's hands (manual_work.gd) and
## takes a few off getting food, so the plain warning shows.
## It never writes a save and quits by itself.
const DockPanel:=preload("res://scripts/hud/dock_panel.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")
const MANUAL_WORK:="res://scripts/manual_work.gd"

class CaptureHud extends Control:
	signal section_requested(section:String,sub:int)
	var dock:Node
	func request_immediate_dock_refresh()->void:
		if dock!=null and dock.provider!=null:dock.present(dock.provider,0)
	func open_detail(_provider:Object,_sub:int=0)->void:pass

## Stands in for the map so the provider can bind its map actions.
class StubTerrain extends Node:
	func _settlement_display_name()->String:return "Seanstone"
	func _open_settlement_naming_panel(_id:String="")->void:pass
	func _discovery_context()->Dictionary:return {}
	func _report_military_action(_r:Dictionary)->void:pass
	func _able_population()->int:return 60
	func _on_settlement_action_pressed()->void:pass

func _ready()->void:
	get_tree().create_timer(60.0).timeout.connect(func():get_tree().quit(3))
	var case:="early";var out:="";var mode:="light";var work:="leaders";var scroll:=""
	for argument:String in OS.get_cmdline_user_args():
		if argument.begins_with("--case="):case=argument.trim_prefix("--case=")
		elif argument.begins_with("--out="):out=argument.trim_prefix("--out=")
		elif argument.begins_with("--mode="):mode=argument.trim_prefix("--mode=")
		elif argument.begins_with("--work="):work=argument.trim_prefix("--work=")
		elif argument.begins_with("--scroll="):scroll=argument.trim_prefix("--scroll=")
	T.set_color_mode(mode)
	get_window().size=Vector2i(1600,900)
	_world(case)
	if work=="ruler" and ResourceLoader.exists(MANUAL_WORK):
		var manual:GDScript=load(MANUAL_WORK)
		manual.call("set_manual",true)
		# Five fewer getting food and more building: the stores begin to fall.
		manual.call("move","Construction",5)
		manual.call("move","Knowledge",1)
	var backdrop:=ColorRect.new();backdrop.color=Color("#8f8a68");backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(backdrop)
	var hud:=CaptureHud.new();hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(hud)
	var panel=DockPanel.new();hud.add_child(panel);hud.dock=panel
	# Where the rail HUD puts a wide dock (command_rail_hud.gd _layout).
	var view:=get_viewport().get_visible_rect().size
	panel.position=Vector2(T.DOCK_X,56);panel.size=Vector2(clampf(view.x*.65,720.0,980.0),view.y-64-T.DOCK_MARGIN_Y)
	var terrain:=StubTerrain.new();add_child(terrain)
	var provider=load("res://scripts/hud/content/dock_content_overview.gd").new(terrain,hud)
	panel.present(provider,0)
	for frame in 30:await get_tree().process_frame
	if scroll=="labor":
		var labor:=panel.body.find_child("Labor",true,false) as Control
		if labor!=null:
			panel.body_scroll.scroll_vertical=maxi(0,int(labor.get_global_rect().position.y-panel.body_scroll.get_global_rect().position.y)-12)
			for frame in 4:await get_tree().process_frame
	elif scroll.is_valid_int() and int(scroll)>0:
		panel.body_scroll.scroll_vertical=int(scroll)
		for frame in 4:await get_tree().process_frame
	if "--dump" in OS.get_cmdline_user_args():
		var labor:Node=panel.body.find_child("Labor",true,false)
		if labor!=null:
			for child in labor.find_children("*","",true,false):
				if child is Label and (child as Label).text!="":print("LABOR ",child.name," | ",(child as Label).text)
				elif child is Button:print("BUTTON ",child.name," | ",(child as Button).text," | ",(child as Button).tooltip_text.replace("\n"," / "))
	await RenderingServer.frame_post_draw
	if out!="" and DisplayServer.get_name()!="headless":
		DirAccess.make_dir_recursive_absolute(out.get_base_dir())
		get_viewport().get_texture().get_image().save_png(out)
	print("PEOPLE_WORK_CAPTURE ",case," ",mode," ",work," -> ",out)
	T.set_color_mode("light")
	get_tree().quit(0)

func _world(case:String)->void:
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(515151 if case=="early" else 616161);GameState.civic_api_enabled=false
	ResourceSystem.reset_for_new_world();FoodSystem.reset_for_new_world();SettlementModel.reset_for_new_world()
	DiscoverySystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world();ForeignDiplomacy.ensure();GovernmentPeopleSystem.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.settlement_founded_day=0
	PeopleDirection.reset_for_new_world()
	match case:
		"late":_late()
		_:_early()
	PeopleDirection.ensure()
	# The leaders share out today's work as they do each day.
	GovernmentPeopleSystem._delegate_settlements(int(GameState.elapsed_days))

## About ninety souls under the first roofs, thirty-one years after the founding.
func _early()->void:
	GameState.ensure_population_total(93)
	GameState.elapsed_days=31*365+120
	GameState.settlement_completed=["Hearth Circle","Lean-to Shelters","Storage Pits"];GameState.settlement_site_committed=true;GameState.settlement_name="Seanstone"
	SettlementModel.ensure_founded();GovernmentPeopleSystem.initialize()
	GameState.housing_capacity=96
	GameState.food_stocks.merge({"Fresh food":900.0,"Stored food":4900.0},true)
	GameState.simulation_metrics.merge({"food_days":212.0,"food_production":31.0,"food_consumption":27.4,"food_eaten":27.4,"food_spoilage":1.2,"food_net":2.4,"food_total_stock":5800.0,"food_workers":33.0,"food_projected_days":9999.0,"food_weather_factor":0.95,"food_harvest":{"Fresh plants":19.0,"Fresh meat":9.0,"Fish":3.0},"housing_ratio":1.0,"labor_efficiency":0.74,"cohesion":0.8,"legitimacy":0.7,"logistics":0.22,"material_capacity":0.18},true)
	GameState.water_metrics={"required_today":93.0,"collected_today":96.0,"household_collected_today":60.0,"organized_collection_capacity":40.0,"collection_workers":8.0,"intake_ratio":1.0,"stored":40.0,"days":0.4,"source_accessible":true}

## A large lettered town.
func _late()->void:
	GameState.ensure_population_total(2400)
	GameState.elapsed_days=180*365+40
	GameState.known_discoveries.append_array(["pictographic_records","latrine_siting","protected_wellheads","seed_selection"])
	GameState.settlement_completed=["Hearth Circle","Lean-to Shelters","Storage Pits","Public Stores","Gathering Yard","Open Work Area","Framed Hall"];GameState.settlement_site_committed=true;GameState.settlement_name="Seanstone"
	SettlementModel.ensure_founded();GovernmentPeopleSystem.initialize()
	GameState.housing_capacity=2250
	GameState.population_health=0.84;GameState.food_security=0.8
	GameState.food_stocks.merge({"Fresh food":16000.0,"Stored food":180000.0},true)
	GameState.simulation_metrics.merge({"food_days":96.0,"food_production":702.0,"food_consumption":702.0,"food_eaten":702.0,"food_spoilage":14.0,"food_net":-14.0,"food_total_stock":196000.0,"food_workers":720.0,"food_projected_days":9999.0,"food_weather_factor":0.9,"food_harvest":{"Fresh plants":180.0,"Fresh meat":90.0,"Fish":60.0,"Dry staples":372.0},"housing_ratio":0.94,"labor_efficiency":0.8,"cohesion":0.7,"legitimacy":0.66,"logistics":0.46,"material_capacity":0.52},true)
	GameState.water_metrics={"required_today":2400.0,"collected_today":2430.0,"household_collected_today":1400.0,"organized_collection_capacity":1100.0,"collection_workers":260.0,"intake_ratio":1.0,"stored":900.0,"days":0.4,"source_accessible":true}

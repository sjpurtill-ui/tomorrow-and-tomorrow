extends Node
## TEST CAPTURE HARNESS, not the game: renders the Settlement dock's Overview
## (our own town's page) on a prepared test world and saves it, for UX review.
## Run it only through tools/run_isolated_gpu_probe.ps1 with user arguments
##   --case=early|late|secondary --out=<absolute png path>
##   [--mode=dark] [--hover=<row key>] [--scroll=<pixels>] [--dock-width=<px>] [--dump]
## early: a hearth of about ninety souls; late: a large lettered town with a
## palisade, a levy and works; secondary: our second town, its own figures.
## Each case knows one or two foreign towns so their marks can be compared.
## It never writes a save and quits by itself.
const DockPanel:=preload("res://scripts/hud/dock_panel.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")

class CaptureHud extends Control:
	signal section_requested(section:String,sub:int)
	var dock:Node
	func request_immediate_dock_refresh()->void:pass
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
	var case:="early";var out:="";var mode:="light";var hover:="";var scroll:=0;var width:=0.0
	for argument:String in OS.get_cmdline_user_args():
		if argument.begins_with("--case="):case=argument.trim_prefix("--case=")
		elif argument.begins_with("--out="):out=argument.trim_prefix("--out=")
		elif argument.begins_with("--mode="):mode=argument.trim_prefix("--mode=")
		elif argument.begins_with("--hover="):hover=argument.trim_prefix("--hover=")
		elif argument.begins_with("--scroll="):scroll=int(argument.trim_prefix("--scroll="))
		elif argument.begins_with("--dock-width="):width=float(argument.trim_prefix("--dock-width="))
	T.set_color_mode(mode)
	get_window().size=Vector2i(1600,900)
	_world(case)
	var backdrop:=ColorRect.new();backdrop.color=Color("#8f8a68");backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(backdrop)
	var hud:=CaptureHud.new();hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(hud)
	var panel=DockPanel.new();hud.add_child(panel);hud.dock=panel
	# Where the rail HUD puts a wide dock (command_rail_hud.gd _layout).
	var view:=get_viewport().get_visible_rect().size
	panel.position=Vector2(T.DOCK_X,56);panel.size=Vector2(width if width>0.0 else clampf(view.x*.65,720.0,980.0),view.y-64-T.DOCK_MARGIN_Y)
	var terrain:=StubTerrain.new();add_child(terrain)
	var provider=load("res://scripts/hud/content/dock_content_settlement.gd").new(terrain,hud)
	panel.present(provider,0)
	for frame in 30:await get_tree().process_frame
	if scroll>0:
		panel.body_scroll.scroll_vertical=scroll
		for frame in 4:await get_tree().process_frame
	if hover!="":
		var row:=panel.body.find_child("Row_"+hover,true,false) as Control
		if row!=null:
			row.mouse_entered.emit()
			for frame in 4:await get_tree().process_frame
		else:print("OWN_TOWN_CAPTURE no row ",hover)
	if "--dump" in OS.get_cmdline_user_args():
		for row in panel.body.find_children("Row_*","Control",true,false):
			print("ROW ",row.name," | ",(row as Control).tooltip_text.replace("\n"," / "))
		var lead:=panel.body.find_child("LeadWords",true,false) as Label
		if lead:print("LEAD ",lead.text)
	await RenderingServer.frame_post_draw
	if out!="" and DisplayServer.get_name()!="headless":
		DirAccess.make_dir_recursive_absolute(out.get_base_dir())
		get_viewport().get_texture().get_image().save_png(out)
	print("OWN_TOWN_CAPTURE ",case," ",mode," -> ",out)
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
	match case:
		"late":_late()
		"secondary":_secondary()
		_:_early()
	PeopleDirection.reset_for_new_world();PeopleDirection.ensure()
	print("OWN_TOWN_WORLD life=%.1f infant=%.0f condition=%.2f exceptional=%.4f" % [GameState.projected_life_expectancy(),preload("res://scripts/civilization_indicators.gd").infant_mortality_per_1000(),GameState._mortality_condition_factor(),GameState._current_exceptional_mortality_rate()])

## About ninety souls under the first roofs, thirty-one years after the founding.
func _early()->void:
	GameState.ensure_population_total(93)
	GameState.elapsed_days=31*365+120
	GameState.settlement_completed=["Hearth Circle","Lean-to Shelters","Storage Pits"];GameState.settlement_site_committed=true;GameState.settlement_name="Seanstone"
	SettlementModel.ensure_founded();GovernmentPeopleSystem.initialize()
	GameState.housing_capacity=96
	GameState.food_stocks.merge({"Fresh food":900.0,"Stored food":4900.0},true)
	GameState.simulation_metrics.merge({"food_days":212.0,"food_production":31.0,"food_eaten":27.4,"food_spoilage":1.2,"food_net":2.4,"food_weather_factor":0.95,"housing_ratio":1.0,"labor_efficiency":0.74,"cohesion":0.8,"logistics":0.22,"material_capacity":0.18},true)
	GameState.water_metrics={"required_today":93.0,"collected_today":96.0,"intake_ratio":1.0,"stored":40.0,"days":0.4,"source_accessible":true}
	_known_town(0,"Flintwick",58.0,.55,270)

## A large lettered town: a palisade, a levy at home, works and water works.
func _late()->void:
	GameState.ensure_population_total(2400)
	GameState.elapsed_days=180*365+40
	GameState.known_discoveries.append_array(["pictographic_records","latrine_siting","protected_wellheads"])
	GameState.settlement_completed=["Hearth Circle","Lean-to Shelters","Storage Pits","Public Stores","Gathering Yard","Open Work Area","Framed Hall"];GameState.settlement_site_committed=true;GameState.settlement_name="Seanstone"
	SettlementModel.ensure_founded();GovernmentPeopleSystem.initialize()
	GameState.housing_capacity=2250
	GameState.population_health=0.84;GameState.food_security=0.8
	GameState.food_stocks.merge({"Fresh food":16000.0,"Stored food":180000.0},true)
	GameState.simulation_metrics.merge({"food_days":96.0,"food_production":640.0,"food_eaten":702.0,"food_spoilage":14.0,"food_net":-76.0,"food_weather_factor":0.9,"housing_ratio":0.94,"labor_efficiency":0.8,"cohesion":0.7,"logistics":0.46,"material_capacity":0.52},true)
	GameState.water_metrics={"required_today":2400.0,"collected_today":2230.0,"intake_ratio":0.93,"stored":900.0,"days":0.4,"source_accessible":true}
	GameState.water_waste_works={"works":[{"id":1,"kind":"latrine","status":"active","work_done":18.0,"work_required":18.0,"condition":0.92,"lining":"","started_day":100,"last_maintenance_day":-1},{"id":2,"kind":"wellhead","status":"active","work_done":24.0,"work_required":24.0,"condition":0.88,"lining":"","started_day":200,"last_maintenance_day":-1}],"next_id":3,"last_day":-1,"report":{}}
	MilitaryCampaign._ensure_settlement_defense()
	MilitaryCampaign.settlement_defense["stage"]=3;MilitaryCampaign.settlement_defense["integrity"]=0.86
	MilitaryCampaign.home_army["troops"]=140
	# A raid burned part of the eastern houses last year.
	var plots:Array=GameState.settlement_plots
	for i in mini(3,plots.size()):
		if String((plots[i] as Dictionary).get("land_use",""))!="field":(plots[i] as Dictionary)["status"]="damaged"
	GameState.city_form={"tier":4.0,"condition":0.83,"materials_paid":0.9}
	_known_town(0,"Tsaren",1800.0,.62,120)
	_known_town(1,"Oskel",3600.0,.5,700)

## Our second town, Rivermeet, beside a home of about nine hundred.
func _secondary()->void:
	GameState.ensure_population_total(1100)
	GameState.elapsed_days=64*365
	GameState.settlement_completed=["Hearth Circle","Lean-to Shelters","Storage Pits","Public Stores"];GameState.settlement_site_committed=true;GameState.settlement_name="Seanstone"
	SettlementModel.ensure_founded()
	GameState.housing_capacity=900
	GameState.simulation_metrics.merge({"food_days":300.0,"food_production":120.0,"food_eaten":118.0,"food_spoilage":2.0,"food_net":0.0,"housing_ratio":1.0},true)
	var home:Vector2=SettlementModel.settlement_record(SettlementModel._primary_settlement_id()).get("position",Vector2.ZERO)
	GameState.player_settlements.append({"id":"second","name":"Rivermeet","position":home+Vector2(9,4),"primary":false,"population_share":.2,"founded_day":52*365})
	GovernmentPeopleSystem.initialize()
	SettlementModel.with_city_resources("second",func()->void:
		GameState.housing_capacity=180
		GameState.settlement_completed=["Hearth Circle","Lean-to Shelters"]
		GameState.food_stocks.merge({"Fresh food":400.0,"Stored food":1400.0},true)
		GameState.simulation_metrics.merge({"food_days":38.0,"food_production":58.0,"food_eaten":61.0,"food_spoilage":2.0,"food_net":-5.0,"food_weather_factor":0.9,"housing_ratio":0.82,"labor_efficiency":0.7,"cohesion":0.75,"logistics":0.2,"material_capacity":0.15},true)
		GameState.water_metrics={"required_today":220.0,"collected_today":190.0,"intake_ratio":0.86,"stored":20.0,"days":0.2,"source_accessible":true})
	SettlementModel.select_settlement("second")
	_known_town(0,"Flintwick",260.0,.55,200)

## A stranger's town our scouts saw `ago` days back, at the given quality.
func _known_town(index:int,name:String,population:float,quality:float,ago:int)->void:
	if CivilizationSystem.civilizations.size()<=index:return
	var civ:Dictionary=CivilizationSystem.civilizations[index]
	civ.player_relation.contact_level=2
	var region:Dictionary=civ.strategic_regions[CivilizationSystem._frontline_region_index(civ)]
	region["name"]=name;region["population"]=population
	var day:=maxi(0,int(GameState.elapsed_days)-ago)
	var intel=CivilizationSystem.city_intelligence
	intel.publish("player",intel.capture("player",String(region.id),quality,day,"physical reconnaissance","capture"),day)

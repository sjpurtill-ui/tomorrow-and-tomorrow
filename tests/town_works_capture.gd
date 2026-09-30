extends Node
## TEST CAPTURE HARNESS, not the game: renders the Buildings dock's THE TOWN
## tab on a prepared test world and saves it, for UX review. Run it only
## through tools/run_isolated_gpu_probe.ps1 with user arguments
##   --case=shortage|building --out=<absolute png path> [--mode=dark]
##   [--scroll=<pixels>] [--sub=<tab, 0 the town>] [--select=<work>] [--dump]
## shortage: about 230 people, every early work built, the first town short
## of timber while the other towns hold plenty, no defences yet; building: a
## young town raising its hall and its watch posts, the Storage Pits just
## finished. It never writes a save and quits by itself.
const DockPanel:=preload("res://scripts/hud/dock_panel.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")

class CaptureHud extends Control:
	signal section_requested(section:String,sub:int)
	var dock:Node
	func request_immediate_dock_refresh()->void:pass
	func open_detail(_provider:Object,_sub:int=0)->void:pass

class StubTerrain extends Node:
	func _settlement_display_name()->String:return "Sean Springs"
	func _report_military_action(_r:Dictionary)->void:pass
	func _on_settlement_action_pressed()->void:pass

func _ready()->void:
	get_tree().create_timer(60.0).timeout.connect(func():get_tree().quit(3))
	var case:="shortage";var out:="";var mode:="light";var scroll:=0;var sub:=0;var select:=""
	for argument:String in OS.get_cmdline_user_args():
		if argument.begins_with("--case="):case=argument.trim_prefix("--case=")
		elif argument.begins_with("--out="):out=argument.trim_prefix("--out=")
		elif argument.begins_with("--mode="):mode=argument.trim_prefix("--mode=")
		elif argument.begins_with("--scroll="):scroll=int(argument.trim_prefix("--scroll="))
		elif argument.begins_with("--sub="):sub=int(argument.trim_prefix("--sub="))
		elif argument.begins_with("--select="):select=argument.trim_prefix("--select=").replace("_"," ")
	T.set_color_mode(mode)
	get_window().size=Vector2i(1600,900)
	_world(case)
	var backdrop:=ColorRect.new();backdrop.color=Color("#8f8a68");backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(backdrop)
	var hud:=CaptureHud.new();hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(hud)
	var panel=DockPanel.new();hud.add_child(panel);hud.dock=panel
	var view:=get_viewport().get_visible_rect().size
	panel.position=Vector2(T.DOCK_X,56);panel.size=Vector2(clampf(view.x*.65,720.0,980.0),view.y-64-T.DOCK_MARGIN_Y)
	var terrain:=StubTerrain.new();add_child(terrain)
	var provider=load("res://scripts/hud/content/dock_content_construction.gd").new(terrain,hud)
	provider.selected_project=select
	panel.present(provider,sub)
	for frame in 30:await get_tree().process_frame
	if scroll>0:
		panel.body_scroll.scroll_vertical=scroll
		for frame in 4:await get_tree().process_frame
	if "--dump" in OS.get_cmdline_user_args():
		for label in panel.body.find_children("*","Label",true,false):
			if (label as Label).is_visible_in_tree():print("LABEL ",(label as Label).text.replace("\n"," / "))
	await RenderingServer.frame_post_draw
	if out!="" and DisplayServer.get_name()!="headless":
		DirAccess.make_dir_recursive_absolute(out.get_base_dir())
		get_viewport().get_texture().get_image().save_png(out)
	print("TOWN_WORKS_CAPTURE ",case," ",mode," -> ",out)
	T.set_color_mode("light")
	get_tree().quit(0)

func _world(case:String)->void:
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(515151 if case=="building" else 616161);GameState.civic_api_enabled=false
	ResourceSystem.reset_for_new_world();FoodSystem.reset_for_new_world();SettlementModel.reset_for_new_world()
	DiscoverySystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world();ForeignDiplomacy.ensure();GovernmentPeopleSystem.reset_for_new_world()
	PeopleDirection.reset_for_new_world();PeopleDirection.ensure()
	GameState.initialize_population_model()
	GameState.settlement_founded_day=0
	ResourceSystem.initialize()
	if case=="building":_building()
	else:_shortage()

## The player's own spring of year 68 in miniature: every early work built,
## timber short at home, the watch five strong, two friendly peoples known.
func _shortage()->void:
	GameState.ensure_population_total(229)
	GameState.elapsed_days=67*365+200
	GameState.settlement_completed=["Hearth Circle","Storage Pits","Gathering Yard","Open Work Area","Lean-to Shelters","Framed Hall","Public Stores","Hearth Shrine"]
	GameState.settlement_site_committed=true;GameState.settlement_name="Sean Springs"
	SettlementModel.ensure_founded();GovernmentPeopleSystem.initialize()
	GameState.housing_capacity=240
	GameState.population_allocations={"Food":50,"Survey":12,"Extraction":11,"Construction":22,"Crafting":9,"Logistics":13,"Knowledge":27,"Administration":6,"Defense":5}
	GameState.resource_stockpiles.merge({"Timber":2.57,"Stone":111.7,"Clay":190.0,"Fiber Plants":251.9},true)
	GameState.simulation_metrics.merge({"food_days":261.0,"labor_efficiency":0.95,"housing_ratio":1.0,"logistics":0.4},true)
	GameState.water_metrics={"source_accessible":true,"intake_ratio":1.0}
	GameState.city_form={"tier":3.0,"condition":0.91,"materials_paid":1.0}
	for index in 2:
		if CivilizationSystem.civilizations.size()>index:
			var civ:Dictionary=CivilizationSystem.civilizations[index]
			civ.player_relation.contact_level=2;civ.player_relation.opinion=0.45;civ.player_relation.border_tension=0.05

## A young town: the hall going up, watch posts rising, pits just finished.
func _building()->void:
	GameState.ensure_population_total(118)
	GameState.elapsed_days=4*365+90
	GameState.settlement_completed=["Hearth Circle","Lean-to Shelters","Open Work Area","Gathering Yard","Storage Pits"]
	GameState.settlement_site_committed=true;GameState.settlement_name="Seanstone"
	SettlementModel.ensure_founded();GovernmentPeopleSystem.initialize()
	GameState.housing_capacity=130
	GameState.population_allocations={"Food":40,"Survey":6,"Extraction":10,"Construction":12,"Crafting":6,"Logistics":7,"Knowledge":4,"Administration":4,"Defense":6}
	GameState.resource_stockpiles.merge({"Timber":60.0,"Stone":40.0,"Clay":30.0,"Fiber Plants":30.0},true)
	GameState.simulation_metrics.merge({"food_days":90.0,"labor_efficiency":0.8,"housing_ratio":1.0,"logistics":0.3},true)
	GameState.water_metrics={"source_accessible":true,"intake_ratio":1.0}
	GameState.city_form={"tier":2.0,"condition":0.97,"materials_paid":1.0}
	GameState.known_discoveries.append("framed_construction");GameState.discovery_adoption["framed_construction"]=0.6
	GameState.settlement_projects["Framed Hall"]=9.0
	GameState.record_building_event({"day":int(GameState.elapsed_days)-6,"event":"completed","kind":"Storage Pits","materials":{"Timber":12.0},"condition":1.0,"status":"active"})
	MilitaryCampaign._ensure_settlement_defense()
	MilitaryCampaign.settlement_defense.merge({"project_stage":1,"project_work":14.0,"project_progress":0.35,"reserved_materials":{"Timber":10.0,"Fiber Plants":4.0},"started_by":"people","started_day":int(GameState.elapsed_days)-9},true)

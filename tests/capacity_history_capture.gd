extends Node
## TEST CAPTURE HARNESS, not the game: renders Culture's "Society's strengths &
## needs" list, or one capacity's history page, on a settled test world that
## has lived a few years, and saves the image for UX review. Run it only
## through tools/run_isolated_gpu_probe.ps1 with user arguments
##   --view=strengths|detail --era=early|late [--dynamic=logistics]
##   [--mode=light|dark] [--scroll=end] --out=res://artifacts/capacity-history/<name>.png
const DockPanel:=preload("res://scripts/hud/dock_panel.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")
const Civilization:=preload("res://scripts/hud/content/dock_content_civilization.gd")
const DETAIL_PATH:="res://scripts/hud/content/dock_detail_capacity.gd"
## Time spent in the society's day: on the month's turn (with its record) and
## on ordinary days, printed with the capture.
var month_usec:=0
var day_usec:=0
var month_days:=0
var other_days:=0

class CaptureHud extends Control:
	signal section_requested(section:String,sub:int)
	var dock:Node
	var opened:Object
	func request_immediate_dock_refresh()->void:pass
	func open_detail(provider:Object,_sub:int=0)->void:opened=provider

## Stands in for the map so providers can bind their map actions.
class StubTerrain extends Node:
	func _dynamic_definition(dynamic_id:String)->String:return "What %s means for the people." % dynamic_id
	func _open_war_planning()->void:pass
	func _cancel_pending_pronouncement(_a:String,_b:String)->void:pass

## The strengths list as the focused report shows it.
class StrengthsReport extends "res://scripts/hud/content/dock_content_base.gd":
	var source:Object
	func meta()->Dictionary:return {"eyebrow":"Culture","title":"Society’s strengths & needs","subtabs":[]}
	func tab(_sub:int)->Dictionary:return {"blocks":source._society_blocks(GameState.society_capacities)}

func _ready()->void:
	var view:="strengths";var era:="early";var dynamic:="logistics";var mode:="light";var scrolled:=false
	var out:="res://artifacts/capacity-history/strengths.png"
	for argument:String in OS.get_cmdline_user_args():
		if argument.begins_with("--view="):view=argument.trim_prefix("--view=")
		elif argument.begins_with("--era="):era=argument.trim_prefix("--era=")
		elif argument.begins_with("--dynamic="):dynamic=argument.trim_prefix("--dynamic=")
		elif argument.begins_with("--mode="):mode=argument.trim_prefix("--mode=")
		elif argument.begins_with("--out="):out=argument.trim_prefix("--out=")
		elif argument=="--scroll=end":scrolled=true
	T.set_color_mode(mode)
	_prepare_world(era)
	var backdrop:=ColorRect.new();backdrop.color=T.PAPER;backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(backdrop)
	var hud:=CaptureHud.new();hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(hud)
	var panel=DockPanel.new();panel.back_mode=true;hud.add_child(panel);hud.dock=panel
	panel.position=Vector2(40,20);panel.size=Vector2(560,860)
	var terrain:=StubTerrain.new();add_child(terrain)
	var civilization=Civilization.new(terrain,hud)
	var provider:Object
	if view=="detail":
		if not ResourceLoader.exists(DETAIL_PATH):
			print("CAPACITY_CAPTURE no detail page in this build");get_tree().quit();return
		provider=load(DETAIL_PATH).new(terrain,hud,dynamic)
	else:
		var report:=StrengthsReport.new(terrain,hud);report.source=civilization;provider=report
	panel.present(provider,0)
	for frame in 12:await get_tree().process_frame
	if scrolled:
		# The lower half of the page: why it moved and what it is made of now.
		panel.body_scroll.scroll_vertical=int(panel.body_scroll.get_v_scroll_bar().max_value)
		for frame in 6:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.get_base_dir()))
	get_viewport().get_texture().get_image().save_png(out)
	print("CAPACITY_CAPTURE ",view,"/",era,"/",dynamic," -> ",out," history bytes ",var_to_bytes(GameState.capacity_history).size()," known ",GameState.known_discoveries.size())
	print("CAPACITY_CAPTURE timing: month-turn day %.1f ms, ordinary day %.2f ms" % [float(month_usec)/maxf(1.0,month_days)/1000.0,float(day_usec)/maxf(1.0,other_days)/1000.0])
	get_tree().quit()

## A settled people that has lived some years: good seasons and lean ones,
## more carriers, a raid, new knowledge taken up month by month.
func _prepare_world(era:String)->void:
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	WorldSimulation.clear()
	GameState.reset_for_new_world(515151)
	ResourceSystem.reset_for_new_world();FoodSystem.reset_for_new_world();SettlementModel.reset_for_new_world();GovernmentPeopleSystem.reset_for_new_world()
	DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	GameState.initialize_population_model();GameState.ensure_population_total(140 if era=="early" else 4200)
	GameState.housing_capacity=150 if era=="early" else 4400
	GameState.settlement_completed=["Hearth Circle"];GameState.settlement_site_committed=true;GameState.settlement_name="Ashford"
	SettlementModel.ensure_founded();GovernmentPeopleSystem.initialize()
	PeopleDirection.reset_for_new_world();PeopleDirection.ensure()
	var model=DiscoverySystem.society_model
	var start_day:=400 if era=="early" else 2900*365
	if era=="late":
		# A people of the printing age: everything before it known and in use.
		for definition:Dictionary in DiscoverySystem.catalog:
			var id:=String(definition.get("id",""))
			if id=="" or bool(definition.get("frontier",false)) or float(definition.get("earliest_year",0.0))>2250.0:continue
			if id not in GameState.known_discoveries:GameState.known_discoveries.append(id)
			GameState.discovery_adoption[id]=0.85
		if "printing_process" not in GameState.known_discoveries:GameState.known_discoveries.append("printing_process")
	var later:Array[String]=["pack_animals","route_memory","supply_groups","basketry","public_stores","watch_rotation"]
	for id in later:GameState.known_discoveries.erase(id)
	var months:=96
	for month in months:
		GameState.elapsed_days=start_day+month*30
		var season:=sin(TAU*float(month)/12.0)
		var carriers:=clampf(0.14+float(month)*0.0022,0.0,0.7)
		GameState.simulation_metrics.merge({"health":0.62+season*0.04+float(month)*0.0008,"cohesion":0.64+float(month)*0.001,"legitimacy":0.6,"security":0.34+float(month)*0.0012,
			"ecology":0.86-float(month)*0.0006,"knowledge":0.2+float(month)*0.002,"material_capacity":0.16+float(month)*0.0015,"logistics":carriers,"food_diet_quality":0.5},true)
		GameState.food_security=clampf(0.7+season*0.08-(0.18 if month in [40,41,42] else 0.0),0.0,1.0)
		GameState.population_health=float(GameState.simulation_metrics.health)
		if month%14==6 and not later.is_empty():
			var id:String=later.pop_front()
			var definition:=DiscoverySystem.discovery_definition(id)
			if not definition.is_empty():
				GameState.known_discoveries.append(id)
				model.register_discovery(definition,DiscoverySystem.catalog)
				GameState.discovery_log.push_front({"day":int(GameState.elapsed_days),"id":id,"name":String(definition.get("name",id)),"effects":definition.get("effects",{}).duplicate(true)})
		if month==60:GameState.settlement_completed.append("Granary")
		# Every day of the month is lived, so each month is read at its mean.
		for day in 30:
			GameState.elapsed_days=start_day+month*30+day
			if month==40 and day==5:
				GameState.food_issue_history.append({"day":int(GameState.elapsed_days),"category":"raid_loss","label":"Stores seized after a failed defense","amount":900.0,"settlement_days":9.0})
			var started:=Time.get_ticks_usec()
			model.process_day(DiscoverySystem.catalog,{"travel":0.4,"materials":0.6,"food":0.8})
			# How long a day takes, the month's turn (and its record) apart.
			if day==0: month_usec+=Time.get_ticks_usec()-started;month_days+=1
			else: day_usec+=Time.get_ticks_usec()-started;other_days+=1

extends Node
## Capture of the report on a town we hold: Tsaren, taken from the Esurai,
## 17 of Rovik's band holding it, the scouts' last look two days before it
## fell, and the men put to the sword at the god's word. Run only through
## tools/run_isolated_gpu_probe.ps1:
##   res://tests/held_town_capture.tscn -- --shot=dock|screen --out=<png path>
## It never writes a save and quits by itself. It also runs on the code
## before the held-town report (the "before" plates).
const CC:=preload("res://scripts/court_commands.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const Route:=preload("res://scripts/army_land_route.gd")
var civ_id:=""
var city_id:=""
var city:=Vector2.ZERO

func _land(_p:Vector2)->bool:return true

func _ready()->void:
	get_tree().create_timer(60.0).timeout.connect(func():get_tree().quit(3))
	var shot:="dock";var out:="";var bottom:=false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):shot=arg.trim_prefix("--shot=")
		elif arg.begins_with("--out="):out=arg.trim_prefix("--out=")
		elif arg=="--bottom":bottom=true
	get_window().size=Vector2i(1600,900)
	var layer:=CanvasLayer.new();layer.layer=-5;add_child(layer)
	var backdrop:=ColorRect.new();backdrop.color=Color("#8f8a68");backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);layer.add_child(backdrop)
	_setup()
	_take()
	var band:Dictionary=MilitaryCampaign.field_armies[0]
	var audience:=Hall.summon({"figure_id":String((band.commander as Dictionary).get("figure_id",""))})
	var r:=CC.hear(String(audience.id),"Put the men of Tsaren to the sword")
	print("FATE ",String(r.get("actor_says","")))
	GameState.elapsed_days+=2
	if shot=="screen":
		CivilizationSystem.city_intelligence.open(city_id)
	else:
		var T=load("res://scripts/hud/hud_tokens.gd");T.set_color_mode("light")
		var ui:=CanvasLayer.new();add_child(ui)
		var panel=load("res://scripts/hud/dock_panel.gd").new();ui.add_child(panel)
		panel.position=Vector2(88,8);panel.size=Vector2(540,884)
		var provider=load("res://scripts/hud/content/dock_detail_foreign_city.gd").new(null,null,city_id)
		panel.present(provider,0)
		if bottom:
			for i in 10:await get_tree().process_frame
			panel.body_scroll.scroll_vertical=100000
	for i in 40:await get_tree().process_frame
	RenderingServer.force_draw(true,0.0)
	await get_tree().process_frame
	if out!="" and DisplayServer.get_name()!="headless":
		var image:=get_viewport().get_texture().get_image()
		if image:image.save_png(out)
	print("HELD_TOWN_CAPTURE shot=",shot," -> ",out)
	get_tree().quit(0)

func _setup()->void:
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(74017);GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world();FoodSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world();ForeignDiplomacy.ensure();GovernmentPeopleSystem.reset_for_new_world()
	GameState.ensure_population_total(900);GameState.housing_capacity=1000
	GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	GameState.select_founding_focus("provision")
	GameState.settlement_name="Seanstone"
	GameState.society_capacities["institutions"]=0.4
	GovernmentPeopleSystem._update_government_stage(false)
	GovernmentPeopleSystem.initialize()
	GameState.resource_stockpiles["Food"]=1000000.0
	GameState.elapsed_days=96*365
	Route.clear_cache()
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ["name"]="Esurai";civ_id=String(civ.id)
	var relation:Dictionary=civ.player_relation
	relation.at_war=true;relation.contact_level=2;relation.home_location_known=true
	var region:Dictionary=civ.strategic_regions[CivilizationSystem._frontline_region_index(civ)]
	region["name"]="Tsaren";region["population"]=96.0;city_id=String(region.id)
	CivilizationSystem.city_intelligence.publish("player",CivilizationSystem.city_intelligence.capture("player",city_id,.5,int(GameState.elapsed_days)-2,"field campaign report","capture"),int(GameState.elapsed_days)-2)
	city=CivilizationSystem.player_world_origin+Vector2(-20.0,8.0)
	CivilizationSystem.city_intelligence.records.player[city_id]["position"]={"x":city.x,"z":city.y}
	CivilizationSystem.set_scout_geography_authority(Callable(self,"_land"))

func _take()->void:
	MilitaryCampaign.military_inventory["improvised"]=int(MilitaryCampaign.military_inventory.get("improvised",0))+18
	MilitaryCampaign.raise_recruits(18)
	MilitaryCampaign.start_training("levy","improvised",18)
	MilitaryCampaign._complete_training(MilitaryCampaign.training_queue[0].duplicate(true))
	MilitaryCampaign.training_queue.clear()
	MilitaryCampaign.create_field_army(18,"LEVY BAND 1")
	var army:Dictionary=MilitaryCampaign.field_armies[0]
	army["supply_level"]=1.0;army["readiness"]=1.0
	army["position"]={"x":city.x+0.3,"z":city.y}
	army["location_id"]=city_id;army["location_name"]="Tsaren";army["status"]="stationed"
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	var ri:=CivilizationSystem._region_index(civ,city_id)
	civ.strategic_regions[ri]["controller"]="player"
	civ.strategic_regions[ri]["last_control_change_day"]=int(GameState.elapsed_days)
	var factor:=maxf(.05,float(army.get("supply_level",1.0))*(.5+.5*clampf(float(army.get("readiness",.45))*.9,.15,1.0)))
	MilitaryCampaign.establish_occupation_force(civ_id,civ.strategic_regions[ri],floorf(17.0*factor),int(army.army_id))

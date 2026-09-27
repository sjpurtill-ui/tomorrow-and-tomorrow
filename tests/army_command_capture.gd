extends Node
## TEST capture only, never a player launch: the Army command panel on a flat
## backdrop with the user's situation (a levy band of 20 and two trained at
## home, one known town across a bay). Arguments after "--":
##   --out=res://artifacts/army-command/<name>.png   where to save
##   --pick                                         choose band, Attack, Tsaren
##   --give                                         (with --pick) give the order
##   --zones                                        show the Drawn zones tab
const CommandPanel=preload("res://scripts/hud/command_hierarchy_panel.gd")

func _ready()->void:
	get_window().title="TEST — Army command capture"
	get_window().size=Vector2i(1600,900)
	call_deferred("_capture")

func _arg(name:String,fallback:String="")->String:
	for a:String in OS.get_cmdline_user_args():
		if a.begins_with("--%s=" % name):return a.get_slice("=",1)
		if a=="--"+name:return "true"
	return fallback

func _land(_p:Vector2)->bool:return true

func _capture()->void:
	for singleton:Node in [GameState,MilitaryCampaign,CivilizationSystem]:singleton.set_process(false)
	WorldSimulation.clear()
	GameState.reset_for_new_world(74017);GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	GameState.ensure_population_total(900);GameState.housing_capacity=1000
	GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	GameState.settlement_name="Seanstone";GameState.resource_stockpiles["Food"]=100000.0
	GovernmentPeopleSystem.initialize()
	GameState.elapsed_days=88*365
	var civ:Dictionary=CivilizationSystem.civilizations[0];civ["name"]="Tsaren"
	var region:Dictionary=civ.strategic_regions[CivilizationSystem._frontline_region_index(civ)];region["name"]="Tsaren"
	var city_id:=String(region.id)
	civ.player_relation.contact_level=2;civ.player_relation.home_location_known=true
	CivilizationSystem.city_intelligence.publish("player",CivilizationSystem.city_intelligence.capture("player",city_id,.8,int(GameState.elapsed_days),"scout report","test"),int(GameState.elapsed_days))
	var home:Vector2=CivilizationSystem.player_world_origin
	CivilizationSystem.city_intelligence.records.player[city_id]["position"]={"x":home.x-22.0,"z":home.y+9.0}
	CivilizationSystem.set_scout_geography_authority(Callable(self,"_land"))
	MilitaryCampaign.raise_recruits(22);MilitaryCampaign.start_training("levy","improvised",22)
	MilitaryCampaign._complete_training(MilitaryCampaign.training_queue[0].duplicate(true));MilitaryCampaign.training_queue.clear()
	var band:Dictionary=MilitaryCampaign.create_field_army(20,"Levy band 1")
	MilitaryCampaign.command_hierarchy.sync()
	var background:=ColorRect.new();background.color=Color("5f6a52");background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(background)
	var hint:=Label.new();hint.text="TEST backdrop (no map)";hint.position=Vector2(40,40);hint.add_theme_font_size_override("font_size",22);add_child(hint)
	var panel:=CommandPanel.new();panel.domain="army";add_child(panel)
	for _frame in 4:await get_tree().process_frame
	var army_id:=int((band.get("army",{}) as Dictionary).get("army_id",0))
	if _arg("pick")!="":
		if panel.has_method("choose_force"):
			panel.choose_force(army_id);panel.choose_verb("attack");panel.choose_place(city_id)
			if _arg("give")!="":panel._give(false)
		else:
			panel._select_force(army_id)
			if is_instance_valid(panel.details_toggle):panel.details_toggle.pressed.emit()
	if _arg("zones")!="" and panel.has_method("show_zone_orders"):
		panel.show_zone_orders();panel._select_force(army_id)
		if is_instance_valid(panel.details_toggle):panel.details_toggle.pressed.emit()
	for _frame in 8:
		await get_tree().process_frame
		RenderingServer.force_draw(false)
	var output:=_arg("out","res://artifacts/army-command/capture.png")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
	var error:=get_viewport().get_texture().get_image().save_png(output)
	print("ARMY_COMMAND_CAPTURE ","PASS" if error==OK else "FAIL"," ",output)
	CivilizationSystem.set_scout_geography_authority(Callable())
	WorldSimulation.clear();get_tree().quit(0 if error==OK else 1)

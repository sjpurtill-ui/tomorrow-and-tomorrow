extends Node
## Capture-only fixture for the objective workflow; never a player launch.
const CommandPanel=preload("res://scripts/hud/command_hierarchy_panel.gd")

func _ready()->void:
	get_window().title="TEST — Command hierarchy visual audit"
	get_window().mode=Window.MODE_MINIMIZED
	get_window().size=Vector2i(1180,860)
	call_deferred("_capture")

func _capture()->void:
	for singleton:Node in [GameState,MilitaryCampaign,CivilizationSystem]:singleton.set_process(false)
	GameState.reset_for_new_world(424242);MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	GameState.initialize_population_model();GameState.ensure_population_total(5000)
	GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("Reserve",[{"id":1,"unit":"levy","weapon":"improvised","count":3,"equipment":3,"ammunition":9,"training":.6,"experience":.2}],.8,.7)
	MilitaryCampaign.command_hierarchy.sync()
	var background:=ColorRect.new();background.color=Color("17282b");background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(background)
	var map_hint:=Label.new();map_hint.text="ISOLATED MAP BACKDROP\nCommand panel visual audit";map_hint.position=Vector2(40,80);map_hint.modulate=Color("78908e");map_hint.add_theme_font_size_override("font_size",24);add_child(map_hint)
	var panel:=CommandPanel.new();panel.domain="army";add_child(panel)
	for _frame in 8:
		await get_tree().process_frame
		RenderingServer.force_draw(false)
	var output:="res://artifacts/command-hierarchy/army-objectives.png"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
	var error:=get_viewport().get_texture().get_image().save_png(output)
	print("COMMAND_HIERARCHY_VISUAL_CAPTURE ","PASS" if error==OK else "FAIL"," ",output)
	WorldSimulation.clear();get_tree().quit(0 if error==OK else 1)

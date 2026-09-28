extends Node
## Capture-only fixture for the Forces page, isolated from saves; never a player launch.
## Reproduces the reported roster: a two-person home reserve with no weapons and a
## twenty-strong levy band in first instruction, with seventeen of twenty armed.
## Output: res://artifacts/military-roster-story/<tag>-*.png (tag from --tag=).
const Roster=preload("res://scripts/hud/military_roster_screen.gd")
var canvas:SubViewport
var screen:CanvasLayer
var tag:="after"
func _ready()->void:
	get_window().title="TEST — Military roster story capture"
	get_window().mode=Window.MODE_MINIMIZED
	for argument:String in OS.get_cmdline_user_args():
		if argument.begins_with("--tag="):tag=argument.trim_prefix("--tag=")
	call_deferred("run")
func settle(frames:int=8)->void:
	for frame in frames:
		await get_tree().process_frame
		RenderingServer.force_draw(false)
func capture(file:String)->void:
	await settle()
	canvas.get_texture().get_image().save_png("res://artifacts/military-roster-story/%s-%s.png" % [tag,file])
func run()->void:
	for singleton:Node in [GameState,MilitaryCampaign,CivilizationSystem]:singleton.set_process(false)
	GameState.reset_for_new_world(424242);MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	GameState.initialize_population_model();GameState.ensure_population_total(120)
	GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("Reserve",[{"id":1,"unit":"levy","weapon":"improvised","count":2,"authorized_count":2,"equipment":0,"training":.7,"experience":.01,"personnel_condition":.98}],.8,.7)
	MilitaryCampaign.recruit_deploy.data={"next_id":2,"next_slot":2,"lines":[{"id":1,"name":"LEVY BAND","template_id":1,"entries":[{"unit":"levy","weapon":"improvised","count":20}],"parallel":1,"remaining":0,"repeat":false,"priority":1,"paused":false,"auto_deploy":true,"target_army":0,"deployed":0,"slots":[1]}]}
	MilitaryCampaign.training_queue=[{"id":5,"mode":"new","unit":"levy","weapon":"improvised","count":20,"initial_count":39,"experience":0.0,"progress_days":5.95,"required_days":7.0,"injury_accumulator":0.0,"deployment_line":1,"deployment_slot":1,"entry_index":0,"target_count":20,"reserved_equipment":17,"equipment_access_today":.85,"personnel_condition":1.0}]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/military-roster-story"))
	canvas=SubViewport.new();canvas.size=Vector2i(1440,900);canvas.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(canvas)
	var background:=ColorRect.new();background.color=Color("5d6a4a");background.size=Vector2(1440,900);canvas.add_child(background)
	screen=Roster.new();canvas.add_child(screen)
	await settle()
	await capture("forces")
	screen.forces_board.set_filter("short");await capture("short-of-gear")
	screen.training_view=true;screen._build_body();await capture("training")
	screen.training_view=false;screen._show_page("support");await capture("support")
	screen._show_page("forces");canvas.size=Vector2i(1024,640);screen._layout();screen._build_body();await capture("small")
	print("MILITARY_ROSTER_STORY_CAPTURE PASS")
	screen.queue_free();await settle(2);WorldSimulation.clear();get_tree().quit(0)

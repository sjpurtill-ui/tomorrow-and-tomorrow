extends Node
## Capture-only fixture, isolated from saves; never a player launch.
const Roster=preload("res://scripts/hud/military_roster_screen.gd")
var canvas:SubViewport
var screen:CanvasLayer
func _ready()->void:
	get_window().title="TEST — Military roster visual audit"
	get_window().mode=Window.MODE_MINIMIZED
	call_deferred("run")
func settle(frames:int=8)->void:
	for frame in frames:
		await get_tree().process_frame
		RenderingServer.force_draw(false)
func capture(file:String)->void:
	await settle()
	canvas.get_texture().get_image().save_png("res://artifacts/military-roster/"+file+".png")
func add_service_force(domain:String)->void:
	var op=MilitaryCampaign.joint_operations
	op.geography.land_query=func(point:Vector2)->bool:return point.y>=0
	var type_id:="war_canoe" if domain=="navy" else "observation_balloon"
	var definition:Dictionary=op.C.UNITS[type_id]
	GameState.known_discoveries.append(String(definition.gate));GameState.discovery_adoption[definition.gate]=1.0
	GameState.player_settlements[0].position=Vector2(0,1)
	op.build_base(String(GameState.player_settlements[0].id),domain)
	var base:Dictionary=op.state.bases.back();base.construction_work=30
	MilitaryCampaign.military_inventory[definition.equipment]=2
	var result:Dictionary=op.commission(int(base.id),type_id,2)
	assert(result.has("ok"),str(result))
func run()->void:
	for singleton:Node in [GameState,MilitaryCampaign,CivilizationSystem]:singleton.set_process(false)
	GameState.reset_for_new_world(424242);MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	GameState.initialize_population_model();GameState.ensure_population_total(5000)
	GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	for resource:String in ["Food","Timber","Stone","Iron Ore","Fiber Plants","Copper Ore","Graphite","Bitumen"]:GameState.resource_stockpiles[resource]=1000000.0
	GameState.food_stocks={"Preserved food":1000000.0}
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("Reserve",[{"id":1,"unit":"levy","weapon":"improvised","count":3,"equipment":0,"training":.4,"experience":0},{"id":2,"unit":"cavalry","weapon":"lance","count":12,"equipment":12,"training":.8,"experience":.6},{"id":3,"unit":"archer","weapon":"bow","count":30,"equipment":24,"training":.65,"experience":.25}],.8,.7)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/military-roster"))
	canvas=SubViewport.new();canvas.size=Vector2i(1440,900);canvas.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(canvas)
	var background:=ColorRect.new();background.color=Color("17262a");background.size=Vector2(1440,900);canvas.add_child(background)
	screen=Roster.new();canvas.add_child(screen)
	await settle()
	await capture("army-forces")
	screen.selected_row=screen._rows()[0];screen._build_body();await capture("army-detail")
	screen.training_view=true;screen._build_body();await capture("army-training")
	for service:String in ["navy","air"]:
		screen.service=service;screen.training_view=false;screen._build_body();await capture(service+"-empty")
		add_service_force(service);MilitaryCampaign.joint_operations.advance(1);screen._build_body();await capture(service+"-forces")
		screen.training_view=true;screen._build_body();await capture(service+"-training")
	screen.service="army";screen.training_view=false;canvas.size=Vector2i(1024,640);screen._layout();screen._build_body();await capture("army-small")
	screen.training_view=true;screen._build_body();await capture("training-small")
	var errors:=0
	if not screen.portraits.find_children("*","SubViewport",true,false).is_empty():errors+=1
	if screen.body.get_combined_minimum_size().x>screen.scroll.size.x:errors+=1
	print("MILITARY_VISUAL_ROSTER_CAPTURE ","PASS" if errors==0 else "FAIL")
	screen.queue_free();await settle(2);WorldSimulation.clear();get_tree().quit(errors)

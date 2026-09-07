extends Node
var failures:Array[String]=[]
func check(value:bool,message:String)->void:
	if not value:failures.append(message)
func _ready()->void:
	GameState.reset_for_new_world(741991);GameState.ensure_population_total(10000)
	MilitaryCampaign.reset_for_new_world()
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("Home",[{"id":1,"unit":"line_infantry","weapon":"spear","count":800}],1,1)
	MilitaryCampaign.active_threat={"seed":741,"name":"Invasion","enemy_force":MilitaryCampaign.simulator.create_formation_force("Invaders",[{"id":2,"unit":"line_infantry","weapon":"spear","count":800}],1,1),"campaign_mode":"defensive"}
	MilitaryCampaign.begin_threat_engagement()
	var screen:=BattleGraphicsScreen.new();add_child(screen)
	await get_tree().process_frame
	check(screen.view.representative_count()==0 and screen.view.generals.is_empty(),"battle spawned soldiers or mounted generals")
	var initial:Dictionary=MilitaryCampaign.export_state().duplicate(true)
	for dimensions in [Vector2(640,480),Vector2(1600,900),Vector2(2200,1400)]:
		screen.size=dimensions
		for phase in ["orders","resolving","result","ended","aftermath"]:
			screen.phase=phase;screen._phase_ui();screen._layout()
			check(not screen.left_panel.visible and not screen.right_panel.visible and not screen.small_toggle.visible and not screen.retreat_button.visible,"legacy controls appeared in "+phase)
	screen.phase="orders";screen._hold_all();screen._choose_order("charge");screen._retreat()
	check(MilitaryCampaign.export_state()==initial,"legacy observation controls changed combat")
	screen._resolve()
	check(screen.resolve_count==1,"observation did not advance exactly once")
	screen._skip()
	var after:Dictionary=MilitaryCampaign.export_state().duplicate(true)
	var day:float=GameState.elapsed_days
	check(not screen.round_records.is_empty(),"no actual exchange to replay")
	if not screen.round_records.is_empty():
		screen._replay();screen._skip()
		check(MilitaryCampaign.export_state()==after,"replay changed authoritative military state")
		check(GameState.elapsed_days==day,"replay advanced the calendar")
	check(screen.resolve_count==1,"replay resolved combat twice")
	screen.view.playback_speed=0;var clock:float=screen.view.clock;screen.view._process(1)
	check(screen.view.clock==clock,"paused observation clock advanced")
	screen.free()
	await get_tree().process_frame
	if failures.is_empty():print("BATTLE_GRAPHICS_PROBE PASS: invasion UI, responsive observation controls, one resolution, replay accounting, pause, zero actors")
	else:
		for failure in failures:push_error(failure)
	get_tree().quit(0 if failures.is_empty() else 1)

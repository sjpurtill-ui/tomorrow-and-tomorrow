extends Node
## Opt-in benchmark of a private mature save. See YEAR20_PERFORMANCE_HANDOFF.md.
class QuietAnnouncements extends CanvasLayer:
	var closing:=false
	var notices:=0
	func enqueue(events:Array[Dictionary])->void:notices+=events.size()

func _ready()->void:
	if not OS.get_user_data_dir().ends_with("TomorrowYear20PerformanceTests"):
		push_error("Performance probes require isolated TomorrowYear20PerformanceTests userdata.")
		get_tree().quit(2);return
	DisplayServer.window_set_title("Performance check — isolated save copy")
	var started:=Time.get_ticks_usec()
	_report("PERF_LOADING")
	var loaded:=SaveSystem.load_game("performance_fixture" if "--repaired-fixture" in OS.get_cmdline_user_args() else "performance_snapshot")
	if not bool(loaded.get("ok",false)):
		push_error(str(loaded));get_tree().quit(2);return
	_report("PERF_LOADED ",loaded," ms=",(Time.get_ticks_usec()-started)/1000)
	if "--save-roundtrip" in OS.get_cmdline_user_args():
		var before:=_outcome()
		started=Time.get_ticks_usec()
		var saved:=SaveSystem.save_game("performance_resaved")
		_report("PERF_SAVED ",saved," ms=",(Time.get_ticks_usec()-started)/1000)
		if not bool(saved.get("ok",false)):get_tree().quit(2);return
		_report("PERF_SAVE_BYTES ",FileAccess.get_file_as_bytes("user://saves/performance_resaved.save").size())
		started=Time.get_ticks_usec()
		var restored:=SaveSystem.load_game("performance_resaved")
		_report("PERF_RELOADED ",restored," ms=",(Time.get_ticks_usec()-started)/1000)
		var same:=before==_outcome()
		_report("PERF_SAVE_CONTINUITY ",same)
		WorldSimulation.clear();get_tree().quit(0 if same and bool(restored.get("ok",false)) else 2);return
	GameState.civic_api_enabled=false
	var terrain=load("res://local_terrain.tscn").instantiate();add_child(terrain)
	terrain._set_game_speed(0);terrain.set_process(false)
	CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	await get_tree().process_frame
	_report("PERF_READY day=",GameState.elapsed_days," actors=",WorldSimulation.actors.size())
	if "--paced" in OS.get_cmdline_user_args():
		if PeopleDirection.needs_century_choice():PeopleDirection.choose("makers")
		if is_instance_valid(PeopleDirection.panel):PeopleDirection.panel.queue_free();PeopleDirection.panel=null
		var quiet:QuietAnnouncements=null
		if "--uninterrupted" in OS.get_cmdline_user_args():
			quiet=QuietAnnouncements.new();terrain.hud.add_child(quiet)
			terrain.hud.set_meta("discovery_popup",quiet)
		terrain.set_process(true)
		var warmup:=Time.get_ticks_usec()
		while Time.get_ticks_usec()-warmup<5000000:await get_tree().process_frame
		terrain._set_game_speed(5)
		var start_day:=GameState.elapsed_days
		var start_time:=Time.get_ticks_usec()
		var start_frame:=Engine.get_process_frames()
		while Time.get_ticks_usec()-start_time<30000000:
			await get_tree().process_frame
			if terrain.hud.has_meta("discovery_popup"):
				var popup:Variant=terrain.hud.get_meta("discovery_popup")
				if is_instance_valid(popup) and not popup is QuietAnnouncements:popup.close()
		terrain._set_game_speed(0);terrain.set_process(false)
		var seconds:=float(Time.get_ticks_usec()-start_time)/1000000.0
		_report("PERF_PACED ",JSON.stringify({"seconds":seconds,"days":GameState.elapsed_days-start_day,"days_per_second":(GameState.elapsed_days-start_day)/seconds,"frames":Engine.get_process_frames()-start_frame,"uninterrupted":quiet!=null,"announcements":quiet.notices if quiet!=null else -1}))
		if "--strategies" in OS.get_cmdline_user_args():
			var rulers:Array[Dictionary]=[]
			for id:String in WorldSimulation.actors:
				WorldSimulation.scoped(id,func()->void:
					var plan:=preload("res://scripts/civilization_controller.gd").current_plan(id)
					rulers.append({"id":id,"goals":plan.goals,"recruit_share":plan.recruit_share,"personnel":WorldSimulation.military._mobilized_count(),"research":WorldSimulation.state.research_allocations.duplicate(true),"training":WorldSimulation.military.training_staff.data.policies.duplicate(true),"orders":WorldSimulation.actors[id].orders.duplicate(true)})
				)
			_report("PERF_STRATEGIES ",JSON.stringify(rulers))
		if "--capture" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("user://performance-map.png")
		terrain.queue_free();WorldSimulation.clear();await get_tree().process_frame;get_tree().quit();return
	for method in ["_refresh_contact_encounter_markers","_refresh_foreign_formation_markers","_refresh_player_field_army_markers","_refresh_player_scout_route_markers","_refresh_settlement_network","_discovery_context","_refresh_discovered_resource_overlays","_refresh_settlement_footprint","_update_time_interface"]:
		started=Time.get_ticks_usec()
		for i in 3:terrain.call(method)
		_report("PERF_METHOD ",method," mean_ms=",(Time.get_ticks_usec()-started)/3000.0)
	for i in 12:
		var day:=int(GameState.elapsed_days)+1
		started=Time.get_ticks_usec()
		var context:Dictionary=terrain._discovery_context()
		WorldSimulation.advance_day(day,context,terrain._process_local_settlement_day)
		_report("PERF_DAY ",day," ms=",(Time.get_ticks_usec()-started)/1000.0)
		await get_tree().process_frame
	var result:=_outcome()
	FileAccess.open("user://performance-outcome.dat",FileAccess.WRITE).store_buffer(var_to_bytes(result))
	terrain.queue_free();WorldSimulation.clear();await get_tree().process_frame
	get_tree().quit()

func _outcome()->Dictionary:
	var result:Dictionary={}
	var ids:Array=["player"];ids.append_array(WorldSimulation.actors.keys())
	for id:String in ids:
		WorldSimulation.scoped(id,func()->void:result[id]={"population":WorldSimulation.state.population_exact,"cohorts":WorldSimulation.state.population_cohorts.duplicate(true),"stores":WorldSimulation.state.resource_stockpiles.duplicate(true),"cities":WorldSimulation.state.player_settlements.duplicate(true),"discoveries":WorldSimulation.state.known_discoveries.duplicate(),"progress":WorldSimulation.state.discovery_progress.duplicate(true),"rng":WorldSimulation.discovery.rng.state,"military":WorldSimulation.military.export_state()})
	return result

func _report(a:Variant,b:Variant="",c:Variant="",d:Variant="")->void:
	var message:=str(a,b,c,d)
	print(message)
	var path:="user://performance-probe.log"
	var file:=FileAccess.open(path,FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE)
	file.seek_end();file.store_line(message)

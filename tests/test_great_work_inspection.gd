extends GdUnitTestSuite
const Atlas=preload("res://scripts/hud/great_works_atlas.gd")
const Pause=preload("res://scripts/hud/simulation_pause.gd")
const U=preload("res://scripts/undertaking_system.gd")
const C=preload("res://scripts/undertaking_catalog.gd")
const W=preload("res://scripts/wonder_concept.gd")

class ClockHost extends Node:
	var game_speed:=2.0
	func _set_game_speed(value:float)->void:game_speed=value

var host:ClockHost
var city:Dictionary
var record:Dictionary
var view:Control

func before_test()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(7615)
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	SettlementModel.reset_for_new_world();HistoricalFigures.reset_for_new_world()
	GameState.settlement_name="First Light";GameState.settlement_site_committed=true
	GameState.settlement_completed.assign(["Hearth Circle"]);SettlementModel.ensure_founded()
	GameState.population_total=180;GameState.population_exact=180.0
	GameState.population_allocations={"Construction":20,"Food":30,"Crafting":10}
	GameState.resource_stockpiles={"Stone":2000.0,"Timber":2000.0,"Clay":2000.0,"Fiber Plants":2000.0}
	city=GameState.player_settlements[0]
	var id:=W.make_id("ring","honor_dead","modest","stone",0,"ab1234")
	var amount:=float(C.get_definition(id).get("work",1000.0))
	record={"id":id,"status":"building","policy":"careful","progress":amount*.32,"quality":amount*.32,
		"custom_name":"First Light Stones","condition":1.0,"strain":0,"stalled_days":0,"operating_days":0,
		"last_day":0,"started":0,"reason":"","legacy":"Unproven","gates":[],"decisions":[],
		"work_scale":1.0,"speed":1.0,"allure_scale":1.0,"last_work":10.0,"shift":0.0,"feasibility":.8}
	city.undertakings=[record]
	host=ClockHost.new();add_child(host)
	view=null

func after_test()->void:
	if is_instance_valid(view):view.close()
	await get_tree().process_frame
	if is_instance_valid(host):host.free()
	WorldSimulation.clear();GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)

func _open()->void:
	view=Atlas.open(host,host,null,"player/%s/%s" % [city.id,record.id])
	await get_tree().process_frame
	await get_tree().process_frame

func test_inspection_is_live_data_without_advancing_work()->void:
	var before:=record.duplicate(true)
	await _open()
	assert_float(host.game_speed).is_equal(0.0)
	assert_object(view.find_child("DetailModel",true,false)).is_not_null()
	assert_str((view.find_child("Milestone1",true,false) as Label).text).contains("Raising stones")
	assert_float(float(view._model_record({"progress":.32},record).fraction)).is_equal(.32)
	view._refresh_live_work()
	assert_dict(record).is_equal(before)
	assert_bool(Pause.blocks(host)).is_true()

func test_watch_releases_only_its_pause_and_restores_running_speed()->void:
	await _open()
	view.set_watching(true)
	assert_float(host.game_speed).is_equal(2.0)
	assert_bool(Pause.blocks(host)).is_false()
	view.set_watching(false)
	assert_float(host.game_speed).is_equal(0.0)
	view.close();await get_tree().process_frame
	assert_float(host.game_speed).is_equal(2.0)
	assert_bool(Pause.blocks(host)).is_false()

func test_watch_from_paused_clock_returns_to_paused_on_close()->void:
	host.game_speed=0.0
	await _open()
	view.set_watching(true)
	assert_float(host.game_speed).is_equal(3.0)
	view._set_watch_pace(4)
	assert_float(host.game_speed).is_equal(5.0)
	view.close();await get_tree().process_frame
	assert_float(host.game_speed).is_equal(0.0)
	assert_bool(Pause.blocks(host)).is_false()

func test_watch_cannot_release_another_audiences_pause()->void:
	var other:=Pause.new();other.acquire(host)
	await _open()
	view.set_watching(true)
	assert_bool(view.watching).is_false()
	assert_float(host.game_speed).is_equal(0.0)
	view.close();await get_tree().process_frame
	assert_bool(Pause.blocks(host)).is_true()
	other.release()
	assert_float(host.game_speed).is_equal(2.0)

func test_daily_progress_retains_model_and_updates_truthful_status()->void:
	await _open()
	var model:Control=view.model_view
	var geometry:Node3D=model.model_root
	model.orbit_by(Vector2(70,20));model.zoom_by(2.0);model.set_plan_visible(true);model.set_scaffolds_visible(false)
	var before:Dictionary=model.report()
	record.progress=U.total_work(record)*.321
	view._refresh_live_work()
	assert_object(view.model_view).is_same(model)
	assert_object(model.model_root).is_same(geometry)
	assert_float((view.find_child("Progress",true,false) as ProgressBar).value).is_equal(.321)
	record.status="stalled";record.reason="Waiting for Stone."
	view._refresh_live_work();await get_tree().process_frame
	assert_str((view.find_child("StatusLine",true,false) as Label).text).contains("Idle").contains("stone")
	assert_object(view.model_view).is_same(model)
	var after:Dictionary=model.report()
	for key:String in ["yaw","pitch","zoom","plan","scaffolds"]:assert_that(after[key]).is_equal(before[key])

func test_nested_pause_during_watch_keeps_the_originally_paused_clock()->void:
	host.game_speed=0.0
	await _open();view.set_watching(true)
	var other:=Pause.new();other.acquire(host)
	view._set_watch_pace(4)
	assert_float(host.game_speed).is_equal(0.0)
	view.close();await get_tree().process_frame
	assert_bool(Pause.blocks(host)).is_true()
	other.release()
	assert_float(host.game_speed).is_equal(0.0)

func test_completion_exposes_the_actual_pending_dedication()->void:
	await _open()
	view.set_watching(true)
	assert_object(view.find_child("DedicateWork",true,false)).is_null()
	record.progress=U.total_work(record);record.status="functioning";record.outcome="success"
	record.ceremony={"status":"pending","day":0,"attendees":[],"name_suggestions":["First Light Stones"]}
	view._refresh_live_work();await get_tree().process_frame
	assert_object(view.find_child("DedicateWork",true,false)).is_not_null()
	assert_str((view.find_child("StatusLine",true,false) as Label).text).contains("Standing")
	assert_str(record.ceremony.status).is_equal("pending")
	assert_bool(view.watching).is_false()
	assert_bool(Pause.blocks(host)).is_true()
	assert_float(host.game_speed).is_equal(0.0)

func test_ruined_list_illustrations_keep_triangulable_silhouettes()->void:
	var plate:Control=preload("res://scripts/hud/great_work_plate.gd").new()
	for shape:String in W.FORMS:
		plate.shape=shape
		for variation in 7:
			plate.variant=variation
			for part:Array in plate._parts(Vector2(60,70),52.0):
				var polygon:PackedVector2Array=plate._ruin(part[0],70.0)
				assert_int(Geometry2D.triangulate_polygon(polygon).size()).is_greater_equal(3)
	plate.free()

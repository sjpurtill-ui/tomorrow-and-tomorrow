extends GdUnitTestSuite
## Watch changes must update the open popup without a transient layout jump.

const BorderMap:=preload("res://scripts/hud/border_map.gd")
const Forts:=preload("res://scripts/fort_border.gd")

class TerrainStub extends Node3D:
	var camera:Camera3D
	var world_globe:Node

var view:SubViewport
var map:Node
var processing:Dictionary={}

func before_test()->void:
	for system:Node in [GameState,MilitaryCampaign,CivilizationSystem,WorldSimulation]:
		processing[system]=system.is_processing();system.set_process(false)
	WorldSimulation.clear()
	GameState.reset_for_new_world(424242)
	GameState.settlement_site_committed=true
	GameState.settlement_founded_at=Vector3.ZERO
	GameState.player_settlements=[{"id":"seat","primary":true,"position":Vector2.ZERO,"claim_radius_km":5.0}]
	GameState.ensure_population_total(5000)
	GameState.population_allocations["Defense"]=600
	GameState.resource_stockpiles={"Timber":5000.0,"Stone":5000.0,"Food":50000.0}
	GameState.known_discoveries=["joinery"]
	GameState.border_forts={"seeded":true,"border_share":0.5,"forts":[
		{"id":1,"kind":"palisade_fort","x":80.0,"z":0.0,"status":"standing","condition":1.0,"progress":6000.0,"name":"East Ridge"},
		{"id":2,"kind":"palisade_fort","x":0.0,"z":80.0,"status":"standing","condition":1.0,"progress":6000.0,"name":"River Gate"}]}
	view=SubViewport.new();view.size=Vector2i(1152,720);add_child(view)
	var terrain:=TerrainStub.new();view.add_child(terrain)
	map=BorderMap.ensure(terrain);map.call("set_enabled",true)
	map.set_process(false)
	for frame in 16:
		map.call("_process",0.0)
		await get_tree().process_frame

func after_test()->void:
	view.queue_free()
	await get_tree().process_frame
	GameState.border_forts={}
	for system:Node in processing:system.set_process(bool(processing[system]))
	processing.clear()

func _words()->String:
	var words:PackedStringArray=[]
	for node in (map.get("key_card") as Control).find_children("*","Label",true,false):
		if node.is_visible_in_tree():words.append(node.text)
	return " | ".join(words)

func test_daily_watch_changes_keep_every_refresh_frame_steady_and_values_current()->void:
	var card:Control=map.get("key_card")
	var before:=card.get_global_rect()
	var peak_delta:=0.0
	for day in 4:
		GameState.elapsed_days+=1
		GameState.population_allocations["Defense"]=602+day*2
		map.call("_process",0.6)
		for frame in 12:
			var rect:=card.get_global_rect()
			peak_delta=maxf(peak_delta,rect.size.distance_to(before.size))
			peak_delta=maxf(peak_delta,rect.position.distance_to(before.position))
			await get_tree().process_frame
			map.call("_process",0.0)
		assert_str(_words()).contains(str(int(Forts.watch().posted)))
	assert_float(peak_delta).override_failure_message("Daily refresh moved/resized the border popup by %.1f px" % peak_delta).is_less_equal(1.0)

func test_daily_refresh_preserves_focused_watch_control()->void:
	var button:=map.find_child("MoreBorderWatch",true,false) as Button
	button.grab_focus()
	GameState.population_allocations["Defense"]=602
	map.call("_process",0.6)
	await get_tree().process_frame
	assert_bool(is_instance_valid(button)).override_failure_message("The focused watch control was destroyed during a daily update").is_true()
	if is_instance_valid(button):assert_object(view.gui_get_focus_owner()).is_same(button)

func test_staffing_action_reads_the_latest_watch_capacity()->void:
	Forts.set_border_share(0.05)
	map.call("_process",0.6)
	GameState.population_allocations["Defense"]=400
	map.call("_process",0.6)
	await get_tree().process_frame
	var button:=map.find_child("ManEveryFort",true,false) as Button
	assert_bool(button.is_visible_in_tree()).is_true()
	button.pressed.emit()
	assert_float(Forts.border_share()).is_equal_approx(0.3,0.001)
	assert_int(int(Forts.watch().garrisons[1])).is_equal(60)
	assert_int(int(Forts.watch().garrisons[2])).is_equal(60)

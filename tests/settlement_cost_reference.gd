extends Node
const Day=preload("res://scripts/civilization_day.gd")
class Terrain extends "res://scripts/local_terrain.gd":
	func _ready()->void:pass
	func _process(_delta:float)->void:pass
func _ready()->void:call_deferred("run")
func run()->void:
	if DisplayServer.get_name()!="headless" or "--settlement-reference" not in OS.get_cmdline_user_args():get_tree().quit(2);return
	var saves=get_tree().root.get_node("SaveSystem")
	var result:Dictionary=saves.load_game("quicksave")
	if result.has("error"):print(result);get_tree().quit(1);return
	var world=get_tree().root.get_node("WorldSimulation")
	var state=get_tree().root.get_node("GameState")
	for node in get_tree().root.get_children():node.set_process(false);node.set_physics_process(false)
	state.civic_api_enabled=false
	for id in world.actors:world.actors[id].systems.GameState.civic_api_enabled=false
	var terrain:=Terrain.new();get_tree().root.add_child(terrain)
	terrain._configure_seamless_world();terrain._configure_shape();terrain._configure_noise()
	world.context_provider=terrain._civilization_geography
	world.surface_material_provider=terrain._civilization_surface_materials
	terrain.camera=Camera3D.new();terrain.add_child(terrain.camera)
	terrain.settler_marker=Area3D.new();terrain.add_child(terrain.settler_marker)
	terrain.settler_marker.position=state.settlement_founded_at
	var report:Dictionary={"day":state.elapsed_days,"population":state.population_total,"cities":state.player_settlements.size(),"plots":state.settlement_plots.size(),"routes":state.settlement_routes.size(),"fabric":[]}
	for lod in [0,1,2]:
		var parent:=Node3D.new();terrain.add_child(parent)
		var plots:Array[Dictionary]=get_tree().root.get_node("SettlementModel").plots_for_lod(lod)
		var start:=Time.get_ticks_usec()
		terrain._create_plot_fabric(state.settlement_founded_at,plots,lod,parent)
		report.fabric.append({"lod":lod,"plots":plots.size(),"build_ms":(Time.get_ticks_usec()-start)/1000.0,"nodes":parent.get_child_count()})
		parent.free()
	var day:=int(state.elapsed_days)+1
	var start:=Time.get_ticks_usec()
	world.advance_rivals(day)
	report.rivals_ms=(Time.get_ticks_usec()-start)/1000.0
	var timings:Dictionary={"enabled":true}
	var secondary:Dictionary={"enabled":true}
	Day.advance(day,terrain._discovery_context(),terrain._process_local_settlement_day,timings,secondary)
	report.player_phases=timings;report.secondary_phases=secondary
	var file:=FileAccess.open("res://artifacts/settlement-baseline.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "));file.close()
	print("SETTLEMENT_BASELINE ",JSON.stringify(report))
	world.clear();terrain.free();get_tree().quit()
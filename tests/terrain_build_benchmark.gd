extends Node
## Headless paired cold-build check; run after freezing the reviewed old builder
## as res://artifacts/terrain-pan/baseline-builder.gd. No player state or rendering.
class Terrain extends "res://scripts/local_terrain.gd":
	func _ready()->void:pass
	func _process(_delta:float)->void:pass
func _ready()->void:call_deferred("run")
func run()->void:
	for node:Node in get_tree().root.get_children():node.set_process(false);node.set_physics_process(false)
	GameState.reset_for_new_world(873421)
	var terrain:=Terrain.new();add_child(terrain)
	terrain._configure_seamless_world();terrain._configure_shape();terrain._configure_noise()
	var previous:Script=load("res://artifacts/terrain-pan/baseline-builder.gd")
	var current:Script=load("res://scripts/terrain_patch_builder.gd")
	var records:Array[Dictionary]=[]
	for pass_id in 4:
		var old:=pass_id==0 or pass_id==3
		var begin:=Time.get_ticks_usec()
		var job:RefCounted=(previous if old else current).new(385,7.59375,Vector2(55.0546875,0),terrain._height_at,terrain._terrain_color_at,terrain._terrain_surface_fields_at,terrain._terrain_seasonality_at)
		while not job.advance(1000):pass
		var row:={"pass":pass_id,"mode":"baseline" if old else "candidate","build_ms":float(Time.get_ticks_usec()-begin)/1000.0}
		records.append(row);print("TERRAIN_COLD_BUILD ",JSON.stringify(row))
	var file:=FileAccess.open("res://artifacts/terrain-pan/cold-build.json",FileAccess.WRITE);file.store_string(JSON.stringify(records,"  "));file.close()
	terrain.queue_free();WorldSimulation.clear();get_tree().quit()

extends Node
## Paired sample-only benchmark. Wrapper cost is present in both arms; this
## isolates new noise cost, not a claim about full-frame performance.
const RELIEF:=preload("res://scripts/terrain_mountain_relief.gd")
const BUILDER:=preload("res://scripts/terrain_patch_builder.gd")
class NoRelief extends "res://scripts/terrain_mountain_relief.gd":
	func height_at(_x:float,_z:float,_uplift:float)->float:return 0.0
class Terrain extends "res://scripts/local_terrain.gd":
	func _ready()->void:pass
	func _process(_delta:float)->void:pass
func _ready()->void:call_deferred("run")
func run()->void:
	for node:Node in get_tree().root.get_children():node.set_process(false);node.set_physics_process(false)
	GameState.reset_for_new_world(873421)
	var terrain:=Terrain.new();terrain._configure_seamless_world();terrain._configure_shape();terrain._configure_noise()
	var detailed:RefCounted=terrain.mountain_relief;var baseline:=NoRelief.new()
	for site:Vector2 in [Vector2(2000,-1000),Vector2(55,0)]:
		for pass_id in 6:
			var is_baseline:=pass_id%2==0
			terrain.mountain_relief=baseline if is_baseline else detailed
			var began:=Time.get_ticks_usec();var sum:=0.0
			for z in 257:
				for x in 257:sum+=terrain._height_at(site.x+float(x)*.04,site.y+float(z)*.04)
			print("RIDGE_SAMPLE_TIME ",JSON.stringify({"site":str(site),"baseline":is_baseline,"samples":66049,"elapsed_ms":float(Time.get_ticks_usec()-began)/1000.0,"checksum":sum}))
	# Match the production builder's complete set of callbacks, including the
	# seasonal channel omitted from the standalone material comparison.
	for pass_id in 4:
		var is_baseline:=pass_id==0 or pass_id==3
		terrain.mountain_relief=baseline if is_baseline else detailed
		var began:=Time.get_ticks_usec()
		var job:=BUILDER.new(385,7.59375,Vector2(55.0546875,0),terrain._height_at,terrain._terrain_color_at,terrain._terrain_surface_fields_at,terrain._terrain_seasonality_at)
		while not job.advance(1000):pass
		print("RIDGE_COMPLETE_BUILD ",JSON.stringify({"baseline":is_baseline,"vertices":job.vertices.size(),"elapsed_ms":float(Time.get_ticks_usec()-began)/1000.0}))
	terrain.free();WorldSimulation.clear();get_tree().quit()

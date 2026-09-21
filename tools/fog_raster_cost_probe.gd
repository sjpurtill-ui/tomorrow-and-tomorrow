extends Node
func _ready()->void:
	if DisplayServer.get_name()!="headless":get_tree().quit(2);return
	var terrain=load("res://scripts/local_terrain.gd").new()
	terrain.world_width=terrain.PLANET_WIDTH_KM;terrain.world_depth=terrain.PLANET_DEPTH_KM
	var reference=load("res://tests/fog_painter_reference.gd").new(terrain)
	var results:Array=[]
	for entry in [["long diagonal",Vector2(-18000,-8000),Vector2(18000,8000),18.0],["regional diagonal",Vector2(-3000,-1500),Vector2(3000,1500),18.0],["horizontal",Vector2(-18000,0),Vector2(18000,0),18.0]]:
		var before:=Image.create(1024,512,false,Image.FORMAT_L8)
		var after:=Image.create(1024,512,false,Image.FORMAT_L8)
		before.fill(Color.BLACK);after.fill(Color.BLACK)
		var start:=Time.get_ticks_usec()
		reference.paint_reference(before,entry[1],entry[2],entry[3],1024,512)
		var old_us:=Time.get_ticks_usec()-start
		start=Time.get_ticks_usec()
		terrain._paint_discovery_segment(after,entry[1],entry[2],entry[3],1024,512)
		var new_us:=Time.get_ticks_usec()-start
		assert(before.get_data()==after.get_data())
		results.append({"case":entry[0],"before_us":old_us,"after_us":new_us,"pixels_identical":true})
	print("FOG_RASTER_COST ",JSON.stringify(results))
	terrain.free();get_tree().quit()

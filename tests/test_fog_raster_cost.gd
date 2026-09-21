extends GdUnitTestSuite
const Terrain=preload("res://scripts/local_terrain.gd")
const Reference=preload("res://tests/fog_painter_reference.gd")
func test_row_clipping_preserves_every_pixel_across_corridors_and_edges()->void:
	var terrain:Node=auto_free(Terrain.new())
	terrain.world_width=1000.0;terrain.world_depth=500.0
	var reference:=Reference.new(terrain)
	var cases:Array=[
		[Vector2(-500,-250),Vector2(500,250),1.0],
		[Vector2(500,-250),Vector2(-500,250),1.0],
		[Vector2(-500,0),Vector2(500,0),2.0],
		[Vector2(0,-250),Vector2(0,250),2.0],
		[Vector2.ZERO,Vector2.ZERO,0.0],
		[Vector2(800,800),Vector2(1000,1000),4.0],
		[Vector2(-1000,-500),Vector2(1000,500),0.1],
		[Vector2(-500,-250),Vector2(500,-249.99999),10.0],
		[Vector2(20,30),Vector2(-20,-30),1000.0]
	]
	var rng:=RandomNumberGenerator.new();rng.seed=4627
	for index in 40:
		cases.append([Vector2(rng.randf_range(-900,900),rng.randf_range(-450,450)),Vector2(rng.randf_range(-900,900),rng.randf_range(-450,450)),rng.randf_range(0,60)])
	var expected:=Image.create(128,64,false,Image.FORMAT_L8)
	var actual:=Image.create(128,64,false,Image.FORMAT_L8)
	for entry in cases:
		expected.fill(Color.BLACK);actual.fill(Color.BLACK)
		reference.paint_reference(expected,entry[0],entry[1],entry[2],128,64)
		terrain._paint_discovery_segment(actual,entry[0],entry[1],entry[2],128,64)
		assert_bool(expected.get_data()==actual.get_data()).override_failure_message(str(entry)).is_true()
func test_overlapping_trails_and_existing_discs_preserve_full_resolution_mask()->void:
	var terrain:Node=auto_free(Terrain.new())
	terrain.world_width=Terrain.PLANET_WIDTH_KM;terrain.world_depth=Terrain.PLANET_DEPTH_KM
	var reference:=Reference.new(terrain)
	var expected:=Image.create(1024,512,false,Image.FORMAT_L8)
	var actual:=Image.create(1024,512,false,Image.FORMAT_L8)
	expected.fill(Color.BLACK);actual.fill(Color.BLACK)
	for image:Image in [expected,actual]:terrain._paint_discovery_disc(image,Vector2.ZERO,240.0,1024,512)
	for entry in [[Vector2(-18000,-8000),Vector2(18000,8000),18.0],[Vector2(-18000,8000),Vector2(18000,-8000),72.0],[Vector2.ZERO,Vector2(12000,5000),12.0]]:
		reference.paint_reference(expected,entry[0],entry[1],entry[2],1024,512)
		terrain._paint_discovery_segment(actual,entry[0],entry[1],entry[2],1024,512)
	assert_bool(expected.get_data()==actual.get_data()).is_true()

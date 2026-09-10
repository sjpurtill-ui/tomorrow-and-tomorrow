extends GdUnitTestSuite
const Cover=preload("res://scripts/landscape_cover.gd")
class Terrain extends "res://scripts/local_terrain.gd":
	var land_biome:={"id":"woodland","woodland":.8,"precipitation":.82,"temperature":.55}
	var water_half:=false
	var cleared:=false
	var captured:Dictionary={}
	func _create_close_vegetation_multimesh(node_name:String,transforms:Array[Transform3D],colors:Array[Color],_radius:float,_height:float)->void:
		if node_name!="TreeCanopies":return
		captured={}
		for i in transforms.size():captured[transforms[i].origin]={"basis":transforms[i].basis,"variant":Cover.crown_variant(transforms[i].origin),"color":colors[i]}
	func _ready()->void:pass
	func _process(_delta:float)->void:pass
	func _height_at(x:float,_z:float)->float:return -1.0 if water_half and x<0 else 1.0
	func _close_surface_height_at(_x:float,_z:float)->float:return 1.0
	func _biome_at(_x:float,_z:float,_height:float=NAN)->Dictionary:return land_biome
	func _local_drainage_distance_at(_x:float,_z:float)->float:return .04
	func _near_persistent_settlement_surface(point:Vector2)->bool:return cleared and point.length()<.025
func fixture()->Terrain:
	GameState.reset_for_new_world(424242)
	var terrain:Terrain=auto_free(Terrain.new());add_child(terrain)
	terrain.terrain_noise=FastNoiseLite.new();terrain.terrain_noise.seed=42
	terrain.moisture_noise=FastNoiseLite.new();terrain.moisture_noise.seed=51;terrain.moisture_noise.frequency=.2
	terrain.detail_noise=FastNoiseLite.new();terrain.detail_noise.seed=73;terrain.detail_noise.frequency=.25
	return terrain
func crowns(terrain:Terrain)->Dictionary:
	return terrain.captured.duplicate(true)
func test_dry_and_cold_surveys_cannot_generate_a_visual_timber_forest()->void:
	var terrain:=fixture()
	for biome:Dictionary in [{"id":"steppe","woodland":0.0,"precipitation":.18,"temperature":.85},{"id":"tundra","woodland":0.0,"precipitation":.7,"temperature":.1}]:
		terrain.land_biome=biome;GameState.morphology_revision+=1;terrain._rebuild_close_vegetation(Vector3.ZERO)
		assert_dict(crowns(terrain)).is_empty()
		terrain._scatter_landscape_vegetation()
		assert_object(terrain.get_node_or_null("WoodlandCanopy")).is_null()
func test_wet_woodland_generates_canopies_but_never_under_water()->void:
	var terrain:=fixture();terrain.water_half=true;terrain._rebuild_close_vegetation(Vector3.ZERO)
	var trees:=crowns(terrain);assert_int(trees.size()).is_greater(0)
	for position:Vector3 in trees:assert_float(position.x).is_greater_equal(0.0)
func test_world_samples_are_unchanged_when_detail_center_moves()->void:
	var first:=Cover.candidates(Vector2(4.11,-6.2),.235,.008,42)
	var second:=Cover.candidates(Vector2(4.16,-6.19),.235,.008,42)
	var points:Dictionary={}
	for item in first:points[item.point]=item.seed
	var overlap:=0
	for item in second:
		if points.has(item.point):assert_int(item.seed).is_equal(points[item.point]);overlap+=1
	assert_int(overlap).is_greater(2000)
	assert_int(first.size()).is_less(3600)
func test_clearing_one_parcel_does_not_move_or_restyle_distant_crowns()->void:
	var terrain:=fixture();terrain._rebuild_close_vegetation(Vector3.ZERO);var before:=crowns(terrain)
	assert_int(before.size()).is_greater(0)
	terrain.cleared=true;GameState.morphology_revision+=1;terrain._rebuild_close_vegetation(Vector3.ZERO)
	var after:=crowns(terrain);var checked:=0
	for position:Vector3 in before:
		if Vector2(position.x,position.z).length()<.07:continue
		assert_bool(after.has(position)).is_true()
		if after.has(position):assert_dict(after[position]).is_equal(before[position]);checked+=1
	assert_int(checked).is_greater(0)
func test_actual_canopies_remain_fixed_through_overlapping_detail_moves()->void:
	var terrain:=fixture();terrain._rebuild_close_vegetation(Vector3.ZERO);var before:=crowns(terrain)
	terrain._rebuild_close_vegetation(Vector3(.04,0,.02));var after:=crowns(terrain);var checked:=0
	for position:Vector3 in before:
		if absf(position.x)>.15 or absf(position.z)>.15:continue
		assert_bool(after.has(position)).is_true()
		if after.has(position):assert_dict(after[position]).is_equal(before[position]);checked+=1
	assert_int(checked).is_greater(0)
func test_scrub_appearance_and_density_follow_real_climate()->void:
	var dry:={"id":"steppe","woodland":0.0,"precipitation":.16,"temperature":.8}
	var wet:={"id":"wetland","woodland":.5,"precipitation":.85,"temperature":.6}
	assert_float(Cover.scrub_density(dry)).is_less(Cover.scrub_density(wet))
	var dry_color:=Cover.scrub_tint(dry,.5);var wet_color:=Cover.scrub_tint(wet,.5)
	assert_float(dry_color.r).is_greater(dry_color.g);assert_float(wet_color.g).is_greater(wet_color.r)

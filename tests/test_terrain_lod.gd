extends GdUnitTestSuite

func test_cartographic_relief_begins_after_close_ground_is_unresolved()->void:
	var source:=FileAccess.get_file_as_string("res://scripts/local_terrain.gd")
	assert_str(source).contains("float map_relief = smoothstep(0.035,0.28,pixel_world)")
const LOD:=preload("res://scripts/terrain_lod.gd")
const SURFACE:=preload("res://scripts/rendered_surface_height.gd")
class Terrain extends "res://scripts/local_terrain.gd":
	func _ready()->void:pass
	func _process(_delta:float)->void:pass
class CheapTerrain extends Terrain:
	func _height_at(x:float,z:float)->float:return x*.001+z*.002
	func _terrain_color_at(_x:float,_z:float,_h:float)->Color:return Color(.2,.3,.15)
	func _terrain_surface_fields_at(_x:float,_z:float,_h:float)->Vector4:return Vector4(1.5,.5,.5,.3)
func fixture()->CheapTerrain:
	var terrain:CheapTerrain=auto_free(CheapTerrain.new());add_child(terrain)
	return terrain
func finish_job(terrain:CheapTerrain)->void:
	while terrain.terrain_patch_job!=null:terrain._advance_terrain_patch()
func test_four_distances_cover_rotated_tilted_and_wide_views()->void:
	for width:float in [2.842611486,14.21305743,150,3000]:
		for aspect:float in [1.0,1.5,1.778,3.556]:
			for pitch:float in [-PI*.5,-.98,-.44]:
				var height:=width/aspect
				var span:=LOD.bucket(LOD.view_span(height,aspect,pitch))
				var center:=Vector2(53.7,-161.2);var snapped:=LOD.center_for(center,span)
				for yaw:float in [0,.72,1.57,2.14]:
					for corner:Vector2 in [Vector2(-1,-1),Vector2(-1,1),Vector2(1,-1),Vector2(1,1)]:
						var footprint:=Vector2(corner.x*width*.5,corner.y*height*.5/sin(absf(pitch))).rotated(yaw)+center-snapped
						assert_float(maxf(absf(footprint.x),absf(footprint.y))).is_less(span*.5)
func test_continental_preview_and_cache_have_explicit_memory_and_density_limits()->void:
	var cache:Array[Dictionary]=[]
	for span:float in [1.2,12,30,100,600,6000,18000,40075]:
		var bucket:=LOD.bucket(span);var resolution:=LOD.resolution_for(bucket)
		assert_int(resolution).is_less_equal(513)
		assert_float(bucket/float(LOD.preview_resolution(bucket)-1)).is_less_equal(80.0)
		LOD.retain(cache,{"center":Vector2(span,0),"span":bucket,"resolution":resolution})
		var vertices:=0
		for entry in cache:vertices+=int(entry.resolution)*int(entry.resolution)
		assert_int(vertices).is_less_equal(600000)
		assert_int(cache.size()).is_less_equal(4)
	var old:=cache.duplicate()
	LOD.retain(cache,{"center":Vector2.ZERO,"span":LOD.bucket(6000),"resolution":129})
	assert_array(cache).is_equal(old)
func test_regional_preview_improves_before_final_detail_is_ready()->void:
	var terrain:=fixture();var point:=Vector2(200,30);var span:=LOD.bucket(290)
	var resolutions:Array[int]=[]
	for stage in 3:
		terrain._rebuild_regional_terrain_patch(point,span)
		finish_job(terrain);resolutions.append(terrain.regional_patch_resolution)
		assert_int(terrain.terrain_patch_cache.size()).is_equal(1 if stage==2 else 0)
	assert_array(resolutions).is_equal([33,129,385])
func test_continental_request_refines_and_cached_return_does_not_rebuild()->void:
	var terrain:=fixture();var camera:=Camera3D.new();terrain.add_child(camera);terrain.camera=camera;camera.size=2000
	terrain._update_world_streaming()
	assert_object(terrain.terrain_patch_job).is_not_null()
	var span:float=terrain.terrain_patch_job.span
	assert_float(span).is_greater(920)
	assert_int(terrain.terrain_patch_job.resolution).is_equal(LOD.preview_resolution(span))
	finish_job(terrain)
	assert_int(terrain.terrain_patch_cache.size()).is_equal(0)
	var preview:=terrain.regional_terrain_patch
	terrain._update_world_streaming()
	assert_int(terrain.terrain_patch_job.resolution).is_equal(385)
	terrain._advance_terrain_patch()
	assert_object(terrain.regional_terrain_patch).is_same(preview)
	finish_job(terrain)
	var mesh:Mesh=terrain.regional_terrain_patch.mesh
	assert_int(terrain.regional_patch_resolution).is_equal(385)
	terrain._rebuild_regional_terrain_patch(Vector2(9000,0),span)
	finish_job(terrain)
	terrain._rebuild_regional_terrain_patch(Vector2.ZERO,span)
	assert_object(terrain.terrain_patch_job).is_null()
	assert_object(terrain.regional_terrain_patch.mesh).is_same(mesh)
	assert_int(terrain.rendered_regional_heights.size()).is_equal(385*385)
func test_cancelled_camera_request_cannot_replace_visible_ground()->void:
	var terrain:=fixture();terrain._rebuild_regional_terrain_patch(Vector2.ZERO,40)
	finish_job(terrain);var old:=terrain.regional_terrain_patch
	terrain._rebuild_regional_terrain_patch(Vector2(500,0),6000)
	terrain._advance_terrain_patch()
	terrain._rebuild_regional_terrain_patch(Vector2(-800,0),150)
	assert_int(terrain.terrain_patch_cancellations).is_equal(1)
	assert_object(terrain.regional_terrain_patch).is_same(old)
	finish_job(terrain)
	assert_float(terrain.regional_patch_center.x).is_less(0)
func sampled_height(terrain:Terrain,point:Vector2,span:float,resolution:int)->float:
	return SURFACE.sample(point,Vector4(0,0,span,resolution),func(cell:Vector2i)->float:
		var p:=(Vector2(cell)/float(resolution-1)-Vector2(.5,.5))*span
		return terrain._height_at(p.x,p.y)+.0006)
func test_regional_sampling_resolves_more_of_the_real_landform()->void:
	GameState.reset_for_new_world(873421)
	var terrain:Terrain=auto_free(Terrain.new());add_child(terrain);terrain._configure_seamless_world();terrain._configure_shape();terrain._configure_noise()
	var span:=LOD.bucket(100*2.9);var old_error:=0.0;var new_error:=0.0
	for z in 31:
		for x in 43:
			var p:=Vector2(float(x)/42-.5,float(z)/30-.5)*150+Vector2(.147,.271)
			var true_height:=terrain._height_at(p.x,p.y)+.0006
			old_error+=pow(sampled_height(terrain,p,span,161)-true_height,2)
			new_error+=pow(sampled_height(terrain,p,span,LOD.resolution_for(span))-true_height,2)
	print("LOD_REGIONAL_RMSE_KM old=",sqrt(old_error/1333)," new=",sqrt(new_error/1333))
	assert_float(new_error).is_less(old_error*.65)
func test_continental_coast_matches_physical_land_more_closely()->void:
	GameState.reset_for_new_world(873421)
	var terrain:Terrain=auto_free(Terrain.new());add_child(terrain);terrain._configure_seamless_world();terrain._configure_shape();terrain._configure_noise()
	var old_wrong:=0;var new_wrong:=0;var shore_samples:=0
	var span:=LOD.bucket(2000*2.9)
	for z in 51:
		for x in 101:
			var p:=Vector2(float(x)/100-.5,float(z)/50-.5)*Vector2(3000,2000)+Vector2(17.19,3.47)
			var height:=terrain._height_at(p.x,p.y)
			if absf(height)>.2:continue
			shore_samples+=1
			# Exactly the old global mesh's 481 x 241 vertices and fixed diagonal.
			var cell:=(p/Vector2(terrain.world_width,terrain.world_depth)+Vector2(.5,.5))*Vector2(480,240)
			var base:=cell.floor();var f:=cell-base;var h:Array[float]=[]
			for corner:Vector2 in [Vector2.ZERO,Vector2.RIGHT,Vector2.ONE,Vector2.DOWN]:
				var q:=((base+corner)/Vector2(480,240)-Vector2(.5,.5))*Vector2(terrain.world_width,terrain.world_depth)
				h.append(terrain._height_at(q.x,q.y))
			var coarse:=h[0]+(h[1]-h[0])*f.x+(h[2]-h[1])*f.y if f.x>=f.y else h[0]+(h[2]-h[3])*f.x+(h[3]-h[0])*f.y
			if (coarse>0)!=(height>0):old_wrong+=1
			if (sampled_height(terrain,p,span,LOD.resolution_for(span))>0)!=(height>0):new_wrong+=1
	print("LOD_COAST samples=",shore_samples," wrong_old=",old_wrong," wrong_new=",new_wrong)
	assert_int(shore_samples).is_greater(100)
	assert_int(new_wrong).is_less(int(old_wrong*.70))

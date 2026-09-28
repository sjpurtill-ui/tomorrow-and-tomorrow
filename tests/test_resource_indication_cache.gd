extends GdUnitTestSuite
## codex/map-speed: a recognized occurrence's ground indication is sampled
## once a grid node (not once a triangle corner) and reused from a cache when
## the overlay regroups at the end of a zoom; what it draws is unchanged.
const Renderer:=preload("res://scripts/local_terrain.gd")
const LANDSCAPE:=preload("res://scripts/landscape_resource_visuals.gd")


func before_test()->void:
	GameState.reset_for_new_world(184271)
	PlanetEnvironment.reset_for_new_world()


func _world()->Node3D:
	var world:Node3D=auto_free(Renderer.new())
	world._configure_seamless_world();world._configure_shape();world._configure_noise()
	return world


## The former per-corner construction, kept verbatim as the oracle.
func _reference_arrays(world:Node3D,cluster:Dictionary)->Array:
	var center:Vector3=cluster.position
	var style:=LANDSCAPE.surface_style(String(cluster.resource))
	var radius:=0.35 if String(cluster.visual_stage)=="recognized" else 0.65
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in 12:
		for x in 12:
			for corner in [Vector2i(0,0),Vector2i(0,1),Vector2i(1,1),Vector2i(0,0),Vector2i(1,1),Vector2i(1,0)]:
				var offset:=Vector2(float(x+corner.x)/12.0*2.0-1.0,float(z+corner.y)/12.0*2.0-1.0)*radius
				var point:=Vector2(center.x,center.z)+offset
				var mottling:=clampf(0.55+world.detail_noise.get_noise_2d(point.x*8.0,point.y*8.0),0.0,1.0)
				var edge:=1.0-smoothstep(0.25,1.0,offset.length()/radius+mottling*0.20)
				if not world._world_position_is_revealed(Vector3(point.x,0.0,point.y)): edge=0.0
				var soil:Color=style.soil
				soil.a=edge*mottling*0.50
				surface.set_color(soil)
				surface.add_vertex(Vector3(point.x,world._height_at(point.x,point.y)+0.002,point.y))
	return surface.commit().surface_get_arrays(0)


func test_indication_is_the_former_mesh_vertex_for_vertex()->void:
	var world:=_world()
	var home:=Vector2(world.world_start_position.x,world.world_start_position.z)
	CivilizationSystem._add_revealed_area(home,20.0,"test")
	for cluster:Dictionary in [{"resource":"Stone","visual_stage":"recognized","position":Vector3(home.x+0.3,0.0,home.y-0.2)},
			{"resource":"Clay","visual_stage":"surveyed","position":Vector3(home.x-0.6,0.0,home.y+0.4)},
			{"resource":"Iron Ore","visual_stage":"recognized","position":Vector3(home.x+19.8,0.0,home.y)}]:
		var patch:MeshInstance3D=auto_free(world._build_resource_ground_indication(cluster))
		var arrays:=patch.mesh.surface_get_arrays(0)
		var reference:=_reference_arrays(world,cluster)
		assert_bool(arrays[Mesh.ARRAY_VERTEX]==reference[Mesh.ARRAY_VERTEX]).override_failure_message(String(cluster.resource)+" vertices").is_true()
		assert_bool(arrays[Mesh.ARRAY_COLOR]==reference[Mesh.ARRAY_COLOR]).override_failure_message(String(cluster.resource)+" colours").is_true()
	CivilizationSystem.revealed_areas.pop_back()
	CivilizationSystem.fog_revision+=1


func test_the_overlay_reuses_built_indications_until_the_chart_changes()->void:
	var world:=_world()
	var camera:=Camera3D.new();world.add_child(camera);world.camera=camera
	camera.size=8.0
	# Charted ground (an uncharted occurrence grows no rocks).
	CivilizationSystem._add_revealed_area(Vector2(world.world_start_position.x,world.world_start_position.z),20.0,"test")
	var cluster:={"resource":"Stone","visual_stage":"recognized","position":world.world_start_position}
	var first:MeshInstance3D=auto_free(world._resource_ground_indication(cluster))
	assert_bool(first.has_node("ExposedRockFaces")).is_true()
	var again:MeshInstance3D=auto_free(world._resource_ground_indication(cluster))
	assert_object(again).is_not_same(first)
	assert_object(again.mesh).is_same(first.mesh)
	assert_object(again.material_override).is_same(first.material_override)
	assert_bool(again.has_node("ExposedRockFaces")).is_true()
	assert_object((again.get_node("ExposedRockFaces") as MeshInstance3D).mesh).is_same((first.get_node("ExposedRockFaces") as MeshInstance3D).mesh)
	# Rocks under a pixel are left out of wide views (a separate entry).
	camera.size=84.375
	var wide:MeshInstance3D=auto_free(world._resource_ground_indication(cluster))
	assert_bool(wide.has_node("ExposedRockFaces")).is_false()
	assert_bool(wide.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]==first.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]).is_true()
	# Newly charted ground can change the indication: it is built afresh.
	camera.size=8.0
	CivilizationSystem.fog_revision+=1
	var recharted:MeshInstance3D=auto_free(world._resource_ground_indication(cluster))
	assert_object(recharted.mesh).is_not_same(first.mesh)
	CivilizationSystem.revealed_areas.pop_back()
	CivilizationSystem.fog_revision+=1

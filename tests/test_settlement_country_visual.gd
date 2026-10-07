extends GdUnitTestSuite
const Visual:=preload("res://scripts/settlement_country_visual.gd")
const Plan:=preload("res://scripts/settlement_country_plan.gd")

func _snapshot()->Dictionary:
	return {"owner":"player","origin":Vector2.ZERO,"population":120.0,
		"core_km":9.0,"worked_km":9.0,"realm_km":39.0,"stage":"settlement",
		"seed":157,"knowledge":[],"built_fabric":{},"road_tier":0,"founded":true,
		"deposits":[_wood("west",Vector3(-0.8,0,0.0)),_wood("east",Vector3(0.8,0,0.0))]}

func _wood(id:String,at:Vector3)->Dictionary:
	return {"id":id,"position":at,"resource":"Timber","landscape_source":"woodland_catchment",
		"stage":"accessible","initial_amount":100.0,"remaining":45.0,"workers":2,
		"distance_km":0.8,"haul_km":0.8,"lifetime_extracted":55.0}

func _visual():
	var visual=auto_free(Visual.new())
	visual.configure(func(_at:Vector2)->float:return 0.0,func(_at:Vector2)->bool:return true)
	return visual

func _flush(visual)->void:
	var guard:=0
	while int(visual.stats().pending)>0 and guard<100:
		visual.process_jobs(100000,8)
		guard+=1
	assert_int(int(visual.stats().pending)).is_equal(0)

func _organic_seed(count:int=3)->Dictionary:
	var plots:Array[Dictionary]=[]
	var routes:Array[Dictionary]=[]
	for index in count:
		var at:=Vector2(float(index)*0.04,0.0)
		plots.append({"id":index+1,"seed":177+index*31,"centroid":at,
			"polygon":PackedVector2Array([at+Vector2(-0.017,-0.020),at+Vector2(0.018,-0.019),at+Vector2(0.018,0.020),at+Vector2(-0.018,0.019)]),
			"frontage_route_id":index+1,"area_ha":0.14,"roof_coverage":0.30,
			"material_family":"organic","land_use":"residential_compound","form":"timber_household",
			"roof_plan":"timber_ridge","storeys":1,"condition":0.9,"status":"active","construction_progress":1.0})
		routes.append({"id":index+1,"active":true,"width_m":0.8,"points":PackedVector2Array([at+Vector2(-0.019,0),at+Vector2(0.021,0.005)])})
	return {"id":"organic_fixture","kind":"cluster","group":"homesteads","position":Vector2(40,60),
		"settlement_plots":plots,"settlement_routes":routes,"geometry_signature":count,"track_from":Vector2.ZERO}

func _seed_context()->Dictionary:
	return {"style":{},"road_tier":0}

func _request_seed(visual,record:Dictionary,key:String,signature:int)->void:
	var entries:Array[Dictionary]=[{"key":key,"signature":signature,"build":visual._build_patch.bind(record,_seed_context())}]
	visual.retained.request(entries)

func _seed_identities(plan:Dictionary)->Dictionary:
	var result:Dictionary={}
	for building:Dictionary in plan.buildings:
		result[building.id]=[building.position,building.angle,building.footprint,building.variant]
	return result

func test_organic_seed_uses_exact_root_parcel_solver_and_world_transforms()->void:
	var visual=_visual()
	var record:=_organic_seed()
	var before:=var_to_bytes(record)
	var root_plan:=preload("res://scripts/early_settlement_visual.gd").layout(record.settlement_plots,record.settlement_routes,func(_point:Vector2)->bool:return true)
	var drawn:Node3D=auto_free(Node3D.new())
	visual._build_patch(drawn,record,_seed_context())
	var seed_plan:Dictionary=drawn.get_meta("country_seed_plan")
	assert_int(seed_plan.buildings.size()).is_greater(0)
	assert_dict(_seed_identities(seed_plan)).is_equal(_seed_identities(root_plan))
	assert_array(var_to_bytes(record)).is_equal(before)
	var expected:Node3D=auto_free(Node3D.new())
	preload("res://scripts/early_settlement_visual.gd").render(root_plan,Vector3(40,0,60),func(_x:float,_z:float)->float:return 0.0,expected)
	var actual_transforms:Array=[];var expected_transforms:Array=[]
	for child:Node in drawn.get_children():
		if child.has_meta("source_transforms"):actual_transforms.append_array(child.get_meta("source_transforms"))
	for child:Node in expected.get_children():
		if child.has_meta("source_transforms"):expected_transforms.append_array(child.get_meta("source_transforms"))
	assert_array(actual_transforms).is_equal(expected_transforms)
	assert_bool(drawn.has_node("ScatteredHomes")).is_false()

func test_organic_seed_growth_keeps_existing_sites_and_reuses_unchanged_layout()->void:
	var visual=_visual()
	var first:Node3D=auto_free(Node3D.new())
	visual._build_patch(first,_organic_seed(2),_seed_context())
	var before:=_seed_identities(first.get_meta("country_seed_plan"))
	var steps:int=visual.seed_layout_steps
	var repeated:Node3D=auto_free(Node3D.new())
	visual._build_patch(repeated,_organic_seed(2),_seed_context())
	assert_int(visual.seed_layout_steps).is_equal(steps)
	var grown:Node3D=auto_free(Node3D.new())
	visual._build_patch(grown,_organic_seed(3),_seed_context())
	var after:=_seed_identities(grown.get_meta("country_seed_plan"))
	assert_int(after.size()).is_greater(before.size())
	assert_int(visual.seed_layout_steps).is_equal(steps+1)
	for id:String in before:assert_array(after.get(id,[])).is_equal(before[id])

func test_organic_layout_advances_one_parcel_and_keeps_old_patch_until_ready()->void:
	var visual=_visual()
	var record:=_organic_seed(2)
	_request_seed(visual,record,"organic",1)
	_flush(visual)
	var old_id:int=visual.retained.installed.organic.node.get_instance_id()
	var canopy_revision:int=visual.seed_ground_revision
	assert_int(visual.seed_ground_records().size()).is_equal(1)
	assert_int(visual.seed_ground_records()[0].plots.size()).is_equal(2)
	var steps:int=visual.seed_layout_steps
	record=_organic_seed(4)
	_request_seed(visual,record,"organic",2)
	visual.process_jobs(1,1)
	assert_int(visual.seed_layout_steps).is_equal(steps)
	visual.process_jobs(1,1)
	assert_int(visual.seed_layout_steps).is_equal(steps+1)
	assert_int(visual.retained.installed.organic.node.get_instance_id()).is_equal(old_id)
	assert_int(visual.seed_ground_revision).is_equal(canopy_revision)
	_flush(visual)
	assert_int(visual.seed_layout_steps).is_equal(steps+2)
	assert_int(visual.retained.installed.organic.node.get_instance_id()).is_not_equal(old_id)
	assert_int(visual.seed_ground_revision).is_greater(canopy_revision)
	assert_int(visual.seed_ground_records()[0].plots.size()).is_equal(4)

func test_seed_generation_is_incremental_and_keeps_previous_claims_private()->void:
	var visual=_visual()
	var record:={"id":"growing_seed","kind":"cluster","group":"homesteads","position":Vector2(40,60),"geometry_signature":3,
		"settlement_growth":{"seed":4177,"parcels":3,"templates":[{"form":"timber_household","roof_plan":"timber_ridge","material_family":"organic","storeys":1}],"obstacles":[]}}
	var source:=var_to_bytes(record)
	_request_seed(visual,record,"grown",3)
	visual.process_jobs(1,1)
	assert_int(visual.seed_growth_steps).is_equal(0)
	visual.process_jobs(1,1)
	assert_int(visual.seed_growth_steps).is_equal(1)
	assert_int(int(visual._job.growth.state.next)).is_equal(1)
	assert_int(visual.retained.installed.size()).is_equal(0)
	_flush(visual)
	assert_array(var_to_bytes(record)).is_equal(source)
	var before:Dictionary=visual._growth_states.growing_seed.duplicate(true)
	assert_int(before.plots.size()).is_greater(0)
	var homes:=_seed_identities(visual.retained.installed.grown.node.get_meta("country_seed_plan"))
	record.settlement_growth.parcels=5;record.geometry_signature=5
	_request_seed(visual,record,"grown",5)
	visual.process_jobs(1,1);visual.process_jobs(1,1)
	# Partial work cannot write through the retained growth state or its arrays.
	assert_dict(visual._growth_states.growing_seed).is_equal(before)
	_flush(visual)
	var after:Dictionary=visual._growth_states.growing_seed
	assert_int(int(after.next)).is_equal(5)
	for index in before.plots.size():assert_dict(after.plots[index]).is_equal(before.plots[index])
	for index in before.routes.size():assert_dict(after.routes[index]).is_equal(before.routes[index])
	var now:=_seed_identities(visual.retained.installed.grown.node.get_meta("country_seed_plan"))
	for id:String in homes:assert_array(now.get(id,[])).is_equal(homes[id])

func test_completed_seed_refreshes_canopy_revision_without_day_or_camera_change()->void:
	var layer=auto_free(preload("res://scripts/settlement_country_layer.gd").new())
	var visual=Visual.new();layer.add_child(visual)
	visual.configure(func(_point:Vector2)->float:return 0.0,func(_point:Vector2)->bool:return true)
	layer.layers={"player":{"node":visual}}
	_request_seed(visual,_organic_seed(2),"canopy_seed",1)
	var revision:int=layer.clearing_revision
	assert_int(layer.canopy_clearings(Vector2(40,60)).size()).is_equal(0)
	var guard:=0
	while not visual.retained.pending.is_empty() and guard<100:
		layer.process_jobs(100000,8);guard+=1
	assert_int(visual.retained.pending.size()).is_equal(0)
	assert_int(layer.clearing_revision).is_greater(revision)
	assert_int(layer.canopy_clearings(Vector2(40,60)).size()).is_equal(2)
	var stable:int=layer.clearing_revision
	for index in 4:layer.process_jobs(100000,8)
	assert_int(layer.clearing_revision).is_equal(stable)

func test_organic_seed_fog_clips_saved_footprints_without_changing_placement()->void:
	var visual=_visual()
	var record:=_organic_seed(3)
	var whole:Node3D=auto_free(Node3D.new())
	visual._build_patch(whole,record,_seed_context())
	var before:=_seed_identities(whole.get_meta("country_seed_plan"))
	var steps:int=visual.seed_layout_steps
	visual.configure(func(_at:Vector2)->float:return 0.0,func(_at:Vector2)->bool:return true,
		func(at:Vector2)->bool:return at.x<40.045,func(_at:Vector2)->bool:return true)
	var partial:Node3D=auto_free(Node3D.new())
	visual._build_patch(partial,record,_seed_context())
	var shown:Dictionary=partial.get_meta("country_seed_plan")
	assert_int(shown.buildings.size()).is_between(1,before.size()-1)
	assert_int(visual.seed_layout_steps).is_equal(steps)
	assert_bool(partial.get_meta("fog_clipped")).is_true()
	for building:Dictionary in shown.buildings:
		assert_array(_seed_identities(shown)[building.id]).is_equal(before[building.id])
		for corner:Vector2 in building.footprint:assert_float(corner.x+40.0).is_less(40.045)
	visual.configure(func(_at:Vector2)->float:return 0.0,func(_at:Vector2)->bool:return true)
	var revealed:Node3D=auto_free(Node3D.new())
	visual._build_patch(revealed,record,_seed_context())
	assert_dict(_seed_identities(revealed.get_meta("country_seed_plan"))).is_equal(before)
	assert_int(visual.seed_layout_steps).is_equal(steps)

func test_adjacent_organic_seeds_reserve_nonoverlapping_roof_footprints()->void:
	var visual=_visual()
	var footprints:Array=[]
	for side in 2:
		var origin:=Vector2(40.0+float(side)*0.08,60.0)
		var neighbour:=Vector2(0.08 if side==0 else -0.08,0.0)
		var record:={"id":"adjacent_"+str(side),"kind":"cluster","group":"homesteads","position":origin,
			"settlement_growth":{"seed":4177+side,"parcels":12,"neighbours":[neighbour],"templates":[{"form":"timber_household","roof_plan":"timber_ridge","material_family":"organic","storeys":1}],"obstacles":[]}}
		var parent:Node3D=auto_free(Node3D.new())
		visual._build_patch(parent,record,_seed_context())
		var plan:Dictionary=parent.get_meta("country_seed_plan")
		assert_int(plan.buildings.size()).is_greater(0)
		for building:Dictionary in plan.buildings:
			var world:=PackedVector2Array()
			for corner:Vector2 in building.footprint:
				assert_bool(preload("res://scripts/settlement_country_growth.gd").owns(record.settlement_growth,corner)).is_true()
				world.append(corner+origin)
			for previous:PackedVector2Array in footprints:assert_array(Geometry2D.intersect_polygons(world,previous)).is_empty()
			footprints.append(world)

func test_actual_root_growth_absorbs_overlapping_saved_roofs_without_rerolling()->void:
	var visual=_visual()
	var record:={"id":"absorbed_seed","kind":"cluster","group":"homesteads","position":Vector2(40,60),
		"settlement_growth":{"seed":4177,"parcels":12,"templates":[{"form":"timber_household","roof_plan":"timber_ridge","material_family":"organic","storeys":1}],"obstacles":[]}}
	var first:Node3D=auto_free(Node3D.new())
	visual._build_patch(first,record,_seed_context())
	var old_plan:Dictionary=first.get_meta("country_seed_plan")
	assert_int(old_plan.buildings.size()).is_greater(1)
	if old_plan.buildings.is_empty():return
	var before:=_seed_identities(old_plan)
	var absorbed:Dictionary=old_plan.buildings[0]
	var claim:=PackedVector2Array()
	# A small claimed polygon inside the roof proves exact polygon absorption,
	# not only nine sampled land points around the footprint.
	for corner:Vector2 in absorbed.footprint:claim.append(Vector2(absorbed.position).lerp(corner,0.25))
	record.settlement_growth.obstacles=[{"polygon":claim}]
	var steps:int=visual.seed_layout_steps
	var after:Node3D=auto_free(Node3D.new())
	visual._build_patch(after,record,_seed_context())
	var remaining:=_seed_identities(after.get_meta("country_seed_plan"))
	assert_int(remaining.size()).is_equal(before.size()-1)
	assert_bool(remaining.has(absorbed.id)).is_false()
	assert_int(visual.seed_layout_steps).is_equal(steps)
	for id:String in remaining:assert_array(remaining[id]).is_equal(before[id])
	record.settlement_growth.obstacles=[]
	var restored:Node3D=auto_free(Node3D.new())
	visual._build_patch(restored,record,_seed_context())
	assert_dict(_seed_identities(restored.get_meta("country_seed_plan"))).is_equal(before)
	assert_int(visual.seed_layout_steps).is_equal(steps)

func test_organic_seed_ground_stays_in_real_parcels_and_recorded_lanes()->void:
	var visual=_visual()
	var record:=_organic_seed(2)
	var parent:Node3D=auto_free(Node3D.new())
	visual._build_patch(parent,record,_seed_context())
	var ground:MeshInstance3D=parent.get_node("WorkedEarth")
	var arrays:Array=ground.mesh.surface_get_arrays(0)
	var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	assert_int(vertices.size()).is_greater(0)
	for vertex:Vector3 in vertices:
		var local:=Vector2(vertex.x,vertex.z)-Vector2(record.position)
		var inside:=false
		for plot:Dictionary in record.settlement_plots:
			if _parcel_bounds(plot.polygon).grow(0.00002).has_point(local):inside=true;break
		if not inside:
			for route:Dictionary in record.settlement_routes:
				for index in range(1,route.points.size()):
					if local.distance_to(Geometry2D.get_closest_point_to_segment(local,route.points[index-1],route.points[index]))<0.001:inside=true
		assert_bool(inside).override_failure_message("Ground must not invent a circular yard or long nearest-origin track").is_true()
		assert_float(vertex.y).is_less(0.0001)

func _parcel_bounds(polygon:PackedVector2Array)->Rect2:
	return preload("res://scripts/organic_town_visual.gd").bounds(polygon)

func test_daily_idle_keeps_retained_meshes_without_new_builds()->void:
	var visual=_visual()
	var snapshot:=_snapshot()
	visual.request(snapshot);_flush(visual)
	var before:Dictionary=visual.stats()
	var started:=Time.get_ticks_usec()
	for day in 365:visual.request(snapshot)
	var elapsed:=Time.get_ticks_usec()-started
	var after:Dictionary=visual.stats()
	assert_int(after.requests).is_equal(1)
	assert_int(after.builds).is_equal(before.builds)
	assert_dict(after.keys).is_equal(before.keys)
	print("COUNTRY_IDLE_2_SITES_USEC_PER_DAY=%.2f" % (float(elapsed)/365.0))

func test_one_depleted_site_replaces_only_that_patch_when_ready()->void:
	var visual=_visual()
	var snapshot:=_snapshot()
	visual.request(snapshot);_flush(visual)
	var before:Dictionary=visual.stats().keys
	snapshot.deposits[1].remaining=0.0;snapshot.deposits[1].workers=0
	visual.request(snapshot)
	var pending:Dictionary=visual.stats()
	assert_int(pending.pending).is_equal(1)
	assert_int(pending.keys["sites:site:player:east"].node_id).is_equal(before["sites:site:player:east"].node_id)
	_flush(visual)
	var after:Dictionary=visual.stats().keys
	assert_int(after["sites:site:player:west"].node_id).is_equal(before["sites:site:player:west"].node_id)
	assert_int(after["sites:site:player:east"].node_id).is_not_equal(before["sites:site:player:east"].node_id)

func test_daily_resource_amounts_do_not_rebuild_drawings_or_mutate_ledger()->void:
	var visual=_visual()
	var snapshot:=_snapshot()
	var original:=snapshot.duplicate(true)
	visual.request(snapshot);_flush(visual)
	assert_dict(snapshot).is_equal(original)
	var before:Dictionary=visual.stats().keys
	snapshot.deposits[1].remaining=44.99;snapshot.deposits[1].workers=3
	visual.request(snapshot)
	assert_int(visual.stats().pending).is_equal(0)
	assert_dict(visual.stats().keys).is_equal(before)
	# A coarser amount bucket may trigger plan inspection, but the visible
	# site is still thinned woodland, so its mesh remains attached.
	snapshot.deposits[1].remaining=31.0
	visual.request(snapshot)
	assert_int(visual.stats().pending).is_equal(0)
	assert_dict(visual.stats().keys).is_equal(before)

func test_regrowing_wood_updates_its_patch_without_touching_other_work()->void:
	var visual=_visual()
	var snapshot:=_snapshot()
	snapshot.deposits[0].remaining=0.0;snapshot.deposits[0].workers=0
	visual.request(snapshot);_flush(visual)
	var before:Dictionary=visual.stats().keys
	snapshot.deposits[0].remaining=18.0
	visual.request(snapshot)
	assert_int(visual.stats().pending).is_equal(1)
	_flush(visual)
	var after:Dictionary=visual.stats().keys
	assert_int(after["sites:site:player:west"].node_id).is_not_equal(before["sites:site:player:west"].node_id)
	assert_int(after["sites:site:player:east"].node_id).is_equal(before["sites:site:player:east"].node_id)

func test_hidden_work_places_have_no_mesh_even_when_real_deposits_exist()->void:
	var visual=auto_free(Visual.new())
	visual.configure(func(_at:Vector2)->float:return 0.0,func(at:Vector2)->bool:return at.x<0)
	visual.request(_snapshot());_flush(visual)
	var keys:Dictionary=visual.stats().keys
	var west:Node=instance_from_id(keys["sites:site:player:west"].node_id)
	var east:Node=instance_from_id(keys["sites:site:player:east"].node_id)
	assert_int(west.get_child_count()).is_greater(0)
	assert_int(east.get_child_count()).is_equal(0)

func test_surface_invalidation_rebuilds_draping_without_state_edits()->void:
	var visual=_visual()
	var snapshot:=_snapshot()
	var before_data:=snapshot.duplicate(true)
	visual.request(snapshot);_flush(visual)
	var before:Dictionary=visual.stats().keys
	visual.invalidate(true)
	visual.request(snapshot)
	assert_int(visual.stats().pending).is_equal(2)
	_flush(visual)
	var after:Dictionary=visual.stats().keys
	assert_int(after["sites:site:player:west"].node_id).is_not_equal(before["sites:site:player:west"].node_id)
	assert_dict(snapshot).is_equal(before_data)

func test_partial_reveal_refreshes_clipped_patch_when_center_remains_visible()->void:
	var cover:={"wide":false}
	var revealed:=func(at:Vector2)->bool:return at.x<0.15 or bool(cover.wide)
	var visual=auto_free(Visual.new())
	visual.configure(func(_at:Vector2)->float:return 0.0,revealed,revealed)
	var snapshot:=_snapshot()
	snapshot.deposits=[_wood("center",Vector3.ZERO)]
	visual.request(snapshot);_flush(visual)
	var before:Dictionary=visual.stats().keys
	cover.wide=true
	visual.invalidate(false)
	visual.request(snapshot)
	assert_int(visual.stats().pending).is_equal(1)
	_flush(visual)
	assert_int(visual.stats().keys["sites:site:player:center"].node_id).is_not_equal(before["sites:site:player:center"].node_id)

func test_unavailable_house_slots_are_skipped_without_stacking_at_the_center()->void:
	var at:=Vector2(10,10)
	var placed:Array[Vector2]=[]
	var visual=auto_free(Visual.new())
	visual.configure(func(point:Vector2)->float:placed.append(point);return 0.0,func(point:Vector2)->bool:return point.distance_to(at)<0.001)
	var root:Node3D=auto_free(Node3D.new())
	visual._add_homes(root,at,3,317,{"known":[],"style":{},"fabric":{}})
	assert_bool(placed.is_empty()).is_true()
	assert_int(root.get_meta("country_home_count")).is_equal(0)
	assert_int(root.get_child_count()).is_equal(0)

func test_shared_house_kits_keep_metre_scale_in_world_kilometres()->void:
	var visual=_visual()
	var contexts:Array=[
		{"known":[],"style":{},"fabric":{"homes":[1.0,0.0,0.0,0.0,0.0]}},
		{"known":["framed_construction"],"style":{},"fabric":{"homes":[0.0,0.0,1.0,0.0,0.0]}},
		{"known":["dry_stone_walls"],"style":{},"fabric":{"homes":[0.0,0.0,0.0,0.0,1.0]}},
		{"known":[],"style":{"kinds":["house_medium"]},"fabric":{}},
	]
	for context:Dictionary in contexts:
		var root:Node3D=auto_free(Node3D.new())
		visual._add_homes(root,Vector2(40,60),2,157,context)
		var homes:MultiMeshInstance3D=root.get_node("ScatteredHomes")
		var bounds:AABB=homes.multimesh.mesh.get_aabb()
		assert_float(bounds.size.length()).is_greater(1.0)
		var transforms:Array=homes.get_meta("source_transforms",[])
		assert_int(transforms.size()).is_equal(2)
		for transform:Transform3D in transforms:
			# Small hand-built variations still stay around the shared .001
			# metre-to-kilometre conversion, never a kilometre-wide dwelling.
			var scale:=transform.basis.get_scale().abs()
			for component:float in [scale.x,scale.y,scale.z]:
				assert_bool(component>0.0007 and component<0.0012).is_true()
			var world_bounds:AABB=transform*bounds
			assert_float(world_bounds.size.length()).is_less(0.05)

func test_completed_late_country_homes_use_recorded_low_rise_kit_and_bounded_props()->void:
	var visual=_visual()
	var era=preload("res://scripts/settlement_country_era.gd")
	var plot:={"id":11,"land_use":"mixed_household","status":"active","fabric_generation":12,"storeys":10,"material_family":"stone","roof_plan":"concrete_roof"}
	var appearance:Dictionary=era.capture([],{},[plot])
	var root:Node3D=auto_free(Node3D.new())
	visual._add_homes(root,Vector2(40,60),3,157,{"country_appearance":era.render_profile(appearance),"style":{}})
	var homes:MultiMeshInstance3D=root.get_node("ScatteredHomes")
	var descriptor:Dictionary=homes.get_meta("country_home")
	assert_str(descriptor.kind).is_equal("modern_villa")
	assert_int(descriptor.storeys).is_equal(2)
	assert_str(descriptor.material).is_equal("stone|slab")
	assert_int(homes.multimesh.instance_count).is_equal(3)
	var props:=0
	for child:Node in root.get_children():
		if child.has_meta("country_prop"):props+=1
	assert_int(props).is_equal(3)
	for transform:Transform3D in homes.get_meta("source_transforms"):
		assert_float((transform*homes.multimesh.mesh.get_aabb()).size.length()).is_less(0.025)

func test_cluster_slots_stay_compact_separated_and_stable_as_roofs_fill_in()->void:
	for seed_value in range(100,140):
		var at:=Vector2(14034,-2892)
		var full:=Visual._cluster_home_slots(at,12,seed_value)
		assert_int(full.size()).is_equal(12)
		for count in [4,6,9,12]:
			var partial:=Visual._cluster_home_slots(at,count,seed_value)
			for index in count:assert_vector(partial[index]).is_equal(full[index])
		for index in full.size():
			assert_float(full[index].distance_to(at)).is_less(0.065)
			for other in range(index):assert_float(full[index].distance_to(full[other])).is_greater(0.016)

func test_clusters_render_six_to_twelve_roofs_with_fixed_transforms_and_three_props()->void:
	var visual=_visual()
	var era=preload("res://scripts/settlement_country_era.gd")
	var appearance:Dictionary=era.capture([],{},[{"id":9,"land_use":"mixed_household","status":"active","fabric_generation":12,"storeys":8}])
	var context:={"country_appearance":era.render_profile(appearance),"style":{}}
	var prior:Dictionary={}
	for count in [4,6,12]:
		var root:Node3D=auto_free(Node3D.new())
		visual._add_homes(root,Vector2(40,60),count,157,context)
		assert_int(root.get_meta("country_home_count")).is_equal(count)
		var groups:=0;var props:=0;var rendered:=0
		var now:Dictionary={}
		for child:Node in root.get_children():
			if child.has_meta("country_prop"):props+=1
			if not child.has_meta("country_home"):continue
			groups+=1;rendered+=(child as MultiMeshInstance3D).multimesh.instance_count
			var slots:Array=child.get_meta("country_home_slots")
			var transforms:Array=child.get_meta("source_transforms")
			for index in slots.size():now[slots[index]]={"transform":transforms[index],"descriptor":child.get_meta("country_home")}
		assert_int(rendered).is_equal(count)
		assert_int(groups).is_less_equal(3)
		assert_int(props).is_equal(3)
		for slot in prior:assert_dict(now[slot]).is_equal(prior[slot])
		prior=now

func test_shoreline_leaves_holes_in_cluster_without_moving_dry_homes()->void:
	var at:=Vector2(40,60)
	var visual=auto_free(Visual.new())
	visual.configure(func(_point:Vector2)->float:return 0.0,func(point:Vector2)->bool:return point.x>=at.x)
	var root:Node3D=auto_free(Node3D.new())
	visual._add_homes(root,at,12,157,{"style":{},"known":[],"fabric":{}})
	var kept:Array=root.get_meta("country_home_positions")
	var all_slots:=Visual._cluster_home_slots(at,12,157)
	assert_int(kept.size()).is_greater(0)
	assert_int(kept.size()).is_less(12)
	for point:Vector2 in kept:
		assert_bool(point in all_slots).is_true()
		assert_float(point.x).is_greater_equal(at.x)
		assert_float(point.distance_to(at)).is_greater(0.01)

func test_herders_have_local_grazing_tracks_even_in_a_wide_realm()->void:
	var visual=_visual()
	var snapshot:=_snapshot()
	snapshot.population=25000.0;snapshot.core_km=24.0
	snapshot.worked_km=120.0;snapshot.realm_km=2000.0;snapshot.deposits=[]
	visual.request(snapshot)
	var count:=0
	for key:String in visual.retained.desired:
		if not key.begins_with("herders:"):continue
		var request:Dictionary=visual.retained.desired[key]
		var bound:Array=(request.build as Callable).get_bound_arguments()
		var record:Dictionary=bound[0]
		var distance:float=(record.position as Vector2).distance_to(record.track_from)
		assert_bool(distance>0.1 and distance<=2.0001).is_true()
		count+=1
	assert_int(count).is_greater(0)

func test_bounded_country_planning_cost_reports_real_scan_size()->void:
	var snapshot:=_snapshot()
	snapshot.population=25000.0;snapshot.core_km=24.0;snapshot.worked_km=120.0
	snapshot.deposits=[]
	for index in 480:snapshot.deposits.append(_wood(str(index),Vector3(float(index%24)*3,0,float(index/24)*3)))
	var started:=Time.get_ticks_usec()
	for iteration in 100:Plan.signature(snapshot)
	var signatures:=Time.get_ticks_usec()-started
	started=Time.get_ticks_usec()
	for iteration in 10:Plan.build(snapshot)
	var builds:=Time.get_ticks_usec()-started
	print("COUNTRY_480_DEPOSITS_SIGNATURE_USEC=%.2f BUILD_USEC=%.2f" % [float(signatures)/100.0,float(builds)/10.0])

func test_compact_farm_ground_does_not_veil_the_house_walls()->void:
	var visual=_visual()
	var root:Node3D=auto_free(Node3D.new())
	var record:={"id":"farm:repair","position":Vector2(40,60),"group":"homesteads","kind":"homestead","field_radius_km":0.14,"rotation":0.3,"buildings":2,"track_from":Vector2(39.8,60)}
	visual._build_patch(root,record,{"known":[],"style":{},"fabric":{},"road_tier":0})
	var ground:MeshInstance3D=root.get_node("WorkedEarth")
	var vertices:PackedVector3Array=ground.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var highest:=0.0
	for point:Vector3 in vertices:highest=maxf(highest,point.y)
	var homes:MultiMeshInstance3D=root.get_node("ScatteredHomes")
	for transform:Transform3D in homes.get_meta("source_transforms"):
		assert_float(highest).is_less(transform.origin.y)
		assert_float(Vector2(transform.origin.x,transform.origin.z).distance_to(record.position)).is_less(0.025)
	assert_object(root.get_node_or_null("SettlementGroundShadows/FarmhouseShadow")).is_not_null()
	assert_object(root.get_node_or_null("Farm_woodpile")).is_not_null()
	assert_object(root.get_node_or_null("CountryChart_field")).is_not_null()
	var layout:Dictionary=root.get_meta("country_layout")
	assert_int(layout.fields.size()).is_equal(4)
	assert_float(layout.envelope_radius_km).is_less_equal(0.18)

func test_off_view_ground_can_be_empty_without_a_null_surface_cast()->void:
	var visual=_visual()
	visual.ground_grid=Vector4(0,0,1,9)
	var root:Node3D=auto_free(Node3D.new())
	var record:={"id":"farm:outside","position":Vector2(40,60),"group":"homesteads","kind":"homestead","field_radius_km":0.14,"rotation":0.3,"buildings":1,"track_from":Vector2(39.8,60)}
	visual._build_patch(root,record,{"known":[],"style":{},"fabric":{},"road_tier":0})
	assert_object(root.get_node_or_null("WorkedEarth")).is_null()
	assert_object(root.get_node_or_null("ScatteredHomes")).is_not_null()
	assert_object(root.get_node_or_null("CountryChart_field")).is_not_null()
	assert_int(visual.drape_budget_skips).is_equal(0)

func test_incremental_ground_keeps_old_patch_until_complete_and_matches_sync_geometry()->void:
	var snapshot:=_snapshot();snapshot.deposits=[_wood("center",Vector3.ZERO)]
	var visual=_visual();visual.ground_grid=Vector4(0,0,3,65)
	visual.request(snapshot);_flush(visual)
	var key:="sites:site:player:center"
	var old_id:int=visual.stats().keys[key].node_id
	visual.invalidate(true);visual.request(snapshot)
	visual.process_jobs(1,1)
	assert_int(visual.stats().pending).is_equal(1)
	assert_int(visual.stats().keys[key].node_id).is_equal(old_id)
	assert_str(visual.stats().preparing).is_equal(key)
	assert_object(visual._job.node.get_node_or_null("WorkedEarth")).is_null()
	# A one-microsecond budget advances one bounded operation; it cannot drain
	# the whole patch behind the retained renderer's nominal frame budget.
	visual.process_jobs(1,1)
	assert_int(visual.stats().keys[key].node_id).is_equal(old_id)
	_flush(visual)
	var actual:MeshInstance3D=instance_from_id(visual.stats().keys[key].node_id).get_node("WorkedEarth")
	var synchronous=_visual();synchronous.ground_grid=visual.ground_grid
	var expected_root:Node3D=auto_free(Node3D.new())
	var arguments:Array=visual.retained.desired[key].build.get_bound_arguments()
	synchronous._build_patch(expected_root,arguments[0],arguments[1])
	var expected:MeshInstance3D=expected_root.get_node("WorkedEarth")
	var actual_arrays:Array=actual.mesh.surface_get_arrays(0)
	var expected_arrays:Array=expected.mesh.surface_get_arrays(0)
	assert_array(actual_arrays[Mesh.ARRAY_VERTEX]).is_equal(expected_arrays[Mesh.ARRAY_VERTEX])
	assert_array(actual_arrays[Mesh.ARRAY_COLOR]).is_equal(expected_arrays[Mesh.ARRAY_COLOR])
	assert_int(visual.drape_budget_skips).is_equal(0)

func test_obsolete_partial_patch_is_discarded_before_new_facts_install()->void:
	var visual=_visual();visual.ground_grid=Vector4(0,0,3,65)
	var snapshot:=_snapshot();snapshot.deposits=[_wood("center",Vector3.ZERO)]
	visual.request(snapshot);visual.process_jobs(1,1)
	var stale:Node=visual._job.node
	var stale_signature:int=visual._job.signature
	snapshot.deposits[0].remaining=0.0;snapshot.deposits[0].workers=0
	visual.request(snapshot);visual.process_jobs(1,1)
	assert_bool(is_instance_valid(stale)).is_false()
	assert_int(visual._job.signature).is_not_equal(stale_signature)
	assert_int(visual.stats().installed).is_equal(0)
	_flush(visual)
	assert_int(visual.stats().installed).is_equal(1)
	assert_int(visual.stats().prepared_patches).is_equal(1)

func test_camera_priority_changes_pending_order_without_invalidating_finished_meshes()->void:
	var visual=_visual();var snapshot:=_snapshot()
	visual.view_center=Vector2(-1,0);visual.request(snapshot)
	assert_str(visual.retained.pending[0]).is_equal("sites:site:player:west")
	visual.view_center=Vector2(1,0);visual.request(snapshot)
	assert_str(visual.retained.pending[0]).is_equal("sites:site:player:east")
	_flush(visual)
	var before:Dictionary=visual.stats().keys
	visual.view_center=Vector2(-1,0);visual.request(snapshot)
	assert_int(visual.stats().pending).is_equal(0)
	assert_dict(visual.stats().keys).is_equal(before)

func test_reveal_change_restarts_a_clipped_incomplete_replacement()->void:
	var cover:={"wide":false}
	var revealed:=func(at:Vector2)->bool:return at.x<0.15 or bool(cover.wide)
	var visual=auto_free(Visual.new());visual.ground_grid=Vector4(0,0,3,65)
	visual.configure(func(_at:Vector2)->float:return 0.0,revealed,revealed)
	var snapshot:=_snapshot();snapshot.deposits=[_wood("center",Vector3.ZERO)]
	visual.request(snapshot)
	var steps:=0
	while not visual._fog_clipped and steps<2000:
		visual.process_jobs(1,1);steps+=1
	assert_bool(visual._fog_clipped).is_true()
	assert_bool(visual._job.is_empty()).is_false()
	var stale:Node=visual._job.node
	cover.wide=true;visual.invalidate(false);visual.request(snapshot)
	visual.process_jobs(1,1)
	assert_bool(is_instance_valid(stale)).is_false()
	_flush(visual)
	var finished:Node=instance_from_id(visual.stats().keys["sites:site:player:center"].node_id)
	assert_bool(finished.get_meta("fog_clipped")).is_false()

func test_quarry_catchments_do_not_become_hundred_metre_ribbons()->void:
	var visual:Node3D=auto_free(Visual.new())
	visual.configure(func(_point:Vector2)->float:return 0.0)
	visual._collecting=true
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	visual._draw_site(surface,{"position":Vector2.ZERO,"resource":"Stone","age":"worked_quarry","radius_km":0.72,"tile_area_km2":9.0},44)
	assert_int(visual._commands.size()).is_greater(0)
	for triangle:Array in visual._commands:
		for index in 3:
			assert_float((triangle[index] as Vector2).distance_to(triangle[(index+1)%3])).is_less(0.16)

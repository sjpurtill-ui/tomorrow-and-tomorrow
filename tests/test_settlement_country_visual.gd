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

func test_hut_offsets_stay_on_admitted_land_beside_a_shoreline()->void:
	var at:=Vector2(10,10)
	var placed:Array[Vector2]=[]
	var visual=auto_free(Visual.new())
	visual.configure(func(point:Vector2)->float:placed.append(point);return 0.0,func(point:Vector2)->bool:return point.distance_to(at)<0.001)
	var root:Node3D=auto_free(Node3D.new())
	visual._add_homes(root,at,3,317,{"known":[],"style":{},"fabric":{}})
	# The dummy headless RenderingServer does not retain MultiMesh transform
	# readback. Height samples are the exact final positions sent to transforms.
	assert_bool(placed.is_empty()).is_false()
	for point:Vector2 in placed:
		assert_bool(point.distance_to(at)<0.001).is_true()

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

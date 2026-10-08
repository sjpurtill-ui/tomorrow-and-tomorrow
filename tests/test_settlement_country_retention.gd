extends GdUnitTestSuite
const Visual:=preload("res://scripts/settlement_country_visual.gd")
const Growth:=preload("res://scripts/settlement_country_growth.gd")

func _snapshot(people:float=11500.0)->Dictionary:
	var fabric:={"claims":[],"templates":[{"form":"portable_shelter_cluster","roof_plan":"ridge_light_shelter","material_family":"organic","storeys":1}]}
	return {"owner":"player","origin":Vector2(40,60),"population":people,
		"core_km":9.0,"worked_km":9.0,"realm_km":9.0,"stage":"town","seed":157,
		"founded":true,"knowledge":[],"built_fabric":{},"road_tier":0,"deposits":[],
		"root_fabric":fabric,"root_geometry_signature":hash(fabric)}

func _visual():
	var visual=auto_free(Visual.new())
	visual.configure(func(_point:Vector2)->float:return 0.0,func(_point:Vector2)->bool:return true)
	visual.view_center=Vector2(40,60)
	return visual

func _build_only(visual,key:String)->void:
	# The real request admits every seed. Preparing only this known affected key
	# keeps the regression focused instead of drawing the whole country fixture.
	visual.retained.pending.assign([key])
	for step in 100:
		visual.process_jobs(100000,1)
		if not visual.retained.pending.has(key):break
	assert_bool(visual.retained.pending.has(key)).is_false()
	assert_bool(visual.retained.installed.has(key)).is_true()

func _roof_positions(plan:Dictionary)->Dictionary:
	var result:Dictionary={}
	for record:Dictionary in plan.buildings:
		result[String(record.id)]=[record.position,record.angle,record.footprint,record.variant]
	return result

func test_population_dip_and_rebound_keep_established_seed_visible_and_roofs_in_place()->void:
	var visual=_visual();var snapshot:=_snapshot()
	var seed_id:="seed:player:157:9"
	var patch_id:="homesteads:"+seed_id
	visual.request(snapshot)
	assert_bool(visual.retained.desired.has(patch_id)).is_true()
	_build_only(visual,patch_id)
	var before:Dictionary=visual._growth_states[seed_id].duplicate(true)
	var layout:Dictionary=visual._seed_layouts[seed_id].duplicate(true)
	var roofs:=_roof_positions(visual.retained.installed[patch_id].node.get_meta("country_seed_plan"))
	assert_dict(roofs).is_not_empty()
	# The sampling allowance becomes nine below about11,211 people. This is
	# not an actual abandonment event for the ten already built neighborhoods.
	snapshot.population=10000.0
	visual.request(snapshot)
	assert_bool(visual.retained.desired.has(patch_id)).is_true()
	assert_bool(visual.retained.installed[patch_id].node.visible).is_true()
	assert_dict(visual._growth_states.get(seed_id,{})).is_equal(before)
	assert_dict(visual._seed_layouts.get(seed_id,{})).is_equal(layout)
	# A later craft/form change is for newly built claims, not a license to
	# regenerate the temporarily inactive seed's whole inherited neighborhood.
	snapshot.root_fabric.templates=[{"form":"earthen_household","roof_plan":"round_thatch","material_family":"earth","storeys":1}]
	snapshot.root_geometry_signature=hash(snapshot.root_fabric)
	snapshot.population=11500.0
	var source_before:=var_to_bytes(snapshot)
	visual.request(snapshot)
	_build_only(visual,patch_id)
	var after:Dictionary=visual._growth_states[seed_id]
	assert_array(after.plots).is_equal(before.plots)
	assert_array(after.routes).is_equal(before.routes)
	assert_dict(_roof_positions(visual.retained.installed[patch_id].node.get_meta("country_seed_plan"))).is_equal(roofs)
	assert_array(var_to_bytes(snapshot)).is_equal(source_before)
	# Persistence must still respect real root claims. Absorb one roof while
	# retaining all nonoverlapping saved sites and the underlying parcel history.
	var offset:=Vector2.ZERO
	for record:Dictionary in visual.plan.homesteads:
		if String(record.id)==seed_id:offset=record.offset;break
	var roof:Array=roofs.values()[0]
	var occupied:=PackedVector2Array()
	for point:Vector2 in roof[2]:occupied.append(point+offset)
	snapshot.root_fabric.claims=[{"centroid":Vector2(roof[0])+offset,"polygon":occupied}]
	snapshot.root_geometry_signature=hash(snapshot.root_fabric)
	snapshot.population=10000.0
	visual.request(snapshot)
	_build_only(visual,patch_id)
	var remaining:=_roof_positions(visual.retained.installed[patch_id].node.get_meta("country_seed_plan"))
	assert_int(remaining.size()).is_less(roofs.size())
	for id:String in remaining:assert_array(remaining[id]).is_equal(roofs[id])
	assert_array(visual._growth_states[seed_id].plots).is_equal(before.plots)

func test_population_loss_retains_at_most_the_fixed_twenty_four_seed_histories()->void:
	var visual=_visual();var snapshot:=_snapshot(1000000.0)
	visual.request(snapshot)
	var ids:Array[String]=[]
	for record:Dictionary in visual.plan.homesteads:
		if not record.has("settlement_growth"):continue
		var id:=String(record.id);ids.append(id)
		visual._growth_states[id]=Growth.begin(record)
		visual._seed_layouts[id]={"plots":[],"plan":{"buildings":[],"replaced":{}}}
	assert_int(ids.size()).is_equal(Growth.MAX_SEEDS)
	snapshot.population=120.0
	visual.request(snapshot)
	assert_dict(visual.retained.desired).is_empty()
	assert_int(visual._growth_states.size()).is_equal(Growth.MAX_SEEDS)
	assert_int(visual._seed_layouts.size()).is_equal(Growth.MAX_SEEDS)
	# Defensive pruning also bounds stale cached data from an obsolete seed ID.
	visual._growth_states["obsolete_seed"]={"plots":[]}
	visual._seed_layouts["obsolete_seed"]={"plots":[]}
	snapshot.population=1000000.0
	visual.request(snapshot)
	assert_int(visual._growth_states.size()).is_equal(Growth.MAX_SEEDS)
	assert_int(visual._seed_layouts.size()).is_equal(Growth.MAX_SEEDS)
	for id:String in ids:
		assert_bool(visual._growth_states.has(id)).is_true()
		assert_bool(visual._seed_layouts.has(id)).is_true()

func test_unbuilt_population_candidates_are_not_promoted_to_established_seeds()->void:
	var visual=_visual();var snapshot:=_snapshot()
	var patch_id:="homesteads:seed:player:157:9"
	visual.request(snapshot)
	assert_bool(visual.retained.desired.has(patch_id)).is_true()
	assert_bool(visual.retained.installed.has(patch_id)).is_false()
	snapshot.population=10000.0
	visual.request(snapshot)
	assert_bool(visual.retained.desired.has(patch_id)).is_false()
	assert_dict(visual._established_seeds).is_empty()

func test_owner_world_seed_origin_or_unfounded_change_drops_unrelated_retained_histories()->void:
	for changed:String in ["owner","seed","origin","founded"]:
		var visual=_visual();var snapshot:=_snapshot()
		visual.request(snapshot)
		# This remains an active ID after an origin change; unlike a population
		# dip, changing the actual settlement identity must not reuse local claims.
		var id:="seed:player:157:0"
		visual._growth_states[id]={"plots":[],"marker":"previous identity"}
		visual._seed_layouts[id]={"plots":[],"marker":"previous identity"}
		visual._established_seeds[id]={"marker":"previous identity"}
		visual._seed_ground_keys[id]=71
		var revision:int=visual.seed_ground_revision
		match changed:
			"owner":snapshot.owner="rival"
			"seed":snapshot.seed=158
			"origin":snapshot.origin=Vector2(60,40)
			"founded":snapshot.founded=false
		visual.request(snapshot)
		assert_dict(visual._growth_states).is_empty()
		assert_dict(visual._seed_layouts).is_empty()
		assert_dict(visual._established_seeds).is_empty()
		assert_dict(visual._seed_ground_keys).is_empty()
		assert_int(visual.seed_ground_revision).is_greater(revision)

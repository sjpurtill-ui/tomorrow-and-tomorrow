extends GdUnitTestSuite
## Country presentation cannot change people, sites or the worked reach.
const Plan:=preload("res://scripts/settlement_country_plan.gd")
const OneSeat:=preload("res://scripts/one_seat.gd")
const Growth:=preload("res://scripts/settlement_country_growth.gd")

func _snapshot(people:float=4000.0,core:float=15.0,worked:float=90.0)->Dictionary:
	return {"owner":"player","origin":Vector2(19.0,-41.0),"population":people,
		"core_km":core,"worked_km":worked,"realm_km":300.0,"stage":"town",
		"seed":47183,"founded":true,"knowledge":["thatched_roofing"],
		"built_fabric":{"homes":[0.0,1.0,0.0,0.0,0.0]},"road_tier":0,"deposits":[]}

func _deposit(id:String,source:String,remaining:float,workers:int=0)->Dictionary:
	return {"id":id,"resource":"Timber","landscape_source":source,
		"position":Vector3(22.0,0.0,-39.0),"distance_km":3.6,"haul_km":3.6,
		"remaining":remaining,"initial_amount":100.0,"workers":workers,
		"stage":"accessible","lifetime_extracted":100.0-remaining}

func test_under_four_hundred_people_keep_only_the_root_settlement()->void:
	var data:=_snapshot(120.0,9.0,18.0)
	var plan:=Plan.build(data)
	assert_int(plan.homesteads.size()).is_equal(0)
	assert_int(plan.herders.size()).is_equal(0)
	# Even when the current engine computes wider worked reach, presentation
	# does not falsify it to enforce the under-400 visual rule.
	assert_float(float(plan.rings.core_km)).is_equal(9.0)
	assert_float(float(plan.rings.worked_km)).is_equal(18.0)

func test_plan_is_deterministic_and_does_not_write_into_source()->void:
	var data:=_snapshot()
	data.deposits=[_deposit("wood","woodland_catchment",40.0,2)]
	data.country_appearance=preload("res://scripts/settlement_country_era.gd").capture(data.knowledge,data.built_fabric)
	var before:=data.duplicate(true)
	var first:=Plan.build(data)
	var second:=Plan.build(data)
	assert_dict(data).is_equal(before)
	assert_dict(first).is_equal(second)
	assert_bool(first.sites.is_empty()).is_false()
	first.sites[0].workers=900
	first.built_fabric.homes[1]=0.0
	first.country_appearance.homes[1]=0.0
	assert_dict(data).is_equal(before)

func test_far_holdings_stand_outside_dense_buildings_inside_worked_land_and_herders_beyond()->void:
	var data:=_snapshot()
	var plan:=Plan.build(data)
	assert_bool(plan.homesteads.is_empty()).is_false()
	for record:Dictionary in plan.homesteads:
		var distance:float=(record.position as Vector2).distance_to(data.origin)
		assert_float(distance).is_less(90.0)
		if record.kind=="cluster":continue # Persistent seed parcels can join root fabric.
		assert_float(distance).is_greater(float(plan.visual_core_km))
		assert_str(record.location_class).is_equal("worked_core" if distance<=15.0 else "homestead_band")
		assert_bool(float(record.field_radius_km)>=0.10 and float(record.field_radius_km)<=0.18).is_true()
	for record:Dictionary in plan.herders:
		var distance:float=(record.position as Vector2).distance_to(data.origin)
		assert_bool(distance>90.0 and distance<300.0).is_true()

func test_more_people_fill_same_band_without_relocating_old_homes()->void:
	var data:=_snapshot(1000.0,12.0,90.0)
	data.dense_radius_km=0.5
	var sparse:=Plan.build(data)
	data.population=4000.0
	var full:=Plan.build(data)
	assert_bool(full.homesteads.size()>sparse.homesteads.size()).is_true()
	var later:={}
	for record:Dictionary in full.homesteads:later[String(record.id)]=record.position
	for record:Dictionary in sparse.homesteads:
		assert_bool(later.has(String(record.id))).is_true()
		assert_vector(record.position).is_equal(later[String(record.id)])

func test_growth_never_moves_a_surviving_representative()->void:
	var earlier:=Plan.build(_snapshot(4000.0,15.0,90.0))
	var later:=Plan.build(_snapshot(8000.0,15.0,120.0))
	var previous:={}
	for record:Dictionary in earlier.homesteads:previous[String(record.id)]=record.position
	var shared:=0
	for record:Dictionary in later.homesteads:
		if previous.has(String(record.id)):
			shared+=1
			assert_vector(record.position).is_equal(previous[String(record.id)])
	assert_bool(shared>0).is_true()

func test_household_layout_is_stable_and_keeps_the_source_record_unchanged()->void:
	var record:Dictionary={"id":"farm_layout","kind":"homestead","position":Vector2(14034,-2892),"field_radius_km":0.14}
	var before:=record.duplicate(true)
	var layout:=Plan.homestead_layout(record)
	assert_dict(record).is_equal(before)
	assert_dict(Plan.homestead_layout(record)).is_equal(layout)
	assert_vector(layout.yard_center).is_equal(record.position)
	assert_float(layout.yard_radius_km).is_equal(0.025)
	assert_int(layout.fields.size()).is_equal(4)
	record["population"]=25000.0;record["day"]=120000
	assert_dict(Plan.homestead_layout(record)).is_equal(layout)

func test_compact_field_slots_leave_the_yard_and_neighbours_clear()->void:
	# Planetary coordinates also exercise metre-scale float precision.
	for index in 160:
		var record:={"id":"layout_%d" % index,"kind":"homestead","position":Vector2(14034,-2892),"field_radius_km":lerpf(0.10,0.18,float(index)/159.0)}
		var layout:=Plan.homestead_layout(record)
		for field:Dictionary in layout.fields:
			var along:=Vector2.from_angle(float(field.angle))
			var across:=along.orthogonal()
			assert_float(float(field.half_length_km)).is_between(0.025,0.071)
			assert_float(float(field.half_width_km)).is_between(0.012,0.035)
			assert_float((field.center as Vector2).distance_to(layout.yard_center)-float(field.half_width_km)).is_greater(float(layout.yard_radius_km)+0.008)
			for long_sign in [-1,1]:
				for cross_sign in [-1,1]:
					var corner:Vector2=field.center+along*float(field.half_length_km)*long_sign+across*float(field.half_width_km)*cross_sign
					assert_float(corner.distance_to(layout.yard_center)).is_less_equal(float(layout.envelope_radius_km)+0.001)
		for first in layout.fields.size():
			for second in range(first+1,layout.fields.size()):
				assert_bool(_field_slots_separated(layout.fields[first],layout.fields[second],0.005)).is_true()

func _field_slots_separated(first:Dictionary,second:Dictionary,gap:float)->bool:
	var first_along:=Vector2.from_angle(float(first.angle));var first_across:=first_along.orthogonal()
	var second_along:=Vector2.from_angle(float(second.angle));var second_across:=second_along.orthogonal()
	var distance:Vector2=second.center-first.center
	for axis:Vector2 in [first_along,first_across,second_along,second_across]:
		var first_radius:=absf(axis.dot(first_along))*float(first.half_length_km)+absf(axis.dot(first_across))*float(first.half_width_km)
		var second_radius:=absf(axis.dot(second_along))*float(second.half_length_km)+absf(axis.dot(second_across))*float(second.half_width_km)
		if absf(distance.dot(axis))>first_radius+second_radius+gap:return true
	return false

func test_herder_has_only_one_smaller_plot_and_yard()->void:
	var record:={"id":"herd_small","kind":"herder","position":Vector2(18,-5),"field_radius_km":0.07}
	var layout:=Plan.homestead_layout(record)
	assert_int(layout.fields.size()).is_equal(1)
	assert_float(layout.yard_radius_km).is_equal(0.014)
	assert_float(layout.envelope_radius_km).is_equal(0.07)
	assert_float(float(layout.fields[0].half_length_km)).is_less(0.033)

func test_density_follows_people_per_band_area()->void:
	var near:=Plan.build(_snapshot(4000.0,15.0,45.0))
	var wide:=Plan.build(_snapshot(4000.0,15.0,120.0))
	var near_density:=float(near.homesteads.size())/float(near.holdings_area_km2)
	var wide_density:=float(wide.homesteads.size())/float(wide.holdings_area_km2)
	assert_bool(near_density>wide_density).is_true()
	assert_float(float(near.rings.density)).is_equal_approx(4000.0/(PI*(45.0*45.0-15.0*15.0)),0.000001)
	assert_float(float(near.holdings_density)).is_equal_approx(4000.0/float(near.holdings_area_km2),0.000001)

func test_representative_density_thins_toward_the_edge()->void:
	var data:=_snapshot(25000.0,24.0,120.0)
	var plan:=Plan.build(data)
	var inner:=0
	var outer:=0
	for record:Dictionary in plan.homesteads:
		if float(record.distance_km)<72.0:inner+=1
		else:outer+=1
	var inner_density:=float(inner)/(72.0*72.0-float(plan.visual_core_km)*float(plan.visual_core_km))
	var outer_density:=float(outer)/(120.0*120.0-72.0*72.0)
	assert_bool(inner_density>outer_density).is_true()

func test_counts_stay_bounded_with_millions_of_people_and_many_sites()->void:
	var data:=_snapshot(2000000.0,30.0,120.0)
	for index in 400:
		data.deposits.append(_deposit(str(index),"woodland_catchment",40.0,2))
	var plan:=Plan.build(data)
	assert_bool(plan.homesteads.size()<=Plan.MAX_HOMESTEADS).is_true()
	assert_bool(plan.herders.size()<=Plan.MAX_HERDERS).is_true()
	assert_int(plan.sites.size()).is_equal(Plan.MAX_SITES)
	assert_int(plan.homesteads.size()+plan.herders.size()+plan.sites.size()).is_less_equal(250)

func test_work_history_distinguishes_cut_ground_regrowth_and_quarry_scars()->void:
	assert_str(Plan.site_state(_deposit("cut","woodland_catchment",1.0)).age).is_equal("cut_over")
	assert_str(Plan.site_state(_deposit("young","woodland_catchment",20.0)).age).is_equal("young_wood")
	assert_str(Plan.site_state(_deposit("active","woodland_catchment",40.0,2)).age).is_equal("thinned")
	assert_str(Plan.site_state(_deposit("virgin","woodland_catchment",100.0)).category).is_equal("resting")
	var stone:=_deposit("scar","surface_stone_catchment",0.0)
	stone.resource="Stone"
	assert_str(Plan.site_state(stone).age).is_equal("spent_quarry")

func test_sites_come_only_from_worked_real_surface_or_search_records()->void:
	var data:=_snapshot()
	var ore:=_deposit("ore","",70.0,1)
	ore.found_by="searchers";ore.resource="Copper Ore";ore.position=Vector3(83,0,-12)
	var hidden:=_deposit("hidden","woodland_catchment",100.0)
	hidden.stage="unseen"
	data.deposits=[ore,hidden,_deposit("not_surface","",60.0,1)]
	var plan:=Plan.build(data)
	assert_int(plan.sites.size()).is_equal(1)
	assert_str(plan.sites[0].deposit_id).is_equal("ore")
	assert_vector(plan.sites[0].position).is_equal(Vector2(83,-12))

func test_site_signature_ignores_daily_amounts_but_detects_visible_change()->void:
	var data:=_snapshot()
	var wood:=_deposit("wood","woodland_catchment",40.0,2)
	data.deposits=[wood]
	var first:=Plan.signature(data)
	wood.remaining=39.9;wood.workers=3
	assert_int(Plan.signature(data)).is_equal(first)
	wood.remaining=0.0;wood.workers=0
	assert_int(Plan.signature(data)).is_not_equal(first)
	var depleted:=Plan.signature(data)
	wood.remaining=20.0
	assert_int(Plan.signature(data)).is_not_equal(depleted)

func test_small_population_changes_retain_plan_until_meaningful_growth()->void:
	var data:=_snapshot()
	var key:=Plan.quick_signature(data)
	data.population=4000.01
	assert_int(Plan.quick_signature(data)).is_equal(key)
	data.population=4500.0
	assert_int(Plan.quick_signature(data)).is_not_equal(key)
	data=_snapshot(399.99)
	key=Plan.quick_signature(data)
	data.population=400.0
	assert_int(Plan.quick_signature(data)).is_not_equal(key)

func test_retained_fabric_key_changes_at_the_same_five_percent_as_drawn_homes()->void:
	var data:=_snapshot()
	data.built_fabric.homes=[0.0,0.66,0.34,0.0,0.0]
	var before:=Plan.quick_signature(data)
	data.built_fabric.homes=[0.0,0.64,0.36,0.0,0.0]
	assert_int(Plan.quick_signature(data)).is_equal(before)
	data.built_fabric.homes=[0.0,0.68,0.32,0.0,0.0]
	assert_int(Plan.quick_signature(data)).is_not_equal(before)

func test_same_scope_api_reads_rival_core_only_without_inventing_worked_land()->void:
	var previous=WorldSimulation.state
	var owner:=WorldSimulation.actor_id
	var rival=auto_free(GameState.get_script().new())
	rival.population_exact=4000.0
	rival.population_total=4000
	rival.world_seed=57
	rival.settlement_site_committed=true
	rival.settlement_founded_at=Vector3(310,0,900)
	rival.settlement_nuclei.assign([{"active":true},{"active":true}])
	rival.settlement_plots.assign([{"polygon":PackedVector2Array([Vector2(8,0),Vector2(7,1),Vector2(7,-1)])}])
	rival.resource_deposits.assign([_deposit("their_wood","woodland_catchment",40.0,2)])
	var before_plots:Array=rival.settlement_plots.duplicate(true)
	WorldSimulation.state=rival
	WorldSimulation.actor_id="country_plan_test"
	var snapshot:=Plan.capture_current({"center":Vector2(310,900),"reach":300.0})
	var engine_core:=OneSeat.core_km()
	var engine_worked:=OneSeat.reach_km()
	WorldSimulation.state=previous
	WorldSimulation.actor_id=owner
	assert_array(rival.settlement_plots).is_equal(before_plots)
	var plan:=Plan.build(snapshot)
	assert_float(float(snapshot.population)).is_equal(4000.0)
	assert_float(float(snapshot.core_km)).is_equal(engine_core)
	assert_float(float(snapshot.worked_km)).is_equal(engine_worked)
	assert_float(engine_worked).is_equal(engine_core)
	assert_float(float(snapshot.dense_radius_km)).is_equal_approx(8.4,0.000001)
	assert_int(plan.homesteads.size()).is_greater(0)
	for record:Dictionary in plan.homesteads:
		assert_str(record.location_class).is_equal("worked_core")
		assert_float(float(record.distance_km)).is_less(engine_worked)
		if record.kind!="cluster":assert_float(float(record.distance_km)).is_greater(8.4)
	assert_int(plan.sites.size()).is_equal(1)

func test_million_person_core_keeps_worked_holdings_outside_actual_built_extent()->void:
	var data:=_snapshot(1369000.0,120.0,120.0)
	var plan:=Plan.build(data)
	var dense:=preload("res://scripts/settlement_visual_extent.gd").radius(1369000)
	assert_float(float(plan.visual_core_km)).is_equal_approx(dense,0.000001)
	assert_float(float(plan.rings.core_km)).is_equal(120.0)
	assert_float(float(plan.rings.worked_km)).is_equal(120.0)
	assert_float(float(plan.rings.band_area_km2)).is_equal(0.0)
	assert_int(plan.homesteads.size()).is_between(1,Plan.MAX_HOMESTEADS)
	for record:Dictionary in plan.homesteads:
		if record.kind!="cluster":assert_float(float(record.distance_km)).is_greater(dense)
		assert_float(float(record.distance_km)).is_less(120.0)
		assert_str(record.location_class).is_equal("worked_core")

func test_carrier_core_growth_reclassifies_holdings_without_removing_or_moving_them()->void:
	var data:=_snapshot(25000.0,15.0,120.0)
	data.dense_radius_km=3.0
	var before:=Plan.build(data)
	data.core_km=120.0
	var after:=Plan.build(data)
	assert_int(after.homesteads.size()).is_equal(before.homesteads.size())
	for index in before.homesteads.size():
		assert_str(after.homesteads[index].id).is_equal(before.homesteads[index].id)
		assert_vector(after.homesteads[index].position).is_equal(before.homesteads[index].position)
		assert_str(after.homesteads[index].location_class).is_equal("worked_core")

func test_dense_extent_filters_far_holdings_but_never_absorbs_organic_seeds()->void:
	var data:=_snapshot(25000.0,120.0,120.0)
	data.dense_radius_km=3.0
	var before:=Plan.build(data)
	var far:Array=(before.homesteads as Array).filter(func(record:Dictionary)->bool:return record.kind!="cluster")
	assert_array(far).is_not_empty()
	if far.is_empty():return
	# Put a sampled far holding inside the new dense diagnostic extent instead
	# of depending on a random farm happening to fall inside a fixed 25km disc.
	var absorbing_radius:=maxf(25.0,float(far[0].distance_km)+0.01)
	data.dense_radius_km=absorbing_radius
	var after:=Plan.build(data)
	var surviving:={}
	for record:Dictionary in after.homesteads:
		if record.kind!="cluster":assert_float(float(record.distance_km)).is_greater(absorbing_radius)
		surviving[record.id]=record
	var absorbed:=0
	var seeds:=0
	for record:Dictionary in before.homesteads:
		if record.kind!="cluster" and float(record.distance_km)<=absorbing_radius:
			assert_bool(surviving.has(record.id)).is_false();absorbed+=1
		else:
			assert_bool(surviving.has(record.id)).is_true()
			assert_vector(surviving[record.id].position).is_equal(record.position)
			if record.kind=="cluster":seeds+=1
	assert_int(absorbed).is_greater(0)
	assert_int(seeds).is_greater(0)
	data.dense_radius_km=120.0
	var fully_dense:=Plan.build(data)
	assert_int(fully_dense.homesteads.size()).is_equal(seeds)
	for record:Dictionary in fully_dense.homesteads:
		assert_str(record.kind).is_equal("cluster")
		assert_vector(record.position).is_equal(surviving[record.id].position)

func test_dense_extent_uses_the_same_recorded_polygon_radius_rule()->void:
	assert_float(Plan.dense_radius(4000,5.0)).is_equal_approx(5.25,0.000001)
	assert_float(Plan.dense_radius(1369000,5.0)).is_equal_approx(preload("res://scripts/settlement_visual_extent.gd").radius(1369000),0.000001)
	assert_float(Plan.dense_radius(0)).is_equal(0.12)
	assert_float(Plan.dense_radius(2000000000,400.0)).is_equal(340.0)

func test_dense_extent_key_is_bounded_to_twenty_five_metre_steps()->void:
	var data:=_snapshot()
	data.dense_radius_km=3.001
	var key:=Plan.quick_signature(data)
	data.dense_radius_km=3.020
	assert_int(Plan.quick_signature(data)).is_equal(key)
	data.dense_radius_km=3.026
	assert_int(Plan.quick_signature(data)).is_not_equal(key)

func test_completed_appearance_changes_key_but_profile_diagnostics_do_not()->void:
	var data:=_snapshot()
	data.country_appearance=preload("res://scripts/settlement_country_era.gd").capture(data.knowledge,data.built_fabric)
	var key:=Plan.quick_signature(data)
	data.country_appearance.completed_residential=1000
	data.country_appearance.sampled_plots=2048
	assert_int(Plan.quick_signature(data)).is_equal(key)
	data.country_appearance.variants=[{"kit":"late","kind":"masonry_villa","storeys":2,"features":0,"material":"stone|tile","weight":20}]
	data.country_appearance.late_share=0.25
	assert_int(Plan.quick_signature(data)).is_not_equal(key)

func test_seed_specs_use_bounded_shared_parcel_growth_instead_of_compounds()->void:
	var data:=_snapshot(25000.0,24.0,120.0)
	data.dense_radius_km=1.0
	var plan:=Plan.build(data)
	var seeds:=0
	for record:Dictionary in plan.homesteads:
		if record.kind!="cluster":continue
		seeds+=1
		assert_bool(record.has("settlement_growth")).is_true()
		var spec:Dictionary=record.settlement_growth
		assert_int(int(spec.parcels)).is_between(6,24)
		assert_bool(spec.has("seed")).is_true()
		assert_bool(spec.get("templates",[]) is Array).is_true()
		assert_float(float(record.distance_km)).is_less(120.0)
	assert_int(seeds).is_between(2,24)

func test_seed_centres_and_parcels_grow_without_rerolling_existing_sites()->void:
	var data:=_snapshot(1000.0,12.0,90.0)
	data.dense_radius_km=1.0
	var before:=Plan.build(data)
	data.population=25000.0
	var after:=Plan.build(data)
	var later:Dictionary={}
	for record:Dictionary in after.homesteads:later[record.id]=record
	var shared:=0
	for record:Dictionary in before.homesteads:
		if record.kind!="cluster":continue
		shared+=1
		assert_bool(later.has(record.id)).is_true()
		assert_vector(later[record.id].position).is_equal(record.position)
		assert_int(int(later[record.id].settlement_growth.seed)).is_equal(int(record.settlement_growth.seed))
		assert_int(int(later[record.id].settlement_growth.parcels)).is_greater(int(record.settlement_growth.parcels))
	assert_int(shared).is_greater_equal(2)

func _seed_records(plan:Dictionary)->Array:
	return (plan.homesteads as Array).filter(func(record:Dictionary)->bool:return record.kind=="cluster")

func test_actual_root_claims_become_local_obstacles_without_moving_seed_centres()->void:
	var data:=_snapshot(4000.0,15.0,90.0)
	var earlier:=_seed_records(Plan.build(data))
	assert_array(earlier).is_not_empty()
	if earlier.is_empty():return
	var selected:Dictionary=earlier[0]
	var center:Vector2=selected.offset
	var polygon:=PackedVector2Array([center+Vector2(-.025,-.02),center+Vector2(.025,-.02),center+Vector2(.025,.02),center+Vector2(-.025,.02)])
	data.root_fabric={"claims":[{"centroid":center,"polygon":polygon},{"centroid":Vector2(4,0),"polygon":PackedVector2Array([Vector2(3.9,0),Vector2(4.1,0),Vector2(4,.1)])}],"templates":[]}
	data.root_geometry_signature=hash(data.root_fabric)
	var source:=data.duplicate(true)
	var later:=_seed_records(Plan.build(data))
	assert_int(later.size()).is_equal(earlier.size())
	for index in earlier.size():
		assert_str(later[index].id).is_equal(earlier[index].id)
		assert_vector(later[index].position).is_equal(earlier[index].position)
	var obstacles:Array=later[0].settlement_growth.obstacles
	assert_int(obstacles.size()).is_equal(1)
	assert_vector(obstacles[0].centroid).is_equal(Vector2.ZERO)
	for index in polygon.size():
		assert_vector(obstacles[0].polygon[index]).is_equal(polygon[index]-center)
	# Grow through the same root selector against the actual occupied claim.
	var state:=Growth.begin(later[0])
	for step in Growth.MAX_PARCELS:Growth.advance(state,Callable(),Callable())
	assert_array(state.plots).is_not_empty()
	for plot:Dictionary in state.plots:
		assert_bool(Geometry2D.is_point_in_polygon(plot.centroid,obstacles[0].polygon)).is_false()
	assert_dict(data).is_equal(source)

func test_seed_specs_own_their_copied_fabric_and_obstacles()->void:
	var data:=_snapshot()
	data.root_fabric={"claims":[{"centroid":Vector2.ZERO,"polygon":PackedVector2Array([Vector2(-.03,-.03),Vector2(.03,-.03),Vector2(.03,.03),Vector2(-.03,.03)])}],
		"templates":[{"form":"durable_household_cluster","material_family":"organic","material_mix":{"Timber":.8}}]}
	data.root_geometry_signature=hash(data.root_fabric)
	var before:=data.duplicate(true)
	var seeds:=_seed_records(Plan.build(data))
	assert_array(seeds).is_not_empty()
	if seeds.is_empty():return
	var spec:Dictionary=seeds[0].settlement_growth
	spec.templates[0].material_mix.Timber=0.0
	if not spec.obstacles.is_empty():spec.obstacles[0].polygon[0]=Vector2(900,900)
	assert_dict(data).is_equal(before)

func test_root_fabric_captures_only_occupied_claims_and_completed_forms()->void:
	var polygon:=PackedVector2Array([Vector2(-.01,-.01),Vector2(.01,-.01),Vector2(.01,.01),Vector2(-.01,.01)])
	var plots:Array=[]
	for item:Dictionary in [{"land_use":"residential_compound","construction_progress":1.0,"form":"durable_household_cluster"},
		{"land_use":"residential_compound","construction_progress":.3,"form":"unfinished"},
		{"land_use":"field","construction_progress":1.0,"form":"field"},
		{"land_use":"residential_compound","construction_progress":1.0,"form":"ruin","status":"ruin"}]:
		item.merge({"centroid":Vector2.ZERO,"polygon":polygon.duplicate(),"material_family":"organic"})
		plots.append(item)
	var before:=plots.duplicate(true)
	var fabric:=Plan._root_fabric(plots)
	assert_int(fabric.claims.size()).is_equal(2)
	assert_int(fabric.templates.size()).is_equal(1)
	assert_str(fabric.templates[0].form).is_equal("durable_household_cluster")
	fabric.claims[0].polygon[0]=Vector2(100,100)
	assert_array(plots).is_equal(before)

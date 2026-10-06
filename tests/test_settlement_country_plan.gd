extends GdUnitTestSuite
## Country presentation cannot change people, sites or the worked reach.
const Plan:=preload("res://scripts/settlement_country_plan.gd")
const OneSeat:=preload("res://scripts/one_seat.gd")

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

func test_young_people_keep_one_cluster_without_country_homes()->void:
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
	var before:=data.duplicate(true)
	var first:=Plan.build(data)
	var second:=Plan.build(data)
	assert_dict(data).is_equal(before)
	assert_dict(first).is_equal(second)
	assert_bool(first.sites.is_empty()).is_false()
	first.sites[0].workers=900
	first.built_fabric.homes[1]=0.0
	assert_dict(data).is_equal(before)

func test_homes_stand_only_between_engine_rings_and_herders_beyond()->void:
	var data:=_snapshot()
	var plan:=Plan.build(data)
	assert_bool(plan.homesteads.is_empty()).is_false()
	for record:Dictionary in plan.homesteads:
		var distance:float=(record.position as Vector2).distance_to(data.origin)
		assert_bool(distance>15.0 and distance<90.0).is_true()
		assert_bool(float(record.field_radius_km)>=0.15 and float(record.field_radius_km)<=0.9).is_true()
	for record:Dictionary in plan.herders:
		var distance:float=(record.position as Vector2).distance_to(data.origin)
		assert_bool(distance>90.0 and distance<300.0).is_true()

func test_more_people_fill_same_band_without_relocating_old_homes()->void:
	var sparse:=Plan.build(_snapshot(1000.0,12.0,90.0))
	var full:=Plan.build(_snapshot(4000.0,12.0,90.0))
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

func test_density_follows_people_per_band_area()->void:
	var near:=Plan.build(_snapshot(4000.0,15.0,45.0))
	var wide:=Plan.build(_snapshot(4000.0,15.0,120.0))
	var near_density:=float(near.homesteads.size())/float(near.rings.band_area_km2)
	var wide_density:=float(wide.homesteads.size())/float(wide.rings.band_area_km2)
	assert_bool(near_density>wide_density).is_true()
	assert_float(float(near.rings.density)).is_equal_approx(4000.0/(PI*(45.0*45.0-15.0*15.0)),0.000001)

func test_representative_density_thins_toward_the_edge()->void:
	var data:=_snapshot(25000.0,24.0,120.0)
	var plan:=Plan.build(data)
	var inner:=0
	var outer:=0
	for record:Dictionary in plan.homesteads:
		if float(record.distance_km)<72.0:inner+=1
		else:outer+=1
	var inner_density:=float(inner)/(72.0*72.0-24.0*24.0)
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

func test_retained_fabric_key_changes_at_the_same_tenth_as_drawn_homes()->void:
	var data:=_snapshot()
	data.built_fabric.homes=[0.0,0.66,0.34,0.0,0.0]
	var before:=Plan.quick_signature(data)
	data.built_fabric.homes=[0.0,0.64,0.36,0.0,0.0]
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
	rival.resource_deposits.assign([_deposit("their_wood","woodland_catchment",40.0,2)])
	WorldSimulation.state=rival
	WorldSimulation.actor_id="country_plan_test"
	var snapshot:=Plan.capture_current({"center":Vector2(310,900),"reach":300.0})
	var engine_core:=OneSeat.core_km()
	var engine_worked:=OneSeat.reach_km()
	WorldSimulation.state=previous
	WorldSimulation.actor_id=owner
	var plan:=Plan.build(snapshot)
	assert_float(float(snapshot.population)).is_equal(4000.0)
	assert_float(float(snapshot.core_km)).is_equal(engine_core)
	assert_float(float(snapshot.worked_km)).is_equal(engine_worked)
	assert_float(engine_worked).is_equal(engine_core)
	assert_int(plan.homesteads.size()).is_equal(0)
	assert_int(plan.sites.size()).is_equal(1)

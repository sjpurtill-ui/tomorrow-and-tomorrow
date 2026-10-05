extends GdUnitTestSuite

const MODEL:=preload("res://scripts/settlement_model.gd")
var model:Node
var was_processing:bool

func before_test()->void:
	was_processing=CivilizationSystem.is_processing()
	CivilizationSystem.set_process(false)
	model=auto_free(MODEL.new())
	_reset(772241)

func after_test()->void:
	GameState.elapsed_days=0.0
	CivilizationSystem.set_process(was_processing)

func _reset(seed:int)->void:
	GameState.reset_for_new_world(seed)
	GameState.settlement_founded_at=Vector3.ZERO
	GameState.settlement_plots.clear()
	GameState.settlement_routes.clear()
	GameState.next_settlement_plot_id=1
	GameState.population_allocations["Food"]=864
	GameState.resource_deposits=[_soil()]
	model._field_geometry_repair_attempts.clear()

func _soil()->Dictionary:
	return {"id":"soil","resource":"Fertile Soil","stage":"surveyed","position":Vector3(1.0,0.0,0.4)}

func _flat()->Dictionary:
	return {"settlement_origin":Vector3.ZERO,"buildable_land_at":func(_x:float,_z:float)->bool:return true,"terrain_height_at":func(_x:float,_z:float)->float:return 0.0,"river_distance_at":func(_x:float,_z:float)->float:return INF}

func _grow(count:int,context:Dictionary)->Array[Dictionary]:
	var fields:Array[Dictionary]=[]
	for index in count:
		var plot:Dictionary=model._create_field_plot(index*30,_soil(),index,context)
		if plot.is_empty():break
		GameState.settlement_plots.append(plot)
		fields.append(plot)
	return fields

func _elongation(plots:Array[Dictionary])->float:
	var center:=Vector2.ZERO
	for plot in plots:center+=Vector2(plot.centroid)
	center/=maxi(1,plots.size())
	var xx:=0.0
	var yy:=0.0
	var xy:=0.0
	for plot in plots:
		var delta:=Vector2(plot.centroid)-center
		xx+=delta.x*delta.x;yy+=delta.y*delta.y;xy+=delta.x*delta.y
	var difference:=sqrt(pow(xx-yy,2)+4.0*xy*xy)
	return sqrt((xx+yy+difference)/maxf(0.0000001,xx+yy-difference))

func _assert_disjoint(plots:Array[Dictionary])->void:
	for index in plots.size():
		for other in range(index+1,plots.size()):
			assert_array(Geometry2D.intersect_polygons(plots[index].polygon,plots[other].polygon)).override_failure_message("fields %d/%d overlap" % [index,other]).is_empty()

func test_growth_forms_compact_patches_instead_of_a_fertile_bearing_chain()->void:
	for seed in [772241,92287,410004]:
		_reset(seed)
		var fields:=_grow(36,_flat())
		assert_int(fields.size()).is_equal(36)
		assert_float(_elongation(fields)).is_less(2.8)
		var patches:Dictionary={}
		var patch_centers:PackedVector2Array=model._field_patch_centers(Vector2(1.0,0.4).normalized())
		var maximum:=0.0
		var infilled:=0
		for plot in fields:
			maximum=maxf(maximum,Vector2(plot.centroid).length())
			patches[model._nearest_field_patch(plot.centroid,patch_centers)]=true
			var neighbours:=0
			for other in fields:
				if other!=plot and Vector2(plot.centroid).distance_to(Vector2(other.centroid))<0.075:neighbours+=1
			if neighbours>=3:infilled+=1
		assert_int(patches.size()).is_greater_equal(3)
		assert_float(maximum).is_less(0.30)
		assert_int(infilled).is_greater_equal(24)
		_assert_disjoint(fields)

func test_new_fields_have_varied_nonrectangular_boundaries_and_are_deterministic()->void:
	var first:=_grow(20,_flat()).duplicate(true)
	var sizes:Dictionary={}
	for plot in first:
		var polygon:PackedVector2Array=plot.polygon
		assert_int(polygon.size()).is_between(5,7)
		assert_int(Geometry2D.triangulate_polygon(polygon).size()).is_greater(0)
		sizes[polygon.size()]=true
	assert_int(sizes.size()).is_greater_equal(2)
	_reset(772241)
	var second:=_grow(20,_flat())
	assert_array(second).is_equal(first)
	# More work does not regenerate or relocate existing parcels.
	var prior:=GameState.settlement_plots.duplicate(true)
	_grow(4,_flat())
	assert_array(GameState.settlement_plots.slice(0,prior.size())).is_equal(prior)

func test_full_polygon_rejects_bad_edges_interiors_water_and_local_cliffs()->void:
	var polygon:=PackedVector2Array([Vector2(-.02,-.02),Vector2(.02,-.02),Vector2(.02,.02),Vector2(-.02,.02)])
	var context:=_flat()
	# Its centre is sound; the east edge is not.
	context.buildable_land_at=func(x:float,_z:float)->bool:return x<.014
	assert_bool(model._field_footprint_buildable(polygon,context)).is_false()
	# A small interior lake also misses the centre and every corner.
	context.buildable_land_at=func(x:float,z:float)->bool:return Vector2(x,z).distance_to(Vector2(.012,.012))>.006
	assert_bool(model._field_footprint_buildable(polygon,context)).is_false()
	context=_flat()
	context.river_distance_at=func(x:float,_z:float)->float:return .010 if x>.014 else .1
	assert_bool(model._field_footprint_buildable(polygon,context)).is_false()
	context=_flat()
	context.terrain_height_at=func(x:float,_z:float)->float:return maxf(0.0,x-.012)*.8
	assert_bool(model._field_footprint_buildable(polygon,context)).is_false()

func test_growth_finds_suitable_side_of_river_and_avoids_inherited_homes()->void:
	var house:={"id":500,"land_use":"residential_compound","centroid":Vector2(.12,0.0),"polygon":PackedVector2Array([Vector2(.075,-.03),Vector2(.16,-.03),Vector2(.16,.035),Vector2(.075,.035)])}
	GameState.settlement_plots.append(house)
	var context:=_flat()
	context.buildable_land_at=func(_x:float,z:float)->bool:return z<.015
	var fields:=_grow(18,context)
	assert_int(fields.size()).is_equal(18)
	for plot in fields:
		for point in plot.polygon:assert_float(point.y).is_less(.015)
		assert_array(Geometry2D.intersect_polygons(plot.polygon,house.polygon)).is_empty()
	_assert_disjoint(fields)

func _legacy_chain(count:int)->Array[Dictionary]:
	var fields:Array[Dictionary]=[]
	for index in count:
		var id:=index+1
		var center:=Vector2(.12+index*.031,.03+index*.002)
		var polygon:=PackedVector2Array([center+Vector2(-.013,-.008),center+Vector2(.013,-.008),center+Vector2(.013,.008),center+Vector2(-.013,.008)])
		var plot:={"id":id,"seed":hash("%d:settlement_field:%d" % [GameState.world_seed,id]),"land_use":"field","form":"hand_cultivated_clearance","status":"active","polygon":polygon,"centroid":center,"area_ha":model._polygon_area_km2(polygon)*100.0,"frontage_route_id":id,"crop_family":"grain","cultivation_phase":"growing","crop_cover":.55,"worker_count":8,"worker_capacity":12,"condition":.61,"created_day":30*index}
		fields.append(plot)
		GameState.settlement_plots.append(plot)
		GameState.settlement_routes.append({"id":id,"kind":"field_track","points":PackedVector2Array([center,Vector2.ZERO if index==0 else Vector2(fields[index-1].centroid)]),"width_m":.72,"condition":.8,"created_day":30*index,"active":true})
	GameState.next_settlement_plot_id=count+1
	return fields

func test_legacy_chain_repair_preserves_ledger_area_ids_and_routes_then_stays_fixed()->void:
	var fields:=_legacy_chain(24)
	var before:=fields.duplicate(true)
	var routes_before:=GameState.settlement_routes.duplicate(true)
	var history_before:=GameState.settlement_plot_history.duplicate(true)
	var count:int=model._repair_legacy_field_geometry(_flat())
	assert_int(count).is_equal(24)
	assert_float(_elongation(fields)).is_less(2.8)
	for index in fields.size():
		var plot:=fields[index].duplicate(true)
		for key in ["polygon","centroid","field_geometry_version"]:plot.erase(key)
		var prior:Dictionary=before[index].duplicate(true)
		prior.erase("polygon");prior.erase("centroid")
		assert_dict(plot).is_equal(prior)
		assert_float(model._polygon_area_km2(fields[index].polygon)*100.0).is_equal_approx(float(fields[index].area_ha),.000001)
		var route:Dictionary=GameState.settlement_routes[index].duplicate(true)
		assert_vector(route.points[0]).is_equal(fields[index].centroid)
		route.erase("points")
		var prior_route:Dictionary=routes_before[index].duplicate(true)
		prior_route.erase("points")
		assert_dict(route).is_equal(prior_route)
	_assert_disjoint(fields)
	assert_array(GameState.settlement_plot_history).is_equal(history_before)
	assert_int(GameState.next_settlement_plot_id).is_equal(25)
	var after:=fields.duplicate(true)
	var revision:=GameState.morphology_revision
	assert_int(model._repair_legacy_field_geometry(_flat())).is_equal(0)
	assert_array(fields).is_equal(after)
	assert_int(GameState.morphology_revision).is_equal(revision)

func test_repair_runs_before_idle_month_gate_even_when_field_target_already_reached()->void:
	var fields:=_legacy_chain(12)
	GameState.population_allocations["Food"]=144
	GameState.elapsed_days=60.0
	GameState.last_morphology_day=60
	GameState.settlement_morphology={"classification":"hamlet"}
	model.process_local_month(_flat())
	assert_int(GameState.settlement_plots.size()).is_equal(12)
	assert_int(GameState.next_settlement_plot_id).is_equal(13)
	for plot in fields:assert_int(int(plot.get("field_geometry_version",0))).is_equal(2)
	var after:=fields.duplicate(true)
	model.process_local_month(_flat())
	assert_array(fields).is_equal(after)

func test_failed_repair_is_atomic_and_does_not_retry_fresh_callbacks_in_same_month()->void:
	_legacy_chain(12)
	var before:=GameState.settlement_plots.duplicate(true)
	var routes:=GameState.settlement_routes.duplicate(true)
	var invalid:=_flat()
	invalid.buildable_land_at=func(_x:float,_z:float)->bool:return false
	assert_int(model._repair_legacy_field_geometry(invalid)).is_equal(0)
	assert_array(GameState.settlement_plots).is_equal(before)
	assert_array(GameState.settlement_routes).is_equal(routes)
	# A fresh context closure cannot cause the expensive migration every frame.
	assert_int(model._repair_legacy_field_geometry(_flat())).is_equal(0)
	GameState.elapsed_days=30.0
	assert_int(model._repair_legacy_field_geometry(_flat())).is_equal(12)

func test_pinning_propagates_from_manual_field_track_and_keeps_archaeology_fixed()->void:
	var fields:=_legacy_chain(4)
	# The last holding was authored rather than generated. Its inherited track
	# ends at field three, recursively pinning the whole connected old chain.
	fields[3]["form"]="authored_field"
	var before:=fields.duplicate(true)
	var routes:=GameState.settlement_routes.duplicate(true)
	assert_int(model._repair_legacy_field_geometry(_flat())).is_equal(0)
	assert_array(fields).is_equal(before)
	assert_array(GameState.settlement_routes).is_equal(routes)
	_reset(772241)
	fields=_legacy_chain(2)
	fields[0]["status"]="ruin"
	fields[1]["status"]="reclaimed"
	before=fields.duplicate(true)
	assert_int(model._repair_legacy_field_geometry(_flat())).is_equal(0)
	assert_array(fields).is_equal(before)

func test_growth_cap_and_invalid_legacy_area_are_bounded()->void:
	var fields:=_grow(72,_flat())
	assert_int(fields.size()).is_equal(72)
	GameState.known_discoveries.append("seed_selection")
	preload("res://scripts/opening_opportunities.gd").data().programs.seed.retained=10.0
	var events:Array[Dictionary]=[]
	model._attempt_field_growth(365,events,_flat())
	assert_int(GameState.settlement_plots.size()).is_equal(72)
	assert_array(events).is_empty()
	_reset(772241)
	fields=_legacy_chain(1)
	fields[0]["area_ha"]=1.0e12
	var before:=fields.duplicate(true)
	assert_int(model._repair_legacy_field_geometry(_flat())).is_equal(0)
	assert_array(fields).is_equal(before)

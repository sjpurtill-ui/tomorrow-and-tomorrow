extends GdUnitTestSuite
const Growth=preload("res://scripts/settlement_country_growth.gd")
const Early=preload("res://scripts/early_settlement_visual.gd")

func _record(kind:String="coast",count:int=6)->Dictionary:
	return {"id":"place:shore","position":Vector2(20,30),
		"place":{"kind":kind,"facing":Vector2.RIGHT if kind!="inland" else Vector2.ZERO},
		"settlement_growth":{"seed":47017,"parcels":count,"templates":[{"form":"timber_household","roof_plan":"timber_ridge","material_family":"timber","storeys":1}]}}

func _grow(record:Dictionary,previous:Dictionary={},river_distance:Callable=Callable())->Dictionary:
	var state:=Growth.begin(record,previous)
	var steps:=0
	while not Growth.advance(state,func(at:Vector2)->bool:return at.x<20.012,func(_at:Vector2)->float:return 0.0,river_distance):
		steps+=1
		assert_int(steps).is_less_equal(Growth.MAX_PARCELS)
	return state

func _layout(state:Dictionary)->Dictionary:
	var plots:Array[Dictionary]=[];plots.assign(state.plots)
	var routes:Array[Dictionary]=[];routes.assign(state.routes)
	return Early.layout(plots,routes,func(at:Vector2)->bool:return at.x<0.012)

func test_shore_doors_face_water_with_checked_dry_footprints()->void:
	for kind:String in ["coast","lake","river"]:
		var record:=_record(kind,18)
		var before:=record.duplicate(true)
		var state:=_grow(record)
		var plan:=_layout(state)
		assert_array(plan.buildings).is_not_empty()
		for home:Dictionary in plan.buildings:
			var direction:=Vector2(sin(float(home.angle)),cos(float(home.angle)))
			assert_float(direction.dot(Vector2.RIGHT)).is_greater(0.999)
			for point:Vector2 in home.footprint:assert_float(point.x).is_less(0.012)
		assert_dict(record).is_equal(before)

func test_population_growth_preserves_founded_parcels_and_shore_lanes()->void:
	var first:=_grow(_record("coast",6))
	var before:=first.duplicate(true)
	var grown:=_grow(_record("coast",Growth.MAX_PARCELS+100),first)
	assert_int(grown.target).is_equal(Growth.MAX_PARCELS)
	assert_int(grown.plots.size()).is_greater(first.plots.size())
	assert_dict(first).is_equal(before)
	for index in first.plots.size():assert_dict(grown.plots[index]).is_equal(first.plots[index])
	for index in first.routes.size():assert_dict(grown.routes[index]).is_equal(first.routes[index])
	assert_vector(grown.origin).is_equal(Vector2(20,30))

func test_inland_seed_keeps_existing_root_geometry_without_water_fields()->void:
	var record:=_record("inland",12)
	var inherited:=record.duplicate(true);inherited.erase("place")
	var named:=_grow(record)
	var ordinary:=_grow(inherited)
	assert_array(named.plots).is_equal(ordinary.plots)
	assert_array(named.routes).is_equal(ordinary.routes)
	for plot:Dictionary in named.plots:assert_bool(plot.has("water_facing")).is_false()

func test_shore_growth_keeps_every_existing_roof_footprint_and_heading()->void:
	var first:=_grow(_record("coast",6))
	var initial:=_layout(first)
	assert_array(initial.buildings).is_not_empty()
	var plots:Array[Dictionary]=[];plots.assign(first.plots)
	Early.remember_layout(initial,plots)
	var grown:=_grow(_record("coast",24),first)
	var after:=_layout(grown)
	var sites:Dictionary={}
	for building:Dictionary in after.buildings:sites[String(building.id)]=building
	for building:Dictionary in initial.buildings:
		assert_bool(sites.has(String(building.id))).is_true()
		if not sites.has(String(building.id)):continue
		var retained:Dictionary=sites[String(building.id)]
		assert_array([retained.position,retained.angle,retained.footprint,retained.variant]).is_equal([building.position,building.angle,building.footprint,building.variant])

func test_river_bank_pulls_are_display_only_and_not_created_for_inland()->void:
	var river:=Growth.begin(_record("river"))
	var inland:=Growth.begin(_record("inland"))
	assert_int(river.nuclei.size()).is_equal(3)
	assert_int(inland.nuclei.size()).is_equal(1)
	assert_float(Vector2(river.nuclei[1].position).dot(Vector2.RIGHT)).is_less(0.0)
	assert_float(Vector2(river.nuclei[2].position).dot(Vector2.RIGHT)).is_less(0.0)

func test_legacy_river_bearing_is_sampled_once_without_changing_the_record()->void:
	var record:=_record("river",6)
	record.place.facing=Vector2.ZERO
	var before:=record.duplicate(true)
	var river:=_grow(record,{},func(at:Vector2)->float:return absf(at.x-20.925))
	assert_vector(river.facing).is_equal(Vector2.RIGHT)
	assert_dict(record).is_equal(before)
	var resumed:=Growth.begin(record,river)
	assert_vector(resumed.facing).is_equal(Vector2.RIGHT)
	assert_int(resumed.nuclei.size()).is_equal(3)

func test_unbuildable_dry_cliff_does_not_invent_a_river_bearing()->void:
	var record:=_record("river",6)
	record.place.facing=Vector2.ZERO
	var state:=_grow(record)
	assert_vector(state.facing).is_equal(Vector2.ZERO)
	assert_vector(Growth.river_facing(Vector2.ZERO,func(_at:Vector2)->float:return INF)).is_equal(Vector2.ZERO)

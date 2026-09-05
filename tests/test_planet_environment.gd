extends GdUnitTestSuite

const TEST_SEED:=873421


func before_test()->void:
	GameState.reset_for_new_world(TEST_SEED)
	PlanetEnvironment.reset_for_new_world()
	ResourceSystem.reset_for_new_world()


func test_same_seed_and_place_produce_the_same_complete_environment()->void:
	var position:=PlanetEnvironment.nearest_viable_land(Vector2(6200.0,-2800.0),17)
	var first:=PlanetEnvironment.profile_at(position)
	var second:=PlanetEnvironment.profile_at(position)
	assert_str(String(first.signature)).is_equal(String(second.signature))
	assert_float(float(first.mean_temperature_c)).is_equal_approx(float(second.mean_temperature_c),0.000001)
	assert_dict(first.resource_potentials).is_equal(second.resource_potentials)
	assert_bool(bool(first.land)).is_true()


func test_planet_contains_materially_different_climates_and_resource_endowments()->void:
	var signatures:Dictionary={}
	var biomes:Dictionary={}
	var min_temperature:=INF
	var max_temperature:=-INF
	var min_rain:=INF
	var max_rain:=-INF
	var leading_resources:Dictionary={}
	for z in [-7800.0,-5200.0,-2600.0,0.0,2600.0,5200.0,7800.0]:
		for x in [-16500.0,-11000.0,-5500.0,0.0,5500.0,11000.0,16500.0]:
			var position:=Vector2(x,z)
			if not PlanetEnvironment.is_land(position): continue
			var profile:=PlanetEnvironment.profile_at(position)
			signatures[String(profile.signature)]=true
			biomes[String(profile.biome)]=true
			min_temperature=minf(min_temperature,float(profile.temperature))
			max_temperature=maxf(max_temperature,float(profile.temperature))
			min_rain=minf(min_rain,float(profile.precipitation))
			max_rain=maxf(max_rain,float(profile.precipitation))
			var best_name:=""
			var best_value:=-1.0
			for resource_variant in (profile.resource_potentials as Dictionary).keys():
				var resource_name:=String(resource_variant)
				var value:=float(profile.resource_potentials[resource_name])
				if value>best_value:
					best_value=value
					best_name=resource_name
			leading_resources[best_name]=true
	assert_int(signatures.size()).is_greater_equal(8)
	assert_int(biomes.size()).is_greater_equal(3)
	assert_int(leading_resources.size()).is_greater_equal(3)
	assert_float(max_temperature-min_temperature).is_greater(0.40)
	assert_float(max_rain-min_rain).is_greater(0.35)


func test_seasons_reverse_between_hemispheres()->void:
	var north:=PlanetEnvironment.profile_at(PlanetEnvironment.nearest_viable_land(Vector2(1200.0,4200.0),23))
	var south:=north.duplicate(true)
	north["position"]=Vector2(1200.0,4200.0)
	south["position"]=Vector2(1200.0,-4200.0)
	var north_factor:=PlanetEnvironment.food_season_factor("Fresh plants",north,91.0)
	var south_factor:=PlanetEnvironment.food_season_factor("Fresh plants",south,91.0)
	assert_float(absf(north_factor-south_factor)).is_greater(0.25)


func test_rivals_begin_on_land_with_varied_causal_profiles()->void:
	CivilizationSystem.reset_for_new_world()
	var signatures:Dictionary={}
	var min_food:=INF
	var max_food:=-INF
	for civ_variant in CivilizationSystem.civilizations:
		var civ:Dictionary=civ_variant
		var world_position:Vector2=CivilizationSystem._civilization_world_position(civ)
		var profile:Dictionary=civ.get("environment_profile",{})
		assert_bool(PlanetEnvironment.is_land(world_position)).is_true()
		assert_bool(profile.is_empty()).is_false()
		signatures[String(profile.get("signature",""))]=true
		min_food=minf(min_food,float(profile.get("food_potential",0.0)))
		max_food=maxf(max_food,float(profile.get("food_potential",0.0)))
	assert_int(signatures.size()).is_greater_equal(maxi(4,CivilizationSystem.civilizations.size()/3))
	assert_float(max_food-min_food).is_greater(0.12)


func test_secondary_settlement_deposits_are_bounded_and_idempotent()->void:
	var profile:=PlanetEnvironment.profile_at(Vector2.ZERO,{"height":0.4,"temperature":0.62,"precipitation":0.72,"river_distance_km":2.0,"biome":"floodplain","fertility":0.95,"woodland":0.58,"game":0.70,"stone":0.35})
	var sites:Array[Dictionary]=[]
	for resource_name in ["Timber","Stone","Fertile Soil","Game","Fiber Plants","Clay","Flint","Limestone","Copper Ore","Iron Ore","Coal","Medicinal Plants","Phosphate Rock"]:
		sites.append({"type":resource_name,"position":Vector3(float(sites.size())+1.0,0.4,2.0),"potential":maxf(0.82,float(profile.resource_potentials.get(resource_name,0.0))),"initially_observed":true})
	ResourceSystem.register_settlement_occurrences("settlement_002",sites,profile)
	var first_count:=GameState.resource_deposits.size()
	assert_int(first_count).is_between(1,12)
	for deposit_variant in GameState.resource_deposits:
		assert_str(String((deposit_variant as Dictionary).source_settlement_id)).is_equal("settlement_002")
	ResourceSystem.register_settlement_occurrences("settlement_002",sites,profile)
	assert_int(GameState.resource_deposits.size()).is_equal(first_count)

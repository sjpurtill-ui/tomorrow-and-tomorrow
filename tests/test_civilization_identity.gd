extends GdUnitTestSuite
const Identity=preload("res://scripts/civilization_identity.gd")
const MapIdentity=preload("res://scripts/city_map_identity.gd")

func test_full_world_has_unique_civilization_and_city_names_across_seeds()->void:
	for seed_value in [1,424242,-212121,1788457137]:
		var roster:=Identity.roster(seed_value)
		var names:Dictionary={};var cities:Dictionary={}
		assert_array(roster).has_size(36)
		for entry:Dictionary in roster:
			assert_bool(names.has(entry.name)).is_false();names[entry.name]=true
			assert_array(entry.cities).has_size(5)
			for city:String in entry.cities:
				assert_bool(cities.has(city)).is_false();cities[city]=true
				assert_bool(city.begins_with(String(entry.name))).is_false()
		assert_int(cities.size()).is_equal(180)

func test_flags_use_distinct_compositions_and_cache_is_scoped_to_world()->void:
	GameState.reset_for_new_world(424242)
	var patterns:Dictionary={};var symbols:Dictionary={};var colors:Dictionary={};var pixels:Dictionary={}
	for index in 36:
		var id:="civ_%02d" % (index+1)
		var entry:=Identity.identity(GameState.world_seed,id)
		patterns[entry.pattern]=true;symbols[entry.symbol]=true;colors[entry.field]=true
		var flag:=MapIdentity.foreign(id)
		var data:PackedByteArray=flag.texture.get_image().get_data()
		var fingerprint:=data.hex_encode()
		assert_bool(pixels.has(fingerprint)).is_false();pixels[fingerprint]=true
		assert_bool(MapIdentity.foreign(id).texture==flag.texture).is_true()
	assert_int(patterns.size()).is_equal(8)
	assert_int(symbols.size()).is_equal(12)
	assert_int(colors.size()).is_equal(12)
	var first:Dictionary=MapIdentity.foreign("civ_01")
	GameState.reset_for_new_world(202603)
	var second:Dictionary=MapIdentity.foreign("civ_01")
	assert_bool(first.texture==second.texture).is_false()
	assert_bool(first.texture.get_image().get_data()==second.texture.get_image().get_data()).is_false()
	GameState.reset_for_new_world(424242)
	assert_array(MapIdentity.foreign("civ_01").texture.get_image().get_data()).is_equal(first.texture.get_image().get_data())

func test_new_world_uses_named_cities_and_existing_names_survive_save()->void:
	GameState.reset_for_new_world(424242)
	CivilizationSystem.reset_for_new_world()
	var names:Dictionary={}
	for civ:Dictionary in CivilizationSystem.civilizations:
		var identity:=Identity.identity(GameState.world_seed,String(civ.id))
		assert_str(String(civ.name)).is_equal(String(identity.name))
		assert_bool(names.has(civ.name)).is_false();names[civ.name]=true
		for i in 5:assert_str(String(civ.strategic_regions[i].name)).is_equal(String(identity.cities[i]))
	var saved:=CivilizationSystem.export_state()
	saved.civilizations[0].name="Earlier civilization name"
	saved.civilizations[0].strategic_regions[0].name="Earlier city name"
	assert_bool(CivilizationSystem.import_state(JSON.parse_string(JSON.stringify(saved))).has("ok")).is_true()
	assert_str(String(CivilizationSystem.civilizations[0].name)).is_equal("Earlier civilization name")
	assert_str(String(CivilizationSystem.civilizations[0].strategic_regions[0].name)).is_equal("Earlier city name")

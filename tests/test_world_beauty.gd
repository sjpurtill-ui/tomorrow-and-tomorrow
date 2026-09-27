extends GdUnitTestSuite
## The painted biome palette (scripts/world_beauty.gdshaderinc) chooses land
## colour from climate. These checks keep it readable and in the art direction:
## wet country greener than dry, woodland darker than open ground, cold land
## greyer, and nothing neon.

const BEAUTY:=preload("res://scripts/world_beauty.gd")


func _saturation(c:Color)->float:
	return c.s


func test_palette_constants_are_read_from_the_shader()->void:
	var p:=BEAUTY.palette()
	for key in ["MEADOW_LUSH","MEADOW","STEPPE","DRYLAND","WETLAND","WOOD","WOOD_COLD","WOOD_DRY","TUNDRA","UPLAND"]:
		assert_bool(p.has(key)).override_failure_message("missing WB_%s" % key).is_true()


func test_wet_meadow_is_greener_than_dry_steppe()->void:
	var meadow:=BEAUTY.biome_colour(0.75,0.6,0.0,0.3)
	var steppe:=BEAUTY.biome_colour(0.25,0.6,0.0,0.3)
	# Green leads red in meadow; red leads green in steppe (ochre).
	assert_float(meadow.g-meadow.r).is_greater(0.03)
	assert_float(steppe.r-steppe.g).is_greater(0.0)
	assert_float(steppe.get_luminance()).is_greater(meadow.get_luminance())


func test_woodland_is_darker_than_open_ground()->void:
	for rain in [0.45,0.65,0.85]:
		var open:=BEAUTY.biome_colour(rain,0.6,0.0,0.3)
		var wood:=BEAUTY.biome_colour(rain,0.6,1.0,0.3)
		assert_float(wood.get_luminance()).is_less(open.get_luminance()*0.85)


func test_hot_drylands_are_the_palest_and_warmest()->void:
	var dryland:=BEAUTY.biome_colour(0.05,0.9,0.0,0.3)
	var meadow:=BEAUTY.biome_colour(0.7,0.6,0.0,0.3)
	assert_float(dryland.get_luminance()).is_greater(meadow.get_luminance())
	assert_float(dryland.r).is_greater(dryland.b+0.15)


func test_cold_country_is_grey_not_green()->void:
	var tundra:=BEAUTY.biome_colour(0.6,0.05,0.0,0.3)
	var meadow:=BEAUTY.biome_colour(0.6,0.6,0.0,0.3)
	assert_float(_saturation(tundra)).is_less(_saturation(meadow))


func test_high_ground_goes_to_bare_upland()->void:
	var low:=BEAUTY.biome_colour(0.6,0.6,0.5,0.3)
	var high:=BEAUTY.biome_colour(0.6,0.6,0.5,10.0)
	assert_float(_saturation(high)).is_less(_saturation(low))


func test_nothing_is_neon()->void:
	# Art direction: land never above ~50% saturation, anywhere in the climate space.
	for rain in [0.0,0.2,0.4,0.6,0.8,1.0]:
		for warm in [0.0,0.3,0.6,0.9]:
			for forest in [0.0,0.5,1.0]:
				for pattern in [0.0,1.0]:
					var c:=BEAUTY.biome_colour(rain,warm,forest,0.5,pattern)
					assert_float(_saturation(c)).override_failure_message("rain %s warm %s forest %s" % [rain,warm,forest]).is_less_equal(0.45)


func test_climate_changes_blend_without_jumps()->void:
	var previous:=BEAUTY.biome_colour(0.0,0.6,0.0,0.3)
	for step in range(1,101):
		var c:=BEAUTY.biome_colour(step/100.0,0.6,0.0,0.3)
		var jump:=absf(c.r-previous.r)+absf(c.g-previous.g)+absf(c.b-previous.b)
		assert_float(jump).is_less(0.05)
		previous=c


func test_shader_include_has_only_declarations_at_top_level()->void:
	# A stray statement outside a function fails the whole terrain shader at
	# run time (the land renders flat grey), and headless tests never compile
	# shaders. Keep the includes structurally sound: balanced braces, and only
	# constants, uniforms and function definitions at the top level.
	for path in ["res://scripts/world_beauty.gdshaderinc","res://scripts/water_beauty.gdshaderinc","res://scripts/map_cloud.gdshaderinc"]:
		_assert_declarations_only(path)


func _assert_declarations_only(path:String)->void:
	var text:=FileAccess.get_file_as_string(path)
	assert_str(text).override_failure_message("missing %s" % path).is_not_empty()
	var depth:=0
	var allowed:=RegEx.new()
	allowed.compile("^(const |uniform |#|}|//|(vec[234]|float|int|bool|mat[234]|void) [A-Za-z_0-9]+[(])")
	var line_number:=0
	for raw in text.split("\n"):
		line_number+=1
		var line:=raw.strip_edges()
		if depth==0 and line!="" and allowed.search(line)==null:
			fail("%s: top-level statement at line %d: %s" % [path,line_number,line])
		depth+=line.count("{")-line.count("}")
		assert_int(depth).override_failure_message("unbalanced braces at line %d" % line_number).is_greater_equal(0)
	assert_int(depth).is_equal(0)


func test_fresh_snow_follows_the_weather_sky()->void:
	var weather:=preload("res://scripts/map_weather.gd")
	var cold:={"precipitation":0.8,"mean_temperature_c":-2.0,"seasonality_c":12.0,"position":Vector2(0,-4000)}
	var hot:={"precipitation":0.8,"mean_temperature_c":26.0,"seasonality_c":4.0,"position":Vector2(0,-500)}
	var snowy_days:=0;var lying_after_snow:=0
	for day in range(0,730):
		# Hot country never shows fresh snow.
		assert_float(BEAUTY.lying_snow(4242,float(day),hot)).is_equal(0.0)
		var sky:Dictionary=weather.state(4242,float(day),cold)
		if float(sky.snow)>0.2:
			snowy_days+=1
			if BEAUTY.lying_snow(4242,float(day),cold)>0.3:lying_after_snow+=1
	assert_int(snowy_days).is_greater(0)
	# Wherever the sky snows hard, the ground shows it the same day.
	assert_int(lying_after_snow).is_equal(snowy_days)


func test_fresh_snow_is_deterministic_and_bounded()->void:
	var cold:={"precipitation":0.9,"mean_temperature_c":-6.0,"seasonality_c":14.0,"position":Vector2(0,-5000)}
	for day in range(0,400,7):
		var a:=BEAUTY.lying_snow(77,float(day),cold)
		assert_float(a).is_equal(BEAUTY.lying_snow(77,float(day),cold))
		assert_float(a).is_between(0.0,1.0)


func test_round_two_shaders_are_wired_in()->void:
	# The terrain paints woodland margins, strands and sky fill, and draws
	# cloud shadows on the land; the sea recognises still ponds; the plants
	# share the land's cloud shadows (codex/beauty-2).
	var terrain:=FileAccess.get_file_as_string("res://scripts/local_terrain.gd")
	for call in ["wb_stand_edge(","wb_fringe(","wb_strand(","wb_sky_fill(","map_cloud_shadow(","wb_macro_normal("]:
		assert_bool(terrain.contains(call)).override_failure_message("terrain shader lacks %s" % call).is_true()
	assert_int(terrain.count('#include "res://scripts/map_cloud.gdshaderinc"')).is_equal(2)
	var sea:=FileAccess.get_file_as_string("res://scripts/coastal_water.gdshader")
	assert_bool(sea.contains("wbw_enclosure(") and sea.contains("wbw_still_water(")).is_true()
	# Ambience hands cloud shadows to materials that draw them on the land.
	var ambience:=FileAccess.get_file_as_string("res://scripts/map_ambience.gd")
	assert_bool(ambience.contains('"map_cloud"')).is_true()

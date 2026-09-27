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
	# shaders. Keep the include structurally sound: balanced braces, and only
	# constants and function definitions at the top level.
	var text:=FileAccess.get_file_as_string("res://scripts/world_beauty.gdshaderinc")
	var depth:=0
	var allowed:=RegEx.new()
	allowed.compile("^(const |uniform |#|}|//|(vec[234]|float|int|bool|mat[234]|void) [A-Za-z_0-9]+[(])")
	var line_number:=0
	for raw in text.split("\n"):
		line_number+=1
		var line:=raw.strip_edges()
		if depth==0 and line!="" and allowed.search(line)==null:
			fail("top-level statement at line %d: %s" % [line_number,line])
		depth+=line.count("{")-line.count("}")
		assert_int(depth).override_failure_message("unbalanced braces at line %d" % line_number).is_greater_equal(0)
	assert_int(depth).is_equal(0)

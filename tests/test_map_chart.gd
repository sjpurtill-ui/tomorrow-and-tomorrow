extends GdUnitTestSuite
## The map as a hand-coloured chart from the regional view outward
## (scripts/map_chart.gdshaderinc, codex/map-beauty). Headless runs never
## compile shaders, so these check the include's structure, that the terrain
## and the sea draw it, and that it takes over at the right views.

const CHART:="res://scripts/map_chart.gdshaderinc"
const TERRAIN:=preload("res://scripts/local_terrain.gd")
const AMBIENCE:=preload("res://scripts/map_ambience.gd")


func _text(path:String)->String:
	return FileAccess.get_file_as_string(path)


func _float_const(name:String)->float:
	var pattern:=RegEx.new()
	pattern.compile("const float %s = ([-0-9.]+);" % name)
	var found:=pattern.search(_text(CHART))
	assert_object(found).override_failure_message("missing %s" % name).is_not_null()
	return float(found.get_string(1)) if found else NAN


func _vec3_consts(prefix:String)->Dictionary:
	var pattern:=RegEx.new()
	pattern.compile("const vec3 (%s[A-Z_]*) = vec3\\(([-0-9.]+), ([-0-9.]+), ([-0-9.]+)\\);" % prefix)
	var out:={}
	for found in pattern.search_all(_text(CHART)):
		out[found.get_string(1)]=Vector3(float(found.get_string(2)),float(found.get_string(3)),float(found.get_string(4)))
	return out


## Mirror of mc_chart_weight() for a straight-down view: a design pixel at
## the view's centre spans camera.size/1080 km (the lens keeps height).
func _weight(camera_size:float)->float:
	return smoothstep(_float_const("MC_CHART_FROM"),_float_const("MC_CHART_FULL"),camera_size/1080.0)


func test_chart_include_has_only_declarations_at_top_level()->void:
	# A stray statement outside a function fails the whole terrain shader at
	# run time (the land renders flat grey).
	var text:=_text(CHART)
	assert_str(text).is_not_empty()
	var depth:=0
	var allowed:=RegEx.new()
	allowed.compile("^(const |uniform |#|}|//|(vec[234]|float|int|bool|mat[234]|void) [A-Za-z_0-9]+[(])")
	var line_number:=0
	for raw in text.split("\n"):
		line_number+=1
		var line:=raw.strip_edges()
		if depth==0 and line!="" and allowed.search(line)==null:
			fail("%s: top-level statement at line %d: %s" % [CHART,line_number,line])
		depth+=line.count("{")-line.count("}")
		assert_int(depth).override_failure_message("unbalanced braces at line %d" % line_number).is_greater_equal(0)
	assert_int(depth).is_equal(0)


func test_chart_takes_no_derivatives()->void:
	# Its functions run inside the terrain shader's branches, where screen
	# derivatives are undefined.
	var text:=_text(CHART)
	for call in ["dFdx(","dFdy(","fwidth("]:
		assert_bool(text.contains(call)).override_failure_message("chart takes %s" % call).is_false()


func test_terrain_and_sea_draw_the_chart()->void:
	var terrain:=_text("res://scripts/local_terrain.gd")
	assert_int(terrain.count('#include "res://scripts/map_chart.gdshaderinc"')).is_equal(1)
	for call in ["mc_chart_weight(","mc_chart_ground(","mc_landform(","mc_fields(","mc_design_km(relative_position"]:
		assert_bool(terrain.contains(call)).override_failure_message("terrain shader lacks %s" % call).is_true()
	var sea:=_text("res://scripts/coastal_water.gdshader")
	assert_bool(sea.contains('#include "res://scripts/map_chart.gdshaderinc"')).is_true()
	assert_bool(sea.contains("mc_chart_sea(")).is_true()
	# The sea's include order: the chart needs world_beauty's contours.
	assert_int(sea.find("world_beauty.gdshaderinc")).is_less(sea.find("map_chart.gdshaderinc"))


func test_chart_takes_over_between_the_valley_and_region_views()->void:
	# Nothing of the chart at 50,000 ft, all of it at the Region view, for
	# every common window shape.
	var levels:Array=TERRAIN.CAMERA_DISTANCE_LEVELS
	var valley_km:=float(levels[1].width_km)
	var region_km:=float(levels[2].width_km)
	for aspect in [4.0/3.0,16.0/10.0,16.0/9.0,21.0/9.0]:
		assert_float(_weight(valley_km/aspect)).override_failure_message("chart shows at 50,000 ft, aspect %.2f" % aspect).is_equal(0.0)
		assert_float(_weight(region_km/aspect)).override_failure_message("chart incomplete at Region, aspect %.2f" % aspect).is_equal(1.0)


func test_chart_crossfade_is_smooth_and_monotonic()->void:
	var previous:=0.0
	var size:=4.0
	while size<200.0:
		var w:=_weight(size)
		assert_float(w).is_greater_equal(previous)
		assert_float(w-previous).override_failure_message("chart jumps near size %.1f" % size).is_less(0.12)
		previous=w
		size*=1.04


func test_cloud_shadows_are_gone_before_the_chart_is_whole()->void:
	# Weather never mottles the chart (the map's grey blotches of old).
	assert_float(AMBIENCE.CLOUD_GONE_ABOVE/1080.0).is_less_equal(_float_const("MC_CHART_FULL"))
	assert_float(AMBIENCE.CLOUD_FULL_BELOW).is_less(AMBIENCE.CLOUD_GONE_ABOVE)


func test_chart_washes_are_muted_and_read_as_their_lands()->void:
	var washes:=_vec3_consts("MC_WASH_")
	assert_int(washes.size()).is_greater_equal(12)
	for key in washes:
		var wash:Vector3=washes[key]
		for channel in [wash.x,wash.y,wash.z]:
			assert_float(channel).override_failure_message("%s out of range" % key).is_between(0.40,1.30)
	var meadow:Vector3=washes.MC_WASH_MEADOW
	var steppe:Vector3=washes.MC_WASH_STEPPE
	var wood:Vector3=washes.MC_WASH_WOOD
	var sea:Vector3=washes.MC_WASH_SEA
	# Wet grass is greener than dry, woods darker than grass, the sea bluer
	# than any land, snow the palest of all.
	assert_float(meadow.y-meadow.x).is_greater(steppe.y-steppe.x)
	assert_float(wood.x+wood.y+wood.z).is_less(meadow.x+meadow.y+meadow.z)
	for key in washes:
		if not String(key).begins_with("MC_WASH_SEA"):
			var land:Vector3=washes[key]
			assert_float(sea.z/sea.x).override_failure_message("%s bluer than the sea" % key).is_greater(land.z/land.x)
	var snow:Vector3=washes.MC_WASH_SNOW
	for key in washes:
		var other:Vector3=washes[key]
		assert_float(snow.x+snow.y+snow.z).is_greater_equal(other.x+other.y+other.z)

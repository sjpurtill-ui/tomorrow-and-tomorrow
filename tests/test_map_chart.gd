extends GdUnitTestSuite
## The map as a hand-coloured chart from the regional view outward
## (scripts/map_chart.gdshaderinc, codex/map-beauty). Headless runs never
## compile shaders, so these check the include's structure, that the terrain
## and the sea draw it, and that it takes over at the right views.

const CHART:="res://scripts/map_chart.gdshaderinc"
const TERRAIN:=preload("res://scripts/local_terrain.gd")
const AMBIENCE:=preload("res://scripts/map_ambience.gd")

class BareTerrain extends "res://scripts/local_terrain.gd":
	func _ready()->void:pass
	func _process(_delta:float)->void:pass


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
	# The chart needs the palette and the coast rasters included before it.
	var chart_include:='#include "res://scripts/map_chart.gdshaderinc"'
	for needed in ["map_palette.gdshaderinc","coast_mask.gdshaderinc","map_coast.gdshaderinc"]:
		var line:='#include "res://scripts/%s"' % needed
		assert_int(sea.find(line)).is_between(0,sea.find(chart_include))
		assert_int(terrain.find(line)).is_between(0,terrain.find(chart_include))


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


func test_relief_is_engraved_and_ranges_carry_peaks()->void:
	# Contours heavier on steep ground and faint on flats, hachures where they
	# would crowd, relief shaded from a generalised landform, and inked peaks
	# at the far views, all composed into the chart.
	var text:=_text(CHART)
	for call in ["mc_contours(","mc_hachures(","mc_mountains(","mc_relief(","mc_patch_bicubic("]:
		assert_bool(text.contains(call)).override_failure_message("chart lacks %s" % call).is_true()
	var ground:=text.substr(text.find("vec3 mc_chart_ground("))
	for call in ["mc_contours(","mc_hachures(","mc_mountains(","mc_relief("]:
		assert_bool(ground.contains(call)).override_failure_message("chart ground does not draw %s" % call).is_true()
	# Peaks stand upright on the screen, whichever way the map is turned.
	assert_bool(_text("res://scripts/local_terrain.gd").contains("mc_screen_up(INV_VIEW_MATRIX)")).is_true()


func test_patch_heights_reach_the_chart_with_box_filtered_levels()->void:
	# The generalised landform reads mip levels of the patch heights: the
	# plain height texture (texelFetch, nearest) stays as it was, and a
	# second texture with every level is bound as chart_relief.
	var terrain:BareTerrain=auto_free(BareTerrain.new())
	add_child(terrain)
	var size:=33
	var heights:=PackedFloat32Array()
	for z in size:
		for x in size:heights.append(0.2+0.1*sin(float(x)*0.4)+0.05*cos(float(z)*0.3))
	terrain._install_regional_patch({"mesh":ArrayMesh.new(),"center":Vector2.ZERO,"span":8.0,"resolution":size,"heights":heights})
	assert_object(terrain.chart_relief_texture).is_not_null()
	var relief:Image=terrain.chart_relief_texture.get_image()
	assert_bool(relief.has_mipmaps()).is_true()
	assert_int(relief.get_width()).is_equal(size)
	assert_bool(terrain.river_terrain_height_texture.get_image().has_mipmaps()).is_false()
	var material:=terrain.regional_terrain_patch.material_override as ShaderMaterial
	assert_object(material.get_shader_parameter("chart_relief")).is_same(terrain.chart_relief_texture)


func test_water_is_drawn_like_a_chart()->void:
	# The sea draws the coast's ink with the land from one shore, three
	# water-lines and a light stipple; rivers taper from a hairline at the
	# spring and stay on the map out to the continent view.
	var sea:=_text("res://scripts/coastal_water.gdshader")
	for call in ["mc_shore_px(","mc_waterlines(","mc_coast_ink("]:
		assert_bool(sea.contains(call)).override_failure_message("sea lacks %s" % call).is_true()
	var ground:=_text(CHART).substr(_text(CHART).find("vec3 mc_chart_ground("))
	assert_bool(ground.contains("mc_shore_px(") and ground.contains("mc_coast_ink(")).is_true()
	var river:=_text("res://scripts/map_river.gdshader")
	assert_bool(river.contains("mix(0.28,1.65")).override_failure_message("river no longer tapers from its spring").is_true()
	var terrain:=_text("res://scripts/local_terrain.gd")
	assert_bool(terrain.contains("river_overlay.visible=camera.size<=4000.0")).is_true()
	# The continent view (a 3,000 km wide window) keeps its rivers at any aspect.
	for aspect in [4.0/3.0,16.0/9.0,21.0/9.0]:
		assert_float(3000.0/aspect).is_less_equal(4000.0)

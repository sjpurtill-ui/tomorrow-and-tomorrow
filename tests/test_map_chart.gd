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

class CheapTerrain extends BareTerrain:
	func _height_at(x:float,z:float)->float:return x*.001+z*.002
	func _terrain_color_at(_x:float,_z:float,_h:float)->Color:return Color(.2,.3,.15)
	func _terrain_surface_fields_at(_x:float,_z:float,_h:float)->Vector4:return Vector4(1.5,.5,.5,.3)


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
## the view's centre spans camera.size/1080 km (the lens keeps height). The
## crossfade is eased over the scale's logarithm.
func _weight(camera_size:float)->float:
	return smoothstep(log(_float_const("MC_CHART_FROM")),log(_float_const("MC_CHART_FULL")),log(camera_size/1080.0))


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
	# The wheel and the glide zoom by equal ratios: through the band no step of
	# 4% changes the chart's share by more than about a tenth.
	assert_bool(_text(CHART).contains("smoothstep(log(MC_CHART_FROM), log(MC_CHART_FULL), log(")).is_true()
	var previous:=0.0
	var size:=4.0
	while size<200.0:
		var w:=_weight(size)
		assert_float(w).is_greater_equal(previous)
		assert_float(w-previous).override_failure_message("chart jumps near size %.1f" % size).is_less(0.09)
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
	var cover:=PackedByteArray()
	for index in size*size:cover.append_array(PackedByteArray([128,160,200,255 if heights[index]>0.2 else 0]))
	terrain._install_regional_patch({"mesh":ArrayMesh.new(),"center":Vector2.ZERO,"span":8.0,"resolution":size,"heights":heights,"cover":cover})
	assert_object(terrain.chart_relief_texture).is_not_null()
	var relief:Image=terrain.chart_relief_texture.get_image()
	assert_bool(relief.has_mipmaps()).is_true()
	assert_int(relief.get_width()).is_equal(size)
	assert_bool(terrain.river_terrain_height_texture.get_image().has_mipmaps()).is_false()
	var material:=terrain.regional_terrain_patch.material_override as ShaderMaterial
	assert_object(material.get_shader_parameter("chart_relief")).is_same(terrain.chart_relief_texture)
	# The land cover and shore mask go the same way (woods, marsh, water-lines).
	var covered:Image=terrain.chart_cover_texture.get_image()
	assert_bool(covered.has_mipmaps()).is_true()
	assert_int(covered.get_width()).is_equal(size)
	assert_object(material.get_shader_parameter("chart_cover")).is_same(terrain.chart_cover_texture)
	# A patch built without a cover (an old cache, a probe) binds none.
	terrain._install_regional_patch({"mesh":ArrayMesh.new(),"center":Vector2.ZERO,"span":8.0,"resolution":size,"heights":heights})
	assert_object(terrain.chart_cover_texture).is_null()


func test_water_is_drawn_like_a_chart()->void:
	# The sea draws the coast's ink with the land from one shore, three
	# water-lines and a light stipple; rivers taper from a hairline at the
	# spring and stay on the map out to the continent view.
	var sea:=_text("res://scripts/coastal_water.gdshader")
	for call in ["mc_shore_px(","mc_waterlines(","mc_coast_ink(","mc_cover_patch("]:
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


func test_woods_marsh_and_worked_land_are_drawn_in_the_same_ink()->void:
	var ground:=_text(CHART).substr(_text(CHART).find("vec3 mc_chart_ground("))
	for call in ["mc_symbols(kind,","kind <= chart_reach","mc_farmland(","mc_marsh(","mc_cover("]:
		assert_bool(ground.contains(call)).override_failure_message("chart ground lacks %s" % call).is_true()
	# The shader's place array holds exactly what chart_places sends.
	var places:=preload("res://scripts/chart_places.gd")
	assert_bool(_text(CHART).contains("uniform vec4 chart_places[%d];" % places.MAX_PLACES)).is_true()
	assert_bool(_text(CHART).contains("for (int i = 0; i < min(chart_place_count, %d); i++)" % places.MAX_PLACES)).is_true()


func test_worked_land_grows_with_a_place_within_historical_reach()->void:
	var places:=preload("res://scripts/chart_places.gd")
	var previous:=0.0
	for population in [0.0,40.0,120.0,1000.0,5000.0,20000.0,100000.0,1000000.0]:
		var reach:=places.worked_radius_km(population)
		assert_float(reach).is_greater_equal(previous)
		assert_float(reach).is_between(1.0,14.0)
		previous=reach
	# A camp farms about a kilometre round it; a town of a few thousand four
	# or five; a great city's hinterland ten or more.
	assert_float(places.worked_radius_km(120.0)).is_less(1.5)
	assert_float(places.worked_radius_km(5000.0)).is_between(3.5,5.0)
	assert_float(places.worked_radius_km(100000.0)).is_greater(10.0)


func test_places_reach_the_terrain_materials_padded_to_the_shader_array()->void:
	var places:=preload("res://scripts/chart_places.gd")
	var saved:=places.places
	var shader:=Shader.new()
	shader.code="shader_type spatial;
uniform int chart_place_count = 0;
uniform vec4 chart_places[24];
void fragment(){ALBEDO=vec3(chart_places[0].x*0.0+float(chart_place_count)*0.0);}
"
	var material:=ShaderMaterial.new();material.shader=shader
	places.places=PackedVector4Array([Vector4(10,20,3,0),Vector4(-5,4,2,1)])
	places.towns=PackedVector4Array([Vector4(0.7,1,0,0),Vector4(0.3,2,12345,0.8)])
	places.push([material])
	assert_int(int(material.get_shader_parameter("chart_place_count"))).is_equal(2)
	var sent:PackedVector4Array=material.get_shader_parameter("chart_places")
	assert_int(sent.size()).is_equal(places.MAX_PLACES)
	assert_vector(sent[1]).is_equal(Vector4(-5,4,2,1))
	var towns:PackedVector4Array=material.get_shader_parameter("chart_towns")
	assert_int(towns.size()).is_equal(places.MAX_PLACES)
	assert_vector(towns[1]).is_equal(Vector4(0.3,2,12345,0.8))
	places.places=saved


func test_towns_are_drawn_as_small_plans_sized_like_real_towns()->void:
	var places:=preload("res://scripts/chart_places.gd")
	assert_bool(_text(CHART).contains("uniform vec4 chart_towns[%d];" % places.MAX_PLACES)).is_true()
	var ground:=_text(CHART).substr(_text(CHART).find("vec3 mc_chart_ground("))
	assert_bool(ground.contains("mc_towns(")).is_true()
	var previous:=0.0
	for population in [1.0,120.0,400.0,4000.0,50000.0,1000000.0]:
		var built:=places.built_radius_km(population)
		assert_float(built).is_greater_equal(previous)
		assert_float(built).is_between(0.08,2.5)
		# A town is always built over less ground than it farms.
		assert_float(built).is_less(places.worked_radius_km(population))
		previous=built
	assert_float(places.built_radius_km(4000.0)).is_between(0.5,0.9)
	assert_float(places.built_radius_km(200000.0)).is_between(2.0,2.5)


func test_holder_colour_packs_the_way_the_shader_unpacks_it()->void:
	var places:=preload("res://scripts/chart_places.gd")
	for colour in [Color(0.2,0.6,0.9),Color(1,0,0),Color(0,0,0),Color(1,1,1),Color(0.47,0.13,0.81)]:
		var packed:=places.pack_colour(colour)
		# mc_unpack_colour() in map_chart.gdshaderinc, in single precision.
		var r:=floorf(packed/65536.0)
		var g:=floorf((packed-r*65536.0)/256.0)
		var b:=packed-r*65536.0-g*256.0
		assert_float(r/255.0).is_equal_approx(colour.r,0.003)
		assert_float(g/255.0).is_equal_approx(colour.g,0.003)
		assert_float(b/255.0).is_equal_approx(colour.b,0.003)
		# Exact in a 32-bit float (below 2^24).
		assert_float(packed).is_less(16777216.0)


func test_gather_keeps_places_and_towns_in_step()->void:
	var places:=preload("res://scripts/chart_places.gd")
	var gathered:Array=places.gather(Vector2.ZERO)
	assert_int(gathered.size()).is_equal(2)
	assert_int((gathered[0] as PackedVector4Array).size()).is_equal((gathered[1] as PackedVector4Array).size())
	assert_int((gathered[0] as PackedVector4Array).size()).is_less_equal(places.MAX_PLACES)


func test_the_planet_layer_draws_the_same_woods_towns_and_fields()->void:
	# Beyond the streamed patch (while a zoom out waits for the new patch)
	# the chart reads the same fields from the macro rasters, so woods, towns
	# and worked land do not pop in when the patch streams in; the sea draws
	# its water-lines from the patch alone.
	var text:=_text(CHART)
	assert_bool(text.contains("vec4 mc_cover_far(")).is_true()
	var ground:=text.substr(text.find("vec3 mc_chart_ground("))
	assert_bool(ground.contains("vec3 farm = mc_farmland(")).is_true()
	assert_bool(ground.contains("chart = mc_towns(")).is_true()
	assert_bool(ground.contains("if (use_patch) { chart = mc_towns(")).is_false()
	var sea:=_text("res://scripts/coastal_water.gdshader")
	assert_bool(sea.contains("mc_cover(")).is_false()


func test_the_terrain_shader_comes_in_a_painted_and_a_chart_build()->void:
	# The chart's code, never run, costs close views register space: they
	# draw with a build that has none of it (scripts/terrain_chart_build.gd).
	var build:=preload("res://scripts/terrain_chart_build.gd")
	var source:=_text("res://scripts/local_terrain.gd")
	assert_int(source.count(build.CHART_ON)).is_equal(1)
	assert_bool(source.contains("float mc_w=MC_CHART_ON?mc_chart_weight(mc_design):0.0;")).is_true()
	var code:="shader_type spatial;
%s
uniform float probe_value = 0.0;
void fragment(){ALBEDO=vec3(MC_CHART_ON?probe_value:0.0);}
" % build.CHART_ON
	var painted:=build.shader_for(code,false)
	var charted:=build.shader_for(code,true)
	assert_object(build.shader_for(code,false)).is_same(painted)
	assert_bool(painted.code.contains(build.CHART_OFF)).is_true()
	assert_bool(charted.code.contains(build.CHART_ON)).is_true()
	# A material moves between the builds and keeps its parameters.
	var material:=ShaderMaterial.new();material.shader=charted
	material.set_shader_parameter("probe_value",0.75)
	assert_int(build.apply([material],false)).is_equal(1)
	assert_object(material.shader).is_same(painted)
	assert_float(float(material.get_shader_parameter("probe_value"))).is_equal_approx(0.75,0.0001)
	assert_int(build.apply([material],false)).is_equal(0)
	# Materials of other shaders are left alone.
	var other:=ShaderMaterial.new();other.shader=Shader.new();other.shader.code="shader_type spatial;"
	assert_int(build.apply([other],true)).is_equal(0)
	# It reads where the chart starts from the include itself.
	assert_float(build.chart_from()).is_equal_approx(_float_const("MC_CHART_FROM"),0.000001)


func test_the_view_takes_the_chart_build_only_when_its_ground_reaches_chart_scale()->void:
	var build:=preload("res://scripts/terrain_chart_build.gd")
	var camera:=Camera3D.new();add_child(camera);auto_free(camera)
	camera.fov=rad_to_deg(2.0*atan(tan(deg_to_rad(25.0))/(16.0/9.0)))
	camera.far=100000.0
	var viewport:=Vector2(1600,900)
	for case:Array in [[1.6,false],[8.0,false],[84.375,true],[1687.5,true]]:
		var size:float=case[0]
		camera.near=size*0.001
		camera.position=Vector3(0.0,size/(2.0*tan(deg_to_rad(camera.fov)*0.5)),0.0)
		camera.look_at(Vector3(0.0,0.0,-0.0001),Vector3.FORWARD)
		camera.rotation.x=-PI*0.5+0.0001
		assert_bool(build.view_needs_chart(camera,viewport,0.0,false)).override_failure_message("size %.1f" % size).is_equal(case[1])
	# Hysteresis: once on, it stays on a little below where it came on. (The
	# rule looks at the farthest corner, about 13% farther than the middle of
	# a 16:9 view: 0.85 in the middle is about 0.96 at the corner.)
	var edge:=build.chart_from()*0.85*1080.0
	camera.position=Vector3(0.0,edge/(2.0*tan(deg_to_rad(camera.fov)*0.5)),0.0)
	assert_bool(build.view_needs_chart(camera,viewport,0.0,false)).is_false()
	assert_bool(build.view_needs_chart(camera,viewport,0.0,true)).is_true()
	# But the 50,000 ft view (about 0.82 at its corners) is never held on the
	# chart build after a zoom in: no ground in it is at chart scale.
	edge=build.chart_from()*0.72*1080.0
	camera.position=Vector3(0.0,edge/(2.0*tan(deg_to_rad(camera.fov)*0.5)),0.0)
	assert_bool(build.view_needs_chart(camera,viewport,0.0,true)).is_false()


func test_a_far_zoom_out_shows_a_preview_before_the_full_patch()->void:
	# A zoom out that leaves the finished patch a sliver of the new view gets
	# a quick preview of all of it first; a small step keeps the finished
	# ground until the full patch replaces it (test_terrain_lod).
	var lod:=preload("res://scripts/terrain_lod.gd")
	var terrain:CheapTerrain=auto_free(CheapTerrain.new());add_child(terrain)
	var span:=lod.bucket(10)
	for stage in 2:
		terrain._rebuild_regional_terrain_patch(Vector2.ZERO,span)
		while terrain.terrain_patch_job!=null:terrain._advance_terrain_patch()
	var wide:=lod.bucket(span*4.0)
	terrain._rebuild_regional_terrain_patch(Vector2.ZERO,wide)
	assert_int(terrain.terrain_patch_job.resolution).is_equal(lod.preview_resolution(wide))
	assert_int(terrain.terrain_patch_job.resolution).is_less(lod.resolution_for(wide))
	# While nothing covers the view the idle budget hurries, within a 120 Hz frame.
	assert_int(terrain.TERRAIN_PATCH_UNCOVERED_BUDGET_USEC).is_greater(terrain.TERRAIN_PATCH_IDLE_BUDGET_USEC)
	assert_int(terrain.TERRAIN_PATCH_UNCOVERED_BUDGET_USEC).is_less_equal(8333)

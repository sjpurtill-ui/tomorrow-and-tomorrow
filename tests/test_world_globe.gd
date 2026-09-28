extends GdUnitTestSuite
## The world view: the exact revealed-area measure, the known-map image's fog
## integrity, how knowledge was learned and how it grew, the zoom hand-overs
## between map and globe, and click-to-fly target maths.

const Chart:=preload("res://scripts/world_globe_chart.gd")
const WorldGlobe:=preload("res://scripts/hud/world_globe.gd")

class CameraTerrain extends "res://scripts/local_terrain.gd":
	var opened:=0
	func _ready()->void:pass
	func _process(_delta:float)->void:pass
	func _height_at(_x:float,_z:float)->float:return 0.0
	func _terrain_hit(_screen:Vector2)->Dictionary:return {}
	func _update_scale_lod()->void:pass
	func open_world_globe(_from_zoom:bool=false)->bool:
		opened+=1
		return true


func terrain_fixture()->Node3D:
	var terrain:Node3D=auto_free(CameraTerrain.new())
	add_child(terrain)
	terrain.camera=Camera3D.new();terrain.add_child(terrain.camera)
	terrain.camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	terrain.world_width=Chart.WIDTH_KM
	terrain.world_depth=Chart.DEPTH_KM
	return terrain


static func circle(x:float,z:float,radius:float,source:String="founding knowledge",day:int=0)->Dictionary:
	return {"kind":"circle","x":x,"z":z,"radius":radius,"source":source,"day":day}


static func trail(points:Array,radius:float,source:String="returned scout trail",day:int=0)->Dictionary:
	var list:Array=[]
	for point:Vector2 in points:list.append({"x":point.x,"z":point.y})
	return {"kind":"trail","x":points[0].x,"z":points[0].y,"radius":radius,"points":list,"source":source,"day":day}


static func heights(value:Callable)->Callable:
	return func()->Dictionary:return {"exact":value}


func build(areas:Array,height:Callable=Callable())->RefCounted:
	var chart:RefCounted=Chart.new()
	chart.refresh(areas,1234,Callable(),heights(height) if height.is_valid() else Callable(),false)
	return chart


## True surface area of a map disc: the integral of cos(latitude) over it.
static func disc_area(center:Vector2,radius:float)->float:
	var total:=0.0
	var steps:=400
	for i in steps:
		var z:=center.y-radius+(float(i)+0.5)*2.0*radius/float(steps)
		var half:=sqrt(maxf(0.0,radius*radius-(z-center.y)*(z-center.y)))
		total+=2.0*half*cos(Chart.latitude(z))*2.0*radius/float(steps)
	return total


func test_known_circle_measures_its_true_area()->void:
	var chart:=build([circle(0,0,72)])
	var expected:=PI*72.0*72.0
	assert_float(float(chart.stats.known_km2)).is_equal_approx(expected,expected*0.004)
	assert_float(float(chart.stats.known_fraction)).is_equal_approx(expected/Chart.surface_km2(),expected/Chart.surface_km2()*0.004)
	# The whole model sphere is about 510 million km2.
	assert_float(Chart.surface_km2()).is_equal_approx(40075.0*20004.0*2.0/PI,40075.0*20004.0*2.0/PI*0.0001)


func test_area_shrinks_with_cos_latitude_toward_the_poles()->void:
	var equator:=build([circle(0,0,72)])
	var north:=build([circle(0,-9000,72)])
	var expected:=disc_area(Vector2(0,-9000),72)
	assert_float(float(north.stats.known_km2)).is_equal_approx(expected,expected*0.01)
	# Near 81 degrees north the same map circle covers about cos(81) of the ground.
	var ratio:=float(north.stats.known_km2)/float(equator.stats.known_km2)
	assert_float(ratio).is_equal_approx(cos(Chart.latitude(-9000.0)),0.004)


func test_trails_measure_as_capsules_in_any_direction()->void:
	var level:=build([trail([Vector2(0,0),Vector2(500,0)],18.0)])
	var slanted:=build([trail([Vector2(0,0),Vector2(300,400)],18.0)])
	var expected:=36.0*500.0+PI*18.0*18.0
	assert_float(float(level.stats.known_km2)).is_equal_approx(expected,expected*0.005)
	assert_float(float(slanted.stats.known_km2)).is_equal_approx(expected,expected*0.006)
	# A bent trail does not count its joint twice.
	var bent:=build([trail([Vector2(0,0),Vector2(400,0),Vector2(400,300)],18.0)])
	var bent_expected:=36.0*700.0+PI*18.0*18.0
	assert_float(float(bent.stats.known_km2)).is_equal_approx(bent_expected,bent_expected*0.01)


func test_overlaps_are_counted_once()->void:
	var once:=build([circle(100,100,50)])
	var twice:=build([circle(100,100,50),circle(100,100,50)])
	assert_float(float(twice.stats.known_km2)).is_equal_approx(float(once.stats.known_km2),0.001)
	# Two circles a radius apart: their union, not their sum.
	var pair:=build([circle(0,0,50),circle(50,0,50)])
	var union:=(2.0*PI-(2.0*PI/3.0-sqrt(3.0)/2.0))*50.0*50.0
	assert_float(float(pair.stats.known_km2)).is_equal_approx(union,union*0.005)
	# A circle inside a trail's corridor adds nothing.
	var corridor:=build([trail([Vector2(0,0),Vector2(400,0)],30.0),circle(200,0,20,"observed city")])
	var corridor_only:=build([trail([Vector2(0,0),Vector2(400,0)],30.0)])
	assert_float(float(corridor.stats.known_km2)).is_equal_approx(float(corridor_only.stats.known_km2),0.01)


func test_ground_is_credited_to_how_it_was_first_learned()->void:
	var areas:=[circle(0,0,72,"founding knowledge",0),
		trail([Vector2(0,0),Vector2(600,0)],18.0,"returned scout trail",40),
		trail([Vector2(-900,300),Vector2(-1500,300)],24.0,"returned diplomatic route",90),
		circle(2000,0,40,"River war: established local geography",120),
		circle(3000,0,30,"trade caravan route",150)]
	var chart:=build(areas)
	var by:Dictionary=chart.stats.by_category
	var surface:=Chart.surface_km2()
	assert_float(float(by.travel)*surface).is_equal_approx(PI*72.0*72.0,PI*72.0*72.0*0.006)
	# The scouts are credited only for what the founding did not already show.
	var scouts_new:=36.0*600.0+PI*18.0*18.0-(36.0*72.0+PI*18.0*18.0*0.5)
	assert_float(float(by.scouts)*surface).is_between(scouts_new*0.97,scouts_new*1.03)
	var envoys:=48.0*600.0+PI*24.0*24.0
	assert_float(float(by.envoys)*surface).is_equal_approx(envoys,envoys*0.01)
	assert_float(float(by.war)).is_greater(0.0)
	assert_float(float(by.trade)).is_greater(0.0)
	var total:=0.0
	for id:String in by:total+=float(by[id])
	assert_float(total).is_equal_approx(float(chart.stats.known_fraction),0.0000001)
	# The card lists the largest share first, in plain words.
	var shares:=WorldGlobe.learned_shares(chart.stats)
	assert_str(String(shares[0][0])).is_equal("envoys")
	assert_array(shares.map(func(row:Array)->String:return String(row[0]))).contains(["scouts","travel","war","trade"])


func test_source_words_map_to_kinds_of_knowing()->void:
	assert_str(Chart.category("founding caravan camp survey")).is_equal("travel")
	assert_str(Chart.category("traveled ground")).is_equal("travel")
	assert_str(Chart.category("returned scout trail")).is_equal("scouts")
	assert_str(Chart.category("captured scout testimony")).is_equal("scouts")
	assert_str(Chart.category("foreign settlement observed")).is_equal("scouts")
	assert_str(Chart.category("returned diplomatic route")).is_equal("envoys")
	assert_str(Chart.category("River war: established local geography")).is_equal("war")
	assert_str(Chart.category("field campaign report")).is_equal("war")
	assert_str(Chart.category("trade caravan route")).is_equal("trade")


func test_unrevealed_texels_never_carry_land()->void:
	# Land everywhere: only what is known may show it.
	var all_land:=build([circle(0,0,72),trail([Vector2(200,50),Vector2(900,-300)],18.0)],func(_p:Vector2)->float:return 2.0)
	var image:Image=all_land.image
	var data:=image.get_data()
	var known:=0
	var leaks:=0
	var over:=0
	var astray:=0
	for texel in Chart.COLUMNS*Chart.ROWS:
		var at:=texel*4
		if data[at]==0:
			if data[at+1]!=0 or data[at+2]!=0 or data[at+3]!=0:leaks+=1
			continue
		known+=1
		if data[at+1]>data[at]:over+=1
		# Every known texel lies on the revealed shapes (within a texel and a half).
		var column:=texel%Chart.COLUMNS
		var row:=texel/Chart.COLUMNS
		var centre:=Vector2(-Chart.WIDTH_KM*0.5+(float(column)+0.5)*Chart.TEXEL_X,-Chart.DEPTH_KM*0.5+(float(row)+0.5)*Chart.TEXEL_Z)
		var near:=centre.distance_to(Vector2.ZERO)<=72.0+Chart.TEXEL_X*1.5 or centre.distance_to(Geometry2D.get_closest_point_to_segment(centre,Vector2(200,50),Vector2(900,-300)))<=18.0+Chart.TEXEL_X*1.5
		if not near:astray+=1
	assert_int(leaks).override_failure_message("unknown texels carry data").is_equal(0)
	assert_int(over).is_equal(0)
	assert_int(astray).override_failure_message("known texels away from the known ground").is_equal(0)
	assert_int(known).is_equal(int(all_land.stats.texels))
	assert_int(known).is_greater(20)


func test_a_coast_beyond_the_known_edge_never_shows()->void:
	# The people know only sea; land begins 20 km past the edge of what they saw.
	var chart:=build([circle(0,0,60)],func(p:Vector2)->float:return 1.5 if p.x>80.0 else -1.0)
	var data:=(chart.image as Image).get_data()
	var land_texels:=0
	for texel in Chart.COLUMNS*Chart.ROWS:
		if data[texel*4+1]!=0:land_texels+=1
	assert_int(land_texels).override_failure_message("texels show land nobody has seen").is_equal(0)
	assert_float(float(chart.stats.land_fraction)).is_equal(0.0)
	assert_float(float(chart.stats.sea_fraction)).is_greater(0.0)


func test_land_and_sea_split_what_is_known()->void:
	var chart:=build([circle(0,0,200)],func(p:Vector2)->float:return 1.0 if p.x>0.0 else -1.0)
	var land:=float(chart.stats.land_fraction)
	var sea:=float(chart.stats.sea_fraction)
	assert_float(land+sea).is_equal_approx(float(chart.stats.known_fraction),0.0000001)
	assert_float(land/(land+sea)).is_between(0.42,0.58)


func test_new_records_and_a_walked_trail_merge_like_a_full_rebuild()->void:
	var areas:Array=[circle(0,0,72)]
	var growing:=trail([Vector2(0,0),Vector2(120,40)],34.0,"traveled ground",3)
	var chart:RefCounted=Chart.new()
	chart.refresh(areas,99,Callable(),Callable(),false)
	var first:=float(chart.stats.known_km2)
	areas.append(growing)
	chart.refresh(areas,99,Callable(),Callable(),false)
	# The travel trail is walked further in place, then a scout trail returns.
	(growing.points as Array).append({"x":260.0,"z":90.0})
	chart.refresh(areas,99,Callable(),Callable(),false)
	areas.append(trail([Vector2(-50,0),Vector2(-400,300)],18.0,"returned scout trail",10))
	chart.refresh(areas,99,Callable(),Callable(),false)
	var fresh:=build(areas)
	assert_float(float(chart.stats.known_km2)).is_greater(first)
	assert_float(float(chart.stats.known_km2)).is_equal_approx(float(fresh.stats.known_km2),0.01)
	assert_bool((chart.image as Image).get_data()==(fresh.image as Image).get_data()).is_true()
	# A different world starts over.
	chart.refresh([circle(5000,0,10)],100,Callable(),Callable(),false)
	assert_float(float(chart.stats.known_km2)).is_equal_approx(PI*100.0*cos(0.0),PI*100.0*0.03)


func test_percent_words_keep_two_significant_figures()->void:
	assert_str(Chart.percent_text(0.004012)).is_equal("0.40%")
	assert_str(Chart.percent_text(0.0000321)).is_equal("0.0032%")
	assert_str(Chart.percent_text(0.01234)).is_equal("1.2%")
	assert_str(Chart.percent_text(0.1234)).is_equal("12%")
	assert_str(Chart.percent_text(0.0999)).is_equal("10%")
	assert_str(Chart.percent_text(1.0)).is_equal("100%")
	# Something known is never "0%".
	assert_str(Chart.percent_text(0.000000002)).is_not_equal("0%")
	assert_str(Chart.percent_text(0.0)).is_equal("0%")
	var founding:=build([circle(0,0,72)])
	assert_str(WorldGlobe.headline_words(founding.stats)).is_equal("We know about 0.0032% of the world.")


func test_growth_comes_from_the_records_own_days()->void:
	var chart:=build([circle(0,0,72,"founding knowledge",0),trail([Vector2(0,0),Vector2(2000,0)],18.0,"returned scout trail",3000),trail([Vector2(0,0),Vector2(0,-2000)],18.0,"returned scout trail",4200)])
	var then:float=chart.known_fraction_at(4200-3650)
	assert_float(then).is_equal_approx(PI*72.0*72.0/Chart.surface_km2(),then*0.01)
	var words:=WorldGlobe.growth_words(chart,4200,true)
	assert_str(words).is_equal("Up from %s ten winters ago." % Chart.percent_text(then))
	assert_str(WorldGlobe.growth_words(chart,4200,false)).contains("ten years ago")
	# A young world with nothing earlier to compare says nothing.
	var young:=build([circle(0,0,72,"founding knowledge",0)])
	assert_str(WorldGlobe.growth_words(young,200,true)).is_equal("")
	# A few years in, it compares with the founding.
	var few:=build([circle(0,0,72,"founding knowledge",0),trail([Vector2(0,0),Vector2(900,0)],18.0,"returned scout trail",800)])
	assert_str(WorldGlobe.growth_words(few,1200,true)).starts_with("Up from 0.0032% when we first settled")


func test_zoom_out_past_the_far_lands_opens_the_world_view()->void:
	var terrain:=terrain_fixture()
	terrain.camera.size=terrain._distance_camera_size(2)
	terrain._step_camera_distance(Vector2.ZERO,1.0)
	assert_int(terrain.opened).is_equal(0)
	assert_int(terrain.camera_distance_level()).is_equal(3)
	terrain.camera.size=terrain._distance_camera_size(3);terrain.zoom_target_size=-1.0;terrain.zoom_preset_active=false
	terrain.distance_input_msec=-100000
	terrain._step_camera_distance(Vector2.ZERO,1.0)
	assert_int(terrain.opened).is_equal(1)
	# The map itself stays where it was, ready for Close.
	assert_float(terrain.camera.size).is_equal_approx(terrain._distance_camera_size(3),0.001)
	# Fine (shift) zoom opens it once the map is well past the far lands.
	terrain.camera.size=terrain._distance_camera_size(3)*1.5
	terrain._queue_camera_zoom(Vector2.ZERO,1.0)
	assert_int(terrain.opened).is_equal(1)
	terrain.camera.size=terrain._distance_camera_size(3)*terrain.WORLD_VIEW_ZOOM_RATIO
	terrain._queue_camera_zoom(Vector2.ZERO,1.0)
	assert_int(terrain.opened).is_equal(2)
	# Zooming in never opens it.
	terrain._queue_camera_zoom(Vector2.ZERO,-1.0)
	assert_int(terrain.opened).is_equal(2)


func test_zoom_in_on_the_globe_returns_to_the_map()->void:
	var rest:=4.3
	var step:=WorldGlobe.zoom_goal(rest,-1.0,rest)
	assert_bool(bool(step.leave)).is_false()
	assert_float(float(step.distance)).is_less(rest)
	# Closing in stops at the nearest globe view, and one more step hands over.
	var goal:=rest
	for notch in 30:
		var next:=WorldGlobe.zoom_goal(goal,-1.0,rest)
		if bool(next.leave):break
		goal=float(next.distance)
	assert_float(goal).is_equal_approx(WorldGlobe.NEAR_DISTANCE,0.0001)
	assert_bool(bool(WorldGlobe.zoom_goal(goal,-1.0,rest).leave)).is_true()
	# Zooming out stops a little past the resting view.
	assert_float(float(WorldGlobe.zoom_goal(rest,5.0,rest).distance)).is_less_equal(rest*1.12)


func test_world_view_hands_the_map_back_over_a_place()->void:
	var terrain:=terrain_fixture()
	terrain._world_view_arrive(Vector2(1234.0,-567.0))
	assert_float(terrain.camera_target.x).is_equal_approx(1234.0,0.001)
	assert_float(terrain.camera_target.z).is_equal_approx(-567.0,0.001)
	assert_float(terrain.camera.size).is_equal_approx(terrain._distance_camera_size(3),0.001)
	assert_float(terrain.zoom_target_size).is_less(0.0)
	# The globe opens at the scale the map was showing.
	var match_distance:=WorldGlobe.map_match_distance(terrain.camera.size,tan(deg_to_rad(WorldGlobe.FOV_DEGREES*0.5)))
	assert_float(match_distance).is_between(1.2,2.0)


func test_click_on_the_globe_flies_to_the_place_under_the_pointer()->void:
	var center:=Vector2(1100,550)
	var half_height:=540.0
	var tan_half:=tan(deg_to_rad(15.0))
	for place:Vector2 in [Vector2(0,0),Vector2(812.5,-2210.0),Vector2(-15300.0,7400.0),Vector2(19950.0,-8800.0),Vector2(-19990.0,120.0)]:
		var lat_lon:=Chart.lat_lon(place)
		for distance:float in [4.3,1.9]:
			# Looking a little away from the place, so it is off-centre on screen.
			var basis:=Chart.view_basis(clampf(lat_lon.x-0.12,-1.5,1.5),lat_lon.y+0.2)
			var screen:=Chart.globe_to_screen(Chart.globe_vector(lat_lon.x,lat_lon.y),center,half_height,distance,tan_half,basis)
			assert_float(screen.z).is_greater(0.0)
			var back:=Chart.map_point_at(Vector2(screen.x,screen.y),center,half_height,distance,tan_half,basis)
			var error:=Vector2(wrapf(back.x-place.x,-Chart.WIDTH_KM*0.5,Chart.WIDTH_KM*0.5),back.y-place.y).length()
			assert_float(error).override_failure_message("%s came back as %s" % [place,back]).is_less(1.0)
	# The far side of the world faces away, and empty sky is not a place.
	var front:=Chart.view_basis(0.0,0.0)
	assert_float(Chart.globe_to_screen(Chart.globe_vector(0.0,PI),center,half_height,4.3,tan_half,front).z).is_less(0.0)
	assert_vector(Chart.map_point_at(Vector2(5,5),center,half_height,4.3,tan_half,front)).is_equal(Vector2.INF)
	# The globe's centre is the place it faces.
	var faced:=Chart.map_point_at(center,center,half_height,4.3,tan_half,Chart.view_basis(Chart.lat_lon(Vector2(3000,-1500)).x,Chart.lat_lon(Vector2(3000,-1500)).y))
	assert_float(faced.distance_to(Vector2(3000,-1500))).is_less(0.5)


func test_measuring_adds_no_saved_state()->void:
	var before:=JSON.stringify(CivilizationSystem.export_state())
	var chart:RefCounted=Chart.new()
	var areas:Array=CivilizationSystem.revealed_areas
	chart.refresh(areas,int(GameState.world_seed),Callable(),Callable(),false)
	assert_str(JSON.stringify(CivilizationSystem.export_state())).is_equal(before)


func test_routes_mark_walked_lines_only_near_them()->void:
	var chart:=build([circle(3000,0,80),trail([Vector2(0,0),Vector2(900,300)],18.0)])
	var routes:Image=chart.routes
	assert_int(routes.get_width()).is_equal(Chart.ROUTE_COLUMNS)
	var data:=routes.get_data()
	var marked:=0
	var astray:=0
	var sides:={}
	var a:=Chart.route_texel(Vector2(0,0))
	var b:=Chart.route_texel(Vector2(900,300))
	for texel in Chart.ROUTE_COLUMNS*Chart.ROUTE_ROWS:
		if data[texel*2+1]==0:continue
		marked+=1
		var p:=Vector2(float(texel%Chart.ROUTE_COLUMNS),float(texel/Chart.ROUTE_COLUMNS))
		if p.distance_to(Geometry2D.get_closest_point_to_segment(p,a,b))>Chart.ROUTE_RANGE:astray+=1
		sides[signi(data[texel*2]-128)]=true
	# The trail is marked on both sides of its line; the circle has no route.
	assert_int(marked).is_greater(40)
	assert_int(astray).is_equal(0)
	assert_bool(sides.has(1) and sides.has(-1)).is_true()


func test_background_prewarm_draws_the_shared_chart()->void:
	WorldGlobe.prewarm(null)
	var model:RefCounted=Chart.shared()
	model.finish()
	assert_bool(model.current(int(GameState.world_seed))).is_true()
	assert_float(float(model.stats.known_fraction)).is_greater_equal(0.0)


func test_world_view_opens_counts_what_is_known_and_closes_cleanly()->void:
	var host:Node=auto_free(Node.new())
	add_child(host)
	var view:Control=WorldGlobe.open(host,null,false)
	assert_object(view).is_not_null()
	view.chart.finish()
	view._process(0.016)
	assert_str(String(view.headline.text)).is_not_empty()
	# Captions stay neutral: nothing claims the world is round.
	for words:String in [view.headline.text,view.growth.text,view.hint_label.text,WorldGlobe._hint_words()]:
		for word:String in words.to_lower().replace("."," ").replace(","," ").split(" ",false):
			assert_bool(word in ["round","globe","sphere","planet","spherical"]).override_failure_message("caption says '%s'" % word).is_false()
	assert_str(String(view.close_button.text)).is_equal("Back to the map")
	# Open, the map beneath need not draw; closing hands it back.
	view.opacity=1.0
	view.phase="open"
	view._process(0.016)
	assert_bool(get_viewport().disable_3d).is_true()
	view.close()
	assert_bool(get_viewport().disable_3d).is_false()
	await await_millis(600)
	assert_bool(is_instance_valid(view)).is_false()

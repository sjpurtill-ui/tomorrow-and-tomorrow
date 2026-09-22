extends GdUnitTestSuite
const Samples=preload("res://scripts/settlement_surface_samples.gd")
class Terrain extends "res://scripts/local_terrain.gd":
	func _ready()->void:pass
	func _process(_delta:float)->void:pass
class ReferenceFood extends "res://scripts/food_system.gd":
	func original(horizon:int,projected_stocks:Dictionary,harvest:Dictionary,seasons:Dictionary,weather:Dictionary,environment:Dictionary,climate_days:Dictionary,current_day:float,non_climate:float,ration_factor:float,inaccessible_army_rations:float,storage_multiplier:float,preservation:Dictionary,milestones:Dictionary)->Dictionary:
		# Keep the same daily arithmetic and consumption order, using local numeric
		# arrays instead of repeatedly resolving string-keyed stock dictionaries.
		var amounts:Array[float]=[];var yields:Array[float]=[];var season:Array[float]=[];var weather_now:Array[float]=[];var spoil:Array[float]=[];var preserve:Array[float]=[]
		for food_type:String in FOOD_TYPES:
			amounts.append(float(projected_stocks.get(food_type,0.0)))
			spoil.append(float(SPOILAGE[food_type]));preserve.append(float(preservation[food_type]))
			if food_type!="Preserved food":
				yields.append(float(harvest.get(food_type,0.0)));season.append(float(seasons[food_type]));weather_now.append(float(weather[food_type]))
		var first_shortage:=-1;var total_produced:=0.0;var total_required:=0.0;var total_spoiled:=0.0
		for offset:int in range(1,horizon+1):
			var future_day:=current_day+float(offset)
			var climate:=_forecast_climate(environment,future_day,climate_days)
			for i:int in 4:
				var factors:Array=climate[FOOD_TYPES[i]]
				var produced:=yields[i]*float(factors[0])/season[i]*float(factors[1])/weather_now[i]
				amounts[i]+=produced;total_produced+=produced
			var season_wave:=sin(fmod(future_day,365.0)/365.0*TAU)
			var future_climate:=non_climate*maxf(0.0,-season_wave)*0.06
			var required:=maxf(0.0,(non_climate+future_climate)*ration_factor-inaccessible_army_rations)
			total_required+=required
			for i:int in 5:
				var loss:=amounts[i]*spoil[i]*storage_multiplier*preserve[i]
				amounts[i]=maxf(0.0,amounts[i]-loss);total_spoiled+=loss
			var remaining:=required
			for i:int in [2,1,0,3,4]:
				var eaten:=minf(remaining,amounts[i])
				amounts[i]-=eaten;remaining-=eaten
				if remaining<=.001:break
			if required-remaining<required*.98 and first_shortage<0:first_shortage=offset
			if offset==30 or offset==horizon:
				for i:int in 5:projected_stocks[FOOD_TYPES[i]]=amounts[i]
				milestones[offset]=_forecast_summary(offset,projected_stocks,current_day,non_climate,ration_factor,inaccessible_army_rations,first_shortage,total_produced,total_required,total_spoiled)
		return milestones.get(horizon,{})

var height_calls:=0
var land_calls:=0
func sample_height(x:float,z:float)->float:
	height_calls+=1;return x*1.731+z*.329
func sample_land(p:Vector2)->bool:
	land_calls+=1;return p.x>=0
func test_exact_samples_reused_without_rounding_or_cross_build_staleness()->void:
	height_calls=0;land_calls=0
	var samples:=Samples.new(sample_height,sample_land)
	var first:=samples.height_at(5000.0000001,12.0)
	assert_float(samples.height_at(5000.0000001,12.0)).is_equal(first)
	samples.height_at(5000.0000002,12.0)
	assert_int(height_calls).is_equal(2)
	assert_bool(samples.land_at(Vector2.ONE)).is_true();assert_bool(samples.land_at(Vector2.ONE)).is_true()
	assert_int(land_calls).is_equal(1)
	var next:=Samples.new(sample_height,sample_land);next.height_at(5000.0000001,12.0)
	assert_int(height_calls).is_equal(3)
func test_small_fabric_is_camera_independent_but_large_or_dispersed_is_bounded()->void:
	var old_plots:=GameState.settlement_plots;var old_routes:=GameState.settlement_routes
	GameState.settlement_plots=[{"id":1,"centroid":Vector2.ZERO}];GameState.settlement_routes=[]
	var terrain:Terrain=auto_free(Terrain.new());terrain.camera=auto_free(Camera3D.new())
	for zoom:float in [.1,1,3,20,2000]:
		terrain.camera.size=zoom;terrain.camera_target=Vector3(zoom,0,-zoom)
		assert_int(terrain._settlement_morphology_lod()).is_equal(1)
		assert_str(terrain._settlement_morphology_view_signature(1)).is_equal("1")
	GameState.settlement_plots[0].centroid=Vector2(2,0)
	assert_bool(terrain._retain_small_settlement_fabric()).is_false()
	GameState.settlement_plots[0].centroid=Vector2.ZERO
	GameState.settlement_routes=[{"points":PackedVector2Array([Vector2.ZERO,Vector2(3,0)])}]
	assert_bool(terrain._retain_small_settlement_fabric()).is_false()
	GameState.settlement_routes=[]
	for i in 97:GameState.settlement_plots.append({"id":i+2,"centroid":Vector2.ZERO})
	assert_bool(terrain._retain_small_settlement_fabric()).is_false()
	GameState.settlement_plots=old_plots;GameState.settlement_routes=old_routes
func test_forecast_kernel_matches_original_exactly_across_shortages_and_seasons()->void:
	var food:ReferenceFood=auto_free(ReferenceFood.new())
	var rng:=RandomNumberGenerator.new();rng.seed=947
	var environment:=PlanetEnvironment.profile_at(Vector2.ZERO)
	var original_usec:=0;var optimized_usec:=0
	for example in 40:
		var stocks:Dictionary={};var harvest:Dictionary={};var seasons:Dictionary={};var weather:Dictionary={};var preservation:Dictionary={}
		for name:String in food.FOOD_TYPES:
			stocks[name]=rng.randf_range(0,5000);preservation[name]=rng.randf_range(.2,1.2)
			if name!="Preserved food":harvest[name]=rng.randf_range(0,100);seasons[name]=rng.randf_range(.1,1.5);weather[name]=rng.randf_range(.5,1.5)
		var day:=float(example*147);var demand:=rng.randf_range(20,600);var ration:=rng.randf_range(.6,1.4);var inaccessible:=rng.randf_range(0,10)
		var old_m:Dictionary={};var new_m:Dictionary={};var old_stock:=stocks.duplicate();var new_stock:=stocks.duplicate();var climate:Dictionary={}
		# Warm deterministic climate so both implementations read identical caches.
		for offset in 91:food._forecast_climate(environment,day+offset,climate)
		var started:=Time.get_ticks_usec()
		var original:=food.original(90,old_stock,harvest,seasons,weather,environment,climate,day,demand,ration,inaccessible,.72,preservation,old_m)
		original_usec+=Time.get_ticks_usec()-started
		started=Time.get_ticks_usec()
		var actual:=food._forecast_ordinary(90,new_stock,harvest,seasons,weather,environment,climate,day,demand,ration,inaccessible,.72,preservation,new_m)
		optimized_usec+=Time.get_ticks_usec()-started
		assert_dict(actual).is_equal(original);assert_dict(new_m).is_equal(old_m);assert_dict(new_stock).is_equal(old_stock)
	print("FORECAST_KERNEL original_us=",original_usec," optimized_us=",optimized_usec)

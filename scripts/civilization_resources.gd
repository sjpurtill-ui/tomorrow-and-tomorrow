extends RefCounted
## World geology is keyed by location, never owner. Each society keeps its own
## survey/access records; extraction draws on one shared physical reserve.
static func initialize(origin:Vector2)->void:
	var state:=WorldSimulation.state
	if not state.resource_deposits.is_empty():return
	if WorldSimulation.water_provider.is_valid():
		var source:Vector3=WorldSimulation.water_provider.call(Vector3(origin.x,0,origin.y))
		if source!=Vector3.ZERO and origin.distance_to(Vector2(source.x,source.z))<=72:
			state.resource_deposits.append(WorldSimulation.resources._deposit("Freshwater",source,1.0,1000,0,"world_hydrology"))
	var grid:=Vector2i(floori(origin.x/16),floori(origin.y/16))
	for x in range(grid.x-1,grid.x+2):
		for z in range(grid.y-1,grid.y+2):
			var center:=Vector2((x+.5)*16,(z+.5)*16)
			var context:=preload("res://scripts/civilization_day.gd").context(center)
			var profile:Dictionary=context.environment_profile
			var potentials:Dictionary=profile.get("resource_potentials",{})
			for resource:String in WorldSimulation.resources.catalog:
				var key:="%d:%d:%s" % [x,z,resource]
				var rng:=RandomNumberGenerator.new();rng.seed=hash("%d:%s" % [state.world_seed,key])
				var potential:=float(potentials.get(resource,0))
				if potential<.14 or rng.randf()>.08+potential*.58:continue
				var point:=center+Vector2(rng.randf_range(-7,7),rng.randf_range(-7,7))
				if not WorldSimulation.world._scout_land_at(point):continue
				if resource in ["Freshwater","Timber","Fiber Plants"]:continue # Continuous measured river access owns water.
				var amount:=rng.randf_range(700,8500)*(.45+potential)
				var deposit:=WorldSimulation.resources._deposit(resource,Vector3(point.x,0,point.y),rng.randf_range(.38,.82)+potential*.58,amount,state.resource_deposits.size(),"world_geology",potential,String(profile.get("signature","")))
				deposit["world_key"]=key
				if WorldSimulation.world._position_is_revealed(point):WorldSimulation.resources._seed_founding_surface_recognition(deposit)
				if not WorldSimulation.geography_stock.has(key):WorldSimulation.geography_stock[key]={"remaining":amount,"initial_amount":amount,"last_day":int(state.elapsed_days)}
				deposit.remaining=WorldSimulation.geography_stock[key].remaining
				state.resource_deposits.append(deposit)

static func survey_founding_camp(origin:Vector2)->Dictionary:
	## Camp study records only what founders can recognize from the surface. It
	## also materializes the deterministic geology cell beneath the new region so
	## later inquiry has real local deposits to discover, without exposing them.
	_ensure_geology_cell(Vector2i(floori(origin.x/16.0),floori(origin.y/16.0)))
	var context:Dictionary={}
	if WorldSimulation.context_provider.is_valid():context=WorldSimulation.context_provider.call(origin)
	var recognized:Array[String]=[]
	var fields:Dictionary=context.get("surface_material_catchments",{})
	var surface_definitions:={
		"Timber":{"field":context.get("woodland_catchment",fields.get("Timber",{})),"source":"woodland_catchment","stock":600.0,"minimum":0.08},
		"Stone":{"field":fields.get("Stone",{}),"source":"surface_stone_catchment","stock":1000.0,"minimum":0.03},
		"Fiber Plants":{"field":fields.get("Fiber Plants",{}),"source":"plant_fiber_catchment","stock":180.0,"minimum":0.08}
	}
	for resource:String in surface_definitions:
		var definition:Dictionary=surface_definitions[resource]
		var field:Dictionary=definition.field
		if float(field.get("density",0.0))<float(definition.minimum):continue
		var deposit:=surface(resource,String(definition.source),field,float(definition.stock))
		if not _has_world_key(String(deposit.get("world_key",""))):
			WorldSimulation.resources._seed_founding_surface_recognition(deposit)
			WorldSimulation.state.resource_deposits.append(deposit)
		recognized.append(resource)
	var profile:Dictionary=context.get("environment_profile",{})
	var potentials:Dictionary=profile.get("resource_potentials",{})
	for resource:String in ["Fertile Soil","Game"]:
		var potential:=clampf(float(potentials.get(resource,0.0)),0.0,1.0)
		if potential<0.16:continue
		var tile:=Vector2i(floori(origin.x/3.0),floori(origin.y/3.0))
		var key:="camp_surface:%d:%d:%s" % [tile.x,tile.y,resource]
		if not _has_world_key(key):
			var center:=Vector2((tile.x+0.5)*3.0,(tile.y+0.5)*3.0)
			var amount:=maxf(1.0,9.0*potential*(260.0 if resource=="Game" else 1400.0))
			var deposit:=WorldSimulation.resources._deposit(resource,Vector3(center.x,0.0,center.y),0.45+potential*0.65,amount,WorldSimulation.state.resource_deposits.size(),"founding_camp_surface",potential,String(profile.get("signature","")))
			deposit["world_key"]=key
			deposit["landscape_source"]="game_catchment" if resource=="Game" else "fertile_soil_catchment"
			WorldSimulation.resources._seed_founding_surface_recognition(deposit)
			WorldSimulation.geography_stock[key]={"remaining":amount,"initial_amount":amount,"last_day":int(WorldSimulation.state.elapsed_days)}
			WorldSimulation.state.resource_deposits.append(deposit)
		recognized.append(resource)
	return {"recognized":recognized,"context":context}

static func _ensure_geology_cell(grid:Vector2i)->void:
	var state:=WorldSimulation.state
	var center:=Vector2((grid.x+0.5)*16.0,(grid.y+0.5)*16.0)
	var context:=preload("res://scripts/civilization_day.gd").context(center)
	var profile:Dictionary=context.environment_profile
	var potentials:Dictionary=profile.get("resource_potentials",{})
	for resource:String in WorldSimulation.resources.catalog:
		if resource in ["Freshwater","Timber","Fiber Plants"]:continue
		var key:="%d:%d:%s" % [grid.x,grid.y,resource]
		if _has_world_key(key):continue
		var rng:=RandomNumberGenerator.new();rng.seed=hash("%d:%s" % [state.world_seed,key])
		var potential:=float(potentials.get(resource,0.0))
		if potential<0.14 or rng.randf()>0.08+potential*0.58:continue
		var point:=center+Vector2(rng.randf_range(-7.0,7.0),rng.randf_range(-7.0,7.0))
		if not WorldSimulation.world._scout_land_at(point):continue
		var amount:=rng.randf_range(700.0,8500.0)*(0.45+potential)
		var deposit:=WorldSimulation.resources._deposit(resource,Vector3(point.x,0.0,point.y),rng.randf_range(0.38,0.82)+potential*0.58,amount,state.resource_deposits.size(),"world_geology",potential,String(profile.get("signature","")))
		deposit["world_key"]=key
		if WorldSimulation.world._position_is_revealed(point) and resource in WorldSimulation.resources.FOUNDING_SURFACE_RESOURCES:
			WorldSimulation.resources._seed_founding_surface_recognition(deposit)
		WorldSimulation.geography_stock[key]={"remaining":amount,"initial_amount":amount,"last_day":int(state.elapsed_days)}
		state.resource_deposits.append(deposit)

static func _has_world_key(key:String)->bool:
	if key=="":return false
	for deposit_variant in WorldSimulation.state.resource_deposits:
		if String((deposit_variant as Dictionary).get("world_key",""))==key:return true
	return false
static func available(deposit:Dictionary)->void:
	if not deposit.has("world_key"):return
	var reserve:Dictionary=WorldSimulation.geography_stock.get(deposit.world_key,{})
	if reserve.is_empty():return
	if String(deposit.get("landscape_source","")) in ["woodland_catchment","plant_fiber_catchment"]:
		var day:=int(WorldSimulation.state.elapsed_days)
		var days:=maxi(0,day-int(reserve.get("last_day",day)))
		var recovery:=.001 if deposit.landscape_source=="plant_fiber_catchment" else .00003
		reserve.remaining=minf(float(reserve.initial_amount),float(reserve.remaining)+float(reserve.initial_amount)*recovery*days)
		reserve.last_day=day
	deposit.remaining=reserve.remaining
static func withdraw(deposit:Dictionary,requested:float)->float:
	if not deposit.has("world_key"):return minf(float(deposit.remaining),requested)
	available(deposit)
	var amount:=minf(float(deposit.remaining),requested)
	WorldSimulation.geography_stock[deposit.world_key].remaining-=amount
	return amount
static func renew(deposit:Dictionary,extracted:float)->void:
	if not deposit.has("world_key"):return
	var reserve:Dictionary=WorldSimulation.geography_stock[deposit.world_key]
	# Original renewable replenishment follows actual extraction, not observer count.
	if not deposit.has("landscape_source") and bool(WorldSimulation.resources.catalog[String(deposit.resource)].renewable):reserve.remaining+=minf(extracted*.35,2)
	deposit.remaining=reserve.remaining

static func surface(resource:String,source:String,field:Dictionary,stock_per_km2:float)->Dictionary:
	var point:Vector3=field.get("position",WorldSimulation.state.settlement_founded_at)
	var tile:=Vector2i(floori(point.x/3),floori(point.z/3))
	var center:=Vector2((tile.x+.5)*3,(tile.y+.5)*3)
	var key:="surface:%d:%d:%s" % [tile.x,tile.y,resource]
	var density:=float(field.get("density",0))
	if WorldSimulation.context_provider.is_valid():
		var actual:Dictionary=WorldSimulation.context_provider.call(center)
		var measured:Dictionary=actual.get("woodland_catchment",{}) if resource=="Timber" else actual.get("surface_material_catchments",{}).get(resource,{})
		if not measured.is_empty():density=float(measured.get("density",0))
	var amount:=9*density*stock_per_km2
	var deposit:=WorldSimulation.resources._deposit(resource,Vector3(center.x,0,center.y),.45+density*.65,amount,WorldSimulation.state.resource_deposits.size(),"local_surface",density)
	deposit.merge({"world_key":key,"landscape_source":source,"surface_density":density,"area_km2":9.0},true)
	if not WorldSimulation.geography_stock.has(key):WorldSimulation.geography_stock[key]={"remaining":amount,"initial_amount":amount,"last_day":int(WorldSimulation.state.elapsed_days)-1}
	available(deposit)
	return deposit

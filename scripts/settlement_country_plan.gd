extends RefCounted
## Read-only, bounded country drawings. Coordinates are world x/z kilometres.
## The engine owns all three reaches, people, knowledge and deposit history.
## A representative is a sample of lived-in land, never another settlement.
const OneSeat:=preload("res://scripts/one_seat.gd")
const RealmReach:=preload("res://scripts/realm_reach.gd")
const Extent:=preload("res://scripts/settlement_visual_extent.gd")
const Roads:=preload("res://scripts/settlement_roads.gd")
const Era:=preload("res://scripts/settlement_country_era.gd")
const Growth:=preload("res://scripts/settlement_country_growth.gd")
const MAX_HOMESTEADS:=144
const MAX_CLUSTERS:=Growth.MAX_SEEDS
const MAX_FAR_HOLDINGS:=48
const MAX_HERDERS:=10
const MAX_SITES:=96
const CELL_KM:=6.0
const MAX_WORKED_KM:=120.0
const PEOPLE_PER_REPRESENTATIVE:=100.0
const SURFACE_SOURCES:=["woodland_catchment","surface_stone_catchment","plant_fiber_catchment"]


## Call synchronously inside the requested WorldSimulation scope. The optional
## realm is the owner's already-computed RealmReach record (required for rivals).
## Deposits are read by reference until build(); plans contain only copied scalars.
## In particular, do not derive a rival's worked reach from its political border:
## one_seat currently gives rival actors core-only worked land.
static func capture_current(realm:Dictionary={})->Dictionary:
	var state=WorldSimulation.state
	var owner:=String(WorldSimulation.actor_id)
	if realm.is_empty() and owner=="player":realm=RealmReach.ours()
	var origin:=Vector2(state.settlement_founded_at.x,state.settlement_founded_at.z)
	var seat:=OneSeat.seat_record()
	if seat.get("position") is Vector2:origin=seat.position
	if realm.get("center") is Vector2:origin=realm.center
	var knowledge:Array=state.known_discoveries.duplicate()
	for entry:Variant in state.discovery_log:
		if entry is Dictionary:
			var id:=String(entry.get("id",""))
			if not id.is_empty() and id not in knowledge:knowledge.append(id)
	var fabric:Dictionary=state.built_fabric.duplicate(true)
	var appearance:=Era.capture(knowledge,fabric,state.settlement_plots)
	var root:=_root_fabric(state.settlement_plots)
	var population:=maxf(0.0,float(state.population_exact))
	var stage:=OneSeat.stage()
	return {"owner":owner,"origin":origin,"population":population,
		"core_km":OneSeat.core_km(),"worked_km":OneSeat.reach_km(),
		"dense_radius_km":dense_radius(roundi(population),float(appearance.plot_radius_km)),
		"realm_km":float(realm.get("reach",0.0)),"stage":String(stage.id),
		"seed":int(state.world_seed),"knowledge":knowledge,"built_fabric":fabric,
		"road_tier":Roads.known_tier(state),"deposits":state.resource_deposits,
		"country_appearance":appearance,"appearance_signature":appearance_signature(knowledge,fabric,appearance),
		"root_fabric":root,"root_geometry_signature":hash(root),
		"founded":bool(state.settlement_site_committed)}


## Constant-size retained key once a snapshot has been captured. Site count
## changes are immediate; in-place work/depletion changes require signature().
## Population bins change at about 4%, leaving old geometry attached in between.
static func quick_signature(snapshot:Dictionary)->int:
	var appearance:=int(snapshot.appearance_signature) if snapshot.has("appearance_signature") else appearance_signature(snapshot.get("knowledge",[]),snapshot.get("built_fabric",{}),snapshot.get("country_appearance",{}))
	return hash([String(snapshot.get("owner","player")),snapshot.get("origin",Vector2.ZERO),
		int(snapshot.get("seed",0)),bool(snapshot.get("founded",true)),
		float(snapshot.get("core_km",0.0)),float(snapshot.get("worked_km",0.0)),
		floori(_snapshot_dense_radius(snapshot)/0.025),
		floori(float(snapshot.get("realm_km",0.0))/3.0),String(snapshot.get("stage","settlement")),
		population_bucket(float(snapshot.get("population",0.0))),
		int(snapshot.get("road_tier",0)),appearance,int(snapshot.get("root_geometry_signature",0)),
		(snapshot.get("deposits",[]) as Array).size()])


## O(N real deposits), with no geometry or population-sized work. There is no
## resource visual revision in the simulation; the renderer checks this once
## per visual refresh day, never per frame. Resource amounts are bucketed by
## visible depletion/regrowth state, not by the daily load removed.
static func signature(snapshot:Dictionary)->int:
	var key:=quick_signature(snapshot)
	for item:Variant in snapshot.get("deposits",[]):
		if not item is Dictionary:continue
		var deposit:Dictionary=item
		if not _eligible(deposit):continue
		var state:=site_state(deposit)
		key=hash([key,String(deposit.get("id","")),deposit.get("position",Vector3.ZERO),
			String(deposit.get("resource","")),String(deposit.get("landscape_source","")),
			state.category,state.age])
	return key


static func population_bucket(people:float)->int:
	return floori(log(maxf(1.0,people))*24.0)*2+(1 if people>=400.0 else 0)


static func appearance_signature(knowledge:Array,fabric:Dictionary,profile:Dictionary={})->int:
	var rendered_profile:=profile if not profile.is_empty() else Era.capture(knowledge,fabric)
	return Era.signature(rendered_profile)


## OneSeat.core_km is a carrier's worked radius, not the dense built footprint.
## Match the town renderer's population and recorded-polygon extent instead.
static func dense_radius(population:int,plot_radius_km:float=0.0)->float:
	return clampf(maxf(Extent.radius(population),plot_radius_km*1.05),0.12,340.0)


static func _snapshot_dense_radius(snapshot:Dictionary)->float:
	if snapshot.has("dense_radius_km"):return clampf(float(snapshot.dense_radius_km),0.12,340.0)
	return dense_radius(roundi(float(snapshot.get("population",0.0))),float((snapshot.get("country_appearance",{}) as Dictionary).get("plot_radius_km",0.0)))


static func build(snapshot:Dictionary)->Dictionary:
	var population:=maxf(0.0,float(snapshot.get("population",0.0)))
	var core:=maxf(0.0,float(snapshot.get("core_km",0.0)))
	var worked:=maxf(core,float(snapshot.get("worked_km",core)))
	var realm:=maxf(0.0,float(snapshot.get("realm_km",0.0)))
	var area:=PI*maxf(0.0,worked*worked-core*core)
	var dense:=_snapshot_dense_radius(snapshot)
	var holdings_area:=PI*maxf(0.0,worked*worked-dense*dense)
	var appearance:Dictionary=snapshot.get("country_appearance",{})
	if appearance.is_empty():appearance=Era.capture(snapshot.get("knowledge",[]),snapshot.get("built_fabric",{}))
	var out:={"owner":String(snapshot.get("owner","player")),
		"origin":snapshot.get("origin",Vector2.ZERO),"population":population,
		"rings":{"core_km":core,"worked_km":worked,"realm_km":realm,
			"band_area_km2":area,"density":population/maxf(1.0,area)},
		"visual_core_km":dense,"holdings_area_km2":holdings_area,
		"holdings_density":population/maxf(1.0,holdings_area),
		"stage":String(snapshot.get("stage","settlement")),"road_tier":int(snapshot.get("road_tier",0)),
		"knowledge":(snapshot.get("knowledge",[]) as Array).duplicate(),
		"built_fabric":(snapshot.get("built_fabric",{}) as Dictionary).duplicate(true),
		"country_appearance":Era.render_profile(appearance),
		"homesteads":[],"herders":[],"sites":[],"bounded":true}
	if population<=0.0 or not bool(snapshot.get("founded",true)):return out
	if population>=400.0 and worked>0.15:
		out.homesteads=_clusters(snapshot,dense,core,worked,population)
		out.homesteads.append_array(_homesteads(snapshot,dense,core,worked,population,holdings_area))
		out.homesteads.sort_custom(_nearer)
	if population>=400.0 and realm>worked+6.0:
		out.herders=_herders(snapshot,worked,realm,population)
	out.sites=_sites(snapshot)
	return out


## New local nuclei accrete from inherited claims with the root's own selector.
## Their positions do not depend on the population radius or a distant field.
## Parcel growth is deferred one claim per renderer step, not built in this scan.
static func _clusters(snapshot:Dictionary,_dense:float,core:float,worked:float,people:float)->Array:
	var origin:Vector2=snapshot.get("origin",Vector2.ZERO)
	var owner:=String(snapshot.get("owner","player"))
	var seed_value:=hash("%s:%d:root_growth" % [owner,int(snapshot.get("seed",0))])
	var allowance:=clampi(1+floori(sqrt(people/400.0)*1.7),2,MAX_CLUSTERS)
	var centres:=Growth.centres(seed_value,MAX_CLUSTERS,0.085)
	var root:Dictionary=snapshot.get("root_fabric",{})
	var records:Array=[]
	for index in mini(allowance,centres.size()):
		var offset:Vector2=centres[index]
		if offset.length()>=worked:continue
		var id:="seed:%s:%d:%d" % [owner,int(snapshot.get("seed",0)),index]
		var count:=clampi(6+floori(log(maxf(1.0,people/(160.0*float(index+1))))*7.0),6,Growth.MAX_PARCELS)
		var obstacles:=seed_obstacles(root,offset)
		var neighbours:Array[Vector2]=[]
		for other in centres.size():
			if other!=index:neighbours.append(centres[other]-offset)
		var spec:={"seed":hash(id),"parcels":count,"templates":(root.get("templates",[]) as Array).duplicate(true),"obstacles":obstacles,"neighbours":neighbours}
		records.append({"id":id,"category":"homestead","kind":"cluster","position":origin+offset,"offset":offset,
			"distance_km":offset.length(),"location_class":"worked_core" if offset.length()<=core else "homestead_band",
			"field_radius_km":0.10,"rotation":0.0,"buildings":count,"road_tier":_country_road_tier(snapshot,0.0),
			"settlement_growth":spec,"geometry_signature":hash(spec)})
	return records

## Current root claims in the fixed seed's own coordinates. Established seeds
## use the same mask even when a population sampling allowance temporarily falls.
static func seed_obstacles(root:Dictionary,offset:Vector2)->Array:
	var obstacles:Array=[]
	for claim:Dictionary in root.get("claims",[]):
		if Vector2(claim.centroid).distance_to(offset)>0.32:continue
		var polygon:=PackedVector2Array()
		for point:Vector2 in claim.polygon:polygon.append(point-offset)
		obstacles.append({"id":-1-obstacles.size(),"centroid":Vector2(claim.centroid)-offset,"polygon":polygon,"land_use":"occupied","status":"active"})
		if obstacles.size()>=Growth.MAX_OBSTACLES:break
	return obstacles

## Copy only bounded geometry and completed residential appearances. Fields do
## not erase whole circles of possible settlement. No ledger objects are retained.
static func _root_fabric(plots:Array)->Dictionary:
	var claims:Array=[];var templates:Array=[];var seen:Dictionary={}
	for plot:Dictionary in plots:
		if String(plot.get("status","active")) in ["ruin","reclaimed","abandoned"]:continue
		if String(plot.get("land_use","")) not in ["residential_compound","mixed_household","communal","civic","market","workshop","storage"]:continue
		if claims.size()<256:claims.append({"centroid":plot.get("centroid",Vector2.ZERO),"polygon":(plot.get("polygon",PackedVector2Array()) as PackedVector2Array).duplicate()})
		if templates.size()>=32 or String(plot.get("land_use","")) not in ["residential_compound","mixed_household"]:continue
		if float(plot.get("construction_progress",1.0))<0.999:continue
		var sample:Dictionary={}
		for key:String in ["form","roof_plan","material_family","material_mix","storeys","fabric_generation","building_materials","installed_components","construction_recipe"]:
			if plot.has(key):sample[key]=plot[key].duplicate(true) if plot[key] is Array or plot[key] is Dictionary else plot[key]
		var key:=hash(sample)
		# Finish follows the root household but must not add a new geometry
		# template or reshuffle the deterministic mix of expansion buildings.
		if plot.has("cultural_appearance"):sample["cultural_appearance"]=(plot.cultural_appearance as Dictionary).duplicate(true) if plot.cultural_appearance is Dictionary else {}
		if not seen.has(key):templates.append(sample);seen[key]=true
	return {"claims":claims,"templates":templates}

## Fixed, jittered world cells keep surviving representatives on precisely the
## same ground when rings or population change. Acceptance uses people per worked
## area and falls toward the soft outer edge. No candidate is snapped to a ring.
## A fixed third of the 41*41 lattice supplies at most 561 outer candidates.
static func _homesteads(snapshot:Dictionary,dense:float,core:float,worked:float,people:float,area:float)->Array:
	var origin:Vector2=snapshot.get("origin",Vector2.ZERO)
	var seed_text:="%s:%d" % [String(snapshot.get("owner","player")),int(snapshot.get("seed",0))]
	var target:=minf(float(MAX_FAR_HOLDINGS),people/PEOPLE_PER_REPRESENTATIVE)
	# The taper's area-weighted mean is about .32. Normalizing the candidate
	# acceptance by holdings area makes equal populations visibly sparser on more land.
	var probability:=target*CELL_KM*CELL_KM/maxf(1.0,area)/0.32
	var limit:=mini(20,ceili(minf(worked,MAX_WORKED_KM)/CELL_KM))
	var records:Array=[]
	for x in range(-limit,limit+1):
		for z in range(-limit,limit+1):
			if posmod(x+z,3)!=0:continue
			var id:="farm:%s:%d:%d" % [seed_text,x,z]
			var at:=Vector2(float(x)+_unit(id+":x")*0.76-0.38,float(z)+_unit(id+":z")*0.76-0.38)*CELL_KM
			var distance:=at.length()
			if distance<=dense or distance>=worked:continue
			# Carrier-core growth only reclassifies a holding. It never relocates
			# or removes one; only the actual dense fabric absorbs its ground.
			var t:=clampf(distance/maxf(0.001,worked),0.0,1.0)
			var taper:=pow(1.0-t,1.35)*0.92+0.025
			# Angular variation leaves open meadows and wooded fingers, not an
			# even circular fringe. It is fixed to this people's original ground.
			var irregular:=0.72+0.28*sin(at.angle()*5.0+_unit(seed_text)*TAU)
			var weight:=taper*irregular
			var selection:=_unit(id+":take")
			if selection>=probability*weight:continue
			records.append({"id":id,"category":"homestead","kind":"homestead",
				"location_class":"worked_core" if distance<=core else "homestead_band",
				"position":origin+at,"offset":at,"distance_km":distance,
				"field_radius_km":lerpf(0.10,0.18,_unit(id+":field")),
				"rotation":_unit(id+":angle")*TAU,"buildings":1+(1 if _unit(id+":kin")<0.18 else 0),
				"road_tier":_country_road_tier(snapshot,t),"rank":selection/maxf(0.001,weight)})
	records.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.rank)<float(b.rank))
	if records.size()>MAX_FAR_HOLDINGS:records.resize(MAX_FAR_HOLDINGS)
	records.sort_custom(_nearer)
	return records


## Very sparse, fixed-position grazing representatives. The geometric sequence
## spans a whole realm without scanning a realm-sized grid; it never depicts a town.
static func _herders(snapshot:Dictionary,worked:float,realm:float,people:float)->Array:
	var origin:Vector2=snapshot.get("origin",Vector2.ZERO)
	var seed_text:="%s:%d" % [String(snapshot.get("owner","player")),int(snapshot.get("seed",0))]
	var records:Array=[]
	var allowance:=clampi(floori(sqrt(people)/36.0),1,MAX_HERDERS)
	for index in 80:
		var id:="herd:%s:%d" % [seed_text,index]
		var distance:=18.0*pow(1.073,float(index))
		if distance<=worked+3.0 or distance>=realm*0.92:continue
		var at:=Vector2.from_angle(_unit(id+":angle")*TAU)*distance
		records.append({"id":id,"category":"herder","kind":"herder",
			"position":origin+at,"offset":at,"distance_km":distance,
			"field_radius_km":lerpf(0.055,0.085,_unit(id+":field")),
			"rotation":_unit(id+":turn")*TAU,"buildings":1,"road_tier":0,"rank":_unit(id+":take")})
	records.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.rank)<float(b.rank))
	if records.size()>allowance:records.resize(allowance)
	records.sort_custom(_nearer)
	return records


## Physical household ground, shared by the field renderer and canopy mask.
## Four tangential plots leave the central yard and gaps between neighbours
## open for paths. The envelope is not itself a cleared or cultivated disc.
## Its seed and dimensions do not depend on population, camera or elapsed day.
static func homestead_layout(record:Dictionary)->Dictionary:
	var at:Vector2=record.get("position",Vector2.ZERO)
	if record.has("settlement_growth"):return {"is_seed":true,"yard_center":at,"yard_radius_km":0.0,"envelope_radius_km":0.0,"fields":[]}
	if String(record.get("kind",""))=="cluster":return _cluster_layout(record)
	var sparse:=String(record.get("kind",record.get("category",record.get("group","")))) in ["herder","herders"]
	var id:=String(record.get("id",str(at)))
	var envelope:=clampf(float(record.get("field_radius_km",0.07 if sparse else 0.14)),0.055 if sparse else 0.10,0.085 if sparse else 0.18)
	var turn:=float(record.get("rotation",_unit(id+":layout_turn")*TAU))
	var yard_radius:=0.014 if sparse else 0.025
	var fields:Array[Dictionary]=[]
	for index in (1 if sparse else 4):
		var field_id:="%s:field:%d" % [id,index]
		var bearing:=turn+float(index)*PI*0.5+lerpf(-0.18,0.18,_unit(field_id+":bearing"))
		var radial:=envelope*lerpf(0.55,0.75,_unit(field_id+":offset"))
		fields.append({"id":field_id,"center":at+Vector2.from_angle(bearing)*radial,
			"half_length_km":maxf(0.012 if sparse else 0.025,radial*lerpf(0.40,0.47,_unit(field_id+":length"))),
			"half_width_km":maxf(0.006 if sparse else 0.012,radial*lerpf(0.18,0.20,_unit(field_id+":width"))),
			"angle":bearing+PI*0.5})
	return {"yard_center":at,"yard_radius_km":yard_radius,"envelope_radius_km":envelope,"fields":fields}


static func _cluster_layout(record:Dictionary)->Dictionary:
	var at:Vector2=record.get("position",Vector2.ZERO)
	var id:=String(record.get("id",str(at)))
	var envelope:=clampf(float(record.get("field_radius_km",0.14)),0.13,0.15)
	var turn:=float(record.get("rotation",_unit(id+":layout_turn")*TAU))
	var fields:Array[Dictionary]=[]
	for index in 2:
		var field_id:="%s:field:%d" % [id,index]
		var bearing:=turn+float(index)*PI+lerpf(-0.22,0.22,_unit(field_id+":bearing"))
		fields.append({"id":field_id,"center":at+Vector2.from_angle(bearing)*envelope*0.80,
			"half_length_km":0.030,"half_width_km":0.012,"angle":bearing+PI*0.5})
	return {"is_cluster":true,"yard_center":at,"yard_radius_km":0.078,
		"canopy_yard_radius_km":0.125,"envelope_radius_km":envelope,"fields":fields}


static func _country_road_tier(snapshot:Dictionary,outward:float)->int:
	var tier:=clampi(int(snapshot.get("road_tier",0)),0,2)
	if outward>0.72:return 0
	return mini(tier,1) if outward>0.38 else tier


static func _sites(snapshot:Dictionary)->Array:
	var origin:Vector2=snapshot.get("origin",Vector2.ZERO)
	var groups:={"active":[],"depleted":[],"regrowing":[],"resting":[]}
	for item:Variant in snapshot.get("deposits",[]):
		if not item is Dictionary:continue
		var deposit:Dictionary=item
		if not _eligible(deposit):continue
		var position_value:Variant=deposit.get("position",null)
		var at:=Vector2.INF
		if position_value is Vector3:at=Vector2(position_value.x,position_value.z)
		elif position_value is Vector2:at=position_value
		if not at.is_finite():continue
		var state:=site_state(deposit)
		var id:=String(deposit.get("id",""))
		if id.is_empty():id="%s:%s" % [String(deposit.get("resource","")),str(at)]
		var record:={"id":"site:"+String(snapshot.get("owner","player"))+":"+id,
			"deposit_id":id,"category":state.category,"kind":"site","age":state.age,
			"position":at,"offset":at-origin,"distance_km":float(deposit.get("distance_km",at.distance_to(origin))),
			"haul_km":float(deposit.get("haul_km",deposit.get("distance_km",at.distance_to(origin)))),
			"resource":String(deposit.get("resource","")),"landscape_source":String(deposit.get("landscape_source","")),
			"remaining_ratio":float(state.remaining_ratio),"workers":int(deposit.get("workers",0)),
			"field_radius_km":0.72 if String(deposit.get("landscape_source","")) in SURFACE_SOURCES else 0.26,
			"rotation":_unit(id+":turn")*TAU,"road_tier":int(snapshot.get("road_tier",0)),
			"tile_area_km2":9.0 if String(deposit.get("landscape_source","")) in SURFACE_SOURCES else 0.0}
		(groups[String(state.category)] as Array).append(record)
	for group:String in groups:(groups[group] as Array).sort_custom(_nearer)
	# Retain both near-town scars and the current outer work front, even with
	# many deposits. Round-robin categories prevent active sites erasing history.
	var out:Array=[]
	var index:=0
	while out.size()<MAX_SITES:
		var appended:=false
		for group:String in ["active","depleted","regrowing","resting"]:
			if index<(groups[group] as Array).size() and out.size()<MAX_SITES:
				out.append(groups[group][index]);appended=true
		if not appended:break
		index+=1
	out.sort_custom(_nearer)
	return out


static func _eligible(deposit:Dictionary)->bool:
	if String(deposit.get("landscape_source","")) not in SURFACE_SOURCES and String(deposit.get("found_by",""))!="searchers":return false
	return String(deposit.get("stage","")) in ["accessible","developed"] or float(deposit.get("lifetime_extracted",0.0))>0.0


## Depletion is the engine's 5% working-reserve threshold. Regrowth means an
## actually harvested, currently idle renewable site with reserve returning;
## it is not inferred merely because a pristine wood has no workers today.
static func site_state(deposit:Dictionary)->Dictionary:
	var initial:=maxf(0.0001,float(deposit.get("initial_amount",1.0)))
	var ratio:=clampf(float(deposit.get("remaining",initial))/initial,0.0,1.0)
	var source:=String(deposit.get("landscape_source",""))
	var resource:=String(deposit.get("resource",""))
	var active:=int(deposit.get("workers",0))>0 or float(deposit.get("extracted_today",0.0))>0.0001
	var harvested:=float(deposit.get("lifetime_extracted",0.0))>0.0
	var renewable:=source in ["woodland_catchment","plant_fiber_catchment"]
	var depleted:=float(deposit.get("remaining",initial))<=maxf(1.0,initial*0.05)
	var category:="depleted" if depleted else ("active" if active else "resting")
	if not depleted and renewable and harvested and not active and ratio<0.95:category="regrowing"
	var age:="mine"
	if source=="woodland_catchment":
		age="cut_over" if depleted else ("young_wood" if category=="regrowing" else ("thinned" if ratio<0.65 else "woodland"))
	elif source=="surface_stone_catchment" or resource=="Stone":age="spent_quarry" if depleted else "quarry"
	elif source=="plant_fiber_catchment":age="cut_fiber" if depleted else ("young_fiber" if category=="regrowing" else "fiber")
	elif resource=="Clay":age="spent_clay" if depleted else "clay"
	else:age="spent_mine" if depleted else "mine"
	return {"category":category,"age":age,"remaining_ratio":ratio}


static func _nearer(a:Dictionary,b:Dictionary)->bool:
	if is_equal_approx(float(a.distance_km),float(b.distance_km)):return String(a.id)<String(b.id)
	return float(a.distance_km)<float(b.distance_km)


static func _unit(key:String)->float:
	# Avalanche the string hash: neighbouring cell names must not make rows.
	var value:=hash(key)&0x7fffffff
	value=((value^(value>>16))*0x45d9f3b)&0x7fffffff
	value=((value^(value>>16))*0x45d9f3b)&0x7fffffff
	return float(value^(value>>16))/2147483647.0

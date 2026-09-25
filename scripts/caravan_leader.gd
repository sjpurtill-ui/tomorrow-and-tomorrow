extends RefCounted
## The caravan leader: one shared travel brain for the founding journey and every
## expansion caravan, human or rival. The ruler only names a destination. The
## leader plans legs between water, decides when to march, water, forage, rest,
## detour or fall back, and explains each decision in plain words.
##
## Hard rules, independent of competency:
## - never make a voluntary camp where there is no water;
## - never enter a dry stretch without enough water to cross it;
## - when water runs short in dry country, turn aside to the nearest reachable
##   water instead of stopping.
## Competency (the leader's Logistics, Provisioning, Knowledge and Defense)
## changes margins, search breadth and how early the party rests — never the
## rules above. Deaths therefore come from genuinely bad ground, not stupidity.
##
## A record is a plain Dictionary so it saves with GameState unchanged. Nothing
## here touches stores directly: adapters (civilization_travel.gd for the
## founding journey, caravan_system.gd for expansion caravans) supply today's
## situation and apply the movement.

const WET_KM:=1.6
const SAMPLE_KM:=1.5
const CAMP_MODES:=["watering","foraging","resting","provisioning"]
const MAX_LOG:=16
const MAX_PENDING:=10
const MAX_SEARCH_CELLS:=56
const LEADER_WEIGHTS:={"Logistics":0.40,"Provisioning":0.30,"Knowledge":0.20,"Defense":0.10}
const GPS:=preload("res://scripts/government_people_system.gd")

## func(point:Vector2)->Dictionary {"water_km":float,"land":bool,"forage":float,
## "game":float,"water_kind":String}. local_terrain.gd binds the real map;
## headless tests bind synthetic geography. water_km<0 means "not charted".
static var geography_provider:Callable
## Optional func(point:Vector2)->Dictionary {"forage":float,"game":float}; the
## richer environment profile is consulted only for candidate camps.
static var forage_provider:Callable

# --------------------------------------------------------------- geography

static func sample(point:Vector2,cache:Dictionary={})->Dictionary:
	var key:=Vector2i(roundi(point.x*2.0),roundi(point.y*2.0))
	if cache.has(key):
		var cached:Dictionary=cache[key]
		return cached
	var result:Dictionary={}
	if geography_provider.is_valid():
		var provided:Variant=geography_provider.call(point)
		if provided is Dictionary: result=(provided as Dictionary).duplicate()
	elif WorldSimulation.context_provider.is_valid():
		var context_value:Variant=WorldSimulation.context_provider.call(point)
		if context_value is Dictionary:
			var context:Dictionary=context_value
			var profile:Dictionary=context.get("environment_profile",{})
			result={"water_km":float(context.get("surface_water_distance_km",-1.0)),"land":bool(profile.get("land",true)),"forage":float(profile.get("forage",0.4)),"game":float(profile.get("game",0.3))}
	if result.is_empty():result={"water_km":-1.0,"land":true,"forage":0.4,"game":0.3}
	cache[key]=result
	return result

static func water_known(data:Dictionary)->bool:
	return float(data.get("water_km",-1.0))>=0.0

static func is_wet(data:Dictionary)->bool:
	var km:=float(data.get("water_km",-1.0))
	return km>=0.0 and km<=WET_KM

static func is_land(data:Dictionary)->bool:
	return bool(data.get("land",true))

static func forage_quality(data:Dictionary)->float:
	return clampf(float(data.get("forage",0.4))*0.6+float(data.get("game",0.3))*0.4,0.0,1.2)

static func forage_at(point:Vector2)->float:
	if forage_provider.is_valid():
		var provided:Variant=forage_provider.call(point)
		if provided is Dictionary:return forage_quality(provided as Dictionary)
	return forage_quality(sample(point))

static func water_words(data:Dictionary)->String:
	var kind:=String(data.get("water_kind","")).strip_edges()
	if kind!="":return "the "+kind
	var km:=float(data.get("water_km",-1.0))
	if km>=0.0 and km<=0.45:return "the river"
	return "the water"

# --------------------------------------------------------------- leaders

static func competency_of(skills:Dictionary)->float:
	var total:=0.0
	for key:String in LEADER_WEIGHTS:
		total+=clampf(float(skills.get(key,45.0)),0.0,100.0)*float(LEADER_WEIGHTS[key])
	return clampf(total/100.0,0.05,0.98)

static func leader_from_person(person:Dictionary)->Dictionary:
	var skills:Dictionary=person.get("skills",{})
	var chosen:Dictionary={}
	for key:String in LEADER_WEIGHTS:chosen[key]=clampf(float(skills.get(key,45.0)),0.0,100.0)
	return {"name":String(person.get("name","The caravan leader")),"person_id":int(person.get("person_id",0)),"skills":chosen,"competency":competency_of(chosen),"background":String(person.get("background","")),"generated":false}

## A leader for a party with no recorded public figure (the first journey, or a
## rival without a cast). Deterministic from the world seed and a salt.
static func generated_leader(salt:String="founding")->Dictionary:
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d:%s:caravan_leader:%s" % [int(WorldSimulation.state.world_seed),WorldSimulation.actor_id,salt])
	# Named as the people name anyone (era_names.gd): their tradition, their era.
	var identity:Dictionary=preload("res://scripts/era_names.gd").make(int(WorldSimulation.state.world_seed),rng.randi(),rng.randf()<0.5,String(WorldSimulation.actor_id) if String(WorldSimulation.actor_id)!="" else "player",{},{"skill":"Logistics"})
	var name:String=String(identity.get("name","The caravan leader"))
	var skills:Dictionary={"Logistics":float(rng.randi_range(52,80)),"Provisioning":float(rng.randi_range(44,74)),"Knowledge":float(rng.randi_range(36,70)),"Defense":float(rng.randi_range(30,66))}
	return {"name":name,"person_id":0,"skills":skills,"competency":competency_of(skills),"background":"Route and caravan organizer","generated":true}

## Candidates from the government cast, in the cast's own stable order, each with
## a plain-words fit summary (traits stay hidden; the ruler hears reputation).
static func candidates(limit:int=6)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	var government:Object=WorldSimulation.government
	if government==null or not government.has_method("living_people"):return result
	var people:Array=government.call("living_people")
	for person_variant:Variant in people:
		if not person_variant is Dictionary:continue
		var person:Dictionary=person_variant
		var leader:=leader_from_person(person)
		leader["summary"]=fit_summary(leader)
		result.append(leader)
	result.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.competency)>float(b.competency))
	if result.size()>limit:result.resize(limit)
	return result

static func fit_summary(leader:Dictionary)->String:
	var competency:=float(leader.get("competency",0.5))
	var reputation:="Seasoned on the road" if competency>=0.66 else ("A capable organizer" if competency>=0.52 else ("Untested with a large party" if competency>=0.42 else "Known for losing the way"))
	var background:=String(leader.get("background",""))
	return reputation if background=="" else "%s • %s" % [reputation,background]

## The best available leader: a named public figure when the cast has one.
static func choose_leader(person_id:int=0,salt:String="founding")->Dictionary:
	var pool:=candidates(64)
	if person_id>0:
		for candidate:Dictionary in pool:
			if int(candidate.get("person_id",0))==person_id:return candidate
	if not pool.is_empty():return pool[0]
	return generated_leader(salt)

## The longest dry run a party can cross when it leaves the last water at dawn
## with full vessels: each night in dry country costs a day of water, and the
## leader keeps its margin in reserve. `vessel_days` is the water held at dawn.
static func safe_dry_distance(daily_km:float,vessel_days:float,competency:float)->float:
	var nights:=floori(maxf(0.0,vessel_days-water_margin_days(competency))+0.001)
	return maxf(daily_km*0.5,float(nights+1)*daily_km*0.92)

static func water_margin_days(competency:float)->float:
	return lerpf(1.25,0.55,clampf(competency,0.0,1.0))

static func food_margin(competency:float)->float:
	return lerpf(1.5,1.15,clampf(competency,0.0,1.0))

static func rest_threshold(competency:float)->float:
	return lerpf(0.36,0.47,clampf(competency,0.0,1.0))

# --------------------------------------------------------------- planning

## Plans the whole trip over the real environment. Options: daily_km,
## vessel_days, competency, start_water_days, cache. Returns ok/reason, a dense
## polyline, its wet stretches, total km, days and a plain-words summary.
static func plan_route(origin:Vector2,destination:Vector2,options:Dictionary={})->Dictionary:
	var cache:Dictionary=options.get("cache",{})
	var competency:=clampf(float(options.get("competency",0.5)),0.0,1.0)
	var daily_km:=maxf(2.0,float(options.get("daily_km",16.0)))
	var vessel_days:=maxf(0.5,float(options.get("vessel_days",3.0)))
	var margin:=water_margin_days(competency)
	var safe_dry_km:=safe_dry_distance(daily_km,vessel_days,competency)
	var start_water_days:=clampf(float(options.get("start_water_days",vessel_days)),0.0,vessel_days)
	var start_allowance:=clampf((start_water_days-margin*0.5)*daily_km,0.0,safe_dry_km)
	var direct_path:Array=[origin,destination]
	var direct:=profile_path(direct_path,cache)
	var base:={"safe_dry_km":safe_dry_km,"daily_km":daily_km,"vessel_days":vessel_days,"direct_km":origin.distance_to(destination),"direct_longest_dry_km":float(direct.longest_dry_km)}
	if not bool(direct.water_known):
		return _finish_plan(direct_path,direct,"unknown",base,options)
	var direct_ok:=float(direct.longest_dry_km)<=safe_dry_km and float(direct.blocked_km)<=0.0 and float(direct.first_dry_km)<=start_allowance
	if direct_ok:return _finish_plan(direct_path,direct,"direct",base,options)
	# The grid measures dry distance between cell centres; search with some
	# slack and accept only a route whose dense profile truly fits the vessels.
	var searched:Dictionary={}
	for slack:float in [0.9,0.72]:
		searched=_search(origin,destination,daily_km,safe_dry_km*slack,start_allowance*slack,competency,cache)
		if not bool(searched.get("found",false)):break
		var raw:Array=searched.path
		var simple:=_simplify(raw,float(searched.cell)*0.6)
		var simple_profile:=profile_path(simple,cache)
		if float(simple_profile.longest_dry_km)<=safe_dry_km and float(simple_profile.blocked_km)<=0.0 and float(simple_profile.first_dry_km)<=start_allowance:
			return _finish_plan(simple,simple_profile,"water_route",base,options)
		var raw_profile:=profile_path(raw,cache)
		if float(raw_profile.longest_dry_km)<=safe_dry_km and float(raw_profile.first_dry_km)<=start_allowance:
			return _finish_plan(raw,raw_profile,"water_route",base,options)
	var failed:=base.duplicate()
	failed["ok"]=false
	failed["water_known"]=true
	var alternative:Variant=searched.get("alternative",null)
	failed["alternative"]=alternative
	var reason:String="Between here and there lies %.0f km without water. Our vessels carry %.1f days — about %.0f km of dry marching with a safe margin — and I found no chain of rivers or springs that closes the gap." % [float(direct.longest_dry_km),vessel_days,safe_dry_km]
	if float(direct.blocked_km)>0.0 and float(direct.longest_dry_km)<=safe_dry_km:
		reason="Open water blocks the way and I found no dry-shod route around it with water along the march."
	if alternative is Vector2:
		reason+=" The nearest ground I can reach safely is by water %.0f km short of it." % (alternative as Vector2).distance_to(destination)
	failed["reason"]=reason
	return failed

static func _finish_plan(path:Array,profile:Dictionary,kind:String,base:Dictionary,options:Dictionary)->Dictionary:
	var result:=base.duplicate()
	var daily_km:=float(base.daily_km)
	var days:=0.0
	var modifier_distance:=0.0
	var modifier_weighted:=0.0
	var route_ok:=true
	var route_reason:=""
	for index in range(path.size()-1):
		var a:Vector2=path[index]
		var b:Vector2=path[index+1]
		var km:=a.distance_to(b)
		var modifier:=1.0
		if km>=0.3 and WorldSimulation.route_provider.is_valid() and not bool(options.get("skip_route_provider",false)):
			var assessed:Variant=WorldSimulation.route_provider.call(Vector3(a.x,0,a.y),Vector3(b.x,0,b.y))
			if assessed is Dictionary:
				var route:Dictionary=assessed
				if bool(route.get("valid",false)):modifier=clampf(float(route.get("terrain_modifier",1.0)),0.3,1.2)
				elif kind!="water_route":
					route_ok=false
					route_reason=String(route.get("reason","No traversable route."))
				else:modifier=0.7
		modifier_distance+=km
		modifier_weighted+=km*modifier
		days+=km/maxf(0.5,daily_km*modifier)
	var total:=float(profile.total_km)
	result["ok"]=route_ok
	if not route_ok:result["reason"]=route_reason
	result["path"]=path.duplicate()
	result["cum_km"]=profile.cum_km
	result["total_km"]=total
	result["stretches"]=profile.stretches
	result["longest_dry_km"]=float(profile.longest_dry_km)
	result["water_known"]=bool(profile.water_known)
	result["route_kind"]=kind
	result["days"]=maxf(0.5 if total>0.0 else 0.0,days)
	result["terrain_modifier"]=modifier_weighted/maxf(0.001,modifier_distance) if modifier_distance>0.0 else 1.0
	result["detour_km"]=maxf(0.0,total-float(base.direct_km))
	result["dry_runs"]=_dry_runs(profile.stretches,total,bool(profile.water_known))
	result["summary"]=plan_summary(result)
	return result

## Dense profile of a polyline: cumulative km per vertex, wet stretches along
## it (merged [start_km,end_km]), longest dry run, leading dry run and any
## open-water (non-land) run.
static func profile_path(path:Array,cache:Dictionary={})->Dictionary:
	var cum:Array=[0.0]
	var total:=0.0
	for index in range(1,path.size()):
		var a:Vector2=path[index-1]
		var b:Vector2=path[index]
		total+=a.distance_to(b)
		cum.append(total)
	var stretches:Array=[]
	var known:=false
	var blocked_run:=0.0
	var blocked_max:=0.0
	var count:=maxi(2,ceili(total/SAMPLE_KM)+1)
	var step:=total/float(count-1) if count>1 else 0.0
	for index in count:
		var km:=minf(total,float(index)*step)
		var point:=position_on(path,cum,km)
		var data:=sample(point,cache)
		if water_known(data):known=true
		var land:=is_land(data) or index==0 or index==count-1
		if not land:
			blocked_run+=step
			blocked_max=maxf(blocked_max,blocked_run)
		else:blocked_run=0.0
		if is_wet(data):
			var start:=km
			var finish:=km
			var extended:=false
			if not stretches.is_empty():
				var last_stretch:Array=stretches[-1]
				if float(last_stretch[1])>=start-step-0.001:
					last_stretch[1]=finish
					extended=true
			if not extended:stretches.append([start,finish])
	var runs:=_dry_runs(stretches,total,known)
	var longest:=0.0
	for run:Array in runs:longest=maxf(longest,float(run[2]))
	var first_dry:=0.0
	if known:
		first_dry=total if stretches.is_empty() else float((stretches[0] as Array)[0])
	# Crossing a river or stream (a few hundred metres of low ground) is a ford,
	# not open water; the route validator decides wider crossings.
	return {"cum_km":cum,"total_km":total,"stretches":stretches,"longest_dry_km":longest if known else 0.0,"first_dry_km":first_dry,"water_known":known,"blocked_km":blocked_max if blocked_max>4.0 else 0.0}

static func _dry_runs(stretches:Array,total:float,known:bool)->Array:
	var runs:Array=[]
	if not known:return runs
	var cursor:=0.0
	for stretch_variant:Variant in stretches:
		var stretch:Array=stretch_variant
		var start:=float(stretch[0])
		if start-cursor>0.05:runs.append([cursor,start,start-cursor])
		cursor=maxf(cursor,float(stretch[1]))
	if total-cursor>0.05:runs.append([cursor,total,total-cursor])
	return runs

static func position_on(path:Array,cum:Array,km:float)->Vector2:
	if path.is_empty():return Vector2.ZERO
	if path.size()==1 or km<=0.0:
		var first:Vector2=path[0]
		return first
	for index in range(1,path.size()):
		var end_km:=float(cum[index])
		if km<=end_km or index==path.size()-1:
			var start_km:=float(cum[index-1])
			var a:Vector2=path[index-1]
			var b:Vector2=path[index]
			var span:=end_km-start_km
			return a if span<=0.0001 else a.lerp(b,clampf((km-start_km)/span,0.0,1.0))
	var last:Vector2=path[-1]
	return last

## Resource-constrained search over a coarse grid of the real ground. A label is
## (cell, cost, dry km since last water); a cell may hold several labels when a
## costlier arrival carries less dry distance. Dry runs longer than the vessels
## can carry are never expanded.
static func _search(origin:Vector2,destination:Vector2,daily_km:float,safe_dry_km:float,start_allowance:float,competency:float,cache:Dictionary)->Dictionary:
	var distance:=origin.distance_to(destination)
	var margin:=clampf(distance*lerpf(0.35,0.65,competency),10.0,110.0)
	var rect:=Rect2(origin,Vector2.ZERO).expand(destination).grow(margin)
	var cell:=clampf(maxf(rect.size.x,rect.size.y)/float(MAX_SEARCH_CELLS-1),0.8,9.0)
	var nx:=mini(MAX_SEARCH_CELLS,ceili(rect.size.x/cell)+1)
	var ny:=mini(MAX_SEARCH_CELLS,ceili(rect.size.y/cell)+1)
	var grid:={"origin":rect.position,"cell":cell,"nx":nx,"ny":ny,"states":[]}
	var states:Array=grid.states
	states.resize(nx*ny)
	states.fill(-1)
	var start_cell:=_grid_cell(grid,origin)
	var goal_cell:=_grid_cell(grid,destination)
	var best_g:=PackedFloat32Array()
	best_g.resize(nx*ny)
	best_g.fill(INF)
	var best_dry:=PackedFloat32Array()
	best_dry.resize(nx*ny)
	best_dry.fill(INF)
	var label_cell:=PackedInt32Array()
	var label_parent:=PackedInt32Array()
	var label_g:=PackedFloat32Array()
	var label_dry:=PackedFloat32Array()
	var heap:Array=[]
	var origin_wet:=is_wet(sample(origin,cache)) or _grid_state(grid,start_cell,cache)==1
	var start_dry:=0.0 if origin_wet else maxf(0.0,safe_dry_km-start_allowance)
	label_cell.append(start_cell);label_parent.append(-1);label_g.append(0.0);label_dry.append(start_dry)
	best_g[start_cell]=0.0
	best_dry[start_cell]=start_dry
	_heap_push(heap,_grid_center(grid,start_cell).distance_to(destination),0)
	var found:=-1
	var closest_wet:=-1
	var closest_wet_distance:=INF
	var offsets:Array[Vector2i]=[Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1),Vector2i(1,1),Vector2i(1,-1),Vector2i(-1,1),Vector2i(-1,-1)]
	var expansions:=0
	while not heap.is_empty() and expansions<60000:
		var label:=_heap_pop(heap)
		expansions+=1
		var index:=label_cell[label]
		var g:=label_g[label]
		var dry:=label_dry[label]
		if g>best_g[index]+0.01 and dry>best_dry[index]+0.01:continue
		if index==goal_cell:
			found=label
			break
		if _grid_state(grid,index,cache)==1:
			var to_goal:=_grid_center(grid,index).distance_to(destination)
			if to_goal<closest_wet_distance:
				closest_wet_distance=to_goal
				closest_wet=index
		var ix:=index%nx
		var iy:=index/nx
		for offset:Vector2i in offsets:
			var jx:=ix+offset.x
			var jy:=iy+offset.y
			if jx<0 or jy<0 or jx>=nx or jy>=ny:continue
			var neighbor:=jy*nx+jx
			var neighbor_state:=_grid_state(grid,neighbor,cache)
			if neighbor_state==2 and neighbor!=goal_cell:continue
			var step_km:=cell*(1.41421356 if offset.x!=0 and offset.y!=0 else 1.0)
			var neighbor_dry:=0.0 if neighbor_state==1 else dry+step_km
			if neighbor_dry>safe_dry_km:continue
			var neighbor_g:=g+step_km*(1.0 if neighbor_state==1 else 1.22)
			if not (neighbor_g<best_g[neighbor]-0.01 or neighbor_dry<best_dry[neighbor]-0.01):continue
			best_g[neighbor]=minf(best_g[neighbor],neighbor_g)
			best_dry[neighbor]=minf(best_dry[neighbor],neighbor_dry)
			label_cell.append(neighbor);label_parent.append(label);label_g.append(neighbor_g);label_dry.append(neighbor_dry)
			_heap_push(heap,neighbor_g+_grid_center(grid,neighbor).distance_to(destination),label_cell.size()-1)
	var result:={"found":found>=0,"cell":cell,"alternative":null}
	if closest_wet>=0 and closest_wet_distance>cell*2.0:result["alternative"]=_grid_center(grid,closest_wet)
	if found<0:return result
	var cells:Array[int]=[]
	var cursor:=found
	while cursor>=0:
		cells.push_front(label_cell[cursor])
		cursor=label_parent[cursor]
	var path:Array=[origin]
	for position_index in range(1,cells.size()-1):
		path.append(_grid_center(grid,cells[position_index]))
	path.append(destination)
	result["path"]=path
	return result

static func _grid_cell(grid:Dictionary,point:Vector2)->int:
	var grid_origin:Vector2=grid.origin
	var cell:=float(grid.cell)
	var nx:=int(grid.nx)
	var i:=clampi(roundi((point.x-grid_origin.x)/cell),0,nx-1)
	var j:=clampi(roundi((point.y-grid_origin.y)/cell),0,int(grid.ny)-1)
	return j*nx+i

static func _grid_center(grid:Dictionary,index:int)->Vector2:
	var grid_origin:Vector2=grid.origin
	var nx:=int(grid.nx)
	return grid_origin+Vector2(float(index%nx),float(index/nx))*float(grid.cell)

## 0 = dry land, 1 = land with water, 2 = not land. Sampled once per cell.
static func _grid_state(grid:Dictionary,index:int,cache:Dictionary)->int:
	var states:Array=grid.states
	var known:=int(states[index])
	if known>=0:return known
	var data:=sample(_grid_center(grid,index),cache)
	var state:=2 if not is_land(data) else (1 if is_wet(data) else 0)
	states[index]=state
	return state

static func _heap_push(heap:Array,priority:float,label:int)->void:
	heap.append(Vector2(priority,float(label)))
	var child:=heap.size()-1
	while child>0:
		var parent:=(child-1)/2
		var child_value:Vector2=heap[child]
		var parent_value:Vector2=heap[parent]
		if parent_value.x<=child_value.x:break
		heap[child]=parent_value
		heap[parent]=child_value
		child=parent

static func _heap_pop(heap:Array)->int:
	var top:Vector2=heap[0]
	var last:Vector2=heap.pop_back()
	if not heap.is_empty():
		heap[0]=last
		var parent:=0
		while true:
			var left:=parent*2+1
			if left>=heap.size():break
			var smallest:=left
			var right:=left+1
			if right<heap.size() and (heap[right] as Vector2).x<(heap[left] as Vector2).x:smallest=right
			if (heap[smallest] as Vector2).x>=(heap[parent] as Vector2).x:break
			var swap:Vector2=heap[smallest]
			heap[smallest]=heap[parent]
			heap[parent]=swap
			parent=smallest
	return int(top.y)

static func _simplify(path:Array,tolerance:float)->Array:
	if path.size()<=2:return path.duplicate()
	var keep:=PackedByteArray()
	keep.resize(path.size())
	keep.fill(0)
	keep[0]=1
	keep[path.size()-1]=1
	var stack:Array=[Vector2i(0,path.size()-1)]
	while not stack.is_empty():
		var span:Vector2i=stack.pop_back()
		var a:Vector2=path[span.x]
		var b:Vector2=path[span.y]
		var worst:=-1
		var worst_distance:=tolerance
		for index in range(span.x+1,span.y):
			var point:Vector2=path[index]
			var closest:=Geometry2D.get_closest_point_to_segment(point,a,b)
			var off:=point.distance_to(closest)
			if off>worst_distance:
				worst_distance=off
				worst=index
		if worst>=0:
			keep[worst]=1
			stack.append(Vector2i(span.x,worst))
			stack.append(Vector2i(worst,span.y))
	var result:Array=[]
	for index in path.size():
		if keep[index]==1:result.append(path[index])
	return result

static func plan_summary(plan:Dictionary)->String:
	var total:=float(plan.get("total_km",0.0))
	var days:=float(plan.get("days",0.0))
	var trip:String="%.0f km, about %s" % [total,_days_words(days)]
	var sentence:=func(text:String)->String:return text if text.is_empty() else text.substr(0,1).to_upper()+text.substr(1)
	if not bool(plan.get("water_known",false)):
		return "%s. We have no chart of water on this route; I will keep the vessels full and judge each camp as we go." % String(sentence.call(trip))
	var runs:Array=plan.get("dry_runs",[])
	var crossings:Array[String]=[]
	for run:Array in runs:
		if float(run[2])>=float(plan.get("daily_km",16.0))*0.5:crossings.append("%.0f km" % float(run[2]))
	var stretches:Array=plan.get("stretches",[])
	var detour:=float(plan.get("detour_km",0.0))
	var opening:String="I will follow water the whole way" if crossings.is_empty() else ("I will keep to water, with one dry crossing of %s" % crossings[0] if crossings.size()==1 else "I will keep to water, with %d dry crossings (%s)" % [crossings.size(),", ".join(crossings)])
	var detour_text:String="" if detour<3.0 else " — %.0f km longer than the straight line, because the direct way is dry" % detour
	return "%s%s. %s; %d places to drink and camp along the way." % [opening,detour_text,String(sentence.call(trip)),stretches.size()]

static func _days_words(days:float)->String:
	if days<1.0:return "less than a day"
	if days<1.5:return "a day"
	return "%d days" % roundi(days)

# --------------------------------------------------------------- records

static func new_record(kind:String,leader:Dictionary,origin:Vector2,destination:Vector2,plan:Dictionary,day:float)->Dictionary:
	var record:={
		"version":1,"kind":kind,"leader":leader.duplicate(true),
		"origin":origin,"home":origin,"destination":destination,
		"path":[],"cum_km":[],"stretches":[],"total_km":0.0,"planned_days":0.0,"speed_scale":1.0,"water_known":false,"route_kind":"direct",
		"progress_km":0.0,"mode":"marching","stop_km":-1.0,"stop_mode":"","stop_reason":"",
		"camp_since":-1.0,"camp_start_food":0.0,"camp_start_water":0.0,"camp_start_health":0.0,"camp_best":0.0,"camp_best_day":-1.0,
		"intent":"","log":[],"pending_reports":[],"reported":{},
		"depart_day":day,"days_on_road":0.0,"days_camped":0.0,"water_stops":0,"diversions":0,"deaths":0,"plan_revision":0,
		"summary":"",
	}
	apply_plan(record,plan,day)
	return record

static func apply_plan(record:Dictionary,plan:Dictionary,_day:float)->void:
	record["path"]=(plan.get("path",[]) as Array).duplicate()
	record["cum_km"]=(plan.get("cum_km",[]) as Array).duplicate()
	record["stretches"]=(plan.get("stretches",[]) as Array).duplicate(true)
	record["total_km"]=float(plan.get("total_km",0.0))
	record["planned_days"]=float(plan.get("days",0.0))
	record["water_known"]=bool(plan.get("water_known",false))
	record["route_kind"]=String(plan.get("route_kind","direct"))
	record["summary"]=String(plan.get("summary",""))
	record["speed_scale"]=clampf(float(plan.get("total_km",0.0))/maxf(0.01,float(plan.get("days",1.0)))/maxf(0.5,float(plan.get("daily_km",16.0))),0.3,1.2) if float(plan.get("days",0.0))>0.0 else 1.0
	record["progress_km"]=0.0
	record["stop_km"]=-1.0
	record["stop_mode"]=""
	record["plan_revision"]=int(record.get("plan_revision",0))+1
	var path:Array=record.path
	if not path.is_empty():record["origin"]=path[0]

static func position(record:Dictionary)->Vector2:
	return position_on(record.get("path",[]),record.get("cum_km",[]),float(record.get("progress_km",0.0)))

static func progress_ratio(record:Dictionary)->float:
	return clampf(float(record.get("progress_km",0.0))/maxf(0.001,float(record.get("total_km",0.0))),0.0,1.0)

static func remaining_km(record:Dictionary)->float:
	return maxf(0.0,float(record.get("total_km",0.0))-float(record.get("progress_km",0.0)))

static func wet_at(record:Dictionary,km:float)->bool:
	if not bool(record.get("water_known",false)):return true
	for stretch_variant:Variant in record.get("stretches",[]):
		var stretch:Array=stretch_variant
		if km>=float(stretch[0])-0.03 and km<=float(stretch[1])+0.03:return true
	return false

## Start of the next wet stretch at or after km (km itself when already wet);
## total_km when no more water lies on the route.
static func next_wet_km(record:Dictionary,km:float)->float:
	var total:=float(record.get("total_km",0.0))
	if not bool(record.get("water_known",false)):return km
	for stretch_variant:Variant in record.get("stretches",[]):
		var stretch:Array=stretch_variant
		if float(stretch[1])+0.01<km:continue
		return maxf(km,float(stretch[0]))
	return total

## The dry run ahead of km: [start,end]. When km is wet the run starts where the
## current stretch ends. [total,total] when only water (or arrival) lies ahead.
static func next_dry_run(record:Dictionary,km:float)->Array:
	var total:=float(record.get("total_km",0.0))
	if not bool(record.get("water_known",false)):return [total,total]
	var start:=km
	if wet_at(record,km):
		for stretch_variant:Variant in record.get("stretches",[]):
			var stretch:Array=stretch_variant
			if km>=float(stretch[0])-0.01 and km<=float(stretch[1])+0.01:
				start=float(stretch[1])
				break
	if start>=total-0.01:return [total,total]
	return [start,next_wet_km(record,start+0.02)]

## Water-days needed at km to reach the next water: every night spent in dry
## country costs a day from the vessels; tonight counts when km is already dry.
static func nights_to_water(record:Dictionary,km:float,daily_km:float)->int:
	var run:=next_dry_run(record,km)
	var end_km:=float(run[1])
	if float(run[0])>=end_km-0.01:return 0
	var start_km:=float(run[0])
	var step:=maxf(0.5,daily_km)
	var nights:=0
	var p:=km+step
	var guard:=0
	while p<end_km-0.01 and guard<400:
		if p>=start_km-0.01:nights+=1
		p+=step
		guard+=1
	return nights

static func report(record:Dictionary,kind:String,title:String,text:String,severity:String="notice",major:bool=false,key:String="")->void:
	if key!="":
		var reported:Dictionary=record.get("reported",{})
		if reported.has(key):return
		reported[key]=true
		if reported.size()>64:reported.erase(reported.keys()[0])
		record["reported"]=reported
	var day:=int(WorldSimulation.state.elapsed_days)
	var leader:Dictionary=record.get("leader",{})
	var entry:={"day":day,"kind":kind,"title":title,"text":text,"severity":severity,"major":major,"leader":String(leader.get("name","The caravan leader")),"caravan":String(record.get("kind","founding"))}
	var pending:Array=record.get("pending_reports",[])
	pending.append(entry)
	while pending.size()>MAX_PENDING:pending.pop_front()
	record["pending_reports"]=pending
	var log:Array=record.get("log",[])
	log.append(entry)
	while log.size()>MAX_LOG:log.pop_front()
	record["log"]=log

static func drain_reports(record:Dictionary)->Array:
	var pending:Array=record.get("pending_reports",[])
	record["pending_reports"]=[]
	return pending

# --------------------------------------------------------------- daily decisions

## One day (or span) of leadership. situation: population, water_days,
## water_capacity_days, supported_days (food endurance while marching),
## food_days, health, daily_km (today's effective march), days, day.
## Returns {"moved_km","arrived","camped","position","mode"}.
static func step(record:Dictionary,situation:Dictionary)->Dictionary:
	var result:={"moved_km":0.0,"arrived":false,"camped":false,"position":position(record),"mode":String(record.get("mode","marching"))}
	var mode:=String(record.get("mode","marching"))
	if mode in ["arrived","returned"]:
		result.arrived=mode=="arrived"
		return result
	var days:=maxf(0.0,float(situation.get("days",1.0)))
	var day:=float(situation.get("day",WorldSimulation.state.elapsed_days))
	var competency:=float((record.get("leader",{}) as Dictionary).get("competency",0.5))
	var daily_km:=maxf(1.0,float(situation.get("daily_km",16.0)))
	var km:=float(record.get("progress_km",0.0))
	var total:=float(record.get("total_km",0.0))
	var capacity:=maxf(0.5,float(situation.get("water_capacity_days",3.0)))
	var resumed_from:=""
	_observe(record,situation,days)
	# ---- camps: wait until the reason for stopping is resolved
	if mode in CAMP_MODES:
		record["days_camped"]=float(record.get("days_camped",0.0))+days
		var verdict:=_camp_verdict(record,situation,competency,daily_km,day)
		if bool(verdict.get("replan",false)):
			var here_camp:=position(record)
			var destination:Vector2=record.get("destination",here_camp)
			var replanned:=plan_route(here_camp,destination,{"daily_km":daily_km,"vessel_days":capacity,"competency":competency,"start_water_days":float(situation.get("water_days",0.0))})
			if bool(replanned.get("ok",false)) and float(replanned.get("longest_dry_km",0.0))<float(next_dry_run(record,float(record.get("progress_km",0.0)))[1])-float(next_dry_run(record,float(record.get("progress_km",0.0)))[0])-0.5:
				var days_before:=float(record.get("days_on_road",0.0))
				apply_plan(record,replanned,day)
				record["days_on_road"]=days_before
				record["mode"]="marching"
				report(record,"divert","A shorter way between waters","At the pace the people can manage, the dry stretch ahead is beyond our vessels. %s" % String(replanned.get("summary","")),"warning",true,"replan_%d" % int(record.get("plan_revision",0)))
				verdict={"ready":true,"text":"We take the new route."}
			else:
				record["mode"]="held"
				report(record,"trouble","The way ahead is beyond our water","At the pace the people can manage, the dry stretch ahead needs more water than our vessels hold, and I know no other way. We stay by the water here; give me another destination or wait until the people are stronger.","danger",true,"stuck_%d" % int(record.get("plan_revision",0)))
				record["intent"]="Holding by the water: the dry stretch ahead is beyond our vessels"
				result.camped=true
				return result
		if not bool(verdict.ready):
			record["intent"]=String(verdict.intent)
			result.camped=true
			return result
		resumed_from=String(record.get("mode",""))
		record["mode"]="marching"
		mode="marching"
		report(record,"resume","The caravan marches on",String(verdict.text),"notice",false)
		km=float(record.get("progress_km",0.0))
	if mode=="held":
		record["days_camped"]=float(record.get("days_camped",0.0))+days
		var hold_here:=position(record)
		var here_data:=sample(hold_here)
		if bool(record.get("water_known",false)) and not is_wet(here_data) and float(situation.get("water_days",0.0))<float(situation.get("water_capacity_days",3.0))*0.5:
			var water_point:Variant=find_water_near(hold_here,maxf(3.0,daily_km),competency)
			if water_point is Vector2:
				_divert(record,hold_here,water_point as Vector2,situation,competency,"held")
				report(record,"divert","No water where we halted","We stopped as you ordered, but there is no water here. I have moved the party %.1f km to %s and will hold there until you give the word." % [hold_here.distance_to(water_point as Vector2),water_words(sample(water_point as Vector2))],"warning",false,"hold_water_%d" % int(record.get("plan_revision",0)))
				km=float(record.get("progress_km",0.0))
				total=float(record.get("total_km",0.0))
				record["mode"]="seeking_hold"
				mode="seeking_hold"
		if mode=="held":
			record["intent"]="Holding position on your order (%s)" % _days_words(float(record.get("days_camped",0.0)))
			result.camped=true
			return result
	var water_days:=float(situation.get("water_days",3.0))
	var health:=float(situation.get("health",1.0))
	var supported:=supported_days(record,situation)
	var here:=position(record)
	var here_wet:=wet_at(record,km)
	var remaining:=maxf(0.0,total-km)
	var remaining_days:=remaining/daily_km
	var margin:=water_margin_days(competency)
	if mode=="marching" and remaining>0.01:
		# ---- decisions that can be taken only where there is water
		if here_wet:
			if health<rest_threshold(competency) and resumed_from!="resting":
				_camp(record,"resting",here,situation,day,"The people are worn down (health %d%%). We camp by %s to rest before going on." % [roundi(health*100.0),water_words(sample(here))])
				result.camped=true
				return result
			var nights:=nights_to_water(record,km,daily_km)
			var dry:=next_dry_run(record,km)
			var dry_len:=float(dry[1])-float(dry[0])
			var water_need:=minf(capacity*0.97,float(nights)+margin)
			if nights>0 and water_days<water_need-0.01 and resumed_from!="watering":
				if float(dry[0])-km<=0.6:
					_camp(record,"watering",here,situation,day,"The land ahead is dry for %.0f km. We camp by %s and fill every waterskin before crossing." % [dry_len,water_words(sample(here))])
					result.camped=true
					return result
				if float(dry[0])-km<=daily_km*days:
					_set_stop(record,float(dry[0]),"watering","We will stop at the last water before a %.0f km dry stretch and fill the vessels there." % dry_len)
			var food_needed:=minf(remaining_days*food_margin(competency)+2.0,12.0)
			if supported<food_needed and not (resumed_from in ["foraging","provisioning"]):
				if forage_at(here)>=0.36 or not bool(record.get("water_known",false)):
					_camp(record,"foraging",here,situation,day,"Our stores would carry us only %.0f of the %.0f days still ahead. We camp by %s to hunt and forage until the reserve is rebuilt." % [supported,remaining_days,water_words(sample(here))])
					result.camped=true
					return result
				var site:=_forage_site_ahead(record,km,minf(total,km+maxf(daily_km,supported*daily_km*0.7)))
				if site>=0.0 and float(record.get("stop_km",-1.0))<0.0:
					_set_stop(record,site,"foraging","Stores are thin; I am making for better foraging ground by water %.0f km ahead." % (site-km))
		else:
			# ---- in dry country: the only question is whether water is reachable
			var to_wet:=next_wet_km(record,km)-km
			var nights_left:=floori(maxf(0.0,to_wet-0.01)/daily_km)
			if bool(record.get("water_known",false)) and water_days<float(nights_left)+0.2:
				var reach:=maxf(1.5,maxf(0.3,water_days)*daily_km*lerpf(0.75,1.0,competency))
				var water_point:Variant=find_water_near(here,minf(reach,to_wet*0.9),competency)
				if water_point is Vector2:
					_divert(record,here,water_point as Vector2,situation,competency,"marching")
					report(record,"divert","Turning aside for water","The vessels will not last the %.0f km to the next water on our road. I am turning aside to %s, %.1f km away, then we rejoin the route." % [to_wet,water_words(sample(water_point as Vector2)),here.distance_to(water_point as Vector2)],"warning",true,"divert_%d" % int(record.get("plan_revision",0)))
					km=0.0
					total=float(record.get("total_km",0.0))
					remaining=total
				else:
					report(record,"trouble","Short of water on the march","Water is short and there is none nearer than our road's next source, %.0f km on. We press on at the best pace the people can bear." % to_wet,"danger",true,"dry_trouble_%d" % int(record.get("plan_revision",0)))
	# ---- move
	if mode in ["marching","seeking_hold"]:
		var budget:=daily_km*days
		if not here_wet and health>0.5:budget*=1.1
		var target:=minf(total,km+budget)
		var stop_km:=float(record.get("stop_km",-1.0))
		var stopping:=stop_km>=km-0.01 and stop_km<target
		if stopping:target=maxf(km,stop_km)
		elif bool(record.get("water_known",false)):
			# Never pass the last water before a dry stretch the vessels cannot cover.
			var guard_km:=_pass_through_guard(record,km,target,water_days,capacity,daily_km,margin)
			if guard_km>=0.0:
				_set_stop(record,guard_km,"watering","We stop at %s to fill the vessels before the dry country beyond." % water_words(sample(position_on(record.path,record.cum_km,guard_km))))
				target=guard_km
				stopping=true
		var entering_dry:=here_wet and bool(record.get("water_known",false)) and not wet_at(record,target) and target>km
		record["progress_km"]=target
		result.moved_km=target-km
		record["days_on_road"]=float(record.get("days_on_road",0.0))+days
		result.position=position(record)
		if entering_dry:
			var run:=next_dry_run(record,km)
			var run_len:=float(run[1])-float(run[0])
			if run_len>=daily_km*0.5:
				report(record,"crossing","Crossing the dry stretch","We have left the water behind: %.0f km of dry country to the next source. The vessels hold %.1f days." % [run_len,water_days],"notice",false,"dry_%d_%d" % [int(record.get("plan_revision",0)),roundi(float(run[0]))])
		if target>=total-0.01:
			if mode=="seeking_hold":
				record["mode"]="held"
				record["intent"]="Holding by %s on your order" % water_words(sample(result.position as Vector2))
				result.camped=true
				return result
			if bool(record.get("returning",false)):
				record["mode"]="returned"
				record["intent"]="Returned home"
				result["returned"]=true
				report(record,"returned","The caravan is home","We are back where we set out. The people rejoin the settlement and the stores we carried return to its storehouses.","major",true,"returned")
				return result
			record["mode"]="arrived"
			record["intent"]="Arrived"
			result.arrived=true
			report(record,"arrival","The caravan has arrived","We have reached the chosen ground after %s on the road and %s in camp. %s" % [_days_words(float(record.get("days_on_road",0.0))),_days_words(float(record.get("days_camped",0.0))),"No one was lost on the way." if int(record.get("deaths",0))<=0 else "%d did not survive the journey." % int(record.get("deaths",0))],"major",true,"arrival")
			return result
		if stopping:
			var stop_mode:=String(record.get("stop_mode",""))
			var stop_reason:=String(record.get("stop_reason",""))
			record["stop_km"]=-1.0
			record["stop_mode"]=""
			if stop_mode in CAMP_MODES:
				_camp(record,stop_mode,result.position as Vector2,situation,day,stop_reason)
				result.camped=true
				return result
		record["intent"]=_march_intent(record,daily_km)
	result.mode=String(record.get("mode","marching"))
	return result

## A wet stretch that today's march would enter and leave again: stop inside it
## when the dry run beyond needs more water than the vessels now hold.
static func _pass_through_guard(record:Dictionary,km:float,target:float,water_days:float,capacity:float,daily_km:float,margin:float)->float:
	for stretch_variant:Variant in record.get("stretches",[]):
		var stretch:Array=stretch_variant
		var start:=float(stretch[0])
		var finish:=float(stretch[1])
		if start<=km+0.05:continue
		if start>=target:break
		if finish>=target:break
		var nights:=nights_to_water(record,finish-0.02,daily_km)
		if nights<=0:continue
		if water_days<minf(capacity*0.97,float(nights)+margin)-0.01:
			return finish if finish>km+0.01 else -1.0
	return -1.0

static func _march_intent(record:Dictionary,daily_km:float)->String:
	var km:=float(record.get("progress_km",0.0))
	var total:=float(record.get("total_km",0.0))
	var stop_km:=float(record.get("stop_km",-1.0))
	if stop_km>=km:
		return "Marching to %s (%.0f km) to %s" % [water_words(sample(position_on(record.path,record.cum_km,stop_km))),stop_km-km,{"watering":"fill the vessels","foraging":"forage","resting":"rest"}.get(String(record.get("stop_mode","")),"camp")]
	if not wet_at(record,km):
		return "Crossing dry country — %.0f km to water" % (next_wet_km(record,km)-km)
	var run:=next_dry_run(record,km)
	if float(run[0])<total-0.01 and float(run[0])-km<daily_km*1.5:
		return "Following water; a %.0f km dry stretch begins in %.0f km" % [float(run[1])-float(run[0]),float(run[0])-km]
	return "Marching along the water — %.0f km to the destination" % (total-km)

static func _set_stop(record:Dictionary,km:float,stop_mode:String,reason:String)->void:
	var current:=float(record.get("stop_km",-1.0))
	if current>=0.0 and current<=km:return
	record["stop_km"]=km
	record["stop_mode"]=stop_mode
	record["stop_reason"]=reason

static func _camp(record:Dictionary,camp_mode:String,at:Vector2,situation:Dictionary,day:float,text:String)->void:
	record["mode"]=camp_mode
	record["camp_since"]=day
	record["camp_start_food"]=float(situation.get("supported_days",0.0))
	record["camp_start_water"]=float(situation.get("water_days",0.0))
	record["camp_start_health"]=float(situation.get("health",1.0))
	record["camp_best"]=_camp_metric(camp_mode,situation)
	record["camp_best_day"]=day
	record["stop_km"]=-1.0
	record["stop_mode"]=""
	if camp_mode=="watering":record["water_stops"]=int(record.get("water_stops",0))+1
	var titles:={"watering":"Making camp to fill the vessels","foraging":"Making camp to forage","resting":"Making camp to rest","provisioning":"Provisioning before we leave"}
	report(record,camp_mode,String(titles.get(camp_mode,"Making camp")),text,"notice",camp_mode!="watering")
	record["intent"]=_camp_intent(record,camp_mode,at,0.0)

static func _camp_intent(_record:Dictionary,camp_mode:String,at:Vector2,days:float)->String:
	var place:=water_words(sample(at))
	var what:=String({"watering":"to fill the vessels","foraging":"to forage and hunt","resting":"to rest the sick and weary","provisioning":"gathering provisions before departure"}.get(camp_mode,"in camp"))
	return "Camped by %s %s (%s)" % [place,what,"day 1" if days<1.0 else "day %d" % (roundi(days)+1)]

static func _camp_metric(camp_mode:String,situation:Dictionary)->float:
	match camp_mode:
		"watering":return float(situation.get("water_days",0.0))
		"resting":return float(situation.get("health",0.0))
	return float(situation.get("food_days",situation.get("supported_days",0.0)))

## Days of food on the march, judged from what the road has actually cost so
## far (food-days lost per marching day). Before the first marching day the
## adapter's estimate stands.
static func supported_days(record:Dictionary,situation:Dictionary)->float:
	var food_days:=float(situation.get("food_days",-1.0))
	if food_days<0.0 or not record.has("march_drain"):return float(situation.get("supported_days",30.0))
	var drain:=float(record.get("march_drain",0.0))
	if drain<=0.02:return 3650.0
	return food_days/drain

## Updates the leader's experience of the road from the day just lived.
static func _observe(record:Dictionary,situation:Dictionary,days:float)->void:
	var food_days:=float(situation.get("food_days",-1.0))
	if food_days<0.0:return
	# The mode chosen at the end of the last step is the one the day was lived in.
	var lived:=String(record.get("mode","marching"))
	if record.has("observed_food_days") and days>0.0:
		var change:=(food_days-float(record.observed_food_days))/days
		if lived=="marching":
			record["march_drain"]=maxf(0.0,-change) if not record.has("march_drain") else lerpf(float(record.march_drain),maxf(0.0,-change),0.4)
		elif lived in ["foraging","provisioning"]:
			record["camp_gain"]=change if not record.has("camp_gain") else lerpf(float(record.camp_gain),change,0.4)
	record["observed_food_days"]=food_days

static func _camp_verdict(record:Dictionary,situation:Dictionary,competency:float,daily_km:float,day:float)->Dictionary:
	var camp_mode:=String(record.get("mode",""))
	var km:=float(record.get("progress_km",0.0))
	var total:=float(record.get("total_km",0.0))
	var remaining_days:=maxf(0.0,total-km)/daily_km
	var since:=float(record.get("camp_since",day))
	var camped_days:=maxf(0.0,day-since)
	var water_days:=float(situation.get("water_days",0.0))
	var capacity:=maxf(0.5,float(situation.get("water_capacity_days",3.0)))
	var supported:=supported_days(record,situation)
	var health:=float(situation.get("health",1.0))
	var metric:=_camp_metric(camp_mode,situation)
	if metric>float(record.get("camp_best",0.0))+0.05:
		record["camp_best"]=metric
		record["camp_best_day"]=day
	var stalled:=day-float(record.get("camp_best_day",day))>=(4.0 if camp_mode!="foraging" else 6.0)
	var nights:=nights_to_water(record,km,daily_km)
	var water_need:=minf(capacity*0.97,float(nights)+water_margin_days(competency))
	var food_need:=minf(remaining_days*food_margin(competency)+2.0,12.0)
	var water_ready:=nights<=0 or water_days>=water_need
	# Hysteresis: a forage camp breaks only with a clear margin over the level
	# that made the leader stop, so the party does not stop-start every day.
	var food_ready:=supported>=food_need*1.1+0.5
	var health_ready:=health>=rest_threshold(competency)+0.12
	var at:=position(record)
	var intent:=_camp_intent(record,camp_mode,at,camped_days)
	match camp_mode:
		"watering":
			if water_ready:return {"ready":true,"text":"The vessels are full: %.1f days of water for %d dry nights ahead. We cross now." % [water_days,nights]}
			if stalled and water_days>=float(nights)+0.2:return {"ready":true,"text":"The source here yields no more. We carry %.1f days of water for %d dry nights and go now, at a steady pace." % [water_days,nights]}
			if stalled:return {"ready":false,"replan":true,"intent":intent}
			return {"ready":false,"intent":intent+" — %.1f of %.1f days filled" % [water_days,water_need]}
		"resting":
			if health_ready or (stalled and camped_days>=5.0):return {"ready":true,"text":"The people have rested (health %d%%). We march on." % roundi(health*100.0)}
			return {"ready":false,"intent":intent}
		_:
			if food_ready:return {"ready":true,"text":"The stores are rebuilt — about %.0f days of food for the %.0f days still ahead. We march on." % [supported,remaining_days]}
			if stalled or camped_days>=40.0:
				if supported>=remaining_days*1.05:
					return {"ready":true,"text":"Foraging here has run its course. We have enough for the %.0f days to our destination and leave now." % remaining_days}
				var falling:=supported+0.25<float(record.get("camp_start_food",0.0))
				if falling or camped_days>=40.0:
					var site:=_forage_site_ahead(record,km+daily_km*0.5,minf(total,km+maxf(daily_km,supported*daily_km*0.6)))
					if site>=0.0:
						_set_stop(record,site,"foraging","This ground cannot feed us; I am moving the camp to better ground by water %.0f km ahead." % (site-km))
						return {"ready":true,"text":"This ground cannot feed us. We move the camp to better ground %.0f km ahead." % (site-km)}
					if supported>=remaining_days*0.85:
						return {"ready":true,"text":"This ground cannot feed us and nothing better lies within reach. The destination is close enough; we go now."}
				report(record,"trouble","The camp is struggling","Foraging here barely holds our stores (about %.0f days). I will stay by the water rather than march the people into hunger." % supported,"warning",true,"camp_trouble_%d" % roundi(since))
			return {"ready":false,"intent":intent+" — stores %.0f of %.0f days" % [supported,food_need]}

static func _forage_site_ahead(record:Dictionary,from_km:float,to_km:float)->float:
	var best:=-1.0
	var best_quality:=0.0
	var km:=from_km
	var count:=0
	while km<=to_km and count<40:
		count+=1
		if wet_at(record,km):
			var quality:=forage_at(position_on(record.path,record.cum_km,km))
			if quality>best_quality+0.04:
				best_quality=quality
				best=km
		km+=SAMPLE_KM*1.5
	return best if best_quality>=0.30 else -1.0

## Nearest water around a point, searching outward in rings; null when none
## lies within radius_km. Better leaders search more carefully.
static func find_water_near(center:Vector2,radius_km:float,competency:float=0.5)->Variant:
	var spokes:=12 if competency<0.5 else 18
	var ring:=0.75
	while ring<=radius_km+0.01:
		var best:Variant=null
		for spoke in spokes:
			var point:=center+Vector2.from_angle(TAU*float(spoke)/float(spokes))*ring
			var data:=sample(point)
			if is_land(data) and is_wet(data):
				best=point
				break
		if best!=null:return best
		ring+=1.0
	return null

## Rebuilds the route through a water point: here → water → destination.
static func _divert(record:Dictionary,here:Vector2,water_point:Vector2,situation:Dictionary,competency:float,next_mode:String)->void:
	var destination:Vector2=record.get("destination",here)
	var options:={"daily_km":maxf(2.0,float(situation.get("daily_km",16.0))),"vessel_days":float(situation.get("water_capacity_days",3.0)),"competency":competency,"start_water_days":float(situation.get("water_capacity_days",3.0))}
	var onward:Dictionary=plan_route(water_point,destination,options) if next_mode=="marching" else {}
	var path:Array=[here,water_point]
	if bool(onward.get("ok",false)):
		var onward_path:Array=onward.path
		for index in range(1,onward_path.size()):path.append(onward_path[index])
	elif next_mode=="marching":path.append(destination)
	var profile:=profile_path(path)
	var plan:=_finish_plan(path,profile,"water_route",{"safe_dry_km":0.0,"daily_km":float(options.daily_km),"vessel_days":float(options.vessel_days),"direct_km":here.distance_to(destination),"direct_longest_dry_km":0.0},{"skip_route_provider":true})
	var days_before:=float(record.get("days_on_road",0.0))
	apply_plan(record,plan,float(situation.get("day",0.0)))
	record["days_on_road"]=days_before
	record["diversions"]=int(record.get("diversions",0))+1
	if next_mode=="held":
		# Hold at the water point itself.
		record["destination_after_hold"]=destination
		var cum:Array=record.cum_km
		record["total_km"]=float(cum[1]) if cum.size()>1 else 0.0

## Ruler override: halt. The leader obeys, but never holds a party in dry
## country when water is near — it moves to the water first.
static func hold(record:Dictionary)->String:
	if String(record.get("mode",""))=="arrived":return "The caravan has already arrived."
	record["mode"]="held"
	record["stop_km"]=-1.0
	record["stop_mode"]=""
	record["days_camped"]=float(record.get("days_camped",0.0))
	record["intent"]="Holding position on your order"
	var here:=position(record)
	var text:="We halt here on your order and camp until you give the word."
	if bool(record.get("water_known",false)) and not is_wet(sample(here)):
		text="We halt on your order. There is no water here; if the vessels run low I will move the party to the nearest water and hold there."
	report(record,"hold","Halting on your order",text,"notice",false)
	return text

## Ruler override: resume after a hold. Replans from the present position so a
## hold-time water detour or a changed situation does not strand the route.
static func resume(record:Dictionary,situation:Dictionary)->String:
	var mode:=String(record.get("mode",""))
	if mode=="arrived":return "The caravan has already arrived."
	var destination:Vector2=record.get("destination_after_hold",record.get("destination",position(record)))
	record.erase("destination_after_hold")
	var here:=position(record)
	record["destination"]=destination
	var competency:=float((record.get("leader",{}) as Dictionary).get("competency",0.5))
	var plan:=plan_route(here,destination,{"daily_km":maxf(2.0,float(situation.get("daily_km",16.0))),"vessel_days":float(situation.get("water_capacity_days",3.0)),"competency":competency,"start_water_days":float(situation.get("water_days",3.0))})
	if bool(plan.get("ok",false)) and here.distance_to(destination)>0.05:
		var days_before:=float(record.get("days_on_road",0.0))
		apply_plan(record,plan,float(situation.get("day",0.0)))
		record["days_on_road"]=days_before
	record["mode"]="marching"
	var text:String="We break camp and march on. %s" % String(record.get("summary",""))
	report(record,"resume","Marching on your word",text,"notice",false)
	return text

## Ruler override: call the caravan home. The leader plans the way back over
## water the same way it planned the way out.
static func recall(record:Dictionary,situation:Dictionary)->String:
	if String(record.get("mode","")) in ["arrived","returned"]:return "The caravan has already finished its journey."
	var here:=position(record)
	var home:Vector2=record.get("home",record.get("origin",here))
	var competency:=float((record.get("leader",{}) as Dictionary).get("competency",0.5))
	var plan:=plan_route(here,home,{"daily_km":maxf(2.0,float(situation.get("daily_km",16.0))),"vessel_days":float(situation.get("water_capacity_days",3.0)),"competency":competency,"start_water_days":float(situation.get("water_days",3.0))})
	if not bool(plan.get("ok",false)):
		plan=_finish_plan([here,home],profile_path([here,home]),"direct",{"safe_dry_km":0.0,"daily_km":16.0,"vessel_days":3.0,"direct_km":here.distance_to(home),"direct_longest_dry_km":0.0},{"skip_route_provider":true})
	var days_before:=float(record.get("days_on_road",0.0))
	apply_plan(record,plan,float(situation.get("day",0.0)))
	record["days_on_road"]=days_before
	record["destination"]=home
	record["returning"]=true
	record["mode"]="marching"
	var text:String="We turn for home on your word. %s" % String(record.get("summary",""))
	report(record,"recall","Turning for home",text,"notice",true,"recall")
	return text

## Departure judgment: may start the caravan in a provisioning or watering camp
## instead of marching straight into shortage.
static func departure(record:Dictionary,situation:Dictionary)->void:
	var competency:=float((record.get("leader",{}) as Dictionary).get("competency",0.5))
	var daily_km:=maxf(1.0,float(situation.get("daily_km",16.0)))
	var day:=float(situation.get("day",WorldSimulation.state.elapsed_days))
	var here:=position(record)
	var remaining_days:=remaining_km(record)/daily_km
	var nights:=nights_to_water(record,0.0,daily_km)
	var water_need:=float(nights)+water_margin_days(competency)
	var summary:=String(record.get("summary",""))
	if wet_at(record,0.0) and nights>0 and float(situation.get("water_days",0.0))<minf(float(situation.get("water_capacity_days",3.0))*0.97,water_need):
		report(record,"departure","The caravan prepares to leave",summary,"notice",true,"departure")
		_camp(record,"watering",here,situation,day,"Before we set out I will fill every waterskin: the first dry stretch needs %d nights of water." % nights)
		return
	var food_need:=minf(remaining_days*1.1+1.0,12.0)
	if float(situation.get("supported_days",30.0))<food_need and wet_at(record,0.0):
		report(record,"departure","The caravan prepares to leave",summary,"notice",true,"departure")
		_camp(record,"provisioning",here,situation,day,"Our stores would carry us only %.0f days. We gather food here first, then set out." % float(situation.get("supported_days",0.0)))
		return
	report(record,"departure","The caravan sets out",summary,"notice",true,"departure")
	record["intent"]=_march_intent(record,daily_km)

## Compact status for cards and dock blocks.
static func status(record:Dictionary)->Dictionary:
	var leader:Dictionary=record.get("leader",{})
	return {
		"leader":String(leader.get("name","The caravan leader")),"competency":float(leader.get("competency",0.5)),"reputation":fit_summary(leader),
		"mode":String(record.get("mode","marching")),"intent":String(record.get("intent","")),
		"progress":progress_ratio(record),"remaining_km":remaining_km(record),"total_km":float(record.get("total_km",0.0)),
		"summary":String(record.get("summary","")),"water_stops":int(record.get("water_stops",0)),"diversions":int(record.get("diversions",0)),"deaths":int(record.get("deaths",0)),
		"log":(record.get("log",[]) as Array).duplicate(true),
	}

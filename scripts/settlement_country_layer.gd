extends Node3D
## Read-only map adapter for the one worked country of each known people.
## A fixed number of retained owner layers shares one frame build budget.
## Reports admit rivals and supply their representative head-count estimate;
## real scoped engine rings and deposit records supply all worked-site facts.
const PLAN=preload("res://scripts/settlement_country_plan.gd")
const VISUAL=preload("res://scripts/settlement_country_visual.gd")
const FOREIGN=preload("res://scripts/foreign_settlement_visual.gd")
const REALM=preload("res://scripts/realm_reach.gd")
const MAX_PEOPLES:=8
const COUNTRY_MARGIN_KM:=125.0
var terrain:Node3D
var layers:Dictionary={}
var _refresh_key:Array=[]
var _surface_key:Array=[]
var _fog_revision:=-1
var _cursor:=0
var refreshes:=0
var captures:=0
var last_refresh_usec:=0
var last_process_usec:=0
var max_refresh_usec:=0
var clearing_revision:=0
var _clearing_cache_revision:=-1
var _clearing_candidates:Array[Dictionary]=[]

func refresh(owner_terrain:Node3D)->void:
	terrain=owner_terrain
	if terrain==null or terrain.camera==null:return
	# The completed ground grid is stable after the camera settles; do not
	# queue replacement country meshes at every intermediate pan/zoom frame.
	if terrain.has_method("_camera_in_motion") and terrain._camera_in_motion():return
	# UI callbacks never run in a rival's synchronous simulation scope.
	if WorldSimulation.actor_id!="player":return
	var camera:Camera3D=terrain.camera
	var center:=Vector2(camera.global_position.x,camera.global_position.z)
	var span:=maxf(0.05,camera.size)
	var level:=roundi(log(span)/log(1.6))
	var step:=maxf(1.0,pow(1.6,float(level))*0.2)
	var detail_visible:bool=terrain.detail_terrain_patch!=null and terrain.detail_terrain_patch.visible
	var surface:Array=[terrain.river_terrain_grid,terrain.detail_surface_center,detail_visible]
	var key:Array=[GameState.world_seed,int(GameState.elapsed_days),GameState.population_total,GameState.settlement_site_committed,GameState.settlement_founded_at,GameState.resource_deposits.size(),GameState.known_discoveries.size(),center.snapped(Vector2.ONE*step),level,surface,CivilizationSystem.fog_revision]
	if key==_refresh_key:return
	_refresh_key=key
	var began:=Time.get_ticks_usec()
	var drape_changed:=surface!=_surface_key
	var fog_changed:=CivilizationSystem.fog_revision!=_fog_revision
	_surface_key=surface
	_fog_revision=CivilizationSystem.fog_revision
	var candidates:=_candidates(center,span*1.15)
	candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var first:float=(a.origin as Vector2).distance_squared_to(center)
		var second:float=(b.origin as Vector2).distance_squared_to(center)
		return String(a.owner)<String(b.owner) if is_equal_approx(first,second) else first<second)
	if candidates.size()>MAX_PEOPLES:candidates.resize(MAX_PEOPLES)
	var admitted:={}
	for candidate:Dictionary in candidates:admitted[String(candidate.owner)]=true
	for id:String in layers.keys():
		if admitted.has(id):continue
		var stale:Node3D=layers[id].node
		if is_instance_valid(stale):remove_child(stale);stale.queue_free()
		layers.erase(id)
		clearing_revision+=1
	for candidate:Dictionary in candidates:
		var id:=String(candidate.owner)
		var entry:Dictionary=layers.get(id,{})
		if entry.is_empty():
			var node:=VISUAL.new()
			node.name="WorkedCountry_"+id.validate_node_name()
			node.configure(Callable(terrain,"_harvest_ground_height_at"),_drawn_land,_revealed)
			add_child(node)
			entry={"node":node,"source_key":[],"snapshot":{},"style":candidate.style,"population":-1}
		var state:Object=GameState if id=="player" else (WorldSimulation.actors[id] as Dictionary).systems.GameState
		var source_key:Array=[int(state.get("elapsed_days")),int(state.get("population_total")),(state.get("resource_deposits") as Array).size(),(state.get("known_discoveries") as Array).size(),candidate.get("observation_day",-1),candidate.get("estimate",{})]
		if source_key!=entry.source_key:
			var realm:Dictionary=candidate.realm
			var snapshot:Dictionary=WorldSimulation.scoped(id,func()->Dictionary:return PLAN.capture_current(realm))
			if id!="player":
				var report:Dictionary=candidate.report
				var population:=FOREIGN.stable_population(report,int(entry.population))
				entry.population=population
				# Rings and deposit facts remain the engine's; the map does not
				# turn the representative households into a secret census.
				snapshot["population"]=maxi(0,population)
			entry.snapshot=snapshot;entry.source_key=source_key;captures+=1
		if drape_changed:entry.node.invalidate(true)
		elif fog_changed:entry.node.invalidate(false)
		entry.node.ground_grid=terrain.river_terrain_grid
		entry.node.view_center=center
		var old_plan_key:int=entry.node.last_plan_signature
		entry.node.request(entry.snapshot,entry.style)
		if old_plan_key!=entry.node.last_plan_signature:clearing_revision+=1
		layers[id]=entry
	refreshes+=1
	last_refresh_usec=Time.get_ticks_usec()-began
	max_refresh_usec=maxi(max_refresh_usec,last_refresh_usec)

## The known capital is the admission rule. Old saves without independent
## actor ledgers have no factual country to paint and keep their existing town.
func _candidates(center:Vector2,radius:float)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	if GameState.settlement_site_committed:
		var realm:=REALM.ours()
		var at:=Vector2(GameState.settlement_founded_at.x,GameState.settlement_founded_at.z)
		if not realm.is_empty():at=realm.center
		var reach:=radius+maxf(COUNTRY_MARGIN_KM,float(realm.get("reach",0.0)))
		if at.distance_squared_to(center)<=reach*reach:
			result.append({"owner":"player","origin":at,"realm":realm,"style":{}})
	var intel:Variant=CivilizationSystem.city_intelligence
	if intel==null:return result
	var book:Dictionary=(intel.records as Dictionary).get("player",{})
	for civ:Dictionary in CivilizationSystem.civilizations:
		var id:=String(civ.get("id",""))
		if not WorldSimulation.actors.has(id):continue
		var city_id:=""
		for region:Dictionary in civ.get("strategic_regions",[]):
			if String(region.get("role",""))=="capital":city_id=String(region.get("id",""));break
		if city_id.is_empty() or not book.has(city_id):continue
		var report:Dictionary=book[city_id]
		if String(report.get("civ_id",""))!=id:continue
		if String(report.get("controller",id)) not in ["",id]:continue
		var estimate:Dictionary=(report.get("fields",{}) as Dictionary).get("population",{})
		if estimate.is_empty():continue
		var location:Dictionary=report.get("position",{})
		var at:=Vector2(float(location.get("x",0.0)),float(location.get("z",0.0)))
		if not terrain._world_position_is_revealed(Vector3(at.x,0.0,at.y)):continue
		var realm:=REALM.of(civ,{city_id:location})
		if realm.is_empty():continue
		var reach:=radius+maxf(COUNTRY_MARGIN_KM,float(realm.get("reach",0.0)))
		if at.distance_squared_to(center)>reach*reach:continue
		result.append({"owner":id,"origin":at,"realm":realm,"style":FOREIGN.style_for(report),"report":report,"observation_day":int(report.get("observed_day",-1)),"estimate":estimate})
	return result

func _drawn_land(point:Vector2)->bool:
	return _revealed(point) and terrain._settlement_stage_land_at(point)

func _revealed(point:Vector2)->bool:
	return terrain._world_position_is_revealed(Vector3(point.x,0.0,point.y))

## Reuse the terrain's existing cut/regrowing canopy treatment for the same
## admitted rivals. These are live read-only ledger references, never copies
## of unobserved people or a second source of resource work.
func woodland_ledgers()->Array:
	var out:Array=[]
	for id:String in layers:
		if id=="player":continue
		var deposits:Variant=(layers[id].snapshot as Dictionary).get("deposits",[])
		if deposits is Array:out.append(deposits)
	return out

## Presentation clearings for sampled farm ground, never harvested sites.
## They share the existing canopy budget and stay out of the stump/detail layer.
func canopy_clearings(center:Vector2,limit:int=16)->PackedVector4Array:
	if _clearing_cache_revision!=clearing_revision:
		_clearing_cache_revision=clearing_revision
		_clearing_candidates.clear()
		for entry:Dictionary in layers.values():
			for kind:String in ["homesteads","herders"]:
				for home:Dictionary in entry.node.plan.get(kind,[]):
					var layout:=PLAN.homestead_layout(home)
					var at:Vector2=layout.yard_center
					_clearing_candidates.append({"anchor":at,"area":Vector4(at.x,at.y,float(layout.yard_radius_km),0.01)})
					for field:Dictionary in layout.fields:
						var along:=Vector2.from_angle(float(field.angle))
						var across:=along.orthogonal()
						var segment_half:=float(field.half_length_km)/3.0
						var half_width:=float(field.half_width_km)
						var radius:=maxf(half_width,segment_half)*1.15
						# Cover each rotated segment through the mask's fully
						# cleared interior, including its scalloped feather edge.
						# L4 <= .65 leaves room for the maximum .15 scallop.
						for side in [-1.0,1.0]:
							var corner:Vector2=(along*segment_half+across*half_width*side).abs()
							var squared:=corner*corner
							radius=maxf(radius,sqrt(sqrt(squared.dot(squared)))/0.65)
						for cell in 3:
							var point:Vector2=field.center+along*segment_half*float((cell-1)*2)
							_clearing_candidates.append({"anchor":at,"area":Vector4(point.x,point.y,radius,0.0)})
	var points:=_clearing_candidates.duplicate()
	points.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return Vector2(a.area.x,a.area.y).distance_squared_to(center)<Vector2(b.area.x,b.area.y).distance_squared_to(center))
	var accepted:=PackedVector4Array()
	var land:Dictionary={}
	for candidate:Dictionary in points:
		if accepted.size()>=maxi(0,limit):break
		var point:Vector4=candidate.area
		if terrain!=null:
			var anchor:Vector2=candidate.anchor
			if not land.has(anchor):land[anchor]=_drawn_land(anchor)
			if not bool(land[anchor]) or not _drawn_land(Vector2(point.x,point.y)):continue
		accepted.append(point)
	return accepted

func process_jobs(budget_usec:int=2000,max_jobs:int=2)->void:
	var began:=Time.get_ticks_usec()
	var ids:=layers.keys()
	var checked:=0
	var built:=0
	while checked<ids.size() and built<maxi(0,max_jobs):
		if checked>0 and Time.get_ticks_usec()-began>=budget_usec:break
		_cursor=posmod(_cursor,ids.size())
		var node:Node3D=layers[ids[_cursor]].node
		_cursor+=1;checked+=1
		if not node.visible:continue
		node.process_jobs(maxi(1,budget_usec-int(Time.get_ticks_usec()-began)),1)
		built+=int(node.retained.last_jobs)
	last_process_usec=Time.get_ticks_usec()-began

func stats()->Dictionary:
	var owners:={}
	var pending:=0
	for id:String in layers:
		var reading:Dictionary=layers[id].node.stats()
		owners[id]=reading;pending+=int(reading.get("pending",0))
	return {"owners":owners,"layers":layers.size(),"limit":MAX_PEOPLES,"pending":pending,"refreshes":refreshes,"captures":captures,"refresh_usec":last_refresh_usec,"max_refresh_usec":max_refresh_usec,"process_usec":last_process_usec}

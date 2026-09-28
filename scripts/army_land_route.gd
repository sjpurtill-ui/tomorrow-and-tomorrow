extends RefCounted
## Land routes for marching armies.
##
## The general picks the road; the player never plots waypoints. A march goes
## straight when the straight line stays on land. Otherwise a bounded A* over
## a lattice laid across the start and goal walks around bays, inlets, lakes
## and headlands, and the raw lattice path is pulled taut into a few long
## legs. Narrow water (a stream, a ford) up to FORD_KM can be waded; open
## water is a wall. Only when no land route exists inside the search box is
## the answer "no route" (another landmass, or a coast with no way round).
##
## Pure and deterministic: the land predicate is passed in (a Callable
## Vector2 -> bool, kilometres), so tests use fixtures and the game uses the
## same authoritative height field the terrain mesh draws. Results are cached
## per snapped start/goal. Static helpers; preload.

## The finest lattice step (km) and the coarsest one.
const MIN_CELL_KM:=0.35
const MAX_CELL_KM:=8.0
## Cells across the straight distance; finer lattices cost more.
const CELLS_ACROSS:=90.0
## Lattice sides are capped, so one search never samples more than this many
## points of ground.
const MAX_SIDE:=200
## Hard ceiling on A* expansions (performance bound).
const MAX_EXPANDED:=30000
## Water a marching column can wade (streams, a ford) in one stretch.
const FORD_KM:=0.3
## Straight-leg sampling step (km).
const SAMPLE_KM:=0.25
const CACHE_MAX:=96
## Samples along a straight line beyond which long lines are sampled coarser.
const LONG_SAMPLES:=2000.0

## With terrain (march_terrain.gd): cells across the straight distance, the
## lattice side cap, and marches this short walked straight.
const CELLS_ACROSS_TERRAIN:=56.0
const MAX_SIDE_TERRAIN:=150
const STRAIGHT_KM:=1.0

const March:=preload("res://scripts/march_terrain.gd")

static var _cache:Dictionary={}
static var last_stats:Dictionary={}

static func clear_cache()->void:
	_cache.clear()

static func world_land()->Callable:
	## The game's land predicate (the rendered height field), or an invalid
	## Callable when the terrain has not been surveyed yet.
	var world:Variant=WorldSimulation.world if WorldSimulation!=null else null
	if world==null or not (world as Object).get("scout_land_authority") is Callable or not (world.scout_land_authority as Callable).is_valid(): return Callable()
	return Callable(world,"_scout_land_at")

static func segment_land(a:Vector2,b:Vector2,land:Callable,step:float=SAMPLE_KM,ford_km:float=FORD_KM)->bool:
	## True when a column can walk the straight leg a->b: every sample is land,
	## except wadeable stretches of water no longer than ford_km.
	var distance:=a.distance_to(b)
	var samples:=clampi(ceili(distance/maxf(0.05,step)),1,20000)
	var wet:=0.0
	var leg:=distance/float(samples)
	for i in samples+1:
		if bool(land.call(a.lerp(b,float(i)/float(samples)))):
			wet=0.0
			continue
		wet+=leg
		if wet>ford_km: return false
	return true

static func _snap_to_land(at:Vector2,land:Callable,radius:float)->Vector2:
	## A coastal town or camp can sit a hair off the sampled shore.
	if bool(land.call(at)): return at
	for ring in range(1,9):
		var r:=radius*float(ring)/8.0
		for k in 16:
			var p:=at+Vector2.from_angle(TAU*float(k)/16.0)*r
			if bool(land.call(p)): return p
	return Vector2.INF

static func find(start:Vector2,goal:Vector2,land:Callable=Callable(),cache:bool=true,ctx:Dictionary={})->Dictionary:
	## {ok, points:Array[Vector2] (legs after start; last is goal), length_km,
	##  direct, expanded} or {error, reason} where reason is "no_survey",
	##  "start_water", "goal_water" or "no_land_route".
	## ctx (march_terrain.context(mix)): the route weighs the ground for that
	## force, and the result also carries its profile: points subdivided,
	## e (cumulative level km), t, effort_km, ground.
	if not land.is_valid(): land=world_land()
	if not land.is_valid(): return {"error":"Terrain information is unavailable.","reason":"no_survey"}
	var key:=""
	if cache:
		# The world's predicate forwards to its terrain authority: a new survey
		# (changed terrain) is a new key.
		var land_id:=land.hash()
		var holder:Variant=land.get_object()
		if holder!=null and (holder as Object).get("scout_land_authority") is Callable: land_id=hash([land_id,(holder.scout_land_authority as Callable).hash()])
		key="%s|%s|%d|%s" % [str(start.snapped(Vector2.ONE*0.05)),str(goal.snapped(Vector2.ONE*0.05)),land_id,String(ctx.get("key",""))]
		if _cache.has(key): return (_cache[key] as Dictionary).duplicate(true)
	var began:=Time.get_ticks_usec()
	var result:=_search_terrain(start,goal,land,ctx) if not ctx.is_empty() else _search(start,goal,land)
	result["search_ms"]=float(Time.get_ticks_usec()-began)/1000.0
	last_stats={"expanded":int(result.get("expanded",0)),"ms":float(result.search_ms),"ok":bool(result.get("ok",false)),"cells":int(result.get("cells",0))}
	if cache:
		if _cache.size()>=CACHE_MAX: _cache.clear()
		_cache[key]=result.duplicate(true)
	return result

class Lattice:
	var lo:Vector2
	var cell:float
	var nx:int
	var ny:int
	var land:Callable
	var ground:PackedByteArray
	func _init(p_lo:Vector2,p_cell:float,p_nx:int,p_ny:int,p_land:Callable)->void:
		lo=p_lo; cell=p_cell; nx=p_nx; ny=p_ny; land=p_land
		ground=PackedByteArray(); ground.resize(nx*ny)
	func at(i:int)->Vector2:
		return lo+Vector2(float(i%nx),float(i/nx))*cell
	func is_land(i:int)->bool:
		# 0 unknown, 1 land, 2 water: each point of ground is sampled once.
		var v:=ground[i]
		if v==0:
			v=1 if bool(land.call(at(i))) else 2
			ground[i]=v
		return v==1
	func nearest_land(i:int,real:Vector2)->int:
		if is_land(i) and _dry(real,at(i)): return i
		var cx:=i%nx; var cy:=i/nx
		for r in range(1,4):
			var best:=-1; var best_d:=INF
			for y in range(cy-r,cy+r+1):
				for x in range(cx-r,cx+r+1):
					if x<0 or y<0 or x>=nx or y>=ny: continue
					var j:=y*nx+x
					if not is_land(j): continue
					var d:=real.distance_to(at(j))
					if d<best_d and _dry(real,at(j)): best=j; best_d=d
			if best>=0: return best
		return i if is_land(i) else -1
	func _dry(a:Vector2,b:Vector2)->bool:
		var distance:=a.distance_to(b)
		var samples:=clampi(ceili(distance/0.25),1,64)
		var wet:=0.0
		for k in samples+1:
			if bool(land.call(a.lerp(b,float(k)/float(samples)))): wet=0.0; continue
			wet+=distance/float(samples)
			if wet>0.6: return false
		return true

static func _search(start:Vector2,goal:Vector2,land:Callable)->Dictionary:
	var dist:=start.distance_to(goal)
	var s:=_snap_to_land(start,land,1.0)
	if s==Vector2.INF: return {"error":"The army is not standing on land.","reason":"start_water"}
	var g:=_snap_to_land(goal,land,1.5)
	if g==Vector2.INF: return {"error":"The destination is not on land.","reason":"goal_water"}
	# Long (continental) marches sample the straight line more coarsely: the
	# cost of one search stays bounded whatever the distance.
	if dist<0.05 or segment_land(start,goal,land,maxf(SAMPLE_KM,dist/LONG_SAMPLES)):
		return {"ok":true,"points":[goal],"length_km":dist,"direct":true,"expanded":0,"cells":0}
	# The lattice covers start and goal with room to go round on either side.
	var cell:=clampf(dist/CELLS_ACROSS,MIN_CELL_KM,MAX_CELL_KM)
	var pad:=maxf(dist*0.8,cell*12.0)
	var lo:=Vector2(minf(s.x,g.x),minf(s.y,g.y))-Vector2.ONE*pad
	var hi:=Vector2(maxf(s.x,g.x),maxf(s.y,g.y))+Vector2.ONE*pad
	var size:=hi-lo
	if maxf(size.x,size.y)/cell>MAX_SIDE: cell=maxf(size.x,size.y)/float(MAX_SIDE)
	var nx:=maxi(2,ceili(size.x/cell)+1)
	var ny:=maxi(2,ceili(size.y/cell)+1)
	var total:=nx*ny
	var grid:=Lattice.new(lo,cell,nx,ny,land)
	var cost:=PackedFloat32Array(); cost.resize(total); cost.fill(INF)
	var parent:=PackedInt32Array(); parent.resize(total); parent.fill(-1)
	var closed:=PackedByteArray(); closed.resize(total)
	var si:=clampi(roundi((s.y-lo.y)/cell),0,ny-1)*nx+clampi(roundi((s.x-lo.x)/cell),0,nx-1)
	var gi:=clampi(roundi((g.y-lo.y)/cell),0,ny-1)*nx+clampi(roundi((g.x-lo.x)/cell),0,nx-1)
	# On a ragged coast the nearest lattice point may be offshore: take the
	# closest dry one within reach of the real start/goal instead.
	si=grid.nearest_land(si,s)
	gi=grid.nearest_land(gi,g)
	# Both ends are dry, but no lattice ground near them: they sit on land too
	# small to leave (an island), so there is no road between them.
	if si<0 or gi<0: return {"error":"No land route reaches it.","reason":"no_land_route","expanded":0,"cells":total}
	var heap_f:=PackedFloat32Array(); var heap_i:=PackedInt32Array()
	var goal_at:=grid.at(gi)
	cost[si]=0.0
	_push(heap_f,heap_i,grid.at(si).distance_to(goal_at),si)
	var expanded:=0
	var found:=false
	const OFFSETS:=[Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1),Vector2i(1,1),Vector2i(-1,1),Vector2i(1,-1),Vector2i(-1,-1)]
	while heap_i.size()>0 and expanded<MAX_EXPANDED:
		var i:=_pop(heap_f,heap_i)
		if closed[i]==1: continue
		closed[i]=1; expanded+=1
		if i==gi: found=true; break
		var cx:=i%nx; var cy:=i/nx
		for o:Vector2i in OFFSETS:
			var x:=cx+o.x; var y:=cy+o.y
			if x<0 or y<0 or x>=nx or y>=ny: continue
			var j:=y*nx+x
			if closed[j]==1 or not grid.is_land(j): continue
			# No cutting across a corner of coast on a diagonal.
			if o.x!=0 and o.y!=0 and (not grid.is_land(cy*nx+x) or not grid.is_land(y*nx+cx)): continue
			var next:=cost[i]+(1.41421356 if o.x!=0 and o.y!=0 else 1.0)*cell
			if next<cost[j]:
				cost[j]=next; parent[j]=i
				_push(heap_f,heap_i,next+grid.at(j).distance_to(goal_at),j)
	if not found:
		return {"error":"No land route reaches it.","reason":"no_land_route","expanded":expanded,"cells":total}
	var raw:Array[Vector2]=[]
	var walk:=gi
	while walk>=0:
		raw.push_front(grid.at(walk))
		walk=parent[walk]
	raw[0]=start
	raw.append(goal)
	# Pull the lattice path taut: from each anchor, the farthest point still
	# reachable by a straight dry leg (galloping, then back off).
	var legs:Array[Vector2]=[]
	var anchor:=0
	var fine:=maxf(minf(SAMPLE_KM,cell*0.5),cell*0.1)
	var last_index:=raw.size()-1
	while anchor<last_index:
		var best:=anchor+1
		var span:=1
		var probe:=anchor+1
		while probe<=last_index and segment_land(raw[anchor],raw[probe],land,fine,0.0):
			best=probe; span*=2; probe=anchor+span
		for k in range(mini(probe,last_index),best,-1):
			if segment_land(raw[anchor],raw[k],land,fine,0.0): best=k; break
		legs.append(raw[best])
		anchor=best
	var length:=0.0
	var prev:=start
	for p:Vector2 in legs:
		length+=prev.distance_to(p); prev=p
	return {"ok":true,"points":legs,"length_km":length,"direct":false,"expanded":expanded,"cells":total}

## The ground's weights on the lattice, sampled once per point.
class Weights:
	var grid:Lattice
	var mix:Dictionary
	var roads:Array
	var road_half:float
	var grounded:bool
	var fac:PackedFloat32Array
	var hgt:PackedFloat32Array
	var rd:PackedInt32Array
	func _init(p_grid:Lattice,p_mix:Dictionary,p_roads:Array,p_half:float,p_grounded:bool)->void:
		grid=p_grid; mix=p_mix; roads=p_roads; road_half=p_half; grounded=p_grounded
		var total:=grid.nx*grid.ny
		fac=PackedFloat32Array(); fac.resize(total); fac.fill(-1.0)
		hgt=PackedFloat32Array(); hgt.resize(total)
		rd=PackedInt32Array(); rd.resize(total); rd.fill(-1)
	func prep(i:int)->float:
		if fac[i]>=0.0: return fac[i]
		var p:=grid.at(i)
		var g:Dictionary=March.ground_at(p) if grounded else {}
		var r:=March.road_at(p,roads,road_half) if not roads.is_empty() else -1
		rd[i]=r
		hgt[i]=float(g.get("h",0.0))
		fac[i]=March.factor(g,mix,r)
		return fac[i]
	func nearest(p:Vector2)->int:
		var x:=clampi(roundi((p.x-grid.lo.x)/grid.cell),0,grid.nx-1)
		var y:=clampi(roundi((p.y-grid.lo.y)/grid.cell),0,grid.ny-1)
		return y*grid.nx+x

static func _search_terrain(start:Vector2,goal:Vector2,land:Callable,ctx:Dictionary)->Dictionary:
	var mix:Dictionary=ctx.get("mix",{"foot":1.0})
	var dist:=start.distance_to(goal)
	var s:=_snap_to_land(start,land,1.0)
	if s==Vector2.INF: return {"error":"The army is not standing on land.","reason":"start_water"}
	var g:=_snap_to_land(goal,land,1.5)
	if g==Vector2.INF: return {"error":"The destination is not on land.","reason":"goal_water"}
	var straight_ok:=dist<0.05 or segment_land(start,goal,land,maxf(SAMPLE_KM,dist/LONG_SAMPLES))
	if straight_ok and dist<STRAIGHT_KM:
		return _with_profile(start,[goal],mix,land,{"ok":true,"direct":true,"straight":true,"expanded":0,"cells":0})
	var cell:=clampf(dist/float(ctx.get("cells_across",CELLS_ACROSS_TERRAIN)),MIN_CELL_KM,MAX_CELL_KM)
	var pad:=maxf(dist*0.6,cell*10.0)
	var lo:=Vector2(minf(s.x,g.x),minf(s.y,g.y))-Vector2.ONE*pad
	var hi:=Vector2(maxf(s.x,g.x),maxf(s.y,g.y))+Vector2.ONE*pad
	var size:=hi-lo
	if maxf(size.x,size.y)/cell>MAX_SIDE_TERRAIN: cell=maxf(size.x,size.y)/float(MAX_SIDE_TERRAIN)
	var nx:=maxi(2,ceili(size.x/cell)+1)
	var ny:=maxi(2,ceili(size.y/cell)+1)
	var total:=nx*ny
	var grid:=Lattice.new(lo,cell,nx,ny,land)
	var box:=Rect2(lo,size)
	var near_roads:Array=[]
	for r in ctx.get("roads",[]):
		if box.intersects(Rect2(r.a,Vector2.ZERO).expand(r.b).grow(1.0)): near_roads.append(r)
	var w:=Weights.new(grid,mix,near_roads,maxf(March.ROAD_HALF_KM,cell*0.6),March.has_ground())
	var climb_k:=March._mix_value(March.CLIMB_K,mix)
	var rivers:=March.rivers_near(box)
	var bridged:=March.bridge_tier()>=1
	var fmin:=minf(1.0,float(ctx.get("fmin",1.0)))
	var cost:=PackedFloat32Array(); cost.resize(total); cost.fill(INF)
	var parent:=PackedInt32Array(); parent.resize(total); parent.fill(-1)
	var closed:=PackedByteArray(); closed.resize(total)
	var si:=clampi(roundi((s.y-lo.y)/cell),0,ny-1)*nx+clampi(roundi((s.x-lo.x)/cell),0,nx-1)
	var gi:=clampi(roundi((g.y-lo.y)/cell),0,ny-1)*nx+clampi(roundi((g.x-lo.x)/cell),0,nx-1)
	si=grid.nearest_land(si,s)
	gi=grid.nearest_land(gi,g)
	if si<0 or gi<0: return {"error":"No land route reaches it.","reason":"no_land_route","expanded":0,"cells":total}
	var heap_f:=PackedFloat32Array(); var heap_i:=PackedInt32Array()
	var goal_at:=grid.at(gi)
	cost[si]=0.0
	w.prep(si)
	_push(heap_f,heap_i,grid.at(si).distance_to(goal_at)*fmin,si)
	var expanded:=0
	var found:=false
	const OFFSETS:=[Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1),Vector2i(1,1),Vector2i(-1,1),Vector2i(1,-1),Vector2i(-1,-1)]
	while heap_i.size()>0 and expanded<MAX_EXPANDED:
		var i:=_pop(heap_f,heap_i)
		if closed[i]==1: continue
		closed[i]=1; expanded+=1
		if i==gi: found=true; break
		var cx:=i%nx; var cy:=i/nx
		var fi:=w.fac[i]
		for o:Vector2i in OFFSETS:
			var x:=cx+o.x; var y:=cy+o.y
			if x<0 or y<0 or x>=nx or y>=ny: continue
			var j:=y*nx+x
			if closed[j]==1 or not grid.is_land(j): continue
			if o.x!=0 and o.y!=0 and (not grid.is_land(cy*nx+x) or not grid.is_land(y*nx+cx)): continue
			var fj:=w.prep(j)
			var step:=(1.41421356 if o.x!=0 and o.y!=0 else 1.0)*cell*(fi+fj)*0.5
			var climb:=w.hgt[j]-w.hgt[i]
			if climb>0.0: step+=climb*climb_k*(0.5 if w.rd[i]>=0 and w.rd[j]>=0 else 1.0)
			if rivers: step+=March.crossing_cost(March.crossing(grid.at(i),grid.at(j)),mix,bridged and w.rd[i]>=0 and w.rd[j]>=0)
			var next:=cost[i]+step
			if next<cost[j]:
				cost[j]=next; parent[j]=i
				_push(heap_f,heap_i,next+grid.at(j).distance_to(goal_at)*fmin,j)
	if not found:
		if straight_ok: return _with_profile(start,[goal],mix,land,{"ok":true,"direct":true,"straight":true,"expanded":expanded,"cells":total})
		return {"error":"No land route reaches it.","reason":"no_land_route","expanded":expanded,"cells":total}
	var raw:Array[Vector2]=[]
	var acc:=PackedFloat32Array()
	var walk:=gi
	while walk>=0:
		raw.push_front(grid.at(walk)); acc.insert(0,cost[walk])
		walk=parent[walk]
	raw[0]=start
	raw.append(goal); acc.append(acc[-1]+_seg_cost(w,raw[raw.size()-2],goal,cell,climb_k,rivers,bridged))
	# Pull the lattice path taut, but only where the straight leg is dry and
	# costs no more than the lattice path it replaces (no cutting over a spur).
	var legs:Array[Vector2]=[]
	var anchor:=0
	var fine:=maxf(minf(SAMPLE_KM,cell*0.5),cell*0.1)
	var last_index:=raw.size()-1
	while anchor<last_index:
		var best:=anchor+1
		var span:=1
		var probe:=anchor+1
		while probe<=last_index and _taut_ok(w,raw,acc,anchor,probe,land,fine,cell,climb_k,rivers,bridged):
			best=probe; span*=2; probe=anchor+span
		var lo_k:=best; var hi_k:=mini(probe,last_index)
		while hi_k-lo_k>1:
			var mid:=(lo_k+hi_k)/2
			if _taut_ok(w,raw,acc,anchor,mid,land,fine,cell,climb_k,rivers,bridged): lo_k=mid
			else: hi_k=mid
		legs.append(raw[lo_k])
		anchor=lo_k
	var result:=_with_profile(start,legs,mix,land,{"ok":true,"direct":straight_ok,"straight":false,"expanded":expanded,"cells":total})
	if straight_ok:
		# The straight road, when it is dry, stands if it is no slower.
		var line:=_with_profile(start,[goal],mix,land,{"ok":true,"direct":true,"straight":true,"expanded":expanded,"cells":total})
		if float(line.effort_km)<=float(result.effort_km)*1.001: return line
	return result

static func _seg_cost(w:Weights,a:Vector2,b:Vector2,cell:float,climb_k:float,rivers:bool,bridged:bool)->float:
	## A straight leg's cost read off the lattice weights (the same scale A* used).
	var d:=a.distance_to(b)
	var n:=maxi(1,ceili(d/maxf(0.05,cell*0.5)))
	var total:=0.0
	var prev_i:=w.nearest(a)
	w.prep(prev_i)
	for k in range(1,n+1):
		var p:=a.lerp(b,float(k)/float(n))
		var j:=w.nearest(p)
		w.prep(j)
		total+=d/float(n)*(w.fac[prev_i]+w.fac[j])*0.5
		var climb:=w.hgt[j]-w.hgt[prev_i]
		if climb>0.0: total+=climb*climb_k*(0.5 if w.rd[prev_i]>=0 and w.rd[j]>=0 else 1.0)
		prev_i=j
	if rivers: total+=March.crossing_cost(March.crossing(a,b),w.mix,bridged and w.rd[w.nearest(a)]>=0 and w.rd[w.nearest(b)]>=0)
	return total

static func _taut_ok(w:Weights,raw:Array[Vector2],acc:PackedFloat32Array,anchor:int,k:int,land:Callable,fine:float,cell:float,climb_k:float,rivers:bool,bridged:bool)->bool:
	if k==anchor+1: return true
	if not segment_land(raw[anchor],raw[k],land,fine,0.0): return false
	return _seg_cost(w,raw[anchor],raw[k],cell,climb_k,rivers,bridged)<=(acc[k]-acc[anchor])*1.02+0.05

static func _with_profile(start:Vector2,legs:Array,mix:Dictionary,land:Callable,out:Dictionary)->Dictionary:
	var prof:=March.profile(start,legs,mix,land)
	out["origin"]=start
	out["mix_key"]=March.mix_key(mix)
	out["points"]=prof.points
	out["e"]=prof.e
	out["t"]=prof.t
	out["effort_km"]=float(prof.effort_km)
	out["length_km"]=float(prof.length_km)
	out["ground"]=prof.ground
	out["ground_words"]=March.ground_words(prof)
	return out

static func _push(f:PackedFloat32Array,ids:PackedInt32Array,priority:float,id:int)->void:
	f.append(priority); ids.append(id)
	var c:=f.size()-1
	while c>0:
		var p:=(c-1)/2
		if f[p]<=f[c]: break
		var tf:=f[p]; f[p]=f[c]; f[c]=tf
		var ti:=ids[p]; ids[p]=ids[c]; ids[c]=ti
		c=p

static func _pop(f:PackedFloat32Array,ids:PackedInt32Array)->int:
	var top:=ids[0]
	var last:=f.size()-1
	f[0]=f[last]; ids[0]=ids[last]
	f.resize(last); ids.resize(last)
	var c:=0
	while true:
		var l:=c*2+1; var r:=l+1; var m:=c
		if l<last and f[l]<f[m]: m=l
		if r<last and f[r]<f[m]: m=r
		if m==c: break
		var tf:=f[m]; f[m]=f[c]; f[c]=tf
		var ti:=ids[m]; ids[m]=ids[c]; ids[c]=ti
		c=m
	return top

static func pack(points:Array)->Array:
	var out:Array=[]
	for p in points:
		var v:Vector2=p
		out.append({"x":v.x,"z":v.y})
	return out

static func unpack(points:Variant)->Array[Vector2]:
	var out:Array[Vector2]=[]
	if not points is Array: return out
	for p in points:
		if p is Dictionary and (p as Dictionary).has_all(["x","z"]): out.append(Vector2(float(p.x),float(p.z)))
		elif p is Vector2: out.append(p)
	return out

static func point_along(start:Vector2,points:Array[Vector2],travelled:float)->Vector2:
	## Position after walking `travelled` km from start along the legs.
	var prev:=start
	var left:=maxf(0.0,travelled)
	for p:Vector2 in points:
		var d:=prev.distance_to(p)
		if left<=d: return prev.move_toward(p,left)
		left-=d; prev=p
	return prev

static func remaining_legs(start:Vector2,points:Array[Vector2],travelled:float)->Array[Vector2]:
	var prev:=start
	var left:=maxf(0.0,travelled)
	var out:Array[Vector2]=[]
	var passed:=true
	for p:Vector2 in points:
		var d:=prev.distance_to(p)
		if passed and left<d: passed=false
		elif passed: left-=d
		if not passed: out.append(p)
		prev=p
	return out

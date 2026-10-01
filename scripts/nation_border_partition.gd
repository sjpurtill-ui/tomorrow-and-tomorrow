extends RefCounted
## THE PARTITION behind the nation borders (nation_borders.gd): which people
## holds each node of a coarse grid over the view, the washes cut along the
## exact meeting curves, and the lines where two peoples' lands meet. Pure:
## setup() and build() read only their input, so the work runs on a worker
## thread from copies and in tests from made-up ground.
##
## A claim scores a point 1 - d/rho: 1 at the hearth, 0 on the claim's own
## outline (rho is how far the outline reaches in that bearing), below 0
## outside it. A node goes to the people whose claim scores highest there,
## if that score is above 0: a big town's land reaches further than a
## hamlet's (a strength-weighted partition). Water and open ground go to
## nobody. Where a cell's corners differ, labelled marching squares cut it:
## between two peoples on the curve where their scores are equal (bisected,
## so both washes and the line between them share one edge); against open
## ground on the claim's outline; against water on the shore between the
## corners' heights. A stranger's land shows only on ground our people have
## charted; our own always shows.

const Stroke:=preload("res://scripts/scout_chart_stroke.gd")
const ChartIndex:=preload("res://scripts/scout_chart_index.gd")

## Samples of a claim's outline reach, one every 360/64 degrees.
const SHAPE_SAMPLES:=64
const NONE:=-1
const WATER:=-2
## Ground at or below this height (km) is sea or lake: local_terrain's
## SEA_LEVEL + 0.015, the land test the terrain, scouts and settlers share.
const SEA:=0.015
## The fused terrain sampler lifts every height by this much (terrain_patch_sampler.gd).
const PATCH_LIFT:=0.0006
## Claims are looked up in square buckets of this many cells (a power of two).
const BUCKET_SHIFT:=3
const BISECTIONS:=14

var origin:=Vector2.ZERO
var cell:=1.0
var n:=2
## [{owner_index, center, radius, table}]
var claims:Array=[]
## Per owner index: {color, wash, firm, foreign}.
var styles:Array=[]
var heights:=PackedFloat32Array()
var label:=PackedInt32Array()
var best:=PackedFloat32Array()
var lift:=0.0
var known_fade:=1.0
var _buckets:Dictionary={}
var _index:RefCounted=null
var _any_foreign:=false
var _crossings:Dictionary={}
var _segments:Dictionary={}
var _known_cache:Dictionary={}
var _wash_vertices:=PackedVector3Array()
var _wash_colors:=PackedColorArray()
var _wash_owner:=PackedInt32Array()


# --- Claims ----------------------------------------------------------------

## A claim's outline as SHAPE_SAMPLES reaches about its hearth, read from a
## star-shaped outline (the settlement model's 32-point claim), or a circle.
static func shape_table(center:Vector2,boundary:Variant,radius:float)->PackedFloat32Array:
	var table:=PackedFloat32Array()
	table.resize(SHAPE_SAMPLES)
	table.fill(maxf(radius,0.000001))
	var polar:Array[Vector2]=[]
	if boundary is PackedVector2Array or boundary is Array:
		for point_variant in boundary:
			if not point_variant is Vector2: continue
			var offset:Vector2=(point_variant as Vector2)-center
			if offset.length_squared()<1e-12: continue
			polar.append(Vector2(fposmod(offset.angle(),TAU),offset.length()))
	if polar.size()<3: return table
	polar.sort_custom(func(a:Vector2,b:Vector2)->bool: return a.x<b.x)
	var count:=polar.size()
	var next:=0
	for k in SHAPE_SAMPLES:
		var bearing:=TAU*float(k)/float(SHAPE_SAMPLES)
		while next<count and polar[next].x<bearing: next+=1
		var after:Vector2=polar[next%count]
		var before:Vector2=polar[(next-1+count)%count]
		var after_angle:=after.x+(TAU if next>=count else 0.0)
		var before_angle:=before.x-(TAU if next==0 else 0.0)
		var span:=after_angle-before_angle
		var t:=0.0 if span<=0.000001 else clampf((bearing-before_angle)/span,0.0,1.0)
		table[k]=maxf(lerpf(before.y,after.y,t),0.000001)
	return table


## 1 at the hearth, 0 on the claim's outline, below 0 beyond it.
static func claim_score(claim:Dictionary,point:Vector2)->float:
	var offset:=point-(claim.center as Vector2)
	var distance:=offset.length()
	if distance<=0.0000001: return 1.0
	var table:PackedFloat32Array=claim.table
	var f:=fposmod(atan2(offset.y,offset.x),TAU)/TAU*float(SHAPE_SAMPLES)
	var i:=int(f)%SHAPE_SAMPLES
	var reach:=lerpf(table[i],table[(i+1)%SHAPE_SAMPLES],f-floorf(f))
	return 1.0-distance/maxf(reach,0.0000001)


## How much of a claim's colour shows at `score`: full through the heart of
## the land, thinning to nothing at its edge, with no rim. A kingdom keeps its
## full colour further out.
static func wash_falloff(score:float,firm:bool)->float:
	return 1.0-smoothstep(0.62 if firm else 0.45,1.0,1.0-score)


# --- Setup ---------------------------------------------------------------------

## input: origin, cell, n, claims [{owner_index, center, radius, table}],
## styles [{color, wash, firm, foreign}], heights (n*n, NAN where unknown,
## may be filled later with set_heights), revealed (charted ground records,
## CivilizationSystem.revealed_areas), lift, known_fade (km).
func setup(input:Dictionary)->void:
	origin=input.get("origin",Vector2.ZERO)
	cell=maxf(float(input.get("cell",1.0)),0.000001)
	n=maxi(2,int(input.get("n",2)))
	claims=input.get("claims",[])
	styles=input.get("styles",[])
	lift=float(input.get("lift",0.0))
	known_fade=maxf(float(input.get("known_fade",cell*0.6)),0.000001)
	for style:Dictionary in styles:
		if bool(style.get("foreign",false)): _any_foreign=true
	if _any_foreign: _index=ChartIndex.new(input.get("revealed",[]))
	var given:Variant=input.get("heights",PackedFloat32Array())
	if given is PackedFloat32Array and (given as PackedFloat32Array).size()==n*n: heights=given
	else:
		heights=PackedFloat32Array()
		heights.resize(n*n)
		heights.fill(NAN)
	_index_claims()


func _index_claims()->void:
	var last:=(n-1)>>BUCKET_SHIFT
	for ci in claims.size():
		var claim:Dictionary=claims[ci]
		var center:Vector2=claim.center
		var reach:=float(claim.radius)+cell*1.5
		var low_x:=clampi(floori((center.x-reach-origin.x)/cell)>>BUCKET_SHIFT,0,last)
		var low_y:=clampi(floori((center.y-reach-origin.y)/cell)>>BUCKET_SHIFT,0,last)
		var high_x:=clampi(floori((center.x+reach-origin.x)/cell)>>BUCKET_SHIFT,0,last)
		var high_y:=clampi(floori((center.y+reach-origin.y)/cell)>>BUCKET_SHIFT,0,last)
		if center.x+reach<origin.x or center.y+reach<origin.y: continue
		if center.x-reach>origin.x+cell*float(n-1) or center.y-reach>origin.y+cell*float(n-1): continue
		for by in range(low_y,high_y+1):
			for bx in range(low_x,high_x+1):
				var key:=Vector2i(bx,by)
				if not _buckets.has(key): _buckets[key]=[]
				(_buckets[key] as Array).append(ci)


func _claims_at(point:Vector2)->Array:
	var last:=(n-1)>>BUCKET_SHIFT
	var bx:=clampi(floori((point.x-origin.x)/cell)>>BUCKET_SHIFT,0,last)
	var by:=clampi(floori((point.y-origin.y)/cell)>>BUCKET_SHIFT,0,last)
	return _buckets.get(Vector2i(bx,by),[])


func node_point(i:int)->Vector2:
	return origin+Vector2(float(i%n),float(int(float(i)/float(n))))*cell


## The strongest claim of `owner` at `point`; very low when it has none near.
func owner_score(owner:int,point:Vector2)->float:
	var top:=-1.0e9
	for ci in _claims_at(point):
		var claim:Dictionary=claims[ci]
		if int(claim.owner_index)==owner: top=maxf(top,claim_score(claim,point))
	return top


## Who holds `point`: [owner index or NONE, its score]. Water is not judged here.
func holder_at(point:Vector2)->Array:
	var top:=-1.0e9
	var who:=NONE
	for ci in _claims_at(point):
		var claim:Dictionary=claims[ci]
		var score:=claim_score(claim,point)
		var owner:=int(claim.owner_index)
		if score>top or (score==top and owner<who): top=score;who=owner
	return [who if top>0.0 else NONE,top]


# --- Building ------------------------------------------------------------------

## Every node's holder before the ground is known. Returns which nodes need
## a height: each held node and its neighbours (the cells that draw).
func assign()->PackedByteArray:
	var count:=n*n
	label.resize(count);label.fill(NONE)
	best.resize(count);best.fill(-1.0e9)
	var needed:=PackedByteArray()
	needed.resize(count)
	for iy in n:
		for ix in n:
			var list:Array=_buckets.get(Vector2i(ix>>BUCKET_SHIFT,iy>>BUCKET_SHIFT),[])
			if list.is_empty(): continue
			var point:=origin+Vector2(float(ix),float(iy))*cell
			var top:=-1.0e9
			var who:=NONE
			for ci in list:
				var claim:Dictionary=claims[ci]
				var score:=claim_score(claim,point)
				var owner:=int(claim.owner_index)
				if score>top or (score==top and owner<who): top=score;who=owner
			var i:=iy*n+ix
			best[i]=top
			if top>0.0:
				label[i]=who
				for oy in range(maxi(0,iy-1),mini(n,iy+2)):
					for ox in range(maxi(0,ix-1),mini(n,ix+2)): needed[oy*n+ox]=1
	return needed


## The ground at each node (n*n, NAN where it was not needed).
func set_heights(values:PackedFloat32Array)->void:
	if values.size()==n*n: heights=values


## Everything after the ground: water, the cut cells, the washes and lines.
## {wash_vertices, wash_colors, wash_owner, lines, label, heights}.
func build(cancel:Array=[false])->Dictionary:
	for i in n*n:
		if is_finite(heights[i]) and heights[i]<=SEA: label[i]=WATER
	for iy in n-1:
		if bool(cancel[0]): return {}
		for ix in n-1:
			_cell(ix,iy)
	if bool(cancel[0]): return {}
	return {"wash_vertices":_wash_vertices,"wash_colors":_wash_colors,"wash_owner":_wash_owner,"lines":_lines(),"label":label,"heights":heights}


func _cell(ix:int,iy:int)->void:
	var i0:=iy*n+ix
	var nodes:=PackedInt32Array([i0,i0+1,i0+n+1,i0+n])
	var labels:=PackedInt32Array([label[nodes[0]],label[nodes[1]],label[nodes[2]],label[nodes[3]]])
	if maxi(maxi(labels[0],labels[1]),maxi(labels[2],labels[3]))<0: return
	if labels[0]==labels[1] and labels[1]==labels[2] and labels[2]==labels[3]:
		_emit([_node_vertex(nodes[0]),_node_vertex(nodes[1]),_node_vertex(nodes[2]),_node_vertex(nodes[3])],labels[0])
		return
	# The perimeter: a crossing on each edge between unlike corners.
	var cuts:Array=[]
	for k in 4:
		if labels[k]!=labels[(k+1)%4]: cuts.append({"k":k,"x":_crossing(nodes[k],nodes[(k+1)%4])})
	var m:=cuts.size()
	# Each run of like corners, cut off by the chord between its crossings.
	var run_labels:=PackedInt32Array()
	var run_sides:=PackedVector2Array()
	for r in m:
		var start:Dictionary=cuts[r]
		var stop:Dictionary=cuts[(r+1)%m]
		var k:=(int(start.k)+1)%4
		var owner:=labels[k]
		run_labels.append(owner)
		run_sides.append(node_point(nodes[k]))
		var piece:Array=[_crossing_vertex(start.x,owner)]
		while true:
			piece.append(_node_vertex(nodes[k]))
			if k==int(stop.k): break
			k=(k+1)%4
		piece.append(_crossing_vertex(stop.x,owner))
		if owner>=0: _emit(piece,owner)
	if m==2:
		_segment(cuts[0].x,cuts[1].x,run_labels[0],run_sides[0],run_labels[1])
		return
	# Three or more crossings enclose the middle; whoever holds the cell's
	# centre holds it, and it meets each run on the chord that cut it off.
	var middle:=_centre_holder(ix,iy,nodes)
	if middle>=0:
		var inner:Array=[]
		for cut:Dictionary in cuts: inner.append(_crossing_vertex(cut.x,middle))
		_emit(inner,middle)
	for r in m:
		_segment(cuts[r].x,cuts[(r+1)%m].x,run_labels[r],run_sides[r],middle)


func _centre_holder(ix:int,iy:int,nodes:PackedInt32Array)->int:
	var ground:=0.0
	var count:=0
	for node in nodes:
		if is_finite(heights[node]): ground+=heights[node];count+=1
	if count>0 and ground/float(count)<=SEA: return WATER
	return int(holder_at(origin+(Vector2(float(ix),float(iy))+Vector2(0.5,0.5))*cell)[0])


## The point where the edge from node a to node b changes hands.
func _crossing(a:int,b:int)->Dictionary:
	if a>b:
		var held:=a;a=b;b=held
	var id:=a*2+(0 if b==a+1 else 1)
	if _crossings.has(id): return _crossings[id]
	var pa:=node_point(a)
	var pb:=node_point(b)
	var la:=label[a]
	var lb:=label[b]
	var ha:=heights[a]
	var hb:=heights[b]
	if not is_finite(ha): ha=hb if is_finite(hb) else 1.0
	if not is_finite(hb): hb=ha
	var t:=0.5
	if la>=0 and lb>=0:
		var low:=0.0
		var high:=1.0
		for step in BISECTIONS:
			var mid:=(low+high)*0.5
			var at:=pa.lerp(pb,mid)
			if owner_score(la,at)-owner_score(lb,at)>0.0: low=mid
			else: high=mid
		t=(low+high)*0.5
	elif la>=0 and lb==NONE: t=_outline(pa,pb,la)
	elif lb>=0 and la==NONE: t=1.0-_outline(pb,pa,lb)
	elif (la==WATER)!=(lb==WATER) and not is_equal_approx(ha,hb): t=clampf((ha-SEA)/(ha-hb),0.0,1.0)
	var row:=int(float(a)/float(n))
	var column:=a%n
	var border:=(b==a+1 and (row==0 or row==n-1)) or (b!=a+1 and (column==0 or column==n-1))
	var result:={"id":id,"p":pa.lerp(pb,t),"h":lerpf(ha,hb,t),"border":border}
	_crossings[id]=result
	return result


## Where `owner`'s claim ends between `inside` and `outside`, as a fraction.
func _outline(inside:Vector2,outside:Vector2,owner:int)->float:
	var low:=0.0
	var high:=1.0
	for step in BISECTIONS:
		var mid:=(low+high)*0.5
		if owner_score(owner,inside.lerp(outside,mid))>0.0: low=mid
		else: high=mid
	return (low+high)*0.5


## A corner of a piece: where it is, its ground, the holder's score there and
## a key for the charted-ground cache (nodes >= 0, crossings < 0).
func _node_vertex(i:int)->Dictionary:
	return {"p":node_point(i),"h":heights[i],"s":best[i],"key":i}


func _crossing_vertex(crossing:Dictionary,owner:int)->Dictionary:
	if owner<0: return {"p":crossing.p,"h":crossing.h,"s":0.0,"key":-1-int(crossing.id)}
	return {"p":crossing.p,"h":crossing.h,"s":owner_score(owner,crossing.p),"key":-1-int(crossing.id)}


## One convex piece of a people's land, fanned into triangles.
func _emit(polygon:Array,owner:int)->void:
	if owner<0 or owner>=styles.size() or polygon.size()<3: return
	var style:Dictionary=styles[owner]
	var color:Color=style.get("color",Color.WHITE)
	var wash:=float(style.get("wash",0.15))
	var firm:=bool(style.get("firm",false))
	var foreign:=bool(style.get("foreign",false))
	var vertices:Array[Vector3]=[]
	var colors:Array[Color]=[]
	for vertex:Dictionary in polygon:
		var point:Vector2=vertex.p
		var ground:=float(vertex.h)
		if not is_finite(ground): ground=0.0
		var alpha:=wash*wash_falloff(float(vertex.s),firm)
		if foreign and alpha>0.0: alpha*=_known(point,int(vertex.key))
		vertices.append(Vector3(point.x,maxf(ground,0.0)+lift,point.y))
		colors.append(Color(color,alpha))
	for k in range(1,polygon.size()-1):
		for corner in [0,k,k+1]:
			_wash_vertices.append(vertices[corner])
			_wash_colors.append(colors[corner])
			_wash_owner.append(owner)


## 0 on ground our people have not charted, rising to 1 a little inside it.
func _known(point:Vector2,key:int)->float:
	if _index==null: return 1.0
	if _known_cache.has(key): return _known_cache[key]
	var value:=smoothstep(0.0,known_fade,known_depth(point))
	_known_cache[key]=value
	return value


## How far inside the charted ground `point` lies (km); negative or -INF outside.
func known_depth(point:Vector2)->float:
	if _index==null: return INF
	var deepest:=-INF
	var bucket:=Vector2i(floori(point.x/ChartIndex.CELL),floori(point.y/ChartIndex.CELL))
	for segment:Dictionary in (_index.get("buckets") as Dictionary).get(bucket,[]):
		deepest=maxf(deepest,float(segment.radius)-point.distance_to(Geometry2D.get_closest_point_to_segment(point,segment.a,segment.b)))
	for segment:Dictionary in _index.get("wide"):
		deepest=maxf(deepest,float(segment.radius)-point.distance_to(Geometry2D.get_closest_point_to_segment(point,segment.a,segment.b)))
	return deepest


# --- Lines ---------------------------------------------------------------------

## One piece of a meeting line between holders x and y, oriented so the
## lower-numbered people lies on its left; `side` is a point on x's side.
func _segment(start:Dictionary,stop:Dictionary,x:int,side:Vector2,y:int)->void:
	if x<0 or y<0 or x==y: return
	var a:=mini(x,y)
	var b:=maxi(x,y)
	var p:Vector2=start.p
	var q:Vector2=stop.p
	var forward:=((q-p).cross(side-p)>0.0)==(x==a)
	var key:=Vector2i(a,b)
	if not _segments.has(key): _segments[key]=[]
	(_segments[key] as Array).append([int(start.id),int(stop.id)] if forward else [int(stop.id),int(start.id)])


## The meeting lines, chained, smoothed and cut where they leave the land or
## reach ground we have not charted: [{a, b, points, heights, strength,
## open_start, open_end, closed}]. An end is open where the line runs out into
## open land, water or the unknown, closed where it meets another line or the
## grid's edge.
func _lines()->Array:
	var touching:Dictionary={}
	for key:Vector2i in _segments:
		for segment:Array in _segments[key]:
			for id in segment: (touching.get_or_add(int(id),{}) as Dictionary)[key]=true
	var out:Array=[]
	for key:Vector2i in _segments:
		for chain:Array in _chains(_segments[key]):
			var ids:PackedInt32Array=chain[0]
			var closed:bool=chain[1]
			var raw:=PackedVector2Array()
			for id in ids: raw.append((_crossings[id] as Dictionary).p)
			var open_start:=not closed and _open_end(ids[0],touching)
			var open_end:=not closed and _open_end(ids[ids.size()-1],touching)
			out.append_array(_finish(key.x,key.y,raw,closed,open_start,open_end))
	return out


func _open_end(id:int,touching:Dictionary)->bool:
	if bool((_crossings[id] as Dictionary).get("border",false)): return false
	return (touching.get(id,{}) as Dictionary).size()<2


## Segments [from, to] chained head to tail: [[ids, closed]].
static func _chains(segments:Array)->Array:
	var leaving:Dictionary={}
	var arriving:Dictionary={}
	for index in segments.size():
		var segment:Array=segments[index]
		(leaving.get_or_add(int(segment[0]),[]) as Array).append(index)
		arriving[int(segment[1])]=int(arriving.get(int(segment[1]),0))+1
	var used:=PackedByteArray()
	used.resize(segments.size())
	var chains:Array=[]
	for pass_index in 2:
		for index in segments.size():
			if used[index]==1: continue
			var first:=int(segments[index][0])
			# Open chains first (nothing arrives at their start), then loops.
			if pass_index==0 and int(arriving.get(first,0))>0: continue
			var ids:=PackedInt32Array([first])
			var current:=index
			while current>=0:
				used[current]=1
				var head:=int(segments[current][1])
				ids.append(head)
				current=-1
				for candidate in leaving.get(head,[]):
					if used[int(candidate)]==0: current=int(candidate);break
			chains.append([ids,ids.size()>2 and ids[0]==ids[ids.size()-1]])
	return chains


## A chained line smoothed, given its ground, strength and charted state,
## and cut into the runs that are drawn.
func _finish(a:int,b:int,raw:PackedVector2Array,closed:bool,open_start:bool,open_end:bool)->Array:
	var points:=raw
	if raw.size()>=3:
		points=Stroke.smooth(raw,cell*0.4,cell*0.12)
		if closed and points.size()>=2 and points[0].distance_to(points[points.size()-1])>cell*0.05: points.append(points[0])
	if points.size()<2: return []
	var foreign_a:=bool((styles[a] as Dictionary).get("foreign",false)) if a<styles.size() else false
	var foreign_b:=bool((styles[b] as Dictionary).get("foreign",false)) if b<styles.size() else false
	# Packed arrays are values: a run is gathered in locals, then stored.
	var runs:Array=[]
	var run_points:=PackedVector2Array()
	var run_heights:=PackedFloat32Array()
	var run_strength:=PackedFloat32Array()
	var run_opens:=false
	for i in points.size():
		var point:=points[i]
		var ground:=height_at(point)
		var keep:=ground>=SEA*0.5
		if keep and (foreign_a or foreign_b): keep=known_depth(point)>0.0
		if not keep:
			if not run_points.is_empty(): runs.append({"a":a,"b":b,"points":run_points,"heights":run_heights,"strength":run_strength,"open_start":run_opens,"open_end":true,"closed":false})
			run_points=PackedVector2Array()
			run_heights=PackedFloat32Array()
			run_strength=PackedFloat32Array()
			continue
		if run_points.is_empty(): run_opens=open_start if i==0 else true
		run_points.append(point)
		run_heights.append(maxf(ground,0.0))
		run_strength.append(minf(owner_score(a,point),owner_score(b,point)))
	if not run_points.is_empty(): runs.append({"a":a,"b":b,"points":run_points,"heights":run_heights,"strength":run_strength,"open_start":run_opens,"open_end":open_end,"closed":false})
	var out:Array=[]
	for run:Dictionary in runs:
		if (run.points as PackedVector2Array).size()<2: continue
		run.closed=closed and runs.size()==1
		if run.closed:
			run.open_start=false
			run.open_end=false
		out.append(run)
	return out


## The ground under `point`, from the nodes about it (NAN-free).
func height_at(point:Vector2)->float:
	var fx:=(point.x-origin.x)/cell
	var fy:=(point.y-origin.y)/cell
	var ix:=clampi(floori(fx),0,n-2)
	var iy:=clampi(floori(fy),0,n-2)
	var tx:=clampf(fx-float(ix),0.0,1.0)
	var ty:=clampf(fy-float(iy),0.0,1.0)
	var corners:=[heights[iy*n+ix],heights[iy*n+ix+1],heights[(iy+1)*n+ix],heights[(iy+1)*n+ix+1]]
	var weights:=[(1.0-tx)*(1.0-ty),tx*(1.0-ty),(1.0-tx)*ty,tx*ty]
	var total:=0.0
	var weight:=0.0
	for k in 4:
		if is_finite(float(corners[k])): total+=float(corners[k])*float(weights[k]);weight+=float(weights[k])
	return total/weight if weight>0.000001 else 1.0


# --- Ground ----------------------------------------------------------------------

## A row request for the fused terrain sampler (terrain_patch_sampler.gd):
## the grid itself, with nothing to reuse.
class RowJob extends RefCounted:
	var resolution:=2
	var center:=Vector2.ZERO
	var span:=1.0
	var reuse_resolution:=0
	var reuse_stride:=1
	var reuse_offset:=Vector2i.ZERO
	var reuse_center:=Vector2.ZERO
	var reuse_span:=1.0
	var reuse_vertices:=PackedVector3Array()
	var reuse_colors:=PackedColorArray()
	var reuse_climate:=PackedVector2Array()
	var reuse_geology:=PackedVector2Array()
	var reuse_seasons:=PackedFloat32Array()


## The ground at the needed nodes of a grid, from `cache` (lattice node ->
## height, kept between builds for this zoom `level`) or the fused sampler a
## row at a time. Any thread. NAN where not needed; 1.0 (land) without a sampler.
static func sample_heights(sampler:RefCounted,origin_point:Vector2,cell_km:float,count:int,needed:PackedByteArray,cache:Dictionary,level:int,cancel:Array=[false])->PackedFloat32Array:
	var out:=PackedFloat32Array()
	out.resize(count*count)
	out.fill(NAN)
	var base:=Vector2i(roundi(origin_point.x/cell_km),roundi(origin_point.y/cell_km))
	var job:=RowJob.new()
	job.resolution=count
	job.span=float(count-1)*cell_km
	job.center=Vector2(float(base.x),float(base.y))*cell_km+Vector2.ONE*float(count-1)*0.5*cell_km
	for y in count:
		if bool(cancel[0]): return PackedFloat32Array()
		var missing:=false
		for x in count:
			var i:=y*count+x
			if needed[i]==0: continue
			var key:=Vector3i(base.x+x,base.y+y,level)
			if cache.has(key): out[i]=cache[key]
			else: missing=true
		if not missing: continue
		if sampler==null:
			for x in count:
				if needed[y*count+x]==1: out[y*count+x]=1.0
			continue
		var row:PackedFloat32Array=sampler.call("sample_rows",job,y,1)[0]
		for x in count:
			var ground:=row[x]-PATCH_LIFT
			cache[Vector3i(base.x+x,base.y+y,level)]=ground
			if needed[y*count+x]==1: out[y*count+x]=ground
	return out

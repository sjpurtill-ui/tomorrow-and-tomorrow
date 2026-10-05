extends RefCounted
## FRONT WORMS: where two sides' forces actually meet, derived, never drawn
## by hand.
##
## Each side exerts influence on the ground around its forces: a bump whose
## height is the square root of its (estimated) strength and whose reach
## grows slowly with size. The front is where the two influences balance,
## the zero line of (ours - theirs), kept only where both sides are actually
## present. So the line bulges toward the weaker side where one side is
## locally stronger, thins where it is stretched, breaks where there is a gap
## between the forces, and reforms when they close again. Nothing in the
## derivation is random: the same positions give the same front.
##
## Observation honesty: enemy sources are dated observations only. Their
## weight fades with the age of the report, and every front vertex carries
## the age of what it was derived from so the map can show it (dashed and
## pale once stale). No observed enemy, no front.
##
## Era presentation (mode): before drill and bands of a few hundred there are
## no fronts at all, only raid tracks and clash marks ("raid"). Hosts meeting
## in the field get a short face-off line where they touch ("host").
## Regiment-scale war gets continuous fronts with offensive arrows to the
## general's objective ("front"); staffs and many armies add fallback lines
## and supply lines ("theatre").
##
## Pure static helpers over plain data: tests call derive() with positions.
##
## Scale: a long front with dozens of hosts and battles stays cheap. The
## lattice follows the theatre's shape (the long side gets GRID_LONG cells),
## hosts standing almost on one another act as one source, and each source
## only touches the cells within its reach.

## Hard bounds: population changes numbers on a front, never node counts.
const GRID:=32
const GRID_LONG:=48
const GRID_SHORT:=20
const MAX_FRIENDLY:=64
const MAX_ENEMY:=96
const MAX_FRONTS:=8
const MAX_POINTS:=128
const MAX_ARROWS:=24
const MAX_CLASHES:=24
const MAX_BATTLES:=32
## Supply lines from home in a theatre: the farthest hosts only.
const MAX_SUPPLY:=16
## Sources nearer than this share of the theatre's scale act as one.
const MERGE_SIGMA:=0.25
## Report age (days) at which an enemy observation has lost most weight.
const AGE_HALF_LIFE:=45.0
## Age beyond which the drawn line is shown as stale.
const STALE_DAYS:=20
## A vertex needs both sides' normalised influence above this to be a front.
const CONTACT:=0.22


## A party too small to hold a line: a handful of people, or a small fraction
## of the force it faces. It is drawn as its own small inked mark
## (hud/army_marks.gd), never given a front, a face-off line or a battle line.
const TINY_PARTY:=8
const TINY_SHARE:=0.2
## Beyond this a force is a host in its own right, however large its foe.
const PARTY_CAP:=60


static func tiny(strength:float,facing_strength:float=0.0)->bool:
	if strength<float(TINY_PARTY): return true
	return strength<float(PARTY_CAP) and facing_strength>0.0 and strength<facing_strength*TINY_SHARE


## The sources that can hold a line of contact: each is compared with the
## nearest force on the other side (the one it actually faces).
static func substantial(sources:Array,opposing:Array)->Array:
	var out:Array=[]
	for s in sources:
		var nearest:=INF; var facing:=0.0
		for o in opposing:
			var d:=(s.pos as Vector2).distance_to(o.pos)
			if d<nearest: nearest=d; facing=float(o.get("strength",0.0))
		if not tiny(float(s.get("strength",0.0)),facing): out.append(s)
	return out


## A fight in which one side is only a handful, or hopelessly outnumbered:
## drawn as a skirmish mark, not as two opposed battle lines.
static func skirmish(ours:int,theirs:int)->bool:
	if ours<=0 or theirs<=0: return false
	return tiny(float(theirs),float(ours)) or tiny(float(ours),float(theirs))


## Presentation stage from what the people know and field, not the calendar.
static func mode(stage:String,known:Array,largest_force:int,armies:int,theatre_troops:int)->String:
	var drilled:=known.has("formation_drill")
	if not drilled and largest_force<250: return "raid"
	if stage=="hearth" and largest_force<1000: return "raid" if not drilled else "host"
	if largest_force<1000 or not drilled: return "host"
	if known.has("military_staffs") and (armies>=3 or theatre_troops>=20000): return "theatre"
	return "front"


static func _sigma(friendly:Array,enemy:Array)->float:
	# The theatre's own scale: the typical gap between opposing forces.
	var total:=0.0
	var count:=0
	for f in friendly:
		var best:=INF
		for e in enemy: best=minf(best,(f.pos as Vector2).distance_to(e.pos))
		if best<INF: total+=best; count+=1
	var gap:=total/float(maxi(1,count))
	return clampf(gap*0.55,0.12,600.0)


static func _weight(source:Dictionary,is_enemy:bool)->float:
	var strength:=maxf(1.0,float(source.get("strength",1.0)))
	var weight:=sqrt(strength)
	if is_enemy:
		var age:=maxf(0.0,float(source.get("age_days",0.0)))
		weight*=0.35+0.65*exp(-age/AGE_HALF_LIFE)
	return weight


static func _reach(source:Dictionary,sigma:float)->float:
	var strength:=maxf(1.0,float(source.get("strength",1.0)))
	return sigma*clampf(0.8+0.08*log(strength)/log(10.0),0.8,1.3)


## Sources standing nearer each other than a quarter of the theatre's scale
## act as one at the front's resolution: their weights add (so coincident
## sources give the very same field); position, reach and report age are
## weighted. [[pos, weight, reach, age]].
static func _merged(sources:Array,is_enemy:bool,sigma:float)->Array:
	var out:Array=[]
	var radius:=sigma*MERGE_SIGMA
	for s in sources:
		var w:=_weight(s,is_enemy)
		var r:=_reach(s,sigma)
		var p:Vector2=s.pos
		var age:=float(s.get("age_days",0.0)) if is_enemy else 0.0
		var joined:=false
		for entry in out:
			if (entry[0] as Vector2).distance_to(p)<=radius:
				var before:float=entry[1]
				var total:=before+w
				entry[0]=(entry[0] as Vector2)*(before/total)+p*(w/total)
				entry[2]=(float(entry[2])*before+r*w)/total
				entry[3]=(float(entry[3])*before+age*w)/total
				entry[1]=total
				joined=true; break
		if not joined: out.append([p,w,r,age])
	return out


## The influence field on a lattice over the theatre: GRID_LONG cells along
## its long side, proportionally fewer across (never under GRID_SHORT).
## Each source is laid on the cells within three reaches of it (a separable
## Gaussian: one multiply-add a cell).
static func field(friendly:Array,enemy:Array)->Dictionary:
	var sigma:=_sigma(friendly,enemy)
	var box:=Rect2((friendly[0].pos as Vector2),Vector2.ZERO)
	for s in friendly+enemy: box=box.expand(s.pos)
	box=box.grow(sigma*2.2)
	var nx:=GRID_LONG; var ny:=GRID_LONG
	if box.size.x>=box.size.y: ny=clampi(roundi(float(GRID_LONG)*box.size.y/maxf(box.size.x,0.000001)),GRID_SHORT,GRID_LONG)
	else: nx=clampi(roundi(float(GRID_LONG)*box.size.x/maxf(box.size.y,0.000001)),GRID_SHORT,GRID_LONG)
	var step:=Vector2(box.size.x/float(nx-1),box.size.y/float(ny-1))
	var cells:=nx*ny
	var ours:=PackedFloat32Array(); ours.resize(cells)
	var theirs:=PackedFloat32Array(); theirs.resize(cells)
	var aged:=PackedFloat32Array(); aged.resize(cells)
	var layers:=[[_merged(friendly,false,sigma),false],[_merged(enemy,true,sigma),true]]
	var ex:=PackedFloat32Array()
	for layer in layers:
		var enemy_layer:bool=layer[1]
		for source in layer[0]:
			var pos:Vector2=source[0]
			var weight:float=source[1]
			var reach:float=source[2]
			var age:float=source[3]
			var cut:=reach*3.0
			var i0:=maxi(0,ceili((pos.x-cut-box.position.x)/step.x)); var i1:=mini(nx-1,floori((pos.x+cut-box.position.x)/step.x))
			var j0:=maxi(0,ceili((pos.y-cut-box.position.y)/step.y)); var j1:=mini(ny-1,floori((pos.y+cut-box.position.y)/step.y))
			if i0>i1 or j0>j1: continue
			var inv:=1.0/(2.0*reach*reach)
			ex.resize(i1-i0+1)
			for i in range(i0,i1+1):
				var dx:=box.position.x+float(i)*step.x-pos.x
				ex[i-i0]=exp(-dx*dx*inv)
			for j in range(j0,j1+1):
				var dy:=box.position.y+float(j)*step.y-pos.y
				var wy:=weight*exp(-dy*dy*inv)
				if wy<=weight*0.0001: continue
				var row:=j*nx
				if enemy_layer:
					for i in range(i0,i1+1):
						var v:=wy*ex[i-i0]
						theirs[row+i]+=v; aged[row+i]+=v*age
				else:
					for i in range(i0,i1+1): ours[row+i]+=wy*ex[i-i0]
	var max_ours:=0.0
	var max_theirs:=0.0
	var age_field:=PackedFloat32Array(); age_field.resize(cells)
	for k in cells:
		max_ours=maxf(max_ours,ours[k]); max_theirs=maxf(max_theirs,theirs[k])
		if theirs[k]>0.0: age_field[k]=aged[k]/theirs[k]
	return {"box":box,"step":step,"nx":nx,"ny":ny,"sigma":sigma,"ours":ours,"theirs":theirs,"age":age_field,"max_ours":maxf(max_ours,0.0001),"max_theirs":maxf(max_theirs,0.0001)}


static func _sample(values:PackedFloat32Array,f:Dictionary,p:Vector2)->float:
	var box:Rect2=f.box
	var step:Vector2=f.step
	var nx:=int(f.get("nx",GRID)); var ny:=int(f.get("ny",GRID))
	var gx:=clampf((p.x-box.position.x)/step.x,0.0,float(nx-1)-0.001)
	var gy:=clampf((p.y-box.position.y)/step.y,0.0,float(ny-1)-0.001)
	var i:=int(gx); var j:=int(gy); var tx:=gx-float(i); var ty:=gy-float(j)
	var a:=values[j*nx+i]; var b:=values[j*nx+i+1]; var c:=values[(j+1)*nx+i]; var d:=values[(j+1)*nx+i+1]
	return lerpf(lerpf(a,b,tx),lerpf(c,d,tx),ty)


## Normalised presence of both sides at p (0..1 each).
static func presence(f:Dictionary,p:Vector2)->Vector2:
	return Vector2(_sample(f.ours,f,p)/float(f.max_ours),_sample(f.theirs,f,p)/float(f.max_theirs))


## Marching squares on (ours - theirs) = 0, chained into polylines.
static func _contour(f:Dictionary)->Array:
	var box:Rect2=f.box
	var step:Vector2=f.step
	var nx:=int(f.get("nx",GRID)); var ny:=int(f.get("ny",GRID))
	var ours:PackedFloat32Array=f.ours
	var theirs:PackedFloat32Array=f.theirs
	# Raw strengths: the stronger side pushes the line toward the weaker.
	var diff:=PackedFloat32Array(); diff.resize(nx*ny)
	for k in nx*ny: diff[k]=ours[k]-theirs[k]
	# Edge keys (integers) identify shared crossings so segments chain exactly:
	# a horizontal edge from lattice point k is 2k, a vertical one 2k+1.
	var segments:Array=[]
	for j in ny-1:
		for i in nx-1:
			var k:=j*nx+i
			var v0:=diff[k]; var v1:=diff[k+1]; var v2:=diff[k+nx+1]; var v3:=diff[k+nx]
			var s0:=v0>0.0
			if s0==(v1>0.0) and s0==(v2>0.0) and s0==(v3>0.0): continue
			var values:=[v0,v1,v2,v3]
			var corners:=[Vector2i(i,j),Vector2i(i+1,j),Vector2i(i+1,j+1),Vector2i(i,j+1)]
			var keys:=[k*2,(k+1)*2+1,(k+nx)*2,k*2+1]
			var crossings:=[]
			for e in 4:
				var a:float=values[e]; var b:float=values[(e+1)%4]
				if (a>0.0)==(b>0.0): continue
				var ca:Vector2i=corners[e]; var cb:Vector2i=corners[(e+1)%4]
				var pa:=box.position+Vector2(float(ca.x)*step.x,float(ca.y)*step.y)
				var pb:=box.position+Vector2(float(cb.x)*step.x,float(cb.y)*step.y)
				crossings.append([keys[e],pa.lerp(pb,a/(a-b))])
			if crossings.size()==2: segments.append([crossings[0],crossings[1]])
			elif crossings.size()==4:
				# Saddle: pair by the cell centre's sign.
				var centre:=(v0+v1+v2+v3)*0.25
				if (centre>0.0)==(v0>0.0):
					segments.append([crossings[0],crossings[3]]); segments.append([crossings[1],crossings[2]])
				else:
					segments.append([crossings[0],crossings[1]]); segments.append([crossings[2],crossings[3]])
	# Chain.
	var by_key:={}
	for index in segments.size():
		for end in 2:
			var key:int=segments[index][end][0]
			if not by_key.has(key): by_key[key]=[]
			by_key[key].append(index)
	var used:={}
	var lines:Array=[]
	for start in segments.size():
		if used.has(start): continue
		used[start]=true
		var line:Array=[segments[start][0],segments[start][1]]
		for direction in 2:
			while true:
				var tip:Array=line[-1] if direction==0 else line[0]
				var next_index:=-1
				for candidate in by_key.get(tip[0],[]):
					if not used.has(candidate): next_index=candidate; break
				if next_index<0: break
				used[next_index]=true
				var seg:Array=segments[next_index]
				var other:Array=seg[1] if int(seg[0][0])==int(tip[0]) else seg[0]
				if direction==0: line.append(other)
				else: line.push_front(other)
		var points:=PackedVector2Array()
		for entry in line: points.append(entry[1])
		lines.append(points)
	return lines


static func _length(points:PackedVector2Array)->float:
	var total:=0.0
	for i in range(1,points.size()): total+=points[i-1].distance_to(points[i])
	return total


static func _chaikin(points:PackedVector2Array)->PackedVector2Array:
	if points.size()<3: return points
	var out:=PackedVector2Array([points[0]])
	for i in points.size()-1:
		out.append(points[i].lerp(points[i+1],0.25)); out.append(points[i].lerp(points[i+1],0.75))
	out.append(points[-1])
	return out


## Evenly spaced resample (bounded point count, stable morphing).
static func resample(points:PackedVector2Array,count:int)->PackedVector2Array:
	if points.size()<2 or count<2: return points
	var total:=_length(points)
	var out:=PackedVector2Array()
	if total<=0.0:
		for i in count: out.append(points[0])
		return out
	var target:=0.0; var walked:=0.0; var index:=1
	for k in count:
		target=total*float(k)/float(count-1)
		while index<points.size()-1 and walked+points[index-1].distance_to(points[index])<target:
			walked+=points[index-1].distance_to(points[index]); index+=1
		var seg:=points[index-1].distance_to(points[index])
		out.append(points[index-1].lerp(points[index],clampf((target-walked)/maxf(seg,0.000001),0.0,1.0)))
	return out


## Split a contour where either side is absent (a gap in the line).
static func _contact_runs(points:PackedVector2Array,f:Dictionary)->Array:
	var runs:Array=[]
	var current:=PackedVector2Array()
	# Contact: on the balance line both sides' influence is equal; it counts
	# where that influence is a fair share of the weaker side's own peak.
	var floor_value:=CONTACT*minf(float(f.max_ours),float(f.max_theirs))
	for p in points:
		if minf(_sample(f.ours,f,p),_sample(f.theirs,f,p))>=floor_value: current.append(p)
		elif current.size()>=2: runs.append(current); current=PackedVector2Array()
		else: current=PackedVector2Array()
	if current.size()>=2: runs.append(current)
	return runs


## friendly/enemy: [{id, pos:Vector2, strength, age_days (enemy)}].
## Returns {fronts:[{points, width[], age[], stale, pressure[]}], sigma, broken}.
static func derive(friendly:Array,enemy:Array)->Dictionary:
	var ours:=friendly.slice(0,MAX_FRIENDLY)
	var theirs:=enemy.slice(0,MAX_ENEMY)
	if ours.is_empty() or theirs.is_empty(): return {"fronts":[],"sigma":0.0,"broken":false}
	var f:=field(ours,theirs)
	var runs:Array=[]
	for line in _contour(f):
		for run in _contact_runs(line,f): runs.append(run)
	runs.sort_custom(func(a:PackedVector2Array,b:PackedVector2Array)->bool: return _length(a)>_length(b))
	var minimum:=float(f.sigma)*0.4
	var fronts:Array=[]
	for run in runs:
		if fronts.size()>=MAX_FRONTS: break
		if _length(run)<minimum: continue
		var smooth:=_chaikin(_chaikin(run))
		var count:=clampi(int(_length(smooth)/(float(f.sigma)*0.08))+2,8,MAX_POINTS)
		var points:=resample(smooth,count)
		var width:=PackedFloat32Array(); var ages:=PackedFloat32Array(); var pressure:=PackedFloat32Array()
		var toward:=PackedVector2Array()
		var oldest:=0.0
		for index in points.size():
			var p:=points[index]
			# Which side of the line is theirs: step across it both ways.
			var along:=(points[mini(points.size()-1,index+1)]-points[maxi(0,index-1)]).normalized()
			var normal:=along.orthogonal()
			var probe:=float(f.sigma)*0.15
			var plus:=_sample(f.ours,f,p+normal*probe)-_sample(f.theirs,f,p+normal*probe)
			var minus:=_sample(f.ours,f,p-normal*probe)-_sample(f.theirs,f,p-normal*probe)
			toward.append(normal if plus<minus else -normal)
			var here:=presence(f,p)
			# Thick where both sides are massed; thin where the line is stretched.
			width.append(clampf(sqrt(here.x*here.y)*1.6,0.25,1.0))
			var age:=_sample(f.age,f,p)
			ages.append(age); oldest=maxf(oldest,age)
			# Which way the local push leans (+ ours, - theirs), from the balance
			# a short step to either side of the line.
			pressure.append(clampf(here.x-here.y,-1.0,1.0))
		fronts.append({"points":points,"width":width,"age":ages,"stale":oldest>=float(STALE_DAYS),"pressure":pressure,"toward":toward})
	return {"fronts":fronts,"sigma":float(f.sigma),"broken":fronts.size()>1}


## FRONTS FROM BORDERS: at war with a people whose land meets ours, the
## front is the line where the two lands meet (nation_borders.gd publishes
## it from the same partition the map washes). It is a front of ground, as
## HOI4's is: it moves when a town changes hands, because the town's claim
## moves with its holder. The forces near it work it: where one side is
## locally stronger the line bends into the weaker side's ground (bounded:
## a share of the theatre's scale), it thickens where both sides are massed,
## and battles on it heat it (battle_marks heat, in the overlay).
## points: the published meeting line; ours_at / theirs_at: our towns' and
## their known towns' places (which side of the line is whose); friendly /
## enemy: the forces (substantial ones), as derive() takes them.
## Returns a front as derive() makes them, with "border": true, "civ" and
## "quiet" (no force of either side near it).
const BORDER_BEND:=0.3
const BORDER_POINTS:=64
static func border_front(points:PackedVector2Array,ours_at:Array,theirs_at:Array,friendly:Array,enemy:Array,civ:String,sigma_hint:=0.0)->Dictionary:
	if points.size()<2: return {}
	var length:=_length(points)
	var line:=resample(points,BORDER_POINTS)
	var sigma:=sigma_hint if sigma_hint>0.0 else length*0.12
	var f:={}
	if not friendly.is_empty() and not enemy.is_empty():
		f=field(friendly.slice(0,MAX_FRIENDLY),enemy.slice(0,MAX_ENEMY))
		sigma=float(f.sigma)
	var width:=PackedFloat32Array(); var ages:=PackedFloat32Array(); var pressure:=PackedFloat32Array()
	var toward:=PackedVector2Array(); var bent:=PackedVector2Array()
	var quiet:=true
	for index in line.size():
		var p:=line[index]
		var along:=(line[mini(line.size()-1,index+1)]-line[maxi(0,index-1)]).normalized()
		var normal:=along.orthogonal()
		# Their side: toward their nearest town and away from ours.
		var side:=_nearest(theirs_at,p)-_nearest(ours_at,p)
		if side.is_finite() and side.length_squared()>0.0 and normal.dot(side)<0.0: normal=-normal
		toward.append(normal)
		var push:=0.0
		var thick:=0.3
		if not f.is_empty():
			var here:=presence(f,p)
			if maxf(here.x,here.y)>=CONTACT: quiet=false
			# Only where a side is actually present does it bend the line.
			push=clampf(here.x-here.y,-1.0,1.0)*clampf(maxf(here.x,here.y)*1.5,0.0,1.0)
			thick=clampf(sqrt(here.x*here.y)*1.6,0.3,1.0)
		pressure.append(push)
		width.append(thick)
		ages.append(0.0)
		bent.append(p+normal*push*sigma*BORDER_BEND)
	# Ends stay on the border: the bend fades in over the first and last few points.
	var n:=bent.size()
	for i in n:
		var edge:=minf(float(i),float(n-1-i))/maxf(1.0,float(n)*0.12)
		bent[i]=line[i].lerp(bent[i],clampf(edge,0.0,1.0))
	return {"points":bent,"width":width,"age":ages,"stale":false,"pressure":pressure,"toward":toward,"border":true,"civ":civ,"quiet":quiet,"border_points":line,"sigma":sigma}


static func _nearest(places:Array,p:Vector2)->Vector2:
	var best:=Vector2.INF
	for at in places:
		if at is Vector2 and (at as Vector2).is_finite() and (not best.is_finite() or (at as Vector2).distance_squared_to(p)<best.distance_squared_to(p)): best=at
	return best


## Whether a derived front runs along a border front (most of its points
## within reach of the border's line): the border front stands for it.
static func along_border(front:Dictionary,border:Dictionary,reach:float)->bool:
	var line:PackedVector2Array=border.get("border_points",border.get("points",PackedVector2Array()))
	var points:PackedVector2Array=front.get("points",PackedVector2Array())
	if line.size()<2 or points.is_empty(): return false
	var near:=0
	for p in points:
		var best:=INF
		for i in range(1,line.size()): best=minf(best,p.distance_to(Geometry2D.get_closest_point_to_segment(p,line[i-1],line[i])))
		if best<=reach: near+=1
	return float(near)>=float(points.size())*0.5


## A face-off line for hosts in the field: only where two hosts are within
## reach of each other; a short arc across the line between them.
static func face_offs(friendly:Array,enemy:Array,reach:float)->Array:
	var out:Array=[]
	for f in friendly.slice(0,MAX_FRIENDLY):
		for e in enemy.slice(0,MAX_ENEMY):
			var a:Vector2=f.pos; var b:Vector2=e.pos
			var d:=a.distance_to(b)
			if d>reach or d<=0.0: continue
			var fs:=sqrt(maxf(1.0,float(f.get("strength",1.0)))); var es:=sqrt(maxf(1.0,float(e.get("strength",1.0))))
			# The meeting point sits nearer the weaker host: the stronger pushes.
			var centre:=a.lerp(b,fs/(fs+es))
			var across:=(b-a).normalized().orthogonal()
			var half:=clampf(d*0.45,0.05,reach*0.4)
			var bow:=(b-a).normalized()*d*0.12*((fs-es)/(fs+es))
			var points:=PackedVector2Array()
			for k in 9:
				var t:=float(k)/8.0*2.0-1.0
				points.append(centre+across*half*t+bow*(1.0-t*t))
			out.append({"points":points,"age":float(e.get("age_days",0.0)),"stale":float(e.get("age_days",0.0))>=float(STALE_DAYS),"friendly":String(f.get("id","")),"enemy":String(e.get("id",""))})
			if out.size()>=MAX_FRONTS: return out
	return out


## Pockets: a front that nearly closes on itself round an enemy they have
## seen, with none of ours inside, is a pocket. closure is how much of the
## ring is closed (1 = cut off); the gap is the distance still open.
static func pockets(fronts:Array,friendly:Array,enemy:Array)->Array:
	var out:Array=[]
	for index in fronts.size():
		var points:PackedVector2Array=fronts[index].points
		if points.size()<6: continue
		var length:=_length(points)
		var gap:=points[0].distance_to(points[-1])
		if length<=0.0 or gap>length*0.6: continue
		var inside:Array=[]
		for e in enemy:
			if Geometry2D.is_point_in_polygon(e.pos,points): inside.append(e)
		if inside.is_empty(): continue
		var ours_inside:=false
		for f in friendly:
			if Geometry2D.is_point_in_polygon(f.pos,points): ours_inside=true; break
		if ours_inside: continue
		var strength:=0.0
		var centre:=Vector2.ZERO
		for e in inside: strength+=float(e.get("strength",0.0)); centre+=e.pos
		centre/=float(inside.size())
		out.append({"front":index,"closure":clampf(length/(length+gap*3.0),0.0,1.0) if gap>0.0 else 1.0,"gap":gap,"centre":centre,"strength":strength,
			"gap_at":points[0].lerp(points[-1],0.5)})
	return out


## Where an army's general would fall back to, from his actual withdrawal
## intent: a point one day's march along the route he would take (his
## commanded route home, the campaign board's road home, or straight home).
static func withdrawal_point(from:Vector2,route:PackedVector2Array,depth:float)->Vector2:
	var walked:=0.0
	var at:=from
	for next in route:
		var step:=at.distance_to(next)
		if walked+step>=depth and step>0.0: return at.lerp(next,(depth-walked)/step)
		walked+=step; at=next
	return at


## The fallback line behind a front, through the fallback points of the
## armies holding it, in order along the front and smoothed. One army gives a
## short line across its road back.
static func fallback_from_intent(front:Dictionary,holders:Array)->PackedVector2Array:
	var points:PackedVector2Array=front.points
	if points.size()<2 or holders.is_empty(): return PackedVector2Array()
	var along:=(points[-1]-points[0]).normalized()
	if holders.size()==1:
		var h:Dictionary=holders[0]
		var back:Vector2=h.fallback
		var road:=(back-(h.pos as Vector2)).normalized()
		var across:=road.orthogonal() if road!=Vector2.ZERO else along
		var half:=maxf(0.05,float(h.get("frontage",0.5)))
		return PackedVector2Array([back-across*half,back,back+across*half])
	var ordered:=holders.duplicate()
	ordered.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return (a.fallback as Vector2).dot(along)<(b.fallback as Vector2).dot(along))
	var line:=PackedVector2Array()
	for h in ordered: line.append(h.fallback)
	return _chaikin(_chaikin(line))


## Evenly subdivide a polyline so it drapes over the ground when projected
## (no segment longer than `step` world units; bounded to `limit` points).
static func densify(points:PackedVector2Array,step:float,limit:int=64)->PackedVector2Array:
	if points.size()<2 or step<=0.0: return points
	var count:=clampi(int(ceilf(_length(points)/step))+1,points.size(),limit)
	return resample(points,count) if count>points.size() else points


## The line the general would fall back to: the front offset toward our side.
static func fallback_line(front:Dictionary,home:Vector2,depth:float)->PackedVector2Array:
	var points:PackedVector2Array=front.points
	var out:=PackedVector2Array()
	if points.size()<2: return out
	var mid:=points[points.size()/2]
	for i in points.size():
		var a:=points[maxi(0,i-1)]; var b:=points[mini(points.size()-1,i+1)]
		var normal:=(b-a).normalized().orthogonal()
		if normal.dot(home-mid)<0.0: normal=-normal
		out.append(points[i]+normal*depth)
	return out


## An offensive arrow from where the army stands (or the nearest point of
## the front) toward its general's objective, bowed a little so parallel
## arrows read apart. Returns [tail, control, head] in world units.
static func arrow(from:Vector2,objective:Vector2,fronts:Array,bias:float=0.0)->PackedVector2Array:
	var start:=from
	var best:=INF
	for front in fronts:
		for p in (front.points as PackedVector2Array):
			var d:=p.distance_squared_to(from)
			if d<best and p.distance_to(objective)<from.distance_to(objective): best=d; start=p
	if best<INF and start.distance_to(from)>from.distance_to(objective)*0.5: start=from
	var delta:=objective-start
	var control:=start+delta*0.5+delta.orthogonal()*(0.12+bias)
	return PackedVector2Array([start,control,objective-delta.normalized()*minf(delta.length()*0.08,delta.length())])


## Quadratic bezier samples of an arrow (bounded).
static func arrow_points(arrow_spec:PackedVector2Array,samples:int=16)->PackedVector2Array:
	var out:=PackedVector2Array()
	if arrow_spec.size()<3: return out
	for k in samples+1:
		var t:=float(k)/float(samples)
		out.append(arrow_spec[0].lerp(arrow_spec[1],t).lerp(arrow_spec[1].lerp(arrow_spec[2],t),t))
	return out


# --- The front giving way -------------------------------------------------------------

## When a battle is won or lost, or a town changes hands, the front surges
## where it happened and settles where control now lies. A bulge: {pos, dir
## (unit, world), amp and radius (world), t, dur (seconds)}.

## How far into its surge a bulge is (0 at the start and the end, 1 at the
## height of it): a smooth swell and settle.
static func envelope(u:float)->float:
	if u<=0.0 or u>=1.0: return 0.0
	var s:=sin(PI*u)
	return s*s


## The displacement of a point of the front by the bulges now running.
static func bulge_offset(p:Vector2,bulges:Array)->Vector2:
	var out:=Vector2.ZERO
	for bulge in bulges:
		var radius:=maxf(0.000001,float(bulge.radius))
		var d:=p.distance_to(bulge.pos)/radius
		if d>3.0: continue
		var k:=envelope(float(bulge.t)/maxf(0.001,float(bulge.dur)))
		if k<=0.0: continue
		out+=(bulge.dir as Vector2)*float(bulge.amp)*k*exp(-d*d)
	return out


## Where on the fronts an event at `at` falls, and which way is forward
## (toward the enemy) there: {front, index, point, toward} or {} when no
## front runs within `reach`.
static func front_at(fronts:Array,at:Vector2,reach:float)->Dictionary:
	var best:={}
	var best_d:=reach
	for f in fronts.size():
		var points:PackedVector2Array=(fronts[f] as Dictionary).get("points",PackedVector2Array())
		var toward:PackedVector2Array=(fronts[f] as Dictionary).get("toward",PackedVector2Array())
		for i in points.size():
			var d:=points[i].distance_to(at)
			if d<best_d:
				best_d=d
				best={"front":f,"index":i,"point":points[i],"toward":toward[i] if i<toward.size() else Vector2.ZERO}
	return best

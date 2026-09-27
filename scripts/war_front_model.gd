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

## Hard bounds: population changes numbers on a front, never node counts.
const GRID:=32
const MAX_FRIENDLY:=12
const MAX_ENEMY:=24
const MAX_FRONTS:=6
const MAX_POINTS:=96
const MAX_ARROWS:=12
const MAX_CLASHES:=8
## Report age (days) at which an enemy observation has lost most weight.
const AGE_HALF_LIFE:=45.0
## Age beyond which the drawn line is shown as stale.
const STALE_DAYS:=20
## A vertex needs both sides' normalised influence above this to be a front.
const CONTACT:=0.12


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


## The influence field on a GRID x GRID lattice over the theatre.
static func field(friendly:Array,enemy:Array)->Dictionary:
	var sigma:=_sigma(friendly,enemy)
	var box:=Rect2((friendly[0].pos as Vector2),Vector2.ZERO)
	for s in friendly+enemy: box=box.expand(s.pos)
	box=box.grow(sigma*2.2)
	var step:=Vector2(box.size.x/float(GRID-1),box.size.y/float(GRID-1))
	var ours:=PackedFloat32Array(); ours.resize(GRID*GRID)
	var theirs:=PackedFloat32Array(); theirs.resize(GRID*GRID)
	var age:=PackedFloat32Array(); age.resize(GRID*GRID)
	var sources:=[]
	for s in friendly: sources.append([s,false,_weight(s,false),_reach(s,sigma)])
	for s in enemy: sources.append([s,true,_weight(s,true),_reach(s,sigma)])
	var max_ours:=0.0
	var max_theirs:=0.0
	for j in GRID:
		for i in GRID:
			var p:=box.position+Vector2(float(i)*step.x,float(j)*step.y)
			var f:=0.0; var e:=0.0; var aged:=0.0
			for entry in sources:
				var reach:float=entry[3]
				var d2:=p.distance_squared_to((entry[0] as Dictionary).pos)
				if d2>reach*reach*9.0: continue
				var v:=float(entry[2])*exp(-d2/(2.0*reach*reach))
				if entry[1]:
					e+=v; aged+=v*float((entry[0] as Dictionary).get("age_days",0.0))
				else: f+=v
			var k:=j*GRID+i
			ours[k]=f; theirs[k]=e; age[k]=aged/e if e>0.0 else 0.0
			max_ours=maxf(max_ours,f); max_theirs=maxf(max_theirs,e)
	return {"box":box,"step":step,"sigma":sigma,"ours":ours,"theirs":theirs,"age":age,"max_ours":maxf(max_ours,0.0001),"max_theirs":maxf(max_theirs,0.0001)}


static func _sample(values:PackedFloat32Array,f:Dictionary,p:Vector2)->float:
	var box:Rect2=f.box
	var step:Vector2=f.step
	var gx:=clampf((p.x-box.position.x)/step.x,0.0,float(GRID-1)-0.001)
	var gy:=clampf((p.y-box.position.y)/step.y,0.0,float(GRID-1)-0.001)
	var i:=int(gx); var j:=int(gy); var tx:=gx-float(i); var ty:=gy-float(j)
	var a:=values[j*GRID+i]; var b:=values[j*GRID+i+1]; var c:=values[(j+1)*GRID+i]; var d:=values[(j+1)*GRID+i+1]
	return lerpf(lerpf(a,b,tx),lerpf(c,d,tx),ty)


## Normalised presence of both sides at p (0..1 each).
static func presence(f:Dictionary,p:Vector2)->Vector2:
	return Vector2(_sample(f.ours,f,p)/float(f.max_ours),_sample(f.theirs,f,p)/float(f.max_theirs))


## Marching squares on (ours - theirs) = 0, chained into polylines.
static func _contour(f:Dictionary)->Array:
	var box:Rect2=f.box
	var step:Vector2=f.step
	var ours:PackedFloat32Array=f.ours
	var theirs:PackedFloat32Array=f.theirs
	var value:=func(i:int,j:int)->float:
		# Raw strengths: the stronger side pushes the line toward the weaker.
		return ours[j*GRID+i]-theirs[j*GRID+i]
	var point:=func(i:int,j:int)->Vector2:
		return box.position+Vector2(float(i)*step.x,float(j)*step.y)
	# Edge keys identify shared crossings so segments chain exactly.
	var segments:Array=[]
	for j in GRID-1:
		for i in GRID-1:
			var corners:=[[i,j],[i+1,j],[i+1,j+1],[i,j+1]]
			var values:=[]
			for c in corners: values.append(value.call(c[0],c[1]))
			var crossings:=[]
			for e in 4:
				var a:float=values[e]; var b:float=values[(e+1)%4]
				if (a>0.0)==(b>0.0): continue
				var ca:Array=corners[e]; var cb:Array=corners[(e+1)%4]
				var t:=a/(a-b)
				var pa:Vector2=point.call(ca[0],ca[1]); var pb:Vector2=point.call(cb[0],cb[1])
				var key:="%d,%d-%d,%d" % ([ca[0],ca[1],cb[0],cb[1]] if (ca[1]*GRID+ca[0])<(cb[1]*GRID+cb[0]) else [cb[0],cb[1],ca[0],ca[1]])
				crossings.append([key,pa.lerp(pb,t)])
			if crossings.size()==2: segments.append([crossings[0],crossings[1]])
			elif crossings.size()==4:
				# Saddle: pair by the cell centre's sign.
				var centre:=(float(values[0])+float(values[1])+float(values[2])+float(values[3]))*0.25
				if (centre>0.0)==(float(values[0])>0.0):
					segments.append([crossings[0],crossings[3]]); segments.append([crossings[1],crossings[2]])
				else:
					segments.append([crossings[0],crossings[1]]); segments.append([crossings[2],crossings[3]])
	# Chain.
	var by_key:={}
	for index in segments.size():
		for end in 2:
			var key:String=segments[index][end][0]
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
				var other:Array=seg[1] if String(seg[0][0])==String(tip[0]) else seg[0]
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
	for p in points:
		var here:=presence(f,p)
		if minf(here.x,here.y)>=CONTACT: current.append(p)
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

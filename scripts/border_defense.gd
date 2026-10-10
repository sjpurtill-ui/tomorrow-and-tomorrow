extends RefCounted
## Real army deployment and swept contact geometry. No people, combat results,
## ownership or clocks live here: a sector is an objective on an existing army.
const Lines:=preload("res://scripts/army_lines.gd")
const MAX_SECTORS:=8
const MAX_POINTS:=96
const ARRIVAL_KM:=0.5
const STARVING_BELOW:=0.45

static func point(value:Variant)->Vector2:
	if value is Vector2:return value
	if value is Dictionary:return Vector2(float(value.get("x",INF)),float(value.get("z",INF)))
	return Vector2.INF

static func points(value:Variant)->PackedVector2Array:
	var out:=PackedVector2Array()
	if value is Array or value is PackedVector2Array:
		for item in value:
			var p:=point(item)
			if p.is_finite():out.append(p)
			if out.size()>=MAX_POINTS:break
	return out

static func packed(line:PackedVector2Array)->Array:
	var out:=[]
	for p:Vector2 in line:out.append({"x":p.x,"z":p.y})
	return out

static func fit(force:Dictionary,today:int=-1)->bool:
	if not bool(force.get("can_defend",true)):return false
	if today>=0 and int(force.get("command_recover_until",0))>today:return false
	if int(force.get("troops",force.get("actual_troops",0)))<=0:return false
	if bool(force.get("resting",false)) or bool(force.get("embarked",false)):return false
	if String(force.get("status","")) in ["retreating","withdrawing","destroyed","captured","surrendered"]:return false
	return not Lines.unfit(force) and float(force.get("provision_ratio",force.get("supply_level",1.0)))>=STARVING_BELOW

static func organization(known:Array)->float:
	if "radio_telegraphy" in known:return 8.0
	if "military_staffs" in known:return 4.0
	if "formation_drill" in known:return 2.0
	return 1.0

static func frontage(force:Dictionary,organization_value:float=1.0)->float:
	var fed:=clampf(float(force.get("provision_ratio",force.get("supply_level",1.0))),0.0,1.0)
	var ready:=clampf(float(force.get("readiness",0.5)),0.0,1.0)
	return maxf(0.0,float(force.get("troops",force.get("actual_troops",0))))*0.003*clampf(organization_value,1.0,8.0)*(0.4+0.6*ready)*(0.4+0.6*fed)

static func length(line:PackedVector2Array)->float:
	var total:=0.0
	for i in range(1,line.size()):total+=line[i-1].distance_to(line[i])
	return total

static func at(line:PackedVector2Array,distance:float)->Vector2:
	if line.is_empty():return Vector2.INF
	var left:=maxf(0.0,distance)
	for i in range(1,line.size()):
		var span:=line[i-1].distance_to(line[i])
		if left<=span:return line[i-1].lerp(line[i],left/maxf(0.000001,span))
		left-=span
	return line[-1]

static func slice(line:PackedVector2Array,start:float,end:float)->PackedVector2Array:
	var out:=PackedVector2Array()
	if line.size()<2 or end<=start:return out
	var total:=length(line);start=clampf(start,0,total);end=clampf(end,start,total)
	out.append(at(line,start))
	var walked:=0.0
	for i in range(1,line.size()):
		walked+=line[i-1].distance_to(line[i])
		if walked>start and walked<end:out.append(line[i])
	out.append(at(line,end))
	return out

## The full assigned sector remains on the army; only the part its current
## people can hold is published. Marching or broken armies leave real gaps.
static func coverage(force:Dictionary,today:int=-1)->PackedVector2Array:
	if not fit(force,today) or String(force.get("status","stationed"))=="moving":return PackedVector2Array()
	var sector:Dictionary=force.get("border_sector",{})
	if sector.is_empty():return PackedVector2Array()
	if String((force.get("council",{}) as Dictionary).get("phase",""))=="home":return PackedVector2Array()
	var anchor:=point(sector.get("anchor"));var here:=point(force.get("position"))
	if not anchor.is_finite() or not here.is_finite() or here.distance_to(anchor)>ARRIVAL_KM:return PackedVector2Array()
	var line:=points(sector.get("points",[]));var total:=length(line)
	var held:=minf(total,frontage(force,float(sector.get("organization",1.0))))
	return slice(line,(total-held)*0.5,(total+held)*0.5)

## Assigned sectors partition the actual closed border. Each army marches
## to its sector's midpoint, never straight to a visual offset or a rival.
static func sector(outline:PackedVector2Array,index:int,count:int,toward:Vector2)->PackedVector2Array:
	if outline.size()<3:return PackedVector2Array()
	var loop:=outline.duplicate()
	if loop[0]!=loop[-1]:loop.append(loop[0])
	var perimeter:=length(loop)
	if perimeter<=0:return PackedVector2Array()
	var nearest:=INF;var focus:=0.0;var walked:=0.0
	for i in range(1,loop.size()):
		var p:=Geometry2D.get_closest_point_to_segment(toward,loop[i-1],loop[i])
		if p.distance_squared_to(toward)<nearest:nearest=p.distance_squared_to(toward);focus=walked+loop[i-1].distance_to(p)
		walked+=loop[i-1].distance_to(loop[i])
	var span:=perimeter/float(maxi(1,count))
	var start:=fposmod(focus+float(index)*span-span*0.5,perimeter)
	var out:=slice(loop,start,minf(perimeter,start+span))
	if start+span>perimeter:
		var rest:=slice(loop,0,start+span-perimeter)
		for i in range(1,rest.size()):out.append(rest[i])
	return out

## Small physical depth, independent of an army's frontage along the border.
static func radius(force:Dictionary)->float:
	return clampf(sqrt(maxf(0,float(force.get("troops",force.get("actual_troops",0)))))*0.012,0.04,0.6)

static func _disk(from:Vector2,delta:Vector2,center:Vector2,r:float)->float:
	var offset:=from-center;var a:=delta.length_squared()
	if offset.length_squared()<=r*r+0.00001:return 0.0
	if a<=0.00000001:return INF
	var b:=2.0*offset.dot(delta);var c:=offset.length_squared()-r*r
	var discriminant:=b*b-4.0*a*c
	if discriminant<0.0:return INF
	var t:=(-b-sqrt(discriminant))/(2.0*a)
	return clampf(t,0,1) if t>=-0.00001 and t<=1.00001 else INF

static func _capsule(from:Vector2,to:Vector2,a:Vector2,b:Vector2,r:float)->float:
	var nearest:=Geometry2D.get_closest_point_to_segment(from,a,b)
	var delta:=to-from
	if from.distance_to(nearest)<=r+0.0001:
		# A force may withdraw away from contact; it cannot step through it.
		if delta.length_squared()>0.000001 and (from-nearest).dot(delta)>0.000001:return INF
		return 0.0
	var best:=minf(_disk(from,delta,a,r),_disk(from,delta,b,r))
	var span:=a.distance_to(b)
	if span<=0.00001:return best
	var axis:=(b-a)/span;var normal:=axis.orthogonal()
	var across:=delta.dot(normal)
	if absf(across)>0.0000001:
		for edge in [-r,r]:
			var t:=(float(edge)-(from-a).dot(normal))/across
			var along:=(from+delta*t-a).dot(axis)
			if t>=0.0 and t<=1.0 and along>=0.0 and along<=span:best=minf(best,t)
	return best

## Caller supplies current hostile forces, including unobserved ones. This
## query discovers only actual contact, never reports remote enemy positions.
static func first_contact(from:Vector2,to:Vector2,enemies:Array,own_force:Dictionary={})->Dictionary:
	var best:={};var first:=INF
	for raw in enemies:
		if not raw is Dictionary:continue
		var enemy:Dictionary=raw
		var force:Dictionary=(enemy.get("record",{}) as Dictionary).duplicate()
		force.merge(enemy,true)
		force["troops"]=int(force.get("troops",force.get("actual_troops",0)))
		if not fit(force):continue
		var line:=points(force.get("defense_points",[])) if force.has("defense_points") else coverage(force)
		if line.is_empty():
			var where:=point(force.get("position",force.get("command_position",force.get("point_a"))))
			if not where.is_finite():continue
			line=PackedVector2Array([where,where])
		elif line.size()==1:line.append(line[0])
		var r:=radius(force)+radius(own_force)
		for i in range(1,line.size()):
			var t:=_capsule(from,to,line[i-1],line[i],r)
			if t>=first:continue
			first=t
			var hit:=from.lerp(to,t)
			best={"t":t,"point":hit,"defended_point":Geometry2D.get_closest_point_to_segment(hit,line[i-1],line[i]),"enemy":enemy,"formation_id":String(enemy.get("id",""))}
	return best

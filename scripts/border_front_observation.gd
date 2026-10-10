extends RefCounted
## Clip a held line to ground actually within lookouts' sight. Disconnected
## glimpses never get joined across unseen ground into an invented front.
static func seen(points:Array,viewers:Array)->Array:
	var runs:Array=[];var current:Array=[]
	for index in range(1,points.size()):
		var a:=_point(points[index-1]);var b:=_point(points[index]);var delta:=b-a
		var intervals:Array=[]
		if delta.length_squared()<0.000001:continue
		for viewer:Dictionary in viewers:
			var offset:=a-Vector2(viewer.point);var radius:=float(viewer.radius)
			var bb:=2.0*offset.dot(delta);var aa:=delta.length_squared()
			var discriminant:=bb*bb-4.0*aa*(offset.length_squared()-radius*radius)
			if discriminant<0.0:continue
			var low:=maxf(0.0,(-bb-sqrt(discriminant))/(2.0*aa))
			var high:=minf(1.0,(-bb+sqrt(discriminant))/(2.0*aa))
			if high>low:intervals.append(Vector2(low,high))
		intervals.sort_custom(func(p:Vector2,q:Vector2)->bool:return p.x<q.x)
		var merged:Array[Vector2]=[]
		for interval:Vector2 in intervals:
			if not merged.is_empty() and interval.x<=merged[-1].y+0.00001:merged[-1].y=maxf(merged[-1].y,interval.y)
			else:merged.append(interval)
		for interval:Vector2 in merged:
			var first:=a.lerp(b,interval.x);var last:=a.lerp(b,interval.y)
			if not current.is_empty() and _point(current[-1]).distance_to(first)>0.001:
				runs.append(current);current=[]
			if current.is_empty():current.append({"x":first.x,"z":first.y})
			current.append({"x":last.x,"z":last.y})
		if merged.is_empty() and not current.is_empty():runs.append(current);current=[]
	if not current.is_empty():runs.append(current)
	var best:Array=[];var longest:=0.0
	for run:Array in runs:
		var length:=0.0
		for index in range(1,run.size()):length+=_point(run[index-1]).distance_to(_point(run[index]))
		if length>longest:longest=length;best=run
	return best

static func _point(value:Variant)->Vector2:
	if value is Vector2:return value
	return Vector2(float(value.get("x",0.0)),float(value.get("z",0.0)))

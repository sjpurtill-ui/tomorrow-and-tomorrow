extends RefCounted
## HOI4's base rule: each capacity slot loses 5% per cumulative missing
## resource unit; the worst resource wins, capped at 100%. No state is owned here.
const PENALTY := 0.05

## `available` is a priority ledger in resource-capacity units. Negative values
## carry unmet demand into the next line. Evaluate arithmetic intervals rather
## than iterating over the population, so millions of makers remain bounded.
static func evaluate(requirements:Dictionary, slots:int, available:Dictionary)->Dictionary:
	if slots<=0:return {"factor":0.0,"missing":{},"stopped":0}
	var cuts:Array[int]=[1,slots+1]
	var curves:Array=[]
	var missing:Dictionary={}
	for resource:String in requirements:
		var cost:=maxf(0.0,float(requirements[resource]))
		if cost<=0:continue
		var supply:=float(available.get(resource,0.0))
		curves.append(Vector2(cost,supply))
		for crossing:float in [supply/cost,(supply+20.0)/cost]:
			var cut:=clampi(floori(crossing)+1,1,slots+1)
			if cut not in cuts:cuts.append(cut)
			var boundary:=clampi(ceili(crossing),1,slots+1)
			if boundary not in cuts:cuts.append(boundary)
		missing[resource]=maxf(0.0,cost*slots-maxf(0.0,supply))
		available[resource]=supply-cost*slots
	for a:Vector2 in curves:
		for b:Vector2 in curves:
			if is_equal_approx(a.x,b.x):continue
			var cut:=clampi(floori((a.y-b.y)/(a.x-b.x))+1,1,slots+1)
			if cut not in cuts:cuts.append(cut)
	cuts.sort()
	var output:=0.0
	var stopped:=0
	for index in cuts.size()-1:
		var first:=cuts[index];var last:=cuts[index+1]-1
		if last<first:continue
		var middle:=(float(first)+last)*.5
		var worst:=Vector2.ZERO
		for curve:Vector2 in curves:
			if curve.x*middle-curve.y>worst.x*middle-worst.y:worst=curve
		var deficit:=maxf(0.0,worst.x*middle-worst.y)
		var count:=last-first+1
		if deficit>=20.0-0.000001:stopped+=count
		output+=count*(0.0 if deficit>=20.0-0.000001 else clampf(1.0-PENALTY*deficit,0.0,1.0))
	return {"factor":output/slots,"missing":missing,"stopped":stopped}

extends RefCounted
## Selected compact-tension trial in normalized units; no certified K_IC claim.
const N=preload("res://scripts/metallurgy_thermal_cycle.gd")
static func shape(alpha:float)->float:
	return (2+alpha)/pow(1-alpha,1.5)*(.886+4.64*alpha-13.32*alpha*alpha+14.72*pow(alpha,3)-5.6*pow(alpha,4))
static func geometry()->Dictionary:
	return {"width":1.0,"thickness":.5,"notch":.45,"orientation":"L-T","yield_strength":20.0,"modulus":1000.0}
static func precrack(cycles:int)->Dictionary:
	# Selected stable fatigue response under a fixed low-load cycling range.
	var length:=.45+float(cycles)*.00005
	return {"cycles":cycles,"minimum_force":.005,"maximum_force":.03,
		"front":[length-.001,length,length+.001],"method":"fatigue_precrack"}
static func sample(index:int,initial:float,g:Dictionary,resistance:float=2.0)->Dictionary:
	# A selected crack resistance sets the specimen response, not the observer.
	var critical:=resistance*float(g.thickness)*sqrt(float(g.width))/shape(initial/float(g.width))
	var imposed:=float(index+1)*.01
	var force:=imposed if imposed<=critical else maxf(.01,critical-(imposed-critical)*.6)
	var extension:=maxf(0,imposed-critical)*2.0
	var compliance:=.5/(float(g.modulus)*float(g.thickness)*pow(1-initial/float(g.width),2))
	var opening:=imposed*compliance*(1.0+extension*10.0)
	return {"force":snappedf(force,.00001),"opening":snappedf(opening,.0000001),"crack_extension":extension}
static func measure(record:Dictionary)->Dictionary:
	var reasons:Array=[]
	var result:={"qualified":false,"classification":"comparison_only","reasons":reasons}
	if not record.has_all(["geometry","precrack","initial_front","final_front","trace"]):reasons.append("Missing specimen evidence.");return result
	var g:Variant=record.geometry;var pre:Variant=record.precrack
	if not g is Dictionary or not pre is Dictionary:return result
	for field:String in ["width","thickness","notch","yield_strength","modulus"]:
		if not N.number(g.get(field)) or float(g[field])<=0:return result
	if g.get("orientation") not in ["L-T","T-L","S-L"]:reasons.append("Unrecorded orientation.")
	if pre.get("method")!="fatigue_precrack" or not pre.get("cycles") is int or int(pre.cycles)<1000:reasons.append("Insufficient fatigue precrack.")
	var initial:Variant=record.initial_front;var final_front:Variant=record.final_front
	if not initial is Array or not final_front is Array or initial.size()!=3 or final_front.size()!=3:return result
	var a:=0.0;var final_a:=0.0
	for index:int in range(3):
		if not N.number(initial[index]) or not N.number(final_front[index]):return result
		a+=float(initial[index])/3.0;final_a+=float(final_front[index])/3.0
		if float(final_front[index])<float(initial[index]) or float(final_front[index])>=float(g.width):reasons.append("Invalid final crack front.")
	if a<=0 or a>=float(g.width):return result
	var ratio:=a/float(g.width)
	if ratio<.45 or ratio>.55 or a-float(g.notch)<.025:reasons.append("Crack geometry outside selected bounds.")
	if float(initial.max())-float(initial.min())>.02*float(g.width):reasons.append("Uneven initial crack front.")
	var trace:Variant=record.trace
	if not trace is Array or trace.size()<8 or trace.size()>32:return result
	var peak:=0.0;var previous_opening:=-1.0;var slope:=0.0;var pq:=0.0
	for index:int in range(trace.size()):
		var point:Variant=trace[index]
		if not point is Dictionary or not N.number(point.get("force")) or not N.number(point.get("opening")) or float(point.force)<0 or float(point.opening)<=previous_opening:return result
		previous_opening=float(point.opening)
		if index==2:
			if float(point.opening)<=0:return result
			slope=float(point.force)/float(point.opening)
		if index>2 and pq==0 and float(point.force)<.95*slope*float(point.opening):pq=peak
		peak=maxf(peak,float(point.force))
	if pq<=0:reasons.append("No resolved departure from elastic loading.");return result
	var kq:=pq/(float(g.thickness)*sqrt(float(g.width)))*shape(ratio)
	var minimum_size:=2.5*pow(kq/float(g.yield_strength),2)
	if minf(float(g.thickness),minf(a,float(g.width)-a))<minimum_size:reasons.append("Insufficient thickness or ligament.")
	if peak/pq>1.1:reasons.append("Excessive nonlinear loading.")
	if final_a<=a:reasons.append("No measured crack extension.")
	result.provisional_k=kq;result.minimum_size=minimum_size;result.orientation=g.get("orientation","")
	result.qualified=reasons.is_empty()
	result.classification="selected_specimen_provisional" if result.qualified else "comparison_only"
	return result

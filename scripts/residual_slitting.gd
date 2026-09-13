extends RefCounted
## Selected five-layer strip: elastic/plastic bending, unload, then incremental cuts.
## Normalized units; not an engineering residual-stress qualification.
const Y=[-2.0,-1.0,0.0,1.0,2.0]
const E:=1000.0
const RESOLUTION:=.00001
static func prepared(curvature:float)->Dictionary:
	var stress:Array=[];var force:=0.0;var moment:=0.0
	for y:float in Y:
		var value:=clampf(E*curvature*y,-1,1)
		stress.append(value);force+=value;moment+=value*y
	for index:int in range(5):stress[index]=float(stress[index])-force/5.0-moment*float(Y[index])/10.0
	return {"curvature":curvature,"unloaded":true,"applied_force":0.0,"applied_moment":0.0,"residual":stress}
static func compliance(cut:int,removed:int)->float:
	var count:=5-cut;var mean:=0.0;var inertia:=0.0
	for index:int in range(count):mean+=float(Y[index])/float(count)
	for index:int in range(count):inertia+=pow(float(Y[index])-mean,2)
	return (1.0/float(count)+(float(Y[0])-mean)*(float(Y[4-removed])-mean)/inertia)/E
static func reading(piece:Dictionary,cut:int,resolution:float=RESOLUTION)->Dictionary:
	var strain:=0.0
	for index:int in range(cut):strain+=compliance(cut,index)*float(piece.residual[4-index])
	return {"depth":cut,"strain":snappedf(strain,resolution),"uncertainty":resolution/2.0,"applied_force":0.0,"applied_moment":0.0}
static func measure(readings:Array)->Dictionary:
	var bad:={"qualified":false,"reason":"Need three unloaded incremental cuts of the calibrated strip."}
	if readings.size()!=3:return bad
	var removed:Array=[];var errors:Array=[]
	for index:int in range(3):
		var r:Variant=readings[index]
		if not r is Dictionary or r.get("depth")!=index+1 or r.get("applied_force")!=0.0 or r.get("applied_moment")!=0.0:return bad
		if not preload("res://scripts/metallurgy_thermal_cycle.gd").number(r.get("strain")) or r.get("uncertainty") not in [RESOLUTION/2.0,0.000001/2.0]:return bad
		var measured_strain:=float(r.strain);var uncertainty:=float(r.uncertainty)
		for previous:int in range(index):
			var coefficient:=compliance(index+1,previous)
			measured_strain-=coefficient*float(removed[previous]);uncertainty+=absf(coefficient)*float(errors[previous])
		var diagonal:=compliance(index+1,index)
		removed.append(measured_strain/diagonal);errors.append(uncertainty/absf(diagonal))
	# Infer the two uncut layers from zero resultant force and moment.
	var sum:=float(removed[0])+float(removed[1])+float(removed[2])
	var moment:=2.0*float(removed[0])+float(removed[1])
	var bottom:=moment+sum;var next:=-sum-bottom
	var bounds:=float(errors[0])*4.0+float(errors[1])*3.0+float(errors[2])*2.0
	var profile:Array=[bottom,next,removed[2],removed[1],removed[0]]
	var qualified:=true
	for value:float in profile:
		if absf(value)+bounds>.8:qualified=false
	return {"qualified":qualified,"profile":profile,"uncertainty":bounds,"method":"unloaded_incremental_slit_compliance","scope":"selected five-layer strip only"}

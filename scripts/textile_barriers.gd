extends RefCounted
## Selected coated shells; ratios below are a declared game wet-flex protocol,
## not laboratory ratings, breathable membranes or chemical protective apparel.
const CREATE:="textile_waterproofing"
const SEAL:="garment_seam_sealing"
const WET_INPUTS:={"Freshwater":.2,"Polyethylene-Coated Textile":.01}
const SEAM_INPUTS:={"Freshwater":.2,"Polyethylene Seam Tape":.002}
const PATCH_INPUTS:={"Polyethylene-Coated Textile":.12,"Spun Yarn":.02}
static func fresh(day:int=-1)->Dictionary:
	return {"surface_loss":[],"seam_loss":[],"sealed":false,"bond":0.0,"last_day":day}
static func surface_ready(lot:Dictionary)->bool:
	var m:Dictionary=lot.get("barrier",fresh())
	if float(lot.condition)<.6 or m.surface_loss.size()!=3:return false
	for loss:float in m.surface_loss:
		if loss>.12:return false
	return true
static func needs_patch(lot:Dictionary)->bool:
	var condition:=float(lot.condition)
	var m:Dictionary=lot.get("barrier",fresh())
	return condition>=.15 and (condition<.6 or (condition<.85 and m.surface_loss.size()==3 and not surface_ready(lot)))
static func seam_ready(lot:Dictionary)->bool:
	var m:Dictionary=lot.get("barrier",fresh())
	if not surface_ready(lot) or not m.sealed or m.seam_loss.size()!=3:return false
	for loss:float in m.seam_loss:
		if loss>.08:return false
	return true
static func storm_factor(lot:Dictionary)->float:
	return .5 if seam_ready(lot) else .35 if surface_ready(lot) else .1
static func demand(C:Script,id:String,population:float,day:int)->Dictionary:
	var needed:Dictionary={}
	if id==CREATE:
		var shells:=minf(10,maxf(0,population*1.1-C.count()))
		if shells>0:needed["Stitched Rain-Shell Panels"]=shells
	for lot:Dictionary in C.data().lots:
		if lot.kind!="rain_shell" or int(lot.ready)>day:continue
		var m:Dictionary=lot.get("barrier",fresh())
		var inputs:Dictionary={}
		if id==CREATE:
			if needs_patch(lot):inputs=PATCH_INPUTS
			elif m.surface_loss.size()<3:inputs=WET_INPUTS
		elif id==SEAL and surface_ready(lot):
			if not m.sealed or (m.seam_loss.size()==3 and not seam_ready(lot)):
				if float(lot.condition)>=.7:inputs={"Polyethylene Seam Tape":.06}
			elif m.seam_loss.size()<3:inputs=SEAM_INPUTS
		for item:String in inputs:needed[item]=float(needed.get(item,0))+minf(10,float(lot.amount))*float(inputs[item])
	return needed
static func power_demand(C:Script)->float:
	var state=WorldSimulation.state
	if not state.resource_settlement_id.is_empty() or state.convoy_traveling or not state.settlement_site_committed or SEAL not in state.known_discoveries:return 0.0
	var rate:=clampf(WorldSimulation.discovery.adoption(SEAL),0,1)
	var capacity:=minf(float(C.data().tools.get(SEAL,0)),maxf(0,state.effective_workers("Logistics"))*.2)*rate
	var needed:=demand(C,SEAL,WorldSimulation.settlements.primary_population_exact(),int(state.elapsed_days))
	if needed.is_empty():return 0.0
	var eligible:=0.0
	for lot:Dictionary in C.data().lots:
		if lot.kind=="rain_shell" and int(lot.ready)<=int(state.elapsed_days) and surface_ready(lot) and not seam_ready(lot):eligible+=float(lot.amount)
	# The paid sealing/checking service uses the same finite local supply.
	for item:String in needed:
		capacity=minf(capacity,eligible*minf(1,C.available(item)/maxf(.000001,float(needed[item]))))
	return minf(capacity,eligible)*.2
static func transfer(C:Script,lot:Dictionary,amount:float,condition:float,m:Dictionary)->bool:
	if not C.add("rain_shell",amount,condition,float(lot.soil),false,false,0,String(lot.get("fabric","plain")),m):return false
	lot.amount-=amount
	return true
static func operate(C:Script,id:String,workers:float,population:float,day:int,report:Dictionary)->void:
	var initial:=float(report.workers)
	for lot:Dictionary in C.data().lots.duplicate():
		if lot.kind!="rain_shell" or int(lot.ready)>day:continue
		var m:Dictionary=lot.get("barrier",fresh()).duplicate(true)
		if int(m.last_day)>=day:continue
		var remaining:=maxf(0,workers-(float(report.workers)-initial))
		if id==CREATE:
			if needs_patch(lot):
				var patches:=minf(float(lot.amount),C.quota(id,remaining,report,PATCH_INPUTS))
				if patches>0:
					lot.condition+=minf(.3,.85-float(lot.condition))*patches/float(lot.amount)
					lot.barrier=fresh(day);C.charge(id,patches,report,PATCH_INPUTS)
				continue
			if m.surface_loss.size()>=3:continue
			var amount:=minf(float(lot.amount),C.quota(id,remaining,report,WET_INPUTS))
			if amount<=.000001:continue
			# Observe surface entry after a paid wet/flex cycle; damaged shells
			# can fail. Every retained result belongs to these actual garments.
			m.surface_loss.append(.04+(1.0-float(lot.condition))*.25)
			m.last_day=day
			if transfer(C,lot,amount,maxf(0,float(lot.condition)-.005),m):C.charge(id,amount,report,WET_INPUTS)
		elif id==SEAL and surface_ready(lot):
			if not m.sealed or (m.seam_loss.size()==3 and not seam_ready(lot)):
				if float(lot.condition)<.7:continue
				var amount:=minf(float(lot.amount),C.quota(id,remaining,report))
				if amount<=.000001:continue
				var profile:Dictionary=C.data().get("sealing_profile",{"heat":1.0,"pressure":1.0})
				var heat:=float(profile.heat);var pressure:=float(profile.pressure)
				m.sealed=true;m.seam_loss=[];m.last_day=day
				m.bond=1.0 if heat>=.85 and heat<=1.15 and pressure>=.85 and pressure<=1.15 else 0.0
				var condition:=maxf(0,float(lot.condition)-(.2 if heat>1.3 else 0.0))
				if transfer(C,lot,amount,condition,m):C.charge(id,amount,report)
			elif m.seam_loss.size()<3:
				var amount:=minf(float(lot.amount),C.quota(id,remaining,report,SEAM_INPUTS))
				if amount<=.000001:continue
				m.seam_loss.append(.015+(1.0-float(lot.condition))*.12+(1.0-float(m.bond))*.2)
				m.last_day=day
				if transfer(C,lot,amount,maxf(0,float(lot.condition)-.005),m):C.charge(id,amount,report,SEAM_INPUTS)
	for index:int in range(C.data().lots.size()-1,-1,-1):
		if float(C.data().lots[index].amount)<.000001:C.data().lots.remove_at(index)
	if id==CREATE:
		var amount:=minf(C.quota(id,maxf(0,workers-(float(report.workers)-initial)),report),maxf(0,population*1.1-C.count()))
		if amount>0 and C.add("rain_shell",amount,1,0,false,false,0,"plain",fresh(day)):C.charge(id,amount,report)
static func number(value:Variant)->bool:
	return (value is int or value is float) and is_finite(float(value))
static func valid(meta:Variant)->bool:
	if not meta is Dictionary or meta.size()!=5 or not meta.has_all(["surface_loss","seam_loss","sealed","bond","last_day"]):return false
	if not meta.sealed is bool or not number(meta.bond) or meta.bond<0 or meta.bond>1:return false
	if not meta.last_day is int or meta.last_day< -1 or meta.last_day>1000000000:return false
	for key:String in ["surface_loss","seam_loss"]:
		if not meta[key] is Array or meta[key].size()>3:return false
		for value:Variant in meta[key]:
			if not number(value) or value<0 or value>1:return false
	if not meta.sealed and (not meta.seam_loss.is_empty() or meta.bond!=0):return false
	if meta.sealed and meta.surface_loss.size()!=3:return false
	return true
static func valid_profile(profile:Variant)->bool:
	if not profile is Dictionary or profile.size()!=2 or not profile.has_all(["heat","pressure"]):return false
	for value:Variant in profile.values():
		if not number(value) or value<0 or value>2:return false
	return true

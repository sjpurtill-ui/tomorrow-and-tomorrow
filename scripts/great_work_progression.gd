extends RefCounted
## A commission freezes the society's capacity; growth never makes its bill move.
## Each ambition commits a percentage of construction output for several years.
const YEARS:={"modest":2.0,"grand":6.0,"audacious":12.0}
const CREW_SHARE:=0.20
static func budget(base:Dictionary,population:float,builders:float,productivity:float)->Dictionary:
	var ambition:=String(base.get("ambition","grand"))
	var tier:=clampi(int(base.get("tier",0)),0,5)
	var years:=float(YEARS.get(ambition,6.0))*(1.0+float(tier)*0.20)
	# Even a society neglecting construction faces a national commitment.
	var capacity:=maxf(maxf(1.0,population)*0.025,builders)*maxf(0.1,productivity)
	var work:=maxf(float(base.work),capacity*CREW_SHARE*365.0*years)
	var ratio:=work/maxf(1.0,float(base.work))
	var costs:Dictionary={}
	for key:String in base.cost:costs[key]=ceilf(float(base.cost[key])*ratio)
	if tier>=4:costs["Civilian Goods"]=ceilf(work*0.02) # Precision fittings and glazed finishes.
	return {"version":1,"work":work,"cost":costs,"population":maxf(1.0,population),"capacity":capacity,"crew_share":CREW_SHARE,"years":years,"tier":tier}
static func quote(base:Dictionary,state:Node)->Dictionary:
	var efficiency:=clampf(float(state.simulation_metrics.get("labor_efficiency",0.72)),0.1,1.0)
	var raw:=maxf(1.0,float(state.population_allocations.get("Construction",0)))
	var effective:=maxf(0.0,float(state.effective_workers("Construction")))
	return budget(base,float(state.population_exact),raw,effective/raw*efficiency)
static func apply(base:Dictionary,quote:Dictionary)->Dictionary:
	var result:=base.duplicate(true)
	if quote.is_empty():return result
	result.work=float(quote.work);result.cost=(quote.cost as Dictionary).duplicate()
	return result
static func reward_scale(tier:int)->float:return 1.0+clampi(tier,0,5)*0.20
static func rewards(base:Dictionary,budget_data:Dictionary)->Dictionary:
	var result:=base.duplicate()
	if budget_data.is_empty():return result
	var scale:=reward_scale(int(budget_data.tier))
	for key:String in result:
		if key in ["food_capacity","water_capacity"]:
			# Infrastructure serving a share of the people, not a village's fixed bins.
			result[key]=minf(180000.0,maxf(float(result[key]),float(budget_data.population)*float(result[key])/1000.0)*scale)
		else:result[key]=float(result[key])*scale
	return result

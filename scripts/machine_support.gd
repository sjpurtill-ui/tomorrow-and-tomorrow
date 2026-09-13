extends RefCounted
## Paid per-line apparatus and observations; no independent labor or save owner.
static func spend(job:Dictionary,stocks:Dictionary,cost:Dictionary)->bool:
	for resource:String in cost:
		if float(stocks.get(resource,0))<float(cost[resource]):return false
	for resource:String in cost:
		stocks[resource]-=float(cost[resource])
		job.last_consumed[resource]=float(job.last_consumed.get(resource,0))+float(cost[resource])
	return true
static func prepare(job:Dictionary,spec:Dictionary,work:float)->float:
	var state=WorldSimulation.state
	var known:Array=state.known_discoveries
	var stocks:Dictionary=state.resource_stockpiles
	if not job.has("machine_support"):job.machine_support={"installed":{},"observations":[],"blocked":"","repair_work":0.0}
	var support:Dictionary=job.machine_support
	work+=float(support.get("measurement_credit",0));support.measurement_credit=0.0
	support.blocked=""
	var apparatus:={"fluid_film_bearings":"Water-Film Bearing Sets","cutting_fluid_management":"Machining Water Filter Sets","machine_tool_stiffness_assessment":"Machine Load Test Sets","machine_condition_monitoring":"Machine Vibration Test Sets"}
	for technology:String in apparatus:
		if technology not in known or support.installed.has(technology):continue
		if work>=.25 and spend(job,stocks,{apparatus[technology]:1.0}):
			support.installed[technology]=int(state.elapsed_days)
			work-=.25;job.last_work+=.25
	# Repeat paid measurements only for a new completed-part count or after repair.
	var due:bool=int(support.get("measured_at_part",-1))!=int(job.completed)
	var measured_failure:=false
	if due:
		for method:String in ["machine_tool_stiffness_assessment","machine_condition_monitoring"]:
			if not support.installed.has(method):continue
			var already:=false
			for prior:Dictionary in support.observations:
				if prior.method==method and int(prior.part)==int(job.completed) and int(prior.get("revision",0))==int(support.get("repairs",0)):already=true;measured_failure=measured_failure or bool(prior.failed)
			if already:continue
			if work<.25:
				support.measurement_credit=work;support.blocked="Accumulating machine measurement work";return 0.0
			if not spend(job,stocks,{"Paper":.01,"Refined Copper":.005}):support.blocked="Waiting for machine measurement supplies";return 0.0
			work-=.25;job.last_work+=.25
			var wear:=float(job.get("machine_wear",0))
			var row:={"day":int(state.elapsed_days),"part":int(job.completed),"method":method,"work":.25,"uncertainty":.025,"revision":int(support.get("repairs",0))}
			if method=="machine_tool_stiffness_assessment":
				row.load=1.0;row.unloaded=0.0;row.loaded=.05+.3*wear;row.limit=.3
				row.failed=float(row.loaded)-float(row.unloaded)+float(row.uncertainty)>float(row.limit)
			else:
				row.vibration=.1+.4*wear
				row.baseline=float(support.get("vibration_baseline",row.vibration))
				support.vibration_baseline=row.baseline
				row.limit=.4;row.failed=float(row.vibration)+float(row.uncertainty)>.4 or float(row.vibration)-float(row.baseline)>.2
			measured_failure=measured_failure or bool(row.failed)
			support.observations.append(row)
			while support.observations.size()>8:support.observations.pop_front()
		support.measured_at_part=int(job.completed)
		if measured_failure:support.repair_needed=true
	if bool(support.get("repair_needed",false)):
		if not bool(support.get("repair_paid",false)):
			if not spend(job,stocks,{"Steel":.2,"Graphite":.02}):support.blocked="Repair material missing after measured machine deterioration";return 0.0
			support.repair_paid=true
		var used:=minf(work,.5-float(support.repair_work))
		support.repair_work+=used;job.last_work+=used;work-=used
		if float(support.repair_work)<.5:support.blocked="Repairing measured machine deterioration";return 0.0
		job.machine_wear=.05
		support.repair_needed=false;support.repair_paid=false;support.repair_work=0.0
		support.measured_at_part=-1
		support.repairs=int(support.get("repairs",0))+1
		# Re-measure the repaired apparatus on the next call before cutting.
		support.blocked="Recheck repaired machine";return 0.0
	return work
static func limit_work(job:Dictionary,work:float)->float:
	var support:Dictionary=job.get("machine_support",{})
	var installed:Dictionary=support.get("installed",{})
	var stocks:Dictionary=WorldSimulation.state.resource_stockpiles
	var water:=0.0
	if installed.has("fluid_film_bearings"):water+=.05
	if installed.has("cutting_fluid_management"):water+=.1
	if water>0:work=minf(work,float(stocks.get("Freshwater",0))/water)
	if installed.has("cutting_fluid_management"):work=minf(work,float(stocks.get("Woven Cloth",0))/.001)
	if work<=0 and water>0:support.blocked="Restore bearing water or filtered cutting-water supplies"
	return maxf(0,work)
static func consume(job:Dictionary,work:float)->void:
	var support:Dictionary=job.get("machine_support",{})
	var installed:Dictionary=support.get("installed",{})
	var stocks:Dictionary=WorldSimulation.state.resource_stockpiles
	var cost:={}
	if installed.has("fluid_film_bearings"):cost.Freshwater=.05*work
	if installed.has("cutting_fluid_management"):
		cost.Freshwater=float(cost.get("Freshwater",0))+.1*work;cost["Woven Cloth"]=.001*work
		stocks["Spent Machining Water"]=float(stocks.get("Spent Machining Water",0))+.1*work
	spend(job,stocks,cost)
	support.film_work=float(support.get("film_work",0))+(work if installed.has("fluid_film_bearings") else 0.0)
	support.filtered_work=float(support.get("filtered_work",0))+(work if installed.has("cutting_fluid_management") else 0.0)

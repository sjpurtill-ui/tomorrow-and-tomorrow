extends RefCounted
## Destructive sections remain attached to their original reserved workpiece.
const Grain=preload("res://scripts/metallurgy_grain_measurement.gd")
const Ops=preload("res://scripts/technology_operations.gd")
const COST={"Steel Tool Bits":.002,"Graded Alumina Abrasive":.01,"Steel Section Etchant":.005,"Woven Cloth":.002,"Freshwater":.05}
const AMOUNT:=.02
const WORK:=.5
static func advance(job:Dictionary,spec:Dictionary,work:float)->float:
	if work<=0 or not job.has("metallurgy_pending"):return 0.0
	var p:Dictionary=job.metallurgy_pending
	if p.phase!="inspection" or float(p.run.temperature)>150:return 0.0
	for apparatus:String in ["Metal Section Preparation Sets","Reflected-Light Metal Microscopes"]:
		if not bool(job.get("tooling_paid",false)) or float(job.get("tooling",{}).get(apparatus,0))<1:return 0.0
	var state=WorldSimulation.state
	if p.site!=state.resource_settlement_id:return 0.0
	if not p.has("section"):
		if float(p.reserved.get(spec.get("section_material",""),0))<=AMOUNT:return 0.0
		for resource:String in COST:
			if float(state.resource_stockpiles.get(resource,0))<float(COST[resource]):return 0.0
		if Ops.service("electricity")<=0:return 0.0
		for resource:String in COST:
			state.resource_stockpiles[resource]-=float(COST[resource])
			job.last_consumed[resource]=float(job.last_consumed.get(resource,0))+float(COST[resource])
		p.section={"source_job":p.source_job,"ordinal":p.ordinal,"site":p.site,
			"material":spec.section_material,"amount":AMOUNT,"supplies":COST.duplicate(true),
			"work":0.0,"energy":0.0,"disposition":"cut"}
	var section:Dictionary=p.section
	if section.disposition=="observed":return 0.0
	var used:=minf(work,minf(WORK-float(section.work),Ops.service("electricity")/.4))
	if used<=0:return 0.0
	Ops.consume_electricity(used*.4)
	section.work+=used;section.energy+=used*.4
	job.last_work=float(job.last_work)+used
	job.progress_days=float(p.run.work)+float(section.work)
	if float(section.work)+.000001>=WORK:
		section.disposition="observed"
		section.frame=frame(p)
		section.observation=Grain.measure(section.frame)
		state.resource_stockpiles["Spent Metallographic Sections"]=float(state.resource_stockpiles.get("Spent Metallographic Sections",0))+AMOUNT
	return used
static func frame(p:Dictionary)->Dictionary:
	# Selected bounded microstructure response, not a general steel phase solver.
	# The downstream observer receives only the resolved boundary image.
	var refinement:=minf(2,float(p.run.hot_work))*2.0
	var coarsening:=maxf(0,float(p.run.peak)-950.0)/80.0
	var spacing:=clampf(10.0-refinement+coarsening,4.0,15.0)
	var seeds:Array=[]
	var serial:=int(p.source_job)*17+int(p.ordinal)*31
	var n:=int(ceil(32.0/spacing))+1
	for y:int in range(n):
		for x:int in range(n):
			var phase:=(serial+x*13+y*7)%17
			seeds.append(Vector2((float(x)-.25)*spacing+float(phase%5)*.12*spacing,(float(y)-.25)*spacing+float(phase%3)*.18*spacing))
	var labels:Array=[]
	for y:int in range(32):
		var row:Array=[]
		for x:int in range(32):
			var nearest:=0;var distance:=INF
			for index:int in range(seeds.size()):
				var d:=Vector2(x,y).distance_squared_to(seeds[index])
				if d<distance:distance=d;nearest=index
			row.append(nearest)
		labels.append(row)
	var pixels:Array=[]
	for y:int in range(32):
		var row:Array=[]
		for x:int in range(32):
			var boundary:bool=(x>0 and labels[y][x]!=labels[y][x-1]) or (y>0 and labels[y][x]!=labels[y-1][x])
			row.append(.1 if boundary else .9)
		pixels.append(row)
	return {"source_id":"%s:%d:%d"%[p.site,p.source_job,p.ordinal],"section_id":1,
		"illumination":"reflected","preparation":"polished_etched",
		"micrometres_per_pixel":1.0,"calibration_uncertainty":.05,"pixels":pixels}
static func valid(p:Dictionary,spec:Dictionary)->bool:
	if not p.has("section"):return true
	var s:Variant=p.section
	if not s is Dictionary or not s.has_all(["source_job","ordinal","site","material","amount","supplies","work","energy","disposition"]):return false
	if s.source_job!=p.source_job or s.ordinal!=p.ordinal or s.site!=p.site or s.material!=spec.get("section_material"):return false
	if s.amount!=AMOUNT or s.supplies!=COST or float(p.reserved.get(s.material,0))<=AMOUNT:return false
	if not Grain.finite(s.work,0,WORK) or not Grain.finite(s.energy,0,WORK*.4+.000001):return false
	if absf(float(s.energy)-float(s.work)*.4)>.000001:return false
	if s.disposition=="cut":return s.work<WORK and not s.has("frame") and not s.has("observation")
	if s.disposition!="observed" or absf(float(s.work)-WORK)>.000001:return false
	return s.get("frame")==frame(p) and s.get("observation")==Grain.measure(s.frame)

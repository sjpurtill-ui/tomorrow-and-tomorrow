extends RefCounted
## Paid finite column operation within the existing daily technology ledger.
const Model=preload("res://scripts/sec_elution_model.gd")
const Analysis=preload("res://scripts/sec_distribution_analysis.gd")
const PREPARATION="sec_traceable_peg_batch"
const CALIBRATION_WORK=6.0
const SAMPLE_WORK=4.0
const Bills=preload("res://scripts/goods_bills.gd")
## Column preparation as authored. The packing and narrow references inside the
## column and reference sets are imported; the rest is drawn as raw materials
## and Civilian Goods.
const COLUMN_SOURCE={"Packed Aqueous SEC Columns":1.0,"SEC PEG Reference Sets":1.0,"Freshwater":3.0,"Paper":.1}
static var COLUMN:=Bills.flatten(COLUMN_SOURCE)
## Per-run supplies; the retained batch itself was paid when it was prepared.
static var RUN:=Bills.flatten({"Freshwater":.5,"Paper":.05})
static func column()->Dictionary:return WorldSimulation.state.technology_operations.get("sec_column",{})
static func usable()->bool:
	var c:=column();var day:=floori(WorldSimulation.state.elapsed_days)
	return c.get("status")=="qualified" and day>=int(c.checked_day) and day-int(c.checked_day)<=30
## Pays `costs`, which are already raw materials and Civilian Goods.
static func pay(costs:Dictionary)->bool:
	var stocks:Dictionary=WorldSimulation.state.resource_stockpiles
	for item:String in costs:
		if float(stocks.get(item,0))<float(costs[item]):return false
	for item:String in costs:stocks[item]=float(stocks[item])-float(costs[item])
	return true
static func start_column()->bool:
	var ops=load("res://scripts/technology_operations.gd");var old:=column()
	if ops.service("sec_column_time")<=0 or old.get("status")=="conditioning" or (usable() and int(old.remaining_runs)>0):return false
	if not pay(COLUMN):return false
	var day:=floori(WorldSimulation.state.elapsed_days)
	WorldSimulation.state.technology_operations["sec_column"]={"epoch":int(old.get("epoch",0))+1,"status":"conditioning","work":0.0,"started_day":day,"last_day":day,"day_work":float(old.get("day_work",0)) if int(old.get("last_day",-1))==day else 0.0,"remaining_runs":8}
	return true
static func consume(amount:float)->float:
	var c:=column();var day:=floori(WorldSimulation.state.elapsed_days)
	if c.is_empty() or day<int(c.last_day):return 0.0
	if day>int(c.last_day):c.last_day=day;c.day_work=0.0
	var used:float=load("res://scripts/technology_operations.gd").consume_service("sec_column_time",minf(amount,1.0-float(c.day_work)))
	c.day_work=float(c.day_work)+used
	return used
static func advance_column()->void:
	var c:=column()
	if c.get("status")!="conditioning":return
	c.work=float(c.work)+consume(CALIBRATION_WORK-float(c.work))
	if float(c.work)<CALIBRATION_WORK:return
	var standards:Array=[]
	for dp:float in [10.0,40.0,160.0]:standards.append({"assigned_dp":dp,"response":Model.scan([{"dp":dp,"number_fraction":1.0}],Model.profile(),roundi(dp)+int(c.epoch),"sec-reference-"+str(dp),int(c.epoch))})
	c["standards"]=standards;c["calibration"]=Analysis.calibrate(standards)
	c.status="qualified" if c.calibration.accepted else "failed"
	c["checked_day"]=floori(WorldSimulation.state.elapsed_days)
static func start(sample:Dictionary)->bool:
	if sample.get("recipe")!=PREPARATION or sample.status!="unmeasured" or not usable() or int(column().remaining_runs)<=0:return false
	for active:Dictionary in WorldSimulation.state.technology_operations.get("polymer_samples",{}).get("records",{}).values():
		if active.get("recipe")==PREPARATION and active.status=="acquiring":return false
	if sample.source_store!=WorldSimulation.state.resource_settlement_id:return false
	if load("res://scripts/technology_operations.gd").service("sec_column_time")<=0:return false
	if not pay(RUN):return false
	sample.status="acquiring"
	sample["acquisition"]={"work":0.0,"started_day":floori(WorldSimulation.state.elapsed_days),"epoch":column().epoch,"specimens_reserved":1}
	column().remaining_runs=int(column().remaining_runs)-1
	return true
static func chains(sample:Dictionary)->Array:
	var rng:=RandomNumberGenerator.new();rng.seed=int(sample.response_model.seed)
	var mean:=rng.randf_range(31.0,39.0)
	if int(sample.response_model.seed)%2==1:return [{"dp":mean*.9,"number_fraction":.25},{"dp":mean,"number_fraction":.5},{"dp":mean*1.1,"number_fraction":.25}]
	return [{"dp":mean*.45,"number_fraction":.5},{"dp":mean*1.55,"number_fraction":.5}]
static func advance(sample:Dictionary)->void:
	if sample.get("recipe")!=PREPARATION or sample.status!="acquiring":return
	if sample.source_store!=WorldSimulation.state.resource_settlement_id:return
	if not usable() or sample.acquisition.epoch!=column().epoch:
		sample.status="measurement_failed";sample["observation"]={"error":"Column calibration expired during the run; prepare another retained batch."};return
	sample.acquisition.work=float(sample.acquisition.work)+consume(SAMPLE_WORK-float(sample.acquisition.work))
	if float(sample.acquisition.work)<SAMPLE_WORK:return
	sample["observation"]=Model.scan(chains(sample),Model.profile(),int(sample.response_model.seed),sample.sample_id,int(column().epoch))
	sample["sec_calibration"]=column().calibration.duplicate(true)
	var result:=Analysis.evaluate(sample.observation,sample.sec_calibration,sample.sample_id)
	sample.status="measured_unqualified" if result.accepted else "measurement_failed"
	if not result.accepted:sample.observation={"error":result.reason};return
	release(sample)
static func release(sample:Dictionary)->void:
	if sample.get("status")!="measured_unqualified":return
	var result:=Analysis.evaluate(sample.get("observation"),sample.get("sec_calibration"),String(sample.get("sample_id","")))
	if not result.get("accepted",false) or sample.get("specimen_released",false):return
	var output:="Distribution-Qualified PEG Batches" if result.narrow_binder_candidate else "Broad-Range Recovered PEG Batches"
	var stocks:Dictionary=WorldSimulation.state.resource_stockpiles
	stocks[output]=float(stocks.get(output,0))+1.0;sample["specimen_released"]=true
static func advance_pending()->void:
	if not WorldSimulation.state.resource_settlement_id.is_empty():return
	var records:Dictionary=WorldSimulation.state.technology_operations.get("polymer_samples",{}).get("records",{})
	var pending:=false;var acquiring:=false
	for sample:Dictionary in records.values():
		if sample.get("recipe")!=PREPARATION or sample.source_store!=WorldSimulation.state.resource_settlement_id:continue
		pending=pending or sample.status=="unmeasured";acquiring=acquiring or sample.status=="acquiring"
	# An operating bench prepares its own retained batch from raw materials and
	# goods; the former workshop preparation line no longer exists.
	if not pending and not acquiring and load("res://scripts/technology_operations.gd").service("sec_column_time")>0 and load("res://scripts/polymer_samples.gd").prepare(PREPARATION):
		pending=true
		records=WorldSimulation.state.technology_operations.polymer_samples.records
	if pending and not acquiring:start_column()
	advance_column()
	for sample:Dictionary in records.values():
		if sample.get("recipe")!=PREPARATION or sample.source_store!=WorldSimulation.state.resource_settlement_id:continue
		if sample.status=="unmeasured":start(sample)
		advance(sample)
static func report(sample:Dictionary)->Dictionary:
	if sample.status=="unmeasured":return {"status":"unmeasured","message":"Awaiting a prepared column, assigned references and operating bench time."}
	if sample.status=="acquiring":return {"status":"acquiring","message":"Size separation: %.1f / 4 paid instrument-time units."%float(sample.acquisition.work)}
	if sample.status=="measurement_failed":return {"status":"measurement_failed","message":sample.observation.error}
	var result:=Analysis.evaluate(sample.observation,sample.sec_calibration,sample.sample_id)
	return {"status":"resolved" if result.accepted else "measurement_failed","message":("Measured relative PEG distribution: %.1f%% conservative fraction in DP20–80; %s."%[100.0*float(result.window_20_80_fraction_lower),"selected binder route" if result.narrow_binder_candidate else "broad-range rework route"]) if result.accepted else result.reason,"interpretation":result}
static func valid_column(value:Variant)->bool:
	if not value is Dictionary or not value.has_all(["epoch","status","work","started_day","last_day","day_work","remaining_runs"]):return false
	for key:String in ["epoch","work","started_day","last_day","day_work","remaining_runs"]:
		if not Model.number(value[key]) or float(value[key])<0:return false
	for key:String in ["epoch","started_day","last_day","remaining_runs"]:
		if float(value[key])!=floorf(float(value[key])):return false
	if value.epoch<1 or value.remaining_runs>8 or value.work>CALIBRATION_WORK or value.day_work>1 or value.last_day<value.started_day or value.work>value.last_day-value.started_day+1:return false
	if value.status=="conditioning":return value.work<CALIBRATION_WORK and value.remaining_runs==8
	if value.status not in ["qualified","failed"] or value.work!=CALIBRATION_WORK or not Model.number(value.get("checked_day")) or value.checked_day<value.started_day or value.checked_day>value.last_day or value.checked_day!=floorf(float(value.checked_day)) or not value.get("standards") is Array or not value.get("calibration") is Dictionary:return false
	return Analysis.calibrate(value.standards)==value.calibration and bool(value.calibration.accepted)==(value.status=="qualified")
static func valid(sample:Dictionary)->bool:
	if sample.status=="unmeasured":return not sample.has("acquisition") and not sample.has("specimen_released")
	if sample.status not in ["acquiring","measurement_failed","measured_unqualified"] or not sample.get("acquisition") is Dictionary:return false
	var a:Dictionary=sample.acquisition
	for key:String in ["work","started_day","epoch","specimens_reserved"]:
		if not Model.number(a.get(key)):return false
	if a.work<0 or a.work>SAMPLE_WORK or a.started_day<sample.prepared_day or a.started_day!=floorf(float(a.started_day)) or a.epoch<1 or a.epoch!=floorf(float(a.epoch)) or a.specimens_reserved!=1:return false
	if sample.has("specimen_released") and (not sample.specimen_released is bool or sample.status!="measured_unqualified"):return false
	if sample.status=="acquiring":return a.work<SAMPLE_WORK and not sample.has("observation")
	if sample.status=="measurement_failed":return sample.get("observation") is Dictionary and sample.observation.get("error") is String
	if a.work!=SAMPLE_WORK or not sample.get("sec_calibration") is Dictionary or not sample.get("observation") is Dictionary:return false
	if sample.observation.get("epoch")!=a.epoch:return false
	return Analysis.evaluate(sample.observation,sample.sec_calibration,sample.sample_id).accepted

static func dependency_routes()->Dictionary:
	var result:Dictionary={}
	for output:String in ["Distribution-Qualified PEG Batches","Broad-Range Recovered PEG Batches"]:
		result["sec_analysis_"+output]={"gate":"size_exclusion_chromatography","requires":[],"output":output,"materials":Bills.flatten({"Sealed SEC PEG Batches":1.0,"Packed Aqueous SEC Columns":1.0,"SEC PEG Reference Sets":1.0,"Freshwater":3.5,"Paper":.15}).duplicate(),"tooling":{},"days":10.0,"power":0.0,"services":{"sec_column_time":10.0},"conditional":true}
	return result

static func report_text()->String:
	var c:=column();var lines:PackedStringArray=[]
	if c.get("status")=="conditioning":
		lines.append("Column preparation and reference checks: %.1f / 6 paid time units."%float(c.work))
	elif usable():
		lines.append("Calibrated column: %d runs remaining; calibration expires after day %d."%[int(c.remaining_runs),int(c.checked_day)+30])
	else:lines.append("No ready column. Prepare a packed aqueous column and assigned PEG reference solutions.")
	if c.get("status")!="conditioning" and (not usable() or int(c.get("remaining_runs",0))==0):
		var missing:PackedStringArray=[]
		for item:String in COLUMN:
			var required:=float(COLUMN[item])
			var shortage:=maxf(0,required-float(WorldSimulation.state.resource_stockpiles.get(item,0)))
			if shortage>0:missing.append("%.2f %s"%[shortage,item])
		if not missing.is_empty():lines.append("Missing for preparation: "+", ".join(missing)+".")
	var records:Dictionary=WorldSimulation.state.technology_operations.get("polymer_samples",{}).get("records",{})
	var ids:Array=[]
	for id:String in records:
		if records[id].get("recipe")==PREPARATION:ids.append(id)
	ids.sort_custom(func(a:String,b:String)->bool:return int(a)<int(b))
	if ids.is_empty():lines.append("The operating bench prepares a retained PEG batch from Civilian Goods and raw materials once ring-opening polymerization is adopted.")
	for index:int in range(maxi(0,ids.size()-6),ids.size()):
		var id:=String(ids[index]);var result:=report(records[id])
		lines.append("Sample "+id+": "+String(result.message))
		if result.status=="resolved":
			var fractions:Array=result.interpretation.observed_mass_fractions
			lines.append("Relative size bins 10–20 / 20–40 / 40–80 / 80–160: %.1f%% / %.1f%% / %.1f%% / %.1f%%."%[100*float(fractions[0]),100*float(fractions[1]),100*float(fractions[2]),100*float(fractions[3])])
	return "\n".join(lines)

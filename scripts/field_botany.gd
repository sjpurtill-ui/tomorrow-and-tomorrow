extends RefCounted
## Crop-specific evidence. Quantities are game units, never laboratory SI claims.
const MATURITY_DAYS:=90
const MAX_LINES:=8
const MAX_RECORDS:=16
const MAX_TRIALS:=2
const STAGES:=[15,45,90]

static func empty_state()->Dictionary:
	return {"last_day":-1,"next_id":1,"lines":[],"trials":[],"vouchers":[],"applications":[],"report":{},"balance":false,"reference_seed":0.0,"reference_site":"","reference_day":-1,"reference_line":{}}

static func number(value:Variant,maximum:float=1e9)->bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)>=0 and float(value)<=maximum

static func valid_line(line:Variant,next_id:int)->bool:
	if not line is Dictionary:return false
	for key:String in ["id","parent","generation","born_day"]:
		if not line.get(key) is int:return false
	return line.id>=1 and line.id<next_id and line.parent>=0 and line.parent<line.id and line.generation>=0 and line.generation<=1000000 and line.born_day>=0 and line.get("site") is String and number(line.get("seed")) and number(line.get("drought_tolerance"),1) and number(line.get("leaf_ratio"),1)

static func valid_stages(stages:Variant,start:int,end:int,age:int)->bool:
	if not stages is Array or stages.size()>3:return false
	var previous:=start
	for index:int in range(stages.size()):
		var stage:Variant=stages[index]
		if not stage is Dictionary or not stage.get("day") is int or not stage.get("age") is int:return false
		if stage.day<=previous or stage.day>end or stage.age!=STAGES[index] or stage.age>age or stage.day-start<stage.age:return false
		for key:String in ["control_size","exposed_size","reference_size"]:
			if not number(stage.get(key),MATURITY_DAYS):return false
		previous=stage.day
	return true

static func valid_voucher(v:Variant,next_id:int)->bool:
	if not v is Dictionary or not valid_line(v.get("line"),next_id) or not valid_line(v.get("reference"),next_id):return false
	for key:String in ["line_id","parent","generation","day","start_day"]:
		if not v.get(key) is int:return false
	if v.line_id<1 or v.line_id>=next_id or v.parent<0 or v.parent>=v.line_id or v.generation<0 or v.start_day<0 or v.day-v.start_day<MATURITY_DAYS:return false
	if not v.get("site") is String or not v.get("qualified") is bool or not number(v.get("response"),1) or not v.get("methods") is Dictionary:return false
	if not valid_stages(v.get("stages"),v.start_day,v.day,MATURITY_DAYS):return false
	for key:String in ["control_water","exposed_water","plant_loss","blank_loss","stress_days"]:
		if not number(v.get(key)):return false
	if v.methods.size()>8:return false
	for key:Variant in v.methods:
		if key not in ["habitat","anatomy","identity","development","heredity","transpiration","differential","resistance"]:return false
		if key in ["anatomy","development"]:
			if v.methods[key]!=v.stages:return false
		elif not v.methods[key] is Dictionary:return false
	var microscopy:Variant=v.get("microscopy",{})
	if not microscopy is Dictionary:return false
	if not microscopy.is_empty():
		for key:String in ["sample","cohort","source_day","day"]:
			if not microscopy.get(key) is int:return false
		if microscopy.sample<1 or microscopy.cohort!=v.line_id or microscopy.source_day!=v.start_day or microscopy.day>v.day or v.day-microscopy.day>7:return false
		if not number(microscopy.get("viable_fraction"),1) or not number(microscopy.get("tissue_order"),1):return false
		if microscopy.viable_fraction<.3 and v.qualified:return false
	if v.qualified:
		if v.methods.size()!=8 or v.stages.size()!=3 or v.generation<1 or v.stress_days<15:return false
		var h:Dictionary=v.methods.heredity
		if h.get("parent")!=v.parent or h.get("offspring")!=v.line_id or h.get("generation")!=v.generation:return false
		var t:Dictionary=v.methods.transpiration
		if t.get("plant_loss")!=v.plant_loss or t.get("blank_loss")!=v.blank_loss:return false
		if not number(t.get("net_loss")) or absf(float(t.net_loss)-(float(v.plant_loss)-float(v.blank_loss)))>.00001:return false
		if v.methods.identity.get("line_id")!=v.line_id or v.methods.habitat.get("site")!=v.site:return false
		if v.methods.identity.get("reference_id")!=v.reference.id or v.methods.identity.get("leaf_ratio")!=v.line.leaf_ratio:return false
		for stage:Dictionary in v.stages:
			if stage.get("leaf_ratio")!=v.line.leaf_ratio or stage.get("reference_leaf_ratio")!=v.reference.leaf_ratio:return false
		if v.methods.resistance.get("relative_gain")!=v.response:return false
	return true

static func valid(value:Variant)->bool:
	if not value is Dictionary:return false
	for key:String in ["last_day","next_id","reference_day"]:
		if not value.get(key) is int:return false
	if value.last_day < -1 or value.reference_day < -1 or value.next_id<1 or value.next_id>1000000000:return false
	if not number(value.get("reference_seed"),100) or not value.get("reference_site") is String:return false
	if not value.get("reference_line") is Dictionary:return false
	if not value.reference_line.is_empty() and not valid_line(value.reference_line,value.next_id):return false
	for key:String in ["lines","trials","vouchers","applications"]:
		if not value.get(key) is Array:return false
	if value.lines.size()>MAX_LINES or value.trials.size()>MAX_TRIALS or value.vouchers.size()>MAX_RECORDS or value.applications.size()>2:return false
	if not value.get("report") is Dictionary or not value.get("balance") is bool:return false
	var seen:Dictionary={}
	for line:Variant in value.lines:
		if not valid_line(line,value.next_id) or seen.has(line.id):return false
		seen[line.id]=true
	for trial:Variant in value.trials:
		if not trial is Dictionary or not valid_line(trial.get("line"),value.next_id) or not valid_line(trial.get("reference"),value.next_id):return false
		if not trial.get("start_day") is int or trial.start_day<0 or not trial.get("age") is int or trial.age<0 or trial.age>MATURITY_DAYS:return false
		if not trial.get("reference_source_day") is int or trial.reference_source_day<0 or trial.reference_source_day>trial.start_day:return false
		if trial.start_day<trial.line.born_day or not trial.get("site") is String or trial.site!=trial.line.site:return false
		if not valid_stages(trial.get("stages"),trial.start_day,value.last_day,trial.age):return false
		for key:String in ["control_growth","reference_growth","exposed_growth","control_water","exposed_water","blank_loss","plant_loss","stress_days","work","seed","reference_seed"]:
			if not number(trial.get(key)):return false
		if trial.age>maxi(0,value.last_day-trial.start_day) or trial.stress_days>trial.age:return false
	for voucher:Variant in value.vouchers:
		if not valid_voucher(voucher,value.next_id):return false
	for application:Variant in value.applications:
		if not application is Dictionary or not application.get("until") is int or not application.get("planted_day") is int or not application.get("site") is String:return false
		if application.planted_day<0 or application.until!=application.planted_day+MATURITY_DAYS:return false
		if not number(application.get("area"),.1) or not number(application.get("response"),1) or not number(application.get("seed"),.5):return false
		if not valid_line(application.get("line"),value.next_id) or not valid_voucher(application.get("evidence"),value.next_id):return false
		if not application.evidence.qualified or application.line.parent!=application.evidence.line_id or application.site!=application.evidence.site or application.site!=application.line.site:return false
		if application.response!=application.evidence.response or application.planted_day<application.evidence.day or application.planted_day-application.evidence.day>365:return false
		if absf(float(application.area)-float(application.seed)*.1)>.00001:return false
	return true

static func valid_settlements(records:Variant)->bool:
	if not records is Array:return false
	for record:Variant in records:
		if not record is Dictionary or not record.get("local_resources",{}) is Dictionary:return false
		if not valid(record.get("local_resources",{}).get("field_botany",empty_state())):return false
	return true

static func has_method_knowledge(known:Array,id:String)->bool:return id in known

## Retain seed from an actual current cultivated harvest. Caller removes the
## returned amount from that harvest before it becomes food; no imported grain identity.
static func retain_seed(ledger:Dictionary,harvest:float,site:String,day:int)->float:
	if harvest<=0 or ledger.next_id>=999999998:return 0.0
	var amount:=minf(2.0,harvest*.01)
	if amount<=0:return 0.0
	if not ledger.lines.is_empty():
		# Only the original local harvest population can be topped up; never
		# turn ordinary crop output into a bred descendant's seed.
		for line:Dictionary in ledger.lines:
			if line.site==site and int(line.generation)==0 and (float(line.seed)<.1 or float(ledger.reference_seed)<.1):
				line.seed+=amount*.5;ledger.reference_seed+=amount*.5
				ledger.reference_line.seed=ledger.reference_seed
				return amount
		return 0.0
	var variation:=float(absi(site.hash())%7)/6.0
	ledger.lines.append({"id":int(ledger.next_id),"parent":0,"generation":0,"seed":amount*.5,"site":site,"born_day":day,"drought_tolerance":.1+.3*variation,"leaf_ratio":.3+.3*variation})
	ledger.next_id+=1
	ledger.reference_line={"id":int(ledger.next_id),"parent":0,"generation":0,"seed":amount*.5,"site":site,"born_day":day,"drought_tolerance":.25,"leaf_ratio":.45}
	ledger.next_id+=1
	ledger.reference_seed=amount*.5;ledger.reference_site=site;ledger.reference_day=day
	return amount

## Starts one paired trial from a real lot. The caller pays water, recording
## material and work before invoking this transition.
static func sow_trial(ledger:Dictionary,line_index:int,site:String,day:int)->bool:
	if ledger.trials.size()>=MAX_TRIALS or line_index<0 or line_index>=ledger.lines.size():return false
	var line:Dictionary=ledger.lines[line_index]
	if line.site!=site or float(line.seed)<.1 or ledger.reference_site!=site or float(ledger.reference_seed)<.1:return false
	line.seed-=.1
	ledger.reference_seed-=.1
	ledger.reference_line.seed=ledger.reference_seed
	ledger.trials.append({"line":line.duplicate(true),"reference":ledger.reference_line.duplicate(true),"site":site,"start_day":day,"age":0,"stages":[],"control_growth":0.0,"reference_growth":0.0,"exposed_growth":0.0,"control_water":0.0,"exposed_water":0.0,"blank_loss":0.0,"plant_loss":0.0,"stress_days":0.0,"work":0.0,"seed":.1,"reference_seed":.1,"reference_source_day":int(ledger.reference_day)})
	return true

## Advance once on an observed day. Missing days are not synthesized.
## Water is split into a watered control, an ambient exposed plot and a blank
## vessel; drought is supplied by the existing settlement weather model.
static func observe(ledger:Dictionary,day:int,site:String,known:Array,water:float,work:float,drought:float)->Dictionary:
	var report:={"water":0.0,"work":0.0,"completed":0,"failed":0}
	if day<=int(ledger.last_day):return report
	ledger.last_day=day
	var survivors:Array=[]
	for trial:Dictionary in ledger.trials:
		if trial.site!=site:
			survivors.append(trial);continue
		if day<=int(trial.start_day):survivors.append(trial);continue
		if day-int(trial.start_day)>MATURITY_DAYS*2:
			report.failed+=1;continue
		if water-float(report.water)<.3 or work-float(report.work)<.1:
			survivors.append(trial);continue
		report.water+=.3;report.work+=.1
		trial.age+=1;trial.work+=.1
		var stress:=clampf(drought,0,1)
		var tolerance:=float(trial.line.drought_tolerance)
		trial.control_water+=.2;trial.exposed_water+=.1
		trial.control_growth+=1.0
		trial.reference_growth+=1.0-stress*(1.0-float(trial.reference.drought_tolerance))
		trial.exposed_growth+=1.0-stress*(1.0-tolerance)
		trial.blank_loss+=.02+.03*stress
		trial.plant_loss+=.02+.03*stress+.05*(1.0-stress*.5)
		if stress>=.25:trial.stress_days+=1
		if int(trial.age) in STAGES:
			trial.stages.append({"day":day,"age":int(trial.age),"control_size":float(trial.control_growth),"exposed_size":float(trial.exposed_growth),"reference_size":float(trial.reference_growth),"leaf_ratio":float(trial.line.leaf_ratio),"reference_leaf_ratio":float(trial.reference.leaf_ratio)})
		if int(trial.age)<MATURITY_DAYS:survivors.append(trial);continue
		_finish(ledger,trial,day,known)
		report.completed+=1
	ledger.trials=survivors
	ledger.report=report.duplicate(true)
	return report

static func matching_morphology(trial:Dictionary)->bool:
	if trial.line.site!=trial.site or trial.reference.site!=trial.site:return false
	if int(trial.line.born_day)>int(trial.start_day) or int(trial.reference.born_day)>int(trial.start_day):return false
	for stage:Dictionary in trial.stages:
		if stage.get("leaf_ratio")!=trial.line.leaf_ratio or stage.get("reference_leaf_ratio")!=trial.reference.leaf_ratio:return false
	return not trial.stages.is_empty()

static func _finish(ledger:Dictionary,trial:Dictionary,day:int,known:Array)->void:
	var methods:Dictionary={}
	if "habitat_observation_records" in known:methods.habitat={"site":String(trial.site),"start_day":int(trial.start_day),"end_day":day,"stress_days":float(trial.stress_days)}
	if "comparative_anatomy" in known:methods.anatomy=trial.stages.duplicate(true)
	if "biological_classification" in known and methods.has("habitat") and methods.has("anatomy") and matching_morphology(trial):methods.identity={"morphotype":"local crop leaf ratio %.3f" % float(trial.line.leaf_ratio),"line_id":int(trial.line.id),"reference_id":int(trial.reference.id),"leaf_ratio":float(trial.line.leaf_ratio),"reference_leaf_ratio":float(trial.reference.leaf_ratio)}
	if "developmental_stage_series" in known and methods.has("anatomy") and trial.stages.size()==3:methods.development=trial.stages.duplicate(true)
	if "heredity_experiments" in known and int(trial.line.generation)>0:
		for previous:Dictionary in ledger.vouchers:
			if int(previous.line_id)==int(trial.line.parent) and previous.site==trial.site and int(previous.day)<=int(trial.start_day):methods.heredity={"parent":int(trial.line.parent),"offspring":int(trial.line.id),"generation":int(trial.line.generation)}
	if "plant_transpiration_measurement" in known and bool(ledger.get("balance",false)):methods.transpiration={"plant_loss":float(trial.plant_loss),"blank_loss":float(trial.blank_loss),"net_loss":float(trial.plant_loss)-float(trial.blank_loss)}
	if "plant_pathology_diagnosis" in known and methods.has("identity") and float(trial.stress_days)>=15:methods.differential={"cause":"water limitation supported; pathogen cause untested","watered_growth":float(trial.control_growth),"ambient_growth":float(trial.exposed_growth)}
	var response:=clampf((float(trial.exposed_growth)-float(trial.reference_growth))/maxf(1,float(trial.control_growth)),0,1)
	if "plant_resistance_trait_trials" in known and methods.has("heredity") and methods.has("differential"):methods.resistance={"candidate_growth":float(trial.exposed_growth),"reference_growth":float(trial.reference_growth),"relative_gain":response}
	var microscopy:=preload("res://scripts/microscopy_lab.gd").field_evidence(int(trial.line.id),int(trial.start_day),day)
	var qualified:=methods.size()==8 and "biological_reference_collections" in known
	if not microscopy.is_empty() and float(microscopy.viable_fraction)<.3:qualified=false
	var voucher:={"line_id":int(trial.line.id),"reference":trial.reference.duplicate(true),"line":trial.line.duplicate(true),"start_day":int(trial.start_day),"day":day,"site":String(trial.site),"qualified":qualified,"response":response,"microscopy":microscopy.duplicate(true),"methods":methods,"stages":trial.stages.duplicate(true),"parent":int(trial.line.parent),"generation":int(trial.line.generation),"control_water":float(trial.control_water),"exposed_water":float(trial.exposed_water),"plant_loss":float(trial.plant_loss),"blank_loss":float(trial.blank_loss),"stress_days":float(trial.stress_days)}
	ledger.vouchers.append(voucher)
	while ledger.vouchers.size()>MAX_RECORDS:ledger.vouchers.pop_front()
	ledger.reference_seed=minf(100.0,float(ledger.reference_seed)+float(trial.reference_seed)*4.0*float(trial.reference_growth)/maxf(1,float(trial.control_growth)))
	ledger.reference_line.seed=ledger.reference_seed
	if ledger.lines.size()>=MAX_LINES or ledger.next_id>=1000000000:return
	ledger.lines.append({"id":int(ledger.next_id),"parent":int(trial.line.id),"generation":int(trial.line.generation)+1,"seed":float(trial.seed)*4.0*float(trial.exposed_growth)/maxf(1,float(trial.control_growth)),"site":String(trial.site),"born_day":day,"drought_tolerance":float(trial.line.drought_tolerance),"leaf_ratio":float(trial.line.leaf_ratio)})
	ledger.next_id+=1

## Pure current-application quote. It cannot generate evidence or future seed.
static func land_quote(ledger:Dictionary,site:String,day:int)->float:
	var count:=0
	for trial:Dictionary in ledger.trials:
		if trial.site==site and day-int(trial.start_day)<=MATURITY_DAYS*2:count+=1
	return minf(.02,float(count)*.01)

static func application_quote(ledger:Dictionary,site:String,day:int,harvest:float,drought:float)->float:
	var area:=0.0
	var recovered:=0.0
	for application:Dictionary in ledger.applications:
		if application.site!=site or day>=int(application.until):continue
		var use:=minf(float(application.area),maxf(0,.1-area))
		area+=use
		recovered+=maxf(0,harvest)*use*clampf(drought,0,1)*minf(.25,float(application.response))
	return recovered

static func site_key()->String:
	var state=WorldSimulation.state
	return String(state.resource_settlement_id) if not String(state.resource_settlement_id).is_empty() else "home"

static func pay(stocks:Dictionary,inputs:Dictionary)->bool:
	for item:String in inputs:
		if float(stocks.get(item,0))<float(inputs[item]):return false
	for item:String in inputs:stocks[item]=float(stocks[item])-float(inputs[item])
	return true

## Called once from the existing local Food workforce. No independent workers.
static func advance(workers:float,traveling:bool,drought:float)->Dictionary:
	var result:={"workers":0.0,"land_fraction":0.0}
	var state=WorldSimulation.state
	var ledger:Dictionary=state.field_botany
	var day:=int(state.elapsed_days)
	if traveling or not state.settlement_site_committed or "habitat_observation_records" not in state.known_discoveries or day<=int(ledger.last_day):return result
	for settlement:Dictionary in state.player_settlements:
		if (String(state.resource_settlement_id).is_empty() and bool(settlement.get("primary",false))) or String(settlement.get("id",""))==String(state.resource_settlement_id):
			if not String(settlement.get("occupied_by","")).is_empty():return result
	var budget:=minf(.5,maxf(0,workers)*.05)
	var stocks:Dictionary=state.resource_stockpiles
	var site:=site_key()
	# Build a simple field balance using existing physical materials. Field staff
	# spend real work assembling their measurement kit; it is not a free recipe.
	if not bool(ledger.get("balance",false)) and "standard_measures" in state.known_discoveries and budget>=.2:
		if pay(stocks,{"Timber":.2,"Fiber Plants":.05,"Stone":.1}):
			ledger.balance=true;budget-=.2;result.workers+=.2
	# Preserve finite line slots without discarding a parent referenced by live
	# trials. Historical parent identity remains on each descendant and voucher.
	if ledger.lines.size()>=MAX_LINES:
		for index:int in range(ledger.lines.size()):
			var candidate:Dictionary=ledger.lines[index]
			var needed:=false
			for trial:Dictionary in ledger.trials:
				if int(trial.line.id)==int(candidate.id):needed=true
			if not needed and int(candidate.generation)>0 and float(candidate.seed)<.1:
				ledger.lines.remove_at(index);break
	# At most one generation in progress for automatic research. Prefer the
	# newest viable descendant, keeping its parent voucher for comparison.
	if ledger.trials.is_empty() and budget>=.1:
		for index:int in range(ledger.lines.size()-1,-1,-1):
			if float(ledger.lines[index].seed)>=.1 and pay(stocks,{"Clay":.02}):
				if sow_trial(ledger,index,site,day):budget-=.1;result.workers+=.1
				break
	var count:int=ledger.trials.size()
	# Clay labels/vouchers are paid as observations occur, including the final
	# retained specimen. No Paper prerequisite is imposed on early fieldwork.
	var recording:=minf(float(count),floorf(budget/.1))
	if recording>0 and not pay(stocks,{"Clay":recording*.002}):budget=0.0
	var observation:=observe(ledger,day,site,state.known_discoveries,float(stocks.get("Freshwater",0)),budget,drought)
	stocks["Freshwater"]=maxf(0,float(stocks.get("Freshwater",0))-float(observation.water))
	result.workers+=float(observation.work)
	result.land_fraction=minf(.02,float(count)*.01)
	var current:Array=[]
	for application:Dictionary in ledger.applications:
		if int(application.until)>day:current.append(application)
	ledger.applications=current
	# Applying a locally tested line consumes its own seed. Successor seed is
	# never replenished by a forecast or by possession of the discovery.
	if ledger.applications.is_empty() and budget-float(observation.work)>=.1:
		for line:Dictionary in ledger.lines:
			if float(line.seed)<.1:continue
			for voucher:Dictionary in ledger.vouchers:
				if not bool(voucher.qualified) or float(voucher.response)<=0 or voucher.site!=site or int(voucher.line_id)!=int(line.parent) or day-int(voucher.day)>365:continue
				var seed:=minf(.5,maxf(0,float(line.seed)-.1))
				if seed<.01:break
				if not pay(stocks,{"Freshwater":.2}):break
				line.seed-=seed
				ledger.applications.append({"site":site,"until":day+MATURITY_DAYS,"area":minf(.1,seed*.1),"response":float(voucher.response),"line_id":int(line.id),"seed":seed,"planted_day":day,"line":line.duplicate(true),"evidence":voucher.duplicate(true)})
				result.workers+=.1
				break
			if not ledger.applications.is_empty():break
	ledger.report.merge(result,true)
	return result

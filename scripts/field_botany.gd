extends RefCounted
## Crop-specific evidence. Quantities are game units, never laboratory SI claims.
const MATURITY_DAYS:=90
const MAX_LINES:=8
const MAX_RECORDS:=16
const MAX_TRIALS:=2
const STAGES:=[15,45,90]

static func empty_state()->Dictionary:
	return {"last_day":-1,"next_id":1,"lines":[],"trials":[],"vouchers":[],"applications":[],"report":{}}

static func number(value:Variant,maximum:float=1e9)->bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)>=0 and float(value)<=maximum

static func valid(value:Variant)->bool:
	if not value is Dictionary:return false
	for key:String in ["last_day","next_id"]:
		if not value.get(key) is int:return false
	if value.last_day < -1 or value.next_id<1 or value.next_id>1000000000:return false
	for key:String in ["lines","trials","vouchers","applications"]:
		if not value.get(key) is Array:return false
	if value.lines.size()>MAX_LINES or value.trials.size()>MAX_TRIALS or value.vouchers.size()>MAX_RECORDS or value.applications.size()>2:return false
	if not value.get("report") is Dictionary:return false
	var seen:Dictionary={}
	for line:Variant in value.lines:
		if not line is Dictionary or not line.get("id") is int or line.id<1 or line.id>=value.next_id or seen.has(line.id):return false
		seen[line.id]=true
		if not line.get("parent") is int or line.parent<0 or line.parent>=line.id:return false
		if not line.get("generation") is int or line.generation<0 or line.generation>1000000:return false
		if not number(line.get("seed")) or not number(line.get("drought_tolerance"),1):return false
		if not line.get("site") is String or not line.get("born_day") is int or line.born_day<0:return false
	for trial:Variant in value.trials:
		if not trial is Dictionary or not trial.get("line") is Dictionary:return false
		if not trial.get("start_day") is int or trial.start_day<0 or not trial.get("age") is int or trial.age<0 or trial.age>MATURITY_DAYS:return false
		if not trial.get("stages") is Array or trial.stages.size()>3:return false
		for key:String in ["control_growth","exposed_growth","control_water","exposed_water","blank_loss","plant_loss","stress_days","work","seed"]:
			if not number(trial.get(key)):return false
		if not trial.get("site") is String:return false
	for voucher:Variant in value.vouchers:
		if not voucher is Dictionary or not voucher.get("line_id") is int or not voucher.get("day") is int or not voucher.get("site") is String:return false
		if not voucher.get("qualified") is bool or not number(voucher.get("response"),1):return false
	for application:Variant in value.applications:
		if not application is Dictionary or not application.get("until") is int or not application.get("site") is String:return false
		if not number(application.get("area"),1) or not number(application.get("response"),1):return false
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
	if harvest<=0 or not ledger.lines.is_empty() or ledger.next_id>=1000000000:return 0.0
	var amount:=minf(2.0,harvest*.01)
	if amount<.1:return 0.0
	ledger.lines.append({"id":int(ledger.next_id),"parent":0,"generation":0,"seed":amount,"site":site,"born_day":day,"drought_tolerance":.25})
	ledger.next_id+=1
	return amount

## Starts one paired trial from a real lot. The caller pays water, recording
## material and work before invoking this transition.
static func sow_trial(ledger:Dictionary,line_index:int,site:String,day:int)->bool:
	if ledger.trials.size()>=MAX_TRIALS or line_index<0 or line_index>=ledger.lines.size():return false
	var line:Dictionary=ledger.lines[line_index]
	if line.site!=site or float(line.seed)<.2:return false
	line.seed-=.2
	ledger.trials.append({"line":line.duplicate(true),"site":site,"start_day":day,"age":0,"stages":[],"control_growth":0.0,"exposed_growth":0.0,"control_water":0.0,"exposed_water":0.0,"blank_loss":0.0,"plant_loss":0.0,"stress_days":0.0,"work":0.0,"seed":.2})
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
		trial.exposed_growth+=1.0-stress*(1.0-tolerance)
		trial.blank_loss+=.02+.03*stress
		trial.plant_loss+=.02+.03*stress+.05*(1.0-stress*.5)
		if stress>=.25:trial.stress_days+=1
		if int(trial.age) in STAGES:
			trial.stages.append({"day":day,"age":int(trial.age),"control_size":float(trial.control_growth),"exposed_size":float(trial.exposed_growth)})
		if int(trial.age)<MATURITY_DAYS:survivors.append(trial);continue
		_finish(ledger,trial,day,known)
		report.completed+=1
	ledger.trials=survivors
	ledger.report=report.duplicate(true)
	return report

static func _finish(ledger:Dictionary,trial:Dictionary,day:int,known:Array)->void:
	var qualified:=true
	for id:String in ["habitat_observation_records","comparative_anatomy","biological_classification","biological_reference_collections","developmental_stage_series","heredity_experiments","plant_transpiration_measurement","plant_pathology_diagnosis","plant_resistance_trait_trials"]:
		qualified=qualified and id in known
	qualified=qualified and trial.stages.size()==3 and float(trial.stress_days)>=15 and int(trial.line.generation)>=1
	var response:=clampf(float(trial.exposed_growth)/maxf(1,float(trial.control_growth)),0,1)
	# An observed response is not an improvement invented by the analysis method.
	var voucher:={"line_id":int(trial.line.id),"day":day,"site":String(trial.site),"qualified":qualified,"response":response,"stages":trial.stages.duplicate(true),"parent":int(trial.line.parent),"generation":int(trial.line.generation),"control_water":float(trial.control_water),"exposed_water":float(trial.exposed_water),"plant_loss":float(trial.plant_loss),"blank_loss":float(trial.blank_loss),"stress_days":float(trial.stress_days)}
	ledger.vouchers.append(voucher)
	while ledger.vouchers.size()>MAX_RECORDS:ledger.vouchers.pop_front()
	if ledger.lines.size()>=MAX_LINES or ledger.next_id>=1000000000:return
	ledger.lines.append({"id":int(ledger.next_id),"parent":int(trial.line.id),"generation":int(trial.line.generation)+1,"seed":float(trial.seed)*2.0*response,"site":String(trial.site),"born_day":day,"drought_tolerance":float(trial.line.drought_tolerance)})
	ledger.next_id+=1

## Pure current-application quote. It cannot generate evidence or future seed.
static func application_quote(ledger:Dictionary,site:String,day:int,harvest:float,drought:float)->float:
	var area:=0.0
	var recovered:=0.0
	for application:Dictionary in ledger.applications:
		if application.site!=site or day>=int(application.until):continue
		var use:=minf(float(application.area),maxf(0,.1-area))
		area+=use
		recovered+=maxf(0,harvest)*use*clampf(drought,0,1)*minf(.25,float(application.response))
	return recovered

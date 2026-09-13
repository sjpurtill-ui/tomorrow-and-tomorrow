extends RefCounted
const Samples=preload("res://scripts/microscopy_samples.gd")
static func available(state:Node)->bool:
	if not state.settlement_site_committed or state.convoy_traveling or not bool(state.microscopy.enabled):return false
	for city:Dictionary in state.player_settlements:
		if (state.resource_settlement_id.is_empty() and bool(city.get("primary",false))) or String(city.get("id",""))==String(state.resource_settlement_id):
			if not String(city.get("occupied_by","")).is_empty():return false
	return "laboratory_notebooks" in state.known_discoveries or "microscopic_cell_observation" in state.known_discoveries or "microbial_observation" in state.known_discoveries
static func reserved(state:Node,after_care:float)->float:
	if not available(state):return 0.0
	return maxf(0,after_care)*clampf(float(state.microscopy.staff_share),0,.5)
static func site()->String:
	return String(WorldSimulation.state.resource_settlement_id) if not String(WorldSimulation.state.resource_settlement_id).is_empty() else "home"
static func pay(ledger:Dictionary,stocks:Dictionary,cost:Dictionary,work:float)->bool:
	if float(ledger.work_bank)<work:return false
	for key:String in cost:
		if float(stocks.get(key,0))<float(cost[key]):return false
	for key:String in cost:stocks[key]=float(stocks[key])-float(cost[key])
	ledger.work_bank-=work
	return true
static func prepare_station(ledger:Dictionary,stocks:Dictionary,known:Array,day:int)->void:
	if not bool(ledger.tools.get("bench",false)):
		if pay(ledger,stocks,{"Compound Microscopes":1.0,"Laboratory Glassware":1.0,"Specimen Slides":.2},.5):ledger.tools.bench=true
	if "precision_thermometry" in known and not bool(ledger.tools.get("thermometry",false)):
		# A finite comparison vessel/probe assembly. Calibration and exposure are
		# abstract game units, not a real sterilization protocol or temperature.
		if pay(ledger,stocks,{"Glass Tubes":1.0,"Copper Wire":.1,"Glass Vessels":1.0},.5):ledger.tools.thermometry=true
	if "instrument_sterilization" in known and bool(ledger.tools.get("thermometry",false)) and int(ledger.tools.get("sterile_until",-1))<day:
		if pay(ledger,stocks,{"Charcoal":.05,"Freshwater":.2},.1):
			ledger.tools.heat_day=day
			ledger.tools.heat_steps=int(ledger.tools.get("heat_steps",0))+1
			if int(ledger.tools.heat_steps)>=2:
				ledger.tools.sterile_until=day+1;ledger.tools.sterile_uses=2;ledger.tools.heat_steps=0
static func collect_starter(ledger:Dictionary,stocks:Dictionary,day:int)->void:
	var batches=load("res://scripts/food_batches.gd")
	for lot:Dictionary in batches.data().lots:
		if lot.kind!="starter" or float(lot.amount)<.02:continue
		var exists:=false
		for sample:Dictionary in ledger.specimens:
			if sample.kind=="starter" and int(sample.source)==int(lot.id) and sample.site==site():exists=true
		if exists or ledger.specimens.size()>=Samples.LIMIT:continue
		if not pay(ledger,stocks,{"Specimen Slides":.01,"Freshwater":.02},.05):return
		var age:=maxi(0,day-int(lot.created))
		var profile:={"viability":clampf(1.0-float(age)*.025,.1,1),"contamination":clampf(float(age)*.02,0,.8),"tissue_order":0.0}
		var sample:=Samples.add(ledger,"starter",int(lot.id),int(lot.created),site(),day,.01,profile)
		if not sample.is_empty():sample.origin=batches.withdraw(lot,.01)
		return
static func collect_plant(ledger:Dictionary,stocks:Dictionary,day:int)->void:
	for trial:Dictionary in WorldSimulation.state.field_botany.trials:
		if int(trial.age)<15 or trial.site!=site() or float(trial.seed)<.001:continue
		var exists:=false
		for sample:Dictionary in ledger.specimens:
			if sample.kind=="plant" and int(sample.source)==int(trial.line.id) and int(sample.source_day)==int(trial.start_day):exists=true
		if exists or ledger.specimens.size()>=Samples.LIMIT:continue
		if not pay(ledger,stocks,{"Specimen Slides":.01,"Freshwater":.02},.05):return
		var vigor:=clampf(float(trial.exposed_growth)/maxf(1,float(trial.control_growth)),0,1)
		var profile:={"viability":vigor,"contamination":.05,"tissue_order":vigor,"stage":int(trial.age),"leaf_ratio":float(trial.line.leaf_ratio)}
		var sample:=Samples.add(ledger,"plant",int(trial.line.id),int(trial.start_day),site(),day,.001,profile)
		if not sample.is_empty():trial.seed-=.001
		return
static func advance(traveling:bool)->Dictionary:
	var state=WorldSimulation.state
	var ledger:Dictionary=state.microscopy
	var day:=int(state.elapsed_days)
	if day<=int(ledger.last_day):return ledger.report
	ledger.last_day=day
	var report:={"staff":0.0,"observed":0,"cultured":0,"expired":0}
	if traveling or not available(state):ledger.report=report;return report
	var staff:=reserved(state,state.effective_workers("Knowledge",false,false,false,true))
	ledger.work_bank=minf(8,float(ledger.work_bank)+staff)
	report.staff=staff
	var stocks:Dictionary=state.resource_stockpiles
	var known:Array=state.known_discoveries
	Samples.expire(ledger,day)
	prepare_station(ledger,stocks,known,day)
	if not bool(ledger.tools.get("bench",false)):ledger.report=report;return report
	collect_starter(ledger,stocks,day);collect_plant(ledger,stocks,day)
	for sample:Dictionary in ledger.specimens.duplicate():
		if sample.site!=site():continue
		var aseptic:bool="aseptic_laboratory_practice" in known and protocol_ready(ledger,String(sample.kind)) and int(ledger.tools.get("sterile_until",-1))>=day and int(ledger.tools.get("sterile_uses",0))>0
		if "cell_culture_methods" in known and day>int(sample.last_day) and float(state.food_stocks.get("Dry staples",0))>=.02:
			if pay(ledger,stocks,{"Freshwater":.05,"Laboratory Glassware":.002},.05):
				if Samples.grow(sample,day,.02,aseptic):
					state.food_stocks["Dry staples"]-=.02
					if aseptic:ledger.tools.sterile_uses-=1
					Samples.record(ledger,sample,day,"culture",{"media":float(sample.media),"aseptic":aseptic,"line":int(sample.line)})
					report.cultured+=1
		if not pay(ledger,stocks,{"Clay":.002},.05):continue
		var stained:=false
		if "biological_staining" in known:stained=pay(ledger,stocks,{"Plant Tannin Extract":.001,"Freshwater":.01},.02)
		if Samples.measure(ledger,sample,day,stained,known):report.observed+=1
		if "microbial_growth_measurement" in known and sample.line>0 and sample.history.size()>=2:
			var first:Dictionary=sample.history[0];var last:Dictionary=sample.history[-1]
			Samples.record(ledger,sample,day,"growth",{"line":int(sample.line),"elapsed":int(last.day)-int(first.day),"initial":float(first.cells),"final":float(last.cells)})
		if "microbial_isolation_methods" in known and sample.kind=="starter" and sample.parent==0 and pay(ledger,stocks,{"Laboratory Glassware":.005,"Freshwater":.02},.05):
			var child:=Samples.isolate(ledger,sample,day)
			if not child.is_empty():Samples.record(ledger,child,day,"isolation",{"parent":int(sample.id),"mixed_fraction":float(child.contamination)})
	interpret(ledger,stocks,known,day)
	ledger.report=report
	return report

static func interpret(ledger:Dictionary,stocks:Dictionary,known:Array,day:int)->void:
	if "cell_theory" in known:
		var kinds:Dictionary={}
		for sample:Dictionary in ledger.specimens:
			if sample.methods.has("cells"):kinds[sample.kind]=int(sample.id)
		if kinds.size()>=2:
			for sample:Dictionary in ledger.specimens:
				if sample.methods.has("cells"):Samples.record(ledger,sample,day,"cellular_model",{"comparisons":kinds.duplicate(),"interpretation":"cellular units across crop tissue and starter material"})
	# A published method requires two separately taken samples and comparable
	# dated observations, not a copy of a result within the same sample lineage.
	if "experimental_protocol_publication" not in known or ledger.protocols.size()>=8:return
	for first:Dictionary in ledger.specimens:
		if not first.methods.has("notebook") or first.history.size()<2:continue
		for second:Dictionary in ledger.specimens:
			if second.id==first.id or second.source==first.source or second.kind!=first.kind or not second.methods.has("notebook") or second.history.size()<2:continue
			var exists:=false
			for protocol:Dictionary in ledger.protocols:
				if protocol.kind==first.kind:exists=true
			if exists:continue
			var repeatable:=absf(float(first.viability)-float(second.viability))<=.25
			if not pay(ledger,stocks,{"Printed Sheets":.1},.2):return
			ledger.protocols.append({"kind":String(first.kind),"first":int(first.id),"second":int(second.id),"day":day,"repeatable":repeatable,"first_source":int(first.source),"second_source":int(second.source)})
			return
static func starter_usable(lot:Dictionary,day:int)->bool:
	var ledger:Dictionary=WorldSimulation.state.microscopy
	for sample:Dictionary in ledger.specimens:
		if sample.kind!="starter" or sample.site!=site() or int(sample.source)!=int(lot.id) or int(sample.source_day)!=int(lot.created) or sample.history.is_empty():continue
		if day-int(sample.history[-1].day)>3:continue
		# A mixed parent alone is not sufficient: require an isolated line with
		# measured growth before rejecting this particular source starter.
		if sample.methods.has("growth") and float(sample.contamination)>.35:return false
	return true
static func field_evidence(cohort:int,start_day:int,day:int)->Dictionary:
	for sample:Dictionary in WorldSimulation.state.microscopy.specimens:
		if sample.kind!="plant" or sample.site!=site() or int(sample.source)!=cohort or int(sample.source_day)!=start_day:continue
		if not sample.methods.has("tissue") or not sample.methods.has("cellular_model") or not sample.methods.has("time_lapse"):continue
		if day-int(sample.methods.tissue.day)>7:continue
		return {"sample":int(sample.id),"day":int(sample.methods.tissue.day),"viable_fraction":float(sample.viability),"tissue_order":float(sample.profile.tissue_order)}
	return {}

static func protocol_ready(ledger:Dictionary,kind:String)->bool:
	for protocol:Dictionary in ledger.protocols:
		if protocol.kind==kind and bool(protocol.repeatable):return true
	return false

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
	if int(ledger.tools.get("sterile_until",-1))<day:ledger.tools.sterile_uses=0
	var calibration:Dictionary=ledger.tools.get("calibration",{})
	if bool(ledger.tools.get("thermometry",false)) and "precision_thermometry" in known and (calibration.is_empty() or day-int(calibration.day)>30):
		if pay(ledger,stocks,{"Freshwater":.2,"Charcoal":.05},.1):
			ledger.tools.calibration={"day":day,"cold_reference":0.0,"hot_reference":1.0,"uncertainty":.05}
			calibration=ledger.tools.calibration
			ledger.tools.heat_readings=[];ledger.tools.erase("heat_day");ledger.tools.heat_level=0.0
	if "instrument_sterilization" in known and not calibration.is_empty() and day-int(calibration.day)<=30 and int(ledger.tools.get("sterile_until",-1))<day:
		if pay(ledger,stocks,{"Charcoal":.05,"Freshwater":.2},.1):
			var consecutive:bool=int(ledger.tools.get("heat_day",-2))==day-1
			var carried:=float(ledger.tools.get("heat_level",0))*.5 if consecutive else 0.0
			var observed_heat:=minf(1.0,carried+.75)
			ledger.tools.heat_steps=(int(ledger.tools.get("heat_steps",0))+1) if consecutive else 1
			ledger.tools.heat_day=day;ledger.tools.heat_level=observed_heat
			var readings:Array=ledger.tools.get("heat_readings",[])
			if not consecutive:readings.clear()
			readings.append({"day":day,"observed_heat":observed_heat,"uncertainty":float(calibration.uncertainty),"calibration_day":int(calibration.day),"fuel":.05,"water":.2})
			while readings.size()>2:readings.pop_front()
			ledger.tools.heat_readings=readings
			if readings.size()==2 and float(readings[0].observed_heat)>=.7 and observed_heat-float(calibration.uncertainty)>=.9:
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
		if int(trial.age)<15 or trial.site!=site() or float(trial.seed)<.001 or day<int(trial.start_day)+int(trial.age):continue
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
		if "cell_culture_methods" in known and day>int(sample.last_day) and float(state.food_stocks.get("Dry staples",0))>=.03:
			if pay(ledger,stocks,{"Freshwater":.05,"Laboratory Glassware":.002},.05):
				if Samples.grow(sample,day,.02,aseptic):
					state.food_stocks["Dry staples"]-=.03
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
		var already_isolated:=false
		for candidate:Dictionary in ledger.specimens:
			if int(candidate.parent)==int(sample.id):already_isolated=true
		if "microbial_isolation_methods" in known and sample.kind=="starter" and sample.parent==0 and not already_isolated and pay(ledger,stocks,{"Laboratory Glassware":.005,"Freshwater":.02},.05):
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
	if "experimental_protocol_publication" not in known:return
	for first:Dictionary in ledger.specimens:
		if not first.methods.has("notebook") or first.history.size()<2:continue
		for second:Dictionary in ledger.specimens:
			if second.id==first.id or second.source==first.source or second.kind!=first.kind or not second.methods.has("notebook") or second.history.size()<2:continue
			var exists:=false
			for protocol:Dictionary in ledger.protocols:
				if protocol.kind==first.kind and (bool(protocol.repeatable) or (mini(int(protocol.first_source),int(protocol.second_source))==mini(int(first.source),int(second.source)) and maxi(int(protocol.first_source),int(protocol.second_source))==maxi(int(first.source),int(second.source)))):exists=true
			if exists:continue
			var pair:=replication_pair(first,second)
			if pair.is_empty():continue
			var first_estimate:=float(pair.first.cells)/maxf(.000001,float(pair.first.total_cells))
			var second_estimate:=float(pair.second.cells)/maxf(.000001,float(pair.second.total_cells))
			var repeatable:=absf(first_estimate-second_estimate)<=.25
			if not pay(ledger,stocks,{"Printed Sheets":.1},.2):return
			if ledger.protocols.size()>=8:
				for index:int in range(ledger.protocols.size()):
					if not bool(ledger.protocols[index].repeatable):ledger.protocols.remove_at(index);break
			ledger.protocols.append({"kind":String(first.kind),"first":int(first.id),"second":int(second.id),"day":day,"repeatable":repeatable,"first_source":int(first.source),"second_source":int(second.source),"first_sample_day":int(first.day),"second_sample_day":int(second.day),"procedure":{"kind":String(first.kind),"preparation":"stained" if float(pair.first.contrast)>.8 else "unstained","view":pair.first.duplicate(true)},"replication":{"kind":String(second.kind),"preparation":"stained" if float(pair.second.contrast)>.8 else "unstained","view":pair.second.duplicate(true)},"first_viability":first_estimate,"second_viability":second_estimate})
			return
static func starter_usable(lot:Dictionary,day:int)->bool:
	var ledger:Dictionary=WorldSimulation.state.microscopy
	for sample:Dictionary in ledger.specimens:
		if sample.kind!="starter" or sample.site!=site() or int(sample.source)!=int(lot.id) or int(sample.source_day)!=int(lot.created) or sample.history.is_empty():continue
		if day-int(sample.history[-1].day)>3:continue
		# A mixed parent alone is not sufficient: require an isolated line with
		# measured growth before rejecting this particular source starter.
		if not sample.methods.has("growth"):continue
		for parent:Dictionary in ledger.specimens:
			if int(parent.id)!=int(sample.parent) or parent.site!=sample.site or int(parent.source)!=int(sample.source) or not parent.methods.has("microbes"):continue
			var observed:Dictionary=parent.methods.microbes.observation
			if day-int(parent.methods.microbes.day)<=3 and float(observed.mixed_fraction)>.35:return false
	return true
static func field_evidence(cohort:int,start_day:int,day:int)->Dictionary:
	for sample:Dictionary in WorldSimulation.state.microscopy.specimens:
		if sample.kind!="plant" or sample.site!=site() or int(sample.source)!=cohort or int(sample.source_day)!=start_day:continue
		if not sample.methods.has("tissue") or not sample.methods.has("cellular_model") or not sample.methods.has("time_lapse"):continue
		if day-int(sample.methods.tissue.day)>7:continue
		return {"sample":int(sample.id),"cohort":int(sample.source),"source_day":int(sample.source_day),"day":int(sample.methods.tissue.day),"viable_fraction":maxf(0,float(sample.methods.tissue.observation.viable_fraction)-float(sample.methods.tissue.observation.uncertainty)),"tissue_order":float(sample.methods.tissue.observation.organized_fraction)}
	return {}

static func protocol_ready(ledger:Dictionary,kind:String)->bool:
	for protocol:Dictionary in ledger.protocols:
		if protocol.kind==kind and bool(protocol.repeatable):return true
	return false

static func replication_pair(first:Dictionary,second:Dictionary)->Dictionary:
	for a:Dictionary in first.history:
		if int(a.day)<=int(first.day) or float(a.blank_paid)<=0 or float(a.contrast)<.8:continue
		for b:Dictionary in second.history:
			if int(a.day)-int(first.day)!=int(b.day)-int(second.day):continue
			if a.source_stage!=b.source_stage or a.aseptic!=b.aseptic or a.contrast!=b.contrast or float(b.blank_paid)<=0:continue
			if absf(float(a.sample_mass)-float(b.sample_mass))>.00001:continue
			return {"first":a.duplicate(true),"second":b.duplicate(true)}
	return {}

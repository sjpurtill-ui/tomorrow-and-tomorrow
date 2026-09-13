extends RefCounted
## Bounded simulated specimens; cell counts/contrast are abstract game measures.
## Sampling and growth never return analyzed/stained material to edible stocks.
const LIMIT:=12
const RECORD_LIMIT:=48
const LIFE:=21
static func empty_state()->Dictionary:
	return {"enabled":true,"staff_share":.25,"last_day":-1,"next_id":1,"specimens":[],"records":[],"protocols":[],"tools":{},"report":{}}
static func add(ledger:Dictionary,kind:String,source:int,source_day:int,site:String,day:int,amount:float,profile:Dictionary,parent:int=0)->Dictionary:
	if kind not in ["starter","plant"] or amount<=0 or ledger.specimens.size()>=LIMIT or int(ledger.next_id)>=1000000000:return {}
	for specimen:Dictionary in ledger.specimens:
		if specimen.kind==kind and int(specimen.source)==source and specimen.site==site and int(specimen.source_day)==source_day and int(specimen.parent)==parent:return {}
	var viability:=clampf(float(profile.get("viability",1)),0,1)
	var sample:={"id":int(ledger.next_id),"kind":kind,"source":source,"source_day":source_day,"site":site,"day":day,"last_day":day,"amount":amount,"profile":profile.duplicate(true),"cells":amount*100.0,"viability":viability,"contamination":clampf(float(profile.get("contamination",0)),0,1),"media":0.0,"line":0,"generation":0,"parent":parent,"history":[],"methods":{},"status":"fresh"}
	ledger.next_id+=1;ledger.specimens.append(sample)
	return sample
static func record(ledger:Dictionary,specimen:Dictionary,day:int,method:String,observation:Dictionary)->void:
	var row:={"sample":int(specimen.id),"source":int(specimen.source),"source_day":int(specimen.source_day),"site":String(specimen.site),"day":day,"method":method,"observation":observation.duplicate(true)}
	ledger.records.append(row)
	while ledger.records.size()>RECORD_LIMIT:ledger.records.pop_front()
	specimen.methods[method]=row.duplicate(true)
static func measure(ledger:Dictionary,specimen:Dictionary,day:int,stained:bool,known:Array)->bool:
	if day<int(specimen.day) or specimen.status=="expired":return false
	if not specimen.history.is_empty() and int(specimen.history[-1].day)>=day:return false
	var contrast:=.85 if stained else .45
	# Microscopic visibility distinguishes aggregate structures from reliably
	# separated cellular units. Staining is optional and material-paid by owner.
	var view:={"day":day,"cells":float(specimen.cells)*float(specimen.viability),"contrast":contrast,"contamination":float(specimen.contamination),"tissue_order":float(specimen.profile.get("tissue_order",0)),"line":int(specimen.line)}
	specimen.history.append(view)
	while specimen.history.size()>8:specimen.history.pop_front()
	if "laboratory_notebooks" in known:record(ledger,specimen,day,"notebook",{"kind":String(specimen.kind),"preparation":"stained" if stained else "unstained","elapsed":day-int(specimen.day),"view":view})
	if "microscopic_cell_observation" in known:record(ledger,specimen,day,"cells",view)
	if stained and "biological_staining" in known:record(ledger,specimen,day,"contrast",{"contrast":contrast,"unstained_reference":.45})
	if specimen.kind=="starter" and "microbial_observation" in known:record(ledger,specimen,day,"microbes",{"count":view.cells,"mixed_fraction":view.contamination,"identity":"unassigned local culture"})
	if "cell_division_observation" in known and specimen.history.size()>=2:
		var previous:Dictionary=specimen.history[-2]
		if day>int(previous.day) and float(view.cells)>float(previous.cells):record(ledger,specimen,day,"division",{"before":float(previous.cells),"after":float(view.cells),"elapsed":day-int(previous.day)})
	if specimen.kind=="plant" and "tissue_histology" in known and contrast>=.8:
		record(ledger,specimen,day,"tissue",{"organized_fraction":view.tissue_order,"viable_fraction":float(specimen.viability),"cohort":int(specimen.source),"sampled_stage":int(specimen.profile.get("stage",0))})
	if "live_cell_time_lapse" in known and specimen.history.size()>=3 and specimen.methods.has("culture"):
		record(ledger,specimen,day,"time_lapse",{"frames":specimen.history.duplicate(true),"source_line":int(specimen.line)})
	return true
static func grow(specimen:Dictionary,day:int,media:float,aseptic:bool)->bool:
	if day<=int(specimen.last_day) or day-int(specimen.day)>LIFE or media<=0:return false
	specimen.last_day=day
	if specimen.status=="expired":return false
	# One eligible day only; missed time is not converted into free generations.
	var food:=minf(media,.02)
	var growth:=food*100.0*float(specimen.viability)*(1.0-float(specimen.contamination))
	specimen.cells=minf(1000000,float(specimen.cells)+growth)
	specimen.media+=food
	specimen.contamination=clampf(float(specimen.contamination)+(.002 if aseptic else .04),0,1)
	specimen.viability=clampf(float(specimen.viability)-float(specimen.contamination)*.02,0,1)
	return true
static func isolate(ledger:Dictionary,specimen:Dictionary,day:int)->Dictionary:
	if specimen.kind!="starter" or specimen.history.is_empty() or float(specimen.amount)<.002 or ledger.specimens.size()>=LIMIT:return {}
	# Transfer part of an observed mixed sample, retaining its origin and mixed
	# fraction; isolation is never an unexplained purity guarantee.
	var taken:=float(specimen.amount)*.25
	specimen.amount-=taken
	var child:=add(ledger,"starter",int(specimen.source),int(specimen.source_day),String(specimen.site),day,taken,specimen.profile,int(specimen.id))
	if child.is_empty():specimen.amount+=taken;return {}
	child.parent=int(specimen.id);child.generation=int(specimen.generation)+1
	child.line=int(child.id);child.contamination=float(specimen.contamination)*.5
	return child
static func expire(ledger:Dictionary,day:int)->void:
	for index:int in range(ledger.specimens.size()-1,-1,-1):
		var specimen:Dictionary=ledger.specimens[index]
		if day-int(specimen.day)>LIFE or float(specimen.viability)<=.05:ledger.specimens.remove_at(index)
static func number(value:Variant,maximum:float=1e9)->bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)>=0 and float(value)<=maximum
static func valid(ledger:Variant)->bool:
	if not ledger is Dictionary or not ledger.get("enabled") is bool or not number(ledger.get("staff_share"),.5):return false
	if not ledger.get("last_day") is int or ledger.last_day < -1 or not ledger.get("next_id") is int or ledger.next_id<1 or ledger.next_id>=1000000000:return false
	for key:String in ["specimens","records","protocols"]:
		if not ledger.get(key) is Array:return false
	if ledger.specimens.size()>LIMIT or ledger.records.size()>RECORD_LIMIT or ledger.protocols.size()>8:return false
	if not ledger.get("tools") is Dictionary or not ledger.get("report") is Dictionary:return false
	var ids:Dictionary={}
	for sample:Variant in ledger.specimens:
		if not sample is Dictionary:return false
		for key:String in ["id","source","source_day","day","last_day","line","generation","parent"]:
			if not sample.get(key) is int or sample[key]<0:return false
		if sample.id<1 or sample.id>=ledger.next_id or ids.has(sample.id) or sample.parent>=sample.id or sample.day<sample.source_day or sample.last_day<sample.day:return false
		ids[sample.id]=true
		if sample.get("kind") not in ["starter","plant"] or not sample.get("site") is String or sample.get("status") not in ["fresh","cultured","expired"]:return false
		for key:String in ["amount","cells","media"]:
			if not number(sample.get(key)):return false
		for key:String in ["viability","contamination"]:
			if not number(sample.get(key),1):return false
		if not sample.get("profile") is Dictionary or not sample.get("methods") is Dictionary or not sample.get("history") is Array or sample.history.size()>8:return false
		var previous:=int(sample.day)-1
		for frame:Variant in sample.history:
			if not frame is Dictionary or not frame.get("day") is int or frame.day<=previous:return false
			for key:String in ["cells","contrast","contamination","tissue_order","line"]:
				if not number(frame.get(key)):return false
			previous=frame.day
	return true

extends RefCounted
## Bounded simulated specimens; cell counts/contrast are abstract game measures.
## Sampling and growth never return analyzed/stained material to edible stocks.
const LIMIT:=12
const RECORD_LIMIT:=48
const LIFE:=21
static func empty_state()->Dictionary:
	return {"enabled":true,"staff_share":.25,"work_bank":0.0,"last_day":-1,"next_id":1,"specimens":[],"records":[],"protocols":[],"tools":{},"report":{}}
static func add(ledger:Dictionary,kind:String,source:int,source_day:int,site:String,day:int,amount:float,profile:Dictionary,parent:int=0)->Dictionary:
	if kind not in ["starter","plant"] or amount<=0 or ledger.specimens.size()>=LIMIT or int(ledger.next_id)>=1000000000:return {}
	for specimen:Dictionary in ledger.specimens:
		if specimen.kind==kind and int(specimen.source)==source and specimen.site==site and int(specimen.source_day)==source_day and int(specimen.parent)==parent:return {}
	var viability:=clampf(float(profile.get("viability",1)),0,1)
	var sample:={"id":int(ledger.next_id),"kind":kind,"source":source,"source_day":source_day,"site":site,"day":day,"last_day":day,"amount":amount,"profile":profile.duplicate(true),"cells":amount*100.0,"viability":viability,"contamination":clampf(float(profile.get("contamination",0)),0,1),"blank_contamination":0.0,"blank_media":0.0,"media":0.0,"line":0,"generation":0,"parent":parent,"history":[],"methods":{},"status":"fresh"}
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
	var view:={"day":day,"cells":float(specimen.cells)*float(specimen.viability),"total_cells":float(specimen.cells),"uncertainty":1.0-contrast,"sample_mass":float(specimen.amount),"source_stage":int(specimen.profile.get("stage",0)),"blank_paid":float(specimen.blank_media),"aseptic":bool(specimen.methods.get("culture",{}).get("observation",{}).get("aseptic",false)),"contrast":contrast,"contamination":float(specimen.contamination),"blank_contamination":float(specimen.blank_contamination),"tissue_order":float(specimen.profile.get("tissue_order",0)),"line":int(specimen.line)}
	specimen.history.append(view)
	while specimen.history.size()>8:specimen.history.pop_front()
	if "laboratory_notebooks" in known:record(ledger,specimen,day,"notebook",{"kind":String(specimen.kind),"preparation":"stained" if stained else "unstained","elapsed":day-int(specimen.day),"view":view})
	if "microscopic_cell_observation" in known:record(ledger,specimen,day,"cells",view)
	if stained and "biological_staining" in known:record(ledger,specimen,day,"contrast",{"contrast":contrast,"unstained_reference":.45})
	if specimen.kind=="starter" and "microbial_observation" in known:record(ledger,specimen,day,"microbes",{"count":view.cells,"mixed_fraction":maxf(0,float(view.contamination)-float(view.blank_contamination)),"blank_fraction":float(view.blank_contamination),"identity":"unassigned local culture"})
	if "cell_division_observation" in known and specimen.history.size()>=2:
		var previous:Dictionary=specimen.history[-2]
		if day>int(previous.day) and float(view.cells)>float(previous.cells):record(ledger,specimen,day,"division",{"before":float(previous.cells),"after":float(view.cells),"elapsed":day-int(previous.day)})
	if specimen.kind=="plant" and "tissue_histology" in known and contrast>=.8:
		record(ledger,specimen,day,"tissue",{"organized_fraction":view.tissue_order,"viable_fraction":clampf(float(view.cells)/maxf(.000001,float(view.total_cells)),0,1),"uncertainty":float(view.uncertainty),"contrast":contrast,"cohort":int(specimen.source),"sampled_stage":int(specimen.profile.get("stage",0))})
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
	specimen.blank_media+=.01
	specimen.blank_contamination=clampf(float(specimen.blank_contamination)+(.002 if aseptic else .04),0,1)
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
	child.cells=float(specimen.cells)*.25;specimen.cells-=float(child.cells)
	child.media=float(specimen.media)*.25;specimen.media-=float(child.media)
	child.viability=float(specimen.viability)
	child.line=int(child.id);child.contamination=float(specimen.contamination)*.5
	child.blank_contamination=float(specimen.blank_contamination)*.5
	return child
static func expire(ledger:Dictionary,day:int)->void:
	for index:int in range(ledger.specimens.size()-1,-1,-1):
		var specimen:Dictionary=ledger.specimens[index]
		if day-int(specimen.day)>LIFE or float(specimen.viability)<=.05:ledger.specimens.remove_at(index)
static func number(value:Variant,maximum:float=1e9)->bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)>=0 and float(value)<=maximum
static func valid(ledger:Variant)->bool:
	if not ledger is Dictionary or not ledger.get("enabled") is bool or not number(ledger.get("staff_share"),.5) or not number(ledger.get("work_bank"),8):return false
	if not ledger.get("last_day") is int or ledger.last_day < -1 or not ledger.get("next_id") is int or ledger.next_id<1 or ledger.next_id>=1000000000:return false
	for key:String in ["specimens","records","protocols"]:
		if not ledger.get(key) is Array:return false
	if ledger.specimens.size()>LIMIT or ledger.records.size()>RECORD_LIMIT or ledger.protocols.size()>8:return false
	if not ledger.get("tools") is Dictionary or not ledger.get("report") is Dictionary:return false
	for key:Variant in ledger.tools:
		if key in ["bench","thermometry"]:
			if not ledger.tools[key] is bool:return false
		elif key in ["heat_day","sterile_until","sterile_uses","heat_steps"]:
			if not ledger.tools[key] is int or ledger.tools[key]<0:return false
		elif key=="heat_level":
			if not number(ledger.tools[key],1):return false
		elif key not in ["calibration","heat_readings"]:return false
	if not valid_heat(ledger.tools):return false
	if int(ledger.tools.get("sterile_uses",0))>2 or int(ledger.tools.get("heat_steps",0))>1:return false
	for key:Variant in ledger.report:
		if key not in ["staff","observed","cultured","expired"] or not number(ledger.report[key]):return false
	for row:Variant in ledger.records:
		if not valid_record(row):return false
	for protocol:Variant in ledger.protocols:
		if not valid_protocol(protocol):return false
	var ids:Dictionary={}
	for sample:Variant in ledger.specimens:
		if not sample is Dictionary:return false
		for key:String in ["id","source","source_day","day","last_day","line","generation","parent"]:
			if not sample.get(key) is int or sample[key]<0:return false
		if sample.id<1 or sample.id>=ledger.next_id or ids.has(sample.id) or sample.parent>=sample.id or sample.day<sample.source_day or sample.last_day<sample.day:return false
		ids[sample.id]=true
		if sample.get("kind") not in ["starter","plant"] or not sample.get("site") is String or sample.get("status") not in ["fresh","cultured","expired"]:return false
		for key:String in ["amount","cells","media","blank_media"]:
			if not number(sample.get(key)):return false
		for key:String in ["viability","contamination","blank_contamination"]:
			if not number(sample.get(key),1):return false
		if not sample.get("profile") is Dictionary or not sample.get("methods") is Dictionary or not sample.get("history") is Array or sample.history.size()>8:return false
		for key:Variant in sample.profile:
			if key not in ["viability","contamination","tissue_order","stage","leaf_ratio"] or not number(sample.profile[key],180 if key=="stage" else 1):return false
		if sample.methods.size()>12:return false
		for method:Variant in sample.methods:
			var row:Variant=sample.methods[method]
			if not valid_record(row) or row.method!=method or row.sample!=sample.id or row.source!=sample.source or row.source_day!=sample.source_day or row.site!=sample.site or row.day<sample.day:return false
		var previous:=int(sample.day)-1
		for frame:Variant in sample.history:
			if not valid_frame(frame) or frame.day<=previous:return false
			for key:String in ["cells","contrast","contamination","tissue_order","line"]:
				if not number(frame.get(key)):return false
			previous=frame.day
	return true

static func valid_settlements(records:Variant)->bool:
	if not records is Array:return false
	for city:Variant in records:
		if not city is Dictionary or not city.get("local_resources",{}) is Dictionary:return false
		if not valid(city.get("local_resources",{}).get("microscopy",empty_state())):return false
	return true

static func valid_frame(frame:Variant)->bool:
	if not frame is Dictionary or not frame.get("day") is int or frame.day<0 or not frame.get("line") is int or frame.line<0:return false
	for key:String in ["cells","total_cells","contrast","uncertainty","sample_mass","blank_paid","contamination","blank_contamination","tissue_order"]:
		if not number(frame.get(key),1000000 if key in ["cells","total_cells","sample_mass","blank_paid"] else 1):return false
	if not frame.get("source_stage") is int or frame.source_stage<0 or not frame.get("aseptic") is bool:return false
	if absf(float(frame.uncertainty)-(1.0-float(frame.contrast)))>.00001:return false
	return true
static func valid_record(row:Variant)->bool:
	if not row is Dictionary:return false
	for key:String in ["sample","source","source_day","day"]:
		if not row.get(key) is int or row[key]<0:return false
	if row.sample<1 or row.source<1 or row.day<row.source_day or not row.get("site") is String or row.site.length()>128 or not row.get("observation") is Dictionary:return false
	var o:Dictionary=row.observation
	match row.get("method",""):
		"notebook":return o.get("kind") in ["starter","plant"] and o.get("preparation") in ["stained","unstained"] and number(o.get("elapsed")) and valid_frame(o.get("view")) and o.view.day==row.day
		"cells":return valid_frame(o) and o.day==row.day
		"contrast":return o.get("contrast")==.85 and o.get("unstained_reference")==.45
		"microbes":return number(o.get("count")) and number(o.get("mixed_fraction"),1) and number(o.get("blank_fraction"),1) and o.get("identity")=="unassigned local culture"
		"division":return number(o.get("before")) and number(o.get("after")) and o.after>o.before and o.get("elapsed") is int and o.elapsed>0
		"tissue":return number(o.get("organized_fraction"),1) and number(o.get("viable_fraction"),1) and number(o.get("uncertainty"),1) and number(o.get("contrast"),1) and o.get("cohort")==row.source and o.get("sampled_stage") is int and o.sampled_stage>=0
		"time_lapse":
			if not o.get("frames") is Array or o.frames.size()<3 or o.frames.size()>8 or not o.get("source_line") is int:return false
			var previous:=-1
			for frame:Variant in o.frames:
				if not valid_frame(frame) or frame.day<=previous or frame.day>row.day or frame.line!=o.source_line:return false
				previous=frame.day
			return true
		"culture":return number(o.get("media")) and o.get("aseptic") is bool and o.get("line") is int and o.line>=0
		"growth":return o.get("line") is int and o.line>0 and o.get("elapsed") is int and o.elapsed>0 and number(o.get("initial")) and number(o.get("final"))
		"isolation":return o.get("parent") is int and o.parent>0 and o.parent<row.sample and number(o.get("mixed_fraction"),1)
		"cellular_model":
			if not o.get("comparisons") is Dictionary or o.comparisons.size()!=2:return false
			for key:String in ["starter","plant"]:
				if not o.comparisons.get(key) is int or o.comparisons[key]<1:return false
			return o.get("interpretation")=="cellular units across crop tissue and starter material"
	return false
static func valid_protocol(protocol:Variant)->bool:
	if not protocol is Dictionary or protocol.get("kind") not in ["starter","plant"] or not protocol.get("repeatable") is bool:return false
	for key:String in ["first","second","day","first_source","second_source","first_sample_day","second_sample_day"]:
		if not protocol.get(key) is int or protocol[key]<0:return false
	if protocol.first<1 or protocol.second<1 or protocol.first==protocol.second or protocol.first_source==protocol.second_source:return false
	if not number(protocol.get("first_viability"),1) or not number(protocol.get("second_viability"),1):return false
	if protocol.repeatable!=(absf(float(protocol.first_viability)-float(protocol.second_viability))<=.25):return false
	for key:String in ["procedure","replication"]:
		var o:Variant=protocol.get(key)
		if not o is Dictionary or o.get("kind")!=protocol.kind or o.get("preparation") not in ["stained","unstained"] or not valid_frame(o.get("view")) or o.view.day>protocol.day:return false
	var a:Dictionary=protocol.procedure.view
	var b:Dictionary=protocol.replication.view
	if a.source_stage!=b.source_stage or a.aseptic!=b.aseptic or a.contrast!=b.contrast or a.contrast<.8 or a.blank_paid<=0 or b.blank_paid<=0:return false
	if absf(float(a.sample_mass)-float(b.sample_mass))>.00001 or a.day-protocol.first_sample_day!=b.day-protocol.second_sample_day:return false
	if absf(float(protocol.first_viability)-float(a.cells)/maxf(.000001,float(a.total_cells)))>.00001 or absf(float(protocol.second_viability)-float(b.cells)/maxf(.000001,float(b.total_cells)))>.00001:return false
	return true

static func valid_heat(tools:Dictionary)->bool:
	var calibration:Variant=tools.get("calibration",{})
	if not calibration is Dictionary:return false
	if not calibration.is_empty():
		if not calibration.get("day") is int or calibration.day<0 or calibration.get("cold_reference")!=0.0 or calibration.get("hot_reference")!=1.0 or calibration.get("uncertainty")!=.05:return false
	var readings:Variant=tools.get("heat_readings",[])
	if not readings is Array or readings.size()>2:return false
	var previous:=-1
	for reading:Variant in readings:
		if not reading is Dictionary or not reading.get("day") is int or reading.day<0 or not number(reading.get("observed_heat"),1):return false
		if previous>=0 and reading.day!=previous+1:return false
		if calibration.is_empty() or reading.get("calibration_day")!=calibration.day or reading.day-calibration.day>30 or reading.get("uncertainty")!=calibration.uncertainty or reading.get("fuel")!=.05 or reading.get("water")!=.2:return false
		previous=reading.day
	if int(tools.get("sterile_uses",0))>0:
		if readings.size()!=2 or float(readings[0].observed_heat)<.7 or float(readings[-1].observed_heat)-float(readings[-1].uncertainty)<.9 or int(tools.get("sterile_until",0))!=int(readings[-1].day)+1:return false
	return true

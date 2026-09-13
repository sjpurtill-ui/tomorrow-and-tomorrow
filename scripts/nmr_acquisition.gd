extends RefCounted
## Uses paid daily bench capacity; no new clock, workers, or save owner.
const WORK=4.0
static func record(sample_id:String)->Dictionary:
	return WorldSimulation.state.technology_operations.get("polymer_samples",{}).get("records",{}).get(sample_id,{})
static func start(sample_id:String)->Dictionary:
	var sample:=record(sample_id)
	if sample.is_empty() or sample.status!="unmeasured":return {"error":"Choose an unmeasured prepared sample."}
	if not sample.has("response_model"):return {"error":"This sample has no supported response model."}
	if sample.source_store!=WorldSimulation.state.resource_settlement_id:return {"error":"Sample is held in a different store."}
	var ops=load("res://scripts/technology_operations.gd")
	if ops.service("nmr_unqualified_time")<=0:return {"error":"No operating NMR bench time is available."}
	var spec:Dictionary=load("res://scripts/civilian_industry.gd").product(sample.recipe)
	var costs:Dictionary={String(spec.output):1.0,"Paper":.1,"Freshwater":.2}
	var stocks:Dictionary=WorldSimulation.state.resource_stockpiles
	for item:String in costs:
		if float(stocks.get(item,0))<float(costs[item]):return {"error":"Missing "+item+" for acquisition."}
	for item:String in costs:stocks[item]=float(stocks[item])-float(costs[item])
	# One representative specimen is retained at the bench. It cannot qualify
	# the remaining stock pool or other specimens in this preparation group.
	sample.status="acquiring"
	sample.acquisition={"work":0.0,"started_day":floori(WorldSimulation.state.elapsed_days),"specimens_reserved":1,"paused":false}
	return {"ok":true}
static func advance(sample_id:String,requested:float)->float:
	if not is_finite(requested) or requested<=0:return 0.0
	var sample:=record(sample_id)
	if sample.is_empty() or sample.status!="acquiring" or bool(sample.acquisition.paused):return 0.0
	if sample.source_store!=WorldSimulation.state.resource_settlement_id:return 0.0
	var ops=load("res://scripts/technology_operations.gd")
	var used:float=ops.consume_service("nmr_unqualified_time",minf(requested,WORK-float(sample.acquisition.work)))
	sample.acquisition.work=float(sample.acquisition.work)+used
	if float(sample.acquisition.work)>=WORK:
		sample.observation=observe(sample)
		sample.status="measured_unqualified"
	return used
static func valid(sample:Dictionary)->bool:
	if sample.status=="unmeasured":return not sample.has("acquisition")
	if not sample.has("response_model"):return false
	if sample.status not in ["acquiring","measured_unqualified"] or not sample.get("acquisition") is Dictionary:return false
	var acquisition:Dictionary=sample.acquisition
	if not acquisition.has_all(["work","started_day","specimens_reserved","paused"]):return false
	if not acquisition.work is float and not acquisition.work is int:return false
	if not is_finite(float(acquisition.work)) or float(acquisition.work)<0 or float(acquisition.work)>WORK:return false
	if not acquisition.started_day is int and not acquisition.started_day is float:return false
	if not is_finite(float(acquisition.started_day)) or float(acquisition.started_day)<float(sample.prepared_day) or float(acquisition.started_day)!=floorf(float(acquisition.started_day)):return false
	if acquisition.specimens_reserved!=1 or not acquisition.paused is bool:return false
	if sample.status=="measured_unqualified":
		if not sample.get("observation") is Dictionary:return false
		var observed:Dictionary=sample.observation
		if observed.get("sample_id")!=sample.sample_id or observed.get("qualified",true)!=false or not observed.get("trace") is Array or observed.trace.size()!=401:return false
		for point:Variant in observed.trace:
			if not (point is int or point is float) or not is_finite(float(point)) or absf(float(point))>10000:return false
	return (float(acquisition.work)<WORK) if sample.status=="acquiring" else (float(acquisition.work)==WORK)

static func observe(sample:Dictionary)->Dictionary:
	# Explicit game sample variability, not a known spectrum inferred from an
	# inventory label. Only this retained representative specimen is observed.
	var rng:=RandomNumberGenerator.new();rng.seed=int(sample.response_model.seed)
	var mixed:=rng.randf_range(.04,.35)
	var ethene:=rng.randf_range(.01,.12)
	var resonances:Array=[{"position":20.0,"amplitude":1.0-mixed-ethene,"intrinsic_width":.1},{"position":25.0,"amplitude":mixed,"intrinsic_width":.1},{"position":30.0,"amplitude":ethene,"intrinsic_width":.1}]
	# Unqualified hardware deliberately retains broadening/drift. Paid scans
	# supply a raw trace; reference qualification must later establish limits.
	var instrument:Dictionary={"linewidth":2.0,"noise":.1,"gain":1.0,"shift_error":.2,"temperature_drift":.6}
	var response:Dictionary=load("res://scripts/nmr_signal_model.gd").acquire(resonances,instrument,16,int(sample.response_model.seed))
	response["sample_id"]=sample.sample_id;response["qualified"]=false
	response["model"]="Synthetic bounded copolymer response; unqualified instrument."
	return response

static func advance_pending()->void:
	var records:Dictionary=WorldSimulation.state.technology_operations.get("polymer_samples",{}).get("records",{})
	var calibration=load("res://scripts/nmr_calibration.gd")
	if not records.is_empty():calibration.start()
	calibration.advance()
	for sample_id:String in records:
		if records[sample_id].status=="unmeasured":start(sample_id)
		advance(sample_id,WORK)

static func report(sample_id:String)->Dictionary:
	var sample:=record(sample_id)
	if sample.is_empty():return {"status":"unavailable","message":"Sample is unavailable."}
	if sample.status=="unmeasured":return {"status":"unmeasured","message":"Prepared; awaiting supported bench time and supplies."}
	if sample.status=="acquiring":return {"status":"acquiring","message":"Acquiring: %.1f / %.1f instrument-time units." % [float(sample.acquisition.work),WORK]}
	var interpretation:Dictionary=load("res://scripts/nmr_trace_analysis.gd").analyze(sample.observation,sample.observation.get("reference",{}))
	return {"status":"measured_unqualified","message":"Unqualified: "+String(interpretation.get("reason","Reference qualification remains required.")),"interpretation":interpretation}
static func report_text()->String:
	var records:Dictionary=WorldSimulation.state.technology_operations.get("polymer_samples",{}).get("records",{})
	if records.is_empty():return "No prepared specimens. Prepare a sealed specimen through workshop production."
	var lines:PackedStringArray=[]
	var ids:Array=records.keys()
	for index:int in range(maxi(0,ids.size()-6),ids.size()):
		var id:=String(ids[index]);lines.append("Sample "+id+": "+String(report(id).message))
	return "\n".join(lines)

extends RefCounted
## Uses paid daily bench capacity; no new clock, workers, or save owner.
const WORK=4.0
## Structural dependency declarations for conditional retained-specimen releases.
## These are analytical operations, not workshop recipes or guaranteed grades.
static func dependency_routes()->Dictionary:
	var routes:Dictionary={}
	for recipe:String in ["sealed_copolymer_specimens","traceable_peg_batch","traceable_pp_batch"]:
		var peg:=recipe=="traceable_peg_batch";var pp:=recipe=="traceable_pp_batch"
		var source:Dictionary=load("res://scripts/civilian_industry.gd").product(recipe)
		var materials:Dictionary={String(source.output):1.0,"NMR Methanol References":1.0,"Paper":.1,"Freshwater":.7 if peg else .2}
		if not peg:materials["Toluene"]=.5
		routes["analysis_"+recipe]={"gate":"nuclear_magnetic_resonance_spectroscopy","requires":["polymer_solution_processing"],"output":"Size-Characterized PEG Batches" if peg else ("Tacticity-Characterized PP Batches" if pp else "Sequence-Characterized Copolymer Specimens"),"materials":materials,"tooling":{},"days":14.0 if peg or pp else 12.0,"power":0.0,"services":{"nmr_unqualified_time":14.0 if peg or pp else 12.0},"conditional":true}
	return routes
static func record(sample_id:String)->Dictionary:
	return WorldSimulation.state.technology_operations.get("polymer_samples",{}).get("records",{}).get(sample_id,{})
static func supported(sample:Dictionary)->bool:
	return sample.get("response_model",{}).get("kind")in ["synthetic_copolymer_v1","synthetic_linear_peg_v1","synthetic_pp_triads_v1"]
static func required_work(sample:Dictionary)->float:
	return 6.0 if sample.get("recipe") in ["traceable_peg_batch","traceable_pp_batch"] else WORK
static func start(sample_id:String)->Dictionary:
	var sample:=record(sample_id)
	if sample.is_empty() or sample.status!="unmeasured":return {"error":"Choose an unmeasured prepared sample."}
	if not supported(sample):return {"error":"This sample has no supported acquisition method."}
	if sample.source_store!=WorldSimulation.state.resource_settlement_id:return {"error":"Sample is held in a different store."}
	var ops=load("res://scripts/technology_operations.gd")
	if ops.service("nmr_unqualified_time")<=0:return {"error":"No operating NMR bench time is available."}
	var spec:Dictionary=load("res://scripts/civilian_industry.gd").product(sample.recipe)
	var costs:Dictionary={String(spec.output):1.0,"Paper":.1,"Freshwater":.2}
	var calibration=load("res://scripts/nmr_calibration.gd")
	var conditioned:bool=calibration.usable() and WorldSimulation.discovery.adoption("polymer_solution_processing")>=.1
	if sample.recipe in ["traceable_peg_batch","traceable_pp_batch"] and not conditioned:return {"error":"Quantitative polymer acquisition requires the calibrated solution method."}
	if conditioned:
		if sample.recipe=="traceable_peg_batch":costs["Freshwater"]+=.5
		else:costs["Toluene"]=.5
	var stocks:Dictionary=WorldSimulation.state.resource_stockpiles
	for item:String in costs:
		if float(stocks.get(item,0))<float(costs[item]):return {"error":"Missing "+item+" for acquisition."}
	for item:String in costs:stocks[item]=float(stocks[item])-float(costs[item])
	# One representative specimen is retained at the bench. It cannot qualify
	# the remaining stock pool or other specimens in this preparation group.
	sample.status="acquiring"
	sample.acquisition={"work":0.0,"started_day":floori(WorldSimulation.state.elapsed_days),"specimens_reserved":1,"paused":false}
	if conditioned:sample.acquisition["reference"]=calibration.snapshot()
	return {"ok":true}
static func advance(sample_id:String,requested:float)->float:
	if not is_finite(requested) or requested<=0:return 0.0
	var sample:=record(sample_id)
	if sample.is_empty() or sample.status!="acquiring" or bool(sample.acquisition.paused):return 0.0
	if sample.source_store!=WorldSimulation.state.resource_settlement_id:return 0.0
	var ops=load("res://scripts/technology_operations.gd")
	var requested_work:=minf(requested,required_work(sample)-float(sample.acquisition.work))
	var used:=0.0
	if sample.acquisition.has("reference"):
		var calibration=load("res://scripts/nmr_calibration.gd")
		used=calibration.consume(requested_work)
		if used>0 and sample.acquisition.reference.checked_day!=calibration.data().checked_day:
			sample.acquisition["discarded_work"]=float(sample.acquisition.get("discarded_work",0))+float(sample.acquisition.work)
			sample.acquisition.work=0.0
			sample.acquisition.reference=calibration.snapshot()
	else:used=ops.consume_service("nmr_unqualified_time",requested_work)
	sample.acquisition.work=float(sample.acquisition.work)+used
	if float(sample.acquisition.work)>=required_work(sample):
		sample.observation=observe(sample)
		sample.status="measurement_failed" if sample.observation.has("error") else "measured_unqualified"
	if sample.status=="measured_unqualified":release_characterized_specimen(sample)
	return used
static func valid(sample:Dictionary)->bool:
	if sample.has("specimen_released") and (not sample.specimen_released is bool or sample.status!="measured_unqualified"):return false
	if sample.status=="unmeasured":return not sample.has("acquisition")
	if not sample.has("response_model"):return false
	if sample.status not in ["acquiring","measured_unqualified","measurement_failed"] or not sample.get("acquisition") is Dictionary:return false
	var acquisition:Dictionary=sample.acquisition
	if not acquisition.has_all(["work","started_day","specimens_reserved","paused"]):return false
	if not acquisition.work is float and not acquisition.work is int:return false
	if not is_finite(float(acquisition.work)) or float(acquisition.work)<0 or float(acquisition.work)>required_work(sample):return false
	if not acquisition.started_day is int and not acquisition.started_day is float:return false
	if not is_finite(float(acquisition.started_day)) or float(acquisition.started_day)<float(sample.prepared_day) or float(acquisition.started_day)!=floorf(float(acquisition.started_day)):return false
	if acquisition.has("discarded_work") and (not (acquisition.discarded_work is int or acquisition.discarded_work is float) or not is_finite(float(acquisition.discarded_work)) or float(acquisition.discarded_work)<0):return false
	if acquisition.has("reference"):
		if not acquisition.reference is Dictionary or not acquisition.reference.has_all(["checked_day","shift_error","temperature_drift"]):return false
		for key:String in ["checked_day","shift_error","temperature_drift"]:
			var value:Variant=acquisition.reference[key]
			if not (value is int or value is float) or not is_finite(float(value)):return false
		if float(acquisition.reference.checked_day)<0 or float(acquisition.reference.checked_day)!=floorf(float(acquisition.reference.checked_day)) or absf(float(acquisition.reference.shift_error))>.05 or absf(float(acquisition.reference.temperature_drift))>.5:return false
	if acquisition.specimens_reserved!=1 or not acquisition.paused is bool:return false
	if sample.status=="measurement_failed":return float(acquisition.work)==required_work(sample) and sample.get("observation") is Dictionary and sample.observation.get("error") is String
	if sample.status=="measured_unqualified":
		if not sample.get("observation") is Dictionary:return false
		var observed:Dictionary=sample.observation
		if observed.get("sample_id")!=sample.sample_id or observed.get("qualified",true)!=false or not observed.get("trace") is Array or observed.trace.size()!=401:return false
		var evidence=load("res://scripts/polymer_spectral_evidence.gd")
		for key:String in ["step","origin","noise_estimate"]:
			if not evidence.finite_number(observed.get(key)):return false
		if float(observed.step)!=.1 or float(observed.origin)!=0.0 or float(observed.noise_estimate)<=0:return false
		if sample.recipe=="traceable_peg_batch" and not observed.get("peg_observation") is Dictionary:return false
		for point:Variant in observed.trace:
			if not (point is int or point is float) or not is_finite(float(point)) or absf(float(point))>10000:return false
		if observed.get("reference",{})!=acquisition.get("reference",{}):return false
		if sample.recipe=="traceable_pp_batch" and bool(sample.get("specimen_released",false)):
			var pp:Dictionary=load("res://scripts/nmr_pp_acquisition.gd").evaluate(observed,sample.sample_id,sample.source_store)
			if not pp.resolved or float(pp.mm_lower)<.85:return false
		if sample.recipe=="traceable_peg_batch" and bool(sample.get("specimen_released",false)):
			var peg:Dictionary=load("res://scripts/polymer_peg_endgroup_assay.gd").evaluate(observed.get("peg_observation",{}),sample.sample_id,sample.source_store)
			if not peg.accepted or float(peg.mean_dp_lower)<10 or float(peg.mean_dp_upper)>80:return false
	return (float(acquisition.work)<required_work(sample)) if sample.status=="acquiring" else (float(acquisition.work)==required_work(sample))

static func observe(sample:Dictionary)->Dictionary:
	if sample.recipe=="traceable_pp_batch":return load("res://scripts/nmr_pp_acquisition.gd").acquire(sample,load("res://scripts/nmr_calibration.gd").profile(),sample.acquisition.get("reference",{}))
	if sample.recipe=="traceable_peg_batch":return load("res://scripts/nmr_peg_acquisition.gd").acquire(sample,load("res://scripts/nmr_calibration.gd").profile(),sample.acquisition.get("reference",{}))
	# Explicit game sample variability, not a known spectrum inferred from an
	# inventory label. Only this retained representative specimen is observed.
	var rng:=RandomNumberGenerator.new();rng.seed=int(sample.response_model.seed)
	var mixed:=rng.randf_range(.04,.35)
	var ethene:=rng.randf_range(.01,.12)
	var resonances:Array=[{"position":20.0,"amplitude":1.0-mixed-ethene,"intrinsic_width":.1},{"position":25.0,"amplitude":mixed,"intrinsic_width":.1},{"position":30.0,"amplitude":ethene,"intrinsic_width":.1}]
	# Unqualified hardware deliberately retains broadening/drift. Paid scans
	# supply a raw trace; reference qualification must later establish limits.
	var instrument:Dictionary={"linewidth":2.0,"noise":.1,"gain":1.0,"shift_error":.2,"temperature_drift":.6}
	if sample.acquisition.has("reference"):instrument=load("res://scripts/nmr_calibration.gd").profile()
	var response:Dictionary=load("res://scripts/nmr_signal_model.gd").acquire(resonances,instrument,16,int(sample.response_model.seed))
	response["sample_id"]=sample.sample_id;response["qualified"]=false
	response["model"]="Synthetic bounded copolymer response."
	if sample.acquisition.has("reference"):response["reference"]=sample.acquisition.reference.duplicate(true)
	return response

static func advance_pending()->void:
	var records:Dictionary=WorldSimulation.state.technology_operations.get("polymer_samples",{}).get("records",{})
	var calibration=load("res://scripts/nmr_calibration.gd")
	var pending:=false
	for sample:Dictionary in records.values():
		if sample.status in ["unmeasured","acquiring"] and supported(sample):pending=true
	if pending:calibration.start()
	calibration.advance()
	for sample_id:String in records:
		if not supported(records[sample_id]):continue
		if records[sample_id].status=="unmeasured" and calibration.usable() and WorldSimulation.discovery.adoption("polymer_solution_processing")>=.1:start(sample_id)
		advance(sample_id,required_work(records[sample_id]))
	if not records.is_empty():load("res://scripts/polymer_samples.gd").retire_completed()

static func report(sample_id:String)->Dictionary:
	var sample:=record(sample_id)
	if sample.is_empty():return {"status":"unavailable","message":"Sample is unavailable."}
	if sample.get("recipe")=="sec_traceable_peg_batch":return preload("res://scripts/sec_acquisition.gd").report(sample)
	if sample.status=="unmeasured":return {"status":"unmeasured","message":"Prepared; awaiting a calibrated method, bench time and supplies."}
	if sample.status=="acquiring":return {"status":"acquiring","message":"Acquiring: %.1f / %.1f instrument-time units." % [float(sample.acquisition.work),required_work(sample)]}
	if sample.status=="measurement_failed":return {"status":"measurement_failed","message":String(sample.observation.error)}
	if sample.recipe=="traceable_pp_batch":
		var pp:Dictionary=load("res://scripts/nmr_pp_acquisition.gd").evaluate(sample.observation,sample.sample_id,sample.source_store)
		return {"status":"resolved" if pp.resolved else "measured_unqualified","message":("Retained PP mm triads %.1f%%; full stereosequence unmeasured." % (100*float(pp.observed_triad_fractions.mm))) if pp.resolved else String(pp.reason),"interpretation":pp}
	if sample.recipe=="traceable_peg_batch":
		var result:Dictionary=load("res://scripts/polymer_peg_endgroup_assay.gd").evaluate(sample.observation.get("peg_observation",{}),sample.sample_id,sample.source_store)
		return {"status":"resolved" if result.accepted else "measured_unqualified","message":("Retained PEG mean repeat count %.1f (%.1f–%.1f); distribution unmeasured." % [result.mean_dp,result.mean_dp_lower,result.mean_dp_upper]) if result.accepted else String(result.reason),"interpretation":result}
	var interpretation:Dictionary=load("res://scripts/nmr_trace_analysis.gd").analyze(sample.observation,sample.observation.get("reference",{}))
	if bool(interpretation.get("resolved",false)):return {"status":"resolved","message":"Selected dyads resolved for this retained specimen; no stock-pool qualification.","interpretation":interpretation}
	return {"status":"measured_unqualified","message":"Unqualified: "+String(interpretation.get("reason","Reference qualification remains required.")),"interpretation":interpretation}
static func report_text()->String:
	var records:Dictionary=WorldSimulation.state.technology_operations.get("polymer_samples",{}).get("records",{})
	if records.is_empty():return "No prepared specimens. Prepare a sealed specimen through workshop production."
	var lines:PackedStringArray=[]
	var ids:Array=records.keys()
	for index:int in range(maxi(0,ids.size()-6),ids.size()):
		var id:=String(ids[index]);lines.append("Sample "+id+": "+String(report(id).message))
	return "\n".join(lines)

static func release_characterized_specimen(sample:Dictionary)->void:
	# Only the representative physically reserved at acquisition can be released.
	# One specimen contained 0.1 source-material units; a microbatch is not a
	# bulk resin unit. Drying and molding remain separate paid workshop jobs.
	if sample.recipe=="traceable_pp_batch":
		var pp:Dictionary=load("res://scripts/nmr_pp_acquisition.gd").evaluate(sample.observation,sample.sample_id,sample.source_store)
		if not pp.resolved or float(pp.mm_lower)<.85 or bool(sample.get("specimen_released",false)):return
		WorldSimulation.state.resource_stockpiles["Tacticity-Characterized PP Batches"]=float(WorldSimulation.state.resource_stockpiles.get("Tacticity-Characterized PP Batches",0))+1.0
		sample.specimen_released=true
		return
	if sample.recipe=="traceable_peg_batch":
		var peg:Dictionary=load("res://scripts/polymer_peg_endgroup_assay.gd").evaluate(sample.observation.get("peg_observation",{}),sample.sample_id,sample.source_store)
		if not peg.accepted or float(peg.mean_dp_lower)<10 or float(peg.mean_dp_upper)>80 or bool(sample.get("specimen_released",false)):return
		WorldSimulation.state.resource_stockpiles["Size-Characterized PEG Batches"]=float(WorldSimulation.state.resource_stockpiles.get("Size-Characterized PEG Batches",0))+1.0
		sample.specimen_released=true
		return
	var result:Dictionary=load("res://scripts/nmr_trace_analysis.gd").analyze(sample.observation,sample.observation.get("reference",{}))
	if not bool(result.get("resolved",false)):return
	var fractions:Dictionary=result.observed_dyad_fractions
	if float(fractions.PE)<.04 or float(fractions.PE)>.3 or float(fractions.EE)>.12:return
	if bool(sample.get("specimen_released",false)):return
	var stocks:Dictionary=WorldSimulation.state.resource_stockpiles
	stocks["Sequence-Characterized Copolymer Specimens"]=float(stocks.get("Sequence-Characterized Copolymer Specimens",0))+1.0
	sample.specimen_released=true

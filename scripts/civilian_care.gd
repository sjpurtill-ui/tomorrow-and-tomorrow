extends RefCounted
const F=preload("res://scripts/civilian_care_fabric.gd")
const IDS={"rounds":"clinical_observation_rounds","pulse":"clinical_pulse_assessment","nursing":"nursing_care_organization"}
static func data()->Dictionary:return WorldSimulation.state.civilian_care
static func methods(state:Node)->Dictionary:
	var result:Dictionary={}
	for key:String in IDS:
		var id:String=IDS[key]
		result[key]=id in state.known_discoveries and float(state.discovery_adoption.get(id,0))>=.25
	return result
static func available(state:Node)->bool:
	if not state.settlement_site_committed or state.convoy_traveling:return false
	if not state.resource_settlement_id.is_empty():
		var city:=WorldSimulation.settlements.settlement_record(state.resource_settlement_id)
		return not city.is_empty() and String(city.get("occupied_by","")).is_empty()
	for city:Dictionary in state.player_settlements:
		if bool(city.get("primary",false)):return String(city.get("occupied_by","")).is_empty()
	return false
static func reserved(state:Node,capacity:float)->float:
	if not available(state) or not bool(state.civilian_care.enabled) or not bool(methods(state).rounds):return 0.0
	# Standing duty is reserved before either daily system runs. It does not vanish
	# when an observation consumes the last clay or a patient finishes care.
	return maxf(0,capacity)*clampf(float(state.civilian_care.staff_share),0,.75)
static func staff()->float:
	var state=WorldSimulation.state
	return reserved(state,state.effective_workers("Knowledge",false,true))
static func process_day(pressure:float)->Dictionary:
	var state=WorldSimulation.state
	var day:=int(state.elapsed_days)
	if int(data().last_day)>=day:return data().report
	var population:=maxf(0,float(state.population_exact))
	F.fit_population(data(),population)
	# This is a generic care-need model, not a disease diagnosis. Baseline resolution
	# does not grant a second population-health or mortality reward.
	var gap:=maxi(1,day-int(data().last_day)) if int(data().last_day)>=0 else 1
	for episode:Dictionary in data().episodes:
		episode.remaining=float(episode.remaining)*exp(-.025*gap)
		episode.observed=minf(float(episode.observed),float(episode.remaining))
		episode.cared=minf(float(episode.cared),float(episode.remaining))
	var burden:=clampf(pressure,0,1)
	F.admit(data(),population,population*burden*.006*WorldSimulation.span,burden,day)
	var supported:=available(state)
	var roster:=staff() if supported else 0.0
	var known:=methods(state) if supported else {}
	var report:=F.serve(data(),state.resource_stockpiles,roster,known,day)
	report.waiting=F.outstanding(data())
	report.health_relief=clampf(float(report.additional_recovery)/maxf(1,population)*2.0,0,.025)
	report.blocker="" if supported else "Settled, accessible local care is unavailable."
	if supported and roster<=0:report.blocker="No adopted observation method or staffed care duty."
	elif supported and float(report.unmet)>.001:
		report.blocker="Care demand exceeds current staff, observation or local supplies."
	if not data().history.is_empty():data().history[-1]=report.duplicate(true)
	return report
static func set_share(value:float)->void:
	if is_finite(value):data().staff_share=clampf(value,0,.75)
static func targets()->Dictionary:
	if not available(WorldSimulation.state) or not bool(methods(WorldSimulation.state).rounds):return {}
	var people:=minf(maxf(1,F.outstanding(data())),staff()*2)
	# Care cloth is held as raw materials and Civilian Goods so trade can move it.
	return preload("res://scripts/bill_stock.gd").add_scaled({"Clay":people*F.RECORD_CLAY*14},F.CLOTH_UNIT,people*14)
static func describe()->String:
	var report:Dictionary=data().report
	var continuing:=0.0
	for episode:Dictionary in data().episodes:
		if int(episode.care_day)==int(WorldSimulation.state.elapsed_days) and int(episode.prior_observation_day)>=0 and int(episode.prior_observation_day)==int(WorldSimulation.state.elapsed_days)-1:continuing+=float(episode.cared)
	return "Care duty: %.2f Knowledge workers (%.0f%% of available local Knowledge labor).\nObserved today: %.2f · supported: %.2f · waiting: %.2f population equivalents.\nSupplies spent: %.3f clay, %.2f water, %.3f cloth.\nContinuing care: %.2f · additional recovery: %.3f population equivalents.\n%s" % [staff(),float(data().staff_share)*100,float(report.get("observed",0)),float(report.get("supported",0)),F.outstanding(data()),float(report.get("record_clay_used",0)),float(report.get("water_used",0)),float(report.get("cloth_used",0)),continuing,float(report.get("additional_recovery",0)),String(report.get("blocker","No daily care record yet."))]

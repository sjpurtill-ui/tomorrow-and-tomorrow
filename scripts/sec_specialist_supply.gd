extends RefCounted
## Declared finite preexisting external-laboratory archive, not local synthesis.
## One grant per eligible external actor; existing stores and embassy own transfer.
const SUBJECT="size_exclusion_chromatography"
const ORIGIN="external_peg_laboratory_archive_v1"
const FOUNDATIONS=["polymer_solution_processing","glass_tube_drawing","optical_lenses","experimental_controls","measurement_uncertainty","public_schools","nuclear_magnetic_resonance_spectroscopy"]
const CONSIGNMENT={"Qualified Aqueous SEC Packing":1.0,"Narrow PEG DP10 Standards":1.0,"Narrow PEG DP40 Standards":1.0,"Narrow PEG DP160 Standards":1.0}
const RESERVE={"Qualified Aqueous SEC Packing":20.0,"Narrow PEG DP10 Standards":24.0,"Narrow PEG DP40 Standards":24.0,"Narrow PEG DP160 Standards":24.0}
static func advance(day:int)->void:
	var state=WorldSimulation.state
	if WorldSimulation.actor_id in ["player","human",""] or not state.settlement_site_committed or state.convoy_traveling:return
	if state.society_exchange.has("sec_specialist_archive"):return
	for id:String in FOUNDATIONS:
		if id not in state.known_discoveries or float(state.discovery_adoption.get(id,0))<.1:return
	if state.effective_workers("Knowledge")<5 or state.effective_workers("Logistics")<1:return
	state.society_exchange["sec_specialist_archive"]={"origin":ORIGIN,"actor":WorldSimulation.actor_id,"endowed_day":day}
	for item:String in RESERVE:state.resource_stockpiles[item]=float(state.resource_stockpiles.get(item,0))+float(RESERVE[item])
	state.society_exchange.history.append({"day":day,"text":"A finite preexisting PEG laboratory archive is available for paid external consignments. Packing and assigned narrow references are imported expertise; this settlement does not synthesize replacements."})
	while state.society_exchange.history.size()>64:state.society_exchange.history.pop_front()
static func valid(value:Variant)->bool:
	if not value is Dictionary:return false
	if value.is_empty():return true
	return value.size()==3 and value.get("origin")==ORIGIN and value.get("actor") is String and value.actor not in ["","player","human"] and (value.get("endowed_day") is int or value.get("endowed_day") is float) and is_finite(float(value.endowed_day)) and float(value.endowed_day)>=0 and float(value.endowed_day)==floorf(float(value.endowed_day))

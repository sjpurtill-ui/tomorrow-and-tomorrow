extends VBoxContainer
const Lab=preload("res://scripts/microscopy_lab.gd")
const Samples=preload("res://scripts/microscopy_samples.gd")
var subject:=""
var details:Label
var toggle:Button
var elapsed:=0.0
static func supports(id:String)->bool:
	for entry:Dictionary in preload("res://scripts/microscopy_knowledge.gd").entries():
		if entry.id==id:return true
	return false
func _ready()->void:
	details=Label.new();details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(details)
	toggle=Button.new();toggle.custom_minimum_size.y=34;add_child(toggle)
	toggle.pressed.connect(func()->void:
		WorldSimulation.state.microscopy.enabled=not bool(WorldSimulation.state.microscopy.enabled)
		refresh())
	refresh()
func _process(delta:float)->void:
	elapsed+=delta
	if elapsed>=1:elapsed=0;refresh()
func refresh()->void:
	if not is_instance_valid(details):return
	var state=WorldSimulation.state
	var ledger:Dictionary=state.microscopy
	var day:=int(state.elapsed_days)
	var workers:=Lab.reserved(state,state.effective_workers("Knowledge",false,false,false,true))
	var lines:Array[String]=["Local microscopy · %s · %.2f Knowledge workers reserved after absences and clinical care."%["operating" if Lab.available(state) else "paused or unavailable",workers],"%.2f stored work · %d/%d specimens · %d retained records."%[float(ledger.work_bank),ledger.specimens.size(),Samples.LIMIT,ledger.records.size()]]
	if not bool(ledger.tools.get("bench",false)):
		lines.append("Bench awaiting 1 Compound Microscope, 1 Laboratory Glassware, 0.2 Specimen Slides and 0.5 stored work. These must be supplied before observations begin.")
	else:lines.append("Microscope bench installed. Samples, media, blank controls, preparation and records consume supplies and work; analyzed material never returns to food.")
	var repeats:=0
	for protocol:Dictionary in ledger.protocols:
		if bool(protocol.repeatable):repeats+=1
	lines.append("%d repeatable published procedures; %d failed comparisons retained."%[repeats,ledger.protocols.size()-repeats])
	lines.append("Instrument treatment: %d available uses%s."%[int(ledger.tools.get("sterile_uses",0)) if day<=int(ledger.tools.get("sterile_until",-1)) else 0," through day %d"%int(ledger.tools.sterile_until) if ledger.tools.has("sterile_until") else ""])
	for sample:Dictionary in ledger.specimens:
		var evidence:="no retained observation"
		if not sample.history.is_empty():
			var frame:Dictionary=sample.history[-1]
			evidence="observed day %d, %.2f visible cells, contrast %.2f"%[int(frame.day),float(frame.cells),float(frame.contrast)]
		lines.append("Sample %d · %s source %d · %s."%[int(sample.id),String(sample.kind),int(sample.source),evidence])
	var rejected:=0
	for lot:Dictionary in state.food_batches.lots:
		if lot.kind=="starter" and not Lab.starter_usable(lot,day):rejected+=1
	lines.append("%d starter lots withheld by current observations. Unobserved or expired evidence does not certify a source; no pathogen identity is inferred."%rejected)
	details.text="\n".join(lines)
	toggle.text="Pause local microscopy" if bool(ledger.enabled) else "Resume local microscopy"

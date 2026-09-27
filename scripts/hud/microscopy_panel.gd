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
	var Plain:=preload("res://scripts/hud/production_plain.gd")
	var Era:=preload("res://scripts/hud/era_words.gd")
	var lines:Array[String]=["The microscope is %s. About %s lore keepers are set aside for it, after those who are away or caring for the sick."%["in use" if Lab.available(state) else "not in use",Plain.number(workers)],"%s days of looking saved up; %d of %d sample places filled; %d records kept."%[Plain.number(float(ledger.work_bank)),ledger.specimens.size(),Samples.LIMIT,ledger.records.size()]]
	if not bool(ledger.tools.get("bench",false)):
		if Lab.BENCH_GATE not in state.known_discoveries:lines.append("Bench awaiting the compound microscope: it cannot be put together until our people know how.")
		else:
			var missing:Array[String]=[]
			var shortfall:Dictionary=Lab.bench_shortfall()
			for item:String in shortfall:missing.append("%s %s"%[Plain.number(float(shortfall[item])),item.to_lower()])
			lines.append("Setting up the bench takes goods and materials for the microscope, glass and slides, and half a day of saved-up looking."+(" Still missing: "+", ".join(missing)+"." if not missing.is_empty() else ""))
	else:lines.append("The microscope bench is set up. Each sample, and the records kept of it, uses supplies and time; nothing looked at goes back into the food.")
	var repeats:=0
	for protocol:Dictionary in ledger.protocols:
		if bool(protocol.repeatable):repeats+=1
	lines.append("%d ways of working that others can repeat; %d attempts that did not hold up, kept on record."%[repeats,ledger.protocols.size()-repeats])
	var clean_uses:=int(ledger.tools.get("sterile_uses",0)) if day<=int(ledger.tools.get("sterile_until",-1)) else 0
	lines.append("Cleaned tools: enough for %d more uses%s."%[clean_uses," until "+Era.when(int(ledger.tools.sterile_until)) if ledger.tools.has("sterile_until") and clean_uses>0 else ""])
	for sample:Dictionary in ledger.specimens:
		var evidence:="not looked at yet"
		if not sample.history.is_empty():
			var frame:Dictionary=sample.history[-1]
			var cells:=float(frame.cells)
			evidence="last looked at %s: %s living cell%s seen, %s"%[Era.ago(int(frame.day)),Plain.number(cells),"" if is_equal_approx(cells,1.0) else "s","clear to read" if float(frame.contrast)>=0.5 else "hard to read"]
		lines.append("Sample %d (%s, from source %d): %s."%[int(sample.id),String(sample.kind).replace("_"," "),int(sample.source),evidence])
	var rejected:=0
	for lot:Dictionary in state.food_batches.lots:
		if lot.kind=="starter" and not Lab.starter_usable(lot,day):rejected+=1
	lines.append("%d starter batches held back by what was seen. A sample not looked at lately proves nothing, and looking cannot tell what illness a sample carries."%rejected)
	details.text="\n".join(lines)
	toggle.text="Stop using the microscope" if bool(ledger.enabled) else "Start using the microscope again"

extends VBoxContainer
const B=preload("res://scripts/food_batches.gd")
const K=preload("res://scripts/food_batch_knowledge.gd")
var subject:=""
var details:Label
var install_button:Button
var elapsed:=0.0
func _ready()->void:
	if not K.METHODS.has(subject):return
	details=Label.new();details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(details)
	install_button=Button.new();install_button.text="Install food equipment";install_button.custom_minimum_size.y=34;add_child(install_button)
	install_button.pressed.connect(func()->void:
		var result:=B.install(subject);install_button.tooltip_text=String(result.get("message",result.get("error","")));refresh())
	refresh()
func _process(delta:float)->void:
	elapsed+=delta
	if elapsed>=1:elapsed=0;refresh()
func refresh()->void:
	if not is_instance_valid(details):return
	var ledger:=B.data();var spec:Dictionary=K.METHODS[subject]
	var lines:Array[String]=["%d installed · %.0f rations per handler-day. Shares remaining Logistics workers with grain handling and preservation."%[int(ledger.tools.get(subject,0)),float(spec.rate)],"Available: %.1f rations · in process: %.1f · loss today: %.2f."%[B.available_total(),B.in_process(),float(ledger.report.get("loss",0))]]
	var shown:=0
	for lot:Dictionary in ledger.lots:
		var observations:Array[String]=[]
		for pair:Array in [["trace","tracked"],["loss","loss measured"],["humidity","humidity measured"],["acidity","acidity measured"],["activity","water activity measured"],["review","handling reviewed"],["barrier","barrier tested"]]:
			if lot.observations.has(pair[0]):observations.append(pair[1])
		if lot.observations.has("leak"):observations.append("leak check day %d: %s"%[int(lot.observations.leak),"passed" if bool(lot.observations.get("leak_pass",false)) else "failed"])
		lines.append("Lot %d · %s · %.2f rations · ready day %d%s"%[int(lot.id),String(lot.kind).capitalize(),float(lot.amount),int(lot.ready)," · "+", ".join(observations) if not observations.is_empty() else ""])
		shown+=1
		if shown>=6:break
	lines.append("Assays consume samples from the examined lot. Packaging protection requires a current passing leak check; it expires after three days.")
	details.text="\n".join(lines)
	var quote:=B.quote(subject);install_button.disabled=quote.has("error");install_button.tooltip_text=String(quote.get("message",quote.get("error","")))

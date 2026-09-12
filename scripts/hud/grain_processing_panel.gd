extends VBoxContainer
const Grain=preload("res://scripts/grain_processing.gd")
var subject:=""
var details:Label
var install_button:Button
var elapsed:=0.0
func _ready()->void:
	if Grain.definition(subject).is_empty():return
	details=Label.new();details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(details)
	install_button=Button.new();install_button.text="Install handling equipment";install_button.clip_text=true;install_button.custom_minimum_size.y=34;add_child(install_button)
	install_button.pressed.connect(func()->void:
		var result:=Grain.install(subject);install_button.tooltip_text=String(result.get("message",result.get("error","")));refresh())
	refresh()
func _process(delta:float)->void:
	elapsed+=delta
	if elapsed>=1:elapsed=0;refresh()
func refresh()->void:
	if not is_instance_valid(details):return
	var ledger:=Grain.data();var spec:=Grain.definition(subject)
	details.text="%d installed · up to %.0f rations per handler-day. Handlers share Logistics time with cooking and preservation.\nGrain and fractions in stores: %.1f rations; germinating: %.1f. Processing loss today: %.2f rations.\nThe steward installs one affordable setup at a time when its input is available and a week's food remains." % [int(ledger.tools.get(subject,0)),float(spec.rate),Grain.available_total(),Grain.in_process(),float(ledger.report.get("loss",0))]
	var quote:=Grain.quote(subject);install_button.disabled=quote.has("error")
	install_button.tooltip_text=String(quote.get("message",quote.get("error","")))

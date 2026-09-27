extends VBoxContainer
const Grain=preload("res://scripts/grain_processing.gd")
var subject:=""
var details:Label
var install_button:Button
var elapsed:=0.0
func _ready()->void:
	if Grain.definition(subject).is_empty():return
	details=Label.new();details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(details)
	install_button=Button.new();install_button.text="Set up the tools for this";install_button.clip_text=true;install_button.custom_minimum_size.y=34;add_child(install_button)
	install_button.pressed.connect(func()->void:
		var result:=Grain.install(subject);install_button.tooltip_text=String(result.get("message",result.get("error","")));refresh())
	refresh()
func _process(delta:float)->void:
	elapsed+=delta
	if elapsed>=1:elapsed=0;refresh()
func refresh()->void:
	if not is_instance_valid(details):return
	var ledger:=Grain.data();var spec:=Grain.definition(subject)
	var Plain:=preload("res://scripts/hud/production_plain.gd")
	details.text="%d set%s up. Each lets one carrier handle about %s rations a day; carriers share this with cooking and keeping food.
In store: %s rations of grain; %s rations still sprouting. Lost in the work today: %s rations.
The steward sets up one more at a time, when there is grain to work and a week's food in hand." % [int(ledger.tools.get(subject,0)),"" if int(ledger.tools.get(subject,0))==1 else "s",Plain.number(float(spec.rate)),Plain.number(Grain.available_total()),Plain.number(Grain.in_process()),Plain.number(float(ledger.report.get("loss",0)))]
	var quote:=Grain.quote(subject);install_button.disabled=quote.has("error")
	install_button.tooltip_text=String(quote.get("message",quote.get("error","")))

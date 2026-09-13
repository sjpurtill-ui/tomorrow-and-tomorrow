extends VBoxContainer
const B=preload("res://scripts/household_clothing.gd")
const K=preload("res://scripts/clothing_knowledge.gd")
var subject:=""
var details:Label
var install_button:Button
var elapsed:=0.0
func _ready()->void:
	if not K.METHODS.has(subject):return
	details=Label.new();details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(details)
	install_button=Button.new();install_button.text="Install clothing equipment";install_button.custom_minimum_size.y=34;add_child(install_button)
	install_button.pressed.connect(func()->void:
		var result:=B.install(subject);install_button.tooltip_text=String(result.get("message",result.get("error","")));refresh())
	refresh()
func _process(delta:float)->void:
	elapsed+=delta
	if elapsed>=1:elapsed=0;refresh()
func refresh()->void:
	if not is_instance_valid(details):return
	var ledger:=B.data();var service:=B.coverage(WorldSimulation.state.population_exact,int(WorldSimulation.state.elapsed_days))
	details.text="%d installed · %.0f units per handler-day. Shares remaining Logistics work.\n%.1f garments · %.1f issued · cold exposure reduced %.1f%% · storm exposure reduced %.1f%%.\nGarments wear during use. Washing consumes water and removes garments for one drying day. Layering pairs spare garments; moisture handling adds tested lining. These are aggregate game coefficients."%[int(ledger.tools.get(subject,0)),float(K.METHODS[subject].rate),B.count(),float(service.issued),float(service.cold)*100,float(service.storm)*100]
	var quote:=B.quote(subject);install_button.disabled=quote.has("error");install_button.tooltip_text=String(quote.get("message",quote.get("error","")))

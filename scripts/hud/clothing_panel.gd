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
	var garments:Array[String]=[]
	var names:={"knit":"knitted","twill":"twill wraps","pile":"pile wraps","sew":"sewn","fit":"fitted","grade":"graded fit","leather":"fitted leather","tied":"tied garments","quilt":"quilted garments","rain_shell":"rain shells"}
	for kind:String in B.CREATION_MODES:
		var amount:=0.0
		for lot:Dictionary in ledger.lots:
			if lot.kind==kind:amount+=float(lot.amount)
		if amount>0:garments.append("%.1f %s"%[amount,names.get(kind,kind)])
	details.text+="\nStock: "+", ".join(garments)+". Recovered bone: %.2f (from actual hunting)."%B.available(B.BONE_RESOURCE)
	details.text+="\nLeather garments: %.1f. Raw hides: %.1f; flexible leather: %.1f. Wet exposure wears leather; fitted leather patches repair it without textile laundering."%[B.leather_count(),B.available("Raw Hides"),B.available("Flexible Leather")]
	details.text+="\nFigured-fabric garments: %.1f. Patterned cloth retains its identity through use and washing; decoration adds no protection."%B.figured_count()
	var equipment:Array[String]=[];var inputs:Array[String]=[]
	var costs:=B.materials(subject,true)
	for item:String in costs:equipment.append("%.2f %s"%[float(costs[item]),item])
	var supplies:=B.materials(subject)
	for item:String in supplies:inputs.append("%.2f %s"%[float(supplies[item]),item])
	if K.METHODS[subject].mode=="layer":inputs.append("2 spare garments per layered assembly")
	details.text+="\nInstall: "+", ".join(equipment)+".\nPer unit processed: "+", ".join(inputs)+".\nProcessed today: %.1f units; all clothing work today: %.2f handler-days."%[float(ledger.report.get("methods",{}).get(subject,0)),float(ledger.report.get("workers",0))]
	if subject in ["textile_waterproofing","garment_seam_sealing"]:
		var barriers=preload("res://scripts/textile_barriers.gd")
		details.text+="\nRain shells need three paid surface checks. Sealed seams need three later checks. Failed surfaces receive compatible patches and start again; washing removes qualification."
		for lot:Dictionary in ledger.lots:
			if lot.kind!="rain_shell":continue
			var meta:Dictionary=lot.get("barrier",barriers.fresh())
			var status:="seams qualified" if barriers.seam_ready(lot) else "surface qualified" if barriers.surface_ready(lot) else "patch needed" if barriers.needs_patch(lot) else "surface checks pending"
			details.text+="\n%.1f rain shells: %s; surface %d/3, seam %d/3; condition %.2f."%[float(lot.amount),status,meta.surface_loss.size(),meta.seam_loss.size(),float(lot.condition)]
	if float(K.METHODS[subject].get("power",0))>0:
		details.text+="\nUses %.2f generated electricity per processed unit."%float(K.METHODS[subject].power)
		if K.METHODS[subject].mode=="machine_wash":details.text+=" Powered washing causes 0.002 condition wear."
	if subject=="textile_durability_testing":
		details.text+="\nTests remove a quarter-garment spare and run five dated wear/wash cycles. Results describe this game protocol, not a guaranteed service life."
		for kind:String in ledger.get("trials",{}):
			var trial:Dictionary=ledger.trials[kind]
			details.text+="\n%s: %d/5 cycles, condition %.3f → %.3f, last observed day %d."%[kind,int(trial.cycles),float(trial.before),float(trial.condition),int(trial.last_day)]
	var quote:=B.quote(subject);install_button.disabled=quote.has("error");install_button.tooltip_text=String(quote.get("message",quote.get("error","")))

extends "res://scripts/hud/content/dock_content_base.gd"
const Land=preload("res://scripts/military_unit_catalog.gd")
const Joint=preload("res://scripts/joint_force_catalog.gd")
const Production=preload("res://scripts/persistent_production.gd")

const EraWords=preload("res://scripts/hud/era_words.gd")

## The chains this people can see: sea and air only once boats or flight exist.
func _domains()->Array[String]:
	var out:Array[String]=["army"]
	if EraWords.has_boats():out.append("navy")
	if EraWords.has_flight():out.append("air")
	return out

func meta()->Dictionary:
	var tabs:Array=[]
	for domain in _domains():tabs.append({"army":"50 LAND","navy":"NAVAL CHAIN","air":"AIR CHAIN"}[domain])
	return {"eyebrow":"MILITARY PROGRESSION","title":"Units & equipment","subtabs":tabs}

func tab(requested:int)->Dictionary:
	var domains:=_domains()
	var sub:=["army","navy","air"].find(domains[clampi(requested,0,domains.size()-1)])
	var entries:Dictionary=Land.ARCHETYPES if sub==0 else Joint.UNITS
	var rows:Array=[]
	for id:String in entries:
		var unit:Dictionary=entries[id]
		if sub>0 and unit.domain!=("navy" if sub==1 else "air"):continue
		var gate:Dictionary=MilitaryCampaign._knowledge_gate(String(unit.gate),.10)
		var items:Array=Land.equipment_for(id) if sub==0 else [unit.equipment]
		var stocks:Array[String]=[]
		for item:String in items:stocks.append("%s: %d in reserve" % [Production.product_name(item),int(MilitaryCampaign.military_inventory.get(item,0))])
		var parent:=String(unit.get("lineage",""))
		var description:=String(unit.purpose)
		if not parent.is_empty():description+="\nDevelops from "+String(entries[parent].label)+"."
		description+="\n"+" · ".join(stocks)
		if not bool(gate.unlocked):description+="\n"+String(gate.reason)
		elif sub==0:description+="\n%d days of training; fielding also requires people and equipment." % int(Land.training_days(id))
		else:description+="\n%d crew per craft · %d km range · %d fuel per day." % [unit.crew,unit.range_km,unit.fuel_per_day]
		rows.append({"name":String(unit.label),"sub":description,"value":"KNOWN" if bool(gate.unlocked) else "LOCKED","value_color":Tokens.TEAL if bool(gate.unlocked) else Tokens.MUTED})
	var branches:PackedStringArray=[]
	for domain in domains.slice(1):branches.append({"navy":"naval","air":"air"}[domain])
	var intro:="50 land archetypes"
	if not branches.is_empty():intro+=" plus separate %s branches" % " and ".join(branches)
	intro+=". Any people can develop these capabilities. Older forms remain available; a new discovery does not replace an existing force."
	return {"kpis":[],"blocks":[{"type":"text","text":intro},{"type":"rows","items":rows}]}

func signature()->Array:
	return [GameState.known_discoveries.duplicate(),GameState.discovery_adoption.duplicate(),MilitaryCampaign.military_inventory.duplicate()]

extends "res://scripts/hud/content/dock_content_base.gd"
const Land=preload("res://scripts/military_unit_catalog.gd")
const Joint=preload("res://scripts/joint_force_catalog.gd")
const Production=preload("res://scripts/persistent_production.gd")

func meta()->Dictionary:
	return {"eyebrow":"MILITARY PROGRESSION","title":"Units & equipment","subtabs":["50 LAND","NAVAL CHAIN","AIR CHAIN"]}

func tab(sub:int)->Dictionary:
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
	return {"kpis":[],"blocks":[{"type":"text","text":"50 land archetypes plus separate naval and air branches. Any civilization can develop these capabilities. Older forms remain available; a new discovery does not replace an existing force."},{"type":"rows","items":rows}]}

func signature()->Array:
	return [GameState.known_discoveries.duplicate(),GameState.discovery_adoption.duplicate(),MilitaryCampaign.military_inventory.duplicate()]

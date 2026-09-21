extends RefCounted
## Compose actual recorded facts only; discovery knowledge belongs to the civilization.
static func events(settlement:Dictionary,discoveries:Array,buildings:Array)->Array:
	var result:Array=[]
	var city_id:=String(settlement.get("id",""))
	var city:=String(settlement.get("name","Settlement"))
	if settlement.has("founded_day"):
		result.append({"day":int(settlement.founded_day),"kind":"Founding","title":city+" founded","scope":city,"description":"A permanent home enters the record.","art":0})
	for entry:Dictionary in discoveries:
		var event:=entry.duplicate(true)
		event["day"]=int(entry.get("day",0));event["kind"]="Discovery";event["scope"]="Civilization"
		event["title"]=String(entry.get("name",entry.get("title","Discovery recorded")))
		event["description"]=String(entry.get("causal_mechanism",entry.get("description","")))
		result.append(event)
	for entry:Dictionary in buildings:
		if String(entry.get("settlement_id",""))!=city_id:continue
		var kind:=String(entry.get("kind","Building")).replace("_"," ").capitalize()
		var material:=String(entry.get("material_family",""))
		var description:=String({"organic":"Timber and plant materials","earth":"Earth construction","masonry":"Masonry construction"}.get(material,material.replace("_"," ").capitalize()))
		result.append({"day":int(entry.get("day",0)),"kind":"Building","scope":city,"title":kind+" · "+String(entry.get("event","recorded")).capitalize(),"description":description,"art":preload("res://scripts/hud/construction_art.gd").building(kind)})
	result.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.day)>int(b.day))
	return result

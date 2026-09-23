extends RefCounted
const Goods=preload("res://scripts/civilian_goods.gd")
static func inquiry(domain:String="",query:String="")->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for entry:Dictionary in DiscoverySystem.technology_tree():
		if domain!="" and String(entry.dynamic)!=domain: continue
		var known:=String(entry.status)=="DISCOVERED"
		var exposed:=known or String(entry.status) in ["AVAILABLE","RESEARCHING"]
		var title:=String(entry.name) if exposed else "Unexplored question"
		if query!="" and not title.to_lower().contains(query.to_lower()): continue
		var item:Dictionary={"id":String(entry.id),"name":title,"domain":String(entry.dynamic),"status":String(entry.status),"known":known,"ready":bool(entry.ready),"requires":entry.get("requires",[]).duplicate(),"progress":float(entry.progress),"description":String(entry.get("observation","")) if exposed else "This question needs earlier knowledge or further evidence. Its outcome is not yet known.","missing":entry.missing.duplicate() if exposed else [],"effects":entry.get("effects",{}).duplicate() if known else {}}
		item["requires_any"]=entry.get("requires_any",[]).duplicate(true)
		item["operating_summary"]=DiscoverySystem._discovery_effect_summary(entry) if exposed and (entry.has("meal_preparation") or String(entry.id) in ["smoking","food_drying"] or Goods.TECHNIQUES.has(String(entry.id))) else ""
		item["pathways"]=entry.get("pathways",[]).duplicate(true) if exposed else []
		item["pathway_description"]=String(entry.get("pathway_description","")) if exposed else ""
		item["subcategory"]=String(entry.get("subcategory",""))
		item["exposed"]=exposed
		item["assignment"]=DiscoverySystem.research_assignment(entry) if exposed and not known else {}
		item["discovered_day"]=_discovered_day(String(entry.id)) if known else -1
		result.append(item)
	return result
static func _discovered_day(id:String)->int:
	var origins:Dictionary=GameState.society_exchange.get("origins",{})
	var origin:Dictionary=origins.get(id,{})
	if origin.has("day"):return int(origin.day)
	for event:Dictionary in GameState.discovery_log:
		if String(event.get("id",""))==id and event.has("day"):return int(event.day)
	return -1
static func materials()->Array[Dictionary]:
	var entries:Dictionary={}
	for deposit:Dictionary in ResourceSystem.visible_deposits():
		var resource:=String(deposit.resource)
		if resource=="Food": continue
		if not entries.has(resource): entries[resource]={"id":resource,"name":ResourceSystem.display_name(resource),"sites":0,"accessible":0,"workable":0,"exhausted":0,"flow":0.0,"stock":0.0,"known":true,"requires":[],"domain":group(resource),"unit":material_unit(resource)}
		var item:Dictionary=entries[resource]
		item.sites+=1; item.flow+=float(deposit.get("delivered_today",0))
		if String(deposit.stage) in ["accessible","developed"]:
			item.accessible+=1
			if ResourceSystem.deposit_exhausted(deposit):item.exhausted+=1
			else:item.workable+=1
	for resource:String in GameState.resource_stockpiles:
		if resource=="Food" or float(GameState.resource_stockpiles[resource])<=0: continue
		if not entries.has(resource): entries[resource]={"id":resource,"name":ResourceSystem.display_name(resource),"sites":0,"accessible":0,"workable":0,"exhausted":0,"flow":0.0,"stock":0.0,"known":true,"requires":[],"domain":group(resource),"unit":material_unit(resource)}
		entries[resource].stock=float(GameState.resource_stockpiles[resource])
	var result:Array[Dictionary]=[]
	for item:Dictionary in entries.values():
		item["status"]="STORED · DEPLETED" if item.stock>0 and item.workable<=0 and item.exhausted>0 else "IN STORAGE" if item.stock>0 else "FLOWING" if item.flow>0.001 else "ACCESSIBLE" if item.workable>0 else "EXHAUSTED" if item.exhausted>0 else "RECOGNIZED"
		item["description"]="%.1f %s stored · %.1f %s delivered today. %d recognized sites; %d workable; %d exhausted. %s" % [item.stock,item.unit,item.flow,item.unit,item.sites,item.workable,item.exhausted,ResourceSystem.plain_language_description(item.id)]
		result.append(item)
	result.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return String(a.domain)+String(a.name)<String(b.domain)+String(b.name))
	result.append({"id":"unknown","name":"Not yet recognized","domain":"Unknown","status":"UNDISCOVERED","description":"Surveying and returning expeditions may identify more materials. Their names, locations and quantities remain unknown.","known":false,"requires":[]})
	return result
static func material_unit(resource:String)->String:
	# The underlying economy is intentionally abstract rather than calibrated to
	# tonnes. Water already has a concrete gameplay meaning: one person's daily
	# drinking portion. Other inventories share the recipe ledger's bulk unit.
	return "daily portions" if resource=="Freshwater" else "bulk units"
static func group(resource:String)->String:
	if resource in ["Timber","Fiber Plants","Game","Medicinal Plants","Peat"]: return "Organic"
	if resource in ["Freshwater","Deep Aquifer","Fertile Soil"]: return "Land & water"
	return "Stone, earth & metals"

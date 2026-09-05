extends RefCounted
static func inquiry(domain:String="",query:String="")->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for entry:Dictionary in DiscoverySystem.technology_tree():
		if domain!="" and String(entry.dynamic)!=domain: continue
		var known:=String(entry.status)=="DISCOVERED"
		var exposed:=known or String(entry.status) in ["AVAILABLE","RESEARCHING"]
		var title:=String(entry.name) if exposed else "Unexplored question"
		if query!="" and not title.to_lower().contains(query.to_lower()): continue
		result.append({"id":String(entry.id),"name":title,"domain":String(entry.dynamic),"status":String(entry.status),"known":known,"ready":bool(entry.ready),"requires":entry.get("requires",[]).duplicate(),"progress":float(entry.progress),"description":String(entry.get("observation","")) if exposed else "This question needs earlier knowledge or further evidence. Its outcome is not yet known.","missing":entry.missing.duplicate() if exposed else [],"effects":entry.get("effects",{}).duplicate() if known else {}})
	return result
static func materials()->Array[Dictionary]:
	var entries:Dictionary={}
	for deposit:Dictionary in ResourceSystem.visible_deposits():
		var resource:=String(deposit.resource)
		if resource=="Food": continue
		if not entries.has(resource): entries[resource]={"id":resource,"name":ResourceSystem.display_name(resource),"sites":0,"accessible":0,"flow":0.0,"stock":0.0,"known":true,"requires":[],"domain":group(resource)}
		var item:Dictionary=entries[resource]
		item.sites+=1; item.flow+=float(deposit.get("delivered_today",0))
		if String(deposit.stage) in ["accessible","developed"]: item.accessible+=1
	for resource:String in GameState.resource_stockpiles:
		if resource=="Food" or float(GameState.resource_stockpiles[resource])<=0: continue
		if not entries.has(resource): entries[resource]={"id":resource,"name":ResourceSystem.display_name(resource),"sites":0,"accessible":0,"flow":0.0,"stock":0.0,"known":true,"requires":[],"domain":group(resource)}
		entries[resource].stock=float(GameState.resource_stockpiles[resource])
	var result:Array[Dictionary]=[]
	for item:Dictionary in entries.values():
		item["status"]="IN STORAGE" if item.stock>0 else "ACCESSIBLE" if item.accessible>0 else "RECOGNIZED"
		item["description"]="%.1f bulk units stored · %.1f delivered today. %d recognized sites; %d accessible. %s" % [item.stock,item.flow,item.sites,item.accessible,ResourceSystem.plain_language_description(item.id)]
		result.append(item)
	result.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return String(a.domain)+String(a.name)<String(b.domain)+String(b.name))
	result.append({"id":"unknown","name":"Not yet recognized","domain":"Unknown","status":"UNDISCOVERED","description":"Surveying and returning expeditions may identify more materials. Their names, locations and quantities remain unknown.","known":false,"requires":[]})
	return result
static func group(resource:String)->String:
	if resource in ["Timber","Fiber Plants","Game","Medicinal Plants","Peat"]: return "Organic"
	if resource in ["Freshwater","Deep Aquifer","Fertile Soil"]: return "Land & water"
	return "Stone, earth & metals"

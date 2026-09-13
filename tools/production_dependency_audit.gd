extends RefCounted
## Structural fabrication closure. Raw resources are assumed obtainable;
## knowledge, quantities, elapsed work and geographic access are not simulated.
static func numeric(value:Variant,positive:bool=false)->bool:
	return (value is int or value is float) and is_finite(float(value)) and (float(value)>0 if positive else float(value)>=0)
static func missing(costs:Dictionary,available:Dictionary)->Array[String]:
	var result:Array[String]=[]
	for item:String in costs:
		if float(costs[item])>0 and not available.has(item):result.append(item)
	return result
static func audit(products:Dictionary,plants:Dictionary,raw_resources:Array,discovery_ids:Array,analytical_routes:Dictionary={})->Dictionary:
	products=products.duplicate(true)
	products.merge(analytical_routes)
	var sources:Dictionary={};var available:Dictionary={};var errors:Array[String]=[]
	for item:String in raw_resources:sources[item]=true;available[item]=true
	for recipe:Dictionary in products.values():
		sources[String(recipe.output)]=true
		for item:String in recipe.get("co_products",{}):sources[item]=true
	var service_sources:Dictionary={}
	for plant:Dictionary in plants.values():
		for name:String in plant.get("services",{}):service_sources[name]=true
	for id:String in products:
		var recipe:Dictionary=products[id]
		for gate:String in [recipe.gate]+recipe.get("requires",[]):
			if gate not in discovery_ids:errors.append(id+": unknown discovery "+gate)
		if String(recipe.output).strip_edges().is_empty():errors.append(id+": missing manufactured output")
		if not numeric(recipe.get("days"),true):errors.append(id+": invalid manufacturing work")
		if not numeric(recipe.get("power",0)):errors.append(id+": invalid electricity requirement")
		for name:String in recipe.get("services",{}):
			if not numeric(recipe.services[name],true):errors.append(id+": invalid service requirement for "+name)
			if not service_sources.has(name):errors.append(id+": no service source for "+name)
		for field:String in ["materials","tooling","co_products"]:
			for item:String in recipe.get(field,{}):
				var quantity:Variant=recipe[field][item]
				if not numeric(quantity,true):errors.append(id+": invalid "+field+" quantity for "+item)
				if field!="co_products" and not sources.has(item):errors.append(id+": no source for "+item+" ("+field+")")
	for id:String in plants:
		var plant:Dictionary=plants[id]
		if not numeric(plant.get("power",0)):errors.append(id+": invalid operating electricity requirement")
		for service:String in plant.get("services",{}):
			if not numeric(plant.services[service],true):errors.append(id+": invalid service quantity for "+service)
		for gate:String in [plant.gate]+plant.get("requires",[]):
			if gate not in discovery_ids:errors.append(id+": unknown discovery "+gate)
		for field:String in ["cost","inputs"]:
			for item:String in plant.get(field,{}):
				var quantity:Variant=plant[field][item]
				if not numeric(quantity,true):errors.append(id+": invalid "+field+" quantity for "+item)
				if not sources.has(item):errors.append(id+": no source for "+item+" ("+field+")")
	# Do not execute closure on invalid quantities or unknown gates. Counts of
	# zero here mean unverified, not proof that every dependency is blocked.
	if not errors.is_empty():
		return {"errors":errors,"blocked_products":{},"blocked_plants":{},"reachable_products":0,"product_count":products.size(),"reachable_plants":0,"plant_count":plants.size(),"rounds":0,"closure_performed":false,"analytical_route_count":analytical_routes.size(),"conditional_analysis_success_assumed":not analytical_routes.is_empty(),"structural_only":true,"campaign_verified":false}
	var made:Dictionary={};var installed:Dictionary={};var services:Dictionary={}
	var changed:=true;var rounds:=0
	while changed:
		changed=false;rounds+=1
		for id:String in products:
			if made.has(id):continue
			var recipe:Dictionary=products[id]
			if not missing(recipe.materials,available).is_empty() or not missing(recipe.get("tooling",{}),available).is_empty():continue
			if float(recipe.get("power",0))>0 and not services.has("electricity"):continue
			if not missing(recipe.get("services",{}),services).is_empty():continue
			made[id]=true;available[String(recipe.output)]=true;changed=true
			for item:String in recipe.get("co_products",{}):available[item]=true
		for id:String in plants:
			if installed.has(id):continue
			var plant:Dictionary=plants[id]
			if not missing(plant.cost,available).is_empty() or not missing(plant.inputs,available).is_empty():continue
			if float(plant.power)>0 and not services.has("electricity"):continue
			installed[id]=true;changed=true
			for service:String in plant.services:
				if float(plant.services[service])>0:services[service]=true
	var blocked:Dictionary={};var blocked_plants:Dictionary={}
	for id:String in products:
		if made.has(id):continue
		var recipe:Dictionary=products[id]
		blocked[id]={"services":missing(recipe.get("services",{}),services),"materials":missing(recipe.materials,available),"tooling":missing(recipe.get("tooling",{}),available),"electricity":float(recipe.get("power",0))<=0 or services.has("electricity")}
	for id:String in plants:
		if not installed.has(id):blocked_plants[id]={"cost":missing(plants[id].cost,available),"inputs":missing(plants[id].inputs,available),"electricity":float(plants[id].power)<=0 or services.has("electricity")}
	return {"errors":errors,"blocked_products":blocked,"blocked_plants":blocked_plants,"reachable_products":made.size(),"product_count":products.size(),"reachable_plants":installed.size(),"plant_count":plants.size(),"rounds":rounds,"closure_performed":true,"analytical_route_count":analytical_routes.size(),"conditional_analysis_success_assumed":not analytical_routes.is_empty(),"structural_only":true,"campaign_verified":false}

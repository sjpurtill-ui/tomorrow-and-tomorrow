extends RefCounted
## Structural fabrication closure. Raw resources are assumed obtainable;
## knowledge, quantities, elapsed work and geographic access are not simulated.
static func missing(costs:Dictionary,available:Dictionary)->Array[String]:
	var result:Array[String]=[]
	for item:String in costs:
		if float(costs[item])>0 and not available.has(item):result.append(item)
	return result
static func audit(products:Dictionary,plants:Dictionary,raw_resources:Array,discovery_ids:Array)->Dictionary:
	var sources:Dictionary={};var available:Dictionary={};var errors:Array[String]=[]
	for item:String in raw_resources:sources[item]=true;available[item]=true
	for recipe:Dictionary in products.values():
		sources[String(recipe.output)]=true
		for item:String in recipe.get("co_products",{}):sources[item]=true
	for id:String in products:
		var recipe:Dictionary=products[id]
		if String(recipe.gate) not in discovery_ids:errors.append(id+": unknown discovery "+String(recipe.gate))
		if String(recipe.output).strip_edges().is_empty():errors.append(id+": missing manufactured output")
		if not is_finite(float(recipe.days)) or float(recipe.days)<=0:errors.append(id+": invalid manufacturing work")
		if not is_finite(float(recipe.get("power",0))) or float(recipe.get("power",0))<0:errors.append(id+": invalid electricity requirement")
		for field:String in ["materials","tooling","co_products"]:
			for item:String in recipe.get(field,{}):
				var quantity:Variant=recipe[field][item]
				if not (quantity is int or quantity is float) or not is_finite(float(quantity)) or float(quantity)<=0:errors.append(id+": invalid "+field+" quantity for "+item)
				if field!="co_products" and not sources.has(item):errors.append(id+": no source for "+item+" ("+field+")")
	for id:String in plants:
		var plant:Dictionary=plants[id]
		for gate:String in [plant.gate]+plant.get("requires",[]):
			if gate not in discovery_ids:errors.append(id+": unknown discovery "+gate)
		for field:String in ["cost","inputs"]:
			for item:String in plant.get(field,{}):
				var quantity:Variant=plant[field][item]
				if not (quantity is int or quantity is float) or not is_finite(float(quantity)) or float(quantity)<=0:errors.append(id+": invalid "+field+" quantity for "+item)
				if not sources.has(item):errors.append(id+": no source for "+item+" ("+field+")")
	var made:Dictionary={};var installed:Dictionary={};var services:Dictionary={}
	var changed:=true;var rounds:=0
	while changed:
		changed=false;rounds+=1
		for id:String in products:
			if made.has(id):continue
			var recipe:Dictionary=products[id]
			if not missing(recipe.materials,available).is_empty() or not missing(recipe.get("tooling",{}),available).is_empty():continue
			if float(recipe.get("power",0))>0 and not services.has("electricity"):continue
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
		blocked[id]={"materials":missing(recipe.materials,available),"tooling":missing(recipe.get("tooling",{}),available),"electricity":float(recipe.get("power",0))<=0 or services.has("electricity")}
	for id:String in plants:
		if not installed.has(id):blocked_plants[id]={"cost":missing(plants[id].cost,available),"inputs":missing(plants[id].inputs,available),"electricity":float(plants[id].power)<=0 or services.has("electricity")}
	return {"errors":errors,"blocked_products":blocked,"blocked_plants":blocked_plants,"reachable_products":made.size(),"product_count":products.size(),"reachable_plants":installed.size(),"plant_count":plants.size(),"rounds":rounds,"structural_only":true,"campaign_verified":false}

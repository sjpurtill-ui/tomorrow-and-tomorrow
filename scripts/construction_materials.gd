extends RefCounted
## Feasible recipes compete for the current city's delivered stores. Culture is
## not a material source. Callers still own labor, construction time and payment.
static func choose(recipes:Array[Dictionary],stocks:Dictionary,known:Array,stone_priority:float=0.0)->Dictionary:
	var best:Dictionary={}
	var least_pressure:=INF
	for recipe:Dictionary in recipes:
		var required:=String(recipe.get("requires",""))
		if not required.is_empty() and required not in known:continue
		var pressure:=0.0
		var feasible:=true
		for resource:String in recipe.cost:
			var amount:=float(recipe.cost[resource])
			var stored:=float(stocks.get(resource,0.0))
			if stored+0.0001<amount:feasible=false;break
			pressure+=amount/maxf(amount,stored)
		if not feasible:continue
		if recipe.get("family","")=="stone":pressure/=1.0+maxf(0.0,stone_priority)*3.0
		pressure/=clampf(float(recipe.get("service_life",1.0)),1.0,2.0)
		if pressure<least_pressure:
			least_pressure=pressure
			best=recipe.duplicate(true)
	if not best.is_empty():best["mix"]=mix_for(best.cost)
	return best

## Drawn buildings take the material family of the city's construction era:
## organic in early settlements, earth once clay work spreads, stone in masonry
## eras or when the city favours stone. Falls back to the best known family.
static func choose_drawn(recipes:Array[Dictionary],known:Array,tier:float,stone_priority:float=0.0)->Dictionary:
	var order:Array=["organic","earth","stone"]
	if tier>=4.0 or stone_priority>0.0:order=["stone","earth","organic"]
	elif tier>=2.0:order=["earth","stone","organic"]
	# Later recipes in a family are its more advanced techniques.
	for family:String in order:
		var pick:Dictionary={}
		for recipe:Dictionary in recipes:
			var required:=String(recipe.get("requires",""))
			if not required.is_empty() and required not in known:continue
			if String(recipe.get("family","organic"))==family:pick=recipe
		if pick.is_empty():continue
		var best:=pick.duplicate(true)
		best["mix"]=mix_for(best.cost)
		return best
	return {}

static func mix_for(cost:Dictionary)->Dictionary:
	var total:=0.0
	for amount in cost.values():total+=float(amount)
	var mix:Dictionary={}
	for resource in cost:mix[resource]=float(cost[resource])/maxf(.0001,total)
	return mix

static func family_for(cost:Dictionary)->String:
	var earth:=float(cost.get("Clay",0))
	var stone:=float(cost.get("Stone",0))
	var timber:=float(cost.get("Timber",0))
	if earth>timber and earth>=stone:return "earth"
	if stone>timber and stone>earth:return "stone"
	return "organic"

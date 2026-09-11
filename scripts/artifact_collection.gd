extends RefCounted
## Deterministic material culture, owned by the existing society_exchange ledger.
const FORMS := ["cutting blade", "carved bead", "counting token", "ceremonial bowl", "woven fragment", "engraved tablet", "measuring rod", "pendant", "seal", "figurine", "flute", "painted panel", "storage jar", "spindle", "route marker", "calendar stone"]
const STYLES := ["etched", "painted", "banded", "dotted", "spiraling", "paired", "interlaced", "radiating", "bordered", "repeated", "angular", "flowing", "layered", "faded", "polished", "miniature"]
const FORM_MATERIALS := ["flint", "shell", "bone", "clay", "fiber", "slate", "wood", "amber", "soapstone", "clay", "bone", "wood", "clay", "wood", "basalt", "limestone"]
const MOTIFS := ["river", "sun", "moon", "herd", "spiral", "mountain", "seed", "rain", "wave", "hand", "star", "bird", "leaf", "hearth", "path", "ancestor"]
const SUBJECTS := ["stone_sorting", "cordage", "tallies", "clay_shaping", "basketry", "oral_epics", "standard_measures", "customary_law", "pit_firing", "festival_calendar", "route_memory", "seasonal_patterns", "food_drying", "joinery", "well_siting", "civic_games"]
const TIERS := ["Common", "Unusual", "Rare", "Exceptional", "Legendary"]

static func site_claimed(id:String)->bool:
	if GameState.society_exchange.get("artifact_sites",{}).has(id):return true
	for actor:Dictionary in WorldSimulation.actors.values():
		var owner:Node=actor.get("systems",{}).get("GameState")
		if owner!=null and owner.society_exchange.get("artifact_sites",{}).has(id):return true
	return false

static func find_at(seed:int, position:Vector2, day:int)->Dictionary:
	var site := "%d:%d" % [floori(position.x/24), floori(position.y/24)]
	var code := absi(hash(str(seed)+":"+site))
	var variant := code % 4096
	var roll := (code / 4096) % 1000
	var tier := 4 if roll>=997 else 3 if roll>=975 else 2 if roll>=880 else 1 if roll>=600 else 0
	return {"id":"artifact:"+str(seed)+":"+site,"kind":"artifact","name":"%s %s · %s %s" % [String(FORM_MATERIALS[variant%16]).capitalize(),FORMS[variant%16],STYLES[(variant/16)%16],MOTIFS[(variant/256)%16]],"source_id":"","source_name":"Survey site "+site,"position":{"x":position.x,"z":position.y},"observed_day":day,"returned_day":day,"discovery_id":SUBJECTS[variant%16],"study":0.0,"work":20.0+tier*20.0,"signals":["survey","culture","research"],"rarity":tier,"catalogue_id":variant,"held_days":0.0,"exhibited":false,"acquisition":"Recovered during a journey into uncharted ground"}

static func prestige(item:Dictionary)->float:
	return pow(2.5,int(item.get("rarity",0)))*(1.0+log(1.0+float(item.get("held_days",0))/360.0))

static func price(item:Dictionary)->float:
	return snappedf(20.0*prestige(item)*(1.0+float(item.study)),.01)

static func summary()->Dictionary:
	var result := {"count":0,"prestige":0.0,"science":0.0,"culture":0.0,"exhibited":0}
	for item:Dictionary in WorldSimulation.state.society_exchange.collections.values():
		if item.kind!="artifact":continue
		result.count+=1;result.prestige+=prestige(item)
		if item.get("exhibited",false):result.exhibited+=1
	result.science=log(1.0+float(result.prestige))*.045
	result.culture=log(1.0+float(result.prestige))*.075
	return result

static func bonus(domain:String)->float:
	return float(WorldSimulation.state.society_exchange.get("artifact_bonuses",{}).get("culture" if domain=="culture" else "science",0))

static func museum_ready()->bool:
	return "public_libraries" in WorldSimulation.state.known_discoveries and "comparative_chronicles" in WorldSimulation.state.known_discoveries

static func exhibit(id:String)->Dictionary:
	var item:Dictionary=WorldSimulation.state.society_exchange.collections.get(id,{})
	if item.get("kind","")!="artifact":return {"error":"This object is no longer held here."}
	if not museum_ready():return {"error":"Public libraries and comparative chronicles are needed to curate a museum collection."}
	item.exhibited=not bool(item.get("exhibited",false))
	return {"ok":true}

static func advance(elapsed:int)->void:
	var state:=WorldSimulation.state
	var attraction:=0.0
	for item:Dictionary in state.society_exchange.collections.values():
		if item.kind!="artifact":continue
		item["held_days"]=float(item.get("held_days",0))+elapsed
		if item.get("exhibited",false) and museum_ready() and float(item.study)>=1:attraction+=prestige(item)
	state.society_exchange["artifact_bonuses"]=summary()
	# Visitors pay from existing household money; exhibitions never mint currency.
	var revenue:=0.0
	if state.economy_stage=="currency" and attraction>0:
		var staff:=state.effective_workers("Knowledge")
		revenue=minf(state.private_currency*.001*elapsed,minf(attraction,staff*10)*.02*elapsed)
		state.private_currency-=revenue;state.public_treasury+=revenue
	state.society_exchange["museum_revenue"]=revenue

static func transfer(id:String,recipient:String,mode:String,offered:String="")->Dictionary:
	var source:=WorldSimulation.state
	var source_id:=WorldSimulation.actor_id
	var target:Node=GameState if recipient=="player" else WorldSimulation.actors.get(recipient,{}).get("systems",{}).get("GameState")
	if target==null or target==source or mode not in ["gift","sell","trade"]:return {"error":"Choose another civilization and a supported exchange."}
	var view_id:="human" if recipient=="player" else recipient
	var index:int=WorldSimulation.world._civilization_index(view_id)
	if index<0 or WorldSimulation.world.civilizations[index].player_relation.get("at_war",false):return {"error":"A peaceful contact is required."}
	if not source.society_exchange.connections.has(recipient):return {"error":"Establish contact through a returned journey first."}
	var item:Dictionary=source.society_exchange.collections.get(id,{})
	if item.get("kind","")!="artifact" or target.society_exchange.collections.has(id):return {"error":"The object is unavailable."}
	if target.society_exchange.collections.size()>=16384:return {"error":"The recipient collection is full."}
	var other:Dictionary=target.society_exchange.collections.get(offered,{})
	if mode=="trade" and (other.get("kind","")!="artifact" or source.society_exchange.collections.has(offered) or price(item)<price(other)):return {"error":"Offer an artifact worth at least the requested object."}
	var value:=price(item)
	if mode=="sell":
		if source.economy_stage!="currency" or target.economy_stage!="currency":return {"error":"Both civilizations need currency before a sale."}
		if target.public_treasury<value:return {"error":"The buyer cannot afford this object."}
		var reserve:=0.0
		for amount:float in target.monetary_reserve_metals.values():reserve+=amount
		if reserve<value/2.5:return {"error":"The buyer lacks transferable monetary backing."}
		var backing:=value/2.5
		for metal:String in target.monetary_reserve_metals:
			var moved:=minf(backing,float(target.monetary_reserve_metals[metal]))
			target.monetary_reserve_metals[metal]-=moved
			source.monetary_reserve_metals[metal]=float(source.monetary_reserve_metals.get(metal,0))+moved
			backing-=moved
		target.public_treasury-=value;target.currency_supply-=value
		source.public_treasury+=value;source.currency_supply+=value
	var message:="%s: %s transferred to %s." % [mode.capitalize(),item.name,target.settlement_name]
	for owner:Node in [source,target]:
		owner.society_exchange.history.push_front({"day":int(source.elapsed_days),"text":message})
		if owner.society_exchange.history.size()>64:owner.society_exchange.history.resize(64)
	move(source,target,item)
	if mode=="trade":move(target,source,other)
	if mode=="gift" and (source_id+":"+recipient) not in item.get("gift_receipts",[]) and item.get("gift_receipts",[]).size()<64:
		if not item.has("gift_receipts"):item.gift_receipts=[]
		item.gift_receipts.append(source_id+":"+recipient)
		WorldSimulation.scoped(recipient,func()->void:
			var ties:Dictionary=preload("res://scripts/society_exchange.gd").connection(source_id)
			ties.respect=minf(1,float(ties.respect)+minf(.15,prestige(item)*.005)))
	for owner:Node in [source,target]:
		var owner_key:=source_id if owner==source else recipient
		WorldSimulation.scoped(owner_key,func()->void:owner.society_exchange["artifact_bonuses"]=summary())
	return {"ok":true,"value":value}

static func move(source:Node,target:Node,item:Dictionary)->void:
	source.society_exchange.collections.erase(item.id)
	if source.society_exchange.evidence.get(item.discovery_id)==item.id:
		source.society_exchange.evidence.erase(item.discovery_id)
		for replacement:Dictionary in source.society_exchange.collections.values():
			if replacement.discovery_id==item.discovery_id and replacement.study>=1:source.society_exchange.evidence[item.discovery_id]=replacement.id;break
	item.exhibited=false;item.returned_day=int(target.elapsed_days)
	target.society_exchange.collections[item.id]=item
	if item.study>=1:target.society_exchange.evidence[item.discovery_id]=item.id

extends RefCounted
## Physical counterparty settlement. Quotes use the ordinary economy's desired
## stocks, prices and throughput; a trade cannot buy goods that do not exist.
static func recipient(id:String)->String:return "player" if id=="human" else id
static func receive(id:String,resource:String,quantity:float,city_id:String="")->float:
	var owner:=recipient(id)
	if owner!="player" and not WorldSimulation.actors.has(owner):return 0.0
	return WorldSimulation.scoped(owner,func()->float:
		var deliver:=func()->float:return WorldSimulation.economy._receive_trade_resource(resource,quantity)
		return WorldSimulation.settlements.with_city_resources(city_id,deliver) if city_id!="" else deliver.call()
	)
static func take(id:String,resource:String,quantity:float,city_id:String="")->float:
	var owner:=recipient(id)
	if owner!="player" and not WorldSimulation.actors.has(owner):return 0.0
	return WorldSimulation.scoped(owner,func()->float:
		var debit:=func()->float:return WorldSimulation.economy._remove_trade_resource(resource,quantity)
		return WorldSimulation.settlements.with_city_resources(city_id,debit) if city_id!="" else debit.call()
	)
static func quote(access:float,domestic:float)->Dictionary:
	var s:=WorldSimulation.state
	var economy:=WorldSimulation.economy
	var partners:Array[String]=[]
	for civ in WorldSimulation.world.civilizations:
		if String(civ.player_relation.get("treaty",""))=="trade" and not bool(civ.player_relation.get("at_war",false)):partners.append(recipient(String(civ.id)))
	var result:={"exports":0.0,"imports":0.0,"exported_goods":{},"imported_goods":{},"friction":0.0,"credit":s.external_trade_credit,"claim_limit":0.0,"claim_loss":0.0,"partners":partners.size(),"available":not partners.is_empty()}
	var offers:Dictionary={};var needs:Dictionary={};var prices:Dictionary={}
	var budget:=0.0
	if s.economy_stage!=economy.STAGE_SUBSISTENCE and s.external_trade_policy!="closed" and access>=.28:
		budget=maxf(s.population_exact*.015,domestic)*clampf((access-.24)/.76,0,1)*(.42 if s.economy_stage==economy.STAGE_METAL else .72)
		for key:String in economy.BASE_VALUES:
			if key in ["Coin","Transport Carts"]:continue
			var stock:=maxf(0,float(s.resource_stockpiles.get(key,0)))
			if not economy._resource_is_economically_known(key,stock):continue
			var desired:=economy._desired_stock(key,maxf(1,s.population_exact))
			offers[key]=maxf(0,stock-desired*1.25)
			needs[key]=maxf(0,desired*.75-stock)
			prices[key]=maxf(.01,float(s.market_prices.get(key,economy.BASE_VALUES[key])))
	WorldSimulation.market_orders[WorldSimulation.actor_id]={"day":int(s.elapsed_days),"partners":partners,"offers":offers,"needs":needs,"prices":prices,"budget":budget,"result":result}
	return result
static func settle(day:int)->void:
	var ids:=WorldSimulation.market_orders.keys();ids.sort()
	# Rotate the first buyer deterministically; nationality/controller never sets priority.
	if not ids.is_empty():
		var offset:=posmod(day,ids.size());ids=ids.slice(offset)+ids.slice(0,offset)
	for buyer:String in ids:
		var buy:Dictionary=WorldSimulation.market_orders[buyer]
		if int(buy.day)!=day:continue
		for seller:String in ids:
			if seller==buyer or seller not in buy.partners:continue
			var sell:Dictionary=WorldSimulation.market_orders[seller]
			if int(sell.day)!=day or buyer not in sell.partners:continue
			for incoming:String in buy.needs:
				for outgoing:String in sell.needs:
					if incoming==outgoing:continue
					var in_price:=float(sell.prices.get(incoming,1));var out_price:=float(buy.prices.get(outgoing,1))
					var value:=minf(minf(float(buy.budget),float(sell.budget)),minf(minf(float(buy.needs[incoming]),float(sell.offers.get(incoming,0)))*in_price,minf(float(sell.needs[outgoing]),float(buy.offers.get(outgoing,0)))*out_price))
					if value<=.0001:continue
					# Matched barter is paid on both sides; no unbacked regional credit.
					var a:=take(seller,incoming,value/in_price);var b:=take(buyer,outgoing,value/out_price)
					var paid:=minf(a*in_price,b*out_price)
					if a>paid/in_price:receive(seller,incoming,a-paid/in_price)
					if b>paid/out_price:receive(buyer,outgoing,b-paid/out_price)
					receive(buyer,incoming,paid/in_price);receive(seller,outgoing,paid/out_price)
					book(buyer,seller,incoming,paid/in_price,paid,true);book(seller,buyer,outgoing,paid/out_price,paid,true)
					buy.needs[incoming]-=paid/in_price;sell.offers[incoming]-=paid/in_price
					sell.needs[outgoing]-=paid/out_price;buy.offers[outgoing]-=paid/out_price
					buy.budget-=paid;sell.budget-=paid
	for id:String in ids:
		var report:Dictionary=WorldSimulation.market_orders[id].result
		WorldSimulation.scoped(id,func()->void:WorldSimulation.economy._update_food_import_dependence(float(report.imported_goods.get("Food",0))))
static func book(buyer:String,seller:String,resource:String,quantity:float,value:float,_barter:bool)->void:
	for id:String in [buyer,seller]:
		var importing:=id==buyer
		var report:Dictionary=WorldSimulation.market_orders[id].result
		var key:="imports" if importing else "exports"
		var goods:="imported_goods" if importing else "exported_goods"
		report[key]+=value;report[goods][resource]=float(report[goods].get(resource,0))+quantity
		WorldSimulation.scoped(id,func()->void:
			if importing:WorldSimulation.state.external_trade_imports+=value
			else:WorldSimulation.state.external_trade_exports+=value
			WorldSimulation.economy._ledger("external_"+key,value,seller,buyer,"%.2f %s exchanged with an actual civilization" % [quantity,resource])
		)

static func occupation(day:int)->void:
	var ids:Array=WorldSimulation.actors.keys();ids.append("player");ids.sort()
	for id:String in ids:
		WorldSimulation.scoped(id,func()->void:
			for civ:Dictionary in WorldSimulation.world.civilizations:
				for region:Dictionary in civ.get("strategic_regions",[]):
					if String(region.get("controller",""))!="player" or not bool(region.get("settlement_founded",false)):continue
					var population:=float(region.get("population",0))
					var resistance:=float(region.get("resistance",0));var damage:=float(region.get("damage",0));var integration:=float(region.get("integration",0))
					var governance:=WorldSimulation.world.OCCUPATION_GOVERNANCE.state(region)
					var local_id:=String(region.get("local_city_id",""))
					var relief:=population*.035*(resistance+damage+float(governance.inequality)*.25)*(1-integration*.5)
					var delivered:=take(id,"Food",relief)
					receive(String(civ.id),"Food",delivered,local_id)
					var tribute:=0.0
					if String(region.get("role",""))=="granary" and bool(WorldSimulation.world.occupation_control(String(civ.id),String(region.id)).get("controlled",false)):
						var extraction:=float(WorldSimulation.world.OCCUPATION_GOVERNANCE.policy(region).extraction)
						var function:=(integration*.7+extraction*.3)*(1-damage)*(.4+.6*float(governance.welfare))
						tribute=take(String(civ.id),"Food",population*.025*function*(1-resistance),local_id)
						receive(id,"Food",tribute)
					WorldSimulation.economy._ledger("occupation_supply",delivered+tribute,id,String(civ.id),"Day %d: %.2f food delivered, %.2f tribute received from actual city stores" % [day,delivered,tribute])
		)

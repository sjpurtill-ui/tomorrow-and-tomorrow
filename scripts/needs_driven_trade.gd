extends RefCounted
## Construction and household requirements are shared by every people. Quotes
## use current stocks, preserve commitments and move named physical resources.
const Build:=preload("res://scripts/settlement_construction.gd")
const Storage:=preload("res://scripts/storage_works.gd")
const WORKSHOP_POPULATION:=1000

static func planned_bill(project:Dictionary)->Dictionary:
	var state=WorldSimulation.state
	var best:Dictionary={};var score:=INF
	for option:Dictionary in Build.material_options(project):
		var discovery:=String(option.get("requires",""))
		if not discovery.is_empty() and discovery not in state.known_discoveries:continue
		var missing:=0.0
		for item:String in option.cost:
			missing+=maxf(0,float(option.cost[item])-float(state.resource_stockpiles.get(item,0)))/maxf(1,float(option.cost[item]))
		if missing<score:score=missing;best=option.cost
	return best.duplicate()

static func projects()->Array[Dictionary]:
	var state=WorldSimulation.state
	var result:Array[Dictionary]=[]
	if not state.settlement_site_committed or state.convoy_traveling:return result
	var held:=Storage.used();var room:=Storage.capacities()
	for project:Dictionary in Build._settlement_definitions():
		if String(project.name) in state.settlement_completed:continue
		if not String(project.get("discovery","")).is_empty() and String(project.discovery) not in state.known_discoveries:continue
		if project.has("storage_kind") and not Storage.needed(String(project.storage_kind),held,room):continue
		var ready:=true
		for required:String in project.requires:
			if required not in state.settlement_completed:ready=false
		if ready:result.append({"name":project.name,"bill":planned_bill(project),"storage":project.has("storage_kind")})
	result.sort_custom(func(a:Dictionary,b:Dictionary):return bool(a.storage) and not bool(b.storage))
	return result

static func desired(resource:String,population:float)->float:
	if resource=="Food":return population*30.0
	if resource=="Civilian Goods":return preload("res://scripts/civilian_goods.gd").target()
	if resource=="Arms":return preload("res://scripts/weapons_stock.gd").trade_wanted()
	# Protect live construction/production bills plus a month's household wear.
	var reserved:=float(preload("res://scripts/local_material_reserves.gd").calculate().get(resource,0))
	var goods=preload("res://scripts/civilian_goods.gd")
	var household:float=goods.target()*goods.DAILY_WEAR*30.0*goods.RAW_PER_UNIT*float(goods.BASKET.get(resource,0))
	return reserved+household

static func needs()->Array[Dictionary]:
	var state=WorldSimulation.state
	var result:Array[Dictionary]=[]
	var seen:Dictionary={}
	var food:=WorldSimulation.food.total_stored()
	if food<state.population_exact*15.0:
		result.append({"resource":"Food","amount":maxf(0,state.population_exact*30.0-food),"purpose":"Food reserves","effect":"Feed the settlement"});seen.Food=true
	for project:Dictionary in projects():
		for item:String in project.bill:
			var missing:=maxf(0,float(project.bill[item])-float(state.resource_stockpiles.get(item,0)))
			if missing<=0 or seen.has(item):continue
			seen[item]=true
			result.append({"resource":item,"amount":missing,"purpose":project.name,"effect":"Supply "+String(project.name).to_lower()})
	return result

static func incoming(owner:String,good:String)->float:
	var ledger=load("res://scripts/trade_ledger.gd")
	var total:=0.0
	for shipment:Dictionary in ledger.peek().get("barter_shipments",[]):
		if String(shipment.status)!="traveling":continue
		if shipment.buyer==owner and shipment.want==good:total+=float(shipment.count)
		if shipment.seller==owner and shipment.give==good:total+=float(shipment.payment)
	return total

static func room_for(owner:String,good:String)->float:
	return WorldSimulation.scoped(owner,func()->float:
		if good=="Civilian Goods":return maxf(0,preload("res://scripts/civilian_goods.gd").ceiling()-float(WorldSimulation.state.resource_stockpiles.get(good,0))-incoming(owner,good))
		var cap:=Storage.capacities();var held:=Storage.used()
		var kind:="food";var bulk:=1.0
		if good!="Food":
			var profile:Dictionary=WorldSimulation.resources.material_profile(good)
			kind=String(profile.store);bulk=float(profile.bulk)
		var reserved:=0.0
		var ledger=load("res://scripts/trade_ledger.gd")
		for item:String in ledger.GOODS:
			if item=="Arms" or item=="Civilian Goods":continue
			var other_kind:="food";var other_bulk:=1.0
			if item!="Food":
				var other:Dictionary=WorldSimulation.resources.material_profile(item)
				other_kind=String(other.store);other_bulk=float(other.bulk)
			if other_kind==kind:reserved+=incoming(owner,item)*other_bulk
		return maxf(0,float(cap[kind])-float(held[kind])-reserved)/bulk)

static func terms(buyer:String,seller:String,want:String,give:String,asked:float)->Dictionary:
	var ledger=load("res://scripts/trade_ledger.gd")
	var out:={"ok":false,"why":"","buyer":buyer,"seller":seller,"want":want,"give":give,"asked":asked,"count":0.0,"payment":0.0}
	if buyer==seller or not ledger.simulated(buyer) or not ledger.simulated(seller) or not ledger.alive(buyer) or not ledger.alive(seller):out.why="No reachable settlement.";return out
	if want==give or want not in ledger.GOODS or give not in ledger.GOODS or want=="Arms" or give=="Arms" or asked<=0:out.why="Choose two different supplies.";return out
	var pair:Dictionary=ledger.pair(buyer,seller)
	if pair.is_empty() or not bool(pair.get("known",false)):out.why="Meet their traders first.";return out
	var blocked:String=ledger.blocked(buyer,seller)
	if not blocked.is_empty():out.why="Trade is blocked: "+blocked+".";return out
	var a:Dictionary=ledger.report(buyer);var b:Dictionary=ledger.report(seller)
	if (want=="Civilian Goods" or give=="Civilian Goods") and minf(float(ledger.population(buyer)),float(ledger.population(seller)))<WORKSHOP_POPULATION:
		out.why="Small settlements barter food and materials.";return out
	var wanted:float=WorldSimulation.scoped(buyer,func():return maxf(0,desired(want,WorldSimulation.state.population_exact)-ledger._held_in_scope(want)-incoming(buyer,want)))
	var theirs:float=WorldSimulation.scoped(seller,func():return maxf(0,desired(give,WorldSimulation.state.population_exact)-ledger._held_in_scope(give)-incoming(seller,give)))
	var prices=load("res://scripts/trade_prices.gd")
	var ratio:=float(prices.value(want,seller))/maxf(.01,float(prices.value(give,seller)))
	var offer:float=ledger.spare_of(seller,want)
	var spare:float=ledger.spare_of(buyer,give)
	var count:=minf(asked,minf(wanted,minf(offer,minf(spare/ratio,theirs/ratio))))
	count=minf(count,minf(room_for(buyer,want),room_for(seller,give)/ratio))
	var today:=int(GameState.elapsed_days)
	var used:=float(pair.get("barter_used",0)) if today-int(pair.get("barter_window",-1000))<91 else 0.0
	var budget:=maxf(0,float(ledger.capacity(buyer,seller,"barter",91,a,b))-used)
	var per:=float(prices.value(want,seller))/float(ledger.CARRY.get(want,1))+ratio*float(prices.value(give,buyer))/float(ledger.CARRY.get(give,1))
	count=minf(count,budget/maxf(.001,per))
	if count<.1:out.why="No exchange fits both towns' needs, spare supplies, storage and seasonal carrying room.";return out
	out.count=snappedf(floorf(count*100.0)/100.0,.01);out.payment=float(out.count)*ratio
	out.load=float(out.count)*per
	out.days=maxi(1,ceili(float(ledger.distance_km(buyer,seller))/12.0))
	out.remaining=maxf(0,float(WorldSimulation.scoped(buyer,func():return ledger._held_in_scope(give)))-float(out.payment))
	out.ok=true
	return out

static func offers(buyer:String,seller:String)->Array[Dictionary]:
	var ledger=load("res://scripts/trade_ledger.gd")
	var result:Array[Dictionary]=[]
	var wanted:Array=WorldSimulation.scoped(buyer,needs)
	for need:Dictionary in wanted:
		if String(need.resource) not in ledger.GOODS:continue
		for give:String in ledger.GOODS:
			if give in [String(need.resource),"Arms"]:continue
			var quote:=terms(buyer,seller,String(need.resource),give,float(need.amount))
			if not bool(quote.ok):continue
			quote.purpose=need.purpose;quote.effect=need.effect;quote.shortfall=need.amount
			result.append(quote);break
		if result.size()>=3:break
	return result

static func send(quote:Dictionary)->Dictionary:
	var ledger=load("res://scripts/trade_ledger.gd")
	if (ledger.peek().get("barter_shipments",[]) as Array).filter(func(item:Dictionary):return String(item.status)=="traveling").size()>=128:return {"error":"The traders are already carrying all the exchanges they can manage."}
	var t:=terms(String(quote.buyer),String(quote.seller),String(quote.want),String(quote.give),float(quote.asked))
	if not bool(t.ok):return {"error":t.why}
	# Re-quote rather than silently execute changed quantities from a stale tile.
	if not is_equal_approx(float(t.count),float(quote.count)) or not is_equal_approx(float(t.payment),float(quote.payment)):return {"error":"The supplies changed. Review the updated offer."}
	var got:float=ledger._take(String(t.seller),String(t.want),float(t.count))
	var paid:float=ledger._take(String(t.buyer),String(t.give),float(t.payment))
	if got<float(t.count)-.0001 or paid<float(t.payment)-.0001:
		ledger._give(String(t.seller),String(t.want),got);ledger._give(String(t.buyer),String(t.give),paid)
		return {"error":"Supplies are no longer available."}
	ledger._note_report(String(t.seller),String(t.want),-got);ledger._note_report(String(t.buyer),String(t.give),-paid)
	var state:Dictionary=ledger.state();var today:=int(GameState.elapsed_days)
	if not state.has("barter_shipments"):state.barter_shipments=[]
	state.serial=int(state.serial)+1
	t.id=state.serial;t.status="traveling";t.arrival=today+int(t.days);t.purpose=quote.get("purpose","Supplies")
	state.barter_shipments.append(t)
	var pair:Dictionary=ledger.pair(String(t.buyer),String(t.seller))
	if today-int(pair.get("barter_window",-1000))>=91:pair.barter_window=today;pair.barter_used=0.0
	pair.barter_used=float(pair.get("barter_used",0))+float(t.load)
	ledger.revision+=1
	return {"ok":true,"shipment_id":t.id,"message":"Supplies dispatched; arrive in %d days." % int(t.days)}

static func advance(day:int)->void:
	var ledger=load("res://scripts/trade_ledger.gd")
	var state:Dictionary=ledger.state()
	var shipments:Array=state.get("barter_shipments",[])
	for shipment:Dictionary in shipments:
		if String(shipment.status)!="traveling" or int(shipment.arrival)>day:continue
		var buyer:=String(shipment.buyer);var seller:=String(shipment.seller)
		var blocked:String=ledger.blocked(buyer,seller)
		if not blocked.is_empty() or not ledger.alive(buyer) or not ledger.alive(seller):
			ledger._give(buyer,String(shipment.give),float(shipment.payment));ledger._give(seller,String(shipment.want),float(shipment.count))
			ledger._note_report(buyer,String(shipment.give),float(shipment.payment));ledger._note_report(seller,String(shipment.want),float(shipment.count))
			shipment.status="returned";shipment.reason="Route closed; supplies returned"
		else:
			ledger._give(buyer,String(shipment.want),float(shipment.count));ledger._give(seller,String(shipment.give),float(shipment.payment))
			ledger._note_report(buyer,String(shipment.want),float(shipment.count));ledger._note_report(seller,String(shipment.give),float(shipment.payment))
			ledger._book_pair(seller,buyer,String(shipment.want),float(shipment.count));ledger._book_pair(buyer,seller,String(shipment.give),float(shipment.payment))
			shipment.status="delivered"
		ledger.revision+=1
	# Retain bounded receipts, never discard an active shipment.
	var done:=0
	for i in range(shipments.size()-1,-1,-1):
		if String(shipments[i].status)=="traveling":continue
		done+=1
		if done>24:shipments.remove_at(i)

static func valid_shipments(value:Variant)->bool:
	if not value is Array or value.size()>152:return false
	var ledger=load("res://scripts/trade_ledger.gd")
	for item:Variant in value:
		if not item is Dictionary:return false
		if not item.has_all(["id","buyer","seller","want","give","count","payment","arrival","days","status"]):return false
		if not item.buyer is String or not item.seller is String or item.buyer==item.seller:return false
		if item.want not in ledger.GOODS or item.give not in ledger.GOODS or item.want==item.give:return false
		if item.status not in ["traveling","returned","delivered"]:return false
		for key:String in ["id","count","payment","arrival","days"]:
			if not (item[key] is float or item[key] is int) or not is_finite(float(item[key])) or float(item[key])<0:return false
	return true

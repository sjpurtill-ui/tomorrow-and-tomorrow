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
## The trade ledger, loaded when used (it preloads this module).
static var _ledger_script:GDScript
static func _ledger()->GDScript:
	if _ledger_script==null: _ledger_script=load("res://scripts/trade_ledger.gd")
	return _ledger_script
static func quote(_access:float,_domestic:float)->Dictionary:
	# Trade between peoples is carried by the trade ledger (trade_ledger.gd), on
	# each pair's own day and by the same rules for every people, from first
	# contact: gifts, then barter, then silver and coin. The economy reads the
	# last month of it here, as a day's worth, and the food it brings in.
	var s:=WorldSimulation.state
	var summary:Dictionary=_ledger().call("summary",WorldSimulation.actor_id)
	var exported:={}; var imported:={}
	for good:String in (summary.exported_goods as Dictionary): exported[good]=float(summary.exported_goods[good])/30.0
	for good:String in (summary.imported_goods as Dictionary): imported[good]=float(summary.imported_goods[good])/30.0
	var result:={"exports":float(summary.exports)/30.0,"imports":float(summary.imports)/30.0,"exported_goods":exported,"imported_goods":imported,"friction":0.0,"credit":s.external_trade_credit,"claim_limit":0.0,"claim_loss":0.0,"partners":int(summary.partners),"available":bool(summary.available)}
	# No orders for the old matching (settle): nothing is traded twice.
	WorldSimulation.market_orders.erase(WorldSimulation.actor_id)
	WorldSimulation.economy._update_food_import_dependence(float(imported.get("Food",0.0))*float(WorldSimulation.span))
	return result
## Retired: goods between peoples move on the trade ledger's own schedule
## (trade_ledger.gd), and quote() places no orders here; kept so the world's
## exchange step reads the same.
static func settle(_day:int)->void:
	WorldSimulation.market_orders.clear()

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
					# Relief and tribute are trade too, on the one ledger (trade_ledger.gd).
					_ledger().call("note_flow",id,String(civ.id),"Food",delivered,"relief")
					var tribute:=0.0
					if String(region.get("role",""))=="granary" and bool(WorldSimulation.world.occupation_control(String(civ.id),String(region.id)).get("controlled",false)):
						var extraction:=float(WorldSimulation.world.OCCUPATION_GOVERNANCE.policy(region).extraction)
						var function:=(integration*.7+extraction*.3)*(1-damage)*(.4+.6*float(governance.welfare))
						tribute=take(String(civ.id),"Food",population*.025*function*(1-resistance),local_id)
						receive(id,"Food",tribute)
						_ledger().call("note_flow",String(civ.id),id,"Food",tribute,"tribute")
					WorldSimulation.economy._ledger("occupation_supply",delivered+tribute,id,String(civ.id),"Day %d: %.2f food delivered, %.2f tribute received from actual city stores" % [day,delivered,tribute])
		)

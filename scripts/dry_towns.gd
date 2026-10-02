extends RefCounted
## A TOWN WITH NO WATER IS LEFT, by one rule for every people.
##
## Each day, after the towns' own days (civilization_day.gd): a town whose own
## water ledger has found no drinking source within reach (the 6 km of
## resource_system.site_water, read by the town's day) for LEAVE_AFTER_DAYS
## days running, and whose people are going short of water, is left. Its
## families go to the nearest town of theirs that has water. The people are
## moved, never lost: the town's share of the people goes to that town (the
## capital's count is what the other towns do not hold), the realm's count is
## unchanged, and the empty place is marked abandoned
## (settlement_model.abandoned), so its day is no longer run and nobody is
## sent there. With no town of theirs that has water, they stay. The god's
## people's leaving is told once in the Chronicle, in plain words.
## Static helpers; preload.

const AutoFounding:=preload("res://scripts/auto_founding.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
## Days running with no source within reach before the families leave.
const LEAVE_AFTER_DAYS:=7
## Below this share of the day's drinking water, people are going short
## (the town's water ledger, resource_system._process_water_flow).
const SHORT_OF_WATER:=0.98

## The day's check for the people in scope. Returns what was done:
## [{city_id, name, to, to_name, people, dry_days, distance_km}].
static func daily(day:int)->Array[Dictionary]:
	var left:Array[Dictionary]=[]
	for city:Dictionary in WorldSimulation.state.player_settlements:
		if bool(city.get("primary",false)) or not String(city.get("occupied_by","")).is_empty() or WorldSimulation.settlements.abandoned(city):continue
		var dry:=dry_days(city,day)
		if dry<LEAVE_AFTER_DAYS or not short_of_water(city):continue
		var done:=leave(city,day,dry)
		if not done.is_empty():left.append(done)
	return left

## Days running, to `day`, that the town's own water ledger found no source
## within reach; 0 when its last day found one or it has had no day yet.
static func dry_days(city:Dictionary,day:int)->int:
	var history:Array=_history(city)
	var first:=-1
	for index in range(history.size()-1,-1,-1):
		var entry:Dictionary=history[index]
		if float(entry.get("source_distance_km",-1.0))>=0.0:break
		first=int(entry.get("day",day))
	return 0 if first<0 else maxi(1,day-first+1)

## Whether the town's people went short of drinking water on its last day.
static func short_of_water(city:Dictionary)->bool:
	var history:Array=_history(city)
	return not history.is_empty() and float((history.back() as Dictionary).get("intake_ratio",0.0))<SHORT_OF_WATER

static func _history(city:Dictionary)->Array:
	var local:Variant=city.get("local_resources",{})
	if not local is Dictionary:return []
	var history:Variant=(local as Dictionary).get("water_history",[])
	return history if history is Array else []

## A town's own water ledger, its last day (the capital's is the people's).
static func _water(city:Dictionary)->Dictionary:
	if bool(city.get("primary",false)):return WorldSimulation.state.water_metrics
	var local:Variant=city.get("local_resources",{})
	var water:Variant=(local as Dictionary).get("water_metrics",{}) if local is Dictionary else {}
	return water if water is Dictionary else {}

## Whether a town of ours had a drinking source within reach on its last day.
static func has_water(city:Dictionary)->bool:
	return bool(_water(city).get("source_accessible",false))

## Whether a town with a source still went short of water on its last day.
static func short_today(city:Dictionary)->bool:
	return float(_water(city).get("intake_ratio",1.0))<SHORT_OF_WATER

## The town of ours the families go to: lived in, not held by another
## people, with a source within reach; the nearest that drank its fill, else
## the nearest with a source at all. {} when there is none.
static func nearest_with_water(city:Dictionary)->Dictionary:
	var model=WorldSimulation.settlements
	var here:Vector2=model._record_position(city)
	var best:Dictionary={}
	var best_rank:=Vector2(INF,INF)
	for other:Dictionary in WorldSimulation.state.player_settlements:
		if String(other.get("id",""))==String(city.get("id","")) or not String(other.get("occupied_by","")).is_empty() or model.abandoned(other):continue
		if not has_water(other):continue
		var rank:=Vector2(1.0 if short_today(other) else 0.0,here.distance_to(model._record_position(other)))
		if rank<best_rank:best=other;best_rank=rank
	return best

## The families of `city` leave for the nearest town of theirs with water.
## {} when no such town exists (they stay).
static func leave(city:Dictionary,day:int,dry:int)->Dictionary:
	var model=WorldSimulation.settlements
	var target:=nearest_with_water(city)
	if target.is_empty():return {}
	var state=WorldSimulation.state
	var share:=maxf(0.0,float(city.get("population_share",0.0)))
	var people:=roundi(share*maxf(0.0,float(state.population_exact)))
	# The same people, in another town: the realm's count does not change.
	city["population_share"]=0.0
	if not bool(target.get("primary",false)):target["population_share"]=maxf(0.0,float(target.get("population_share",0.0)))+share
	# What they own goes with them: the stores, the cargo on its way there,
	# and the named people who lived there (its leader steps down).
	var carried:=carry_stores(city,target)
	var redirected:=redirect_shipments(String(city.get("id","")),target)
	var named:=rehome(String(city.get("id","")),target)
	city["status"]="abandoned"
	city["abandoned_day"]=day
	city["abandoned_cause"]="no water"
	city["abandoned_to"]=String(target.get("id",""))
	# Its last day's report described people who are no longer there.
	city["resource_metrics"]={}
	state.settlement_network_revision+=1
	var km:=(model._record_position(city) as Vector2).distance_to(model._record_position(target))
	var done:={"city_id":String(city.get("id","")),"name":_name(city),"to":String(target.get("id","")),"to_name":_name(target),"people":people,"dry_days":dry,"distance_km":km,
		"carried":carried,"redirected":redirected,"named":named}
	_tell(done)
	return done

## Everything in the empty town's stores goes with its people: its food into
## the other town's food by the food system's own paths (so fresh and stored
## food and the store's total stay one count), every other good onto that
## town's piles. {good: amount carried}.
static func carry_stores(city:Dictionary,target:Dictionary)->Dictionary:
	var model=WorldSimulation.settlements
	var goods:Dictionary=model.with_city_resources(String(city.get("id","")),func()->Dictionary:
		var out:={}
		var food:float=WorldSimulation.food.take_for_levy(WorldSimulation.food.total_stored())
		if food>0.0:out["Food"]=food
		var piles:Dictionary=WorldSimulation.state.resource_stockpiles
		for good:String in piles.keys():
			var amount:=float(piles[good])
			if good=="Food" or amount<=0.0:continue
			out[good]=amount
			piles[good]=0.0
		return out
	)
	model.with_city_resources(String(target.get("id","")),func()->void:
		var piles:Dictionary=WorldSimulation.state.resource_stockpiles
		for good:String in goods:
			if good=="Food":WorldSimulation.food.receive_external_food(float(goods[good]))
			else:piles[good]=float(piles.get(good,0.0))+float(goods[good])
	)
	return goods

## Cargo on the road to the empty town goes on to `target` instead (rail
## cargo is turned at its station: settlement_model.receive_city_trade_arrivals).
## Returns how many loads were turned.
static func redirect_shipments(city_id:String,target:Dictionary)->int:
	var turned:=0
	for shipment:Dictionary in WorldSimulation.state.city_trade_shipments:
		if String(shipment.get("destination_id",""))!=city_id or String(shipment.get("transport_mode",""))=="rail":continue
		shipment["destination_id"]=String(target.get("id",""))
		shipment["destination_name"]=_name(target)
		turned+=1
	return turned

## The named people of the empty town live in `target` from now: the cast
## (its leader steps down without blame) and, for the god's people, those
## the court has met.
static func rehome(city_id:String,target:Dictionary)->int:
	var to_id:=String(target.get("id",""))
	var moved:=0
	if WorldSimulation.government!=null:moved+=int(WorldSimulation.government.rehome_from(city_id,to_id))
	if WorldSimulation.state==GameState:
		# Loaded, not preloaded: the calendar's scripts stay free of the court's.
		for person:Variant in load("res://scripts/court_persons.gd").people():
			if not person is Dictionary or String((person as Dictionary).get("settlement_id",""))!=city_id:continue
			person["settlement_id"]=to_id
			person["village"]=_name(target)
			moved+=1
	return moved

static func _name(city:Dictionary)->String:
	if bool(city.get("primary",false)):return String(WorldSimulation.state.settlement_name)
	return String(city.get("name","the town"))

## The Chronicle line (the god's people only; chronicle.gd keeps no other).
static func _tell(done:Dictionary)->Dictionary:
	return preload("res://scripts/chronicle.gd").record({"key":"town_left:%s" % String(done.city_id),
		"title":"%s abandoned: no water" % String(done.name),
		"text":words(done),
		# Told each time, never folded into a tally: the ruler must hear it.
		"tier":"notice","kind":"settlement","domain":"settlement","priority":true,
		"action":{"kind":"section","section":"settlement","sub":0}})

## "Ashleyton had no drinking water within 6 km for 9 days. Its 12 people
## have gone to Keansburg, a day's walk away, where there is water.
## Ashleyton stands empty."
static func words(done:Dictionary)->String:
	var name:=String(done.name)
	var people:=int(done.people)
	var dry:=int(done.dry_days)
	var lack:="%s had no drinking water within 6 km for %d %s." % [name,dry,"day" if dry==1 else "days"]
	if people<1:return "%s Nobody was left there. %s stands empty." % [lack,name]
	var who:="Its one person has" if people==1 else "Its %d people have" % people
	var stores:=" They took its stores with them." if not (done.get("carried",{}) as Dictionary).is_empty() else ""
	return "%s %s gone to %s, %s away, where there is water.%s %s stands empty." % [lack,who,String(done.to_name),_walk(float(done.distance_km)),stores,name]

## "less than a day's walk", "a day's walk", "three days' walk".
static func _walk(km:float)->String:
	var days:=km/AutoFounding.WALK_KM_PER_DAY
	if days<0.75:return "less than a day's walk"
	if days<1.5:return "a day's walk"
	return "%s days' walk" % EraWords.count_word(roundi(days))

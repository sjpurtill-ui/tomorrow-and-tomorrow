extends RefCounted
## A LEVY'S DAYS, AS THE ENGINE WILL RUN THEM: when the weapons the workshops
## make are in the store, and when the drill ends with them in hand.
##
## The court says these numbers when a levy is raised (home_orders.gd), and the
## order's card shows them while it drills (order_probes.gd); neither keeps a
## number of its own. Each day here is the engine's own day, in its order
## (civilization_day.gd), run forward on copies of today's ledger:
##   materials  the town's own cutters and diggers bring in what they brought
##              in today (the deposits' delivered_today); our other towns send
##              what the city trade sends (settlement_model.process_city_trade):
##              when the store is below its floor, up to its target, from the
##              nearest town with some to spare, after the days on the road;
##              shipments already on the road arrive on their day.
##   workshops  every job as _process_equipment_production_day runs it: lines in
##              their order, sharing the crafting hands by weight, taking their
##              materials from the store item by item, with soldiers who wait for
##              simple gear helping to make it; batches with their materials set
##              aside.
##   drill      every order in drill as _process_training_day runs it: the
##              instructors' pace shared by everyone who attends (fewer as the
##              hurt leave and others finish), the food for it, the share of
##              each order's weapons in hand that day (the recruitment lines
##              take theirs first), and the injuries of drill.
## When nothing can start for want of one weapon's materials in store but
## they are on their way, the line the workshop officer starts the day they
## are in is counted too (officer_line).
## What the engine cannot know ahead (later orders, a battle, the leaders
## moving people between tasks, the seasons) is not guessed at: the numbers are
## today's, carried forward. Static helpers; preload.

const P:=preload("res://scripts/persistent_production.gd")
## Days looked ahead at most.
const HORIZON:=1095
const CITY_TRADE_GOODS:=["Food","Timber","Stone","Clay","Fiber Plants","Salt","Medicinal Plants","Flint","Copper Ore","Tin Ore","Iron Ore","Coal","Civilian Goods"]
## What a town keeps of a material before it sends any away (the city trade's
## smallest reserve).
const DONOR_RESERVE:=20.0

static func _mc()->Node:
	return WorldSimulation.military

# --------------------------------------------------------------------------
# Materials reaching the store
# --------------------------------------------------------------------------

static func _primary()->Dictionary:
	for city in WorldSimulation.state.player_settlements:
		if bool((city as Dictionary).get("primary",false)):return city
	return {}

## How the materials reach the store: {local:{m: per day}, road:{day: {m: q}},
## trade:{ready, floor, target, donors:{m: {spare, days, name}}}}.
static func supply(materials:Array)->Dictionary:
	var state=WorldSimulation.state
	var today:=int(state.elapsed_days)
	var local:Dictionary={}
	for deposit in state.resource_deposits:
		var m:=String((deposit as Dictionary).get("resource",""))
		if m in materials:local[m]=float(local.get(m,0.0))+maxf(0.0,float((deposit as Dictionary).get("delivered_today",0.0)))
	var primary:=_primary()
	var home:=String(primary.get("id",""))
	var road:Dictionary={}
	for shipment in state.city_trade_shipments:
		var s:Dictionary=shipment
		var m:=String(s.get("resource",""))
		if not m in materials or home=="" or String(s.get("destination_id",""))!=home:continue
		var day:=maxi(1,int(ceil(float(s.get("arrival_day",today))))-today)
		if not road.has(day):road[day]={}
		road[day][m]=float((road[day] as Dictionary).get(m,0.0))+float(s.get("quantity",0.0))
	return {"local":local,"road":road,"trade":_trade(primary,materials)}

## The city trade's rule for the store, read once: its floor and target, and
## for each material the nearest town with some to spare and its days on the
## road. ready=false with one town, or before leaders can organise deliveries.
static func _trade(primary:Dictionary,materials:Array)->Dictionary:
	var out:={"ready":false,"floor":0.0,"target":0.0,"donors":{}}
	var model:Node=WorldSimulation.settlements
	if primary.is_empty() or model==null or WorldSimulation.state.player_settlements.size()<2:return out
	var capacity:Dictionary=model.city_trade_capacity()
	if not bool(capacity.get("ready",false)):return out
	var people:=float(model._settlement_population(primary))
	out.ready=true
	out.floor=maxf(2.0,people*0.02)
	out.target=maxf(6.0,people*0.06)
	var here:Vector2=model._record_position(primary)
	for m:String in materials:
		if not m in CITY_TRADE_GOODS or m=="Food":continue
		var best:={}
		var nearest:=INF
		for city in WorldSimulation.state.player_settlements:
			var source:Dictionary=city
			if bool(source.get("primary",false)) or not String(source.get("occupied_by","")).is_empty():continue
			var there:Vector2=model._record_position(source)
			var distance:=here.distance_to(there)
			if distance>float(capacity.range_km) or distance>=nearest:continue
			var spare:=float((model._city_stores(source) as Dictionary).get(m,0.0))-DONOR_RESERVE
			if spare<=0.01:continue
			if not bool(model.known_route_assessment(there,here).get("known",false)):continue
			nearest=distance
			best={"spare":spare,"days":maxi(1,ceili(distance/maxf(0.1,float(capacity.speed_km_per_day)))),"name":String(source.get("name",""))}
		if not best.is_empty():out.donors[m]=best
	return out

# --------------------------------------------------------------------------
# The workshops, day by day
# --------------------------------------------------------------------------

## Every job's output, run forward from today: {stock: {item: [stock at the
## end of day 1, 2, ...]}} for the items asked for, the days run, and the
## supply used. Stops when every asked item is made or nothing more can be.
## officer_line {weapon, target}: a line the workshop officer starts for the
## weapon the day the store holds one weapon's materials (a line cannot start
## with less: persistent_production.gd startup_blockers).
static func workshops(items:Array,days:int=HORIZON,officer_line:Dictionary={})->Dictionary:
	var mc:=_mc()
	var state=WorldSimulation.state
	var jobs:Array=[]
	var materials:Array=[]
	var queue:Array=(mc.equipment_queue as Array).duplicate()
	if not officer_line.is_empty():
		var recipe:Dictionary=P.recipe(mc,String(officer_line.weapon))
		if not recipe.has("error"):
			var line:=recipe.duplicate(true)
			line.merge({"id":-1,"persistent":true,"target_stock":int(officer_line.get("target",0)),"paused":false,"allocation":1.0,"efficiency":0.20,"progress_days":0.0,"completed":0,"job_type":"production","_waits_to_start":true},true)
			queue.append(line)
	for job in queue:
		var j:Dictionary=(job as Dictionary).duplicate(true)
		var status:=String(P.state(mc,job)) if int(j.get("id",0))>=0 else "Working"
		j["_never"]=status.begins_with("Research unavailable") or status.begins_with("No operational")
		j["_licensed"]=preload("res://scripts/research_licenses.gd").uses_license(String(j.get("item","")))
		jobs.append(j)
		for m in (j.get("materials",{}) as Dictionary):
			if not m in materials:materials.append(m)
	var store:Dictionary={}
	for m in materials:store[m]=float(state.resource_stockpiles.get(m,0.0))
	var stock:Dictionary={}
	var waiting:Dictionary={}
	for j:Dictionary in jobs:
		var item:=String(j.get("item",""))
		if not stock.has(item):stock[item]=_stock(j)
		if not waiting.has(item) and String(j.get("job_type","production"))=="production":
			var w:Dictionary=mc.workshop.waiting_for(item)
			waiting[item]=int(w.recruits)+int(w.serving)
	for item in items:
		if not stock.has(item):stock[item]=int((mc.military_inventory as Dictionary).get(item,0))
	var flow:=supply(materials)
	var road:Dictionary=(flow.road as Dictionary).duplicate(true)
	var incoming:Dictionary={}
	for day in road:
		for m in road[day]:incoming[m]=float(incoming.get(m,0.0))+float(road[day][m])
	var trade:Dictionary=flow.trade
	var spare:Dictionary={}
	for m in (trade.donors as Dictionary):spare[m]=float(trade.donors[m].spare)
	var crafting:=maxf(0.0,float(mc._production_rate()))
	var health:=clampf(float(state.population_health),0.2,1.0)
	var adoption:=float(mc._adoption("workshop_standards"))
	var out:={"stock":{},"days":0,"supply":flow}
	for item in items:out.stock[item]=[]
	for t in range(1,days+1):
		# The town's own deliveries, then our other towns' (the city trade).
		for m in materials:store[m]=float(store[m])+float((flow.local as Dictionary).get(m,0.0))
		if road.has(t):
			for m in road[t]:
				store[m]=float(store.get(m,0.0))+float(road[t][m])
				incoming[m]=float(incoming.get(m,0.0))-float(road[t][m])
			road.erase(t)
		if bool(trade.ready):
			for m in spare:
				if float(store.get(m,0.0))>=float(trade.floor):continue
				var asked:=float(trade.target)-float(store.get(m,0.0))-float(incoming.get(m,0.0))
				if asked<=0.01 or float(spare[m])<=0.01:continue
				var sent:=minf(asked,float(spare[m]))
				spare[m]=float(spare[m])-sent
				var arrive:=t+int(trade.donors[m].days)
				if not road.has(arrive):road[arrive]={}
				road[arrive][m]=float((road[arrive] as Dictionary).get(m,0.0))+sent
				incoming[m]=float(incoming.get(m,0.0))+sent
		_workshop_day(jobs,store,stock,waiting,crafting,health,adoption)
		for item in items:(out.stock[item] as Array).append(int(stock.get(item,0)))
		out.days=t
		if _settled(jobs,store,items,stock,flow,road,trade,spare):break
	return out

## A job's item stock, as P.stock reads it.
static func _stock(job:Dictionary)->int:
	var mc:=_mc()
	match String(job.get("job_type","production")):
		"consumable":return int((mc.military_consumables as Dictionary).get(String(job.item),0))
		"transport":return int(WorldSimulation.state.resource_stockpiles.get(P.transport_stock(String(job.get("item",""))),0))
	return int((mc.military_inventory as Dictionary).get(String(job.get("item","")),0))

static func _eligible(job:Dictionary,store:Dictionary,stock:Dictionary)->bool:
	if bool(job.get("paused",false)) or bool(job.get("_never",false)):return false
	if not bool(job.get("persistent",false)):return true
	if bool(job.get("_waits_to_start",false)):
		for m in (job.get("materials",{}) as Dictionary):
			if float(store.get(m,0.0))<float(job.materials[m]):return false
		job.erase("_waits_to_start")
	if int(job.get("target_stock",0))>0 and int(stock.get(String(job.item),0))>=int(job.target_stock):return false
	for m in (job.get("materials",{}) as Dictionary):
		if float(job.materials[m])>0.0 and float(store.get(m,0.0))<=0.000000001:return false
	return true

## One day of _process_equipment_production_day, on the copies.
static func _workshop_day(jobs:Array,store:Dictionary,stock:Dictionary,waiting:Dictionary,crafting:float,health:float,adoption:float)->void:
	var weight_total:=0.0
	for j:Dictionary in jobs:
		if _eligible(j,store,stock):weight_total+=maxf(0.05,float(j.get("allocation",1.0)))
	for j:Dictionary in jobs:
		if not bool(j.get("persistent",false)):continue
		var work:=crafting*float(j.get("allocation",1.0))/maxf(0.05,weight_total)*float(j.get("efficiency",0.2))
		var item:=String(j.get("item",""))
		if not _eligible(j,store,stock):continue
		# Soldiers waiting for simple gear help to make it (workshop_steward.gd).
		if String(j.get("job_type","production"))=="production" and float(j.get("work_per_item",1.0))<=0.6 and not WorldSimulation.state.convoy_traveling:
			work+=maxf(0.0,float(int(waiting.get(item,0))-int(stock.get(item,0))))*0.25*health
		if bool(j.get("_licensed",false)):work*=0.65
		var per_item:=maxf(0.000001,float(j.get("work_per_item",1.0)))
		var units:=work/per_item
		if int(j.get("target_stock",0))>0:units=minf(units,maxf(0.0,int(j.target_stock)-int(stock.get(item,0))-float(j.get("progress_days",0.0))/per_item))
		var possible:=units
		for m in (j.get("materials",{}) as Dictionary):
			var cost:=float(j.materials[m])
			if cost>0.0:possible=minf(possible,maxf(0.0,float(store.get(m,0.0)))/cost)
		possible=maxf(0.0,possible)
		for m in (j.get("materials",{}) as Dictionary):store[m]=maxf(0.0,float(store.get(m,0.0))-float(j.materials[m])*possible)
		var progress:=float(j.get("progress_days",0.0))+possible*per_item
		var produced:=maxi(0,floori(progress/per_item+0.000000001))
		j["progress_days"]=maxf(0.0,progress-produced*per_item)
		stock[item]=int(stock.get(item,0))+produced
		if possible>0.0:j["efficiency"]=move_toward(float(j.get("efficiency",0.2)),1.0,0.0025*(0.65+adoption)*minf(1.0,possible/maxf(0.000001,units)))
	for index in range(jobs.size()-1,-1,-1):
		var j:Dictionary=jobs[index]
		if bool(j.get("persistent",false)) or not _eligible(j,store,stock):continue
		var efficiency:=clampf(float(j.get("efficiency",0.20)),0.10,1.0)
		var work:=crafting*maxf(0.05,float(j.get("allocation",1.0)))/maxf(0.05,weight_total)*efficiency
		if work<=0.0:continue
		j["progress_days"]=float(j.get("progress_days",0.0))+work
		j["efficiency"]=move_toward(efficiency,1.0,0.0025*(0.65+adoption))
		var per_item:=maxf(0.01,float(j.get("work_per_item",float(j.get("required_days",1.0))/maxf(1.0,float(j.get("count",1))))))
		var completed:=mini(int(j.get("count",0)),floori(float(j.progress_days)/per_item))
		var produced:=maxi(0,completed-int(j.get("completed",0)))
		j["completed"]=completed
		var item:=String(j.get("item",""))
		stock[item]=int(stock.get(item,0))+produced
		if completed>=int(j.get("count",0)):jobs.remove_at(index)

## Nothing asked for will change any more: every job that makes one is done,
## stopped at its target, or waits on materials that will never come.
static func _settled(jobs:Array,store:Dictionary,items:Array,stock:Dictionary,flow:Dictionary,road:Dictionary,trade:Dictionary,spare:Dictionary)->bool:
	for j:Dictionary in jobs:
		if not String(j.get("item","")) in items or bool(j.get("paused",false)) or bool(j.get("_never",false)):continue
		# A batch still at work, its materials already set aside.
		if not bool(j.get("persistent",false)):return false
		if int(j.get("target_stock",0))>0 and int(stock.get(String(j.item),0))>=int(j.target_stock):continue
		var starved:=false
		for m in (j.get("materials",{}) as Dictionary):
			if float(j.materials[m])<=0.0 or float(store.get(m,0.0))>=float(j.materials[m]):continue
			var on_road:=false
			for day in road:
				if float((road[day] as Dictionary).get(m,0.0))>0.0:on_road=true
			var coming:=float((flow.local as Dictionary).get(m,0.0))>0.0 or on_road or (bool(trade.ready) and float(spare.get(m,0.0))>0.01)
			if not coming:starved=true
		if not starved:return false
	return true

# --------------------------------------------------------------------------
# The levy
# --------------------------------------------------------------------------

## The training order `training_id` from today: {days (until fit to fight; -1
## when the drill stands still or does not end within the horizon), halted
## (why it stands still, "" when it moves), weapon, need, in_hand (now),
## all_day (the day every weapon is in hand: 0 already, -1 never), last
## (weapons in hand once the workshops stop), rate (weapons a day while they
## come), trade (the city trade's rule for the store), local (per day),
## per_item (materials a weapon takes)}. {} when there is no such order.
static func levy(training_id:int,officer_line:Dictionary={})->Dictionary:
	var mc:=_mc()
	var order:={}
	for entry in mc.training_queue:
		if int((entry as Dictionary).get("id",-1))==training_id:order=entry;break
	if order.is_empty():return {}
	var weapon:=String(order.get("weapon","improvised"))
	var need:=maxi(1,int(mc._equipment_required_for(String(order.get("unit","levy")),int(order.get("count",0)))))
	var reserved:=maxi(0,int(order.get("reserved_equipment",0)))
	# Weapons the recruitment lines take for their own bands first each day
	# (recruit_deploy.prepare runs before the drill).
	var lines_take:=0
	for entry in mc.training_queue:
		var o:Dictionary=entry
		if o.has("deployment_line") and String(o.get("weapon",""))==weapon:
			lines_take+=maxi(0,int(mc._equipment_required_for(String(o.get("unit","levy")),int(o.get("count",0))))-int(o.get("reserved_equipment",0)))
	var made:=workshops([weapon],HORIZON,officer_line)
	var stock_by_day:Array=(made.stock as Dictionary).get(weapon,[])
	var now:=int((mc.military_inventory as Dictionary).get(weapon,0))
	var out:={"days":-1,"halted":"","weapon":weapon,"need":need,"in_hand":mini(need,maxi(0,now-lines_take)+reserved),"all_day":-1,"last":0,"rate":0.0,
		"trade":(made.supply as Dictionary).get("trade",{}),"local":(made.supply as Dictionary).get("local",{}),"per_item":_recipe(weapon)}
	if int(out.in_hand)>=need:out.all_day=0
	for i in stock_by_day.size():
		if int(out.all_day)<0 and mini(need,maxi(0,int(stock_by_day[i])-lines_take)+reserved)>=need:out.all_day=i+1
	out.last=mini(need,maxi(0,(int(stock_by_day.back()) if not stock_by_day.is_empty() else now)-lines_take)+reserved)
	if int(out.all_day)>0:out.rate=float(need-int(out.in_hand))/float(out.all_day)
	# The drill, as _process_training_day runs it.
	var drill:=_drill(training_id,weapon,stock_by_day)
	out.days=int(drill.days)
	out.halted=String(drill.halted)
	return out

## The days until the order `training_id` is fit to fight, as
## _process_training_day runs them for everyone in drill: the instructors'
## pace shared by all who attend (fewer as the injured leave and others
## finish), the food for it, each order's weapons in hand that day (the
## newest order first, after the recruitment lines take theirs), and the
## injuries of drill. {days (-1 when it stands still or outlasts the
## horizon), halted}.
static func _drill(training_id:int,weapon:String,stock_by_day:Array)->Dictionary:
	var mc:=_mc()
	var state=WorldSimulation.state
	var policy:Dictionary=mc.training_staff.policy("army")
	var intake:=float(policy.get("intake",1.0))
	var food:=float(mc.training_staff.instruction_food())
	if intake<=0.0:return {"days":-1,"halted":"the army's training is suspended"}
	if food<=0.0:return {"days":-1,"halted":"there is no food to spare for drill"}
	var paused_lines:Dictionary={}
	for line:Dictionary in mc.recruit_deploy.data.lines:
		if bool(line.paused):paused_lines[int(line.id)]=true
	var orders:Array=[]
	for entry in mc.training_queue:orders.append((entry as Dictionary).duplicate(true))
	var condition:=clampf(float(state.population_health)*0.50+float(state.food_security)*0.25+float(mc._population_shelter_condition())*0.25,0.0,1.0)
	var risk:=float(mc._training_injury_risk_multiplier())
	var inventory:Dictionary=(mc.military_inventory as Dictionary).duplicate()
	var taken:=0
	for t in range(1,HORIZON+1):
		# The workshops' day: the weapons made so far, less what the
		# recruitment lines took into their own bands' hands.
		if t-1<stock_by_day.size():inventory[weapon]=maxi(0,int(stock_by_day[t-1])-taken)
		elif not stock_by_day.is_empty():inventory[weapon]=maxi(0,int(stock_by_day.back())-taken)
		# recruit_deploy.prepare: a line's orders take their weapons first.
		for o:Dictionary in orders:
			if not o.has("deployment_line") or paused_lines.has(int(o.deployment_line)):continue
			var w:=String(o.get("weapon","improvised"))
			var take:=mini(maxi(0,int(mc._equipment_required_for(String(o.get("unit","levy")),int(o.get("count",0))))-int(o.get("reserved_equipment",0))),maxi(0,int(inventory.get(w,0))))
			if take<=0:continue
			o["reserved_equipment"]=int(o.get("reserved_equipment",0))+take
			inventory[w]=int(inventory.get(w,0))-take
			if w==weapon:taken+=take
		var attending:=0
		for o:Dictionary in orders:
			if paused_lines.has(int(o.get("deployment_line",-1))):continue
			if (o.has("deployment_line") or o.has("build_batch")) and float(o.progress_days)>=float(o.required_days):continue
			attending+=int(o.count)
		if attending<=0:return {"days":-1,"halted":"nobody is in drill"}
		var rations:=float(attending)*0.18*intake
		var fed:=clampf(minf(rations,food)/maxf(0.001,rations),0.0,1.0)
		var rate:=float(mc._effective_training_rate(attending))*intake*fed
		if rate<=0.0:return {"days":-1,"halted":"nobody can be drilled now"}
		var budget:=inventory.duplicate()
		for index in range(orders.size()-1,-1,-1):
			var o:Dictionary=orders[index]
			if o.has("deployment_line") and paused_lines.has(int(o.deployment_line)):continue
			if (o.has("deployment_line") or o.has("build_batch")) and float(o.progress_days)>=float(o.required_days):continue
			var w:=String(o.get("weapon","improvised"))
			var reserved:=maxi(0,int(o.get("reserved_equipment",0)))
			var available:=(0 if o.has("deployment_line") else maxi(0,int(budget.get(w,0))))+reserved
			var required_examples:=int(mc._equipment_required_for(String(o.get("unit","levy")),int(o.get("count",1))))
			var examples:=mini(maxi(1,required_examples),available)
			budget[w]=maxi(0,available-examples-reserved)
			var access:=clampf(float(examples)/maxf(1.0,float(required_examples)),0.0,1.0)
			var floor_share:=0.55 if w=="improvised" else 0.25
			var increment:=rate*(floor_share+(1.0-floor_share)*access)
			if o.has("deployment_line"):
				var manpower:=float(o.count)/maxi(1,int(o.get("target_count",o.count)))
				increment=minf(increment,maxf(0.0,float(o.required_days)*minf(manpower,access)-float(o.progress_days)))
			o["progress_days"]=minf(float(o.required_days),float(o.get("progress_days",0.0))+increment)
			var intensity:=float({"levy":0.75,"line_infantry":1.0,"skirmisher":0.90,"cavalry":1.20}.get(String(o.get("unit","levy")),1.0))
			o["injury_accumulator"]=float(o.get("injury_accumulator",0.0))+float(o.count)*0.0012*intensity*(1.35-condition*0.55)*risk
			var injuries:=mini(int(o.count),floori(float(o.injury_accumulator)))
			o["injury_accumulator"]=float(o.injury_accumulator)-float(injuries)
			o["count"]=int(o.count)-injuries
			if int(o.count)<=0:
				if int(o.get("id",-1))==training_id:return {"days":-1,"halted":"every one of them was hurt in drill"}
				orders.remove_at(index)
				continue
			if float(o.progress_days)<float(o.required_days):continue
			if o.has("build_batch") or o.has("deployment_line"):continue
			if int(o.get("id",-1))==training_id:return {"days":t,"halted":""}
			orders.remove_at(index)
	return {"days":-1,"halted":""}

## Are the materials this weapon takes on their way to the store: brought in
## by our own people, already on the road, or sent by our other towns when
## the store runs short?
static func coming(weapon:String)->bool:
	var recipe:=_recipe(weapon)
	var flow:=supply(recipe.keys())
	for m in recipe:
		if float(recipe[m])<=0.0 or float(WorldSimulation.state.resource_stockpiles.get(m,0.0))>=float(recipe[m]):continue
		var on_road:=false
		for day in (flow.road as Dictionary):
			if float((flow.road[day] as Dictionary).get(m,0.0))>0.0:on_road=true
		if not (float((flow.local as Dictionary).get(m,0.0))>0.0 or on_road or (bool(flow.trade.ready) and (flow.trade.donors as Dictionary).has(m))):return false
	return true

## Materials one weapon takes {material: amount}.
static func _recipe(weapon:String)->Dictionary:
	var recipe:Dictionary=_mc()._equipment_recipe(weapon)
	return (recipe.get("materials",{}) as Dictionary).duplicate()

## How many weapons the store's materials make now (the scarcest material).
static func store_makes(weapon:String)->int:
	var made:=1000000
	for m in _recipe(weapon):
		var cost:=float(_recipe(weapon)[m])
		if cost>0.0:made=mini(made,floori(float(WorldSimulation.state.resource_stockpiles.get(m,0.0))/cost+0.000001))
	return made if made<1000000 else 0

## The material that holds the weapons back: the one the store has fewest
## weapons' worth of. "" when none is short for `count` of them.
static func scarce(weapon:String,count:int)->String:
	var worst:="";var least:=INF
	for m in _recipe(weapon):
		var cost:=float(_recipe(weapon)[m])
		if cost<=0.0:continue
		var makes:=float(WorldSimulation.state.resource_stockpiles.get(m,0.0))/cost
		if makes<float(count) and makes<least:least=makes;worst=String(m)
	return worst

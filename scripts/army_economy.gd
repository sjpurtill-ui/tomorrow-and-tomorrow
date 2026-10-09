extends RefCounted
## WHAT THE ARMY COSTS THE PEOPLE, in the engine's own numbers: the War
## screen's cost card and the army size buttons' tips. Every figure is read
## from the rule the engine applies (named beside it), for the army as it is
## and for the army with `extra` more under arms:
##   hands     who leaves which work: with the work set by hand the watch
##             takes from the biggest task, one person at a time
##             (manual_work.gd move); with the leaders sharing it out, from
##             every task in its own proportion (watch_military.gd move);
##   food      the food those taken from the food getters no longer bring
##             (today's harvest per food getter, food_system.gd), the extra
##             ration each soldier eats (task_impact.gd EXERTION), against
##             what the people bring in and eat a day;
##   births    past the watch the people can spare, every one more costs
##             births, work and weariness as an extra learner does
##             (society_model.gd watch_free, watch_upkeep_for);
##   pay       a soldier's pay against what the realm brings in
##             (realm_purse.gd line_cost_per_day);
##   gear      the kits the army's makeup still lacks (army_makeup.gd
##             wanted) and the makers' arms (weapons_stock.gd), in workshop
##             days and materials;
##   carts     the baggage train the carriers want (cart_supply_planner.gd),
##             in carts and materials.
## Static; preload.

const Makeup:=preload("res://scripts/army_makeup.gd")
const Manual:=preload("res://scripts/manual_work.gd")
const Purse:=preload("res://scripts/realm_purse.gd")
const Society:=preload("res://scripts/society_model.gd")
const Impact:=preload("res://scripts/task_impact.gd")
const Stock:=preload("res://scripts/weapons_stock.gd")
const Carts:=preload("res://scripts/cart_supply_planner.gd")
const P:=preload("res://scripts/persistent_production.gd")

const ROLE_WORDS:={"Food":"food","Survey":"searching","Extraction":"cutting and digging","Construction":"building","Crafting":"making","Logistics":"carrying","Knowledge":"learning","Administration":"keeping","Defense":"the watch"}


static func _state()->Variant:
	return WorldSimulation.state

static func _watch()->GDScript:
	return load("res://scripts/watch_military.gd") as GDScript


## Who leaves which work when `n` more join the watch: {role: people}.
static func donors(n:int)->Dictionary:
	var out:={}
	if n<=0:return out
	var state=_state()
	if WorldSimulation.actor_id=="player" and Manual.manual():
		var now:Dictionary=Manual.whole_people(Manual.split(),Manual.able())
		# The biggest task gives one at a time: whole runs at once where one
		# task stands above the next (manual_work.gd move, _most).
		var left:=n
		while left>0:
			var top:=Manual._most(now,"Defense")
			if top=="":break
			var next:=0
			for role:String in now:
				if role!="Defense" and role!=top:next=maxi(next,int(now[role]))
			var step:=mini(left,maxi(1,int(now[top])-next))
			now[top]=int(now[top])-step;out[top]=int(out.get(top,0))+step;left-=step
		return out
	var others:=0.0
	for role:String in state.population_allocations:
		if role!="Defense":others+=maxf(0.0,float(state.population_allocations[role]))
	if others<=0.0:return out
	var given:=0
	for role:String in state.population_allocations:
		if role=="Defense":continue
		var share:=roundi(float(n)*maxf(0.0,float(state.population_allocations[role]))/others)
		if share>0:out[role]=share;given+=share
	# Rounding: the biggest task makes up the difference.
	if given!=n and not out.is_empty():
		var top:=""
		for role in out:if top=="" or int(out[role])>int(out[top]):top=role
		out[top]=maxi(0,int(out[top])+n-given)
	return out


## Rations a food getter brings in a day (today's harvest, food_system.gd).
static func per_getter()->float:
	var metrics:Dictionary=_state().simulation_metrics
	var getters:=float(metrics.get("food_workers",0.0))
	return float(metrics.get("food_production",0.0))/getters if getters>0.0 else 0.0


## The army's cost, now (extra 0) or with `extra` more under arms. Every
## amount a day unless named: {watch, people, able, one_in, from (donors),
## food_lost, food_eaten, food_in, food_need, food_net, births (fewer in
## 100, past the free watch), free, over, pay_season, income_season,
## gear [{item, name, sets, days, materials}], gear_days, gear_materials,
## carts, carts_materials}.
static func cost(extra:int=0)->Dictionary:
	var state=_state()
	var mc=WorldSimulation.military
	var watch:=int(_watch().call("manpower",mc))+maxi(0,extra)
	var able:=maxi(1,int(state.able_population()))
	var metrics:Dictionary=state.simulation_metrics
	var out:={"watch":watch,"people":int(state.population_total),"able":able,"one_in":roundi(float(able)/float(watch)) if watch>0 else 0}
	# Hands: those already on watch came from their work too; the extra from
	# the tasks that would give them.
	var from:=donors(extra)
	out.from=from
	var lost:=float(from.get("Food",0))*per_getter()
	out.food_lost=lost
	out.food_eaten=float(watch)*float(Impact.EXERTION.Defense)
	out.food_in=float(metrics.get("food_production",0.0))-lost
	out.food_need=float(metrics.get("food_consumption",0.0))+float(maxi(0,extra))*float(Impact.EXERTION.Defense)
	out.food_net=float(out.food_in)-float(out.food_need)
	out.food_days=float(metrics.get("food_days",0.0))
	# Past the free watch: fewer births (and work and weariness).
	var free:=Society.watch_free()
	var over:=maxf(0.0,float(watch)-float(free))
	out.free=free;out.over=over
	out.births=-Society.watch_upkeep_for("conception_support",over/float(able))*100.0
	# Pay against the realm's income, a season.
	var oph:=Purse.output_per_head()
	out.pay_season=(Purse.line_cost_per_day("army",oph)+float(maxi(0,extra))*Purse.PAY_SOLDIER*oph)*Purse.SEASON_DAYS
	out.income_season=Purse.output_per_day()*Purse.SEASON_DAYS
	# Gear: the kits the makeup lacks, and for the extra men theirs.
	var sets:=Makeup.wanted(mc) if Makeup.chosen(mc) else {}
	if extra>0:
		var shares:=Makeup.shares(mc)
		for id:String in shares:
			if float(shares[id])<=0.0:continue
			var kit:=Makeup.kit_for(mc,id)
			if kit.is_empty() or String(kit.item)=="improvised":continue
			var men:=roundi(float(shares[id])*float(extra))
			if men<=0:continue
			sets[String(kit.item)]=int(sets.get(String(kit.item),0))+int(mc.simulator.equipment_required_for_weapon(String(kit.item),men))
	var gear:Array=[];var gear_days:=0.0;var gear_materials:={}
	for item:String in sets:
		var n:=int(sets[item])
		if n<=0:continue
		var row:={"item":item,"name":P.product_name(item),"sets":n,"days":0.0,"materials":{}}
		if item in Stock.made_items(mc):
			# The makers' own sets (weapons_stock.gd cost_per_fighter).
			var each:Dictionary=Stock.cost_per_fighter()
			row.days=float(each.get("maker_days",0.0))*n
			for m:String in (each.get("materials",{}) as Dictionary):row.materials[m]=float(each.materials[m])*n
		else:
			var recipe:=P.recipe(mc,item)
			if recipe.has("error"):continue
			row.days=float(recipe.work_per_item)*n
			for m:String in recipe.materials:row.materials[m]=float(recipe.materials[m])*n
		gear.append(row);gear_days+=float(row.days)
		for m:String in row.materials:gear_materials[m]=float(gear_materials.get(m,0.0))+float(row.materials[m])
	out.gear=gear;out.gear_days=gear_days;out.gear_materials=gear_materials
	# Carts: the baggage train for the army (cart_supply_planner READY_PER),
	# never more than there are drivers for.
	var held:=int(float(state.resource_stockpiles.get("Transport Carts",0.0)))
	var serving:=int(mc._mobilized_count())+maxi(0,extra)
	var want:=mini(int(state.population_allocations.get("Logistics",0)),ceili(float(serving)/Carts.READY_PER))
	var carts:=maxi(0,want-held)
	out.carts=carts;out.carts_held=held
	var cart_materials:={}
	var cart:=P.recipe(mc,"transport_cart")
	if carts>0 and not cart.has("error"):
		for m:String in cart.materials:cart_materials[m]=float(cart.materials[m])*carts
	out.carts_materials=cart_materials
	out.carts_days=float(cart.get("work_per_item",0.0))*carts if not cart.has("error") else 0.0
	return out


## The difference between two readings, for the "one step more" column.
static func step_words(now:Dictionary,more:Dictionary)->PackedStringArray:
	var lines:=PackedStringArray()
	var added:=int(more.watch)-int(now.watch)
	if added<=0:return lines
	lines.append("%s more under arms, taken from %s." % [_grouped(added),from_words(more.from)])
	var food:=float(more.food_net)-float(now.food_net)
	if absf(food)>=0.5:lines.append("Food: %s rations a day (%s brought in, %s more eaten)." % [_signed(food),_signed(-float(more.food_lost)),_grouped(roundi(float(more.food_eaten)-float(now.food_eaten)))])
	var births:=float(more.births)-float(now.births)
	if births>=0.05:lines.append("Births: %s in 100 fewer (past the %s the people can spare)." % [_one(births),_grouped(int(more.free))])
	var pay:=float(more.pay_season)-float(now.pay_season)
	if pay>=0.5:lines.append("Pay: %s more a season." % Purse.amount_text(pay))
	var days:=float(more.gear_days)-float(now.gear_days)
	if days>=0.5:lines.append("Gear: about %s more maker-days." % _grouped(roundi(days)))
	var carts:=int(more.carts)-int(now.carts)
	if carts>0:lines.append("Carts: %s more to build." % _grouped(carts))
	return lines


## "food (620) and making (55)": who gave the hands.
static func from_words(from:Dictionary)->String:
	if from.is_empty():return "nobody"
	var keys:=from.keys()
	keys.sort_custom(func(a:String,b:String)->bool:return int(from[a])>int(from[b]))
	var parts:=PackedStringArray()
	for role:String in keys.slice(0,4):parts.append("%s (%s)" % [String(ROLE_WORDS.get(role,role.to_lower())),_grouped(int(from[role]))])
	if keys.size()>4:parts.append("others")
	return ", ".join(parts)


## "Timber 1,200 · Iron Ore 300": the biggest materials first.
static func materials_words(materials:Dictionary,limit:=3)->String:
	if materials.is_empty():return ""
	var keys:=materials.keys()
	keys.sort_custom(func(a:String,b:String)->bool:return float(materials[a])>float(materials[b]))
	var parts:=PackedStringArray()
	for m:String in keys.slice(0,limit):parts.append("%s %s" % [String(WorldSimulation.resources.display_name(m)) if WorldSimulation.resources!=null else m,_grouped(ceili(float(materials[m])))])
	return " · ".join(parts)


static func _grouped(n:int)->String:
	return preload("res://scripts/hud/era_words.gd").grouped(n)

static func _signed(v:float)->String:
	return ("+" if v>=0.0 else "−")+_grouped(roundi(absf(v)))

static func _one(v:float)->String:
	return "%.1f" % v


## One fighter's kit of `item` for `unit`, in words: "a set: 0.8 workshop
## days · Timber 0.5 · Fiber Plants 0.3", or "" when it costs nothing.
static func kit_words(unit:String,item:String)->String:
	var mc=WorldSimulation.military
	if item=="" or item=="improvised" or mc==null:return ""
	var per:=float(mc.simulator.equipment_required_for_weapon(item,100))/100.0
	var days:=0.0;var materials:={}
	if item in Stock.made_items(mc):
		var each:Dictionary=Stock.cost_per_fighter()
		days=float(each.get("maker_days",0.0))
		materials=each.get("materials",{})
	else:
		var recipe:=P.recipe(mc,item)
		if recipe.has("error"):return ""
		days=float(recipe.work_per_item);materials=recipe.materials
	var parts:=PackedStringArray(["%.1f maker-days" % (days*per)])
	var keys:=materials.keys()
	keys.sort_custom(func(a:String,b:String)->bool:return float(materials[a])>float(materials[b]))
	for m:String in keys.slice(0,3):parts.append("%s %.1f" % [String(WorldSimulation.resources.display_name(m)) if WorldSimulation.resources!=null else m,float(materials[m])*per])
	return "Each one's kit: "+" · ".join(parts)

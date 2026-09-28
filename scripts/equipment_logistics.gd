extends RefCounted
## What the bands hold and what they still need, per kind of equipment: in
## store, missing on serving formations, owed to recruits in training, and
## asked for by called-up levies and requested recruitment. One reading shared
## by the Production screen, the Warriors dock and the supply map. It reads
## MilitaryCampaign state and changes nothing.
##
## Needs mirror WorkshopSteward: fielded and requisitioned gear follow
## army_demands(); training follows waiting_for() (every cohort still in
## drill, net of the sets reserved for it). So the Quartermaster, this screen
## and the other docks agree on what is short.
##
## API (static; host defaults to the MilitaryCampaign autoload):
##   rows(host, snapshot) -> Array[Dictionary], one per kind in play:
##     {item, name, category, stock, needed, deficit, fielded, training,
##      requisitioned, damaged, repairing, repair_status, making_per_day,
##      days_to_cover (-1 = not covered), lines:[ids], for:[{who,count,where}]}
##   row(item, host) / deficit(item, host)
##   needs(host) -> {item:{fielded,training,requisitioned,for:{who:{who,count,where}}}}
##   needs_by_force(host) -> [{force_id (0 = home), who, where, position, items:{item:missing}}]
##   line_badge(line, host, needs) -> {} or {text:"for Rovik's levy", tip, count}
##   material_trend(resource) -> {} or {per_day, days}; note_stores() samples.

const P:=preload("res://scripts/persistent_production.gd")
const Upkeep:=preload("res://scripts/routine_military_upkeep.gd")
const Joint:=preload("res://scripts/joint_force_catalog.gd")
const Units:=preload("res://scripts/military_unit_catalog.gd")
const CATEGORY_ORDER:=["weapons","ammunition","carts","boats","aircraft"]
## Days of store history kept for the material trend.
const TREND_DAYS:=7

static func _host(host:Node)->Node:
	return host if host!=null else MilitaryCampaign

# --- Kinds ----------------------------------------------------------------------

static func category(item:String)->String:
	var joint:=Joint.by_equipment(item)
	if not joint.is_empty():return "boats" if String(joint.domain)=="navy" else "aircraft"
	if item=="transport_cart":return "carts"
	if MilitaryCampaign.CONSUMABLE_KNOWLEDGE.has(item):return "ammunition"
	return "weapons"

static func stock(item:String,host:Node=null)->int:
	host=_host(host)
	match category(item):
		"ammunition":return int(host.military_consumables.get(item,0))
		"carts":return int(WorldSimulation.state.resource_stockpiles.get("Transport Carts",0))
	return int(host.military_inventory.get(item,0))

## Who uses it, in a few words: "levy, spearmen", "bows", "patrol, 4 crew".
static func arms(item:String,limit:int=2)->String:
	var joint:=Joint.by_equipment(item)
	if not joint.is_empty():
		var purpose:=String(joint.get("purpose","")).get_slice(".",0).get_slice(",",0).to_lower().strip_edges()
		if purpose.length()>18:purpose=String(joint.get("mission","")).to_lower()
		return "%s, %d crew" % [purpose,int(joint.get("crew",0))]
	if item=="transport_cart":return "carries supplies"
	var users:Array[String]=[]
	if MilitaryCampaign.CONSUMABLE_KNOWLEDGE.has(item):
		for weapon:String in MilitaryCampaign.EQUIPMENT_KNOWLEDGE:
			if String(MilitaryCampaign._ammunition_type_for(weapon))==item:users.append(P.product_name(weapon).to_lower())
		return ("feeds "+", ".join(users.slice(0,limit))) if not users.is_empty() else ""
	for unit:Dictionary in Units.ARCHETYPES.values():
		if item in unit.get("equipment",[]):
			var label:=String(unit.get("label","")).to_lower()
			if not label.is_empty() and label not in users:users.append(label)
	return ", ".join(users.slice(0,limit))

# --- Needs ----------------------------------------------------------------------

static func _war_leader()->String:
	var orders=load("res://scripts/army_orders.gd")
	return String(orders.war_leader_name()) if orders!=null else ""

static func levy_name()->String:
	var leader:=_war_leader()
	return ("%s's levy" % leader) if not leader.is_empty() else "the levy at home"

static func force_name(record:Dictionary)->String:
	## "Tarn's war party", or the band's own name when its leader is nameless.
	var orders=load("res://scripts/army_orders.gd")
	var general:=String(orders.general_name(record)) if orders!=null else ""
	var troops:=int(record.get("troops",0))
	var noun:=String(preload("res://scripts/hud/army_marks.gd").noun(maxi(1,troops),preload("res://scripts/hud/era_words.gd").stage()))
	if not general.is_empty():return "%s's %s" % [general,noun]
	var name:=String(record.get("name","")).strip_edges()
	return name if not name.is_empty() else "our "+noun

static func _add(result:Dictionary,item:String,part:String,count:int,who:String,where:String)->void:
	if count<=0 or item.is_empty():return
	var entry:Dictionary=result.get(item,{"fielded":0,"training":0,"requisitioned":0,"for":{}})
	entry[part]=int(entry[part])+count
	var groups:Dictionary=entry["for"]
	var group:Dictionary=groups.get(who,{"who":who,"count":0,"where":where})
	group.count=int(group.count)+count
	groups[who]=group
	result[item]=entry

static func _formation_needs(host:Node,formation:Dictionary)->Dictionary:
	## {weapon:missing sets, ammunition:missing rounds} for one formation.
	var result:={}
	var item:=String(formation.get("weapon","improvised"))
	var required:=maxi(0,int(formation.get("equipment_required",formation.get("count",0))))
	var missing:=maxi(0,required-int(formation.get("equipment",0)))
	if missing>0:result[item]=missing
	var ammunition:=String(host._ammunition_type_for(item))
	if not ammunition.is_empty():
		var rounds:=maxi(0,int(formation.get("ammunition_required",host._ammunition_required_for(item,required)))-int(formation.get("ammunition",0)))
		if rounds>0:result[ammunition]=int(result.get(ammunition,0))+rounds
	return result

static func needs(host:Node=null)->Dictionary:
	host=_host(host)
	var result:={}
	if host==null:return result
	var levy:=levy_name()
	var explicit:=false
	for template:Dictionary in host.army_templates:
		if not bool(template.get("recruitment_requested",false)):continue
		explicit=true
		var quote:Dictionary=host.template_training_quote(int(template.get("template_id",-1)))
		var name:=String(template.get("name","")).strip_edges()
		for item:String in quote.get("equipment",{}):
			_add(result,item,"requisitioned",int(quote.equipment[item]),name if not name.is_empty() else "the new recruits","called_up")
	for order:Dictionary in host.training_queue:
		var item:=String(order.get("weapon","improvised"))
		var missing:=maxi(0,host._equipment_required_for(String(order.get("unit","levy")),int(order.get("count",0)))-int(order.get("reserved_equipment",0)))
		_add(result,item,"training",missing,levy if bool(order.get("automated_basic",false)) else "the recruits","training")
	if not explicit:
		var gap:=maxi(0,host._home_garrison_target()-int(host.home_army.get("troops",0))-host._automatic_basic_trainees())
		gap=mini(gap,maxi(0,host.training_capacity()-host._queued_trainees()))
		_add(result,"improvised","requisitioned",gap,levy,"called_up")
	for formation:Dictionary in host.home_army.get("formations",[]):
		var missing:=_formation_needs(host,formation)
		for item:String in missing:_add(result,item,"fielded",int(missing[item]),levy,"home")
	for army:Dictionary in host.field_armies:
		var who:=force_name(army)
		for formation:Dictionary in army.get("formations",[]):
			var missing:=_formation_needs(host,formation)
			for item:String in missing:_add(result,item,"fielded",int(missing[item]),who,"field")
	for force:Dictionary in host.occupation_forces:
		var who:="the garrison at "+String(force.get("region_name","the held town")).capitalize()
		for formation:Dictionary in force.get("formations",[]):
			var missing:=_formation_needs(host,formation)
			for item:String in missing:_add(result,item,"fielded",int(missing[item]),who,"garrison")
	return result

static func needs_by_force(host:Node=null)->Array[Dictionary]:
	## Missing gear per force, for the supply map: the levy at home (force_id
	## 0), each field army (its army_id) and each garrison (its region_id).
	host=_host(host)
	var result:Array[Dictionary]=[]
	if host==null:return result
	var forces:Array=[{"force_id":0,"who":levy_name(),"where":"home","record":host.home_army}]
	for army:Dictionary in host.field_armies:forces.append({"force_id":int(army.get("army_id",0)),"who":force_name(army),"where":"field","record":army})
	for force:Dictionary in host.occupation_forces:forces.append({"force_id":String(force.get("region_id","")),"who":"the garrison at "+String(force.get("region_name","the held town")).capitalize(),"where":"garrison","record":force})
	for entry:Dictionary in forces:
		var items:={}
		for formation:Dictionary in (entry.record as Dictionary).get("formations",[]):
			var missing:=_formation_needs(host,formation)
			for item:String in missing:items[item]=int(items.get(item,0))+int(missing[item])
		if items.is_empty():continue
		var record:Dictionary=entry.record
		result.append({"force_id":entry.force_id,"who":entry.who,"where":entry.where,"position":record.get("position",null),"items":items})
	return result

# --- Rows -----------------------------------------------------------------------

static func rows(host:Node=null,snapshot:Dictionary={})->Array[Dictionary]:
	host=_host(host)
	var result:Array[Dictionary]=[]
	if host==null:return result
	if snapshot.is_empty():snapshot=host.production_lines_snapshot()
	var need:=needs(host)
	var items:={}
	var making:={}
	var line_ids:={}
	for line:Dictionary in snapshot.get("lines",[]):
		var item:=String(line.get("item",""))
		if item.is_empty():continue
		items[item]=true
		if not bool(line.get("paused",false)):making[item]=float(making.get(item,0.0))+maxf(0.0,float(line.get("forecast_output_per_day",0.0)))
		var ids:Array=line_ids.get(item,[]);ids.append(int(line.get("id",0)));line_ids[item]=ids
	for item:String in need:items[item]=true
	for table:Dictionary in [host.military_inventory,host.military_consumables,host.damaged_equipment]:
		for item:String in table:
			if int(table[item])>0:items[item]=true
	if int(WorldSimulation.state.resource_stockpiles.get("Transport Carts",0))>0:items["transport_cart"]=true
	for item:String in items:result.append(_row(host,item,need,making,line_ids))
	result.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var ca:=CATEGORY_ORDER.find(String(a.category));var cb:=CATEGORY_ORDER.find(String(b.category))
		return ca<cb if ca!=cb else String(a.name)<String(b.name))
	return result

static func _row(host:Node,item:String,need:Dictionary,making:Dictionary,line_ids:Dictionary)->Dictionary:
	var entry:Dictionary=need.get(item,{"fielded":0,"training":0,"requisitioned":0,"for":{}})
	var needed:=int(entry.fielded)+int(entry.training)+int(entry.requisitioned)
	var held:=stock(item,host)
	var deficit:=maxi(0,needed-held)
	var per_day:=float(making.get(item,0.0))
	var groups:Array=(entry["for"] as Dictionary).values()
	groups.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.count)>int(b.count) if int(a.count)!=int(b.count) else String(a.who)<String(b.who))
	var repairing:=Upkeep.pending(host,item)
	var damaged:=maxi(0,int(host.damaged_equipment.get(item,0)))
	return {"item":item,"name":P.product_name(item),"category":category(item),"stock":held,"needed":needed,"deficit":deficit,
		"fielded":int(entry.fielded),"training":int(entry.training),"requisitioned":int(entry.requisitioned),
		"damaged":damaged,"repairing":repairing,"repair_status":Upkeep.status(host,item) if damaged+repairing>0 else "",
		"making_per_day":per_day,"days_to_cover":(0.0 if deficit<=0 else (deficit/per_day if per_day>0.0 else -1.0)),
		"lines":line_ids.get(item,[]),"for":groups}

static func row(item:String,host:Node=null)->Dictionary:
	for entry:Dictionary in rows(host):
		if String(entry.item)==item:return entry
	host=_host(host)
	return _row(host,item,{},{},{})

static func deficit(item:String,host:Node=null)->int:
	host=_host(host)
	var entry:Dictionary=needs(host).get(item,{})
	if entry.is_empty():return 0
	return maxi(0,int(entry.fielded)+int(entry.training)+int(entry.requisitioned)-stock(item,host))

## The small badge on a line making gear someone waits for:
## {text:"for Rovik's levy", tip, count} or {} when nobody waits beyond stores.
static func line_badge(line:Dictionary,host:Node=null,need:Dictionary={})->Dictionary:
	host=_host(host)
	var item:=String(line.get("item",""))
	if item.is_empty() or bool(line.get("paused",false)):return {}
	if need.is_empty():need=needs(host)
	var entry:Dictionary=need.get(item,{})
	if entry.is_empty():return {}
	var total:=int(entry.fielded)+int(entry.training)+int(entry.requisitioned)
	var short:=total-stock(item,host)
	if short<=0:return {}
	var groups:Array=(entry["for"] as Dictionary).values()
	groups.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.count)>int(b.count) if int(a.count)!=int(b.count) else String(a.who)<String(b.who))
	var lines:Array[String]=[]
	var where_words:={"home":"at home","field":"in the field","garrison":"holding a town","training":"in training","called_up":"called up"}
	for group:Dictionary in groups:
		lines.append("%s: %d %s" % [String(group.who).left(1).to_upper()+String(group.who).substr(1),int(group.count),String(where_words.get(String(group.where),""))])
	var text:="for "+String(groups[0].who)
	if groups.size()>1:text+=" +%d" % (groups.size()-1)
	var tip:="Gear for:\n"+"\n".join(lines)+"\nShort %d after what is in store. They draw it as it is made; nothing to order." % short
	return {"text":text,"tip":tip,"count":short}

# --- Material trend -------------------------------------------------------------

static var _log:Dictionary={}
static var _log_scope:=""

static func _scope()->String:
	return "%d|%s" % [int(WorldSimulation.state.world_seed),String(WorldSimulation.state.resource_settlement_id)]

## Remember today's stores (or `stocks` for `day`) so the header can show how
## each material moved over the last week. In memory only; never saved.
static func note_stores(stocks:Dictionary={},day:int=-1)->void:
	var today:=int(WorldSimulation.state.elapsed_days)
	if day<0:day=today
	if stocks.is_empty():stocks=WorldSimulation.state.resource_stockpiles
	var scope:=_scope()
	if scope!=_log_scope:_log.clear();_log_scope=scope
	for logged:int in _log.keys():
		if logged>today or logged<today-TREND_DAYS:_log.erase(logged)
	if day<today-TREND_DAYS or _log.has(day):return
	var copy:={}
	for resource:String in stocks:copy[resource]=float(stocks[resource])
	_log[day]=copy

## Net change a day over the last week of samples, or over the last monthly
## count when this session has no older sample: {per_day, days} or {}.
static func material_trend(resource:String)->Dictionary:
	note_stores()
	var today:=int(WorldSimulation.state.elapsed_days)
	var now:=float(WorldSimulation.state.resource_stockpiles.get(resource,0.0))
	var oldest:=today
	for day:int in _log:
		if day<oldest and (_log[day] as Dictionary).has(resource):oldest=day
	if oldest<today:
		return {"per_day":(now-float(_log[oldest][resource]))/float(today-oldest),"days":today-oldest}
	var scope:=""
	for city:Dictionary in WorldSimulation.state.player_settlements:
		if bool(city.get("primary",false)):scope=String(city.get("id",""))
	if scope.is_empty():return {}
	var points:Array=preload("res://scripts/strategic_history.gd").points(WorldSimulation.state.strategic_history,scope)
	for index in range(points.size()-1,-1,-1):
		var point:Dictionary=points[index]
		if not point.has(resource) or int(point.get("day",today))>=today:continue
		return {"per_day":(now-float(point[resource]))/float(today-int(point.day)),"days":today-int(point.day)}
	return {}

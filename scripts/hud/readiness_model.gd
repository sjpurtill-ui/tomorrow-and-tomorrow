extends RefCounted
## THE READINESS & SUPPLY TAB AS NUMBERS: HOI4's logistics view;
## hud/readiness_board.gd draws it.
##
## Everything is the supply model's own reading (scripts/supply_state.gd)
## and the shared gear reading (scripts/equipment_logistics.gd); nothing is
## worked out twice (docs/ADJUDICATION.md). Pure reads.
##
##   strip()  who carries our food (porters, carts or lorries) and how many,
##            the share of the fighters' need our carriers can move
##            (supply_state.day_inputs().transport), our hubs and depots, the
##            rations the fighters eat a day and the gear being mended
##   rows()   one per force: the levy at home and each town we hold as
##            supply_state.of_force reports them today, and each band by the
##            army bar's one supply rule (army_bar_model.known_supply: today's
##            reading while word reaches home, else its last runner's report,
##            dated), so a band reads the same here, on the army bar and on
##            the supply map. Each row has the model's keys (ratio, state,
##            hub, days, km, road, hungry_days, why...), the name the army bar
##            gives it and its gear shortfalls (equipment_logistics
##            .needs_by_force)

const Supply:=preload("res://scripts/supply_state.gd")
const Logistics:=preload("res://scripts/equipment_logistics.gd")
const BarModel:=preload("res://scripts/hud/army_bar_model.gd")
const Upkeep:=preload("res://scripts/routine_military_upkeep.gd")
const P:=preload("res://scripts/persistent_production.gd")
## Row order: the levy at home, then the bands out, then the towns we hold.
const ORDER:=["home","field","garrison"]


static func _host(mc:Node)->Node:
	return mc if mc!=null else MilitaryCampaign


# --- The strip --------------------------------------------------------------------

static func strip(mc:Node=null)->Dictionary:
	mc=_host(mc)
	var state:Variant=WorldSimulation.state
	var inputs:=Supply.day_inputs()
	var who:=Supply.carrier()
	var hubs:Array[String]=[];var depots:Array[String]=[]
	for hub:Dictionary in Supply.hubs():
		if String(hub.get("kind",""))=="held":depots.append(String(hub.get("name","")))
		else:hubs.append(String(hub.get("name","")))
	return {"carrier":who,"carrier_words":String((Supply.CARRIERS.get(who,Supply.CARRIERS.foot) as Dictionary).words),
		"haulers":int((state.population_allocations as Dictionary).get("Logistics",0)) if state!=null else 0,
		"carts":int(float((state.resource_stockpiles as Dictionary).get("Transport Carts",0.0))) if state!=null else 0,
		"lorries":int(float((state.resource_stockpiles as Dictionary).get("Supply Lorries",0.0))) if state!=null else 0,
		"fleet":(mc.carrier_reading() as Dictionary) if mc.has_method("carrier_reading") else {},
		"transport":float(inputs.transport),"stores":float(inputs.stores),"siege":float(inputs.siege),
		"hubs":hubs,"depots":depots,"rations":float(mc.economic_burden_snapshot().get("daily_field_provisions",0.0)),"mending":mending(mc)}


## Gear waiting to be mended: {count, lines:["Simple levy weapons: ..."]}
## (the damaged sets and the repairs under way, as the upkeep staff read them).
static func mending(mc:Node=null)->Dictionary:
	mc=_host(mc)
	var damaged:=0
	var items:Array=[]
	for item:String in mc.damaged_equipment:
		damaged+=int(mc.damaged_equipment[item])
		items.append(item)
	for job:Dictionary in mc.equipment_queue:
		if (String(job.get("job_type",""))=="repair" or job.has("repair_pending")) and String(job.get("item","")) not in items:items.append(String(job.item))
	var lines:Array[String]=[]
	for item:String in items:
		var underway:=int(Upkeep.pending(mc,item))
		damaged+=underway
		if int(mc.damaged_equipment.get(item,0))+underway>0:lines.append("%s: %s" % [P.product_name(item),Upkeep.status(mc,item)])
	return {"count":damaged,"lines":lines}


# --- Rows ---------------------------------------------------------------------------

## A force's key, the same for its supply report, its army-bar card and its
## gear needs: "home", "army:<id>" or "held:<region id>".
static func key_of(report:Dictionary)->String:
	match String(report.get("force_kind","")):
		"home":return "home"
		"garrison":return "held:"+String(report.get("region_id",""))
	return "army:%d" % int(report.get("army_id",0))


static func rows(mc:Node=null)->Array[Dictionary]:
	mc=_host(mc)
	var cards:={}
	for card:Dictionary in BarModel.cards(mc):
		var ones:Array=[card]
		if String(card.kind)=="group":ones=card.get("member_cards",[])
		for one in ones:
			var c:Dictionary=one
			var key:="home" if String(c.kind)=="home" else ("held:"+String(c.get("region_id","")) if String(c.kind)=="garrison" else "army:%d" % int(c.army_id))
			cards[key]=c
	var gear:={}
	for need:Dictionary in Logistics.needs_by_force(mc):
		var key:="home" if String(need.where)=="home" else ("held:%s" % String(need.force_id) if String(need.where)=="garrison" else "army:%d" % int(need.force_id))
		gear[key]=need.items
	var stock:={}
	for entry:Dictionary in Logistics.rows(mc):stock[String(entry.item)]=entry
	var out:Array[Dictionary]=[]
	for report:Dictionary in _reports(mc):
		var row:=report.duplicate()
		var key:=key_of(report)
		var card:Dictionary=cards.get(key,{})
		row["key"]=key
		row["card_id"]=String(card.get("id",key))
		row["title"]=String(card.get("title","")) if not card.is_empty() else _fallback_title(report)
		row["general"]=card.get("general",{})
		row["card_kind"]=String(card.get("kind",String(report.get("force_kind",""))))
		row["men"]=int(report.get("troops",-1))
		var short:Array[Dictionary]=[]
		var items:Dictionary=gear.get(key,{})
		for item:String in items:
			var entry:Dictionary=stock.get(item,{})
			short.append({"item":item,"name":String(entry.get("name",P.product_name(item))),"missing":int(items[item]),"stock":int(entry.get("stock",Logistics.stock(item,mc))),
				"making_per_day":float(entry.get("making_per_day",0.0)),"category":String(entry.get("category",Logistics.category(item)))})
		short.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.missing)>int(b.missing))
		row["short"]=short
		# A band's place in the supply queue and the replacements walking out
		# to it (field_sustainment.gd), read today at home.
		if String(report.get("force_kind",""))=="field":
			var army_index:int=mc._field_army_index(int(report.get("army_id",0)))
			var army:Dictionary=mc.field_armies[army_index] if army_index>=0 else {}
			row["priority"]=String(army.get("priority","normal"))
			row["drafts"]=mc.sustainment.drafts_for(int(report.get("army_id",0)))
		row["order"]=ORDER.find(String(report.get("force_kind","field")))*10000+out.size()
		out.append(row)
	out.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.order)<int(b.order))
	return out


## The forces' supply as we know it at home: the levy and the towns we hold
## today, each band by the one rule ({unknown} while no runner has come).
static func _reports(mc:Node)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	if int((mc.home_army as Dictionary).get("troops",0))>0:out.append(_today(Supply.of_force(mc.home_army)))
	for a in mc.field_armies:
		if not a is Dictionary or int((a as Dictionary).get("troops",0))<=0:continue
		var army:Dictionary=a
		var known:=BarModel.known_supply(mc,army)
		out.append(known if not known.is_empty() else {"force_kind":"field","army_id":int(army.get("army_id",0)),"name":String(army.get("name","")),"unknown":true,"live":false})
	for g in mc.occupation_forces:
		if g is Dictionary and int((g as Dictionary).get("troops",0))>0:out.append(_today(Supply.of_force(g)))
	return out


static func _today(report:Dictionary)->Dictionary:
	var out:=report.duplicate()
	out["live"]=true;out["report_age"]=0
	return out


static func _fallback_title(report:Dictionary)->String:
	match String(report.get("force_kind","")):
		"home":return Logistics.levy_name().substr(0,1).to_upper()+Logistics.levy_name().substr(1)
		"garrison":return "Garrison of %s" % Supply.town_name("",String(report.get("region_id","")),String(report.get("name","the town")))
	return String(report.get("name","Our band"))


## "12 on the road, first in 3 days; 8 in training" for a band's replacements.
static func drafts_words(drafts:Dictionary,today:int)->String:
	var parts:PackedStringArray=[]
	var road:=int(drafts.get("on_road",0))
	if road>0:
		var wait:=maxi(0,int(drafts.get("next_arrival_day",today))-today)
		parts.append("%d replacements on the road, the first %s" % [road,"arriving today" if wait<=0 else ("in %d day%s" % [wait,"" if wait==1 else "s"])])
	var training:=int(drafts.get("in_training",0))
	if training>0: parts.append("%d in training at home" % training)
	var block:=String(drafts.get("block",""))
	if block!="" and DRAFT_BLOCKS.has(block): parts.append(String(DRAFT_BLOCKS[block]))
	return "; ".join(parts)

const PRIORITY_WORDS:={"first":"Reinforced first","normal":"Reinforced in turn","last":"Reinforced last"}
const PRIORITY_TIPS:={"first":"This band gets gear, rounds and replacements before the others. Food is shared by the carriers alike.","normal":"This band waits its turn for gear, rounds and replacements.","last":"This band gets gear only at home and no replacement drafts."}
const DRAFT_BLOCKS:={"no_people":"No one to draft: everyone set aside for defence is serving. Raise the Defense share of work, or call up more on Recruit & deploy.","hungry":"No drafts while the band is starving: they would starve too.","cut_off":"No drafts: no road our carriers use reaches the band.","last":"No drafts for a band reinforced last.","campaign":"The general's campaign keeps its own ranks."}


## Plain words for a gear shortfall, for its tooltip.
static func short_words(entry:Dictionary)->String:
	var making:=float(entry.get("making_per_day",0.0))
	var line:="Short %d %s · %d in store" % [int(entry.missing),String(entry.name).to_lower(),int(entry.stock)]
	line+=(" · workshops make %s a day" % (("%.1f" % making).trim_suffix(".0") if making<10.0 else str(roundi(making)))) if making>0.0 else " · no workshop makes them"
	return line+"\nClick to open production."

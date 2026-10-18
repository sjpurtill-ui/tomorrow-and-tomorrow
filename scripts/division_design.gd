extends RefCounted
## A bounded template, not a manpower ledger. Slots compile to the existing
## unit/weapon/count entries used by recruitment, deployment and equipment.
const Catalog=preload("res://scripts/military_unit_catalog.gd")
const Kits=preload("res://scripts/equipment_ledger.gd")
const Makeup=preload("res://scripts/army_makeup.gd")
const SLOT_COUNT:=30
const SUPPORT_COUNT:=5
const MAX_MEN:=100000
const MAX_DESIGNS:=64

static func support(unit:String)->bool:
	return String(Catalog.archetype(unit).get("branch","")) in ["field_support","reconnaissance"] or unit in ["combat_engineer","anti_air","anti_tank"]

## Suggestions follow the manpower already assigned, never draft new people.
static func size_presets(available:int)->Array[int]:
	var result:Array[int]=[]
	for n:int in [1,2,5,10,20,50,100,250,500,1000]:
		if n<=maxi(1,available):result.append(n)
	return result

## Identity follows actual combat composition. Population cannot unlock a unit.
static func formation_name(design:Array)->String:
	var counts:={};var total:=0;var dominant:=""
	for e:Dictionary in design:
		total+=int(e.count)
		if String(Catalog.archetype(String(e.unit)).get("branch",""))=="field_support":continue
		counts[e.unit]=int(counts.get(e.unit,0))+int(e.count)
		if dominant.is_empty() or int(counts[e.unit])>int(counts[dominant]):dominant=String(e.unit)
	if dominant.is_empty():return "New formation"
	if dominant=="levy":return "Levy band" if total<=20 else "Levy formation"
	var kind:=String(Catalog.archetype(dominant).label)
	if dominant in ["main_battle_tank","armored_formation"]:kind="Armored"
	elif dominant=="rifle_infantry":kind="Rifle"
	elif dominant=="line_infantry":kind="Infantry"
	var scale:="group" if total<100 else ("company" if total<500 else ("battalion" if total<3000 else "division"))
	return kind+" "+scale

static func migration_error(template:Dictionary)->String:
	if template.has("designer_slots"):return ""
	var source:Array=template.get("entries",[])
	var mapped:=entries(slots(template))
	var expected:={};var actual:={}
	for e:Dictionary in source:
		var key:=String(e.unit)+"|"+String(e.weapon)
		expected[key]=int(expected.get(key,0))+int(e.count)
	for e:Dictionary in mapped:actual[String(e.unit)+"|"+String(e.weapon)]=int(e.count)
	return "This legacy design has more groups than the designer can hold. Duplicate or simplify it in the existing roster before editing; nothing has been removed." if expected!=actual else ""

static func slots(template:Dictionary)->Array:
	if template.get("designer_slots") is Array:
		return template.designer_slots.duplicate(true)
	var out:Array=[]
	out.resize(SLOT_COUNT);out.fill({})
	var front:=SUPPORT_COUNT;var rear:=0
	for entry:Dictionary in template.get("entries",[]):
		var index:=rear if support(String(entry.unit)) and rear<SUPPORT_COUNT else front
		if index>=SLOT_COUNT:continue
		out[index]={"unit":String(entry.unit),"weapon":String(entry.weapon),"count":int(entry.count)}
		if index<SUPPORT_COUNT:rear+=1
		else:front+=1
	if front==SUPPORT_COUNT:
		for i in SUPPORT_COUNT:
			if not (out[i] as Dictionary).is_empty() and String(Catalog.archetype(String(out[i].unit)).get("branch",""))!="field_support":
				out[SUPPORT_COUNT]=out[i];out[i]={};break
	return out

static func entries(cells:Array)->Array:
	var out:Array=[];var by_key:={}
	for cell:Variant in cells:
		if not cell is Dictionary or cell.is_empty():continue
		var key:=String(cell.unit)+"|"+String(cell.weapon)
		if not by_key.has(key):
			by_key[key]=out.size();out.append({"unit":String(cell.unit),"weapon":String(cell.weapon),"count":0})
		out[int(by_key[key])].count+=int(cell.count)
	return out

static func validate(mc:Variant,cells:Variant,check_gates:=true)->String:
	if not cells is Array or cells.size()!=SLOT_COUNT:return "A design has five support slots and twenty-five combat slots."
	var total:=0;var front:=0
	for i in cells.size():
		var cell:Variant=cells[i]
		if not cell is Dictionary:return "Invalid formation slot."
		if cell.is_empty():continue
		if not cell.get("unit") is String or not cell.get("weapon") is String:return "Choose a unit and its equipment."
		var unit:=String(cell.unit);var weapon:=String(cell.weapon)
		if not Catalog.ARCHETYPES.has(unit) or not weapon in Catalog.equipment_for(unit):return "That equipment does not belong to this unit."
		var n:Variant=cell.get("count")
		if not (n is int or n is float) or not is_finite(float(n)) or float(n)!=floorf(float(n)) or float(n)<1 or float(n)>MAX_MEN:return "Each occupied slot needs a whole number of people, from 1 to 100,000."
		if i<SUPPORT_COUNT and not support(unit):return "Choose a support unit for a support slot."
		if i>=SUPPORT_COUNT and String(Catalog.archetype(unit).get("branch",""))=="field_support":return "Medical and repair teams belong in support slots."
		if check_gates:
			var gate:Dictionary=mc._training_gate(unit,weapon)
			if not gate.is_empty():return String(gate.get("error","Adopt this practice before making it an army standard."))
		total+=int(n)
		if i>=SUPPORT_COUNT:front+=int(n)
	if front==0:return "Add at least one combat group."
	if total>MAX_MEN:return "Keep a single division at or below 100,000 people."
	return ""

static func save(mc:Variant,id:int,label:String,cells:Array)->Dictionary:
	var error:=validate(mc,cells)
	if not error.is_empty():return {"error":error}
	var index:int=mc._template_index(id)
	if index<0:return {"error":"That design no longer exists."}
	var migration:=migration_error(mc.army_templates[index])
	if not migration.is_empty():return {"error":migration}
	if label.strip_edges().is_empty() or label.length()>64:return {"error":"Name the design using 1–64 characters."}
	mc.army_templates[index]["name"]=label.strip_edges()
	mc.army_templates[index]["designer_slots"]=cells.duplicate(true)
	mc.army_templates[index]["entries"]=entries(cells)
	return {"ok":true,"message":"Design saved. Existing troops and queued formations keep their equipment and orders."}

static func activate(mc:Variant,id:int)->Dictionary:
	var index:int=mc._template_index(id)
	if index<0:return {"error":"That design no longer exists."}
	var migration:=migration_error(mc.army_templates[index])
	if not migration.is_empty():return {"error":migration}
	var error:=validate(mc,slots(mc.army_templates[index]))
	if not error.is_empty():return {"error":error}
	mc.active_division_template_id=id
	return {"ok":true,"message":"Army standard set. Staff equip and retrain people already allocated to Defense; no extra people are enlisted."}

static func active(mc:Variant)->Array:
	if mc==null or not "active_division_template_id" in mc or int(mc.active_division_template_id)<=0:return []
	for template:Dictionary in mc.army_templates:
		if int(template.get("template_id",0))==int(mc.active_division_template_id):return template.get("entries",[])
	return []

## Largest remainders: exact whole-person target, no phantom recruits.
static func targets(design:Array,total:int)->Array:
	var sum:=0
	for e:Dictionary in design:sum+=maxi(0,int(e.count))
	if sum==0 or total<=0:return []
	var out:Array=[];var rest:Array=[];var assigned:=0
	for e:Dictionary in design:
		var exact:=float(total)*int(e.count)/sum
		var n:=floori(exact);assigned+=n
		out.append({"unit":String(e.unit),"weapon":String(e.weapon),"count":n})
		rest.append([exact-n,out.size()-1])
	rest.sort_custom(func(a:Array,b:Array)->bool:return a[0]>b[0])
	for i in total-assigned:out[int(rest[i][1])].count+=1
	return out

static func split(mc:Variant,n:int)->Array:
	var out:Array=[]
	for e:Dictionary in targets(active(mc),n):
		if int(e.count)<=0:continue
		var gate:Dictionary=mc._training_gate(String(e.unit),String(e.weapon))
		var kit:Dictionary={"unit":e.unit,"item":e.weapon} if gate.is_empty() else {"unit":"levy","item":"improvised"}
		out.append({"kit":kit,"count":e.count})
	return out

static func wanted(mc:Variant)->Dictionary:
	var out:={};var have:=Makeup._men_in_kits(mc)
	for e:Dictionary in targets(active(mc),int(mc.watch_manpower())):
		var gap:=maxi(0,int(e.count)-int(have.get(String(e.unit)+"|"+String(e.weapon),0)))
		if gap>0 and String(e.weapon)!="improvised":out[e.weapon]=int(out.get(e.weapon,0))+mc.simulator.equipment_required_for_weapon(String(e.weapon),gap)
	return out

## Exact equipment choices survive automatic best-kit selection. Reuse the
## existing transfer path: old kit returns, new kit is withdrawn, drill falls.
static func converge(mc:Variant)->int:
	if mc.recovery.home_unavailable() or mc._home_battle_running():return 0
	var home:=int(mc.home_army.get("troops",0))
	if home<=0:return 0
	var budget:=maxi(1,floori(home*Makeup.CONVERT_DAY));var moved:=0
	var have:=Makeup._men_in_kits(mc);var total:=0
	for key in have:total+=int(have[key])
	var desired:={};var design:=targets(active(mc),total)
	for e:Dictionary in design:desired[String(e.unit)+"|"+String(e.weapon)]=int(e.count)
	for e:Dictionary in design:
		var to:=String(e.unit)+"|"+String(e.weapon)
		var gap:=maxi(0,int(e.count)-int(have.get(to,0)))
		if gap==0 or not (mc._training_gate(String(e.unit),String(e.weapon)) as Dictionary).is_empty():continue
		var kit:={"unit":e.unit,"item":e.weapon}
		for from:String in have.keys():
			var surplus:=int(have[from])-int(desired.get(from,0))
			if surplus<=0:continue
			var n:=mini(mini(gap,surplus),budget-moved)
			n=mini(n,Makeup._sets_free(mc,kit,n))
			if n<=0:continue
			var done:=Makeup._retrain(mc,Makeup.role_of(from.get_slice("|",0)),to,kit,n,-INF,from)
			have[from]-=done;have[to]=int(have.get(to,0))+done;gap-=done;moved+=done
			if gap<=0 or moved>=budget:break
		if moved>=budget:break
	if moved>0:
		mc._rebuild_home_army_with([]);mc.army_changed.emit(mc.home_army.duplicate(true))
	return moved

static func validate_saved(payload:Dictionary)->String:
	var templates:Variant=payload.get("army_templates",[])
	if not templates is Array:return "Invalid division templates."
	var ids:={}
	for t:Variant in templates:
		if not t is Dictionary:return "Invalid division design."
		var id:=int(t.get("template_id",0))
		ids[id]=true
		if t.has("designer_slots"):
			var error:=validate(null,t.designer_slots,false)
			if not error.is_empty():return error
			if entries(t.designer_slots)!=t.get("entries",[]):return "Division slots disagree with the equipment and manpower bill."
	var active_id:Variant=payload.get("active_division_template_id",0)
	if not (active_id is int or active_id is float) or not is_finite(float(active_id)) or float(active_id)!=floorf(float(active_id)) or float(active_id)<0:return "Invalid army standard."
	if int(active_id)>0 and not ids.has(int(active_id)):return "Army standard refers to a missing design."
	return ""

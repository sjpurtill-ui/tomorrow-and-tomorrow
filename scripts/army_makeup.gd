extends RefCounted
## THE ARMY'S MAKEUP: what kinds of fighters the army is made of.
##
## The ruler sets each kind's share of everyone under arms, and nothing more:
##   line     those who hold the field (levy, spearmen, legions, riflemen);
##   missile  those who shoot from a distance (slingers, archers, crossbows);
##   mounted  riders and machines (horse, chariots, then armour);
##   guns     siege and fire (rams and catapults, then cannon and artillery).
## The war leader fills each kind with the best fighters our people can train
## today and the best gear it can make (best): the unit's and the weapon's
## practice adopted (no prototype cohorts), the weapon in the armoury or
## makeable, the highest fighting worth (unit attack x defence x the kit's
## worth, armor_equipment.preference). So the makeup never names a unit:
## a people's "missile" are slingers in one age and riflemen with mortars in
## another, and the army moves to the newest kit by itself.
##
## How the makeup is kept (every day, watch_military.gd):
##   - those joining the watch are split among the kinds short of their share
##     (split), each joining as its kind's best;
##   - at home, a few of those standing in a kind above its share, or in an
##     older kit than its kind's best, retrain each day (converge_day): only
##     as many as there are sets of the new kit in store, so nobody is
##     disarmed to be retrained. Their drill falls to half (new weapons, new
##     drill), never below a raw recruit's;
##   - the workshops make the kits the makeup still lacks (wanted, read by
##     workshop_steward.gd army_demands), so sets are there to take up.
## With no makeup chosen (an older save, every computer people until its
## ruler sets one) the army is all line, kitted as before (watch_military
## arms_kit). Static; preload.

const Watch_PATH:="res://scripts/watch_military.gd"
const Stock:=preload("res://scripts/weapons_stock.gd")

const ROLES:=[
	{"id":"line","label":"Line","glyph":"spear","branches":["force_generation","heavy_infantry","autonomous"],
		"tip":"Line: those who hold the field and take towns, from the levy and the spear to riflemen."},
	{"id":"missile","label":"Missile","glyph":"bow","branches":["missile_infantry","reconnaissance"],
		"tip":"Missile: those who fight from a distance, from slings and bows to crossbows and drones."},
	{"id":"mounted","label":"Mounted","glyph":"horse","branches":["mounted","protection"],
		"tip":"Mounted: riders, chariots and, later, armour. Fast on the march; they hit hard and chase."},
	{"id":"guns","label":"Siege & guns","glyph":"catapult","branches":["siege_fires"],
		"tip":"Siege and guns: rams and catapults against walls, then cannon and artillery."},
]
## Each press of + or − moves a kind by a tenth of the army.
const STEP:=0.1
## Of everyone at home, at most this share retrains in a day.
const CONVERT_DAY:=0.02
## Drill kept by a fighter who changes weapons.
const KEEP_DRILL:=0.5
const START_DRILL:=0.25


static func _watch()->GDScript:
	return load(Watch_PATH) as GDScript

static func role_ids()->Array:
	return ROLES.map(func(r:Dictionary)->String:return String(r.id))

static func role(id:String)->Dictionary:
	for r:Dictionary in ROLES:
		if String(r.id)==id:return r
	return {}

## A saved makeup made safe: known kinds, shares 0..1 adding to 1; {} when
## nothing usable.
static func clean(value:Variant)->Dictionary:
	if not value is Dictionary:return {}
	var out:={};var sum:=0.0
	for id:String in role_ids():
		var share:Variant=(value as Dictionary).get(id,0.0)
		if (share is float or share is int) and is_finite(float(share)) and float(share)>0.0:
			out[id]=float(share);sum+=float(share)
	if sum<=0.0:return {}
	for id in out:out[id]=float(out[id])/sum
	return out

## Whether the ruler chose a makeup.
static func chosen(mc:Variant)->bool:
	return mc!=null and mc.get("army_makeup") is Dictionary and not (mc.army_makeup as Dictionary).is_empty()

## Each kind's share (all line until chosen).
static func shares(mc:Variant)->Dictionary:
	var out:={}
	for id in role_ids():out[id]=0.0
	if chosen(mc):
		for id in mc.army_makeup:out[id]=float(mc.army_makeup[id])
	else:out.line=1.0
	return out

## Sets one kind's share; the others give or take the difference in their
## own proportions (all to line when they had none). {ok, shares} or {error}.
static func set_share(mc:Variant,id:String,share:float)->Dictionary:
	if role(id).is_empty():return {"error":"There is no such kind of fighter."}
	share=clampf(snappedf(share,0.01),0.0,1.0)
	var now:=shares(mc)
	var others:=0.0
	for other in now:
		if other!=id:others+=float(now[other])
	var room:=1.0-share
	for other in now:
		if other==id:continue
		now[other]=float(now[other])*room/others if others>0.0 else (room if other=="line" else 0.0)
	now[id]=share
	if id=="line" and others<=0.0 and room>0.0:return {"error":"Raise another kind first."}
	mc.army_makeup=clean(now)
	return {"ok":true,"shares":shares(mc)}

static func step(mc:Variant,id:String,direction:int)->Dictionary:
	return set_share(mc,id,float(shares(mc).get(id,0.0))+STEP*signf(direction))

## The kind a unit belongs to ("" for those the makeup does not count:
## medics, repairers, specialists).
static func role_of(unit:String)->String:
	var catalog:=preload("res://scripts/military_unit_catalog.gd").ARCHETYPES
	var branch:=String((catalog.get(unit,{}) as Dictionary).get("branch",""))
	if unit=="levy":return "line"
	for r:Dictionary in ROLES:
		if branch in (r.branches as Array):return String(r.id)
	return ""

## What a unit and kit are worth in a fight: striking power times staying
## power (the unit's and the kit's attack, defence and armour, as the combat
## engine reads them), the shooters and the guns judged mostly on how hard
## they strike.
static func worth(mc:Variant,unit:String,item:String)->float:
	var spec:Dictionary=mc.simulator.UNIT_TYPES.get(unit,{})
	if spec.is_empty() or not mc.simulator.WEAPONS.has(item):return -INF
	var kit:Dictionary=mc.simulator.WEAPONS[item]
	var strike:=maxf(0.05,float(spec.get("attack",0.5))*float(kit.get("attack",1.0)))
	var stay:=maxf(0.05,float(spec.get("defense",0.5))*float(kit.get("defense",1.0))+float(kit.get("armor",0.0))*0.45)
	var shooting:=role_of(unit) in ["missile","guns"]
	return pow(strike,1.5 if shooting else 1.0)*pow(stay,0.5 if shooting else 1.0)

## Whether a kit can reach a fighter's hands: in the armoury, made by the
## makers, or a workshop line can start on it now (its practice, materials
## and tools in hand: the same test as the Production screen's).
static func _obtainable(mc:Variant,item:String)->bool:
	if item=="improvised":return true
	if int((mc.military_inventory as Dictionary).get(item,0))>0:return true
	if item in Stock.made_items(mc):return true
	return mc.PersistentProduction.startup_blockers(mc,item).is_empty()

## The best a kind can be today: {unit, item, worth}, {} when our people can
## train none of it. Line falls back on the levy with what comes to hand.
static func best(mc:Variant,id:String,ready:=true)->Dictionary:
	var r:=role(id)
	if r.is_empty():return {}
	var found:={};var top:=-INF
	var catalog:Dictionary=mc.UnitCatalog.ARCHETYPES
	var units:Array=catalog.keys();units.sort()
	for unit:String in units:
		if not String((catalog[unit] as Dictionary).get("branch","")) in (r.branches as Array):continue
		for item:String in mc.UnitCatalog.equipment_for(unit):
			if not (mc._training_gate(unit,item) as Dictionary).is_empty():continue
			if ready and not _obtainable(mc,item):continue
			if not ready and item!="improvised" and mc.PersistentProduction.recipe(mc,item).has("error") and int((mc.military_inventory as Dictionary).get(item,0))<=0 and not item in Stock.made_items(mc):continue
			var value:=worth(mc,unit,item)
			if value>top:top=value;found={"unit":unit,"item":item,"worth":value}
	if found.is_empty() and id=="line":
		var kit:Dictionary=_watch().call("arms_kit",mc)
		found={"unit":String(kit.unit),"item":String(kit.item),"worth":worth(mc,String(kit.unit),String(kit.item))}
	return found

## The kit those joining a kind take up: the makers' own sets for line when
## they are as good (they are made without a workshop line), else the best.
static func kit_for(mc:Variant,id:String)->Dictionary:
	var top:=best(mc,id)
	if id=="line":
		var made:Dictionary=_watch().call("arms_kit",mc)
		if top.is_empty() or (role_of(String(made.unit))=="line" and worth(mc,String(made.unit),String(made.item))>=float(top.worth)):return made
	return top

## Men of each kind, wherever they stand (home, bands, garrisons).
static func counts(mc:Variant,home_only:=false)->Dictionary:
	var out:={}
	for id in role_ids():out[id]=0
	var forces:Array=[mc.home_army] if home_only else [mc.home_army]+mc.field_armies+mc.occupation_forces
	for force in forces:
		if not force is Dictionary:continue
		for f in (force as Dictionary).get("formations",[]):
			if not f is Dictionary or bool((f as Dictionary).get("emergency_militia",false)):continue
			var id:=role_of(String((f as Dictionary).get("unit","levy")))
			if id!="":out[id]=int(out[id])+maxi(0,int((f as Dictionary).get("count",0)))
	return out

## Those joining, split among the kinds short of their share: [{kit, count}].
## A kind our people cannot train gives its place to line.
static func split(mc:Variant,n:int)->Array:
	if n<=0:return []
	if not chosen(mc):return [{"kit":_watch().call("arms_kit",mc),"count":n}]
	var want:=shares(mc)
	var kits:={}
	for id in role_ids():
		if float(want[id])<=0.0:continue
		var kit:=kit_for(mc,id)
		if kit.is_empty():want.line=float(want.line)+float(want[id]);want[id]=0.0
		else:kits[id]=kit
	if not kits.has("line") and float(want.line)>0.0:kits.line=kit_for(mc,"line")
	var have:=counts(mc)
	var total:=n
	for id in have:total+=int(have[id])
	var short:={};var sum:=0.0
	for id in kits:
		var gap:=maxf(0.0,float(want[id])*float(total)-float(have[id]))
		if gap>0.0:short[id]=gap;sum+=gap
	if sum<=0.0:
		for id in kits:short[id]=float(want[id]);sum+=float(want[id])
	# Whole people, largest remainders last.
	var out:Array=[];var given:=0;var rest:=[]
	for id in short:
		var exact:=float(n)*float(short[id])/sum
		var whole:=floori(exact)
		rest.append([exact-float(whole),id])
		if whole>0:out.append({"kit":kits[id],"count":whole,"role":id})
		given+=whole
	rest.sort_custom(func(a:Array,b:Array)->bool:return float(a[0])>float(b[0]))
	var i:=0
	while given<n and not rest.is_empty():
		var id:String=rest[i%rest.size()][1]
		var placed:=false
		for part:Dictionary in out:
			if String(part.role)==id:part.count=int(part.count)+1;placed=true;break
		if not placed:out.append({"kit":kits[id],"count":1,"role":id})
		given+=1;i+=1
	return out

## Kits the makeup still lacks, for the workshops: {item: sets}. Each kind's
## share of everyone under arms in its best kit, less those already in it
## and the sets of it already held.
static func wanted(mc:Variant)->Dictionary:
	var out:={}
	if not chosen(mc):return out
	var want:=shares(mc)
	var have:=counts(mc)
	var total:=0
	for id in have:total+=int(have[id])
	total=maxi(total,int(_watch().call("manpower",mc)))
	var in_kit:=_men_in_kits(mc)
	for id in role_ids():
		if float(want[id])<=0.0:continue
		var kit:=kit_for(mc,id)
		# The makers' own sets (weapons_stock.gd) are made without a line.
		if kit.is_empty() or String(kit.item)=="improvised" or String(kit.item) in Stock.made_items(mc):continue
		var men:=maxi(0,roundi(float(want[id])*float(total))-int(in_kit.get("%s|%s" % [kit.unit,kit.item],0)))
		if men<=0:continue
		var sets:int=mc.simulator.equipment_required_for_weapon(String(kit.item),men)
		out[String(kit.item)]=int(out.get(String(kit.item),0))+sets
	return out

static func _men_in_kits(mc:Variant)->Dictionary:
	var out:={}
	for force in [mc.home_army]+mc.field_armies+mc.occupation_forces:
		if not force is Dictionary:continue
		for f in (force as Dictionary).get("formations",[]):
			if not f is Dictionary:continue
			var key:="%s|%s" % [String((f as Dictionary).get("unit","")),String((f as Dictionary).get("weapon",""))]
			out[key]=int(out.get(key,0))+maxi(0,int((f as Dictionary).get("count",0)))
	return out

## A day's retraining at home toward the makeup and the newest kits: men in a
## kind above its share move to a kind below it, and men in an older kit
## than their kind's best take up the new one, at most CONVERT_DAY of those
## at home and never more than the sets of the new kit held. Returns the men
## retrained.
static func converge_day(mc:Variant)->int:
	if not chosen(mc) or mc.recovery.home_unavailable() or mc._home_battle_running():return 0
	var formations:Array=mc.home_army.get("formations",[])
	if formations.is_empty():return 0
	var home:=0
	for f in formations:if f is Dictionary:home+=maxi(0,int((f as Dictionary).get("count",0)))
	var budget:=maxi(1,floori(float(home)*CONVERT_DAY)) if home>=10 else 0
	if budget<=0:return 0
	var want:=shares(mc);var have:=counts(mc)
	var total:=0
	for id in have:total+=int(have[id])
	var over:={};var under:={}
	for id in role_ids():
		var gap:=roundi(float(want[id])*float(total))-int(have[id])
		if gap>0 and not kit_for(mc,id).is_empty():under[id]=gap
		elif gap<0:over[id]=-gap
	var moved:=0
	# Kinds short of their share: men from kinds above theirs.
	for to:String in under:
		var kit:=kit_for(mc,to)
		for from:String in over:
			var n:=mini(mini(int(under[to]),int(over[from])),budget-moved)
			n=mini(n,_sets_free(mc,kit,n))
			if n<=0:continue
			var done:=_retrain(mc,from,"",kit,n)
			over[from]=int(over[from])-done;under[to]=int(under[to])-done;moved+=done
			if moved>=budget:break
		if moved>=budget:break
	# The newest kit: men of a kind in an older one take it up.
	for id in role_ids():
		if moved>=budget:break
		var kit:=kit_for(mc,id)
		if kit.is_empty():continue
		# Those changing drill but not weapons keep their own sets.
		var n:=mini(budget-moved,_sets_free(mc,kit,budget-moved)+_same_kit_men(mc,id,kit))
		if n<=0:continue
		moved+=_retrain(mc,id,"%s|%s" % [kit.unit,kit.item],kit,n,float(kit.get("worth",worth(mc,String(kit.unit),String(kit.item)))))
	if moved>0:
		mc._rebuild_home_army_with([])
		mc.army_changed.emit(mc.home_army.duplicate(true))
	return moved

## Men at home of a kind carrying the kit's weapon in a lesser unit.
static func _same_kit_men(mc:Variant,id:String,kit:Dictionary)->int:
	var men:=0
	for f in mc.home_army.get("formations",[]):
		if not f is Dictionary:continue
		var unit:=String((f as Dictionary).get("unit",""))
		if role_of(unit)==id and unit!=String(kit.unit) and String((f as Dictionary).get("weapon",""))==String(kit.item):men+=maxi(0,int((f as Dictionary).get("count",0)))
	return men

## How many of `n` men the sets held of the kit can arm.
static func _sets_free(mc:Variant,kit:Dictionary,n:int)->int:
	if n<=0:return 0
	if String(kit.item)=="improvised":return n
	var held:=int(Stock.weapons_held(String(kit.item),mc))
	var per:=float(mc.simulator.equipment_required_for_weapon(String(kit.item),100))/100.0
	if per<=0.0:return n
	return mini(n,floori(float(held)/per))

## Up to `n` men at home of kind `from` (not already in `skip`, and below
## `better` worth when given) retrain as `kit`: their old kit back to the
## armoury, the new taken up, drill halved. Returns the men moved.
static func _retrain(mc:Variant,from:String,skip:String,kit:Dictionary,n:int,better:=-INF)->int:
	var Watch:=_watch()
	var formations:Array=mc.home_army.get("formations",[])
	var order:Array=range(formations.size())
	# The least drilled change first.
	order.sort_custom(func(a:int,b:int)->bool:return float((formations[a] as Dictionary).get("training",0.0))<float((formations[b] as Dictionary).get("training",0.0)))
	var left:=n;var drill_sum:=0.0;var exp_sum:=0.0
	for index:int in order:
		if left<=0:break
		var f:Dictionary=formations[index]
		if bool(f.get("emergency_militia",false)) or bool(f.get("prototype",false)):continue
		var unit:=String(f.get("unit","levy"));var item:=String(f.get("weapon","improvised"))
		if role_of(unit)!=from or "%s|%s" % [unit,item]==skip:continue
		if better>-INF and worth(mc,unit,item)>=better:continue
		var count:=int(f.get("count",0))
		var off:=mini(left,count)
		if off<=0:continue
		var gear:=mini(int(f.get("equipment",0)),roundi(float(int(f.get("equipment",0)))*float(off)/maxf(1.0,float(count))))
		Watch.call("return_weapons",mc,gear,item)
		f["count"]=count-off
		f["authorized_count"]=maxi(int(f.count),int(f.get("authorized_count",count))-off)
		f["equipment"]=int(f.get("equipment",0))-gear
		f["equipment_required"]=mc._equipment_required_for(unit,int(f.authorized_count))
		drill_sum+=float(f.get("training",START_DRILL))*off;exp_sum+=float(f.get("experience",0.0))*off
		left-=off
	var moved:=n-left
	if moved<=0:return 0
	mc.home_army["formations"]=formations.filter(func(f:Dictionary)->bool:return int(f.get("count",0))>0)
	var unit:=String(kit.unit);var item:=String(kit.item)
	var sets:int=mc._equipment_required_for(unit,moved)
	var armed:=int(Watch.call("take_weapons",mc,sets,item))
	var target:Dictionary=Watch.call("_formation_of",mc,unit,item)
	var id:=int(target.get("id",-1)) if not target.is_empty() else int(mc.next_formation_id)
	if target.is_empty():mc.next_formation_id=int(mc.next_formation_id)+1
	var drill:=maxf(START_DRILL,drill_sum/float(moved)*KEEP_DRILL)
	if target.is_empty():
		(mc.home_army.formations as Array).append({"id":id,"unit":unit,"weapon":item,"count":moved,"authorized_count":moved,"equipment":armed,"equipment_required":sets,
			"ammunition":0,"ammunition_required":mc._ammunition_required_for(item,sets),"training":drill,"experience":exp_sum/float(moved),"personnel_condition":1.0})
	else:
		var have:=int(target.get("count",0))
		target["training"]=(float(target.get("training",START_DRILL))*have+drill*moved)/float(have+moved)
		target["experience"]=(float(target.get("experience",0.0))*have+exp_sum)/float(have+moved)
		target["count"]=have+moved
		target["authorized_count"]=int(target.get("authorized_count",have))+moved
		target["equipment"]=int(target.get("equipment",0))+armed
		target["equipment_required"]=mc._equipment_required_for(unit,int(target.authorized_count))
		target["ammunition_required"]=mc._ammunition_required_for(item,int(target.equipment_required))
	return moved

## The kinds for the War screen: [{id, label, glyph, tip, share, unit, item,
## kind (words), men, target, armed, drill}].
static func rows(mc:Variant)->Array:
	var out:Array=[]
	var want:=shares(mc);var have:=counts(mc)
	var total:=0
	for id in have:total+=int(have[id])
	total=maxi(total,int(_watch().call("manpower",mc)))
	var gear:={};var drill:={}
	for f in mc.home_army.get("formations",[])+_away_formations(mc):
		if not f is Dictionary:continue
		var id:=role_of(String((f as Dictionary).get("unit","levy")))
		if id=="":continue
		var count:=maxi(0,int((f as Dictionary).get("count",0)))
		var g:Array=gear.get(id,[0.0,0.0]);g[0]=float(g[0])+minf(float((f as Dictionary).get("equipment",0)),float((f as Dictionary).get("equipment_required",count)));g[1]=float(g[1])+float(maxi(1,int((f as Dictionary).get("equipment_required",count))));gear[id]=g
		var d:Array=drill.get(id,[0.0,0]);d[0]=float(d[0])+float((f as Dictionary).get("training",0.0))*count;d[1]=int(d[1])+count;drill[id]=d
	for r:Dictionary in ROLES:
		var id:=String(r.id)
		var kit:=kit_for(mc,id)
		# The best our people know of the kind, and what keeps its kit off
		# the workshop lines (a material short, a tool missing) when it is
		# not the one men take up today.
		var known:=best(mc,id,false)
		var waiting:=""
		if not known.is_empty() and (kit.is_empty() or float(known.worth)>float(kit.get("worth",worth(mc,String(kit.unit),String(kit.item))))+0.0001):
			var blockers:Array=mc.PersistentProduction.startup_blockers(mc,String(known.item))
			if not blockers.is_empty():waiting=String(blockers[0])
		if kit.is_empty():kit=known
		var g:Array=gear.get(id,[0.0,0.0]);var d:Array=drill.get(id,[0.0,0])
		out.append({"id":id,"label":String(r.label),"glyph":String(r.glyph),"tip":String(r.tip),"share":float(want[id]),
			"unit":String(kit.get("unit","")),"item":String(kit.get("item","")),"kind":kind_words(mc,kit),"can":not kit.is_empty(),"waiting":waiting,"best":kind_words(mc,known) if not known.is_empty() else "",
			"men":int(have[id]),"target":roundi(float(want[id])*float(total)),
			"armed":float(g[0])/float(g[1]) if float(g[1])>0.0 else -1.0,"drill":float(d[0])/float(d[1]) if int(d[1])>0 else -1.0})
	return out

static func _away_formations(mc:Variant)->Array:
	var out:Array=[]
	for force in mc.field_armies+mc.occupation_forces:
		if force is Dictionary:out.append_array((force as Dictionary).get("formations",[]))
	return out

## "Archers · bows"; "none yet" when our people can train none of the kind.
static func kind_words(mc:Variant,kit:Dictionary)->String:
	if kit.is_empty():return "none yet"
	var unit:=String((mc.UnitCatalog.ARCHETYPES.get(String(kit.unit),{}) as Dictionary).get("label",String(kit.unit).capitalize()))
	var item:=String(mc.PersistentProduction.product_name(String(kit.item))) if String(kit.item)!="improvised" else "what comes to hand"
	return "%s · %s" % [unit,item.to_lower()]

extends RefCounted
## Shared geographic food, in soldier-days. A 12 km district feeds twenty
## soldiers in ordinary country, regardless of how many flags/bands enter it.
## Saved on WorldSimulation; map workers receive immutable snapshots.
const FEEDS:=20.0
const TYPICAL:=0.42
const DISTRICT_KM:=12.0
const STOCK_DAYS:=20.0
const RECOVERY_DAYS:=60.0
const FLOOR:=0.1

static func district(p:Vector2)->String:
	return "%d:%d" % [floori(p.x/DISTRICT_KM),floori(p.y/DISTRICT_KM)]

static func capacity(rich:float,chill:float)->float:
	return FEEDS*clampf(rich/TYPICAL,0.3,1.5)*(1.0-0.7*clampf(chill,0.0,1.0))

static func position(force:Dictionary)->Vector2:
	var p:Variant=force.get("position",{})
	if p is Vector2:return p
	if p is Dictionary and p.has("x"):return Vector2(float(p.x),float(p.get("z",0.0)))
	return Vector2.INF

static func snapshot(exclude:Dictionary={})->Dictionary:
	var demands:Dictionary={}
	var armies:Array=[MilitaryCampaign]
	for actor:Dictionary in WorldSimulation.actors.values():armies.append(actor.systems.MilitaryCampaign)
	for mc in armies:
		for force:Dictionary in mc.field_armies:
			if is_same(force,exclude) or (mc==WorldSimulation.military and int(exclude.get("army_id",0))>0 and int(force.get("army_id",0))==int(exclude.get("army_id",0))) or mc._army_is_home(force):continue
			var p:=position(force)
			if not p.is_finite():continue
			var key:=district(p)
			demands[key]=int(demands.get(key,0))+maxi(0,int(force.get("troops",0)))
	return {"demands":demands,"land":WorldSimulation.forage_land.duplicate(true)}

## Existing-force forecast: replace the matching own band, while an added
## expedition (the map default) competes with every force already present.
static func at_point(p:Vector2,troops:int,one_more:bool)->Dictionary:
	if not one_more:
		for force:Dictionary in WorldSimulation.military.field_armies:
			if int(force.get("troops",0))==troops and position(force).distance_to(p)<0.01:return snapshot(force)
	return snapshot()

static func debt(row:Dictionary,day:int)->float:
	return maxf(0.0,float(row.get("debt",0.0))-maxi(0,day-int(row.get("day",day)))*float(row.get("stock",FEEDS*STOCK_DAYS))/RECOVERY_DAYS)

static func left(row:Dictionary,day:int,opening:=false)->float:
	var used:=float(row.get("used",0.0)) if opening and int(row.get("day",-1))==day else 0.0
	return clampf(1.0-(debt(row,day)-used)/maxf(1.0,float(row.get("stock",FEEDS*STOCK_DAYS))),FLOOR,1.0)

## Pure, also used on the supply-map worker. `extra` excludes this band from
## the snapshot, so it is counted once; a proposed expedition is additional.
static func factor(data:Dictionary,p:Vector2,day:int,rich:float,chill:float,extra:int)->float:
	var key:=district(p)
	var row:Dictionary=data.get("land",{}).get(key,{})
	var total:=maxi(1,extra+int(data.get("demands",{}).get(key,0)))
	return capacity(rich,chill)*left(row,day,true)/float(total)

## An actual withdrawal. The shared daily ceiling also prevents repeated
## ration calls, merging/splitting or actor processing order creating food.
static func take(p:Vector2,day:int,rich:float,chill:float,wanted:float,span:float)->float:
	if wanted<=0.0 or not p.is_finite():return 0.0
	var key:=district(p)
	var row:Dictionary=WorldSimulation.forage_land.get(key,{})
	if int(row.get("day",-1))!=day:
		var stock:=FEEDS*STOCK_DAYS*clampf(rich/TYPICAL,0.3,1.5)
		row={"day":day,"debt":debt(row,day),"stock":stock,"used":0.0}
		row["budget"]=capacity(rich,chill)*left(row,day)*maxf(1.0,span)
	var got:=minf(maxf(0.0,wanted),maxf(0.0,float(row.budget)-float(row.used)))
	row.used=float(row.used)+got
	row.debt=minf(float(row.stock),float(row.debt)+got)
	WorldSimulation.forage_land[key]=row
	# Recovered districts need no save record. No troop/actor history retained.
	for old:String in WorldSimulation.forage_land.keys():
		if old!=key and debt(WorldSimulation.forage_land[old],day)<=0.0:WorldSimulation.forage_land.erase(old)
	return got

static func valid(data:Variant)->bool:
	if not data is Dictionary:return false
	for key in data:
		if not key is String or key.length()>64 or not data[key] is Dictionary:return false
		var row:Dictionary=data[key]
		for field in ["day","debt","stock","used","budget"]:
			var n:Variant=row.get(field)
			if not (n is float or n is int) or not is_finite(float(n)) or float(n)<0.0:return false
		if float(row.stock)<=0.0 or float(row.debt)>float(row.stock) or float(row.used)>float(row.budget):return false
	return true

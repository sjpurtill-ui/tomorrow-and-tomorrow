extends RefCounted
## A fleet's blockade of a hostile port, run by the fleet's commander inside
## the drawn zone (a close or distant blockade chosen in battle_tactics.gd).
## It is a slow squeeze, not a switch: each day the port's blockade level
## climbs toward a ceiling at a rate set by how firmly the fleet holds the
## water, and eases again once the fleet leaves. The level cuts the port's
## sea-borne food and its trade, within fixed bounds.
##
## Calibration: blockades of the sail and steam eras cut a blockaded port's
## sea trade by a half to four fifths within months but rarely sealed it
## (runners got through), and a coastal state's food fell far less than its
## trade because most food came overland. So the level caps at 0.6 (close)
## or 0.4 (distant); trade loses at most 0.8 x level (about half at the close
## cap), sea food at most 0.5 x level, and a whole civilization's food and
## supply only in proportion to the share of its people living at that port.
##
## Pure static helpers over a plain ledger {city_id: entry}; joint_operations
## owns the ledger in its saved state.

## At full control a close blockade reaches its ceiling in about two months.
const CLOSE_RATE:=1.0/90.0
const DISTANT_RATE:=1.0/180.0
const CLOSE_CAP:=0.6
const DISTANT_CAP:=0.4
## How fast a lifted blockade eases (level per day).
const RELIEF_RATE:=1.0/30.0
const MAX_PORTS:=64
## Effect scales (see the calibration note).
const TRADE_LOSS:=0.8
const SEA_FOOD_LOSS:=0.5
const CIV_FOOD_LOSS:=0.35
const CIV_SUPPLY_LOSS:=0.3


static func rate_and_cap(tactic:String)->Vector2:
	if tactic=="close_blockade": return Vector2(CLOSE_RATE,CLOSE_CAP)
	if tactic=="distant_blockade": return Vector2(DISTANT_RATE,DISTANT_CAP)
	return Vector2.ZERO


## One day. `pressure` maps city_id -> {rate, cap, control, civ_id, owner,
## tactic, name}; the strongest fleet on a port sets its pressure. Returns the
## new ledger (entries that have eased to nothing are dropped).
static func step(ledger:Dictionary,pressure:Dictionary,day:int)->Dictionary:
	var out:Dictionary={}
	for city_id in ledger:
		var entry:Dictionary=(ledger[city_id] as Dictionary).duplicate()
		if pressure.has(city_id): continue
		entry.level=maxf(0.0,float(entry.get("level",0.0))-RELIEF_RATE)
		entry.held=false
		if float(entry.level)>0.005: out[city_id]=entry
	for city_id in pressure:
		if out.size()>=MAX_PORTS: break
		var p:Dictionary=pressure[city_id]
		var entry:Dictionary=(ledger.get(city_id,{}) as Dictionary).duplicate()
		var level:=float(entry.get("level",0.0))
		var cap:=clampf(float(p.get("cap",0.0)),0.0,CLOSE_CAP)
		var control:=clampf(float(p.get("control",0.0)),0.0,1.0)
		if level<cap: level=minf(cap,level+float(p.get("rate",0.0))*control)
		else: level=maxf(cap,level-RELIEF_RATE)
		if not entry.has("since"): entry.since=day
		entry.level=level; entry.held=true; entry.day=day
		for key in ["civ_id","owner","tactic","name"]: entry[key]=p.get(key,entry.get(key,""))
		out[city_id]=entry
	return out


static func trade_factor(level:float)->float:
	return clampf(1.0-TRADE_LOSS*clampf(level,0.0,CLOSE_CAP),0.0,1.0)


static func sea_food_factor(level:float)->float:
	return clampf(1.0-SEA_FOOD_LOSS*clampf(level,0.0,CLOSE_CAP),0.0,1.0)


## A civilization's exposure: blockade levels weighted by the share of its
## people living at each blockaded port (0..CLOSE_CAP).
static func closure(ledger:Dictionary,civ_id:String,share_of:Callable)->float:
	var total:=0.0
	for city_id in ledger:
		var entry:Dictionary=ledger[city_id]
		if String(entry.get("civ_id",""))!=civ_id: continue
		total+=float(entry.get("level",0.0))*clampf(float(share_of.call(String(city_id))),0.0,1.0)
	return clampf(total,0.0,CLOSE_CAP)


## Plain words for the map and the commander's note.
static func describe(entry:Dictionary,day:int)->String:
	var level:=float(entry.get("level",0.0))
	var days:=maxi(0,day-int(entry.get("since",day)))
	var cut:=roundi((1.0-trade_factor(level))*100.0)
	if not bool(entry.get("held",false)): return "The blockade has lifted; their sea trade is recovering (still about %d%% down)." % cut
	return "Blockaded %d days: their sea trade is down about %d%%, and less food comes in by sea." % [days,cut]

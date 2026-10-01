extends RefCounted
## THE STATED ODDS (docs/MILITARY_SYSTEM_V2.md, iteration 11, critic round 5).
## Before an attack on a town the war leader states the odds by the combat
## engine's own reading (combat_simulator.raw_odds): our force as it stands
## (morale, readiness, kit, stores and general) against the men our scouts
## counted there. They carry the arms the scouts saw, or ours when nobody saw
## them lately; they are drilled as a garrison is (GARRISON_DRILL) and as
## ready as their people's army; and they stand behind the walls the battle
## gives the town (civilization_system: 1.03 + 0.34 x fortification + 0.07 x
## logistics + 0.05 x institutions, 1.04 to 1.38).
## The Army grid's preview (army_orders.gd) and the court's spoken order
## (court_war_orders.gd) read the same odds, and the war leader objects as
## "the weaker side" by them (OBJECT_BELOW), so one panel never says both.
## Static helpers; preload.

const StrategyAI:=preload("res://scripts/civilization_strategy.gd")
const KitLedger:=preload("res://scripts/equipment_ledger.gd")

## How well a town's defenders are drilled when our scouts could not tell.
const GARRISON_DRILL:=0.7
## A count older than this says nothing trustworthy of their arms.
const ARMS_SEEN_DAYS:=90
## Odds against us by more than 5 to 4 (ours over theirs below this): the
## war leader objects that we would be the weaker side.
const OBJECT_BELOW:=0.8
## THE WAR COUNCIL'S LINES (war_council.gd), the same for every people:
## before going at a town's walls the war leader gathers until the odds are
## 3 to 2 for us; a raid on a town's fields and stores goes at even odds or
## better, with a band sized to make it 3 to 2 when the men are there.
const TAKE_ODDS:=1.5
const RAID_ODDS:=1.0
## The steps by which the war leader reckons how many more he would need.
const MORE_STEPS:=[1.1,1.25,1.5,1.75,2.0,2.5,3.0,4.0,6.0]
## Odds under this are "about even".
const EVEN_BELOW:=1.15
## Each named fraction covers the odds nearer to it than to its neighbours:
## [upper bound, numerator, denominator].
const BINS:=[[1.29,5,4],[1.42,4,3],[1.75,3,2],[2.5,2,1],[4.0,3,1],[6.0,5,1]]

## {odds (stronger over weaker, 1 or more), ours (true when with us),
##  raw (ours over theirs), walls} or {} when there is nothing to weigh.
## A host met in the open (`open_field`) has no walls, and its readiness is
## what our scouts made of it (`their_ready`, when given).
static func of(force:Dictionary,formations:Array,going:int,their_men:float,fortification:float,their_arms:Array=[],civ_id:String="",open_field:bool=false,their_ready:float=-1.0)->Dictionary:
	var mc:Variant=WorldSimulation.military
	var n:=heads(formations)
	if mc==null or n<=0 or going<=0 or their_men<1.0: return {}
	var sim=mc.simulator
	var us:Dictionary=sim.create_formation_force("Us",scaled(formations,float(going)/float(n)),float(force.get("morale",1.0)),float(force.get("readiness",1.0)))
	us["stores_share"]=float(force.get("stores_share",1.0))
	if force.get("commander") is Dictionary: us["commander"]=force.commander
	var kit:Array=their_arms if heads(their_arms)>0 else _as_a_garrison(formations)
	var civ:=_civ(civ_id)
	var fort:=clampf(fortification,0.0,1.0)
	var walls:=1.0 if open_field else clampf(1.03+fort*0.34+float(civ.get("logistics",0.0))*0.07+float(civ.get("institutions",0.0))*0.05,1.04,1.38)
	var ready:=clampf(float(civ.get("military_readiness",1.0))*0.82+float(civ.get("command_readiness",0.4))*0.18,0.1,1.0) if not civ.is_empty() else 1.0
	if their_ready>=0.0: ready=clampf(their_ready,0.1,1.0)
	var them:Dictionary=sim.create_formation_force("Them",scaled(kit,their_men/float(heads(kit))),1.0,ready)
	var raw:float=sim.raw_odds(us,them,walls)
	return {"odds":raw if raw>=1.0 else 1.0/maxf(0.0001,raw),"ours":raw>=1.0,"raw":raw,"walls":walls}

## True when the war leader would object that we are the weaker side.
static func weaker(odds:Dictionary)->bool:
	return not odds.is_empty() and float(odds.get("raw",1.0))<OBJECT_BELOW

## The odds a kind of blow wants before the war leader goes unbidden: 3 to 2
## at a town's walls, even odds for a raid on its fields and stores.
static func wanted(kind:String)->float:
	return RAID_ODDS if kind=="raid" else TAKE_ODDS

## How many more men than `going` (the same kit, drilled the same) would
## bring the odds to `want`: 0 when they already do, -1 when even six times
## as many would not. Bounded: a few readings of the combat engine.
static func more_for(force:Dictionary,formations:Array,going:int,their_men:float,fortification:float,their_arms:Array,civ_id:String,want:float,open_field:bool=false,their_ready:float=-1.0)->int:
	if going<=0 or heads(formations)<=0 or their_men<1.0: return -1
	var now:=of(force,formations,going,their_men,fortification,their_arms,civ_id,open_field,their_ready)
	if not now.is_empty() and float(now.raw)>=want: return 0
	for step in MORE_STEPS:
		var n:=ceili(float(going)*float(step))
		var o:=of(force,formations,n,their_men,fortification,their_arms,civ_id,open_field,their_ready)
		if not o.is_empty() and float(o.raw)>=want: return n-going
	return -1

## "about 3 to 2 for us" / "about 2 to 3 against us" from a reading of of().
static func said(odds:Dictionary)->String:
	if odds.is_empty(): return ""
	return words(float(odds.odds),bool(odds.ours))

## Our kit carried by men drilled as a garrison is, fully armed.
static func _as_a_garrison(formations:Array)->Array:
	var out:=[]
	for f in formations:
		var g:Dictionary=(f as Dictionary).duplicate()
		g["training"]=GARRISON_DRILL; g["experience"]=0.0
		g["equipment"]=int(g.get("equipment_required",g.get("equipment",0)))
		g.erase("ammunition")
		out.append(g)
	return out

static func _civ(civ_id:String)->Dictionary:
	var world:Variant=WorldSimulation.world
	if civ_id=="" or world==null: return {}
	var index:int=world._civilization_index(civ_id)
	return world.civilizations[index] if index>=0 else {}

## Their arms as our scouts saw them: the people's formations, when the count
## of the town is fresh enough to trust what they carry.
static func their_arms(civ_id:String,age:int)->Array:
	if civ_id=="" or age<0 or age>ARMS_SEEN_DAYS: return []
	return StrategyAI.arms_of(civ_id)

## "mostly spears, some bows and a few horses and lances".
static func arms_words(arms:Array)->String:
	var total:=0
	for f in arms: total+=maxi(0,int((f as Dictionary).get("count",0)))
	if total<=0: return ""
	var sorted:=arms.duplicate()
	sorted.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return int(a.count)>int(b.count))
	var parts:=PackedStringArray()
	var seen:={}
	for f:Dictionary in sorted:
		if parts.size()>=3: break
		var name:=KitLedger.label(String(f.get("weapon","improvised"))).to_lower().replace(" & "," and ")
		if seen.has(name): continue
		seen[name]=true
		var share:=float(int(f.count))/float(total)
		parts.append(("mostly " if share>=0.5 else ("some " if share>=0.15 else "a few "))+name)
	if parts.size()==1: return parts[0]
	return ", ".join(parts.slice(0,parts.size()-1))+" and "+parts[-1]

## [numerator, denominator] of the named fraction, [0,0] for even, [-1,-1]
## beyond the last.
static func _bin(odds:float)->Array:
	if odds<EVEN_BELOW: return [0,0]
	for row in BINS:
		if odds<float(row[0]): return [int(row[1]),int(row[2])]
	return [-1,-1]

## "about 3 to 2 for us", "about even", "more than 5 to 1 against us".
static func words(odds:float,ours:bool)->String:
	var b:=_bin(odds)
	var side:="for us" if ours else "against us"
	if int(b[0])==0: return "about even"
	if int(b[0])<0: return "more than 5 to 1 %s" % side
	return "about %d to %d %s" % [int(b[0]),int(b[1]),side]

## "3:2" (for us), "2:3" (against us), "even": the summary line's form.
static func short(odds:float,ours:bool)->String:
	var b:=_bin(odds)
	if int(b[0])==0: return "even"
	if int(b[0])<0: return ">5:1" if ours else "<1:5"
	return "%d:%d" % [int(b[0]),int(b[1])] if ours else "%d:%d" % [int(b[1]),int(b[0])]

static func scaled(formations:Array,share:float)->Array:
	var out:=[]
	for f in formations:
		var g:Dictionary=(f as Dictionary).duplicate()
		for key in ["count","authorized_count","equipment","equipment_required","ammunition","ammunition_required"]:
			if g.has(key): g[key]=maxi(0,roundi(float(g[key])*share))
		out.append(g)
	return out

static func heads(formations:Array)->int:
	var n:=0
	for f in formations: n+=maxi(0,int((f as Dictionary).get("count",0)))
	return n

extends RefCounted
## BATTLE BLOCKS: how a battle of any size is fought and read.
##
## Each side is gathered into era-sized blocks: bands in the first ages,
## companies, battalions and regiments later, brigades and divisions in the
## age of rifles and motors. Blocks grow with the force, so a side never has
## more than about MAX_BLOCKS of them, whether it is twenty people or two
## hundred thousand. Each block keeps the arm of the formation it came from
## (spear, bow, sling, horse, pike, musket, rifle, guns, armour...), its men,
## and its cohesion: the will to keep fighting, 0 to 1.
##
## The ground allows only so many to fight at once (the frontage). Open
## country is wide; a forest edge, a pass, a ford or a bridge is narrow; at
## walls only the breach or the gate can be fought over. A blow on the flank
## widens the front both sides must hold. Front blocks fight and take the
## losses; the rest wait in reserve and go in when a front block is worn out
## or breaks. A block with no cohesion left breaks and leaves the field: some
## are cut down, some hurt, some taken, most run.
##
## Exchanges are grouped into phases (a couple of hours in the early ages,
## longer later). Each phase the generals may change how they fight
## (battle_tactics.gd rechoose), and each phase is recorded with a snapshot of
## every block, both tactics, the losses, what changed and why one side is
## winning, so a battle can be stepped through later without being fought again.
##
## Pure and static: combat_simulator.gd calls it once per exchange and carries
## the plain-data state between calls. Nothing here reads the world.

const MAX_BLOCKS:=24
## Hard ceiling on blocks a side (after arms are kept apart).
const BLOCK_CEILING:=32
const TIERS:=["stone","bronze","classical","gunpowder","industrial","modern"]
## Smallest block for each age: a band, a band, a company, a company, a
## battalion, a battalion.
const BASE_SIZE:=[30,40,100,120,250,250]
## Men who can be in the fight at once on open ground, by age.
const FRONT_MEN:=[8000,12000,16000,20000,24000,30000]
## Exchanges in a phase, by age: two hours early, four hours in the rifle age.
const PHASE_EXCHANGES:=[4,4,4,6,8,8]
## How much of the line is struck in half an hour of fighting, by age (1.0:
## close order, shield to shield). Muskets fight at range in open order;
## rifle, machine-gun and armoured lines are dispersed and dug in, so a host
## bleeds a few in a hundred an hour and a great battle lasts a day or days
## (Breitenfeld and Waterloo a long day; Antietam and Sedan a day; armoured
## battles days), not an hour (tests/test_battle_eval.gd ranges).
const LETHALITY:=[1.0,1.0,1.0,0.35,0.14,0.08]
## Limits on a battle's length in exchanges (thirty minutes each).
const MIN_EXCHANGES:=12
const MAX_EXCHANGES:=48
## A block's cohesion is the army's heart times the block's own condition
## (1.0 fresh), which only losses beyond the army's own wear down. A front
## block is relieved when its condition falls below ROTATE_BELOW and a
## waiting block at READY_AT or better can go in.
const ROTATE_BELOW:=0.45
const READY_AT:=0.75
## A block breaks at the same point a whole army breaks (MORALE_BREAK).
const BREAK_AT:=0.15
## Losses to blocks waiting in reserve, as a share of a front block's
## exposure: nothing reaches them before guns, a little after.
const RESERVE_EXPOSURE:=[0.02,0.02,0.03,0.08,0.15,0.15]
## Fire from blocks waiting behind the line: guns shoot over it, bows a little.
const SUPPORT:={"guns":0.6,"bow":0.15,"sling":0.1,"javelin":0.05,"machine_gun":0.2}
## Condition regained per exchange out of the fight.
const REST:=0.04
## After this many exchanges in the line without relief, a block tires.
const FRESH_EXCHANGES:=4
## Attacking across a river: weaker blows, more exposed (the far bank holds).
const RIVER_ATTACK:=0.8
const RIVER_EXPOSURE:=1.1
## A hungry side fights a little worse and loses heart a little faster.
const HUNGER_POWER:=0.92
const HUNGER_DRAIN:=1.15

## The ground, as the battle sees it. width: share of FRONT_MEN that can be
## in the fight; flank: whether there is room to come round a side.
const GROUNDS:={
	"open":{"width":1.0,"flank":true,"words":"open ground"},
	"rough":{"width":0.6,"flank":true,"words":"broken, hilly ground"},
	"forest":{"width":0.4,"flank":true,"words":"a forest edge"},
	"marsh":{"width":0.35,"flank":false,"words":"marshy ground"},
	"pass":{"width":0.15,"flank":false,"words":"a narrow pass"},
	"ford":{"width":0.12,"flank":false,"river":true,"words":"a ford"},
	"bridge":{"width":0.03,"flank":false,"river":true,"words":"a bridge"},
	"breach":{"width":0.06,"flank":false,"walls":true,"words":"a breach in the walls"},
	"gate":{"width":0.02,"flank":false,"walls":true,"words":"the gate"},
}

## Era of a unit (index into TIERS). Weapons can date a unit later.
const UNIT_TIER:={
	"levy":0,"skirmisher":0,"slinger":0,"javelineer":0,"archer":0,"axeman":0,
	"spearman":1,"line_infantry":1,"chariot":1,"cavalry":1,"light_cavalry":1,"horse_archer":1,"siege_engineer":1,"ram_crew":1,
	"heavy_swordsman":2,"pikeman":2,"crossbowman":2,"armored_cavalry":2,"war_elephant":2,"catapult_crew":2,"trebuchet_crew":2,"light_infantry":2,
	"hand_cannoneer":3,"musketeer":3,"grenadier":3,"dragoon":3,"bombard_crew":3,"horse_artillery":3,"field_artillery":3,"sharpshooter":3,
	"rifle_infantry":4,"machine_gun_company":4,"mortar_crew":4,"assault_infantry":4,"combat_engineer":4,"marines":4,"anti_tank":4,"anti_air":4,"armored_car":4,"mountain_infantry":4,
	"motorized_infantry":5,"armored_formation":5,"modern_artillery":5,"light_tank":5,"heavy_tank":5,"tank_destroyer":5,"mechanized_infantry":5,"rocket_artillery":5,"air_assault":5,"paratrooper":5,
}
const WEAPON_TIER:={"musket":3,"hand_cannon":3,"grenadier_kit":3,"dragoon_kit":3,"bombard":3,"horse_gun":3,"field_gun":3,
	"service_rifle":4,"machine_gun":4,"mortar":4,"marksman_rifle":4,"assault_kit":4,"marine_kit":4,"engineering_kit":4,"anti_tank_kit":4,"anti_air_gun":4,"armored_car_kit":4,"mountain_kit":4,
	"motorized_kit":5,"armored_vehicle":5,"modern_field_gun":5,"light_tank_kit":5,"heavy_tank_kit":5,"tank_destroyer_kit":5,"mechanized_kit":5,"rocket_launcher":5,"air_assault_kit":5,"airborne_kit":5}

## Order in which a general puts arms into the line: foot and missiles first,
## horse held for the flanks and the pursuit, guns and engineers behind.
const DEPLOY_ORDER:={"spear":3,"pike":3,"sword":3,"axe":3,"club":3,"musket":3,"rifle":3,"machine_gun":3,"armour":3,"elephant":3,
	"bow":2,"sling":2,"javelin":2,"horse":1,"chariot":1,"guns":0,"engineers":0,"support":0}


# --- Arms and ages --------------------------------------------------------------

## The arm a formation fights as, for its icon and its words.
static func arm_of(unit:String,weapon:String="")->String:
	match unit:
		"skirmisher","archer","crossbowman","horse_archer": return "bow" if unit!="horse_archer" else "horse"
		"slinger": return "sling"
		"javelineer": return "javelin"
		"cavalry","light_cavalry","armored_cavalry","dragoon": return "horse"
		"chariot": return "chariot"
		"war_elephant": return "elephant"
		"pikeman": return "pike"
		"heavy_swordsman": return "sword"
		"axeman": return "axe"
		"hand_cannoneer","musketeer","grenadier": return "musket"
		"sharpshooter","rifle_infantry","assault_infantry","marines","paratrooper","mountain_infantry","motorized_infantry","mechanized_infantry","air_assault","light_infantry": return "rifle" if int(UNIT_TIER.get(unit,0))>=4 or unit=="sharpshooter" else "spear"
		"machine_gun_company": return "machine_gun"
		"field_artillery","modern_artillery","catapult_crew","trebuchet_crew","bombard_crew","horse_artillery","mortar_crew","rocket_artillery","anti_air": return "guns"
		"armored_formation","light_tank","heavy_tank","tank_destroyer","armored_car","anti_tank": return "armour" if unit!="anti_tank" else "guns"
		"siege_engineer","combat_engineer","ram_crew": return "engineers"
		"field_repair_company","medical_detachment": return "support"
		"spearman": return "spear"
		"line_infantry":
			if weapon in ["musket","hand_cannon"]: return "musket"
			if weapon in ["service_rifle","marksman_rifle"]: return "rifle"
			if weapon in ["sword_shield"]: return "sword"
			return "spear"
		"levy":
			if weapon in ["spear","shield_spear","padded_spear"]: return "spear"
			if weapon=="bow": return "bow"
			return "club"
	if weapon in ["bow","crossbow"]: return "bow"
	if weapon=="sling": return "sling"
	return "spear"


## The age a force fights in: the latest arm that makes up a real share of it.
static func tier_of(force:Dictionary)->int:
	var total:=0
	var formations:Array=force.get("formations",[])
	for formation_variant in formations:
		if formation_variant is Dictionary: total+=maxi(0,int((formation_variant as Dictionary).get("count",0)))
	var tier:=0
	for formation_variant in formations:
		if not formation_variant is Dictionary: continue
		var formation:Dictionary=formation_variant
		var count:=maxi(0,int(formation.get("count",0)))
		if count<=0 or float(count)<float(total)*0.05: continue
		tier=maxi(tier,maxi(int(UNIT_TIER.get(String(formation.get("unit","levy")),0)),weapon_tier(String(formation.get("weapon","")))))
	return clampi(tier,0,TIERS.size()-1)


## The age a kit dates its bearers to: the table where it names the kit,
## otherwise the kit's year in the equipment ledger (gunpowder, rifles and
## motors; anything later fights at the last age's pace).
static func weapon_tier(weapon:String)->int:
	if WEAPON_TIER.has(weapon): return int(WEAPON_TIER[weapon])
	var year:=preload("res://scripts/equipment_ledger.gd").year(weapon)
	if year>=2600.0: return 5
	if year>=2500.0: return 4
	if year>=1800.0: return 3
	return 0


## A round size a clerk would give a unit of this many.
static func nice_size(n:int)->int:
	var steps:=[10,12,15,20,25,30,40,50,60,75,100,120,150,200,250,300,400,500,600,750,1000,1200,1500,2000,2500,3000,4000,5000,6000,7500]
	for step in steps:
		if n<=int(step): return int(step)
	var scale:=10000
	while true:
		for mult in [1,1.2,1.5,2,2.5,3,4,5,6,7.5]:
			var value:=roundi(float(scale)*float(mult))
			if n<=value: return value
		scale*=10
	return n


## The plain word for one block of this size in this age.
static func block_word(size:int,tier:int)->String:
	if tier<=1: return "band" if size<150 else ("war party" if size<1000 else "host")
	if size<250: return "company"
	if tier==2: return "battalion" if size<1200 else "regiment"
	if size<1200 or (tier>=4 and size<1500): return "battalion"
	if size<3500: return "regiment"
	if size<8000 or tier<=3: return "brigade"
	return "division"


static func plural(word:String)->String:
	if word=="war party": return "war parties"
	return word+"es" if word.ends_with("s") or word.ends_with("h") else word+"s"


# --- Blocks ------------------------------------------------------------------------

## Gathers a side into blocks. Returns {size, word, tier, blocks:[{id, arm,
## unit, weapon, men0, members:[[formation index, men]]}]}. Formations of the
## same arm share blocks; a large formation is split across several.
static func build_side(force:Dictionary,prefix:String,tier:int)->Dictionary:
	var formations:Array=force.get("formations",[])
	if formations.is_empty():
		# A force known only by its head count is one body of fighters.
		formations=[{"unit":"levy","weapon":"improvised","count":maxi(0,int(force.get("troops",force.get("population",0))))}]
	var troops:=0
	var groups:Dictionary={}
	var order:Array=[]
	for index in formations.size():
		var formation:Dictionary=formations[index]
		var count:=maxi(0,int(formation.get("count",0)))
		if count<=0: continue
		troops+=count
		var arm:=arm_of(String(formation.get("unit","levy")),String(formation.get("weapon","")))
		var key:=arm+"|"+String(formation.get("unit","levy"))
		if not groups.has(key):
			groups[key]={"arm":arm,"unit":String(formation.get("unit","levy")),"weapon":String(formation.get("weapon","")),"parts":[]}
			order.append(key)
		(groups[key].parts as Array).append([index,count])
	if troops<=0 and not formations.is_empty():
		# A side with nobody left still gets one empty block to show.
		var first:Dictionary=formations[0]
		var arm0:=arm_of(String(first.get("unit","levy")),String(first.get("weapon","")))
		return {"size":BASE_SIZE[tier],"word":block_word(BASE_SIZE[tier],tier),"tier":tier,"blocks":[{"id":prefix+"0","arm":arm0,"unit":String(first.get("unit","levy")),"weapon":String(first.get("weapon","")),"men0":0,"members":[[0,0]]}]}
	var room:=maxi(1,MAX_BLOCKS-maxi(0,order.size()-1))
	var size:=maxi(int(BASE_SIZE[tier]),nice_size(ceili(float(troops)/float(room))))
	var blocks:Array=[]
	for attempt in 6:
		blocks=_pack(groups,order,size,prefix)
		if blocks.size()<=BLOCK_CEILING: break
		size=nice_size(size+1)
	return {"size":size,"word":block_word(size,tier),"tier":tier,"blocks":blocks}


static func _pack(groups:Dictionary,order:Array,size:int,prefix:String)->Array:
	var blocks:Array=[]
	for key in order:
		var group:Dictionary=groups[key]
		var current:Array=[]
		var filled:=0
		var group_blocks:Array=[]
		for part in group.parts:
			var index:=int(part[0]); var left:=int(part[1])
			while left>0:
				var take:=mini(left,size-filled)
				current.append([index,take]); filled+=take; left-=take
				if filled>=size:
					group_blocks.append(current); current=[]; filled=0
		if not current.is_empty():
			# A small remainder joins the block before it rather than stand alone.
			if not group_blocks.is_empty() and filled<int(float(size)*0.4):
				var last:Array=group_blocks[-1]
				for member in current:
					var merged:=false
					for existing in last:
						if int(existing[0])==int(member[0]): existing[1]=int(existing[1])+int(member[1]); merged=true; break
					if not merged: last.append(member)
			else: group_blocks.append(current)
		for members in group_blocks:
			var men:=0
			for member in members: men+=int(member[1])
			blocks.append({"id":"%s%d" % [prefix,blocks.size()],"arm":String(group.arm),"unit":String(group.unit),"weapon":String(group.weapon),"men0":men,"members":members})
	return blocks


## The ground the battle is fought on, from what the caller knows: an
## explicit ground kind, or the old defended-ground number alone.
static func ground_of(options:Dictionary)->Dictionary:
	var given:Variant=options.get("ground",{})
	var kind:=""
	if given is Dictionary: kind=String((given as Dictionary).get("kind",""))
	elif given is String: kind=String(given)
	if not GROUNDS.has(kind):
		var terrain:=float(options.get("terrain_defense",1.0))
		kind="rough" if terrain>=1.25 else "open"
	var spec:Dictionary=GROUNDS[kind]
	var out:={"kind":kind,"width":float(spec.width),"flank":bool(spec.flank),"river":bool(spec.get("river",false)),"walls":bool(spec.get("walls",false))}
	if given is Dictionary and (given as Dictionary).has("label"): out["label"]=String(given.label)
	return out


## Men who can be in the fight at once for each side.
static func capacity(tier:int,ground:Dictionary,directions:int)->int:
	var width:=clampf(float(ground.get("width",1.0)),0.005,1.0)
	var extra:=clampi(directions,0,2) if bool(ground.get("flank",true)) else 0
	return maxi(1,roundi(float(FRONT_MEN[clampi(tier,0,TIERS.size()-1)])*width*(1.0+0.5*float(extra))))


# --- The battle state ------------------------------------------------------------

## A new battle between two normalized forces. options: ground, max_rounds,
## tactics (the plan), phase_exchanges (override). Pure data.
static func begin(attacker:Dictionary,defender:Dictionary,options:Dictionary={})->Dictionary:
	var tiers:={"attacker":tier_of(attacker),"defender":tier_of(defender)}
	var era:=maxi(int(tiers.attacker),int(tiers.defender))
	var ground:=ground_of(options)
	var state:={"v":1,"tier":tiers,"era":era,"ground":ground,"exchange":0,
		"phase_len":int(options.get("phase_exchanges",PHASE_EXCHANGES[era])),
		"sides":{},"live":{},"initial":{},"morale0":{},"progress":0.0,"trend":0.0,"phases":[],"events":[],
		"cur":{},"directions":0}
	var forces:={"attacker":attacker,"defender":defender}
	for side in ["attacker","defender"]:
		var force:Dictionary=forces[side]
		var built:=build_side(force,"a" if side=="attacker" else "d",int(tiers[side]))
		state.sides[side]=built
		var morale:=clampf(float(force.get("morale",1.0)),0.0,1.0)
		state.morale0[side]=morale
		var live:Array=[]
		var total:=0
		for block in built.blocks:
			var members:Array=block.members
			var men:Array=[]
			for member in members: men.append(int(member[1]))
			live.append({"men":int(block.men0),"m":men,"c":morale,"cond":1.0,"st":"reserve","fat":0,"slot":-1,"k":0,"w":0,"f":0,"cap":0,"broke_at":-1})
			total+=int(block.men0)
		state.live[side]=live
		state.initial[side]=total
	state.directions=_directions(options.get("tactics",{}))
	state.capacity=capacity(era,ground,int(state.directions))
	var biggest:=maxi(int(state.initial.attacker),int(state.initial.defender))
	var waves:=ceili(float(biggest)/float(maxi(1,int(state.capacity))))
	# A slower age (dispersed lines) fights longer before it is decided.
	state.max_exchanges=clampi(roundi(float(MIN_EXCHANGES*maxi(1,waves))/float(LETHALITY[era])),MIN_EXCHANGES,MAX_EXCHANGES)
	state.cur=_new_phase(1)
	deploy(state,{},true)
	state.start=snapshot(state)
	return state


static func _new_phase(from:int)->Dictionary:
	return {"from":from,"losses":{"attacker":{"k":0,"w":0,"f":0,"c":0},"defender":{"k":0,"w":0,"f":0,"c":0}},"events":[],"tactics":{},"changes":{}}


static func _directions(plan:Variant)->int:
	if not plan is Dictionary or (plan as Dictionary).is_empty(): return 0
	var most:=0
	for role in ["attacker","defender"]:
		var entry:Variant=(plan as Dictionary).get(role,{})
		if entry is Dictionary: most=maxi(most,preload("res://scripts/battle_tactics.gd").extra_directions(String((entry as Dictionary).get("id",""))))
	return most


## Whether this battle is fought as blocks with a frontage at all: a side too
## big for the ground has reserves. Small fights keep every block in the line.
static func limited(state:Dictionary)->bool:
	return maxi(int(state.initial.get("attacker",0)),int(state.initial.get("defender",0)))>int(state.get("capacity",0))


# --- The line: who fights, who waits ----------------------------------------------

## Puts blocks into the line at the start of an exchange: worn front blocks are
## relieved by fresh ones, gaps left by broken blocks are filled, and the line
## is filled to the frontage. Returns the changes as structured events.
static func deploy(state:Dictionary,plan:Dictionary,opening:bool=false)->Array:
	var directions:=_directions(plan) if not plan.is_empty() else int(state.get("directions",0))
	if directions!=int(state.get("directions",0)):
		state.directions=directions
		state.capacity=capacity(int(state.era),state.ground,directions)
		if not opening and directions>0 and bool(state.ground.get("flank",true)):
			_event(state,{"k":"widened","side":_flanker(plan)})
	var events:Array=[]
	var cap:=int(state.capacity)
	for side in ["attacker","defender"]:
		var blocks:Array=state.sides[side].blocks
		var live:Array=state.live[side]
		# One pass: the line as it stands, and whether anything can change.
		var front_men:=0; var front_count:=0; var worst:=2.0; var waiting:=0; var ready:=0
		var used:={}
		for block in live:
			var st:String=block.st
			if st=="front":
				front_men+=int(block.men); front_count+=1; worst=minf(worst,float(block.get("cond",1.0))); used[int(block.slot)]=true
			elif st=="reserve" and int(block.men)>0:
				waiting+=1
				if float(block.get("cond",1.0))>=READY_AT: ready+=1
		if waiting==0: continue
		var threshold:=0.0 if opening else READY_AT
		if not opening and worst>=ROTATE_BELOW and front_count>0 and (front_men>=cap or ready==0): continue
		var flank_side:=_directions_for(plan,side)>0
		var queue:=_queue(blocks,live,flank_side,threshold)
		var next:=0
		# Relieve worn blocks with fresh ones, slot for slot.
		var relieved:=0
		var slots:Array=[]
		if not opening and worst<ROTATE_BELOW:
			for index in live.size():
				if next>=queue.size(): break
				var block:Dictionary=live[index]
				if String(block.st)!="front" or float(block.get("cond",1.0))>=ROTATE_BELOW: continue
				var incoming:=int(queue[next]); next+=1
				live[incoming].st="front"; live[incoming].slot=int(block.slot); live[incoming].fat=0
				front_men+=int(live[incoming].men)-int(block.men)
				block.st="reserve"; block.slot=-1
				relieved+=1; slots.append(int(live[incoming].slot))
		# Fill the line up to the frontage (at least one block always fights).
		var filled:=0
		while next<queue.size() and (front_men<cap or front_count+filled==0):
			var index:=int(queue[next])
			var men:=int(live[index].men)
			if front_men>0 and front_men+men>cap+men/2: break
			next+=1
			var slot:=0
			while used.has(slot): slot+=1
			used[slot]=true
			live[index].st="front"; live[index].slot=slot; live[index].fat=0
			front_men+=men
			filled+=1; slots.append(slot)
		if front_count+filled==0:
			var any:=_queue(blocks,live,flank_side,0.0)
			if not any.is_empty():
				var slot:=0
				while used.has(slot): slot+=1
				live[int(any[0])].st="front"; live[int(any[0])].slot=slot
				filled+=1; slots.append(slot)
		# The line shrank (a flank attack given up): pull the most worn out.
		while front_men>cap*3/2 and front_count+filled>1:
			var worn:=-1
			for index in live.size():
				if String(live[index].st)=="front" and (worn<0 or float(live[index].get("cond",1.0))<float(live[worn].get("cond",1.0))): worn=index
			front_men-=int(live[worn].men); live[worn].st="reserve"; live[worn].slot=-1
			front_count-=1
		if not opening and relieved+filled>0:
			events.append({"k":"reserve_in","side":side,"n":relieved+filled,"slots":slots,"relieved":relieved,"word":String(state.sides[side].word)})
	for event in events: _event(state,event)
	return events


## Waiting blocks fit to go in, in the order a general sends them: the right
## arm first, then the freshest, then the biggest. One native sort of packed
## keys (score descending, block index in the low bits).
static func _queue(blocks:Array,live:Array,flanking:bool,min_cohesion:float)->PackedInt64Array:
	var keys:=PackedInt64Array()
	for index in live.size():
		var block:Dictionary=live[index]
		if String(block.st)!="reserve" or int(block.men)<=0 or float(block.get("cond",1.0))<min_cohesion: continue
		var score:=_priority(String(blocks[index].arm),flanking)*100000000+roundi(float(block.get("cond",1.0))*20.0)*1000000+mini(999999,int(block.men))
		keys.append(-score*128+index)
	keys.sort()
	for i in keys.size(): keys[i]=posmod(keys[i],128)
	return keys


static func _flanker(plan:Dictionary)->String:
	var BattleTactics:=preload("res://scripts/battle_tactics.gd")
	for role in ["attacker","defender"]:
		if BattleTactics.extra_directions(String((plan.get(role,{}) as Dictionary).get("id","")))>0: return role
	return ""


static func _directions_for(plan:Dictionary,side:String)->int:
	if plan.is_empty(): return 0
	return preload("res://scripts/battle_tactics.gd").extra_directions(String((plan.get(side,{}) as Dictionary).get("id","")))


static func _front(live:Array)->Array:
	var out:Array=[]
	for index in live.size():
		if String(live[index].st)=="front": out.append(index)
	out.sort_custom(func(a:int,b:int)->bool: return int(live[a].slot)<int(live[b].slot))
	return out


static func _priority(arm:String,flanking:bool)->int:
	var base:=int(DEPLOY_ORDER.get(arm,2))
	if flanking and arm in ["horse","chariot"]: base=3
	return base


# --- The exchange ---------------------------------------------------------------------

## Per-formation weights for fighting power: the share of each formation's men
## in the line, scaled by their block's heart relative to the army's, their
## freshness, and fire from the guns and bows behind. All in the line at full
## heart gives 1.0 everywhere, so a small fight is exactly the old one.
static func weights(state:Dictionary,side:String,formation_count:int,morale:float)->PackedFloat32Array:
	var out:=PackedFloat32Array(); out.resize(formation_count); out.fill(0.0)
	var totals:=PackedFloat32Array(); totals.resize(formation_count); totals.fill(0.0)
	var blocks:Array=state.sides[side].blocks
	var live:Array=state.live[side]
	var morale_floor:=maxf(0.05,morale)
	for b in blocks.size():
		var block:Dictionary=live[b]
		var members:Array=blocks[b].members
		var st:=String(block.st)
		var factor:=0.0
		if st=="front":
			factor=clampf(float(block.c)/morale_floor,0.3,1.6)*fatigue_factor(int(block.fat))
		elif st=="reserve":
			factor=float(SUPPORT.get(String(blocks[b].arm),0.0))*clampf(float(block.c)/morale_floor,0.3,1.6)
		for j in members.size():
			var f:=int(members[j][0])
			if f<0 or f>=formation_count: continue
			var men:=float((block.m as Array)[j])
			totals[f]+=men
			out[f]+=men*factor
	for f in formation_count:
		out[f]=out[f]/totals[f] if totals[f]>0.0 else 0.0
	return out


static func fatigue_factor(fatigue:int)->float:
	return clampf(1.0-0.025*float(maxi(0,fatigue-FRESH_EXCHANGES)),0.8,1.0)


## Men in the line on a side.
static func front_men(state:Dictionary,side:String)->int:
	var total:=0
	for block in state.live[side]:
		if String(block.st)=="front": total+=int(block.men)
	return total


## Men still in the fight (in the line or waiting) on a side.
static func standing_men(state:Dictionary,side:String)->int:
	var total:=0
	for block in state.live[side]:
		if String(block.st) in ["front","reserve"]: total+=int(block.men)
	return total


## Per-formation multipliers on how many losses a formation takes: in the line
## it is fully exposed, waiting it is almost out of reach (until guns).
static func exposure(state:Dictionary,side:String,formation_count:int)->PackedFloat32Array:
	var out:=PackedFloat32Array(); out.resize(formation_count); out.fill(1.0)
	var weighted:=PackedFloat32Array(); weighted.resize(formation_count); weighted.fill(0.0)
	var totals:=PackedFloat32Array(); totals.resize(formation_count); totals.fill(0.0)
	var blocks:Array=state.sides[side].blocks
	var live:Array=state.live[side]
	var reach:=float(RESERVE_EXPOSURE[int(state.era)])
	for b in blocks.size():
		var st:=String(live[b].st)
		var factor:=1.0 if st=="front" else (reach if st=="reserve" else 0.0)
		var members:Array=blocks[b].members
		for j in members.size():
			var f:=int(members[j][0])
			if f<0 or f>=formation_count: continue
			var men:=float((live[b].m as Array)[j])
			totals[f]+=men; weighted[f]+=men*factor
	for f in formation_count:
		if totals[f]>0.0: out[f]=weighted[f]/totals[f]
	return out


## Keeps blocks in step with their formations: a formation's men are the sum of
## its members across blocks. Anything that changed a formation outside the
## battle (it should not) is spread back over its blocks.
static func reconcile(state:Dictionary,side:String,formations:Array)->void:
	if formations.is_empty(): return
	var blocks:Array=state.sides[side].blocks
	var live:Array=state.live[side]
	var held:={}
	for b in blocks.size():
		var members:Array=blocks[b].members
		for j in members.size():
			var f:=int(members[j][0])
			held[f]=int(held.get(f,0))+int((live[b].m as Array)[j])
	for f in held:
		var actual:=maxi(0,int((formations[int(f)] as Dictionary).get("count",0))) if int(f)<formations.size() else 0
		var have:=int(held[f])
		if actual<have: take_formation_loss(state,side,int(f),have-actual,true)
		elif actual>have: _add_to_formation(state,side,int(f),actual-have)


static func _add_to_formation(state:Dictionary,side:String,f:int,gain:int)->void:
	var blocks:Array=state.sides[side].blocks
	var live:Array=state.live[side]
	for b in blocks.size():
		if String(live[b].st) in ["broken","fled"]: continue
		var members:Array=blocks[b].members
		for j in members.size():
			if int(members[j][0])!=f: continue
			(live[b].m as Array)[j]=int((live[b].m as Array)[j])+gain
			live[b].men=int(live[b].men)+gain
			return


## Where each formation's men sit: for each formation a flat list of block
## and member positions [b, j, b, j, ...]. Membership never changes during a
## battle, so a caller builds this once.
static func index_of(state:Dictionary,side:String,formation_count:int)->Array:
	var out:Array=[]
	for f in formation_count: out.append(PackedInt32Array())
	var blocks:Array=state.sides[side].blocks
	for b in blocks.size():
		var members:Array=blocks[b].members
		for j in members.size():
			var f:=int(members[j][0])
			if f>=0 and f<formation_count:
				(out[f] as PackedInt32Array).append(b); (out[f] as PackedInt32Array).append(j)
	return out


## Spreads one formation's losses over the blocks it is in: the blocks in the
## line first, waiting blocks only as far as fire reaches them.
static func take_formation_loss(state:Dictionary,side:String,f:int,loss:int,any_block:bool=false,where:PackedInt32Array=PackedInt32Array())->Array:
	var blocks:Array=state.sides[side].blocks
	var live:Array=state.live[side]
	var reach:=float(RESERVE_EXPOSURE[int(state.era)])
	var slots:Array=[]
	var total:=0.0
	if where.is_empty():
		for b in blocks.size():
			var members:Array=blocks[b].members
			for j in members.size():
				if int(members[j][0])==f: where.append(b); where.append(j)
	for k in range(0,where.size(),2):
		var b:=int(where[k]); var j:=int(where[k+1])
		var men:=int((live[b].m as Array)[j])
		if men<=0: continue
		var st:=String(live[b].st)
		var weight:=float(men)*(1.0 if st=="front" or any_block else (reach if st=="reserve" else 0.0))
		slots.append([b,j,men,weight]); total+=weight
	var taken:=[]
	if slots.is_empty() or loss==0: return taken
	if total<=0.0:
		for slot in slots: slot[3]=float(slot[2]); total+=float(slot[2])
	var left:=loss
	var shares:Array=[]
	for slot in slots:
		var exact:=float(loss)*float(slot[3])/total
		var whole:=mini(int(slot[2]),floori(exact))
		shares.append([whole,exact-float(whole)])
		left-=whole
	while left>0:
		var best:=-1
		for i in slots.size():
			if int(shares[i][0])>=int(slots[i][2]): continue
			if best<0 or float(shares[i][1])>float(shares[best][1]): best=i
		if best<0: break
		shares[best][0]=int(shares[best][0])+1; shares[best][1]=-1.0; left-=1
	for i in slots.size():
		var b:=int(slots[i][0]); var j:=int(slots[i][1]); var n:=int(shares[i][0])
		if n<=0: continue
		(live[b].m as Array)[j]=int((live[b].m as Array)[j])-n
		live[b].men=int(live[b].men)-n
		taken.append([b,n])
	return taken


## Books an exchange's losses on the blocks (from the formations' losses) and
## returns each block's losses this exchange.
static func book_losses(state:Dictionary,side:String,cohort_losses:Array,index:Array=[])->Dictionary:
	var by_block:={}
	for f in cohort_losses.size():
		var loss:=int(cohort_losses[f])
		if loss<=0: continue
		for taken in take_formation_loss(state,side,f,loss,false,index[f] if f<index.size() else PackedInt32Array()):
			by_block[int(taken[0])]=int(by_block.get(int(taken[0]),0))+int(taken[1])
	return by_block


## Cohesion after an exchange. Blocks in the line lose heart with their own
## losses (against their own starting strength, as the army loses morale
## against its own) and under pressure; tired and hungry blocks faster.
## Waiting blocks recover toward the army's heart. Returns the indices of
## blocks that have no heart left.
## side_rate: the army's losses this exchange over its starting strength (what
## its morale is shaken by); a block is worn only by losses beyond that, so
## when everyone fights, every block keeps pace with the army, and in a big
## battle the blocks in the line wear out while the reserve rests.
static func wear(state:Dictionary,side:String,block_losses:Dictionary,side_rate:float,resolve:float,morale:float,hungry:bool,struck:Array=[])->Array:
	var blocks:Array=state.sides[side].blocks
	var live:Array=state.live[side]
	var protection:=0.78+clampf(resolve,0.0,1.0)*0.34
	var drain:=HUNGER_DRAIN if hungry else 1.0
	var breaking:Array=[]
	for b in blocks.size():
		var block:Dictionary=live[b]
		var st:=String(block.st)
		if st in ["broken","fled"]: continue
		var men0:=maxf(1.0,float(blocks[b].men0))
		var lost:=float(block_losses.get(b,0))
		var cond:=float(block.get("cond",1.0))
		var worn:=maxf(0.0,lost/men0-side_rate)*1.8/protection*drain
		if st=="front":
			block.fat=int(block.fat)+1
			cond-=worn
			if int(block.fat)>FRESH_EXCHANGES: cond-=0.02*drain
			if struck.has(b): cond-=0.06
		else:
			block.fat=maxi(0,int(block.fat)-2)
			cond=minf(1.0,cond-worn+REST)
		block.cond=clampf(cond,0.0,1.0)
		block.c=clampf(morale*float(block.cond),0.0,1.0)
		if int(block.men)<=0 or float(block.c)<=BREAK_AT: breaking.append(b)
	# The worst first.
	breaking.sort_custom(func(x:int,y:int)->bool: return float(live[x].c)<float(live[y].c))
	return breaking


## A block breaks and leaves the field. Its men are split within the bounded
## casualty rules: a few cut down and some hurt in the rout, some taken if
## the enemy can ride them down, most run. Returns {per_formation:[...],
## killed, wounded, fled, captured} and marks the block broken.
static func break_block(state:Dictionary,side:String,b:int,rng:RandomNumberGenerator,enemy_pursues:bool,exchange:int)->Dictionary:
	var blocks:Array=state.sides[side].blocks
	var live:Array=state.live[side]
	var block:Dictionary=live[b]
	var men:=int(block.men)
	var result:={"killed":0,"wounded":0,"fled":0,"captured":0,"per_formation":{}}
	var slot:=int(block.slot)
	var was_front:=String(block.st)=="front"
	block.st="broken"; block.slot=-1; block.broke_at=exchange
	if men<=0: return result
	var killed:=clampi(roundi(float(men)*rng.randf_range(0.03,0.08)*(1.5 if enemy_pursues else 1.0)),0,men)
	var wounded:=clampi(roundi(float(men)*rng.randf_range(0.06,0.12)),0,men-killed)
	var captured:=clampi(roundi(float(men)*(rng.randf_range(0.10,0.25) if enemy_pursues else rng.randf_range(0.0,0.04))),0,men-killed-wounded)
	var fled:=men-killed-wounded-captured
	result.killed=killed; result.wounded=wounded; result.fled=fled; result.captured=captured
	var members:Array=blocks[b].members
	for j in members.size():
		var f:=int(members[j][0])
		var n:=int((block.m as Array)[j])
		if n>0: result.per_formation[f]=int(result.per_formation.get(f,0))+n
		(block.m as Array)[j]=0
	block.men=0
	block.k=int(block.k)+killed; block.w=int(block.w)+wounded; block.f=int(block.f)+fled; block.cap=int(block.cap)+captured
	# The blocks beside it in the line waver.
	if was_front:
		for other in live:
			if String(other.st)=="front" and absi(int(other.slot)-slot)==1: other.c=maxf(0.0,float(other.c)-0.04)
	_event(state,{"k":"broke","side":side,"b":b,"arm":String(blocks[b].arm),"men":men,"cap":captured,"x":exchange,"slot":slot})
	return result


## Books losses by kind on the blocks that took them (for the plates and
## the phase totals), spreading a side's killed/wounded/fled/captured over the
## blocks in proportion to their losses.
static func book_kinds(state:Dictionary,side:String,block_losses:Dictionary,casualties:Dictionary)->void:
	var cur_losses:Dictionary=state.cur.losses[side]
	cur_losses.k=int(cur_losses.k)+int(casualties.get("killed",0))
	cur_losses.w=int(cur_losses.w)+int(casualties.get("wounded",0))
	cur_losses.f=int(cur_losses.f)+int(casualties.get("scattered",0))
	cur_losses.c=int(cur_losses.c)+int(casualties.get("captured",0))
	var total:=0
	for b in block_losses: total+=int(block_losses[b])
	if total<=0: return
	var live:Array=state.live[side]
	var keys:={"killed":"k","wounded":"w","scattered":"f"}
	for kind in keys:
		var amount:=int(casualties.get(kind,0))
		if amount<=0: continue
		var given:=0
		var blocks_hit:=block_losses.keys()
		for i in blocks_hit.size():
			var b:int=blocks_hit[i]
			var n:=roundi(float(amount)*float(block_losses[b])/float(total)) if i<blocks_hit.size()-1 else amount-given
			n=clampi(n,0,amount-given)
			live[b][keys[kind]]=int(live[b][keys[kind]])+n
			given+=n


# --- Progress -----------------------------------------------------------------------

## Who is winning, from -1 (the defender) to +1 (the attacker): the strength of
## each side's line times its heart, with the waiting reserve counting for
## part, plus the trend over recent exchanges. quality: per-formation fighting
## quality per man (sqrt(attack x defense)) for each side.
static func measure(state:Dictionary,quality:Dictionary,morale:Dictionary)->float:
	var strength:={}
	for side in ["attacker","defender"]:
		var blocks:Array=state.sides[side].blocks
		var live:Array=state.live[side]
		var q:PackedFloat32Array=quality.get(side,PackedFloat32Array())
		var total:=0.0
		for b in blocks.size():
			var block:Dictionary=live[b]
			var st:=String(block.st)
			if st not in ["front","reserve"]: continue
			var per_man:=0.0; var men:=0.0
			var members:Array=blocks[b].members
			for j in members.size():
				var f:=int(members[j][0]); var n:=float((block.m as Array)[j])
				per_man+=n*(float(q[f]) if f<q.size() else 1.0); men+=n
			if men<=0.0: continue
			var weight:=1.0 if st=="front" else 0.35
			total+=per_man*float(block.c)*weight
		strength[side]=total*maxf(0.05,float(morale.get(side,1.0)))
	var a:=float(strength.attacker); var d:=float(strength.defender)
	var raw:=(a-d)/maxf(0.0001,a+d)
	var previous:=float(state.get("progress_raw",raw))
	var trend:=float(state.get("trend",0.0))*0.6+(raw-previous)*0.4
	state.progress_raw=raw
	state.trend=trend
	state.progress=clampf(raw*0.85+clampf(trend*3.0,-1.0,1.0)*0.15,-1.0,1.0)
	return float(state.progress)


## Progress seen from one side (+1: that side is winning).
static func progress_for(state:Dictionary,side:String)->float:
	var p:=float(state.get("progress",0.0))
	return p if side=="attacker" else -p


# --- Phases ---------------------------------------------------------------------------

## Whether the exchange about to be counted closes its phase.
static func closing(state:Dictionary,ended:bool)->bool:
	return ended or int(state.exchange)+1-int(state.cur.from)+1>=int(state.phase_len)


## After each exchange: counts it, and closes the phase at its boundary or at
## the end. why: the signed modifiers of this exchange (see factors()).
static func after_exchange(state:Dictionary,plan:Dictionary,why:Array,ended:bool)->void:
	state.exchange=int(state.exchange)+1
	if not why.is_empty(): state.why=why
	var cur:Dictionary=state.cur
	var length:=int(state.exchange)-int(cur.from)+1
	if ended or length>=int(state.phase_len): close_phase(state,plan,why)


static func close_phase(state:Dictionary,plan:Dictionary,why:Array)->void:
	var cur:Dictionary=state.cur
	if int(state.exchange)<int(cur.from): return
	var tactics:={}
	var BattleTactics:=preload("res://scripts/battle_tactics.gd")
	for role in ["attacker","defender"]:
		var other:="defender" if role=="attacker" else "attacker"
		var id:=String((plan.get(role,{}) as Dictionary).get("id","")) if not plan.is_empty() else ""
		var enemy_id:=String((plan.get(other,{}) as Dictionary).get("id","")) if not plan.is_empty() else ""
		tactics[role]={"id":id,"countered":id!="" and BattleTactics.countered(id,enemy_id),"changed":(cur.changes as Dictionary).has(role)}
	var phase:={"i":(state.phases as Array).size()+1,"from":int(cur.from),"to":int(state.exchange),"tactics":tactics,
		"losses":(cur.losses as Dictionary).duplicate(true),"progress":float(state.progress),"trend":float(state.trend),
		"events":(cur.events as Array).slice(0,8),"why":why.duplicate(true),"snap":snapshot(state),
		"front":{"attacker":_front(state.live.attacker).size(),"defender":_front(state.live.defender).size()},"capacity":int(state.capacity)}
	(state.phases as Array).append(phase)
	state.cur=_new_phase(int(state.exchange)+1)


## A compact picture of every block: [men, cohesion in hundredths, state code, slot].
const STATE_CODE:={"front":0,"reserve":1,"broken":2,"fled":3}
const CODE_STATE:=["front","reserve","broken","fled"]

static func snapshot(state:Dictionary)->Dictionary:
	var out:={}
	for side in ["attacker","defender"]:
		var rows:Array=[]
		for block in state.live[side]:
			rows.append([int(block.men),roundi(float(block.c)*100.0),int(STATE_CODE.get(String(block.st),1)),int(block.slot)])
		out[side]=rows
	return out


## At the end: the beaten side's standing blocks leave the field with it.
static func finish(state:Dictionary,outcome:String,termination:Dictionary)->void:
	var beaten:=String({"attacker_victory":"defender","defender_retreat":"defender","defender_victory":"attacker","attacker_retreat":"attacker","mutual_collapse":"both"}.get(outcome,""))
	if bool(state.get("finished",false)): return
	state.finished=true
	state.outcome=outcome
	for side in ["attacker","defender"]:
		if beaten!=side and beaten!="both": continue
		for block in state.live[side]:
			if String(block.st) in ["front","reserve"]: block.st="fled"; block.slot=-1
	if beaten in ["attacker","defender"]:
		state.progress=1.0 if beaten=="defender" else -1.0
	elif beaten=="both": state.progress=0.0
	# The last phase shows the field as it was left.
	var phases:Array=state.get("phases",[])
	if not phases.is_empty() and int((phases[-1] as Dictionary).get("to",0))>=int(state.get("exchange",0)):
		phases[-1]["snap"]=snapshot(state)
		phases[-1]["progress"]=float(state.progress)
	var fate:=String(termination.get("commander_fate",""))
	if fate in ["captured","killed","wounded, but escaped"] and beaten in ["attacker","defender"]:
		_event(state,{"k":"chief","side":beaten,"fate":fate,"name":String(termination.get("commander",""))})
	if int(termination.get("prisoners",0))>0 and beaten in ["attacker","defender"]:
		_event(state,{"k":"taken","side":beaten,"n":int(termination.prisoners),"type":String(termination.get("type",""))})


## Something that really changed in the fight, for the phase's events.
static func note_event(state:Dictionary,event:Dictionary)->void:
	_event(state,event)


static func _event(state:Dictionary,event:Dictionary)->void:
	event["x"]=int(event.get("x",int(state.get("exchange",0))+1))
	var cur:Dictionary=state.get("cur",{})
	if not cur.is_empty(): (cur.events as Array).append(event)
	var all:Array=state.events
	all.append(event)
	while all.size()>60: all.pop_front()


## A tactic change or a counter, as an event for the phase.
static func note_tactics(state:Dictionary,changes:Dictionary,plan:Dictionary)->void:
	var cur:Dictionary=state.cur
	for role in changes:
		(cur.changes as Dictionary)[role]=changes[role]
		_event(state,{"k":"tactic","side":String(role),"from":String(changes[role].get("from","")),"to":String(changes[role].get("to","")),"why":String(changes[role].get("why",""))})
	var BattleTactics:=preload("res://scripts/battle_tactics.gd")
	for role in ["attacker","defender"]:
		var other:="defender" if role=="attacker" else "attacker"
		var id:=String((plan.get(role,{}) as Dictionary).get("id",""))
		var enemy_id:=String((plan.get(other,{}) as Dictionary).get("id",""))
		if id!="" and BattleTactics.countered(id,enemy_id) and (changes.has(other) or int(state.exchange)==0):
			_event(state,{"k":"countered","side":role,"id":id,"by":enemy_id})


# --- Why ------------------------------------------------------------------------------

## The signed modifiers actually used this exchange, attacker's view (a
## positive value favours the attacker). Each: {k, v (natural log of the
## attacker/defender ratio), a, d (the plain quantities on each side)}.
## f: {attacker:{...}, defender:{...}} per side: men (standing), front (men
## in the line), quality, terrain, readiness, cohesion, command, fatigue,
## hunger, river; exposure: {attacker, defender} from tactics; surprise.
static func factors(f:Dictionary,exposure:Dictionary,tactic_ids:Dictionary,surprise:String)->Array:
	var a:Dictionary=f.attacker; var d:Dictionary=f.defender
	var out:Array=[]
	var ratio:=func(x:float,y:float)->float: return log(maxf(0.0001,x)/maxf(0.0001,y))
	out.append({"k":"numbers","v":ratio.call(float(a.men),float(d.men)),"a":int(a.men),"d":int(d.men)})
	var frontage:=float(ratio.call(float(a.front),float(d.front)))-float(ratio.call(float(a.men),float(d.men)))
	if absf(frontage)>0.01: out.append({"k":"frontage","v":frontage,"a":int(a.front),"d":int(d.front)})
	out.append({"k":"weapons","v":ratio.call(float(a.quality),float(d.quality)),"a":float(a.quality),"d":float(d.quality)})
	if absf(float(a.terrain)-float(d.terrain))>0.001: out.append({"k":"ground","v":ratio.call(sqrt(float(a.terrain)),sqrt(float(d.terrain))),"a":float(a.terrain),"d":float(d.terrain)})
	if float(a.river)<1.0: out.append({"k":"river","v":log(float(a.river)),"a":float(a.river),"d":1.0})
	out.append({"k":"cohesion","v":ratio.call(float(a.cohesion),float(d.cohesion)),"a":float(a.cohesion),"d":float(d.cohesion)})
	out.append({"k":"supply","v":ratio.call(float(a.readiness),float(d.readiness)),"a":float(a.readiness),"d":float(d.readiness)})
	if float(a.hunger)<1.0 or float(d.hunger)<1.0: out.append({"k":"hunger","v":ratio.call(float(a.hunger),float(d.hunger)),"a":float(a.hunger),"d":float(d.hunger)})
	if absf(float(a.fatigue)-float(d.fatigue))>0.001: out.append({"k":"fatigue","v":ratio.call(float(a.fatigue),float(d.fatigue)),"a":float(a.fatigue),"d":float(d.fatigue)})
	out.append({"k":"general","v":ratio.call(float(a.command),float(d.command)),"a":float(a.command),"d":float(d.command)})
	var tactic:=float(ratio.call(float(exposure.get("defender",1.0)),float(exposure.get("attacker",1.0))))
	if absf(tactic)>0.005:
		var entry:={"k":"surprise" if surprise!="" else "tactics","v":tactic,"a":String(tactic_ids.get("attacker","")),"d":String(tactic_ids.get("defender","")),"by":surprise}
		out.append(entry)
	var kept:Array=[]
	for item in out:
		if absf(float(item.v))>=0.03 or String(item.k)=="numbers": kept.append(item)
	kept.sort_custom(func(x:Dictionary,y:Dictionary)->bool: return absf(float(x.v))>absf(float(y.v)))
	return kept

extends RefCounted
## FEUDS BETWEEN OTHER PEOPLES, FOUGHT FOR REAL. war_loop._rival_wars starts
## feuds between two small neighbours at the benchmark rate. In a world where
## every people is simulated (WorldSimulation.enabled) the old monthly pass that
## fought them no longer runs, so a feud was only a note on the pair relation:
## no raid, no dead, no stolen food. Here each is fought with the same bands and
## the same combat simulator as raids on the god's people (war_loop._band,
## _clash), and the dead and the stolen food come out of the two peoples' own
## ledgers. Each remembers it: the raided people's opinion of its raiders falls
## and its border tightens, in its own view of the world.
##
## Bookkeeping stays where CivilizationSystem keeps it, on the pair relation:
## feud_since, feud_last (the last blood), feud_raids, feud_dead {civ_id: n},
## feud_cause. A feud raids less as it ages (RIVAL_FEUD_AGE_DAYS), a people
## that has buried a twenty-fifth of itself in it stays home, and it goes cold
## after RIVAL_FEUD_COLD_DAYS without blood. Between feuds, grudges fade.

const War:=preload("res://scripts/war_loop.gd")
const CIV:=preload("res://scripts/civilization_system.gd")
const EXCHANGE:=preload("res://scripts/civilization_exchange.gd")

## A feud's ending between two other peoples, by the rule the god's own
## feuds follow (world_answer.gd): a people worn out by the feud (it has
## buried SPENT_SHARE of itself) and outmatched (the other's fighting
## strength BOW_RATIO times its own) may bow, at BOW_MONTHLY a month less its
## ruler's boldness. It pays tribute through the one trade ledger
## (trade_stances, the same agreement every people's tribute is) and the
## feud ends; while it pays, no new feud starts between them (BOWED_DAYS).
const BOW_RATIO:=1.5
const BOW_MONTHLY:=0.05
const BOWED_DAYS:=5*365

## Monthly share by which a pair's opinion and border tension drift back
## toward calm while they are not feuding.
const CALM_MONTHLY:=0.04
## Share of a people's feud dead after which it stops sending raiders.
const SPENT_SHARE:=0.04

## Called from war_loop.daily every `days` days, in the god's scope.
static func tick(day:int,days:int)->void:
	if not WorldSimulation.enabled: return
	var world=WorldSimulation.world
	if world==null: return
	var civs:Array=world.civilizations
	for i in civs.size():
		for j in range(i+1,civs.size()):
			var first:Dictionary=civs[i]
			var second:Dictionary=civs[j]
			if not bool(first.get("alive",true)) or not bool(second.get("alive",true)): continue
			if bool(first.get("general_campaign_owned",false)) or bool(second.get("general_campaign_owned",false)): continue
			if not _simulated(String(first.id)) or not _simulated(String(second.id)): continue
			var relation:Dictionary=((first.relations as Dictionary).get(String(second.id),{}) as Dictionary).duplicate(true)
			if relation.is_empty(): continue
			var before:=relation.hash()
			# A declaration between two simulated peoples is theirs to make
			# (their own leaders' diplomacy); an old undelivered note is dropped.
			if String(relation.get("pending_message",""))=="war": relation["pending_message"]=""
			# A people down to a handful (war_loop.BROKEN_PEOPLE) keeps no feud:
			# nobody is left to send raiders, and nobody needs raiding.
			var spent:=minf(float(first.get("population",0.0)),float(second.get("population",0.0)))<War.BROKEN_PEOPLE
			if int(relation.get("feud_since",-1))>=0 and spent:
				for key in ["feud_since","feud_last","feud_raids","feud_dead","feud_cause"]: relation.erase(key)
				relation["feud_ended_day"]=day
			elif int(relation.get("feud_since",-1))>=0:
				_feud(first,second,relation,day,days)
				if day%30<days and int(relation.get("feud_since",-1))>=0: _bow(first,second,relation,day)
			elif day%30<days: _calm(relation)
			if relation.hash()!=before: world._set_pair_relation(i,j,relation)

static func _simulated(civ_id:String)->bool:
	return WorldSimulation.actors.has(civ_id)

## Has one of this pair bowed to the other lately? {payer, payee, day} or {}.
static func bowed(relation:Dictionary,day:int)->Dictionary:
	var b:Variant=relation.get("bowed",{})
	if not b is Dictionary or (b as Dictionary).is_empty() or day-int((b as Dictionary).get("day",-99999))>=BOWED_DAYS: return {}
	return b

static func _bow(first:Dictionary,second:Dictionary,relation:Dictionary,day:int)->void:
	var dead:Dictionary=relation.get("feud_dead",{}) if relation.get("feud_dead") is Dictionary else {}
	var Standing:=preload("res://scripts/standing.gd")
	for pair in [[first,second],[second,first]]:
		var weak:Dictionary=pair[0]; var strong:Dictionary=pair[1]
		var spent:=float(dead.get(String(weak.id),0))>=float(weak.get("population",100.0))*SPENT_SHARE
		var ratio:=Standing.their_fighting_strength(strong)/maxf(1.0,Standing.their_fighting_strength(weak))
		if not spent or ratio<BOW_RATIO: continue
		var chance:=BOW_MONTHLY*clampf(1.3-float(weak.get("aggression",0.5)),0.2,1.0)
		if War._rng("rival_bow:%s:%s:%d" % [String(weak.id),String(strong.id),day]).randf()>=chance: continue
		var Stances:=preload("res://scripts/trade_stances.gd")
		Stances._begin_tribute(String(weak.id),String(strong.id),maxf(1.0,Stances.tribute_size(String(weak.id))),day)
		for key in ["feud_since","feud_last","feud_raids","feud_dead","feud_cause"]: relation.erase(key)
		relation["feud_ended_day"]=day
		relation["bowed"]={"payer":String(weak.id),"payee":String(strong.id),"day":day}
		relation["border_tension"]=minf(float(relation.get("border_tension",0.5)),0.35)
		# Word reaches us of it if we know them both.
		var known:=func(c:Dictionary)->bool: return int((c.get("player_relation",{}) as Dictionary).get("contact_level",0))>=1
		if known.call(weak) and known.call(strong):
			preload("res://scripts/chronicle.gd").record({"key":"rival_bow:%s:%s:%d" % [String(weak.id),String(strong.id),day],"title":"%s Bow to %s" % [String(weak.get("name","")),String(strong.get("name",""))],
				"text":"Word comes that %s, worn out by its feud, has bowed to %s and pays it tribute." % [String(weak.get("name","")),String(strong.get("name",""))],"tier":"notice","kind":"contact","domain":"diplomacy"})
		return

## Grudges fade between feuds; a pact or a truce is left as it stands.
static func _calm(relation:Dictionary)->void:
	var opinion:=float(relation.get("opinion",0.0))
	if opinion<0.0: relation["opinion"]=minf(0.0,opinion+maxf(0.005,-opinion*CALM_MONTHLY))
	var tension:=float(relation.get("border_tension",0.0))
	if tension>0.35: relation["border_tension"]=maxf(0.35,tension-maxf(0.005,(tension-0.35)*CALM_MONTHLY))

static func _feud(first:Dictionary,second:Dictionary,relation:Dictionary,day:int,days:int)->void:
	if day-int(relation.get("feud_last",-99999))>=CIV.RIVAL_FEUD_COLD_DAYS:
		for key in ["feud_since","feud_last","feud_raids","feud_dead","feud_cause"]: relation.erase(key)
		relation["feud_ended_day"]=day
		return
	var rng:=War._rng("rival_feud:%s:%s:%d" % [String(first.id),String(second.id),day])
	var heat:=exp(-float(maxi(0,day-int(relation.get("feud_since",day))))/CIV.RIVAL_FEUD_AGE_DAYS)
	var chance:=1.0-pow(1.0-CIV.RIVAL_FEUD_RAID_DAILY*heat,float(days))
	if rng.randf()>=chance: return
	var first_attacks:=rng.randf()<clampf(0.5+(float(first.get("aggression",0.4))-float(second.get("aggression",0.4)))*0.5,0.2,0.8)
	var attacker:Dictionary=first if first_attacks else second
	var defender:Dictionary=second if first_attacks else first
	var dead:Dictionary=relation.get("feud_dead",{}) if relation.get("feud_dead") is Dictionary else {}
	if float(dead.get(String(attacker.id),0))>=float(attacker.get("population",100.0))*SPENT_SHARE: return
	var result:=raid(attacker,defender,day)
	dead[String(defender.id)]=int(dead.get(String(defender.id),0))+int(result.defender_dead)
	dead[String(attacker.id)]=int(dead.get(String(attacker.id),0))+int(result.attacker_dead)
	relation["feud_dead"]=dead
	relation["feud_raids"]=int(relation.get("feud_raids",0))+1
	if int(result.defender_dead)+int(result.attacker_dead)>0: relation["feud_last"]=day
	relation["border_tension"]=clampf(float(relation.get("border_tension",0.5))+0.02,0.0,1.0)
	relation["opinion"]=clampf(float(relation.get("opinion",-0.3))-0.02,-1.0,1.0)

## One raid between two simulated peoples: {won, attacker_dead, defender_dead,
## taken}. The same bands and simulator as a raid on the god's people.
static func raid(attacker:Dictionary,defender:Dictionary,day:int)->Dictionary:
	var a_id:=String(attacker.id)
	var d_id:=String(defender.id)
	var key:="rival_raid:%s:%s:%d" % [a_id,d_id,day]
	var rng:=War._rng(key)
	var a_pop:=maxf(10.0,float(attacker.get("population",100.0)))
	var d_pop:=maxf(10.0,float(defender.get("population",100.0)))
	var a_n:=War._band_size(a_pop,rng.randf_range(0.03,0.05))
	var d_n:=War._band_size(d_pop,rng.randf_range(0.02,0.035))
	var band_a:=War._band("%s raiders" % String(attacker.get("name",a_id)),a_n,float(attacker.get("knowledge",0.15)),float(attacker.get("military_readiness",0.5)),"their war leader",0.5)
	var band_d:=War._band(String(defender.get("name",d_id)),d_n,float(defender.get("knowledge",0.15)),float(defender.get("military_readiness",0.5)),"their war leader",0.45)
	var fight:=War._clash(band_a,band_d,1.0,key)
	var won:=bool(fight.won)
	var d_dead:=War._cap_dead(int(fight.def_dead),d_pop)
	var a_dead:=War._cap_dead(int(fight.att_dead),a_pop)
	if not won: a_dead=mini(a_dead,1)
	var taken:=0.0
	if won:
		var stock:=float(WorldSimulation.scoped(d_id,func()->float: return _food_held()))
		var loot:=minf(stock*rng.randf_range(0.05,0.12),float(a_n)*War.CARRY)
		if loot>=1.0:
			taken=EXCHANGE.take(d_id,"Food",loot)
			if taken>0.0: EXCHANGE.receive(a_id,"Food",taken)
	d_dead=_bury(d_id,d_dead)
	a_dead=_bury(a_id,a_dead)
	# Each remembers: the raided most of all.
	_remember(d_id,a_id,0.05,0.10)
	_remember(a_id,d_id,0.02,0.05)
	return {"won":won,"attacker_dead":a_dead,"defender_dead":d_dead,"taken":taken}

static func _food_held()->float:
	var total:=0.0
	for pool in WorldSimulation.state.food_stocks: total+=maxf(0.0,float(WorldSimulation.state.food_stocks[pool]))
	return total

static func _bury(civ_id:String,count:int)->int:
	if count<=0: return 0
	return int(WorldSimulation.scoped(civ_id,func()->int:
		return int((WorldSimulation.state.register_population_deaths(count,"Killed in battle") as Dictionary).get("count",0))))

## In `viewer`'s own view of the world, its opinion of `other` falls and the
## border between them tightens.
static func _remember(viewer:String,other:String,opinion_drop:float,tension_rise:float)->void:
	WorldSimulation.scoped(viewer,func()->void:
		for civ in WorldSimulation.world.civilizations:
			if String(civ.get("id",""))!=other: continue
			var relation:Dictionary=civ.get("player_relation",{})
			relation["opinion"]=clampf(float(relation.get("opinion",0.0))-opinion_drop,-1.0,1.0)
			relation["border_tension"]=clampf(float(relation.get("border_tension",0.0))+tension_rise,0.0,1.0)
			civ["player_relation"]=relation
			return)

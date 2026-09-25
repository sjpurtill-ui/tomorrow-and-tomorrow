extends RefCounted
## WAR IN THE LIVING WORLD: refusals that bite, raids, and general-led war.
##
## - Follow-through. A tribute demand that was not a bluff, refused or answered
##   with threats, is followed through by the ruler's trait and the real
##   strength of both peoples: most such rulers come within two years. The
##   ladder runs raid (outlying fields, herds, the gathering grounds, a hunting
##   or scouting party) -> border skirmish -> war. Called bluffs still collapse
##   (rival_rulers.bluff_called); this module never touches them.
## - Grudges feed it. A ruler's grudge weight (rival_rulers.rival_character)
##   raises the chance and the rung, and a heavy old grudge can send raiders
##   without a new demand.
## - War in the player's own world. Nothing restarts the world. The war leader
##   (the Marshal office; the Hearth Chief when there is none) carries a court
##   matter. The god summons them and gives an objective in conversation
##   (offline: a choice list; online: typed words, see typed_choice): hold the
##   approaches, go after the raiders, burn their stores, bring me their chief,
##   send for a truce, pay, or "do as you judge". The general runs the
##   operation; the combat simulator (MilitaryCampaign.simulator) resolves each
##   clash. Results come back as Chronicle moments and a report matter:
##   casualties from the real population on both sides, captives, loot, grudges.
##   A general left without word acts on their own judgment.
## - Scale. Bands are capped at the pre-modern mobilisation benchmark
##   (EPOCHAL_SHIFTS.md s3.4: 3-7% of the population), so a stone-age raid is a
##   handful of hunters and a war is a few small war bands.
## - Endings. Wars end in a truce (a messenger, or both sides worn out),
##   tribute (paid by the side that is losing; a captured chief is ransomed) or
##   exhaustion (the war is simply dropped after years of it).
## - Rival wars drag the player in. Standing with kin (a marriage or alliance)
##   in their war sends your fighters to it: war with their enemy. Standing
##   with a people you are not bound to only earns their enemy's raiders.
##
## State lives in ForeignDiplomacy.audiences["war"] (saved with the audience
## hall; older saves start with an empty ledger). Static helpers; preload.

const Hall:=preload("res://scripts/audience_hall.gd")
const EXCHANGE:=preload("res://scripts/civilization_exchange.gd")
const EraNames:=preload("res://scripts/era_names.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")
const RIVALS_PATH:="res://scripts/rival_rulers.gd"

const VERSION:=1
const TICK:=5
## Pre-modern mobilisation cap (EPOCHAL_SHIFTS.md s3.4): 3-7% of the people.
const MOBILIZE_MIN:=0.03
const MOBILIZE_MAX:=0.07
## No single clash kills more than this share of a people.
const CLASH_DEATH_CAP:=0.025
const LOG_MAX:=120
const REFUSALS_MAX:=80
const TRUCE_DAYS:=3*365
const WAR_COOLDOWN:=6*365
const GENERAL_WAIT:=30
const GUARD_DAYS:=180
## What one fighter carries home, in Food.
const CARRY:=14.0
const TERMS_WAIT:=60
const LEVEL_DECAY_DAYS:=4*365

## How often a ruler with a real grievance comes, by signature trait.
const FOLLOW:={"grudge":0.9,"hunter":0.8,"ledger":0.72,"bluffer":0.7,"magpie":0.62,"matchmaker":0.5}
const OBJECTIVES:=["war_guard","war_pursue","war_burn","war_chief","war_parley","war_pay","war_general","war_let","war_rest"]
const TARGETS:={
	"fields":{"words":"the planted fields","who":"field hands","lethal":true},
	"herds":{"words":"the herds","who":"herders","lethal":true},
	"gathering":{"words":"the gathering grounds","who":"gatherers","lethal":true},
	"racks":{"words":"the drying racks","who":"the old ones minding the racks","lethal":true},
	"hunters":{"words":"a hunting party","who":"hunters","lethal":true},
	"scouts":{"words":"our scouting party","who":"scouts","lethal":false},
}

# --------------------------------------------------------------------------
# State
# --------------------------------------------------------------------------

static func _day()->int:
	return int(GameState.elapsed_days)

static func _rivals()->GDScript:
	return load(RIVALS_PATH) as GDScript

static func _rng(key:String)->RandomNumberGenerator:
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d:war:%s" % [int(GameState.world_seed),key])
	return rng

static func state()->Dictionary:
	ForeignDiplomacy.ensure()
	var holder:Dictionary=ForeignDiplomacy.audiences
	var s:Variant=holder.get("war")
	if not s is Dictionary or int((s as Dictionary).get("version",0))!=VERSION or int((s as Dictionary).get("world_seed",GameState.world_seed))!=int(GameState.world_seed):
		s={"version":VERSION,"world_seed":int(GameState.world_seed),"fronts":{},"refusals":[],"log":[],"stats":{},"serial":0}
		holder["war"]=s
	var d:Dictionary=s
	for key in ["fronts","stats"]:
		if not d.get(key) is Dictionary: d[key]={}
	for key in ["refusals","log"]:
		if not d.get(key) is Array: d[key]=[]
	return d

static func valid_state(data:Variant)->bool:
	if not data is Dictionary: return false
	var d:Dictionary=data
	if d.is_empty(): return true
	if not d.get("fronts",{}) is Dictionary or (d.get("fronts",{}) as Dictionary).size()>64: return false
	for key in ["refusals","log"]:
		if not d.get(key,[]) is Array: return false
	if (d.get("refusals",[]) as Array).size()>REFUSALS_MAX or (d.get("log",[]) as Array).size()>LOG_MAX: return false
	if not d.get("stats",{}) is Dictionary: return false
	return JSON.stringify(d).length()<=200000

static func _stat(key:String,amount:int=1)->void:
	var stats:Dictionary=state().stats
	stats[key]=int(stats.get(key,0))+amount

static func front(civ_id:String)->Dictionary:
	var fronts:Dictionary=state().fronts
	if not fronts.get(civ_id) is Dictionary:
		fronts[civ_id]={"level":0,"last_harm":-99999,"pending":{},"war":{},"guard_until":-1,"taken":0.0,"last_war_end":-99999,"matter_day":-1}
	return fronts[civ_id]

static func _log(civ_id:String,kind:String,text:String,extra:Dictionary={})->void:
	var entry:={"day":_day(),"civ":civ_id,"kind":kind,"text":text.substr(0,300)}
	entry.merge(extra,true)
	var list:Array=state().log
	list.push_front(entry)
	while list.size()>LOG_MAX: list.pop_back()

static func summary()->Dictionary:
	## Plain numbers for tests, probes and the playtest harness.
	var s:=state()
	var real:=0; var followed:=0; var within:=0
	for r in s.refusals:
		if not r is Dictionary: continue
		real+=1
		if bool(r.get("follow",false)): followed+=1
		if int(r.get("harm_day",-1))>=0 and int(r.harm_day)-int(r.day)<=730: within+=1
	var at_war:Array=[]
	for civ_id in s.fronts:
		if not ((s.fronts[civ_id] as Dictionary).get("war",{}) as Dictionary).is_empty(): at_war.append(String(civ_id))
	return {"stats":(s.stats as Dictionary).duplicate(),"real_refusals":real,"followed":followed,"harmed_within_2y":within,"at_war":at_war}

# --------------------------------------------------------------------------
# Peoples, strength and bands
# --------------------------------------------------------------------------

static func _civ(civ_id:String)->Dictionary:
	var index:=Hall._civ_index(civ_id)
	return WorldSimulation.world.civilizations[index] if index>=0 else {}

static func _relation(civ_id:String)->Dictionary:
	var civ:=_civ(civ_id)
	return civ.get("player_relation",{}) if not civ.is_empty() else {}

static func _name(civ_id:String)->String:
	return Hall._civ_name(civ_id)

static func _the(name:String)->String:
	return name if name.begins_with("The ") or name.begins_with("the ") else name

static func _their_pop(civ_id:String)->float:
	return maxf(10.0,float(_civ(civ_id).get("population",100.0)))

static func _our_pop()->float:
	return Hall._player_population()

static func _band_size(pop:float,share:float)->int:
	return maxi(3,roundi(pop*clampf(share,MOBILIZE_MIN,MOBILIZE_MAX)))

static func ratio(civ_id:String)->float:
	## Their fighting strength over ours: people and readiness, not a guess.
	var civ:=_civ(civ_id)
	var readiness:=clampf(float(civ.get("military_readiness",0.45)),0.2,1.0)
	return clampf(_their_pop(civ_id)*(0.7+readiness*0.5)/maxf(1.0,_our_pop()*0.95),0.2,5.0)

static func _rival(civ_id:String)->Dictionary:
	var r:GDScript=_rivals()
	return r.call("rival_character",civ_id) if r!=null else {}

static func _our_tech()->float:
	var inventory:Dictionary=WorldSimulation.military.military_inventory
	if int(inventory.get("bow",0))>0: return 0.55
	if int(inventory.get("spear",0))>0: return 0.3
	return 0.15

static func _band(label:String,count:int,tech:float,readiness:float,leader:String,skill:float)->Dictionary:
	var formations:Array[Dictionary]=[]
	if tech>=0.52:
		var archers:=roundi(count*0.28); var line:=roundi(count*0.38)
		formations=[{"unit":"levy","weapon":"improvised","count":count-archers-line},{"unit":"line_infantry","weapon":"spear","count":line},{"unit":"skirmisher","weapon":"bow","count":archers,"ammunition":archers*6}]
	elif tech>=0.27:
		var spears:=roundi(count*0.42)
		formations=[{"unit":"levy","weapon":"improvised","count":count-spears},{"unit":"line_infantry","weapon":"spear","count":spears}]
	else:
		formations=[{"unit":"levy","weapon":"improvised","count":count}]
	var force:Dictionary=WorldSimulation.military.simulator.create_formation_force(label,formations,clampf(0.5+readiness*0.35,0.3,0.95),clampf(readiness,0.1,1.0))
	force["commander"]=WorldSimulation.military.simulator.create_commander(leader,skill,skill,0.5,clampf(skill+0.1,0.0,1.0))
	return force

static func _clash(attacker:Dictionary,defender:Dictionary,terrain:float,key:String)->Dictionary:
	## One fight, resolved by the shared combat simulator. Deaths are the share
	## of casualties who do not come home; the rest are wounded or scattered.
	var result:Dictionary=WorldSimulation.military.simulator.simulate(attacker,defender,{"seed":hash(key),"terrain_defense":terrain,"max_rounds":6,"casualty_intensity":0.8})
	var a:Dictionary=result.get("attacker",{}); var d:Dictionary=result.get("defender",{})
	var outcome:=String(result.get("outcome","inconclusive"))
	var rng:=_rng("clash:"+key)
	return {"outcome":outcome,"won":outcome=="attacker_victory" or (outcome=="inconclusive" and rng.randf()<0.4),
		"att_dead":roundi(float(a.get("casualties",0))*rng.randf_range(0.3,0.5)),"def_dead":roundi(float(d.get("casualties",0))*rng.randf_range(0.3,0.5))}

static func _cap_dead(n:int,pop:float)->int:
	return clampi(n,0,maxi(1,ceili(pop*CLASH_DEATH_CAP)))

static func _general()->Dictionary:
	return Hall._relevant_official(["Marshal"])

static func _general_skill(general:Dictionary)->float:
	var skills:Dictionary=general.get("skills",{}) if general.get("skills") is Dictionary else {}
	return clampf(float(skills.get("Defense",40.0))/100.0*0.6+float(general.get("courage",0.5))*0.25+0.1,0.2,0.9)

# --------------------------------------------------------------------------
# Losses on both sides, from the real population
# --------------------------------------------------------------------------

static func _our_deaths(count:int)->int:
	if count<=0: return 0
	return int(GameState.register_population_deaths(count,"Killed in battle").get("count",0))

static func _our_captives_lost(count:int,civ_id:String)->int:
	if count<=0: return 0
	return int(GameState.register_population_departures(count,"Taken captive by %s" % _name(civ_id),{"children":1.2,"youth":1.4,"early_adults":1.0,"established_adults":0.6,"mature_adults":0.3,"elders":0.1}).get("count",0))

static func _their_deaths(civ_id:String,count:int)->int:
	if count<=0: return 0
	if WorldSimulation.actors.has(civ_id):
		return int(WorldSimulation.scoped(civ_id,func()->int:return int(WorldSimulation.state.register_population_deaths(count,"Killed in battle").get("count",0))))
	var index:=Hall._civ_index(civ_id)
	if index<0: return 0
	var world:=WorldSimulation.world
	var civ:Dictionary=world.civilizations[index]
	var before:=float(civ.get("population",0.0))
	var dead:=minf(float(count),maxf(0.0,before-1.0))
	if dead<=0.0: return 0
	civ["population"]=before-dead
	civ["military_population"]=maxf(0.0,float(civ.get("military_population",0.0))-dead*0.7)
	if civ.get("cohorts") is Dictionary and world.has_method("_remove_weighted_cohort_population"):
		civ["cohorts"]=world._scaled_cohorts(world._remove_weighted_cohort_population(civ.cohorts,dead,{"children":0.08,"youth":1.3,"early_adults":1.85,"established_adults":1.7,"mature_adults":1.05,"elders":0.18}),float(civ.population))
	if world.has_method("_scale_strategic_region_populations"): civ=world._scale_strategic_region_populations(civ,float(civ.population)/maxf(1.0,before))
	world.civilizations[index]=civ
	return roundi(dead)

static func _their_captives(civ_id:String,count:int)->int:
	## Captives brought home join the people's hearths.
	if count<=0: return 0
	var taken:=0
	if WorldSimulation.actors.has(civ_id):
		taken=int(WorldSimulation.scoped(civ_id,func()->int:return int(WorldSimulation.state.register_population_departures(count,"Taken captive").get("count",0))))
	else:
		taken=_their_deaths(civ_id,count)
	if taken>0: GameState.register_population_arrivals(taken,"Captives from %s" % _name(civ_id))
	return taken

static func _names(count:int,key:String,women_share:float)->Array[String]:
	## The named dead: the people are counted in aggregate, but the Chronicle
	## gives the first few their names.
	var used:Dictionary={}
	var out:Array[String]=[]
	for i in mini(count,3):
		var serial:=posmod(hash("%s:%d" % [key,i]),800000)+100000
		var woman:=_rng("%s:%d:w" % [key,i]).randf()<women_share
		var identity:Dictionary=EraNames.make(int(GameState.world_seed),serial,woman,"player",used)
		var given:=String(identity.get("given",String(identity.get("name","")).get_slice(" ",0)))
		if given=="" or used.has("given:"+given): continue
		used["given:"+given]=true
		out.append(given)
	return out

static func _dead_words(count:int,names:Array[String],who:String)->String:
	if count<=0: return "No one of ours was killed."
	var listed:=", ".join(PackedStringArray(names)) if names.size()<=2 else "%s and %s" % [", ".join(PackedStringArray(names.slice(0,names.size()-1))),names[-1]]
	if names.size()==2: listed="%s and %s" % [names[0],names[1]]
	if count>names.size() and not names.is_empty(): return "%s and %d more of the %s were killed." % [listed,count-names.size(),who]
	if names.is_empty(): return "%d of the %s were killed." % [count,who]
	return "%s %s killed." % [listed,"was" if count==1 else "were"]

static func _record_battle(civ_id:String,name:String,our_dead:int,their_dead:int,taken:int,result:String)->void:
	var war:Dictionary=front(civ_id).get("war",{})
	var war_id:=String(war.get("war_id",""))
	if war_id=="" or not WorldSimulation.world.has_method("_record_war_battle"): return
	WorldSimulation.world._record_war_battle(war_id,{"day":_day(),"name":name,"location":"frontier","outcome":result,
		"losses":{"player":{"military_dead":our_dead,"civilian_dead":0,"wounded":our_dead,"captured":0,"displaced":0},civ_id:{"military_dead":their_dead,"civilian_dead":0,"wounded":their_dead,"captured":taken,"displaced":0}}})

static func _exhaust(civ_id:String,our_dead:int,their_dead:int)->void:
	var war:Dictionary=front(civ_id).get("war",{})
	if war.is_empty(): return
	war["our_dead"]=int(war.get("our_dead",0))+our_dead
	war["their_dead"]=int(war.get("their_dead",0))+their_dead
	war["our_exh"]=clampf(float(war.get("our_exh",0.0))+0.04+float(our_dead)/_our_pop()*6.0,0.0,1.0)
	war["their_exh"]=clampf(float(war.get("their_exh",0.0))+0.04+float(their_dead)/_their_pop(civ_id)*6.0,0.0,1.0)
	var index:=Hall._civ_index(civ_id)
	if index>=0:
		var relation:Dictionary=WorldSimulation.world.civilizations[index].player_relation
		relation["player_war_exhaustion"]=maxf(float(relation.get("player_war_exhaustion",0.0)),float(war.our_exh))
		relation["rival_war_exhaustion"]=maxf(float(relation.get("rival_war_exhaustion",0.0)),float(war.their_exh))

static func _chronicle(key:String,title:String,text:String,tier:String,civ_id:String)->void:
	Chronicle.record({"key":"war:"+key,"title":title.substr(0,70),"text":text,"tier":tier,"kind":"war","domain":"security",
		"action":{"kind":"court","focus":{"civ_id":civ_id}}})

static func _pick_target(civ_id:String,rng:RandomNumberGenerator)->String:
	var known:Array=GameState.known_discoveries
	var weights:={"gathering":1.0,"racks":0.8,"hunters":0.9}
	if "tillage" in known or "seed_selection" in known: weights["fields"]=1.4
	if "animal_taming" in known: weights["herds"]=1.2
	if not (WorldSimulation.world.scout_missions as Array).is_empty(): weights["scouts"]=0.35
	var total:=0.0
	for k in weights: total+=float(weights[k])
	var roll:=rng.randf()*total
	for k in weights:
		roll-=float(weights[k])
		if roll<=0.0: return String(k)
	return "gathering"

# --------------------------------------------------------------------------
# Refusals and follow-through
# --------------------------------------------------------------------------

static func after_answer(audience:Dictionary,option_id:String)->void:
	## Called by rival_rulers.after_answer for every foreign answer.
	if String(audience.get("origin",""))!="foreign" or WorldSimulation.actor_id!="player": return
	var civ_id:=String(audience.get("civ_id",""))
	if civ_id=="": return
	var kind:=String(audience.get("kind",""))
	var situation:Dictionary=audience.get("situation",{}) if audience.get("situation") is Dictionary else {}
	var type:=String(situation.get("type",""))
	var bluff:=bool((audience.get("hidden",{}) as Dictionary).get("bluff",false)) if audience.get("hidden") is Dictionary else false
	if kind=="threat" and option_id in ["defy","counter"] and not bluff: on_refusal(audience,option_id)
	elif kind=="threat" and option_id in ["defy","counter"] and bluff: _stat("bluffs_called")
	elif kind=="threat" and option_id=="pay": _stat("paid")
	if type=="war_support" and option_id=="stand": _stand_with(civ_id,String(situation.get("enemy","")))

static func on_refusal(audience:Dictionary,option_id:String)->Dictionary:
	## A real demand refused: the ruler decides, by trait and strength, whether
	## and when to come.
	var civ_id:=String(audience.civ_id)
	var s:=state()
	var day:=_day()
	var rival:=_rival(civ_id)
	var trait_id:=String(rival.get("trait",""))
	var grudge:=float(rival.get("grudge_weight",0.0))
	var r:=ratio(civ_id)
	var civ:=_civ(civ_id)
	var chance:=float(FOLLOW.get(trait_id,0.7))+minf(grudge,1.5)*0.1+clampf(r-1.0,-0.6,0.8)*0.3+(0.1 if option_id=="counter" else 0.0)+(0.08 if Hall._hungry(civ) else 0.0)
	chance=clampf(chance,0.2,0.95)
	var rng:=_rng("refusal:"+String(audience.id))
	var follow:=rng.randf()<chance
	var entry:={"day":day,"civ":civ_id,"id":String(audience.id),"type":String((audience.get("situation",{}) as Dictionary).get("type","")),"follow":follow,"harm_day":-1,"chance":snappedf(chance,0.01)}
	(s.refusals as Array).push_front(entry)
	while (s.refusals as Array).size()>REFUSALS_MAX: (s.refusals as Array).pop_back()
	_stat("real_refusals")
	if follow:
		var lo:=20 if trait_id=="hunter" else 40
		var hi:=150 if trait_id=="hunter" else 260
		_schedule(civ_id,day+rng.randi_range(lo,hi),"refusal",String(audience.id))
	else:
		_log(civ_id,"stood_down","%s let the refusal pass." % String(rival.get("name",_name(civ_id))),{"ref":String(audience.id)})
	return entry

static func _schedule(civ_id:String,due:int,cause:String,ref:String)->void:
	var f:=front(civ_id)
	var pending:Dictionary=f.pending
	if pending.is_empty() or due<int(pending.get("day",due)):
		f["pending"]={"day":due,"cause":cause,"ref":ref,"stack":int(pending.get("stack",0))+1}
	else:
		pending["stack"]=int(pending.get("stack",1))+1

static func _mark_harm(civ_id:String,day:int)->void:
	for r in state().refusals:
		if r is Dictionary and String(r.get("civ",""))==civ_id and int(r.get("harm_day",-1))<0 and day-int(r.get("day",0))<=730 and day>=int(r.get("day",0)):
			r["harm_day"]=day

static func _truce_binds(civ_id:String,day:int)->bool:
	var relation:=_relation(civ_id)
	return String(relation.get("treaty","none"))=="non_aggression" or int(relation.get("truce_until_day",0))>day

static func _execute(civ_id:String,day:int)->void:
	var f:=front(civ_id)
	var pending:Dictionary=f.pending
	f["pending"]={}
	var relation:=_relation(civ_id)
	if relation.is_empty() or bool(relation.get("at_war",false)): return
	if _truce_binds(civ_id,day):
		_log(civ_id,"held_back","%s kept to the truce." % _name(civ_id))
		return
	if day-int(f.last_harm)>LEVEL_DECAY_DAYS: f["level"]=maxi(0,int(f.level)-1)
	var rival:=_rival(civ_id)
	var rng:=_rng("rung:%s:%d" % [civ_id,day])
	var level:=int(f.level)
	var cause:=String(pending.get("cause","refusal"))
	# The ladder is strict: war comes only after they have already fought us
	# at the border (a skirmish of theirs within three years).
	if level>=2 and day-int(f.get("last_skirmish",-99999))<=3*365 and day-int(f.last_war_end)>=WAR_COOLDOWN:
		var p_war:=clampf(0.12+ratio(civ_id)*0.12+float(rival.get("grudge_weight",0.0))*0.1+(0.1 if String(rival.get("trait","")) in ["grudge","hunter"] else 0.0),0.1,0.5)
		if rng.randf()<p_war:
			declare(civ_id,day,_cause_words(civ_id,cause))
			return
	if level>=1 and rng.randf()<0.6: _raid(civ_id,day,cause,true)
	else: _raid(civ_id,day,cause,false)

static func _cause_words(civ_id:String,cause:String)->String:
	match cause:
		"refusal": return "the tribute you would not pay"
		"grudge":
			var rival:=_rival(civ_id)
			var grudges:Array=rival.get("grudges",[])
			if not grudges.is_empty(): return (_rivals().call("narrate",String((grudges[0] as Dictionary).get("text","an old wrong"))) as String)
			return "an old wrong"
		"sided": return "your siding with their enemy"
		"vengeance": return "the blood your fighters spilled"
	return "old wrongs"

# --------------------------------------------------------------------------
# Raids and skirmishes
# --------------------------------------------------------------------------

static func _raid(civ_id:String,day:int,cause:String,skirmish:bool)->Dictionary:
	var f:=front(civ_id)
	var name:=_name(civ_id)
	var key:="raid:%s:%d" % [civ_id,day]
	var rng:=_rng(key)
	var target:=_pick_target(civ_id,rng)
	var t:Dictionary=TARGETS[target]
	var guarded:=int(f.guard_until)>day
	var their_n:=_band_size(_their_pop(civ_id),rng.randf_range(0.05,0.07) if skirmish else rng.randf_range(0.03,0.05))
	var our_n:=_band_size(_our_pop(),rng.randf_range(0.04,0.06) if (skirmish or guarded) else rng.randf_range(0.02,0.035))
	var civ:=_civ(civ_id)
	var general:=_general()
	var attacker:=_band("%s raiders" % name,their_n,float(civ.get("knowledge",0.15)),float(civ.get("military_readiness",0.5)),"their war leader",0.5)
	var defender:=_band("%s" % String(GameState.settlement_name),our_n,_our_tech(),0.55 if guarded else 0.4,String(general.get("name","")),_general_skill(general) if guarded else 0.4)
	var fight:=_clash(attacker,defender,1.35 if guarded else 1.0,key)
	var won:=bool(fight.won)
	var lethal:=bool(t.lethal)
	var our_dead:=_cap_dead(int(fight.def_dead),_our_pop()) if lethal else 0
	var their_dead:=_cap_dead(int(fight.att_dead),_their_pop(civ_id))
	if not skirmish and not won: their_dead=mini(their_dead,1)
	var stock:=Hall.player_stock("Food")
	var loot:=0.0
	if won: loot=minf(stock*rng.randf_range(0.05,0.12)*(1.4 if skirmish else 1.0),float(their_n)*CARRY)
	elif rng.randf()<0.4: loot=minf(stock*0.02,float(their_n)*4.0)
	if target=="scouts": loot=minf(loot,12.0)
	var taken:=EXCHANGE.take("player","Food",loot) if loot>=1.0 else 0.0
	if taken>0.0: Hall._credit_civ(civ_id,"Food",taken*(0.5 if target=="fields" else 1.0))
	var captives:=0
	if won and lethal and target in ["gathering","hunters","herds"] and rng.randf()<(0.3 if skirmish else 0.18): captives=1
	var names:=_names(our_dead,key,0.5 if target in ["gathering","racks"] else 0.15)
	our_dead=_our_deaths(our_dead)
	their_dead=_their_deaths(civ_id,their_dead)
	captives=_our_captives_lost(captives,civ_id)
	Hall._shift_relation(civ_id,-0.06 if skirmish else -0.04,0.14 if skirmish else 0.1)
	var rivals:=_rivals()
	if cause=="refusal": rivals.call("settle_grudges",civ_id,0.4)
	if their_dead>0: rivals.call("grudge",civ_id,"the %s we lost at your %s" % ["hunters" if their_dead>1 else "hunter",String(t.words).trim_prefix("the ").trim_prefix("a ").trim_prefix("our ")],0.25,"raid_dead:"+key)
	f["level"]=maxi(int(f.level),2 if skirmish else 1)
	f["last_harm"]=day
	if skirmish: f["last_skirmish"]=day
	f["taken"]=taken
	f["last_raid"]={"day":day,"target":target,"their_n":their_n,"our_dead":our_dead,"their_dead":their_dead,"taken":roundi(taken),"captives":captives,"skirmish":skirmish,"cause":cause,"names":names}
	_mark_harm(civ_id,day)
	_stat("skirmishes" if skirmish else "raids")
	# Told plainly: who came, where, who died, what was taken, and why.
	var where:=String(t.words)
	var text:=""
	if target=="scouts":
		text="%d %s men caught %s in the open and drove them home. They took %d Food from the packs." % [their_n,name,where,roundi(taken)]
	elif skirmish:
		text="%d %s fighters crossed the border at %s and our people met them. %s" % [their_n,name,where,_dead_words(our_dead,names,String(t.who))]
		if their_dead>0: text+=" %d of theirs fell." % their_dead
		text+=" They took %d Food." % roundi(taken) if taken>=1.0 else " They took nothing."
	else:
		text="At first light %d %s men came for %s. %s" % [their_n,name,where,_dead_words(our_dead,names,String(t.who))]
		text+=" They carried off %d Food." % roundi(taken) if taken>=1.0 else " They were driven off empty-handed."
		if their_dead>0: text+=" %d of the raiders did not go home." % their_dead
	if captives>0: text+=" One of ours was taken away with them."
	if guarded and not won: text+=" The watch at the approaches held."
	text+=" It was for %s." % _cause_words(civ_id,cause) if cause!="" else ""
	var title:="%s %s at %s" % [name,"Fighters" if skirmish else "Raiders",_cap(where.trim_prefix("our "))]
	_chronicle(key,title,text,"moment" if our_dead>0 or skirmish or captives>0 else "notice",civ_id)
	ForeignDiplomacy.remember(civ_id,"Our %s went against the god's people at %s and came home with %d Food." % ["fighters" if skirmish else "raiders",where,roundi(taken)])
	_log(civ_id,"skirmish" if skirmish else "raid",text,{"our_dead":our_dead,"their_dead":their_dead,"taken":roundi(taken),"captives":captives,"target":target,"cause":cause})
	_file(civ_id,"raided",text,day)
	return f.last_raid

static func _cap(text:String)->String:
	return text.substr(0,1).to_upper()+text.substr(1) if text!="" else text

# --------------------------------------------------------------------------
# War: declaration, the general's operations, the enemy's, the ending
# --------------------------------------------------------------------------

static func declare(civ_id:String,day:int,cause:String,ally:String="")->bool:
	var index:=Hall._civ_index(civ_id)
	if index<0: return false
	var world:=WorldSimulation.world
	var civ:Dictionary=world.civilizations[index]
	var relation:Dictionary=civ.get("player_relation",{})
	if bool(relation.get("at_war",false)): _adopt(civ_id,day); return true
	relation["at_war"]=true; relation["treaty"]="war"; relation["stance"]="hostile"; relation["trade"]=0.0
	relation["contact_level"]=maxi(2,int(relation.get("contact_level",0)))
	relation["opinion"]=clampf(float(relation.get("opinion",0.0))-0.2,-1.0,1.0); relation["border_tension"]=maxf(0.8,float(relation.get("border_tension",0.0)))
	relation["war_goal"]="defend"; relation["war_target_region_id"]=""; relation["war_score"]=0.0; relation["conflict_turns"]=0
	relation["war_started_day"]=day; relation["last_war_result"]="ongoing"
	relation["war_id"]=String(world._start_war("player",civ_id,"defend","",day,"War over %s" % cause)) if world.has_method("_start_war") else ""
	civ["player_relation"]=relation
	world.civilizations[index]=civ
	var f:=front(civ_id)
	f["level"]=3
	f["last_harm"]=day
	var rng:=_rng("war:%s:%d" % [civ_id,day])
	f["war"]={"start":day,"war_id":String(relation.war_id),"cause":cause.substr(0,120),"our_dead":0,"their_dead":0,"our_exh":0.0,"their_exh":0.0,"score":0,
		"op":{},"objective":"","queued":"","next_enemy":day+rng.randi_range(25,70),"filed_day":day,"chief_held":false,"ally":ally,"terms":{},"terms_day":-1,"ops":0}
	_stat("wars")
	var name:=_name(civ_id)
	var theirs:=_band_size(_their_pop(civ_id),0.06)
	var ours:=_band_size(_our_pop(),0.06)
	var text:="%s has come to war over %s. They can put about %d fighters in the field; we have about %d." % [name,cause,theirs,ours]
	if ally!="": text="Your fighters go to stand with %s. %s is at war with us now: about %d of theirs against about %d of ours." % [_name(ally),name,theirs,ours]
	var general:=_general()
	if not general.is_empty(): text+=" %s waits at the fire for your word." % EraNames.given_of(String(general.get("name","")))
	_chronicle("declared:%s:%d" % [civ_id,day],"War With %s" % name,text,"moment",civ_id)
	ForeignDiplomacy.remember(civ_id,"We went to war with the god's people over %s." % cause)
	_log(civ_id,"war",text,{"ally":ally})
	_mark_harm(civ_id,day)
	_file(civ_id,"war",text,day)
	return true

static func _adopt(civ_id:String,day:int)->void:
	## A war opened by other means (an invasion, an uprising, a declaration the
	## god sent): the general takes it up.
	var f:=front(civ_id)
	if not (f.war as Dictionary).is_empty(): return
	var relation:=_relation(civ_id)
	var rng:=_rng("adopt:%s:%d" % [civ_id,day])
	f["level"]=3
	f["war"]={"start":int(relation.get("war_started_day",day)),"war_id":String(relation.get("war_id","")),"cause":"the war","our_dead":0,"their_dead":0,"our_exh":0.0,"their_exh":0.0,"score":0,
		"op":{},"objective":"","queued":"","next_enemy":day+rng.randi_range(30,80),"filed_day":day,"chief_held":false,"ally":"","terms":{},"terms_day":-1,"ops":0}
	_stat("wars_adopted")
	_file(civ_id,"war","War with %s has begun. The war leader asks what you want done." % _name(civ_id),day)

static func _stand_with(ally:String,enemy:String)->void:
	if enemy=="" or enemy=="player" or Hall._civ_index(enemy)<0: return
	var day:=_day()
	var kin:=not (_rivals().call("has_bond",ally,["marriage","ally"]) as Dictionary).is_empty()
	if kin and not _truce_binds(enemy,day) and not bool(_relation(enemy).get("at_war",false)):
		declare(enemy,day,"your fighters standing with %s" % _name(ally),ally)
		_stat("dragged_in")
	elif not kin and _rng("sided:%s:%s:%d" % [ally,enemy,day]).randf()<0.5 and int(_relation(enemy).get("contact_level",0))>=1:
		_schedule(enemy,day+_rng("sided_day:%s:%d" % [enemy,day]).randi_range(60,240),"sided","stand:"+ally)

static func stand_words(civ_id:String,enemy:String,name:String,enemy_name:String)->String:
	## The option text for standing with a people at war.
	var kin:=not (_rivals().call("has_bond",civ_id,["marriage","ally"]) as Dictionary).is_empty()
	if kin: return "You are kin to %s: your fighters go to their war, and %s will be at war with you." % [name,enemy_name]
	return "Warmer with %s; %s will count you an enemy's friend, and may send raiders." % [name,enemy_name]

static func _objective_for_general(civ_id:String,general:Dictionary,at_war:bool)->String:
	## What the war leader does without the god's word, by their own character.
	var courage:=float(general.get("courage",0.5))
	var p:Dictionary=general.get("personality",{}) if general.get("personality") is Dictionary else {}
	var care:=float(p.get("empathy",0.5))
	var r:=ratio(civ_id)
	var war:Dictionary=front(civ_id).get("war",{})
	if at_war:
		if float(war.get("our_exh",0.0))>0.45 and care>0.5: return "war_parley"
		if r<0.85 and courage>0.55: return "war_burn"
		if r<0.7 and courage>0.75: return "war_chief"
		return "war_guard"
	if r<1.1 and courage>0.55: return "war_pursue"
	if care>0.65: return "war_parley"
	return "war_guard"

static func _march_days(civ_id:String,rng:RandomNumberGenerator)->int:
	var civ:=_civ(civ_id)
	var world:=WorldSimulation.world
	var km:=40.0
	if world.has_method("_civilization_world_position") and GameState.settlement_site_committed:
		var there:Vector2=world._civilization_world_position(civ)
		var here:Vector2=world.player_world_origin
		km=maxf(5.0,here.distance_to(there))
	return clampi(ceili(km/18.0)+rng.randi_range(1,4),3,30)

static func order(civ_id:String,objective:String,auto:bool=false)->String:
	## The god's word (or the general's own judgment) becomes an operation.
	var day:=_day()
	var f:=front(civ_id)
	var war:Dictionary=f.get("war",{})
	var at_war:=not war.is_empty()
	var general:=_general()
	var gname:=EraNames.given_of(String(general.get("name","The war leader"))) if not general.is_empty() else "The war leader"
	if objective=="war_general": objective=_objective_for_general(civ_id,general,at_war)
	if objective=="war_rest": objective="war_guard" if at_war else "war_let"
	if at_war and not (war.op as Dictionary).is_empty():
		war["queued"]=objective
		return "%s is already in the field. Your word will stand when they are back." % gname
	var rng:=_rng("order:%s:%s:%d" % [civ_id,objective,day])
	var name:=_name(civ_id)
	_stat("orders_auto" if auto else "orders")
	var prefix:="With no word from you, " if auto else ""
	if at_war:
		war["objective"]=objective
		war["ordered_day"]=day
	match objective:
		"war_guard":
			f["guard_until"]=day+GUARD_DAYS
			var n:=_band_size(_our_pop(),0.05)
			_log(civ_id,"order","guard",{"auto":auto})
			return "%s%s takes %d to watch the approaches for half a year. Anyone who comes from %s will meet them." % [prefix,gname,n,name]
		"war_let":
			_log(civ_id,"order","let",{"auto":auto})
			_rivals().call("settle_grudges",civ_id,0.3)
			if String(_rival(civ_id).get("trait","")) in ["hunter","bluffer","grudge"] and rng.randf()<0.35:
				_schedule(civ_id,day+rng.randi_range(120,330),"grudge","bolder")
			return "The dead are buried. No one goes after %s this year." % name
		"war_pay":
			var terms:Dictionary=war.get("terms",{})
			var paid:=Hall._debit_player("Food",float(terms.get("amount",0.0)))
			if paid>0.0: Hall._credit_civ(civ_id,"Food",paid)
			_close_war(civ_id,day,"tribute paid","You paid %d Food. %s's fighters went home." % [roundi(paid),name])
			return "You paid %d Food to %s, and the war is over." % [roundi(paid),name]
	var band:=_band_size(_our_pop(),rng.randf_range(0.05,0.07)) if objective!="war_parley" else 2
	var due:=day+_march_days(civ_id,rng)
	var op:={"objective":objective,"start":day,"due":due,"band":band,"general_pid":int(general.get("person_id",0)),"general":gname,"auto":auto}
	if at_war: war["op"]=op
	else: f["op"]=op
	_log(civ_id,"order",objective,{"auto":auto,"band":band,"due":due})
	match objective:
		"war_parley": return "%s%s sends two messengers to %s to ask for an end to it. They should be back in %d days." % [prefix,gname,name,due-day]
		"war_pursue": return "%s%s takes %d after the raiders, on their trail toward %s. Word will come back when it is done." % [prefix,gname,band,name]
		"war_burn": return "%s%s leaves at dusk with %d to burn %s's stores." % [prefix,gname,band,name]
		"war_chief": return "%s%s takes %d of the best to bring back %s's chief. Few of them expect to come home unhurt." % [prefix,gname,band,name]
	return "%s goes." % gname

static func _resolve_op(civ_id:String,op:Dictionary,day:int)->void:
	var f:=front(civ_id)
	var war:Dictionary=f.get("war",{})
	var at_war:=not war.is_empty()
	var name:=_name(civ_id)
	var civ:=_civ(civ_id)
	var objective:=String(op.get("objective",""))
	var gname:=String(op.get("general","The war leader"))
	var key:="op:%s:%s:%d" % [civ_id,objective,int(op.get("start",day))]
	var rng:=_rng(key)
	_stat("ops")
	if at_war: war["ops"]=int(war.get("ops",0))+1
	if objective=="war_parley":
		var rival:=_rival(civ_id)
		var accept:=0.25+(float(war.get("their_exh",0.0))*0.9 if at_war else 0.35)+float(war.get("score",0))*0.06-float(rival.get("grudge_weight",0.0))*0.12-(0.15 if String(rival.get("trait",""))=="grudge" else 0.0)+float(rival.get("dread",0.0))*0.2
		if rng.randf()<clampf(accept,0.05,0.9):
			if at_war: _close_war(civ_id,day,"truce","The messengers came back with a truce. %s's fighters are going home." % name)
			else:
				f["level"]=maxi(0,int(f.level)-1); f["pending"]={}
				_rivals().call("settle_grudges",civ_id,0.5)
				_chronicle(key,"Words With %s" % name,"%s's messengers came back: %s will send no more raiders. The matter is closed." % [gname,name],"notice",civ_id)
			_log(civ_id,"parley_ok","accepted")
		else:
			var refusal:="%s's messengers came back with nothing. %s will not hear of it." % [gname,name]
			_chronicle(key,"%s Will Not Talk" % name,refusal,"notice",civ_id)
			_log(civ_id,"parley_refused",refusal)
			if at_war: _file(civ_id,"report",refusal,day)
		return
	var their_share:=rng.randf_range(0.04,0.06) if objective=="war_pursue" else (rng.randf_range(0.05,0.07) if at_war else rng.randf_range(0.03,0.05))
	var their_n:=_band_size(_their_pop(civ_id),their_share)
	var general:=Hall._official(int(op.get("general_pid",0)))
	if general.is_empty(): general=_general()
	var skill:=_general_skill(general)
	var ours:=_band(String(GameState.settlement_name),int(op.get("band",4)),_our_tech(),0.6,gname,skill)
	var terrain:=1.0 if objective=="war_pursue" else (1.45 if objective=="war_chief" else 1.15)
	var defender:=_band(name,their_n,float(civ.get("knowledge",0.15)),float(civ.get("military_readiness",0.5)),"their war leader",0.5)
	var fight:=_clash(ours,defender,terrain,key)
	var won:=bool(fight.won)
	if objective=="war_chief": won=won and rng.randf()<0.55
	var our_dead:=_cap_dead(int(fight.att_dead)+(1 if objective=="war_chief" and not won else 0),_our_pop())
	var their_dead:=_cap_dead(int(fight.def_dead),_their_pop(civ_id))
	var names:=_names(our_dead,key,0.1)
	our_dead=_our_deaths(our_dead)
	their_dead=_their_deaths(civ_id,their_dead)
	var loot:=0.0
	var captives:=0
	var text:=""
	var title:=""
	match objective:
		"war_pursue":
			title="The Raiders Overtaken" if won else "The Trail Went Cold"
			if won:
				loot=EXCHANGE.take(civ_id,"Food",minf(maxf(float(f.get("taken",0.0)),8.0),float(op.get("band",4))*CARRY))
				captives=_their_captives(civ_id,1 if rng.randf()<0.4 else 0)
				text="%s caught the %s raiders two days out.%s We brought back %d Food%s." % [gname,name," %d of theirs fell." % their_dead if their_dead>0 else "",roundi(loot)," and one captive" if captives>0 else ""]
			else:
				text="%s followed the %s raiders to their own ground and turned back." % [gname,name]
				if their_dead>0: text+=" %d of theirs fell in a fight at the edge of it." % their_dead
		"war_burn":
			title="%s's Stores Burned" % name if won else "Beaten Back From %s" % name
			if won:
				var stock:=Hall.foreign_stock(civ_id,"Food")
				var burned:=EXCHANGE.take(civ_id,"Food",minf(stock*rng.randf_range(0.15,0.3),float(op.get("band",4))*rng.randf_range(30.0,50.0)))
				loot=minf(burned*rng.randf_range(0.25,0.45),float(op.get("band",4))*CARRY)
				text="%s's band reached %s's stores by night and burned them. They carried %d Food home and left %d burning." % [gname,name,roundi(loot),roundi(burned-loot)]
				if their_dead>0: text+=" %d of theirs fell." % their_dead
			else:
				text="%s's band was seen before it reached %s's stores and had to fight its way out." % [gname,name]
				if their_dead>0: text+=" %d of theirs fell." % their_dead
		"war_chief":
			title="%s's Chief Taken" % name if won else "The Strike at %s's Chief Failed" % name
			if won:
				if at_war: war["chief_held"]=true
				text="%s came back with %s. %s is held at our fire." % [gname,String(_rival(civ_id).get("name","their chief")),String(_rival(civ_id).get("name","their chief")).get_slice(" ",0)]
				_rivals().call("grudge",civ_id,"how you dragged our chief to your fire",1.0,"chief:"+key)
			else:
				text="%s's band could not get near %s's chief." % [gname,name]
	var dead_text:=_dead_words(our_dead,names,"fighters")
	if our_dead>0: text+=" "+dead_text
	if loot>0.0: EXCHANGE.receive("player","Food",loot)
	if at_war:
		war["score"]=int(war.get("score",0))+(1 if won else -1)
		_exhaust(civ_id,our_dead,their_dead)
		_record_battle(civ_id,title,our_dead,their_dead,captives,"won" if won else "lost")
	else:
		# Blood for blood: a people you strike may come back for more.
		f["level"]=maxi(int(f.level),2 if objective=="war_burn" else 1)
		if their_dead>0 or objective=="war_burn":
			_rivals().call("grudge",civ_id,"the %s you burned" % "stores" if objective=="war_burn" else "hunters you killed on our own ground",0.4,"struck:"+key)
			if rng.randf()<(0.6 if objective=="war_burn" else 0.4): _schedule(civ_id,day+rng.randi_range(60,300),"vengeance",key)
	Hall._shift_relation(civ_id,-0.05,0.08)
	_chronicle(key,title,text,"moment",civ_id)
	_log(civ_id,"op_"+objective.trim_prefix("war_"),text,{"won":won,"our_dead":our_dead,"their_dead":their_dead,"loot":roundi(loot),"captives":captives})
	if at_war and bool(war.get("chief_held",false)): return
	_file(civ_id,"report",text,day)

static func _enemy_op(civ_id:String,day:int)->void:
	var f:=front(civ_id)
	var war:Dictionary=f.war
	var name:=_name(civ_id)
	var civ:=_civ(civ_id)
	var key:="enemy:%s:%d" % [civ_id,day]
	var rng:=_rng(key)
	var guarded:=int(f.guard_until)>day
	var their_n:=_band_size(_their_pop(civ_id),rng.randf_range(0.05,0.07))
	var our_n:=_band_size(_our_pop(),rng.randf_range(0.05,0.07) if guarded else rng.randf_range(0.03,0.05))
	var general:=_general()
	var attacker:=_band(name,their_n,float(civ.get("knowledge",0.15)),float(civ.get("military_readiness",0.5)),"their war leader",0.5)
	var defender:=_band(String(GameState.settlement_name),our_n,_our_tech(),0.6 if guarded else 0.45,String(general.get("name","")),_general_skill(general))
	var fight:=_clash(attacker,defender,1.4 if guarded else 1.1,key)
	var won:=bool(fight.won)
	var target:=_pick_target(civ_id,rng)
	var t:Dictionary=TARGETS[target] if target!="scouts" else TARGETS.gathering
	var our_dead:=_cap_dead(int(fight.def_dead),_our_pop())
	var their_dead:=_cap_dead(int(fight.att_dead),_their_pop(civ_id))
	var names:=_names(our_dead,key,0.3)
	our_dead=_our_deaths(our_dead)
	their_dead=_their_deaths(civ_id,their_dead)
	var taken:=0.0
	var captives:=0
	if won:
		taken=EXCHANGE.take("player","Food",minf(Hall.player_stock("Food")*rng.randf_range(0.06,0.14),float(their_n)*CARRY))
		if taken>0.0: Hall._credit_civ(civ_id,"Food",taken)
		if rng.randf()<0.3: captives=_our_captives_lost(1,civ_id)
	war["score"]=int(war.get("score",0))+(-1 if won else 1)
	_exhaust(civ_id,our_dead,their_dead)
	_record_battle(civ_id,"%s attack at %s" % [name,String(t.words)],our_dead,their_dead,0,"lost" if won else "held")
	var text:=""
	if won:
		text="%d %s fighters broke through at %s. %s They carried off %d Food%s." % [their_n,name,String(t.words),_dead_words(our_dead,names,String(t.who)),roundi(taken)," and one of ours" if captives>0 else ""]
		if their_dead>0: text+=" %d of theirs fell." % their_dead
	else:
		text="%d %s fighters came at %s and were thrown back%s. %s" % [their_n,name,String(t.words)," by the watch at the approaches" if guarded else "",_dead_words(our_dead,names,String(t.who))]
		if their_dead>0: text+=" %d of theirs did not go home." % their_dead
	_chronicle(key,"%s %s" % [name,"Break Through" if won else "Thrown Back"],text,"moment" if our_dead>0 or captives>0 or won else "notice",civ_id)
	_log(civ_id,"enemy_attack",text,{"won":won,"our_dead":our_dead,"their_dead":their_dead,"taken":roundi(taken),"captives":captives})
	if (war.op as Dictionary).is_empty() and day-int(front(civ_id).get("matter_day",-1))>45: _file(civ_id,"report",text,day)

static func _check_end(civ_id:String,day:int)->void:
	var f:=front(civ_id)
	var war:Dictionary=f.war
	var name:=_name(civ_id)
	var ours:=float(war.get("our_exh",0.0)); var theirs:=float(war.get("their_exh",0.0))
	var score:=int(war.get("score",0))
	var length:=day-int(war.get("start",day))
	if bool(war.get("chief_held",false)):
		var ransom:=EXCHANGE.take(civ_id,"Food",maxf(10.0,Hall.foreign_stock(civ_id,"Food")*0.25))
		if ransom>0.0: EXCHANGE.receive("player","Food",ransom)
		_close_war(civ_id,day,"tribute received","%s ransomed its chief for %d Food and asked for peace." % [name,roundi(ransom)])
		return
	if theirs>=0.6 or (theirs>=0.4 and score>=2):
		var tribute:=EXCHANGE.take(civ_id,"Food",maxf(8.0,Hall.foreign_stock(civ_id,"Food")*0.15))
		if tribute>0.0: EXCHANGE.receive("player","Food",tribute)
		_close_war(civ_id,day,"tribute received","%s has had enough. Its herald brought %d Food and asked for peace." % [name,roundi(tribute)])
		return
	if (ours>=0.6 or (ours>=0.4 and score<=-2)) and (war.terms as Dictionary).is_empty():
		var amount:=Hall._nice(maxf(10.0,Hall.player_stock("Food")*0.2))
		war["terms"]={"resource":"Food","amount":amount}
		war["terms_day"]=day
		var text:="%s's herald came to the edge of the camp: pay %d Food and the fighting stops." % [name,roundi(amount)]
		_chronicle("terms:%s:%d" % [civ_id,day],"%s Names Its Price" % name,text,"notice",civ_id)
		_file(civ_id,"terms",text,day)
		return
	if not (war.terms as Dictionary).is_empty() and day-int(war.get("terms_day",day))>=TERMS_WAIT and (war.op as Dictionary).is_empty():
		_close_war(civ_id,day,"exhaustion","No one answered %s's herald. Our people stopped going out to fight, and so did theirs." % name)
		return
	if (length>=int(2.5*365) and ours>=0.3 and theirs>=0.3) or length>=4*365:
		_close_war(civ_id,day,"exhaustion","After %d winters of it, neither side sends fighters any more. No one made peace; the war just stopped." % maxi(1,roundi(length/365.0)))

static func _close_war(civ_id:String,day:int,result:String,text:String)->void:
	var f:=front(civ_id)
	var war:Dictionary=f.get("war",{})
	var index:=Hall._civ_index(civ_id)
	var world:=WorldSimulation.world
	if index>=0:
		var civ:Dictionary=world.civilizations[index]
		var relation:Dictionary=civ.player_relation
		if bool(relation.get("at_war",false)):
			relation["at_war"]=false; relation["treaty"]="truce"; relation["stance"]="watchful"; relation["border_tension"]=0.35
			relation["truce_until_day"]=day+TRUCE_DAYS; relation["last_war_result"]=result
			if world.has_method("_end_war"): world._end_war(String(relation.get("war_id",war.get("war_id",""))),day,result)
			if world.has_method("_remove_pending_player_incidents"): world._remove_pending_player_incidents(civ_id)
			civ["player_relation"]=relation
			world.civilizations[index]=civ
	var name:=_name(civ_id)
	var told:="%s In all, %d of ours and %d of theirs died in it." % [text,int(war.get("our_dead",0)),int(war.get("their_dead",0))]
	_chronicle("peace:%s:%d" % [civ_id,day],"The War With %s Is Over" % name,told,"moment",civ_id)
	ForeignDiplomacy.remember(civ_id,"The war with the god's people ended: %s." % result)
	_rivals().call("settle_grudges",civ_id,0.6)
	if result=="tribute received": _rivals().call("grudge",civ_id,"the war you made us pay for",0.35,"lost_war:%d" % day)
	_stat("ends_"+result.replace(" ","_"))
	_log(civ_id,"war_end",told,{"result":result,"our_dead":int(war.get("our_dead",0)),"their_dead":int(war.get("their_dead",0)),"days":day-int(war.get("start",day))})
	f["war"]={}; f["pending"]={}; f["level"]=1; f["last_war_end"]=day; f["guard_until"]=-1; f["op"]={}
	_drop_matters(civ_id)

# --------------------------------------------------------------------------
# Daily
# --------------------------------------------------------------------------

static func daily(day:int)->void:
	if WorldSimulation.actor_id!="player" or not GameState.settlement_site_committed or day%TICK!=0: return
	# The authored General Campaign runs its own war; leave it alone.
	if WorldSimulation.system("GeneralCampaign")!=null and bool(WorldSimulation.campaign.active): return
	var s:=state()
	# Wars opened by other means are taken up by the war leader.
	for civ in WorldSimulation.world.civilizations:
		var relation:Dictionary=civ.get("player_relation",{})
		if bool(relation.get("at_war",false)) and bool(civ.get("alive",true)) and not bool(civ.get("general_campaign_owned",false)) and int(relation.get("contact_level",0))>=1 and ((front(String(civ.id)).war as Dictionary).is_empty()): _adopt(String(civ.id),day)
	for civ_id in (s.fronts as Dictionary).keys():
		var id:=String(civ_id)
		var f:=front(id)
		var civ:=_civ(id)
		if civ.is_empty() or not bool(civ.get("alive",true)):
			if not (f.war as Dictionary).is_empty(): f["war"]={}
			continue
		var war:Dictionary=f.war
		if war.is_empty():
			var pending:Dictionary=f.pending
			if not pending.is_empty() and day>=int(pending.get("day",day)): _execute(id,day)
			var op:Dictionary=f.get("op",{})
			if not op.is_empty() and day>=int(op.get("due",day)):
				f["op"]={}
				_resolve_op(id,op,day)
			continue
		if not bool(_relation(id).get("at_war",false)):
			_close_war(id,day,"truce","%s and your people have made peace." % _name(id))
			continue
		var op2:Dictionary=war.get("op",{})
		if not op2.is_empty() and day>=int(op2.get("due",day)):
			war["op"]={}
			_resolve_op(id,op2,day)
			if (front(id).war as Dictionary).is_empty(): continue
			if String(war.get("queued",""))!="":
				var next:=String(war.queued); war["queued"]=""
				order(id,next,false)
		elif op2.is_empty() and day-int(war.get("filed_day",day))>=GENERAL_WAIT and day-int(war.get("ordered_day",-9999))>=GENERAL_WAIT*3 and int(f.guard_until)<day:
			var general:=_general()
			if not general.is_empty():
				var said:=order(id,"war_general",true)
				_chronicle("auto:%s:%d" % [id,day],"%s Acts Alone" % EraNames.given_of(String(general.get("name",""))),said,"notice",id)
		if day>=int(war.get("next_enemy",day+1)):
			_enemy_op(id,day)
			war["next_enemy"]=day+_rng("next:%s:%d" % [id,day]).randi_range(50,120)
		if not (front(id).war as Dictionary).is_empty(): _check_end(id,day)
	if day%30==0:
		_grudges(day)
		_rival_wars(day)

## Neighbouring peoples go to war with each other at about the benchmark rate
## for general war (EPOCHAL_SHIFTS.md s5: 0.15-0.6 wars per people per game
## century before the modern era), faster when they are hungry, hostile,
## pressed at the border or ruled by a grudge-holder or a far hunter. The
## declaration is carried and the war fought by CivilizationSystem.
## Annual war onset per people (split across its neighbours), before the
## multipliers of its condition.
const RIVAL_WAR_BASE:=0.0018
const RIVAL_WAR_CAP:=0.012
const NEIGHBOUR_RANGE:=1.55

static func rival_war_hazard(first:Dictionary,second:Dictionary,relation:Dictionary,neighbours:float=1.0)->float:
	## Annual chance that these two neighbours go to war, from their condition.
	## `neighbours` is the pair's mean count of neighbours: a people's hazard
	## is shared across its borders, not multiplied by them.
	var opinion:=float(relation.get("opinion",0.0))
	var tension:=float(relation.get("border_tension",0.0))
	var factor:=1.0+maxf(0.0,-opinion)*3.0+tension*2.0+(float(first.get("aggression",0.3))+float(second.get("aggression",0.3)))*0.8
	for civ in [first,second]:
		if Hall._hungry(civ): factor+=1.0
		var known:Variant=ForeignDiplomacy.leaders.get(String(civ.id),{})
		var c:Variant=(known as Dictionary).get("character") if known is Dictionary else null
		if c is Dictionary and String((c as Dictionary).get("trait","")) in ["grudge","hunter"]: factor+=0.5
	return clampf(RIVAL_WAR_BASE*factor,0.0,RIVAL_WAR_CAP)/maxf(1.0,neighbours)

static func neighbour_counts()->Dictionary:
	var counts:={}
	var civs:=WorldSimulation.world.civilizations
	for i in civs.size():
		for j in range(i+1,civs.size()):
			if not bool(civs[i].get("alive",true)) or not bool(civs[j].get("alive",true)): continue
			var a:Vector2=civs[i].get("position",Vector2.ZERO); var b:Vector2=civs[j].get("position",Vector2.ZERO)
			if a.distance_to(b)>NEIGHBOUR_RANGE: continue
			counts[String(civs[i].id)]=int(counts.get(String(civs[i].id),0))+1
			counts[String(civs[j].id)]=int(counts.get(String(civs[j].id),0))+1
	return counts

static func _rival_wars(day:int)->void:
	var world:=WorldSimulation.world
	var civs:=world.civilizations
	var counts:=neighbour_counts()
	for i in civs.size():
		for j in range(i+1,civs.size()):
			var first:Dictionary=civs[i]; var second:Dictionary=civs[j]
			if not bool(first.get("alive",true)) or not bool(second.get("alive",true)): continue
			if bool(first.get("general_campaign_owned",false)) or bool(second.get("general_campaign_owned",false)): continue
			var a:Vector2=first.get("position",Vector2.ZERO); var b:Vector2=second.get("position",Vector2.ZERO)
			if a.distance_to(b)>NEIGHBOUR_RANGE: continue
			var relation:Dictionary=(first.get("relations",{}) as Dictionary).get(String(second.id),{})
			if relation.is_empty() or bool(relation.get("at_war",false)) or String(relation.get("pending_message",""))!="" or String(relation.get("treaty","none")) in ["non_aggression","truce","trade"]: continue
			var monthly:=rival_war_hazard(first,second,relation,(float(counts.get(String(first.id),1))+float(counts.get(String(second.id),1)))*0.5)/12.0
			if _rng("rivalwar:%s:%s:%d" % [String(first.id),String(second.id),day]).randf()>=monthly: continue
			var carried:=relation.duplicate(true)
			carried["pending_message"]="war"
			carried["pending_message_sent_day"]=day
			carried["pending_message_due_day"]=day+(world._intercivilization_message_days(first,second,false) if world.has_method("_intercivilization_message_days") else 10)
			carried["border_tension"]=maxf(0.55,float(carried.get("border_tension",0.0)))
			carried["opinion"]=minf(-0.25,float(carried.get("opinion",0.0)))
			world._set_pair_relation(i,j,carried)
			_stat("rival_wars")

static func _grudges(day:int)->void:
	## A heavy old grudge sends raiders without a new demand.
	for civ_id in ForeignDiplomacy.leaders.keys():
		var id:=String(civ_id)
		var relation:=_relation(id)
		if relation.is_empty() or int(relation.get("contact_level",0))<2 or bool(relation.get("at_war",false)) or _truce_binds(id,day): continue
		var f:=front(id)
		if not (f.pending as Dictionary).is_empty() or day-int(f.last_harm)<365: continue
		var rival:=_rival(id)
		var weight:=float(rival.get("grudge_weight",0.0))
		if weight<0.9: continue
		var chance:=clampf((weight-0.8)*0.03,0.0,0.035)*(1.3 if String(rival.get("trait",""))=="grudge" else 1.0)
		if _rng("grudge:%s:%d" % [id,day]).randf()<chance:
			_schedule(id,day+_rng("grudge_day:%s:%d" % [id,day]).randi_range(20,90),"grudge","grudge")

# --------------------------------------------------------------------------
# The court: the war leader's matter, options, answers
# --------------------------------------------------------------------------

static func has_campaign(civ_id:String)->bool:
	return not (front(civ_id).war as Dictionary).is_empty()

static func _drop_matters(civ_id:String)->void:
	var list:Array=Hall.state().matters
	for m in list.duplicate():
		if m is Dictionary and String(m.get("situation_type",""))=="war_campaign" and String((((m.get("audience",{}) as Dictionary).get("situation",{}) as Dictionary).get("war",{}) as Dictionary).get("civ_id",""))==civ_id: list.erase(m)

static func _file(civ_id:String,mode:String,summary:String,day:int)->Dictionary:
	var general:=_general()
	if general.is_empty(): return {}
	_drop_matters(civ_id)
	var name:=_name(civ_id)
	var audience:=Hall._new_audience("court","petition",day)
	audience.speaker={"name":String(general.get("name","")).substr(0,100),"title":String(general.get("office_title","War Leader")).substr(0,100),"person_id":int(general.get("person_id",0)),"role":"official"}
	var headline:String={"raided":"comes about the raid","war":"comes about the war","report":"reports from the field","terms":"brings the enemy's terms"}.get(mode,"comes about the war")
	var text:=summary.substr(0,380)
	audience.petition={"topic":"campaign","summary":text,"suggested_decree":""}
	audience.situation={"type":"war_campaign","ask":"war:%s:%s:%d" % [civ_id,mode,day],"headline":headline,"summary":text,
		"occasion":{"type":"war_campaign","text":"%s and %s" % [mode,name],"day":day,"crisis":mode!="report"},
		"war":{"civ_id":civ_id,"civ_name":name,"mode":mode,"filed":day}}
	var entry:=Hall._file_matter(audience,[])
	entry["urgency"]=0.95 if mode in ["war","terms"] else 0.85
	front(civ_id)["matter_day"]=day
	var war:Dictionary=front(civ_id).war
	if not war.is_empty(): war["filed_day"]=day
	return entry

static func _war_part(audience:Dictionary)->Dictionary:
	var situation:Dictionary=audience.get("situation",{}) if audience.get("situation") is Dictionary else {}
	return situation.get("war",{}) if situation.get("war") is Dictionary else {}

static func _odds_words(odds:float)->String:
	if odds>=1.3: return "I think we win it."
	if odds>=0.95: return "It could go either way."
	if odds>=0.7: return "It will be hard."
	return "I would not bet on it."

static func _odds(civ_id:String,objective:String)->float:
	var r:=ratio(civ_id)
	var terrain:float={"war_pursue":1.0,"war_burn":1.15,"war_chief":1.6}.get(objective,1.0)
	return 1.0/maxf(0.2,r*terrain)

static func options(audience:Dictionary)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	var part:=_war_part(audience)
	var civ_id:=String(part.get("civ_id",""))
	var f:=front(civ_id)
	var war:Dictionary=f.get("war",{})
	var name:=_name(civ_id)
	var mode:=String(part.get("mode",""))
	if civ_id=="" or _civ(civ_id).is_empty() or (mode in ["war","terms"] and war.is_empty()):
		out.append(Hall._option("war_rest","It is past","That war is over.","neutral"))
		return out
	var band:=_band_size(_our_pop(),0.06)
	var theirs:=_band_size(_their_pop(civ_id),0.06)
	var busy:=not (war.get("op",{}) as Dictionary).is_empty() or not (f.get("op",{}) as Dictionary).is_empty()
	var note:=" (after the band now in the field is back)" if busy else ""
	if not war.is_empty():
		out.append(Hall._option("war_guard","Hold the approaches","Keep %d at the approaches for half a year; whoever comes meets spears.%s" % [band,note],"neutral"))
		out.append(Hall._option("war_burn","Burn their stores","Take %d against %s's stores by night. %s%s" % [band,name,_odds_words(_odds(civ_id,"war_burn")),note],"hostile"))
		out.append(Hall._option("war_chief","Bring me their chief","Go for %s's chief. %s If it fails, few come back.%s" % [name,_odds_words(_odds(civ_id,"war_chief")),note],"hostile"))
		out.append(Hall._option("war_parley","Send for a truce","Two messengers to %s. %s" % [name,"They may listen now." if float(war.get("their_exh",0.0))>=0.3 else "They are not tired of it yet."],"warm"))
		var terms:Dictionary=war.get("terms",{})
		if not terms.is_empty():
			var short:=Hall._short("Food",float(terms.get("amount",0.0)))
			out.append(Hall._option("war_pay","Pay what they ask","%d Food, and the war ends." % roundi(float(terms.get("amount",0.0))),"neutral",short=="",short))
		out.append(Hall._option("war_general","Do as you judge","The war leader chooses.","neutral"))
		return out
	var raid:Dictionary=f.get("last_raid",{})
	out.append(Hall._option("war_pursue","Go after them","Take %d on the raiders' trail%s. %s Blood may answer blood.%s" % [band," and bring back the %d Food" % int(raid.get("taken",0)) if int(raid.get("taken",0))>0 else "",_odds_words(_odds(civ_id,"war_pursue")),note],"hostile"))
	out.append(Hall._option("war_burn","Burn their stores in return","Take %d against %s's stores. %s %s may come to war over it.%s" % [band,name,_odds_words(_odds(civ_id,"war_burn")),name,note],"hostile"))
	out.append(Hall._option("war_guard","Guard the approaches","A watch of %d for half a year. The next raiders meet spears." % band,"neutral"))
	out.append(Hall._option("war_parley","Send word: enough","Messengers to %s to settle it. Some will call it weakness." % name,"warm"))
	out.append(Hall._option("war_let","Let it pass","Bury the dead and do nothing. %s may take it for weakness." % name,"neutral"))
	return out

static func on_open(audience:Dictionary)->void:
	var part:=_war_part(audience)
	if part.is_empty(): return
	var civ_id:=String(part.get("civ_id",""))
	var speaker:Dictionary=audience.get("speaker",{})
	var general:=GovernmentPeopleSystem.person_snapshot(int(speaker.get("person_id",0)))
	if general.is_empty(): general={"person_id":int(speaker.get("person_id",0)),"name":String(speaker.get("name",""))}
	var name:=_name(civ_id)
	var mode:=String(part.get("mode",""))
	var band:=_band_size(_our_pop(),0.06)
	var theirs:=_band_size(_their_pop(civ_id),0.06)
	var said:=""
	match mode:
		"raided":
			var raid:Dictionary=front(civ_id).get("last_raid",{})
			said="%s came to %s. %s" % [name,String((TARGETS.get(String(raid.get("target","gathering")),TARGETS.gathering) as Dictionary).words),"We lost %d." % int(raid.get("our_dead",0)) if int(raid.get("our_dead",0))>0 else "No one of ours died."]
			if int(raid.get("taken",0))>0: said+=" They took %d Food." % int(raid.get("taken",0))
			said+=" I can take %d after them, or keep the approaches. Tell me which." % band
		"war":
			said="%s is at war with us. They have about %d who can fight; we have about %d. Tell me what you want done, and I will see to it." % [name,theirs,band]
		"report":
			said=String((audience.get("petition",{}) as Dictionary).get("summary","")).substr(0,300)
			said+=" What now?"
		"terms":
			var terms:Dictionary=(front(civ_id).war as Dictionary).get("terms",{})
			said="%s's herald wants %d Food to end it. Our people are worn down. It is your word." % [name,int(float(terms.get("amount",0.0)))]
	var advice:=_objective_for_general(civ_id,general,not (front(civ_id).war as Dictionary).is_empty())
	var advice_words:String={"war_guard":"If it were mine to say, I would hold the approaches and let them come to us.","war_burn":"If it were mine to say, I would burn their stores.",
		"war_chief":"If it were mine to say, I would go for their chief.","war_pursue":"If it were mine to say, I would go after them now, while the trail is fresh.","war_parley":"If it were mine to say, I would send for a truce."}.get(advice,"")
	if said!="": Hall.append_line(String(audience.id),{"speaker":String(general.get("name","")),"role":"official","person_id":int(general.get("person_id",0)),"civ_id":"player","text":said,"day":_day(),"aside":false})
	if advice_words!="": Hall.append_line(String(audience.id),{"speaker":String(general.get("name","")),"role":"official","person_id":int(general.get("person_id",0)),"civ_id":"player","text":advice_words,"day":_day(),"aside":false})

static func resolve(audience:Dictionary,option_id:String)->Dictionary:
	var part:=_war_part(audience)
	var civ_id:=String(part.get("civ_id",""))
	if option_id=="war_rest" and (front(civ_id).war as Dictionary).is_empty() and String(part.get("mode","")) in ["war","terms"]:
		return {"outcome":"That war is already over.","reaction":"neutral"}
	if not option_id in OBJECTIVES: return {"error":"That is not an order the war leader can carry."}
	var outcome:=order(civ_id,option_id,false)
	var pid:=int((audience.get("speaker",{}) as Dictionary).get("person_id",0))
	if pid>0: GovernmentPeopleSystem.record_person_memory(pid,"The god gave me the war with %s: %s" % [_name(civ_id),outcome.substr(0,160)],"audience",0.6,{"emotion":"duty"})
	return {"outcome":outcome,"reaction":"pleased" if option_id in ["war_general","war_guard"] else "neutral"}

const TYPED:=[
	["war_chief",["chief","ruler","leader","bring me","capture","their head"]],
	["war_burn",["burn","stores","granar","raid them","strike them","hit them","their food"]],
	["war_pursue",["after them","pursue","take back","chase","follow","get it back","hunt them"]],
	["war_guard",["defend","hold","guard","ford","watch","approach","protect","keep them out","wall"]],
	["war_parley",["peace","truce","talk","parley","messenger","end it","enough"]],
	["war_pay","pay"],
	["war_let",["let it pass","leave it","do nothing","bury"]],
	["war_general",["you judge","your judgment","you decide","as you see","your call","do what you"]],
]

static func typed_choice(audience_id:String,text:String)->String:
	## The god's own words mapped onto an order the war leader can carry.
	var audience:=Hall.find(audience_id)
	if audience.is_empty() or _war_part(audience).is_empty(): return ""
	var lower:=text.to_lower()
	var open:Dictionary={}
	for option in Hall.options(audience_id):
		if bool(option.get("enabled",true)): open[String(option.id)]=true
	for row in TYPED:
		var words:Array=row[1] if row[1] is Array else [row[1]]
		for word in words:
			if String(word) in lower and open.has(String(row[0])): return String(row[0])
	return ""

extends RefCounted
## Rival rulers as persistent characters, and envoys whose business always
## carries a cost or a string.
##
## - Character. Each foreign ruler the god knows gets a lasting character the
##   first time they are needed: a portrait cell kept for life, one literary
##   voice model kept for life (character_voice.gd), one signature trait that
##   colours every envoy they send, an age and a natural span of years.
## - Memory. Grudges (a refused gift, a defied demand, a broken bond), debts
##   (a gift they count as a loan, food they were given) and bonds (a marriage
##   between houses, an ally's feud, hunting rights) are kept on the ruler.
##   They come back: a later envoy names them, a grudge returns as a demand for
##   redress, a debt falls due and is called, kin call on kin in their wars.
## - Heirs. When a ruler dies their child rules, keeps the parent's voice of
##   the people but not their manner, and inherits the parent's reputation:
##   grudges (somewhat softened), debts and bonds.
## - Strings. Every envoy's gift or request carries a cost or a string: a gift
##   that obliges a marriage or is counted as a loan, tribute that emboldens a
##   third people, an understanding that drags you into their feud, a trade
##   that brings a cough home or carries a craft secret away, a threat that may
##   be a bluff with tells the court can read. A court member objects to one
##   answer (and another may speak for one), in their own voice.
## - Offline talk. Without a live model, the god briefs envoys to a foreign
##   ruler with state-driven choices; the ruler answers in their own manner
##   from what they remember.
##
## State lives on ForeignDiplomacy.leaders[civ_id]["character"] (saved with the
## leaders; older saves create characters lazily). Static helpers; preload.
## Public API for other systems: rival_character(civ_id).

const Hall:=preload("res://scripts/audience_hall.gd")
const CV:=preload("res://scripts/character_voice.gd")
const EraNames:=preload("res://scripts/era_names.gd")
const EXCHANGE:=preload("res://scripts/civilization_exchange.gd")
const SOCIETY:=preload("res://scripts/society_exchange.gd")
const LIVES_PATH:="res://scripts/court_lives.gd"

const GRUDGES_MAX:=12
const DEBTS_MAX:=8
const BONDS_MAX:=8
const LINEAGE_MAX:=6
const RECALLS_MAX:=16
const LATER_MAX:=6
const RECALL_GAP:=300
const GRUDGE_RETURN_MIN:=180
const TICK:=10

## Situations this module generates for the hall (kinds from Hall.SITUATIONS).
const SITUATION_TYPES:=["debt_call","redress_demand"]
## Occasions this module raises, and which situations they invite.
const OCCASION_MIX:={
	"debt_due":{"debt_call":1.0},
	"grudge":{"redress_demand":1.0,"tribute_demand":0.25},
	"kin_call":{"war_support":1.0},
}

const TRAITS:={
	"ledger":{"words":"counts every gift","epithet":"who counts every gift"},
	"grudge":{"words":"never forgets a slight","epithet":"who forgets nothing"},
	"bluffer":{"words":"boasts beyond their spears","epithet":"of the loud threats"},
	"matchmaker":{"words":"binds peoples by marriage","epithet":"who weds peoples together"},
	"hunter":{"words":"covets far hunting grounds","epithet":"of the far hunts"},
	"magpie":{"words":"covets other peoples' crafts","epithet":"who gathers crafts"},
}
const STRING_TYPES:=["debt","marriage","hunting","dependent","emboldens","feud","secret","sickness","frontier","muster","kin","bluff","messenger","price","none"]
const PLACES:=["north woods","east ridge","river bend","upper valley","south marsh","west hills"]

# --------------------------------------------------------------------------
# Character
# --------------------------------------------------------------------------

static func _day()->int:
	return int(GameState.elapsed_days)

static func _lives()->GDScript:
	return load(LIVES_PATH) as GDScript

static func _rng(key:String)->RandomNumberGenerator:
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d:rival:%s" % [int(GameState.world_seed),key])
	return rng

static func character(civ_id:String)->Dictionary:
	## The live character record of this people's ruler ({} if unknown).
	var leader:=ForeignDiplomacy.leader(civ_id)
	if leader.is_empty(): return {}
	if not valid_character(leader.get("character")):
		leader["character"]=_create(civ_id,leader,1,{})
	return leader.character

static func _create(civ_id:String,leader:Dictionary,generation:int,parent:Dictionary)->Dictionary:
	var day:=_day()
	var rng:=_rng("character:%s:%d" % [civ_id,generation])
	var p:Dictionary=leader.get("personality",{})
	var age:=rng.randi_range(24,50) if generation==1 else rng.randi_range(19,34)
	var tier:=CV.era_tier(CV.era_tags(civ_id))
	var span:=rng.randi_range(48,70)+tier*4
	var dies:=day+maxi(3*365,(span-age)*365+rng.randi_range(0,300))
	var trait_id:=_pick_trait(p,rng)
	if not parent.is_empty() and rng.randf()<0.4: trait_id=String(parent.get("trait",trait_id))
	var model:=_pick_model(civ_id,leader,generation,String(parent.get("model","")))
	var portrait:=posmod(hash("%s:%s" % [civ_id,String(leader.get("name",""))]),4)
	if not parent.is_empty() and portrait==int(parent.get("portrait",-1)): portrait=(portrait+1+rng.randi_range(0,2))%4
	return {"gen":generation,"born":day-age*365,"dies":dies,"trait":trait_id,"model":model,"portrait":portrait,
		"woman":posmod(hash(String(leader.get("name",""))),2)==0,
		"lineage":(parent.get("lineage",[]) as Array).duplicate(true) if not parent.is_empty() else [],
		"grudges":[],"debts":[],"bonds":[],"recalls":[],"later":[],"since":day}

static func _pick_trait(p:Dictionary,rng:RandomNumberGenerator)->String:
	var a:=float(p.get("assertiveness",0.5)); var r:=float(p.get("risk_tolerance",0.5)); var e:=float(p.get("empathy",0.5))
	var o:=float(p.get("openness",0.5)); var d:=float(p.get("discipline",0.5))
	var weights:={"bluffer":0.3+a*0.8+r*0.6-d*0.5,"grudge":0.3+(1.0-e)*0.9+a*0.3,"ledger":0.3+d*0.9,
		"matchmaker":0.15+e*0.6,"hunter":0.4+r*0.4,"magpie":0.3+o*0.9}
	var total:=0.0
	for k in weights: total+=maxf(0.05,float(weights[k]))
	var roll:=rng.randf()*total
	for k in weights:
		roll-=maxf(0.05,float(weights[k]))
		if roll<=0.0: return String(k)
	return "ledger"

static func _pick_model(civ_id:String,leader:Dictionary,generation:int,avoid:String)->String:
	## One literary manner for life: the best fit for this ruler that no other
	## rival ruler holds (and never the parent's).
	var p:Dictionary=leader.get("personality",{})
	var features:={}
	for axis in ["assertiveness","risk_tolerance","empathy","openness","discipline"]: features[axis]=float(p.get(axis,0.5))
	var frng:=_rng("features:%s:%d" % [civ_id,generation])
	for axis in ["pride","suspicion","honesty","courage"]: features[axis]=frng.randf()
	var shape:Dictionary=CV.TEMPERAMENT_FEATURES.get(String(leader.get("temperament","")),{})
	var stance:=String(shape.get("stance","pragmatic"))
	var ranking:=CV.rank_models(features,stance,"ruler:%s:%d" % [civ_id,generation])
	var held:={}
	for other_id in ForeignDiplomacy.leaders:
		if String(other_id)==civ_id: continue
		var other:Variant=(ForeignDiplomacy.leaders[other_id] as Dictionary).get("character")
		if other is Dictionary: held[String((other as Dictionary).get("model",""))]=true
	for candidate in ranking:
		if String(candidate)!=avoid and not held.has(String(candidate)): return String(candidate)
	for candidate in ranking:
		if String(candidate)!=avoid: return String(candidate)
	return "grant"

static func valid_character(value:Variant)->bool:
	if not value is Dictionary: return false
	var c:Dictionary=value
	if not c.has_all(["gen","born","dies","trait","model","portrait","grudges","debts","bonds","lineage"]): return false
	for key in ["gen","born","dies","portrait"]:
		if not Hall._num(c[key]): return false
	if not TRAITS.has(String(c.trait)) or not c.model is String or String(c.model).length()>40: return false
	for key in ["grudges","debts","bonds","lineage","recalls","later"]:
		if not c.get(key,[]) is Array: return false
	if (c.grudges as Array).size()>GRUDGES_MAX or (c.debts as Array).size()>DEBTS_MAX or (c.bonds as Array).size()>BONDS_MAX or (c.lineage as Array).size()>LINEAGE_MAX: return false
	if (c.get("recalls",[]) as Array).size()>RECALLS_MAX or (c.get("later",[]) as Array).size()>LATER_MAX: return false
	return JSON.stringify(c).length()<=12000

static func ruler_name(civ_id:String)->String:
	return String(ForeignDiplomacy.leader(civ_id).get("name","their ruler"))

static func given(civ_id:String)->String:
	return ruler_name(civ_id).get_slice(" ",0)

static func age(civ_id:String)->int:
	var c:=character(civ_id)
	return 0 if c.is_empty() else maxi(16,floori(float(_day()-int(c.born))/365.0))

static func rival_character(civ_id:String)->Dictionary:
	## A read-only view of the ruler as a character, for other systems (aims,
	## the court, the Known World). {} when the god has no contact with them.
	var c:=character(civ_id)
	if c.is_empty(): return {}
	var leader:=ForeignDiplomacy.leader(civ_id)
	var model:Dictionary=CV.model(String(c.model))
	var grudges:Array=[]
	for g in c.grudges:
		if g is Dictionary and not bool(g.get("settled",false)): grudges.append({"day":int(g.day),"text":String(g.text),"weight":float(g.weight),"inherited":bool(g.get("inherited",false))})
	var debts:Array=[]
	for d in c.debts:
		if d is Dictionary and not bool(d.get("settled",false)): debts.append({"owed_by":String(d.owed_by),"resource":String(d.resource),"amount":float(d.amount),"due":int(d.due)})
	var bonds:Array=[]
	for b in c.bonds:
		if b is Dictionary and int(b.get("until",1<<30))>_day(): bonds.append({"kind":String(b.kind),"text":String(b.text),"day":int(b.day)})
	var dread:=0.0
	var lives:=_lives()
	if lives!=null: dread=float(lives.call("rival_dread",civ_id))
	return {"civ_id":civ_id,"civ_name":Hall._civ_name(civ_id),"name":String(leader.get("name","")),"generation":int(c.gen),"age":age(civ_id),
		"temperament":String(leader.get("temperament","")),"trait":String(c.trait),"trait_words":String(TRAITS[String(c.trait)].words),
		"voice_model":String(c.model),"voice_name":String(model.get("name","")),"portrait":int(c.portrait),"trust":float(leader.get("trust",0.0)),
		"grudge_weight":grudge_weight(civ_id),"grudges":grudges,"debts":debts,"bonds":bonds,"lineage":(c.lineage as Array).duplicate(true),
		"dread":dread,"recalled":(c.get("recalls",[]) as Array).size()}

static func portrait_person(civ_id:String)->Dictionary:
	## The ruler as a portrait subject: the same picture for life.
	var c:=character(civ_id)
	var person:={"name":ruler_name(civ_id),"person_id":0}
	if not c.is_empty(): person["early_art_index"]=int(c.portrait)
	return person

static func epithet(civ_id:String)->String:
	var c:=character(civ_id)
	if c.is_empty(): return ruler_name(civ_id)
	return "%s, %s" % [ruler_name(civ_id),String(TRAITS[String(c.trait)].epithet)]

# --------------------------------------------------------------------------
# Memory: grudges, debts, bonds
# --------------------------------------------------------------------------

static func grudge(civ_id:String,clause:String,weight:float,source:String)->void:
	var c:=character(civ_id)
	if c.is_empty(): return
	if String(c.trait)=="grudge": weight*=1.5
	for g in c.grudges:
		if g is Dictionary and String(g.get("source",""))==source and not bool(g.get("settled",false)):
			g["weight"]=clampf(float(g.weight)+weight*0.5,0.0,1.5); return
	(c.grudges as Array).push_front({"day":_day(),"text":clause.substr(0,160),"weight":clampf(weight,0.0,1.5),"source":source.substr(0,80),"settled":false,"recalled":0,"returned":false})
	_trim(c.grudges,GRUDGES_MAX)

static func grudge_weight(civ_id:String)->float:
	var c:=character(civ_id)
	var total:=0.0
	for g in c.get("grudges",[]):
		if g is Dictionary and not bool(g.get("settled",false)): total+=float(g.weight)
	return total

static func _top_grudge(c:Dictionary,min_age:int=0)->Dictionary:
	var best:={}
	for g in c.get("grudges",[]):
		if not g is Dictionary or bool(g.get("settled",false)) or _day()-int(g.day)<min_age: continue
		if best.is_empty() or float(g.weight)>float(best.weight): best=g
	return best

static func settle_grudges(civ_id:String,share:float)->Array:
	## Amends paid: the heaviest grudges are settled first. Returns their clauses.
	var c:=character(civ_id)
	var settled:Array=[]
	var budget:=share
	var list:Array=(c.get("grudges",[]) as Array).duplicate()
	list.sort_custom(func(a:Variant,b:Variant)->bool:return float((a as Dictionary).get("weight",0))>float((b as Dictionary).get("weight",0)))
	for g in list:
		if budget<=0.0: break
		if not g is Dictionary or bool(g.get("settled",false)): continue
		budget-=float(g.weight)
		g["settled"]=true
		settled.append(String(g.text))
	return settled

static func debt(civ_id:String,owed_by:String,resource:String,amount:float,due_in:int,clause:String)->void:
	var c:=character(civ_id)
	if c.is_empty() or amount<=0.0: return
	(c.debts as Array).push_front({"day":_day(),"owed_by":owed_by,"resource":resource,"amount":Hall._nice(amount),"due":_day()+due_in,"text":clause.substr(0,160),"called":false,"settled":false})
	_trim(c.debts,DEBTS_MAX)

static func open_debt(civ_id:String,owed_by:String)->Dictionary:
	for d in character(civ_id).get("debts",[]):
		if d is Dictionary and String(d.owed_by)==owed_by and not bool(d.get("settled",false)): return d
	return {}

static func bond(civ_id:String,kind:String,text:String,until:int=1<<30,data:Dictionary={})->void:
	var c:=character(civ_id)
	if c.is_empty(): return
	(c.bonds as Array).push_front({"kind":kind,"day":_day(),"text":text.substr(0,160),"until":until,"data":data.duplicate(true)})
	_trim(c.bonds,BONDS_MAX)

static func has_bond(civ_id:String,kinds:Array)->Dictionary:
	for b in character(civ_id).get("bonds",[]):
		if b is Dictionary and String(b.kind) in kinds and int(b.get("until",1<<30))>_day(): return b
	return {}

static func break_bond(civ_id:String,kinds:Array)->Dictionary:
	var b:=has_bond(civ_id,kinds)
	if not b.is_empty(): b["until"]=_day()
	return b

static func _trim(list:Array,limit:int)->void:
	while list.size()>limit:
		# Settled memories fade first.
		var drop:=list.size()-1
		for i in range(list.size()-1,-1,-1):
			if list[i] is Dictionary and (bool(list[i].get("settled",false)) or int(list[i].get("until",1<<30))<=_day()): drop=i; break
		list.remove_at(drop)

static func _note_recall(civ_id:String,kind:String,text:String)->void:
	var c:=character(civ_id)
	if c.is_empty(): return
	var list:Array=c.get("recalls",[])
	list.push_front({"day":_day(),"kind":kind,"text":text.substr(0,160)})
	_trim(list,RECALLS_MAX)
	c["recalls"]=list

# --------------------------------------------------------------------------
# Daily: debts fall due, grudges return, kin call, heirs succeed
# --------------------------------------------------------------------------

static func daily(day:int)->void:
	if day%TICK!=0 or WorldSimulation.actor_id!="player": return
	for civ_id in ForeignDiplomacy.leaders.keys():
		var id:=String(civ_id)
		var civ:=ForeignDiplomacy.civilization(id)
		if civ.is_empty() or not bool(civ.get("alive",true)): continue
		var c:=character(id)
		if c.is_empty(): continue
		if day>=int(c.dies): _succeed(id,day); c=character(id)
		var war:=bool((civ.get("player_relation",{}) as Dictionary).get("at_war",false))
		_later(id,c,day)
		_hunting(id,c,day)
		_war_preparation(id,c,day)
		if war: continue
		var name:=String(civ.get("name",id))
		for d in c.debts:
			if not d is Dictionary or bool(d.get("settled",false)) or bool(d.get("called",false)) or String(d.owed_by)!="player" or int(d.due)>day: continue
			d["called"]=true
			Hall._add_occasion({"key":"debt_due:%s:%d" % [id,int(d.day)],"type":"debt_due","civ_id":id,"day":day,"expires":day+240,
				"data":{"text":"%s comes to collect what it is owed" % name,"debt_day":int(d.day)}})
			break
		var g:=_top_grudge(c,GRUDGE_RETURN_MIN)
		if not g.is_empty() and not bool(g.get("returned",false)) and float(g.weight)>=0.35:
			var rng:=_rng("grudge:%s:%d:%d" % [id,int(g.day),day])
			if rng.randf()<clampf(float(g.weight)*0.12,0.02,0.2):
				g["returned"]=true
				Hall._add_occasion({"key":"grudge:%s:%d" % [id,int(g.day)],"type":"grudge","civ_id":id,"day":day,"expires":day+300,
					"data":{"text":"an old grievance between your peoples","grudge_day":int(g.day)}})
		var kin:=has_bond(id,["marriage","ally"])
		if not kin.is_empty():
			for other in (civ.get("relations",{}) as Dictionary):
				if String(other)=="player" or not bool(((civ.relations as Dictionary)[other] as Dictionary).get("at_war",false)): continue
				var enemy_name:=Hall._civ_name(String(other))
				Hall._add_occasion({"key":"kin_call:%s:%s:%d" % [id,String(other),floori(day/365.0)],"type":"kin_call","civ_id":id,"day":day,"expires":day+90,"crisis":true,
					"data":{"text":"%s calls on its kin against %s" % [name,enemy_name],"enemy":String(other),"enemy_name":enemy_name}})
				break

static func _later(civ_id:String,c:Dictionary,day:int)->void:
	## Delayed truths: a bluff paid for comes out, a cough spreads, word travels.
	var list:Array=c.get("later",[])
	for item in list.duplicate():
		if not item is Dictionary or int(item.get("day",0))>day: continue
		list.erase(item)
		match String(item.get("kind","")):
			"bluff_paid":
				var lost:Array=[]
				for person in Hall._officials():
					if float(person.get("pride",0.5))>0.55:
						GovernmentPeopleSystem.adjust_person_relationship(int(person.person_id),0,-0.03,0.01)
						lost.append(String(person.name).get_slice(" ",0))
				_record("%s Had No Spears" % Hall._civ_name(civ_id).substr(0,40),String(item.get("text",""))+(" %s took it hard." % " and ".join(PackedStringArray(lost)) if not lost.is_empty() else ""),civ_id,"notice")
				_note_recall(civ_id,"bluff",String(item.get("text","")))
			"sickness":
				GameState.population_health=clampf(float(GameState.population_health)-0.05,0.05,0.98)
				_record("A Cough From %s" % Hall._civ_name(civ_id).substr(0,40),String(item.get("text","")),civ_id,"notice")

static func _hunting(civ_id:String,c:Dictionary,day:int)->void:
	for b in c.get("bonds",[]):
		if not b is Dictionary or String(b.kind)!="hunting" or int(b.until)<=day: continue
		var data:Dictionary=b.get("data",{})
		if day-int(data.get("last",int(b.day)))<30: continue
		data["last"]=day
		b["data"]=data
		var taken:=Hall._debit_player("Food",float(data.get("monthly",2.0)))
		if taken>0.0: Hall._credit_civ(civ_id,"Food",taken)

static func narrate(clause:String)->String:
	## A clause kept in the foreign people's own voice ("how you refused our
	## gift"), retold by a narrator ("how the god's people refused their gift").
	return (" "+clause+" ").replace(" our "," their ").replace(" us "," them ").replace(" we "," they ").strip_edges()

static func _record(title:String,text:String,civ_id:String,tier:String)->void:
	var lives:=_lives()
	if lives!=null: lives.call("record","rival",title,text,{"civ_id":civ_id},{"tier":tier,"focus":{"civ_id":civ_id}})

static func _succeed(civ_id:String,day:int)->void:
	## The ruler dies; their child rules and carries their reputation.
	var leader:=ForeignDiplomacy.leader(civ_id)
	var old:Dictionary=leader.get("character",{})
	if old.is_empty(): return
	var old_name:=String(leader.get("name",""))
	var generation:=int(old.gen)+1
	var serial:=posmod(hash("%s:heir:%d" % [civ_id,generation]),90000)+20000
	var heir_woman:=serial%2==0
	var used:={old_name:true,"given:"+old_name.get_slice(" ",0):true}
	var identity:Dictionary=EraNames.make(int(GameState.world_seed),serial,heir_woman,civ_id,used)
	var heir_name:=String(identity.get("name",""))
	if heir_name.is_empty() or heir_name==old_name: heir_name=old_name.get_slice(" ",0)+" the Younger"
	var reign:=maxi(1,floori(float(day-int(old.get("since",day)))/365.0))
	var reputation:="remembered kindly" if float(leader.get("trust",0.0))>0.1 else ("remembered as your enemy" if grudge_weight(civ_id)>0.6 else "remembered warily")
	var lineage:Array=(old.get("lineage",[]) as Array).duplicate(true)
	lineage.push_front({"name":old_name,"gen":int(old.gen),"died":day,"reign":reign,"trait":String(old.trait),"reputation":reputation,"woman":bool(old.get("woman",false))})
	while lineage.size()>LINEAGE_MAX: lineage.pop_back()
	leader["name"]=heir_name
	var fresh:=_create(civ_id,leader,generation,old)
	fresh["woman"]=heir_woman
	fresh["lineage"]=lineage
	# The child inherits the parent's reputation: grudges soften but stay, debts
	# and bonds pass down whole.
	for g in old.get("grudges",[]):
		if g is Dictionary and not bool(g.get("settled",false)):
			var copy:Dictionary=(g as Dictionary).duplicate(true)
			copy["weight"]=float(g.weight)*0.75; copy["inherited"]=true; copy["returned"]=false
			(fresh.grudges as Array).append(copy)
	for d in old.get("debts",[]):
		if d is Dictionary and not bool(d.get("settled",false)): (fresh.debts as Array).append((d as Dictionary).duplicate(true))
	for b in old.get("bonds",[]):
		if b is Dictionary and int(b.get("until",1<<30))>day: (fresh.bonds as Array).append((b as Dictionary).duplicate(true))
	_trim(fresh.grudges,GRUDGES_MAX); _trim(fresh.debts,DEBTS_MAX); _trim(fresh.bonds,BONDS_MAX)
	leader["character"]=fresh
	leader["trust"]=clampf(float(leader.get("trust",0.0))*0.6,-1.0,1.0)
	var civ_name:=Hall._civ_name(civ_id)
	var child:=("daughter" if heir_woman else "son")
	var top:=_top_grudge(fresh)
	var carries:=""
	if not top.is_empty(): carries=" %s has not forgotten %s." % [heir_name.get_slice(" ",0),narrate(String(top.text))]
	elif not has_bond(civ_id,["marriage","ally"]).is_empty(): carries=" %s holds to the bond between your peoples." % heir_name.get_slice(" ",0)
	var text:="%s of %s is dead after %d year%s. %s, %s's %s, now speaks for %s.%s" % [old_name,civ_name,reign,"" if reign==1 else "s",heir_name,old_name.get_slice(" ",0),child,civ_name,carries]
	ForeignDiplomacy.remember(civ_id,"%s died; %s rules now, as %s's %s." % [old_name,heir_name,old_name.get_slice(" ",0),child])
	_record("%s of %s Is Dead" % [old_name.substr(0,30),civ_name.substr(0,30)],text,civ_id,"moment")
	_note_recall(civ_id,"heir",text)
	var mix_type:="grudge" if not top.is_empty() and float(top.weight)>=0.3 else "ambient"
	Hall._add_occasion({"key":"heir:%s:%d" % [civ_id,generation],"type":mix_type,"civ_id":civ_id,"day":day,"not_before":day+30,"expires":day+330,
		"data":{"text":"%s's %s now rules %s" % [old_name.get_slice(" ",0),child,civ_name],"heir":true,"grudge_day":int(top.get("day",-1))}})

# --------------------------------------------------------------------------
# Envoys: weights, candidates and dress
# --------------------------------------------------------------------------

static func weight(situation_type:String,civ_id:String)->float:
	## Grudges make hostile business likelier and warm business rarer; kinship
	## the reverse. A people whose envoys were harmed brings no gifts at all,
	## only terrified tribute (when dread rules them) or demands.
	var posture:=envoy_posture(civ_id)
	if posture!="":
		if situation_type=="dread_tribute": return 3.0 if posture=="fearful" else 0.0
		if situation_type in WARM_TYPES: return 0.0
	var g:=grudge_weight(civ_id)
	var kin:=not has_bond(civ_id,["marriage","ally"]).is_empty()
	match situation_type:
		"tribute_demand","test_of_resolve","artifact_return","emboldened_demand":
			return (1.0+g*1.2)*(0.6 if kin else 1.0)
		"gift_goods","accord_offer","trade_offer","protection_pact","artifact_gift","league_invitation":
			return (1.0/(1.0+g*0.8))*(1.3 if kin else 1.0)
	return 1.0

static func occasion_mix(type:String,civ_id:String)->Dictionary:
	return OCCASION_MIX.get(type,{})

static func candidate(situation_type:String,civ_id:String,occasion:Dictionary,rng:RandomNumberGenerator,used:Dictionary,day:int)->Dictionary:
	var civ:=ForeignDiplomacy.civilization(civ_id)
	if civ.is_empty() or bool((civ.get("player_relation",{}) as Dictionary).get("at_war",false)): return {}
	var name:=String(civ.get("name",civ_id))
	var data:Dictionary=occasion.get("data",{}) if occasion.get("data") is Dictionary else {}
	var situation:={"type":situation_type,"headline":String(Hall.SITUATIONS.get(situation_type,{}).get("headline",""))}
	match situation_type:
		"debt_call":
			var d:=open_debt(civ_id,"player")
			if d.is_empty(): return {}
			var have:=Hall.player_stock(String(d.resource))
			var amount:=Hall._nice(minf(float(d.amount),maxf(5.0,have*0.6)))
			if amount<3.0: return {}
			situation.ask="debt:%s:%d" % [String(d.resource),int(d.day)]
			situation.debt_day=int(d.day)
			situation.summary="%s has come to collect %d %s: %s." % [name,roundi(amount),String(d.resource),String(d.text)]
			return {"kind":"request","terms":{"resource":String(d.resource),"amount":amount},"situation":situation}
		"redress_demand":
			var c:=character(civ_id)
			var g:={}
			var wanted:=int(data.get("grudge_day",-1))
			for item in c.get("grudges",[]):
				if item is Dictionary and not bool(item.get("settled",false)) and (wanted<0 or int(item.day)==wanted): g=item; break
			if g.is_empty(): g=_top_grudge(c)
			if g.is_empty(): return {}
			var threat:=Hall._threat_terms(civ,rng,used,0.6+float(g.weight)*0.4)
			if threat.is_empty(): return {}
			situation.ask="redress:%d" % int(g.day)
			situation.grudge_day=int(g.day)
			situation.summary="%s demands %s in redress for %s." % [name,Hall._terms_text(threat),String(g.text)]
			return {"kind":"threat","terms":threat,"situation":situation}
	return {}

static func dress(audience:Dictionary,occasion:Dictionary,day:int)->void:
	## Every envoy speaks for a character, remembers, and carries a string.
	var civ_id:=String(audience.get("civ_id",""))
	var c:=character(civ_id)
	if c.is_empty(): return
	var situation:Dictionary=audience.get("situation",{})
	var rng:=_rng("dress:"+String(audience.id))
	situation["ruler"]=epithet(civ_id)
	var string:=_string_for(audience,situation,c,rng)
	# Memory of past dealings: a grudge, a debt or a bond, named aloud (a kin
	# call already names the bond it rests on).
	var recall:=_recall(civ_id,situation,occasion,day)
	if not recall.is_empty() and not (String(string.get("type",""))=="kin" and String(recall.kind)=="bond"):
		situation["recall"]=recall
		situation["summary"]=(String(situation.get("summary",""))+" "+String(recall.text)).strip_edges()
		_note_recall(civ_id,String(recall.kind),String(recall.text))
	if not string.is_empty():
		situation["string"]=string
		situation["summary"]=(String(situation.get("summary",""))+" "+String(string.text)).strip_edges()
	if String(audience.get("kind",""))=="threat":
		var truth:=_bluff(civ_id,audience,rng)
		audience["hidden"]={"bluff":bool(truth.bluff)}
		if not (truth.tells as Array).is_empty(): situation["tells"]=truth.tells
		if not (truth.signs as Array).is_empty(): situation["signs"]=truth.signs
	audience["situation"]=situation

static func _recall(civ_id:String,situation:Dictionary,occasion:Dictionary,day:int)->Dictionary:
	var c:=character(civ_id)
	var who:=given(civ_id)
	var data:Dictionary=occasion.get("data",{}) if occasion.get("data") is Dictionary else {}
	if bool(data.get("heir",false)) and not (c.lineage as Array).is_empty():
		var parent:Dictionary=c.lineage[0]
		var top:=_top_grudge(c)
		var text:="%s rules now in place of %s, and was raised on %s." % [who,String(parent.name).get_slice(" ",0),"the story of "+String(top.text) if not top.is_empty() else "tales of your people"]
		return {"kind":"heir","text":text,"day":int(parent.get("died",day)),"ruler":ruler_name(civ_id)}
	var recalls:Array=c.get("recalls",[])
	if not recalls.is_empty() and day-int((recalls[0] as Dictionary).get("day",-99999))<60: return {}
	var type:=String(situation.get("type",""))
	if type in ["redress_demand","debt_call"]: return {}
	var g:=_top_grudge(c,60)
	if not g.is_empty() and day-int(g.get("last_recalled",-99999))>=RECALL_GAP:
		g["recalled"]=int(g.get("recalled",0))+1; g["last_recalled"]=day
		var lead:String=["%s has not forgotten %s." % [who,String(g.text)],"%s still speaks of %s." % [who,String(g.text)],"At %s's fire they still tell of %s." % [who,String(g.text)]][posmod(int(g.day)+int(g.recalled),3)]
		if bool(g.get("inherited",false)) and not (c.lineage as Array).is_empty():
			var parent:Dictionary=c.lineage[0]
			lead="%s's %s %s never forgave %s; neither has %s." % [who,"mother" if bool(parent.get("woman",false)) else "father",String(parent.name).get_slice(" ",0),String(g.text),who]
		return {"kind":"grudge","text":lead,"day":int(g.day),"ruler":ruler_name(civ_id)}
	var d:=open_debt(civ_id,"player")
	if not d.is_empty() and day-int(d.day)>=60 and day-int(d.get("last_recalled",-99999))>=RECALL_GAP:
		d["last_recalled"]=day
		return {"kind":"debt","text":"%s reminds you of %s." % [who,String(d.text)],"day":int(d.day),"ruler":ruler_name(civ_id)}
	var b:=has_bond(civ_id,["marriage","ally","dependent"])
	if not b.is_empty() and day-int(b.day)>=90 and day-int(b.get("last_recalled",-99999))>=RECALL_GAP:
		b["last_recalled"]=day
		return {"kind":"bond","text":"%s speaks warmly of %s." % [who,String(b.text)],"day":int(b.day),"ruler":ruler_name(civ_id)}
	var theirs:=open_debt(civ_id,"them")
	if not theirs.is_empty() and day-int(theirs.day)>=120 and day-int(theirs.get("last_recalled",-99999))>=RECALL_GAP:
		theirs["last_recalled"]=day
		return {"kind":"debt_owed","text":"%s has not forgotten %s." % [who,String(theirs.text)],"day":int(theirs.day),"ruler":ruler_name(civ_id)}
	return {}

# --------------------------------------------------------------------------
# Strings
# --------------------------------------------------------------------------

static func _enemy(civ_id:String)->String:
	## A people this one is fighting or quarrelling with (not the player).
	var civ:=ForeignDiplomacy.civilization(civ_id)
	var best:="";var best_score:=0.0
	for other in (civ.get("relations",{}) as Dictionary):
		if String(other) in ["player",civ_id]: continue
		var rel:Dictionary=(civ.relations as Dictionary)[other]
		var score:=(2.0 if bool(rel.get("at_war",false)) else 0.0)+float(rel.get("border_tension",0.0))
		if score>0.45 and score>best_score and Hall._civ_index(String(other))>=0: best=String(other); best_score=score
	return best

static func _third(civ_id:String)->String:
	## Another people the god knows, the boldest first.
	var best:="";var best_score:=-1.0
	for civ in WorldSimulation.world.civilizations:
		var id:=String(civ.get("id",""))
		if id==civ_id or ForeignDiplomacy.civilization(id).is_empty() or bool((civ.get("player_relation",{}) as Dictionary).get("at_war",false)): continue
		var p:=Hall._personality(id)
		var score:=float(p.get("assertiveness",0.5))+float(p.get("risk_tolerance",0.5))*0.5
		if score>best_score: best=id; best_score=score
	return best

static func _craft(civ_id:String)->Dictionary:
	## A practice the player's people know that this people does not.
	var theirs:={}
	for id in CV.known_ids(civ_id): theirs[String(id)]=true
	var founding:={}
	for id in preload("res://scripts/founding_knowledge.gd").PRACTICES: founding[String(id)]=true
	var mine:Array=CV.known_ids("player")
	for index in range(mine.size()-1,-1,-1):
		var id:=String(mine[index])
		if theirs.has(id) or founding.has(id): continue
		var definition:Dictionary=WorldSimulation.discovery.discovery_definition(id) if WorldSimulation.discovery!=null else {}
		var name:=String(definition.get("name",""))
		if name.is_empty() or bool(definition.get("frontier",false)): continue
		return {"id":id,"name":name.to_lower()}
	return {}

static func _string_for(audience:Dictionary,situation:Dictionary,c:Dictionary,rng:RandomNumberGenerator)->Dictionary:
	var civ_id:=String(audience.civ_id)
	var type:=String(situation.get("type",""))
	var name:=Hall._civ_name(civ_id)
	var who:=given(civ_id)
	var terms:Dictionary=audience.get("terms",{})
	var res:=String(terms.get("resource",""))
	var amt:=float(terms.get("amount",0.0))
	var trait_id:=String(c.trait)
	var enemy:=_enemy(civ_id)
	var enemy_name:=Hall._civ_name(enemy) if enemy!="" else ""
	match type:
		"gift_goods","gratitude_gift","artifact_gift":
			var weights:={"debt":1.0+(1.6 if trait_id=="ledger" else 0.0),"marriage":0.7+(1.6 if trait_id=="matchmaker" else 0.0),"hunting":0.6+(1.6 if trait_id=="hunter" else 0.0)}
			if not has_bond(civ_id,["marriage"]).is_empty(): weights.erase("marriage")
			if type=="gratitude_gift": weights["dependent"]=1.0; weights.erase("debt")
			if type=="artifact_gift": weights.erase("debt")
			var kind:=_weighted_key(weights,rng)
			match kind:
				"debt":
					var owed:=Hall._nice(amt*1.5)
					return {"type":"debt","text":"%s counts every gift as a loan: within a year %s will ask %d %s back." % [who,name,roundi(owed),res],"owed":owed,"resource":res}
				"marriage":
					var woman:=rng.randf()<0.5
					var serial:=posmod(hash(String(audience.id)+":inlaw"),90000)+30000
					var identity:Dictionary=EraNames.make(int(GameState.world_seed),serial,woman,civ_id,{ruler_name(civ_id):true})
					var inlaw:=String(identity.get("name","")).get_slice(" ",0)
					if inlaw.is_empty(): inlaw="a child of the house"
					var feud:=" Kin to %s is kin in its quarrel with %s." % [name,enemy_name] if enemy!="" else " Kin to %s is kin in its quarrels."  % name
					return {"type":"marriage","text":"The gift comes with %s, %s's %s, to marry into your people.%s" % [inlaw,who,"daughter" if woman else "son",feud],"inlaw":inlaw,"woman":woman,"enemy":enemy,"enemy_name":enemy_name}
				"hunting":
					var place:=String(PLACES[rng.randi_range(0,PLACES.size()-1)])
					var monthly:=Hall._nice(clampf(amt*(0.06 if res=="Food" else 0.1),2.0,maxf(2.0,Hall._player_population()*0.02)))
					return {"type":"hunting","text":"In return %s's hunters mean to take game in your %s for two winters, about %d Food a month." % [name,place,roundi(monthly)],"place":place,"monthly":monthly}
				"dependent":
					return {"type":"dependent","text":"%s now counts you as kin in hard times, and will look to you when it goes hungry again." % name}
		"dread_tribute":
			var third:=_third(civ_id)
			if third!="": return {"type":"emboldens","text":"Word will travel that %s pays you tribute; %s will take it to mean it is next." % [name,Hall._civ_name(third)],"third":third,"third_name":Hall._civ_name(third)}
			return {"type":"emboldens","text":"%s's young hunters swear among themselves to win this tribute back one day." % name,"third":""}
		"tribute_demand","emboldened_demand","test_of_resolve","redress_demand":
			var third2:=_third(civ_id)
			if third2!="": return {"type":"bluff","text":"If you pay, %s will hear that you can be pressed." % Hall._civ_name(third2),"third":third2,"third_name":Hall._civ_name(third2)}
			return {"type":"bluff","text":"If you pay, %s will know you can be pressed." % name,"third":""}
		"aid_request","debt_call":
			if type=="debt_call": return {"type":"price","text":"Refuse, and %s will call your people faithless at every fire." % who}
			if enemy!="": return {"type":"feud","text":"%s is fighting %s; feeding it counts you in that quarrel." % [name,enemy_name],"enemy":enemy,"enemy_name":enemy_name}
			return {"type":"dependent","text":"Feed them once and %s will count on it: it will call it kinship next hungry winter." % name}
		"news_report","rumor_share","intelligence_share":
			return {"type":"messenger","text":"The messenger lingers by the fire, hoping to go home with a gift."}
		"accord_offer","protection_pact","league_invitation":
			if enemy!="": return {"type":"feud","text":"Bound to %s, you become %s's enemy too." % [name,enemy_name],"enemy":enemy,"enemy_name":enemy_name}
			var craft:=_craft(civ_id)
			if not craft.is_empty() and (type=="accord_offer" or trait_id=="magpie"): return {"type":"secret","text":"Their teachers mean to carry home the secret of %s." % String(craft.name),"craft":String(craft.id),"craft_name":String(craft.name)}
			return {"type":"muster","text":"When %s is threatened, %s will expect your hunters at its side." % [name,who]}
		"trade_offer":
			var craft2:=_craft(civ_id)
			var sick:=float(ForeignDiplomacy.civilization(civ_id).get("health",0.7))<0.55 or rng.randf()<0.35
			if sick or craft2.is_empty(): return {"type":"sickness","text":"A cough is going round %s's camps this season; their traders would bring it with them." % name}
			return {"type":"secret","text":"Their traders mean to learn the secret of %s and carry it home." % String(craft2.name),"craft":String(craft2.id),"craft_name":String(craft2.name)}
		"nonaggression_offer":
			var place2:=String(PLACES[rng.randi_range(0,PLACES.size()-1)])
			if enemy!="": return {"type":"frontier","text":"%s wants its back safe to fight %s, and the %s stays on its side of the line." % [name,enemy_name,place2],"place":place2,"enemy":enemy,"enemy_name":enemy_name}
			return {"type":"frontier","text":"It fixes the frontier where it stands: the %s stays on %s's side." % [place2,name],"place":place2}
		"war_support":
			var kin:=has_bond(civ_id,["marriage","ally"])
			if not kin.is_empty(): return {"type":"kin","text":"%s calls on you as kin: %s." % [who,String(kin.text)]}
	return {}

static func _weighted_key(weights:Dictionary,rng:RandomNumberGenerator)->String:
	var total:=0.0
	for k in weights: total+=float(weights[k])
	var roll:=rng.randf()*total
	for k in weights:
		roll-=float(weights[k])
		if roll<=0.0: return String(k)
	return String(weights.keys()[-1]) if not weights.is_empty() else ""

static func _bluff(civ_id:String,audience:Dictionary,rng:RandomNumberGenerator)->Dictionary:
	## Whether the threat is real, and what the court can see of it.
	var civ:=ForeignDiplomacy.civilization(civ_id)
	var p:=Hall._personality(civ_id)
	var c:=character(civ_id)
	var size_ratio:=clampf(float(civ.get("population",100))/Hall._player_population(),0.3,1.8)
	var hungry:=Hall._hungry(civ)
	var enemy:=_enemy(civ_id)
	var dread:=0.0
	var lives:=_lives()
	if lives!=null: dread=float(lives.call("rival_dread",civ_id))
	var chance:=0.22+(1.0-minf(size_ratio,1.4))*0.35+(0.3 if String(c.get("trait",""))=="bluffer" else 0.0)+dread*0.25+(0.15 if hungry else 0.0)+(0.12 if enemy!="" else 0.0)-float(p.get("discipline",0.5))*0.15
	var bluff:=rng.randf()<clampf(chance,0.05,0.85)
	var name:=String(civ.get("name",civ_id))
	var tells:Array=[]
	var signs:Array=[]
	if bluff:
		var pool:Array=["%s's herald names no day and no place, and will not meet your eye." % name]
		if size_ratio<0.9: pool.append("The herald boasts of more spears than %s has grown hunters." % name)
		if hungry: pool.append("%s's escort is thin and hungry; no band marches on empty bellies." % name)
		if enemy!="": pool.append("%s is already quarrelling with %s; it cannot fight on two sides." % [name,Hall._civ_name(enemy)])
		if String(c.get("trait",""))=="bluffer": pool.append("%s is known for threats that never arrive." % given(civ_id))
		if rng.randf()<0.85:
			var first:=rng.randi_range(0,pool.size()-1)
			tells.append(pool[first])
			pool.remove_at(first)
			if not pool.is_empty() and rng.randf()<0.5: tells.append(pool[rng.randi_range(0,pool.size()-1)])
	else:
		var strong:Array=["%s's escort is painted for war, and the herald names a day." % name,"%s's herald counts the paths to your fires aloud, as if already walking them." % name]
		if size_ratio>=1.0: strong.append("%s has more grown hunters than your people, and the herald knows it." % name)
		if rng.randf()<0.7: signs.append(strong[rng.randi_range(0,strong.size()-1)])
		if rng.randf()<0.15: tells.append("%s's herald names no day and no place, and will not meet your eye." % name)
	return {"bluff":bluff,"tells":tells,"signs":signs}

# --------------------------------------------------------------------------
# Options: costs, objections and support
# --------------------------------------------------------------------------

static func annotate_options(audience:Dictionary,options:Array)->void:
	if String(audience.get("origin",""))!="foreign": return
	var situation:Dictionary=audience.get("situation",{}) if audience.get("situation") is Dictionary else {}
	var voices:=_voices(audience)
	for option in options:
		if not option is Dictionary: continue
		var id:=String(option.get("id",""))
		if id.begins_with("hear:"): continue
		var cost:=_cost(audience,situation,id)
		if not cost.is_empty():
			option["cost"]=cost
			option["sub"]=(cost+" "+String(option.get("sub",""))).strip_edges()
		for side in ["objection","support"]:
			var v:Dictionary=voices.get(side,{})
			if not v.is_empty() and String(v.option)==id: option[side]="%s (%s): “%s”" % [String(v.name),String(v.office),String(v.text)]

static func _cost(audience:Dictionary,situation:Dictionary,option_id:String)->String:
	var civ_id:=String(audience.civ_id)
	var name:=String(audience.get("civ_name",Hall._civ_name(civ_id)))
	var who:=given(civ_id)
	var string:Dictionary=situation.get("string",{}) if situation.get("string") is Dictionary else {}
	var stype:=String(string.get("type",""))
	var terms:Dictionary=audience.get("terms",{})
	var terms_text:=Hall._terms_text(terms)
	match "%s:%s" % [String(audience.kind),option_id]:
		"gift:accept","gift:accept_return","proposal:accept":
			if String(situation.get("type",""))=="artifact_gift" or String(audience.kind)=="gift" or stype in ["feud","secret","sickness","muster","frontier"]:
				match stype:
					"debt": return "String: you will owe %d %s within a year%s." % [roundi(float(string.owed)*(0.7 if option_id=="accept_return" else 1.0)),String(string.resource)," (less your courtesy gift)" if option_id=="accept_return" else ""]
					"marriage": return "String: %s marries into your people; %s's quarrels become yours." % [String(string.inlaw),name]
					"hunting": return "String: their hunters take about %d Food a month for two winters." % roundi(float(string.monthly))
					"dependent": return "String: %s will look to you next hungry winter." % name
					"emboldens": return ("String: %s will fear it is next." % String(string.third_name)) if String(string.get("third",""))!="" else "String: their young hunters swear to win it back."
					"feud": return "String: %s counts you its enemy." % String(string.enemy_name)
					"secret": return "String: they carry home the secret of %s." % String(string.craft_name)
					"sickness": return "String: a cough may come home with their traders."
					"muster": return "String: %s will expect your hunters in its fights." % name
					"frontier": return "String: the %s stays on their side." % String(string.place)
		"gift:refuse": return "Cost: %s takes it as an insult; %s will remember." % [who,name]
		"gift:decline": return "Cost: no gift, and %s is a little stiff about it." % who
		"proposal:decline":
			if String(situation.get("type",""))=="war_support": return ""
			return "Cost: %s looks elsewhere for friends." % name
		"proposal:rebuff","proposal:refuse": return "Cost: %s will remember the rebuff." % who
		"request:grant":
			if String(situation.get("type",""))=="debt_call": return "Cost: %s leaves your stores; the debt is settled." % terms_text
			return "Cost: %s leaves your stores.%s" % [terms_text,(" "+("%s counts you in its quarrel with %s." % [name,String(string.enemy_name)] if stype=="feud" else "%s will count on you again." % name)) if stype in ["feud","dependent"] else ""]
		"request:grant_half": return "Cost: %s leaves your stores%s." % [Hall._terms_text({"resource":terms.get("resource","Food"),"amount":Hall._nice(float(terms.get("amount",0))*0.5)}),"; half the debt stays owed" if String(situation.get("type",""))=="debt_call" else ""]
		"request:refuse":
			if String(situation.get("type",""))=="debt_call": return "Cost: %s will call you faithless; a grudge." % who
			return "Cost: %s will remember who let them go hungry." % name
		"threat:pay":
			return "Cost: lose %s; %s" % [terms_text,("%s hears you can be pressed." % String(string.third_name)) if String(string.get("third",""))!="" else "they may come back for more."]
		"threat:defy": return "Risk: if they mean it, the frontier heats; if not, %s loses face." % who
		"threat:counter": return "Risk: raises the stakes whether or not they mean it."
		"news:thank": return "Cost: a thin welcome; their next news may go to others."
		"news:reward": return "Cost: a gift from your stores."
		"proposal:stand": return "Cost: %s counts you among its enemies." % String(situation.get("enemy_name","their enemy"))
		"proposal:abstain":
			if stype=="kin": return "Cost: breaks the bond; %s will call it betrayal." % who
			return "Cost: %s will remember you stood aside." % name
		"proposal:counsel_peace": return "Cost: neither side will thank you."
		"proposal:sell","proposal:trade","proposal:return": return "Cost: the treasure leaves your people for good."
		"proposal:compensate": return "Cost: goods from your stores."
		"proposal:defy": return "Cost: %s will remember the refusal." % who
		"proposal:restraint": return "Cost: no recruiting among them for two years."
	if option_id=="accept" and String(audience.kind)=="proposal":
		match String(situation.get("type","")):
			"scholar_offer","research_sale","license_offer": return "Cost: %s %s from your stores." % [str(roundi(float(situation.get("payment_amount",0.0)))),String(situation.get("payment","goods"))]
			"peace_feeler": return "Cost: the present line holds; the dead stay unavenged."
	return ""

const OFFICE_FOR:={
	"debt":["Quartermaster","Steward"],"marriage":["Marshal","Envoy","Steward"],"hunting":["ChiefScout","Steward"],"dependent":["Steward","Quartermaster"],
	"emboldens":["Envoy","Marshal","ChiefScout"],"feud":["Marshal","ChiefScout"],"secret":["Scholar","Quartermaster","Steward"],"sickness":["Scholar","Steward"],
	"muster":["Marshal","Steward"],"frontier":["Marshal","ChiefScout"],"kin":["Envoy","Steward"],"bluff":["Marshal","ChiefScout"],"messenger":["Envoy","ChiefScout"],"price":["Steward","Quartermaster"],
}
const SUPPORT_OFFICE_FOR:={
	"debt":["Steward"],"marriage":["Envoy","Steward"],"hunting":["Steward"],"dependent":["Envoy","Steward"],"emboldens":["Marshal"],"feud":["Envoy","Steward"],
	"secret":["Envoy","Steward"],"sickness":["Quartermaster","Steward"],"muster":["Envoy"],"frontier":["Steward","Envoy"],"kin":["Marshal"],"bluff":["Steward","Quartermaster"],
	"messenger":["Steward"],"price":["Envoy","Steward"],
}

static func _voices(audience:Dictionary)->Dictionary:
	## Who objects to which answer, and who speaks for another, with why.
	var situation:Dictionary=audience.get("situation",{}) if audience.get("situation") is Dictionary else {}
	var string:Dictionary=situation.get("string",{}) if situation.get("string") is Dictionary else {}
	var stype:=String(string.get("type",""))
	if stype.is_empty(): return {}
	var civ_id:=String(audience.civ_id)
	var name:=String(audience.get("civ_name",Hall._civ_name(civ_id)))
	var terms:Dictionary=audience.get("terms",{})
	var res:=String(terms.get("resource","Food"))
	var stock:=floori(Hall.player_stock(res)) if not res.is_empty() else 0
	var c:=Hall.conditions()
	var lean:=float(c.food_days)<35.0
	var tells:Array=situation.get("tells",[]) if situation.get("tells") is Array else []
	var signs:Array=situation.get("signs",[]) if situation.get("signs") is Array else []
	var against:="";var against_why:="";var favour:="";var favour_why:=""
	match stype:
		"debt":
			if lean and res=="Food": against="refuse"; against_why="We are hungry now. Take it; we can pay it back after the harvest."
			else: against="accept"; against_why="They will want this paid back. We have %d %s of our own." % [stock,res]
			favour="accept_return" if against!="accept_return" else ""; favour_why="Send something back, and the debt shrinks."
		"marriage":
			if String(string.get("enemy",""))!="":
				against="accept"; against_why="Wed their child and we wed their feud with %s." % String(string.enemy_name)
				favour="decline"; favour_why="Send the child home with honour. Keep out of their quarrel."
			else:
				against="decline"; against_why="Turn their child away and we shame their whole house."
				favour="accept"; favour_why="Take the match. With their child living here, they will think twice before raiding us."
		"hunting":
			var value:=float(terms.get("amount",0))*(1.0 if res=="Food" else 1.5)
			if value>=float(string.monthly)*24.0 and not lean:
				against="decline"; against_why="Send all that back? The game they take we would never reach."
				favour="accept"; favour_why="The %s has more game than we can take ourselves." % String(string.place)
			else:
				against="accept"; against_why="Once their hunters learn the paths in the %s, they will keep coming back." % String(string.place)
				favour="decline"; favour_why="Thank them and keep our woods. We will need that game."
		"dependent":
			if lean: against="accept" if String(audience.kind)=="gift" else "grant"; against_why="We are short ourselves. Whatever we send them comes out of our own children's meals."
			else: against="refuse"; against_why="Let them starve and they will come for ours."
			favour="accept" if String(audience.kind)=="gift" else "grant"; favour_why="If they live on our food, they will not raid us."
		"emboldens":
			if String(string.get("third",""))!="":
				against="accept"; against_why="Take their tribute and %s counts its spears against us." % String(string.third_name)
				favour="decline"; favour_why="Send it back. If we take tribute, the other neighbours will wonder if they are next."
			else:
				against="refuse"; against_why="Throw it back at them and they will fear us less."
				favour="accept"; favour_why="They fear us. Let them pay for it."
		"feud":
			var ally_size:=float(ForeignDiplomacy.civilization(civ_id).get("population",100))
			var enemy_index:=Hall._civ_index(String(string.get("enemy","")))
			var enemy_size:=float(WorldSimulation.world.civilizations[enemy_index].get("population",100)) if enemy_index>=0 else 100.0
			var yes:="accept" if String(audience.kind)=="proposal" else "grant"
			against=yes; against_why="Their quarrel with %s is not ours. Not yet." % String(string.enemy_name)
			if ally_size>=enemy_size: favour=yes; favour_why="They are the stronger side. Help them win and they will owe us."
			else: favour="decline" if String(audience.kind)=="proposal" else "grant_half"; favour_why="Keep friends with both. %s is the stronger." % String(string.enemy_name)
		"secret":
			var warm:=float((ForeignDiplomacy.civilization(civ_id).get("player_relation",{}) as Dictionary).get("opinion",0.0))>0.2
			if warm and String(character(civ_id).get("trait",""))!="magpie":
				against="decline"; against_why="Turn their teachers away and we learn nothing of theirs either."
				favour="accept"; favour_why="Let them learn. They will show us their own crafts in return."
			else:
				against="accept"; against_why="The secret of %s is ours. They will copy it within a season." % String(string.craft_name)
				favour="decline"; favour_why="Not this year. Let them earn it."
		"sickness":
			against="accept"; against_why="I have seen that cough empty a camp. Keep their traders out this season."
			favour="decline"; favour_why="Wait a season. The trade can wait; our old people and small children might not survive that cough."
		"muster":
			var bigger:=float(ForeignDiplomacy.civilization(civ_id).get("population",100))>=Hall._player_population()*0.8
			if bigger:
				against="decline"; against_why="They are nearly our size. Lend them a few hunters now and their spears are ours when we need them."
				favour="accept"; favour_why="If we refuse, those same spears could be pointed at us next."
			else:
				against="accept"; against_why="Their fights will cost our young hunters, and they are too few to help ours."
				favour="decline"; favour_why="Stay friends without the oath."
		"frontier":
			var tense:=float((ForeignDiplomacy.civilization(civ_id).get("player_relation",{}) as Dictionary).get("border_tension",0.0))>0.35
			if tense:
				against="rebuff"; against_why="Our hunters and theirs nearly came to blows on that border. Take the peace while they offer it."
				favour="accept"; favour_why="With the border settled, our people can hunt and build without watching their backs."
			else:
				against="accept"; against_why="The %s is ours by right. Do not sign it away." % String(string.place)
				favour="decline"; favour_why="The border is quiet already. We need no line drawn."
		"kin":
			against="stand"; against_why="Kin or not, our hunters would be dying in their fight, not ours."
			favour="stand"; favour_why="We married into them and swore to stand with them. If we stay home, no one will trust our oath again."
		"bluff":
			if not tells.is_empty() and signs.is_empty():
				against="pay"; against_why=_tell_reason(String(tells[0]))
				favour="defy"; favour_why="Call it. %s has nothing behind the words." % given(civ_id)
			elif not signs.is_empty():
				against="defy"; against_why=_sign_reason(String(signs[0]))
				favour="defy"; favour_why="If we pay now, they will be back every winter asking for more."
			else:
				against="pay"; against_why="If we give in now, they will come back next year with the same threat."
				favour="pay"; favour_why="We cannot tell if they mean it. Paying costs us food; a raid would cost us people."
		"messenger":
			if String(situation.get("type",""))=="news_report":
				favour="thank"; favour_why="Thanks is enough for news this thin."
				if lean: against="reward"; against_why="We have nothing to spare for tale-bearers."
			else:
				against="thank"; against_why="Send them home empty and the next word goes to %s's rivals." % name
		"price":
			against="refuse"; against_why="We took their gift. Pay what we owe, or no one trusts our word."
			favour="refuse" if lean else ""; favour_why="We cannot spare it. Not this season."
	var used:={}
	var out:={}
	var speaker_id:=int((audience.get("speaker",{}) as Dictionary).get("person_id",0))
	if against!="":
		var person:=_official_for(OFFICE_FOR.get(stype,[]),used,speaker_id,String(audience.id)+":against")
		if not person.is_empty():
			used[int(person.person_id)]=true
			out["objection"]={"option":against,"pid":int(person.person_id),"name":String(person.name).get_slice(" ",0),"office":String(person.get("office_title",person.get("office_key",""))),"text":against_why}
	if favour!="" and (favour!=against or stype in ["feud","kin","bluff","dependent"]):
		var person2:=_official_for(SUPPORT_OFFICE_FOR.get(stype,[]),used,speaker_id,String(audience.id)+":for")
		if not person2.is_empty():
			out["support"]={"option":favour,"pid":int(person2.person_id),"name":String(person2.name).get_slice(" ",0),"office":String(person2.get("office_title",person2.get("office_key",""))),"text":favour_why}
	return out

static func _sign_reason(sign:String)->String:
	var low:=sign.to_lower()
	if "painted" in low: return "They mean it. Their hunters are already painted for war."
	if "paths" in low: return "They mean it. They have walked those paths already."
	if "more grown hunters" in low: return "They mean it, and they have the hunters to do it."
	return "They mean it. I would not call this one."

static func _tell_reason(tell:String)->String:
	var low:=tell.to_lower()
	if "hungry" in low: return "Their escort is half-starved. They could not march three days on that."
	if "more spears" in low: return "They have not the hunters to make good on that."
	if "two sides" in low: return "They are fighting elsewhere. They cannot come here too."
	if "never arrive" in low: return "They have threatened before and never come."
	return "The herald will not meet my eye. I do not think they will come."

static func _official_for(offices:Array,used:Dictionary,speaker_id:int,salt:String)->Dictionary:
	## From those seated at this audience (the court bench).
	var officials:=Hall.court(salt.get_slice(":",0))
	for office in offices:
		for person in officials:
			if String(person.get("office_key",""))==String(office) and not used.has(int(person.person_id)) and int(person.person_id)!=speaker_id: return person
	var pool:Array=[]
	for person in officials:
		if not used.has(int(person.person_id)) and int(person.person_id)!=speaker_id: pool.append(person)
	if pool.is_empty(): return {}
	return pool[posmod(hash(salt),pool.size())]

# --------------------------------------------------------------------------
# Answers: the string takes hold, grudges and debts are written down
# --------------------------------------------------------------------------

static func after_answer(audience:Dictionary,option_id:String,result:Dictionary)->Dictionary:
	if String(audience.get("origin",""))!="foreign": return result
	var civ_id:=String(audience.civ_id)
	if character(civ_id).is_empty(): return result
	var situation:Dictionary=audience.get("situation",{}) if audience.get("situation") is Dictionary else {}
	var string:Dictionary=situation.get("string",{}) if situation.get("string") is Dictionary else {}
	var stype:=String(string.get("type",""))
	var type:=String(situation.get("type",""))
	var name:=String(audience.get("civ_name",Hall._civ_name(civ_id)))
	var who:=given(civ_id)
	var terms:Dictionary=audience.get("terms",{})
	var terms_text:=Hall._terms_text(terms)
	var notes:PackedStringArray=PackedStringArray()
	var key:=String(audience.id)
	var accepted:=option_id in ["accept","accept_return"]
	match stype:
		"debt":
			if accepted:
				var owed:=float(string.owed)*(0.7 if option_id=="accept_return" else 1.0)
				debt(civ_id,"player",String(string.resource),owed,rng_days(key,300,420),"the %d %s you owe for our gift" % [roundi(Hall._nice(owed)),String(string.resource)])
				notes.append("You owe %s %d %s within the year." % [name,roundi(Hall._nice(owed)),String(string.resource)])
		"marriage":
			if accepted:
				bond(civ_id,"marriage","the marriage of %s into your people" % String(string.inlaw),1<<30,{"inlaw":String(string.inlaw)})
				Hall._shift_relation(civ_id,0.05,-0.03)
				notes.append("%s came with the gift and married into your people; you are kin to %s now." % [String(string.inlaw),name])
				if String(string.get("enemy",""))!="":
					Hall._shift_relation(String(string.enemy),-0.08,0.06)
					grudge(String(string.enemy),"how you married into %s's house" % name,0.3,"kin:"+civ_id)
					notes.append("%s took note." % String(string.enemy_name))
		"hunting":
			if accepted:
				bond(civ_id,"hunting","their hunters' right to your %s" % String(string.place),_day()+730,{"monthly":float(string.monthly),"last":_day()})
				notes.append("%s's hunters will take about %d Food a month from your %s for two winters." % [name,roundi(float(string.monthly)),String(string.place)])
		"dependent":
			if accepted or option_id in ["grant","grant_half"]:
				bond(civ_id,"dependent","the food you sent in their hunger",_day()+1095)
				if option_id in ["grant","grant_half"]:
					debt(civ_id,"them",String(terms.get("resource","Food")),float(terms.get("amount",0))*(0.5 if option_id=="grant_half" else 1.0)*0.8,720,"the %s you sent when we were hungry" % terms_text)
				notes.append("%s will count on you next hungry winter." % name)
		"emboldens":
			if accepted:
				var third:=String(string.get("third",""))
				if third!="":
					Hall._shift_relation(third,-0.08,0.1)
					grudge(third,"how you took tribute from %s; we could be next" % name,0.35,"tribute_from:"+civ_id)
					notes.append("%s has heard of it, and now fears it is next." % String(string.third_name))
				else:
					grudge(civ_id,"the tribute you took from us",0.45,"tribute:"+key)
					notes.append("%s's young hunters swear to win it back." % name)
		"feud":
			if accepted or option_id=="grant":
				Hall._shift_relation(String(string.enemy),-0.1,0.08)
				grudge(String(string.enemy),"how you sided with %s against us" % name,0.4,"sided:"+civ_id)
				if accepted: bond(civ_id,"ally","your bond with %s against %s" % [name,String(string.enemy_name)],_day()+1460)
				notes.append("%s counts you among its enemies now." % String(string.enemy_name))
		"secret":
			if accepted:
				_share_craft(civ_id,String(string.craft),String(string.craft_name))
				notes.append("Their people carry home the secret of %s; they must still learn it." % String(string.craft_name))
		"sickness":
			if accepted:
				(character(civ_id).later as Array).append({"day":_day()+rng_days(key,20,50),"kind":"sickness","text":"The cough came home with %s's traders. The old and the small children suffered most." % name})
				notes.append("Their traders are coughing.")
		"muster":
			if accepted:
				bond(civ_id,"ally","your promise to stand with %s" % name,_day()+1460)
				notes.append("%s will call on your hunters when it is threatened." % name)
		"frontier":
			if accepted:
				var marshal:=Hall._relevant_official(["Marshal","ChiefScout"])
				if not marshal.is_empty(): GovernmentPeopleSystem.adjust_person_relationship(int(marshal.person_id),0,-0.03,0.01)
				bond(civ_id,"frontier","the line that leaves the %s to them" % String(string.place),_day()+1825)
				if String(string.get("enemy",""))!="": Hall._shift_relation(String(string.enemy),-0.04,0.04)
				notes.append("The %s is theirs now." % String(string.place))
		"kin":
			if option_id=="abstain":
				var broken:=break_bond(civ_id,["marriage","ally"])
				grudge(civ_id,"how you left your kin to fight %s alone" % String(situation.get("enemy_name","their enemy")),0.8,"betrayal:"+key)
				Hall._shift_relation(civ_id,-0.12,0.08)
				notes.append("%s calls it betrayal%s." % [who,": "+String(broken.text)+" is broken" if not broken.is_empty() else ""])
		"price":
			if option_id in ["grant","grant_half"]:
				var d:=_debt_by_day(civ_id,int(situation.get("debt_day",-1)))
				if not d.is_empty():
					if option_id=="grant": d["settled"]=true
					else: d["amount"]=Hall._nice(float(d.amount)*0.5); d["called"]=false; d["due"]=_day()+365
			elif option_id=="refuse":
				var d2:=_debt_by_day(civ_id,int(situation.get("debt_day",-1)))
				if not d2.is_empty(): d2["settled"]=true
				grudge(civ_id,"the debt you would not pay",0.7,"default:"+key)
				Hall._leader_trust(civ_id,-0.1)
				notes.append("%s will call your people faithless at every fire." % who)
		"bluff":
			if option_id=="pay":
				var third2:=String(string.get("third",""))
				if third2!="":
					Hall._add_occasion({"key":"pressed:%s:%s" % [third2,key],"type":"relation_cool","civ_id":third2,"day":_day(),"not_before":_day()+60,"expires":_day()+300,
						"data":{"text":"word that you paid %s tribute" % name}})
					ForeignDiplomacy.remember(third2,"The ruler paid %s tribute. They can be pressed." % name)
					notes.append("Word of it goes to %s." % String(string.third_name))
				if bool((audience.get("hidden",{}) as Dictionary).get("bluff",false)):
					(character(civ_id).later as Array).append({"day":_day()+rng_days(key,60,150),"kind":"bluff_paid","text":"Travellers laugh that %s never had the spears it threatened you with; the %s you paid bought nothing." % [name,terms_text]})
				if type=="redress_demand": _settle_grudge_by_day(civ_id,int(situation.get("grudge_day",-1)))
	# Refusals and rebuffs are remembered by every temper.
	match "%s:%s" % [String(audience.kind),option_id]:
		"gift:refuse": grudge(civ_id,"how you refused our gift of %s" % terms_text,0.4,"refused_gift:"+key)
		"request:refuse":
			if type=="aid_request": grudge(civ_id,"how you refused us %s when we were hungry" % terms_text,0.5 if Hall._hungry(ForeignDiplomacy.civilization(civ_id)) else 0.3,"refused_aid:"+key)
		"threat:defy","threat:counter":
			if not bool((audience.get("hidden",{}) as Dictionary).get("bluff",false)): grudge(civ_id,"the %s you would not pay" % terms_text,0.4,"defied:"+key)
		"proposal:rebuff": grudge(civ_id,"how you rebuffed our envoy",0.3,"rebuff:"+key)
		"proposal:refuse":
			if type=="artifact_return": grudge(civ_id,"the treasure you would not give back",0.5,"artifact:"+key)
		"proposal:defy": grudge(civ_id,"how you rejected our protest",0.3,"protest:"+key)
		"news:thank": Hall._shift_relation(civ_id,-0.01,0.0)
	# A gift they sent in thanks, or a debt of theirs answered, settles what they owed.
	if type=="gratitude_gift" and accepted:
		var theirs:=open_debt(civ_id,"them")
		if not theirs.is_empty(): theirs["settled"]=true
	if not notes.is_empty(): result["outcome"]=(String(result.get("outcome",""))+" "+" ".join(notes)).strip_edges()
	return result

static func rng_days(key:String,lo:int,hi:int)->int:
	return _rng("days:"+key).randi_range(lo,hi)

static func _debt_by_day(civ_id:String,day:int)->Dictionary:
	for d in character(civ_id).get("debts",[]):
		if d is Dictionary and int(d.day)==day and not bool(d.get("settled",false)): return d
	return open_debt(civ_id,"player")

static func _settle_grudge_by_day(civ_id:String,day:int)->void:
	for g in character(civ_id).get("grudges",[]):
		if g is Dictionary and int(g.day)==day: g["settled"]=true

static func _share_craft(civ_id:String,craft_id:String,craft_name:String)->void:
	## The practice travels as an account their people must still study.
	var target:=SOCIETY.owner_state(civ_id)
	if target==null or craft_id.is_empty(): return
	var key:="player:%s" % craft_id
	var collections:Dictionary=target.society_exchange.get("collections",{})
	if collections.has(key) or collections.size()>=int(SOCIETY.COLLECTION_LIMIT): return
	var definition:Dictionary=WorldSimulation.discovery.discovery_definition(craft_id)
	collections[key]={"id":key,"kind":"knowledge","name":"A trader's account of "+craft_name,"source_id":"player","source_name":String(GameState.settlement_name),"position":{},"observed_day":_day(),"returned_day":_day(),"discovery_id":craft_id,"study":0.0,"work":90.0,"signals":(definition.get("signals",[]) as Array).duplicate(),"acquisition":"Carried home by traders under the compact"}

static func bluff_called(audience:Dictionary,option_id:String)->Dictionary:
	## The threat was empty: they back down, lose face, and remember it.
	var civ_id:=String(audience.civ_id)
	var name:=String(audience.get("civ_name",Hall._civ_name(civ_id)))
	var terms_text:=Hall._terms_text(audience.get("terms",{}))
	Hall._shift_relation(civ_id,-0.02,-0.08)
	Hall._leader_trust(civ_id,-0.03)
	grudge(civ_id,"how you called our bluff before your court",0.3,"bluff:"+String(audience.id))
	var proud:Array=[]
	for person in Hall.court(String(audience.id)):
		if float(person.get("pride",0.5))>0.5:
			GovernmentPeopleSystem.adjust_person_relationship(int(person.person_id),0,0.03,-0.01)
			proud.append(String(person.name).get_slice(" ",0))
	var outcome:="You %s. It was a bluff: %s never came for the %s, and the frontier quieted. %s will not forget the humiliation." % ["refused to pay" if option_id=="defy" else "answered threat with threat",name,terms_text,given(civ_id)]
	if not proud.is_empty(): outcome+=" %s stood a little taller." % " and ".join(PackedStringArray(proud))
	ForeignDiplomacy.remember(civ_id,"Our herald's threat was called, and nothing came of it. We lost face.")
	return {"outcome":outcome,"reaction":"offended"}

# --------------------------------------------------------------------------
# Voice: what the envoy and the court say about all this (offline)
# --------------------------------------------------------------------------

static func open_lines(audience:Dictionary)->Dictionary:
	## Envoy lines (the recall, then the string in the ruler's trait) and the
	## court's objection/support, as ready text for the offline voice.
	var situation:Dictionary=audience.get("situation",{}) if audience.get("situation") is Dictionary else {}
	var civ_id:=String(audience.get("civ_id",""))
	var out:={"envoy":[],"court":[]}
	var recall:Dictionary=situation.get("recall",{}) if situation.get("recall") is Dictionary else {}
	if not recall.is_empty(): (out.envoy as Array).append([String(recall.text)])
	var string:Dictionary=situation.get("string",{}) if situation.get("string") is Dictionary else {}
	if not string.is_empty():
		var said:=_envoy_string_lines(audience,string)
		if not said.is_empty(): (out.envoy as Array).append(said)
	# What the court can see of a threat, and the messenger's hopes, are staged.
	var staged:Array=[]
	for key in ["signs","tells"]:
		for t in situation.get(key,[]): staged.append("[%s]" % String(t))
	if String(string.get("type",""))=="messenger": staged.append("[The messenger lingers by the fire, hoping to go home with a gift.]")
	# After envoys were harmed here, the next one shows it.
	var wrong:=_top_envoy_wrong(character(civ_id))
	if not wrong.is_empty():
		if String(situation.get("type",""))=="dread_tribute":
			staged.push_front("[The envoy will not lift their eyes from the floor; their hands shake as the tribute is set down, and their bearers stay close to the door.]")
			(out.envoy as Array).push_front(["We know %s. Take this, and let us go home whole." % String(wrong.get("text","what befell the last of us")),"Everyone at home knows %s. We bring this so it does not happen to us." % String(wrong.get("text","what befell the last of us"))])
		elif String(situation.get("type","")) in ["redress_demand","tribute_demand","test_of_resolve"]:
			staged.push_front("[The envoy comes in with a guard of spearmen and keeps a hand near their knife; nobody from %s kneels.]" % Hall._civ_name(civ_id))
			(out.envoy as Array).push_front(["You know why I stand here armed: %s." % String(wrong.get("text","")),"%s has not forgotten %s, and neither will you." % [given(civ_id),String(wrong.get("text",""))]])
	out["narrator"]=staged
	var voices:=_voices(audience)
	for side in ["objection","support"]:
		var v:Dictionary=voices.get(side,{})
		if v.is_empty(): continue
		var label:=_option_words(audience,String(v.option))
		var why:=String(v.text)
		var lines:Array=["%s" % why]
		if side=="objection": lines.append_array(["Do not %s. %s" % [label,why],"I speak against it. %s" % why])
		else: lines.append_array(["I say %s. %s" % [label,why],"%s" % why])
		(out.court as Array).append({"pid":int(v.pid),"lines":lines,"side":side})
	return out

static func _envoy_string_lines(audience:Dictionary,string:Dictionary)->Array:
	## The envoy names the string in their own people's voice, coloured by the
	## ruler's signature trait. Several phrasings: nothing is said twice.
	var civ_id:=String(audience.get("civ_id",""))
	var c:=character(civ_id)
	var who:=given(civ_id)
	var trait_id:=String(c.get("trait","ledger"))
	var terms:Dictionary=audience.get("terms",{})
	var res:=String(terms.get("resource",""))
	var lines:Array=[]
	match String(string.get("type","")):
		"debt":
			var owed:=roundi(float(string.owed))
			lines=["With us, a gift is a loan. %s will want %d %s back within the year." % [who,owed,res],
				"%s counts every gift, and this one is counted: %d %s, back within the year." % [who,owed,res],
				"Take it as a loan, not a gift. We will come for %d %s before the year is out." % [owed,res]]
		"marriage":
			var kin:="daughter" if bool(string.get("woman",false)) else "son"
			var quarrel:=(" Marry into us and you are in our quarrel with %s too." % String(string.enemy_name)) if String(string.get("enemy",""))!="" else " Marry into us and our quarrels are yours too."
			lines=["%s, %s's %s, comes with it, to marry among you.%s" % [String(string.inlaw),who,kin,quarrel],
				"The gift is a bride-gift. %s's %s %s will marry into your people.%s" % [who,kin,String(string.inlaw),quarrel],
				"%s binds peoples with marriages. %s comes with the gift.%s" % [who,String(string.inlaw),quarrel]]
		"hunting":
			lines=["In return our hunters will take game in your %s for two winters." % String(string.place),
				"%s asks only this: our hunters in your %s for two winters." % [who,String(string.place)],
				"Our hunters will follow the game into your %s for two winters. That is the bargain." % String(string.place)]
		"dependent":
			if String(audience.get("kind",""))=="request":
				lines=["Feed us once and we will count on you next hungry winter. That is kinship, as we reckon it.","Help us now and we will look to you again. That is what neighbours are for."]
			else:
				lines=["We will remember your help, and look to you when we go hungry again.","From now on we count you as kin in hard times. We will come to you again."]
		"emboldens":
			if String(string.get("third",""))!="": lines=["%s will hear that we pay you. Let them fear what we fear." % String(string.third_name),"Everyone will know we paid. %s most of all." % String(string.third_name)]
			else: lines=["Our young hunters grumble at this. They say they will win it back one day.","Take it. But our young men carry this home like a stone."]
		"feud":
			var enemy:=String(string.enemy_name)
			if String(audience.get("kind",""))=="request": lines=["We are fighting %s. Feed us, and they will count you with us." % enemy,"%s will know where our food came from." % enemy]
			else: lines=["Bind yourselves to us, and %s counts you its enemy too. We will not pretend otherwise." % enemy,"Our quarrel with %s comes with our friendship. %s will not hide it." % [enemy,who]]
		"secret":
			lines=["Our teachers would like to see how you work %s. Only to learn, of course." % String(string.craft_name),"%s is curious about your %s. Our people learn quickly." % [who,String(string.craft_name)]]
			if trait_id=="magpie": lines.push_front("%s gathers crafts the way others gather berries. Yours, %s, most of all." % [who,String(string.craft_name)])
		"sickness":
			lines=["Our traders are coughing this season. It will pass, they say.","A cough is going round our camps. Nothing, surely."]
		"muster":
			lines=["When we are threatened, %s will look for your hunters beside ours." % who,"If we are attacked, %s will send for your hunters and expect them to come." % who]
		"frontier":
			lines=["The line stays where it is. The %s is ours." % String(string.place),"%s wants the %s settled as ours, for good." % [who,String(string.place)]]
		"kin":
			lines=["%s calls on you as kin. Kin do not stand aside." % who,"We are kin now. %s expects kin to come." % who]
		"price":
			lines=["Pay, and our peoples are square. Refuse, and %s will say at every fire that your word is wind." % who,"%s remembers the gift. Now remember the debt." % who]
	if trait_id=="bluffer" and String(audience.get("kind",""))=="threat": lines.append("%s has never yet been refused. Think on that." % who)
	return lines

static func _option_words(audience:Dictionary,option_id:String)->String:
	match option_id:
		"accept","accept_return": return "take it"
		"refuse": return "send them away"
		"pay": return "pay"
		"defy": return "call it"
		"grant": return "give it"
		"thank": return "send them off empty-handed"
		"stand": return "stand with them"
		"decline": return "send it home with thanks"
		"rebuff": return "send them away"
		"reward": return "reward them"
		"grant_half": return "give half"
	return "do it"

# --------------------------------------------------------------------------
# Live voice context
# --------------------------------------------------------------------------

static func prompt_view(civ_id:String)->Dictionary:
	var view:=rival_character(civ_id)
	if view.is_empty(): return {}
	var grudges:Array=[]
	for g in view.grudges: grudges.append(String(g.text))
	var debts:Array=[]
	for d in view.debts: debts.append("%s owes %d %s" % ["the ruler's people" if String(d.owed_by)=="player" else "this people",roundi(float(d.amount)),String(d.resource)])
	var bonds:Array=[]
	for b in view.bonds: bonds.append(String(b.text))
	var parents:Array=[]
	for l in view.lineage: parents.append("%s (%s)" % [String(l.name),String(l.get("reputation",""))])
	return {"signature_trait":String(view.trait_words),"literary_manner":String(view.voice_name),"age":int(view.age),"generation":int(view.generation),
		"grudges":grudges.slice(0,4),"debts":debts.slice(0,3),"bonds":bonds.slice(0,3),"predecessors":parents.slice(0,3)}

# --------------------------------------------------------------------------
# Offline talk with a foreign ruler: state-driven briefs
# --------------------------------------------------------------------------

static func talk_choices(civ_id:String)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	var c:=character(civ_id)
	if c.is_empty(): return out
	var who:=given(civ_id)
	var name:=Hall._civ_name(civ_id)
	out.append({"id":"ask_intent","label":"Ask what %s wants of us" % who,"reaction":"unchanged"})
	var g:=_top_grudge(c)
	if not g.is_empty():
		var amends:=_amends_terms(float(g.weight))
		var short:=Hall._short(String(amends.resource),float(amends.amount))
		out.append({"id":"amends","label":"Send amends for %s" % String(g.text),"reaction":"conciliate","cost":amends,"enabled":short=="","reason":short})
	var mine:=open_debt(civ_id,"player")
	if not mine.is_empty():
		var short2:=Hall._short(String(mine.resource),float(mine.amount))
		out.append({"id":"pay_debt","label":"Send the %d %s we owe" % [roundi(float(mine.amount)),String(mine.resource)],"reaction":"conciliate","cost":{"resource":String(mine.resource),"amount":float(mine.amount)},"enabled":short2=="","reason":short2})
	var theirs:=open_debt(civ_id,"them")
	if not theirs.is_empty(): out.append({"id":"call_debt","label":"Remind %s of what %s owes" % [who,name],"reaction":"warn"})
	if has_bond(civ_id,["marriage"]).is_empty(): out.append({"id":"marriage","label":"Propose a marriage between our houses","reaction":"conciliate"})
	if not (c.lineage as Array).is_empty(): out.append({"id":"heir","label":"Ask if %s holds to %s's word" % [who,String((c.lineage[0] as Dictionary).name).get_slice(" ",0)],"reaction":"unchanged"})
	out.append({"id":"honour","label":"Honour %s's house" % who,"reaction":"conciliate"})
	out.append({"id":"warn","label":"Warn %s off our borders" % who,"reaction":"warn"})
	return out

static func _amends_terms(weight:float)->Dictionary:
	var best:="";var best_stock:=0.0
	for resource in Hall.RESOURCES:
		var stock:=Hall.player_stock(String(resource))
		if stock>best_stock: best_stock=stock; best=String(resource)
	if best=="": best="Food"
	return {"resource":best,"amount":Hall._nice(clampf(Hall._player_population()*(0.1 if best=="Food" else 0.04)*(0.6+weight),3.0,60.0))}

static func talk_depart(civ_id:String,choice:Dictionary)->Dictionary:
	## Goods carried by the envoy leave now. Returns {} or {"error":...}.
	var cost:Dictionary=choice.get("cost",{}) if choice.get("cost") is Dictionary else {}
	if cost.is_empty(): return {}
	var short:=Hall._short(String(cost.resource),float(cost.amount))
	if short!="": return {"error":short}
	var sent:=Hall._debit_player(String(cost.resource),float(cost.amount))
	Hall._credit_civ(civ_id,String(cost.resource),sent)
	return {}

static func talk_reply(civ_id:String,choice_id:String)->Dictionary:
	## The ruler's answer, in their own manner, from what they remember. Also
	## applies the lasting effects of the choice (amends settle grudges, a paid
	## debt is settled, a marriage is agreed or refused).
	var c:=character(civ_id)
	var leader:=ForeignDiplomacy.leader(civ_id)
	var persona:=CV.for_foreign_leader(civ_id)
	var rng:=_rng("talk:%s:%s:%d" % [civ_id,choice_id,_day()])
	var who:=given(civ_id)
	var name:=Hall._civ_name(civ_id)
	var trust:=float(leader.get("trust",0.0))
	var opinion:=float((ForeignDiplomacy.civilization(civ_id).get("player_relation",{}) as Dictionary).get("opinion",0.0))
	var warm:=trust+opinion>0.1
	var manner:=_manner_line(persona,"reply",rng)
	var fact:=""
	var envoy:=""
	var reaction:="unchanged"
	var g:=_top_grudge(c)
	match choice_id:
		"ask_intent":
			envoy="I asked %s plainly what %s wants from your people." % [who,name]
			var goals:Array=leader.get("goals",[])
			var want:=String((goals[0] as Dictionary).get("title","")).to_lower() if not goals.is_empty() and goals[0] is Dictionary else "be left in peace"
			fact="%s wants to %s." % [name,want]
			if not g.is_empty(): fact+=" And I have not forgotten %s." % String(g.text)
			elif not has_bond(civ_id,["marriage","ally"]).is_empty(): fact+=" We are kin; I expect kin's help."
		"amends":
			envoy="I laid your gift at %s's feet and named the old wrong for what it was." % who
			var settled:=settle_grudges(civ_id,0.6)
			Hall._shift_relation(civ_id,0.06,-0.05); Hall._leader_trust(civ_id,0.08)
			reaction="conciliate"
			fact=("Then let the old wrong be buried with this gift: %s." % String(settled[0])) if not settled.is_empty() else "Then there is nothing left between us to bury."
			manner=_manner_line(persona,"farewell_warm",rng)
		"pay_debt":
			var d:=open_debt(civ_id,"player")
			if not d.is_empty(): d["settled"]=true
			envoy="I carried what you owed to %s and counted it out before witnesses." % who
			Hall._shift_relation(civ_id,0.05,-0.03); Hall._leader_trust(civ_id,0.1)
			reaction="conciliate"
			fact="Paid in full. Your word is good at my fire."
			manner=_manner_line(persona,"farewell_warm",rng)
		"call_debt":
			var theirs:=open_debt(civ_id,"them")
			envoy="I reminded %s, politely, of %s." % [who,String(theirs.get("text","an old kindness"))]
			if warm and not theirs.is_empty():
				var sent:=EXCHANGE.take(civ_id,String(theirs.resource),float(theirs.amount)*0.6)
				if sent>0.0: EXCHANGE.receive("player",String(theirs.resource),sent)
				theirs["settled"]=true
				fact="We remember. %d %s goes back with your envoy." % [roundi(sent),String(theirs.resource)] if sent>0.0 else "We remember, and we have nothing to send. Not yet."
			else:
				grudge(civ_id,"how you dunned us for a kindness",0.2,"dunned:%d" % _day())
				fact="You count your kindnesses like a trader. I will remember that."
				reaction="warn"
		"marriage":
			envoy="I proposed that our houses be joined by a marriage."
			if warm or String(c.trait)=="matchmaker":
				var serial:=posmod(hash("%s:match:%d" % [civ_id,_day()]),90000)+40000
				var woman:=serial%2==0
				var identity:Dictionary=EraNames.make(int(GameState.world_seed),serial,woman,civ_id,{ruler_name(civ_id):true})
				var inlaw:=String(identity.get("name","")).get_slice(" ",0)
				bond(civ_id,"marriage","the marriage of %s into your people" % inlaw,1<<30,{"inlaw":inlaw})
				Hall._shift_relation(civ_id,0.06,-0.04)
				reaction="conciliate"
				fact="Then %s, my %s, will come to your fires. Kin now, in fair seasons and foul." % [inlaw,"daughter" if woman else "son"]
			else:
				fact="Marry into a house I do not yet trust? Not this year."
		"heir":
			var parent:Dictionary=c.lineage[0] if not (c.lineage as Array).is_empty() else {}
			envoy="I asked whether %s holds to what %s promised." % [who,String(parent.get("name","their parent")).get_slice(" ",0)]
			fact=("My %s's word is mine. So is my %s's memory." % ["mother" if bool(c.get("woman",false)) else "father","mother" if bool(c.get("woman",false)) else "father"]) if not g.is_empty() else "My parent's friends are my friends, until they prove otherwise."
		"honour":
			envoy="I spoke of %s's house with all the honour you asked for." % who
			reaction="conciliate"
			Hall._shift_relation(civ_id,0.02,-0.02)
			fact="Fine words. %s" % ("They cost you nothing, and I know it." if not g.is_empty() else "I will repay them in kind.")
		"warn":
			envoy="I told %s your people will meet any trespass at the border." % who
			reaction="warn"
			fact="Tell your ruler I heard. %s" % ("I will not forget it." if String(c.trait)=="grudge" else "We will see who blinks.")
			manner=_manner_line(persona,"farewell_cold",rng)
	_note_recall(civ_id,"talk",fact)
	var reply:=(manner+" "+fact).strip_edges() if not manner.is_empty() else fact
	return {"envoy_words":envoy,"reply":reply.substr(0,1700),"accord":"","tone":"equals","generous":false,"reaction":reaction}

static func _manner_line(persona:Dictionary,bank:String,rng:RandomNumberGenerator)->String:
	var lines:Array=[]
	var tags:Array=persona.get("era_tags",[])
	for line in CV.model_bank(persona,bank):
		if not "{" in String(line) and CV.permits(String(line),tags) and CV.imitation_ok(String(line)): lines.append(String(line))
	if lines.is_empty(): return ""
	return String(lines[rng.randi_range(0,lines.size()-1)])

# --------------------------------------------------------------------------
# Wronged envoys: a people whose envoys were slain, maimed, flogged, shamed or
# seized does not keep sending gifts. What they do instead depends on the
# ruler's trait, whether dread or hatred rules them, and relative strength.
# --------------------------------------------------------------------------

## Grudge sources that record a wrong done to an envoy (see court_commands.gd).
const ENVOY_WRONGS:=["slain_envoy","maimed_envoy","beaten_envoy","insulted_envoy","seized_envoy"]
## Business a wronged people will not bring: gifts and friendship.
const WARM_TYPES:=["gift_goods","gratitude_gift","artifact_gift","accord_offer","protection_pact","league_invitation","trade_offer","scholar_offer","research_sale","license_offer","nonaggression_offer","artifact_purchase","rumor_share","intelligence_share"]
## Occasions a posture never overrides.
const POSTURE_EXEMPT:=["first_contact","debt_due","peace_possible"]
const POSTURE_MIX:={
	"redress":{"redress_demand":1.4,"tribute_demand":0.6,"test_of_resolve":0.4},
	"war":{"test_of_resolve":1.0,"redress_demand":0.9,"tribute_demand":0.4},
	"fearful":{"dread_tribute":1.6,"redress_demand":0.15},
}
const WAR_PREP_MIN:=150
const WAR_PREP_MAX:=420

static func envoy_wrongs(civ_id:String)->Dictionary:
	## Unsettled wrongs done to this people's envoys (inherited ones included).
	var out:={"slain":0,"maimed":0,"beaten":0,"insulted":0,"seized":0,"count":0,"weight":0.0,"last_day":-1}
	for g in character(civ_id).get("grudges",[]):
		if not g is Dictionary or bool(g.get("settled",false)): continue
		var kind:=String(g.get("source","")).get_slice(":",0)
		if not kind in ENVOY_WRONGS: continue
		var key:=kind.trim_suffix("_envoy")
		out[key]=int(out[key])+1
		out.count=int(out.count)+1
		out.weight=float(out.weight)+float(g.get("weight",0.0))
		out.last_day=maxi(int(out.last_day),int(g.get("day",-1)))
	return out

static func envoy_posture(civ_id:String)->String:
	## "" (no wrong remembered), "redress" (threats and demands), "halt" (no more
	## envoys), "fearful" (terrified tribute) or "war" (preparing for war).
	var wrongs:=envoy_wrongs(civ_id)
	if float(wrongs.weight)<0.25: return ""
	var civ:=ForeignDiplomacy.civilization(civ_id)
	if civ.is_empty(): return ""
	var relation:Dictionary=civ.get("player_relation",{}) if civ.get("player_relation") is Dictionary else {}
	if bool(relation.get("at_war",false)): return "war"
	var c:=character(civ_id)
	var trait_id:=String(c.get("trait",""))
	var p:=Hall._personality(civ_id)
	var bold:=(float(p.get("assertiveness",0.5))+float(p.get("risk_tolerance",0.5)))*0.5
	var size_ratio:=clampf(float(civ.get("population",100.0))/maxf(1.0,Hall._player_population()),0.2,3.0)
	var hatred:=clampf(float(wrongs.weight)*0.6,0.0,1.2)+maxf(0.0,-float(relation.get("opinion",0.0)))*0.3
	var lives:=Hall._lives()
	var dread:=float(lives.call("rival_dread",civ_id)) if lives!=null else 0.0
	var blood:=int(wrongs.slain)+int(wrongs.maimed)
	# Dread outweighs hatred in a weaker, less bold people: they pay, shaking.
	var fear:=dread*(1.4-bold)
	if fear>hatred*0.35+0.15 and size_ratio<1.1 and bold<0.62 and trait_id!="grudge": return "fearful"
	var war_score:=hatred*(0.55+bold)*clampf(size_ratio,0.5,1.6)+(0.35 if trait_id in ["grudge","bluffer"] else 0.0)+0.25*maxi(0,blood-1)
	if blood>=2 and war_score>=1.5: return "war"
	if blood>=1 and dread>=0.35 and size_ratio<0.9 and bold<0.5: return "halt"
	if fear>hatred*0.45+0.1 and size_ratio<1.2 and trait_id!="grudge": return "fearful"
	return "redress"

static func envoy_mix(civ_id:String,occasion_type:String)->Dictionary:
	## The business a wronged people brings instead of what the occasion invites.
	if occasion_type in POSTURE_EXEMPT: return {}
	return (POSTURE_MIX.get(envoy_posture(civ_id),{}) as Dictionary).duplicate()

static func withholds_envoys(civ_id:String,occasion:Dictionary,rng:RandomNumberGenerator)->bool:
	## A people that has lost envoys at your court may stop sending them.
	if String(occasion.get("type","")) in POSTURE_EXEMPT: return false
	var posture:=envoy_posture(civ_id)
	var halt:=posture=="halt" or (posture=="war" and rng.randf()<0.5)
	if not halt: return false
	var c:=character(civ_id)
	if not c.is_empty():
		c["envoys_withheld"]=int(c.get("envoys_withheld",0))+1
		if _day()-int(c.get("withheld_noted",-99999))>=365:
			c["withheld_noted"]=_day()
			var name:=Hall._civ_name(civ_id)
			_record("%s Sends No Envoys" % name.substr(0,40),"%s will not send another envoy into the hall where %s." % [name,narrate(String(_top_envoy_wrong(c).get("text","their envoys were harmed")))],civ_id,"notice")
			ForeignDiplomacy.remember(civ_id,"We will send no more envoys to a ruler who harms them.")
	return true

static func _top_envoy_wrong(c:Dictionary)->Dictionary:
	var best:={}
	for g in c.get("grudges",[]):
		if not g is Dictionary or bool(g.get("settled",false)) or not String(g.get("source","")).get_slice(":",0) in ENVOY_WRONGS: continue
		if best.is_empty() or float(g.weight)>float(best.weight): best=g
	return best

static func _war_preparation(civ_id:String,c:Dictionary,day:int)->void:
	## Wronged and bold enough: they sharpen spears, the border hardens, and in
	## time their ruler opens a war that their own generals run.
	if envoy_posture(civ_id)!="war":
		if c.has("war_prep_day") and envoy_posture(civ_id)!="war": c.erase("war_prep_day")
		return
	var civ:=ForeignDiplomacy.civilization(civ_id)
	var relation:Dictionary=civ.get("player_relation",{}) if civ.get("player_relation") is Dictionary else {}
	if bool(relation.get("at_war",false)): return
	var name:=Hall._civ_name(civ_id)
	if not c.has("war_prep_day"):
		c["war_prep_day"]=day
		c["war_due_day"]=day+rng_days("war:%s:%d" % [civ_id,day],WAR_PREP_MIN,WAR_PREP_MAX)
		_record("%s Sharpens Its Spears" % name.substr(0,40),"%s is gathering fighters on the border. %s has not forgotten %s." % [name,given(civ_id),narrate(String(_top_envoy_wrong(c).get("text","what was done to their envoys")))],civ_id,"moment")
		ForeignDiplomacy.remember(civ_id,"We make ready for war over what was done to our envoys.")
	Hall._shift_relation(civ_id,-0.01,0.02)
	if day>=int(c.get("war_due_day",day+1)) and CivilizationSystem.has_method("rival_opens_war"):
		var clause:=narrate(String(_top_envoy_wrong(c).get("text","what was done to their envoys")))
		var opened:Dictionary=CivilizationSystem.rival_opens_war(civ_id,"Vengeance for %s" % clause)
		if bool(opened.get("ok",false)):
			c.erase("war_prep_day"); c.erase("war_due_day")
			_record("%s Goes to War" % name.substr(0,40),"%s opens war to avenge %s. Their generals take the field." % [name,clause],civ_id,"moment")

extends RefCounted
## SICKNESS & DISASTERS: one plain line for every sickness and hardship the
## god's own people meet, with the engine's own numbers.
##
## Written by crisis_system.gd (fevers and fluxes, the strangers' sickness,
## hungry seasons, dry spells, the dim sun, floods, fires, the worn land) and
## consequence_engine.gd (a spell of widespread sickness: its warnings and the
## deaths of sickness while health is failing). Each line says when and where,
## what it was, how many fell ill and died (the dead by name), what was lost,
## what was done about it and who decided. It is updated as the trouble runs
## its course, so one trouble is one line.
##
## These are told here and nowhere else: no card, no Chronicle entry, no
## council decision, no line over the map. Only an EXTREME one also comes to
## the god, once (the thresholds below). The court still hears of the staged
## ones through the event ledger (crisis_system.gd _ledger_line), so officials
## can be asked about them. Nothing here changes what happens: who falls sick,
## who dies and what is lost are decided before a line is written.
##
## State: ForeignDiplomacy.audiences["hardships"], saved with the court and
## validated by audience_hall.gd; older saves start with an empty log. Newest
## first, at most LOG_MAX lines.
## Read by hud/content/dock_detail_health.gd ("Sickness & disasters").
## A crisis's line is keyed "<crisis id>@<start day>" and carries "crisis";
## a spell of sickness is "illness:<start day>".

const KEY:="hardships"
const VERSION:=1
## The newest lines kept (and saved). About one trouble a year in the early
## centuries: two hundred years of them.
const LOG_MAX:=200
const TEXT_MAX:=200
const NAME_MAX:=60
const NAMES_KEPT:=3

## EXTREME: the only sicknesses and disasters that still interrupt the god
## (one Chronicle moment card; the Chronicle also keeps how it ended). Measured
## with the engine's own numbers for that trouble (crisis_system.gd is_extreme
## for a crisis, illness_deaths() below for a spell of widespread sickness):
##   - the dead: one in twenty (EXTREME_DEAD_SHARE) of the people it struck, by
##     the engine's planned death share when it begins (the crisis's `m`,
##     before anyone answers) or by the dead counted so far. That is the
##     catalog's pestilence tail (crisis_system SEVERE sickness: a few times a
##     century at most in the historical bands). A typical fever plans well
##     under one death in a hundred, a hungry season one to three.
##   - the losses: half (EXTREME_LOSS_SHARE) or more of the food in the stores,
##     or of the people's shelter, gone at once. A fire takes at most about a
##     fifth of either and a flood about a third, so neither is extreme unless
##     it also kills one in twenty.
## On three forty-year runs of a band of about 150, none of the 130 troubles
## logged was extreme. A virgin-soil strangers' sickness usually is, and about
## a third of new pestilences. Everything else is written only here.
const EXTREME_DEAD_SHARE:=0.05
const EXTREME_LOSS_SHARE:=0.5

## A spell of widespread sickness ends when neither its warning nor a death
## of sickness has come for this long; the next one is a new line.
const SPELL_GAP_DAYS:=120

## The mark each kind of trouble shows (resource_icons.gd moment glyphs).
const GLYPHS:={"sickness":"sickness","stranger":"stranger","hunger":"hunger","drought":"drought","cold":"cold","flood":"flood","fire":"fire","thinning":"thinning","illness":"sickness"}
## What each was, in a word or two.
const WHAT:={"sickness":"Sickness","stranger":"Strangers' sickness","hunger":"Hunger","drought":"Dry spell","cold":"Dim sun","flood":"Flood","fire":"Fire","thinning":"Worn land","illness":"Sickness"}
## What was done, by the crisis answer it carried out (crisis_system.gd _apply).
const COURSE:={
	"ration":"portions were cut","hunt":"the strongest went far to hunt","ask":"food was asked of the neighbours","raid":"food was taken from the neighbours' pits",
	"seed":"the seed was eaten","pots":"the pots were kept boiling","herd":"animals were killed from the herd","speak":"the god went among them",
	"apart":"the sick were kept apart","tend":"everyone tended the sick","herbs":"the plant-knowers were sent for","water":"the water was boiled and the drinking place moved",
	"burn":"the sick huts were burned","rite":"the people gathered to hear their god","close":"the path to the strangers was closed","healers":"healers came from the strangers",
	"carry":"water was carried from far off","hardy":"seed that needs little water was sown","rain":"the god promised rain","gather":"everyone gathered while there was food",
	"high_ground":"the hearths moved up the slope","save_stores":"the stores were carried out first","boats":"the stores and the old went out by boat",
	"mounds":"the homes were raised on mounds","wait":"they waited for the water to go down","rebuild":"the homes were rebuilt as they were",
	"earth":"the homes were rebuilt in earth","blame":"someone was punished for it","range":"the gatherers walked farther","rest":"the near ground was rested",
	"burn_brush":"the old brush was burned","press":"nothing was changed",
	"children_apart":"the children were kept from the sick","mothers":"the mothers nursed their own","far_camp":"the well moved to a clean camp upstream",
	"send_away":"some families were sent away","roots":"everyone dug roots and bark","river_camp":"the sleeping places moved to the river",
	"send_hunters":"hunters followed the game","hold":"","stay":""}
## The same words where a fire, not a sickness, was met that way.
const FIRE_COURSE:={"apart":"the homes were rebuilt apart","rite":"the ashes were given to the god"}
const RITES:={"pyre":"a great fire was lit for the dead","cairn":"a cairn was raised over the dead","rest_no_rite":"the dead were buried without a rite"}


static func active()->bool:
	## Only the god's own people keep this log; every other people's crises
	## run silently (crisis_unattended.gd).
	return Engine.get_main_loop()!=null and WorldSimulation.state==GameState


static func state()->Dictionary:
	# The court block is replaced when a new world begins or a save loads.
	ForeignDiplomacy.ensure()
	var raw:Variant=ForeignDiplomacy.audiences.get(KEY,{})
	var s:Dictionary=raw if raw is Dictionary else {}
	if not s.is_empty() and int(s.get("world_seed",GameState.world_seed))!=int(GameState.world_seed): s.clear()
	if int(s.get("version",0))!=VERSION or not s.get("entries") is Array:
		if not s.get("entries") is Array: s["entries"]=[]
		s["version"]=VERSION
		s["world_seed"]=int(GameState.world_seed)
		s["revision"]=int(s.get("revision",0)) if _num(s.get("revision")) else 0
	ForeignDiplomacy.audiences[KEY]=s
	return s


static func entries()->Array:
	## Newest first.
	return state().entries if Engine.get_main_loop()!=null else []


static func revision()->int:
	return int(state().get("revision",0))


static func count_in_year(year:int)->int:
	## How many troubles in this log ran during 0-based year `year`. The year's
	## telling reads this, and only this, so it never calls a year with one in
	## it free of sickness, hunger or fire (chronicle_annals.gd compose,
	## hud/chronicle_year_model.gd). Nothing more of them is told there.
	var first:=year*365
	var last:=first+364
	var today:=int(WorldSimulation.state.elapsed_days) if Engine.get_main_loop()!=null else last
	var n:=0
	for e in entries():
		var line:Dictionary=e
		var start:=int(line.get("start",0))
		var stop:=int(line.get("end",line.get("last",today)))
		if start<=last and stop>=first: n+=1
	return n


static func of_crisis(crisis_id:String)->Dictionary:
	## The newest line of crisis `crisis_id`, or {}.
	for e in entries():
		if String((e as Dictionary).get("crisis",""))==crisis_id: return e
	return {}


static func note(id:String,fields:Dictionary)->Dictionary:
	## Writes, or brings up to date, the line of one trouble (`id`: its crisis
	## id, or its spell of sickness). Returns the line.
	if not active() or id=="": return {}
	var s:=state()
	var list:Array=s.entries
	var entry:Dictionary={}
	for e in list:
		if e is Dictionary and String((e as Dictionary).get("id",""))==id: entry=e; break
	if entry.is_empty():
		entry={"id":id.substr(0,NAME_MAX)}
		list.push_front(entry)
		while list.size()>LOG_MAX: list.pop_back()
	for key in fields:
		var value:Variant=_clean(fields[key])
		if value!=null: entry[String(key)]=value
	s.revision=int(s.get("revision",0))+1
	return entry


static func _clean(value:Variant)->Variant:
	if value is bool or value is int: return value
	if value is float: return value if is_finite(value) else 0.0
	if value is String or value is StringName: return String(value).substr(0,TEXT_MAX)
	if value is Array:
		var out:Array=[]
		for item in value:
			if out.size()>=NAMES_KEPT: break
			out.append(String(item).substr(0,NAME_MAX))
		return out
	return null


static func _num(value:Variant)->bool:
	return (value is int or value is float) and is_finite(float(value))


static func valid_state(data:Variant)->bool:
	## Optional save block; absent in older saves.
	if not data is Dictionary: return false
	var d:Dictionary=data
	if d.has("entries"):
		if not d.entries is Array or (d.entries as Array).size()>LOG_MAX: return false
		for e in d.entries:
			if not e is Dictionary or not (e as Dictionary).get("id","") is String: return false
	for key in ["version","world_seed","revision"]:
		if d.has(key) and not _num(d[key]): return false
	return JSON.stringify(d).length()<=LOG_MAX*1200


# --------------------------------------------------------------------------
# A spell of widespread sickness (consequence_engine.gd)
# --------------------------------------------------------------------------

static func _spell(day:int)->Dictionary:
	## The spell of widespread sickness going on now, or {}.
	for e in entries():
		if String((e as Dictionary).get("type",""))!="illness": continue
		if day-int((e as Dictionary).get("last",-100000))<=SPELL_GAP_DAYS: return e
		return {}
	return {}


static func _place()->String:
	return String(WorldSimulation.state.settlement_name).strip_edges()


static func illness_warning(event:Dictionary,health:float)->void:
	## consequence_engine's warning that health is failing: written in the
	## log and marked so the council, the Chronicle and the map pass it by.
	if event.is_empty(): return
	event["hardship"]=true
	if not active(): return
	var day:=int(event.get("day",int(WorldSimulation.state.elapsed_days)))
	var spell:=_spell(day)
	var id:=String(spell.get("id","illness:%d" % day))
	var low:=minf(health,float(spell.get("health_low",health)))
	note(id,{"type":"illness","name":"Widespread sickness","start":int(spell.get("start",day)),"last":day,"health_low":low,
		"pop":int(spell.get("pop",WorldSimulation.state.population_total)),"place":String(spell.get("place",_place()))})


static func illness_deaths(record:Dictionary,count:int)->void:
	## Deaths of sickness while health is failing (consequence_engine.gd; the
	## ordinary ones are tallied by the season). Marked like the warning;
	## counted in the spell's line. When the spell has killed one in twenty of
	## the people it began with, it is extreme: told once in the Chronicle.
	if record.is_empty() or count<=0: return
	record["hardship"]=true
	if not active(): return
	var day:=int(WorldSimulation.state.elapsed_days)
	var spell:=_spell(day)
	var people_then:=int(spell.get("pop",WorldSimulation.state.population_total+count))
	var dead:=int(spell.get("dead",0))+count
	var id:=String(spell.get("id","illness:%d" % day))
	var health:=float(WorldSimulation.state.population_health)
	var line:=note(id,{"type":"illness","name":"Widespread sickness","start":int(spell.get("start",day)),"last":day,"dead":dead,"pop":people_then,
		"health_low":minf(health,float(spell.get("health_low",health))),"place":String(spell.get("place",_place()))})
	if bool(line.get("extreme",false)) or float(dead)<float(maxi(1,people_then))*EXTREME_DEAD_SHARE: return
	line["extreme"]=true
	var steward:Variant=WorldSimulation.state.leadership_positions.get("Steward")
	var pid:=int((steward as Dictionary).get("person_id",0)) if steward is Dictionary else 0
	var moment:={"key":"hardship:%s" % id,"title":"The Sickness Will Not Lift",
		"text":"%d have died of sickness since %s, one in %d of the people. Health stands at %d in 100." % [dead,_since(int(line.get("start",day))),maxi(1,roundi(float(people_then)/float(dead))),roundi(health*100.0)],
		"tier":"moment","priority":true,"kind":"sickness","domain":"health"}
	if pid>0: moment["action"]={"kind":"court","focus":{"person_id":pid}}
	preload("res://scripts/chronicle.gd").record(moment)


static func _since(day:int)->String:
	return preload("res://scripts/chronicle.gd").date_label(day).replace(" · "," in ").to_lower()


# --------------------------------------------------------------------------
# Words: one line of the log, plain and with its numbers
# --------------------------------------------------------------------------

static func glyph(e:Dictionary)->String:
	return String(GLYPHS.get(String(e.get("type","")),"sickness"))




static var _year_words:RegEx

static func title(e:Dictionary)->String:
	## "The Summer Flux", "The Burning", "Widespread sickness".
	var name:=String(e.get("name","")).strip_edges()
	if name=="": name=String(WHAT.get(String(e.get("type","")),"Hard times"))
	if _year_words==null: _year_words=RegEx.create_from_string(" of (year \\d+|the [a-z\\-]+ year)$")
	name=_year_words.sub(name,"")
	return name.substr(0,1).to_upper()+name.substr(1)


static func over(e:Dictionary)->bool:
	## Ended: a crisis that ran its course, or a spell of sickness not heard
	## of for SPELL_GAP_DAYS.
	if e.has("end"): return true
	if String(e.get("type",""))!="illness": return false
	var last:=int(e.get("last",0))
	var today:=int(WorldSimulation.state.elapsed_days) if Engine.get_main_loop()!=null else last
	return today-last>SPELL_GAP_DAYS


static func when(e:Dictionary)->String:
	## "Year 9 · Summer", or "Year 9 · Summer to Year 10 · Spring" for a long one.
	var chronicle:=preload("res://scripts/chronicle.gd")
	var start:=int(e.get("start",0))
	var first:=chronicle.date_label(start)
	var last:=chronicle.date_label(int(e.get("end",e.get("last",start))))
	return first if last==first else "%s to %s" % [first,last]


static func place(e:Dictionary)->String:
	var home:=String(e.get("place",""))
	var where:=String(e.get("where",""))
	if home!="" and where!="": return "%s, %s" % [home,where]
	if home!="": return home
	return where


static func numbers(e:Dictionary)->String:
	## The engine's numbers, in plain words: who fell ill, what was lost,
	## who died.
	var parts:PackedStringArray=[]
	var type:=String(e.get("type",""))
	var pop:=maxf(1.0,float(e.get("pop",1)))
	if int(e.get("sick",0))>0: parts.append("%d fell ill" % int(e.sick))
	match type:
		"hunger":
			if e.has("food_days"): parts.append("the stores held about %d days when it began" % int(e.food_days))
		"drought":
			if float(e.get("sev",0.0))>0.0: parts.append("the gathering fell by about %s in 10" % _parts(float(e.sev)))
			# The water ledger (dry_water.gd): how far the springs failed, and the thirst.
			if e.has("depth"): parts.append("at its worst the near springs gave about %d in 10 of their water" % clampi(roundi((1.0-float(e.depth))*10.0),0,10))
			if int(e.get("thirst",0))>0: parts.append("%d died of thirst when the water stores ran dry" % int(e.thirst))
		"cold":
			if float(e.get("sev",0.0))>0.0: parts.append("the year's gathering fell by about %s in 10" % _parts(float(e.sev)))
		"thinning":
			if e.has("eco"): parts.append("the near ground stood at %d in 100" % roundi(float(e.eco)*100.0))
		"illness":
			if e.has("health_low"): parts.append("health fell to %d in 100" % roundi(float(e.health_low)*100.0))
	var lost:PackedStringArray=[]
	var food:=float(e.get("food_lost",0.0))
	if food>=1.0:
		var days:=roundi(food/pop)
		lost.append("%d Food (%s)" % [roundi(food),"about a day's worth" if days<=1 else "about %d days' worth" % days])
	if float(e.get("timber_lost",0.0))>=1.0: lost.append("%d timber" % roundi(float(e.timber_lost)))
	if not lost.is_empty(): parts.append("%s %s" % [" and ".join(lost),"burned" if type=="fire" else "lost"])
	if int(e.get("house_lost",0))>0: parts.append("shelter for %d lost" % int(e.house_lost))
	var dead:=int(e.get("dead",0))
	var names:PackedStringArray=[]
	for n in (e.get("names",[]) if e.get("names") is Array else []): names.append(String(n))
	if dead<=0: parts.append("no one died" if over(e) else "no one has died")
	elif names.is_empty(): parts.append("%d died" % dead)
	else: parts.append("%d died: %s%s" % [dead,"; ".join(names),"; and others" if dead>names.size() else ""])
	var text:="; ".join(parts)
	return (text.substr(0,1).to_upper()+text.substr(1)+".") if text!="" else ""


static func _parts(share:float)->String:
	var n:=maxi(1,roundi(share*10.0))
	return "1 part" if n==1 else "%d parts" % n


static func course(e:Dictionary)->String:
	## What was done and who decided: "Everyone tended the sick, then the
	## children were kept from the sick. Tomaq decided; the god was silent."
	var type:=String(e.get("type",""))
	var steps:PackedStringArray=[]
	var bys:Array=[]
	for pair in [["choice","by"],["mid_choice","by_mid"]]:
		var id:=String(e.get(pair[0],""))
		if id=="": continue
		var words:=String(FIRE_COURSE.get(id,"")) if type=="fire" and FIRE_COURSE.has(id) else String(COURSE.get(id,""))
		if words=="": continue
		steps.append(words)
		bys.append(String(e.get(pair[1],"")))
	var rite:=String(RITES.get(String(e.get("rite","")),""))
	if rite!="":
		steps.append(rite)
		bys.append(String(e.get("by_rite","")))
	if steps.is_empty(): return ""
	var holder:=String(e.get("holder","")).strip_edges().get_slice(" ",0)
	var kinds:Dictionary={}
	for b in bys:
		if String(b)!="": kinds[String(b)]=true
	var mixed:=kinds.size()>1
	if mixed:
		for i in steps.size():
			var said:=_by_short(String(bys[i]),holder)
			if said!="": steps[i]="%s (%s)" % [steps[i],said]
	var told:=", then ".join(steps)
	told=told.substr(0,1).to_upper()+told.substr(1)+"."
	if mixed or kinds.is_empty(): return told
	match String(kinds.keys()[0]):
		"custom": return told+" The people did it by their own custom."
		"god": return told+" By the god's word."
		"holder": return told+(" %s decided; the god was silent." % holder if holder!="" else " The god was silent.")
	return told


static func _by_short(by:String,holder:String)->String:
	match by:
		"custom": return "by custom"
		"god": return "the god's word"
		"holder": return ("%s decided" % holder) if holder!="" else "the god was silent"
	return ""


static func sentence(e:Dictionary)->String:
	## One plain sentence for the court's event ledger.
	var ended:=" is over" if over(e) else ""
	return ("%s%s. %s %s" % [title(e),ended,numbers(e),course(e)]).strip_edges()


static func words(e:Dictionary)->Dictionary:
	## The dock's row, in words: {title, sub, detail, value, tip}.
	var what:=String(WHAT.get(String(e.get("type","")),"Hard times"))
	var where:=place(e)
	var sub:="%s · %s%s" % [what,when(e),(" · "+where) if where!="" else ""]
	var detail:=numbers(e)
	var done:=course(e)
	if done!="": detail+=" "+done
	var ended:=over(e)
	if not ended: detail+=" Still going."
	var dead:=int(e.get("dead",0))
	var value:=("%d died" % dead) if dead>0 else ("none died" if ended else "none yet")
	var tip:="Extreme: one in twenty of the people dead, or half the stores or shelter lost. It also came to you as a card and is kept in the Chronicle." if bool(e.get("extreme",false)) else "Kept only in this log."
	return {"title":title(e),"sub":sub,"detail":detail.strip_edges(),"value":value,"tip":tip}

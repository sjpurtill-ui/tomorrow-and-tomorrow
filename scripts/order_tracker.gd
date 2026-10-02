extends RefCounted
## THE ORDER TRACKER: the fail-safe for every order the god gives.
##
## The player asked for 20 soldiers and saw nothing happen. Now every order,
## from every screen and the court, is written here the moment it is given,
## and the card at the bottom right of the screen (hud/order_stack.gd) says
## how it is being carried out, from the engine's own ledger:
##   accepted   given; a mechanic has it, or the court waits on the god's word
##   under_way  the ledger moves ("7 of 20 called up · drill 12 of 45 days")
##   done       finished
##   stalled    it moved, then stopped, with the reason in numbers
##   refused    it could not be done, and why
##   called_off a later word of the god's on the same subject replaced it
##              (supersede): "Build the next defences now", then "Hold off
##              new defences", leaves one card, not two stacked.
##   nothing    THE FAIL-SAFE: by the end of the next game day no mechanic
##              moved it ("Nothing has happened yet: <the engine's reason>"),
##              or no system ever took it ("No one took this order"), or the
##              court could map the words to nothing ("Not carried out:
##              nobody could act on this").
##
## Entry points register an order (register) and say which mechanic took it
## (claim, from_court, from_home, from_war, refuse, done, nothing). The kind
## and its refs let order_probes.gd read the live state of the order from the
## ledger itself; nothing on a card is kept apart from the state. update(day)
## runs the probes and the fail-safe once a game day (the order stack calls it
## when the day changes, never every frame).
##
## The ledger is GameState.order_tracker ({next_id, orders}), saved with the
## game: at most MAX_ORDERS, finished ones dropped KEEP_FINISHED_DAYS after
## they end. An older save loads with none. Only the god's own orders are
## written; other peoples' rulers never call these functions.
## Static helpers; preload.

const Probes:=preload("res://scripts/order_probes.gd")

const MAX_ORDERS:=40
const KEEP_FINISHED_DAYS:=60
## A claimed order that moved before and has not moved for this many days is
## stalled.
const STALL_DAYS:=3
## Most words a card line may hold.
const MAX_WORDS:=12
const ENDED:=["done","refused","called_off"]
## The screen each source opens (command_rail_hud section ids; "court" opens
## the court).
const SCREENS:={"court":"court","army":"military","recruit":"military:1","production":"production","buildings":"construction","defences":"construction","research":"inquiry"}

## The one signal the order stack listens to: a card was added or changed.
class Hub extends RefCounted:
	signal changed

static var _hub:Hub

static func hub()->Hub:
	if _hub==null:_hub=Hub.new()
	return _hub

static func _today()->int:
	return int(GameState.elapsed_days)

static func _data()->Dictionary:
	var d:Dictionary=GameState.order_tracker
	if not d.get("orders") is Array:d["orders"]=[]
	if int(d.get("next_id",0))<1:d["next_id"]=1
	return d

## Every order kept, newest first.
static func orders()->Array:
	return _data().orders

static func find(id:int)->Dictionary:
	if id<=0:return {}
	for o in orders():
		if int((o as Dictionary).get("id",0))==id:return o
	return {}

## A new order, given now. words: the order in plain words ("Raise 20
## levies"); source: where it was given (court, army, recruit, production,
## buildings, defences, research); said: the god's own words, if typed;
## who: who carries it out, when already known. Returns its id.
static func register(words:String,source:String,said:String="",who:String="",screen:String="")->int:
	var d:=_data()
	var id:=int(d.next_id)
	d["next_id"]=id+1
	var today:=_today()
	var o:={"id":id,"day":today,"words":short(words,8),"said":said.strip_edges().substr(0,160),"source":source,"who":who,"screen":screen if screen!="" else String(SCREENS.get(source,"")),
		"kind":"","refs":{},"claimed":false,"state":"accepted","line":"Given · waiting for someone to take it up","value":0,"total":0,
		"progress":-1.0,"moved_day":today,"ever_moved":false,"updated_day":today,"ended_day":-1}
	(d.orders as Array).push_front(o)
	_prune()
	_changed()
	return id

## A mechanic took the order: kind and refs say where its state is read
## (order_probes.gd). The card reads the ledger at once.
static func claim(id:int,kind:String,refs:Dictionary={},who:String="",screen:String="")->void:
	var o:=find(id)
	if o.is_empty():return
	o["claimed"]=true
	o["kind"]=kind
	o["refs"]=refs.duplicate(true)
	if who!="":o["who"]=who
	if screen!="":o["screen"]=screen
	o["progress"]=-1.0
	o["ended_day"]=-1
	_read(o,_today(),true)
	_changed()

## It could not be done, and why (the engine's own words, made short).
static func refuse(id:int,reason:String,who:String="")->void:
	_end(id,"refused",reason,who)

## Done at once (a setting changed, a band formed).
static func done(id:int,line:String,who:String="")->void:
	_end(id,"done",line,who)

## Nobody could act on it: red at once, the fail-safe's own words.
static func nothing(id:int,line:String="Not carried out: nobody could act on this")->void:
	var o:=find(id)
	if o.is_empty():return
	# Settled as nothing: no probe will ever move it.
	o["kind"]="none"
	o["state"]="nothing"
	o["line"]=short(line)
	o["updated_day"]=_today()
	_changed()

## The god's later word on the same subject (one knob of the realm: the
## town's defences, a town's first work, a research question, the stance
## toward a people) calls off any earlier order on it still open: its card
## ends "Called off · now: <the later order>" and fades, instead of standing
## under the new one waiting forever.
static func supersede(id:int,subject:String)->void:
	var o:=find(id)
	if o.is_empty() or subject=="":return
	o["subject"]=subject
	var now:=_lower_first(String(o.get("words","")))
	for other in orders():
		var earlier:Dictionary=other
		if int(earlier.get("id",0))==id or String(earlier.get("subject",""))!=subject:continue
		if String(earlier.get("state",""))in ENDED:continue
		earlier["claimed"]=true
		if String(earlier.get("kind",""))=="":earlier["kind"]="settled"
		earlier["state"]="called_off"
		earlier["line"]=short("now: "+now)
		earlier["ended_day"]=_today()
		earlier["updated_day"]=_today()
	_changed()

static func _end(id:int,state:String,line:String,who:String)->void:
	var o:=find(id)
	if o.is_empty():return
	o["claimed"]=true
	if String(o.get("kind",""))=="":o["kind"]="settled"
	o["state"]=state
	o["line"]=short(line)
	if who!="":o["who"]=who
	o["ended_day"]=_today()
	o["updated_day"]=_today()
	_changed()

## The live state of every order not yet ended, from the ledger, and the
## fail-safe. Cheap: a few dictionary reads an order. Called once a game day.
static func update(day:int=-1)->void:
	if day<0:day=_today()
	var moved:=false
	for o in orders():
		var order:Dictionary=o
		if String(order.get("state",""))in ENDED:continue
		var before:=[String(order.state),String(order.line),int(order.value),int(order.total)]
		_read(order,day,false)
		if before!=[String(order.state),String(order.line),int(order.value),int(order.total)]:moved=true
	if _prune():moved=true
	if moved:_changed()

## One order read from the ledger, with the fail-safe applied.
static func _read(o:Dictionary,day:int,claiming:bool)->void:
	if String(o.get("kind",""))=="none":return
	o["updated_day"]=day
	if not bool(o.get("claimed",false)):
		# Nobody took it. By the end of the next game day, say so in red.
		if day>=int(o.day)+2:
			o["state"]="nothing";o["line"]="Nothing has happened yet: no one took this order"
		return
	var r:=Probes.read(o)
	var progress:=float(r.get("progress",0.0))
	if float(o.get("progress",-1.0))<0.0 or claiming:
		o["progress"]=progress;o["moved_day"]=day
	elif progress>float(o.progress)+0.0001:
		o["progress"]=progress;o["moved_day"]=day;o["ever_moved"]=true
	o["value"]=int(r.get("value",0));o["total"]=int(r.get("total",0))
	var state:=String(r.get("state","under_way"))
	var line:=String(r.get("line",""))
	var reason:=String(r.get("reason",""))
	if state in ENDED:
		o["state"]=state;o["line"]=short(line);o["ended_day"]=day
		return
	if state=="refused_now":
		o["state"]="refused";o["line"]=short(line);o["ended_day"]=day
		return
	# The fail-safe: claimed, but the ledger has not moved since it was given
	# and the next game day is over.
	if not bool(o.get("ever_moved",false)) and not bool(r.get("moved",false)) and day>=int(o.day)+2 and not bool(r.get("standing",false)):
		o["state"]="nothing"
		o["line"]=short("Nothing has happened yet: "+(reason if reason!="" else "nothing in the ledger has moved"))
		return
	if state=="under_way" and bool(o.get("ever_moved",false)) and day-int(o.get("moved_day",day))>=STALL_DAYS and not bool(r.get("standing",false)):
		state="stalled"
		if reason=="":reason="nothing has moved for %d days" % (day-int(o.moved_day))
	o["state"]=state
	o["line"]=short(line if state!="stalled" or reason=="" else "Stalled: "+reason)

## Drops orders that ended long ago, and the oldest beyond MAX_ORDERS.
static func _prune()->bool:
	var list:=orders()
	var today:=_today()
	var before:=list.size()
	for i in range(list.size()-1,-1,-1):
		var o:Dictionary=list[i]
		var ended:=int(o.get("ended_day",-1))
		if (String(o.get("state",""))in ENDED and ended>=0 and today-ended>KEEP_FINISHED_DAYS) or (String(o.get("state",""))=="nothing" and today-int(o.get("day",today))>KEEP_FINISHED_DAYS):
			list.remove_at(i)
	while list.size()>MAX_ORDERS:
		var dropped:=false
		for i in range(list.size()-1,-1,-1):
			if String((list[i] as Dictionary).get("state",""))in ENDED:
				list.remove_at(i);dropped=true;break
		if not dropped:list.remove_at(list.size()-1)
	return list.size()!=before

static func _changed()->void:
	hub().changed.emit()

## At most `limit` words, plainly cut (a "·" or a dash is no word).
static func short(text:String,limit:int=MAX_WORDS)->String:
	var clean:=text.strip_edges().replace("\n"," ")
	var words:=clean.split(" ",false)
	var counted:=0
	for i in words.size():
		if _wordlike(String(words[i])):counted+=1
		if counted>limit:return " ".join(words.slice(0,i)).rstrip(",;:·- ")+"…"
	return clean

static var _word_re:RegEx

static func _wordlike(token:String)->bool:
	if _word_re==null:_word_re=RegEx.create_from_string("[A-Za-z0-9]")
	return _word_re.search(token)!=null

# --------------------------------------------------------------------------
# What each kind of result means for its card
# --------------------------------------------------------------------------

## A home order's result (home_orders.gd perform): which mechanic took it and
## where its state lives, or why it could not be done.
static func from_home(id:int,result:Dictionary,who:String="")->void:
	var o:=find(id)
	if o.is_empty():return
	var kind:=String(result.get("kind",""))
	var ok:=bool(result.get("ok",false))
	var why:=_why(String(result.get("outcome","")),String(result.get("says","")))
	match kind:
		"levy","recruit":
			if not ok and int(result.get("raised",0))<=0 and int(result.get("drilling",0))<=0:
				refuse(id,why,who);return
			claim(id,"levy",{"training_id":int(result.get("training_id",-1)),"asked":int(result.get("asked",result.get("count",0))),"raised":int(result.get("raised",result.get("count",0))),
				"drilling":int(result.get("drilling",0)),"weapon":String(result.get("weapon","")),"camp":bool(result.get("camp",false)),"reason":why},who if who!="" else _war_leader(),"military:2")
		"arm","carts","repair":
			if not ok or int(result.get("count",0))<=0:
				if ok:done(id,why,who)
				else:refuse(id,why,who)
				return
			claim(id,"workshop",{"item":String(result.get("item","cart" if kind=="carts" else "")),"count":int(result.get("count",0)),"job_id":int(result.get("job_id",-1)),"start_made":_made(String(result.get("item","")))},who if who!="" else _workshop_officer(),"production")
		"line":
			if not ok:refuse(id,why,who);return
			claim(id,"line",{"item":String(result.get("item","")),"target":int(result.get("target",0))},who if who!="" else _workshop_officer(),"production")
		"deploy":
			if not ok:refuse(id,why,who);return
			claim(id,"band",{"army_id":int(result.get("army_id",0))},who if who!="" else _war_leader(),"military")
		"inquiry":
			if not ok:refuse(id,why,who);return
			var inquiry:=String(result.get("id",""))
			if inquiry=="" or int(result.get("count",1))<=0:done(id,why,who);return
			claim(id,"research",{"id":inquiry,"start":float(GameState.discovery_progress.get(inquiry,0.0))},who if who!="" else _lore_keeper(),"inquiry")
		"build":
			if not ok:refuse(id,why,who);return
			var title:=String(result.get("work",""))
			if title=="":done(id,why,who);return
			var built:=0
			for t in GameState.settlement_completed:
				if String(t)==title:built+=1
			claim(id,"build",{"title":title,"settlement_id":String(result.get("settlement_id","")),"built_before":built,"start_work":float(GameState.settlement_projects.get(title,0.0))},who,"construction")
		"defences":
			if not ok:refuse(id,why,who);return
			claim(id,"defences",{"word":"build"},who if who!="" else _war_leader(),"construction")
		_:
			if ok:done(id,why,who)
			else:refuse(id,why,who)

## The war leader's answer (court_war_orders.perform, army_orders.give): a
## march with a band on the road, an objection that waits on the god's word,
## or a plain no.
static func from_war(id:int,decision:Dictionary)->void:
	var o:=find(id)
	if o.is_empty():return
	var general:=String(decision.get("general",""))
	var why:=_why(String(decision.get("outcome","")),String(decision.get("says","")))
	# A no or an objection is told by its reason, the war leader's own words.
	var reason:=_why(String(decision.get("says","")),String(decision.get("outcome","")))
	var objective:Dictionary=decision.get("objective",{}) if decision.get("objective") is Dictionary else {}
	match String(decision.get("verdict","")):
		"act","fate":
			var army_id:=int(objective.get("army_id",0))
			if army_id>0:
				claim(id,"march",{"army_id":army_id,"kind":String(objective.get("kind",decision.get("kind",""))),"zone_id":String(objective.get("zone_id","")),"start_day":_today(),"days":int(objective.get("days",0))},general,"military")
			else:done(id,why,general)
		"object","ask":
			# The war leader waits on the god's word: given, not yet carried out.
			claim(id,"waiting",{"reason":reason},general,"court")
		_:
			refuse(id,reason,general)

## A covert order (covert_orders.perform): a venture set in motion that the
## card follows (travelling, in place, struck, outcome), an objection waiting
## on the god's word, or a plain refusal. One card per target (supersede).
static func from_covert(id:int,decision:Dictionary,who:String)->void:
	var o:=find(id)
	if o.is_empty():return
	var carrier:=String(decision.get("carrier",who))
	var why:=_why(String(decision.get("outcome","")),String(decision.get("says","")))
	match String(decision.get("verdict","")):
		"act":
			supersede(id,"covert:%d" % int(decision.get("op_id",0)))
			claim(id,"covert",{"op_id":int(decision.get("op_id",0))},carrier,"military")
		"object":
			claim(id,"waiting",{"reason":_lower_first(_why(String(decision.get("says","")),"it waits for your word"))},carrier,"court")
		_:
			refuse(id,why,carrier)

## A court result (court_commands.hear and the court's other answers): the
## mechanic behind it, or the plain truth that nothing was set in motion.
static func from_court(id:int,result:Dictionary)->void:
	var o:=find(id)
	if o.is_empty():return
	var who:=String(result.get("actor_name",""))
	var route:=String(result.get("route",""))
	if route=="home" and result.get("home") is Dictionary:
		from_home(id,result.home as Dictionary,who);return
	if route=="war" or String(result.get("verb",""))=="war":
		var decision:Dictionary=result.get("war",{}) if result.get("war") is Dictionary else {}
		if not decision.is_empty():from_war(id,decision);return
	if String(result.get("verb",""))=="covert":
		from_covert(id,result.get("covert",{}) if result.get("covert") is Dictionary else {},who);return
	var outcome:=String(result.get("outcome",""))
	match route:
		"custom_directive":
			var applied:Dictionary=result.get("applied",{}) if result.get("applied") is Dictionary else {}
			claim(id,"directive",{"order_id":String(result.get("order_id","")),"days":int(float((applied.get("assessment",{}) as Dictionary).get("days",180.0))) if applied.get("assessment") is Dictionary else 180,"start_day":_today()},who if who!="" else "the council","court")
			return
		"civic":
			claim(id,"civic",{"settlement_id":String(result.get("settlement_id","")),"start_day":_today()},who if who!="" else "the town council","court")
			return
		"recorded":
			nothing(id,"Not carried out: "+_lower_first(_why(outcome,"nobody could act on this")));return
	if bool(result.get("executed",false)):
		done(id,_why(outcome,"Carried out"),who)
	elif outcome.begins_with("Nothing is set in motion") or String(result.get("stage",""))=="none":
		nothing(id,"Not carried out: "+_lower_first(_why(outcome,"nobody could act on this")))
	elif String(result.get("stage","")).begins_with("refuse") or String(result.get("obedience",{}).get("id","")) in ["refuse","object"]:
		refuse(id,_why(outcome,"Refused"),who)
	else:
		# Taken up, but held back (a hesitation, a question back): it waits on
		# the god's word, and the fail-safe watches it.
		claim(id,"waiting",{"reason":_lower_first(_why(outcome,"it waits for your word"))},who,"court")

## The first clause of the engine's words: "Nothing is set in motion: no free
## adults" -> "no free adults".
static func _why(outcome:String,fallback:String)->String:
	var text:=outcome.strip_edges().trim_prefix("Nothing is set in motion: ")
	if text=="":text=fallback.strip_edges()
	var first:=text.get_slice(". ",0).strip_edges()
	first=first.trim_suffix(".")
	return first.substr(0,1).to_upper()+first.substr(1)

static func _lower_first(text:String)->String:
	return text.substr(0,1).to_lower()+text.substr(1)

static func _made(item:String)->int:
	if item=="":return 0
	return int((MilitaryCampaign.military_inventory as Dictionary).get(item,0))

static func _war_leader()->String:
	var leader:Dictionary=load("res://scripts/court_war_orders.gd").war_leader()
	if String(leader.get("name",""))!="":return String(leader.name)
	var p:Dictionary=GovernmentPeopleSystem.officeholder("Marshal")
	return String(p.get("name","the war leader")) if not p.is_empty() else "the war leader"

static func _workshop_officer()->String:
	for office in ["Quartermaster","Steward"]:
		var p:Dictionary=GovernmentPeopleSystem.officeholder(office)
		if not p.is_empty():return String(p.get("name","the workshops"))
	return "the workshops"

static func _lore_keeper()->String:
	var p:Dictionary=GovernmentPeopleSystem.officeholder("Scholar")
	return String(p.get("name","our thinkers")) if not p.is_empty() else "our thinkers"

# --------------------------------------------------------------------------
# Orders from the screens
# --------------------------------------------------------------------------

## A workshop order from a screen: a batch (its job id) or a line that keeps
## a stock (its job_id).
static func workshop_order(words:String,result:Dictionary,item:String,count:int,line:bool)->int:
	var card:=register(words,"production")
	if result.has("error"):
		refuse(card,String(result.error))
	elif line:
		claim(card,"line",{"item":item,"job_id":int(result.get("job_id",-1)),"target":count,"start_made":0},_workshop_officer(),"production")
	else:
		claim(card,"workshop",{"item":item,"count":int(result.get("queued",count)),"job_id":int(result.get("id",-1))},_workshop_officer(),"production")
	return card

## A setting changed on a screen (a line paused, a field's attention, who
## decides): done at once, or refused with the reason.
static func setting_order(words:String,result:Dictionary,source:String,who:String="",screen:String="")->int:
	var card:=register(words,source,"",who,screen)
	if result.has("error"):refuse(card,String(result.error))
	elif result.has("ok") and not bool(result.ok):refuse(card,String(result.get("reason",result.get("message","It could not be done"))))
	else:done(card,_why(String(result.get("message","Done")),"Done"))
	return card

## A work put first by the builders (settlement_construction.set_priority):
## followed until it stands.
static func building_order(title:String,result:Dictionary,settlement_id:String="")->int:
	var card:=register(("Build %s first" % title) if title!="" else "Let the leader choose the works","buildings")
	if result.has("error"):refuse(card,String(result.error));return card
	# One work comes first in a town: a later choice replaces the earlier.
	supersede(card,"priority:%s" % settlement_id)
	if title=="":done(card,"The town's leader chooses what is built");return card
	var built:=0
	for t in GameState.settlement_completed:
		if String(t)==title:built+=1
	claim(card,"build",{"title":title,"settlement_id":settlement_id,"built_before":built,"start_work":float(GameState.settlement_projects.get(title,0.0))},"the builders","construction")
	return card

## The god's word on the town's defences (home_defense.set_word).
static func defence_order(word:String,result:Dictionary)->int:
	var labels:={"people":"Let the people decide the defences","build":"Build the next defences now","hold":"Hold off new defences"}
	var card:=register(String(labels.get(word,"Defences: "+word)),"defences")
	if result.has("error"):refuse(card,String(result.error));return card
	# One word on the defences stands: the later one replaces the earlier.
	supersede(card,"defences")
	claim(card,"defences",{"word":word},_war_leader(),"construction")
	return card

## A discovery chosen for research (DiscoverySystem.select_research_target).
static func research_order(id:String,name:String,result:Dictionary)->int:
	var card:=register("Research %s" % name,"research")
	if not bool(result.get("ok",false)):refuse(card,String(result.get("reason","It cannot be studied now")));return card
	supersede(card,"research:%s" % id)
	claim(card,"research",{"id":id,"start":float(GameState.discovery_progress.get(id,0.0))},_lore_keeper(),"inquiry")
	return card

# --------------------------------------------------------------------------
# For the screen
# --------------------------------------------------------------------------

## Orders for the stack, newest first: everything not finished, then what
## finished in the last `fresh_days` days.
static func current(fresh_days:int=1)->Array:
	var out:=[]
	var today:=_today()
	for o in orders():
		var order:Dictionary=o
		if String(order.state) in ENDED and today-int(order.get("ended_day",today))>fresh_days:continue
		out.append(order)
	return out

## The court's words, read as an order or not: a question or plain talk is
## no order and gets no card.
static func is_order_words(text:String)->bool:
	var clean:=text.strip_edges()
	if clean=="" or clean.ends_with("?"):return false
	var CC=load("res://scripts/court_commands.gd")
	if not (load("res://scripts/home_orders.gd").read(clean) as Dictionary).is_empty():return true
	var cls:Dictionary=CC.classify(clean)
	if String(cls.get("act",""))=="question":return false
	return String(cls.get("act",""))=="command" and String(cls.get("verb","none"))!="none"

## The order in plain words for its card: what a home order or a war order
## does ("Raise 20 levies", "Attack Tsaren"), else the god's own words.
static func court_title(text:String)->String:
	var HO=load("res://scripts/home_orders.gd")
	var r:Dictionary=HO.read(text)
	match String(r.get("kind","")):
		"levy":
			var n:=int(r.get("count",0))
			var what:=String(HO.KIND_NAMES.get(String(r.get("unit","levy")),"a levy")).trim_prefix("a ")
			if what=="levy":what="levies"
			if bool(r.get("recruit",false)) or bool(r.get("fill",false)):return ("Raise %d %s" % [n,what]) if n>0 else "Raise a levy"
			return "Drill the recruits"
		"stand_down":
			var n:=int(r.get("count",0))
			if String(r.get("band_name",""))!="":return short("Disband %s" % String(r.band_name),8)
			if n>0:return "Send %d fighters home" % n
			return "Disband the army" if bool(r.get("all",false)) else "Send fighters home"
		"arm":
			var n:=int(r.get("count",0))
			var item:=String(HO.ITEM_NAMES.get(String(r.get("item","")),"weapons"))
			return ("Make %d %s" % [n,item]) if n>0 else "Arm the recruits"
	var clean:=text.strip_edges().trim_suffix(".").trim_suffix("!")
	return short(clean.substr(0,1).to_upper()+clean.substr(1),8)

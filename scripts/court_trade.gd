extends RefCounted
## TRADE ORDERS AT COURT: the god's word on trade with another people,
## carried out by the trade ledger (trade_stances.gd), answered in the
## official's own words with the engine's numbers and odds.
##
## The Envoy (the Messenger) carries trade with other peoples; until that
## office is open or held, the Headman (Steward) does (office_levers.gd
## order_holder). The orders, by what they set:
##   free     "trade with Ildor", "open trade with the Ildor", "lift the
##            embargo on Ildor" (the envoy goes to propose a compact, as before)
##   embargo  "stop all trade with Ildor", "embargo the Ildor", "cut them off"
##   squeeze  "buy up their flint", "keep flint from the Ildor"
##   tribute  "demand tribute from Kezari", "make them pay us tribute"
##   gift     "send them 200 grain" (once, from our stores now)
##   gifts    "send gifts to the Varesh" (each season, from our plenty)
##   favour   "flood their markets with cloth", "favour the Ildor"
##   toll     "put a toll on Ildor's traders"
## "them" and "their" mean the people last named in this audience (or the
## only people we know). Words that ask ("what do we trade with Kezari?") are
## questions, answered from the keeper's facts (court_facts.gd, court_answers.gd).
## Words for an embassy ("send an envoy with gifts") go to the envoys as before.
##
## hear(id, audience, text, context) is the court's hook (court_commands.hear):
## a result like a home order's (route "home", the order card follows it), or
## {} when the words are no trade order. Static; preload.

const Ledger:=preload("res://scripts/trade_ledger.gd")
const Stances:=preload("res://scripts/trade_stances.gd")
const Words:=preload("res://scripts/trade_words.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const CC_PATH:="res://scripts/court_commands.gd"
const LEVERS_PATH:="res://scripts/office_levers.gd"

const QUESTION:="(?i)^\\s*(?:what|why|how|who|whom|where|when|whose|which|do we|does|is|are|can we)\\b"
const EMBASSY:="(?i)\\b(envoys?|emissar(?:y|ies)|messengers?|embass(?:y|ies)|delegation|heralds?)\\b"
const EMBARGO:="(?i)\\b(?:(?:stop|end|cease|halt|break off|ban|forbid|suspend|cut off)\\b[^.!?]{0,30}?\\b(?:all\\s+)?(?:trade|trading|exchange|barter|bartering|dealings|commerce)\\b|embargo|no (?:more |longer )?trade with|(?:don'?t|do not|never) trade with|close (?:our )?markets? to|shut (?:out|off) (?:their|the)\\b[^.!?]{0,20}?\\btraders?)\\b"
const LIFT:="(?i)\\b(?:lift|end|drop|stop|remove|call off)\\s+(?:the\\s+|our\\s+)?(?:embargo|toll|tolls|squeeze)\\b"
const FREE:="(?i)\\b(?:(?:open|start|begin|resume|restore|reopen|renew)\\b[^.!?]{0,20}?\\btrad(?:e|ing)|trade (?:freely )?with|barter with|trade freely|let (?:our )?traders? (?:go|trade))\\b"
const SQUEEZE:="(?i)\\b(?:buy up|buy all|corner|squeeze)\\b"
## Denying a good is a squeeze only when a people is named (said of "them" it
## may be a siege or a war order).
const DENY:="(?i)\\b(?:deny|withhold|keep\\b[^.!?]{0,25}?\\bfrom)\\b"
const TRIBUTE:="(?i)\\b(?:(?:demand|exact|take|ask for|require|levy|extract|collect)\\b[^.!?]{0,20}?\\btribute|(?:make|force)\\b[^.!?]{0,25}?\\bpay\\b[^.!?]{0,10}?\\btribute|pay (?:us )?tribute)\\b"
const TOLL:="(?i)\\b(?:tolls?|tariffs?|duties|duty on|tax (?:their|the)\\b[^.!?]{0,15}?\\btraders?|charge\\b[^.!?]{0,20}?\\b(?:toll|fee))\\b"
const FAVOUR:="(?i)\\b(?:flood|favou?r|sell cheap|undersell|undercut|dump|good terms|better terms|generous terms)\\b"
const GIFT:="(?i)\\b(?:send|give|bring|offer|ship|carry)\\b"
const GIFT_WORDS:="(?i)\\b(?:gifts?|presents?|tokens?)\\b"
## People sent are a party, never a gift ("send scouts", "send them men",
## "send an assassin with gifts": spies and assassins are covert business).
const NOT_GOODS:="(?i)\\b(?:scouts?|part(?:y|ies)|searchers|hunters|men|warriors|fighters|soldiers|settlers|bands?|army|armies|word|riders|outriders|expedition|traders|spy|spies|assassins?|agents?|killers?|thie(?:f|ves)|saboteurs?|poisoners?)\\b"
const SEASONAL:="(?i)\\b(?:each|every)\\s+(?:season|year|spring|harvest)|\\bseasonal(?:ly)?\\b|\\bregular(?:ly)?\\b"
const PRONOUN:="(?i)\\b(?:them|their|they|theirs)\\b"
## The words for each good, as people say them.
const GOOD_WORDS:=[["Food","\\b(?:food|grain|meat|bread|rations|provisions|corn|wheat|barley)\\b"],["Salt","\\bsalt\\b"],["Flint","\\b(?:flint|knife-?stone)\\b"],
	["Timber","\\b(?:timber|wood|logs|lumber)\\b"],["Stone","\\b(?:stone|stones)\\b"],["Clay","\\bclay\\b"],["Fiber Plants","\\b(?:fib(?:er|re)s?|reeds|flax)\\b"],
	["Medicinal Plants","\\b(?:herbs|medicines?|healing plants)\\b"],["Copper Ore","\\bcopper\\b"],["Tin Ore","\\btin\\b"],["Iron Ore","\\biron\\b"],["Coal","\\bcoal\\b"],
	["Civilian Goods","\\b(?:cloth|clothing|garments|textiles|goods|tools|pots|wares|made things|crafts)\\b"]]

static func _re(pattern:String)->RegEx:
	var r:=RegEx.new(); r.compile(pattern)
	return r

static func _has(text:String,pattern:String)->bool:
	return _re(pattern).search(text)!=null

# --------------------------------------------------------------------------
# Reading
# --------------------------------------------------------------------------

## The trade order the words give: {kind:"trade", act, civ_id, people, good,
## amount, ask?} or {}. ask: the people could not be told ("Which people?").
static func read(text:String,audience:Dictionary={})->Dictionary:
	var clean:=text.strip_edges()
	if clean.is_empty() or clean.ends_with("?") or _has(clean,QUESTION): return {}
	var lower:=clean.to_lower().replace("’","'")
	if _has(lower,EMBASSY): return {}
	var act:=""
	if _has(lower,LIFT): act="free"
	elif _has(lower,EMBARGO): act="embargo"
	elif _has(lower,TRIBUTE): act="tribute"
	elif _has(lower,TOLL) and _has(lower,"(?i)\\b(?:traders?|trade|caravans?|goods|on (?:the |them|their))\\b"): act="toll"
	elif (_has(lower,SQUEEZE) or (_has(lower,DENY) and not people_in(lower).is_empty())) and good_in(lower)!="": act="squeeze"
	elif _has(lower,FAVOUR) and (_has(lower,"(?i)\\b(?:markets?|traders?|terms|trade)\\b") or good_in(lower)!=""): act="favour"
	elif _has(lower,FREE): act="free"
	elif _has(lower,GIFT) and not _has(lower,NOT_GOODS) and (_has(lower,GIFT_WORDS) or (good_in(lower)!="" and _amount(lower)>0)): act="gift"
	if act=="": return {}
	var people:=people_in(lower)
	if people.is_empty():
		# "them", "their": the people last named here, or the only one we know.
		if not _has(lower,PRONOUN): return {}
		people=_people_in_audience(audience)
		if people.is_empty():
			var known:=known_peoples()
			if known.size()==1: people=known[0]
			elif act=="gift" and not _has(lower,GIFT_WORDS): return {}
			else: return {"kind":"trade","act":act,"civ_id":"","people":"","good":good_in(lower),"amount":_amount(lower),"ask":true}
	var good:=good_in(lower)
	var amount:=_amount(lower)
	if act=="gift":
		# Gifts without a count or a good, or each season, are the standing gifts.
		if amount<=0 or good=="" or _has(lower,SEASONAL): act="gifts"
		elif good!="" and amount<=0: act="gifts"
	return {"kind":"trade","act":act,"civ_id":String(people.get("id","")),"people":String(people.get("name","")),"good":good,"amount":amount}

## The good the words name ("" for none). Goods named after "for" are what
## we ask, never what we send.
static func good_in(lower:String)->String:
	var best:=""; var at:=1<<30
	for pair:Array in GOOD_WORDS:
		var m:=_re("(?i)"+String(pair[1])).search(lower)
		if m!=null and m.get_start()<at: at=m.get_start(); best=String(pair[0])
	return best

static func _amount(lower:String)->int:
	var numbers:Array=preload("res://scripts/trade_pacts.gd").numbers_in(lower)
	for n in numbers:
		if int(n)>0: return int(n)
	return 0

## Every people we have met: [{id, name}].
static func known_peoples()->Array:
	var out:Array=[]
	if WorldSimulation.world==null: return out
	for c in WorldSimulation.world.civilizations:
		if not c is Dictionary: continue
		var id:=String((c as Dictionary).get("id",""))
		if id=="" or id=="player" or not bool((c as Dictionary).get("alive",true)): continue
		if int(((c as Dictionary).get("player_relation",{}) as Dictionary).get("contact_level",0))<1: continue
		out.append({"id":id,"name":String((c as Dictionary).get("name",""))})
	return out

## The people the words name: {id, name} or {}.
static func people_in(lower:String)->Dictionary:
	for p:Dictionary in known_peoples():
		var name:=String(p.name).to_lower().trim_prefix("the ")
		if name.length()>=3 and _has(lower,"(?i)\\b"+_escape(name)+"(?:s|'s)?\\b"): return p
	return {}

static func _escape(text:String)->String:
	var out:=""
	for ch in text:
		out+=("\\"+ch) if ch in ".^$*+?()[]{}|\\" else ch
	return out

## The people last named by the god in this audience.
static func _people_in_audience(audience:Dictionary)->Dictionary:
	if audience.is_empty(): return {}
	var civ_id:=String(audience.get("civ_id",""))
	if String(audience.get("origin",""))=="foreign" and civ_id!="":
		for p:Dictionary in known_peoples():
			if String(p.id)==civ_id: return p
	var lines:Array=audience.get("lines",[]) if audience.get("lines") is Array else []
	for i in range(lines.size()-1,maxi(-1,lines.size()-13),-1):
		var line:Variant=lines[i]
		if not line is Dictionary: continue
		var found:=people_in(String((line as Dictionary).get("text","")).to_lower())
		if not found.is_empty(): return found
	return {}

# --------------------------------------------------------------------------
# Carrying it out
# --------------------------------------------------------------------------

## Who carries trade with other peoples: the Envoy, or the Headman while no
## Envoy can or does hold office. {office, title, name, person}.
static func carrier()->Dictionary:
	var levers:=load(LEVERS_PATH) as GDScript
	var held:Dictionary=levers.call("order_holder","Envoy") if levers!=null else {}
	var office:=String(held.get("office","Envoy"))
	var person:Dictionary=held.get("person",{}) if held.get("person") is Dictionary else {}
	var title:=String(levers.call("office_title",office)) if levers!=null else office
	return {"office":office,"title":title,"name":String(person.get("name","")),"person":person}

## {ok, kind:"trade", count, says, outcome, act, civ_id}.
static func perform(reading:Dictionary)->Dictionary:
	var act:=String(reading.get("act",""))
	var civ_id:=String(reading.get("civ_id",""))
	var out:={"ok":false,"kind":"trade","count":0,"says":"","outcome":"","act":act,"civ_id":civ_id}
	if bool(reading.get("ask",false)) or civ_id=="":
		var names:=PackedStringArray()
		for p:Dictionary in known_peoples(): names.append("the %s" % String(p.name))
		out.says="Which people do you mean: %s?" % _or(names) if not names.is_empty() else "We have met no other people to trade with."
		out.outcome="Nothing is set in motion: no people was named."
		return out
	var name:=String(reading.get("people",Ledger.name_of(civ_id)))
	var good:=String(reading.get("good",""))
	var amount:=float(reading.get("amount",0))
	var who:=carrier()
	var by:=_by(who)
	var met:=int((Ledger.civ(civ_id).get("player_relation",{}) as Dictionary).get("contact_level",0))>=2
	if not met and act=="gift":
		out.says="The %s are known to us only by word: no carrier of ours can reach them, and nothing leaves the stores." % name
		out.outcome="Nothing is set in motion: the %s are known only by word." % name
		return out
	if not met and act!="free":
		# A people known only by word: the word stands, and nothing moves until we meet them.
		Stances.set_stance("player",civ_id,act,good,amount,"god")
		out.ok=true
		out.says="The %s are known to us only by word: no trader of ours reaches them, so nothing moves yet. When we meet them, it will be as you say." % name
		out.outcome="Nothing is set in motion yet: the %s are known only by word." % name
		return out
	if act!="free" and Ledger.blocked("player",civ_id) in ["war","feud"]:
		out.says="We are fighting the %s: no trader goes to them now, and no word of trade would be heard." % name
		out.outcome="Nothing is set in motion: we are fighting the %s." % name
		return out
	match act:
		"gift":
			var sent:=_send(civ_id,good,amount)
			if sent<=0.0:
				out.says="We have no %s to spare for the %s." % [Words.good_word(good),name]
				out.outcome="Nothing is set in motion: no %s to spare." % Words.good_word(good)
				return out
			out.ok=true; out.count=1
			out.says="%s %s go to the %s with our carriers%s. It warms them, and they will owe us for it." % [_cap(Words.amount(sent,good)),"" if sent>=amount-0.5 else " (all we can spare of the %s asked)" % EraWords.grouped(int(amount)),name,by]
			if good=="Food": out.says+=" It leaves us %s." % EraWords.store_span(_food_days())
			out.outcome="%s sent to the %s as a gift." % [_cap(Words.amount(sent,good)),name]
			return out
		"free":
			var lifted:=String(Stances.stance("player",civ_id).get("id","free"))
			var r:=Stances.set_stance("player",civ_id,"free","",0.0,"god")
			out.ok=true; out.count=1
			if not met:
				out.count=0
				out.says="The %s are known to us only by word: no trader of ours reaches them yet." % name
				var word:=_envoy(civ_id) if not bool(reading.get("page",false)) else ""
				if word!="": out.says+=" "+word; out.count=1
				out.outcome="Trade with the %s waits until we meet them." % name if word=="" else "Envoys go to the %s." % name
				return out
			var flows_now:=Words.flow_words("player",civ_id)
			out.says=("%s Our traders deal with the %s as it comes%s." % ["The %s is lifted." % Words._stance_noun(lifted,"") if lifted!="free" else "",name,(": we send %s; they send %s" % [flows_now,Words.flow_words(civ_id,"player")]) if flows_now!="nothing" else ""]).strip_edges()
			# The envoy goes to propose a standing compact, as before (not from the page).
			var envoy:=_envoy(civ_id) if not bool(reading.get("page",false)) else ""
			if envoy!="": out.says+=" "+envoy
			out.outcome="Trade with the %s is open%s." % [name,by]
			out["stance"]=r
			return out
	var result:=Stances.set_stance("player",civ_id,act,good,amount,"god")
	if not bool(result.get("ok",false)):
		out.says=String(result.get("said","That cannot be done."))
		out.outcome="Nothing is set in motion: "+_lower_first(out.says)
		return out
	out.ok=true; out.count=1
	var st:=Stances.stance("player",civ_id)
	var says:=PackedStringArray([String(result.get("said",""))])
	if act in ["embargo","squeeze"]:
		var leaning:=Words.leaning_line(civ_id,"player")
		if leaning!="": says.append(leaning)
	if int(result.get("answer_day",-1))>=0:
		var odds:Dictionary=(result.get("odds",{}) as Dictionary).get("p",{})
		says.append("Word reaches them in about %s. %s." % [EraWords.days(float(int(result.answer_day)-int(GameState.elapsed_days))),Words.odds_line(odds)])
	out.says=" ".join(says)+(by if by!="" else "")
	out.outcome="%s: %s%s." % [String(Words.LABELS.get(act,act)),name,(" (%s)" % Words.good_word(String(st.get("good","")))) if String(st.get("good",""))!="" else ""]
	out["stance"]=result
	return out

static func _by(who:Dictionary)->String:
	if String(who.get("name",""))=="": return ""
	return " %s the %s carries it" % [String(who.name).get_slice(" ",0),String(who.get("title","")).to_lower()]

## Goods sent once as a gift, from our stores now: what went.
static func _send(civ_id:String,good:String,amount:float)->float:
	if good=="" or amount<=0.0: return 0.0
	var spare:=Ledger.engine_report("player",int(GameState.elapsed_days))
	Ledger._fresh("player",spare)
	var x:Dictionary=(spare.get("g",{}) as Dictionary).get(good,{})
	var held:=float(x.get("s",0.0))
	# The god's word is obeyed, but never the very last of the food: a day's eating stays.
	if good=="Food": held=maxf(0.0,held-float(x.get("d",0.0))/30.0)
	var sent:=Ledger.move("player",civ_id,good,minf(amount,held))
	if sent<=0.0: return 0.0
	Ledger.ensure_pair("player",civ_id)
	Ledger._book_pair("player",civ_id,good,sent)
	Ledger.note_kind("player",civ_id,"gift",sent*Ledger.Prices.value(good,"player"))
	Ledger._warm(civ_id,"player",Ledger._goodwill(sent*Ledger.Prices.value(good,"player"),civ_id))
	var p:=Ledger.pair("player",civ_id)
	if not p.is_empty() and String(p.form) in ["gift","barter"]: p["owed"]=float(p.get("owed",0.0))+(sent*Ledger.Prices.value(good,"player"))*(1.0 if String(p.a)=="player" else -1.0)
	return sent

## Days of food our stores hold now (the food system's own count).
static func _food_days()->float:
	var need:=maxf(1.0,float(GameState.simulation_metrics.get("food_consumption",GameState.population_exact)))
	return FoodSystem.total_stored()/need

## The envoy who goes to propose a standing compact of trade (as before).
static func _envoy(civ_id:String)->String:
	var civ:=Ledger.civ(civ_id)
	if civ.is_empty() or String((civ.get("player_relation",{}) as Dictionary).get("treaty","none"))=="trade": return ""
	var cc:=load(CC_PATH) as GDScript
	if cc==null: return ""
	var sent:Dictionary=cc.call("dispatch_envoy",civ,"trade","")
	return String(sent.get("says","")) if bool(sent.get("ok",false)) else ""

static func _or(names:PackedStringArray)->String:
	if names.size()<=1: return "".join(names)
	return "%s or %s" % [", ".join(names.slice(0,names.size()-1)),names[names.size()-1]]

static func _cap(text:String)->String:
	return text.substr(0,1).to_upper()+text.substr(1) if text!="" else text

static func _lower_first(text:String)->String:
	return text.substr(0,1).to_lower()+text.substr(1) if text!="" else text

# --------------------------------------------------------------------------
# The court's hook
# --------------------------------------------------------------------------

## The trade order in these words, carried out and answered, or {}.
static func hear(id:String,audience:Dictionary,clean:String,context:Dictionary)->Dictionary:
	if audience.is_empty() or String(audience.get("origin",""))=="foreign" or bool(context.get("insist",false)): return {}
	var reading:=read(clean,audience)
	if reading.is_empty(): return {}
	var cc:=load(CC_PATH) as GDScript
	var list:Array=cc.call("roster",audience)
	var speaker:Dictionary=cc.call("_speaker_entry",list)
	if not bool(context.get("echoed",false)):
		Hall.append_line(id,{"speaker":"You","role":"ruler","person_id":0,"civ_id":"","text":clean,"day":Hall._day(),"aside":false})
		audience["echoed_here"]=clean
	audience.erase("pending_command")
	var done:=perform(reading)
	var r:={"handled":true,"ok":true,"act":"command","verb":"order","text":clean,"insist":false,"actor":speaker.duplicate(),"target":{},
		"actor_name":String(speaker.get("name","")),"target_name":"","executed":bool(done.ok) and int(done.count)>0,"terminal":false,"removed":false,
		"outcome":String(done.outcome),"stage":"order" if bool(done.ok) else "none","reaction":"neutral","effects":{},"obedience":{"id":"obey","manner":"guards"},"witness_ids":[],
		"route":"home","home":done.duplicate(),"actor_says":String(done.says),"trade":done.duplicate()}
	return r

# --------------------------------------------------------------------------
# The office's buttons (court_office_orders.gd): one blank each
# --------------------------------------------------------------------------

## [{label, name, items:[{label, text}]}] for the peoples we know.
static func menus()->Array:
	var peoples:=known_peoples()
	if peoples.is_empty(): return []
	var trade:Array=[]; var stop:Array=[]; var squeeze:Array=[]; var tribute:Array=[]; var gifts:Array=[]; var toll:Array=[]; var favour:Array=[]; var ask:Array=[]
	for p:Dictionary in peoples.slice(0,8):
		var people:=String(p.name)
		var the:="the "+people.trim_prefix("The ").trim_prefix("the ")
		trade.append({"label":people,"text":"Trade with %s" % the})
		stop.append({"label":people,"text":"Stop all trade with %s" % the})
		var most:=Ledger.most_needed(String(p.id),"player")
		var good:=String(most.get("good","Flint"))
		squeeze.append({"label":"%s: their %s" % [people,Words.good_word(good)],"text":"Buy up %s's %s" % [people,Words.good_word(good)]})
		tribute.append({"label":people,"text":"Demand tribute from %s" % the})
		gifts.append({"label":"%s: 100 food" % people,"text":"Send %s 100 food" % the})
		toll.append({"label":people,"text":"Put a toll on %s's traders" % people})
		favour.append({"label":"%s: our goods" % people,"text":"Flood %s's markets with goods" % people})
		ask.append({"label":people,"text":"What do we trade with %s?" % the})
	return [{"label":"Trade with ▾","name":"TradeWith","items":trade},{"label":"Stop trade ▾","name":"StopTrade","items":stop},{"label":"Squeeze ▾","name":"Squeeze","items":squeeze},
		{"label":"Demand tribute ▾","name":"DemandTribute","items":tribute},{"label":"Send gifts ▾","name":"SendGifts","items":gifts},{"label":"Toll ▾","name":"Toll","items":toll},
		{"label":"Favour ▾","name":"Favour","items":favour},{"label":"What we trade ▾","name":"WhatWeTrade","items":ask}]

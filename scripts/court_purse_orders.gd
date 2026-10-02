extends RefCounted
## THE PURSE AT COURT: the god's orders about the realm's one purse
## (realm_purse.gd), read from plain words, carried out by its own levers and
## answered with the engine's numbers. The Treasurer keeps the purse, or the
## Steward (the Headman) while no Treasurer is named; whoever hears the god's
## word passes it on, and the answer states what was set and what it costs.
##
##   "raise the levy", "lower the levy", "make the levy heavy"   the levy
##   "pay the soldiers", "stop paying the soldiers"             the soldiers' pay
##   "fund the scholars", "stop funding the scholars"           the scholars' keep
##   "hire crews", "let the crews go"                           paid crews
##   "spend 100 on food for the hungry"                         relief bought now
##   "buy food for the hungry towns", "stop buying food"        relief each month
## A levy of fighters ("raise a levy of ten men", "stand the levy down") is the
## war leader's (home_orders.gd), and "tax the rich" a standing policy
## (government_policy_catalog.gd wealth_levy): neither is read here.
## Questions ("how much is in the treasury?", "what does the levy bring in?")
## are answered from the purse's fact sheet (facts(), answer()), offline and
## for the live voice alike (court_facts.gd, court_answers.gd).
##
##   read(text) -> {kind:"levy", level|step} | {kind:"line", line, on}
##                 | {kind:"relief", amount} (amount < 0: buy each month) | {}
##   carry(result, reading) -> the court's result (court_commands._result shape)
##   menus() -> the purse's office buttons (court_office_orders.gd)
##   facts() -> the purse's fact sheet; answer(sheet, question) -> "" or the answer
## Static; preload.

const Purse:=preload("res://scripts/realm_purse.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")

const QUESTION:="(?i)(\\?\\s*[!.]*\\s*$|^\\s*((and|so|then|now|well|but|also)\\s+)?(how|what|where|who|whom|whose|which|when|why|tell me|is (it|there|that|this|the|our)|are (we|they|there|the|our|you)|do (we|they|you|the|our)|does (the|it|our)|can (you|we)|could (you|we)|will (we|they|you|our)|have (we|they|you|the|our)|has (the|our))\\b)"
const NEGATE:="(?i)\\b(stop|stopping|stopped|no longer|don'?t|do not|dont|never|cease|end|halt|withhold|withholding|cut off|suspend|no more|let (?:the |our )?\\w+ go|dismiss|without pay|unpaid|not be paid|not paid)\\b"
## The levy as a due on the harvest, never a levy of fighters.
const LEVY_NOUN:="(?i)\\b(?:the|our|my|this|that|your)\\s+(?:harvest\\s+)?(?:levy|dues|tithe)\\b|\\btax(?:es)?\\b|\\btithes?\\b|\\b(?:light|heavy|heavier|lighter|usual|harsh|low|high)\\s+(?:levy|dues)\\b"
const FIGHTER_LEVY:="(?i)\\blevy of\\b|\\blevies\\b|\\b(men|fighters|warriors|soldiers|spearmen|archers|bowmen|recruits|troops|conscripts)\\b|\\bstand\\b[^.!?]*\\bdown\\b|\\b(disband|drill|train|arm|muster|call up)\\b"
const TAX_THE_RICH:="(?i)\\btax(?:es)?\\s+(?:on\\s+)?(?:the\\s+)?(rich|wealthy|great households|nobles|powerful)\\b|\\b(rich|wealthy)\\s+pay\\b"
const UP:="(?i)\\b(raise|raised|increase|lift|heighten|double|harden|hike|up|more|heavier|higher|squeeze|take more)\\b"
const DOWN:="(?i)\\b(lower|lowered|reduce|cut|lighten|ease|halve|lessen|drop|decrease|soften|less|lighter|take less|relieve)\\b"
const SET_LIGHT:="(?i)\\b(light|lightest|low)\\b"
const SET_USUAL:="(?i)\\b(usual|normal|ordinary|customary|as (?:it was )?before|middling)\\b"
const SET_HEAVY:="(?i)\\b(heavy|heaviest|high|harsh|full)\\b"
const PAY:="(?i)\\b(pay|pays|paying|paid|wages?|keep paying|give (?:the |our )?\\w* ?pay)\\b"
const SOLDIERS:="(?i)\\b(soldiers?|warriors?|fighters?|army|troops|men under arms|spearmen|archers|bowmen|the levy)\\b"
const FUND:="(?i)\\b(fund|funds|funding|support|supporting|pay|paying|feed|feeding|sponsor|endow|keep|keeping|maintain|patron\\w*)\\b"
const SCHOLARS:="(?i)\\b(scholars?|thinkers|lore[- ]?keepers|loremasters|sages|wise ones|researchers|learned (?:men|women|ones))\\b"
const HIRE:="(?i)\\b(hire|hires|hiring|hired|pay|paying|fund|funding|keep|employ)\\b"
const CREWS:="(?i)\\b(crews?|builders|work ?gangs?|workmen|labou?rers|masons|building hands)\\b"
const FOOD:="(?i)\\b(food|rations|grain|bread|meat|relief|provisions)\\b"
const HUNGRY:="(?i)\\b(hungry|starving|famished|poor|in need|short of food|going hungry|famine)\\b"
const SPEND_AMOUNT:="(?i)\\b(?:spend|use|put|lay out|pay|give|set aside)\\s+(\\d[\\d,]*)\\b"
const BUY:="(?i)\\b(buy|buying|bought|purchase|send|sending|bring|get|feed|feeding)\\b"


static func _re(pattern:String)->RegEx:
	var r:=RegEx.new(); r.compile(pattern)
	return r

static func _has(text:String,pattern:String)->bool:
	return _re(pattern).search(text)!=null


# --- Reading the god's words ---------------------------------------------------

static func read(text:String)->Dictionary:
	var lower:=text.strip_edges().to_lower().replace("’","'")
	if lower.is_empty() or _has(lower,QUESTION):return {}
	var negated:=_has(lower,NEGATE)
	# Food bought for the hungry, now ("spend 100 on food for the hungry") or
	# each month ("buy food for the hungry towns"); "stop buying food".
	if (_has(lower,FOOD) or _has(lower,"(?i)\\bfeed\\b")) and (_has(lower,HUNGRY) or _has(lower,"(?i)\\brelief\\b")):
		var amount:=_re(SPEND_AMOUNT).search(lower)
		if amount!=null and not negated:return {"kind":"relief","amount":float(amount.get_string(1).replace(",",""))}
		if _has(lower,BUY) or _has(lower,"(?i)\\brelief\\b"):
			if negated:return {"kind":"line","line":"relief","on":false}
			return {"kind":"relief","amount":-1.0}
	if negated and _has(lower,"(?i)\\b(buying|buy)\\b") and _has(lower,FOOD):return {"kind":"line","line":"relief","on":false}
	# The scholars' keep.
	if _has(lower,SCHOLARS) and (_has(lower,FUND) or negated):
		return {"kind":"line","line":"scholars","on":not negated}
	# Paid crews.
	if _has(lower,CREWS) and (_has(lower,HIRE) or negated) and not _has(lower,"(?i)\\b(build|raise)\\s+(?:a|an|the|more|some)\\b"):
		return {"kind":"line","line":"crews","on":not negated}
	# The soldiers' pay.
	if _has(lower,PAY) and _has(lower,SOLDIERS) and not _has(lower,"(?i)\\bblood[- ]price\\b"):
		return {"kind":"line","line":"army","on":not negated}
	# The levy on the harvest.
	if _has(lower,LEVY_NOUN) and not _has(lower,TAX_THE_RICH):
		var noun:=_re(LEVY_NOUN).search(lower)
		var taxes:=noun!=null and noun.get_string().begins_with("tax")
		if not taxes and _has(lower,FIGHTER_LEVY):return {}
		var level:=""
		if _has(lower,"(?i)\\b(set|make|keep|put|let)\\b") or _has(lower,"(?i)\\b(a|an)\\s+(light|heavy|usual|normal|harsh)\\s+(levy|dues)\\b"):
			if _has(lower,SET_HEAVY):level="heavy"
			elif _has(lower,SET_LIGHT):level="light"
			elif _has(lower,SET_USUAL):level="usual"
		if level!="":return {"kind":"levy","level":level}
		if _has(lower,UP):return {"kind":"levy","step":1}
		if _has(lower,DOWN):return {"kind":"levy","step":-1}
		if _has(lower,SET_HEAVY):return {"kind":"levy","level":"heavy"}
		if _has(lower,SET_LIGHT):return {"kind":"levy","level":"light"}
		if _has(lower,SET_USUAL):return {"kind":"levy","level":"usual"}
	return {}


# --- Carrying it out ---------------------------------------------------------------

## The court's result for a purse order (court_commands._result shape): the
## lever moved, the official's plain answer with the numbers, the narration.
static func carry(r:Dictionary,reading:Dictionary)->Dictionary:
	var done:=perform(reading)
	r.verb="order"
	r["route"]="purse"
	r["purse"]=done.duplicate(true)
	r["actor_says"]=String(done.get("says",""))
	r.outcome=String(done.get("outcome",""))
	r.executed=bool(done.get("ok",false)) and bool(done.get("changed",false))
	r.stage="order" if bool(r.executed) else "none"
	r.reaction="neutral"
	return r

## {ok, changed, kind, says, outcome}: the lever, set by its real mechanic.
static func perform(reading:Dictionary)->Dictionary:
	match String(reading.get("kind","")):
		"levy":return _levy(reading)
		"line":return _line(String(reading.get("line","")),bool(reading.get("on",true)))
		"relief":return _relief(float(reading.get("amount",-1.0)))
	return {"ok":false,"changed":false,"kind":"","says":"","outcome":"Nothing is set in motion: no order about the purse was given."}

static func _amount(value:float)->String:
	return Purse.amount_text(value)

static func _cap(text:String)->String:
	return text.substr(0,1).to_upper()+text.substr(1)

static func _levy(reading:Dictionary)->Dictionary:
	var before:=String(Purse.state().levy)
	var old:=Purse.quote(before)
	var result:=Purse.set_levy(String(reading.level)) if reading.has("level") else Purse.step_levy(int(reading.get("step",0)))
	if not bool(result.get("ok",false)):return {"ok":false,"changed":false,"kind":"levy","says":String(result.get("error","")),"outcome":"Nothing is set in motion: "+String(result.get("error",""))}
	var level:=String(result.level)
	var q:Dictionary=result.quote
	var name:=String(Purse.LEVEL_NAMES[level]).to_lower()
	var store:=Purse.account_name()
	if not bool(result.changed):
		var why:="already %s" % name
		if bool(result.get("at_end",false)):why="already as %s as it goes in this age" % ("heavy" if level=="heavy" else "light")
		return {"ok":true,"changed":false,"kind":"levy","level":level,
			"says":"The levy is %s: %s of %s, about %s a season into %s." % [why,String(q.words),Purse.harvest_word(),_amount(float(q.per_season)),store],
			"outcome":"Nothing is changed: the levy was %s." % why}
	var trust:=float(q.trust)-float(old.trust)
	var goodwill:=""
	if absf(trust)>=0.5:goodwill=", and trust in you %s about %d %s" % ["falls" if trust>0.0 else "rises",maxi(1,roundi(absf(trust))),"point" if roundi(absf(trust))==1 else "points"]
	return {"ok":true,"changed":true,"kind":"levy","level":level,"before":before,"per_season":float(q.per_season),"before_per_season":float(old.per_season),"hidden_one_in":int(q.hidden_one_in),
		"says":"The levy is %s now: %s of %s. It should bring about %s a season into %s, against %s before. About 1 in %d will hide what they owe%s." % [name,String(q.words),Purse.harvest_word(),_amount(float(q.per_season)),store,Purse.number(float(old.per_season)),int(q.hidden_one_in),goodwill],
		"outcome":"The levy is set %s: %s of %s." % [name,String(q.words),Purse.harvest_word()]}

static func _line(line:String,on:bool)->Dictionary:
	var was:=Purse.line_on(line)
	var result:=Purse.set_line(line,on)
	if not bool(result.get("ok",false)):return {"ok":false,"changed":false,"kind":"line","says":String(result.get("error","")),"outcome":"Nothing is set in motion: no such spending."}
	var store:=Purse.account_name()
	var per:=float(result.cost_per_season)
	var f:=Purse.forecast()
	var who:=String(((f.lines as Dictionary).get(line,{}) as Dictionary).get("who",""))
	var out:={"ok":true,"changed":bool(result.changed),"kind":"line","line":line,"on":on,"per_season":per}
	if not bool(result.changed):
		out.says="%s %s already." % [_cap(String(LINE_WORDS[line][0])),"is under way" if on else "is stopped"] if line!="army" else ("The soldiers are paid from %s already: about %s a season." % [store,_amount(per)] if on else "The soldiers' pay is stopped already.")
		out.outcome="Nothing is changed: %s %s already." % [String(LINE_WORDS[line][0]),"was under way" if on else "was stopped"]
		return out
	if not on:
		match line:
			"army":out.says="Their pay is stopped. Unpaid, their will falls about %d points a month, they are slower to muster, and about 1 in 50 of those at home will go home each month, 1 in 25 after three months." % roundi(100.0*0.06)
			"scholars":out.says="The scholars' keep is stopped: their work goes at its old pace."
			"crews":out.says="The hired crews are let go: building goes at its old pace."
			"relief":out.says="No more food is bought for hungry towns."
		out.outcome="%s: stopped." % _cap(String(LINE_WORDS[line][0]))
		return out
	var short:=""
	var income:=float(f["in"])
	if float(f.out)>income+0.5:short=" All that is paid now comes to %s a season, more than the levy brings in (%s): %s holds %s." % [_amount(float(f.out)),Purse.number(income),store,_amount(Purse.balance())]
	match line:
		"army":out.says="The soldiers are paid from %s: about %s a season in %s, for %s.%s" % [store,_amount(per),Purse.pay_word(),who,short]
		"scholars":out.says="The scholars are kept from %s: about %s a season for %s. Their work goes about %d in 100 faster while they are paid.%s" % [store,_amount(per),who,roundi(Purse.SCHOLARS_MAX*100.0),short]
		"crews":out.says="Crews are hired from %s: about %s a season for %s. Building goes about %d in 100 faster while they are paid.%s" % [store,_amount(per),who,roundi(Purse.CREWS_MAX*100.0),short]
		"relief":out.says="Food will be bought for hungry towns each month, up to a quarter of %s." % store
	out.outcome="%s from %s." % [_cap(String(LINE_WORDS[line][1])),store]
	return out

const LINE_WORDS:={"army":["the soldiers' pay","the soldiers' pay comes"],"scholars":["the scholars' keep","the scholars are kept"],"crews":["paid crews","crews are hired"],"relief":["food for hungry towns","food for hungry towns is bought"]}

static func _relief(amount:float)->Dictionary:
	var store:=Purse.account_name()
	var standing:=amount<0.0
	var budget:=Purse.balance()*Purse.RELIEF_SHARE if standing else amount
	var turned:={}
	if standing:turned=Purse.set_line("relief",true)
	var bought:=Purse.buy_relief(budget)
	var out:={"ok":float(bought.spent)>0.0 or standing,"changed":float(bought.spent)>0.0 or bool(turned.get("changed",false)),"kind":"relief","spent":float(bought.spent),"rations":float(bought.rations),"deliveries":bought.deliveries}
	var parts:PackedStringArray=[]
	for d:Dictionary in bought.deliveries:
		parts.append("%s rations from %s to %s at %s a ration, %d %s on the road" % [Purse.number(float(d.rations)),String(d.from),String(d.to),Purse.number(float(d.price)),int(d.days),"day" if int(d.days)==1 else "days"])
	var now:=""
	if float(bought.spent)>0.0:now="Bought %s: %s from %s." % ["; ".join(parts),_amount(float(bought.spent)),store]
	else:now="Nothing is bought now: %s." % String(bought.reason)
	if standing:
		out.says="Food will be bought for hungry towns each month, up to a quarter of %s. %s" % [store,now]
		out.outcome="Food for hungry towns is bought each month from %s." % store
	else:
		out.says=now
		out.outcome=("Food bought for the hungry: %s rations." % Purse.number(float(bought.rations))) if float(bought.spent)>0.0 else "Nothing is set in motion: %s." % String(bought.reason)
	return out


# --- The office's buttons -------------------------------------------------------------

## The purse's business as plain choices (court_office_orders.gd): each item
## is the words the god could type.
static func menus()->Array:
	var out:Array=[]
	var levels:Array=[]
	for level:String in Purse.LEVELS:
		var q:=Purse.quote(level)
		levels.append({"label":"%s: %s" % [String(Purse.LEVEL_NAMES[level]),String(q.words)],"text":"Set the levy to %s" % level})
	out.append({"label":"The levy ▾","name":"Levy","items":levels})
	out.append({"label":"Stop paying the soldiers" if Purse.line_on("army") else "Pay the soldiers","name":"PayArmy","text":"Stop paying the soldiers" if Purse.line_on("army") else "Pay the soldiers"})
	out.append({"label":"Stop funding the scholars" if Purse.line_on("scholars") else "Fund the scholars","name":"Scholars","text":"Stop funding the scholars" if Purse.line_on("scholars") else "Fund the scholars"})
	out.append({"label":"Let the crews go" if Purse.line_on("crews") else "Hire crews","name":"Crews","text":"Let the crews go" if Purse.line_on("crews") else "Hire crews"})
	var held:=Purse.balance()
	var food:Array=[]
	for share in [0.1,0.25]:
		var n:=_round_amount(held*float(share))
		if n>0:food.append({"label":"Spend %s" % EraWords.grouped(n),"text":"Spend %d on food for the hungry" % n})
	food.append({"label":"Stop buying each month","text":"Stop buying food for the hungry"} if Purse.line_on("relief") else {"label":"Buy each month","text":"Buy food for the hungry towns every month"})
	out.append({"label":"Food for the hungry ▾","name":"Relief","items":food})
	return out

## A plain amount near `value`: 10, 20, 50, 100, 200, 500 ...
static func _round_amount(value:float)->int:
	if value<10.0:return 0
	var scale:=pow(10.0,floorf(log(value)/log(10.0)))
	for step in [5.0,2.0,1.0]:
		if value>=scale*step:return int(scale*step)
	return int(scale)


# --- What the keeper of the purse knows ---------------------------------------------------

## The purse's fact sheet (court_facts.gd "purse"): exact figures in its unit.
static func facts()->Dictionary:
	var purse:=Purse.state()
	var f:=Purse.forecast()
	var q:Dictionary=f.quote
	var lines:={}
	for line:String in Purse.LINES:
		var entry:Dictionary=(f.lines as Dictionary).get(line,{})
		lines[line]={"on":bool(entry.get("on",false)),"per_season":roundi(float(entry.get("per_season",0.0))),"who":String(entry.get("who",""))}
	var shares:Array=WorldSimulation.state.wealth_shares
	return {"name":Purse.account_name(),"unit":Purse.unit_word(),"balance":roundi(float(purse.balance)),"levy":String(purse.levy),"levy_words":String(q.words),"harvest":Purse.harvest_word(),
		"levy_season":roundi(float(f["in"])),"hidden_one_in":int(q.hidden_one_in),"lines":lines,"out_season":roundi(float(f.out)),"unpaid_months":int(purse.get("unpaid_months",0)),
		"deserted":int(purse.get("deserted",0)),"debt":roundi(float(purse.get("debt",0.0))),"pay":Purse.pay_word(),
		"top_fifth":roundi(float(shares[4])*100.0) if shares.size()==5 else 35,"bottom_fifth":roundi(float(shares[0])*100.0) if shares.size()==5 else 8}

## The sheet as prompt lines for the live voice (plain, exact figures).
static func text(p:Dictionary)->String:
	if p.is_empty():return ""
	var paid:PackedStringArray=[]
	for line:String in Purse.LINES:
		var entry:Dictionary=(p.lines as Dictionary).get(line,{})
		paid.append("%s %s (%s)" % [String(LINE_WORDS[line][0]),EraWords.grouped(int(entry.get("per_season",0))) if line!="relief" else "as needed","on" if bool(entry.get("on",false)) else "off"])
	var said:="The realm's account is %s, counted in %s: it holds %s. The levy is %s, %s of %s; it brings about %s a season, and about 1 in %d hide what they owe. Paid from it a season: %s." % [String(p.name),String(p.unit),EraWords.grouped(int(p.balance)),String(p.levy),String(p.levy_words),String(p.harvest),EraWords.grouped(int(p.levy_season)),int(p.hidden_one_in),"; ".join(paid)]
	if int(p.unpaid_months)>0:said+=" The soldiers have gone short of their pay %d %s running." % [int(p.unpaid_months),"month" if int(p.unpaid_months)==1 else "months"]
	if int(p.debt)>0:said+=" Old debts owed by the realm: %s." % EraWords.grouped(int(p.debt))
	said+=" The richest fifth of our households hold %d in every 100 parts of the wealth; the poorest fifth %d." % [int(p.top_fifth),int(p.bottom_fifth)]
	return said

const ASKS_BALANCE:="(?i)\\b(treasury|purse|common store|silver store|how much (?:silver|coin|money|wealth)|what (?:do|have) we (?:in|got in) (?:the )?(?:treasury|purse|store))\\b"
const ASKS_LEVY:="(?i)\\b(levy|levies|tax|taxes|dues|tithe)\\b"
const ASKS_SPENDING:="(?i)\\b(spend|spending|spent|pay for|pays for|going out|goes out|outgo|costs?)\\b"
const ASKS_ARMY_PAY:="(?i)\\b(soldiers|army|warriors|fighters|troops)\\b[^?]*\\b(paid|pay|pays|wages?)\\b|\\b(paid|pay|pays|wages?)\\b[^?]*\\b(soldiers|army|warriors|fighters|troops)\\b"
const ASKS_WEALTH:="(?i)\\b(richest|the rich|wealthy|the poor|poorest|inequal\\w*|who holds the wealth|how is the wealth)\\b"

## The answer to a question about the purse, from its sheet, or "".
static func answer(sheet:Dictionary,lower:String)->String:
	var p:Dictionary=sheet.get("purse",{}) if sheet.get("purse") is Dictionary else {}
	if p.is_empty():return ""
	var name:=_cap(String(p.name))
	var unit:=String(p.unit)
	var army:Dictionary=(p.lines as Dictionary).get("army",{})
	if _has(lower,ASKS_ARMY_PAY):
		if int(p.unpaid_months)>0:return "The soldiers have gone short of their pay %d %s running; %s holds %s %s, and their pay comes to about %s a season." % [int(p.unpaid_months),"month" if int(p.unpaid_months)==1 else "months",String(p.name),EraWords.grouped(int(p.balance)),unit,EraWords.grouped(int(army.get("per_season",0)))]
		if not bool(army.get("on",false)):return "Their pay is stopped. It would come to about %s %s a season." % [EraWords.grouped(int(army.get("per_season",0))),unit]
		return "The soldiers are paid in %s: about %s %s a season, from %s, which holds %s." % [String(p.pay),EraWords.grouped(int(army.get("per_season",0))),unit,String(p.name),EraWords.grouped(int(p.balance))]
	if _has(lower,ASKS_WEALTH):
		return "The richest fifth of our households hold %d in every 100 parts of what we have; the poorest fifth %d." % [int(p.top_fifth),int(p.bottom_fifth)]
	if _has(lower,ASKS_LEVY):
		return "The levy is %s: %s of %s. It brings in about %s %s a season, after about 1 in %d hide what they owe." % [String(p.levy),String(p.levy_words),String(p.harvest),EraWords.grouped(int(p.levy_season)),unit,int(p.hidden_one_in)]
	if _has(lower,ASKS_SPENDING):
		return _spending(p)
	if _has(lower,ASKS_BALANCE):
		return "%s holds %s %s. The levy brings in about %s a season; %s" % [name,EraWords.grouped(int(p.balance)),unit,EraWords.grouped(int(p.levy_season)),_spending(p,true)]
	return ""

static func _spending(p:Dictionary,short:=false)->String:
	var paid:PackedStringArray=[]
	for line:String in Purse.LINES:
		var entry:Dictionary=(p.lines as Dictionary).get(line,{})
		if not bool(entry.get("on",false)):continue
		paid.append("%s about %s" % [String(LINE_WORDS[line][0]),EraWords.grouped(int(entry.get("per_season",0)))] if line!="relief" else "food for hungry towns as they need it")
	if paid.is_empty():return "nothing is paid from it." if short else "Nothing is paid from %s now." % String(p.name)
	var said:="; ".join(paid)
	return ("out of it go %s a season." % said) if short else "Paid from %s a season: %s; about %s in all." % [String(p.name),said,EraWords.grouped(int(p.out_season))]

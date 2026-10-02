extends RefCounted
## BUSINESS AT COURT: the god's stance on the people's business sector
## (enterprise.gd), read from plain words, set by its own lever and answered
## with the engine's numbers. The Treasurer keeps it with the purse, or the
## Steward (the Headman) while no Treasurer is named.
##
##   "guard the trades", "keep the guilds' rules"             Guarded
##   "grant charters", "sell the right to trade"               Chartered
##   "open the markets to all", "let anyone trade"             Open
##   "let the state run the works", "nationalize the works"    State works
## "free the markets" is a standing policy (government_policy_catalog.gd
## market_deregulation), "trade with the Esurai" the Envoy's (court_trade.gd),
## "guard the gate" the war leader's: none is read here. Questions ("how is
## business?", "what do the merchant houses bring us?") are answered from the
## business fact sheet (facts(), answer()), offline and for the live voice.
##
##   read(text) -> {kind:"business", stance} | {}
##   carry(result, reading) -> the court's result (court_commands._result shape)
##   menus() -> the Business office button (court_office_orders.gd)
##   facts() -> the business fact sheet; answer(sheet, question) -> "" or the answer
## Static; preload.

const Business:=preload("res://scripts/enterprise.gd")
const Purse:=preload("res://scripts/realm_purse.gd")
const PurseOrders:=preload("res://scripts/court_purse_orders.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")

const NEGATE:="(?i)\\b(stop|stopping|no longer|don'?t|do not|dont|never|cease|halt|no more|not|refuse|forbid)\\b"
## Words that hand the line to another office.
const ELSEWHERE:="(?i)\\bfree (?:the |our )?markets?\\b|\\b(deregulat\\w*|liberali[sz]e|price controls?)\\b|\\btrade with\\b|\\b(gates?|walls?|camp|border|ford|bridge|road|roads|stores?|granar\\w*|well|wells)\\b"
const OPEN:="(?i)\\bopen (?:up )?(?:the |our )?(?:markets?|trades?|business|commerce)(?: (?:to|for) (?:all|everyone|anyone|all comers))?\\b|\\blet (?:anyone|everyone|any man|all comers|whoever will) (?:trade|open (?:a )?shops?|set up (?:a )?(?:shops?|trades?|business))\\b|\\bfree enterprise\\b|\\bbusiness (?:open|free)\\b|\\bopen stance\\b"
const CHARTER:="(?i)\\b(?:grant|give|sell|issue|award)\\w* (?:out )?(?:royal |trade |trading )?(charters?|licen[cs]es?)\\b|\\bcharter (?:the |our )?(?:trades|merchants?|guilds?|houses|companies|traders)\\b|\\bsell (?:the )?right to trade\\b|\\bcharters? (?:for|at) a fee\\b|\\bchartered\\b"
const GUARD:="(?i)\\bguard (?:the |our )?(?:trades|crafts|guilds|markets)\\b|\\b(?:protect|shelter) (?:the |our )?(?:trades|crafts)\\b|\\bkeep (?:the |our )?(?:trades|crafts|business) (?:under|by|to) (?:the )?(?:guilds?|rules|custom)\\b|\\bkeep (?:the |our )?guilds'? rules\\b|\\bguilds and rules\\b|\\brein in (?:the |our )?(?:merchants?|trades|houses|companies|traders|business)\\b|\\bguarded\\b"
const STATE:="(?i)\\b(?:let |have |make )?the state (?:run|own|take over|take|hold|manage)s? (?:the |our )?(?:great )?(?:works|industries|trades|mills|factories)\\b|\\bnationali[sz]e (?:the |our )?(?:great )?(?:works|industries|trades|mills|factories|business)\\b|\\bstate works\\b"
const QUESTION:="(?i)(\\?\\s*[!.]*\\s*$|^\\s*((and|so|then|now|well|but|also)\\s+)?(how|what|where|who|whom|whose|which|when|why|should|shall|tell me|is (it|there|that|this|the|our)|are (we|they|there|the|our|you)|do (we|they|you|the|our)|does (the|it|our)|can (you|we)|could (you|we)|would|will (we|they|you|our)|have (we|they|you|the|our)|has (the|our))\\b)"


static func _re(pattern:String)->RegEx:
	var r:=RegEx.new(); r.compile(pattern)
	return r

static func _has(text:String,pattern:String)->bool:
	return _re(pattern).search(text)!=null


# --- Reading the god's words ---------------------------------------------------

static func read(text:String)->Dictionary:
	var lower:=text.strip_edges().to_lower().replace("’","'")
	if lower.is_empty() or _has(lower,QUESTION) or _has(lower,NEGATE):return {}
	if _has(lower,"(?i)\\bif\\b|\\bsuppose\\b|\\bthe elders say\\b"):return {}
	var state:=_has(lower,STATE)
	var open:=_has(lower,OPEN)
	var charter:=_has(lower,CHARTER)
	var guard:=_has(lower,GUARD)
	if not (state or open or charter or guard):return {}
	if _has(lower,ELSEWHERE) and not (state or charter):return {}
	var found:=0
	for hit in [state,open,charter,guard]:
		if hit:found+=1
	if found!=1:return {}
	if state:return {"kind":"business","stance":"state"}
	if open:return {"kind":"business","stance":"open"}
	if charter:return {"kind":"business","stance":"chartered"}
	return {"kind":"business","stance":"guarded"}


# --- Carrying it out ---------------------------------------------------------------

## The court's result for a business order (court_commands._result shape).
static func carry(r:Dictionary,reading:Dictionary)->Dictionary:
	var done:=perform(reading)
	r.verb="order"
	r["route"]="business"
	r["business"]=done.duplicate(true)
	var said:=String(done.get("says",""))
	var keeper:=PurseOrders.keeper_of_purse()
	var actor:Dictionary=r.get("actor",{}) if r.get("actor") is Dictionary else {}
	if not keeper.is_empty() and int(actor.get("person_id",0))>0 and int(actor.get("person_id",0))!=int(keeper.get("person_id",0)) and said!="":
		said="%s keeps the trades' rules; I have sent your word. %s" % [String(keeper.get("name","")).get_slice(" ",0),said]
	r["actor_says"]=said
	r.outcome=String(done.get("outcome",""))
	r.executed=bool(done.get("ok",false)) and bool(done.get("changed",false))
	r.stage="order" if bool(r.executed) else "none"
	r.reaction="neutral"
	return r

## {ok, changed, stance, says, outcome}: the stance, set by its real lever.
static func perform(reading:Dictionary)->Dictionary:
	var id:=String(reading.get("stance",""))
	var result:=Business.set_stance(id)
	if not bool(result.get("ok",false)):
		var why:=String(result.get("error",""))
		return {"ok":false,"changed":false,"stance":id,"says":why,"outcome":"Nothing is set in motion: "+why}
	var q:Dictionary=result.quote
	var name:=Business.stance_name(id)
	if not bool(result.changed):
		return {"ok":true,"changed":false,"stance":id,"says":"Business is %s already: %s. %s" % [name.to_lower(),String(q.words).to_lower(),_effect_sentence(q)],"outcome":"Nothing is changed: business was %s already." % name.to_lower()}
	var says:="Business is %s now: %s. " % [name.to_lower(),String(q.words).to_lower()]
	if Business.rung()<1:
		says+="There is no business beyond the household yet: it needs %s. Your word stands for when there is." % Business.next_needs()
	else:
		says+=_effect_sentence(q)
		if float(result.trust)>0.0:says+=" Trust in you falls %d points for the change." % roundi(float(result.trust)*100.0)
	return {"ok":true,"changed":true,"stance":id,"before":String(result.before),"trust":float(result.trust),"target":float(q.target),"work":float(q.work),"bust_year":float(q.bust_year),
		"says":says,"outcome":"Business is set %s." % name.to_lower()}

## "As the trades grow toward 4 in 100 of our workers, all work goes about
## 0.6% faster ... Busts: about 1 in 160 years."
static func _effect_sentence(q:Dictionary)->String:
	if Business.rung()<1:return ""
	var said:="As %s grow toward %s of our workers, all work goes %s faster and the richest fifth gain about %d %s in 100." % [_who(),Business.in_100(float(q.target)),Business.percent(float(q.work)).trim_prefix("+"),roundi(float(q.rich)*100.0),"part" if roundi(float(q.rich)*100.0)==1 else "parts"]
	if float(q.purse_season)>=0.5:said+=" %s bring about %s a season into %s." % [String(q.purse_name),Purse.amount_text(float(q.purse_season)),Purse.account_name()]
	said+=" Busts: %s." % String(q.odds).to_lower()
	return said

## The trades, by the rung: "the stalls and workshops", "the merchant houses".
static func _who()->String:
	match Business.rung():
		1:return "the stalls and hired workshops"
		2:return "the merchant houses and guilds"
		3:return "the banking houses and partnerships"
		4:return "the chartered companies"
		5:return "the corporations"
	return "the trades"


# --- The office's buttons -------------------------------------------------------------

## The business stance as plain choices (court_office_orders.gd), once the
## people have business beyond the household.
static func menus()->Array:
	if Business.rung()<1:return []
	var items:Array=[]
	for id:String in Business.choices():
		var q:=Business.quote(id)
		items.append({"label":"%s: %s work" % [Business.stance_name(id),Business.percent(float(q.work))],"text":String(MENU_WORDS[id])})
	return [{"label":"Business ▾","name":"Business","items":items}]

const MENU_WORDS:={"guarded":"Guard the trades with guilds and rules","chartered":"Grant charters to the trades for a fee","open":"Open the markets to all","state":"Let the state run the great works"}


# --- What the keeper knows ---------------------------------------------------------------

## The business fact sheet (court_facts.gd, with the purse): exact figures.
static func facts()->Dictionary:
	var r:=Business.rung()
	var id:=Business.stance()
	var x:=Business.effects()
	var q:=Business.quote(id)
	var form:=Business.form()
	return {"rung":r,"rung_name":Business.rung_name(r),"next":Business.rung_name(r+1) if r<Business.RUNGS.size()-1 else "","next_needs":Business.next_needs(),
		"share":roundi(Business.share()*1000.0)/10.0,"target":roundi(Business.target()*1000.0)/10.0,"stance":id,"stance_name":Business.stance_name(id),"stance_words":Business.stance_words(id),
		"work":roundi(float(x.work)*1000.0)/10.0,"trade":roundi(float(x.trade)*100.0),"rich":roundi(float(x.rich)*100.0),"odds":String(q.odds),"one_in":roundi(1.0/float(q.bust_year)) if float(q.bust_year)>0.0 else 0,
		"booming":Business.booming(),"bust_left":Business.bust_left(),"form":String((Business.FORMS.get(form,{}) as Dictionary).get("name","")),
		"purse_name":String(q.purse_name),"purse_season":roundi(float(Purse.charter_per_day())*Purse.SEASON_DAYS),"unit":Purse.unit_word(),"choices":Business.choices()}

## The sheet as prompt lines for the live voice (plain, exact figures).
static func text(p:Dictionary)->String:
	if p.is_empty():return ""
	if int(p.rung)<1:return "Business: none beyond household crafts yet; it needs %s." % String(p.next_needs)
	var said:="Business: %s. %s in 100 of our workers are in it, heading for %s. The stance is %s (%s). It adds %s%% to all work and goods, trade reach +%d, and the richest fifth +%d parts in 100. Busts: %s." % [String(p.rung_name).to_lower(),_num(float(p.share)),_num(float(p.target)),String(p.stance_name),String(p.stance_words).to_lower(),_num(float(p.work)),int(p.trade),int(p.rich),String(p.odds).to_lower()]
	if int(p.purse_season)>0:said+=" %s bring %s %s a season into the purse." % [String(p.purse_name),EraWords.grouped(int(p.purse_season)),String(p.unit)]
	if bool(p.booming):said+=" The trades are booming: credit is running high."
	if int(p.bust_left)>0:said+=" A bust is still felt: %d more %s of slower work." % [int(p.bust_left),"month" if int(p.bust_left)==1 else "months"]
	if String(p.form)!="":said+=" Our crafts are organized as %s." % String(p.form).to_lower()
	if String(p.next)!="":said+=" Next: %s, which needs %s." % [String(p.next).to_lower(),String(p.next_needs)]
	return said

static func _num(value:float)->String:
	return ("%.1f" % value).trim_suffix(".0")

const ASKS:="(?i)\\b(business|businesses|enterprise|merchant houses?|merchants|trading houses?|guilds?|companies|company|corporations?|stalls|hired workshops|banking houses|bankers|the trades|charters?|charter fees|booms?|booming|busts?|bubbles?)\\b"

## The answer to a question about business, from its sheet, or "".
static func answer(sheet:Dictionary,lower:String)->String:
	var p:Dictionary=sheet.get("business",{}) if sheet.get("business") is Dictionary else {}
	if p.is_empty() or not _has(lower,ASKS):return ""
	if int(p.rung)<1:return "We have no business beyond household crafts yet. It needs %s." % String(p.next_needs)
	if _has(lower,"(?i)\\b(busts?|booms?|booming|bubbles?|fail\\w*|crash\\w*)\\b"):
		var now:=""
		if int(p.bust_left)>0:now=" A bust is still felt: work goes slower for %d more %s." % [int(p.bust_left),"month" if int(p.bust_left)==1 else "months"]
		elif bool(p.booming):now=" They are booming now, on credit, and that raises the odds while it lasts."
		return "Under the %s stance, busts come %s.%s" % [String(p.stance_name).to_lower(),String(p.odds).to_lower(),now]
	if _has(lower,"(?i)\\b(charters?|charter fees|fees)\\b") and int(p.purse_season)>0:
		return "%s bring about %s %s a season into %s." % [String(p.purse_name),EraWords.grouped(int(p.purse_season)),String(p.unit),Purse.account_name()]
	return "%s: %s in 100 of our workers, heading for %s, under the %s stance. They add %s%% to all work and goods, carry our trade +%d further, and the richest fifth hold %d parts in 100 more. Busts: %s." % [String(p.rung_name),_num(float(p.share)),_num(float(p.target)),String(p.stance_name).to_lower(),_num(float(p.work)),int(p.trade),int(p.rich),String(p.odds).to_lower()]

extends RefCounted
## TRADE IN PLAIN WORDS: every line the Trade page, the War screen, the alerts
## under the clock, the chronicle and the court say about trade between
## peoples, read from the trade ledger's own numbers (trade_ledger.gd,
## trade_stances.gd). Nothing here is kept apart from the ledger.
##
## Labels and alert lines stay within MAX_WORDS words. Before money the words
## are gifts and goods; "silver" once weighed metal changes hands; "coin" once
## coin does (the pair's form). Static; preload.

const Ledger:=preload("res://scripts/trade_ledger.gd")
const Stances:=preload("res://scripts/trade_stances.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const Names:=preload("res://scripts/resource_names.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")

const MAX_WORDS:=12
## [label, what it does] for the stance buttons (the numbers come from the
## engine in tip()).
const LABELS:={"free":"Trade freely","favour":"Favour","toll":"Toll","embargo":"Embargo","squeeze":"Squeeze","tribute":"Demand tribute","gifts":"Send gifts"}
const SHORT:={"free":"trading freely","favour":"favoured","toll":"tolled","embargo":"embargoed","squeeze":"squeezed","tribute":"asked for tribute","gifts":"sent gifts"}
const ANSWER_WORDS:={"yield":"yield","supplier":"find others","counter":"strike back","raid":"raid traders","war":"war","bear":"bear it"}
## Alerts: [tone, kinds]. Red when it strikes at us, amber for what wants seeing to.
const RED_NEWS:=["embargo","squeeze","toll","raided","war","tribute_stopped"]
const ALERT_NEWS:=["partner","meeting","embargo","squeeze","toll","yield","shortage","raided","war","counter","supplier","lifted","tribute_stopped"]

# --------------------------------------------------------------------------
# Goods and numbers
# --------------------------------------------------------------------------

## The people's word for a good: "flint", "food", "salt", "goods", ores by
## what the people can see until they know the metal.
static func good_word(good:String)->String:
	match good:
		"Civilian Goods": return "goods"
		"Fiber Plants": return "plant fiber"
		"Medicinal Plants": return "healing herbs"
	return Names.label(good).to_lower()

static func qty(value:float)->String:
	if value>=10.0: return EraWords.grouped(roundi(value))
	if value>=1.0: return str(roundi(value))
	if value>=0.1: return "a little"
	return "a scrap of"

## "12 flint", "1,200 food", "a little salt".
static func amount(value:float,good:String)->String:
	return "%s %s" % [qty(value),good_word(good)]

## How often a pair settles: a season for gifts and barter, a month for priced trade.
static func period_word(form:String)->String:
	return "a month" if form in ["silver","coin"] else "a season"

static func per_period(monthly:float,form:String)->float:
	return monthly*(1.0 if form in ["silver","coin"] else 3.0)

## The money a pair settles in.
static func medium(form:String)->String:
	match form:
		"silver": return "silver"
		"coin": return "coin"
		"barter": return "goods for goods"
	return "gifts"

static func form_words(form:String)->String:
	match form:
		"gift": return "gifts each season"
		"barter": return "barter each season"
		"silver": return "trade for silver"
		"coin": return "trade for coin"
	return form

## "3 in 10", "all", "1 in 20".
static func share_words(share:float)->String:
	if share>=0.95: return "all"
	if share>=0.095: return "%d in 10" % clampi(roundi(share*10.0),1,9)
	if share>=0.02: return "1 in %d" % clampi(roundi(1.0/share),11,50)
	return "almost none"

## A chance in the same words: "3 in 10", "1 in 20".
static func chance_words(p:float)->String:
	if p>=0.95: return "almost sure"
	if p>=0.095: return "%d in 10" % clampi(roundi(p*10.0),1,9)
	if p>=0.01: return "1 in %d" % clampi(roundi(1.0/p),11,100)
	return "almost none"

static func days_words(days:float)->String:
	if days<0.0: return "they would not run short"
	return EraWords.days(days)

static func goods_line(goods:Dictionary,form:String,limit:int=3)->String:
	var rows:Array=[]
	for good:String in goods: rows.append({"good":good,"q":per_period(float(goods[good]),form)})
	rows.sort_custom(func(x:Dictionary,y:Dictionary)->bool: return float(x.q)*Ledger.Prices.base(String(x.good))>float(y.q)*Ledger.Prices.base(String(y.good)))
	var parts:=PackedStringArray()
	for row:Dictionary in rows:
		if float(row.q)<0.05: continue
		parts.append(amount(float(row.q),String(row.good)))
		if parts.size()>=limit: break
	return ", ".join(parts)

static func _short(text:String)->String:
	var words:=text.split(" ",false)
	if words.size()<=MAX_WORDS: return text
	return " ".join(words.slice(0,MAX_WORDS))

static func _the(name:String)->String:
	return name

# --------------------------------------------------------------------------
# One people's row: what flows, the leaning it makes, the stance, the answer
# --------------------------------------------------------------------------

## What flows from `from` to `to` a season (or month): "12 flint, 30 food a season".
static func flow_words(from:String,to:String)->String:
	var p:=Ledger.pair(from,to)
	var form:=String(p.get("form","gift")) if not p.is_empty() else "gift"
	var line:=goods_line(Ledger.flows(from,to),form)
	return ("%s %s" % [line,period_word(form)]) if line!="" else "nothing"

## "Ildor gets 3 in 10 of its flint from us; without it their stores last 40 days."
static func leaning_line(owner:String,from:String)->String:
	var rows:=Ledger.reading(owner,from)
	if rows.is_empty(): return ""
	var top:Dictionary=rows[0]
	if float(top.share)<0.05: return ""
	var who:=Ledger.name_of(owner) if owner!="player" else "We"
	var whom:="us" if from=="player" else Ledger.name_of(from)
	var get:="get" if owner=="player" else "gets"
	var its:="our" if owner=="player" else "its"
	var line:="%s %s %s of %s %s from %s" % [who,get,share_words(float(top.share)),its,good_word(String(top.good)),whom]
	var days:=float(top.days)
	if days>=0.0: line+="; without it %s stores last %s" % ["our" if owner=="player" else "their",EraWords.days(days)]
	else: line+="; without it %s would not run short" % ("we" if owner=="player" else "they")
	return line+"."

## The odds as chips: [["yield","3 in 10"], ...] in roll order, the unlikely dropped.
static func odds_chips(p:Dictionary)->Array:
	var out:Array=[]
	for answer:String in Stances.ANSWERS:
		var chance:=float(p.get(answer,0.0))
		if chance<0.01: continue
		out.append([String(ANSWER_WORDS[answer]),chance_words(chance)])
	return out

## "Their answer: yield 3 in 10 · find others 2 in 10 · bear it 5 in 10".
static func odds_line(p:Dictionary)->String:
	var parts:=PackedStringArray()
	for chip:Array in odds_chips(p): parts.append("%s %s" % [String(chip[0]),String(chip[1])])
	return "Their answer: "+" · ".join(parts) if not parts.is_empty() else ""

## What a stance does, in one or two plain sentences with the engine's numbers.
static func effect_line(preview:Dictionary,actor:String,target:String)->String:
	var form:=String(preview.get("form","gift"))
	var them:=Ledger.name_of(target)
	var per:=period_word(form)
	var money:=Ledger.purse_unit(actor)
	var worth:=func(v:float)->String: return ("%s %s" % [qty(v*(1.0 if form in ["silver","coin"] else 3.0)),money]) if money!="" and form in ["silver","coin"] else "goods worth %s" % qty(v*(1.0 if form in ["silver","coin"] else 3.0))
	match String(preview.get("id","")):
		"free": return "Our traders deal with %s as it comes: %s." % [them,flow_words("player",target) if actor=="player" else "as before"]
		"favour":
			var flood:=String(preview.get("good",""))
			return "We sell to %s a fifth below our price%s; trade grows 4 in 10. It costs us about %s %s." % [them,(" and push our %s on them" % good_word(flood)) if flood!="" else "",worth.call(float(preview.get("cost",0.0))),per]
		"toll":
			return "A tenth of all trade with %s comes to us: about %s %s. Trade falls by a quarter." % [them,worth.call(float(preview.get("gain",0.0))),per]
		"embargo":
			var lost:=flow_words(target,actor)
			return "Nothing passes between us and %s. We lose %s; they lose %s." % [them,lost,flow_words(actor,target)]
		"squeeze":
			var good:=String(preview.get("good",""))
			return "No %s goes to %s, and we buy theirs up from others: about %s %s." % [good_word(good),them,worth.call(float(preview.get("cost",0.0))),per]
		"tribute":
			return "We ask %s for goods worth %s a season, for %d years." % [them,qty(float(preview.get("gain",0.0))),Stances.TRIBUTE_YEARS]
		"gifts":
			return "Each season we send %s gifts worth %s from our plenty." % [them,qty(float(preview.get("cost",0.0)))]
	return ""

## The tip on a stance button: what it does and, for pressure, their odds.
static func tip(id:String,actor:String,target:String,good:String="")->String:
	var preview:=Stances.preview_for(id,actor,target,good)
	var lines:=PackedStringArray([String(preview.get("effect",""))])
	if preview.has("odds"):
		var line:=odds_line((preview.odds as Dictionary).get("p",{}))
		if line!="": lines.append(line+".")
		lines.append("Word reaches them in about %s." % EraWords.days(float(Stances.message_days(actor,target))))
	return "\n".join(lines)

## The last answer they gave: "They bore the embargo · roll 0.62 against yield 0.30".
static func answer_line(actor:String,target:String)->String:
	var s:=Ledger.peek()
	if s.is_empty(): return ""
	var a:Variant=(s.get("answers",{}) as Dictionary).get(Stances.skey(actor,target))
	if not a is Dictionary: return ""
	var answer:Dictionary=a
	var stance:=String(answer.get("stance",""))
	var what:=""
	match String(answer.get("kind","")):
		"yield": what="yielded to the %s" % _stance_noun(stance,String(answer.get("good","")))
		"supplier": what="found another supplier"
		"counter": what="struck back with their own embargo"
		"raid": what="raided our traders"
		"war": what="went to war over it"
		"bear": what="bore the %s" % _stance_noun(stance,String(answer.get("good","")))
	return "Last word: they %s, %s (%s)." % [what,EraWords.ago(int(answer.get("day",-1))),"chance %s" % chance_words(float((answer.get("odds",{}) as Dictionary).get(String(answer.get("kind","")),0.0)))]

static func _stance_noun(stance:String,good:String)->String:
	match stance:
		"embargo": return "embargo"
		"squeeze": return "squeeze on their %s" % good_word(good) if good!="" else "squeeze"
		"toll": return "toll"
		"tribute": return "demand for tribute"
	return stance

## The plain cause, for war and memory: "the flint embargo".
static func cause(st:Dictionary)->String:
	var good:=String(st.get("good",""))
	match String(st.get("id","")):
		"embargo": return "the trade embargo"
		"squeeze": return "the %s embargo" % good_word(good) if good!="" else "the squeeze on their trade"
		"toll": return "the toll on their traders"
		"tribute": return "the demand for tribute"
	return "the trade"

## What they remember of it (ForeignDiplomacy.remember).
static func remembered(st:Dictionary,_actor:String)->String:
	match String(st.get("id","")):
		"embargo": return "The ruler stopped all trade with us."
		"squeeze": return "The ruler cut off our %s and bought it up from others." % good_word(String(st.get("good","")))
		"toll": return "The ruler put a toll on our traders."
		"tribute": return "The ruler demanded tribute from us."
	return "The ruler changed how our traders are met."

## The god's own stance toward a people, and theirs toward us, in a few words.
static func stance_words(owner:String,other:String)->String:
	var st:=Stances.stance(owner,other)
	var id:=String(st.get("id","free"))
	if id=="free": return ""
	var good:=String(st.get("good",""))
	if id=="squeeze" and good!="": return "squeezing their %s" % good_word(good)
	return String(SHORT.get(id,id))

# --------------------------------------------------------------------------
# The Trade page: short labels (MAX_WORDS at most each)
# --------------------------------------------------------------------------

## What flows one way, a season or a month: [[good, quantity], ...] largest worth first.
static func flow_items(from:String,to:String,limit:int=4)->Array:
	var p:=Ledger.pair(from,to)
	var form:=String(p.get("form","gift")) if not p.is_empty() else "gift"
	var rows:Array=[]
	var goods:=Ledger.flows(from,to)
	for good:String in goods:
		var q:=per_period(float(goods[good]),form)
		if q>=0.05: rows.append([good,q])
	rows.sort_custom(func(x:Array,y:Array)->bool: return float(x[1])*Ledger.Prices.base(String(x[0]))>float(y[1])*Ledger.Prices.base(String(y[0])))
	return rows.slice(0,limit)

## "Leans on us for flint: 3 in 10" / "We lean on them for salt: 6 in 10".
static func lean_label(owner:String,from:String)->String:
	var rows:=Ledger.reading(owner,from)
	if rows.is_empty() or float((rows[0] as Dictionary).share)<0.05: return ""
	var top:Dictionary=rows[0]
	if owner=="player": return _short("We lean on them for %s: %s" % [good_word(String(top.good)),share_words(float(top.share))])
	return _short("They lean on us for %s: %s" % [good_word(String(top.good)),share_words(float(top.share))])

## "Without us, their flint lasts 40 days" / "Without them, our salt lasts 25 days".
static func lasts_label(owner:String,from:String)->String:
	var rows:=Ledger.reading(owner,from)
	if rows.is_empty() or float((rows[0] as Dictionary).share)<0.05: return ""
	var top:Dictionary=rows[0]
	var days:=float(top.days)
	if owner=="player":
		return _short("Without them, our %s lasts %s" % [good_word(String(top.good)),EraWords.days(days)]) if days>=0.0 else "Without them, we would not run short"
	return _short("Without us, their %s lasts %s" % [good_word(String(top.good)),EraWords.days(days)]) if days>=0.0 else "Without us, they would not run short"

## "Last word: found another supplier, last season".
static func answer_label(actor:String,target:String)->String:
	var s:=Ledger.peek()
	if s.is_empty(): return ""
	var a:Variant=(s.get("answers",{}) as Dictionary).get(Stances.skey(actor,target))
	if not a is Dictionary: return ""
	var kind:=String((a as Dictionary).get("kind",""))
	var said:={"yield":"they yielded","supplier":"found another supplier","counter":"struck back with an embargo","raid":"they raid our traders","war":"war over it","bear":"they bear it"}
	return _short("Last word: %s, %s" % [String(said.get(kind,kind)),EraWords.ago(int((a as Dictionary).get("day",-1)))])

## Their stance toward us, short: "They embargo us" / "They squeeze our salt".
static func theirs_label(other:String)->String:
	var st:=Stances.stance(other,"player")
	match String(st.get("id","free")):
		"embargo": return "They embargo us"
		"squeeze": return _short("They squeeze our %s" % good_word(String(st.get("good",""))))
		"toll": return "They toll our traders"
		"favour": return "They favour us"
		"gifts": return "They send us gifts"
	return ""

## Tribute between us, short: "They pay us 120 a season · 4 years left".
static func tribute_label(other:String)->String:
	var day:=int(GameState.elapsed_days)
	var theirs:=Stances.tribute(other,"player")
	if not theirs.is_empty(): return _short("They pay us tribute worth %s a season · %s left" % [qty(float(theirs.value)),_years(int(theirs.until)-day)])
	var ours:=Stances.tribute("player",other)
	if not ours.is_empty(): return _short("We pay them tribute worth %s a season · %s left" % [qty(float(ours.value)),_years(int(ours.until)-day)])
	return ""

static func _years(days:int)->String:
	var years:=roundi(float(days)/365.0)
	if years<=0: return "under a year"
	return "a year" if years==1 else "%s years" % EraWords.count_word(years)

## When their answer comes: "Their answer in about 9 days".
static func waiting_label(actor:String,target:String)->String:
	var st:=Stances.stance(actor,target)
	var due:=int(st.get("answer",-1))
	if due<0 or not String(st.get("id","")) in Stances.COERCIVE: return ""
	return "Their answer in about %s" % EraWords.days(float(maxi(1,due-int(GameState.elapsed_days))))

# --------------------------------------------------------------------------
# The War screen: one short line per enemy row
# --------------------------------------------------------------------------

## "Trade: embargoed · they lack flint" (MAX_WORDS at most), "" when trade
## does not bear on them.
static func war_line(civ_id:String)->String:
	var parts:=PackedStringArray()
	var ours:=Stances.stance("player",civ_id)
	var theirs:=Stances.stance(civ_id,"player")
	if String(ours.get("id","free"))!="free": parts.append("we have %s them" % String(SHORT.get(String(ours.id),String(ours.id))) if String(ours.id)!="squeeze" else "we squeeze their %s" % good_word(String(ours.get("good",""))))
	if String(theirs.get("id","free")) in Stances.COERCIVE: parts.append("they have %s us" % String(SHORT.get(String(theirs.id),String(theirs.id))) if String(theirs.id)!="squeeze" else "they squeeze our %s" % good_word(String(theirs.get("good",""))))
	var leaned:Dictionary=ours.get("leaned",{}) if ours.get("leaned") is Dictionary else {}
	var lacking:=""
	for good:String in leaned:
		if float(leaned[good])>=0.2: lacking=good; break
	if lacking!="": parts.append("they lack %s" % good_word(lacking))
	else:
		var most:=Ledger.most_needed(civ_id,"player")
		if not most.is_empty() and float(most.share)>=0.2: parts.append("they lean on our %s" % good_word(String(most.good)))
		var ours_most:=Ledger.most_needed("player",civ_id)
		if not ours_most.is_empty() and float(ours_most.share)>=0.2: parts.append("we lean on their %s" % good_word(String(ours_most.good)))
	if parts.is_empty(): return ""
	return _short("Trade: "+" · ".join(parts))

# --------------------------------------------------------------------------
# News: the alert under the clock and the chronicle, told once
# --------------------------------------------------------------------------

static func _other(item:Dictionary)->String:
	return String(item.b) if String(item.a)=="player" else String(item.a)

## The alert line (MAX_WORDS at most).
static func news_line(item:Dictionary)->String:
	var other:=_other(item)
	var them:=Ledger.name_of(other)
	var good:=String(item.get("good",""))
	var line:=""
	match String(item.get("kind","")):
		"partner":
			var p:=Ledger.pair(String(item.a),String(item.b))
			line="New trade partner: %s · %s" % [them,form_words(String(p.get("form","gift")))]
		"meeting": line="A meeting place with %s: barter each season" % them
		"embargo": line="%s embargoes us · we lose %s" % [them,flow_words(other,"player")] if String(item.a)!="player" else "We embargo %s" % them
		"squeeze": line="%s cuts off our %s and buys it up" % [them,good_word(good)] if String(item.a)!="player" else "We squeeze %s's %s" % [them,good_word(good)]
		"toll": line="%s tolls our traders · a tenth of our trade" % them
		"yield":
			match String(item.get("stance","")):
				"tribute":
					var t:=Stances.tribute(other,"player")
					line="%s yields: tribute worth %s a season" % [them,qty(float(t.get("value",0.0)))]
				"toll": line="%s accepts our toll" % them
				_: line="%s yields and pays to end the %s" % [them,_stance_noun(String(item.get("stance","")),good)]
		"bear": line="%s bears the %s" % [them,_stance_noun(String(item.get("stance","")),good)]
		"supplier": line="%s finds another supplier" % them
		"counter": line="%s strikes back with an embargo on us" % them
		"raid": line="%s will raid our traders" % them
		"raided":
			if String(item.a)=="player": line="Our people raid %s's traders" % them
			else: line="%s raids our traders · %s taken%s" % [them,qty(float(item.get("seized",0.0))),(", %d killed" % int(item.dead)) if int(item.get("dead",0))>0 else ""]
		"war": line="%s goes to war over %s" % [them,cause({"id":String(item.get("stance","")),"good":good})]
		"shortage":
			if String(item.b)=="player": line="We run short of %s" % good_word(good)
			else: line="%s runs short of %s · %s of it was ours" % [them,good_word(good),share_words(float(item.get("share",0.0)))]
		"lifted": line="%s opens trade with us again" % them if String(item.a)!="player" else "Trade with %s opens again" % them
		"tribute_end": line="Tribute from %s ends" % them if String(item.b)=="player" else "Our tribute to %s ends" % them
		"tribute_stopped": line="%s stops paying tribute" % them if String(item.b)=="player" else "We could not pay %s" % them
		_: line="Trade with %s: %s" % [them,String(item.get("kind",""))]
	return _short(line)

## The longer telling for the chronicle, once (keyed by the news id).
static func chronicle(item:Dictionary)->void:
	var kind:=String(item.get("kind",""))
	var other:=_other(item)
	var them:=Ledger.name_of(other)
	var good:=String(item.get("good",""))
	var title:=""
	var text:=String(item.get("text",""))+"."
	var tier:="notice"
	match kind:
		"partner":
			title="Trade With %s" % them
			text="Goods have begun to pass between our people and %s: %s. We send %s; they send %s." % [them,form_words(String(Ledger.pair(String(item.a),String(item.b)).get("form","gift"))),flow_words("player",other),flow_words(other,"player")]
		"meeting":
			title="A Meeting Place With %s" % them
			text="After seasons of gifts both ways, our people and %s now meet each season to trade goods for goods." % them
		"embargo","squeeze","toll":
			if String(item.a)=="player": return
			title="%s Turns On Our Trade" % them
			text="%s. %s" % [String(item.text),leaning_line("player",other)]
			tier="moment"
		"yield":
			title="%s Gives Way" % them
			tier="moment"
		"war":
			title="War Over Trade"
			tier="moment"
		"shortage":
			title="Short of %s" % good_word(good).capitalize()
			text="%s. %s" % [String(item.text),leaning_line(other if String(item.b)!="player" else "player","player" if String(item.b)!="player" else other)]
		"raided":
			title="Traders Waylaid" if String(item.b)=="player" else "We Raid Their Traders"
		_:
			title="Trade: %s" % them
	Chronicle.record({"title":title.substr(0,60),"text":text.strip_edges(),"tier":tier,"kind":"contact","key":"trade:%d" % int(item.get("id",0))})

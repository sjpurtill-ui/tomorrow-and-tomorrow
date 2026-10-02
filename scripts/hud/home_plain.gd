extends RefCounted
## Plain-language readings for the home docks (Food, Materials, Wealth,
## Settlement, Health). Each reading gives a number its label, its direction
## and its cause, in words a new player can act on. Pure functions over values
## the simulation already computes; nothing here changes game state.
##
## Durations and small quantities reuse the Production screen's wording
## (production_plain.gd) so every dock says "about 7 months" the same way.

const Plain:=preload("res://scripts/hud/production_plain.gd")

## "rising", "falling" or "steady" from a daily change and the stock it moves.
static func direction(change:float,stock:float=0.0)->String:
	var noise:=maxf(0.05,absf(stock)*0.002)
	if change>noise:return "rising"
	if change<-noise:return "falling"
	return "steady"

static func _first_upper(text:String)->String:
	return text.left(1).to_upper()+text.substr(1) if not text.is_empty() else text

## How long the food lasts, which way it is going and why, from the daily flow.
## `flow` holds produced, eaten, spoiled and missions (rations today).
static func food(days:float,flow:Dictionary,reported:bool=true)->Dictionary:
	var produced:=maxf(0.0,float(flow.get("produced",0.0)))
	var eaten:=maxf(0.0,float(flow.get("eaten",0.0)))
	var spoiled:=maxf(0.0,float(flow.get("spoiled",0.0)))
	var sent:=maxf(0.0,float(flow.get("missions",0.0)))
	var net:=float(flow.get("net",produced-eaten-spoiled-sent))
	var result:={"trend":"steady","tone":"good"}
	if not reported:
		result.headline="Food stores are not counted yet"
		result.cause="The first count comes after the first day passes."
		result.sentence=String(result.headline)+". "+String(result.cause)
		result.tone="muted"
		return result
	if days<=0.05:result.headline="The food is gone"
	elif days>=3650.0:result.headline="Food lasts for years at this rate"
	else:result.headline="Food lasts "+Plain.duration_text(days)
	result.trend=direction(net,days*maxf(0.5,eaten))
	match String(result.trend):
		"rising":
			result.cause="more comes in each day than is eaten" if spoiled<produced*0.25 else "more comes in than is eaten, though some spoils"
		"falling":
			var shortfall:=eaten-produced
			if sent>maxf(shortfall,spoiled):result.cause="food went out with a departing party"
			elif spoiled>maxf(0.0,shortfall):result.cause="more spoils than we can spare"
			elif produced<=0.05:result.cause="nothing is coming in"
			else:result.cause="we eat more than comes in each day"
		_:
			result.cause="what comes in matches what is eaten"
	# Under the lean buffer (food_care.gd), or falling toward it, is bad.
	var lean:=float(preload("res://scripts/food_care.gd").LEAN_DAYS)
	if (days<lean and result.trend!="rising") or (days<lean*1.5 and result.trend=="falling"):result.tone="bad"
	elif days<90.0 and result.trend=="falling":result.tone="warn"
	result.sentence="%s; %s: %s." % [String(result.headline),String(result.trend),String(result.cause)]
	return result

## A day's flow as a short sentence: "84 came in, 70 were eaten, 3 spoiled".
static func flow_sentence(flow:Dictionary)->String:
	var parts:Array[String]=[]
	parts.append("%s came in" % Plain.number(float(flow.get("produced",0.0))))
	parts.append("%s eaten" % Plain.number(float(flow.get("eaten",0.0))))
	if float(flow.get("spoiled",0.0))>0.05:parts.append("%s spoiled" % Plain.number(float(flow.get("spoiled",0.0))))
	if float(flow.get("missions",0.0))>0.05:parts.append("%s sent with a party" % Plain.number(float(flow.get("missions",0.0))))
	return "Today: "+", ".join(parts)+" (rations)."

## Drinking water: share of need met, which way and why.
static func water(water_metrics:Dictionary)->Dictionary:
	if not water_metrics.has("required_today"):
		return {"headline":"Water is not counted yet","cause":"The first count comes after the first day passes.","tone":"muted","ratio":-1.0}
	var ratio:=clampf(float(water_metrics.get("intake_ratio",0.0)),0.0,1.0)
	var collected:=float(water_metrics.get("collected_today",0.0))
	var needed:=maxf(0.001,float(water_metrics.get("required_today",1.0)))
	var headline:="Everyone has the water they need" if ratio>=0.98 else "%d in every 10 drink enough" % roundi(ratio*10.0) if ratio>=0.1 else "Almost no one drinks enough"
	var cause:="the carriers bring in enough each day"
	if ratio<0.98:cause="the carriers bring in less than is needed" if collected<needed else "stores ran low before the carriers returned"
	return {"headline":headline,"cause":cause,"tone":"good" if ratio>=0.98 else "warn" if ratio>=0.8 else "bad","ratio":ratio,"sentence":"%s: %s." % [headline,cause]}

## A material's stock, which way it moved since the last record, and why.
## `points` is the stock history (oldest first, value may be null).
static func material(stock:float,delivered:float,loss:float,points:Array,blocked_reason:String="")->Dictionary:
	var previous:=-1.0;var previous_day:=-1
	for index in range(points.size()-1,-1,-1):
		var point:Dictionary=points[index]
		if point.get("value")==null:continue
		previous=float(point.value);previous_day=int(point.get("day",-1));break
	var trend:="steady"
	if previous>=0.0:
		var change:=stock-previous
		if change>maxf(0.5,previous*0.03):trend="rising"
		elif change<-maxf(0.5,previous*0.03):trend="falling"
	elif delivered>loss+0.05:trend="rising"
	elif loss>delivered+0.05:trend="falling"
	var cause:=""
	if delivered>0.05:cause="%s brought in a day" % Plain.number(delivered)
	elif not blocked_reason.is_empty():cause=blocked_reason.left(1).to_lower()+blocked_reason.substr(1)
	else:cause="nothing is being brought in"
	if loss>0.05:cause+="; %s a day spoils or is lost" % Plain.number(loss)
	elif trend=="falling" and delivered>0.05:cause+=", but more is used"
	var tone:="bad" if trend=="falling" and stock<5.0 else "warn" if trend=="falling" else "good" if trend=="rising" or delivered>0.05 else "muted"
	return {"trend":trend,"cause":cause,"since":"since last month" if previous_day>=0 else "","tone":tone}

## One sentence for the store and the carriers: what, if anything, slows supply.
static func supply(stored:float,capacity:float,hauling:Variant)->Dictionary:
	var full:=clampf(stored/capacity,0.0,1.0) if capacity>0.0 else -1.0
	var carried:=clampf(float(hauling),0.0,1.0) if hauling!=null else -1.0
	var store:="Storage is not built yet" if full<0.0 else "Stores are full" if full>=0.97 else "Stores are nearly full" if full>=0.85 else "Stores are about %d%% full" % (roundi(full*10.0)*10) if full>=0.1 else "Stores are almost empty"
	var carry:=""
	if carried>=0.0:
		if carried>=0.95:carry="the carriers bring in everything that is dug and cut"
		elif carried>=0.6:carry="the carriers bring in most of what is dug and cut"
		else:carry="the carriers bring in only %d in every 10 loads; hauling is what slows us" % roundi(carried*10.0)
	var slows:=""
	if full>=0.97:slows="Storage is what slows us: more is dug than there is room for."
	elif carried>=0.0 and carried<0.6:slows="Hauling is what slows us."
	var sentence:=store+("; "+carry if not carry.is_empty() else "")+"."
	return {"sentence":sentence,"store_words":store,"carry_words":carry,"slows":slows,"full":full,"carried":carried}

## The day's useful work, which way it is going, and what holds it back.
## `history` is economy_history (entries with day and output_per_capita).
static func output(economy:Dictionary,history:Array,conditions:Dictionary)->Dictionary:
	var per_person:=float(economy.get("gdp_per_capita",0.0))
	var productivity:=float(economy.get("productivity",0.0))
	var trend:="steady"
	var latest:={};var earlier:={}
	for index in range(history.size()-1,-1,-1):
		var entry:Dictionary=history[index]
		if not entry.has("output_per_capita"):continue
		if latest.is_empty():latest=entry;continue
		if int(latest.get("day",0))-int(entry.get("day",0))>=30:earlier=entry;break
	if not latest.is_empty() and not earlier.is_empty():
		var before:=float(earlier.output_per_capita);var now:=float(latest.output_per_capita)
		if now>before*1.03:trend="rising"
		elif now<before*0.97:trend="falling"
	# The weakest of the conditions that set how much each worker gets done.
	var causes:=[[float(conditions.get("health",1.0)),"sickness"],[float(conditions.get("cohesion",1.0)),"quarrels and unrest"],[float(conditions.get("housing",1.0)),"too little shelter"]]
	var weakest:Array=[]
	for cause:Array in causes:
		if float(cause[0])<0.75 and (weakest.is_empty() or float(cause[0])<float(weakest[0])):weakest=cause
	var skill:="Each worker gets done about %d%% of what a healthy, settled worker could" % roundi(clampf(productivity,0.0,1.5)*100.0)
	var held:=("; "+String(weakest[1])+" holds them back most") if not weakest.is_empty() else "; health, shelter and goodwill are all sound"
	return {"trend":trend,"per_person":per_person,"workers":float(economy.get("effective_workers",0.0)),
		"headline":"Each person's share of the day's work: %s" % Plain.number(per_person),
		"cause":skill+held+".","tone":"warn" if trend=="falling" or not weakest.is_empty() else "good"}

## Old-to-young balance in words, from the count of dependants per worker.
static func dependency(dependants:int,workers:int)->String:
	if workers<=0:return "No one of working age lives here."
	var ratio:=float(dependants)/float(workers)
	if ratio<0.35:return "Few children and elders: most people here can work."
	if ratio<0.7:return "About %s dependants for every ten workers." % Plain.number(roundf(ratio*10.0))
	if ratio<1.0:return "Nearly one child or elder for every worker: the workers carry a heavy load."
	return "More children and elders than workers: every worker feeds more than themself."

## The two things a player wants to know about care of the sick.
static func care(share:float,staff:float,report:Dictionary,waiting:float,known_rounds:bool)->Dictionary:
	var choice:="none" if share<=0.001 else "standard" if share<=0.3 else "more"
	if not known_rounds:
		return {"choice":choice,"first":"No one yet knows how to watch over the sick by regular rounds.","second":"Care duty opens once the people learn observation rounds."}
	var carers:=roundi(staff)
	var first:="No carers are set aside; the sick are looked after at home." if staff<0.05 or share<=0.001 else ("About %s of those who keep the lore look after the sick." % (Plain.number(staff) if carers<1 else str(carers)))
	var supported:=float(report.get("supported",0.0))
	var blocker:=String(report.get("blocker",""))
	var second:=""
	if waiting>=0.5:second="%s sick %s waiting for care%s." % [Plain.number(waiting),"person is" if roundi(waiting)==1 else "people are",(" because "+_reason(blocker)) if not blocker.is_empty() else ""]
	elif supported>=0.5:second="Everyone who fell sick today was cared for."
	else:second="No one is waiting for care."
	return {"choice":choice,"first":first,"second":second}

static func _reason(blocker:String)->String:
	if blocker.begins_with("Care demand exceeds"):return "there are too few carers or supplies"
	if blocker.begins_with("No adopted observation"):return "no carers are set aside"
	if blocker.begins_with("Settled, accessible"):return "the people are not settled"
	return blocker.left(1).to_lower()+blocker.substr(1).trim_suffix(".")

## A share (0..1) of an official's suitability, in words.
static func fit_words(fit:float)->String:
	if fit>=0.8:return "Suits the office very well"
	if fit>=0.6:return "Suits the office well"
	if fit>=0.4:return "A fair fit for the office"
	if fit>=0.2:return "A poor fit for the office"
	return "Badly suited to the office"

## A skill score out of 100, in words.
static func skill_words(value:float)->String:
	if value>=80.0:return "masterly"
	if value>=65.0:return "skilled"
	if value>=45.0:return "capable"
	if value>=25.0:return "untried"
	return "weak"

## Research team size (full-time equivalents) as the people would say it.
static func researchers(amount:float)->String:
	if amount<=0.05:return "No one is working on it yet"
	if amount<0.75:return "One person, part of the time"
	if amount<1.5:return "About one person, full time"
	if amount<9.5:return "About %d people" % roundi(amount)
	return "About %d people" % (roundi(amount/5.0)*5)

## The team on a question, as the people would say it: "A team of about 3
## people", "Two teams, about 6 people", "One person, part of the time".
static func team(people:float,teams:int=1)->String:
	if people<=0.05:return "No one is working on it yet"
	if teams>=2:return "%s teams, %s" % ["Two" if teams==2 else str(teams),researchers(people).to_lower()]
	if people<1.5:return researchers(people)
	return "A team of "+researchers(people).to_lower()

## A question's clock: "about 1½ years to proof"; "" when nobody works it.
static func clock(days:float)->String:
	if days<=0.0 or not is_finite(days):return ""
	if days>365.0*150.0:return "no end in sight at this pace"
	return Plain.duration_text(days)+" to proof"

## A question's step to proof, with its trial use: "gathering the first
## cases", "first cases hold: 5 in 100 households try it", "repeated with the
## same result: 15 in 100 households use it".
static func step(stage:int,share:float)->String:
	var households:=roundi(clampf(share,0.0,1.0)*100.0)
	match stage:
		0:return "gathering the first cases"
		1:return "first cases hold: %d in 100 households try it" % households
	return "repeated with the same result: %d in 100 households use it" % households

## The price of working ahead of the age: "25 years ahead: six times the work".
static func lead_price(years:float,factor:float)->String:
	var whole:=roundi(factor)
	var times:="twice" if whole<=2 else ("%s times" % (["","","","three","four","five","six","seven","eight","nine","ten"][whole] if whole<=10 else str(whole)))
	return "%d years ahead: %s the work" % [roundi(years),times]

## Evidence gathered (0..1) as words.
static func evidence(progress:float)->String:
	var p:=clampf(progress,0.0,1.0)
	if p>=1.0:return "the work is done"
	if p>=0.85:return "nearly proven"
	if p>=0.6:return "most of the way to proof"
	if p>=0.4:return "about half proven"
	if p>=0.15:return "a quarter of the way to proof"
	return "just begun"

extends RefCounted
## WHY THE HEARTHS ARE FEWER (fun audit 2, item 3). When a year closes with
## fewer people than it opened, this names who died and why, from the same
## early-care profile (early_life_conditions.gd) that sets the death and birth
## rates. The cause named therefore changes when a practice is learned or a
## care decree covers it, because the rates change with it.
##
## The winter tally (hearth_count.gd) carries the sentence; the Chronicle gets
## a notice when the decline continues; the Steward can bring it to court as a
## condition petition (audience_hall.gd, topic "people") with the decree that
## answers the cause. All wording is plain and era-grounded: fevers, fouled
## water, childbed, hard food, lean winters; never germs or statistics.

## Which care category kills which age band, from early_life_conditions.CATEGORIES.
const CARE:=preload("res://scripts/early_life_conditions.gd")
## The decree that answers each missing practice (pronouncement_interpreter.gd
## maps these words to water_security, care_rotation and family_support, whose
## coverage channels are early_life_conditions.DECREE_COVER).
const DECREES:={"water":"Secure water and dig wells","remedies":"Organize healers to care for the sick","childcare":"Organize healers to care for the sick",
	"birth":"Organize healers to care for the sick","wounds":"Organize healers to care for the sick","cooking":"Organize healers to care for the sick",
	"stores":"Organize healers to care for the sick","births":"Support families and care for children"}
## Short plain causes, in the people's words, for each missing practice.
const CAUSE_WORDS:={
	"water":"fouled water and the summer fevers",
	"remedies":"fevers and coughs that nobody knows how to treat",
	"birth":"hard births with no one who knows how to help",
	"childcare":"hard food too early and too little watching while the mothers work",
	"cooking":"raw and spoiled food and the wrong plants",
	"stores":"the lean months, when nothing has been put by",
	"wounds":"cuts, bites and falls that fester",
}
## A crude birth rate under this (per 1,000) is "too few children born".
const LOW_BIRTHS_PER_1000:=36.0

## Who died most, and the likeliest cause, for a year's tally.
## `year`: {born, buried, young, grown, old, infants, mothers, start_people}.
static func explain(year:Dictionary,care:Dictionary,people:int)->Dictionary:
	var born:=int(year.get("born",0))
	var buried:=int(year.get("buried",0))
	var young:=float(year.get("young",0.0))+float(year.get("infants",0))
	var grown:=float(year.get("grown",0.0))+float(year.get("mothers",0))
	var old:=float(year.get("old",0.0))
	var dead:=maxf(1.0,young+grown+old)
	var band:="young"
	if old/dead>=0.5:band="old"
	elif young/dead<0.45:band="grown"
	var category:=_worst_category(care,band,float(year.get("infants",0))/maxf(1.0,young),float(year.get("mothers",0))/maxf(1.0,grown))
	var birth_rate:=float(born)*1000.0/maxf(1.0,float(people))
	var few_births:=birth_rate<LOW_BIRTHS_PER_1000
	var parts:PackedStringArray=[]
	if buried>born:parts.append("More were buried than born this year: %d graves and %d births." % [buried,born])
	var who:=String({"young":"Most of the dead were small children","grown":"Most of the dead were grown men and women","old":"Most of the dead were old"}[band])
	if band=="old":
		parts.append(who+".")
	elif category!="":
		parts.append("%s, taken by %s." % [who,String(CAUSE_WORDS[category])])
	else:
		parts.append("%s, taken by the fevers every people suffers." % who)
	var birth_reason:=""
	if few_births:
		birth_reason=_birth_reason(care)
		parts.append("Too few children are born%s." % birth_reason)
	var cause_id:=category if band!="old" and category!="" else ("births" if few_births else "fevers")
	if band=="old" and not few_births:cause_id="age"
	return {"text":" ".join(parts),"band":band,"cause":cause_id,"decree":String(DECREES.get(cause_id,DECREES.remedies)) if cause_id!="age" else "",
		"birth_rate":birth_rate,"few_births":few_births,"summary":_summary(band,cause_id,birth_reason)}

## One sentence for a court petition.
static func _summary(band:String,cause:String,birth_reason:String)->String:
	if cause=="births":return "Our people grow fewer each year: too few children are born%s." % birth_reason
	if cause=="age":return "Our people grow fewer each year; the old die and there are not enough young to take their places."
	var who:=String({"young":"the small children","grown":"grown men and women","old":"the old"}.get(band,"our people"))
	return "Our people grow fewer each year. Most of the dead are %s, taken by %s." % [who,String(CAUSE_WORDS.get(cause,"the fevers every people suffers"))]

static func _worst_category(care:Dictionary,band:String,infant_share:float,mother_share:float)->String:
	var best:=""
	var best_score:=0.05
	var coverage:Dictionary={}
	for row:Dictionary in care.get("categories",[]):coverage[String(row.get("id",""))]=float(row.get("coverage",0.0))
	for category:Dictionary in CARE.CATEGORIES:
		var id:=String(category.id)
		var weight:=0.0
		if band=="young":weight=float(category.get("under5",0.0))*0.7+float(category.get("child",0.0))*0.3+float(category.get("neonatal",0.0))*infant_share
		else:weight=float(category.get("adult",0.0))+float(category.get("maternal",0.0))*mother_share
		var score:=weight*(1.0-float(coverage.get(id,0.0)))
		if score>best_score:
			best_score=score
			best=id
	return best

## The main reason the people are fewer this year, in a few plain words for the
## People card ("fevers among the old"), by the same rule as the winter tally
## (explain). `year` is the hearth tally (hearth_count.gd: born, buried, young,
## grown, old, infants, mothers); with no deaths told by age yet, `buried` is
## split as the ledger takes ordinary deaths (hearth_count.gd age_split).
static func short_reason(year:Dictionary,care:Dictionary,people:int)->String:
	var tally:=year.duplicate()
	if float(tally.get("young",0.0))+float(tally.get("grown",0.0))+float(tally.get("old",0.0))<=0.0:
		# Loaded, not preloaded: hearth_count.gd preloads this script.
		tally.merge(load("res://scripts/hearth_count.gd").age_split(int(tally.get("buried",0))),true)
	var why:=explain(tally,care,people)
	var who:=String({"young":"the small children","grown":"the grown","old":"the old"}.get(String(why.band),"the people"))
	match String(why.cause):
		"age":return "the old die, and too few young follow"
		"births":
			var because:=_birth_reason(care).trim_prefix(": ")
			return "too few are born"+(", because "+because if because!="" else "")
		"fevers":return "fevers among %s" % who
	return "%s, taken by %s" % [who,String(CAUSE_WORDS.get(String(why.cause),"the fevers every people suffers"))]

## Deaths that are no part of the ordinary toll (a fire, a flood, war, the road,
## an outbreak, hunger, thirst, the god's word), in the words the card uses.
const ORDINARY_DEATHS:=["Natural causes","Neonatal complications","Complications of childbirth"]
const MISFORTUNE_WORDS:={"Hunger":"hunger","Illness":"sickness","Dehydration":"thirst","Drowning":"floods and drowning","Fire":"fire",
	"Exposure":"cold and exposure","Insecurity":"raids and the wild","Killed in battle":"war","Civilian deaths in war":"war","Killed defending the town":"war",
	"Died of wounds":"war","Executed at the god's word":"the god's word","Work accidents":"accidents at work","Travel exhaustion":"the road","Hardship":"hard times"}

## The misfortune behind a year that buried more than it bore, from the
## people's deaths by cause (GameState.rolling_death_causes): when the deaths
## outside the ordinary toll cover the shortfall, the largest of them, said
## plainly ("8 lost to fire"); "" when the ordinary toll explains it.
static func misfortune(causes:Dictionary,shortfall:int)->String:
	var unusual:=0
	var top:="";var top_count:=0
	for cause:String in causes:
		if cause in ORDINARY_DEATHS:continue
		var n:=int(causes[cause])
		unusual+=n
		if n>top_count:top=cause;top_count=n
	if top=="" or unusual<shortfall:return ""
	var words:=misfortune_words(top)
	return "%d lost to %s" % [top_count,words] if words!="" else "%d died by misfortune" % top_count

## Words found in the causes other systems give a death, and how the card says
## them: the sea, captivity, the trading road and the like. Checked in order.
const MISFORTUNE_PARTS:=[["at sea","the sea"],["captivity","captivity"],["trading road","the trading road"],["on the road","the road"],
	["scouting","scouting"],["envoy","the envoys' road"],["agents captured","agents captured abroad"],["hunger in the field","hunger in the field"],
	["village was burned","the burning of the village"],["sacrific","sacrifice"],["independence","a failed rising"],["displaced","the flight from war"],
	["under occupation","hunger under occupation"],["battle","war"],["in war","war"],["wounds","war"]]

## A death's cause in the card's words ("" when there are none: the card then
## says the dead died "by misfortune", never the raw cause). A directive's
## killings and executions are the god's word; a great work's fall or its
## builders' accidents are accidents at work.
static func misfortune_words(cause:String)->String:
	if cause.begins_with("Directive: "):
		var what:=cause.trim_prefix("Directive: ").to_lower()
		if "collapse" in what or "accident" in what:return "accidents at work"
		if "sacrific" in what:return "sacrifice"
		return "the god's word"
	if MISFORTUNE_WORDS.has(cause):return String(MISFORTUNE_WORDS[cause])
	var lower:=cause.to_lower()
	for part:Array in MISFORTUNE_PARTS:
		if String(part[0]) in lower:return String(part[1])
	return ""

## How many of the year's dead were the ordinary toll (for explain's counts).
static func ordinary_count(causes:Dictionary)->int:
	var n:=0
	for cause:String in causes:
		if cause in ORDINARY_DEATHS:n+=int(causes[cause])
	return n

static func _birth_reason(care:Dictionary)->String:
	if float(care.get("overwork",0.0))>=0.3:return ": the women are worked too hard to carry children"
	if float(care.get("diet",0.62))<0.55:return ": the food is too thin for the women to conceive"
	if float(care.get("crowding",0.0))>0.1:return ": the land is crowded and couples marry late"
	return ""

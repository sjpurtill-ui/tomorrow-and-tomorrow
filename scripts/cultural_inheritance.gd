extends RefCounted
## Additive cultural inheritance; current direction has a sixty-year half-life.
const HALF_LIFE_DAYS:=21900.0
const DOMAINS:={
	"ambition":["expansion","stewardship","commerce","influence"],
	"belonging":["universal_dignity","citizenship","in_group_supremacy","might_makes_right"],
	"authority":["consent","law","sacred_mandate","personal_domination"],
	"strength":["protection","prestige","conquest","extraction"],
	"obligation":["mutual_aid","fair_exchange","guardianship","exploitation"],
	"justice":["restoration","proportionality","vengeance","terror"],
	"difference":["pluralism","assimilation","separation","purification"],
	"truth":["evidence","tradition","revelation","political_usefulness"],
	"status":["equal_standing","achievement","heredity","ruthless_competition"]}
const PROFILES:={
	"horizons":{"ambition":{"influence":1.0},"difference":{"pluralism":1.0},"truth":{"evidence":1.0}},
	"makers":{"status":{"achievement":1.0},"truth":{"evidence":1.0},"ambition":{"stewardship":1.0}},
	"gathering":{"belonging":{"citizenship":1.0},"difference":{"pluralism":1.0},"authority":{"consent":1.0}},
	"inquiry":{"truth":{"evidence":1.0},"status":{"achievement":1.0},"difference":{"pluralism":1.0}},
	"military":{"strength":{"protection":0.6,"prestige":0.4},"authority":{"law":1.0}},
	"sustenance":{"ambition":{"stewardship":1.0},"obligation":{"guardianship":1.0}},
	"wellbeing":{"belonging":{"universal_dignity":1.0},"obligation":{"mutual_aid":1.0},"justice":{"restoration":1.0}},
	"commerce":{"ambition":{"commerce":1.0},"obligation":{"fair_exchange":1.0},"status":{"achievement":1.0}},
	"expansion":{"ambition":{"expansion":1.0},"status":{"achievement":0.5,"ruthless_competition":0.5}},
	"dominion":{"ambition":{"expansion":1.0},"strength":{"conquest":0.6,"extraction":0.4},"authority":{"personal_domination":1.0},"obligation":{"exploitation":1.0}},
	"purity":{"difference":{"purification":1.0},"belonging":{"in_group_supremacy":1.0},"truth":{"revelation":1.0}},
	"dynasty":{"status":{"heredity":1.0},"authority":{"sacred_mandate":0.5,"personal_domination":0.5},"truth":{"tradition":1.0}},
	"retribution":{"justice":{"vengeance":0.5,"terror":0.5},"strength":{"prestige":1.0},"belonging":{"might_makes_right":1.0}},
	"orthodoxy":{"truth":{"political_usefulness":0.5,"tradition":0.5},"difference":{"assimilation":0.5,"separation":0.5},"authority":{"personal_domination":1.0}}}
static func empty()->Dictionary:return {"version":1,"inheritance":{},"recent":{},"recent_day":0,"choices":{},"events":[]}
static func _valid_day(value:Variant)->bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)>=0.0 and float(value)<=1e12 and float(value)==floorf(float(value))
static func valid(state:Variant)->bool:
	if not state is Dictionary or state.get("version",0)!=1:return false
	if not state.get("choices") is Dictionary or not state.get("events") is Array or state.events.size()>1024:return false
	if not _valid_day(state.get("recent_day")):return false
	for channel in ["inheritance","recent"]:
		if not state.get(channel) is Dictionary:return false
		for domain in state[channel]:
			if not DOMAINS.has(domain) or not state[channel][domain] is Dictionary:return false
			for pole in state[channel][domain]:
				var value:Variant=state[channel][domain][pole]
				if pole not in DOMAINS[domain] or not (value is float or value is int) or not is_finite(float(value)) or value<0:return false
	for key in state.choices:
		var weight:Variant=state.choices[key]
		if not PROFILES.has(key) or not (weight is float or weight is int) or not is_finite(float(weight)) or weight<0:return false
	for event in state.events:
		if not event is Dictionary or not event.get("id") is String or not event.get("choice") is String or not _valid_day(event.get("day")) or not (event.get("weight") is float or event.get("weight") is int):return false
		if not PROFILES.has(event.choice) or event.day<0 or not is_finite(event.weight) or event.weight<=0:return false
	return true
static func record(state:Dictionary,id:String,choice:String,day:int,weight:float)->bool:
	if not PROFILES.has(choice) or day<0 or weight<=0 or not is_finite(weight) or state.events.size()>=1024:return false
	for event:Dictionary in state.events:
		if event.id==id:return false
	if day<int(state.recent_day):return false
	var factor:=pow(.5,float(day-int(state.recent_day))/HALF_LIFE_DAYS)
	for domain in state.recent:
		for pole in state.recent[domain]:state.recent[domain][pole]*=factor
	state.recent_day=day
	for domain in PROFILES[choice]:
		for channel in ["inheritance","recent"]:
			if not state[channel].has(domain):state[channel][domain]={}
			for pole in PROFILES[choice][domain]:state[channel][domain][pole]=float(state[channel][domain].get(pole,0))+weight*float(PROFILES[choice][domain][pole])
	state.choices[choice]=float(state.choices.get(choice,0))+weight
	state.events.append({"id":id,"choice":choice,"day":day,"weight":weight})
	return true
static func distribution(state:Dictionary,domain:String,day:int,current:bool=false)->Dictionary:
	var historical:Dictionary=state.inheritance.get(domain,{})
	var recent:Dictionary=state.recent.get(domain,{})
	var factor:=pow(.5,maxf(0,float(day-int(state.recent_day)))/HALF_LIFE_DAYS)
	var scores:Dictionary={};var total:=0.0
	for pole in DOMAINS.get(domain,[]):
		var value:=float(historical.get(pole,0))
		if current:value=value*.25+float(recent.get(pole,0))*factor
		scores[pole]=value;total+=value
	if total>0:
		for pole in scores:scores[pole]/=total
	return scores
static func weight(state:Dictionary,domain:String,pole:String,day:int)->float:
	return float(distribution(state,domain,day,true).get(pole,0))

static func choice_weights(state:Dictionary,day:int)->Dictionary:
	var scores:Dictionary={}
	for choice in state.choices:scores[choice]=float(state.choices[choice])*.25
	for event:Dictionary in state.events:
		scores[event.choice]=float(scores.get(event.choice,0))+float(event.weight)*pow(.5,maxf(0,float(day-int(event.day)))/HALF_LIFE_DAYS)
	return scores

const WORK:={
	"horizons":{"Survey":12.0,"Logistics":6.0},"makers":{"Crafting":12.0,"Construction":6.0},
	"gathering":{"Administration":10.0,"Logistics":4.0,"Knowledge":4.0},"inquiry":{"Knowledge":14.0,"Survey":4.0},
	"military":{"Defense":12.0,"Logistics":6.0},"sustenance":{"Food":12.0,"Logistics":6.0},
	"wellbeing":{"Food":6.0,"Knowledge":8.0,"Construction":4.0},"commerce":{"Logistics":10.0,"Crafting":8.0},
	"expansion":{"Survey":6.0,"Logistics":6.0,"Construction":6.0},"dominion":{"Defense":10.0,"Extraction":5.0,"Administration":3.0},
	"purity":{"Administration":10.0,"Defense":8.0},"dynasty":{"Administration":10.0,"Construction":8.0},
	"retribution":{"Defense":12.0,"Administration":6.0},"orthodoxy":{"Administration":12.0,"Knowledge":6.0}}
static func labor_bias(state:Dictionary,day:int)->Dictionary:
	var choices:=choice_weights(state,day);var total:=0.0;var result:Dictionary={}
	for value in choices.values():total+=float(value)
	if total<=0:return result
	for choice in choices:
		for role in WORK[choice]:result[role]=float(result.get(role,0))+float(WORK[choice][role])*float(choices[choice])/total
	return result
static func scout_share(state:Dictionary,day:int)->float:
	var choices:=choice_weights(state,day);var total:=0.0;var share:=0.0
	for choice in choices:
		var amount:=float(choices[choice]);total+=amount
		share+=amount*(.08 if choice in ["expansion","horizons"] else .05 if choice in ["dominion","commerce","inquiry"] else .02)
	return share/total if total>0 else 0.0

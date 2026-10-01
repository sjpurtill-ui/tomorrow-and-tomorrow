extends RefCounted
## A GENERAL'S RECORD AND WHAT THEY CHANGE, in numbers (leader_commands.gd
## record, historical_figures.gd skills). The ruler sees behaviour and
## numbers, never the character labels behind them
## (docs/GENERAL_CAMPAIGN_DESIGN.md): how their bands fight, march, go hungry
## and desert under them against an ordinary general (every skill 0.5), and
## what they have done: battles won and lost, men lost for men of theirs,
## their pace on the march, the hungry days and the deserters.
## Static; preload.

const Sustain:=preload("res://scripts/field_sustainment.gd")
const ORDINARY:={"command":0.5,"tactics":0.5,"logistics":0.5,"resolve":0.5}

## What a commander does against another (ORDINARY by default), as shares:
## {fight (battle power, for a band of `men`: a general's hand thins past
## combat_simulator.COMMAND_REACH_MEN), pace (march speed), hunger (men lost
## to hunger), desertion (men lost to desertion under the same hardship)}.
## 0.07 = 7% more; hunger and desertion below 0 are fewer lost.
static func levers(commander:Dictionary,against:Dictionary=ORDINARY,men:float=0.0)->Dictionary:
	var cs:=preload("res://scripts/combat_simulator.gd")
	var fight:=cs.command_factor(_s(commander,"command"),men)/cs.command_factor(_s(against,"command"),men)-1.0
	var pace:=(0.9+0.2*_s(commander,"logistics"))/(0.9+0.2*_s(against,"logistics"))-1.0
	var hunger:=(Sustain.HUNGER_BASE-Sustain.HUNGER_BY_LOGISTICS*_s(commander,"logistics"))/(Sustain.HUNGER_BASE-Sustain.HUNGER_BY_LOGISTICS*_s(against,"logistics"))-1.0
	var desertion:=_desertion_factor(commander)/_desertion_factor(against)-1.0
	return {"fight":fight,"pace":pace,"hunger":hunger,"desertion":desertion}

static func _s(commander:Dictionary,skill:String)->float:
	return clampf(float(commander.get(skill,0.5)),0.0,1.0)

## The share of hardship's pull that discipline lets through (a band at
## middling drill, no professional corps), as desertion_day reads it.
static func _desertion_factor(commander:Dictionary)->float:
	var leadership:=clampf(_s(commander,"command")*0.55+_s(commander,"resolve")*0.45,0.0,1.0)
	var discipline:=clampf(0.18+leadership*0.42+0.5*0.30,0.0,1.0)
	return 1.15-discipline*0.65

static func _pct(share:float)->int:
	return roundi(absf(share)*100.0)

## "Under Tesk bands fight 7% harder, march 4% faster, lose 8% fewer men to
## hunger and 10% fewer to desertion than under an ordinary general."
static func lever_line(commander:Dictionary,name:String,men:float=0.0)->String:
	if commander.is_empty(): return ""
	var l:=levers(commander,ORDINARY,men)
	var parts:PackedStringArray=PackedStringArray()
	parts.append("fight %d%% %s" % [_pct(l.fight),"harder" if float(l.fight)>=0.0 else "softer"])
	parts.append("march %d%% %s" % [_pct(l.pace),"faster" if float(l.pace)>=0.0 else "slower"])
	parts.append("lose %d%% %s men to hunger" % [_pct(l.hunger),"fewer" if float(l.hunger)<=0.0 else "more"])
	parts.append("%d%% %s to desertion" % [_pct(l.desertion),"fewer" if float(l.desertion)<=0.0 else "more"])
	var who:=name.get_slice(" ",0) if name!="" else "them"
	return "Under %s bands %s, %s, %s and %s than under an ordinary general." % [who,parts[0],parts[1],parts[2],parts[3]]

## "If Tesk led this band: power +9%, pace +3%" (against its leader now).
static func if_led(now:Dictionary,other:Dictionary,name:String,men:float=0.0)->String:
	if other.is_empty(): return ""
	var l:=levers(other,now if not now.is_empty() else ORDINARY,men)
	return "If %s led it: power %+d%%, pace %+d%%, hunger %+d%%, desertion %+d%%" % [name.get_slice(" ",0),roundi(float(l.fight)*100.0),roundi(float(l.pace)*100.0),roundi(float(l.hunger)*100.0),roundi(float(l.desertion)*100.0)]

## A general's record in one line: "Fought 4 · won 3 · lost 1 · 38 of ours
## lost for 120 of theirs · 17 km a day on the march · 6 hungry days ·
## 2 deserted · 3 years in public life". record is leader_commands.record.
static func words(record:Dictionary)->String:
	if record.is_empty(): return ""
	var parts:PackedStringArray=PackedStringArray()
	var fought:=int(record.get("battles",0))
	parts.append(("Fought %d · won %d · lost %d" % [fought,int(record.get("won",0)),int(record.get("lost",0))]) if fought>0 else "Has not led a fight yet")
	if fought>0: parts.append("%d of ours lost for %d of theirs" % [int(record.get("men_lost",0)),int(record.get("enemy_lost",0))])
	if int(record.get("march_days",0))>0: parts.append("%d km a day on the march" % roundi(float(record.get("km_day",0.0))))
	if int(record.get("field_days",0))>0: parts.append("%d days in the field" % int(record.field_days))
	if int(record.get("hungry_days",0))>0: parts.append("%d hungry days" % int(record.hungry_days))
	if int(record.get("deserted",0))>0: parts.append("%d deserted" % int(record.deserted))
	var years:=int(record.get("years",0))
	parts.append("%d %s in public life" % [years,"year" if years==1 else "years"])
	return " · ".join(parts)

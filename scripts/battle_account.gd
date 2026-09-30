extends RefCounted
## One battle, told plainly (docs/MILITARY_MAP_PRESENTATION.md, section 11).
##
## Who fought, what each side lost, how each general fought, how it went
## exchange by exchange, where things stand now and what happens next, and
## what the war leader advises. build() is pure: it reads only the battle
## record and the state it is handed. gather() collects that state from the
## live campaign. The report card, the council inbox, the Chronicle and the
## battle replay all tell the same account.
##
## Accounting (tests/test_battle_account.gd): for our side
##   in_fight = killed + wounded + fled + captured + detached + present
##   sent     = in_fight + earlier (losses in this operation's earlier fights)
##              + elsewhere (anything the record cannot explain; normally 0)
## Their side is what our people saw: exact when few enough to count, a
## range otherwise, and nothing about the ground we did not hold.

const Tactics:=preload("res://scripts/battle_tactics.gd")
const Marks:=preload("res://scripts/hud/army_marks.gd")

## Exchanges are thirty minutes each (docs/GENERAL_CAMPAIGN_DESIGN.md).
const EXCHANGE_MINUTES:=30
## Up to this many on a side, our people can count them one by one.
const COUNTABLE:=12
const ORDINALS:=["first","second","third","fourth","fifth","sixth","seventh","eighth","ninth","tenth","eleventh","twelfth"]
const NUMBER_WORDS:=["no","one","two","three","four","five","six","seven","eight","nine","ten","eleven","twelve"]


# --- Small words ------------------------------------------------------------

## Morale as the war leader would say it. Never a bare percentage.
static func morale_words(morale:float)->String:
	if morale>=0.85: return "in good heart"
	if morale>=0.65: return "steady"
	if morale>=0.42: return "shaken but holding"
	if morale>0.15: return "badly shaken"
	return "broken"


## Why a won town was not held, from the engine's own reckoning
## (siege_recovery.gd capture_capacity / capture_city): {troops, effective,
## required}, the counts unknown as -1; {} when the town was not refused.
static func hold_shortfall(strategic:Dictionary)->Dictionary:
	var said:=String(strategic.get("message",""))
	var m:=RegEx.create_from_string("their (\\d+) survivors provide ([\\d.]+) effective personnel; holding this city needs (\\d+)").search(said)
	if m!=null: return {"troops":int(m.get_string(1)),"effective":float(m.get_string(2)),"required":int(m.get_string(3))}
	if "lack the supplied" in said: return {"troops":-1,"effective":-1.0,"required":-1}
	return {}


## "our 5 are hungry and worn: they count for about 2 at holding a town, and
## it needs 3," or the same without the numbers when they are not known.
static func hold_words(short:Dictionary)->String:
	if int(short.get("required",-1))<0: return "we are too few and too hungry to hold the town,"
	return "our %s %s hungry and worn: they count for about %s at holding a town, and it needs %s," % [exact(int(short.troops)),"is" if int(short.troops)==1 else "are",exact(maxi(0,floori(float(short.effective)))),exact(int(short.required))]


static func count_words(n:int)->String:
	n=maxi(0,n)
	return NUMBER_WORDS[n] if n<NUMBER_WORDS.size() else Marks.about(n)


## A number of our own, told exactly: the war leader counted them ("45",
## "1,200"; small ones in words). Theirs are count_words, "about" when many.
static func exact(n:int)->String:
	n=maxi(0,n)
	return NUMBER_WORDS[n] if n<NUMBER_WORDS.size() else preload("res://scripts/hud/era_words.gd").grouped(n)


static func _ours(n:int,one:String="person",many:String="people")->String:
	return "%s %s" % [exact(n),one if n==1 else many]


static func _people(n:int,one:String="person",many:String="people")->String:
	return "%s %s" % [count_words(n),one if n==1 else many]


static func _ordinal(index:int)->String:
	return ORDINALS[index] if index>=0 and index<ORDINALS.size() else "%dth" % (index+1)


## "a, b and c".
static func _and_list(items:PackedStringArray)->String:
	if items.size()<=1: return "".join(items)
	return "%s and %s" % [", ".join(items.slice(0,items.size()-1)),items[-1]]


static func _cap(text:String)->String:
	return text if text.is_empty() else text.substr(0,1).to_upper()+text.substr(1)


static func _first_name(full:String)->String:
	var clean:=full.strip_edges()
	if clean.is_empty(): return ""
	# Placeholder staffs ("ESURAI FIELD STAFF") are never named.
	if clean==clean.to_upper() and clean.length()>3: return ""
	return clean.get_slice(" ",0)


static func _place_name(name:String)->String:
	## "the field contact" and other internal placeholders are not places.
	var clean:=name.strip_edges()
	if clean.is_empty() or clean.begins_with("the field") or clean=="MARKED GROUND": return ""
	return clean


static func duration_words(exchanges:int)->String:
	var minutes:=maxi(0,exchanges)*EXCHANGE_MINUTES
	if minutes<=0: return "no time at all"
	if minutes<60: return "half an hour"
	if minutes<90: return "about an hour"
	var hours:=roundi(float(minutes)/60.0)
	return "about %s hours" % count_words(hours) if hours<=12 else "all day"


# --- The record -------------------------------------------------------------

static func sides(record:Dictionary)->Dictionary:
	var home:=String(record.get("home_side","attacker"))
	return {"home":home,"enemy":"defender" if home=="attacker" else "attacker"}


## Killed, wounded, fled (scattered) and taken (when a block broke and the
## enemy rode its men down) on one side, summed from the rounds.
static func round_losses(record:Dictionary,side:String)->Dictionary:
	var out:={"killed":0,"wounded":0,"fled":0,"taken":0,"total":0}
	for round_variant in record.get("rounds",[]):
		var round_data:Dictionary=round_variant
		var total:=int(round_data.get(side+"_losses",0))
		var breakdown:Dictionary=round_data.get(side+"_casualties",{})
		var killed:=int(breakdown.get("killed",0)); var wounded:=int(breakdown.get("wounded",0)); var fled:=int(breakdown.get("scattered",0)); var taken:=int(breakdown.get("captured",0))
		# Older records carry only the total; count the unexplained as fled.
		fled+=maxi(0,total-killed-wounded-fled-taken)
		out.killed+=killed; out.wounded+=wounded; out.fled+=fled; out.taken+=taken; out.total+=total
	return out


## won | lost | withdrew | held | mutual | taken | uncontested | nobody
static func outcome_kind(record:Dictionary)->String:
	var s:=sides(record)
	var ours:Dictionary=record.get(s.home,{})
	var termination:Dictionary=record.get("termination",{})
	var strategic:Dictionary=record.get("strategic_outcome",{})
	var rounds:Array=record.get("rounds",[])
	if bool(strategic.get("region_captured",false)) and String(record.get("home_side",""))=="attacker": return "taken"
	var fought_blind:=int(ours.get("initial_troops",0))>int(ours.get("remaining_troops",ours.get("initial_troops",0)))
	if rounds.is_empty() and not fought_blind and not bool((record.get("orders",{}) as Dictionary).get("retreated",false)):
		var enemy:Dictionary=record.get(s.enemy,{})
		return "nobody" if int(enemy.get("initial_troops",0))<=0 else "uncontested"
	if bool((record.get("orders",{}) as Dictionary).get("retreated",false)) or String(record.get("outcome","")).ends_with("_retreat"): return "withdrew"
	var our_name:=String(ours.get("name",""))
	if String(termination.get("type",""))=="mutual_withdrawal": return "mutual"
	if our_name!="" and String(termination.get("captor",""))==our_name: return "won"
	if our_name!="" and String(termination.get("defeated",""))==our_name: return "lost"
	var outcome:=String(record.get("outcome",""))
	if outcome==s.home+"_victory": return "won"
	if outcome==s.enemy+"_victory": return "lost"
	return "held"


# --- The account --------------------------------------------------------------

## state keys (all optional): stage, today, army (our field army now, {} if
## gone), garrison (occupation force now holding the target), siege (public
## siege snapshot for this army), engaged_again, aftermath_pending, operation
## ({sent, day, target_name, kind}), earlier ({killed, wounded, fled,
## captured, detached, fights}), near (nearest known town for a field fight),
## marching_to ({name, days, kind}), command_status, general_name.
static func build(record:Dictionary,state:Dictionary={})->Dictionary:
	var s:=sides(record)
	var stage:=String(state.get("stage","hearth"))
	var ours:Dictionary=record.get(s.home,{})
	var theirs:Dictionary=record.get(s.enemy,{})
	var threat:Dictionary=record.get("threat",{})
	var termination:Dictionary=record.get("termination",{})
	var strategic:Dictionary=record.get("strategic_outcome",{})
	var kind:=outcome_kind(record)
	var defending:=String(s.home)=="defender"
	var field:=bool(record.get("field_encounter",threat.get("field_encounter",false)))
	var raid:=String(threat.get("incident_kind",""))=="raid"
	var town:=_place_name(String(record.get("target_region_name",threat.get("target_region_name",""))))
	var near:=_place_name(String(state.get("near","")))
	# Who led the fight, and who leads the band now: the same man unless he
	# fell or was taken (military_campaign.gd _apply_force_commander_fate).
	var led:=String((ours.get("commander",{}) as Dictionary).get("name",""))
	var succession:Dictionary=record.get("commander_succession",{}) if record.get("commander_succession") is Dictionary else {}
	var general_full:=String(state.get("general_name",String(succession.get("now",led)) if not succession.is_empty() else led))
	var general:=_first_name(general_full)
	var leader:=_first_name(led) if _first_name(led)!="" else general
	var before:=int(ours.get("initial_troops",0))
	var noun:=Marks.noun(maxi(1,before),stage)
	var band:=("%s's %s" % [leader,noun]) if leader!="" else ("our "+noun)
	var enemy_people:=String(threat.get("source_name",""))
	var enemy_name:=("the "+enemy_people) if enemy_people!="" and not enemy_people.begins_with("UNIDENTIFIED") else "the strangers"
	var home_place:=String(state.get("home_name","home"))

	# Where it happened, in words. Home defended at its edge is "at home".
	var at_home:=defending and town=="" and not field and String(record.get("home_force_kind","field"))=="field"
	var where:=""
	var our_raid:=raid and not defending and town!=""
	if at_home:
		where="at "+home_place
	elif our_raid:
		where="outside "+town
	elif field or town=="":
		where=("near "+near) if near!="" else "in the open country"
	elif defending:
		where="at "+(town if town!="" else home_place)
	else:
		where="before "+town

	# Our ledger.
	var lost:=round_losses(record,String(s.home))
	var captured:=int(termination.get("prisoners",0)) if kind in ["lost","withdrew"] else 0
	var after_fight:=int(ours.get("remaining_troops",before-int(lost.total)))
	captured=mini(captured,after_fight)
	# Taken in the fight itself (a block broke and was ridden down) plus at the end.
	var taken_in_fight:=int(lost.taken)
	# Records without exchanges (older saves) still say how many were lost.
	var unsorted:=maxi(0,before-after_fight-int(lost.total))
	var detached:=clampi(int(record.get("detached",0)),0,after_fight-captured)
	var present:=maxi(0,after_fight-captured-detached)
	var morale:=float(ours.get("morale",0.0))
	var operation:Dictionary=state.get("operation",{})
	var earlier:Dictionary=state.get("earlier",{})
	var earlier_total:=int(earlier.get("killed",0))+int(earlier.get("wounded",0))+int(earlier.get("fled",0))+int(earlier.get("captured",0))+int(earlier.get("detached",0))
	var sent:=int(operation.get("sent",before+earlier_total))
	var elsewhere:=maxi(0,sent-before-earlier_total)
	var ledger:={"sent":sent,"earlier":earlier_total,"earlier_fights":int(earlier.get("fights",0)),"elsewhere":elsewhere,
		"in_fight":before,"killed":int(lost.killed),"wounded":int(lost.wounded),"fled":int(lost.fled),"unsorted":unsorted,"captured":captured+taken_in_fight,
		"detached":detached,"present":present,"morale":morale,"morale_words":morale_words(morale),"machines":int(ours.get("machines_lost",0))}

	# Their side, as our people saw it.
	var their_before:=int(theirs.get("initial_troops",0))
	var their_lost:=round_losses(record,String(s.enemy))
	var our_captives:=(int(termination.get("prisoners",0)) if kind in ["won","taken","uncontested"] else 0)+int(their_lost.taken)
	var held_field:=kind in ["won","taken","uncontested","nobody"]
	var countable:=their_before<=COUNTABLE
	var seen_low:=their_before if countable else roundi(float(their_before)*0.8)
	var seen_high:=their_before if countable else roundi(float(their_before)*1.2)
	var their_fell:=int(their_lost.killed)+int(their_lost.wounded)
	var theirs_ledger:={"seen_low":seen_low,"seen_high":seen_high,"exact":countable,"fell":their_fell,"killed":int(their_lost.killed),
		"wounded":int(their_lost.wounded),"fled":int(their_lost.fled),"taken":our_captives,"counted":held_field,
		"morale_words":morale_words(float(theirs.get("morale",0.0))),"name":enemy_name,
		"commander":_first_name(String((theirs.get("commander",{}) as Dictionary).get("name",""))),
		# The fate told at the end is the beaten side's general's.
		"commander_fate":String(termination.get("commander_fate","")) if kind in ["won","taken"] else ""}

	# How each side fought.
	var plan:Dictionary=record.get("tactics",{})
	var our_tactic:=String((plan.get(s.home,{}) as Dictionary).get("id",Tactics.BASELINE))
	var their_tactic:=String((plan.get(s.enemy,{}) as Dictionary).get("id",Tactics.BASELINE))
	var tactics:={"ours_id":our_tactic,"theirs_id":their_tactic,
		"ours":_tactic_line(our_tactic,stage,true) if not plan.is_empty() else "",
		"theirs":_tactic_line(their_tactic,stage,false) if not plan.is_empty() else ""}
	if not plan.is_empty() and our_tactic==their_tactic:
		tactics["ours"]=_both_line(our_tactic,stage); tactics["theirs"]=""
	if kind in ["uncontested","nobody"]: tactics={"ours_id":"","theirs_id":"","ours":"","theirs":""}
	# A strike by night: whether they were seen, and the chance they had.
	var surprise:Dictionary=(plan.get(s.home,{}) as Dictionary).get("surprise",{}) if plan.get(s.home) is Dictionary and (plan.get(s.home) as Dictionary).get("surprise") is Dictionary else {}
	var surprise_line:=""
	if not surprise.is_empty():
		var odds:=Tactics.chance_words(float(surprise.get("chance",0.0)))
		surprise_line=("We reached them in the dark unseen; the chance of that had been %s." % odds) if bool(surprise.get("unseen",false)) else ("Their watch saw us coming in the dark; the chance of reaching them unseen had been %s." % odds)
		tactics["ours"]=(String(tactics.ours)+" "+surprise_line).strip_edges()

	var headline:=_headline(kind,band,enemy_name,where,town,defending,their_tactic,raid,home_place)
	var phases:=_phases(record,s,band,enemy_name,kind,termination)
	if overrun(record):
		# One short beat: who overran whom, and what it cost.
		if kind in ["won","lost"]: headline=_overrun_headline(kind,before,their_before,enemy_name,where,band)
		phases=[_overrun_line(kind,theirs_ledger,ledger,their_before,termination)+(" "+surprise_line if surprise_line!="" else "")]
		tactics={"ours_id":our_tactic,"theirs_id":their_tactic,"ours":"","theirs":""}
	if kind=="taken" and their_before<=0:
		headline="%s walked into %s: nobody stood to defend it." % [_cap(band),town if town!="" else "the town"]
		phases=["There was nobody under arms to meet us."]
		tactics={"ours_id":"","theirs_id":"","ours":"","theirs":""}
	var now:=_standing(kind,band,enemy_name,town,ledger,state,strategic,defending,general,at_home,our_raid)
	# Home itself lost with the fight (siege_recovery.gd capture): everyone of
	# ours still there is in their hands.
	var occupation:Dictionary=strategic.get("player_occupation",{}) if strategic.get("player_occupation") is Dictionary else {}
	var army_now:Dictionary=state.get("army",{})
	if at_home and int(record.get("militia_id",-1))>=0 and not army_now.is_empty():
		var neighbours:=int(ledger.present)-int(army_now.get("troops",0))
		if neighbours>0 and kind in ["won","held","mutual","uncontested","nobody"]:
			now["now"]=String(now.now)+" The other %s who stood with the watch %s gone back to their work." % [exact(neighbours),"has" if neighbours==1 else "have"]
	var raided:Dictionary=strategic.get("raid_losses",{}) if strategic.get("raid_losses") is Dictionary else {}
	if at_home and not raided.is_empty():
		var taken_goods:PackedStringArray=PackedStringArray()
		for item in ["Food","Timber","Stone","Fiber Plants"]:
			var amount:=roundi(float(raided.get(item,0.0)))
			if amount>0: taken_goods.append("%s %s" % [exact(amount),String(item).to_lower()])
		if not taken_goods.is_empty(): now["now"]=String(now.now)+" They broke into the stores and carried off %s." % _and_list(taken_goods)
	if at_home and kind in ["lost","withdrew"] and not occupation.is_empty() and not bool(occupation.get("ok",false)):
		now["now"]=String(now.now)+" They broke through, but they are too few to hold %s; it is still ours." % home_place
	if at_home and kind in ["lost","withdrew"] and bool(occupation.get("ok",false)):
		now={"now":"%s is theirs now: they hold it, and the %s of ours still there are in their hands." % [home_place,exact(int(ledger.present))],
			"next":"What becomes of %s and its people is for you to say: talk with them, or gather our people elsewhere to take it back." % home_place}
	# Our general's own fate, told first: who fell or was taken, and who
	# leads the band now; or that he was hurt and got away.
	var fate_line:=""
	var our_fate:=String(termination.get("commander_fate","")) if kind in ["lost","withdrew"] else ""
	if not succession.is_empty():
		var fell:=_first_name(String(succession.get("fell",led)))
		var now_name:=_first_name(String(succession.get("now","")))
		fate_line="%s %s; %s the %s now." % [fell if fell!="" else "Our war leader","fell in the fight" if String(succession.get("fate",""))=="killed" else "was taken by them",("%s leads" % now_name) if now_name!="" else "another leads",noun]
	elif our_fate=="wounded, but escaped" and leader!="":
		fate_line="%s was wounded but got away." % leader
	if fate_line!="": now["now"]=fate_line+" "+String(now.now)
	# What the general did with the captives and spoils (military_campaign.gd
	# _settle_aftermath), in one line.
	var settled:Dictionary=record.get("aftermath_settled",{}) if record.get("aftermath_settled") is Dictionary else {}
	if String(settled.get("line",""))!="": now["now"]=String(now.now)+" "+String(settled.line)
	var first:=String(state.get("voice",""))=="first"
	if first:
		# The war leader tells it himself: the same account, his own voice.
		headline=_spoken(headline,band,general,noun)
		now={"now":_spoken(String(now.now),band,general,noun),"next":_spoken(String(now.next),band,general,noun)}
	var advice:=_advice(kind,ledger,theirs_ledger,town,state,defending,at_home,our_raid)
	var actions:Array=[]
	if not (record.get("rounds",[]) as Array).is_empty(): actions.append({"id":"watch","label":"Watch the battle"})
	actions.append({"id":"talk","label":("Talk to "+general) if general!="" else "Talk to the war leader"})
	actions.append({"id":"aftermath","label":"Decide the captives"} if bool(state.get("aftermath_pending",false)) else {"id":"continue","label":"Continue"})
	return {"kind":kind,"headline":headline,"where":where,"town":town,"band":band,"general":general,"general_full":general_full,
		"enemy":enemy_name,"ours":ledger,"theirs":theirs_ledger,"tactics":tactics,"phases":phases,
		"exchanges":(record.get("rounds",[]) as Array).size(),"duration":duration_words((record.get("rounds",[]) as Array).size()),
		"now":now.now,"next":now.next,"advice":advice,"actions":actions,"seed":int(record.get("seed",0)),"day":int(record.get("day",state.get("today",0))),"voice":"first" if first else ""}


## One of the account's sentences in the war leader's own voice: his band is
## "my band", his name is "I" or "me".
static func _spoken(text:String,band:String,general:String,noun:String)->String:
	var out:=text.replace(_cap(band),"My "+noun).replace(band,"my "+noun)
	if general=="": return out
	for pair in [[" has "," have "],[" keeps "," keep "],[" waits "," wait "],[" means "," mean "],[" left "," left "],[" is "," am "],[" sent "," sent "],[" let "," let "],[" gave "," gave "],[" had "," had "],[" traded "," traded "],[" leads "," lead "]]:
		out=out.replace(general+String(pair[0]),"I"+String(pair[1]))
	out=out.replace("with "+general,"with me")
	return out


static func _tactic_line(id:String,stage:String,ours:bool)->String:
	var name:=Tactics.name_of(id,stage)
	if stage=="hearth":
		# The hearth names are told from the doer's side ("met them head-on");
		# theirs are told from ours ("They met us head-on").
		if ours: return "We %s." % name
		return "They %s." % (" "+name+" ").replace(" them "," us ").replace(" their "," our ").strip_edges()
	return ("We fought with %s." if ours else "They fought with %s.") % Tactics._with_article(name)


## Both sides fought the same way: said once.
static func _both_line(id:String,stage:String)->String:
	var name:=Tactics.name_of(id,stage)
	if stage=="hearth": return "Both sides %s." % (" "+name+" ").replace(" them "," ").strip_edges()
	return "Both sides fought with %s." % Tactics._with_article(name)


static func _headline(kind:String,band:String,enemy:String,where:String,town:String,defending:bool,their_tactic:String,raid:bool,home_place:String)->String:
	var who:=_cap(band)
	match kind:
		"taken": return "%s took %s." % [who,town if town!="" else "the town"]
		"nobody": return ("Nobody stood to defend %s." % town) if town!="" and not defending else "%s found nobody to fight %s." % [who,where]
		"uncontested": return "%s did not stand: %s found them already scattered %s." % [_cap(enemy),band,where]
		"withdrew": return "%s broke off the fight %s and pulled back." % [who,where]
		"mutual": return "Both sides came apart %s; neither held the field." % where
		"held": return "Neither side gave way %s." % where
		"lost":
			if defending: return "%s broke through %s %s." % [_cap(enemy),band,where]
			return "%s threw back %s %s." % [_cap(enemy),band,where]
	# won
	if defending: return "%s drove off %s%s %s." % [who,enemy,(" raiders" if raid else ""),where]
	var from:=String({"fortified_camp":"from the ditch","entrenched_defence":"from their trenches","shield_wall":"off the field","dense_line":"off the field"}.get(their_tactic,"off the field"))
	return "%s drove %s %s %s." % [who,enemy,from,where]


## An overrun: one side so outmatched it was cut down, taken or scattered in
## a single exchange (combat_simulator.gd overrun_side).
static func overrun(record:Dictionary)->bool:
	return String((record.get("termination",{}) as Dictionary).get("type",""))=="overrun"


static func _overrun_headline(kind:String,ours:int,theirs:int,enemy:String,where:String,band:String)->String:
	var of_them:="%s of %s" % [count_words(theirs),enemy]
	if kind=="lost": return "%s overran %s, %s strong, %s." % [_cap(of_them),band,exact(ours),where]
	return "%s, %s strong, overran %s %s." % [_cap(band),exact(ours),of_them,where]


## "both", "all three", "one", "two": n out of a group of total.
static func _of_group(n:int,total:int,whose:String="them")->String:
	var ours:=whose=="ours"
	if n==total and total==2: return "both of %s" % whose
	if n==total and total>2: return "all %s of %s" % [exact(total) if ours else count_words(total),whose]
	return exact(n) if ours else count_words(n)


static func _overrun_line(kind:String,theirs:Dictionary,ours:Dictionary,their_before:int,termination:Dictionary)->String:
	var won:=kind!="lost"
	var beaten_total:=their_before if won else int(ours.in_fight)
	var fell:=int(theirs.fell) if won else int(ours.killed)+int(ours.wounded)
	var taken:=int(termination.get("prisoners",0))
	var ran:=maxi(0,beaten_total-fell-taken)
	var parts:Array[String]=[]
	var whose:="them" if won else "ours"
	if fell>0: parts.append("%s fell" % _of_group(fell,beaten_total,whose))
	if taken>0: parts.append("%s %s taken" % [_of_group(taken,beaten_total,whose),"was" if taken==1 else "were"])
	if ran>0: parts.append("%s got away" % _of_group(ran,beaten_total,whose))
	var beaten:=", ".join(parts) if not parts.is_empty() else "they broke at once"
	var hurt_killed:=int(theirs.killed) if not won else int(ours.killed)
	var hurt_wounded:=int(theirs.wounded) if not won else int(ours.wounded)
	var cost:=""
	if hurt_killed<=0 and hurt_wounded<=0: cost="none of %s was hurt" % ("ours" if won else "theirs")
	else:
		var bits:Array[String]=[]
		if hurt_killed>0: bits.append("%s of %s %s killed" % [exact(hurt_killed) if won else count_words(hurt_killed),"ours" if won else "theirs","was" if hurt_killed==1 else "were"])
		if hurt_wounded>0: bits.append("%s of %s %s" % [exact(hurt_wounded) if won else count_words(hurt_wounded),"ours" if won else "theirs","was cut" if hurt_wounded==1 else "were cut"])
		cost=" and ".join(bits)
	return "It was over at once: %s; %s." % [beaten,cost]


## A short account, exchange by exchange, from the recorded rounds.
static func _phases(record:Dictionary,s:Dictionary,band:String,enemy:String,kind:String,termination:Dictionary)->Array:
	var rounds:Array=record.get("rounds",[])
	var lines:Array=[]
	if rounds.is_empty():
		if kind=="nobody": lines.append("There was nobody under arms to meet us.")
		elif kind=="uncontested": lines.append("They were already beaten and scattering when we came up. No blow was struck and nobody on our side was hurt.")
		return lines
	var home:=String(s.home); var foe:=String(s.enemy)
	var first:Dictionary=rounds[0]
	lines.append("%s %s. We lost %s; they lost %s." % [_cap("in the first exchange"),_intensity_words(String(first.get("intensity",""))),_loss_words(int(first.get(home+"_losses",0)),true),_loss_words(int(first.get(foe+"_losses",0)))])
	var told:Dictionary={}
	var wavered:=false
	for index in range(1,rounds.size()):
		if lines.size()>=4: break
		var r:Dictionary=rounds[index]
		var event:=_event_words(r,home,band,enemy)
		if event!="" and not told.has(event):
			told[event]=true
			lines.append("In the %s exchange %s" % [_ordinal(index),event])
			continue
		var our_m:=float(r.get(home+"_morale",1.0)); var their_m:=float(r.get(foe+"_morale",1.0))
		if not wavered and (our_m<0.42 or their_m<0.42):
			wavered=true
			lines.append("By the %s exchange %s." % [_ordinal(index),("our people were wavering" if our_m<their_m else "%s were wavering" % enemy)])
	var ending:=""
	var exchanges:=rounds.size()
	var span:=duration_words(exchanges)
	match kind:
		"won","taken":
			match String(termination.get("type","")):
				"surrender": ending="After %s some of them threw down their arms; we took %s." % [span,_ours(int(termination.get("prisoners",0)),"captive","captives")]
				"pursuit": ending="After %s they broke and ran; we chased them and took %s." % [span,_ours(int(termination.get("prisoners",0)),"captive","captives")]
				_: ending="After %s they gave up the fight and drew off%s." % [span,(", leaving %s behind" % _ours(int(termination.get("prisoners",0)),"captive","captives")) if int(termination.get("prisoners",0))>0 else ""]
		"lost":
			ending="After %s we broke%s." % [span,(" and %s of ours were taken" % exact(int(termination.get("prisoners",0)))) if int(termination.get("prisoners",0))>0 else ""]
		"withdrew": ending="After %s we broke off and pulled back%s." % [span,(", losing %s as captives" % exact(int(termination.get("prisoners",0)))) if int(termination.get("prisoners",0))>0 else ""]
		"mutual": ending="After %s both sides had had enough and drew apart." % span
		_: ending="After %s neither side would give way, and the fighting stopped." % span
	lines.append(ending)
	return lines


static func _intensity_words(label:String)->String:
	return String({"Broken contact":"the lines barely touched","Skirmishing":"there was only skirmishing","Sustained combat":"the lines fought hard",
		"Close engagement":"it came to close fighting","Violent crisis":"it turned savage","Overrun":"it was over at once"}.get(label,"the lines met"))


static func _loss_words(n:int,ours:bool=false)->String:
	return "nobody" if n<=0 else (exact(n) if ours else count_words(n))


## The simulator's local events, in plain words and the right names.
static func _event_words(r:Dictionary,home:String,band:String,enemy:String)->String:
	var tactic_event:=String(r.get("tactic_event",""))
	if tactic_event!="": return tactic_event.substr(0,1).to_lower()+tactic_event.substr(1)
	var event:=String(r.get("event",""))
	var attacker:=band if home=="attacker" else enemy
	var defender:=enemy if home=="attacker" else band
	if event.begins_with("River Host punches"): return "%s broke through a weak point." % attacker
	if event.begins_with("Hill Guard catches"): return "%s caught the attack in a killing ground." % defender
	if event.begins_with("The defended ground"): return "the ground they held broke up the attack."
	if event.begins_with("A River Host cohort"): return "part of %s wavered and was cut up falling back." % attacker
	if event.begins_with("A Hill Guard cohort"): return "part of %s wavered and was cut up falling back." % defender
	if event.begins_with("Confused local fighting"): return "the fighting broke up into confusion on both sides."
	return ""


## Where things stand now and what happens next, from the real state.
static func _standing(kind:String,band:String,enemy:String,town:String,ledger:Dictionary,state:Dictionary,strategic:Dictionary,defending:bool,general:String,at_home:bool=false,our_raid:bool=false)->Dictionary:
	var army:Dictionary=state.get("army",{})
	var garrison:Dictionary=state.get("garrison",{})
	var siege:Dictionary=state.get("siege",{})
	var marching:Dictionary=state.get("marching_to",{})
	var who:=general if general!="" else "The war leader"
	var he:=general if general!="" else "the war leader"
	var now:=""; var next:=""
	var left:=int(army.get("troops",0)) if not army.is_empty() else int(ledger.present)
	var morale:=String(ledger.morale_words)
	if kind=="taken":
		var holding:=int(garrison.get("troops",ledger.detached))
		now="%s is ours. %s %s to hold it." % [town if town!="" else "The town",("%s left" % who) if general!="" else "We left",_ours(holding,"fighter","fighters")]
		if left>0: now+=" %s more %s still with %s." % [_cap(exact(left)),"is" if left==1 else "are",he]
		next="What becomes of %s and its people is for you to say." % (town if town!="" else "the town")
	elif not siege.is_empty():
		var days:=int(siege.get("days",0))
		now=("The siege of %s has begun." % String(siege.get("target_name",town))) if days<=1 else "Day %d of the siege of %s." % [days,String(siege.get("target_name",town))]
		next="%s keeps them shut in until the town gives in, our food runs short, or you call us off." % _cap(he)
	elif bool(state.get("engaged_again",false)):
		now="%s is fighting again already." % _cap(band)
		next="Another report will follow when that fight ends."
	elif left<=0 and garrison.is_empty():
		now="None of %s is still under arms there." % band
		next="Nobody is left to go on. The wounded and the scattered make their way home as they can."
	elif not marching.is_empty() and String(marching.get("name",""))!="":
		var dest:=String(marching.name)
		var days:=int(marching.get("days",0))
		if String(marching.get("kind",""))=="home":
			now="%s is on the road home with %s, %s." % [_cap(band),_ours(left,"fighter","fighters"),morale]
			next="They should be home in about %s." % _days(days)
		else:
			now="%s goes on toward %s with %s, %s." % [_cap(band),dest,_ours(left,"fighter","fighters"),morale]
			var verb:=String({"siege":"lay siege to it","raid":"raid its fields and stores"}.get(String(marching.get("kind","")),"attack it"))
			next="%s means to %s on arrival, about %s from now." % [_cap(he),verb,_days(days)]
	else:
		match kind:
			"won":
				if our_raid:
					now="We raided the fields and stores of %s; the town itself is still theirs. %s has %s, %s." % [town,who,_ours(left,"fighter","fighters"),morale]
					next="%s waits outside %s for your word. Nothing more happens there unless you give it." % [_cap(he),town]
				elif town!="" and not defending and not bool(strategic.get("region_captured",false)) and not hold_shortfall(strategic).is_empty():
					now="We won the fight at %s, but %s so the town is still theirs. %s has %s, %s." % [town,hold_words(hold_shortfall(strategic)),who,_ours(left,"fighter","fighters"),morale]
					next="Send more fighters, or let these eat and rest, and the town can be taken. %s waits outside %s for your word." % [_cap(he),town]
				elif town!="" and not defending and not bool(strategic.get("region_captured",false)):
					now="We hold the ground before %s, but they still hold the town; the gate is shut. %s has %s, %s." % [town,who,_ours(left,"fighter","fighters"),morale]
					next="%s waits outside %s for your word. Nothing more happens there unless you give it." % [_cap(he),town]
				elif at_home:
					# Beaten off at our own edge: the watch goes back to its posts.
					now="They are driven off. %s has %s under arms at home, %s." % [who,_ours(left,"fighter","fighters"),morale]
					next="The watch is back at its posts; nothing more is done unless you want them followed."
				else:
					now="The field is ours. %s has %s, %s." % [who,_ours(left,"fighter","fighters"),morale]
					next="%s waits where the fight was for your word." % _cap(he)
			"uncontested","nobody":
				now="Nothing stands in front of %s. %s has %s, %s." % [band,who,_ours(left,"fighter","fighters"),morale]
				next="%s waits there for your word." % _cap(he)
			"lost","withdrew":
				now="%s is beaten and has pulled back, %s, with %s left." % [_cap(band),morale,exact(left)]
				next="%s waits for your word. Nothing more happens unless you give it." % _cap(he)
			"mutual":
				now="Both sides have drawn apart. %s has %s, %s." % [who,_ours(left,"fighter","fighters"),morale]
				next="%s waits for your word." % _cap(he)
			_:
				now="Both sides still face each other. %s has %s, %s." % [who,_ours(left,"fighter","fighters"),morale]
				next="Nothing more happens there unless you give the word."
	if bool(state.get("aftermath_pending",false)): next+=" The captives and what we took wait on your word first."
	return {"now":now,"next":next}


static func _days(days:int)->String:
	return "a day" if days<=1 else "%s days" % count_words(days)


## What the war leader advises, in his own plain words.
static func _advice(kind:String,ours:Dictionary,theirs:Dictionary,town:String,state:Dictionary,defending:bool,at_home:bool=false,our_raid:bool=false)->String:
	var present:=int(ours.present)
	var their_left:=maxi(0,int(theirs.seen_high)-int(theirs.fell)-int(theirs.fled)-int(theirs.taken))
	var marching:Dictionary=state.get("marching_to",{})
	var shaken:=float(ours.morale)<0.42
	if kind in ["won","uncontested","nobody"] and not marching.is_empty() and String(marching.get("kind",""))!="home" and present>0:
		var dest:=String(marching.get("name","the town"))
		if shaken: return "Our people are badly shaken. Let me rest them a day before we try %s, or call us home." % dest
		return "The road to %s is open. We go on unless you call us back." % dest
	match kind:
		"taken": return "Leave enough here to keep the gate, and let the hurt go home to heal."
		"uncontested","nobody": return "Their band is broken. We can go on, or come home."
		"won":
			if our_raid: return "We have taken what we could carry from their fields. Call us home, or name the next town to raid."
			if town!="" and not defending:
				if their_left*2<present: return "They have few left behind the gate. Let me try it again while they are still shaken."
				return "Their gate is too strong for us as we are. Send me more fighters, or let me ring the town and starve it."
			if at_home: return "They may come again once they have mended. Keep the watch as strong as it is."
			return "We had the better of them. Tell me whether to press on or come home."
		"lost","withdrew":
			if present<=0: return ""
			if at_home: return "We could not hold them at our own edge. We need more drilled fighters at home, and a wall or ditch would help us hold them."
			return "We cannot beat them as we are. Let the hurt heal and give me more drilled fighters before we try them again."
		"mutual": return "Both sides are spent. Let me bring the band home to recover."
	return "Standing here trading blows costs us every day. Tell me to press them or bring us home."


# --- Text ---------------------------------------------------------------------

static func ledger_line(ours:Dictionary)->String:
	var parts:Array[String]=[]
	if int(ours.killed)>0: parts.append("%s killed" % exact(int(ours.killed)))
	if int(ours.wounded)>0: parts.append("%s wounded" % exact(int(ours.wounded)))
	if int(ours.fled)>0: parts.append("%s ran off" % exact(int(ours.fled)))
	if int(ours.get("unsorted",0))>0: parts.append("%s out of the fight, dead or hurt" % exact(int(ours.unsorted)))
	if int(ours.captured)>0: parts.append("%s taken captive" % exact(int(ours.captured)))
	if int(ours.detached)>0: parts.append("%s left to hold the town" % exact(int(ours.detached)))
	if int(ours.get("machines",0))>0: parts.append("%s %s lost" % [exact(int(ours.machines)),"machine" if int(ours.machines)==1 else "machines"])
	var lost:=", ".join(parts) if not parts.is_empty() else "nobody lost"
	var left:="none" if int(ours.present)<=0 else exact(int(ours.present))
	return "%s went in: %s; %s still with the band, %s." % [_cap(exact(int(ours.in_fight))),lost,left,String(ours.morale_words)]


static func sent_line(ours:Dictionary)->String:
	## Only when the band that fought is not the band that set out.
	var sent:=int(ours.sent)
	if sent<=int(ours.in_fight): return ""
	var parts:Array[String]=[]
	if int(ours.earlier)>0: parts.append("%s were lost or hurt in %s" % [exact(int(ours.earlier)),"the earlier fight" if int(ours.earlier_fights)<=1 else "%s earlier fights" % count_words(int(ours.earlier_fights))])
	if int(ours.elsewhere)>0: parts.append("%s fell out on the road, sick or lame" % exact(int(ours.elsewhere)))
	return "Of the %s who set out, %s." % [exact(sent),"; ".join(parts)] if not parts.is_empty() else ""


static func their_line(theirs:Dictionary)->String:
	var strength:=count_words(int(theirs.seen_low)) if bool(theirs.exact) else Marks.about_range(int(theirs.seen_low),int(theirs.seen_high))
	var text:="%s had %s." % [_cap(String(theirs.name)),strength]
	var parts:Array[String]=[]
	if int(theirs.fell)>0: parts.append(("we counted %s of theirs down" if bool(theirs.counted) else "we think we brought down %s") % count_words(int(theirs.fell)))
	if int(theirs.fled)>0: parts.append("%s ran" % count_words(int(theirs.fled)))
	if int(theirs.taken)>0: parts.append("we took %s captive" % exact(int(theirs.taken)))
	if not parts.is_empty(): text+=" "+_cap(", ".join(parts))+"."
	# Their leader's fate, when he fell or was hurt (a leader taken is told in
	# the general's settlement line).
	var leader:=String(theirs.get("commander",""))
	match String(theirs.get("commander_fate","")):
		"killed": text+=" Their leader%s fell." % ((", %s," % leader) if leader!="" else "")
		"wounded, but escaped": text+=" Their leader%s was wounded but got away." % ((", %s," % leader) if leader!="" else "")
	return text


## The whole account as one plain paragraph (council inbox, Chronicle).
static func text(account:Dictionary)->String:
	var lines:Array[String]=[String(account.headline)]
	var sent:=sent_line(account.ours)
	if sent!="": lines.append(sent)
	lines.append(ledger_line(account.ours))
	lines.append(their_line(account.theirs))
	var tactics:Dictionary=account.tactics
	if String(tactics.ours)!="": lines.append(String(tactics.ours)+(" "+String(tactics.theirs) if String(tactics.theirs)!="" else ""))
	lines.append(String(account.now))
	lines.append(String(account.next))
	if String(account.advice)!="" and String(account.get("voice",""))=="first": lines.append(String(account.advice))
	elif String(account.advice)!="": lines.append("%s says: \"%s\"" % [String(account.general) if String(account.general)!="" else "The war leader",String(account.advice)])
	return " ".join(lines)


# --- Live state ---------------------------------------------------------------

## Collects the state build() needs from the running campaign.
static func gather(record:Dictionary)->Dictionary:
	var mc:Node=WorldSimulation.military
	var state:={"stage":preload("res://scripts/hud/era_words.gd").stage(),"today":int(WorldSimulation.state.elapsed_days),"home_name":String(WorldSimulation.state.settlement_name)}
	if mc==null: return state
	var army_id:=int(record.get("home_force_id",0))
	var kind:=String(record.get("home_force_kind","field"))
	var index:int=mc._field_army_index(army_id) if kind=="field_army" and army_id>0 else -1
	var army:Dictionary=mc.field_armies[index] if index>=0 else {}
	state["army"]=army.duplicate(true) if index>=0 else {}
	if kind!="field_army": state["army"]={"troops":int(mc.home_army.get("troops",0))} if kind=="field" else {}
	var threat:Dictionary=record.get("threat",{})
	var region_id:=String(record.get("target_region_id",threat.get("target_region_id","")))
	var civ_id:=String(threat.get("source_civ_id",""))
	if region_id!="":
		var garrison:Dictionary=mc.occupation_force_for_region(civ_id,region_id) if mc.has_method("occupation_force_for_region") else {}
		if not garrison.is_empty() and String(record.get("home_side",""))=="attacker": state["garrison"]=garrison
	var siege:Dictionary=mc.active_siege
	if not siege.is_empty() and army_id>0 and int(siege.get("army_id",0))==army_id:
		state["siege"]={"days":int(siege.get("days",0)),"target_name":String((siege.get("threat",{}) as Dictionary).get("target_region_name",""))}
	for engagement_variant in mc.engagements.values():
		var engagement:Dictionary=engagement_variant
		if int(engagement.get("seed",0))!=int(record.get("seed",0)) and int(engagement.get("home_force_id",-1))==army_id and army_id>0: state["engaged_again"]=true
	state["aftermath_pending"]=not mc.pending_aftermath.is_empty()
	if not army.is_empty():
		var operation:Dictionary=army.get("operation",{})
		if not operation.is_empty(): state["operation"]=operation.duplicate(true)
		state["earlier"]=earlier_losses(mc.battle_history,army_id,int(operation.get("day",1<<40)) if not operation.is_empty() else (1<<40),int(record.get("seed",0)))
		state["marching_to"]=_marching(army,int(state.today))
		state["command_status"]=String(army.get("command_status",""))
		var commander:Dictionary=army.get("commander",{})
		if String(commander.get("name",""))!="": state["general_name"]=String(commander.name)
	if bool(record.get("field_encounter",false)) or region_id=="":
		state["near"]=_nearest_town(threat.get("target_position",{}))
	return state


## Losses from this operation's earlier fights (not this one).
static func earlier_losses(history:Array,army_id:int,since_day:int,skip_seed:int)->Dictionary:
	var out:={"killed":0,"wounded":0,"fled":0,"captured":0,"detached":0,"fights":0}
	for past_variant in history:
		var past:Dictionary=past_variant
		if int(past.get("home_force_id",0))!=army_id or String(past.get("home_force_kind",""))!="field_army": continue
		if int(past.get("seed",0))==skip_seed or int(past.get("day",-1))<since_day: continue
		var s:=sides(past)
		var lost:=round_losses(past,String(s.home))
		var kind:=outcome_kind(past)
		out.killed+=int(lost.killed); out.wounded+=int(lost.wounded); out.fled+=int(lost.fled)
		if kind in ["lost","withdrew"]: out.captured+=int((past.get("termination",{}) as Dictionary).get("prisoners",0))
		out.detached+=int(past.get("detached",0))
		out.fights+=1
	return out


static func _marching(army:Dictionary,today:int)->Dictionary:
	var planned:Dictionary=army.get("city_operation",{})
	var days:=maxi(0,int(army.get("arrival_day",today))-today)
	if not planned.is_empty():
		var order:Dictionary=army.get("court_order",{})
		var name:=String(order.get("city_name",""))
		if name=="":
			var report:Dictionary=WorldSimulation.world.city_intelligence.known("player",String(planned.get("region_id","")))
			name=String(report.get("name",""))
		return {"name":name,"days":days,"kind":"siege" if bool(planned.get("besiege",false)) else ("raid" if bool(planned.get("raid",false)) else "attack")}
	if String(army.get("status",""))=="moving" and String(army.get("destination_id",""))=="player_home":
		return {"name":"home","days":days,"kind":"home"}
	return {}


## A known town this close names a fight ("near Tsaren"); farther off it is
## told by its ground or its distance from home. The battle panel, the
## report and the map (hud/battle_marker_source.gd) all use this one rule.
const NEAR_TOWN_KM:=25.0


static func _nearest_town(position:Variant)->String:
	if not position is Dictionary or not (position as Dictionary).has_all(["x","z"]): return ""
	var at:=Vector2(float(position.x),float(position.z))
	var world:Variant=WorldSimulation.world if WorldSimulation!=null else null
	if world==null or world.get("city_intelligence")==null: return ""
	var best:=""; var best_d:=NEAR_TOWN_KM
	for city_variant in world.city_intelligence.known_cities("player","",false):
		var city:Dictionary=city_variant
		var p:Dictionary=city.get("position",{}) if city.get("position") is Dictionary else {}
		if not p.has_all(["x","z"]): continue
		var d:=at.distance_to(Vector2(float(p.x),float(p.z)))
		if d<best_d: best_d=d; best=String(city.get("name","")).trim_prefix("Reported home of ")
	return best


## What an army is doing, in a few plain words, for its card and the forces
## screen: fighting, besieging, marching to attack, going home, or waiting
## for the ruler's word after a fight.
static func doing(army:Dictionary)->String:
	var mc:Node=WorldSimulation.military
	if mc==null: return ""
	var id:=int(army.get("army_id",0))
	var today:=int(WorldSimulation.state.elapsed_days)
	var fights:Array=mc.engagements.values()
	for fight_variant in fights:
		var fight:Dictionary=fight_variant
		var in_it:=int(fight.get("home_force_id",-1))==id
		for member in fight.get("command_participants",[]):
			if int((member as Dictionary).get("army_id",-1))==id: in_it=true
		if in_it:
			var threat:Dictionary=fight.get("threat",{})
			var place:=_place_name(String(threat.get("target_region_name","")))
			var who:=String(threat.get("source_name","them"))
			return "fighting the %s%s, %s exchanges so far" % [who,(" at "+place) if place!="" else "",count_words((fight.get("rounds",[]) as Array).size())]
	var siege:Dictionary=mc.active_siege
	if not siege.is_empty() and int(siege.get("army_id",0))==id:
		return "laying siege to %s, day %d" % [String((siege.get("threat",{}) as Dictionary).get("target_region_name","the town")),maxi(1,int(siege.get("days",0)))]
	var marching:=_marching(army,today)
	if not marching.is_empty():
		if String(marching.kind)=="home": return "on the road home, %s out" % _days(int(marching.days))
		var verb:=String({"siege":"lay siege to","raid":"raid"}.get(String(marching.kind),"attack"))
		return "marching to %s %s, %s out" % [verb,String(marching.name) if String(marching.name)!="" else "the town",_days(int(marching.days))]
	if String(army.get("status",""))=="moving":
		# Going after a band that was seen (its label is "INTERCEPT · who"):
		# said as the map card says it (hud/army_marks.gd doing).
		if String(army.get("destination_name","")).to_upper().begins_with("INTERCEPT"): return Marks.doing({"status":"moving","destination_name":String(army.get("destination_name",""))})
		return "marching to %s" % (_place_name(String(army.get("destination_name",""))) if _place_name(String(army.get("destination_name","")))!="" else "the marked ground")
	if Marks.at_home(army,WorldSimulation.world.player_world_origin): return "at home"
	for past_variant in mc.battle_history:
		var past:Dictionary=past_variant
		if int(past.get("home_force_id",-1))!=id or String(past.get("home_force_kind",""))!="field_army": continue
		if today-int(past.get("day",-9999))<=5:
			var where:=_place_name(String(past.get("target_region_name","")))
			return "waiting for your word after the fight%s" % ((" at "+where) if where!="" else "")
		break
	var here:=_place_name(String(army.get("location_name","")))
	var km:=Marks.home_km(army,WorldSimulation.world.player_world_origin)
	if (here=="" or Marks._generic_place(here) or here.to_lower()=="home settlement") and km>=Marks.HOME_RADIUS_KM: return "camped %s from home" % Marks.km_words(km)
	return ("holding "+here) if here!="" and here!="Commanded ground" else "waiting where you sent it"

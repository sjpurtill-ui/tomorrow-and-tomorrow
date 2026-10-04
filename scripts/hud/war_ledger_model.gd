extends RefCounted
## THE WAR LEDGER: each feud or war with a people we know, read the way HOI4's
## war overview reads one. Everything comes from the one ledger (war_loop.gd)
## and the forces' own records; nothing is estimated here.
##   - the dead on each side;
##   - their strength against ours, on the war leader's own scale (standing.gd);
##   - how worn each people is, with marks where the engine's rules turn:
##     from PEACE_WORN they may send someone to end it, and from ENEMY_SPENT
##     they keep their raiders home;
##   - the quiet since blood was last spilled, with the points where a feud
##     stops being hot (FEUD_HOT_DAYS) and goes cold (FEUD_COLD_DAYS);
##   - their raids and our strikes, the war leader's band out against them,
##     and our bands at their towns.
## A feud that ended lately stays listed for a while, with how it ended.
## Static helpers; preload. The Feuds page draws it (hud/war_ledger_board.gd).

const WarLoop:=preload("res://scripts/war_loop.gd")
const WarOdds:=preload("res://scripts/war_odds.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const Counter:=preload("res://scripts/hud/army_counter.gd")
const Logistics:=preload("res://scripts/equipment_logistics.gd")

## A feud that ended stays on the page this long (days).
const ENDED_SHOWN_DAYS:=2*365
## What the war leader's band against them is doing (war_loop objectives).
const OP_WORDS:={"war_guard":"guarding the approaches","war_pursue":"on the raiders' trail","war_track":"tracking the raiders","war_burn":"gone to burn their stores",
	"war_chief":"gone for their headman","war_parley":"gone to talk","war_pay":"taking them the blood price","war_price":"asking a blood price","war_general":"in the field","war_rest":"resting","war_let":"standing down"}
## How a feud ended (war_loop _end_feud's why), in plain words.
const END_WORDS:={"marriage":"kin by marriage now","blood price":"a blood price was paid","parley":"a parley held","peace sought":"their peace-seeker was heard","ransom":"a ransom was paid",
	"went cold":"three quiet winters: it went cold","broken":"their people are broken","submission":"they bowed to the god and pay tribute"}


## Every feud and war with a people we know, wars first and then the hottest;
## the feuds that ended lately last.
static func entries(day:int=-1)->Array[Dictionary]:
	if day<0: day=int(GameState.elapsed_days)
	var out:Array[Dictionary]=[]
	if WorldSimulation.world==null: return out
	var fronts:=_fronts()
	var bands:=bands_by_civ()
	var listed:={}
	for civ_variant in fronts.keys():
		var civ_id:=String(civ_variant)
		var f:Dictionary=fronts[civ_variant] if fronts[civ_variant] is Dictionary else {}
		var war:Dictionary=f.get("war",{}) if f.get("war") is Dictionary else {}
		if war.is_empty() or not _alive(civ_id): continue
		var quiet:=day-int(war.get("last_fight",war.get("start",day)))
		var entry:=_common(civ_id,f,bands,day)
		entry.merge({"kind":"war","hot":true,"since":int(war.get("start",day)),"days":maxi(0,day-int(war.get("start",day))),"cause":String(war.get("cause","")),
			"our_dead":int(war.get("our_dead",0)),"their_dead":int(war.get("their_dead",0)),"our_worn":clampf(float(war.get("our_exh",0.0)),0.0,1.0),
			"their_worn":clampf(float(war.get("their_exh",0.0)),0.0,1.0),"quiet":maxi(0,quiet)},true)
		out.append(entry); listed[civ_id]=true
	for view in WarLoop.feuds(day):
		var civ_id:=String(view.civ_id)
		if listed.has(civ_id): continue
		var f:Dictionary=fronts.get(civ_id,{}) if fronts.get(civ_id) is Dictionary else {}
		var entry:=_common(civ_id,f,bands,day)
		var raid:Dictionary=view.get("last_raid",{})
		entry.merge({"kind":"feud","hot":bool(view.hot),"since":int(view.since),"days":int(view.days),"cause":WarLoop._feud_cause(civ_id),
			"our_dead":int(view.our_dead),"their_dead":int(view.their_dead),"raids":int(view.raids),"strikes":int(view.strikes),
			"our_worn":clampf(float(f.get("our_exh",0.0)),0.0,1.0),"their_worn":clampf(float(f.get("their_exh",0.0)),0.0,1.0),
			"quiet":int(view.quiet),"home_known":bool(view.home_known),"way":String(view.get("way","")),"open_fight":bool(view.get("open_fight",false)),
			"peace_due":WarLoop.peace_due(civ_id,day),"blood_price":WarLoop.blood_price(civ_id),
			"last_raid":{} if raid.is_empty() else {"target":String(raid.get("target","")),"days_ago":day-int(raid.get("day",day)),"our_dead":int(raid.get("our_dead",0)),"taken":int(raid.get("taken",0))}},true)
		out.append(entry); listed[civ_id]=true
	# A people gathering every spear against us is on the page whether or not
	# a feud runs (world_answer.gd): the days until it marches lead its card.
	var answer:=load("res://scripts/world_answer.gd") as GDScript
	if answer!=null:
		for civ in WorldSimulation.world.civilizations:
			var civ_id:=String((civ as Dictionary).get("id","")) if civ is Dictionary else ""
			if civ_id=="" or not _alive(civ_id): continue
			# Only what our watchers have heard of (world_answer heard_of_arming).
			var arm:Dictionary=answer.call("heard_of_arming",civ_id)
			if arm.is_empty(): continue
			var left:=maxi(0,int(arm.get("march",day))-day)
			if listed.has(civ_id):
				for e in out:
					if String((e as Dictionary).civ_id)==civ_id: (e as Dictionary)["arming_days"]=left
				continue
			var f2:Dictionary=fronts.get(civ_id,{}) if fronts.get(civ_id) is Dictionary else {}
			var entry2:=_common(civ_id,f2,bands,day)
			entry2.merge({"kind":"feud","hot":true,"since":int(arm.get("since",day)),"days":maxi(0,day-int(arm.get("since",day))),"cause":"what they remember of us",
				"our_dead":int(f2.get("our_dead",0)),"their_dead":int(f2.get("their_dead",0)),"raids":0,"strikes":0,"our_worn":0.0,"their_worn":clampf(float(f2.get("their_exh",0.0)),0.0,1.0),
				"quiet":99999,"home_known":WarLoop.home_known(civ_id),"way":"","open_fight":false,"peace_due":false,"blood_price":WarLoop.blood_price(civ_id),"last_raid":{},"arming_days":left},true)
			out.append(entry2); listed[civ_id]=true
	for civ_variant in fronts.keys():
		var civ_id:=String(civ_variant)
		if listed.has(civ_id) or not fronts[civ_variant] is Dictionary: continue
		var ended:=ended_view(civ_id,fronts[civ_variant],day)
		if not ended.is_empty(): out.append(ended)
	return out


## A feud that ended within ENDED_SHOWN_DAYS: {civ_id, name, kind:"ended",
## how, ended_day, ago, our_dead, their_dead}; {} otherwise.
static func ended_view(civ_id:String,f:Dictionary,day:int)->Dictionary:
	if int(f.get("level",0))>=1 or not (f.get("war",{}) as Dictionary).is_empty(): return {}
	var ended_day:=-1; var how:=""
	var end:Dictionary=f.get("feud_end",{}) if f.get("feud_end") is Dictionary else {}
	if not end.is_empty(): ended_day=int(end.get("day",-1)); how=String(end.get("why",""))
	if f.has("cold_day") and int(f.cold_day)>ended_day: ended_day=int(f.cold_day); how="went cold"
	if ended_day<0 or day-ended_day>ENDED_SHOWN_DAYS: return {}
	if not _alive(civ_id): how="broken"
	return {"civ_id":civ_id,"name":WarLoop._name(civ_id),"kind":"ended","how":how,"how_words":String(END_WORDS.get(how,how)),"ended_day":ended_day,"ago":day-ended_day,
		"our_dead":int(f.get("our_dead",0)),"their_dead":int(f.get("their_dead",0))}


## What every entry shares: their name, their strength against ours, their
## dread of us, the war leader's band out against them and our bands at their
## towns.
static func _common(civ_id:String,f:Dictionary,bands:Dictionary,day:int)->Dictionary:
	var op:Dictionary=f.get("op",{}) if f.get("op") is Dictionary else {}
	var war:Dictionary=f.get("war",{}) if f.get("war") is Dictionary else {}
	if op.is_empty() and war.get("op") is Dictionary: op=war.op
	var band:={}
	if not op.is_empty():
		var objective:=String(op.get("objective",""))
		band={"objective":objective,"words":String(OP_WORDS.get(objective,"out against them")),"men":int(op.get("band",0)),"general":String(op.get("general","")),
			"days_left":maxi(0,int(op.get("due",day))-day)}
	# Their strength as our watchers reckon it (standing.gd estimate: how well
	# we know them and our cunning), the same reckoning the Standing page shows.
	# Too little known of them: unknown, as the Standing card says it.
	var truth:=WarLoop.ratio(civ_id)
	var est:=preload("res://scripts/standing.gd").estimate(civ_id,"strength_ratio",truth,true)
	var unknown:=bool(est.get("unknown",false))
	return {"civ_id":civ_id,"name":WarLoop._name(civ_id),"strength":1.0 if unknown else float(est.value),"strength_unknown":unknown,"strength_exact":not unknown and bool(est.exact),
		"strength_low":float(est.low),"strength_high":float(est.high),"dread":WarLoop._dread(civ_id),"band":band,"bands":bands.get(civ_id,[])}


## The war leader's measure of their strength against ours, as the odds:
## {raw (ours over theirs), odds (stronger over weaker), ours}.
## {"unknown": true} too when we know too little of them to say.
static func odds(entry:Dictionary)->Dictionary:
	if bool(entry.get("strength_unknown",false)): return {"raw":1.0,"odds":1.0,"ours":true,"unknown":true}
	var theirs:=maxf(0.01,float(entry.get("strength",1.0)))
	var raw:=1.0/theirs
	return {"raw":raw,"odds":maxf(raw,1.0/raw),"ours":raw>=1.0}

## "about 2 to 1 for us": their strength against ours in words (our
## watchers' reckoning, with its band when we do not know them well).
static func odds_words(entry:Dictionary)->String:
	if bool(entry.get("strength_unknown",false)): return "unknown: we know too little of them to say how strong they are"
	var o:=odds(entry)
	var words:=WarOdds.words(float(o.odds),bool(o.ours))
	if entry.has("strength_exact") and not bool(entry.strength_exact):
		words+=" by our watchers' reckoning (theirs somewhere between %.1f and %.1f times ours)" % [float(entry.get("strength_low",1.0)),float(entry.get("strength_high",1.0))]
	return words


## Our bands at or bound for their towns: {civ_id: [{army_id, name, troops,
## glyph, where}]}.
static func bands_by_civ()->Dictionary:
	var owner:={}
	var intelligence:Variant=CivilizationSystem.get("city_intelligence")
	if intelligence!=null:
		for city in intelligence.known_cities():
			owner[String(city.get("city_id",""))]=String(city.get("controller",city.get("civ_id",""))) if String(city.get("controller",""))!="" else String(city.get("civ_id",""))
	var out:={}
	for force_variant in MilitaryCampaign.field_armies:
		if not force_variant is Dictionary: continue
		var force:Dictionary=force_variant
		if int(force.get("troops",0))<=0: continue
		var moving:=String(force.get("status",""))=="moving"
		var place:=String(force.get("destination_id" if moving else "location_id",""))
		var civ_id:=""
		var operation:Dictionary=force.get("city_operation",{}) if force.get("city_operation") is Dictionary else {}
		if not operation.is_empty(): civ_id=String(operation.get("civ_id",""))
		if civ_id=="": civ_id=String(owner.get(place,""))
		if civ_id=="" or civ_id=="player": continue
		var where:=String(force.get("destination_name" if moving else "location_name",""))
		if not out.has(civ_id): out[civ_id]=[]
		# Named as the army bar and the war chart name it ("Ennis's band").
		var name:=Logistics.force_name({"commander":force.get("commander",{}),"troops":int(force.get("troops",0)),"name":force.get("name","")})
		(out[civ_id] as Array).append({"army_id":int(force.get("army_id",0)),"name":name,"troops":int(force.get("troops",0)),
			"glyph":Counter.main_glyph(force.get("formations",[]),"spear"),"where":("bound for %s" % where if moving else "at %s" % where) if where!="" else ("on the march" if moving else "in their land")})
	return out


## "Hot", "Simmering", "War", "Ended": the chip on the card.
static func state_word(entry:Dictionary)->String:
	match String(entry.get("kind","")):
		"war": return "War"
		"ended": return "Ended"
	return "Hot" if bool(entry.get("hot",false)) else "Simmering"

## "Feud · 2 winters · for the killing of their envoy".
static func subtitle(entry:Dictionary)->String:
	var parts:=PackedStringArray()
	parts.append("War" if String(entry.get("kind",""))=="war" else "Feud")
	var days:=int(entry.get("days",0))
	parts.append("begun today" if days<=0 else span_words(days))
	var cause:=String(entry.get("cause",""))
	if cause!="" and cause!="the war": parts.append("over %s" % cause)
	return " · ".join(parts)

## "today", "40 days", "a winter", "3 winters".
static func span_words(days:int)->String:
	if days<=0: return "today"
	if days<60: return "%d %s" % [days,"day" if days==1 else "days"]
	if days<300: return "%d months" % roundi(float(days)/30.0)
	var winters:=maxi(1,roundi(float(days)/365.0))
	return "a winter" if winters==1 else "%s winters" % EraWords.count_word(winters)

## Where the feud stands on the quiet clock, in the engine's own days:
## "Hot · 325 days more without blood and envoys may come again; cold in 1,055".
static func clock_words(entry:Dictionary)->String:
	var quiet:=int(entry.get("quiet",0))
	if quiet>=99999: return "No blood spilled yet."
	var hot_left:=WarLoop.FEUD_HOT_DAYS-quiet
	var cold_left:=WarLoop.FEUD_COLD_DAYS-quiet
	var since:="Blood was spilled today." if quiet<=0 else "%s since blood." % span_words(quiet)
	if hot_left>0: return "%s Hot %s more; cold after %s without blood." % [since,span_words(hot_left),span_words(cold_left)]
	if cold_left>0: return "%s since blood. Cold in %s if nobody kills." % [span_words(quiet),span_words(cold_left)]
	return "%s since blood: it goes cold when the war leader's business with them is done." % span_words(quiet)

## The ways the engine lets this feud end, with its numbers.
static func ending_words(entry:Dictionary)->String:
	if String(entry.get("kind",""))!="feud": return ""
	var parts:=PackedStringArray()
	var worn:=float(entry.get("their_worn",0.0)); var dread:=float(entry.get("dread",0.0))
	if bool(entry.get("peace_due",false)): parts.append("They may send someone to end it any day now")
	elif worn>=WarLoop.PEACE_WORN or dread>=WarLoop.PEACE_DREAD: parts.append("They may send someone to end it after %d quiet days" % WarLoop.PEACE_QUIET_DAYS)
	else: parts.append("They will not seek peace until worn to %d%% or in dread of us" % roundi(WarLoop.PEACE_WORN*100.0))
	parts.append("we can pay a blood price of %s food" % EraWords.grouped(roundi(float(entry.get("blood_price",0.0)))))
	parts.append("a marriage ends it")
	return "; ".join(parts)+"."


static func _fronts()->Dictionary:
	var s:Dictionary=WarLoop.state()
	return s.get("fronts",{}) if s.get("fronts") is Dictionary else {}

static func _alive(civ_id:String)->bool:
	var civ:Dictionary=WarLoop._civ(civ_id)
	return not civ.is_empty() and bool(civ.get("alive",true))

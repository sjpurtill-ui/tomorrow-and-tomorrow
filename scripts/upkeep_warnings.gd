extends RefCounted
## THE UPKEEP OF THE TOWN: the official who runs the town's work warns the god
## when its buildings are wearing out faster than they are mended.
##
## The town's condition (SettlementModel.city_form().condition) falls 0.02 a
## month from wear and rises with builders and paid materials
## (_advance_city_form). Low condition shrinks what the stores hold, what the
## workshops and stores do, and how well work goes (_built_capacities), and it
## draws every standing building as stressed. Nothing forced the player to
## notice; now the settlement's leader (or the Hearth Chief if the town has no
## leader of its own) raises it as a court matter:
##   slipping  wearing faster than mended, still sound: a heads-up with the
##             number of builders needed to hold it.
##   failing   below 0.48 and still falling.
##   floor     at the bottom (0.05), nothing left to lose but everything to mend.
## Each new stage is news: a Chronicle notice (the card opens the court on the
## official) and a line in the year's entry. While unresolved the matter is
## renewed at most once a season, quietly; if the god says "let it be" it is
## not raised again unless things get worse. When the town is sound again the
## official says so, and an order to build more is lifted.
##
## The only game-initiated talk is envoys (player-initiated-court): this waits
## as a matter until summoned. Offline the court offers choices; online the
## god's own words choose the same answers (typed_choice) or go to the live
## voice with the same facts. Moving people to building uses the settlement's
## real focus (GovernmentPeopleSystem owns daily labour).
##
## State lives in ForeignDiplomacy.audiences["upkeep"] (saved with the court;
## older saves start empty).

const Hall:=preload("res://scripts/audience_hall.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")
const EraNames:=preload("res://scripts/era_names.gd")

const KEY:="upkeep"
const VERSION:=1
const STAGES:=["sound","slipping","failing","floor"]
## Sampled once a month, as the town's condition changes monthly.
const SAMPLE_DAYS:=30
## Unresolved trouble is raised again at most once a season.
const RENEW_DAYS:=90
const FAILING_BELOW:=0.48
const FLOOR_AT:=0.08
const SOUND_AT:=0.58
## A heads-up only while the town could still turn bad within this many months.
const HEADS_UP_MONTHS:=18.0
const HEADS_UP_BELOW:=0.75
## Clearly falling (to raise it) versus clearly holding (to drop a heads-up).
const FALLING:=-0.004
const HOLDING:=0.002
## Capacity reference: a sound, well-kept town.
const SOUND_REFERENCE:=0.8
const NUMBER_WORDS:=["no one","one","two","three","four","five","six","seven","eight","nine","ten","eleven","twelve","thirteen","fourteen","fifteen","sixteen","seventeen","eighteen","nineteen","twenty"]
## The god's typed words (online) that name an answer.
const WORDS:={
	"more_builders":["build","mend","repair","fix","patch","rebuild","roof","more hands","more people","more workers","put people","builders","thatch","clay pit","cut timber"],
	"accept":["let it be","let it go","leave it","let them fall","accept","not now","later","ignore","no more hands","it can wait"],
}

# --------------------------------------------------------------------------
# State
# --------------------------------------------------------------------------

static func state()->Dictionary:
	ForeignDiplomacy.ensure()
	var raw:Variant=ForeignDiplomacy.audiences.get(KEY,{})
	var s:Dictionary=raw if raw is Dictionary else {}
	if not s.is_empty() and (int(s.get("world_seed",GameState.world_seed))!=int(GameState.world_seed) or float(s.get("last_sample",0))>GameState.elapsed_days+1.0): s.clear()
	if int(s.get("version",0))!=VERSION:
		s["version"]=VERSION
		s["world_seed"]=int(GameState.world_seed)
		for key in ["stage","accepted"]:
			if not s.get(key) is String or not String(s.get(key)) in STAGES: s[key]="sound" if key=="stage" else ""
		for key in ["last_sample","last_filed","stage_day"]:
			if not _num(s.get(key)): s[key]=-99999
		if not s.get("order") is Dictionary: s["order"]={}
	ForeignDiplomacy.audiences[KEY]=s
	return s

static func valid_state(data:Variant)->bool:
	if not data is Dictionary: return false
	var d:Dictionary=data
	for key in ["stage","accepted"]:
		if d.has(key) and (not d[key] is String or (String(d[key])!="" and not String(d[key]) in STAGES)): return false
	for key in ["last_sample","last_filed","stage_day","version","world_seed"]:
		if d.has(key) and not _num(d[key]): return false
	if d.has("order") and not d.order is Dictionary: return false
	return JSON.stringify(d).length()<4000

static func _num(value:Variant)->bool:
	return (value is int or value is float) and is_finite(float(value))

static func _day()->int:
	return int(GameState.elapsed_days)

static func _rank(stage:String)->int:
	return maxi(0,STAGES.find(stage))

# --------------------------------------------------------------------------
# The real state of the town
# --------------------------------------------------------------------------

static func primary_settlement_id()->String:
	for settlement in GameState.player_settlements:
		if bool(settlement.get("primary",false)): return String(settlement.get("id",""))
	return String(GameState.player_settlements[0].get("id","")) if not GameState.player_settlements.is_empty() else ""

static func facts()->Dictionary:
	## Everything the official says comes from here: the same numbers
	## SettlementModel._advance_city_form and _built_capacities use.
	var model:=WorldSimulation.settlements
	var form:Dictionary=model.city_form()
	var condition:=clampf(float(form.get("condition",0.9)),0.0,1.0)
	var tier:=float(form.get("tier",0.0))
	var paid:=clampf(float(form.get("materials_paid",1.0)),0.0,1.0)
	var population:=maxf(1.0,float(model.call("_primary_population")))
	var heads:=maxi(0,int(GameState.population_allocations.get("Construction",0)))
	var effective:=maxf(0.0,float(GameState.effective_workers("Construction")))
	var per_head:=effective/float(heads) if heads>0 else 0.8
	per_head=maxf(0.05,per_head)
	var share:=clampf(effective/maxf(1.0,population*0.05),0.0,1.0)
	var change:=0.04*share*paid-0.02
	# Builders needed to hold the town as it is (share*paid=0.5) and to mend it
	# at about a hundredth a month (share*paid=0.75); none are enough when
	# fewer than half the materials can be paid.
	var hold:=-1
	var mend:=-1
	if paid>=0.5: hold=ceili(population*0.05*(0.5/paid)/per_head)
	if paid>=0.75: mend=ceili(population*0.05*(0.75/paid)/per_head)
	elif paid>=0.5: mend=ceili(population*0.05/per_head)
	var basket:Dictionary={"Timber":.45,"Fiber Plants":.2,"Clay":.2,"Stone":.15} if tier<3.0 else {"Stone":.45,"Timber":.3,"Clay":.15,"Limestone":.1}
	var short:=""
	var lowest:=INF
	for item:String in basket:
		var have:=float(GameState.resource_stockpiles.get(item,0.0))
		if have/float(basket[item])<lowest: lowest=have/float(basket[item]); short=item
	var stressed:=0
	var standing:=0
	for plot in GameState.settlement_plots:
		var status:=String(plot.get("status",""))
		if String(plot.get("land_use","")) in ["field","pasture","water","waste","temporary_encampment"]: continue
		if status in ["active","stressed","damaged"]: standing+=1
		if status in ["stressed","damaged"]: stressed+=1
	var months:=-1.0
	if change<0.0 and condition>FAILING_BELOW: months=(condition-FAILING_BELOW)/-change
	return {"condition":snappedf(condition,0.01),"monthly_change":snappedf(change,0.001),"population":roundi(population),"builders":heads,
		"builders_effective":snappedf(effective,0.1),"builders_to_hold":hold,"builders_to_mend":mend,"materials_paid":snappedf(paid,0.01),
		"short_material":short if paid<0.95 else "","fabric_tier":tier,"stressed_buildings":stressed,"standing_buildings":standing,
		"months_until_failing":snappedf(months,0.1),"capacity_share":snappedf(clampf(condition/SOUND_REFERENCE,0.0,1.0),0.01)}

static func stage_for(f:Dictionary,current:String)->String:
	## The stage the town is in now, with hysteresis against the current one.
	var c:=float(f.condition)
	var d:=float(f.monthly_change)
	if c<=FLOOR_AT and d<=0.0: return "floor"
	if c<FAILING_BELOW and d<0.0: return "failing"
	if current in ["failing","floor"]:
		# Trouble stays trouble until the town is sound again; climbing off
		# the floor is failing, not recovery.
		return "sound" if c>=SOUND_AT else "failing"
	var months:=float(f.months_until_failing)
	if current=="slipping":
		return "sound" if d>=HOLDING or c>=HEADS_UP_BELOW+0.03 else "slipping"
	if c<HEADS_UP_BELOW and d<=FALLING and months>=0.0 and months<=HEADS_UP_MONTHS: return "slipping"
	return "sound"

# --------------------------------------------------------------------------
# Daily: sample once a month and raise what is news
# --------------------------------------------------------------------------

static func daily(day:int)->void:
	if WorldSimulation.actor_id!="player" or GameState.settlement_plots.is_empty(): return
	var s:=state()
	if day-int(s.last_sample)<SAMPLE_DAYS: return
	s.last_sample=day
	var f:=facts()
	var before:=String(s.stage)
	var after:=stage_for(f,before)
	var had_order:=not (s.order as Dictionary).is_empty()
	_follow_order(s,f,day)
	if after!=before:
		s.stage=after
		s.stage_day=day
		if after=="sound":
			_drop_matters()
			if before in ["failing","floor"]: _recovered(f,day,had_order)
			s.accepted=""
			return
		if _rank(after)>_rank(before):
			_file(f,after,day,true)
			return
		# Climbing off the floor: still failing, quietly.
		return
	if after=="sound": return
	# Unresolved: renewed at most once a season, and not after the god said to
	# let it be (unless it got worse, which files above).
	if String(s.accepted)!="" and _rank(after)<=_rank(String(s.accepted)): return
	if float(f.monthly_change)>0.0: return
	if day-int(s.last_filed)<RENEW_DAYS: return
	_file(f,after,day,false)

static func _follow_order(s:Dictionary,f:Dictionary,day:int)->void:
	## An order to build more lasts until the town is sound again.
	var order:Dictionary=s.order
	if order.is_empty() or float(f.condition)<SOUND_AT: return
	var id:=String(order.get("settlement_id",""))
	var management:=GovernmentPeopleSystem.settlement_management(id)
	if not management.is_empty() and String(management.get("focus",""))=="shelter" and not bool(management.get("auto_manage",true)):
		if bool(order.get("prior_auto",true)): GovernmentPeopleSystem.restore_delegation(id)
		else: GovernmentPeopleSystem.set_settlement_focus(id,String(order.get("prior_focus","balanced")))
	s.order={}

# --------------------------------------------------------------------------
# Who raises it, and in what words
# --------------------------------------------------------------------------

static func holder()->Dictionary:
	## The town's own leader runs its daily work; without one, the Hearth
	## Chief (Steward); else whoever leads the court.
	var officials:=Hall._officials()
	var primary:=primary_settlement_id()
	for person in officials:
		if String(person.get("office_key",""))=="settlement" and String(person.get("settlement_id",""))==primary: return person
	var leader:=GovernmentPeopleSystem.settlement_leader(primary) if primary!="" else {}
	if not leader.is_empty():
		for person in officials:
			if int(person.get("person_id",0))==int(leader.get("person_id",0)): return person
	for person in officials:
		if String(person.get("office_key",""))=="Steward": return person
	return officials[0] if not officials.is_empty() else {}

static func _count(n:int)->String:
	return NUMBER_WORDS[n] if n>=0 and n<NUMBER_WORDS.size() else str(n)

static func _cap(text:String)->String:
	return text.substr(0,1).to_upper()+text.substr(1) if text!="" else text

static func homes(f:Dictionary)->String:
	return "huts" if float(f.get("fabric_tier",0.0))<1.0 else "houses"

static func _material_words(item:String)->String:
	return String({"Timber":"timber","Fiber Plants":"reeds for thatch","Clay":"clay","Stone":"stone","Limestone":"lime"}.get(item,item.to_lower()))

static func _share_words(share:float)->String:
	## What a store holds against a sound one, in plain words.
	if share>=0.9: return "nearly all"
	if share>=0.7: return "about three parts in four of"
	if share>=0.55: return "not much more than half"
	if share>=0.4: return "about half"
	if share>=0.28: return "about a third of"
	if share>=0.18: return "about a quarter of"
	return "hardly a tenth of"

static func _months_words(months:float)->String:
	if months<2.0: return "within a month or two"
	if months<5.0: return "before the season is out"
	if months<9.0: return "in about half a year"
	if months<15.0: return "in about a year"
	return "within two years"

static func costs(f:Dictionary)->String:
	## The real effects of low condition, plainly.
	var share:=float(f.capacity_share)
	var held:=_share_words(share)
	var holds:="hold %s what sound ones would" % held if held!="nearly all" else "hold nearly what sound ones would"
	return "The store pits and shelters %s, so less keeps through the lean months; the workshops turn out fewer tools; carrying and storing go slower; and the families are poorer for it." % holds

static func need_words(f:Dictionary)->String:
	var have:=int(f.builders)
	var hold:=int(f.builders_to_hold)
	var mend:=int(f.builders_to_mend)
	var who:="No one" if have==0 else "%s of us" % _cap(_count(have))
	var verb:="keeps" if have<=1 else "keep"
	if hold<0:
		return "%s %s them up, but hands alone will not do it: we have %s for less than half the mending." % [who,verb,_material_words(String(f.short_material)) if String(f.short_material)!="" else "materials"]
	var line:=""
	if have<hold: line="%s %s them up; to hold them as they are we need about %s, and to get ahead of it about %s." % [who,verb,_count(hold),_count(maxi(hold,mend))]
	elif have<mend: line="%s %s them up, which only just holds them; to get ahead of it we need about %s." % [who,verb,_count(mend)]
	else: line="%s %s them up, and that is enough to mend them, slowly." % [who,verb]
	if String(f.short_material)!="": line+=" And we are short of %s: only enough for %s of the mending." % [_material_words(String(f.short_material)),_parts_words(float(f.materials_paid))]
	return line

static func _parts_words(paid:float)->String:
	var tenths:=clampi(roundi(paid*10.0),1,9)
	return "%s parts in ten" % _count(tenths)

static func spoken(f:Dictionary,stage:String,renewed:bool)->String:
	## The official's own words when summoned.
	var h:=homes(f)
	var opening:String
	var gaining:=float(f.monthly_change)>0.0
	match stage:
		"slipping":
			opening="The %s are wearing out faster than we mend them. Nothing has fallen in yet" % h
			var months:=float(f.months_until_failing)
			opening+=(", but at this rate the roofs will be leaking %s." % _months_words(months)) if months>=0.0 and not gaining else "."
		"failing":
			opening="Our %s are falling apart." % h
			var stressed:=int(f.stressed_buildings)
			if stressed>0: opening+=" Roofs leak and walls lean at %s of the %s buildings." % [_count(stressed),_count(int(f.standing_buildings))]
			if renewed: opening="The %s are still falling apart, and it is no better than when I last said so." % h
		_:
			opening="There is almost nothing left sound. The rain comes through every roof, and some walls are down to the posts."
	if gaining: opening+=" We are gaining on it now, but slowly."
	var ask:="Give me more hands for building, or tell me to let it be."
	if int(f.builders_to_hold)<0: ask="Put people to cutting and digging as well as building, or tell me to let it be."
	return "%s %s %s %s" % [opening,need_words(f),costs(f) if stage!="slipping" else "If it goes on, the stores will hold less and the workshops will do less.",ask]

static func _summary(f:Dictionary,stage:String)->String:
	var h:=homes(f)
	match stage:
		"slipping": return "The %s are wearing out faster than they are mended: %d at building, about %d needed to hold them." % [h,int(f.builders),maxi(0,int(f.builders_to_hold))]
		"failing": return "The %s are falling apart: %d at building, about %d needed to get ahead of it." % [h,int(f.builders),maxi(0,int(f.builders_to_mend))]
	return "The %s are nearly ruined: %d at building, about %d needed to mend them." % [h,int(f.builders),maxi(0,int(f.builders_to_mend))]

static func _headline(stage:String)->String:
	return String({"slipping":"comes about the wear on the town","failing":"comes about the town falling apart","floor":"comes about the town in ruins"}.get(stage,"comes about the town"))

# --------------------------------------------------------------------------
# Filing the matter, and the Chronicle
# --------------------------------------------------------------------------

static func _drop_matters()->void:
	for m in (Hall.state().matters as Array).duplicate():
		if m is Dictionary and String(m.get("situation_type",""))=="upkeep": (Hall.state().matters as Array).erase(m)

static func _file(f:Dictionary,stage:String,day:int,news:bool)->void:
	var person:=holder()
	if person.is_empty(): return
	var s:=state()
	s.last_filed=day
	# One matter at a time: a new stage replaces the old one.
	_drop_matters()
	var audience:=Hall._new_audience("court","petition",day)
	audience.speaker={"name":String(person.get("name","")).substr(0,100),"title":String(person.get("office_title","Official")).substr(0,100),"person_id":int(person.get("person_id",0)),"role":"official"}
	var summary:=_summary(f,stage)
	var said:=spoken(f,stage,not news)
	audience.petition={"topic":"upkeep","summary":summary.substr(0,400),"suggested_decree":""}
	var upkeep:=f.duplicate()
	upkeep["stage"]=stage
	# The facts come before the spoken words: the live voice's fact block is capped.
	audience.situation={"type":"upkeep","ask":"upkeep","headline":_headline(stage),"summary":summary.substr(0,400),"upkeep":upkeep,
		"occasion":{"type":"upkeep","text":"the %s are %s" % [homes(f),{"slipping":"wearing out faster than they are mended","failing":"falling apart","floor":"nearly ruined"}.get(stage,"wearing")],"day":day,"crisis":stage!="slipping"},
		"spoken":said.substr(0,900)}
	var entry:=Hall._file_matter(audience,[])
	entry["urgency"]=float({"slipping":0.35,"failing":0.7,"floor":0.85}.get(stage,0.5))
	if not news: return
	var given:=EraNames.given_of(String(person.get("name","")))
	var title:=String({"slipping":"The %s Wear Faster Than They Are Mended","failing":"The %s Are Falling Apart","floor":"The %s Are Nearly Ruined"}.get(stage,"The Town Wears")) % _cap(homes(f))
	Chronicle.record({"key":"upkeep:%s:%d" % [stage,day],"title":title,"text":"%s %s waits to be summoned." % [summary,given],
		"tier":"notice","kind":"settlement","domain":"infrastructure","action":{"kind":"court","focus":{"person_id":int(person.get("person_id",0))}}})

static func _recovered(f:Dictionary,day:int,had_order:bool)->void:
	var person:=holder()
	var given:=EraNames.given_of(String(person.get("name",""))) if not person.is_empty() else ""
	var lifted:=" The extra builders have gone back to their usual work." if had_order else ""
	var text:="The %s are sound again: %s." % [homes(f),"%s says the roofs hold and the stores are full size again" % given if given!="" else "the roofs hold and the stores are full size again"]
	Chronicle.record({"key":"upkeep:sound:%d" % day,"title":"The %s Are Sound Again" % _cap(homes(f)),"text":text+lifted,
		"tier":"notice","kind":"settlement","domain":"infrastructure","action":{"kind":"court","focus":{"person_id":int(person.get("person_id",0))}} if not person.is_empty() else {"kind":"court","focus":{}}})

# --------------------------------------------------------------------------
# At court (called from AudienceHall for the "upkeep" topic)
# --------------------------------------------------------------------------

static func on_open(audience:Dictionary)->void:
	var situation:Dictionary=audience.get("situation",{}) if audience.get("situation") is Dictionary else {}
	if String(situation.get("type",""))!="upkeep": return
	var speaker:Dictionary=audience.get("speaker",{})
	var person:=GovernmentPeopleSystem.person_snapshot(int(speaker.get("person_id",0)))
	if person.is_empty(): person={"person_id":int(speaker.get("person_id",0)),"name":String(speaker.get("name",""))}
	# Spoken from the town as it is now, not as it was when the matter was filed.
	var f:=facts()
	var stage:=String((situation.get("upkeep",{}) as Dictionary).get("stage","failing"))
	var said:=spoken(f,stage,false)
	situation["spoken"]=said.substr(0,900)
	var fresh:=f.duplicate(); fresh["stage"]=stage
	situation["upkeep"]=fresh
	Hall.append_line(String(audience.id),{"speaker":"","role":"narrator","person_id":0,"civ_id":"","text":"[%s comes in with mud to the elbows.]" % EraNames.given_of(String(person.get("name",""))),"day":_day(),"aside":false})
	Hall.append_line(String(audience.id),{"speaker":String(person.get("name","")),"role":"official","person_id":int(person.get("person_id",0)),"civ_id":"player","text":said,"day":_day(),"aside":false})

static func options(audience:Dictionary)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	var f:=facts()
	var id:=primary_settlement_id()
	var management:=GovernmentPeopleSystem.settlement_management(id) if id!="" else {}
	var already:=String(management.get("focus",""))=="shelter"
	var occupied:=id!="" and not String(WorldSimulation.settlements.settlement_record(id).get("occupied_by","")).is_empty()
	var title:=String(GovernmentPeopleSystem.settlement_leader_title()).to_lower()
	var reason:="Most of the hands the %s can spare are already building." % title if already else ("The town is held by others." if occupied else "There is no town to order.")
	out.append(Hall._option("more_builders","Put more hands to building","Move people to building, and to cutting timber and digging clay, until the %s are sound. Fewer hands for crafts, learning and the watch." % homes(f),"warm",id!="" and not already and not occupied,reason))
	out.append(Hall._option("accept","Let it be for now","The %s keep wearing. This will not be raised again unless it gets worse." % homes(f),"neutral"))
	return out

static func resolve(audience:Dictionary,option_id:String)->Dictionary:
	var speaker:Dictionary=audience.get("speaker",{})
	var pid:=int(speaker.get("person_id",0))
	var name:=String(speaker.get("name",""))
	var f:=facts()
	var s:=state()
	var stage:=String((Hall._situation(audience).get("upkeep",{}) as Dictionary).get("stage",s.stage))
	match option_id:
		"more_builders":
			var id:=primary_settlement_id()
			var before:=GovernmentPeopleSystem.settlement_management(id)
			var before_share:=float((before.get("allocations",{}) as Dictionary).get("Construction",0.0))
			var result:=GovernmentPeopleSystem.set_settlement_focus(id,"shelter")
			if not bool(result.get("ok",false)): return {"error":String(result.get("reason","That cannot be ordered now."))}
			s.order={"day":_day(),"settlement_id":id,"prior_auto":bool(before.get("auto_manage",true)),"prior_focus":String(before.get("focus","balanced"))}
			s.accepted=""
			var after_share:=float((GovernmentPeopleSystem.settlement_management(id).get("allocations",{}) as Dictionary).get("Construction",0.0))
			if pid>0:
				GovernmentPeopleSystem.adjust_person_bonds(pid,{"trust":0.03})
				GovernmentPeopleSystem.record_person_memory(pid,"I told the god the %s were falling apart, and the god gave me more hands to mend them." % homes(f),"civic",0.5,{"emotion":"relief"})
			Hall.append_line(String(audience.id),{"speaker":name,"role":"official","person_id":pid,"civ_id":"player","text":"Then I will take them from the crafts and the watch from tomorrow, and put them to the roofs, the timber and the clay pits.","day":_day(),"aside":false})
			return {"outcome":"You told %s to put more hands to building. About %d in every hundred will now build, up from %d, until the %s are sound." % [name,roundi(after_share),roundi(before_share),homes(f)],"reaction":"pleased"}
		"accept":
			s.accepted=stage
			if pid>0: GovernmentPeopleSystem.record_person_memory(pid,"I told the god the %s were wearing out, and the god said to let it be." % homes(f),"civic",0.4,{"emotion":"worry"})
			Hall.append_line(String(audience.id),{"speaker":name,"role":"official","person_id":pid,"civ_id":"player","text":"As you say. We will patch what leaks worst and live with the rest.","day":_day(),"aside":false})
			return {"outcome":"You told %s to let the %s wear. It will not be raised again unless it gets worse." % [name,homes(f)],"reaction":"neutral"}
	return {"error":"That answer is not open to you here."}

static func typed_choice(audience_id:String,text:String)->String:
	## Online, the god may simply say it: "Put more people on the roofs."
	## Returns the option id their words name, or "".
	var audience:=Hall.find(audience_id)
	if String(Hall._situation(audience).get("type",""))!="upkeep" or String(audience.get("status",""))!="waiting": return ""
	var lower:=" "+text.to_lower()+" "
	var open:Array=options(audience).filter(func(o:Dictionary)->bool:return bool(o.get("enabled",true))).map(func(o:Dictionary)->String:return String(o.id))
	var found:=""
	for id in WORDS:
		if not String(id) in open: continue
		for word in WORDS[id]:
			if lower.contains(String(word)):
				if found!="" and found!=String(id): return ""
				found=String(id)
	return found

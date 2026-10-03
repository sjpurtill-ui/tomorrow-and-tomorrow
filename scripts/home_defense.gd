extends RefCounted
## THE TOWN'S DEFENCES: who decides when the next stage goes up, and exactly
## what stops it, in the engine's own numbers.
##
## One word on the defence ledger (MilitaryCampaign.settlement_defense.word,
## saved with it; an older save reads "people"):
##   people  Our people and their officials raise the next stage by the rule
##           every computer ruler uses (civilization_controller
##           defense_decision): the danger they read, weighed by their temper,
##           against the stage's need; food for 30 days; twice its materials in
##           store so it can be spared; Defense hands to raise it within three
##           years. They look at their monthly council, as every ruler does.
##   build   The god's "build now": the next stage starts the day its
##           materials are in the town's store and someone keeps the watch,
##           whatever the danger. It stays the word until the god changes it.
##   hold    No new stage starts. One already going up is finished.
## Whoever decides, a stage starts through the one order
## (civilization_orders "settlement_defense" -> start_settlement_defense_upgrade,
## which takes the materials from the store) and rises by the one daily work
## (settlement_defense_daily_work), so the stores and the watch pay for it.
## While a stage is wanted but its materials are short, the town asks our
## other towns for them through the ordinary deliveries (material_targets,
## read by settlement_model.process_city_trade). The Chronicle says when a
## stage starts and when it stands. Static helpers; preload.

const WORDS:=["people","build","hold"]
## The choice as the screen and the court say it.
const WORD_LABELS:={"people":"Let the people decide","build":"Build now","hold":"Hold off"}
const WORD_TIPS:={
	"people":"Our people raise the next works when the danger they see is great enough, food and materials allow, and the watch can finish them.",
	"build":"Each next stage starts as soon as its materials are in store and someone keeps the watch, whatever the danger.",
	"hold":"No new works start. Any already going up are finished."}
## "stand" or "stands" for each stage's short name.
const STANDS:=["stands","stand","stands","stands","stand","stands"]
## Plain names for the parts of the danger the people read (DEFENSE_DANGER).
const DANGER_WORDS:={"war":"at war or under attack","attacked":"attacked at home in the last two years","fear":"the people fear war",
	"hostile":"a neighbour is hostile","tempting":"rich stores and few guards","neighbours":"other peoples are known",
	"builders":"skilled builders want walls"}

static func _controller()->GDScript:
	return load("res://scripts/civilization_controller.gd")

static func _mc()->Variant:
	return WorldSimulation.military


# --------------------------------------------------------------------------
# The word
# --------------------------------------------------------------------------

## Who decides when the next stage goes up: "people", "build" or "hold".
static func word()->String:
	var mc=_mc()
	if mc==null:return "people"
	mc._ensure_settlement_defense()
	return String(mc.settlement_defense.get("word","people"))

## Sets the god's word. "build" starts the next stage at once when it can.
## {ok, changed, word, started} or {error}.
static func set_word(chosen:String)->Dictionary:
	if chosen not in WORDS:return {"error":"No such word for the defences."}
	var mc=_mc()
	if mc==null:return {"error":"There is nobody to raise defences."}
	mc._ensure_settlement_defense()
	var changed:=String(mc.settlement_defense.get("word","people"))!=chosen
	mc.settlement_defense["word"]=chosen
	var started:=act(WorldSimulation.actor_id)
	if changed and started.is_empty():mc.settlement_defense_changed.emit(mc.settlement_defense_snapshot())
	return {"ok":true,"changed":changed,"word":chosen,"started":bool(started.get("ok",false))}


# --------------------------------------------------------------------------
# The council, for every people alike
# --------------------------------------------------------------------------

## The people's plan as their council reads it: their own temper (the values
## they live by, for the god's people) and their situation.
static func plan(id:String="")->Dictionary:
	return _controller().current_plan(id if id!="" else String(WorldSimulation.actor_id))

## The monthly council's word on defences, for the god's people and every
## computer ruler alike: the shared rule decides, the god's word (if any)
## overrides it. Keeps what the council found (the materials it wants
## brought, material_targets) and returns the rule's decision.
static func council(id:String,people_plan:Dictionary)->Dictionary:
	var decision:Dictionary=_controller().defense_decision(people_plan)
	var mc=_mc()
	mc.settlement_defense["council"]={"day":int(WorldSimulation.state.elapsed_days),"stage":int(decision.stage),"wants":bool(decision.get("wants",false))}
	match word():
		"hold":pass
		"build":act(id)
		_:
			if bool(decision.build):WorldSimulation.submit(id,{"kind":"settlement_defense","stage":int(decision.stage),"reason":String(decision.reason),"by":"people"})
	return decision

## The god's "build now", checked every day: the next stage starts the day
## its materials and a watch are there. {} when nothing started.
static func act(id:String)->Dictionary:
	if word()!="build":return {}
	var available:Dictionary=_mc().settlement_defense_upgrade_availability()
	if not bool(available.get("available",false)):return {}
	var started:Dictionary=WorldSimulation.submit(id,{"kind":"settlement_defense","stage":int(available.stage_index),"reason":"The god's word: build now","by":"ruler"})
	return started if bool(started.get("ok",false)) else {}

## What the town that raises the works wants in its store for the next
## stage, {material: amount}: twice the stage's bill (DEFENSE_SPARE, the
## shared rule's "enough to spare it"), at the god's "build now" or when the
## people's own council wants the works; nothing while a stage is going up,
## on "hold", or when the people see no need. Deliveries from our other
## towns fill it (process_city_trade). Twice, not once: the town's other
## building draws on the same store every day, and "build now" starts the
## works as soon as the bill itself is there.
static func material_targets()->Dictionary:
	var mc=_mc()
	if mc==null:return {}
	mc._ensure_settlement_defense()
	var ledger:Dictionary=mc.settlement_defense
	if int(ledger.project_stage)>=0:return {}
	var next:=int(ledger.stage)+1
	if next>=mc.SETTLEMENT_DEFENSE_STAGES.size():return {}
	var factor:=0.0
	match word():
		"build":factor=float(_controller().DEFENSE_SPARE)
		"people":
			var found:Dictionary=ledger.get("council",{}) if ledger.get("council") is Dictionary else {}
			if bool(found.get("wants",false)) and int(found.get("stage",-1))==next:factor=float(_controller().DEFENSE_SPARE)
	if factor<=0.0:return {}
	var out:={}
	var bill:Dictionary=mc.SETTLEMENT_DEFENSE_STAGES[next].materials
	for material:String in bill:out[material]=float(bill[material])*factor
	return out


# --------------------------------------------------------------------------
# The Chronicle
# --------------------------------------------------------------------------

## A stage begins: what was set aside, who raises it and how long it takes,
## and who decided. Only the god's own people keep a chronicle.
static func tell_started(stage_index:int,by:String)->Dictionary:
	var chronicle=preload("res://scripts/chronicle.gd")
	if not chronicle.active():return {}
	var mc=_mc()
	var stage:Dictionary=mc.SETTLEMENT_DEFENSE_STAGES[stage_index]
	var name:=String(stage.short).to_lower()
	var parts:PackedStringArray=[]
	for material:String in stage.materials:parts.append("%d %s" % [roundi(float(stage.materials[material])),_material(material)])
	var daily:float=mc.settlement_defense_daily_work(stage_index)
	# Those of the watch at home raise them, not its bands away.
	var hands:=int(mc.watch_at_home())
	var pace:=("%d on the watch raise them in %s." % [hands,preload("res://scripts/hud/production_plain.gd").duration_text(float(stage.work)/daily)]) if daily>0.0 else "Nobody keeps the watch yet, so no one works on them."
	var who:String={"people":"The people judged the danger worth it.","ruler":"At your word.","court":"At your word in the court."}.get(by,"")
	return chronicle.record({"key":"defense_start:%d:%d" % [stage_index,int(WorldSimulation.state.elapsed_days)],"title":"Work begins on the %s" % name,
		"text":("%s set aside. %s %s" % [_and(parts),pace,who]).strip_edges(),"kind":"work","tier":"notice","domain":"security",
		"action":{"kind":"section","section":"construction","sub":0}})

## A stage stands: what it now does, in the engine's numbers. True when the
## god's own people were told (their Chronicle keeps the ledger line).
static func tell_finished(stage_index:int,by:String)->bool:
	var chronicle=preload("res://scripts/chronicle.gd")
	if not chronicle.active():return false
	var stage:Dictionary=_mc().SETTLEMENT_DEFENSE_STAGES[stage_index]
	var who:String={"people":" The people raised them of their own accord.","ruler":" Raised at your word.","court":" Raised at your word in the court."}.get(by,"")
	chronicle.record({"key":"defense_done:%d:%d" % [stage_index,int(WorldSimulation.state.elapsed_days)],"title":"The %s %s" % [String(stage.short).to_lower(),STANDS[stage_index]],
		"text":"Defenders now fight %d%% better at home, raiders are seen %d km off, and %d%% of the stores are safe from raids.%s" % [roundi(float(stage.defense_bonus)*100.0),roundi(float(stage.observation_km)),roundi(float(stage.store_protection)*100.0),who],
		"kind":"milestone","tier":"moment","domain":"security","action":{"kind":"section","section":"construction","sub":0}})
	return true


# --------------------------------------------------------------------------
# The reading for the screens
# --------------------------------------------------------------------------

## Everything the town screen shows of the defences, from the ledger and the
## shared rule, never worked out again:
## {word, stage, short, now:{defense_bonus, lookout_km, stores_safe,
##  integrity}, next:{} | {index, short, work, materials, after:{...}},
##  building:{} | {index, short, progress, days_left, daily, started_by},
##  workers, decision (the shared rule's), danger:{danger, weighed, need,
##  temper, parts:[{key, words, value}]}, status, blockers:[{kind, text,
##  have, need, resource}], incoming:{material: amount}, next_council}.
## status: "unsettled", "complete", "building", "stalled", "ready" (it
## starts at the next check), "waiting" (the word or rule wants it, the
## means lack), "calm" (the people see no need), "hungry" (no works while
## food is short), "held".
static func reading(people_plan:Dictionary={})->Dictionary:
	var mc=_mc()
	var state=WorldSimulation.state
	var snap:Dictionary=mc.settlement_defense_snapshot()
	var stages:Array=mc.SETTLEMENT_DEFENSE_STAGES
	var stage:=int(snap.stage)
	var out:={"word":word(),"stage":stage,"short":String(snap.short),"workers":int(_mc().watch_at_home()),
		"now":{"defense_bonus":float(snap.defense_bonus),"lookout_km":float(snap.observation_radius_km),"stores_safe":float(snap.store_protection),"integrity":float(snap.integrity)},
		"next":{},"building":{},"decision":{},"danger":{},"blockers":[],"incoming":{},"status":"calm","next_council":next_council(int(state.elapsed_days))}
	if not bool(state.settlement_site_committed):
		out.status="unsettled"
		out.blockers.append({"kind":"unsettled","text":"No town yet"})
		return out
	var building:Dictionary=snap.get("construction",{})
	var next_index:=int(building.stage) if not building.is_empty() else stage+1
	if next_index<stages.size():
		var works:Dictionary=stages[next_index]
		out.next={"index":next_index,"short":String(works.short),"work":float(works.work),"materials":(works.materials as Dictionary).duplicate(),
			"after":{"defense_bonus":float(works.defense_bonus),"lookout_km":float(works.observation_km),"stores_safe":float(works.store_protection)}}
		for material:String in works.materials:
			var coming:=_incoming(material)
			if coming>0.0:out.incoming[material]=coming
	if not building.is_empty():
		out.status="building"
		out.building={"index":int(building.stage),"short":String(building.get("short","")),"progress":float(building.progress),"days_left":float(building.get("days_left",-1.0)),"daily":float(building.get("daily_work",0.0)),"started_by":String(building.get("started_by",""))}
		if float(building.get("daily_work",0.0))<=0.0:
			out.status="stalled"
			out.blockers.append({"kind":"watch","text":"Nobody on the watch","have":0,"need":1})
		return out
	if next_index>=stages.size():
		out.status="complete"
		return out
	var used_plan:=people_plan if not people_plan.is_empty() else plan()
	var decision:Dictionary=_controller().defense_decision(used_plan)
	out.decision=decision
	var parts:Array=[]
	for key:String in (decision.get("parts",{}) as Dictionary):parts.append({"key":key,"words":String(DANGER_WORDS.get(key,key)),"value":float(decision.parts[key])})
	parts.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.value)>float(b.value))
	out.danger={"danger":float(decision.danger),"weighed":float(decision.weighed),"need":float(decision.need),"temper":0.6+0.8*float(decision.wariness),"parts":parts}
	var available:Dictionary=mc.settlement_defense_upgrade_availability()
	var w:=String(out.word)
	if w=="hold":
		out.status="held"
		out.blockers.append({"kind":"held","text":"You said hold off"})
		return out
	# The god's word asks only what physically starts the works (availability);
	# the people's own rule asks its own (defense_decision), each in numbers.
	var spare:=w=="people"
	if spare and float(decision.weighed)<float(decision.need):
		out.blockers.append({"kind":"danger","text":"Danger %d of %d needed" % [danger_points(float(decision.weighed)),roundi(float(decision.need)*100.0)],"have":float(decision.weighed),"need":float(decision.need)})
	if spare and (float(decision.food_days)<float(_controller().DEFENSE_FOOD_DAYS) or bool(used_plan.get("hungry",false))):
		out.blockers.append({"kind":"food","text":"Food %d of %d days" % [roundi(float(decision.food_days)),roundi(_controller().DEFENSE_FOOD_DAYS)],"have":float(decision.food_days),"need":float(_controller().DEFENSE_FOOD_DAYS)})
	for material:String in (out.next.materials as Dictionary):
		var have:=float(state.resource_stockpiles.get(material,0.0))
		var need:=float(out.next.materials[material])*(float(_controller().DEFENSE_SPARE) if spare else 1.0)
		if have+0.0001<need:out.blockers.append({"kind":"material","resource":material,"text":"%s %s of %s" % [_material_name(material),_count(have),_count(need)],"have":have,"need":need})
	if int(out.workers)<=0:
		out.blockers.append({"kind":"watch","text":"Nobody on the watch","have":0,"need":1})
	elif spare and float(decision.days)>float(_controller().DEFENSE_MAX_DAYS):
		out.blockers.append({"kind":"slow","text":"%d on the watch: %s" % [int(out.workers),preload("res://scripts/hud/production_plain.gd").span_text(float(decision.days))],"have":float(_controller().DEFENSE_MAX_DAYS),"need":float(decision.days)})
	if (out.blockers as Array).is_empty():
		# Nothing the rule names stands in the way: it starts at the next check
		# (the god's word: tomorrow; the people: their council).
		out.status="ready" if bool(available.get("available",false)) else "waiting"
		if not bool(available.get("available",false)):out.blockers.append({"kind":"other","text":String(available.get("reason","Not possible now"))})
		return out
	# The people's own reasons come first: while the danger is too low they
	# see no need, and while food is short they raise nothing, whatever else
	# is missing. Otherwise the works are wanted and only the means lack.
	var kinds:=(out.blockers as Array).map(func(b:Dictionary)->String:return String(b.kind))
	out.status="calm" if "danger" in kinds else ("hungry" if "food" in kinds else "waiting")
	return out

## Danger as the screen counts it, out of 100: whole points, never rounded
## up to meet a need it falls short of.
static func danger_points(weighed:float)->int:
	return floori(weighed*100.0+0.0001)

## How many more the watch needs for stage `stage_index`: enough to raise it
## at its fastest pace (settlement_defense_full_pace_workers), no more than
## the watch the planners' own base plan keeps (GovernmentPeopleSystem
## BASE_ALLOCATIONS), and never fewer than the shared rule's three years ask
## (DEFENSE_MAX_DAYS). 0 when the watch is already enough.
static func watch_fix(stage_index:int)->int:
	var mc=_mc()
	if stage_index<0 or stage_index>=mc.SETTLEMENT_DEFENSE_STAGES.size():return 0
	var state=WorldSimulation.state
	var now:=int(mc.watch_at_home())
	var full:int=mc.settlement_defense_full_pace_workers(stage_index)
	var per_hand:float=mc.settlement_defense_daily_work(stage_index,1.0)
	var work:=float(mc.SETTLEMENT_DEFENSE_STAGES[stage_index].work)
	var rule_least:=ceili(work/(float(_controller().DEFENSE_MAX_DAYS)*per_hand)-0.0001) if per_hand>0.0 else 1
	var base:=ceili(float(state.able_population())*float(WorldSimulation.government.BASE_ALLOCATIONS.get("Defense",4.0))/100.0)
	return maxi(0,maxi(maxi(1,rule_least),mini(full,base))-now)

## What the war leader knows of the town's defences (court_facts.gd), from
## the same reading as the screen: {stands, rising, progress, days_left,
## next, word, status, blockers:[text]}.
static func court_facts()->Dictionary:
	var r:=reading()
	var building:Dictionary=r.building
	return {"stands":String(r.short),"rising":String(building.get("short","")),"progress":roundi(float(building.get("progress",0.0))*100.0),
		"days_left":roundi(float(building.get("days_left",-1.0))),"next":String((r.next as Dictionary).get("short","")),"word":String(r.word),"status":String(r.status),
		"blockers":(r.blockers as Array).filter(func(b:Dictionary)->bool:return String(b.kind)!="unsettled").map(func(b:Dictionary)->String:return String(b.text))}

## The war leader's line on the defences: what stands, what goes up or why
## nothing does, and the god's word.
static func court_words(f:Dictionary)->String:
	var parts:PackedStringArray=["%s now" % String(f.get("stands","Open ground"))]
	var next:=String(f.get("next","")).to_lower()
	if String(f.get("rising",""))!="":
		parts.append("the %s going up, %d%% done, %s" % [String(f.rising).to_lower(),int(f.progress),("about %d days left" % int(f.days_left)) if int(f.days_left)>=0 else "stopped"])
	elif next!="":
		var why:String={"calm":"the people see no need for the %s yet","waiting":"the %s are wanted, but the means are short","ready":"the %s start at the next check",
			"held":"no new works: the god said hold off","hungry":"no new works while food is short","stalled":"the %s have stopped"}.get(String(f.get("status","")),"")
		if why!="":parts.append(why % next if "%s" in why else why)
	var blockers:Array=f.get("blockers",[])
	if not blockers.is_empty():parts.append("what stops them: "+", ".join(PackedStringArray(blockers)))
	parts.append("the god's word: "+String(WORD_LABELS.get(String(f.get("word","people")),"let the people decide")).to_lower())
	return "; ".join(parts)

## The next monthly council of the god's people, after `today`.
static func next_council(today:int)->int:
	var controller:=_controller()
	for day in range(today+1,today+32):
		if controller.review_due("player",day):return day
	return today+30

## Material on the road to the town that raises the works.
static func _incoming(material:String)->float:
	var state=WorldSimulation.state
	var home:=""
	for city:Dictionary in state.player_settlements:
		if bool(city.get("primary",false)):home=String(city.get("id",""))
	var total:=0.0
	for shipment:Dictionary in state.city_trade_shipments:
		if String(shipment.get("resource",""))==material and (home=="" or String(shipment.get("destination_id",""))==home):total+=float(shipment.get("quantity",0.0))
	return total

static func _material(material:String)->String:
	return preload("res://scripts/resource_names.gd").label(material).to_lower()

static func _material_name(material:String)->String:
	return preload("res://scripts/resource_names.gd").label(material)

## Whole units, never rounded up to make a need look met (2.6 timber is 2).
static func _count(value:float)->String:
	return str(floori(maxf(0.0,value)+0.0001))

static func _and(items:PackedStringArray)->String:
	if items.size()<=1:return "" if items.is_empty() else items[0]
	return ", ".join(items.slice(0,items.size()-1))+" and "+items[items.size()-1]

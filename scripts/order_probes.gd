extends RefCounted
## THE ORDER TRACKER'S PROBES: how each kind of order stands, read from the
## engine's own ledger (order_tracker.gd). Nothing here is kept apart from the
## state; a card never says more than the ledger shows.
##
## read(order) -> {state, line, value, total, progress, reason, moved,
##   standing}:
##   state     "accepted", "under_way", "done", "stalled", or "refused_now"
##   line      the card's status words, short and plain
##   value/total  the bar (0/0: no bar)
##   progress  a number that only grows while the order moves (the tracker
##             compares it day to day for the fail-safe)
##   reason    why it does not move, in the engine's numbers ("" when it does)
##   moved     the ledger already shows work done for it
##   standing  a standing order (a line kept, a zone held, a law in force):
##             still, but not stalled
## Probes read the god's own systems (the autoloads), never another people's.
## Static helpers; preload.

const P:=preload("res://scripts/persistent_production.gd")
const ITEM_NAMES:={"improvised":"clubs","spear":"spears","bow":"bows","sword_shield":"swords","lance":"lances","cart":"carts"}

static func _today()->int:
	return int(GameState.elapsed_days)

static func read(o:Dictionary)->Dictionary:
	var refs:Dictionary=o.get("refs",{}) if o.get("refs") is Dictionary else {}
	match String(o.get("kind","")):
		"levy": return _levy(refs)
		"workshop": return _workshop(refs)
		"line": return _line(refs)
		"march": return _march(refs)
		"band": return {"state":"done","line":"The band is formed","progress":1.0,"moved":true}
		"recruit_line": return _recruit_line(refs)
		"research": return _research(refs)
		"build": return _build(refs)
		"defences": return _defences(refs)
		"directive": return _directive(refs)
		"civic": return _civic(refs)
		"waiting": return {"state":"accepted","line":"Waits on your word: "+String(refs.get("reason","")),"reason":String(refs.get("reason","")) if String(refs.get("reason",""))!="" else "it waits for your word","progress":0.0}
		"setting": return {"state":"done","line":String(refs.get("line","Done")),"progress":1.0,"moved":true}
	return {"state":"accepted","line":"Taken up","progress":0.0}

static func _arms(item:String)->String:
	return String(ITEM_NAMES.get(item,item.replace("_"," ")))

# --- A levy: called up, in drill, armed ---------------------------------------

static func _levy(refs:Dictionary)->Dictionary:
	var mc:=MilitaryCampaign
	if bool(refs.get("camp",false)):return _camp_drill()
	var tid:=int(refs.get("training_id",-1))
	var raised:=int(refs.get("raised",0))
	var asked:=int(refs.get("asked",0))
	if tid<0:
		# Called up, but their drill could not begin.
		if raised>0:return {"state":"stalled","line":"%d called up · no drill: %s" % [raised,String(refs.get("reason",""))],"reason":String(refs.get("reason","")),"value":raised,"total":maxi(raised,asked),"progress":0.0,"moved":true}
		return {"state":"refused_now","line":String(refs.get("reason","Nobody could be called up")),"progress":0.0}
	var order:={}
	for entry in mc.training_queue:
		if int((entry as Dictionary).get("id",-1))==tid:order=entry;break
	if order.is_empty():
		# Their drill is over: finished (they stand under arms at home), or
		# stopped before it was (stood down, or fell).
		var last:=float(refs.get("last_days",0.0))
		var required:=maxf(1.0,float(refs.get("required_days",1.0)))
		var pace:=float(refs.get("pace",0.0))
		var since:=maxi(0,_today()-int(refs.get("last_day",_today())))
		var count:=int(refs.get("count",raised))
		if last+pace*float(since)>=required*0.95:
			return {"state":"done","line":"%d drilled and under arms at home" % count,"value":count,"total":count,"progress":2.0,"moved":true}
		return {"state":"stalled","line":"Their drill stopped before they were ready","reason":"their drill stopped before they were ready (stood down or hurt)","progress":last,"moved":true}
	var count:=int(order.get("count",0))
	var days:=float(order.get("progress_days",0.0))
	var required:=float(order.get("required_days",1.0))
	# The tracker's own memory of the drill, to tell a finished drill from a
	# stopped one once it leaves the queue.
	var last_days:=float(refs.get("last_days",0.0))
	var last_day:=int(refs.get("last_day",_today()))
	if _today()>last_day and days>last_days:refs["pace"]=(days-last_days)/float(_today()-last_day)
	refs["last_days"]=days;refs["last_day"]=_today();refs["required_days"]=required;refs["count"]=count
	var weapon:=String(order.get("weapon","improvised"))
	var need:int=mc._equipment_required_for(String(order.get("unit","levy")),count)
	var have:=mini(need,int(order.get("reserved_equipment",0))+int((mc.military_inventory as Dictionary).get(weapon,0)))
	var line:="%d in drill · %d of %d days" % [count,floori(days),ceili(required)]
	if have<need:line+=" · %s %d of %d" % [_arms(weapon),have,need]
	# Fewer could be called up than were asked for: said first, compactly.
	if asked>0 and raised>0 and raised<asked:line="%d of %d called up · drill %d/%d days%s" % [raised,asked,floori(days),ceili(required)," · %s %d/%d" % [_arms(weapon),have,need] if have<need else ""]
	var reason:=_drill_halt(mc)
	if reason=="" and days<=0.0:reason="their drill has not begun"
	var state:="under_way" if days>0.0 else "accepted"
	if reason!="" and days>0.0 and _drill_halt(mc)!="":state="stalled"
	return {"state":state,"line":line if state!="stalled" else "Drill halted: "+reason,"value":floori(days),"total":ceili(required),"progress":days+float(have)*0.001,"reason":reason,"moved":days>0.0}

## Why no drill moves at all ("" when it does): the army's training
## suspended, or no food to spare for drill (military_campaign
## _process_training_day).
static func _drill_halt(mc:Node)->String:
	var policy:Dictionary=mc.training_staff.policy("army")
	if float(policy.get("intake",1.0))<=0.0:return "the army's training is suspended"
	if float(mc.training_staff.instruction_food())<=0.0:return "no food to spare for drill"
	return ""

static func _camp_drill()->Dictionary:
	var program:Dictionary=MilitaryCampaign.training_program
	if program.is_empty():return {"state":"done","line":"Camp drill finished","progress":1.0,"moved":true}
	var days:=float(program.get("progress_days",0.0))
	var total:=float(program.get("duration_days",1.0))
	var still:=String(program.get("paused_reason",""))
	if still!="":return {"state":"stalled","line":"Camp drill stands still: "+still,"reason":still,"value":floori(days),"total":ceili(total),"progress":days}
	return {"state":"under_way" if days>0.0 else "accepted","line":"Camp drill · %d of %d days" % [floori(days),ceili(total)],"value":floori(days),"total":ceili(total),"progress":days,"moved":days>0.0}

# --- Workshops ---------------------------------------------------------------

static func _job(id:int)->Dictionary:
	for job in MilitaryCampaign.equipment_queue:
		if int((job as Dictionary).get("id",-1))==id:return job
	return {}

## A batch in the workshops: made against asked.
static func _workshop(refs:Dictionary)->Dictionary:
	var item:=String(refs.get("item",""))
	var count:=maxi(1,int(refs.get("count",1)))
	var job:=_job(int(refs.get("job_id",-1)))
	if job.is_empty():
		for candidate in MilitaryCampaign.equipment_queue:
			var j:Dictionary=candidate
			if String(j.get("item",""))==item and not bool(j.get("persistent",false)):job=j;break
	if job.is_empty():
		return {"state":"done","line":"%d %s made" % [count,_arms(item)],"value":count,"total":count,"progress":float(count),"moved":true}
	var made:=int(job.get("completed",0))
	var work:=float(job.get("progress_days",0.0))
	var reason:=""
	if bool(job.get("paused",false)):reason="the work is paused"
	elif float(WorldSimulation.state.effective_workers("Crafting"))<=0.0:reason="nobody works in the workshops"
	return {"state":"under_way" if made>0 or work>0.0 else "accepted","line":"%d of %d %s made" % [made,int(job.get("count",count)),_arms(item)],"value":made,"total":int(job.get("count",count)),"progress":float(made)+work,"reason":reason,"moved":made>0 or work>0.0}

## A workshop line that keeps a stock: in store against its target.
static func _line(refs:Dictionary)->Dictionary:
	var item:=String(refs.get("item",""))
	var job:=_job(int(refs.get("job_id",-1)))
	if job.is_empty():
		for candidate in MilitaryCampaign.equipment_queue:
			var j:Dictionary=candidate
			if String(j.get("item",""))==item and bool(j.get("persistent",false)):job=j;break
	if job.is_empty():return {"state":"stalled","line":"The line for %s is gone" % _arms(item),"reason":"the line was stopped","progress":0.0}
	var stock:=int(P.stock(MilitaryCampaign,job))
	var target:=int(job.get("target_stock",refs.get("target",0)))
	var made:=int(job.get("completed",0))
	var work:=float(job.get("progress_days",0.0))
	var state:=String(P.state(MilitaryCampaign,job))
	if target>0 and stock>=target:return {"state":"done","line":"%d %s in store, as asked" % [stock,_arms(item)],"value":stock,"total":target,"progress":float(made)+work,"moved":true}
	var reason:=""
	if state=="Paused":reason="the line is paused"
	elif state.begins_with("Missing "):reason="no "+state.trim_prefix("Missing ").to_lower()+" in store"
	elif state!="Working" and state!="Batch":reason=state.to_lower()
	var line:=("%d of %d %s in store" % [stock,target,_arms(item)]) if target>0 else ("%s: %d made" % [_arms(item).capitalize(),made])
	return {"state":"under_way","line":line,"value":stock,"total":target,"progress":float(made)+work,"reason":reason,"moved":made>int(refs.get("start_made",0)) or work>0.0,"standing":target<=0}

# --- A band on the road, a ground held ----------------------------------------

static func _march(refs:Dictionary)->Dictionary:
	var army:={}
	for a in MilitaryCampaign.field_armies:
		if int((a as Dictionary).get("army_id",-1))==int(refs.get("army_id",-1)):army=a;break
	if army.is_empty():return {"state":"stalled","line":"The band is no more","reason":"the band was disbanded or lost","progress":0.0}
	var name:=String(army.get("name","The band"))
	var kind:=String(refs.get("kind",""))
	if String(army.get("status",""))=="moving":
		var total:=float(army.get("distance_total_km",0.0))
		var left:=float(army.get("distance_remaining_km",0.0))
		var days:=maxi(0,int(army.get("arrival_day",_today()))-_today())
		var where:=String(army.get("destination_name","")).to_lower().capitalize()
		return {"state":"under_way","line":"On the road to %s · %d %s left" % [where,days,"day" if days==1 else "days"] if where!="" else "On the road · %d days left" % days,
			"value":roundi(total-left),"total":roundi(total),"progress":total-left,"moved":total-left>0.0}
	var at:=String(army.get("location_name",army.get("location_id","")))
	if kind in ["guard","front","defend"]:
		return {"state":"under_way","line":"%s holds %s" % [name,at.to_lower().capitalize()] if at!="" else "%s holds its ground" % name,"progress":1.0,"moved":true,"standing":true}
	return {"state":"done","line":"%s is at %s" % [name,at.to_lower().capitalize()] if at!="" else "%s has arrived" % name,"progress":1.0,"moved":true}

# --- A recruitment line (the Army screen's Train) ------------------------------

static func _recruit_line(refs:Dictionary)->Dictionary:
	var rd:RefCounted=MilitaryCampaign.recruit_deploy
	var item:Dictionary=rd.line(int(refs.get("line_id",-1)))
	if item.is_empty():
		return {"state":"done" if int(refs.get("deployed",0))>0 else "stalled","line":"Their band was sent out" if int(refs.get("deployed",0))>0 else "The line was stopped","reason":"the recruitment line was stopped","progress":1.0,"moved":true}
	refs["deployed"]=int(item.get("deployed",0))
	var people:=0;var target:=0;var drill:=1.0
	for slot in item.get("slots",[]):
		var s:Dictionary=rd.status(int(item.id),int(slot))
		people+=int(s.people);target+=int(s.target);drill=minf(drill,float(s.training))
	if (item.get("slots",[]) as Array).is_empty():
		if int(item.get("deployed",0))>0 and int(item.get("remaining",0))<=0 and not bool(item.get("repeat",false)):return {"state":"done","line":"%d %s sent out" % [int(item.deployed),"band" if int(item.deployed)==1 else "bands"],"progress":2.0,"moved":true}
		for entry:Dictionary in item.get("entries",[]):target+=int(entry.get("count",0))
		drill=0.0
	var reason:=""
	if MilitaryCampaign.recovery.home_unavailable():reason="home is not ours to drill in"
	elif bool(item.get("paused",false)):reason="the line is paused"
	elif people<target and MilitaryCampaign.recruitment_capacity()-MilitaryCampaign._mobilized_count()<=0 and MilitaryCampaign.aggregate_recruits<=0:reason="no free adults: %d of %d called up" % [people,target]
	var line:="%d of %d called up" % [people,target]
	if people>0:line+=" · drill %d%%" % roundi(drill*100.0)
	return {"state":"under_way" if people>0 else "accepted","line":line,"value":people,"total":target,"progress":float(people)+drill,"reason":reason,"moved":people>0}

# --- Research -------------------------------------------------------------------

static func _research(refs:Dictionary)->Dictionary:
	var id:=String(refs.get("id",""))
	var name:=String(DiscoverySystem.discovery_definition(id).get("name",id.replace("_"," ")))
	if id in GameState.known_discoveries:return {"state":"done","line":"%s is known" % name,"progress":2.0,"moved":true,"value":100,"total":100}
	var progress:=float(GameState.discovery_progress.get(id,0.0))
	var studied:=id in GameState.research_targets.values() or id in GameState.active_investigations.values()
	var reason:="" if studied else "no one studies it now"
	return {"state":"under_way" if progress>0.0 else "accepted","line":"%s · %d%% learned" % [name,roundi(progress*100.0)],"value":roundi(progress*100.0),"total":100,"progress":progress,"reason":reason,"moved":progress>float(refs.get("start",0.0))}

# --- Buildings and defences ------------------------------------------------------

static func _build(refs:Dictionary)->Dictionary:
	var title:=String(refs.get("title",""))
	var built:=0
	for t in GameState.settlement_completed:
		if String(t)==title:built+=1
	if built>int(refs.get("built_before",0)):return {"state":"done","line":"%s stands" % title,"progress":2.0,"moved":true}
	var days:=1.0
	for project:Dictionary in load("res://scripts/settlement_construction.gd")._settlement_definitions():
		if String(project.get("name",""))==title:days=maxf(1.0,float(project.get("days",1.0)))
	var work:=float(GameState.settlement_projects.get(title,0.0))
	var share:=clampf(work/days,0.0,1.0)
	var reason:=""
	if float(GameState.effective_workers("Construction"))<=0.0:reason="nobody is building"
	elif work<=float(refs.get("start_work",0.0)):reason="the builders have not reached it yet"
	return {"state":"under_way" if work>float(refs.get("start_work",0.0)) else "accepted","line":"%s · %d%% built" % [title,roundi(share*100.0)],"value":roundi(share*100.0),"total":100,"progress":work,"reason":reason,"moved":work>float(refs.get("start_work",0.0))}

static func _defences(refs:Dictionary)->Dictionary:
	var HD=load("res://scripts/home_defense.gd")
	var r:Dictionary=HD.reading()
	var word:=String(refs.get("word",HD.word()))
	var status:=String(r.get("status",""))
	var building:Dictionary=r.get("building",{}) if r.get("building") is Dictionary else {}
	var blockers:Array=r.get("blockers",[]) if r.get("blockers") is Array else []
	var blocker:=String((blockers[0] as Dictionary).get("text","")) if not blockers.is_empty() and blockers[0] is Dictionary else ""
	if word=="hold":return {"state":"done","line":"No new works start","progress":1.0,"moved":true}
	if word=="people" and status!="building":return {"state":"done","line":"Our people decide when to build","progress":1.0,"moved":true}
	match status:
		"building":
			var share:=clampf(float(building.get("progress",0.0)),0.0,1.0)
			return {"state":"under_way","line":"%s rising · %d%% · %d days left" % [String(building.get("short","The works")).capitalize(),roundi(share*100.0),int(building.get("days_left",0))],"value":roundi(share*100.0),"total":100,"progress":share,"moved":true}
		"complete":return {"state":"done","line":"Every defence stands","progress":2.0,"moved":true}
		"ready":return {"state":"accepted","line":"Starts at the next check","progress":0.0,"reason":"it starts at the next check"}
	return {"state":"accepted","line":"Waiting: "+(blocker if blocker!="" else status),"reason":blocker if blocker!="" else status,"progress":0.0}

# --- Standing orders and the councils ---------------------------------------------

## A standing order (custom_directive.gd through ConsequenceEngine): no
## single deed; it is in force for its days.
static func _directive(refs:Dictionary)->Dictionary:
	var start:=int(refs.get("start_day",_today()))
	var days:=maxi(1,int(refs.get("days",180)))
	var left:=start+days-_today()
	if left<=0:return {"state":"done","line":"The standing order has run its course","progress":2.0,"moved":true}
	return {"state":"under_way","line":"Standing order, no single deed · %d days left" % left,"value":_today()-start,"total":days,"progress":float(_today()-start),"moved":true,"standing":true}

## An order to a town's leader goes through the civic council
## (pronouncement_interpreter.gd): its state is the council's own record.
static func _civic(refs:Dictionary)->Dictionary:
	var Civic=load("res://scripts/hud/court_civic.gd")
	var sid:=String(refs.get("settlement_id",""))
	var order:Dictionary=Civic.latest_order(sid,int(refs.get("person_id",0))) if sid!="" else {}
	if order.is_empty() or int(order.get("day",order.get("issued_day",_today())))<int(refs.get("start_day",0)):
		return {"state":"accepted","line":"With the town council","reason":"the council has not taken it up","progress":0.0}
	var state:=String(Civic.state(order))
	var words:=String(Civic.status_text(state)).get_slice(" · ",0)
	match state:
		"UNDERWAY":return {"state":"under_way","line":"The council: under way","progress":1.0,"moved":true,"standing":true}
		"REPORTED","OBSERVING EFFECTS":return {"state":"done","line":"The council: done","progress":2.0,"moved":true}
		"REFUSED","BLOCKED","WITHDRAWN":return {"state":"refused_now","line":"The council: "+words.to_lower(),"progress":0.0}
		"DISCUSSION","PROPOSAL RECORDED":return {"state":"accepted","line":"The council: talk only, nothing done","reason":"the council only talked; nothing has changed","progress":0.0}
		"NEEDS YOUR DECISION":return {"state":"accepted","line":"The council waits for your answer","reason":"the town leader objects and waits for you","progress":0.0}
	return {"state":"accepted","line":"The council weighs it","reason":"the town leader is still weighing it","progress":0.0}

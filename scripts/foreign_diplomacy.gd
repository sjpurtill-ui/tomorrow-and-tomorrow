extends Node

const NAMES=preload("res://scripts/historical_name_generator.gd")
const TEMPERAMENTS=["Bridge-builder","Proud guardian","Practical organizer","Restless visionary"]
const TONES={"equals":"Speak as equals","honor":"Honor their standing","firm":"Make a firm case"}
const ACCORDS={
	"exchange":{"name":"Exchange of teachers","domain":"knowledge","purpose":"Let teachers carry useful discoveries between your communities."},
	"routes":{"name":"Shared waystations","domain":"logistics","purpose":"Coordinate safe stopping places and pass on route knowledge."},
	"restraint":{"name":"Border understanding","domain":"culture","purpose":"Recognize each other's independence and quiet the frontier."}
}
var seed_value:=-999999
var leaders:Dictionary={}
var layer:CanvasLayer
var panel:Control

func reset_for_new_world()->void:
	seed_value=-999999; leaders.clear()
	if is_instance_valid(panel): panel.queue_free()
	ForeignDialogue.reset()

func ensure()->void:
	if seed_value==GameState.world_seed: return
	reset_for_new_world(); seed_value=GameState.world_seed

func civilization(id:String)->Dictionary:
	CivilizationSystem.initialize()
	for civ:Dictionary in CivilizationSystem.civilizations:
		if String(civ.id)==id and int(civ.player_relation.get("contact_level",0))>=2: return civ
	return {}

func leader(id:String)->Dictionary:
	ensure()
	var civ:=civilization(id)
	if civ.is_empty(): return {}
	if not leaders.has(id):
		var serial:=posmod(hash(id),10000)
		var traditions:Array=NAMES.POOLS.keys()
		var identity:Dictionary=NAMES.make(seed_value,serial,serial%2==0,traditions[serial%4],{})
		var temperament:String=TEMPERAMENTS[serial%4]
		var past:Array=["Earned a hearing by settling a bitter dispute between families.","Rose to prominence defending the community's right to govern itself.","Won support by organizing work that rival households could not finish alone.","Gathered followers by bringing unfamiliar ideas home from a long journey."]
		leaders[id]={"name":identity.name,"temperament":temperament,"bio":past[serial%4],"trust":0.0,"memories":[],"accord":{},"counter":{},"next_day":0,"serial":0,"resolved":0}
	return leaders[id]

func situation(id:String)->Dictionary:
	var civ:=civilization(id)
	var person:=leader(id)
	if person.is_empty(): return {}
	var relation:Dictionary=civ.player_relation
	if bool(relation.get("at_war",false)): return {"title":"Words across a battlefield","line":"While our people fight, promises of shared work ring hollow. Send peace envoys first.","priority":"restraint"}
	if float(relation.get("border_tension",0))>.45: return {"title":"A frontier on edge","line":"Every movement near the boundary is becoming a rumor. Can we give our people a reason to stop expecting a fight?","priority":"restraint"}
	if not (person.counter as Dictionary).is_empty(): return {"title":"An answer with conditions","line":"I can defend this agreement before my people if yours carries more of the burden. Those are the terms I can offer.","priority":person.counter.accord}
	if String(relation.get("treaty","none"))=="trade": return {"title":"More than exchanging goods","line":"Our traders already meet. Let us make those journeys useful to the people who come after them.","priority":"routes"}
	if int(person.resolved)==0: return {"title":"Two peoples, one first impression","line":"Your envoys have a seat by our fire. Tell me what you want us to build together—and what you are willing to give.","priority":"exchange"}
	return {"title":"What comes after the promise?","line":"We remember how you dealt with us. Show me how this proposal serves both our communities.","priority":"exchange" if String(civ.get("strategy",""))=="inquiry" else "routes"}

func forecast(id:String,accord:String,tone:String,generous:bool=false)->Dictionary:
	var p:=leader(id); var civ:=civilization(id)
	if p.is_empty() or not ACCORDS.has(accord) or not TONES.has(tone): return {"error":"Choose a known leader and supported terms."}
	var relation:Dictionary=civ.player_relation
	var favorite:String={"Bridge-builder":"equals","Proud guardian":"honor","Practical organizer":"firm","Restless visionary":"equals"}[p.temperament]
	var priority:String=situation(id).priority
	var score:float=float(relation.get("opinion",0))*.5+float(p.trust)*.4+(.20 if priority==accord else 0)+(.18 if tone==favorite else (-.15 if tone=="firm" else 0)) + (.28 if generous else 0)
	var reasons:Array[String]=[]
	reasons.append("This addresses their immediate concern." if priority==accord else "Their immediate concern lies elsewhere.")
	reasons.append("This approach suits their temperament." if tone==favorite else ("A hard line may offend them." if tone=="firm" else "Your approach gives no personal advantage."))
	if float(p.trust)<-.1: reasons.append("Past dealings have damaged personal trust.")
	if float(p.trust)>.1: reasons.append("Past dealings give your word weight.")
	var blocker:=""
	if bool(relation.get("at_war",false)): blocker="Peace must be negotiated before shared work."
	elif not (p.accord as Dictionary).is_empty(): blocker="An understanding is already active with this leader."
	elif int(GameState.elapsed_days)<int(p.next_day): blocker="Let the last exchange settle: %d days before another proposal." % (int(p.next_day)-int(GameState.elapsed_days))
	var binding:=not (p.counter as Dictionary).is_empty() and String(p.counter.accord)==accord and generous
	var outcome:="accept" if score>=.25 or binding else ("counter" if score>=-.1 and not generous else "refuse")
	return {"outcome":outcome,"label":{"accept":"Receptive","counter":"Likely to ask for more","refuse":"Unconvinced"}[outcome],"reasons":" ".join(reasons),"blocker":blocker,"cost":12 if generous else 4,"bonus":.08 if generous else .12,"domain":ACCORDS[accord].domain,"binding":binding}

func send(id:String,accord:String,tone:String,generous:bool=false)->Dictionary:
	var f:=forecast(id,accord,tone,generous)
	if f.has("error"): return f
	if f.blocker!="": return {"error":f.blocker}
	if float(GameState.resource_stockpiles.get("Timber",0))<int(f.cost): return {"error":"The delegation needs %d Timber for the proposed shared work." % int(f.cost)}
	var result:=CivilizationSystem.dispatch_diplomat(id,"","leader_parley")
	if result.has("error"): return result
	GameState.resource_stockpiles["Timber"]=float(GameState.resource_stockpiles.get("Timber",0))-int(f.cost)
	var p:=leader(id); p.serial=int(p.serial)+1
	CivilizationSystem.diplomatic_mission["leader_terms"]={"accord":accord,"tone":tone,"generous":generous,"cost":int(f.cost),"serial":p.serial}
	remember(id,"You sent a proposal for %s. The answer is still on the road." % ACCORDS[accord].name)
	return result

func send_audience(id:String)->Dictionary:
	if leader(id).is_empty(): return {"error":"Establish direct contact first."}
	if bool(ForeignDialogue.access(id).ok): return {"error":"Your envoy channel is already established; continue the conversation."}
	var result:=CivilizationSystem.dispatch_diplomat(id,"","leader_parley")
	if result.has("error"): return result
	CivilizationSystem.diplomatic_mission["leader_audience"]=true
	remember(id,"Delegates departed to establish an audience. No agreement was proposed.")
	return result

func resolve(id:String)->Dictionary:
	var mission:Dictionary=CivilizationSystem.diplomatic_mission
	var terms:Dictionary=mission.get("leader_terms",{})
	var p:=leader(id)
	if not p.is_empty() and String(mission.get("civ_id",""))==id and bool(mission.get("leader_audience",false)):
		if int(GameState.elapsed_days)<int(mission.get("return_day",2147483647)): return {"error":"The audience report is still traveling."}
		p["audience_day"]=int(GameState.elapsed_days)
		mission["leader_audience"]=false
		var greeting:="The delegates established an audience with %s. The envoy channel is open for continued discussion; no agreement has been made." % String(p.name)
		remember(id,greeting)
		return {"ok":true,"message":greeting}
	if p.is_empty() or String(mission.get("civ_id",""))!=id or int(GameState.elapsed_days)<int(mission.get("return_day",2147483647)) or not valid_terms(terms): return {"error":"No returned leader proposal is available."}
	if int(terms.serial)<=int(p.resolved): return {"error":"This answer has already been received."}
	if int(terms.serial)!=int(p.serial): return {"error":"This answer does not match the dispatched proposal."}
	var f:=forecast(id,String(terms.accord),String(terms.tone),bool(terms.generous))
	p.resolved=int(terms.serial)
	p["audience_day"]=int(GameState.elapsed_days)
	var outcome:String=f.get("outcome","refuse")
	if String(f.get("blocker",""))!="": outcome="refuse"
	var civ:=civilization(id); var relation:Dictionary=civ.player_relation
	var message:=""
	if outcome=="accept":
		p.counter={}; p.accord={"kind":terms.accord,"until":int(GameState.elapsed_days)+730,"bonus":f.bonus}
		p.trust=clampf(float(p.trust)+.15,-1,1)
		relation.opinion=clampf(float(relation.get("opinion",0))+.08,-1,1)
		if terms.accord=="restraint": relation.border_tension=maxf(0,float(relation.get("border_tension",0))-.25)
		civ["gift_value_received"]=float(civ.get("gift_value_received",0))+int(terms.cost)
		var capability:String="logistics" if terms.accord=="routes" else ("knowledge" if terms.accord=="exchange" else "cohesion")
		civ[capability]=clampf(float(civ.get(capability,0))+(.04 if terms.generous else .02),0,1)
		message="%s agrees to %s. Your %s research gains %d%% for two years; their %s rises %d points. War ends the understanding." % [p.name,ACCORDS[terms.accord].name,ACCORDS[terms.accord].domain,roundi(float(f.bonus)*100),capability,4 if terms.generous else 2]
	elif outcome=="counter":
		p.counter={"accord":terms.accord}; p.next_day=int(GameState.elapsed_days)
		message="%s offers a counterproposal: your people supply 12 Timber and receive an 8%% research benefit; theirs gain four capability points. Send revised terms whenever you wish." % p.name
	else:
		p.counter={}; p.next_day=int(GameState.elapsed_days)+90
		p.trust=clampf(float(p.trust)-.04,-1,1)
		message="%s declines. %s The next approach can be made after 90 days." % [p.name,"War has overtaken the proposal." if bool(relation.get("at_war",false)) else String(f.get("reasons","Conditions have changed."))]
	if outcome!="accept":
		GameState.resource_stockpiles["Timber"]=float(GameState.resource_stockpiles.get("Timber",0))+int(terms.cost)
		message+=" The reserved Timber is returned; journey provisions were consumed."
	remember(id,message)
	return {"ok":outcome=="accept","message":message,"outcome":outcome}

func remember(id:String,message:String)->void:
	var p:=leader(id)
	if p.is_empty(): return
	p.memories.push_front({"day":int(GameState.elapsed_days),"text":message})
	if p.memories.size()>12: p.memories.resize(12)

func advance(day:int)->void:
	ensure()
	for id:String in leaders.keys():
		var civ:=civilization(id); var p:Dictionary=leaders[id]
		if civ.is_empty() or (p.accord as Dictionary).is_empty(): continue
		var war:=bool(civ.player_relation.get("at_war",false))
		if war or day>=int(p.accord.until):
			p.accord={}; p.next_day=day+90 if war else day
			p.trust=clampf(float(p.trust)+(-.35 if war else .10),-1,1)
			remember(id,"War ended our shared undertaking. Trust fell sharply." if war else "Two years of cooperation completed. Your word carries more weight now.")

func multiplier(domain:String)->float:
	advance(int(GameState.elapsed_days))
	var bonus:=0.0
	for p:Dictionary in leaders.values():
		if not (p.accord as Dictionary).is_empty() and ACCORDS[p.accord.kind].domain==domain: bonus+=float(p.accord.bonus)
	return 1.0+minf(.24,bonus)

func valid_terms(t:Dictionary)->bool:
	return t.has_all(["accord","tone","generous","cost","serial"]) and ACCORDS.has(t.accord) and TONES.has(t.tone) and t.generous is bool and t.cost==(12 if t.generous else 4) and (t.serial is int or t.serial is float) and float(t.serial)>=1

func export_state()->Dictionary:
	ensure(); return {"seed":seed_value,"leaders":leaders.duplicate(true),"dialogue":ForeignDialogue.export_state()}

func import_state(data:Dictionary)->Dictionary:
	if data.get("seed")!=GameState.world_seed or not data.get("leaders") is Dictionary or data.leaders.size()>8: return {"error":"Invalid foreign leader state."}
	if not ForeignDialogue.validate_state(data.get("dialogue",{})): return {"error":"Invalid foreign discussion history."}
	for id in data.get("dialogue",{}):
		if not data.leaders.has(id): return {"error":"Discussion references an unknown leader."}
	for id in data.leaders:
		var p:Variant=data.leaders[id]
		if not id is String or not p is Dictionary or not p.has_all(["name","temperament","bio","trust","memories","accord","counter","next_day","serial","resolved"]): return {"error":"Incomplete foreign leader."}
		if not p.name is String or p.name.length()>100 or not p.bio is String or p.bio.length()>500 or p.temperament not in TEMPERAMENTS: return {"error":"Invalid foreign identity."}
		for field in ["trust","next_day","serial","resolved"]:
			if not (p[field] is int or p[field] is float) or not is_finite(float(p[field])): return {"error":"Invalid foreign leader value."}
		if absf(float(p.trust))>1 or p.next_day<0 or p.resolved<0 or p.serial<p.resolved: return {"error":"Invalid foreign leader history."}
		if p.has("audience_day") and (not (p.audience_day is int or p.audience_day is float) or not is_finite(float(p.audience_day)) or p.audience_day<0): return {"error":"Invalid audience date."}
		if not p.memories is Array or p.memories.size()>12 or not p.accord is Dictionary or not p.counter is Dictionary: return {"error":"Invalid foreign commitments."}
		for m in p.memories:
			if not m is Dictionary or not m.get("text") is String or m.text.length()>2000 or not (m.get("day") is int or m.get("day") is float): return {"error":"Invalid foreign memory."}
		if not p.counter.is_empty() and not ACCORDS.has(p.counter.get("accord","")): return {"error":"Invalid counteroffer."}
		if not p.accord.is_empty():
			if not ACCORDS.has(p.accord.get("kind","")) or p.accord.get("bonus",0) not in [.08,.12] or not (p.accord.get("until") is int or p.accord.get("until") is float) or not is_finite(float(p.accord.until)) or p.accord.until<0: return {"error":"Invalid active understanding."}
	leaders=data.leaders.duplicate(true); seed_value=GameState.world_seed; ForeignDialogue.import_state(data.get("dialogue",{}))
	return {"ok":true}

func open(id:String)->void:
	if leader(id).is_empty(): return
	if is_instance_valid(panel): panel.queue_free()
	if not is_instance_valid(layer): layer=CanvasLayer.new(); layer.layer=84; add_child(layer)
	panel=preload("res://scripts/foreign_leader_screen.gd").new(); panel.civ_id=id; layer.add_child(panel)

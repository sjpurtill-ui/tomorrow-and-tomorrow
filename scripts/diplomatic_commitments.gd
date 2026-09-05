extends RefCounted
## Bounded, executable commitments. Conversation never calls resolve directly.
const ACTIONS={"protection":"Mutual protection", "found_faction":"Found a league", "join_faction":"Invite to our league", "set_goal":"Change the league's policy", "debate_war":"Consult the league about war", "leave_faction":"Leave the league", "request_relief":"Request siege relief", "negotiate_siege":"Negotiate a siege withdrawal"}
const GOALS={"defense":"Mutual defense", "exchange":"Learning and exchange", "routes":"Safe roads and commerce"}
const OBLIGATION="Respond to a member's defensive siege with feasible relief; consult before offensive war. No automatic conquest or unlimited military guarantee."
var state:Dictionary={"serial":0,"resolved":0,"pacts":{},"factions":[],"obligations":[],"relief":[],"history":[]}

func civ(id:String)->Dictionary:
	for value:Dictionary in CivilizationSystem.civilizations:
		if String(value.id)==id: return value
	return {}

func faction(id:String="player")->Dictionary:
	for value:Dictionary in state.factions:
		if id in value.members: return value
	return {}

func valid_terms(t:Variant)->bool:
	return t is Dictionary and t.has_all(["action","goal","target_id","siege_id"]) and ACTIONS.has(t.action) and GOALS.has(t.goal) and t.target_id is String and t.target_id.length()<=80 and t.siege_id is String and t.siege_id.length()<=120

func terms(action:String,goal:String="defense",target_id:String="",siege_id:String="")->Dictionary:
	return {"action":action,"goal":goal,"target_id":target_id,"siege_id":siege_id}

func opinion(first:String,second:String)->float:
	if first==second: return 1.0
	var value:=civ(second if first=="player" else first)
	if value.is_empty(): return -1.0
	return float(value.player_relation.get("opinion",0)) if "player" in [first,second] else float((value.relations as Dictionary).get(second,{}).get("opinion",0))

func at_war(first:String,second:String)->bool:
	var value:=civ(second if first=="player" else first)
	if value.is_empty(): return true
	return bool(value.player_relation.get("at_war",false)) if "player" in [first,second] else bool((value.relations as Dictionary).get(second,{}).get("at_war",false))

func eligibility(id:String,t:Dictionary)->String:
	if not valid_terms(t) or ForeignDiplomacy.leader(id).is_empty(): return "Choose a known leader and valid terms."
	var league:=faction()
	if t.action not in ["negotiate_siege","leave_faction"] and at_war("player",id): return "We are at war with this leader; settle that conflict first."
	match String(t.action):
		"protection":
			if state.pacts.has(id): return "Our mutual protection treaty is already active."
			if state.pacts.size()>=8: return "We already maintain eight separate protection commitments; use a shared league for broader coordination."
		"found_faction":
			if not league.is_empty() or not faction(id).is_empty(): return "Both founders must be independent of another league."
			if state.factions.size()>=4: return "The world already has four active leagues."
		"join_faction":
			if league.is_empty():
				league=faction(id)
				if league.is_empty(): return "Found a league first, or address a member of an existing league to join theirs."
			elif not faction(id).is_empty(): return "This civilization already belongs to a league."
			if league.members.size()>=9: return "All nine civilization seats are already filled."
		"set_goal","debate_war","leave_faction":
			if league.is_empty() or id not in league.members: return "Address a member of your league."
			if t.action=="debate_war" and (ForeignDiplomacy.civilization(t.target_id).is_empty() or t.target_id in league.members): return "Choose a known civilization outside the league for the war discussion."
		"request_relief":
			if not covered(id,"player",t.siege_id): return "No defensive siege obligation to us is active for this leader."
		"negotiate_siege":
			var siege:=siege_info(t.siege_id)
			if not bool(siege.get("active",false)) or id not in [siege.get("attacker_id"),siege.get("defender_id")]: return "Choose an active siege involving this leader."
			if MilitaryCampaign.has_method("siege_negotiation_available"):
				var consent:Dictionary=MilitaryCampaign.call("siege_negotiation_available",t.siege_id,id)
				if not bool(consent.get("ok",false)): return String(consent.get("reason",consent.get("error","The opposing leader is not willing to withdraw under these conditions.")))
	return ""

func assessment(id:String,t:Dictionary)->Dictionary:
	var blocker:=eligibility(id,t)
	var votes:Dictionary={}
	var voters:Array=[id]
	var league:=faction()
	if league.is_empty() and t.action=="join_faction": league=faction(id)
	if not league.is_empty() and t.action in ["join_faction","set_goal","debate_war"]:
		for member:String in league.members:
			if member!="player" and member not in voters: voters.append(member)
	for member:String in voters:
		var support:=opinion("player",member)+float(ForeignDiplomacy.leader(member).get("trust",0))*.35
		var reason:="Our dealings give this proposal a basis." if support>=.05 else "We need stronger relations before taking on this promise."
		if t.action=="join_faction" and "player" in league.get("members",[]) and member!=id:
			support=minf(support,opinion(member,id)); reason="We judge the candidate by our own relationship with them."
		if t.action=="debate_war":
			support=-opinion(member,t.target_id)-.20
			reason="We weigh our own relationship with the proposed opponent; a vote is not a mobilization order."
		if t.action=="set_goal" and String(t.goal)=="defense": support+=.1
		votes[member]={"accept":support>=.05,"reason":reason}
	var accepted:=blocker==""
	for vote:Dictionary in votes.values(): accepted=accepted and bool(vote.accept)
	if t.action in ["leave_faction","request_relief","negotiate_siege"]: accepted=blocker==""
	return {"blocker":blocker,"accepted":accepted,"votes":votes,"rule":"Unanimous consent; each civilization retains its own leader and forces."}

func mission_quote(id:String,t:Dictionary)->Dictionary:
	var error:=eligibility(id,t)
	if error!="": return {"error":error}
	var quote:=CivilizationSystem.diplomatic_mission_quote(id,"","leader_parley")
	if quote.has("error"): return quote
	# A league proposal includes physical consultation of every existing member.
	var extra_days:=0
	var league:=faction()
	if league.is_empty() and t.action=="join_faction": league=faction(id)
	if not league.is_empty() and t.action in ["join_faction","set_goal","debate_war","leave_faction"]:
		for member:String in league.members:
			if member!="player" and member!=id: extra_days+=CivilizationSystem._intercivilization_message_days(civ(id),civ(member))
	var extra_food:=float(extra_days)*float(quote.personnel)*.55
	if FoodSystem.total_stored()<float(quote.provisions)+extra_food: return {"error":"The delegation and league consultations need %.1f Food." % (float(quote.provisions)+extra_food)}
	quote["consultation_days"]=extra_days; quote["consultation_food"]=extra_food
	return quote

func send(id:String,t:Dictionary)->Dictionary:
	var quote:=mission_quote(id,t)
	if quote.has("error"): return quote
	var extra_days:=int(quote.consultation_days); var extra_food:=float(quote.consultation_food)
	var result:=CivilizationSystem.dispatch_diplomat(id,"","leader_parley")
	if result.has("error"): return result
	if extra_food>0: FoodSystem.issue_for_obligation(extra_food,"diplomacy","League consultations",extra_days,int(quote.personnel))
	state.serial=int(state.serial)+1
	var carried:=t.duplicate(true); carried["serial"]=state.serial
	CivilizationSystem.diplomatic_mission["commitment_terms"]=carried
	CivilizationSystem.diplomatic_mission.return_day+=extra_days
	CivilizationSystem.diplomatic_mission.provisions+=extra_food
	ForeignDiplomacy.remember(id,"Envoys carry our proposal: %s. No commitment exists until their return." % ACTIONS[t.action])
	return result

func resolve(id:String,mission:Dictionary)->Dictionary:
	var t:Dictionary=mission.get("commitment_terms",{})
	if not valid_terms(t) or String(mission.get("civ_id",""))!=id or int(GameState.elapsed_days)<int(mission.get("return_day",2147483647)): return {"error":"No returned commitment proposal is available."}
	if not number(t.get("serial")) or float(t.serial)!=floor(float(t.serial)) or int(t.serial)!=int(state.serial) or int(t.serial)<=int(state.resolved): return {"error":"This commitment answer was already received or is stale."}
	state.resolved=int(t.serial)
	var forecast:=assessment(id,t)
	var message:=String(forecast.blocker)
	var ok:=bool(forecast.accepted)
	var league:=faction()
	if league.is_empty() and t.action=="join_faction": league=faction(id)
	if ok:
		match String(t.action):
			"protection":
				state.pacts[id]={"since":int(GameState.elapsed_days),"trigger":"defensive_siege","obligation":OBLIGATION}
				message="Mutual protection is ratified. It covers defensive sieges beginning after today, subject to real forces, provisions and access; it does not authorize offensive wars."
			"found_faction":
				state.factions.append({"id":"league_%d" % int(t.serial),"name":"League of %s" % String(civ(id).name),"members":["player",id],"joined":{"player":int(GameState.elapsed_days),id:int(GameState.elapsed_days)},"goal":t.goal,"since":int(GameState.elapsed_days),"votes":{},"obligation":OBLIGATION})
				message="Our league is founded. Each member keeps its leader, people and army. New members and policy changes require consultation and unanimous consent."
			"join_faction":
				var joining:String=id if "player" in league.members else "player"
				league.members.append(joining); league.votes=forecast.votes
				league.joined[joining]=int(GameState.elapsed_days)
				message="The candidate and existing members consent. %s joins the league." % (String(civ(id).name) if joining!="player" else "Your civilization")
			"set_goal":
				league.goal=t.goal; league.votes=forecast.votes
				message="Members adopt %s. Foreign members shift four percentage points of strategic effort toward that goal; your own allocations remain under your control." % GOALS[t.goal]
			"debate_war":
				league.votes=forecast.votes
				message="Members support discussing war against %s. No declaration or troops have been sent; each member must still act through its military and diplomacy systems." % String(civ(t.target_id).name)
			"leave_faction":
				league.members.erase("player")
				league.joined.erase("player")
				message="Our departure has reached the league. Membership obligations end; any separate protection treaty remains."
				if league.members.size()<2: state.factions.erase(league)
			"request_relief":
				var result:=dispatch_relief(id,"player",t.siege_id)
				ok=bool(result.get("ok",false)); message=String(result.get("message",result.get("error","Relief could not depart.")))
			"negotiate_siege":
				var result:Dictionary={"error":"No siege negotiation executor is available."}
				if MilitaryCampaign.has_method("negotiated_siege_withdrawal"): result=MilitaryCampaign.call("negotiated_siege_withdrawal",t.siege_id,id)
				ok=bool(result.get("ok",false)); message=String(result.get("message",result.get("error","The siege terms were declined.")))
	else:
		if not league.is_empty(): league.votes=forecast.votes
		if message=="": message="The proposal did not receive unanimous consent. The recorded positions explain the disagreement; revise it and continue the discussion."
	ForeignDiplomacy.leader(id)["audience_day"]=int(GameState.elapsed_days)
	ForeignDiplomacy.remember(id,message); record(message)
	return {"ok":ok,"message":message}

func record(message:String)->void:
	state.history.push_front({"day":int(GameState.elapsed_days),"text":message})
	if state.history.size()>24: state.history.resize(24)

func note_food_aid(id:String,amount:float,day:int)->void:
	if amount<=0: return
	for obligation:Dictionary in state.obligations:
		if obligation.donor=="player" and obligation.beneficiary==id and obligation.status=="requested":
			obligation.status="food_aid_delivered"
			record("Day %d: %.1f Food reached %s in response to their call. Food support has been delivered; no military force was promised or created by this shipment." % [day,amount,id])

func policy_allocations(id:String,allocations:Dictionary)->Dictionary:
	var league:=faction(id)
	if league.is_empty(): return allocations
	var result:=allocations.duplicate(true)
	var recipient:String={"defense":"military","exchange":"knowledge","routes":"production"}[league.goal]
	var source:="production" if recipient=="military" else "military"
	var amount:=minf(.04,float(result.get(source,0)))
	result[source]=float(result.get(source,0))-amount; result[recipient]=float(result.get(recipient,0))+amount
	return result

func siege_info(id:String)->Dictionary:
	if not MilitaryCampaign.has_method("siege_public_snapshot"): return {}
	return MilitaryCampaign.call("siege_public_snapshot","" if id=="current" else id)

func covered(donor:String,beneficiary:String,siege_id:String)->bool:
	for obligation:Dictionary in state.obligations:
		if obligation.donor==donor and obligation.beneficiary==beneficiary and obligation.siege_id==siege_id and obligation.status=="requested":
			var league:=faction(donor)
			var pact_id:=beneficiary if donor=="player" else donor
			var pact:=bool("player" in [donor,beneficiary] and state.pacts.has(pact_id))
			return not at_war(donor,beneficiary) and (pact or (not league.is_empty() and beneficiary in league.members))
	return false

func notify_attack(attacker:String,defender:String,siege_id:String,day:int)->void:
	# Called by the siege executor only for an actual defensive siege.
	var siege:=siege_info(siege_id)
	if not bool(siege.get("active",false)) or siege.get("attacker_id")!=attacker or siege.get("defender_id")!=defender or int(siege.get("start_day",-1))!=day: return
	var verified:=false
	for war:Dictionary in CivilizationSystem.war_history:
		if String(war.get("status",""))=="active" and attacker in war.get("participants",[]) and defender in war.get("participants",[]) and war_initiator(war)==attacker: verified=true; break
	if not verified: return
	create_obligations(attacker,defender,siege_id,day)

func war_initiator(war:Dictionary)->String:
	var participants:Array=war.get("participants",[])
	if participants.size()!=2: return ""
	var cause:=String(war.get("cause",""))
	if cause=="Organized rival invasion": return String(participants[1])
	if cause.begins_with("War declared by ") or cause=="A physically carried declaration follows escalating border pressure": return String(participants[0])
	# Older inferred wars and occupation uprisings do not prove defensive eligibility.
	return ""

func create_obligations(attacker:String,defender:String,siege_id:String,day:int)->void:
	var donors:Array=[]
	if defender=="player":
		for id:String in state.pacts:
			if int(state.pacts[id].since)<day: donors.append(id)
	elif state.pacts.has(defender) and int(state.pacts[defender].since)<day: donors.append("player")
	var league:=faction(defender)
	if not league.is_empty() and int(league.joined.get(defender,day))<day:
		for member:String in league.members:
			if member!=defender and member not in donors and int(league.joined.get(member,day))<day: donors.append(member)
	for donor:String in donors:
		if donor==attacker or at_war(donor,defender): continue
		var existing:=false
		for obligation:Dictionary in state.obligations:
			if obligation.siege_id==siege_id and obligation.donor==donor: existing=true
		if existing: continue
		if state.obligations.size()>=32: return
		state.obligations.append({"donor":donor,"beneficiary":defender,"attacker":attacker,"siege_id":siege_id,"day":day,"status":"requested"})
		record("%s requests defensive relief from %s under an existing promise." % [defender,donor])

func observe_ally_wars()->void:
	# Rival-only wars have aggregate records, not simulated siege scenes. Their
	# defensive call requests player aid; it never manufactures a besieged city.
	for war:Dictionary in CivilizationSystem.war_history:
		if war.get("status")!="active" or "player" in war.get("participants",[]): continue
		var attacker:=war_initiator(war)
		if attacker=="": continue
		var members:Array=war.participants
		var defender:=String(members[1] if members[0]==attacker else members[0])
		var source:=civ(defender)
		if source.is_empty() or int(source.player_relation.get("contact_level",0))<2: continue
		var league:=faction()
		if not state.pacts.has(defender) and (league.is_empty() or defender not in league.members): continue
		# Use the known home route to the actual player origin for message travel.
		var position:Dictionary=source.player_relation.get("home_position",{})
		if not position.has_all(["x","z"]): continue
		var delay:=maxi(3,ceili(CivilizationSystem.player_world_origin.distance_to(Vector2(float(position.x),float(position.z)))/13.0))
		if int(GameState.elapsed_days)<int(war.started_day)+delay: continue
		create_obligations(attacker,defender,"war:"+String(war.id),int(war.started_day))

func relief_quote(donor:String,beneficiary:String,siege_id:String)->Dictionary:
	if not covered(donor,beneficiary,siege_id): return {"error":"There is no unfulfilled defensive relief obligation."}
	if donor=="player": return {"error":"Send an existing army through military controls; a treaty cannot create a new player force."}
	var siege:=siege_info(siege_id)
	if not bool(siege.get("active",false)) or String(siege.get("defender_id",""))!=beneficiary: return {"error":"The defensive siege has ended or changed."}
	var source:=civ(donor)
	if source.is_empty() or not bool(source.get("alive",true)) or at_war(donor,beneficiary): return {"error":"This donor cannot aid the beneficiary."}
	if opinion(donor,beneficiary)<-.20: return {"error":"The leader declines to honor the promise after relations deteriorated. This refusal is recorded."}
	if state.relief.size()>=16: return {"error":"All sixteen tracked relief missions are still active."}
	var position:Dictionary=siege.get("target_position",{})
	if not position.has_all(["x","z"]): return {"error":"No confirmed route reaches this siege."}
	var origin:=CivilizationSystem._civilization_world_position(source)
	var distance:=origin.distance_to(Vector2(float(position.x),float(position.z)))
	var days:=maxi(3,ceili(distance/(17.0*(.75+float(source.logistics)*.25))))
	var available:=maxi(0,floori(float(source.military_population)*.20))
	# Keep at least 20 days of food at home; reserve every ration before departure.
	var spare:=maxf(0,float(source.food_days)-20)*float(source.population)
	var per_troop:=float(days*2+30)*.55
	var troops:=mini(available,floori(spare/maxf(1,per_troop)))
	if troops<3 or float(source.military_readiness)<.20: return {"error":"The leader cannot spare a provisioned relief force without stripping home defense or food reserves."}
	return {"ok":true,"troops":troops,"food":float(troops)*per_troop,"travel_days":days,"travel_food":float(troops)*float(days)*.55,"camp_food":float(troops)*30*.55}

func dispatch_relief(donor:String,beneficiary:String,siege_id:String)->Dictionary:
	var quote:=relief_quote(donor,beneficiary,siege_id)
	if quote.has("error"): return quote
	var source:=civ(donor)
	source.military_population=float(source.military_population)-int(quote.troops)
	source.food_days=maxf(0,float(source.food_days)-float(quote.food)/maxf(1,float(source.population)))
	state.serial=int(state.serial)+1
	var receipt:={"id":"relief_%d" % int(state.serial),"siege_id":siege_id,"donor_civ_id":donor,"beneficiary_id":beneficiary,"troops":int(quote.troops),"food":float(quote.camp_food),"travel_food":float(quote.travel_food),"travel_days":int(quote.travel_days),"due_day":int(GameState.elapsed_days)+int(quote.travel_days),"status":"outbound","survivors":int(quote.troops),"unused_food":0.0}
	state.relief.append(receipt)
	for obligation:Dictionary in state.obligations:
		if obligation.donor==donor and obligation.beneficiary==beneficiary and obligation.siege_id==siege_id: obligation.status="dispatched"
	var message:="%s sends %d existing troops with %.1f Food reserved for both travel legs and thirty days at the siege. Arrival is expected around day %d." % [String(source.name),int(quote.troops),float(quote.food),int(receipt.due_day)]
	record(message)
	return {"ok":true,"message":message,"receipt_id":receipt.id}

func consume_receipt(receipt_id:String,siege_id:String)->Dictionary:
	for receipt:Dictionary in state.relief:
		if receipt.id!=receipt_id: continue
		if receipt.siege_id!=siege_id or receipt.status!="delivered" or int(GameState.elapsed_days)<int(receipt.due_day): return {"error":"No matching delivered relief receipt is available."}
		var siege:=siege_info(siege_id)
		if not bool(siege.get("active",false)) or String(siege.get("defender_id",""))!=String(receipt.beneficiary_id): return {"error":"The receipt's beneficiary is not defending this active siege."}
		receipt.status="camped"
		return {"ok":true,"donor_civ_id":receipt.donor_civ_id,"beneficiary_id":receipt.beneficiary_id,"troops":receipt.troops,"food":receipt.food}
	return {"error":"Unknown relief receipt."}

func complete_relief(receipt_id:String,survivors:int,unused_food:float)->Dictionary:
	for receipt:Dictionary in state.relief:
		if receipt.id!=receipt_id: continue
		# Relief camps do not participate in casualty rounds. A lower survivor
		# count needs a future explicit casualty/death-ledger transaction first.
		if receipt.status not in ["camped","delivered","outbound"] or survivors!=int(receipt.troops) or not is_finite(unused_food) or unused_food<0 or unused_food>float(receipt.food)+.001: return {"error":"Invalid or duplicate relief return."}
		receipt.survivors=survivors; receipt.unused_food=unused_food; receipt.status="returning"
		receipt.due_day=int(GameState.elapsed_days)+int(receipt.travel_days)
		return {"ok":true}
	return {"error":"Unknown relief receipt."}

func advance_relief(day:int)->void:
	for receipt:Dictionary in state.relief.duplicate():
		if day<int(receipt.due_day): continue
		if receipt.status=="outbound":
			receipt.status="delivered"
			var delivered:Dictionary={"error":"Siege ended."}
			if MilitaryCampaign.has_method("receive_siege_relief"): delivered=MilitaryCampaign.call("receive_siege_relief",receipt.siege_id,receipt.id)
			if not bool(delivered.get("ok",false)): complete_relief(receipt.id,int(receipt.troops),float(receipt.food))
		elif receipt.status=="returning":
			var source:=civ(receipt.donor_civ_id)
			if not source.is_empty():
				source.military_population=minf(float(source.population),float(source.military_population)+int(receipt.survivors))
				source.food_days=minf(180,float(source.food_days)+float(receipt.unused_food)/maxf(1,float(source.population)))
				record("%d relief troops returned to %s with %.1f unused Food." % [int(receipt.survivors),String(source.name),float(receipt.unused_food)])
			state.relief.erase(receipt)

func advance(day:int)->void:
	if state.pacts.is_empty() and state.factions.is_empty() and state.obligations.is_empty() and state.relief.is_empty(): return
	advance_relief(day)
	observe_ally_wars()
	for id:String in state.pacts.keys():
		if at_war("player",id): state.pacts.erase(id); record("War broke our separate protection treaty with %s." % id)
	for league:Dictionary in state.factions.duplicate():
		for member:String in (league.members as Array).duplicate():
			if member=="player" or member not in league.members: continue
			for other:String in league.members:
				if other!=member and at_war(member,other):
					league.members.erase(member); league.joined.erase(member); record("War between %s and %s broke their shared league membership." % [member,other]); break
		if league.members.size()<2: state.factions.erase(league)
	for obligation:Dictionary in state.obligations:
		if obligation.status=="requested" and (day-int(obligation.day)>730 or not covered(obligation.donor,obligation.beneficiary,obligation.siege_id)): obligation.status="expired"
	while state.obligations.size()>24 and state.obligations[0].status!="requested": state.obligations.pop_front()

func public_snapshot(id:String)->Dictionary:
	var league:=faction()
	var promises:Array=[]
	for obligation:Dictionary in state.obligations:
		if "player" in [obligation.donor,obligation.beneficiary]: promises.append(obligation.duplicate(true))
	var missions:Array=[]
	for receipt:Dictionary in state.relief:
		if receipt.beneficiary_id=="player": missions.append({"id":receipt.id,"donor":receipt.donor_civ_id,"status":receipt.status,"due_day":receipt.due_day,"troops":receipt.troops})
	var known:Array=[]
	for value:Dictionary in CivilizationSystem.civilizations:
		if int(value.player_relation.get("contact_level",0))>=2: known.append({"id":String(value.id),"name":String(value.name)})
	return {"protection":state.pacts.get(id,{}).duplicate(true),"league":league.duplicate(true),"obligations":promises,"relief":missions,"history":state.history.duplicate(true),"known_civilizations":known,"actions":ACTIONS,"goals":GOALS}

func validate(data:Variant)->bool:
	if not data is Dictionary or not data.has_all(["serial","resolved","pacts","factions","obligations","relief","history"]): return false
	for key:String in ["serial","resolved"]:
		if not number(data[key]) or float(data[key])<0 or float(data[key])!=floor(float(data[key])): return false
	if data.resolved>data.serial or not data.pacts is Dictionary or data.pacts.size()>8: return false
	for id in data.pacts:
		var pact:Variant=data.pacts[id]
		if not id is String or civ(id).is_empty() or not pact is Dictionary or pact.get("trigger")!="defensive_siege" or not number(pact.get("since")) or pact.since<0 or pact.get("obligation")!=OBLIGATION: return false
	for key:String in ["factions","obligations","relief","history"]:
		if not data[key] is Array: return false
	if data.factions.size()>4 or data.obligations.size()>32 or data.relief.size()>16 or data.history.size()>24: return false
	var members:Array=[]; var ids:Array=[]
	for league in data.factions:
		if not league is Dictionary or not league.has_all(["id","name","members","joined","goal","since","votes","obligation"]): return false
		if not league.id is String or league.id.length()>80 or league.id in ids or not league.name is String or league.name.length()>160 or not GOALS.has(league.goal) or not league.members is Array or league.members.size()<2 or league.members.size()>9 or not number(league.since) or league.since<0 or not league.votes is Dictionary or league.votes.size()>8 or league.obligation!=OBLIGATION: return false
		ids.append(league.id)
		if not league.joined is Dictionary or league.joined.size()!=league.members.size(): return false
		for member in league.members:
			if not member is String or member in members or (member!="player" and civ(member).is_empty()): return false
			if not number(league.joined.get(member)) or league.joined[member]<league.since: return false
			members.append(member)
		for voter in league.votes:
			var vote:Variant=league.votes[voter]
			if not voter is String or civ(voter).is_empty() or not vote is Dictionary or not vote.get("accept") is bool or not vote.get("reason") is String or vote.reason.length()>500: return false
	for item in data.history:
		if not item is Dictionary or not number(item.get("day")) or item.day<0 or not item.get("text") is String or item.text.length()>2000: return false
	for item in data.obligations:
		if not item is Dictionary or not item.has_all(["donor","beneficiary","attacker","siege_id","day","status"]): return false
		for key:String in ["donor","beneficiary","attacker"]:
			if not item[key] is String or (item[key]!="player" and civ(item[key]).is_empty()): return false
		if not item.siege_id is String or item.siege_id.length()>120 or not number(item.day) or item.day<0 or item.status not in ["requested","dispatched","expired","declined","food_aid_delivered"]: return false
	var receipts:Array=[]
	for receipt in data.relief:
		if not receipt is Dictionary or not receipt.has_all(["id","siege_id","donor_civ_id","beneficiary_id","troops","food","travel_food","travel_days","due_day","status","survivors","unused_food"]): return false
		if not receipt.id is String or receipt.id.length()>80 or receipt.id in receipts or not receipt.siege_id is String or receipt.siege_id.length()>120 or not receipt.donor_civ_id is String or civ(receipt.donor_civ_id).is_empty() or not receipt.beneficiary_id is String or (receipt.beneficiary_id!="player" and civ(receipt.beneficiary_id).is_empty()) or receipt.status not in ["outbound","delivered","camped","returning"]: return false
		for key:String in ["troops","food","travel_food","travel_days","due_day","survivors","unused_food"]:
			if not number(receipt[key]) or float(receipt[key])<0: return false
		if receipt.troops<3 or receipt.troops>1000000000 or receipt.survivors!=receipt.troops or receipt.unused_food>receipt.food or receipt.travel_days<3: return false
		for key:String in ["troops","survivors","travel_days","due_day"]:
			if float(receipt[key])!=floor(float(receipt[key])): return false
		if not is_equal_approx(float(receipt.food),float(receipt.troops)*30*.55) or not is_equal_approx(float(receipt.travel_food),float(receipt.troops)*float(receipt.travel_days)*.55): return false
		receipts.append(receipt.id)
	return true

func number(value:Variant)->bool:
	return (value is int or value is float) and is_finite(float(value))

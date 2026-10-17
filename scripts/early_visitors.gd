extends RefCounted
## Personal encounters below 1,000 people. The hall owns their saved records;
## existing population, stores, knowledge and relationship ledgers own effects.
const Hall:=preload("res://scripts/audience_hall.gd")
const Society:=preload("res://scripts/society_exchange.gd")
const Exchange:=preload("res://scripts/civilization_exchange.gd")
const Names:=preload("res://scripts/era_names.gd")
const LIMIT:=1000
const CASES:=["hunt","craft","lovers","traveller","families","captives","invitation","return"]
const TITLES:={"hunt":"A hunter with a grievance","craft":"A craftsperson seeking a home","lovers":"Two people seeking shelter","traveller":"A traveller offering a guide","families":"A household at your fire","captives":"A visitor with your missing scouts","invitation":"An invitation to a gathering","return":"A familiar visitor"}

static func active()->bool:return float(GameState.population_exact)>0.0 and float(GameState.population_exact)<LIMIT
static func handles(a:Dictionary)->bool:return String(a.get("situation",{}).get("type",""))=="early_visit"
static func urgent(o:Dictionary)->bool:
	# Real war/peace consequences remain possible; hunger and first contact
	# do not bypass the personal-visit budget just by being tagged a crisis.
	return String(o.get("type","")) in ["war_end","peace_possible","feud_peace","submission"] or (String(o.get("type",""))=="sequel" and String(o.get("data",{}).get("branch",""))=="peace")

static func available_adults(source:Node)->float:
	if source==null:return 0.0
	var count:=0.0
	for cohort in ["early_adults","established_adults","mature_adults"]:count+=float(source.population_cohorts.get(cohort,0.0))
	return count

static func craft(civ_id:String,subject:String="")->Dictionary:
	var source:=Society.owner_state(civ_id)
	if source==null:return {}
	for id:String in source.known_discoveries:
		if subject!="" and id!=subject:continue
		if id in GameState.known_discoveries or Society.data().evidence.has(id):continue
		if not Society.OBJECTS.has(id):continue
		var definition:Dictionary=DiscoverySystem.discovery_definition(id)
		if definition.is_empty() or bool(definition.get("frontier",false)):continue
		if float(source.discovery_adoption.get(id,0.0))<0.35:continue
		if Society.data().collections.has("visitor:"+civ_id+":"+id):continue
		return {"id":id,"name":String(definition.name),"signals":definition.get("signals",[]).duplicate()}
	return {}

static func previous(civ_id:String,day:int)->Dictionary:
	for a:Dictionary in Hall.state().history:
		if not handles(a) or String(a.get("civ_id",""))!=civ_id or a.status!="resolved":continue
		if a.get("return_used",false) or String(a.situation.visit.case)=="return":continue
		var ago:=day-int(a.arrived_day)
		if ago>=365 and ago<=3650:return a
	return {}

static func eligible(civ_id:String,day:int)->Array[String]:
	var out:Array[String]=[]
	if not active():return out
	var civ:=ForeignDiplomacy.civilization(civ_id)
	if civ.is_empty() or bool(civ.get("player_relation",{}).get("at_war",false)):return out
	if not preload("res://scripts/envoy_requests.gd").plausible("joint_hunt",civ,day):return out
	var relation:Dictionary=civ.get("player_relation",{})
	var source:=Society.owner_state(civ_id)
	if float(relation.get("border_tension",0))>=0.15 and Hall.player_stock("Food")>=4:out.append("hunt")
	if source!=null and float(source.population_exact)>30:
		if available_adults(source)>=2:out.append("lovers")
		if available_adults(source)>=1 and not craft(civ_id).is_empty() and Society.data().collections.size()<Society.COLLECTION_LIMIT:out.append("craft")
		if float(civ.get("food_days",30))<22 or float(civ.get("health",0.8))<0.55 or float(civ.get("displaced_population",0))>0:out.append("families")
	if not CivilizationSystem._scout_target_option("contact:"+civ_id).is_empty():out.append("traveller")
	if int(CivilizationSystem.captured_player_scouts.get(civ_id,{}).get("count",0))>0:out.append("captives")
	if float(relation.get("opinion",0))>=0 and float(civ.get("food_days",30))>=22:out.append("invitation")
	if not previous(civ_id,day).is_empty():out.append("return")
	return out

static func generate(civ_id:String,occasion:Dictionary,day:int,forced:String="")->Dictionary:
	var available:=eligible(civ_id,day)
	if available.is_empty() or (forced!="" and not forced in available):return {}
	var rng:=Hall._rng("personal:"+civ_id+":"+str(Hall.state().serial),day)
	var recent:Array=[]
	for old:Dictionary in Hall.state().history:
		if handles(old):recent.append(String(old.situation.visit.case))
		if recent.size()>=3:break
	var fresh:Array[String]=[]
	for kind in available:
		if not kind in recent:fresh.append(kind)
	if not fresh.is_empty():available=fresh
	var kind:=forced if forced!="" else available[rng.randi_range(0,available.size()-1)]
	var civ:=ForeignDiplomacy.civilization(civ_id)
	var a:=Hall._new_audience("foreign","request",day)
	a.civ_id=civ_id;a.civ_name=String(civ.get("name",civ_id))
	var serial:=absi(hash(String(a.id)+civ_id))%90000+10000
	var name:=String(Names.make(int(GameState.world_seed),serial,serial%2==0,civ_id,{}).get("name","A traveller"))
	var other:=String(Names.make(int(GameState.world_seed),serial+1,serial%2!=0,civ_id,{name:true}).get("name","their companion"))
	a.speaker={"name":name,"title":String(TITLES[kind]),"person_id":0,"role":"visitor"}
	var visit:={"case":kind,"name":name,"other":other,"food":clampf(roundf(Hall._player_population()*0.04),4,20),"people":0,"heard":false}
	var opening:="";var detail:=""
	match kind:
		"hunt":
			opening="Your hunters took the animal we were following. I want our share, and I want you to hear how it happened."
			detail="%s says their party wounded the animal first. Your hunters say they found it already dying. Neither party claims the other struck a person. The claim concerns %d Food already counted in your stores." % [name,int(visit.food)]
		"craft":
			visit.craft=craft(civ_id);visit.people=1
			opening="I know %s. Give me a place beside your fire and I will show your people. My old household wants me back." % String(visit.craft.name).to_lower()
			detail="One adult asks to settle voluntarily. Their former household objects to losing a skilled worker. Welcoming them adds a practice to your study collection; your people must still study and adopt it."
		"lovers":
			visit.people=2
			opening="%s and I chose each other. Our families will not let us live together. Will you give us somewhere to stay?" % other
			detail="Both visitors are adults and both ask to stay. They are still counted among %s until you admit them. A reconciliation offering may ease their families' objection; refusal leaves them free to go, not prisoners." % String(a.civ_name)
		"traveller":
			visit.target=civ_id
			opening="I know the way to %s. Send people with me and they can see the country for themselves." % String(a.civ_name)
			detail="This is an offer to guide a real scouting expedition to a known contact. The journey uses your existing scouts, provisions and travel rules. No ground or deposits become known until they are actually observed."
		"families":
			visit.people=clampi(floori(Hall._player_population()*0.025),3,6)
			opening="There are %d of us. We can work, but we cannot keep living as we are. May we make our home here?" % int(visit.people)
			var reason:="food is short" if float(civ.get("food_days",30))<22 else ("sickness is widespread" if float(civ.get("health",0.8))<0.55 else "families have been displaced")
			detail="In %s, %s. Your headman counts %d spare places under shelter. The newcomers would need food and homes and would join the ordinary population and work allocations." % [String(a.civ_name),reason,maxi(0,int(GameState.housing_capacity)-int(GameState.population_total))]
		"captives":
			visit.count=int(CivilizationSystem.captured_player_scouts[civ_id].count)
			visit.captured_day=int(CivilizationSystem.captured_player_scouts[civ_id].get("captured_day",0))
			opening="I have brought your %d missing scouts to the meeting place. Their guards want food before they let them go." % int(visit.count)
			detail="The captive register confirms these scouts are alive and held by %s. The visitor calls this a rescue; the scouts say the visitor also dealt with their captors. Hearing them establishes that disagreement, not guilt. Returning scouts were already in your population and are not counted twice." % String(a.civ_name)
		"invitation":
			visit.chance=clampf(0.45+float(GameState.simulation_metrics.get("cohesion",0.5))*0.3,0.45,0.75)
			opening="Come to our gathering. Bring a song, send two people to the contests, or simply share food with us."
			detail="Two delegates can go for fourteen days. A contest has about a %d%% chance of success, based on your people's cohesion. Success brings up to %d Food from the host's actual stores; a loss costs no lives. An offering without competitors is also welcome." % [roundi(float(visit.chance)*100),int(visit.food)]
		"return":
			var old:=previous(civ_id,day)
			visit.previous_id=String(old.id);visit.previous_outcome=String(old.outcome);visit.previous_option=String(old.option_id)
			name=String(old.speaker.name);visit.name=name;a.speaker.name=name
			opening={"share":"You shared the catch with us. I wanted you to know I remember.","back":"You stood by your hunters last time. I remember that answer. Will you hear me now?","welcome":"You gave us a home. I wanted to stand before you again.","reconcile":"You made room for us and tried to mend things with our families. I have not forgotten.","explore":"You sent scouts along the way I described. Do you remember me?","ransom":"You paid to bring your scouts home. I came back to thank you.","compete":"You sent two people to our gathering. I wondered if you would remember me.","offering":"Your food reached our gathering. We remembered who sent it."}.get(String(old.option_id),"You heard me before and sent me away. Do you remember what I asked?")
			detail="%s returns to speak about your recorded decision: %s" % [name,String(old.outcome)]
	visit.opening=opening;visit.detail=detail
	a.situation={"type":"early_visit","headline":String(TITLES[kind]).to_lower(),"summary":opening,"ask":"personal:"+kind+":"+str(day/365),"visit":visit,"occasion":occasion.duplicate(true)}
	# The visitor's allegation is distinct from the fixed witness finding.
	# No reread or reload rerolls the finding or the invitation outcome.
	a.hidden={"early":{"witness_roll":rng.randf(),"contest_roll":rng.randf()}}
	return a

static func options(a:Dictionary)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	if not handles(a) or String(a.get("status",""))!="waiting":return out
	var p:Dictionary=a.situation.visit
	if not bool(p.heard):out.append(Hall._option("hear","Hear the people involved","Hear their account before deciding. This does not settle the visit.","neutral"))
	var food:=float(p.food);var enough:=Hall.player_stock("Food")>=food and Society.owner_state(String(a.civ_id))!=null
	var kind:=String(p.case)
	match kind:
		"hunt":
			out.append(Hall._option("share","Share the disputed catch","Give %d Food from your stores as compensation; ease the quarrel." % int(food),"warm",enough,"Your stores cannot cover the share."))
			out.append(Hall._option("back","Back your hunters","Keep the food; the other party carries its grievance home.","hostile"))
		"craft","lovers","families":
			var source:=Society.owner_state(String(a.civ_id))
			var can:=source!=null and float(source.population_exact)>=float(p.people)+20.0
			if kind!="families":can=can and available_adults(source)>=int(p.people)
			if kind=="craft":can=can and not craft(String(a.civ_id),String(p.craft.id)).is_empty() and Society.data().collections.size()<Society.COLLECTION_LIMIT
			out.append(Hall._option("welcome","Let them make a home here","Admit %d people and give them %d Food to start. Their former community loses the same people." % [int(p.people),int(food)],"warm",enough and can,"There are not enough supplies or people available to make this move."))
			if kind in ["craft","lovers"]:
				out.append(Hall._option("reconcile","Welcome them and reconcile the families","Admit them; give %d Food for their start and %d Food to their former household. Ease the dispute." % [int(food),int(food)],"warm",Hall.player_stock("Food")>=food*2 and can,"The two offerings cannot be met."))
		"traveller":
			var proposal:Dictionary=CivilizationSystem.contact_investigation_proposal(String(p.target))
			out.append(Hall._option("explore","Send scouts with the guide",String(proposal.get("message","A scouting expedition follows the usual travel and supply rules.")),"warm",bool(proposal.get("ok",false)),String(proposal.get("error","No scouting expedition can leave now."))))
		"captives":
			var held:Dictionary=CivilizationSystem.captured_player_scouts.get(String(a.civ_id),{})
			var present:=int(held.get("count",0))>=int(p.count) and int(held.get("captured_day",0))==int(p.captured_day)
			out.append(Hall._option("ransom","Pay for their freedom","Transfer %d Food and release the %d scouts from captivity." % [int(food),int(p.count)],"warm",enough and present,"The food or this captive group is no longer available."))
		"invitation":
			var free:=float(GameState.able_population())-float(MilitaryCampaign._mobilized_count())-float(CivilizationSystem.mission_absent_personnel())-preload("res://scripts/lent_hands.gd").away(int(GameState.elapsed_days))
			out.append(Hall._option("compete","Send two people to the contests","Give %d Food; two workers are away for 14 days. About %d%% chance of winning up to %d Food." % [int(food),roundi(float(p.chance)*100),int(food)],"warm",enough and free>=2 and jobs().size()<8 and preload("res://scripts/envoy_requests.gd").store().lent.size()<preload("res://scripts/envoy_requests.gd").LENT_MAX,"Two free adults, provisions and room for a journey are needed."))
			out.append(Hall._option("offering","Send food for the gathering","Give %d Food to the hosts; strengthen friendship without taking workers away." % int(food),"warm",enough,"There is not enough food for the offering."))
		"return":
			out.append(Hall._option("remember","Hear what your answer meant","Acknowledge this person's account; strengthen trust without granting goods or people again.","warm"))
	out.append(Hall._option("decline","Let them leave peacefully","No payment or new commitment. This personal visit creates no automatic diplomatic demand.","neutral"))
	return out

static func jobs()->Array:
	var s:=Hall.state()
	if not s.get("personal_journeys") is Array:s.personal_journeys=[]
	return s.personal_journeys

static func hear(a:Dictionary)->Dictionary:
	var p:Dictionary=a.situation.visit
	var text:=String(p.detail)
	if String(p.case)=="hunt":
		var first:=float(a.get("hidden",{}).get("early",{}).get("witness_roll",0.5))<0.5
		text+=" A witness saw the visiting hunters wound it first." if first else " A witness saw your hunters make the first wound; the visitor had been following its tracks."
		p["finding"]="visitor_first" if first else "ours_first"
	p.heard=true;p["heard_account"]=text
	Hall.append_line(String(a.id),{"speaker":"","role":"narrator","text":text,"day":int(GameState.elapsed_days),"aside":false})
	return {"ok":true,"keep_open":true,"outcome":text,"reaction":"neutral"}

static func migrate(civ_id:String,count:int,adults:bool)->int:
	var source:=Society.owner_state(civ_id)
	if source==null or float(source.population_exact)<count+20:return 0
	if adults and available_adults(source)<count:return 0
	var weights:={"children":0.0 if adults else 1.0,"youth":0.0 if adults else 1.0,"early_adults":1.0,"established_adults":1.0,"mature_adults":1.0,"elders":0.0 if adults else 1.0}
	var departure:Dictionary=WorldSimulation.scoped(Society.owner_id(civ_id),func()->Dictionary:
		var result:Dictionary=WorldSimulation.state.register_population_departures(count,"Voluntary settlement after a personal audience",weights)
		result["cohorts"]=WorldSimulation.state.last_population_removal_by_cohort.duplicate()
		return result)
	var moved:=int(departure.get("count",0))
	if moved<=0:return 0
	GameState.register_population_arrivals(moved,"New households from "+Hall._civ_name(civ_id),departure.cohorts)
	var merged:=false
	for group:Dictionary in Society.data().integration:
		if group.origin==civ_id:group.count+=moved;group.remaining+=moved;merged=true;break
	if not merged:Society.data().integration.append({"origin":civ_id,"count":float(moved),"remaining":float(moved)})
	Society.connection(civ_id).arrivals+=moved
	return moved

static func teaching(civ_id:String,p:Dictionary)->void:
	var c:Dictionary=p.craft
	var key:="visitor:"+civ_id+":"+String(c.id)
	var item:={"id":key,"kind":"knowledge","name":"A newcomer teaches "+String(c.name),"source_id":civ_id,"source_name":Hall._civ_name(civ_id),"position":{"x":CivilizationSystem.player_world_origin.x,"z":CivilizationSystem.player_world_origin.y},"observed_day":int(GameState.elapsed_days),"returned_day":int(GameState.elapsed_days),"discovery_id":String(c.id),"study":0.0,"work":90.0,"signals":c.signals.duplicate(),"acquisition":"Taught by "+String(p.name)+", who settled here"}
	Society.data().collections[key]=item

static func resolve(a:Dictionary,option:String)->Dictionary:
	if option=="hear":return hear(a)
	var p:Dictionary=a.situation.visit
	var civ_id:=String(a.civ_id);var food:=float(p.food);var day:=int(GameState.elapsed_days)
	var outcome:="";var reaction:="neutral"
	match option:
		"share":
			var paid:=Hall._debit_player("Food",food);Exchange.receive(civ_id,"Food",paid)
			Hall._shift_relation(civ_id,0.04,-0.05)
			outcome="%s's hunting party received %d Food from your stores. Both parties retain their accounts; you settled the share without declaring either a criminal." % [String(p.name),roundi(paid)]
		"back":
			Hall._shift_relation(civ_id,-0.04,0.04)
			outcome="You backed your hunters and kept the food. %s left with the grievance unresolved." % String(p.name)
		"welcome","reconcile":
			if String(p.case)=="craft" and (craft(civ_id,String(p.craft.id)).is_empty() or Society.data().collections.size()>=Society.COLLECTION_LIMIT):return {"error":"That practice is already known or your study collection has no room. No one has moved."}
			var moved:=migrate(civ_id,int(p.people),String(p.case)!="families")
			if moved<=0:return {"error":"This household can no longer make the move. Nothing was spent."}
			var spent:=Hall._debit_player("Food",food)
			var compensation:=0.0
			if option=="reconcile":compensation=Hall._debit_player("Food",food);Exchange.receive(civ_id,"Food",compensation)
			var contested:=String(p.case) in ["craft","lovers"]
			Hall._shift_relation(civ_id,0.04 if option=="reconcile" or not contested else -0.03,-0.03 if option=="reconcile" else (0.03 if contested else 0.0))
			p["settled"]=moved
			if String(p.case)=="craft":teaching(civ_id,p)
			outcome="%s and their household settled here: %d people moved from %s into your population, with %d Food issued for their start." % [String(p.name),moved,String(a.civ_name),roundi(spent)]
			if moved==1:outcome="%s settled here: one adult moved from %s into your population, with %d Food issued for their start." % [String(p.name),String(a.civ_name),roundi(spent)]
			if compensation>0:outcome+=" Their former household received %d Food; the dispute eased." % roundi(compensation)
			elif contested:outcome+=" Their former household still objects."
			if String(p.case)=="craft":outcome+=" Their teaching is in your study collection; it does not instantly unlock the craft."
			reaction="pleased"
		"explore":
			var sent:Dictionary=CivilizationSystem.investigate_known_contact(String(p.target))
			if sent.has("error"):return {"error":String(sent.error)}
			outcome=String(sent.get("message","Your scouts set out with the guide."))
		"ransom":
			var paid:=Hall._debit_player("Food",food);Exchange.receive(civ_id,"Food",paid)
			preload("res://scripts/envoy_requests.gd")._release_ours(civ_id,int(p.count))
			Hall._shift_relation(civ_id,0.01,-0.03)
			outcome="%d Food paid; %d scouts released from the captive register. They were already counted in your population. The visitor's part in their capture remains disputed." % [roundi(paid),int(p.count)]
		"compete":
			var paid:=Hall._debit_player("Food",food);Exchange.receive(civ_id,"Food",paid)
			preload("res://scripts/envoy_requests.gd")._lend(2,14,"delegates at the gathering of "+String(a.civ_name))
			jobs().append({"audience":String(a.id),"civ":civ_id,"name":String(p.name),"due":day+14,"chance":float(p.chance),"roll":float(a.hidden.early.contest_roll),"prize":food})
			outcome="Two delegates set out for fourteen days; %d Food went to their hosts. Their contest has about a %d%% chance of success, based on cohesion. The result will be reported when they return." % [roundi(paid),roundi(float(p.chance)*100)]
			Hall._shift_relation(civ_id,0.03,-0.02)
		"offering":
			var paid:=Hall._debit_player("Food",food);Exchange.receive(civ_id,"Food",paid)
			Hall._shift_relation(civ_id,0.04,-0.02)
			outcome="Your people sent %d Food for the gathering. No workers left; the shared offering strengthened friendship." % roundi(paid)
		"remember":
			Hall._shift_relation(civ_id,0.02,0.0)
			outcome="You heard %s's account of your earlier decision. No goods or people were granted a second time. Their people remember that you listened." % String(p.name)
		"decline":outcome="%s left peacefully. No goods changed hands and no people were admitted." % String(p.name)
		_:return {"error":"That answer is not available."}
	if String(p.case)=="return":
		var old:=Hall.find(String(p.previous_id))
		if not old.is_empty():old["return_used"]=true
	ForeignDiplomacy.remember(civ_id,outcome)
	a.status="resolved";a.outcome=outcome;a.option_id=option
	Hall._archive(a);Hall._ledger_close(a,option,reaction,outcome)
	return {"ok":true,"outcome":outcome,"reaction":reaction}

static func daily(day:int)->void:
	for job:Dictionary in jobs().duplicate():
		if int(job.due)>day:continue
		var won:=float(job.roll)<float(job.chance)
		var brought:=Exchange.take(String(job.civ),"Food",float(job.prize)) if won else 0.0
		if brought>0:Exchange.receive("player","Food",brought)
		var text:="Your two delegates returned from %s's gathering. " % Hall._civ_name(String(job.civ))
		text+="They won the contest and brought %d Food from the hosts' stores." % roundi(brought) if won else "They lost the contest, but returned unharmed."
		text+=" Chance %d%%; recorded roll %.3f." % [roundi(float(job.chance)*100),float(job.roll)]
		GameState.simulation_events.push_front({"day":day,"title":"HOME FROM THE GATHERING","description":text,"domain":"society","severity":"notice"})
		if GameState.simulation_events.size()>80: GameState.simulation_events.resize(80)
		var audience:=Hall.find(String(job.audience))
		if not audience.is_empty():audience.situation.visit["journey_result"]=text
		ForeignDiplomacy.remember(String(job.civ),text)
		jobs().erase(job)

static func typed_choice(a:Dictionary,text:String)->Dictionary:
	if not handles(a) or String(a.get("status",""))!="waiting":return {}
	var clean:=text.strip_edges().to_lower().trim_suffix(".").trim_suffix("!")
	var aliases:={"hear":["hear them","hear both sides","hear the witnesses","what happened?","tell me more","hear the people involved"],"share":["share the catch","share the disputed catch","compensate them"],"back":["back our hunters","back your hunters"],"welcome":["let them stay","welcome them","let them make a home here"],"reconcile":["welcome them and reconcile the families","reconcile the families"],"explore":["send scouts with the guide","send the scouts"],"ransom":["pay for their freedom","pay the ransom"],"compete":["send two people to the contests","send the delegates"],"offering":["send food for the gathering"],"remember":["hear what your answer meant","i remember you"],"decline":["let them leave peacefully","decline","no thank you"]}
	for o:Dictionary in options(a):
		if bool(o.enabled) and clean in aliases.get(String(o.id),[]):return {"option":String(o.id)}
	return {}

static func voice_facts(a:Dictionary)->Dictionary:
	var p:Dictionary=a.situation.visit
	return {"identity":"A private visitor speaking for themselves, not an envoy of their ruler.","opening":String(p.opening),"account":String(p.get("heard_account",p.detail)),"previous":String(p.get("previous_outcome","")),"choices":options(a),"rule":"Allegations are claims, not proven guilt. Do not invent threats, deeds, promises or outcomes. Only an engine result settles the visit."}

static func valid_jobs(value:Variant)->bool:
	if not value is Array or value.size()>8:return false
	for j in value:
		if not j is Dictionary or not j.has_all(["audience","civ","name","due","chance","roll","prize"]):return false
		for key in ["audience","civ","name"]:
			if not j[key] is String or String(j[key]).length()>120:return false
		for key in ["due","chance","roll","prize"]:
			if not Hall._num(j[key]) or float(j[key])<0:return false
		if float(j.chance)>1 or float(j.roll)>1:return false
	return true

static func valid(a:Dictionary)->bool:
	var p:Variant=a.get("situation",{}).get("visit")
	if not p is Dictionary or not p.has_all(["case","name","other","food","people","heard","opening","detail"]):return false
	if not p.case in CASES or not p.heard is bool:return false
	for key in ["name","other","opening","detail"]:
		if not p[key] is String or String(p[key]).length()>2000:return false
	for key in ["food","people"]:
		if not Hall._num(p[key]) or float(p[key])<0 or float(p[key])>20:return false
	var rolls:Variant=a.get("hidden",{}).get("early") if a.get("hidden",{}) is Dictionary else null
	if not rolls is Dictionary:return false
	for key in ["witness_roll","contest_roll"]:
		if not Hall._num(rolls.get(key)) or float(rolls[key])<0 or float(rolls[key])>1:return false
	match String(p.case):
		"craft":
			if not p.get("craft") is Dictionary or not p.craft.get("id") is String or not p.craft.get("name") is String or not p.craft.get("signals") is Array:return false
			if not Society.OBJECTS.has(p.craft.id) or int(p.people)!=1:return false
		"lovers":
			if int(p.people)!=2:return false
		"families":
			if float(p.people)<3 or float(p.people)>6:return false
		"traveller":
			if not p.get("target") is String or p.target!=a.civ_id:return false
		"captives":
			if not Hall._num(p.get("count")) or float(p.count)<1 or not Hall._num(p.get("captured_day")):return false
		"invitation":
			if not Hall._num(p.get("chance")) or float(p.chance)<0 or float(p.chance)>1:return false
		"return":
			for key in ["previous_id","previous_outcome","previous_option"]:
				if not p.get(key) is String:return false
	return true

static func parting(a:Dictionary)->String:
	match String(a.get("option_id","")):
		"share":return "I will take this food home. We can leave the quarrel here."
		"back":return "Then I have heard your answer. I still dispute your hunters' account."
		"welcome":return "We will make our home here. Show us where to begin."
		"reconcile":return "Thank you for making room for us, and for trying to mend things with home."
		"explore":return "Your scouts are ready. I will show them the way."
		"ransom":return "Your people are free to come home. Let them tell you what they saw."
		"compete":return "Our fires will be ready for your two competitors."
		"offering":return "I will take your food to the gathering and tell them who sent it."
		"remember":return "You remembered. That was what I came to find out."
	return "I understand. I will be on my way."

extends Node
## Headless probe for the Audience Hall engine: event-driven pacing over three
## simulated years, no repeated asks, continuity between audiences, variety of
## situations grounded in real mechanics, physical transfers, disabled options,
## expiry penalties, legacy-save calming and save compatibility.
const HALL=preload("res://scripts/audience_hall.gd")
const ART=preload("res://scripts/artifact_collection.gd")
const LIC=preload("res://scripts/research_licenses.gd")
const SV=preload("res://scripts/scholar_visits.gd")
const RP=preload("res://scripts/research_purchase.gd")
const SE=preload("res://scripts/society_exchange.gd")
const SEED:=313131
const YEARS:=3
var failures:Array[String]=[]

func check(ok:bool,message:String)->void:
	if not ok: failures.append(message); push_error(message)

func _civ(id:String,name:String,population:int,food_days:float,strategy:String,aggression:float,opinion:float,tension:float,position:Vector2)->Dictionary:
	return {"id":id,"name":name,"alive":true,"population":population,"food_days":food_days,"strategy":strategy,"aggression":aggression,"world_position":position,"position":position,"strategic_regions":[],"relations":{},
		"player_relation":{"opinion":opinion,"border_tension":tension,"at_war":false,"treaty":"none","stance":"watchful","contact_level":2,"contact_intelligence":0.1,"met_day":0,"home_location_known":true,"home_position":{"x":position.x,"z":position.y}}}

func _stock_actor(id:String,food:float,timber:float)->void:
	WorldSimulation.create_actor(id,SEED,Vector2(30,0)); WorldSimulation.actors[id].controller="manual"
	WorldSimulation.scoped(id,func()->void:
		WorldSimulation.state.ensure_population_total(180); WorldSimulation.state.settlement_site_committed=true
		WorldSimulation.food.receive_external_food(food)
		for resource in ["Timber","Stone","Clay","Fiber Plants"]: WorldSimulation.state.resource_stockpiles[resource]=timber)

func _refill()->void:
	var have:=WorldSimulation.food.total_stored()
	if have<4000: FoodSystem.receive_external_food(4000-have)
	for resource in ["Timber","Stone","Clay","Fiber Plants"]: GameState.resource_stockpiles[resource]=maxf(300.0,float(GameState.resource_stockpiles.get(resource,0)))

func _civ_ref(id:String)->Dictionary:
	for civ in CivilizationSystem.civilizations:
		if String(civ.id)==id: return civ
	return {}

func _base()->void:
	WorldSimulation.clear()
	GameState.set_process(false); CivilizationSystem.set_process(false); MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(SEED); GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world(); FoodSystem.reset_for_new_world(); MilitaryCampaign.reset_for_new_world()

func _people(population:int=200)->void:
	GameState.ensure_population_total(population); GameState.housing_capacity=int(population*1.3)
	GameState.society_capacities["institutions"]=0.4
	GameState.settlement_site_committed=true; GameState.settlement_completed=["Hearth Circle"]; SettlementModel.ensure_founded()
	GameState.population_health=0.9; GameState.simulation_metrics.merge({"food_days":60.0,"food_intake_ratio":1.0,"security":0.6,"cohesion":0.7},true)
	GovernmentPeopleSystem.initialize()

func _setup()->void:
	## Three hand-made neighbors with real ledgers (transfer and petition tests).
	_base()
	CivilizationSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world(); GovernmentPeopleSystem.reset_for_new_world()
	_people()
	_refill()
	_stock_actor("rival_a",3000,400); _stock_actor("rival_b",2000,250); _stock_actor("rival_c",800,80)
	CivilizationSystem.civilizations.clear()
	CivilizationSystem.civilizations.append(_civ("rival_a","Kel Adun",260,70,"commerce",0.2,0.35,0.1,Vector2(30,0)))
	CivilizationSystem.civilizations.append(_civ("rival_b","Varrow",420,18,"fortification",0.8,-0.3,0.65,Vector2(0,30)))
	CivilizationSystem.civilizations.append(_civ("rival_c","Isle of Mora",150,9,"expansion",0.4,0.0,0.3,Vector2(-30,0)))
	var war:={"opinion":-0.6,"at_war":true,"border_tension":0.8,"treaty":"war"}
	_civ_ref("rival_b").relations["rival_c"]=war.duplicate(); _civ_ref("rival_c").relations["rival_b"]=war.duplicate()
	var calm:={"opinion":0.1,"at_war":false,"border_tension":0.2,"treaty":"none"}
	for pair in [["rival_a","rival_b"],["rival_a","rival_c"]]:
		_civ_ref(pair[0]).relations[pair[1]]=calm.duplicate(); _civ_ref(pair[1]).relations[pair[0]]=calm.duplicate()
	GameState.elapsed_days=1

func _setup_world()->void:
	## Ten real generated civilizations, all in direct contact, each with a
	## simulated ledger, and a court of at least five officials.
	_base()
	GameState.opponent_count=10
	CivilizationSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world(); GovernmentPeopleSystem.reset_for_new_world()
	_people(2400)
	_refill()
	var index:=0
	for civ in CivilizationSystem.civilizations:
		var relation:Dictionary=civ.player_relation
		relation.contact_level=2; relation.home_location_known=true; relation.met_day=0
		var world:Vector2=civ.get("world_position",Vector2(30*index,0))
		relation.home_position={"x":world.x,"z":world.y}
		relation.opinion=[-0.3,-0.1,0.0,0.1,0.2,0.3,0.35,-0.2,0.15,0.05][index%10]
		relation.border_tension=[0.5,0.3,0.2,0.1,0.15,0.1,0.05,0.4,0.2,0.25][index%10]
		civ.food_days=45.0
		for other in civ.relations: civ.relations[other].at_war=false
		_stock_actor(String(civ.id),2500,300)
		index+=1
	_fill_court()
	GameState.elapsed_days=1

func _fill_court()->void:
	for office in GovernmentPeopleSystem.active_offices():
		if not GovernmentPeopleSystem.officeholder(String(office.key)).is_empty(): continue
		var candidates:=GovernmentPeopleSystem.candidates_for_office(String(office.key))
		if not candidates.is_empty(): GovernmentPeopleSystem.mark_central_appointment(int(candidates[0].person_id),String(office.key))

func _ready()->void:
	_setup_world()
	check(HALL._officials().size()>=5,"The simulated court has fewer than five officials (%d)" % HALL._officials().size())
	var rest_only:="--rest-only" in OS.get_cmdline_user_args()
	var normal:=0 if rest_only else _test_three_years("normal",true)
	if "--pacing-only" in OS.get_cmdline_user_args():
		print("AUDIENCE_HALL "+("PASS (pacing only)" if failures.is_empty() else "FAIL: "+"; ".join(failures)))
		get_tree().quit(0 if failures.is_empty() else 1)
		return
	if not rest_only:
		_setup_world()
		var rare:=_test_three_years("rare",false)
		_setup_world()
		var lively:=_test_three_years("lively",false)
		print("AUDIENCE_HALL frequency over three years: rare %d, normal %d, lively %d" % [rare,normal,lively])
		check(rare<=normal and normal<=lively and rare<normal+lively,"Frequency setting does not order the pace (rare %d, normal %d, lively %d)" % [rare,normal,lively])
	_setup_world()
	_test_situations()
	_setup_world()
	_test_offers_and_artifacts()
	_setup_world()
	_test_famine_episodes()
	_setup_world()
	_test_court_matters()
	_setup_world()
	_test_legacy_calm()
	_setup()
	check(not ForeignDiplomacy.civilization("rival_a").is_empty(),"Contacted civilization not visible")
	_test_transfers()
	_test_petitions()
	_test_reports()
	_test_expiry()
	_test_saves()
	print("AUDIENCE_HALL "+("PASS: rare event-driven audiences, no repeats, continuity, varied real situations, transfers, expiry, legacy calm and saves" if failures.is_empty() else "FAIL: "+"; ".join(failures)))
	get_tree().quit(0 if failures.is_empty() else 1)

# ------------------------------------------------------------------ 3-year sim

func _civ_ids()->Array[String]:
	var ids:Array[String]=[]
	for civ in CivilizationSystem.civilizations: ids.append(String(civ.id))
	return ids

func _set_war(a:String,b:String,on:bool)->void:
	var ca:=_civ_ref(a); var cb:=_civ_ref(b)
	if not ca.relations.has(b): ca.relations[b]={"opinion":0.0,"border_tension":0.2,"treaty":"none"}
	if not cb.relations.has(a): cb.relations[a]={"opinion":0.0,"border_tension":0.2,"treaty":"none"}
	ca.relations[b].at_war=on; cb.relations[a].at_war=on

func _world_events(day:int,ids:Array[String],rng:RandomNumberGenerator)->void:
	## A living world: drift, wars, famines, incidents and crises on a schedule.
	if day%45==0:
		var civ:=_civ_ref(ids[rng.randi_range(0,ids.size()-1)])
		civ.player_relation.opinion=clampf(float(civ.player_relation.opinion)+rng.randf_range(-0.3,0.3),-0.9,0.9)
	match day:
		90: _set_war(ids[2],ids[3],true)
		150:
			_civ_ref(ids[4]).food_days=10.0
			CivilizationSystem.rumor_network.receive(ids[5],CivilizationSystem.rumor_network.observation(ids[5],ids[8],String(_civ_ref(ids[8]).name),Vector2(400,300),200,day,"traveler account"),day)
		260: _civ_ref(ids[4]).food_days=45.0
		300: ForeignDiplomacy.apply_recruitment_incident(ids[5],3,day)
		380:
			var rel:Dictionary=_civ_ref(ids[6]).player_relation
			rel.at_war=true; rel.treaty="war"; rel.war_started_day=day; rel.war_score=0.0; rel.opinion=-0.5
		430:
			var rel2:Dictionary=_civ_ref(ids[6]).player_relation
			rel2.war_score=70.0; rel2.rival_war_exhaustion=0.9; rel2.player_war_exhaustion=0.1
		480: GameState.simulation_metrics["food_days"]=7.0; GameState.simulation_metrics["food_intake_ratio"]=0.8
		540: GameState.simulation_metrics["food_days"]=60.0; GameState.simulation_metrics["food_intake_ratio"]=1.0
		600:
			var holder:=GovernmentPeopleSystem.officeholder("Steward")
			if not holder.is_empty():
				GovernmentPeopleSystem.remove_central_officeholder("Steward","dismiss")
				_fill_court()
		650: _set_war(ids[0],ids[9],true)
		700: GameState.housing_capacity=1700
		760: GameState.housing_capacity=3120
		800: _civ_ref(ids[7]).player_relation.border_tension=0.8
		880: _set_war(ids[2],ids[3],false)
		950: _civ_ref(ids[1]).food_days=9.0
		1000:
			var person:Dictionary=HALL._officials()[1]
			GovernmentPeopleSystem.adjust_person_relationship(int(person.person_id),-0.4,0,0.4)

func _answer(audience:Dictionary,serial:int)->String:
	## A ruler with habits: refuses requests, accepts gifts, alternates on
	## threats and petitions, accepts proposals when possible.
	var ids:Array=[]
	for option in HALL.options(String(audience.id)):
		if bool(option.enabled): ids.append(String(option.id))
	var prefer:Array=[]
	match String(audience.kind):
		"request": prefer=["refuse"]
		"gift": prefer=["accept"]
		"threat": prefer=["pay","defy"] if serial%2==0 else ["defy","pay"]
		"news": prefer=["thank"]
		"proposal": prefer=["accept","stand","restraint","decline"] if serial%3!=0 else ["decline","abstain","defy"]
		"petition": prefer=["promise","decree","apologise","welcome","patience"] if serial%2==0 else ["dismiss","rebuke","decree"]
		"report": prefer=["reward_scouts","dismiss"]
		_: prefer=[]
	for id in prefer:
		if id in ids: return String(id)
	return String(ids[-1]) if not ids.is_empty() else ""

func _test_three_years(level:String,full:bool)->int:
	check(HALL.set_frequency(level),"Unknown frequency "+level)
	var ids:=_civ_ids()
	var rng:=RandomNumberGenerator.new(); rng.seed=SEED
	var arrivals:Array[Dictionary]=[]
	var situations:Dictionary={}
	var branches:Dictionary={}
	var resolved_count:=0
	var continuity:Array[String]=[]
	var sample:Array[String]=[]
	var history_seen:=false
	var court_arrivals:=0
	var matter_types:Dictionary={}
	for day in range(1,YEARS*365+1):
		GameState.elapsed_days=day
		_refill()
		_world_events(day,ids,rng)
		var made:=HALL.daily(day)
		check(made.size()<=1,"More than one arrival in a day")
		for m in HALL.matters(): matter_types[String(m.get("situation_type",m.get("kind","")))]=true
		for audience in made:
			if String(audience.origin)=="court": court_arrivals+=1
			arrivals.append(audience)
			var situation:Dictionary=audience.get("situation",{})
			var type:=String(situation.get("type",audience.kind))
			situations[type]=int(situations.get(type,0))+1
			var arc:Dictionary=situation.get("arc",{})
			if not arc.is_empty():
				branches[String(arc.branch)]=int(branches.get(String(arc.branch),0))+1
				var previous:Dictionary=arc.get("previous",{})
				continuity.append("day %d %s: %s after %s/%s on day %d" % [day,HALL._speaker_key(audience),String(arc.branch),String(previous.get("situation","")),String(previous.get("option",previous.get("decree",""))),int(previous.get("day",0))])
			var ctx:=HALL.voice_context(String(audience.id))
			check(ctx.has("history_with_speaker") and ctx.has("history_with_civ") and ctx.has("situation"),"voice_context lacks history or situation")
			if not (ctx.history_with_speaker as Array).is_empty(): history_seen=true
			if audience.kind=="proposal": check(String(situation.get("summary",""))!="","Proposal without a factual summary")
		for audience in HALL.waiting():
			if day-int(audience.arrived_day)>=3:
				var option:=_answer(audience,resolved_count)
				if option=="": continue
				var result:=HALL.resolve(String(audience.id),option)
				check(bool(result.get("ok",false)),"Enabled option %s failed on %s: %s" % [option,String(audience.get("situation",{}).get("type",audience.kind)),String(result.get("outcome",""))])
				resolved_count+=1
				if sample.size()<40: sample.append("day %4d  %-24s %-20s %-28s -> %s" % [int(audience.arrived_day),HALL._speaker_key(audience),String(audience.get("situation",{}).get("type",audience.kind)),String(HALL._ask_key(audience)).substr(0,28),option])
	# Budget.
	var total:=arrivals.size()
	var per_year:=float(total)/float(YEARS)
	print("AUDIENCE_HALL 3-year sim (%s): %d audiences (%.1f/year, one per %.0f days) across %d civs and %d officials" % [level,total,per_year,float(YEARS*365)/maxf(1.0,float(total)),ids.size(),HALL._officials().size()])
	print("AUDIENCE_HALL court audiences that arrived on their own (%s): %d; matters held meanwhile: %s" % [level,court_arrivals,str(matter_types.keys())])
	check(court_arrivals==0,"The court arrived uninvited %d times (%s)" % [court_arrivals,level])
	check(HALL.waiting().filter(func(a:Dictionary)->bool:return String(a.origin)=="court").is_empty(),"A court audience is waiting uninvited")
	if not full:
		for index in range(1,total): check(int(arrivals[index].arrived_day)-int(arrivals[index-1].arrived_day)>=HALL.MIN_GAP,"Two %s audiences closer than %d days" % [level,HALL.MIN_GAP])
		return total
	print("AUDIENCE_HALL situations: ",situations)
	print("AUDIENCE_HALL arcs: ",branches)
	for line in sample: print("AUDIENCE_HALL   ",line)
	for line in continuity: print("AUDIENCE_HALL continuity ",line)
	# Ten peoples met at once and a crowded schedule of wars, famines and
	# incidents: urgent business still comes, routine envoys stay rare.
	check(total>=3,"Too few audiences in three years (%d)" % total)
	check(total<=int(YEARS*365/120.0),"Too many audiences in three years (%d): stone-age envoys come about once a season at most" % total)
	for index in range(1,total):
		check(int(arrivals[index].arrived_day)-int(arrivals[index-1].arrived_day)>=HALL.MIN_GAP,"Two audiences closer than %d days" % HALL.MIN_GAP)
		check(HALL._speaker_key(arrivals[index])!=HALL._speaker_key(arrivals[index-1]) or String(arrivals[index].get("situation",{}).get("occasion",{}).get("type","")) in HALL.THREAD_OCCASIONS,"Same speaker twice in a row")
	# Per-speaker spacing and no repeats.
	var last_by_speaker:Dictionary={}
	var seen:Dictionary={}
	for audience in arrivals:
		var speaker:=HALL._speaker_key(audience)
		var day:=int(audience.arrived_day)
		var occasion:Dictionary=audience.get("situation",{}).get("occasion",{})
		if last_by_speaker.has(speaker):
			var gap:=day-int(last_by_speaker[speaker])
			var crisis:=bool(occasion.get("crisis",false))
			var thread:=String(occasion.get("type","")) in HALL.THREAD_OCCASIONS
			var floor_gap:=(HALL.CIV_CRISIS_GAP if crisis else HALL.CIV_GAP) if speaker.begins_with("civ:") else (HALL.PERSON_CRISIS_GAP if crisis else (HALL.PERSON_THREAD_GAP if thread else HALL.PERSON_GAP))
			check(gap>=floor_gap,"%s spoke twice within %d days (crisis %s, thread %s)" % [speaker,gap,crisis,thread])
		last_by_speaker[speaker]=day
		var key:="%s|%s|%s" % [speaker,String(audience.kind),HALL._ask_key(audience)]
		if seen.has(key): check(day-int(seen[key])>=HALL.REPEAT_DAYS,"Repeated ask within three years: %s (days %d and %d)" % [key,int(seen[key]),day])
		seen[key]=day
		check(String(occasion.get("type",""))!="","Audience without an occasion: %s" % key)
	check(situations.size()>=4,"Too little variety: %d situation types %s" % [situations.size(),str(situations.keys())])
	check(matter_types.size()>=3,"The court held too few kinds of matters: %s" % str(matter_types.keys()))
	# A refusal brings the same people back, but only after most of a
	# stone-age envoy gap (years), so within three years the sequel may still
	# be waiting its turn.
	var cooler:=int(branches.get("cooler",0))+int(branches.get("threat_after_refusal",0))
	var pending_sequels:=HALL.occasions().filter(func(o:Dictionary)->bool:return String(o.get("type",""))=="sequel").size()
	print("AUDIENCE_HALL sequels still waiting their turn: %d" % pending_sequels)
	check(cooler>=1 or pending_sequels>=1,"No envoy came back (or is due back) after a refusal: %s" % str(branches))
	check(history_seen,"No audience could recall an earlier one with the same speaker")
	return total

# ------------------------------------------------------------------ situations

func _test_situations()->void:
	## Each new situation resolves through its real mechanic.
	GameState.elapsed_days=30
	var ids:=_civ_ids()
	var friend:=ids[5]
	_civ_ref(friend).player_relation.opinion=0.5
	var accord:=HALL.debug_situation("accord_offer",friend)
	check(not accord.is_empty() and accord.kind=="proposal","Accord offer not generated")
	if not accord.is_empty():
		check(HALL.resolve(String(accord.id),"accept").get("ok",false),"Accord accept failed")
		check(not (ForeignDiplomacy.leader(friend).accord as Dictionary).is_empty(),"Accepted accord not active in ForeignDiplomacy")
		check(ForeignDiplomacy.multiplier(String(ForeignDiplomacy.ACCORDS[String(accord.situation.accord)].domain))>1.0,"Accord bonus not applied")
	var pact:=HALL.debug_situation("protection_pact",friend)
	check(not pact.is_empty(),"Protection pact not generated")
	if not pact.is_empty():
		check(HALL.resolve(String(pact.id),"accept").get("ok",false),"Pact accept failed")
		check(ForeignDiplomacy.commitments.state.pacts.has(friend),"Pact not recorded in commitments")
		check(ForeignDiplomacy.commitments.validate(ForeignDiplomacy.commitments.state),"Commitments invalid after pact")
	var other:=ids[4]
	_civ_ref(other).player_relation.opinion=0.5
	var league:=HALL.debug_situation("league_invitation",other)
	check(not league.is_empty(),"League invitation not generated")
	if not league.is_empty():
		check(HALL.resolve(String(league.id),"accept").get("ok",false),"League accept failed")
		check(not ForeignDiplomacy.commitments.faction("player").is_empty(),"Player not in a league after accepting")
		check(ForeignDiplomacy.commitments.validate(ForeignDiplomacy.commitments.state),"Commitments invalid after league")
	var trader:=ids[3]
	_civ_ref(trader).player_relation.opinion=0.3
	var trade:=HALL.debug_situation("trade_offer",trader)
	check(not trade.is_empty(),"Trade offer not generated")
	if not trade.is_empty():
		check(HALL.resolve(String(trade.id),"accept").get("ok",false),"Trade accept failed")
		check(String(_civ_ref(trader).player_relation.treaty)=="trade","Trade compact not opened")
	var calm:=HALL.debug_situation("nonaggression_offer",ids[7])
	check(not calm.is_empty(),"Non-aggression offer not generated")
	if not calm.is_empty():
		check(HALL.resolve(String(calm.id),"accept").get("ok",false),"Non-aggression accept failed")
		check(String(_civ_ref(ids[7]).player_relation.treaty)=="non_aggression","Non-aggression compact not recorded")
	_set_war(ids[0],ids[1],true)
	var side:=HALL.debug_situation("war_support",ids[0],{"enemy":ids[1]})
	check(not side.is_empty(),"War support not generated")
	if not side.is_empty():
		var before:=float(_civ_ref(ids[1]).player_relation.opinion)
		check(HALL.resolve(String(side.id),"stand").get("ok",false),"Standing with an ally failed")
		check(float(_civ_ref(ids[1]).player_relation.opinion)<before,"Their enemy did not resent your choice")
	var rel:Dictionary=_civ_ref(ids[8]).player_relation
	rel.at_war=true; rel.treaty="war"; rel.war_started_day=10; rel.war_score=70.0; rel.rival_war_exhaustion=0.9
	var peace:=HALL.debug_situation("peace_feeler",ids[8])
	check(not peace.is_empty(),"Peace feeler not generated while the enemy would accept")
	if not peace.is_empty():
		var r:=HALL.resolve(String(peace.id),"accept")
		check(r.get("ok",false) and not bool(_civ_ref(ids[8]).player_relation.at_war),"Peace did not end the war: %s" % String(r.get("outcome","")))
	var net=CivilizationSystem.rumor_network
	net.receive(ids[2],net.observation(ids[2],ids[9],String(_civ_ref(ids[9]).name),Vector2(500,200),150,25,"traveler account"),25)
	var rumor:=HALL.debug_situation("rumor_share",ids[2])
	check(not rumor.is_empty(),"Rumor share not generated from a real lead")
	if not rumor.is_empty():
		check(HALL.resolve(String(rumor.id),"thank").get("ok",false),"Rumor thanks failed")
		check((net.books.get("player",{}) as Dictionary).has(String(rumor.situation.lead_id)),"Rumor did not reach the player's book")
	ForeignDiplomacy.apply_recruitment_incident(ids[9],2,28)
	var protest:=HALL.debug_situation("recruitment_protest",ids[9])
	check(not protest.is_empty(),"Recruitment protest not generated after an incident")
	if not protest.is_empty():
		var options:Array=HALL.options(String(protest.id)).map(func(o:Dictionary)->String:return String(o.id))
		check("restraint" in options and "compensate" in options and "defy" in options,"Protest options incomplete: %s" % str(options))
		check(HALL.resolve(String(protest.id),"compensate").get("ok",false),"Compensation failed")
	for type in ["ambition","introduction","promise_followup","war_council","grievance"]:
		if type=="grievance": GovernmentPeopleSystem.adjust_person_relationship(int(HALL._officials()[0].person_id),-0.5,0,0.5)
		var court:=HALL.debug_situation(type,"",{"enemy_name":"Varrow"} if type=="war_council" else {})
		check(not court.is_empty(),"Court situation %s not generated" % type)
		if court.is_empty(): continue
		check(String(court.petition.topic) in HALL.TOPICS,"Court situation has an unknown topic")
		var first:=String(HALL.options(String(court.id))[0].id)
		check(HALL.resolve(String(court.id),first).get("ok",false),"Court situation %s failed to resolve" % type)
	# Research offers stay silent until their real preconditions hold.
	for type in ["scholar_offer","research_sale","license_offer"]:
		check(HALL.debug_situation(type).is_empty(),"%s raised without its preconditions" % type)
	check(HALL.validate_state(JSON.parse_string(JSON.stringify(HALL.state()))),"Hall state with new situations failed validation")

# ------------------------------------------------------------------ research, intel, artifacts, famines

func _ready_subject()->String:
	## An unresolved discovery the player has the foundations for.
	var day:=int(GameState.elapsed_days)
	var ids:Array=DiscoverySystem.catalog_by_id.keys(); ids.sort()
	for id in ids:
		if String(id) in GameState.known_discoveries: continue
		if preload("res://scripts/knowledge_pathways.gd").ready(DiscoverySystem.discovery_definition(String(id)),day): return String(id)
	return ""

func _supplier(id:String,subjects:Array)->void:
	WorldSimulation.scoped(id,func()->void:
		WorldSimulation.state.society_exchange.sharing_policy="open"
		WorldSimulation.state.population_allocations["Knowledge"]=20.0
		WorldSimulation.state.population_allocations["Crafting"]=20.0
		for subject in subjects:
			if not String(subject) in WorldSimulation.state.known_discoveries: WorldSimulation.state.known_discoveries.append(String(subject))
			WorldSimulation.state.discovery_adoption[String(subject)]=0.8)

func _home_view(id:String)->void:
	## A foreign ruler's own world view of the player's people (built by projections in play).
	WorldSimulation.scoped(id,func()->void:
		for civ in WorldSimulation.world.civilizations:
			if String(civ.get("id",""))=="human": return
		WorldSimulation.world.civilizations.append({"id":"human","name":"Home","player_relation":{"at_war":false}}))

func _piece(point:Vector2,rarity:int,source:String)->Dictionary:
	var item:=ART.find_at(777,point,1)
	item.rarity=rarity
	if source!="":
		item.erase("art_collection"); item["artifact_origin"]="civilization"; item.source_id=source; item.source_name="Their workshop"
	return item

func _test_offers_and_artifacts()->void:
	GameState.elapsed_days=40
	var ids:=_civ_ids()
	var types:Dictionary={}
	# Research offers: player prerequisites and a willing supplier.
	GameState.known_discoveries.append_array(["apprentice_contracts","public_schools","experimental_controls","workshop_standards","material_accounting"])
	GameState.population_allocations["Knowledge"]=20.0
	var subject:=_ready_subject()
	var license_subject:=""
	for candidate in LIC.subjects():
		if not LIC.independent(candidate): license_subject=candidate; break
	check(subject!="" and license_subject!="","No research subject available for the offer scenario")
	var supplier:=ids[5]
	_supplier(supplier,[subject,license_subject])
	CivilizationSystem.diplomatic_mission={"civ_id":ids[0],"stage":"outbound","return_day":999}
	for type in ["scholar_offer","research_sale","license_offer"]:
		var offer:=HALL.debug_situation(type,supplier)
		check(not offer.is_empty(),"%s not raised when its preconditions hold (our mission slot is busy)" % type)
		if offer.is_empty(): continue
		types[type]=true
		var resource:=String(offer.situation.payment); var price:=float(offer.situation.payment_amount)
		var mine:=HALL.player_stock(resource); var theirs:=HALL.foreign_stock(supplier,resource)
		var r:=HALL.resolve(String(offer.id),"accept")
		check(r.get("ok",false),"%s accept failed: %s" % [type,String(r.get("outcome",""))])
		check(is_equal_approx(mine-HALL.player_stock(resource),price) and is_equal_approx(HALL.foreign_stock(supplier,resource)-theirs,price),"%s payment not conserved" % type)
	check((GameState.society_exchange.get("scholar_visits",{}) as Dictionary).size()==1 and SV.valid(GameState.society_exchange.scholar_visits),"Scholar visit not registered validly")
	check(GameState.society_exchange.collections.has(RP.key(supplier,subject)),"Purchased study not in the collection")
	check(LIC.active(license_subject),"Envoy license not active")
	check(SE.valid(GameState.society_exchange),"Society exchange invalid after envoy offers")
	CivilizationSystem.diplomatic_mission={}
	# City intelligence: a neighbor's fresh look at a third people's city.
	var watcher:=ids[3]; var watched:=ids[6]
	var intel=CivilizationSystem.city_intelligence
	var city_id:String=intel.primary_id(watched)
	intel.publish(watcher,intel.capture(watcher,city_id,0.7,38,"traders","probe"),38)
	var share:=HALL.debug_situation("intelligence_share",watcher)
	check(not share.is_empty(),"City intelligence share not raised from a real observation")
	if not share.is_empty():
		types["intelligence_share"]=true
		check(HALL.resolve(String(share.id),"thank").get("ok",false) and not intel.known("player",city_id).is_empty(),"Shared city intelligence did not reach our reports")
	# Artifacts: gift, purchase (sell and trade) and return, through the exchange engine.
	var giver:=ids[4]
	_home_view(giver)
	var gift_piece:=_piece(Vector2(4000,100),1,"")
	WorldSimulation.scoped(giver,func()->void:WorldSimulation.state.society_exchange.collections[gift_piece.id]=gift_piece)
	var gift:=HALL.debug_situation("artifact_gift",giver)
	check(not gift.is_empty(),"Artifact gift not raised")
	if not gift.is_empty():
		types["artifact_gift"]=true
		check(HALL.resolve(String(gift.id),"accept").get("ok",false),"Artifact gift accept failed")
		var held:Dictionary=GameState.society_exchange.collections.get(gift_piece.id,{})
		check(not held.is_empty() and not ART.holdings(giver).has(gift_piece.id),"Gifted artifact did not change hands")
		check(String((held.get("provenance",[{}]) as Array)[-1].get("from",""))==giver,"Gifted artifact has no provenance")
	var buyer:=ids[2]
	_home_view(buyer)
	var ours:=_piece(Vector2(8000,100),3,"")
	GameState.society_exchange.collections[ours.id]=ours
	var theirs_piece:=_piece(Vector2(12000,100),0,"")
	WorldSimulation.scoped(buyer,func()->void:WorldSimulation.state.society_exchange.collections[theirs_piece.id]=theirs_piece)
	GameState.economy_stage="currency"; GameState.public_treasury=100.0; GameState.currency_supply=100.0
	WorldSimulation.scoped(buyer,func()->void:
		WorldSimulation.state.economy_stage="currency"; WorldSimulation.state.public_treasury=100000.0; WorldSimulation.state.currency_supply=100000.0
		WorldSimulation.state.monetary_reserve_metals={"Gold":100000.0})
	var ask:=HALL.debug_situation("artifact_purchase",buyer)
	check(not ask.is_empty(),"Artifact purchase not raised")
	if not ask.is_empty():
		types["artifact_purchase"]=true
		var option_ids:Array=HALL.options(String(ask.id)).filter(func(o:Dictionary)->bool:return bool(o.enabled)).map(func(o:Dictionary)->String:return String(o.id))
		check("sell" in option_ids and "trade" in option_ids,"Purchase offers lack sell or trade: %s" % str(option_ids))
		var money:=GameState.public_treasury+float(E_state(buyer).public_treasury)
		check(HALL.resolve(String(ask.id),"sell").get("ok",false),"Artifact sale failed")
		check(is_equal_approx(money,GameState.public_treasury+float(E_state(buyer).public_treasury)) and GameState.public_treasury>100.0,"Artifact sale did not conserve money")
		check(ART.holdings(buyer).has(ours.id),"Sold artifact did not reach the buyer")
	var maker:=ids[7]
	_home_view(maker)
	var theirs_made:=_piece(Vector2(16000,100),2,maker)
	GameState.society_exchange.collections[theirs_made.id]=theirs_made
	var demand:=HALL.debug_situation("artifact_return",maker)
	check(not demand.is_empty() and String(demand.situation.mode)=="origin","Return demand for a piece of their making not raised")
	if not demand.is_empty():
		types["artifact_return"]=true
		check(HALL.resolve(String(demand.id),"return").get("ok",false) and ART.holdings(maker).has(theirs_made.id),"Returning their piece failed")
	# Looted treasure: our soldiers carried a piece off from their great work.
	var victim:=ids[8]
	var loot:=_piece(Vector2(20000,100),2,"")
	GameState.society_exchange.collections[loot.id]=loot
	var their_city:Dictionary=E_state(victim).player_settlements[0] if not (E_state(victim).player_settlements as Array).is_empty() else {}
	if their_city.is_empty():
		their_city={"id":"victim_city","name":"Their city","undertakings":[]}
		E_state(victim).player_settlements.append(their_city)
	if not their_city.has("undertakings"): their_city["undertakings"]=[]
	(their_city.undertakings as Array).append({"id":"stolen_work","custom_name":"The Singing Gate","status":"functioning","rivalry":{"events":[],"grievances":[],"looted":[{"id":loot.id,"by":"player","day":35,"returned":false}]}})
	var looted:=HALL.debug_situation("artifact_return",victim)
	check(not looted.is_empty() and String(looted.situation.mode)=="looted","Return demand for looted treasure not raised")
	if not looted.is_empty():
		var r2:=HALL.resolve(String(looted.id),"return")
		check(r2.get("ok",false) and ART.holdings(victim).has(loot.id),"Returning looted treasure failed: %s" % String(r2.get("outcome","")))
	check(SE.valid(GameState.society_exchange),"Player collection invalid after artifact exchanges")
	for id in [giver,buyer,maker,victim]: check(SE.valid(E_state(id).society_exchange),"%s collection invalid after artifact exchanges" % id)
	check(HALL.validate_state(JSON.parse_string(JSON.stringify(HALL.state()))),"Hall state invalid after offers and artifacts")
	print("AUDIENCE_HALL targeted offers raised: ",types.keys())
	check(types.size()==7,"Not every offer and artifact situation appeared: %s" % str(types.keys()))

func E_state(id:String)->Node: return SE.owner_state(id)

func _test_famine_episodes()->void:
	## The same people may ask for Food again only for a new famine, and never within a year.
	var ids:=_civ_ids()
	var hungry:=ids[4]
	_civ_ref(hungry).food_days=8.0
	GameState.elapsed_days=100
	var first:=HALL._generate_foreign_occasion({"type":"their_famine","key":"f1","civ_id":hungry,"day":100,"data":{"episode":100}},100)
	check(not first.is_empty() and String(first.terms.resource)=="Food","First famine did not bring a Food request")
	if first.is_empty(): return
	HALL._enqueue(first,100); HALL.resolve(String(first.id),"refuse")
	GameState.elapsed_days=300
	var soon:=HALL._generate_foreign_occasion({"type":"their_famine","key":"f2","civ_id":hungry,"day":300,"data":{"episode":300}},300)
	check(soon.is_empty() or String(soon.terms.get("resource",""))!="Food","A Food request repeated within a year")
	if not soon.is_empty(): HALL._enqueue(soon,300); HALL.resolve(String(soon.id),HALL.options(String(soon.id))[-1].id)
	GameState.elapsed_days=520
	var later:=HALL._generate_foreign_occasion({"type":"their_famine","key":"f3","civ_id":hungry,"day":520,"data":{"episode":520}},520)
	check(not later.is_empty() and String(later.terms.resource)=="Food" and String(later.situation.ask)=="request:Food:famine520","A distinct famine a year later could not ask for Food again")
	var same:=HALL._generate_foreign_occasion({"type":"their_famine","key":"f4","civ_id":hungry,"day":520,"data":{"episode":100}},520)
	check(same.is_empty() or String(same.terms.get("resource",""))!="Food","The same famine episode asked for Food twice")

# ------------------------------------------------------------------ court matters

func _test_court_matters()->void:
	## The court never arrives on its own: its business waits as matters.
	GameState.elapsed_days=5
	for day in range(5,12): HALL.daily(day)
	GameState.simulation_metrics["food_days"]=6.0; GameState.simulation_metrics["food_intake_ratio"]=0.8
	var arrivals:Array=[]
	for day in range(12,40):
		GameState.elapsed_days=day
		arrivals.append_array(HALL.daily(day))
	check(arrivals.filter(func(a:Dictionary)->bool:return String(a.origin)=="court").is_empty(),"A famine brought an official in uninvited")
	var food:=HALL.matters().filter(func(m:Dictionary)->bool:return String(m.situation_type)=="crisis_petition")
	check(not food.is_empty(),"The famine left no matter with the court")
	if food.is_empty(): return
	var matter:Dictionary=food[0]
	var holder:=String(matter.holder_key)
	check(int(HALL.matter_counts().get(holder,0))>=1,"Matter counts do not show the holder")
	var pid:=int(matter.holder.person_id)
	var resent:=float(GovernmentPeopleSystem.person_snapshot(pid).relationships.sovereign.resentment)
	var opened:=HALL.open_matter(String(matter.id))
	check(not opened.is_empty() and String(opened.status)=="waiting" and String(opened.origin)=="court","Opening a matter did not call the official in")
	check(HALL.matters(holder).filter(func(m:Dictionary)->bool:return String(m.id)==String(matter.id)).is_empty(),"An opened matter stayed pending")
	if not opened.is_empty(): check(HALL.resolve(String(opened.id),"decree").get("ok",false),"The summoned official's decree failed")
	# Matters lapse quietly.
	var quiet:=HALL._generate_petition(pid,40,"ambition")
	HALL._file_matter(quiet,[])
	# (A generational aim the court may propose that same day is new business, not an old matter.)
	var not_aim:=func(m:Dictionary)->bool:return String(m.get("situation_type",""))!="aim"
	var before:=HALL.matters("person:%d" % pid).filter(not_aim).size()
	GameState.simulation_metrics["food_days"]=60.0; GameState.simulation_metrics["food_intake_ratio"]=1.0
	GameState.elapsed_days=40+HALL.MATTER_DAYS+1
	HALL.daily(40+HALL.MATTER_DAYS+1)
	check(HALL.matters("person:%d" % pid).filter(not_aim).size()<before,"Old matters never lapsed")
	check(is_equal_approx(float(GovernmentPeopleSystem.person_snapshot(pid).relationships.sovereign.resentment),resent),"A lapsed matter cost the official's goodwill")
	# A version-2 save with a court audience waiting in the antechamber.
	var petition:=HALL._generate_petition(pid,int(GameState.elapsed_days),"ambition")
	var saved:=ForeignDiplomacy.export_state()
	var old:Dictionary=JSON.parse_string(JSON.stringify(saved))
	old.audiences["version"]=2
	(old.audiences.queue as Array).append(JSON.parse_string(JSON.stringify(petition)))
	(old.audiences as Dictionary).erase("matters")
	check(ForeignDiplomacy.import_state(old).get("ok",false),"Version-2 hall state failed to load")
	check(HALL.waiting().filter(func(a:Dictionary)->bool:return String(a.origin)=="court").is_empty(),"A saved court audience still waits after loading")
	check(not HALL.matters("person:%d" % pid).is_empty() and int(HALL.state().version)==HALL.VERSION,"A saved court audience did not become a matter")
	check(HALL.validate_state(JSON.parse_string(JSON.stringify(HALL.state()))),"Hall state with matters failed validation")
# ------------------------------------------------------------------ legacy

func _legacy_audience(id:int,kind:String,civ_id:String,civ_name:String,day:int,terms:Dictionary,petition:Dictionary,person_id:int)->Dictionary:
	return {"id":"aud_%d" % id,"origin":"court" if kind=="petition" else "foreign","kind":kind,"civ_id":civ_id,"civ_name":civ_name,
		"speaker":{"name":"Speaker %d" % id,"title":"Envoy","person_id":person_id,"role":"official" if kind=="petition" else "envoy"},
		"arrived_day":day,"expires_day":day+20,"status":"waiting","terms":terms,"news":{},"petition":petition,"report":{},"lines":[],"outcome":"","option_id":"","mood":0.0}

func _test_legacy_calm()->void:
	## A version-1 hall with a stuffed antechamber and every timer overdue.
	var day:=400
	GameState.elapsed_days=day
	var ids:=_civ_ids()
	var officials:=HALL._officials()
	var pid:=int(officials[0].person_id)
	var ambition:={"topic":"ambition","summary":"Wants a public council.","suggested_decree":"Hold a public council to hear the people"}
	var queue:Array=[
		_legacy_audience(40,"gift",ids[0],"A",day-12,{"resource":"Timber","amount":20.0},{},0),
		_legacy_audience(41,"gift",ids[0],"A",day-9,{"resource":"Timber","amount":20.0},{},0),
		_legacy_audience(42,"petition","","",day-8,{},ambition,pid),
		_legacy_audience(43,"petition","","",day-5,{},ambition,pid),
		_legacy_audience(44,"request",ids[1],"B",day-3,{"resource":"Food","amount":30.0},{},0),
		_legacy_audience(45,"request",ids[2],"C",day-1,{"resource":"Food","amount":30.0},{},0),
	]
	var history:Array=[]
	for index in 6:
		var old:=_legacy_audience(30+index,"petition","","",day-60-index*5,{},ambition,pid)
		old.status="resolved"; old.option_id="promise"
		history.append(old)
	var next_foreign:Dictionary={}
	for id in ids: next_foreign[id]=day-2
	var legacy:={"version":1,"queue":queue,"history":history,"next_foreign":next_foreign,"next_court":{str(pid):day-4},"last_arrival_day":day-1,"serial":50,"summon_immediately":true}
	var saved:=ForeignDiplomacy.export_state()
	saved["audiences"]=legacy
	var roundtrip:Variant=JSON.parse_string(JSON.stringify(saved))
	var opinion_loaded:=float(_civ_ref(ids[0]).player_relation.opinion)
	check(ForeignDiplomacy.import_state(roundtrip).get("ok",false),"Legacy hall state failed to load")
	var waiting:=HALL.waiting()
	check(waiting.size()<=HALL.MIGRATION_KEEP,"Legacy antechamber not calmed: %d still waiting" % waiting.size())
	var speakers:Dictionary={}
	for audience in waiting:
		check(not speakers.has(HALL._speaker_key(audience)),"Legacy duplicates kept for one speaker")
		speakers[HALL._speaker_key(audience)]=true
	check(int(HALL.state().version)==HALL.VERSION and (HALL.state().next_foreign as Dictionary).is_empty(),"Legacy timers not retired")
	check(is_equal_approx(opinion_loaded,float(_civ_ref(ids[0]).player_relation.opinion)),"Withdrawing legacy audiences cost relations")
	var withdrawn:=0
	for audience in HALL.state().history:
		if String(audience.get("option_id",""))=="withdrawn": withdrawn+=1
	check(withdrawn>=2,"Withdrawn legacy audiences not archived (%d)" % withdrawn)
	check(HALL.waiting().filter(func(a:Dictionary)->bool:return String(a.origin)=="court").is_empty(),"Legacy court audiences still wait in the antechamber")
	check(not HALL.matters("person:%d" % pid).is_empty(),"Legacy court audience did not become a matter")
	var arrivals:=0
	for step in range(day,day+45):
		GameState.elapsed_days=step
		arrivals+=HALL.daily(step).size()
	check(arrivals==0,"A calmed legacy hall produced %d arrivals in the next 45 days" % arrivals)
	var ambition_repeat:=HALL._generate_court_occasion({"type":"ambition","person_id":pid,"key":"x","data":{}},day+45)
	check(ambition_repeat.is_empty() or String(ambition_repeat.petition.suggested_decree)!="Hold a public council to hear the people","Legacy ledger did not stop a repeated ambition")
	print("AUDIENCE_HALL legacy calm: kept %d waiting, withdrew %d, next routine day %d (loaded day %d)" % [waiting.size(),withdrawn,int(HALL.state().next_any),day])

# ------------------------------------------------------------------ transfers

func _serial(audience:Dictionary)->int: return int(String(audience.id).trim_prefix("aud_"))

func _foreign_stock(id:String,resource:String)->float: return HALL.foreign_stock(id,resource)

func _opinion(id:String)->float: return float(_civ_ref(id).player_relation.opinion)

func _test_transfers()->void:
	_refill()
	# Gift: goods leave the foreign ledger and arrive in the player's.
	var gift:=HALL.debug_force("gift","rival_a")
	check(not gift.is_empty(),"Gift could not be generated from a stocked neighbor")
	if not gift.is_empty():
		var res:=String(gift.terms.resource); var amount:=float(gift.terms.amount)
		var their_before:=_foreign_stock("rival_a",res); var mine_before:=HALL.player_stock(res); var opinion_before:=_opinion("rival_a")
		var r:=HALL.resolve(gift.id,"accept")
		check(r.get("ok",false) and r.reaction=="pleased","Gift accept failed")
		check(is_equal_approx(their_before-_foreign_stock("rival_a",res),amount),"Gift was not debited from foreign stores (%s %.1f -> %.1f)" % [res,their_before,_foreign_stock("rival_a",res)])
		check(is_equal_approx(HALL.player_stock(res)-mine_before,amount),"Gift did not reach player stores")
		check(_opinion("rival_a")>opinion_before,"Accepting a gift did not warm relations")
		check(HALL.find(gift.id).status=="resolved" and HALL.waiting().is_empty(),"Resolved gift left in the queue")
		check(not HALL.resolve(gift.id,"accept").get("ok",false),"Resolved gift could be accepted twice")
	# No simulated ledger: no gift possible.
	var saved_actor:Dictionary=WorldSimulation.actors["rival_c"]
	WorldSimulation.actors.erase("rival_c")
	check(HALL.debug_force("gift","rival_c").is_empty(),"Gift generated from a polity without stores")
	WorldSimulation.actors["rival_c"]=saved_actor
	# Request: player pays; foreign ledger receives.
	var request:=HALL.debug_force("request","rival_c")
	check(not request.is_empty(),"Request not generated")
	if not request.is_empty():
		var res2:=String(request.terms.resource); var amount2:=float(request.terms.amount)
		var mine:=HALL.player_stock(res2); var theirs:=_foreign_stock("rival_c",res2)
		check(HALL.resolve(request.id,"grant").get("ok",false),"Grant failed")
		check(is_equal_approx(mine-HALL.player_stock(res2),amount2),"Grant did not debit player")
		check(is_equal_approx(_foreign_stock("rival_c",res2)-theirs,amount2),"Grant did not reach the requester")
	# Disabled options when stores are short.
	var short:=HALL.debug_force("request","rival_c")
	if not short.is_empty():
		var res3:=String(short.terms.resource)
		if res3=="Food": FoodSystem.issue_for_obligation(WorldSimulation.food.total_stored()-1.0,"test","drain")
		else: GameState.resource_stockpiles[res3]=1.0
		var grant:={}
		for option in HALL.options(short.id):
			if option.id=="grant": grant=option
		check(not grant.is_empty() and not bool(grant.enabled) and String(grant.reason)!="","Grant stayed enabled with empty stores")
		var before:=HALL.player_stock(res3)
		check(not HALL.resolve(short.id,"grant").get("ok",false) and is_equal_approx(before,HALL.player_stock(res3)),"Disabled grant moved goods")
		check(HALL.resolve(short.id,"refuse").get("ok",false),"Refusal failed")
	_refill()
	# Tribute: player pays under threat; tension falls.
	var threat:=HALL.debug_force("threat","rival_b")
	check(not threat.is_empty(),"Threat not generated")
	if not threat.is_empty():
		var res4:=String(threat.terms.resource); var mine4:=HALL.player_stock(res4)
		var tension:=float(_civ_ref("rival_b").player_relation.border_tension)
		check(HALL.resolve(threat.id,"pay").get("ok",false),"Tribute payment failed")
		check(is_equal_approx(mine4-HALL.player_stock(res4),float(threat.terms.amount)),"Tribute did not debit the player")
		check(float(_civ_ref("rival_b").player_relation.border_tension)<tension,"Tribute did not ease tension")
	var defy:=HALL.debug_force("threat","rival_b")
	if not defy.is_empty():
		var opinion_before:=_opinion("rival_b")
		var r2:=HALL.resolve(defy.id,"defy")
		check(r2.get("ok",false) and r2.reaction in ["offended","furious"] and _opinion("rival_b")<opinion_before,"Defiance had no consequence")
	var counter:=HALL.debug_force("threat","rival_b")
	if not counter.is_empty():
		check(HALL.resolve(counter.id,"counter").get("ok",false),"Counter-threat failed")
	# News is about third parties and is backed by a real fact.
	var news:=HALL.debug_force("news","rival_a")
	check(not news.is_empty() and String(news.news.subject_civ_id)!="rival_a","News not generated about a third party")
	if not news.is_empty():
		check(HALL.resolve(news.id,"reward").get("ok",false),"Rewarding messenger failed")
	# Mood is bounded and only adds a small opinion change.
	var mood_gift:=HALL.debug_force("gift","rival_a")
	if not mood_gift.is_empty():
		for i in 10: HALL.apply_mood(mood_gift.id,5.0)
		check(is_equal_approx(float(HALL.find(mood_gift.id).mood),1.0),"Mood not clamped")
		var before2:=_opinion("rival_a")
		HALL.resolve(mood_gift.id,"accept")
		check(_opinion("rival_a")-before2<=0.04+0.03+0.0001,"Mood exceeded its opinion bound")
	# Voice context carries dated history with this people.
	var talk:=HALL.debug_force("news","rival_a")
	if not talk.is_empty():
		HALL.append_line(talk.id,{"speaker":"Envoy","role":"envoy","text":"Greetings.","civ_id":"rival_a"})
		HALL.append_line(talk.id,{"speaker":"X","role":"hacker","text":""})
		check(HALL.find(talk.id).lines.size()==1,"Line validation failed")
		var ctx:=HALL.voice_context(talk.id)
		check(ctx.has("civ") and ctx.has("leader") and ctx.court is Array and ctx.court.size()<=4,"Voice context incomplete")
		check((ctx.history_with_civ as Array).size()==3 and int(ctx.history_with_civ[0].day)>=0 and String(ctx.history_with_civ[0].answer)!="","Voice context lacks dated history with this people")
		check(HALL.court(talk.id).size()<=4,"Court too large")
		HALL.defer(talk.id)
		check(HALL.find(talk.id).status=="waiting","Deferral resolved the audience")

func _test_petitions()->void:
	GameState.simulation_metrics["food_days"]=6.0; GameState.simulation_metrics["food_intake_ratio"]=0.8
	var petition:=HALL.debug_force("petition","food")
	check(not petition.is_empty() and petition.petition.topic=="food","Food petition not generated under famine")
	if not petition.is_empty():
		var decree:=String(petition.petition.suggested_decree)
		check(PronouncementInterpreter._policy_has_term_in_text("rationing",decree.to_lower()),"Suggested decree not understood by the civic interpreter: "+decree)
		var pid:=int(petition.speaker.person_id)
		var trust_before:=float(GovernmentPeopleSystem.person_snapshot(pid).relationships.sovereign.trust)
		check(HALL.resolve(petition.id,"decree").get("ok",false),"Decree option failed")
		check(float(GovernmentPeopleSystem.person_snapshot(pid).relationships.sovereign.trust)>trust_before,"Taking up a petition did not build trust")
	GameState.population_health=0.4
	var health:=HALL.debug_force("petition","health")
	check(not health.is_empty() and PronouncementInterpreter._policy_has_term_in_text("care_rotation",String(health.petition.suggested_decree).to_lower()),"Health petition decree not understood")
	if not health.is_empty():
		HALL.resolve(health.id,"promise")
		var followups:=HALL.occasions().filter(func(o:Dictionary)->bool:return String(o.type)=="promise_followup")
		check(not followups.is_empty(),"A promise did not leave a follow-up thread")
	GameState.housing_capacity=120
	var housing:=HALL.debug_force("petition","housing")
	check(not housing.is_empty() and PronouncementInterpreter._policy_has_term_in_text("emergency_building",String(housing.petition.suggested_decree).to_lower()),"Housing petition decree not understood")
	if not housing.is_empty():
		var pid2:=int(housing.speaker.person_id)
		var resent:=float(GovernmentPeopleSystem.person_snapshot(pid2).relationships.sovereign.resentment)
		HALL.resolve(housing.id,"dismiss")
		check(float(GovernmentPeopleSystem.person_snapshot(pid2).relationships.sovereign.resentment)>resent,"Dismissal did not cause resentment")
	# Every ambition on every ladder is a decree the civic interpreter understands.
	for office in HALL.AMBITIONS:
		for decree in HALL.AMBITIONS[office]:
			var understood:=false
			for policy in PronouncementInterpreter.POLICY_TERMS:
				if PronouncementInterpreter._policy_has_term_in_text(String(policy),String(decree).to_lower()): understood=true
			check(understood,"Ambition decree not understood: "+String(decree))
	var official:Dictionary=HALL._officials()[0]
	GovernmentPeopleSystem.adjust_person_relationship(int(official.person_id),-0.6,0,0.5)
	var grievance:=HALL._generate_petition(int(official.person_id),int(GameState.elapsed_days),"grievance")
	check(not grievance.is_empty(),"Grievance not available for a resentful official")
	GameState.population_health=0.9; GameState.housing_capacity=260; GameState.simulation_metrics["food_days"]=60.0; GameState.simulation_metrics["food_intake_ratio"]=1.0

func _test_reports()->void:
	_refill()
	for audience in HALL.waiting(): HALL.resolve(audience.id,HALL.options(audience.id)[-1].id)
	var report:=HALL.debug_force("report","rival_b")
	check(not report.is_empty() and report.origin=="court" and report.status=="waiting" and not (report.report.facts as Array).is_empty(),"Report not generated")
	if not report.is_empty():
		var ids:Array=[]
		for option in HALL.options(report.id): ids.append(option.id)
		check("reward_scouts" in ids and "dismiss" in ids,"Report options missing: %s" % str(ids))
		check(HALL.voice_context(report.id).report.subject_civ_id=="rival_b","Report facts missing from voice context")
		var food:=HALL.player_stock("Food")
		check(HALL.resolve(report.id,"reward_scouts").get("ok",false),"Rewarding scouts failed")
		check(food-HALL.player_stock("Food")>=5.0-0.001,"Scout reward did not use real Food")
	check(HALL.enqueue({"kind":"report","speaker":{"name":""},"report":{"facts":[]}}).is_empty(),"Report without a speaker accepted")
	check(HALL.enqueue({"kind":"report","speaker":{"name":"Scout"},"report":{"facts":[42]}}).is_empty(),"Report with malformed facts accepted")
	check(HALL.enqueue({"kind":"bribe","speaker":{"name":"Scout"}}).is_empty(),"Unknown kind accepted")
	check(HALL.enqueue({"kind":"proposal","origin":"foreign","speaker":{"name":"X"},"civ_id":"rival_a"}).is_empty(),"Proposal without a situation accepted")
	# A full antechamber still hears the scouts; the oldest petition steps aside.
	var petitions:Array=[]
	for topic in ["ambition","ambition","ambition","ambition"]:
		var officials:=HALL._officials()
		var p:=HALL._generate_petition(int(officials[petitions.size()%officials.size()].person_id),int(GameState.elapsed_days),topic)
		if not p.is_empty(): HALL._enqueue(p,int(GameState.elapsed_days)); petitions.append(p)
	check(HALL.waiting().size()>=4,"Could not fill the antechamber")
	var uninvited:=HALL.enqueue({"kind":"report","origin":"court","speaker":{"name":"Tamsin Reed","title":"Pathfinder","person_id":0},"report":{"facts":["a far camp"],"subject_civ_id":"rival_b","subject_name":"Varrow","source":"scouts","observed_day":1}})
	check(uninvited.is_empty() and not HALL.matters("role:chief_scout").is_empty(),"A scout report came in uninvited instead of waiting as a matter")
	var full_report:=HALL.enqueue({"kind":"report","origin":"court","summoned":true,"speaker":{"name":"Tamsin Reed","title":"Pathfinder","person_id":0},"report":{"facts":["smoke from many hearths","a stone wall"],"subject_civ_id":"rival_a","subject_name":"Kel Adun","source":"scouts","observed_day":1}})
	check(not full_report.is_empty() and HALL.find(petitions[0].id).status=="expired","Report did not displace the oldest petition")
	check(HALL.waiting().size()<=4,"Antechamber overflowed")
	check(not HALL.room_for("routine") and not HALL.room_for("urgent"),"A full antechamber still offered room")
	for audience in HALL.waiting(): HALL.resolve(audience.id,HALL.options(audience.id)[-1].id)

func _test_expiry()->void:
	for audience in HALL.waiting(): HALL.resolve(audience.id,HALL.options(audience.id)[0].id)
	var day:=int(GameState.elapsed_days)
	var news:=HALL.debug_force("news","rival_a")
	var petition:=HALL.debug_force("petition","ambition")
	check(not news.is_empty() and not petition.is_empty(),"Expiry fixtures not generated")
	if news.is_empty() or petition.is_empty(): return
	var opinion:=_opinion("rival_a"); var trust:=float(ForeignDiplomacy.leader("rival_a").trust)
	var pid:=int(petition.speaker.person_id)
	var resent:=float(GovernmentPeopleSystem.person_snapshot(pid).relationships.sovereign.resentment)
	GameState.elapsed_days=day+HALL.EXPIRY_DAYS-1
	HALL.daily(day+HALL.EXPIRY_DAYS-1)
	check(HALL.find(news.id).status=="waiting","Audience expired early")
	GameState.elapsed_days=day+HALL.EXPIRY_DAYS
	HALL.daily(day+HALL.EXPIRY_DAYS)
	check(HALL.find(news.id).status=="expired" and HALL.find(petition.id).status=="expired","Audiences did not expire")
	check(is_equal_approx(opinion-_opinion("rival_a"),0.04),"Expired envoy did not cost opinion")
	check(is_equal_approx(trust-float(ForeignDiplomacy.leader("rival_a").trust),0.03),"Expired envoy did not cost trust")
	check(is_equal_approx(float(GovernmentPeopleSystem.person_snapshot(pid).relationships.sovereign.resentment),resent),"A summoned official left unheard was penalized")
	check(String(ForeignDiplomacy.leader("rival_a").memories[0].text).contains("antechamber"),"Leader did not remember being ignored")
	var sequel:=HALL.occasions().filter(func(o:Dictionary)->bool:return String(o.type)=="sequel" and String(o.civ_id)=="rival_a")
	check(not sequel.is_empty() and String(sequel[0].data.previous.option)=="ignored","An ignored envoy left no sequel for its people")

func _test_saves()->void:
	_refill()
	check(HALL.set_frequency("rare") and HALL.frequency()=="rare" and not HALL.set_frequency("constant"),"Frequency setting not honored")
	var waiting_one:=HALL.debug_force("gift","rival_a")
	HALL.append_line(waiting_one.id,{"speaker":"Envoy","role":"envoy","text":"We bring gifts."})
	var saved:=ForeignDiplomacy.export_state()
	check(saved.has("audiences") and not (saved.audiences.queue as Array).is_empty(),"Audiences missing from export")
	var roundtrip:Variant=JSON.parse_string(JSON.stringify(saved))
	var queue_ids:Array=[]
	for a in HALL.state().queue: queue_ids.append(String(a.id))
	var history_size:int=HALL.state().history.size()
	var ledger_size:int=HALL.state().ledger.size()
	ForeignDiplomacy.audiences={}
	check(ForeignDiplomacy.import_state(roundtrip).get("ok",false),"Audience state failed JSON roundtrip")
	var restored_ids:Array=[]
	for a in HALL.state().queue: restored_ids.append(String(a.id))
	check(restored_ids==queue_ids and HALL.state().history.size()==history_size,"Roundtrip changed the queue or history")
	check(HALL.state().ledger.size()==ledger_size and HALL.frequency()=="rare","Roundtrip lost the ledger or frequency")
	check(HALL.find(waiting_one.id).lines.size()==1,"Roundtrip lost scene lines")
	check(not HALL.options(waiting_one.id).is_empty() and HALL.resolve(waiting_one.id,"accept").get("ok",false),"Restored audience could not be resolved")
	var old:Dictionary=JSON.parse_string(JSON.stringify(saved)); old.erase("audiences")
	check(ForeignDiplomacy.import_state(old).get("ok",false),"Old save without audiences failed to load")
	check(HALL.waiting().is_empty() and int(HALL.state().serial)==0,"Old save did not start with an empty hall")
	var bad:Dictionary=JSON.parse_string(JSON.stringify(saved)); bad.audiences.queue[0].kind="bribe"
	check(ForeignDiplomacy.import_state(bad).has("error"),"Invalid audience state accepted")
	var bad2:Dictionary=JSON.parse_string(JSON.stringify(saved)); bad2.audiences.queue[0].terms.amount=-5
	check(ForeignDiplomacy.import_state(bad2).has("error"),"Negative terms accepted")
	var bad3:Dictionary=JSON.parse_string(JSON.stringify(saved)); bad3.audiences.frequency="constant"
	check(ForeignDiplomacy.import_state(bad3).has("error"),"Unknown frequency accepted")

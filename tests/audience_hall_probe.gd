extends Node
## Headless probe for the Audience Hall engine: pacing and variety, physical
## transfers, disabled options, expiry penalties, and save compatibility.
const HALL=preload("res://scripts/audience_hall.gd")
const SEED:=313131
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

func _setup()->void:
	WorldSimulation.clear()
	GameState.set_process(false); CivilizationSystem.set_process(false); MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(SEED); GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world(); FoodSystem.reset_for_new_world(); MilitaryCampaign.reset_for_new_world(); CivilizationSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world(); GovernmentPeopleSystem.reset_for_new_world()
	GameState.ensure_population_total(200); GameState.housing_capacity=260
	GameState.settlement_site_committed=true; GameState.settlement_completed=["Hearth Circle"]; SettlementModel.ensure_founded()
	GameState.population_health=0.9; GameState.simulation_metrics.merge({"food_days":60.0,"food_intake_ratio":1.0,"security":0.6,"cohesion":0.7},true)
	GovernmentPeopleSystem.initialize()
	_refill()
	_stock_actor("rival_a",3000,400); _stock_actor("rival_b",2000,250); _stock_actor("rival_c",800,80)
	CivilizationSystem.civilizations.clear()
	CivilizationSystem.civilizations.append(_civ("rival_a","Kel Adun",260,70,"commerce",0.2,0.35,0.1,Vector2(30,0)))
	CivilizationSystem.civilizations.append(_civ("rival_b","Varrow",420,18,"fortification",0.8,-0.3,0.65,Vector2(0,30)))
	CivilizationSystem.civilizations.append(_civ("rival_c","Isle of Mora",150,9,"expansion",0.4,0.0,0.3,Vector2(-30,0)))
	# Real third-party facts: Varrow and Mora are at war.
	var war:={"opinion":-0.6,"at_war":true,"border_tension":0.8,"treaty":"war"}
	_civ_ref("rival_b").relations["rival_c"]=war.duplicate(); _civ_ref("rival_c").relations["rival_b"]=war.duplicate()
	var calm:={"opinion":0.1,"at_war":false,"border_tension":0.2,"treaty":"none"}
	for pair in [["rival_a","rival_b"],["rival_a","rival_c"]]:
		_civ_ref(pair[0]).relations[pair[1]]=calm.duplicate(); _civ_ref(pair[1]).relations[pair[0]]=calm.duplicate()
	GameState.elapsed_days=1

func _ready()->void:
	_setup()
	check(not ForeignDiplomacy.civilization("rival_a").is_empty(),"Contacted civilization not visible")
	check(not HALL._officials().is_empty(),"No officials available for petitions")
	_test_generation()
	_setup()
	_test_transfers()
	_test_petitions()
	_test_reports()
	_test_expiry()
	_test_saves()
	print("AUDIENCE_HALL "+("PASS: varied arrivals, physical gifts/requests/tribute, disabled options, expiry, petitions and saves" if failures.is_empty() else "FAIL: "+"; ".join(failures)))
	get_tree().quit(0 if failures.is_empty() else 1)

func _test_generation()->void:
	var kinds:Dictionary={}
	var arrival_days:Array=[]
	var news_kinds:Dictionary={}
	var civs_seen:Dictionary={}
	for day in range(1,201):
		GameState.elapsed_days=day
		_refill()
		var arrivals:=HALL.daily(day)
		check(arrivals.size()<=1,"More than one arrival in a day")
		check(HALL.waiting().size()<=HALL.QUEUE_MAX,"Queue exceeded limit")
		for audience in arrivals:
			kinds[audience.kind]=int(kinds.get(audience.kind,0))+1
			arrival_days.append(day)
			if audience.origin=="foreign": civs_seen[audience.civ_id]=true
			if audience.kind=="news":
				news_kinds[audience.news.fact_kind]=true
				check(String(audience.news.subject_civ_id)!=String(audience.civ_id),"News was about the envoy's own people")
			if audience.kind in ["gift","request","threat"]: check(float(audience.terms.amount)>0,"Terms without an amount")
			if audience.kind=="petition": check(String(audience.petition.topic) in HALL.TOPICS and String(audience.petition.summary)!="","Petition without topic")
		# Answer most audiences promptly with their first open option; let every fifth wait.
		for audience in HALL.waiting():
			if day-int(audience.arrived_day)>=2 and _serial(audience)%5!=0:
				for option in HALL.options(audience.id):
					if option.enabled:
						check(HALL.resolve(audience.id,option.id).get("ok",false),"Enabled option failed to resolve")
						break
	for index in range(1,arrival_days.size()):
		check(int(arrival_days[index])-int(arrival_days[index-1])>=HALL.GAP_DAYS,"Arrivals closer than the global gap")
	var total:=0
	for kind in kinds: total+=int(kinds[kind])
	print("AUDIENCE_HALL generation over 200 days: ",kinds," news facts: ",news_kinds.keys()," civs: ",civs_seen.keys())
	check(total>=15,"Too few arrivals in 200 days (%d)" % total)
	check(kinds.size()>=4,"Too little variety in audience kinds: %s" % str(kinds))
	check(kinds.has("petition"),"Officials never petitioned")
	check(civs_seen.size()>=2,"Envoys came from too few civilizations")

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
		print("AUDIENCE_HALL defy: ",r2.outcome)
	var counter:=HALL.debug_force("threat","rival_b")
	if not counter.is_empty():
		var r3:=HALL.resolve(counter.id,"counter")
		check(r3.get("ok",false),"Counter-threat failed")
		print("AUDIENCE_HALL counter: ",r3.outcome)
	# News is about third parties and is backed by a real fact.
	var news:=HALL.debug_force("news","rival_a")
	check(not news.is_empty() and String(news.news.subject_civ_id)!="rival_a","News not generated about a third party")
	if not news.is_empty():
		print("AUDIENCE_HALL news: ",news.news.fact)
		var reward:=HALL.options(news.id)[1]
		check(HALL.resolve(news.id,"reward").get("ok",false),"Rewarding messenger failed")
	# Mood is bounded and only adds a small opinion change.
	var mood_gift:=HALL.debug_force("gift","rival_a")
	if not mood_gift.is_empty():
		for i in 10: HALL.apply_mood(mood_gift.id,5.0)
		check(is_equal_approx(float(HALL.find(mood_gift.id).mood),1.0),"Mood not clamped")
		var before2:=_opinion("rival_a")
		HALL.resolve(mood_gift.id,"accept")
		check(_opinion("rival_a")-before2<=0.04+0.03+0.0001,"Mood exceeded its opinion bound")
	# Voice context and lines.
	var talk:=HALL.debug_force("news","rival_a")
	if not talk.is_empty():
		HALL.append_line(talk.id,{"speaker":"Envoy","role":"envoy","text":"Greetings.","civ_id":"rival_a"})
		HALL.append_line(talk.id,{"speaker":"X","role":"hacker","text":""})
		check(HALL.find(talk.id).lines.size()==1,"Line validation failed")
		var ctx:=HALL.voice_context(talk.id)
		check(ctx.has("civ") and ctx.has("leader") and ctx.court is Array and ctx.court.size()<=4,"Voice context incomplete")
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
	if not health.is_empty(): HALL.resolve(health.id,"promise")
	GameState.housing_capacity=120
	var housing:=HALL.debug_force("petition","housing")
	check(not housing.is_empty() and PronouncementInterpreter._policy_has_term_in_text("emergency_building",String(housing.petition.suggested_decree).to_lower()),"Housing petition decree not understood")
	if not housing.is_empty():
		var pid2:=int(housing.speaker.person_id)
		var resent:=float(GovernmentPeopleSystem.person_snapshot(pid2).relationships.sovereign.resentment)
		HALL.resolve(housing.id,"dismiss")
		check(float(GovernmentPeopleSystem.person_snapshot(pid2).relationships.sovereign.resentment)>resent,"Dismissal did not cause resentment")
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
	# A full antechamber still hears the scouts; the oldest petition steps aside.
	var petitions:Array=[]
	for topic in ["ambition","ambition","ambition","ambition"]:
		var officials:=HALL._officials()
		var p:=HALL._generate_petition(int(officials[petitions.size()%officials.size()].person_id),int(GameState.elapsed_days),topic)
		if not p.is_empty(): HALL._enqueue(p,int(GameState.elapsed_days)); petitions.append(p)
	check(HALL.waiting().size()>=4,"Could not fill the antechamber")
	var full_report:=HALL.enqueue({"kind":"report","origin":"court","speaker":{"name":"Tamsin Reed","title":"Pathfinder","person_id":0},"report":{"facts":["smoke from many hearths","a stone wall"],"subject_civ_id":"rival_a","subject_name":"Kel Adun","source":"scouts","observed_day":1}})
	check(not full_report.is_empty() and HALL.find(petitions[0].id).status=="expired","Report did not displace the oldest petition")
	check(HALL.waiting().size()<=4,"Antechamber overflowed")
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
	check(is_equal_approx(float(GovernmentPeopleSystem.person_snapshot(pid).relationships.sovereign.resentment)-resent,0.04),"Expired petition did not cause resentment")
	check(String(ForeignDiplomacy.leader("rival_a").memories[0].text).contains("antechamber"),"Leader did not remember being ignored")

func _test_saves()->void:
	_refill()
	var waiting_one:=HALL.debug_force("gift","rival_a")
	HALL.append_line(waiting_one.id,{"speaker":"Envoy","role":"envoy","text":"We bring gifts."})
	var saved:=ForeignDiplomacy.export_state()
	check(saved.has("audiences") and not (saved.audiences.queue as Array).is_empty(),"Audiences missing from export")
	var roundtrip:Variant=JSON.parse_string(JSON.stringify(saved))
	var queue_ids:Array=[]
	for a in HALL.state().queue: queue_ids.append(String(a.id))
	var history_size:int=HALL.state().history.size()
	ForeignDiplomacy.audiences={}
	check(ForeignDiplomacy.import_state(roundtrip).get("ok",false),"Audience state failed JSON roundtrip")
	var restored_ids:Array=[]
	for a in HALL.state().queue: restored_ids.append(String(a.id))
	check(restored_ids==queue_ids and HALL.state().history.size()==history_size,"Roundtrip changed the queue or history")
	check(HALL.find(waiting_one.id).lines.size()==1,"Roundtrip lost scene lines")
	check(not HALL.options(waiting_one.id).is_empty() and HALL.resolve(waiting_one.id,"accept").get("ok",false),"Restored audience could not be resolved")
	var old:Dictionary=JSON.parse_string(JSON.stringify(saved)); old.erase("audiences")
	check(ForeignDiplomacy.import_state(old).get("ok",false),"Old save without audiences failed to load")
	check(HALL.waiting().is_empty() and int(HALL.state().serial)==0,"Old save did not start with an empty hall")
	var bad:Dictionary=JSON.parse_string(JSON.stringify(saved)); bad.audiences.queue[0].kind="bribe"
	check(ForeignDiplomacy.import_state(bad).has("error"),"Invalid audience state accepted")
	var bad2:Dictionary=JSON.parse_string(JSON.stringify(saved)); bad2.audiences.queue[0].terms.amount=-5
	check(ForeignDiplomacy.import_state(bad2).has("error"),"Negative terms accepted")

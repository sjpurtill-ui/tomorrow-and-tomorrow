extends RefCounted
## Consequential delegations for growing settlements. Eligibility reads live
## pressures; answers use the existing economy, population and general orders.
const Hall=preload("res://scripts/audience_hall.gd")
const Early=preload("res://scripts/early_visitors.gd")
const Society=preload("res://scripts/society_exchange.gd")
const Pacts=preload("res://scripts/trade_pacts.gd")
const Ledger=preload("res://scripts/trade_ledger.gd")
const Council=preload("res://scripts/war_council.gd")
const Access=preload("res://scripts/resource_access.gd")
const Orders=preload("res://scripts/order_tracker.gd")
const TITLES={"food":"Food for the coming seasons","army":"We need our people at home","suppliers":"The raids are costing us supplies","relocate":"Help us leave a failing settlement","quarry":"Work our quarry on terms","households":"Take our households before hunger"}

static func active()->bool:
	var population:=SettlementModel.national_population()
	return population>=1000 and population<10000

static func handles(a:Dictionary)->bool:
	return String(a.get("situation",{}).get("type",""))=="growing_visit"

static func jobs()->Array:
	var s:=Hall.state()
	if not s.get("growing_jobs") is Array:s.growing_jobs=[]
	return s.growing_jobs

static func pressure()->bool:
	return float(GameState.simulation_metrics.get("food_days",100))<30 or float(GameState.simulation_metrics.get("food_intake_ratio",1))<0.95

static func food_terms(civ:String)->Dictionary:
	var source:=Society.owner_state(civ)
	if source==null or not pressure() or Ledger.blocked("player",civ)!="":return {}
	if Hall.foreign_stock(civ,"Food")<float(source.population_exact)*30:return {}
	var give:=mini(Pacts.cap("Timber"),floori(Hall.player_stock("Timber")*0.25))
	if give<1:return {}
	var t:={"give_res":"Timber","give_amt":give,"get_res":"Food","get_amt":mini(240,Pacts.their_limit(civ,"Food")),"cadence":"season","portions":4,"when_ready":true,"carry_debt":false}
	t=Pacts.fit(civ,t).terms
	var appraisal:=Pacts.appraise(civ,t)
	if appraisal.decision=="counter":t=appraisal.terms;appraisal=Pacts.appraise(civ,t,true)
	if appraisal.decision!="accept" or Pacts.seal_blocker(civ,t)!="":return {}
	return t

static func threatened_supplier(civ:String)->bool:
	if not Council.stance_of(civ) in ["punish","take"]:return false
	if Ledger.dependence("player",civ)>0.01:return true
	return not Pacts.pacts(civ,true).is_empty()

static func local_value(town:Dictionary,field:String,fallback:Variant)->Variant:
	return GameState.get(field) if bool(town.get("primary",false)) else town.get("local_state",{}).get(field,fallback)

static func relocation()->Dictionary:
	for source:Dictionary in GameState.player_settlements:
		if SettlementModel.abandoned(source) or String(source.get("occupied_by",""))!="":continue
		var metrics:Dictionary=local_value(source,"simulation_metrics",{})
		var water:Dictionary=local_value(source,"water_metrics",{})
		var hungry:=float(metrics.get("food_days",100))<14
		var thirsty:=float(water.get("intake_ratio",1))<0.8
		if not hungry and not thirsty:continue
		var pop:=SettlementModel._settlement_population(source)
		if pop<40:continue
		for target:Dictionary in GameState.player_settlements:
			if target.id==source.id or SettlementModel.abandoned(target) or String(target.get("occupied_by",""))!="":continue
			var room:=floori(float(local_value(target,"housing_capacity",0))-SettlementModel._settlement_population(target))
			var target_metrics:Dictionary=local_value(target,"simulation_metrics",{})
			var target_water:Dictionary=local_value(target,"water_metrics",{})
			if room<10 or float(target_metrics.get("food_days",0))<30 or float(target_water.get("intake_ratio",1))<0.98:continue
			var count:=mini(room,mini(200,floori(pop*0.2)))
			var distance:float=(source.position as Vector2).distance_to(target.position as Vector2)
			return {"source":String(source.id),"target":String(target.id),"people":count,"days":maxi(3,ceili(distance/12)),"reason":"water is failing" if thirsty else "food is running short"}
	return {}

static func eligible(civ:String)->Array[String]:
	var out:Array[String]=[]
	if not active():return out
	if civ=="":
		if jobs().any(func(j:Dictionary)->bool:return j.status=="active"):return out
		if pressure() and int(GameState.population_allocations.get("Defense",0))>=10:out.append("army")
		if not relocation().is_empty():out.append("relocate")
		for contact:Dictionary in CivilizationSystem.civilizations:
			if threatened_supplier(String(contact.id)):out.append("suppliers");break
		return out
	var source:=Society.owner_state(civ)
	if source==null:return out
	if not food_terms(civ).is_empty():out.append("food")
	if not Access.offer(civ).is_empty():out.append("quarry")
	var foreign_metrics:Dictionary=source.simulation_metrics
	if float(source.population_exact)>100 and (float(foreign_metrics.get("food_days",100))<14 or float(foreign_metrics.get("food_intake_ratio",1))<0.85):out.append("households")
	return out

static func generate(civ:String,occasion:Dictionary,day:int,forced:String="")->Dictionary:
	var choices:=eligible(civ)
	if choices.is_empty() or (forced!="" and not forced in choices):return {}
	if forced=="" and choices.size()>1:
		for old:Dictionary in Hall.state().history:
			if handles(old):
				choices.erase(String(old.situation.visit.case));break
	var rng:=Hall._rng("growing:"+civ+":"+str(Hall.state().serial),day)
	var kind:=forced if forced!="" else choices[rng.randi_range(0,choices.size()-1)]
	var a:=Hall._new_audience("court" if civ=="" else "foreign","request",day)
	a.civ_id=civ;a.civ_name=Hall._civ_name(civ) if civ!="" else "Your households"
	var name:=String(preload("res://scripts/era_names.gd").make(int(GameState.world_seed),int(Hall.state().serial)+81000,true,civ,{}).get("name","A household representative"))
	a.speaker={"name":name,"title":"Household representative" if civ=="" else "Visiting representative","person_id":0,"role":"visitor"}
	var p:={"case":kind,"name":name,"heard":false,"opening":"","detail":""}
	match kind:
		"food":
			p.terms=food_terms(civ)
			p.opening="You need food. We can send it, if your timber keeps coming in return. Will you commit part of your output?"
			p.detail=Pacts.describe(p.terms)+" The first exchange is due after travel (20 days). It draws on actual stores, so promised timber is unavailable for your buildings and equipment. Missing either load delays that exchange; war suspends it."
		"army":
			p.people=clampi(floori(float(GameState.population_allocations.Defense)*0.25),1,200)
			p.opening="Food is running short while our people serve in the army. Bring some home to work."
			p.detail="Release up to %d people from the Defense allocation as they become available at home. Generals will recall their active expeditions. Battles and travel can delay release; people already lost or captive cannot be conjured back. Leaders will prioritize provisions where they control daily work; your manual split remains yours." % int(p.people)
		"suppliers":
			for contact:Dictionary in CivilizationSystem.civilizations:
				if threatened_supplier(String(contact.id)):p.supplier=String(contact.id);break
			p.opening="We depend on supplies from %s. Your order to raid or take their land puts those deliveries at risk." % Hall._civ_name(String(p.supplier))
			p.detail="This supplier appears in your actual import ledger or a standing trade pact. Recall the expedition, ask the general to seek peace, or keep the current objective. Existing war, routes, stocks and deliveries determine the cost; recalling raiders does not instantly restore trade."
		"relocate":
			p.merge(relocation())
			p.opening="In %s, %s. Let some of us move to %s." % [String(SettlementModel.settlement_record(p.source).name),String(p.reason),String(SettlementModel.settlement_record(p.target).name)]
			p.detail="Arrange a move for up to %d people in %d days, issuing one Food per person now. Until moving day they remain at their current work. The destination must still have shelter, food and water when the move happens. People and their age groups transfer together; buildings and stores stay behind." % [int(p.people),int(p.days)]
		"quarry":
			p.terms=Access.offer(civ)
			p.opening="You may work our %s deposit for a year. Your people do the digging and carrying; one quarter of what they extract stays with us." % String(p.terms.resource).to_lower()
			p.detail="Use 25%% of the home settlement's Extraction and Logistics workers for 365 days. The real deposit is %d travel days away; loads take the same time home. The host receives 25%% of extraction. Depletion, war, feud, embargo or a closed route stops access. Domestic production loses those workers. You can end the agreement in the court's access controls." % int(p.terms.travel)
		"households":
			p.people=clampi(floori(float(source_population(civ))*0.08),10,200)
			p.opening="There are %d of us who want to leave before the food runs out. Can your settlement take our households?" % int(p.people)
			p.detail="These are existing people in %s, including dependents. Admission transfers the same age groups into your normal population, adding food, water and housing demand. Each newcomer receives one Food from your stores. At arrival, your reception capacity was %d; admitting a smaller group leaves the others at home." % [String(a.civ_name),Society.reception_capacity()]
	a.situation={"type":"growing_visit","headline":String(TITLES[kind]),"summary":p.opening,"ask":"growing:"+kind+":"+str(day/365),"visit":p,"occasion":occasion.duplicate(true)}
	return a

static func source_population(civ:String)->float:
	var source:=Society.owner_state(civ)
	return 0.0 if source==null else float(source.population_exact)

static func option(id:String,label:String,detail:String,enabled:bool=true,reason:String="Conditions no longer allow this choice.")->Dictionary:
	return Hall._option(id,label,detail,"neutral",enabled,reason)

static func options(a:Dictionary)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	if not handles(a) or a.get("status")!="waiting":return out
	var p:Dictionary=a.situation.visit;var civ:=String(a.civ_id)
	if not bool(p.heard):out.append(option("hear","Explain the consequences",String(p.detail)))
	match String(p.case):
		"food":out.append(option("trade","Commit timber for food",Pacts.describe(p.terms),Society.owner_state(civ)!=null and Ledger.blocked("player",civ)=="" and Pacts.seal_blocker(civ,p.terms)=="" and Pacts.appraise(civ,p.terms,true).decision=="accept"))
		"army":out.append(option("release","Bring people home to work",String(p.detail),int(GameState.population_allocations.get("Defense",0))>0 and not jobs().any(func(j:Dictionary)->bool:return j.status=="active")))
		"suppliers":
			out.append(option("recall","Recall the raiders","The general ends the expedition and brings the army home.",threatened_supplier(String(p.supplier))))
			out.append(option("peace","Seek peace with the supplier","The general seeks peace; the other side must agree before war ends.",threatened_supplier(String(p.supplier))))
		"relocate":out.append(option("move","Arrange the household move",String(p.detail),Hall.player_stock("Food")>=int(p.people) and move_possible(p) and not jobs().any(func(j:Dictionary)->bool:return j.status=="active")))
		"quarry":out.append(option("access","Accept the quarry terms",String(p.detail),Access.offer(civ)==p.terms))
		"households":
			var room:=maxi(0,mini(Society.reception_capacity(),mini(floori(Hall.player_stock("Food")),floori(source_population(civ))-20)))
			out.append(option("admit","Admit all the households","Transfer %d people; issue %d Food." % [int(p.people),int(p.people)],room>=int(p.people),String(Society.reception_snapshot().message)))
			var smaller:=mini(int(p.people)/2,room)
			out.append(option("some","Admit the smaller group","Transfer %d people; issue %d Food. The others remain at home." % [smaller,smaller],smaller>=2,String(Society.reception_snapshot().message)))
	out.append(option("decline","Leave things as they are","No new commitment. Existing orders and shortages continue."))
	return out

static func resolve(a:Dictionary,choice:String)->Dictionary:
	var p:Dictionary=a.situation.visit;var civ:=String(a.civ_id)
	if choice=="hear":
		p.heard=true
		Hall.append_line(String(a.id),{"speaker":"","role":"narrator","text":String(p.detail),"day":int(GameState.elapsed_days),"aside":false})
		return {"ok":true,"keep_open":true,"outcome":String(p.detail),"reaction":"neutral"}
	var text:="";var refs:={};var kind:="growing_visit"
	match choice:
		"trade":
			var result:=Pacts.seal(civ,p.terms,20)
			if result.has("error"):return result
			refs={"pact":String(result.pact.id)};text=Pacts.describe(p.terms)+" First exchange due in 20 days."
		"access":
			var result:=Access.sign(civ,p.terms)
			if result.has("error"):return result
			refs={"access":String(result.contract.id)}
			text="Agreement signed. One quarter of home Extraction and Logistics workers will work this deposit for a year; the host keeps one quarter of output. First deliveries require travel and extraction."
		"release":
			var fronts:Array[String]=[]
			for contact:Dictionary in CivilizationSystem.civilizations:
				var id:=String(contact.id)
				if not Council.bands_against(id).is_empty() or Council.stance_of(id) in ["punish","take","defend"]:
					Council.order(id,"leave");fronts.append(id)
			var job:={"id":String(a.id),"type":"release","people":mini(int(p.people),int(GameState.population_allocations.get("Defense",0))),"released":0,"fronts":fronts,"status":"active","reason":"Waiting for troops to return home","start":int(GameState.elapsed_days)}
			add_job(job);refs={"job":String(job.id)}
			text="Generals have orders to return. Up to %d people will leave Defense as they become available at home. Leaders prioritize provisions where they control daily work; your manual split remains yours." % int(job.people)
		"recall","peace":
			var result:=Council.order(String(p.supplier),"leave" if choice=="recall" else "peace",{"card":true})
			text=String(result.get("says","The general has the objective."))
		"move":
			if not move_possible(p):return {"error":"The named destination no longer has room, food and water for this move."}
			Hall._debit_player("Food",int(p.people))
			var job:={"id":String(a.id),"type":"move","source":String(p.source),"target":String(p.target),"people":int(p.people),"released":0,"start":int(GameState.elapsed_days),"due":int(GameState.elapsed_days)+int(p.days),"status":"active","reason":"Preparing the move"}
			add_job(job);refs={"job":String(job.id)};text="The move is arranged for day %d. %d Food issued; households remain at work until moving day." % [int(job.due),int(p.people)]
		"admit","some":
			var count:=int(p.people) if choice=="admit" else mini(int(p.people)/2,Society.reception_capacity())
			count=mini(count,mini(floori(Hall.player_stock("Food")),floori(source_population(civ))-20))
			if count<2 or (choice=="admit" and count<int(p.people)):return {"error":"The household or reception capacity has changed."}
			var moved:=Early.migrate(civ,count,false)
			if moved<=0:return {"error":"These households can no longer move. Nothing was spent."}
			Hall._debit_player("Food",moved)
			text="%d people moved from %s into your population; %d Food issued. Their food, water, housing and work needs now belong to your settlement." % [moved,Hall._civ_name(civ),moved]
		"decline":text="The delegation left. Existing work, military orders and shortages continue."
		_:return {"error":"That answer is not available."}
	if choice!="decline" and not choice in ["recall","peace"]:
		var id:=Orders.register(String(TITLES[p.case]),"court")
		if refs.is_empty():Orders.done(id,text)
		else:Orders.claim(id,kind,refs)
	a.status="resolved";a.option_id=choice;a.outcome=text
	Hall._archive(a);Hall._ledger_close(a,choice,"neutral",text)
	if civ!="":ForeignDiplomacy.remember(civ,text)
	return {"ok":true,"outcome":text,"reaction":"neutral"}

static func add_job(job:Dictionary)->void:
	for old:Dictionary in jobs().duplicate():
		if old.status!="active":jobs().erase(old)
	jobs().append(job)

static func move_possible(p:Dictionary)->bool:
	var source:=SettlementModel.settlement_record(String(p.source));var target:=SettlementModel.settlement_record(String(p.target))
	if source.is_empty() or target.is_empty() or source==target:return false
	if SettlementModel.abandoned(source) or SettlementModel.abandoned(target) or String(source.get("occupied_by",""))!="" or String(target.get("occupied_by",""))!="":return false
	var metrics:Dictionary=local_value(target,"simulation_metrics",{})
	var water:Dictionary=local_value(target,"water_metrics",{})
	return SettlementModel._settlement_population(source)>=int(p.people)+20 and float(local_value(target,"housing_capacity",0))-SettlementModel._settlement_population(target)>=int(p.people) and float(metrics.get("food_days",0))>=30 and float(water.get("intake_ratio",1))>=0.98

static func transfer(p:Dictionary)->void:
	var source:=SettlementModel.settlement_record(String(p.source));var target:=SettlementModel.settlement_record(String(p.target))
	var count:=float(p.people);var total:=float(GameState.population_exact)
	var src_pop:=SettlementModel._settlement_population(source);var dst_pop:=SettlementModel._settlement_population(target)
	for town:Dictionary in [source,target]:
		var pop:=src_pop if town==source else dst_pop
		var local:Dictionary=town.get("population_state",{}).duplicate(true)
		for field in ["population_cohorts","pregnancy_cohorts"]:
			var values:Dictionary=local.get(field,GameState.get(field)).duplicate(true)
			var scale:=pop/maxf(1,float(local.get("population",total))) if local.has(field) else pop/total
			for key in values:values[key]=float(values[key])*scale
			local[field]=values
		local.population=pop;town.population_state=local
	for field in ["population_cohorts","pregnancy_cohorts"]:
		var from:Dictionary=source.population_state[field];var to:Dictionary=target.population_state[field]
		for key in from:
			var moved:=float(from[key])*count/src_pop
			from[key]-=moved;to[key]=float(to.get(key,0))+moved
	source.population_state.population=src_pop-count;target.population_state.population=dst_pop+count
	if not bool(source.get("primary",false)):source.population_share=(src_pop-count)/total
	if not bool(target.get("primary",false)):target.population_share=(dst_pop+count)/total
	GameState.settlement_network_revision+=1

static func daily(day:int)->void:
	Access.daily(day)
	for j:Dictionary in jobs():
		if j.status!="active":continue
		if j.type=="move":
			if day<int(j.due):continue
			if not move_possible(j):j.status="ended";j.reason="Move cancelled: destination capacity or ownership changed. Provisions were already issued.";continue
			transfer(j);j.released=j.people;j.status="done";j.reason="Households moved; buildings and stores remain at their original settlement."
		else:
			if j.fronts.any(func(id:String)->bool:return Council.stance_of(id)!="leave"):
				j.status="ended";j.reason="A newer military objective replaced the recall";continue
			var wanted:=maxi(0,int(j.people)-int(j.released))
			for band:Dictionary in MilitaryCampaign.field_armies.duplicate():
				if int(MilitaryCampaign.home_army.get("troops",0))+MilitaryCampaign.aggregate_recruits>=wanted:break
				if band.get("location_id","")=="player_home" and band.get("status","")=="stationed":MilitaryCampaign.disband_field_army(int(band.id))
			var released:=int(MilitaryCampaign.demobilize(wanted).get("released",0)) if wanted>0 else 0
			# Unmobilized Defense workers can return immediately through the same split.
			var free:=maxi(0,int(GameState.population_allocations.get("Defense",0))-MilitaryCampaign._mobilized_count())
			var extra:=mini(wanted-released,free)
			if extra>0:preload("res://scripts/watch_military.gd").move(-extra)
			j.released+=released+extra
			for town:Dictionary in GameState.player_settlements:
				GovernmentPeopleSystem.set_settlement_focus(String(town.id),"provisions")
			if int(j.released)>=int(j.people):j.status="done";j.reason="People released from Defense into civilian work"
			elif day-int(j.start)>365:j.status="ended";j.reason="A year passed; unavailable, lost or captive troops were not replaced"
		if j.status!="active":
			GameState.simulation_events.push_front({"day":day,"title":"HOUSEHOLD DELEGATION","description":String(j.reason)+" (%d/%d people)." % [int(j.released),int(j.people)],"domain":"society","severity":"notice"})
			if GameState.simulation_events.size()>80:GameState.simulation_events.resize(80)

static func card(refs:Dictionary)->Dictionary:
	if refs.has("access"):return Access.card(String(refs.access))
	if refs.has("pact"):
		var p:=Pacts.find(String(refs.pact))
		if p.is_empty():return {"state":"done","line":"Trade agreement archived","progress":1.0,"moved":true}
		return {"state":"stalled" if bool(p.get("suspended",false)) or bool(p.get("waiting",false)) else ("under_way" if p.status=="active" else "done"),"line":Pacts.next_words(p),"reason":Pacts.next_words(p),"progress":float(p.done),"standing":true,"moved":true}
	for j:Dictionary in jobs():
		if j.id==refs.get("job",""):
			return {"state":"under_way" if j.status=="active" else ("done" if j.status=="done" else "refused_now"),"line":"%d/%d people. %s" % [int(j.released),int(j.people),String(j.reason)],"progress":float(j.released),"moved":int(j.released)>0 or j.status=="active","standing":j.status=="active","reason":String(j.reason)}
	return {"state":"done","line":"Delegation's work archived","progress":1.0,"moved":true}

static func typed_choice(a:Dictionary,text:String)->Dictionary:
	if not handles(a):return {}
	var clean:=text.strip_edges().to_lower().trim_suffix(".").trim_suffix("!")
	for o:Dictionary in options(a):
		if bool(o.enabled) and clean==String(o.label).to_lower():return {"option":String(o.id)}
	return {}

static func voice_facts(a:Dictionary)->Dictionary:
	return {"identity":"A representative of the households or workers named in this account.","opening":a.situation.visit.opening,"account":a.situation.visit.detail,"choices":options(a),"outcome":a.get("outcome",""),"rule":"Describe only these facts. No invented benefits, threats or completed actions. The engine alone carries out a choice."}

static func parting(a:Dictionary)->String:
	return "We have heard your decision. "+String(a.get("outcome",""))

static func valid(a:Dictionary)->bool:
	var p:Variant=a.get("situation",{}).get("visit")
	if not p is Dictionary or not TITLES.has(p.get("case","")) or not p.get("heard") is bool:return false
	for key in ["name","opening","detail"]:
		if not p.get(key) is String or String(p[key]).length()>2000:return false
	if p.case in ["army","relocate","households"] and (not Hall._num(p.get("people")) or float(p.people)<1 or float(p.people)>200):return false
	if p.case=="food" and not Pacts.valid_terms(p.get("terms",{})):return false
	if p.case=="quarry":
		var t:Variant=p.get("terms")
		if not t is Dictionary or not t.get("deposit") is String or not t.get("resource") in ["Stone","Clay"]:return false
		for key in ["travel","duration","royalty"]:
			if not Hall._num(t.get(key)) or float(t[key])<0:return false
	if p.case=="suppliers" and not p.get("supplier") is String:return false
	if p.case=="relocate" and (not p.get("source") is String or not p.get("target") is String or not Hall._num(p.get("days"))):return false
	return true

static func valid_jobs(value:Variant)->bool:
	if not value is Array or value.size()>8:return false
	for j in value:
		if not j is Dictionary or not j.get("id") is String or not j.get("type") in ["release","move"] or not j.get("status") in ["active","done","ended"] or not j.get("reason") is String:return false
		for key in ["people","released","start"]:
			if not Hall._num(j.get(key)) or float(j[key])<0:return false
		if float(j.people)>200 or float(j.released)>float(j.people):return false
		if j.type=="move":
			if not j.get("source") is String or not j.get("target") is String or not Hall._num(j.get("due")):return false
		else:
			if not j.get("fronts") is Array or j.fronts.size()>100:return false
			for id in j.fronts:
				if not id is String:return false
	return true
